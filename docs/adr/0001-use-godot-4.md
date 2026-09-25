# ADR-0001：使用 Godot 4.7.2

- 状态：已接受
- 日期：2026-09-25

## 背景

游戏要跑在安卓手机上，竖屏，先做单机。仓库所有者用 Windows 上的 Godot 编辑器和 Cursor 看 AI 改动，不靠手写大型工程来推进。工具需要能免费使用、场景文件能直接打开、并且能在 GitHub Actions 里打出 APK。

## 决定

- 引擎使用 Godot **4.7.2** 标准版，脚本语言是 GDScript。版本以仓库根目录的 `godot-version.txt` 为唯一来源，CI 和文档都读它。
- 新工程使用 Mobile 渲染器。
- 基准分辨率 1080×1920，拉伸模式 `canvas_items`，宽高比 `expand`，方向为纵向。
- 不使用 Godot .NET / C# 版本。
- 升级到别的 4.x 稳定版时，要新写一篇 ADR，并同时改 `godot-version.txt`、CI 和 `docs/SETUP_WINDOWS.md`。

## 后果

- 场景和脚本都是文本，PR 里能看出改了哪一块界面。
- 导出模板必须和 4.7.2 严格匹配，否则 Android 打包会失败。
- Mobile 渲染器是手机上的目标效果；桌面预览也用它，避免两套画面。
- 编辑器和 CI 都要跟着官方稳定版走，不使用开发版或 RC。
