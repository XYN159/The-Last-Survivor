class_name BattleSim
extends RefCounted

## 一局塔防的规则。不画画面。每调用一次 tick，逻辑时间前进 1/60 秒。
## 放置、升级、出售和叫波在点击时立刻结算。移动、攻击和胜负只在 tick 里发生。
## 第一波的 delay_sec 不另加：10 秒布阵结束就出怪。波间用 next_wave_delay_sec。

const PHASE_DEPLOY := "deploy"
const PHASE_SPAWNING := "spawning"
const PHASE_WAITING := "waiting"
const PHASE_INTERMISSION := "intermission"
const PHASE_FINAL := "final"
const PHASE_VICTORY := "victory"
const PHASE_DEFEAT := "defeat"

var _catalog: CombatCatalog
var _level: Dictionary = {}
var _waves: Array = []
var _paths: Dictionary = {}
var _rng := RandomNumberGenerator.new()
var _units: Array[BattleUnit] = []
var _enemies: Array[BattleEnemy] = []
var _shots: Array[BattleShot] = []
var _jobs: Array = []
var _hits: Array = []
var _events: Array = []
var _unknown_attacks: Dictionary = {}
var _dt: float = 1.0 / 60.0
var _armor_floor: float = 0.2
var _min_damage: int = 1
var _spirit: int = 0
var _spirit_per_wave: int = 0
var _early_call_rate: float = 2.0
var _early_start_rate: float = 1.0
var _max_copies: int = 3
var _max_level: int = 3
var _spawn_state: float = 0.3
var _knockback_cooldown: float = 0.25
var _guard_hp: int = 20
var _guard_max_hp: int = 20
var _intermission_sec: float = 4.0
var _phase: String = PHASE_DEPLOY
var _phase_time: float = 10.0
var _wave_index: int = -1
var _id_serial: int = 1
var _pending_wave_bonus: bool = false


static func from_catalog(catalog: CombatCatalog) -> BattleSim:
	var sim := BattleSim.new()
	sim._configure(catalog)
	return sim


func set_seed(seed_value: int) -> void:
	_rng.seed = seed_value


func tick() -> Array:
	if _phase == PHASE_VICTORY or _phase == PHASE_DEFEAT:
		return []
	_events = []
	_hits = []
	_advance_clock(_dt)
	_advance_spawns(_dt)
	_tick_status(_dt)
	_move_enemies(_dt)
	_attack(_dt)
	_move_shots(_dt)
	_resolve_hits()
	_apply_leaks()
	_erase_dead()
	_apply_outcome()
	_apply_wave_bonus()
	_apply_intermission()
	_clear_born()
	return _events


func place(character_id: String, col: int, row: int) -> bool:
	if _terminal() or not _character_allowed(character_id):
		return false
	if _cell_mark(col, row) != "." or _unit_on(col, row) != null:
		return false
	if _copy_count(character_id) >= _max_copies:
		return false
	var data := _catalog.character(character_id)
	if data.is_empty():
		return false
	var cost := _next_cost(character_id)
	if _spirit < cost:
		return false
	var stats: Dictionary = data.get("stats", {})
	var unit := BattleUnit.new()
	unit.instance_id = _next_id()
	unit.character_id = character_id
	unit.display_name = str(data.get("display_name", character_id))
	unit.col = col
	unit.row = row
	unit.level = 1
	unit.spent = cost
	unit.base_attack = float(stats.get("base_attack", 0))
	unit.level_attack_mult = stats.get("level_attack_mult", [1.0])
	unit.crit_chance = float(stats.get("crit_chance", 0))
	unit.crit_mult = float(stats.get("crit_mult", 1))
	unit.refund_ratio = float(stats.get("sell_refund_ratio", 0.7))
	unit.upgrade_costs = stats.get("upgrade_costs", [])
	_set_base_attack(unit, data)
	unit.cooldown = float(unit.attack.get("initial_delay_sec", 0.3))
	_units.append(unit)
	_spirit -= cost
	return true


func upgrade(unit_id: int) -> bool:
	var unit := _find_unit(unit_id)
	if unit == null or _terminal():
		return false
	var cost := _upgrade_cost(unit)
	if cost < 0 or _spirit < cost:
		return false
	_spirit -= cost
	unit.spent += cost
	unit.level += 1
	_rebuild_attack(unit)
	return true


