#define IS_VALID_CLIENT(%1)     (%1 > 0 && %1 <= MaxClients)
#define IS_SURVIVOR(%1)         (GetClientTeam(%1) == 2)
#define IS_INFECTED(%1)         (GetClientTeam(%1) == 3)
#define IS_VALID_INGAME(%1)     (IS_VALID_CLIENT(%1) && IsClientInGame(%1))
#define IS_VALID_SURVIVOR(%1)   (IS_VALID_INGAME(%1) && IS_SURVIVOR(%1))
#define IS_VALID_INFECTED(%1)   (IS_VALID_INGAME(%1) && IS_INFECTED(%1))
#define IS_SURVIVOR_ALIVE(%1)   (IS_VALID_SURVIVOR(%1) && IsPlayerAlive(%1))
#define IS_INFECTED_ALIVE(%1)   (IS_VALID_INFECTED(%1) && IsPlayerAlive(%1))

#define TEAM_SPECTATOR          1
#define TEAM_SURVIVOR           2
#define TEAM_INFECTED           3

#define ZC_SMOKER               1
#define ZC_BOOMER               2
#define ZC_HUNTER               3
#define ZC_SPITTER              4
#define ZC_JOCKEY               5
#define ZC_CHARGER              6
#define ZC_WITCH                7
#define ZC_TANK                 8
#define ZC_NOTINFECTED          9
#define ZC_TOTAL                7

#define CONBUFSIZE              (1 << 10)       // 1k
#define CONBUFSIZELARGE         (1 << 12)       // 4k
#define MAXCHUNKS               10              // how many chunks of 4k max
#define CHARTHRESHOLD           160             // detecting unicode stuff
#define MAXLINESPERCHUNK        4               // how many lines in a chunk
#define DIVIDERINTERVAL         4               // add divider line every X lines

#define MAXTRACKED              64
#define MAXROUNDS               48              // ridiculously high, but just in case players do a marathon or something
#define MAXSHOWROUNDS           10              // how many rounds to show in the general stats table, max

#define MAXNAME                 64
#define MAXNAME_TABLE           20              // name size max in console tables
#define MAXCHARACTERS           4
#define MAXMAP                  32
#define MAXGAME                 24
#define MAXWEAPNAME             24

#define STUMBLE_DMG_THRESH      3               // smaller than this is stumble damage (for chargers)

#define STATS_RESET_DELAY       5.0
#define ROUNDSTART_DELAY        5.5             // this should always be longer than CMT's roundstart scores check, so we know whether there's been a swap! hardcoded 5.0 in there
#define ROUNDEND_SCORE_DELAY    1.0
#define ROUNDEND_DELAY          3.0
#define ROUNDEND_DELAY_SCAV     2.0
#define PRINT_REPEAT_DELAY      15              // how many seconds to wait before re-doing automatic round end prints (opening/closing end door, etc)
#define PRINT_DELAY_INC         0.1             // print delay increments (pauses between tables)
#define FREQ_FLOWCHECK          1.0

#define MIN_TEAM_PRESENT_TIME   30              // how many seconds a player with 0-stats has to have been on a team to be listed as part of that team

#define WP_MELEE                19
#define WP_PISTOL               1
#define WP_PISTOL_MAGNUM        32
#define WP_SMG                  2
#define WP_SMG_SILENCED         7
#define WP_HUNTING_RIFLE        6
#define WP_SNIPER_MILITARY      10
#define WP_PUMPSHOTGUN          3
#define WP_SHOTGUN_CHROME       8
#define WP_AUTOSHOTGUN          4
#define WP_SHOTGUN_SPAS         11
#define WP_RIFLE                5
#define WP_RIFLE_DESERT         9
#define WP_RIFLE_AK47           26
#define WP_SMG_MP5              33
#define WP_RIFLE_SG552          34
#define WP_SNIPER_AWP           35
#define WP_SNIPER_SCOUT         36
#define WP_RIFLE_M60            37
#define WP_MACHINEGUN           45

#define HITGROUP_HEAD           1

