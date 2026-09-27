# 配置表字段说明

> JSON 不能写注释，所以每个字段的含义写在这里。
> 「归属」列：**战斗** = 战斗策划（行为和手感）；**数值** = 数值策划（占位，待数值策划确认）；**关卡** = 关卡策划；**文案** = 文案策划；**程序** = 实现细节。
> 所有文件都在 `data/balance/combat/`，UTF-8，字段英文小写下划线。每个文件都有 `meta` 段：`schema_version`（整数，结构改了就 +1）、`status`（`draft` / `placeholder_pending_balance_design`）、`owner`、`doc`（对应文档）。
> 注意：Godot 的 `JSON.parse` 把所有数字读成浮点数，程序取整数字段时要 `int()`。

## 文件归属总览

| 文件 | 内容 | 主要归属 |
| --- | --- | --- |
| `rules.json` | 棋盘、tick、局内流程、选敌、移动、危急、符卡能量规则、连击、慢动作、伤害取整和护甲提示、放置、强化触发、性能上限 | 战斗 |
| `stats.json` | 伤害保底全局常量，以及守护点生命、灵力经济、充能换算、角色/敌人/Boss 的费用攻击血量护甲掉落、技能/符卡/强化的数值系数 | **数值**（`armor_floor_ratio`、`min_damage` 已定；其余占位） |
| `characters.json` | 角色攻击方式、射程、间隔、弹道、技能、符卡、每级外观 | 战斗 |
| `enemies.json` | 敌人移速、标签、反馈、状态机 | 战斗 |
| `bosses.json` | Boss 阶段、符卡、控制免疫、切阶段规则 | 战斗 |
| `statuses.json` | 状态效果、时长、叠加、免疫、视觉 | 战斗 |
| `terrain.json` | 地形效果 | 战斗（关卡引用） |
| `spell_cards.json` | 符卡效果 | 战斗 |
| `synergies.json` | 联动条件和效果 | 战斗 |
| `buffs.json` | 强化行为、叠层、质变 | 战斗（结构）/ 系统（稀有度、权重）/ 数值（每层数值） |
| `feel.json` | 打击反馈和演出参数 | 战斗 |

## rules.json

