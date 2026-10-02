# MVP 开发计划

> 维护：执行制作人。写于 2026-10-02（UTC+8）。
> MVP 范围：序章 3 关（prologue_01–03）+ 第一章 4 关（ch1_01–04）。
> 规则以 PR #3 的 `docs/GDD.md` 为准；数值以 PR #8 为唯一来源；战斗、关卡、文案、美术以各自的设计 PR 为准。
> 待拍板和待对齐的事见同目录 [`DECISIONS_PENDING.md`](DECISIONS_PENDING.md)。用户拍板项编号 D-xx，策划对齐项编号 A-xx。

## 1. 正在进行的开发 agent

| 任务 | agent | 状态 | 说明 |
| --- | --- | --- | --- |
| T-00 塔防核心原型 | https://cursor.com/agents/bc-062dec78-83a7-5a85-9366-e6690ee5d174 | 进行中 | 网格地图、残影沿路线走、在 `.` 格放角色自动攻击、灵力、生命、波次、胜负、色块占位 |
| 修 CI（`ci/export_android_debug.sh`） | https://cursor.com/agents/bc-5cebddf9-0607-573d-bec7-3435cd202717 | 进行中，PR #7 | 改名提交 `7818316` 让第 7 行丢了 `}`，main 上 export-android 一直是红的 |
| GitHub 整理员 | https://cursor.com/agents/bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344 | 进行中 | 只更新分支、打标签、维护 `docs/PR_STATUS.md`，不合并。其他 PR 不要碰 `docs/PR_STATUS.md` |

## 2. 开发流程与验收

1. **任务下发**：开发任务由执行制作人拆定，发给 Grok Bot。Grok Bot 原样交给 Cursor cloud agent 执行，不改内容。
2. **PR 验收**：每个开发 PR 开出后，由执行制作人牵头，对应策划一起验收。
   - 分工：战斗规则 → 战斗策划；数值 → 数值策划；关卡 → 关卡策划；画面 → 美术策划；文字 → 文案策划。
   - 游戏测试对照验收清单（PR #9 `docs/qa/MVP_ACCEPTANCE.md`）查 bug。
   - 意见用中文评论，直接留在该 PR 下。
3. **结论和返工**：执行制作人汇总结论，发给 Grok Bot，只有两种：
   - 「可以合并」；
   - 「需要返工」，并列出具体要改的点。返工由 Grok Bot 转给原来那个 Cursor agent 修改。
4. **PR 规矩**：每个任务一个 PR。PR 描述里写明三件事：
   - 依赖了哪些设计文档和配置表；
   - 哪些值是临时的；
   - 卡在哪条 D-xx / A-xx 上。
5. **数值不写死**：数值一律从 `data/balance/` 读，不写死在脚本里。表里还是占位的字段，在 PR 里标「临时」。

## 3. 设计 PR 合并顺序

截至 2026-10-02 12:35（UTC+8），#2 到 #9 都没有合并，也都没有评审评论。

| 顺序 | PR | 分支 @ 提交 | 理由 |
| --- | --- | --- | --- |
| 1 | #7 修 CI | `cursor/fix-android-export-brace-2717` @ `ab3f279` | 先让 main 的 export-android 变绿，后面每个 PR 的 CI 才看得出真问题 |
| 2 | #3 GDD / ROADMAP | `docs/gdd-touhou-td` @ `1c64371` | 总纲是其他文档引用的规则来源。合进去之后，main 上不再是车道玩法（DI-16） |
| 3 | #8 数值（现为草稿） | `numeric/touhou-td-framework` @ `5091adb` | 数值唯一来源。先合进去，#4 / #5 就能删掉副本改成指向它，不会再起 `stats.json`、`level_difficulty.json` 的「双方新增同名文件」冲突 |
| 4 | #4 战斗 | `cursor/docs-combat-rules-354a` @ `1956921` | 先从 diff 里去掉 `stats.json`，再合。其他战斗 JSON 引用 #8 的 key |
| 5 | #5 关卡 | `cursor/design-level-framework-01a3` @ `f2212be` | 依赖 #8 的难度表和 #4 的读图约定。校验器和测试要改成读 #8 的值 |
| 6 | #2 叙事 | `docs/touhou-narrative-draft` @ `ccdf270` | 和别的 PR 没有文件重叠，可以早合，但要等 D-02 拍板后改完教学句 |
| 7 | #6 美术 | `docs/art-framework` @ `2fc4440` | 引用 #4 / #5 的 ID 和特效时长，放在它们后面 |
| 8 | #9 QA（现为草稿） | `cursor/docs-qa-plan-fc39` @ `12ac952` | 最后合。合之前把已经关掉的 DI 条目标成已解决，验收清单才对得上最终文档 |

