# 《东方守幻录》战斗规则文档（草案）

> 东方 Project 二次创作。原作权利归上海爱丽丝幻乐团 / ZUN。
> 维护者：战斗策划。状态：**草案**。写于 2026-09-27，2026-10-02 按执行制作人的意见改过一轮（见第 10 节）。已拍板的条目见「已拍板」一节；其余问题仍待拍板。
> 依据：制作人已验收的战斗框架；PR #2（文案，分支 `docs/touhou-narrative-draft`）的角色名单、残影设定、符卡名、文本 key 和术语表；数值策划 PR #8（分支 `numeric/touhou-td-framework`）的 `stats.json`。
> **数值以 PR #8 为唯一来源。** 本目录只写规则、公式和字段含义，引用 PR #8 的字段名（如 `stats.json` → `enemies.<id>.hp`、`bosses.boss_cirno.leak_damage`），不抄数字。本 PR 不再带 `data/balance/combat/stats.json`。**合并顺序：先合 PR #8，再合本 PR**，本 PR 引用 PR #8 的表。
> 本目录里的战斗 ID 在这里第一次定义。别人以后要改 ID，请先和战斗策划对齐。关卡波数需要举例时，引用关卡策划 PR #5，不在这里另编关卡号。

## 1. 一句话

单机竖屏角色塔防：7 列 × 12 行格子，残影从上方的裂缝沿固定路线走向下方的守护点；玩家只能把角色放在地图上标成 `.` 的预定槽位里，角色自动攻击；全队共用一条符卡能量（满值按当前符卡使读 PR #8 `characters.<id>.spell_energy_max`），满了放一张带立绘演出的符卡，自动释放是默认关闭的全局开关；每 5 波三选一 roguelite 强化，2 层质变，只管当局。每波刷怪窗口约 20 秒、空档 4 秒、不等清场，追求爽感和险胜。

## 2. 文件索引

| 文件 | 内容 |
| --- | --- |
| [core_rules.md](core_rules.md) | 格子和坐标、60Hz tick 和 12 步结算顺序、时间倍率实现、敌人移动公式、局内状态机、波次和叫波、守护点和胜负、单手操作 |
| [damage_and_status.md](damage_and_status.md) | 9 步伤害流水线、加成分类和倍率桶、状态表、冻结和结界规则、联动判定时机 |
| [characters.md](characters.md) | 13 名角色的战斗行为，MVP 角色详细规则，MVP 冻结来源，紫的隙间探头 |
| [enemies_and_bosses.md](enemies_and_bosses.md) | 残影种类、敌人状态机、护甲提示、Boss 通用规则、冰之残影三阶段 |
| [terrain_and_map.md](terrain_and_map.md) | 地形效果表、冰柱遮挡判定、关卡地图数据对接格式（给关卡策划） |
| [spell_cards.md](spell_cards.md) | 能量条、充能节奏、手动和自动释放、立绘演出、符卡使（方案 A+）、MVP 符卡详细效果 |
| [synergies.md](synergies.md) | 框架联动 2 条 + 新增联动 6 条 |
| [roguelite_buffs.md](roguelite_buffs.md) | 强化触发时机、叠层和质变结构、12 个强化 |
| [feedback.md](feedback.md) | 反馈事件表（含 MVP 批次）、伤害数字上限与合并、连击、慢动作、立绘演出细节 |
| [data_reference.md](data_reference.md) | 所有配置表的字段说明（字段、类型、单位、含义、归属） |

配置表（`data/balance/combat/`）：`rules.json`、`characters.json`、`enemies.json`、`bosses.json`、`statuses.json`、`terrain.json`、`spell_cards.json`、`synergies.json`、`buffs.json`、`feel.json`，都已用 `python -m json.tool` 校验。它们只放行为和手感参数，数值用 `*_stats_key` 指向 PR #8 的 `stats.json`（同一目录，由 PR #8 生成）。字段对照见 data_reference.md。

### 为什么放在 `data/balance/combat/` 而不是 `data/combat/`

