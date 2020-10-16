#if defined _l4d2_playstats_database_included
 #endinput
#endif

#define _l4d2_playstats_database_included

#include <sourcemod>

InitDatabase() {
    GetConVarString(g_hCvarDatabaseConfig, g_sDatabaseConfig, sizeof(g_sDatabaseConfig));
    if (g_Database != null) {
        delete g_Database;
    }
    Database.Connect(T_Connect, g_sDatabaseConfig);
    PrintDebug( 1, "[InitDatabase] g_sDatabaseConfig: %s", g_sDatabaseConfig );
}

public void T_Connect(Database db, const char[] error, any data) {
    if (db == null) {
        PrintToServer("Could not connect: %s", errorBuffer);
    }
    g_Database = db;
    g_Database.Query(OnSQLCreateTableCallback, "CREATE TABLE IF NOT EXISTS `round` ( `id` INT NOT NULL auto_increment, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, `matchId` INT, `round` INT, `team` INT, `map` varchar(64), `deleted` BOOLEAN, `isSecondHalf` BOOLEAN, `teamIsA` BOOLEAN, `teamARound` INT, `teamATotal` INT, `teamBRound` INT, `teamBTotal` INT, `survivorCount` INT, `maxCompletionScore` INT, `maxFlowDist` INT, `rndRestarts` INT, `rndPillsUsed` INT, `rndKitsUsed` INT, `rndDefibsUsed` INT, `rndCommon` INT, `rndSIKilled` INT, `rndSIDamage` INT, `rndSISpawned` INT, `rndWitchKilled` INT, `rndTankKilled` INT, `rndIncaps` INT, `rndDeaths` INT, `rndFFDamageTotal` INT, `rndStartTime` INT, `rndEndTime` INT, `rndStartTimePause` INT, `rndStopTimePause` INT, `rndStartTimeTank` INT, `rndStopTimeTank` INT, `configName` varchar(64), PRIMARY KEY  (`id`) );");
    g_Database.Query(OnSQLCreateTableCallback, "CREATE TABLE IF NOT EXISTS `survivor` ( `id` INT NOT NULL auto_increment, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, `matchId` INT, `round` INT, `team` INT, `map` varchar(64), `steamid` varchar(32), `deleted` BOOLEAN, `isSecondHalf` BOOLEAN, `plyShotsShotgun` INT, `plyShotsSmg` INT, `plyShotsSniper` INT, `plyShotsPistol` INT, `plyHitsShotgun` INT, `plyHitsSmg` INT, `plyHitsSniper` INT, `plyHitsPistol` INT, `plyHeadshotsSmg` INT, `plyHeadshotsSniper` INT, `plyHeadshotsPistol` INT, `plyHeadshotsSISmg` INT, `plyHeadshotsSISniper` INT, `plyHeadshotsSIPistol` INT, `plyHitsSIShotgun` INT, `plyHitsSISmg` INT, `plyHitsSISniper` INT, `plyHitsSIPistol` INT, `plyHitsTankShotgun` INT, `plyHitsTankSmg` INT, `plyHitsTankSniper` INT, `plyHitsTankPistol` INT, `plyCommon` INT, `plyCommonTankUp` INT, `plySIKilled` INT, `plySIKilledTankUp` INT, `plySIDamage` INT, `plySIDamageTankUp` INT, `plyIncaps` INT, `plyDied` INT, `plySkeets` INT, `plySkeetsHurt` INT, `plySkeetsMelee` INT, `plyLevels` INT, `plyLevelsHurt` INT, `plyPops` INT, `plyCrowns` INT, `plyCrownsHurt` INT, `plyShoves` INT, `plyDeadStops` INT, `plyTongueCuts` INT, `plySelfClears` INT, `plyFallDamage` INT, `plyDmgTaken` INT, `plyDmgTakenBoom` INT, `plyDmgTakenCommon` INT, `plyDmgTakenTank` INT, `plyBowls` INT, `plyCharges` INT, `plyDeathCharges` INT, `plyFFGiven` INT, `plyFFTaken` INT, `plyFFHits` INT, `plyTankDamage` INT, `plyWitchDamage` INT, `plyMeleesOnTank` INT, `plyRockSkeets` INT, `plyRockEats` INT, `plyFFGivenPellet` INT, `plyFFGivenBullet` INT, `plyFFGivenSniper` INT, `plyFFGivenMelee` INT, `plyFFGivenFire` INT, `plyFFGivenIncap` INT, `plyFFGivenOther` INT, `plyFFGivenSelf` INT, `plyFFTakenPellet` INT, `plyFFTakenBullet` INT, `plyFFTakenSniper` INT, `plyFFTakenMelee` INT, `plyFFTakenFire` INT, `plyFFTakenIncap` INT, `plyFFTakenOther` INT, `plyFFGivenTotal` INT, `plyFFTakenTotal` INT, `plyCarsTriggered` INT, `plyJockeyRideDuration` INT, `plyJockeyRideTotal` INT, `plyClears` INT, `plyAvgClearTime` INT, `plyTimeStartPresent` INT, `plyTimeStopPresent` INT, `plyTimeStartAlive` INT, `plyTimeStopAlive` INT, `plyTimeStartUpright` INT, `plyTimeStopUpright` INT, `plyCurFlowDist` INT, `plyFarFlowDist` INT, `plyProtectAwards` INT, `plyHeadshotsCISmg` INT, `plyHeadshotsCIPistol` INT, `plyHitsCISmg` INT, `plyHitsCIPistol` INT, `plyHeadshotsPctSISmg` NUMERIC(10, 5), `plyHeadshotsPctSIPistol` NUMERIC(10, 5), `plyHeadshotsPctCISmg` NUMERIC(10, 5), `plyHeadshotsPctCIPistol` NUMERIC(10, 5), `plyDmgTakenSI` INT, PRIMARY KEY  (`id`) );");
    g_Database.Query(OnSQLCreateTableCallback, "CREATE TABLE IF NOT EXISTS `infected` ( `id` INT NOT NULL auto_increment, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, `matchId` INT, `round` INT, `team` INT, `map` varchar(64), `steamid` varchar(32), `deleted` BOOLEAN, `isSecondHalf` BOOLEAN, `infDmgTotal` INT, `infDmgUpright` INT, `infDmgTank` INT, `infDmgTankIncap` INT, `infDmgScratch` INT, `infDmgScratchSmoker` INT, `infDmgScratchBoomer` INT, `infDmgScratchHunter` INT, `infDmgScratchCharger` INT, `infDmgScratchSpitter` INT, `infDmgScratchJockey` INT, `infDmgSpit` INT, `infDmgBoom` INT, `infDmgTankUp` INT, `infHunterDPs` INT, `infHunterDPDmg` INT, `infJockeyDPs` INT, `infDeathCharges` INT, `infCharges` INT, `infMultiCharges` INT, `infBoomsSingle` INT, `infBoomsDouble` INT, `infBoomsTriple` INT, `infBoomsQuad` INT, `infBooms` INT, `infBoomerPops` INT, `infLedged` INT, `infCommon` INT, `infSpawns` INT, `infSpawnSmoker` INT, `infSpawnBoomer` INT, `infSpawnHunter` INT, `infSpawnCharger` INT, `infSpawnSpitter` INT, `infSpawnJockey` INT, `infTankPasses` INT, `infTankRockHits` INT, `infCarsTriggered` INT, `infJockeyRideDuration` INT, `infJockeyRideTotal` INT, `infTimeStartPresent` INT, `infTimeStopPresent` INT, `infBoomsProxyTotal` INT, `infDmgTotalPerSpawn` NUMERIC(10, 5), `infDmgUprightPerSpawn` NUMERIC(10, 5), `infDmgTankPerSpawn` NUMERIC(10, 5), `infDmgTankIncapPerSpawn` NUMERIC(10, 5), `infDmgScratchPerSpawn` NUMERIC(10, 5), `infDmgScratchSmokerPerSpawn` NUMERIC(10, 5), `infDmgScratchBoomerPerSpawn` NUMERIC(10, 5), `infDmgScratchHunterPerSpawn` NUMERIC(10, 5), `infDmgScratchChargerPerSpawn` NUMERIC(10, 5), `infDmgScratchSpitterPerSpawn` NUMERIC(10, 5), `infDmgScratchJockeyPerSpawn` NUMERIC(10, 5), `infDmgSpitPerSpawn` NUMERIC(10, 5), `infDmgBoomPerSpawn` NUMERIC(10, 5), `infDmgTankUpPerSpawn` NUMERIC(10, 5), `infHunterDPsPerSpawn` NUMERIC(10, 5), `infHunterDPDmgPerSpawn` NUMERIC(10, 5), `infDeathChargesPerSpawn` NUMERIC(10, 5), `infChargesPerSpawn` NUMERIC(10, 5), `infMultiChargesPerSpawn` NUMERIC(10, 5), `infBoomsSinglePerSpawn` NUMERIC(10, 5), `infBoomsDoublePerSpawn` NUMERIC(10, 5), `infBoomsTriplePerSpawn` NUMERIC(10, 5), `infBoomsQuadPerSpawn` NUMERIC(10, 5), `infBoomsPerSpawn` NUMERIC(10, 5), `infBoomsProxyTotalPerSpawn` NUMERIC(10, 5), `infBoomerPopsPerSpawn` NUMERIC(10, 5), `infLedgedPerSpawn` NUMERIC(10, 5), `infTankRockHitsPerSpawn` NUMERIC(10, 5), `infCarsTriggeredPerSpawn` NUMERIC(10, 5), `infJockeyRideDurationPerSpawn` NUMERIC(10, 5), `infJockeyRideTotalPerSpawn` NUMERIC(10, 5), PRIMARY KEY  (`id`) );");
    g_Database.Query(OnSQLCreateTableCallback, "CREATE TABLE IF NOT EXISTS `matchlog` ( `id` INT NOT NULL auto_increment, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, `matchId` INT, `map` varchar(64), `deleted` BOOLEAN, `result` INT, `steamid` varchar(32), `startedAt` INT, `endedAt` INT, `team` INT, `configName` varchar(64), PRIMARY KEY  (`id`) );");
    g_Database.Query(OnSQLCreateTableCallback, "CREATE TABLE IF NOT EXISTS `pvp_ff` ( `id` INT NOT NULL auto_increment, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, `matchId` INT, `round` INT, `team` INT, `map` varchar(64), `steamid` varchar(32), `deleted` BOOLEAN, `isSecondHalf` BOOLEAN, `victim` varchar(32), `damage` INT, PRIMARY KEY  (`id`) );");
    g_Database.Query(OnSQLCreateTableCallback, "CREATE TABLE IF NOT EXISTS `pvp_infdmg` ( `id` INT NOT NULL auto_increment, `createdAt` TIMESTAMP DEFAULT CURRENT_TIMESTAMP, `matchId` INT, `round` INT, `team` INT, `map` varchar(64), `steamid` varchar(32), `deleted` BOOLEAN, `isSecondHalf` BOOLEAN, `victim` varchar(32), `damage` INT, PRIMARY KEY  (`id`) );");
}

