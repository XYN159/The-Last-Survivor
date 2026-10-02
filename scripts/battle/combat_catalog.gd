class_name CombatCatalog
extends RefCounted

## 战斗表和关卡的读取。
## 原型表在 data/prototype。USE_OFFICIAL_TABLES 保持 false，
## 直到下面三份都合并进 main 再打开：
## #4 的 rules.json、characters.json、enemies.json、feel.json，
## #5 的 data/levels，#8 的 stats.json 和 level_difficulty.json。
## 只合了其中一份就打开，会缺文件。
## 开关打开时，缺文件或缺关键字段用 push_error，不要悄悄填默认值。
## 关键字段：攻击、费用、射程、间隔、血量、移速、护甲、漏怪伤害、血量倍率。
## 正式难度表的 hp_multiplier 是字符串，用 read_float，不要用 read_int。
## 射程和间隔先认 stats 里嵌套的 attack.range_cells、attack.interval_sec，
## 再认扁平的 range_cells、attack_interval_sec，最后才用 characters.json。
## 同名上限先认每个角色自己的 max_copies，没有再用规则里的全局值。
## deploy_wait_for_player 留到切正式序章之前再读。原型关用不上。

const USE_OFFICIAL_TABLES := false

const _PROTOTYPE_ROOTS := {
	"combat_dir": "res://data/prototype/combat",
	"level_path": "res://data/prototype/levels/prototype_01.json",
	"difficulty_path": "res://data/prototype/level_difficulty.json",
}
const _OFFICIAL_ROOTS := {
	"combat_dir": "res://data/balance/combat",
	"level_path": "res://data/levels/prologue_01.json",
	"difficulty_path": "res://data/balance/level_difficulty.json",
}
const _FALLBACK_NAMES := {
	"chr_reimu": "灵梦",
	"chr_marisa": "魔理沙",
	"enm_shade_basic": "小残影",
	"enm_shade_fast": "快残影",
}

var _rules: Dictionary = {}
var _stats: Dictionary = {}
var _feel: Dictionary = {}
var _level: Dictionary = {}
var _difficulty: Dictionary = {}
var _difficulty_row: Dictionary = {}
var _characters: Dictionary = {}
var _enemies: Dictionary = {}


static func load_default() -> CombatCatalog:
	var official := USE_OFFICIAL_TABLES
	var roots: Dictionary = _OFFICIAL_ROOTS if official else _PROTOTYPE_ROOTS
	var combat_dir := str(roots.combat_dir)
	var catalog := from_dictionaries(
		_read_json(combat_dir.path_join("rules.json"), official),
		_read_json(combat_dir.path_join("stats.json"), official),
		_read_json(combat_dir.path_join("characters.json"), official),
		_read_json(combat_dir.path_join("enemies.json"), official),
		_read_json(combat_dir.path_join("feel.json"), official),
		_read_json(str(roots.level_path), official),
		_read_json(str(roots.difficulty_path), official),
	)
	if official:
		for gap in catalog.official_gaps():
			push_error(gap)
	return catalog


static func from_dictionaries(
	rules: Dictionary,
	stats: Dictionary,
	characters: Dictionary,
	enemies: Dictionary,
	feel: Dictionary,
	level: Dictionary,
	difficulty: Dictionary,
) -> CombatCatalog:
	var catalog := CombatCatalog.new()
	catalog._rules = rules
	catalog._stats = stats
	catalog._feel = feel
	catalog._level = level
	catalog._difficulty = difficulty
	catalog._index(characters, enemies)
	return catalog


static func read_int(value: Variant, fallback: int) -> int:
	match typeof(value):
		TYPE_INT:
			return int(value)
		TYPE_FLOAT:
			return int(value)
		TYPE_STRING:
			if str(value).is_valid_int():
				return int(str(value))
			if str(value).is_valid_float():
				return int(float(str(value)))
	return fallback


