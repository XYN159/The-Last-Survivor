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
| `enemy_catalog.json` | 关卡要用的敌人 id、显示名、文本 key 和引用路径。生命、移速和威胁点不在这里 |
| `character_roster.json` | 角色 id、能不能放、从哪一关加入。放置消耗不在这里 |
| `rating.json` | 星级区间。全游戏共用，不写进每一关 |
| `data/balance/level_difficulty.json` | 数值策划的难度表。权威在 PR #8。本 PR 不附带这份文件，要在 #8 之后合并 |

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
| `display_name_status` | 可选。`decided` 或 `pending_文案策划`。玩家看到的暂名还没定稿时用后者 |
| `kind` | `tutorial` 教学，`normal` 普通，`boss` 章节首领，`final_boss` 终章 |
| `route_type` | 路线类型，见下表 |
| `guard_point.id` | 守护点 id，形如 `guard.hakurei_offering_box` |
| `guard_point.display_name` | 给人看的名字，例如「赛钱箱」 |
| `summary` | 这一关希望玩家学会什么，一句话 |
| `player_feeling` | 这一关希望玩家感受到什么 |
| `teaches` | 这一关只有一个主教学点，一句话 |
| `previews` | 可选。顺带看到的内容，字符串数组。不算学习曲线验收点 |
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
| `delay_sec` | 这一波开始前再等多少秒。第 1 波是 0：布阵倒计时一结束，第一只立即出场。其余波是 4，对应 PR #4 `rules.json` 的 `intermission_sec` |
| `next_wave_delay_sec` | 战斗字段。等于下一波的 `delay_sec`。最后一波是 0 |
| `duration_sec` | 固定 20。刷怪窗口，从本波第一只出场算到最后一只出场。窗口结束后空 4 秒再来下一波，不等场上清空。叫波会跳过剩余的窗口和空档。首领关最后一波如果 `ends_when` 是 `boss_defeated`，20 秒仍只是刷怪窗口 |
| `ends_when` | `spawn_window` 表示刷怪窗口结束并经过后面的空档，下一波就开始。`boss_defeated` 只用于首领关的最后一波 |
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

画完的关：文件 `data/balance/level_difficulty.json` 存在时，每一波的敌人威胁要等于该关的 `wave_threat_budgets`，全关合计要等于 `threat_budget_total`。这份文件由 PR #8 提供。它还不在本 PR 里时，校验只打印警告并跳过这项，不报错。首领不占预算。硬残影只允许出现在第一章第 3 关，共 8 只。

### 时间轴

普通关：开局布阵倒计时 10 秒，可以点「开始」提前结束。倒计时一结束，第一只立即出场，第 1 波 `delay_sec` 是 0。每一波先用 20 秒把怪刷完，再空 4 秒，然后下一波，不等场上清空。叫波会跳过剩余的窗口和这 4 秒空档。

序章：布阵倒计时停在 10 秒不走，玩家放下第一个角色后才开始倒数。之后和普通关一样，第 1 波不再另加 4 秒。关卡里用 `deploy_wait_for_player: true` 表示这件事。

序章前两关可以少于 5 波，现在是 3 波和 4 波，没有三选一。制作人已定：非序章关卡每关 1 到 3 次，最后一波不弹。10 波只有第 5 波后一次。15 波是第 5、10 波后。20 波是第 5、10、15 波后。11 到 14 波同 15 波，16 波同 20 波。波数不改。

## 难度表 `data/balance/level_difficulty.json`

这张表归数值策划，权威文件在 PR #8（分支 `numeric/touhou-td-framework`）的同名路径。本 PR 不附带它，要在 #8 之后合并。系数、每波预算、全关合计和首通剩余生命一律以那份文件为准，这里不抄数字。

关卡校验在文件存在时，按下面这些字段核对画完的关。文件不存在时只警告并跳过。

| 字段 | 含义 |
| --- | --- |
| `levels.<level_id>.threat_budget_coef` | 这一关的威胁系数 |
| `levels.<level_id>.wave_threat_budgets` | 每一波的威胁预算 |
| `levels.<level_id>.threat_budget_total` | 全关威胁合计 |
| `levels.<level_id>.target_lives_first_clear` | 首通剩余生命。不参与星级 |

旧字段名不要再使用。首通目标只认 `target_lives_first_clear`。

## 剧情事件 `scripted_events`

可选。MVP 里只有 `ch1_03` 有一项。schema 要求写明触发波、触发条件、目标、效果，以及是否造成伤害。

