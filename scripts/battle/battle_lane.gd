extends Control

## 占位战斗车道。这里还没有角色移动，只展示从数值配置读到的小队人数。

@onready var _back_button: Button = %BackButton
@onready var _status_label: Label = %StatusLabel


func _ready() -> void:
	_back_button.pressed.connect(_on_back_pressed)
	_status_label.text = "小队人数：%d" % GameState.squad_size


func _on_back_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main/main_menu.tscn")
