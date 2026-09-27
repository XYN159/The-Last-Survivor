extends GutTest

## 关卡 JSON 的几何和威胁。schema 由 tools/validate_levels.py 检查，两边规则要保持一致。

const _LEVEL_DIR := "res://data/levels/"
const _DIFFICULTY_PATH := "res://data/balance/level_tables/level_difficulty.csv"
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
	var rows := _read_difficulty()
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
	var rows := _read_difficulty()
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
		grouped[chapter].append(_budget_total(int(row["wave_count"])))
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


func test_difficulty_seed_records_the_open_points() -> void:
	var file := FileAccess.open(_DIFFICULTY_PATH, FileAccess.READ)
	assert_not_null(file, _DIFFICULTY_PATH)
	var text := file.get_as_text()
	assert_true(text.contains("owner: 数值策划"))
	assert_true(text.contains("status: seed"))
	assert_true(text.contains("(10 + 4 × wave_index) × threat_budget_coef"))
	assert_true(text.contains("1.3"))
	assert_true(text.contains("0.85"))
	assert_true(text.contains("11-13"))
	assert_true(text.contains("10-11"))
	assert_true(text.contains("制作人"))
	var rows := _read_difficulty()
	assert_eq(str(rows["prologue_01"]["threat_budget_coef"]), "1.0")
	assert_eq(str(rows["ch1_04"]["expected_first_clear_lives"]), "10-11")
	assert_eq(str(rows["ch1_01"]["expected_first_clear_lives"]), "11-13")
	assert_eq(str(rows["prologue_01"]["reward_spirit_start"]), "150")
	assert_eq(str(rows["prologue_01"]["reward_spirit_per_wave"]), "20")
	assert_true(text.contains("pending_numbers"))
	assert_true(text.contains("重打"))
	assert_true(text.contains("50%"))
	assert_eq(str(rows["prologue_01"]["wave_count"]), "3")
	assert_eq(str(rows["prologue_01"]["reward_buff_pick_count"]), "0")
	assert_eq(str(rows["prologue_03"]["reward_buff_after_waves"]), "5")
	assert_eq(str(rows["ch1_01"]["reward_buff_after_waves"]), "5")
	assert_eq(str(rows["ch1_02"]["reward_buff_after_waves"]), "5;10")
	assert_eq(str(rows["ch1_04"]["reward_buff_after_waves"]), "5;10")
	assert_eq(str(rows["final_01"]["reward_buff_after_waves"]), "5;10;15")
	assert_false(str(rows["final_01"]["reward_buff_after_waves"]).ends_with(";20"))
	assert_eq(str(rows["ch1_01"]["reward_meta_first_clear"]), "pending_numbers")
	assert_eq(str(rows["ch1_01"]["reward_meta_replay"]), "pending_numbers")
	assert_eq(str(rows["final_01"]["wave_count"]), "20")


func test_fast_shade_stats_are_not_in_the_level_catalog() -> void:
	var catalog := _read_dictionary(_LEVEL_DIR + "enemy_catalog.json")
	var source: Dictionary = catalog["stat_source"]
	assert_eq(str(source["path"]), "data/balance/combat/stats.json")
	assert_eq(str(source["enemies_field"]), "enemies")
	assert_eq(str(source["bosses_field"]), "bosses")
	assert_false(catalog.has("stat_conflict"))
	var blob := JSON.stringify(catalog)
	assert_false(blob.contains("生命 35"))
	assert_false(blob.contains("每秒 2.0"))
	assert_false(blob.contains("普通残影"))
	assert_false(blob.contains("飞屑"))
	assert_false(blob.contains("boss_yukari"))
	var names := {}
	for entry in catalog["entries"]:
		names[str(entry["id"])] = str(entry["display_name"])
	assert_eq(str(names["enm_shade_basic"]), "小残影")
	assert_eq(str(names["enm_shade_flying"]), "飞行残影")
	assert_eq(str(names["boss_ch4_sanae_shade"]), "风祝的残影")
	assert_eq(str(names["boss_ch5_gatekeeper"]), "结界裂缝的守门残影")
	for entry in catalog["entries"]:
		assert_false(entry.has("hp"))
		assert_false(entry.has("move_speed"))
		assert_false(entry.has("max_hp"))
		assert_false(entry.has("stats"))


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
	assert_eq(int(bands[1]["lives_max"]), 19)
	assert_eq(int(bands[2]["lives_min"]), 20)
	assert_eq(int(bands[2]["lives_max"]), 20)
	assert_eq(float(rating["two_star_lives_ratio"]), 0.5)
	assert_eq(str(rating["two_star_ratio_status"]), "pending_numbers")
	assert_true(bool(rating["replay"]["cleared_levels_anytime"]))
	assert_true(bool(rating["replay"]["can_earn_missing_stars"]))
	assert_false(bool(rating["leak"]["stored_in_level_data"]))
	assert_eq(str(rating["first_clear"]["normal_lives_remaining"]), "11-13")
	assert_eq(str(rating["first_clear"]["boss_lives_remaining"]), "10-11")


