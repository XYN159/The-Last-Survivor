# 敌人与 Boss

> 状态：草案（战斗策划）。残影种类和外观意象来自 PR #2（`story_outline.md`「残影种类」）。玩家看见的名字和文本 key 以 PR #2 术语表「敌人名」和 `data/text/names_zh.csv` 为准：key 是 `enemy.<战斗 id 去掉 enm_>.name`，Boss 用完整战斗 id（`enemy.boss_cirno.name`）。
> 数值（血量、移速、护甲、灵力掉落、漏怪伤害、威胁值、击杀充能、被挡时的每秒伤害、首次出现关卡）只在数值策划 PR #8 的 `stats.json` 里：普通敌人是 `enemies.<id>.*`，Boss 是 `bosses.<id>.*`。本文件和 `enemies.json`、`bosses.json` 只写行为，不抄数字。

## 1. 敌人一览

字段名都在 `stats.json` → `enemies.<id>` 下：`hp`、`move_speed_cells_per_sec`、`armor`、`spirit_drop`、`leak_damage`、`threat_points`、`kill_charge`、`block_dps`、`first_level_id`、`value_status`。

| ID | 显示名（PR #2 key） | 叙事对应（PR #2） | 行为特点 | 标签 | MVP |
| --- | --- | --- | --- | --- | --- |
| `enm_shade_basic` | 小残影（`enemy.shade_basic.name`） | 通用，褪色杂物 | 沿路线走，不攻击 | shade | 是 |
| `enm_shade_fast` | 快残影（`enemy.shade_fast.name`） | 褪色玩具 | 成群，走路时左右轻微晃动（纯视觉） | shade, outside_object, fast | 是 |
| `enm_shade_armored` | 硬残影（`enemy.shade_armored.name`） | 旧电器 | 护甲高，被打时冒火花并飘「护甲」【框架】；击退减半 | shade, outside_object, armored | 是，只在 `ch1_03` 出现（制作人 2026-09-27 定，见第 7 节） |
| `enm_shade_heavy` | 待文案起名（`enemy.shade_heavy.name`，PR #2 还没有） | 旧电器（大型） | PR #8 新增的暂定兵种：比硬残影更硬 | shade, outside_object, armored | 预留 |
| `enm_shade_swarm` | 待文案起名（`enemy.shade_swarm.name`，PR #2 还没有） | 褪色玩具（成群） | PR #8 新增的暂定兵种：一次出一大群 | shade, outside_object, swarm | 预留 |
| `enm_shade_pouncer` | 扑人残影（`enemy.shade_pouncer.name`，PR #2 暂定） | 第三章，会攻击村民 | 【推荐】扑向最近的已放置角色，让它短暂停止行动（`st_unit_pounced`），然后继续走 | shade, pouncer | 否（`post_mvp`） |
| `enm_shade_flying` | 飞行残影（`enemy.shade_flying.name`） | 第四章 | 【推荐】飞在路线上空，无视阻挡，美铃也挡不住；仍沿路线走、仍能被打 | shade, flying | 否（`post_mvp`） |
| `enm_shade_phantom` | 遗忘残影（`enemy.shade_phantom.name`，PR #2 暂定） | 原暂名遗忘之影 | 隐形，被反隐（文）照到后才能被选为目标 | shade, stealth | 预留 |
| `enm_shade_heap` | 堆积残影（`enemy.shade_heap.name`，PR #2 暂定） | 原暂名堆积体 | 精英，死亡时分裂出 3 个快残影 | shade, elite | 预留 |
| `enm_shade_rift` | 结界残影（`enemy.shade_rift.name`，PR #2 暂定） | 原名结界之渣 | 第五章起，周围 1 格的可放置格褪色（`ter_faded`） | shade, elite, rift | 预留 |

- 所有残影**不主动攻击角色**（PR #2 设定：角色存在感太强不会褪色）。例外：被美铃挡住（`st_blocked`）时，被挡的残影打美铃，每秒伤害是 `enemies.<id>.block_dps`；扑人残影（第三章，推荐行为）会扑向角色让她短暂停手。扑人残影和飞行残影只写了推荐行为，本 PR 不写数字（触发距离、停手秒数等等数值策划在 PR #8 补）。
- 标签 `outside_object` 对应 PR #2「外界之物」（褪色玩具、旧电器），早苗对它们有特攻。
- 显示名用 PR #2 `names_zh.csv` 已有的 key（上表）。`enm_shade_heavy`、`enm_shade_swarm` 是 PR #8 新加的暂定兵种，文案还没起名。

## 2. 敌人状态机【战斗策划决定 4】

