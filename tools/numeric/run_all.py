# -*- coding: utf-8 -*-
"""一键：生成养成表 →（可选）校准威胁预算系数 → 模拟 24 关 → 输出报告。

用法（在仓库根目录）：
    python tools/numeric/run_all.py              # 用表里现有系数模拟并出报告，并重新生成 stats.json
    python tools/numeric/run_all.py --calibrate  # 先重新校准每关系数和每点伤害充能再出报告（8 核约 15–30 分钟）
    python tools/numeric/run_all.py --quick      # 只跑 1 个种子、不做敏感性分析，快速看一眼
"""
from __future__ import annotations

import csv
import math
import statistics as st
import sys
import time

import campaign
import config as C
import gen_progression
import tdsim

OUT = tdsim.ROOT / "tools" / "numeric" / "output"
DOC = tdsim.ROOT / "docs" / "design" / "numeric" / "generated"


def write_csv(path, rows, fields):
    path.parent.mkdir(parents=True, exist_ok=True)
    with open(path, "w", newline="", encoding="utf-8") as f:
        w = csv.DictWriter(f, fieldnames=fields, lineterminator="\n", extrasaction="ignore")
        w.writeheader()
        w.writerows(rows)


def early_share(row):
    lost = [sum(max(0, w["hp_lost"]) for w in r["waves"]) for r in row["results"]]
    early = [sum(max(0, w["hp_lost"]) for w in r["waves"][:5]) for r in row["results"]]
    return (sum(early) / sum(lost)) if sum(lost) > 0 else 0.0


def summarize(rows):
    out = []
    for r in rows:
        res = r["results"]
        out.append(dict(
            level_id=r["level_id"], level_index=r["level_index"], role=r["role"], waves=r["waves"],
            start_spirit=int(r["start_spirit"]), threat_budget_coef=f'{r["budget_coef"]:.2f}', calib=r["calib"],
            sim_hp_smoothed=r.get("smoothed_hp", ""),
            hp_multiplier=round(r["hp_mult"], 2), target_hp=r["target"], sim_hp_mean=r["hp_mean"],
            sim_hp_min=r["hp_min"], sim_hp_max=r["hp_max"], fail_seeds=r["fail_seeds"],
            star2_share=f'{r["star2"]:.0%}', star3_share=f'{r["star3"]:.0%}',
            clean_waves=round(st.mean(x["waves_clean"] for x in res), 1),
            early5_loss_share=f"{early_share(r):.0%}",
            duration_min=round(st.mean(x["duration"] for x in res) / 60, 1),
            sec_per_wave=round(st.mean(x["duration"] for x in res) / r["waves"], 1),
            boss_loops=round(st.mean(x["boss_loops"] for x in res), 2),
            spirit_earned=round(st.mean(x["spirit_earned"] for x in res)),
            spirit_left_end=round(st.mean(x["spirit_left"] for x in res)),
            upgrades_bought=round(st.mean(x["n_upgrades"] for x in res), 1),
            copies_bought=round(st.mean(x["copies"] for x in res), 1),
            transforms=round(st.mean(len(x["transforms"]) for x in res), 2),
            guaranteed_offers=round(st.mean(x["guaranteed_offers"] for x in res), 2),
            squad=r["squad"], meta_levels=r["meta_levels"], meta_avg=r["meta_avg"], reward=r["reward"]))
    return out


def cycle_summary(res_list):
    """符卡能量从 0 到满的实际秒数（模拟测量）。"""
    cyc = [c for r in res_list for c in r["cycles"]]
    if not cyc:
        return dict(n=0)
    normal = [c["sec"] * 100 / c["emax"] for c in cyc if c["crisis"] <= 0.1 * c["sec"]]
    crisis = [c["sec"] * 100 / c["emax"] for c in cyc if c["crisis"] >= 0.5 * c["sec"]]
    tot_d = sum(c["dmg"] for c in cyc)
    tot_k = sum(c["kill"] for c in cyc)
    return dict(n=len(cyc), all_sec=round(st.mean(c["sec"] for c in cyc), 1),
                normal_sec_per100=round(st.median(normal), 1) if normal else "",
                crisis_sec_per100=round(st.median(crisis), 1) if crisis else "",
                crisis_time_share=f'{sum(c["crisis"] for c in cyc) / max(1e-9, sum(c["sec"] for c in cyc)):.0%}',
                dmg_share=f"{tot_d / max(1e-9, tot_d + tot_k):.0%}")


def spell_stats(rows):
    """每关：每点伤害充能、D、K、实际充满秒数、伤害/击杀占比、每关释放次数。"""
    out = []
    for r in rows:
        cs = cycle_summary(r["results"])
        casters = {}
        for res in r["results"]:
            for _, cid in res["casts"]:
                casters[cid] = casters.get(cid, 0) + 1
        out.append(dict(level_id=r["level_id"], per_damage=f'{r["per_damage"]:.3g}', team_dps=round(r["charge_d"]),
                        kills_per_sec=round(r["charge_k"], 2), casts_per_level=round(sum(casters.values()) / len(r["results"]), 1),
                        casters="|".join(f"{k}:{v}" for k, v in sorted(casters.items(), key=lambda x: -x[1])),
                        full_sec_all=cs.get("all_sec", ""), full_sec_normal=cs.get("normal_sec_per100", ""),
                        full_sec_crisis=cs.get("crisis_sec_per100", ""), crisis_time_share=cs.get("crisis_time_share", ""),
                        damage_share=cs.get("dmg_share", "")))
    return out


