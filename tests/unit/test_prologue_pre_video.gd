extends GutTest

## 序章第一关的关前视频：全屏铺满、不循环，右上角有真按钮「跳过」，
## 点屏幕、点跳过、播完都只进一次战斗；视频打不开也照样进战斗。

const VIDEO_SCENE := preload("res://scenes/main/prologue_pre_video.tscn")
const MENU_SCENE := preload("res://scenes/main/main_menu.tscn")
const PRE_VIDEO_SCENE_PATH := "res://scenes/main/prologue_pre_video.tscn"
const BATTLE_SCENE_PATH := "res://scenes/battle/battle_board.tscn"
const VIDEO_PATH := "res://assets/video/prologue_01_pre.ogv"


func test_video_is_theora_and_does_not_loop() -> void:
	var video := _make_video()
	var player := video.get_node("%VideoPlayer") as VideoStreamPlayer
	assert_true(player.stream is VideoStreamTheora)
	assert_eq((player.stream as VideoStreamTheora).file, VIDEO_PATH)
	assert_false(player.loop)
	assert_true(player.is_playing())
	assert_gt(player.get_stream_length(), 0.0)


func test_video_fills_a_1920_by_1080_screen() -> void:
	var video := _make_video_on_screen(Vector2(1920, 1080))
	await wait_process_frames(2)
	var player := video.get_node("%VideoPlayer") as VideoStreamPlayer
	assert_true(player.expand)
	assert_eq(player.get_rect(), Rect2(Vector2.ZERO, Vector2(1920, 1080)))


func test_video_covers_a_wider_screen_without_stretching() -> void:
	var video := _make_video_on_screen(Vector2(2400, 1080))
	await wait_process_frames(2)
	var player := video.get_node("%VideoPlayer") as VideoStreamPlayer
	var rect := player.get_rect()
	assert_true(rect.encloses(Rect2(Vector2.ZERO, video.size)), str(rect))
	assert_almost_eq(rect.size.x / rect.size.y, 16.0 / 9.0, 0.01)


func test_skip_button_sits_at_the_top_right() -> void:
	var video := _make_video()
	await wait_process_frames(1)
	var button := video.get_node("%SkipButton") as Button
	assert_eq(button.text, "跳过")
	assert_eq(button.anchor_left, 1.0)
	assert_eq(button.anchor_right, 1.0)
	assert_eq(button.anchor_top, 0.0)
	assert_eq(button.size, Vector2(160, 64))
	var rect := button.get_global_rect()
	var screen := video.get_global_rect()
	assert_eq(rect.position.y - screen.position.y, 28.0)
	assert_eq(screen.end.x - rect.end.x, 28.0)


func test_skip_button_enters_the_battle_once() -> void:
	var video := _make_video()
	watch_signals(video)
	var button := video.get_node("%SkipButton") as Button
	button.pressed.emit()
	button.pressed.emit()
	assert_signal_emitted_with_parameters(video, "scene_change_requested", [BATTLE_SCENE_PATH])
	assert_signal_emit_count(video, "scene_change_requested", 1)
	assert_false((video.get_node("%VideoPlayer") as VideoStreamPlayer).is_playing())


func test_click_anywhere_skips() -> void:
	var video := _make_video()
	watch_signals(video)
	var click := InputEventMouseButton.new()
	click.button_index = MOUSE_BUTTON_LEFT
	click.pressed = true
	click.position = Vector2(960, 540)
	video.call("_gui_input", click)
	assert_signal_emitted_with_parameters(video, "scene_change_requested", [BATTLE_SCENE_PATH])


func test_finishing_then_clicking_enters_the_battle_once() -> void:
	var video := _make_video()
	watch_signals(video)
	var player := video.get_node("%VideoPlayer") as VideoStreamPlayer
	player.finished.emit()
	video.call("skip")
	(video.get_node("%SkipButton") as Button).pressed.emit()
	assert_signal_emitted_with_parameters(video, "scene_change_requested", [BATTLE_SCENE_PATH])
	assert_signal_emit_count(video, "scene_change_requested", 1)


func test_missing_video_still_enters_the_battle() -> void:
	var video := VIDEO_SCENE.instantiate()
	video.auto_change_scene = false
	video.video_path = "res://assets/video/does_not_exist.ogv"
	watch_signals(video)
	add_child_autofree(video)
	await wait_process_frames(2)
	assert_push_warning("关前视频打不开")
	assert_signal_emitted_with_parameters(video, "scene_change_requested", [BATTLE_SCENE_PATH])
	assert_signal_emit_count(video, "scene_change_requested", 1)


func test_title_start_button_requests_the_pre_video() -> void:
	var menu := MENU_SCENE.instantiate()
	menu.auto_change_scene = false
	add_child_autofree(menu)
	watch_signals(menu)
	(menu.get_node("%StartButton") as Button).pressed.emit()
	await wait_for_signal(menu.scene_change_requested, 2.0)
	assert_signal_emitted_with_parameters(menu, "scene_change_requested", [PRE_VIDEO_SCENE_PATH])


func _make_video() -> Control:
	var video := VIDEO_SCENE.instantiate()
	video.auto_change_scene = false
	add_child_autofree(video)
	return video


func _make_video_on_screen(screen_size: Vector2) -> Control:
	var screen := Control.new()
	screen.size = screen_size
	add_child_autofree(screen)
	var video := VIDEO_SCENE.instantiate()
	video.auto_change_scene = false
	screen.add_child(video)
	return video
