#!/usr/bin/env python3
"""校验 data/levels 的关卡 JSON。

设计期要严：坏文件直接失败。以后游戏里的读取器要宽，坏文件警告并回退，不闪退。
规则与 tests/unit/test_level_data.gd 里的几何和威胁检查保持一致。
"""

from __future__ import annotations

import json
import sys
from pathlib import Path

from jsonschema import Draft202012Validator
from jsonschema.exceptions import ValidationError

ROOT = Path(__file__).resolve().parents[1]
LEVEL_DIR = ROOT / "data" / "levels"
BALANCE_PATH = ROOT / "data" / "balance" / "level_difficulty.json"
STATS_PATH = ROOT / "data" / "balance" / "combat" / "stats.json"
DIFFICULTY_FIELDS = (
    "threat_budget_coef",
    "wave_threat_budgets",
    "threat_budget_total",
    "target_lives_first_clear",
)
# 第 6–11 波各 1 只，第 12 波左右各 1 只。左、右、左、右、左、右，再左右各一只。
CH1_03_ARMOR = {
    6: [("path.left", 1)],
    7: [("path.right", 1)],
    8: [("path.left", 1)],
    9: [("path.right", 1)],
    10: [("path.left", 1)],
    11: [("path.right", 1)],
    12: [("path.left", 1), ("path.right", 1)],
}
SCHEMA_PATH = LEVEL_DIR / "level.schema.json"
KNOWN_ENEMIES = (
    "enm_shade_basic",
    "enm_shade_fast",
    "enm_shade_armored",
    "boss_cirno",
)
STARTERS = ["chr_reimu"]
EXPECTED_COUNTS = {
    "prologue": 3,
    "ch1": 4,
    "ch2": 4,
    "ch3": 4,
    "ch4": 4,
    "ch5": 4,
    "final": 1,
}
CHAPTER_ORDER = list(EXPECTED_COUNTS)
ORTHOGONAL = ((1, 0), (-1, 0), (0, 1), (0, -1))
ROUTE = {"P", "S", "G"}
STAT_KEYS = {"hp", "move_speed", "armor", "spirit_on_kill", "lives_on_leak", "stats"}


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"{path}: 不是合法 JSON：{error}") from error


def load_difficulty(path: Path) -> dict | None:
    """文件来自 PR #8。合并前不存在时只警告，不把缺文件当成错误。"""
    if not path.is_file():
        print(
            "警告：找不到 data/balance/level_difficulty.json。"
            "这份文件由 PR #8（分支 numeric/touhou-td-framework）提供，"
            "本 PR 要在 #8 之后合并。威胁预算核对已跳过。",
            file=sys.stderr,
        )
        return None
    data = load_json(path)
    levels = data.get("levels")
    if not isinstance(levels, dict):
        raise SystemExit(f"{path}: 缺少 levels")
    for row in levels.values():
        if "wave_threat_budgets" in row:
            row["wave_threat_budgets"] = [int(item) for item in row["wave_threat_budgets"]]
        if "threat_budget_total" in row:
            row["threat_budget_total"] = int(row["threat_budget_total"])
    return {"levels": levels}


def load_stats(path: Path) -> dict | None:
    """属性表来自 PR #8。还不在仓库里时只警告，不把缺文件当成错误。"""
    if not path.is_file():
        print(
            "警告：找不到 data/balance/combat/stats.json。"
            "星级阈值、敌人威胁点和生命以 PR #8 的这份文件为准。"
            "本 PR 不附带它，相关数字检查已跳过。",
            file=sys.stderr,
        )
        return None
    return load_json(path)


def threat_table(stats: dict | None) -> dict[str, int] | None:
    if stats is None:
        return None
    table: dict[str, int] = {}
    for bucket in ("enemies", "bosses"):
        rows = stats.get(bucket, {})
        if not isinstance(rows, dict):
            continue
        for enemy_id, row in rows.items():
            if isinstance(row, dict) and row.get("threat_points") is not None:
                table[enemy_id] = int(row["threat_points"])
    return table


def pointer_value(stats: dict, pointer: str):
    if "#" not in pointer:
        return None
    path = pointer.split("#", 1)[1].strip("/")
    node = stats
    for part in path.split("/"):
        if not isinstance(node, dict) or part not in node:
            return None
        node = node[part]
    return node


def cell_char(grid: list[str], col: int, row: int) -> str | None:
    if row < 0 or row >= len(grid) or col < 0 or col >= len(grid[row]):
        return None
    return grid[row][col]


