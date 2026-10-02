extends GutTest

## 序章第一关的动效：进关、放置、按钮、受击、结算都会播放，
## 而且不挡路线、不挡顶栏数字、不挡点击，也不改规则。
## 动效按手动步长推进，测试里关掉各节点自己的 _process，结果每次一样。

const BATTLE_SCENE := preload("res://scenes/battle/battle_board.tscn")
const MENU_SCENE := preload("res://scenes/main/main_menu.tscn")
const STEP := 1.0 / 60.0
const SLOTS := [Vector2i(2, 1), Vector2i(2, 4), Vector2i(4, 4)]

var _config := MotionConfig.load_default()


func test_entry_starts_dark_with_bars_off_screen() -> void:
	var board := _open_battle()
	var screen := _screen(board)
	var veil := board.get_node("%EntryVeil") as ColorRect
	assert_true(screen.call("is_entry_playing"))
	assert_true(veil.visible)
	assert_gt(veil.color.a, 0.9)
	var top := board.get_node("%TopBar") as Control
	var bottom := board.get_node("%BottomBar") as Control
	assert_lt(top.position.y, (screen.call("base_position", top) as Vector2).y)
	assert_gt(bottom.position.y, (screen.call("base_position", bottom) as Vector2).y)


func test_entry_settles_and_leaves_nothing_in_the_way() -> void:
	var board := _open_battle()
	var screen := _screen(board)
	_step(screen, float(screen.call("entry_duration")) + STEP)
	var veil := board.get_node("%EntryVeil") as ColorRect
	assert_false(screen.call("is_entry_playing"))
	assert_false(veil.visible)
	assert_eq(veil.color.a, 0.0)
	for node_name in ["TopFrame", "TopBar", "SpeedButton", "BottomBar"]:
		var node := board.get_node("%" + node_name) as Control
		assert_eq(node.position, screen.call("base_position", node), node_name)


func test_motion_layers_never_take_clicks() -> void:
	var board := _open_battle()
	var paths := [
		"%EntryVeil",
		"%BoardMotion",
		"%ResultMotes",
		"%ResultCard",
		"%CardSeal",
		"%ResultCard/CardPaper",
		"%ResultCard/CardFrame",
		"%TopBar/LifeSlot",
	]
	for path in paths:
		var node := board.get_node(path) as Control
		assert_eq(node.mouse_filter, Control.MOUSE_FILTER_IGNORE, path)


func test_cells_can_be_picked_while_the_entry_plays() -> void:
	var board := _open_battle()
	assert_true(_screen(board).call("is_entry_playing"))
	board.call("_on_cell_pressed", 2, 4)
	board.call("_on_character_pressed", "chr_reimu")
	var sim: BattleSim = board.get("_sim")
	assert_eq(sim.view_state().units.size(), 1)


func test_picking_a_slot_flashes_its_yin_yang() -> void:
	var board := _open_battle()
	var motion := _motion(board)
	board.call("_on_cell_pressed", 2, 4)
	assert_eq(motion.call("active_count", "select"), 1)
	_step(motion, 1.0)
	assert_eq(motion.call("active_count", "select"), 0)


func test_path_cell_does_not_flash() -> void:
	var board := _open_battle()
	board.call("_on_cell_pressed", 3, 4)
	assert_eq(_motion(board).call("active_count", "select"), 0)


func test_placing_reimu_lands_like_a_stamp() -> void:
	var board := _open_battle()
	var motion := _motion(board)
	var unit_id := _place(board, 2, 4)
	assert_gt(float(motion.call("unit_scale", unit_id)), 1.2)
	_step(motion, _config.number("place", "stamp_sec", 0.2))
	assert_lt(float(motion.call("unit_scale", unit_id)), 1.0)
	_step(motion, 1.0)
	assert_eq(float(motion.call("unit_scale", unit_id)), 1.0)


func test_placing_reimu_opens_a_barrier_and_throws_papers() -> void:
	var board := _open_battle()
	var motion := _motion(board)
	_place(board, 2, 4)
	_step(motion, _config.number("place", "stamp_sec", 0.2) + STEP)
	assert_eq(motion.call("active_count", "ring"), 1)
	assert_eq(motion.call("active_count", "paper"), _config.count("place", "paper_count", 6))
	_step(motion, 1.0)
	assert_eq(motion.call("active_count", "ring"), 0)
	assert_eq(motion.call("active_count", "paper"), 0)


