# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 新增

- 加入东方同人塔防的战斗规则草案（`docs/design/combat/`）和配置表（`data/balance/combat/`）。数值仍是占位，游戏尚未读取。

### 变更

- 战斗草案记下制作人 2026-09-27 拍板的 5 条（符卡使方案 A+、同名角色最多 3 个、MVP 冻结来源、紫的隙间探头、Boss 折返）。伤害保底改为 `stats.json` 顶层的 `armor_floor_ratio` 和 `min_damage`。
- 敌人的血量、移速、护甲、掉落、漏怪、威胁和击杀充能改记在 `stats.json` 的 `enemies` 里（含预留残影和琪露诺）。`enemies.json`、`bosses.json` 只留行为。快残影血量 35、移速 2.0 已确认。换符卡使清能量已由数值策划确认为 true。
- 战斗草案对齐制作人和系统策划的新决定：强化 2 层质变、每 5 波三选一且只管当局、每波约 20 秒、MVP 敌人只有普通残影和快残影、失败可从当前波的快照重来、符卡自动释放是全局开关、角色只能放在地图上的 `P` 格。
- 更正角色解锁：紫在第一章隙间探头后，于第一章 Boss 关打完加入，MVP 里重打已通关卡使用。琪露诺可放置时机改为待定。序章前两关没有三选一，第 3 关开始教。
- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/The-Last-Survivor/compare/main...HEAD
