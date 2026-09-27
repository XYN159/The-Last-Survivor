# 关卡数据格式

程序以后读 `data/levels/` 里的 JSON。这次没有写游戏内的加载器。设计期的检查是严的：字段错了，校验直接失败。以后真正进游戏时，要学 `BalanceConfig` 的做法：每个字段有默认值和地板，坏文件只警告，不闪退。那一步另开 PR。

schema 在 `data/levels/level.schema.json`，方言是 JSON Schema 2020-12。

## 文件

| 文件 | 作用 |
| --- | --- |
| `level.schema.json` | 单关文件的格式 |
| `index.json` | 24 关的顺序。这个顺序就是解锁顺序 |
| `prologue_01.json` … `ch1_04.json` | 画完的 7 关 |
| `ch2_01.json` … `final_01.json` | 17 关草案，只有说明，没有地图 |
| `enemy_catalog.json` | 残影和首领的 id、占位威胁、占位属性 |
| `character_roster.json` | 角色 id、能不能放、占位灵力消耗 |
| `rating.json` | 星级区间。全游戏共用，不写进每一关 |

导出过滤器已经是 `data/*`。按现有架构说明，它连子目录里的 JSON 一起打进包。加载器接上之前，玩家还不会看见这些关。

## 坐标

列 `col` 从左到右是 0 到 6。行 `row` 从上到下是 0 到 11。`map.origin` 固定写 `row_0_is_north`，表示第 0 行在画面最上方。残影往更大的行号走，最后到守护点。

文档里的地图为了好读，会把入口画成 `E`、守护点画成 `G`、好位置画成 `*`。JSON 里没有这三种字符。入口和守护点的那一格在 `grid` 里是 `P`，好位置在 `grid` 里是 `.`。

## 每一关都有的字段

| 字段 | 含义 |
| --- | --- |
| `schema_version` | 现在固定是 1。以后改字段就加版本，不偷偷改旧文件的意思 |
| `id` | 关卡 id。只能是 `prologue_01` 到 `prologue_03`、`ch1_01` 到 `ch5_04`、`final_01` |
| `status` | `complete` 表示地图和波次都有。`stub` 表示只有说明 |
| `chapter_id` | `prologue`、`ch1` 到 `ch5`、`final` |
| `index_in_chapter` | 这一章里的第几关，从 1 数 |
| `display_name` | 给人看的关卡名，例如「神社的直路」 |
| `display_name_key` | 提案的文本 key，形如 `level.prologue_01.name`。叙事那份 `names_zh.csv` 还没合并，也还没有这些行 |
| `kind` | `tutorial` 教学，`normal` 普通，`boss` 章节首领，`final_boss` 终章 |
| `route_type` | 路线类型，见下表 |
| `guard_point.id` | 守护点 id，形如 `guard.hakurei_offering_box` |
| `guard_point.display_name` | 给人看的名字，例如「赛钱箱」 |
| `summary` | 这一关希望玩家学会什么，一句话 |
| `player_feeling` | 这一关希望玩家感受到什么 |
| `teaches` | 学会的要点，字符串数组 |
| `new_character_ids` | 这一关新给的角色。没有就是空数组。id 用叙事稿的 `char.reimu` 这一组 |
| `new_enemy_ids` | 这一关新出现的残影。没有就是空数组 |
| `params.starting_spirit_power` | 开局灵力。占位。击破后的回复不在这个文件里 |
| `params.lives` | 开局生命。现在每一关都是 20，schema 把它定死了。困难模式以后另做，不在这里改小 |
| `params.available_character_ids` | 这一关可以放置的角色。新角色必须在里面。正在和玩家决斗的角色不能在里面 |
| `modifiers` | 全图生效的修正，例如浓雾。没有就是空数组 |
| `bosses` | 首领。普通关和草案关都是空数组。画完的首领关才有内容 |
| `placeholders._placeholder` | 固定 `true`。提醒读文件的人：威胁和灵力还没定案 |
| `placeholders.align_with` | 要找谁对齐。现在是「数值策划」和「战斗策划」 |
| `placeholders.threat_budget` | 这一关的占位威胁预算 |
| `placeholders.note` | 用中文写明哪些数是占位 |

