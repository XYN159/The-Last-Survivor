# -*- coding: utf-8 -*-
"""从 CSV 主表生成 data/balance/combat/stats.json（战斗策划 PR #4 约定的数值文件）。

CSV 是给人读、给人改的主表；stats.json 只由本脚本生成，不要手改。
- 保留 PR #4 的全部 ID 和字段名（chr_* / enm_* / boss_* / skl_* / st_* / sc_* / buff_*）。
- 另加全局常量 global.armor_floor_ratio、global.min_damage，以及几段新字段（见 meta.added_fields_zh）。
用法：python tools/numeric/gen_stats_json.py（run_all.py 结束时也会自动调用）
"""
from __future__ import annotations

import json

import tdsim

OUT = tdsim.DATA / "balance" / "combat" / "stats.json"


def n(v):
    """CSV 字符串 → int 或 float（整数就输出整数，JSON 更干净）。"""
    f = float(v)
    return int(f) if f.is_integer() else round(f, 6)


def blank_or_num(rules: dict, key: str):
    """空参数保持 null。待 P7 的费用字段不能填 1、5、10 或 50。"""
    v = rules.get(key, "")
    if v is None or v == "":
        return None
    return n(v)


def main():
    R = tdsim.load_rules()
    rule_rows = tdsim.read_csv(tdsim.DATA / "balance" / "battle_rules.csv")
    rule_status = {r["rule_key"]: r["status"] for r in rule_rows}
    chars = tdsim.load_characters()
    enemies = tdsim.load_enemies()
    buffs = tdsim.load_buffs()
    levels = tdsim.load_levels()
    coef_rows = tdsim.read_csv(tdsim.DATA / "balance" / "combat_coefficients.csv")

    up = [n(R["upgrade_cost_1"]), n(R["upgrade_cost_2"])]
    lvl_mult = [1.0] + [round(tdsim.upgrade_mult(k, R["upgrade_attack_pct"]), 4) for k in (1, 2)]

    ch_out = {}
    for c in chars.values():
        d = {
            "cost": n(c["deploy_cost"]),
            "upgrade_costs": up,
            "sell_refund_ratio": n(c["sell_refund_ratio"]),
            "copy_cost_increase_ratio": n(c["copy_cost_increase_ratio"]),
            "max_copies": n(c["max_copies"]),
            "base_attack": n(c["attack"]),
            "level_attack_mult": lvl_mult,
            "crit_chance": n(c["crit_chance"]),
            "crit_mult": n(c["crit_mult"]),
            "attack_interval_sec": n(c["attack_interval"]),
            "range_cells": n(c["range"]),
            "attack": {"range_cells": n(c["range"]), "interval_sec": n(c["attack_interval"])},
            "spell_energy_max": n(c["spell_energy_max"]),
            "growth_tier": c.get("growth_tier") or "待 P3",
            "value_status": c["status"],
            "max_copies_status": "abolished_q3",
            "copy_cost_status": "pending_p6",
        }
        if float(c["max_hp"] or 0) > 0:
            d["max_hp"] = n(c["max_hp"])
            d["block_count"] = n(c["block_count"])
        if c["normal_effect"] in ("slow_on_hit", "splash", "bonus_vs_fast", "aura_aspd"):
            d["normal_effect"] = {"type": c["normal_effect"], "value": n(c["normal_effect_value"]),
                                  "param": c["normal_effect_param"] if not c["normal_effect_param"].replace(".", "").isdigit()
                                  else n(c["normal_effect_param"])}
        ch_out[c["combat_id"]] = d

    # 敌人数值迁入 stats.json（方案二，和 PR #4 约定）：7 个字段名固定；Boss 用同样字段放在 bosses 下
    en_out, boss_out = {}, {}
    for e in enemies.values():
        d = {"hp": n(e["hp"]), "move_speed_cells_per_sec": n(e["move_speed_cells_per_sec"]), "armor": n(e["armor"]),
             "spirit_drop": n(e["spirit_drop"]), "leak_damage": n(e["leak_damage"]),
             "threat_points": n(e["threat_points"]), "kill_charge": n(e["kill_charge"])}
        extra = {"first_level_id": e["first_level_id"], "value_status": e["status"]}
        if e.get("balance_hold"):
            extra["balance_hold"] = e["balance_hold"]
        if float(e.get("block_dps") or 0) > 0:
            extra["block_dps"] = n(e["block_dps"])
        d.update(extra)
        # Boss 只进 bosses。leak_damage 的正式路径是 bosses.<id>.leak_damage，不在 enemies 里再放一份。
        if e["category"] == "boss":
            boss_out[e["enemy_id"]] = d
        else:
            en_out[e["enemy_id"]] = d

    sections: dict = {"skills": {}, "statuses": {}, "synergies": {}, "spell_cards": {}}
    for r in coef_rows:
        sections[r["section"]].setdefault(r["id"], {})[r["field"]] = n(r["value"])

    bf_out = {}
    for b in buffs:
        d = {"offer_weight": n(b["weight"]), "max_stacks": n(b["max_stacks"])}
        if b.get("transform_at_stacks") and float(b["transform_at_stacks"]) > 0:
            d["transform_at_stacks"] = n(b["transform_at_stacks"])
        if b["stats_field"]:
            d[b["stats_field"]] = n(b["value"])
        if b["stats_field2"]:
            d[b["stats_field2"]] = n(b["value2"])
        if b["source"] != "pr4":
            d["value_status"] = "numeric_proposal_new_buff_behavior_pending_combat_design"
        bf_out[b["buff_id"]] = d

    per_level = {L["level_id"]: n(L["spell_charge_per_damage"]) for L in levels if L.get("spell_charge_per_damage")}
    first = per_level.get(levels[0]["level_id"], n(R["spell_charge_per_damage_base"]))

    stats = {
        "meta": {
            "schema_version": 2,
            "status": "filled_by_balance_design",
            "owner": "balance_design",
            "doc": "docs/design/combat/data_reference.md",
            "numeric_doc": "docs/design/numeric/README.md",
            "generated_by": "tools/numeric/gen_stats_json.py",
            "source_tables": ["data/characters.csv", "data/enemies.csv", "data/roguelite_buffs.csv",
                              "data/balance/battle_rules.csv", "data/balance/combat_coefficients.csv",
                              "data/balance/level_difficulty.csv"],
            "note_zh": "本文件由脚本从 CSV 生成，改数请改 CSV 后重跑 run_all.py 或 gen_stats_json.py，不要手改。"
                       "2026-10-03 USER_DECISIONS 高于旧口径：armor_floor_ratio = 0.05（Q14）。"
                       "min_damage 的「至少 1」和旧的 20% 已被 Q14 取代。"
                       "status 为 abolished 的规则（局内升级、共用符卡、同名上限、10/20/4 波次窗口、危机充能、主线三选一）不是现行定案，数字只是旧值。"
                       "copy_cost_increase_ratio 不改名，待 P6。initial_cost、cost_regen_per_sec、max_cost 为空，待 P7。"
                       "Boss 血量 balance_hold=待 P10 是旧锁。重甲残影待 P11。growth_tier 待 P3。"
                       "boss_phase_count 与 boss_freeze_on_boss_mult 待 P4，未写入敌人数值。",
            "rule_status": rule_status,
            "added_fields_zh": "相对 PR #4 占位新增：顶层 armor_floor_ratio / min_damage / caster_switch_clears_charge、level_scaling、"
                               "in_battle_upgrade、economy.early_call_reward_cap、"
                               "characters.*.max_copies/attack_interval_sec/range_cells/attack.{range_cells,interval_sec}/spell_energy_max/max_hp/block_count、"
                               "enemies 与 bosses 各有 7 个字段（hp、move_speed_cells_per_sec、armor、spirit_drop、leak_damage、threat_points、kill_charge）。"
                               "Boss 只在 bosses 段，leak_damage 不抄到 enemies。enemies.json 只留 ID 和表现。"
                               "扁平的 attack_interval_sec / range_cells 和嵌套的 attack 是同一对数，旧的字段路径还能读。"
                               "buffs.*.transform_at_stacks（叠到 2 层质变）、buff_offer（保底规则）、spell_charge.per_damage_by_level、stars 等。"
                               "attack_interval_sec、range_cells、move_speed 是用户确认的数值，若与 characters.json / enemies.json 不同，以本文件为准。"
                               "value_status: confirmed=用户已确认，其余为数值提议或占位，待用户拍板。",
        },
        "armor_floor_ratio": n(R["armor_floor_ratio"]),
        "min_damage": n(R["min_damage"]),
        "min_damage_status": rule_status.get("min_damage", ""),
        "caster_switch_clears_charge": bool(int(float(R.get("caster_switch_clears_charge", 1)))),
        "rounding": "round_half_away_from_zero",
        "guard": {"max_hp": n(R["base_hp"])},
        "economy": {
            "starting_spirit": n(R["start_spirit"]),
            "wave_clear_bonus": n(R["wave_clear_bonus"]),
            "early_call_reward_per_sec": n(R["early_call_reward_per_sec"]),
            "early_call_reward_cap": n(R["early_call_reward_cap"]),
            "early_start_reward_per_sec": n(R["early_start_reward_per_sec"]),
            "sell_refund_ratio_default": n(R["sell_refund_ratio"]),
            "copy_cost_increase_ratio_default": n(R["copy_cost_increase_ratio"]),
            "copy_cost_status": "pending_p6",
            "max_copies_per_character": n(R["max_copies_per_character"]),
            "max_copies_status": "abolished_q3",
            "initial_cost": blank_or_num(R, "initial_cost"),
            "cost_regen_per_sec": blank_or_num(R, "cost_regen_per_sec"),
            "max_cost": blank_or_num(R, "max_cost"),
            "cost_params_status": "pending_p7",
        },
        "spell_charge": {
            "energy_max_default": n(R["spell_energy_max_default"]),
            "per_damage": first,
            "per_damage_by_level": per_level,
            "per_damage_fallback": {"base": n(R["spell_charge_per_damage_base"]), "rule": "base_div_enemy_hp_multiplier"},
            "per_kill_default": n(enemies["enm_shade_basic"]["kill_charge"]),
            "energy_start": n(R.get("spell_energy_start", 0)),
            "auto_release_default_on": bool(int(float(R.get("auto_release_default_on", 0)))),
            "manual_release_sim_rule_zh": "模拟里手动放的假设：充满后，场上敌人 ≥%s 个、有 Boss、进入危急，或充满已等 %s 秒且敌人 ≥3 个时，再过 %s 秒反应时间放出"
                                          % (n(R.get("manual_release_min_enemies", 6)), n(R.get("manual_release_wait_sec", 8)), n(R.get("manual_release_reaction_sec", 1))),
            "damage_share": n(R["spell_charge_damage_share"]),
            "kill_share": n(R["spell_charge_kill_share"]),
            "target_full_sec_normal": n(R["spell_target_full_sec"]),
            "crisis_charge_mult": n(R["crisis_charge_mult"]),
            "design_status": "abolished_q5",
        },
        "stars": {"thresholds_lives_left": [n(x) for x in str(R["star_thresholds"]).split("|")],
                  "rule_zh": "满生命 20/20 = 3 星；剩余 ≥10 = 2 星；通关 = 1 星。星星只解锁外观和故事，不给资源",
                  "gives_resources": False},
        "buff_offer": {"every_n_waves": n(R["buff_pick_every_waves"]), "choices": n(R["buff_offer_count"]),
                       "transform_at_stacks_default": n(R["buff_transform_stacks"]),
                       "guarantee_owned_untransformed": bool(int(float(R["buff_guarantee_untransformed"]))),
                       "rule_zh": "已拥有但还没质变的强化，下一次三选一保底出现其中一个；最后一波之后那次三选一对本局无效",
                       "design_status": "abolished_q12"},
        "waves": {"advance_mode": R.get("wave_advance_mode", "spawn_window"), "spawn_window_sec": n(R["wave_spawn_window_base"]),
                  "gap_sec": n(R["wave_gap_after_clear"]), "deploy_time_sec": 10,
                  "rule_zh": "旧窗口：每波刷怪 20 秒，窗口结束 + 4 秒后下一波。Q2 已废止，不是现行节奏。",
                  "design_status": "abolished_q2"},
        "boss_rules": {"enter_waves_from_end": n(R["boss_enter_waves_from_end"]), "on_reach_guard": R["boss_on_reach_guard"],
                       "phase_hp_ratios": [n(x) for x in str(R["boss_phase_hp_ratios"]).split("|")],
                       "phase_invuln_sec": n(R["boss_phase_invuln_sec"]),
                       "hp_uses_level_mult": bool(int(float(R.get("boss_hp_uses_level_mult", 1))))},
        "terrain": {"ter_ice": {"move_speed_mult": n(R["ter_ice_speed_mult"]), "stop_on_declare_sec": n(R["ice_stop_on_declare_sec"])},
                    "ter_fog": {"range_minus_cells": n(R.get("fog_range_minus", 1)), "min_range_cells": n(R["fog_min_range"]),
                                "note_zh": "目标站在雾格上时，角色射程 −1 格（最少 1 格）。雾格和从第几波开始由关卡文件的 terrain 决定（PR #5 最新分支，和 PR #4 一致）"}},
        "in_battle_upgrade": {
            "max_level": 1 + len(up),
            "costs": up,
            "attack_mult_by_level": lvl_mult,
            "note_zh": "废止（Q6）。旧的局内升级费用和倍率留在这里，不是现行定案。",
            "design_status": "abolished_q6",
        },
        "level_scaling": {
            "enemy_hp_mult_per_level": n(R["hp_mult_per_level"]),
            "wave_budget_base": n(R["budget_base"]),
            "wave_budget_per_wave": n(R["budget_per_wave"]),
            "boss_threat_points": n(R["boss_threat"]),
            "upgrade_attack_pct": n(R["upgrade_attack_pct"]),
            "buff_offer_every_n_waves": n(R["buff_pick_every_waves"]),
            "buff_offer_choices": n(R["buff_offer_count"]),
            "meta_attack_per_level": n(R["meta_attack_per_level"]),
            "meta_level_max": n(R["meta_level_max"]),
            "per_level_table": "data/balance/level_difficulty.csv",
        },
        "characters": ch_out,
        "enemies": en_out,
        "bosses": boss_out,
        "skills": sections["skills"],
        "statuses": sections["statuses"],
        "synergies": sections["synergies"],
        "spell_cards": sections["spell_cards"],
        "buffs": bf_out,
    }
    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(stats, ensure_ascii=False, indent=2) + "\n", encoding="utf-8")
    print("已生成", OUT.relative_to(tdsim.ROOT))


if __name__ == "__main__":
    main()