| 字段 | 含义 |
| --- | --- |
| `id` | 例如 `evt_yukari_gap_demo` |
| `once` | 必须是 true。只演一次 |
| `wave_id` | 触发波。隙间换位是 `w06` |
| `trigger` | 触发条件。第 6 波左路第一只硬残影出场，大约在波内第 10 秒 |
| `target` | 作用对象。这一只硬残影 |
| `effect` | 隙间打开，把它送回本路起点的裂隙 |
| `deals_damage` | 这一下是否造成伤害。隙间换位是 false |
| `threat_unchanged` | 为 true 时威胁点不变 |
| `dialogue_key` | 台词 key。`dlg.ch1_03.yukari_gap_demo` |
| `dialogue_status` | 固定 `pending_文案策划` |

紫的可放置规则不变：从 `ch2_01` 起首通才能放，重打已通关的关卡也可以放。这段事件不是让玩家放置紫。

## 首领 `bosses`

一项首领：

| 字段 | 含义 |
| --- | --- |
| `id` | `boss_cirno` 这种战斗侧 id |
| `display_name` | 给人看的名字 |
| `character_id` | 例如 `chr_cirno` |
| `blocks_character_id` | 决斗期间不能放置的角色。不能出现在可放置名单里。冰之残影不锁琪露诺，写 `null` |
| `enters_at_wave_id` | 从哪一波走进来，例如 `w05` |
| `enter_wave` | 同一个入场波的整数。冰之残影现在是 5。制作人拍板后改这一个数，并让波次 id、前奏和 `is_boss` 跟它一致 |
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

生命、护甲、击破灵力、漏怪扣命、击破充能和威胁点的权威来源是数值策划的 `data/balance/combat/stats.json`，字段是 `enemies` 和 `bosses`。图鉴用 `stat_source` 和 `threat_points_source` 指向这份表。这里只留 id、显示名、文本 key 和引用。校验如果看见 `hp`、`move_speed`、`threat_points` 或抄来的数字，会失败。

| 字段 | 含义 |
| --- | --- |
| `id` | `enm_` 或 `boss_` |
| `display_name` | 中文名。玩家看到的名字以文案术语表为准 |
| `display_name_key` | `enemy.<战斗ID>.name`，例如 `enemy.enm_shade_basic.name` |
| `introduced_in` | 第一次出现的关卡。还没有关用到时是 `null` |
| `threat_points_source` | 指向 `stats.json` 里这一只的 `threat_points`。不在图鉴里抄数字 |
| `name_status` | `decided` 或 `pending_文案策划` |
| `splits_into` | 可选。堆积体记下战斗草案：被打散时会裂开。裂出哪一种、裂出几只以战斗和数值表为准 |
| `note` | 中文 |

已定名：小残影、快残影、硬残影、飞行残影、冰之残影。暂名、状态 `pending_文案策划`：扑人残影、遗忘之影、堆积体、结界之渣、红魔的女仆残影、不死鸟的残影、风祝的残影、守门残影、落野忘。

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
| `lives_source` | 指向 `data/balance/combat/stats.json` 的 `guard.max_hp`。满生命以这一字段为准，这里不抄数字 |
| `stars_do_not_grant_power` | `true` |
| `stars_grant` | 现在写了 `cosmetics` 和 `codex_stories`。具体外观和图鉴句子还没做 |
| `hard_mode` | `later`。这次没有困难倍率 |
| `win`、`lose` | 最后一波结束还有命即胜，命耗尽即败。首领关相同 |
| `stars_source` | 指向 `stars.thresholds_lives_left`。`order` 依次是 3 星、2 星、1 星。按剩余生命的绝对值。阈值不在这里抄。首通目标不参与星级 |
| `first_clear_source` | 指向 PR #8 的 `levels.<level_id>.target_lives_first_clear`。不在这里抄每关该剩多少命 |
| `replay` | 已通关的关可以重打，并能补星。局外奖励以 PR #8 的难度表为准 |
| `leak.stored_in_level_data` | `false`。扣几条命不写在关卡里 |
| `leak.note` | 指向 `data/balance/combat/stats.json` 的 `enemies` 和 `bosses` |

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

它会检查：JSON 能解析，符合 schema，地图是 7×12，路径连续，入口是 `S`、守护点是 `G`，每一个 `.` 都是预定槽位并且贴着路线，地形和冰之残影的三组格子符合战斗约定，第 1 波 `delay_sec` 是 0、其余波是 4，非序章每关 1 到 3 次三选一且最后一波不弹，可放置名单跟着 `unlock_character_ids` 走，每一关只有一个主教学点。系数、预算、首通目标、星级阈值、血量和威胁点不写死在校验里：`level_difficulty.json` 或 `stats.json` 在的时候才读它们核对；不在的时候只警告并跳过。图鉴和星级文件里不能再出现这些数字。

Godot 测试 `tests/unit/test_level_data.gd` 再查一遍地图、路径、威胁和星级，不查 schema 文本。CI 的 lint 跑 Python 校验，test 跑 Godot 测试。
