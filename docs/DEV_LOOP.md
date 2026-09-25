# 每天的开发循环

目标是这样摆屏幕：左边是 Cursor，右边是正在跑的游戏。AI 改完脚本并保存后，游戏里能看到变化。你看完差别，再决定留不留。

引擎版本是 **Godot 4.7.2**，和 `godot-version.txt` 一致。下面的菜单名按这个版本的简体中文界面来写，括号里是英文原名。你的编辑器如果是英文，用括号里的名字找。

安装 Godot、Cursor 和克隆仓库的步骤在 [`docs/SETUP_WINDOWS.md`](SETUP_WINDOWS.md)。

## 桌面上的窗口有多大

手机上的逻辑分辨率是 **1080×1920**，竖屏。桌面预览窗口是 **540×960**，正好是一半，一台笔记本上可以放在编辑器旁边。

这两套数字都在 `project.godot` 里：

- `window/size/viewport_width` / `viewport_height`：1080 和 1920。游戏逻辑和以后的手机画面按这个算。
- `window/size/window_width_override` / `window_height_override`：540 和 960。只影响桌面窗口有多大。

拉伸模式是 `canvas_items`，比例是 `expand`。窗口和手机的比例不完全一样时，画面会多留出一点边，不会把按钮拉变形。

在编辑器里查看：**项目 → 项目设置 → 显示 → 窗口**（Project → Project Settings → Display → Window）。不要把视口改成 540×960，那会让手机上的画面变糊。只改窗口覆盖值。

## 1. 让 Godot 用 Cursor 打开脚本

Godot 自己也能改脚本。日常改代码放在 Cursor 里，Godot 负责看场景和运行游戏。

1. 打开 Godot 里的这个工程。
2. 菜单 **编辑器 → 编辑器设置**（Editor → Editor Settings）。
3. 左侧进入 **文本编辑器 → 外部**（Text Editor → External）。
4. 勾选 **使用外部编辑器**（Use External Editor）。
5. **可执行文件路径**（Exec Path）填 Cursor 的 `Cursor.exe`，不是快捷方式。

   常见位置是：

   `C:\Users\你的用户名\AppData\Local\Programs\cursor\Cursor.exe`

   不确定时：先打开 Cursor，再打开任务管理器，在 Cursor 上右键，选「打开文件所在的位置」，把那个 `Cursor.exe` 的完整路径贴过来。

6. **执行参数**（Exec Flags）整行贴上：

   ```text
   {project} --goto {file}:{line}:{col}
   ```

   从 Godot 4.5 起，它认识的编辑器会自动填参数。名单里有 Visual Studio Code，没有 Cursor。`Cursor.exe` 不会被自动认出来，所以这一行要自己贴。花括号不要改，Godot 会换成工程路径、文件路径、行号和列号。

7. 再进入 **文本编辑器 → 行为 → 文件**（Text Editor → Behavior → Files），确认 **外部修改时自动重新加载脚本**（Auto Reload Scripts on External Change）是勾上的。Godot 4.7.2 默认就是勾上的。勾上之后，Cursor 一保存 `.gd` 文件，Godot 会自己重新读，不必每次点对话框。

8. 打开任意一个脚本，看脚本编辑器顶部的 **调试** 菜单（这是脚本编辑器里的 Debug，不是窗口最上方那一个）。勾选 **使用外部编辑器调试**（Debug with External Editor）。断点停住时，Godot 会把文件送到 Cursor，而不是在自己的脚本页里打开。这一项默认是关的。

试一次：在 Godot 里双击 `scripts/main/main_menu.gd`。Cursor 应打开这个文件。打不开就回到第 5 步，确认路径指向的是 `Cursor.exe`。

## 2. 游戏运行时同步场景和脚本

按 `F5` 把游戏跑起来之后，打开窗口最上方的 **调试** 菜单（Debug），确认这两项有勾：

- **同步场景修改**（Synchronize Scene Changes）
- **同步脚本修改**（Synchronize Script Changes）

Godot 4.7.2 里这两项默认就是勾上的，并且按工程记住。如果某次被关掉了，再勾上。

它们分别做什么：

- **场景。** 你在 Godot 的场景停靠栏里改「本地」（Local）场景树，正在跑的游戏会跟着变。停掉游戏后，这些改动还在。游戏运行时场景树会多出一个「远程」（Remote）标签，那里的改动停游戏后就没了。要留住改动，改本地场景树。
- **脚本。** 脚本被保存之后，正在跑的游戏会重新加载它。在 Cursor 里改完要保存（`Ctrl+S`）。只打字、不保存，游戏不会变。

Cursor 直接改 `.tscn` 时，Godot 是从磁盘重新读场景文件，不是你在场景停靠栏里拖控件。文件面板提示重新加载时，选重新加载。脚本热更新比较稳；场景文件如果没立刻反映到正在跑的画面上，停掉再按一次 `F5`。

