extends Control

## 结算卡片标题后面的结界纹：展开之后慢慢转。守住了用金和朱红，失守了褪成灰。
## 圈心跟着标题走，标题换位置不用改这里。

const _GOLD := Color("#D4A94F")
const _VERMILION := Color("#C8323C")
const _PAPER := Color("#FFFBEF")
const _FADED := Color("#9AA0A6")
const _DASHES := 24
const _TALISMANS := 8

@export var anchor_path: NodePath

var progress: float = 0.0:
	set(value):
		progress = clampf(value, 0.0, 1.0)
		queue_redraw()

var _won: bool = true
var _spin: float = 0.0
var _spin_speed: float = 0.25
var _tween: Tween


func play(won: bool, seconds: float, spin_speed: float) -> void:
	_won = won
	_spin_speed = spin_speed if won else spin_speed * 0.4
	_spin = 0.0
	progress = 0.0
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "progress", 1.0, maxf(seconds, 0.01)).set_trans(Tween.TRANS_CUBIC)
	set_process(true)


func show_still(won: bool) -> void:
	_won = won
	progress = 1.0


func is_won() -> bool:
	return _won


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_process(false)


func _process(delta: float) -> void:
	_spin += delta * _spin_speed
	queue_redraw()


func _draw() -> void:
	if progress <= 0.0:
		return
	var center := _center()
	var eased := 1.0 - pow(1.0 - progress, 3.0)
	var radius := lerpf(60.0, 168.0, eased)
	var main := _GOLD if _won else _FADED
	var accent := _VERMILION if _won else _FADED
	var alpha := 0.55 * progress if _won else 0.4 * progress
	for i in _DASHES:
		var start := _spin + TAU * float(i) / float(_DASHES)
		draw_arc(
			center, radius, start, start + TAU / float(_DASHES) * 0.6, 6, Color(main, alpha), 4.0
		)
	draw_arc(center, radius * 0.84, 0.0, TAU, 64, Color(accent, alpha * 0.8), 2.0, true)
	for i in _TALISMANS:
		var angle := -_spin * 0.6 + TAU * float(i) / float(_TALISMANS)
		var point := center + Vector2.from_angle(angle) * radius * 1.12
		draw_set_transform(point, angle + PI * 0.5, Vector2.ONE)
		draw_rect(Rect2(Vector2(-7, -13), Vector2(14, 26)), Color(_PAPER, alpha * 1.4))
		draw_rect(Rect2(Vector2(-2, -9), Vector2(4, 18)), Color(accent, alpha * 1.4))
		draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _center() -> Vector2:
	var anchor := get_node_or_null(anchor_path) as Control
	if anchor == null:
		return size * 0.5
	return anchor.get_global_rect().get_center() - get_global_rect().position
