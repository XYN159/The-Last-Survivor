extends SceneTree

## 60 秒宣传 PV 的实机录制。一段一个进程，用 PV_SEGMENT 选择。
## 只模拟点击和战斗规则里已有的操作，不加灵力、不改数值。
## 用法见同目录 README.md。

const FLOW_SCENE := "res://scenes/main/original_flow.tscn"
const BATTLE_SCENE := "res://scenes/battle/battle_board.tscn"
const REIMU := "chr_reimu"
const FPS := 60
const CELL_FIRST := Vector2i(2, 4)
const CELL_SECOND := Vector2i(4, 4)
const CELL_THIRD := Vector2i(2, 1)
const GOAL_THIRD := "third"
const GOAL_UPGRADE := "upgrade"
const GOAL_BRAWL := "brawl"
const GOAL_ENDING := "ending"

var _segment := ""
var _timeline_path := ""
var _lines: PackedStringArray = []
var _frame0 := 0
var _fallback_clicks := 0


func _initialize() -> void:
	_segment = OS.get_environment("PV_SEGMENT").strip_edges()
	_timeline_path = OS.get_environment("PV_TIMELINE").strip_edges()
	Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	_run.call_deferred()


func _run() -> void:
	_frame0 = Engine.get_frames_drawn()
	_note("片段 %s" % _segment)
	_note("视口 %s，渲染 %s" % [str(root.size), RenderingServer.get_current_rendering_method()])
	match _segment:
		"test":
			await _run_test()
		"probe":
			_run_probe()
		"R1":
			await _run_r1()
		"R2":
			await _run_r2()
		"R3":
			await _run_r3()
		"R4a":
			await _run_r4a()
		"R4b":
			await _run_r4b()
		"R5":
			await _run_r5()
		"R6x1":
			await _run_r6(1)
		"R6x2":
			await _run_r6(2)
		"R7":
			await _run_r7()
		"R8":
			await _run_r8()
		"R9place":
			await _run_r3()
		"R9upgrade":
			await _run_r5()
		_:
			push_error("未知片段：%s" % _segment)
			quit(1)
			return
	_note("点击没落到控件上、改走按钮回调的次数：%d" % _fallback_clicks)
	_flush_timeline()
	quit()


func _run_test() -> void:
	var board := _mount_battle(false)
	_roll(board)
	_mark("测试片：布阵画面，确认不是黑屏")
	await _wait(0.4)
	await _tap_cell(board, CELL_FIRST, "点直路中段左（推荐的第一格）")
	await _wait(0.3)
	await _tap_reimu(board, "点灵梦头像")
	await _wait(1.0)
	_mark("测试片结束，场上单位 %d" % (_state(board).units as Array).size())


func _run_probe() -> void:
	var catalog := CombatCatalog.load_default()
	var tune := catalog.tuning()
	print(
		(
			"PROBE tune spirit=%s per_wave=%s deploy=%s"
			% [str(tune.starting_spirit), str(tune.spirit_per_wave), str(tune.deploy_time_sec)]
		)
	)
	_probe_path(GOAL_THIRD)
	_probe_path(GOAL_UPGRADE)
	_probe_path(GOAL_BRAWL)
	_probe_path(GOAL_ENDING)


func _probe_path(goal: String) -> void:
	var board := _mount_battle(false)
	board.set_process(false)
	print("PROBE goal %s" % goal)
	_farm(board, goal)
	print("PROBE %s" % _summary(board))
	board.free()
	current_scene = null


func _run_r1() -> void:
	var flow := _mount(FLOW_SCENE)
	flow.call("reset_to", "home")
	await process_frame
	_mark("主界面，片头余量")
	await _wait(1.0)
	_mark("主界面停留")
	await _wait(2.5)
	await _tap_hotspot(flow, "sortie", "chapter", "点出击")
	await _wait(2.0)
	await _tap_hotspot(flow, "chapter_sakura", "stage_map", "点樱花章节")
	await _wait(2.0)
	await _tap_hotspot(flow, "stage_node", "stage_detail", "点关卡节点")
	_mark("关卡详情多停 1 秒，看残影剪影")
	await _wait(3.0)
	await _tap_hotspot(flow, "start_operation", "squad", "点关卡详情里的开始，进入编队")
	await _wait(2.0)
	await _tap_hotspot(flow, "start_battle", "dialogue", "点编队里的开始作战")
	_mark("剧情页出现，再留 1 秒")
	await _wait(1.0)