仓库 `AGENTS.md` 和 `.cursor/rules/project-workflow.mdc` 规定「数值放进 `data/balance/`」，`docs/CODING_STYLE.md` 也说「会调平衡的数字放进 `data/balance/`」。战斗的手感参数也属于要调的数字，所以跟随仓库约定放在 `data/balance/combat/`。`export_presets.cfg` 的 `include_filter="data/*"` 能匹配子目录（Godot 的 `*` 通配符可以跨 `/`，现有的 `data/balance/starting_balance.json` 本身就在子目录里并且能打包），不用改导出设置；程序接入后仍建议导出一次 APK 确认新 JSON 被打进包里。

## 3. 标记说明

| 标记 | 含义 |
| --- | --- |
| 【框架】 | 制作人已验收，照做 |
| 【战斗策划决定 N】 | 战斗策划的设计决定（默认按此实现） |
| 【草案默认值】 | 战斗策划给的默认值，可调 |
| 【数值·PR #8】 | 数值策划的字段，本目录只写字段名，数字以 PR #8 为准 |
| 草案 | 新设计内容，待制作人确认 |

## 4. 术语表

| 术语 | 含义 |
| --- | --- |
| 格 | 距离和速度的单位，一个格子的边长 |
| 路程 / 离守护点的路程 | 敌人沿路线还要走多少格才到守护点 |
| tick | 一次逻辑更新，固定 1/60 秒 |
| 命中请求 | 一次「谁打谁」的伤害请求 |
| 攻击加成分类 | `buff`（强化）、`aura`（光环）、`temp`（临时）；同类相加、异类相乘 |
| 易伤桶 / 联动桶 | 伤害倍率的两个桶，桶内相加、桶间相乘 |
| 重击 | 暴击，或标记为 heavy 的命中；飘黄色大字、震屏 |
| 硬停止 | 让敌人速度归零的状态：冻结、拦截、时停、隙间晕眩（美铃的阻挡 `st_blocked` 单独算） |
| 符卡使 | 开局前选定的一名角色。底部符卡按钮放她的默认符卡，能量满值也按她读。布阵期和波次空档可以换，刷怪窗口里不能换；换人清空能量 |
| 危急 | 有敌人进入最后 3 行，或守护点生命 ≤ 30%；符卡充能乘 `spell_charge.crisis_charge_mult` |
| 报警区 | 最后 2 行，有敌人时守护点闪红 |
| 地形效果 | 叠在格子上的效果（冰面、冰柱、浓雾、结界……） |
| 灵力 | 放置和升级用的局内资源。PR #2 术语表已定名「灵力」（文本 key `currency.reiryoku`）。字段名仍用 `spirit` |
| 角色 / 塔 | 玩家可见文本说「角色」，策划和代码可以说「塔」（PR #2 术语表） |
| 残影名 | 玩家可见名一律「某某残影」，以 PR #2 术语表为准：小残影、快残影、硬残影、扑人残影、飞行残影、遗忘残影、堆积残影、结界残影、冰之残影。文本 key `enemy.<战斗 id 去掉 enm_>.name`，Boss 用完整 ID（`enemy.boss_cirno.name`） |

## 5. 最终 ID 清单（关卡策划可以直接引用）

### 角色（`chr_` + PR #2 文本 key 的角色 id）

`chr_reimu` 灵梦、`chr_marisa` 魔理沙、`chr_cirno` 琪露诺、`chr_daiyousei` 大妖精（可玩待定）、`chr_meiling` 美铃、`chr_sakuya` 咲夜、`chr_remilia` 蕾米莉亚（可玩待定）、`chr_keine` 慧音、`chr_mokou` 妹红、`chr_aya` 文（可玩待定）、`chr_sanae` 早苗、`chr_yukari` 紫、`chr_wasure` 忘。

### 敌人

MVP：`enm_shade_basic`（小残影）、`enm_shade_fast`（快残影）、`enm_shade_armored`（硬残影，只在 `ch1_03` 出现，一共 8 只），外加 Boss `boss_cirno`（冰之残影，琪露诺的复制体）。
MVP 之后（`post_mvp`，只写了推荐行为，没有数字）：`enm_shade_pouncer`（扑人残影，第三章：扑向最近的已放置角色，让她短暂停手）、`enm_shade_flying`（飞行残影，第四章：无视阻挡，美铃也挡不住）。
预留：`enm_shade_phantom`（遗忘残影）、`enm_shade_heap`（堆积残影）、`enm_shade_rift`（结界残影），以及 PR #8 新加的暂定兵种 `enm_shade_heavy`、`enm_shade_swarm`。

