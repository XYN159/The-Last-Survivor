# -*- coding: utf-8 -*-
"""整条战役的推演：按「只打首通、不刷关」的玩家，一关一关往下打。

每关：按剧情解锁角色 → 选阵容（去掉本关禁用的角色）→ 用每个角色各自的局外等级模拟
→ 发首通奖励（星星不给资源）→ 按分法花资源升级 → 下一关。
可选：自动校准每关的威胁预算系数（budget_coef），让模拟的首通剩余生命接近目标。

两种分资源的玩法（系统策划 PR #3 要求都验证不需要刷关）：
    even  = 每次给出战阵容里等级最低的人升 1 级（用来校准）
    focus = 只培养偏好最靠前的 3 人（config.FOCUS_COUNT），其他人停在加入时的等级
"""
from __future__ import annotations

import csv
import multiprocessing as mp
import os
import statistics as st

import config as C
import tdsim


def load_tables():
    return dict(rules=tdsim.load_rules(), chars=tdsim.load_characters(), enemies=tdsim.load_enemies(),
                buffs=tdsim.load_buffs(), levels=tdsim.load_levels(), coefs=tdsim.load_coefs(),
                costs={int(r["level"]): tdsim.num(r["cost_to_next"]) for r in tdsim.read_csv(tdsim.DATA / "progression" / "character_level_cost.csv")})


# 多进程：每个种子一局，并行跑（表在每个子进程里读一次）
_W = {}
_POOL = None


def _worker(args):
    L, lineup, meta, s, rules, join_wave, force_caster, spell_mode, enemies_override = args
    if not _W:
        _W.update(chars=tdsim.load_characters(), enemies=tdsim.load_enemies(), buffs=tdsim.load_buffs(),
                  coefs=tdsim.load_coefs())
    enemies = _W["enemies"]
    if enemies_override:
        enemies = {k: dict(v, **enemies_override.get(k, {})) for k, v in enemies.items()}
    b = tdsim.Battle(L, lineup, meta, seed=s, rules=rules, chars=_W["chars"], enemies=enemies,
                     buffs=_W["buffs"], coefs=_W["coefs"], join_wave=join_wave, force_caster=force_caster,
                     spell_mode=spell_mode)
    return b.run()


def _pool():
    """Linux/macOS 用 fork 多进程；Windows 没有 fork，返回 None，改为一个一个跑（结果完全一样，只是慢）。"""
    global _POOL
    if _POOL is None and "fork" in mp.get_all_start_methods():
        _POOL = mp.get_context("fork").Pool(max(1, min(len(C.SEEDS), os.cpu_count() or 1, 8)))
    return _POOL


def choose_squad(owned, cap, banned=()):
    squad = [c for c in C.SQUAD_PREFERENCE if c in owned and c not in banned][: int(cap)]
    return sorted(squad, key=C.DEPLOY_ORDER.index)


SCENARIOS = {
    # A：用户已确认的值（开局 150 灵力）+ 战斗策划 PR #4 的规则
    "confirmed": "start_spirit",
    # B：数值建议方案，只改一项：开局灵力随关卡递增 = 150 × √血量倍率；用和 A 一样的系数对比
    "proposed": "proposed_start_spirit",
}

# 解锁口径
#   story = 制作人定的方案 B（level_difficulty.csv 的 unlock_characters，和关卡策划 PR #5 最新分支一致）：
#           琪露诺通关 ch1_01 后加入（ch1_02 起可用），紫通关 ch1_04 后加入（ch2_01 起），美铃 ch2_02、咲夜 ch3_01、
#           慧音 ch3_02、妹红 ch4_01、早苗 ch5_01 起可用
UNLOCK_OVERRIDES = {}


def scenario_level(level, scenario):
    L = dict(level)
    L["start_spirit"] = level[SCENARIOS[scenario]]
    L["_scenario"] = scenario
    return L


def simulate_level(T, level, lineup, meta, seeds, coef=None, rules_override=None, join_wave=None, force_caster=None,
                   spell_mode=None, enemies_override=None):
    L = dict(level)
    if coef is not None:
        L["threat_budget_coef"] = f"{coef:.2f}"
    rules = dict(T["rules"])
    if rules_override:
        rules.update(rules_override)
    args = [(L, list(lineup), meta, s, rules, join_wave or {}, force_caster, spell_mode or C.SPELL_MODE, enemies_override)
            for s in seeds]
    if len(seeds) > 1 and _pool() is not None:
        return _pool().map(_worker, args)
    return [_worker(a) for a in args]


def charge_stats(res):
    """全队每秒有效伤害 D、每秒击杀 K（只算普攻/技能/灼烧，不算符卡；只算场上有敌人的时间）。"""
    act = sum(r["active_time"] for r in res) or 1
    return sum(r["normal_damage"] for r in res) / act, sum(r["normal_kills"] for r in res) / act


