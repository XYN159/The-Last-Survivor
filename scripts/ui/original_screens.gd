class_name OriginalScreens
extends RefCounted

## 界面原画的画面表，读 data/ui/original_screens.json。
## 每个画面是一张 1920×1080 原画，加上一组点击区（透明按钮或带字的小按钮）。
## 这里只读数据，不建节点；换画面的事交给 original_flow.gd。

const DEFAULT_PATH := "res://data/ui/original_screens.json"
const ACTION_PUSH := "push"
const ACTION_REPLACE := "replace"
const ACTION_RESET := "reset"
const ACTION_BACK := "back"
const ACTION_POPUP := "popup"
const ACTION_CLOSE_POPUP := "close_popup"
const ACTION_BATTLE := "battle"
const ACTIONS: Array[String] = [
	ACTION_PUSH,
	ACTION_REPLACE,
	ACTION_RESET,
	ACTION_BACK,
	ACTION_POPUP,
	ACTION_CLOSE_POPUP,
	ACTION_BATTLE,
]
const _FALLBACK_BACK_RECT := Rect2(24, 996, 160, 60)

var _data: Dictionary = {}


static func load_default() -> OriginalScreens:
	return load_path(DEFAULT_PATH)


static func load_path(path: String) -> OriginalScreens:
	var screens := OriginalScreens.new()
	if not FileAccess.file_exists(path):
		push_warning("找不到界面原画表：%s" % path)
		return screens
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		push_warning("界面原画表不是合法 JSON：%s" % path)
		return screens
	var parsed: Variant = parser.data
	if typeof(parsed) == TYPE_DICTIONARY:
		screens._data = parsed
	return screens


func ids() -> Array[String]:
	var result: Array[String] = []
	for key in _screens().keys():
		result.append(str(key))
	return result


func has_screen(screen_id: String) -> bool:
	return _screens().has(screen_id)


func image_path(screen_id: String) -> String:
	return str(_screen(screen_id).get("image", ""))


func is_popup(screen_id: String) -> bool:
	return bool(_screen(screen_id).get("popup", false))


func has_back(screen_id: String) -> bool:
	return bool(_screen(screen_id).get("back", true))


func back_rect(screen_id: String) -> Rect2:
	var own: Variant = _screen(screen_id).get("back_rect", null)
	if own != null:
		return _to_rect(own, _FALLBACK_BACK_RECT)
	return _to_rect(_data.get("back_rect", null), _FALLBACK_BACK_RECT)


func design_size() -> Vector2:
	var size_v: Variant = _data.get("design_size", [])
	if typeof(size_v) == TYPE_ARRAY and (size_v as Array).size() == 2:
		return Vector2(float(size_v[0]), float(size_v[1]))
	return Vector2(1920, 1080)


## 返回这一屏的点击区。每项至少有 id、rect（Rect2）、action；可能有 target 和 label。
func hotspots(screen_id: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var list_v: Variant = _screen(screen_id).get("hotspots", [])
	if typeof(list_v) != TYPE_ARRAY:
		return result
	for item_v in list_v:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_v
		(
			result
			. append(
				{
					"id": str(item.get("id", "")),
					"rect": _to_rect(item.get("rect", null), Rect2()),
					"action": str(item.get("action", "")),
					"target": str(item.get("target", "")),
					"label": str(item.get("label", "")),
				}
			)
		)
	return result


func _screens() -> Dictionary:
	var found: Variant = _data.get("screens", {})
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return found


func _screen(screen_id: String) -> Dictionary:
	var found: Variant = _screens().get(screen_id, {})
	if typeof(found) != TYPE_DICTIONARY:
		return {}
	return found


func _to_rect(value: Variant, fallback: Rect2) -> Rect2:
	if typeof(value) != TYPE_ARRAY:
		return fallback
	var parts: Array = value
	if parts.size() != 4:
		return fallback
	return Rect2(float(parts[0]), float(parts[1]), float(parts[2]), float(parts[3]))