`route_type` 的取值：

| 值 | 含义 |
| --- | --- |
| `straight` | 一条直路 |
| `curve` | 弯路 |
| `fork_merge` | 一个入口，中间分开，再汇合 |
| `double_entrance` | 两个入口。从第二章开始 |
| `dual_route` | 两条都要顾的路，第三章还要加上村民 |
| `flying` | 有飞行路线。从第四章开始 |
| `moving` | 战斗中路线会变。从第五章开始 |

### 只在画完的关卡里有

| 字段 | 含义 |
| --- | --- |
| `map` | 地图。见下一节 |
| `waves` | 波次。见再下一节 |

草案关不能写这两个字段。

### 只在草案关里有

| 字段 | 含义 |
| --- | --- |
| `wave_count` | 计划中的波数。普通关 8 到 12，首领关 15 |
| `design_notes` | 中文备注。首领阶段、符卡和还没画的地图变化写在这里 |

画完的关卡不能写这两个字段。它们的说明在 `docs/design/level/` 对应的那一篇里。

## 地图 `map`

| 字段 | 含义 |
| --- | --- |
| `columns` | 固定 7 |
| `rows` | 固定 12 |
| `origin` | 固定 `row_0_is_north` |
| `grid` | 12 个字符串，每个长度 7。字符只有 `#` 障碍、`.` 空地、`P` 路线 |
| `entrances` | 入口列表。每项有 `id`、`col`、`row`。id 形如 `entrance.north`。这一格在 grid 里必须是 `P` |
| `guard_cell` | 守护点坐标 `col`、`row`。必须是 `P`，而且是每条路径的最后一格 |
| `paths` | 路径列表 |
| `good_spots` | 好位置，3 到 6 个 |

一条 `paths` 里的项：

| 字段 | 含义 |
| --- | --- |
| `id` | 形如 `path.main`、`path.left`、`path.right` |
| `entrance_id` | 从哪个入口出发 |
| `kind` | `ground` 或 `flying`。现在画完的图全是 `ground`。`flying` 留给第四章 |
| `cells` | 从入口走到守护点的坐标列表，按顺序。相邻两格只能差一列或差一行，不能斜着，不能跳格，不能重复。每一格都必须是 `P` |

grid 里的每一个 `P` 都必须被至少一条路径走过。路径和路径之间可以共用格子。

一个好位置：

| 字段 | 含义 |
| --- | --- |
| `id` | 形如 `spot.mid_left` |
| `col`、`row` | 坐标。这一格必须是 `.` |
| `label` | 短名字，例如「直路中段左」 |
| `why` | 为什么这里好。给策划和程序看，不是玩家台词 |

好位置必须上下左右至少挨着一格 `P`。斜着不算。

## 波次 `waves`

| 字段 | 含义 |
| --- | --- |
| `id` | `w01` 这种两位编号。一关里面不能重复 |
| `delay_sec` | 这一波开始前再等多少秒。第一波从关卡开始算。后面的波从上一波最后一只出场算起 |
| `note` | 可选。给读数据的人看的中文，例如「第一只疾走玩具」 |
| `groups` | 这一波里的一组或多组残影 |

一组 `groups`：

| 字段 | 含义 |
| --- | --- |
| `enemy_id` | 敌人图鉴里的 id，例如 `remnant.faded_toy` |
| `count` | 这一组出几只，至少 1 |
| `interval_sec` | 这一组里，相邻两只相隔多少秒。必须大于 0 |
| `entrance_id` | 从哪个入口出来。必须是这张图上有的入口 |
| `path_id` | 走哪条路径。必须是这张图上有的路径 |
| `delay_sec` | 相对这一波开始，这一组再等多少秒。和波本身的 `delay_sec` 不是同一个数 |

