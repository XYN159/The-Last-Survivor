extends Control

## 塔防对局的画面。规则在 BattleSim，这里只负责按钮、棋盘和结算。

const FLOW_SCENE := "res://scenes/main/original_flow.tscn"
const _HINT_DEFAULT := "ui.battle.hint_default"
const _HINT_PICK_CELL := "ui.battle.hint_pick_cell"
const _HINT_PICK_CHARACTER := "ui.battle.hint_pick_character"
const _HINT_PLACE_FAILED := "ui.battle.hint_place_failed"
const _CARD_FRAME := preload("res://assets/art/prologue_01/card_frame.png")
const _REIMU_TOKEN := preload("res://assets/art/prologue_01/reimu_token.png")
const BoardMotion := preload("res://scripts/battle/board_motion.gd")
const ScreenMotion := preload("res://scripts/battle/screen_motion.gd")
const PressMotion := preload("res://scripts/ui/press_motion.gd")
const OriginalFlow := preload("res://scripts/main/original_flow.gd")

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
var _roster_labels: Dictionary = {}
var _vignette_left: float = 0.0
var _vignette_duration: float = 0.4
var _vignette_alpha: float = 0.45
var _step_seconds: float = 1.0 / 60.0
var _max_ticks: int = 4
var _call_press: PressMotion
var _starting_spirit: int = 0

@onready var _spirit_label: Label = %SpiritLabel
@onready var _life_label: Label = %LifeLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _spirit_fill: Control = %SpiritFill
@onready var _life_fill: Control = %LifeFill
@onready var _wave_fill: Control = %WaveFill
@onready var _board: Control = %BoardView
@onready var _character_bar: HBoxContainer = %CharacterBar
@onready var _call_button: Button = %CallButton
@onready var _speed_button: Button = %SpeedButton
# Button 不支持字体阴影，倍速文字放在按钮里的 Label 上。
@onready var _speed_label: Label = %SpeedLabel
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
@onready var _call_frame: Control = %CallFrame
@onready var _board_motion: BoardMotion = %BoardMotion
@onready var _screen_motion: ScreenMotion = %ScreenMotion


func _ready() -> void:
	_catalog = CombatCatalog.load_default()
	_sim = BattleSim.from_catalog(_catalog)
	_apply_speed_rules()
	var tune := _catalog.tuning()
	_step_seconds = 1.0 / float(tune.logic_hz)
	_max_ticks = int(tune.max_ticks_per_frame)
	_starting_spirit = int(tune.starting_spirit)
	var vignette: Dictionary = _catalog.feel().get("guard_damage_vignette", {})
	_vignette_duration = float(vignette.get("duration_sec", 0.4))
	_vignette_alpha = float(vignette.get("max_alpha", 0.45))
	_board.call("setup", _catalog)
	_setup_motion()
	_build_roster()
	_call_button.pressed.connect(_on_call_pressed)
	_speed_button.pressed.connect(_on_speed_pressed)
	_upgrade_button.pressed.connect(_on_upgrade_pressed)
	_sell_button.pressed.connect(_on_sell_pressed)
	_close_unit_button.pressed.connect(_on_close_unit_pressed)
	_retry_button.pressed.connect(_on_retry_pressed)
	_menu_button.pressed.connect(_on_menu_pressed)
	_board.connect("cell_pressed", _on_cell_pressed)
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
		_advance_board_fx(delta)
		return
	if not _finished:
		_run_ticks(delta)
	_advance_board_fx(delta * float(_speed))
	_refresh()


## 棋盘上的战斗光效跟倍速走；界面动效（ScreenMotion、按钮）按真实时间走。
func _advance_board_fx(delta: float) -> void:
	_board.call("advance_fx", delta)
	_board_motion.advance(delta)


func _setup_motion() -> void:
	var config := MotionConfig.load_default()
	_board_motion.setup(_board, config, _spirit_label)
	_board.call("attach_motion", _board_motion)
	_board_motion.spirit_mote_arrived.connect(_screen_motion.glow_spirit)
	_call_press = PressMotion.new()
	_call_press.bind(_call_button, [_call_frame], config)
	_screen_motion.setup(config)
	_screen_motion.play_entry()


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


