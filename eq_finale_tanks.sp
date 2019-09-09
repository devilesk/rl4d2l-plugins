#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>

#define FINALE_STAGE_TANK 8

enum TankSpawningScheme {
    Skip,
    FirstOnEvent,
    SecondOnEvent
};

new Handle:hOnlyFirstEventTankSpawningScheme;
new Handle:hOnlySecondEventTankSpawningScheme;

new TankSpawningScheme:spawnScheme;
new tankCount;

new Handle:g_hCvarDebug = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Finale Tank Manager",
    author = "devilesk, original by Visor",
    description = "Two event tanks, only first event tank, or only second event tank. Does not manage flow tanks.",
    version = "1.0.2",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public OnPluginStart() {
    g_hCvarDebug = CreateConVar("sm_tank_map_debug", "0", "Finale Tank Manager debug mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);

    HookEvent("round_start", EventHook:RoundStartEvent, EventHookMode_PostNoCopy);

    hOnlyFirstEventTankSpawningScheme = CreateTrie();
    hOnlySecondEventTankSpawningScheme = CreateTrie();

    RegServerCmd("tank_map_only_first_event", SetMapOnlyFirstEventSpawningScheme);
    RegServerCmd("tank_map_only_second_event", SetMapOnlySecondEventSpawningScheme);
}

public Action:SetMapOnlyFirstEventSpawningScheme(args) {
    decl String:mapname[64];
    GetCmdArg(1, mapname, sizeof(mapname));
    SetTrieValue(hOnlyFirstEventTankSpawningScheme, mapname, true);
    PrintDebug("[SetMapOnlyFirstEventSpawningScheme] Added: %s", mapname);
}

public Action:SetMapOnlySecondEventSpawningScheme(args) {
    decl String:mapname[64];
    GetCmdArg(1, mapname, sizeof(mapname));
    SetTrieValue(hOnlySecondEventTankSpawningScheme, mapname, true);
    PrintDebug("[SetMapOnlySecondEventSpawningScheme] Added: %s", mapname);
}

public RoundStartEvent() {
    CreateTimer(8.0, ProcessTankSpawn, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:ProcessTankSpawn(Handle:timer) {
    spawnScheme = Skip;
    tankCount = 0;
    
    decl String:mapname[64];
    GetCurrentMap(mapname, sizeof(mapname));
    
    new bool:dummy;
    if (GetTrieValue(hOnlyFirstEventTankSpawningScheme, mapname, dummy)) {
        spawnScheme = FirstOnEvent;
    }
    if (GetTrieValue(hOnlySecondEventTankSpawningScheme, mapname, dummy)) {
        spawnScheme = SecondOnEvent;
    }

    PrintDebug("[ProcessTankSpawn] mapname: %s, spawnScheme: %i", mapname, spawnScheme);
}

public Action:L4D2_OnChangeFinaleStage(&finaleType, const String:arg[]) {
    PrintDebug("[OnChangeFinaleStage] finaleType: %i, tankCount: %i, spawnScheme: %i", finaleType, tankCount, spawnScheme);
    
    if (finaleType == FINALE_STAGE_TANK) {
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

stock PrintDebug(const String:Message[], any:...) {
    if (GetConVarBool(g_hCvarDebug)) {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}