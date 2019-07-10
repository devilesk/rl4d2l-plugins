#pragma semicolon 1

/* This is the "safe zone" around the tank spawn */
#define DEBUG 0

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>
#include <l4d2lib>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#include <left4downtown>

#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))
#define MIN(%0,%1) (((%0) < (%1)) ? (%0) : (%1))

public Plugin:myinfo =
{
	name = "Tank and no Witch ifier!",
	author = "CanadaRox, Sir, devilesk",
	version = "1.0.1",
	description = "Sets a tank spawn and removes witch spawn point on every map"
};

new Handle:g_hVsBossBuffer;
new Handle:g_hVsBossFlowMax;
new Handle:g_hVsBossFlowMin;
new Handle:hStaticTankMaps;

public OnPluginStart()
{
	g_hVsBossBuffer = FindConVar("versus_boss_buffer");
	g_hVsBossFlowMax = FindConVar("versus_boss_flow_max");
	g_hVsBossFlowMin = FindConVar("versus_boss_flow_min");
	hStaticTankMaps = CreateTrie();

	HookEvent("round_start", RoundStartEvent, EventHookMode_PostNoCopy);
	RegServerCmd("static_tank_map", StaticTank_Command);
	RegServerCmd("reset_static_maps", Reset_Command);

#if DEBUG
	RegConsoleCmd("sm_doshit", DoShit_Cmd);
#endif
}

public Action:L4D_OnSpawnWitch(const Float:vector[3], const Float:qangle[3])
{
	return Plugin_Handled;
}

public Action:L4D_OnSpawnWitchBride(const Float:vector[3], const Float:qangle[3])
{
	return Plugin_Handled;
}

public Action:StaticTank_Command(args)
{
	decl String:mapname[64];
	GetCmdArg(1, mapname, sizeof(mapname));
	SetTrieValue(hStaticTankMaps, mapname, true);
#if DEBUG
	PrintToChatAll("Added %s", mapname);
#endif
}

public Action:Reset_Command(args)
{
	ClearTrie(hStaticTankMaps);
}

public RoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.5, AdjustBossFlow);
}

#if DEBUG
public Action:DoShit_Cmd(client, args)
{
	PrintToChatAll("Doing shit!");
	CreateTimer(0.5, AdjustBossFlow);
}
#endif

public Action:AdjustBossFlow(Handle:timer)
{
	if (InSecondHalfOfRound()) return;

	decl String:sCurMap[64];
	decl dummy;
	GetCurrentMap(sCurMap, sizeof(sCurMap));

	new iCvarMinFlow = RoundFloat(GetConVarFloat(g_hVsBossFlowMin) * 100);
	new iCvarMaxFlow = RoundFloat(GetConVarFloat(g_hVsBossFlowMax) * 100);

	// https://jsfiddle.net/c8qdn03e/3/
	new iTankFlow = -1;

	if (!GetTrieValue(hStaticTankMaps, sCurMap, dummy))
	{
#if DEBUG
		PrintToChatAll("Not static tank map");
#endif
		new iMinBanFlow = L4D2_GetMapValueInt("tank_ban_flow_min", 0);
		new iMaxBanFlow = L4D2_GetMapValueInt("tank_ban_flow_max", 0);
		if (iMaxBanFlow <= 0)
		{
			iMaxBanFlow = iCvarMinFlow - 1;
		}
		new iIntervalMin = MAX( iCvarMinFlow, iMinBanFlow );
		new iIntervalMax = MIN( iCvarMaxFlow, iMaxBanFlow );
		new iPreIntervalLength = iIntervalMin - iCvarMinFlow;
		new iPostIntervalLength = iCvarMaxFlow - iIntervalMax;
		new iTankFlowLength = iPreIntervalLength + iPostIntervalLength - 1;

		iTankFlow = GetRandomInt(0, iTankFlowLength);
#if DEBUG
		PrintToChatAll("iCvarMinFlow: %i", iCvarMinFlow);
		PrintToChatAll("iCvarMaxFlow: %i", iCvarMaxFlow);
		PrintToChatAll("iMinBanFlow: %i", iMinBanFlow);
		PrintToChatAll("iMaxBanFlow: %i", iMaxBanFlow);
		PrintToChatAll("iIntervalMin: %i", iIntervalMin);
		PrintToChatAll("iIntervalMax: %i", iIntervalMax);
		PrintToChatAll("iPreIntervalLength: %i", iPreIntervalLength);
		PrintToChatAll("iPostIntervalLength: %i", iPostIntervalLength);
		PrintToChatAll("iTankFlowLength: %i", iTankFlowLength);
		PrintToChatAll("iTankFlow_pre: %i", iTankFlow);
#endif
		if (iPreIntervalLength == 0)
		{
#if DEBUG
			PrintToChatAll("iPreIntervalLength = 0. Adding iMaxBanFlow + 1: %i", iMaxBanFlow + 1);
#endif
			iTankFlow += iMaxBanFlow + 1;
		}
		else
		{
#if DEBUG
			PrintToChatAll("iPreIntervalLength > 0. Adding iCvarMinFlow: %i", iCvarMinFlow);
#endif
			iTankFlow += iCvarMinFlow;
			if (iPostIntervalLength > 0 && iTankFlow >= iIntervalMin)
			{
#if DEBUG
				PrintToChatAll("iPostIntervalLength > 0 and iTankFlow > iIntervalMin. Adding (iIntervalMax - iIntervalMin + 1): %i", iIntervalMax - iIntervalMin + 1);
#endif
				iTankFlow += (iIntervalMax - iIntervalMin + 1);
			}
		}
		
		new Float:fTankFlow = iTankFlow / 100.0;
#if DEBUG
		PrintToChatAll("iTankFlow_post: %i, fTankFlow_post: %f", iTankFlow, fTankFlow);
#endif
		L4D2Direct_SetVSTankToSpawnThisRound(0, true);
		L4D2Direct_SetVSTankToSpawnThisRound(1, true);
		L4D2Direct_SetVSTankFlowPercent(0, fTankFlow);
		L4D2Direct_SetVSTankFlowPercent(1, fTankFlow);
	}
	else
	{
		L4D2Direct_SetVSTankToSpawnThisRound(0, false);
		L4D2Direct_SetVSTankToSpawnThisRound(1, false);
#if DEBUG
		PrintToChatAll("Static tank map");
#endif
	}
    L4D2Direct_SetVSWitchToSpawnThisRound(0, false);
    L4D2Direct_SetVSWitchToSpawnThisRound(1, false);
}

stock Float:GetTankFlow(round)
{
	return L4D2Direct_GetVSTankFlowPercent(round) - Float:GetConVarInt(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}