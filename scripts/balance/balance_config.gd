class_name BalanceConfig
extends RefCounted

## 关卡和基地共用的起始数值。改 data/balance 里的 JSON，不要把数字写死在场景里。

const DEFAULT_SQUAD_SIZE := 1
const DEFAULT_GATE_BONUS := 1
const DEFAULT_SUPPLIES := 0

var starting_squad_size: int = DEFAULT_SQUAD_SIZE
var gate_bonus_per_upgrade: int = DEFAULT_GATE_BONUS
var starting_supplies: int = DEFAULT_SUPPLIES


static func from_dictionary(raw: Dictionary) -> BalanceConfig:
	var config := BalanceConfig.new()
	config.starting_squad_size = maxi(int(raw.get("starting_squad_size", DEFAULT_SQUAD_SIZE)), 1)
	config.gate_bonus_per_upgrade = maxi(
		int(raw.get("gate_bonus_per_upgrade", DEFAULT_GATE_BONUS)), 0
	)
	config.starting_supplies = maxi(int(raw.get("starting_supplies", DEFAULT_SUPPLIES)), 0)
	return config


static func load_from_json_file(path: String) -> BalanceConfig:
	if not FileAccess.file_exists(path):
		push_warning("找不到数值配置，改用默认值：%s" % path)
		return BalanceConfig.new()
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_warning("无法读取数值配置，改用默认值：%s" % path)
		return BalanceConfig.new()
	return from_json_text(file.get_as_text())


static func from_json_text(text: String) -> BalanceConfig:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		push_warning("数值配置不是合法 JSON，改用默认值。")
		return BalanceConfig.new()
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("数值配置不是 JSON 对象，改用默认值。")
		return BalanceConfig.new()
	return from_dictionary(parsed)


func squad_size_after_gates(gate_count: int) -> int:
	var safe_gates := maxi(gate_count, 0)
	return starting_squad_size + safe_gates * gate_bonus_per_upgrade
