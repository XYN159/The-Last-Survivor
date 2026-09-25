extends Node

## 跨场景的运行时状态。数值来自 BalanceConfig，真正的存档读写留给后续的 SaveGame。

signal squad_size_changed(new_size: int)

const BALANCE_PATH := "res://data/balance/starting_balance.json"

var squad_size: int = 1
var supplies: int = 0


func _ready() -> void:
	apply_balance(BalanceConfig.load_from_json_file(BALANCE_PATH))


func apply_balance(config: BalanceConfig) -> void:
	squad_size = config.starting_squad_size
	supplies = config.starting_supplies
	squad_size_changed.emit(squad_size)
