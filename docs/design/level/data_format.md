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
| `enemy_catalog.json` | 关卡要用的敌人 id、显示名、首次出场、威胁点。生命和移速不在这里 |
| `character_roster.json` | 角色 id、能不能放、从哪一关加入。放置消耗不在这里 |
| `rating.json` | 星级区间。全游戏共用，不写进每一关 |
| `data/balance/level_tables/level_difficulty.csv` | 数值策划的难度种子表。他们会整表替换 |

导出过滤器已经是 `data/*`。按现有架构说明，它连子目录里的 JSON 一起打进包。加载器接上之前，玩家还不会看见这些关。

## 坐标

列 `col` 从左到右是 0 到 6。行 `row` 从上到下是 0 到 11。`map.origin` 固定写 `row_0_is_north`，表示第 0 行在画面最上方。残影往更大的行号走，最后到守护点。

给人看的地图仍把入口画成 `E`、障碍画成 `#`、预定槽位画成 `*`。JSON 的 `cells` 用战斗侧字符：入口 `S`，守护点 `G`，障碍 `B`，路线 `P`，预定槽位 `.`。战斗侧把 `.` 叫做可放置。这里每一个 `.` 都是槽位，不能再有别的可放置格。坐标是 0 起的 `[列, 行]`。

## 每一关都有的字段

| 字段 | 含义 |
| --- | --- |
| `schema_version` | 现在固定是 1。以后改字段就加版本，不偷偷改旧文件的意思 |
| `id` | 关卡 id。只能是 `prologue_01` 到 `prologue_03`、`ch1_01` 到 `ch5_04`、`final_01` |
| `difficulty_id` | 难度表里的同一行。必须和 `id` 相同。这一关多重，去那一行看，不写在关卡文件里 |
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
| `new_character_ids` | 这一关新给的角色。没有就是空数组。id 用战斗侧的 `chr_` 加叙事角色 id，例如 `chr_reimu` |
| `new_enemy_ids` | 这一关新出现的残影。没有就是空数组 |
| `unlock_character_ids` | 通关这一关后加入的角色。下一关的可放置名单才会出现她们。这一关的首通名单不含她们 |
| `params.starting_spirit_power` | 开局灵力。已确认是 150。每活过一波再加 20，写在难度表，不写进每一波 |
| `params.lives` | 开局生命。现在每一关都是 20，schema 把它定死了。困难模式以后另做，不在这里改小 |
| `params.available_character_ids` | 这一关首通可以放置的角色。等于开局角色加上前面每一关 `unlock_character_ids` 的合计 |
| `bosses` | 首领。普通关和草案关都是空数组。画完的首领关才有内容 |
| `placeholders._placeholder` | 固定 `true`。提醒读文件的人：还有和数值、战斗对齐的事 |
| `placeholders.align_with` | 要找谁对齐。现在是「数值策划」和「战斗策划」 |
| `placeholders.note` | 用中文写明哪些数是占位。威胁预算不要再写在这里 |

`route_type` 的取值：

| 值 | 含义 |
| --- | --- |
| `straight` | 一条直路 |
| `curve` | 弯路 |
| `fork_merge` | 一个入口，中间分开，再汇合 |
| `double_entrance` | 两个入口。第一章第 2 关起就可以有 |
| `dual_route` | 两条都要顾的路，第三章还要加上村民 |
| `flying` | 有飞行路线。从第四章开始 |
| `fixed_gates` | 几条路线开战前就画好。入口按波次或阶段打开、关掉。格子不在战斗中改。第五章和终章用这个 |

### 只在画完的关卡里有

| 字段 | 含义 |
| --- | --- |
| `map` | 地图。见下一节。战斗直接读这里的 `cells`、`paths`、`guard`、`terrain`、`cell_sets` |
| `waves` | 波次。见再下一节。战斗读 `wave_id`、`spawns`、`next_wave_delay_sec`、`is_boss` |
| `spell_energy_start` | 开局符卡能量，0 到 100。现在是 0 |
| `spell_charge_mult` | 本关充能倍率。序章按战斗草案写 2.0，其余 1.0。不是数值定案 |
| `deploy_time_sec` | 布阵秒数。现在是 10 |
| `deploy_wait_for_player` | 序章为真：等玩家放完才开始倒计时。战斗草案 |
| `intermission_sec` | 波与波之间的空档，只能 3 到 5。现在是 4 |

草案关不能写这两个字段。

### 只在草案关里有

| 字段 | 含义 |
| --- | --- |
| `wave_count` | 计划中的波数。序章前两关可以少于 5，但那两关已经画完，不写这个字段。草案关是 10 到 20 |
| `design_notes` | 中文备注。首领阶段、符卡和还没画的地图变化写在这里 |

