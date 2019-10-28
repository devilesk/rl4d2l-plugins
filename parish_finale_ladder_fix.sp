#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

/*
 * There are 5 infected ladders on the parish finale bridge that don't get loaded in the second round.
 * For some reason it is due to having the bridge entity as their parent when the first round ends.
 * To fix this the ladders have their parent cleared after the bridge is lowered in the first round,
 * When the second round starts, the ladders are moved back to their original position
 * and their parent is set back to the bridge.
 * Ladder entity model names: *58, *59, *60, *61, *62
 */

new String:mapname[200];

public Plugin:myinfo = {
    name = "Parish Finale Ladder Fix",
    author = "devilesk",
    description = "Fixes Parish finale bridge ladders disappearing in second round.",
    version = "1.0.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public OnPluginStart() {
    HookEvent("round_start", Event_RoundStart, EventHookMode_Post);
}

// Clear the parent for the ladders on the bridge once the bridge is lowered
public Hook_OnReachedBottom(const String:output[], caller, activator, Float:delay)
{
    if (caller <= 0 || caller > GetMaxEntities() || !IsValidEntity(caller)) return;

    decl String:targetname[128];
    Entity_GetName(caller, targetname, sizeof(targetname));
    if (!StrEqual(targetname, "drawbridge", false))
        return;

    decl String:classname[32];
    decl String:modelname[128];
    for (new i = MaxClients + 1; i <= GetEntityCount(); i++)
    {
        if (!IsValidEntity(i))
            continue;

        GetEntityClassname(i, classname, 32);
        if (!StrEqual(classname, "func_simpleladder", false))
            continue;

        GetEntPropString(i, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
        if (!StrEqual(modelname, "*58", false) &&
            !StrEqual(modelname, "*59", false) &&
            !StrEqual(modelname, "*60", false) &&
            !StrEqual(modelname, "*61", false) &&
            !StrEqual(modelname, "*62", false))
            continue;

        Entity_ClearParent(i);
    }
}

// 1st round: Hook the bridge OnReachedBottom output
// 2nd round: Move the ladders back and set their parent to the bridge
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
    GetCurrentMap(mapname, sizeof(mapname));
    if (!StrEqual(mapname, "c5m5_bridge", false)) return;

    new drawbridge = Entity_FindByName("drawbridge");
    if (!IsValidEntity(drawbridge))
        return;

    if (!InSecondHalfOfRound()) {
        HookSingleEntityOutput(drawbridge, "OnReachedBottom", Hook_OnReachedBottom, true);
        return;
    }

    decl String:classname[32];
    decl String:modelname[128];
    new Float:origin[3] = { 0.0, 0.0, 0.0 };
    for (new i = MaxClients + 1; i <= GetEntityCount(); i++)
    {
        if (!IsValidEntity(i))
            continue;

        GetEntityClassname(i, classname, 32);
        if (!StrEqual(classname, "func_simpleladder", false))
            continue;

        GetEntPropString(i, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
        if (!StrEqual(modelname, "*58", false) && !StrEqual(modelname, "*59", false) && !StrEqual(modelname, "*60", false) && !StrEqual(modelname, "*61", false) && !StrEqual(modelname, "*62", false))
            continue;

        TeleportEntity(i, origin, NULL_VECTOR, NULL_VECTOR);
        Entity_SetParent(i, drawbridge);
    }
}

stock bool:InSecondHalfOfRound() {
    return bool:GameRules_GetProp("m_bInSecondHalfOfRound");
}

/*
 * Entity stocks from smlib/entities.inc
 */

stock Entity_FindByName(const String:name[], const String:className[]="")
{
    if (className[0] == '\0') {
        // Hack: Double the limit to gets none-networked entities too.
        new realMaxEntities = GetMaxEntities() * 2;
        for (new entity=0; entity < realMaxEntities; entity++) {

            if (!IsValidEntity(entity)) {
                continue;
            }

            if (Entity_NameMatches(entity, name)) {
                return entity;
            }
        }
    }
    else {
        new entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, className)) != INVALID_ENT_REFERENCE) {

            if (Entity_NameMatches(entity, name)) {
                return entity;
            }
        }
    }

    return INVALID_ENT_REFERENCE;
}

stock bool:Entity_NameMatches(entity, const String:name[])
{
    decl String:entity_name[128];
    Entity_GetName(entity, entity_name, sizeof(entity_name));

    return StrEqual(name, entity_name);
}

stock Entity_GetName(entity, String:buffer[], size)
{
    return GetEntPropString(entity, Prop_Data, "m_iName", buffer, size);
}

stock Entity_ClearParent(entity)
{
    SetVariantString("");
    AcceptEntityInput(entity, "ClearParent");
}

stock Entity_SetParent(entity, parent)
{
    SetVariantString("!activator");
    AcceptEntityInput(entity, "SetParent", parent);
}