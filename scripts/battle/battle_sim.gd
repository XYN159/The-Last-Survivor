class_name BattleSim
extends RefCounted

## 一局塔防的规则。不画画面。每调用一次 tick，逻辑时间前进 1/60 秒。
## 放置、撤退和叫波在点击时立刻结算。移动、攻击、回灵和胜负只在 tick 里发生。
## 调参读 data/balance/stage1_rules.json（经 CombatCatalog.tuning）：
## 灵力每秒回一点、有上限；同名同时只能放一个；放置必须带朝向；不做局内升级；
## 撤退返还本次费用的一半，再放加价、并要等一段时间；普通和 Boss 漏过扣的命不同。
## 关卡有 timeline 时按绝对秒数出怪（BattleTimeline），开局就开始计时，没有布阵和叫波。
## 全部出完、场上清空且生命还在就胜利。没有 timeline 的关卡照旧走下面的波次：
## 每一波都读 delay_sec。第 1 波写成 0，布阵结束就出怪，代码不再单独豁免。
## 出怪窗口用这一波的 duration_sec，从这一波开始时算。窗口结束再空一档，不等清场。
## 空档优先用下一波的 delay_sec；没有就用上一波的 next_wave_delay_sec，再没有用规则里的 4 秒。
## 关卡写了 deploy_wait_for_player 时，布阵倒计时停住，放下第一个角色才开始走。

const PHASE_DEPLOY := "deploy"
const PHASE_SPAWNING := "spawning"
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
var _armor_floor: float = 0.0
var _min_damage: int = 0
var _economy := BattleEconomy.new()
var _early_call_rate: float = 2.0
var _early_start_rate: float = 1.0
var _max_copies: int = 1
var _ordinary_leak: int = 1
var _boss_leak: int = 1
var _timeline: BattleTimeline = null
var _spawn_state: float = 0.3
var _knockback_cooldown: float = 0.25
var _guard_hp: int = 20
var _guard_max_hp: int = 20
var _intermission_sec: float = 4.0
var _spawn_window_sec: float = 20.0
var _phase: String = PHASE_DEPLOY
var _phase_time: float = 10.0
## 当前这段计时开始时的总长，只给画面算倒计时条，不参与结算。0 表示这段没有计时。
var _phase_duration: float = 10.0
var _window_left: float = 0.0
var _wave_index: int = -1
var _id_serial: int = 1
var _deploy_waiting: bool = false


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
	_economy.advance(_dt)
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
	_clear_born()
	return _events


## 朝向必须显式给出（BattleFacing.ALL 之一），没有朝向就放不下。
func place(character_id: String, col: int, row: int, facing: String) -> bool:
	if not BattleFacing.is_valid(facing) or not can_place(character_id, col, row):
		return false
	var data := _catalog.character(character_id)
	var cost := _next_cost(character_id)
	var stats: Dictionary = data.get("stats", {})
	var unit := BattleUnit.new()
	unit.instance_id = _next_id()
	unit.character_id = character_id
	unit.display_name = str(data.get("display_name", character_id))
	unit.col = col
	unit.row = row
	unit.facing = facing
	unit.spent = cost
	unit.base_attack = float(stats.get("base_attack", 0))
	unit.level_attack_mult = stats.get("level_attack_mult", [1.0])
	unit.crit_chance = float(stats.get("crit_chance", 0))
	unit.crit_mult = float(stats.get("crit_mult", 1))
	_set_base_attack(unit, data)
	_set_barrier(unit)
	unit.cooldown = float(unit.attack.get("initial_delay_sec", 0.3))
	_units.append(unit)
	_economy.spend(cost)
	_deploy_waiting = false
	return true


## 不看朝向的放置检查。界面在让玩家选朝向之前先问一次，放不下就不弹方向按钮。
func can_place(character_id: String, col: int, row: int) -> bool:
	if _terminal() or not _character_allowed(character_id):
		return false
	if _cell_mark(col, row) != "." or _unit_on(col, row) != null:
		return false
	if _copy_count(character_id) >= _copy_limit(character_id):
		return false
	if _economy.respawn_wait(character_id) > 0.0:
		return false
	if _catalog.character(character_id).is_empty():
		return false
	return _economy.spirit >= _next_cost(character_id)


## 第一版战斗不做局内升级（制作人决定 P3），永远失败。
func upgrade(_unit_id: int) -> bool:
	return false