会有 git 冲突的文件：

| 文件 | 涉及的 PR |
| --- | --- |
| `CHANGELOG.md` | #3 #4 #5 #6 #7 |
| `README.md` | #3 #4 |
| `docs/ARCHITECTURE.md` | #3 #4 #5 |
| `docs/GDD.md` | #3 #5 |
| `data/balance/combat/stats.json` | #4 #8 |
| `data/balance/level_difficulty.json` | #5 #8 |

后合的 PR 先 rebase 到 main 再合。

### 3.1 每个 PR 合并前必须改的地方

括号里是负责人。A-xx / D-xx 见 `DECISIONS_PENDING.md`。

**#7（程序）**：没有设定冲突。确认 CI 三项都绿就合。

**#3 GDD（系统）**

1. `docs/GDD.md` 的「MVP」节和 `docs/ROADMAP.md` 第 2 节：敌人那句补上「ch1_03 少量硬残影」（A-02）。
2. 第 8、9、10、14 条的「待你补充」，改成指向 `docs/design/numeric/`；伤害公式补「最少 1 点」（A-03、A-04、A-07）。
3. 写明 prologue_03 有 1 次三选一（A-18）。
4. 删掉「标题画面可能还写着 The Last Survivor」（A-18）。
5. 加「从当前波重来」的快照字段表（A-11）。

**#8 数值（数值）**

1. 从草稿转为可审。
2. README §7 差异表里的「#4 冰面 ×1.4」「#4 质变 3 层」已经过时，删掉（A-09）。
3. `data/characters.csv` 里「灵符「封魔阵」」改成「梦符「封魔阵」」（A-09）。
4. D-01 拍板后，改 ch1_04 系数（现在是 0.25，推荐 0.70），重新生成 `level_difficulty.json`。
5. 补一行 `CHANGELOG.md`。

**#4 战斗（战斗，部分跟数值）**

1. 去掉 `data/balance/combat/stats.json`；文档里的数字改成指向 #8 的字段路径（A-01）。
2. 硬残影改成 MVP 内只在 ch1_03 少量出现：README「已拍板」第 14 条、§5，以及 `enemies.json` 的 `status: post_mvp`（A-02）。
3. 「普通残影」全部改成「小残影」；文本 key 和 #2 统一（A-15）。
4. 魔理沙的加入时机（`characters.md` 第 15 行、`spell_cards.md` 第 64 行写「序章第 3 波前」），改成「通关 prologue_01 后」（A-16）。
5. 过时的文本 key 换成新格式：`tut.prologue.004/008`、`dlg.prologue.mid.017`、`dlg.ch01.duel.001`（A-16）。
6. 冻结时长统一为 2 秒，冰柱 12 秒（A-08）；Boss 速度 0.4（A-09）。
7. 删掉预留首领 ID `boss_sakuya` 等，改用 `boss_ch2_sakuya_shade` 等（A-17）。
8. 波次时间轴：`core_rules.md` 4.1–4.3 按 D-03 / A-10 改。
9. D-04 拍板后，灵梦默认符卡定稿（`characters.md` 第 14、79 行，`characters.json`）。
10. `rules.json` 的 `mvp_wave_count_max` 不当成硬上限；§6 第 1 条「GDD 仍是旧车道」删掉（A-18）。

**#5 关卡（关卡，部分跟数值）**

