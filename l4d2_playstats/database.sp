#if defined _l4d2_playstats_database_included
 #endinput
#endif

#define _l4d2_playstats_database_included

#include <sourcemod>

InitDatabase() {
    db = SQL_DefConnect(errorBuffer, sizeof(errorBuffer));
    if (db == INVALID_HANDLE) {
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

// write round stats to database
stock WriteStatsToDB( iTeam, bool:bSecondHalf ) {
    if ( g_bModeCampaign ) { return; }

    if (db == INVALID_HANDLE) {
        PrintToServer("[Stats] DB is null");
        PrintDebug( 1, "[Stats] DB is null" );
        return;
    }
    PrintToServer("[Stats] Saving to database");
    PrintDebug( 1, "[Stats] Saving to database" );

    decl String: sTmpMap[64];
    GetCurrentMap( sTmpMap, sizeof(sTmpMap) );
    decl String: sTmpTime[20];
    FormatTime( sTmpTime, sizeof(sTmpTime), "%Y-%m-%d %H:%M:%S" );
    
    // round data
    new i;
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

        if ( hRoundStmt == INVALID_HANDLE ) {
            PrintDebug( 1, "[Stats] Prepare round query failed. %s", errorBuffer );
            return;
        }
    }

    SQL_BindParamString(hRoundStmt, 0, sTmpTime, false);
    SQL_BindParamInt(hRoundStmt, 1, g_iRound, false);
    SQL_BindParamInt(hRoundStmt, 2, iTeam, false);
    SQL_BindParamString(hRoundStmt, 3, sTmpMap, false);
    SQL_BindParamInt(hRoundStmt, 4, 0, false);
    SQL_BindParamInt(hRoundStmt, 5, g_bSecondHalf, false);
    SQL_BindParamInt(hRoundStmt, 6, iTeam == LTEAM_A, false);
    SQL_BindParamInt(hRoundStmt, 7, g_iScores[LTEAM_A] - g_iFirstScoresSet[((g_bCMTSwapped)?1:0)], false);
    SQL_BindParamInt(hRoundStmt, 8, g_iScores[LTEAM_A], false);
    SQL_BindParamInt(hRoundStmt, 9, g_iScores[LTEAM_B] - g_iFirstScoresSet[((g_bCMTSwapped)?0:1)], false);
    SQL_BindParamInt(hRoundStmt, 10, g_iScores[LTEAM_B], false);
    SQL_BindParamInt(hRoundStmt, 11, g_iSurvived[iTeam], false);
    SQL_BindParamInt(hRoundStmt, 12, L4D_GetVersusMaxCompletionScore(), false);
    SQL_BindParamInt(hRoundStmt, 13, RoundFloat(L4D2Direct_GetMapMaxFlowDistance()), false);

    for ( i = 0; i <= MAXRNDSTATS; i++ ) {
        SQL_BindParamInt(hRoundStmt, i+14, g_strRoundData[g_iRound][iTeam][i], false);
    }
    if (!SQL_Execute(hRoundStmt)) {
        PrintToChatAll("[Stats] Failed to save round stats.");
    }
    else {
        PrintDebug( 1, "[Stats] Saved round stats.");
    }
    
    // player data
    new j;
    new iPlayerCount = 0;
    for ( j = FIRST_NON_BOT; j < g_iPlayers; j++ ) {
        if ( g_iPlayerRoundTeam[iTeam][j] != iTeam ) { continue; }
        iPlayerCount++;

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

            if ( hSurvivorStmt == INVALID_HANDLE ) {
                PrintDebug( 1, "[Stats] Prepare survivor query failed. %s", errorBuffer );
                continue;
            }
        }

        SQL_BindParamString(hSurvivorStmt, 0, sTmpTime, false);
        SQL_BindParamInt(hSurvivorStmt, 1, g_iRound, false);
        SQL_BindParamInt(hSurvivorStmt, 2, iTeam, false);
        SQL_BindParamString(hSurvivorStmt, 3, sTmpMap, false);
        SQL_BindParamString(hSurvivorStmt, 4, g_sPlayerId[j], false);
        SQL_BindParamInt(hSurvivorStmt, 5, 0, false);
        SQL_BindParamInt(hSurvivorStmt, 6, g_bSecondHalf, false);

        for ( i = 0; i <= MAXPLYSTATS; i++ ) {
            SQL_BindParamInt(hSurvivorStmt, i+7, g_strRoundPlayerData[j][iTeam][i], false);
        }
        if (!SQL_Execute(hSurvivorStmt)) {
            PrintToChatAll("[Stats] Failed to save survivor stats for %s.", g_sPlayerId[j]);
        }
        else {
            PrintDebug( 1, "[Stats] Saved survivor stats for %s.", g_sPlayerId[j] );
        }
    }

    // infected player data
    iPlayerCount = 0;
    for ( j = FIRST_NON_BOT; j < g_iPlayers; j++ ) {
        // opposite team!
        if ( g_iPlayerRoundTeam[iTeam][j] != (iTeam) ? 0 : 1 ) { continue; }

        // leave out players that were actually specs...
        if (    g_strRoundPlayerInfData[j][iTeam][infTimeStartPresent] == 0 && g_strRoundPlayerInfData[j][iTeam][infTimeStopPresent] == 0 ||
                g_strRoundPlayerInfData[j][iTeam][infSpawns] == 0 && g_strRoundPlayerInfData[j][iTeam][infTankPasses] == 0
        ) {
            continue;
        }
        iPlayerCount++;

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

            if ( hInfectedStmt == INVALID_HANDLE ) {
                PrintDebug( 1, "[Stats] Prepare infected query failed. %s", errorBuffer );
                continue;
            }
        }

        SQL_BindParamString(hInfectedStmt, 0, sTmpTime, false);
        SQL_BindParamInt(hInfectedStmt, 1, g_iRound, false);
        SQL_BindParamInt(hInfectedStmt, 2, iTeam, false);
        SQL_BindParamString(hInfectedStmt, 3, sTmpMap, false);
        SQL_BindParamString(hInfectedStmt, 4, g_sPlayerId[j], false);
        SQL_BindParamInt(hInfectedStmt, 5, 0, false);
        SQL_BindParamInt(hInfectedStmt, 6, g_bSecondHalf, false);

        
        for ( i = 0; i <= MAXINFSTATS; i++ ) {
            SQL_BindParamInt(hInfectedStmt, i+7, g_strRoundPlayerInfData[j][iTeam][i], false);
        }
        if (!SQL_Execute(hInfectedStmt)) {
            PrintToChatAll("[Stats] Failed to save infected stats for %s.", g_sPlayerId[j]);
        }
        else {
            PrintDebug( 1, "[Stats] Saved infected stats for %s.", g_sPlayerId[j] );
        }
    }
    
    // progress data
    new Float: curFlowDist[MAXPLAYERS+1];
    new Float: farFlowDist[MAXPLAYERS+1];
    new clients = 0;
    for ( i = 1; i <= MaxClients; i++ ) {
        if ( !IS_VALID_SURVIVOR(i) ) { continue; }
        
        if ( clients < 4 ) {
            // GetEntPropFloat( i, Prop_Data, "m_farthestSurvivorFlowAtDeath" );     // this doesn't work/exist
            // instead, we're tracking it per character 0-3
            farFlowDist[clients] = g_fHighestFlow[clients];
        }
        curFlowDist[clients] = L4D2Direct_GetFlowDistance( i );
        clients++;
    }
    
    for ( i = 0; i < clients; i++ ) {
        j = GetPlayerIndexForClient( i );
        if ( j == -1 ) { continue; }
            
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

            if ( hProgressStmt == INVALID_HANDLE ) {
                PrintDebug( 1, "[Stats] Prepare progress query failed. %s", errorBuffer );
                continue;
            }
        }

        SQL_BindParamString(hProgressStmt, 0, sTmpTime, false);
        SQL_BindParamInt(hProgressStmt, 1, g_iRound, false);
        SQL_BindParamInt(hProgressStmt, 2, iTeam, false);
        SQL_BindParamString(hProgressStmt, 3, sTmpMap, false);
        SQL_BindParamString(hProgressStmt, 4, g_sPlayerId[j], false);
        SQL_BindParamInt(hProgressStmt, 5, 0, false);
        SQL_BindParamInt(hProgressStmt, 6, g_bSecondHalf, false);
        SQL_BindParamInt(hProgressStmt, 7, RoundFloat(curFlowDist[i]), false);
        SQL_BindParamInt(hProgressStmt, 8, RoundFloat((i < 4) ? farFlowDist[i] : 0.0), false);

        if (!SQL_Execute(hProgressStmt)) {
            PrintToChatAll("[Stats] Failed to save progress stats.");
        }
        else {
            PrintDebug( 1, "[Stats] Saved progress stats.");
        }
    }
}