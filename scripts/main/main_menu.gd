extends Control

## 标题画面。开始按钮只负责进入占位战斗车道，用来确认场景切换。

@onready var _start_button: Button = %StartButton
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	var version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	_version_label.text = "v%s" % version


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/battle_lane.tscn")