在手机上远程调试时，官方说明写的是：再打开 **使用网络文件系统的小型部署**（Small Deploy with Network Filesystem），场景和脚本同步会更快。这个工程资源还很小，平时不用开。

## 3. 一键部署到安卓手机

编辑器右上角可以出现一个安卓图标。点它会打调试包、装到已经连上的手机并运行。这叫一键部署。仓库里的 Android 预设已经标成可运行（`runnable=true`），不用再新建一个预设。

先做完 [`docs/SETUP_WINDOWS.md`](SETUP_WINDOWS.md) 第 3 节，装上 **4.7.2** 导出模板。

### 在电脑上指出 JDK 17 和 Android SDK

Godot 4.7 导出安卓时要自己找到 `java` 和 `adb`。路径写在编辑器设置里，不写进仓库。

1. 安装 **JDK 17**。可用 [Eclipse Temurin 17](https://adoptium.net/temurin/releases/?version=17&os=windows&arch=x64&package=jdk)。不要用 Java 8 或 Java 21 代替，Godot 4.7 的安卓导出按 JDK 17 来。
2. 安装 Android SDK。装 [Android Studio](https://developer.android.com/studio) 时会带上 SDK。只想要命令行工具也可以，但要保证里面有 `platform-tools`（含 `adb`）和 `build-tools`（含 `apksigner`）。
3. 回到 Godot：**编辑器 → 编辑器设置 → 导出 → Android**（Editor Settings → Export → Android）。
4. **Java SDK 路径**（Java SDK Path）填 JDK 的根目录，也就是里面有 `bin\java.exe` 的那一层。不要填到 `java.exe` 自己。

   示例：`C:\Program Files\Eclipse Adoptium\jdk-17.0.xx.x-hotspot`

5. **Android SDK 路径**（Android SDK Path）填 SDK 根目录，里面应能看到 `platform-tools\adb.exe`。

   示例：`C:\Users\你的用户名\AppData\Local\Android\Sdk`

路径不对时，Godot 会直接说缺 `bin`、找不到 `java`、缺 `platform-tools` 或找不到 `apksigner`。按那句提示改路径，不要猜。

第一次成功导出时，Godot 会在你的用户目录里生成一把调试证书。不要把它拷进仓库，也不要发到网上。

### 在手机上打开 USB 调试

各家手机的菜单名字略有差别，顺序是一样的：

1. 打开系统设置，进入「关于手机」。
2. 连续点「版本号」（有的机型叫「构建号」）大约 7 次，直到出现「你已处于开发者模式」。
3. 返回设置，进入「系统」或「更多设置」里的 **开发者选项**。
4. 打开 **USB 调试**。
5. 用数据线把手机接到电脑。手机上弹出「允许 USB 调试吗」，勾选一律允许，再点允许。
6. 在电脑上确认连上了。如果 `adb` 还不在命令行里，用 Android SDK 的 `platform-tools` 目录，或下一节 scrcpy 解压目录里的 `adb.exe`：

   ```bash
   adb devices
   ```

   列表里应出现一行设备号，右边是 `device`。如果是 `unauthorized`，回到手机上看授权弹窗。如果列表是空的，换一根数据线（有的线只能充电），并重新插拔。

### 点右上角的安卓按钮

设备被认出来、导出模板和上面两条路径都有效时，Godot 右上角播放按钮旁边会出现安卓图标。点它。

编辑器会打调试包、安装并启动。窗口最上方 **调试** 菜单里的 **使用远程调试部署**（Deploy with Remote Debug）在 4.7.2 里默认是勾上的。保持勾选，手机上的游戏才会连回这台电脑，方便看报错。本地按 `F5` 不依赖这一项。

无线调试可以以后再弄：手机和电脑在同一个 Wi-Fi，用 `adb pair` 配对。日常先用数据线。

## 4. 用 scrcpy 把手机画面映到 Windows

[scrcpy](https://github.com/Genymobile/scrcpy) 把手机屏幕映到电脑上，这样手机可以放在桌上，你看电脑右侧的画面。

1. 从上面的发布页下载 Windows 压缩包并解压，例如放到 `C:\Tools\scrcpy\`。里面有 `scrcpy.exe`，也带了一份 `adb.exe`。
2. USB 调试已经打开，并且 `adb devices` 能看到 `device`。
3. 在该目录打开终端，执行：

   ```bash
   scrcpy --max-size 960
   ```

   `--max-size 960` 把镜像窗口限制在大约 960 像素的长边，避免盖住左边的 Cursor。不加这个参数会按手机原始分辨率开一个更大的窗口。

这是独立于 Godot 的镜像，CI 装上的包和一键部署的包都能看。

Godot 4.7 也可以在一键部署时自己启动 scrcpy：

1. **编辑器设置 → 导出 → Android → scrcpy → 路径**（Export → Android → scrcpy → Path）填 `scrcpy.exe` 的完整路径，例如 `C:\Tools\scrcpy\scrcpy.exe`。留空时 Godot 会在系统路径里找 `scrcpy`。
2. 这个工程是竖屏。Godot 4.7 默认会开一块 **虚拟显示**（Virtual Display），尺寸是 `1920x1080/120`，那是横屏。要看手机自己的竖屏画面，把 **虚拟显示** 关掉。关掉后，scrcpy 镜像的是手机当前屏幕。
3. 右上角安卓设备列表的第一项是 **镜像安卓设备**（Mirror Android devices）。点一次，图标变成勾选。然后再点具体的那台手机做一键部署。Godot 会用 scrcpy 启动游戏。

找不到 `scrcpy.exe` 时，输出面板会写：到编辑器设置的 Export → Android → scrcpy → Path 里配置路径。

## 5. 用 Cursor 的 Agent 改代码

1. 用 Cursor 打开仓库文件夹（里面直接能看到 `project.godot` 的那一层）。
2. 右下角如果提示安装推荐扩展，安装 **godot-tools**（发布者 geequlim）。也可以自己在扩展市场搜 `geequlim.godot-tools`。
3. 如果 Godot 不在 `C:\Tools\Godot\Godot_v4.7.2-stable_win64.exe`，打开 `.vscode/settings.json`，只改 `godotTools.editorPath.godot4` 那一行。
4. Godot 编辑器开着这个工程时，Cursor 底部状态栏的 GDScript 语言服务器应连上。端口是 **6005**。连不上时，看本文最后的端口表，不要把扩展改回 6008。
5. 在聊天里切到 **Agent**，用中文说明要改什么。
6. 它改完后先看差别，再决定留不留：
   - 聊天里的改动卡片可以点开，每一块改动（hunk）旁边有接受和拒绝。
   - 接受（Accept / Keep）留下这一块。拒绝（Reject / Undo）丢掉这一块。
   - 左侧源代码管理里也能看到全部文件的差别。
   - 看不懂的先拒绝，让它重做。不要整份改动不看就全部接受。
7. 接受并保存之后，如果游戏还在右边跑，并且第 2 节的两个同步项是勾上的，脚本改动会进到正在跑的游戏里。

从 Cursor 里启动游戏：左侧「运行和调试」，选 **GDScript: Launch Project**，按 `F5`。它会用 godot-tools 启动主场景，窗口大小同样是 540×960。地址必须是 `127.0.0.1`，不要写成 `http://127.0.0.1`，当前的 godot-tools 2.x 会拒绝带协议的地址。断点下在 `.gd` 文件的行号左边。

Godot 4.7 文档里的旧示例还写了 `debugServer: 6006`。核对过 godot-tools **2.7.1** 的配置：它自己启动游戏，并用 `--remote-debug` 连回 `port`（6007），不再读取 `debugServer`。所以仓库里的 `launch.json` 不写这一项。Godot 自己的调试适配器端口仍是 6006，不用为了这个启动项去改它。

### 本机上的 AI 也要走分支和 PR

Agent 在你电脑上改文件，和在云端改文件是同一条规矩。不要把改动直接推进 `main`。

在 Git Bash 里，仓库目录下：

```bash
git switch main
git pull origin main
git switch -c feature/短英文名
```

修缺陷用 `fix/`，杂务用 `chore/`，只改文档用 `docs/`。改完并看过差别之后再提交、推送这条分支，然后在 GitHub 上开拉取请求。合并方式写在 [`CONTRIBUTING.md`](../CONTRIBUTING.md)。给 AI 的硬性规则在 [`AGENTS.md`](../AGENTS.md)。

如果 Agent 问能不能推送到 `main`，回答是不能。让它停在当前功能分支上。

## 端口对照

连不上补全或断点时，先对这张表。三个端口各干一件事，不要设成同一个。

| 用途 | 端口 | 在哪里 |
| --- | --- | --- |
| 代码补全（LSP） | 6005 | Godot：**网络 → 语言服务器 → 远程端口**。Cursor：`godotTools.lsp.serverPort` |
| Godot 自带调试适配器（DAP） | 6006 | Godot：**网络 → 调试适配器 → 远程端口**。本仓库的启动项不用改它 |
| 游戏连回调试器 | 6007 | Cursor 的 `launch.json` 里 `port`。Godot：**网络 → 调试 → 远程端口** |

中文界面里，「网络」是 Network，「调试」是 Debug，「语言服务器」是 Language Server，「调试适配器」是 Debug Adapter，「远程端口」是 Remote Port。
