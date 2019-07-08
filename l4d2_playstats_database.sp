#pragma semicolon 1

#include <sourcemod>
#include <l4d2_playstats>
#include <l4d2_playstats_database>

public Plugin:myinfo =
{
    name = "Player Statistics Database",
    author = "devilesk",
    version = "1.0.0",
    description = "L4D2 Playstats database functions.",
    url = "https://steamcommunity.com/groups/RL4D2L"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    RegPluginLibrary("l4d2_playstats_database");
    
    CreateNative("IsDatabaseConnected", Native_IsDatabaseConnected);
    CreateNative("PrepareRoundQuery", Native_PrepareRoundQuery);
    CreateNative("PrepareSurvivorQuery", Native_PrepareSurvivorQuery);
    CreateNative("PrepareInfectedQuery", Native_PrepareInfectedQuery);
    CreateNative("PrepareProgressQuery", Native_PrepareProgressQuery);
    CreateNative("ExecuteRoundQuery", Native_ExecuteRoundQuery);
    CreateNative("ExecuteSurvivorQuery", Native_ExecuteSurvivorQuery);
    CreateNative("ExecuteInfectedQuery", Native_ExecuteInfectedQuery);
    CreateNative("ExecuteProgressQuery", Native_ExecuteProgressQuery);
}

new     Handle: g_hCvarDebug            = INVALID_HANDLE;
new String:errorBuffer[255];
new Handle:db;
new Handle:hRoundStmt;
new Handle:hSurvivorStmt;
new Handle:hInfectedStmt;
new Handle:hProgressStmt;

