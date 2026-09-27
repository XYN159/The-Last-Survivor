# 《东方守幻录》战斗规则文档（草案）

> 东方 Project 二次创作。原作权利归上海爱丽丝幻乐团 / ZUN。
> 维护者：战斗策划。状态：**草案**。写于 2026-09-27。同日制作人拍板 5 条，见「已拍板」一节；其余问题仍待拍板。
> 依据：制作人已验收的战斗框架；PR #2（叙事文档初稿，分支 `docs/touhou-narrative-draft`，尚未合并）的角色名单、残影设定和符卡名；数值策划的伤害公式 `伤害 = max(攻击 − 护甲, 攻击 × armor_floor_ratio)`。`armor_floor_ratio` 和 `min_damage` 是 `stats.json` 顶层的全局常量。
> 截至写作时，仓库里还没有数值策划、关卡策划、系统策划的 PR 或分支，所以本目录里的 ID 是第一次定义。别人以后要改 ID，请先和战斗策划对齐。

## 1. 一句话

单机竖屏角色塔防：7 列 × 12 行格子，残影从上方的裂缝沿路线走向下方的守护点；玩家点空格放置东方角色，角色自动攻击；全队共用一条符卡能量，满了放一张带立绘演出的符卡；每几波三选一 roguelite 强化，叠层会质变。一关 3–5 分钟，追求爽感和险胜。

## 2. 文件索引

| 文件 | 内容 |
| --- | --- |
| [core_rules.md](core_rules.md) | 格子和坐标、60Hz tick 和 12 步结算顺序、时间倍率实现、敌人移动公式、局内状态机、波次和叫波、守护点和胜负、单手操作 |
| [damage_and_status.md](damage_and_status.md) | 9 步伤害流水线、加成分类和倍率桶、状态表、冻结和结界规则、联动判定时机 |
| [characters.md](characters.md) | 13 名角色的战斗行为，MVP 角色详细规则，MVP 冻结来源，紫的隙间探头 |
| [enemies_and_bosses.md](enemies_and_bosses.md) | 残影种类、敌人状态机、护甲提示、Boss 通用规则、Boss 琪露诺三阶段 |
| [terrain_and_map.md](terrain_and_map.md) | 地形效果表、冰柱遮挡判定、关卡地图数据对接格式（给关卡策划） |
| [spell_cards.md](spell_cards.md) | 能量条、充能节奏、手动和自动释放、立绘演出、符卡使（方案 A+）、MVP 符卡详细效果 |
| [synergies.md](synergies.md) | 框架联动 2 条 + 新增联动 6 条 |
| [roguelite_buffs.md](roguelite_buffs.md) | 强化触发时机、叠层和质变结构、12 个强化 |
| [feedback.md](feedback.md) | 反馈事件表（含 MVP 批次）、伤害数字上限与合并、连击、慢动作、立绘演出细节 |
| [data_reference.md](data_reference.md) | 所有配置表的字段说明（字段、类型、单位、含义、归属） |

配置表（`data/balance/combat/`）：`rules.json`、`stats.json`、`characters.json`、`enemies.json`、`bosses.json`、`statuses.json`、`terrain.json`、`spell_cards.json`、`synergies.json`、`buffs.json`、`feel.json`。都已用 `python -m json.tool` 校验。

### 为什么放在 `data/balance/combat/` 而不是 `data/combat/`

仓库 `AGENTS.md` 和 `.cursor/rules/project-workflow.mdc` 规定「数值放进 `data/balance/`」，`docs/CODING_STYLE.md` 也说「会调平衡的数字放进 `data/balance/`」。战斗的手感参数也属于要调的数字，所以跟随仓库约定放在 `data/balance/combat/`。`export_presets.cfg` 的 `include_filter="data/*"` 能匹配子目录（Godot 的 `*` 通配符可以跨 `/`，现有的 `data/balance/starting_balance.json` 本身就在子目录里并且能打包），不用改导出设置；程序接入后仍建议导出一次 APK 确认新 JSON 被打进包里。

## 3. 标记说明

