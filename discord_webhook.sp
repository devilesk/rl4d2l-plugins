#pragma semicolon 1

#include <sourcemod>
#include <discord_webhook>
#include <SteamWorks>

#define CONBUFSIZELARGE         (1 << 12)       // 4k

public Plugin:myinfo =
{
    name = "Discord Webhook",
    author = "devilesk",
    version = "1.0.0",
    description = "Discord webhook functions.",
    url = "https://steamcommunity.com/groups/RL4D2L"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
    RegPluginLibrary("discord_webhook");
    
    CreateNative("FormatEmbed", Native_FormatEmbed);
    CreateNative("FormatEmbed2", Native_FormatEmbed2);
    CreateNative("FormatEmbedRequest", Native_FormatEmbedRequest);
    CreateNative("SendEmbedToDiscord", Native_SendEmbedToDiscord);
    CreateNative("SendMessageToDiscord", Native_SendMessageToDiscord);
    CreateNative("SendToDiscord", Native_SendToDiscord);
    
    return APLRes_Success;
}

public Native_FormatEmbed(Handle:plugin, numParams)
{
    int bufferLen = GetNativeCell(2);
    if (bufferLen < 1) { return; }

    new String:buffer[bufferLen+1];

    new len;

    GetNativeStringLength(3, len);
    new String:title[len+1];
    GetNativeString(3, title, len+1);

    GetNativeStringLength(4, len);
    new String:description[len+1];
    GetNativeString(4, description, len+1);

    GetNativeStringLength(5, len);
    new String:url[len+1];
    GetNativeString(5, url, len+1);
    
    int color = GetNativeCell(6);
    
    char fields[CONBUFSIZELARGE];
    char name[256];
    char value[256];
    new inline;
    
    for (int i = 7; i <= numParams; i+=3)
    {
        // field name
        GetNativeStringLength(i, len);
        if (len <= 0) { return; }
        GetNativeString(i, name, len+1);
        
        // field value
        GetNativeStringLength(i+1, len);
        if (len <= 0) { return; }
        GetNativeString(i+1, value, len+1);
        
        inline = GetNativeCellRef(i+2);
        
        if (i == 7)
        {
            Format(fields, CONBUFSIZELARGE, "{\"name\":\"%s\",\"value\":\"%s\",\"inline\":%d}", name, value, inline);
        }
        else
        {
            Format(fields, CONBUFSIZELARGE, "%s,{\"name\":\"%s\",\"value\":\"%s\",\"inline\":%d}", fields, name, value, inline);
        }
    }

    InternalFormatEmbed(buffer, bufferLen, title, description, url, color, fields);
    
    SetNativeString(1, buffer, bufferLen+1, false);
}

public Native_FormatEmbed2(Handle:plugin, numParams)
{
    int bufferLen = GetNativeCell(2);
    if (bufferLen < 1) { return; }

    new String:buffer[bufferLen+1];

    new len;

    GetNativeStringLength(3, len);
    new String:title[len+1];
    GetNativeString(3, title, len+1);

    GetNativeStringLength(4, len);
    new String:description[len+1];
    GetNativeString(4, description, len+1);

    GetNativeStringLength(5, len);
    new String:url[len+1];
    GetNativeString(5, url, len+1);
    
    int color = GetNativeCell(6);

    GetNativeStringLength(7, len);
    new String:fields[len+1];
    GetNativeString(7, fields, len+1);

    InternalFormatEmbed(buffer, bufferLen+1, title, description, url, color, fields);
    SetNativeString(1, buffer, bufferLen+1, false);
}

public Native_FormatEmbedRequest(Handle:plugin, numParams)
{
    int bufferLen = GetNativeCell(2);
    if (bufferLen < 1) { return; }
    
    new String:buffer[bufferLen+1];
    
    new len;

    GetNativeStringLength(3, len);
    if (len <= 0) { return; }
    new String:message[len+1];
    GetNativeString(3, message, len+1);

    InternalFormatEmbedRequest(buffer, bufferLen+1, message);
    
    SetNativeString(1, buffer, bufferLen+1, false);
}

public Native_SendEmbedToDiscord(Handle:plugin, numParams)
{
    new len;
    
    GetNativeStringLength(1, len);
    if (len <= 0) { return; }
    new String:webhook[len+1];
    GetNativeString(1, webhook, len+1);

    GetNativeStringLength(2, len);
    new String:title[len+1];
    GetNativeString(2, title, len+1);

    GetNativeStringLength(3, len);
    new String:description[len+1];
    GetNativeString(3, description, len+1);

    GetNativeStringLength(4, len);
    new String:url[len+1];
    GetNativeString(4, url, len+1);
    
    int color = GetNativeCell(5);
    
    char fields[CONBUFSIZELARGE];
    char name[256];
    char value[256];
    new inline;
    
    for (int i = 6; i <= numParams; i+=3)
    {
        // field name
        GetNativeStringLength(i, len);
        if (len <= 0) { return; }
        GetNativeString(i, name, len+1);
        
        // field value
        GetNativeStringLength(i+1, len);
        if (len <= 0) { return; }
        GetNativeString(i+1, value, len+1);
        
        inline = GetNativeCellRef(i+2);
        
        if (i == 6)
        {
            Format(fields, CONBUFSIZELARGE, "{\"name\":\"%s\",\"value\":\"%s\",\"inline\":%d}", name, value, inline);
        }
        else
        {
            Format(fields, CONBUFSIZELARGE, "%s,{\"name\":\"%s\",\"value\":\"%s\",\"inline\":%d}", fields, name, value, inline);
        }
    }

    InternalSendEmbedToDiscord(webhook, title, description, url, color, fields);
}

