class_name BattleEnemy
extends RefCounted

## 沿固定路线走的一只残影。progress 是已经走过的格数。

var instance_id: int = 0
var enemy_id: String = ""
var path_id: String = ""
var path_length: float = 0.0
var progress: float = 0.0
var hp: float = 1.0
var max_hp: float = 1.0
var armor: float = 0.0
var speed: float = 1.0
var spirit_drop: int = 0
## 漏过扣几条命。普通和 Boss 两档都读 stage1_rules.json。
var leak_damage: int = 1
var boss: bool = false
var hit_radius: float = 0.3
var knockback_resist: float = 0.0
var spawn_left: float = 0.0
var knockback_cd: float = 0.0
var born: bool = false
var reaching: bool = false
var dead: bool = false
