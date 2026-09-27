# 数值脚本（tools/numeric）

给数值策划用的计算和模拟脚本。**不是游戏代码**，游戏运行时不会用到它们。只用 Python 3.10+ 标准库，不用装任何包。

## 一键重跑

在仓库根目录执行：

```bash
python tools/numeric/run_all.py              # 用表里现有的系数模拟 24 关、出报告、重新生成 stats.json 和 level_difficulty.json（8 核约 2 分钟）
python tools/numeric/run_all.py --quick      # 只跑 1 个随机种子、不做敏感性分析（约 40 秒）
python tools/numeric/run_all.py --calibrate  # 先按「首通目标剩余生命」重新校准每关的系数和每点伤害充能，再出报告（8 核约 5 分钟）
python tools/numeric/gen_stats_json.py       # 只从 CSV 重新生成 data/balance/combat/stats.json（1 秒）
python tools/numeric/gen_level_json.py       # 只从 CSV 重新生成 data/balance/level_difficulty.json（1 秒）
python tools/numeric/mvp_sweep.py            # MVP 7 关的「系数 → 剩余生命」扫描表（约 1 分钟）
```

Windows 上把 `python` 换成 `py` 也可以。

跑完会更新：

| 文件 | 内容 |
| --- | --- |
| `data/balance/level_difficulty.csv` | 回写 `threat_budget_coef`、`spell_charge_per_damage`、`threat_budget_coef_boss_fix`（仅 `--calibrate`）、`reward_*`、`sim_*`、`expected_meta_level` 列 |
| `data/balance/level_difficulty.json` | 关卡策划 PR #5 建的文件，本脚本按原结构重新生成（校准后的系数、每波预算、模拟结果），**不要手改** |
| `data/balance/combat/stats.json` | 战斗策划 PR #4 约定的数值文件（含敌人数值 enemies / bosses），从 CSV 生成，**不要手改** |
| `data/progression/character_level_cost.csv`、`meta_rules.csv` | 按 `config.py` 的公式重新生成 |
| `docs/design/numeric/generated/sim_results.md` | 给人看的模拟结果表 |
| `tools/numeric/output/*.csv` | 同样的结果，表格版（该目录有 `.gdignore`，Godot 不会导入） |

## 改参数该改哪里

| 想改的东西 | 改哪里 |
| --- | --- |
| 角色攻击、射程、费用、暴击、卖出、同名上限、符卡满能量 | `data/characters.csv` |
| 敌人血量、速度、护甲、威胁点、击杀充能 | `data/enemies.csv` |
| 开局灵力、升级花费、伤害公式参数、预算公式、充能规则、叫波奖励 | `data/balance/battle_rules.csv` |
| 技能、状态（灼烧/结界）、联动、符卡的系数 | `data/balance/combat_coefficients.csv` |
| 每关波数、系数、敌人参考组成、首通目标 | `data/balance/level_difficulty.csv` |
| roguelite 强化池 | `data/roguelite_buffs.csv` |
| 局外升级花费公式、首通奖励公式 | `tools/numeric/config.py`，然后跑 `gen_progression.py` 或 `run_all.py` |
| 模拟里「玩家怎么玩」的假设（带谁、先放谁、集中培养几人、符卡手动还是自动） | `tools/numeric/config.py` |
| MVP 地图（格子、路线、冰面） | `tools/numeric/ref_maps.json`（PR #5 地图的快照；关卡策划改了地图要同步） |

`init_level_difficulty.py` 是重排关卡结构时才用的一次性脚本，会覆盖校准结果，需要加 `--force`。

## 文件说明

| 文件 | 作用 |
| --- | --- |
| `tdsim.py` | 单关模拟器：PR #5 地图（多路线、预设格、冰面、浓雾）或参考路、敌人移动、PR #4 伤害流水线（暴击、护甲、易伤桶、联动桶、最少 1）、技能、减速/冻结/时停/阻挡/送回、同名多个、灵力收支、共用能量条和危急充能、手动/自动符卡、三选一（每 5 波，打完最后一波不再给；2 层质变 + 保底）、Boss 阶段和回起点 |
| `gen_stats_json.py` | 从 CSV 生成 `data/balance/combat/stats.json`（保留 PR #4 的 ID） |
| `gen_level_json.py` | 从 CSV 生成 `data/balance/level_difficulty.json`（保持 PR #5 的结构） |
| `ref_maps.json` | PR #5 MVP 7 关的地图快照 |
| `mvp_sweep.py` | MVP 7 关系数扫描 |
| `campaign.py` | 整条战役推演：按剧情解锁、一关一关打，发首通奖励、给每个角色升级（平均分 / 集中培养）；可自动校准系数；Boss 建议方案 |
| `gen_progression.py` | 生成局外养成表和每关奖励列 |
| `run_all.py` | 串起来跑并出报告 |
| `config.py` | 可调参数 |

模型假设和局限见 `docs/design/numeric/09_simulation.md`。模拟是简化模型，结论要靠试玩校正。
