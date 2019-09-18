#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4downtown>
#include <l4d2_direct>
#include <l4d2_playstats>
#include <clientprefs>
#undef REQUIRE_PLUGIN
#include <readyup>
#include <lgofnoc>
#include <system2>
#define REQUIRE_PLUGIN

#include "l4d2_playstats/globals.sp"
#include "l4d2_playstats/game.sp"
#include "l4d2_playstats/display.sp"
#include "l4d2_playstats/console.sp"
#include "l4d2_playstats/tracking.sp"
#include "l4d2_playstats/skill.sp"
#include "l4d2_playstats/util.sp"
#include "l4d2_playstats/database.sp"
#include "l4d2_playstats/file.sp"
    
public Plugin: myinfo = {
    name = "Player Statistics",
    author = "Tabun, devilesk",
    description = "Tracks statistics, even when clients disconnect. MVP, Skills, Accuracy, etc. Modified for RL4D2L",
    version = "0.13.1",
    url = "https://github.com/Tabbernaut/L4D2-Plugins"
};

/*
    todo
    ----

        fix:
        ------
        - the current CMT + forwards for teamswaps solution is kinda bad.
            - would be nicer to fix CMT so the normal gamerules swapped
              check is correct -- so: test whether "m_bAreTeamsFlipped"
              can be unproblematically written to (yes, I was afraid to
              just try this without doing some serious testing with it
              first).

        - end of round MVP chat prints: doesn't show your rank

        - full game stats don't show before round is live
        - full game stat: shows last round time, instead of full game time
        
        
        build:
        ------
        - skill
            - clears / instaclears (show in stats)
            - show average clear time (for all survivors?)
        
    ideas
    -----
    - instead of hits/shots, display average multiplier for shotgun pellets
        (can just do that per hitgroup, if we use what we know about the SI)
*/

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
    g_bLateLoad = late;
    return APLRes_Success;
}

// crox readyup usage
public OnAllPluginsLoaded() {
    g_bLGOAvailable = LibraryExists("lgofnoc");
    g_bReadyUpAvailable = LibraryExists("readyup");
    g_bPauseAvailable = LibraryExists("pause");
    g_bSkillDetectLoaded = LibraryExists("skill_detect");
    g_bSystem2Loaded = LibraryExists("system2");
}
public OnLibraryRemoved(const String:name[]) {
    if ( StrEqual(name, "lgofnoc") ) { g_bLGOAvailable = false; }
    else if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = false; }
    else if ( StrEqual(name, "pause") ) { g_bPauseAvailable = false; }
    else if ( StrEqual(name, "skill_detect") ) { g_bSkillDetectLoaded = false; }
    else if ( StrEqual(name, "system2") ) { g_bSystem2Loaded = false; }
}
public OnLibraryAdded(const String:name[]) {
    if ( StrEqual(name, "lgofnoc") ) { g_bLGOAvailable = true; }
    else if ( StrEqual(name, "readyup") ) { g_bReadyUpAvailable = true; }
    else if ( StrEqual(name, "pause") ) { g_bPauseAvailable = true; }
    else if ( StrEqual(name, "skill_detect") ) { g_bSkillDetectLoaded = true; }
    else if ( StrEqual(name, "system2") ) { g_bSystem2Loaded = true; }
}

public OnPluginStart() {
    // events    
    HookEvent("round_start",                Event_RoundStart,				EventHookMode_PostNoCopy);
    HookEvent("scavenge_round_start",       Event_RoundStart,				EventHookMode_PostNoCopy);
    HookEvent("round_end",                  Event_RoundEnd,				EventHookMode_PostNoCopy);
    
    HookEvent("mission_lost",               Event_MissionLostCampaign,		EventHookMode_Post);
    HookEvent("map_transition",             Event_MapTransition,			EventHookMode_PostNoCopy);
    HookEvent("finale_win",                 Event_FinaleWin,				EventHookMode_PostNoCopy);
    HookEvent("survivor_rescued",           Event_SurvivorRescue,			EventHookMode_Post);
    
    HookEvent("player_team",                Event_PlayerTeam,				EventHookMode_Post);
    HookEvent("player_spawn",               Event_PlayerSpawn,			EventHookMode_Post);
    HookEvent("player_hurt",                Event_PlayerHurt,				EventHookMode_Post);
    HookEvent("player_death",               Event_PlayerDeath,			EventHookMode_Post);
    HookEvent("player_incapacitated",       Event_PlayerIncapped,			EventHookMode_Post);
    HookEvent("player_ledge_grab",          Event_PlayerLedged,			EventHookMode_Post);
    HookEvent("player_ledge_release",       Event_PlayerLedgeRelease,		EventHookMode_Post);
    
    HookEvent("revive_success",             Event_PlayerRevived,			EventHookMode_Post);
    HookEvent("player_falldamage",          Event_PlayerFallDamage,		EventHookMode_Post);
    
    HookEvent("tank_spawn",                 Event_TankSpawned,			EventHookMode_Post);
    HookEvent("weapon_fire",                Event_WeaponFire,				EventHookMode_Post);
    HookEvent("infected_hurt",              Event_InfectedHurt,			EventHookMode_Post);
    HookEvent("witch_killed",               Event_WitchKilled,			EventHookMode_Post);
    HookEvent("heal_success",               Event_HealSuccess,			EventHookMode_Post);
    HookEvent("defibrillator_used",         Event_DefibUsed,				EventHookMode_Post);
    HookEvent("pills_used",                 Event_PillsUsed,				EventHookMode_Post);
    HookEvent("adrenaline_used",            Event_AdrenUsed,				EventHookMode_Post);
    
    HookEvent("player_now_it",              Event_PlayerBoomed,			EventHookMode_Post);
    HookEvent("player_no_longer_it",        Event_PlayerUnboomed,			EventHookMode_Post);
    
    HookEvent("charger_carry_start",        Event_ChargerCarryStart,		EventHookMode_Post);
    HookEvent("charger_impact",             Event_ChargerImpact,			EventHookMode_Post);
    HookEvent("jockey_ride",                Event_JockeyRide,				EventHookMode_Post);
    HookEvent("jockey_ride_end",            Event_JockeyRideEnd,		EventHookMode_Post);
    HookEvent("award_earned",               Event_AwardEarned,		EventHookMode_Post);
    
    // Database config cvar
    g_hCvarDatabaseConfig = CreateConVar(
            "l4d2_playstats_database_cfg",
            "l4d2_playstats",
            "Name of database keyvalue entry to use in databases.cfg",
            FCVAR_PLUGIN, true, 0.0, false
        );
    
    // cvars
    g_hCvarDebug = CreateConVar(
            "sm_stats_debug",
            "0",
            "Debug mode",
            FCVAR_PLUGIN, true, 0.0, false
        );
    g_hCvarMVPBrevityFlags = CreateConVar(
            "sm_survivor_mvp_brevity",
            "4",
            "Flags for setting brevity of MVP chat report (hide 1:SI, 2:CI, 4:FF, 8:rank, 32:perc, 64:abs).",
            FCVAR_PLUGIN, true, 0.0, false
        );
    g_hCvarAutoPrintVs = CreateConVar(
            "sm_stats_autoprint_vs_round",
            "8325",                                     // default = 1 (mvpchat) + 4 (mvpcon-round) + 128 (special round) = 133 + (funfact round) 8192 = 8325
            "Flags for automatic print [versus round] (show 1,4:MVP-chat, 4,8,16:MVP-console, 32,64:FF, 128,256:special, 512,1024,2048,4096:accuracy).",
            FCVAR_PLUGIN, true, 0.0, false
        );
    g_hCvarAutoPrintCoop = CreateConVar(
            "sm_stats_autoprint_coop_round",
            "1289",                                     // default = 1 (mvpchat) + 8 (mvpcon-all) + 256 (special all) + 1024 (acc all) = 1289
            "Flags for automatic print [campaign round] (show 1,4:MVP-chat, 4,8,16:MVP-console, 32,64:FF, 128,256:special, 512,1024,2048,4096:accuracy).",
            FCVAR_PLUGIN, true, 0.0, false
        );
    g_hCvarShowBots = CreateConVar(
            "sm_stats_showbots",
            "1",
            "Show bots in all tables (0 = show them in MVP and FF tables only)",
            FCVAR_PLUGIN, true, 0.0, false
        );
    g_hCvarDetailPercent = CreateConVar(
            "sm_stats_percentdecimal",
            "0",
            "Show the first decimal for (most) MVP percent in console tables.",
            FCVAR_PLUGIN, true, 0.0, false
        );
    g_hCvarWriteStats = CreateConVar(
            "sm_stats_writestats",
            "0",
            "Whether to store stats in logs/ dir (1 = write csv; 2 = write csv & pretty tables). Versus only.",
            FCVAR_PLUGIN, true, 0.0, false
        );
    g_hCvarSkipMap = CreateConVar(
            "sm_stats_resetnextmap",
            "0",
            "First round is ignored (for use with confogl/matchvotes - this will be automatically unset after a new map is loaded).",
            FCVAR_PLUGIN, true, 0.0, false
        );
    
    g_iTeamSize = 4;
    g_iFirstScoresSet[2] = 1;   // don't save scores for first map
    
    // commands:
    RegConsoleCmd( "sm_stats",      Cmd_StatsDisplayGeneral,    "Prints stats for survivors" );
    RegConsoleCmd( "sm_mvp",        Cmd_StatsDisplayGeneral,    "Prints MVP stats for survivors" );
    RegConsoleCmd( "sm_skill",      Cmd_StatsDisplayGeneral,    "Prints special skills stats for survivors" );
    RegConsoleCmd( "sm_ff",         Cmd_StatsDisplayGeneral,    "Prints friendly fire stats stats" );
    RegConsoleCmd( "sm_acc",        Cmd_StatsDisplayGeneral,    "Prints accuracy stats for survivors" );
    
    RegConsoleCmd( "sm_stats_auto", Cmd_Cookie_SetPrintFlags,   "Sets client-side preference for automatic stats-print at end of round" );
    
    RegAdminCmd(   "statsreset",    Cmd_StatsReset, ADMFLAG_CHANGEMAP, "Resets the statistics. Admins only." );
    
    RegConsoleCmd( "say",           Cmd_Say );
    RegConsoleCmd( "say_team",      Cmd_Say );
    
    // cookie
    g_hCookiePrint = RegClientCookie( "sm_stats_autoprintflags", "Stats Auto Print Flags", CookieAccess_Public );
    
    // tries
    InitTries();
    
    // prepare team array
    ClearPlayerTeam();
    
    if ( g_bLateLoad ) {
        new i, index;
        new time = GetTime();
        
        for ( i = 1; i <= MaxClients; i++ ) {
            if ( IsClientInGame(i) && !IsFakeClient(i) ) {
                // store each player with a first check
                index = GetPlayerIndexForClient( i );
                
                // set start time to now
                if ( IS_VALID_SURVIVOR(i) ) {
                    g_strRoundPlayerData[index][0][plyTimeStartPresent] = time;
                    g_strRoundPlayerData[index][0][plyTimeStartAlive] = time;
                    g_strRoundPlayerData[index][0][plyTimeStartUpright] = time;
                    g_strRoundPlayerData[index][1][plyTimeStartPresent] = time;
                    g_strRoundPlayerData[index][1][plyTimeStartAlive] = time;
                    g_strRoundPlayerData[index][1][plyTimeStartUpright] = time;
                }
                else {
                    g_strRoundPlayerInfData[index][0][infTimeStartPresent] = time;
                }
            }
        }
        
        // set time for bots aswell
        for ( i = 0; i < FIRST_NON_BOT; i++ ) {
            g_strRoundPlayerData[i][0][plyTimeStartPresent] = time;
            g_strRoundPlayerData[i][0][plyTimeStartAlive] = time;
            g_strRoundPlayerData[i][0][plyTimeStartUpright] = time;
            g_strRoundPlayerData[i][1][plyTimeStartPresent] = time;
            g_strRoundPlayerData[i][1][plyTimeStartAlive] = time;
            g_strRoundPlayerData[i][1][plyTimeStartUpright] = time;
        }
        
        // just assume this
        g_bInRound = true;
        g_bPlayersLeftStart = true;
        
        g_strGameData[gmStartTime] = GetTime();
        g_strRoundData[0][0][rndStartTime] = GetTime();
        g_strRoundData[0][1][rndStartTime] = GetTime();
        
        // team
        g_iCurTeam = ( g_bModeCampaign ) ? 0 : GetCurrentTeamSurvivor();
        UpdatePlayerCurrentTeam();
    }
}

