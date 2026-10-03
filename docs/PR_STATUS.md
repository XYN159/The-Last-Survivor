# 拉取请求状态

给制作人看的合并清单。这里只记录状态，不代替各 PR 里的设计正文。

最近整理：2026-10-02 第五轮。基准仍是 `main` 的 `61e80d5`（首页已改成《东方守幻录》）。这一轮 `main` 没有新提交。今天写入的是 #11、#12、#14。

这一轮没有合并、没有关闭任何 PR，没有点 Approve，没有删除分支，也没有推送到 `main`。合并仍然只有用户能点。不要自动合并。

## 推荐合并顺序

设计文档先于依赖它的开发。数值表先于关卡表。先修导出脚本，是因为除了那一个 PR，其余开着的 PR 打包检查都是红的，原因相同。

顺序仍按 **PR #11**：先合数值。表的内容以 #8 为准。#4 已经去掉自己的 `stats.json`，#5 已经不再自带难度表，所以同名文件冲突少了。不要把别处的表覆盖回 #8。

**PR #10**、**#11**、**#13** 只新增文档，可以随时合，不插入下面的顺序。#13 自己写了要在 #11 之后或同时合。建议先读 #11 的计划，再读 #13 的角色手册。

1. **PR #7** 安卓导出脚本。不改玩法。合上之后，`main` 才能打出调试 APK，后面的 PR 再跟上 `main` 时，打包检查才会变绿。
2. **PR #3** 玩法总纲。后面的战斗、关卡、数值都按这里的规则写。
3. **PR #8** 数值表。先于战斗表和关卡表。`stats.json` 和 `level_difficulty.json` 都以这份为准。它现在是草稿，计划要求先转成可审再合。第一章首领入场仍待拍板，最好先定再合。
4. **PR #4** 战斗规则。它自己已经从 diff 里去掉 `stats.json`，改成指向 #8。这一轮没有再改它的文件。正式数值仍先合 #8。
5. **PR #5** 关卡表。放在数值表后面。它自己已经不再改 `docs/GDD.md` 和 `data/balance/level_difficulty.json`，难度表仍以 #8 为准。校验器要读 #8 的值，所以不要先于 #8。
6. **PR #2** 叙事和用词。文件不和别人重叠。放置方式这一轮已经写成先点格子再点头像。第二到四章首领身份仍待定，#2 自己写了不卡住合并。
7. **PR #6** 美术规范。引用战斗和关卡的 ID，放在它们后面。若更新日志和别人撞在一起，两边的条目都留下。
8. **PR #12** 能玩的塔防原型。仍是草稿，结论仍是需要返工，不要合并。返工清单在 https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5946132812 。执行时没有进入原原型 agent https://cursor.com/agents/bc-062dec78-83a7-5a85-9366-e6690ee5d174 ，而是新开了 https://cursor.com/agents/bc-d0f2930b-36eb-543e-b3a6-be672f2e2b60 。提示词要求它改原来的 PR #12，不要新开 PR。放在它依赖的设计文档后面。数值在 `data/prototype/`，不要拿它覆盖 #8 的正式表。它会改 `CHANGELOG.md` 和 `docs/ARCHITECTURE.md`，和前面的设计 PR 撞在一起时，更新日志两边都留。
9. **PR #9** 测试计划。放在最后。合之前把已经对上的问题标成已解决，验收清单才跟得上最终文档。合设计稿之前仍可以先读它的 `DESIGN_ISSUES.md`。

**PR #14** 角色概念图。head `01fe51c`。四人都选 v2，总览中文已重画。执行制作人汇总是可以合并，等用户合并。放在 #6 后面即可，不挡住 #12。图在 `docs/design/art/concepts/`，不进游戏。不要自动合并。汇总评论：https://github.com/XYN159/Touhou-forgotten-defense/pull/14#issuecomment-5946166173

## 开着的 PR

