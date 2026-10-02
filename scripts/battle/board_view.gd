extends Control

## 棋盘上的色块。格子尺寸来自配置，不在这里写死。

signal cell_pressed(col: int, row: int)

const _COLOR_BLOCKED := Color("#24302C")
const _COLOR_PATH := Color("#C4B49A")
const _COLOR_PLACE := Color("#E6D39A")
const _COLOR_SPAWN := Color("#6B4C9A")
const _COLOR_GUARD := Color("#C23B4A")
const _COLOR_REIMU := Color("#E24B4B")
const _COLOR_REIMU_INNER := Color("#F4F0E6")
const _COLOR_MARISA := Color("#F0C14A")
const _COLOR_MARISA_INNER := Color("#1A1420")
const _COLOR_BASIC := Color("#8E97A8")
const _COLOR_FAST := Color("#5EC8E6")
const _COLOR_SHOT := Color("#FFF6E8")
const _COLOR_BEAM := Color("#FFE14A")

var _columns: int = 7
var _rows: int = 12
var _cell: int = 128
var _cells: Array = []
var _state: Dictionary = {}
var _armed_id: String = ""
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


func setup(catalog: CombatCatalog) -> void:
	var layout := catalog.board()
	_columns = int(layout.columns)
	_rows = int(layout.rows)
	_cell = int(layout.cell_size)
	var map: Dictionary = catalog.level().get("map", {})
	_cells = map.get("cells", [])
	var feel := catalog.feel()
	var flash: Dictionary = feel.get("hit_flash", {})
	var numbers: Dictionary = feel.get("damage_numbers", {})
	_flash_time = float(flash.get("duration_sec", 0.08))
	_number_life = float(numbers.get("lifetime_sec", 0.6))
	_number_rise = float(numbers.get("rise_px", 60))
	_max_numbers = maxi(CombatCatalog.read_int(numbers.get("max_on_screen", 40), 40), 1)
	_normal_size = CombatCatalog.read_int(numbers.get("normal_font_px", 34), 34)
	_heavy_size = CombatCatalog.read_int(numbers.get("heavy_font_px", 48), 48)
	_normal_color = Color.html(str(numbers.get("normal_color", "#FFFFFF")))
	_heavy_color = Color.html(str(numbers.get("heavy_color", "#FFD23F")))


func sync(state: Dictionary, armed_id: String, selected_id: int) -> void:
	_state = state
	_armed_id = armed_id
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
	if mouse.button_index != MOUSE_BUTTON_LEFT or _cell <= 0:
		return
	var col := int(mouse.position.x / float(_cell))
	var row := int(mouse.position.y / float(_cell))
	if col < 0 or row < 0 or col >= _columns or row >= _rows:
		return
	cell_pressed.emit(col, row)
	accept_event()


func _draw() -> void:
	_draw_cells()
	_draw_range()
	_draw_units()
	_draw_enemies()
	_draw_shots()
	_draw_beams()


func _draw_cells() -> void:
	for row in _rows:
		for col in _columns:
			var mark := _mark(col, row)
			var rect := Rect2(col * _cell, row * _cell, _cell, _cell)
			draw_rect(rect, _cell_color(mark))
			if mark == "." and _armed_id != "":
				draw_rect(rect.grow(-10), Color(1, 0.95, 0.55, 0.45))
			draw_rect(rect, Color(0, 0, 0, 0.28), false, 2.0)
			if mark == "G":
				_draw_guard(rect)


func _draw_range() -> void:
	for unit_v in _state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		if int(unit.get("id", -1)) != _selected_id:
			continue
		var center := _cell_center(int(unit.col), int(unit.row))
		var radius := float(unit.get("range", 1.0)) * float(_cell)
		draw_arc(center, radius, 0.0, TAU, 64, Color(1, 1, 1, 0.85), 4.0)


func _draw_units() -> void:
	var font := get_theme_default_font()
	for unit_v in _state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		var center := _cell_center(int(unit.col), int(unit.row))
		var palette := _unit_colors(str(unit.get("character_id", "")))
		draw_circle(center, 42.0, palette[0])
		draw_circle(center, 22.0, palette[1])
		if font == null:
			continue
		draw_string(
			font,
			center + Vector2(-16, 54),
			str(int(unit.get("level", 1))),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			28,
			Color.WHITE,
		)


func _draw_enemies() -> void:
	for enemy_v in _state.get("enemies", []):
		if typeof(enemy_v) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = enemy_v
		var pos := Vector2(float(enemy.x), float(enemy.y)) * float(_cell)
		var fast := str(enemy.get("enemy_id", "")) == "enm_shade_fast"
		var radius := 22.0 if fast else 30.0
		var tint := (
			Color.WHITE if _flashes.has(int(enemy.id)) else (_COLOR_FAST if fast else _COLOR_BASIC)
		)
		draw_circle(pos, radius, tint)
		_draw_hp(pos, float(enemy.hp), float(enemy.max_hp), radius)


func _draw_shots() -> void:
	for shot_v in _state.get("projectiles", []):
		if typeof(shot_v) != TYPE_DICTIONARY:
			continue
		var shot: Dictionary = shot_v
		var pos := Vector2(float(shot.x), float(shot.y)) * float(_cell)
		draw_rect(Rect2(pos - Vector2(8, 12), Vector2(16, 24)), _COLOR_SHOT)


func _draw_beams() -> void:
	for beam_v in _beams:
		var beam: Dictionary = beam_v
		var from := Vector2(float(beam.x0), float(beam.y0)) * float(_cell)
		var to := Vector2(float(beam.x1), float(beam.y1)) * float(_cell)
		draw_line(from, to, _COLOR_BEAM, 10.0)


func _draw_guard(rect: Rect2) -> void:
	var box := Rect2(rect.position + Vector2(34, 36), Vector2(60, 56))
	draw_rect(box, Color("#F4F0E6"))
	draw_rect(Rect2(box.position + Vector2(0, 24), Vector2(60, 8)), _COLOR_GUARD)


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
	var origin := Vector2(float(event.x), float(event.y)) * float(_cell) + Vector2(-28, -36)
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


func _cell_color(mark: String) -> Color:
	match mark:
		".":
			return _COLOR_PLACE
		"P":
			return _COLOR_PATH
		"S":
			return _COLOR_SPAWN
		"G":
			return _COLOR_GUARD
		_:
			return _COLOR_BLOCKED


func _unit_colors(character_id: String) -> Array:
	if character_id == "chr_reimu":
		return [_COLOR_REIMU, _COLOR_REIMU_INNER]
	if character_id == "chr_marisa":
		return [_COLOR_MARISA, _COLOR_MARISA_INNER]
	return [Color("#D0D0D0"), Color("#333333")]


func _cell_center(col: int, row: int) -> Vector2:
	return Vector2((float(col) + 0.5) * float(_cell), (float(row) + 0.5) * float(_cell))
