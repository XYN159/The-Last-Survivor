# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 变更

- 标题画面的「开始」改进序章第一关「神社的直路」（`prologue_01`）。地图、路线、三波小残影都读 `data/levels/prologue_01.json`（原样复制自关卡 PR #5）。这一关只能放灵梦，魔理沙要通关后才加入。布阵倒计时等玩家放下第一个角色才开始走；「开始」按钮只在布阵时出现，不做叫波。打完最后一波还有生命就赢，生命归零就输，结算可以再打一次或返回标题。
- 标题画面的副标题改为「东方 Project 二次创作」，仍走文本 key `ui.menu.subtitle`。
- 塔防原型的放置改成先点亮色格子、再点头像。出怪窗口按每一波的 `duration_sec` 从这一波开始算 20 秒，窗口结束后固定空 4 秒，清场不再缩短空档。第 1 波 `delay_sec` 为 0，代码按数据读取，不再单独豁免第一波。同一角色第 k 个的费用改为部署费 × (1 + 0.5 × (k − 1))。敌人血量乘难度表里的 `hp_multiplier`（按浮点读）。玩家能看见的文字改走 `locale/game_zh.csv`。
- 对外名称从 The Last Survivor（最后的幸存者）改为《东方守幻录》。英文仓库名是 touhou-forgotten-defense。定位改为东方Project 同人、个人免费非商业的竖屏角色塔防，不是弹幕射击。调试 APK 文件名改为 `touhou-forgotten-defense-*`，Android 包名改为 `com.xyn159.touhouforgottendefense`。
- GitHub 首页的 `README.md` 整份改写成《东方守幻录》的介绍。

### 新增

- 可玩的塔防核心原型。标题画面的「开始」进入 7×12 棋盘：能放灵梦和魔理沙，小残影和快残影沿固定路线走向守护点，漏怪扣生命，打完或生命归零后可以重打或返回标题。数值和这一关都在 `data/prototype/`。
- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/touhou-forgotten-defense/compare/main...HEAD
