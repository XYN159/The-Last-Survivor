extends Control

## 棋盘上的动效层，盖在 BoardView 上面，大小和棋盘一样，不接收点击。
## 只画反馈：放置格呼吸光、选中框、放下时的结界印、命中光点、击倒光点飞向灵力、守护点受击。
## 规则和数字不在这里：反馈时长读 feel.json（战斗策划）和 ui_motion.json（动效临时值）。
## 路线格上只出现一闪而过的细线和光点，不铺实色，免得挡住残影。

signal orb_arrived

const _PAPER := Color("#F5EFE2")
const _VERMILION := Color("#C8323C")
const _GOLD := Color("#D4A94F")
const _GLOW := Color("#FFF3B0")
const _MOTE := Color("#F4D98A")
const _MOTE_CORE := Color("#FFFBEF")
const _SPIRIT := Color("#5CCBF0")
const _SPIRIT_CORE := Color("#E6FAFF")
const _SHADE := Color("#D9DCE0")
const _LIFE := Color("#E8505B")
const _FADED := Color("#B9B4A8")
const _INK := Color("#2B2230")

var _columns: int = 7
var _rows: int = 12
var _cell: float = 128.0
var _cells: Array = []
var _units: Array = []
var _selected_col: int = -1
var _selected_row: int = -1
var _clock: float = 0.0
var _snap_left: float = 0.0
var _sweep_age: float = -1.0
var _effects: Array = []
var _orbs: Array = []
var _lands: Dictionary = {}
var _pops: Dictionary = {}
var _spirit_target: Vector2 = Vector2.ZERO
var _rng := RandomNumberGenerator.new()

var _breath_sec: float = 0.8
var _snap_sec: float = 0.14
var _sweep_step: float = 0.12
var _sweep_sec: float = 0.5
var _barrier_sec: float = 0.9
var _land_sec: float = 0.25
var _land_from: float = 1.35
var _seal_sec: float = 0.5
var _place_motes: int = 6
var _place_mote_sec: float = 0.6
var _sell_motes: int = 6
var _sell_mote_sec: float = 0.5
var _spark_count: int = 3
var _spark_sec: float = 0.22
var _puff_sec: float = 0.12
var _guard_ring_sec: float = 0.5
var _orbs_per_kill: int = 6
var _orb_sec: float = 0.5
var _max_orbs: int = 60
var _level_up_sec: float = 0.3
var _level_up_scale: float = 1.15


func setup(catalog: CombatCatalog, config: MotionConfig) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_rng.seed = 20261002
	var layout := catalog.board()
	_columns = int(layout.columns)
	_rows = int(layout.rows)
	_cell = float(layout.cell_size)
	var map: Dictionary = catalog.level().get("map", {})
	_cells = map.get("cells", [])
	_read_feel(catalog.feel())
	_breath_sec = config.number("slot", "breath_sec", _breath_sec)
	_snap_sec = config.number("slot", "select_snap_sec", _snap_sec)
	_sweep_step = config.number("entry", "slot_sweep_step_sec", _sweep_step)
	_sweep_sec = config.number("entry", "slot_sweep_sec", _sweep_sec)
	_barrier_sec = config.number("entry", "barrier_sec", _barrier_sec)
	_land_sec = config.number("place", "land_sec", _land_sec)
	_land_from = config.number("place", "land_from_scale", _land_from)
	_seal_sec = config.number("place", "seal_sec", _seal_sec)
	_place_motes = config.count("place", "mote_count", _place_motes)
	_place_mote_sec = config.number("place", "mote_sec", _place_mote_sec)
	_sell_motes = config.count("sell", "mote_count", _sell_motes)
	_sell_mote_sec = config.number("sell", "mote_sec", _sell_mote_sec)
	_spark_count = config.count("hit", "spark_count", _spark_count)
	_spark_sec = config.number("hit", "spark_sec", _spark_sec)
	_puff_sec = config.number("kill", "puff_sec", _puff_sec)
	_guard_ring_sec = config.number("guard_hit", "ring_sec", _guard_ring_sec)


