#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <builtinvotes>

#define TEAM_SPECTATOR          1
#define TEAM_INFECTED           3
#define ZOMBIECLASS_TANK        8

new g_iTankClient = 0;
new bool:g_bIsTankInPlay = false;
new bool:g_bTankLocationSaved = false;
new bool:g_bUseCustomPosition = false;
new Float:g_vecPosition[3];
new Float:g_vecPositionCustom[3];
new Handle:hVote = INVALID_HANDLE;
new Handle:g_hCvarDebug = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Teleport Tank",
    author = "devilesk",
    version = "1.6.0",
    description = "Adds sm_teleporttank to teleport tank to its original spawn point and sm_teleporttankto to teleport tank to a given point.",
    url = "https://steamcommunity.com/groups/RL4D2L"
};

public OnPluginStart() {
    g_hCvarDebug = CreateConVar("sm_teleport_tank_debug", "0", "Teleport Tank debug mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);

    Reset();
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("tank_spawn", Event_TankSpawn,  EventHookMode_Post);
    HookEvent("tank_killed", Event_TankKilled,  EventHookMode_Post);
    RegConsoleCmd("sm_teleporttank", Command_Teleport);
    RegConsoleCmd("sm_teleporttankto", Command_TeleportTo);
}

Reset() {
    g_iTankClient = 0;
    g_bIsTankInPlay = false;
    g_bTankLocationSaved = false;
    g_bUseCustomPosition = false;
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
        GetClientAbsOrigin(tankclient, g_vecPosition);
        g_bTankLocationSaved = true;
    }
    PrintDebug("[Timer_SaveTankLocation] tankclient: %i, saved: %i, pos (%.2f,%.2f,%.2f).", tankclient, g_bTankLocationSaved, g_vecPosition[0], g_vecPosition[1], g_vecPosition[2]);
    return Plugin_Handled;
}

public Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast) {
    Reset();
}

public Action:Command_Teleport(client, args)  {
    if (!g_bIsTankInPlay) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank not spawned.");
        return Plugin_Handled;
    }
    
    if (!g_bTankLocationSaved) {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank spawn location not saved. Try !teleporttank_to <x> <y> <z>.");
        return Plugin_Handled;
    }
    
    if (CheckCommandAccess(client, "sm_teleporttank", ADMFLAG_KICK, true)) {
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
    
    if (!g_bIsTankInPlay) {
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
    
    if (CheckCommandAccess(client, "sm_teleporttankto", ADMFLAG_KICK, true)) {
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
        for (new i = 1; i <= MaxClients; i++) {
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
                PrintDebug("[VoteResultHandler] Vote passed! Teleporting tank...");
                TeleportTank();
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

TeleportTank() {
    if (!g_bIsTankInPlay) {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Teleport failed. Tank not spawned.");
        PrintDebug("[TeleportTank] Teleport failed. Tank not spawned.");
        return;
    }

    if (!g_bTankLocationSaved && !g_bUseCustomPosition) {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Teleport failed. Teleport location not set.");
        PrintDebug("[TeleportTank] Teleport failed. Teleport location not set.");
        return;
    }
    
    new tankclient = GetTankClient();
    if (tankclient > 0) {
        decl String:name[MAX_NAME_LENGTH];
        if (IsFakeClient(tankclient)) name = "AI";
        else GetClientName(tankclient, name, sizeof(name));

        new Float:pos[3];
        new Float:vecPosition[3];
        float newVelocity[3] = {0.0,0.0,0.0};
        // attempt to teleport tank, increasing z pos each time
        for (new i = 0; i <= 10; i++) {
            if (g_bUseCustomPosition) {
                CopyVector(g_vecPositionCustom, vecPosition);
            }
            else {
                CopyVector(g_vecPosition, vecPosition);
            }
            PrintDebug("[TeleportTank] Use custom position: %i", g_bUseCustomPosition);

            vecPosition[2] += i * 10;
            TeleportEntity(tankclient, vecPosition, NULL_VECTOR, newVelocity);

            GetClientAbsOrigin(tankclient, pos);
            float distance = GetVectorDistance(pos, vecPosition, false);
            
            // check if teleport successful
            if (distance <= 10) {
                PrintToChatAll("\x01[\x04Teleport Tank\x01] Tank (\x03%s\x01) teleported to (%.2f,%.2f,%.2f).", name, vecPosition[0], vecPosition[1], vecPosition[2]);
                PrintDebug("[TeleportTank] Tank (%s) teleported to (%.2f,%.2f,%.2f) after %i attempts.", name, vecPosition[0], vecPosition[1], vecPosition[2], i);
                return;
            }
        }
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Tank (\x03%s\x01) teleport to (%.2f,%.2f,%.2f) failed.", name, vecPosition[0], vecPosition[1], vecPosition[2]);
        PrintDebug("[TeleportTank] Tank (%s) teleport to (%.2f,%.2f,%.2f) failed.", name, vecPosition[0], vecPosition[1], vecPosition[2]);
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
        tankclient = FindTankClient(); // find the tank client
        if (!tankclient) return 0;
        g_iTankClient = tankclient;
    }
 
    return tankclient;
}

FindTankClient() {
    for (new client = 1; client <= MaxClients; client++) {
            if (!IsClientInGame(client) ||
                GetClientTeam(client) != TEAM_INFECTED ||
                !IsPlayerAlive(client) ||
                GetEntProp(client, Prop_Send, "m_zombieClass") != ZOMBIECLASS_TANK)
                continue;
 
            return client; // Found tank, return
    }
    return 0;
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