def geometry_problems(level: dict) -> list[str]:
    problems: list[str] = []
    level_map = level["map"]
    grid = level_map["cells"]
    if len(grid) != 12 or any(len(row) != 7 for row in grid):
        problems.append("地图不是 7 列 × 12 行")
        return problems
    entrances = {item["id"]: (item["col"], item["row"]) for item in level_map["entrances"]}
    guard = tuple(level_map["guard"]["cell"])
    if cell_char(grid, guard[0], guard[1]) != "G":
        problems.append("守护点不是 G")
    if level_map["guard"]["id"] != level["guard_point"]["id"]:
        problems.append("地图上的守护点和关卡守护点不是同一个")
    covered: set[tuple[int, int]] = set()
    path_ids = set()
    parsed_paths = []
    for path in level_map["paths"]:
        path_ids.add(path["path_id"])
        if path["id"] != path["path_id"]:
            problems.append(f"{path['path_id']} 的 id 和 path_id 不一致")
        cells = [tuple(item) for item in path["cells"]]
        parsed_paths.append((path, cells))
    starts = {cells[0] for _path, cells in parsed_paths if cells}
    for path, cells in parsed_paths:
        if path["entrance_id"] not in entrances:
            problems.append(f"{path['path_id']} 的入口不存在")
        if not cells:
            problems.append(f"{path['path_id']} 是空的")
            continue
        if path["entrance_id"] in entrances and cells[0] != entrances[path["entrance_id"]]:
            problems.append(f"{path['path_id']} 没有从入口出发")
        if cells[-1] != guard:
            problems.append(f"{path['path_id']} 没有走到守护点")
        previous = None
        for col, row in cells:
            char = cell_char(grid, col, row)
            if (col, row) == guard:
                expected = "G"
            elif (col, row) in starts:
                expected = "S"
            else:
                expected = "P"
            if char != expected:
                problems.append(f"{path['path_id']} 在 ({col},{row}) 应是 {expected}，实际是 {char}")
            if previous is not None:
                delta = abs(col - previous[0]) + abs(row - previous[1])
                if delta != 1:
                    problems.append(f"{path['path_id']} 在 ({previous[0]},{previous[1]}) 到 ({col},{row}) 不连续")
            previous = (col, row)
            covered.add((col, row))
    for row, line in enumerate(grid):
        for col, char in enumerate(line):
            if char == "P" and (col, row) not in covered:
                problems.append(f"路线格 ({col},{row}) 没有任何一条路径走过")
            if char == "S" and (col, row) not in starts:
                problems.append(f"裂缝 ({col},{row}) 不是任何路线的起点")
    slot_cells = set()
    for spot in level_map["slots"]:
        col, row = spot["col"], spot["row"]
        slot_cells.add((col, row))
        if cell_char(grid, col, row) != ".":
            problems.append(f"预定槽位 {spot['id']} 不是 .")
            continue
        adjacent = any(cell_char(grid, col + dx, row + dy) in ROUTE for dx, dy in ORTHOGONAL)
        if not adjacent:
            problems.append(f"预定槽位 {spot['id']} 没有贴着路线")
    dots = {
        (col, row)
        for row, line in enumerate(grid)
        for col, char in enumerate(line)
        if char == "."
    }
    if dots != slot_cells:
        problems.append("预定槽位必须和每一个 . 一一对应，不能再有没列入名单的可放置格")
    enters = level["bosses"][0]["enters_at_wave_id"] if level["bosses"] else None
    wave_ids = []
    for index, wave in enumerate(level["waves"]):
        wave_ids.append(wave["id"])
        if wave["wave_id"] != wave["id"]:
            problems.append(f"{wave['id']} 的 wave_id 不一致")
        if wave["is_boss"] != (wave["id"] == enters):
            problems.append(f"{wave['id']} 的 is_boss 应该只在首领入场那一波为真")
        if index + 1 < len(level["waves"]):
            expected_gap = level["waves"][index + 1]["delay_sec"]
            if wave["next_wave_delay_sec"] != expected_gap:
                problems.append(f"{wave['id']} 的 next_wave_delay_sec 没有等于下一波的 delay_sec")
        elif wave["next_wave_delay_sec"] != 0:
            problems.append(f"{wave['id']} 是最后一波，next_wave_delay_sec 应该是 0")
        for spawn in wave["spawns"]:
            if spawn["entrance_id"] not in entrances:
                problems.append(f"{wave['id']} 使用了不存在的入口")
            if spawn["path_id"] not in path_ids:
                problems.append(f"{wave['id']} 使用了不存在的路径")
    if len(wave_ids) != len(set(wave_ids)):
        problems.append("波次 id 重复")
    problems.extend(terrain_problems(level, set(wave_ids)))
    return problems


def terrain_problems(level: dict, wave_ids: set[str]) -> list[str]:
    problems: list[str] = []
    grid = level["map"]["cells"]
    for effect in level["map"]["terrain"]:
        start = effect["start"]
        if start != "level_start":
            number = int(start.split("_", 1)[1])
            if f"w{number:02d}" not in wave_ids:
                problems.append(f"{effect['terrain_id']} 的 {start} 没有对应波次")
        if effect["duration_sec"] != -1 and effect["duration_sec"] <= 0:
            problems.append(f"{effect['terrain_id']} 的持续时间不对")
        cells = effect.get("cells", [])
        for col, row in cells:
            char = cell_char(grid, col, row)
            if char is None:
                problems.append(f"{effect['terrain_id']} 盖到了地图外")
                continue
            if effect["terrain_id"] == "ter_ice" and char not in ROUTE:
                problems.append(f"冰面 ({col},{row}) 不在路线上")
            if effect["terrain_id"] == "ter_icicle" and char == ".":
                continue
            if effect["terrain_id"] == "ter_icicle" and char != ".":
                problems.append(f"冰柱 ({col},{row}) 必须在可放置格")
    return problems


def boss_problems(level: dict) -> list[str]:
    problems: list[str] = []
    wave_ids = [wave["id"] for wave in level["waves"]]
    wave_set = set(wave_ids)
    path_ids = {path["path_id"] for path in level["map"]["paths"]}
    for boss in level["bosses"]:
        blocked = boss.get("blocks_character_id")
        if blocked and blocked in level["params"]["available_character_ids"]:
            problems.append(f"{boss['id']} 决斗时仍然可以放置")
        if boss["enters_at_wave_id"] not in wave_set:
            problems.append(f"{boss['id']} 的入场波次不存在")
        if boss["path_id"] not in path_ids:
            problems.append(f"{boss['id']} 的路线不存在")
        prelude = boss["prelude_wave_ids"]
        if len(prelude) != len(set(prelude)) or not set(prelude) <= wave_set:
            problems.append(f"{boss['id']} 的前奏波次无效")
        if boss["id"] == "boss_cirno":
            problems.extend(cirno_problems(level, boss))
    problems.extend(wave_count_span_problems(level, len(wave_ids)))
    return problems


def wave_count_span_problems(level: dict, count: int) -> list[str]:
    if level["chapter_id"] == "prologue" and level["index_in_chapter"] <= 2:
        if count >= 5:
            return [f"序章教学关波次数 {count} 应该少于 5，这样才没有三选一"]
        if count < 3:
            return [f"序章教学关波次数 {count} 至少要有 3 波"]
        return []
    if not 10 <= count <= 20:
        return [f"波次数 {count} 不在 10 到 20"]
    return []


