extends Control

## 庭院棋盘上的动效层：点格子时阴阳圈亮一下，放灵梦时盖章、张开结界圈、飞出符纸，
## 受击溅光点，打倒后光点飞向灵力数字，漏怪时守护点的结界裂一下。
## 它和 BoardView 一样大，是 BoardView 的子节点，自己不接收点击。
## 地面光效（选格光、结界圈）由 BoardView 在格子标记和角色之间调用 draw_ground() 画出，
## 其余光效画在本节点上，压在角色和敌人上面。时长和幅度读 MotionConfig，都是临时值。

signal spirit_mote_arrived

const BoardView := preload("res://scripts/battle/board_view.gd")
const _SELECT_TEXTURE := preload("res://assets/art/prologue_01/yin_yang_gold.png")
const _RING_TEXTURE := preload("res://assets/art/prologue_01/ofuda_ring.png")
## ofuda_ring.png 正上方那一张符纸，单独拿来当飞出的小符纸。
const _PAPER_REGION := Rect2(105, 15, 40, 44)
const _SLOT_HALF := Vector2(84, 62)
const _GUARD_HALF := Vector2(88, 65)
const _GOLD := Color("#F2C66B")
const _LIGHT := Color("#FFF4E0")
const _RING_LIGHT := Color("#FFD9A0")
const _PETAL := Color("#F7A8C4")
const _SPIRIT := Color("#A8DCFF")
const _CRACK := Color("#FF6A6A")

var _view: BoardView
var _spirit_target: Control
var _rng := RandomNumberGenerator.new()
var _selects: Array = []
var _stamps: Array = []
var _rings: Array = []
var _papers: Array = []
var _sparks: Array = []
var _motes: Array = []
var _cracks: Array = []

var _select_sec: float = 0.36
var _select_glow: float = 0.9
var _select_ring_from: float = 0.92
var _select_ring_to: float = 0.55
var _stamp_sec: float = 0.2
var _stamp_from: float = 1.35
var _stamp_squash: float = 0.92
var _settle_sec: float = 0.14
var _ring_sec: float = 0.55
var _ring_size := Vector2(160, 104)
var _paper_count: int = 6
var _paper_sec: float = 0.6
var _paper_min: float = 60.0
var _paper_max: float = 105.0
var _paper_spread: float = deg_to_rad(70.0)
var _paper_size: float = 28.0
var _spark_count: int = 4
var _spark_sec: float = 0.24
var _spark_distance: float = 34.0
var _spark_size: float = 4.0
var _max_sparks: int = 64
var _mote_count: int = 5
var _petal_every: int = 2
var _mote_sec: float = 0.7
var _mote_stagger: float = 0.05
var _burst_px: float = 46.0
var _stop_below: float = 18.0
var _mote_size: float = 5.0
var _max_motes: int = 40
var _crack_sec: float = 0.5
var _crack_count: int = 6
var _crack_length: float = 72.0
var _route_clear: float = 28.0