/*
    Commands
    --------
*/

public Action: Cmd_Say ( client, args ) {
    // catch and hide !<command>s
    if (!client) { return Plugin_Continue; }
    
    decl String:sMessage[MAXNAME];
    GetCmdArg(1, sMessage, sizeof(sMessage));
    
    if (    StrEqual(sMessage, "!mvp")   ||
            StrEqual(sMessage, "!ff")    ||
            StrEqual(sMessage, "!stats")
    ) {
        return Plugin_Handled;
    }
    
    return Plugin_Continue;
}

public Action: Cmd_StatsDisplayGeneral ( client, args ) {
    // determine main type
    new iType = typGeneral;
    
    new String: sArg[24];
    GetCmdArg( 0, sArg, sizeof(sArg) );
    
    // determine main type (the command typed)
    if ( StrEqual(sArg, "sm_mvp", false) ) {        iType = typMVP; }
    else if ( StrEqual(sArg, "sm_ff", false) ) {    iType = typFF; }
    else if ( StrEqual(sArg, "sm_skill", false) ) { iType = typSkill; }
    else if ( StrEqual(sArg, "sm_acc", false) ) {   iType = typAcc; }
    else if ( StrEqual(sArg, "sm_inf", false) ) {   iType = typInf; }
    
    new bool:bSetRound, bool:bRound = true;
    new bool:bSetGame,  bool:bGame = false;
    new bool:bSetAll,   bool:bAll = false;
    new bool:bOther = false;
    new bool:bTank = false;
    new bool:bMore = false;
    new bool:bMy = false;
    new iStart = 1;
    
    new otherTeam = (g_iCurTeam) ? 0 : 1;
    
    if ( args ) {
        GetCmdArg( 1, sArg, sizeof(sArg) );
        
        // find type selection (always 1)
        if ( StrEqual(sArg, "help", false) || StrEqual(sArg, "?", false) ) {
            // show help
            if ( IS_VALID_INGAME(client) ) {
                PrintToChat( client, "\x01Use: /stats [<type>] [\x05round\x01/\x05game\x01/\x05team\x01/\x05all\x01/\x05other\x01]" );
                PrintToChat( client, "\x01 or: /stats [<type>] [\x05r\x01/\x05g\x01/\x05t\x01/\x05a\x01/\x05o\x01]" );
                PrintToChat( client, "\x01 where <type> is '\x04mvp\x01', '\x04skill\x01', '\x04ff\x01', '\x04acc\x01' or '\x04inf\x01'. (for more, see console)" );
            }
            
            decl String:bufBasic[CONBUFSIZELARGE];
            Format(bufBasic, CONBUFSIZELARGE,    "|------------------------------------------------------------------------------|\n");
            Format(bufBasic, CONBUFSIZELARGE,  "%s| /stats command help      in chat:    '/stats <type> [argument [argument]]'   |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|                          in console: 'sm_stats <type> [arguments...]'        |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|------------------------------------------------------------------------------|\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s| stat type:   'general':  general statistics about the game, as in campaign   |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|              'mvp'    :  SI damage, common kills    (extra argument: 'tank') |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|              'skill'  :  skeets, levels, crowns, tongue cuts, etc            |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|              'ff'     :  friendly fire damage (per type of weapon)           |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|              'acc'    :  accuracy details           (extra argument: 'more') |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|              'inf'    :  special infected stats (dp's, damage done etc)      |", bufBasic);
            if ( IS_VALID_INGAME(client) ) { PrintToConsole( client, bufBasic); } else { PrintToServer( bufBasic); }
            
            Format(bufBasic, CONBUFSIZELARGE,    "|------------------------------------------------------------------------------|\n");
            Format(bufBasic, CONBUFSIZELARGE,  "%s| arguments:                                                                   |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|------------------------------------------------------------------------------|\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   'round' ('r') / 'game' ('g') : for this round; or for entire game so far   |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   'team' ('t') / 'all' ('a')   : current survivor team only; or all players  |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   'other' ('o') / 'my'         : team that is now infected; or your team NMW |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   'tank'          [ MVP only ] : show stats for tank fight                   |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   'more'    [ ACC & MVP only ] : show more stats ( MVP time / SI/tank hits ) |", bufBasic);
            if ( IS_VALID_INGAME(client) ) { PrintToConsole( client, bufBasic); } else { PrintToServer( bufBasic); }
            
            Format(bufBasic, CONBUFSIZELARGE,    "|------------------------------------------------------------------------------|\n");
            Format(bufBasic, CONBUFSIZELARGE,  "%s| examples:                                                                    |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|------------------------------------------------------------------------------|\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   '/stats skill round all' => shows skeets etc for all players, this round   |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   '/stats ff team game'    => shows active team's friendly fire, this round  |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   '/stats acc my'          => shows accuracy stats (your team, this round)   |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|   '/stats mvp tank'        => shows survivor action while tank is/was up     |\n", bufBasic);
            Format(bufBasic, CONBUFSIZELARGE,  "%s|------------------------------------------------------------------------------|", bufBasic);
            if ( IS_VALID_INGAME(client) ) { PrintToConsole( client, bufBasic); } else { PrintToServer( bufBasic); }
            return Plugin_Handled;
        }
        else if ( StrEqual(sArg, "mvp", false) ) { iType = typMVP; iStart++; }
        else if ( StrEqual(sArg, "ff", false) ) { iType = typFF; iStart++; }
        else if ( StrEqual(sArg, "skill", false) || StrEqual(sArg, "special", false) || StrEqual(sArg, "s", false) ) { iType = typSkill; iStart++; }
        else if ( StrEqual(sArg, "acc", false) || StrEqual(sArg, "accuracy", false) || StrEqual(sArg, "ac", false) ) { iType = typAcc; iStart++; }
        else if ( StrEqual(sArg, "inf", false) || StrEqual(sArg, "i", false) ) { iType = typInf; iStart++; }
        else if ( StrEqual(sArg, "fact", false) || StrEqual(sArg, "fun", false) ) { iType = typFact; iStart++; }
        else if ( StrEqual(sArg, "general", false) || StrEqual(sArg, "gen", false) ) { iType = typGeneral; iStart++; }
        
        // check each other argument and see what we find
        for ( new i = iStart; i <= args; i++ ) {
            GetCmdArg( i, sArg, sizeof(sArg) );
            
            if ( StrEqual(sArg, "round", false)     || StrEqual(sArg, "r", false) ) {
                bSetRound = true; bRound = true;
            }
            else if ( StrEqual(sArg, "game", false) || StrEqual(sArg, "g", false) ) {
                bSetGame = true; bGame = true;
            }
            else if ( StrEqual(sArg, "all", false)  || StrEqual(sArg, "a", false) ) {
                bSetAll = true; bAll = true;
            }
            else if ( StrEqual(sArg, "team", false) || StrEqual(sArg, "t", false) ) {
                if ( bSetAll ) { bSetAll = true; bAll = false; }
            }
            else if ( StrEqual(sArg, "other", false) || StrEqual(sArg, "o", false) || StrEqual(sArg, "otherteam", false) ) {
                bOther = true;
            }
            else if ( StrEqual(sArg, "more", false) || StrEqual(sArg, "m", false) ) {
                bMore = true;
            }
            else if ( StrEqual(sArg, "tank", false) ) {
                bTank = true;
            }
            else if ( StrEqual(sArg, "my", false) ) {
                bMy = true;
            }
            else {
                if ( IS_VALID_INGAME(client) ) {
                    PrintToChat( client, "Stats command: unknown argument: '%s'. Type '/stats help' for possible arguments.", sArg );
                } else {
                    PrintToServer( "Stats command: unknown argument: '%s'. Type '/stats help' for possible arguments.", sArg );
                }
            }
        }
    }
    
    new iTeam = (bOther) ? otherTeam : -1;
    
    // what is 'my' team?
    if ( bMy ) {
        new index = GetPlayerIndexForClient( client );
        new curteam = -1;
        if ( index != -1 ) {
            curteam = g_iPlayerRoundTeam[LTEAM_CURRENT][index];
            if ( curteam != -1 ) {
                bSetAll = true;
                bAll = false;
                iTeam = curteam;
            } else {
                // fall back to default
                iTeam = -1;
            }
        }
    }
    
    switch ( iType ) {
        case typGeneral: {
            // game by default, unless overridden by 'round'
            //  the first -1 == round number (may think about allowing a number input here later)
            DisplayStats( client, ( bSetRound && bRound ) ? true : false, -1, ( bSetAll && bAll ) ? false : true, iTeam );
        }
        case typMVP: {
            // by default: only for round
            DisplayStatsMVP( client, bTank, bMore, ( bSetGame && bGame ) ? false : true, ( bSetAll && bAll ) ? false : true, iTeam );
            // only show chat for non-tank table
            if ( !bTank && !bMore ) {
                DisplayStatsMVPChat( client, ( bSetGame && bGame ) ? false : true, ( bSetAll && bAll ) ? false : true, iTeam );
            }
        }
        case typFF: {
            // by default: only for round
            DisplayStatsFriendlyFire( client, ( bSetGame && bGame ) ? false : true, ( bSetAll && bAll ) ? false : true, false, iTeam );
        }
        case typSkill: {
            // by default: only for round
            DisplayStatsSpecial( client, ( bSetGame && bGame ) ? false : true, ( bSetAll && bAll ) ? false : true, false, iTeam );
        }
        case typAcc: {
            // by default: only for round
            DisplayStatsAccuracy( client, bMore, ( bSetGame && bGame ) ? false : true, ( bSetAll && bAll ) ? false : true, false, iTeam );
        }
        case typInf: {
            // by default: only for round
            DisplayStatsInfected( client, ( bSetGame && bGame ) ? false : true, ( bSetAll && bAll ) ? false : true, false, iTeam );
        }
        case typFact: {
            DisplayStatsFunFactChat( client, ( bSetGame && bGame ) ? false : true, ( bSetAll && bAll ) ? false : true, iTeam );
        }
    }
    
    return Plugin_Handled;
}