画完的关：所有组的 `count × 该敌人的 threat` 加起来，再加 `bosses` 里每个首领的 threat 一次，必须等于 `placeholders.threat_budget`。

普通关和教学关的波数是 8 到 12。首领关是 14 到 16。现在的首领关是 15。

## 修正 `modifiers`

现在只用在浓雾上。

| 字段 | 含义 |
| --- | --- |
| `id` | 例如 `mist` |
| `display_name` | 例如「浓雾」 |
| `effects` | 效果列表 |

一个效果：

| 字段 | 含义 |
| --- | --- |
| `id` | 现在用到的是 `attack_range_multiplier` 和 `enemy_speed_multiplier` |
| `value` | 数字。倍率或 0 |
| `duration_sec` | 可选。持续多少秒 |
| `starts_after_sec` | 可选。从第几秒开始生效 |
| `_placeholder` | 固定 `true`。这些数等数值策划 |
| `note` | 中文说明 |

第一章的雾写的是攻击范围倍率。冰面写的是残影移速倍率。冻不冻角色不在效果 id 里，写在首领的 `combat_notes`。

## 首领 `bosses`

一项首领：

| 字段 | 含义 |
| --- | --- |
| `id` | 图鉴里的首领 id，例如 `boss.cirno` |
| `display_name` | 给人看的名字 |
| `character_id` | 对应的角色 id |
| `blocks_character_id` | 决斗期间不能放置的角色。现在和 `character_id` 是同一个。这个角色不能出现在 `available_character_ids` 里 |
| `enters_at_wave_id` | 从哪一波走进来 |
| `entrance_id`、`path_id` | 从哪进、走哪条路 |
| `prelude_wave_ids` | 符卡之前的波。可以是空的。琪露诺关用了前 5 波当出场，这 5 波没有符卡 |
| `phases` | 2 到 3 个阶段。每个阶段一张符卡 |
| `combat_notes` | 中文列表。写给战斗策划、还没做成规则的事 |

一个阶段：

| 字段 | 含义 |
| --- | --- |
| `id` | `phase_1`、`phase_2`、`phase_3` |
| `display_name` | 例如「冰瀑」 |
| `spell_card_id` | 叙事稿里的符卡 key，例如 `spell.cirno.icicle_fall` |
| `spell_card_name` | 给人看的牌名，例如冰符「冰瀑」 |
| `wave_ids` | 这一阶段包含哪些波 |
| `map_changes` | 这一阶段怎么改地图。至少一条 |

前奏和所有阶段的波次合在一起，必须刚好等于这一关的全部波次，不能重叠，也不能漏。

一条地图变化：

| 字段 | 含义 |
| --- | --- |
| `id` | 例如 `ice_column` |
| `label` | 给人看的短名 |
| `cells` | 被改掉的格子。每一格都必须已经是路线 `P` |
| `terrain` | 现在只允许 `ice`。新地形要改 schema |
| `replaces_previous` | 为真时，这一阶段开始就撤掉上一阶段的变化，换成这一条 |
| `effects` | 和雾一样的效果对象 |

琪露诺的第二阶段有两个移速效果：先是 0，持续 3 秒；再是 1.5，从第 3 秒开始。两个数都是占位。

草案里的首领不写进 `bosses`。他们的阶段写在 `design_notes`，避免一个只有半截字段的首领对象混进校验。

## 索引 `index.json`

| 字段 | 含义 |
| --- | --- |
| `schema_version` | 1 |
| `game_title` | 东方守幻录 |
| `unlock_rule` | 固定 `sequential_clear`。通关上一关才开下一关 |
| `stars_do_not_grant_power` | 固定 `true` |
| `note` | 中文说明 |
| `chapters` | 章节目录。每项有 `id`、`display_name`、`location`、`guard_point_name`、`level_ids` |
| `levels` | 按解锁顺序排列。每项有 `id`、`file`、`status`、`chapter_id`、`unlock_after` |