| PR | 一句话 | 状态 | 更新日志 | CI |
| --- | --- | --- | --- | --- |
| [#14](https://github.com/XYN159/Touhou-forgotten-defense/pull/14) | head `01fe51c`。四人都选 v2，总览中文已重画。执行制作人汇总是可以合并，等用户合并。不接入游戏。汇总评论：https://github.com/XYN159/Touhou-forgotten-defense/pull/14#issuecomment-5946166173 | 可以合并，等用户点。不要自动合并。标签仍是设计文档、待拍板。已在最新 `main` 上，无冲突。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#13](https://github.com/XYN159/Touhou-forgotten-defense/pull/13) | 8 个角色的工作手册。这一轮补了角色图的硬性验收。 | CI/工程，待审核。已在最新 `main` 上，无冲突。 | 未改 | `export-android` 失败，另外两项通过 |
| [#12](https://github.com/XYN159/Touhou-forgotten-defense/pull/12) | 仍是草稿，结论仍是需要返工，不要合并。返工清单在 https://github.com/XYN159/Touhou-forgotten-defense/pull/12#issuecomment-5946132812 。执行时没有进入原原型 agent https://cursor.com/agents/bc-062dec78-83a7-5a85-9366-e6690ee5d174 ，而是新开了 https://cursor.com/agents/bc-d0f2930b-36eb-543e-b3a6-be672f2e2b60 。提示词要求它改原来的 PR #12，不要新开 PR。 | 开发、测试，待审核。草稿，需要返工。不要合并。已在最新 `main` 上，无冲突。 | 已更新 | `export-android` 失败，`lint` 和 `test` 通过 |
| [#11](https://github.com/XYN159/Touhou-forgotten-defense/pull/11) | MVP 开发计划和待拍板清单。分支 `docs/production-plan` 的最新提交 `017d708` 里有执行制作人交接 `HANDOFF.md`。 | 设计文档，待拍板。已在最新 `main` 上，无冲突。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#10](https://github.com/XYN159/Touhou-forgotten-defense/pull/10) | 维护本页：开着的 PR、状态和推荐合并顺序。草稿。 | CI/工程，待审核。从最新 `main` 拉出。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#7](https://github.com/XYN159/Touhou-forgotten-defense/pull/7) | 补上调试 APK 路径少写的 `}`，并让 lint 检查 shell 语法。 | CI/工程，待审核。已在最新 `main` 上。 | 已更新 | `lint`、`test`、`export-android` 都通过 |
| [#9](https://github.com/XYN159/Touhou-forgotten-defense/pull/9) | 写测试计划、MVP 验收和关卡模拟方案，并列出设计稿之间对不上的地方。草稿。 | 测试，待审核。已在最新 `main` 上。 | 按描述故意未改 | `export-android` 失败，另外两项通过 |
| [#3](https://github.com/XYN159/Touhou-forgotten-defense/pull/3) | 把总纲和路线图改成竖屏塔防。这一轮又写了共用符卡条，并锁了序章波数。 | 设计文档，待审核。已在最新 `main` 上。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#2](https://github.com/XYN159/Touhou-forgotten-defense/pull/2) | 叙事初稿和中文文本表。放置已写成先点格子再点头像，并确认了残影 ID。 | 设计文档，待拍板。已在最新 `main` 上。 | 仍未改 | `export-android` 失败，另外两项通过 |
| [#6](https://github.com/XYN159/Touhou-forgotten-defense/pull/6) | 美术规范、MVP 资源清单，以及这一轮补上的音频清单和已定事项。 | 设计文档，待审核。已在最新 `main` 上。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#4](https://github.com/XYN159/Touhou-forgotten-defense/pull/4) | 战斗规则草案。这一轮去掉了自己的 `stats.json`，数字改指向 #8。 | 设计文档，待拍板。已在最新 `main` 上。 | 已更新 | `export-android` 失败，另外两项通过 |
| [#8](https://github.com/XYN159/Touhou-forgotten-defense/pull/8) | 数值文档、配置表和关卡模拟。草稿。 | 设计文档，待拍板。已在最新 `main` 上。 | 未改，描述里写了要后续补 | `export-android` 失败，另外两项通过 |
| [#5](https://github.com/XYN159/Touhou-forgotten-defense/pull/5) | 24 关框架和 MVP 七关编组。这一轮不再改总纲和难度表，校验器改读 #8。 | 设计文档、测试，待拍板。已在最新 `main` 上。 | 已更新 | `export-android` 失败，另外两项通过 |

描述里没有还指向旧仓库名 `The-Last-Survivor` 的链接。#14 也没有。

#11 最新提交 `017d708` 里有执行制作人交接 `docs/production/HANDOFF.md`。状态页这一轮没有改计划正文。

### 打包检查为什么是红的

除 PR #7 外，上面每个 PR 的 `export-android` 都失败在同一处：`ci/export_android_debug.sh` 第 7 行默认路径少了一个 `}`，bash 报 `unexpected EOF while looking for matching '`'`。这是 `main` 上改名时留下的，不是这些设计稿自己弄坏的。PR #7 已经修好，并且自己的 CI 是绿的。

### 和 main 的冲突

这一轮 `main` 没动。#2 到 #14 都已经包含它，没有新的冲突要解。#14 没有冲突，可以合并，等用户点。不要自动合并。

上一轮 PR #2、#5 无冲突，已合入。PR #3、#4 的冲突只动了说明文字，没有改玩法规则和战斗数值：

- 更新日志两边都保留。
- PR #3 的首页用 `main` 上已经改名的版本，文档索引仍指向这一份总纲和 24 关路线图。「多人与服务器」仍写成已作废。
- PR #4 的首页保留战斗文档链接。数值说明两边都留：怎么读取，以及旧占位不要当成新玩法定案。

没有留下还没解决的、挡在 `main` 外面的冲突。标签「有冲突」已建好，这一轮没有 PR 需要贴它。

D-01 已定：Boss 第 11 波登场，血量不加成。

### 还要你拍板、这一轮没有代你选的

这些选择会改设计含义，所以没有写进文件。完整编号在 PR #11 的 `DECISIONS_PENDING.md`（D-01 到 D-17）。这里只记会挡住合并顺序的几条：

- PR #4：雪符「钻石风暴」、被冻住能不能连点破冰、新联动和强化、局内资源正式名字、大妖精 / 蕾米莉亚 / 文能不能玩。
- PR #2：局外资源叫什么、大妖精 / 蕾米莉亚 / 文能不能玩、若干敌人正式名，以及要不要补一行更新日志。放置方式已经写成先点格子再点头像。第二到四章首领仍待定，不挡住这份稿合并。
- 正式数值表仍只在 #8。#4 已经去掉自己的 `stats.json`，#5 已经不再带 `level_difficulty.json`。先合 #8，不要把别处的表覆盖回去。
- PR #14：四人都选 v2，总览中文已重画。执行制作人汇总是可以合并，等用户合并。不要自动合并。这一轮没有代你点合并。

## 已合并或已关闭的 PR 留下的远程分支

不要删除。这一轮只列出来。

| 分支 | 来源 | 说明 |
| --- | --- | --- |
| `chore/project-scaffold` | 已合并的 [PR #1](https://github.com/XYN159/Touhou-forgotten-defense/pull/1) | 没有 `main` 上所没有的提交。 |

另外，远程还有 `cursor/rename-touhou-td-d401`。它和 `main` 指向同一个提交，没有找到对应的已关闭 PR，所以不算上面这一类。也没有删除。

## 标签

仓库里现在有这些整理用标签：设计文档、开发、CI/工程、测试、待审核、有冲突、待拍板。

「有冲突」这一轮没有贴。和 `main` 的冲突已经处理完。PR #12 仍贴着「开发」，它是目前唯一在做游戏功能的 PR，结论是需要返工。PR #14 的标签仍是「设计文档」和「待拍板」：这一轮没能改掉，当前身份不能改别人 PR 的标签。看上面的文字，四人都选了 v2，可以合并，等用户点，不是再挑一版。