## 撤退：返还本次部署费用的一半（向下取整），记一次撤退，并开始再部署等待。
func retreat(unit_id: int) -> bool:
	var unit := _find_unit(unit_id)
	if unit == null or _terminal():
		return false
	_economy.record_retreat(unit.character_id, unit.spent)
	_units.erase(unit)
	return true


func call_next_wave() -> bool:
	if _timeline != null:
		return false
	if _phase == PHASE_DEPLOY:
		return _start_early(0, _early_start_rate)
	if _phase == PHASE_INTERMISSION:
		return _start_early(_wave_index + 1, _early_call_rate)
	return false


func view_state() -> Dictionary:
	return {
		"spirit": _economy.spirit,
		"max_spirit": _economy.max_spirit,
		"guard_hp": _guard_hp,
		"guard_max_hp": _guard_max_hp,
		"phase": _phase,
		"phase_time_left": maxf(_phase_time, 0.0),
		"phase_duration": _phase_duration,
		"deploy_waiting": _deploy_waiting,
		"timeline": _timeline != null,
		"spawned": 0 if _timeline == null else _timeline.spawned(),
		"spawn_total": 0 if _timeline == null else _timeline.total(),
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
	_economy = BattleEconomy.from_tuning(tune)
	_early_call_rate = float(tune.early_call_reward_per_sec)
	_early_start_rate = float(tune.early_start_reward_per_sec)
	_max_copies = int(tune.max_copies)
	_ordinary_leak = int(tune.ordinary_leak)
	_boss_leak = int(tune.boss_leak)
	_spawn_state = float(tune.spawn_state_sec)
	_knockback_cooldown = float(tune.knockback_cooldown_sec)
	_guard_max_hp = int(tune.guard_max_hp)
	_guard_hp = _guard_max_hp
	_intermission_sec = float(tune.intermission_sec)
	_spawn_window_sec = float(tune.spawn_window_sec)
	_phase = PHASE_DEPLOY
	_phase_time = float(tune.deploy_time_sec)
	_phase_duration = _phase_time
	_deploy_waiting = bool(tune.deploy_wait_for_player)
	_wave_index = -1
	_paths = BattleLevelReader.paths(_level)
	_rng.seed = 1
	_timeline = BattleTimeline.from_level(_level)
	if _timeline == null:
		_waves = _level.get("waves", [])
		return
	_waves = []
	_phase = PHASE_SPAWNING
	_phase_time = _timeline.time_to_next()
	_phase_duration = _timeline.gap_to_next()
	_deploy_waiting = false


func _advance_timeline(dt: float) -> void:
	for entry in _timeline.advance(dt):
		_spawn_enemy(str(entry.enemy_id), str(entry.path_id), bool(entry.boss))
	_phase_time = _timeline.time_to_next()
	_phase_duration = _timeline.gap_to_next()
	if _timeline.finished():
		_phase = PHASE_FINAL


func _advance_clock(dt: float) -> void:
	if _timeline != null:
		if _phase == PHASE_SPAWNING:
			_advance_timeline(dt)
		return
	if _phase == PHASE_SPAWNING:
		_window_left = maxf(0.0, _window_left - dt)
		_phase_time = _window_left
		return
	if _phase != PHASE_DEPLOY and _phase != PHASE_INTERMISSION:
		return
	if _phase == PHASE_DEPLOY and _deploy_waiting:
		return
	_phase_time = maxf(0.0, _phase_time - dt)
	if _phase_time > 0.0:
		return
	if _phase == PHASE_DEPLOY:
		_release_wave(0)
		return
	_begin_wave(_wave_index + 1)


func _advance_spawns(dt: float) -> void:
	if _timeline != null or _phase != PHASE_SPAWNING:
		return
	for job_v in _jobs:
		_spawn_job(job_v, dt)
	if _window_left <= 0.0:
		_close_spawn_window()


func _spawn_job(job_v: Variant, dt: float) -> void:
	if typeof(job_v) != TYPE_DICTIONARY:
		return
	var job: Dictionary = job_v
	while int(job.left) > 0 and float(job.wait) <= 0.0:
		_spawn_enemy(str(job.enemy_id), str(job.path_id), bool(job.boss))
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
	var hit := {
		"power": shot.attack_power,
		"knockback": shot.knockback,
		"heavy": shot.heavy,
		"uses_barrier": shot.uses_barrier,
		"barrier": shot.barrier,
	}
	_queue_hit(target, hit)
	return false


func _resolve_hits() -> void:
	for hit_v in _hits:
		if typeof(hit_v) != TYPE_DICTIONARY:
			continue
		var hit: Dictionary = hit_v
		var enemy: BattleEnemy = hit.enemy
		if enemy.dead:
			continue
		var outside := bool(hit.uses_barrier) and not _in_barrier(hit.barrier, enemy)
		var damage := 0
		if not outside:
			damage = DamageMath.resolve(float(hit.power), enemy.armor, _armor_floor, _min_damage)
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
					"outside_barrier": outside,
					"id": enemy.instance_id,
				}
			)
		)
		if enemy.hp > 0.0:
			if not outside:
				_apply_knockback(enemy, float(hit.knockback))
			continue
		enemy.hp = 0.0
		enemy.dead = true
		_economy.gain(enemy.spirit_drop)
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