### Boss

`boss_cirno`（冰之残影）。以后的预留 ID 和 PR #5、PR #8 一致（DI-10）：`boss_ch2_sakuya_shade`、`boss_ch3_mokou_shade`、`boss_ch4_sanae_shade`、`boss_ch5_gatekeeper`、`boss_wasure`。只预留命名，行为未定义。数值在 PR #8 `stats.json` 的 `bosses` 段。

### 状态

MVP：`st_slow`、`st_freeze`、`st_freeze_immune`、`st_barrier_mark`、`st_ofuda_tag`、`st_invulnerable`、`st_unit_frozen`、`st_unit_freeze_immune`。
后续：`st_burn`、`st_hold`、`st_hold_immune`、`st_blocked`（美铃阻挡）、`st_time_stop`、`st_gap_daze`、`st_registered`、`st_unit_pounced`（扑人残影）。

### 地形

MVP：`ter_ice`（冰面）、`ter_icicle`（冰柱）、`ter_fog`（浓雾）、`ter_barrier`（灵梦结界）。
后续：`ter_burning`（火焰地面）、`ter_faded`（褪色格）。

### 符卡

玩家（`sc_` + PR #2 符卡 id）：`sc_fantasy_seal`、`sc_evil_sealing_circle`、`sc_master_spark`、`sc_stardust_reverie`、`sc_perfect_freeze`、`sc_icicle_fall`、`sc_morning_mist`、`sc_rainbow_dance`、`sc_extreme_typhoon`、`sc_the_world`、`sc_killing_doll`、`sc_gungnir`、`sc_red_magic`、`sc_modoribashi`、`sc_legend_of_gensokyo`、`sc_phoenix_wings`、`sc_phoenix_rebirth`、`sc_gensou_fuubi`、`sc_autumn_leaf_fan`、`sc_gray_thaumaturgy`、`sc_yasaka_divine_wind`、`sc_spiriting_away`、`sc_quadruple_barrier`、`sc_lost_and_found`、`sc_forgotten_song`。
Boss：`sc_boss_cirno_icicle_fall`（冰符「冰瀑」）、`sc_boss_cirno_perfect_freeze`（冻符「完美冻结」）、`sc_boss_cirno_diamond_blizzard`（雪符「钻石风暴」，新增）。

### 其他

技能 `skl_<角色>_<名>`；联动 `syn_<名>`（见 synergies.md）；强化 `buff_<名>`（见 roguelite_buffs.md）；召唤物 `hlp_<名>`（目前只有 `hlp_lost_item`）；关卡里 Boss 用的格子集合名 `boss_cirno_p1_icicles`、`boss_cirno_p2_area`、`boss_cirno_p3_ice`。

## 6. 与仓库现状的冲突和缺口

