// Player Skill Stats
#include <sdktools>
#include <sourcemod>
#pragma semicolon 1
#pragma newdecls required
#define PSS_VERSION "8.5"

// THIS IS AN EDITED VERSION!
public Plugin myinfo =
{
	name = "Player Skill Stats",
	author = "Psyk0tik (Crasher_3637)",
	description = "Tracks player skill stats and saves the data to a file.",
	version = PSS_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=301577"
};
// bscal var
char errorBuffer[255];
Database db = null;
bool endRoundCheck = false;

char g_sSavePath[255];
ConVar g_cvPSSEnable;
ConVar g_cvPSSEnabledGameModes;
ConVar g_cvPSSDisabledGameModes;
ConVar g_cvPSSGameMode;
ConVar g_cvPSSInformDelay;
ConVar g_cvPSSSaveType;
int g_iBoomerKilled[MAXPLAYERS + 1];
int g_iBoomer[MAXPLAYERS + 1];
int g_iBulletCount[MAXPLAYERS + 1];
int g_iBullet[MAXPLAYERS + 1];
int g_iChargerKilled[MAXPLAYERS + 1];
int g_iCharger[MAXPLAYERS + 1];
int g_iEnemyHits[MAXPLAYERS + 1];
int g_iEnemy[MAXPLAYERS + 1];
int g_iHunterKilled[MAXPLAYERS + 1];
int g_iHunter[MAXPLAYERS + 1];
int g_iJockeyKilled[MAXPLAYERS + 1];
int g_iJockey[MAXPLAYERS + 1];
int g_iSmokerKilled[MAXPLAYERS + 1];
int g_iSmoker[MAXPLAYERS + 1];
int g_iSpitterKilled[MAXPLAYERS + 1];
int g_iSpitter[MAXPLAYERS + 1];
int g_iTankDamage[MAXPLAYERS + 1];
int g_iTank[MAXPLAYERS + 1];
int g_iTotalKilled[MAXPLAYERS + 1];
int g_iTotal[MAXPLAYERS + 1];
int g_iWitchKilled[MAXPLAYERS + 1];
int g_iWitch[MAXPLAYERS + 1];

