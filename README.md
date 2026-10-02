# 东方守幻录

[![CI](https://github.com/XYN159/touhou-forgotten-defense/actions/workflows/ci.yml/badge.svg)](https://github.com/XYN159/touhou-forgotten-defense/actions/workflows/ci.yml)

英文仓库名：**touhou-forgotten-defense**

《东方守幻录》是个人制作的 **东方Project 同人**游戏，免费、非商业，发布在 GitHub。玩法是 **横屏角色塔防**：把角色放在路上，拦住走过来的敌人。它 **不是弹幕射击**。

这是粉丝作品，不是上海爱丽丝幻乐团的官方游戏。创作和发布遵守 ZUN 的[东方二次创作规约](https://touhou-project.news/guideline/)（[英文](https://touhou-project.news/guidelines_en/)）：写明同人身份，不冒充官方，不使用官方游戏素材。手机同人游戏按规约免费发布。本仓库不收费，也不做商业用途。以官方页面为准。

下面二十张图是已经定下要进游戏的界面，都是 1920×1080。从主界面出发，选章节、看地图、编队，然后出战，打完看结算。剧情用立绘和对话框讲。角色养成、招募、商店、任务和邮件先把样子定下来，功能往后接。肉鸽模式以后再加，不在这二十张里。

引擎是 **Godot 4.7.2** 标准版（GDScript），版本写在 [`godot-version.txt`](godot-version.txt)。不要用带 .NET 的编辑器。

仓库地址：<https://github.com/XYN159/touhou-forgotten-defense>

## 游戏介绍

### 进门

启动页是神社和鸟居前的博丽灵梦。点一下进入登录。登录和选服务器只是进门的画面，游戏不建账号，也不连网。公告用来放活动和维护说明。

![启动页](docs/design/art/ui_originals/01_splash.png)

![登录](docs/design/art/ui_originals/02_login.png)

![服务器选择](docs/design/art/ui_originals/03_server.png)

![公告](docs/design/art/ui_originals/04_notice.png)

### 主界面

主界面是整部游戏的中枢。左边是看板角色，右边是「出击」，底下是编队、角色、任务、商店和邮件。

![主界面](docs/design/art/ui_originals/05_home.png)

### 出战

选章节时可以看主线、活动和资源本。进了章节，关卡连成一条路。点一关能看到敌人、掉落和推荐等级。编队画面确认这次带谁，再开始作战。打完给出星级、掉落和经验。故事用立绘加对话框讲。

![章节选择](docs/design/art/ui_originals/06_chapter.png)

![关卡地图](docs/design/art/ui_originals/07_stage_map.png)

![关卡详情](docs/design/art/ui_originals/08_stage_detail.png)

![编队](docs/design/art/ui_originals/09_squad.png)

![结算](docs/design/art/ui_originals/10_result.png)

![剧情对话](docs/design/art/ui_originals/11_dialogue.png)

### 角色

角色列表可以筛选和排序。点进一个人，能看属性、技能和攻击范围，再升级、升阶、升技能。装备、档案、语音和皮肤放在同一页的不同页签里。

![角色列表](docs/design/art/ui_originals/12_roster.png)

![角色详情](docs/design/art/ui_originals/13_character.png)

![升级与精英化](docs/design/art/ui_originals/14_upgrade.png)

![装备与档案](docs/design/art/ui_originals/15_gear.png)

### 招募、商店和日常

招募界面是「幻想的邂逅」。商店用不同的货币。任务里有日常、周常、成就和签到。邮件收通知。体力不够时弹出确认框。

![抽卡](docs/design/art/ui_originals/16_gacha.png)

![商店](docs/design/art/ui_originals/17_shop.png)

![任务](docs/design/art/ui_originals/18_missions.png)

![邮件](docs/design/art/ui_originals/19_mail.png)

![体力不足](docs/design/art/ui_originals/20_popup_stamina.png)

## 在电脑上跑起来

完整步骤在 [`docs/SETUP_WINDOWS.md`](docs/SETUP_WINDOWS.md)。最短的做法：

1. 安装带 Git LFS 的 Git，以及 Godot 4.7.2。
2. 克隆本仓库。已经克隆过旧地址时，不必重下，在仓库目录执行 `git remote set-url origin https://github.com/XYN159/touhou-forgotten-defense.git`。
3. 用 Godot 打开 `project.godot`，按 `F5`。
4. 标题应是 **东方守幻录**。序章第一关从标题的「开始」进入。上面二十张界面会按主界面 → 选关 → 编队 → 战斗 → 结算接到游戏里。

左边放 Cursor、右边放正在跑的游戏，按 [`docs/DEV_LOOP.md`](docs/DEV_LOOP.md)。这二十张界面是横屏 1920×1080。你手头这个分支如果还是旧的竖屏窗口，以 `project.godot` 里的分辨率为准。

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

游戏本身的许可证还没定。在你选定之前，不要把仓库改成「默认允许别人随便拿去商用」。
