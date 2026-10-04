extends GutTest

## 战斗界面：放人要先点格子、再点头像、再点方向；升级按钮藏起来，出售改成撤退。

const BATTLE_SCENE := preload("res://scenes/battle/battle_board.tscn")
const PORTRAIT_PATH := "res://assets/art/prologue_01/reimu_portrait.png"
const PLATE_PATH := "res://assets/art/prologue_01/button_plate.png"
const KAI_FONT_PATH := "res://assets/fonts/LXGWWenKai-Regular.ttf"
const BLACK_FONT_PATH := "res://assets/fonts/NotoSansCJKsc-Black.otf"
const HINT_DEFAULT := "先点亮色格子，再点下面的角色，最后选朝向。中段两格最合适。"
const HINT_PICK_FACING := "再点「上」「下」「左」「右」，选她面朝哪边。结界在她面前。"
const FACING_BUTTONS := [
	"FacingUpButton",
	"FacingDownButton",
	"FacingLeftButton",
	"FacingRightButton",
	"FacingCancelButton",
]


func test_battle_board_shows_spirit_life_and_only_reimu() -> void:
	var board := _open()
	var spirit := board.get_node("%SpiritLabel") as Label
	var life := board.get_node("%LifeLabel") as Label
	var wave := board.get_node("%WaveLabel") as Label
	assert_eq(spirit.text, "灵力 10")
	assert_eq(life.text, "生命 10/10")
	assert_eq(wave.text, "残影 0/6  下一只 8 秒")
	var bar := board.get_node("%CharacterBar") as HBoxContainer
	assert_eq(bar.get_child_count(), 1)
	assert_eq((bar.get_child(0) as Button).text, "灵梦\n16")
	var hint := board.get_node("%HintLabel") as Label
	assert_eq(hint.text, HINT_DEFAULT)


func test_call_button_never_shows_on_a_timeline_level() -> void:
	var board := _open()
	var call_button := board.get_node("%CallButton") as Button
	assert_false(call_button.visible)
	_fund(board)
	board._refresh()
	assert_false(call_button.visible)


func test_placement_needs_cell_then_portrait_then_facing() -> void:
	var board := _open()
	var hint := board.get_node("%HintLabel") as Label
	var spirit := board.get_node("%SpiritLabel") as Label
	var panel := board.get_node("%FacingPanel") as Control
	_fund(board)
	board._on_character_pressed("chr_reimu")
	assert_eq(hint.text, "先点亮色格子。")
	assert_false(panel.visible)
	board._on_cell_pressed(2, 4)
	assert_eq(hint.text, "再点下面的角色，放到这一格。")
	board._on_character_pressed("chr_reimu")
	assert_true(panel.visible)
	assert_eq(hint.text, HINT_PICK_FACING)
	assert_eq(_sim(board).view_state().units.size(), 0, "方向没选完，格子上没有角色")
	assert_eq(spirit.text, "灵力 16")
	(board.get_node("%FacingDownButton") as Button).pressed.emit()
	var units: Array = _sim(board).view_state().units
	assert_eq(units.size(), 1)
	assert_eq(units[0].facing, BattleFacing.RIGHT, "棋盘横着画，屏幕的「下」是地图的右")
	assert_eq(spirit.text, "灵力 0")
	assert_false(panel.visible)
	assert_eq(hint.text, HINT_DEFAULT)


func test_cancel_or_another_cell_leaves_the_slot_empty() -> void:
	var board := _open()
	var panel := board.get_node("%FacingPanel") as Control
	_fund(board)
	board._on_cell_pressed(2, 4)
	board._on_character_pressed("chr_reimu")
	(board.get_node("%FacingCancelButton") as Button).pressed.emit()
	assert_false(panel.visible)
	assert_eq(_sim(board).view_state().units.size(), 0)
	board._on_cell_pressed(2, 4)
	board._on_character_pressed("chr_reimu")
	board._on_cell_pressed(4, 4)
	assert_false(panel.visible)
	board._on_facing_pressed("up")
	assert_eq(_sim(board).view_state().units.size(), 0)
	assert_eq(int(_sim(board).view_state().spirit), 16)


func test_portrait_without_enough_spirit_does_not_open_the_facing_panel() -> void:
	var board := _open()
	board._on_cell_pressed(2, 4)
	board._on_character_pressed("chr_reimu")
	assert_false((board.get_node("%FacingPanel") as Control).visible)
	assert_eq((board.get_node("%HintLabel") as Label).text, "放不下。要亮色格子、灵力够；同名只能放一个，撤退后要等一会儿。")


func test_path_cell_is_not_a_slot() -> void:
	var board := _open()
	var hint := board.get_node("%HintLabel") as Label
	_fund(board)
	board._on_cell_pressed(3, 4)
	assert_eq(hint.text, "先点亮色格子。")
	board._on_character_pressed("chr_reimu")
	assert_false((board.get_node("%FacingPanel") as Control).visible)
	assert_eq(_sim(board).view_state().units.size(), 0)


func test_facing_buttons_are_text_on_plates() -> void:
	var board := _open()
	var expected := ["上", "下", "左", "右", "取消"]
	for index in FACING_BUTTONS.size():
		var button_name: String = FACING_BUTTONS[index]
		var button := board.get_node("%" + button_name) as Button
		assert_eq(button.text, expected[index])
		var plate := button.get_node(button_name + "Plate") as TextureRect
		assert_eq(plate.texture.resource_path, PLATE_PATH)
		assert_true(plate.show_behind_parent, button_name)
		assert_eq(button.get_theme_font("font").resource_path, KAI_FONT_PATH)
	assert_eq((board.get_node("%FacingTitle") as Label).text, "选朝向")