| 字段 | 类型 | 单位 | 含义 | 归属 |
| --- | --- | --- | --- | --- |
| `grid.columns` / `grid.rows` | 整数 | 格 | 7 × 12【框架】 | 战斗 |
| `grid.origin` | 字符串 | — | 坐标原点，`top_left` | 程序 |
| `grid.cell_size_px` | 整数 | 像素 | 每格像素，草案 128 | 程序/制作人 |
| `grid.board_offset_px` | [x, y] | 像素 | 棋盘左上角在 1080×1920 画面里的位置 | 程序 |
| `tick.logic_hz` | 整数 | 次/秒 | 逻辑频率 60 | 战斗 |
| `tick.max_ticks_per_frame` | 整数 | 次 | 一帧最多补跑几个 tick | 程序 |
| `time_scale.speed_options` | 数组 | 倍 | 可选倍速 [1, 2]【框架】 | 战斗 |
| `battle_flow.deploy_time_sec` | 数字 | 秒 | 布阵期 10【框架】 | 战斗（关卡可覆盖） |
| `battle_flow.intermission_sec` | 数字 | 秒 | 空档 4，允许 3–5【框架】 | 战斗（关卡可覆盖） |
| `battle_flow.early_call_allowed_states` | 数组 | — | 哪些局内状态能叫波 | 战斗 |
| `battle_flow.early_call_reward_rounding` | 字符串 | — | 奖励取整方式 `floor` | 战斗 |
| `targeting.default_rule` | 字符串 | — | 默认选敌 `closest_to_guard`（离守护点路程最近） | 战斗 |
| `targeting.tie_breaker` | 字符串 | — | 平局取出生更早的 | 战斗 |
| `targeting.deprioritize_invulnerable` | 布尔 | — | 无敌目标排在最后 | 战斗 |
| `movement.min_speed_mult` | 数字 | 倍 | 移速总倍率下限 0.3【框架】 | 战斗 |
| `movement.max_speed_mult` | 数字 | 倍 | 上限 2.0 | 战斗 |
| `movement.boss_min_speed_mult` | 数字 | 倍 | Boss 下限 0.5 | 战斗 |
| `movement.hard_stop_statuses` | 数组 | — | 让速度归零的状态 | 战斗 |
| `knockback.default_cells` | 数字 | 格 | 默认击退 0.1【框架】 | 战斗 |
| `knockback.per_enemy_cooldown_sec` | 数字 | 秒 | 同一敌人普通击退冷却 0.25 | 战斗 |
| `enemy_spawn.spawn_state_sec` | 数字 | 秒 | 出生状态时长 0.3 | 战斗 |
| `guard.alert_rows_from_bottom` | 整数 | 行 | 报警区 = 最后 2 行 | 战斗 |
| `guard.alert_throttle_real_sec` | 数字 | 秒（真实） | 报警音节流 2.0 | 战斗 |
| `guard.damage_vignette_sec` | 数字 | 秒 | 扣血泛红 0.4【框架】 | 战斗 |
| `crisis.rows_from_bottom` | 整数 | 行 | 危急区 = 最后 3 行 | 战斗 |
| `crisis.guard_hp_ratio` | 数字 | 比例 | 守护点 ≤ 30% 算危急 | 战斗 |
| `crisis.charge_mult` | 数字 | 倍 | 危急充能 ×1.5 | 战斗（数值确认） |
| `spell_energy.max` / `start` | 数字 | 能量 | 满值 100，开局 0 | 战斗 |
| `spell_energy.charge_from_spell_damage` | 布尔 | — | 符卡伤害是否充能（否） | 战斗 |
| `spell_energy.count_overkill` | 布尔 | — | 溢出伤害是否充能（否） | 战斗 |
| `spell_energy.target_full_sec_normal` / `_crisis` | 数字 | 秒 | 设计目标 60 / 40，给数值换算用，程序不读 | 战斗 |
| `spell_energy.auto_release_default_on` | 布尔 | — | 自动释放默认关 | 战斗 |
| `spell_energy.auto_release_min_enemies` | 整数 | 只 | 自动释放条件之一：场上 ≥ 8 只 | 战斗 |
| `spell_energy.auto_release_rows_from_bottom` | 整数 | 行 | 自动释放条件之二：有敌人进入最后 3 行 | 战斗 |
| `spell_energy.caster_mode` | 字符串 | — | 已定为 `single_caster_switchable`（方案 A+，2026-09-27） | 制作人 |
| `spell_energy.caster_switch_allowed_states` | 数组 | — | 允许换符卡使的状态：`deploy`、`intermission` | 战斗 |
| `spell_energy.caster_switch_clears_charge` | 布尔 | — | 换符卡使时能量是否清零。现为 true。草案原先没写，这一细节待数值策划确认 | 战斗/数值 |
| `spell_energy.caster_absent_origin` | 字符串 | — | 符卡使不在场时从哪里发出（守护点） | 战斗 |
| `spell_energy.caster_unfreeze_on_cast` | 布尔 | — | 释放时解冻被冻住的符卡使 | 战斗 |
| `spell_cutin.first_duration_sec` / `repeat_duration_sec` | 数字 | 秒 | 1.2 / 0.6【框架】 | 战斗 |
| `spell_cutin.shorten_scope` | 字符串 | — | 缩短按「同一关同一张符卡」计 | 战斗 |
| `combo.chain_window_sec` | 数字 | 秒 | 连击间隔 1.0 | 战斗 |
| `combo.display_from` | 整数 | 次 | ×3 起显示 | 战斗 |
| `slowmo.kills_window_sec` / `kills_threshold` | 数字 / 整数 | 秒 / 只 | 0.2 秒内 8 只 | 战斗 |
| `slowmo.spell_kills_threshold` | 整数 | 只 | 符卡击杀 5 只 | 战斗 |
| `slowmo.duration_real_sec` / `time_mult` / `cooldown_real_sec` | 数字 | 秒 / 倍 / 秒 | 0.5 / 0.3【框架】/ 8 | 战斗 |
| `damage.rounding` | 字符串 | — | 四舍五入（0.5 远离 0） | 战斗 |
| `damage.armor_feedback_ratio` / `_throttle_sec` | 数字 | 比例 / 秒 | 削掉 ≥ 50% 提示「护甲」，0.5 秒一次 | 战斗 |
| `damage.attack_mult_categories` | 数组 | — | 攻击加成的分类（同类加、异类乘） | 战斗 |
| `damage.damage_mult_buckets` | 数组 | — | 伤害倍率桶：易伤、联动 | 战斗 |
| `placement.place_delay_sec` | 数字 | 秒 | 放置后多久开始攻击 | 战斗 |
| `placement.max_copies_per_character` | 整数 | 个 | 同一角色最多放几个。已定为 3（2026-09-27） | 制作人 |
| `character_levels.max_level` | 整数 | 级 | 局内最高 3 级，即每个角色升 2 次。已和数值策划对齐 | 战斗/数值 |
| `buff_offers.every_n_waves_cleared` / `choices` | 整数 | 波 / 个 | 每 3 波三选一 | 战斗/系统 |
| `buff_offers.scope` | 字符串 | — | 强化作用范围 `per_level`，待拍板 | 制作人/系统 |
| `fog.range_penalty_cells` / `min_range_cells` | 数字 | 格 | 浓雾射程 −1，最少 1 | 战斗 |
| `performance.max_projectiles` / `max_damage_numbers` / `max_kill_orbs` | 整数 | 个 | 性能上限 300 / 40 / 60 | 程序/战斗 |
| `rng.seeded_per_battle` | 布尔 | — | 每局一个随机种子 | 程序 |

