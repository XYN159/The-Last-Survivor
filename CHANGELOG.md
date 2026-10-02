# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 变更

- 灵梦默认符卡按 D-04 定为梦符「封魔阵」。梦想封印仍是第二张，优先级更低。
- 紫的弱化状态暂定名为「半褪」（文本 key `state.yukari_halffaded.name`），资源文件名改为 `yukari_halffaded`。从 `ch1_04` 持续到 `ch5_04`。名称待制作人最终确认，改名只影响文本，不影响资源。
- 对外名称从 The Last Survivor（最后的幸存者）改为《东方守幻录》。英文仓库名是 touhou-forgotten-defense。定位改为东方Project 同人、个人免费非商业的竖屏角色塔防，不是弹幕射击。调试 APK 文件名改为 `touhou-forgotten-defense-*`，Android 包名改为 `com.xyn159.touhouforgottendefense`。
- GitHub 首页的 `README.md` 整份改写成《东方守幻录》的介绍。

### 新增

- 加入 20 张 1920×1080 横屏界面原画，覆盖启动、登录、主界面、选关、编队、养成、商店和通用弹窗。
- 加入美术框架和 MVP 音频清单（`docs/design/art/`、`docs/design/audio/`）：Q 版手绘平涂画风、章节配色、敌我区分、已确认的 1080×1920 版面（每格 128、7×12、偏移 (92, 140)；长屏先扣刘海、其余高度给底栏）、Godot 导入设置、按战斗 ID 去掉 `enm_` 的命名、占位方案、多路线可读性（含延迟开启的路线）、不分稀有度的三选一卡面（新强化 / 再叠一层 / 叠到 2 层质变）、按「一章全部 3 星」组织的星星外观、MVP 资源清单（4 名角色、小残影 / 快残影 / 硬残影、首领冰之残影 `boss_cirno` 三阶段）和素材许可证登记表。只有文档，没有图片和代码改动。
- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/touhou-forgotten-defense/compare/main...HEAD
