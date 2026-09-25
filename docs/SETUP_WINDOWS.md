# 在 Windows 上把游戏跑起来

这份说明假设你平时不写代码。每一步做完，都应该能看到下面写的结果。做不到就停下来，把你看到的画面记下来，再继续让 AI 看，不要连跳几步。

引擎版本必须是 **4.7.2 标准版**，和仓库里的 `godot-version.txt` 一致。版本不同，工程可能打不开，打出来的 APK 也会和 CI 对不上。

## 1. 安装 Git 和 Git LFS

1. 打开 <https://git-scm.com/download/win> 下载 Git for Windows。
2. 安装时，看到 **Git LFS** 的选项就勾上。其他选项保持默认即可。
3. 安装结束后打开「开始」菜单里的 **Git Bash**，输入：

```bash
git lfs install
git --version
git lfs version
```

两条 version 都有数字就算成功。先装 LFS 再克隆。如果先克隆，图片和字体会坏掉，需要在仓库目录里再执行一次 `git lfs pull`。

## 2. 安装 Godot 4.7.2

1. 打开 <https://godotengine.org/download/archive/4.7.2-stable/>。
2. 下载 **Windows x86_64** 的标准版。不要下载带 .NET 或 C# 字样的版本。
3. 解压 zip。里面是一个 `Godot_v4.7.2-stable_win64.exe`。把它放进一个不会被清理的文件夹，例如 `C:\Tools\Godot\`。
4. 双击运行。第一次会问要不要导入旧设置，没有旧版本就选不导入。
5. 窗口标题或关于对话框里应能看到 **4.7.2**。

Godot 不需要安装到系统里，这个 exe 就是编辑器。

## 3. 安装 Android 导出模板

只有在你想从自己的电脑打 APK 时才需要。平时只按 F5 预览，可以先跳过。CI 会自己下载同一份模板。

1. 在 Godot 顶部菜单选 **编辑器 → 管理导出模板**。
2. 下载并安装和编辑器匹配的 **4.7.2** 模板。状态变成已安装即可。
3. 如果网页下载更快，可以用这个文件，再选「从文件安装」：<https://github.com/godotengine/godot/releases/download/4.7.2-stable/Godot_v4.7.2-stable_export_templates.tpz>

调试证书不用自己做。Godot 第一次导出时会在编辑器设置里生成一把 debug keystore。不要把那个文件发到网上，也不要放进仓库。

## 4. 安装 Cursor

1. 打开 <https://cursor.com/download>，下载 Windows 版并安装。
2. 用你的账号登录。
3. 以后看 AI 改界面时：左边 Cursor，右边游戏。把 Cursor 设成外部编辑器、打开运行时同步、以及在手机上部署，都写在 [`docs/DEV_LOOP.md`](DEV_LOOP.md)。

## 5. 克隆仓库

在 Git Bash 里：

```bash
cd /c/Users/你的用户名/Documents
git clone https://github.com/XYN159/The-Last-Survivor.git
cd The-Last-Survivor
```

克隆完成后，`assets/fonts/NotoSansSC-Regular.ttf` 应该是一个大约 7MB 的字体文件，而不是几行 `version https://git-lfs.github.com/spec/v1` 文本。如果是文本，执行 `git lfs pull`。

## 6. 把某个 PR 的分支拉到本机

GitHub 的 PR 页面上有分支名，例如 `chore/project-scaffold`。在仓库目录里：

```bash
git fetch origin
git switch --track origin/chore/project-scaffold
```

已经跟踪过这条分支时，用 `git switch chore/project-scaffold` 再 `git pull`。

回到主线：

```bash
git switch main
git pull origin main
```

## 7. 在编辑器里运行

1. 打开 Godot。如果它还停在项目列表，选 **导入**，找到仓库里的 `project.godot`。
2. 第一次导入会扫资源，等它结束。
3. 按 `F5`，或点右上角的播放按钮。
4. 应该看到深色标题 **The Last Survivor**、中文副标题，以及 **开始** 按钮。
5. 点 **开始**，进入「战斗车道」。画面中间有一条竖道和两道色块，并显示 **小队人数：1**。
6. 点 **返回**，回到标题。

窗口比手机窄，是故意的：逻辑分辨率仍是 1080×1920，桌面上缩成 540×960，免得挡住别的窗口。

底部 GUT 面板可以跑测试。没看到这个面板时，打开 **项目 → 项目设置 → 插件**，确认 Gut 已启用，然后重启编辑器。

## 8. 把 CI 的 APK 装到手机

1. 用浏览器打开仓库的 **Actions**。
2. 左侧选 **CI**，点开一次绿色的运行。
3. 拉到页面底部，下载名为 `the-last-survivor-android-debug` 的 Artifact。
4. 解压，得到 `the-last-survivor-debug.apk`。
5. 用数据线或微信文件传输助手把 APK 拷到手机。
6. 在手机上点开 APK。如果系统拦截，到设置里允许浏览器或文件管理器「安装未知应用」，然后再点一次。
7. 安装后打开，应看到和编辑器里一样的标题画面。点「开始」和「返回」确认。

这是调试签名，Android 会提示来源不明。这是预期现象，不要拿它上架。

电脑上如果装了 Android Platform Tools，也可以在 APK 所在目录执行：

```bash
adb install -r the-last-survivor-debug.apk
```

手机需要先打开开发者选项里的 USB 调试。
