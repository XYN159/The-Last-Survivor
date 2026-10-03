# 明日方舟（Arknights）系统与数据研究

给《东方守幻录》（XYN159/Touhou-forgotten-defense）做参考用的研究资料。整理人：明日方舟收集员。最后更新：2026-10-03 18:25（UTC+8，第 4 轮）。

## 这个目录是干什么的

- 把明日方舟的数据结构、数值公式、关卡节奏、养成经济、系统框架等整理成中文文档，供守幻录的策划和数值对照。
- 文档里的结论尽量来自本地原始数据的统计（脚本可重跑）。数据里看不出来的，注明出自哪里（主要是 PRTS wiki）。拿不准的标「待核实」。
- 守幻录这边以开着的 PR 分支为准（main 上的 GDD 是旧车道草案）：#3 GDD、#5 关卡、#8 数值、#11 制作计划，必要时看 #4 战斗。

## 使用边界（重要）

- `raw/` 里的明日方舟原始数据**只在这台电脑上做统计**。不外传，不复制进守幻录仓库，也不把原始 JSON、截图、美术、文本放进游戏。
- 文档里引用的字段名、少量数值和条目名，只用来说明结构和做法。守幻录的数值和内容要自己设计，不照搬。
- 明日方舟的著作权归鹰角网络（Hypergryph）所有；数据来自社区解包仓库，这里只做个人研究。
- 守幻录仓库只读查看，不评论、不改动、不开 PR。

## 目录

