# -*- coding: utf-8 -*-
"""《东方守幻录》简化关卡模拟器（只用 Python 标准库）。

这是给数值策划算曲线用的「简化但真实」模型，不是游戏代码。
所有数值从仓库 data/ 下的 CSV 读取，改表后重跑即可。
模型假设和局限写在 docs/design/numeric/09_simulation.md。
"""
from __future__ import annotations

import csv
import json
import math
import random
from dataclasses import dataclass, field
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / "data"

DT = 0.1  # 模拟步长（秒）


# ---------------------------------------------------------------- 读表
def read_csv(path: Path) -> list[dict]:
    with open(path, encoding="utf-8", newline="") as f:
        return list(csv.DictReader(f))


def num(v, default=0.0):
    if v is None or v == "":
        return default
    try:
        return float(v)
    except ValueError:
        return default


def load_rules() -> dict:
    rules = {}
    for r in read_csv(DATA / "balance" / "battle_rules.csv"):
        v = r["value"]
        try:
            rules[r["rule_key"]] = float(v)
        except ValueError:
            rules[r["rule_key"]] = v
    return rules


def load_characters() -> dict:
    return {r["character_id"]: r for r in read_csv(DATA / "characters.csv")}


def load_enemies() -> dict:
    return {r["enemy_id"]: r for r in read_csv(DATA / "enemies.csv")}


def load_buffs() -> list[dict]:
    return read_csv(DATA / "roguelite_buffs.csv")


def load_levels() -> list[dict]:
    return read_csv(DATA / "balance" / "level_difficulty.csv")


def load_coefs() -> dict:
    """data/balance/combat_coefficients.csv → {id: {field: value}}（技能、状态、联动、符卡的系数）。"""
    out: dict = {}
    for r in read_csv(DATA / "balance" / "combat_coefficients.csv"):
        try:
            v = float(r["value"])
        except ValueError:
            v = r["value"]
        out.setdefault(r["id"], {})[r["field"]] = v
    return out


# ---------------------------------------------------------------- 公式
def damage(attack: float, armor: float, min_ratio: float = 0.2) -> float:
    """护甲这一步：max(攻击 - 护甲, 攻击 × 0.2)。"""
    return max(attack - armor, attack * min_ratio)


def round_half_away(x: float) -> int:
    """四舍五入，0.5 远离 0（对应 GDScript roundi）。"""
    return int(math.floor(abs(x) + 0.5)) * (1 if x >= 0 else -1)


def final_damage(attack: float, armor: float, vuln_add: float = 0.0, synergy_add: float = 0.0,
                 floor_ratio: float = 0.2, min_damage: float = 1) -> int:
    """PR #4 流水线第 3–5 步：护甲 → 易伤桶 × 联动桶 → 取整且最少 1。攻击力和暴击在调用前算好。"""
    d = damage(attack, armor, floor_ratio)
    return max(int(min_damage), round_half_away(d * (1 + vuln_add) * (1 + synergy_add)))


def hp_multiplier(level_index: int, per_level: float = 0.15) -> float:
    return 1 + per_level * (level_index - 1)


def wave_budget(wave: int, base: float, per_wave: float, coef: float) -> float:
    return (base + per_wave * wave) * coef


def meta_attack_mult(level: int, per_level: float = 0.08) -> float:
    return 1 + per_level * (level - 1)


def upgrade_mult(upgrades: int, pct: float = 0.4) -> float:
    """局内升级：在 1 级基础上加法叠加。升 2 次 = 1 + 0.4 × 2 = 1.8。"""
    return 1 + pct * upgrades


# ---------------------------------------------------------------- 地图
# 7 列 × 12 行，x = 列(0..6)，y = 行(0..11)，格子中心为整数坐标，第 0 行在最上面（北）。
# MVP 7 关用关卡策划 PR #5 的真实地图（快照在 tools/numeric/ref_maps.json）：只能放在「.」格，路线是「P」格，可以有多条固定路线。
# 其他关还没有地图，用下面这条「参考路径」（S 形，约 22 格长）。
GRID_W, GRID_H = 7, 12
REF_WAYPOINTS = [(1, -0.5), (1, 3), (5, 3), (5, 7), (1, 7), (1, 10), (3, 10), (3, 11.5)]
SAMPLE_STEP = 0.05
MAPS_FILE = Path(__file__).resolve().parent / "ref_maps.json"


class Path2D:
    def __init__(self, pts, pid="main"):
        self.pid = pid
        self.pts = pts
        self.seg = []
        acc = 0.0
        for (x0, y0), (x1, y1) in zip(pts, pts[1:]):
            ln = math.hypot(x1 - x0, y1 - y0)
            if ln <= 0:
                continue
            self.seg.append((acc, ln, x0, y0, x1, y1))
            acc += ln
        self.length = acc
        self.samples = [self.pos(i * SAMPLE_STEP) for i in range(int(self.length / SAMPLE_STEP) + 1)]

    def pos(self, p: float):
        if p <= 0:
            return self.pts[0]
        for acc, ln, x0, y0, x1, y1 in self.seg:
            if p <= acc + ln:
                t = (p - acc) / ln
                return (x0 + (x1 - x0) * t, y0 + (y1 - y0) * t)
        return self.pts[-1]

    def path_cells(self):
        cells = set()
        for x, y in self.samples:
            cx, cy = round(x), round(y)
            if 0 <= cy < GRID_H and 0 <= cx < GRID_W and abs(x - cx) < 0.45 and abs(y - cy) < 0.45:
                cells.add((cx, cy))
        return cells

    def coverage(self, cx, cy, rng):
        """路径上处于射程内的进度区间列表 [(p0, p1), ...]。"""
        ivs, start = [], None
        for i, (x, y) in enumerate(self.samples):
            inside = math.hypot(x - cx, y - cy) <= rng + 1e-9
            p = i * SAMPLE_STEP
            if inside and start is None:
                start = p
            if not inside and start is not None:
                ivs.append((start, p))
                start = None
        if start is not None:
            ivs.append((start, self.length))
        return ivs

    def progress_of_cell(self, cell):
        best, bd = 0, 9
        for i, (x, y) in enumerate(self.samples):
            d = math.hypot(x - cell[0], y - cell[1])
            if d < bd:
                best, bd = i * SAMPLE_STEP, d
        return best


def path_from_cells(cells, pid):
    """关卡文件的路线格子 → 折线：从入口格上方半格进来，走到守护点格再往外半格算漏过。"""
    pts = [(cells[0][0], cells[0][1] - 0.5)] + [tuple(c) for c in cells]
    last, prev = cells[-1], cells[-2]
    pts.append((last[0] + 0.5 * (last[0] - prev[0]), last[1] + 0.5 * (last[1] - prev[1])))
    return Path2D(pts, pid)