public void OnSQLCreateTableCallback(Database db, DBResultSet results, const char[] error, any data) {
    if (results == null)
        LogError("Create table query failure: %s", error);
}

public void OnSQLInsertCallback(Database db, DBResultSet results, const char[] error, any data)
{
    g_iQueries--;
    if (results == null)
        LogError("Insert query failure: %s", error);
}

public void InsertRound(const char[] createdAt, int matchId, int round, int team, const char[] map, bool deleted, bool isSecondHalf, bool teamIsA, int teamARound, int teamATotal, int teamBRound, int teamBTotal, int survivorCount, int maxCompletionScore, int maxFlowDist, const char[] configName, int _rndRestarts, int _rndPillsUsed, int _rndKitsUsed, int _rndDefibsUsed, int _rndCommon, int _rndSIKilled, int _rndSIDamage, int _rndSISpawned, int _rndWitchKilled, int _rndTankKilled, int _rndIncaps, int _rndDeaths, int _rndFFDamageTotal, int _rndStartTime, int _rndEndTime, int _rndStartTimePause, int _rndStopTimePause, int _rndStartTimeTank, int _rndStopTimeTank) {
    g_iQueries++;
    char sQuery[2500];
    g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO round ( id, createdAt, matchId, round, team, map, deleted, isSecondHalf, teamIsA, teamARound, teamATotal, teamBRound, teamBTotal, survivorCount, maxCompletionScore, maxFlowDist, configName, rndRestarts, rndPillsUsed, rndKitsUsed, rndDefibsUsed, rndCommon, rndSIKilled, rndSIDamage, rndSISpawned, rndWitchKilled, rndTankKilled, rndIncaps, rndDeaths, rndFFDamageTotal, rndStartTime, rndEndTime, rndStartTimePause, rndStopTimePause, rndStartTimeTank, rndStopTimeTank ) VALUES ( NULL,'%s',%i,%i,%i,'%s',%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,'%s',%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i)", createdAt, matchId, round, team, map, deleted, isSecondHalf, teamIsA, teamARound, teamATotal, teamBRound, teamBTotal, survivorCount, maxCompletionScore, maxFlowDist, configName, _rndRestarts, _rndPillsUsed, _rndKitsUsed, _rndDefibsUsed, _rndCommon, _rndSIKilled, _rndSIDamage, _rndSISpawned, _rndWitchKilled, _rndTankKilled, _rndIncaps, _rndDeaths, _rndFFDamageTotal, _rndStartTime, _rndEndTime, _rndStartTimePause, _rndStopTimePause, _rndStartTimeTank, _rndStopTimeTank);
    g_Database.Query(OnSQLInsertCallback, sQuery);
}