func _run_r2() -> void:
	_mount_battle(true)
	_mark("进关第一帧，暗幕开始淡开")
	await _wait(5.0)
	_mark("入场后停在布阵。进关从第一帧就开始，前面没有可垫的 1 秒")


func _run_r3() -> void:
	var board := _mount_battle(false)
	_roll(board)
	_mark("布阵，片头余量")
	await _wait(1.0)
	_mark("布阵停留")
	await _wait(1.0)
	await _place_on_camera(board, CELL_FIRST, "直路中段左，推荐的第一格")
	_mark("盖章、结界圈、符纸之后再停")
	await _wait(1.5)
	_mark("片尾余量")
	await _wait(1.0)


func _run_r4a() -> void:
	var board := _mount_battle(false)
	board.set_process(false)
	if not _place_quiet(board, CELL_FIRST):
		_note("准备时第一位没有放下")
	_roll(board)
	_mark("第一位已经在直路中段左，片头余量")
	await _wait(1.0)
	await _place_on_camera(board, CELL_SECOND, "直路中段右，第二位")
	await _wait(1.0)
	_mark("第二位放置结束")


func _run_r4b() -> void:
	var board := _mount_battle(false)
	board.set_process(false)
	_farm(board, GOAL_THIRD)
	_roll(board)
	_mark("灵力够放第三位。%s" % _summary(board))
	await _wait(1.0)
	await _place_on_camera(board, CELL_THIRD, "靠入口，第三位")
	await _wait(1.0)
	_mark("第三位放置结束")


func _run_r5() -> void:
	var board := _mount_battle(false)
	board.set_process(false)
	_farm(board, GOAL_UPGRADE)
	_roll(board)
	var cell := _closest_cell(_state(board))
	_mark("准备升级。面前最近的格子是 (%d,%d)。%s" % [cell.x, cell.y, _summary(board)])
	# 面前的残影还在射程里，片头只留很短，避免还没点就已经被打掉。
	await _wait(0.25)
	await _tap_unit(board, cell)
	await _wait(0.4)
	var first: bool = await _tap_upgrade(board, "点升级（第 1 次）")
	await _wait(0.45)
	var second: bool = await _tap_upgrade(board, "点升级（第 2 次）")
	_note("两次升级结果：%s / %s" % [str(first), str(second)])
	await _wait(0.3)
	await _tap_close(board)
	await _await_volleys(board, cell, 3)
	await _wait(0.6)
	_mark("三轮符札后再留 1 秒")
	await _wait(1.0)


func _run_r6(speed: int) -> void:
	var board := _mount_battle(false)
	board.set_process(false)
	_farm(board, GOAL_BRAWL)
	_roll(board)
	_mark("混战开始。%s" % _summary(board))
	if speed == 2:
		await _tap_speed(board, 2)
	else:
		_mark("保持 ×1")
	await _wait(1.0)
	var state := _state(board)
	if str(state.phase) == BattleSim.PHASE_INTERMISSION and int(state.wave_index) >= 1:
		_mark("提前开始第 3 波。波与波之间界面没有叫波按钮，这一下走战斗规则里的叫波")
		_sim(board).call_next_wave()
	var frames := 0
	var half := false
	while frames < FPS * 24:
		await process_frame
		frames += 1
		state = _state(board)
		var spawning := str(state.phase) == BattleSim.PHASE_SPAWNING
		if spawning and int(state.wave_index) >= 2 and _wave_half(state) and not half:
			half = true
			_mark("第 3 波过半")
		if half and frames >= FPS * 8:
			break
		if str(state.outcome) != "":
			_mark("混战在录完前分出了胜负")
			break
	if not half:
		_mark("这段里第 3 波还没过半，画面停在：%s" % _summary(board))
	await _wait(1.0)


