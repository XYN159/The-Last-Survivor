extends SceneTree

## 序章第一关动效截图。不进 GUT，手动运行：
##   godot --path . --resolution 1920x1080 -s tests/capture/motion_capture.gd
## 截图写到 MOTION_CAPTURE_DIR（默认 user://motion_capture）。
## 动效按固定步长手动推进，每次截出来的画面都一样。

const MENU_SCENE := preload("res://scenes/main/main_menu.tscn")
const BATTLE_SCENE := preload("res://scenes/battle/battle_board.tscn")
const STEP := 1.0 / 60.0

var _directory: String = ""


func _initialize() -> void:
	_directory = OS.get_environment("MOTION_CAPTURE_DIR")
	if _directory == "":
		_directory = "user://motion_capture"
	DirAccess.make_dir_recursive_absolute(_directory)
	_run.call_deferred()


func _run() -> void:
	await _capture_menu()
	await _capture_win()
	await _capture_loss()
	quit()


func _capture_menu() -> void:
	var menu := MENU_SCENE.instantiate()
	root.add_child(menu)
	var button := menu.get_node("%StartButton") as Button
	var press: Node = button.get_node("PressMotion")
	press.set_process(false)
	button.button_down.emit()
	press.call("advance", 0.2)
	await _save("00-start-pressed")
	button.button_up.emit()
	press.call("advance", 0.12)
	await _save("00-start-rebound")
	menu.free()


func _capture_win() -> void:
	var board := _open_battle()
	var screen: Node = board.get_node("%ScreenMotion")
	screen.call("advance", 0.2)
	await _save("01-entry")
	screen.call("finish_entry")
	_wait_for_spirit(board, "chr_reimu", 2, 4)
	board.call("_on_cell_pressed", 2, 4)
	_step_board(board, 0.06)
	await _save("02-select")
	board.call("_on_character_pressed", "chr_reimu")
	_step_board(board, 0.06)
	await _save("02b-facing")
	board.call("_on_facing_pressed", "down")
	_step_board(board, 0.36)
	await _save("03-place")
	board.call("_on_cell_pressed", 2, 4)
	_step_board(board, 0.06)
	await _save("03b-retreat")
	board.call("_on_close_unit_pressed")
	_step_board(board, 1.0)
	_tick_until(board, "death", 0.3)
	await _save("04-hit")
	_tick_to_outcome(board)
	screen.call("advance", 0.12)
	await _save("05-result-unfold")
	screen.call("advance", 1.0)
	_step_result_motes(board, 1.4)
	await _save("06-result-win")
	board.free()


func _capture_loss() -> void:
	var board := _open_battle()
	board.get_node("%ScreenMotion").call("finish_entry")
	_tick_until(board, "leak", 0.12)
	await _save("07-leak")
	_tick_to_outcome(board)
	board.get_node("%ScreenMotion").call("advance", 1.0)
	_step_result_motes(board, 1.4)
	await _save("08-result-loss")
	board.free()


func _open_battle() -> Node:
	var board := BATTLE_SCENE.instantiate()
	root.add_child(board)
	board.set_process(false)
	board.get_node("%ScreenMotion").set_process(false)
	board.get_node("%ResultMotes").set_process(false)
	return board


func _step_board(board: Node, seconds: float) -> void:
	var steps := int(round(seconds / STEP))
	for _step in steps:
		board.call("_advance_board_fx", STEP)
		board.get_node("%ScreenMotion").call("advance", STEP)
	board.call("_refresh")


## 开局灵力不够放灵梦，先跑规则等灵力回上来。
func _wait_for_spirit(board: Node, character_id: String, col: int, row: int) -> void:
	var sim: BattleSim = board.get("_sim")
	var guard := 0
	while not sim.can_place(character_id, col, row) and guard < 6000:
		board.call("_note_events", sim.tick())
		guard += 1
	board.call("_refresh")


## 逐帧跑规则，直到出现某种事件，再多跑 after 秒，让光效飞到半路。
func _tick_until(board: Node, kind: String, after: float) -> void:
	var sim: BattleSim = board.get("_sim")
	var guard := 0
	var seen := false
	while guard < 60000 and not seen:
		var events := sim.tick()
		board.call("_note_events", events)
		board.call("_advance_board_fx", STEP)
		board.get_node("%ScreenMotion").call("advance", STEP)
		for event_v in events:
			if str((event_v as Dictionary).get("type", "")) == kind:
				seen = true
		guard += 1
	var tail := int(round(after / STEP))
	for _step in tail:
		board.call("_note_events", sim.tick())
		board.call("_advance_board_fx", STEP)
		board.get_node("%ScreenMotion").call("advance", STEP)
	board.call("_refresh")


func _tick_to_outcome(board: Node) -> void:
	var sim: BattleSim = board.get("_sim")
	var guard := 0
	while str(sim.view_state().outcome) == "" and guard < 300000:
		sim.tick()
		guard += 1
	board.call("_show_result", sim.view_state())
	board.call("_refresh")


func _step_result_motes(board: Node, seconds: float) -> void:
	var motes: Node = board.get_node("%ResultMotes")
	var steps := int(round(seconds / STEP))
	for _step in steps:
		motes.call("advance", STEP)


func _save(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var image := root.get_texture().get_image()
	var path := _directory.path_join("%s.png" % shot_name)
	image.save_png(path)
	print("已保存截图 %s" % path)