public void InsertSurvivor(const char[] createdAt, int matchId, int round, int team, const char[] map, const char[] steamid, bool deleted, bool isSecondHalf, int j, int iTeam) {
    g_iQueries++;
    char sQuery[7000];
    int iLen;
    iLen = FormatEx(sQuery, sizeof(sQuery) - 1, "INSERT INTO survivor ( id, createdAt, matchId, round, team, map, steamid, deleted, isSecondHalf, plyShotsShotgun, plyShotsSmg, plyShotsSniper, plyShotsPistol, plyHitsShotgun, plyHitsSmg, plyHitsSniper, plyHitsPistol, plyHeadshotsSmg, plyHeadshotsSniper, plyHeadshotsPistol, plyHeadshotsSISmg, plyHeadshotsSISniper, plyHeadshotsSIPistol, plyHitsSIShotgun, plyHitsSISmg, plyHitsSISniper, plyHitsSIPistol, plyHitsTankShotgun, plyHitsTankSmg, plyHitsTankSniper, plyHitsTankPistol, plyCommon, plyCommonTankUp, plySIKilled, plySIKilledTankUp, plySIDamage, plySIDamageTankUp, plyIncaps, plyDied, plySkeets, plySkeetsHurt, plySkeetsMelee, plyLevels, plyLevelsHurt, plyPops, plyCrowns, plyCrownsHurt, plyShoves, plyDeadStops, plyTongueCuts, plySelfClears, plyFallDamage, plyDmgTaken, plyDmgTakenBoom, plyDmgTakenCommon, plyDmgTakenTank, plyBowls, plyCharges, plyDeathCharges, plyFFGiven, plyFFTaken, plyFFHits, plyTankDamage, plyWitchDamage, plyMeleesOnTank, plyRockSkeets, plyRockEats, plyFFGivenPellet, plyFFGivenBullet, plyFFGivenSniper, plyFFGivenMelee, plyFFGivenFire, plyFFGivenIncap, plyFFGivenOther, plyFFGivenSelf, plyFFTakenPellet, plyFFTakenBullet, plyFFTakenSniper, plyFFTakenMelee, plyFFTakenFire, plyFFTakenIncap, plyFFTakenOther, plyFFGivenTotal, plyFFTakenTotal, plyCarsTriggered, plyJockeyRideDuration, plyJockeyRideTotal, plyClears, plyAvgClearTime, plyTimeStartPresent, plyTimeStopPresent, plyTimeStartAlive, plyTimeStopAlive, plyTimeStartUpright, plyTimeStopUpright, plyCurFlowDist, plyFarFlowDist, plyProtectAwards ) ");
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, "VALUES ( NULL,'%s',%i,%i,%i,'%s','%s',%i,%i", createdAt, matchId, round, team, map, steamid, deleted, isSecondHalf);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i,%i", g_strRoundPlayerData[j][iTeam][0], g_strRoundPlayerData[j][iTeam][1], g_strRoundPlayerData[j][iTeam][2], g_strRoundPlayerData[j][iTeam][3], g_strRoundPlayerData[j][iTeam][4], g_strRoundPlayerData[j][iTeam][5], g_strRoundPlayerData[j][iTeam][6], g_strRoundPlayerData[j][iTeam][7], g_strRoundPlayerData[j][iTeam][8], g_strRoundPlayerData[j][iTeam][9]);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i,%i", g_strRoundPlayerData[j][iTeam][10], g_strRoundPlayerData[j][iTeam][11], g_strRoundPlayerData[j][iTeam][12], g_strRoundPlayerData[j][iTeam][13], g_strRoundPlayerData[j][iTeam][14], g_strRoundPlayerData[j][iTeam][15], g_strRoundPlayerData[j][iTeam][16], g_strRoundPlayerData[j][iTeam][17], g_strRoundPlayerData[j][iTeam][18], g_strRoundPlayerData[j][iTeam][19]);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i,%i", g_strRoundPlayerData[j][iTeam][20], g_strRoundPlayerData[j][iTeam][21], g_strRoundPlayerData[j][iTeam][22], g_strRoundPlayerData[j][iTeam][23], g_strRoundPlayerData[j][iTeam][24], g_strRoundPlayerData[j][iTeam][25], g_strRoundPlayerData[j][iTeam][26], g_strRoundPlayerData[j][iTeam][27], g_strRoundPlayerData[j][iTeam][28], g_strRoundPlayerData[j][iTeam][29]);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i,%i", g_strRoundPlayerData[j][iTeam][30], g_strRoundPlayerData[j][iTeam][31], g_strRoundPlayerData[j][iTeam][32], g_strRoundPlayerData[j][iTeam][33], g_strRoundPlayerData[j][iTeam][34], g_strRoundPlayerData[j][iTeam][35], g_strRoundPlayerData[j][iTeam][36], g_strRoundPlayerData[j][iTeam][37], g_strRoundPlayerData[j][iTeam][38], g_strRoundPlayerData[j][iTeam][39]);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i,%i", g_strRoundPlayerData[j][iTeam][40], g_strRoundPlayerData[j][iTeam][41], g_strRoundPlayerData[j][iTeam][42], g_strRoundPlayerData[j][iTeam][43], g_strRoundPlayerData[j][iTeam][44], g_strRoundPlayerData[j][iTeam][45], g_strRoundPlayerData[j][iTeam][46], g_strRoundPlayerData[j][iTeam][47], g_strRoundPlayerData[j][iTeam][48], g_strRoundPlayerData[j][iTeam][49]);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i,%i", g_strRoundPlayerData[j][iTeam][50], g_strRoundPlayerData[j][iTeam][51], g_strRoundPlayerData[j][iTeam][52], g_strRoundPlayerData[j][iTeam][53], g_strRoundPlayerData[j][iTeam][54], g_strRoundPlayerData[j][iTeam][55], g_strRoundPlayerData[j][iTeam][56], g_strRoundPlayerData[j][iTeam][57], g_strRoundPlayerData[j][iTeam][58], g_strRoundPlayerData[j][iTeam][59]);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i,%i", g_strRoundPlayerData[j][iTeam][60], g_strRoundPlayerData[j][iTeam][61], g_strRoundPlayerData[j][iTeam][62], g_strRoundPlayerData[j][iTeam][63], g_strRoundPlayerData[j][iTeam][64], g_strRoundPlayerData[j][iTeam][65], g_strRoundPlayerData[j][iTeam][66], g_strRoundPlayerData[j][iTeam][67], g_strRoundPlayerData[j][iTeam][68], g_strRoundPlayerData[j][iTeam][69]);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i,%i", g_strRoundPlayerData[j][iTeam][70], g_strRoundPlayerData[j][iTeam][71], g_strRoundPlayerData[j][iTeam][72], g_strRoundPlayerData[j][iTeam][73], g_strRoundPlayerData[j][iTeam][74], g_strRoundPlayerData[j][iTeam][75], g_strRoundPlayerData[j][iTeam][76], g_strRoundPlayerData[j][iTeam][77], g_strRoundPlayerData[j][iTeam][78], g_strRoundPlayerData[j][iTeam][79]);
    iLen += FormatEx(sQuery[iLen], sizeof(sQuery) - iLen - 1, ",%i,%i,%i,%i,%i,%i,%i,%i,%i )", g_strRoundPlayerData[j][iTeam][80], g_strRoundPlayerData[j][iTeam][81], g_strRoundPlayerData[j][iTeam][82], g_strRoundPlayerData[j][iTeam][83], g_strRoundPlayerData[j][iTeam][84], g_strRoundPlayerData[j][iTeam][85], g_strRoundPlayerData[j][iTeam][86], g_strRoundPlayerData[j][iTeam][87], g_strRoundPlayerData[j][iTeam][88]);

    g_Database.Query(OnSQLInsertCallback, sQuery);
}