func _run_r7() -> void:
	var board := _mount_battle(false)
	board.set_process(false)
	_farm(board, GOAL_ENDING)
	_roll(board)
	_mark("从最后几只残影开始。%s" % _summary(board))
	var marked_three := false
	var guard := 0
	while guard < FPS * 25:
		await process_frame
		guard += 1
		var state := _state(board)
		var living := (state.enemies as Array).size()
		if not marked_three and living > 0 and living <= 3:
			marked_three = true
			_mark("场上还剩 %d 只残影" % living)
		if (board.get_node("%ResultPanel") as CanvasItem).visible:
			_mark("结算卡展开，金色光点上升")
			break
	await _wait(3.0)
	await _tap_continue(board)
	_mark("结算原画再留 3 秒")
	await _wait(3.0)


func _run_r8() -> void:
	var board := _mount_battle(false)
	board.set_process(false)
	board.call("_on_call_pressed")
	var placed := false
	var guard := 0
	while guard < 20000:
		var state := _state(board)
		if str(state.outcome) != "":
			break
		var lead_y := _max_enemy_y(state)
		var count := (state.enemies as Array).size()
		if not placed and count >= 2 and lead_y >= 8.6:
			placed = _place_quiet(board, CELL_FIRST)
			_note("两只残影走过中段射程后才放灵梦：%s" % str(placed))
		if placed and lead_y >= 10.3:
			break
		_sim(board).tick()
		guard += 1
	_roll(board)
	_mark("残影接近赛钱箱。%s" % _summary(board))
	var leaks := 0
	var hp := int(_state(board).guard_hp)
	var frames := 0
	while frames < FPS * 6:
		await process_frame
		frames += 1
		var next_hp := int(_state(board).guard_hp)
		if next_hp < hp:
			leaks += hp - next_hp
			hp = next_hp
			_mark("第 %d 只残影走到赛钱箱，结界裂开，生命数字抖动" % leaks)
		if leaks >= 2 and frames >= FPS * 2:
			break
	if frames < FPS * 6:
		await _wait(float(FPS * 6 - frames) / float(FPS))
	if leaks < 1:
		_mark("这段没有漏怪。%s" % _summary(board))
	else:
		_mark("漏怪段结束，共 %d 只" % leaks)


func _place_on_camera(board: Node, cell: Vector2i, where: String) -> void:
	await _tap_cell(board, cell, "点格子（%s）" % where)
	await _wait(0.4)
	await _tap_reimu(board, "点灵梦头像")
	await _wait(0.8)


func _farm(board: Node, goal: String) -> void:
	if not _place_quiet(board, CELL_FIRST):
		_note("准备时第一位没有放下")
	if not _place_quiet(board, CELL_SECOND):
		_note("准备时第二位没有放下")
	board.call("_on_call_pressed")
	var guard := 0
	while guard < 300000:
		if _goal_met(board, goal):
			break
		var state := _state(board)
		if str(state.outcome) != "":
			_note("准备时对局已结束")
			break
		_step_goal(board, state, goal)
		if str(_state(board).outcome) == "":
			_sim(board).tick()
		if _segment == "probe" and guard % 300 == 0:
			print("PROBE %s" % _summary(board))
		guard += 1
	board.call("_refresh")
	_note(_summary(board))


func _step_goal(board: Node, state: Dictionary, goal: String) -> void:
	# 先放满三位再升级。升级会把第三位要用的灵力花掉。
	var want_squad := goal == GOAL_BRAWL or goal == GOAL_ENDING
	var units := (state.units as Array).size()
	if want_squad and units < 3 and int(state.spirit) >= _reimu_cost(state):
		_place_quiet(board, CELL_THIRD)
		return
	if want_squad and units >= 3 and _max_level(state) < 3:
		if _upgrade_quiet(board, CELL_FIRST):
			return
	var phase := str(state.phase)
	var wave := int(state.wave_index)
	if phase == BattleSim.PHASE_INTERMISSION and wave < 1:
		_sim(board).call_next_wave()


