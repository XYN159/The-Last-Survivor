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
SCHEMA_PATH = LEVEL_DIR / "level.schema.json"

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


def load_json(path: Path):
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as error:
        raise SystemExit(f"{path}: 不是合法 JSON：{error}") from error


def cell_char(grid: list[str], col: int, row: int) -> str | None:
    if row < 0 or row >= len(grid) or col < 0 or col >= len(grid[row]):
        return None
    return grid[row][col]


def geometry_problems(level: dict) -> list[str]:
    problems: list[str] = []
    level_map = level["map"]
    grid = level_map["grid"]
    if len(grid) != 12 or any(len(row) != 7 for row in grid):
        problems.append("地图不是 7 列 × 12 行")
        return problems
    entrances = {item["id"]: (item["col"], item["row"]) for item in level_map["entrances"]}
    guard = (level_map["guard_cell"]["col"], level_map["guard_cell"]["row"])
    if cell_char(grid, guard[0], guard[1]) != "P":
        problems.append("守护点不在路线格上")
    covered: set[tuple[int, int]] = set()
    path_ids = set()
    for path in level_map["paths"]:
        path_ids.add(path["id"])
        if path["entrance_id"] not in entrances:
            problems.append(f"{path['id']} 的入口不存在")
        cells = [(item["col"], item["row"]) for item in path["cells"]]
        if not cells:
            problems.append(f"{path['id']} 是空的")
            continue
        if path["entrance_id"] in entrances and cells[0] != entrances[path["entrance_id"]]:
            problems.append(f"{path['id']} 没有从入口出发")
        if cells[-1] != guard:
            problems.append(f"{path['id']} 没有走到守护点")
        previous = None
        for col, row in cells:
            char = cell_char(grid, col, row)
            if char != "P":
                problems.append(f"{path['id']} 经过了非路线格 ({col},{row})")
            if previous is not None:
                delta = abs(col - previous[0]) + abs(row - previous[1])
                if delta != 1:
                    problems.append(f"{path['id']} 在 ({previous[0]},{previous[1]}) 到 ({col},{row}) 不连续")
            previous = (col, row)
            covered.add((col, row))
    for row, line in enumerate(grid):
        for col, char in enumerate(line):
            if char == "P" and (col, row) not in covered:
                problems.append(f"路线格 ({col},{row}) 没有任何一条路径走过")
    for spot in level_map["good_spots"]:
        col, row = spot["col"], spot["row"]
        if cell_char(grid, col, row) != ".":
            problems.append(f"好位置 {spot['id']} 不是空地")
            continue
        adjacent = False
        for offset_col, offset_row in ORTHOGONAL:
            if cell_char(grid, col + offset_col, row + offset_row) == "P":
                adjacent = True
        if not adjacent:
            problems.append(f"好位置 {spot['id']} 没有贴着路线")
    wave_ids = []
    for wave in level["waves"]:
        wave_ids.append(wave["id"])
        for spawn in wave["groups"]:
            if spawn["entrance_id"] not in entrances:
                problems.append(f"{wave['id']} 使用了不存在的入口")
            if spawn["path_id"] not in path_ids:
                problems.append(f"{wave['id']} 使用了不存在的路径")
    if len(wave_ids) != len(set(wave_ids)):
        problems.append("波次 id 重复")
    return problems


def boss_problems(level: dict) -> list[str]:
    problems: list[str] = []
    wave_ids = [wave["id"] for wave in level["waves"]]
    wave_set = set(wave_ids)
    claimed: list[str] = []
    for boss in level["bosses"]:
        if boss["blocks_character_id"] in level["params"]["available_character_ids"]:
            problems.append(f"{boss['id']} 决斗时仍然可以放置")
        if boss["enters_at_wave_id"] not in wave_set:
            problems.append(f"{boss['id']} 的入场波次不存在")
        claimed.extend(boss["prelude_wave_ids"])
        for phase in boss["phases"]:
            claimed.extend(phase["wave_ids"])
            for change in phase["map_changes"]:
                for cell in change["cells"]:
                    char = cell_char(level["map"]["grid"], cell["col"], cell["row"])
                    if char != "P":
                        problems.append(f"{change['id']} 改到了非路线格 ({cell['col']},{cell['row']})")
    if level["bosses"]:
        if len(claimed) != len(set(claimed)):
            problems.append("首领阶段的波次有重叠")
        if set(claimed) != wave_set:
            problems.append("前奏和符卡阶段没有刚好盖住全部波次")
    kind = level["kind"]
    count = len(wave_ids)
    if kind in ("boss", "final_boss") and not 14 <= count <= 16:
        problems.append(f"首领关波次数 {count} 不在 14 到 16")
    if kind in ("tutorial", "normal") and not 8 <= count <= 12:
        problems.append(f"普通关波次数 {count} 不在 8 到 12")
    return problems


def threat_problems(level: dict, threats: dict[str, int]) -> list[str]:
    total = 0
    problems: list[str] = []
    for wave in level["waves"]:
        for spawn in wave["groups"]:
            enemy_id = spawn["enemy_id"]
            if enemy_id not in threats:
                problems.append(f"波次使用了图鉴里没有的敌人 {enemy_id}")
                continue
            total += spawn["count"] * threats[enemy_id]
    for boss in level["bosses"]:
        if boss["id"] not in threats:
            problems.append(f"图鉴里没有首领 {boss['id']}")
            continue
        total += threats[boss["id"]]
    budget = level["placeholders"]["threat_budget"]
    if total != budget:
        problems.append(f"波次威胁 {total} 和占位预算 {budget} 不一致")
    return problems