1. `level_difficulty.json` 以 #8 为准。`tools/validate_levels.py`（`CALIBRATED_COEFS`、`status: seed`）和 `tests/unit/test_level_data.gd` 改成读 #8 的值（A-01）。
2. `enemy_catalog.json` 和 `rating.json` 不再自带数字，改成引用 #8（A-01、A-06）。
3. 撤掉对 `docs/GDD.md` 的修改（顶部横幅），以 #3 为准（A-18）。
4. D-01 拍板后，ch1_04 的 `enter_wave` 改为 11，`enters_at_wave_id`、`prelude_wave_ids`、`is_boss` 跟着改。
5. `prologue_0*.md` 里的旧文本 key 换成新格式（A-16）。
6. 24 关表的 ch1_03 一行补上硬残影（A-02）。
7. `teaches` 字段分开写主教学点和「提前看见」（A-14）。
8. 紫的换位演示写进 ch1_03 第 6 波，对象是第一只硬残影（A-13）。

**#2 叙事（文案）**

1. 改教学句：`tut.prologue_01.004` 按 D-02 改；`tut.prologue_01.008` 改成「点击下方的符卡按钮」（A-16）。
2. 补雪符「钻石风暴」的名字 key 和 `dlg.ch1_04.mid` 宣言台词（A-16、D-05）。
3. 硬残影「只预告一两只」改掉；`names_zh.csv` 中 `enemy.armored` 的备注改掉（A-02）。
4. 敌人文本 key 按 A-15 统一。
5. 「路会移动」改写成「另一条已画好的路晚开」（A-12）。
6. 首领本人还是残影（第 141、150、156 行）：等 D-09。不影响 MVP，可以先标「待定」再合。
7. 补一行 `CHANGELOG.md`。

> **已核对，不是冲突**：琪露诺通关 ch1_01 后加入、紫通关 ch1_04 后弱化加入，`ccdf270` 已经写对了：
>
> - `story_outline.md` 第 91、94、113 行
> - `dialogue_zh.csv` 的 `dlg.ch1_01.post.001` 和 `dlg.ch1_04.post.001–005`

**#6 美术（美术）**

1. `asset_list_mvp.csv` 的 `spell_fx_mvp` 按 D-04 改（现在写的是梦想封印）。
2. 待确认第 9 条按 D-02 关掉，第 10 条（符卡按钮）划掉，因为方案 A+ 已定（A-16）。
3. 「已定」第 5 条去掉「待最终确认」（A-02）。
4. `ice_block_unit` 的冻结时长说明按 A-08 改。
5. 补大妖精的名字牌和小头像（D-10）。她在 `dlg.ch1_02.post.001`、`dlg.ch1_04.post.008` 有台词，但资源清单里没有。

**#9 QA（游戏测试）**：A-xx / D-xx 落实之后，在 `DESIGN_ISSUES.md` 里把对应的 DI 标成已解决，再合。

## 4. MVP 开发任务

T-00 正在由别人做。下面 T-01 起都排在它后面，按顺序开工。每个任务一个 Cursor cloud agent、一个 PR。

文中路径都是设计 PR 合并后在 main 上的位置。没合并之前，到对应分支去读。

| 简称 | 文件 |
| --- | --- |
| 战斗表 | `data/balance/combat/*.json` |
| 数值表 | `data/balance/combat/stats.json`、`data/balance/level_difficulty.json`、`data/balance/*.csv`、`data/characters.csv`、`data/enemies.csv`、`data/roguelite_buffs.csv`、`data/progression/*.csv` |
| 关卡表 | `data/levels/*.json` |
| 文本表 | `data/text/*.csv` |

### T-00 塔防核心原型（进行中，别人在做）

- **说明**：网格地图、残影沿路线走、在 `.` 格放角色自动攻击、灵力、生命、波次、胜负、色块占位。
- **agent**：https://cursor.com/agents/bc-062dec78-83a7-5a85-9366-e6690ee5d174
- **验收负责人**：战斗策划、关卡策划、游戏测试

