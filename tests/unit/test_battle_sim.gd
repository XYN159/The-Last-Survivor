extends GutTest

## 战斗规则不依赖画面：伤害、波次、路线和胜负都能单独跑完。
## 第一关新加的规则另见 test_stage1_rules.gd。

const Fixture := preload("res://tests/unit/battle_fixture.gd")


func test_early_start_pays_the_remaining_deploy_seconds() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 50})
	assert_true(sim.call_next_wave())
	var state := sim.view_state()
	assert_eq(state.phase, BattleSim.PHASE_SPAWNING)
	assert_eq(state.spirit, 60)
	assert_false(sim.call_next_wave())


func test_phase_duration_follows_each_timer() -> void:
	var sim := Fixture.mini_sim({})
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
	var sim := (
		Fixture
		. mini_sim(
			{
				"deploy": 0.0,
				"hp": 100,
				"armor": 8.0,
				"attack": 22.0,
				"interval": 10.0,
			}
		)
	)
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	sim.tick()
	assert_almost_eq(float(sim.view_state().enemies[0].hp), 86.0, 0.001)


func test_heavy_armor_takes_five_percent() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"deploy": 0.0,
				"hp": 100,
				"armor": 50.0,
				"attack": 40.0,
				"interval": 10.0,
			}
		)
	)
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	sim.tick()
	assert_almost_eq(float(sim.view_state().enemies[0].hp), 98.0, 0.001)


func test_clearing_the_field_does_not_change_when_the_next_wave_starts() -> void:
	var preview := Fixture.wave_pair({"hp": 1, "attack": 50.0})
	assert_true(preview.place("chr_reimu", 1, 5, "left"))
	preview.tick()
	assert_eq(preview.view_state().phase, BattleSim.PHASE_SPAWNING)
	assert_eq(preview.view_state().enemies.size(), 0)
	var fast_ticks := _ticks_with_reimu({"hp": 1, "attack": 50.0})
	var slow_ticks := _ticks_with_reimu({"hp": 100000, "attack": 1.0})
	assert_eq(fast_ticks, slow_ticks)
	assert_almost_eq(float(fast_ticks) / 60.0, 9.0, 0.05)


func test_first_wave_delay_is_read_from_the_wave() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"deploy": 0.0,
				"wave_delay": 0.5,
				"count": 1,
				"spawn_state": 0.0,
				"speed": 0.0,
			}
		)
	)
	sim.tick()
	assert_eq(sim.view_state().enemies.size(), 0)
	assert_eq(sim.view_state().phase, BattleSim.PHASE_INTERMISSION)
	var ticks := 1
	while ticks < 600 and sim.view_state().enemies.is_empty():
		sim.tick()
		ticks += 1
	assert_almost_eq(float(ticks) / 60.0, 0.5, 0.05)


func test_hp_multiplier_string_scales_enemy_hp() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"deploy": 0.0,
				"hp": 10,
				"hp_multiplier": "1.90",
				"count": 1,
				"spawn_state": 0.0,
			}
		)
	)
	sim.tick()
	assert_almost_eq(float(sim.view_state().enemies[0].max_hp), 19.0, 0.001)
	assert_almost_eq(float(sim.view_state().enemies[0].hp), 19.0, 0.001)


func test_a_leak_can_end_the_level() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"deploy": 0.0,
				"lives": 1,
				"speed": 30.0,
				"spawn_state": 0.0,
				"count": 1,
			}
		)
	)
	var state := Fixture.run(sim, 600)
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


func test_scripted_opening_places_with_facing_on_the_prototype_level() -> void:
	var catalog := CombatCatalog.load_level(CombatCatalog.PROTOTYPE_LEVEL_PATH)
	var sim := BattleSim.from_catalog(catalog)
	sim.set_seed(1)
	for opening_v in catalog.scripted_opening():
		var opening: Dictionary = opening_v
		assert_true(BattleFacing.is_valid(str(opening.facing)))
		assert_true(
			sim.place(
				str(opening.character_id), int(opening.col), int(opening.row), str(opening.facing)
			)
		)
	assert_eq(sim.view_state().units.size(), 2)


func test_ignoring_the_cracks_loses_the_prototype_level() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_level(CombatCatalog.PROTOTYPE_LEVEL_PATH))
	var state := Fixture.run(sim, 300000)
	assert_eq(state.outcome, BattleSim.PHASE_DEFEAT)


func _ticks_with_reimu(options: Dictionary) -> int:
	var sim := Fixture.wave_pair(options)
	sim.place("chr_reimu", 1, 5, "left")
	return Fixture.ticks_until_wave(sim, 1)


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