func _goal_met(board: Node, goal: String) -> bool:
	var state := _state(board)
	var units := (state.units as Array).size()
	var spirit := int(state.spirit)
	var phase := str(state.phase)
	var wave := int(state.wave_index)
	var living := (state.enemies as Array).size()
	var met := false
	if goal == GOAL_THIRD:
		met = units == 2 and spirit >= _reimu_cost(state)
	elif goal == GOAL_UPGRADE and units >= 2 and spirit >= _upgrade_total(board, CELL_FIRST):
		met = _nearest_distance(state, _closest_cell(state)) <= 2.2
	elif goal == GOAL_BRAWL and units >= 3 and _max_level(state) >= 3:
		var before_wave_three := phase == BattleSim.PHASE_INTERMISSION and wave >= 1
		var wave_three := wave >= 2 and phase != BattleSim.PHASE_DEPLOY
		met = before_wave_three or wave_three
	elif goal == GOAL_ENDING:
		met = phase == BattleSim.PHASE_FINAL and living > 0
	return met


func _mount(scene_path: String) -> Node:
	var packed := load(scene_path) as PackedScene
	var node := packed.instantiate()
	root.add_child(node)
	current_scene = node
	return node


func _mount_battle(play_entry: bool) -> Node:
	var board := _mount(BATTLE_SCENE)
	if not play_entry:
		board.get_node("%ScreenMotion").call("finish_entry")
	return board


func _roll(board: Node) -> void:
	board.call("_refresh")
	board.set_process(true)


func _place_quiet(board: Node, cell: Vector2i) -> bool:
	var before := (_state(board).units as Array).size()
	board.call("_on_cell_pressed", cell.x, cell.y)
	board.call("_on_character_pressed", REIMU)
	_drain(board, 0.75)
	return (_state(board).units as Array).size() > before


func _upgrade_quiet(board: Node, cell: Vector2i) -> bool:
	var unit := _unit_at(_state(board), cell)
	if unit.is_empty() or not bool(unit.get("can_upgrade", false)):
		return false
	var upgraded: bool = _sim(board).upgrade(int(unit.id))
	board.call("_refresh")
	return upgraded


func _drain(board: Node, seconds: float) -> void:
	var step := 1.0 / float(FPS)
	var count := int(round(seconds * float(FPS)))
	for _index in count:
		board.call("_advance_board_fx", step)
		board.get_node("%ScreenMotion").call("advance", step)


func _tap_hotspot(flow: Node, hotspot_id: String, screen_id: String, action: String) -> void:
	var button: Button = flow.call("hotspot_button", hotspot_id)
	if button == null:
		_mark("找不到按钮 %s" % hotspot_id)
		return
	await _click_at(button.get_global_rect().get_center(), action)
	await _expect_screen(flow, screen_id, button)


func _expect_screen(flow: Node, screen_id: String, button: Button) -> void:
	var guard := 0
	while str(flow.call("current_screen_id")) != screen_id and guard < 20:
		await process_frame
		guard += 1
	if str(flow.call("current_screen_id")) == screen_id:
		return
	_fallback_clicks += 1
	_mark("点击没有切到 %s，改走按钮回调" % screen_id)
	button.pressed.emit()
	guard = 0
	while str(flow.call("current_screen_id")) != screen_id and guard < 20:
		await process_frame
		guard += 1


func _tap_cell(board: Node, cell: Vector2i, action: String) -> void:
	var view := board.get_node("%BoardView") as Control
	var local: Vector2 = view.call("cell_center", cell.x, cell.y)
	await _click_at(view.get_global_transform() * local, action)
	await process_frame
	if _cell_selected(board, cell) or _panel_open(board):
		return
	_fallback_clicks += 1
	_mark("点击没有落到格子上，改走格子回调")
	board.call("_on_cell_pressed", cell.x, cell.y)


func _tap_reimu(board: Node, action: String) -> void:
	var before := (_state(board).units as Array).size()
	var button := _reimu_button(board)
	if button == null:
		_mark("找不到灵梦头像")
		return
	await _click_at(button.get_global_rect().get_center(), action)
	await process_frame
	if (_state(board).units as Array).size() > before:
		return
	_fallback_clicks += 1
	_mark("点击没有放下灵梦，改走头像回调")
	board.call("_on_character_pressed", REIMU)