func _build_roster() -> void:
	for entry_v in _sim.view_state().roster:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		var character_id := str(entry.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(180, 204)
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		button.add_theme_color_override("font_color", Color.TRANSPARENT)
		button.add_theme_color_override("font_disabled_color", Color.TRANSPARENT)
		button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		var portrait := TextureRect.new()
		portrait.position = Vector2(20, 14)
		portrait.size = Vector2(140, 150)
		portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
		portrait.texture = _REIMU_TOKEN
		portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		button.add_child(portrait)
		var frame := TextureRect.new()
		frame.size = Vector2(180, 204)
		frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		frame.texture = _CARD_FRAME
		frame.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		frame.stretch_mode = TextureRect.STRETCH_SCALE
		button.add_child(frame)
		var label := Label.new()
		label.position = Vector2(10, 155)
		label.size = Vector2(160, 42)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_color_override("font_color", Color("#F8EBDD"))
		label.add_theme_color_override("font_shadow_color", Color("#16070B"))
		label.add_theme_constant_override("shadow_offset_x", 2)
		label.add_theme_constant_override("shadow_offset_y", 2)
		label.add_theme_font_size_override("font_size", 23)
		button.add_child(label)
		button.pressed.connect(_on_character_pressed.bind(character_id))
		_character_bar.add_child(button)
		_buttons[character_id] = button
		_roster_labels[character_id] = label


func _refresh() -> void:
	var state := _sim.view_state()
	_spirit_label.text = tr("ui.battle.spirit") % int(state.spirit)
	_life_label.text = tr("ui.battle.life") % [int(state.guard_hp), int(state.guard_max_hp)]
	# 状态条只有一行高，两行的波次文字在条里并成一行。
	_wave_label.text = _wave_text(state).replace("\n", "  ")
	_refresh_bars(state)
	_speed_label.text = tr("ui.battle.speed") % _speed
	# 叫波还没拍板（D-18），这个按钮只在布阵时当「开始」用。
	_call_button.visible = str(state.phase) == BattleSim.PHASE_DEPLOY
	_call_button.disabled = not bool(state.call_allowed)
	_call_button.text = tr("ui.battle.start") % int(state.call_reward)
	_refresh_roster(state)
	_board.call("sync", state, _selected_col, _selected_row, _selected_unit)
	if _unit_panel.visible:
		_fill_unit_panel(state)


## 三条状态条的填充长度。灵力以开局灵力为满，花掉就变短，攒得比开局多时保持满条。
func _refresh_bars(state: Dictionary) -> void:
	var spirit := float(state.spirit)
	_spirit_fill.anchor_right = fill_ratio(spirit, maxf(float(_starting_spirit), spirit))
	_life_fill.anchor_right = fill_ratio(float(state.guard_hp), float(state.guard_max_hp))
	var duration := float(state.get("phase_duration", 0.0))
	var wave_ratio := 1.0
	if duration > 0.0:
		wave_ratio = fill_ratio(float(state.phase_time_left), duration)
	_wave_fill.anchor_right = wave_ratio


static func fill_ratio(value: float, full: float) -> float:
	if full <= 0.0:
		return 0.0
	return clampf(value / full, 0.0, 1.0)


func _refresh_roster(state: Dictionary) -> void:
	for entry_v in state.roster:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		var character_id := str(entry.get("id", ""))
		var button: Button = _buttons.get(character_id)
		if button == null:
			continue
		button.text = "%s\n%d" % [str(entry.display_name), int(entry.cost)]
		var label: Label = _roster_labels.get(character_id)
		if label != null:
			label.text = "%s  ◆%d" % [str(entry.display_name), int(entry.cost)]
		button.disabled = not bool(entry.affordable)
		button.modulate = Color(0.55, 0.55, 0.62, 0.72) if button.disabled else Color.WHITE


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
		var unit := _unit_at(_sim.view_state(), _selected_col, _selected_row)
		_board_motion.play_place(_selected_col, _selected_row, int(unit.get("id", -1)))
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
	_board_motion.play_select(col, row)
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
	# 守住或失守都先看结算原画，再从那里回主界面。
	OriginalFlow.pending_entry = OriginalFlow.RESULT_SCREEN
	get_tree().change_scene_to_file(FLOW_SCENE)


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
	_screen_motion.play_result(won)


func _note_events(events: Array) -> void:
	for event_v in events:
		if typeof(event_v) != TYPE_DICTIONARY:
			continue
		if str((event_v as Dictionary).get("type", "")) == "leak":
			_vignette_left = _vignette_duration
			_screen_motion.shake_life()
	_board.call("push_events", events)
	_board_motion.push_events(events)


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


func _apply_static_labels() -> void:
	_close_unit_button.text = tr("ui.battle.close")
	_retry_button.text = tr("ui.battle.retry")
	_menu_button.text = tr("ui.battle.continue")


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
	_screen_motion.finish_entry()
	await RenderingServer.frame_post_draw
	_save_capture("01-deploy")
	_place_opening()
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
