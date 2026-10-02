# -*- coding: utf-8 -*-
"""从 data/balance/level_difficulty.csv 生成 data/balance/level_difficulty.json。

这个 JSON 最早由关卡策划 PR #5 建立（schema_version 1，_owner 写的就是数值策划）。PR #5 最新分支已经把难度表挪到
data/balance/level_tables/level_difficulty.csv（种子，系数全 1.0，写明「数值策划会整表替换」），不再有这个 JSON。
本脚本保持 JSON 的结构：confirmed 段是关卡策划已确认的规则，proposal / alignment_open 段是数值策划的结论，
levels.<id> 写入校准后的系数和模拟结果。另外按 PR #5 新表的列顺序导出一份可以直接整表替换的 CSV：
tools/numeric/output/level_tables_level_difficulty.csv（不直接写进 data/balance/level_tables/，免得和 PR #5 冲突）。
改数请改 CSV 后重跑，不要手改 JSON。用法：python tools/numeric/gen_level_json.py（run_all.py 结束时也会自动调用）
"""
from __future__ import annotations

import csv
import json
from decimal import ROUND_HALF_UP, Decimal

import config as C
import tdsim

OUT = tdsim.DATA / "balance" / "level_difficulty.json"
OUT_PR5_TABLE = tdsim.ROOT / "tools" / "numeric" / "output" / "level_tables_level_difficulty.csv"
PR5_TABLE_HEADER = ["level_id", "chapter", "level_index", "level_role", "wave_count", "threat_budget_coef", "hp_multiplier",
                    "reward_spirit_start", "reward_spirit_per_wave", "reward_buff_after_waves", "reward_buff_pick_count",
                    "expected_first_clear_lives", "reward_meta_first_clear", "reward_meta_replay"]
PR5_ROLE = {"tutorial": "teaching", "practice": "practice", "trial": "test", "boss": "boss"}

# PR #5 的 confirmed 段（关卡策划已确认的规则），原样保留
CONFIRMED = {
    "per_wave_threat": "10 + 4 * wave_index", "wave_index_starts_at": 1,
    "examples": {"wave_1": 14, "wave_10": 50, "wave_15": 70},
    "level_total": "10 * N + 2 * N * (N + 1)",
    "known_totals": {"8": 224, "9": 270, "10": 320, "11": 374, "12": 432, "15": 630},
    "hp_multiplier": "1 + 0.15 * (level_number - 1)",
    "hp_base": "图鉴里的 hp 是第 1 关基础值，实战生命再乘本关 hp_multiplier",
    "starting_spirit_power": 150, "spirit_per_wave_survived": 20, "lives": 20,
    "buff_rule": "非序章关卡每关 1 到 3 次三选一，最后一波不弹：10 波 1 次（第 5 波后），11–15 波 2 次（第 5、10 波后），"
                 "16–20 波 3 次（第 5、10、15 波后）；序章前两关没有",
    "buff_pick_count": 3, "boss_does_not_consume_wave_budget": True,
    "stars": "通关 1 星；剩余生命 ≥ 10/20 为 2 星；满命 20/20 为 3 星",
    "wave_timing": "每波刷怪窗口 20 秒，窗口结束 + 4 秒空隙后下一波，不等清场；布阵 10 秒；首领关最后一波要等首领被击败",
    "placement": "只能放在关卡预定槽位（MVP 每关 3–5 格）",
}


def num(v, d=None):
    try:
        f = float(v)
    except (TypeError, ValueError):
        return d
    return int(f) if f.is_integer() else round(f, 3)


def pr5_role(L):
    """PR #5 校验器的定位规则：首领关 boss；否则章内第 1 关 teaching、第 2 关 practice、其余 test（序章第 2 关也是 practice）。"""
    if L["level_role"] == "boss":
        return "boss"
    return {1: "teaching", 2: "practice"}.get(int(L["chapter_level"]), "test")


def wave_budgets(R, n, coef_text):
    """每波预算 = (10 + 4 × 波次) × 系数，四舍五入（0.5 进位，和 PR #5 tools/validate_levels.py 的 scaled_budget 一致）。"""
    c = Decimal(str(coef_text))
    return [int((Decimal(str(R["budget_base"] + R["budget_per_wave"] * w)) * c).quantize(Decimal("1"), rounding=ROUND_HALF_UP))
            for w in range(1, n + 1)]


