# roguelite 强化

> 状态：草案（战斗策划）。强化的系统结构（稀有度、局外解锁、叙事名称）归系统策划；每层数值、最多层数、质变层数、抽中权重归数值策划，唯一来源是 PR #8 的 `stats.json` → `buffs.<id>.*` 和 `buff_offer.*`，本文只写字段名。战斗策划负责：触发时机草案、叠层和质变的数据结构、每个强化在战斗里的行为。
> 叙事包装采用 PR #2 的建议：残影被击散后留下的「被遗忘之物」，角色捡起来借用它的力量。下表「失物」一栏是建议名，待文案和系统策划确认。
> 对应配置：`data/balance/combat/buffs.json`。

## 1. 什么时候给强化（已拍板，2026-09-27）

1. 每 5 波给一次三选一（PR #8 `buff_offer.every_n_waves` = 5、`buff_offer.choices` = 3，和已拍板一致）。时机：第 5、10、15 波的最后一只出生、进入 `intermission` 空档的那一刻弹出（`buff_offers.offer_trigger_point`）。因为空档不等清场（core_rules.md 4.2），这里也不等这一波的敌人打完。这一波如果已经是本关最后一波，不再弹，直接按胜负结算（`skip_offer_on_final_wave`）。
2. 选择期间逻辑暂停（`buff_select`），空档倒计时也暂停；选完继续。
3. 抽选规则：从强化池里按 `buffs.<id>.offer_weight` 加权随机抽 `buff_offer.choices` 个**不同**的；已经满层的不出；需要特定角色（比如「大结界」需要灵梦）而本关没带这个角色的不出。随机数用每局种子。MVP 只从 `buffs.json` 里 `mvp` 为 true 的强化里抽（`offer_rules.include_only_mvp`）。
4. **保底**：玩家已经拿到、但层数还没到质变门槛的强化，下一次三选一里保底出现其中一个（`pity_owned_below_threshold`）。有好几个都没到质变时，从里面随机保底一个，另外两格仍按权重抽，并且不和保底的那个重复。
5. **只管当局**（`buff_offers.scope` = `per_level`）。过关就清空，不带到下一关。同一个强化可以重复选，用来叠层（`allow_repeat_stacks`），满层之后不再出现。
6. 序章前两关没有三选一（`prologue_levels_without_offer` = 2）。序章第 3 关开始教三选一（`prologue_offer_starts_at_level` = 3）。波数举例见 core_rules.md 第 4.3 节。

## 2. 叠层和质变的数据结构

每个强化在 `buffs.json` 里：

- `max_stacks_stats_key`：最多叠几层，指向 `buffs.<id>.max_stacks`。
- `offer_weight_stats_key`：抽中权重，指向 `buffs.<id>.offer_weight`。
- `per_stack`：每一层都生效的效果（数值从 `stats.json` 按 `stats_key` 取，乘以层数）。
- `thresholds`：达到某层数时额外触发的「质变」。每个质变有：
  - `stacks_stats_key`：达到几层触发，指向 `buffs.<id>.transform_at_stacks`（没有就用 `buff_offer.transform_at_stacks_default`，已拍板 2 层）；
  - `override`（替换每层效果）或 `add`（追加一个新效果）；
  - `unit_visual`：质变后所有相关角色身上的外观变化（成长可见）；
  - `feedback_event`：触发 `buff_threshold_reached` 反馈，屏幕中央横幅 1.2 秒 + 专属音效。

叠加规则：同一个强化的多层之间是**相加**（比如「锐利」2 层 = 2 × `buffs.buff_sharp_ofuda.attack_pct_per_stack`）；不同强化如果都加攻击，按它们的 `attack_category` 分类，同类相加、异类相乘（见伤害流水线第 1 步）。

## 3. 强化清单（12 个）

用户 2026-10-02 定（D-06）：MVP 三选一只抽这 7 个，`mvp` = true：`buff_frost_frog` 寒气、`buff_split_shot` 分裂弹、`buff_crit_charm` 会心、`buff_sharp_ofuda` 锐利、`buff_rapid_fire` 连射、`buff_spell_battery` 充能、`buff_guard_mend` 修补。大结界、穿透、香火、连击狂热、隙间之眼留在表里，`mvp` = false，MVP 抽不到。

「每层效果」里的数字都在 PR #8 的 `buffs.<id>` 下，表里只写字段名。最多层数是 `max_stacks`，质变层数是 `transform_at_stacks`（都是 2）。

