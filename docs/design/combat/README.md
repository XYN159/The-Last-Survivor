# 《东方守幻录》战斗规则文档（草案）

> 东方 Project 二次创作。原作权利归上海爱丽丝幻乐团 / ZUN。
> 维护者：战斗策划。状态：**草案**。写于 2026-09-27，2026-10-02 按执行制作人的意见改过一轮（见第 10 节），2026-10-03 按用户 Q2–Q6、Q12、Q14 改过（见第 11 节）。已拍板的条目见「已拍板」一节；其余问题仍待拍板。
> 依据：制作人已验收的战斗框架；PR #2（文案，分支 `docs/touhou-narrative-draft`）的角色名单、残影设定、符卡名、文本 key 和术语表；数值策划 PR #8（分支 `numeric/touhou-td-framework`）的 `stats.json`。
> **数值以 PR #8 为唯一来源。** 本目录只写规则、公式和字段含义，引用 PR #8 的字段名（如 `stats.json` → `enemies.<id>.hp`、`bosses.boss_cirno.leak_damage`），不抄数字。本 PR 不再带 `data/balance/combat/stats.json`。**合并顺序：先合 PR #8，再合本 PR**，本 PR 引用 PR #8 的表。
> 本目录里的战斗 ID 在这里第一次定义。别人以后要改 ID，请先和战斗策划对齐。关卡波数需要举例时，引用关卡策划 PR #5，不在这里另编关卡号。

## 1. 一句话

单机竖屏角色塔防：7 列 × 12 行格子，残影沿固定路线走向守护点。放置是先点 `.` 格，再点头像，再选方向（Q3b）；同一个角色只能放一个（Q3）。射程是格子加朝向。出怪用连续时间轴（Q2），不再用 20 秒刷怪窗口和 4 秒空档。没有局内升级，换位置就撤退再部署（Q6）。没有全队共用的符卡条，符卡名挂在角色自己的技能上（Q5），技力怎么回复待 P2。主线没有三选一，强化池留给肉鸽（Q12）。伤害保底是攻击的 5%，没有通用暴击（Q14）。Boss 漏过扣 2 命（Q4）。阶段、冻结减半、不免疫都待 P4。

## 1.1 关于 D-05、D-06、D-18、D-19

PR #15 曾把 D-05、D-06、D-18、D-19 写成锁定，但用户并没有拍这四条。D-05 的第三阶段待 P4；D-06 的局内强化和 Q6、Q12 冲突；D-18 的叫波属于旧波次钟，Q2 之后不再当规则；D-19 美铃不是 MVP 角色。不要把这四条再写成「已定」。

## 2. 文件索引

| 文件 | 内容 |
| --- | --- |
| [core_rules.md](core_rules.md) | 格子和朝向、60Hz tick、连续时间轴、撤退再部署、守护点和胜负、单手放置 |
| [damage_and_status.md](damage_and_status.md) | 9 步伤害流水线、加成分类和倍率桶、状态表、冻结和结界规则、联动判定时机 |
| [characters.md](characters.md) | 13 名角色的战斗行为，MVP 角色详细规则，MVP 冻结来源，紫的隙间探头 |
| [enemies_and_bosses.md](enemies_and_bosses.md) | 残影种类、敌人状态机、护甲提示、Boss 漏过扣 2 命；三阶段钻石风暴标为旧稿待 P4 |
| [terrain_and_map.md](terrain_and_map.md) | 地形效果表、冰柱遮挡判定、关卡地图数据对接格式（给关卡策划） |
| [spell_cards.md](spell_cards.md) | 共用符卡条已删除；符卡名挂到角色技能。机制细则待 P2。后面几节是旧稿 |
| [synergies.md](synergies.md) | 框架联动 2 条 + 新增联动 6 条 |
| [roguelite_buffs.md](roguelite_buffs.md) | 主线不用。三选一和强化池留给肉鸽（Q12） |
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
| 重击 | 标记为 heavy 的命中；飘黄色大字、震屏。通用暴击已去掉 |
| 硬停止 | 让敌人速度归零的状态：冻结、拦截、时停、隙间晕眩（美铃的阻挡 `st_blocked` 单独算） |
| 符卡 | 不再有全队共用的符卡使。符卡名挂在角色自己的技能上（Q5）。技力回复待 P2 |
| 危急 | 旧稿用来给共用符卡条加速充能。共用条已删除（Q5），这条不再当充能规则 |
| 报警区 | 最后 2 行，有敌人时守护点闪红 |
| 地形效果 | 叠在格子上的效果（冰面、冰柱、浓雾、结界……） |
| 灵力 | 放置用的局内资源。局内升级已删除（Q6）。名称仍是「灵力」（文本 key `currency.reiryoku`）。字段名仍用 `spirit`。费用尺度待 P7 |
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
Boss 旧稿：`sc_boss_cirno_icicle_fall`（冰符「冰瀑」）、`sc_boss_cirno_perfect_freeze`（冻符「完美冻结」）、`sc_boss_cirno_diamond_blizzard`（雪符「钻石风暴」）。三阶段和钻石风暴待 P4，不是已定。

