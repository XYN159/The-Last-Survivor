# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 变更

- 执行制作人接手六位策划和游戏测试在 #2 #3 #4 #5 #6 #8 #9 上未完成的修改。ch1_04 系数定为 0.74，入场波定为 11。细节在 `docs/production/HANDOFF.md`。
- 六位策划和游戏测试已有 Cursor agent，名单在 `HANDOFF.md` 第 0.1 节。之后由执行制作人分派。动效师还没有常驻 agent。
- T-00 返工已推到 PR #12 的 `b5b3bed`。复审汇总是需要返工：标题必须出现「东方 Project 二次创作」。
- 增加常驻程序 agent，第一张卡是把序章第一关接到塔防原型上。名单在 `HANDOFF.md` 第 0.2 节。程序岗位按小团队兼岗，不拆成主程、服务器、引擎等一排 agent。
- 对外名称从 The Last Survivor（最后的幸存者）改为《东方守幻录》。英文仓库名是 touhou-forgotten-defense。定位改为东方Project 同人、个人免费非商业的竖屏角色塔防，不是弹幕射击。调试 APK 文件名改为 `touhou-forgotten-defense-*`，Android 包名改为 `com.xyn159.touhouforgottendefense`。
- GitHub 首页的 `README.md` 整份改写成《东方守幻录》的介绍。

### 新增

- 执行制作人交接写在 `docs/production/HANDOFF.md`。Grok Bot 暂停后，派工由执行制作人直接发给原来的 Cursor agent。T-19b 等 #14 和 #12 都合并；T-20 和 T-02 等 #12 合并；T-01 等 A-01。
- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/touhou-forgotten-defense/compare/main...HEAD
