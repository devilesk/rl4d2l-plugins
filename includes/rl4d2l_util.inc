#if defined _rl4d2l_util_
  #endinput
#endif
#define _rl4d2l_util_

stock StrToLower(String:arg[]) {
    for (new i = 0; i < strlen(arg); i++) {
        arg[i] = CharToLower(arg[i]);
    }
}

stock GetCurrentMapLower(String:buffer[], buflen) {
    new iBytesWritten = GetCurrentMap(buffer, buflen);
    StrToLower(buffer);
    return iBytesWritten;
}