func _tap_unit(board: Node, cell: Vector2i) -> void:
	await _tap_cell(board, cell, "点场上的灵梦（%d,%d）" % [cell.x, cell.y])
	if _panel_open(board):
		return
	_fallback_clicks += 1
	_mark("面板没打开，再走一次格子回调")
	board.call("_on_cell_pressed", cell.x, cell.y)


func _tap_upgrade(board: Node, action: String) -> bool:
	var unit_id := int(board.get("_selected_unit"))
	var before := _level_of(_state(board), unit_id)
	var button := board.get_node("%UpgradeButton") as Button
	await _click_at(button.get_global_rect().get_center(), action)
	await process_frame
	if _level_of(_state(board), unit_id) > before:
		return true
	_fallback_clicks += 1
	_mark("点击没有升级，改走升级回调")
	board.call("_on_upgrade_pressed")
	await process_frame
	return _level_of(_state(board), unit_id) > before


func _tap_close(board: Node) -> void:
	var button := board.get_node("%CloseUnitButton") as Button
	await _click_at(button.get_global_rect().get_center(), "关闭面板")
	await process_frame
	if not _panel_open(board):
		return
	_fallback_clicks += 1
	_mark("点击没有关掉面板，改走关闭回调")
	board.call("_on_close_unit_pressed")


func _tap_speed(board: Node, target: int) -> void:
	var button := board.get_node("%SpeedButton") as Button
	await _click_at(button.get_global_rect().get_center(), "点倍速，切到 ×%d" % target)
	await process_frame
	if int(board.get("_speed")) == target:
		return
	_fallback_clicks += 1
	_mark("点击没有切倍速，改走倍速回调")
	board.call("_on_speed_pressed")


func _tap_continue(board: Node) -> void:
	var button := board.get_node("%MenuButton") as Button
	await _click_at(button.get_global_rect().get_center(), "点继续，进入结算原画")
	await _wait(0.6)
	if _on_result_art():
		return
	_fallback_clicks += 1
	_mark("点击没有进入结算原画，改走继续回调")
	if is_instance_valid(board):
		board.call("_on_menu_pressed")
	await _wait(0.6)


func _await_volleys(board: Node, cell: Vector2i, needed: int) -> void:
	var seen := 0
	var previous := _cooldown(board, cell)
	var guard := 0
	while seen < needed and guard < FPS * 8:
		await process_frame
		guard += 1
		var current := _cooldown(board, cell)
		if previous >= 0.0 and current > previous + 0.4:
			var level := int(_unit_at(_state(board), cell).get("level", 1))
			if level >= 3:
				seen += 1
				_mark("第 %d 轮三张符札飞出" % seen)
		previous = current
	if seen < needed:
		_mark("只数到 %d 轮三张符札" % seen)


func _click_at(at: Vector2, action: String) -> void:
	_mark("%s（%.0f, %.0f）" % [action, at.x, at.y])
	_post_pointer(at, true)
	await _wait(0.08)
	_post_pointer(at, false)
	await process_frame


func _post_pointer(at: Vector2, pressed: bool) -> void:
	Input.warp_mouse(at)
	var motion := InputEventMouseMotion.new()
	motion.position = at
	motion.global_position = at
	Input.parse_input_event(motion)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = pressed
	click.position = at
	click.global_position = at
	if pressed:
		click.button_mask = MOUSE_BUTTON_MASK_LEFT
	Input.parse_input_event(click)
	Input.flush_buffered_events()


func _on_result_art() -> bool:
	var scene := current_scene
	if scene == null:
		return false
	return scene.scene_file_path == FLOW_SCENE and str(scene.call("current_screen_id")) == "result"


func _cell_selected(board: Node, cell: Vector2i) -> bool:
	return int(board.get("_selected_col")) == cell.x and int(board.get("_selected_row")) == cell.y


func _panel_open(board: Node) -> bool:
	return (board.get_node("%UnitPanel") as CanvasItem).visible


func _reimu_button(board: Node) -> Button:
	var bar := board.get_node("%CharacterBar")
	for child in bar.get_children():
		if child is Button:
			return child
	return null


func _sim(board: Node) -> BattleSim:
	return board.get("_sim") as BattleSim