// bscal vars
int g_iInfectedDamage[MAXPLAYERS + 1];
int g_iTankKilled[MAXPLAYERS + 1];
int g_iFriendlyFire[MAXPLAYERS + 1];
int g_iTimesDowned[MAXPLAYERS + 1];
int g_iPlayersDowned[MAXPLAYERS + 1];
int g_iPlayerMultiBooms[MAXPLAYERS + 1];
int g_iBooms[MAXPLAYERS + 1];
int g_iLastBoomerClient;
int g_iMultiCharges[MAXPLAYERS + 1];

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion evEngine = GetEngineVersion();
	if (evEngine != Engine_Left4Dead && evEngine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Player Skill Stats only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	db = SQL_DefConnect(errorBuffer, sizeof(errorBuffer));
	if (db == null)
	{
		PrintToServer("Could not connect: %s", errorBuffer);
	}

	g_cvPSSDisabledGameModes = CreateConVar("pss_disabledgamemodes", "", "Disable Player Skill Stats in these game modes.\nSeparate game modes with commas.\nGame mode limit: 64\nCharacter limit for each game mode: 32\n(Empty: None)\n(Not empty: Disabled only in these game modes.)");
	g_cvPSSEnable = CreateConVar("pss_enable", "1", "Enable Player Skill Stats?\n(0: OFF)\n(1: ON)", _, true, 0.0, true, 1.0);
	g_cvPSSEnabledGameModes = CreateConVar("pss_enabledgamemodes", "", "Enable Player Skill Stats in these game modes.\nSeparate game modes with commas.\nGame mode limit: 64\nCharacter limit for each game mode: 32\n(Empty: All)\n(Not empty: Enabled only in these game modes.)");
	g_cvPSSGameMode = FindConVar("mp_gamemode");
	g_cvPSSInformDelay = CreateConVar("pss_informdelay", "60.0", "Inform players of the !mystats command every time this many seconds passes.", _, true, 1.0, true, 99999.0);
	g_cvPSSSaveType = CreateConVar("pss_savetype", "0", "How should Player Skill Stats save data?\n(0: Overall stats)\n(1: Per day)\n(2: Per map)", _, true, 0.0, true, 2.0);
	CreateConVar("pss_pluginversion", PSS_VERSION, "Player Skill Stats Version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	//RegConsoleCmd("pss_info", cmdMyStats, "Shows player skill stats.");
	HookEvent("infected_death", eEventInfectedKilled);
	HookEvent("player_death", eEventPlayerDeath);
	HookEvent("player_hurt", eEventPlayerHurt);
	HookEvent("weapon_fire", eEventWeaponFire);
	HookEvent("witch_killed", eEventWitchKilled);
	HookEvent("round_end", eOnRoundEnd, EventHookMode_Pre);
	HookEvent("friendly_fire", eEventFriendlyFire);
	HookEvent("player_incapacitated", eEventDowned);
	HookEvent("player_now_it", eEventGotBoomed);
	HookEvent("charger_impact", eEventChargerImpact);
	HookEvent("versus_round_start", eTestVersuRoundStart);
	HookEvent("round_start_pre_entity", eTestStart);
	AutoExecConfig(true, "player_skill_stats");
}


public void OnMapStart()
{
	if (g_cvPSSEnable.BoolValue && bIsSystemValid())
	{
		CreateDirectory("addons/sourcemod/data/Player_Skill_Stats/", 511);
		if (g_cvPSSSaveType.IntValue == 0)
		{
			BuildPath(Path_SM, g_sSavePath, sizeof(g_sSavePath), "data/Player_Skill_Stats/player_skill_stats.txt");
		}
		else if (g_cvPSSSaveType.IntValue == 1)
		{
			char sTimeFormat[32];
			FormatTime(sTimeFormat, sizeof(sTimeFormat), "%b_%d_%Y", GetTime());
			BuildPath(Path_SM, g_sSavePath, sizeof(g_sSavePath), "data/Player_Skill_Stats/player_skill_stats_%s.txt", sTimeFormat);
		}
		else if (g_cvPSSSaveType.IntValue == 2)
		{
			char sMap[64];
			GetCurrentMap(sMap, sizeof(sMap));
			BuildPath(Path_SM, g_sSavePath, sizeof(g_sSavePath), "data/Player_Skill_Stats/player_skill_stats_%s.txt", sMap);
		}
		//CreateTimer(g_cvPSSInformDelay.FloatValue, tTimerStats, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
	}
}
/*
public void OnMapEnd()
{
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++)
	{
		if (g_cvPSSEnable.BoolValue && bIsSystemValid() && bIsHumanSurvivor(iPlayer))
		{
			vSaveStats(iPlayer);
		}
	}
}
*/

// bscal add
void SaveStatToDB(int client) {
	if (!endRoundCheck) {
		return;
	}
	char sSteamID[32];
	char defaultDiscord[] = "none";
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	
	if (db == null) {
		PrintToServer("[Stats] DB is null");
	}
	
	PrintToServer("[Stats] Saving to database");
	
	DBStatement hUserStmt = null;
	// Database Insert/Update here
	hUserStmt = SQL_PrepareQuery(db, "UPDATE players SET "
		... "kills=kills + ?, hits=hits + ?, bullets=bullets + ?, "
		... "smokers=smokers + ?, boomers=boomers + ?, hunters=hunters + ?, spitter=spitter + ?, "
		... "jockeys=jockeys + ?, chargers=chargers + ?, witch=witch + ?, tankdmg=tankdmg + ?, round=round+1, infdmg=infdmg + ?, "
		... "tankkills=tankkills + ?, friendly_fire=friendly_fire + ?, times_down=times_down + ?, "
		... "player_downs=player_downs + ?, multi_booms=multi_booms + ?, booms=booms + ?, "
		... "multi_charge=multi_charge + ? WHERE steamid=?", errorBuffer, sizeof(errorBuffer));
 
	if (hUserStmt == null) {
		PrintToServer("[Stats] updatestmt is null");
	}
 
	hUserStmt.BindInt(0, g_iTotalKilled[client], false);
	hUserStmt.BindInt(1, g_iEnemyHits[client], false);
	hUserStmt.BindInt(2, g_iBulletCount[client], false);
	hUserStmt.BindInt(3, g_iSmokerKilled[client], false);
	hUserStmt.BindInt(4, g_iBoomerKilled[client], false);
	hUserStmt.BindInt(5, g_iHunterKilled[client], false);
	hUserStmt.BindInt(6, g_iSpitterKilled[client], false);
	hUserStmt.BindInt(7, g_iJockeyKilled[client], false);
	hUserStmt.BindInt(8, g_iChargerKilled[client], false);
	hUserStmt.BindInt(9, g_iWitchKilled[client], false);
	hUserStmt.BindInt(10, g_iTankDamage[client], false);
	hUserStmt.BindInt(11, g_iInfectedDamage[client], false);
	hUserStmt.BindInt(12, g_iTankKilled[client], false);
	hUserStmt.BindInt(13, g_iFriendlyFire[client], false);
	hUserStmt.BindInt(14, g_iTimesDowned[client], false);
	hUserStmt.BindInt(15, g_iPlayersDowned[client], false);
	hUserStmt.BindInt(16, g_iPlayerMultiBooms[client], false);
	hUserStmt.BindInt(17, g_iBooms[client], false);
	hUserStmt.BindInt(18, g_iMultiCharges[client], false);
	// steamid
	hUserStmt.BindString(19, sSteamID, false);
	if (!SQL_Execute(hUserStmt))
	{
		return;
	}
	
	if(SQL_GetAffectedRows(hUserStmt) < 1) {
		PrintToServer("[Stats] rows: %d", SQL_GetRowCount(hUserStmt));
		PrintToServer("[Stats] Inserting to database");
		DBStatement iUserStmt = null;
		// INSERTS THE INFO BECAUSE IT WASNT BEFORE.
		iUserStmt = SQL_PrepareQuery(db, "INSERT INTO players (discord, steamid, kills, hits, bullets, smokers, boomers, hunters, spitter, "
			... "jockeys, chargers, witch, tankdmg, round, infdmg, tankkills, friendly_fire, times_down, player_downs, multi_booms, booms, multi_charge) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 1, ?, ?, ?, ?, ?, ?, ?, ?)", errorBuffer, sizeof(errorBuffer));
			
		if (iUserStmt == null) {
			PrintToServer("[Stats] insertdb is null");
		}
			
		iUserStmt.BindString(0, defaultDiscord, false);
		iUserStmt.BindString(1, sSteamID, false);	
		iUserStmt.BindInt(2, g_iTotalKilled[client], false);
		iUserStmt.BindInt(3, g_iEnemyHits[client], false);
		iUserStmt.BindInt(4, g_iBulletCount[client], false);
		iUserStmt.BindInt(5, g_iSmokerKilled[client], false);
		iUserStmt.BindInt(6, g_iBoomerKilled[client], false);
		iUserStmt.BindInt(7, g_iHunterKilled[client], false);
		iUserStmt.BindInt(8, g_iSpitterKilled[client], false);
		iUserStmt.BindInt(9, g_iJockeyKilled[client], false);
		iUserStmt.BindInt(10, g_iChargerKilled[client], false);
		iUserStmt.BindInt(11, g_iWitchKilled[client], false);
		iUserStmt.BindInt(12, g_iTankDamage[client], false);
		iUserStmt.BindInt(13, g_iInfectedDamage[client], false);
		iUserStmt.BindInt(14, g_iTankKilled[client], false);
		iUserStmt.BindInt(15, g_iFriendlyFire[client], false);
		iUserStmt.BindInt(16, g_iTimesDowned[client], false);
		iUserStmt.BindInt(17, g_iPlayersDowned[client], false);
		iUserStmt.BindInt(18, g_iPlayerMultiBooms[client], false);
		iUserStmt.BindInt(19, g_iBooms[client], false);
		iUserStmt.BindInt(20, g_iMultiCharges[client], false);
		if (!SQL_Execute(iUserStmt)) {
			return;
		}
	}

	PrintToServer("[Stats] User saved to database");
	resetStats(client);
}

void resetPlayerStats() {
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if (g_cvPSSEnable.BoolValue && bIsSystemValid()) {
			resetStats(iPlayer);
		}
	}
}

