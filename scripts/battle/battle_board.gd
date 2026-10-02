extends Control

## 塔防对局的画面。规则在 BattleSim，这里只负责按钮、棋盘和结算。
## 动效在 BoardMotion（棋盘上）和 ScreenMotion（整屏），这里只在操作发生时通知它们。

const BoardMotion := preload("res://scripts/battle/board_motion.gd")
const ButtonMotion := preload("res://scripts/ui/button_motion.gd")
const ResultSeal := preload("res://scripts/battle/result_seal.gd")
const ScreenMotion := preload("res://scripts/battle/screen_motion.gd")
const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const _HINT_DEFAULT := "ui.battle.hint_default"
const _HINT_PICK_CELL := "ui.battle.hint_pick_cell"
const _HINT_PICK_CHARACTER := "ui.battle.hint_pick_character"
const _HINT_PLACE_FAILED := "ui.battle.hint_place_failed"
const _TITLE_WIN := Color("#C8323C")
const _TITLE_LOSE := Color("#5A6068")

static var remembered_speed: int = 1

var _catalog: CombatCatalog
var _motion_config: MotionConfig
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
var _last_wave_key: String = ""
var _leaving: bool = false

@onready var _spirit_label: Label = %SpiritLabel
@onready var _life_label: Label = %LifeLabel
@onready var _wave_label: Label = %WaveLabel
@onready var _board: Control = %BoardView
@onready var _top_bar: Control = %TopBar
@onready var _bottom_bar: Control = %BottomBar
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
@onready var _board_motion: BoardMotion = %BoardMotion
@onready var _screen_motion: ScreenMotion = %ScreenMotion
@onready var _entry_veil: ColorRect = %EntryVeil
@onready var _entry_ofuda: Control = %EntryOfuda
@onready var _entry_ofuda_label: Label = %EntryOfudaLabel
@onready var _dimmer: ColorRect = %Dimmer
@onready var _result_card: Control = %ResultCard
@onready var _result_seal: ResultSeal = %ResultSeal
@onready var _result_motes: CPUParticles2D = %ResultMotes


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
	_motion_config = MotionConfig.load_default()
	_board.call("setup", _catalog)
	_board_motion.setup(_catalog, _motion_config)
	_screen_motion.setup(_motion_config, _catalog.feel())
	_layout_board()
	_build_roster()
	_attach_button_motion()
	_board_motion.orb_arrived.connect(_on_orb_arrived)
	_vignette.resized.connect(_sync_vignette_size)
	_sync_vignette_size()
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
		_screen_motion.skip_entry(_entry_veil, _entry_ofuda)
		_capture_sequence()
		return
	_play_entry()


func _process(delta: float) -> void:
	_fade_vignette(delta)
	if _capturing:
		_advance_fx(delta)
		return
	if not _finished:
		_run_ticks(delta)
	_advance_fx(delta * float(_speed))
	_refresh()


func _advance_fx(delta: float) -> void:
	_board_motion.advance(delta)
	_board.call("set_unit_scales", _board_motion.unit_scales())
	_board.call("advance_fx", delta)


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
	_board_motion.position = origin
	_board_motion.size = size
	_top_bar.offset_bottom = origin.y
	_bottom_bar.anchor_top = 0.0
	_bottom_bar.anchor_bottom = 1.0
	_bottom_bar.offset_top = origin.y + size.y
	_bottom_bar.offset_bottom = 0.0


func _build_roster() -> void:
	for entry_v in _sim.view_state().roster:
		if typeof(entry_v) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = entry_v
		var character_id := str(entry.get("id", ""))
		var button := Button.new()
		button.custom_minimum_size = Vector2(250, 110)
		button.add_theme_font_size_override("font_size", 32)
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
	_board_motion.sync(state, _selected_col, _selected_row)
	_note_wave_change(state)
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
		button.text = "%s\n%d" % [str(entry.display_name), int(entry.cost)]
		button.disabled = not bool(entry.affordable)
		button.modulate = Color.WHITE


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
		_set_hint(_HINT_PICK_CELL, true)
		_refresh()
		return
	var col := _selected_col
	var row := _selected_row
	if _sim.place(character_id, col, row):
		_clear_selected_cell()
		_set_hint(_HINT_DEFAULT)
		var placed := _unit_at(_sim.view_state(), col, row)
		if not placed.is_empty():
			_board_motion.play_place(col, row, int(placed.id))
	else:
		_set_hint(_HINT_PLACE_FAILED, true)
	_refresh()


