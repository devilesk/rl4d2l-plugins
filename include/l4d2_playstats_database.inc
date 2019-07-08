#if defined _l4d2_playstats_database_included_
  #endinput
#endif
#define _l4d2_playstats_database_included_

native int IsDatabaseConnected();
native int PrepareRoundQuery();
native int PrepareSurvivorQuery();
native int PrepareInfectedQuery();
native int PrepareProgressQuery();
native int ExecuteRoundQuery(String:sTime[], iRound, iTeam, String:sMap[], bool:bDeleted, bool:bSecondHalf, bool:bTeamIsA, iTeamARound, iTeamATotal, iTeamBRound, iTeamBTotal, iSurvivorCount, iMaxCompletionScore, iMaxFlowDist, int[] rndData, int size);
native int ExecuteSurvivorQuery(String:sTime[], iRound, iTeam, String:sMap[], String:sSteamId[], bool:bDeleted, bool:bSecondHalf, int[] rndData, int size);
native int ExecuteInfectedQuery(String:sTime[], iRound, iTeam, String:sMap[], String:sSteamId[], bool:bDeleted, bool:bSecondHalf, int[] rndData, int size);
native int ExecuteProgressQuery(String:sTime[], iRound, iTeam, String:sMap[], String:sSteamId[], bool:bDeleted, bool:bSecondHalf, iCurFlowDist, iFarFlowDist);

public SharedPlugin __pl_l4d2_playstats_database = 
{
    name = "l4d2_playstats_database",
    file = "l4d2_playstats_database.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_playstats_database_SetNTVOptional()
{
    MarkNativeAsOptional("IsDatabaseConnected");
    MarkNativeAsOptional("PrepareRoundQuery");
    MarkNativeAsOptional("PrepareSurvivorQuery");
    MarkNativeAsOptional("PrepareInfectedQuery");
    MarkNativeAsOptional("PrepareProgressQuery");
    MarkNativeAsOptional("ExecuteRoundQuery");
    MarkNativeAsOptional("ExecuteSurvivorQuery");
    MarkNativeAsOptional("ExecuteInfectedQuery");
    MarkNativeAsOptional("ExecuteProgressQuery");
}
#endif