## stats.json

顶层 `armor_floor_ratio`、`min_damage` 是已定的全局常量。其余数字仍是占位，待数值策划确认。

| 字段 | 类型 | 单位 | 含义 |
| --- | --- | --- | --- |
| `armor_floor_ratio` | 数字 | 比例 | 护甲保底：伤害不低于攻击 × 该值。已定 0.2 |
| `min_damage` | 整数 | 点 | 非无敌命中取整后的最少伤害。已定 1 |
| `guard.max_hp` | 整数 | 点 | 守护点生命 |
| `economy.starting_spirit` | 整数 | 灵力 | 开局灵力 |
| `economy.early_call_reward_per_sec` | 数字 | 灵力/秒 | 提前叫波每剩 1 秒奖励 |
| `economy.early_start_reward_per_sec` | 数字 | 灵力/秒 | 布阵期提前开始每剩 1 秒奖励 |
| `spell_charge.per_damage` | 数字 | 能量/点伤害 | 每点有效伤害充能 |
| `spell_charge.per_kill_default` | 数字 | 能量 | 敌人没填 `charge_on_kill` 时的默认值 |
| `characters.<id>.cost` | 整数 | 灵力 | 放置费用 |
| `characters.<id>.upgrade_costs` | 整数数组 | 灵力 | 升到 2 级、3 级的费用 |
| `characters.<id>.sell_refund_ratio` | 数字 | 比例 | 卖出返还已花费用的比例 |
| `characters.<id>.copy_cost_increase_ratio` | 数字 | 比例 | 第 2、第 3 个同名角色相对上一个的费用递增比例。已允许最多 3 个，比例仍是占位 |
| `characters.<id>.base_attack` | 数字 | 点 | 基础攻击 |
| `characters.<id>.level_attack_mult` | 数字数组 | 倍 | 1、2、3 级攻击倍率，共 3 项（升 2 次）。数字仍是占位 |
| `characters.<id>.crit_chance` / `crit_mult` | 数字 | 比例 / 倍 | 暴击率、暴击倍率 |
| `enemies.<id>.max_hp` / `armor` | 数字 | 点 | 血量、护甲 |
| `enemies.<id>.spirit_drop` | 整数 | 灵力 | 击杀掉落灵力 |
| `enemies.<id>.leak_damage` | 整数 | 点 | 漏怪扣守护点多少 |
| `enemies.<id>.charge_on_kill` | 数字 | 能量 | 击杀充能 |
| `bosses.<id>.*` | — | — | 同上；Boss 的 `leak_damage` 是每次折返扣多少 |
| `skills.<id>.damage_coef` | 数字 | 倍攻击 | 技能伤害系数（0 = 不造成伤害） |
| `statuses.st_burn.tick_damage_coef` | 数字 | 倍攻击 | 灼烧每跳伤害系数 |
| `spell_cards.<id>.*_coef` | 数字 | 倍攻击 | 符卡伤害系数（每跳 / 每颗 / 每把） |
| `buffs.<id>.*` | 数字 | 见字段名 | 强化每层数值和质变数值 |

## characters.json

