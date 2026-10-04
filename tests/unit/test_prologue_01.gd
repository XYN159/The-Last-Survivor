extends GutTest

## 「开始」进的序章第一关 prologue_01。
## 依据：data/levels/prologue_01.json（#5 关卡策划），
## 以及 docs/production/PRODUCER_DECISIONS.md 和 data/balance/stage1_rules.json。

const LEVEL_ID := "prologue_01"
const TIMELINE_SECONDS: Array[float] = [8.0, 14.0, 20.0, 28.0, 36.0, 46.0]
const ONE_SECOND := 60


func test_start_loads_prologue_01_from_data_levels() -> void:
	assert_eq(CombatCatalog.DEFAULT_LEVEL_ID, LEVEL_ID)
	assert_true(FileAccess.file_exists(CombatCatalog.level_path(LEVEL_ID)))
	var level := CombatCatalog.load_default().level()
	assert_eq(level.id, LEVEL_ID)
	assert_eq(level.display_name, "神社的直路")
	assert_eq(level.map.cells.size(), 12)
	assert_eq(str(level.map.cells[0]).length(), 7)


func test_spirit_and_lives_follow_the_producer_decisions() -> void:
	var catalog := CombatCatalog.load_default()
	assert_eq(int(catalog.level().params.starting_spirit_power), 10)
	assert_eq(int(catalog.level().params.lives), 10)
	var state := BattleSim.from_catalog(catalog).view_state()
	assert_eq(state.spirit, 10)
	assert_eq(state.guard_hp, 10)
	assert_eq(state.guard_max_hp, 10)


func test_timeline_lists_six_small_shades() -> void:
	var timeline: Array = CombatCatalog.load_default().level().timeline
	assert_eq(timeline.size(), 6)
	for index in timeline.size():
		var entry: Dictionary = timeline[index]
		assert_almost_eq(float(entry.at_sec), TIMELINE_SECONDS[index], 0.001)
		assert_eq(entry.enemy_id, "enm_shade_basic")
		assert_eq(entry.path_id, "path.main")


func test_route_runs_from_the_crack_to_the_guard() -> void:
	var level := CombatCatalog.load_default().level()
	var cells: Array = level.map.cells
	assert_eq(level.map.paths.size(), 1)
	var points: Array = level.map.paths[0].cells
	assert_eq(_mark(cells, points[0]), "S")
	assert_eq(_mark(cells, points[points.size() - 1]), "G")
	for index in range(1, points.size() - 1):
		assert_eq(_mark(cells, points[index]), "P")


func test_shades_enter_at_the_timeline_seconds() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	var seen := {}
	var spawn_seconds: Array[float] = []
	var ticks := 0
	while ticks < 60 * ONE_SECOND and spawn_seconds.size() < TIMELINE_SECONDS.size():
		sim.tick()
		ticks += 1
		for enemy_v in sim.view_state().enemies:
			if not seen.has(int(enemy_v.id)):
				seen[int(enemy_v.id)] = true
				spawn_seconds.append(float(ticks) / 60.0)
	assert_eq(spawn_seconds.size(), TIMELINE_SECONDS.size())
	for index in spawn_seconds.size():
		assert_almost_eq(spawn_seconds[index], TIMELINE_SECONDS[index], 0.02)


func test_timeline_level_has_no_deploy_phase_or_call_button() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	var state := sim.view_state()
	assert_true(bool(state.timeline))
	assert_ne(state.phase, BattleSim.PHASE_DEPLOY)
	assert_false(bool(state.call_allowed))
	assert_false(sim.call_next_wave())
	assert_eq(int(state.spawn_total), 6)


func test_spirit_regenerates_until_reimu_is_affordable() -> void:
	var sim := BattleSim.from_catalog(CombatCatalog.load_default())
	assert_false(sim.can_place("chr_reimu", 2, 4))
	_tick(sim, 6 * ONE_SECOND - 1)
	assert_eq(sim.view_state().spirit, 15)
	assert_false(sim.can_place("chr_reimu", 2, 4))
	_tick(sim, 1)
	assert_eq(sim.view_state().spirit, 16)
	assert_true(sim.place("chr_reimu", 2, 4, BattleFacing.RIGHT))
	assert_eq(sim.view_state().spirit, 0)