def caster_stats(rows):
    """按符卡使汇总：满能量、平均充满秒数（换算到本人满能量）。"""
    chars = tdsim.load_characters()
    agg = {}
    for r in rows:
        for res in r["results"]:
            for c in res["cycles"]:
                agg.setdefault(c["caster"], []).append(c)
    out = []
    for cid, cyc in agg.items():
        normal = [c["sec"] for c in cyc if c["crisis"] <= 0.1 * c["sec"]]
        out.append(dict(name_zh=chars[cid]["name_zh"], spell=chars[cid]["spell_name_zh"],
                        energy_max=chars[cid]["spell_energy_max"], cycles=len(cyc),
                        full_sec_all=round(st.mean(c["sec"] for c in cyc), 1),
                        full_sec_normal=round(st.median(normal), 1) if normal else ""))
    return out


def mvp_waves(T, rows):
    out = []
    R = T["rules"]
    ids = [tdsim.MIX_PREFIX + k for k in tdsim.MIX_KEYS]
    for r in rows:
        lv = next(L for L in T["levels"] if L["level_id"] == r["level_id"])
        if lv["is_mvp"] != "1":
            continue
        L = campaign.scenario_level(lv, "confirmed")
        L["threat_budget_coef"] = f'{r["budget_coef"]:.2f}'
        b = tdsim.Battle(L, r["squad"].split("|"), {}, seed=1, rules=R, chars=T["chars"], enemies=T["enemies"], buffs=T["buffs"])
        plan = b.build_waves()
        for w, ev in enumerate(plan, start=1):
            lst = [x[1] for x in ev]
            losses = [x["waves"][w - 1]["hp_lost"] for x in r["results"] if len(x["waves"]) >= w]
            leaks = [x["waves"][w - 1]["leaked_count"] for x in r["results"] if len(x["waves"]) >= w]
            secs = [x["waves"][w - 1]["duration"] for x in r["results"] if len(x["waves"]) >= w]
            out.append(dict(level_id=r["level_id"], wave=w,
                            budget=round(tdsim.wave_budget(w, R["budget_base"], R["budget_per_wave"], r["budget_coef"]), 1),
                            n_basic=lst.count(ids[0]), n_fast=lst.count(ids[1]), n_armored=lst.count(ids[2]),
                            boss="琪露诺" if "boss_cirno" in lst else "",
                            enemy_hp_basic=round(60 * r["hp_mult"]),
                            wave_sec=round(st.mean(secs), 1) if secs else "",
                            avg_leaked=round(st.mean(leaks), 1) if leaks else "",
                            avg_hp_lost=round(st.mean(losses), 1) if losses else "",
                            buff_pick="是" if str(w) in lv["buff_pick_waves"].split("|") else ""))
    return out


def md_table(rows, cols, heads):
    s = "| " + " | ".join(heads) + " |\n| " + " | ".join("---" for _ in heads) + " |\n"
    for r in rows:
        s += "| " + " | ".join(str(r.get(c, "")).replace("|", "、") for c in cols) + " |\n"
    return s


def hp_of(res):
    return round(campaign.mean_hp(res), 1)


def meta_of(raw):
    return {kv.split(":")[0]: int(kv.split(":")[1]) for kv in raw["meta_levels"].split("|")}


# ch1_03 的硬残影（制作人定：硬残影进 MVP，只在 ch1_03 少量出现）。主版本的出场写在 level_difficulty.csv 的 extra_spawns 列：
# 「波次:只数:路线」，每只硬残影从同一路线扣掉 4 点威胁的小残影（左路）或快残影（右路），全关总预算不变。
# 下面几种写法只做对照（每种都重新校准系数）。
ARMORED_SPECS = [
    ("关卡策划倾向：第 6–12 波各 1 只（7 只）",
     "6:1:path.left;7:1:path.right;8:1:path.left;9:1:path.right;10:1:path.left;11:1:path.right;12:1:path.left"),
    ("第 6–9 波各 1 只、第 10–12 波各 2 只（10 只）",
     "6:1:path.left;7:1:path.right;8:1:path.left;9:1:path.right;10:2:path.left;11:2:path.right;12:2:path.left"),
    ("只有小残影和快残影（旧版，对照）", ""),
]


def level_budget(L, coef, R):
    return sum(tdsim.wave_budget(w, R["budget_base"], R["budget_per_wave"], coef) for w in range(1, int(L["wave_count"]) + 1))


def n_armored(spec):
    return sum(int(x.split(":")[1]) for x in spec.split(";") if x.strip())


