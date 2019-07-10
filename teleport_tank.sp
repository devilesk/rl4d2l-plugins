#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <builtinvotes>

new g_iTankId;
new bool:g_bUseCustomPos = false;
new Float:position[3];
new Float:positionCustom[3];
new bool:g_bTankSpawned = false;
new Handle:hVote;

public Plugin:myinfo =
{
    name = "Teleport Tank",
    author = "devilesk",
    version = "1.1.0",
    description = "Adds sm_teleporttank to teleport tank back to its spawn point.",
    url = "https://steamcommunity.com/groups/RL4D2L"
};

public OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
    HookEvent("tank_spawn", Event_TankSpawn,  EventHookMode_Post);
    HookEvent("tank_killed", Event_TankKilled,  EventHookMode_Post);
    RegConsoleCmd("sm_teleporttank", Vote);
    RegConsoleCmd("sm_teleporttank_to", Vote2);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bTankSpawned = false;
}

public Event_TankSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_iTankId = GetEventInt(event, "tankid");
    CreateTimer(2.0, Timer_SaveTankLocation, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action: Timer_SaveTankLocation ( Handle:timer )
{
    if (!g_bTankSpawned && g_iTankId > 0)
    {
        GetEntPropVector(g_iTankId, Prop_Send, "m_vecOrigin", position);
        g_bTankSpawned = true;
    }
}

public Event_TankKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
    g_bTankSpawned = false;
}

public Action:Vote2(client, args) 
{
    if (args < 3)
    {
        ReplyToCommand(client, "[SM] Usage: sm_teleporttank_to <x coord> <y coord> <z coord>");
        return Plugin_Handled;
    }
    
    if (!g_bTankSpawned)
    {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank not spawned.");
        return Plugin_Handled;
    }

    if (IsSpectator(client))
    {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote can only be started by a player!");
        return Plugin_Handled;
    }
    
    char x[8];
    char y[8];
    char z[8];
    GetCmdArg(1, x, sizeof(x));
    GetCmdArg(2, y, sizeof(y));
    GetCmdArg(3, z, sizeof(z));
    positionCustom[0] = StringToFloat(x);
    positionCustom[1] = StringToFloat(y);
    positionCustom[2] = StringToFloat(z);

    new String:prompt[100];
    Format(prompt, sizeof(prompt), "Teleport tank to point (%.2f,%.2f,%.2f)?", positionCustom[0], positionCustom[1], positionCustom[2]);
    if (StartVote(client, prompt, true))
        FakeClientCommand(client, "Vote Yes");

    return Plugin_Handled; 
}

public Action:Vote(client, args) 
{
    if (!g_bTankSpawned)
    {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Tank not spawned.");
        return Plugin_Handled;
    }

    if (IsSpectator(client))
    {
        PrintToChat(client, "\x01[\x04Teleport Tank\x01] Vote can only be started by a player!");
        return Plugin_Handled;
    }

    new String:prompt[100];
    Format(prompt, sizeof(prompt), "Teleport tank back to its spawn point (%.2f,%.2f,%.2f)?", position[0], position[1], position[2]);
    if (StartVote(client, prompt, false))
        FakeClientCommand(client, "Vote Yes");

    return Plugin_Handled; 
}

bool:StartVote(client, const String:sVoteHeader[], bool:bUseCustomPos)
{
    if (IsNewBuiltinVoteAllowed())
    {
        new iNumPlayers;
        decl players[MaxClients];
        for (new i = 1; i <= MaxClients; i++)
        {
            if (!IsClientConnected(i) || !IsClientInGame(i)) continue;
            if (IsSpectator(i) || IsFakeClient(i)) continue;
            
            players[iNumPlayers++] = i;
        }
    
        g_bUseCustomPos = bUseCustomPos;
        
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

public VoteActionHandler(Handle:vote, BuiltinVoteAction:action, param1, param2)
{
    switch (action)
    {
        case BuiltinVoteAction_End:
        {
            hVote = INVALID_HANDLE;
            CloseHandle(vote);
        }
        case BuiltinVoteAction_Cancel:
        {
            DisplayBuiltinVoteFail(vote, BuiltinVoteFailReason:param1);
        }
    }
}

public VoteResultHandler(Handle:vote, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
    for (new i = 0; i < num_items; i++)
    {
        if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
        {
            if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
            {
                DisplayBuiltinVotePass(vote, "Teleporting tank...");
                PrintToChatAll("\x01[\x04Teleport Tank\x01] Vote passed! Teleporting tank...");
                TeleportTank();
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

public TeleportTank()
{
    if (g_bTankSpawned) {
        TeleportEntity(g_iTankId, g_bUseCustomPos ? positionCustom : position, NULL_VECTOR, NULL_VECTOR);
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Tank teleported to (%.2f,%.2f,%.2f).",
            g_bUseCustomPos ? positionCustom[0] : position[0],
            g_bUseCustomPos ? positionCustom[1] : position[1],
            g_bUseCustomPos ? positionCustom[2] : position[2]);
    }
    else {
        PrintToChatAll("\x01[\x04Teleport Tank\x01] Tank not spawned.");
    }
}

stock bool:IsSpectator(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1;
}