| # | 问题 | 处理 |
| --- | --- | --- |
| 1 | `docs/GDD.md` 仍是旧的车道/小队/基地玩法，并写着「明确先不做：复杂剧情和过场」 | 本目录不改它。需要系统策划/制作人按新定位更新 GDD；在那之前，战斗相关以本目录为准 |
| 2 | 任务要求的 `data/combat/` 与仓库「数值放 `data/balance/`」的规定不一致 | 采用 `data/balance/combat/`（见第 2 节） |
| 3 | MVP（序章 + 第一章）玩家开局只有灵梦和魔理沙，冰碎仍要能触发 | 已拍板：第一章第 2 关起有琪露诺本人，冰碎可以自然触发；另外还有寒气和冰之残影二阶段。见「已拍板」 |
| 4 | 紫第五章才可玩，MVP 里碰不到 | 已拍板：`ch1_03` 第 6 波用隙间演示一次；`ch1_04` 打完后紫正式加入，从 `ch2_01` 起可放，MVP 里重打已通关卡使用 |
| 5 | MVP 只有两名角色，如果每个角色只能放一个，棋盘上最多两个塔，爽感不足 | 已拍板（2026-09-27）：同一角色最多放 3 个，费用递增 |
| 6 | PR #2 琪露诺只有两张符卡，框架要求 Boss 2–3 个阶段并以 3 阶段为默认 | 补 雪符「钻石风暴」。PR #2 已加 key `spell.cirno.diamond_blizzard.name` 和宣言 `dlg.ch1_04.mid.008`–`009`。三阶段本身仍在待拍板第 6 条 |
| 7 | PR #2 教学 `tut.prologue_01.004` 原先写「拖动灵梦的头像」 | PR #2 已改成「先点发光的格子，再点灵梦的头像」，和 core_rules 6.1 一致。操作本身见待拍板第 26 条 |
| 8 | PR #2 教学 `tut.prologue_01.008` 现在写「符卡充能完毕！先点格子，再点灵梦的头像」，和「符卡按钮在底部」仍不一致 | 请文案改成「符卡充能完毕！点下方的符卡按钮」。魔理沙 `prologue_01` 打完才加入，`prologue_02` 布阵期可以设她为符卡使，`dlg.prologue_02.mid.002` 能成立 |
| 9 | 1080×1920 下 7 列铺满宽度时 12 行几乎占满高度，底部按钮放不下 | 草案每格 128 像素（core_rules 1.3），待真机确认 |
| 10 | 连击「×N」的 `×` 可能不在字体子集里 | 程序确认，必要时扩字体子集 |
| 11 | `docs/ARCHITECTURE.md` 的「数值配置」原先只登记了 `starting_balance.json` | 已补上 `data/balance/combat/` 的表；`stats.json` 那一行登记为 PR #8 生成。游戏代码仍未读取这些 JSON |
| 12 | PR #2 `dlg.prologue_01.mid.010`（灵梦首次发动符卡）喊的是 灵符「梦想封印」 | 灵梦默认符卡已改成 梦符「封魔阵」（用户已确认），请文案改这句 |
| 13 | PR #8 `characters.csv` 把封魔阵写成 灵符「封魔阵」，PR #2 是 梦符「封魔阵」 | 以 PR #2 为准，请数值策划改显示名 |

## 已拍板（2026-09-27 起）

制作人、系统策划和用户已拍板。下面按确定规则执行。数字一律在 PR #8。