### T-01 配置读取层

- **目标**：
  - 新建纯数据类，用 `class_name` 声明：`CombatConfig`、`LevelRepository`、`DifficultyTable`。它们读战斗表、数值表、关卡表。
  - 缺字段或文件坏了只警告并回退，不闪退。
  - 场景脚本不自己解析 JSON。
- **依赖**：#4 `docs/design/combat/data_reference.md`；#5 `docs/design/level/data_format.md`、`data/levels/level.schema.json`；#8 `docs/design/numeric/README.md`
- **验收标准**：
  - GUT 测试覆盖 7 个 MVP 关卡都能加载。
  - 每关能取到槽位、路线、波次，以及「编组 × 系数」后的数量。
  - 能取到每个敌人的血量和漏怪扣命，`boss_cirno` 从 `bosses` 段取。
  - 坏文件只告警不崩溃。
  - CI 绿。
- **卡在**：A-01（要先只剩一份数值表）
- **验收负责人**：数值策划、关卡策划、游戏测试

### T-02 清掉车道占位

- **目标**：
  - 删掉 `scenes/battle/battle_lane.tscn`、`scripts/battle/battle_lane.gd`，以及 `data/balance/starting_balance.json` 里小队人数、加人门、物资这些字段。
  - `GameState` 和 `BalanceConfig` 里的小队逻辑一起删。
  - 「开始」进入 T-00 的塔防场景。
  - 同步改 `docs/ARCHITECTURE.md` 和 `tests/unit/test_scenes.gd`、`test_balance_config.gd`。
- **依赖**：#3 `docs/GDD.md`「明确不做」、`docs/ROADMAP.md` 第 1 节；PR #9 DI-16
- **验收标准**：
  - 仓库里搜不到「小队人数」「车道」这类玩法代码。
  - 标题 → 开始 → 进入塔防场景。
  - 测试改写后全过。
- **卡在**：无
- **验收负责人**：系统策划、游戏测试

### T-03 按关卡数据驱动原型

- **目标**：用 `data/levels/*.json` 驱动 T-00 原型，要支持：
  - 地图字母 `P` / `.` / `B` / `S` / `G`；
  - 多入口、多条固定路线，入口按波次打开；
  - 每波编组按出生间隔出怪；
  - 布阵 10 秒后第一只立刻出场（`waves[0].delay_sec = 0`）、20 秒刷怪窗口、刷完固定空 4 秒，不等清场；
  - 序章 `deploy_wait_for_player`。
- **依赖**：#5 `data_format.md`、`overview.md`、`data/levels/`；#4 `core_rules.md` 4.1–4.3、`terrain_and_map.md` §4；`level_difficulty.json`
- **验收标准**：
  - 7 关都能从选关进入、打完。
  - 出怪数量和 `wave_threat_budgets` 一致，GUT 断言。
  - 计时按 A-10 的时间轴。
  - 打完最后一波还有命即胜，命到 0 即败。
- **卡在**：D-03（计时口径）
- **验收负责人**：关卡策划、战斗策划、游戏测试

### T-04 伤害、敌人和漏怪

- **目标**：
  - 实现 9 步伤害流水线：`max(攻击 − 护甲, 攻击 × 0.2)`，最少 1。
  - 实现小、快、硬三种残影：移速、护甲、漏怪扣命、击破掉落灵力。
  - 击倒光点飞向灵力栏。
  - 硬残影出现「护甲」提示。
- **依赖**：#4 `damage_and_status.md`、`enemies_and_bosses.md`；`stats.json` 的 `enemies`
- **验收标准**：
  - GUT 覆盖伤害公式边界：护甲大于攻击、最少 1 点。
  - 漏怪扣命按 `stats.json`。
  - ch1_03 的 8 只硬残影按波出现。
- **卡在**：A-01、A-03
- **验收负责人**：战斗策划、数值策划、游戏测试

### T-05 MVP 角色和局内升级

