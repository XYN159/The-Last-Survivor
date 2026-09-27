# 东方守幻录

GitHub 仓库名仍是 **The Last Survivor**。那是以前的名字，暂时不改。游戏暂定名是《东方守幻录》。

[![CI](https://github.com/XYN159/The-Last-Survivor/actions/workflows/ci.yml/badge.svg)](https://github.com/XYN159/The-Last-Survivor/actions/workflows/ci.yml)

东方 Project 的同人游戏，个人制作，免费，放在 GitHub 上，不商业化。原作权利归上海爱丽丝幻乐团 / ZUN。本作与官方无关。二次创作遵守 [ZUN 的二次创作指南](https://touhou-project.news/guideline/)（2024 年 5 月 31 日更新）。

玩法是单机竖屏角色塔防：把角色放到路上守住目标，每打完 5 波从三个强化里选一个。设计总纲在 [`docs/GDD.md`](docs/GDD.md)。以前的末日车道、加人、基地建筑和 SLG 已经作废。

现在打开工程，看到的还是旧标题和一条占位车道，用来确认 Godot 和自动打包是通的。那条车道的玩法不要再做，以后换成塔防原型。这次只改了文档，场景还没换。

当前引擎版本写在 [`godot-version.txt`](godot-version.txt)：**Godot 4.7.2**。请使用标准版（GDScript），不要用 .NET 版。

## 在 Windows 上打开并运行

完整的安装步骤在 [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)。最短路径：

1. 安装 Git（勾选 Git LFS）和 Godot 4.7.2。
2. 克隆这个仓库。
3. 用 Godot 打开 `project.godot`。
4. 按 `F5`。标题画面出现后，点「开始」会进入一条占位车道（旧画面，玩法已作废），再点「返回」。

想左边放 Cursor、右边放正在跑的游戏，并让 AI 的改动直接进到画面里，按 [`docs/DEV_LOOP.md`](docs/DEV_LOOP.md) 做。桌面窗口是 540×960，逻辑分辨率仍是 1080×1920。

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
| [`docs/DEV_LOOP.md`](docs/DEV_LOOP.md) | 左边 Cursor、右边游戏：外部编辑器、运行时同步、真机部署、scrcpy、Agent |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | 分支、提交、审查、合并、发版 |
| [`docs/GDD.md`](docs/GDD.md) | 玩法总纲，以及需要你亲自拍板的部分 |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | 目录、场景、数值、存档。旧的车道字段和服务器计划已作废 |
| [`docs/CODING_STYLE.md`](docs/CODING_STYLE.md) | GDScript 写法 |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | 从塔防原型到 7 关 MVP，再到完整 24 关 |
| [`docs/BRANCH_PROTECTION.md`](docs/BRANCH_PROTECTION.md) | 你需要在 GitHub 网页上亲手打开的分支保护 |
| [`docs/adr/`](docs/adr/) | 已经定下来的技术决定 |
| [`CHANGELOG.md`](CHANGELOG.md) | 更新日志 |
| [`AGENTS.md`](AGENTS.md) | 以后帮你写代码的 AI 要遵守的规则 |

## 第三方组件

- [GUT](https://github.com/bitwes/Gut) 9.7.1，单元测试插件，MIT 许可证，见 `addons/gut/LICENSE.md`。不要手改这个目录。
- [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC)，界面中文字体。许可证全文在 `assets/fonts/OFL.txt`（英文原文，按许可证要求原样保留）。仓库里放的是只含常用汉字区的子集，方便打包。

游戏按制作人的决定免费发布、不商业化。仓库代码用哪一种开源许可证还没定。在你选定之前，不要把仓库改成「默认允许别人拿去商用」。同人作品还要同时遵守文首写的二次创作指南。
