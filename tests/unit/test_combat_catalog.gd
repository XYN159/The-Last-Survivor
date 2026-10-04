extends GutTest

## 原型表能读出来，字段和设计文档用的是同一套名字。
## 第一关的调参只读 data/balance/stage1_rules.json。


func test_default_level_uses_the_confirmed_opening_numbers() -> void:
	var catalog := CombatCatalog.load_default()
	var tune := catalog.tuning()
	var layout := catalog.board()
	assert_eq(tune.starting_spirit, 10)
	assert_false(tune.has("spirit_per_wave"))
	assert_eq(tune.guard_max_hp, 10)
	assert_eq(layout.columns, 7)
	assert_eq(layout.rows, 12)
	assert_eq(layout.cell_size, 128)
	assert_eq(layout.offset_x, 92.0)
	assert_eq(layout.offset_y, 140.0)


func test_stage1_rules_drive_the_tuning() -> void:
	var catalog := CombatCatalog.load_default()
	var tune := catalog.tuning()
	assert_eq(catalog.stage1_gaps().size(), 0, ", ".join(catalog.stage1_gaps()))
	assert_almost_eq(float(tune.armor_floor_ratio), 0.05, 0.0001)
	assert_eq(tune.min_damage, 0)
	assert_almost_eq(float(tune.spirit_regen_per_sec), 1.0, 0.0001)
	assert_eq(tune.max_spirit, 99)
	assert_eq(tune.max_copies, 1)
	assert_almost_eq(float(tune.retreat_refund_ratio), 0.5, 0.0001)
	assert_almost_eq(float(tune.redeploy_cost_step), 0.5, 0.0001)
	assert_eq(tune.redeploy_cost_stacks_max, 2)
	assert_almost_eq(float(tune.respawn_sec), 20.0, 0.0001)
	assert_eq(tune.ordinary_leak, 1)
	assert_eq(tune.boss_leak, 2)


func test_deploy_costs_come_from_stage1_rules() -> void:
	var catalog := CombatCatalog.load_default()
	assert_eq(catalog.deploy_cost("chr_reimu"), 16)
	assert_eq(catalog.deploy_cost("chr_marisa"), 24)
	assert_eq(catalog.deploy_cost("chr_cirno"), 12)
	assert_eq(catalog.deploy_cost("chr_yukari"), 30)


func test_only_reimu_has_a_barrier() -> void:
	var catalog := CombatCatalog.load_default()
	assert_eq(catalog.barrier("chr_reimu"), {"forward": 2, "side": 1})
	assert_eq(catalog.barrier("chr_marisa"), {})


func test_level_without_lives_falls_back_to_the_stage1_table() -> void:
	var catalog := CombatCatalog.from_dictionaries(
		{}, {}, {}, {}, {}, {"id": "ch1_04", "params": {}}, {}
	)
	assert_eq(catalog.tuning().guard_max_hp, 4)
	assert_eq(catalog.tuning().starting_spirit, 10)


func test_prototype_tables_have_the_critical_fields() -> void:
	var gaps := CombatCatalog.load_default().official_gaps()
	assert_eq(gaps.size(), 0, ", ".join(gaps))


func test_read_float_keeps_a_fractional_string() -> void:
	assert_almost_eq(CombatCatalog.read_float("1.90", 0.0), 1.9, 0.001)
	assert_eq(CombatCatalog.read_int("1.90", 0), 1)


func test_nested_attack_stats_override_flat_fields_and_the_character_file() -> void:
	var catalog := _catalog_with_stats(
		{
			"chr_reimu":
			{
				"cost": 80,
				"base_attack": 20,
				"attack": {"range_cells": "3.25", "interval_sec": "1.10"},
				"range_cells": 9,
				"attack_interval_sec": 9,
			},
			"chr_marisa":
			{
				"cost": 70,
				"base_attack": 22,
				"range_cells": 4,
				"attack_interval_sec": 1.5,
			},
		}
	)
	var reimu: Dictionary = catalog.character("chr_reimu")
	var marisa: Dictionary = catalog.character("chr_marisa")
	assert_almost_eq(float(reimu.attack.range_cells), 3.25, 0.001)
	assert_almost_eq(float(reimu.attack.interval_sec), 1.1, 0.001)
	assert_almost_eq(float(marisa.attack.range_cells), 4.0, 0.001)
	assert_almost_eq(float(marisa.attack.interval_sec), 1.5, 0.001)


