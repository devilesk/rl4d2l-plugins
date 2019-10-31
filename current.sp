#pragma semicolon 1

#include <sourcemod>
#include <l4d2_direct>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>

#define DEBUG 0
#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))
#define MAX_PRECISION    3
#define MIN_PRECISION    0

new Handle:g_hVsBossBuffer = INVALID_HANDLE;
new Handle:hCvarPrecision = INVALID_HANDLE;

public Plugin:myinfo =
{
    name = "L4D2 Survivor Progress",
    author = "CanadaRox, Visor, Sir, devilesk",
    description = "Print survivor progress in flow percents.",
    version = "2.3.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public OnPluginStart()
{
    RegConsoleCmd("sm_cur", CurrentCmd);
    RegConsoleCmd("sm_current", CurrentCmd);
    g_hVsBossBuffer = FindConVar("versus_boss_buffer");
    hCvarPrecision = CreateConVar("current_precision", "1", "Number of decimal places to display.", FCVAR_PLUGIN, true, float(MIN_PRECISION), true, float(MAX_PRECISION));
}

public Action:CurrentCmd(client, args)
{
    new precision = GetConVarInt(hCvarPrecision);
    if (args) {
        char x[8];
        GetCmdArg(1, x, sizeof(x));
        precision = StringToInt(x);
        if (precision < MIN_PRECISION) precision = MIN_PRECISION;
        if (precision > MAX_PRECISION) precision = MAX_PRECISION;
    }
    new Float:proximity = RoundToNearestN(GetProximity() * 100.0, precision);
    decl String:msg[128];
    Format(msg, sizeof(msg), "\x01Current: \x04%%.%df%%%%", precision);
    PrintToChat(client, msg, proximity);

#if DEBUG
    PrintDebug("Round: %i. Flipped? %i", InSecondHalfOfRound(), GameRules_GetProp("m_bAreTeamsFlipped"));
    PrintDebug("Tank Enabled? %i %i", L4D2Direct_GetVSTankToSpawnThisRound(0), L4D2Direct_GetVSTankToSpawnThisRound(1));
    PrintDebug("Tank Flow %%: %i %i", L4D2Direct_GetVSTankFlowPercent(0), L4D2Direct_GetVSTankFlowPercent(1));
    PrintDebug("Witch Enabled? %i %i", L4D2Direct_GetVSWitchToSpawnThisRound(0), L4D2Direct_GetVSWitchToSpawnThisRound(1));
    PrintDebug("Witch Flow %%: %i %i", L4D2Direct_GetVSWitchFlowPercent(0), L4D2Direct_GetVSWitchFlowPercent(1));
#endif

    return Plugin_Handled;
}

stock Float:RoundToNearestN(Float:value, places) {
    new Float:power = Pow(10.0, float(places));
    return RoundToNearest(value * power) / power;
}

stock Float:GetProximity()
{
    new Float:proximity = GetMaxSurvivorCompletion();
    if (proximity > 1.0) proximity = 1.0;
    if (proximity < 0.0) proximity = 0.0;
    return proximity;
}

stock Float:GetMaxSurvivorCompletion()
{
    new Float:flow = 0.0;
    for (new i = 1; i <= MaxClients; i++)
    {
        if (IsSurvivor(i))
        {
            flow = MAX(flow, L4D2Direct_GetFlowDistance(i));
        }
    }
    return (flow + GetConVarFloat(g_hVsBossBuffer)) / L4D2Direct_GetMapMaxFlowDistance();
}

#if DEBUG
stock PrintDebug(const String:Message[], any:...) {
    decl String:DebugBuff[256];
    VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
    LogMessage(DebugBuff);
    PrintToChatAll(DebugBuff);
}
#endif