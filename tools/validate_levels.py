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
SCHEMA_PATH = LEVEL_DIR / "level.schema.json"
CONFIRMED_ENEMIES = {
    "shade_small": {"hp": 60, "move_speed": 1.0, "armor": 0, "spirit_on_kill": 5, "lives_on_leak": 1, "threat": 1},
    "shade_fast": {"hp": 35, "move_speed": 2.0, "armor": 0, "spirit_on_kill": 5, "lives_on_leak": 1, "threat": 1},
    "shade_hard": {"hp": 200, "move_speed": 0.6, "armor": 10, "spirit_on_kill": 15, "lives_on_leak": 2, "threat": 4},
    "boss_ch1": {"hp": 3000, "move_speed": 0.4, "armor": 5, "spirit_on_kill": 100, "lives_on_leak": 10, "threat": None},
}
KNOWN_TOTALS = {8: 224, 9: 270, 10: 320, 11: 374, 12: 432, 15: 630}

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


def wave_threat(wave: dict, threats: dict[str, int]) -> tuple[int, list[str]]:
    total = 0
    problems: list[str] = []
    for spawn in wave["groups"]:
        enemy_id = spawn["enemy_id"]
        if enemy_id not in threats:
            problems.append(f"波次使用了图鉴里没有的敌人 {enemy_id}")
            continue
        total += spawn["count"] * threats[enemy_id]
    return total, problems


def threat_problems(level: dict, threats: dict[str, int], budgets: list[int], catalog_ids: set[str]) -> list[str]:
    problems: list[str] = []
    if len(level["waves"]) != len(budgets):
        problems.append(f"波次数 {len(level['waves'])} 和难度表的 {len(budgets)} 不一致")
        return problems
    for wave, budget in zip(level["waves"], budgets):
        total, missing = wave_threat(wave, threats)
        problems.extend(missing)
        if total != budget:
            problems.append(f"{wave['id']} 的威胁 {total} 不是难度表里的 {budget}")
        for spawn in wave["groups"]:
            if spawn["enemy_id"] not in threats:
                problems.append(f"{wave['id']} 使用了没有威胁点的敌人 {spawn['enemy_id']}")
    for boss in level["bosses"]:
        if boss["id"] not in catalog_ids:
            problems.append(f"图鉴里没有首领 {boss['id']}")
        elif boss["id"] in threats:
            problems.append(f"{boss['id']} 不该占用波次预算")
    return problems