#define DMG_GENERIC             0               // generic damage was done
#define DMG_CRUSH               (1 << 0)        // crushed by falling or moving object. 
#define DMG_BULLET              (1 << 1)        // shot
#define DMG_SLASH               (1 << 2)        // cut, clawed, stabbed
#define DMG_BURN                (1 << 3)        // heat burned
#define DMG_BLAST               (1 << 6)        // explosive blast damage
#define DMG_CLUB                (1 << 7)        // crowbar, punch, headbutt
#define DMG_BUCKSHOT            (1 << 24)       // not quite a bullet. Little, rounder, different. 

#define FIRST_NON_BOT           4               // first index that doesn't belong to a survivor bot

#define TOTAL_FFGIVEN           0
#define TOTAL_FFTAKEN           1
#define FFTYPE_TOTAL            0
#define FFTYPE_PELLET           1
#define FFTYPE_BULLET           2
#define FFTYPE_SNIPER           3
#define FFTYPE_MELEE            4
#define FFTYPE_FIRE             5
#define FFTYPE_INCAP            6
#define FFTYPE_OTHER            7
#define FFTYPE_SELF             8
#define FFTYPE_MAX              9

#define SORT_SI                 0
#define SORT_CI                 1
#define SORT_FF                 2
#define SORT_INF                3
#define MAXSORTS                4

#define LTEAM_A                 0
#define LTEAM_B                 1
#define LTEAM_CURRENT           2

#define BREV_SI                 (1 << 0)        // flags for MVP chat print appearance
#define BREV_CI                 (1 << 1)
#define BREV_FF                 (1 << 2)
#define BREV_RANK               (1 << 3)        // note: 16 reserved/removed
#define BREV_PERCENT            (1 << 5)
#define BREV_ABSOLUTE           (1 << 6)

#define AUTO_MVPCHAT_ROUND      (1 << 0)        // flags for what to print automatically at round end
#define AUTO_MVPCHAT_GAME       (1 << 1)
#define AUTO_MVPCON_ROUND       (1 << 2)
#define AUTO_MVPCON_GAME        (1 << 3)
#define AUTO_MVPCON_TANK        (1 << 4)        // 16
#define AUTO_FFCON_ROUND        (1 << 5)
#define AUTO_FFCON_GAME         (1 << 6)
#define AUTO_SKILLCON_ROUND     (1 << 7)        // 128
#define AUTO_SKILLCON_GAME      (1 << 8)
#define AUTO_ACCCON_ROUND       (1 << 9)
#define AUTO_ACCCON_GAME        (1 << 10)       // 1024
#define AUTO_ACCCON_MORE_ROUND  (1 << 11)
#define AUTO_ACCCON_MORE_GAME   (1 << 12)
#define AUTO_FUNFACT_ROUND      (1 << 13)
#define AUTO_FUNFACT_GAME       (1 << 14)       // 16384
#define AUTO_MVPCON_MORE_ROUND  (1 << 15)
#define AUTO_MVPCON_MORE_GAME   (1 << 16)       
#define AUTO_INFCON_ROUND       (1 << 17)       // 131072
#define AUTO_INFCON_GAME        (1 << 18)       // 262144


// fun fact
#define FFACT_MAX_WEIGHT        10
#define FFACT_TYPE_CROWN        1
#define FFACT_TYPE_DRAWCROWN    2
#define FFACT_TYPE_SKEETS       3
#define FFACT_TYPE_MELEESKEETS  4
#define FFACT_TYPE_HUNTERDP     5
#define FFACT_TYPE_JOCKEYDP     6
#define FFACT_TYPE_M2           7
#define FFACT_TYPE_MELEETANK    8
#define FFACT_TYPE_CUT          9
#define FFACT_TYPE_POP          10
#define FFACT_TYPE_DEADSTOP     11
#define FFACT_TYPE_LEVELS       12
#define FFACT_TYPE_SCRATCH      13
#define FFACT_TYPE_DCHARGE      14
#define FFACT_TYPE_BOOMDMG      15
#define FFACT_TYPE_SPITDMG      16
#define FFACT_MAXTYPES          16

