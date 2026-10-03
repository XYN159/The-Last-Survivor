extends GutTest

## 二十张界面原画的流程：图都能装上，点击区都能走通，登录不写文件，出击进现有战斗。

const FLOW_SCENE := preload("res://scenes/main/original_flow.tscn")
const OriginalFlow := preload("res://scripts/main/original_flow.gd")
const BATTLE_SCENE_PATH := "res://scenes/battle/battle_board.tscn"


func after_each() -> void:
	OriginalFlow.pending_entry = ""


func test_screen_table_has_twenty_distinct_originals() -> void:
	var screens := OriginalScreens.load_default()
	var images := {}
	for screen_id in screens.ids():
		images[screens.image_path(screen_id)] = true
	assert_eq(screens.ids().size(), 20)
	assert_eq(images.size(), 20)


func test_every_original_loads_at_1920_by_1080() -> void:
	var screens := OriginalScreens.load_default()
	for screen_id in screens.ids():
		var texture := load(screens.image_path(screen_id)) as Texture2D
		assert_not_null(texture, screen_id)
		if texture != null:
			assert_eq(texture.get_size(), Vector2(1920, 1080), screen_id)


func test_every_screen_shows_its_original_in_the_flow() -> void:
	var screens := OriginalScreens.load_default()
	var flow := _make_flow()
	for screen_id in screens.ids():
		var layer := "%ScreenLayer"
		if screens.is_popup(screen_id):
			layer = "%PopupLayer"
			flow.open_popup(screen_id)
		else:
			flow.reset_to(screen_id)
		var art := flow.get_node(layer).find_child("Art", true, false) as TextureRect
		assert_eq(art.texture.resource_path, screens.image_path(screen_id), screen_id)


func test_every_hotspot_has_a_known_action_and_target() -> void:
	var screens := OriginalScreens.load_default()
	for screen_id in screens.ids():
		for spot in screens.hotspots(screen_id):
			var where := "%s/%s" % [screen_id, spot.id]
			assert_true(str(spot.action) in OriginalScreens.ACTIONS, where)
			assert_true((spot.rect as Rect2).has_area(), where)
			var needs_target := str(spot.action) in ["push", "replace", "reset", "popup"]
			if needs_target:
				assert_true(screens.has_screen(str(spot.target)), where)


func test_hotspots_stay_inside_the_1920_by_1080_board() -> void:
	var screens := OriginalScreens.load_default()
	var board := Rect2(Vector2.ZERO, screens.design_size())
	for screen_id in screens.ids():
		for spot in screens.hotspots(screen_id):
			assert_true(board.encloses(spot.rect), "%s/%s" % [screen_id, spot.id])
		if screens.has_back(screen_id):
			assert_true(board.encloses(screens.back_rect(screen_id)), screen_id)


func test_flow_starts_on_the_splash() -> void:
	var flow := _make_flow()
	assert_eq(flow.current_screen_id(), "splash")


func test_splash_tap_opens_login() -> void:
	var flow := _make_flow()
	_press(flow, "tap_to_start")
	assert_eq(flow.stack_ids(), ["login"])


func test_login_reaches_home_without_writing_files() -> void:
	var before := _user_files("user://")
	var flow := _make_flow()
	_press(flow, "tap_to_start")
	_press(flow, "login")
	assert_eq(flow.stack_ids(), ["home"])
	assert_eq(_user_files("user://"), before)


func test_server_and_notice_open_and_close_from_login() -> void:
	var flow := _make_flow()
	_press(flow, "tap_to_start")
	_press(flow, "open_server")
	assert_eq(flow.current_screen_id(), "server")
	_press(flow, "confirm_server")
	assert_eq(flow.current_screen_id(), "login")
	_press(flow, "open_notice")
	assert_eq(flow.current_screen_id(), "notice")
	_press(flow, "close_notice")
	assert_eq(flow.current_screen_id(), "login")


func test_back_button_says_back_and_returns() -> void:
	var flow := _make_flow()
	flow.reset_to("home")
	_press(flow, "open_shop")
	var back: Button = flow.hotspot_button(OriginalFlow.BACK_BUTTON_NAME)
	assert_eq(back.text, "返回")
	back.pressed.emit()
	assert_eq(flow.current_screen_id(), "home")


