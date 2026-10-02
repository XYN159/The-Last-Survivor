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
- 2026-10-02 起，聊天侧的六位策划（系统、数值、文案、关卡、战斗、美术）和游戏测试也停手。他们在 #2、#3、#4、#5、#6、#8、#9 上还没做完的修改，以及之后 PR 的策划审核和测试验收，都由这个执行制作人按 `ROLES.md` 里对应角色的身份接着做。GitHub 上这七个 PR 没有角色审核线程，只有整理员关于合入 main 和 CI 的一条说明；继续的依据是各分支上的提交和 `PLAN.md` 第 3.1 节。仍然不合并。还没定的事继续问用户。

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

## 4. PR #12（T-00 原型）要返工

- PR：https://github.com/XYN159/Touhou-forgotten-defense/pull/12
- 分支：`cursor/battle-core-prototype-d174`
- head：`452f1b3`（草稿）
- agent：https://cursor.com/agents/bc-062dec78-83a7-5a85-9366-e6690ee5d174
- 正式审核已经补上：[战斗策划](https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5946132717)、[执行制作人汇总](https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5946132812)。评论 `5945898325` 是更早的一份战斗验收，和后来的更正有冲突，不以它为返工清单。

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

改完把草稿 PR 转为 ready for review，再请各角色复审。

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
- **#12 的审核**：战斗策划和执行制作人汇总已经留在 PR 上，结论是需要返工。

正在做：

- **#12 返工**：应发回原原型 agent [bc-062dec78-83a7-5a85-9366-e6690ee5d174](https://cursor.com/agents/bc-062dec78-83a7-5a85-9366-e6690ee5d174)。2026-10-02 直接派工时，工具新开了 [bc-d0f2930b-36eb-543e-b3a6-be672f2e2b60](https://cursor.com/agents/bc-d0f2930b-36eb-543e-b3a6-be672f2e2b60)。提示词要求它改原来的 PR #12，不要新开 PR，也不要由制作人改 `scripts/`。
- **状态页**：整理员 [bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344](https://cursor.com/agents/bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344) 没有被原会话叫醒。刷新发给了 [bc-f9b5cac4-b05b-5ecd-a1e0-1dce1ea95eee](https://cursor.com/agents/bc-f9b5cac4-b05b-5ecd-a1e0-1dce1ea95eee)，只许改 `docs/PR_STATUS.md`。

先不要派，条件到了再按原文发：

| 任务 | 什么时候派 |
| --- | --- |
| T-19b | #14 和 #12 都合并之后 |
| T-20 | #12 合并之后。字体用东方风格 |
| T-02 清掉车道占位 | #12 合并之后 |
| T-01 配置读取层 | A-01 完成之后 |

GitHub 整理员是 [bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344](https://cursor.com/agents/bc-18aea9d7-7507-56b7-93d4-c0f73fb6d344)。原来靠 Grok Bot 的 GitHub 触发例程叫醒，该例程已暂停。状态页过期时，由执行制作人直接给它发消息。它只维护 `docs/PR_STATUS.md`，不合并。

用户还没回复的拍板见第 6 节。D-01 已定，不要再问。只有用户能合并。