func sell(unit_id: int) -> bool:
	var unit := _find_unit(unit_id)
	if unit == null or _terminal():
		return false
	_spirit += _sell_value(unit)
	_units.erase(unit)
	return true


func call_next_wave() -> bool:
	if _phase == PHASE_DEPLOY:
		return _start_early(0, _early_start_rate)
	if _phase == PHASE_WAITING or _phase == PHASE_INTERMISSION:
		return _start_early(_wave_index + 1, _early_call_rate)
	return false


func view_state() -> Dictionary:
	return {
		"spirit": _spirit,
		"guard_hp": _guard_hp,
		"guard_max_hp": _guard_max_hp,
		"phase": _phase,
		"phase_time_left": maxf(_phase_time, 0.0),
		"wave_index": _wave_index,
		"wave_count": _waves.size(),
		"outcome": _outcome(),
		"level_name": str(_level.get("display_name", "")),
		"roster": _roster(),
		"units": _unit_snapshots(),
		"enemies": _enemy_snapshots(),
		"projectiles": _shot_snapshots(),
		"call_allowed": _call_allowed(),
		"call_reward": _call_reward_now(),
	}


func _configure(catalog: CombatCatalog) -> void:
	_catalog = catalog
	_level = catalog.level()
	var tune := catalog.tuning()
	_dt = 1.0 / float(tune.logic_hz)
	_armor_floor = float(tune.armor_floor_ratio)
	_min_damage = int(tune.min_damage)
	_spirit = int(tune.starting_spirit)
	_spirit_per_wave = int(tune.spirit_per_wave)
	_early_call_rate = float(tune.early_call_reward_per_sec)
	_early_start_rate = float(tune.early_start_reward_per_sec)
	_max_copies = int(tune.max_copies)
	_max_level = int(tune.max_level)
	_spawn_state = float(tune.spawn_state_sec)
	_knockback_cooldown = float(tune.knockback_cooldown_sec)
	_guard_max_hp = int(tune.guard_max_hp)
	_guard_hp = _guard_max_hp
	_intermission_sec = float(tune.intermission_sec)
	_phase = PHASE_DEPLOY
	_phase_time = float(tune.deploy_time_sec)
	_wave_index = -1
	_waves = _level.get("waves", [])
	_read_paths()
	_rng.seed = 1


func _advance_clock(dt: float) -> void:
	var timed := _phase == PHASE_DEPLOY or _phase == PHASE_WAITING or _phase == PHASE_INTERMISSION
	if not timed:
		return
	_phase_time = maxf(0.0, _phase_time - dt)
	if _phase == PHASE_WAITING and _living_count() == 0:
		_phase = PHASE_INTERMISSION
		_phase_time = minf(_phase_time, _intermission_sec)
	if _phase_time > 0.0:
		return
	if _phase == PHASE_DEPLOY:
		_begin_wave(0)
		return
	_begin_wave(_wave_index + 1)


func _advance_spawns(dt: float) -> void:
	if _phase != PHASE_SPAWNING:
		return
	for job_v in _jobs:
		_spawn_job(job_v, dt)
	if not _jobs_done():
		return
	_pending_wave_bonus = true
	_jobs.clear()
	if _wave_index >= _waves.size() - 1:
		_phase = PHASE_FINAL
		_phase_time = 0.0
		return
	_phase = PHASE_WAITING
	_phase_time = _next_gap(_wave_index)


func _spawn_job(job_v: Variant, dt: float) -> void:
	if typeof(job_v) != TYPE_DICTIONARY:
		return
	var job: Dictionary = job_v
	while int(job.left) > 0 and float(job.wait) <= 0.0:
		_spawn_enemy(str(job.enemy_id), str(job.path_id))
		job.left = int(job.left) - 1
		job.wait = float(job.wait) + float(job.interval)
	if int(job.left) > 0:
		job.wait = float(job.wait) - dt


func _tick_status(dt: float) -> void:
	for enemy in _enemies:
		enemy.spawn_left = maxf(0.0, enemy.spawn_left - dt)
		enemy.knockback_cd = maxf(0.0, enemy.knockback_cd - dt)