static func read_float(value: Variant, fallback: float) -> float:
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return float(value)
		TYPE_STRING:
			if str(value).is_valid_float():
				return float(str(value))
	return fallback


func board() -> Dictionary:
	var grid: Dictionary = _rules.get("grid", {})
	var offset_x := 92.0
	var offset_y := 140.0
	var offset_v: Variant = grid.get("board_offset_px", [])
	if typeof(offset_v) == TYPE_ARRAY and (offset_v as Array).size() >= 2:
		offset_x = float((offset_v as Array)[0])
		offset_y = float((offset_v as Array)[1])
	return {
		"columns": maxi(read_int(grid.get("columns", 7), 7), 1),
		"rows": maxi(read_int(grid.get("rows", 12), 12), 1),
		"cell_size": maxi(read_int(grid.get("cell_size_px", 128), 128), 1),
		"offset_x": offset_x,
		"offset_y": offset_y,
	}


func tuning() -> Dictionary:
	var tick: Dictionary = _rules.get("tick", {})
	var placement: Dictionary = _rules.get("placement", {})
	var levels: Dictionary = _rules.get("character_levels", {})
	var spawn: Dictionary = _rules.get("enemy_spawn", {})
	var knockback: Dictionary = _rules.get("knockback", {})
	var economy: Dictionary = _stats.get("economy", {})
	var flow: Dictionary = _rules.get("battle_flow", {})
	var wave_rules: Dictionary = _dictionary_copy(_stats.get("waves", {}))
	var params: Dictionary = _level.get("params", {})
	var guard: Dictionary = _stats.get("guard", {})
	var starting := read_int(
		(
			params
			. get(
				"starting_spirit_power",
				_difficulty_row.get("reward_spirit_start", economy.get("starting_spirit", 150)),
			)
		),
		150,
	)
	var per_wave := read_int(
		_difficulty_row.get("reward_spirit_per_wave", params.get("reward_spirit_per_wave", 0)),
		0,
	)
	var window := read_float(
		wave_rules.get("spawn_window_sec", flow.get("wave_target_sec", 20)),
		20.0,
	)
	return {
		"logic_hz": maxi(read_int(tick.get("logic_hz", 60), 60), 1),
		"max_ticks_per_frame": maxi(read_int(tick.get("max_ticks_per_frame", 4), 4), 1),
		"armor_floor_ratio": float(_stats.get("armor_floor_ratio", 0.2)),
		"min_damage": maxi(read_int(_stats.get("min_damage", 1), 1), 0),
		"starting_spirit": maxi(starting, 0),
		"spirit_per_wave": maxi(per_wave, 0),
		"early_call_reward_per_sec": float(economy.get("early_call_reward_per_sec", 2)),
		"early_start_reward_per_sec": float(economy.get("early_start_reward_per_sec", 1)),
		"max_copies": maxi(read_int(placement.get("max_copies_per_character", 3), 3), 1),
		"max_level": maxi(read_int(levels.get("max_level", 3), 3), 1),
		"spawn_state_sec": maxf(float(spawn.get("spawn_state_sec", 0.3)), 0.0),
		"knockback_cooldown_sec": maxf(float(knockback.get("per_enemy_cooldown_sec", 0.25)), 0.0),
		"guard_max_hp": maxi(read_int(params.get("lives", guard.get("max_hp", 20)), 20), 1),
		"deploy_time_sec":
		maxf(read_float(_level.get("deploy_time_sec", flow.get("deploy_time_sec", 10)), 10.0), 0.0),
		"intermission_sec":
		maxf(read_float(_level.get("intermission_sec", flow.get("intermission_sec", 4)), 4.0), 0.0),
		"spawn_window_sec": maxf(window, 0.0),
	}


func level() -> Dictionary:
	return _level


func feel() -> Dictionary:
	return _feel


func character(character_id: String) -> Dictionary:
	var found: Variant = _characters.get(character_id, {})
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return found


