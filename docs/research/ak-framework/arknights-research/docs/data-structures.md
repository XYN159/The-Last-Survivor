# 明日方舟数据结构与表间关系

> 数据：`raw/`（ArknightsGameData 国服数据，提交 `a550f5e`，dataVersion 77.6.0）。本篇字段名照抄原表，例子都是 raw 里的真实条目。数字由 `scripts/verify_formulas.py`、`scripts/inventory.py` 统计（结果在 `stats/`），文中会注明。
> 更新：2026-10-03（UTC+8）。

## 0. 一张图看懂

```
                        ┌──────────── gamedata_const（全局常量：等级上限、精英化龙门币、经验表…）
                        │
character_table[charId] ─┬─ skills[].skillId ───────────▶ skill_table[skillId].levels[]（每级 blackboard）
  phases[].rangeId ─────┼──────────────────────────────▶ range_table[rangeId].grids
  subProfessionId ──────┼──────────────────────────────▶ uniequip_table.subProfDict（分支中文名）
  phases[].evolveCost / skills[].levelUpCostCond / allSkillLvlup ─▶ item_table.items[itemId]
  favorKeyFrames ───────┴── 信赖点数换算 ───────────────▶ favor_table.favorFrames

zone_table[zoneId] ◀── stage_table.stages[stageId] ──levelId──▶ raw/levels/obt/…/level_xxx.json
  └─ chapter_table           │ hardStagedId（#f# 突袭）             ├─ mapData（地图格子）
                             │ stageDropInfo ─▶ item_table          ├─ routes（路线）
                             │                                       ├─ waves → fragments → actions(SPAWN key)
                             │                                       ├─ enemyDbRefs(id, level, overwrittenData)
                             │                                       └─ runes（突袭等加成）
                                                                               │
                         enemy_handbook_table.enemyData[enemyId] ◀────────────┤（图鉴：名字、档位、伤害类型）
                         levels/enemy_database[enemyId][level]  ◀─────────────┘（数值本体）
```

一句话：**charId、skillId、stageId、enemyId 是主键；关卡 JSON 只记"放什么、什么时候放"，敌人数值从数据库按 level 下标取。**

## 1. character_table（干员、召唤物、装置）

以 `charId` 为键，共 1375 条。`profession` 不只有 8 个职业，还包括 `TRAP` 843 个（地图装置）和 `TOKEN` 74 个（召唤物）。8 个职业共 458 条，其中 `isNotObtainable=false` 的可获得干员 429 名（`stats/operators_maxstats.csv` 也是 429 行）。

| 字段 | 含义 | 例：`char_208_melan` 玫兰莎 |
| --- | --- | --- |
| `name` / `appellation` | 名字 / 英文名 | 玫兰莎 / Melantha |
| `description` | 分支特性文本 | 能够阻挡一个敌人 |
| `rarity` | 稀有度，字符串 `TIER_1`~`TIER_6` | `TIER_3`（3★） |
| `profession` | 职业 | `WARRIOR`（近卫） |
| `subProfessionId` | 分支 | `fearless`（无畏者，中文名在 `uniequip_table.subProfDict`） |
| `position` | 只能放地面还是高台 | `MELEE` |
| `tagList` | 招募标签 | `['输出', '生存']` |
| `maxPotentialLevel` / `potentialItemId` | 潜能上限 / 潜能信物 | 5（即潜能 1~6） |
| `phases[]` | 每个精英化阶段一项（E0/E1/E2） | 见下 |
| `skills[]` | 技能槽，包括 `skillId` 和专精花费 | 3★ 有 1 个技能 |
| `talents[]` | 天赋，按精英化和潜能分档 | 见下 |
| `potentialRanks[]` | 潜能 2~6 的效果 | 见下 |
| `favorKeyFrames` | 信赖加成关键帧 | 见下 |
| `allSkillLvlup[]` | 技能 1→7 级的通用花费（6 档） | 第 1 档用 3301 技巧概要·卷1 |

