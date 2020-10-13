#pragma semicolon 1;

#include <sourcemod>
#include <sdktools>
#include <l4d2util>
#include <left4dhooks>
#include <colors>
#include <readyup>
#include <l4d_tank_control_eq>
#include "includes/finalemaps"

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define MAXSTEAMID              64
#define MAXMAP                  64
#define MAXTANKS                4

new Handle:g_hCvarDebug = INVALID_HANDLE;
new Handle:g_hStaticTankPlayers[MAXTANKS];
new String:g_sQueuedTankSteamId[MAXSTEAMID] = "";
new g_iTankCount = 0;
new bool:g_bRoundStarted = false;

enum strMapType {
    MP_FINALE
};

public Plugin:myinfo = {
    name = "Static Tank Control",
    author = "devilesk",
    description = "Predetermined tank control distribution.",
    version = "0.6.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
}

public OnPluginStart() {
    for ( new i = 0; i < MAXTANKS; i++ ) {
        g_hStaticTankPlayers[i] = CreateTrie();
    }
    
    HookEvent("round_end", EventHook:RoundEnd_Event, EventHookMode_PostNoCopy);
    HookEvent("player_team", EventHook:PlayerTeam_Event, EventHookMode_PostNoCopy);
    
    RegServerCmd("static_tank_control", StaticTankControl_Command);
    RegServerCmd("static_tank_control_tank_num", StaticTankControlTankNum_Command); 
    
    g_hCvarDebug = CreateConVar("static_tank_control_debug", "0", "Whether or not to debug to console", 0);
}

/**
 * Provides a way to set the tank count in case plugin is reloaded after a tank has spawned.
 */
public Action:StaticTankControlTankNum_Command(args) {
    if (args < 1) {
        LogError("[StaticTankControlTankNum_Command] Missing args");
        return;
    }
    
    decl String:sTankNum[16];
    GetCmdArg(1, sTankNum, sizeof(sTankNum));
    new iTankNum = StringToInt(sTankNum);
    if (iTankNum < 1 || iTankNum > MAXTANKS) {
        LogError("[StaticTankControlTankNum_Command] Invalid tank num arg");
        return;
    }
    
    g_iTankCount = iTankNum - 1;
    PrintDebug("[StaticTankControlTankNum_Command] iTankNum: %i, g_iTankCount: %i", iTankNum, g_iTankCount);
}

public Action:StaticTankControl_Command(args) {
    if (args < 2) {
        LogError("[StaticTankControl_Command] Missing args");
        return;
    }
    
    decl String:sTankNum[16];
    GetCmdArg(1, sTankNum, sizeof(sTankNum));
    new iTankNum = StringToInt(sTankNum);
    if (iTankNum < 1 || iTankNum > MAXTANKS) {
        LogError("[StaticTankControl_Command] Invalid tank num arg");
        return;
    }
    
    decl String:sMapName[MAXMAP];
    GetCmdArg(2, sMapName, sizeof(sMapName));
    StrToLower(sMapName);
    new Handle:hSteamIds = CreateArray(MAXSTEAMID);
    SetTrieValue(g_hStaticTankPlayers[iTankNum-1], sMapName, hSteamIds);
    
    decl String:steamId[MAXSTEAMID];
    for ( new i = 3; i <= args; i++ ) {
        GetCmdArg(i, steamId, sizeof(steamId));
        if (strlen(steamId)) {
            PushArrayString(hSteamIds, steamId);
            PrintDebug("[StaticTankControl_Command] Added iTankNum: %i, sMapName: %s steamId: %s", iTankNum, sMapName, steamId);
        }
    }
}

/**
 * When a new game starts, reset the tank pool.
 */
public TankControlEQ_OnTankControlReset() {
    PrintDebug("[TankControlEQ_OnTankControlReset] Resetting tank control.");
    g_sQueuedTankSteamId[0] = '\0';
    g_iTankCount = 0;
}

public OnRoundStart() {
    g_bRoundStarted = true;
    g_iTankCount = 0;
    g_sQueuedTankSteamId[0] = '\0';
}

public RoundEnd_Event(Handle:event, const String:name[], bool:dontBroadcast) {
    g_bRoundStarted = false;
}

/**
 * When a player reconnects, check if they are the static tank player
 */
public OnClientConnected(client)  {
    if (!g_bRoundStarted) return;
    decl String:steamId[MAXSTEAMID];
    if (IS_VALID_INFECTED(client)) {
        GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
        if (StrEqual(g_sQueuedTankSteamId, steamId)) {
            PrintDebug("[OnClientConnected] Static tank player reconnected. Setting player as tank. steamId: %s.", steamId);
            TankControlEQ_SetTank(steamId);
        }
    }
}

/**
 * When the queued tank switches to infected, check if they are the static tank player
 */
public PlayerTeam_Event(Handle:event, const String:name[], bool:dontBroadcast) {
    if (!g_bRoundStarted) return;
    decl String:steamId[MAXSTEAMID];
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    if (IS_VALID_INFECTED(client)) {
        GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));
        if (StrEqual(g_sQueuedTankSteamId, steamId)) {
            PrintDebug("[OnClientConnected] Static tank player joined infected. Setting player as tank. steamId: %s.", steamId);
            TankControlEQ_SetTank(steamId);
        }
    }
}

