# 素材来源和许可证登记

> 本作是 東方Project（东方 Project）的二次创作同人游戏。东方 Project 的原作权利归 上海アリス幻樂団（上海爱丽丝幻乐团）/ ZUN 所有。本作为个人制作的免费作品，与官方无关，不以营利为目的。本作不使用任何官方素材（立绘、音乐、截图、游戏内素材等），也不使用明日方舟的官方图、截图和素材。
> 依据：ZUN《東方Projectの二次創作ガイドライン》（2024-05-31 更新，<https://touhou-project.news/guideline/>）。

这一份先登记序章第一关画面用到的图。字体那一行和 PR #6 的登记一致，避免这支分支上漏掉正在使用的字体。

## 登记表

| 资源 | 文件路径 | 作者 / 来源 | 来源链接 | 许可证 | 许可证文件 / 存档 | 是否修改 | AI 生成 | 状态 | 登记日期 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Noto Sans SC Regular（子集） | `assets/fonts/NotoSansSC-Regular.ttf` | Adobe（Copyright 2014-2021 Adobe, with Reserved Font Name 'Source'），Google Fonts 发布 | <https://fonts.google.com/noto/specimen/Noto+Sans+SC> | SIL Open Font License 1.1 | `assets/fonts/OFL.txt` | 是：仓库里已有的子集 | 否 | 使用中 | 2026-09-27 | 界面中文。本轮没有换字体 |
| 标题神社背景 | `assets/textures/ui/bg_title_shrine.jpg` | Cursor cloud agent 内置生图。调用时没有返回底层模型名，这里不猜 | — | 本仓库原创，随免费同人作品使用 | — | 是：从 720×1280 放大到 1080×1920 | 是 | 使用中 | 2026-10-02 | 标题画面。没有喂官方图或同人图 |
| 序章庭院背景 | `assets/textures/tiles/shrine/bg_prologue_01.jpg` | 同上 | — | 本仓库原创，随免费同人作品使用 | — | 是：从 720×1280 放大到 1080×1920 | 是 | 使用中 | 2026-10-02 | `prologue_01` 战斗背景 |
| 灵梦侧栏头像 | `assets/textures/ui/reimu_v2_card.png` | 裁自 PR #14 已选定的 `reimu_v2.png`（`01fe51c`）。原图由 Cursor cloud agent 内置生图，没有返回模型名 | PR #14 | 本仓库原创，随免费同人作品使用 | `docs/design/art/concepts/SOURCES.md`（在 `art/t19a-character-concepts`） | 是：去掉右下角 128 预览格，裁成上半身 | 是 | 使用中（临时） | 2026-10-02 | 不是 T-19b 的正式立绘。正式立绘仍等 T-19b |
| 灵梦棋盘标记 | `assets/textures/ui/reimu_v2_token.png` | 同上 | PR #14 | 本仓库原创，随免费同人作品使用 | 同上 | 是：去掉预览格后缩成全身 | 是 | 使用中（临时） | 2026-10-02 | 静止的一张。没有待机和攻击两种姿态 |
| 灵力图标 | `assets/textures/ui/ui_icon_spirit.png` | Cursor cloud agent 用 Pillow 绘制 | — | 本仓库原创 | — | 否 | 否 | 使用中 | 2026-10-02 | 顶栏 |
| 生命图标 | `assets/textures/ui/ui_icon_life.png` | Cursor cloud agent 用 Pillow 绘制 | — | 本仓库原创 | — | 否 | 否 | 使用中 | 2026-10-02 | 小赛钱箱，顶栏 |

## 音频

这一轮没有加音乐和音效。