func test_only_reimu_can_be_placed() -> void:
	var catalog := CombatCatalog.load_default()
	var level := catalog.level()
	assert_eq(level.params.available_character_ids, ["chr_reimu"])
	assert_true((level.unlock_character_ids as Array).has("chr_marisa"))
	var sim := _funded_sim(catalog)
	var roster: Array = sim.view_state().roster
	assert_eq(roster.size(), 1)
	assert_eq(roster[0].id, "chr_reimu")
	assert_false(sim.place("chr_marisa", 2, 4, BattleFacing.RIGHT))
	assert_true(sim.place("chr_reimu", 2, 4, BattleFacing.RIGHT))


func test_only_dot_cells_take_a_character() -> void:
	var sim := _funded_sim(CombatCatalog.load_default())
	assert_false(sim.place("chr_reimu", 3, 4, BattleFacing.LEFT))
	assert_false(sim.place("chr_reimu", 0, 0, BattleFacing.LEFT))
	assert_false(sim.place("chr_reimu", 3, 0, BattleFacing.LEFT))
	assert_false(sim.place("chr_reimu", 3, 11, BattleFacing.LEFT))
	assert_true(sim.place("chr_reimu", 4, 4, BattleFacing.LEFT))
	assert_false(sim.place("chr_reimu", 4, 4, BattleFacing.LEFT))


func test_slot_facings_cover_the_road() -> void:
	var catalog := CombatCatalog.load_default()
	for slot_v in catalog.level().map.slots:
		var slot: Dictionary = slot_v
		var col := int(slot.col)
		var row := int(slot.row)
		assert_eq(str(slot.facing), BattleFacing.RIGHT if col == 2 else BattleFacing.LEFT)
		var sim := _funded_sim(catalog)
		assert_true(sim.place("chr_reimu", col, row, str(slot.facing)))
		var cells: Array = sim.view_state().units[0].barrier_cells
		assert_eq(cells.size(), 3, str(slot.id))
		for offset in [-1, 0, 1]:
			if row + offset < 0:
				continue
			assert_true(cells.has([3, row + offset]), "%s 盖住第 %d 行" % [slot.id, row + offset])


func test_facing_away_from_the_road_covers_nothing() -> void:
	var sim := _funded_sim(CombatCatalog.load_default())
	assert_true(sim.place("chr_reimu", 2, 4, BattleFacing.LEFT))
	assert_eq(sim.view_state().units[0].barrier_cells.size(), 0)


func test_holding_with_reimu_wins_with_every_life() -> void:
	var catalog := CombatCatalog.load_default()
	var sim := BattleSim.from_catalog(catalog)
	sim.set_seed(1)
	for opening_v in catalog.scripted_opening():
		var opening: Dictionary = opening_v
		while not sim.can_place(str(opening.character_id), int(opening.col), int(opening.row)):
			sim.tick()
		assert_true(
			sim.place(
				str(opening.character_id), int(opening.col), int(opening.row), str(opening.facing)
			)
		)
	var won := _run(sim)
	assert_eq(won.outcome, BattleSim.PHASE_VICTORY)
	assert_eq(int(won.guard_hp), 10)


## 生命 10、6 只普通残影各扣 1：什么都不放也还剩 4 条命，按规则算守住。
func test_doing_nothing_leaks_all_six_shades() -> void:
	var idle := BattleSim.from_catalog(CombatCatalog.load_default())
	var state := _run(idle)
	assert_eq(state.outcome, BattleSim.PHASE_VICTORY)
	assert_eq(int(state.guard_hp), 10 - 6)
	assert_eq(int(state.spawned), 6)
	assert_eq(state.enemies.size(), 0)


func test_old_waves_stay_in_the_file_but_are_not_read() -> void:
	var catalog := CombatCatalog.load_default()
	assert_eq(catalog.level().waves.size(), 3)
	assert_eq(int(BattleSim.from_catalog(catalog).view_state().wave_count), 0)


## 先等 6 秒，灵力从 10 回到 16，刚好够放一个灵梦。
func _funded_sim(catalog: CombatCatalog) -> BattleSim:
	var sim := BattleSim.from_catalog(catalog)
	_tick(sim, 6 * ONE_SECOND)
	return sim


func _tick(sim: BattleSim, count: int) -> void:
	for _step in count:
		sim.tick()


func _run(sim: BattleSim) -> Dictionary:
	var ticks := 0
	while ticks < 300000 and str(sim.view_state().outcome) == "":
		sim.tick()
		ticks += 1
	return sim.view_state()


func _mark(cells: Array, point: Array) -> String:
	var line := str(cells[int(point[1])])
	return line.substr(int(point[0]), 1)