func enemy(enemy_id: String) -> Dictionary:
	var found: Variant = _enemies.get(enemy_id, {})
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return found


func enemy_hp_multiplier(enemy_id: String = "") -> float:
	var multiplier := _hp_multiplier()
	if not enemy_id.begins_with("boss_"):
		return multiplier
	var boss_rules := _dictionary_copy(_stats.get("boss_rules", {}))
	if boss_rules.has("hp_uses_level_mult") and not bool(boss_rules["hp_uses_level_mult"]):
		return 1.0
	return multiplier


func time_scale() -> Dictionary:
	var scale: Dictionary = _rules.get("time_scale", {})
	var options: Array = scale.get("speed_options", [1, 2])
	var speeds: Array[int] = []
	for item_v in options:
		var speed := read_int(item_v, 0)
		if speed > 0:
			speeds.append(speed)
	if speeds.is_empty():
		speeds = [1, 2]
	var default_speed := read_int(scale.get("default_speed", speeds[0]), speeds[0])
	if not speeds.has(default_speed):
		default_speed = speeds[0]
	return {
		"options": speeds,
		"default_speed": default_speed,
		"remember_last_speed": bool(scale.get("remember_last_speed", true)),
	}


func official_gaps() -> PackedStringArray:
	var gaps := PackedStringArray()
	if _characters.is_empty():
		gaps.append("正式角色表是空的")
	if _enemies.is_empty():
		gaps.append("正式敌人表是空的")
	_difficulty_gaps(gaps)
	for id_v in _characters.keys():
		_character_gaps(str(id_v), gaps)
	for id_v in _enemies.keys():
		_enemy_gaps(str(id_v), gaps)
	return gaps


static func _read_json(path: String, official: bool = false) -> Dictionary:
	if not FileAccess.file_exists(path):
		_missing_file(path, official)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		_missing_file(path, official)
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		_missing_file(path, official)
		return {}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		_missing_file(path, official)
		return {}
	return parsed


static func _missing_file(path: String, official: bool) -> void:
	if official:
		push_error("正式表缺文件：%s" % path)
		return
	push_warning("找不到配置，按空表继续：%s" % path)


func _index(characters: Dictionary, enemies: Dictionary) -> void:
	_characters = {}
	_enemies = {}
	var char_stats: Dictionary = _stats.get("characters", {})
	for item_v in characters.get("characters", []):
		_store_character(item_v, char_stats)
	var enemy_stats: Dictionary = _stats.get("enemies", {})
	for item_v in enemies.get("enemies", []):
		_store_enemy(item_v, enemy_stats)
	_difficulty_row = {}
	var table_v: Variant = _difficulty.get("levels", {})
	if typeof(table_v) != TYPE_DICTIONARY:
		return
	var row_v: Variant = (table_v as Dictionary).get(str(_level.get("id", "")), {})
	if typeof(row_v) == TYPE_DICTIONARY:
		_difficulty_row = row_v
	_apply_level_name()


func _store_character(item_v: Variant, char_stats: Dictionary) -> void:
	if typeof(item_v) != TYPE_DICTIONARY:
		return
	var item: Dictionary = item_v
	var id := str(item.get("id", ""))
	if id == "":
		return
	var merged := item.duplicate(true)
	var stats := _dictionary_copy(char_stats.get(id, {}))
	merged["stats"] = stats
	merged["attack"] = _attack_with_stats(_dictionary_copy(item.get("attack", {})), stats)
	merged["display_name"] = _visible_name(item, id)
	_characters[id] = merged


func _store_enemy(item_v: Variant, enemy_stats: Dictionary) -> void:
	if typeof(item_v) != TYPE_DICTIONARY:
		return
	var item: Dictionary = item_v
	var id := str(item.get("id", ""))
	if id == "":
		return
	var merged := item.duplicate(true)
	merged["stats"] = _dictionary_copy(enemy_stats.get(id, {}))
	merged["display_name"] = _visible_name(item, id)
	_enemies[id] = merged


