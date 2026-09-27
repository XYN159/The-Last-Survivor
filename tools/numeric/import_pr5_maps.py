# -*- coding: utf-8 -*-
"""把关卡策划 PR #5 的 MVP 关卡文件（data/levels/<关卡>.json）导出成模拟用的快照 tools/numeric/ref_maps.json。

用法：python import_pr5_maps.py <PR #5 分支的仓库目录>
    例：git clone -b cursor/design-level-framework-01a3 https://github.com/XYN159/Touhou-forgotten-defense /tmp/pr5
        python import_pr5_maps.py /tmp/pr5

只取模拟需要的字段：
- 格子：B 墙 → #，P/S/G 路线 → P，「.」预定槽位（只能放在这里）
- 路线格子（多条路线各自独立）
- 浓雾格子和从第几波开始（效果：目标站在雾格上时，角色射程 −1 格）
- 首领格子集合（ch1_04：冰瀑落点、完美冻结半径、钻石风暴冰面）
- 逐波编组：每组 敌人 / 路线 / 个数 / 间隔 / 延迟（系数 1.0 时的原样；模拟里个数 × 系数）
PR #5 合并后可以改成直接读 data/levels/<关卡>.json。
"""
import json
import subprocess
import sys
from pathlib import Path

MVP = ["prologue_01", "prologue_02", "prologue_03", "ch1_01", "ch1_02", "ch1_03", "ch1_04"]
OUT = Path(__file__).resolve().parent / "ref_maps.json"


def start_wave(s):
    s = str(s or "level_start")
    return int(s.split("_")[1]) if s.startswith("wave_") else 1


def main():
    if len(sys.argv) < 2:
        print(__doc__)
        return
    root = Path(sys.argv[1])
    try:
        head = subprocess.run(["git", "-C", str(root), "log", "-1", "--format=%H %cI"], capture_output=True,
                              text=True).stdout.strip()
    except Exception:
        head = ""
    levels = {}
    for lid in MVP:
        d = json.loads((root / "data" / "levels" / f"{lid}.json").read_text(encoding="utf-8"))
        m = d["map"]
        grid = ["".join("#" if ch == "B" else ("." if ch == "." else "P") for ch in row) for row in m["cells"]]
        fog = [dict(cells=t["cells"], from_wave=start_wave(t.get("start"))) for t in m.get("terrain", [])
               if t.get("terrain_id") == "ter_fog"]
        boss = {}
        for b in d.get("bosses", []):
            for ph in b.get("phases", []):
                ref = ph.get("cells_ref")
                cs = m.get("cell_sets", {}).get(ref)
                boss[ph["id"]] = dict(cells=cs if isinstance(cs, list) else [],
                                      radius=(cs or {}).get("radius_cells", 0) if isinstance(cs, dict) else 0,
                                      terrain=ph.get("terrain_id", ""), duration_sec=ph.get("duration_sec", 0),
                                      freeze_characters=ph.get("status_on_character") == "st_freeze",
                                      freeze_shades=ph.get("status_on_shade") == "st_freeze")
            boss["_enters_at_wave"] = int(b["enters_at_wave_id"][1:])
            boss["_path"] = b.get("path_id")
        waves = []
        for w in d["waves"]:
            waves.append(dict(wave=int(w["wave_id"][1:]), duration_sec=w.get("duration_sec", 20),
                              delay_sec=w.get("delay_sec", 4), ends_when=w.get("ends_when", "spawn_window"),
                              is_boss=bool(w.get("is_boss")),
                              spawns=[dict(enemy_id=s["enemy_id"], path=s["path_id"], count=s["count"],
                                           interval_sec=s.get("interval_sec", 1.0), delay_sec=s.get("delay_sec", 0))
                                      for s in w["spawns"]]))
        levels[lid] = dict(grid=grid, paths=[dict(id=p["id"], cells=p["cells"]) for p in m["paths"]],
                           slots=[[s["col"], s["row"]] for s in m.get("slots", [])], fog=fog, boss=boss,
                           waves=waves, deploy_time_sec=d.get("deploy_time_sec", 10),
                           spell_charge_mult=d.get("spell_charge_mult", 1.0),
                           available_characters=[c.replace("chr_", "") for c in d.get("params", {}).get("available_character_ids", [])],
                           unlock_on_clear=[c.replace("chr_", "") for c in d.get("unlock_character_ids", [])])
    OUT.write_text(json.dumps(dict(
        _note_zh=("关卡策划 PR #5（分支 cursor/design-level-framework-01a3，提交 " + head + "）里 MVP 7 关的快照，"
                  "由 tools/numeric/import_pr5_maps.py 导出。格子：# 墙 / . 预定槽位（只能放这里）/ P 路线。"
                  "浓雾 = 目标站在雾格上时射程 −1 格；ch1_04 首领三阶段的格子；逐波编组是系数 1.0 时的原样，"
                  "模拟里每组个数 × 本关系数。关卡策划改图后请重新导出。"),
        levels=levels), ensure_ascii=False, indent=1), encoding="utf-8")
    print("已写", OUT, "共", len(levels), "关；来源", head)


if __name__ == "__main__":
    main()