def cirno_problems(level: dict, boss: dict) -> list[str]:
    problems: list[str] = []
    phases = boss["phases"]
    expected = [
        ("phase_1", 1.0, 0.66, "sc_boss_cirno_icicle_fall", "boss_cirno_p1_icicles"),
        ("phase_2", 0.66, 0.33, "sc_boss_cirno_perfect_freeze", "boss_cirno_p2_area"),
        ("phase_3", 0.33, 0.0, "sc_boss_cirno_diamond_blizzard", "boss_cirno_p3_ice"),
    ]
    if len(phases) != 3:
        return ["琪露诺应该有 3 个血量阶段"]
    cell_sets = level["map"]["cell_sets"]
    grid = level["map"]["cells"]
    good = {(spot["col"], spot["row"]) for spot in level["map"]["slots"]}
    route = {tuple(cell) for path in level["map"]["paths"] for cell in path["cells"]}
    for phase, (phase_id, start, end, spell_id, cells_ref) in zip(phases, expected):
        if phase["id"] != phase_id or phase["spell_card_id"] != spell_id or phase["cells_ref"] != cells_ref:
            problems.append(f"{phase_id} 的符卡或格子集合不对")
        if round(phase["hp_ratio_start"], 2) != start or round(phase["hp_ratio_end"], 2) != end:
            problems.append(f"{phase_id} 的血量区间不是 {start} 到 {end}")
        if cells_ref not in cell_sets:
            problems.append(f"缺少格子集合 {cells_ref}")
    icicles = cell_sets.get("boss_cirno_p1_icicles")
    if isinstance(icicles, list):
        if not 3 <= len(icicles) <= 5:
            problems.append("冰瀑落点应该是 3 到 5 格")
        for col, row in icicles:
            if cell_char(grid, col, row) != ".":
                problems.append(f"冰柱 ({col},{row}) 不在可放置格")
            near = (col, row) in good or any((col + dx, row + dy) in good for dx, dy in ORTHOGONAL)
            if not near:
                problems.append(f"冰柱 ({col},{row}) 没有落在预定槽位上或贴着预定槽位")
    area = cell_sets.get("boss_cirno_p2_area")
    if not isinstance(area, dict) or area.get("mode") != "radius_around_boss" or area.get("radius_cells") != 2.5:
        problems.append("完美冻结应该写成跟着首领、半径 2.5 格，而不是写死的格子")
    ice = cell_sets.get("boss_cirno_p3_ice")
    if isinstance(ice, list):
        if len(ice) != 10:
            problems.append("钻石风暴应该是 10 个路线格")
        for col, row in ice:
            if (col, row) not in route or cell_char(grid, col, row) != "P":
                problems.append(f"冰面 ({col},{row}) 不是普通路线格")
    if phases[0].get("terrain_id") != "ter_icicle" or phases[0].get("duration_sec") != 12:
        problems.append("冰瀑应引用 ter_icicle，持续 12 秒")
    if phases[0].get("status_on_character") != "st_freeze":
        problems.append("冰瀑落在角色身上应引用 st_freeze")
    if phases[2].get("terrain_id") != "ter_ice" or phases[2].get("duration_sec") != -1:
        problems.append("钻石风暴应把格子变成一直存在的 ter_ice")
    return problems


def wave_threat(wave: dict, threats: dict[str, int]) -> tuple[int, list[str]]:
    total = 0
    problems: list[str] = []
    for spawn in wave["spawns"]:
        enemy_id = spawn["enemy_id"]
        if enemy_id not in threats:
            problems.append(f"波次使用了图鉴里没有威胁点的敌人 {enemy_id}")
            continue
        total += spawn["count"] * threats[enemy_id]
    return total, problems


def threat_problems(level: dict, threats: dict[str, int], row: dict, catalog_ids: set[str]) -> list[str]:
    """按 PR #8 的分波预算和全关合计核对。只认 target_lives_first_clear。"""
    problems: list[str] = []
    for field in DIFFICULTY_FIELDS:
        if field not in row:
            problems.append(f"难度行缺少 {field}")
    budgets = row.get("wave_threat_budgets")
    if not isinstance(budgets, list):
        return problems
    if len(level["waves"]) != len(budgets):
        problems.append(f"波次数 {len(level['waves'])} 和难度表的 {len(budgets)} 不一致")
        return problems
    summed = 0
    for wave, budget in zip(level["waves"], budgets):
        total, missing = wave_threat(wave, threats)
        problems.extend(missing)
        summed += total
        if total != budget:
            extra = ""
            if level["id"] == "ch1_04":
                extra = "。入场仍是第 5 波，等制作人拍板。建议看 levels.ch1_04.threat_budget_coef_if_boss_fix"
            problems.append(f"{wave['id']} 的威胁 {total} 不是难度表里的 {budget}{extra}")
    expected_total = row.get("threat_budget_total")
    if expected_total is None or summed != expected_total:
        problems.append(f"全关威胁 {summed} 不是难度表里的 {expected_total}")
    elif sum(budgets) != expected_total:
        problems.append("难度表的分波预算加总不等于 threat_budget_total")
    for boss in level["bosses"]:
        if boss["id"] not in catalog_ids:
            problems.append(f"图鉴里没有首领 {boss['id']}")
        elif threats.get(boss["id"], 0):
            problems.append(f"{boss['id']} 不该占用波次预算")
    return problems