def composition_problems(level: dict, threats: dict[str, int], row: dict) -> list[str]:
    problems: list[str] = []
    level_id = level["id"]
    offers = set(row["buff_after_waves"])
    swift_threat = 0
    total_threat = 0
    for index, wave in enumerate(level["waves"], start=1):
        note = wave.get("note", "")
        if (index in offers) != ("三选一" in note):
            problems.append(f"{wave['id']} 的备注没有和三选一时机对上")
        for spawn in wave["groups"]:
            enemy_id = spawn["enemy_id"]
            if enemy_id not in threats:
                continue
            threat = spawn["count"] * threats[enemy_id]
            total_threat += threat
            if enemy_id == "shade_fast":
                swift_threat += threat
            if enemy_id == "shade_hard" and level_id != "ch1_03":
                problems.append(f"{level_id} 不该出现硬残影")
    if level_id == "ch1_01":
        for index, wave in enumerate(level["waves"], start=1):
            has_fast = any(spawn["enemy_id"] == "shade_fast" for spawn in wave["groups"])
            if index < 6 and has_fast:
                problems.append("教学关的快残影出现在前半")
            if index >= 6 and not has_fast:
                problems.append(f"{wave['id']} 后半应该有快残影")
        if total_threat and not 0.18 <= swift_threat / total_threat <= 0.22:
            problems.append(f"教学关快残影威胁占比 {swift_threat / total_threat:.3f} 不在两成附近")
    if level_id == "ch1_02":
        for wave in level["waves"]:
            kinds = {spawn["enemy_id"] for spawn in wave["groups"]}
            if kinds != {"shade_small", "shade_fast"}:
                problems.append(f"{wave['id']} 没有把小残影和快残影混在同一波")
        if total_threat and not 0.45 <= swift_threat / total_threat <= 0.55:
            problems.append(f"练习关快残影占比 {swift_threat / total_threat:.3f} 不在一半附近")
    if level_id == "ch1_03":
        hard_count = 0
        for index, wave in enumerate(level["waves"], start=1):
            delays = [spawn["delay_sec"] for spawn in wave["groups"]]
            paths = {spawn["path_id"] for spawn in wave["groups"]}
            if len(wave["groups"]) < 2 or any(delay != 0 for delay in delays) or len(paths) < 2:
                problems.append(f"{wave['id']} 没有左右同时出场")
            hard_here = sum(spawn["count"] for spawn in wave["groups"] if spawn["enemy_id"] == "shade_hard")
            hard_count += hard_here
            if index >= 10 and hard_here != 1:
                problems.append(f"{wave['id']} 应该正好有 1 只硬残影")
            if index < 10 and hard_here:
                problems.append(f"{wave['id']} 硬残影不该出现在第 10 波之前")
        if hard_count != 3:
            problems.append(f"第一章试炼的硬残影应该是 3 只，实际 {hard_count}")
    if level_id == "prologue_03":
        for index, wave in enumerate(level["waves"], start=1):
            if index < 6:
                continue
            paths = {spawn["path_id"] for spawn in wave["groups"]}
            delays = [spawn["delay_sec"] for spawn in wave["groups"]]
            if len(wave["groups"]) < 2 or paths != {"path.main"} or any(delay != 0 for delay in delays):
                problems.append(f"{wave['id']} 后半应该两组同时走同一条路")
    if level_id == "ch1_04":
        boss = level["bosses"][0]
        if boss["enters_at_wave_id"] != "w05":
            problems.append("琪露诺应该在第 5 波入场")
        if boss["prelude_wave_ids"] != ["w01", "w02", "w03", "w04"]:
            problems.append("琪露诺的前奏应该是前 4 波")
        for index, wave in enumerate(level["waves"], start=1):
            expected = "minion" if index <= 4 or index % 2 == 0 else "boss_phase"
            if wave.get("pressure") != expected:
                problems.append(f"{wave['id']} 的压力应该是 {expected}")
        spell_ids = [phase["spell_card_id"] for phase in boss["phases"]]
        if len(spell_ids) != len(set(spell_ids)):
            problems.append("一个阶段一张符卡，不能重复")
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
    if level["params"]["starting_spirit_power"] != 150:
        problems.append("开局灵力已确认是 150")
    if known_costs and level["params"]["starting_spirit_power"] < min(known_costs):
        problems.append("起始灵力不够放置最便宜的角色")
    for enemy_id in level["new_enemy_ids"]:
        if not enemy_id.startswith(("remnant.", "boss.", "shade_", "boss_")):
            problems.append(f"新敌人 id 不像已有格式：{enemy_id}")
    return problems


def role_for(level: dict) -> str:
    if level["kind"] in ("boss", "final_boss"):
        return "boss"
    if level["index_in_chapter"] == 1:
        return "teaching"
    if level["index_in_chapter"] == 2:
        return "practice"
    return "test"


def base_budget(wave_index: int) -> int:
    return 10 + 4 * wave_index