| # | 原问题 | 结论 |
| --- | --- | --- |
| 1 | 符卡按钮放谁的符卡 | 方案 A+。布阵期和波次空档可以换符卡使，刷怪窗口里不能换。换人时能量清零，数值策划已确认为 true。能量满值按当前符卡使读 `characters.<id>.spell_energy_max`，不是固定 100 |
| 2 | 同一角色能不能放多个 | 最多 3 个，费用递增。每人上限和递增比例见 PR #8 `characters.<id>.max_copies`、`copy_cost_increase_ratio` |
| 3 | MVP 的冻结来源 | 三个：第一章第 2 关起的琪露诺本人（冰碎可以自然触发）、寒气强化、冰之残影二阶段。寒气的 2 层「青蛙冰雕」仍算寒气这一条 |
| 4 | 紫什么时候能放 | `ch1_03` 第 6 波，隙间把第一只硬残影送回裂缝，演示一次，不伤害（DI-14）。`ch1_04` 打完后正式加入（`unlock` = `chapter1_boss_clear`），从 `ch2_01` 起可放；MVP 里通过重打已通关的关卡使用（`mvp_use` = `replay_cleared_levels`），和 PR #5 一致。这一关的 Boss 是冰之残影，不是琪露诺本人 |
| 5 | Boss 走到守护点、以及输了怎么办 | 扣守护点生命（`bosses.boss_cirno.leak_damage`，DI-07），然后回裂缝重走。普通关打完最后一波且还有生命就赢，生命归零就输。Boss 关的最后一波要等 Boss 被击败才算打完。输了可以「从当前波重来」（快照内容见 core_rules 5.2，DI-05）或整关重打 |
| 12 | 强化质变、三选一、作用范围 | 质变门槛 2 层。每 5 波三选一（第 5、10、15 波刷完进入空档时），只管当局，过关清空，同一强化可以重复叠加。已拥有但还没质变的强化，下次三选一保底出现其中一个。最后一波之后不给，序章前两关没有三选一，第 3 关开始教。和 PR #8 `buff_offer` 一致 |
| 13 | 关卡节奏 | 每波刷怪窗口 20 秒，窗口结束再空固定 4 秒。序章教学可以少于 5 波，其余关卡 10 到 20 波，MVP 多用 10 到 12 波。计时见 core_rules 4.2（D-03 已定） |
| 14 | MVP 敌人 | 小残影、快残影、硬残影，外加 Boss 冰之残影（`boss_cirno`）。硬残影只在 `ch1_03` 出现，一共 8 只：第 6 到 11 波每波 1 只，第 12 波 2 只，每只约在这一波开始后 10 秒出生（制作人 2026-09-27 23:53 定，PR #5、PR #8 已一致） |
| 15 | 放置、路线、自动释放 | 角色只能放在地图里的 `.` 格。路线标成 `P`，字母表跟随关卡策划 PR #5。一关可以有多条固定路线，战斗中路线不动（DI-11）。符卡自动释放是全局开关，默认关闭，局内可以切换 |
| 16 | 琪露诺什么时候能放 | 2026-09-27 已定：第一章第 1 关 `ch1_01` 打完后加入（`unlock` = `ch1_01_clear`）。从第一章第 2 关起可以放置 |
| 17 | 数值归属（执行制作人，2026-10-02） | PR #8 是数值唯一来源。本 PR 删掉自己的 `stats.json`，规则文档只写字段名。先合 PR #8，再合本 PR |
| 18 | 灵梦默认符卡（用户确认） | 梦符「封魔阵」：以灵梦为中心减速，不造成伤害（`spell_cards.sc_evil_sealing_circle.*`）。`sc_evil_sealing_circle` 是 MVP，梦想封印 `sc_fantasy_seal` 改为 MVP 之后 |
| 19 | 冻结和冰之残影（用户确认） | 冻结时长、冰之残影移速都归 PR #8：完美冻结 `spell_cards.sc_perfect_freeze.freeze_sec`，冰之残影的冻结 `terrain.ter_ice.stop_on_declare_sec`，移速 `bosses.boss_cirno.move_speed_cells_per_sec`。冰柱存在时间是关卡字段（`ch1_04` 第 1 阶段 12 秒）。三张 Boss 符卡各在进入阶段时放一次。本目录不再写冻结秒数 |
| 20 | 冰面倍率 | `terrain.ter_ice.move_speed_mult`（PR #8，和 PR #5 一致） |
| 21 | 美铃（用户确认） | 阻挡型，同时挡 `characters.chr_meiling.block_count` 个敌人（2 个）。原来的「拦截 + 击退」取消。被挡的敌人停下来打她（`enemies.<id>.block_dps`），她倒下就放开。Boss 和飞行残影挡不住 |
| 22 | 魔理沙什么时候加入 | 序章第 1 关 `prologue_01` 打完后加入，从 `prologue_02` 起可放（和 PR #2、PR #5、PR #8 一致）。旧稿「序章第 3 波前加入」作废 |
| 23 | 敌人名和文本 key | 以 PR #2 术语表为准：普通残影改叫小残影；遗忘之影、堆积体、结界之渣改叫遗忘残影、堆积残影、结界残影；key 用 `enemy.shade_basic.name` 这种，Boss 用 `enemy.boss_cirno.name`（替换 `boss.ice_shade.name`） |

战斗策划这次补的规则（回应 PR #8 和 PR #9，没有改已拍板的东西）：

- **多发总伤害不变**：2、3 级多发、咲夜飞刀，一次攻击的总伤害不变，攻击和护甲都按发数平分，暴击每发各掷（damage_and_status.md 2.2，`rules.json` → `damage.multi_shot_split`）。写明「每颗」系数的符卡和「分裂弹」的小子弹不拆分。
- **浓雾**：目标在雾里时射程减 `terrain.ter_fog.range_minus_cells`，最少 `min_range_cells`。PR #5 和 PR #8 现在都是这一版（PR #5 早先的「射程乘倍率」已改掉），不再有冲突。
- **Boss 阶段**：按血量 100% / 66% / 33% 切三段（`boss_rules.phase_hp_ratios`）。PR #5 的 `ch1_04.json` 也是三段按血量；它的「波次交替加压」只控制伴随刷怪，不切符卡。不再有冲突。
- **重来快照**（DI-05）：内容见 core_rules.md 5.2。
- **扑人残影、飞行残影**：只写推荐行为，没有数字，状态 `post_mvp`。

## 7. 需要制作人拍板的问题

