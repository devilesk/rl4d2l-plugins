#if defined _l4d2_playstats_tries_included_
  #endinput
#endif
#define _l4d2_playstats_tries_included_

native int GetWeaponTypeForClassname ( const String:classname[] );
native int IsMissionFinalMap ( const String:mapname[] );
native int IsWitch ( iEntity );
native int IsCommon ( iEntity );

public SharedPlugin __pl_l4d2_playstats_tries = 
{
    name = "l4d2_playstats_tries",
    file = "l4d2_playstats_tries.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_l4d2_playstats_tries_SetNTVOptional()
{
    MarkNativeAsOptional("GetWeaponTypeForClassname");
    MarkNativeAsOptional("IsMissionFinalMap");
    MarkNativeAsOptional("IsWitch");
    MarkNativeAsOptional("IsCommon");
}
#endif