def composition_problems(level: dict, threats: dict[str, int]) -> list[str]:
    problems: list[str] = []
    level_id = level["id"]
    wave_count = len(level["waves"])
    offers = {wave for wave in (5, 10, 15, 20) if wave < wave_count}
    swift_threat = 0
    total_threat = 0
    basic = "enm_shade_basic"
    fast = "enm_shade_fast"
    armored = "enm_shade_armored"
    for index, wave in enumerate(level["waves"], start=1):
        note = wave.get("note", "")
        if (index in offers) != ("三选一" in note):
            problems.append(f"{wave['id']} 的备注没有和三选一时机对上")
        for spawn in wave["spawns"]:
            enemy_id = spawn["enemy_id"]
            if enemy_id not in threats:
                continue
            threat = spawn["count"] * threats[enemy_id]
            total_threat += threat
            if enemy_id == fast:
                swift_threat += threat
            if enemy_id == armored and level_id != "ch1_03":
                problems.append(f"{level_id} 不该出现硬残影。MVP 里只有第一章第 3 关可以出")
            allowed = (basic, fast, armored) if level_id == "ch1_03" else (basic, fast)
            if level["chapter_id"] in ("prologue", "ch1") and enemy_id not in allowed:
                problems.append(f"{level_id} 的 MVP 敌人不对")
    if level["chapter_id"] == "prologue" and swift_threat:
        problems.append(f"{level_id} 只该有小残影")
    if level_id == "ch1_01":
        for index, wave in enumerate(level["waves"], start=1):
            has_fast = any(spawn["enemy_id"] == fast for spawn in wave["spawns"])
            if index < 6 and has_fast:
                problems.append("教学关的快残影不该在第 6 波之前出现")
            if index >= 6 and not has_fast:
                problems.append(f"{wave['id']} 从第 6 波起应该有快残影")
        if total_threat and not 0.27 <= swift_threat / total_threat <= 0.33:
            problems.append(f"教学关快残影威胁占比 {swift_threat / total_threat:.3f} 不在三成附近")
    if level_id == "ch1_02":
        for wave in level["waves"]:
            kinds = {spawn["enemy_id"] for spawn in wave["spawns"]}
            if kinds != {basic, fast}:
                problems.append(f"{wave['id']} 没有把小残影和快残影混在同一波")
        if total_threat and not 0.45 <= swift_threat / total_threat <= 0.55:
            problems.append(f"练习关快残影占比 {swift_threat / total_threat:.3f} 不在一半附近")
    if level_id == "ch1_03":
        if "enm_shade_armored" not in level.get("new_enemy_ids", []):
            problems.append("第一章第 3 关的新敌人应该包含硬残影")
        basic_points = 0
        swift_points = 0
        for index, wave in enumerate(level["waves"], start=1):
            starters = [spawn for spawn in wave["spawns"] if spawn["enemy_id"] in (basic, fast)]
            delays = [spawn["delay_sec"] for spawn in starters]
            paths = {spawn["path_id"] for spawn in starters}
            if len(starters) < 2 or any(delay != 0 for delay in delays) or paths != {"path.left", "path.right"}:
                problems.append(f"{wave['id']} 没有左右同时出场")
            armored_spawns = [spawn for spawn in wave["spawns"] if spawn["enemy_id"] == armored]
            got = [(spawn["path_id"], spawn["count"]) for spawn in armored_spawns]
            if got != CH1_03_ARMOR.get(index, []):
                problems.append(f"{wave['id']} 的硬残影数量或路线不对")
            for spawn in armored_spawns:
                if not 8 <= spawn["delay_sec"] <= 12:
                    problems.append(f"{wave['id']} 的硬残影应该在第 8 到 12 秒出场")
            for spawn in starters:
                if spawn["enemy_id"] == basic:
                    basic_points += spawn["count"]
                else:
                    swift_points += spawn["count"]
        shade_points = basic_points + swift_points
        if shade_points and not 0.35 <= basic_points / shade_points <= 0.45:
            problems.append(f"分叉关小残影占比 {basic_points / shade_points:.3f} 不在四成附近")
    if level_id == "prologue_03":
        for index, wave in enumerate(level["waves"], start=1):
            if index < 6:
                continue
            paths = {spawn["path_id"] for spawn in wave["spawns"]}
            delays = [spawn["delay_sec"] for spawn in wave["spawns"]]
            if len(wave["spawns"]) < 2 or paths != {"path.main"} or any(delay != 0 for delay in delays):
                problems.append(f"{wave['id']} 后半应该两组同时走同一条路")
    if level_id == "ch1_04":
        boss = level["bosses"][0]
        enter = boss.get("enter_wave")
        if enter != 5:
            problems.append("冰之残影的 enter_wave 现在仍是 5，等制作人拍板后再改")
        if not isinstance(enter, int):
            problems.append("冰之残影要有整数 enter_wave")
            enter = 5
        expected_wave = f"w{enter:02d}"
        if boss["enters_at_wave_id"] != expected_wave:
            problems.append("enters_at_wave_id 要和 enter_wave 是同一波")
        expected_prelude = [f"w{index:02d}" for index in range(1, enter)]
        if boss["prelude_wave_ids"] != expected_prelude:
            problems.append("冰之残影的前奏应该是入场前的每一波")
        for index, wave in enumerate(level["waves"], start=1):
            if wave.get("is_boss") != (index == enter):
                problems.append(f"{wave['id']} 的 is_boss 要和 enter_wave 一致")
            expected_pressure = "minion" if index < enter or index % 2 == 0 else "boss_phase"
            if wave.get("pressure") != expected_pressure:
                problems.append(f"{wave['id']} 的压力应该是 {expected_pressure}")
        spell_ids = [phase["spell_card_id"] for phase in boss["phases"]]
        if len(spell_ids) != len(set(spell_ids)):
            problems.append("一个阶段一张符卡，不能重复")
    return problems


def timing_problems(level: dict) -> list[str]:
    problems: list[str] = []
    prologue = level["chapter_id"] == "prologue"
    if level["spell_charge_mult"] != (2.0 if prologue else 1.0):
        problems.append("符卡充能倍率和战斗草案的建议不一致")
    if level["deploy_wait_for_player"] is not prologue:
        problems.append("只有序章应该等玩家放完再开始倒计时")
    if level["intermission_sec"] != 4 or level["deploy_time_sec"] != 10:
        problems.append("布阵或波间秒数不是战斗草案的默认值")
    if prologue:
        note = level.get("combat_timing_note", "")
        if "10" not in note or "第一个角色" not in note:
            problems.append("序章要写明倒计时停在 10 秒，放下第一个角色后才倒数")
    waves = level["waves"]
    for index, wave in enumerate(waves):
        last = index == len(waves) - 1
        if wave.get("duration_sec") != 20:
            problems.append(f"{wave['id']} 的刷怪窗口应该是 20 秒")
        expected_delay = 0 if index == 0 else 4
        if wave.get("delay_sec") != expected_delay:
            problems.append(f"{wave['id']} 的 delay_sec 应该是 {expected_delay}")
        next_delay = 0 if last else waves[index + 1]["delay_sec"]
        if wave.get("next_wave_delay_sec") != next_delay:
            problems.append(f"{wave['id']} 的 next_wave_delay_sec 应该等于下一波的 delay_sec")
        boss_last = last and level["id"] == "ch1_04"
        expected_end = "boss_defeated" if boss_last else "spawn_window"
        if wave.get("ends_when") != expected_end:
            problems.append(f"{wave['id']} 的结束条件应该是 {expected_end}")
        for spawn in wave["spawns"]:
            count = spawn["count"]
            if count <= 1:
                continue
            end = spawn["delay_sec"] + (count - 1) * spawn["interval_sec"]
            if not 18 <= end <= 22:
                problems.append(f"{wave['id']} 的刷怪窗口 {end:.1f} 秒不在 18 到 22 秒")
    if level["id"] == "ch1_04":
        leak = level["bosses"][0].get("leak", {})
        if leak.get("on_reach_guard") != "deduct_lives_and_return_to_rift":
            problems.append("冰之残影走到守护点后要扣命并回到裂缝")
        if leak.get("then") != "walk_the_same_route_again":
            problems.append("冰之残影扣命后要再走同一条路")
        source = leak.get("lives_source", "")
        if source != "data/balance/combat/stats.json#/bosses/boss_cirno/leak_damage":
            problems.append("冰之残影的扣命要指向 stats.json，不要把数字写进关卡")
        if any(character.isdigit() for character in json.dumps({key: leak[key] for key in leak if key != "lives_source"})):
            problems.append("冰之残影的漏怪说明里不要抄扣命数字")
    return problems