### 1.1 phases[]：精英化阶段

每个阶段有 `rangeId`、`maxLevel`、`attributesKeyFrames`、`evolveCost`。**`attributesKeyFrames` 永远只有两帧：1 级和满级**（统计 1236 个阶段全部如此，见 `stats/formula_checks.txt` A1）。中间等级要自己插值，见 formulas.md。

玫兰莎的例子：

| 阶段 | 等级 | 生命 | 攻击 | 防御 | 费用 | rangeId |
| --- | --- | --- | --- | --- | --- | --- |
| E0 | 1 → 40 | 1395 → 1993 | 396 → 583 | 83 → 119 | 13 | 1-1 |
| E1 | 1 → 55 | 1993 → 2745 | 583 → 738 | 119 → 155 | 15 | 1-1 |

E1 1 级的数值等于 E0 满级（全部 807 次精英化都这样，A2），费用 +2。

`attributesKeyFrames[].data` 是一个统一的「属性包」，敌人数据也用这一套字段：`maxHp`、`atk`、`def`、`magicResistance`、`cost`、`blockCnt`、`moveSpeed`、`attackSpeed`（干员全是 100）、`baseAttackTime`（攻击间隔，玫兰莎 1.5 秒）、`respawnTime`（再部署时间，70 秒）、`spRecoveryPerSec`（干员全是 1.0）、`maxDeployCount`、`tauntLevel`（嘲讽等级）、`massLevel`（重量），以及一串 `*Immune` 免疫开关（`stunImmune`、`silenceImmune`、`frozenImmune`……）。

`evolveCost` 是 `[{id, count, type}]`，`id` 指向 `item_table.items`，例如 3241「狙击芯片」、30012「固源岩」、30052「酮凝集」。精英化要花的龙门币不在这里，而在 `gamedata_const.evolveGoldCost`。

### 1.2 skills[] 和 skill_table

`character_table.skills[]`：`skillId`、`overridePrefabKey`、`levelUpCostCond[]`（专精 1~3，每项有 `unlockCond`、`lvlUpTime`、`levelUpCost` 材料列表。例：能天使 S3 的 `unlockCond` 是 `PHASE_2` 1 级，`lvlUpTime` 为 28800 / 57600 / 86400 秒，也就是 8 / 16 / 24 小时。3★ 玫兰莎这一项为空，不能专精）。

`skill_table[skillId]`：共 1811 条，有 `iconId`、`hidden`，主体是 `levels[]`。普通技能有 10 级（1~7 级加专精 1~3，928 个），少数只有 7 级（17 个）。每一级包含：

| 字段 | 含义 |
| --- | --- |
| `name` / `description` | 描述里有占位符，例如 `攻击力+{atk:0%}`，数值从 blackboard 填进去 |
| `rangeId` | 开技能时换成的攻击范围，null 表示不换 |
| `skillType` | `MANUAL` 手动 741 / `PASSIVE` 被动 571 / `AUTO` 自动 499（按技能等级计数） |
| `durationType` | `NONE` 按时间；`AMMO` 按弹药次数 |
| `spData` | `spType`（`INCREASE_WITH_TIME` 自然回复 / `INCREASE_WHEN_ATTACK` 攻击回复 / `INCREASE_WHEN_TAKEN_DAMAGE` 受击回复 / 数值 `8`）、`spCost`、`initSp`、`maxChargeTime`（可充能次数）、`increment` |
| `duration` | 持续秒数；`-1` 表示无限 |
| `blackboard` | `[{key, value, valueStr}]`，技能实际效果的参数 |

例子（全部取自 raw）：

