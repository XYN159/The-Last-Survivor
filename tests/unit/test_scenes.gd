extends GutTest

const MAIN_MENU_SCENE := preload("res://scenes/main/main_menu.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/battle_board.tscn")


func test_cjk_font_is_applied_to_the_root() -> void:
	var theme := get_tree().root.theme
	assert_not_null(theme)
	assert_not_null(theme.default_font)


func test_main_menu_shows_game_title() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	var title := menu.get_node("%TitleLabel") as Label
	var subtitle := menu.get_node("%SubtitleLabel") as Label
	assert_eq(title.text, "东方守幻录")
	assert_eq(subtitle.text, "东方 Project 二次创作")


func test_title_shows_the_fanwork_notice() -> void:
	assert_eq(tr("ui.menu.subtitle"), "东方 Project 二次创作")
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	var subtitle := menu.get_node("CenterColumn/SubtitleLabel") as Label
	assert_eq(subtitle.text, tr("ui.menu.subtitle"))
	assert_eq(subtitle.text, "东方 Project 二次创作")


func test_main_menu_has_start_button() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	var button := menu.get_node("%StartButton") as Button
	assert_eq(button.text, "开始")
	var version_label := menu.get_node("%VersionLabel") as Label
	assert_eq(version_label.text, "v0.1.0")


func test_prologue_scenes_use_redrawn_backgrounds() -> void:
	var menu := MAIN_MENU_SCENE.instantiate()
	add_child_autofree(menu)
	var background := menu.get_node("%Background") as TextureRect
	assert_eq(
		background.texture.resource_path,
		"res://assets/art/prologue_01/prologue_title_art.jpg",
	)
	var battle := BATTLE_SCENE.instantiate()
	add_child_autofree(battle)
	var courtyard := battle.get_node("%Background") as TextureRect
	assert_eq(
		courtyard.texture.resource_path,
		"res://assets/art/prologue_01/prologue_battle_courtyard.jpg",
	)