func _move_enemies(dt: float) -> void:
	for enemy in _enemies:
		if enemy.dead or enemy.born or enemy.spawn_left > 0.0 or enemy.reaching:
			continue
		enemy.progress += enemy.speed * dt
		if enemy.progress < enemy.path_length:
			continue
		enemy.progress = enemy.path_length
		enemy.reaching = true


func _attack(dt: float) -> void:
	for unit in _units:
		if unit.cooldown > 0.0:
			unit.cooldown = maxf(0.0, unit.cooldown - dt)
		if unit.cooldown > 0.0:
			continue
		var target := _pick_target(unit)
		if target == null:
			continue
		_fire(unit, target)
		unit.cooldown = maxf(float(unit.attack.get("interval_sec", 1.0)), 0.05)


func _move_shots(dt: float) -> void:
	var kept: Array[BattleShot] = []
	for shot in _shots:
		if _step_shot(shot, dt):
			kept.append(shot)
	_shots = kept


func _step_shot(shot: BattleShot, dt: float) -> bool:
	shot.life -= dt
	if shot.life <= 0.0:
		return false
	var target := _live_target(shot.target_id)
	if target == null:
		target = _retarget(shot)
		shot.target_id = -1 if target == null else target.instance_id
	if target != null:
		_steer(shot, _enemy_xy(target), dt)
	var pos := Vector2(shot.x, shot.y) + shot.direction * shot.speed * dt
	shot.x = pos.x
	shot.y = pos.y
	if target == null:
		return true
	var reach := shot.hit_radius + target.hit_radius
	if pos.distance_to(_enemy_xy(target)) > reach:
		return true
	_queue_hit(target, shot.attack_power, shot.knockback, shot.heavy)
	return false


func _resolve_hits() -> void:
	for hit_v in _hits:
		if typeof(hit_v) != TYPE_DICTIONARY:
			continue
		var hit: Dictionary = hit_v
		var enemy: BattleEnemy = hit.enemy
		if enemy.dead:
			continue
		var damage := DamageMath.resolve(float(hit.power), enemy.armor, _armor_floor, _min_damage)
		var pos := _enemy_xy(enemy)
		enemy.hp -= float(damage)
		(
			_events
			. append(
				{
					"type": "damage",
					"x": pos.x,
					"y": pos.y,
					"amount": damage,
					"heavy": bool(hit.heavy),
					"id": enemy.instance_id,
				}
			)
		)
		if enemy.hp > 0.0:
			_apply_knockback(enemy, float(hit.knockback))
			continue
		enemy.hp = 0.0
		enemy.dead = true
		_spirit += enemy.spirit_drop
		(
			_events
			. append(
				{
					"type": "death",
					"x": pos.x,
					"y": pos.y,
					"spirit": enemy.spirit_drop,
					"id": enemy.instance_id,
				}
			)
		)


func _apply_leaks() -> void:
	for enemy in _enemies:
		if enemy.dead or not enemy.reaching:
			continue
		enemy.dead = true
		_guard_hp -= enemy.leak_damage
		var pos := _enemy_xy(enemy)
		_events.append({"type": "leak", "amount": enemy.leak_damage, "x": pos.x, "y": pos.y})


func _erase_dead() -> void:
	var kept: Array[BattleEnemy] = []
	for enemy in _enemies:
		if not enemy.dead:
			kept.append(enemy)
	_enemies = kept


func _apply_outcome() -> void:
	if _guard_hp <= 0:
		_guard_hp = 0
		_phase = PHASE_DEFEAT
		_events.append({"type": "defeat"})
		return
	if _phase != PHASE_FINAL or _living_count() > 0:
		return
	_phase = PHASE_VICTORY
	_events.append({"type": "victory"})


func _apply_wave_bonus() -> void:
	if not _pending_wave_bonus:
		return
	_pending_wave_bonus = false
	if _guard_hp <= 0 or _spirit_per_wave <= 0:
		return
	_spirit += _spirit_per_wave
	_events.append({"type": "spirit", "amount": _spirit_per_wave})


func _apply_intermission() -> void:
	if _phase != PHASE_WAITING or _living_count() != 0:
		return
	_phase = PHASE_INTERMISSION
	_phase_time = minf(_phase_time, _intermission_sec)


func _clear_born() -> void:
	for enemy in _enemies:
		enemy.born = false