func test_screen_directions_map_onto_the_sideways_board() -> void:
	var view := _open().get_node("%BoardView")
	assert_eq(view.call("grid_facing", "down"), BattleFacing.RIGHT)
	assert_eq(view.call("grid_facing", "up"), BattleFacing.LEFT)
	assert_eq(view.call("grid_facing", "left"), BattleFacing.DOWN)
	assert_eq(view.call("grid_facing", "right"), BattleFacing.UP)
	for facing in BattleFacing.ALL:
		var word := str(view.call("screen_facing", facing))
		assert_eq(view.call("grid_facing", word), facing)
	assert_eq(view.call("grid_facing", ""), "")


func test_finishing_the_level_offers_retry_and_title() -> void:
	var board := _open()
	_place(board, 2, 4, "down")
	var sim := _sim(board)
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
	var board := _open()
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
	var board := _open()
	var spirit := board.get_node("%SpiritLabel") as Label
	var life := board.get_node("%LifeLabel") as Label
	var wave := board.get_node("%WaveLabel") as Label
	var spirit_fill := board.get_node("%SpiritFill") as Control
	var life_fill := board.get_node("%LifeFill") as Control
	var wave_fill := board.get_node("%WaveFill") as Control
	assert_eq(spirit_fill.anchor_right, 1.0)
	assert_eq(life_fill.anchor_right, 1.0)
	assert_eq(wave_fill.anchor_right, 1.0)
	_place(board, 2, 4, "down")
	assert_eq(spirit.text, "灵力 0")
	assert_eq(spirit_fill.anchor_right, 0.0)
	assert_lt(wave_fill.anchor_right, 1.0)
	var hint := board.get_node("%HintLabel") as Control
	var speed := board.get_node("%SpeedLabel") as Label
	assert_eq(speed.text, "倍速 ×1")
	assert_eq(speed.mouse_filter, Control.MOUSE_FILTER_IGNORE)
	assert_eq(
		(board.get_node("%SpeedButton") as Control).get_theme_font("font").resource_path,
		BLACK_FONT_PATH
	)
	for control in [spirit, life, wave, hint, speed]:
		assert_eq((control as Control).get_theme_font("font").resource_path, BLACK_FONT_PATH)
		assert_eq((control as Control).get_theme_color("font_color").to_html(false), "f7f4ef")
		assert_eq(
			(control as Control).get_theme_color("font_shadow_color").to_html(false), "30151d"
		)
		assert_eq((control as Control).get_theme_constant("shadow_offset_x"), 3)
		assert_eq((control as Control).get_theme_constant("shadow_offset_y"), 3)
		assert_eq((control as Control).get_theme_constant("outline_size"), 0)


func test_fill_ratio_stays_between_empty_and_full() -> void:
	var board_script: GDScript = BATTLE_SCENE.instantiate().get_script()
	assert_eq(board_script.fill_ratio(5.0, 20.0), 0.25)
	assert_eq(board_script.fill_ratio(30.0, 20.0), 1.0)
	assert_eq(board_script.fill_ratio(-1.0, 20.0), 0.0)
	assert_eq(board_script.fill_ratio(3.0, 0.0), 0.0)


func test_unit_panel_hides_upgrade_and_offers_retreat() -> void:
	var board := _open()
	_place(board, 2, 4, "down")
	board._on_cell_pressed(2, 4)
	assert_true((board.get_node("%UnitPanel") as Control).visible)
	var title := board.get_node("%UnitTitle") as Label
	assert_eq(title.text, "灵梦  朝下")
	assert_eq(
		(title.get_parent() as NinePatchRect).texture.resource_path,
		"res://assets/art/prologue_01/level_plate.png",
	)
	assert_false((board.get_node("%UpgradeButton") as Button).visible)
	for button_name in ["SellButton", "CloseUnitButton"]:
		var button := board.get_node("%" + button_name) as Button
		var plate := button.get_node(button_name + "Plate") as TextureRect
		assert_eq(plate.texture.resource_path, PLATE_PATH)
		assert_true(plate.show_behind_parent, button_name)
		assert_true(button.get_theme_stylebox("normal") is StyleBoxEmpty, button_name)
		assert_eq(button.get_theme_color("font_hover_color"), Color("#FFE2A3"), button_name)
		assert_eq(button.get_theme_font("font").resource_path, KAI_FONT_PATH)
	assert_eq((board.get_node("%SellButton") as Button).text, "撤退 +8")
	assert_eq((board.get_node("%CloseUnitButton") as Button).text, "关闭")


func test_retreat_refunds_half_and_shows_the_wait_on_the_portrait() -> void:
	var board := _open()
	_place(board, 2, 4, "down")
	board._on_cell_pressed(2, 4)
	(board.get_node("%SellButton") as Button).pressed.emit()
	assert_eq(_sim(board).view_state().units.size(), 0)
	assert_eq((board.get_node("%SpiritLabel") as Label).text, "灵力 8")
	assert_false((board.get_node("%UnitPanel") as Control).visible)
	var portrait := board.get_node("%CharacterBar").get_child(0) as Button
	assert_true(portrait.disabled)
	var label := board._roster_labels["chr_reimu"] as Label
	assert_eq(label.text, "灵梦  20 秒")


func _open() -> Node:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	return board


func _sim(board: Node) -> BattleSim:
	return board.get("_sim")


## 跳过 6 秒，让灵力从 10 回到 16，够放一个灵梦。
func _fund(board: Node) -> void:
	for _step in 6 * 60:
		_sim(board).tick()
	board._refresh()


func _place(board: Node, col: int, row: int, screen_dir: String) -> void:
	_fund(board)
	board._on_cell_pressed(col, row)
	board._on_character_pressed("chr_reimu")
	board._on_facing_pressed(screen_dir)
