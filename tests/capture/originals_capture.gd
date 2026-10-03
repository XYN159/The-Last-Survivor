extends SceneTree

## 界面原画流程截图。不进 GUT，手动运行：
##   godot --path . --resolution 1920x1080 -s tests/capture/originals_capture.gd
## 截图写到 ORIGINALS_CAPTURE_DIR（默认 user://originals_capture）。
## 从启动页一路点到序章战斗，打完后经结算原画回到主界面，中间每一屏截一张。

const FLOW_SCENE := "res://scenes/main/original_flow.tscn"
const SETTLE_SEC := 0.3

var _directory: String = ""
var _shot: int = 0


func _initialize() -> void:
	_directory = OS.get_environment("ORIGINALS_CAPTURE_DIR")
	if _directory == "":
		_directory = "user://originals_capture"
	DirAccess.make_dir_recursive_absolute(_directory)
	_run.call_deferred()


func _run() -> void:
	change_scene_to_file(FLOW_SCENE)
	await _settle()
	await _save("splash")
	await _press("tap_to_start", "login")
	await _press("open_server", "server")
	await _press("BackButton", "")
	await _press("open_notice", "notice")
	await _press("close_notice", "")
	await _press("login", "home")
	await _press("open_stamina", "stamina_popup")
	await _press("stamina_cancel", "")
	for page in ["roster", "missions", "shop", "mail", "gacha"]:
		await _press("open_%s" % page, page)
		await _press("BackButton", "")
	await _press("open_roster", "")
	await _press("open_character", "character")
	await _press("open_upgrade", "upgrade")
	await _press("BackButton", "")
	await _press("open_gear", "gear")
	for _step in 3:
		await _press("BackButton", "")
	await _press("sortie", "chapter")
	await _press("chapter_sakura", "stage_map")
	await _press("stage_node", "stage_detail")
	await _press("start_operation", "squad")
	await _press("start_battle", "dialogue")
	await _press("continue_dialogue", "")
	await _finish_battle()
	await _press("confirm_result", "home_after_result")
	quit()


func _finish_battle() -> void:
	var board := current_scene
	board.set_process(false)
	board.get_node("%ScreenMotion").call("finish_entry")
	board.call("_place_opening")
	board.call("_on_call_pressed")
	var sim: BattleSim = board.get("_sim")
	var guard := 0
	while str(sim.view_state().outcome) == "" and guard < 300000:
		sim.tick()
		guard += 1
	board.call("_show_result", sim.view_state())
	board.call("_refresh")
	board.get_node("%ScreenMotion").call("advance", 1.0)
	await _save("battle_result")
	board.call("_on_menu_pressed")
	await _settle()
	await _save("result")


func _press(hotspot_id: String, shot_name: String) -> void:
	var button: Button = current_scene.call("hotspot_button", hotspot_id)
	if button == null:
		push_error("找不到按钮 %s" % hotspot_id)
		quit(1)
		return
	button.pressed.emit()
	await _settle()
	if shot_name != "":
		await _save(shot_name)


func _settle() -> void:
	await create_timer(SETTLE_SEC).timeout
	await process_frame


func _save(shot_name: String) -> void:
	await RenderingServer.frame_post_draw
	_shot += 1
	var image := root.get_texture().get_image()
	var path := _directory.path_join("%02d-%s.png" % [_shot, shot_name])
	image.save_png(path)
	print("已保存截图 %s" % path)
