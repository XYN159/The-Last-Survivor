class_name BattleTimeline
extends RefCounted

## 按绝对秒数出怪的时间轴。关卡写了非空的 timeline 数组时使用，旧的 waves 不再读取。
## 每一项写 at_sec（从开打算起的秒数）、enemy_id、path_id；boss 为 true 时漏过按 Boss 扣命。
## 时钟从第一次 tick 开始走，没有布阵倒计时，也没有叫波。

var _entries: Array[Dictionary] = []
var _next: int = 0
var _clock: float = 0.0


## 关卡没有 timeline，或者里面一项能用的都没有，就返回 null，模拟器照旧走波次。
static func from_level(level: Dictionary) -> BattleTimeline:
	var raw: Variant = level.get("timeline", [])
	if typeof(raw) != TYPE_ARRAY:
		return null
	var timeline := BattleTimeline.new()
	for item_v in raw:
		if typeof(item_v) != TYPE_DICTIONARY:
			continue
		var item: Dictionary = item_v
		(
			timeline
			. _entries
			. append(
				{
					"at": maxf(CombatCatalog.read_float(item.get("at_sec"), 0.0), 0.0),
					"enemy_id": str(item.get("enemy_id", "")),
					"path_id": str(item.get("path_id", "")),
					"boss": bool(item.get("boss", false)),
				}
			)
		)
	if timeline._entries.is_empty():
		return null
	timeline._entries.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a.at < b.at)
	return timeline


## 时钟往前走 dt 秒，返回这一步到点的条目。
func advance(dt: float) -> Array[Dictionary]:
	_clock += dt
	var due: Array[Dictionary] = []
	while _next < _entries.size() and float(_entries[_next].at) <= _clock + 0.000001:
		due.append(_entries[_next])
		_next += 1
	return due


func clock() -> float:
	return _clock


func spawned() -> int:
	return _next


func total() -> int:
	return _entries.size()


func finished() -> bool:
	return _next >= _entries.size()


func time_to_next() -> float:
	if finished():
		return 0.0
	return maxf(float(_entries[_next].at) - _clock, 0.0)


## 上一只到下一只的间隔，给画面算倒计时条。第一只从 0 秒算起。
func gap_to_next() -> float:
	if finished():
		return 0.0
	var previous := 0.0 if _next == 0 else float(_entries[_next - 1].at)
	return maxf(float(_entries[_next].at) - previous, 0.0)
