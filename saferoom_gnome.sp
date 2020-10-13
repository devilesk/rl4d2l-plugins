#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <readyup>

new Handle:g_hCvarEnabled = INVALID_HANDLE;
new Handle:g_hCvarDebug = INVALID_HANDLE;
new g_iGnome = -1;
new bool:g_bRoundIsLive = false;

public Plugin:myinfo = {
    name = "Saferoom Gnome",
    author = "devilesk",
    description = "Spawns a gnome in the saferoom that is removed when the round goes live.",
    version = "1.3.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
}

public OnPluginStart() {
    g_hCvarEnabled = CreateConVar("sm_saferoom_gnome", "1", "Enable saferoom gnome spawn", 0, true, 0.0, true, 1.0);
    g_hCvarDebug = CreateConVar("sm_saferoom_gnome_debug", "0", "Saferoom Gnome debug mode", 0, true, 0.0, true, 1.0);
    HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    if(!GetConVarBool(g_hCvarEnabled)) return Plugin_Continue;
    g_iGnome = -1;
    g_bRoundIsLive = false;
    PrintDebug("[Event_RoundStart] Starting spawn gnome timer...");
    CreateTimer(1.0, Timer_SpawnGnome, TIMER_FLAG_NO_MAPCHANGE);
    
    return Plugin_Continue;
}

public Action:Timer_SpawnGnome(Handle:timer) {
    new client = GetInGameClient();
    if (client) {
        if (IsValidEdict(g_iGnome)) {
            PrintDebug("[Timer_SpawnGnome] Gnome exists. g_iGnome: %i", g_iGnome);
            return;
        }
        
        g_iGnome = CreateEntityByName("weapon_gnome");
        DispatchSpawn(g_iGnome);

        decl Float:vecPosition[3];
        GetClientAbsOrigin(client, vecPosition);
        vecPosition[2] += 20;
        TeleportEntity(g_iGnome, vecPosition, NULL_VECTOR, NULL_VECTOR);
        
        PrintDebug("[Timer_SpawnGnome] client %i, g_iGnome %i, vecPosition: (%.2f,%.2f,%.2f)", client, g_iGnome, vecPosition[0], vecPosition[1], vecPosition[2]);
    }
    else {
        PrintDebug("[Timer_SpawnGnome] No client. Retrying...");
        CreateTimer(1.0, Timer_SpawnGnome, TIMER_FLAG_NO_MAPCHANGE);
    }
}

// track gnomes that are dropped
public OnEntityCreated(entity, const String:classname[]) {
    if (g_bRoundIsLive) return;
    
    if (StrEqual(classname, "physics_prop", false)) {
        CreateTimer(0.01, Timer_CreatedPropPhysics, entity, TIMER_FLAG_NO_MAPCHANGE);
    }
}

public Action: Timer_CreatedPropPhysics(Handle:timer, any:entity) {
    if (!IsValidEntity(entity)) return Plugin_Continue;
    
    new String:modelname[64];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
    
    if (StrEqual(modelname, "models/props_junk/gnome.mdl", false)) {
        PrintDebug("[Timer_CreatedPropPhysics] g_iGnome %i", g_iGnome);
        g_iGnome = entity;
    }
    
    return Plugin_Continue;
}

public OnRoundIsLive() {
    // kill all held gnomes
    decl String:weapon_name[64];
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) == 2) {
            GetClientWeapon(i, weapon_name, sizeof(weapon_name));
            if (StrEqual(weapon_name, "weapon_gnome", false)) {
                new entity = GetEntPropEnt(i, Prop_Send, "m_hActiveWeapon");
                if (IsValidEdict(entity)) {
                    PrintDebug("[OnRoundIsLive] Killing held gnome. client: %i, weapon_name: %s, entity: %i", i, weapon_name, entity);
                    AcceptEntityInput(entity, "Kill");
                }
            }
        }
    }
    
    // kill tracked gnome
    decl String:modelname[64];
    if (IsValidEdict(g_iGnome)) {
        GetEntPropString(g_iGnome, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
        if (StrEqual(modelname, "models/props_junk/gnome.mdl", false)) {
            PrintDebug("[OnRoundIsLive] Killing gnome. g_iGnome %i", g_iGnome);
            AcceptEntityInput(g_iGnome, "Kill");
            g_iGnome = -1;
        }
    }
    
    g_bRoundIsLive = true;
}

stock GetInGameClient() {
    for (new i = 1; i <= MaxClients; i++) {
        if (IsClientInGame(i) && GetClientTeam(i) == 2)
            return i;
    }
    return 0;
}

stock PrintDebug(const String:Message[], any:...) {
    if (GetConVarBool(g_hCvarDebug)) {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}