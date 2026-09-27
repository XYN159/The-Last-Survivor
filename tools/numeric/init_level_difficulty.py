# -*- coding: utf-8 -*-
"""（一次性）生成 data/balance/level_difficulty.csv 的设计输入骨架。

平时不用跑它：它会覆盖校准好的系数和模拟结果。只有要从头重排关卡结构时才用（加 --force）。
波数按关卡策划 PR #5 最新分支：序章 3 / 4 / 10，第一章 10 / 11 / 12 / 15，第二到五章每章 10 / 12 / 14 / 16，终章 20。
MVP 7 关的出怪编组、地图、浓雾以 tools/numeric/ref_maps.json（import_pr5_maps.py 导出）为准，这里的组成只是说明。
"""
import csv
import math
import sys

import tdsim

MIX_KEYS = ("basic", "fast", "armored", "heavy", "swarm", "phantom")   # 列名 ref_mix_<key> 对应敌人 ID enm_shade_<key>
ROWS = [
    # level_id, chapter, chapter_level, role, role_zh, waves, mix(basic, fast, armored, heavy, swarm, phantom), fast_from, boss, target, fog
    ("prologue_01", "prologue", 1, "tutorial", "教学", 3, (1, 0, 0, 0, 0, 0), 1, "", 18, 1.0),
    ("prologue_02", "prologue", 2, "tutorial", "教学", 4, (1, 0, 0, 0, 0, 0), 1, "", 17, 1.0),
    ("prologue_03", "prologue", 3, "trial", "考验", 10, (1, 0, 0, 0, 0, 0), 1, "", 16, 1.0),
    ("ch1_01", "ch1", 1, "tutorial", "教学", 10, (.9, .1, 0, 0, 0, 0), 8, "", 14, 1.0),
    ("ch1_02", "ch1", 2, "practice", "练习", 11, (.5, .5, 0, 0, 0, 0), 1, "", 13, 1.0),
    ("ch1_03", "ch1", 3, "trial", "考验", 12, (.35, .55, .10, 0, 0, 0), 1, "", 12, 1.0),
    ("ch1_04", "ch1", 4, "boss", "Boss", 15, (.63, .37, 0, 0, 0, 0), 1, "boss_cirno", 11, 1.0),
    ("ch2_01", "ch2", 1, "tutorial", "教学", 10, (.5, .3, .2, 0, 0, 0), 1, "", 14, 1.0),
    ("ch2_02", "ch2", 2, "practice", "练习", 12, (.4, .25, .15, .2, 0, 0), 1, "", 13, 1.0),
    ("ch2_03", "ch2", 3, "trial", "考验", 14, (.35, .25, .15, .25, 0, 0), 1, "", 12, 1.0),
    ("ch2_04", "ch2", 4, "boss", "Boss", 16, (.35, .25, .2, .2, 0, 0), 1, "boss_ch2_sakuya_shade", 11, 1.0),
    ("ch3_01", "ch3", 1, "tutorial", "教学", 10, (.35, .2, .1, .15, .2, 0), 1, "", 14, 1.0),
    ("ch3_02", "ch3", 2, "practice", "练习", 12, (.25, .2, .15, .15, .25, 0), 1, "", 13, 1.0),
    ("ch3_03", "ch3", 3, "trial", "考验", 14, (.2, .2, .15, .2, .25, 0), 1, "", 12, 1.0),
    ("ch3_04", "ch3", 4, "boss", "Boss", 16, (.25, .2, .15, .15, .25, 0), 1, "boss_ch3_mokou_shade", 10.5, 1.0),
    ("ch4_01", "ch4", 1, "tutorial", "教学", 10, (.3, .2, .1, .15, .15, .1), 1, "", 14, 1.0),
    ("ch4_02", "ch4", 2, "practice", "练习", 12, (.2, .15, .15, .15, .15, .2), 1, "", 13, 1.0),
    ("ch4_03", "ch4", 3, "trial", "考验", 14, (.15, .15, .15, .2, .15, .2), 1, "", 12, 1.0),
    ("ch4_04", "ch4", 4, "boss", "Boss", 16, (.2, .15, .15, .15, .15, .2), 1, "boss_ch4_sanae_shade", 10.5, 1.0),
    ("ch5_01", "ch5", 1, "tutorial", "教学", 10, (.2, .15, .15, .15, .15, .2), 1, "", 13.5, 1.0),
    ("ch5_02", "ch5", 2, "practice", "练习", 12, (.15, .15, .15, .2, .15, .2), 1, "", 12.5, 1.0),
    ("ch5_03", "ch5", 3, "trial", "考验", 14, (.1, .15, .2, .2, .15, .2), 1, "", 11.5, 1.0),
    ("ch5_04", "ch5", 4, "boss", "Boss", 16, (.15, .15, .15, .2, .15, .2), 1, "boss_ch5_gatekeeper", 10.5, 1.0),
    ("final_01", "final", 1, "boss", "Boss", 20, (.15, .15, .15, .2, .15, .2), 1, "boss_wasure", 10, 1.0),
]
# 解锁 = 这一关起首通可用（方案 B，制作人 2026-09-27 定；和关卡策划 PR #5 最新分支一致）
UNLOCK = {"prologue_01": "reimu", "prologue_02": "marisa", "ch1_02": "cirno", "ch2_01": "yukari", "ch2_02": "meiling",
          "ch3_01": "sakuya", "ch3_02": "keine", "ch4_01": "mokou", "ch5_01": "sanae"}