| 字段 | 类型 | 单位 | 含义 | 归属 |
| --- | --- | --- | --- | --- |
| `id` | 字符串 | — | `chr_<PR #2 角色 id>` | 战斗 |
| `name_key` | 字符串 | — | 显示名文本 key（PR #2 已有） | 文案 |
| `playable_status` | 字符串 | — | `confirmed` / `pending_producer`（PR #2 待定的三人） | 制作人 |
| `mvp` | 布尔 | — | 是否能在 MVP 里放置。紫为 false | 战斗 |
| `mvp_appearance` | 字符串 | — | 可选。紫为 `story_gap_peek_once`：MVP 只通过隙间探头演示一次换位 | 战斗 |
| `role` | 字符串 | — | 定位标签，只给人看 | 战斗 |
| `tags` | 数组 | — | 机制标签，如 `fade_immune` | 战斗 |
| `attack.type` | 字符串 | — | 攻击类型，见 characters.md 第 3 节 | 战斗 |
| `attack.range_cells` | 数字 | 格 | 射程（圆形） | 战斗 |
| `attack.interval_sec` | 数字 | 秒 | 攻击间隔 | 战斗 |
| `attack.initial_delay_sec` | 数字 | 秒 | 放置后第一次攻击的延迟 | 战斗 |
| `attack.targeting` | 字符串 | — | 选敌规则：`closest_to_guard` / `highest_current_hp` / `highest_max_hp` | 战斗 |
| `attack.count` | 整数 | 发 | 一次发几发 | 战斗 |
| `attack.heavy` | 布尔 | — | 是否每击都算重击 | 战斗 |
| `attack.can_crit` | 布尔 | — | 能否暴击 | 战斗 |
| `attack.knockback_cells` | 数字 | 格 | 每击击退 | 战斗 |
| `attack.blocked_by_icicle` | 布尔 | — | 是否被冰柱挡住 | 战斗 |
| `attack.damage_tags` | 数组 | — | 伤害标签，联动用（`fire`、`ice`…） | 战斗 |
| `attack.applies_statuses[]` | 数组 | — | 命中附加的状态：`status_id`、`strength`（0–1）、`duration_sec`（秒） | 战斗 |
| `attack.projectile.speed_cells_per_sec` | 数字 | 格/秒 | 弹速 | 战斗 |
| `attack.projectile.turn_deg_per_sec` | 数字 | 度/秒 | 追踪转向速度，0 = 直线 | 战斗 |
| `attack.projectile.lifetime_sec` | 数字 | 秒 | 弹体寿命 | 战斗 |
| `attack.projectile.hit_radius_cells` | 数字 | 格 | 碰撞半径 | 战斗 |
| `attack.projectile.retarget_radius_cells` | 数字 | 格 | 目标死后在多大范围内换目标 | 战斗 |
| `attack.projectile.pierce` | 整数 | 个 | 穿透数 | 战斗 |
| `attack.line_width_cells` | 数字 | 格 | 直线攻击宽度（魔理沙） | 战斗 |
| `attack.splash_radius_cells` | 数字 | 格 | 溅射半径 | 战斗 |
| `attack.spread_deg` | 数字 | 度 | 多发弹体的扇形角 | 战斗 |
| `attack.ignores_fog` | 布尔 | — | 不受浓雾射程惩罚（紫） | 战斗 |
| `attack.bonus_vs_tags[]` | 数组 | — | 对某标签的加成：`tag`、`bucket`、`add` | 战斗 |
| `attack.leaves_terrain` | 对象 | — | 命中处留下地形（妹红） | 战斗 |
| `attack.heavy_every_n_hits` / `heavy_knockback_cells` | 整数 / 数字 | 次 / 格 | 每第 N 击重击及其击退（美铃） | 战斗 |
| `skills[].id` | 字符串 | — | `skl_<角色>_<名>` | 战斗 |
| `skills[].trigger` | 字符串 | — | `auto_cooldown`（冷却好就放）/ `passive_aura` / `on_marked_enemy_death` | 战斗 |
| `skills[].cooldown_sec` / `initial_delay_sec` | 数字 | 秒 | 冷却和首次延迟 | 战斗 |
| `skills[].requires_target_in_range` | 布尔 | — | 射程内有敌人才放 | 战斗 |
| `skills[].effect` | 对象 | — | 技能效果，`type` 决定其余字段 | 战斗 |
| `spell_card_ids` / `default_spell_card_id` | 数组 / 字符串 | — | 该角色的符卡和按钮默认放的那张 | 战斗 |
| `levels[].level` | 整数 | 级 | 1–3 | 战斗 |
| `levels[].visual.sprite_variant` | 字符串 | — | 角色小人/立绘变体资源名 | 战斗/美术 |
| `levels[].visual.aura_vfx` | 字符串 | — | 身边常驻特效，空字符串 = 没有 | 战斗/美术 |
| `levels[].visual.projectile_vfx` | 字符串 | — | 弹幕外观 | 战斗/美术 |
| `levels[].visual.scale` | 数字 | 倍 | 体型缩放 | 战斗 |
| `levels[].behavior_mods[]` | 数组 | — | `{op: "set"/"add", path: "字段路径", value}`，升级时改行为；技能用 `skills.<技能id>.字段` | 战斗 |

