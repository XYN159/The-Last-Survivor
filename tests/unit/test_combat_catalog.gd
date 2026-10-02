extends GutTest

## 原型表能读出来，字段和设计文档用的是同一套名字。


func test_prototype_level_uses_the_confirmed_opening_numbers() -> void:
	var catalog := CombatCatalog.load_default()
	var tune := catalog.tuning()
	var layout := catalog.board()
	assert_eq(tune.starting_spirit, 150)
	assert_eq(tune.spirit_per_wave, 20)
	assert_eq(tune.guard_max_hp, 20)
	assert_eq(layout.columns, 7)
	assert_eq(layout.rows, 12)
	assert_eq(layout.cell_size, 128)
	assert_eq(layout.offset_x, 92.0)
	assert_eq(layout.offset_y, 140.0)


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
	var level := CombatCatalog.load_default().level()
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


func _mark(cells: Array, point: Array) -> String:
	var line := str(cells[int(point[1])])
	return line.substr(int(point[0]), 1)