BANNED = {}
# 制作人定：硬残影进 MVP，只在 ch1_03 少量出现（波次:只数:路线；每只从同一路线扣 4 点威胁的小/快残影）
EXTRA = {"ch1_03": "6:1:path.left;7:1:path.right;8:1:path.left;9:1:path.right;10:1:path.left;11:1:path.right;12:2:path.left"}                                     # 第五章首领改成「守门残影」，不再禁用紫
NO_BUFF = {"prologue_01", "prologue_02"}          # 序章前两关没有三选一（最终口径）
MAPPED = {"prologue_01", "prologue_02", "prologue_03", "ch1_01", "ch1_02", "ch1_03", "ch1_04"}
HEADER = ["level_id", "chapter", "chapter_level", "level_index", "level_role", "level_role_zh", "is_mvp", "wave_count",
          "threat_budget_coef", "hp_multiplier", "start_spirit", "proposed_start_spirit", "spell_charge_per_damage",
          "map_source", "fog_range_mult"] + [f"ref_mix_{k}" for k in MIX_KEYS] + [
          "fast_from_wave", "boss_enemy_id", "boss_wave", "extra_spawns", "buff_pick_waves", "unlock_characters", "banned_characters",
          "target_hp_first_clear", "reward_first_clear", "reward_repeat_2nd", "reward_repeat_3rd", "reward_repeat_floor",
          "expected_meta_level", "sim_hp_first_clear", "sim_hp_min_of_seeds", "sim_star2_share", "sim_star3_share",
          "sim_hp_focus_meta", "sim_hp_auto_spell", "sim_hp_one_copy_only", "sim_spell_full_sec_normal", "sim_duration_min"]


def main():
    if "--force" not in sys.argv:
        print("会覆盖 level_difficulty.csv，确认要重建请加 --force")
        return
    out = []
    for i, (lid, ch, cl, role, rzh, w, mix, ff, boss, tgt, fog) in enumerate(ROWS, start=1):
        hm = round(1 + 0.15 * (i - 1), 2)
        assert abs(sum(mix) - 1) < 1e-9, lid
        row = dict(
            level_id=lid, chapter=ch, chapter_level=cl, level_index=i, level_role=role, level_role_zh=rzh,
            is_mvp=1 if i <= 7 else 0, wave_count=w, threat_budget_coef="1.00", hp_multiplier=hm, start_spirit=150,
            proposed_start_spirit=int(10 * round(150 * math.sqrt(hm) / 10)), spell_charge_per_damage="",
            map_source="pr5_snapshot" if lid in MAPPED else "reference", fog_range_mult=fog,
            fast_from_wave=ff, boss_enemy_id=boss, extra_spawns=EXTRA.get(lid, ""), boss_wave=(max(1, w - 10) if boss else ""),
            # 制作人定：10 波 1 次（第 5 波后）、11–15 波 2 次、16–20 波 3 次，最后一波不弹
            buff_pick_waves="" if lid in NO_BUFF else "|".join(str(5 * k) for k in range(1, (1 if w <= 10 else 2 if w <= 15 else 3) + 1) if 5 * k < w),
            unlock_characters=UNLOCK.get(lid, ""), banned_characters=BANNED.get(lid, ""), target_hp_first_clear=tgt)
        for k, v in zip(MIX_KEYS, mix):
            row[f"ref_mix_{k}"] = v
        out.append(row)
    with open(tdsim.DATA / "balance" / "level_difficulty.csv", "w", newline="", encoding="utf-8") as f:
        wr = csv.DictWriter(f, fieldnames=HEADER, lineterminator="\n", extrasaction="ignore")
        wr.writeheader()
        wr.writerows(out)
    print("已重建 data/balance/level_difficulty.csv，共", len(out), "关")


if __name__ == "__main__":
    main()
