extends GutTest


func test_cjk_font_is_applied_to_the_root() -> void:
	var theme := get_tree().root.theme
	assert_not_null(theme)
	assert_not_null(theme.default_font)


func test_main_menu_has_start_button() -> void:
	var scene := load("res://scenes/main/main_menu.tscn") as PackedScene
	var menu := scene.instantiate()
	add_child_autofree(menu)
	var button := menu.get_node("%StartButton") as Button
	assert_eq(button.text, "开始")
	var version_label := menu.get_node("%VersionLabel") as Label
	assert_eq(version_label.text, "v0.1.0")


func test_battle_lane_shows_configured_squad_size() -> void:
	var scene := load("res://scenes/battle/battle_lane.tscn") as PackedScene
	var lane := scene.instantiate()
	add_child_autofree(lane)
	var status := lane.get_node("%StatusLabel") as Label
	var expected := "小队人数：%d" % GameState.squad_size
	assert_eq(status.text, expected)
	assert_eq(GameState.squad_size, 1)