| 标记 | 含义 |
| --- | --- |
| 【框架】 | 制作人已验收，照做 |
| 【战斗策划决定 N】 | 战斗策划的设计决定（默认按此实现） |
| 【草案默认值】 | 战斗策划给的默认值，可调 |
| 【占位·数值】 | 属于数值策划的字段，占位，待数值策划确认 |
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
| 硬停止 | 让敌人速度归零的状态：冻结、拦截、时停、隙间晕眩 |
| 符卡使 | 开局前选定的一名角色。底部符卡按钮放她的默认符卡。布阵期和波次空档可以换，波次进行中不能换 |
| 危急 | 有敌人进入最后 3 行，或守护点生命 ≤ 30%；符卡充能 ×1.5 |
| 报警区 | 最后 2 行，有敌人时守护点闪红 |
| 地形效果 | 叠在格子上的效果（冰面、冰柱、浓雾、结界……） |
| 灵力 | 放置和升级用的局内资源。框架里已经用了「灵力栏」这个词；PR #2 术语表把资源名列为「待系统策划定」，这里暂用「灵力」，字段名用 `spirit` |
| 角色 / 塔 | 玩家可见文本说「角色」，策划和代码可以说「塔」（PR #2 术语表） |

## 5. 最终 ID 清单（关卡策划可以直接引用）

### 角色（`chr_` + PR #2 文本 key 的角色 id）

`chr_reimu` 灵梦、`chr_marisa` 魔理沙、`chr_cirno` 琪露诺、`chr_daiyousei` 大妖精（可玩待定）、`chr_meiling` 美铃、`chr_sakuya` 咲夜、`chr_remilia` 蕾米莉亚（可玩待定）、`chr_keine` 慧音、`chr_mokou` 妹红、`chr_aya` 文（可玩待定）、`chr_sanae` 早苗、`chr_yukari` 紫、`chr_wasure` 忘。

### 敌人

MVP：`enm_shade_basic`（普通残影）、`enm_shade_fast`（快残影 / 褪色玩具）、`enm_shade_armored`（硬残影 / 旧电器）。
预留：`enm_shade_phantom`（遗忘之影）、`enm_shade_heap`（堆积体）、`enm_shade_rift`（结界之渣）。

### Boss

`boss_cirno`。以后按同样规则：`boss_meiling`、`boss_sakuya`、`boss_keine`、`boss_mokou`、`boss_sanae`、`boss_yukari`、`boss_wasure`（未定义，仅预留命名）。

### 状态

MVP：`st_slow`、`st_freeze`、`st_freeze_immune`、`st_barrier_mark`、`st_ofuda_tag`、`st_invulnerable`、`st_unit_frozen`、`st_unit_freeze_immune`。
后续：`st_burn`、`st_hold`、`st_hold_immune`、`st_time_stop`、`st_gap_daze`、`st_registered`。

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
| 3 | MVP（序章 + 第一章）玩家只有灵梦和魔理沙，没有冻结角色，冰碎无法自然触发 | 已拍板（2026-09-27）：强化「寒气」+ 琪露诺二阶段冻住残影。见「已拍板」第 3 条 |
| 4 | 紫第五章才可玩，MVP 里碰不到 | 已拍板（2026-09-27）：用 PR #2 已有的「隙间探头」演示一次换位。紫不是 MVP 可放置角色 |
| 5 | MVP 只有两名角色，如果每个角色只能放一个，棋盘上最多两个塔，爽感不足 | 已拍板（2026-09-27）：同一角色最多放 3 个，费用递增 |
| 6 | PR #2 琪露诺只有两张符卡，框架要求 Boss 2–3 个阶段并以 3 阶段为默认 | 补 雪符「钻石风暴」，需要文案加 key 和台词 |
| 7 | PR #2 教学 `tut.prologue.004`「拖动灵梦的头像」与框架「点空地选角色放置」不一致 | 需要文案改成「点击发光的格子，再选择灵梦」 |
| 8 | PR #2 教学 `tut.prologue.008`「点击灵梦，发动符卡」与框架「符卡按钮在底部」不一致；`dlg.prologue.mid.017` 需要能放魔理沙的符卡 | 已拍板方案 A+。文案仍要把教学改成「点击下方的符卡按钮」；魔理沙加入后的空档可以把她设为符卡使 |
| 9 | 1080×1920 下 7 列铺满宽度时 12 行几乎占满高度，底部按钮放不下 | 草案每格 128 像素（core_rules 1.3），待真机确认 |
| 10 | 连击「×N」的 `×` 可能不在字体子集里 | 程序确认，必要时扩字体子集 |
| 11 | `docs/ARCHITECTURE.md` 的「数值配置」表只登记了 `starting_balance.json` | 合并时需要补登记，见第 9 节草稿 |

## 已拍板（2026-09-27）

制作人于 2026-09-27 拍板。下面 5 条按确定规则执行。