void resetStats(int client) {
	g_iEnemyHits[client] = 0;
	g_iBulletCount[client] = 0;
	g_iTotalKilled[client] = 0;
	g_iSmokerKilled[client] = 0;
	g_iBoomerKilled[client] = 0;
	g_iHunterKilled[client] = 0;
	g_iSpitterKilled[client] = 0;
	g_iJockeyKilled[client] = 0;
	g_iChargerKilled[client] = 0;
	g_iWitchKilled[client] = 0;
	g_iTankDamage[client] = 0;
	g_iInfectedDamage[client] = 0;
	g_iTankKilled[client] = 0;
	g_iFriendlyFire[client] = 0;
	g_iTimesDowned[client] = 0;
	g_iPlayersDowned[client] = 0;
	g_iLastBoomerClient = 0;
	g_iPlayerMultiBooms[client] = 0;
	g_iBooms[client] = 0;
	g_iMultiCharges[client] = 0;
}



public Action eEventChargerImpact(Event event, const char[] name, bool dontBroadcast)
{
	int iCharger = GetClientOfUserId(event.GetInt("userid"));
	if (g_cvPSSEnable.BoolValue && bIsSystemValid() && bIsInfected(iCharger)) {
		g_iMultiCharges[iCharger]++;
	}
}

public Action eEventGotBoomed(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	bool iByBoomer = event.GetBool("by_boomer");
	if (g_cvPSSEnable.BoolValue && bIsSystemValid()) {
		if (!iByBoomer) {
			return;
		}
		if (!bIsHumanSurvivor(iVictim)) {
			return;
		}
		if (!bIsInfected(iAttacker)) {
			return;
		}
		if (g_iLastBoomerClient == iAttacker) {
			g_iPlayerMultiBooms[iAttacker]++;
		}
		g_iBooms[iAttacker]++;
		g_iLastBoomerClient = iAttacker;
	}
}

