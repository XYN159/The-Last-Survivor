extends GutTest

## 战斗规则不依赖画面：伤害、灵力、波次和胜负都能单独跑完。


func test_place_sell_and_upgrade_move_spirit() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	assert_eq(sim.view_state().spirit, 150)
	assert_true(sim.place("chr_reimu", 2, 4))
	assert_false(sim.place("chr_reimu", 1, 4))
	assert_eq(sim.view_state().spirit, 100)
	var unit_id := int(sim.view_state().units[0].id)
	assert_true(sim.upgrade(unit_id))
	assert_eq(sim.view_state().spirit, 60)
	assert_eq(int(sim.view_state().units[0].level), 2)
	assert_true(sim.sell(unit_id))
	assert_eq(sim.view_state().spirit, 123)
	assert_eq(sim.view_state().units.size(), 0)


func test_second_copy_costs_more_and_third_is_the_last() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	assert_true(sim.place("chr_reimu", 2, 1))
	assert_true(sim.place("chr_reimu", 2, 4))
	assert_eq(int(sim.view_state().roster[0].cost), 100)
	assert_false(sim.place("chr_reimu", 4, 4))
	assert_eq(sim.view_state().spirit, 25)


func test_early_start_pays_the_remaining_deploy_seconds() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	assert_true(sim.call_next_wave())
	var state := sim.view_state()
	assert_eq(state.phase, BattleSim.PHASE_SPAWNING)
	assert_eq(state.spirit, 160)
	assert_false(sim.call_next_wave())


func test_phase_duration_follows_each_timer() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	var state := sim.view_state()
	assert_eq(float(state.phase_duration), 10.0)
	assert_eq(float(state.phase_time_left), 10.0)
	assert_true(sim.call_next_wave())
	state = sim.view_state()
	assert_eq(state.phase, BattleSim.PHASE_SPAWNING)
	assert_gt(float(state.phase_duration), 0.0)
	assert_eq(float(state.phase_duration), float(state.phase_time_left))
	sim.tick()
	state = sim.view_state()
	assert_lt(float(state.phase_time_left), float(state.phase_duration))


func test_armor_hit_uses_the_damage_formula() -> void:
	var sim := _mini(
		{
			"deploy": 0.0,
			"hp": 100,
			"armor": 8.0,
			"attack": 22.0,
			"interval": 10.0,
		}
	)
	assert_true(sim.place("chr_reimu", 1, 5))
	sim.tick()
	assert_almost_eq(float(sim.view_state().enemies[0].hp), 86.0, 0.001)


func test_clearing_the_field_does_not_change_when_the_next_wave_starts() -> void:
	var preview := _wave_pair({"hp": 1, "attack": 50.0})
	assert_true(preview.place("chr_reimu", 1, 5))
	preview.tick()
	assert_eq(preview.view_state().phase, BattleSim.PHASE_SPAWNING)
	assert_eq(preview.view_state().enemies.size(), 0)
	var fast_ticks := _ticks_with_reimu({"hp": 1, "attack": 50.0})
	var slow_ticks := _ticks_with_reimu({"hp": 100000, "attack": 1.0})
	assert_eq(fast_ticks, slow_ticks)
	assert_almost_eq(float(fast_ticks) / 60.0, 9.0, 0.05)


func test_first_wave_delay_is_read_from_the_wave() -> void:
	var sim := _mini(
		{
			"deploy": 0.0,
			"wave_delay": 0.5,
			"count": 1,
			"spawn_state": 0.0,
			"speed": 0.0,
		}
	)
	sim.tick()
	assert_eq(sim.view_state().enemies.size(), 0)
	assert_eq(sim.view_state().phase, BattleSim.PHASE_INTERMISSION)
	var ticks := 1
	while ticks < 600 and sim.view_state().enemies.is_empty():
		sim.tick()
		ticks += 1
	assert_almost_eq(float(ticks) / 60.0, 0.5, 0.05)