已经定了的：原第 5 条（强化只管当局）见已拍板第 12 条；原第 10 条（局内资源名）PR #2 已定为「灵力」；第 16 条见已拍板。下面还开着的编号沿用旧清单，新加的从 24 起。

| # | 问题 | 选项 | 推荐 |
| --- | --- | --- | --- |
| 6 | 冰之残影第三阶段用 雪符「钻石风暴」（冰面加速），也就是三阶段（DI-13） | 认可 / 改成别的符卡 / 只做两阶段 | **认可**：原作琪露诺的冰符，冰面加速正好是框架例子。数据、PR #5 关卡、PR #2 台词都已按三阶段写；不认可就要一起改 `bosses.json`、`ch1_04.json` 和台词 |
| 8 | 被 Boss 冻住的角色能不能连点提前破冰（DI-13） | 能（数据先写 3 下）/ 不能 | **不能也行**：冻结时间现在很短（用户已确认的秒数在 PR #8），连点意义不大；如果想给单手玩家一个小互动就保留。数据里 `tap_to_break_status` 标着待拍板 |
| 9 | 新增 6 条联动、12 个强化，以及 PR #8 另提的 5 个强化（`buff_boss_slayer`、`buff_armor_break`、`buff_offering_box`、`buff_upgrade_discount`、`buff_spell_power`）是否认可 | 逐条确认 | 先认可 MVP 能用到的：符札引爆、寒气、分裂弹、会心、锐利、连射、充能。PR #8 那 5 个等认可后，战斗策划再补行为 |
| 11 | 大妖精、蕾米莉亚、文是否可玩（PR #2 已提出）；文对快敌人的加成（`chr_aya.bonus_vs_speed`，PR #8 `syn_aya_vs_fast`） | — | 战斗行为都已备好草案，任一结果都能接 |
| 24 | 波次时间轴（DI-03、DI-04） | A：推荐版（下面）/ B：制作人原话版，布阵 10 秒后再等 4 秒才出第一只 | **A**。布阵倒计时 10 秒，可以点「开始」提前结束；倒计时结束马上出第一只（`waves[0].delay_sec` = 0）；每波刷怪窗口约 20 秒（第一只到最后一只出生）；最后一只出生后进入唯一的空档状态 `intermission`，固定 4 秒，清场不缩短，走到 0 就出下一波，不等清场；刷怪窗口里也能叫波，跳过剩下的窗口和空档，但这一波没出生的敌人不丢，按原时间表出生、和下一波叠在一起（叫波是冒险换灵力，不能跳过敌人）；空档里叫波跳过剩下的空档；序章 `deploy_wait_for_player` 让倒计时停在 10 秒，等玩家放下第一个角色。理由：布阵就是准备时间，再空等 4 秒没有意义。关卡策划在 PR #5 按 A 改，PR #8 `waves` 也是这个口径。详见 core_rules.md 4.2 |
| 25 | 美铃放在哪 | A：放在紧贴路线的 `.` 格，挡相邻路线格（`placement` = `placeable_adjacent_to_path`）/ B：直接放在路线格上（PR #8 `characters.csv` 的写法） | **A**：不破坏已拍板第 15 条「只能放 `.`」，PR #5 的槽位设计不用改。选 B 就要给路线格开放置，并改关卡校验 |
| 26 | 放置手势和符卡按钮（DI-12） | A：先点发光的格子，再点头像；符卡用底部按钮 / B：拖头像 | **A**：单手好按，PR #2 的 `tut.prologue_01.004` 已经按 A 改了。定了以后文案改 `tut.prologue_01.008`，美术划掉待确认第 9、10 条 |

另外两件事不需要拍板，只是告诉制作人：

- 紫的隙间演示（DI-14）：制作人原稿写 `ch1_02` 第 6 波。因为硬残影只在 `ch1_03` 出现，战斗策划和关卡策划改成 `ch1_03` 第 6 波。
- 首领关入场波和 Boss 血量乘不乘关卡倍率（DI-06）归关卡策划和数值策划，战斗规则不受影响（Boss 什么时候出场都按同一套阶段和折返规则）。

## 8. 新增联动和强化速览

联动（草案，加成数字见 PR #8 `synergies.<id>.synergy_add`）：