public void InsertInfected(const char[] createdAt, int matchId, int round, int team, const char[] map, const char[] steamid, bool deleted, bool isSecondHalf, int _infDmgTotal, int _infDmgUpright, int _infDmgTank, int _infDmgTankIncap, int _infDmgScratch, int _infDmgScratchSmoker, int _infDmgScratchBoomer, int _infDmgScratchHunter, int _infDmgScratchCharger, int _infDmgScratchSpitter, int _infDmgScratchJockey, int _infDmgSpit, int _infDmgBoom, int _infDmgTankUp, int _infHunterDPs, int _infHunterDPDmg, int _infJockeyDPs, int _infDeathCharges, int _infCharges, int _infMultiCharges, int _infBoomsSingle, int _infBoomsDouble, int _infBoomsTriple, int _infBoomsQuad, int _infBooms, int _infBoomerPops, int _infLedged, int _infCommon, int _infSpawns, int _infSpawnSmoker, int _infSpawnBoomer, int _infSpawnHunter, int _infSpawnCharger, int _infSpawnSpitter, int _infSpawnJockey, int _infTankPasses, int _infTankRockHits, int _infCarsTriggered, int _infJockeyRideDuration, int _infJockeyRideTotal, int _infTimeStartPresent, int _infTimeStopPresent) {
    g_iQueries++;
    char sQuery[7000];
    g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO infected ( id, createdAt, matchId, round, team, map, steamid, deleted, isSecondHalf, infDmgTotal, infDmgUpright, infDmgTank, infDmgTankIncap, infDmgScratch, infDmgScratchSmoker, infDmgScratchBoomer, infDmgScratchHunter, infDmgScratchCharger, infDmgScratchSpitter, infDmgScratchJockey, infDmgSpit, infDmgBoom, infDmgTankUp, infHunterDPs, infHunterDPDmg, infJockeyDPs, infDeathCharges, infCharges, infMultiCharges, infBoomsSingle, infBoomsDouble, infBoomsTriple, infBoomsQuad, infBooms, infBoomerPops, infLedged, infCommon, infSpawns, infSpawnSmoker, infSpawnBoomer, infSpawnHunter, infSpawnCharger, infSpawnSpitter, infSpawnJockey, infTankPasses, infTankRockHits, infCarsTriggered, infJockeyRideDuration, infJockeyRideTotal, infTimeStartPresent, infTimeStopPresent ) VALUES ( NULL,'%s',%i,%i,%i,'%s','%s',%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i,%i )", createdAt, matchId, round, team, map, steamid, deleted, isSecondHalf, _infDmgTotal, _infDmgUpright, _infDmgTank, _infDmgTankIncap, _infDmgScratch, _infDmgScratchSmoker, _infDmgScratchBoomer, _infDmgScratchHunter, _infDmgScratchCharger, _infDmgScratchSpitter, _infDmgScratchJockey, _infDmgSpit, _infDmgBoom, _infDmgTankUp, _infHunterDPs, _infHunterDPDmg, _infJockeyDPs, _infDeathCharges, _infCharges, _infMultiCharges, _infBoomsSingle, _infBoomsDouble, _infBoomsTriple, _infBoomsQuad, _infBooms, _infBoomerPops, _infLedged, _infCommon, _infSpawns, _infSpawnSmoker, _infSpawnBoomer, _infSpawnHunter, _infSpawnCharger, _infSpawnSpitter, _infSpawnJockey, _infTankPasses, _infTankRockHits, _infCarsTriggered, _infJockeyRideDuration, _infJockeyRideTotal, _infTimeStartPresent, _infTimeStopPresent);
    g_Database.Query(OnSQLInsertCallback, sQuery);
}

