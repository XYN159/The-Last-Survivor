# 东方守幻录

[![CI](https://github.com/XYN159/touhou-forgotten-defense/actions/workflows/ci.yml/badge.svg)](https://github.com/XYN159/touhou-forgotten-defense/actions/workflows/ci.yml)

英文仓库名是 **touhou-forgotten-defense**。

《东方守幻录》是一部 **东方Project 同人**作品：个人制作，免费，非商业。玩法是 **竖屏角色塔防**，局外和局内有轻度 roguelite 增益。它 **不是弹幕射击游戏**。

这是粉丝二次创作，不是上海爱丽丝幻乐团的官方作品。请遵守 ZUN 公布的[东方二次创作规约](https://touhou-project.news/guideline/)（[英文版](https://touhou-project.news/guidelines_en/)）：标明同人身份，不要让人误以为这是官方游戏，也不要使用官方游戏素材。手机同人游戏按规约以免费形式发布。本仓库不收费，也不做商业用途。细节以官方页面为准。

当前仍是占位原型。能打开的是标题画面，以及一条用来确认场景切换的旧占位场景。塔防原型正在开发。

当前引擎版本写在 [`godot-version.txt`](godot-version.txt)：**Godot 4.7.2**。请使用标准版（GDScript），不要用 .NET 版。

仓库地址是 <https://github.com/XYN159/touhou-forgotten-defense>。如果这个链接还打不开，先在 GitHub 网页上把仓库改成这个名字；改名之后，旧地址会跳转到新地址。

## 在 Windows 上打开并运行

完整的安装步骤在 [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)。最短路径：

1. 安装 Git（勾选 Git LFS）和 Godot 4.7.2。
2. 克隆这个仓库。
3. 用 Godot 打开 `project.godot`。
4. 按 `F5`。标题画面应显示 **东方守幻录**。点「开始」进入占位场景，再点「返回」。

想左边放 Cursor、右边放正在跑的游戏，并让 AI 的改动直接进到画面里，按 [`docs/DEV_LOOP.md`](docs/DEV_LOOP.md) 做。桌面窗口是 540×960，逻辑分辨率仍是 1080×1920。

## 从 CI 下载 APK

每次向 `main` 推送、以及每个拉取请求，GitHub Actions 都会检查代码、跑测试，并打出一个调试版 APK。

1. 打开 [Actions](https://github.com/XYN159/touhou-forgotten-defense/actions/workflows/ci.yml)。
2. 点开一次成功的 **CI** 运行。
3. 在页面底部的 **Artifacts** 里下载 `touhou-forgotten-defense-android-debug`。
4. 解压得到 `touhou-forgotten-defense-debug.apk`，传到手机上安装。

这个 APK 用的是调试证书，只能自己安装试用，不能上传到 Google Play。手机上安装调试包的步骤也写在 [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)。

打上形如 `v0.1.0` 的标签后，[Release 工作流](.github/workflows/release.yml) 会把同样的调试 APK 挂到对应的 GitHub Release 上。标签构建的文件名是 `touhou-forgotten-defense-v0.1.0-debug.apk` 这种形式。

## 文档索引

| 文档 | 内容 |
| --- | --- |
| [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md) | Windows 上安装 Git、Godot、Cursor，以及怎么跑起来 |
| [`docs/DEV_LOOP.md`](docs/DEV_LOOP.md) | 左边 Cursor、右边游戏：外部编辑器、运行时同步、真机部署、scrcpy、Agent |
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