public Action eEventDowned(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if (g_cvPSSEnable.BoolValue && bIsSystemValid()) {
		if (bIsHumanSurvivor(iVictim)) {
			g_iTimesDowned[iVictim]++;
		}
		
		if (bIsInfected(iAttacker)) {
			g_iPlayersDowned[iAttacker]++;
		}
	}
}

public Action eTestVersuRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("--- VERSUS ROUND EVENT MESSAGE ---");
	resetPlayerStats();
}


public Action eTestStart(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("--- START ROUND EVENT MESSAGE ---");
	endRoundCheck = true;
}


// bscal add xd valve onmapend function no work
public Action eOnRoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	PrintToServer("End Event Called!");
	PrintToServer("Winner Event: %d", event.GetInt("winner"));
	PrintToServer("Time Event: %f", event.GetFloat("time"));
	for (int iPlayer = 1; iPlayer <= MaxClients; iPlayer++) {
		if (g_cvPSSEnable.BoolValue && bIsSystemValid()) {
			if (!bIsInfected(iPlayer) && !bIsHumanSurvivor(iPlayer)) {
				continue;
			}
			SaveStatToDB(iPlayer);
		}
	}
	endRoundCheck = false;
}

public Action eEventFriendlyFire(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	g_iFriendlyFire[iAttacker]++;
}

