# 参与协作

这个仓库用 GitHub Flow：`main` 永远是能发布的版本，任何改动都先开分支，再通过拉取请求（Pull Request，下面简称 PR）进来。不要直接把提交推到 `main`。

你不需要先成为程序员才能看懂一次改动。每个 PR 的描述都用中文写清楚改了什么、为什么改、怎么自己点一点确认。

## 分支

从最新的 `main` 拉出分支。名字用下面几种前缀：

| 前缀 | 用来做什么 | 例子 |
| --- | --- | --- |
| `feature/` | 新玩法或新功能 | `feature/lane-gates` |
| `fix/` | 修一个已经存在的问题 | `fix/start-button-overlap` |
| `chore/` | 工程、工具、CI，不改玩法 | `chore/project-scaffold` |
| `docs/` | 只改文档 | `docs/gdd-buildings` |

```bash
git switch main
git pull origin main
git switch -c feature/lane-gates
```

## 提交说明

提交说明用英文 [Conventional Commits](https://www.conventionalcommits.org/)，方便以后按版本号归类。PR 的标题同样用这种英文格式；PR 正文用中文。

常用类型：

| 类型 | 含义 |
| --- | --- |
| `feat` | 玩家能感知的新功能 |
| `fix` | 修复问题 |
| `docs` | 只改文档 |
| `test` | 只加或只改测试 |
| `chore` | 工具、构建、杂项 |
| `refactor` | 行为不变的代码整理 |

例子：`feat: show squad size on the battle lane`

一次提交只做一件事。PR 也保持小：一个 PR 最好只解决一个问题，让你能在几分钟内看完描述并点进游戏确认。

## 打开 PR

1. 把分支推上去：`git push -u origin feature/lane-gates`
2. 在 GitHub 上打开 PR，目标分支是 `main`。
3. 按模板填写：改了什么、为什么、截图、怎么验证。
4. 勾选清单。改了玩法就更新 `docs/GDD.md`；改了工程结构就更新 `docs/ARCHITECTURE.md`；任何玩家或工程上的变化都更新 `CHANGELOG.md`。
5. 等 CI 全绿。三个检查的名字是 `lint`、`test`、`export-android`。

界面有变化时，在描述里放上截图。

## 审查和合并

- `.github/CODEOWNERS` 会把 `@XYN159` 标成审查者。
- 看中文描述能不能让你复述这次改动。看不懂就让作者改描述，不要猜。
- CI 必须通过。APK 工件可以下载到手机上试。
- 建议用 **Squash and merge**。这样 `main` 上一个 PR 对应一次提交，历史更短。合并标题保持 Conventional Commits 英文。
- 不要给 `main` 设置「必须有 1 个批准」的审查人数，除非另有第二个人帮你点批准。GitHub 不允许作者批准自己的 PR，人数设成 1 会把你自己卡在外面。要求「必须通过 PR」本身已经能挡住直接推送。

## 让分支跟上 main

别人的改动进了 `main` 之后，你的分支要先合入最新 `main` 再继续：

```bash
git switch feature/lane-gates
git fetch origin
git merge origin/main
```

有冲突时，Git 会在文件里留下 `<<<<<<<` 和 `>>>>>>>`。打开那个文件，留下想要的内容，删掉这些标记，然后：

```bash
git add 冲突的文件
git commit
git push
```

对还在学习的阶段，用 `merge` 即可。`rebase` 会改写已经推送过的提交，更容易把分支弄乱。

## 撤回一次不好的改动

还没合并的 PR：再推一个修正提交，或者直接关掉 PR。不要强推 `main`。

已经合并进 `main`：新开一个修复分支，用 `git revert` 做一次反向提交，再开 PR。假设那次合并提交的编号是 `abc1234`：

```bash
git switch main
git pull origin main
git switch -c fix/revert-bad-change
git revert -m 1 abc1234
git push -u origin fix/revert-bad-change
```

然后照常开 PR，等 CI 通过再合并。这样历史里能看到「加过」和「撤掉」，而不是把记录擦掉。

## 版本号和发布

版本号用[语义化版本](https://semver.org/lang/zh-CN/)：`主版本.次版本.修订号`。

- `0.y.z`：游戏还在成形。次版本可以带来较大的玩法变化。
- 修订号：修问题，玩法不变。
- 次版本：向后兼容的新内容。
- 到 `1.0.0` 之后，主版本才表示存档或操作对不上的大改。

当前工程版本写在 `project.godot` 的 `application/config/version`。Android 的 `version/code` 在 `export_presets.cfg` 里，每次真正发给别人安装、需要覆盖旧包时再加 1。

发布步骤：

1. 确认要发布的提交已经在 `main` 上，而且 CI 是绿的。
2. 把 `CHANGELOG.md` 里 `Unreleased` 的条目挪到新版本号下面，并写上日期。这个改动本身也走 PR。
3. 合并之后，在那次 `main` 提交上打标签并推送：

```bash
git switch main
git pull origin main
git tag v0.1.0
git push origin v0.1.0
```

4. 标签会触发 Release 工作流，把调试签名的 APK 挂到 GitHub Release。

调试签名的包不能上架。以后如果要上 Google Play，再单独做发布证书，并放进 GitHub Secrets，不要放进仓库。那一步会另写决定记录。

## 本地跑和 CI 一样的检查

CI 用的是 Python 工具 gdtoolkit 4.5.0。你平时只在 Godot 里点运行也可以，CI 会帮你查格式。想在自己电脑上提前查：

```bash
py -3 -m pip install -r requirements-dev.txt
py -3 -m gdformat --check scripts tests
py -3 -m gdlint scripts tests
```

测试在 Godot 里用底部的 GUT 面板运行，或在安装了 Godot 命令行的环境里执行 `./ci/run_tests.sh`。
