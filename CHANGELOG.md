# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 变更

- 所有 Boss（含终章）的 `leak_damage` 改为 2。章 Boss 旧的 10 和终章旧的 20 已被 Q4 取代。普通残影的漏怪扣命未改。
- 按 USER_DECISIONS（Q14）把伤害保底改为 0.05，旧的 20% 和「至少 1」标成已被 Q14 取代。局内升级、共用符卡、同名份数上限、波次窗口 10/20/4、危机充能和主线三选一标为废止，旧数字保留。`copy_cost_increase_ratio` 不改名，待 P6。`initial_cost`、`cost_regen_per_sec`、`max_cost` 留空，待 P7。章 Boss 3000 和终章 4000 仍是旧锁，待 P10。重甲残影 25 甲仍在 ch2_02，待 P11。`growth_tier` 待 P3。Boss 两阶段和冻结减半待 P4，未写入敌人表。
- ch1_04 的 `threat_budget_coef` 定为 0.71，并删掉旁路系数。Boss 第 11 波登场，`boss_rules.hp_uses_level_mult` 为 false。扑人残影威胁点 3，飞行残影威胁点 2。Boss 的 `leak_damage` 只留在 `bosses` 段。
- 叫波奖励一次最多 20。灵梦默认符卡写成梦符「封魔阵」。`stats.json` 补上嵌套的攻击字段和局内升级。
- 对外名称从 The Last Survivor（最后的幸存者）改为《东方守幻录》。英文仓库名是 touhou-forgotten-defense。定位改为东方Project 同人、个人免费非商业的竖屏角色塔防，不是弹幕射击。调试 APK 文件名改为 `touhou-forgotten-defense-*`，Android 包名改为 `com.xyn159.touhouforgottendefense`。
- GitHub 首页的 `README.md` 整份改写成《东方守幻录》的介绍。

### 新增

- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/touhou-forgotten-defense/compare/main...HEAD
