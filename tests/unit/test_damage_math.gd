extends GutTest

## 伤害公式：max(攻击 − 护甲, 攻击 × 保底比例)，内部浮点，返回前四舍五入。
## 第一关的保底比例 0.05、最低伤害 0，都读 data/balance/stage1_rules.json。

const RULES_PATH := "res://data/balance/stage1_rules.json"


func test_stage1_rules_use_a_five_percent_floor_and_no_minimum() -> void:
	var rules := _rules()
	assert_almost_eq(float(rules.armor_floor_ratio), 0.05, 0.0001)
	assert_eq(int(rules.min_damage), 0)


func test_armor_uses_the_larger_of_subtraction_and_floor() -> void:
	assert_eq(DamageMath.resolve(22.0, 8.0, 0.05, 0), 14)


func test_high_armor_still_deals_five_percent() -> void:
	assert_eq(DamageMath.resolve(100.0, 200.0, 0.05, 0), 5)
	assert_eq(DamageMath.resolve(30.0, 25.0, 0.05, 0), 5)


func test_floor_can_round_down_to_zero() -> void:
	assert_eq(DamageMath.resolve(9.0, 10.0, 0.05, 0), 0)
	assert_eq(DamageMath.resolve(0.0, 0.0, 0.05, 0), 0)


func test_floor_is_computed_in_floats_then_rounded() -> void:
	# 10 × 0.05 = 0.5，四舍五入到 1；29 × 0.05 = 1.45，四舍五入到 1。
	assert_eq(DamageMath.resolve(10.0, 25.0, 0.05, 0), 1)
	assert_eq(DamageMath.resolve(29.0, 40.0, 0.05, 0), 1)
	assert_eq(DamageMath.resolve(2.5, 0.0, 0.05, 0), 3)


func test_a_positive_minimum_still_applies() -> void:
	assert_eq(DamageMath.resolve(9.0, 10.0, 0.05, 1), 1)


func test_crit_is_applied_before_armor() -> void:
	assert_eq(DamageMath.resolve(22.0 * 1.8, 0.0, 0.05, 0), 40)


func _rules() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(RULES_PATH))
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	return parsed if typeof(parsed) == TYPE_DICTIONARY else {}
