#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <l4d2_direct>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>
#include <discord_webhook>
#include "includes/finalemaps"

#define DEBUG 1

#define CONBUFSIZELARGE         (1 << 12)       // 4k
#define ROUNDEND_DELAY          3.0
#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))

#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define MAXMAP                  32

new     bool:   g_bInRound              = false;
new iTankPercent = 0;
new scoreTotals[2];
new Handle:g_hVsBossBuffer;
new String:sPlayers[2][512];
new String:titles[2][64];
new String:sEmbedRequest[CONBUFSIZELARGE];
new iEmbedCount = 0;
new Handle: g_hCvarWebhookConfig = INVALID_HANDLE;
new String: g_sWebhookName[64];

enum strMapType {
    MP_FINALE
};

public Plugin: myinfo =
{
    name = "Discord Scoreboard",
    author = "devilesk",
    description = "Reports round end stats to discord",
    version = "1.4.1",
    url = "https://steamcommunity.com/groups/RL4D2L"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    RegPluginLibrary("discord_scoreboard");
    
    CreateNative("AddEmbed", Native_AddEmbed);
    return APLRes_Success;
}

public OnPluginStart()
{
    g_hCvarWebhookConfig = CreateConVar("discord_scoreboard_webhook_cfg", "discord_scoreboard", "Name of webhook keyvalue entry to use in discord_webhook.cfg", FCVAR_NONE);
    g_hVsBossBuffer = FindConVar("versus_boss_buffer");
    HookEvent("round_start",                Event_RoundStart,				EventHookMode_PostNoCopy);
    HookEvent("round_end",                  Event_RoundEnd,				EventHookMode_PostNoCopy);
}

public OnMapStart()
{
    sEmbedRequest[0] = '\0';
    iEmbedCount = 0;
}

