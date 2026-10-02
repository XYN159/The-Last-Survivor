extends Control

## 塔防对局的画面。规则在 BattleSim，这里只负责按钮、棋盘和结算。

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const _HINT_DEFAULT := "ui.battle.hint_default"
const _HINT_PICK_CELL := "ui.battle.hint_pick_cell"
const _HINT_PICK_CHARACTER := "ui.battle.hint_pick_character"
const _HINT_PLACE_FAILED := "ui.battle.hint_place_failed"
const _REIMU_CARD: Texture2D = preload("res://assets/textures/ui/reimu_v2_card.png")
const _INK := Color("#2B2B33")
const _SPIRIT_INK := Color("#146887")
const _PAPER := Color("#F5EFE2")
const _SEAL := Color("#C8323C")
const _GOLD := Color("#D4A94F")

static var remembered_speed: int = 1

var _catalog: CombatCatalog
var _sim: BattleSim
var _speed: int = 1
var _speed_options: Array[int] = [1, 2]
var _remember_speed: bool = true
var _accumulator: float = 0.0
var _selected_col: int = -1
var _selected_row: int = -1
var _selected_unit: int = -1
var _finished: bool = false
var _capturing: bool = false
var _buttons: Dictionary = {}
var _vignette_left: float = 0.0
var _vignette_duration: float = 0.4
var _vignette_alpha: float = 0.45
var _step_seconds: float = 1.0 / 60.0
var _max_ticks: int = 4
var _style_card: StyleBoxFlat
var _style_card_ready: StyleBoxFlat

@onready var _spirit_label: Label = %SpiritLabel
@onready var _life_label: Label = %LifeLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _board: Control = %BoardView
@onready var _top_bar: Control = %TopBar
@onready var _top_plate: ColorRect = %TopPlate
@onready var _top_line: ColorRect = %TopLine
@onready var _bottom_bar: Control = %BottomBar
@onready var _bottom_plate: ColorRect = %BottomPlate
@onready var _bottom_line: ColorRect = %BottomLine
@onready var _character_bar: HBoxContainer = %CharacterBar
@onready var _call_button: Button = %CallButton
@onready var _speed_button: Button = %SpeedButton
@onready var _hint_label: Label = %HintLabel
@onready var _unit_panel: Control = %UnitPanel
@onready var _unit_title: Label = %UnitTitle
@onready var _upgrade_button: Button = %UpgradeButton
@onready var _sell_button: Button = %SellButton
@onready var _close_unit_button: Button = %CloseUnitButton
@onready var _result_panel: Control = %ResultPanel
@onready var _result_title: Label = %ResultTitle
@onready var _result_body: Label = %ResultBody
@onready var _retry_button: Button = %RetryButton
@onready var _menu_button: Button = %MenuButton
@onready var _vignette: ColorRect = %Vignette


