extends Control

## 棋盘上的路线、符纸槽位和单位。格子尺寸来自配置，不在这里写死。

signal cell_pressed(col: int, row: int)

const _COLOR_ROUTE := Color("#E4D2AE")
const _COLOR_ROUTE_EDGE := Color("#6B3A2E")
const _COLOR_CHEVRON := Color("#8A5A32")
const _COLOR_OFUDA := Color("#F7F1E4")
const _COLOR_SEAL := Color("#C8323C")
const _COLOR_SELECT := Color("#D4A94F")
const _COLOR_REIMU := Color("#E24B4B")
const _COLOR_REIMU_INNER := Color("#F4F0E6")
const _COLOR_MARISA := Color("#F0C14A")
const _COLOR_MARISA_INNER := Color("#1A1420")
const _COLOR_SHADE := Color("#D9DCE0")
const _COLOR_SHADE_EDGE := Color("#5A6068")
const _COLOR_SHOT := Color("#F7F2E8")
const _COLOR_BEAM := Color("#FFE14A")
const _REIMU_TOKEN: Texture2D = preload("res://assets/textures/ui/reimu_v2_token.png")

var _columns: int = 7
var _rows: int = 12
var _cell: int = 128
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
	_cell = int(layout.cell_size)
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
			if _is_route(mark):
				_draw_route_cell(col, row, rect, mark)
			elif mark == ".":
				_draw_ofuda(rect, col == _selected_col and row == _selected_row)


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
		_draw_ground_shadow(center, 36.0)
		if str(unit.get("character_id", "")) == "chr_reimu" and _REIMU_TOKEN != null:
			var dest := Rect2(center - Vector2(52, 64), Vector2(104, 112))
			draw_texture_rect(_REIMU_TOKEN, dest, false)
		else:
			var palette := _unit_colors(str(unit.get("character_id", "")))
			draw_circle(center, 42.0, palette[0])
			draw_circle(center, 22.0, palette[1])
		if font == null:
			continue
		var badge := center + Vector2(34, -46)
		draw_circle(badge, 16.0, Color(0.12, 0.09, 0.14, 0.88))
		draw_string(
			font,
			badge + Vector2(-8, 8),
			str(int(unit.get("level", 1))),
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			24,
			Color("#F5EDDB")
		)


func _draw_enemies() -> void:
	for enemy_v in _state.get("enemies", []):
		if typeof(enemy_v) != TYPE_DICTIONARY:
			continue
		var enemy: Dictionary = enemy_v
		var pos := Vector2(float(enemy.x), float(enemy.y)) * float(_cell)
		var fast := str(enemy.get("enemy_id", "")) == "enm_shade_fast"
		var radius := 22.0 if fast else 30.0
		var tint := _COLOR_SHADE
		if _flashes.has(int(enemy.id)):
			tint = _COLOR_SHADE.lerp(_flash_color, _flash_strength)
		tint.a = 0.82
		_draw_ground_shadow(pos, radius * 0.7)
		if fast:
			draw_set_transform(pos, 0.0, Vector2(0.72, 1.2))
			draw_circle(Vector2.ZERO, radius, tint)
			draw_arc(Vector2.ZERO, radius, 0.0, TAU, 24, _COLOR_SHADE_EDGE, 3.0)
			draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		else:
			draw_circle(pos, radius, tint)
			draw_arc(pos, radius, 0.0, TAU, 28, _COLOR_SHADE_EDGE, 3.0)
			_draw_windup_key(pos + Vector2(0, -radius + 2.0))
		var eye := pos + (Vector2(0, -4) if not fast else Vector2.ZERO)
		draw_arc(eye + Vector2(-8, 0), 4.0, 0.0, TAU, 10, _COLOR_SHADE_EDGE, 2.0)
		draw_arc(eye + Vector2(8, 0), 4.0, 0.0, TAU, 10, _COLOR_SHADE_EDGE, 2.0)
		_draw_hp(pos, float(enemy.hp), float(enemy.max_hp), radius)


func _draw_shots() -> void:
	for shot_v in _state.get("projectiles", []):
		if typeof(shot_v) != TYPE_DICTIONARY:
			continue
		var shot: Dictionary = shot_v
		var pos := Vector2(float(shot.x), float(shot.y)) * float(_cell)
		var slip := Rect2(pos - Vector2(10, 16), Vector2(20, 32))
		draw_rect(slip, _COLOR_SHOT)
		draw_rect(slip, _COLOR_SEAL, false, 2.0)
		draw_line(slip.position + Vector2(10, 6), slip.position + Vector2(10, 26), _COLOR_SEAL, 2.0)


func _draw_beams() -> void:
	for beam_v in _beams:
		var beam: Dictionary = beam_v
		var from := Vector2(float(beam.x0), float(beam.y0)) * float(_cell)
		var to := Vector2(float(beam.x1), float(beam.y1)) * float(_cell)
		draw_line(from, to, _COLOR_BEAM, 10.0)