func _begin_wave(index: int) -> void:
	if index < 0 or index >= _waves.size():
		return
	_wave_index = index
	_phase = PHASE_SPAWNING
	_jobs.clear()
	var wave_v: Variant = _waves[index]
	if typeof(wave_v) != TYPE_DICTIONARY:
		return
	for group_v in (wave_v as Dictionary).get("spawns", []):
		_add_job(group_v)


func _add_job(group_v: Variant) -> void:
	if typeof(group_v) != TYPE_DICTIONARY:
		return
	var group: Dictionary = group_v
	(
		_jobs
		. append(
			{
				"enemy_id": str(group.get("enemy_id", "")),
				"path_id": str(group.get("path_id", "")),
				"left": CombatCatalog.read_int(group.get("count", 0), 0),
				"interval": maxf(float(group.get("interval_sec", 1.0)), 0.01),
				"wait": maxf(float(group.get("delay_sec", 0.0)), 0.0),
			}
		)
	)


func _start_early(index: int, rate: float) -> bool:
	if index < 0 or index >= _waves.size():
		return false
	var reward := floori(maxf(_phase_time, 0.0) * rate)
	_spirit += reward
	_begin_wave(index)
	return true


func _fire(unit: BattleUnit, primary: BattleEnemy) -> void:
	var kind := str(unit.attack.get("type", ""))
	if kind == "instant_line":
		_fire_line(unit, primary)
		return
	if kind == "homing_projectile":
		_fire_homing(unit, primary)
		return
	if _unknown_attacks.has(kind):
		return
	_unknown_attacks[kind] = true
	push_warning("原型还不会这种攻击：%s" % kind)


func _fire_homing(unit: BattleUnit, primary: BattleEnemy) -> void:
	var count := maxi(CombatCatalog.read_int(unit.attack.get("count", 1), 1), 1)
	var projectile_v: Variant = unit.attack.get("projectile", {})
	var projectile: Dictionary = projectile_v if typeof(projectile_v) == TYPE_DICTIONARY else {}
	var origin := _unit_center(unit)
	var direction := _aim_direction(origin, _enemy_xy(primary))
	for _shot_index in count:
		var rolled := _roll_shot(unit)
		var shot := BattleShot.new()
		shot.instance_id = _next_id()
		shot.character_id = unit.character_id
		shot.target_id = primary.instance_id
		shot.x = origin.x
		shot.y = origin.y
		shot.direction = direction
		shot.speed = float(projectile.get("speed_cells_per_sec", 7.0))
		shot.turn_deg = float(projectile.get("turn_deg_per_sec", 540.0))
		shot.life = float(projectile.get("lifetime_sec", 1.5))
		shot.hit_radius = float(projectile.get("hit_radius_cells", 0.25))
		shot.retarget_radius = float(projectile.get("retarget_radius_cells", 1.5))
		shot.attack_power = float(rolled.power)
		shot.knockback = float(rolled.knockback)
		shot.heavy = bool(rolled.heavy)
		_shots.append(shot)


func _fire_line(unit: BattleUnit, primary: BattleEnemy) -> void:
	var origin := _unit_center(unit)
	var direction := _aim_direction(origin, _enemy_xy(primary))
	var reach := float(unit.attack.get("range_cells", 0.0))
	for enemy in _line_targets(unit, primary, origin, direction, reach):
		var rolled := _roll_shot(unit)
		_queue_hit(enemy, float(rolled.power), float(rolled.knockback), bool(rolled.heavy))
	var tip := origin + direction * reach
	(
		_events
		. append(
			{
				"type": "beam",
				"x0": origin.x,
				"y0": origin.y,
				"x1": tip.x,
				"y1": tip.y,
				"duration": float(unit.attack.get("beam_visual_sec", 0.15)),
			}
		)
	)


func _line_targets(
	unit: BattleUnit, primary: BattleEnemy, origin: Vector2, direction: Vector2, reach: float
) -> Array[BattleEnemy]:
	var half_width := float(unit.attack.get("line_width_cells", 0.5)) * 0.5
	var targets: Array[BattleEnemy] = [primary]
	for enemy in _enemies:
		if enemy == primary or not _targetable(enemy):
			continue
		var rel := _enemy_xy(enemy) - origin
		var along := rel.dot(direction)
		if along < 0.0 or along > reach:
			continue
		var lateral := (rel - direction * along).length()
		if lateral <= half_width + enemy.hit_radius:
			targets.append(enemy)
	var burst := float(unit.attack.get("end_star_burst_radius_cells", 0.0))
	if burst <= 0.0:
		return targets
	var tip := origin + direction * reach
	for enemy in _enemies:
		if not _targetable(enemy) or targets.has(enemy):
			continue
		if _enemy_xy(enemy).distance_to(tip) <= burst + enemy.hit_radius:
			targets.append(enemy)
	return targets