## enemies.json

| 字段 | 类型 | 单位 | 含义 | 归属 |
| --- | --- | --- | --- | --- |
| `id` | 字符串 | — | `enm_shade_<类型>` | 战斗 |
| `name_key` | 字符串 | — | 建议 `enemy.<类型>.name`，待文案新增 | 文案 |
| `narrative_ref` | 字符串 | — | PR #2 的叙事对应，只给人看 | — |
| `status` | 字符串 | — | `mvp` / `reserved`（预留） | 战斗 |
| `tags` | 数组 | — | `shade`、`outside_object`、`armored`、`elite`、`stealth` 等 | 战斗 |
| `move_speed_cells_per_sec` | 数字 | 格/秒 | 基础移速 | 战斗（数值可调） |
| `attacks_units` | 布尔 | — | 是否攻击角色（残影都是否） | 战斗 |
| `hit_radius_cells` | 数字 | 格 | 受击半径 | 战斗 |
| `knockback_resist` | 数字 | 比例 | 击退抗性，0.5 = 击退减半 | 战斗 |
| `armor_feedback` | 布尔 | — | 是否显示「护甲」提示 | 战斗 |
| `immunities` | 数组 | — | 免疫的状态 ID | 战斗 |
| `lateral_jitter_cells` | 数字 | 格 | 纯视觉的左右晃动幅度 | 战斗 |
| `stealth` / `on_death_spawn` / `aura_terrain` | 对象 | — | 预留敌人的特殊行为 | 战斗 |
| `visual.*` | 字符串 / 数字 | — | 资源名和缩放 | 美术 |
| `state_machine.states` | 数组 | — | 敌人状态列表，见 enemies_and_bosses.md | 程序 |

## bosses.json

| 字段 | 类型 | 单位 | 含义 | 归属 |
| --- | --- | --- | --- | --- |
| `id` | 字符串 | — | `boss_<角色>` | 战斗 |
| `move_speed_cells_per_sec` | 数字 | 格/秒 | 移速 | 战斗 |
| `knockback_immune` | 布尔 | — | 免疫击退 | 战斗 |
| `status_conversions[]` | 数组 | — | 状态转换：`from` 状态改成 `to` 状态，`strength` 强度，`keep_duration` 是否保留时长；`to: "none"` = 直接免疫 | 战斗 |
| `immune_to_effects` | 数组 | — | 免疫的效果类型（隙间换位、送回） | 战斗 |
| `affected_by_terrain` | 布尔 | — | 是否受地形影响 | 战斗 |
| `on_reach_guard` | 字符串 | — | 已定为 `loop_to_spawn`：扣血后回到裂缝（2026-09-27） | 战斗 |
| `reach_guard_deals_leak_damage` | 布尔 | — | 走到守护点时是否扣 `leak_damage`。已定为 true | 战斗 |
| `reach_guard_keeps_hp_and_phase` | 布尔 | — | 折返时是否保持当前血量和阶段。已定为 true | 战斗 |
| `victory` | 字符串 | — | Boss 关胜利条件。已定为 `must_defeat` | 战斗 |
| `phase_transition.clamp_hp_at_threshold` | 布尔 | — | 血量卡在阈值 | 战斗 |
| `phase_transition.invulnerable_sec` | 数字 | 秒 | 切阶段无敌 1.5 | 战斗 |
| `phase_transition.stop_moving_while_invulnerable` | 布尔 | — | 无敌时站定 | 战斗 |
| `phase_transition.clear_previous_phase_terrain` | 布尔 | — | 清掉上一阶段地形 | 战斗 |
| `phases[].hp_ratio_start` | 数字 | 比例 | 该阶段从多少血开始 | 战斗 |
| `phases[].spell_card_id` | 字符串 | — | 该阶段符卡 | 战斗 |
| `phases[].cast_on_enter` | 布尔 | — | 进入阶段立即施放 | 战斗 |
| `phases[].repeat_interval_sec` | 数字 | 秒 | 阶段内重复施放间隔，0 = 不重复 | 战斗 |
| `phases[].level_hook` | 字符串 | — | 关卡脚本可以监听的事件名 | 关卡 |