public Native_SendMessageToDiscord(Handle:plugin, numParams)
{
    new len;
    
    GetNativeStringLength(1, len);
    if (len <= 0) { return; }
    new String:webhook[len+1];
    GetNativeString(1, webhook, len+1);

    GetNativeStringLength(2, len);
    if (len <= 0) { return; }
    new String:message[len+1];
    GetNativeString(2, message, len+1);

    InternalSendMessageToDiscord(webhook, message);
}

public Native_SendToDiscord(Handle:plugin, numParams)
{
    new len;
    
    GetNativeStringLength(1, len);
    if (len <= 0) { return; }
    new String:webhook[len+1];
    GetNativeString(1, webhook, len+1);

    GetNativeStringLength(2, len);
    if (len <= 0) { return; }
    new String:message[len+1];
    GetNativeString(2, message, len+1);

    InternalSendToDiscord(webhook, message);
}

InternalFormatEmbed(char[] buffer, bufferLen, const String:title[], const String:description[], const String:url[], color, const String:fields[])
{
    Format(buffer, bufferLen, "{\"title\":\"%s\",\"description\":\"%s\",\"url\":\"%s\",\"color\": %d,\"fields\": [%s]}", title, description, url, color, fields);
}

InternalFormatEmbedRequest(char[] buffer, bufferLen, const String:sMessage[])
{
    Format(buffer, bufferLen, "{\"embeds\": [%s]}", sMessage);
}

InternalSendEmbedToDiscord(const String:sWebhook[], const String:title[], const String:description[], const String:url[], color, const String:fields[]) {
    char sMessage[CONBUFSIZELARGE];
    InternalFormatEmbed(sMessage, sizeof(sMessage), title, description, url, color, fields);
    InternalFormatEmbedRequest(sMessage, sizeof(sMessage), sMessage);
    InternalSendToDiscord(sWebhook, sMessage);
}

public void InternalSendMessageToDiscord(const char[] sWebhook, const char[] message) {
    char sMessage[4096];
    Format(sMessage, sizeof(sMessage), "{\"content\":\"%s\"}", message);
    InternalSendToDiscord(sWebhook, sMessage);
}

public void InternalSendToDiscord(const char[] sWebhook, const char[] message) {
    char sUrl[512];
    if(!GetWebHook(sWebhook, sUrl, sizeof(sUrl)))
    {
        LogError("Error: Webhook: %s - Url: %s", sWebhook, sUrl);
        return;
    }

    Handle request = SteamWorks_CreateHTTPRequest(k_EHTTPMethodPOST, sUrl);

    //SteamWorks_SetHTTPRequestGetOrPostParameter(request, "content", message);
    //SteamWorks_SetHTTPRequestHeaderValue(request, "Content-Type", "application/x-www-form-urlencoded");

    //char sMessage[4096];
    //Format(sMessage, sizeof(sMessage), "{\"content\":\"%s\"}", message);
    //Format(sMessage, sizeof(sMessage), "{\"embeds\": [{\"title\": \"Hello!\",\"description\": \"%s\"}]}", message);
    SteamWorks_SetHTTPRequestRawPostBody(request, "application/json", message, strlen(message));
    LogMessage("%s", message);
    
    if(request == null || !SteamWorks_SetHTTPCallbacks(request, Discord_Callback) || !SteamWorks_SendHTTPRequest(request)) {
        PrintToServer("[SendToSlack] SendToDiscord failed to fire");
        delete request;
    }
}

public Discord_Callback(Handle hRequest, bool bFailure, bool bRequestSuccessful, EHTTPStatusCode eStatusCode) {
    if(!bFailure && bRequestSuccessful) {
        switch (eStatusCode) {
            case 200:{
                //all gud
            }
            default: {
                PrintToServer("[Send To Discord] failed with code [%i]", eStatusCode);
                SteamWorks_GetHTTPResponseBodyCallback(hRequest, Print_Response);
            }
        }
    }
    delete hRequest;
}

public Print_Response(const char[] sData)
{
    PrintToServer("[Print_Response] %s", sData);
}

bool GetWebHook(const char[] sWebhook, char[] sUrl, int iLength)
{
    KeyValues kv = new KeyValues("Discord");

    char sFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sFile, sizeof(sFile), "configs/discord_webhook.cfg");

    if (!FileExists(sFile))
    {
        SetFailState("[GetWebHook] \"%s\" not found!", sFile);
        return false;
    }

    kv.ImportFromFile(sFile);

    if (!kv.GotoFirstSubKey())
    {
        SetFailState("[GetWebHook] Can't find webhook for \"%s\"!", sFile);
        return false;
    }

    char sBuffer[64];

    do
    {
        kv.GetSectionName(sBuffer, sizeof(sBuffer));

        if(StrEqual(sBuffer, sWebhook, false))
    {
        kv.GetString("url", sUrl, iLength);
        delete kv;
        return true;
    }
    }
    while (kv.GotoNextKey());

    delete kv;

    return false;
}