class LevelMap:
    def __init__(self, level_id: str, source: str):
        self.level_id = level_id
        self.ice_phases = []
        data = None
        if source == "pr5_snapshot" and MAPS_FILE.exists():
            data = json.loads(MAPS_FILE.read_text(encoding="utf-8"))["levels"].get(level_id)
        if data:
            self.paths = [path_from_cells(p["cells"], p["id"]) for p in data["paths"]]
            self.placeable = sorted((x, y) for y, row in enumerate(data["grid"]) for x, ch in enumerate(row) if ch == ".")
            self.ice_phases = data.get("ice_phases", [])
            self.source = "pr5_snapshot"
        else:
            self.paths = [Path2D(REF_WAYPOINTS, "ref")]
            self.source = "reference"
            cells = self.paths[0].path_cells()
            self.placeable = sorted((x, y) for x in range(GRID_W) for y in range(GRID_H) if (x, y) not in cells)
        self.path_cells = set()
        for p in self.paths:
            self.path_cells |= p.path_cells()


_MAP_CACHE: dict = {}


def get_map(level: dict) -> LevelMap:
    key = (level["level_id"], level.get("map_source", "reference"))
    if key not in _MAP_CACHE:
        _MAP_CACHE[key] = LevelMap(*key)
    return _MAP_CACHE[key]


def in_ivs(p, ivs):
    for a, b in ivs:
        if a <= p <= b:
            return True
    return False


# ---------------------------------------------------------------- 实体
@dataclass
class Enemy:
    eid: str
    hp: float
    maxhp: float
    armor: float
    speed: float
    reward: float
    leak: float
    block_dps: float
    flying: bool
    boss: bool
    wave: int
    path: object = None
    charge_on_kill: float = 0.0
    speed_mult_terrain: float = 1.0
    progress: float = 0.0
    alive: bool = True
    leaked: bool = False
    slow_amt: float = 0.0
    slow_until: float = -1.0
    frozen_until: float = -1.0
    freeze_immune_until: float = -1.0
    stun_until: float = -1.0          # 隙间晕眩等「速度为 0 但不是冻结」
    blocked_by: object = None
    burn_atk: float = 0.0
    burn_until: float = -1.0
    burn_next: float = 0.0
    burn_src: object = None
    invuln_until: float = -1.0
    phase: int = 1
    loops: int = 0
    is_chapter_boss: bool = False


def _pos(e):
    return e.path.pos(e.progress)


@dataclass
class Unit:
    key: str                      # 例如 reimu、reimu#2（第 2 个同名角色）
    cid: str
    row: dict
    cell: tuple
    meta_level: int
    copy_index: int = 1
    upgrades: int = 0
    cooldown: float = 0.0
    skill_cd: float = 1.0
    ivs: dict = field(default_factory=dict)       # {路线 id: [(p0, p1), ...]}
    rng: float = 0.0
    block_path: str = ""
    hp: float = 0.0
    maxhp: float = 0.0
    down_until: float = -1.0
    retreated: bool = False
    block_progress: float = 0.0
    blocked: list = field(default_factory=list)
    damage_done: float = 0.0
    spell_damage: float = 0.0
    hits: int = 0
    invested: float = 0.0