func setup(view: BoardView, config: MotionConfig, spirit_target: Control) -> void:
	_view = view
	_spirit_target = spirit_target
	_rng.seed = 1002
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_select_sec = config.number("select", "flash_sec", _select_sec)
	_select_glow = config.number("select", "glow_strength", _select_glow)
	_select_ring_from = config.number("select", "ring_from", _select_ring_from)
	_select_ring_to = config.number("select", "ring_to", _select_ring_to)
	_stamp_sec = config.number("place", "stamp_sec", _stamp_sec)
	_stamp_from = config.number("place", "stamp_from_scale", _stamp_from)
	_stamp_squash = config.number("place", "stamp_squash", _stamp_squash)
	_settle_sec = config.number("place", "settle_sec", _settle_sec)
	_ring_sec = config.number("place", "ring_sec", _ring_sec)
	_ring_size = Vector2(
		config.number("place", "ring_width_px", _ring_size.x),
		config.number("place", "ring_height_px", _ring_size.y),
	)
	_paper_count = config.count("place", "paper_count", _paper_count)
	_paper_sec = config.number("place", "paper_sec", _paper_sec)
	_paper_min = config.number("place", "paper_distance_min_px", _paper_min)
	_paper_max = config.number("place", "paper_distance_max_px", _paper_max)
	_paper_spread = deg_to_rad(config.number("place", "paper_spread_deg", 70.0))
	_paper_size = config.number("place", "paper_size_px", _paper_size)
	_spark_count = config.count("hit", "spark_count", _spark_count)
	_spark_sec = config.number("hit", "spark_sec", _spark_sec)
	_spark_distance = config.number("hit", "spark_distance_px", _spark_distance)
	_spark_size = config.number("hit", "spark_size_px", _spark_size)
	_max_sparks = maxi(config.count("hit", "max_sparks", _max_sparks), 1)
	_mote_count = config.count("kill", "mote_count", _mote_count)
	_petal_every = maxi(config.count("kill", "petal_every", _petal_every), 1)
	_mote_sec = config.number("kill", "mote_sec", _mote_sec)
	_mote_stagger = config.number("kill", "mote_stagger_sec", _mote_stagger)
	_burst_px = config.number("kill", "burst_px", _burst_px)
	_stop_below = config.number("kill", "stop_below_px", _stop_below)
	_mote_size = config.number("kill", "mote_size_px", _mote_size)
	_max_motes = maxi(config.count("kill", "max_motes", _max_motes), 1)
	_crack_sec = config.number("leak", "crack_sec", _crack_sec)
	_crack_count = config.count("leak", "crack_count", _crack_count)
	_crack_length = config.number("leak", "crack_length_px", _crack_length)
	_route_clear = config.number("layout", "route_clear_px", _route_clear)


func route_clear_px() -> float:
	return _route_clear


func play_select(col: int, row: int) -> void:
	_selects = [{"center": _view.cell_center(col, row), "age": 0.0}]
	queue_redraw()


func play_place(col: int, row: int, unit_id: int) -> void:
	var center := _view.cell_center(col, row)
	_selects.clear()
	_stamps.append({"id": unit_id, "age": 0.0})
	_rings.append({"center": center, "age": -_stamp_sec})
	var away := _away_from_route(center)
	for index in _paper_count:
		var spread := 0.0
		if _paper_count > 1:
			spread = lerpf(-_paper_spread, _paper_spread, float(index) / float(_paper_count - 1))
		spread += _rng.randf_range(-0.12, 0.12)
		(
			_papers
			. append(
				{
					"origin": center + away * 18.0,
					"dir": away.rotated(spread),
					"distance": _rng.randf_range(_paper_min, _paper_max),
					"angle": spread + _rng.randf_range(-0.4, 0.4),
					"spin": _rng.randf_range(-5.0, 5.0),
					"age": -_stamp_sec,
				}
			)
		)
	queue_redraw()


func push_events(events: Array) -> void:
	for event_v in events:
		if typeof(event_v) != TYPE_DICTIONARY:
			continue
		var event: Dictionary = event_v
		match str(event.get("type", "")):
			"damage":
				_spawn_sparks(_event_point(event))
			"death":
				_spawn_motes(_event_point(event))
			"leak":
				_spawn_crack(_view.guard_point())


## 盖章：先放大落下，压扁一点，再弹回原大小。不在盖章中的角色返回 1。
func unit_scale(unit_id: int) -> float:
	for stamp_v in _stamps:
		var stamp: Dictionary = stamp_v
		if int(stamp.id) != unit_id:
			continue
		var age := float(stamp.age)
		if age < _stamp_sec:
			return lerpf(_stamp_from, _stamp_squash, MotionEase.in_quad(age / _stamp_sec))
		var settle := MotionEase.ratio(age - _stamp_sec, _settle_sec)
		return lerpf(_stamp_squash, 1.0, MotionEase.out_cubic(settle))
	return 1.0