- `skcom_atk_up[1]`（「攻击力强化·α型」）1 级：SP 50，持续 20 秒，`atk = 0.1`。
- `skchr_angel_3`（能天使 S3）专精 3：`AUTO`，`spCost 30`、`initSp 20`、持续 15 秒，`attack@atk_scale = 1.1`、`attack@times = 5`、`base_attack_time = -0.11`。
- `skchr_svrash_3`（银灰 S3）专精 3：`atk 2.0`、`def -0.7`、目标数 6，SP 90 / 初始 75，持续 30 秒。
- `skchr_amgoat_2`（艾雅法拉 S2）专精 3：`maxChargeTime 3`（可充能 3 次）、倍率 3.7、`magic_resistance -0.25`。
- `skcom_charge_cost[1]`（「冲锋号令·α型」）1 级：`cost = 6`。

`blackboard` 的键名不完全统一：有的带前缀（`attack@atk_scale`），有的直接写（`atk`）。它们的含义要和技能描述对着看，**没有一张独立的键名字典**。

`spType` 等于数字 8 的技能基本都对应被动技能。第 2 轮核实：可获得干员里 49 个 `spType = 8` 技能全部是被动，且技能等级几乎都是 `spCost = 0`，作用是「不需要技力」；代码里的名字仍**待核实**（见 `formulas.md` 第 2.2 节）。

### 1.3 talents / potentialRanks / favorKeyFrames

- `talents[].candidates[]`：同一个天赋会按 `unlockCondition`（`phase` + `level`）和 `requiredPotentialRank` 分成几档，每档有自己的 `blackboard`。例：玫兰莎 E1 天赋「攻击力 +4%」，E1 55 级后变成 +8%。
- `potentialRanks[]`：5 项，对应潜能 2~6。效果写在 `buff.attributes.attributeModifiers[]`，每项是 `{attributeType, formulaItem, value}`。玫兰莎：`COST` −1、`RESPAWN_TIME` −4、`ATK` +25……；`type = CUSTOM` 表示「天赋强化」，数值在 `talents` 里。
- `favorKeyFrames`：两帧，`level 0` 和 `level 50`。玫兰莎 50 级是 `atk +65`。这里的 level 指的是 `favor_table` 里的 `battlePhase`，不是信赖点数（见下节）。

### 1.4 range_table

73 种范围，结构是 `{id, direction, grids:[{row, col}]}`，坐标相对于干员所在格、面朝右。例：`1-1` = `(0,0)`、`(0,1)`，即本格加前方一格（近卫和重装最常见）。**范围是格子集合，不是半径**，部署时转方向。

## 2. 辅助表

| 表 | 关键结构 | 例子 |
| --- | --- | --- |
| `gamedata_const` | 全局常量 | `maxLevel = [[30],[30],[40,55],[45,60,70],[50,70,80],[50,80,90]]`（按稀有度×阶段）；`evolveGoldCost`、`characterExpMap`、`characterUpgradeCostMap`；`subProfessionDamageTypePairs`（分支→伤害类型：PHYSICAL 49 / MAGICAL 15 / HEAL 6 / NONE 6）；`dataVersion 77.6.0` |
| `favor_table` | `maxFavor 25570`；`favorFrames[]` 共 201 帧，每帧 `{level, data:{favorPoint, percent, battlePhase}}` | `battlePhase = floor(percent / 2)`，全部帧都成立；信赖 100% 时 battlePhase = 50，对应 `favorKeyFrames` 的满帧 |
| `item_table.items` | 1564 种道具，`itemId → {name, rarity, itemType…}` | 3241 狙击芯片、30012 固源岩、3303 技巧概要·卷3、4002 至纯源石 |
| `uniequip_table` | 模组；`subProfDict` 有分支 id 和中文名 | `fearless → 无畏者` |

## 3. 敌人：图鉴和数值分在两处

### 3.1 enemy_handbook_table（图鉴，给玩家看的）