def roster_problems(level: dict, playable: dict[str, str], stats: dict | None) -> list[str]:
    problems: list[str] = []
    available = level["params"]["available_character_ids"]
    allowed_playable = {"yes", "pending_文案策划"}
    for character_id in available:
        if playable.get(character_id) not in allowed_playable:
            problems.append(f"可放置名单里有未定案或未知角色 {character_id}")
    for character_id in level["new_character_ids"]:
        if character_id not in available:
            problems.append(f"新角色 {character_id} 不在可放置名单里")
    if stats is not None:
        expected_spirit = pointer_value(stats, "data/balance/combat/stats.json#/economy/starting_spirit")
        if expected_spirit is not None and level["params"]["starting_spirit_power"] != expected_spirit:
            problems.append("开局灵力和 stats.json 的 economy.starting_spirit 不一致")
        expected_lives = pointer_value(stats, "data/balance/combat/stats.json#/guard/max_hp")
        if expected_lives is not None and level["params"]["lives"] != expected_lives:
            problems.append("生命和 stats.json 的 guard.max_hp 不一致")
    for enemy_id in level["new_enemy_ids"]:
        if not enemy_id.startswith(("enm_", "boss_")):
            problems.append(f"新敌人 id 不是战斗侧的命名：{enemy_id}")
    return problems


def teaching_problems(level: dict) -> list[str]:
    teaches = level.get("teaches")
    problems: list[str] = []
    if not isinstance(teaches, str) or not teaches.strip():
        problems.append("teaches 应该是一条主教学点")
        teaches = ""
    previews = level.get("previews", [])
    if not isinstance(previews, list) or any(not isinstance(item, str) for item in previews):
        problems.append("previews 应该是字符串数组")
    if level["id"] == "ch5_02":
        if level.get("display_name") != "迟来的岔路":
            problems.append("ch5_02 的名字暂用「迟来的岔路」")
        if level.get("display_name_status") != "pending_文案策划":
            problems.append("ch5_02 的名字要标成 pending_文案策划")
        if "会移动" in level.get("display_name", "") or "会移动" in teaches:
            problems.append("路线在战斗中不会移动，不要再叫会移动的路")
    if level["id"] == "prologue_03":
        if "三选一" not in teaches:
            problems.append("序章第 3 关的主教学点应该是第一次三选一")
        if "拐角" in teaches or "弯路" in teaches:
            problems.append("弯路和拐角是地图形状，不是序章第 3 关的教学点")
    if level["id"] == "ch1_01":
        if "快残影" not in teaches:
            problems.append("第一章第 1 关的主教学点应该是快残影")
        if "雾" in teaches:
            problems.append("浓雾是第一章的环境，不是第一章第 1 关的教学点")
    return problems


def scripted_event_problems(level: dict) -> list[str]:
    events = level.get("scripted_events", [])
    if level["id"] != "ch1_03":
        if events:
            return [f"{level['id']} 不该有剧情事件。MVP 里只有第一章第 3 关有隙间换位"]
        return []
    if len(events) != 1:
        return ["第一章第 3 关应该只有一段隙间换位"]
    event = events[0]
    problems: list[str] = []
    if event.get("id") != "evt_yukari_gap_demo" or event.get("once") is not True:
        problems.append("隙间换位的 id 应该是 evt_yukari_gap_demo，并且只演一次")
    if event.get("wave_id") != "w06":
        problems.append("隙间换位应该在第 6 波触发")
    trigger = event.get("trigger", "")
    if "左路" not in trigger or "硬残影" not in trigger:
        problems.append("隙间换位应该在第 6 波左路第一只硬残影出场时触发")
    effect = event.get("effect", "")
    if "送回" not in effect or "裂隙" not in effect:
        problems.append("隙间换位要把这只硬残影送回本路起点的裂隙")
    if event.get("deals_damage") is not False:
        problems.append("隙间换位不造成伤害")
    if event.get("threat_unchanged") is not True:
        problems.append("隙间换位不改变威胁点")
    if event.get("dialogue_status") != "pending_文案策划":
        problems.append("隙间换位的台词状态应该是 pending_文案策划")
    if "ch2_01" not in event.get("note", ""):
        problems.append("隙间换位要写明紫从 ch2_01 起才能放，这一下不是让玩家放置紫")
    return problems


def json_number_problems(value, path: str, allow_keys: set[str]) -> list[str]:
    problems: list[str] = []
    if isinstance(value, bool):
        return problems
    if isinstance(value, (int, float)):
        problems.append(f"{path} 不该自己带数字")
        return problems
    if isinstance(value, dict):
        for key, item in value.items():
            if key in allow_keys:
                continue
            problems.extend(json_number_problems(item, f"{path}.{key}", allow_keys))
    elif isinstance(value, list):
        for index, item in enumerate(value):
            problems.extend(json_number_problems(item, f"{path}[{index}]", allow_keys))
    return problems


