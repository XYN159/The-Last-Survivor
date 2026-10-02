extends GutTest

## 动效时长表：标成临时，数字都能读出来，缺字段时退回后备值。


func test_motion_table_is_marked_temporary() -> void:
	assert_true(FileAccess.file_exists(MotionConfig.DEFAULT_PATH))
	assert_eq(MotionConfig.load_default().status(), "temporary")


func test_every_motion_number_is_non_negative() -> void:
	var parsed: Variant = JSON.parse_string(
		FileAccess.get_file_as_string(MotionConfig.DEFAULT_PATH)
	)
	assert_eq(typeof(parsed), TYPE_DICTIONARY)
	var checked := 0
	for section_v in (parsed as Dictionary).keys():
		if str(section_v) == "meta":
			continue
		var section: Dictionary = (parsed as Dictionary)[section_v]
		for key_v in section.keys():
			var value: Variant = section[key_v]
			assert_true(typeof(value) in [TYPE_INT, TYPE_FLOAT], "%s.%s" % [section_v, key_v])
			assert_true(float(value) >= 0.0, "%s.%s" % [section_v, key_v])
			checked += 1
	assert_gt(checked, 20)


func test_missing_fields_fall_back() -> void:
	var config := MotionConfig.from_dictionary({"button": {"press_scale": "x"}})
	assert_eq(config.number("button", "press_scale", 0.9), 0.9)
	assert_eq(config.number("nothing", "here", 0.4), 0.4)
	assert_eq(config.count("place", "paper_count", 6), 6)


func test_missing_file_still_gives_a_config() -> void:
	var config := MotionConfig.load_path("res://data/prototype/no_such_motion.json")
	assert_eq(config.number("entry", "veil_fade_sec", 0.6), 0.6)


func test_back_ease_overshoots_then_lands() -> void:
	assert_almost_eq(MotionEase.out_back(0.0, 1.8), 0.0, 0.0001)
	assert_almost_eq(MotionEase.out_back(1.0, 1.8), 1.0, 0.0001)
	assert_gt(MotionEase.out_back(0.7, 1.8), 1.0)
