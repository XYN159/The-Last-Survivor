extends Control

## 序章庭院上的角色与战斗反馈。背景和静态光效都使用重绘素材。

signal cell_pressed(col: int, row: int)

const _REIMU_TEXTURE := preload("res://assets/art/prologue_01/reimu_token.png")
const _PLACE_TEXTURE := preload("res://assets/art/prologue_01/yin_yang_blue.png")
const _SELECT_TEXTURE := preload("res://assets/art/prologue_01/yin_yang_gold.png")
const _UNIT_RING_TEXTURE := preload("res://assets/art/prologue_01/ofuda_ring.png")
const _RANGE_TEXTURE := preload("res://assets/art/prologue_01/petal_ward.png")
const _SHOT_TEXTURE := preload("res://assets/art/prologue_01/spirit_shot.png")
const _HIT_TEXTURE := preload("res://assets/art/prologue_01/hit_burst.png")
const _ENEMY_TEXTURE := preload("res://assets/art/prologue_01/shade_enemy.png")

var _columns: int = 7
var _rows: int = 12
var _cells: Array = []
var _state: Dictionary = {}
var _selected_col: int = -1
var _selected_row: int = -1
var _selected_id: int = -1
var _floaters: Array = []
var _beams: Array = []
var _flashes: Dictionary = {}
var _flash_time: float = 0.08
var _number_life: float = 0.6
var _number_rise: float = 60.0
var _max_numbers: int = 40
var _normal_size: int = 34
var _heavy_size: int = 48
var _normal_color := Color.WHITE
var _heavy_color := Color("#FFD23F")
var _flash_color := Color.WHITE
var _flash_strength: float = 0.85


func setup(catalog: CombatCatalog) -> void:
	var layout := catalog.board()
	_columns = int(layout.columns)
	_rows = int(layout.rows)
	var map: Dictionary = catalog.level().get("map", {})
	_cells = map.get("cells", [])
	var feel := catalog.feel()
	var flash: Dictionary = feel.get("hit_flash", {})
	var numbers: Dictionary = feel.get("damage_numbers", {})
	_flash_time = float(flash.get("duration_sec", 0.08))
	_flash_color = Color.html(str(flash.get("color", "#FFFFFF")))
	_flash_strength = clampf(float(flash.get("strength", 0.85)), 0.0, 1.0)
	_number_life = float(numbers.get("lifetime_sec", 0.6))
	_number_rise = float(numbers.get("rise_px", 60))
	_max_numbers = maxi(CombatCatalog.read_int(numbers.get("max_on_screen", 40), 40), 1)
	_normal_size = CombatCatalog.read_int(numbers.get("normal_font_px", 34), 34)
	_heavy_size = CombatCatalog.read_int(numbers.get("heavy_font_px", 48), 48)
	_normal_color = Color.html(str(numbers.get("normal_color", "#FFFFFF")))
	_heavy_color = Color.html(str(numbers.get("heavy_color", "#FFD23F")))


func sync(state: Dictionary, selected_col: int, selected_row: int, selected_id: int) -> void:
	_state = state
	_selected_col = selected_col
	_selected_row = selected_row
	_selected_id = selected_id
	queue_redraw()


func push_events(events: Array) -> void:
	for event_v in events:
		if typeof(event_v) != TYPE_DICTIONARY:
			continue
		_take_event(event_v)


func advance_fx(delta: float) -> void:
	_age_floaters(delta)
	_age_beams(delta)
	_age_flashes(delta)
	queue_redraw()


func _gui_input(event: InputEvent) -> void:
	var mouse := event as InputEventMouseButton
	if mouse == null or not mouse.pressed:
		return
	if mouse.button_index != MOUSE_BUTTON_LEFT:
		return
	var nearest := Vector2i(-1, -1)
	var nearest_distance := 86.0
	for row in _rows:
		for col in _columns:
			var distance := mouse.position.distance_to(_cell_center(col, row))
			if distance < nearest_distance:
				nearest = Vector2i(col, row)
				nearest_distance = distance
	if nearest.x < 0:
		return
	cell_pressed.emit(nearest.x, nearest.y)
	accept_event()