def rating_problems(rating: dict, stats: dict | None) -> list[str]:
    problems: list[str] = []
    problems.extend(json_number_problems(rating, "rating", {"schema_version"}))
    if rating.get("stars_do_not_grant_power") is not True:
        problems.append("星级必须明确不提供强度")
    if "bands" in rating or "thresholds_lives_left" in rating or "max_lives" in rating:
        problems.append("rating.json 不要自己写星级区间或生命上限")
    stars = rating.get("stars_source", {})
    if stars.get("path") != "data/balance/combat/stats.json":
        problems.append("星级要指向 data/balance/combat/stats.json")
    if stars.get("field") != "stars.thresholds_lives_left":
        problems.append("星级字段应该是 stars.thresholds_lives_left")
    if stars.get("order") != ["3星", "2星", "1星"]:
        problems.append("星级顺序应该是 3 星、2 星、1 星")
    if "首通目标不参与星级" not in stars.get("note", ""):
        problems.append("要写明首通目标不参与星级")
    if "first_clear" in rating or "two_star_lives_ratio" in rating:
        problems.append("rating.json 不要再写 first_clear 或 two_star_lives_ratio")
    lives = rating.get("lives_source", {})
    if lives.get("path") != "data/balance/combat/stats.json" or lives.get("field") != "guard.max_hp":
        problems.append("满生命要指向 stats.json 的 guard.max_hp")
    source = rating.get("first_clear_source", {})
    if source.get("path") != "data/balance/level_difficulty.json":
        problems.append("首通目标要指向 PR #8 的难度表")
    if source.get("field") != "levels.<level_id>.target_lives_first_clear":
        problems.append("首通目标字段应该是 levels.<level_id>.target_lives_first_clear")
    if "不参与星级" not in source.get("note", ""):
        problems.append("首通目标说明要写明它不参与星级")
    replay = rating.get("replay", {})
    if replay.get("cleared_levels_anytime") is not True or replay.get("can_earn_missing_stars") is not True:
        problems.append("已通关的关要能重打，并且能补星")
    replay_note = replay.get("note", "")
    if "重打" not in replay_note or "level_difficulty.json" not in replay_note:
        problems.append("重打奖励要指向 PR #8 的难度表")
    if "大于零" not in rating.get("win", "") or "耗尽" not in rating.get("lose", ""):
        problems.append("胜负要写明：最后一波结束还有命即胜，生命耗尽即败")
    leak = rating.get("leak", {})
    if leak.get("stored_in_level_data") is not False:
        problems.append("漏怪扣命不应该写进关卡数据")
    leak_note = leak.get("note", "")
    if "权威" not in leak_note or "lives_on_leak" in leak_note or "stats.json" not in leak_note:
        problems.append("漏怪说明要指向 data/balance/combat/stats.json，不要在关卡里再抄一份")
    if stats is None:
        return problems
    thresholds = pointer_value(stats, "data/balance/combat/stats.json#/stars/thresholds_lives_left")
    if not isinstance(thresholds, list) or len(thresholds) != 3:
        print("警告：stats.json 里没有三档星级阈值，星级数字检查已跳过。", file=sys.stderr)
    elif pointer_value(stats, "data/balance/combat/stats.json#/guard/max_hp") is None:
        print("警告：stats.json 里没有 guard.max_hp，满生命检查已跳过。", file=sys.stderr)
    return problems


def index_problems(index: dict, levels: dict[str, dict]) -> list[str]:
    problems: list[str] = []
    entries = index.get("levels", [])
    if len(entries) != 24:
        problems.append(f"索引不是 24 关，而是 {len(entries)}")
    if index.get("unlock_rule") != "sequential_clear":
        problems.append("解锁规则不是顺序通关")
    if index.get("starting_character_ids") != STARTERS:
        problems.append("开局角色应该只有灵梦")
    decided = {item.get("id"): item for item in index.get("character_joins_decided", [])}
    cirno = decided.get("chr_cirno")
    if cirno is None or cirno.get("status") != "decided":
        problems.append("琪露诺的加入关要标成制作人已定")
    if cirno and (cirno.get("unlock_after_clearing") != "ch1_01" or cirno.get("first_placeable_level") != "ch1_02"):
        problems.append("琪露诺应该是通关 ch1_01 后加入，ch1_02 起可放置")
    proposals = index.get("character_join_proposals", [])
    if any(item.get("id") == "chr_cirno" for item in proposals):
        problems.append("琪露诺不再是待文案的提案")
    expected_proposals = {
        "chr_meiling": ("ch2_01", "ch2_02"),
        "chr_sakuya": ("ch2_04", "ch3_01"),
        "chr_keine": ("ch3_01", "ch3_02"),
        "chr_mokou": ("ch3_04", "ch4_01"),
        "chr_sanae": ("ch4_04", "ch5_01"),
    }
    by_proposal = {item.get("id"): item for item in proposals}
    for character_id, (unlock_after, first_level) in expected_proposals.items():
        item = by_proposal.get(character_id)
        if item is None or item.get("status") != "pending_文案策划":
            problems.append(f"{character_id} 的加入要标成 pending_文案策划")
        elif item.get("unlock_after_clearing") != unlock_after or item.get("first_placeable_level") != first_level:
            problems.append(f"{character_id} 的加入关不对")
    aya = by_proposal.get("chr_aya")
    if aya is None or aya.get("unlock_after_clearing") is not None or aya.get("first_placeable_level") is not None:
        problems.append("文还不可玩，不进解锁链")
    replay = index.get("replay", {})
    if replay.get("cleared_levels_anytime") is not True or replay.get("can_earn_missing_stars") is not True:
        problems.append("索引要写明已通关的关可以重打并补星")
    previous = None
    seen = []
    for entry in entries:
        level_id = entry.get("id")
        seen.append(level_id)
        if entry.get("unlock_after") != previous:
            problems.append(f"{level_id} 的 unlock_after 不是上一关")
        expected_file = f"{level_id}.json"
        if entry.get("file") != expected_file:
            problems.append(f"{level_id} 的文件名不对")
        if level_id not in levels:
            problems.append(f"索引指向了不存在的关卡 {level_id}")
        elif levels[level_id]["status"] != entry.get("status"):
            problems.append(f"{level_id} 的完成状态和索引不一致")
        previous = level_id
    if len(seen) != len(set(seen)):
        problems.append("索引里有重复关卡")
    chapters = {chapter["id"]: chapter.get("level_ids", []) for chapter in index.get("chapters", [])}
    if list(chapters) != CHAPTER_ORDER:
        problems.append("章节顺序不对")
    for chapter_id, expected_count in EXPECTED_COUNTS.items():
        ids = chapters.get(chapter_id, [])
        if len(ids) != expected_count:
            problems.append(f"{chapter_id} 应有 {expected_count} 关，实际 {len(ids)}")
    return problems


def schema_errors(validator: Draft202012Validator, level: dict) -> list[str]:
    errors = sorted(validator.iter_errors(level), key=lambda error: list(error.path))
    messages = []
    for error in errors:
        location = "/".join(str(part) for part in error.path) or "(根)"
        messages.append(f"schema {location}: {error.message}")
    return messages


