extends GutTest

## 依据：docs/design/ui_motion/prologue_01_motion.md「按钮」一节。

const ButtonMotion := preload("res://scripts/ui/button_motion.gd")

var _button: Button
var _fx: ButtonMotion


func before_each() -> void:
	_button = Button.new()
	_button.size = Vector2(200, 100)
	add_child_autofree(_button)
	_fx = ButtonMotion.new()
	_fx.bind(_button, MotionConfig.load_default())


func test_motion_is_a_child_that_ignores_clicks() -> void:
	assert_eq(_fx.get_parent(), _button)
	assert_eq(_fx.mouse_filter, Control.MOUSE_FILTER_IGNORE)


func test_press_flashes_then_fades() -> void:
	_button.pressed.emit()
	assert_gt(_fx.flash_left(), 0.0)
	await wait_seconds(0.5)
	assert_eq(_fx.flash_left(), 0.0)


func test_button_down_squashes_and_release_springs_back() -> void:
	_button.button_down.emit()
	await wait_seconds(0.15)
	assert_lt(_button.scale.x, 1.0)
	_button.button_up.emit()
	await wait_seconds(0.4)
	assert_almost_eq(_button.scale.x, 1.0, 0.01)


func test_disabled_button_does_not_squash() -> void:
	_button.disabled = true
	_button.button_down.emit()
	await wait_seconds(0.15)
	assert_eq(_button.scale.x, 1.0)
