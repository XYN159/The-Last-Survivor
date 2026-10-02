class_name DamageMath
extends RefCounted

## 单次命中的护甲结算。暴击先乘进攻击力，再交给这里。


static func resolve(attack: float, armor: float, floor_ratio: float, min_damage: int) -> int:
	var safe_attack := maxf(attack, 0.0)
	var effective_armor := maxf(armor, 0.0)
	var raw := maxf(safe_attack - effective_armor, safe_attack * floor_ratio)
	return maxi(min_damage, roundi(raw))
