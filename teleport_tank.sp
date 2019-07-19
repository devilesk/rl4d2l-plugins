#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <builtinvotes>

#define TEAM_SPECTATOR          1
#define TEAM_INFECTED           3
#define ZC_TANK                 8

new bool:g_bTankSpawned = false;
new bool:g_bTankLocationSaved = false;
new bool:g_bUseCustomPosition = false;
new Float:g_vecPosition[3];
new Float:g_vecPositionCustom[3];
new Handle:hVote;

public Plugin:myinfo = {
    name = "Teleport Tank",
    author = "devilesk",
    version = "1.4.0",
    description = "Adds sm_teleporttank to teleport tank to its original spawn point and sm_teleporttankto to teleport tank to a given point.",
    url = "https://steamcommunity.com/groups/RL4D2L"
};

public OnPluginStart() {
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("tank_spawn", Event_TankSpawn,  EventHookMode_Post);
    HookEvent("tank_killed", Event_TankKilled,  EventHookMode_Post);
    RegConsoleCmd("sm_teleporttank", Command_Teleport);
    RegConsoleCmd("sm_teleporttankto", Command_TeleportTo);
}

Reset() {
    g_bTankSpawned = false;
    g_bTankLocationSaved = false;
}

public OnMapStart() {
    Reset();
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    Reset();
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast) {
    g_bTankSpawned = true;
    CreateTimer(1.0, Timer_SaveTankLocation, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action: Timer_SaveTankLocation ( Handle:timer ) {
    if (!g_bTankSpawned) { return Plugin_Handled; }
    new iTank = FindTankClient();
    if (iTank > 0) {
        GetClientAbsOrigin(iTank, g_vecPosition);
        g_bTankLocationSaved = true;
    }
    return Plugin_Handled;
}

public Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast) {
    Reset();
}

public Action:Command_Teleport(client, args)  {
    if (!g_bTankSpawned) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank not spawned.");
        return Plugin_Handled;
    }
    
    if (!g_bTankLocationSaved) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank spawn location not saved. Try !teleporttank_to <x> <y> <z>.");
        return Plugin_Handled;
    }
    
    if (CheckCommandAccess(client, "sm_teleporttank", ADMFLAG_KICK)) {
        g_bUseCustomPosition = false;
        TeleportTank();
    }
    else if (IsSpectator(client)) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote can only be started by a player!");
    }
    else {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Teleport tank to spawn point (%.2f,%.2f,%.2f)?", g_vecPosition[0], g_vecPosition[1], g_vecPosition[2]);
        if (StartVote(client, prompt, false)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    
    return Plugin_Handled; 
}

public Action:Command_TeleportTo(client, args)  {
    if (args < 3) {
        ReplyToCommand(client, "[SM] Usage: sm_teleporttankto <x> <y> <z>");
        return Plugin_Handled;
    }
    
    if (!g_bTankSpawned) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank not spawned.");
        return Plugin_Handled;
    }

    char x[8], y[8], z[8];
    GetCmdArg(1, x, sizeof(x));
    GetCmdArg(2, y, sizeof(y));
    GetCmdArg(3, z, sizeof(z));
    g_vecPositionCustom[0] = StringToFloat(x);
    g_vecPositionCustom[1] = StringToFloat(y);
    g_vecPositionCustom[2] = StringToFloat(z);
    
    if (CheckCommandAccess(client, "sm_teleporttankto", ADMFLAG_KICK)) {
        g_bUseCustomPosition = true;
        TeleportTank();
    }
    else if (IsSpectator(client)) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote can only be started by a player!");
    }
    else {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Teleport tank to point (%.2f,%.2f,%.2f)?", g_vecPositionCustom[0], g_vecPositionCustom[1], g_vecPositionCustom[2]);
        if (StartVote(client, prompt, true)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }

    return Plugin_Handled; 
}

bool:StartVote(client, const String:sVoteHeader[], bool:bUseCustomPosition) {
    if (IsNewBuiltinVoteAllowed()) {
        new iNumPlayers;
        decl players[MaxClients];
        for (new i = 1; i <= MaxClients; i++)
        {
            if (!IsClientConnected(i) || !IsClientInGame(i)) continue;
            if (IsSpectator(i) || IsFakeClient(i)) continue;
            
            players[iNumPlayers++] = i;
        }
    
        g_bUseCustomPosition = bUseCustomPosition;
        
        hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
        SetBuiltinVoteArgument(hVote, sVoteHeader);
        SetBuiltinVoteInitiator(hVote, client);
        SetBuiltinVoteResultCallback(hVote, VoteResultHandler);
        DisplayBuiltinVote(hVote, players, iNumPlayers, 20);
        return true;
    }

    PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote cannot be started now.");
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
                DisplayBuiltinVotePass(vote, "Teleporting tank...");
                PrintToChatAll("\x01[\x04Teleport Tank\x01] Vote passed! Teleporting tank...");
                TeleportTank();
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

TeleportTank() {
    if (!g_bTankSpawned) {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Teleport failed. Tank not spawned.");
        return;
    }

    if (!g_bTankLocationSaved && !g_bUseCustomPosition) {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Teleport failed. Teleport location not set.");
        return;
    }
    
    new iTank = FindTankClient();
    if (iTank > 0) {
        new Float:vecPosition[3];
        if (g_bUseCustomPosition) {
            vecPosition = g_vecPositionCustom;
        }
        else {
            vecPosition = g_vecPosition;
        }
        TeleportEntity(iTank, vecPosition, NULL_VECTOR, NULL_VECTOR);
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Tank teleported to (%.2f,%.2f,%.2f).", vecPosition[0], vecPosition[1], vecPosition[2]);
    }
    else {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Teleport failed. Tank not found.");
    }
}

IsInfected(client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_INFECTED;
}

IsSpectator(client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR;
}

FindTankClient() {
    for (new client = 1; client <= MaxClients; client++) {
        if (!IsInfected(client) ||
            !IsPlayerAlive(client) ||
            GetEntProp(client, Prop_Send, "m_zombieClass") != ZC_TANK) {
                continue;
        }
        return client;
    }
    return 0;
}