# MVP 验收清单

MVP 是序章 3 关加第一章 4 关，共 7 关。关卡 id 和顺序以 PR #5 `data/levels/index.json` 为准：`prologue_01`、`prologue_02`、`prologue_03`、`ch1_01`、`ch1_02`、`ch1_03`、`ch1_04`。

范围也写在 PR #3 `docs/GDD.md`「MVP」和 `docs/ROADMAP.md` 第 2 节。

打勾规则：

- **数据**：打开对应 PR 分支上的 JSON，或在该分支运行 `python3 tools/validate_levels.py`。对得上就勾。不需要游戏。
- **实机**：等塔防原型合并后，在 Godot 里按顺序打。原型还没有 PR，这些先不要勾。
- **待定**：`DESIGN_ISSUES.md` 里还没对齐。不能勾，也不能改成一个自编的数字再勾。

`main` 上的车道占位不参与本清单（DI-16）。

试玩方法（学习曲线和「不会卡关」共用）：

1. 找没有看过 `docs/design/` 的人，从 `prologue_01` 按解锁顺序打。设计文档没有规定人数，记录实际人数即可。
2. 允许看游戏里的教学句，不允许看外部攻略或策划表。
3. 每一关结束问一句：「这一关新学会的是什么？」对照该关下面的「主教学点」。
4. 若在该教学句出现之前就失败，并且说不出下一步该点哪里，记为卡关。用游戏内的重打再试一次仍如此，这一关的「不会卡关」不通过。

---

## 1. 七关是否就是这份编组

数据来自 PR #5 `docs/design/level/overview.md` 的波次表、`data/balance/level_difficulty.json`，以及各关 JSON 的 `display_name`、`params`、`waves`。

- [ ] 数据：七关都是 `status: complete`，第二章起不在本次验收里（那些文件在 PR #5 是 `stub`）
- [ ] 数据：`prologue_01`「神社的直路」3 波，威胁合计 37，系数 0.68
- [ ] 数据：`prologue_02`「直路的尽头」4 波，威胁合计 55，系数 0.69
- [ ] 数据：`prologue_03`「弯过院子」10 波，威胁合计 218，系数 0.68
- [ ] 数据：`ch1_01`「湖畔薄雾」10 波，威胁合计 214，系数 0.67
- [ ] 数据：`ch1_02`「雾里的弯道」11 波，威胁合计 233，系数 0.62
- [ ] 数据：`ch1_03`「分叉的湖岸」12 波，威胁合计 330，系数 0.75
- [ ] 数据：`ch1_04`「完美冻结」15 波，威胁合计 441，系数 0.70
- [ ] 数据：每波预算等于 `round((10 + 4 × 波次) × 系数)`，和 `wave_threat_budgets` 一致。公式见 PR #5 `docs/design/level/data_format.md`「难度表」
- [ ] 数据：`ch1_01` 的威胁合计 214，低于 `prologue_03` 的 218。出处同上，总览「难度怎么爬」

地图格子数是 7 列 × 12 行。出处：PR #4 `data/balance/combat/rules.json` 的 `grid`，PR #5 `docs/design/level/overview.md`「地图和预定槽位」，PR #6 `docs/design/art/README.md`「已定」第 2 条（每格 128 像素）。可以用色块代替正式立绘（PR #6 允许占位），但格子数不能变。

- [ ] 实机：棋盘是 7×12，不是 `main` 上那条车道

---

## 2. 学习曲线

总目标写在 PR #5 `docs/design/level/overview.md`「设计目标」：每一关只加一件新事。和这一句冲突的两关见 DI-17，那两关的「只一件」不能勾。

### prologue_01 神社的直路

主教学点：只能放在预定槽位上，角色会自己打。出处：总览 24 关表；`prologue_01.json` 的 `teaches`。本关可放置只有 `chr_reimu`。3 个槽位，一条 12 格的路。没有三选一。

- [ ] 实机：教学出现之前，点路线 `P`、障碍 `B`、裂缝 `S`、守护点 `G` 都放不下人。只有 `.` 能放灵梦
- [ ] 实机：放下灵梦之后不需要再点攻击，残影进入范围会自己掉血
- [ ] 实机：被试说得出的新规则就是「放到发光的格子上，然后它自己打」。还说出魔理沙、三选一或快残影，则不通过
- [ ] 实机：按第 0 节的方法，不会在「放好之前不出怪」这条教学出现前卡死。教学 key 是 `tut.prologue_01.004`（PR #2 `data/text/dialogue_zh.csv`）。这句话和真实手势是否一致，见第 6 节，受 DI-12 限制

