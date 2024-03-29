#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#include <readyup>
#include <pause>
#include <colors>
#undef REQUIRE_PLUGIN
#include <l4d2_hybrid_scoremod_zone>

#pragma newdecls required

#define SPECHUD_DRAW_INTERVAL   0.5

#define ZOMBIECLASS_NAME(%0) (L4D2_InfectedNames[view_as<int>(%0)-1])

enum L4D2WeaponSlot
{
	L4D2WeaponSlot_Primary,
	L4D2WeaponSlot_Secondary,
	L4D2WeaponSlot_Throwable,
	L4D2WeaponSlot_HeavyHealthItem,
	L4D2WeaponSlot_LightHealthItem
};

enum L4D2Gamemode
{
	L4D2Gamemode_None,
	L4D2Gamemode_Versus,
	L4D2Gamemode_Scavenge
};

Handle survivor_limit;
Handle z_max_player_zombies;

bool bSpecHudActive[MAXPLAYERS + 1];
bool bSpecHudHintShown[MAXPLAYERS + 1];
bool bTankHudActive[MAXPLAYERS + 1];
bool bTankHudHintShown[MAXPLAYERS + 1];
bool hybridScoringAvailable;

public Plugin myinfo = 
{
	name = "Hyper-V HUD Manager [Public Version]",
	author = "Visor, Sir, devilesk",
	description = "Provides different HUDs for spectators",
	version = "3.2.1",
	url = "https://github.com/devilesk/rl4d2l-plugins"
};

public void OnPluginStart() 
{
	survivor_limit = FindConVar("survivor_limit");
	z_max_player_zombies = FindConVar("z_max_player_zombies");

	RegConsoleCmd("sm_spechud", ToggleSpecHudCmd);
	RegConsoleCmd("sm_tankhud", ToggleTankHudCmd);

	CreateTimer(SPECHUD_DRAW_INTERVAL, HudDrawTimer, _, TIMER_REPEAT);
}

public void OnAllPluginsLoaded()
{
	hybridScoringAvailable = LibraryExists("l4d2_hybrid_scoremod_zone") || LibraryExists("l4d2_hybrid_scoremod");
}
public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "l4d2_hybrid_scoremod_zone", true))
	{
		hybridScoringAvailable = false;
	}
	if (StrEqual(name, "l4d2_hybrid_scoremod", true))
	{
		hybridScoringAvailable = false;
	}
}
public void OnLibraryAdded(const char[] name)
{
	if (StrEqual(name, "l4d2_hybrid_scoremod_zone", true))
	{
		hybridScoringAvailable = true;
	}
	if (StrEqual(name, "l4d2_hybrid_scoremod", true))
	{
		hybridScoringAvailable = true;
	}
}

public void OnClientConnected(int client)
{
	bSpecHudActive[client] = false;
	bSpecHudHintShown[client] = false;
	bTankHudActive[client] = true;
	bTankHudHintShown[client] = false;
}

public Action ToggleSpecHudCmd(int client, int args) 
{
	bSpecHudActive[client] = !bSpecHudActive[client];
	CPrintToChat(client, "<{olive}HUD{default}> Spectator HUD is now %s.", (bSpecHudActive[client] ? "{blue}on{default}" : "{red}off{default}"));
}

public Action ToggleTankHudCmd(int client, int args) 
{
	bTankHudActive[client] = !bTankHudActive[client];
	CPrintToChat(client, "<{olive}HUD{default}> Tank HUD is now %s.", (bTankHudActive[client] ? "{blue}on{default}" : "{red}off{default}"));
}

