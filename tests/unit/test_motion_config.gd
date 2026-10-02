extends GutTest

## 依据：data/prototype/ui_motion.json（动效临时值）和 docs/design/ui_motion/prologue_01_motion.md。


func test_default_file_is_marked_temporary() -> void:
	var file := FileAccess.get_file_as_string(MotionConfig.DEFAULT_PATH)
	var parsed: Variant = JSON.parse_string(file)
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	assert_eq(str((parsed as Dictionary).get("meta", {}).get("status", "")), "temporary")


func test_reads_numbers_from_the_default_file() -> void:
	var config := MotionConfig.load_default()
	assert_gt(config.number("entry", "veil_fade_sec", -1.0), 0.0)
	assert_gt(config.number("button", "hover_scale", -1.0), 1.0)
	assert_lt(config.number("button", "press_scale", -1.0), 1.0)


func test_missing_fields_use_the_fallback() -> void:
	var config := MotionConfig.from_dictionary({"entry": {"veil_fade_sec": "slow"}})
	assert_eq(config.number("entry", "veil_fade_sec", 0.5), 0.5)
	assert_eq(config.number("nothing", "here", 0.7), 0.7)


func test_count_rounds_and_never_goes_negative() -> void:
	var config := MotionConfig.from_dictionary({"place": {"mote_count": 5.6, "bad": -3}})
	assert_eq(config.count("place", "mote_count", 0), 6)
	assert_eq(config.count("place", "bad", 2), 0)