public OnPluginStart()
{
    g_hCvarDebug = CreateConVar(
            "sm_stats_database_debug",
            "0",
            "Debug mode",
            FCVAR_PLUGIN, true, 0.0, false
        );
        
    db = SQL_DefConnect(errorBuffer, sizeof(errorBuffer));
    if (db == INVALID_HANDLE)
    {
        PrintToServer("Could not connect: %s", errorBuffer);
    }
    else {
        SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS `round` ( \
        `id` INT NOT NULL auto_increment, \
        `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, \
        `round` INT, \
        `team` INT, \
        `map` varchar(64), \
        `deleted` BOOLEAN, \
        `isSecondHalf` BOOLEAN, \
        `teamIsA` BOOLEAN, \
        `teamARound` INT, \
        `teamATotal` INT, \
        `teamBRound` INT, \
        `teamBTotal` INT, \
        `survivorCount` INT, \
        `maxCompletionScore` INT, \
        `maxFlowDist` INT, \
        `rndRestarts` INT, \
        `rndPillsUsed` INT, \
        `rndKitsUsed` INT, \
        `rndDefibsUsed` INT, \
        `rndCommon` INT, \
        `rndSIKilled` INT, \
        `rndSIDamage` INT, \
        `rndSISpawned` INT, \
        `rndWitchKilled` INT, \
        `rndTankKilled` INT, \
        `rndIncaps` INT, \
        `rndDeaths` INT, \
        `rndFFDamageTotal` INT, \
        `rndStartTime` INT, \
        `rndEndTime` INT, \
        `rndStartTimePause` INT, \
        `rndStopTimePause` INT, \
        `rndStartTimeTank` INT, \
        `rndStopTimeTank` INT, \
        PRIMARY KEY  (`id`) \
        );");
        
        SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS `survivor` ( \
        `id` INT NOT NULL auto_increment, \
        `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, \
        `round` INT, \
        `team` INT, \
        `map` varchar(64), \
        `steamid` varchar(32), \
        `deleted` BOOLEAN, \
        `isSecondHalf` BOOLEAN, \
        `plyShotsShotgun` INT, \
        `plyShotsSmg` INT, \
        `plyShotsSniper` INT, \
        `plyShotsPistol` INT, \
        `plyHitsShotgun` INT, \
        `plyHitsSmg` INT, \
        `plyHitsSniper` INT, \
        `plyHitsPistol` INT, \
        `plyHeadshotsSmg` INT, \
        `plyHeadshotsSniper` INT, \
        `plyHeadshotsPistol` INT, \
        `plyHeadshotsSISmg` INT, \
        `plyHeadshotsSISniper` INT, \
        `plyHeadshotsSIPistol` INT, \
        `plyHitsSIShotgun` INT, \
        `plyHitsSISmg` INT, \
        `plyHitsSISniper` INT, \
        `plyHitsSIPistol` INT, \
        `plyHitsTankShotgun` INT, \
        `plyHitsTankSmg` INT, \
        `plyHitsTankSniper` INT, \
        `plyHitsTankPistol` INT, \
        `plyCommon` INT, \
        `plyCommonTankUp` INT, \
        `plySIKilled` INT, \
        `plySIKilledTankUp` INT, \
        `plySIDamage` INT, \
        `plySIDamageTankUp` INT, \
        `plyIncaps` INT, \
        `plyDied` INT, \
        `plySkeets` INT, \
        `plySkeetsHurt` INT, \
        `plySkeetsMelee` INT, \
        `plyLevels` INT, \
        `plyLevelsHurt` INT, \
        `plyPops` INT, \
        `plyCrowns` INT, \
        `plyCrownsHurt` INT, \
        `plyShoves` INT, \
        `plyDeadStops` INT, \
        `plyTongueCuts` INT, \
        `plySelfClears` INT, \
        `plyFallDamage` INT, \
        `plyDmgTaken` INT, \
        `plyDmgTakenBoom` INT, \
        `plyDmgTakenCommon` INT, \
        `plyDmgTakenTank` INT, \
        `plyBowls` INT, \
        `plyCharges` INT, \
        `plyDeathCharges` INT, \
        `plyFFGiven` INT, \
        `plyFFTaken` INT, \
        `plyFFHits` INT, \
        `plyTankDamage` INT, \
        `plyWitchDamage` INT, \
        `plyMeleesOnTank` INT, \
        `plyRockSkeets` INT, \
        `plyRockEats` INT, \
        `plyFFGivenPellet` INT, \
        `plyFFGivenBullet` INT, \
        `plyFFGivenSniper` INT, \
        `plyFFGivenMelee` INT, \
        `plyFFGivenFire` INT, \
        `plyFFGivenIncap` INT, \
        `plyFFGivenOther` INT, \
        `plyFFGivenSelf` INT, \
        `plyFFTakenPellet` INT, \
        `plyFFTakenBullet` INT, \
        `plyFFTakenSniper` INT, \
        `plyFFTakenMelee` INT, \
        `plyFFTakenFire` INT, \
        `plyFFTakenIncap` INT, \
        `plyFFTakenOther` INT, \
        `plyFFGivenTotal` INT, \
        `plyFFTakenTotal` INT, \
        `plyCarsTriggered` INT, \
        `plyJockeyRideDuration` INT, \
        `plyJockeyRideTotal` INT, \
        `plyClears` INT, \
        `plyAvgClearTime` INT, \
        `plyTimeStartPresent` INT, \
        `plyTimeStopPresent` INT, \
        `plyTimeStartAlive` INT, \
        `plyTimeStopAlive` INT, \
        `plyTimeStartUpright` INT, \
        `plyTimeStopUpright` INT, \
        PRIMARY KEY  (`id`) \
        );");
        
        SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS `infected` ( \
        `id` INT NOT NULL auto_increment, \
        `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, \
        `round` INT, \
        `team` INT, \
        `map` varchar(64), \
        `steamid` varchar(32), \
        `deleted` BOOLEAN, \
        `isSecondHalf` BOOLEAN, \
        `infDmgTotal` INT, \
        `infDmgUpright` INT, \
        `infDmgTank` INT, \
        `infDmgTankIncap` INT, \
        `infDmgScratch` INT, \
        `infDmgSpit` INT, \
        `infDmgBoom` INT, \
        `infDmgTankUp` INT, \
        `infHunterDPs` INT, \
        `infHunterDPDmg` INT, \
        `infJockeyDPs` INT, \
        `infDeathCharges` INT, \
        `infCharges` INT, \
        `infMultiCharges` INT, \
        `infBoomsSingle` INT, \
        `infBoomsDouble` INT, \
        `infBoomsTriple` INT, \
        `infBoomsQuad` INT, \
        `infBooms` INT, \
        `infBoomerPops` INT, \
        `infLedged` INT, \
        `infCommon` INT, \
        `infSpawns` INT, \
        `infSpawnSmoker` INT, \
        `infSpawnBoomer` INT, \
        `infSpawnHunter` INT, \
        `infSpawnCharger` INT, \
        `infSpawnSpitter` INT, \
        `infSpawnJockey` INT, \
        `infTankPasses` INT, \
        `infTankRockHits` INT, \
        `infCarsTriggered` INT, \
        `infJockeyRideDuration` INT, \
        `infJockeyRideTotal` INT, \
        `infTimeStartPresent` INT, \
        `infTimeStopPresent` INT, \
        PRIMARY KEY  (`id`) \
        );");
        
        SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS `progress` ( \
        `id` INT NOT NULL auto_increment, \
        `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, \
        `round` INT, \
        `team` INT, \
        `map` varchar(64), \
        `steamid` varchar(32), \
        `deleted` BOOLEAN, \
        `isSecondHalf` BOOLEAN, \
        `curFlowDist` INT, \
        `farFlowDist` INT, \
        PRIMARY KEY  (`id`) \
        );");
    }
}

