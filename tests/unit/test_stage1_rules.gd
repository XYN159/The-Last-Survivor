extends GutTest

## 第一关战斗规则（制作人决定，数字在 data/balance/stage1_rules.json）：
## 朝向、同名上限、不能升级、撤退返还和再部署、回灵和上限、灵梦的结界、Boss 漏怪、时间轴出怪。

const Fixture := preload("res://tests/unit/battle_fixture.gd")
const ONE_SECOND := 60


func test_place_needs_an_explicit_facing() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 50})
	assert_false(sim.place("chr_reimu", 1, 5, ""))
	assert_false(sim.place("chr_reimu", 1, 5, "north"))
	assert_eq(sim.view_state().units.size(), 0)
	assert_eq(sim.view_state().spirit, 50)
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	assert_eq(sim.view_state().units[0].facing, "left")


func test_deploy_cost_comes_from_stage1_rules() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 50})
	assert_eq(int(sim.view_state().roster[0].cost), 16)
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	assert_eq(sim.view_state().spirit, 34)


func test_second_copy_of_the_same_character_is_refused() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 99})
	assert_true(sim.place("chr_reimu", 1, 1, "left"))
	assert_false(sim.can_place("chr_reimu", 1, 2))
	assert_false(sim.place("chr_reimu", 1, 2, "left"))
	assert_eq(sim.view_state().units.size(), 1)
	assert_false(bool(sim.view_state().roster[0].affordable))


func test_character_max_copies_beats_the_global_limit() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 99, "max_copies": 2})
	assert_true(sim.place("chr_reimu", 1, 1, "left"))
	assert_true(sim.place("chr_reimu", 1, 2, "left"))
	assert_false(sim.place("chr_reimu", 1, 3, "left"))


func test_upgrade_always_fails() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 99})
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	var unit_id := int(sim.view_state().units[0].id)
	var before := int(sim.view_state().spirit)
	assert_false(sim.upgrade(unit_id))
	assert_false(sim.upgrade(-1))
	assert_eq(sim.view_state().spirit, before)
	assert_eq(int(sim.view_state().units[0].level), 1)


func test_retreat_refunds_half_of_this_deploy() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 20})
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	assert_eq(sim.view_state().spirit, 4)
	var unit_id := int(sim.view_state().units[0].id)
	assert_eq(int(sim.view_state().units[0].retreat_refund), 8)
	assert_true(sim.retreat(unit_id))
	assert_eq(sim.view_state().spirit, 12)
	assert_eq(sim.view_state().units.size(), 0)
	assert_false(sim.retreat(unit_id))


func test_retreat_refund_rounds_down() -> void:
	var sim := Fixture.mini_sim(
		{"starting_spirit": 20, "stage1": {"deploy_cost": {"chr_reimu": 15}}}
	)
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	assert_true(sim.retreat(int(sim.view_state().units[0].id)))
	assert_eq(sim.view_state().spirit, 5 + 7)


func test_cannot_redeploy_for_twenty_seconds_after_retreat() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 99, "deploy": 1000.0})
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	assert_true(sim.retreat(int(sim.view_state().units[0].id)))
	assert_false(sim.place("chr_reimu", 1, 5, "left"))
	assert_almost_eq(float(sim.view_state().roster[0].respawn_left), 20.0, 0.001)
	Fixture.tick(sim, 20 * ONE_SECOND - 1)
	assert_false(sim.can_place("chr_reimu", 1, 5))
	assert_false(sim.place("chr_reimu", 1, 5, "left"))
	Fixture.tick(sim, 1)
	assert_true(sim.place("chr_reimu", 1, 5, "left"))


func test_redeploy_cost_rises_by_half_and_stops_at_double() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 99, "stage1": {"respawn_sec": 0}})
	var costs: Array[int] = []
	for _round in 4:
		costs.append(int(sim.view_state().roster[0].cost))
		assert_true(sim.place("chr_reimu", 1, 5, "left"))
		assert_true(sim.retreat(int(sim.view_state().units[0].id)))
	assert_eq(costs, [16, 24, 32, 32] as Array[int])


func test_spirit_regenerates_one_point_per_second() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 10, "deploy": 1000.0})
	Fixture.tick(sim, ONE_SECOND - 1)
	assert_eq(sim.view_state().spirit, 10)
	Fixture.tick(sim, 1)
	assert_eq(sim.view_state().spirit, 11)
	Fixture.tick(sim, 5 * ONE_SECOND)
	assert_eq(sim.view_state().spirit, 16)


func test_spirit_never_goes_above_99() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 97, "deploy": 1000.0})
	Fixture.tick(sim, 10 * ONE_SECOND)
	assert_eq(sim.view_state().spirit, 99)
	assert_eq(sim.view_state().max_spirit, 99)
	var capped := Fixture.mini_sim({"starting_spirit": 150})
	assert_eq(capped.view_state().spirit, 99)