func test_missing_critical_fields_are_reported() -> void:
	var catalog := (
		CombatCatalog
		. from_dictionaries(
			{},
			{"characters": {"chr_reimu": {}}, "enemies": {"enm_shade_basic": {}}},
			{
				"characters":
				[
					{
						"id": "chr_reimu",
						"attack":
						{"type": "homing_projectile", "range_cells": 2.5, "interval_sec": 0.8},
					}
				]
			},
			{"enemies": [{"id": "enm_shade_basic"}]},
			{},
			{"id": "mini"},
			{"levels": {"mini": {}}},
		)
	)
	var gaps := catalog.official_gaps()
	assert_true(gaps.has("chr_reimu 缺少费用 cost"))
	assert_true(gaps.has("chr_reimu 缺少攻击 base_attack"))
	assert_true(gaps.has("enm_shade_basic 缺少血量 hp"))
	assert_true(gaps.has("enm_shade_basic 缺少移速 move_speed_cells_per_sec"))
	assert_true(gaps.has("enm_shade_basic 缺少护甲 armor"))
	assert_true(gaps.has("enm_shade_basic 缺少漏怪伤害 leak_damage"))
	assert_true(gaps.has("缺少血量倍率 hp_multiplier"))


func test_fast_shade_name_stays_on_its_key() -> void:
	assert_eq(tr("enemy.shade_fast.name"), "快残影")
	assert_eq(CombatCatalog.load_default().enemy("enm_shade_fast").display_name, "快残影")


func test_reimu_and_marisa_keep_their_attack_types() -> void:
	var catalog := CombatCatalog.load_default()
	var reimu: Dictionary = catalog.character("chr_reimu")
	var marisa: Dictionary = catalog.character("chr_marisa")
	assert_eq(reimu.display_name, "灵梦")
	assert_eq(reimu.attack.type, "homing_projectile")
	assert_almost_eq(float(reimu.attack.range_cells), 2.5, 0.001)
	assert_eq(marisa.display_name, "魔理沙")
	assert_eq(marisa.attack.type, "instant_line")
	assert_almost_eq(float(marisa.stats.base_attack), 22.0, 0.001)


func test_both_paths_stay_on_the_map_and_end_at_the_guard() -> void:
	var level := CombatCatalog.load_level(CombatCatalog.PROTOTYPE_LEVEL_PATH).level()
	var cells: Array = level.map.cells
	assert_eq(level.map.paths.size(), 2)
	for path_v in level.map.paths:
		var path: Dictionary = path_v
		var points: Array = path.cells
		var first: Array = points[0]
		var last: Array = points[points.size() - 1]
		assert_eq(_mark(cells, first), "S")
		assert_eq(_mark(cells, last), "G")
		for index in range(1, points.size()):
			var before: Array = points[index - 1]
			var after: Array = points[index]
			var steps := absi(int(before[0]) - int(after[0])) + absi(int(before[1]) - int(after[1]))
			assert_eq(steps, 1)


func _catalog_with_stats(character_stats: Dictionary) -> CombatCatalog:
	return (
		CombatCatalog
		. from_dictionaries(
			{},
			{"characters": character_stats, "enemies": {}},
			{
				"characters":
				[
					{
						"id": "chr_reimu",
						"name_key": "char.reimu.name",
						"attack":
						{"type": "homing_projectile", "range_cells": 2.5, "interval_sec": 0.8},
					},
					{
						"id": "chr_marisa",
						"display_name": "魔理沙",
						"attack": {"type": "instant_line", "range_cells": 3.5, "interval_sec": 1.6},
					},
				]
			},
			{"enemies": []},
			{},
			{"id": "mini", "display_name": "测试"},
			{"levels": {"mini": {"hp_multiplier": "1.00"}}},
		)
	)


func _mark(cells: Array, point: Array) -> String:
	var line := str(cells[int(point[1])])
	return line.substr(int(point[0]), 1)