- `enemyData[enemyId]`，共 1765 条：`name`、`enemyIndex`、`enemyLevel`（`NORMAL`/`ELITE`/`BOSS`）、`damageType`（如 `["PHYSIC"]`）、`abilityList`、`linkEnemies`、`hideInHandbook` 等。例：`enemy_1006_shield` 重装防御者，`enemyIndex '8'`、`enemyLevel ELITE`、`damageType ['PHYSIC']`。
- `levelInfoList`：把数值换成档位的阈值表（SS、S+…E），每档有 `attack`/`def`/`magicRes`/`maxHP`/`moveSpeed`/`attackSpeed` 的区间。例：SS 档要求生命 ≥ 500000、防御 ≥ 5000。**图鉴里不写具体数字，只显示档位。**
- `raceData`：11 种种族，例如 `infection` 感染生物、`drone` 无人机。

### 3.2 levels/enemy_database.json（数值本体）

结构：`{"enemies":[{"Key": enemyId, "Value":[{"level":0, "enemyData":{…}}, {"level":1, …}]}]}`，共 2163 种。

- **每个字段都包成 `{m_defined, m_value}`。** level 0 是完整数据；level ≥ 1 只把要改的字段设成 `m_defined: true`，其余沿用 level 0。
- `enemyData` 主要字段：`name`、`applyWay`（`MELEE`/`RANGED`…）、`motion`（`WALK`/`FLY`）、`levelType`、`lifePointReduce`（漏过扣几点生命）、`rangeRadius`、`attributes`（与干员同一套属性包）、`talentBlackboard`、`skills`、`spData`。

| 敌人 | level | 生命 | 攻击 | 防御 | 法抗 | 移速 | 间隔 | 扣命 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| `enemy_1007_slime` 源石虫 | 0 | 550 | 130 | 0 | 0 | 1.0 | 1.7 | 1 |
| 同上 | 1 | 2050 | 300 | （沿用） | | | | |
| `enemy_1006_shield` 重装防御者 | 0 | 6000 | 600 | 800 | 0 | 0.75 | 2.6 | 1 |
| 同上 | 1 | 8000 | （沿用 600） | 850 | | | | |

全体分布（2111 种、去掉不移动的单位，`stats/enemy_attr_level0.csv`）：生命中位数 10000、防御中位数 300、法抗中位数 20、移速中位数 0.8；`FLY` 174 种。`levelType`：NORMAL 968、ELITE 841、BOSS 302。`lifePointReduce`：普通和精英几乎都是 1，也有 0（不扣命）；BOSS 主要是 2（88 种）和 5（62 种）。

## 4. 关卡：stage_table → 关卡 JSON

### 4.1 stage_table.stages（关卡的"外壳"）

共 3602 个：ACTIVITY 2483、MAIN 709、CLIMB_TOWER 239、SUB 87……。以 `main_01-07`「1-7 暴君」为例：

| 字段 | 值 | 含义 |
| --- | --- | --- |
| `stageId` / `code` / `name` | `main_01-07` / 1-7 / 暴君 | |
| `zoneId` | `main_1` | → `zone_table`「第一章 黑暗时代·下」→ `chapter_table` 的 `chapter_0`「觉醒」（包含 main_0~main_3） |
| `levelId` | `Obt/Main/level_main_01-07` | → 关卡 JSON（小写路径 `obt/main/level_main_01-07.json`） |
| `hardStagedId` | `main_01-07#f#` | 突袭版。它是另一个 stageId（`difficulty = FOUR_STAR`），**和普通版共用同一个 levelId** |
| `dangerLevel` | LV.10 | 推荐等级（只是文本） |
| `apCost` | 6 | 理智消耗 |
| `expGain` / `goldGain` / `passFavor` | 60 / 60 / 6 | 通关奖励 |
| `unlockCondition` | `tr_09` | 先通关教学关 TR-9 |
| `stageDropInfo.displayDetailRewards` | 首通掉落 `char_278_orchid`（干员）、常规掉落 30012、`DIAMOND` 4002 | 掉落表也指向 `item_table` |

主线关之间会插入 `tr_xx` 教学关。

### 4.2 关卡 JSON（关卡的"内容"）