public Action: Cmd_StatsReset ( client, args ) {
    ResetStats( false, -1 );
    PrintToChatAll( "Player statistics reset." );
    return Plugin_Handled;
}


/*
    Cookies and clientprefs
    -----------------------
*/
public Action: Cmd_Cookie_SetPrintFlags ( client, args ) {
    if ( !IS_VALID_INGAME(client) ) {
        PrintToServer( "This command can only be used by clients. Use the sm_stats_autoprint_* cvars to set server preferences." );
        return Plugin_Handled;
    }
    
    if ( args ) {
        decl String: sArg[24];
        GetCmdArg( 1, sArg, sizeof(sArg) );
        new iFlags = StringToInt( sArg );
        
        if ( StrEqual(sArg, "?", false) || StrEqual(sArg, "help", false) )  {
            PrintToChat( client, "\x01Use: \x04/stats_auto <flags>\x01. Flags is an integer that is the sum of all printouts to be displayed at round-end." );
            PrintToChat( client, "\x01Set flags to 0 to use server autoprint default; set to -1 to not display anything at all." );
            PrintToChat( client, "\x01See: \x05https://github.com/Tabbernaut/L4D2-Plugins/blob/master/stats/README.md\x01 for a list of flags." );
            return Plugin_Handled;
        }
        else if ( StrEqual(sArg, "test", false) || StrEqual(sArg, "preview", false) ) {
            if ( g_iCookieValue[client] < 1 ) {
                PrintToChat( client, "\x01Stats Preview: No flags set. First set flags with \x04/stats_auto <flags>\x01. Type \x04/stats_auto help\x01 for more info." );
                return Plugin_Handled;
            }
            AutomaticPrintPerClient( g_iCookieValue[client], client );
        }
        else if ( iFlags >= -1 ) {
            if ( iFlags == -1 ) {
                PrintToChat( client, "\x01Stats Pref.: \x04no round end prints at all\x01." );
            }
            else if ( iFlags == 0 ) {
                PrintToChat( client, "\x01Stats Pref.: \x04server default\x01." );
            }
            else {
                new String: tmpStr[14][24], String: tmpPrint[256];
                new part = 0;
                
                if ( iFlags & AUTO_MVPCHAT_ROUND ) {
                    Format( tmpStr[part], 24, "mvp/chat(round)" );
                    part++;
                }
                if ( iFlags & AUTO_MVPCHAT_GAME ) {
                    Format( tmpStr[part], 24, "mvp/chat(game)" );
                    part++;
                }
                if ( iFlags & AUTO_MVPCON_ROUND ) {
                    Format( tmpStr[part], 24, "mvp(round)" );
                    part++;
                }
                if ( iFlags & AUTO_MVPCON_GAME ) {
                    Format( tmpStr[part], 24, "mvp(game)" );
                    part++;
                }
                if ( iFlags & AUTO_MVPCON_MORE_ROUND ) {
                    Format( tmpStr[part], 24, "mvp/more(round)" );
                    part++;
                }
                if ( iFlags & AUTO_MVPCON_MORE_GAME ) {
                    Format( tmpStr[part], 24, "mvp/more(game)" );
                    part++;
                }
                if ( iFlags & AUTO_MVPCON_TANK ) {
                    Format( tmpStr[part], 24, "mvp/tankfight" );
                    part++;
                }
                if ( iFlags & AUTO_SKILLCON_ROUND ) {
                    Format( tmpStr[part], 24, "skill/special(round)" );
                    part++;
                }
                if ( iFlags & AUTO_SKILLCON_GAME ) {
                    Format( tmpStr[part], 24, "skill/special(game)" );
                    part++;
                }
                if ( iFlags & AUTO_FFCON_ROUND ) {
                    Format( tmpStr[part], 24, "ff(round)" );
                    part++;
                }
                if ( iFlags & AUTO_FFCON_GAME ) {
                    Format( tmpStr[part], 24, "ff(game)" );
                    part++;
                }
                if ( iFlags & AUTO_ACCCON_ROUND ) {
                    Format( tmpStr[part], 24, "accuracy(round)" );
                    part++;
                }
                if ( iFlags & AUTO_ACCCON_GAME ) {
                    Format( tmpStr[part], 24, "accuracy(game)" );
                    part++;
                }
                if ( iFlags & AUTO_ACCCON_MORE_ROUND ) {
                    Format( tmpStr[part], 24, "acc/more(round)" );
                    part++;
                }
                if ( iFlags & AUTO_ACCCON_MORE_GAME ) {
                    Format( tmpStr[part], 24, "acc/more(game)" );
                    part++;
                }
                
                PrintToChat( client, "\x01Stats Pref.: Flags set for:", tmpStr );
                // print all parts
                new tmpCnt = 0;
                for ( new i = 0; i < part; i++ ) {
                    Format( tmpPrint, sizeof(tmpPrint), "%s%s%s", tmpPrint, (tmpCnt) ? ", " : "", tmpStr[i] );
                    tmpCnt++;
                    
                    // print each chunk of 6
                    if ( tmpCnt >= 6 || i == part - 1 ) {
                        PrintToChat( client, "\x04%s%s\x01", tmpPrint, (i < part - 1) ? "," : "" );
                        tmpCnt = 0;
                        tmpPrint = "";
                    }
                }
                PrintToChat( client, "\x01Use \x04/stats_auto test\x01 to get a report preview.");
            }
            
            g_iCookieValue[client] = iFlags;
            
            if ( AreClientCookiesCached(client) ) {
                decl String:sCookieValue[16];
                IntToString(iFlags, sCookieValue, sizeof(sCookieValue));
                SetClientCookie( client, g_hCookiePrint, sCookieValue );
            }
            else {
                PrintToChat( client, "Stats Pref.: Error: cookie not cached yet (try again in a bit)." );
            }    
        }
        else {
            PrintToChat( client, "Stats Pref.: invalid value: '%s'. Type '/stats_auto help' for more info.", sArg );
        }
    }
    else {
        PrintToChat( client, "\x01Use: \x04/stats_auto <flags>\x01. Type \x04/stats_auto help\x01 for more info." );
    }
    
    return Plugin_Handled;
}