| # | 原问题 | 结论 |
| --- | --- | --- |
| 1 | 符卡按钮放谁的符卡 | 方案 A+（`spell_energy.caster_mode` = `single_caster_switchable`）。开局前选一名符卡使，底部符卡按钮绑定她的默认符卡。`deploy`（布阵期）和 `intermission`（波次空档）可以换人；`spawning` 和 `waiting` 不能换。换人时符卡能量清零（`caster_switch_clears_charge` = true，数值策划已确认） |
| 2 | 同一角色能不能放多个 | 最多 3 个（`placement.max_copies_per_character`）。每多放一个，费用按 `characters.<id>.copy_cost_increase_ratio` 递增。递增比例仍是占位，归数值策划 |
| 3 | MVP 的冻结来源（冰碎要用） | 只有两个来源：强化「寒气」`buff_frost_frog`（命中有几率冻结；3 层「青蛙冰雕」的连锁冻结仍算这一条），以及琪露诺二阶段符卡 `sc_boss_cirno_perfect_freeze`。冰碎靠这两个来源触发 |
| 4 | 紫在 MVP 里怎么出现 | 通过 PR #2 已有的「隙间探头」事件露面，演示一次隙间换位。她不是 MVP 的可放置角色。正式可放置仍在第五章 |
| 5 | Boss 走到守护点怎么办 | 按 `leak_damage` 扣守护点生命，然后回到裂缝重新走（`on_reach_guard: loop_to_spawn`），保持当前血量和阶段。Boss 关必须打倒 Boss 才算胜利 |

## 7. 需要制作人拍板的问题

| # | 问题 | 选项 | 推荐 |
| --- | --- | --- | --- |
| 5 | 强化的作用范围 | 只在本关有效 / 整章延续 | **只在本关**：一关 3–5 分钟，每关都能体验一次从弱到强 |
| 6 | 琪露诺第三阶段用 雪符「钻石风暴」（冰面加速） | 认可 / 改成别的符卡 / 只做两阶段 | **认可**：原作琪露诺的冰符，冰面加速正好是框架例子 |
| 8 | 被 Boss 冻住的角色能不能连点 3 下提前破冰 | 能 / 不能 | **能**：单手可操作，把「被控」变成小互动 |
| 9 | 新增 6 条联动（第 8 节）和 12 个强化是否认可 | 逐条确认 | 先认可 MVP 能用到的：符札引爆、寒气、分裂弹、会心、锐利、连射、充能 |
| 10 | 局内资源的名字 | 「灵力」/ 等系统策划定 | 暂用「灵力」（框架已用） |
| 11 | 大妖精、蕾米莉亚、文是否可玩（PR #2 已提出） | — | 战斗行为都已备好草案，任一结果都能接 |

## 8. 新增联动和强化速览

联动（草案）：

- 符札引爆（灵梦 + 魔理沙）：魔理沙打中刚被灵梦御札打过的敌人必定暴击。
- 博丽与八云（灵梦 + 紫）：被紫的隙间移动过的敌人在出口带 4 秒结界标记，受伤 +20%。
- 境界火花（魔理沙 + 紫）：放极限火花时，紫从隙间再射出一道 50% 伤害的光束。
- 冰火交加（琪露诺 + 妹红）：火焰打被冰减速或冻结的敌人伤害 +50%，并融化冻结。
- 门番的一条直线（美铃 + 魔理沙）：魔理沙打被美铃拦住的敌人伤害 +50%，额外击退。
- 冻结的时刻（咲夜 + 冻结）：咲夜飞刀连续扎同一个冻结敌人，每刀递增 +10%，最多 +50%。

强化（草案）：分裂弹（3 层「满天星」满屏子弹）、锐利、连射（3 层「三连发」）、寒气（3 层「青蛙冰雕」连锁冻结）、会心（3 层「必中之符」暴击爆炸）、大结界（3 层常驻结界）、充能（3 层「连续宣言」返还能量）、穿透、香火、修补（3 层漏怪 −1）、连击狂热、隙间之眼（3 层「隙间回廊」）。

## 9. 待其他策划和程序确认

### 9.1 数值策划