### prologue_02 直路的尽头

主教学点：魔理沙的攻击沿直线穿透。出处：总览 24 关表。本关可放置 `chr_reimu` 和 `chr_marisa`。4 波，没有三选一。

- [ ] 实机：本关开始时魔理沙已经在可放置名单里，不需要再打一遍上一关才出现（上一关已经通关的前提下）
- [ ] 实机：魔理沙打中一列上的多只残影时，伤害不在第一只停住。穿透的具体格数以 PR #4 `characters.json` 里她的攻击形状为准，本清单不另写格数
- [ ] 实机：被试说得出的新规则是直线穿透。没有出现快残影、分叉或三选一
- [ ] 实机：按第 0 节的方法不会卡关

### prologue_03 弯过院子

总览同时写了两件新事：弯路的拐角和直路不是同一格，以及第一次三选一。见 DI-17。

- [ ] 待定（DI-17）：「只教一件新事」在本关不能判。澄清前不要为了打勾而把两件事合成一句
- [ ] 实机（澄清前仍可记观察，不判过）：第 5 波结束后出现三选一，第 10 波结束后不出现。数据出处：`level_difficulty.json` 的 `prologue_03.buff_after_waves` 是 `[5]`
- [ ] 实机：弯路能走完，残影不会斜着抄近路。路径只能上下左右，见 PR #5 `docs/design/level/overview.md`「地图和预定槽位」

### ch1_01 湖畔薄雾

总览同时写了雾和快残影。见 DI-17。数据：可放置仍是灵梦和魔理沙，没有琪露诺。`new_enemy_ids` 是 `enm_shade_fast`。快残影从 `w06` 起出现，全关 63 只快残影、151 只小残影（合计 214，大约三成）。这组只数是 `ch1_01.json` 的 `spawns` 加总，总览写的是「大约占三成」。

- [ ] 待定（DI-17）：「只教一件」不能判
- [ ] 数据：`w01` 到 `w05` 的 `spawns` 里没有 `enm_shade_fast`
- [ ] 实机：本关名单里点不到琪露诺
- [ ] 实机：雾格上的残影，角色射程比没有雾时少 1 格，最少仍有 1 格。出处：PR #4 `rules.json` 的 `fog.range_penalty_cells`、`fog.min_range_cells`，以及 `terrain.json` 里 `ter_fog` 的 `target_range_penalty`

### ch1_02 雾里的弯道

主教学点：两个入口，琪露诺的减速用来接住快残影。出处：总览 24 关表「练习关才教新角色」。可放置三人：灵梦、魔理沙、琪露诺。11 波。

- [ ] 实机：通关 `ch1_01` 之后，本关可以放琪露诺；没通关 `ch1_01` 时选不了本关（解锁顺序）
- [ ] 实机：琪露诺的普通攻击会给残影挂 `st_slow`，多个减速同时存在时只保留最强的一个。出处：PR #4 `core_rules.md` 3.2。强度 0.35（`characters.json` 的 `chr_cirno.attack.applies_statuses`）和数值分支写的 20% 还不一致，具体百分比见 DI-01，本条不判那一个数
- [ ] 实机：被试说得出的新规则是「把琪露诺放下去，快的会变慢」以及「有两个入口」。没有出现硬残影或首领符卡（硬残影是否本应在下一关出现，见 DI-02，本关先按 JSON：`new_enemy_ids` 为空）
- [ ] 数据：本关 `spawns` 里没有 `enm_shade_armored`
- [ ] 实机：按第 0 节的方法不会卡关

### ch1_03 分叉的湖岸

主教学点若不含硬残影：一个入口分成两边，分叉中间打不到另一边。出处：总览「地图和预定槽位」。硬残影见 DI-02，本关 JSON 实际刷了 8 只。

- [ ] 实机：左右两条路同时有怪时，只放在一边的角色打不到另一边路上的残影
- [ ] 实机：被试说得出的新规则是「分叉要两边都顾」。若 DI-02 定案为「本关不出现硬残影」，则被试提到护甲或硬残影算多教了一件
- [ ] 待定（DI-02）：本关出现几只 `enm_shade_armored` 不能判过或失败
- [ ] 实机：按第 0 节的方法，在「分叉」这件事上不会卡关。不要用「打不过硬残影」来判这条，那是 DI-02

