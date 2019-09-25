## l4d2_playstats.sp

* Source code broken up into multiple files.
* More stats tracked.
* Adds logging to database.
  * Add a "l4d2_playstats" configuration to databases.cfg.
* Executes system command after last stats of the match have been logged.
  * Requires [system2](https://forums.alliedmods.net/showthread.php?t=146019) extension.
  * Create a `addons/sourcemod/configs/l4d2_playstats.cfg`.
    ```
    "l4d2_playstats.cfg"
    {
        "match_end_script_cmd"	"ls /home"
    }
    ```
  
## teleport_tank.sp

* Tank teleport vote plugin.
* Adds sm_teleporttank and sm_teleporttankto <x> <y> <z> commands.
* Adds `sm_teleport_tank_debug` cvar for logging.

## spawn_secondary.sp

* Spawn pistol and axe for survivors plugin.
* Adds `sm_spawnsecondary`, `sm_spawnaxe`, and `sm_spawnpistol` commands.
* Intended to be used when missing starting axes.

## discord_webhook.sp

* Plugin library for making discord webhook requests.
* Requires [SteamWorks](https://forums.alliedmods.net/showthread.php?t=229556) extension.
* Create a `addons/sourcemod/configs/discord_webhook.cfg`.
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

* End of round scores reported to discord via webhook.
* Requires discord_webhook plugin.
  * Add `discord_scoreboard` entry to `discord_webhook.cfg`.

## l4d\_tank_damage\_announce.sp

* Added discord_scoreboard plugin integration.
* Requires discord_scoreboard plugin.
* Fixed bug in damage to tank percent fudging by removing it.

## tank\_and\_nowitch\_ifier.sp

* Fixed AdjustBossFlow to properly use boss ban flow min and max.
* Added `sm_tank_nowitch_debug` cvar for logging.
* Added `sm_tank_nowitch_debug_info` command for dumping info on current spawn configuration.
  * Requires `sm_tank_nowitch_debug` set to 1.

## l4d2\_horde\_equaliser.sp

* Fixed infinite hordes for horde sizes below 120.

## suicideblitzfinalefix.sp

* Modified ProdigySim's [spawnstatefix](https://gist.github.com/ProdigySim/04912e5e76f69027f8c4) plugin to autofix Suicide Blitz 2 finale.

## player_skill_stats.sp

* Psykotikism's [player skill stats](https://github.com/Psykotikism/Player_Skill_Stats) modified by bscal to save to database.
* No longer in use and replaced by modified l4d2_playstats plugin.

## eq_finale_tanks.sp

* Modified Visor's [EQ2 Finale Manager](https://github.com/Attano/L4D2-Competitive-Framework/blob/master/addons/sourcemod/scripting/eq_finale_tanks.sp).
  Reworked to no longer manage flow tanks, since that can be handled by the `static_tank_map` cvar used in the [tank\_and\_nowitch\_ifier](https://github.com/devilesk/rl4d2l-plugins/blob/master/tank_and_nowitch_ifier.sp) plugin. Cvars:
  * `tank_map_only_second_event` (formerly `tank_map_flow_and_second_event`)
  * `tank_map_only_first_event` (unchanged)
* Added `sm_tank_map_debug` cvar for logging.
* Updated to handle tanks on gauntlet finales.
  * `bridge_escape_fix.smx` no longer needed.

## l4d2_restartmap.sp

* Adds sm_restartmap to restart the current map. Preserves scores and who has played tank. Automatically restarts map when broken flow detected.
  * `sm_restartmap_debug` cvar for logging.
  * `sm_restartmap_autofix` cvar for autofix. Enabled by default.
  * `sm_restartmap_autofix_max_tries` cvar for max autofix map restart attempts.
* Score setting based on Visor's [SetScores](https://github.com/Attano/L4D2-Competitive-Framework/blob/master/addons/sourcemod/scripting/l4d2_setscores.sp).

## l4d_tank_control_eq.sp
* Modified arti's [L4D2 Tank Control](https://github.com/alexberriman/l4d2-plugins/blob/master/l4d_tank_control/l4d_tank_control.sp).
  * Merged with SirPlease's changes from decompiled [ZoneMod version](https://github.com/SirPlease/ZoneMod/blob/master/addons/sourcemod/plugins/optional/zonemod/l4d_tank_control_eq.smx).
* Fixed handle leaks.
* Added commands for viewing and modifying the pool of players who have not played tank:
  * `sm_tankpool` displays the tank pool.
  * `sm_addtankpool`, `sm_queuetank` adds a player to the tank pool.
  * `sm_removetankpool`, `sm_dequeuetank` removes a player from the tank pool.
* Added natives:
  * `TankControlEQ_SetTank`
  * `TankControlEQ_GetWhosHadTank`
  * `TankControlEQ_ClearWhosHadTank`
  * `TankControlEQ_GetTankPool`
* Added forwards:
  * `TankControlEQ_OnChooseTank` called whenever a tank is chosen from the tank pool.
    * Return `Plugin_Continue` to continue with default tank choosing process.
    * Return `Plugin_Handled` to block the default tank choosing process.
  * `TankControlEQ_OnTankGiven` called when player has been given control of the tank.
    * Called with Steam ID of tank player.
  * `TankControlEQ_OnTankControlReset` called when new game detected and pools are reset.

## readyup.sp
* Reconstructed SirPlease's version of CanadaRox's [readyup](https://github.com/MatthewClair/l4d2readyup/blob/master/readyup.sp) plugin used in [ZoneMod 1.9.3](https://github.com/SirPlease/ZoneMod/blob/master/addons/sourcemod/plugins/optional/zonemod/readyup.smx).
* Applied spoon's [bugfix](https://github.com/spoon-l4d2/Plugins/blob/19b55c3c3122333bba0ce2e2cec202b4af623cab/source/readyup.sp#L1409) to prevent unbreakable doors from being made breakable.

## l4d_stuckzombiemeleefix.sp
* Minor edit to AtomicStryker's [Stuck Zombie Melee Fix](http://forums.alliedmods.net/showthread.php?p=932416) to use recommended datapack timer practices described in the wiki and eliminate possible handle leak.

## l4d2_getupfix.sp
* Minor edit to [L4D2 Get-Up Fix](https://github.com/Attano/L4D2-Competitive-Framework/blob/master/addons/sourcemod/scripting/l4d2_getupfix.sp) to use datapack instead of stack and use recommended datapack timer practices described in the wiki and eliminate possible handle leak.

## l4d2_sound_manipulation.sp
* Updated [Sound Manipulation](https://github.com/SirPlease/L4D2-Competitive-Rework/blob/master/addons/sourcemod/scripting/l4d2_sound_manipulation.sp) to allow for more control over which sounds are blocked by using `sound_block_for_comp` to set flags.
  * Block flags: 1 - World, 2 - Look, 4 - Ask, 8 - Follow Me, 16 - Getting Revived, 32 - Give Item Alert, 64 - I'm With You, 128 - Laughter, 256 - Name, 512 - Lead On, 1024 - Move On, 2048 - Friendly Fire, 4096 - Splat.
  * Block default: 8190 (allow world).
  * Block all: 8191.
  
## l4d_tank_rush.sp
* Added cvar `l4d_no_tank_rush_debug` to [L4D2 No Tank Rush](https://github.com/Attano/L4D2-Competitive-Framework/blob/master/addons/sourcemod/scripting/l4d_tank_rush.sp) for debug logging.

## static_tank_control.sp
* Requires l4d_tank_control_eq plugin and overrides its tank selection process with a predetermined one.
* Adds `static_tank_control` server command to specify if a given player should play a given tank on a given map.
  * Usage: `static_tank_control <tank_number> <map_name> [steam_id...]`
    * `tank_number` 1 or 2 representing which tank spawn to apply to.
    * `map_name` the map id to apply to.
    * `steam_id` any number of steam ids. The first player that is currently infected will be given the tank.
  * Example:
    ```
    static_tank_control 1 c1m1_hotel "STEAM_1:1:TEAMA_PLAYER1" "STEAM_1:1:TEAMB_PLAYER1"
    static_tank_control 1 c1m2_streets "STEAM_1:1:TEAMA_PLAYER2" "STEAM_1:1:TEAMB_PLAYER2"
    static_tank_control 1 c1m3_mall "STEAM_1:1:TEAMA_PLAYER3" "STEAM_1:1:TEAMB_PLAYER3"
    static_tank_control 1 c1m4_atrium "STEAM_1:1:TEAMA_PLAYER4" "STEAM_1:1:TEAMB_PLAYER4"
    static_tank_control 2 c1m4_atrium "STEAM_1:1:TEAMA_PLAYER1" "STEAM_1:1:TEAMB_PLAYER1"
    ```

## tankdoorfix.sp
* Minor edit to Dr. Greg House's [TankDoorFix](https://forums.alliedmods.net/showthread.php?t=225087) to fix `Array index is out of bounds` error.

## l4d2_getup_slide_fix.sp
* Updated [Stagger Blocker](https://raw.githubusercontent.com/Attano/L4D2-Competitive-Framework/master/addons/sourcemod/scripting/l4d2_getup_slide_fix.sp) to check for valid infected attacker.