def catalog_problems(catalog: dict, stats: dict | None = None) -> tuple[list[str], dict[str, dict]]:
    problems: list[str] = []
    note = catalog.get("_owner_note", "")
    if "权威" not in note or "stats.json" not in note:
        problems.append("图鉴要写明属性的权威来源是 stats.json，不是这份关卡文件")
    if "stat_conflict" in catalog:
        problems.append("图鉴不要再记快残影的生命和移速差异")
    source = catalog.get("stat_source", {})
    if source.get("path") != "data/balance/combat/stats.json":
        problems.append("图鉴的 stat_source 要指向 data/balance/combat/stats.json")
    if source.get("enemies_field") != "enemies" or source.get("bosses_field") != "bosses":
        problems.append("图鉴要指向 stats.json 的 enemies 和 bosses")
    blob = json.dumps(catalog, ensure_ascii=False)
    for phrase in ("生命 35", "每秒 2.0", "每秒 1.8", "普通残影", "飞屑", "boss_yukari", "boss_sakuya"):
        if phrase in blob:
            problems.append(f"图鉴里不该再出现：{phrase}")
    expected_names = {
        "enm_shade_basic": "小残影",
        "enm_shade_fast": "快残影",
        "enm_shade_armored": "硬残影",
        "enm_shade_flying": "飞行残影",
        "enm_shade_phantom": "遗忘之影",
        "enm_shade_heap": "堆积体",
        "enm_shade_rift": "结界之渣",
        "enm_shade_pouncer": "扑人残影",
        "boss_cirno": "冰之残影",
        "boss_ch2_sakuya_shade": "红魔的女仆残影",
        "boss_ch3_mokou_shade": "不死鸟的残影",
        "boss_ch4_sanae_shade": "风祝的残影",
        "boss_ch5_gatekeeper": "守门残影",
        "boss_wasure": "落野忘",
    }
    decided_names = {
        "enm_shade_basic",
        "enm_shade_fast",
        "enm_shade_armored",
        "enm_shade_flying",
        "boss_cirno",
    }
    by_id: dict[str, dict] = {}
    for entry in catalog.get("entries", []):
        enemy_id = entry["id"]
        if enemy_id in by_id:
            problems.append(f"敌人 id 重复：{enemy_id}")
        by_id[enemy_id] = entry
        if STAT_KEYS & set(entry) or "threat_points" in entry:
            problems.append(f"{enemy_id} 不应该再抄生命、移速、护甲或威胁点")
        bucket = "bosses" if enemy_id.startswith("boss_") else "enemies"
        expected_source = f"data/balance/combat/stats.json#/{bucket}/{enemy_id}/threat_points"
        if entry.get("threat_points_source") != expected_source:
            problems.append(f"{enemy_id} 的威胁点要指向 {expected_source}")
        elif stats is not None and pointer_value(stats, expected_source) is None:
            print(f"警告：{enemy_id} 在 stats.json 里还没有威胁点，跳过这项核对。", file=sys.stderr)
        expected_key = f"enemy.{enemy_id}.name"
        if entry.get("display_name_key") != expected_key:
            problems.append(f"{enemy_id} 的文本 key 应该是 {expected_key}")
        expected_status = "decided" if enemy_id in decided_names else "pending_文案策划"
        if entry.get("name_status") != expected_status:
            problems.append(f"{enemy_id} 的名字状态应该是 {expected_status}")
        problems.extend(json_number_problems(entry, enemy_id, set()))
    for enemy_id in KNOWN_ENEMIES:
        if enemy_id not in by_id:
            problems.append(f"缺少敌人 {enemy_id}")
    for enemy_id in ("enm_shade_phantom", "enm_shade_heap", "enm_shade_rift", "enm_shade_flying"):
        if enemy_id not in by_id:
            problems.append(f"缺少预留敌人 {enemy_id}")
    for enemy_id, display_name in expected_names.items():
        entry = by_id.get(enemy_id)
        if entry is None:
            problems.append(f"缺少 {enemy_id}")
        elif entry.get("display_name") != display_name:
            problems.append(f"{enemy_id} 的显示名应该是 {display_name}")
    for enemy_id, entry in by_id.items():
        if not enemy_id.startswith("boss_") or enemy_id == "boss_cirno":
            continue
        if entry.get("name_status") != "pending_文案策划":
            problems.append(f"{enemy_id} 的名字要标成 pending_文案策划")
    return problems, by_id


def roster_file_problems(roster: dict) -> list[str]:
    problems: list[str] = []
    if "不在本文件" not in roster.get("_owner_note", ""):
        problems.append("角色名单要写明属性不在这份文件里")
    decided = {
        "chr_reimu": ("yes", "prologue_01", None, "decided"),
        "chr_marisa": ("yes", "prologue_02", "prologue_01", "decided"),
        "chr_cirno": ("yes", "ch1_02", "ch1_01", "decided"),
        "chr_yukari": ("yes", "ch2_01", "ch1_04", "decided"),
    }
    proposed = {
        "chr_meiling": ("ch2_02", "ch2_01"),
        "chr_sakuya": ("ch3_01", "ch2_04"),
        "chr_keine": ("ch3_02", "ch3_01"),
        "chr_mokou": ("ch4_01", "ch3_04"),
        "chr_sanae": ("ch5_01", "ch4_04"),
    }
    seen = set()
    for character in roster.get("characters", []):
        character_id = character.get("id")
        seen.add(character_id)
        if "spirit_power_cost" in character or "hp" in character:
            problems.append(f"{character_id} 不应该再写消耗或生命")
        if character_id in decided:
            playable, joins_at, unlocked_by, join_status = decided[character_id]
            if character.get("playable") != playable or character.get("joins_at_level") != joins_at:
                problems.append(f"{character_id} 的可玩状态或加入关不对")
            if character.get("unlocked_by_clearing") != unlocked_by:
                problems.append(f"{character_id} 的解锁关不对")
            if character.get("join_status") != join_status:
                problems.append(f"{character_id} 的加入状态应该是 {join_status}")
        elif character_id in proposed:
            joins_at, unlocked_by = proposed[character_id]
            if character.get("playable") != "pending_文案策划" or character.get("join_status") != "pending_文案策划":
                problems.append(f"{character_id} 是提案，要标成 pending_文案策划")
            if character.get("joins_at_level") != joins_at or character.get("unlocked_by_clearing") != unlocked_by:
                problems.append(f"{character_id} 的加入关不对")
        elif character.get("playable") != "pending_producer" or character.get("joins_at_level") is not None:
            problems.append(f"{character_id} 还不可玩，不应该写进解锁链")
    for character_id in (*decided, *proposed):
        if character_id not in seen:
            problems.append(f"角色名单缺少 {character_id}")
    return problems


