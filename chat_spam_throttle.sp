#pragma semicolon 1

#define MAXMSGLEN       192

new Handle:g_hCvarDebug = INVALID_HANDLE;
new Handle:g_hCvarExpireTime = INVALID_HANDLE;
new Handle:g_hCvarCheckSender = INVALID_HANDLE;
new Handle:g_hMsgTime = INVALID_HANDLE;
new Handle:g_hMsgSender = INVALID_HANDLE;
new Handle:g_hMsgText = INVALID_HANDLE;
new g_iMsgCount = 0;

public Plugin:myinfo = {
    name = "Chat Spam Throttle",
    author = "devilesk",
    description = "Chat filter to prevent spamming the same message too often.",
    version = "0.1.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
}

public OnPluginStart() {
    g_hCvarDebug = CreateConVar("chat_spam_throttle_debug", "0", "Chat Spam Throttle debug mode", FCVAR_PLUGIN, true, 0.0, true, 1.0);
    g_hCvarExpireTime = CreateConVar("chat_spam_throttle_time", "20", "Time in seconds before a message can be repeated.", FCVAR_PLUGIN);
    g_hCvarCheckSender = CreateConVar("chat_spam_throttle_check_sender", "1", "Allow repeating messages sent by someone else.", FCVAR_PLUGIN);
    g_hMsgTime = CreateArray(32);
    g_hMsgSender = CreateArray(32);
    g_hMsgText = CreateArray(MAXMSGLEN);
}

public OnMapStart() {
    ClearArray(g_hMsgTime);
    ClearArray(g_hMsgSender);
    ClearArray(g_hMsgText);
    g_iMsgCount = 0;
}

public Action:OnClientSayCommand(client, const String:command[], const String:args[]) {
    decl String:message[MAXMSGLEN];
    PrintDebug("[OnClientSayCommand] command: %s, args: %s", command, args);
    if (args[0] == '!' || args[0] == '/') return Plugin_Continue;
    strcopy(message, MAXMSGLEN, args);
    FilterMessage(message);
    if(FindMessage(client, message) != -1) {
        PrintToChat(client, "You are sending that message too often.");
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public FindMessage(client, const String:message[]) {
    new expireTime = GetTime() - GetConVarInt(g_hCvarExpireTime);
    new bool:bCheckSender = GetConVarBool(g_hCvarCheckSender);
    decl String:msg[MAXMSGLEN];
    for (new i = g_iMsgCount - 1; i >= 0; i--) {
        if (GetArrayCell(g_hMsgTime, i) < expireTime) {
            UntrackMessage(i);
            continue;
        }
        if (bCheckSender && client != GetArrayCell(g_hMsgSender, i)) continue;
        GetArrayString(g_hMsgText, i, msg, sizeof(msg));
        if (!StrEqual(message, msg, false)) continue;
        PrintDebug("[FindMessage] match %s, %s", message, msg);
        return i;
    }
    PrintDebug("[FindMessage] no match %s, %s", message, msg);
    TrackMessage(client, message);
    return -1;
}

public UntrackMessage(index) {
    RemoveFromArray(g_hMsgTime, index);
    RemoveFromArray(g_hMsgSender, index);
    RemoveFromArray(g_hMsgText, index);
    g_iMsgCount--;
}

public TrackMessage(client, const String:message[]) {
    PushArrayCell(g_hMsgTime, GetTime());
    PushArrayCell(g_hMsgSender, client);
    PushArrayString(g_hMsgText, message);
    g_iMsgCount++;
}

// Based on Unicode Name Filter https://forums.alliedmods.net/showthread.php?p=2207177?p=2207177
public FilterMessage(String:message[]) {
    TrimString(message);

    new charMax = strlen(message);
    new charIndex;
    new copyPos = 0;

    new String:strippedString[MAXMSGLEN];

    for (charIndex = 0; charIndex < charMax; charIndex++) {
        // Reach end of string. Break.
        if (message[copyPos] == 0) {
            strippedString[copyPos] = 0;
            break;
        }

        if (GetCharBytes(message[charIndex]) > 1) continue;

        if (IsAlphaNumeric(message[charIndex]) || IsCharSpace(message[charIndex])) {
            strippedString[copyPos] = message[charIndex];
            copyPos++;
            continue;
        }
    }

    // Copy back to passing parameter.
    strcopy(message, MAXMSGLEN, strippedString);
    
    PrintDebug("[FilterMessage] message: %s", message);
}

public bool:IsAlphaNumeric(characterNum) {
    return ((characterNum >= 48 && characterNum <= 57)
        ||  (characterNum >= 65 && characterNum <= 90)
        ||  (characterNum >= 97 && characterNum <= 122));
}

stock PrintDebug(const String:Message[], any:...) {
    if (GetConVarBool(g_hCvarDebug)) {
        decl String:DebugBuff[256];
        VFormat(DebugBuff, sizeof(DebugBuff), Message, 2);
        LogMessage(DebugBuff);
    }
}