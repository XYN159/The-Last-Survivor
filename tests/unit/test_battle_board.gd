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
	assert_eq(call_button.text, "开始 +10")
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
	assert_eq((board.get_node("%MenuButton") as Button).text, "返回标题")


func test_entry_opens_with_a_veil_and_the_level_ofuda() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var veil := board.get_node("%EntryVeil") as ColorRect
	var ofuda := board.get_node("%EntryOfuda") as Control
	var ofuda_label := board.get_node("%EntryOfudaLabel") as Label
	assert_true(veil.visible)
	assert_true(ofuda.visible)
	assert_eq(ofuda_label.text, "神\n社\n的\n直\n路")


func test_ofuda_stays_left_of_the_route_and_below_the_top_bar() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var ofuda := board.get_node("%EntryOfuda") as Control
	var top_bar := board.get_node("%TopBar") as Control
	var board_view := board.get_node("%BoardView") as Control
	var route_left := board_view.position.x + 3.0 * 128.0
	var slot_left := board_view.position.x + 2.0 * 128.0
	assert_lt(ofuda.position.x + ofuda.size.x, minf(route_left, slot_left))
	assert_gt(ofuda.position.y, top_bar.size.y)


func test_every_battle_button_has_press_feedback() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	for unique in ["%CallButton", "%SpeedButton", "%RetryButton", "%MenuButton", "%SellButton"]:
		var button := board.get_node(unique) as Button
		assert_not_null(button.get_node_or_null("ButtonMotion"), unique)
	var bar := board.get_node("%CharacterBar") as HBoxContainer
	assert_not_null(bar.get_child(0).get_node_or_null("ButtonMotion"))


func test_placing_plays_the_seal_and_landing() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var motion: Node = board.get_node("%BoardMotion")
	var before := int(motion.call("active_effect_count"))
	board._on_cell_pressed(2, 4)
	board._on_character_pressed("chr_reimu")
	assert_gt(int(motion.call("active_effect_count")), before)
	assert_eq((motion.call("unit_scales") as Dictionary).size(), 1)


func test_result_card_unrolls_and_tints_the_title() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var sim: BattleSim = board._sim
	var guard := 0
	while str(sim.view_state().outcome) == "" and guard < 300000:
		sim.tick()
		guard += 1
	board._show_result(sim.view_state())
	var card := board.get_node("%ResultCard") as Control
	var title := board.get_node("%ResultTitle") as Label
	var motes := board.get_node("%ResultMotes") as CPUParticles2D
	assert_eq(title.text, "失守了")
	assert_eq(title.get_theme_color("font_color"), Color("#5A6068"))
	assert_lt(card.scale.y, 1.0)
	assert_true(motes.emitting)
	assert_false((board.get_node("%EntryOfuda") as Control).visible)
	await wait_seconds(1.0)
	assert_almost_eq(card.scale.y, 1.0, 0.01)


func test_retry_fades_out_before_reloading() -> void:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	var veil := board.get_node("%EntryVeil") as ColorRect
	await wait_seconds(0.8)
	assert_false(veil.visible)
	board._leave(func() -> void: pass)
	assert_true(veil.visible)