public int Native_IsDatabaseConnected(Handle:plugin, numParams)
{
    return db != INVALID_HANDLE;
}

public int Native_PrepareRoundQuery(Handle:plugin, numParams)
{
    return InternalPrepareRoundQuery();
}

public int Native_PrepareSurvivorQuery(Handle:plugin, numParams)
{
    return InternalPrepareSurvivorQuery();
}

public int Native_PrepareInfectedQuery(Handle:plugin, numParams)
{
    return InternalPrepareInfectedQuery();
}


public int Native_PrepareProgressQuery(Handle:plugin, numParams)
{
    return InternalPrepareProgressQuery();
}

public int Native_ExecuteRoundQuery(Handle:plugin, numParams)
{
    new len;

    GetNativeStringLength(1, len);
    new String:sTime[len+1];
    GetNativeString(1, sTime, len+1);
    
    int iRound = GetNativeCell(2);
    int iTeam = GetNativeCell(3);

    GetNativeStringLength(4, len);
    new String:sMap[len+1];
    GetNativeString(4, sMap, len+1);
    
    bool bDeleted = GetNativeCell(5);
    bool bSecondHalf = GetNativeCell(6);
    bool bTeamIsA = GetNativeCell(7);
    int iTeamARound = GetNativeCell(8);
    int iTeamATotal = GetNativeCell(9);
    int iTeamBRound = GetNativeCell(10);
    int iTeamBTotal = GetNativeCell(11);
    int iSurvivorCount = GetNativeCell(12);
    int iMaxCompletionScore = GetNativeCell(13);
    int iMaxFlowDist = GetNativeCell(14);
    
    int size = GetNativeCell(16);
    if (size < 1) { return false; }

    int[] rndData = new int[size];
    GetNativeArray(15, rndData, size);
    
    SQL_BindParamString(hRoundStmt, 0, sTime, false);
    SQL_BindParamInt(hRoundStmt, 1, iRound, false);
    SQL_BindParamInt(hRoundStmt, 2, iTeam, false);
    SQL_BindParamString(hRoundStmt, 3, sMap, false);
    SQL_BindParamInt(hRoundStmt, 4, bDeleted, false);
    SQL_BindParamInt(hRoundStmt, 5, bSecondHalf, false);
    SQL_BindParamInt(hRoundStmt, 6, bTeamIsA, false);
    SQL_BindParamInt(hRoundStmt, 7, iTeamARound, false);
    SQL_BindParamInt(hRoundStmt, 8, iTeamATotal, false);
    SQL_BindParamInt(hRoundStmt, 9, iTeamBRound, false);
    SQL_BindParamInt(hRoundStmt, 10, iTeamBTotal, false);
    SQL_BindParamInt(hRoundStmt, 11, iSurvivorCount, false);
    SQL_BindParamInt(hRoundStmt, 12, iMaxCompletionScore, false);
    SQL_BindParamInt(hRoundStmt, 13, iMaxFlowDist, false);

    for (new i = 0; i <= MAXRNDSTATS; i++ )
    {
        SQL_BindParamInt(hRoundStmt, i+14, rndData[i], false);
    }
    if (!SQL_Execute(hRoundStmt))
    {
        PrintToChatAll("[Stats] Failed to save round stats.");
        return false;
    }
    else
    {
        PrintDebug( 1, "[Stats] Saved round stats.");
    }
    
    return true;
}