## statuses.json

| 字段 | 类型 | 单位 | 含义 |
| --- | --- | --- | --- |
| `id` | 字符串 | — | `st_<名>` |
| `target_kind` | 字符串 | — | `enemy` / `unit`（角色） |
| `effect.type` | 字符串 | — | `move_speed_mult` / `hard_stop` / `block_status` / `damage_taken_bucket_add` / `damage_over_time` / `hard_stop_store_damage` / `damage_immune` / `unit_disable` / `marker` / `mark_for_owner_trigger` |
| `default_duration_sec` | 数字 | 秒 | 来源没指定时的时长；0 = 区域绑定 |
| `zone_bound` | 布尔 | — | 是否跟随区域进出 |
| `stacking` | 字符串 | — | `strongest_only` / `single_instance` / `single_instance_refcount_zones` |
| `same_source` | 字符串 | — | 同一来源再次施加：`refresh_duration` / `extend_to_max` / `none` |
| `max_strength` | 数字 | 比例 | 强度上限（减速 0.7） |
| `max_chain_sec` | 数字 | 秒 | 连续冻结总时长上限 |
| `blocks_knockback` | 布尔 | — | 期间不被击退 |
| `on_end_apply` | 对象 | — | 结束时附加的状态（免疫） |
| `immune_tags` / `boss_conversion` | 数组 / 对象 | — | 哪些标签的目标免疫；Boss 改成什么 |
| `visual.tint` / `overlay_vfx` / `icon` / `pause_animation` | — | — | 染色、叠加特效、图标、是否暂停动画 |

## terrain.json

| 字段 | 类型 | 单位 | 含义 |
| --- | --- | --- | --- |
| `id` | 字符串 | — | `ter_<名>` |
| `allowed_cell_types` | 数组 | — | 能放在哪种格子上（`empty` 指非路线的空格） |
| `effects[]` | 数组 | — | `enemy_move_speed_mult`（`value` 倍）/ `block_line_attacks` / `block_placement` / `target_range_penalty` / `zone_status` / `disable_unit_on_cell` |
| `owner_bound` | 布尔 | — | 属于某个角色（结界、火焰地面） |
| `on_occupied_cell` | 对象 | — | 生成时格上有角色怎么办（冰柱：冻住角色，不生成） |
| `destroyed_by_spell_tags` | 数组 | — | 被带这些标签的符卡打碎 |
| `affects_boss` | 布尔 | — | 是否影响 Boss |
| `priority` | 整数 | — | 同类地形重叠时优先级高的生效 |
| `stack_with_other_terrain` | 布尔 | — | 区域类，可和别的地形叠加 |
| `visual.telegraph_sec` | 数字 | 秒 | 生成前的地面预警时长 |

## spell_cards.json

| 字段 | 类型 | 单位 | 含义 |
| --- | --- | --- | --- |
| `id` | 字符串 | — | 玩家符卡 `sc_<PR #2 符卡 id>`；Boss 符卡 `sc_boss_<角色>_<符卡 id>` |
| `owner` | 字符串 | — | 所属角色或 Boss ID |
| `name_key` | 字符串 | — | PR #2 的 `spell.<角色>.<符卡>.name`；`spell.cirno.diamond_blizzard.name` 需新增 |
| `user` | 字符串 | — | `player` / `boss` |
| `detail_level` | 字符串 | — | `full`（可直接实现）/ `outline`（概要，后续细化） |
| `portrait` | 字符串 | — | 立绘资源名 |
| `tags` | 数组 | — | `beam`（能打碎冰柱）、`freeze`、`map_change` 等 |
| `mvp_freeze_source` | 布尔 | — | 可选。为 true 时，这张符卡是 MVP 冻结来源之一 |
| `effects[].type` | 字符串 | — | 效果类型，见 spell_cards.md |
| `effects[].*_stats_key` | 字符串 | — | 去 `stats.json` 取数值的路径 |
| `effects[].cells_ref` | 字符串 | — | Boss 符卡引用关卡 `cell_sets` 里的格子集合名 |
| `effects[].fallback` | 对象 | — | 关卡没给格子集合时的兜底选格规则 |
| `effects[].telegraph_sec` | 数字 | 秒 | 地面预警 |
| `effects[].duration_sec` | 数字 | 秒 | -1 = 持续到 Boss 被击败 |
| `direction_rules.best_of_8` | 对象 | — | 极限火花 8 方向自动选择规则 |