func _draw() -> void:
	_draw_stage_markers()
	_draw_range()
	_draw_units()
	_draw_enemies()
	_draw_shots()
	_draw_beams()


func _draw_stage_markers() -> void:
	for row in _rows:
		for col in _columns:
			var mark := _mark(col, row)
			var center := _cell_center(col, row)
			if mark == ".":
				var texture := (
					_SELECT_TEXTURE
					if col == _selected_col and row == _selected_row
					else _PLACE_TEXTURE
				)
				var tint := Color.WHITE if texture == _SELECT_TEXTURE else Color(0.75, 0.9, 1, 0.72)
				draw_texture_rect(
					texture, Rect2(center - Vector2(84, 62), Vector2(168, 124)), false, tint
				)
			elif mark == "S":
				draw_texture_rect(
					_UNIT_RING_TEXTURE,
					Rect2(center - Vector2(72, 64), Vector2(144, 128)),
					false,
					Color(1, 0.45, 0.5, 0.72),
				)
			elif mark == "G":
				draw_texture_rect(
					_SELECT_TEXTURE,
					Rect2(center - Vector2(88, 65), Vector2(176, 130)),
					false,
					Color(1, 0.9, 0.58, 0.82),
				)


func _draw_range() -> void:
	for unit_v in _state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		if int(unit.get("id", -1)) != _selected_id:
			continue
		var center := _cell_center(int(unit.col), int(unit.row))
		var radius := float(unit.get("range", 1.0)) * 110.0
		draw_texture_rect(
			_RANGE_TEXTURE,
			Rect2(center - Vector2(radius, radius * 0.72), Vector2(radius * 2.0, radius * 1.44)),
			false,
			Color(1, 1, 1, 0.78),
		)


func _draw_units() -> void:
	var font := get_theme_default_font()
	for unit_v in _state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		var center := _cell_center(int(unit.col), int(unit.row))
		draw_texture_rect(
			_UNIT_RING_TEXTURE,
			Rect2(center - Vector2(78, 70), Vector2(156, 140)),
			false,
			Color(1, 0.72, 0.72, 0.9),
		)
		draw_texture_rect(
			_REIMU_TEXTURE,
			Rect2(center - Vector2(51, 64), Vector2(102, 102)),
			false,
		)
		if font == null:
			continue
		draw_string(
			font,
			center + Vector2(-12, 58),
			str(int(unit.get("level", 1))),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color("#FFF0DC"),
		)


func _draw_enemies() -> void:
	for enemy_v in _state.get("enemies", []):
		if typeof(enemy_v) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = enemy_v
		var pos := _logical_point(Vector2(float(enemy.x), float(enemy.y)))
		var fast := str(enemy.get("enemy_id", "")) == "enm_shade_fast"
		var radius := 38.0 if fast else 46.0
		var tint := Color(0.72, 0.82, 1, 0.92) if fast else Color.WHITE
		if _flashes.has(int(enemy.id)):
			tint = tint.lerp(_flash_color, _flash_strength)
			draw_texture_rect(
				_HIT_TEXTURE,
				Rect2(pos - Vector2(70, 64), Vector2(140, 128)),
				false,
				Color(1, 0.72, 0.76, 0.88),
			)
		draw_texture_rect(
			_ENEMY_TEXTURE,
			Rect2(pos - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)),
			false,
			tint,
		)
		_draw_hp(pos, float(enemy.hp), float(enemy.max_hp), radius)


func _draw_shots() -> void:
	for shot_v in _state.get("projectiles", []):
		if typeof(shot_v) != TYPE_DICTIONARY:
			continue
		var shot: Dictionary = shot_v
		var pos := _logical_point(Vector2(float(shot.x), float(shot.y)))
		draw_texture_rect(
			_SHOT_TEXTURE,
			Rect2(pos - Vector2(62, 28), Vector2(124, 56)),
			false,
		)


