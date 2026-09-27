extends GutTest

## 关卡 JSON 的几何和威胁。schema 由 tools/validate_levels.py 检查，两边规则要保持一致。

const _LEVEL_DIR := "res://data/levels/"
const _DIFFICULTY_PATH := "res://data/balance/level_difficulty.json"
const _COLUMNS := 7
const _ROWS := 12


func test_index_unlocks_twenty_four_levels_in_order() -> void:
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	var levels: Array = index["levels"]
	assert_eq(levels.size(), 24)
	var previous = null
	for entry in levels:
		assert_eq(entry["unlock_after"], previous, str(entry["id"]))
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		assert_eq(str(level["id"]), str(entry["id"]))
		assert_eq(int(level["params"]["lives"]), 20, str(entry["id"]))
		assert_eq(int(level["params"]["starting_spirit_power"]), 150, str(entry["id"]))
		previous = entry["id"]
	assert_eq(str(levels[0]["id"]), "prologue_01")
	assert_eq(str(levels[23]["id"]), "final_01")


func test_complete_levels_have_valid_maps_and_threats() -> void:
	var threats := _threats()
	var difficulty := _read_dictionary(_DIFFICULTY_PATH)
	var rows: Dictionary = difficulty["levels"]
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	for entry in index["levels"]:
		if str(entry["status"]) != "complete":
			continue
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		var problems := _map_problems(level)
		problems.append_array(_threat_problems(level, threats, rows[str(level["id"])]))
		assert_eq(problems.size(), 0, _join(problems))


func test_each_new_chapter_opens_below_the_previous_peak() -> void:
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	var difficulty := _read_dictionary(_DIFFICULTY_PATH)
	var rows: Dictionary = difficulty["levels"]
	var order: Array[String] = []
	var grouped := {}
	var hp_grouped := {}
	for entry in index["levels"]:
		var level_id := str(entry["id"])
		var row: Dictionary = rows[level_id]
		var chapter := str(entry["chapter_id"])
		if not grouped.has(chapter):
			order.append(chapter)
			grouped[chapter] = []
			hp_grouped[chapter] = []
		grouped[chapter].append(int(row["threat_budget_total"]))
		hp_grouped[chapter].append(float(row["hp_multiplier"]))
	var previous_peak := 0
	var previous_hp := 0.0
	var previous_chapter := ""
	for chapter in order:
		var budgets: Array = grouped[chapter]
		var previous_budget := -1
		for budget in budgets:
			if previous_budget >= 0:
				assert_gt(int(budget), previous_budget, chapter)
			previous_budget = int(budget)
		if previous_peak > 0 and chapter != "final":
			if previous_chapter == "prologue":
				assert_lte(int(budgets[0]), previous_peak, chapter + " vs " + previous_chapter)
			else:
				assert_lt(int(budgets[0]), previous_peak, chapter + " vs " + previous_chapter)
		if chapter == "final":
			assert_gte(int(budgets[0]), previous_peak)
			assert_gt(float(hp_grouped[chapter][0]), previous_hp)
		previous_peak = int(budgets[budgets.size() - 1])
		var hp_row: Array = hp_grouped[chapter]
		previous_hp = float(hp_row[hp_row.size() - 1])
		previous_chapter = chapter


func test_difficulty_table_keeps_the_two_open_points() -> void:
	var difficulty := _read_dictionary(_DIFFICULTY_PATH)
	var ids: Array[String] = []
	for item in difficulty["alignment_open"]:
		ids.append(str(item["id"]))
	assert_true(ids.has("threat_budget_coef_pending"))
	assert_true(ids.has("half_lives_sits_on_star_boundary"))
	assert_eq(int(difficulty["confirmed"]["starting_spirit_power"]), 150)
	assert_eq(int(difficulty["confirmed"]["spirit_per_wave_survived"]), 20)
	assert_eq(float(difficulty["levels"]["prologue_01"]["threat_budget_coef"]), 1.0)
	assert_eq(str(difficulty["_owner"]), "数值策划")


func test_rating_bands_use_twenty_lives() -> void:
	var rating := _read_dictionary(_LEVEL_DIR + "rating.json")
	assert_eq(int(rating["max_lives"]), 20)
	assert_eq(int(rating["defeat_lives"]), 0)
	assert_true(bool(rating["stars_do_not_grant_power"]))
	var bands: Array = rating["bands"]
	assert_eq(bands.size(), 3)
	assert_eq(int(bands[0]["lives_min"]), 1)
	assert_eq(int(bands[0]["lives_max"]), 9)
	assert_eq(int(bands[1]["lives_min"]), 10)
	assert_eq(int(bands[1]["lives_max"]), 17)
	assert_eq(int(bands[2]["lives_min"]), 18)
	assert_eq(int(bands[2]["lives_max"]), 20)


