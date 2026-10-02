extends Node

## 整屏动效：进关、结算出现、数字弹跳和抖动、小面板弹出、离场转暗。
## 只动 modulate、scale、position，不改文字和数值，读文字的测试照常拿到最终结果。
## 时长读 ui_motion.json（动效临时值）和 feel.json 的 spirit_counter_bump（战斗策划）。

const _FLASH_LIFE := Color(1.6, 1.15, 1.15)
const _FLASH_GOLD := Color(1.45, 1.3, 1.0)
const _FLASH_WARN := Color(1.5, 1.05, 1.05)
const _MOTE_WIN := Color("#F4D98A")
const _MOTE_LOSE := Color("#B9B4A8")

var _config: MotionConfig = MotionConfig.from_dictionary({})
var _bump_scale: float = 1.25
var _bump_sec: float = 0.15
var _last_bump_msec: int = -100000
var _tweens: Dictionary = {}
var _rest_positions: Dictionary = {}


func setup(config: MotionConfig, feel: Dictionary) -> void:
	_config = config
	var bump: Dictionary = feel.get("spirit_counter_bump", {})
	_bump_scale = CombatCatalog.read_float(bump.get("scale", 1.25), 1.25)
	_bump_sec = CombatCatalog.read_float(bump.get("duration_sec", 0.15), 0.15)


## 进关：暗幕散开，顶栏和底栏滑进来，棋盘淡入，左侧挂下一张写着关卡名的符札。
func play_entry(
	veil: ColorRect,
	bars: Array[Control],
	layers: Array[Control],
	ofuda: Control,
	ofuda_label: Label,
	level_name: String,
) -> void:
	var veil_sec := _num("entry", "veil_fade_sec", 0.5)
	var bar_sec := _num("entry", "bar_slide_sec", 0.45)
	veil.visible = true
	veil.color.a = 1.0
	var veil_tween := _fresh(veil, "veil")
	veil_tween.tween_property(veil, "color:a", 0.0, veil_sec)
	veil_tween.tween_callback(veil.hide)
	for bar in bars:
		bar.modulate.a = 0.0
	_slide_bars(bars, bar_sec)
	for layer in layers:
		layer.modulate.a = 0.0
		var layer_tween := _fresh(layer, "modulate")
		layer_tween.tween_property(layer, "modulate:a", 1.0, _num("entry", "board_fade_sec", 0.5))
	_drop_ofuda(ofuda, ofuda_label, level_name)


## 截图模式和测试里直接跳到进关结束的样子。
func skip_entry(veil: ColorRect, ofuda: Control) -> void:
	veil.visible = false
	veil.color.a = 0.0
	ofuda.visible = false