func _draw_beams() -> void:
	for beam_v in _beams:
		var beam: Dictionary = beam_v
		var from := _logical_point(Vector2(float(beam.x0), float(beam.y0)))
		var to := _logical_point(Vector2(float(beam.x1), float(beam.y1)))
		draw_line(from, to, Color(1, 0.87, 0.5, 0.9), 6.0)
		draw_texture_rect(_SHOT_TEXTURE, Rect2(to - Vector2(54, 24), Vector2(108, 48)), false)


func _draw_hp(pos: Vector2, hp: float, max_hp: float, radius: float) -> void:
	var width := 48.0
	var origin := pos + Vector2(-width * 0.5, -radius - 16.0)
	draw_rect(Rect2(origin, Vector2(width, 8)), Color(0, 0, 0, 0.55))
	var ratio := 0.0 if max_hp <= 0.0 else clampf(hp / max_hp, 0.0, 1.0)
	draw_rect(Rect2(origin, Vector2(width * ratio, 8)), Color("#7DDE92"))


func _take_event(event: Dictionary) -> void:
	var kind := str(event.get("type", ""))
	if kind == "damage":
		_spawn_number(event)
		_flashes[int(event.get("id", -1))] = _flash_time
		return
	if kind == "beam":
		(
			_beams
			. append(
				{
					"x0": float(event.x0),
					"y0": float(event.y0),
					"x1": float(event.x1),
					"y1": float(event.y1),
					"life": float(event.get("duration", 0.15)),
				}
			)
		)


func _spawn_number(event: Dictionary) -> void:
	while _floaters.size() >= _max_numbers:
		var oldest: Dictionary = _floaters[0]
		(oldest.label as Label).queue_free()
		_floaters.remove_at(0)
	var heavy := bool(event.get("heavy", false))
	var label := Label.new()
	label.text = str(int(event.get("amount", 0)))
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", _heavy_size if heavy else _normal_size)
	label.add_theme_color_override("font_color", _heavy_color if heavy else _normal_color)
	label.add_theme_color_override("font_outline_color", Color("#1A1420"))
	label.add_theme_constant_override("outline_size", 8)
	var origin := _logical_point(Vector2(float(event.x), float(event.y))) + Vector2(-28, -46)
	label.position = origin
	add_child(label)
	_floaters.append(
		{"label": label, "age": 0.0, "life": _number_life, "rise": _number_rise, "origin": origin}
	)


func _age_floaters(delta: float) -> void:
	var kept: Array = []
	for item_v in _floaters:
		var item: Dictionary = item_v
		item.age = float(item.age) + delta
		var label: Label = item.label
		if float(item.age) >= float(item.life):
			label.queue_free()
			continue
		var ratio := float(item.age) / float(item.life)
		label.position = (item.origin as Vector2) + Vector2(0, -float(item.rise) * ratio)
		label.modulate.a = 1.0 - ratio
		kept.append(item)
	_floaters = kept


func _age_beams(delta: float) -> void:
	var kept: Array = []
	for beam_v in _beams:
		var beam: Dictionary = beam_v
		beam.life = float(beam.life) - delta
		if float(beam.life) > 0.0:
			kept.append(beam)
	_beams = kept


func _age_flashes(delta: float) -> void:
	var expired: Array = []
	for id_v in _flashes.keys():
		_flashes[id_v] = float(_flashes[id_v]) - delta
		if float(_flashes[id_v]) <= 0.0:
			expired.append(id_v)
	for id_v in expired:
		_flashes.erase(id_v)


func _mark(col: int, row: int) -> String:
	if row < 0 or row >= _cells.size():
		return ""
	var line := str(_cells[row])
	if col < 0 or col >= line.length():
		return ""
	return line.substr(col, 1)


func _cell_center(col: int, row: int) -> Vector2:
	return _logical_point(Vector2(float(col) + 0.5, float(row) + 0.5))


func _logical_point(point: Vector2) -> Vector2:
	var row_ratio := point.y / float(maxi(_rows, 1))
	var column_offset := point.x - float(_columns) * 0.5
	return Vector2(
		lerpf(size.x - 95.0, 95.0, row_ratio),
		size.y * 0.5 + column_offset * 92.0,
	)