public int Native_ExecuteSurvivorQuery(Handle:plugin, numParams)
{
    new len;

    GetNativeStringLength(1, len);
    new String:sTime[len+1];
    GetNativeString(1, sTime, len+1);
    
    int iRound = GetNativeCell(2);
    int iTeam = GetNativeCell(3);

    GetNativeStringLength(4, len);
    new String:sMap[len+1];
    GetNativeString(4, sMap, len+1);

    GetNativeStringLength(5, len);
    new String:sSteamId[len+1];
    GetNativeString(5, sSteamId, len+1);
    
    bool bDeleted = GetNativeCell(6);
    bool bSecondHalf = GetNativeCell(7);
    
    int size = GetNativeCell(9);
    if (size < 1) { return false; }

    int[] rndData = new int[size];
    GetNativeArray(8, rndData, size);
    
    SQL_BindParamString(hSurvivorStmt, 0, sTime, false);
    SQL_BindParamInt(hSurvivorStmt, 1, iRound, false);
    SQL_BindParamInt(hSurvivorStmt, 2, iTeam, false);
    SQL_BindParamString(hSurvivorStmt, 3, sMap, false);
    SQL_BindParamString(hSurvivorStmt, 4, sSteamId, false);
    SQL_BindParamInt(hSurvivorStmt, 5, bDeleted, false);
    SQL_BindParamInt(hSurvivorStmt, 6, bSecondHalf, false);

    for (new i = 0; i <= MAXPLYSTATS; i++ )
    {
        SQL_BindParamInt(hSurvivorStmt, i+7, rndData[i], false);
    }
    if (!SQL_Execute(hSurvivorStmt))
    {
        PrintToChatAll("[Stats] Failed to save survivor stats for %s.", sSteamId);
        return false;
    }
    else
    {
        PrintDebug( 1, "[Stats] Saved survivor stats for %s.", sSteamId );
    }
    
    return true;
}

public int Native_ExecuteInfectedQuery(Handle:plugin, numParams)
{
    new len;

    GetNativeStringLength(1, len);
    new String:sTime[len+1];
    GetNativeString(1, sTime, len+1);
    
    int iRound = GetNativeCell(2);
    int iTeam = GetNativeCell(3);

    GetNativeStringLength(4, len);
    new String:sMap[len+1];
    GetNativeString(4, sMap, len+1);

    GetNativeStringLength(5, len);
    new String:sSteamId[len+1];
    GetNativeString(5, sSteamId, len+1);
    
    bool bDeleted = GetNativeCell(6);
    bool bSecondHalf = GetNativeCell(7);
    
    int size = GetNativeCell(9);
    if (size < 1) { return false; }

    int[] rndData = new int[size];
    GetNativeArray(8, rndData, size);
    
    SQL_BindParamString(hInfectedStmt, 0, sTime, false);
    SQL_BindParamInt(hInfectedStmt, 1, iRound, false);
    SQL_BindParamInt(hInfectedStmt, 2, iTeam, false);
    SQL_BindParamString(hInfectedStmt, 3, sMap, false);
    SQL_BindParamString(hInfectedStmt, 4, sSteamId, false);
    SQL_BindParamInt(hInfectedStmt, 5, bDeleted, false);
    SQL_BindParamInt(hInfectedStmt, 6, bSecondHalf, false);

    for (new i = 0; i <= MAXINFSTATS; i++ )
    {
        SQL_BindParamInt(hInfectedStmt, i+7, rndData[i], false);
    }
    if (!SQL_Execute(hInfectedStmt))
    {
        PrintToChatAll("[Stats] Failed to save infected stats for %s.", sSteamId);
        return false;
    }
    else
    {
        PrintDebug( 1, "[Stats] Saved infected stats for %s.", sSteamId );
    }
    
    return true;
}


