# 执行制作人交接

> 写于 2026-10-02（UTC+8）。聊天侧的执行制作人因 token 用尽停手，从这一份起由接手的 agent 继续。
> 和 [`PLAN.md`](PLAN.md)、[`DECISIONS_PENDING.md`](DECISIONS_PENDING.md) 一起看。三份不一致时，以本文件写明的「已定」和用户最新交代为准，并回头改另外两份。
> 角色规则在 PR #13（分支 `docs/agent-roles`，head `e3e91ae`）的 `docs/production/ROLES.md` 和 `.cursor/skills/`。那份 PR 还没合并，用 `git show origin/docs/agent-roles:<路径>` 读。

## 0. 接手后立刻遵守

- 从 2026-10-02 起，Grok Bot 暂停。派工、返工、叫醒别的 agent，都由执行制作人直接做，不再经 Grok Bot。
- 中文写文档、PR 描述和评论。不合并任何 PR，不点 Approve，不推 `main`，不改 `docs/PR_STATUS.md`。合并和拍板只由用户 @XYN159 决定。
- 角色必须好看，字体用东方风格。带界面的 PR 必须过动效师审核，画面不好看不放行。
- 开发 PR 按 `ROLES.md` 第 4 节，用对应角色在 PR 下留中文评论。带界面的 PR 还要动效师审。汇总结论只有「可以合并」或「需要返工」。
- 角色好不好看，最终由用户亲自点头。用户没点头之前，不能给角色美术 PR「可以合并」。
- 本交接不替用户合并。下面的顺序是建议，等用户自己点合并。
- 2026-10-02 起，聊天侧的六位策划和游戏测试停手。停手后的那一轮未完成修改，已由执行制作人按角色补进各 PR（提交号见第 2 节）。用户随后把这七个角色搬到 Cursor。之后的策划修改、审核和测试验收，由执行制作人分派给第 0.1 节的 agent，不再由制作人改他们的文件。仍然不合并。还没定的事继续问用户。

### 0.1 策划和测试的 agent

用户把下面七个角色搬到 Cursor。执行制作人统一分派：改文档、留审核评论，都发给对应的 agent。链接是 `https://cursor.com/agents/<id>`。

