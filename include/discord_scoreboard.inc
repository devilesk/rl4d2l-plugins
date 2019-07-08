#if defined _discord_scoreboard_included_
  #endinput
#endif
#define _discord_scoreboard_included_

native void AddEmbed(const String:title[], const String:description[], const String:url[], color, any ... );

public SharedPlugin __pl_discord_scoreboard = 
{
    name = "discord_scoreboard",
    file = "discord_scoreboard.smx",
#if defined REQUIRE_PLUGIN
    required = 1,
#else
    required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_discord_scoreboard_SetNTVOptional()
{
    MarkNativeAsOptional("AddEmbed");
}
#endif