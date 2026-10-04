class_name DamageMath
extends RefCounted

## 单次命中的护甲结算。暴击先乘进攻击力，再交给这里。
## 伤害 = max(攻击 − 护甲, 攻击 × 保底比例)。中间全用浮点，返回前才四舍五入。
## 保底比例和最低伤害来自 data/balance/stage1_rules.json；最低伤害是 0 时，结果可以是 0。


static func resolve(attack: float, armor: float, floor_ratio: float, min_damage: int) -> int:
	var safe_attack := maxf(attack, 0.0)
	var effective_armor := maxf(armor, 0.0)
	var raw := maxf(safe_attack - effective_armor, safe_attack * maxf(floor_ratio, 0.0))
	return maxi(maxi(min_damage, 0), roundi(raw))