func _ready() -> void:
	_catalog = CombatCatalog.load_default()
	_sim = BattleSim.from_catalog(_catalog)
	_apply_speed_rules()
	var tune := _catalog.tuning()
	_step_seconds = 1.0 / float(tune.logic_hz)
	_max_ticks = int(tune.max_ticks_per_frame)
	var vignette: Dictionary = _catalog.feel().get("guard_damage_vignette", {})
	_vignette_duration = float(vignette.get("duration_sec", 0.4))
	_vignette_alpha = float(vignette.get("max_alpha", 0.45))
	_board.call("setup", _catalog)
	_layout_board()
	_style_card = _make_ofuda_style(_SEAL, 4)
	_style_card_ready = _make_ofuda_style(_GOLD, 6)
	_build_roster()
	_call_button.pressed.connect(_on_call_pressed)
	_speed_button.pressed.connect(_on_speed_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	_close_unit_button.pressed.connect(_on_close_unit_pressed)
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_board.connect("cell_pressed", _on_cell_pressed)
	_apply_ofuda_button(_call_button)
	_apply_ofuda_button(_speed_button)
	_apply_ofuda_button(_upgrade_button)
	_apply_ofuda_button(_sell_button)
	_apply_ofuda_button(_close_unit_button)
	_apply_ofuda_button(_retry_button)
	_apply_ofuda_button(_menu_button)
	_unit_panel.visible = false
	_result_panel.visible = false
	_apply_static_labels()
	_hint_label.text = tr(_HINT_DEFAULT)
	_refresh()
	if OS.get_environment("BATTLE_CAPTURE") == "1":
		_capturing = true
		_capture_sequence()


func _process(delta: float) -> void:
	_fade_vignette(delta)
	if _capturing:
		_board.call("advance_fx", delta)
		return
	if not _finished:
		_run_ticks(delta)
	_board.call("advance_fx", delta * float(_speed))
	_refresh()


func _run_ticks(delta: float) -> void:
	_accumulator += delta * float(_speed)
	var steps := 0
	while _accumulator >= _step_seconds and steps < _max_ticks:
		_note_events(_sim.tick())
		_accumulator -= _step_seconds
		steps += 1
		if str(_sim.view_state().outcome) != "":
			_show_result(_sim.view_state())
			break
	if steps >= _max_ticks:
		_accumulator = minf(_accumulator, _step_seconds)


func _layout_board() -> void:
	var layout := _catalog.board()
	var origin := Vector2(float(layout.offset_x), float(layout.offset_y))
	var size := Vector2(
		float(int(layout.cell_size) * int(layout.columns)),
		float(int(layout.cell_size) * int(layout.rows)),
	)
	_board.position = origin
	_board.size = size
	_top_bar.offset_bottom = origin.y
	_top_plate.offset_bottom = origin.y
	_top_line.offset_top = origin.y - 4.0
	_top_line.offset_bottom = origin.y
	_bottom_bar.anchor_top = 0.0
	_bottom_bar.anchor_bottom = 1.0
	_bottom_bar.offset_top = origin.y + size.y
	_bottom_bar.offset_bottom = 0.0
	_bottom_plate.anchor_top = 0.0
	_bottom_plate.anchor_bottom = 1.0
	_bottom_plate.offset_top = origin.y + size.y
	_bottom_plate.offset_bottom = 0.0
	_bottom_line.anchor_top = 0.0
	_bottom_line.anchor_bottom = 0.0
	_bottom_line.offset_top = origin.y + size.y
	_bottom_line.offset_bottom = origin.y + size.y + 4.0


func _build_roster() -> void:
	for entry_v in _sim.view_state().roster:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		var character_id := str(entry.get("id", ""))
		var button := _make_character_card(character_id)
		button.pressed.connect(_on_character_pressed.bind(character_id))
		_character_bar.add_child(button)
		_buttons[character_id] = button


func _refresh() -> void:
	var state := _sim.view_state()
	_spirit_label.text = tr("ui.battle.spirit") % int(state.spirit)
	_life_label.text = tr("ui.battle.life") % [int(state.guard_hp), int(state.guard_max_hp)]
	_wave_label.text = _wave_text(state)
	_speed_button.text = tr("ui.battle.speed") % _speed
	# 叫波还没拍板（D-18），这个按钮只在布阵时当「开始」用。
	_call_button.visible = str(state.phase) == BattleSim.PHASE_DEPLOY
	_call_button.disabled = not bool(state.call_allowed)
	_call_button.text = tr("ui.battle.start") % int(state.call_reward)
	_refresh_roster(state)
	_board.call("sync", state, _selected_col, _selected_row, _selected_unit)
	if _unit_panel.visible:
		_fill_unit_panel(state)


func _refresh_roster(state: Dictionary) -> void:
	for entry_v in state.roster:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		var character_id := str(entry.get("id", ""))
		var button: Button = _buttons.get(character_id)
		if button == null:
			continue
		var name_label := button.get_node("Row/Info/NameLabel") as Label
		var cost_label := button.get_node("Row/Info/CostLabel") as Label
		name_label.text = str(entry.display_name)
		cost_label.text = tr("ui.battle.spirit") % int(entry.cost)
		var affordable := bool(entry.affordable)
		button.disabled = not affordable
		button.modulate = Color(1, 1, 1, 1.0 if affordable else 0.5)
		var highlighted := affordable and _has_selected_cell()
		if bool(button.get_meta("ready_highlight", false)) != highlighted:
			button.set_meta("ready_highlight", highlighted)
			var style := _style_card_ready if highlighted else _style_card
			_assign_button_style(button, style)


func _fill_unit_panel(state: Dictionary) -> void:
	var unit := _unit_by_id(state, _selected_unit)
	if unit.is_empty():
		_unit_panel.visible = false
		return
	_unit_title.text = tr("ui.battle.unit_level") % [str(unit.display_name), int(unit.level)]
	var cost := int(unit.upgrade_cost)
	if cost < 0:
		_upgrade_button.text = tr("ui.battle.upgrade_max")
		_upgrade_button.disabled = true
	else:
		_upgrade_button.text = tr("ui.battle.upgrade") % cost
		_upgrade_button.disabled = not bool(unit.can_upgrade)
	_sell_button.text = tr("ui.battle.sell") % int(unit.sell_refund)


func _wave_text(state: Dictionary) -> String:
	var phase := str(state.phase)
	var total := int(state.wave_count)
	var index := int(state.wave_index) + 1
	if phase == BattleSim.PHASE_DEPLOY:
		return tr("ui.battle.deploy") % ceili(float(state.phase_time_left))
	if phase == BattleSim.PHASE_VICTORY:
		return tr("ui.battle.victory")
	if phase == BattleSim.PHASE_DEFEAT:
		return tr("ui.battle.defeat")
	if phase == BattleSim.PHASE_FINAL:
		return tr("ui.battle.wave_final") % [index, total]
	if phase == BattleSim.PHASE_INTERMISSION:
		var shown := maxi(index, 1)
		return tr("ui.battle.wave_next") % [shown, total, ceili(float(state.phase_time_left))]
	return tr("ui.battle.wave") % [index, total]


func _on_character_pressed(character_id: String) -> void:
	if _finished:
		return
	_selected_unit = -1
	_unit_panel.visible = false
	if not _has_selected_cell():
		_hint_label.text = tr(_HINT_PICK_CELL)
		_refresh()
		return
	if _sim.place(character_id, _selected_col, _selected_row):
		_clear_selected_cell()
		_hint_label.text = tr(_HINT_DEFAULT)
	else:
		_hint_label.text = tr(_HINT_PLACE_FAILED)
	_refresh()


func _on_cell_pressed(col: int, row: int) -> void:
	if _finished:
		return
	var state := _sim.view_state()
	var unit := _unit_at(state, col, row)
	if not unit.is_empty():
		_clear_selected_cell()
		_selected_unit = int(unit.id)
		_unit_panel.visible = true
		_fill_unit_panel(state)
		_refresh()
		return
	_selected_unit = -1
	_unit_panel.visible = false
	if _cell_mark(col, row) != ".":
		_clear_selected_cell()
		_hint_label.text = tr(_HINT_PICK_CELL)
		_refresh()
		return
	_selected_col = col
	_selected_row = row
	_hint_label.text = tr(_HINT_PICK_CHARACTER)
	_refresh()


func _on_call_pressed() -> void:
	if _finished or str(_sim.view_state().phase) != BattleSim.PHASE_DEPLOY:
		return
	_sim.call_next_wave()
	_refresh()


func _on_speed_pressed() -> void:
	if _speed_options.is_empty():
		return
	var index := _speed_options.find(_speed)
	var next_index := 0 if index < 0 else (index + 1) % _speed_options.size()
	_speed = _speed_options[next_index]
	if _remember_speed:
		remembered_speed = _speed
	_refresh()


func _on_upgrade_pressed() -> void:
	if _finished:
		return
	_sim.upgrade(_selected_unit)
	_refresh()


func _on_sell_pressed() -> void:
	if _finished:
		return
	if _sim.sell(_selected_unit):
		_selected_unit = -1
		_unit_panel.visible = false
	_refresh()


func _on_close_unit_pressed() -> void:
	_selected_unit = -1
	_unit_panel.visible = false
	_refresh()


func _on_retry_pressed() -> void:
	get_tree().reload_current_scene()


func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _show_result(state: Dictionary) -> void:
	_finished = true
	_unit_panel.visible = false
	_result_panel.visible = true
	var won := str(state.outcome) == BattleSim.PHASE_VICTORY
	var title_key := "ui.battle.result_win" if won else "ui.battle.result_lose"
	_result_title.text = tr(title_key)
	_result_body.text = (
		tr("ui.battle.result_body")
		% [
			str(state.level_name),
			int(state.guard_hp),
			int(state.guard_max_hp),
			int(state.spirit),
		]
	)


func _note_events(events: Array) -> void:
	for event_v in events:
		if typeof(event_v) != TYPE_DICTIONARY:
			continue
		if str((event_v as Dictionary).get("type", "")) == "leak":
			_vignette_left = _vignette_duration
	_board.call("push_events", events)


func _fade_vignette(delta: float) -> void:
	if _vignette_left <= 0.0:
		_vignette.color.a = 0.0
		return
	_vignette_left = maxf(0.0, _vignette_left - delta * float(_speed))
	var ratio := 0.0 if _vignette_duration <= 0.0 else _vignette_left / _vignette_duration
	_vignette.color.a = _vignette_alpha * ratio


func _apply_speed_rules() -> void:
	var scale := _catalog.time_scale()
	var options: Array = scale.get("options", [1, 2])
	_speed_options = []
	for item_v in options:
		_speed_options.append(int(item_v))
	if _speed_options.is_empty():
		_speed_options = [1, 2]
	_remember_speed = bool(scale.get("remember_last_speed", true))
	var default_speed := int(scale.get("default_speed", _speed_options[0]))
	if _remember_speed and _speed_options.has(remembered_speed):
		_speed = remembered_speed
		return
	_speed = default_speed if _speed_options.has(default_speed) else _speed_options[0]


func _make_character_card(character_id: String) -> Button:
	var button := Button.new()
	button.custom_minimum_size = Vector2(500, 128)
	button.focus_mode = Control.FOCUS_NONE
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT
	_assign_button_style(button, _style_card)
	var row := HBoxContainer.new()
	row.name = "Row"
	row.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	row.offset_left = 12.0
	row.offset_top = 8.0
	row.offset_right = -12.0
	row.offset_bottom = -8.0
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 12)
	button.add_child(row)
	var portrait := TextureRect.new()
	portrait.name = "Portrait"
	portrait.custom_minimum_size = Vector2(112, 112)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if character_id == "chr_reimu":
		portrait.texture = _REIMU_CARD
	row.add_child(portrait)
	var info := VBoxContainer.new()
	info.name = "Info"
	info.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info.alignment = BoxContainer.ALIGNMENT_CENTER
	info.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_child(info)
	var name_label := Label.new()
	name_label.name = "NameLabel"
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 32)
	name_label.add_theme_color_override("font_color", _INK)
	info.add_child(name_label)
	var cost_label := Label.new()
	cost_label.name = "CostLabel"
	cost_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cost_label.add_theme_font_size_override("font_size", 44)
	cost_label.add_theme_color_override("font_color", _SPIRIT_INK)
	info.add_child(cost_label)
	return button