### ch1_04 完美冻结

主教学点：和冰之残影决斗，符卡改地形，不改路线。出处：总览 24 关表。首通可放置仍是灵梦、魔理沙、琪露诺。通关后 `unlock_character_ids` 是 `chr_yukari`。

- [ ] 实机：本关首通不能把紫放进槽位
- [ ] 实机：冰柱和冰面出现时，`map.paths` 的格子序列不变，变的是地形。冰面移速倍率见 `terrain.json` 的 `ter_ice`（1.5）
- [ ] 待定（DI-06）：本关能不能打过、剩多少命，不能判
- [ ] 数据（DI-13，用户 2026-10-02 已定）：第三阶段符卡是雪符「钻石风暴」（`sc_boss_cirno_diamond_blizzard`），不是只有两阶段。玩家能看见的名字和宣言句等文案 key 落地后再勾实机；现在 #2 还没有这张牌的宣言句
- [ ] 待定（DI-14）：第一章里那一次换位演示如果被指定发生在本关，澄清前不能判；澄清前只检查「首通不能放紫」

---

## 3. 节奏

已写进文件、可以先做数据检查的数：

- 布阵 10 秒：PR #4 `rules.json` `battle_flow.deploy_time_sec`，以及七关 JSON 的 `deploy_time_sec`
- 波间允许范围 3 到 5 秒，关卡填写 4 秒：`battle_flow.intermission_min_sec`、`intermission_max_sec`、`intermission_sec`，以及七关的 `intermission_sec`
- 刷怪时长字段 20 秒：七关每波 `duration_sec`，多只一组时出场窗口落在 18 到 22 秒。出处：PR #5 `data_format.md`「波次」，由 `validate_levels.py` 检查

实机「玩家感觉每一波大约 20 秒」取决于从哪一秒量到哪一秒，见 DI-03。第一波前是 10 秒还是 10 秒再加 4 秒，见 DI-04。

- [ ] 数据：七关 `deploy_time_sec` 都是 10，`intermission_sec` 都是 4，每波 `duration_sec` 都是 20
- [ ] 数据：序章三关 `deploy_wait_for_player` 为 true，第一章四关为 false
- [ ] 待定（DI-04）：实机从「可以放置」到「第一只残影出现」的秒数不能判
- [ ] 待定（DI-03）：实机每一波的起止秒数不能判。澄清前允许记录观察（从第一只出现量到下一只不同波的第一只出现），只记在备注里，不打勾
- [ ] 实机：提前开始的按钮存在于布阵。奖励每秒多少灵力是占位（PR #4 `stats.json` `economy.early_start_reward_per_sec` 为 1，文件状态是占位；`core_rules.md` 4.2 标了占位）。按钮可以测，奖励数字待定，不要断言「一定 +1」

10 波大约 4 到 5 分钟、20 波大约 8 到 10 分钟，写在 PR #3 `docs/GDD.md`「局内塔防」。MVP 没有 20 波的关。`ch1_04` 是 15 波，总纲没有单独给 15 波的分钟数。

- [ ] 待定（DI-03）：`prologue_03` 和 `ch1_01` 这两关 10 波的墙钟时间是否落在 4 到 5 分钟，要等「20 秒怎么量」定了再判。定了之后，墙钟含布阵 10 秒和波间，不含玩家把游戏切到后台的时间

---

## 4. 胜负、生命、重来

- [ ] 实机：守护点生命上限是 20。出处：PR #3 `docs/GDD.md`「局内塔防」；PR #5 各关 `params.lives`；`rating.json` 的 `max_lives`。PR #4 把 `guard.max_hp` 标成占位，但数字同样是 20，和总纲一致，按 20 验收
- [ ] 实机：普通关最后一波的敌人都离开场（打死或漏掉），且生命仍大于 0，判定胜利。出处：PR #4 `core_rules.md` 5.2
- [ ] 实机：生命变成 0 时立刻失败，同一时刻如果也满足胜利，算失败。出处同上
- [ ] 实机：失败界面有「从当前波重来」和「整关重打」两个选择。出处：PR #3 `docs/GDD.md`「核心循环」
- [ ] 待定（DI-05）：从当前波重来之后，生命、灵力、等级、强化、符卡充能哪些回到波开始时，不能逐项判
- [ ] 实机：中途退出不增加局外进度。出处：PR #3 同上。局外资源的数量本身待定（DI-09），这里只检查退出前后局外等级和关卡解锁没有变
- [ ] 待定（DI-07）：漏一只小残影或快残影扣几点、冰之残影折返扣几点，不能判。只检查关卡 JSON 没有自己写一个扣血数字（`ch1_04` 的 `leak` 只有指针，没有数字）

