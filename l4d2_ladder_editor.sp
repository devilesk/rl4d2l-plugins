#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define MAX_STR_LEN             100
#define DEFAULT_STEP_SIZE       1.0
#define TEAM_INFECTED           3

static selectedLadder[MAXPLAYERS + 1];
static bEditMode[MAXPLAYERS + 1];
static Float:stepSize[MAXPLAYERS + 1];
new Handle:hLadders;
new bool:in_attack[MAXPLAYERS + 1];
new bool:in_attack2[MAXPLAYERS + 1];

public Plugin:myinfo = {
    name = "L4D2 Ladder Editor",
    author = "devilesk",
    version = "0.3.0",
    description = "Clone and move special infected ladders.",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public OnPluginStart() {
    RegConsoleCmd("sm_edit", Command_Edit);
    RegConsoleCmd("sm_step", Command_Step);
    RegConsoleCmd("sm_select", Command_Select);
    RegConsoleCmd("sm_clone", Command_Clone);
    RegConsoleCmd("sm_move", Command_Move);
    RegConsoleCmd("sm_nudge", Command_Nudge);
    RegConsoleCmd("sm_kill", Command_Kill);
    RegConsoleCmd("sm_info", Command_Info);
    HookEvent("player_team", PlayerTeam_Event);
    hLadders = CreateTrie();
    for (new i = 1; i <= MaxClients; i++) {
        selectedLadder[i] = -1;
        bEditMode[i] = false;
        in_attack[i] = false;
        in_attack2[i] = false;
        stepSize[i] = DEFAULT_STEP_SIZE;
    }
}

public OnMapStart() {
    for (new i = 1; i <= MaxClients; i++) {
        selectedLadder[i] = -1;
        bEditMode[i] = false;
        in_attack[i] = false;
        in_attack2[i] = false;
        stepSize[i] = DEFAULT_STEP_SIZE;
    }
    ClearTrie(hLadders);
}

public OnClientDisconnect_Post(client)
{
    bEditMode[client] = false;
    in_attack[client] = false;
    in_attack2[client] = false;
    stepSize[client] = DEFAULT_STEP_SIZE;
}

stock SetClientFrozen(client, freeze)
{
    SetEntityMoveType(client, freeze ? MOVETYPE_NONE : MOVETYPE_WALK);
}

public bool:GetEndPosition(client, Float:end[3])
{
    decl Float:start[3], Float:angle[3];
    GetClientEyePosition(client, start);
    GetClientEyeAngles(client, angle);
    TR_TraceRayFilter(start, angle, MASK_SOLID, RayType_Infinite, TraceEntityFilterPlayer, client);
    if (TR_DidHit(INVALID_HANDLE))
    {
        TR_GetEndPosition(end, INVALID_HANDLE);
        return true;
    }
    return false;
}

public bool:TraceEntityFilterPlayer(entity, contentsMask, any:data)
{
    return entity > MaxClients;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon) {
    if (client <= 0 || client > MaxClients) return Plugin_Continue;
    if (!IsClientInGame(client)) return Plugin_Continue;
    if (IsFakeClient(client)) return Plugin_Continue;
    if (!bEditMode[client]) return Plugin_Continue;

    new prevButtons = buttons;

    // Player was holding m1, and now isn't. (Released)
    if (buttons & IN_ATTACK != IN_ATTACK && in_attack[client]) {
        in_attack[client] = false;
        Command_Select(client, 0);
    }
    // Player was not holding m1, and now is. (Pressed)
    if (buttons & IN_ATTACK == IN_ATTACK && !in_attack[client]) {
        in_attack[client] = true;
    }

    // Player was holding m2, and now isn't. (Released)
    if (buttons & IN_ATTACK2 != IN_ATTACK2 && in_attack2[client]) {
        in_attack2[client] = false;
        decl Float:end[3];
        if (GetEndPosition(client, end))
            Move(client, end[0], end[1], end[2], true);
        else
            PrintToChat(client, "Invalid end position.");
    }
    // Player was not holding m2, and now is. (Pressed)
    if (buttons & IN_ATTACK2 == IN_ATTACK2 && !in_attack2[client]) {
        in_attack2[client] = true;
    }

    if (buttons & IN_MOVELEFT == IN_MOVELEFT) {
        Nudge(client, -stepSize[client], 0.0, 0.0, false);
    }
    if (buttons & IN_MOVERIGHT == IN_MOVERIGHT) {
        Nudge(client, stepSize[client], 0.0, 0.0, false);
    }
    if (buttons & IN_FORWARD == IN_FORWARD) {
        Nudge(client, 0.0, stepSize[client], 0.0, false);
    }
    if (buttons & IN_BACK == IN_BACK) {
        Nudge(client, 0.0, -stepSize[client], 0.0, false);
    }
    if (buttons & IN_USE == IN_USE) {
        Nudge(client, 0.0, 0.0, stepSize[client], false);
    }
    if (buttons & IN_RELOAD == IN_RELOAD) {
        Nudge(client, 0.0, 0.0, -stepSize[client], false);
    }

    buttons &= ~(IN_ATTACK | IN_ATTACK2 | IN_USE | IN_RELOAD);

    if (prevButtons != buttons) {
        return Plugin_Changed;
    }
    return Plugin_Continue;
}

public PlayerTeam_Event(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    new team = GetEventInt(event, "team");
    if (team != TEAM_INFECTED && bEditMode[client]) {
        bEditMode[client] = false;
        PrintToChat(client, "Exiting edit mode.");
    }
}

public Action Command_Step(int client, int args)
{
    if (args != 1) {
        PrintToChat(client, "[SM] Usage: sm_step <size>");
        return Plugin_Handled;
    }
    char x[8];
    GetCmdArg(1, x, sizeof(x));
    new size = StringToInt(x);
    if (size > 0) {
        stepSize[client] = size * 1.0;
        PrintToChat(client, "Step size set to %i.", size);
    }
    else {
        PrintToChat(client, "Step size must be greater than 0.");
    }
    return Plugin_Handled;
}

public Action Command_Edit(int client, int args)
{
    if (GetClientTeam(client) != TEAM_INFECTED) {
        PrintToChat(client, "Must be on infected team to enter edit mode.");
        return Plugin_Handled;
    }
    if (bEditMode[client]) {
        bEditMode[client] = false;
        SetClientFrozen(client, false);
        PrintToChat(client, "Exiting edit mode.");
    }
    else {
        bEditMode[client] = true;
        SetClientFrozen(client, true);
        PrintToChat(client, "Entering edit mode.");
    }
    return Plugin_Handled;
}

public Action Command_Kill(int client, int args)
{
    decl String:modelname[128];
    new String:classname[MAX_STR_LEN];
    new entity = selectedLadder[client];
    if (IsValidEntity(entity)) {
        GetEntityClassname(entity, classname, MAX_STR_LEN);
        new Float:normal[3];
        new Float:origin[3];
        new Float:position[3];
        decl Float:mins[3], Float:maxs[3];
        GetEntPropVector(entity, Prop_Send, "m_climbableNormal", normal);
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
        GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
        GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
        position[0] = origin[0] + (mins[0] + maxs[0]) * 0.5;
        position[1] = origin[1] + (mins[1] + maxs[1]) * 0.5;
        position[2] = origin[1] + (mins[2] + maxs[2]) * 0.5;
        AcceptEntityInput(entity, "Kill");
        selectedLadder[client] = -1;
        decl String:key[8];
        IntToString(entity, key, 8);
        RemoveFromTrie(hLadders, key);
        PrintToChat(client, "Killed ladder entity %i, %s at (%.2f,%.2f,%.2f). origin: (%.2f,%.2f,%.2f). normal: (%.2f,%.2f,%.2f)", entity, modelname, position[0], position[1], position[2], origin[0], origin[1], origin[2], normal[0], normal[1], normal[2]);
    }
    else {
        PrintToChat(client, "No ladder selected.");
    }
    return Plugin_Handled;
}

public Action Command_Info(int client, int args)
{
    decl String:modelname[128];
    new String:classname[MAX_STR_LEN];
    new entity = GetClientAimTarget(client, false);
    if (IsValidEntity(entity)) {
        GetEntityClassname(entity, classname, MAX_STR_LEN);
        if (StrEqual(classname, "func_simpleladder", false)) {
            GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
            new Float:normal[3];
            new Float:origin[3];
            new Float:position[3];
            decl Float:mins[3], Float:maxs[3];
            GetEntPropVector(entity, Prop_Send, "m_climbableNormal", normal);
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
            GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
            GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
            position[0] = origin[0] + (mins[0] + maxs[0]) * 0.5;
            position[1] = origin[1] + (mins[1] + maxs[1]) * 0.5;
            position[2] = origin[1] + (mins[2] + maxs[2]) * 0.5;
            PrintToChat(client, "Ladder entity %i, %s at (%.2f,%.2f,%.2f). origin: (%.2f,%.2f,%.2f). normal: (%.2f,%.2f,%.2f)", entity, modelname, position[0], position[1], position[2], origin[0], origin[1], origin[2], normal[0], normal[1], normal[2]);

            PrintToChat(client, "add:");
            PrintToChat(client, "{");
            PrintToChat(client, "    \"model\" \"%s\"", modelname);
            PrintToChat(client, "    \"normal.z\" \"%.2f\"", normal[2]);
            PrintToChat(client, "    \"normal.y\" \"%.2f\"", normal[1]);
            PrintToChat(client, "    \"normal.x\" \"%.2f\"", normal[0]);
            PrintToChat(client, "    \"team\" \"2\"");
            PrintToChat(client, "    \"classname\" \"func_simpleladder\"");
            PrintToChat(client, "    \"origin\" \"%.2f %.2f %.2f\"", origin[0], origin[1], origin[2]);
            PrintToChat(client, "}");
        }
        else {
            PrintToChat(client, "Not looking at a ladder. Entity %i, classname: %s", entity, classname);
        }
    }
    else {
        PrintToChat(client, "Looking at invalid entity %i", entity);
    }
    return Plugin_Handled;
}

public Nudge(int client, float x, float y, float z, bool bPrint)
{
    new entity = selectedLadder[client];
    if (IsValidEntity(entity)) {
        new Float:position[3];
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
        new Float:origin[3];
        origin[0] = position[0] + x;
        origin[1] = position[1] + y;
        origin[2] = position[2] + z;
        TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
        GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
        if (bPrint)
            PrintToChat(client, "Nudged ladder entity %i. Origin (%.2f,%.2f,%.2f)", entity, origin[0], origin[1], origin[2]);
    }
    else {
        if (bPrint)
            PrintToChat(client, "No ladder selected.");
    }
}

public Action Command_Nudge(int client, int args)
{
    if (args != 3) {
        PrintToChat(client, "[SM] Usage: sm_nudge <x> <y> <z>");
        return Plugin_Handled;
    }
    char x[8], y[8], z[8];
    GetCmdArg(1, x, sizeof(x));
    GetCmdArg(2, y, sizeof(y));
    GetCmdArg(3, z, sizeof(z));
    Nudge(client, StringToFloat(x), StringToFloat(y), StringToFloat(z), true);
    return Plugin_Handled;
}

public Move(int client, float x, float y, float z, bool bPrint)
{
    new entity = selectedLadder[client];
    if (IsValidEntity(entity)) {
        new sourceEnt;
        decl String:key[8];
        IntToString(entity, key, 8);
        if (!GetTrieValue(hLadders, key, sourceEnt)) {
            if (bPrint)
                PrintToChat(client, "Original ladder not found.");
            return;
        }
        new Float:sourcePos[3];
        decl Float:mins[3], Float:maxs[3];
        GetEntPropVector(sourceEnt, Prop_Send, "m_vecOrigin", sourcePos);
        GetEntPropVector(sourceEnt,Prop_Send,"m_vecMins",mins);
        GetEntPropVector(sourceEnt,Prop_Send,"m_vecMaxs",maxs);
        sourcePos[0] += (mins[0] + maxs[0]) * 0.5;
        sourcePos[1] += (mins[1] + maxs[1]) * 0.5;
        sourcePos[2] += (mins[2] + maxs[2]) * 0.5;
        if (bPrint)
            PrintToChat(client, "Original ladder entity %i at (%.2f,%.2f,%.2f)", sourceEnt, sourcePos[0], sourcePos[1], sourcePos[2]);
        
        new Float:origin[3];
        origin[0] = x - sourcePos[0];
        origin[1] = y - sourcePos[1];
        origin[2] = z - sourcePos[2];
    
        TeleportEntity(entity, origin, NULL_VECTOR, NULL_VECTOR);
        if (bPrint)
            PrintToChat(client, "Moved ladder entity %i. Origin (%.2f,%.2f,%.2f)", entity, origin[0], origin[1], origin[2]);
    }
    else {
        if (bPrint)
            PrintToChat(client, "No ladder selected.");
    }
}

public Action Command_Move(int client, int args)
{
    if (args != 3) {
        PrintToChat(client, "[SM] Usage: sm_move <x> <y> <z>");
        return Plugin_Handled;
    }
    char x[8], y[8], z[8];
    GetCmdArg(1, x, sizeof(x));
    GetCmdArg(2, y, sizeof(y));
    GetCmdArg(3, z, sizeof(z));
    Move(client, StringToFloat(x), StringToFloat(y), StringToFloat(z), true);
    return Plugin_Handled;
}

public Action Command_Clone(int client, int args)
{
    decl String:modelname[128];
    decl String:buf[32];
    new String:classname[MAX_STR_LEN];
    new sourceEnt = selectedLadder[client];
    if (IsValidEntity(sourceEnt)) {
        GetEntityClassname(sourceEnt, classname, MAX_STR_LEN);
        if (!StrEqual(classname, "func_simpleladder", false)) {
            selectedLadder[client] = -1;
            PrintToChat(client, "No ladder selected.");
            return Plugin_Handled;
        }
        GetEntPropString(sourceEnt, Prop_Data, "m_ModelName", modelname, 128);
        PrecacheModel(modelname,true);
        new Float:normal[3];
        GetEntPropVector(sourceEnt, Prop_Send, "m_climbableNormal", normal);
        new entity = CreateEntityByName("func_simpleladder");
        if (entity == -1)
        {
            PrintToChat(client, "Failed to create ladder.");
            return Plugin_Handled;
        }
        DispatchKeyValue(entity, "model", modelname);
        Format(buf, sizeof(buf), "%.6f", normal[2]);
        DispatchKeyValue(entity, "normal.z", buf);
        Format(buf, sizeof(buf), "%.6f", normal[1]);
        DispatchKeyValue(entity, "normal.y", buf);
        Format(buf, sizeof(buf), "%.6f", normal[0]);
        DispatchKeyValue(entity, "normal.x", buf);
        DispatchKeyValue(entity, "team", "2");
        DispatchKeyValue(entity, "origin", "50 0 0");

        DispatchSpawn(entity);
        selectedLadder[client] = entity;
        decl String:key[8];
        IntToString(entity, key, 8);
        SetTrieValue(hLadders, key, sourceEnt, true);
        PrintToChat(client, "Cloned ladder entity %i. New entity %i", sourceEnt, entity);
    }
    else {
        PrintToChat(client, "No ladder selected.");
    }
    return Plugin_Handled;
}

public Action Command_Select(int client, int args)
{
    decl String:modelname[128];
    new String:classname[MAX_STR_LEN];
    new entity = GetClientAimTarget(client, false);
    if (IsValidEntity(entity)) {
        GetEntityClassname(entity, classname, MAX_STR_LEN);
        if (StrEqual(classname, "func_simpleladder", false)) {
            GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, 128);
            selectedLadder[client] = entity;
            new Float:normal[3];
            new Float:origin[3];
            new Float:position[3];
            decl Float:mins[3], Float:maxs[3];
            GetEntPropVector(entity, Prop_Send, "m_climbableNormal", normal);
            GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
            GetEntPropVector(entity,Prop_Send,"m_vecMins",mins);
            GetEntPropVector(entity,Prop_Send,"m_vecMaxs",maxs);
            position[0] = origin[0] + (mins[0] + maxs[0]) * 0.5;
            position[1] = origin[1] + (mins[1] + maxs[1]) * 0.5;
            position[2] = origin[1] + (mins[2] + maxs[2]) * 0.5;
            PrintToChat(client, "Selected ladder entity %i, %s at (%.2f,%.2f,%.2f). origin: (%.2f,%.2f,%.2f). normal: (%.2f,%.2f,%.2f)", entity, modelname, position[0], position[1], position[2], origin[0], origin[1], origin[2], normal[0], normal[1], normal[2]);
        }
        else {
            selectedLadder[client] = -1;
            PrintToChat(client, "Not looking at a ladder. Entity %i, classname: %s", entity, classname);
        }
    }
    else {
        selectedLadder[client] = -1;
        PrintToChat(client, "Looking at invalid entity %i", entity);
    }
    return Plugin_Handled;
}