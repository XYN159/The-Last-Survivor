# 伤害流水线、状态、联动判定

> 状态：草案（战斗策划）。伤害公式和全部数字归数值策划，唯一来源是 PR #8 的 `stats.json`。保底常量在它的顶层：`armor_floor_ratio`、`min_damage`。公式是 `伤害 = max(攻击 − 护甲, 攻击 × armor_floor_ratio)`，取整后不少于 `min_damage`。本文件只定**顺序和堆叠规则**，不写具体数字。
> 对应配置：`statuses.json`、`synergies.json`、`rules.json` 的 `damage` 段（取整、护甲提示、倍率桶、多发拆分）。数值读 PR #8 的 `stats.json`。

## 1. 术语

| 术语 | 含义 |
| --- | --- |
| 命中请求 | 一次「某攻击者对某目标造成一次伤害」的请求。即时攻击、弹体碰撞、持续伤害跳伤、符卡每一跳都各算一次。 |
| 攻击力（A） | 流水线第 ① 步算出来的数。 |
| 桶 | 同类倍率放进一个桶。**桶内相加，桶间相乘**。 |
| 易伤桶 | 目标身上「更容易受伤」的效果。灵梦结界（`statuses.st_barrier_mark.vulnerability_add`）属于这里。 |
| 联动桶 | 攻击者和目标之间的组合效果。冰碎（`synergies.syn_ice_shatter.synergy_add`）属于这里，早苗对「外界之物」的特攻也放这里。 |
| 重击 | 暴击，或者技能标记 `heavy: true` 的命中，或者联动标记 `force_heavy` 的命中。重击飘黄色放大数字并轻微震屏。 |

## 2. 单次命中的伤害流水线【战斗策划决定 2】

每个命中请求在 tick 第 ⑧ 步按下面 9 步结算：

1. **算攻击力**
   `A = 基础攻击 × 局内等级倍率 × 技能系数 × Π(1 + 该类加成之和)`
   - 基础攻击、局内等级倍率：`characters.<id>.base_attack`、`characters.<id>.level_attack_mult`【数值·PR #8】。
   - 技能系数：普通攻击为 1；符卡、技能的系数是 `spell_cards.<id>.damage_coef`、`skills.<id>.damage_coef` 等【数值·PR #8】。
   - 多发攻击（2、3 级多发、「分裂」强化、咲夜飞刀）：先按整次攻击算出 A，再平分给每一发，见 2.2。
   - 加成分类（`rules.json` → `damage.attack_mult_categories`）：`buff`（roguelite 强化）、`aura`（光环，比如大妖精）、`temp`（临时效果，比如连击狂热）。**同一类的百分比相加，不同类之间相乘**。例子：两层「锐利」（每层 +x，同类）→ ×(1 + 2x)；再有大妖精光环 +y（异类）→ (1 + 2x) × (1 + y)。
2. **暴击判定**
   - 攻击的 `can_crit` 为真时，按暴击率掷骰（每局种子随机数）。暴击则 `A = A × 暴击倍率`。暴击率、暴击倍率是 `characters.<id>.crit_chance`、`crit_mult`【数值·PR #8】。
   - 联动「符札引爆」在这一步强制暴击。
   - 持续伤害（灼烧）不暴击。
3. **护甲**
   - 有效护甲 = `max(0, 护甲 − 破甲)`。破甲效果在这一步之前减护甲（目前草案里没有破甲来源，预留）。
   - `D = max(A − 有效护甲, A × armor_floor_ratio)`。`armor_floor_ratio` 读 `stats.json` 顶层。
   - 记下「被护甲削掉的比例」 `r = (A − D) / A`，第 ⑥ 步后用于硬残影提示。