public void InsertMatchlog(const char[] createdAt, int matchId, const char[] map, bool deleted, int result, const char[] steamid, int startedAt, int endedAt, int team, const char[] configName) {
    g_iQueries++;
    char sQuery[2500];
    g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO matchlog ( id, createdAt, matchId, map, deleted, result, steamid, startedAt, endedAt, team, configName ) VALUES ( NULL,'%s',%i,'%s',%i,%i,'%s',%i,%i,%i,'%s' )", createdAt, matchId, map, deleted, result, steamid, startedAt, endedAt, team, configName);
    g_Database.Query(OnSQLInsertCallback, sQuery);
}

public void InsertPvpFF(const char[] createdAt, int matchId, int round, int team, const char[] map, const char[] steamid, bool deleted, bool isSecondHalf, const char[] victim, int damage) {
    g_iQueries++;
    char sQuery[2500];
    g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO pvp_ff ( id, createdAt, matchId, round, team, map, steamid, deleted, isSecondHalf, victim, damage ) VALUES ( NULL,'%s',%i,%i,%i,'%s','%s',%i,%i,'%s',%i )", createdAt, matchId, round, team, map, steamid, deleted, isSecondHalf, victim, damage);
    g_Database.Query(OnSQLInsertCallback, sQuery);
}

