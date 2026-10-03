# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 变更

- 首页介绍的启动图去掉左右两块黑色空白，空出来的位置补上神社夜景。标题、灵梦和「点击开始」没有改。
- 服务器选择图里，红魔馆、白玉楼、月之廊各只写一遍。
- 仓库首页的介绍加上二十张界面原画。登录和选服务器只是画面，不建账号，也不连网。
- 对外名称从 The Last Survivor（最后的幸存者）改为《东方守幻录》。英文仓库名是 touhou-forgotten-defense。定位改为东方Project 同人、个人免费非商业的竖屏角色塔防，不是弹幕射击。调试 APK 文件名改为 `touhou-forgotten-defense-*`，Android 包名改为 `com.xyn159.touhouforgottendefense`。
- GitHub 首页的 `README.md` 整份改写成《东方守幻录》的介绍。

### 新增

- 加入《东方守幻录》塔防的关卡框架：24 关的顺序，以及序章 3 关、第一章 4 关的完整地图和波次。说明在 `docs/design/level/`，地图在 `data/levels/`。
- 难度数字以 PR #8 的 `data/balance/level_difficulty.json` 为准。本 PR 不附带这份文件，要在 #8 之后合并。字段是 `threat_budget_coef`、`wave_threat_budgets`、`threat_budget_total`、`target_lives_first_clear`。不再使用旧的首通字段名。
- 按游戏测试的设计问题改了关卡：DI-02 硬残影进 MVP，只在第一章第 3 关出现，共 8 只。DI-03、DI-04 第 1 波不再另加 4 秒，刷怪窗口 20 秒后空 4 秒，序章要等放下第一个角色才倒数。DI-08 星级改成看 `stars.thresholds_lives_left`，按顺序对应 3 星、2 星、1 星，首通目标不参与星级。DI-14 第一章第 3 关第 6 波有一段只演一次的隙间换位。DI-17 每一关只有一个主教学点，其余内容放进 `previews`。
- 制作人已定：非序章关卡每关 1 到 3 次三选一，最后一波不弹。10 波 1 次，15 波 2 次，20 波 3 次。少于 5 波没有。波数不改。开局灵力 150，每活过一波加 20。
- 冰之残影按 D-01 在第 11 波入场，血量不乘关卡系数。#8 已把系数锁定为 0.74。出怪数量还没按这一版的 `wave_threat_budgets` 重排。扣命指向 `bosses.boss_cirno.leak_damage`。冻角色用 `st_unit_frozen`。刷怪窗口内叫波，本波没出的怪照原节奏继续出，和下一波重叠。飞行残影按战斗规则仍能被地面攻击打到。扑人残影威胁点 3、飞行残影威胁点 2 是临时值。
- 关卡 id、地图字符和琪露诺的三组格子改成战斗策划的读图约定。难度种子改成 CSV。生命和移速不再写进关卡图鉴。
- 角色只能放在预定槽位上。`.` 就是槽位，并和 `slots` 一一对应。
- 路线开战前固定。第一章第 2 关起可以有两个入口。第五章改为按波次开关入口，不再在战斗中改路。
- 序章前两关改成 3 波和 4 波，没有三选一。序章第 3 关 10 波，用来教三选一。其余关卡 10 到 20 波。
- MVP 的敌人是小残影、快残影、冰之残影，外加只在第一章第 3 关出现的硬残影，共 8 只。琪露诺通关第一章第 1 关后加入。八云紫通关第一章首领后加入。
- 敌人显示名对齐文案术语表。文本 key 一律是 `enemy.<战斗ID>.name`。已定名是小残影、快残影、硬残影、飞行残影、冰之残影。暂名、状态 `pending_文案策划`：扑人残影、遗忘之影、堆积体、结界之渣，以及首领「红魔的女仆残影」「不死鸟的残影」「风祝的残影」「守门残影」「落野忘」。第五章第 2 关改称「迟来的岔路」，不再叫「会移动的路」。
- 制作人定了加入节奏和波次时长：每章第 1 关通关后新角色加入，第 2 关才教她；本章第二人在首领关之后加入。每一波刷怪约 20 秒，波间 4 秒。首领关最后一波等首领被击败。属性指向 `data/balance/combat/stats.json`，不在关卡里抄数字。第二章起的人选是提案，待文案。第一章第 1 关的快残影从第 6 波起，大约占三成。
- 星级按剩余生命的绝对值，阈值以 `data/balance/combat/stats.json` 的 `stars.thresholds_lives_left` 为准，这里不抄数字。首通目标不参与星级。已通关的关可以重打并补星。局外奖励以 PR #8 的难度表为准。图鉴和星级文件只留引用，不带数值。校验在难度表或属性表不存在时只警告并跳过。
- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/touhou-forgotten-defense/compare/main...HEAD