public Event_RoundStart (Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    g_bInRound = true;
    new indexSurvivor = GameRules_GetProp("m_bAreTeamsFlipped");
    new indexInfected = 1 - indexSurvivor;
    scoreTotals[indexSurvivor] = GameRules_GetProp("m_iCampaignScore", 2, indexSurvivor);
    scoreTotals[indexInfected] = GameRules_GetProp("m_iCampaignScore", 2, indexInfected);
    CreateTimer(6.0, SaveBossFlows, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:SaveBossFlows(Handle:timer)
{
	if (!InSecondHalfOfRound())
	{
		iTankPercent = 0;

		if (L4D2Direct_GetVSTankToSpawnThisRound(0))
		{
			iTankPercent = RoundToNearest(GetTankFlow(0)*100.0);
		}
	}
	else
	{
		if (iTankPercent != 0)
		{
			iTankPercent = RoundToNearest(GetTankFlow(1)*100.0);
		}
	}
}

public Event_RoundEnd (Handle:hEvent, const String:name[], bool:dontBroadcast)
{
    if ( !g_bInRound ) { return; }
    g_bInRound = false;
    CreateTimer( ROUNDEND_DELAY, Timer_RoundEnd, _, TIMER_FLAG_NO_MAPCHANGE );
}

public Action: Timer_RoundEnd ( Handle:timer )
{
    new String:sMap[64];
    decl String:description[512];
    sPlayers[0][0] = '\0';
    sPlayers[1][0] = '\0';
    
    if (iTankPercent)
    {
        Format(description, sizeof(description), "Tank spawn: %d%%", iTankPercent);
    }
    else
    {
        strcopy(description, sizeof(description), "Tank spawn: None");
    }
    
    GetCurrentMapLower(sMap, sizeof(sMap));
    GetMapName(sMap, sMap, sizeof(sMap));
    
    new indexSurvivor = GameRules_GetProp("m_bAreTeamsFlipped");
    new indexInfected = 1 - indexSurvivor;
    new totalSurvivor = GameRules_GetProp("m_iCampaignScore", 2, indexSurvivor);
    new roundSurvivor = totalSurvivor - scoreTotals[indexSurvivor];
    scoreTotals[indexSurvivor] = totalSurvivor;
    Format(titles[indexSurvivor], sizeof(titles[]), "Team %d: %d (+%d)", InSecondHalfOfRound() ? 2 : 1, totalSurvivor, roundSurvivor);
    
    for ( new client = 1; client <= MaxClients; client++ )
    {
        if ( IS_VALID_SURVIVOR(client) )
        {
            Format(sPlayers[indexSurvivor], sizeof(sPlayers[]), "%s%N\\n", sPlayers[indexSurvivor], client);
        }
        else if ( IS_VALID_INFECTED(client) ) {
            Format(sPlayers[indexInfected], sizeof(sPlayers[]), "%s%N\\n", sPlayers[indexInfected], client);
        }
    }
    if (!sPlayers[indexSurvivor][0]) {
        strcopy(sPlayers[indexSurvivor], sizeof(sPlayers[]), "None");
    }
    if (!sPlayers[indexInfected][0]) {
        strcopy(sPlayers[indexInfected], sizeof(sPlayers[]), "None");
    }
    if (InSecondHalfOfRound()) {
        decl String:fields[CONBUFSIZELARGE];
        Format(fields, CONBUFSIZELARGE, "{\"name\":\"%s\",\"value\":\"%s\",\"inline\":%d},{\"name\":\"%s\",\"value\":\"%s\",\"inline\":%d}", titles[0], sPlayers[0], 1, titles[1], sPlayers[1], 1);
        InternalAddEmbed(sMap, description, "", 15158332, fields);
        FormatEmbedRequest(sEmbedRequest, sizeof(sEmbedRequest), sEmbedRequest);
        GetConVarString(g_hCvarWebhookConfig, g_sWebhookName, sizeof(g_sWebhookName));
        SendToDiscord(g_sWebhookName, sEmbedRequest);
        
        if (IsMissionFinalMap()) {
            scoreTotals[0] = 0;
            scoreTotals[1] = 0;
        }
    }
}

bool GetMapName(const char[] mapId, char[] mapName, int iLength)
{
    KeyValues kv = new KeyValues("DiscordScoreboard");

    char sFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sFile, sizeof(sFile), "configs/discord_scoreboard.cfg");

    if (!FileExists(sFile))
    {
        SetFailState("[GetMapName] \"%s\" not found!", sFile);
        return false;
    }

    kv.ImportFromFile(sFile);

    if (!kv.JumpToKey(mapId, false))
    {
        SetFailState("[GetMapName] Can't find map \"%s\" in \"%s\"!", mapId, sFile);
        delete kv;
        return false;
    }
    kv.GetString(NULL_STRING, mapName, iLength);
    delete kv;
    return true;
}

stock Float:GetTankFlow(round)
{
    return L4D2Direct_GetVSTankFlowPercent(round) - GetConVarFloat(g_hVsBossBuffer) / L4D2Direct_GetMapMaxFlowDistance();
}

public Native_AddEmbed(Handle:plugin, numParams)
{
    new len;

    GetNativeStringLength(1, len);
    new String:title[len+1];
    GetNativeString(1, title, len+1);

    GetNativeStringLength(2, len);
    new String:description[len+1];
    GetNativeString(2, description, len+1);

    GetNativeStringLength(3, len);
    new String:url[len+1];
    GetNativeString(3, url, len+1);
    
    int color = GetNativeCell(4);
    
    char fields[CONBUFSIZELARGE];
    char name[256];
    char value[256];
    new inline;
    
    for (int i = 5; i <= numParams; i+=3)
    {
        // field name
        GetNativeStringLength(i, len);
        if (len <= 0) { return; }
        GetNativeString(i, name, len+1);
        
        // field value
        GetNativeStringLength(i+1, len);
        if (len <= 0) { return; }
        GetNativeString(i+1, value, len+1);
        
        inline = GetNativeCellRef(i+2);
        
        if (i == 5)
        {
            Format(fields, CONBUFSIZELARGE, "{\"name\":\"%s\",\"value\":\"%s\",\"inline\":%d}", name, value, inline);
        }
        else
        {
            Format(fields, CONBUFSIZELARGE, "%s,{\"name\":\"%s\",\"value\":\"%s\",\"inline\":%d}", fields, name, value, inline);
        }
    }
    
    InternalAddEmbed(title, description, url, color, fields);
}

InternalAddEmbed(const String:title[], const String:description[], const String:url[], color, const String:fields[])
{
    decl String:sEmbed[CONBUFSIZELARGE];
    FormatEmbed2(sEmbed, sizeof(sEmbed), title, description, url, color, fields);
    if (iEmbedCount == 0) {
        strcopy(sEmbedRequest, sizeof(sEmbedRequest), sEmbed);
    }
    else {
        Format(sEmbedRequest, sizeof(sEmbedRequest), "%s,%s", sEmbedRequest, sEmbed);
    }
    iEmbedCount++;
}