func set_spirit_target(local_point: Vector2) -> void:
	_spirit_target = local_point


func sync(state: Dictionary, selected_col: int, selected_row: int) -> void:
	_units = state.get("units", [])
	if selected_col != _selected_col or selected_row != _selected_row:
		_snap_left = _snap_sec if selected_col >= 0 else 0.0
	_selected_col = selected_col
	_selected_row = selected_row
	queue_redraw()


func play_entry() -> void:
	_sweep_age = 0.0
	_add_effect("barrier", _guard_center(), _barrier_sec)


func play_place(col: int, row: int, unit_id: int) -> void:
	var center := _cell_center(col, row)
	_lands[unit_id] = {"age": 0.0, "life": _land_sec}
	_add_effect("seal", center, _seal_sec)
	_add_motes(center, _place_motes, _place_mote_sec, _MOTE)


func play_level_up(col: int, row: int, unit_id: int) -> void:
	_pops[unit_id] = {"age": 0.0, "life": _level_up_sec}
	_add_effect("level_up", _cell_center(col, row), _level_up_sec)


func play_sell(col: int, row: int) -> void:
	_add_effect("puff", _cell_center(col, row), _seal_sec)
	_add_motes(_cell_center(col, row), _sell_motes, _sell_mote_sec, _FADED)


func push_events(events: Array) -> void:
	for event_v in events:
		if typeof(event_v) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_v
		var kind := str(event.get("type", ""))
		var point := Vector2(float(event.get("x", 0.0)), float(event.get("y", 0.0))) * _cell
		match kind:
			"damage":
				_add_sparks(point)
			"death":
				_add_effect("puff", point, _puff_sec)
				_add_orbs(point)
			"leak":
				_add_effect("guard", _guard_center(), _guard_ring_sec)


func advance(delta: float) -> void:
	_clock += delta
	_snap_left = maxf(0.0, _snap_left - delta)
	if _sweep_age >= 0.0:
		_sweep_age += delta
		if _sweep_age > _sweep_step * float(_slot_count()) + _sweep_sec:
			_sweep_age = -1.0
	_age_list(_effects, delta)
	_age_orbs(delta)
	_age_map(_lands, delta)
	_age_map(_pops, delta)
	queue_redraw()


func unit_scales() -> Dictionary:
	var scales := {}
	for id_v in _lands.keys():
		var item: Dictionary = _lands[id_v]
		scales[id_v] = _land_scale(float(item.age) / maxf(float(item.life), 0.001))
	for id_v in _pops.keys():
		var item: Dictionary = _pops[id_v]
		var t := float(item.age) / maxf(float(item.life), 0.001)
		var bump := 1.0 + (_level_up_scale - 1.0) * sin(PI * t)
		scales[id_v] = float(scales.get(id_v, 1.0)) * bump
	return scales


func active_effect_count() -> int:
	return _effects.size()


func active_orb_count() -> int:
	return _orbs.size()


func is_sweeping() -> bool:
	return _sweep_age >= 0.0


func _draw() -> void:
	_draw_slots()
	_draw_selection()
	for effect_v in _effects:
		_draw_effect(effect_v)
	for orb_v in _orbs:
		_draw_orb(orb_v)


func _draw_slots() -> void:
	var breath := 0.5 + 0.5 * sin(TAU * _clock / maxf(_breath_sec * 2.0, 0.01))
	var index := 0
	for row in _rows:
		for col in _columns:
			if _mark(col, row) != ".":
				continue
			var lit := _sweep_light(index)
			index += 1
			if _occupied(col, row):
				continue
			var rect := _cell_rect(col, row).grow(-8.0)
			draw_rect(rect, Color(_GLOW, 0.14 + 0.2 * breath + 0.45 * lit))
			if lit > 0.0:
				draw_rect(rect.grow(6.0 * lit), Color(_PAPER, 0.8 * lit), false, 3.0)


