extends SceneTree

## 无头跑完「开始」进的那一关。摆放见 CombatCatalog.scripted_opening，一直 tick 到胜负。


func _init() -> void:
	var catalog := CombatCatalog.load_default()
	var sim := BattleSim.from_catalog(catalog)
	sim.set_seed(1)
	for opening_v in catalog.scripted_opening():
		_try_place(sim, opening_v)
	var ticks := 0
	while str(sim.view_state().outcome) == "" and ticks < 300000:
		sim.tick()
		ticks += 1
	var state := sim.view_state()
	print(
		(
			"结果 %s，逻辑 %.1f 秒，生命 %d，灵力 %d"
			% [state.outcome, float(ticks) / 60.0, int(state.guard_hp), int(state.spirit)]
		)
	)
	quit(0 if str(state.outcome) == "victory" else 1)


func _try_place(sim: BattleSim, opening_v: Variant) -> void:
	if typeof(opening_v) != TYPE_DICTIONARY:
		return
	var opening: Dictionary = opening_v
	var character_id := str(opening.get("character_id", ""))
	var placed := sim.place(character_id, int(opening.get("col", -1)), int(opening.get("row", -1)))
	print("放置 %s -> %s" % [character_id, placed])
