extends Control

## 塔防对局的画面。规则在 BattleSim，这里只负责按钮、棋盘和结算。

const MAIN_MENU_SCENE := "res://scenes/main/main_menu.tscn"
const _DEFAULT_HINT := "先点下面的角色，再点亮色格子。中段两格最合适。"

static var remembered_speed: int = 1

var _catalog: CombatCatalog
var _sim: BattleSim
var _speed: int = 1
var _accumulator: float = 0.0
var _armed_id: String = ""
var _selected_unit: int = -1
var _finished: bool = false
var _capturing: bool = false
var _buttons: Dictionary = {}
var _vignette_left: float = 0.0
var _vignette_duration: float = 0.4
var _vignette_alpha: float = 0.45
var _step_seconds: float = 1.0 / 60.0
var _max_ticks: int = 4

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


func _ready() -> void:
	_catalog = CombatCatalog.load_default()
	_sim = BattleSim.from_catalog(_catalog)
	_speed = 2 if remembered_speed == 2 else 1
	var tune := _catalog.tuning()
	_step_seconds = 1.0 / float(tune.logic_hz)
	_max_ticks = int(tune.max_ticks_per_frame)
	var vignette: Dictionary = _catalog.feel().get("guard_damage_vignette", {})
	_vignette_duration = float(vignette.get("duration_sec", 0.4))
	_vignette_alpha = float(vignette.get("max_alpha", 0.45))
	_board.call("setup", _catalog)
	_layout_board()
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
	_hint_label.text = _DEFAULT_HINT
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
	_spirit_label.text = "灵力 %d" % int(state.spirit)
	_life_label.text = "生命 %d/%d" % [int(state.guard_hp), int(state.guard_max_hp)]
	_wave_label.text = _wave_text(state)
	_speed_button.text = "倍速 ×%d" % _speed
	_call_button.disabled = not bool(state.call_allowed)
	_call_button.text = _call_text(state)
	_refresh_roster(state)
	_board.call("sync", state, _armed_id, _selected_unit)
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
		button.modulate = Color(1, 0.95, 0.7) if _armed_id == character_id else Color.WHITE


func _fill_unit_panel(state: Dictionary) -> void:
	var unit := _unit_by_id(state, _selected_unit)
	if unit.is_empty():
		_unit_panel.visible = false
		return
	_unit_title.text = "%s  %d 级" % [str(unit.display_name), int(unit.level)]
	var cost := int(unit.upgrade_cost)
	if cost < 0:
		_upgrade_button.text = "已满级"
		_upgrade_button.disabled = true
	else:
		_upgrade_button.text = "升级 %d" % cost
		_upgrade_button.disabled = not bool(unit.can_upgrade)
	_sell_button.text = "出售 +%d" % int(unit.sell_refund)


func _wave_text(state: Dictionary) -> String:
	var phase := str(state.phase)
	var total := int(state.wave_count)
	var index := int(state.wave_index) + 1
	if phase == BattleSim.PHASE_DEPLOY:
		return "布阵 %d 秒" % ceili(float(state.phase_time_left))
	if phase == BattleSim.PHASE_VICTORY:
		return "胜利"
	if phase == BattleSim.PHASE_DEFEAT:
		return "失败"
	if phase == BattleSim.PHASE_FINAL:
		return "第 %d/%d 波\n最后一波" % [index, total]
	if phase == BattleSim.PHASE_WAITING or phase == BattleSim.PHASE_INTERMISSION:
		return "第 %d/%d 波\n下一波 %d 秒" % [index, total, ceili(float(state.phase_time_left))]
	return "第 %d/%d 波" % [index, total]


func _call_text(state: Dictionary) -> String:
	var reward := int(state.call_reward)
	if str(state.phase) == BattleSim.PHASE_DEPLOY:
		return "开始 +%d" % reward
	return "叫下一波 +%d" % reward


func _on_character_pressed(character_id: String) -> void:
	if _finished:
		return
	_selected_unit = -1
	_unit_panel.visible = false
	_armed_id = "" if _armed_id == character_id else character_id
	_hint_label.text = _DEFAULT_HINT
	_refresh()


func _on_cell_pressed(col: int, row: int) -> void:
	if _finished:
		return
	var state := _sim.view_state()
	var unit := _unit_at(state, col, row)
	if not unit.is_empty():
		_armed_id = ""
		_selected_unit = int(unit.id)
		_unit_panel.visible = true
		_fill_unit_panel(state)
		_refresh()
		return
	_selected_unit = -1
	_unit_panel.visible = false
	if _armed_id == "":
		_refresh()
		return
	if _sim.place(_armed_id, col, row):
		_armed_id = ""
		_hint_label.text = _DEFAULT_HINT
	else:
		_hint_label.text = "放不下。要亮色格子，并且灵力够。"
	_refresh()


func _on_call_pressed() -> void:
	if _finished:
		return
	_sim.call_next_wave()
	_refresh()


func _on_speed_pressed() -> void:
	_speed = 1 if _speed == 2 else 2
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
	_result_title.text = "守住了" if won else "失守了"
	_result_body.text = (
		"%s\n生命 %d/%d    灵力 %d"
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
	for opening_v in _catalog.level().get("suggested_opening", []):
		if typeof(opening_v) != TYPE_DICTIONARY:
			continue
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