- 符札引爆（灵梦 + 魔理沙）：魔理沙打中刚被灵梦御札打过的敌人必定暴击。
- 博丽与八云（灵梦 + 紫）：被紫的隙间移动过的敌人在出口带 4 秒结界标记。
- 境界火花（魔理沙 + 紫）：放极限火花时，紫从隙间再射出一道光束。
- 冰火交加（琪露诺 + 妹红）：火焰打被冰减速或冻结的敌人伤害提高，并融化冻结。
- 门番的一条直线（美铃 + 魔理沙）：魔理沙打被美铃挡住的敌人伤害提高（不再额外击退）。
- 冻结的时刻（咲夜 + 冻结）：咲夜飞刀连续扎同一个冻结敌人，加成逐刀递增。

强化（草案）：分裂弹（2 层「满天星」满屏子弹）、锐利、连射（2 层「三连发」）、寒气（2 层「青蛙冰雕」连锁冻结）、会心（2 层「必中之符」暴击爆炸）、大结界（2 层常驻结界）、充能（2 层「连续宣言」返还能量）、穿透、香火、修补（2 层减少漏怪伤害）、连击狂热、隙间之眼（2 层「隙间回廊」）。

## 9. 待其他策划和程序确认

### 9.1 数值策划（PR #8）

1. 本 PR 已删掉自己的 `stats.json`，全部改成引用 PR #8 的字段。请保留 ID（`chr_*`、`enm_*`、`boss_*`、`sc_*`、`buff_*`、`skl_*`、`syn_*`）和字段名；要改名请告诉战斗策划同步 `*_stats_key`。字段清单见 data_reference.md「stats.json」一节。
2. 请在 PR #8 补这些字段（本 PR 已经引用，JSON 里标了 `numeric_pending_pr8` 或 `*_pending_numeric`）：
   - `skills.skl_cirno_freeze.freeze_sec`（冰结）、`buffs.buff_frost_frog.freeze_sec`（寒气、青蛙冰雕）、`statuses.st_freeze.max_chain_sec`、`statuses.st_freeze_immune.duration_sec`、`statuses.st_unit_freeze_immune.duration_sec`。冻结类时长都归数值（A-08），本 PR 不再写秒数。
   - 冰之残影冻结秒数的专用字段（建议 `bosses.boss_cirno.unit_freeze_sec`）。现在借用 `terrain.ter_ice.stop_on_declare_sec`。
   - `characters.chr_meiling.redeploy_cooldown_sec`（`battle_rules.csv` 已有 `blocker_redeploy_cooldown`，还没进 `stats.json`）。
   - `synergies.syn_gatekeeper_line.synergy_add`、`buffs.buff_gap_eye.swap_hit_damage_coef`。
   - 扑人残影、飞行残影的数值（建议 `enemies.enm_shade_pouncer.pounce_disable_sec` 等），第三、四章前补即可。
3. 请改 PR #8 里和已拍板不一致的说明文字：`battle_rules.csv` 的三选一说明（「最后一波正好是 5 的倍数时也给」→ 不给）；第一波前另有 4 秒的写法（→ 推荐 0，见待拍板第 24 条）；封魔阵显示名（→ 梦符「封魔阵」）；美铃 `placement`（见待拍板第 25 条）。
4. 多发总伤害不变已写进规则：攻击和护甲都按发数平分（damage_and_status.md 2.2）。模拟里如果是「每发扣全额护甲」，请按这个改。
5. 刷怪窗口里也能叫波，最多能拿到「剩余窗口 + 4 秒」的奖励，请确认 `economy.early_call_reward_per_sec` 是否要设上限。
6. `enm_shade_heavy`、`enm_shade_swarm` 已在 `enemies.json` 登记为预留，行为是草案。
7. `skills.skl_meiling_hold` 不再使用（美铃改成阻挡），可以删。

### 9.2 关卡策划（PR #5）

1. 地图格式以 PR #5 `data_format.md` 为准；战斗读的字段见 terrain_and_map.md 第 4 节。
2. 按待拍板第 24 条推荐版：各关 `waves[0].delay_sec` 改成 0，`ends_when` = `spawn_window`，`delay_sec` = 4。
3. `ch1_03` 的 `w06` 加紫的隙间演示事件（`evt_yukari_gap_demo`，目标是这一波第一只硬残影，走到一半送回裂缝，不伤害）。
4. `ch1_04.json` 各阶段的 `status_on_character` 写的是 `st_freeze`，战斗里冻角色用的是 `st_unit_frozen`（`st_freeze` 只给敌人）。请改成 `st_unit_frozen`。
5. 浓雾、Boss 三阶段按血量都已一致，不用再改。
6. 第二章起要给美铃留紧贴路线的 `.` 格。