def main():
    R = tdsim.load_rules()
    levels = tdsim.load_levels()
    out_levels = {}
    for L in levels:
        n = int(L["wave_count"])
        coef = float(L["threat_budget_coef"])
        lid = L["level_id"]
        if lid in C.FIX_COEF and abs(C.FIX_COEF[lid] - coef) > 1e-9:
            raise SystemExit(f"{lid}: CSV 系数 {coef} 和 config.FIX_COEF 锁定值 {C.FIX_COEF[lid]} 不一致，先改成一致再生成")
        budgets = wave_budgets(R, n, f"{coef:.2f}")
        is_boss = L["level_role"] == "boss"
        # 前几个字段和 PR #5 种子（f2212be 的 data/balance/level_difficulty.json）同名同类型（字符串），供它的校验器和 GUT 测试读取
        d = {
            "chapter": L["chapter"], "level_index": int(L["level_index"]),
            "level_role": pr5_role(L), "wave_count": n,
            "threat_budget_coef": f"{coef:.2f}",
            "threat_budget_coef_status": "locked_level_design_confirmed" if lid in C.FIX_COEF else "numbers_calibrated",
            "hp_multiplier": f'{float(L["hp_multiplier"]):.2f}',
            "reward_spirit_start": str(int(num(L.get("start_spirit"), 150))), "reward_spirit_per_wave": str(int(R["wave_clear_bonus"])),
            "buff_after_waves": [int(x) for x in L["buff_pick_waves"].split("|") if x],
            "buff_pick_count": int(R["buff_offer_count"]) if L["buff_pick_waves"] else 0,
            "wave_threat_budgets": budgets, "threat_budget_total": sum(budgets),
            "expected_first_clear_lives": "10-11" if is_boss else "11-13",
            "reward_meta_first_clear": "pending_numbers", "reward_meta_replay": "pending_numbers",
            # 以下是数值策划的附加字段
            "level_number": int(L["level_index"]), "role": L["level_role"],
            "reward_meta_proposal": {"first_clear": num(L.get("reward_first_clear")), "replay_2nd": num(L.get("reward_repeat_2nd")),
                                     "replay_3rd": num(L.get("reward_repeat_3rd")), "replay_floor": num(L.get("reward_repeat_floor")),
                                     "status": "numbers_proposal_pending_producer"},
            "target_lives_first_clear": num(L["target_hp_first_clear"]),
            "sim_lives_first_clear": num(L["sim_hp_first_clear"]),
            "sim_lives_worst_seed": num(L["sim_hp_min_of_seeds"]),
            "sim_star2_share": L["sim_star2_share"], "sim_star3_share": L["sim_star3_share"],
            "sim_duration_min": num(L["sim_duration_min"]),
            "expected_meta_level_avg": num(L["expected_meta_level"]),
            "map_source": L["map_source"],
        }
        if L.get("boss_wave"):
            d["boss_id"] = L["boss_enemy_id"]
            d["boss_enters_wave"] = int(L["boss_wave"])
            if L.get("threat_budget_coef_boss_fix"):
                d["threat_budget_coef_if_boss_fix"] = num(L["threat_budget_coef_boss_fix"])
                d["sim_lives_if_boss_fix"] = num(L["sim_hp_boss_fix"])
                if (num(L["sim_hp_first_clear"], 0) or 0) < (num(L["target_hp_first_clear"], 0) or 0) - 1:
                    d["threat_budget_coef_status"] = "numbers_calibrated_target_unreachable_under_current_boss_rules"
        if L.get("extra_spawns"):
            spawns = [x.split(":") for x in L["extra_spawns"].split(";") if x.strip()]
            d["armored_shades"] = dict(
                enemy_id="enm_shade_armored", count=sum(int(x[1]) for x in spawns),
                waves=[dict(wave=int(x[0]), count=int(x[1]), path_id=x[2] if len(x) > 2 else "") for x in spawns],
                threat_share=round(sum(int(x[1]) for x in spawns) * 4 / sum(budgets), 3),
                note="每只硬残影（威胁 4）从同一路线扣掉 4 点威胁的小/快残影，全关总预算不变。制作人定：硬残影进 MVP，只在这一关少量出现")
        if L.get("threat_budget_coef_no_armored"):
            d["variant_without_armored"] = dict(threat_budget_coef=num(L["threat_budget_coef_no_armored"]),
                                                note="对照参考：只有小残影和快残影时的系数")
        if lid in C.FIX_COEF:
            d["threat_budget_coef_lock"] = dict(
                by="关卡策划（PR #5 cursor/design-level-framework-01a3，f2212be）",
                note="手动锁定，tools/numeric/config.py 的 FIX_COEF；run_all.py --calibrate 不会改写。自动校准会给 0.77。")
        if L.get("unlock_characters"):
            d["unlock_characters"] = L["unlock_characters"].split("|")
        if L.get("banned_characters"):
            d["banned_characters"] = L["banned_characters"].split("|")
        out_levels[L["level_id"]] = d
    doc = {
        "schema_version": 1,
        "_owner": "数值策划",
        # status / comments / order 和 PR #5 种子同名（PR #5 的校验器按 comments 里的文字、order 的顺序检查）
        "status": "numbers_calibrated",
        "comments": [
            "owner: 数值策划",
            "status: numbers_calibrated（tools/numeric/gen_level_json.py 从 data/balance/level_difficulty.csv 生成，不再是种子）",
            "formula: 每一波预算 = (10 + 4 × wave_index) × threat_budget_coef，wave_index 从 1 起，四舍五入（0.5 进位）",
            "coef: 24 关都按模拟校准；ch1_03 按关卡策划确认锁定 0.75（config.FIX_COEF）。首领关按现行规则校准，"
            "如果制作人采纳数值建议的首领修正，改用各关的 threat_budget_coef_if_boss_fix（ch1_04 = "
            + next((f'{float(L["threat_budget_coef_boss_fix"]):.2f}' for L in levels if L["level_id"] == "ch1_04"
                    and L.get("threat_budget_coef_boss_fix")), "—") + "）",
            "first_clear: 普通关剩余 11-13 条命，首领关 10-11（expected_first_clear_lives）；数值校准目标见 target_lives_first_clear，等制作人确认",
            "lives: 20",
            "boss_does_not_consume_wave_budget: true",
            "hp_multiplier: 1 + 0.15 × (level_index - 1)，level_index 是 1 到 24",
            "meta_reward: 首通和重打的局外奖励 reward_meta_first_clear、reward_meta_replay 仍写 pending_numbers；"
            "数值提议在 reward_meta_proposal（首通 50 + 70 × (序号 − 1)，首领 ×1.5；重打 50% / 30% / 20%），待制作人拍板",
            "stars: 通关 1 星；剩余生命 ≥ 10/20 为 2 星；满命 20/20 为 3 星",
            "buff: 制作人已定：非序章关卡每关 1 到 3 次三选一，最后一波不弹",
            "placement: 只能放在关卡预定槽位",
        ],
        "order": [L["level_id"] for L in levels],
        "note": "本文件由 tools/numeric/gen_level_json.py 从 data/balance/level_difficulty.csv 生成（数值策划 PR 覆盖关卡策划 PR #5 的同名文件），"
                "改数请改 CSV 后重跑。confirmed 段保持关卡策划原样。每波威胁预算 = (10 + 4 × 波次) × 本关系数，四舍五入（0.5 进位），"
                "data/levels 里各关的编组需要按 wave_threat_budgets 重新凑（请关卡策划配合）。",
        "confirmed": CONFIRMED,
        "proposal": {
            "threat_budget_coef": {
                "default": None, "status": "numbers_calibrated",
                "note": "数值策划按模拟校准了每关系数，目标是只打首通、不刷关的玩家剩下 target_lives_first_clear 条命（MVP 第一章 14/13/12/11）。"
                        "解锁按方案 B：序章 3 关和 ch1_01 首通只有灵梦和魔理沙，ch1_02–ch1_04 首通多一个琪露诺（通关 ch1_01 后加入），"
                        "紫通关 ch1_04 后加入。MVP 7 关按关卡策划 PR #5 最新分支的地图、预定槽位、逐波编组（个数 × 系数）和浓雾模拟。",
            },
            "boss_fix": {
                "status": "numbers_proposal_pending_producer",
                "note": "按现行规则（Boss 血量 3000 × 本关倍率、倒数第 10 波入场、碰到守护点扣 10 后回起点）模拟里 Boss 至少漏过 1–2 次，"
                        "Boss 关达不到目标。数值建议：Boss 血量写的就是实战值（不乘倍率），并改为倒数第 5 波入场；"
                        "采用后请用各关的 threat_budget_coef_if_boss_fix。",
                "enter_waves_from_end": int(R.get("proposed_boss_enter_waves_from_end", 5)),
                "boss_hp_uses_level_mult": False,
            },
            "stars": {"rule": "满生命 20/20 = 3 星；剩余 ≥10 = 2 星；通关 = 1 星", "gives_resources": False},
        },
        "alignment_open": [
            {"id": "table_path", "note": "PR #5 最新分支（f2212be）已把难度表放回 data/balance/level_difficulty.json（种子：MVP 七关第二轮系数，其余 1.0），"
                                         "并删掉了 data/balance/level_tables/。本文件就是正式输出；tools/numeric/output/level_tables_level_difficulty.csv 只作参考。"
                                         "PR #5 的 tools/validate_levels.py 和 tests/unit/test_level_data.gd 里写死了种子系数和「status: seed」，合并后需要关卡策划按本表更新。"},
            {"id": "boss_rules", "note": "见 proposal.boss_fix，待制作人拍板。PR #5 首领关目标写约 10–11 条命，本表 ch1_04 用 11。"},
            {"id": "enemy_ids", "note": "PR #5 敌人图鉴有 pouncer / flying，没有本表第三章起用的 heavy / swarm；第二章起的编组等关卡策划出稿后再对齐。"},
            {"id": "mvp_enemies", "note": "制作人定：MVP 敌人 = 小残影、快残影，加 ch1_03 少量硬残影（第 6–11 波各 1 只、第 12 波左右各 1 只，共 8 只）；其他 MVP 关不出硬残影。PR #5 f2212be 的 ch1_03 已按系数 0.75 补上这 8 只，排法一致。"},
            {"id": "boss_cirno_phases", "note": "ch1_04 冰瀑挡直线、完美冻结的秒数和次数是模拟假设（冻结 2 秒、宣言时一次），等战斗策划定。"},
        ],
        "levels": out_levels,
    }
    OUT.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("已生成", OUT.relative_to(tdsim.ROOT))
    write_pr5_table(levels)


