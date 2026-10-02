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


def main():
    R = tdsim.load_rules()
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
            "value_status": c["status"],
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
        if float(e.get("block_dps") or 0) > 0:
            extra["block_dps"] = n(e["block_dps"])
        d.update(extra)
        en_out[e["enemy_id"]] = d
        if e["category"] == "boss":
            boss_out[e["enemy_id"]] = d

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
                       "用户已确认的值与 PR #4 占位冲突时一律以用户确认值为准（如灵梦攻击 20、硬残影护甲 10）。",
            "added_fields_zh": "相对 PR #4 占位新增：顶层 armor_floor_ratio / min_damage / caster_switch_clears_charge、level_scaling、"
                               "in_battle_upgrade、economy.early_call_reward_cap、"
                               "characters.*.max_copies/attack_interval_sec/range_cells/attack.{range_cells,interval_sec}/spell_energy_max/max_hp/block_count、"
                               "enemies 与 bosses 的同一份 7 个字段（hp、move_speed_cells_per_sec、armor、spirit_drop、leak_damage、threat_points、kill_charge）。"
                               "Boss 两处都有，数字相同；#4 的正式路径仍是 bosses.<id>。enemies.json 只留 ID 和表现。"
                               "扁平的 attack_interval_sec / range_cells 和嵌套的 attack 是同一对数，旧的字段路径还能读。"
                               "buffs.*.transform_at_stacks（叠到 2 层质变）、buff_offer（保底规则）、spell_charge.per_damage_by_level、stars 等。"
                               "attack_interval_sec、range_cells、move_speed 是用户确认的数值，若与 characters.json / enemies.json 不同，以本文件为准。"
                               "value_status: confirmed=用户已确认，其余为数值提议或占位，待用户拍板。",
        },
        "armor_floor_ratio": n(R["armor_floor_ratio"]),
        "min_damage": n(R["min_damage"]),
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
            "max_copies_per_character": n(R["max_copies_per_character"]),
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
        },
        "stars": {"thresholds_lives_left": [n(x) for x in str(R["star_thresholds"]).split("|")],
                  "rule_zh": "满生命 20/20 = 3 星；剩余 ≥10 = 2 星；通关 = 1 星。星星只解锁外观和故事，不给资源",
                  "gives_resources": False},
        "buff_offer": {"every_n_waves": n(R["buff_pick_every_waves"]), "choices": n(R["buff_offer_count"]),
                       "transform_at_stacks_default": n(R["buff_transform_stacks"]),
                       "guarantee_owned_untransformed": bool(int(float(R["buff_guarantee_untransformed"]))),
                       "rule_zh": "已拥有但还没质变的强化，下一次三选一保底出现其中一个；最后一波之后那次三选一对本局无效"},
        "waves": {"advance_mode": R.get("wave_advance_mode", "spawn_window"), "spawn_window_sec": n(R["wave_spawn_window_base"]),
                  "gap_sec": n(R["wave_gap_after_clear"]), "deploy_time_sec": 10,
                  "rule_zh": "每波刷怪窗口 20 秒，窗口结束 + 4 秒后下一波，不等清场（关卡策划 PR #5 ends_when = spawn_window）"},
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
            "note_zh": "局内从 1 级升到 max_level。costs 是第 1 次、第 2 次升级的灵力。attack_mult_by_level 下标 0 是 1 级。和每个角色上的 upgrade_costs、level_attack_mult 相同。",
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
