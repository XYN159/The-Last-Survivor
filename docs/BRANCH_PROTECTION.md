# 保护 main 分支

代码和 CI 已经要求「改动走 PR」，但 GitHub 默认仍允许仓库管理员直接推送到 `main`。需要你在网页上打开保护。这一步不能由提交进仓库的文件代劳。

这个仓库目前是 **公开** 的。公开仓库在 GitHub Free 上可以启用下面的规则。如果以后把仓库改成私有，Free 个人账号不会强制执行这些保护，需要 GitHub Pro（或把仓库放到有 Team 计划的组织里）才会生效。改成私有之前先想清楚这一点。

保护打开之后，你自己也要走 PR。这是刻意的：避免手滑直接推到 `main`。

不要把「必须有 1 个批准审查」打开。你是唯一的审查者时，GitHub 不允许作者批准自己的 PR，人数要求会让你无法合并。挡住直接推送，靠的是「必须通过拉取请求」，不是靠批准人数。

等本仓库第一次 CI 在 `main` 上跑过之后，状态检查的名字才会稳定出现在列表里。合并脚手架 PR 之前，可以先看那个 PR 的检查是否全绿；合并之后再回来把检查设成必需。

## 推荐做法：规则集

1. 打开 <https://github.com/XYN159/The-Last-Survivor/settings/rules>。
2. 点 **New ruleset**，再点 **New branch ruleset**。
3. **Ruleset Name** 填 `Protect main`。
4. **Enforcement status** 选 **Active**。
5. **Bypass list** 留空。不要把自己加进绕过名单，否则直接推送仍然可行。
6. 在 **Target branches** 里点 **Add target**，选 **Include default branch**。默认分支就是 `main`。也可以再加一条 **Include by pattern**，模式填 `main`。
7. 打开这些规则：
   - **Restrict deletions**（禁止删除被保护的分支）
   - **Block force pushes**（禁止强推；规则集里它经常默认就是开的，确认它是开的）
   - **Require a pull request before merging**
     - Required approvals 填 **0**
     - 不要勾选要求代码所有者批准，除非你确定不会因此把自己卡住
   - **Require status checks to pass**
     - 搜索并添加 `lint`、`test`、`export-android`
     - 如果列表里显示的是 `CI / lint` 这种带工作流前缀的名字，就选带前缀的那一项，不要自造一个名字
     - 勾选 **Require branches to be up to date before merging**，这样 `main` 有新提交时，旧 PR 会先更新再合并
8. 点 **Create** 保存。

保存后做一次确认：在本地对 `main` 做一个空提交并推送，GitHub 应该拒绝。然后确认一个 CI 已通过的 PR 仍然可以合并。

## 另一条路：经典分支保护规则

如果设置页里你更熟悉 **Branches** 而不是 Rulesets，可以用经典规则，效果对齐：

1. 打开 <https://github.com/XYN159/The-Last-Survivor/settings/branches>。
2. 点 **Add branch ruleset** 或 **Add classic branch protection rule**。走经典规则时：
3. **Branch name pattern** 填 `main`。
4. 勾选 **Require a pull request before merging**。Required approvals 设为 **0**。
5. 勾选 **Require status checks to pass before merging**。
6. 勾选 **Require branches to be up to date before merging**。
7. 在搜索框里加入 `lint`、`test`、`export-android`（或带 `CI /` 前缀的实际名字）。
8. 勾选 **Do not allow bypassing the above settings**，这样管理员也不能直接推。
9. 不要勾选 **Allow force pushes**。
10. 不要勾选 **Allow deletions**。
11. 保存。

两条路开一条即可，不要配出互相打架的两套规则。优先用规则集。

## 规则挡住你自己的时候

- 推送到 `main` 被拒绝：改到 `feature/`、`fix/`、`chore/` 或 `docs/` 分支，再开 PR。
- PR 无法合并，因为检查还是旧的：按 `CONTRIBUTING.md` 把 `main` 合进你的分支，等 CI 重跑。
- 检查名字对不上：打开一次成功的 Actions 运行，看每个作业左侧显示的准确名字，再填回规则里。