public Action:TankControlEQ_OnChooseTank() {
    if (g_iTankCount >= MAXTANKS) {
        PrintDebug("[TankControlEQ_OnChooseTank] g_iTankCount: %i tanks spawned >= MAXTANKS %i. Continuing with default tank selection.", g_iTankCount, MAXTANKS);
        return Plugin_Continue;
    }
    
    new Handle:hStaticTankPlayers;
    
    decl String:sMapName[MAXMAP];
    GetCurrentMapLower(sMapName, sizeof(sMapName));
    PrintDebug("[TankControlEQ_OnChooseTank] Attempting to find static tank player for map %s tank %i.", sMapName, g_iTankCount + 1);
    
    // check that there is a static tank list for the current tank spawn on this map
    if (!GetTrieValue(g_hStaticTankPlayers[g_iTankCount], sMapName, hStaticTankPlayers)) {
        PrintDebug("[TankControlEQ_OnChooseTank] Map %s for tank %i not found. Continuing with default tank selection.", sMapName, g_iTankCount + 1);
        return Plugin_Continue;
    }
    
    // check static tank list not empty
    new iStaticTankPlayersSize = GetArraySize(hStaticTankPlayers);
    if (!iStaticTankPlayersSize) {
        PrintDebug("[TankControlEQ_OnChooseTank] Static tank players size: %i. Continuing with default tank selection.", iStaticTankPlayersSize);
        return Plugin_Continue;
    }

    // if finale and someone has not played tank, then use default tank selection
    new Handle:hWhosNotHadTank = TankControlEQ_GetWhosNotHadTank();
    new iWhosNotHadTankSize = GetArraySize(hWhosNotHadTank);
    if (IsMissionFinalMap() && iWhosNotHadTankSize > 0) {
        PrintDebug("[TankControlEQ_OnChooseTank] Finale with %i skipped tank player. Continuing with default tank selection.", iWhosNotHadTankSize);
        CloseHandle(hWhosNotHadTank);
        return Plugin_Continue;
    }
    CloseHandle(hWhosNotHadTank);

    // find a static tank player in the pool of tank players
    new Handle:hTankPool = TankControlEQ_GetTankPool();
    new String:sSteamId[MAXSTEAMID];
    if (FindSteamIdInArrays(sSteamId, sizeof(sSteamId), hTankPool, hStaticTankPlayers)) {
        strcopy(g_sQueuedTankSteamId, sizeof(g_sQueuedTankSteamId), sSteamId); // store static tank player in case they disconnect or change teams
        PrintDebug("[TankControlEQ_OnChooseTank] Setting tank to %s.", sSteamId);
        TankControlEQ_SetTank(sSteamId);
        CloseHandle(hTankPool);
        return Plugin_Handled;
    }
    
    PrintDebug("[TankControlEQ_OnChooseTank] No static tank player in tank pool. Continuing with default tank selection.");
    CloseHandle(hTankPool);
    return Plugin_Continue;
}

public bool FindSteamIdInArrays(String:buffer[], bufferLen, Handle:hArrayA, Handle:hArrayB) {
    decl String:sSteamIdA[MAXSTEAMID];
    decl String:sSteamIdB[MAXSTEAMID];
    for (new i = 0; i < GetArraySize(hArrayA); i++) {
        GetArrayString(hArrayA, i, sSteamIdA, sizeof(sSteamIdA));
        for (new j = 0; j < GetArraySize(hArrayB); j++) {
            GetArrayString(hArrayB, j, sSteamIdB, sizeof(sSteamIdB));
            if (StrEqual(sSteamIdA, sSteamIdB)) {
                strcopy(buffer, bufferLen, sSteamIdA);
                PrintDebug("[FindSteamIdInArrays] Match found. steamId: %s. buffer: %s", sSteamIdA, buffer);
                return true;
            }
        }
    }
    PrintDebug("[FindSteamIdInArrays] Match not found.");
    return false;
}

public TankControlEQ_OnTankGiven(const String:steamId[]) {
    // stop storing static tank player once they've been given tank
    if (StrEqual(g_sQueuedTankSteamId, steamId))
        g_sQueuedTankSteamId[0] = '\0';

    g_iTankCount++;
    
    PrintDebug("[TankControlEQ_OnTankGiven] Gave tank %i to %s.", g_iTankCount, steamId);
}

/**
 * Retrieves a valid infected player's client index by their steam id.
 * 
 * @param const String:steamId[]
 *     The steam id to look for.
 * 
 * @return
 *     The player's client index.
 */
public GetValidInfectedClientBySteamId(const String:steamId[]) {
    decl String:tmpSteamId[MAXSTEAMID];
   
    for (new i = 1; i <= MaxClients; i++) {
        if (!IS_VALID_INFECTED(i))
            continue;
        
        GetClientAuthId(i, AuthId_Steam2, tmpSteamId, sizeof(tmpSteamId));
        
        if (StrEqual(steamId, tmpSteamId))
            return i;
    }
    
    return -1;
}

stock PrintDebug(const String:Message[], any:...) {
    if (GetConVarBool(g_hCvarDebug)) {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
        for (new x = 1; x <= MaxClients; x++) { 
            if (IsClientInGame(x)) {
                SetGlobalTransTarget(x); 
                PrintToConsole(x, DebugBuff); 
            } 
        }
    }
}