伤害公式可以单测，也可以在实机用一只护甲为 0 的小残影看数字是否等于攻击力（四舍五入规则在 `rules.json` `damage.rounding`：`round_half_away_from_zero`）。

- [ ] 实机或单测：护甲为 0 时，伤害等于攻击（再按上述舍入）。有护甲时不低于攻击的两成。公式出处：PR #3 `docs/GDD.md`「局内塔防」
- [ ] 待定（DI-01）：是否再有「最少 1 点」（`stats.json` 的 `min_damage`）不能判

---

## 5. 谁能放、何时加入

已对齐的加入时机（PR #3 `docs/GDD.md`「剧情和角色」，PR #5 `data/levels/index.json` 的 `character_joins_decided`，PR #4 `characters.json` 的 `unlock`）：

| 角色 | 什么时候加入 | 第一次能放的关 |
| --- | --- | --- |
| 灵梦 `chr_reimu` | 开局 | `prologue_01` |
| 魔理沙 `chr_marisa` | 通关 `prologue_01` | `prologue_02` |
| 琪露诺 `chr_cirno` | 通关 `ch1_01` | `ch1_02` |
| 紫 `chr_yukari` | 通关 `ch1_04` | 七关首通都不能放。重打已通关关卡可以放（PR #3「MVP」） |

- [ ] 实机：上表四行都成立。七关第一次打通时，用过的人只有灵梦、魔理沙、琪露诺
- [ ] 实机：通关 `ch1_04` 之后重打 `prologue_01`，紫出现在可放置名单里
- [ ] 实机：同一角色最多放 3 个。出处：PR #4 `rules.json` `placement.max_copies_per_character`
- [ ] 待定（DI-01）：第 2 个、第 3 个的费用倍率（`copy_cost_increase_ratio`）不能判
- [ ] 待定（DI-14）：隙间换位的那一次演示不能判
- [ ] 数据：大妖精、蕾米莉亚、文、忘不在七关的 `available_character_ids` 里。他们是否可玩仍待定（PR #2 `story_outline.md`「待制作人拍板」），MVP 不要求能放

---

## 6. 操作和教学句

战斗已拍板的操作在 PR #4 `core_rules.md` 第 6 节：点 `.`，再点头像。符卡按钮在底部。教学 CSV 仍写拖动头像、点击灵梦放符卡。见 DI-12。

- [ ] 待定（DI-12）：序章教学句和手势一致，不能判。澄清并改完 `tut.prologue_01.004`、`tut.prologue_01.008` 之后，实机按新句子能完成放置和第一次符卡，才能勾
- [ ] 实机：自动释放是全局一个开关，默认关，局内可以拨动。出处：PR #3 `docs/GDD.md`「局内塔防」；PR #4 `rules.json` `spell_energy.auto_release_default_on` 为 false
- [ ] 实机：倍速只有 1 和 2，默认 1。出处：`rules.json` 的 `time_scale.speed_options`、`default_speed`
- [ ] 实机：波次进行中不能更换符卡使；布阵和波间可以换，换人后符卡能量归零。出处：PR #4「已拍板」第 1 条，`spell_energy.caster_switch_clears_charge` 为 true

---

## 7. 三选一

规则：每打完 5 波给 3 个选项，选 1 个；最后一波之后不给；只在本局有效；叠到 2 层质变；还没质变的已有强化，下次保底出现一个。出处：PR #3 `docs/GDD.md`「核心循环」；PR #4 `rules.json` 的 `buff_offers`；PR #5 难度表 `buff_after_waves`。

各关应弹出的波次（数据，来自 `level_difficulty.json`）：

| 关卡 | `buff_after_waves` |
| --- | --- |
| `prologue_01`、`prologue_02` | 空，没有三选一 |
| `prologue_03`、`ch1_01` | `[5]` |
| `ch1_02`、`ch1_03`、`ch1_04` | `[5, 10]` |