def write_pr5_table(levels):
    """按 PR #5 新表（data/balance/level_tables/level_difficulty.csv）的列导出，系数用校准值。"""
    OUT_PR5_TABLE.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_PR5_TABLE, "w", newline="", encoding="utf-8") as f:
        f.write("# owner: 数值策划\n# status: numbers_calibrated（tools/numeric/gen_level_json.py 生成）\n"
                "# formula: 每一波预算 = (10 + 4 × wave_index) × threat_budget_coef，wave_index 从 1 起\n"
                "# coef: 按现行首领规则校准；ch1_03 按关卡策划确认锁定 0.75；首领关如果采用数值建议的首领修正，改用 data/balance/level_difficulty.csv 的 threat_budget_coef_boss_fix\n"
                "# lives: 20\n")
        w = csv.writer(f, lineterminator="\n")
        w.writerow(PR5_TABLE_HEADER)
        for L in levels:
            n = int(L["wave_count"])
            tgt = num(L["target_hp_first_clear"])
            w.writerow([L["level_id"], L["chapter"], L["level_index"], pr5_role(L), n,
                        f'{float(L["threat_budget_coef"]):.2f}', f'{float(L["hp_multiplier"]):.2f}',
                        num(L.get("start_spirit"), 150), 20, ";".join(x for x in L["buff_pick_waves"].split("|") if x),
                        3 if L["buff_pick_waves"] else 0, ("10-11" if L["level_role"] == "boss" else "11-13"),
                        L.get("reward_first_clear", "pending_numbers"), L.get("reward_repeat_2nd", "pending_numbers")])
    print("已生成", OUT_PR5_TABLE.relative_to(tdsim.ROOT))


if __name__ == "__main__":
    main()