func test_placement_effects_stay_off_the_route() -> void:
	var board := _open_battle()
	var motion := _motion(board)
	var route: Array[Vector2] = board.get_node("%BoardView").call("route_points")
	var clear := float(motion.call("route_clear_px"))
	assert_gt(route.size(), 1)
	for slot in SLOTS:
		motion.call("play_select", slot.x, slot.y)
		motion.call("play_place", slot.x, slot.y, 99)
		var closest := INF
		var sampled := 0
		for _frame in 60:
			for rect_v in motion.call("placement_rects"):
				closest = minf(closest, _rect_to_route(rect_v, route))
				sampled += 1
			motion.call("advance", STEP)
		assert_gt(sampled, 0)
		assert_gte(closest, clear, "slot %s" % slot)


func test_call_button_shrinks_then_rebounds() -> void:
	var board := _open_battle()
	var button := board.get_node("%CallButton") as Button
	var frame := board.get_node("%CallFrame") as Control
	_assert_press_rebound(button, frame)


func test_start_button_shrinks_then_rebounds() -> void:
	var menu := MENU_SCENE.instantiate()
	add_child_autofree(menu)
	var button := menu.get_node("%StartButton") as Button
	var frame := menu.get_node("%StartFrame") as Control
	_assert_press_rebound(button, frame)


func test_hits_splash_light_points() -> void:
	var board := _open_battle()
	var motion := _motion(board)
	board.call("_note_events", [{"type": "damage", "x": 3.5, "y": 6.0, "amount": 10, "id": 1}])
	assert_eq(motion.call("active_count", "spark"), _config.count("hit", "spark_count", 4))
	_step(motion, 1.0)
	assert_eq(motion.call("active_count", "spark"), 0)


func test_kill_motes_fly_to_spirit_without_covering_the_numbers() -> void:
	var board := _open_battle()
	await wait_process_frames(2)
	var motion := _motion(board)
	watch_signals(motion)
	board.call("_note_events", [{"type": "death", "x": 3.5, "y": 6.0, "spirit": 5, "id": 1}])
	assert_eq(motion.call("active_count", "mote"), _config.count("kill", "mote_count", 5))
	var to_local := (motion as Control).get_global_transform().affine_inverse()
	var label_rects: Array[Rect2] = []
	for label_name in ["SpiritLabel", "LifeLabel", "WaveLabel"]:
		var label := board.get_node("%" + label_name) as Label
		var rect := label.get_global_rect()
		var text_width := label.get_minimum_size().x
		var text_rect := Rect2(
			rect.get_center() - Vector2(text_width, label.get_minimum_size().y) * 0.5,
			Vector2(text_width, label.get_minimum_size().y),
		)
		label_rects.append(Rect2(to_local * text_rect.position, text_rect.size))
	var target: Vector2 = motion.call("spirit_target_point")
	var radius := float(motion.call("mote_radius"))
	var last_distance := INF
	for _frame in 60:
		motion.call("advance", STEP)
		for point in motion.call("mote_points"):
			for rect in label_rects:
				assert_false(rect.grow(radius).has_point(point), "光点压到顶栏数字 %s" % point)
			last_distance = (point as Vector2).distance_to(target)
	assert_lt(last_distance, 60.0)
	assert_eq(motion.call("active_count", "mote"), 0)
	assert_signal_emitted(motion, "spirit_mote_arrived")


func test_leak_cracks_the_barrier_and_shakes_life() -> void:
	var board := _open_battle()
	var screen := _screen(board)
	var label := board.get_node("%LifeLabel") as Label
	var before := label.position
	board.call("_note_events", [{"type": "leak", "amount": 1, "x": 3.5, "y": 11.5}])
	assert_eq(_motion(board).call("active_count", "crack"), 1)
	assert_true(screen.call("is_life_shaking"))
	_step(screen, 0.02)
	assert_ne(label.position.x, before.x)
	_step(screen, 1.0)
	assert_false(screen.call("is_life_shaking"))
	assert_eq(label.position, before)


func test_result_card_unfolds_like_paper() -> void:
	var board := _open_battle()
	var screen := _screen(board)
	board.call("_show_result", _result_state(BattleSim.PHASE_VICTORY))
	var card := board.get_node("%ResultCard") as Control
	var column := board.get_node("%ResultColumn") as Control
	assert_true(screen.call("is_result_playing"))
	assert_lt(card.scale.y, 0.2)
	assert_eq(column.modulate.a, 0.0)
	_step(screen, float(screen.call("result_duration")) + STEP)
	assert_eq(card.scale, Vector2.ONE)
	assert_eq(column.modulate.a, 1.0)
	assert_true((board.get_node("%RetryButton") as Button).visible)