func _roll_shot(unit: BattleUnit) -> Dictionary:
	var mult := 1.0
	var index := unit.level - 1
	if index >= 0 and index < unit.level_attack_mult.size():
		mult = float(unit.level_attack_mult[index])
	var power := unit.base_attack * mult
	var heavy := bool(unit.attack.get("heavy", false))
	var can_crit := bool(unit.attack.get("can_crit", false))
	if can_crit and _rng.randf() < unit.crit_chance:
		power *= unit.crit_mult
		heavy = true
	return {
		"power": power,
		"heavy": heavy,
		"knockback": float(unit.attack.get("knockback_cells", 0.1)),
	}


func _pick_target(unit: BattleUnit) -> BattleEnemy:
	var best: BattleEnemy = null
	var best_remaining := 0.0
	for enemy in _enemies:
		if not _targetable(enemy) or not _in_range(unit, enemy):
			continue
		var remaining: float = enemy.path_length - enemy.progress
		var closer: bool = best == null or remaining < best_remaining - 0.0001
		var tie: bool = best != null and absf(remaining - best_remaining) <= 0.0001
		if closer or (tie and enemy.instance_id < best.instance_id):
			best = enemy
			best_remaining = remaining
	return best


func _retarget(shot: BattleShot) -> BattleEnemy:
	var origin := Vector2(shot.x, shot.y)
	var best: BattleEnemy = null
	var best_dist := shot.retarget_radius
	for enemy in _enemies:
		if not _targetable(enemy):
			continue
		var dist := origin.distance_to(_enemy_xy(enemy))
		if dist > shot.retarget_radius:
			continue
		var closer: bool = best == null or dist < best_dist - 0.0001
		var tie: bool = best != null and absf(dist - best_dist) <= 0.0001
		if closer or (tie and enemy.instance_id < best.instance_id):
			best = enemy
			best_dist = dist
	return best


func _queue_hit(enemy: BattleEnemy, power: float, knockback: float, heavy: bool) -> void:
	_hits.append({"enemy": enemy, "power": power, "knockback": knockback, "heavy": heavy})


func _apply_knockback(enemy: BattleEnemy, amount: float) -> void:
	if amount <= 0.0 or enemy.knockback_cd > 0.0:
		return
	var resisted := amount * maxf(0.0, 1.0 - enemy.knockback_resist)
	enemy.progress = maxf(0.0, enemy.progress - resisted)
	enemy.knockback_cd = _knockback_cooldown
	if enemy.progress < enemy.path_length:
		enemy.reaching = false


func _steer(shot: BattleShot, aim: Vector2, dt: float) -> void:
	var desired := aim - Vector2(shot.x, shot.y)
	if desired.length() < 0.001:
		return
	if shot.direction.length() < 0.001:
		shot.direction = desired.normalized()
		return
	var max_turn := deg_to_rad(shot.turn_deg) * dt
	var delta := clampf(shot.direction.angle_to(desired.normalized()), -max_turn, max_turn)
	shot.direction = shot.direction.rotated(delta).normalized()


func _spawn_enemy(enemy_id: String, path_id: String) -> void:
	var data := _catalog.enemy(enemy_id)
	if data.is_empty() or not _paths.has(path_id):
		push_warning("刷怪失败：%s / %s" % [enemy_id, path_id])
		return
	var stats: Dictionary = data.get("stats", {})
	var path: Array = _paths[path_id]
	var enemy := BattleEnemy.new()
	enemy.instance_id = _next_id()
	enemy.enemy_id = enemy_id
	enemy.path_id = path_id
	enemy.path_length = float(path.size() - 1)
	enemy.max_hp = maxf(float(stats.get("hp", 1)), 1.0)
	enemy.hp = enemy.max_hp
	enemy.armor = float(stats.get("armor", 0))
	enemy.speed = float(stats.get("move_speed_cells_per_sec", 1))
	enemy.spirit_drop = CombatCatalog.read_int(stats.get("spirit_drop", 0), 0)
	enemy.leak_damage = maxi(CombatCatalog.read_int(stats.get("leak_damage", 1), 1), 0)
	enemy.hit_radius = float(data.get("hit_radius_cells", 0.3))
	enemy.knockback_resist = float(data.get("knockback_resist", 0.0))
	enemy.spawn_left = _spawn_state
	enemy.born = true
	_enemies.append(enemy)