func test_copy_cost_is_linear_and_the_fourth_is_refused() -> void:
	var sim := _mini({"starting_spirit": 500})
	assert_true(sim.place("chr_reimu", 1, 1))
	assert_eq(int(sim.view_state().roster[0].cost), 75)
	assert_true(sim.place("chr_reimu", 1, 2))
	assert_eq(int(sim.view_state().roster[0].cost), 100)
	assert_true(sim.place("chr_reimu", 1, 3))
	assert_false(sim.place("chr_reimu", 1, 4))
	assert_eq(sim.view_state().units.size(), 3)


func test_character_max_copies_beats_the_global_limit() -> void:
	var sim := _mini({"starting_spirit": 500, "max_copies": 1})
	assert_true(sim.place("chr_reimu", 1, 1))
	assert_false(sim.place("chr_reimu", 1, 2))
	assert_eq(sim.view_state().units.size(), 1)


func test_hp_multiplier_string_scales_enemy_hp() -> void:
	var sim := _mini(
		{
			"deploy": 0.0,
			"hp": 10,
			"hp_multiplier": "1.90",
			"count": 1,
			"spawn_state": 0.0,
		}
	)
	sim.tick()
	assert_almost_eq(float(sim.view_state().enemies[0].max_hp), 19.0, 0.001)
	assert_almost_eq(float(sim.view_state().enemies[0].hp), 19.0, 0.001)


func test_a_leak_can_end_the_level() -> void:
	var sim := _mini(
		{
			"deploy": 0.0,
			"lives": 1,
			"leak": 1,
			"speed": 30.0,
			"spawn_state": 0.0,
			"count": 1,
		}
	)
	var state := _run(sim, 600)
	assert_eq(state.outcome, BattleSim.PHASE_DEFEAT)
	assert_eq(state.guard_hp, 0)


func test_two_paths_move_apart() -> void:
	var sim := _two_paths()
	sim.call_next_wave()
	for _step in 90:
		sim.tick()
	var enemies: Array = sim.view_state().enemies
	assert_eq(enemies.size(), 2)
	assert_gt(absf(float(enemies[0].x) - float(enemies[1].x)), 1.0)


func test_scripted_opening_clears_the_prototype_level() -> void:
	var catalog := CombatCatalog.load_level(CombatCatalog.PROTOTYPE_LEVEL_PATH)
	var sim := BattleSim.from_catalog(catalog)
	sim.set_seed(1)
	for opening_v in catalog.level().get("suggested_opening", []):
		var opening: Dictionary = opening_v
		assert_true(sim.place(str(opening.character_id), int(opening.col), int(opening.row)))
	var state := _run(sim, 300000)
	assert_eq(
		state.outcome, BattleSim.PHASE_VICTORY, "生命 %s 波次 %s" % [state.guard_hp, state.wave_index]
	)
	assert_gt(int(state.guard_hp), 0)


func test_ignoring_the_cracks_loses_the_prototype_level() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_level(CombatCatalog.PROTOTYPE_LEVEL_PATH))
	var state := _run(sim, 300000)
	assert_eq(state.outcome, BattleSim.PHASE_DEFEAT)


func _run(sim: BattleSim, limit: int) -> Dictionary:
	var ticks := 0
	while ticks < limit and str(sim.view_state().outcome) == "":
		sim.tick()
		ticks += 1
	return sim.view_state()


