#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>
#include <builtinvotes>

#define TEAM_SPECTATOR          1
#define MAXMAP                  32

// Used to set the scores
new Handle:gConf = INVALID_HANDLE;
new Handle:fSetCampaignScores = INVALID_HANDLE;

new g_iMapRestarts;                                     // current number of restart attempts
new bool:g_bIsMapRestarted;                             // whether map has been restarted by this plugin
new Handle:g_hCvarDebug = INVALID_HANDLE;
new Handle:g_hCvarAutofix = INVALID_HANDLE;
new Handle:g_hCvarAutofixMaxTries = INVALID_HANDLE;     // max number of restart attempts convar
new Handle:hVote;                                       // restart vote handle
new g_iSurvivorTeamIndex;
new g_iInfectedTeamIndex;
new g_iSurvivorScore;
new g_iInfectedScore;
new String:g_sMapName[MAXMAP] = "";

public Plugin:myinfo = {
    name = "L4D2 Restart Map",
    author = "devilesk",
    description = "Adds sm_restartmap to restart the current map and keep current scores. Automatically restarts map when broken flow detected.",
    version = "0.4.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public OnPluginStart() {
    g_hCvarDebug = CreateConVar("sm_restartmap_debug", "0", "Restart Map debug mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarAutofix = CreateConVar("sm_restartmap_autofix", "1", "Check for broken flow on map load and automatically restart.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarAutofixMaxTries = CreateConVar("sm_restartmap_autofix_max_tries", "1", "Max number of automatic restart attempts to fix broken flow.", FCVAR_PLUGIN, true, 1.0);
    
    RegConsoleCmd("sm_restartmap", Command_RestartMap);
    
    g_iMapRestarts = 0;
    g_bIsMapRestarted = false;
    
    gConf = LoadGameConfigFile("left4downtown.l4d2");
    if(gConf == INVALID_HANDLE) {
        LogError("Could not load gamedata/left4downtown.l4d2.txt");
    }

    StartPrepSDKCall(SDKCall_GameRules);
    if (PrepSDKCall_SetFromConf(gConf, SDKConf_Signature, "SetCampaignScores")) {
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
        fSetCampaignScores = EndPrepSDKCall();
        if (fSetCampaignScores == INVALID_HANDLE) {
            LogError("Function 'SetCampaignScores' found, but something went wrong.");
        }
    }
    else {
        LogError("Function 'SetCampaignScores' not found.");
    }
}

public OnMapStart() {
    // Compare current map to previous map and reset if different.
    decl String:sBuffer[MAXMAP];
    GetCurrentMap(sBuffer,sizeof(sBuffer));
    if (!StrEqual(g_sMapName, sBuffer, false)) {
        g_bIsMapRestarted = false;
        g_iMapRestarts = 0;
    }
    
    // Start broken flow check timer if autofix enabled and max tries not reached
    if (GetConVarBool(g_hCvarAutofix) && g_iMapRestarts < GetConVarInt(g_hCvarAutofixMaxTries)) {
        CreateTimer(2.0, CheckFlowBroken, _, TIMER_FLAG_NO_MAPCHANGE);
    }
    
    // Set scores if map restarted
    if (g_bIsMapRestarted) {
        PrintDebug("[OnMapStart] Restarted. Setting scores... survivor: %i, score %i, infected: %i, score %i", g_iSurvivorTeamIndex, g_iSurvivorScore, g_iInfectedTeamIndex, g_iInfectedScore);
        
        //Set the scores
        SDKCall(fSetCampaignScores, g_iSurvivorScore, g_iInfectedScore); //visible scores
        L4D2Direct_SetVSCampaignScore(g_iSurvivorTeamIndex, g_iSurvivorScore); //real scores
        L4D2Direct_SetVSCampaignScore(g_iInfectedTeamIndex, g_iInfectedScore);
        
        g_bIsMapRestarted = false;
    }
}

public Action:CheckFlowBroken(Handle:timer) {
    new bool:bIsFlowBroken = IsFlowBroken();
    PrintDebug("[CheckFlowBroken] Flow broken: %i", bIsFlowBroken);
    if (bIsFlowBroken) {
        PrintToChatAll("Broken flow detected.");
        PrintToConsoleAll("Broken flow detected.");
        PrintDebug("Broken flow detected.");
        RestartMap();
    }
    else {
        g_iMapRestarts = 0;
    }
}

public RestartMap() {
    g_iSurvivorTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped") ? 1 : 0;
    g_iInfectedTeamIndex = GameRules_GetProp("m_bAreTeamsFlipped") ? 0 : 1;

    g_iSurvivorScore = L4D2Direct_GetVSCampaignScore(g_iSurvivorTeamIndex);
    g_iInfectedScore = L4D2Direct_GetVSCampaignScore(g_iInfectedTeamIndex);
    
    g_bIsMapRestarted = true;
    g_iMapRestarts++;
    
    PrintToConsoleAll("[RestartMap] Restarting map. Attempt: %i of %i... survivor: %i, score %i, infected: %i, score %i", g_iMapRestarts, GetConVarInt(g_hCvarAutofixMaxTries), g_iSurvivorTeamIndex, g_iSurvivorScore, g_iInfectedTeamIndex, g_iInfectedScore);
    PrintDebug("[RestartMap] Restarting map. Attempt: %i of %i...  survivor: %i, score %i, infected: %i, score %i", g_iMapRestarts, GetConVarInt(g_hCvarAutofixMaxTries), g_iSurvivorTeamIndex, g_iSurvivorScore, g_iInfectedTeamIndex, g_iInfectedScore);
    
    GetCurrentMap(g_sMapName, sizeof(g_sMapName));
    ServerCommand("changelevel %s", g_sMapName);
}

IsSpectator(client) {
    return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == TEAM_SPECTATOR;
}

bool:CanStartVote(client) {
    if (IsSpectator(client)) {
        PrintToChat(client, "\x01[\x04Restart Map\x01] Vote can only be started by a player!");
        return false;
    }
    return true;
}

bool:IsFlowBroken() {
    return L4D2Direct_GetMapMaxFlowDistance() == 0;
}

public Action Command_RestartMap(int client, int args)
{
    if (CheckCommandAccess(client, "sm_restartmap", ADMFLAG_KICK, true)) {
        RestartMap();
    }
    else if (CanStartVote(client)) {
        new String:prompt[100];
        Format(prompt, sizeof(prompt), "Restart map? Scores will be preserved.");
        if (StartVote(client, prompt)) {
            FakeClientCommand(client, "Vote Yes");
        }
    }
    return Plugin_Handled;
}

bool:StartVote(client, const String:sVoteHeader[]) {
    if (IsNewBuiltinVoteAllowed()) {
        new iNumPlayers;
        decl players[MaxClients];
        for (new i = 1; i <= MaxClients; i++)
        {
            if (!IsClientConnected(i) || !IsClientInGame(i)) continue;
            if (IsSpectator(i) || IsFakeClient(i)) continue;
            
            players[iNumPlayers++] = i;
        }

        hVote = CreateBuiltinVote(VoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
        SetBuiltinVoteArgument(hVote, sVoteHeader);
        SetBuiltinVoteInitiator(hVote, client);
        SetBuiltinVoteResultCallback(hVote, VoteResultHandler);
        DisplayBuiltinVote(hVote, players, iNumPlayers, 20);
        return true;
    }

    PrintToChat(client, "\x01[\x04Restart Map\x01] Vote cannot be started now.");
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
                DisplayBuiltinVotePass(vote, "Restarting map...");
                PrintToChatAll("\x01[\x04Restart Map\x01] Vote passed! Restarting map...");
                RestartMap();
                return;
            }
        }
    }
    DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
}

stock PrintDebug(const String:Message[], any:...) {
    if (GetConVarBool(g_hCvarDebug)) {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}

/**
 * Sends a message to all clients console.
 *
 * @param format        Formatting rules.
 * @param ...            Variable number of format parameters.
 * @noreturn
 */
stock PrintToConsoleAll(const String:format[], any:...)
{
    decl String:text[192];
    for (new x = 1; x <= MaxClients; x++)
    {
        if (IsClientInGame(x))
        {
            SetGlobalTransTarget(x);
            VFormat(text, sizeof(text), format, 2);
            PrintToConsole(x, text);
        }
    }
} 