# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 新增

- 加入《东方守幻录》塔防的关卡框架：24 关的顺序，以及序章 3 关、第一章 4 关的完整地图和波次。说明在 `docs/design/level/`，地图在 `data/levels/`。
- 难度改由数值策划的 `data/balance/level_tables/level_difficulty.csv` 负责。序章波次是 8、9、10，第一章是 10、11、12，首领 15。每 5 波一次三选一。
- 普通残影、快残影、硬残影和第一章首领的威胁点用来对预算。波次预算是 `(10 + 4 × 波次) × 系数`，系数种子全部是 1.0。开局灵力 150，每活过一波加 20。
- 关卡 id、地图字符和琪露诺的三组格子改成战斗策划的读图约定。难度种子改成 CSV。生命和移速不再写进关卡图鉴。
- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/The-Last-Survivor/compare/main...HEAD