def per_damage_for(T, level, lineup, meta, seeds, coef):
    """PR #4 换算：每点伤害充能 = 70 ÷ (60 × D)。先用基准值跑一次拿到 D。"""
    L = dict(level)
    L["spell_charge_per_damage"] = ""
    res = simulate_level(T, L, lineup, meta, seeds, coef)
    d, _ = charge_stats(res)
    share = T["rules"]["spell_charge_damage_share"] * 100
    return float(f"{share / (T['rules']['spell_target_full_sec'] * max(d, 1e-6)):.3g}")


def mean_hp(res):
    return st.mean(r["hp_left"] for r in res)


def star_share(res, k):
    return sum(1 for r in res if r["star"] >= k) / len(res)


def boss_fix(level, rules):
    """数值建议的 Boss 方案（待拍板）：Boss 血量写的就是实战值（不乘关卡血量倍率），并改为倒数第 5 波入场。
    返回 (改过的关卡, 规则覆盖)。非 Boss 关原样返回。"""
    if not level.get("boss_wave"):
        return level, {}
    L = dict(level)
    L["boss_wave"] = str(int(L["wave_count"]) - int(rules.get("proposed_boss_enter_waves_from_end", 5)))
    return L, {"boss_hp_uses_level_mult": 0}


def calibrate(T, level, lineup, meta, target, rules_override=None, info=None):
    lo, hi = C.COEF_MIN, C.COEF_MAX
    cache = {}

    def f(c):
        c = round(c, 4)
        if c not in cache:
            cache[c] = mean_hp(simulate_level(T, level, lineup, meta, C.CALIBRATE_SEEDS, c, rules_override)) - target
        return cache[c]
    # 第 1 步（粗扫）：按 0.05 一格从 0.2 扫到 1.6。难度对系数不一定单调：系数太低时击杀少、灵力少，Boss 关反而更难，
    # 所以不找「最接近目标」的点，而是找「最大的、剩余生命还 ≥ 目标 − 1.5、而且左边一格也满足」的系数 c0
    # （第一章目标 13/12/11，−1.5 正好是 11–13 条命区间的下沿；「左边一格也满足」防止偶然的好种子）。
    step = C.COEF_ROUND
    band = 1.5
    grid = [round(lo + step * i, 2) for i in range(int(round((1.6 - lo) / step)) + 1)]
    while f(grid[-1]) > 0 and grid[-1] < hi:
        grid.append(round(grid[-1] + 0.2, 2))
    cand = [c for i, c in enumerate(grid) if f(c) >= -band and (i == 0 or f(grid[i - 1]) >= -band)]
    if not cand:
        best = max(grid, key=lambda x: (f(x), -x))
        return best, "unreachable"
    c0 = max(cand)
    if c0 == grid[-1]:
        return c0, "hit_max"
    fs, sm = C.CAL_FINE_STEP, C.CAL_SMOOTH
    if not fs:
        return c0, "ok"
    # 第 2 步（细扫）：MVP 只有 3–5 个预定槽位、编组固定，剩余生命随系数是锯齿状的（差 0.01 就能差 3–5 条命），单点靠不住。
    # 在 c0 左右 ±0.10 按 0.01 一格细扫，每个系数的「期望剩余生命」= 它左右 ±C.CAL_SMOOTH 内 5 个系数 × 5 个种子共 25 局的平均。
    # 选「期望 ≥ 目标 − 0.5」的最大系数；都不满足就选期望最高的。
    k = int(round(sm / fs))
    fine = [round(c0 - 0.10 + fs * i, 2) for i in range(int(round(0.20 / fs)) + 1)]
    fine = [c for c in fine if c >= lo]

    def g(c):
        pts = [round(c + fs * j, 2) for j in range(-k, k + 1) if c + fs * j >= lo - 1e-9]
        return sum(f(p) for p in pts) / len(pts)
    ok = [c for c in fine if g(c) >= -0.5]
    best = max(ok) if ok else max(fine, key=lambda x: (g(x), -x))
    drop = f(round(best + 0.05, 2))                     # 再加 0.05 会怎样：掉到目标以下 3 条命以上 = 台阶（cliff）
    if info is not None:
        info.update(smoothed_hp=round(g(best) + target, 1), coarse_coef=c0, plus005_hp=round(drop + target, 1))
    if g(best) < -band:
        return best, "short"
    return best, ("cliff" if drop < -3 else "ok")


def level_up_cost(levels, cid, T):
    lv = levels[cid]
    cost = T["costs"].get(lv, 0)
    if max(levels.values()) - lv >= C.CATCH_UP_GAP:
        cost *= C.CATCH_UP_DISCOUNT
    return cost


def spend(levels_meta, squad, fragments, T, alloc):
    """花资源升级，返回剩余资源。"""
    mx = int(T["rules"]["meta_level_max"])
    while True:
        if alloc == "focus":
            core = [c for c in C.SQUAD_PREFERENCE if c in levels_meta][: C.FOCUS_COUNT]
            pool = [c for c in core if levels_meta[c] < mx] or [c for c in squad if levels_meta[c] < mx]
        else:
            pool = [c for c in squad if levels_meta[c] < mx] or [c for c in levels_meta if levels_meta[c] < mx]
        if not pool:
            return fragments
        c = min(pool, key=lambda k: (levels_meta[k], C.SQUAD_PREFERENCE.index(k)))
        cost = level_up_cost(levels_meta, c, T)
        if fragments < cost:
            return fragments
        fragments -= cost
        levels_meta[c] += 1


