class_name BattleEconomy
extends RefCounted

## 一局里的灵力、撤退和再部署等待。数字全部来自 CombatCatalog.tuning，
## 也就是 data/balance/stage1_rules.json：每秒回灵、灵力上限、撤退返还比例、
## 再部署加价（每撤退一次加一档，最多几档）、撤退后要等几秒才能再放。

var spirit: int = 0
var max_spirit: int = 0
var _regen_per_sec: float = 0.0
## 不满一点的回灵先攒在这里，满一点才加进 spirit。
var _progress: float = 0.0
var _refund_ratio: float = 0.0
var _cost_step: float = 0.0
var _cost_stacks_max: int = 0
var _respawn_sec: float = 0.0
## 角色 id → 本局已撤退次数。
var _retreats: Dictionary = {}
## 角色 id → 还要等几秒才能再放。
var _respawn_left: Dictionary = {}


static func from_tuning(tune: Dictionary) -> BattleEconomy:
	var economy := BattleEconomy.new()
	economy.max_spirit = int(tune.max_spirit)
	economy.spirit = int(tune.starting_spirit)
	economy._regen_per_sec = float(tune.spirit_regen_per_sec)
	economy._refund_ratio = float(tune.retreat_refund_ratio)
	economy._cost_step = float(tune.redeploy_cost_step)
	economy._cost_stacks_max = int(tune.redeploy_cost_stacks_max)
	economy._respawn_sec = float(tune.respawn_sec)
	return economy


func advance(dt: float) -> void:
	_regen(dt)
	for id_v in _respawn_left.keys():
		var left := float(_respawn_left[id_v]) - dt
		if left <= 0.000001:
			_respawn_left.erase(id_v)
		else:
			_respawn_left[id_v] = left


## 加灵力，超过上限的部分丢掉。
func gain(amount: int) -> void:
	spirit = clampi(spirit + amount, 0, maxi(max_spirit, spirit))


func spend(amount: int) -> void:
	spirit -= amount


## 再放费用 = 基础费用 × (1 + 加价比例 × 已撤退次数)，撤退次数最多算到上限。
func deploy_cost(character_id: String, base_cost: int) -> int:
	var stacks := mini(retreats(character_id), _cost_stacks_max)
	return roundi(float(base_cost) * (1.0 + _cost_step * float(stacks)))


## 撤退返还本次部署费用的一半，向下取整。
func refund(spent: int) -> int:
	return floori(float(spent) * _refund_ratio + 0.000001)


func record_retreat(character_id: String, spent: int) -> void:
	gain(refund(spent))
	_retreats[character_id] = retreats(character_id) + 1
	if _respawn_sec > 0.0:
		_respawn_left[character_id] = _respawn_sec


func retreats(character_id: String) -> int:
	return int(_retreats.get(character_id, 0))


func respawn_wait(character_id: String) -> float:
	return float(_respawn_left.get(character_id, 0.0))


func _regen(dt: float) -> void:
	if spirit >= max_spirit:
		_progress = 0.0
		return
	_progress += _regen_per_sec * dt
	var whole := floori(_progress + 0.000001)
	if whole <= 0:
		return
	_progress = maxf(_progress - float(whole), 0.0)
	gain(whole)