func _attack_with_stats(attack: Dictionary, stats: Dictionary) -> Dictionary:
	var nested := _dictionary_copy(stats.get("attack", {}))
	if nested.has("range_cells"):
		attack["range_cells"] = read_float(nested["range_cells"], 0.0)
	elif stats.has("range_cells"):
		attack["range_cells"] = read_float(stats["range_cells"], 0.0)
	if nested.has("interval_sec"):
		attack["interval_sec"] = read_float(nested["interval_sec"], 0.0)
	elif stats.has("attack_interval_sec"):
		attack["interval_sec"] = read_float(stats["attack_interval_sec"], 0.0)
	return attack


func _visible_name(item: Dictionary, fallback_id: String) -> String:
	var key := str(item.get("name_key", item.get("display_name_key", "")))
	if key != "":
		var translated := tr(key)
		if translated != key:
			return translated
	if item.has("display_name"):
		return str(item["display_name"])
	return str(_FALLBACK_NAMES.get(fallback_id, fallback_id))


func _apply_level_name() -> void:
	var key := str(_level.get("display_name_key", _level.get("name_key", "")))
	if key == "":
		return
	var translated := tr(key)
	if translated != key:
		_level["display_name"] = translated
		return
	if not _level.has("display_name"):
		_level["display_name"] = key


func _hp_multiplier() -> float:
	if _difficulty_row.has("hp_multiplier"):
		return read_float(_difficulty_row["hp_multiplier"], 1.0)
	if not _difficulty_row.has("level_number"):
		return 1.0
	var scaling := _dictionary_copy(_stats.get("level_scaling", {}))
	var per_level := read_float(scaling.get("enemy_hp_mult_per_level", 0.15), 0.15)
	var number := read_int(_difficulty_row.get("level_number"), 1)
	return 1.0 + per_level * float(number - 1)


func _difficulty_gaps(gaps: PackedStringArray) -> void:
	var table_v: Variant = _difficulty.get("levels", {})
	if typeof(table_v) != TYPE_DICTIONARY or (table_v as Dictionary).is_empty():
		gaps.append("正式难度表是空的")
		return
	var level_id := str(_level.get("id", ""))
	if not (table_v as Dictionary).has(level_id):
		gaps.append("正式难度表是空的")
		return
	if not _difficulty_row.has("hp_multiplier"):
		gaps.append("缺少血量倍率 hp_multiplier")


func _character_gaps(character_id: String, gaps: PackedStringArray) -> void:
	var data: Dictionary = _characters[character_id]
	var stats := _dictionary_copy(data.get("stats", {}))
	var attack := _dictionary_copy(data.get("attack", {}))
	if attack.is_empty() or not attack.has("type"):
		gaps.append("%s 缺少攻击 attack" % character_id)
	if not stats.has("base_attack"):
		gaps.append("%s 缺少攻击 base_attack" % character_id)
	if not stats.has("cost"):
		gaps.append("%s 缺少费用 cost" % character_id)
	if not attack.has("range_cells"):
		gaps.append("%s 缺少射程 range_cells" % character_id)
	if not attack.has("interval_sec"):
		gaps.append("%s 缺少攻击间隔 interval_sec" % character_id)


func _enemy_gaps(enemy_id: String, gaps: PackedStringArray) -> void:
	var stats := _dictionary_copy(_enemies[enemy_id].get("stats", {}))
	if not stats.has("hp"):
		gaps.append("%s 缺少血量 hp" % enemy_id)
	if not stats.has("move_speed_cells_per_sec"):
		gaps.append("%s 缺少移速 move_speed_cells_per_sec" % enemy_id)
	if not stats.has("armor"):
		gaps.append("%s 缺少护甲 armor" % enemy_id)
	if not stats.has("leak_damage"):
		gaps.append("%s 缺少漏怪伤害 leak_damage" % enemy_id)


func _dictionary_copy(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return (value as Dictionary).duplicate(true)