```
raw/
  excel/        明日方舟 excel 表（30 个 JSON，约 130 MB）
  levels/
    enemy_database.json      敌人数值库（2163 种）
    obt/main/*.json          主线关卡 153 个（第 1 轮 0–3 章 60 个；第 2 轮补到 0–8 章，含支线 S 关）
    obt/hard/*.json          H 关 16 个（第 2 轮，H5–H8）
    obt/training/*.json      教学关 TR 20 个
    activities/…             2 个活动的 4 个关卡（拉取时顺带取到，未使用）
    _fetch_manifest.csv      关卡拉取清单（共 193 条）
  story/                     （第 2 轮）主线剧情脚本 517 个 txt，约 12 MB，只做结构统计
    _fetch_manifest.csv      剧情拉取清单（storyTxt、来源、路径、大小、状态）
scripts/
  ops.py                 （项目统筹）干员属性统计 → stats/operators_*.csv
  inventory.py           （第 1 轮）盘点 raw/scripts/stats → stats/raw_inventory.csv
  fetch_levels.py        （第 1 轮）按 stage_table 拉关卡 JSON，只新增不覆盖；--zones 指定章节
  verify_formulas.py     （第 1 轮）用 raw 数据核对公式 → stats/formula_checks.txt 等
  ak_common.py           （第 2 轮）共用函数：读表、敌人属性合并、出场时刻推算、能力关键词分类
  fetch_story.py         （第 2 轮）拉主线剧情和战斗内剧情脚本 → raw/story/，只新增不覆盖
  analyze_enemies.py     （第 2 轮）敌人统计 → stats/enemies_report.txt、enemy_*.csv
  analyze_stages.py      （第 2 轮）每关指标 → stats/stages_*.csv、stage_mechanics_first.csv、stages_report.txt
  analyze_pacing.py      （第 2 轮）关内节奏 → stats/stage_pacing.csv、pacing_report.txt
  analyze_story.py       （第 2 轮）剧情结构 → stats/story_*.csv、story_report.txt
  verify_round2.py       （第 2 轮）核实第 1 轮的待核实项 → stats/formula_checks_r2.txt
  analyze_operators.py   （第 3 轮）职业、分支、费用—强度、范围 × 阻挡、技能 → stats/operator_*.csv、operator_roles_report.txt
  analyze_progression.py （第 3 轮）等级、精英化、技能、专精、模组成本，推荐练度，干员 vs 敌人，理智 → stats/progression_*.csv、progression_report.txt
  analyze_bosses.py      （第 4 轮）首领关、章末关、护甲保留比例，守幻录 ch1_04 系数核对 → stats/boss_report.txt、boss_stages.csv、chapter_end_stages.csv
stats/
  operators_by_rarity.csv / operators_by_prof_rarity.csv / operators_by_sub.csv / operators_maxstats.csv（项目统筹）
  raw_inventory.csv      文件清单、大小、sha1、结构
  formula_checks.txt     公式核对报告（人读）
  level_options.csv      已拉关卡的初始费用、回费、部署上限、生命、地图尺寸、波次
  enemy_attr_level0.csv  每种敌人 level 0 的主要属性
  damage_examples.csv    伤害公式算例
  —— 第 2 轮 ——
  enemies_report.txt               敌人统计报告（E1~E7）
  enemy_by_leveltype.csv           普通/精英/首领的属性分位数
  enemy_ability_categories.csv     能力类别 × 级别
  enemy_variants.csv               同族强化型（_2/_3）对比
  enemy_main_usage.csv             主线 0–8 章每种敌人的首次出场与出场次数
  stages_main.csv                  每关一行（189 关）：地图、路线、出怪、总血、时长、费用、剧情触发
  stages_by_chapter.csv            按章中位数
  stage_mechanics_first.csv        新机制首次出现
  stages_report.txt                关卡报告（S1~S7）
  stage_pacing.csv / pacing_report.txt   关内四等分、20 秒窗口、空档、精英/首领出场位置（P1~P4）
  story_entries.csv                每段剧情一行（标题、位置、行数、字数、说话人数、演出命令数；不含正文）
  story_by_chapter.csv / story_report.txt  剧情按章汇总（T1~T9）
  formula_checks_r2.txt            第 1 轮待核实项的核对（V1~V6）
  —— 第 3 轮 ——
  operator_roles_report.txt        干员报告（O1~O8）
  operator_subclass.csv            72 个分支：伤害类型、阻挡、间隔、范围形状、费用、属性、标签
  operator_cost_strength.csv       职业 × 稀有度：费用、属性、攻/间隔、每费指标
  operator_skills.csv              945 个技能：类型、回复方式、SP、持续、主要效果
  progression_report.txt           成长报告（P1~P9）
  progression_level_cost.csv       各稀有度各阶段的经验 / 龙门币
  progression_evolve_materials.csv 每名干员精英化材料（件数、最高阶、折底层）
  progression_skill_cost.csv       技能 1→7 级与每个技能的专精成本
  progression_recommended.csv      主线关推荐练度（256 关）
  progression_vs_enemy.csv         0~8 章：推荐练度下的干员攻击 vs 敌人中位属性
docs/
  data-structures.md     数据表结构与表间关系
  formulas.md            战斗与成长公式
  enemies.md             （第 2 轮）敌人数值库：分级、属性、能力类型、精英与首领
  stages-and-pacing.md   （第 2 轮）关卡：地图、路线、出怪节奏、强度曲线、新机制顺序
  story-pacing.md        （第 2 轮）剧情结构：插入位置、章节结构、每关剧情量
  operator-roles.md      （第 3 轮）职业与分支定位、费用与强度、范围 × 阻挡、技能类型
  economy-and-progression.md （第 3 轮）局外成长成本曲线、推荐练度、敌人 vs 玩家成长、理智结构
  boss-and-armor.md      （第 4 轮）首领关与护甲：明日方舟章末关 / 首领 vs 守幻录 Boss，ch1_04 系数核对，4 种 Boss 方案
  mapping-to-touhou.md   （第 4 轮）所有「对守幻录的启示」汇总表（优先级、PR / 文件、岗位）和需要用户拍板的决策点
```

## 数据来源与版本

