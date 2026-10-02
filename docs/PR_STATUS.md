# 拉取请求状态

给制作人看的合并清单。这里只记录状态，不代替各 PR 里的设计正文。

最近整理：2026-10-02。基准是 `main` 的 `61e80d5`（首页已改成《东方守幻录》）。

这一轮没有合并、没有关闭任何 PR，没有删除分支，也没有推送到 `main`。

## 推荐合并顺序

设计文档先于依赖它的内容。数值表先于关卡表。先修导出脚本，是因为除了那一个 PR，其余开着的 PR 打包检查都是红的，原因相同。

1. **PR #7** 安卓导出脚本。不改玩法。合上之后，`main` 才能打出调试 APK，后面的 PR 再跟上 `main` 时，打包检查才会变绿。
2. **PR #9** 测试计划。只新增 `docs/qa/`，不和别人抢文件。合设计稿之前先看它的 `DESIGN_ISSUES.md`，里面记下了各稿互相矛盾的地方。
3. **PR #3** 玩法总纲。后面的战斗、关卡、数值都按这里的规则写。
4. **PR #2** 叙事和用词。文件不和别人重叠，但战斗、关卡里的名字要跟着它。
5. **PR #6** 美术规范。文件基本独立。若和 #3 的更新日志撞在一起，两边的条目都留下。
6. **PR #4** 战斗规则和占位配置表。数值 PR 写明要先合这个。
7. **PR #8** 数值表。先于关卡表。和 #4 冲突时，`data/balance/combat/stats.json` 以 #8 为准（#8 的描述里约定了）。和 #5 冲突时，`data/balance/level_difficulty.json` 以 #8 为准（两边的描述都这么写）。第一章首领入场仍待拍板，最好先定再合，否则这两张表还要再改。
8. **PR #5** 关卡表。放在数值表后面。它和 #3 都会改 `docs/GDD.md`：#3 是整份总纲重写，#5 是在更早的总纲上补关卡句子。合并时不要用 #5 的总纲覆盖 #3。

本页所在的整理 PR 只改这份清单和更新日志，可以随时合，不插入上面的顺序。

## 开着的 PR

| PR | 一句话 | 状态 | 更新日志 | CI |
| --- | --- | --- | --- | --- |
| [#7](https://github.com/XYN159/Touhou-forgotten-defense/pull/7) | 补上调试 APK 路径少写的 `}`，并让 lint 检查 shell 语法。 | CI/工程，待审核。已在最新 `main` 上。 | 已更新 | `lint`、`test`、`export-android` 都通过 |
| [#9](https://github.com/XYN159/Touhou-forgotten-defense/pull/9) | 写测试计划、MVP 验收和关卡模拟方案，并列出设计稿之间对不上的地方。草稿。 | 测试，待审核。已在最新 `main` 上。 | 按描述故意未改 | `export-android` 失败，另外两项通过 |
| [#3](https://github.com/XYN159/Touhou-forgotten-defense/pull/3) | 把总纲和路线图改成竖屏塔防，并记下已经拍板的规则。 | 设计文档，待审核。已合入最新 `main`。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#2](https://github.com/XYN159/Touhou-forgotten-defense/pull/2) | 叙事初稿、角色加入时机和中文文本表。 | 设计文档，待拍板。已合入最新 `main`，无冲突。 | 未改，描述里还在问要不要补一行 | `export-android` 失败，另外两项通过 |
| [#6](https://github.com/XYN159/Touhou-forgotten-defense/pull/6) | 美术规范、界面和 MVP 资源清单。框架已确认，文内仍有待确认项。 | 设计文档，待审核。已在最新 `main` 上。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#4](https://github.com/XYN159/Touhou-forgotten-defense/pull/4) | 战斗规则草案和 `data/balance/combat/` 配置表。游戏还不会读这些表。 | 设计文档，待拍板。已合入最新 `main`。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#8](https://github.com/XYN159/Touhou-forgotten-defense/pull/8) | 数值文档、配置表和关卡模拟。草稿。 | 设计文档，待拍板。已在最新 `main` 上。 | 未改，描述里写了要后续补 | `export-android` 失败，另外两项通过 |
| [#5](https://github.com/XYN159/Touhou-forgotten-defense/pull/5) | 24 关框架和 MVP 七关编组，并带关卡数据测试。 | 设计文档、测试，待拍板。已合入最新 `main`，无冲突。 | 已更新 | `export-android` 失败，另外两项通过 |

描述里的旧仓库名 `The-Last-Survivor` 只出现在 PR #4，已经改成 `Touhou-forgotten-defense`。其余描述没有这个旧链接。

### 打包检查为什么是红的

除 PR #7 外，上面每个 PR 的 `export-android` 都失败在同一处：`ci/export_android_debug.sh` 第 7 行默认路径少了一个 `}`，bash 报 `unexpected EOF while looking for matching '`'`。这是 `main` 上改名时留下的，不是这些设计稿自己弄坏的。PR #7 已经修好，并且自己的 CI 是绿的。

### 和 main 的冲突这一轮怎么处理的

PR #2、#5 和 `main` 没有冲突，已经直接合入。

PR #3、#4 有冲突，只动了说明文字，没有改玩法规则和战斗数值：

- 更新日志两边都保留。
- PR #3 的首页用 `main` 上已经改名的版本，文档索引仍指向这一份总纲和 24 关路线图。「多人与服务器」仍写成已作废。
- PR #4 的首页保留战斗文档链接。数值说明两边都留：怎么读取，以及旧占位不要当成新玩法定案。

没有留下还没解决的、挡在 `main` 外面的冲突。标签「有冲突」已建好，这一轮没有 PR 需要贴它。

### 还要你拍板、这一轮没有代你选的

这些选择会改设计含义，所以没有写进文件：

- PR #5 和 #8：第一章首领仍是第 5 波入场。两边都说按现行规则打不过，改不改要你定。
- PR #4：雪符「钻石风暴」、被冻住能不能连点破冰、新联动和强化、局内资源正式名字、大妖精 / 蕾米莉亚 / 文能不能玩。
- PR #2：局外资源叫什么、大妖精 / 蕾米莉亚 / 文能不能玩、若干敌人正式名，以及要不要补一行更新日志。
- PR #8 和 #4 的 `stats.json`、PR #8 和 #5 的 `level_difficulty.json` 还没有互相合并。顺序和以谁为准见上面第 7、8 步。现在不要把其中一份覆盖到另一条分支上。

## 已合并或已关闭的 PR 留下的远程分支

不要删除。这一轮只列出来。

| 分支 | 来源 | 说明 |
| --- | --- | --- |
| `chore/project-scaffold` | 已合并的 [PR #1](https://github.com/XYN159/Touhou-forgotten-defense/pull/1) | 没有 `main` 上所没有的提交。 |

另外，远程还有 `cursor/rename-touhou-td-d401`。它和 `main` 指向同一个提交，没有找到对应的已关闭 PR，所以不算上面这一类。也没有删除。

## 标签

仓库里现在有这些整理用标签：设计文档、开发、CI/工程、测试、待审核、有冲突、待拍板。

「开发」和「有冲突」这一轮没有贴到 PR 上。没有开着的 PR 是在做游戏功能；和 `main` 的冲突已经处理完。
