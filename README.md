# The Last Survivor（最后的幸存者）

[![CI](https://github.com/XYN159/The-Last-Survivor/actions/workflows/ci.yml/badge.svg)](https://github.com/XYN159/The-Last-Survivor/actions/workflows/ci.yml)

竖屏安卓生存策略游戏的工程仓库。玩法方向是：在车道里前进、捡到增益、让小队变大，再回到基地升级建筑，然后打更难的关。目前仓库里还没有正式玩法，只有能打开的标题画面和一条占位战斗车道，用来确认 Godot 工程和自动打包是通的。

当前引擎版本写在 [`godot-version.txt`](godot-version.txt)：**Godot 4.7.2**。请使用标准版（GDScript），不要用 .NET 版。

## 在 Windows 上打开并运行

完整的安装步骤在 [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)。最短路径：

1. 安装 Git（勾选 Git LFS）和 Godot 4.7.2。
2. 克隆这个仓库。
3. 用 Godot 打开 `project.godot`。
4. 按 `F5`。标题画面出现后，点「开始」进入占位战斗车道，再点「返回」。

## 从 CI 下载 APK

每次向 `main` 推送、以及每个拉取请求，GitHub Actions 都会检查代码、跑测试，并打出一个调试版 APK。

1. 打开 [Actions](https://github.com/XYN159/The-Last-Survivor/actions/workflows/ci.yml)。
2. 点开一次成功的 **CI** 运行。
3. 在页面底部的 **Artifacts** 里下载 `the-last-survivor-android-debug`。
4. 解压得到 `the-last-survivor-debug.apk`，传到手机上安装。

这个 APK 用的是调试证书，只能自己安装试用，不能上传到 Google Play。手机上安装调试包的步骤也写在 [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)。

打上形如 `v0.1.0` 的标签后，[Release 工作流](.github/workflows/release.yml) 会把同样的调试 APK 挂到对应的 GitHub Release 上。

## 文档索引

| 文档 | 内容 |
| --- | --- |
| [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md) | Windows 上安装 Git、Godot、Cursor，以及怎么跑起来 |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | 分支、提交、审查、合并、发版 |
| [`docs/GDD.md`](docs/GDD.md) | 玩法草案，以及需要你亲自补上的部分 |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | 目录、场景、数值、存档，以及以后服务器怎么接 |
| [`docs/CODING_STYLE.md`](docs/CODING_STYLE.md) | GDScript 写法 |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | 从脚手架到单机 MVP，以及更后面的多人 |
| [`docs/BRANCH_PROTECTION.md`](docs/BRANCH_PROTECTION.md) | 你需要在 GitHub 网页上亲手打开的分支保护 |
| [`docs/adr/`](docs/adr/) | 已经定下来的技术决定 |
| [`CHANGELOG.md`](CHANGELOG.md) | 更新日志 |
| [`AGENTS.md`](AGENTS.md) | 以后帮你写代码的 AI 要遵守的规则 |

## 第三方组件

- [GUT](https://github.com/bitwes/Gut) 9.7.1，单元测试插件，MIT 许可证，见 `addons/gut/LICENSE.md`。不要手改这个目录。
- [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC)，界面中文字体。许可证全文在 `assets/fonts/OFL.txt`（英文原文，按许可证要求原样保留）。仓库里放的是只含常用汉字区的子集，方便打包。

游戏本身的许可证还没定。在你选定之前，不要把仓库改成「默认允许别人随便拿去商用」。