public Action HudDrawTimer(Handle hTimer) 
{
	if (IsInReady() || IsInPause())
		return Plugin_Handled;

	bool bSpecsOnServer = false;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsSpectator(i))
		{
			bSpecsOnServer = true;
			break;
		}
	}

	if (bSpecsOnServer) // Only bother if someone's watching us
	{
		Handle specHud = CreatePanel();

		FillHeaderInfo(specHud);
		FillSurvivorInfo(specHud);
		FillInfectedInfo(specHud);
		FillTankInfo(specHud);
		FillGameInfo(specHud);

		for (int i = 1; i <= MaxClients; i++) 
		{
			if (!bSpecHudActive[i] || !IsSpectator(i) || IsFakeClient(i))
				continue;

			SendPanelToClient(specHud, i, DummySpecHudHandler, 3);
			if (!bSpecHudHintShown[i])
			{
				bSpecHudHintShown[i] = true;
				CPrintToChat(i, "<{olive}HUD{default}> Type {green}!spechud{default} into chat to toggle the {blue}Spectator HUD{default}.");
			}
		}

		delete specHud;
	}
	
	Handle tankHud = CreatePanel();
	if (!FillTankInfo(tankHud, true)) // No tank -- no HUD
	{
		delete tankHud;
		return Plugin_Handled;
	}

	for (int i = 1; i <= MaxClients; i++) 
	{
		if (!bTankHudActive[i] || !IsClientInGame(i) || IsFakeClient(i) || IsSurvivor(i) || (bSpecHudActive[i] && IsSpectator(i)))
			continue;

		SendPanelToClient(tankHud, i, DummyTankHudHandler, 3);
		if (!bTankHudHintShown[i])
		{
			bTankHudHintShown[i] = true;
			CPrintToChat(i, "<{olive}HUD{default}> Type {green}!tankhud{default} into chat to toggle the {red}Tank HUD{default}.");
		}
	}

	delete tankHud;
	return Plugin_Continue;
}

public int DummySpecHudHandler(Handle hMenu, MenuAction action, int param1, int param2) {}
public int DummyTankHudHandler(Handle hMenu, MenuAction action, int param1, int param2) {}

void FillHeaderInfo(Handle hSpecHud) 
{
	DrawPanelText(hSpecHud, "Spectator HUD");

	char buffer[512];
	Format(buffer, sizeof(buffer), "Slots %i/%i | Tickrate %i", GetRealClientCount(), GetConVarInt(FindConVar("sv_maxplayers")), RoundToNearest(1.0 / GetTickInterval()));
	DrawPanelText(hSpecHud, buffer);
}

void GetMeleePrefix(int client, char[] prefix, int length) 
{
	int secondary = GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Secondary));
	WeaponId secondaryWep = IdentifyWeapon(secondary);

	char buf[4];
	switch (secondaryWep)
	{
		case WEPID_NONE: buf = "N";
		case WEPID_PISTOL: buf = (GetEntProp(secondary, Prop_Send, "m_isDualWielding") ? "DP" : "P");
		case WEPID_MELEE: buf = "M";
		case WEPID_PISTOL_MAGNUM: buf = "DE";
		default: buf = "?";
	}

	strcopy(prefix, length, buf);
}

