class_name CombatCatalog
extends RefCounted

## 战斗表和关卡的读取。
## 原型表在 data/prototype。设计 PR 合并后，把 USE_OFFICIAL_TABLES 改成 true，
## 就会改读 data/balance/combat、data/levels 和 data/balance/level_difficulty.json。
## 正式难度表里的灵力有时是字符串，read_int 两种都认。

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
	var roots: Dictionary = _PROTOTYPE_ROOTS
	if USE_OFFICIAL_TABLES:
		roots = _OFFICIAL_ROOTS
	var combat_dir := str(roots.combat_dir)
	return from_dictionaries(
		_read_json(combat_dir.path_join("rules.json")),
		_read_json(combat_dir.path_join("stats.json")),
		_read_json(combat_dir.path_join("characters.json")),
		_read_json(combat_dir.path_join("enemies.json")),
		_read_json(combat_dir.path_join("feel.json")),
		_read_json(str(roots.level_path)),
		_read_json(str(roots.difficulty_path)),
	)


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
		maxf(float(_level.get("deploy_time_sec", flow.get("deploy_time_sec", 10))), 0.0),
		"intermission_sec":
		maxf(float(_level.get("intermission_sec", flow.get("intermission_sec", 4))), 0.0),
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


static func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("找不到配置，按空表继续：%s" % path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("无法读取配置，按空表继续：%s" % path)
		return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		push_warning("配置不是合法 JSON，按空表继续：%s" % path)
		return {}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("配置不是 JSON 对象，按空表继续：%s" % path)
		return {}
	return parsed


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


func _store_character(item_v: Variant, char_stats: Dictionary) -> void:
	if typeof(item_v) != TYPE_DICTIONARY:
		return
	var item: Dictionary = item_v
	var id := str(item.get("id", ""))
	if id == "":
		return
	var merged := item.duplicate(true)
	merged["stats"] = _dictionary_copy(char_stats.get(id, {}))
	if not merged.has("display_name"):
		merged["display_name"] = str(_FALLBACK_NAMES.get(id, id))
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
	if not merged.has("display_name"):
		merged["display_name"] = str(_FALLBACK_NAMES.get(id, id))
	_enemies[id] = merged


func _dictionary_copy(value: Variant) -> Dictionary:
	if typeof(value) != TYPE_DICTIONARY:
		return {}
	return (value as Dictionary).duplicate(true)