public int Native_ExecuteProgressQuery(Handle:plugin, numParams)
{
    new len;

    GetNativeStringLength(1, len);
    new String:sTime[len+1];
    GetNativeString(1, sTime, len+1);
    
    int iRound = GetNativeCell(2);
    int iTeam = GetNativeCell(3);

    GetNativeStringLength(4, len);
    new String:sMap[len+1];
    GetNativeString(4, sMap, len+1);

    GetNativeStringLength(5, len);
    new String:sSteamId[len+1];
    GetNativeString(5, sSteamId, len+1);
    
    bool bDeleted = GetNativeCell(6);
    bool bSecondHalf = GetNativeCell(7);
    int iCurFlowDist = GetNativeCell(8);
    int iFarFlowDist = GetNativeCell(9);

    SQL_BindParamString(hProgressStmt, 0, sTime, false);
    SQL_BindParamInt(hProgressStmt, 1, iRound, false);
    SQL_BindParamInt(hProgressStmt, 2, iTeam, false);
    SQL_BindParamString(hProgressStmt, 3, sMap, false);
    SQL_BindParamString(hProgressStmt, 4, sSteamId, false);
    SQL_BindParamInt(hProgressStmt, 5, bDeleted, false);
    SQL_BindParamInt(hProgressStmt, 6, bSecondHalf, false);
    SQL_BindParamInt(hProgressStmt, 7, iCurFlowDist, false);
    SQL_BindParamInt(hProgressStmt, 8, iFarFlowDist, false);

    if (!SQL_Execute(hProgressStmt))
    {
        PrintToChatAll("[Stats] Failed to save progress stats.");
        return false;
    }
    else
    {
        PrintDebug( 1, "[Stats] Saved progress stats.");
    }
    
    return true;
}

bool:InternalPrepareRoundQuery()
{
    if ( hRoundStmt == INVALID_HANDLE ) {
        hRoundStmt = SQL_PrepareQuery(db, "INSERT INTO round ( \
        id, \
        createdAt, \
        round, \
        team, \
        map, \
        deleted, \
        isSecondHalf, \
        teamIsA`, \
        teamARound, \
        teamATotal, \
        teamBRound, \
        teamBTotal, \
        survivorCount, \
        maxCompletionScore, \
        maxFlowDist, \
        rndRestarts, \
        rndPillsUsed, \
        rndKitsUsed, \
        rndDefibsUsed, \
        rndCommon, \
        rndSIKilled, \
        rndSIDamage, \
        rndSISpawned, \
        rndWitchKilled, \
        rndTankKilled, \
        rndIncaps, \
        rndDeaths, \
        rndFFDamageTotal, \
        rndStartTime, \
        rndEndTime, \
        rndStartTimePause, \
        rndStopTimePause, \
        rndStartTimeTank, \
        rndStopTimeTank \
        ) VALUES ( NULL, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,? \
        )", errorBuffer, sizeof(errorBuffer));

        if ( hRoundStmt == INVALID_HANDLE )
        {
            PrintDebug( 1, "[Stats] Prepare round query failed. %s", errorBuffer );
            return false;
        }
    }
    return true;
}

bool:InternalPrepareSurvivorQuery()
{
    if ( hSurvivorStmt == INVALID_HANDLE ) {
        hSurvivorStmt = SQL_PrepareQuery(db, "INSERT INTO survivor ( \
        id, \
        createdAt, \
        round, \
        team, \
        map, \
        steamid, \
        deleted, \
        isSecondHalf, \
        plyShotsShotgun, \
        plyShotsSmg, \
        plyShotsSniper, \
        plyShotsPistol, \
        plyHitsShotgun, \
        plyHitsSmg, \
        plyHitsSniper, \
        plyHitsPistol, \
        plyHeadshotsSmg, \
        plyHeadshotsSniper, \
        plyHeadshotsPistol, \
        plyHeadshotsSISmg, \
        plyHeadshotsSISniper, \
        plyHeadshotsSIPistol, \
        plyHitsSIShotgun, \
        plyHitsSISmg, \
        plyHitsSISniper, \
        plyHitsSIPistol, \
        plyHitsTankShotgun, \
        plyHitsTankSmg, \
        plyHitsTankSniper, \
        plyHitsTankPistol, \
        plyCommon, \
        plyCommonTankUp, \
        plySIKilled, \
        plySIKilledTankUp, \
        plySIDamage, \
        plySIDamageTankUp, \
        plyIncaps, \
        plyDied, \
        plySkeets, \
        plySkeetsHurt, \
        plySkeetsMelee, \
        plyLevels, \
        plyLevelsHurt, \
        plyPops, \
        plyCrowns, \
        plyCrownsHurt, \
        plyShoves, \
        plyDeadStops, \
        plyTongueCuts, \
        plySelfClears, \
        plyFallDamage, \
        plyDmgTaken, \
        plyDmgTakenBoom, \
        plyDmgTakenCommon, \
        plyDmgTakenTank, \
        plyBowls, \
        plyCharges, \
        plyDeathCharges, \
        plyFFGiven, \
        plyFFTaken, \
        plyFFHits, \
        plyTankDamage, \
        plyWitchDamage, \
        plyMeleesOnTank, \
        plyRockSkeets, \
        plyRockEats, \
        plyFFGivenPellet, \
        plyFFGivenBullet, \
        plyFFGivenSniper, \
        plyFFGivenMelee, \
        plyFFGivenFire, \
        plyFFGivenIncap, \
        plyFFGivenOther, \
        plyFFGivenSelf, \
        plyFFTakenPellet, \
        plyFFTakenBullet, \
        plyFFTakenSniper, \
        plyFFTakenMelee, \
        plyFFTakenFire, \
        plyFFTakenIncap, \
        plyFFTakenOther, \
        plyFFGivenTotal, \
        plyFFTakenTotal, \
        plyCarsTriggered, \
        plyJockeyRideDuration, \
        plyJockeyRideTotal, \
        plyClears, \
        plyAvgClearTime, \
        plyTimeStartPresent, \
        plyTimeStopPresent, \
        plyTimeStartAlive, \
        plyTimeStopAlive, \
        plyTimeStartUpright, \
        plyTimeStopUpright \
        ) VALUES ( NULL, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,? \
        )", errorBuffer, sizeof(errorBuffer));

        if ( hSurvivorStmt == INVALID_HANDLE )
        {
            PrintDebug( 1, "[Stats] Prepare survivor query failed. %s", errorBuffer );
            return false;
        }
    }
    return true;
}