func test_character_unlocks_follow_clears() -> void:
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	var decided: Array = index["character_joins_decided"]
	var cirno: Dictionary = {}
	for item in decided:
		if str(item["id"]) == "chr_cirno":
			cirno = item
	assert_eq(str(cirno["status"]), "decided")
	assert_eq(str(cirno["unlock_after_clearing"]), "ch1_01")
	assert_eq(str(cirno["first_placeable_level"]), "ch1_02")
	var proposals: Array = index["character_join_proposals"]
	var meiling: Dictionary = proposals[0]
	assert_eq(str(meiling["id"]), "chr_meiling")
	assert_eq(str(meiling["status"]), "pending_文案策划")
	assert_eq(str(meiling["unlock_after_clearing"]), "ch2_01")
	var aya_locked := false
	for item in proposals:
		if str(item["id"]) == "chr_cirno":
			assert_false(true, "琪露诺不再是提案")
		if str(item["id"]) == "chr_aya":
			aya_locked = item["unlock_after_clearing"] == null
	assert_true(aya_locked)
	var unlocked: Array[String] = ["chr_reimu"]
	var previous: Array[String] = []
	for entry in index["levels"]:
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		var available: Array = level["params"]["available_character_ids"]
		assert_eq(available, unlocked, str(level["id"]))
		var expected_new: Array[String] = []
		for character_id in available:
			if not previous.has(str(character_id)):
				expected_new.append(str(character_id))
		assert_eq(level["new_character_ids"], expected_new, str(level["id"]))
		for character_id in level["unlock_character_ids"]:
			unlocked.append(str(character_id))
		previous.clear()
		for character_id in available:
			previous.append(str(character_id))


func test_waves_last_about_twenty_seconds() -> void:
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	for entry in index["levels"]:
		if str(entry["status"]) != "complete":
			continue
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		var waves: Array = level["waves"]
		var last_index := waves.size() - 1
		for wave_index in waves.size():
			var wave: Dictionary = waves[wave_index]
			assert_eq(int(wave["duration_sec"]), 20, str(level["id"]))
			assert_eq(float(wave["delay_sec"]), 4.0, str(level["id"]))
			var boss_last := str(level["id"]) == "ch1_04" and wave_index == last_index
			var expected := "boss_defeated" if boss_last else "spawn_window"
			assert_eq(str(wave["ends_when"]), expected, str(wave["id"]))
			for spawn in wave["spawns"]:
				var count := int(spawn["count"])
				if count <= 1:
					continue
				var window := float(spawn["delay_sec"])
				window += float(count - 1) * float(spawn["interval_sec"])
				assert_true(window >= 18.0 and window <= 22.0, str(wave["id"]))
	var boss_level := _read_dictionary(_LEVEL_DIR + "ch1_04.json")
	var leak: Dictionary = boss_level["bosses"][0]["leak"]
	var source := "data/balance/combat/stats.json#/bosses/boss_cirno/leak_damage"
	assert_eq(str(leak["lives_source"]), source)
	assert_eq(str(leak["on_reach_guard"]), "deduct_lives_and_return_to_rift")
	assert_false(JSON.stringify(leak).contains('"5"'))


func test_ch1_01_fast_shades_arrive_late() -> void:
	var level := _read_dictionary(_LEVEL_DIR + "ch1_01.json")
	var fast_total := 0
	var wave_index := 0
	for wave in level["waves"]:
		wave_index += 1
		var fast_here := 0
		for spawn in wave["spawns"]:
			if str(spawn["enemy_id"]) == "enm_shade_fast":
				fast_here += int(spawn["count"])
		if wave_index < 8:
			assert_eq(fast_here, 0, str(wave["id"]))
		else:
			assert_gt(fast_here, 0, str(wave["id"]))
		fast_total += fast_here
	assert_eq(fast_total, 32)


func test_mvp_levels_only_spawn_basic_and_fast_shades() -> void:
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	for entry in index["levels"]:
		if str(entry["status"]) != "complete":
			continue
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		for wave in level["waves"]:
			for spawn in wave["spawns"]:
				var enemy_id := str(spawn["enemy_id"])
				var allowed := enemy_id == "enm_shade_basic" or enemy_id == "enm_shade_fast"
				assert_true(allowed, "%s %s" % [str(level["id"]), enemy_id])


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


func _read_difficulty() -> Dictionary:
	var file := FileAccess.open(_DIFFICULTY_PATH, FileAccess.READ)
	assert_not_null(file, _DIFFICULTY_PATH)
	var header: PackedStringArray = PackedStringArray()
	var rows := {}
	while file != null and not file.eof_reached():
		var line := file.get_line().strip_edges()
		if line.is_empty() or line.begins_with("#"):
			continue
		var parts := line.split(",")
		if header.is_empty():
			header = parts
			continue
		var row := {}
		for column in header.size():
			row[header[column]] = parts[column]
		rows[str(row["level_id"])] = row
	return rows


func _budget_total(wave_count: int) -> int:
	var total := 0
	for wave_index in range(1, wave_count + 1):
		total += 10 + 4 * wave_index
	return total