def armored_variant(T, A, levels, cal):
    raw = next(r for r in A if r["level_id"] == "ch1_03")
    base = campaign.scenario_level(levels["ch1_03"], "confirmed")
    squad, meta = raw["squad"].split("|"), meta_of(raw)
    tgt = tdsim.num(base["target_hp_first_clear"])
    th = tdsim.num(T["enemies"]["enm_shade_armored"]["threat_points"])
    R = T["rules"]
    main_spec = base.get("extra_spawns", "")
    tried = [dict(name="主版本（写进表里）：第 6–11 波各 1 只、第 12 波左右各 1 只", spec=main_spec, n=n_armored(main_spec),
                  coef=raw["budget_coef"], status=raw["calib"], res=raw["results"], L=base, smoothed=raw.get("smoothed_hp", ""),
                  share=n_armored(main_spec) * th / level_budget(base, raw["budget_coef"], R), main=True)]
    for name, spec in ARMORED_SPECS:
        L = dict(base, extra_spawns=spec)
        info = {}
        if cal or (spec == "" and not base.get("threat_budget_coef_no_armored")) or spec:
            coef, status = campaign.calibrate(T, L, squad, meta, tgt, info=info)
        else:
            coef, status = tdsim.num(base["threat_budget_coef_no_armored"]), "table"
        res = campaign.simulate_level(T, L, squad, meta, C.SEEDS, coef)
        tried.append(dict(name=name, spec=spec, n=n_armored(spec), coef=coef, status=status, res=res, L=L,
                          smoothed=info.get("smoothed_hp", ""), share=n_armored(spec) * th / level_budget(L, coef, R), main=False))
        if spec == "":
            levels["ch1_03"]["threat_budget_coef_no_armored"] = f"{coef:.2f}"
        print(f"ch1_03 {name}: 系数 {coef:.2f} 剩余 {hp_of(res)} 占比 {tried[-1]['share']:.1%}", flush=True)
    pick = tried[0]

    def split(res, eid):
        agg = {}
        for r in res:
            for k, v in r["dmg_by"].items():
                c, e = k.split("|")
                if e == eid:
                    agg[c] = agg.get(c, 0) + v
        tot = sum(agg.values()) or 1
        return {c: agg.get(c, 0) / tot for c in squad}
    res = pick["res"]
    spawned = st.mean(r["spawned"].get("enm_shade_armored", 0) for r in res)
    leaked_hp = st.mean(r["leak_by"].get("enm_shade_armored", 0) for r in res)
    chars = T["chars"]
    per_hit = []
    for c in squad:
        row = chars[c]
        atk = tdsim.num(row["attack"]) * tdsim.meta_attack_mult(meta[c], R["meta_attack_per_level"])
        for up in (0, 2):
            a = atk * tdsim.upgrade_mult(up, R["upgrade_attack_pct"])
            d0 = tdsim.final_damage(a, 0, 0, 0, R["armor_floor_ratio"], R.get("min_damage", 1))
            d10 = tdsim.final_damage(a, 10, 0, 0, R["armor_floor_ratio"], R.get("min_damage", 1))
            itv = tdsim.num(row["attack_interval"])
            per_hit.append(dict(character=row["name_zh"], meta_level=meta[c], upgrades=up, attack=round(a, 1),
                                hit_vs_0_armor=d0, hit_vs_10_armor=d10, kept=f"{d10 / d0:.0%}",
                                dps_vs_10_armor=round(d10 / itv, 1),
                                hits_to_kill_armored=math.ceil(200 * tdsim.hp_multiplier(6, R["hp_mult_per_level"]) / d10)))
    no_armor = campaign.simulate_level(T, pick["L"], squad, meta, C.SEEDS, pick["coef"],
                                       enemies_override={"enm_shade_armored": {"armor": "0"}})
    plain_same = campaign.simulate_level(T, dict(base, extra_spawns=""), squad, meta, C.SEEDS, pick["coef"])
    drop = {}
    for c in squad:
        sq = [x for x in squad if x != c]
        drop[c] = hp_of(campaign.simulate_level(T, pick["L"], sq, {x: meta[x] for x in sq}, C.SEEDS, pick["coef"]))
    # 逐波：威胁预算和敌人个数（种子 1 的出怪表）
    b = tdsim.Battle(pick["L"], squad, meta, seed=1, rules=R, chars=chars, enemies=T["enemies"], buffs=T["buffs"])
    waves = []
    for w, ev in enumerate(b.build_waves(), start=1):
        ids = [x[1] for x in ev]
        thr = sum(tdsim.num(T["enemies"][i]["threat_points"]) for i in ids)
        waves.append(dict(wave=w, budget=round(tdsim.wave_budget(w, R["budget_base"], R["budget_per_wave"], pick["coef"]), 1),
                          threat_spawned=int(thr), n_basic=ids.count("enm_shade_basic"), n_fast=ids.count("enm_shade_fast"),
                          n_armored=ids.count("enm_shade_armored"), armored_threat=4 * ids.count("enm_shade_armored")))
    return dict(pick=pick, tried=tried, spawned=spawned, leaked_hp=leaked_hp, per_hit=per_hit,
                hp_no_armor=hp_of(no_armor), hp_plain_same_coef=hp_of(plain_same), drop=drop, waves=waves,
                dmg_split_all={e: split(res, e) for e in ("enm_shade_basic", "enm_shade_fast", "enm_shade_armored")})