- [ ] 数据：上表和难度表一致，且这些数组里没有该关的最后一波
- [ ] 实机：序章前两关全程不弹出三选一
- [ ] 实机：上表里有的波次，打完该波后弹出，选项是 3 个
- [ ] 实机：`ch1_04` 第 15 波打完后直接结算，不弹出
- [ ] 实机：过关再开下一关，上一关选过的强化不在
- [ ] 实机：同一强化拿到第 2 层时发生质变。质变演出时长见第 9 节；质变的具体效果名单仍待定（PR #3 清单第 11 条），只检查「第 2 层和第 1 层不是同一个说明文字」
- [ ] 实机：已经有、但只有 1 层的强化，下一次三选一的三个选项里至少有一个是它

---

## 8. 灵力和局外成长

名字「灵力」已定。出处：PR #2 `docs/design/narrative/glossary.md`；PR #3 `docs/GDD.md`。局外那种 1 到 20 级的资源，界面和测试先用文本 key `currency.meta`（用户 2026-10-02）。中文显示名仍未选定（DI-09）。

- [ ] 实机：界面把局内货币写成「灵力」，不写成金币或能量
- [ ] 待定（DI-01）：开局是 150 还是 100，每波结束加不加 20，击杀掉落是多少，放置费用是多少，不能判。PR #5 关卡写 `starting_spirit_power` 150、`reward_spirit_per_wave` 20；PR #4 `stats.json` 写 `starting_spirit` 100，且整份是占位
- [ ] 实机：放置和局内升级会减少灵力。升级最多 2 次，角色局内等级不超过 3。出处：PR #3「局内塔防」；`rules.json` `character_levels.max_level`
- [ ] 待定（DI-01）：这两次升级加的是攻击、攻速还是别的，不能判（PR #3 清单第 10 条）
- [ ] 待定（DI-09）：过关给多少局外资源、重打给多少，不能判。显示不写死中文名，用 `currency.meta`
- [ ] 实机：每个角色的局外等级有上限 20 这一档的入口或数据字段，不能升到 21。加成内容待定，不检查「升一级攻击变高」
- [ ] 实机：星星不能用来解锁角色，也不能加攻击、生命或灵力。出处：PR #3「关卡推进」；`rating.json` `stars_do_not_grant_power`

---

## 9. 爽感反馈是否按时出现

MVP 第一批硬要求，出处：PR #4 `docs/design/combat/feedback.md` 第 1 节末尾：命中闪白、伤害数字、光点飞向灵力栏、符卡立绘、冰碎。时长以 `data/balance/combat/feel.json` 的字段为准。立绘的总时长不在 `feel.json`，在 `rules.json` 的 `spell_cutin`，下面分开写。

计时方法：1 倍速，录屏或看调试时钟。逻辑每秒 60 步（`rules.json` 的 `tick.logic_hz`）。量到的时间和字段相差达到或超过一步（1/60 秒）就不符合；不要再加一个文档里没有的容差。2 倍速时，伤害数字的寿命按真实时间除以倍速（`feedback.md` 第 2 节）；立绘按真实时间，不受倍速影响（`feedback.md` 第 5 节，`core_rules.md` 第 7 节）。1 倍速每条都看。2 倍速只抽查立绘没有变短，以及伤害数字比 1 倍速消失得快。

冰碎要等琪露诺在场且魔理沙打中被冻的敌人，所以最早在 `ch1_02` 才能看。序章充能倍率是 2.0（各关 `spell_charge_mult`），用来更快看到第一次立绘，不是数值定案（`prologue_01.json` 的 `combat_timing_note`）。验收只要求序章能放出至少一次符卡，不要求「正好 60 秒充满」。充满目标 60 秒 / 危急 40 秒在 `rules.json` `spell_energy.target_full_sec_normal` 和 `target_full_sec_crisis`，PR #3 清单第 13 条仍说充能速度待定，所以不把 60 秒写成通过条件。