- **目标**：
  - 实现灵梦、魔理沙、琪露诺、紫的普攻和技能：灵梦追踪符札加结界易伤、魔理沙直线穿透、琪露诺减速加冻结、紫隙间换位。
  - 同名最多 3 个，费用 1.5 / 2 倍。
  - 局内升级 2 次（1.0 / 1.4 / 1.8，费用 50 / 100），可以卖出。
  - 升级外观先用色块。
- **依赖**：#4 `characters.md`、`characters.json`；`data/characters.csv`；#8 `01_combat_and_characters.md`
- **验收标准**：
  - 4 名角色的行为和文档一致。
  - 费用、攻击、射程、间隔都从表里读。
  - 放第 4 个同名角色时被拒绝。
  - GUT 覆盖升级和卖出的灵力结算。
- **卡在**：D-02（放置操作）、A-05
- **验收负责人**：战斗策划、数值策划、游戏测试

### T-06 状态和地形

- **目标**：
  - 实现减速、冻结（含冻结免疫）、结界标记。
  - 实现地形：浓雾（站在雾格上射程 −1）、冰面（移速 ×1.5）、冰柱（挡直线、占槽位）、灵梦结界。
  - 实现冰碎联动。
- **依赖**：#4 `damage_and_status.md`、`statuses.json`、`terrain.json`、`terrain_and_map.md`；#8 `stats.json` 的 `terrain`
- **验收标准**：
  - ch1_01–03 的雾按关卡数据在指定波次出现。
  - 冻结时长按 A-08。
  - GUT 覆盖状态叠加和免疫。
- **卡在**：A-08
- **验收负责人**：战斗策划、关卡策划、游戏测试

### T-07 符卡系统

- **目标**：
  - 全队共用一条能量条，按 70/30 规则充能；危急时 ×1.5；序章 ×2。
  - 符卡使方案 A+：布阵期和波间可以换，波次中不能换，换人清空能量。
  - 手动释放，自动释放是全局开关、默认关。
  - 做 4 名 MVP 角色的默认符卡效果。
  - 立绘演出先用占位：遮罩加色带。
- **依赖**：#4 `spell_cards.md`、`spell_cards.json`、`rules.json`；#8 `04_spell_energy.md`
- **验收标准**：
  - 普通约 60 秒、危急约 40 秒充满，允许 ±15%。
  - 自动开关在局内随时能切。
  - 换符卡使后能量为 0。
- **卡在**：D-04（灵梦默认符卡）
- **验收负责人**：战斗策划、数值策划、游戏测试

### T-08 三选一强化

- **目标**：
  - 每 5 波弹一次三选一，最后一波不弹。prologue_01、02 不弹；prologue_03 弹 1 次。
  - 只管当局，过关清空。
  - 叠到 2 层质变。已拥有但没质变的强化，下次保底出现一个。
  - 做 MVP 强化池。
  - 卡面区分三种状态：新强化 / 再叠一层 / 这次会质变。
- **依赖**：#4 `roguelite_buffs.md`、`buffs.json`、`synergies.json`；`data/roguelite_buffs.csv`；#8 `08_roguelite_buffs.md`；#6 `ui_visual_spec.md` 三选一卡
- **验收标准**：
  - 7 关的弹出次数和波次与关卡 JSON 的说明一致。
  - GUT 覆盖保底和质变。
- **卡在**：D-06（强化池）
- **验收负责人**：战斗策划、数值策划、游戏测试

### T-09 首领冰之残影（ch1_04）

- **目标**：
  - 冰之残影按 `enter_wave` 入场。
  - 三阶段（100% / 66% / 33%）：冰瀑冰柱落在预定槽位、完美冻结半径 2.5 格、钻石风暴让前方 10 格路线结冰。
  - 换阶段时短暂无敌。
  - 走到守护点扣命，回裂缝重走。最后一波要等她被击败才算打完。
  - Boss 血条显示阶段分隔点。
  - 「Boss 血量乘不乘关卡倍率」做成可配置。