### 9.3 文案策划（PR #2）

1. 改 `tut.prologue_01.008`：现在是「先点格子，再点灵梦的头像」，应为「点下方的符卡按钮」。
2. 改 `dlg.prologue_01.mid.010`：灵梦首次符卡改喊 梦符「封魔阵」。
3. 新增：紫的演示提示 `tut.ch1_03.001`；`enemy.shade_heavy.name`、`enemy.shade_swarm.name`；联动名 `syn.*.name`；强化名和说明 `buff.*.name/desc`；界面文本 `combat.armor`（护甲）、`combat.synergy_found`（发现联动：%s！）、`combat.invulnerable`（无效）、`combat.final_wave`（最后一波）。

### 9.4 程序

1. 时间倍率用自建累加器，不用 `Engine.time_scale`（core_rules 2.2）。
2. 建议新建纯数据类（例如 `CombatConfig`，写 `class_name`）读取 `data/balance/combat/*.json`，场景脚本不自己解析 JSON，与现有 `BalanceConfig` 做法一致。`*_stats_key` 按点号路径去 `stats.json` 取值，`<id>`、`<caster_id>` 换成当前对象。
3. 伤害流水线、状态叠加、波次状态机都是纯函数，适合写 GUT 单元测试。
4. 存档加 `discovered_synergies`（已发现联动列表），`SaveGame` 的 `version` 相应处理。
5. `docs/ARCHITECTURE.md` 的「数值配置」已经登记了下面这张表。游戏代码仍未读取这些 JSON：

| 文件 | 内容 | 维护者 |
| --- | --- | --- |
| `data/balance/combat/stats.json` | 全部数值，由 PR #8 的脚本从 `data/*.csv` 生成，不要手改。本 PR 不带这个文件 | 数值策划（PR #8） |
| `data/balance/combat/rules.json` | 战斗规则和手感参数 | 战斗策划 |
| `data/balance/combat/characters.json` | 角色攻击方式、技能、符卡、阻挡、升级外观 | 战斗策划 |
| `data/balance/combat/enemies.json` / `bosses.json` | 敌人和 Boss 的行为。数值在 `stats.json` 的 `enemies` / `bosses` | 战斗策划 |
| `data/balance/combat/statuses.json` / `terrain.json` | 状态和地形效果 | 战斗策划 |
| `data/balance/combat/spell_cards.json` / `synergies.json` / `buffs.json` | 符卡、联动、强化 | 战斗策划 |
| `data/balance/combat/feel.json` | 打击反馈和演出参数 | 战斗策划 |

## 10. 2026-10-02 改动记录

- 删掉 `data/balance/combat/stats.json`，数值全部改为引用 PR #8；合并顺序改为先 PR #8、后本 PR。
- 对齐 PR #8：三选一每 5 波、2 层质变、冰面倍率、冰之残影移速、冻结时长、美铃挡 2 个、灵梦默认封魔阵、冰之残影每阶段一次符卡。
- 回应 PR #9：DI-03、DI-04（时间轴，待拍板第 24 条）、DI-05（快照）、DI-07（漏怪读 `bosses` 段）、DI-10（Boss ID）、DI-11（路线固定）、DI-12（待拍板第 26 条）、DI-13（待拍板第 6、8 条）、DI-14（紫的演示）、DI-15（敌人名和 key）。
- 硬残影进 MVP（`ch1_03`）；新增 `post_mvp` 的扑人残影、飞行残影，预留 PR #8 的 `enm_shade_heavy`、`enm_shade_swarm`。
- 敌人名和文本 key 跟随 PR #2 术语表；魔理沙改为 `prologue_01` 打完加入；文本 key 改成 PR #2 的新格式（如 `tut.prologue_01.004`、`dlg.ch1_04.mid.001`）。
- 能量满值按符卡使读 `characters.<id>.spell_energy_max`，不再固定 100。
