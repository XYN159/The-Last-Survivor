extends Control

## 标题画面。开始按钮先播关前视频，再进入序章第一关（CombatCatalog.DEFAULT_LEVEL_ID）。

signal scene_change_requested(path: String)

const PressMotion := preload("res://scripts/ui/press_motion.gd")
const PRE_VIDEO_SCENE := "res://scenes/main/prologue_pre_video.tscn"

## 测试里关掉，只看信号，不真的换场景。
var auto_change_scene: bool = true
var _start_press: PressMotion
var _leaving: bool = false

@onready var _start_button: Button = %StartButton
@onready var _version_label: Label = %VersionLabel
@onready var _title_label: Label = %TitleLabel
@onready var _english_title_label: Label = %EnglishTitleLabel
@onready var _chapter_label: Label = %ChapterLabel
@onready var _prologue_title_label: Label = %PrologueTitleLabel
@onready var _prologue_english_label: Label = %PrologueEnglishLabel
@onready var _subtitle_label: Label = %SubtitleLabel
@onready var _start_frame: Control = %StartFrame


func _ready() -> void:
	_start_button.pressed.connect(_on_start_pressed)
	_start_press = PressMotion.new()
	_start_press.bind(_start_button, [_start_frame], MotionConfig.load_default())
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
	if _leaving:
		return
	_leaving = true
	# 等松开回弹播完再换场景，不然按钮刚弹起来画面就切走了。
	await get_tree().create_timer(_start_press.settle_sec()).timeout
	scene_change_requested.emit(PRE_VIDEO_SCENE)
	if auto_change_scene:
		get_tree().change_scene_to_file(PRE_VIDEO_SCENE)