### 其他

技能 `skl_<角色>_<名>`；联动 `syn_<名>`（见 synergies.md）；强化 `buff_<名>`（见 roguelite_buffs.md）；召唤物 `hlp_<名>`（目前只有 `hlp_lost_item`）；关卡里 Boss 用的格子集合名 `boss_cirno_p1_icicles`、`boss_cirno_p2_area`、`boss_cirno_p3_ice`。

## 6. 与仓库现状的冲突和缺口

| # | 问题 | 处理 |
| --- | --- | --- |
| 1 | `docs/GDD.md` 仍是旧的车道/小队/基地玩法，并写着「明确先不做：复杂剧情和过场」 | 本目录不改它。需要系统策划/制作人按新定位更新 GDD；在那之前，战斗相关以本目录为准 |
| 2 | 任务要求的 `data/combat/` 与仓库「数值放 `data/balance/`」的规定不一致 | 采用 `data/balance/combat/`（见第 2 节） |
| 3 | MVP（序章 + 第一章）玩家开局只有灵梦和魔理沙，冰碎仍要能触发 | 已拍板：第一章第 2 关起有琪露诺本人，冰碎可以自然触发；另外还有寒气和冰之残影二阶段。见「已拍板」 |
| 4 | 紫第五章才可玩，MVP 里碰不到 | 已拍板：`ch1_03` 第 6 波用隙间演示一次；`ch1_04` 打完后紫正式加入，从 `ch2_01` 起可放，MVP 里重打已通关卡使用 |
| 5 | MVP 只有两名角色，如果每个角色只能放一个，棋盘上最多两个塔，爽感不足 | Q3（2026-10-03）：同名只能一个。旧的「最多 3 个、费用递增」作废。不在这里另定新的人数上限 |
| 6 | PR #2 琪露诺只有两张符卡，旧稿用三阶段 | 三阶段钻石风暴是旧稿，待 P4，不是用户已经同意。两阶段、冻结减半、不免疫也待 P4。见第 1.1 节，不要写成 D-05 已定 |
| 7 | PR #2 教学 `tut.prologue_01.004` 原先写「拖动灵梦的头像」 | 放置已定（Q3b）：点格子 → 点头像 → 选方向。教学如果还没写选方向，请文案后补。旧的待拍板第 26 条里「先点格子再点头像」这一半已经定了 |
| 8 | PR #2 教学 `tut.prologue_01.008` 按共用符卡按钮来写 | 共用符卡按钮已删除（Q5）。这句教学以后跟角色自己的技能改。不要再改成「点下方的符卡按钮」，也不再设符卡使 |
| 9 | 1080×1920 下 7 列铺满宽度时 12 行几乎占满高度，底部按钮放不下 | 草案每格 128 像素（core_rules 1.3），待真机确认 |
| 10 | 连击「×N」的 `×` 可能不在字体子集里 | 程序确认，必要时扩字体子集 |
| 11 | `docs/ARCHITECTURE.md` 的「数值配置」原先只登记了 `starting_balance.json` | 已补上 `data/balance/combat/` 的表；`stats.json` 那一行登记为 PR #8 生成。游戏代码仍未读取这些 JSON |
| 12 | PR #2 `dlg.prologue_01.mid.010`（灵梦首次发动符卡）喊的是 灵符「梦想封印」 | 灵梦默认符卡已改成 梦符「封魔阵」（用户已确认），请文案改这句 |
| 13 | PR #8 `characters.csv` 把封魔阵写成 灵符「封魔阵」，PR #2 是 梦符「封魔阵」 | 以 PR #2 为准，请数值策划改显示名 |

## 已拍板（2026-09-27 起）

制作人、系统策划和用户已拍板。下面按确定规则执行。数字一律在 PR #8。