func _state(board: Node) -> Dictionary:
	return _sim(board).view_state()


func _unit_at(state: Dictionary, cell: Vector2i) -> Dictionary:
	for unit_v in state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		if int(unit.col) == cell.x and int(unit.row) == cell.y:
			return unit
	return {}


func _level_of(state: Dictionary, unit_id: int) -> int:
	for unit_v in state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		if int(unit.get("id", -1)) == unit_id:
			return int(unit.get("level", 1))
	return 0


func _max_level(state: Dictionary) -> int:
	var found := 0
	for unit_v in state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		found = maxi(found, int((unit_v as Dictionary).get("level", 1)))
	return found


func _reimu_cost(state: Dictionary) -> int:
	for entry_v in state.get("roster", []):
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		if str(entry.get("id", "")) == REIMU:
			return int(entry.get("cost", 100))
	return 100


func _upgrade_total(board: Node, cell: Vector2i) -> int:
	var units: Array = _sim(board).get("_units")
	for unit_v in units:
		var body := unit_v as BattleUnit
		if body == null or body.col != cell.x or body.row != cell.y:
			continue
		var total := 0
		for cost_v in body.upgrade_costs:
			total += int(cost_v)
		return total
	return 120


func _closest_cell(state: Dictionary) -> Vector2i:
	var best := CELL_FIRST
	var best_distance := _nearest_distance(state, CELL_FIRST)
	var other := _nearest_distance(state, CELL_SECOND)
	if other < best_distance:
		best = CELL_SECOND
	return best


func _nearest_distance(state: Dictionary, cell: Vector2i) -> float:
	var origin := Vector2(float(cell.x) + 0.5, float(cell.y) + 0.5)
	var best := 999.0
	for enemy_v in state.get("enemies", []):
		if typeof(enemy_v) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = enemy_v
		var pos := Vector2(float(enemy.x), float(enemy.y))
		best = minf(best, origin.distance_to(pos))
	return best


func _max_enemy_y(state: Dictionary) -> float:
	var found := -1.0
	for enemy_v in state.get("enemies", []):
		if typeof(enemy_v) != TYPE_DICTIONARY:
			continue
		found = maxf(found, float((enemy_v as Dictionary).y))
	return found


func _cooldown(board: Node, cell: Vector2i) -> float:
	var units: Array = _sim(board).get("_units")
	for unit_v in units:
		var body := unit_v as BattleUnit
		if body != null and body.col == cell.x and body.row == cell.y:
			return body.cooldown
	return -1.0


func _wave_half(state: Dictionary) -> bool:
	var duration := float(state.get("phase_duration", 0.0))
	if duration <= 0.0:
		return false
	return float(state.get("phase_time_left", duration)) <= duration * 0.5


func _summary(board: Node) -> String:
	var state := _state(board)
	return (
		"阶段 %s，波次序号 %d，剩余 %.1f/%.1f 秒，灵力 %d，单位 %d，最高 Lv%d，残影 %d，生命 %d"
		% [
			str(state.phase),
			int(state.wave_index),
			float(state.phase_time_left),
			float(state.phase_duration),
			int(state.spirit),
			(state.units as Array).size(),
			_max_level(state),
			(state.enemies as Array).size(),
			int(state.guard_hp),
		]
	)


func _wait(seconds: float) -> void:
	var frames := maxi(int(round(seconds * float(FPS))), 0)
	for _index in frames:
		await process_frame


func _sec() -> float:
	return float(maxi(Engine.get_frames_drawn() - _frame0, 0)) / float(FPS)


func _mark(action: String) -> void:
	var line := "%.2f 秒  %s" % [_sec(), action]
	_lines.append(line)
	print("PV_TIMELINE %s" % line)


func _note(text: String) -> void:
	_lines.append("# %s" % text)
	print("PV_NOTE %s" % text)


func _flush_timeline() -> void:
	if _timeline_path == "":
		return
	var file := FileAccess.open(_timeline_path, FileAccess.WRITE)
	if file == null:
		push_error("写不了对照表 %s" % _timeline_path)
		return
	file.store_string("\n".join(_lines) + "\n")