public OnClientCookiesCached ( client ) {
    decl String:sCookieValue[16];
    GetClientCookie( client, g_hCookiePrint, sCookieValue, sizeof(sCookieValue) );
    g_iCookieValue[client] = StringToInt( sCookieValue );
}

/*
    Forwards from custom_map_transitions
*/
// called when the first map is about to be loaded
public OnCMTStart( rounds, const String:mapname[] ) {
    // reset stats
    g_bCMTActive = true;
    PrintDebug(2, "CMT start. Rounds: %i. First map: %s", rounds, mapname);
    
    // reset all stats
    ResetStats( false, -1 );
}

// called after the last round has ended
public OnCMTEnd() {
    g_bCMTActive = false;
    PrintDebug(2, "CMT end.");
    
    HandleGameEnd();
}
// called when (before) CMT swaps logical teams in a round (this happens ~5 seconds after round start)
public OnCMTTeamSwap() {
    PrintDebug(2, "CMT TeamSwap.");

    // toggle CMT swap
    g_bCMTSwapped = !g_bCMTSwapped;

    // swap scores (they were stored for reversed teams)
    new iTmp = g_iScores[LTEAM_A];
    g_iScores[LTEAM_A] = g_iScores[LTEAM_B];
    g_iScores[LTEAM_B] = iTmp;

    iTmp = g_iFirstScoresSet[0];
    g_iFirstScoresSet[0] = g_iFirstScoresSet[1];
    g_iFirstScoresSet[1] = iTmp;
}

/*
    Stats cleanup
    -------------
*/
// stats reset (called on map start, clears both roundhalves)
public Action: Timer_ResetStats (Handle:timer, any:roundOnly) {
    // reset stats (for current team)
    ResetStats( bool:(roundOnly) );
}

// team -1 = clear both; failedround = campaign mode only
stock ResetStats ( bool:bCurrentRoundOnly = false, iTeam = -1, bool: bFailedRound = false ) {
    new i, j, k;
    
    PrintDebug( 1, "Resetting stats [round %i]. (for: %s; for team: %i)", g_iRound, (bCurrentRoundOnly) ? "this round" : "the game", iTeam );
    
    // if we're cleaning the entire GAME ('round' refers to two roundhalves here)
    if ( !bCurrentRoundOnly ) {
        // just so nobody gets robbed of seeing stats, print to all
        DisplayStats( );
        
        // clear game
        g_iRound = 0;
        g_bGameStarted = false;
        g_strGameData[gmFailed] = 0;
        
        // clear rounds
        for ( i = 0; i < MAXROUNDS; i++ ) {
            // no need to clear mapnames.. they are only shown when relevant anyway
            //if ( i > 0 ) { g_sMapName[i] = ""; }
            for ( j = 0; j < 2; j++ ) {
                for ( k = 0; k <= MAXRNDSTATS; k++ ) {
                    g_strRoundData[i][j][k] = 0;
                }
            }
        }
        for ( j = 0; j < 2; j++ ) {
            for ( k = 0; k <= MAXRNDSTATS; k++ ) {
                g_strAllRoundData[j][k] = 0;
            }
        }
        
        // clear players / team
        for ( i = 0; i < MAXTRACKED; i++ ) {
            for ( j = 0; j <= MAXPLYSTATS; j++ ) {
                g_strPlayerData[i][j] = 0;
            }
            for ( j = 0; j <= MAXINFSTATS; j++ ) {
                g_strPlayerInfData[i][j] = 0;
            }
            // clear all-game teams
            for ( j = 0; j < 2; j++ ) {
                g_iPlayerGameTeam[j][i] = -1;
            }
        }
        
        for ( j = 0; j < 2; j++ ) {
            g_iScores[j] = 0;
        }
    }
    else {
        if ( iTeam == -1 ) {
            for ( k = 0; k <= MAXRNDSTATS; k++ ) {
                if ( bFailedRound && k == _:rndRestarts ) { continue; }
                g_strRoundData[g_iRound][LTEAM_A][k] = 0;
                g_strRoundData[g_iRound][LTEAM_B][k] = 0;
            }
        }
        else {
            for ( k = 0; k <= MAXRNDSTATS; k++ ) {
                if ( bFailedRound && k == _:rndRestarts ) { continue; }
                g_strRoundData[g_iRound][iTeam][k] = 0;
            }
        }
    }
    
    // other round data
    if ( iTeam == -1 ) {   // both
        // round data for players
        for ( i = 0; i < MAXTRACKED; i++ ) {
            for ( j = 0; j < 2; j++ ) {
                for ( k = 0; k <= MAXPLYSTATS; k++ ) {
                    g_strRoundPlayerData[i][j][k] = 0;
                }
                for ( k = 0; k <= MAXPLYSTATS; k++ ) {
                    g_strRoundPlayerInfData[i][j][k] = 0;
                }
                for ( k = 0; k < MAXTRACKED; k++ ) {
                    g_strRoundPvPFFData[i][j][k] = 0;
                    g_strRoundPvPInfDmgData[i][j][k] = 0;
                }
            }
        }
    }
    else {
        // round data for players
        for ( i = 0; i < MAXTRACKED; i++ ) {
            for ( k = 0; k <= MAXPLYSTATS; k++ ) {
                g_strRoundPlayerData[i][iTeam][k] = 0;
            }
            for ( k = 0; k <= MAXINFSTATS; k++ ) {
                g_strRoundPlayerInfData[i][iTeam][k] = 0;
            }
            for ( k = 0; k < MAXTRACKED; k++ ) {
                g_strRoundPvPFFData[i][iTeam][k] = 0;
                g_strRoundPvPInfDmgData[i][iTeam][k] = 0;
            }
        }
    }
}

