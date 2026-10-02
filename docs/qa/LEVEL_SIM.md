# 无头关卡模拟器方案

只写方案，这次不实现，也不加脚本、不改 CI。等塔防核心原型合并之后再做。原型指：格子地图、残影沿路线走、在 `.` 格放角色并自动攻击、灵力、守护点生命、波次、胜负。写这份方案时还没有这个原型的 PR。

`main` 上的 `scenes/battle/battle_lane.tscn` 是车道占位，不能拿来跑这个模拟。

数值分支 `numeric/touhou-td-framework`（没有 PR）里已经有一份 Python 模拟，说明在该分支 `docs/design/numeric/09_simulation.md`，结果在 `generated/sim_results.md`。那份模拟服务的是调系数，而且它自己列出了没模拟的机制（弹道、击退细节、紫的换位、提前叫波、从当前波重来等）。本方案不依赖那份脚本。两边数字冲突时以 `DESIGN_ISSUES.md` 的 DI-01 为准：先对齐表，再谈谁的剩余生命算数。

---

## 1. 目的

自动、可重复地回答三件事：

1. 用同一种笨办法打，MVP 七关能不能过。
2. 每一波结束时还剩多少生命、灵力怎么随时间变。
3. 相邻两关的这些数是不是突然变差。变差的门槛现在待定，见第 5 节。

它不代替 `MVP_ACCEPTANCE.md` 里的人工体验，也不验证 `feel.json` 的闪白和立绘。演出不改逻辑结果，只有慢动作和立绘暂停会改时间（PR #4 `docs/design/combat/feedback.md` 开头）。模拟若要和实机对表，必须把这两种暂停算进逻辑时间；其余粒子可以不画。

---

## 2. 输入

模拟开始前先做「数字来源检查」。下面这些字段如果仍是 DI-01、DI-03、DI-06、DI-07 里的冲突状态，输出写 `blocked`，列出 DI 编号，不要私下选 100 或 150。检查通过之后，只读文件，不把结果写回配置表。

### 2.1 关卡（PR #5）

| 路径 | 用到的字段 |
| --- | --- |
| `data/levels/index.json` | `levels` 的顺序、`unlock_after`。只模拟已解锁到的关 |
| `data/levels/prologue_01.json` 到 `prologue_03.json`，`data/levels/ch1_01.json` 到 `ch1_04.json` | 见下 |
| `data/levels/enemy_catalog.json` | `threat_points`，只用来核对预算，不代替血量 |
| `data/levels/character_roster.json` | `joins_at_level`、`unlocked_by_clearing`，决定这一关能放谁 |
| `data/levels/rating.json` | 胜负句、`max_lives`。2 星比例在 `two_star_ratio_status` 仍是 `pending_numbers` 时不计算星级 |
| `data/balance/level_difficulty.json` | 每关的 `hp_multiplier`、`threat_budget_coef`、`wave_threat_budgets`、`reward_spirit_start`、`reward_spirit_per_wave`、`buff_after_waves`、`buff_pick_count` |

每一关 JSON 要读的字段：

- `params.starting_spirit_power`、`params.lives`、`params.available_character_ids`
- `deploy_time_sec`、`deploy_wait_for_player`、`intermission_sec`、`spell_charge_mult`、`spell_energy_start`
- `map.columns`、`map.rows`、`map.cells`、`map.paths`（`path_id`、`cells`、`kind`）、`map.slots`、`map.terrain`、`map.cell_sets`、`map.entrances`、`map.guard`
- `waves[]`：`wave_id`、`duration_sec`、`delay_sec`、`next_wave_delay_sec`、`ends_when`、`is_boss`、`spawns`（`enemy_id`、`path_id`、`count`、`interval_sec`、`delay_sec`）
- `bosses[]`（仅 `ch1_04`）：`id`、`enter_wave`、`path_id`、`phases`（`hp_ratio_start`、`hp_ratio_end`、`spell_card_id`、`duration_sec`、`terrain_id`）、`leak.lives_source`
- `unlock_character_ids`

草案关（`ch2_01.json` 起，`status` 为 stub）没有地图，不进入 MVP 模拟。

### 2.2 战斗数值和行为（PR #4）