func _clear_born() -> void:
	for enemy in _enemies:
		enemy.born = false


func _release_wave(index: int) -> void:
	var lead := _lead_in(index)
	if lead <= 0.0:
		_begin_wave(index)
		return
	_phase = PHASE_INTERMISSION
	_phase_time = lead
	_phase_duration = lead
	_wave_index = index - 1


func _begin_wave(index: int) -> void:
	if index < 0 or index >= _waves.size():
		return
	_wave_index = index
	_phase = PHASE_SPAWNING
	_jobs.clear()
	var wave := BattleLevelReader.wave_at(_waves, index)
	_window_left = BattleLevelReader.wave_duration(wave, _spawn_window_sec)
	_phase_time = _window_left
	_phase_duration = _window_left
	for group_v in wave.get("spawns", []):
		_add_job(group_v)


func _close_spawn_window() -> void:
	_jobs.clear()
	if _wave_index >= _waves.size() - 1:
		_phase = PHASE_FINAL
		_phase_time = 0.0
		_phase_duration = 0.0
		_window_left = 0.0
		return
	_phase = PHASE_INTERMISSION
	_phase_time = _lead_in(_wave_index + 1)
	_phase_duration = _phase_time
	_window_left = 0.0


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
				"boss": bool(group.get("boss", false)),
			}
		)
	)


func _start_early(index: int, rate: float) -> bool:
	if index < 0 or index >= _waves.size():
		return false
	_economy.gain(floori(maxf(_phase_time, 0.0) * rate))
	if _phase == PHASE_DEPLOY:
		_release_wave(index)
	else:
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
		shot.uses_barrier = unit.uses_barrier
		shot.barrier = unit.barrier
		_shots.append(shot)


func _fire_line(unit: BattleUnit, primary: BattleEnemy) -> void:
	var origin := _unit_center(unit)
	var direction := _aim_direction(origin, _enemy_xy(primary))
	var reach := float(unit.attack.get("range_cells", 0.0))
	for enemy in _line_targets(unit, primary, origin, direction, reach):
		var rolled := _roll_shot(unit)
		rolled["uses_barrier"] = unit.uses_barrier
		rolled["barrier"] = unit.barrier
		_queue_hit(enemy, rolled)
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
		if shot.uses_barrier and not _in_barrier(shot.barrier, enemy):
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


## hit 里带 power、knockback、heavy；发射者只打结界时再带 uses_barrier 和 barrier。
func _queue_hit(enemy: BattleEnemy, hit: Dictionary) -> void:
	var queued := hit.duplicate()
	queued["enemy"] = enemy
	if not queued.has("uses_barrier"):
		queued["uses_barrier"] = false
		queued["barrier"] = {}
	_hits.append(queued)


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


func _spawn_enemy(enemy_id: String, path_id: String, boss: bool) -> void:
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
	var base_hp := CombatCatalog.read_float(stats.get("hp", 1), 1.0)
	enemy.max_hp = maxf(base_hp * _catalog.enemy_hp_multiplier(enemy_id), 1.0)
	enemy.hp = enemy.max_hp
	enemy.armor = float(stats.get("armor", 0))
	enemy.speed = float(stats.get("move_speed_cells_per_sec", 1))
	enemy.spirit_drop = CombatCatalog.read_int(stats.get("spirit_drop", 0), 0)
	enemy.boss = boss or bool(data.get("is_boss", false)) or enemy_id.begins_with("boss_")
	enemy.leak_damage = _boss_leak if enemy.boss else _ordinary_leak
	enemy.hit_radius = float(data.get("hit_radius_cells", 0.3))
	enemy.knockback_resist = float(data.get("knockback_resist", 0.0))
	enemy.spawn_left = _spawn_state
	enemy.born = true
	_enemies.append(enemy)


