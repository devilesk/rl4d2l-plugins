#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <builtinvotes>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#define TEAM_SPECTATOR          1
#define TEAM_INFECTED           3
#define ZOMBIECLASS_TANK        8
#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))

enum VoteType
{
    VoteType_SpawnTank,
    VoteType_TeleportTank
}

new g_iTankClient = 0;
new bool:g_bIsTankInPlay = false;
new bool:g_bTankLocationSaved = false;
new Float:g_vecSpawnPosition[3];
new Float:g_vecTeleportDestination[3];
new Handle:hVote = INVALID_HANDLE;
new Handle:g_hCvarDebug = INVALID_HANDLE;
new VoteType:g_VoteType;

public Plugin:myinfo = {
    name = "Teleport Tank",
    author = "devilesk",
    version = "1.8.0",
    description = "Adds sm_teleporttank to teleport tank to its original spawn point or to a given point.",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public OnPluginStart() {
    g_hCvarDebug = CreateConVar("sm_teleport_tank_debug", "0", "Teleport Tank debug mode", 0, true, 0.0, true, 1.0);

    Reset();
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("tank_spawn", Event_TankSpawn,  EventHookMode_Post);
    HookEvent("tank_killed", Event_TankKilled,  EventHookMode_Post);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    RegConsoleCmd("sm_teleporttank", Command_Teleport);
    RegConsoleCmd("sm_spawntank", Command_Spawn);
}

Reset() {
    g_iTankClient = 0;
    g_bIsTankInPlay = false;
    g_bTankLocationSaved = false;
}

public OnMapStart() {
    Reset();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    Reset();
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    g_iTankClient = client;
    
    if (g_bIsTankInPlay) return; // Tank passed
    
    g_bIsTankInPlay = true;
    CreateTimer(1.0, Timer_SaveTankLocation, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action: Timer_SaveTankLocation ( Handle:timer ) {
    if (!g_bIsTankInPlay) { return Plugin_Handled; }
    new tankclient = GetTankClient();
    if (tankclient > 0) {
        GetClientAbsOrigin(tankclient, g_vecSpawnPosition);
        g_bTankLocationSaved = true;
    }
    PrintDebug("[Timer_SaveTankLocation] tankclient: %i, saved: %i, pos (%.2f,%.2f,%.2f).", tankclient, g_bTankLocationSaved, g_vecSpawnPosition[0], g_vecSpawnPosition[1], g_vecSpawnPosition[2]);
    return Plugin_Handled;
}

public Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast) {
    Reset();
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
    new victimId = GetEventInt(event, "userid");
    new victim = GetClientOfUserId(victimId);
    
    if (IS_VALID_INGAME(victim) && GetEntProp(victim, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK) {
        Reset();
    }
}

public Action:Command_Spawn(client, args)  {
    if (g_bIsTankInPlay) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank already spawned.");
        return Plugin_Handled;
    }
    
    new bool:bIsAdmin = CheckCommandAccess(client, "sm_spawntank", ADMFLAG_KICK, true);
    
    if (!bIsAdmin) {
        if (IsSpectator(client)) {
            PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote can only be started by a player!");
            return Plugin_Handled;
        }
        else if (!IsNewBuiltinVoteAllowed()) {
            PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote cannot be started now.");
            return Plugin_Handled;
        }
    }
    else {
        if (IsBuiltinVoteInProgress()) {
            PrintToChat(client, "\x01[\x04Teleport Tank\x01] There is a vote in progress.");
            return Plugin_Handled;
        }
    }
    
    if (bIsAdmin) {
        SpawnTank();
    }
    else {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Spawn tank?");
        StartVote(client, prompt, VoteType_SpawnTank);
        FakeClientCommand(client, "Vote Yes");
    }
    
    return Plugin_Handled; 
}

public Action:Command_Teleport(client, args)  {
    if (!g_bIsTankInPlay) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank not spawned.");
        return Plugin_Handled;
    }
    
    new bool:bIsAdmin = CheckCommandAccess(client, "sm_teleporttank", ADMFLAG_KICK, true);
    
    if (!bIsAdmin) {
        if (IsSpectator(client)) {
            PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote can only be started by a player!");
            return Plugin_Handled;
        }
        else if (!IsNewBuiltinVoteAllowed()) {
            PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote cannot be started now.");
            return Plugin_Handled;
        }
    }
    else {
        if (IsBuiltinVoteInProgress()) {
            PrintToChat(client, "\x01[\x04Teleport Tank\x01] There is a vote in progress.");
            return Plugin_Handled;
        }
    }
    
    if (args == 3) {
        char x[8], y[8], z[8];
        GetCmdArg(1, x, sizeof(x));
        GetCmdArg(2, y, sizeof(y));
        GetCmdArg(3, z, sizeof(z));
        g_vecTeleportDestination[0] = StringToFloat(x);
        g_vecTeleportDestination[1] = StringToFloat(y);
        g_vecTeleportDestination[2] = StringToFloat(z);
    }
    else {
        if (g_bTankLocationSaved) {
            CopyVector(g_vecSpawnPosition, g_vecTeleportDestination);
        }
        else {
            PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank spawn location not saved. Try !teleporttank <x> <y> <z>.");
            return Plugin_Handled;
        }
    }
    
    if (bIsAdmin) {
        TeleportTank();
    }
    else {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Teleport tank to point (%.2f,%.2f,%.2f)?", g_vecTeleportDestination[0], g_vecTeleportDestination[1], g_vecTeleportDestination[2]);
        StartVote(client, prompt, VoteType_TeleportTank);
        FakeClientCommand(client, "Vote Yes");
    }
    
    return Plugin_Handled; 
}

public StartVote(client, const String:sVoteHeader[], VoteType:voteType) {
    new iNumPlayers;
    decl players[MaxClients];
    for (new i = 1; i <= MaxClients; i++) {
        if (!IsClientConnected(i) || !IsClientInGame(i)) continue;
        if (IsSpectator(i) || IsFakeClient(i)) continue;
        
        players[iNumPlayers++] = i;
    }

    g_VoteType = voteType;
    hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
    SetBuiltinVoteArgument(hVote, sVoteHeader);
    SetBuiltinVoteInitiator(hVote, client);
    SetBuiltinVoteResultCallback(hVote, VoteResultHandler);
    DisplayBuiltinVote(hVote, players, iNumPlayers, 20);
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
                DisplayBuiltinVotePass(vote, "Teleporting tank...");
                PrintToChatAll("\x01[\x04Teleport Tank\x01] Vote passed! Teleporting tank...");
                PrintDebug("[VoteResultHandler] Vote passed! Teleporting tank...");
                if (g_VoteType == VoteType_SpawnTank)
                    SpawnTank();
                else if (g_VoteType == VoteType_TeleportTank)
                    TeleportTank();
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

SpawnTank() {
    if (g_bIsTankInPlay) {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Spawn tank failed. Tank already spawned.");
        PrintDebug("[TeleportTank] Spawn tank failed. Tank already spawned.");
        return;
    }
    PrintToChatAll("\x01[\x04Teleport Tank\x01] Setting tank %% to zero.");
    PrintDebug("[TeleportTank] Setting tank %% to zero.");
    new round = InSecondHalfOfRound();
    L4D2Direct_SetVSTankFlowPercent(round, 0.0);
}

TeleportTank() {
    if (!g_bIsTankInPlay) {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Teleport failed. Tank not spawned.");
        PrintDebug("[TeleportTank] Teleport failed. Tank not spawned.");
        return;
    }
    
    new tankclient = GetTankClient();
    if (tankclient > 0) {
        decl String:name[MAX_NAME_LENGTH];
        if (IsFakeClient(tankclient))
            name = "AI";
        else
            GetClientName(tankclient, name, sizeof(name));

        new Float:currentPosition[3];
        new Float:targetPosition[3];
        float newVelocity[3] = {0.0,0.0,0.0};
        // attempt to teleport tank, increasing z pos each time
        for (new i = 0; i <= 10; i++) {
            CopyVector(g_vecTeleportDestination, targetPosition);
            targetPosition[2] += i * 10;
            TeleportEntity(tankclient, targetPosition, NULL_VECTOR, newVelocity);

            GetClientAbsOrigin(tankclient, currentPosition);
            float distance = GetVectorDistance(currentPosition, targetPosition, false);
            
            // check if teleport successful
            if (distance <= 10) {
                PrintToChatAll("\x01[\x04Teleport Tank\x01] Tank (\x03%s\x01) teleported to (%.2f,%.2f,%.2f).", name, targetPosition[0], targetPosition[1], targetPosition[2]);
                PrintDebug("[TeleportTank] Tank (%s) teleported to (%.2f,%.2f,%.2f) after %i attempts.", name, targetPosition[0], targetPosition[1], targetPosition[2], i);
                return;
            }
        }
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Tank (\x03%s\x01) teleport to (%.2f,%.2f,%.2f) failed.", name, targetPosition[0], targetPosition[1], targetPosition[2]);
        PrintDebug("[TeleportTank] Tank (%s) teleport to (%.2f,%.2f,%.2f) failed.", name, targetPosition[0], targetPosition[1], targetPosition[2]);
    }
    else {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Teleport failed. Tank not found.");
        PrintDebug("[TeleportTank] Teleport failed. Tank not found.");
    }
}

IsSpectator(client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR;
}

GetTankClient() {
    if (!g_bIsTankInPlay) return 0;
 
    new tankclient = g_iTankClient;
 
    if (!IsClientInGame(tankclient)) {  // If tank somehow is no longer in the game (kicked, hence events didn't fire)
        tankclient = FindTankClient(-1); // find the tank client
        if (tankclient != -1) return 0;
        g_iTankClient = tankclient;
    }
 
    return tankclient;
}

void CopyVector(const float vecSrc[3], float vecDest[3]) {
    vecDest[0] = vecSrc[0];
    vecDest[1] = vecSrc[1];
    vecDest[2] = vecSrc[2];
}

stock PrintDebug(const String:Message[], any:...) {
    if (GetConVarBool(g_hCvarDebug)) {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}