func _threats() -> Dictionary:
	var catalog := _read_dictionary(_LEVEL_DIR + "enemy_catalog.json")
	var threats := {}
	for entry in catalog["entries"]:
		if entry["threat_points"] == null:
			continue
		threats[str(entry["id"])] = int(entry["threat_points"])
	return threats


func _map_problems(level: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	var level_map: Dictionary = level["map"]
	var grid: Array = level_map["cells"]
	if grid.size() != _ROWS:
		problems.append("%s 行数不是 12" % str(level["id"]))
		return problems
	for row in grid:
		if str(row).length() != _COLUMNS:
			problems.append("%s 有一行不是 7 列" % str(level["id"]))
			return problems
	var guard_cell: Array = level_map["guard"]["cell"]
	var guard_col := int(guard_cell[0])
	var guard_row := int(guard_cell[1])
	if _cell(grid, guard_col, guard_row) != "G":
		problems.append("%s 守护点不是 G" % str(level["id"]))
	var entrances := {}
	for entrance in level_map["entrances"]:
		entrances[str(entrance["id"])] = Vector2i(int(entrance["col"]), int(entrance["row"]))
	var starts := {}
	var parsed: Array = []
	for path in level_map["paths"]:
		var cells: Array = path["cells"]
		parsed.append(path)
		if not cells.is_empty():
			var first: Array = cells[0]
			starts["%d,%d" % [int(first[0]), int(first[1])]] = true
	var covered := {}
	for path in parsed:
		var cells: Array = path["cells"]
		var previous := Vector2i(-99, -99)
		var index := 0
		for cell in cells:
			var here := Vector2i(int(cell[0]), int(cell[1]))
			var expected := "P"
			if here.x == guard_col and here.y == guard_row:
				expected = "G"
			elif starts.has("%d,%d" % [here.x, here.y]):
				expected = "S"
			if _cell(grid, here.x, here.y) != expected:
				problems.append("%s 路径字符不对" % str(path["path_id"]))
			if index > 0 and absi(here.x - previous.x) + absi(here.y - previous.y) != 1:
				problems.append("%s 路径不连续" % str(path["path_id"]))
			previous = here
			covered["%d,%d" % [here.x, here.y]] = true
			index += 1
		if cells.is_empty():
			problems.append("%s 路径是空的" % str(path["path_id"]))
		else:
			var first_cell: Array = cells[0]
			var start := Vector2i(int(first_cell[0]), int(first_cell[1]))
			var entrance_id := str(path["entrance_id"])
			if not entrances.has(entrance_id) or entrances[entrance_id] != start:
				problems.append("%s 没有从入口出发" % str(path["path_id"]))
			var last: Array = cells[cells.size() - 1]
			if int(last[0]) != guard_col or int(last[1]) != guard_row:
				problems.append("%s 没有走到守护点" % str(path["path_id"]))
	var slot_cells := {}
	for spot in level_map["slots"]:
		var col := int(spot["col"])
		var row := int(spot["row"])
		slot_cells["%d,%d" % [col, row]] = true
		if _cell(grid, col, row) != ".":
			problems.append("%s 预定槽位不是 ." % str(spot["id"]))
		elif not _touches_route(grid, col, row):
			problems.append("%s 预定槽位没有贴着路线" % str(spot["id"]))
	for row_index in grid.size():
		var line := str(grid[row_index])
		for col_index in line.length():
			var here := line.substr(col_index, 1)
			var key := "%d,%d" % [col_index, row_index]
			if here == "P" and not covered.has(key):
				problems.append("%s 有路线格没人走" % str(level["id"]))
			if here == "." and not slot_cells.has(key):
				problems.append("%s 有可放置格不在槽位名单" % str(level["id"]))
	return problems


func _threat_problems(level: Dictionary, threats: Dictionary, row: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	var wave_count := int(row["wave_count"])
	var waves: Array = level["waves"]
	if waves.size() != wave_count:
		problems.append("%s 波次数和难度表不一致" % str(level["id"]))
		return problems
	if str(level["difficulty_id"]) != str(level["id"]):
		problems.append("%s 的难度行没有指向自己" % str(level["id"]))
	if str(row["threat_budget_coef"]) != "1.0":
		problems.append("%s 的系数种子不是 1.0" % str(level["id"]))
	for index in waves.size():
		var wave: Dictionary = waves[index]
		var total := 0
		for spawn in wave["spawns"]:
			var enemy_id := str(spawn["enemy_id"])
			if not threats.has(enemy_id):
				problems.append("缺少敌人 " + enemy_id)
			else:
				total += int(spawn["count"]) * int(threats[enemy_id])
		var budget := 10 + 4 * (index + 1)
		if total != budget:
			problems.append(
				"%s %s 威胁 %d 不是 %d" % [str(level["id"]), str(wave["id"]), total, budget]
			)
	return problems


func _touches_route(grid: Array, col: int, row: int) -> bool:
	var neighbors := [
		_cell(grid, col + 1, row),
		_cell(grid, col - 1, row),
		_cell(grid, col, row + 1),
		_cell(grid, col, row - 1),
	]
	for neighbor in neighbors:
		if neighbor == "P" or neighbor == "S" or neighbor == "G":
			return true
	return false


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
