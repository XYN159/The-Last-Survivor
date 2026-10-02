extends Control

## 标题画面。开始按钮进入序章第一关（CombatCatalog.DEFAULT_LEVEL_ID）。

@onready var _start_button: Button = %StartButton
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.text = tr("ui.menu.start")
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
	get_tree().change_scene_to_file("res://scenes/battle/battle_board.tscn")