public void InsertPvpInfDmg(const char[] createdAt, int matchId, int round, int team, const char[] map, const char[] steamid, bool deleted, bool isSecondHalf, const char[] victim, int damage) {
    g_iQueries++;
    char sQuery[2500];
    g_Database.Format(sQuery, sizeof(sQuery), "INSERT INTO pvp_infdmg ( id, createdAt, matchId, round, team, map, steamid, deleted, isSecondHalf, victim, damage ) VALUES ( NULL,'%s',%i,%i,%i,'%s','%s',%i,%i,'%s',%i )", createdAt, matchId, round, team, map, steamid, deleted, isSecondHalf, victim, damage);
    g_Database.Query(OnSQLInsertCallback, sQuery);
}

// write round stats to database
stock WriteStatsToDB( iTeam, bool:bSecondHalf ) {
    if ( g_bModeCampaign ) { return; }

    if (g_Database == null) {
        PrintToServer("[Stats] DB is null");
        PrintDebug( 1, "[Stats] DB is null" );
        return;
    }
    PrintToServer("[Stats] Saving to database");
    PrintDebug( 1, "[Stats] Saving to database" );

    decl String: sTmpMap[64];
    GetCurrentMapLower( sTmpMap, sizeof(sTmpMap) );
    PrintDebug( 1, "[Stats] Map %s", sTmpMap );
    decl String: sTmpTime[20];
    FormatTime( sTmpTime, sizeof(sTmpTime), "%Y-%m-%d %H:%M:%S" );
    PrintDebug( 1, "[Stats] Time %s", sTmpTime );
    PrintDebug( 1, "[Stats] IsMissionFinalMap %i", IsMissionFinalMap() );
    PrintDebug( 1, "[Stats] bSecondHalf %i", bSecondHalf );

    decl String:cfgString[64];
    cfgString[0] = '\0';
    GetConVarString(g_hCvarCustomConfig, cfgString, sizeof(cfgString));
    PrintDebug( 1, "[Stats] g_hCvarCustomConfig %s", cfgString );
    
    new matchId = g_strRoundData[0][0][rndStartTime];
    new startedAt = MIN( g_strRoundData[0][0][rndStartTime], g_strRoundData[0][1][rndStartTime] );
    new endedAt = MAX( g_strRoundData[g_iRound][0][rndEndTime], g_strRoundData[g_iRound][1][rndEndTime] );
    new result = 0;
    
    // round data
    new i;

    InsertRound(sTmpTime, matchId, g_iRound, iTeam, sTmpMap, false, g_bSecondHalf, iTeam == LTEAM_A, g_iScores[LTEAM_A] - g_iFirstScoresSet[((g_bCMTSwapped)?1:0)], g_iScores[LTEAM_A], g_iScores[LTEAM_B] - g_iFirstScoresSet[((g_bCMTSwapped)?0:1)], g_iScores[LTEAM_B], g_iSurvived[iTeam], L4D_GetVersusMaxCompletionScore(), RoundFloat(L4D2Direct_GetMapMaxFlowDistance()), cfgString, g_strRoundData[g_iRound][iTeam][0], g_strRoundData[g_iRound][iTeam][1], g_strRoundData[g_iRound][iTeam][2], g_strRoundData[g_iRound][iTeam][3], g_strRoundData[g_iRound][iTeam][4], g_strRoundData[g_iRound][iTeam][5], g_strRoundData[g_iRound][iTeam][6], g_strRoundData[g_iRound][iTeam][7], g_strRoundData[g_iRound][iTeam][8], g_strRoundData[g_iRound][iTeam][9], g_strRoundData[g_iRound][iTeam][10], g_strRoundData[g_iRound][iTeam][11], g_strRoundData[g_iRound][iTeam][12], g_strRoundData[g_iRound][iTeam][13], g_strRoundData[g_iRound][iTeam][14], g_strRoundData[g_iRound][iTeam][15], g_strRoundData[g_iRound][iTeam][16], g_strRoundData[g_iRound][iTeam][17], g_strRoundData[g_iRound][iTeam][18]);
    
    // player data
    new j;
    new iPlayerCount = 0;
    for ( j = FIRST_NON_BOT; j < g_iPlayers; j++ ) {
        if ( g_iPlayerRoundTeam[iTeam][j] != iTeam ) { continue; }
        iPlayerCount++;

        InsertSurvivor(sTmpTime, matchId, g_iRound, iTeam, sTmpMap, g_sPlayerId[j], false, g_bSecondHalf, j, iTeam);

        if (IsMissionFinalMap() && bSecondHalf) {
            if (g_iScores[iTeam] > g_iScores[(iTeam) ? 0 : 1]) {
                result = 1;
            }
            else if (g_iScores[iTeam] < g_iScores[(iTeam) ? 0 : 1]) {
                result = -1;
            }
            else {
                result = 0;
            }
            InsertMatchlog(sTmpTime, matchId, sTmpMap, false, result, g_sPlayerId[j], startedAt, endedAt, iTeam, cfgString);
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

        InsertInfected(sTmpTime, matchId, g_iRound, iTeam, sTmpMap, g_sPlayerId[j], false, g_bSecondHalf, g_strRoundPlayerInfData[j][iTeam][0], g_strRoundPlayerInfData[j][iTeam][1], g_strRoundPlayerInfData[j][iTeam][2], g_strRoundPlayerInfData[j][iTeam][3], g_strRoundPlayerInfData[j][iTeam][4], g_strRoundPlayerInfData[j][iTeam][5], g_strRoundPlayerInfData[j][iTeam][6], g_strRoundPlayerInfData[j][iTeam][7], g_strRoundPlayerInfData[j][iTeam][8], g_strRoundPlayerInfData[j][iTeam][9], g_strRoundPlayerInfData[j][iTeam][10], g_strRoundPlayerInfData[j][iTeam][11], g_strRoundPlayerInfData[j][iTeam][12], g_strRoundPlayerInfData[j][iTeam][13], g_strRoundPlayerInfData[j][iTeam][14], g_strRoundPlayerInfData[j][iTeam][15], g_strRoundPlayerInfData[j][iTeam][16], g_strRoundPlayerInfData[j][iTeam][17], g_strRoundPlayerInfData[j][iTeam][18], g_strRoundPlayerInfData[j][iTeam][19], g_strRoundPlayerInfData[j][iTeam][20], g_strRoundPlayerInfData[j][iTeam][21], g_strRoundPlayerInfData[j][iTeam][22], g_strRoundPlayerInfData[j][iTeam][23], g_strRoundPlayerInfData[j][iTeam][24], g_strRoundPlayerInfData[j][iTeam][25], g_strRoundPlayerInfData[j][iTeam][26], g_strRoundPlayerInfData[j][iTeam][27], g_strRoundPlayerInfData[j][iTeam][28], g_strRoundPlayerInfData[j][iTeam][29], g_strRoundPlayerInfData[j][iTeam][30], g_strRoundPlayerInfData[j][iTeam][31], g_strRoundPlayerInfData[j][iTeam][32], g_strRoundPlayerInfData[j][iTeam][33], g_strRoundPlayerInfData[j][iTeam][34], g_strRoundPlayerInfData[j][iTeam][35], g_strRoundPlayerInfData[j][iTeam][36], g_strRoundPlayerInfData[j][iTeam][37], g_strRoundPlayerInfData[j][iTeam][38], g_strRoundPlayerInfData[j][iTeam][39], g_strRoundPlayerInfData[j][iTeam][40], g_strRoundPlayerInfData[j][iTeam][41]);
        
        if (IsMissionFinalMap() && bSecondHalf) {
            if (g_iScores[iTeam] < g_iScores[(iTeam) ? 0 : 1]) {
                result = 1;
            }
            else if (g_iScores[iTeam] > g_iScores[(iTeam) ? 0 : 1]) {
                result = -1;
            }
            else {
                result = 0;
            }
            InsertMatchlog(sTmpTime, matchId, sTmpMap, false, result, g_sPlayerId[j], startedAt, endedAt, (iTeam) ? 0 : 1, cfgString);
        }
    }

    // player ff data
    iPlayerCount = 0;
    for ( j = FIRST_NON_BOT; j < g_iPlayers; j++ ) {
        if ( g_iPlayerRoundTeam[iTeam][j] != iTeam ) { continue; }
        iPlayerCount++;

        for ( i = FIRST_NON_BOT; i < g_iPlayers; i++ ) {
            InsertPvpFF(sTmpTime, matchId, g_iRound, iTeam, sTmpMap, g_sPlayerId[j], false, g_bSecondHalf, g_sPlayerId[i], g_strRoundPvPFFData[j][iTeam][i]);
        }
    }

    // player infdmg data
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
        
        for ( i = FIRST_NON_BOT; i < g_iPlayers; i++ ) {
            InsertPvpInfDmg(sTmpTime, matchId, g_iRound, iTeam, sTmpMap, g_sPlayerId[j], false, g_bSecondHalf, g_sPlayerId[i], g_strRoundPvPInfDmgData[j][iTeam][i]);
        }
    }

    if (IsMissionFinalMap() && bSecondHalf) {
        if (g_bSystem2Loaded) {
            CreateTimer(3.0, Timer_MatchEndScript, matchId, TIMER_REPEAT);
        }
        else {
            PrintDebug( 1, "[Stats] system2 library not loaded. Match end cmd won't execute." );
        }
    }
}