func _set_base_attack(unit: BattleUnit, data: Dictionary) -> void:
	var attack_v: Variant = data.get("attack", {})
	if typeof(attack_v) != TYPE_DICTIONARY:
		unit.attack = {}
		return
	unit.attack = (attack_v as Dictionary).duplicate(true)


## 结界只留地面格（路线、入口、守护点），草地和障碍不算。
func _set_barrier(unit: BattleUnit) -> void:
	var size := _catalog.barrier(unit.character_id)
	unit.uses_barrier = not size.is_empty()
	unit.barrier = {}
	if not unit.uses_barrier:
		return
	var area := BattleFacing.area(
		unit.col, unit.row, unit.facing, int(size.forward), int(size.side)
	)
	for cell in area:
		if _is_ground(cell.x, cell.y):
			unit.barrier[cell] = true


func _is_ground(col: int, row: int) -> bool:
	return ["P", "S", "G"].has(_cell_mark(col, row))


func _in_barrier(barrier: Dictionary, enemy: BattleEnemy) -> bool:
	var pos := _enemy_xy(enemy)
	return barrier.has(Vector2i(floori(pos.x), floori(pos.y)))


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
	if unit.uses_barrier:
		return _in_barrier(unit.barrier, enemy)
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
	return _economy.deploy_cost(character_id, _catalog.deploy_cost(character_id))


func _copy_limit(character_id: String) -> int:
	var stats: Dictionary = _catalog.character(character_id).get("stats", {})
	if stats.has("max_copies"):
		return maxi(CombatCatalog.read_int(stats.get("max_copies"), _max_copies), 0)
	return _max_copies


func _copy_count(character_id: String) -> int:
	var count := 0
	for unit in _units:
		if unit.character_id == character_id:
			count += 1
	return count


func _cell_mark(col: int, row: int) -> String:
	return BattleLevelReader.cell_mark(_level, col, row)


func _character_allowed(character_id: String) -> bool:
	var params: Dictionary = _level.get("params", {})
	for id_v in params.get("available_character_ids", []):
		if str(id_v) == character_id:
			return true
	return false


func _lead_in(index: int) -> float:
	return BattleLevelReader.lead_in(_waves, index, _intermission_sec)


func _call_allowed() -> bool:
	if _timeline != null:
		return false
	if _phase == PHASE_DEPLOY:
		return true
	if _phase != PHASE_INTERMISSION:
		return false
	return _wave_index + 1 < _waves.size()


func _call_reward_now() -> int:
	if _phase == PHASE_DEPLOY:
		return floori(maxf(_phase_time, 0.0) * _early_start_rate)
	if _phase == PHASE_INTERMISSION:
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
		var wait := _economy.respawn_wait(id)
		var affordable := (
			copies < _copy_limit(id) and _economy.spirit >= cost and wait <= 0.0 and not _terminal()
		)
		(
			result
			. append(
				{
					"id": id,
					"display_name": str(data.get("display_name", id)),
					"cost": cost,
					"copies": copies,
					"respawn_left": wait,
					"retreats": _economy.retreats(id),
					"affordable": affordable,
				}
			)
		)
	return result


func _unit_snapshots() -> Array:
	var result: Array = []
	for unit in _units:
		var barrier_cells: Array = []
		for cell_v in unit.barrier.keys():
			var cell: Vector2i = cell_v
			barrier_cells.append([cell.x, cell.y])
		(
			result
			. append(
				{
					"id": unit.instance_id,
					"character_id": unit.character_id,
					"display_name": unit.display_name,
					"col": unit.col,
					"row": unit.row,
					"facing": unit.facing,
					"level": unit.level,
					"range": float(unit.attack.get("range_cells", 1.0)),
					"uses_barrier": unit.uses_barrier,
					"barrier_cells": barrier_cells,
					"retreat_refund": _economy.refund(unit.spent),
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