| # | 原问题 | 结论 |
| --- | --- | --- |
| 1 | 符卡按钮放谁的符卡 | Q5：共用符卡条和符卡使删除。符卡名挂到角色技能。方案 A+ 是旧稿。技力回复待 P2 |
| 2 | 同一角色能不能放多个 | Q3：同名只能一个。旧的「最多 3 个、费用递增」作废 |
| 3 | MVP 的冻结来源 | 三个：第一章第 2 关起的琪露诺本人（冰碎可以自然触发）、寒气强化、冰之残影二阶段。寒气的 2 层「青蛙冰雕」仍算寒气这一条 |
| 4 | 紫什么时候能放 | `ch1_03` 第 6 波，隙间把第一只硬残影送回裂缝，演示一次，不伤害（DI-14）。`ch1_04` 打完后正式加入（`unlock` = `chapter1_boss_clear`），从 `ch2_01` 起可放；MVP 里通过重打已通关的关卡使用（`mvp_use` = `replay_cleared_levels`），和 PR #5 一致。这一关的 Boss 是冰之残影，不是琪露诺本人 |
| 5 | Boss 走到守护点、以及输了怎么办 | Q4：漏过扣 2 命。折返是旧稿，待 P4。普通关要等时间轴出完并清场。输了可以整关重打。「从当前波重来」属于旧波次钟，Q2 之后不再当规则 |
| 12 | 强化质变、三选一、作用范围 | Q12：主线删除三选一，局内强化池留给肉鸽。旧的每 5 波三选一不再当主线规则 |
| 13 | 关卡节奏 | Q2：连续时间轴。20 秒窗口、4 秒空档、叫波都不再当规则。D-18 未拍 |
| 14 | MVP 敌人 | 小残影、快残影、硬残影，外加 Boss 冰之残影（`boss_cirno`）。硬残影只在 `ch1_03` 出现，一共 8 只：第 6 到 11 波每波 1 只，第 12 波 2 只，每只约在这一波开始后 10 秒出生（制作人 2026-09-27 23:53 定，PR #5、PR #8 已一致） |
| 15 | 放置、路线、自动释放 | 放置是点格子 → 点头像 → 选方向（Q3b），只能放在 `.` 格。路线标成 `P`，一关可以有多条，中途不动。共用符卡的自动释放是旧稿（Q5） |
| 16 | 琪露诺什么时候能放 | 2026-09-27 已定：第一章第 1 关 `ch1_01` 打完后加入（`unlock` = `ch1_01_clear`）。从第一章第 2 关起可以放置 |
| 17 | 数值归属（执行制作人，2026-10-02） | PR #8 是数值唯一来源。本 PR 删掉自己的 `stats.json`，规则文档只写字段名。先合 PR #8，再合本 PR |
| 18 | 灵梦默认符卡（用户确认） | 梦符「封魔阵」：以灵梦为中心减速，不造成伤害（`spell_cards.sc_evil_sealing_circle.*`）。`sc_evil_sealing_circle` 是 MVP，梦想封印 `sc_fantasy_seal` 改为 MVP 之后 |
| 19 | 冻结和冰之残影 | 秒数和移速仍归数值，本文不另写。三张符卡各放一次是旧的三阶段稿，待 P4。冻结减半、不免疫也待 P4。连点破冰不是已定（见第 1.1 节） |
| 20 | 冰面倍率 | `terrain.ter_ice.move_speed_mult`（PR #8，和 PR #5 一致） |
| 21 | 美铃 | 不是 MVP 角色。站位和阻挡数待 P2。不要把 D-19 或「挡 2 个」写成已定 |
| 22 | 魔理沙什么时候加入 | 序章第 1 关 `prologue_01` 打完后加入，从 `prologue_02` 起可放（和 PR #2、PR #5、PR #8 一致）。旧稿「序章第 3 波前加入」作废 |
| 23 | 敌人名和文本 key | 以 PR #2 术语表为准：普通残影改叫小残影；遗忘之影、堆积体、结界之渣改叫遗忘残影、堆积残影、结界残影；key 用 `enemy.shade_basic.name` 这种，Boss 用 `enemy.boss_cirno.name`（替换 `boss.ice_shade.name`） |
| D-05 | 冰之残影第三阶段，以及被冻住能不能连点破冰 | **未拍。** 第三阶段待 P4。不要写成已定。见第 1.1 节 |
| D-06 | MVP 认可哪些联动和强化 | **未拍。** 局内强化和 Q6、Q12 冲突。符札引爆的暴击已随通用暴击去掉。见第 1.1 节 |
| D-18 | 刷怪窗口里能不能提前叫下一波 | **未拍。** 叫波属于旧波次钟，Q2 之后不再当规则。见第 1.1 节 |
| D-19 | 美铃放在哪种格子 | **未拍。** 美铃不是 MVP 角色。站位待 P2。见第 1.1 节 |