画完的关卡不能写这两个字段。它们的说明在 `docs/design/level/` 对应的那一篇里。

## 地图 `map`

战斗策划按这些字段读图。预定槽位用他们的 `.`，再由 `slots` 把每一个 `.` 列出来。他们可以不读 `slots`，但关卡校验要求两边一样。

| 字段 | 含义 |
| --- | --- |
| `columns` | 固定 7 |
| `rows` | 固定 12 |
| `origin` | 固定 `row_0_is_north` |
| `cells` | 12 个字符串，每个长度 7。`P` 路线，`.` 预定槽位（战斗侧叫可放置），`B` 障碍，`S` 裂缝（入口），`G` 守护点 |
| `cell_legend` | 上面五个字符的英文名，给战斗对照 |
| `entrances` | 入口列表。每项有 `id`、`col`、`row`。id 形如 `entrance.north`。这一格在 `cells` 里必须是 `S` |
| `guard.cell` | 守护点，`[列, 行]`。必须是 `G`，而且是每条路径的最后一格 |
| `guard.id`、`guard.display_name` | 和关卡顶部的 `guard_point` 是同一个守护点 |
| `paths` | 路径列表 |
| `terrain` | 关卡自带的地形。见下 |
| `cell_sets` | 名字到格子的集合，给首领符卡查。琪露诺用三组，见 `ch1_04` |
| `slots` | 预定槽位，3 到 6 个。必须和每一个 `.` 一一对应。战斗可以不读 |

一条路径：

| 字段 | 含义 |
| --- | --- |
| `path_id` | 形如 `path.main`。战斗读这个 |
| `id` | 和 `path_id` 相同，关卡文档沿用旧名字 |
| `entrance_id` | 从哪个入口出发 |
| `kind` | `ground` 或 `flying`。现在画完的图全是 `ground` |
| `cells` | 从裂缝走到守护点的 `[列, 行]` 列表。相邻两格只能差一列或差一行 |

`cells` 字符串里的每一个 `P` 都必须被至少一条路径走过。起点是 `S`，终点是 `G`。路径之间可以共用格子。

一条地形：

| 字段 | 含义 |
| --- | --- |
| `terrain_id` | `ter_ice`、`ter_icicle`、`ter_fog`、`ter_barrier` |
| `cells` 或 `rect` | 二选一。格子是 `[列, 行]` 的数组。`rect` 是 `[列, 行, 宽, 高]` |
| `start` | `level_start`，或 `wave_2` 这种「第几波开始」 |
| `duration_sec` | 秒。`-1` 表示一直在 |
| `note` | 可选。给人看的中文 |

`ter_ice` 只能铺在路线上，敌人移速 ×1.5，这是战斗的地形表，关卡不另写倍率。`ter_icicle` 只能铺在预定槽位上。`ter_fog` 让打在雾格上的目标射程减 1。第一章用它，不再写攻击范围倍率。

一个预定槽位：

| 字段 | 含义 |
| --- | --- |
| `id` | 形如 `slot.mid_left` |
| `col`、`row` | 坐标。这一格必须是 `.` |
| `label` | 短名字 |
| `why` | 为什么留在这里 |

槽位必须上下左右至少挨着 `P`、`S` 或 `G`。斜着不算。没有列进 `slots` 的格子不能是 `.`。

## 波次 `waves`

| 字段 | 含义 |
| --- | --- |
| `id` | `w01` 这种两位编号。一关里面不能重复 |
| `wave_id` | 和 `id` 相同。战斗读这个 |
| `delay_sec` | 这一波开始前再等多少秒。制作人定波间 3 到 5 秒，关卡写 4。第一波的 4 秒是开战空隙，另外还有 10 秒布阵 |
| `next_wave_delay_sec` | 战斗字段。等于下一波的 `delay_sec`。最后一波是 0 |
| `duration_sec` | 固定 20。这一波刷怪大约持续 20 秒。首领关最后一波如果 `ends_when` 是 `boss_defeated`，20 秒只是刷怪窗口 |
| `ends_when` | `spawn_window` 表示刷完并经过波间空隙就结束。`boss_defeated` 只用于首领关的最后一波 |
| `is_boss` | 只有首领入场的那一波为真，用来播一次登场 |
| `pressure` | 可选。`minion` 或 `boss_phase`。冰之残影关仍交替，但交替不切换符卡 |
| `note` | 可选。有三选一的那一波要写上「三选一」。少于 5 波的关不要写 |
| `spawns` | 这一波的刷怪。战斗读这个名字 |

一组 `spawns`：

