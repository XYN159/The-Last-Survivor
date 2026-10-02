extends GutTest

const MAIN_MENU_SCENE := preload("res://scenes/main/main_menu.tscn")


func test_cjk_font_is_applied_to_the_root() -> void:
	var theme := get_tree().root.theme
	assert_not_null(theme)
	assert_not_null(theme.default_font)


func test_main_menu_shows_game_title() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	var title := menu.get_node("CenterColumn/TitleLabel") as Label
	var subtitle := menu.get_node("CenterColumn/SubtitleLabel") as Label
	assert_eq(title.text, "东方守幻录")
	assert_eq(subtitle.text, "Touhou Forgotten Defense")


func test_main_menu_has_start_button() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	var button := menu.get_node("%StartButton") as Button
	assert_eq(button.text, "开始")
	var version_label := menu.get_node("%VersionLabel") as Label
	assert_eq(version_label.text, "v0.1.0")