func _on_cell_pressed(col: int, row: int) -> void:
	if _finished:
		return
	var state := _sim.view_state()
	var unit := _unit_at(state, col, row)
	if not unit.is_empty():
		_clear_selected_cell()
		_selected_unit = int(unit.id)
		_show_unit_panel()
		_fill_unit_panel(state)
		_refresh()
		return
	_selected_unit = -1
	_unit_panel.visible = false
	if _cell_mark(col, row) != ".":
		_clear_selected_cell()
		_set_hint(_HINT_PICK_CELL, true)
		_refresh()
		return
	_selected_col = col
	_selected_row = row
	_set_hint(_HINT_PICK_CHARACTER)
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
	var unit := _unit_by_id(_sim.view_state(), _selected_unit)
	if _sim.upgrade(_selected_unit) and not unit.is_empty():
		_board_motion.play_level_up(int(unit.col), int(unit.row), _selected_unit)
	_refresh()


func _on_sell_pressed() -> void:
	if _finished:
		return
	var unit := _unit_by_id(_sim.view_state(), _selected_unit)
	if _sim.sell(_selected_unit):
		if not unit.is_empty():
			_board_motion.play_sell(int(unit.col), int(unit.row))
		_selected_unit = -1
		_unit_panel.visible = false
	_refresh()


func _on_close_unit_pressed() -> void:
	_selected_unit = -1
	_unit_panel.visible = false
	_refresh()


func _on_retry_pressed() -> void:
	_leave(_reload_scene)


func _on_menu_pressed() -> void:
	_leave(_open_main_menu)


func _leave(then: Callable) -> void:
	if _leaving:
		return
	_leaving = true
	_screen_motion.leave(_entry_veil, then)


func _reload_scene() -> void:
	get_tree().reload_current_scene()


func _open_main_menu() -> void:
	get_tree().change_scene_to_file(MAIN_MENU_SCENE)


func _show_result(state: Dictionary) -> void:
	_finished = true
	_unit_panel.visible = false
	_screen_motion.hide_now(_entry_ofuda)
	_result_panel.visible = true
	var won := str(state.outcome) == BattleSim.PHASE_VICTORY
	var title_key := "ui.battle.result_win" if won else "ui.battle.result_lose"
	_result_title.text = tr(title_key)
	_result_title.add_theme_color_override("font_color", _TITLE_WIN if won else _TITLE_LOSE)
	_result_body.text = (
		tr("ui.battle.result_body")
		% [
			str(state.level_name),
			int(state.guard_hp),
			int(state.guard_max_hp),
			int(state.spirit),
		]
	)
	if _capturing:
		_result_seal.show_still(won)
		return
	var fade_ins: Array[Control] = [_result_body, _retry_button, _menu_button]
	_screen_motion.play_result(
		_dimmer, _result_card, _result_title, fade_ins, _result_seal, _result_motes, won
	)


func _note_events(events: Array) -> void:
	for event_v in events:
		if typeof(event_v) != TYPE_DICTIONARY:
			continue
		if str((event_v as Dictionary).get("type", "")) == "leak":
			_vignette_left = _vignette_duration
			_screen_motion.hit_life(_life_label)
	_board_motion.set_spirit_target(_spirit_target())
	_board_motion.push_events(events)
	_board.call("push_events", events)


func _on_orb_arrived() -> void:
	_screen_motion.bump(_spirit_label)


func _spirit_target() -> Vector2:
	return _spirit_label.get_global_rect().get_center() - _board_motion.get_global_rect().position


func _play_entry() -> void:
	var bars: Array[Control] = [_top_bar, _bottom_bar]
	var layers: Array[Control] = [_board, _board_motion]
	var level_name := str(_sim.view_state().level_name)
	_screen_motion.play_entry(
		_entry_veil, bars, layers, _entry_ofuda, _entry_ofuda_label, level_name
	)
	var delay := _motion_config.number("entry", "barrier_delay_sec", 0.35)
	get_tree().create_timer(delay).timeout.connect(_board_motion.play_entry)


func _attach_button_motion() -> void:
	var buttons: Array[Button] = [
		_call_button,
		_speed_button,
		_upgrade_button,
		_sell_button,
		_close_unit_button,
		_retry_button,
		_menu_button,
	]
	for button_v in _buttons.values():
		buttons.append(button_v as Button)
	for button in buttons:
		ButtonMotion.new().bind(button, _motion_config)


func _set_hint(key: String, warn: bool = false) -> void:
	var text := tr(key)
	var changed := _hint_label.text != text
	_hint_label.text = text
	if warn:
		_screen_motion.warn(_hint_label)
	elif changed:
		_screen_motion.fade_in(_hint_label)


func _show_unit_panel() -> void:
	var was_visible := _unit_panel.visible
	_unit_panel.visible = true
	if not was_visible:
		_screen_motion.pop_in(_unit_panel)


func _note_wave_change(state: Dictionary) -> void:
	var key := "%s:%d" % [str(state.phase), int(state.wave_index)]
	if key == _last_wave_key:
		return
	if _last_wave_key != "":
		_screen_motion.pop(_wave_label)
	_last_wave_key = key


func _sync_vignette_size() -> void:
	var vignette_material := _vignette.material as ShaderMaterial
	if vignette_material != null:
		vignette_material.set_shader_parameter("rect_size", _vignette.size)


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