def unlock_chain_problems(order: list[dict]) -> list[str]:
    problems: list[str] = []
    unlocked = list(STARTERS)
    previous: set[str] = set()
    for level in order:
        available = level["params"]["available_character_ids"]
        if available != unlocked:
            problems.append(f"{level['id']} 的可放置名单应该是 {unlocked}")
        expected_new = [character_id for character_id in available if character_id not in previous]
        if level["new_character_ids"] != expected_new:
            problems.append(f"{level['id']} 的新角色应该是 {expected_new}")
        for character_id in level["unlock_character_ids"]:
            if character_id in unlocked:
                problems.append(f"{level['id']} 重复解锁 {character_id}")
            unlocked.append(character_id)
        previous = set(available)
    return problems


def route_plan_problems(level: dict) -> list[str]:
    if level["route_type"] == "moving":
        return [f"{level['id']} 的路线不能在战斗中移动"]
    if level["status"] != "complete":
        return []
    expected = {
        "prologue_01": (1, 1, "straight"),
        "prologue_02": (1, 1, "curve"),
        "prologue_03": (1, 1, "curve"),
        "ch1_01": (1, 1, "curve"),
        "ch1_02": (2, 2, "double_entrance"),
        "ch1_03": (1, 2, "fork_merge"),
        "ch1_04": (1, 1, "curve"),
    }
    entrances = len(level["map"]["entrances"])
    paths = len(level["map"]["paths"])
    got = (entrances, paths, level["route_type"])
    if got != expected[level["id"]]:
        return [f"{level['id']} 的入口、路线数量或类型应该是 {expected[level['id']]}，实际 {got}"]
    return []


def boss_identity_problems(level: dict) -> list[str]:
    expected = {
        "ch2_04": "boss_ch2_sakuya_shade",
        "ch3_04": "boss_ch3_mokou_shade",
        "ch4_04": "boss_ch4_sanae_shade",
        "ch5_04": "boss_ch5_gatekeeper",
        "final_01": "boss_wasure",
    }
    boss_id = expected.get(level["id"])
    if boss_id is None:
        return []
    if boss_id not in level.get("new_enemy_ids", []):
        return [f"{level['id']} 的新敌人应该包含 {boss_id}"]
    return []


def stub_wave_problems(level: dict) -> list[str]:
    return wave_count_span_problems(level, level["wave_count"])


def stale_reference_problems() -> list[str]:
    """旧的首通字段名不能再出现在关卡数据和说明里。"""
    needle = "expected_first_clear_" + "lives"
    problems: list[str] = []
    paths = [ROOT / "CHANGELOG.md"]
    for folder in (LEVEL_DIR, ROOT / "docs"):
        paths.extend(path for path in folder.rglob("*") if path.is_file())
    for path in paths:
        if path.suffix not in {".md", ".json", ".gd"}:
            continue
        if path.name == "level_difficulty.json":
            continue
        text = path.read_text(encoding="utf-8")
        if needle in text:
            problems.append(f"{path.relative_to(ROOT)} 还在引用旧的首通字段")
    return problems


def main() -> int:
    schema = load_json(SCHEMA_PATH)
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)
    index = load_json(LEVEL_DIR / "index.json")
    difficulty = load_difficulty(BALANCE_PATH)
    stats = load_stats(STATS_PATH)
    catalog = load_json(LEVEL_DIR / "enemy_catalog.json")
    roster = load_json(LEVEL_DIR / "character_roster.json")
    rating = load_json(LEVEL_DIR / "rating.json")
    roster_errors = roster_file_problems(roster)
    if roster_errors:
        print("角色名单:", file=sys.stderr)
        for problem in roster_errors:
            print(f"  - {problem}", file=sys.stderr)
        return 1
    catalog_errors, catalog_ids = catalog_problems(catalog, stats)
    if catalog_errors:
        print("敌人图鉴:", file=sys.stderr)
        for problem in catalog_errors:
            print(f"  - {problem}", file=sys.stderr)
        return 1
    threats = threat_table(stats)
    playable = {character["id"]: character["playable"] for character in roster["characters"]}
    levels = {}
    failed = False
    for entry in index["levels"]:
        path = LEVEL_DIR / entry["file"]
        if not path.is_file():
            print(f"缺少文件 {path}", file=sys.stderr)
            failed = True
            continue
        level = load_json(path)
        levels[level["id"]] = level
        problems = schema_errors(validator, level)
        if level["status"] == "complete":
            problems.extend(geometry_problems(level))
            problems.extend(boss_problems(level))
            problems.extend(timing_problems(level))
            problems.extend(composition_problems(level, threats or {}))
            problems.extend(scripted_event_problems(level))
            if difficulty is not None and threats is not None:
                row = difficulty.get("levels", {}).get(level["id"])
                if not isinstance(row, dict):
                    problems.append("难度表里没有这一关")
                else:
                    problems.extend(threat_problems(level, threats, row, set(catalog_ids)))
            elif difficulty is not None:
                print(f"警告：{level['id']} 有难度表但没有属性表，威胁核对已跳过。", file=sys.stderr)
        else:
            problems.extend(stub_wave_problems(level))
        problems.extend(teaching_problems(level))
        problems.extend(roster_problems(level, playable, stats))
        problems.extend(boss_identity_problems(level))
        problems.extend(route_plan_problems(level))
        if level["placeholders"].get("_placeholder") is not True:
            problems.append("缺少占位标记")
        if problems:
            failed = True
            print(f"{level['id']}:", file=sys.stderr)
            for problem in problems:
                print(f"  - {problem}", file=sys.stderr)
        else:
            print(f"{level['id']}: 通过")
    ordered = [levels[entry["id"]] for entry in index["levels"] if entry["id"] in levels]
    problems = index_problems(index, levels)
    problems.extend(unlock_chain_problems(ordered))
    problems.extend(rating_problems(rating, stats))
    problems.extend(stale_reference_problems())
    if problems:
        failed = True
        print("索引 / 星级:", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
    else:
        print("索引、星级: 通过")
    if failed:
        return 1
    print("全部通过")
    return 0


if __name__ == "__main__":
    try:
        sys.exit(main())
    except ValidationError as error:
        print(error.message, file=sys.stderr)
        sys.exit(1)