bool:InternalPrepareInfectedQuery()
{
    if ( hInfectedStmt == INVALID_HANDLE ) {
        hInfectedStmt = SQL_PrepareQuery(db, "INSERT INTO infected ( \
        id, \
        createdAt, \
        round, \
        team, \
        map, \
        steamid, \
        deleted, \
        isSecondHalf, \
        infDmgTotal, \
        infDmgUpright, \
        infDmgTank, \
        infDmgTankIncap, \
        infDmgScratch, \
        infDmgSpit, \
        infDmgBoom, \
        infDmgTankUp, \
        infHunterDPs, \
        infHunterDPDmg, \
        infJockeyDPs, \
        infDeathCharges, \
        infCharges, \
        infMultiCharges, \
        infBoomsSingle, \
        infBoomsDouble, \
        infBoomsTriple, \
        infBoomsQuad, \
        infBooms, \
        infBoomerPops, \
        infLedged, \
        infCommon, \
        infSpawns, \
        infSpawnSmoker, \
        infSpawnBoomer, \
        infSpawnHunter, \
        infSpawnCharger, \
        infSpawnSpitter, \
        infSpawnJockey, \
        infTankPasses, \
        infTankRockHits, \
        infCarsTriggered, \
        infJockeyRideDuration, \
        infJockeyRideTotal, \
        infTimeStartPresent, \
        infTimeStopPresent \
        ) VALUES ( NULL, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,?,?,?,?,?,?,?,?, \
            ?,?,? \
        )", errorBuffer, sizeof(errorBuffer));

        if ( hInfectedStmt == INVALID_HANDLE )
        {
            PrintDebug( 1, "[Stats] Prepare infected query failed. %s", errorBuffer );
            return false;
        }
    }
    return true;
}

bool:InternalPrepareProgressQuery()
{
    if ( hProgressStmt == INVALID_HANDLE ) {
        hProgressStmt = SQL_PrepareQuery(db, "INSERT INTO progress ( \
        id, \
        createdAt, \
        round, \
        team, \
        map, \
        steamid, \
        deleted, \
        isSecondHalf, \
        curFlowDist, \
        farFlowDist \
        ) VALUES ( NULL, \
            ?,?,?,?,?,?,?,? \
        )", errorBuffer, sizeof(errorBuffer));

        if ( hProgressStmt == INVALID_HANDLE )
        {
            PrintDebug( 1, "[Stats] Prepare progress query failed. %s", errorBuffer );
            return false;
        }
    }
    return true;
}

stock PrintDebug( debugLevel, const String:Message[], any:... )
{
    if (debugLevel <= GetConVarInt(g_hCvarDebug))
    {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 3);
        LogMessage(DebugBuff);
        //PrintToServer(DebugBuff);
    }
}