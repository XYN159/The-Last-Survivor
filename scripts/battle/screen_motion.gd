extends Node

## 战斗画面上不跟倍速走的界面动效：进关暗幕淡开、上下栏滑入，漏怪时生命数字抖动，
## 灵力光点到达时灵力数字亮一下，结算卡像符纸一样从上往下展开。
## 按真实时间推进；时长和幅度读 MotionConfig，都是临时值。
## 只改位置、缩放和透明度，不改按钮的可点状态，也不挡点击。

const ResultMotes := preload("res://scripts/battle/result_motes.gd")

var _veil_hold: float = 0.12
var _veil_fade: float = 0.6
var _bar_delay: float = 0.08
var _bar_slide: float = 0.5
var _top_slide: float = 170.0
var _bottom_slide: float = 320.0
var _shake_px: float = 9.0
var _shake_sec: float = 0.36
var _shake_hz: float = 16.0
var _glow_sec: float = 0.28
var _glow_strength: float = 0.5
var _dim_sec: float = 0.3
var _unfold_sec: float = 0.45
var _unfold_from: float = 0.04
var _content_delay: float = 0.3
var _content_fade: float = 0.25

var _top_nodes: Array[Control] = []
var _bottom_nodes: Array[Control] = []
var _bases: Dictionary = {}
var _veil_alpha: float = 1.0
var _dim_alpha: float = 0.78
var _entry_age: float = -1.0
var _shake_age: float = -1.0
var _shake_applied: float = 0.0
var _glow_age: float = -1.0
var _result_age: float = -1.0

@onready var _veil: ColorRect = %EntryVeil
@onready var _top_frame: Control = %TopFrame
@onready var _top_bar: Control = %TopBar
@onready var _speed_button: Control = %SpeedButton
@onready var _bottom_bar: Control = %BottomBar
@onready var _life_label: Label = %LifeLabel
@onready var _spirit_label: Label = %SpiritLabel
@onready var _dimmer: ColorRect = %ResultDimmer
@onready var _card: Control = %ResultCard
@onready var _column: Control = %ResultColumn
@onready var _seal: CanvasItem = %CardSeal
@onready var _motes: ResultMotes = %ResultMotes


func setup(config: MotionConfig) -> void:
	_veil_hold = config.number("entry", "veil_hold_sec", _veil_hold)
	_veil_fade = config.number("entry", "veil_fade_sec", _veil_fade)
	_bar_delay = config.number("entry", "bar_delay_sec", _bar_delay)
	_bar_slide = config.number("entry", "bar_slide_sec", _bar_slide)
	_top_slide = config.number("entry", "top_slide_px", _top_slide)
	_bottom_slide = config.number("entry", "bottom_slide_px", _bottom_slide)
	_shake_px = config.number("leak", "life_shake_px", _shake_px)
	_shake_sec = config.number("leak", "life_shake_sec", _shake_sec)
	_shake_hz = config.number("leak", "life_shake_hz", _shake_hz)
	_glow_sec = config.number("spirit_glow", "glow_sec", _glow_sec)
	_glow_strength = config.number("spirit_glow", "strength", _glow_strength)
	_dim_sec = config.number("result", "dim_sec", _dim_sec)
	_unfold_sec = config.number("result", "unfold_sec", _unfold_sec)
	_unfold_from = config.number("result", "unfold_from_scale", _unfold_from)
	_content_delay = config.number("result", "content_delay_sec", _content_delay)
	_content_fade = config.number("result", "content_fade_sec", _content_fade)
	_top_nodes = [_top_frame, _top_bar, _speed_button]
	_bottom_nodes = [_bottom_bar]
	for node in _top_nodes + _bottom_nodes:
		_bases[node] = node.position
	_dim_alpha = _dimmer.color.a
	_motes.setup(config)


func play_entry() -> void:
	_entry_age = 0.0
	_veil.visible = true
	_apply_entry()


func finish_entry() -> void:
	if _entry_age >= 0.0:
		_entry_age = entry_duration()
		_apply_entry()


func entry_duration() -> float:
	return maxf(_veil_hold + _veil_fade, _bar_delay + _bar_slide)


func is_entry_playing() -> bool:
	return _entry_age >= 0.0 and _entry_age < entry_duration()


func base_position(node: Control) -> Vector2:
	return _bases.get(node, node.position)


func shake_life() -> void:
	_shake_age = 0.0


func is_life_shaking() -> bool:
	return _shake_age >= 0.0


func life_shake_offset() -> float:
	return _shake_applied


func glow_spirit() -> void:
	_glow_age = 0.0


func play_result(won: bool) -> void:
	_result_age = 0.0
	_card.pivot_offset = Vector2(_card.size.x * 0.5, 0.0)
	_seal.modulate = Color.WHITE if won else Color(0.62, 0.6, 0.66)
	_motes.play(won)
	_apply_result()


func result_duration() -> float:
	return maxf(_unfold_sec, _content_delay + _content_fade)


func is_result_playing() -> bool:
	return _result_age >= 0.0 and _result_age < result_duration()


func advance(delta: float) -> void:
	if is_entry_playing():
		_entry_age = minf(_entry_age + delta, entry_duration())
		_apply_entry()
	if _shake_age >= 0.0:
		_shake_age += delta
		_apply_shake()
	if _glow_age >= 0.0:
		_glow_age += delta
		_apply_glow()
	if is_result_playing():
		_result_age = minf(_result_age + delta, result_duration())
		_apply_result()


func _process(delta: float) -> void:
	advance(delta)


func _apply_entry() -> void:
	var veil_t := MotionEase.ratio(_entry_age - _veil_hold, _veil_fade)
	_veil.color.a = _veil_alpha * (1.0 - MotionEase.out_cubic(veil_t))
	if veil_t >= 1.0:
		_veil.visible = false
	var slide := 1.0 - MotionEase.out_cubic(MotionEase.ratio(_entry_age - _bar_delay, _bar_slide))
	for node in _top_nodes:
		node.position = (_bases[node] as Vector2) + Vector2(0, -_top_slide * slide)
	for node in _bottom_nodes:
		node.position = (_bases[node] as Vector2) + Vector2(0, _bottom_slide * slide)


func _apply_shake() -> void:
	var t := MotionEase.ratio(_shake_age, _shake_sec)
	var offset := sin(TAU * _shake_hz * _shake_age) * _shake_px * (1.0 - t)
	if t >= 1.0:
		_shake_age = -1.0
		offset = 0.0
	# 只加减抖动自己那一截，不管标签原来摆在哪，抖完都回到原位。
	_life_label.position.x += offset - _shake_applied
	_shake_applied = offset


func _apply_glow() -> void:
	var t := MotionEase.ratio(_glow_age, _glow_sec)
	if t >= 1.0:
		_glow_age = -1.0
		_spirit_label.modulate = Color.WHITE
		return
	var boost := 1.0 + _glow_strength * (1.0 - t)
	_spirit_label.modulate = Color(boost, boost, boost * 0.85)


func _apply_result() -> void:
	_dimmer.color.a = _dim_alpha * MotionEase.out_cubic(MotionEase.ratio(_result_age, _dim_sec))
	var unfold := MotionEase.ratio(_result_age, _unfold_sec)
	_card.scale = Vector2(
		lerpf(0.9, 1.0, MotionEase.out_cubic(unfold)),
		lerpf(_unfold_from, 1.0, MotionEase.out_back(unfold, 0.9)),
	)
	_card.modulate.a = minf(unfold * 3.0, 1.0)
	var content := MotionEase.ratio(_result_age - _content_delay, _content_fade)
	_column.modulate.a = MotionEase.out_cubic(content)