本轮拉取了主线 0~3 章 60 关和教学关 17 关（`raw/levels/obt/`）。顶层字段：`options`、`mapData`、`runes`、`routes`、`enemyDbRefs`、`waves`、`predefines`、`randomSeed`、`branches` 等。下面以 `level_main_01-07` 为例：

**options（关卡参数）**：`initialCost 10`、`maxCost 99`、`costIncreaseTime 1.0`（每秒 1 费）、`characterLimit 8`（同时在场上限）、`maxLifePoint 10`、`moveMultiplier 0.5`。主线 60 关的分布（`stats/level_options.csv`）：

- `initialCost` 为 10 的有 57 关；`maxCost` 全是 99；`costIncreaseTime` 全是 1.0；`moveMultiplier` 全是 0.5。
- `characterLimit` 为 8 的有 54 关。
- `maxLifePoint`：3（21 关）、5（15）、10（8）、15（8）、8（7）、20（1）。

**mapData**：`map` 是二维数组（行 × 列），每格存 `tiles` 的下标；`tiles[i]` 有 `tileKey`、`heightType`（`LOWLAND` 地面 / `HIGHLAND` 高台）、`buildableType`（`MELEE`/`RANGED`/`NONE`）、`passableMask`。1-7 是 7 行 × 11 列，画出来是这样（`#` 禁区、`.` 地面、`^` 高台、`S` 出怪点、`E` 保护点）：

```
###########
#^^^....._S
#^...^^^^##
E..#....._S
#^...^^^^##
#^^^....._S
###########
```

主线地图尺寸以 8×11（17 关）和 7×11（15 关）最多，都是横屏。**方向（第 2 轮已核实）**：`routes`、`predefines` 等坐标的 row 0 在画面**最下方**，而 `mapData.map` 数组的第 0 行是画面**最上方**，两者要用 `map[H − 1 − row]` 换算。依据：189 个关卡文件里，WALK 路线起点直接查 map 只单独对上 tile_start 5 次，翻转后单独对上 2912 次（上下对称、两种都对上的 1671 次）（`scripts/verify_round2.py` V1）。上面 1-7 这张图上下对称，所以起点两种算法都对得上，看不出来。NGA 帖也说「坐标从左下角 (0,0) 开始」，yuanyan3060/ArknightsGameResource 的 `levels_gen.py` 用的也是 `height − row − 1`。

**routes**：27 条（26 条 `WALK`，1 条 `E_NUM`）。每条有 `startPosition`、`endPosition`、`checkpoints[{type: MOVE, position}]`。例：从 (5,10) 出发，经 (5,4)→(4,4)→(4,2)→(3,2)，到 (3,0)。路线由**几个拐点**描述，中间的路径由游戏寻路生成，不需要逐格列出。

**waves**：三层结构 `waves[] → fragments[] → actions[]`。

- `wave`：`preDelay`、`postDelay`、`maxTimeWaitingForNextWave`、`fragments`
- `fragment`：`preDelay`、`actions`
- `action`：`actionType`（已拉的 77 关里出现过 `SPAWN` 出怪、`STORY` 剧情、`PREVIEW_CURSOR` 路线预告、`DISPLAY_ENEMY_INFO` 新敌人介绍、`ACTIVATE_PREDEFINED` 启用预置单位、`PLAY_OPERA` 演出）、`key`（敌人 id，如 `enemy_1007_slime_2`）、`count`、`interval`、`preDelay`、`routeIndex`（→ `routes` 下标）；另外还有 `blockFragment`、`randomSpawnGroupKey` 等字段，分别控制是否等清场、随机出怪。第 2 轮补充：主线 0~8 章的 wave 全部是 `maxTimeWaitingForNextWave = −1`、`postDelay = 0`，即下一波一直等到清场；0~8 章没有用到随机出怪组；出场时刻的推算方法见 `stages-and-pacing.md` 第 0 节

1-7 只有 1 个 wave，含 6 个 fragment、27 个 action（SPAWN 24、PREVIEW_CURSOR 2、STORY 1），一共出 41 个敌人。