func _draw_selection() -> void:
	if _selected_col < 0 or _selected_row < 0:
		return
	var t := 0.0 if _snap_sec <= 0.0 else _snap_left / _snap_sec
	var rect := _cell_rect(_selected_col, _selected_row).grow(-6.0 + 14.0 * t)
	var alpha := 1.0 - 0.6 * t
	draw_rect(rect.grow(3.0), Color(_INK, 0.55 * alpha), false, 3.0)
	draw_rect(rect, Color(_GOLD, alpha), false, 5.0)
	draw_rect(rect.grow(-8.0), Color(_PAPER, 0.85 * alpha), false, 2.0)
	var seal := Vector2(14, 14)
	var corners := [
		rect.position,
		Vector2(rect.end.x, rect.position.y),
		Vector2(rect.position.x, rect.end.y),
		rect.end,
	]
	for corner_v in corners:
		draw_rect(Rect2((corner_v as Vector2) - seal * 0.5, seal), Color(_VERMILION, alpha))


func _draw_effect(effect: Dictionary) -> void:
	var t := clampf(float(effect.age) / maxf(float(effect.life), 0.001), 0.0, 1.0)
	var center: Vector2 = effect.pos
	match str(effect.kind):
		"seal":
			_draw_seal(center, t)
		"barrier":
			_draw_barrier(center, t)
		"level_up":
			draw_circle(center, _cell * 0.42, Color(_MOTE_CORE, 0.45 * (1.0 - t)))
			_draw_ring(center, _cell * lerpf(0.3, 0.62, _ease_out(t)), _GOLD, 1.0 - t, 5.0)
		"puff":
			_draw_ring(center, _cell * lerpf(0.12, 0.36, _ease_out(t)), _SHADE, 1.0 - t, 4.0)
		"guard":
			_draw_guard_hit(center, t)
		"spark":
			_draw_sparks(effect, t)
		"motes":
			_draw_motes(effect, t)


func _draw_seal(center: Vector2, t: float) -> void:
	var fade := 1.0 - t
	var radius := _cell * lerpf(0.24, 0.5, _ease_out(t))
	_draw_ring(center, radius, _VERMILION, fade, 4.0)
	_draw_ring(center, radius * 0.78, _PAPER, fade, 2.0)
	_draw_ticks(center, radius * 0.89, 8, t * 0.8, Color(_VERMILION, fade))
	var reach := _cell * lerpf(0.08, 0.4, _ease_out(t))
	for i in 4:
		var angle := PI * 0.25 + PI * 0.5 * float(i)
		var point := center + Vector2.from_angle(angle) * reach
		_draw_ofuda(point, angle + PI * 0.5 + t * 1.6, fade)


func _draw_barrier(center: Vector2, t: float) -> void:
	var alpha := sin(PI * t)
	var radius := _cell * lerpf(0.2, 0.95, _ease_out(t))
	_draw_ring(center, radius, _VERMILION, alpha, 5.0)
	_draw_ring(center, radius * 0.86, _PAPER, alpha, 3.0)
	_draw_ticks(center, radius * 0.93, 12, t * 1.2, Color(_PAPER, alpha))


func _draw_guard_hit(center: Vector2, t: float) -> void:
	var fade := 1.0 - t
	var radius := _cell * lerpf(0.32, 0.72, _ease_out(t))
	_draw_ring(center, radius, _LIFE, fade, 5.0)
	for i in 6:
		var direction := Vector2.from_angle(TAU * float(i) / 6.0 + 0.3)
		var from := center + direction * _cell * 0.3
		draw_line(from, from + direction * _cell * 0.22 * _ease_out(t), Color(_LIFE, fade), 3.0)


func _draw_sparks(effect: Dictionary, t: float) -> void:
	var center: Vector2 = effect.pos
	for direction_v in effect.dirs:
		var point := center + (direction_v as Vector2) * 24.0 * _ease_out(t)
		_draw_mote(point, lerpf(5.0, 2.0, t), _MOTE, 1.0 - t)


func _draw_motes(effect: Dictionary, t: float) -> void:
	var center: Vector2 = effect.pos
	var color: Color = effect.color
	for offset_v in effect.offsets:
		var offset: Vector2 = offset_v
		var rise := _cell * 0.55 * _ease_out(t)
		var sway := sin(t * TAU + offset.x) * 6.0
		var point := center + Vector2(offset.x + sway, offset.y - rise)
		_draw_mote(point, 4.5, color, sin(PI * t))


