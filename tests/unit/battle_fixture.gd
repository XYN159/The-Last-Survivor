extends RefCounted

## 战斗模拟测试共用的迷你关卡。文件名不以 test_ 开头，GUT 不会把它当测试跑。
## 调参用 data/balance/stage1_rules.json 的副本；默认关掉结界，只有专门测结界的用例才打开。


static func tick(sim: BattleSim, count: int) -> void:
	for _step in count:
		sim.tick()


static func run(sim: BattleSim, limit: int) -> Dictionary:
	var ticks := 0
	while ticks < limit and str(sim.view_state().outcome) == "":
		sim.tick()
		ticks += 1
	return sim.view_state()


## 一直 tick 到出过 count 只敌人（按 id 计，漏掉的也算），返回用了几秒。
static func seconds_until_enemies(sim: BattleSim, count: int) -> float:
	var seen := {}
	for enemy_v in sim.view_state().enemies:
		seen[int(enemy_v.id)] = true
	var ticks := 0
	while ticks < 6000 and seen.size() < count:
		sim.tick()
		ticks += 1
		for enemy_v in sim.view_state().enemies:
			seen[int(enemy_v.id)] = true
	return float(ticks) / 60.0


## 第一关规则表的副本。options.barrier 为 true 才保留灵梦的结界；options.stage1 里的键覆盖原值。
static func stage1(options: Dictionary) -> Dictionary:
	var stage1 := CombatCatalog.read_stage1_rules().duplicate(true)
	if not bool(options.get("barrier", false)):
		stage1["barrier"] = {}
	var overrides: Dictionary = options.get("stage1", {})
	for key in overrides.keys():
		stage1[key] = overrides[key]
	return stage1


static func mini_sim(options: Dictionary) -> BattleSim:
	var rules := {
		"tick": {"logic_hz": 60, "max_ticks_per_frame": 4},
		"enemy_spawn": {"spawn_state_sec": float(options.get("spawn_state", 0.0))},
		"knockback": {"per_enemy_cooldown_sec": 0.25},
		"battle_flow": {"intermission_sec": float(options.get("intermission", 4.0))},
	}
	var stats := {
		"economy": {"early_call_reward_per_sec": 2, "early_start_reward_per_sec": 1},
		"characters":
		{
			"chr_reimu":
			{
				"cost": 50,
				"base_attack": float(options.get("attack", 10.0)),
				"level_attack_mult": [1.0],
				"crit_chance": 0.0,
				"crit_mult": 1.8,
			},
		},
		"enemies":
		{
			"enm_shade_basic":
			{
				"hp": int(options.get("hp", 30)),
				"move_speed_cells_per_sec": float(options.get("speed", 1.0)),
				"armor": float(options.get("armor", 0.0)),
				"spirit_drop": 0,
				"leak_damage": 1,
			},
		},
	}
	var characters := {
		"characters":
		[
			{
				"id": "chr_reimu",
				"display_name": "灵梦",
				"attack":
				{
					"type": "instant_line",
					"range_cells": float(options.get("range", 20.0)),
					"interval_sec": float(options.get("interval", 0.5)),
					"initial_delay_sec": 0.0,
					"line_width_cells": 1.0,
					"can_crit": false,
					"knockback_cells": 0.0,
				},
			}
		],
	}
	var enemies := {
		"enemies": [{"id": "enm_shade_basic", "display_name": "小残影", "hit_radius_cells": 0.3}],
	}
	var level := {
		"id": "mini",
		"display_name": "测试",
		"deploy_time_sec": float(options.get("deploy", 10.0)),
		"intermission_sec": float(options.get("intermission", 4.0)),
		"params":
		{
			"starting_spirit_power": int(options.get("starting_spirit", 99)),
			"lives": int(options.get("lives", 20)),
			"available_character_ids": ["chr_reimu"],
		},
		"map":
		{
			"cells":
			[
				"S.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"P.BBBBB",
				"G.BBBBB",
			],
			"paths":
			[
				{
					"path_id": "path.main",
					"cells":
					[
						[0, 0],
						[0, 1],
						[0, 2],
						[0, 3],
						[0, 4],
						[0, 5],
						[0, 6],
						[0, 7],
						[0, 8],
						[0, 9],
						[0, 10],
						[0, 11],
					],
				}
			],
		},
		"waves": waves_for(options),
	}
	if options.has("timeline"):
		level["timeline"] = options["timeline"]
	if options.has("max_copies"):
		stats["characters"]["chr_reimu"]["max_copies"] = int(options["max_copies"])
	var difficulty := {}
	if options.has("hp_multiplier"):
		difficulty = {"levels": {"mini": {"hp_multiplier": str(options["hp_multiplier"])}}}
	var catalog := CombatCatalog.from_dictionaries(
		rules, stats, characters, enemies, {}, level, difficulty, stage1(options)
	)
	return BattleSim.from_catalog(catalog)


static func wave_pair(options: Dictionary) -> BattleSim:
	options["deploy"] = 0.0
	options["gap"] = 8.0
	options["duration"] = 1.0
	options["follow_up"] = true
	return mini_sim(options)


static func ticks_until_wave(sim: BattleSim, wave_index: int) -> int:
	var ticks := 0
	while ticks < 5000 and int(sim.view_state().wave_index) < wave_index:
		sim.tick()
		ticks += 1
	return ticks


static func waves_for(options: Dictionary) -> Array:
	var waves: Array = [one_wave(options)]
	if not bool(options.get("follow_up", false)):
		return waves
	(
		waves
		. append(
			{
				"id": "w02",
				"wave_id": "w02",
				"next_wave_delay_sec": 4.0,
				"spawns":
				[
					{
						"enemy_id": "enm_shade_basic",
						"path_id": "path.main",
						"count": 1,
						"interval_sec": 1.0,
						"delay_sec": 0.0,
					}
				],
			}
		)
	)
	return waves


static func one_wave(options: Dictionary) -> Dictionary:
	var wave := {
		"id": "w01",
		"wave_id": "w01",
		"duration_sec": float(options.get("duration", 20.0)),
		"next_wave_delay_sec": float(options.get("gap", 4.0)),
		"spawns":
		[
			{
				"enemy_id": "enm_shade_basic",
				"path_id": "path.main",
				"count": int(options.get("count", 1)),
				"interval_sec": float(options.get("spawn_interval", 1.0)),
				"delay_sec": 0.0,
			}
		],
	}
	if options.has("wave_delay"):
		wave["delay_sec"] = float(options["wave_delay"])
	return wave
