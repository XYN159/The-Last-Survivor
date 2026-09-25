extends GutTest

const _TEMP_NAME := "gut_save_game_test.json"


func after_each() -> void:
	var directory := DirAccess.open("user://")
	if directory != null and directory.file_exists(_TEMP_NAME):
		directory.remove(_TEMP_NAME)


func test_round_trip_keeps_squad_and_supplies() -> void:
	var path := "user://%s" % _TEMP_NAME
	var payload := {"squad_size": 4, "supplies": 12}
	var error := SaveGame.save_to_file(path, payload)
	assert_eq(error, OK)
	var loaded := SaveGame.load_from_file(path)
	assert_eq(int(loaded["squad_size"]), 4)
	assert_eq(int(loaded["supplies"]), 12)


func test_missing_file_returns_empty_dictionary() -> void:
	var loaded := SaveGame.load_from_file("user://this-save-does-not-exist.json")
	assert_eq(loaded.size(), 0)


func test_invalid_text_returns_empty_dictionary() -> void:
	var loaded := SaveGame.from_json_text("{")
	assert_eq(loaded.size(), 0)