func _make_ofuda_style(border: Color, width: int) -> StyleBoxFlat:
	var box := StyleBoxFlat.new()
	box.bg_color = _PAPER
	box.border_color = border
	box.set_border_width_all(width)
	box.set_corner_radius_all(8)
	box.content_margin_left = 8
	box.content_margin_right = 8
	box.content_margin_top = 4
	box.content_margin_bottom = 4
	return box


func _assign_button_style(button: Button, style: StyleBoxFlat) -> void:
	for state_name in ["normal", "hover", "pressed", "disabled", "focus"]:
		button.add_theme_stylebox_override(state_name, style)
	button.add_theme_color_override("font_color", _INK)
	button.add_theme_color_override("font_disabled_color", _INK)


func _apply_ofuda_button(button: Button) -> void:
	var normal := _make_ofuda_style(_SEAL, 4)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#E7DCC8")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#D9CBB0")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", normal)
	button.add_theme_stylebox_override("focus", normal)
	button.add_theme_color_override("font_color", _INK)
	button.add_theme_color_override("font_hover_color", _INK)
	button.add_theme_color_override("font_pressed_color", _INK)
	button.add_theme_color_override("font_disabled_color", _INK)


func _apply_static_labels() -> void:
	_close_unit_button.text = tr("ui.battle.close")
	_retry_button.text = tr("ui.battle.retry")
	_menu_button.text = tr("ui.battle.back_to_title")