| 状态 | 进入 | 行为 | 退出 |
| --- | --- | --- | --- |
| `spawn` 出生 | 在裂缝格生成 | 播出生动画 0.3 秒；不移动、不能被选为目标 | 0.3 秒后 → `walk` |
| `walk` 行走 | 出生结束，或控制结束 | 按 core_rules 3.2 节移动 | 被硬停止状态控制 → `controlled`；走到终点 → `reaching`；血量归零 → `dead` |
| `controlled` 被控制 | 身上有 `st_freeze` / `st_hold` / `st_time_stop` / `st_gap_daze` | 速度 0；能被攻击；减速等状态照常计时 | 所有硬停止状态结束 → `walk`；血量归零 → `dead` |
| `blocked` 被挡住 | 走进美铃相邻的路线格，美铃还有空位（最多 `characters.chr_meiling.block_count` 个） | 停下，打美铃（`enemies.<id>.block_dps`）；能被攻击 | 美铃倒下或被卖掉 → `walk`；被击退离开那一格 → `walk`；血量归零 → `dead` |
| `reaching` 到达中 | 第 ⑤ 步走到 `path_length` | 本 tick 仍可被攻击 | 第 ⑩ 步：还活着 → `leaked`（扣守护点血，移除）；被击退回路线上 → `walk`；死亡 → `dead` |
| `dead` 死亡 | 第 ⑧ 步血量归零 | 第 ⑨ 步结算灵力、连击、充能；播放碎成光点飞向灵力栏的演出 | 移除 |
| `leaked` 漏怪 | 第 ⑩ 步 | 守护点扣血；播放残影扑进守护点、守护点褪色一下的演出 | 移除 |

## 3. 硬残影的「护甲」提示

1. 每次命中在流水线第 3 步记下「被护甲削掉的比例」 `r = (攻击 − 护甲后伤害) / 攻击`。
2. 如果敌人 `armor_feedback = true` 且 `r ≥ 0.5`，发出「护甲」反馈：命中点冒金属火花，头顶飘灰色「护甲」二字（文本 key `combat.armor`），配金属「叮」声。
3. 同一个敌人 0.5 秒内只提示一次（`rules.json` → `damage.armor_feedback_throttle_sec`）。
4. 目的：告诉玩家「这里要用高攻击的角色（魔理沙、符卡）打」。

## 4. 快残影给关卡策划的说明

- 移速和血量见 `stats.json` → `enemies.enm_shade_fast.move_speed_cells_per_sec`、`enemies.enm_shade_fast.hp`。它比小残影快一倍左右，血量相近。
- 适合成群出（建议每组 5–8 只，出怪间隔 0.3–0.5 秒），让魔理沙的穿透和灵梦的结界有发挥空间。
- 在冰面上再乘 `terrain.ter_ice.move_speed_mult`，很危险。冰之残影三阶段把路冻住时，混进快残影能制造高潮。
- 减速对它同样有效，下限也是 30%。

## 5. Boss 通用规则

1. **血条**：屏幕顶部，显示名字（PR #2 `enemy.boss_cirno.name`「冰之残影」）和阶段分隔点（`stats.json` → `boss_rules.phase_hp_ratios`）。掉血时血条延迟 0.3 秒滑落。
2. **阶段**：按血量切，冰之残影是 100% / 66% / 33% 三段【战斗策划决定 4】。阈值读 `boss_rules.phase_hp_ratios`（PR #8），关卡里的 `phases[].hp_ratio_start` 要和它一致（PR #5 `ch1_04.json` 已是三段按血量，不是按波次）。
3. **切阶段流程**（血量跌破下一个阈值时）：
   1. 血量**卡在阈值**上（超出的伤害作废），防止一口气打穿两个阶段。
   2. 进入逻辑暂停，播放 Boss 立绘演出（从右侧滑入，显示符卡名），规则和玩家符卡相同：首次 1.2 秒，同一关里同一张之后 0.6 秒，可点击跳过。
   3. 演出结束时释放该阶段的符卡（第一次施放）。
   4. 同时给 Boss 挂 `st_invulnerable`，时长 `boss_rules.phase_invuln_sec`（逻辑时间），期间 Boss 站定不走（宣言姿势），伤害为 0。
   5. 上一阶段留下的地形效果全部清除（冰柱碎掉，播放碎裂特效）。