func _read_paths() -> void:
	_paths = {}
	var map: Dictionary = _level.get("map", {})
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
			_paths[path_id] = centers


func _rebuild_attack(unit: BattleUnit) -> void:
	var data := _catalog.character(unit.character_id)
	_set_base_attack(unit, data)
	for level_v in data.get("levels", []):
		if typeof(level_v) != TYPE_DICTIONARY:
			continue
		var level_def: Dictionary = level_v
		if CombatCatalog.read_int(level_def.get("level", 1), 1) > unit.level:
			continue
		for mod_v in level_def.get("behavior_mods", []):
			_apply_mod(unit, mod_v)


func _set_base_attack(unit: BattleUnit, data: Dictionary) -> void:
	var attack_v: Variant = data.get("attack", {})
	if typeof(attack_v) != TYPE_DICTIONARY:
		unit.attack = {}
		return
	unit.attack = (attack_v as Dictionary).duplicate(true)


func _apply_mod(unit: BattleUnit, mod_v: Variant) -> void:
	if typeof(mod_v) != TYPE_DICTIONARY:
		return
	var mod: Dictionary = mod_v
	if str(mod.get("op", "")) != "set":
		return
	var path := str(mod.get("path", ""))
	if not path.begins_with("attack."):
		return
	unit.attack[path.substr(7)] = mod.value


func _enemy_xy(enemy: BattleEnemy) -> Vector2:
	var raw: Array = _paths.get(enemy.path_id, [])
	if raw.is_empty():
		return Vector2.ZERO
	var last := raw.size() - 1
	var progress := clampf(enemy.progress, 0.0, float(last))
	var index := int(floor(progress))
	if index >= last:
		return raw[last]
	var from: Vector2 = raw[index]
	var to: Vector2 = raw[index + 1]
	return from.lerp(to, progress - float(index))


func _unit_center(unit: BattleUnit) -> Vector2:
	return Vector2(float(unit.col) + 0.5, float(unit.row) + 0.5)


func _aim_direction(origin: Vector2, aim: Vector2) -> Vector2:
	var direction := aim - origin
	if direction.length() < 0.001:
		return Vector2.DOWN
	return direction.normalized()


func _in_range(unit: BattleUnit, enemy: BattleEnemy) -> bool:
	var reach := float(unit.attack.get("range_cells", 0.0))
	return _unit_center(unit).distance_to(_enemy_xy(enemy)) <= reach


func _targetable(enemy: BattleEnemy) -> bool:
	return not enemy.dead and enemy.spawn_left <= 0.0


func _live_target(target_id: int) -> BattleEnemy:
	var enemy := _find_enemy(target_id)
	if enemy == null or not _targetable(enemy):
		return null
	return enemy


func _next_cost(character_id: String) -> int:
	var stats: Dictionary = _catalog.character(character_id).get("stats", {})
	var cost := CombatCatalog.read_int(stats.get("cost", 0), 0)
	var ratio := float(stats.get("copy_cost_increase_ratio", 0.0))
	for _copy_index in _copy_count(character_id):
		cost = roundi(float(cost) * (1.0 + ratio))
	return cost


func _upgrade_cost(unit: BattleUnit) -> int:
	if unit.level >= _max_level:
		return -1
	var index := unit.level - 1
	if index < 0 or index >= unit.upgrade_costs.size():
		return -1
	return CombatCatalog.read_int(unit.upgrade_costs[index], 0)


func _sell_value(unit: BattleUnit) -> int:
	return int(floor(float(unit.spent) * unit.refund_ratio + 0.000001))


func _copy_count(character_id: String) -> int:
	var count := 0
	for unit in _units:
		if unit.character_id == character_id:
			count += 1
	return count


