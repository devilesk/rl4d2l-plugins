#pragma semicolon 1

#include <sourcemod>
#include <l4d2_playstats>
#include <l4d2_playstats_tries>

public Plugin:myinfo =
{
    name = "Player Statistics Tries",
    author = "devilesk",
    version = "1.0.0",
    description = "L4D2 Playstats tries functions.",
    url = "https://steamcommunity.com/groups/RL4D2L"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    RegPluginLibrary("l4d2_playstats_tries");
    
    CreateNative("GetWeaponTypeForClassname", Native_GetWeaponTypeForClassname);
    CreateNative("IsMissionFinalMap", Native_IsMissionFinalMap);
    CreateNative("IsWitch", Native_IsWitch);
    CreateNative("IsCommon", Native_IsCommon);
}

new     Handle: g_hTrieWeapons                                      = INVALID_HANDLE;   // trie for getting weapon type (from classname)
new     Handle: g_hTrieMaps                                         = INVALID_HANDLE;   // trie for getting finale maps
new     Handle: g_hTrieEntityCreated                                = INVALID_HANDLE;   // trie for getting classname of entity created

public OnPluginStart()
{
    InitTries();
}

InitTries()
{
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
}

public int Native_GetWeaponTypeForClassname(Handle:plugin, numParams)
{
    new len;

    GetNativeStringLength(1, len);
    new String:classname[len+1];
    GetNativeString(1, classname, len+1);
    
    new strWeaponType: weaponType;
    
    if ( !GetTrieValue(g_hTrieWeapons, classname, weaponType) ) {
        return WPTYPE_NONE;
    }
    
    return weaponType;
}

public int Native_IsMissionFinalMap(Handle:plugin, numParams)
{
    new len;

    GetNativeStringLength(1, len);
    new String:mapname[len+1];
    GetNativeString(1, mapname, len+1);
    
    // since L4D_IsMissionFinalMap() is bollocksed, simple map string check
    new strMapType: mapType;
    if ( !GetTrieValue(g_hTrieMaps, mapname, mapType) ) { return false; }
    return bool:( mapType == MP_FINALE );
}

public int Native_IsWitch(Handle:plugin, numParams)
{
    int iEntity = GetNativeCell(1);
    
    if ( iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity) )
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        new strOEC: entType;
        
        if ( !GetTrieValue(g_hTrieEntityCreated, strClassName, entType) ) { return false; }
        
        return bool:(entType == OEC_WITCH);
    }
    return false;
}

public int Native_IsCommon(Handle:plugin, numParams)
{
    int iEntity = GetNativeCell(1);
    
    if ( iEntity > 0 && IsValidEntity(iEntity) && IsValidEdict(iEntity) )
    {
        decl String:strClassName[64];
        GetEdictClassname(iEntity, strClassName, sizeof(strClassName));
        new strOEC: entType;
        
        if ( !GetTrieValue(g_hTrieEntityCreated, strClassName, entType) ) { return false; }
        
        return bool:(entType == OEC_INFECTED);
    }
    return false;
}