func _has_selected_cell() -> bool:
	return _selected_col >= 0 and _selected_row >= 0


func _clear_selected_cell() -> void:
	_selected_col = -1
	_selected_row = -1


func _cell_mark(col: int, row: int) -> String:
	var map: Dictionary = _catalog.level().get("map", {})
	var cells: Array = map.get("cells", [])
	if row < 0 or row >= cells.size():
		return ""
	var line := str(cells[row])
	if col < 0 or col >= line.length():
		return ""
	return line.substr(col, 1)


func _unit_at(state: Dictionary, col: int, row: int) -> Dictionary:
	for unit_v in state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		if int(unit.col) == col and int(unit.row) == row:
			return unit
	return {}


func _unit_by_id(state: Dictionary, unit_id: int) -> Dictionary:
	for unit_v in state.get("units", []):
		if typeof(unit_v) != TYPE_DICTIONARY:
			continue
		var unit: Dictionary = unit_v
		if int(unit.get("id", -1)) == unit_id:
			return unit
	return {}


func _capture_sequence() -> void:
	get_window().size = Vector2i(1080, 1920)
	await RenderingServer.frame_post_draw
	_save_capture("01-deploy")
	_on_cell_pressed(2, 4)
	_refresh()
	await RenderingServer.frame_post_draw
	_save_capture("01b-slot")
	_place_opening()
	_clear_selected_cell()
	_hint_label.text = tr(_HINT_DEFAULT)
	_refresh()
	await RenderingServer.frame_post_draw
	_save_capture("02-placed")
	_sim.call_next_wave()
	for _step in 200:
		if str(_sim.view_state().outcome) != "":
			break
		_note_events(_sim.tick())
	_refresh()
	await RenderingServer.frame_post_draw
	_save_capture("03-combat")
	var guard := 0
	while str(_sim.view_state().outcome) == "" and guard < 300000:
		_sim.tick()
		guard += 1
	_show_result(_sim.view_state())
	_board.call("advance_fx", 5.0)
	_refresh()
	await RenderingServer.frame_post_draw
	_save_capture("04-result")
	get_tree().quit()


func _place_opening() -> void:
	for opening_v in _catalog.scripted_opening():
		var opening: Dictionary = opening_v
		(
			_sim
			. place(
				str(opening.get("character_id", "")),
				int(opening.get("col", -1)),
				int(opening.get("row", -1)),
			)
		)


func _save_capture(shot_name: String) -> void:
	var image := get_viewport().get_texture().get_image()
	var directory := OS.get_environment("BATTLE_CAPTURE_DIR")
	if directory == "":
		directory = "user://"
	var path := directory.path_join("%s.png" % shot_name)
	image.save_png(path)
	print("已保存截图 %s" % path)
