extends SceneTree

## 动效截图：按真实时间跑序章第一关，在动效播到一半时存图。只给 PR 截图用，不是测试，不进安装包。
## 用法：godot --path . --resolution 1080x1920 -s res://tests/capture/motion_capture.gd
## 图存到环境变量 MOTION_CAPTURE_DIR，默认 user://motion。

const BATTLE_SCENE := "res://scenes/battle/battle_board.tscn"
const MAX_TICKS := 300000

var _dir: String = "user://motion"


func _initialize() -> void:
	var from_env := OS.get_environment("MOTION_CAPTURE_DIR")
	if from_env != "":
		_dir = from_env
	DirAccess.make_dir_recursive_absolute(_dir)
	_run.call_deferred()


func _run() -> void:
	await _capture_win_run()
	await _capture_lose_run()
	quit()


func _capture_win_run() -> void:
	var board: Node = load(BATTLE_SCENE).instantiate()
	root.add_child(board)
	await _wait(0.15)
	await _shot("01_entry_open")
	await _wait(0.55)
	await _shot("02_entry_ofuda")
	await _wait(0.5)
	board.call("_on_cell_pressed", 2, 4)
	await _wait(0.06)
	await _shot("03_select_slot")
	var reimu: Button = (board.get("_buttons") as Dictionary)["chr_reimu"]
	reimu.mouse_entered.emit()
	reimu.button_down.emit()
	await _wait(0.08)
	await _shot("04_button_down")
	reimu.button_up.emit()
	reimu.pressed.emit()
	await _wait(0.09)
	await _shot("05_place_seal")
	await _wait(0.6)
	board.call("_on_cell_pressed", 4, 4)
	reimu.pressed.emit()
	board.call("_on_call_pressed")
	await _until_event(board, "death")
	await _wait(0.3)
	await _shot("06_hit_and_kill_orbs")
	await _finish(board)
	await _wait(0.2)
	await _shot("07_result_win_opening")
	await _wait(1.2)
	await _shot("08_result_win")
	board.queue_free()
	await _wait(0.1)


func _capture_lose_run() -> void:
	var board: Node = load(BATTLE_SCENE).instantiate()
	root.add_child(board)
	await _wait(1.2)
	board.call("_on_cell_pressed", 3, 4)
	await _wait(0.05)
	await _shot("09_place_failed_shake")
	board.call("_on_call_pressed")
	await _until_event(board, "leak")
	await _wait(0.1)
	await _shot("10_guard_hit")
	await _finish(board)
	await _wait(1.4)
	await _shot("11_result_lose")
	board.queue_free()
	await _wait(0.1)


func _until_event(board: Node, kind: String) -> void:
	var sim: BattleSim = board.get("_sim")
	for _step in MAX_TICKS:
		var events := sim.tick()
		board.call("_note_events", events)
		for event_v in events:
			if str((event_v as Dictionary).get("type", "")) == kind:
				board.call("_refresh")
				return
		if str(sim.view_state().outcome) != "":
			return
	await process_frame


func _finish(board: Node) -> void:
	var sim: BattleSim = board.get("_sim")
	var guard := 0
	while str(sim.view_state().outcome) == "" and guard < MAX_TICKS:
		board.call("_note_events", sim.tick())
		guard += 1
	board.call("_show_result", sim.view_state())
	board.call("_refresh")
	await process_frame


func _wait(seconds: float) -> void:
	await create_timer(seconds).timeout


func _shot(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	var path := _dir.path_join("%s.png" % shot_name)
	root.get_texture().get_image().save_png(path)
	print("已保存动效截图 %s" % path)
