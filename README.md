# 东方守幻录

[![CI](https://github.com/XYN159/touhou-forgotten-defense/actions/workflows/ci.yml/badge.svg)](https://github.com/XYN159/touhou-forgotten-defense/actions/workflows/ci.yml)

英文仓库名：**touhou-forgotten-defense**

《东方守幻录》是个人制作的 **东方Project 同人**游戏，免费、非商业，发布在 GitHub。玩法是 **竖屏角色塔防**，局外和局内有轻度 roguelite 增益。它 **不是弹幕射击**。

这是粉丝作品，不是上海爱丽丝幻乐团的官方游戏。创作和发布遵守 ZUN 的[东方二次创作规约](https://touhou-project.news/guideline/)（[英文](https://touhou-project.news/guidelines_en/)）：写明同人身份，不冒充官方，不使用官方游戏素材。手机同人游戏按规约免费发布。本仓库不收费，也不做商业用途。以官方页面为准。

现在能玩的还是占位原型：标题画面，加上一个用来确认场景能切换的旧画面。塔防原型正在做。

引擎是 **Godot 4.7.2** 标准版（GDScript），版本写在 [`godot-version.txt`](godot-version.txt)。不要用带 .NET 的编辑器。

仓库地址：<https://github.com/XYN159/touhou-forgotten-defense>

## 在电脑上跑起来

完整步骤在 [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)。最短的做法：

1. 安装带 Git LFS 的 Git，以及 Godot 4.7.2。
2. 克隆本仓库。已经克隆过旧地址时，不必重下，在仓库目录执行 `git remote set-url origin https://github.com/XYN159/touhou-forgotten-defense.git`。
3. 用 Godot 打开 `project.godot`，按 `F5`。
4. 标题应是 **东方守幻录**。点「开始」进入占位画面，再点「返回」。

左边放 Cursor、右边放正在跑的游戏，按 [`docs/DEV_LOOP.md`](docs/DEV_LOOP.md)。桌面窗口是 540×960，游戏逻辑分辨率仍是 1080×1920。

## 下载调试 APK

每次拉取请求，以及推送到 `main`，GitHub Actions 都会检查代码、跑测试，并打出调试 APK。

1. 打开 [Actions 里的 CI](https://github.com/XYN159/touhou-forgotten-defense/actions/workflows/ci.yml)。
2. 点开一次成功的运行。
3. 在页面底部的 **Artifacts** 下载 `touhou-forgotten-defense-android-debug`。
4. 解压得到 `touhou-forgotten-defense-debug.apk`，拷到手机安装。

这个包用调试证书签名，只能自己试用，不能上架 Google Play。手机安装步骤也在 [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)。

打上 `v0.1.0` 这种标签后，[Release 工作流](.github/workflows/release.yml) 会把调试 APK 挂到对应的 GitHub Release，文件名类似 `touhou-forgotten-defense-v0.1.0-debug.apk`。

## 文档

| 文档 | 内容 |
| --- | --- |
| [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md) | 在 Windows 上安装 Git、Godot、Cursor，并把游戏跑起来 |
| [`docs/DEV_LOOP.md`](docs/DEV_LOOP.md) | 左边 Cursor、右边游戏：外部编辑器、运行时同步、真机、scrcpy |
| [`CONTRIBUTING.md`](CONTRIBUTING.md) | 分支、提交、审查、合并、发版 |
| [`docs/GDD.md`](docs/GDD.md) | 玩法草案。标成「待你补充」的部分要你来定 |
| [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) | 目录、场景、数值、存档 |
| [`docs/CODING_STYLE.md`](docs/CODING_STYLE.md) | GDScript 写法 |
| [`docs/ROADMAP.md`](docs/ROADMAP.md) | 从现在的工程到单机版本，以及更后面的安排 |
| [`docs/BRANCH_PROTECTION.md`](docs/BRANCH_PROTECTION.md) | 在 GitHub 网页上打开 `main` 的分支保护 |
| [`docs/adr/`](docs/adr/) | 已经定下来的技术决定 |
| [`CHANGELOG.md`](CHANGELOG.md) | 更新日志 |
| [`AGENTS.md`](AGENTS.md) | 帮你改代码的 AI 要遵守的规则 |

## 第三方组件

- [GUT](https://github.com/bitwes/Gut) 9.7.1：单元测试插件，MIT 许可证，见 `addons/gut/LICENSE.md`。不要手改这个目录。
- [Noto Sans SC](https://fonts.google.com/noto/specimen/Noto+Sans+SC)：界面中文字体。许可证原文在 `assets/fonts/OFL.txt`（英文，按许可证要求原样保留）。仓库里是常用汉字区的子集，方便打包。
- [霞鹜文楷 LXGW WenKai](https://github.com/lxgw/LxgwWenKai) v1.521：标题画面、战斗状态条和单位面板的字体。许可证原文在 `assets/fonts/LXGWWenKai-OFL.txt`（SIL OFL 1.1，按许可证要求原样保留）。

游戏本身的许可证还没定。在你选定之前，不要把仓库改成「默认允许别人随便拿去商用」。
