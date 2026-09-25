extends GutTest

## 数值配置的纯逻辑测试，不依赖场景。


func test_squad_grows_by_gate_bonus() -> void:
	var config := (
		BalanceConfig
		. from_dictionary(
			{
				"starting_squad_size": 5,
				"gate_bonus_per_upgrade": 2,
				"starting_supplies": 10,
			}
		)
	)
	assert_eq(config.squad_size_after_gates(4), 13)
	assert_eq(config.starting_supplies, 10)


func test_negative_gate_count_does_not_shrink_squad() -> void:
	var config := (
		BalanceConfig
		. from_dictionary(
			{
				"starting_squad_size": 3,
				"gate_bonus_per_upgrade": 2,
			}
		)
	)
	assert_eq(config.squad_size_after_gates(-5), 3)


func test_squad_size_never_starts_below_one() -> void:
	var config := BalanceConfig.from_dictionary({"starting_squad_size": 0})
	assert_eq(config.starting_squad_size, 1)


func test_project_balance_file_loads() -> void:
	var config := BalanceConfig.load_from_json_file("res://data/balance/starting_balance.json")
	assert_eq(config.starting_squad_size, 1)
	assert_eq(config.gate_bonus_per_upgrade, 1)
	assert_eq(config.starting_supplies, 0)
	assert_eq(config.squad_size_after_gates(3), 4)


func test_invalid_json_falls_back_to_defaults() -> void:
	var config := BalanceConfig.from_json_text("not-json")
	assert_eq(config.starting_squad_size, 1)
	assert_eq(config.gate_bonus_per_upgrade, 1)