4. **易伤与联动倍率**
   - `易伤倍率 V = 1 + Σ易伤桶`（结界 `statuses.st_barrier_mark.vulnerability_add`；同一个敌人不管同时处在几个结界里，结界标记只算一次）。
   - `联动倍率 S = 1 + Σ联动桶`（冰碎、冰火交加、早苗特攻……各自的 `synergies.<id>.synergy_add`）。
   - `D2 = D × V × S`。
   - 例子：硬残影（护甲 `enemies.enm_shade_armored.armor`，记作 R）被魔理沙打中（攻击力 A），它在结界里（易伤 v）并且被冻住（冰碎 s）：D = max(A − R, A × armor_floor_ratio)；D2 = D × (1 + v) × (1 + s)。
5. **取整**：`最终伤害 = max(min_damage, 四舍五入(D2))`。`min_damage` 读 `stats.json` 顶层。四舍五入指 0.5 远离 0，对应 GDScript 的 `roundi()`。目标处于无敌（`st_invulnerable`）时，最终伤害为 0，跳过第 6–9 步，只飘灰色「无效」（节流 0.5 秒）。
6. **扣血**：`hp -= 最终伤害`。记录「有效伤害」= `min(最终伤害, 扣血前的 hp)`，用于符卡充能，避免溢出伤害虚增能量。
   - 如果目标有 `armor_feedback` 且 `r ≥ 0.5`，发出「护甲」反馈事件（同一敌人 0.5 秒内只发一次）【战斗策划决定 4】。
   - 如果 hp ≤ 0：目标标记为死亡，**跳过第 7、8 步**，第 9 步照常执行，死亡结算留到 tick 第 ⑨ 步。
7. **附加状态**：先执行本次命中触发的「移除状态」（冰碎、冰火交加移除冻结），再附加这次命中带的状态（减速、冻结几率、符札标记等）。
   - 因为状态在伤害**之后**才附加，**同一击先冻后碎不成立**：一次命中不会既冻结目标又享受冰碎加成。
   - 冰碎移除冻结后，冻结结束的 `on_end_apply` 会给目标一段冻结免疫（`statuses.st_freeze_immune.duration_sec`），所以同一击的冻结几率也不会马上把它重新冻住。
8. **击退**：按第 core_rules 3.3 节执行（冻结、时停、Boss 不被击退）。
9. **符卡充能**：`能量 += 有效伤害 × 每点伤害充能 × 充能倍率`。符卡自己造成的伤害不充能（`spell_energy.charge_from_spell_damage = false`）。击杀那部分能量在 tick 第 ⑨ 步加。详见 spell_cards.md。

### 2.1 伪代码（给程序对照）

```
func resolve_hit(req):
    if req.target.dead: return
    var a = base_attack(req.attacker) * level_mult(req.attacker) * req.skill_coef
    for cat in ["buff", "aura", "temp"]:
        a *= 1.0 + sum_pct(req.attacker, cat)
    a *= req.split_share            # 多发攻击：每一发 = 1 / 发数，见 2.2；单发为 1
    var heavy = req.heavy
    if req.can_crit and (rng.randf() < crit_chance(req.attacker) or synergy_forces_crit(req)):
        a *= crit_mult(req.attacker); heavy = true
    var armor = max(0, req.target.armor - armor_break(req.target)) * req.split_share   # 多发时护甲也按 1 / 发数 扣
    var d = max(a - armor, a * armor_floor_ratio)
    var armor_ratio = (a - d) / a
    var v = 1.0 + sum_bucket(req, "vulnerability")
    var s = 1.0 + sum_bucket(req, "synergy")
    heavy = heavy or synergy_forces_heavy(req)
    var final = 0 if req.target.invulnerable else max(min_damage, roundi(d * v * s))
    ...
```

### 2.2 多发攻击：总伤害不变（回应数值策划，2026-10-02）

2 级、3 级的多发升级（灵梦 2 级 2 张符札、3 级 3 张；咲夜 3 把飞刀，升级到 4、5 把）**一次攻击的总伤害不变**，平分给每一发（`rules.json` → `damage.multi_shot_split`）。多发的好处是能打到更多目标、更稳，不是总伤害翻倍。