1. `stats.json` 整份文件归数值策划。快残影的 `hp`（35）和移速（2.0）已确认；`threat_points` 以及预留敌人除移速外的数字是这次补的占位；其余数字仍是占位。可以改文件内部结构，但请保留 ID（`chr_*`、`enm_*`、`boss_*`、`sc_*`、`buff_*`、`skl_*`）；如果要拆分文件或改名，告诉战斗策划同步 `*_stats_key`。
2. 充能换算：每点有效伤害充能、每只敌人击杀充能，目标普通约 60 秒、危急约 40 秒充满（换算方法见 spell_cards.md 1.1）。
3. 攻击成长：每个角色升 2 次（1 级到 3 级）已和数值策划对齐。`level_attack_mult` 三项、`upgrade_costs` 两项、卖出返还比例、同名角色费用递增比例 `copy_cost_increase_ratio` 的具体数字仍是占位。
4. 暴击率和暴击倍率；重击是否需要额外倍率（目前没有）。
5. 守护点生命、各敌人漏怪伤害、Boss 每次折返扣多少。
6. 灵力：开局灵力、各敌人掉落、叫波每秒奖励、提前开始每秒奖励。
7. 技能、符卡、灼烧、强化的伤害系数和每层数值。
8. 伤害保底已定为 `stats.json` 顶层全局常量：`armor_floor_ratio`（0.2）、`min_damage`（1）。请保留这两个键名。`rules.json` 不再重复这两项。
9. 敌人移速已放进 `stats.json` 的 `enemies.<id>.move_speed_cells_per_sec`（普通 1.0 / 快 2.0 / 硬 0.7 / 琪露诺 0.5 格/秒）。快残影 2.0 已确认。如果要按章节整体提速，建议加一个章节倍率，不要改基础值。
10. 硬残影护甲 8 配合魔理沙攻击 22、灵梦攻击 10 时，灵梦打硬残影只有 2 点（被削 80%），会频繁出「护甲」提示；这是有意的，但请确认强度。
11. 换符卡使时能量清零已由数值策划确认（`rules.json` → `spell_energy.caster_switch_clears_charge` = true）。请保留这个键。

### 9.2 关卡策划

1. 地图格式建议见 terrain_and_map.md 第 4 节（格子类型、路线格子序列、地形、`cell_sets`、波次字段）。
2. 琪露诺 Boss 关请提供 `boss_cirno_p1_icicles`、`boss_cirno_p3_ice` 两个格子集合（不给会用兜底规则）。
3. 每波的 `next_wave_delay_sec` 决定叫波奖励的上限；空档 `intermission_sec` 只能 3–5 秒。
4. 序章建议 `spell_charge_mult: 2.0`、`deploy_wait_for_player: true`，并有一段长直路给魔理沙。
5. 第一章浓雾用 `ter_fog`，可以按波次出现。
6. 路线长度建议 18–26 格：按 `stats.json` 的移速，普通残影约 18–26 秒，快残影（2.0 格/秒）约 9–13 秒，给玩家反应时间。

### 9.3 文案策划

1. 修改 `tut.prologue.004`（拖动 → 点格子选角色）、`tut.prologue.008`（点击灵梦 → 点击符卡按钮）。
2. 新增 `spell.cirno.diamond_blizzard.name`（雪符「钻石风暴」，原名 雪符「ダイアモンドブリザード」）和第三阶段宣言台词。
3. 新增敌人名 `enemy.shade_basic.name` 等、联动名 `syn.*.name`、强化名和说明 `buff.*.name/desc`、界面文本 `combat.armor`（护甲）、`combat.synergy_found`（发现联动：%s！）、`combat.invulnerable`（无效）、`combat.final_wave`（最后一波）。

### 9.4 程序

1. 时间倍率用自建累加器，不用 `Engine.time_scale`（core_rules 2.2）。
2. 建议新建纯数据类（例如 `CombatConfig`，写 `class_name`）读取 `data/balance/combat/*.json`，场景脚本不自己解析 JSON，与现有 `BalanceConfig` 做法一致。
3. 伤害流水线、状态叠加、波次状态机都是纯函数，适合写 GUT 单元测试。
4. 存档加 `discovered_synergies`（已发现联动列表），`SaveGame` 的 `version` 相应处理。
5. 合并时在 `docs/ARCHITECTURE.md` 的「数值配置」下补登记，草稿如下：

| 文件 | 内容 | 维护者 |
| --- | --- | --- |
| `data/balance/combat/rules.json` | 战斗规则和手感参数 | 战斗策划 |
| `data/balance/combat/stats.json` | 全局常量 `armor_floor_ratio`、`min_damage`，以及角色、敌人（含 Boss）、经济、充能、系数的数值。敌人的血量、移速、护甲、掉落、漏怪、威胁、击杀充能都在 `enemies` 里 | 数值策划 |
| `data/balance/combat/characters.json` | 角色攻击方式、技能、符卡、升级外观 | 战斗策划 |
| `data/balance/combat/enemies.json` / `bosses.json` | 敌人和 Boss 的行为。血量、移速等数值在 `stats.json` | 战斗策划 |
| `data/balance/combat/statuses.json` / `terrain.json` | 状态和地形效果 | 战斗策划 |
| `data/balance/combat/spell_cards.json` / `synergies.json` / `buffs.json` | 符卡、联动、强化 | 战斗策划 |
| `data/balance/combat/feel.json` | 打击反馈和演出参数 | 战斗策划 |