4. **开场**：Boss 出生时就是第一阶段，出生演出后直接释放第一阶段符卡（也有立绘）。
5. **每阶段施放一次**（2026-10-02 改，对齐 PR #8 的模拟）：每张符卡只在进入该阶段时施放一次（`casts_per_phase` = 1，`repeat_interval_sec` = 0），阶段内不再重复。字段保留，以后的 Boss 想重复施放时再填。
6. **控制**：Boss 免疫冻结、拦截、时停（都改成减速），免疫隙间换位和送回，**不能被美铃挡住**，不被击退；受地形影响（冰面上也会加速）。移动总倍率下限 0.5。
7. **走到守护点**（已拍板，2026-09-27）：扣守护点 `stats.json` → `bosses.boss_cirno.leak_damage`（回应 DI-07：Boss 在 PR #8 的 `bosses` 段，不在 `enemies` 段；PR #5 的 `lives_source` 也指向这里），然后回到裂缝重新走（`on_reach_guard: loop_to_spawn`，和 PR #8 `boss_rules.on_reach_guard = leak_then_loop`、PR #5 `deduct_lives_and_return_to_rift` 是同一条规则），保持当前血量和阶段。Boss 不因漏怪离场。Boss 关的最后一波要等 Boss 被击败才算打完（`victory: must_defeat`）。输了可以从当前波重来或整关重打，见 core_rules.md 第 5.2 节。
8. **击败**：最后一段血打空 → 大型碎冰特效，自动触发一次慢动作（不受冷却限制），然后场上剩余残影继续清理，全部离场后胜利。
9. **伴随刷怪**：由关卡数据的 Boss 波定义（关卡策划负责），战斗在每个阶段开始时发出事件 `on_boss_phase_start(boss_id, phase_index)`，关卡脚本可以挂额外刷怪。

## 6. 冰之残影 `boss_cirno`（琪露诺的复制体）

第一章 Boss 不是可放置的琪露诺本人，而是她的复制体「冰之残影」。ID 沿用 `boss_cirno`，不改。`identity` = `cirno_copy`，`copy_of` = `chr_cirno`。数值在 `stats.json` → `bosses.boss_cirno`（`hp`、`move_speed_cells_per_sec`（用户已确认 0.4）、`armor`、`spirit_drop`、`leak_damage`……）。显示名用 PR #2 的 `enemy.boss_cirno.name`。

以后各章 Boss 的预留 ID（和 PR #5、PR #8 一致，回应 DI-10）：`boss_ch2_sakuya_shade`、`boss_ch3_mokou_shade`、`boss_ch4_sanae_shade`、`boss_ch5_gatekeeper`、`boss_wasure`。只是预留名字，行为还没写，`bosses.json` 里也还没有条目。

叙事依据：PR #2 `ch1_04` 的台词，符卡 冰符「冰瀑」、冻符「完美冻结」，笑点是「完美冻结连残影一起冻住，你到底帮哪边」。框架要求 3 个阶段，所以补了第三张 雪符「钻石风暴」（原作琪露诺的冰符之一，原名 雪符「ダイアモンドブリザード」），PR #2 已加名字 key `spell.cirno.diamond_blizzard.name` 和宣言 `dlg.ch1_04.mid.008`。

| 阶段 | 血量区间 | 符卡 ID | 符卡名 | 改地图方式 | 重复 |
| --- | --- | --- | --- | --- | --- |
| 1 | 100%–66% | `sc_boss_cirno_icicle_fall` | 冰符「冰瀑」 | 冰柱落下：落在角色身上就冻住角色；落在空格上变成冰柱（`ter_icicle`），挡住直线攻击 12 秒（PR #5 `phase_1.duration_sec`） | 进入阶段时一次 |
| 2 | 66%–33% | `sc_boss_cirno_perfect_freeze` | 冻符「完美冻结」 | 以 Boss 为中心半径 2.5 格：范围内角色冻住，范围内残影也冻住（Boss 自己不受影响） | 进入阶段时一次 |
| 3 | 33%–0% | `sc_boss_cirno_diamond_blizzard` | 雪符「钻石风暴」 | Boss 前方 10 格路线变成冰面（`ter_ice`），敌人在上面移速 × `terrain.ter_ice.move_speed_mult`，持续到 Boss 被击败 | 不重复 |

冻结秒数（用户已确认，值在 PR #8）：冰瀑和完美冻结都读 `stats.json` → `terrain.ter_ice.stop_on_declare_sec`。这是 PR #8 现在唯一的「冰之残影冻结秒数」字段，名字是借用的，已请数值策划补一个专用字段（见 README 9.1）。冰柱 12 秒是关卡字段，`bosses.json` 里兜底也是 12。所以 `ch1_04` 一局里：冰瀑一次（最多冻 2 个角色）、完美冻结一次（范围内角色和残影），一共两次冻结，每次的秒数都是上面那个字段。

### 6.1 一阶段 冰符「冰瀑」

