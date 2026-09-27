# -*- coding: utf-8 -*-
"""MVP 7 关（序章 + 第一章）的「系数 → 剩余生命」扫描表。

给关卡策划和试玩调参用：想让某关更难/更简单，查表看系数改多少。
用法：python tools/numeric/mvp_sweep.py （约 3–5 分钟），输出 tools/numeric/output/mvp_coef_sweep.csv
并在 docs/design/numeric/generated/mvp_coef_sweep.md 生成表格。
"""
import statistics as st

import campaign
import config as C
import run_all
import tdsim

COEFS = [round(0.3 + 0.05 * i, 2) for i in range(15)]  # 0.30 … 1.00，每 0.05 一格


def main():
    T = campaign.load_tables()
    # 用和主报告一样的推演拿到每关阵容与局外等级
    rows = campaign.run_campaign(T, "confirmed", seeds=C.SEEDS, verbose=False, stop_after="ch1_04")
    out = []
    for r in rows[:7]:
        L = campaign.scenario_level(next(x for x in T["levels"] if x["level_id"] == r["level_id"]), "confirmed")
        squad = r["squad"].split("|")
        meta = {kv.split(":")[0]: int(kv.split(":")[1]) for kv in r["meta_levels"].split("|")}
        line = dict(level_id=r["level_id"], table_coef=L["threat_budget_coef"], target=r["target"])
        for c in COEFS:
            res = campaign.simulate_level(T, L, squad, meta, C.SEEDS, c)
            line[f"c{c:.2f}"] = f'{st.mean(x["hp_left"] for x in res):.1f}/{min(x["hp_left"] for x in res):.0f}'
        out.append(line)
        print(line)
    fields = list(out[0].keys())
    run_all.write_csv(run_all.OUT / "mvp_coef_sweep.csv", out, fields)
    md = ("# MVP 7 关：威胁预算系数 → 首通剩余生命（脚本生成）\n\n"
          "每格是「5 个种子平均 / 最差种子」。阵容（序章和 ch1_01 灵梦 + 魔理沙，ch1_02–04 再加琪露诺，方案 B）和各角色局外等级按只打首通的玩家推算（同 sim_results.md）。"
          "MVP 只有 3–5 个预定槽位，剩余生命随系数是锯齿状的，相邻两格差 3–5 条命很正常；看趋势，别只看一格。"
          "用法：想让某关更紧，就往右找平均值低 1–2 的那一格；如果最差种子掉到 0 以下，说明那里有「悬崖」，别再往右。\n\n")
    md += run_all.md_table(out, fields, ["关卡", "表内系数", "目标"] + [f"{c:.2f}" for c in COEFS])
    (run_all.DOC / "mvp_coef_sweep.md").write_text(md, encoding="utf-8")


if __name__ == "__main__":
    main()
