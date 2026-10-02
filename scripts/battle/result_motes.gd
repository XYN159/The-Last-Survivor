extends Control

## 结算时卡片后面的少量光点。守住了是金色光点往上飘，夹几片樱花；失守了是灰色光点往下落。
## 画在暗幕和结算卡之间，不压字，也不接收点击。

const _GOLD := Color("#F2C66B")
const _PETAL := Color("#F7A8C4")
const _ASH := Color("#8E8A93")

var _rng := RandomNumberGenerator.new()
var _motes: Array = []
var _won: bool = true
var _count: int = 18
var _petal_every: int = 4
var _speed: float = 70.0
var _life: float = 2.4
var _size: float = 5.0


func setup(config: MotionConfig) -> void:
	_rng.seed = 2026
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_count = config.count("result", "mote_count", _count)
	_petal_every = maxi(config.count("result", "petal_every", _petal_every), 1)
	_speed = config.number("result", "mote_speed_px", _speed)
	_life = maxf(config.number("result", "mote_life_sec", _life), 0.1)
	_size = config.number("result", "mote_size_px", _size)


func play(won: bool) -> void:
	_won = won
	_motes.clear()
	for index in _count:
		var mote := _new_mote(index)
		# 错开出生时间，免得所有光点同一帧冒出来。
		mote.age = -_rng.randf_range(0.0, _life)
		_motes.append(mote)
	queue_redraw()


func is_rising() -> bool:
	return _won


func mote_color() -> Color:
	return _GOLD if _won else _ASH


func mote_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for mote_v in _motes:
		var mote: Dictionary = mote_v
		if float(mote.age) >= 0.0:
			points.append(_point(mote))
	return points


func advance(delta: float) -> void:
	for index in _motes.size():
		var mote: Dictionary = _motes[index]
		mote.age = float(mote.age) + delta
		if float(mote.age) >= _life:
			_motes[index] = _new_mote(index)
	queue_redraw()


func _process(delta: float) -> void:
	if visible and not _motes.is_empty():
		advance(delta)


func _draw() -> void:
	for mote_v in _motes:
		var mote: Dictionary = mote_v
		var age := float(mote.age)
		if age < 0.0:
			continue
		var alpha := sin(PI * age / _life) * 0.9
		var pos := _point(mote)
		if bool(mote.petal):
			draw_set_transform(pos, float(mote.phase) + age * 2.0, Vector2(1.0, 0.55))
			draw_circle(Vector2.ZERO, _size * 1.5, Color(_PETAL, alpha))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
			continue
		var color := mote_color()
		draw_circle(pos, _size * 2.4, Color(color, alpha * 0.22))
		draw_circle(pos, _size, Color(color, alpha))
		draw_circle(pos, _size * 0.4, Color(Color.WHITE, alpha * (0.9 if _won else 0.4)))


func _new_mote(index: int) -> Dictionary:
	var height := maxf(size.y, 1.0)
	var start_y := (
		height * _rng.randf_range(0.6, 1.0) if _won else height * _rng.randf_range(0.0, 0.4)
	)
	return {
		"x": _rng.randf_range(0.0, maxf(size.x, 1.0)),
		"y": start_y,
		"speed": _speed * _rng.randf_range(0.7, 1.3),
		"phase": _rng.randf_range(0.0, TAU),
		"petal": _won and index % _petal_every == 0,
		"age": 0.0,
	}


func _point(mote: Dictionary) -> Vector2:
	var age := maxf(float(mote.age), 0.0)
	var direction := -1.0 if _won else 1.0
	var sway := sin(float(mote.phase) + age * 1.7) * 14.0
	return Vector2(float(mote.x) + sway, float(mote.y) + direction * float(mote.speed) * age)
