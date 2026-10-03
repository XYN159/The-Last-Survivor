extends Control

## 用二十张界面原画串起来的流程：启动页 → 登录 → 主界面 → 出击 → 关前视频 → 序章战斗 → 结算 → 主界面。
## 每张原画按 1920×1080 铺满舞台；能点的地方盖透明按钮，坐标在 data/ui/original_screens.json。
## 这里只换画面：不写存档、不记账号、不联网，也不改任何数值。

signal screen_shown(screen_id: String)
signal scene_change_requested(path: String)

## 出击先进关前视频，视频播完或跳过后由它自己进战斗。
const PRE_VIDEO_SCENE := "res://scenes/main/prologue_pre_video.tscn"
const FIRST_SCREEN := "splash"
const HOME_SCREEN := "home"
const RESULT_SCREEN := "result"
const BACK_BUTTON_NAME := "BackButton"
const _LABEL_FONT_SIZE := 28
const _LABEL_TEXT_COLOR := Color("#F8EBDD")
const _LABEL_FILL := Color(0.04, 0.02, 0.05, 0.72)
const _LABEL_BORDER := Color(0.75, 0.19, 0.23, 0.9)

## 从战斗回来时要先显示的画面。战斗换场景前写入，这里进场读一次就清空。
static var pending_entry: String = ""

## 测试里关掉，只看信号，不真的换场景。
var auto_change_scene: bool = true
var _screens: OriginalScreens
var _stack: Array[String] = []
var _popup_id: String = ""
var _leaving: bool = false
var _fade_sec: float = 0.18

@onready var _screen_layer: Control = %ScreenLayer
@onready var _popup_layer: Control = %PopupLayer


func _ready() -> void:
	_screens = OriginalScreens.load_default()
	_fade_sec = MotionConfig.load_default().number("originals", "page_fade_sec", _fade_sec)
	var entry := pending_entry
	pending_entry = ""
	if entry == RESULT_SCREEN:
		# 结算页下面垫着主界面，点「返回」或「确认」都回到主界面。
		_stack = [HOME_SCREEN, RESULT_SCREEN]
		_render_page()
	else:
		reset_to(FIRST_SCREEN)


func current_screen_id() -> String:
	return "" if _stack.is_empty() else _stack[-1]


func popup_screen_id() -> String:
	return _popup_id


func stack_ids() -> Array[String]:
	return _stack.duplicate()


## 按 id 找当前可点的按钮：弹窗开着时先找弹窗。找不到返回 null。
func hotspot_button(hotspot_id: String) -> Button:
	for layer in [_popup_layer, _screen_layer]:
		for page in (layer as Control).get_children():
			var found := page.get_node_or_null(hotspot_id) as Button
			if found != null:
				return found
	return null


func push(screen_id: String) -> void:
	if not _screens.has_screen(screen_id):
		push_warning("没有这个画面：%s" % screen_id)
		return
	_stack.append(screen_id)
	_render_page()


func replace(screen_id: String) -> void:
	if not _screens.has_screen(screen_id):
		push_warning("没有这个画面：%s" % screen_id)
		return
	if not _stack.is_empty():
		_stack.pop_back()
	_stack.append(screen_id)
	_render_page()


func reset_to(screen_id: String) -> void:
	if not _screens.has_screen(screen_id):
		push_warning("没有这个画面：%s" % screen_id)
		return
	_stack = [screen_id]
	_render_page()


func back() -> void:
	if _stack.size() <= 1:
		return
	_stack.pop_back()
	_render_page()


func open_popup(screen_id: String) -> void:
	if not _screens.has_screen(screen_id):
		push_warning("没有这个画面：%s" % screen_id)
		return
	close_popup()
	_popup_id = screen_id
	_popup_layer.add_child(_build_page(screen_id))
	screen_shown.emit(screen_id)


func close_popup() -> void:
	_clear(_popup_layer)
	_popup_id = ""


