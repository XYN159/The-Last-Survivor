extends Control

## 标题画面。开始按钮进入序章第一关（CombatCatalog.DEFAULT_LEVEL_ID）。
## 点开始后画面先转暗再换场景，和第一关进关时的暗幕接上。

const ButtonMotion := preload("res://scripts/ui/button_motion.gd")
const BATTLE_SCENE := "res://scenes/battle/battle_board.tscn"

var _motion_config: MotionConfig
var _leaving: bool = false

@onready var _start_button: Button = %StartButton
@onready var _version_label: Label = %VersionLabel
@onready var _veil: ColorRect = %Veil


func _ready() -> void:
	_motion_config = MotionConfig.load_default()
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.text = tr("ui.menu.start")
	ButtonMotion.new().bind(_start_button, _motion_config)
	var title := get_node("CenterColumn/TitleLabel") as Label
	var subtitle := get_node("CenterColumn/SubtitleLabel") as Label
	var hint := get_node("CenterColumn/HintLabel") as Label
	if title != null:
		title.text = tr("ui.menu.title")
	if subtitle != null:
		subtitle.text = tr("ui.menu.subtitle")
	if hint != null:
		hint.text = tr("ui.menu.hint")
	var version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	_version_label.text = tr("ui.menu.version") % version


func _on_start_pressed() -> void:
	if _leaving:
		return
	_leaving = true
	_veil.visible = true
	var tween := create_tween()
	tween.tween_property(
		_veil, "color:a", 1.0, _motion_config.number("transition", "leave_sec", 0.25)
	)
	tween.tween_callback(_enter_battle)


func _enter_battle() -> void:
	get_tree().change_scene_to_file(BATTLE_SCENE)