func _draw_orb(orb: Dictionary) -> void:
	var t := float(orb.age) / maxf(float(orb.life), 0.001)
	if t < 0.0:
		return
	var orb_size := float(orb.size)
	for step in 3:
		var back := clampf(t - 0.05 * float(step + 1), 0.0, 1.0)
		var trail := _bezier(orb, _ease_in_out(back))
		draw_circle(trail, 6.0 * orb_size * (1.0 - 0.25 * float(step)), Color(_SPIRIT, 0.25))
	var point := _bezier(orb, _ease_in_out(t))
	draw_circle(point, 15.0 * orb_size, Color(_SPIRIT, 0.28))
	draw_circle(point, 8.0 * orb_size, _SPIRIT)
	draw_circle(point, 4.0 * orb_size, _SPIRIT_CORE)


func _draw_mote(point: Vector2, radius: float, color: Color, alpha: float) -> void:
	if alpha <= 0.0:
		return
	draw_circle(point, radius * 2.2, Color(color, 0.25 * alpha))
	draw_circle(point, radius, Color(color, alpha))
	draw_circle(point, radius * 0.45, Color(_MOTE_CORE, alpha))


func _draw_ring(center: Vector2, radius: float, color: Color, alpha: float, width: float) -> void:
	if alpha <= 0.0:
		return
	draw_arc(center, radius, 0.0, TAU, 48, Color(color, alpha), width, true)


func _draw_ticks(center: Vector2, radius: float, count: int, spin: float, color: Color) -> void:
	for i in count:
		var angle := spin + TAU * float(i) / float(count)
		var direction := Vector2.from_angle(angle)
		draw_line(
			center + direction * (radius - 5.0), center + direction * (radius + 5.0), color, 2.0
		)


func _draw_ofuda(point: Vector2, angle: float, alpha: float) -> void:
	draw_set_transform(point, angle, Vector2.ONE)
	draw_rect(Rect2(Vector2(-6, -11), Vector2(12, 22)), Color(_PAPER, alpha))
	draw_rect(Rect2(Vector2(-1.5, -7), Vector2(3, 14)), Color(_VERMILION, alpha))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _add_effect(kind: String, point: Vector2, life: float) -> Dictionary:
	var effect := {"kind": kind, "pos": point, "age": 0.0, "life": maxf(life, 0.01)}
	_effects.append(effect)
	return effect


func _add_motes(point: Vector2, amount: int, life: float, color: Color) -> void:
	var effect := _add_effect("motes", point, life)
	var offsets: Array = []
	for i in amount:
		var spread := (float(i) + 0.5) / float(maxi(amount, 1)) - 0.5
		offsets.append(Vector2(spread * _cell * 0.7, _rng.randf_range(0.0, _cell * 0.25)))
	effect["offsets"] = offsets
	effect["color"] = color


func _add_sparks(point: Vector2) -> void:
	var effect := _add_effect("spark", point, _spark_sec)
	var dirs: Array = []
	var base := _rng.randf() * TAU
	for i in _spark_count:
		dirs.append(Vector2.from_angle(base + TAU * float(i) / float(maxi(_spark_count, 1))))
	effect["dirs"] = dirs


func _add_orbs(point: Vector2) -> void:
	var room := _max_orbs - _orbs.size()
	if room <= 0:
		return
	var amount := mini(_orbs_per_kill, room)
	var orb_size := 1.0
	if amount < _orbs_per_kill:
		orb_size = clampf(float(_orbs_per_kill) / float(amount), 1.5, 2.0)
	for i in amount:
		var burst := Vector2.from_angle(TAU * float(i) / float(amount) + _rng.randf()) * 18.0
		var start := point + burst
		var bend := Vector2(_rng.randf_range(-140.0, 140.0), _rng.randf_range(-60.0, -200.0))
		(
			_orbs
			. append(
				{
					"from": start,
					"ctrl": start.lerp(_spirit_target, 0.35) + bend,
					"to": _spirit_target,
					"age": -0.03 * float(i),
					"life": _orb_sec,
					"size": orb_size,
				}
			)
		)


