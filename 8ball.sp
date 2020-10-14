#pragma semicolon 1

#include <sourcemod> 
#include <colors>  

#pragma newdecls required

#define MAXMSG              192

Handle hAnswers = INVALID_HANDLE;

public Plugin myinfo = {
    name = "8Ball",
    description = "Simple 8Ball Game Plugin. Works the same as Coinflip / Dice Roll.",
    author = "spoon, devilesk",
    version = "1.4.0",
    url = "https://github.com/devilesk/rl4d2l-plugins"
};

public void OnPluginStart() {
    RegConsoleCmd("sm_8ball", Command_8ball);
    
    Handle hAnswersFile = INVALID_HANDLE;
    char sFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sFile, sizeof(sFile), "configs/8ball.ini");
    
    hAnswersFile = OpenFile(sFile, "r");
    
    if (hAnswersFile == INVALID_HANDLE) {
        SetFailState("[OnPluginStart] \"%s\" not found!", sFile);
        return;
    }
    
    if (hAnswers == INVALID_HANDLE)
        hAnswers = CreateArray(MAXMSG);
    
    char sBuffer[MAXMSG];
    while(ReadFileLine(hAnswersFile, sBuffer, sizeof(sBuffer))) {
        TrimString(sBuffer);
        if((StrContains(sBuffer, "//") == -1) && (!StrEqual(sBuffer, ""))) {
            PushArrayString(hAnswers, sBuffer);
        }
    }
    CloseHandle(hAnswersFile);
}

public Action Command_8ball(int client, int args) {
    if (args == 0) {
        CPrintToChat(client, "{default}[{green}8Ball{default}] Usage: !8ball <question>");
        return;
    }
    else {
        char question[MAXMSG];
        char answer[MAXMSG];
        char client_name[32];

        GetClientName(client, client_name, 32);

        GetCmdArgString(question, sizeof(question));
        StripQuotes(question);

        PrintToChatAll("\x01[\x048Ball\x01] \x03%s\x01 Asked: \x05%s\x01", client_name, question[0]);

        int maxIndex = GetArraySize(hAnswers) - 1;
        int rndIndex = Math_GetRandomInt(0, maxIndex);
        GetArrayString(hAnswers, rndIndex, answer, sizeof(answer));
        CPrintToChatAll(answer);
    }
}

#define SIZE_OF_INT         2147483647 // without 0
stock int Math_GetRandomInt(int min, int max)
{
    int random = GetURandomInt();

    if (random == 0) {
        random++;
    }

    return RoundToCeil(float(random) / (float(SIZE_OF_INT) / float(max - min + 1))) + min - 1;
}