/*
* Based on
* [L4D] Pills Here by Crimson_Fox
* http://forums.alliedmods.net/showthread.php?p=915033
* [L4D & L4D2] Weapon Spawn by SilverShot
* https://forums.alliedmods.net/showthread.php?t=222934?t=222934
* [L4D2] Melee Weapon Spawner
* https://forums.alliedmods.net/showthread.php?t=223020?t=223020
* Player Statistics by Tabun
* https://github.com/Tabbernaut/L4D2-Plugins/tree/master/stats
*/

#include <sourcemod>
#include <sdktools>
#include <left4downtown>
#include <builtinvotes>
#undef REQUIRE_PLUGIN
#include <readyup>
#define REQUIRE_PLUGIN

#define PISTOL  0
#define AXE     1
#define BOTH    2
#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
 
new bool:g_bReadyUpAvailable = false;
new bool:g_bSpawnNotAllowed = false;
new g_iMaxCount;
new g_wepType;
new Handle:hVote;

public Plugin:myinfo = {
    name = "Spawn Secondary",
    author = "devilesk",
    description = "Admin commands and vote commands for spawning pistols and/or axes for survivors.",
    version = "0.6.0",
    url = "https://steamcommunity.com/groups/RL4D2L"
}

public OnPluginStart() {
    g_bReadyUpAvailable = LibraryExists("readyup");
    RegConsoleCmd("sm_spawnsecondary", Command_SpawnSecondary, "Call vote to spawn pistol and axe for 1 to 4 survivors.");
    RegConsoleCmd("sm_spawnpistol", Command_SpawnPistol, "Call vote to spawn a pistol for 1 to 4 survivors.");
    RegConsoleCmd("sm_spawnaxe", Command_SpawnAxe, "Call vote to spawn an axe for 1 to 4 survivors.");
    HookEvent("round_end", Event_RoundEnd);
}

public OnLibraryRemoved(const String:name[]) {
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = false; }
}

public OnLibraryAdded(const String:name[]) {
    if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = true; }
}

public OnMapStart() {
    g_bSpawnNotAllowed = false;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
    g_bSpawnNotAllowed = false;
}

public OnRoundIsLive() {
    // only called if readyup is available
    g_bSpawnNotAllowed = true;
}

public Action: L4D_OnFirstSurvivorLeftSafeArea( client ) {
    // if no readyup, use this to set spawn not allowed
    if ( !g_bReadyUpAvailable ) {
        g_bSpawnNotAllowed = true;
    }
}

bool:SpawnPistol(const Float:vecPosition[3]) {
    new iWeapon = CreateEntityByName("weapon_pistol");
    
    if(IsValidEntity(iWeapon)) {
        DispatchKeyValue(iWeapon, "solid", "6");
        DispatchKeyValue(iWeapon, "model", "models/w_models/weapons/w_pistol_a.mdl");
        DispatchKeyValue(iWeapon, "rendermode", "3");
        DispatchKeyValue(iWeapon, "disableshadows", "1");
        TeleportEntity(iWeapon, vecPosition, NULL_VECTOR, NULL_VECTOR);
        DispatchSpawn(iWeapon);
        return true;
    }
    return false;
}

bool:SpawnAxe(const Float:vecPosition[3]) {
    new iWeapon = CreateEntityByName("weapon_melee");
    
    if(IsValidEntity(iWeapon)) {
        DispatchKeyValue(iWeapon, "solid", "6");
        DispatchKeyValue(iWeapon, "melee_script_name", "fireaxe");
        DispatchSpawn(iWeapon);
        TeleportEntity(iWeapon, vecPosition, NULL_VECTOR, NULL_VECTOR);
        return true;
    }
    return false;
}

bool:SpawnPistolForClient(iClient) {
    if (IsClientInGame(iClient) && GetClientTeam(iClient) == TEAM_SURVIVOR) {
        decl Float:vecPosition[3];
        GetClientAbsOrigin(iClient, vecPosition);
        vecPosition[2] += 10;
        if (SpawnPistol(vecPosition)) {
            PrintToChatAll("\x01[\x04Spawn Secondary\x01] Spawned pistol by %N.", iClient);
            return true;
        }
    }
    return false;
}

bool:SpawnAxeForClient(iClient) {
    if (IsClientInGame(iClient) && GetClientTeam(iClient) == TEAM_SURVIVOR) {
        decl Float:vecPosition[3];
        GetClientAbsOrigin(iClient, vecPosition);
        vecPosition[2] += 20;
        if (SpawnAxe(vecPosition)) {
            PrintToChatAll("\x01[\x04Spawn Secondary\x01] Spawned axe by %N.", iClient);
            return true;
        }
    }
    return false;
}

bool:SpawnWeaponForClient(wepType, iClient) {
    if (wepType == PISTOL) {
        return SpawnPistolForClient(iClient);
    }
    else {
        return SpawnAxeForClient(iClient);
    }
}

SpawnWeaponForClients(wepType, iMaxCount) {
    new iCount = 0;
    for (new i = 1; i <= MaxClients; i++) {
        if (iCount < iMaxCount) {
            if (SpawnWeaponForClient(wepType, i)) {
                iCount++;
            }
        }
    }
}

