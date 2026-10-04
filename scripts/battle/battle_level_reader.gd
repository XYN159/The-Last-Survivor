class_name BattleLevelReader
extends RefCounted

## 从关卡字典里读地图和波次的纯函数。模拟器只管结算，读表的细节放在这里。


## 路线 id → 每一格中心点（逻辑坐标，格子中心是 +0.5）。少于两格的路线不收。
static func paths(level: Dictionary) -> Dictionary:
	var result := {}
	var map: Dictionary = level.get("map", {})
	for path_v in map.get("paths", []):
		if typeof(path_v) != TYPE_DICTIONARY:
			continue
		var path: Dictionary = path_v
		var centers: Array = []
		for point_v in path.get("cells", []):
			if typeof(point_v) != TYPE_ARRAY or (point_v as Array).size() < 2:
				continue
			var point: Array = point_v
			centers.append(Vector2(float(point[0]) + 0.5, float(point[1]) + 0.5))
		var path_id := str(path.get("path_id", ""))
		if path_id != "" and centers.size() >= 2:
			result[path_id] = centers
	return result


static func cell_mark(level: Dictionary, col: int, row: int) -> String:
	var map: Dictionary = level.get("map", {})
	var cells: Array = map.get("cells", [])
	if row < 0 or row >= cells.size():
		return ""
	var line := str(cells[row])
	if col < 0 or col >= line.length():
		return ""
	return line.substr(col, 1)


static func wave_at(waves: Array, index: int) -> Dictionary:
	if index < 0 or index >= waves.size():
		return {}
	var wave_v: Variant = waves[index]
	if typeof(wave_v) != TYPE_DICTIONARY:
		return {}
	return wave_v


static func wave_duration(wave: Dictionary, fallback: float) -> float:
	if wave.has("duration_sec"):
		return maxf(CombatCatalog.read_float(wave.get("duration_sec"), 0.0), 0.0)
	return fallback


## 第 index 波开始前的空档。先认这一波的 delay_sec，再认上一波的 next_wave_delay_sec；
## 第 1 波没写就是 0，其他波没写用规则里的 intermission。
static func lead_in(waves: Array, index: int, intermission: float) -> float:
	if index < 0 or index >= waves.size():
		return intermission
	var wave := wave_at(waves, index)
	if wave.has("delay_sec"):
		return maxf(CombatCatalog.read_float(wave.get("delay_sec"), 0.0), 0.0)
	if index > 0:
		var previous := wave_at(waves, index - 1)
		if previous.has("next_wave_delay_sec"):
			return maxf(CombatCatalog.read_float(previous.get("next_wave_delay_sec"), 0.0), 0.0)
	if index == 0:
		return 0.0
	return intermission