| 字段 | 含义 |
| --- | --- |
| `enemy_id` | 例如 `enm_shade_basic` |
| `path_id` | 走哪条路径 |
| `count` | 至少 1 |
| `interval_sec` | 相邻两只相隔多少秒，必须大于 0。一组的出场窗口（组延迟 +（数量 − 1）× 间隔）落在 18 到 22 秒 |
| `delay_sec` | 相对这一波开始再等多少秒 |
| `entrance_id` | 关卡多留的入口 id，必须是这张图上有的 |

画完的关：每一波的 `count × threat_points` 必须等于 `(10 + 4 × 波次) × threat_budget_coef`。系数种子是 1.0，所以现在就是整数。首领不占预算。

序章前两关可以少于 5 波，现在是 3 波和 4 波，没有三选一。其余关卡是 10 到 20 波，每 5 波一次三选一。序章第 3 关和第一章是 10、11、12，首领 15。后面各章草案是 10、12、14、16，终章 20。

## 难度表 `data/balance/level_tables/level_difficulty.csv`

这张表归数值策划。他们之后会整表替换。列是平的，所以这次改成 CSV，方便直接换行。文件放在 `data/balance/level_tables/`，旁边有 `.gdignore`：Godot 会把普通 `.csv` 当成翻译表导入，这个目录避开导入器。校验器和测试按文本读取。文件开头的 `#` 注释写明归属和公式。

约定的每一波预算是 `(10 + 4 × wave_index) × threat_budget_coef`，`wave_index` 从 1 起。系数现在每一关都是 1.0，等模拟。参考值先不要套用：首领约 1.3，下一章第 1 关约 0.85。系数若以后不是 1，按四舍五入到整数，再重做那一关的编组。

首通剩余生命：普通关 11 到 13，首领关大约 10 到 11。这是手感目标，还等制作人确认。它不是星级分档。2 星的占位是剩余至少 50%（10/20）。

| 列 | 含义 |
| --- | --- |
| `level_id` | 和关卡 id 相同 |
| `chapter` | `prologue`、`ch1` 到 `ch5`、`final` |
| `level_index` | 解锁顺序，1 到 24 |
| `level_role` | `teaching`、`practice`、`test`、`boss` |
| `wave_count` | 几波 |
| `threat_budget_coef` | 现在全部 `1.0` |
| `hp_multiplier` | `1 + 0.15 × (level_index − 1)`，只升不降 |
| `reward_spirit_start` | 开局灵力 150 |
| `reward_spirit_per_wave` | 每活过一波加 20 |
| `reward_buff_after_waves` | 三选一的波次，用分号隔开，例如 `5;10;15`。少于 5 波则空着 |
| `reward_buff_pick_count` | 有三选一的关是 3。少于 5 波是 0 |
| `expected_first_clear_lives` | `11-13` 或首领的 `10-11` |
| `reward_meta_first_clear` | 局外首通奖励。现在是 `pending_numbers`，不要发明数字 |
| `reward_meta_replay` | 局外重打奖励。一定比首通少。现在也是 `pending_numbers` |

生命 20、首领不占预算，写在文件开头的注释里，不每行重复。分波预算不存进表，校验按公式算。

## 首领 `bosses`

一项首领：

| 字段 | 含义 |
| --- | --- |
| `id` | `boss_cirno` 这种战斗侧 id |
| `display_name` | 给人看的名字 |
| `character_id` | 例如 `chr_cirno` |
| `blocks_character_id` | 决斗期间不能放置的角色。不能出现在可放置名单里。冰之残影不锁琪露诺，写 `null` |
| `enters_at_wave_id` | 从哪一波走进来 |
| `entrance_id`、`path_id` | 从哪进、走哪条路 |
| `prelude_wave_ids` | 入场前的波。琪露诺是前 4 波。这些波不必再被阶段瓜分 |
| `phases` | 2 到 3 个血量阶段，每个阶段一张符卡 |
| `combat_notes` | 中文列表 |
| `leak` | 走到守护点后扣命，回到裂缝，再走同一条路。`lives_source` 指向 `stats.json` 里的 `leak_damage`，不抄数字 |

一个阶段：

| 字段 | 含义 |
| --- | --- |
| `id` | `phase_1` 到 `phase_3` |
| `display_name` | 例如「冰瀑」 |
| `spell_card_id` | 战斗侧符卡 id，例如 `sc_boss_cirno_icicle_fall` |
| `spell_card_name` | 给人看的牌名 |
| `hp_ratio_start`、`hp_ratio_end` | 血量比例。琪露诺是 1.00–0.66、0.66–0.33、0.33–0 |
| `cells_ref` | `cell_sets` 里的名字 |
| `terrain_id` | 可选。冰瀑是 `ter_icicle`，钻石风暴是 `ter_ice` |
| `duration_sec` | 可选。冰柱 12 秒，冰面 `-1` 表示直到击败 |
| `status_on_character`、`status_on_shade` | 可选。冻结用 `st_freeze`。减速的状态 id 是 `st_slow`，这一关的符卡不用它 |
| `note` | 中文 |

