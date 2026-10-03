# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 变更

- DI-06 改为已定：ch1_04 第 11 波入场，Boss 血量不乘倍率，系数 0.74。漏怪扣命仍见 DI-07。
- 测试文档记下 2026-10-02 的用户拍板：冰之残影第三阶段用雪符「钻石风暴」，被冻住可以连点破冰；结算画面交给美术（东方风梦幻的 MVP 图，字体要有游戏感和赛博朋克感）；界面和测试先用文本 key `currency.meta`。
- 对外名称从 The Last Survivor（最后的幸存者）改为《东方守幻录》。英文仓库名是 touhou-forgotten-defense。定位改为东方Project 同人、个人免费非商业的竖屏角色塔防，不是弹幕射击。调试 APK 文件名改为 `touhou-forgotten-defense-*`，Android 包名改为 `com.xyn159.touhouforgottendefense`。
- GitHub 首页的 `README.md` 整份改写成《东方守幻录》的介绍。

### 新增

- 为原型实验 E1、E2、E7 各加一张记录表（`docs/design/qa/prototype_experiments_e1_e2_e7.md`）。结论都写「未测」。玩家能玩的 PR #30 还没有朝向、每人技力和结界外不攻击，这三张表还不能实测。
- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/touhou-forgotten-defense/compare/main...HEAD