| 路径 | 用到的字段 |
| --- | --- |
| `data/balance/combat/stats.json` | `armor_floor_ratio`、`min_damage`（是否生效等 DI-01）、`guard.max_hp`、`economy`、`spell_charge`、`characters` 的费用和攻击、`enemies` 的 `hp`、`move_speed_cells_per_sec`、`armor`、`spirit_drop`、`leak_damage`、`kill_charge` |
| `data/balance/combat/rules.json` | `tick.logic_hz`、`battle_flow`、`targeting`、`movement` 的速度上下限、`enemy_spawn.spawn_state_sec`、`placement`、`buff_offers`、`spell_energy`、`damage.rounding`、`fog`、`retry` |
| `data/balance/combat/characters.json` | 攻击方式、射程、攻速、技能 id、默认符卡。具体键以该文件为准，实现时按 `docs/design/combat/data_reference.md` 读，不在这里另造字段 |
| `data/balance/combat/enemies.json` | 行为标签，例如是否攻击角色、击退抗性。血量不在这里 |
| `data/balance/combat/bosses.json` | `boss_cirno` 的阶段、`on_reach_guard`、`phase_transition` |
| `data/balance/combat/statuses.json` | 减速、冻结的持续和强度 |
| `data/balance/combat/terrain.json` | `ter_ice` 的移速倍率、`ter_fog` 的射程惩罚、`ter_icicle` 挡住直线 |
| `data/balance/combat/spell_cards.json` | 玩家和 Boss 符卡的系数、持续时间 |
| `data/balance/combat/buffs.json` | 三选一的层数和质变。池子未拍板时（PR #3 清单第 11 条），模拟可以按文件里已有的 id 抽，报告里写「用的是草案池」 |
| `data/balance/combat/synergies.json` | 联动条件。冰碎是 MVP 要能发生的联动 |
| `data/balance/combat/feel.json` | 逻辑模拟不读，除非以后要核对「立绘暂停了多少真实时间」。暂停时长以 `rules.json` 的 `spell_cutin` 为准 |

敌人的实战血量按 PR #5 的写法：基础血量乘该关 `hp_multiplier`。Boss 乘不乘，等 DI-06。乘的公式本身是 `1 + 0.15 × (关卡序号 − 1)`，序号在难度表的 `level_index`。

### 2.3 明确不读

- `data/balance/starting_balance.json`：车道占位，关卡不用（PR #5 总览「和现有文档、代码的差别」）
- 局外升级的具体消耗：PR #3 不写数字，难度表是 `pending_numbers`（DI-09）。首版模拟默认局外等级全是 1，并在报告里写明。不要把数值分支里的 50%、30%、20% 写进模拟器
- `feel.json` 的粒子数量和颜色

---

## 3. 自动放角色的策略

三种都要能选，同一种子下结果必须能复现。逻辑步进用 `rules.json` 的 `tick.logic_hz`（60）。随机只来自传入的种子：暴击、三选一的抽取。种子写进输出。

### 3.1 固定脚本

给七关各写一份「第几秒、在哪个 `slot.id`、放哪个 `chr_`、升不升级」的列表，放在以后的 `tools/sim/scripts/`（实现时再加，这次没有这个目录）。

编列表的规则，只使用关卡文件里已经写明的意图，不另估强度：

- 只使用该关 `params.available_character_ids`
- 槽位优先读 `map.slots[].why`：长直路给魔理沙，拐角和贴路的槽给灵梦，出现快残影的那一关才把琪露诺放上
- 灵力不够就不放，不卖出
- 序章 `deploy_wait_for_player` 为 true 时，脚本的第一次放置算「玩家已完成放置」，然后才走布阵倒计时

固定脚本用来回归：改了战斗代码之后，同一份列表的剩余生命不该无故变化。

### 3.2 贪心

每个可以放置的决策点（布阵，以及 DI-03 澄清后的波间）做同一件事：

1. 按教学顺序看可用角色：灵梦、魔理沙、琪露诺。还没解锁的跳过。
2. 若灵力够最便宜的一次放置或升级，就花掉：优先把「这一关 `teaches` 里点名的新角色」放到还空着的、贴着路线的槽；否则升级已经在场、攻击最高的那个。
3. 槽位评分只用几何：该槽上下左右能覆盖到的路径格数量。射程数字来自 `characters.json`，不在模拟器里写死格数。
4. 不提前叫波，不卖出。数值分支的模拟也做了这个保守假设（`09_simulation.md` 第 2 节）。这里沿用它作为「贪心」的定义，避免和那份结果完全无法对照。它不是制作人定的唯一玩法。

同名角色最多 3 个（PR #4 `rules.json` 的 `placement.max_copies_per_character`）。第 2、第 3 个的加价比例在 DI-01 里仍是占位，未澄清时贪心只放 1 个，并在报告里注明。

### 3.3 固定种子的多次随机

在「放 / 升级 / 什么都不做」和空槽之间用种子抽样。只在灵力足够时抽样。

跑几次，设计文档没有定。数值分支用了 5 个种子，那是那份草案的做法，不是本方案的门槛。实现时把次数做成参数，默认先和固定脚本一样只跑种子 1。次数要写成门槛，等制作人定，不在这里写死。

三选一：在 `buff_after_waves` 列出的波次结束后，从 3 个选项里按种子选 1 个。已拥有但未到 2 层质变的强化必须出现在选项里（PR #3、PR #4 已定）。最后一波的波次 id 不得出现在 `buff_after_waves`。

---

## 4. 输出

每一关一份 JSON，另有一份七关摘要。建议路径（实现时再创建）：`tools/sim/out/<关卡id>.json`。人读的摘要用简体中文写在旁边的 Markdown 里。

每一波结束时记录：