public Action eEventInfectedKilled(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));	
	if (g_cvPSSEnable.BoolValue && bIsSystemValid() && bIsHumanSurvivor(iAttacker))
	{
		g_iEnemyHits[iAttacker] += 1;
		g_iTotalKilled[iAttacker] += 1;
	}
}

public Action eEventPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	if (g_cvPSSEnable.BoolValue && bIsSystemValid() && bIsHumanSurvivor(iAttacker) && bIsInfected(iVictim))
	{
		int iClass = GetEntProp(iVictim, Prop_Send, "m_zombieClass");
		if (iClass == 1)
		{
			g_iSmokerKilled[iAttacker] += 1;
			g_iTotalKilled[iAttacker] += 1;
		}
		else if (iClass == 2)
		{
			g_iBoomerKilled[iAttacker] += 1;
			g_iTotalKilled[iAttacker] += 1;
		}
		else if (iClass == 3)
		{
			g_iHunterKilled[iAttacker] += 1;
			g_iTotalKilled[iAttacker] += 1;
		}
		else if (iClass == 4 && bIsL4D2Game())
		{
			g_iSpitterKilled[iAttacker] += 1;
			g_iTotalKilled[iAttacker] += 1;
		}
		else if (iClass == 5 && bIsL4D2Game())
		{
			g_iJockeyKilled[iAttacker] += 1;
			g_iTotalKilled[iAttacker] += 1;
		}
		else if (iClass == 6 && bIsL4D2Game())
		{
			g_iChargerKilled[iAttacker] += 1;
			g_iTotalKilled[iAttacker] += 1;
		}
		else if (iClass == 8 && bIsL4D2Game())
		{
			g_iTankKilled[iAttacker] += 1;
			g_iTotalKilled[iAttacker] += 1;
		}
	}
}

public Action eEventPlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iTarget = GetClientOfUserId(event.GetInt("userid"));
	if (g_cvPSSEnable.BoolValue && bIsSystemValid())
	{
		if (bIsHumanSurvivor(iAttacker))
		{
			// Tank Damage
			if (bIsL4D2Game() ? GetEntProp(iTarget, Prop_Send, "m_zombieClass") == 8 : GetEntProp(iTarget, Prop_Send, "m_zombieClass") == 5)
			{
				int iDamage = event.GetInt("dmg_health");
				if (bIsHumanSurvivor(iAttacker) && iTarget > 0)
				{
					g_iTankDamage[iAttacker] += iDamage;
				}
			}
			g_iEnemyHits[iAttacker] += 1;
		}
		else if (bIsInfected(iAttacker)) 
		{
			int iDamage = event.GetInt("dmg_health");
			g_iInfectedDamage[iAttacker] += iDamage;
		}
	}
}

public Action eEventWeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int iShooter = GetClientOfUserId(event.GetInt("userid"));
	if (g_cvPSSEnable.BoolValue && bIsSystemValid() && bIsHumanSurvivor(iShooter))
	{
		g_iBulletCount[iShooter] += 1;
	}
}

public Action eEventWitchKilled(Event event, char[] name, bool dontBroadcast)
{
	int iKiller = GetClientOfUserId(event.GetInt("userid"));
	if (g_cvPSSEnable.BoolValue && bIsSystemValid() && bIsHumanSurvivor(iKiller))
	{
		g_iWitchKilled[iKiller] += 1;
	}
}

public Action cmdMyStats(int client, int args)
{
	ReplyToCommand(client, "\x04[PS]\x01 THIS COMMAND NO LONGER WORKS");
	/*
	if (!g_cvPSSEnable.BoolValue || !bIsSystemValid())
	{
		ReplyToCommand(client, "\x04[PS]\x01 Player Skill Stats is disabled.");
		return Plugin_Handled;
	}
	if (!bIsHumanSurvivor(client))
	{
		ReplyToCommand(client, "\x04[PS]\x01 You must be on the survivor team to use this command.");
		return Plugin_Handled;
	}
	if (args < 1)
	{
		vShowStats(client);
		return Plugin_Handled;
	}
	char target[32];
	char target_name[32];
	int target_list[MAXPLAYERS];
	int target_count;
	bool tn_is_ml;
	GetCmdArg(1, target, sizeof(target));
	if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	for (int iPlayer = 0; iPlayer < target_count; iPlayer++)
	{
		vShowStats(target_list[iPlayer]);
	}
	*/
	return Plugin_Handled;
}