战斗策划这次补的规则（回应 PR #8 和 PR #9，没有改已拍板的东西）：

- **多发总伤害不变**：一次攻击的总伤害平分给每一发（damage_and_status.md 2.2）。通用暴击已去掉，不再每发掷暴击。局内升级已删除（Q6），主线不靠升到 2 级、3 级才变多发。
- **浓雾**：目标在雾里时射程减 `terrain.ter_fog.range_minus_cells`，最少 `min_range_cells`。PR #5 和 PR #8 现在都是这一版（PR #5 早先的「射程乘倍率」已改掉），不再有冲突。
- **Boss 阶段**：三阶段是旧稿，待 P4，不是用户已经同意。两阶段、冻结减半、不免疫也待 P4。漏过扣 2 命已定（Q4）。
- **重来快照**（DI-05）：内容见 core_rules.md 5.2。
- **扑人残影、飞行残影**：只写推荐行为，没有数字，状态 `post_mvp`。

## 7. 需要制作人拍板的问题

已经定了的：放置顺序见 Q3b；同名一个见 Q3；时间轴见 Q2；共用符卡条删除见 Q5；局内升级删除见 Q6；主线无三选一见 Q12；保底 5% 见 Q14；Boss 扣 2 命见 Q4。资源名仍是「灵力」。D-05、D-06、D-18、D-19 没有拍，见第 1.1 节，不要再写成已定。下面还开着的编号沿用旧清单。

| # | 问题 | 选项 | 推荐 |
| --- | --- | --- | --- |
| 11 | 大妖精、蕾米莉亚、文是否可玩（PR #2 已提出）；文对快敌人的加成（`chr_aya.bonus_vs_speed`，PR #8 `syn_aya_vs_fast`） | — | 战斗行为都已备好草案，任一结果都能接 |
| 26 | 放置手势里还没写进教学的部分 | 点格子、点头像、选方向已经由 Q3b 定下。底部共用符卡按钮已删除（Q5） | 文案以后补「选方向」。不要再写成点底部符卡按钮 |

另外两件事不需要拍板，只是告诉制作人：

- 紫的隙间演示（DI-14）：制作人原稿写 `ch1_02` 第 6 波。因为硬残影只在 `ch1_03` 出现，战斗策划和关卡策划改成 `ch1_03` 第 6 波。
- 首领关入场和 Boss 血量归关卡策划和数值策划。战斗已定的只有：按时间轴出场，漏过扣 2 命。折返和阶段待 P4。

## 8. 联动和强化

D-06 不是已定，见第 1.1 节。主线没有三选一（Q12），也没有局内升级（Q6）。

仍按框架做的联动：冰碎、结界加护。符札引爆的「必定暴击」随通用暴击去掉，不当规则，也不另编伤害数字。其余联动待 P2，不在这里定谁和谁联动。

强化清单留在 roguelite_buffs.md，给肉鸽用，不进主线。

## 9. 待其他策划和程序确认

### 9.1 数值策划（PR #8）

1. 本 PR 已删掉自己的 `stats.json`，全部改成引用 PR #8 的字段。请保留 ID（`chr_*`、`enm_*`、`boss_*`、`sc_*`、`buff_*`、`skl_*`、`syn_*`）和字段名；要改名请告诉战斗策划同步 `*_stats_key`。字段清单见 data_reference.md「stats.json」一节。
2. 请在 PR #8 补这些字段（本 PR 已经引用，JSON 里标了 `numeric_pending_pr8` 或 `*_pending_numeric`）：
   - `skills.skl_cirno_freeze.freeze_sec`（冰结）、`buffs.buff_frost_frog.freeze_sec`（寒气、青蛙冰雕）、`statuses.st_freeze.max_chain_sec`、`statuses.st_freeze_immune.duration_sec`、`statuses.st_unit_freeze_immune.duration_sec`。冻结类时长都归数值（A-08），本 PR 不再写秒数。
   - 冰之残影冻结秒数的专用字段（建议 `bosses.boss_cirno.unit_freeze_sec`）。现在借用 `terrain.ter_ice.stop_on_declare_sec`。
   - `characters.chr_meiling.redeploy_cooldown_sec`（`battle_rules.csv` 已有 `blocker_redeploy_cooldown`，还没进 `stats.json`）。
   - `synergies.syn_gatekeeper_line.synergy_add`、`buffs.buff_gap_eye.swap_hit_damage_coef`。
   - 扑人残影、飞行残影的数值（建议 `enemies.enm_shade_pouncer.pounce_disable_sec` 等），第三、四章前补即可。