func _age_list(items: Array, delta: float) -> void:
	var index := items.size() - 1
	while index >= 0:
		var item: Dictionary = items[index]
		item.age = float(item.age) + delta
		if float(item.age) >= float(item.life):
			items.remove_at(index)
		index -= 1


func _age_orbs(delta: float) -> void:
	var index := _orbs.size() - 1
	while index >= 0:
		var orb: Dictionary = _orbs[index]
		orb.age = float(orb.age) + delta
		if float(orb.age) >= float(orb.life):
			_orbs.remove_at(index)
			orb_arrived.emit()
		index -= 1


func _age_map(items: Dictionary, delta: float) -> void:
	for id_v in items.keys():
		var item: Dictionary = items[id_v]
		item.age = float(item.age) + delta
		if float(item.age) >= float(item.life):
			items.erase(id_v)


func _read_feel(feel: Dictionary) -> void:
	var burst: Dictionary = feel.get("kill_burst", {})
	_orbs_per_kill = maxi(CombatCatalog.read_int(burst.get("particles_per_kill", 6), 6), 1)
	_orb_sec = CombatCatalog.read_float(burst.get("fly_duration_sec", 0.5), 0.5)
	_max_orbs = maxi(CombatCatalog.read_int(burst.get("max_active_orbs", 60), 60), 1)
	var level_up: Dictionary = feel.get("level_up", {})
	_level_up_sec = CombatCatalog.read_float(level_up.get("flash_sec", 0.3), 0.3)
	_level_up_scale = CombatCatalog.read_float(level_up.get("scale_pop", 1.15), 1.15)


func _sweep_light(index: int) -> float:
	if _sweep_age < 0.0 or _sweep_sec <= 0.0:
		return 0.0
	var local := _sweep_age - _sweep_step * float(index)
	if local < 0.0 or local > _sweep_sec:
		return 0.0
	return sin(PI * local / _sweep_sec)


func _land_scale(t: float) -> float:
	if t < 0.6:
		return lerpf(_land_from, 0.9, _ease_in(t / 0.6))
	return lerpf(0.9, 1.0, _ease_out((t - 0.6) / 0.4))


func _bezier(orb: Dictionary, t: float) -> Vector2:
	var from: Vector2 = orb.from
	var ctrl: Vector2 = orb.ctrl
	var to: Vector2 = orb.to
	return from.lerp(ctrl, t).lerp(ctrl.lerp(to, t), t)


func _ease_out(t: float) -> float:
	return 1.0 - pow(1.0 - clampf(t, 0.0, 1.0), 3.0)


func _ease_in(t: float) -> float:
	return pow(clampf(t, 0.0, 1.0), 2.0)


func _ease_in_out(t: float) -> float:
	var x := clampf(t, 0.0, 1.0)
	return x * x * (3.0 - 2.0 * x)


func _slot_count() -> int:
	var total := 0
	for row in _rows:
		for col in _columns:
			if _mark(col, row) == ".":
				total += 1
	return total


func _occupied(col: int, row: int) -> bool:
	for unit_v in _units:
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		if int(unit.get("col", -1)) == col and int(unit.get("row", -1)) == row:
			return true
	return false


func _guard_center() -> Vector2:
	for row in _rows:
		for col in _columns:
			if _mark(col, row) == "G":
				return _cell_center(col, row)
	return _cell_center(int(_columns * 0.5), _rows - 1)


func _mark(col: int, row: int) -> String:
	if row < 0 or row >= _cells.size():
		return ""
	var line := str(_cells[row])
	if col < 0 or col >= line.length():
		return ""
	return line.substr(col, 1)


func _cell_rect(col: int, row: int) -> Rect2:
	return Rect2(float(col) * _cell, float(row) * _cell, _cell, _cell)


func _cell_center(col: int, row: int) -> Vector2:
	return Vector2((float(col) + 0.5) * _cell, (float(row) + 0.5) * _cell)
