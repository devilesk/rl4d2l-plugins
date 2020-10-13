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
#include <left4dhooks>
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
new g_wepType;
new Handle:hVote;
int g_target_list[MAXPLAYERS];
int g_target_count;

public Plugin:myinfo = {
    name = "Spawn Secondary",
    author = "devilesk",
    description = "Spawning pistols and/or axes for players.",
    version = "0.9.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
}

public OnPluginStart() {
    g_bReadyUpAvailable = LibraryExists("readyup");
    RegConsoleCmd("sm_spawnsecondary", Command_SpawnSecondary, "Spawn pistol and axe for a player.");
    RegConsoleCmd("sm_spawnpistol", Command_SpawnPistol, "Spawn a pistol for a player.");
    RegConsoleCmd("sm_spawnaxe", Command_SpawnAxe, "Spawn an axe for a player.");
    HookEvent("round_end", Event_RoundEnd);
    LoadTranslations("common.phrases");
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
            PrintToChatAll("\x01[\x04Spawn Secondary\x01] Spawned pistol for %N.", iClient);
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
            PrintToChatAll("\x01[\x04Spawn Secondary\x01] Spawned axe for %N.", iClient);
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

bool:IsSpawnAllowed() {
    if (g_bSpawnNotAllowed) {
        PrintToChatAll("\x01[\x04Spawn Secondary\x01] Cannot spawn after round started.");
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
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_spawnpistol <#userid|name>");
        return Plugin_Handled;
    }

    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
    
    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    
    if (CheckCommandAccess(client, "sm_spawnpistol", ADMFLAG_KICK, true)) {
        for (int i = 0; i < target_count; i++)
        {
            SpawnWeaponForClient(PISTOL, target_list[i]);
        }
    }
    else if (CanStartVote(client)) {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Spawn pistol for %s?", target_name);
        if (StartVote(client, prompt, PISTOL, target_count, target_list)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    
    return Plugin_Handled; 
}

public Action:Command_SpawnAxe(client, args)  {
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_spawnaxe <#userid|name>");
        return Plugin_Handled;
    }

    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
    
    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    
    if (CheckCommandAccess(client, "sm_spawnaxe", ADMFLAG_KICK, true)) {
        for (int i = 0; i < target_count; i++)
        {
            SpawnWeaponForClient(AXE, target_list[i]);
        }
    }
    else if (CanStartVote(client)) {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Spawn axe for %s?", target_name);
        if (StartVote(client, prompt, AXE, target_count, target_list)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    
    return Plugin_Handled; 
}

public Action:Command_SpawnSecondary(client, args)  {
    if (args < 1)
    {
        ReplyToCommand(client, "[SM] Usage: sm_spawnsecondary <#userid|name>");
        return Plugin_Handled;
    }

    char arg[65];
    GetCmdArg(1, arg, sizeof(arg));

    char target_name[MAX_TARGET_LENGTH];
    int target_list[MAXPLAYERS], target_count;
    bool tn_is_ml;
    
    if ((target_count = ProcessTargetString(
            arg,
            client,
            target_list,
            MAXPLAYERS,
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
    {
        ReplyToTargetError(client, target_count);
        return Plugin_Handled;
    }
    
    if (CheckCommandAccess(client, "sm_spawnsecondary", ADMFLAG_KICK, true)) {
        for (int i = 0; i < target_count; i++)
        {
            SpawnWeaponForClient(PISTOL, target_list[i]);
            SpawnWeaponForClient(AXE, target_list[i]);
        }
    }
    else if (CanStartVote(client)) {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Spawn pistol and axe for %s?", target_name);
        if (StartVote(client, prompt, BOTH, target_count, target_list)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    
    return Plugin_Handled; 
}

bool:StartVote(client, const String:sVoteHeader[], wepType, target_count, const target_list[MAXPLAYERS]) {
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
        g_target_count = target_count;
        g_target_list = target_list;
        
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
                for (int j = 0; j < g_target_count; j++)
                {
                    if (g_wepType == BOTH || g_wepType == AXE)
                        SpawnWeaponForClient(AXE, g_target_list[j]);
                    if (g_wepType == BOTH || g_wepType == PISTOL)
                        SpawnWeaponForClient(PISTOL, g_target_list[j]);
                }
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}