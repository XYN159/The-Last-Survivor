extends GutTest

## 依据：docs/design/ui_motion/prologue_01_motion.md；
## 光点数量、飞行时间、上限读 data/prototype/combat/feel.json 的 kill_burst（照抄 PR #4）。

const BoardMotion := preload("res://scripts/battle/board_motion.gd")

var _catalog: CombatCatalog
var _motion: BoardMotion


func before_each() -> void:
	_catalog = CombatCatalog.load_default()
	_motion = BoardMotion.new()
	add_child_autofree(_motion)
	_motion.setup(_catalog, MotionConfig.load_default())


func test_placed_unit_lands_from_above_and_settles() -> void:
	_motion.play_place(2, 4, 7)
	assert_gt(float(_motion.unit_scales()[7]), 1.0)
	assert_gt(_motion.active_effect_count(), 0)
	_motion.advance(1.0)
	assert_false(_motion.unit_scales().has(7))
	assert_eq(_motion.active_effect_count(), 0)


func test_kill_sends_orbs_that_reach_the_spirit_counter() -> void:
	var feel: Dictionary = _catalog.feel().get("kill_burst", {})
	var per_kill := int(feel.get("particles_per_kill", 0))
	_motion.set_spirit_target(Vector2(90, -70))
	_motion.push_events([{"type": "death", "x": 3.5, "y": 2.5, "id": 1}])
	assert_eq(_motion.active_orb_count(), per_kill)
	watch_signals(_motion)
	_motion.advance(float(feel.get("fly_duration_sec", 0.5)) + 0.5)
	assert_eq(_motion.active_orb_count(), 0)
	assert_signal_emit_count(_motion, "orb_arrived", per_kill)


func test_orbs_respect_the_on_screen_cap() -> void:
	var cap := int(_catalog.feel().get("kill_burst", {}).get("max_active_orbs", 0))
	var deaths: Array = []
	for i in 30:
		deaths.append({"type": "death", "x": 3.5, "y": 2.0, "id": i})
	_motion.push_events(deaths)
	assert_eq(_motion.active_orb_count(), cap)


func test_hits_and_leaks_spawn_short_lived_effects() -> void:
	(
		_motion
		. push_events(
			[
				{"type": "damage", "x": 3.5, "y": 3.0, "amount": 10, "heavy": false, "id": 1},
				{"type": "leak", "amount": 1, "x": 3.5, "y": 11.5},
			]
		)
	)
	assert_eq(_motion.active_effect_count(), 2)
	_motion.advance(1.0)
	assert_eq(_motion.active_effect_count(), 0)


func test_entry_sweeps_the_slots_once() -> void:
	_motion.play_entry()
	assert_true(_motion.is_sweeping())
	_motion.advance(5.0)
	assert_false(_motion.is_sweeping())


func test_level_up_pops_the_unit() -> void:
	_motion.play_level_up(2, 4, 3)
	_motion.advance(0.15)
	assert_gt(float(_motion.unit_scales()[3]), 1.0)