func advance(delta: float) -> void:
	_selects = _aged(_selects, delta, _select_sec)
	_stamps = _aged(_stamps, delta, _stamp_sec + _settle_sec)
	_rings = _aged(_rings, delta, _ring_sec)
	_papers = _aged(_papers, delta, _paper_sec)
	_sparks = _aged(_sparks, delta, _spark_sec)
	_cracks = _aged(_cracks, delta, _crack_sec)
	_advance_motes(delta)
	queue_redraw()


func active_count(kind: String) -> int:
	var groups := {
		"select": _selects,
		"stamp": _stamps,
		"ring": _rings,
		"paper": _papers,
		"spark": _sparks,
		"mote": _motes,
		"crack": _cracks,
	}
	return (groups.get(kind, []) as Array).size()


## 放置相关光效此刻占的范围（本节点坐标）。测试用它确认这些光效不压到路线上。
func placement_rects() -> Array[Rect2]:
	var rects: Array[Rect2] = []
	for select_v in _selects:
		rects.append(Rect2((select_v as Dictionary).center - _SLOT_HALF, _SLOT_HALF * 2.0))
	for ring_v in _rings:
		var ring: Dictionary = ring_v
		if float(ring.age) < 0.0:
			continue
		var half := _ring_half(float(ring.age))
		rects.append(Rect2((ring.center as Vector2) - half, half * 2.0))
	for paper_v in _papers:
		var paper: Dictionary = paper_v
		if float(paper.age) < 0.0:
			continue
		var half := Vector2(_paper_size, _paper_size) * 0.5
		rects.append(Rect2(_paper_point(paper) - half, half * 2.0))
	return rects


func mote_points() -> Array[Vector2]:
	var points: Array[Vector2] = []
	for mote_v in _motes:
		var mote: Dictionary = mote_v
		if float(mote.age) >= 0.0:
			points.append(_mote_point(mote))
	return points


func mote_radius() -> float:
	return _mote_size * 2.2


func spirit_target_point() -> Vector2:
	if _spirit_target == null or not _spirit_target.is_inside_tree():
		return Vector2(size.x * 0.5, -_stop_below)
	var rect := _spirit_target.get_global_rect()
	var global_point := Vector2(rect.get_center().x, rect.end.y + _stop_below)
	return get_global_transform().affine_inverse() * global_point


func draw_ground(canvas: CanvasItem) -> void:
	for select_v in _selects:
		var select: Dictionary = select_v
		var t := MotionEase.ratio(float(select.age), _select_sec)
		var fade := 1.0 - MotionEase.out_cubic(t)
		var center: Vector2 = select.center
		var glow := 1.0 + _select_glow * fade
		(
			canvas
			. draw_texture_rect(
				_SELECT_TEXTURE,
				Rect2(center - _SLOT_HALF, _SLOT_HALF * 2.0),
				false,
				Color(glow, glow * 0.95, glow * 0.8, fade),
			)
		)
		var ring := lerpf(_select_ring_from, _select_ring_to, MotionEase.out_cubic(t))
		_draw_ellipse(canvas, center, _SLOT_HALF * ring, Color(_LIGHT, fade), 4.0)
	for ring_v in _rings:
		var ring: Dictionary = ring_v
		var age := float(ring.age)
		if age < 0.0:
			continue
		var t := MotionEase.ratio(age, _ring_sec)
		var fade := 1.0 - MotionEase.in_quad(t)
		var half := _ring_half(age)
		var center: Vector2 = ring.center
		canvas.draw_texture_rect(
			_RING_TEXTURE, Rect2(center - half, half * 2.0), false, Color(1.5, 1.3, 1.2, fade)
		)
		_draw_ellipse(canvas, center, half, Color(_RING_LIGHT, fade), 5.0)
		_draw_ellipse(canvas, center, half * 0.82, Color(_GOLD, fade * 0.6), 2.0)


func _draw() -> void:
	_draw_papers()
	_draw_sparks()
	_draw_cracks()
	_draw_motes()