def difficulty_problems(order: list[dict], difficulty: dict) -> list[str]:
    problems: list[str] = []
    if difficulty.get("_owner") != "数值策划":
        problems.append("难度表必须标明归数值策划")
    confirmed = difficulty.get("confirmed", {})
    if confirmed.get("starting_spirit_power") != 150 or confirmed.get("spirit_per_wave_survived") != 20:
        problems.append("开局灵力应该是 150，每活过一波加 20")
    if confirmed.get("lives") != 20 or confirmed.get("buff_every_waves") != 5 or confirmed.get("buff_pick_count") != 3:
        problems.append("生命、三选一间隔或张数和已确认的规则不一致")
    if confirmed.get("boss_does_not_consume_wave_budget") is not True:
        problems.append("首领必须单独出场，不占那一波的预算")
    known = confirmed.get("known_totals", {})
    for wave_count, total in KNOWN_TOTALS.items():
        if int(known.get(str(wave_count), -1)) != total:
            problems.append(f"{wave_count} 波的合计应该是 {total}")
        expected = sum(base_budget(index) for index in range(1, wave_count + 1))
        if expected != total:
            problems.append(f"{wave_count} 波的公式合计不是 {total}")
    rows = difficulty.get("levels")
    if not isinstance(rows, dict):
        return problems + ["难度表缺少 levels"]
    open_ids = [item.get("id") for item in difficulty.get("alignment_open", [])]
    if "threat_budget_coef_pending" not in open_ids or "half_lives_sits_on_star_boundary" not in open_ids:
        problems.append("难度表要记下：系数仍是提议，以及一半生命踩在星级交界上")
    if list(rows) != [level["id"] for level in order]:
        problems.append("难度表的关卡顺序和索引不一致")
        return problems
    previous_hp = 0
    for number, level in enumerate(order, start=1):
        row = rows[level["id"]]
        if level.get("difficulty_id") != level["id"]:
            problems.append(f"{level['id']} 的 difficulty_id 没有指向自己")
        if row.get("level_number") != number:
            problems.append(f"{level['id']} 的关卡序号不是 {number}")
        role = role_for(level)
        if row.get("role") != role:
            problems.append(f"{level['id']} 的难度角色应该是 {role}")
        if row.get("threat_budget_coef") != 1 or row.get("threat_budget_coef_status") != "proposal":
            problems.append(f"{level['id']} 的威胁系数应该是提议中的 1.0")
        expected_hp = 100 + 15 * (number - 1)
        got_hp = int(round(float(row["hp_multiplier"]) * 100))
        if got_hp != expected_hp:
            problems.append(f"{level['id']} 的生命倍率不是 {expected_hp / 100}")
        if got_hp <= previous_hp:
            problems.append(f"{level['id']} 的生命倍率没有比上一关更高")
        previous_hp = got_hp
        wave_count = len(level["waves"]) if level["status"] == "complete" else level["wave_count"]
        if row.get("wave_count") != wave_count:
            problems.append(f"{level['id']} 的波数和难度表不一致")
        expected_offers = [wave for wave in (5, 10, 15) if wave <= wave_count]
        if row.get("buff_after_waves") != expected_offers or row.get("buff_pick_count") != 3:
            problems.append(f"{level['id']} 的三选一不是每 5 波一次、三张里选一张")
        expected_budgets = [base_budget(index) for index in range(1, wave_count + 1)]
        if row.get("wave_threat_budgets") != expected_budgets:
            problems.append(f"{level['id']} 的分波预算不是 10 + 4 × 波次")
        if row.get("threat_budget_total") != sum(expected_budgets):
            problems.append(f"{level['id']} 的威胁合计不是各波之和")
    return problems


