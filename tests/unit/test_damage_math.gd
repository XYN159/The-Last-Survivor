extends GutTest

## 伤害公式：max(攻击 − 护甲, 攻击 × 保底比例)，再四舍五入，至少 1。


func test_armor_uses_the_larger_of_subtraction_and_floor() -> void:
	assert_eq(DamageMath.resolve(22.0, 8.0, 0.2, 1), 14)


func test_high_armor_still_deals_twenty_percent() -> void:
	assert_eq(DamageMath.resolve(10.0, 100.0, 0.2, 1), 2)


func test_half_rounds_away_from_zero_and_respects_minimum() -> void:
	assert_eq(DamageMath.resolve(2.5, 0.0, 0.2, 1), 3)
	assert_eq(DamageMath.resolve(0.2, 0.0, 0.2, 1), 1)


func test_crit_is_applied_before_armor() -> void:
	assert_eq(DamageMath.resolve(22.0 * 1.8, 0.0, 0.2, 1), 40)