void FillSurvivorInfo(Handle hSpecHud) 
{
	char info[512];
	char buffer[64];
	char name[MAX_NAME_LENGTH];

	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->1. Survivors");

	int survivorCount;
	for (int client = 1; client <= MaxClients && survivorCount < GetConVarInt(survivor_limit); client++) 
	{
		if (!IsSurvivor(client))
			continue;

		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client))
		{
			Format(info, sizeof(info), "%s: Dead", name);
		}
		else
		{
			WeaponId primaryWep = IdentifyWeapon(GetPlayerWeaponSlot(client, view_as<int>(L4D2WeaponSlot_Primary)));
			GetLongWeaponName(primaryWep, info, sizeof(info));
			GetMeleePrefix(client, buffer, sizeof(buffer)); 
			Format(info, sizeof(info), "%s/%s", info, buffer);

			if (IsSurvivorHanging(client))
			{
				Format(info, sizeof(info), "%s: %iHP <Hanging> [%s]", name, GetSurvivorHealth(client), info);
			}
			else if (IsIncapacitated(client))
			{
				Format(info, sizeof(info), "%s: %iHP <Incapped(#%i)> [%s]", name, GetSurvivorHealth(client), (GetSurvivorIncapCount(client) + 1), info);
			}
			else
			{
				int health = GetSurvivorHealth(client) + GetSurvivorTemporaryHealth(client);
				int incapCount = GetSurvivorIncapCount(client);
				if (incapCount == 0)
				{
					Format(info, sizeof(info), "%s: %iHP [%s]", name, health, info);
				}
				else
				{
					Format(buffer, sizeof(buffer), "%i incap%s", incapCount, (incapCount > 1 ? "s" : ""));
					Format(info, sizeof(info), "%s: %iHP (%s) [%s]", name, health, buffer, info);
				}
			}
		}

		survivorCount++;
		DrawPanelText(hSpecHud, info);
	}
	if (hybridScoringAvailable)
	{
		int healthBonus = SMPlus_GetHealthBonus();
		int damageBonus = SMPlus_GetDamageBonus();
		int pillsBonus = SMPlus_GetPillsBonus();
		DrawPanelText(hSpecHud, " ");
		Format(info, 512, "HB: %i <%.1f%%>", healthBonus, ToPercent(healthBonus, SMPlus_GetMaxHealthBonus()));
		DrawPanelText(hSpecHud, info);
		Format(info, 512, "DB: %i <%.1f%%>", damageBonus, ToPercent(damageBonus, SMPlus_GetMaxDamageBonus()));
		DrawPanelText(hSpecHud, info);
		Format(info, 512, "Pills: %i <%.1f%%>", pillsBonus, ToPercent(pillsBonus, SMPlus_GetMaxPillsBonus()));
		DrawPanelText(hSpecHud, info);
	}
}

void FillInfectedInfo(Handle hSpecHud)
{
	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->2. Infected");

	char info[512];
	char buffer[32];
	char name[MAX_NAME_LENGTH];

	int infectedCount;
	for (int client = 1; client <= MaxClients && infectedCount < GetConVarInt(z_max_player_zombies); client++) 
	{
		if (!IsInfected(client))
			continue;

		GetClientFixedName(client, name, sizeof(name));
		if (!IsPlayerAlive(client)) 
		{
			CountdownTimer spawnTimer = L4D2Direct_GetSpawnTimer(client);
			float timeLeft = -1.0;
			if (spawnTimer != CTimer_Null)
			{
				timeLeft = CTimer_GetRemainingTime(spawnTimer);
			}

			if (timeLeft < 0.0)
			{
				Format(info, sizeof(info), "%s: Dead", name);
			}
			else
			{
				Format(buffer, sizeof(buffer), "%is", RoundToNearest(timeLeft));
				Format(info, sizeof(info), "%s: Dead (%s)", name, (RoundToNearest(timeLeft) ? buffer : "Spawning..."));
			}
		}
		else 
		{
			L4D2_Infected zClass = GetInfectedClass(client);
			if (zClass == L4D2Infected_Tank)
				continue;

			if (IsInfectedGhost(client))
			{
				// TO-DO: Handle a case of respawning chipped SI, show the ghost's health
				Format(info, sizeof(info), "%s: %s (Ghost)", name, ZOMBIECLASS_NAME(zClass));
			}
			else if (GetEntityFlags(client) & FL_ONFIRE)
			{
				Format(info, sizeof(info), "%s: %s (%iHP) [On Fire]", name, ZOMBIECLASS_NAME(zClass), GetClientHealth(client));
			}
			else
			{
				Format(info, sizeof(info), "%s: %s (%iHP)", name, ZOMBIECLASS_NAME(zClass), GetClientHealth(client));
			}
		}

		infectedCount++;
		DrawPanelText(hSpecHud, info);
	}
	
	if (!infectedCount)
	{
		DrawPanelText(hSpecHud, "There are no SI at this moment.");
	}
}