stock UpdatePlayerCurrentTeam() {
    new client, index;
    new time = GetTime();
    
    new bool: botPresent[4];
    
    // if paused, add the full pause time so far,
    // so that it will get substracted neatly when the
    // game unpauses
    
    // reset
    ClearPlayerTeam( LTEAM_CURRENT );
    
    // find all survivors
    // find all infected
    
    for ( client = 1; client <= MaxClients; client++ ) {
        if ( !IS_VALID_INGAME(client) ) { continue; }
        
        index = GetPlayerIndexForClient( client );
        if ( index == -1 ) { continue; }
        
        if ( IS_VALID_SURVIVOR(client) ) {
            g_iPlayerRoundTeam[LTEAM_CURRENT][index] = g_iCurTeam;

            if ( !g_bPlayersLeftStart ) { continue; }
            
            // check bots
            if ( index < FIRST_NON_BOT ) { botPresent[index] = true; }
            
            // for tracking which players ever were in the team (only useful if they were in the team when round was live)
            g_iPlayerRoundTeam[g_iCurTeam][index] = g_iCurTeam;
            g_iPlayerGameTeam[g_iCurTeam][index] = g_iCurTeam;
            
            // if player wasn't present, update presence (shift start forward)
            
            if ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] = time - ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] - g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] );
            } else if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] = time;
            }
            g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] = 0;
            if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] -= time - g_iPauseStart; }
            
            // if player wasn't alive and is now, update -- if never joined and dead, start = stop
            if ( IsPlayerAlive(client) ) {
                if ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] ) {
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] = time - ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] - g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] );
                } else if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] ) {
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] = time;
                }
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] = 0;
                if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] -= time - g_iPauseStart; }
            }
            else if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] = time;
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] = time;
            }
            
            
            // if player wasn't upright and is now, update -- if never joined and incapped, start = stop
            if ( !IsPlayerIncapacitatedAtAll(client) && IsPlayerAlive(client) ) {
                if ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] ) {
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] = time - ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] - g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] );
                } else if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] ) {
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] = time;
                }
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] = 0;
                if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] -= time - g_iPauseStart; }
            }
            else  if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] = time;
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] = time;
            }
            
            // if the player moved here from the other team, stop his presence time (as infected)
            if ( !g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] && g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] ) {
                g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] = time;
                if ( g_bPaused ) { g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] -= time - g_iPauseStart; }
            }
        }
        else {
            if ( IS_VALID_INFECTED(client) ) {
                g_iPlayerRoundTeam[LTEAM_CURRENT][index] = (g_iCurTeam) ? 0 : 1;
                
                if ( g_bPlayersLeftStart ) {
                    if ( index >= FIRST_NON_BOT ) {
                        g_iPlayerRoundTeam[g_iCurTeam][index] = (g_iCurTeam) ? 0 : 1;
                        g_iPlayerGameTeam[g_iCurTeam][index] = (g_iCurTeam) ? 0 : 1;
                        
                        if ( g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] && g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] ) {
                            g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] = time - ( g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] - g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] );
                        } else if ( !g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] ) {
                            g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] = time;
                        }
                        g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] = 0;
                        if ( g_bPaused ) { g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] -= time - g_iPauseStart; }
                    }
                }
            }
            else  {
                g_iPlayerRoundTeam[LTEAM_CURRENT][index] = -1;
                
                // if the player moved here from the other team, stop his presence time
                if ( !g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] && g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] ) {
                    g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] = time;
                    if ( g_bPaused ) { g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] -= time - g_iPauseStart; }
                }
            }
            
            // if the player moved here from the other team, stop his presence time
            if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] = time;
                if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] -= time - g_iPauseStart; }
            }
            if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] = time;
                if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] -= time - g_iPauseStart; }
            }
            if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] = time;
                if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] -= time - g_iPauseStart; }
            }
        }
    }
    
    /*
        bots don't work as normal -- they just disappear
        check which bots are here, and consider the other
        bots to have moved instead
    
    */
    if ( g_bPlayersLeftStart ) {
        for ( index = 0; index < FIRST_NON_BOT; index++ ) {
            if ( botPresent[index] ) { continue; }
            
            // if the bot was removed from survivors:
            if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] = time;
                if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] -= time - g_iPauseStart; }
            }
            if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] = time;
                if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] -= time - g_iPauseStart; }
            }
            if ( !g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] && g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] ) {
                g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] = time;
                if ( g_bPaused ) { g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] -= time - g_iPauseStart; }
            }
        }
    }
}

stock ClearPlayerTeam ( iTeam = -1 ) {
    new i, j;
    
    if ( iTeam == -1 ) {
        // clear all
        for ( j = 0; j < 3; j++ ) {
            for ( i = 0; i < MAXTRACKED; i++ ) {
                g_iPlayerRoundTeam[j][i] = -1;
            }
        }
    }
    else {
        for ( i = 0; i < MAXTRACKED; i++ ) {
            g_iPlayerRoundTeam[iTeam][i] = -1;
        }
    }
}

stock SetStartSurvivorTime ( bool:bGame = false, bool:bRestart = false ) {
    new client, index;
    new time = GetTime();
    
    for ( client = 1; client <= MaxClients; client++ ) {
        if ( !IS_VALID_INGAME(client) ) { continue; }
        
        index = GetPlayerIndexForClient( client );
        if ( index == -1 ) { continue; }
        
        if ( IS_VALID_SURVIVOR(client) ) {
            if ( bGame ) {
                g_strPlayerData[index][plyTimeStartPresent] = time;
                g_strPlayerData[index][plyTimeStartAlive] = time;
                g_strPlayerData[index][plyTimeStartUpright] = time;
            }
            else {
                if ( bRestart ) {
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] = time - ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopPresent] - g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] );
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] = time - ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopAlive] - g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] );
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] = time - ( g_strRoundPlayerData[index][g_iCurTeam][plyTimeStopUpright] - g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] );
                }
                else {
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartPresent] = time;
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartAlive] = time;
                    g_strRoundPlayerData[index][g_iCurTeam][plyTimeStartUpright] = time;
                }
            }
        }
        else if ( IS_VALID_INFECTED(client) ) {
            if ( bGame ) {
                g_strPlayerInfData[index][infTimeStartPresent] = time;
            }
            else {
                if ( bRestart ) {
                    g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] = time - ( g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStopPresent] - g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] );
                }
                else {
                    g_strRoundPlayerInfData[index][g_iCurTeam][infTimeStartPresent] = time;
                }
            }
        }
    }
}

