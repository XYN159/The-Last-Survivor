# 架构

这份文档说明代码放在哪里、数据怎么流。玩法意图在 `docs/GDD.md`，写法约定在 `docs/CODING_STYLE.md`。

## 目录

```
addons/gut/          GUT 测试插件（第三方，不要手改）
assets/audio/        音效和音乐
assets/fonts/        界面字体。Noto Sans SC 子集（许可证见 OFL.txt）；霞鹜文楷（许可证见 LXGWWenKai-OFL.txt）
assets/models/       三维模型（glb 等）
assets/textures/     图片
assets/ui/originals/ 二十张界面原画（1920×1080），原样拷自原画分支，不改画面
assets/video/        过场视频（Theora 编码的 ogv，Git LFS）。现在只有序章第一关的关前视频 prologue_01_pre.ogv
data/balance/        数值 JSON。调平衡改这里
data/levels/         正式关卡。现在只有 prologue_01.json，原样复制自关卡 PR #5
data/prototype/      塔防原型用的数值和旧的两路试验关。正式表合并前先读这里
data/ui/             界面原画的点击区表（只有坐标和跳转，没有数值）
scenes/main/         标题等流程场景
scenes/battle/       可玩的塔防棋盘，以及还留着的旧车道画面
scenes/ui/           以后可复用的界面碎片（目前还没有）
scripts/autoload/    自动加载的全局节点
scripts/balance/     旧车道数值的读取和计算
scripts/battle/      塔防规则（不画画面）、棋盘画面和战斗动效
scripts/main/        启动流程和标题场景脚本
scripts/save/        存档读写
scripts/ui/          界面动效的公共部分（动效时长表、缓动曲线、按钮按压）和界面原画的点击区表
tests/unit/          GUT 测试，文件名以 test_ 开头
tests/capture/       手动运行的截图脚本，不进 GUT
ci/                  给 GitHub Actions 用的脚本
docs/                给人读的文档
```

Godot 工程根目录就是仓库根目录，入口文件是 `project.godot`。

空目录里的 `.gitkeep` 只是为了让 Git 记住这个文件夹。放进真正的文件之后可以删掉它。

二进制资源（png、jpg、wav、ogg、ogv、mp3、ttf、glb 等）由 Git LFS 管理，规则在 `.gitattributes`。克隆之前要先装好 Git LFS，否则这些文件会变成一小段指针文本，Godot 打不开。

## 场景和脚本

一个画面一个场景：

| 场景 | 脚本 | 作用 |
| --- | --- | --- |
| `scenes/main/original_flow.tscn` | `scripts/main/original_flow.gd` | 启动场景。二十张界面原画串成的流程：启动页、登录、主界面和各个子画面，出击先进关前视频，再进序章棋盘，打完回结算原画。见下面「界面原画流程」 |
| `scenes/main/prologue_pre_video.tscn` | `scripts/main/prologue_pre_video.gd` | 序章第一关战斗前的全屏关前视频。点屏幕或右上角「跳过」立刻进棋盘，播完也进棋盘，只换一次场景；视频打不开就警告后直接进棋盘。见 ADR-0010 |
| `scenes/main/main_menu.tscn` | `scripts/main/main_menu.gd` | 旧的序章标题。现在不是启动场景，也没有画面再跳回它 |
| `scenes/battle/battle_board.tscn` | `scripts/battle/battle_board.gd` | 可玩的塔防棋盘。按钮和结算在这里，规则不在这里 |
| `scenes/battle/battle_lane.tscn` | `scripts/battle/battle_lane.gd` | 旧车道占位。标题已经不进这里 |

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

平衡数字放在 `data/balance/starting_balance.json`。下面这些字段仍是旧占位原型在用，塔防数值以后另写，不要把这里当成新玩法的定案：

| 字段 | 含义 | 当前值 |
| --- | --- | --- |
| `starting_squad_size` | 进入车道时的小队人数，最小为 1 | 1 |
| `gate_bonus_per_upgrade` | 每通过一道「加人门」增加的人数 | 1 |
| `starting_supplies` | 开局物资 | 0 |

`BalanceConfig` 负责读取和计算，例如 `squad_size_after_gates()`。场景脚本只问 `GameState` 要结果，不自己解析 JSON。

塔防原型的数字不写在上面那张旧表里。它们在 `data/prototype/`：

| 文件 | 作用 |
| --- | --- |
| `combat/rules.json` | 棋盘像素、tick、布阵和波间 |
| `combat/stats.json` | 攻击、费用、敌人生命和移速 |
| `combat/characters.json` | 灵梦、魔理沙怎么打 |
| `combat/enemies.json` | 小残影、快残影的体型和击退 |
| `combat/feel.json` | 闪白和伤害数字 |
| `ui_motion.json` | 序章动效的时长和幅度（进关、放置、按钮、受击、结算），以及界面原画换页的淡入时长。全是临时值，见 ADR-0007 |
| `levels/prototype_01.json` | 旧的两路试验关。「开始」不再进这里，只留给测试 |
| `level_difficulty.json` | 每关的开局灵力、每波加的灵力和血量倍率。`prologue_01` 这一行是照抄 #8 的临时行 |

