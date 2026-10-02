extends Node

## 按钮手感：按下缩小，松开回弹。挂成按钮的子节点（Node 不参与布局，也不接点击）。
## 按钮的底图常常是另一个节点（例如「开始」的 StartFrame），一起传进来同步缩放。

var _button: BaseButton
var _targets: Array[Control] = []
var _press_scale: float = 0.92
var _press_sec: float = 0.07
var _release_sec: float = 0.26
var _overshoot: float = 1.8
var _from: float = 1.0
var _to: float = 1.0
var _elapsed: float = 0.0
var _duration: float = 0.0
var _releasing: bool = false
var _scale: float = 1.0


func bind(button: BaseButton, extras: Array[Control], config: MotionConfig) -> void:
	_button = button
	_press_scale = config.number("button", "press_scale", _press_scale)
	_press_sec = config.number("button", "press_sec", _press_sec)
	_release_sec = config.number("button", "release_sec", _release_sec)
	_overshoot = config.number("button", "overshoot", _overshoot)
	_targets = [button as Control]
	_targets.append_array(extras)
	name = "PressMotion"
	button.add_child(self)
	button.button_down.connect(_on_button_down)
	button.button_up.connect(_on_button_up)
	_center_pivots()


func current_scale() -> float:
	return _scale


func is_playing() -> bool:
	return _elapsed < _duration


func settle_sec() -> float:
	return _release_sec


func advance(delta: float) -> void:
	if not is_playing():
		return
	_elapsed = minf(_elapsed + delta, _duration)
	var t := MotionEase.ratio(_elapsed, _duration)
	var eased := MotionEase.out_back(t, _overshoot) if _releasing else MotionEase.out_cubic(t)
	_apply(lerpf(_from, _to, eased))


func _process(delta: float) -> void:
	advance(delta)


func _on_button_down() -> void:
	if _button.disabled:
		return
	_start(_press_scale, _press_sec, false)


func _on_button_up() -> void:
	_start(1.0, _release_sec, true)


func _start(target: float, seconds: float, releasing: bool) -> void:
	_center_pivots()
	_from = _scale
	_to = target
	_elapsed = 0.0
	_duration = maxf(seconds, 0.001)
	_releasing = releasing


func _apply(value: float) -> void:
	_scale = value
	for target in _targets:
		if is_instance_valid(target):
			target.scale = Vector2.ONE * value


func _center_pivots() -> void:
	for target in _targets:
		if is_instance_valid(target):
			target.pivot_offset = target.size * 0.5