#define FFACT_MIN_CROWN         1
#define FFACT_MAX_CROWN         10
#define FFACT_MIN_DRAWCROWN     1
#define FFACT_MAX_DRAWCROWN     10
#define FFACT_MIN_SKEET         2
#define FFACT_MAX_SKEET         20
#define FFACT_MIN_MELEESKEET    1
#define FFACT_MAX_MELEESKEET    10
#define FFACT_MIN_HUNTERDP      2
#define FFACT_MAX_HUNTERDP      10
#define FFACT_MIN_JOCKEYDP      2
#define FFACT_MAX_JOCKEYDP      10
#define FFACT_MIN_M2            15
#define FFACT_MAX_M2            50
#define FFACT_MIN_MELEETANK     4
#define FFACT_MAX_MELEETANK     10
#define FFACT_MIN_CUT           4
#define FFACT_MAX_CUT           10
#define FFACT_MIN_POP           4
#define FFACT_MAX_POP           10
#define FFACT_MIN_DEADSTOP      7
#define FFACT_MAX_DEADSTOP      20
#define FFACT_MIN_LEVEL         3
#define FFACT_MAX_LEVEL         10
#define FFACT_MIN_SCRATCH       50
#define FFACT_MAX_SCRATCH       200
#define FFACT_MIN_DCHARGE       1
#define FFACT_MAX_DCHARGE       4
#define FFACT_MIN_BOOMDMG       40
#define FFACT_MAX_BOOMDMG       200
#define FFACT_MIN_SPITDMG       60
#define FFACT_MAX_SPITDMG       200


// writing
#define DIR_OUTPUT              "logs/"
#define MAX_QUERY_SIZE          8192
#define FILETABLEFLAGS          164532          // AUTO_ flags for what to print to a file automatically

#define MAX(%0,%1) (((%0) > (%1)) ? (%0) : (%1))
#define MIN(%0,%1) (((%0) < (%1)) ? (%0) : (%1))

// types of statistic table(sets)
enum strStatType {
    typGeneral,
    typMVP,
    typFF,
    typSkill,
    typAcc,
    typInf,
    typFact
};

// information for entire game
enum strGameData {
            gmFailed,				// survivors lost the mission * times
            gmStartTime				// GetTime() value when starting
};

// information per round
enum strRoundData {
            rndRestarts,				// how many times retried?
            rndPillsUsed,
            rndKitsUsed,
            rndDefibsUsed,
            rndCommon,
            rndSIKilled,
            rndSIDamage,
            rndSISpawned,
            rndWitchKilled,
            rndTankKilled,
            rndIncaps,				// 10
            rndDeaths,
            rndFFDamageTotal,
            rndStartTime,				// GetTime() value when starting    
            rndEndTime,				// GetTime() value when done
            rndStartTimePause,
            rndStopTimePause,
            rndStartTimeTank,
            rndStopTimeTank
};
#define MAXRNDSTATS                 18