| ID | 名称 | 失物（建议） | 每层效果（PR #8 字段） | 2 层质变 |
| --- | --- | --- | --- | --- |
| `buff_split_shot` | 分裂弹 | 断了链的钥匙扣 | 普通攻击命中后分裂出 1 颗小子弹（每层 +1 颗），扇形 60 度飞出，每颗伤害 × `split_damage_ratio`，小子弹不再分裂。小子弹是额外伤害，不从原攻击里分 | **「满天星」**：每次命中改为向四周 360 度分裂 `starfall_sub_bullets` 颗，小子弹还能再分裂一次（最多两代）。满屏子弹【框架例子】 |
| `buff_sharp_ofuda` | 锐利 | 削尖的旧铅笔 | 攻击 + `attack_pct_per_stack`（`buff` 类） | 无 |
| `buff_rapid_fire` | 连射 | 上满弦的发条 | 攻击间隔 + `interval_pct_per_stack`（负数 = 变快） | **「三连发」**：每第 5 次攻击立刻再追加 `burst_extra_attacks` 次（间隔 0.08 秒） |
| `buff_frost_frog` | 寒气 | 褪色的发条青蛙（PR #2 的例子） | 普通攻击命中有 `freeze_chance_per_stack` 几率冻结（秒数 `freeze_sec`，PR #8 待补；受冻结免疫限制）。**MVP 冻结来源之一**（另有第一章第 2 关起的琪露诺本人，以及冰之残影二阶段） | **「青蛙冰雕」**：冻结中的敌人被冰碎或死亡时炸成冰片，1 格内敌人受到 攻击 × `shard_damage_coef` 的伤害并冻结（同一个 `freeze_sec`）；连锁最多 3 层。连锁冻结仍算寒气这一条来源 |
| `buff_crit_charm` | 会心 | 掉漆的招财猫 | 暴击率 + `crit_chance_per_stack` | **「必中之符」**：每次暴击在目标处爆炸，0.8 格范围伤害 × `explosion_coef`（爆炸本身不暴击） |
| `buff_great_barrier` | 大结界 | 褪色的注连绳 | 需要灵梦。结界持续时间 +2 秒 | **「常驻大结界」**：灵梦射程内的所有路线格永久是结界，结界易伤再 + `barrier_vuln_add_at_max` |
| `buff_spell_battery` | 充能 | 还剩一格电的旧电池 | 符卡充能 + `charge_pct_per_stack` | **「连续宣言」**：每次放完符卡返还 `refund_ratio_at_max` 能量 |
| `buff_piercing_star` | 穿透 | 一颗玻璃弹珠 | 弹体多穿透 `pierce_per_stack` 个敌人 | 无 |
| `buff_spirit_greed` | 香火 | 空空的存钱罐 | 每次击杀额外 + `spirit_per_kill_per_stack` 灵力 | 无 |
| `buff_guard_mend` | 修补 | 缝补过的布偶 | 选中时守护点回复 `guard_heal_per_pick` 点 | **「不褪色」**：每次漏怪伤害 − `leak_reduction_at_max`（最少 1） |
| `buff_combo_fever` | 连击狂热 | 转个不停的陀螺 | 连击数每满 10，全队攻击 + `attack_pct_per_10_combo`（`temp` 类），最多 + `cap_pct`；连击断了就归零 | 无 |
| `buff_gap_eye` | 隙间之眼 | 半张旧车票 | 需要紫。隙间换位冷却 + `cooldown_pct_per_stack`（负数 = 变短） | **「隙间回廊」**：每次多换 1 对，被换走的领头敌人额外吃一次紫的重击，系数 `swap_hit_damage_coef`（PR #8 还没有这个字段，已请数值策划补） |

有 2 层质变的强化共 8 个：分裂弹、连射、寒气、会心、大结界、充能、修补、隙间之眼。质变门槛是 2 层（已拍板）。最多层数可以高于门槛（例如最多 3 层的，第 2 层就质变，第 3 层继续叠每层效果）。

PR #8 另外提了 5 个新强化（`buff_boss_slayer`、`buff_armor_break`、`buff_offering_box`、`buff_upgrade_discount`、`buff_spell_power`），只有数值、没有行为。用户 2026-10-02 的 D-06 没有收这 5 个。`buffs.json` 暂时不收，等以后另拍板再补行为。

## 4. 质变的实现细节

### 4.1 满天星（分裂弹 2 层）

- 适用于所有普通攻击。即时类攻击（魔理沙射线、紫的隙间）以每个被命中敌人的位置为分裂起点。
- 小子弹：直线飞行，速度 8 格/秒，寿命 0.5 秒，撞到第一个敌人结算；受冰柱阻挡。
- 第二代小子弹不再分裂。一次命中最多产生 6 + 36 = 42 颗子弹。
- **性能保护**：全场弹体上限 300（`rules.json` → `performance.max_projectiles`）。到上限后新的小子弹不生成（原始攻击照常）。飘字按反馈表的合并规则处理。
- 外观：所有角色的弹幕带星星拖尾（`projectile_star_trail`）。

### 4.2 青蛙冰雕（寒气 2 层）

- 触发：冻结中的敌人被冰碎，或者在冻结状态下死亡。
- 效果：以它为中心 1 格内的其他敌人受到 攻击 × `buffs.buff_frost_frog.shard_damage_coef` 的伤害（算触发者那个角色的攻击），并冻结 `buffs.buff_frost_frog.freeze_sec` 秒（受冻结免疫限制）。
- 连锁：被冰片冻住的敌人之后被冰碎或死亡，又会炸一次。同一个 tick 里连锁深度最多 3 层，超过的留到下一 tick。
- 外观：相关角色身边绕一只小冰青蛙。

### 4.3 常驻大结界（大结界 2 层）

- 灵梦的结界技能改为常驻模式：她射程内所有路线格都是 `ter_barrier`，不再有冷却。
- 多个灵梦的常驻结界重叠时，标记仍只算一次。

## 5. 局内升级的外观字段

局内升级（1–3 级）的外观和特效在 `characters.json` → `levels[].visual`，字段见 [data_reference.md](data_reference.md)。强化质变的外观在 `buffs.json` → `thresholds[].unit_visual`。两者叠加显示：等级决定角色本体和光环，强化质变加额外特效。