def coef_sensitivity(T, A, levels, boss_rows, arm):
    """每关用校准系数 ±0.05 跑一遍（同样的阵容、局外等级、每点伤害充能），看剩余生命怎么变。"""
    out = []
    fix = {b["level_id"]: b for b in boss_rows}
    for raw in A:
        L = campaign.scenario_level(levels[raw["level_id"]], "confirmed")
        squad, meta = raw["squad"].split("|"), meta_of(raw)
        c0 = raw["budget_coef"]
        vname = "主版本（含 8 只硬残影）" if raw["level_id"] == "ch1_03" else "现行规则"
        row = dict(level_id=raw["level_id"], variant=vname, target=raw["target"], coef=f"{c0:.2f}")
        for tag, d in (("minus", -0.05), ("base", 0.0), ("plus", 0.05)):
            c = round(max(0.05, c0 + d), 2)
            res = raw["results"] if d == 0 else campaign.simulate_level(T, L, squad, meta, C.SEEDS, c)
            row[f"hp_{tag}"] = hp_of(res)
            row[f"min_{tag}"] = min(r["hp_left"] for r in res)
        out.append(row)
        if raw["level_id"] in fix:
            LF, ov = campaign.boss_fix(L, T["rules"])
            cf = float(fix[raw["level_id"]]["coef_fix"])
            row = dict(level_id=raw["level_id"], variant="Boss 修正", target=raw["target"], coef=f"{cf:.2f}")
            for tag, d in (("minus", -0.05), ("base", 0.0), ("plus", 0.05)):
                res = campaign.simulate_level(T, LF, squad, meta, C.SEEDS, round(cf + d, 2), ov)
                row[f"hp_{tag}"] = hp_of(res)
                row[f"min_{tag}"] = min(r["hp_left"] for r in res)
            out.append(row)
        if raw["level_id"] == "ch1_03" and arm:
            p = next(t for t in arm["tried"] if t["spec"] == "")
            row = dict(level_id="ch1_03", variant="只有小和快（对照）", target=raw["target"], coef=f'{p["coef"]:.2f}')
            for tag, d in (("minus", -0.05), ("base", 0.0), ("plus", 0.05)):
                res = campaign.simulate_level(T, p["L"], squad, meta, C.SEEDS, round(p["coef"] + d, 2))
                row[f"hp_{tag}"] = hp_of(res)
                row[f"min_{tag}"] = min(r["hp_left"] for r in res)
            out.append(row)
    return out