bool FillTankInfo(Handle hSpecHud, bool bTankHUD = false)
{
	int tank = FindTank();
	if (tank == -1)
		return false;

	char info[512];
	char name[MAX_NAME_LENGTH];

	if (bTankHUD)
	{
		GetConVarString(FindConVar("l4d_ready_cfg_name"), info, sizeof(info));
		Format(info, sizeof(info), "%s :: Tank HUD", info);
		DrawPanelText(hSpecHud, info);
		DrawPanelText(hSpecHud, "___________________");
	}
	else
	{
		DrawPanelText(hSpecHud, " ");
		DrawPanelText(hSpecHud, "->3. Tank");
	}

	// Draw owner & pass counter
	int passCount = L4D2Direct_GetTankPassedCount();
	switch (passCount)
	{
		case 0: Format(info, sizeof(info), "native");
		case 1: Format(info, sizeof(info), "%ist", passCount);
		case 2: Format(info, sizeof(info), "%ind", passCount);
		case 3: Format(info, sizeof(info), "%ird", passCount);
		default: Format(info, sizeof(info), "%ith", passCount);
	}

	if (!IsFakeClient(tank))
	{
		GetClientFixedName(tank, name, sizeof(name));
		Format(info, sizeof(info), "Control : %s (%s)", name, info);
	}
	else
	{
		Format(info, sizeof(info), "Control : AI (%s)", info);
	}
	DrawPanelText(hSpecHud, info);

	// Draw health
	int health = GetClientHealth(tank);
	if (health <= 0 || IsIncapacitated(tank) || !IsPlayerAlive(tank))
	{
		info = "Health  : Dead";
	}
	else
	{
		int healthPercent = RoundFloat((100.0 / (GetConVarFloat(FindConVar("z_tank_health")) * 1.5)) * health);
		Format(info, sizeof(info), "Health  : %i / %i%%", health, ((healthPercent < 1) ? 1 : healthPercent));
	}
	DrawPanelText(hSpecHud, info);

	// Draw frustration
	if (!IsFakeClient(tank))
	{
		Format(info, sizeof(info), "Frustr.  : %d%%", GetTankFrustration(tank));
	}
	else
	{
		info = "Frustr.  : AI";
	}
	DrawPanelText(hSpecHud, info);

	// Draw fire status
	if (GetEntityFlags(tank) & FL_ONFIRE)
	{
		int timeleft = RoundToCeil(health / 80.0);
		Format(info, sizeof(info), "On Fire : %is", timeleft);
		DrawPanelText(hSpecHud, info);
	}

	return true;
}

void FillGameInfo(Handle hSpecHud)
{
	// Turns out too much info actually CAN be bad, funny ikr
	int tank = FindTank();
	if (tank != -1)
		return;

	DrawPanelText(hSpecHud, " ");
	DrawPanelText(hSpecHud, "->3. Game");

	char info[512];
	char buffer[512];

	GetConVarString(FindConVar("l4d_ready_cfg_name"), info, sizeof(info));

	if (GetCurrentGameMode() == L4D2Gamemode_Versus)
	{
		Format(info, sizeof(info), "%s (%s round)", info, (InSecondHalfOfRound() ? "2nd" : "1st"));
		DrawPanelText(hSpecHud, info);

		Format(info, sizeof(info), "Survivor progress: %i%%", RoundToNearest(GetHighestSurvivorFlow() * 100.0));
		DrawPanelText(hSpecHud, info);

		if (RoundHasFlowTank())
		{
			Format(info, sizeof(info), "Tank: %i%% (%i%%)", RoundToNearest(L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) * 100.0), RoundToNearest(GetTankFlow() * 100.0));
			DrawPanelText(hSpecHud, info);
		}

		if (RoundHasFlowWitch())
		{
			Format(info, sizeof(info), "Witch: %i%% (%i%%)", RoundToNearest(L4D2Direct_GetVSWitchFlowPercent(InSecondHalfOfRound()) * 100.0), RoundToNearest(GetWitchFlow() * 100.0));
			DrawPanelText(hSpecHud, info);
		}
	}
	else if (GetCurrentGameMode() == L4D2Gamemode_Scavenge)
	{
		DrawPanelText(hSpecHud, info);

		int round = GetScavengeRoundNumber();
		switch (round)
		{
			case 0: Format(buffer, sizeof(buffer), "N/A");
			case 1: Format(buffer, sizeof(buffer), "%ist", round);
			case 2: Format(buffer, sizeof(buffer), "%ind", round);
			case 3: Format(buffer, sizeof(buffer), "%ird", round);
			default: Format(buffer, sizeof(buffer), "%ith", round);
		}

		Format(info, sizeof(info), "Half: %s", (InSecondHalfOfRound() ? "2nd" : "1st"));
		DrawPanelText(hSpecHud, info);

		Format(info, sizeof(info), "Round: %s", buffer);
		DrawPanelText(hSpecHud, info);
	}
}