# ---------------------------------------------------------------- 模拟
class Battle:
    def __init__(self, level: dict, lineup: list, meta_levels: dict, seed: int = 1,
                 rules=None, chars=None, enemies=None, buffs=None, buff_priority=None,
                 join_wave=None, coefs=None, force_caster=None, spell_mode=None):
        self.R = rules or load_rules()
        self.C = chars or load_characters()
        self.E = enemies or load_enemies()
        self.B = buffs or load_buffs()
        self.K = coefs or load_coefs()
        self.level = level
        self.map = get_map(level)
        self.idx = int(level["level_index"])
        # 符卡释放：manual = 合理的手动玩家（默认，自动释放开关默认关闭）；auto = 打开自动释放开关（PR #4 条件）
        self.spell_mode = spell_mode or ("auto" if self.R.get("auto_release_default_on", 0) else "manual")
        self.caster_switches = 0
        self.ready_since = None               # 手动玩家：满足放符卡条件的起始时间（反应时间）
        self.ice_cells = set()
        self.boss_timeout = False
        self.spawn_count = 0
        self.buff_offers = 0
        self.guaranteed_offers = 0
        self.transforms = []
        self._buff_by_id = {b["buff_id"]: b for b in self.B}
        self.lineup = lineup
        self.join_wave = join_wave or {}
        self.current_wave = 0
        self.meta = meta_levels
        self.rng = random.Random(seed * 7919 + self.idx)
        self.crit_rng = random.Random(seed * 104729 + self.idx * 31)
        self.t = 0.0
        self.spirit = num(level.get("start_spirit"), self.R["start_spirit"]) or self.R["start_spirit"]
        self.base_hp = self.R["base_hp"]
        self.min_hp_seen = self.base_hp
        self.units: list[Unit] = []
        self.enemies: list[Enemy] = []
        self.timestop_until = -1.0
        self.guard_invuln_until = -1.0
        self.guard_shield = 0
        self.zones = []                       # 灵梦结界：(cx, cy, until, owner_key)
        self.temp_aspd = (0.0, -1.0)          # (加成, 到期)，晨雾之湖
        self.buff_priority = buff_priority or DEFAULT_BUFF_PRIORITY
        self.mod = dict(atk_pct=0.0, aspd_pct=0.0, energy_pct=0.0, kill_spirit_flat=0.0, crit_add=0.0,
                        upgrade_discount=0.0, boss_dmg=0.0, armor_pen=0.0, spell_power=0.0,
                        split=0, pierce=0, freeze_chance=0.0, barrier_plus=0.0, combo=0.0, leak_reduce=0)
        self.buff_stacks: dict = {}
        self.picked: list = []
        # 符卡：全队共用一条能量（PR #4），满能量由当前符卡使决定
        self.energy = float(self.R.get("spell_energy_start", 0) or 0)
        self.caster: Unit | None = None
        self.full_since = None
        self.force_caster = force_caster      # 对比用：强制某个角色当符卡使
        self.hp_mult = hp_multiplier(self.idx, self.R["hp_mult_per_level"])
        # 每点伤害充能：优先用本关表里校准好的值（level_difficulty.csv），没有就用 基准 ÷ 血量倍率
        self.per_damage = num(level.get("spell_charge_per_damage")) or self.R["spell_charge_per_damage_base"] / self.hp_mult
        self.cycle = dict(start=0.0, normal=0.0, crisis=0.0, dmg=0.0, kill=0.0)
        self.cycles = []                      # 每次从 0 充到满：用时、其中危急秒数、伤害/击杀各占多少
        self.casts = []                       # (时间, 符卡使)
        self.crisis = False
        # 统计
        self.spirit_earned = self.spirit
        self.spirit_spent = 0.0
        self.wave_log = []
        self.purchases = []
        self.active_time = 0.0                # 场上有敌人的时间
        self.normal_damage = 0.0              # 非符卡的有效伤害（算每秒伤害 D）
        self.normal_kills = 0                 # 非符卡击杀（算每秒击杀 K）
        self.build_queue = self._make_queue()

    # ---------------- 购买计划
    def max_copies(self, cid):
        return int(min(self.R.get("max_copies_per_character", 1), num(self.C[cid].get("max_copies"), 1)))

    def _make_queue(self):
        # 先按阵容顺序部署，主力输出立刻升 1 次；全部部署完补齐升级；
        # 灵力还有富余时买第 2、3 个同名角色（每个买完就升满）。
        q = []
        for c in self.lineup:
            q.append(("deploy", c))
            if c in EARLY_UPGRADE:
                q.append(("up", c))
        order = sorted(self.lineup, key=lambda c: UPGRADE_PRIORITY.index(c) if c in UPGRADE_PRIORITY else 99)
        q += [("up", c) for c in order if c not in EARLY_UPGRADE]
        q += [("up", c) for c in order]
        for k in (2, 3):
            for c in order:
                if self.C[c]["placement"] == "path" and k > 2:
                    continue
                if k <= self.max_copies(c):
                    key = f"{c}#{k}"
                    q += [("deploy", key), ("up", key), ("up", key)]
        return q

    def unit(self, key):
        for u in self.units:
            if u.key == key:
                return u
        return None

    @staticmethod
    def cid_of(key):
        return key.split("#")[0]

    def cost_of(self, item):
        kind, key = item
        cid = self.cid_of(key)
        if kind == "deploy":
            k = int(key.split("#")[1]) if "#" in key else 1
            ratio = num(self.C[cid].get("copy_cost_increase_ratio"), self.R.get("copy_cost_increase_ratio", 0.5))
            return round(num(self.C[cid]["deploy_cost"]) * (1 + ratio * (k - 1)))
        u = self.unit(key)
        base = self.R["upgrade_cost_1"] if u.upgrades == 0 else self.R["upgrade_cost_2"]
        return round(base * (1 - self.mod["upgrade_discount"]))

    def try_buy(self):
        for u in self.units:
            if u.retreated and self.t >= u.down_until:
                cost = round(num(u.row["deploy_cost"]) * 0.5)
                if self.spirit >= cost:
                    self.spirit -= cost
                    self.spirit_spent += cost
                    u.retreated = False
                    u.hp = u.maxhp
                    self.purchases.append((round(self.t, 1), "redeploy", u.key, cost))
        while self.build_queue:
            item = None
            for it in self.build_queue:
                if self.join_wave.get(self.cid_of(it[1]), 1) > max(1, self.current_wave):
                    continue
                if it[0] == "up" and self.unit(it[1]) is None:
                    continue
                item = it
                break
            if item is None:
                return
            cost = self.cost_of(item)
            if self.spirit < cost:
                return
            self.spirit -= cost
            self.spirit_spent += cost
            self.build_queue.remove(item)
            if item[0] == "deploy":
                if self.deploy(item[1]) is None:       # 没有空格：退钱，放弃这个角色和它的升级
                    self.spirit += cost
                    self.spirit_spent -= cost
                    self.build_queue = [it for it in self.build_queue if it[1] != item[1]]
                    continue
                self.unit(item[1]).invested += cost
            else:
                u = self.unit(item[1])
                u.upgrades += 1
                u.invested += cost
            self.purchases.append((round(self.t, 1), item[0], item[1], cost))

    # ---------------- 摆位
    def covers(self, u: Unit, e: Enemy) -> bool:
        return in_ivs(e.progress, u.ivs.get(e.path.pid, ()))

    def unit_range(self, row) -> float:
        """射程 × 本关浓雾倍率（最低 fog_min_range 格）。"""
        rng = num(row["range"])
        fog = num(self.level.get("fog_range_mult"), 1.0) or 1.0
        if fog < 1.0 and rng > 0:
            rng = max(self.R.get("fog_min_range", 1.0), rng * fog)
        return rng

    def deploy(self, key):
        cid = self.cid_of(key)
        row = self.C[cid]
        occupied = {u.cell for u in self.units}
        rng = self.unit_range(row)
        M = self.map
        best, best_score, best_path = None, -1, ""
        if row["placement"] == "path":
            for P in M.paths[:1]:
                for cell in sorted(P.path_cells()):
                    if cell in occupied:
                        continue
                    prog = P.progress_of_cell(cell)
                    if prog < 3 or prog > P.length - 1.5:
                        continue
                    score = sum(1 for u in self.units if u.row["placement"] != "path" and in_ivs(prog, u.ivs.get(P.pid, ())))
                    score = score * 100 + prog
                    if score > best_score:
                        best, best_score, best_path = cell, score, P.pid
        else:
            share = 1.0 / len(M.paths)
            for cell in M.placeable:
                if cell in occupied:
                    continue
                score = 0.0
                for P in M.paths:
                    for a, b in P.coverage(cell[0], cell[1], rng):
                        p = a
                        while p < b:
                            n = sum(1 for u in self.units if u.row["placement"] != "path" and in_ivs(p, u.ivs.get(P.pid, ())))
                            score += share * SAMPLE_STEP * 4 / (1 + n)
                            p += SAMPLE_STEP * 4
                if cid == "marisa":
                    score += 0.5 * max(self._beam_len(cell, d) for d in DIRS)
                if score > best_score + 1e-9:
                    best, best_score = cell, score
        if best is None:                      # 没有空格可放了
            return None
        u = Unit(key=key, cid=cid, row=row, cell=best, meta_level=self.meta.get(cid, 1),
                 copy_index=int(key.split("#")[1]) if "#" in key else 1)
        u.rng = rng
        u.ivs = {P.pid: P.coverage(best[0], best[1], rng) for P in M.paths}
        if num(row["max_hp"]) > 0:
            m = meta_attack_mult(u.meta_level, self.R["meta_attack_per_level"]) if self.R.get("meta_hp_scaling", 0) else 1
            u.maxhp = u.hp = num(row["max_hp"]) * m
            P = next(p for p in M.paths if p.pid == (best_path or M.paths[0].pid))
            u.block_progress = P.progress_of_cell(best)
            u.block_path = P.pid
        self.units.append(u)
        if self.caster is None:
            self.choose_caster(force=True)
        return u

    def preferred_caster(self):
        cands = [u for u in self.units if u.copy_index == 1]
        if self.force_caster:
            cands = [u for u in cands if u.cid == self.force_caster] or cands
        if not cands:
            return None
        return min(cands, key=lambda u: (num(u.row["caster_priority"], 9), self.units.index(u)))

    def choose_caster(self, force=False):
        """方案 A+（PR #4）：布阵期和波次空档可以换符卡使。换人时充能清零（caster_switch_clears_charge），
        所以模拟里的玩家只在「还没有符卡使」或「刚放完、能量 ≤ 15%」时才换成更合适的人。"""
        best = self.preferred_caster()
        if best is None or best is self.caster:
            return
        if self.caster is None or force:
            self.caster = best
            return
        if self.energy <= 0.15 * self.energy_max():
            if self.R.get("caster_switch_clears_charge", 1):
                self.energy = 0.0
                self.cycle = dict(start=self.t, normal=0.0, crisis=0.0, dmg=0.0, kill=0.0)
            self.caster = best
            self.caster_switches += 1

    def energy_max(self):
        if self.caster is None:
            return self.R.get("spell_energy_max_default", 100)
        return num(self.caster.row["spell_energy_max"], 100)

    def _beam_len(self, cell, d):
        return sum(sum(1 for (x, y) in P.samples if _in_beam(cell, d, x, y)) * SAMPLE_STEP for P in self.map.paths)

    # ---------------- 伤害流水线（PR #4 damage_and_status.md 第 2 节）
    def attack_power(self, u: Unit, coef=1.0):
        """① 攻击力 = 基础 × 局外等级倍率 × 局内等级倍率 × 技能系数 × Π(1 + 同类加成之和)。"""
        base = num(u.row["attack"])
        buff = self.mod["atk_pct"]
        aura = 0.0
        temp = self.mod["combo"]
        return (base * meta_attack_mult(u.meta_level, self.R["meta_attack_per_level"])
                * upgrade_mult(u.upgrades, self.R["upgrade_attack_pct"]) * coef
                * (1 + buff) * (1 + aura) * (1 + temp))

    def interval(self, u):
        aspd_temp = self.temp_aspd[0] if self.t < self.temp_aspd[1] else 0.0
        return num(u.row["attack_interval"]) * max(0.3, 1 + self.mod["aspd_pct"]) / (1 + aspd_temp)

    def barrier_vuln(self, e: Enemy) -> float:
        """灵梦结界（易伤桶）。大结界叠到质变层数后：灵梦射程内的路线常驻结界，易伤再加一点。"""
        k = self.K["st_barrier_mark"]["vulnerability_add"]
        if self.transformed("buff_great_barrier"):
            if any(u.cid == "reimu" and self.covers(u, e) for u in self.units):
                return k + num(self.buff_row("buff_great_barrier").get("value"), 0.1)
        if not self.zones:
            return 0.0
        x, y = _pos(e)
        return k if any(abs(x - cx) <= 1.5 and abs(y - cy) <= 1.5 for cx, cy, until, _ in self.zones) else 0.0

    def charge_mult(self):
        return (self.R["crisis_charge_mult"] if self.crisis else 1.0) * (1 + self.mod["energy_pct"])

    def add_energy(self, amount, kind):
        mx = self.energy_max()
        if self.energy >= mx:
            return
        amount *= self.charge_mult()
        self.cycle[kind] += min(amount, mx - self.energy)
        self.energy = min(mx, self.energy + amount)

    def hit(self, e: Enemy, attack, u: Unit | None = None, can_crit=True, spell=False, dot=False, syn=0.0, depth=0):
        if not e.alive or self.t < e.invuln_until:
            return 0
        a = attack
        crit = False
        was_frozen = self.t < e.frozen_until
        # ② 暴击（持续伤害不暴击）
        if can_crit and not dot and u is not None:
            chance = num(u.row.get("crit_chance"), self.R.get("crit_chance_default", 0.05)) + self.mod["crit_add"]
            if self.crit_rng.random() < chance:
                a *= num(u.row.get("crit_mult"), self.R.get("crit_mult_default", 1.8))
                crit = True
        # ③ 护甲
        armor = max(0.0, e.armor - self.mod["armor_pen"])
        # ④ 易伤桶 × 联动桶
        vuln = self.barrier_vuln(e)
        if e.boss:
            syn += self.mod["boss_dmg"]
        if u is not None and u.cid == "marisa" and self.t < e.frozen_until:
            syn += self.K["syn_ice_shatter"]["synergy_add"]
            e.frozen_until = self.t                      # 冰碎：解除冻结 + 1.5 秒冻结免疫
            e.freeze_immune_until = self.t + 1.5
        # ⑤ 取整且最少 1
        final = final_damage(a, armor, vuln, syn, self.R["armor_floor_ratio"], self.R.get("min_damage", 1))
        eff = min(final, e.hp)                           # 有效伤害（不算溢出）
        e.hp -= final
        if e.is_chapter_boss and e.hp > 1e-9:            # PR #4：Boss 到换阶段血线时卡住，无敌 1.5 秒并停步
            ratios = [float(x) for x in str(self.R.get("boss_phase_hp_ratios", "0.66|0.33")).split("|") if x]
            if e.phase <= len(ratios) and e.hp <= ratios[e.phase - 1] * e.maxhp:
                eff -= max(0.0, ratios[e.phase - 1] * e.maxhp - e.hp)
                e.hp = ratios[e.phase - 1] * e.maxhp
                e.phase += 1
                e.invuln_until = self.t + self.R.get("boss_phase_invuln_sec", 1.5)
        if u is not None:
            if spell:
                u.spell_damage += eff
            else:
                u.damage_done += eff
        if not spell:
            self.normal_damage += eff
            self.add_energy(eff * self.per_damage, "dmg")
        if e.hp <= 1e-9:
            e.alive = False
            gain = e.reward + self.mod["kill_spirit_flat"]
            self.spirit += gain
            self.spirit_earned += gain
            if not spell:
                self.normal_kills += 1
                self.add_energy(e.charge_on_kill * self.R.get("spell_charge_per_kill_scale", 1.0), "kill")
            if e.blocked_by is not None and e in e.blocked_by.blocked:
                e.blocked_by.blocked.remove(e)
            if was_frozen and depth < 3 and self.transformed("buff_frost_frog"):   # 质变「青蛙冰雕」
                self._burst(e, attack * num(self.buff_row("buff_frost_frog").get("value2"), 0.5), u, 1.0, depth + 1, freeze=1.0)
        if crit and depth < 1 and self.transformed("buff_crit_charm"):              # 质变「必中之符」
            self._burst(e, attack * num(self.buff_row("buff_crit_charm").get("value2"), 0.4), u, 0.8, depth + 1)
        return eff

    def _burst(self, center: Enemy, attack, u, radius, depth, freeze=0.0):
        cx, cy = _pos(center)
        for o in [x for x in self.enemies if x.alive and x is not center]:
            if math.hypot(*_sub(_pos(o), (cx, cy))) <= radius:
                self.hit(o, attack, u, can_crit=False, depth=depth)
                if freeze and o.alive:
                    self.freeze(o, freeze)

    def freeze(self, e: Enemy, dur, ignore_immunity=False, boss_slow=0.5):
        t = self.t
        if e.boss:
            self.slow(e, boss_slow, dur)
            return
        if not ignore_immunity and t < e.freeze_immune_until and t >= e.frozen_until:
            return
        e.frozen_until = max(e.frozen_until, t + dur)
        e.freeze_immune_until = e.frozen_until + 1.5

    def slow(self, e: Enemy, amt, dur):
        t = self.t
        amt = min(amt, self.K["st_slow"]["max_strength"])
        if t < e.slow_until and e.slow_amt > amt:
            return
        e.slow_amt = amt
        e.slow_until = t + dur

    def apply_burn(self, e: Enemy, u: Unit, dur):
        a = self.attack_power(u) * self.K["st_burn"]["tick_damage_coef"]
        if self.t < e.burn_until and e.burn_atk > a:
            return
        if not (self.t < e.burn_until):
            e.burn_next = self.t + self.R["burn_tick_sec"]
        e.burn_atk, e.burn_until, e.burn_src = a, self.t + dur, u

    # ---------------- 刷怪
    def build_waves(self):
        """每波威胁预算 (10 + 4 × 波次) × 系数，按本关参考组成换成敌人个数（余数滚到下一波）。
        Boss 不占预算（PR #5），在 boss_wave 那一波额外加入。fast_from_wave 之前的快残影份额并入小残影。"""
        L = self.level
        waves = int(L["wave_count"])
        coef = num(L["threat_budget_coef"], 1)
        mix = {MIX_PREFIX + k: num(L.get("ref_mix_" + k)) for k in MIX_KEYS}
        fast_from = int(num(L.get("fast_from_wave"), 1) or 1)
        carry = {k: 0.0 for k in mix}
        plan = []
        for w in range(1, waves + 1):
            budget = wave_budget(w, self.R["budget_base"], self.R["budget_per_wave"], coef)
            is_boss_wave = bool(L["boss_enemy_id"]) and int(num(L["boss_wave"])) == w
            lst = []
            if is_boss_wave:
                lst.append(L["boss_enemy_id"])
                budget -= num(self.E[L["boss_enemy_id"]]["threat_points"])
            budget = max(budget, 0)
            m = dict(mix)
            if w < fast_from and m.get(FAST_ID, 0) > 0:
                m[BASIC_ID] = m.get(BASIC_ID, 0) + m[FAST_ID]
                m[FAST_ID] = 0
            for k, share in m.items():
                if share <= 0:
                    continue
                th = num(self.E[k]["threat_points"])
                exact = budget * share / th + carry[k]
                n = int(exact)
                carry[k] = exact - n
                lst += [k] * n
            self.rng.shuffle(lst)
            lst.sort(key=lambda k: 1 if self.E[k]["category"] == "boss" else 0)
            plan.append(lst)
        return plan

    def spawn(self, eid, wave):
        r = self.E[eid]
        hp = num(r["hp"]) * (self.hp_mult if (r["category"] != "boss" or self.R.get("boss_hp_uses_level_mult", 1)) else 1.0)
        paths = self.map.paths
        P = paths[self.spawn_count % len(paths)]          # 多条路线：轮流分配
        self.spawn_count += 1
        e = Enemy(eid=eid, hp=hp, maxhp=hp, armor=num(r["armor"]), speed=num(r["move_speed_cells_per_sec"]),
                  reward=num(r["spirit_drop"]), leak=num(r["leak_damage"]), block_dps=num(r["block_dps"]),
                  flying=r["flying"] == "1", boss=r["category"] in ("boss", "elite"), wave=wave, path=P,
                  charge_on_kill=num(r.get("kill_charge")))
        e.is_chapter_boss = r["category"] == "boss"
        self.enemies.append(e)
        return e

    def update_terrain(self, w):
        """Boss 符卡改出来的冰面（PR #5 ch1_04）：按波次换冰面格子；第 2 阶段宣言时冰上的敌人先停住。"""
        cells = set()
        for ph in self.map.ice_phases:
            if ph["from_wave"] <= w <= ph["to_wave"]:
                cells = {tuple(c) for c in ph["cells"]}
                if w == ph["from_wave"] and ph["phase"] != "phase_1":
                    stop = self.R.get("ice_stop_on_declare_sec", 0)
                    for e in self.enemies:
                        if e.alive and self.cell_of(e) in cells:
                            e.stun_until = max(e.stun_until, self.t + stop)
        self.ice_cells = cells

    @staticmethod
    def cell_of(e):
        x, y = _pos(e)
        return (round(x), round(y))

    # ---------------- 主循环
    def run(self):
        plan = self.build_waves()
        pick_waves = {int(x) for x in self.level["buff_pick_waves"].split("|") if x}
        self.try_buy()  # 开局准备（不计时）
        n_waves = len(plan)
        for w, lst in enumerate(plan, start=1):
            self.current_wave = w
            self.update_terrain(w)
            self.try_buy()
            self.choose_caster()   # 波次开始前可以换符卡使（方案 A+）；换人充能清零
            wave_start = self.t
            hp_before = self.base_hp
            wave_enemies = []
            queue = list(lst)
            window = min(self.R["wave_spawn_window_max"],
                         self.R["wave_spawn_window_base"] + self.R["wave_spawn_window_per_wave"] * w)
            weights = [math.sqrt(max(0.25, num(self.E[k]["threat_points"]))) for k in queue]
            unit_gap = window / max(1e-9, sum(weights)) if weights else 0
            gaps = [unit_gap * x for x in weights]
            next_spawn = self.t
            last_spawn_t = self.t
            while True:
                if queue and self.t >= next_spawn - 1e-9:
                    eid = queue.pop(0)
                    wave_enemies.append(self.spawn(eid, w))
                    next_spawn = self.t + gaps.pop(0)
                    last_spawn_t = self.t
                self.step()
                if not queue:
                    if all((not e.alive) or e.is_chapter_boss for e in wave_enemies):
                        break
                    if self.t - last_spawn_t >= self.R["wave_force_next_after_spawn"]:
                        break
            wait_until = self.t + self.R["wave_gap_after_clear"]
            leaks = sum(1 for e in wave_enemies if e.leaked)
            self.spirit += self.R["wave_clear_bonus"]
            self.spirit_earned += self.R["wave_clear_bonus"]
            # 打完最后一波直接结算，不再给三选一（制作人定）。
            # 等于总波数的那一次本来就不影响当关结果，这里连计数也不做。
            if w in pick_waves and w < n_waves:
                self.buff_offers += 1
                self.pick_buff()
            if w < n_waves:
                while self.t < wait_until:
                    self.step()
            self.wave_log.append(dict(wave=w, enemies=len(wave_enemies), leaked_count=leaks,
                                      hp_lost=hp_before - self.base_hp,
                                      duration=round(self.t - wave_start, 1), spirit_after=round(self.spirit)))
        # 最后一波刷完：要把场上的敌人（包括还在绕圈的 Boss）打完才算打完
        guard = 0
        while any(e.alive for e in self.enemies) and self.base_hp > 0 and guard < 6000:
            self.step()
            guard += 1
        if any(e.alive for e in self.enemies) and self.base_hp > 0:
            self.boss_timeout = True
        return self.result()

    def _leak(self, e: Enemy):
        if e.is_chapter_boss and self.R.get("boss_on_reach_guard", "leak_then_loop") == "leak_then_loop":
            e.progress = 0.0                     # PR #4 loop_to_spawn：扣血后回到起点再走
            e.loops += 1
            e.leaked = True
        else:
            e.alive = False
            e.leaked = True
        if self.t < self.guard_invuln_until:
            return
        if self.guard_shield > 0:
            self.guard_shield -= 1
            return
        dmg = e.leak
        if self.mod["leak_reduce"]:
            dmg = max(1, dmg - self.mod["leak_reduce"])
        self.base_hp -= dmg
        self.min_hp_seen = min(self.min_hp_seen, self.base_hp)

    def step(self):
        self.try_buy()
        t = self.t
        dt = DT
        ts = t < self.timestop_until
        alive = [e for e in self.enemies if e.alive]
        if alive:
            self.active_time += dt
        self.zones = [z for z in self.zones if z[2] > t]
        # 危急：有敌人进入最后 3 行，或守护点生命 ≤ 30%
        edge = GRID_H - self.R["crisis_rows_from_bottom"] - 0.5
        self.crisis = (self.base_hp <= self.R["crisis_guard_hp_ratio"] * self.R["base_hp"]
                       or any(_pos(e)[1] >= edge for e in alive))
        if self.energy < self.energy_max() and self.caster is not None:
            self.cycle["crisis" if self.crisis else "normal"] += dt
        # 1) 角色状态
        for u in self.units:
            if u.cid == "mokou" and u.down_until > 0 and t >= u.down_until and u.hp <= 0:
                u.hp = u.maxhp
        # 2) 敌人移动与阻挡；灼烧跳伤
        for e in alive:
            if t < e.burn_until and t >= e.burn_next - 1e-9:
                e.burn_next += self.R["burn_tick_sec"]
                self.hit(e, e.burn_atk, e.burn_src, can_crit=False, dot=True)
                if not e.alive:
                    continue
            if e.blocked_by is not None:
                b = e.blocked_by
                if b.hp <= 0 or b.retreated:
                    e.blocked_by = None
                elif not ts:
                    b.hp -= e.block_dps * dt
                    if b.hp <= 0:
                        self._blocker_down(b)
                    continue
                else:
                    continue
            if (ts and not e.boss) or t < e.frozen_until or t < e.stun_until or t < e.invuln_until:
                continue
            slow = e.slow_amt if t < e.slow_until else 0.0
            if ts and e.boss:
                slow = max(slow, self.K["sc_the_world"]["boss_slow_strength"])
            terrain = self.R.get("ter_ice_speed_mult", 1.5) if (self.ice_cells and self.cell_of(e) in self.ice_cells) else 1.0
            v = e.speed * min(2.0, max(0.5 if e.boss else 0.3, 1 - slow) * terrain)   # PR #4：移速倍率 0.3–2.0（Boss 最低 0.5）
            p0 = e.progress
            p1 = p0 + v * dt
            if not e.flying:
                for b in self.units:
                    if (b.maxhp > 0 and b.hp > 0 and not b.retreated and b.block_path == e.path.pid
                            and p0 < b.block_progress <= p1):
                        cap = int(num(b.row["block_count"]))
                        b.blocked = [x for x in b.blocked if x.alive and x.blocked_by is b]
                        if len(b.blocked) < cap:
                            p1 = b.block_progress
                            e.blocked_by = b
                            b.blocked.append(e)
                            break
            e.progress = p1
            if e.progress >= e.path.length:
                self._leak(e)
        alive = sorted((e for e in self.enemies if e.alive), key=lambda e: -e.progress)
        # 3) 符卡：能量满后按释放方式放（manual = 合理的手动玩家；auto = 自动释放开关打开，PR #4 条件）
        full = self.caster is not None and self.energy >= self.energy_max() - 1e-9
        if full and self.full_since is None:
            self.full_since = t
        if full and alive and self.want_cast(alive, t):
            if self.cast(self.caster, alive):
                c = self.cycle
                self.cycles.append(dict(sec=round(c["normal"] + c["crisis"], 1), crisis=round(c["crisis"], 1),
                                        dmg=c["dmg"], kill=c["kill"], emax=self.energy_max(),
                                        caster=self.caster.cid))
                self.casts.append((t, self.caster.cid))
                self.energy = 0.0
                if self.transformed("buff_spell_battery"):
                    self.energy = self.energy_max() * num(self.buff_row("buff_spell_battery").get("value2"), 0.25)
                self.full_since = None
                self.ready_since = None
                self.cycle = dict(start=t, normal=0.0, crisis=0.0, dmg=0.0, kill=0.0)
                alive = sorted((e for e in self.enemies if e.alive), key=lambda e: -e.progress)
        # 4) 技能（PR #4：灵梦结界、琪露诺冰结、慧音护盾）
        for u in self.units:
            if u.retreated or (u.maxhp > 0 and u.hp <= 0):
                continue
            if u.cid in ("reimu", "cirno", "keine"):
                u.skill_cd -= dt
                if u.skill_cd <= 0:
                    self.use_skill(u, alive)
        # 5) 普攻
        for u in self.units:
            if u.retreated or (u.maxhp > 0 and u.hp <= 0) or num(u.row["attack"]) <= 0:
                continue
            u.cooldown -= dt
            if u.cooldown > 0:
                continue
            target = None
            for e in alive:
                if e.alive and self.covers(u, e):
                    target = e
                    break
            if target is None:
                u.cooldown = 0
                continue
            a = self.attack_power(u)
            eff = u.row["normal_effect"]
            syn = 0.0
            if eff == "bonus_vs_fast" and target.speed >= num(u.row["normal_effect_param"], 1.4):
                syn = self.K["syn_aya_vs_fast"]["synergy_add"]
            self.hit(target, a, u, syn=syn)
            u.hits += 1
            if u.hits % 5 == 0 and self.transformed("buff_rapid_fire"):     # 质变「三连发」：每第 5 次多打几发
                for _ in range(int(num(self.buff_row("buff_rapid_fire").get("value2"), 1))):
                    if target.alive:
                        self.hit(target, a, u, syn=syn)
            if eff == "slow_on_hit" and target.alive:
                self.slow(target, num(u.row["normal_effect_value"]), num(u.row["normal_effect_param"]))
            if u.cid == "mokou" and target.alive:
                self.apply_burn(target, u, 3.0)
            tx, ty = _pos(target)
            if eff == "splash":
                for e in alive:
                    if e is not target and e.alive:
                        x, y = _pos(e)
                        if math.hypot(x - tx, y - ty) <= num(u.row["normal_effect_param"]):
                            self.hit(e, a * num(u.row["normal_effect_value"]), u)
                            if u.cid == "mokou" and e.alive:
                                self.apply_burn(e, u, 3.0)
            # 强化：分裂、穿透、寒气
            if self.mod["split"] or self.mod["pierce"]:
                near = [e for e in alive if e is not target and e.alive
                        and math.hypot(*_sub(_pos(e), (tx, ty))) <= 1.0]
                for e in near[: self.mod["split"]]:
                    self.hit(e, a * self.split_ratio, u)
                behind = [e for e in near if e.progress < target.progress]
                if u.row["placement"] != "path" and u.cid != "marisa":
                    for e in behind[: self.mod["pierce"]]:
                        self.hit(e, a, u)
            if self.mod["freeze_chance"] and target.alive and self.rng.random() < self.mod["freeze_chance"]:
                self.freeze(target, 1.0)
            u.cooldown += self.interval(u)
            alive = [e for e in alive if e.alive]
        self.t = round(t + dt, 6)

    def want_cast(self, alive, t) -> bool:
        rows_edge = GRID_H - self.R["crisis_rows_from_bottom"] - 0.5
        in_last_rows = any(_pos(e)[1] >= rows_edge for e in alive)
        if self.spell_mode == "auto":
            return len(alive) >= self.R["auto_release_min_enemies"] or in_last_rows
        cond = (self.crisis or any(e.is_chapter_boss for e in alive)
                or len(alive) >= self.R.get("manual_release_min_enemies", 6)
                or (t - self.full_since >= self.R.get("manual_release_wait_sec", 8) and len(alive) >= 3))
        if not cond:
            self.ready_since = None
            return False
        if self.ready_since is None:
            self.ready_since = t
        return t - self.ready_since >= self.R.get("manual_release_reaction_sec", 1) - 1e-9

    def use_skill(self, u: Unit, alive):
        tgt = [e for e in alive if e.alive and self.covers(u, e)]
        if u.cid == "reimu":
            if not tgt:
                u.skill_cd = 0
                return
            if any(z[3] == u.key for z in self.zones):
                u.skill_cd = 0.5
                return
            x, y = _pos(tgt[0])
            self.zones.append((round(x), round(y), self.t + 6.0 + self.mod["barrier_plus"], u.key))
            u.skill_cd = 8.0 if u.upgrades >= 2 else 10.0
        elif u.cid == "cirno":
            if not tgt:
                u.skill_cd = 0
                return
            x, y = _pos(tgt[0])
            for e in alive:
                if math.hypot(*_sub(_pos(e), (x, y))) <= 0.8:
                    self.freeze(e, 1.5)
            u.skill_cd = 5.0 if u.upgrades >= 2 else 6.0
        elif u.cid == "keine":
            cap = 3 if u.upgrades >= 2 else 2
            self.guard_shield = min(cap, self.guard_shield + 1)
            u.skill_cd = 16.0 if u.upgrades >= 1 else 20.0

    def _blocker_down(self, b: Unit):
        for e in b.blocked:
            e.blocked_by = None
        b.blocked = []
        b.hp = 0
        b.retreated = True
        b.down_until = self.t + self.R["blocker_redeploy_cooldown"]

    def _densest(self, alive, radius):
        best, bn = None, -1
        for c in alive:
            cx, cy = _pos(c)
            n = sum(1 for e in alive if math.hypot(*_sub(_pos(e), (cx, cy))) <= radius)
            if n > bn or (n == bn and c.progress > best[2]):
                best, bn = (cx, cy, c.progress), n
        return best

    # ---------------- 符卡（按 PR #4 的默认符卡行为，系数来自 combat_coefficients.csv）
    def cast(self, u: Unit, alive) -> bool:
        sc = u.row["spell_card_id"]
        k = self.K.get(sc, {})
        sp = 1 + self.mod["spell_power"]
        a = self.attack_power(u)
        t = self.t
        alive = [e for e in alive if e.alive]
        if not alive:
            return False
        if sc == "sc_fantasy_seal":
            for i in range(int(k["orb_count"])):
                live = sorted((e for e in alive if e.alive), key=lambda e: -e.hp)
                if not live:
                    break
                tgt = live[i % len(live)] if i < len(live) else live[0]
                tx, ty = _pos(tgt)
                self.hit(tgt, a * k["damage_coef"] * sp, u, spell=True)
                for e in live:
                    if e is not tgt and e.alive and math.hypot(*_sub(_pos(e), (tx, ty))) <= 0.8:
                        self.hit(e, a * k["damage_coef"] * k["splash_coef"] * sp, u, spell=True)
            return True
        if sc == "sc_master_spark":
            best, bs, bl = None, -1, []
            for d in DIRS8:
                hits = [e for e in alive if _in_beam(u.cell, d, *_pos(e), half_width=0.8)]
                s = sum(1 + e.progress / e.path.length for e in hits)
                if s > bs:
                    best, bs, bl = d, s, hits
            if not bl:
                return False
            for _ in range(int(k["ticks"])):
                for e in bl:
                    if e.alive:
                        self.hit(e, a * k["damage_coef_per_tick"] * sp, u, spell=True)
            return True
        if sc == "sc_perfect_freeze":
            cx, cy, _ = self._densest(alive, k["radius_cells"])
            for e in alive:
                if math.hypot(*_sub(_pos(e), (cx, cy))) <= k["radius_cells"]:
                    self.hit(e, a * k["damage_coef"] * sp, u, spell=True)
                    if e.alive:
                        self.freeze(e, k["freeze_sec"] * sp, ignore_immunity=True, boss_slow=k["boss_slow_strength"])
            return True
        if sc == "sc_the_world":
            self.timestop_until = t + k["duration_sec"] * sp
            return True
        if sc == "sc_evil_sealing_circle":
            tgt = [e for e in alive if self.covers(u, e)]
            if not tgt:
                return False
            for e in tgt:
                self.slow(e, k["slow_strength"], k["duration_sec"] * sp)
            return True
        if sc == "sc_rainbow_dance":
            near = [e for e in alive if math.hypot(*_sub(_pos(e), u.cell)) <= 2.0]
            if not near:
                return False
            for e in near:
                self.hit(e, a * k["damage_coef"] * sp, u, spell=True)
                if e.alive and not e.boss:
                    if e.blocked_by is not None and e in e.blocked_by.blocked:
                        e.blocked_by.blocked.remove(e)
                    e.blocked_by = None
                    e.progress = max(0.0, e.progress - k["knockback_cells"])
            return True
        if sc == "sc_modoribashi":
            seg = [e for e in alive if e.progress >= e.path.length - 5 and not e.boss]
            if not seg:
                return False
            for e in seg:
                if e.blocked_by is not None and e in e.blocked_by.blocked:
                    e.blocked_by.blocked.remove(e)
                e.blocked_by = None
                e.progress = max(0.0, e.progress - k["send_back_cells"])
            return True
        if sc == "sc_phoenix_wings":
            for e in list(alive):
                self.hit(e, a * k["damage_coef"] * sp, u, spell=True)
                if e.alive:
                    self.apply_burn(e, u, 4.0)
            return True
        if sc == "sc_gensou_fuubi":
            for _ in range(2):
                for e in list(alive):
                    self.hit(e, a * k["damage_coef"] * sp, u, spell=True)
            return True
        if sc == "sc_gray_thaumaturgy":
            centers = []
            for _ in range(5):
                live = [e for e in alive if e.alive]
                if not live:
                    break
                cand = [e for e in live if all(math.hypot(*_sub(_pos(e), c)) > 1.2 for c in centers)] or live
                cx, cy, _p = self._densest(cand, 1.2)
                centers.append((cx, cy))
                for e in live:
                    if math.hypot(*_sub(_pos(e), (cx, cy))) <= 1.2:
                        self.hit(e, a * k["damage_coef"] * sp, u, spell=True)
            return True
        if sc == "sc_spiriting_away":
            normal = sorted((e for e in alive if not e.boss), key=lambda e: -e.progress)[: int(k["max_targets"])]
            for e in normal:
                if e.blocked_by is not None and e in e.blocked_by.blocked:
                    e.blocked_by.blocked.remove(e)
                e.blocked_by = None
                e.progress = self.rng.random()
                e.stun_until = t + 1.0
            for e in alive:
                if e.boss:
                    self.slow(e, k["boss_slow_strength"], 4.0)
            return True
        if sc == "sc_morning_mist":
            self.temp_aspd = (0.3, t + 8.0)
            return True
        return False

    # ---------------- roguelite 三选一
    def buff_row(self, bid):
        return self._buff_by_id.get(bid, {})

    def transform_at(self, b) -> int:
        return int(num(b.get("transform_at_stacks"), 0))

    def transformed(self, bid) -> bool:
        b = self._buff_by_id.get(bid)
        return bool(b) and self.transform_at(b) > 0 and self.buff_stacks.get(bid, 0) >= self.transform_at(b)

    def pick_buff(self):
        """每 5 波三选一，但打完最后一波不再给。保底：已拥有但还没质变的强化，这次必出其中一个（制作人定）。
        模拟玩家：生命 ≤ 10 且有「修补」先拿；否则有能凑成质变的就拿（质变很强）；再按优先级表。"""
        owned = {self.C[c]["combat_id"] for c in self.lineup}
        pool = []
        for b in self.B:
            if b["requires_character"] and b["requires_character"] not in owned:
                continue
            if self.buff_stacks.get(b["buff_id"], 0) >= int(num(b["max_stacks"], 1)):
                continue
            pool.append(b)
        offer = []
        n = int(self.R["buff_offer_count"])
        if self.R.get("buff_guarantee_untransformed", 1):
            pending = [b for b in pool if self.transform_at(b) > 0 and 0 < self.buff_stacks.get(b["buff_id"], 0) < self.transform_at(b)]
            if pending:
                g = self._weighted(pending)
                offer.append(g)
                pool.remove(g)
                self.guaranteed_offers += 1
        while pool and len(offer) < n:
            b = self._weighted(pool)
            offer.append(b)
            pool.remove(b)
        if not offer:
            return
        if self.base_hp <= 10:
            for b in offer:
                if b["sim_effect"] == "base_heal":
                    return self.apply_buff(b)
        completes = [b for b in offer if self.transform_at(b) > 0
                     and self.buff_stacks.get(b["buff_id"], 0) + 1 == self.transform_at(b) and b["buff_id"] in self.buff_priority[:10]]
        if completes:
            return self.apply_buff(completes[0])
        offer.sort(key=lambda b: self.buff_priority.index(b["buff_id"]) if b["buff_id"] in self.buff_priority else 99)
        self.apply_buff(offer[0])

    def _weighted(self, lst):
        tot = sum(num(b["weight"]) for b in lst)
        r = self.rng.random() * tot
        for b in lst:
            r -= num(b["weight"])
            if r <= 0:
                return b
        return lst[-1]

    split_ratio = 0.30

    def apply_buff(self, b):
        bid = b["buff_id"]
        self.buff_stacks[bid] = self.buff_stacks.get(bid, 0) + 1
        stacks = self.buff_stacks[bid]
        self.picked.append(bid)
        if self.transform_at(b) and stacks == self.transform_at(b):
            self.transforms.append(bid)
        et, v = b["sim_effect"], num(b["value"])
        if et == "spirit_now":
            self.spirit += v
            self.spirit_earned += v
        elif et == "base_heal":
            self.base_hp = min(self.R["base_hp"], self.base_hp + v)
            if self.transformed(bid):
                self.mod["leak_reduce"] = int(num(b["value2"]))
        elif et == "split":
            self.mod["split"] += 1
            self.split_ratio = v
            if self.transformed(bid):
                self.mod["split"] = max(self.mod["split"], int(num(b["value2"], 6)))   # 满天星：6 颗环形
        elif et == "pierce":
            self.mod["pierce"] += int(v)
        elif et == "freeze_chance":
            self.mod["freeze_chance"] += v
        elif et == "barrier_plus":
            self.mod["barrier_plus"] += 2.0
        elif et == "combo":
            self.mod["combo"] = num(b["value2"]) / 2          # 连击狂热：按平均一半上限近似
        elif et == "upgrade_discount":
            self.mod["upgrade_discount"] += -v
        elif et == "none":
            pass
        elif et in self.mod:
            self.mod[et] += v

    # ---------------- 结果
    def result(self):
        units = {}
        for u in self.units:
            units[u.key] = dict(damage=u.damage_done, spell_damage=u.spell_damage, hits=u.hits, cell=u.cell,
                                upgrades=u.upgrades)
        deploy_done = max((p[0] for p in self.purchases if p[1] == "deploy" and "#" not in p[2]), default=0)
        all_up = [p[0] for p in self.purchases if p[1] == "up" and "#" not in p[2]]
        copies = sum(1 for p in self.purchases if p[1] == "deploy" and "#" in p[2])
        cleared = self.base_hp > 0 and not self.boss_timeout
        th = [float(x) for x in str(self.R.get("star_thresholds", "20|10|1")).split("|")]
        star = 0 if not cleared else (3 if self.base_hp >= th[0] - 1e-9 else 2 if self.base_hp >= th[1] - 1e-9 else 1)
        return dict(level_id=self.level["level_id"], hp_left=(self.base_hp if cleared else min(0, self.base_hp)),
                    min_hp=self.min_hp_seen, cleared=cleared, star=star, duration=round(self.t, 1), waves=self.wave_log,
                    spirit_earned=round(self.spirit_earned), spirit_spent=round(self.spirit_spent),
                    spirit_left=round(self.spirit), deploy_done_t=deploy_done,
                    all_upgraded_t=(max(all_up) if len(all_up) == 2 * len(self.lineup) else None),
                    n_upgrades=len(all_up), copies=copies, units=units, buffs=list(self.picked),
                    purchases=self.purchases, casts=list(self.casts), cycles=list(self.cycles),
                    active_time=round(self.active_time, 1), normal_damage=round(self.normal_damage),
                    normal_kills=self.normal_kills, per_damage=self.per_damage,
                    waves_clean=sum(1 for w in self.wave_log if w["leaked_count"] == 0),
                    boss_timeout=self.boss_timeout, boss_loops=sum(e.loops for e in self.enemies if e.is_chapter_boss),
                    buff_offers=self.buff_offers, guaranteed_offers=self.guaranteed_offers, transforms=list(self.transforms),
                    caster_switches=self.caster_switches, spell_mode=self.spell_mode, map_source=self.map.source)