- `wave_id`
- 这一波结束时的守护点生命
- 这一波漏掉的只数（按 `enemy_id` 分开）
- 这一波结束时的灵力
- 场上还活着的敌人数（用来看出波次有没有重叠）
- 是否弹出了三选一，选了哪个 id

整关记录：

- `result`：`victory`、`defeat` 或 `blocked`
- 结束时生命、灵力
- 灵力随时间的序列：模拟时间（秒）和当时的灵力。时间用逻辑秒，立绘暂停期间逻辑时钟停
- 第一次漏怪发生在哪一波
- 符卡释放次数
- 若星级规则已澄清（DI-08）：按 `rating.json` 算出的星数。未澄清则星数字段写 `pending`
- 使用的策略名、种子、读到的 `stats.json` 提交号

七关摘要：

- 每关通关与否
- 多种子时的通关率（通过次数 / 次数）。次数未定时，这一格留空，不写假的百分比门槛
- 相邻关卡的生命差、第一次漏怪波次差，交给第 5 节

`blocked` 的关不参加通关率。

---

## 5. 怎么看难度跳变

比较的是解锁顺序上相邻的两关，顺序来自 `data/levels/index.json`：`prologue_01` → `prologue_02` → `prologue_03` → `ch1_01` → `ch1_02` → `ch1_03` → `ch1_04`。

看这三个差，都用同一种策略、同一个种子：

- 结束时剩余生命：后一关减前一关
- 第一次漏怪的波次：后一关减前一关
- 通关与否：前一关过、后一关不过

PR #5 总览已经用威胁合计描述「后一关应该更难，但有首领的章结束之后，下一章第 1 关要松下来」。MVP 里能对上的已写数字是：`ch1_01` 的威胁合计 214，低于 `prologue_03` 的 218（同一篇「难度怎么爬」）。这只说明预算表是这样填的，不是剩余生命允许掉多少。

剩余生命掉多少、通关率掉多少算「跳变」，设计文档没有门槛。标 **待定**。不要把数值分支里「差 0.05 系数就崩」当成 QA 门槛，那是他们校准系数时的观察，不是验收标准。

在门槛定下来之前，模拟只把相邻关的三个差打印出来，供制作人看，CI 不因此失败。定门槛时要同时处理 DI-08：序章和首领关的首通目标现在不是同一组数。

另外两件已经写明、实现后可以直接当失败，不算「待定的难度门槛」：

- 同一关的威胁合计和 `wave_threat_budgets` 对不上（这是配置校验的事，模拟再查一次）
- `ch1_04` 的 `enter_wave` 和文档「请制作人拍板」那条不一致。在 DI-06 关闭前，这关结果恒为 `blocked`，即使贪心打赢了也不算通过

---

## 6. 用 Godot 无头，还是用 Python 再写一套

| | Godot `--headless` | Python 复刻 |
| --- | --- | --- |
| 和真游戏的关系 | 调用原型里的同一套战斗步进。规则改了，模拟跟着改 | 要另维护一份规则。PR #4 和数值分支已经证明两套数字会分叉 |
| 速度 | 七关、60 步每秒，一局大约是实机逻辑时间。扫很多种子会慢 | 适合扫系数。数值分支就是这样做的 |
| 漏掉的机制 | 少。没接上的系统会在游戏里同样缺失 | 多。弹道、击退、换位、叫波很容易被写丢，然后得出错误的「能打过」 |
| CI | 仓库已经会装 Godot 4.7.2 并无头跑 GUT（`ci/run_tests.sh`） | 只需 Python。PR #5 的校验器已经是 Python |
| 适合当验收吗 | 适合。这是以后要相信的那一份 | 不适合当验收。可以留给数值策划调表，和 Godot 结果不一致时，以 Godot 为准查 Python |

建议：验收模拟用 Godot 无头，入口做成一个只跑逻辑、不创建粒子的场景或脚本，由 `godot --headless --path . -s <脚本>` 启动。Python 继续负责 `validate_levels.py` 那种不需要战斗的检查。数值分支的 Python 模拟保留为策划工具，不进「这关算不算过」的判定。

若原型暂时无法无头步进，不要先写 Python 复刻来充数。那样会把 DI-01 再复制一份。

---

## 7. 和 CI 怎么接

这次的 PR 不改 `.github/workflows/ci.yml`。

原型和模拟都落地之后，另开 PR，建议做成 `test` 作业里的额外一步，而不是塞进安卓导出：

1. 先跑配置校验（第 2 节的来源检查）。出现 `blocked` 时，这一步是黄色说明，不是红色失败，直到 DI-01、DI-03、DI-06、DI-07 关闭。
2. 关闭之后，固定脚本加种子 1 跑七关。崩溃、读不到字段、胜利条件算错，CI 失败。
3. 难度差的门槛未定之前，把摘要上传成 CI 构件即可，不失败。
4. 不要在 CI 里校准系数或改写 `level_difficulty.json`。

本机在合入前的验证命令，实现时再写进那个 PR。形式应和现有测试一样，是仓库根目录的一条无头命令，而不是打开编辑器点播放。
