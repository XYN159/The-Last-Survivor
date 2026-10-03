extends GutTest

## 关卡 JSON 的几何和威胁。schema 由 tools/validate_levels.py 检查，两边规则要保持一致。

const _LEVEL_DIR := "res://data/levels/"
const _DIFFICULTY_PATH := "res://data/balance/level_difficulty.json"
const _STATS_PATH := "res://data/balance/combat/stats.json"
const _COLUMNS := 7
const _ROWS := 12
var _warned_missing_balance := false


func test_index_unlocks_twenty_four_levels_in_order() -> void:
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	var levels: Array = index["levels"]
	assert_eq(levels.size(), 24)
	var previous = null
	for entry in levels:
		assert_eq(entry["unlock_after"], previous, str(entry["id"]))
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		assert_eq(str(level["id"]), str(entry["id"]))
		_assert_lives_match_stats(level)
		previous = entry["id"]
	assert_eq(str(levels[0]["id"]), "prologue_01")
	assert_eq(str(levels[23]["id"]), "final_01")


func test_complete_levels_have_valid_maps() -> void:
	var catalog_ids := _catalog_ids()
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	for entry in index["levels"]:
		if str(entry["status"]) != "complete":
			continue
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		var problems := _map_problems(level)
		problems.append_array(_known_enemy_problems(level, catalog_ids))
		assert_eq(problems.size(), 0, _join(problems))


func test_difficulty_table_is_not_in_this_pr() -> void:
	assert_false(FileAccess.file_exists(_DIFFICULTY_PATH))
	var rating := _read_dictionary(_LEVEL_DIR + "rating.json")
	var source: Dictionary = rating["first_clear_source"]
	assert_eq(str(source["path"]), "data/balance/level_difficulty.json")
	assert_eq(str(source["field"]), "levels.<level_id>.target_lives_first_clear")
	assert_false(rating.has("first_clear"))


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
	assert_eq(str(names["enm_shade_phantom"]), "遗忘之影")
	assert_eq(str(names["enm_shade_heap"]), "堆积体")
	assert_eq(str(names["enm_shade_rift"]), "结界之渣")
	assert_eq(str(names["boss_ch2_sakuya_shade"]), "红魔的女仆残影")
	assert_eq(str(names["boss_ch3_mokou_shade"]), "不死鸟的残影")
	assert_eq(str(names["boss_ch4_sanae_shade"]), "风祝的残影")
	assert_eq(str(names["boss_ch5_gatekeeper"]), "守门残影")
	for entry in catalog["entries"]:
		assert_false(entry.has("hp"))
		assert_false(entry.has("move_speed"))
		assert_false(entry.has("max_hp"))
		assert_false(entry.has("stats"))
		assert_false(entry.has("threat_points"))
		var enemy_id := str(entry["id"])
		assert_eq(str(entry["display_name_key"]), "enemy.%s.name" % enemy_id)
		assert_true(str(entry["threat_points_source"]).ends_with("/threat_points"))
	_assert_only_schema_version_is_numeric(catalog, "enemy_catalog")


func test_rating_bands_use_twenty_lives() -> void:
	var rating := _read_dictionary(_LEVEL_DIR + "rating.json")
	assert_true(bool(rating["stars_do_not_grant_power"]))
	assert_false(rating.has("bands"))
	assert_false(rating.has("max_lives"))
	assert_false(rating.has("two_star_lives_ratio"))
	var stars: Dictionary = rating["stars_source"]
	assert_eq(str(stars["path"]), "data/balance/combat/stats.json")
	assert_eq(str(stars["field"]), "stars.thresholds_lives_left")
	assert_false(stars.has("thresholds_lives_left"))
	assert_true(str(stars["note"]).contains("首通目标不参与星级"))
	var lives: Dictionary = rating["lives_source"]
	assert_eq(str(lives["field"]), "guard.max_hp")
	for path in [
		"res://docs/design/level/overview.md",
		"res://docs/design/level/data_format.md",
		"res://docs/adr/0003-level-data-format.md",
		"res://docs/adr/0004-preset-slots-and-fixed-routes.md",
		"res://CHANGELOG.md",
	]:
		var prose := FileAccess.get_file_as_string(path)
		assert_false(prose.contains("18–20"), path)
		assert_false(prose.contains("18-20"), path)
		assert_false(prose.contains("10–17"), path)
		assert_false(prose.contains("10-17"), path)
	assert_true(bool(rating["replay"]["cleared_levels_anytime"]))
	assert_true(bool(rating["replay"]["can_earn_missing_stars"]))
	assert_false(bool(rating["leak"]["stored_in_level_data"]))
	assert_false(rating.has("first_clear"))
	_assert_only_schema_version_is_numeric(rating, "rating")
	var stats := _optional_stats()
	if stats.is_empty():
		return
	var thresholds: Array = stats["stars"]["thresholds_lives_left"]
	assert_eq(thresholds.size(), 3)


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
			var expected_delay := 0.0 if wave_index == 0 else 4.0
			assert_eq(float(wave["delay_sec"]), expected_delay, str(level["id"]))
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