func _mini(options: Dictionary) -> BattleSim:
	var rules := {
		"tick": {"logic_hz": 60, "max_ticks_per_frame": 4},
		"placement": {"max_copies_per_character": 3},
		"character_levels": {"max_level": 3},
		"enemy_spawn": {"spawn_state_sec": float(options.get("spawn_state", 0.0))},
		"knockback": {"per_enemy_cooldown_sec": 0.25},
		"battle_flow": {"intermission_sec": float(options.get("intermission", 4.0))},
	}
	var stats := {
		"armor_floor_ratio": 0.2,
		"min_damage": 1,
		"economy": {"early_call_reward_per_sec": 2, "early_start_reward_per_sec": 1},
		"characters":
		{
			"chr_reimu":
			{
				"cost": 50,
				"upgrade_costs": [40, 80],
				"sell_refund_ratio": 0.7,
				"copy_cost_increase_ratio": 0.5,
				"base_attack": float(options.get("attack", 10.0)),
				"level_attack_mult": [1.0, 1.5, 2.2],
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
				"spirit_drop": 5,
				"leak_damage": int(options.get("leak", 1)),
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
			"starting_spirit_power": int(options.get("starting_spirit", 150)),
			"lives": int(options.get("lives", 20)),
			"available_character_ids": ["chr_reimu"],
			"reward_spirit_per_wave": int(options.get("per_wave", 20)),
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
		"waves": _waves_for(options),
	}
	if options.has("max_copies"):
		stats["characters"]["chr_reimu"]["max_copies"] = int(options["max_copies"])
	var difficulty := {}
	if options.has("hp_multiplier"):
		difficulty = {"levels": {"mini": {"hp_multiplier": str(options["hp_multiplier"])}}}
	var catalog := CombatCatalog.from_dictionaries(
		rules, stats, characters, enemies, {}, level, difficulty
	)
	return BattleSim.from_catalog(catalog)


func _wave_pair(options: Dictionary) -> BattleSim:
	options["deploy"] = 0.0
	options["gap"] = 8.0
	options["duration"] = 1.0
	options["follow_up"] = true
	options["per_wave"] = 20
	return _mini(options)


func _ticks_with_reimu(options: Dictionary) -> int:
	var sim := _wave_pair(options)
	sim.place("chr_reimu", 1, 5)
	return _ticks_until_wave(sim, 1)


func _ticks_until_wave(sim: BattleSim, wave_index: int) -> int:
	var ticks := 0
	while ticks < 5000 and int(sim.view_state().wave_index) < wave_index:
		sim.tick()
		ticks += 1
	return ticks


func _waves_for(options: Dictionary) -> Array:
	var waves: Array = [_one_wave(options)]
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


func _one_wave(options: Dictionary) -> Dictionary:
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


func _two_paths() -> BattleSim:
	var rules := {
		"tick": {"logic_hz": 60},
		"enemy_spawn": {"spawn_state_sec": 0.0},
		"placement": {"max_copies_per_character": 3},
		"character_levels": {"max_level": 3},
	}
	var stats := {
		"armor_floor_ratio": 0.2,
		"min_damage": 1,
		"characters": {},
		"enemies":
		{
			"enm_shade_basic":
			{
				"hp": 100,
				"move_speed_cells_per_sec": 1.0,
				"armor": 0,
				"spirit_drop": 1,
				"leak_damage": 1,
			},
		},
	}
	var enemies := {"enemies": [{"id": "enm_shade_basic", "hit_radius_cells": 0.3}]}
	var level := {
		"id": "fork",
		"deploy_time_sec": 10.0,
		"params": {"starting_spirit_power": 0, "lives": 20, "available_character_ids": []},
		"map":
		{
			"cells":
			[
				"SBBBBBS",
				"PBBBBBP",
				"PBBBBBP",
				"PBBBBBP",
				"PBBBBBP",
				"PBBBBBP",
				"PBBBBBP",
				"PBBBBBP",
				"PPPPPPP",
				"BBBPBBB",
				"BBBPBBB",
				"BBBGBBB",
			],
			"paths":
			[
				{
					"path_id": "path.left",
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
						[3, 8],
						[3, 11]
					],
				},
				{
					"path_id": "path.right",
					"cells":
					[
						[6, 0],
						[6, 1],
						[6, 2],
						[6, 3],
						[6, 4],
						[6, 5],
						[6, 6],
						[6, 7],
						[6, 8],
						[3, 8],
						[3, 11]
					],
				},
			],
		},
		"waves":
		[
			{
				"id": "w01",
				"next_wave_delay_sec": 4.0,
				"spawns":
				[
					{
						"enemy_id": "enm_shade_basic",
						"path_id": "path.left",
						"count": 1,
						"interval_sec": 1.0,
						"delay_sec": 0.0
					},
					{
						"enemy_id": "enm_shade_basic",
						"path_id": "path.right",
						"count": 1,
						"interval_sec": 1.0,
						"delay_sec": 0.0
					},
				],
			}
		],
	}
	return BattleSim.from_catalog(
		CombatCatalog.from_dictionaries(rules, stats, {"characters": []}, enemies, {}, level, {})
	)