stock SortPlayersMVP ( bool:bRound = true, sortCol = SORT_SI, bool:bTeam = true, iTeam = -1 ) {
    new iStored = 0;
    new i, j;
    new bool: found, highest, highTeam, pickTeam;
    
    if ( sortCol < SORT_SI || sortCol > MAXSORTS -1 ) { return; }
    
    new team = ( iTeam != -1 ) ? iTeam : ( ( g_bSecondHalf && !g_bPlayersLeftStart ) ? ( (g_iCurTeam) ? 0 : 1) : g_iCurTeam );
    
    while ( iStored < g_iPlayers ) {
        highest = -1;
        
        for ( i = 0; i < g_iPlayers; i++ ) {
            // if we already sorted the index, skip it
            found = false;
            for ( j = 0; j < iStored; j++ ) {
                if ( g_iPlayerIndexSorted[sortCol][j] == i ) { found = true; }
            }
            if ( found ) { continue; }
            
            // if the index is the (next) highest, take it
            switch ( sortCol ) {
                case SORT_SI: {
                    if ( bRound ) {
                        if ( bTeam ) {
                            if (    highest == -1 ||
                                    g_strRoundPlayerData[i][team][plySIDamage] > g_strRoundPlayerData[highest][team][plySIDamage] || 
                                    g_strRoundPlayerData[i][team][plySIDamage] == g_strRoundPlayerData[highest][team][plySIDamage] &&
                                        (   g_strRoundPlayerData[i][team][plyCommon] > g_strRoundPlayerData[highest][team][plyCommon] ||
                                            ( g_strRoundPlayerData[i][team][plyCommon] == g_strRoundPlayerData[highest][team][plyCommon] && highest < FIRST_NON_BOT ) )
                            ) {
                                highest = i;
                            }
                        }
                        else {
                            pickTeam = ( g_strRoundPlayerData[i][LTEAM_A][plySIDamage] >= g_strRoundPlayerData[i][LTEAM_B][plySIDamage] ) ? LTEAM_A : LTEAM_B;
                            if (    highest == -1 ||
                                    g_strRoundPlayerData[i][pickTeam][plySIDamage] > g_strRoundPlayerData[highest][highTeam][plySIDamage] ||
                                    g_strRoundPlayerData[i][pickTeam][plySIDamage] == g_strRoundPlayerData[highest][highTeam][plySIDamage] &&
                                        (   g_strRoundPlayerData[i][pickTeam][plyCommon] > g_strRoundPlayerData[highest][highTeam][plyCommon] ||
                                            ( g_strRoundPlayerData[i][pickTeam][plyCommon] == g_strRoundPlayerData[highest][highTeam][plyCommon] && highest < FIRST_NON_BOT ) )
                            ) {
                                highest = i;
                                g_iPlayerSortedUseTeam[sortCol][i] = pickTeam;
                                highTeam = pickTeam;
                            }
                        }
                    }
                    else {
                        if (    highest == -1 ||
                                g_strPlayerData[i][plySIDamage] > g_strPlayerData[highest][plySIDamage] ||
                                g_strPlayerData[i][plySIDamage] == g_strPlayerData[highest][plySIDamage] &&
                                    (   g_strPlayerData[i][plyCommon] > g_strPlayerData[highest][plyCommon] ||
                                        ( g_strPlayerData[i][plyCommon] == g_strPlayerData[highest][plyCommon] && highest < FIRST_NON_BOT ) )
                        ) {
                            highest = i;
                        }
                    }
                }
                case SORT_CI: {
                    if ( bRound ) {
                        if ( bTeam ) {
                            if (    highest == -1 ||
                                    g_strRoundPlayerData[i][team][plyCommon] > g_strRoundPlayerData[highest][team][plyCommon] ||
                                    g_strRoundPlayerData[i][team][plyCommon] == g_strRoundPlayerData[highest][team][plyCommon] &&
                                        (   g_strRoundPlayerData[i][team][plySIDamage] > g_strRoundPlayerData[highest][team][plySIDamage] ||
                                            ( g_strRoundPlayerData[i][team][plySIDamage] == g_strRoundPlayerData[highest][team][plySIDamage] && highest < FIRST_NON_BOT ) )
                            ) {
                                highest = i;
                            }
                        } else {
                            pickTeam = ( g_strRoundPlayerData[i][LTEAM_A][plyCommon] >= g_strRoundPlayerData[i][LTEAM_B][plyCommon] ) ? LTEAM_A : LTEAM_B;
                            if (    highest == -1 ||
                                    g_strRoundPlayerData[i][pickTeam][plyCommon] > g_strRoundPlayerData[highest][highTeam][plyCommon] ||
                                    g_strRoundPlayerData[i][pickTeam][plyCommon] == g_strRoundPlayerData[highest][highTeam][plyCommon] &&
                                        (   g_strRoundPlayerData[i][pickTeam][plySIDamage] > g_strRoundPlayerData[highest][highTeam][plySIDamage] ||
                                            ( g_strRoundPlayerData[i][pickTeam][plySIDamage] == g_strRoundPlayerData[highest][highTeam][plySIDamage] && highest < FIRST_NON_BOT ) )
                            ) {
                                highest = i;
                                g_iPlayerSortedUseTeam[sortCol][i] = pickTeam;
                                highTeam = pickTeam;
                            }
                        }
                    }
                    else {
                        if (    highest == -1 ||
                                g_strPlayerData[i][plyCommon] > g_strPlayerData[highest][plyCommon] ||
                                g_strPlayerData[i][plyCommon] == g_strPlayerData[highest][plyCommon] &&
                                    (   g_strPlayerData[i][plySIDamage] > g_strPlayerData[highest][plySIDamage] ||
                                        ( g_strPlayerData[i][plySIDamage] == g_strPlayerData[highest][plySIDamage] && highest < FIRST_NON_BOT ) )
                        ) {
                            highest = i;
                        }
                    }
                }
                case SORT_FF: {
                    if ( bRound ) {
                        if ( bTeam ) {
                            if (    highest == -1 ||
                                    g_strRoundPlayerData[i][team][plyFFGiven] > g_strRoundPlayerData[highest][team][plyFFGiven]
                            ) {
                                highest = i;
                            }
                        } else {
                            pickTeam = ( g_strRoundPlayerData[i][LTEAM_A][plyFFGiven] >= g_strRoundPlayerData[i][LTEAM_B][plyFFGiven] ) ? LTEAM_A : LTEAM_B;
                            if (    highest == -1 ||
                                    g_strRoundPlayerData[i][pickTeam][plyFFGiven] > g_strRoundPlayerData[highest][highTeam][plyFFGiven]
                            ) {
                                highest = i;
                                g_iPlayerSortedUseTeam[sortCol][i] = pickTeam;
                                highTeam = pickTeam;
                            }
                        }
                        
                    }
                    else {
                        if (    highest == -1 ||
                                g_strPlayerData[i][plyFFGiven] > g_strPlayerData[highest][plyFFGiven]
                        ) {
                            highest = i;
                        }
                    }
                }
                case SORT_INF: {
                    if ( bRound ) {
                        if ( bTeam ) {
                            if (    highest == -1 ||
                                    g_strRoundPlayerInfData[i][team][infDmgUpright] > g_strRoundPlayerInfData[highest][team][infDmgUpright]
                            ) {
                                highest = i;
                            }
                        } else {
                            pickTeam = ( g_strRoundPlayerInfData[i][LTEAM_A][infDmgUpright] >= g_strRoundPlayerInfData[i][LTEAM_B][infDmgUpright] ) ? LTEAM_A : LTEAM_B;
                            if (    highest == -1 ||
                                    g_strRoundPlayerInfData[i][pickTeam][infDmgUpright] > g_strRoundPlayerInfData[highest][highTeam][infDmgUpright]
                            ) {
                                highest = i;
                                g_iPlayerSortedUseTeam[sortCol][i] = pickTeam;
                                highTeam = pickTeam;
                            }
                        }
                        
                    }
                    else {
                        if (    highest == -1 ||
                                g_strPlayerInfData[i][infDmgUpright] > g_strPlayerInfData[highest][infDmgUpright]
                        ) {
                            highest = i;
                        }
                    }
                }
            }
        }
    
        g_iPlayerIndexSorted[sortCol][iStored] = highest;
        iStored++;
    }
}

