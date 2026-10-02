class_name MotionConfig
extends RefCounted

## 界面动效的时长和幅度，读 data/prototype/ui_motion.json。
## 表里都是动效师的临时值，正式数字归数值策划。缺字段时用调用方给的后备值，不让画面卡住。

const DEFAULT_PATH := "res://data/prototype/ui_motion.json"

var _data: Dictionary = {}


static func load_default() -> MotionConfig:
	return load_path(DEFAULT_PATH)


static func load_path(path: String) -> MotionConfig:
	if not FileAccess.file_exists(path):
		push_warning("找不到动效配置，按后备值继续：%s" % path)
		return from_dictionary({})
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning("动效配置不是合法 JSON，按后备值继续：%s" % path)
		return from_dictionary({})
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return from_dictionary({})
	return from_dictionary(parsed)


static func from_dictionary(data: Dictionary) -> MotionConfig:
	var config := MotionConfig.new()
	config._data = data
	return config


func number(section: String, key: String, fallback: float) -> float:
	var value: Variant = _section(section).get(key, fallback)
	match typeof(value):
		TYPE_INT, TYPE_FLOAT:
			return float(value)
	return fallback


func count(section: String, key: String, fallback: int) -> int:
	return maxi(int(round(number(section, key, float(fallback)))), 0)


func _section(section: String) -> Dictionary:
	var found: Variant = _data.get(section, {})
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return found