| 项目 | 内容 |
| --- | --- |
| 来源仓库 | GitHub `Kengxxiao/ArknightsGameData`，`zh_CN/gamedata/`（国服简中） |
| 对应提交 | `a550f5e`（2026-09-29 16:02 UTC+8，提交说明 `Client:2.7.71 Data:26-09-22-07-47-20_6c71fa`） |
| 数据版本 | `gamedata_const.dataVersion = 77.6.0`，`resPrefVersion = 77d0d0`；上游 `data_version.txt` 写 `VersionControl:77.6.0`，`Change:123576 on 2026/09/17` |
| 一致性核对 | 本地 9 个文件（character_table、skill_table、stage_table、enemy_handbook_table、chapter_table、crisis_table、favor_table、range_table、enemy_database）的 sha1 与该提交逐一相同 |
| 已有文件 | `raw/excel` 30 个、`raw/levels/enemy_database.json` 由项目统筹在 2026-10-03 17:19 放入；本轮没有改动或删除它们 |
| 第 1 轮新增 | `raw/levels/obt/…` 77 个关卡 + 4 个活动关卡，共约 5.5 MB，来源同一提交，清单见 `raw/levels/_fetch_manifest.csv` |
| 第 2 轮新增 | 关卡补拉到主线 0–8 章（含支线、H 关），清单共 193 条；主线剧情脚本 517 个（`raw/story/`），来源同一提交 |
| 出场时刻算法 | 关卡数据只存延迟和间隔，出场时刻按 PRTS 地图微件（Hydrogina/sandbox/map）的算法推算，见 `docs/stages-and-pacing.md` 第 0 节；多波关的波间要等清场，时长只能算下限 |
| 社区资料 | PRTS wiki：[游戏数据基础](https://prts.wiki/w/游戏数据基础)、[作战机制](https://prts.wiki/w/作战机制)、[部署费用](https://prts.wiki/w/部署费用)（页面标注的参考客户端版本为 2.7.61～2.7.71，与本地数据同期） |

盘点细节（每个文件的大小、sha1、顶层结构、条目数）见 `stats/raw_inventory.csv`。几个主要表的条目数：character_table 1375 条（其中 8 职业可获得干员 429 名，其余是召唤物、装置等）、skill_table 1811、stage_table.stages 3602、enemy_handbook_table.enemyData 1765、enemy_database 2163、item_table.items 1564、zone_table.zones 482。

已知小问题：`scripts/ops.py` 里还会生成 `operators_by_prof6.csv`，但 `stats/` 里没有这个文件，说明 4 个 CSV 是用更早版本的脚本生成的。本轮没有重跑 `ops.py`，因为重跑会覆盖项目统筹的 4 个 CSV。

## 怎么重跑

在 `/workspace/research/arknights/` 下：

```bash
python3 scripts/inventory.py          # 盘点，几秒
python3 scripts/fetch_levels.py       # 只补缺的关卡，已有的跳过；--zones main_4 可扩到别的章
python3 scripts/verify_formulas.py    # 重算 stats/formula_checks.txt 等 4 个文件
# 第 2 轮
python3 scripts/fetch_levels.py --zones main_4,main_5,main_6,main_7,main_8   # 补拉 4–8 章（已有的跳过）
python3 scripts/fetch_story.py        # 拉剧情脚本（已有的跳过）
python3 scripts/analyze_enemies.py
python3 scripts/analyze_stages.py
python3 scripts/analyze_pacing.py
python3 scripts/analyze_story.py
python3 scripts/verify_round2.py
# 第 3 轮
python3 scripts/analyze_operators.py
python3 scripts/analyze_progression.py
# 第 4 轮
python3 scripts/analyze_bosses.py
```

只需要 Python 3 标准库。

## 文档索引与进度

| # | 主题 | 文件 | 状态 | 一句话 |
| --- | --- | --- | --- | --- |
| 1 | 数据结构 | [docs/data-structures.md](docs/data-structures.md) | 第 1 轮完成，第 2 轮补地图方向 | 干员、技能、敌人、关卡、波次各表的字段和关系 |
| 2 | 公式 | [docs/formulas.md](docs/formulas.md) | 第 1 轮完成，第 2 轮核实 4 项 | 伤害、攻速、阻挡、费用、再部署、精英化/等级/潜能/信赖 |
| 3 | 干员职业定位 | [docs/operator-roles.md](docs/operator-roles.md) | 第 3 轮完成 | 8 职业画像、72 分支、费用买的是功能、范围 × 阻挡、技能类型与 SP 节奏、对照 #8 角色表 |
| 4 | 敌人 | [docs/enemies.md](docs/enemies.md) | 第 2 轮完成 | 三级属性分布、能力类型、强化型、首领分量与登场时机 |
| 5 | 关卡与节奏 | [docs/stages-and-pacing.md](docs/stages-and-pacing.md) | 第 2 轮完成 | 地图与路线、出怪节奏、强度曲线、新机制顺序、对照 #5/#8 |
| 6 | 经济与养成 | [docs/economy-and-progression.md](docs/economy-and-progression.md) | 第 3 轮完成 | 等级 / 精英化 / 技能 / 专精成本、推荐练度、敌人 vs 玩家成长、对照 #8 05/07，理智只做结构参考 |
| 7 | 系统框架 | docs/systems-framework.md | 待做 | 主线/活动/集成战略/危机合约等玩法的组织 |
| 8 | 美术与 UI 框架 | docs/art-ui-framework.md | 待做 | 只记做法和信息层级，不复制素材 |
| 9 | 剧情节奏 | [docs/story-pacing.md](docs/story-pacing.md) | 第 2 轮完成 | 行动前/后/幕间、每章剧情量、战斗内弹窗、对照 #3 和 PR #2 |
| 10 | 对照守幻录 | [docs/mapping-to-touhou.md](docs/mapping-to-touhou.md) | 第 4 轮完成 | 47 条启示（高 7 / 中 25 / 低 15），对应 PR / 文件、岗位、现状；8 个需用户拍板的决策点 |
| 11 | 首领关与护甲 | [docs/boss-and-armor.md](docs/boss-and-armor.md) | 第 4 轮完成 | 明日方舟首领关 / 章末关数据，守幻录 Boss 并排，ch1_04 系数核对（以 0.71 为准），4 种 Boss 方案 |

## 看过的守幻录分支（只读）

| PR | 分支 | 看的提交 | 看了什么 |
| --- | --- | --- | --- |
| #3 | `docs/gdd-touhou-td` | `6d18f33` | `docs/GDD.md` |
| #5 | `cursor/design-level-framework-01a3` | `822ae26` | `docs/design/level/data_format.md` |
| #8 | `numeric/touhou-td-framework` | `eddf21a` | `docs/design/numeric/01_combat_and_characters.md`、`data/characters.csv`、`data/balance/combat_coefficients.csv` |
| #11 | `docs/production-plan` | `7b7fe32` | `docs/production/DECISIONS_PENDING.md` |
| #2 | `docs/touhou-narrative-draft` | `02c7ba6`（第 2 轮） | `docs/design/narrative/story_outline.md`、`dialogue_samples.md` |
| #3 | `docs/gdd-touhou-td` | `6d18f33`（第 2 轮） | `docs/GDD.md` 的章节、关卡数、剧情规划部分 |
| #5 | `cursor/design-level-framework-01a3` | `822ae26`（第 2 轮） | `docs/design/level/overview.md`、`data/levels/ch1_01.json` |
| #8 | `numeric/touhou-td-framework` | `eddf21a`（第 2 轮） | `data/balance/level_difficulty.json` |
| #8 | `numeric/touhou-td-framework` | `eddf21a`（第 3 轮，分支头未变） | `data/characters.csv`（含 notes）、`docs/design/numeric/05_meta_progression.md`、`07_progression_vs_difficulty.md`、`docs/design/numeric/` 目录 |
| #3 | `docs/gdd-touhou-td` | `6d18f33`（第 3 轮，分支头未变） | `docs/GDD.md` 的角色、成长、经济相关部分 |
| #8 | `numeric/touhou-td-framework` | `eddf21a`（第 4 轮，分支头未变） | `02_enemies_and_waves.md`、`06_level_curve.md`、`07_progression_vs_difficulty.md`、`data/balance/level_difficulty.csv`、`level_difficulty.json`、`data/characters.csv` |
| #5 | `cursor/design-level-framework-01a3` | `822ae26`（第 4 轮，分支头未变） | `data/levels/ch1_04.json`；该分支没有 `data/balance/level_difficulty.json`（404） |
| #11 | `docs/production-plan` | `c26b6b8`（第 4 轮，2026-10-03 17:41 UTC+8） | `docs/production/DECISIONS_PENDING.md` |

第 2 轮注意到：#5 最新提交说明写「ch1_04 系数现在是 0.74」，而 #8 稍后的提交说明写「ch1_04 威胁系数锁定为 0.71」，两处可能不同步。**第 4 轮已读文件核实**：#8 的 CSV / JSON / 06 都是 0.71；#5 `ch1_04.json` 注释写 0.74，但实际编组是 0.70 的预算（合计 441）；#8 07 的表和 #11 D-01 也还是旧数。详见 `docs/boss-and-armor.md` 第 1 节。