## synergies.json

| 字段 | 类型 | 含义 |
| --- | --- | --- |
| `discovery.*` | — | 发现提示规则：存进存档、首次弹窗、之后小字节流 |
| `id` | 字符串 | `syn_<名>` |
| `draft_name` | 字符串 | 草案中文名，正式文本走 `name_key` |
| `status` | 字符串 | `confirmed_framework`（框架）/ `draft`（草案） |
| `requires.characters_any` / `characters_all` | 数组 | 需要场上有其中任一 / 全部角色 |
| `requires.freeze_source` | 布尔 | 需要某种冻结来源 |
| `mvp_freeze_sources` | 数组 | MVP 里允许触发冰碎的冻结来源 ID。已定为 `buff_frost_frog`、`sc_boss_cirno_perfect_freeze` |
| `trigger.event` | 字符串 | `on_hit` / `on_gap_move` / `on_spell_cast` |
| `trigger.check_step` | 字符串 | 在伤害流水线第几步判定 |
| `trigger.attacker_character` / `attacker_damage_tag` / `target_has_status` | 字符串 | 条件 |
| `effect.bucket` / `add` | 字符串 / 数字 | 放进哪个桶、加多少 |
| `effect.force_heavy` / `force_crit` | 布尔 | 强制重击 / 强制暴击 |
| `effect.remove_target_status` / `remove_at_step` | 字符串 | 命中后移除的状态和时机 |

## buffs.json

| 字段 | 类型 | 含义 | 归属 |
| --- | --- | --- | --- |
| `offer_rules.*` | — | 三选一规则 | 战斗/系统 |
| `id` | 字符串 | `buff_<名>` | 战斗 |
| `mvp_freeze_source` | 布尔 | 可选。为 true 时，该强化是 MVP 冻结来源之一 | 战斗 |
| `draft_name` / `narrative_item` | 字符串 | 草案名 / 失物包装建议 | 文案/系统 |
| `name_key` / `desc_key` | 字符串 | `buff.<名>.name` / `.desc`，待文案新增 | 文案 |
| `category` | 字符串 | 强化类别 | 战斗 |
| `max_stacks` | 整数 | 最多层数 | 战斗 |
| `offer_weight` | 整数 | 抽选权重 | 系统 |
| `requires_characters_any` | 数组 | 本关带了这些角色之一才会出现 | 战斗 |
| `per_stack[]` | 数组 | 每层效果；数值用 `stats_key` 去 `stats.json` 取 | 战斗（数值归数值） |
| `thresholds[].stacks` | 整数 | 质变层数 | 战斗 |
| `thresholds[].override` / `add` | 对象 | 替换或追加的效果 | 战斗 |
| `thresholds[].unit_visual` | 字符串 | 质变后的外观特效 | 战斗/美术 |
| `thresholds[].feedback_event` | 字符串 | 质变反馈事件 | 战斗 |

## feel.json

全部归战斗策划。字段名直接对应 feedback.md 反馈事件表里的数字：`hit_flash`（闪白）、`damage_numbers`（伤害数字）、`screen_shake`（震屏）、`kill_burst`（光点）、`spirit_counter_bump`（灵力跳动）、`spell_button`、`spell_cutin`、`combo`、`slowmo`、`armor_feedback`、`guard_alert`、`guard_damage_vignette`、`synergy_popup`、`boss`、`wave_banner`、`early_call`、`level_up`、`buff_threshold`、`freeze`、`unit_frozen`。单位：`*_sec` 秒（演出时间，真实时间 × 倍速），`*_px` 像素（1080×1920 逻辑分辨率），`*_alpha` 0–1 不透明度，`*_scale` 倍数，颜色是 `#RRGGBB`，`*_key` 是文本 key。
