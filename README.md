## l4d2_playstats.sp

* Source code broken up into multiple files
* More stats tracked
* Adds logging to database
  * Add a "l4d2_playstats" configuration to databases.cfg
* Executes system command after last stats of the match have been logged.
  * Requires [system2](https://forums.alliedmods.net/showthread.php?t=146019) extension
  * Create a `addons/sourcemod/configs/l4d2_playstats.cfg`
  ```
  "l4d2_playstats.cfg"
  {
    "match_end_script_cmd"	"ls /home"
  }
  ```
  
## teleport_tank.sp

* Tank teleport vote plugin.
* Adds sm_teleporttank and sm_teleporttankto <x> <y> <z> commands
* Adds `sm_teleport_tank_debug` cvar for logging

## spawn_secondary.sp

* Spawn pistol and axe for survivors plugin
* Adds sm_spawnsecondary command
* Intended to be used when missing starting axes.

## discord_webhook.sp

* Plugin library for making discord webhook requests
* Requires [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556) extension
* Create a `addons/sourcemod/configs/discord_webhook.cfg`
```
"Discord"
{
	"discord_test"
	{
		"url"	"<webhook_url>"
	}
}
```

## discord_scoreboard.sp

* End of round scores reported to discord via webhook
* Requires discord_webhook plugin
  * Add `discord_scoreboard` entry to `discord_webhook.cfg`

## l4d\_tank_damage\_announce.sp

* Added discord_scoreboard plugin integration
* Requires discord_scoreboard plugin
* Fixed bug in damage to tank percent fudging by removing it

## tank\_and\_nowitch\_ifier.sp

* Fixed AdjustBossFlow to properly use boss ban flow min and max
* Added `sm_tank_nowitch_debug` cvar for logging
* Added `sm_tank_nowitch_debug_info` command for dumping info on current spawn configuration
  * Requires `sm_tank_nowitch_debug` set to 1

## l4d2\_horde\_equaliser.sp

* Fixed infinite hordes for horde sizes below 120.

## suicideblitzfinalefix.sp

* Modified ProdigySim's [spawnstatefix](https://gist.github.com/ProdigySim/04912e5e76f69027f8c4) plugin to autofix Suicide Blitz 2 finale.

## player_skill_stats.sp

* Psykotikism's [player skill stats](https://github.com/Psykotikism/Player_Skill_Stats) modified by bscal to save to database. No longer in use and replaced by modified l4d2_playstats plugin.

## eq_finale_tanks.sp

* Modified Visor's [EQ2 Finale Manager](https://github.com/Attano/L4D2-Competitive-Framework/blob/master/addons/sourcemod/scripting/eq_finale_tanks.sp).
  Reworked to no longer manage flow tanks, since that can be handled by the `static_tank_map` cvar used in the [tank\_and\_nowitch\_ifier](https://github.com/devilesk/rl4d2l-plugins/blob/master/tank_and_nowitch_ifier.sp) plugin. Cvars:
  * `tank_map_only_second_event` (formerly `tank_map_flow_and_second_event`)
  * `tank_map_only_first_event` (unchanged)
* Added `sm_tank_map_debug` cvar for logging
* Updated to handle tanks on gauntlet finales.
  * `bridge_escape_fix.smx` no longer needed.

## l4d2_restartmap.sp

* Adds sm_restartmap to restart the current map. Preserves scores and who has played tank. Automatically restarts map when broken flow detected.
  * `sm_restartmap_debug` cvar for logging
  * `sm_restartmap_autofix` cvar for autofix. Enabled by default.
  * `sm_restartmap_autofix_max_tries` cvar for max autofix map restart attempts
* Score setting based on Visor's [SetScores](https://github.com/Attano/L4D2-Competitive-Framework/blob/master/addons/sourcemod/scripting/l4d2_setscores.sp)

## l4d_tank_control_eq.sp
* Modified arti's [L4D2 Tank Control](https://github.com/alexberriman/l4d2-plugins/blob/master/l4d_tank_control/l4d_tank_control.sp)
  * Merged with SirPlease's changes from decompiled [ZoneMod version](https://github.com/SirPlease/ZoneMod/blob/master/addons/sourcemod/plugins/optional/zonemod/l4d_tank_control_eq.smx)
* Fixed handle leaks

## readyup.sp
* Reconstructed SirPlease's version of CanadaRox's [readyup](https://github.com/MatthewClair/l4d2readyup/blob/master/readyup.sp) plugin used in [ZoneMod 1.9.3](https://github.com/SirPlease/ZoneMod/blob/master/addons/sourcemod/plugins/optional/zonemod/readyup.smx)
* Applied spoon's [bugfix](https://github.com/spoon-l4d2/Plugins/blob/19b55c3c3122333bba0ce2e2cec202b4af623cab/source/readyup.sp#L1409) to prevent unbreakable doors from being made breakable.