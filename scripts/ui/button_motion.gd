extends Control

## 按钮手感：悬停放大，按下压一下，松开回弹；点中时闪一下，并向外扩出一圈金色符札角。
## 作为按钮的子节点挂上去，自己不接收点击。用 bind() 接到按钮上。

const _GOLD := Color("#D4A94F")
const _FLASH := Color("#FFF6E8")
const _CORNER_PX := 18.0

var _button: Button
var _hover_scale: float = 1.05
var _press_scale: float = 0.94
var _press_sec: float = 0.06
var _release_sec: float = 0.18
var _flash_sec: float = 0.24
var _ring_px: float = 12.0
var _flash_left: float = 0.0
var _hovered: bool = false
var _tween: Tween


func bind(button: Button, config: MotionConfig) -> void:
	_button = button
	_hover_scale = config.number("button", "hover_scale", _hover_scale)
	_press_scale = config.number("button", "press_scale", _press_scale)
	_press_sec = config.number("button", "press_sec", _press_sec)
	_release_sec = config.number("button", "release_sec", _release_sec)
	_flash_sec = config.number("button", "flash_sec", _flash_sec)
	_ring_px = config.number("button", "ring_px", _ring_px)
	name = "ButtonMotion"
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	button.add_child(self)
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	button.resized.connect(_center_pivot)
	button.mouse_entered.connect(_on_hover_changed.bind(true))
	button.mouse_exited.connect(_on_hover_changed.bind(false))
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	button.pressed.connect(_on_button_pressed)
	_center_pivot()
	set_process(false)


func flash_left() -> float:
	return _flash_left


func _process(delta: float) -> void:
	_flash_left = maxf(0.0, _flash_left - delta)
	queue_redraw()
	if _flash_left <= 0.0:
		set_process(false)


func _draw() -> void:
	if _flash_left <= 0.0 or _flash_sec <= 0.0:
		return
	var ratio := _flash_left / _flash_sec
	var inner := Rect2(Vector2.ZERO, size)
	draw_rect(inner, Color(_FLASH, 0.38 * ratio))
	var ring := inner.grow(_ring_px * (1.0 - ratio))
	var gold := Color(_GOLD, ratio)
	_draw_corners(ring, gold)


func _draw_corners(rect: Rect2, color: Color) -> void:
	var arm := minf(_CORNER_PX, minf(rect.size.x, rect.size.y) * 0.4)
	var corners := [
		[rect.position, Vector2(1, 0), Vector2(0, 1)],
		[Vector2(rect.end.x, rect.position.y), Vector2(-1, 0), Vector2(0, 1)],
		[Vector2(rect.position.x, rect.end.y), Vector2(1, 0), Vector2(0, -1)],
		[rect.end, Vector2(-1, 0), Vector2(0, -1)],
	]
	for corner_v in corners:
		var corner: Array = corner_v
		var origin: Vector2 = corner[0]
		draw_line(origin, origin + (corner[1] as Vector2) * arm, color, 3.0)
		draw_line(origin, origin + (corner[2] as Vector2) * arm, color, 3.0)


func _center_pivot() -> void:
	if _button != null:
		_button.pivot_offset = _button.size * 0.5


func _on_hover_changed(hovered: bool) -> void:
	_hovered = hovered
	if _button.button_pressed:
		return
	_scale_to(_rest_scale(), _release_sec, Tween.TRANS_QUAD)


func _on_button_down() -> void:
	if _button.disabled:
		return
	_scale_to(_press_scale, _press_sec, Tween.TRANS_QUAD)


func _on_button_up() -> void:
	_scale_to(_rest_scale(), _release_sec, Tween.TRANS_BACK)


func _on_button_pressed() -> void:
	_flash_left = _flash_sec
	set_process(true)
	queue_redraw()


func _rest_scale() -> float:
	if _hovered and not _button.disabled:
		return _hover_scale
	return 1.0


func _scale_to(target: float, seconds: float, transition: Tween.TransitionType) -> void:
	if not is_inside_tree():
		return
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_center_pivot()
	_tween = create_tween()
	(
		_tween
		. tween_property(_button, "scale", Vector2.ONE * target, maxf(seconds, 0.01))
		. set_trans(transition)
		. set_ease(Tween.EASE_OUT)
	)