func test_waves_no_longer_pay_spirit() -> void:
	var sim := Fixture.wave_pair({"hp": 100000, "starting_spirit": 10})
	var ticks := Fixture.ticks_until_wave(sim, 1)
	assert_eq(int(sim.view_state().spirit), 10 + floori(float(ticks) / 60.0))


func test_reimu_does_not_hurt_enemies_outside_her_barrier() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"deploy": 0.0,
				"speed": 0.0,
				"barrier": true,
				"starting_spirit": 50,
				"interval": 0.2,
			}
		)
	)
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	var dealt := 0
	for _step in 3 * ONE_SECOND:
		for event_v in sim.tick():
			if str(event_v.type) == "damage":
				dealt += int(event_v.amount)
	assert_eq(sim.view_state().enemies.size(), 1)
	assert_almost_eq(float(sim.view_state().enemies[0].hp), 30.0, 0.001)
	assert_eq(dealt, 0)


func test_reimu_hurts_enemies_inside_her_barrier() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"deploy": 0.0,
				"speed": 0.0,
				"barrier": true,
				"starting_spirit": 50,
				"interval": 0.2,
				"hp": 1000,
			}
		)
	)
	assert_true(sim.place("chr_reimu", 1, 1, "left"))
	Fixture.tick(sim, ONE_SECOND)
	assert_eq(sim.view_state().enemies.size(), 1)
	assert_lt(float(sim.view_state().enemies[0].hp), 1000.0)


func test_barrier_is_two_ahead_and_one_to_each_side_on_ground_only() -> void:
	var sim := Fixture.mini_sim({"starting_spirit": 50, "barrier": true})
	assert_true(sim.place("chr_reimu", 1, 5, "left"))
	var cells: Array = sim.view_state().units[0].barrier_cells
	assert_eq(cells.size(), 3)
	for cell in [[0, 4], [0, 5], [0, 6]]:
		assert_true(cells.has(cell), str(cell))
	var cells_up := BattleFacing.area(1, 5, BattleFacing.UP, 2, 1)
	assert_eq(cells_up.size(), 6)
	assert_true(cells_up.has(Vector2i(1, 3)))
	assert_true(cells_up.has(Vector2i(0, 4)))
	assert_true(cells_up.has(Vector2i(2, 4)))


func test_boss_leak_costs_two_lives() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"lives": 10,
				"speed": 30.0,
				"timeline":
				[
					{
						"at_sec": 0.5,
						"enemy_id": "enm_shade_basic",
						"path_id": "path.main",
						"boss": true
					}
				],
			}
		)
	)
	var state := Fixture.run(sim, 600)
	assert_eq(state.guard_hp, 8)
	assert_eq(state.outcome, BattleSim.PHASE_VICTORY)


func test_ordinary_leak_costs_one_life() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"lives": 10,
				"speed": 30.0,
				"timeline":
				[{"at_sec": 0.5, "enemy_id": "enm_shade_basic", "path_id": "path.main"}],
			}
		)
	)
	assert_eq(Fixture.run(sim, 600).guard_hp, 9)


func test_timeline_spawns_at_absolute_seconds_without_a_call_button() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"speed": 0.0,
				"timeline":
				[
					{"at_sec": 3.0, "enemy_id": "enm_shade_basic", "path_id": "path.main"},
					{"at_sec": 1.0, "enemy_id": "enm_shade_basic", "path_id": "path.main"},
				],
			}
		)
	)
	var state := sim.view_state()
	assert_true(bool(state.timeline))
	assert_eq(state.phase, BattleSim.PHASE_SPAWNING)
	assert_false(bool(state.call_allowed))
	assert_false(sim.call_next_wave())
	assert_almost_eq(Fixture.seconds_until_enemies(sim, 1), 1.0, 0.02)
	assert_almost_eq(Fixture.seconds_until_enemies(sim, 2), 2.0, 0.02)
	assert_eq(sim.view_state().phase, BattleSim.PHASE_FINAL)


func test_timeline_level_is_lost_when_lives_reach_zero() -> void:
	var sim := (
		Fixture
		. mini_sim(
			{
				"lives": 1,
				"speed": 30.0,
				"timeline":
				[
					{"at_sec": 0.5, "enemy_id": "enm_shade_basic", "path_id": "path.main"},
					{"at_sec": 5.0, "enemy_id": "enm_shade_basic", "path_id": "path.main"},
				],
			}
		)
	)
	var state := Fixture.run(sim, 6000)
	assert_eq(state.outcome, BattleSim.PHASE_DEFEAT)
	assert_eq(state.guard_hp, 0)
