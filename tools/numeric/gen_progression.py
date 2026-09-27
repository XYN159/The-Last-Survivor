# -*- coding: utf-8 -*-
"""按 config.py 的公式生成 data/progression/ 下的局外养成表。"""
import csv

import config as C
import tdsim


def round5(x):
    return int(5 * round(x / 5))


def level_cost(n):
    k = n - 1
    return round5(C.LEVEL_COST_A + C.LEVEL_COST_B * k + C.LEVEL_COST_C * k * k)


def main():
    R = tdsim.load_rules()
    out = tdsim.DATA / "progression"
    out.mkdir(exist_ok=True)
    maxlv = int(R["meta_level_max"])
    with open(out / "character_level_cost.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["level", "cost_to_next", "cumulative_cost_from_1", "attack_multiplier"])
        cum = 0
        for lv in range(1, maxlv + 1):
            cost = level_cost(lv) if lv < maxlv else ""
            w.writerow([lv, cost, cum, round(tdsim.meta_attack_mult(lv, R["meta_attack_per_level"]), 2)])
            if lv < maxlv:
                cum += level_cost(lv)
    # 奖励列写回 data/balance/level_difficulty.csv（按 level_id 对应），其他列保持不变
    levels = tdsim.load_levels()
    for L in levels:
        i = int(L["level_index"])
        base = C.FIRST_CLEAR_BASE + C.FIRST_CLEAR_STEP * (i - 1)
        if L["level_role"] == "boss":
            base *= C.BOSS_REWARD_MULT
        fc = round5(base)
        L["reward_first_clear"] = fc
        L["reward_repeat_2nd"] = round5(fc * C.REPEAT_RATIOS[0])
        L["reward_repeat_3rd"] = round5(fc * C.REPEAT_RATIOS[1])
        L["reward_repeat_floor"] = round5(fc * C.REPEAT_RATIOS[2])
    with open(tdsim.DATA / "balance" / "level_difficulty.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(levels[0].keys()), lineterminator="\n")
        w.writeheader()
        w.writerows(levels)
    with open(out / "meta_rules.csv", "w", encoding="utf-8", newline="") as f:
        w = csv.writer(f)
        w.writerow(["rule_key", "value", "status", "description_zh"])
        rows = [
            ("currency_name", C.CURRENCY_NAME, "proposal", "局外养成货币暂名，待文案策划确认；只能靠通关获得，没有任何购买渠道"),
            ("level_cost_formula", f"{C.LEVEL_COST_A}+{C.LEVEL_COST_B}*(n-1)+{C.LEVEL_COST_C}*(n-1)^2", "proposal", "每个角色各自 1–20 级；n 级升 n+1 级的花费，取整到 5"),
            ("first_clear_formula", f"{C.FIRST_CLEAR_BASE}+{C.FIRST_CLEAR_STEP}*(L-1)", "proposal", "第 L 关（全局序号）首通奖励，Boss 关再乘 boss_reward_mult，取整到 5"),
            ("boss_reward_mult", C.BOSS_REWARD_MULT, "proposal", "Boss 关首通奖励倍率"),
            ("star_reward", 0, "confirmed", "星星只解锁外观和故事，不给任何资源（系统策划 PR #3）；补拿星靠重打"),
            ("focus_count_checked", C.FOCUS_COUNT, "proposal", "模拟验证了两种分法：平均分给出战阵容 / 集中培养前 3 人，都不需要刷关"),
            ("repeat_ratio_2nd", C.REPEAT_RATIOS[0], "proposal", "第 2 次通关奖励比例"),
            ("repeat_ratio_3rd", C.REPEAT_RATIOS[1], "proposal", "第 3 次通关奖励比例"),
            ("repeat_ratio_floor", C.REPEAT_RATIOS[2], "proposal", "第 4 次起的保底比例"),
            ("catch_up_gap", C.CATCH_UP_GAP, "proposal", "比最高等级角色低这么多级及以上时享受追赶折扣"),
            ("catch_up_discount", C.CATCH_UP_DISCOUNT, "proposal", "追赶折扣（0.5 = 花费打 5 折）"),
            ("join_level_rule", C.JOIN_RULE, "proposal", "新角色加入时等级 = 已有角色平均等级向下取整"),
            ("fail_reward", 0, "proposal", "失败不给碎片，也不扣任何东西"),
        ]
        w.writerows(rows)
    print("已生成 data/progression/character_level_cost.csv、meta_rules.csv，并写入 level_difficulty.csv 的 reward_* 列")


if __name__ == "__main__":
    main()