/* Stocks */

float ToPercent(int score, int maxbonus)
{
	return score < 1 ? 0.0 : float(score) / float(maxbonus) * 100.0;
}

void GetClientFixedName(int client, char[] name, int length) 
{
	GetClientName(client, name, length);

	if (name[0] == '[') 
	{
		char temp[MAX_NAME_LENGTH];
		strcopy(temp, sizeof(temp), name);
		temp[sizeof(temp)-2] = 0;
		strcopy(name[1], length-1, temp);
		name[0] = ' ';
	}

	if (strlen(name) > 25) 
	{
		name[22] = name[23] = name[24] = '.';
		name[25] = 0;
	}
}

int GetRealClientCount() 
{
	int clients = 0;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i)) clients++;
	}
	return clients;
}

int GetScavengeRoundNumber()
{
	return GameRules_GetProp("m_nRoundNumber");
}

float GetClientFlow(int client)
{
	return (L4D2Direct_GetFlowDistance(client) / L4D2Direct_GetMapMaxFlowDistance());
}

float GetHighestSurvivorFlow()
{
	float flow;
	float maxflow = 0.0;
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsSurvivor(i))
		{
			flow = GetClientFlow(i);
			if (flow > maxflow)
			{
				maxflow = flow;
			}
		}
	}
	return maxflow;
}

bool RoundHasFlowTank()
{
	return L4D2Direct_GetVSTankToSpawnThisRound(InSecondHalfOfRound());
}

bool RoundHasFlowWitch()
{
	return L4D2Direct_GetVSWitchToSpawnThisRound(InSecondHalfOfRound());
}

float GetTankFlow() 
{
	return L4D2Direct_GetVSTankFlowPercent(InSecondHalfOfRound()) -
		(GetConVarFloat(FindConVar("versus_boss_buffer")) / L4D2Direct_GetMapMaxFlowDistance());
}

float GetWitchFlow() 
{
	return L4D2Direct_GetVSWitchFlowPercent(InSecondHalfOfRound()) -
		(GetConVarFloat(FindConVar("versus_boss_buffer")) / L4D2Direct_GetMapMaxFlowDistance());
}

bool IsSpectator(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 1;
}

int FindTank() 
{
	for (int i = 1; i <= MaxClients; i++) 
	{
		if (IsInfected(i) && GetInfectedClass(i) == L4D2Infected_Tank && IsPlayerAlive(i))
			return i;
	}

	return -1;
}

bool IsSurvivorHanging(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isHangingFromLedge") | GetEntProp(client, Prop_Send, "m_isFallingFromLedge"));
}

int GetSurvivorHealth(int client)
{
	return GetEntProp(client, Prop_Send, "m_iHealth");
}

L4D2Gamemode GetCurrentGameMode()
{
	static char sGameMode[32];
	if (sGameMode[0] == EOS)
	{
		GetConVarString(FindConVar("mp_gamemode"), sGameMode, sizeof(sGameMode));
	}
	if (StrContains(sGameMode, "scavenge") > -1)
	{
		return L4D2Gamemode_Scavenge;
	}
	if (StrContains(sGameMode, "versus") > -1
		|| StrEqual(sGameMode, "mutation12")) // realism versus
	{
		return L4D2Gamemode_Versus;
	}
	else
	{
		return L4D2Gamemode_None; // Unsupported
	}
}