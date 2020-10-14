#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#include "includes/rl4d2l_util"

#pragma newdecls required

#define FINALE_GAUNTLET_1               0
#define FINALE_HORDE_ATTACK_1           1
#define FINALE_HALFTIME_BOSS            2
#define FINALE_GAUNTLET_2               3
#define FINALE_HORDE_ATTACK_2           4
#define FINALE_FINAL_BOSS               5
#define FINALE_HORDE_ESCAPE             6
#define FINALE_CUSTOM_PANIC             7
#define FINALE_CUSTOM_TANK              8
#define FINALE_CUSTOM_SCRIPTED          9
#define FINALE_CUSTOM_DELAY             10
#define FINALE_CUSTOM_CLEAROUT          11
#define FINALE_GAUNTLET_START           12
#define FINALE_GAUNTLET_HORDE           13
#define FINALE_GAUNTLET_HORDE_BONUSTIME 14
#define FINALE_GAUNTLET_BOSS_INCOMING   15
#define FINALE_GAUNTLET_BOSS            16
#define FINALE_GAUNTLET_ESCAPE          17

enum TankSpawningScheme {
    Skip,
    FirstOnEvent,
    SecondOnEvent
};

StringMap hOnlyFirstEventTankSpawningScheme;
StringMap hOnlySecondEventTankSpawningScheme;

TankSpawningScheme spawnScheme;
int tankCount;

Handle g_hCvarDebug = INVALID_HANDLE;

public Plugin myinfo = {
    name = "Finale Tank Manager",
    author = "Visor, Sir, Electr0, devilesk",
    description = "Two event tanks, only first event tank, or only second event tank. Does not manage flow tanks.",
    version = "1.1.3",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public void OnPluginStart() {
    g_hCvarDebug = CreateConVar("sm_tank_map_debug", "0", "Finale Tank Manager debug mode", 0, true, 0.0, true, 1.0);

    HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);

    hOnlyFirstEventTankSpawningScheme = new StringMap();
    hOnlySecondEventTankSpawningScheme = new StringMap();

    RegServerCmd("tank_map_only_first_event", SetMapOnlyFirstEventSpawningScheme);
    RegServerCmd("tank_map_only_second_event", SetMapOnlySecondEventSpawningScheme);
}

public Action SetMapOnlyFirstEventSpawningScheme(int args) {
    char mapname[64];
    GetCmdArg(1, mapname, sizeof(mapname));
    StrToLower(mapname);
    SetTrieValue(hOnlyFirstEventTankSpawningScheme, mapname, true);
    PrintDebug("[SetMapOnlyFirstEventSpawningScheme] Added: %s", mapname);
}

public Action SetMapOnlySecondEventSpawningScheme(int args) {
    char mapname[64];
    GetCmdArg(1, mapname, sizeof(mapname));
    StrToLower(mapname);
    hOnlySecondEventTankSpawningScheme.SetValue(mapname, true);
    PrintDebug("[SetMapOnlySecondEventSpawningScheme] Added: %s", mapname);
}

public Action RoundStartEvent(Handle hEvent, const char[] name, bool dontBroadcast) {
    CreateTimer(8.0, ProcessTankSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action ProcessTankSpawn(Handle timer) {
    spawnScheme = Skip;
    tankCount = 0;
    
    char mapname[64];
    GetCurrentMapLower(mapname, sizeof(mapname));
    
    bool dummy;
    if (hOnlyFirstEventTankSpawningScheme.GetValue(mapname, dummy)) {
        spawnScheme = FirstOnEvent;
    }
    if (hOnlySecondEventTankSpawningScheme.GetValue(mapname, dummy)) {
        spawnScheme = SecondOnEvent;
    }

    PrintDebug("[ProcessTankSpawn] mapname: %s, spawnScheme: %i", mapname, spawnScheme);
}

public Action L4D2_OnChangeFinaleStage(int &finaleType, const char[] arg) {
    PrintDebug("[OnChangeFinaleStage] finaleType: %i, tankCount: %i, spawnScheme: %i", finaleType, tankCount, spawnScheme);
    
    if (spawnScheme != Skip && (finaleType == FINALE_CUSTOM_TANK || finaleType == FINALE_GAUNTLET_BOSS || finaleType == FINALE_GAUNTLET_ESCAPE)) {
        tankCount++;

        if (spawnScheme == FirstOnEvent && tankCount != 1) {
            PrintDebug("[OnChangeFinaleStage] Blocking finale tank %i", tankCount);
            return Plugin_Handled;
        }
        if (spawnScheme == SecondOnEvent && tankCount != 2) {
            PrintDebug("[OnChangeFinaleStage] Blocking finale tank %i", tankCount);
            return Plugin_Handled;
        }
    }
    return Plugin_Continue;
}

stock void PrintDebug(const char[] Message, any ...) {
    if (GetConVarBool(g_hCvarDebug)) {
        char DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}