// information per player
enum strPlayerData {
            plyShotsShotgun,			// 0 pellets
            plyShotsSmg,				// all bullets from smg/rifle
            plyShotsSniper,			// all bullets from snipers
            plyShotsPistol,			// all bullets from pistol/magnum
            plyHitsShotgun,
            plyHitsSmg,
            plyHitsSniper,
            plyHitsPistol,
            plyHeadshotsSmg,			// headshots for everything but on tank
            plyHeadshotsSniper,
            plyHeadshotsPistol,		// 10
            plyHeadshotsSISmg,		// headshots for SI only
            plyHeadshotsSISniper,
            plyHeadshotsSIPistol,
            plyHitsSIShotgun,			// all hits on special infected (not tank)
            plyHitsSISmg,
            plyHitsSISniper,
            plyHitsSIPistol,
            plyHitsTankShotgun,		// all hits on tank
            plyHitsTankSmg,			// useful for getting real headshot count (leave tank out of it)
            plyHitsTankSniper,		// 20
            plyHitsTankPistol,
            plyCommon,
            plyCommonTankUp,
            plySIKilled,
            plySIKilledTankUp,
            plySIDamage,
            plySIDamageTankUp,
            plyIncaps,
            plyDied,
            plySkeets,				// 30 skeets, full
            plySkeetsHurt,
            plySkeetsMelee,
            plyLevels,				// charger levels, full
            plyLevelsHurt,
            plyPops,					// boomer pops (pre puke)
            plyCrowns,
            plyCrownsHurt,			// non-full crowns 
            plyShoves,				// count every shove
            plyDeadStops,
            plyTongueCuts,			// 40 only real cuts
            plySelfClears,
            plyFallDamage,
            plyDmgTaken,
            plyDmgTakenBoom,			// damage taken from common while boomed
            plyDmgTakenCommon,		// damage taken from common
            plyDmgTakenTank,		// damage taken from tank
            plyBowls,				// bowls from charger
            plyCharges,				// charges from charger
			plyDeathCharges,			// death charge count
            plyFFGiven,
            plyFFTaken,				// 50
            plyFFHits,				// total amount of shotgun blasts / bullets / etc
            plyTankDamage,			// survivor damage to tank
            plyWitchDamage,
            plyMeleesOnTank,
            plyRockSkeets,
            plyRockEats,
            plyFFGivenPellet,
            plyFFGivenBullet,
            plyFFGivenSniper,			// 60
            plyFFGivenMelee,
            plyFFGivenFire,
            plyFFGivenIncap,
            plyFFGivenOther,
            plyFFGivenSelf,
            plyFFTakenPellet,
            plyFFTakenBullet,
            plyFFTakenSniper,
            plyFFTakenMelee,
            plyFFTakenFire,			// 70
            plyFFTakenIncap,
            plyFFTakenOther,
            plyFFGivenTotal,
            plyFFTakenTotal,
            plyCarsTriggered,
            plyJockeyRideDuration,
            plyJockeyRideTotal,
            plyClears,				// amount of clears (under a min)
            plyAvgClearTime,			// average time it takes to clear someone (* 1000 so it doesn't have to be a float)
            plyTimeStartPresent,		// 80 time present (on the team)
            plyTimeStopPresent,		// if stoptime is 0, then it's NOW, ongoing
            plyTimeStartAlive,
            plyTimeStopAlive,		// time not capped
            plyTimeStartUpright,
            plyTimeStopUpright,
            plyCurFlowDist,
            plyFarFlowDist,
            plyProtectAwards
};
#define MAXPLYSTATS                 88

// information per infected player (during other team's survivor round)
enum strInfData {
            infDmgTotal,				// including on incapped, excluding all tank damage!
            infDmgUpright,			// 1
            infDmgTank,				// only upright
            infDmgTankIncap,			// only incapped
            infDmgScratch,			// only upright
            infDmgScratchSmoker,		// only upright
            infDmgScratchBoomer,		// only upright
            infDmgScratchHunter,		// only upright
            infDmgScratchCharger,		// only upright
            infDmgScratchSpitter,		// only upright
            infDmgScratchJockey,	// 10 only upright
            infDmgSpit,				// only upright
            infDmgBoom,				// only upright
            infDmgTankUp,				// only upright, excluding the tank itself
            infHunterDPs,				// damage pounce count
            infHunterDPDmg,			// damage pounce damage
            infJockeyDPs,
            infDeathCharges,
            infCharges,
            infMultiCharges,
            infBoomsSingle,         // 20
            infBoomsDouble,
            infBoomsTriple,
            infBoomsQuad,
            infBooms,				// boomed survivors
            infBoomerPops,				// times popped as boomer
            infLedged,				// survivors ledged
            infCommon,				// common killed by SI
            infSpawns,
            infSpawnSmoker,
            infSpawnBoomer,         // 30
            infSpawnHunter,
            infSpawnCharger,
            infSpawnSpitter,
            infSpawnJockey,
            infTankPasses,
            infTankRockHits,
            infCarsTriggered,
            infJockeyRideDuration,		// in milliseconds
            infJockeyRideTotal,
            infTimeStartPresent,		// 40 time present (on the team)
            infTimeStopPresent		// if stoptime is 0, then it's NOW, ongoing
};
#define MAXINFSTATS                 41

// trie values: weapon type (per accuracy-class)
enum strWeaponType {
    WPTYPE_NONE,
    WPTYPE_SHOTGUN,
    WPTYPE_SMG,
    WPTYPE_SNIPER,
    WPTYPE_PISTOL
};

// trie values: weapon type (per accuracy-class)
enum strMapType {
    MP_FINALE
};

// trie values: OnEntityCreated classname
enum strOEC {
    OEC_INFECTED,
    OEC_WITCH
};