func _read_dictionary(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	assert_not_null(file, path)
	if file == null:
		return {}
	var parser := JSON.new()
	var error := parser.parse(file.get_as_text())
	assert_eq(error, OK, path)
	var parsed: Variant = parser.data
	assert_true(parsed is Dictionary, path)
	if parsed is Dictionary:
		return parsed
	return {}


func _threats() -> Dictionary:
	var catalog := _read_dictionary(_LEVEL_DIR + "enemy_catalog.json")
	var threats := {}
	for entry in catalog["entries"]:
		if entry["threat"] == null:
			continue
		threats[str(entry["id"])] = int(entry["threat"])
	return threats


func _map_problems(level: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	var level_map: Dictionary = level["map"]
	var grid: Array = level_map["grid"]
	if grid.size() != _ROWS:
		problems.append("%s 行数不是 12" % str(level["id"]))
		return problems
	for row in grid:
		if str(row).length() != _COLUMNS:
			problems.append("%s 有一行不是 7 列" % str(level["id"]))
			return problems
	var guard: Dictionary = level_map["guard_cell"]
	var guard_col := int(guard["col"])
	var guard_row := int(guard["row"])
	if _cell(grid, guard_col, guard_row) != "P":
		problems.append("%s 守护点不在路线上" % str(level["id"]))
	var entrances := {}
	for entrance in level_map["entrances"]:
		entrances[str(entrance["id"])] = Vector2i(int(entrance["col"]), int(entrance["row"]))
	var covered := {}
	var path_ids := {}
	for path in level_map["paths"]:
		path_ids[str(path["id"])] = true
		var cells: Array = path["cells"]
		var previous := Vector2i(-99, -99)
		var index := 0
		for cell in cells:
			var here := Vector2i(int(cell["col"]), int(cell["row"]))
			if _cell(grid, here.x, here.y) != "P":
				problems.append("%s 路径踩到非路线" % str(path["id"]))
			if index > 0 and absi(here.x - previous.x) + absi(here.y - previous.y) != 1:
				problems.append("%s 路径不连续" % str(path["id"]))
			previous = here
			covered["%d,%d" % [here.x, here.y]] = true
			index += 1
		if cells.is_empty():
			problems.append("%s 路径是空的" % str(path["id"]))
		else:
			var first: Dictionary = cells[0]
			var start := Vector2i(int(first["col"]), int(first["row"]))
			var entrance_id := str(path["entrance_id"])
			if not entrances.has(entrance_id) or entrances[entrance_id] != start:
				problems.append("%s 没有从入口出发" % str(path["id"]))
			var last: Dictionary = cells[cells.size() - 1]
			if int(last["col"]) != guard_col or int(last["row"]) != guard_row:
				problems.append("%s 没有走到守护点" % str(path["id"]))
	for row_index in grid.size():
		var line := str(grid[row_index])
		for col_index in line.length():
			if (
				line.substr(col_index, 1) == "P"
				and not covered.has("%d,%d" % [col_index, row_index])
			):
				problems.append("%s 有路线格没人走" % str(level["id"]))
	for spot in level_map["good_spots"]:
		var col := int(spot["col"])
		var row := int(spot["row"])
		if _cell(grid, col, row) != ".":
			problems.append("%s 好位置不是空地" % str(spot["id"]))
		elif not _touches_path(grid, col, row):
			problems.append("%s 好位置没有贴着路线" % str(spot["id"]))
	return problems


func _threat_problems(level: Dictionary, threats: Dictionary, row: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	var budgets: Array = row["wave_threat_budgets"]
	var waves: Array = level["waves"]
	if waves.size() != budgets.size():
		problems.append("%s 波次数和难度表不一致" % str(level["id"]))
		return problems
	if str(level["difficulty_id"]) != str(level["id"]):
		problems.append("%s 的难度行没有指向自己" % str(level["id"]))
	for index in waves.size():
		var wave: Dictionary = waves[index]
		var total := 0
		for spawn in wave["groups"]:
			var enemy_id := str(spawn["enemy_id"])
			if not threats.has(enemy_id):
				problems.append("缺少敌人 " + enemy_id)
			else:
				total += int(spawn["count"]) * int(threats[enemy_id])
		if total != int(budgets[index]):
			problems.append(
				(
					"%s %s 威胁 %d 不是 %d"
					% [str(level["id"]), str(wave["id"]), total, int(budgets[index])]
				)
			)
	return problems


func _touches_path(grid: Array, col: int, row: int) -> bool:
	return (
		_cell(grid, col + 1, row) == "P"
		or _cell(grid, col - 1, row) == "P"
		or _cell(grid, col, row + 1) == "P"
		or _cell(grid, col, row - 1) == "P"
	)


func _cell(grid: Array, col: int, row: int) -> String:
	if row < 0 or row >= grid.size():
		return ""
	var line := str(grid[row])
	if col < 0 or col >= line.length():
		return ""
	return line.substr(col, 1)


func _join(parts: PackedStringArray) -> String:
	var text := ""
	for part in parts:
		text += part + "\n"
	return text
