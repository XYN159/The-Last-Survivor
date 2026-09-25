class_name SaveGame
extends RefCounted

## 把一份字典写成本地 JSON 存档。当前只有单机文件；以后服务器可以收发同一份字段。

const SAVE_VERSION := 1


static func to_json_text(data: Dictionary) -> String:
	var payload := {
		"version": SAVE_VERSION,
		"data": data,
	}
	return JSON.stringify(payload, "\t")


static func from_json_text(text: String) -> Dictionary:
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return {}
	var parsed: Variant = parser.data
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var body: Dictionary = parsed
	var data: Variant = body.get("data", {})
	if typeof(data) != TYPE_DICTIONARY:
		return {}
	return data


static func save_to_file(path: String, data: Dictionary) -> Error:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(to_json_text(data))
	return OK


static func load_from_file(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	return from_json_text(file.get_as_text())