func start_battle() -> void:
	if _leaving:
		return
	_leaving = true
	# 体力弹窗不拦出击：进战斗前一律关掉。
	close_popup()
	scene_change_requested.emit(PRE_VIDEO_SCENE)
	if auto_change_scene:
		get_tree().change_scene_to_file(PRE_VIDEO_SCENE)


func _render_page() -> void:
	close_popup()
	_clear(_screen_layer)
	var screen_id := current_screen_id()
	_screen_layer.add_child(_build_page(screen_id))
	screen_shown.emit(screen_id)


func _build_page(screen_id: String) -> Control:
	var page := Control.new()
	page.name = screen_id
	page.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	# 整页吃掉点击，免得弹窗下面的主界面按钮被点穿。
	page.mouse_filter = Control.MOUSE_FILTER_STOP
	var art := TextureRect.new()
	art.name = "Art"
	art.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_SCALE
	art.texture = load(_screens.image_path(screen_id)) as Texture2D
	page.add_child(art)
	for spot in _screens.hotspots(screen_id):
		var button := _make_button(str(spot.label))
		button.name = str(spot.id)
		_place(button, spot.rect)
		button.pressed.connect(_on_hotspot_pressed.bind(spot))
		page.add_child(button)
	if _screens.has_back(screen_id):
		var back_button := _make_button("ui.originals.back")
		back_button.name = BACK_BUTTON_NAME
		_place(back_button, _screens.back_rect(screen_id))
		back_button.pressed.connect(back)
		page.add_child(back_button)
	if _fade_sec > 0.0:
		page.modulate.a = 0.0
		page.create_tween().tween_property(page, "modulate:a", 1.0, _fade_sec)
	return page


func _on_hotspot_pressed(spot: Dictionary) -> void:
	var target := str(spot.target)
	match str(spot.action):
		OriginalScreens.ACTION_PUSH:
			push(target)
		OriginalScreens.ACTION_REPLACE:
			replace(target)
		OriginalScreens.ACTION_RESET:
			reset_to(target)
		OriginalScreens.ACTION_BACK:
			back()
		OriginalScreens.ACTION_POPUP:
			open_popup(target)
		OriginalScreens.ACTION_CLOSE_POPUP:
			close_popup()
		OriginalScreens.ACTION_BATTLE:
			start_battle()
		_:
			push_warning("未知的点击动作：%s" % str(spot.action))


## 没有 label 的是盖在原画上的透明按钮，只在按下时泛一层淡光；
## 有 label 的是原画上没有、额外补的小按钮，用半透明深底，不盖住主要画面。
func _make_button(label_key: String) -> Button:
	var button := Button.new()
	button.focus_mode = Control.FOCUS_NONE
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if label_key == "":
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", _flat(Color(1, 1, 1, 0.05), Color.TRANSPARENT))
		button.add_theme_stylebox_override(
			"pressed", _flat(Color(1, 1, 1, 0.12), Color.TRANSPARENT)
		)
		return button
	button.text = tr(label_key)
	button.add_theme_font_size_override("font_size", _LABEL_FONT_SIZE)
	button.add_theme_color_override("font_color", _LABEL_TEXT_COLOR)
	button.add_theme_color_override("font_hover_color", Color.WHITE)
	button.add_theme_color_override("font_pressed_color", Color.WHITE)
	button.add_theme_stylebox_override("normal", _flat(_LABEL_FILL, _LABEL_BORDER))
	button.add_theme_stylebox_override("hover", _flat(_LABEL_FILL.lightened(0.12), _LABEL_BORDER))
	button.add_theme_stylebox_override("pressed", _flat(_LABEL_FILL.lightened(0.24), _LABEL_BORDER))
	return button


func _flat(fill: Color, border: Color) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = fill
	box.border_color = border
	if border.a > 0.0:
		box.set_border_width_all(2)
	box.set_corner_radius_all(10)
	return box


func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


func _clear(layer: Control) -> void:
	for child in layer.get_children():
		layer.remove_child(child)
		child.queue_free()