- **依赖**：#4 `enemies_and_bosses.md`、`bosses.json`；#5 `data/levels/ch1_04.json`、`docs/design/level/ch1_04.md`；#8 `06_level_curve.md` §5
- **验收标准**：
  - 三阶段按血量切换。
  - 用 D-01 定下的规则时，按推荐摆法能通关，剩余生命约等于首通目标。
- **卡在**：D-01（最阻塞）、D-05、A-08
- **验收负责人**：战斗策划、关卡策划、数值策划、游戏测试

### T-10 从当前波重来、整关重打、中途退出

- **目标**：
  - 每波开始时存一份局内快照，字段按 A-11 的表。
  - 失败界面给「从当前波重来」和「整关重打」两个选项。
  - 中途退出不给奖励。
  - `SaveGame` 升版本，并做迁移。
- **依赖**：#3 `docs/GDD.md`「核心循环」、`docs/ROADMAP.md` 第 1 节；#4 `core_rules.md` 5.2；`scripts/save/save_game.gd`
- **验收标准**：
  - 从第 N 波重来后，快照里每个字段都和第 N 波开始时一致，GUT 断言。
  - 退出后局外进度不变。
- **卡在**：A-11
- **验收负责人**：系统策划、战斗策划、游戏测试

### T-11 结算和星级

- **目标**：
  - 胜利和失败结算界面。
  - 星级：通关 1 星、剩 ≥ 10 得 2 星、20/20 得 3 星，重打可以补拿。
  - 显示本次获得的局外资源。
- **依赖**：#3 GDD「关卡推进」；#5 `data/levels/rating.json`；#8 `05_meta_progression.md`
- **验收标准**：
  - 星级边界 9 / 10 / 19 / 20 条命，GUT 断言。
  - 重打只补拿更高档，不重复给。
- **卡在**：D-07、A-06
- **验收负责人**：系统策划、数值策划、游戏测试

### T-12 选关、解锁和局外养成

- **目标**：
  - 选关界面：章节标签、锁、星数。
  - 剧情解锁链：魔理沙 prologue_01 后、琪露诺 ch1_01 后、紫 ch1_04 后。紫只在重打已通关关卡时可放。
  - 每个角色 1–20 级，一种通用资源，首通和重打给的数量不同，由玩家选给谁升级。
  - 存档。
- **依赖**：#3 GDD「局外养成」「关卡推进」；#5 `data/levels/index.json`、`character_roster.json`；`data/progression/*.csv`；#8 `05_meta_progression.md`；#6 `ui_level_select`、`ui_meta_upgrade`
- **验收标准**：
  - 首通 7 关时，每关可放置的角色名单和 `available_character_ids` 一致。
  - 通关 ch1_04 后，重打前面的关可以放紫。
  - 资源数量按表。
- **卡在**：A-07；D-08 不卡（界面先用 key `currency.meta`）
- **验收负责人**：系统策划、数值策划、文案策划、游戏测试

### T-13 局内界面（HUD）

- **目标**：按 `ui_visual_spec.md` 做 1080×1920 布局：
  - 顶部栏：灵力、生命、波次、暂停；
  - 底部角色栏 2×2，头像带「×n/3」；
  - 符卡按钮和能量环、自动开关、倍速、叫波；
  - 长按放置格弹出气泡；
  - 长屏和刘海安全区。
- **依赖**：#6 `docs/design/art/ui_visual_spec.md`、`asset_specs.md`；#4 `core_rules.md` §6
- **验收标准**：
  - 在 1080×1920 和 1080×2400 两种分辨率下截图对照规格。
  - 单手能完成放置、升级、释放符卡。
- **卡在**：D-02
- **验收负责人**：美术策划、战斗策划、游戏测试

### T-14 文本表接入和剧情对话

- **目标**：
  - 把 `data/text/*.csv` 登记进 `project.godot` 的翻译。
  - 关卡前、中、后的对话播放器，用 key 规则 `dlg.<关卡id>.<pre|mid|post>.NNN`。
  - 名字牌。
  - 失物簿界面，按星数解锁。
  - 界面文字全部走 key。