- [ ] 实机：命中且伤害大于 0 时，敌人闪白。`hit_flash.duration_sec` 是 0.08，`hit_flash.strength` 是 0.85，`hit_flash.color` 是 `#FFFFFF`。同一敌人 `hit_flash.throttle_per_enemy_sec`（0.05）之内不闪第二次
- [ ] 实机：普通伤害数字是白色，字号 `damage_numbers.normal_font_px`（34），上飘 `damage_numbers.rise_px`（60），停留 `damage_numbers.lifetime_sec`（0.6）
- [ ] 实机：重击（暴击或冰碎）是 `damage_numbers.heavy_color`（`#FFD23F`），字号 `heavy_font_px`（48），弹出倍数 `heavy_pop_scale`（1.4）
- [ ] 实机：同一敌人在 `damage_numbers.merge_same_target_window_sec`（0.12）内的多次普通伤害并成一个数字。同时存在的数字不超过 `damage_numbers.max_on_screen`（40）
- [ ] 实机：敌人死亡后，`kill_burst.particles_per_kill`（6）个光点飞向灵力栏，飞行 `kill_burst.fly_duration_sec`（0.5）。场上光点不超过 `kill_burst.max_active_orbs`（60）
- [ ] 实机：光点到达后，灵力数字放大到 `spirit_counter_bump.scale`（1.25），放大持续 `spirit_counter_bump.duration_sec`（0.15），数字用 `spirit_counter_bump.count_up_sec`（0.3）滚到新值
- [ ] 实机：符卡能量满时，按钮按 `spell_button.ready_glow_pulse_sec`（0.8）脉冲，并只响一次 `spell_button.ready_sfx`（`spell_ready_chime`）
- [ ] 实机：立绘遮罩不透明度到 `spell_cutin.dim_alpha`（0.55）。立绘滑入 `spell_cutin.portrait_slide_in_sec`（0.2），玩家从 `portrait_side_player`（left），首领从 `portrait_side_boss`（right）。符卡名淡入 `spell_cutin.name_fade_in_sec`（0.15）
- [ ] 实机：同一张符卡在本关第一次的总时长是 `rules.json` `spell_cutin.first_duration_sec`（1.2），之后是 `repeat_duration_sec`（0.6）。点击可以跳过（`spell_cutin.skippable` 为 true，`feel.json` `spell_cutin.tap_to_skip` 为 true）。演出期间逻辑暂停（`pauses_logic` 为 true）
- [ ] 实机：在 `ch1_02` 或之后，魔理沙打中被琪露诺冻住的敌人时，出现冰碎的黄色大数字。碎冰时长 0.3 秒写在 `feedback.md` 的 `ice_shatter` 行，`feel.json` 没有对应的秒数字段。在补上字段之前，这条只检查「有碎冰并且伤害数字用了重击色」，不检查 0.3 秒
- [ ] 实机：第一次触发冰碎时，横幅时长是 `synergy_popup.first_time_duration_sec`（1.6）

第二批（震屏、慢动作、连击）不是 MVP 硬要求。出处：`feedback.md`「MVP 第二批」。若这版做了，再按下面的字段看，没做不算 MVP 失败。

- [ ] 若有震屏：`screen_shake.heavy_duration_sec` 0.15，`heavy_amplitude_px` 6，且设置里能关（`settings_toggle` 为 true）
- [ ] 若有连击数字：`combo.display_linger_sec` 1.2。连击从几开始显示、窗口多少秒在 `rules.json` 的 `combo`（`display_from` 3，`chain_window_sec` 1.0），不在 `feel.json`
- [ ] 若有慢动作：持续 `rules.json` `slowmo.duration_real_sec`（0.5），时间倍率 `slowmo.time_mult`（0.3）。进出缓动是 `feel.json` `slowmo.ease_in_real_sec`（0.05）和 `ease_out_real_sec`（0.1）

首领血条和波次横幅属于「随 Boss / 第一批配套」，工期紧时不是五件硬要求里的。若 `ch1_04` 做了首领，再检查：

- [ ] 若有首领血条：掉血后滑落时间是 `feel.json` `boss.hp_bar_drain_sec`（0.3），过阶段闪白 `boss.phase_break_flash_sec`（0.2），登场横幅 `boss.entry_banner_sec`（1.0）
- [ ] 若有波次横幅：`wave_banner.duration_sec`（1.0），最后一波的文本 key 是 `wave_banner.final_wave_text_key`（`combat.final_wave`）

守护点被漏怪打中时的泛红：`guard_damage_vignette.duration_sec` 0.4，`max_alpha` 0.45。`feedback.md` 把它标成建议。MVP 若做了扣血，就应同时有这下反馈，否则玩家不知道为什么掉血。

- [ ] 实机：漏怪扣血时，屏幕边缘泛红，时长按 `guard_damage_vignette.duration_sec`（0.4）。扣多少血仍待定（DI-07），这条只查反馈在不在