1. 先按第 1 步算出这一次攻击的攻击力 A（等级倍率、强化、光环都算进去）。发数记作 n（`attack.count`）。
2. 每一发的攻击力 = A ÷ n（`split_share`，配置 `per_shot_skill_coef = 1/count`）。
3. 每一发扣的护甲也是 护甲 ÷ n（`per_shot_armor = armor/count`）。所以 n 发都打中同一个目标时，护甲后的总伤害 = max(A − 护甲, A × armor_floor_ratio)，和单发完全一样。升级不会让角色打硬残影反而变弱。
4. 每一发各自掷暴击（`crit_roll = per_shot`）、各自取整、各自吃联动。取整和 `min_damage` 可能让总数差 1 点左右，可以接受。
5. 某一发打空了，那一发的伤害就丢了，不转给别的子弹。多发打到不同目标时，每个目标只吃到自己那一份。
6. 符卡充能按每一发的有效伤害各自算，加起来和单发时一样。

例外：写明「每颗」「每跳」系数的不拆分，按各自的系数算，因为数值策划的系数本来就是按每颗定的：符卡（梦想封印的光弹、极限火花的每一跳、杀人玩偶的飞刀），以及强化「分裂弹」额外生成的小子弹（每颗 `buffs.buff_split_shot.split_damage_ratio`，是额外伤害，不从原攻击里分）。

## 3. 状态表【战斗策划决定 3】

所有状态定义在 `statuses.json`。下表是 MVP 必需的状态和后续角色会用到的状态。