| 角色 | `ROLES.md` | agent |
| --- | --- | --- |
| 系统策划 | 第 5 节 `system-designer` | [bc-d4c93e72-ea81-5a53-9645-c599dbfc658d](https://cursor.com/agents/bc-d4c93e72-ea81-5a53-9645-c599dbfc658d) |
| 数值策划 | 第 6 节 `numeric-designer` | [bc-49c67e0a-9266-5682-9aaa-fa0d488908ff](https://cursor.com/agents/bc-49c67e0a-9266-5682-9aaa-fa0d488908ff) |
| 文案策划 | 第 7 节 `narrative-designer` | [bc-976aafe6-cbf0-5222-878b-aecb9e0f87b8](https://cursor.com/agents/bc-976aafe6-cbf0-5222-878b-aecb9e0f87b8) |
| 关卡策划 | 第 8 节 `level-designer` | [bc-6f15e683-ffc0-52fe-8694-75d1953fd04b](https://cursor.com/agents/bc-6f15e683-ffc0-52fe-8694-75d1953fd04b) |
| 战斗策划 | 第 9 节 `combat-designer` | [bc-4fa5baf3-7f5f-5fae-a4c1-517e087bfbce](https://cursor.com/agents/bc-4fa5baf3-7f5f-5fae-a4c1-517e087bfbce) |
| 美术策划 | 第 10 节 `art-designer` | [bc-f9d00968-aefa-521c-b290-c66b48800915](https://cursor.com/agents/bc-f9d00968-aefa-521c-b290-c66b48800915) |
| 游戏测试 | 第 13 节 `qa-tester` | [bc-44ef6f13-a35e-52a3-b0c2-0db173efc126](https://cursor.com/agents/bc-44ef6f13-a35e-52a3-b0c2-0db173efc126) |

动效师（第 11 节 `ui-motion-designer`）还没有常驻 agent。带界面的 PR 要审时，按 `ROLES.md` 第 11 节另开一个，评论开头「【动效师审核】」。不要把动效审派给美术策划。#12 这一轮另开的是 [bc-04f23713-8a1c-515d-b28d-8e4e7d211378](https://cursor.com/agents/bc-04f23713-8a1c-515d-b28d-8e4e7d211378)，只审这一轮。

### 0.2 程序分工

大团队里「程序」会拆成主程、客户端、玩法、战斗、UI、系统、AI、图形、TA、工具、引擎、服务器。这个项目现在是小团队，按下面这张表兼岗，不按那棵树各开一个 agent。

| 岗位 | 现在谁做 | 什么时候再单开 |
| --- | --- | --- |
| 主程 | 不单开。技术取舍写在已有的 `docs/ARCHITECTURE.md` 和 `docs/adr/`。执行制作人派任务，不另写一套架构文档 | 战斗或存档的结构真的拆不动时再开 |
| 玩法程序、战斗程序、客户端里这一关的输入和场景 | [bc-c2fac131-4f71-52a1-b1c2-f74302385ab9](https://cursor.com/agents/bc-c2fac131-4f71-52a1-b1c2-f74302385ab9) | 用 Opus 5.5。一张任务一个 PR |
| UI 程序 | 先不单开。界面好看归动效师，动效师还没有常驻 agent | T-20 |
| 系统程序（局外、结算、存档） | 先不单开 | T-10、T-11 开工时，仍优先交给上面同一个程序 agent |
| 工具程序 | 先不单开。数值生成脚本已经在 #8 | 要做关卡编辑器时再开 |
| 敌人 AI | 先不单开。残影沿开战前画好的路线走，不追玩家 | 出现会自己选路的敌人时再开 |
| 图形、TA、引擎 | 先不单开。色块和现有 Godot 够用 | 要写 shader 或自研管线时再开 |
| 服务器 | 不开。多人、账号、联网不在当前范围 | 先有新的 ADR，并且用户点头 |

执行制作人按 `ROLES.md` 附录 A 派任务。程序不改策划文档里的已定规则，也不把已经废弃的车道、加人门、小队人数做回来。需求落到哪个表、哪个场景，沿用现有的 `docs/GDD.md`、`docs/ARCHITECTURE.md` 和各设计 PR，不另建 `SYSTEMS.md`、`DATA_SCHEMA.md`、`TECH_DESIGN.md`。

模型：改脚本、场景、测试的程序任务用 Opus 5.5（派工时选 `claude-opus-5-5-high`）。策划、审核、文档和其他不写代码的任务用 Grok（派工时选 `grok-4.7-high`）。动效如果要改场景或脚本，也算写程序，用 Opus 5.5。

[bc-24406a2e-50cf-5dde-a9cd-1106db7248f3](https://cursor.com/agents/bc-24406a2e-50cf-5dde-a9cd-1106db7248f3) 是 Grok，已经把分支 `cursor/prologue-01-playable-48f3` 推到 `119fe9c`，但没有 PR。不要给这个分支开 PR，也不要派美术和动效到这上面。序章第一关以 Opus 5.5 的 [bc-c2fac131-4f71-52a1-b1c2-f74302385ab9](https://cursor.com/agents/bc-c2fac131-4f71-52a1-b1c2-f74302385ab9) 为准。

第一张卡：从塔防原型最新提交另开分支，把序章第一关 `prologue_01` 接到「开始」上，打完能结算。不推 PR #12。七关一起接、符卡、三选一都不在这张卡里。

程序这张卡交出版本之后，立刻做两件事，现在都不要派：

1. 派美术策划 [bc-f9d00968-aefa-521c-b290-c66b48800915](https://cursor.com/agents/bc-f9d00968-aefa-521c-b290-c66b48800915) 把这一关的背景图和画面做到能看的完成度。信息排布参考明日方舟这种用户最多的二次元塔防：分层的关卡背景、路线一眼能看清、角色立绘或头像在侧、技能和费用信息清楚。画出来的风格必须是东方：神社、符札、阴阳、和风建筑和植物，角色用 #14 已选定的 v2。不要做成现代军事或科幻干员界面。本作是竖屏 1080×1920，布局按竖屏重排，不要改成横屏。只参考完成度，不使用明日方舟或东方 Project 的官方图、截图和素材。范围是标题和这一关战斗里看得见的背景与画面。不改玩法，不重画四个角色的概念图，也不提前做 T-19b。
2. 按 `ROLES.md` 第 11 节另开动效师，做这一关的动效，不只是审。手感参考这种二次元塔防：进关、放角色、按钮按下、受击和结算要有反馈，动效不挡住路线和血量。反馈的样子用符札、结界和和风光点，不用科幻准星。动效师还没有常驻 agent，到时候新开，改场景或脚本用 Opus 5.5，评论开头「【动效师审核】」。不要把动效派给美术策划代做。完整的东方字体和 T-20 那一套仍等 #12 合并后再做；这一关交出版本后的动效不能漏。

画面好不好看仍要用户点头。色块原型不能当成这一关的最终画面。动效师没通过，不能写「可以合并」。

## 1. 已定，不再问用户

这些已经写进 `DECISIONS_PENDING.md` 的「已定规则」。这里只列接手时必须记住的：

- **#8 是唯一数值来源**（分支 `numeric/touhou-td-framework`）。别的 PR 不保留自己的数字副本。
- **硬残影进 MVP**，8 只只在 `ch1_03`（第 6 到 11 波各 1 只，第 12 波左右各 1 只）。
- **战斗中路线不变。** 路线开战前就画好。
- **加入时机**：灵梦开局；魔理沙通关 `prologue_01` 后；琪露诺通关 `ch1_01` 后；紫通关 `ch1_04` 后以弱化（半褪 / 褪色）加入，MVP 里只在重打已通关关卡时可放。
- **放置**：先点格子，再点角色头像。只能放在 `.` 格。
- **符卡能量满值**按当前符卡使读 #8 的 `spell_energy_max`，不是固定 100。
- **换符卡使**：布阵时和两波之间可以换，换后能量清零。波次进行中不能换。
- **冻结时长归 #8。** 战斗和美术只引用，不另写一套秒数。
- **灵梦 MVP 默认符卡是封魔阵**（梦符「封魔阵」）。梦想封印是第二张。
- **波次节奏**：10 秒布阵；第一只敌人立即出；20 秒出怪窗口；两波之间固定 4 秒；不等清场。
- **D-01**：Boss 第 11 波登场，血量不加成。`ch1_04` 系数已由数值锁定为 **0.74**（#8 `ac47c18`）。5 个种子平均剩余 10.0，平滑期望 11.9，最差种子 −9。第 2 到 5 章首领关还没按「血量不乘倍率」重跑。
- **D-05 的推荐**（条目本身还没拍板）：用雪符「钻石风暴」；**不能连点破冰**。
- **T-19a 选定**：四个角色都用 **v2**。紫的半褪用 **v2 版**。见第 5 节。总览中文已在 #14 `01fe51c` 重画。还没有合并。

## 2. 合并顺序

#7 → #3 → #8 → #4 → #5 → #2 → #6 → #9 → #11 → #13。

#12、#14 不插进这条设计文档顺序。#10 是 GitHub 整理员的状态页，别人不碰。

提交号核对于 2026-10-02（UTC+8）。`export-android` 在 #7 以外的 PR 上是红的，原因是 `main` 的 `ci/export_android_debug.sh` 少了一个 `}`，不是这些 PR 自己改坏的。

| 顺序 | PR | 分支 | head | 现在能不能合 |
| --- | --- | --- | --- | --- |
| 1 | #7 修 CI | `cursor/fix-android-export-brace-2717` | `ab3f279` | 先合。lint / test / export-android 都绿 |
| 2 | #3 GDD | `docs/gdd-touhou-td` | `6d18f33` | 可以合并 |
| 3 | #8 数值 | `numeric/touhou-td-framework` | `ac47c18` | 系数 0.74、第 11 波、血量不乘倍率、叫波上限 20、战斗要的字段都已写入。合完 #3 再合它 |
| 4 | #4 战斗 | `cursor/docs-combat-rules-354a` | `ad8ab29` | 空档改为窗口结束后固定 4 秒。可以合并。等 #8 之后，避免数值副本冲突 |
| 5 | #5 关卡 | `cursor/design-level-framework-01a3` | `822ae26` | `enter_wave` 已是 11。出怪数量还没按 0.74 的每波预算重排 |
| 6 | #2 叙事 | `docs/touhou-narrative-draft` | `02c7ba6` | 等 #4、#5 合并后可以合并。这次没有新的已定文案要改 |
| 7 | #6 美术 | `docs/art-framework` | `fe0f3d5` | 封魔阵已按 D-04 写成定案。可以合并。顺序上排在 #2 后面 |
| 8 | #9 QA | `cursor/docs-qa-plan-fc39` | `e1259d9` | DI-06 的入场和血量已改成已定。DI-07 漏怪扣命仍开着。设计文档齐了再合 |
| 9 | #11 本计划 | `docs/production-plan` | 本分支 | 请用户审核，不要自动合并 |
| 10 | #13 角色手册 | `docs/agent-roles` | `e3e91ae` | 待用户审核。紧跟 #11，或和 #11 一起看 |

会冲突的文件仍见 `PLAN.md` 第 3 节。后合的先 rebase 到 `main`。

## 3. 各 PR 还要做什么

细节和负责人在 `PLAN.md` 第 3.1 节。交接时只强调还没做完的：

- **#8**（`ac47c18`）：系数锁定 0.74。Boss 第 11 波、血量不乘倍率。`stats.json` 补了 `characters.<id>.attack`、`in_battle_upgrade`、`economy.early_call_reward_cap` = 20，Boss 在 `enemies` 和 `bosses` 里各有一份相同数字。封魔阵写成梦符。README 里过时的「冰面 ×1.4」「质变 3 层」两行已删。
- **#5**（`822ae26`）：`enter_wave` 是 11，前奏、`enters_at_wave_id`、`is_boss` 已对齐。出怪数量还是旧编组，等按 0.74 的 `wave_threat_budgets` 重排。这一轮没有重排，避免猜数量。
- **#4**（`ad8ab29`）：空档从 20 秒窗口结束起算，固定 4 秒。删掉 3 到 5 秒。
- **#6**（`fe0f3d5`）：默认符卡改成已定的梦符「封魔阵」。
- **#9**（`e1259d9`）：DI-06 的入场和血量不再待拍板。漏一次扣多少仍是 DI-07，要问用户。
- **#2、#3**：这次没有新的已定修改。#2 仍等 #4、#5 进 `main` 再合。
- **#12、#14**：见第 4、5 节。不在上表的顺序里。

## 4. PR #12（T-00 原型）可以合并，等用户点

- PR：https://github.com/XYN159/Touhou-forgotten-defense/pull/12
- 分支：`cursor/battle-core-prototype-d174`
- 返工 head：`b5b3bed`（已不是草稿）。上一轮「需要返工」看的是 `452f1b3`，不作为这一版的结论。
- head 现为 `81c5d04`。`ui.menu.subtitle` 已是「东方 Project 二次创作」。文案复审通过。执行制作人汇总是可以合并，等用户点。
- 原原型 agent：[bc-062dec78-83a7-5a85-9366-e6690ee5d174](https://cursor.com/agents/bc-062dec78-83a7-5a85-9366-e6690ee5d174)
- 上一轮正式审核：[战斗策划](https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5946132717)、[执行制作人汇总](https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5946132812)。评论 `5945898325` 是更早的一份战斗验收，和后来的更正有冲突，不以它为返工清单。

2026-10-02 已按第 4.1 节派出复审，只看 `b5b3bed`。分派时，第 0.1 节里的战斗策划和数值策划正在跑更早的任务，关卡、文案、游戏测试当时空闲，follow-up 没有附到那些原 agent 上，这一轮实际在审的是下面这些。动效师按第 11 节另开，东方字体和 Theme 归 T-20，不挡这个色块原型。

| 角色 | 这一轮实际在审 |
| --- | --- |
| 战斗策划 | [bc-3b0c8fde-57b3-5820-a844-54c36f207d07](https://cursor.com/agents/bc-3b0c8fde-57b3-5820-a844-54c36f207d07) |
| 数值策划 | [bc-8f07b024-f775-543e-88e9-8cde9b93c939](https://cursor.com/agents/bc-8f07b024-f775-543e-88e9-8cde9b93c939) |
| 关卡策划 | [bc-44b1f8f0-2cae-5268-99df-8759e291015d](https://cursor.com/agents/bc-44b1f8f0-2cae-5268-99df-8759e291015d) |
| 文案策划 | [bc-6664af32-85c4-582d-a3d9-10477ad558af](https://cursor.com/agents/bc-6664af32-85c4-582d-a3d9-10477ad558af) |
| 游戏测试 | [bc-9c0a15aa-e590-568c-8a41-6a1d1a5c0cbd](https://cursor.com/agents/bc-9c0a15aa-e590-568c-8a41-6a1d1a5c0cbd) |
| 动效师 | [bc-04f23713-8a1c-515d-b28d-8e4e7d211378](https://cursor.com/agents/bc-04f23713-8a1c-515d-b28d-8e4e7d211378) |

要合并的评论（以这些为准，互相打架时以下面的返工清单为准）：

| 角色 | 评论 |
| --- | --- |
| 执行制作人 | https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5945901786 |
| 执行制作人更正（波次） | https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5945923597 |
| 数值策划 | https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5945975154 |
| 游戏测试 | https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5946033758 |

### 4.1 必须改

1. **放置顺序反了。** 改成先点格子，再点角色头像。提示文字、场景里的提示、PR 描述里的验证步骤一起改。
2. **波次节奏**（以更正评论为准，不要把波内间隔改成 4 秒）：
   - `waves[0].delay_sec = 0`，去掉「第一波不读 delay」的特判。
   - `duration_sec` 当作 20 秒出怪窗口，从这一波开始时算。
   - 两波间隔固定 4 秒，从出怪窗口结束起算，不等清场。
   - 删掉 `intermission_min_sec` / `intermission_max_sec`，以及「清场就缩短空档」的逻辑和对应测试。
   - 波内 `interval_sec` 按这一波的数量摊在 20 秒里（原型可用 `duration_sec / 数量`）。
3. **玩家能看见的文字都走文本 key**，加一张翻译 CSV，并在 `project.godot` 里登记。角色、敌人、关卡、HUD、按钮、结算都走 key。日志和 `push_warning` 不用改。
4. **快残影用战斗文档里的正式名字。** #4 `a061f11` 的 `docs/design/combat/enemies_and_bosses.md` 里，`enm_shade_fast` 的玩家可见名就是「快残影」，key 是 `enemy.shade_fast.name`。制作人评论 `5945901786` 第 4 点要求改成「遗忘残影 / 堆积残影 / 结界残影」，**那一点作废**。不要改 id。遗忘残影、堆积残影、结界残影是别的预留敌人。
5. **第 k 个同角色的费用** = 部署费 × (1 + 0.5 × (k − 1))。现在的代码是连乘，测试里的 `113` 是按错公式写的，要一起改。
6. **敌人血量乘 `hp_multiplier`。** #8 里这个字段是字符串，用浮点读，不要截成整数。
7. **射程和攻击间隔读 #8。** 先认嵌套的 `attack.range_cells`、`attack.interval_sec`，再认扁平的旧字段，最后才退回 `characters.json`。
8. **同名上限用每个角色自己的 `max_copies`。** 没有这个字段时再用全局值。
9. **正式表依赖 #4、#5、#8。** 注释和 ADR 里写清楚。`USE_OFFICIAL_TABLES` 打开时，缺文件或缺关键字段用 `push_error`，不要悄悄用默认值。
10. **删掉旧车道的 GUT 用例**：`tests/unit/test_scenes.gd` 第 30–37 行，以及 `test_balance_config.gd`、`test_save_game.gd` 里还在保护小队和物资的断言。

草稿已经转为 ready for review。复审已派出，见本节开头的表。

### 4.2 可选，不挡这一轮合并

- 命中闪白的强度和颜色读 `feel.json`。
- 倍速读 `rules.json` 的 `time_scale`，不要在 1 和 2 之间写死翻转。
- `deploy_wait_for_player` 记入后续（切到正式序章之前要做，这一轮可以不做）。

### 4.3 不要自己加进去的

- **提前叫波**还没拍板，见 D-18。MVP 可以先不做叫波。更早的战斗验收要求「出怪窗口里也能叫波」，先不要当成必须改。
- 符卡、三选一、Boss 折返不在 T-00 这一轮的必须范围里。

## 5. PR #14（T-19a）和后面的美术、界面

- PR：https://github.com/XYN159/Touhou-forgotten-defense/pull/14
- 分支：`art/t19a-character-concepts`
- head：`01fe51c`（在 `d50480e` 之后补了一笔）
- 用户已经选定：**灵梦、魔理沙、琪露诺、紫都用 v2；紫的半褪用 v2 版。**

`01fe51c` 已经做完合并前要的两件事：

1. `overview.png` 顶部和底部的中文，改用仓库里的 `assets/fonts/NotoSansSC-Regular.ttf` 重画。2026-10-02 核对过，不再是方块。
2. 选定版本写在 `docs/design/art/concepts/SOURCES.md`，也写在 PR 描述里。v1、v3 留着作参考，没有删。v2 原图没有改。

角色图本身和 `d50480e` 相同。`01fe51c` 上已有美术策划、游戏测试和执行制作人汇总，结论是可以合并。等用户合并。不要再派修图。

### T-19b（#14 和 #12 都合并之后才能派）

不要现在派。两份都进 `main` 之后，从当时的 `main` 开分支 `art/t19b-portraits-sprites`，按下面的原文派，不改范围：

- 照 v2 做四个角色的游戏内立绘，以及棋盘小人（待机、攻击两种姿态）。
- 另加紫的半褪立绘。
- 规格按 `docs/design/art/`（PR #6，没合并就到 `docs/art-framework` 上读）。
- 纹理用 Linear 过滤，不开 mipmap。
- 源文件（分层稿）不进仓库。
- 接到原型里，并出一张总览图。图上的中文不能乱码。
- 验收：美术策划、游戏测试、动效师。角色好不好看由用户亲自点头，没点头不能合。

### T-20（#12 合并之后才能派）

不要现在派。#12 进 `main` 之后，从当时的 `main` 开分支 `feat/t20-ui-polish`。字体必须是东方风格。范围是标题画面、战斗 HUD、角色栏、结算。附改前、改后截图。

- 两款 OFL 字体：霞鹜文楷，再加思源宋体或得意黑。字体开 MSDF。
- `project.godot` 的拉伸模式用 `canvas_items`。
- 标题金色 `#E8C872`，6px 深棕描边。
- 三层背景：插画、暗角、大约 30 个 `CPUParticles2D`（樱花或光点）。
- 按钮用 `StyleBoxFlat`：圆角 8、1px 金边、半透明底，并带 hover、pressed。
- 标题用 Tween 淡入，然后上下浮动 2–4px，周期 2–3 秒。
- 按钮悬停放大到 1.05，点击闪一下。底部提示的透明度做脉动。
- 凡是改 UI 的 PR 都要过动效师审。画面不好看不放行。

## 6. 还等用户拍板

完整选项和推荐在 `DECISIONS_PENDING.md`。阻塞程度没变的不在这里重复论证。

| 编号 | 要用户选的 | 推荐 | 挡不挡 MVP |
| --- | --- | --- | --- |
| D-05 | 第三阶段用不用钻石风暴；被冻住能不能连点破冰 | 用钻石风暴；不能连点 | 部分阻塞 T-09 |
| D-06 | MVP 认可哪些联动和强化 | 先做符札引爆，以及寒气、分裂弹、会心、锐利、连射、充能、修补 | 不阻塞 |
| D-07 | 结算画面显示什么 | 过关与否、剩余生命、星级、本次局外资源；失败给两种重来 | 部分阻塞 |
| D-08 | 局外资源叫什么 | 「忆晶」，key `currency.meta` | 界面可先用 key |
| D-09 到 D-17 | 见决策清单 | 见决策清单 | 不阻塞，或发布前再看 |
| D-18 | 刷怪窗口里能不能提前叫下一波 | 可以叫；没出的怪照常出并重叠。上限已由 #8 定为一次最多 20。功能开不开仍要问用户。MVP 可以先不做 | 不阻塞 |
| D-19 | 美铃放在哪种格子 | 紧贴路线的 `.` 格，不破坏「只能放 `.`」 | 不阻塞。美铃不是 MVP 角色 |

D-01、D-02、D-03、D-04 已定，不要再问。

## 7. 现在谁在等什么

已经做完、不要再派：

- **#14 / T-19a**：乱码由 agent [bc-97f23ac2-10b8-503a-917f-c8fc5d4870ca](https://cursor.com/agents/bc-97f23ac2-10b8-503a-917f-c8fc5d4870ca) 在 `01fe51c` 修好。四人 v2 已写进 PR。等用户合并。
- **#12 的上一轮审核**：针对 `452f1b3`，结论是需要返工。标题声明随后推到了 `81c5d04`。

正在做：

- **#12**：`81c5d04` 文案复审通过，汇总是可以合并。等用户点，不要自动合并。
- **程序第一张卡**：以 Opus 5.5 的 [bc-c2fac131-4f71-52a1-b1c2-f74302385ab9](https://cursor.com/agents/bc-c2fac131-4f71-52a1-b1c2-f74302385ab9) 为准，还在做。Grok 已推 `cursor/prologue-01-playable-48f3` @ `119fe9c`，不给它开 PR。
- **状态页**：整理员 [bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344](https://cursor.com/agents/bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344) 没有被原会话叫醒。刷新发给了 [bc-f9b5cac4-b05b-5ecd-a1e0-1dce1ea95eee](https://cursor.com/agents/bc-f9b5cac4-b05b-5ecd-a1e0-1dce1ea95eee)，只许改 `docs/PR_STATUS.md`。

先不要派，条件到了再按原文发：

| 任务 | 什么时候派 |
| --- | --- |
| 序章第一关的背景图和画面 | 程序的 `prologue_01` 交出版本之后。派给美术策划 [bc-f9d00968-aefa-521c-b290-c66b48800915](https://cursor.com/agents/bc-f9d00968-aefa-521c-b290-c66b48800915)。完成度参考明日方舟，风格是东方。竖屏，不用官方素材。现在不要派 |
| 序章第一关的动效 | 和上面同一时刻。另开动效师来做，不只是审。进关、放置、按钮、受击、结算要有反馈。现在不要派。不要派给美术策划 |
| T-19b | #14 和 #12 都合并之后 |
| T-20 | #12 合并之后。字体用东方风格 |
| T-02 清掉车道占位 | #12 合并之后 |
| T-01 配置读取层 | A-01 完成之后 |

GitHub 整理员是 [bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344](https://cursor.com/agents/bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344)。原来靠 Grok Bot 的 GitHub 触发例程叫醒，该例程已暂停。状态页过期时，由执行制作人直接给它发消息。它只维护 `docs/PR_STATUS.md`，不合并。

策划和测试的常驻名单在第 0.1 节。#12 这一轮复审没有附到那些原 agent 上，实际审核链接见第 4 节。动效师需要时另开。用户还没回复的拍板见第 6 节。D-01 已定，不要再问。只有用户能合并。