func test_sortie_from_home_enters_the_existing_battle() -> void:
	var flow := _make_flow()
	flow.reset_to("home")
	watch_signals(flow)
	for hotspot_id in ["sortie", "chapter_sakura", "stage_node", "start_operation", "start_battle"]:
		_press(flow, hotspot_id)
	assert_eq(flow.current_screen_id(), "dialogue")
	assert_signal_not_emitted(flow, "scene_change_requested")
	_press(flow, "continue_dialogue")
	assert_signal_emitted_with_parameters(flow, "scene_change_requested", [BATTLE_SCENE_PATH])


func test_battle_target_is_the_prologue_board() -> void:
	assert_eq(OriginalFlow.BATTLE_SCENE, BATTLE_SCENE_PATH)
	var board := (load(BATTLE_SCENE_PATH) as PackedScene).instantiate()
	add_child_autofree(board)
	var sim: BattleSim = board._sim
	assert_eq(str(sim.view_state().level_name), tr("level.prologue_01.name"))


func test_stamina_popup_never_blocks_the_sortie() -> void:
	var flow := _make_flow()
	flow.reset_to("squad")
	flow.open_popup("stamina_popup")
	watch_signals(flow)
	flow.start_battle()
	assert_eq(flow.popup_screen_id(), "")
	assert_signal_emitted(flow, "scene_change_requested")


func test_home_bottom_bar_opens_each_page() -> void:
	var flow := _make_flow()
	var pages := {
		"open_squad": "squad",
		"open_roster": "roster",
		"open_missions": "missions",
		"open_shop": "shop",
		"open_mail": "mail",
		"open_gacha": "gacha",
		"open_event_banner": "notice",
	}
	for hotspot_id in pages:
		flow.reset_to("home")
		_press(flow, hotspot_id)
		assert_eq(flow.stack_ids(), ["home", pages[hotspot_id]], hotspot_id)


func test_roster_opens_character_upgrade_and_gear() -> void:
	var flow := _make_flow()
	flow.reset_to("home")
	_press(flow, "open_roster")
	_press(flow, "open_character")
	_press(flow, "open_upgrade")
	assert_eq(flow.stack_ids(), ["home", "roster", "character", "upgrade"])
	flow.back()
	_press(flow, "open_gear")
	assert_eq(flow.stack_ids(), ["home", "roster", "character", "gear"])


func test_stamina_popup_only_closes() -> void:
	var flow := _make_flow()
	flow.reset_to("home")
	var supplies := GameState.supplies
	var squad := GameState.squad_size
	for hotspot_id in ["stamina_confirm", "stamina_cancel"]:
		_press(flow, "open_stamina")
		assert_eq(flow.popup_screen_id(), "stamina_popup")
		_press(flow, hotspot_id)
		assert_eq(flow.popup_screen_id(), "", hotspot_id)
		assert_eq(flow.stack_ids(), ["home"], hotspot_id)
	assert_eq([GameState.supplies, GameState.squad_size], [supplies, squad])


func test_returning_from_battle_shows_result_then_home() -> void:
	OriginalFlow.pending_entry = OriginalFlow.RESULT_SCREEN
	var flow := _make_flow()
	assert_eq(flow.stack_ids(), ["home", "result"])
	assert_eq(OriginalFlow.pending_entry, "")
	_press(flow, "confirm_result")
	assert_eq(flow.stack_ids(), ["home"])


func _make_flow() -> Control:
	var flow := FLOW_SCENE.instantiate()
	flow.auto_change_scene = false
	add_child_autofree(flow)
	return flow


func _press(flow: Control, hotspot_id: String) -> void:
	var button: Button = flow.hotspot_button(hotspot_id)
	assert_not_null(button, "%s 上找不到 %s" % [flow.current_screen_id(), hotspot_id])
	if button != null:
		button.pressed.emit()


func _user_files(path: String) -> Array[String]:
	var found: Array[String] = []
	for file_name in DirAccess.get_files_at(path):
		found.append(path.path_join(file_name))
	for dir_name in DirAccess.get_directories_at(path):
		found.append_array(_user_files(path.path_join(dir_name)))
	found.sort()
	return found