3. 请改 PR #8 里和 2026-10-03 拍板不一致的说明：主线三选一整段移出（Q12）；波次钟的 20 秒窗口和 4 秒空档换成连续时间轴（Q2）；封魔阵显示名仍是梦符「封魔阵」；美铃站位不要按 D-19 改，那条没拍。保底比例改为 0.05（Q14），并去掉通用暴击字段。本文不另写一套伤害数字。
4. 多发总伤害不变已写进规则：攻击和护甲都按发数平分（damage_and_status.md 2.2）。模拟里如果是「每发扣全额护甲」，请按这个改。
5. 叫波不再当规则（Q2）。D-18 未拍。不要为叫波奖励再加字段。
6. `enm_shade_heavy`、`enm_shade_swarm` 已在 `enemies.json` 登记为预留，行为是草案。
7. `skills.skl_meiling_hold` 不再使用（美铃改成阻挡），可以删。

### 9.2 关卡策划（PR #5）

1. 地图格式以 PR #5 `data_format.md` 为准；战斗读的字段见 terrain_and_map.md 第 4 节。
2. 出怪改成连续时间轴（Q2）。不要再按 20 秒窗口和 4 秒空档排。表结构归关卡策划，战斗不另定秒数。
3. `ch1_03` 的 `w06` 加紫的隙间演示事件（`evt_yukari_gap_demo`，目标是这一波第一只硬残影，走到一半送回裂缝，不伤害）。
4. `ch1_04.json` 各阶段的 `status_on_character` 写的是 `st_freeze`，战斗里冻角色用的是 `st_unit_frozen`（`st_freeze` 只给敌人）。请改成 `st_unit_frozen`。
5. Boss 三阶段是旧稿，待 P4。关卡先不要按钻石风暴定稿。漏过扣 2 命已定。
6. 美铃不是 MVP 角色，站位待 P2。不要按 D-19 预留紧贴路线的格子。

### 9.3 文案策划（PR #2）

1. `tut.prologue_01.008` 不要改成底部符卡按钮。共用符卡条已删除（Q5）。这句以后跟角色自己的技能改。
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
- 对齐 PR #8 的那一轮里，三选一、美铃挡 2 个、三阶段符卡，已由 2026-10-03 的拍板盖过，见第 11 节。
- 回应 PR #9 的记录留在这里当历史。其中 DI-13 不要再理解成 D-05 已定。
- 2026-10-02 曾把 D-05、D-06、D-18、D-19 写成拍板。用户并没有拍这四条。见第 1.1 节。
- 硬残影进 MVP（`ch1_03`）；新增 `post_mvp` 的扑人残影、飞行残影，预留 PR #8 的 `enm_shade_heavy`、`enm_shade_swarm`。
- 敌人名和文本 key 跟随 PR #2 术语表；魔理沙改为 `prologue_01` 打完加入；文本 key 改成 PR #2 的新格式（如 `tut.prologue_01.004`、`dlg.ch1_04.mid.001`）。
- （旧稿记录）当时把能量满值写成按符卡使读 `characters.<id>.spell_energy_max`。Q5 之后共用符卡条已删除，不当当前规则。

## 11. 2026-10-03 改动记录

- 射程改为格子加朝向（Q3b）。每个人的范围形状、站位、阻挡数、技能回复方式待 P2，本文不定。
- 波次状态机改为连续时间轴（Q2）。叫波不再当规则。
- 放置改为点格子 → 点头像 → 选方向。同名只能一个（Q3）。
- 局内升级删除，改为撤退再部署（Q6）。再部署的费用和等待待 P6。
- 伤害保底改为 5%（Q14）。通用暴击去掉。不另编一套伤害数字。
- 共用符卡条删除，符卡名挂到角色技能（Q5）。四人机制细则待 P2。
- Boss 漏过扣 2 命（Q4）。两阶段、冻结减半、不免疫待 P4。三阶段钻石风暴标为旧稿，待 P4。
- 主线三选一和局内强化池移出主线，留给肉鸽（Q12）。
- PR #15 曾把 D-05、D-06、D-18、D-19 写成锁定，用户并没有拍这四条。不要再写成已定。