def run_campaign(T, scenario="confirmed", do_calibrate=False, alloc="even", unlock="story", rules_override=None,
                 seeds=None, verbose=True, spell_mode=None, stop_after=None, spend_rule="pinned"):
    seeds = seeds or C.SEEDS
    rules = T["rules"]
    levels_meta: dict[str, int] = {}
    fragments = 0.0
    rows = []
    for raw_level in T["levels"]:
        level = scenario_level(raw_level, scenario)
        lid = level["level_id"]
        idx = int(level["level_index"])
        unl = [x for x in level["unlock_characters"].split("|") if x] + UNLOCK_OVERRIDES.get(unlock, {}).get(lid, [])
        for c in unl:
            if c not in levels_meta:
                levels_meta[c] = max(1, int(st.mean(levels_meta.values())) if levels_meta else 1)
        banned = [x for x in level.get("banned_characters", "").split("|") if x]
        squad = choose_squad(levels_meta, rules["squad_cap"], banned)
        meta = {c: levels_meta[c] for c in squad}
        coef = tdsim.num(level["threat_budget_coef"], 1.0)
        status = "table"
        smoothed = ""
        if do_calibrate:
            pd = per_damage_for(T, level, squad, meta, C.CALIBRATE_SEEDS, coef)
            level["spell_charge_per_damage"] = raw_level["spell_charge_per_damage"] = f"{pd:.3g}"
            # 系数和每点伤害充能互相影响：校准系数 → 按新系数下的 D 重算充能 → 再校准一次 → 再重算充能
            for _ in range(2):
                if lid in C.FIX_COEF:
                    coef, status = C.FIX_COEF[lid], "fixed"
                else:
                    info = {}
                    coef, status = calibrate(T, level, squad, meta, tdsim.num(level["target_hp_first_clear"]), info=info)
                    smoothed = info.get("smoothed_hp", "")
                level["threat_budget_coef"] = raw_level["threat_budget_coef"] = f"{coef:.2f}"
                pd = per_damage_for(T, level, squad, meta, C.CALIBRATE_SEEDS, coef)
                level["spell_charge_per_damage"] = raw_level["spell_charge_per_damage"] = f"{pd:.3g}"
        res = simulate_level(T, level, squad, meta, seeds, coef, rules_override, spell_mode=spell_mode)
        hp = mean_hp(res)
        cleared = hp > 0
        # 星星不给资源。模拟打输的关，按「从当前波重来后终究打过」发首通奖励（fail_seeds 会标出来）
        gain = tdsim.num(level["reward_first_clear"])
        fragments += gain
        meta_before = dict(meta)
        spend_to = C.SPEND_ONLY.get(lid, squad) if (spend_rule == "pinned" and alloc == "even") else squad
        fragments = spend(levels_meta, [c for c in spend_to if c in levels_meta], fragments, T, alloc)
        row = dict(scenario=scenario, alloc=alloc, unlock=unlock, start_spirit=tdsim.num(level["start_spirit"]),
                   level_index=idx, level_id=lid, role=level["level_role_zh"], waves=int(level["wave_count"]),
                   budget_coef=coef, calib=status, smoothed_hp=smoothed, hp_mult=tdsim.hp_multiplier(idx, rules["hp_mult_per_level"]),
                   target=tdsim.num(level["target_hp_first_clear"], 0), hp_mean=round(hp, 1),
                   hp_min=min(r["hp_left"] for r in res), hp_max=max(r["hp_left"] for r in res),
                   fail_seeds=sum(1 for r in res if not r["cleared"]), squad="|".join(squad),
                   meta_levels="|".join(f"{c}:{meta_before[c]}" for c in squad),
                   meta_avg=round(st.mean(meta_before.values()), 2),
                   star2=star_share(res, 2), star3=star_share(res, 3),
                   reward=gain, fragments_left=round(fragments),
                   meta_after=dict(levels_meta), results=res,
                   per_damage=res[0]["per_damage"], charge_d=charge_stats(res)[0], charge_k=charge_stats(res)[1])
        rows.append(row)
        if verbose:
            print(f"{idx:>2} {lid:<11} coef {coef:.2f} ({status}) hp {hp:5.1f} (目标 {row['target']:.0f}) "
                  f"min {row['hp_min']:5.1f} {row['meta_levels']}", flush=True)
        if stop_after and lid == stop_after:
            break
    return rows


def write_level_curve(T):
    path = tdsim.DATA / "balance" / "level_difficulty.csv"
    fields = list(T["levels"][0].keys())
    with open(path, "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator="\n")
        w.writeheader()
        w.writerows(T["levels"])