def curve_problems(levels: list[dict], rows: dict) -> list[str]:
    problems: list[str] = []
    by_chapter: dict[str, list[dict]] = {chapter_id: [] for chapter_id in CHAPTER_ORDER}
    for level in levels:
        by_chapter[level["chapter_id"]].append(level)
    previous_peak = None
    previous_hp = None
    previous_id = None
    for chapter_id in CHAPTER_ORDER:
        chapter_levels = by_chapter[chapter_id]
        budgets = [rows[level["id"]]["threat_budget_total"] for level in chapter_levels]
        for earlier, later in zip(budgets, budgets[1:]):
            if later <= earlier:
                problems.append(f"{chapter_id} 的威胁合计没有逐关上升：{budgets}")
                break
        if previous_peak is not None and chapter_id != "final":
            # 序章没有首领。第一章第 1 关和序章第 3 关都是 10 波，合计可以相同。
            # 有首领的章，下一章第 1 关必须更低，因为波数从 15 掉下来。
            previous_is_boss = previous_id is not None and previous_id.endswith("_04")
            too_high = budgets[0] > previous_peak or (previous_is_boss and budgets[0] >= previous_peak)
            if too_high:
                problems.append(
                    f"{chapter_levels[0]['id']} 的合计 {budgets[0]} 相对上一章最后一关 {previous_id} 的 {previous_peak} 没有松下来"
                )
        if chapter_id == "final" and previous_peak is not None:
            final_hp = rows[chapter_levels[0]["id"]]["hp_multiplier"]
            if budgets[0] < previous_peak or final_hp <= previous_hp:
                problems.append("终章的威胁合计或生命倍率没有站在第五章首领之上")
        previous_peak = budgets[-1]
        previous_hp = rows[chapter_levels[-1]["id"]]["hp_multiplier"]
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
    leak = rating.get("leak", {})
    if leak.get("_placeholder") is not False:
        problems.append("已确认敌人的漏怪扣命不再是占位")
    if "lives_on_leak" not in leak.get("note", ""):
        problems.append("漏怪扣命要指向敌人图鉴里的 lives_on_leak")
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


def catalog_problems(catalog: dict) -> tuple[list[str], dict[str, dict]]:
    problems: list[str] = []
    if catalog.get("_placeholder") is not False:
        problems.append("图鉴里已有确认条目，不要再把整份标成占位")
    by_id: dict[str, dict] = {}
    for entry in catalog.get("entries", []):
        enemy_id = entry["id"]
        if enemy_id in by_id:
            problems.append(f"敌人 id 重复：{enemy_id}")
        by_id[enemy_id] = entry
        expected = CONFIRMED_ENEMIES.get(enemy_id)
        stats = entry.get("stats", {})
        if expected is not None:
            if entry.get("confirmed") is not True:
                problems.append(f"{enemy_id} 应该标成已确认")
            for key, value in expected.items():
                if key == "threat":
                    if entry.get("threat") != value:
                        problems.append(f"{enemy_id} 的威胁点不是 {value}")
                    continue
                if stats.get(key) != value:
                    problems.append(f"{enemy_id} 的 {key} 不是已确认的 {value}")
        else:
            if entry.get("confirmed") is True:
                problems.append(f"{enemy_id} 还没被制作人确认")
            threat = entry.get("threat")
            if not isinstance(threat, int) or threat <= 0:
                problems.append(f"{enemy_id} 的占位威胁不是正数")
    for enemy_id in CONFIRMED_ENEMIES:
        if enemy_id not in by_id:
            problems.append(f"缺少已确认敌人 {enemy_id}")
    return problems, by_id


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
    difficulty = load_json(BALANCE_PATH)
    catalog = load_json(LEVEL_DIR / "enemy_catalog.json")
    roster = load_json(LEVEL_DIR / "character_roster.json")
    rating = load_json(LEVEL_DIR / "rating.json")
    if not roster.get("_placeholder"):
        print("角色放置消耗还没确认，名单必须标成占位", file=sys.stderr)
        return 1
    catalog_errors, catalog_ids = catalog_problems(catalog)
    if catalog_errors:
        print("敌人图鉴:", file=sys.stderr)
        for problem in catalog_errors:
            print(f"  - {problem}", file=sys.stderr)
        return 1
    threats = {
        enemy_id: entry["threat"]
        for enemy_id, entry in catalog_ids.items()
        if entry.get("threat") is not None
    }
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
            row = difficulty.get("levels", {}).get(level["id"], {})
            budgets = row.get("wave_threat_budgets", [])
            problems.extend(threat_problems(level, threats, budgets, set(catalog_ids)))
            if row:
                problems.extend(composition_problems(level, threats, row))
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
    ordered = [levels[entry["id"]] for entry in index["levels"] if entry["id"] in levels]
    problems = index_problems(index, levels)
    problems.extend(difficulty_problems(ordered, difficulty))
    if isinstance(difficulty.get("levels"), dict):
        problems.extend(curve_problems(ordered, difficulty["levels"]))
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
