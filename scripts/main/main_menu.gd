extends Control

## 标题画面。开始按钮进入序章第一关（CombatCatalog.DEFAULT_LEVEL_ID）。

@onready var _start_button: Button = %StartButton
@onready var _version_label: Label = %VersionLabel


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.text = tr("ui.menu.start")
	_apply_ofuda_button(_start_button)
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
	if OS.get_environment("TITLE_CAPTURE") == "1":
		_capture_title()


func _apply_ofuda_button(button: Button) -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color("#F5EFE2")
	normal.border_color = Color("#C8323C")
	normal.set_border_width_all(4)
	normal.set_corner_radius_all(8)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("#E7DCC8")
	var pressed := normal.duplicate() as StyleBoxFlat
	pressed.bg_color = Color("#D9CBB0")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_color_override("font_color", Color("#2B2B33"))
	button.add_theme_color_override("font_hover_color", Color("#2B2B33"))
	button.add_theme_color_override("font_pressed_color", Color("#2B2B33"))


func _capture_title() -> void:
	get_window().size = Vector2i(1080, 1920)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	var directory := OS.get_environment("TITLE_CAPTURE_DIR")
	if directory == "":
		directory = "user://"
	var path := directory.path_join("00-title.png")
	image.save_png(path)
	print("已保存截图 %s" % path)
	get_tree().quit()


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/battle_board.tscn")
