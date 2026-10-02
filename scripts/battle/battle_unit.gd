class_name BattleUnit
extends RefCounted

## 已经放在棋盘上的一名角色。画面不读这里的结算，只读模拟器给出的快照。

var instance_id: int = 0
var character_id: String = ""
var display_name: String = ""
var col: int = 0
var row: int = 0
var level: int = 1
var cooldown: float = 0.0
var spent: int = 0
var base_attack: float = 0.0
var level_attack_mult: Array = []
var crit_chance: float = 0.0
var crit_mult: float = 1.0
var refund_ratio: float = 0.7
var upgrade_costs: Array = []
var attack: Dictionary = {}