第一关的 `unlock_after` 是 `null`。后面每一关的 `unlock_after` 必须是上一关的 id。

章节关数：序章 3，第一章到第五章各 4，终章 1。

## 敌人图鉴 `enemy_catalog.json`

整个文件有 `_placeholder: true`。

| 字段 | 含义 |
| --- | --- |
| `move_speed_unit` | 提案的单位名：`cells_per_second`，每秒走几格。未定案 |
| `note` | 怎么把威胁加进预算 |
| `entries` | 一条残影或一位首领 |

一条 entry：

| 字段 | 含义 |
| --- | --- |
| `id` | 敌人或首领 id |
| `display_name` | 中文名 |
| `category` | `remnant` 或 `boss` |
| `proposal` | `true` 表示这个 id 是关卡侧新提案，叙事稿里没有这个名字 |
| `introduced_in` | 第一次出现的关卡 id。还没有任何关使用时是 `null`，例如 `boss.meiling` |
| `threat` | 占位威胁。正整数 |
| `stats.hp` | 占位生命 |
| `stats.move_speed` | 占位移速 |
| `stats.armor` | 占位护甲 |
| `tags` | 字符串标签，例如 `flying`、`stealth`、`splits`。给战斗策划看方向，不是结算规则 |
| `splits_into` | 可选。堆积体用它写出分裂成谁、几只 |
| `note` | 中文 |

## 角色名单 `character_roster.json`

整个文件有 `_placeholder: true`。灵力消耗没有定案。

| 字段 | 含义 |
| --- | --- |
| `id` | 叙事稿的 `char.*` |
| `display_name` | 气泡名 |
| `playable` | `yes` 可以放。`pending_producer` 还在等制作人，不能写进关卡的可放置名单 |
| `spirit_power_cost` | 放下去花多少灵力。占位 |
| `role` | 英文短标签，例如 `slow`、`pierce`。只说明方向 |
| `joins_at_level` | 从哪一关开始能放。忘要等终章通关，所以是 `null` |

一关的起始灵力至少要够放最便宜的那个可放置角色，否则教学关没法动手。这只是校验，不是平衡。

## 星级 `rating.json`

| 字段 | 含义 |
| --- | --- |
| `max_lives` | 20 |
| `defeat_lives` | 0。到 0 就是失败 |
| `stars_do_not_grant_power` | `true` |
| `stars_grant` | 现在写了 `cosmetics` 和 `codex_stories`。具体外观和图鉴句子还没做 |
| `hard_mode` | `later`。这次没有困难倍率 |
| `bands` | 三档。1 星是剩余 1 到 9，2 星是 10 到 17，3 星是 18 到 20 |
| `leak._placeholder` | `true` |
| `leak.lives_cost_per_remnant` | 暂定 1。等数值策划 |
| `leak.note` | 中文说明精英和首领还没定 |

## 这次故意不放进文件的字段

下面这些已经在草案备注里提到，但没有做成字段，避免假装规则已经定了：

- 村民的避难路线，以及褪色几人算失败
- 魔理沙的包把残影吸过去
- 战斗中途改路径的 `path_shifts`
- 飞行路径具体经过哪些障碍格
- 击破一只残影回复多少灵力
- 困难模式

## 怎么检查

在仓库根目录执行：

```bash
python3 tools/validate_levels.py
```

它会检查：JSON 能解析，符合 schema，地图是 7×12，路径连续并且只走路线格，好位置贴着路线，波次威胁等于预算，新章第 1 关的预算低于上一章最后一关，星级区间是上面那三档。

Godot 测试 `tests/unit/test_level_data.gd` 再查一遍地图、路径、威胁和星级，不查 schema 文本。CI 的 lint 跑 Python 校验，test 跑 Godot 测试。