**enemyDbRefs**：`[{id, level, overwrittenData}]`。关卡用到的每种敌人都在这里登记，`level` 是 `enemy_database` 里的下标。`overwrittenData` 可以只针对这一关改个别字段（同样是 `m_defined` 写法）。主线前几章大多是 level 0、不覆盖。

**predefines**：开局就放好的单位。1-7 在 (3,3) 放了一个 `trap_002_emp` 震撼装置（它本身也是 character_table 里的一条 TRAP）。

**runes**：用来实现关卡加成。突袭（`#f#`）不是另做一份关卡，而是在同一个关卡文件上叠加 rune：`gbuff_lifepoint`（生命 = 1）、`ebuff_attribute`（敌人 `atk`/`def`/`max_hp` ×1.2）、`cbuff_cost_recovery`（`scale 2.0`：第 2 轮已核实是乘在回费间隔上，即回费速度减半，1-7 突袭说明写的就是「部署费用的自然回复速度减半」）。

**randomSeed**：每关一个固定种子，1-7 是 1924903387。

## 5. 小结：明日方舟数据组织的几个习惯

1. **一个 id 一路串到底**：charId → skillId → rangeId → itemId；stageId → levelId → enemyId(+level)。每张表只管自己那块。
2. **配置写「首末两帧」，中间靠插值**：干员的等级属性和信赖加成都只存两帧。
3. **变体只写差异**：敌人 level 1+ 只写改动的字段；关卡里的 `overwrittenData` 也一样；突袭用 rune 叠在普通关上。
4. **展示和数值分开**：图鉴只给档位，数值在数据库里；技能描述用占位符从 blackboard 取数，不会出现文案和数值不一致的问题。
5. **关卡 = 地图 + 路线 + 时间轴**：时间轴里不只能出怪，也能放剧情、路线预告。

## 对守幻录的启示

对照的是 PR #5 的 `data/levels/*.json`（分支 `cursor/design-level-framework-01a3`）和 PR #8 的 `data/characters.csv`、`stats.json`（分支 `numeric/touhou-td-framework`）。

- **敌人"图鉴/数值"分离，守幻录已经这样做了**：PR #5 的 `enemy_catalog.json` 只登记 id，数值以 #8 的 `stats.json` 为准，关卡文件里不写敌人生命和移速。这与明日方舟一致，值得坚持。将来做「强化版残影」时，可以学 `enemy_database` 的 level 下标，只写差异字段，不必复制整条。
- **困难模式可以用"关卡 + 加成层"来做**：GDD 说困难模式以后再做。明日方舟的突袭是在同一份关卡上叠 rune（敌人属性 ×1.2、生命改成 1），没有复制关卡。守幻录以后可以在关卡 JSON 外加一个 `modifiers` 列表，24 关不必各写两份。
- **波次结构基本对得上**：PR #5 的 `waves[].spawns[]{enemy_id, path_id, count, interval_sec, delay_sec}`，对应明日方舟 `action{key, routeIndex, count, interval, preDelay}`，差一层 fragment。明日方舟把剧情、路线预告和新敌人介绍（`STORY`、`PREVIEW_CURSOR`、`DISPLAY_ENEMY_INFO`）也放进同一条时间轴。守幻录的教学提示、新敌人预告如果需要卡在某个时刻出现，可以考虑做成 spawns 旁边的事件条目，不必另起一套。
- **符卡描述可以用占位符**：明日方舟的技能描述是 `{atk:0%}` 从 blackboard 填数。守幻录 #8 已经把系数放进 `combat_coefficients.csv`，如果 UI 文案也从这张表取数，改系数时就不会漏改文案。
- **关卡路径的写法差别**：守幻录 PR #5 逐格列出路径（`paths[].cells`），明日方舟只写拐点再寻路。守幻录的地图只有 7×12，逐格写更直观，也方便校验，不需要改；只是提醒，如果以后需要动态改路（比如放阻挡），逐格路径会更难维护。