## 结算：暗幕压下，符札卡片像卷轴一样展开，标题落印，结界纹转起来，按钮依次浮出。
func play_result(
	dimmer: ColorRect,
	card: Control,
	title: Label,
	fade_ins: Array[Control],
	seal: Control,
	motes: CPUParticles2D,
	won: bool,
) -> void:
	var dim_alpha := dimmer.color.a
	dimmer.color.a = 0.0
	_fresh(dimmer, "dim").tween_property(
		dimmer, "color:a", dim_alpha, _num("result", "dim_sec", 0.3)
	)
	card.pivot_offset = card.size * 0.5
	card.scale = Vector2(1.0, 0.04)
	card.modulate.a = 0.0
	var card_sec := _num("result", "card_sec", 0.4)
	var card_tween := _fresh(card, "card").set_parallel(true)
	(
		card_tween
		. tween_property(card, "scale", Vector2.ONE, card_sec)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	card_tween.tween_property(card, "modulate:a", 1.0, card_sec * 0.5)
	_stamp_title(title)
	var delay := _num("result", "button_delay_sec", 0.45)
	var stagger := _num("result", "button_stagger_sec", 0.08)
	for index in fade_ins.size():
		_rise_in(fade_ins[index], delay + stagger * float(index))
	if seal.has_method("play"):
		seal.call(
			"play", won, _num("result", "seal_sec", 0.6), _num("result", "seal_spin_per_sec", 0.25)
		)
	motes.color = _MOTE_WIN if won else _MOTE_LOSE
	motes.direction = Vector2(0, -1) if won else Vector2(0, 1)
	motes.gravity = Vector2(0, -12) if won else Vector2(0, 14)
	motes.restart()
	motes.emitting = true


## 灵力栏被光点打到时弹一下。短时间内多次到达只弹一次（feel.json 的 spirit_counter_bump）。
func bump(control: Control) -> void:
	var now := Time.get_ticks_msec()
	if float(now - _last_bump_msec) < _bump_sec * 1000.0:
		return
	_last_bump_msec = now
	_pulse(control, _bump_scale, _bump_sec, _FLASH_GOLD)


func pop(control: Control) -> void:
	_pulse(
		control,
		_num("wave_label", "pop_scale", 1.2),
		_num("wave_label", "pop_sec", 0.25),
		_FLASH_GOLD,
	)


func hit_life(control: Control) -> void:
	_shake(control, _num("guard_hit", "shake_px", 8.0), _num("guard_hit", "shake_sec", 0.3))
	_flash(control, _FLASH_LIFE, _num("guard_hit", "shake_sec", 0.3))


func warn(control: Control) -> void:
	_shake(control, _num("hint", "shake_px", 10.0), _num("hint", "shake_sec", 0.25))
	_flash(control, _FLASH_WARN, _num("hint", "shake_sec", 0.25))


func fade_in(control: Control) -> void:
	control.modulate.a = 0.35
	_fresh(control, "modulate").tween_property(
		control, "modulate:a", 1.0, _num("hint", "fade_sec", 0.15)
	)


func pop_in(control: Control) -> void:
	var seconds := _num("panel", "pop_sec", 0.15)
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 0.9
	control.modulate.a = 0.0
	var tween := _fresh(control, "pop_in").set_parallel(true)
	(
		tween
		. tween_property(control, "scale", Vector2.ONE, seconds)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(control, "modulate:a", 1.0, seconds)


## 离场：暗幕合上再换场景，和下一个画面的进关暗幕接上。
func leave(veil: ColorRect, then: Callable) -> void:
	veil.visible = true
	var tween := _fresh(veil, "veil")
	tween.tween_property(veil, "color:a", 1.0, _num("transition", "leave_sec", 0.25))
	tween.tween_callback(then)


## 栏里的文字第一帧还没排好版（自动换行的提示要等宽度确定），等两帧再记停靠位置。
func _slide_bars(bars: Array[Control], seconds: float) -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	for index in bars.size():
		var bar := bars[index]
		if not is_instance_valid(bar):
			continue
		var rest := bar.position
		var away := -bar.size.y if index == 0 else bar.size.y
		bar.position = rest + Vector2(0, away)
		bar.modulate.a = 1.0
		var tween := _fresh(bar, "position")
		tween.tween_property(bar, "position", rest, seconds).set_trans(Tween.TRANS_CUBIC).set_ease(
			Tween.EASE_OUT
		)


func hide_now(control: Control) -> void:
	for channel in ["ofuda", "modulate", "position"]:
		var key := "%d:%s" % [control.get_instance_id(), channel]
		var old: Tween = _tweens.get(key)
		if old != null and old.is_valid():
			old.kill()
	control.visible = false


func _drop_ofuda(ofuda: Control, label: Label, level_name: String) -> void:
	label.text = "\n".join(_characters(level_name))
	var rest := ofuda.position
	var drop := _num("entry", "ofuda_drop_px", 70.0)
	ofuda.visible = true
	ofuda.position = rest - Vector2(0, drop)
	ofuda.modulate.a = 0.0
	ofuda.pivot_offset = Vector2(ofuda.size.x * 0.5, 0.0)
	ofuda.rotation = -0.08
	var drop_sec := _num("entry", "ofuda_drop_sec", 0.5)
	var tween := _fresh(ofuda, "ofuda")
	tween.tween_interval(_num("entry", "ofuda_delay_sec", 0.3))
	tween.tween_property(ofuda, "position", rest, drop_sec).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tween.parallel().tween_property(ofuda, "modulate:a", 1.0, drop_sec * 0.5)
	tween.parallel().tween_method(_swing.bind(ofuda), 0.0, 1.0, drop_sec * 2.0)
	tween.tween_interval(_num("entry", "ofuda_hold_sec", 1.6))
	var fade_sec := _num("entry", "ofuda_fade_sec", 0.4)
	tween.tween_property(ofuda, "modulate:a", 0.0, fade_sec)
	tween.parallel().tween_property(ofuda, "position", rest + Vector2(0, -24), fade_sec)
	tween.tween_callback(ofuda.hide)
	tween.tween_callback(func() -> void: ofuda.position = rest)


func _swing(t: float, ofuda: Control) -> void:
	ofuda.rotation = -0.08 * cos(t * TAU * 1.5) * (1.0 - t)


func _stamp_title(title: Label) -> void:
	title.pivot_offset = title.size * 0.5
	var from := _num("result", "title_from_scale", 1.4)
	title.scale = Vector2.ONE * from
	title.modulate.a = 0.0
	var seconds := _num("result", "title_sec", 0.3)
	var tween := _fresh(title, "stamp")
	tween.tween_interval(_num("result", "title_delay_sec", 0.2))
	tween.tween_property(title, "scale", Vector2.ONE, seconds).set_trans(Tween.TRANS_BACK).set_ease(
		Tween.EASE_OUT
	)
	tween.parallel().tween_property(title, "modulate:a", 1.0, seconds * 0.6)


func _rise_in(control: Control, delay: float) -> void:
	var seconds := _num("result", "button_sec", 0.2)
	control.pivot_offset = control.size * 0.5
	control.modulate.a = 0.0
	control.scale = Vector2.ONE * 0.9
	var tween := _fresh(control, "rise")
	tween.tween_interval(delay)
	tween.tween_property(control, "modulate:a", 1.0, seconds)
	(
		tween
		. parallel()
		. tween_property(control, "scale", Vector2.ONE, seconds)
		. set_trans(Tween.TRANS_BACK)
		. set_ease(Tween.EASE_OUT)
	)


func _pulse(control: Control, peak: float, seconds: float, flash: Color) -> void:
	control.pivot_offset = control.size * 0.5
	var half := maxf(seconds * 0.5, 0.01)
	var tween := _fresh(control, "pulse")
	tween.tween_property(control, "scale", Vector2.ONE * peak, half).set_trans(Tween.TRANS_QUAD)
	tween.tween_property(control, "scale", Vector2.ONE, half).set_trans(Tween.TRANS_QUAD)
	_flash(control, flash, seconds)


func _flash(control: Control, color: Color, seconds: float) -> void:
	control.modulate = Color(color, control.modulate.a)
	_fresh(control, "flash").tween_property(
		control, "modulate", Color(1, 1, 1, control.modulate.a), maxf(seconds, 0.01)
	)


func _shake(control: Control, px: float, seconds: float) -> void:
	var key := control.get_instance_id()
	if not _rest_positions.has(key):
		_rest_positions[key] = control.position
	var rest: Vector2 = _rest_positions[key]
	var step := maxf(seconds / 5.0, 0.01)
	var tween := _fresh(control, "shake")
	for offset in [px, -px, px * 0.5, -px * 0.5, 0.0]:
		tween.tween_property(control, "position", rest + Vector2(float(offset), 0), step)
	tween.tween_callback(func() -> void: _rest_positions.erase(key))


func _fresh(target: Object, channel: String) -> Tween:
	var key := "%d:%s" % [target.get_instance_id(), channel]
	var old: Tween = _tweens.get(key)
	if old != null and old.is_valid():
		old.kill()
	var tween := create_tween()
	_tweens[key] = tween
	return tween


func _num(section: String, key: String, fallback: float) -> float:
	return _config.number(section, key, fallback)


func _characters(text: String) -> PackedStringArray:
	var result := PackedStringArray()
	for index in text.length():
		result.append(text.substr(index, 1))
	return result