func test_ch1_01_fast_shades_start_at_wave_six() -> void:
	var level := _read_dictionary(_LEVEL_DIR + "ch1_01.json")
	var fast_total := 0
	var wave_index := 0
	for wave in level["waves"]:
		wave_index += 1
		var fast_here := 0
		for spawn in wave["spawns"]:
			var count := int(spawn["count"])
			if str(spawn["enemy_id"]) == "enm_shade_fast":
				fast_here += count
		if wave_index < 6:
			assert_eq(fast_here, 0, str(wave["id"]))
		else:
			assert_gt(fast_here, 0, str(wave["id"]))
		fast_total += fast_here
	assert_gt(fast_total, 0)
	_assert_threat_matches_budget(level)


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
				if str(level["id"]) == "ch1_03" and enemy_id == "enm_shade_armored":
					allowed = true
				assert_true(allowed, "%s %s" % [str(level["id"]), enemy_id])


func test_ch1_03_armored_shades_follow_the_schedule() -> void:
	var level := _read_dictionary(_LEVEL_DIR + "ch1_03.json")
	var armored_total := 0
	var wave_index := 0
	for wave in level["waves"]:
		wave_index += 1
		var left := 0
		var right := 0
		for spawn in wave["spawns"]:
			if str(spawn["enemy_id"]) != "enm_shade_armored":
				continue
			var count := int(spawn["count"])
			armored_total += count
			var delay := float(spawn["delay_sec"])
			assert_true(delay >= 8.0 and delay <= 12.0, str(wave["id"]))
			if str(spawn["path_id"]) == "path.left":
				left += count
			elif str(spawn["path_id"]) == "path.right":
				right += count
		if wave_index < 6:
			assert_eq(left + right, 0, str(wave["id"]))
		elif wave_index == 12:
			assert_eq(left, 1, str(wave["id"]))
			assert_eq(right, 1, str(wave["id"]))
		elif wave_index % 2 == 0:
			assert_eq(left, 1, str(wave["id"]))
			assert_eq(right, 0, str(wave["id"]))
		else:
			assert_eq(left, 0, str(wave["id"]))
			assert_eq(right, 1, str(wave["id"]))
	assert_eq(armored_total, 8)
	assert_eq(
		str(level["armored_shade_lock"]),
		"首次出现仍是这一关（Q13）。数量 8 只是旧锁，待按新时间轴重排。"
	)
	var boss_level := _read_dictionary(_LEVEL_DIR + "ch1_04.json")
	var bosses: Array = boss_level["bosses"]
	var boss: Dictionary = bosses[0]
	assert_eq(int(boss["enter_wave"]), 11)
	assert_eq(str(boss["enter_timing_status"]), "待 P10")
	assert_eq(str(boss["enters_at_wave_id"]), "w11")
	var prelude: Array = boss["prelude_wave_ids"]
	assert_eq(prelude.size(), 10)
	assert_false(bool(boss["applies_level_hp_multiplier"]))
	var phases: Array = boss["phases"]
	assert_eq(str(phases[0]["status_on_character"]), "st_unit_frozen")
	assert_eq(str(phases[1]["status_on_character"]), "st_unit_frozen")
	assert_eq(str(phases[1]["status_on_shade"]), "st_freeze")


func test_level_table_placeholders_stay_blank() -> void:
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	var armor_lock := "首次出现仍是这一关（Q13）。数量 8 只是旧锁，待按新时间轴重排。"
	for entry in index["levels"]:
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		var level_id := str(level["id"])
		assert_eq(str(level["battle_problem"]), "待 P1", level_id)
		assert_eq(str(level["initial_cost"]), "待定", level_id)
		assert_eq(str(level["max_life_point"]), "待定", level_id)
		assert_eq(str(level["buildable"]), "待定", level_id)
		var kind := str(level["kind"])
		if kind == "boss" or kind == "final_boss":
			assert_eq(str(level["boss_enter_timing_status"]), "待 P10", level_id)
		else:
			assert_false(level.has("boss_enter_timing_status"), level_id)
		if level_id == "ch1_03":
			assert_eq(str(level["armored_shade_lock"]), armor_lock)
		else:
			assert_false(level.has("armored_shade_lock"), level_id)


func test_ch1_03_gap_demo_runs_once() -> void:
	var level := _read_dictionary(_LEVEL_DIR + "ch1_03.json")
	var events: Array = level["scripted_events"]
	assert_eq(events.size(), 1)
	var event: Dictionary = events[0]
	assert_eq(str(event["id"]), "evt_yukari_gap_demo")
	assert_true(bool(event["once"]))
	assert_eq(str(event["wave_id"]), "w06")
	assert_false(bool(event["deals_damage"]))
	assert_true(bool(event["threat_unchanged"]))
	assert_eq(str(event["dialogue_status"]), "pending_文案策划")
	assert_true(str(event["trigger"]).contains("左路"))
	assert_true(str(event["trigger"]).contains("一半"))
	assert_true(str(event["effect"]).contains("裂隙"))
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	for entry in index["levels"]:
		if str(entry["id"]) == "ch1_03":
			continue
		var other := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		assert_false(other.has("scripted_events"), str(entry["id"]))