func _draw_papers() -> void:
	var paper_size := Vector2(
		_paper_size * _PAPER_REGION.size.x / _PAPER_REGION.size.y, _paper_size
	)
	for paper_v in _papers:
		var paper: Dictionary = paper_v
		var age := float(paper.age)
		if age < 0.0:
			continue
		var t := MotionEase.ratio(age, _paper_sec)
		var fade := 1.0 - MotionEase.in_quad(maxf(t - 0.4, 0.0) / 0.6)
		var angle := float(paper.angle) + float(paper.spin) * age
		draw_set_transform(_paper_point(paper), angle, Vector2.ONE)
		draw_texture_rect_region(
			_RING_TEXTURE,
			Rect2(-paper_size * 0.5, paper_size),
			_PAPER_REGION,
			Color(1, 1, 1, fade),
		)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sparks() -> void:
	for spark_v in _sparks:
		var spark: Dictionary = spark_v
		var t := MotionEase.ratio(float(spark.age), _spark_sec)
		var pos: Vector2 = (
			(spark.origin as Vector2)
			+ (spark.dir as Vector2) * _spark_distance * MotionEase.out_cubic(t)
		)
		var fade := 1.0 - t
		var radius := lerpf(_spark_size, _spark_size * 0.3, t)
		if bool(spark.petal):
			_draw_petal(pos, radius * 1.6, float(spark.angle), Color(_PETAL, fade))
		else:
			_draw_glow(pos, radius, _LIGHT, fade)


func _draw_cracks() -> void:
	for crack_v in _cracks:
		var crack: Dictionary = crack_v
		var t := MotionEase.ratio(float(crack.age), _crack_sec)
		var fade := 1.0 - MotionEase.in_quad(t)
		var center: Vector2 = crack.center
		draw_texture_rect(
			_SELECT_TEXTURE,
			Rect2(center - _GUARD_HALF, _GUARD_HALF * 2.0),
			false,
			Color(1.6, 0.55, 0.55, fade * 0.8),
		)
		for line_v in crack.lines:
			draw_polyline(line_v, Color(_CRACK, fade), lerpf(4.0, 1.5, t), true)
			draw_polyline(line_v, Color(_LIGHT, fade * 0.8), lerpf(1.6, 0.6, t), true)
		_draw_ellipse(self, center, _GUARD_HALF * lerpf(0.7, 1.0, t), Color(_CRACK, fade), 3.0)


func _draw_motes() -> void:
	for mote_v in _motes:
		var mote: Dictionary = mote_v
		var age := float(mote.age)
		if age < 0.0:
			continue
		var t := MotionEase.ratio(age, _mote_sec)
		var fade := minf(t / 0.12, 1.0) * (1.0 - MotionEase.in_quad(maxf(t - 0.6, 0.0) / 0.4))
		var pos := _mote_point(mote)
		if bool(mote.petal):
			_draw_petal(pos, _mote_size * 1.5, float(mote.angle) + age * 4.0, Color(_PETAL, fade))
		else:
			_draw_glow(pos, _mote_size, _SPIRIT, fade)


func _spawn_sparks(origin: Vector2) -> void:
	for index in _spark_count:
		if _sparks.size() >= _max_sparks:
			_sparks.remove_at(0)
		var angle := _rng.randf_range(0.0, TAU)
		(
			_sparks
			. append(
				{
					"origin": origin,
					"dir": Vector2.RIGHT.rotated(angle),
					"angle": angle,
					"petal": index == 0 and _rng.randf() < 0.5,
					"age": 0.0,
				}
			)
		)


func _spawn_motes(origin: Vector2) -> void:
	for index in _mote_count:
		if _motes.size() >= _max_motes:
			_motes.remove_at(0)
		var burst := Vector2.UP.rotated(_rng.randf_range(-1.6, 1.6)) * _burst_px
		(
			_motes
			. append(
				{
					"start": origin,
					"control": origin + burst + Vector2(0, -_burst_px),
					"petal": index % _petal_every == 0,
					"angle": _rng.randf_range(0.0, TAU),
					"age": -_mote_stagger * float(index),
				}
			)
		)