void vShowStats(int client)
{
	vSaveStats(client);
	PrintToChat(client, "\x03%N's Personal Skill Stats Info:", client);
	bIsL4D2Game() ? PrintToChat(client, "\x03Smokers Killed: \x04%d\x01/\x03Boomers Killed: \x04%d\x01/\x03Hunters Killed: \x04%d\x01/\x03Spitters Killed: \x04%d\x01/\x03Jockeys Killed: \x04%d\x01/\x03Chargers Killed: \x04%d", g_iSmoker[client] + g_iSmokerKilled[client], g_iBoomer[client] + g_iBoomerKilled[client], g_iHunter[client] + g_iHunterKilled[client], g_iSpitter[client] + g_iSpitterKilled[client], g_iJockey[client] + g_iJockeyKilled[client], g_iCharger[client] + g_iChargerKilled[client]) : PrintToChat(client, "\x03Smokers Killed: \x04%d\x01/\x03Boomers Killed: \x04%d\x01/\x03Hunters Killed: \x04%d", g_iSmoker[client] + g_iSmokerKilled[client], g_iBoomer[client] + g_iBoomerKilled[client], g_iHunter[client] + g_iHunterKilled[client]);
	PrintToChat(client, "\x03Witches Killed: \x04%d\x01/\x03Tank Damage: \x04%d\x01/\x03Total Infected Killed: \x04%d", g_iWitch[client] + g_iWitchKilled[client], g_iTank[client] + g_iTankDamage[client], g_iTotal[client] + g_iTotalKilled[client]);
	PrintToChat(client, "\x03Bullets Fired: \x04%d\x01/\x03Total Hits: \x04%d\x01/\x03Accuracy: \x04%.1f%%", g_iBullet[client] + g_iBulletCount[client], g_iEnemy[client] + g_iEnemyHits[client], float(g_iEnemy[client] + g_iEnemyHits[client]) / float(g_iBullet[client] + g_iBulletCount[client]) * 100);
	PrintToChat(client, "\x03Keep surviving the apocalypse!");
	g_iEnemyHits[client] = 0;
	g_iBulletCount[client] = 0;
	g_iTotalKilled[client] = 0;
	g_iSmokerKilled[client] = 0;
	g_iBoomerKilled[client] = 0;
	g_iHunterKilled[client] = 0;
	g_iSpitterKilled[client] = 0;
	g_iJockeyKilled[client] = 0;
	g_iChargerKilled[client] = 0;
	g_iWitchKilled[client] = 0;
	g_iTankDamage[client] = 0;
}