`boss_cirno_p2_area` 不是格子数组。她在移动，所以写成 `mode: radius_around_boss`、`radius_cells: 2.5`、`follows: boss_position`。详见 `ch1_04` 的说明。

草案里的首领不写进 `bosses`。阶段写在 `design_notes`。

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

生命、护甲、击破灵力、漏怪扣命、击破充能的权威来源是数值策划的 `data/balance/combat/stats.json`，字段是 `enemies` 和 `bosses`。图鉴用 `stat_source` 指向这份表。这里只留关卡编排要的字段。校验如果看见 `hp`、`move_speed` 或抄来的属性数字，会失败。

| 字段 | 含义 |
| --- | --- |
| `id` | `enm_` 或 `boss_` |
| `display_name` | 中文名 |
| `introduced_in` | 第一次出现的关卡。还没有关用到时是 `null`，例如 `boss_meiling` |
| `threat_points` | 用来对波次预算。普通残影和快残影是 1，硬残影是 4。首领是 `null`，不占预算 |
| `threat_points_status` | `confirmed_for_budget` 或 `level_design_placeholder`。预留怪的数字不能当成已确认预算 |
| `splits_into` | 可选。堆积体记下战斗草案：死亡分裂出 3 个 `enm_shade_fast` |
| `note` | 中文 |

预留、以后章节再用：`enm_shade_phantom`（遗忘之影）、`enm_shade_heap`（堆积体）、`enm_shade_rift`（结界之渣）。扑人残影和飞屑还没有战斗 id，不写进图鉴。

## 角色名单 `character_roster.json`

放置消耗和攻击数字不在本文件。

| 字段 | 含义 |
| --- | --- |
| `id` | `chr_` 加叙事角色 id，例如 `chr_reimu` |
| `display_name` | 气泡名 |
| `playable` | `yes` 是已定的 MVP。`pending_文案策划` 是提案，可以写进后续关的可放置名单。`pending_producer` 还在等制作人，不能写进可放置名单 |
| `role` | 英文短标签，例如 `slow`、`pierce`。只说明方向 |
| `joins_at_level` | 从哪一关开始能放。忘要等终章通关，所以是 `null` |

## 星级 `rating.json`

| 字段 | 含义 |
| --- | --- |
| `max_lives` | 20 |
| `defeat_lives` | 0。到 0 就是失败 |
| `stars_do_not_grant_power` | `true` |
| `stars_grant` | 现在写了 `cosmetics` 和 `codex_stories`。具体外观和图鉴句子还没做 |
| `hard_mode` | `later`。这次没有困难倍率 |
| `win`、`lose` | 最后一波结束还有命即胜，命到 0 即败。首领关相同 |
| `two_star_lives_ratio` | 2 星要达到的剩余生命比例。现在是 `0.5`，状态 `pending_numbers` |
| `bands` | 三档。1 星是通关且剩余 1 到 9，2 星是 10 到 19，3 星只有 20 |
| `replay` | 已通关的关可以重打，并能补星。局外奖励看难度表那两列 |
| `leak.stored_in_level_data` | `false`。扣几条命不写在关卡里 |
| `leak.note` | 指向 `data/balance/combat/stats.json` 的 `enemies` 和 `bosses` |
| `first_clear` | 普通关剩余 `11-13`，首领关 `10-11`。状态是关卡和数值已对齐，等制作人确认 |

## 这次故意不放进文件的字段

下面这些已经在草案备注里提到，但没有做成字段，避免假装规则已经定了：

- 村民的避难路线，以及褪色几人算失败
- 魔理沙的包把残影吸过去
- 战斗中途改路径的格子。路线几何已经定成开战前固定，不再做 `path_shifts`
- 飞行路径具体经过哪些障碍格
- 击破一只残影回复多少灵力
- 困难模式

## 怎么检查

在仓库根目录执行：

```bash
python3 tools/validate_levels.py
```

它会检查：JSON 能解析，符合 schema，地图是 7×12，路径连续，入口是 `S`、守护点是 `G`，每一个 `.` 都是预定槽位并且贴着路线，地形和冰之残影的三组格子符合战斗约定，每一波威胁等于 `(10 + 4 × 波次) × 系数`，新章第 1 关的威胁合计低于上一章最后一关，少于 5 波没有三选一、其余每 5 波一次，可放置名单跟着 `unlock_character_ids` 走，星级区间是上面那三档。图鉴里不能再出现生命和移速。

Godot 测试 `tests/unit/test_level_data.gd` 再查一遍地图、路径、威胁和星级，不查 schema 文本。CI 的 lint 跑 Python 校验，test 跑 Godot 测试。