func _spawn_crack(center: Vector2) -> void:
	var lines: Array[PackedVector2Array] = []
	for index in _crack_count:
		var angle := TAU * float(index) / float(maxi(_crack_count, 1)) + _rng.randf_range(-0.3, 0.3)
		var point := center
		var line := PackedVector2Array([point])
		for _segment in 3:
			angle += _rng.randf_range(-0.45, 0.45)
			var step := Vector2.RIGHT.rotated(angle) * _crack_length / 3.0
			point += Vector2(step.x, step.y * 0.72)
			line.append(point)
		lines.append(line)
	_cracks.append({"center": center, "lines": lines, "age": 0.0})
	queue_redraw()


func _advance_motes(delta: float) -> void:
	var kept: Array = []
	var arrived := false
	for mote_v in _motes:
		var mote: Dictionary = mote_v
		mote.age = float(mote.age) + delta
		if float(mote.age) >= _mote_sec:
			arrived = true
			continue
		kept.append(mote)
	_motes = kept
	if arrived:
		spirit_mote_arrived.emit()


func _aged(items: Array, delta: float, life: float) -> Array:
	var kept: Array = []
	for item_v in items:
		var item: Dictionary = item_v
		item.age = float(item.age) + delta
		if float(item.age) < life:
			kept.append(item)
	return kept


func _ring_half(age: float) -> Vector2:
	var t := MotionEase.out_cubic(MotionEase.ratio(age, _ring_sec))
	return _ring_size * 0.5 * lerpf(0.35, 1.0, t)


func _paper_point(paper: Dictionary) -> Vector2:
	var t := MotionEase.out_cubic(MotionEase.ratio(float(paper.age), _paper_sec))
	return (paper.origin as Vector2) + (paper.dir as Vector2) * float(paper.distance) * t


func _mote_point(mote: Dictionary) -> Vector2:
	var t := MotionEase.ratio(float(mote.age), _mote_sec)
	var eased := t * t * (3.0 - 2.0 * t)
	var start: Vector2 = mote.start
	var control: Vector2 = mote.control
	var finish := spirit_target_point()
	return start.lerp(control, eased).lerp(control.lerp(finish, eased), eased)


func _event_point(event: Dictionary) -> Vector2:
	return _view.logical_point(Vector2(float(event.get("x", 0.0)), float(event.get("y", 0.0))))


## 符纸朝离开路线的方向飞，避免挡住残影要走的路。
func _away_from_route(center: Vector2) -> Vector2:
	var points := _view.route_points()
	var nearest := Vector2.INF
	for index in range(points.size() - 1):
		var candidate := Geometry2D.get_closest_point_to_segment(
			center, points[index], points[index + 1]
		)
		if candidate.distance_to(center) < nearest.distance_to(center):
			nearest = candidate
	if nearest == Vector2.INF or nearest.is_equal_approx(center):
		return Vector2.UP
	return (center - nearest).normalized()


func _draw_glow(pos: Vector2, radius: float, color: Color, alpha: float) -> void:
	draw_circle(pos, radius * 2.2, Color(color, alpha * 0.25))
	draw_circle(pos, radius, Color(color, alpha))
	draw_circle(pos, radius * 0.45, Color(Color.WHITE, alpha))


func _draw_petal(pos: Vector2, radius: float, angle: float, color: Color) -> void:
	draw_set_transform(pos, angle, Vector2(1.0, 0.55))
	draw_circle(Vector2.ZERO, radius, color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_ellipse(
	canvas: CanvasItem, center: Vector2, radii: Vector2, color: Color, width: float
) -> void:
	var points := PackedVector2Array()
	for index in 41:
		var angle := TAU * float(index) / 40.0
		points.append(center + Vector2(cos(angle) * radii.x, sin(angle) * radii.y))
	canvas.draw_polyline(points, color, width, true)