func _cell_mark(col: int, row: int) -> String:
	var map: Dictionary = _level.get("map", {})
	var cells: Array = map.get("cells", [])
	if row < 0 or row >= cells.size():
		return ""
	var line := str(cells[row])
	if col < 0 or col >= line.length():
		return ""
	return line.substr(col, 1)


func _character_allowed(character_id: String) -> bool:
	var params: Dictionary = _level.get("params", {})
	for id_v in params.get("available_character_ids", []):
		if str(id_v) == character_id:
			return true
	return false


func _jobs_done() -> bool:
	for job_v in _jobs:
		if typeof(job_v) == TYPE_DICTIONARY and int((job_v as Dictionary).left) > 0:
			return false
	return true


func _next_gap(index: int) -> float:
	var wave_v: Variant = _waves[index]
	if typeof(wave_v) != TYPE_DICTIONARY:
		return _intermission_sec
	return maxf(float((wave_v as Dictionary).get("next_wave_delay_sec", _intermission_sec)), 0.0)


func _call_allowed() -> bool:
	if _phase == PHASE_DEPLOY:
		return true
	if _phase != PHASE_WAITING and _phase != PHASE_INTERMISSION:
		return false
	return _wave_index + 1 < _waves.size()


func _call_reward_now() -> int:
	if _phase == PHASE_DEPLOY:
		return floori(maxf(_phase_time, 0.0) * _early_start_rate)
	if _phase == PHASE_WAITING or _phase == PHASE_INTERMISSION:
		return floori(maxf(_phase_time, 0.0) * _early_call_rate)
	return 0


func _outcome() -> String:
	if _phase == PHASE_VICTORY or _phase == PHASE_DEFEAT:
		return _phase
	return ""


func _terminal() -> bool:
	return _phase == PHASE_VICTORY or _phase == PHASE_DEFEAT


func _living_count() -> int:
	var count := 0
	for enemy in _enemies:
		if not enemy.dead:
			count += 1
	return count


func _next_id() -> int:
	var current := _id_serial
	_id_serial += 1
	return current


func _find_unit(unit_id: int) -> BattleUnit:
	for unit in _units:
		if unit.instance_id == unit_id:
			return unit
	return null


func _find_enemy(enemy_id: int) -> BattleEnemy:
	for enemy in _enemies:
		if enemy.instance_id == enemy_id and not enemy.dead:
			return enemy
	return null


func _unit_on(col: int, row: int) -> BattleUnit:
	for unit in _units:
		if unit.col == col and unit.row == row:
			return unit
	return null


func _roster() -> Array:
	var result: Array = []
	var params: Dictionary = _level.get("params", {})
	for id_v in params.get("available_character_ids", []):
		var id := str(id_v)
		var data := _catalog.character(id)
		if data.is_empty():
			continue
		var cost := _next_cost(id)
		var copies := _copy_count(id)
		var affordable := copies < _max_copies and _spirit >= cost and not _terminal()
		(
			result
			. append(
				{
					"id": id,
					"display_name": str(data.get("display_name", id)),
					"cost": cost,
					"copies": copies,
					"affordable": affordable,
				}
			)
		)
	return result


func _unit_snapshots() -> Array:
	var result: Array = []
	for unit in _units:
		var cost := _upgrade_cost(unit)
		(
			result
			. append(
				{
					"id": unit.instance_id,
					"character_id": unit.character_id,
					"display_name": unit.display_name,
					"col": unit.col,
					"row": unit.row,
					"level": unit.level,
					"range": float(unit.attack.get("range_cells", 1.0)),
					"upgrade_cost": cost,
					"sell_refund": _sell_value(unit),
					"can_upgrade": cost >= 0 and _spirit >= cost,
				}
			)
		)
	return result


func _enemy_snapshots() -> Array:
	var result: Array = []
	for enemy in _enemies:
		var pos := _enemy_xy(enemy)
		(
			result
			. append(
				{
					"id": enemy.instance_id,
					"enemy_id": enemy.enemy_id,
					"x": pos.x,
					"y": pos.y,
					"hp": enemy.hp,
					"max_hp": enemy.max_hp,
				}
			)
		)
	return result


func _shot_snapshots() -> Array:
	var result: Array = []
	for shot in _shots:
		(
			result
			. append(
				{
					"id": shot.instance_id,
					"character_id": shot.character_id,
					"x": shot.x,
					"y": shot.y,
				}
			)
		)
	return result