public Action Timer_MatchEndScript(Handle timer, int matchId) {
    if (g_iQueries > 0) {
        PrintDebug(1, "[Stats] Waiting for %i queries to finish before executing match end.", g_iQueries);
        return Plugin_Continue;
    }
    
    char cmd[256];
    char fCmd[256];
    if (GetMatchEndScriptCmd(cmd, sizeof(cmd))) {
        Format(fCmd, sizeof(fCmd), cmd, matchId);
        PrintDebug(1, "[Stats] Executing match end cmd: %s.", fCmd);
        System2_ExecuteThreaded(ExecuteCallback, fCmd);
    }
    else {
        PrintDebug(1, "[Stats] Match end cmd not found.");
    }

    return Plugin_Stop;
}

public void ExecuteCallback(bool success, const char[] command, System2ExecuteOutput output, any data) {
    if (!success || output.ExitStatus != 0) {
        PrintToServer("[Stats] Couldn't execute commands %s successfully", command);
        PrintDebug(1, "[Stats] Couldn't execute commands %s successfully", command);
    } else {
        char outputString[128];
        output.GetOutput(outputString, sizeof(outputString));
        PrintToServer("[Stats] Output of the command %s: %s", command, outputString);
        PrintDebug(1, "[Stats] Output of the command %s: %s", command, outputString);
    }
}

bool GetMatchEndScriptCmd(char[] cmd, int iLength)
{
    KeyValues kv = new KeyValues("l4d2_playstats");

    char sFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sFile, sizeof(sFile), "configs/l4d2_playstats.cfg");

    if (!FileExists(sFile))
    {
        PrintDebug(1, "[Stats] GetMatchEndScriptCmd \"%s\" not found!", sFile);
        return false;
    }

    kv.ImportFromFile(sFile);

    if (!kv.JumpToKey("match_end_script_cmd", false))
    {
        PrintDebug(1, "[Stats] GetMatchEndScriptCmd Can't find \"match_end_script_cmd\" in \"%s\"!", sFile);
        delete kv;
        return false;
    }
    kv.GetString(NULL_STRING, cmd, iLength);
    delete kv;
    return true;
}