「开始」进的关卡是 `CombatCatalog.DEFAULT_LEVEL_ID`，现在是 `prologue_01`，地图、路线和波次读 `data/levels/prologue_01.json`。这份文件原样复制自关卡 PR #5，归关卡策划，程序不改它的内容。

`CombatCatalog` 负责读这些文件。`USE_OFFICIAL_TABLES` 现在是 `false`。把它改成 `true` 之前，#4（`rules.json`、`characters.json`、`enemies.json`、`feel.json`）、#5（`data/levels`）和 #8（`stats.json`、`level_difficulty.json`）都要先合并。只合了其中一份就打开，会缺文件。开关打开后，缺文件或缺关键字段会 `push_error`，不再悄悄用默认值。关键字段是攻击、费用、射程、间隔、血量、移速、护甲、漏怪伤害、血量倍率。

玩家能看见的字在 `locale/game_zh.csv`，并登记在 `project.godot` 的 `locale/translations`。角色、敌人、关卡、HUD、按钮和结算都用文本 key。日志和 `push_warning` 不走这张表。

一局怎么打在 `BattleSim` 里，不在场景脚本里。画面每帧问它要快照。无头试跑是 `scripts/battle/simulate_level.gd`。

## 动效

动效只读规则发出的事件和快照，不反过来改规则。分成几块（决定记录见 `docs/adr/0007-prologue-motion-overlay.md`）：

| 节点 / 脚本 | 推进方式 | 负责 |
| --- | --- | --- |
| `BoardMotion`（`scripts/battle/board_motion.gd`），`BoardView` 的子节点 | 真实时间 × 倍速 | 选格光、盖章、结界圈、小符纸、受击光点、飞向灵力的光点、守护点裂纹 |
| `ScreenMotion`（`scripts/battle/screen_motion.gd`） | 真实时间 | 进关暗幕和上下栏、生命数字抖动、灵力数字亮一下、结算卡展开 |
| `ResultMotes`（`scripts/battle/result_motes.gd`） | 真实时间 | 结算卡后面的金色或灰色光点 |
| `PressMotion`（`scripts/ui/press_motion.gd`），代码挂到按钮下 | 真实时间 | 「开始」和「出击」按下缩小、松开回弹 |

动效节点一律不接收点击（`mouse_filter` 为忽略）。时长和幅度都在 `data/prototype/ui_motion.json`，由 `MotionConfig` 读取。

动效截图用手动脚本，按固定步长推进，每次画面一样：

```bash
MOTION_CAPTURE_DIR=/tmp/motion godot --path . --resolution 1920x1080 -s tests/capture/motion_capture.gd
```

## 界面原画流程

二十张 1920×1080 界面原画放在 `assets/ui/originals/`，内容和原画分支 `docs/design/art/ui_originals/` 一模一样，不改画面。决定记录见 `docs/adr/0008-ui-originals-as-placeholder-screens.md`。

- `OriginalScreens`（`scripts/ui/original_screens.gd`）读 `data/ui/original_screens.json`：每个画面用哪张图、哪些地方能点、点了做什么。坐标按原图像素写，`rect` 是 `[左, 上, 宽, 高]`。
- `original_flow.gd` 把原画放进居中的 1920×1080 舞台，按表在上面盖透明按钮；没有画在原画上的入口（登录页的「服务器」「公告」，主界面的「抽卡」「体力」，角色详情的「装备」）是带字的小按钮，文字走 `ui.originals.*`。除了启动页、登录、主界面和体力弹窗，每屏都有「返回」。
- 点击动作只有几种：`push` 进下一屏、`back` 回上一屏、`replace` 替换当前屏、`reset` 清空历史只留目标屏、`popup` / `close_popup` 开关弹窗、`battle` 先进关前视频、再进序章棋盘。
- 战斗结算卡上的「继续」把 `original_flow.gd` 的 `pending_entry` 设成 `result`，回到流程时先显示结算原画，下面垫着主界面。
- 这一层不写存档、不记账号、不联网，也不碰任何数值。抽卡、商店、邮件、升级只能打开、看、返回。

流程截图同样用手动脚本，从启动页一路点到战斗，再经结算回主界面：

```bash
ORIGINALS_CAPTURE_DIR=/tmp/originals godot --path . --resolution 1920x1080 -s tests/capture/originals_capture.gd
```

新增一种 JSON 时，记得在 `export_presets.cfg` 的 `include_filter` 里能匹配到它。Godot 默认只打包它认识的资源；JSON 这种纯文本要靠 include filter 才能进 APK。当前规则是 `data/*` 和 `locale/*`。

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
- 包名 `com.xyn159.touhouforgottendefense`。应用名是「东方守幻录」。游戏还没发布过，改包名没有旧安装包要兼容。
- 调试 APK 文件名是 `touhou-forgotten-defense-debug.apk`。
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
- 服务器不负责算这一局怎么打。手机上算出结果，服务器负责保存和以后可能的校验。

在单机循环稳定之前，不要加网络自动加载，也不要加账号系统。
