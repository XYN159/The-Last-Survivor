class_name BattleShot
extends RefCounted

## 灵梦打出的一张符札。伤害在发射时就算好，卖出角色之后它仍会命中。

var instance_id: int = 0
var character_id: String = ""
var target_id: int = -1
var x: float = 0.0
var y: float = 0.0
var direction: Vector2 = Vector2.DOWN
var speed: float = 7.0
var turn_deg: float = 540.0
var life: float = 1.5
var hit_radius: float = 0.25
var retarget_radius: float = 1.5
var attack_power: float = 0.0
var knockback: float = 0.1
var heavy: bool = false
