extends Control

## 序章第一关战斗前的全屏关前视频。台词已经烧进画面，这里不再叠字。
## 画面整幅放进屏幕，不裁边；比例对不上的屏幕在黑底上留黑边，底下的台词始终看得全。
## 只有点右上角真按钮「跳过」才立刻进战斗，点画面其余地方不跳；播完也进战斗。无论哪条路，只换一次场景。
## 视频打不开时只警告，照样进战斗，免得卡死在黑屏上。

signal scene_change_requested(path: String)

const BATTLE_SCENE := "res://scenes/battle/battle_board.tscn"
const VIDEO_PATH := "res://assets/video/prologue_01_pre.ogv"

## 测试里关掉，只看信号，不真的换场景。要在加进场景树之前设。
var auto_change_scene: bool = true
## 测试里可以换成不存在的路径，验证打不开时也能进战斗。要在加进场景树之前设。
var video_path: String = VIDEO_PATH
var _leaving: bool = false

@onready var _player: VideoStreamPlayer = %VideoPlayer
@onready var _skip_button: Button = %SkipButton


func _ready() -> void:
	_skip_button.text = tr("ui.pre_video.skip")
	_skip_button.pressed.connect(skip)
	_player.finished.connect(_enter_battle)
	resized.connect(_fit_inside)
	_player.loop = false
	if not _open_stream():
		push_warning("关前视频打不开，直接进战斗：%s" % video_path)
		_enter_battle.call_deferred()
		return
	_player.play()
	_fit_inside()


func skip() -> void:
	_enter_battle()


func is_leaving() -> bool:
	return _leaving


func _open_stream() -> bool:
	if not ResourceLoader.exists(video_path) and not FileAccess.file_exists(video_path):
		return false
	var stream := VideoStreamTheora.new()
	stream.file = video_path
	_player.stream = stream
	return _player.stream != null and _player.get_stream_length() > 0.0


func _enter_battle() -> void:
	if _leaving:
		return
	_leaving = true
	_player.stop()
	scene_change_requested.emit(BATTLE_SCENE)
	if auto_change_scene:
		get_tree().change_scene_to_file(BATTLE_SCENE)


## 按「整幅放进去」缩放：保持视频比例，放到碰到屏幕较近的一对边为止，居中摆在黑底上。
## 16:9 屏幕正好铺满；更宽或更高的屏幕两侧或上下留黑边，不裁掉画面，也不拉伸。
func _fit_inside() -> void:
	var video_size := Vector2.ZERO
	var texture := _player.get_video_texture()
	if texture != null:
		video_size = texture.get_size()
	if video_size.x <= 0.0 or video_size.y <= 0.0:
		video_size = size
	if video_size.x <= 0.0 or video_size.y <= 0.0:
		return
	var scale_factor := minf(size.x / video_size.x, size.y / video_size.y)
	var fitted := video_size * scale_factor
	_player.position = (size - fitted) * 0.5
	_player.size = fitted