| ID | 挂在 | 效果 | 默认时长 | 叠加规则 | 免疫 | 视觉 | MVP |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `st_slow` | 敌人 | 移速 × (1 − 强度)，强度上限 `statuses.st_slow.max_strength` | 由来源决定，琪露诺普攻读 `characters.chr_cirno.normal_effect`（`value` 是强度，`param` 是秒数） | 不叠加，只取最强的一个；同一来源再次命中刷新时长；不同来源共存但只有最强的生效，最强的到期后次强的接着生效 | 无（Boss 也吃，但总倍率下限 0.5） | 淡蓝色调 + 寒气粒子 | 是 |
| `st_freeze` | 敌人 | 速度为 0，不被击退，动画暂停 | 由来源决定（技能 `skills.skl_cirno_freeze.freeze_sec`、符卡 `spell_cards.sc_perfect_freeze.freeze_sec`、寒气 `buffs.buff_frost_frog.freeze_sec`、冰之残影 `terrain.ter_ice.stop_on_declare_sec`） | 单实例。已冻住时再被冻：时长取「剩余」和「新时长」的较大值；但同一次连续冻结总时长有上限（`statuses.st_freeze.max_chain_sec`） | Boss 免疫，改为 `st_slow`、同样时长（强度：完美冻结读 `spell_cards.sc_perfect_freeze.boss_slow_strength`，其他来源 0.5【草案默认值】）；有 `st_freeze_immune` 时无法冻结（符卡带 `ignore_immunity` 例外） | 冰块包裹 | 是 |
| `st_freeze_immune` | 敌人 | 阻止 `st_freeze` | `statuses.st_freeze_immune.duration_sec` | 单实例，刷新 | — | 融水滴 | 是 |
| `st_barrier_mark` | 敌人 | 易伤桶 + `statuses.st_barrier_mark.vulnerability_add` | 区域绑定：进入结界挂上，离开移除；「博丽与八云」联动会挂一个 4 秒的限时版本 | 单实例，用引用计数：记录「有几个结界区域 + 几个限时来源」在给它挂标记，计数归零才移除。数值只算一次 | 无 | 头顶红白札 | 是 |
| `st_ofuda_tag` | 敌人 | 标记，供联动「符札引爆」使用 | 1.5 秒 | 单实例，刷新 | — | 身上贴一张小札 | 是 |
| `st_invulnerable` | 敌人（Boss） | 伤害为 0，不接受新状态，不被击退 | `boss_rules.phase_invuln_sec` | 单实例 | — | 宣言光环 | 是 |
| `st_unit_frozen` | 角色 | 不攻击、技能和冷却暂停，不能升级卖出；连点破冰待拍板（DI-13，数据先写 3 下） | 由来源决定。冰之残影读 `terrain.ter_ice.stop_on_declare_sec`（用户已确认的值在 PR #8） | 单实例，取较大值 | 结束后挂 `st_unit_freeze_immune` | 角色被冰块包住 | 是（冰之残影） |
| `st_unit_pounced` | 角色 | 被扑人残影扑中：短暂停止攻击和技能（推荐行为）。不影响升级卖出 | 秒数待 PR #8 补（建议字段 `enemies.enm_shade_pouncer.pounce_disable_sec`） | 单实例，刷新 | — | 灰色手印 | 否（扑人残影，第三章） |
| `st_unit_freeze_immune` | 角色 | 阻止 `st_unit_frozen` | `statuses.st_unit_freeze_immune.duration_sec` | 单实例 | — | 融水滴 | 是 |
| `st_burn` | 敌人 | 每 0.5 秒一次持续伤害，每跳系数 `statuses.st_burn.tick_damage_coef`（走流水线第 3–9 步，不暴击、不击退、不附加状态） | 3.0 秒 | 不叠加，取伤害最高的一个；同一来源刷新时长 | 无 | 小火苗 | 否（妹红） |
| `st_hold` | 敌人 | 速度为 0（「拦住」，**不是**冻结，不能冰碎），可以被击退 | 1.2 秒 | 单实例，取较大值；结束后 1 秒 `st_hold_immune` | Boss 改为减速 0.5 | 气劲光圈 | 否（美铃符卡「极彩台风」） |
| `st_blocked` | 敌人 | 被美铃挡住：停在美铃面前的路线格上，不前进，转为攻击美铃（`enemies.<id>.block_dps`）。**不是**冻结，不能冰碎；不被普通击退推开 | 挡住期间一直在；美铃被打倒、被卖掉，或被挡的敌人被击退离开那一格时移除 | 每个美铃最多同时挡 `characters.chr_meiling.block_count` 个（用户确认 2 个），先到先挡 | Boss 和飞行残影（`enm_shade_flying`，推荐行为）不能被挡，直接走过去 | 气劲光圈 + 美铃举手架势 | 否（美铃） |
| `st_time_stop` | 敌人 | 速度为 0，期间受到的伤害先记账，结束时一次性结算为一次重击 | 3.0 秒 | 单实例 | Boss 改为减速 0.7 | 灰色钟面 | 否（咲夜） |
| `st_gap_daze` | 敌人 | 速度为 0，表现为从隙间出来后晕头转向 | 0.6 秒 | 单实例，刷新 | Boss 免疫 | 眼睛漩涡 | 否（紫） |
| `st_registered` | 敌人 | 忘的「登记」：带着这个标记死亡时，给忘生成一个失物帮手 | 4.0 秒 | 单实例，刷新 | Boss 免疫 | 头顶编号牌 | 否（忘） |

### 3.1 冻结的完整规则

1. 冻结来源：琪露诺技能「冰结」、琪露诺玩家符卡「完美冻结」（冻 `spell_cards.sc_perfect_freeze.freeze_sec`）、冰之残影二阶段符卡（连残影一起冻）、强化「寒气」的几率冻结和它 2 层「青蛙冰雕」的碎片。冰之残影冻住角色（`st_unit_frozen`）和残影的秒数都读 `terrain.ter_ice.stop_on_declare_sec`。**MVP 来源是三个**：第一章第 2 关起的琪露诺本人 `chr_cirno`（`unlock` = `ch1_01_clear`，冰碎可以自然触发）、`buff_frost_frog`（含青蛙冰雕）、冰之残影二阶段 `sc_boss_cirno_perfect_freeze`。
2. 附加冻结时依次检查：目标是 Boss → 改成减速；目标有 `st_freeze_immune` 且来源没有 `ignore_immunity` → 失败；目标已冻结 → 按叠加规则延长；否则新建冻结。
3. 冻结期间：速度 0，不被击退，攻击照样能打到它，减速等其他状态照常计时。
4. 冻结结束（自然到期、被冰碎移除、被冰火交加融化）→ 立即获得冻结免疫（`statuses.st_freeze_immune.duration_sec`），防止永冻。
5. 被紫传送的冻结敌人保持冻结状态。