func test_win_motes_rise_in_gold() -> void:
	var board := _open_battle()
	board.call("_show_result", _result_state(BattleSim.PHASE_VICTORY))
	var motes := board.get_node("%ResultMotes")
	assert_true(motes.call("is_rising"))
	var gold: Color = motes.call("mote_color")
	assert_gt(gold.r, gold.b + 0.3)
	assert_gt(_share_moving(motes, -1.0), 0.8)


func test_loss_motes_fall_in_grey() -> void:
	var board := _open_battle()
	board.call("_show_result", _result_state(BattleSim.PHASE_DEFEAT))
	var motes := board.get_node("%ResultMotes")
	assert_false(motes.call("is_rising"))
	var grey: Color = motes.call("mote_color")
	assert_lt(absf(grey.r - grey.b), 0.1)
	assert_gt(_share_moving(motes, 1.0), 0.8)


func _open_battle() -> Node:
	var board := BATTLE_SCENE.instantiate()
	add_child_autofree(board)
	board.set_process(false)
	_screen(board).set_process(false)
	board.get_node("%ResultMotes").set_process(false)
	return board


func _screen(board: Node) -> Node:
	return board.get_node("%ScreenMotion")


func _motion(board: Node) -> Node:
	return board.get_node("%BoardMotion")


func _step(node: Node, seconds: float) -> void:
	var steps := ceili(seconds / STEP)
	for _frame in steps:
		node.call("advance", STEP)


func _place(board: Node, col: int, row: int) -> int:
	board.call("_on_cell_pressed", col, row)
	board.call("_on_character_pressed", "chr_reimu")
	var sim: BattleSim = board.get("_sim")
	for unit_v in sim.view_state().units:
		if int(unit_v.col) == col and int(unit_v.row) == row:
			return int(unit_v.id)
	return -1


func _assert_press_rebound(button: Button, frame: Control) -> void:
	var press := button.get_node("PressMotion")
	press.set_process(false)
	var press_scale := _config.number("button", "press_scale", 0.92)
	button.button_down.emit()
	_step(press, _config.number("button", "press_sec", 0.07) + STEP)
	assert_almost_eq(button.scale.x, press_scale, 0.001)
	assert_almost_eq(frame.scale.x, press_scale, 0.001)
	button.button_up.emit()
	var peak := 0.0
	for _frame in ceili(_config.number("button", "release_sec", 0.26) / STEP) + 1:
		press.call("advance", STEP)
		peak = maxf(peak, button.scale.x)
	assert_gt(peak, 1.0, "松开时要冲过原大小再回落")
	assert_eq(button.scale, Vector2.ONE)
	assert_eq(frame.scale, Vector2.ONE)


func _result_state(outcome: String) -> Dictionary:
	return {
		"outcome": outcome,
		"level_name": "神社的直路",
		"guard_hp": 20 if outcome == BattleSim.PHASE_VICTORY else 0,
		"guard_max_hp": 20,
		"spirit": 100,
	}


## 先让所有光点都出生，再看一小段时间里朝 direction（-1 向上，1 向下）走的比例。
func _share_moving(motes: Node, direction: float) -> float:
	_step(motes, _config.number("result", "mote_life_sec", 2.4) + STEP)
	var before: Array[Vector2] = motes.call("mote_points")
	motes.call("advance", 0.1)
	var after: Array[Vector2] = motes.call("mote_points")
	assert_eq(before.size(), after.size())
	var moving := 0
	for index in before.size():
		if (after[index].y - before[index].y) * direction > 0.0:
			moving += 1
	return float(moving) / float(maxi(before.size(), 1))


func _rect_to_route(rect: Rect2, route: Array[Vector2]) -> float:
	var closest := INF
	for index in range(route.size() - 1):
		var start := route[index]
		var finish := route[index + 1]
		var samples := maxi(int(start.distance_to(finish) / 4.0), 1)
		for sample in samples + 1:
			var point := start.lerp(finish, float(sample) / float(samples))
			closest = minf(closest, point.distance_to(point.clamp(rect.position, rect.end)))
	return closest