func _draw_route_cell(col: int, row: int, rect: Rect2, mark: String) -> void:
	draw_rect(rect, _COLOR_ROUTE)
	_draw_route_edge(
		rect, not _is_route(_mark(col, row - 1)), Vector2(0, 0), Vector2(rect.size.x, 0)
	)
	_draw_route_edge(
		rect,
		not _is_route(_mark(col, row + 1)),
		Vector2(0, rect.size.y),
		Vector2(rect.size.x, rect.size.y)
	)
	_draw_route_edge(
		rect, not _is_route(_mark(col - 1, row)), Vector2(0, 0), Vector2(0, rect.size.y)
	)
	_draw_route_edge(
		rect,
		not _is_route(_mark(col + 1, row)),
		Vector2(rect.size.x, 0),
		Vector2(rect.size.x, rect.size.y)
	)
	if mark == "P":
		_draw_chevron(rect)
	elif mark == "S":
		_draw_rift(rect)
	elif mark == "G":
		_draw_offering_box(rect)


func _draw_route_edge(rect: Rect2, visible: bool, start: Vector2, end: Vector2) -> void:
	if not visible:
		return
	draw_line(rect.position + start, rect.position + end, _COLOR_ROUTE_EDGE, 6.0)


func _draw_chevron(rect: Rect2) -> void:
	var center := rect.get_center() + Vector2(0, 6)
	var points := PackedVector2Array(
		[center + Vector2(-16, -12), center + Vector2(16, -12), center + Vector2(0, 14)]
	)
	draw_colored_polygon(points, _COLOR_CHEVRON)


func _draw_ofuda(rect: Rect2, selected: bool) -> void:
	var paper := rect.grow(-18)
	draw_rect(paper, _COLOR_OFUDA)
	var ink := _COLOR_SELECT if selected else _COLOR_SEAL
	draw_rect(paper, ink, false, 6.0 if selected else 4.0)
	var stripe_x := paper.position.x + paper.size.x * 0.5
	draw_line(
		Vector2(stripe_x, paper.position.y + 18.0),
		Vector2(stripe_x, paper.end.y - 18.0),
		_COLOR_SEAL,
		3.0
	)
	draw_circle(paper.position + Vector2(20, 20), 9.0, _COLOR_SEAL)
	if selected:
		draw_rect(rect.grow(-8), _COLOR_SELECT, false, 4.0)


func _draw_rift(rect: Rect2) -> void:
	var center := rect.get_center()
	draw_circle(center, 40.0, Color(0.36, 0.18, 0.55, 0.92))
	draw_circle(center, 18.0, Color(0.95, 0.93, 0.98, 0.95))
	draw_arc(center, 30.0, 0.0, TAU, 28, Color("#2B2230"), 3.0)
	draw_line(center + Vector2(-22, -6), center + Vector2(6, 2), Color("#F7F2E8"), 4.0)
	draw_line(center + Vector2(6, 2), center + Vector2(-8, 20), Color("#F7F2E8"), 4.0)


func _draw_offering_box(rect: Rect2) -> void:
	var box := Rect2(rect.position + Vector2(34, 48), Vector2(60, 44))
	draw_rect(box, Color("#8C5A32"))
	draw_rect(box, Color("#2B2230"), false, 3.0)
	var roof := PackedVector2Array(
		[
			box.position + Vector2(-6, 6),
			box.position + Vector2(30, -18),
			box.position + Vector2(66, 6)
		]
	)
	draw_colored_polygon(roof, _COLOR_SEAL)
	draw_line(box.position + Vector2(12, 16), box.position + Vector2(48, 16), Color("#2B2230"), 3.0)


func _draw_ground_shadow(center: Vector2, radius: float) -> void:
	draw_set_transform(center + Vector2(0, radius * 0.85), 0.0, Vector2(1.15, 0.38))
	draw_circle(Vector2.ZERO, radius, Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_windup_key(origin: Vector2) -> void:
	draw_line(origin, origin + Vector2(0, -16), _COLOR_SHADE_EDGE, 3.0)
	draw_arc(origin + Vector2(0, -16), 7.0, 0.4, 5.0, 10, _COLOR_SHADE_EDGE, 3.0)


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


func _is_route(mark: String) -> bool:
	return mark == "P" or mark == "S" or mark == "G"


func _mark(col: int, row: int) -> String:
	if row < 0 or row >= _cells.size():
		return ""
	var line := str(_cells[row])
	if col < 0 or col >= line.length():
		return ""
	return line.substr(col, 1)


func _unit_colors(character_id: String) -> Array:
	if character_id == "chr_reimu":
		return [_COLOR_REIMU, _COLOR_REIMU_INNER]
	if character_id == "chr_marisa":
		return [_COLOR_MARISA, _COLOR_MARISA_INNER]
	return [Color("#D0D0D0"), Color("#333333")]


func _cell_center(col: int, row: int) -> Vector2:
	return Vector2((float(col) + 0.5) * float(_cell), (float(row) + 0.5) * float(_cell))
