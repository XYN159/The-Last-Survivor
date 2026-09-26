extends Node

## 启动时换成能显示中文的字体，并保留 Godot 自带的按钮样式。

const FONT_PATH := "res://assets/fonts/NotoSansSC-Regular.ttf"
const DEFAULT_FONT_SIZE := 32


func _ready() -> void:
	var font := load(FONT_PATH) as Font
	if font == null:
		push_warning("中文字体加载失败：%s" % FONT_PATH)
		return
	var theme := ThemeDB.get_default_theme().duplicate(true) as Theme
	theme.default_font = font
	theme.default_font_size = DEFAULT_FONT_SIZE
	get_tree().root.theme = theme
