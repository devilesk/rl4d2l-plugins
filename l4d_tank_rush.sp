#pragma semicolon 1

#include <sourcemod>
#include <left4dhooks>
#include <colors>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#pragma newdecls required

#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define TANK_CHECK_DELAY        0.5 // tank spawn not always detected if too small

const int TANK_ZOMBIE_CLASS = 8;

bool bTankAlive = false;
bool bHooked = false;

int iDistance;

Handle cvar_noTankRush;
Handle g_hCvarDebug = INVALID_HANDLE;

public Plugin myinfo = {
    name = "L4D2 No Tank Rush",
    author = "Jahze, vintik, Sir, devilesk",
    version = "1.7",
    description = "Stops distance points accumulating whilst the tank is alive"
};

public void OnPluginStart() {
    cvar_noTankRush = CreateConVar("l4d_no_tank_rush", "1", "Prevents survivor team from accumulating points whilst the tank is alive");
    g_hCvarDebug = CreateConVar("l4d_no_tank_rush_debug", "0", "L4D2 No Tank Rush debug mode", 0, true, 0.0, true, 1.0);

    HookConVarChange(cvar_noTankRush, NoTankRushChange);
    if (GetConVarBool(cvar_noTankRush)) {
        PluginEnable();
    }
}

public void OnPluginEnd() {
    bHooked = false;
    PluginDisable();
}

public void OnMapStart() {
    bTankAlive = false;
}

void PluginEnable() {
    if ( !bHooked ) {
        HookEvent("round_start", RoundStart);
        HookEvent("tank_spawn", TankSpawn);
        HookEvent("player_death", PlayerDeath);
        
        if ( FindTank() > 0 ) {
            FreezePoints();
        }
        bHooked = true;
    }
}

void PluginDisable() {
    if ( bHooked ) {
        UnhookEvent("round_start", RoundStart);
        UnhookEvent("tank_spawn", TankSpawn);
        UnhookEvent("player_death", PlayerDeath);
        
        bHooked = false;
    }
    UnFreezePoints();
}

public void NoTankRushChange( Handle cvar, const char[] oldValue, const char[] newValue ) {
    if ( StringToInt(newValue) == 0 ) {
        PluginDisable();
    }
    else {
        PluginEnable();
    }
}

public Action RoundStart( Handle event, const char[] name, bool dontBroadcast ) {
    if ( InSecondHalfOfRound() ) {
        UnFreezePoints();
    }
}

public Action TankSpawn( Handle event, const char[] name, bool dontBroadcast ) {
    FreezePoints(true);
}

public Action PlayerDeath( Handle event, const char[] name, bool dontBroadcast ) {
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    if ( IS_VALID_CLIENT(client) && IsTank(client) ) {
        CreateTimer(TANK_CHECK_DELAY, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public void OnClientDisconnect( int client ) {
    if ( IS_VALID_CLIENT(client) && IsTank(client) ) {
        CreateTimer(TANK_CHECK_DELAY, CheckForTanksDelay, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action CheckForTanksDelay( Handle timer ) {
    if ( FindTank() == -1 ) {
        UnFreezePoints(true);
    }
}

void FreezePoints( bool show_message = false ) {
    if ( !bTankAlive ) {
        iDistance = L4D_GetVersusMaxCompletionScore();
        if ( show_message ) CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Tank {default}spawned. {olive}Freezing {default}distance points!");
        L4D_SetVersusMaxCompletionScore(0);
        bTankAlive = true;
        PrintDebug("[FreezePoints] Points frozen. Max completion score value was %i", iDistance);
    }
}

void UnFreezePoints( bool show_message = false ) {
    if ( bTankAlive ) {
        if ( show_message ) CPrintToChatAll("{red}[{default}NoTankRush{red}] {red}Tank {default}is dead. {olive}Unfreezing {default}distance points!");
        PrintDebug("[UnFreezePoints] Unfreezing points. L4D_GetVersusMaxCompletionScore: %i. Points set to %i", L4D_GetVersusMaxCompletionScore(), iDistance);
        L4D_SetVersusMaxCompletionScore(iDistance);
        bTankAlive = false;
    }
}

int FindTank() {
    for ( int i = 1; i <= MaxClients; i++ ) {
        if ( IsTank(i) && IsPlayerAlive(i) ) {
            return i;
        }
    }
    
    return -1;
}

stock void PrintDebug(const char[] Message, any ...) {
    if (GetConVarBool(g_hCvarDebug)) {
        char DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}
