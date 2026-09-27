# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 变更

- 玩法方向改为东方 Project 同人竖屏塔防，暂定名《东方守幻录》。重写了 `docs/GDD.md` 和 `docs/ROADMAP.md`。旧的末日车道、加人、基地建筑和 SLG 设定作废。仓库名 The Last Survivor 暂时不改。场景和 `data/` 这次没动。

### 新增

- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。（这条车道只是当时的占位，玩法方向现已作废，见路线图。）
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/The-Last-Survivor/compare/main...HEAD