---

## 10. 冰之残影（数据能查的部分）

- [ ] 数据：`ch1_04` 的首领 id 是 `boss_cirno`，显示名是「冰之残影」，不是琪露诺本人。`bosses.json` 的 `identity` 是 `cirno_copy`，`copy_of` 是 `chr_cirno`
- [ ] 数据：阶段血量比例是 1.00 到 0.66、0.66 到 0.33、0.33 到 0。关卡 `phases` 和 `bosses.json` 的 `hp_ratio_start` 一致
- [ ] 数据：当前 `enter_wave` 是 5。这和「建议改成第 11 波」并存，见 DI-06。本条只核对 JSON 仍是 5，不表示 5 是最终玩法
- [ ] 待定（DI-06）：实机通关不能判
- [ ] 数据（DI-13，用户 2026-10-02 已定）：第三阶段出现雪符「钻石风暴」。实机名字等文案 key，见第 2 节 `ch1_04`
- [ ] 实机（DI-13，用户 2026-10-02 已定）：角色被冻住后可以连点破冰。点几次读战斗配置里的次数字段，本清单不写死次数。用户没有另给次数；草案里的 3 下只在字段仍是 3 时成立
- [ ] 实机（仅在 DI-06 仍用第 5 波入场时作为观察，不判胜负）：走到守护点后首领不消失，而是回到裂缝再走同一条路。出处：PR #4「已拍板」第 5 条；`bosses.json` `on_reach_guard` 是 `loop_to_spawn`。扣多少命待定（DI-07）
- [ ] 实机：最后一波在首领被击败之前不算结束。出处：PR #3 `docs/GDD.md`「核心循环」；该关最后一波 `ends_when` 是 `boss_defeated`

---

## 11. 星级和失物簿

- [ ] 实机：没通关（生命到 0）没有星。出处：`rating.json` 的 `defeat_lives` 0
- [ ] 实机：通关且生命是 20/20，得到 3 星。出处：PR #3 `docs/GDD.md`「关卡推进」；`rating.json` 里 3 星的 `lives_min` 和 `lives_max` 都是 20
- [ ] 实机：通关但不是满命，至少得到 1 星
- [ ] 待定（DI-08）：剩多少命算 2 星，不能判。PR #3 写当前是 ≥ 10/20，PR #5 把这个比例标成 `pending_numbers`
- [ ] 实机：重打一关可以补上还没有的星，不会把已经有的星拿掉。出处：PR #3「关卡推进」
- [ ] 实机：1 星能看见该关失物簿的标题和第一段，2 星能看见第二段。文本在 PR #2 `data/text/lostbook_zh.csv`，规则在 `docs/design/narrative/lost_and_found.md`。2 星的生命门槛未定，所以这条在 DI-08 关闭后，用定下来的门槛去打开第二段
- [ ] 待定：某一章全部 3 星解锁哪套外观。PR #2 写了方向，又写星数由系统定；PR #6 说 MVP 外观只做换色。不检查具体衣服

---

## 12. 明确不做，出现了就算失败

出处：PR #3 `docs/GDD.md`「明确不做」。

- [ ] 实机：没有让玩家操纵角色去躲弹的弹幕射击。符卡是放在格子上的技能
- [ ] 实机：没有抽卡、体力、付费、内购、广告
- [ ] 实机：没有多人、账号、服务器
- [ ] 实机：没有车道、加人门、基地建筑这套旧循环。`main` 上若仍能点进占位车道，那是 DI-16 的合并顺序问题，塔防原型 PR 必须关掉这个入口之后，本条才能勾

---

## 13. 本清单故意不验收的

- 第二章到终章的地图、首领和加入人物（DI-10、DI-11）
- 局外资源的中文名和数量（DI-09）。key 用 `currency.meta`
- 结算画面好不好看。方向已由用户交给美术和动效师：东方风梦幻的 MVP 图；字体要灵活，有游戏感，也要有赛博朋克感。测试不代替判断好看
- 强化池里每一条的数值（PR #3 清单第 11 条）
- 符卡要打多少下才充满（PR #3 清单第 13 条）
- 第三章村民褪色算不算失败（PR #2、PR #5 都标待定）
- `feel.json` 里第二批没有做的震屏、慢动作、连击（第 9 节已写「若有」）
- 无头模拟的通关率和难度跳变门槛（`LEVEL_SIM.md`，门槛待定）