bool:IsSpawnAllowed() {
    if (g_bSpawnNotAllowed) {
        PrintToChatAll("\x01[\x04Spawn Secondary\x01] Cannot spawn after round started.");
        return false;
    }
    return true;
}

bool:IsValidMaxCount(iMaxCount) {
    if (iMaxCount < 1 || iMaxCount > 4) {
        PrintToChatAll("\x01[\x04Spawn Secondary\x01] Spawn count must be between 1 and 4.");
        return false;
    }
    return true;
}

IsSpectator(client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR;
}

bool:CanStartVote(client) {
    if (!IsSpawnAllowed()) {
        return false;
    }
    if (IsSpectator(client)) {
        PrintToChat(client, "\x01[\x04Spawn Secondary\x01] Vote can only be started by a player!");
        return false;
    }
    return true;
}

public Action:Command_SpawnPistol(client, args)  {
    new iMaxCount;
    if (args < 1)  {
        iMaxCount = 1;
    }
    else {
        char arg[8];
        GetCmdArg(1, arg, sizeof(arg));
        iMaxCount = StringToInt(arg);
        if (!IsValidMaxCount(iMaxCount)) { return Plugin_Handled; }
    }
    
    if (CheckCommandAccess(client, "sm_spawnpistol", ADMFLAG_KICK, true)) {
        SpawnWeaponForClients(PISTOL, iMaxCount);
    }
    else if (CanStartVote(client)) {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Spawn %d pistol for survivors?", iMaxCount);
        if (StartVote(client, prompt, PISTOL, iMaxCount)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    
    return Plugin_Handled; 
}

public Action:Command_SpawnAxe(client, args)  {
    new iMaxCount;
    if (args < 1)  {
        iMaxCount = 1;
    }
    else {
        char arg[8];
        GetCmdArg(1, arg, sizeof(arg));
        iMaxCount = StringToInt(arg);
        if (!IsValidMaxCount(iMaxCount)) { return Plugin_Handled; }
    }
    
    if (CheckCommandAccess(client, "sm_spawnaxe", ADMFLAG_KICK, true)) {
        SpawnWeaponForClients(AXE, iMaxCount);
    }
    else if (CanStartVote(client)) {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Spawn %d axe for survivors?", iMaxCount);
        if (StartVote(client, prompt, AXE, iMaxCount)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    
    return Plugin_Handled; 
}

public Action:Command_SpawnSecondary(client, args)  {
    new iMaxCount;
    if (args < 1)  {
        iMaxCount = 1;
    }
    else {
        char arg[8];
        GetCmdArg(1, arg, sizeof(arg));
        iMaxCount = StringToInt(arg);
        if (!IsValidMaxCount(iMaxCount)) { return Plugin_Handled; }
    }
    
    if (CheckCommandAccess(client, "sm_spawnsecondary", ADMFLAG_KICK, true)) {
        SpawnWeaponForClients(PISTOL, iMaxCount);
        SpawnWeaponForClients(AXE, iMaxCount);
    }
    else if (CanStartVote(client)) {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Spawn %d pistol and axe for survivors?", iMaxCount);
        if (StartVote(client, prompt, BOTH, iMaxCount)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    
    return Plugin_Handled; 
}

bool:StartVote(client, const String:sVoteHeader[], wepType, iMaxCount) {
    if (IsNewBuiltinVoteAllowed()) {
        new iNumPlayers;
        decl players[MaxClients];
        for (new i = 1; i <= MaxClients; i++)
        {
            if (!IsClientConnected(i) || !IsClientInGame(i)) continue;
            if (IsSpectator(i) || IsFakeClient(i)) continue;
            
            players[iNumPlayers++] = i;
        }
    
        g_wepType = wepType;
        g_iMaxCount = iMaxCount;
        
        hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
        SetBuiltinVoteArgument(hVote, sVoteHeader);
        SetBuiltinVoteInitiator(hVote, client);
        SetBuiltinVoteResultCallback(hVote, VoteResultHandler);
        DisplayBuiltinVote(hVote, players, iNumPlayers, 20);
        return true;
    }

    PrintToChat(client, "\x01[\x04Spawn Secondary\x01] Vote cannot be started now.");
    return false;
}

public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2) {
    switch (action) {
        case BuiltinVoteAction_End: {
            hVote = INVALID_HANDLE;
            CloseHandle(vote);
        }
        case BuiltinVoteAction_Cancel: {
            DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
        }
    }
}

public VoteResultHandler(Handle:vote, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2]) {
    for (new i = 0; i < num_items; i++) {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES) {
            if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2)) {
                DisplayBuiltinVotePass(vote, "Spawning weapons...");
                PrintToChatAll("\x01[\x04Spawn Secondary\x01] Vote passed! Spawning weapons...");
                if (g_wepType == BOTH) {
                    SpawnWeaponForClients(PISTOL, g_iMaxCount);
                    SpawnWeaponForClients(AXE, g_iMaxCount);
                }
                else {
                    SpawnWeaponForClients(g_wepType, g_iMaxCount);
                }
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}