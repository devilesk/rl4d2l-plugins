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

## l4d2\_horde\_equaliser.sp

* Fixed infinite hordes for horde sizes below 120.

## suicideblitzfinalefix.sp

* Modified ProdigySim's [spawnstatefix](https://gist.github.com/ProdigySim/04912e5e76f69027f8c4) plugin to autofix Suicide Blitz 2 finale.