- **依赖**：#2 `docs/design/narrative/dialogue_samples.md`、`glossary.md`、`lost_and_found.md`、`data/text/dialogue_zh.csv`、`names_zh.csv`、`lostbook_zh.csv`
- **验收标准**：
  - 7 关的 pre / mid / post 对话都能按时机播放。
  - 不缺字（Noto Sans SC 子集）。
  - 界面里没有硬编码的中文。
- **卡在**：A-15、A-16
- **验收负责人**：文案策划、游戏测试

### T-15 序章教学引导

- **目标**：
  - 序章 3 关的教学步骤（`tut.prologue_0X.NNN`）。
  - 引导高亮框，放好之前不出怪。
  - prologue_03 第一次三选一的引导。
  - ch1_03 第 6 波紫的隙间换位演示（A-13）。
- **依赖**：#5 `prologue_01–03.md`；#2 `dialogue_zh.csv`（tut）；#6 `ui_guide_highlight`
- **验收标准**：
  - 新玩家不看文档也能完成序章。
  - 每一步教学都有明确的触发条件和完成条件。
- **卡在**：D-02、A-16、A-14
- **验收负责人**：关卡策划、文案策划、游戏测试

### T-16 占位美术资源接入

- **目标**：
  - 按 `asset_specs.md` 建好目录和命名规则（ID ↔ 文件名），设好导入设置。
  - P0 资源先全部用同尺寸色块占位接上。
  - `palette_swap` 着色器、冰色残影着色器、紫的「褪色」外观（`yukari_faded`）。
  - 加载失败时有兜底。
- **依赖**：#6 `asset_specs.md`、`asset_list_mvp.csv`、`art_style_guide.md`
- **验收标准**：
  - `asset_list_mvp.csv` 里每个 P0 都有对应的文件或占位。
  - 换成正式图时不用改代码。
- **卡在**：A-20（不阻塞）
- **验收负责人**：美术策划、游戏测试

### T-17 打击反馈和手感

- **目标**：按 `feedback.md` / `feel.json` 做：
  - 命中闪白、伤害数字（上限和合并）、击倒光点、灵力跳动；
  - 冰碎、Boss 血条、升级闪光；
  - 震屏开关、符卡演出的长短设置。
- **依赖**：#4 `feedback.md`、`feel.json`；#6 `vfx_visual_spec.md`
- **验收标准**：
  - 参数都从 `feel.json` 读。
  - 同屏数量不超过 `rules.json` 的 `performance` 上限。
  - 中端机 60 帧。
- **卡在**：无
- **验收负责人**：战斗策划、美术策划、游戏测试

### T-18 MVP 通关回归和 APK 冒烟

- **目标**：
  - 无头脚本按推荐摆法自动打 7 关，输出剩余生命，和 #8 的模拟结果对照。
  - CI 出调试 APK，装到真机冒烟：标题 → 序章 → ch1_04 → 结算。
- **依赖**：#8 `tools/numeric/`、`docs/design/numeric/generated/sim_results.md`；PR #9 `docs/qa/TEST_PLAN.md`、`MVP_ACCEPTANCE.md`、`LEVEL_SIM.md`
- **验收标准**：
  - 7 关都能通关。
  - 剩余生命和首通目标的偏差在 ±3 以内，超出的列成数值问题。
  - `MVP_ACCEPTANCE.md` 全部勾完，或列出原因。
- **卡在**：D-01
- **验收负责人**：数值策划、关卡策划、游戏测试（执行制作人总验收）

## 5. 还缺、没有人负责的东西

1. **音频**：`assets/audio/` 是空的。`feedback.md` 有音效列，但没有音效和 BGM 清单、来源、许可证，也没有负责人。需要指定一位负责人，或者让美术策划兼一份音频清单（登记在 `CREDITS.md`）。
2. **程序架构**：场景和节点结构、局内状态机由谁写进 `docs/ARCHITECTURE.md`，建议由 T-00 的 agent 补上。
3. **教学的可测标准**：#9 DI-17 提出的「每关只教一件新事」，要等 A-14 落实后才能验收。
