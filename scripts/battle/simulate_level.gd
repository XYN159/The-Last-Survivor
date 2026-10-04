extends SceneTree

## 无头跑完「开始」进的那一关。摆放见 CombatCatalog.scripted_opening（每一项都带朝向），
## 灵力不够时先 tick 等回灵，够了再放。放完一直 tick 到胜负。

const WAIT_LIMIT_TICKS := 6000


func _init() -> void:
	var catalog := CombatCatalog.load_default()
	var sim := BattleSim.from_catalog(catalog)
	sim.set_seed(1)
	var ticks := 0
	for opening_v in catalog.scripted_opening():
		ticks += _try_place(sim, opening_v)
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


## 返回等灵力用掉的 tick 数。
func _try_place(sim: BattleSim, opening_v: Variant) -> int:
	if typeof(opening_v) != TYPE_DICTIONARY:
		return 0
	var opening: Dictionary = opening_v
	var character_id := str(opening.get("character_id", ""))
	var col := int(opening.get("col", -1))
	var row := int(opening.get("row", -1))
	var facing := str(opening.get("facing", ""))
	var waited := 0
	while not sim.can_place(character_id, col, row) and waited < WAIT_LIMIT_TICKS:
		if str(sim.view_state().outcome) != "":
			break
		sim.tick()
		waited += 1
	var placed := sim.place(character_id, col, row, facing)
	print("第 %.1f 秒放置 %s 朝 %s -> %s" % [float(waited) / 60.0, character_id, facing, placed])
	return waited
