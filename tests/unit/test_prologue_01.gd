extends GutTest

## 「开始」进的序章第一关 prologue_01。
## 依据：data/levels/prologue_01.json（#5 cursor/design-level-framework-01a3@822ae26）。

const LEVEL_ID := "prologue_01"


func test_start_loads_prologue_01_from_data_levels() -> void:
	assert_eq(CombatCatalog.DEFAULT_LEVEL_ID, LEVEL_ID)
	assert_true(FileAccess.file_exists(CombatCatalog.level_path(LEVEL_ID)))
	var level := CombatCatalog.load_default().level()
	assert_eq(level.id, LEVEL_ID)
	assert_eq(level.display_name, "神社的直路")
	assert_eq(level.map.cells.size(), 12)
	assert_eq(str(level.map.cells[0]).length(), 7)
	assert_eq(level.waves.size(), 3)


func test_route_runs_from_the_crack_to_the_guard() -> void:
	var level := CombatCatalog.load_default().level()
	var cells: Array = level.map.cells
	assert_eq(level.map.paths.size(), 1)
	var points: Array = level.map.paths[0].cells
	assert_eq(_mark(cells, points[0]), "S")
	assert_eq(_mark(cells, points[points.size() - 1]), "G")
	for index in range(1, points.size() - 1):
		assert_eq(_mark(cells, points[index]), "P")


func test_first_wave_delay_follows_the_file() -> void:
	var catalog := CombatCatalog.load_default()
	var delay := float(catalog.level().waves[0].delay_sec)
	var deploy := float(catalog.tuning().deploy_time_sec)
	var sim := BattleSim.from_catalog(catalog)
	assert_true(sim.place("chr_reimu", 2, 4))
	assert_almost_eq(_seconds_until_first_enemy(sim), deploy + delay, 0.05)


func test_start_button_still_waits_the_first_wave_delay() -> void:
	var catalog := CombatCatalog.load_default()
	catalog.level().waves[0].delay_sec = 1.5
	var sim := BattleSim.from_catalog(catalog)
	assert_true(sim.call_next_wave())
	assert_almost_eq(_seconds_until_first_enemy(sim), 1.5, 0.05)


func test_spawn_window_then_a_fixed_gap_before_wave_two() -> void:
	var catalog := CombatCatalog.load_default()
	var waves: Array = catalog.level().waves
	var window := float(waves[0].duration_sec)
	var gap := float(waves[1].delay_sec)
	var sim := BattleSim.from_catalog(catalog)
	assert_true(sim.call_next_wave())
	var ticks := 0
	while ticks < 6000 and int(sim.view_state().wave_index) < 1:
		sim.tick()
		ticks += 1
	assert_almost_eq(float(ticks) / 60.0, window + gap, 0.05)


func test_only_reimu_can_be_placed() -> void:
	var catalog := CombatCatalog.load_default()
	var level := catalog.level()
	assert_eq(level.params.available_character_ids, ["chr_reimu"])
	assert_true((level.unlock_character_ids as Array).has("chr_marisa"))
	var sim := BattleSim.from_catalog(catalog)
	var roster: Array = sim.view_state().roster
	assert_eq(roster.size(), 1)
	assert_eq(roster[0].id, "chr_reimu")
	assert_false(sim.place("chr_marisa", 2, 4))
	assert_true(sim.place("chr_reimu", 2, 4))


func test_only_dot_cells_take_a_character() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	assert_false(sim.place("chr_reimu", 3, 4))
	assert_false(sim.place("chr_reimu", 0, 0))
	assert_false(sim.place("chr_reimu", 3, 0))
	assert_false(sim.place("chr_reimu", 3, 11))
	assert_true(sim.place("chr_reimu", 4, 4))
	assert_false(sim.place("chr_reimu", 4, 4))


func test_deploy_countdown_waits_for_the_first_character() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	for _step in 600:
		sim.tick()
	assert_eq(sim.view_state().phase, BattleSim.PHASE_DEPLOY)
	assert_almost_eq(float(sim.view_state().phase_time_left), 10.0, 0.001)
	assert_true(sim.place("chr_reimu", 2, 4))
	for _step in 60:
		sim.tick()
	assert_almost_eq(float(sim.view_state().phase_time_left), 9.0, 0.05)


func test_holding_with_reimu_wins_and_doing_nothing_loses() -> void:
	var catalog := CombatCatalog.load_default()
	var sim := BattleSim.from_catalog(catalog)
	sim.set_seed(1)
	for opening_v in catalog.scripted_opening():
		var opening: Dictionary = opening_v
		sim.place(str(opening.character_id), int(opening.col), int(opening.row))
	assert_gt(sim.view_state().units.size(), 0)
	var won := _run(sim)
	assert_eq(won.outcome, BattleSim.PHASE_VICTORY)
	assert_gt(int(won.guard_hp), 0)
	var idle := BattleSim.from_catalog(catalog)
	idle.call_next_wave()
	var lost := _run(idle)
	assert_eq(lost.outcome, BattleSim.PHASE_DEFEAT)
	assert_eq(int(lost.guard_hp), 0)


func _seconds_until_first_enemy(sim: BattleSim) -> float:
	var ticks := 0
	while ticks < 6000 and sim.view_state().enemies.is_empty():
		sim.tick()
		ticks += 1
	return float(ticks) / 60.0


func _run(sim: BattleSim) -> Dictionary:
	var ticks := 0
	while ticks < 300000 and str(sim.view_state().outcome) == "":
		sim.tick()
		ticks += 1
	return sim.view_state()


func _mark(cells: Array, point: Array) -> String:
	var line := str(cells[int(point[1])])
	return line.substr(int(point[0]), 1)
