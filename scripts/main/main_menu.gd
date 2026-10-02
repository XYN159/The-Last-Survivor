extends Control

## 标题画面。开始按钮进入序章第一关（CombatCatalog.DEFAULT_LEVEL_ID）。

@onready var _start_button: Button = %StartButton
@onready var _version_label: Label = %VersionLabel
@onready var _title_label: Label = %TitleLabel
@onready var _english_title_label: Label = %EnglishTitleLabel
@onready var _chapter_label: Label = %ChapterLabel
@onready var _prologue_title_label: Label = %PrologueTitleLabel
@onready var _prologue_english_label: Label = %PrologueEnglishLabel
@onready var _subtitle_label: Label = %SubtitleLabel


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_button.text = tr("ui.menu.start")
	_title_label.text = tr("ui.menu.title")
	_english_title_label.text = tr("ui.menu.english_title")
	_chapter_label.text = tr("ui.menu.chapter")
	_prologue_title_label.text = tr("ui.menu.prologue_title")
	_prologue_english_label.text = tr("ui.menu.prologue_english")
	_subtitle_label.text = tr("ui.menu.subtitle")
	var version := str(ProjectSettings.get_setting("application/config/version", "0.1.0"))
	_version_label.text = tr("ui.menu.version") % version


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/battle/battle_board.tscn")