// return the player index for the player with the highest value for a given prop
stock GetPlayerWithHighestValue ( property, bool:bRound = true, bool:bTeam = true, team = -1, bool:bInfected = false ) {
    new i, highest, highTeam, pickTeam;
    
    //new team = ( iTeam != -1 ) ? iTeam : ( ( g_bSecondHalf && !g_bPlayersLeftStart ) ? ( (g_iCurTeam) ? 0 : 1) : g_iCurTeam );
    
    highest = -1;
    
    if ( bInfected ) {
        for ( i = FIRST_NON_BOT; i < g_iPlayers; i++ ) {
            // if the index is the highest, take it
            if ( bRound ) {
                if ( bTeam ) {
                    if ( highest == -1 || g_strRoundPlayerInfData[i][team][property] > g_strRoundPlayerInfData[highest][team][property] ) {
                        highest = i;
                    }
                }
                else {
                    pickTeam = ( g_strRoundPlayerInfData[i][LTEAM_A][property] >= g_strRoundPlayerInfData[i][LTEAM_B][property] ) ? LTEAM_A : LTEAM_B;
                    if ( highest == -1 || g_strRoundPlayerInfData[i][pickTeam][property] > g_strRoundPlayerInfData[highest][highTeam][property] ) {
                        highest = i;
                        highTeam = pickTeam;
                    }
                }
            }
            else {
                if ( highest == -1 || g_strPlayerInfData[i][property] > g_strPlayerInfData[highest][property] ) {
                    highest = i;
                }
            }
        }
    }
    else {
        for ( i = FIRST_NON_BOT; i < g_iPlayers; i++ ) {
            // if the index is the highest, take it
            if ( bRound ) {
                if ( bTeam ) {
                    if ( highest == -1 || g_strRoundPlayerData[i][team][property] > g_strRoundPlayerData[highest][team][property] ) {
                        highest = i;
                    }
                }
                else {
                    pickTeam = ( g_strRoundPlayerData[i][LTEAM_A][property] >= g_strRoundPlayerData[i][LTEAM_B][property] ) ? LTEAM_A : LTEAM_B;
                    if ( highest == -1 || g_strRoundPlayerData[i][pickTeam][property] > g_strRoundPlayerData[highest][highTeam][property] ) {
                        highest = i;
                        highTeam = pickTeam;
                    }
                }
            }
            else {
                if ( highest == -1 || g_strPlayerData[i][property] > g_strPlayerData[highest][property] ) {
                    highest = i;
                }
            }
        }
    }
    
    return highest;
}
stock TableIncludePlayer ( index, team, bool:bRound = true, bool:bReverseTeam = false, statA = plySIDamage, statB = plyCommon ) {
    // not on team at all: don't show
    if ( bReverseTeam ) {
        if ( g_iPlayerRoundTeam[team][index] != ((team) ? 0 : 1) ) { return false; }
    } else {
        if ( g_iPlayerRoundTeam[team][index] != team ) { return false; }
    }
    
    // if on team right now, always show (or was last round?)
    if ( g_bPlayersLeftStart ) {
        if ( bReverseTeam ) {
            // no specs, only real infected
            if (    (   g_strRoundPlayerInfData[index][team][infTimeStartPresent]   &&
                        (   g_strRoundPlayerInfData[index][team][infSpawns] ||
                            g_strRoundPlayerInfData[index][team][infTankPasses] )
                    ) &&
                    team == g_iCurTeam &&
                    g_iPlayerRoundTeam[LTEAM_CURRENT][index] == ((team) ? 0 : 1) &&
                    index >= FIRST_NON_BOT
            ) {
                return true;
            }
        }
        else {
            if ( team == g_iCurTeam && g_iPlayerRoundTeam[LTEAM_CURRENT][index] == team ) { return true; }
        }
    }
    else if ( !bRound ) {
        // if player was never on the team, don't show
        if ( bReverseTeam ) {
            // no specs, only real infected
            if (    !(  g_strPlayerInfData[index][infTimeStartPresent]   &&
                        (   g_strPlayerInfData[index][infSpawns] ||
                            g_strPlayerInfData[index][infTankPasses] )
                    ) ||
                    g_iPlayerGameTeam[team][index] != ((team) ? 0 : 1) ||
                    index < FIRST_NON_BOT
            ) {
                return false;
            }
        }
        else {
            if (    !(  g_strPlayerData[index][plyTimeStartPresent]     ||
                        g_strPlayerData[index][statA]                   ||
                        g_strPlayerData[index][statB]
                    ) ||
                    g_iPlayerGameTeam[team][index] != team
            ) {
                return false;
            }
        }
    }
    else {
        // just allow it if he is currently a survivor
        if ( index >= FIRST_NON_BOT ) {
            if ( !IsIndexSurvivor(index, bReverseTeam) ) {
                if ( team == g_iCurTeam ) { return false; }
            } else { 
                if ( team != g_iCurTeam ) { return false; }
            }
        }
    }
    
    // has positive relevant scores? show
    if ( bReverseTeam ) {
        if ( bRound ) {
            if ( g_strRoundPlayerInfData[index][team][statA] || g_strRoundPlayerInfData[index][team][statB] ) { return true; }
        } else {
            if ( g_strPlayerInfData[index][statA] || g_strPlayerInfData[index][statB] ) { return true; }
        }
    } else {
        if ( bRound ) {
            if ( g_strRoundPlayerData[index][team][statA] || g_strRoundPlayerData[index][team][statB] ) { return true; }
        } else {
            if ( g_strPlayerData[index][statA] || g_strPlayerData[index][statB] ) { return true; }
        }
    }
    
    // this point, any bot should not be shown
    if ( index < FIRST_NON_BOT ) { return false; }
    
    // been on the team for longer than X seconds? show
    new presTime = 0;
    new time = GetTime();
    
    if ( !bReverseTeam ) {
        if ( bRound ) {
            presTime = ( (g_strRoundPlayerData[index][team][plyTimeStopPresent]) ? g_strRoundPlayerData[index][team][plyTimeStopPresent] : time ) - g_strRoundPlayerData[index][team][plyTimeStartPresent];
        } else {
            presTime = ( (g_strPlayerData[index][plyTimeStopPresent]) ? g_strPlayerData[index][plyTimeStopPresent] : time ) - g_strPlayerData[index][plyTimeStartPresent];
        }
    }
    else {
        if ( bRound ) {
            presTime = ( (g_strRoundPlayerInfData[index][team][infTimeStopPresent]) ? g_strRoundPlayerInfData[index][team][infTimeStopPresent] : time ) - g_strRoundPlayerInfData[index][team][infTimeStartPresent];
        } else {
            presTime = ( (g_strPlayerInfData[index][infTimeStopPresent]) ? g_strPlayerInfData[index][infTimeStopPresent] : time ) - g_strPlayerInfData[index][infTimeStartPresent];
        }
    }
    if ( presTime >= MIN_TEAM_PRESENT_TIME ) { return true; }
    
    return false;
}

// get full, tank or pause time for this round, taking into account the time for a current/ongoing pause
stock GetFullRoundTime( bRound, bTeam, team, bool:bTank = false ) {
    new start = rndStartTime;
    new stop = rndEndTime;
    
    if ( bTank ) {
        start = rndStartTimeTank;
        stop = rndStopTimeTank;
    }
    
    // get full time of this round (or both roundhalves) / or game
    new fullTime = 0;
    new time = GetTime();
    
    if ( bRound ) {
        if ( bTeam ) {
            if ( g_strRoundData[g_iRound][team][start] ) {
                fullTime = ( (g_strRoundData[g_iRound][team][stop]) ? g_strRoundData[g_iRound][team][stop] : time ) - g_strRoundData[g_iRound][team][start];
                if ( g_bPaused && team == g_iCurTeam ) {
                    if ( !bTank || g_bTankInGame ) {
                        fullTime -= time - g_iPauseStart;
                    }
                }
            }
        }
        else {
            if ( g_strRoundData[g_iRound][LTEAM_A][start] ) {
                fullTime = ( (g_strRoundData[g_iRound][LTEAM_A][stop]) ? g_strRoundData[g_iRound][LTEAM_A][stop] : time ) - g_strRoundData[g_iRound][LTEAM_A][start];
                if ( g_bPaused && LTEAM_A == g_iCurTeam ) {
                    if ( !bTank || g_bTankInGame ) {
                        fullTime -= time - g_iPauseStart;
                    }
                }
            }
            if ( g_strRoundData[g_iRound][LTEAM_B][start] ) {
                fullTime += ( (g_strRoundData[g_iRound][LTEAM_B][stop]) ? g_strRoundData[g_iRound][LTEAM_B][stop] : time ) - g_strRoundData[g_iRound][LTEAM_B][start];
                if ( g_bPaused && LTEAM_B == g_iCurTeam ) {
                    if ( !bTank || g_bTankInGame ) {
                        fullTime -= time - g_iPauseStart;
                    }
                }
            }
        }
    }
    else {
        if ( bTeam ) {
            if ( g_strAllRoundData[team][start] ) {
                fullTime = ( (g_strAllRoundData[team][stop]) ? g_strAllRoundData[team][stop] : time ) - g_strAllRoundData[team][start];
                if ( g_bPaused && team == g_iCurTeam ) {
                    if ( !bTank || g_bTankInGame ) {
                        fullTime -= time - g_iPauseStart;
                    }
                }
            }
        }
        else {
            if ( g_strAllRoundData[LTEAM_A][start] ) {
                fullTime = ( (g_strAllRoundData[LTEAM_A][stop]) ? g_strAllRoundData[LTEAM_A][stop] : time ) - g_strAllRoundData[LTEAM_A][start];
                if ( g_bPaused && LTEAM_A == g_iCurTeam ) {
                    if ( !bTank || g_bTankInGame ) {
                        fullTime -= time - g_iPauseStart;
                    }
                }
            }
            if ( g_strAllRoundData[LTEAM_B][start] ) {
                fullTime += ( (g_strAllRoundData[LTEAM_B][stop]) ? g_strAllRoundData[LTEAM_B][stop] : time ) - g_strAllRoundData[LTEAM_B][start];
                if ( g_bPaused && LTEAM_B == g_iCurTeam ) {
                    if ( !bTank || g_bTankInGame ) {
                        fullTime -= time - g_iPauseStart;
                    }
                }
            }
        }
    }
    
    return fullTime;
}

