class_name BattleUnit
extends RefCounted

## 已经放在棋盘上的一名角色。画面不读这里的结算，只读模拟器给出的快照。
## 第一版战斗不做局内升级，level 固定为 1。

var instance_id: int = 0
var character_id: String = ""
var display_name: String = ""
var col: int = 0
var row: int = 0
## 地图表里的朝向：up / down / left / right，见 BattleFacing。
var facing: String = ""
var level: int = 1
var cooldown: float = 0.0
var spent: int = 0
var base_attack: float = 0.0
var level_attack_mult: Array = []
var crit_chance: float = 0.0
var crit_mult: float = 1.0
var attack: Dictionary = {}
## 为 true 时只打结界里的敌人，结界外伤害为 0。barrier 的键是 Vector2i 格子。
var uses_barrier: bool = false
var barrier: Dictionary = {}
