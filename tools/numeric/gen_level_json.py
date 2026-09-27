# -*- coding: utf-8 -*-
"""从 data/balance/level_difficulty.csv 生成 data/balance/level_difficulty.json。

这个 JSON 最早由关卡策划 PR #5 建立（schema_version 1，_owner 写的就是数值策划）。本脚本保持它的结构：
confirmed 段原样保留（关卡策划已确认的规则），proposal / alignment_open 段更新为数值策划的结论，
levels.<id> 保留原有字段并写入校准后的系数，另加几项模拟结果字段。改数请改 CSV 后重跑，不要手改 JSON。
用法：python tools/numeric/gen_level_json.py（run_all.py 结束时也会自动调用）
"""
from __future__ import annotations

import json

import tdsim

OUT = tdsim.DATA / "balance" / "level_difficulty.json"

# PR #5 的 confirmed 段（关卡策划已确认的规则），原样保留
CONFIRMED = {
    "per_wave_threat": "10 + 4 * wave_index", "wave_index_starts_at": 1,
    "examples": {"wave_1": 14, "wave_10": 50, "wave_15": 70},
    "level_total": "10 * N + 2 * N * (N + 1)",
    "known_totals": {"8": 224, "9": 270, "10": 320, "11": 374, "12": 432, "15": 630},
    "hp_multiplier": "1 + 0.15 * (level_number - 1)",
    "hp_base": "图鉴里的 hp 是第 1 关基础值，实战生命再乘本关 hp_multiplier",
    "starting_spirit_power": 150, "spirit_per_wave_survived": 20, "lives": 20,
    "buff_every_waves": 5, "buff_pick_count": 3, "boss_does_not_consume_wave_budget": True,
}


def num(v, d=None):
    try:
        f = float(v)
    except (TypeError, ValueError):
        return d
    return int(f) if f.is_integer() else round(f, 3)


def main():
    R = tdsim.load_rules()
    levels = tdsim.load_levels()
    out_levels = {}
    for L in levels:
        n = int(L["wave_count"])
        coef = float(L["threat_budget_coef"])
        budgets = [int(round((R["budget_base"] + R["budget_per_wave"] * w) * coef)) for w in range(1, n + 1)]
        d = {
            "level_number": int(L["level_index"]), "role": L["level_role"], "wave_count": n,
            "threat_budget_coef": round(coef, 2), "threat_budget_coef_status": "numbers_calibrated",
            "hp_multiplier": num(L["hp_multiplier"]),
            "buff_after_waves": [int(x) for x in L["buff_pick_waves"].split("|") if x],
            "buff_pick_count": int(R["buff_offer_count"]),
            "wave_threat_budgets": budgets, "threat_budget_total": sum(budgets),
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
        if L.get("unlock_characters"):
            d["unlock_characters"] = L["unlock_characters"].split("|")
        if L.get("banned_characters"):
            d["banned_characters"] = L["banned_characters"].split("|")
        out_levels[L["level_id"]] = d
    doc = {
        "schema_version": 1,
        "_owner": "数值策划",
        "note": "本文件由 tools/numeric/gen_level_json.py 从 data/balance/level_difficulty.csv 生成（数值策划 PR 覆盖关卡策划 PR #5 的同名文件），"
                "改数请改 CSV 后重跑。confirmed 段保持关卡策划原样。每波威胁预算 = round((10 + 4 × 波次) × 本关系数)，"
                "data/levels 里各关的编组需要按 wave_threat_budgets 重新凑（请关卡策划配合）。",
        "confirmed": CONFIRMED,
        "proposal": {
            "threat_budget_coef": {
                "default": None, "status": "numbers_calibrated",
                "note": "数值策划按模拟校准了每关系数，目标是只打首通、不刷关的玩家剩下 target_lives_first_clear 条命（MVP 第一章 14/13/12/11）。"
                        "首通 MVP 7 关只有灵梦和魔理沙（打败琪露诺后琪露诺和紫才解锁）。每波约 20 秒。",
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
            {"id": "wave_counts", "note": "序章按 3/4/10 波、前两关没有三选一；第二到五章第 1 关 PR #5 写 8 波（少于 10），本表用 11/12/12/13 波。"},
            {"id": "cirno_unlock", "note": "制作人定：打败琪露诺（ch1_04）后琪露诺和紫一起解锁；PR #5 写琪露诺第一章第 1 关起可用，需改。"},
            {"id": "star_band", "note": "PR #5 的 18–20 三星作废，按 20/20 三星、≥10 两星。"},
            {"id": "boss_rules", "note": "见 proposal.boss_fix，待制作人拍板。"},
        ],
        "levels": out_levels,
    }
    OUT.write_text(json.dumps(doc, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("已生成", OUT.relative_to(tdsim.ROOT))


if __name__ == "__main__":
    main()