1. 目标格：优先用关卡数据里的格子集合 `boss_cirno_p1_icicles`；关卡没给就按兜底规则：离 Boss 最近的 2 个角色所在格 + 路线旁 3 个空的可放置格。
2. 目标格出现 0.8 秒的落点阴影（预警），玩家能看到。
3. 落下时：
   - 格上有角色 → 角色获得 `st_unit_frozen`（有 `st_unit_freeze_immune` 则无效），不生成冰柱。对应 PR #2 台词 `dlg.ch1_04.mid.001`（宣言）、`dlg.ch1_04.mid.002`「大家被冻住了」。
   - 格上没有角色 → 生成冰柱 `ter_icicle`，持续 12 秒（关卡 `phase_1.duration_sec`）：这格不能放角色，任何经过这格的直线攻击（魔理沙射线、琪露诺冰片、早苗星弹等）在这里截断。追踪弹、隙间、近战不受影响。
4. 冰柱会被「极限火花」这类光束符卡直接打碎（`destroyed_by_spell_tags: ["beam"]`），爽感来源之一。
5. 切到二阶段时所有冰柱碎掉。

### 6.2 二阶段 冻符「完美冻结」

1. 以 Boss 当前位置为圆心、半径 2.5 格（关卡可用 `boss_cirno_p2_area` 指定格子集合代替圆形）。
2. 地面出现 1.0 秒的冰蓝色圆形预警。
3. 生效时：范围内角色 `st_unit_frozen`；范围内非 Boss 敌人 `st_freeze`（这张符卡无视冻结免疫）。秒数都读 `terrain.ter_ice.stop_on_declare_sec`。
4. 玩法意图：一部分角色停火，但被冻住的残影停在原地，范围外的魔理沙正好打「冰碎」。对应 PR #2 `dlg.ch1_04.mid.005`–`007`（「连残影都冻住了！」）。
5. 被冻的角色能不能连点提前破冰还在待拍板（DI-13，README 第 8 条）。冻结时间很短，不加连点也能接受。

### 6.3 三阶段 雪符「钻石风暴」

1. 冰面格：优先用 `boss_cirno_p3_ice`；没给就取 Boss 当前位置前方（朝守护点方向）的 10 个路线格。
2. 0.6 秒预警后，冰面在 1.0 秒内从 Boss 脚下向前蔓延（视觉），逻辑上在蔓延到某格时该格生效。
3. 冰面上所有敌人（包括 Boss）移速 × `terrain.ter_ice.move_speed_mult`，这个倍率和减速相乘（例：被减速强度 s 的残影在冰上是 (1 − s) × 冰面倍率）。
4. 持续到 Boss 被击败，然后冰面在 1 秒内融化。
5. 玩法意图：最后三分之一血是高潮，敌人突然变快，逼玩家用符卡。危急加速充能（守护点 ≤ 30% 或敌人进入最后 3 行时，充能乘 `spell_charge.crisis_charge_mult`）让玩家这时候刚好能放符卡。

### 6.4 给文案的对接

- 符卡名用 PR #2 `names_zh.csv` 已有的 `spell.cirno.icicle_fall.name`、`spell.cirno.perfect_freeze.name`；第三张 `spell.cirno.diamond_blizzard.name`（雪符「钻石风暴」）PR #2 已加。Boss 名用 `enemy.boss_cirno.name`（冰之残影，替换旧草案的 `boss.ice_shade.name`）。
- PR #2 `ch1_04` 的台词按「宣言第 1 / 第 2 张符卡」触发（`dlg.ch1_04.mid.001`、`dlg.ch1_04.mid.005`），第 3 张的宣言和反应 PR #2 已补：`dlg.ch1_04.mid.008`–`009`。
- 教学提示 `tut.ch1_04.001`「击破它的每一张符卡就能过关」与 3 阶段一致。

## 7. 硬残影在 MVP 里（制作人 2026-09-27 23:53 定）

- 只在 `ch1_03` 出现，一共 8 只：第 6 到 11 波每波 1 只，第 12 波 2 只，每只大约在这一波开始后 10 秒出生（PR #5 `ch1_03.json`，PR #8 `enemies.enm_shade_armored.first_level_id` = `ch1_03`）。
- 第 6 波那只是紫的隙间演示目标（characters.md 2.2）：走到路线一半时被隙间送回裂缝，不受伤害，只演示一次。
- `enemies.json` 里它的 `status` = `mvp`，`mvp_levels` = `["ch1_03"]`。
- 它让玩家第一次看到「护甲」提示，知道要用攻击高的角色（魔理沙）或冰碎去打。多发攻击按「总伤害不变」拆分，护甲也按发数拆，所以升级成多发不会打它更疼也不会更弱。
