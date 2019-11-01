#pragma semicolon 1

#include <sourcemod>
#include <l4d2_direct>
#include <left4downtown>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#define DEBUG 0

new Handle:g_hCvarDebug = INVALID_HANDLE;
new Handle:g_hVsBossBuffer = INVALID_HANDLE;
new Address:g_pTankSpawnNav = Address_Null;
new bool:g_bFirstFlowTankSpawned = false;
new Float:g_fTankSpawnOrigin[3];
new Float:g_fNavAreaFlow;
new Float:g_fMapMaxFlowDistance;
new Float:g_fTankFlow;

public Plugin:myinfo = {
    name = "L4D2 Tank Spawn Fix",
    author = "devilesk",
    version = "1.0.2",
    description = "Fixes inconsistent tank spawns between rounds.",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public OnPluginStart() {
    g_hCvarDebug = CreateConVar("sm_tank_spawn_fix_debug", "1", "Tank Spawn Fix debug mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hVsBossBuffer = FindConVar("versus_boss_buffer");
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    if (!InSecondHalfOfRound()) g_bFirstFlowTankSpawned = false;

    // Delayed flow check due to L4D2Direct_GetMapMaxFlowDistance not returning a consistent value if called immediately on round start
    CreateTimer(8.0, CheckFlow, _, TIMER_FLAG_NO_MAPCHANGE);
}

/*
 * Calculates what the second round tank flow should be based off the nav area stored from the first round flow tank spawn.
 * If the flow returned from the nav area has changed between rounds or the max map flow distance has changed between rounds,
 * then update the second round flow tank percent.
 */
public Action:CheckFlow(Handle:timer) {
    PrintDebug("[CheckFlow] Round: %i. Round 2 Tank Enabled: %i. FirstFlowTankSpawned: %i.", InSecondHalfOfRound(), L4D2Direct_GetVSTankToSpawnThisRound(1), g_bFirstFlowTankSpawned);

    // only check second round flow tanks if enabled and first round flow tank spawned
    if (!InSecondHalfOfRound() || !L4D2Direct_GetVSTankToSpawnThisRound(1) || !g_bFirstFlowTankSpawned) return;

    // get nav area that spawned first round flow tank
    new Address:pTankSpawnNav = L4D2Direct_GetTerrorNavArea(g_fTankSpawnOrigin);
    if (pTankSpawnNav == Address_Null) return;

    // calculate tank flow from the nav area
    new Float:fMapMaxFlowDistance = L4D2Direct_GetMapMaxFlowDistance();
    new Float:fNavAreaFlow = L4D2Direct_GetTerrorNavAreaFlow(pTankSpawnNav);
    new Float:fTankFlow = (fNavAreaFlow + GetConVarFloat(g_hVsBossBuffer)) / fMapMaxFlowDistance;

    PrintDebug("[CheckFlow] NavArea: %i %i %i", g_pTankSpawnNav, pTankSpawnNav, g_pTankSpawnNav == pTankSpawnNav);
    PrintDebug("[CheckFlow] NavAreaFlow: %f %f %i", g_fNavAreaFlow, fNavAreaFlow, g_fNavAreaFlow == fNavAreaFlow);
    PrintDebug("[CheckFlow] TankFlow: %f %f %i", g_fTankFlow, fTankFlow, g_fTankFlow == fTankFlow);
    PrintDebug("[CheckFlow] MapFlowDist: %f %f %i", g_fMapMaxFlowDistance, fMapMaxFlowDistance, g_fMapMaxFlowDistance == fMapMaxFlowDistance);
    
    // update tank flow if nav area flows or map distances don't match between rounds or if the tank flow randomly changes during rounds
    if (g_fNavAreaFlow != fNavAreaFlow || g_fMapMaxFlowDistance != fMapMaxFlowDistance || L4D2Direct_GetVSTankFlowPercent(0) != L4D2Direct_GetVSTankFlowPercent(1)) {
        PrintDebug("[CheckFlow] Fixing tank flow.");
        L4D2Direct_SetVSTankFlowPercent(1, fTankFlow);
    }
    else {
        PrintDebug("[CheckFlow] Tank flow match.");
    }
    PrintDebug("[CheckFlow] VSTankFlow: %f %f %i", L4D2Direct_GetVSTankFlowPercent(0), L4D2Direct_GetVSTankFlowPercent(1), L4D2Direct_GetVSTankFlowPercent(0) == L4D2Direct_GetVSTankFlowPercent(1));
}

/*
 * Store the nav area that triggered the first round flow tank spawn along with other flow info
 */
public Action:L4D_OnSpawnTank(const Float:vector[3], const Float:qangle[3]) {
    if (!InSecondHalfOfRound() && L4D2Direct_GetVSTankToSpawnThisRound(0) && !g_bFirstFlowTankSpawned) {
        GetMaxSurvivorNavInfo(g_pTankSpawnNav, g_fTankSpawnOrigin, g_fNavAreaFlow, g_fMapMaxFlowDistance, g_fTankFlow);
        g_bFirstFlowTankSpawned = true;
    }
#if DEBUG
    if (InSecondHalfOfRound() && L4D2Direct_GetVSTankToSpawnThisRound(1)) {
        new Address:pNavArea, Float:origin[3], Float:fNavAreaFlow, Float:fMapMaxFlowDistance, Float:fTankFlow;
        GetMaxSurvivorNavInfo(pNavArea, origin, fNavAreaFlow, fMapMaxFlowDistance, fTankFlow);
    }
#endif
}

/*
 * Stores the nav area and flow info of the survivor with highest flow
 */
public GetMaxSurvivorNavInfo(&Address:pNavArea, Float:origin[], &Float:fNavAreaFlow, &Float:fMapMaxFlowDistance, &Float:fTankFlow)
{
    fNavAreaFlow = 0.0;
    new Float:tmp_flow;
    decl Float:tmp_origin[3];
    new Address:tmp_pNavArea;
    for (new client = 1; client <= MaxClients; client++) {
        if(IsSurvivor(client)) {
            GetClientAbsOrigin(client, tmp_origin);
            tmp_pNavArea = L4D2Direct_GetTerrorNavArea(tmp_origin);
            if (tmp_pNavArea != Address_Null) {
                tmp_flow = L4D2Direct_GetTerrorNavAreaFlow(tmp_pNavArea);
                if (tmp_flow > fNavAreaFlow) {
                    pNavArea = tmp_pNavArea;
                    fNavAreaFlow = tmp_flow;
                    origin[0] = tmp_origin[0];
                    origin[1] = tmp_origin[1];
                    origin[2] = tmp_origin[2];
                }
            }
        }
    }
    fMapMaxFlowDistance = L4D2Direct_GetMapMaxFlowDistance();
    fTankFlow = (fNavAreaFlow + GetConVarFloat(g_hVsBossBuffer)) / fMapMaxFlowDistance;

    PrintDebug("[MaxSurvNav] Round: %i", InSecondHalfOfRound());
    PrintDebug("[MaxSurvNav] Origin: %f %f %f", origin[0], origin[1], origin[2]);
    PrintDebug("[MaxSurvNav] NavArea: %i", pNavArea);
    PrintDebug("[MaxSurvNav] NavAreaFlow: %f", fNavAreaFlow);
    PrintDebug("[MaxSurvNav] TankFlow: %f", fTankFlow);
    PrintDebug("[MaxSurvNav] MapFlowDist: %f", fMapMaxFlowDistance);
    PrintDebug("[MaxSurvNav] VSTankFlow: %f. Round: %i", L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()), InSecondHalfOfRound());
}

stock PrintDebug(const String:Message[], any:...) {
    if (GetConVarBool(g_hCvarDebug)) {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
#if DEBUG
        PrintToChatAll(DebugBuff);
#endif
    }
}