// get full or current (if relevant) pause time
stock GetPauseTime( bRound, bTeam, team, bool: bCurrentOnly = false ) {
    new start = rndStartTimePause;
    new stop = rndStopTimePause;
    
    new fullTime = 0;
    new time = GetTime();
    
    if ( bCurrentOnly ) {
        if ( bRound ) {
            if ( g_bPaused && ( team == g_iCurTeam || !bTeam ) ) {
                fullTime += time - g_iPauseStart;
            }
        }
        return fullTime;
    }
    
    // get pause time
    if ( bRound ) {
        if ( bTeam ) {
            if ( g_strRoundData[g_iRound][team][start] && g_strRoundData[g_iRound][team][stop] ) {
                fullTime = g_strRoundData[g_iRound][team][stop] - g_strRoundData[g_iRound][team][start];
            }
            if ( g_bPaused && team == g_iCurTeam ) {
                fullTime += time - g_iPauseStart;
            }
        }
        else {
            if ( g_strRoundData[g_iRound][LTEAM_A][start] && g_strRoundData[g_iRound][LTEAM_A][stop] ) {
                fullTime = g_strRoundData[g_iRound][LTEAM_A][stop] - g_strRoundData[g_iRound][LTEAM_A][start];
            }
            if ( g_strRoundData[g_iRound][LTEAM_B][start] && g_strRoundData[g_iRound][LTEAM_B][stop] ) {
                fullTime += g_strRoundData[g_iRound][LTEAM_B][stop] - g_strRoundData[g_iRound][LTEAM_B][start];
            }
            if ( g_bPaused ) {
                fullTime += time - g_iPauseStart;
            }
        }
    }
    else {
        if ( bTeam ) {
            if ( g_strAllRoundData[team][start] && g_strAllRoundData[team][stop] ) {
                fullTime = g_strAllRoundData[team][stop] - g_strAllRoundData[team][start];
            }
            /* (doesn't include current round)
            if ( g_bPaused && team == g_iCurTeam ) {
                fullTime += time - g_iPauseStart;
            } */
        }
        else {
            if ( g_strAllRoundData[LTEAM_A][start] && g_strAllRoundData[LTEAM_A][stop] ) {
                fullTime = g_strAllRoundData[LTEAM_A][stop] - g_strAllRoundData[LTEAM_A][start];
            }
            if ( g_strAllRoundData[LTEAM_B][start] && g_strAllRoundData[LTEAM_B][stop] ) {
                fullTime += g_strAllRoundData[LTEAM_B][stop] - g_strAllRoundData[LTEAM_B][start];
            }
            /* if ( g_bPaused ) {
                fullTime += time - g_iPauseStart;
            } */
        }
    }
    
    return fullTime;
}

// safe furthest flow seen for each living survivor
stock SaveFurthestFlows() {
    new chr, Float: fTmp;
    
    for ( new i = 1; i <= MaxClients; i++ ) {
        if ( !IS_VALID_SURVIVOR(i) || !IsPlayerAlive(i) ) { continue; }
        
        chr = GetPlayerCharacter(i);
        fTmp = L4D2Direct_GetFlowDistance(i);
        
        g_strRoundPlayerData[i][g_iCurTeam][plyCurFlowDist] = RoundFloat(fTmp);
        
        if ( fTmp > g_fHighestFlow[chr] ) {
            g_fHighestFlow[chr] = fTmp;
            g_strRoundPlayerData[i][g_iCurTeam][plyFarFlowDist] = RoundFloat(fTmp);
        }
    }
}

public Action: Timer_SaveFlows ( Handle:timer ) {
    if ( !g_bPlayersLeftStart || !g_bInRound ) { return Plugin_Continue; }
    
    SaveFurthestFlows();
    
    return Plugin_Continue;
}

/*
    Tries
    -----
*/

stock InitTries() {
    // player index
    g_hTriePlayers = CreateTrie();
    
    // create 4 slots for bots
    SetTrieValue( g_hTriePlayers, "BOT_0", 0 );
    SetTrieValue( g_hTriePlayers, "BOT_1", 1 );
    SetTrieValue( g_hTriePlayers, "BOT_2", 2 );
    SetTrieValue( g_hTriePlayers, "BOT_3", 3 );
    g_sPlayerName[0] = "BOT [Nick/Bill]";
    g_sPlayerName[1] = "BOT [Rochelle/Zoey]";
    g_sPlayerName[2] = "BOT [Coach/Louis]";
    g_sPlayerName[3] = "BOT [Ellis/Francis]";
    g_sPlayerId[0] = "BOT_0";
    g_sPlayerId[1] = "BOT_1";
    g_sPlayerId[2] = "BOT_2";
    g_sPlayerId[3] = "BOT_3";
    g_iPlayers += FIRST_NON_BOT;
    
    for ( new i = 0; i < 4; i++ ) {
        g_sPlayerNameSafe[i] = g_sPlayerName[i];
    }
    
    // weapon recognition
    g_hTrieWeapons = CreateTrie();
    SetTrieValue(g_hTrieWeapons, "weapon_pistol",               WPTYPE_PISTOL);
    SetTrieValue(g_hTrieWeapons, "weapon_pistol_magnum",        WPTYPE_PISTOL);
    SetTrieValue(g_hTrieWeapons, "weapon_pumpshotgun",          WPTYPE_SHOTGUN);
    SetTrieValue(g_hTrieWeapons, "weapon_shotgun_chrome",       WPTYPE_SHOTGUN);
    SetTrieValue(g_hTrieWeapons, "weapon_autoshotgun",          WPTYPE_SHOTGUN);
    SetTrieValue(g_hTrieWeapons, "weapon_shotgun_spas",         WPTYPE_SHOTGUN);
    SetTrieValue(g_hTrieWeapons, "weapon_hunting_rifle",        WPTYPE_SNIPER);
    SetTrieValue(g_hTrieWeapons, "weapon_sniper_military",      WPTYPE_SNIPER);
    SetTrieValue(g_hTrieWeapons, "weapon_sniper_awp",           WPTYPE_SNIPER);
    SetTrieValue(g_hTrieWeapons, "weapon_sniper_scout",         WPTYPE_SNIPER);
    SetTrieValue(g_hTrieWeapons, "weapon_smg",                  WPTYPE_SMG);
    SetTrieValue(g_hTrieWeapons, "weapon_smg_silenced",         WPTYPE_SMG);
    SetTrieValue(g_hTrieWeapons, "weapon_smg_mp5",              WPTYPE_SMG);
    SetTrieValue(g_hTrieWeapons, "weapon_rifle",                WPTYPE_SMG);
    SetTrieValue(g_hTrieWeapons, "weapon_rifle_desert",         WPTYPE_SMG);
    SetTrieValue(g_hTrieWeapons, "weapon_rifle_ak47",           WPTYPE_SMG);
    SetTrieValue(g_hTrieWeapons, "weapon_rifle_sg552",          WPTYPE_SMG);
    SetTrieValue(g_hTrieWeapons, "weapon_rifle_m60",            WPTYPE_SMG);
    //SetTrieValue(g_hTrieWeapons, "weapon_melee",               WPTYPE_NONE);
    //SetTrieValue(g_hTrieWeapons, "weapon_chainsaw",            WPTYPE_NONE);
    //SetTrieValue(g_hTrieWeapons, "weapon_grenade_launcher",    WPTYPE_NONE);
    
    g_hTrieEntityCreated = CreateTrie();
    SetTrieValue(g_hTrieEntityCreated, "infected",              OEC_INFECTED);
    SetTrieValue(g_hTrieEntityCreated, "witch",                 OEC_WITCH);
    
    // finales
    g_hTrieMaps = CreateTrie();
    SetTrieValue(g_hTrieMaps, "c1m4_atrium",                    MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c2m5_concert",                   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c3m4_plantation",                MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c4m5_milltown_escape",           MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c5m5_bridge",                    MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c6m3_port",                      MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c7m3_port",                      MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c8m5_rooftop",                   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c9m2_lots",                      MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c10m5_houseboat",                MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c11m5_runway",                   MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c12m5_cornfield",                MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c13m4_cutthroatcreek",           MP_FINALE);

    SetTrieValue(g_hTrieMaps, "2019_M3b",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "bhm4_base",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "bloodtracks_04",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d2_bts06_school",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "cwm4_building",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "cotd04_rooftop",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d2_city17_05",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d2_ff05_station",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "dkr_m5_stadium",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d2_darkblood04_extraction",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d2_daybreak05_rescue",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "ddg3_bluff_v2_1",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "deadbeat04_park",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d_dbd2dc_new_dawn",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "death_sentence_5",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "cdta_05finalroad",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "dprm5_milltown_escape",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "ec05_quarry",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c1m1_hotel_d_insane",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "hf04_escape",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "BombShelter",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "highway05_afb02_20130820",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d_ihm05_lakeside",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "jsarena204_arena",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d2_diescraper4_top_361",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d2_diescraper4_top_361",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d_149_5",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d_tbm_5",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "x1m5_salvation",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d_ravenholm05_docks",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "l4d2_stadium5_stadium",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "eu05_train_b16",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "uz_escape",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "uf4_airfield",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "mnac",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "wfp4_commstation",             MP_FINALE);
    SetTrieValue(g_hTrieMaps, "c1_mario1_4",             MP_FINALE);

}