DIRS = [(1, 0), (-1, 0), (0, 1), (0, -1)]
_S = 1 / math.sqrt(2)
DIRS8 = DIRS + [(_S, _S), (_S, -_S), (-_S, _S), (-_S, -_S)]
MIX_PREFIX = "enm_shade_"
MIX_KEYS = ("basic", "fast", "armored", "heavy", "swarm", "phantom")   # level_difficulty.csv 的 ref_mix_<key> = 敌人 ID enm_shade_<key>
BASIC_ID, FAST_ID = "enm_shade_basic", "enm_shade_fast"
EARLY_UPGRADE = {"reimu", "marisa", "sanae", "aya"}
UPGRADE_PRIORITY = ["marisa", "reimu", "sanae", "aya", "sakuya", "yukari", "mokou", "cirno", "meiling", "keine"]
DEFAULT_BUFF_PRIORITY = ["buff_sharp_ofuda", "buff_spell_battery", "buff_rapid_fire", "buff_boss_slayer",
                         "buff_crit_charm", "buff_armor_break", "buff_split_shot", "buff_piercing_star",
                         "buff_spell_power", "buff_great_barrier", "buff_frost_frog", "buff_combo_fever",
                         "buff_upgrade_discount", "buff_offering_box", "buff_spirit_greed", "buff_guard_mend",
                         "buff_gap_eye"]


def _cell_dist(a, b):
    return math.hypot(a[0] - b[0], a[1] - b[1])


def _sub(p, c):
    return (p[0] - c[0], p[1] - c[1])


def _in_beam(cell, d, x, y, half_width=0.5):
    dx, dy = x - cell[0], y - cell[1]
    along = dx * d[0] + dy * d[1]
    perp = abs(dx * d[1] - dy * d[0])
    return along > 0 and perp <= half_width