def main():
    quick = "--quick" in sys.argv
    if quick:
        C.SEEDS = [1]
        C.CALIBRATE_SEEDS = [1]
    t0 = time.time()
    gen_progression.main()
    T = campaign.load_tables()
    cal = "--calibrate" in sys.argv
    print("== 方案 A：用户已确认值 + PR #4 战斗规则；平均分资源（even）；符卡手动 ==")
    A = campaign.run_campaign(T, "confirmed", do_calibrate=cal, alloc="even")
    sa = summarize(A)
    by_a = {r["level_id"]: r for r in sa}
    levels = {L["level_id"]: L for L in T["levels"]}

    print("== 对照列（同样的阵容、局外等级和系数，只改一项）==")
    auto_rows = []
    for row, raw in zip(sa, A):
        L = campaign.scenario_level(levels[raw["level_id"]], "confirmed")
        LB = campaign.scenario_level(levels[raw["level_id"]], "proposed")
        squad = raw["squad"].split("|")
        meta = {kv.split(":")[0]: int(kv.split(":")[1]) for kv in raw["meta_levels"].split("|")}
        row["sim_hp_at_coef_1"] = hp_of(campaign.simulate_level(T, L, squad, meta, C.SEEDS, 1.0))
        row["sim_hp_one_copy"] = hp_of(campaign.simulate_level(
            T, L, squad, meta, C.SEEDS, raw["budget_coef"], rules_override={"max_copies_per_character": 1}))
        row["sim_hp_proposed_B"] = hp_of(campaign.simulate_level(T, LB, squad, meta, C.SEEDS, raw["budget_coef"]))
        ra = campaign.simulate_level(T, L, squad, meta, C.SEEDS, raw["budget_coef"], spell_mode="auto")
        row["sim_hp_auto_spell"] = hp_of(ra)
        auto_rows.append(dict(raw, results=ra))

    print("== Boss 关：数值建议的 Boss 方案（Boss 血量不乘倍率 + 倒数第 5 波入场）==")
    boss_rows = []
    for row, raw in zip(sa, A):
        base = levels[raw["level_id"]]
        if not base.get("boss_wave"):
            continue
        L0 = campaign.scenario_level(base, "confirmed")
        LF, ov = campaign.boss_fix(L0, T["rules"])
        squad = raw["squad"].split("|")
        meta = {kv.split(":")[0]: int(kv.split(":")[1]) for kv in raw["meta_levels"].split("|")}
        tgt = tdsim.num(base["target_hp_first_clear"])
        same = campaign.simulate_level(T, LF, squad, meta, C.SEEDS, raw["budget_coef"], ov)
        if cal:
            info = {}
            coef, status = campaign.calibrate(T, LF, squad, meta, tgt, ov, info=info)
        else:
            coef, status, info = tdsim.num(base.get("threat_budget_coef_boss_fix"), raw["budget_coef"]), "table", {}
        res = campaign.simulate_level(T, LF, squad, meta, C.SEEDS, coef, ov)
        base["threat_budget_coef_boss_fix"] = f"{coef:.2f}"
        base["sim_hp_boss_fix"] = hp_of(res)
        boss_rows.append(dict(level_id=raw["level_id"], squad=raw["squad"], target=tgt,
                              coef_confirmed=f'{raw["budget_coef"]:.2f}', hp_confirmed=raw["hp_mean"],
                              boss_loops_confirmed=row["boss_loops"],
                              hp_fix_same_coef=hp_of(same), coef_fix=f"{coef:.2f}", calib=status, hp_fix=hp_of(res),
                              hp_fix_smoothed=info.get("smoothed_hp", ""),
                              boss_loops_fix=round(st.mean(x["boss_loops"] for x in res), 2),
                              star2_fix=f'{campaign.star_share(res, 2):.0%}',
                              duration_min_fix=round(st.mean(x["duration"] for x in res) / 60, 1)))
        print(boss_rows[-1], flush=True)

    print("== 养成对照：集中培养前 3 人（focus），同一套系数 ==")
    F = campaign.run_campaign(T, "confirmed", alloc="focus", verbose=False)
    focus_rows = []
    for a, f in zip(A, F):
        by_a[a["level_id"]]["sim_hp_focus"] = f["hp_mean"]
        focus_rows.append(dict(level_id=a["level_id"], target=a["target"], even_hp=a["hp_mean"], even_meta=a["meta_levels"],
                               focus_hp=f["hp_mean"], focus_min=f["hp_min"], focus_fail_seeds=f["fail_seeds"],
                               focus_meta=f["meta_levels"]))

    print("== 对照：第一章首通时碎片也平均分给琪露诺（even_all），同一套系数 ==")
    P = campaign.run_campaign(T, "confirmed", spend_rule="even_all", verbose=False, stop_after="ch1_04")
    pr5_rows = [dict(level_id=p["level_id"], pinned_meta=by_a[p["level_id"]]["meta_levels"],
                     pinned_hp=by_a[p["level_id"]]["sim_hp_mean"], even_meta=p["meta_levels"], even_hp=p["hp_mean"],
                     even_min=p["hp_min"]) for p in P if p["level_id"].startswith("ch1_")]

    print("== ch1_03 硬残影：主版本和几种对照写法 ==")
    arm = armored_variant(T, A, levels, cal)

    print("== 重打 MVP 7 关：打完 ch1_04 后的局外等级，阵容加入琪露诺和紫 ==")
    after = dict(A[6]["meta_after"])
    for c in ("yukari",):
        after.setdefault(c, max(1, int(st.mean(after.values()))))
    replay_rows = []
    for raw in A[:7]:
        L = campaign.scenario_level(levels[raw["level_id"]], "confirmed")
        squad = campaign.choose_squad(after, T["rules"]["squad_cap"])
        meta = {c: after[c] for c in squad}
        res = campaign.simulate_level(T, L, squad, meta, C.SEEDS, raw["budget_coef"])
        replay_rows.append(dict(level_id=raw["level_id"], first_clear_hp=raw["hp_mean"], replay_squad="|".join(squad),
                                replay_meta="|".join(f"{c}:{meta[c]}" for c in squad), replay_hp=hp_of(res),
                                replay_star2=f"{campaign.star_share(res, 2):.0%}", replay_star3=f"{campaign.star_share(res, 3):.0%}",
                                reward_2nd=levels[raw["level_id"]]["reward_repeat_2nd"]))
        if levels[raw["level_id"]].get("boss_wave"):
            LF, ov = campaign.boss_fix(L, T["rules"])
            coef_f = tdsim.num(levels[raw["level_id"]].get("threat_budget_coef_boss_fix"), raw["budget_coef"])
            replay_rows[-1]["replay_hp_boss_fix"] = hp_of(campaign.simulate_level(T, LF, squad, meta, C.SEEDS, coef_f, ov))

    sp = spell_stats(A)
    sp_auto = spell_stats(auto_rows)
    by_sp = {r["level_id"]: r for r in sp}
    for L in T["levels"]:
        a = by_a[L["level_id"]]
        L["sim_hp_first_clear"] = a["sim_hp_mean"]
        L["sim_hp_min_of_seeds"] = a["sim_hp_min"]
        L["sim_star2_share"] = a["star2_share"]
        L["sim_star3_share"] = a["star3_share"]
        L["sim_hp_focus_meta"] = a.get("sim_hp_focus", "")
        L["sim_hp_auto_spell"] = a["sim_hp_auto_spell"]
        L["sim_hp_one_copy_only"] = a["sim_hp_one_copy"]
        L["sim_spell_full_sec_normal"] = by_sp[L["level_id"]]["full_sec_normal"]
        L["sim_duration_min"] = a["duration_min"]
        L["expected_meta_level"] = a["meta_avg"]
        L.setdefault("threat_budget_coef_boss_fix", "")
        L.setdefault("sim_hp_boss_fix", "")
        L.setdefault("threat_budget_coef_no_armored", "")
        L.setdefault("extra_spawns", "")
    campaign.write_level_curve(T)
    write_csv(OUT / "campaign_confirmed.csv", sa, list(sa[0].keys()))
    write_csv(OUT / "spell_charge_by_level.csv", sp, list(sp[0].keys()))
    write_csv(OUT / "spell_charge_by_level_auto.csv", sp_auto, list(sp_auto[0].keys()))
    cst = caster_stats(A)
    write_csv(OUT / "spell_charge_by_caster.csv", cst, list(cst[0].keys()))
    mw = mvp_waves(T, A)
    write_csv(OUT / "mvp_waves.csv", mw, list(mw[0].keys()))
    write_csv(OUT / "boss_fix.csv", boss_rows, list(boss_rows[0].keys()))
    write_csv(OUT / "meta_even_vs_focus.csv", focus_rows, list(focus_rows[0].keys()))
    write_csv(OUT / "ch1_meta_pinned_vs_even.csv", pr5_rows, list(pr5_rows[0].keys()))
    print("== 系数敏感度（±0.05）==")
    csens = coef_sensitivity(T, A, levels, boss_rows, arm)
    write_csv(OUT / "coef_sensitivity.csv", csens, list(csens[0].keys()))
    arm_rows = [dict(name=t["name"], spec=t["spec"], n=t["n"], coef=f'{t["coef"]:.2f}', calib=t["status"],
                     share=f'{t["share"]:.1%}', hp=hp_of(t["res"]), smoothed=t["smoothed"], hp_min=min(r["hp_left"] for r in t["res"]),
                     picked="主版本" if t["main"] else "对照") for t in arm["tried"]]
    write_csv(OUT / "ch1_03_waves.csv", arm["waves"], list(arm["waves"][0].keys()))
    write_csv(OUT / "ch1_03_armored.csv", arm_rows, list(arm_rows[0].keys()))
    write_csv(OUT / "ch1_03_armored_per_hit.csv", arm["per_hit"], list(arm["per_hit"][0].keys()))
    names = {c: T["chars"][c]["name_zh"] for c in T["chars"]}
    split_rows = [dict(enemy=e, **{names[c]: f"{v:.0%}" for c, v in d.items()}) for e, d in arm["dmg_split_all"].items()]
    replay_fields = list(dict.fromkeys(k for r in replay_rows for k in r))
    write_csv(OUT / "mvp_replay_with_cirno_yukari.csv", replay_rows, replay_fields)

    sens, cmp_rows = [], []
    if not quick:
        variants = [("少 3 级", lambda v: v - 3), ("多 3 级", lambda v: v + 3), ("全程 1 级（完全不养成）", lambda v: 1),
                    ("全员满级 20", lambda v: 20)]
        print("== 养成敏感性 ==")
        for raw in A:
            L = campaign.scenario_level(levels[raw["level_id"]], "confirmed")
            squad = raw["squad"].split("|")
            base_meta = {kv.split(":")[0]: int(kv.split(":")[1]) for kv in raw["meta_levels"].split("|")}
            row = dict(level_id=raw["level_id"], expected_meta=raw["meta_avg"], expected=raw["hp_mean"])
            for name, fn in variants:
                meta = {c: min(20, max(1, int(fn(v)))) for c, v in base_meta.items()}
                row[name] = hp_of(campaign.simulate_level(T, L, squad, meta, C.SEEDS[:3], raw["budget_coef"]))
            sens.append(row)
        write_csv(OUT / "sensitivity.csv", sens, list(sens[0].keys()))
        print("== 符卡使对比 ==")
        chars = T["chars"]
        for raw in A:
            if not levels[raw["level_id"]].get("boss_wave"):
                continue
            L = campaign.scenario_level(levels[raw["level_id"]], "confirmed")
            squad = raw["squad"].split("|")
            meta = {kv.split(":")[0]: int(kv.split(":")[1]) for kv in raw["meta_levels"].split("|")}
            for cid in squad:
                res = campaign.simulate_level(T, L, squad, meta, C.SEEDS[:3], raw["budget_coef"], force_caster=cid)
                cyc = [c for r in res for c in r["cycles"]]
                normal = [c["sec"] for c in cyc if c["crisis"] <= 0.1 * c["sec"]]
                cmp_rows.append(dict(level_id=raw["level_id"], caster=chars[cid]["name_zh"], spell=chars[cid]["spell_name_zh"],
                                     energy_max=chars[cid]["spell_energy_max"], casts=round(len(cyc) / len(res), 1),
                                     full_sec_all=round(st.mean(c["sec"] for c in cyc), 1) if cyc else "",
                                     full_sec_normal=round(st.median(normal), 1) if normal else "", hp=hp_of(res)))
        write_csv(OUT / "caster_compare.csv", cmp_rows, list(cmp_rows[0].keys()))

    DOC.mkdir(parents=True, exist_ok=True)
    cols = ["level_id", "role", "waves", "threat_budget_coef", "calib", "hp_multiplier", "meta_levels", "target_hp",
            "sim_hp_mean", "sim_hp_smoothed", "sim_hp_min", "fail_seeds", "star2_share", "star3_share", "sim_hp_at_coef_1", "sim_hp_one_copy",
            "sim_hp_auto_spell", "sim_hp_proposed_B", "sim_hp_focus", "early5_loss_share", "duration_min", "sec_per_wave",
            "boss_loops", "transforms"]
    heads = ["关卡", "定位", "波数", "预算系数", "校准", "血量倍率", "各角色局外等级", "目标剩余生命", "模拟剩余(均值)",
             "期望(系数±0.02平滑)", "最差种子",
             "失败种子数", "≥2星占比", "3星占比", "系数=1.00时", "同名只能1个时", "符卡自动释放时", "方案B(开局灵力递增)",
             "集中培养3人时", "前5波掉血占比", "时长(分)", "秒/波", "Boss漏过次数", "每局质变次数"]
    md = ["# 模拟结果（脚本自动生成，请勿手改）\n\n",
          f"生成命令：`python tools/numeric/run_all.py{' --calibrate' if cal else ''}{' --quick' if quick else ''}`，种子 {C.SEEDS}。说明见 `../09_simulation.md`。\n\n",
          "## 方案 A：用户已确认值 + 战斗策划 PR #4 的规则（首通，平均分资源，符卡手动）\n\n",
          "开局 150 灵力，每波预算 (10+4×波次)×系数；同名角色最多 3 个；强化 2 层质变、未质变保底；"
          "解锁按方案 B（和关卡策划 PR #5 最新分支一致）：序章 3 关和 ch1_01 首通只有灵梦和魔理沙，ch1_02–ch1_04 首通多一个琪露诺，"
          "紫通关 ch1_04 后加入（MVP 首通用不到）。第一章 2–4 关首通时碎片照旧只花在灵梦和魔理沙身上（和上一版首通等级一样），琪露诺停在加入时的 3 级。"
          "MVP 7 关用 PR #5 最新分支的地图（只能放预定槽位，每关 3–5 格）、逐波编组（个数 × 系数）、浓雾（目标在雾格上射程 −1）和 ch1_04 首领三阶段；"
          "每波 20 秒刷怪窗口 + 4 秒空隙，不等清场。"
          "后面几列用同样的阵容和局外等级、同样的系数，只改一项。校准列 unreachable = 系数怎么调都达不到目标，表里填的是剩余生命最高的那个系数。locked = 关卡策划确认后手动锁定的系数（config.FIX_COEF，目前只有 ch1_03 = 0.75），不再自动校准，期望和 +0.05 按同样的口径另算；locked_cliff = 锁定值再加 0.05 会掉到目标以下 3 条命以上。"
          "校准先按 0.05 粗扫，再在附近按 0.01 细扫；剩余生命随系数是锯齿状的，所以每个系数取左右 ±0.02 共 5 个点 × 5 个种子的平均当「期望」，"
          "选「期望 ≥ 目标 − 0.5」的最大系数（系数太低时灵力少、反而难，所以取大的）。「模拟剩余」是这个系数本身 5 个种子的平均，和期望差 1–3 条命是正常的锯齿；校准列 cliff = 再加 0.05 就掉到目标以下 3 条命以上。\n\n",
          md_table(sa, cols, heads),
          "\n## Boss 关：现行规则 vs 数值建议的 Boss 方案（Boss 血量不乘关卡倍率 + 倒数第 5 波入场，待拍板）\n\n",
          md_table(boss_rows, list(boss_rows[0].keys()), ["关卡", "阵容", "目标", "现行系数", "现行剩余", "现行Boss漏过",
                                                          "建议方案(同系数)", "建议方案系数", "校准", "建议方案剩余", "建议方案期望(平滑)",
                                                          "建议方案Boss漏过", "≥2星占比", "时长(分)"]),
          "\n## 养成对照：平均分（even，校准用） vs 集中培养前 3 人（focus），同一套系数\n\n",
          md_table(focus_rows, list(focus_rows[0].keys()), ["关卡", "目标", "平均分剩余", "平均分等级", "集中剩余", "集中最差种子",
                                                            "集中失败种子数", "集中等级"]),
          "\n## 对照：第一章首通时碎片也平均分给琪露诺，同一套系数\n\n",
          md_table(pr5_rows, list(pr5_rows[0].keys()), ["关卡", "主口径等级", "主口径剩余", "平均分等级", "平均分剩余", "平均分最差种子"]),
          "\n## 系数敏感度：每关系数 ±0.05 时的剩余生命（同样的阵容和等级，5 个种子平均；括号外均值，min_ 为最差种子）\n\n",
          md_table(csens, list(csens[0].keys()), ["关卡", "版本", "目标", "系数", "−0.05 剩余", "−0.05 最差", "原系数剩余", "原系数最差",
                                                   "+0.05 剩余", "+0.05 最差"]),
          "\n## ch1_03 的硬残影（enm_shade_armored：200 血 / 0.6 速 / 10 甲 / 漏过扣 2 / 威胁 4）\n\n",
          "制作人定：硬残影进 MVP，只在 ch1_03 少量出现。主版本（写进难度表）：第 6–11 波各 1 只、第 12 波左右各 1 只，共 8 只，左右两路轮流；"
          "每只从同一路线扣掉 4 点威胁的小残影（左路）或快残影（右路），全关总预算不变。下面的对照写法都各自重新校准过系数。\n\n",
          md_table(arm_rows, list(arm_rows[0].keys()), ["写法", "出场（波:只数:路线）", "只数", "系数", "校准", "占全关预算", "剩余", "期望(平滑)", "最差种子", "用途"]),
          "\nch1_03 主版本逐波（种子 1 的出怪表；威胁预算 = (10 + 4 × 波次) × 系数，实际刷出的威胁点因为取整和余数滚动会差 1）：\n\n",
          md_table(arm["waves"], list(arm["waves"][0].keys()), ["波", "威胁预算", "实际威胁点", "小残影", "快残影", "硬残影", "硬残影威胁点"]),
          f"\n选中写法下：每局出 {arm['spawned']:.1f} 只硬残影，平均漏过扣 {arm['leaked_hp']:.1f} 条命；同系数把硬残影护甲改成 0 时剩余 {arm['hp_no_armor']}；"
          f"同系数不加硬残影（原版编组）剩余 {arm['hp_plain_same_coef']}。去掉某个角色（同系数）后的剩余："
          + "、".join(f"去掉{names[c]} {v}" for c, v in arm["drop"].items()) + "。\n\n各角色打各类残影的有效伤害占比（含符卡）：\n\n",
          md_table(split_rows, list(split_rows[0].keys()), ["敌人"] + list(split_rows[0].keys())[1:]),
          "\n单发伤害（本关局外等级，不暴击；硬残影实战血量 = 200 × 本关血量倍率）：\n\n",
          md_table(arm["per_hit"], list(arm["per_hit"][0].keys()), ["角色", "局外等级", "局内升级", "攻击", "打 0 甲", "打 10 甲", "保留",
                                                                    "对 10 甲每秒伤害", "打死 1 只硬残影要几下"]),
          "\n## 重打 MVP 7 关（打完 ch1_04 后的局外等级，阵容加入琪露诺和紫）\n\n",
          md_table(replay_rows, replay_fields, replay_fields),
          "\n## 符卡充能（方案 A，手动释放，每关）\n\n",
          "每点伤害充能按 PR #4 换算 = 70 ÷ (60 × D)，D 是本关模拟的全队每秒有效伤害（不算符卡）。充满秒数换算到满能量 100："
          "「普通」= 充能期间危急时间 ≤10% 的那几次的中位数，「危急为主」= 危急时间 ≥50% 的中位数。\n\n",
          md_table(sp, list(sp[0].keys()), ["关卡", "每点伤害充能", "全队每秒伤害 D", "每秒击杀 K", "每关释放次数", "符卡使:次数",
                                          "平均充满秒数", "普通(秒/100能量)", "危急为主(秒/100能量)", "危急时间占比", "伤害充能占比"]),
          "\n## 符卡充能（自动释放对照）\n\n",
          md_table(sp_auto, list(sp_auto[0].keys()), ["关卡", "每点伤害充能", "全队每秒伤害 D", "每秒击杀 K", "每关释放次数", "符卡使:次数",
                                                    "平均充满秒数", "普通(秒/100能量)", "危急为主(秒/100能量)", "危急时间占比", "伤害充能占比"]),
          "\n## 符卡充能（按符卡使汇总，秒数为本人满能量）\n\n",
          md_table(cst, list(cst[0].keys()), ["符卡使", "符卡", "满能量", "充满次数", "平均充满秒数", "普通波次中位秒数"]),
          "\n## MVP 7 关逐波明细（方案 A，种子 1 的刷怪表 + 各种子平均结果）\n\n",
          md_table(mw, list(mw[0].keys()), ["关卡", "波", "威胁预算", "小残影", "快残影", "硬残影", "Boss", "小残影实战血量",
                                            "本波秒数", "平均漏怪", "平均掉血", "三选一"])]
    if sens:
        md += ["\n## 养成敏感性（同样的系数和阵容，只改每个角色的局外等级；数值为模拟剩余生命，3 个种子）\n\n",
               md_table(sens, list(sens[0].keys()), ["关卡", "预计平均等级", "按预计等级"] + list(sens[0].keys())[3:])]
    if cmp_rows:
        md += ["\n## 符卡使对比（Boss 关，轮流让阵容里每个人当符卡使，3 个种子）\n\n",
               md_table(cmp_rows, list(cmp_rows[0].keys()), ["关卡", "符卡使", "符卡", "满能量", "每关释放次数", "平均充满秒数", "普通波次中位秒数", "剩余生命"])]
    (DOC / "sim_results.md").write_text("".join(md), encoding="utf-8")
    import gen_stats_json
    import gen_level_json
    gen_stats_json.main()
    gen_level_json.main()
    print(f"完成，用时 {time.time() - t0:.0f} 秒。报告：docs/design/numeric/generated/sim_results.md")


if __name__ == "__main__":
    main()
