# 架构

这份文档说明代码放在哪里、数据怎么流。玩法意图在 `docs/GDD.md`，写法约定在 `docs/CODING_STYLE.md`。

## 目录

```
addons/gut/          GUT 测试插件（第三方，不要手改）
assets/audio/        音效和音乐
assets/fonts/        界面字体。Noto Sans SC 子集，许可证见 OFL.txt
assets/models/       三维模型（glb 等）
assets/textures/     图片
data/balance/        数值 JSON。调平衡改这里
scenes/main/         标题等流程场景
scenes/battle/       战斗车道场景
scenes/ui/           以后可复用的界面碎片（目前还没有）
scripts/autoload/    自动加载的全局节点
scripts/balance/     数值配置的读取和计算
scripts/battle/      战斗场景脚本
scripts/main/        标题场景脚本
scripts/save/        存档读写
tests/unit/          GUT 测试，文件名以 test_ 开头
ci/                  给 GitHub Actions 用的脚本
docs/                给人读的文档
```

Godot 工程根目录就是仓库根目录，入口文件是 `project.godot`。

空目录里的 `.gitkeep` 只是为了让 Git 记住这个文件夹。放进真正的文件之后可以删掉它。

二进制资源（png、jpg、wav、ogg、mp3、ttf、glb 等）由 Git LFS 管理，规则在 `.gitattributes`。克隆之前要先装好 Git LFS，否则这些文件会变成一小段指针文本，Godot 打不开。

## 场景和脚本

一个画面一个场景：

| 场景 | 脚本 | 作用 |
| --- | --- | --- |
| `scenes/main/main_menu.tscn` | `scripts/main/main_menu.gd` | 标题和「开始」 |
| `scenes/battle/battle_lane.tscn` | `scripts/battle/battle_lane.gd` | 占位车道和「返回」 |

场景脚本不写 `class_name`，用节点路径和 `%唯一名` 找按钮。纯数据类才写 `class_name`，例如 `BalanceConfig` 和 `SaveGame`，这样测试和其他脚本都能直接用类型。

竖屏设置在 `project.godot`：

- 视口 1080×1920
- 拉伸模式 `canvas_items`，比例 `expand`
- 手持方向为纵向
- 渲染器为 Mobile
- 桌面窗口用 540×960 显示，避免编辑器里窗口铺满屏幕；逻辑分辨率仍然是 1080×1920。和 Cursor 并排的用法见 `docs/DEV_LOOP.md`

界面中文走 `AppTheme` 自动加载：它复制 Godot 默认主题，只换上 `assets/fonts/NotoSansSC-Regular.ttf`，按钮样式保持引擎自带的样子。字体子集覆盖基本拉丁字符和中日韩统一表意文字（U+4E00–U+9FFF）。日常简体中文够用。如果某个很生僻的字显示成方框，需要扩大子集后重新放进 `assets/fonts/`，并保留 `OFL.txt`。

## 自动加载

| 名称 | 脚本 | 职责 |
| --- | --- | --- |
| `AppTheme` | `scripts/autoload/app_theme.gd` | 启动时设置中文字体 |
| `GameState` | `scripts/autoload/game_state.gd` | 当前小队人数和物资。启动时读数值配置 |

自动加载按 `project.godot` 里的顺序初始化。`AppTheme` 在前，这样主场景出现时字体已经换好。

以后如果要加音效总线、场景切换记录，再新增自动加载，并在这张表里写一行。不要把所有逻辑都塞进 `GameState`。

## 数值配置

平衡数字放在 `data/balance/starting_balance.json`：

| 字段 | 含义 | 当前值 |
| --- | --- | --- |
| `starting_squad_size` | 进入车道时的小队人数，最小为 1 | 1 |
| `gate_bonus_per_upgrade` | 每通过一道「加人门」增加的人数 | 1 |
| `starting_supplies` | 开局物资 | 0 |

`BalanceConfig` 负责读取和计算，例如 `squad_size_after_gates()`。场景脚本只问 `GameState` 要结果，不自己解析 JSON。

新增一种 JSON 时，记得在 `export_presets.cfg` 的 `include_filter` 里能匹配到它。Godot 默认只打包它认识的资源；JSON 这种纯文本要靠 include filter 才能进 APK。当前规则是 `data/*`。

## 存档

`SaveGame` 把一份字典写成 JSON：

```json
{
  "version": 1,
  "data": {
    "squad_size": 1,
    "supplies": 0
  }
}
```

`version` 用来以后迁移旧档。读写失败时返回空字典或错误码，不让游戏崩掉。

计划中的落点是玩家设备上的 `user://saves/profile.json`。标题画面和基地在后续 PR 里调用 `SaveGame`，`GameState` 继续只保存这一局内存里的状态。当前占位场景还不会写盘，但测试已经覆盖了来回读写。

不要把存档写进 `res://`。`res://` 在导出后是只读的。

## 导出

Android 预设在 `export_presets.cfg`，预设名是 `Android`。

- 使用引擎自带的调试 APK 模板，不开启 Gradle 自定义构建。这样 CI 不必编译 Java 工程。
- 包名 `com.xyn159.thelastsurvivor`。
- 只打 `arm64-v8a`，覆盖当前绝大多数手机。
- 版本名留空，导出时采用 `project.godot` 里的 `application/config/version`。
- 证书三项都留空。调试证书来自本机 Godot 的编辑器设置，或 CI 里的环境变量 `GODOT_ANDROID_KEYSTORE_DEBUG_PATH`、`GODOT_ANDROID_KEYSTORE_DEBUG_USER`、`GODOT_ANDROID_KEYSTORE_DEBUG_PASSWORD`。
- 测试插件和 `tests/` 被排除在安装包之外。

发布到商店需要的正式证书以后再加，并且只放在 GitHub Secrets 或你自己的电脑上。

## 以后的服务器

多人要等单机 MVP 玩起来之后再做。预留的接法是：

- 玩法代码只生产普通字典：小队、资源、建筑等级、已通过的关卡。
- `SaveGame` 今天把字典写进本地文件。以后可以加一个同样接收这份字典的上传实现，把 JSON 发给你自己的 VPS。
- 战斗、基地、数值计算不直接打开网络连接。网络只出现在那一个存档出入口。
- 服务器不负责算车道碰撞。手机上算出结果，服务器负责保存和以后可能的校验。

在单机循环稳定之前，不要加网络自动加载，也不要加账号系统。