func test_each_level_teaches_one_thing() -> void:
	var prologue := _read_dictionary(_LEVEL_DIR + "prologue_03.json")
	var prologue_teaches := str(prologue["teaches"])
	assert_true(prologue_teaches.contains("三选一"))
	assert_false(prologue_teaches.contains("拐角"))
	var lake := _read_dictionary(_LEVEL_DIR + "ch1_01.json")
	var lake_teaches := str(lake["teaches"])
	assert_true(lake_teaches.contains("快残影"))
	assert_false(lake_teaches.contains("雾"))
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	for entry in index["levels"]:
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		assert_true(level["teaches"] is String, str(level["id"]))


func test_buff_notes_match_offer_waves() -> void:
	var index := _read_dictionary(_LEVEL_DIR + "index.json")
	for entry in index["levels"]:
		if str(entry["status"]) != "complete":
			continue
		var level := _read_dictionary(_LEVEL_DIR + str(entry["file"]))
		var waves: Array = level["waves"]
		var wave_index := 0
		for wave in waves:
			wave_index += 1
			var offered := wave_index < waves.size() and wave_index % 5 == 0
			var note := str(wave.get("note", ""))
			assert_eq(note.contains("三选一"), offered, str(level["id"]) + " " + str(wave["id"]))


func _optional_stats() -> Dictionary:
	if not FileAccess.file_exists(_STATS_PATH):
		_warn_missing(_STATS_PATH, "属性")
		return {}
	return _read_dictionary(_STATS_PATH)


func _warn_missing(path: String, label: String) -> void:
	if _warned_missing_balance:
		return
	_warned_missing_balance = true
	print("警告：找不到 %s。%s数字检查已跳过。" % [path, label])


func _assert_lives_match_stats(level: Dictionary) -> void:
	var stats := _optional_stats()
	if stats.is_empty():
		return
	var lives := int(stats["guard"]["max_hp"])
	var spirit := int(stats["economy"]["starting_spirit"])
	assert_eq(int(level["params"]["lives"]), lives, str(level["id"]))
	assert_eq(int(level["params"]["starting_spirit_power"]), spirit, str(level["id"]))


func _assert_threat_matches_budget(level: Dictionary) -> void:
	var missing_difficulty := not FileAccess.file_exists(_DIFFICULTY_PATH)
	var missing_stats := not FileAccess.file_exists(_STATS_PATH)
	if missing_difficulty or missing_stats:
		_warn_missing(_DIFFICULTY_PATH, "难度或属性")
		return
	var stats := _read_dictionary(_STATS_PATH)
	var points := {}
	for bucket in ["enemies", "bosses"]:
		if not stats.has(bucket):
			continue
		var stat_rows: Dictionary = stats[bucket]
		for enemy_id in stat_rows:
			var stat_row: Dictionary = stat_rows[enemy_id]
			if stat_row.has("threat_points") and stat_row["threat_points"] != null:
				points[str(enemy_id)] = int(stat_row["threat_points"])
	var threat_total := 0
	for wave in level["waves"]:
		for spawn in wave["spawns"]:
			var enemy_id := str(spawn["enemy_id"])
			if not points.has(enemy_id):
				print("警告：stats.json 没有 %s 的威胁点，威胁核对已跳过。" % enemy_id)
				return
			threat_total += int(spawn["count"]) * int(points[enemy_id])
	var table := _read_dictionary(_DIFFICULTY_PATH)
	var rows: Dictionary = table["levels"]
	var row: Dictionary = rows[str(level["id"])]
	assert_eq(threat_total, int(row["threat_budget_total"]), str(level["id"]))


func _assert_only_schema_version_is_numeric(value, path: String) -> void:
	if value is float:
		assert_false(true, "%s 不该自己带数字" % path)
		return
	if value is Dictionary:
		for key in value:
			if str(key) == "schema_version":
				continue
			var child := "%s.%s" % [path, str(key)]
			_assert_only_schema_version_is_numeric(value[key], child)
	elif value is Array:
		var index := 0
		for item in value:
			_assert_only_schema_version_is_numeric(item, "%s[%d]" % [path, index])
			index += 1


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


func _catalog_ids() -> Dictionary:
	var catalog := _read_dictionary(_LEVEL_DIR + "enemy_catalog.json")
	var ids := {}
	for entry in catalog["entries"]:
		ids[str(entry["id"])] = true
	return ids


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


func _known_enemy_problems(level: Dictionary, catalog_ids: Dictionary) -> PackedStringArray:
	var problems: PackedStringArray = []
	if str(level["difficulty_id"]) != str(level["id"]):
		problems.append("%s 的难度行没有指向自己" % str(level["id"]))
	for wave in level["waves"]:
		for spawn in wave["spawns"]:
			var enemy_id := str(spawn["enemy_id"])
			if not catalog_ids.has(enemy_id):
				problems.append("缺少敌人 " + enemy_id)
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