### 3.2 结界区域

- 结界是地形效果 `ter_barrier`（区域类），由灵梦的技能「结界」生成，也可以由符卡或强化生成。
- 敌人在第 ④ 步被判定位于结界范围内（位置点落在区域格子里）就挂 `st_barrier_mark`，离开就把计数减 1。
- 结界到期消失时，对里面所有敌人把计数减 1。

## 4. 联动判定

联动在 `synergies.json` 里定义，每条有「触发事件」「条件」「效果」。判定时机：

| 触发事件 | 在哪一步判定 | 例子 |
| --- | --- | --- |
| `on_hit` 且影响暴击 | 流水线第 2 步 | 符札引爆 |
| `on_hit` 且进桶 | 流水线第 4 步：检查条件，把加成放进对应桶；需要移除的状态记下来，在第 7 步移除 | 冰碎、冰火交加、门番的一条直线、冻结的时刻 |
| `on_gap_move` | 紫的技能或符卡执行位移之后 | 博丽与八云 |
| `on_spell_cast` | 符卡效果开始执行时 | 境界火花 |

### 4.1 冰碎（`syn_ice_shatter`）【框架】

- 条件：攻击者是魔理沙（普通攻击、符卡「极限火花」的每一跳都算），目标在第 4 步判定时处于 `st_freeze`。
- 效果：联动桶 +1.0（即 ×2），本次命中强制算重击，第 7 步移除冻结，播放碎冰特效和音效。
- 极限火花一跳碎冰后，目标获得冻结免疫，后面几跳不再有冰碎加成（符合直觉：冰已经碎了）。
- 同一击先冻后碎不成立（见流水线第 7 步）。

### 4.2 结界加护（`syn_barrier_bonus`）【框架】

- 数值本身由 `st_barrier_mark` 提供（易伤桶 `statuses.st_barrier_mark.vulnerability_add`），这条联动只负责「发现联动」弹窗：第一次有攻击打到带结界标记的敌人时弹出。

### 4.3 「发现联动」提示

- 每个联动在**整个存档**里第一次触发时，弹出「发现联动：冰碎！」这类提示 1.6 秒，不暂停逻辑。已发现列表存进存档（字段由程序加到 `SaveGame` 的数据里，比如 `discovered_synergies`）。
- 已发现的联动再次触发时，只在目标头上飘一个小字（比如「冰碎」），同一联动 3 秒内最多一次。
- 文本 key：`combat.synergy_found`（「发现联动：%s！」），联动名 `syn.<name>.name`。需要文案策划加进 `data/text/names_zh.csv`。

## 5. 边界情况

| 情况 | 处理 |
| --- | --- |
| 同一 tick 两次命中打同一个敌人，第一次已打死 | 第二次作废，不产生飘字、不充能。 |
| 伤害算出不到 1 | 取整后不少于 `min_damage`。 |
| 护甲大于攻击 | 伤害 = 攻击 × `armor_floor_ratio`。只要 `armor_floor_ratio` ≤ 0.5，护甲提示一定触发（r = 1 − armor_floor_ratio）。 |
| 冻结中又被琪露诺减速 | 减速照常挂上并计时，冻结结束后如果还没到期就生效。 |
| 结界标记 + 限时标记同时存在 | 引用计数为 2，数值仍然只算一次。 |
| 多发攻击里某一发打空 | 那一发的伤害就丢了，不转给别的子弹。 |
| 持续伤害打死敌人 | 算谁的击杀：施加灼烧的角色。连击、灵力照常。 |
| 时停中记账的伤害 | 时停期间每次命中照常算完第 1–5 步，但不扣血，只把最终伤害记账；时停结束时把记账总和 × `stored_damage_mult` 作为一次命中，从第 6 步开始结算，算重击。 |
