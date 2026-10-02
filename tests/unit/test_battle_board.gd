extends GutTest

const BATTLE_SCENE := preload("res://scenes/battle/battle_board.tscn")


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
