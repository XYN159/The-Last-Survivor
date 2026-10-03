extends GutTest

const BATTLE_SCENE := preload("res://scenes/battle/battle_board.tscn")
const PORTRAIT_PATH := "res://assets/art/prologue_01/reimu_portrait.png"
const KAI_FONT_PATH := "res://assets/fonts/LXGWWenKai-Regular.ttf"


func test_battle_board_shows_spirit_life_and_only_reimu() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var spirit := board.get_node("%SpiritLabel") as Label
	var life := board.get_node("%LifeLabel") as Label
	var wave := board.get_node("%WaveLabel") as Label
	assert_eq(spirit.text, "灵力 150")
	assert_eq(life.text, "生命 20/20")
	assert_eq(wave.text, "布阵 10 秒")
	var bar := board.get_node("%CharacterBar") as HBoxContainer
	assert_eq(bar.get_child_count(), 1)
	assert_eq((bar.get_child(0) as Button).text, "灵梦\n50")
	var call_button := board.get_node("%CallButton") as Button
	assert_eq(call_button.text, "出击 +10")
	var hint := board.get_node("%HintLabel") as Label
	assert_eq(hint.text, "先点亮色格子，再点下面的角色。中段两格最合适。")


func test_placement_selects_a_cell_before_the_character() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	board._on_character_pressed("chr_reimu")
	var hint := board.get_node("%HintLabel") as Label
	var spirit := board.get_node("%SpiritLabel") as Label
	assert_eq(hint.text, "先点亮色格子。")
	assert_eq(spirit.text, "灵力 150")
	board._on_cell_pressed(2, 4)
	assert_eq(hint.text, "再点下面的角色，放到这一格。")
	board._on_character_pressed("chr_reimu")
	assert_eq(spirit.text, "灵力 100")
	assert_eq(hint.text, "先点亮色格子，再点下面的角色。中段两格最合适。")


func test_path_cell_is_not_a_slot() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var hint := board.get_node("%HintLabel") as Label
	var spirit := board.get_node("%SpiritLabel") as Label
	board._on_cell_pressed(3, 4)
	assert_eq(hint.text, "先点亮色格子。")
	board._on_character_pressed("chr_reimu")
	assert_eq(spirit.text, "灵力 150")


func test_start_button_only_shows_while_deploying() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var call_button := board.get_node("%CallButton") as Button
	assert_true(call_button.visible)
	board._on_call_pressed()
	assert_false(call_button.visible)


func test_finishing_the_level_offers_retry_and_title() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	board._on_cell_pressed(2, 4)
	board._on_character_pressed("chr_reimu")
	board._on_cell_pressed(4, 4)
	board._on_character_pressed("chr_reimu")
	var sim: BattleSim = board._sim
	var guard := 0
	while str(sim.view_state().outcome) == "" and guard < 300000:
		sim.tick()
		guard += 1
	board._show_result(sim.view_state())
	var panel := board.get_node("%ResultPanel") as Control
	var title := board.get_node("%ResultTitle") as Label
	var body := board.get_node("%ResultBody") as Label
	assert_true(panel.visible)
	assert_eq(title.text, "守住了")
	assert_true(body.text.begins_with("神社的直路"), body.text)
	assert_eq((board.get_node("%RetryButton") as Button).text, "再打一次")
	assert_eq((board.get_node("%MenuButton") as Button).text, "继续")


func test_portrait_shows_the_whole_reimu() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var portrait := board.get_node("%PortraitImage") as TextureRect
	assert_eq(portrait.texture.resource_path, PORTRAIT_PATH)
	assert_ne(portrait.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert_eq(portrait.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_CENTERED)
	# 槽位是竖版 3:4，和立绘同比例，整张图都看得见。
	assert_almost_eq(portrait.size.x / portrait.size.y, 0.75, 0.01)
	var name_label := board.get_node("%PortraitName") as Label
	assert_eq(tr(name_label.text), "灵梦")
	assert_false(portrait.get_rect().intersects(name_label.get_rect()))


func test_status_bars_fill_from_the_state() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var spirit := board.get_node("%SpiritLabel") as Label
	var life := board.get_node("%LifeLabel") as Label
	var wave := board.get_node("%WaveLabel") as Label
	assert_eq(spirit.text, "灵力 150")
	assert_eq(life.text, "生命 20/20")
	assert_eq(wave.text, "布阵 10 秒")
	var spirit_fill := board.get_node("%SpiritFill") as Control
	var life_fill := board.get_node("%LifeFill") as Control
	var wave_fill := board.get_node("%WaveFill") as Control
	assert_eq(spirit_fill.anchor_right, 1.0)
	assert_eq(life_fill.anchor_right, 1.0)
	assert_eq(wave_fill.anchor_right, 1.0)
	board._on_cell_pressed(2, 4)
	board._on_character_pressed("chr_reimu")
	assert_eq(spirit.text, "灵力 100")
	assert_almost_eq(spirit_fill.anchor_right, 100.0 / 150.0, 0.001)
	for label in [spirit, life, wave]:
		assert_eq((label as Label).get_theme_font("font").resource_path, KAI_FONT_PATH)


func test_fill_ratio_stays_between_empty_and_full() -> void:
	var board_script: GDScript = BATTLE_SCENE.instantiate().get_script()
	assert_eq(board_script.fill_ratio(5.0, 20.0), 0.25)
	assert_eq(board_script.fill_ratio(30.0, 20.0), 1.0)
	assert_eq(board_script.fill_ratio(-1.0, 20.0), 0.0)
	assert_eq(board_script.fill_ratio(3.0, 0.0), 0.0)


func test_unit_panel_text_sits_on_plates() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	board._on_cell_pressed(2, 4)
	board._on_character_pressed("chr_reimu")
	board._on_cell_pressed(2, 4)
	assert_true((board.get_node("%UnitPanel") as Control).visible)
	var title := board.get_node("%UnitTitle") as Label
	assert_eq(title.text, "灵梦  1 级")
	assert_eq(
		(title.get_parent() as NinePatchRect).texture.resource_path,
		"res://assets/art/prologue_01/level_plate.png",
	)
	for button_name in ["UpgradeButton", "SellButton", "CloseUnitButton"]:
		var button := board.get_node("%" + button_name) as Button
		var plate := button.get_node(button_name + "Plate") as TextureRect
		assert_eq(plate.texture.resource_path, "res://assets/art/prologue_01/button_plate.png")
		assert_true(plate.show_behind_parent, button_name)
		assert_true(button.get_theme_stylebox("normal") is StyleBoxEmpty, button_name)
		assert_eq(button.get_theme_color("font_hover_color"), Color("#FFE2A3"), button_name)
		assert_eq(button.get_theme_font("font").resource_path, KAI_FONT_PATH)
	assert_eq((board.get_node("%UpgradeButton") as Button).text, "升级 40")
	assert_eq((board.get_node("%SellButton") as Button).text, "出售 +35")
	assert_eq((board.get_node("%CloseUnitButton") as Button).text, "关闭")