def roster_problems(level: dict, playable: dict[str, str], costs: dict[str, int]) -> list[str]:
    problems: list[str] = []
    available = level["params"]["available_character_ids"]
    for character_id in available:
        if playable.get(character_id) != "yes":
            problems.append(f"可放置名单里有未定案或未知角色 {character_id}")
    for character_id in level["new_character_ids"]:
        if character_id not in available:
            problems.append(f"新角色 {character_id} 不在可放置名单里")
    known_costs = [costs[character_id] for character_id in available if character_id in costs]
    if known_costs and level["params"]["starting_spirit_power"] < min(known_costs):
        problems.append("起始灵力不够放置最便宜的角色")
    for enemy_id in level["new_enemy_ids"]:
        if not enemy_id.startswith("remnant.") and not enemy_id.startswith("boss."):
            problems.append(f"新敌人 id 不像提案格式：{enemy_id}")
    return problems


def curve_problems(levels: list[dict]) -> list[str]:
    problems: list[str] = []
    by_chapter: dict[str, list[dict]] = {chapter_id: [] for chapter_id in CHAPTER_ORDER}
    for level in levels:
        by_chapter[level["chapter_id"]].append(level)
    previous_peak = None
    previous_id = None
    for chapter_id in CHAPTER_ORDER:
        chapter_levels = by_chapter[chapter_id]
        budgets = [level["placeholders"]["threat_budget"] for level in chapter_levels]
        for earlier, later in zip(budgets, budgets[1:]):
            if later <= earlier:
                problems.append(f"{chapter_id} 的威胁预算没有逐关上升：{budgets}")
                break
        if previous_peak is not None and chapter_id != "final":
            if budgets[0] >= previous_peak:
                problems.append(
                    f"{chapter_levels[0]['id']} 的预算 {budgets[0]} 不低于上一章最后一关 {previous_id} 的 {previous_peak}"
                )
        if chapter_id == "final" and previous_peak is not None and budgets[0] <= previous_peak:
            problems.append("终章预算没有高于第五章首领")
        previous_peak = budgets[-1]
        previous_id = chapter_levels[-1]["id"]
    return problems


def rating_problems(rating: dict) -> list[str]:
    problems: list[str] = []
    if rating.get("max_lives") != 20 or rating.get("defeat_lives") != 0:
        problems.append("星级规则的生命上限不是 20，或失败线不是 0")
    if rating.get("stars_do_not_grant_power") is not True:
        problems.append("星级必须明确不提供强度")
    expected = [(1, 1, 9), (2, 10, 17), (3, 18, 20)]
    got = [
        (band.get("stars"), band.get("lives_min"), band.get("lives_max"))
        for band in rating.get("bands", [])
    ]
    if got != expected:
        problems.append(f"星级区间不对：{got}")
    if not rating.get("leak", {}).get("_placeholder"):
        problems.append("漏怪扣命还没和数值策划对齐，必须标成占位")
    return problems


def index_problems(index: dict, levels: dict[str, dict]) -> list[str]:
    problems: list[str] = []
    entries = index.get("levels", [])
    if len(entries) != 24:
        problems.append(f"索引不是 24 关，而是 {len(entries)}")
    if index.get("unlock_rule") != "sequential_clear":
        problems.append("解锁规则不是顺序通关")
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


def stub_wave_problems(level: dict) -> list[str]:
    count = level["wave_count"]
    kind = level["kind"]
    if kind in ("boss", "final_boss") and not 14 <= count <= 16:
        return [f"草案首领波次数 {count} 不在 14 到 16"]
    if kind in ("tutorial", "normal") and not 8 <= count <= 12:
        return [f"草案普通波次数 {count} 不在 8 到 12"]
    return []


def main() -> int:
    schema = load_json(SCHEMA_PATH)
    Draft202012Validator.check_schema(schema)
    validator = Draft202012Validator(schema)
    index = load_json(LEVEL_DIR / "index.json")
    catalog = load_json(LEVEL_DIR / "enemy_catalog.json")
    roster = load_json(LEVEL_DIR / "character_roster.json")
    rating = load_json(LEVEL_DIR / "rating.json")
    if not catalog.get("_placeholder") or not roster.get("_placeholder"):
        print("敌人图鉴和角色名单必须标成占位", file=sys.stderr)
        return 1
    threats = {}
    for entry in catalog["entries"]:
        if entry["id"] in threats:
            print(f"敌人 id 重复：{entry['id']}", file=sys.stderr)
            return 1
        if entry["threat"] <= 0:
            print(f"{entry['id']} 的威胁不是正数", file=sys.stderr)
            return 1
        threats[entry["id"]] = entry["threat"]
    playable = {}
    costs = {}
    for character in roster["characters"]:
        playable[character["id"]] = character["playable"]
        costs[character["id"]] = character["spirit_power_cost"]
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
            problems.extend(threat_problems(level, threats))
        else:
            problems.extend(stub_wave_problems(level))
        problems.extend(roster_problems(level, playable, costs))
        if level["placeholders"].get("_placeholder") is not True:
            problems.append("缺少占位标记")
        if problems:
            failed = True
            print(f"{level['id']}:", file=sys.stderr)
            for problem in problems:
                print(f"  - {problem}", file=sys.stderr)
        else:
            print(f"{level['id']}: 通过")
    problems = index_problems(index, levels)
    problems.extend(curve_problems([levels[entry["id"]] for entry in index["levels"] if entry["id"] in levels]))
    problems.extend(rating_problems(rating))
    if problems:
        failed = True
        print("索引 / 曲线 / 星级:", file=sys.stderr)
        for problem in problems:
            print(f"  - {problem}", file=sys.stderr)
    else:
        print("索引、难度曲线、星级: 通过")
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