void vSaveStats(int client)
{
	KeyValues kvPlayerStats = new KeyValues("Player Skill Stats");
	FileToKeyValues(kvPlayerStats, g_sSavePath);
	char sSteamID[32];
	GetClientAuthId(client, AuthId_Steam2, sSteamID, sizeof(sSteamID));
	if (kvPlayerStats.JumpToKey(sSteamID, true))
	{
		char sCurrentName[32];
		char sSteamName[32];
		GetClientName(client, sSteamName, sizeof(sSteamName));
		kvPlayerStats.GetString("Name", sCurrentName, sizeof(sCurrentName), "NULL");
		g_iTotal[client] = kvPlayerStats.GetNum("Total Kills", 0);
		g_iEnemy[client] = kvPlayerStats.GetNum("Enemy Hits", 0);
		g_iBullet[client] = kvPlayerStats.GetNum("Fired Bullets", 0);
		g_iSmoker[client] = kvPlayerStats.GetNum("Smoker Kills", 0);
		g_iBoomer[client] = kvPlayerStats.GetNum("Boomer Kills", 0);
		g_iHunter[client] = kvPlayerStats.GetNum("Hunter Kills", 0);
		if (bIsL4D2Game())
		{
			g_iSpitter[client] = kvPlayerStats.GetNum("Spitter Kills", 0);
			g_iJockey[client] = kvPlayerStats.GetNum("Jockey Kills", 0);
			g_iCharger[client] = kvPlayerStats.GetNum("Charger Kills", 0);
		}
		g_iWitch[client] = kvPlayerStats.GetNum("Witch Kills", 0);
		g_iTank[client] = kvPlayerStats.GetNum("Tank Damage", 0);
		kvPlayerStats.SetString("Name", sSteamName);
		kvPlayerStats.SetNum("Total Kills", g_iTotal[client] + g_iTotalKilled[client]);
		kvPlayerStats.SetNum("Enemy Hits", g_iEnemy[client] + g_iEnemyHits[client]);
		kvPlayerStats.SetNum("Fired Bullets", g_iBullet[client] + g_iBulletCount[client]);
		kvPlayerStats.SetNum("Smoker Kills", g_iSmoker[client] + g_iSmokerKilled[client]);
		kvPlayerStats.SetNum("Boomer Kills", g_iBoomer[client] + g_iBoomerKilled[client]);
		kvPlayerStats.SetNum("Hunter Kills", g_iHunter[client] + g_iHunterKilled[client]);
		if (bIsL4D2Game())
		{
			kvPlayerStats.SetNum("Spitter Kills", g_iSpitter[client] + g_iSpitterKilled[client]);
			kvPlayerStats.SetNum("Jockey Kills", g_iJockey[client] + g_iJockeyKilled[client]);
			kvPlayerStats.SetNum("Charger Kills", g_iCharger[client] + g_iChargerKilled[client]);
		}
		kvPlayerStats.SetNum("Witch Kills", g_iWitch[client] + g_iWitchKilled[client]);
		kvPlayerStats.SetNum("Tank Damage", g_iTank[client] + g_iTankDamage[client]);
		kvPlayerStats.Rewind();
		KeyValuesToFile(kvPlayerStats, g_sSavePath);
		delete kvPlayerStats;
	}
}

public Action tTimerStats(Handle timer)
{
	PrintToChatAll("\x04You can type\x05 !pss_info \x04to see your personal skill stats.");
	PrintToChatAll("\x04You can also type\x05 !pss_info <#userid|name>\x04 to see another player's personal skill stats.");
}

stock bool bIsHumanSurvivor(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client) && GetClientTeam(client) == 2 && !IsFakeClient(client);
}

stock bool bIsInfected(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsClientInKickQueue(client) && GetClientTeam(client) == 3;
}

stock bool bIsL4D2Game()
{
	EngineVersion evEngine = GetEngineVersion();
	return evEngine == Engine_Left4Dead2;
}

stock bool bIsSystemValid()
{
	char sGameMode[32];
	char sConVarModes[32];
	g_cvPSSGameMode.GetString(sGameMode, sizeof(sGameMode));
	Format(sGameMode, sizeof(sGameMode), ",%s,", sGameMode);
	g_cvPSSEnabledGameModes.GetString(sConVarModes, sizeof(sConVarModes));
	if (strcmp(sConVarModes, ""))
	{
		Format(sConVarModes, sizeof(sConVarModes), ",%s,", sConVarModes);
		if (StrContains(sConVarModes, sGameMode, false) == -1)
		{
			return false;
		}
	}
	g_cvPSSDisabledGameModes.GetString(sConVarModes, sizeof(sConVarModes));
	if (strcmp(sConVarModes, ""))
	{
		Format(sConVarModes, sizeof(sConVarModes), ",%s,", sConVarModes);
		if (StrContains(sConVarModes, sGameMode, false) != -1)
		{
			return false;
		}
	}
	return true;
}