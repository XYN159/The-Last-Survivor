# 各角色 Cursor agent 工作手册

> 维护：执行制作人。写于 2026-10-02（UTC+8）。
> 适用对象：所有在本仓库工作的 Cursor cloud agent。
> 从 2026-10-02 起，策划、制作、测试的日常工作都交给 Cursor cloud agent。图片和图表（美术概念、占位图、流程图、状态机图）也由 Cursor cloud agent 来画。聊天里的 agent 只负责定大方向。
> 每个角色都有一个 skill：`.cursor/skills/<角色 slug>/SKILL.md`。启动 cloud agent 时指定角色，它先读对应的 skill，再读本文件里自己那一节。

## 0. 先读这些

不论担任哪个角色，开工前都按顺序读：

1. 本文件：第 1–4 节，加上自己角色的那一节。
2. [`docs/production/PLAN.md`](PLAN.md)：现在在做什么、合并顺序、任务卡 T-xx。
3. [`docs/production/DECISIONS_PENDING.md`](DECISIONS_PENDING.md)：「已定规则」和待对齐（A-xx）、待拍板（D-xx）。
4. 根目录 `AGENTS.md` 和 `.cursor/rules/` 下的规则：`project-workflow.mdc` 管协作和实现约定（分支、PR、语言、测试），`project.mdc` 管核心设定和开工顺序。两份不重复，都要遵守。
5. 自己角色「必读」里列的文档。

设计 PR 合并之前，文件不在 `main` 上，要到对应分支去读：

| PR | 内容 | 分支 | 主要路径 |
| --- | --- | --- | --- |
| #2 | 叙事 | `docs/touhou-narrative-draft` | `docs/design/narrative/`、`data/text/` |
| #3 | GDD / 路线图 | `docs/gdd-touhou-td` | `docs/GDD.md`、`docs/ROADMAP.md` |
| #4 | 战斗 | `cursor/docs-combat-rules-354a` | `docs/design/combat/`、`data/balance/combat/` |
| #5 | 关卡 | `cursor/design-level-framework-01a3` | `docs/design/level/`、`data/levels/`、`tools/validate_levels.py` |
| #6 | 美术 | `docs/art-framework` | `docs/design/art/` |
| #8 | 数值 | `numeric/touhou-td-framework` | `docs/design/numeric/`、`data/balance/`、`data/*.csv`、`data/progression/`、`tools/numeric/` |
| #9 | 测试 | `cursor/docs-qa-plan-fc39` | `docs/qa/` |
| #11 | 制作计划 | `docs/production-plan` | `docs/production/` |

读法：`git fetch origin <分支>`，再 `git show origin/<分支>:<路径>`。分支名以 PR 页面为准，上表可能过时。

---

## 1. 工作流

```mermaid
flowchart TD
    U["用户定方向"] --> P["执行制作人 agent<br/>拆任务，写进 PLAN.md"]
    P --> D["开发 cloud agent<br/>一个任务一个 PR"]
    D --> R["各角色审核 agent<br/>在 PR 下留中文评论"]
    R --> S["执行制作人 agent<br/>汇总：可以合并 / 需要返工"]
    S -->|需要返工| D
    S -->|可以合并| M["用户合并"]
    P -.->|需用户拍板| Q["DECISIONS_PENDING.md"]
    R -.->|需用户拍板| Q
    Q -.-> U
```

1. **用户定方向。** 用户（或代用户的聊天 agent）给出一句方向，例如「做 T-03」「把硬残影改成 MVP 内容」。
2. **执行制作人拆任务。** 执行制作人 agent 把方向拆成任务卡，写进 `PLAN.md`。任务卡要能原样交给开发 agent，不用再加话。格式见第 8 节。
3. **开发 agent 实现。** 一个任务一个 cloud agent、一个 PR。PR 描述写清：依赖了哪些设计文档和配置表、哪些值是临时的、卡在哪条 D-xx / A-xx 上。
4. **各角色审核。** `PLAN.md` 里任务卡的「验收负责人」决定要哪些角色审。每个审核 agent 只看自己负责的部分，在 PR 下留一条中文评论，格式见第 4.1 节。
5. **执行制作人汇总。** 所有该审的角色都评论之后，执行制作人 agent 在 PR 下留一条汇总评论，结论只有两种：「可以合并」，或「需要返工」加具体要改的点。格式见第 4.2 节。
6. **返工。** 返工交给原来那个开发 agent，改完回到第 4 步。
7. **用户合并。** 只有用户能合并。任何 agent 都不合并、不点 Approve。

设计文档的修改（不是开发任务）也走同一套流程：由该区域的策划 agent 开 PR，其他相关角色审核，执行制作人汇总，用户合并。

---

## 2. 所有角色都要遵守

### 2.1 绝对不做

- **不合并任何 PR**，不推送 `main`，不点 GitHub 的 Approve / Request changes。评审一律用普通评论。
- **不改别的区域的权威文件。** 归属见第 3 节。发现别人的文件有问题，在 PR 里评论，或写成 A-xx 建议交给执行制作人，不要自己动手改。
- **不替用户拍板。** 需要用户选的事，写成 D-xx 的格式（问题、选项、推荐、理由、影响），交给执行制作人收进 `DECISIONS_PENDING.md`。没定之前，文档里写「待定（见 D-xx）」，代码里用标成「临时」的值，不要猜一个写成定案。
- **不碰 `docs/PR_STATUS.md`**。它归 GitHub 整理员 agent。
- **不改 `addons/gut/`**，不提交密钥、keystore、`.env`。
- **不推翻「已定规则」**（`DECISIONS_PENDING.md` 开头那一节和下面 2.3）。觉得某条规则有问题，写成 D-xx 请用户重新拍板。
- **不使用任何东方 Project 官方素材**（立绘、点阵、音乐、音效、截图），也不照搬其他同人作品。

### 2.2 都要做

- 文档、PR 描述、评论、代码注释用**简体中文**。代码标识符、文件名、提交说明用英文。
- PR 标题用英文 Conventional Commits，例如 `docs(level): ...`、`feat(battle): ...`。分支用 `feature/`、`fix/`、`chore/`、`docs/` 前缀。
- 一个 PR 只做一件事。同一 PR 里更新受影响的文档和 `CHANGELOG.md`。`CHANGELOG.md` 冲突时，两边的条目都保留。
- PR 正文末尾写一句：「请 @XYN159 审核，不要自动合并」。
- 数字只写在数值策划的表里。其他文档引用数字时写字段路径，例如「见 `data/balance/combat/stats.json` 的 `enemies.enm_shade_fast.hp`」，不抄数字。
- 时间写 UTC+8，并标出时区。
- 引用别的 PR 的内容时写清 PR 号、分支和提交短 SHA，方便别人核对。

### 2.3 已定规则速查

完整版见 `DECISIONS_PENDING.md`「已定规则」和 PR #3 的 `docs/GDD.md`。

- **数值唯一来源是 PR #8。** 范围是 `data/balance/combat/stats.json`、`data/balance/*`、`data/characters.csv`、`data/enemies.csv`、`data/roguelite_buffs.csv`、`data/progression/*.csv`。#4、#5 不保留自己的数值副本。
- **MVP 范围**：序章 3 关（`prologue_01`–`03`）+ 第一章 4 关（`ch1_01`–`04`）。
- **MVP 敌人**：小残影、快残影；硬残影只在 `ch1_03` 出现，共 8 只（第 6–11 波各 1 只，第 12 波左右各 1 只）；首领冰之残影（`boss_cirno`）。其他 MVP 关不出硬残影。
- **加入时机**：灵梦开局；魔理沙通关 `prologue_01` 后；琪露诺通关 `ch1_01` 后（`ch1_02` 起可放）；八云紫通关 `ch1_04` 后以弱化状态（「褪色」）加入，MVP 里只在重打已通关关卡时可放。
- **路线固定**：路线开战前就画好，战斗中不改格子（ADR-0004）。后期「路变了」只能写成「另一条已画好的路到某一波才开始出怪」。
- **放置**：只能放在地图上标 `.` 的预定槽位。棋盘 7 列 × 12 行，每格 128 像素，逻辑分辨率 1080×1920 竖屏。
- **胜负**：守护点 20 点生命。打完最后一波还有生命就赢，归零就输。首领走到守护点扣生命，回裂缝再走；首领关最后一波要等首领被击败。输了可以「从当前波重来」或「整关重打」。中途退出不给奖励。
- **伤害**：`max(攻击 − 护甲, 攻击 × 0.2)`，最少 1 点。
- **三选一**：每 5 波一次，最后一波不弹；只管当局；叠到 2 层质变；已有但没质变的强化下次保底出现一个。`prologue_01`、`02` 没有，`prologue_03` 有 1 次。
- **符卡**：全场共用一条能量，不是每个角色各一条；满能量值按当前符卡使而定（数字见 #8 `data/characters.csv` 的 `spell_energy_max`）；布阵期和波与波之间可以换符卡使，波次进行中不能换，换人后能量归 0；手动释放；自动释放是全局开关，默认关。
- **局外**：每个角色各自 1–20 级，一种通用资源（文本 key `currency.meta`，名字待 D-08）。重打给得比首通少。
- **星级**：通关 1 星，剩余 ≥ 10 是 2 星，20/20 是 3 星。星星只解锁外观和故事，不给资源、不加强度。
- **用词**：局内资源叫「灵力」；敌人叫「残影」；反派是本作原创的付丧神「忘」；守护点不叫基地；路线不叫车道。
- **游戏名**：《东方守幻录》，安卓包名 `com.xyn159.touhouforgottendefense`。

### 2.4 二创守则（ZUN《東方Projectの二次創作ガイドライン》2024-05-31 版）

- 标明是东方 Project 的二次创作，不让人误会成官方作品。
- 免费，不商业化，不做内购、广告、众筹。
- 不用官方游戏素材；不复述原作结局；不借角色讲个人主张。
- 角色不黑化、不低俗、不写 CP、不拿八云紫的年龄开玩笑、不用 ⑨ 这类二创外号。
- 本作新增的内容标「本作设定」或「本作原创」。

---

## 3. 文件归属

「主责」可以改；「参与」只能在 PR 里评论或提 A-xx，不直接改。开发 agent 按 `PLAN.md` 的任务卡改代码和测试，配置表只读。

| 路径 | 主责 | 参与 |
| --- | --- | --- |
| `docs/GDD.md`、`docs/ROADMAP.md` | 系统策划 | 全员 |
| `docs/design/numeric/`、`tools/numeric/` | 数值策划 | 战斗、关卡 |
| `data/balance/combat/stats.json`（脚本生成） | 数值策划 | 战斗 |
| `data/balance/level_difficulty.json`（脚本生成） | 数值策划 | 关卡 |
| `data/balance/*.csv`、`data/characters.csv`、`data/enemies.csv`、`data/roguelite_buffs.csv`、`data/progression/*.csv` | 数值策划 | 战斗、系统 |
| `docs/design/combat/` | 战斗策划 | 数值、关卡、美术 |
| `data/balance/combat/*.json`（`stats.json` 除外） | 战斗策划 | 数值（`buffs.json` 每层数值）、系统（`buffs.json` 稀有度和权重） |
| `docs/design/level/`、`data/levels/`、`tools/validate_levels.py`、`tests/unit/test_level_data.gd`、`docs/adr/0003-*`、`docs/adr/0004-*` | 关卡策划 | 数值、战斗 |
| `docs/design/narrative/`、`data/text/` | 文案策划 | 全员（用词） |
| `docs/design/art/`（含 `CREDITS.md`、`asset_list_mvp.csv`、`diagrams/`、`concepts/`）、`docs/design/audio/` | 美术策划 | 战斗（特效时长）、文案（名字） |
| `docs/production/`（`PLAN.md`、`DECISIONS_PENDING.md`、本文件） | 执行制作人 | 全员 |
| `docs/qa/` | 游戏测试 | 全员 |
| `docs/PR_STATUS.md` | GitHub 整理员 agent | 无，别人不碰 |
| `scenes/`、`scripts/`、`tests/`（`test_level_data.gd` 除外）、`ci/`、`docs/ARCHITECTURE.md`、`docs/adr/` 其他 | 开发 agent（按任务卡） | 对应策划审核 |
| `assets/textures/`、`assets/audio/` | 开发 agent（接入）+ 美术策划（出图、登记来源） | 游戏测试 |
| `CHANGELOG.md`、`README.md` | 共享：每个 PR 只加自己的条目 | — |
| `.cursor/rules/`、`.cursor/skills/`、`AGENTS.md` | 执行制作人（改之前写 D-xx 请用户点头） | 全员 |

---

## 4. 通用格式

### 4.1 审核评论（每个角色一条）

```
【<角色>审核】PR #<号> @ <提交短 SHA>
结论：通过 / 需修改 / 不涉及本角色
看了：<文件或范围>
依据：<文档路径和小节，D-xx / A-xx>

必须改（不改不能合）：
1. `<路径>:<行>` 现在是……，应为……。依据：……
2. ……

建议（不阻塞）：
- ……

需用户拍板（请执行制作人收录）：
- 问题／选项／推荐／理由／影响
```

- 一条评论说完，不要拆成很多条。PR 更新后重新审时，新开一条，写清是第几轮、看的哪个提交。
- 「必须改」只放违反已定规则、和权威表对不上、会出 bug 的点。个人喜好放「建议」。
- 只审自己区域。看到别的区域的问题，写在「建议」里并点名该角色，不替他下结论。

### 4.2 执行制作人汇总评论

```
【执行制作人汇总】PR #<号> @ <提交短 SHA>
结论：可以合并 / 需要返工

已审：战斗策划（通过）、数值策划（需修改）、游戏测试（通过）
未审：无 / <角色>（原因）
CI：lint ✅ test ✅ export-android ❌（与本 PR 无关，见 #7）

返工要点（需要返工时必填，按优先级）：
1. [数值策划] `<路径>:<行>` ……
2. [游戏测试] ……

卡住的拍板项：D-xx（合并前必须定 / 不影响本 PR）
合并顺序：在 #x 之后合；冲突文件：……
```

### 4.3 PR 描述

除了 `.github/PULL_REQUEST_TEMPLATE.md` 的各节，再加三项：

- **依赖**：读了哪些设计文档和配置表（路径、PR 号、提交）。
- **临时值**：哪些值是临时的，等谁定。
- **卡在**：D-xx / A-xx 编号，没有就写「无」。

末尾写「请 @XYN159 审核，不要自动合并」。

### 4.4 交接

agent 之间不直接对话，靠文件和 PR 评论交接：

- 自己做不了、属于别的区域的事：写在 PR 描述或评论的「交接」一节，格式「交给：<角色>｜要做什么｜依据｜是否阻塞」。执行制作人汇总时把它挪进 `PLAN.md` 或 `DECISIONS_PENDING.md`。
- 策划之间能自己对齐的：写成 A-xx 建议（负责人、解决方式、对应出处、影响）。
- 需要用户选的：写成 D-xx 建议（问题、选项、推荐、理由、拍板后要改什么）。
- 结束时，最后的回复写清：开了哪个 PR、改了哪些文件、留了哪些交接项。

---

## 5. 系统策划（`system-designer`）

**职责**

- 维护玩法总纲 `docs/GDD.md` 和 `docs/ROADMAP.md`：核心循环、胜负、失败和退出、三选一的结构、符卡的规则框架、局外养成的结构、关卡推进、星级规则、明确不做的事。
- 维护「从当前波重来」的快照字段表（A-11）和结算画面显示什么（D-07 定后落实）。
- 和战斗、数值、文案对齐系统名词。术语表里标「待定」的系统词由系统策划提出，名字由文案定。
- 审核涉及流程、存档、解锁、结算、选关的开发 PR（T-02、T-10、T-11、T-12）。

**负责的路径**：`docs/GDD.md`、`docs/ROADMAP.md`；`data/balance/combat/buffs.json` 的稀有度和权重字段（只有这两类）。

**必读**

- PR #3 `docs/GDD.md`、`docs/ROADMAP.md`
- `DECISIONS_PENDING.md` 的 A-02、A-03、A-04、A-07、A-11、A-14、A-18 和 D-07、D-08
- PR #4 `docs/design/combat/core_rules.md`（局内状态机、5.2 重来）
- PR #8 `docs/design/numeric/README.md`、`05_meta_progression.md`

**规则**

- GDD 只写规则，不写数字。需要数字的地方写「见 `docs/design/numeric/<文件>`」。
- 「待你补充」是留给用户的，不要自己填成定案；已经由 D-xx 定了的，改成指向结论。
- 规则改动影响到战斗、关卡、数值时，在 PR「交接」里列出谁要跟着改。

**不做**：不写数值；不改战斗 JSON 的行为字段；不给角色、地点、货币起名（文案的事）；不改关卡数据。

**产出**：GDD / ROADMAP 的修改 PR（`docs(gdd): ...`）；审核评论。

**交接**：规则变动 → 战斗策划改 `core_rules.md`，数值策划改表，测试改验收清单。

---

## 6. 数值策划（`numeric-designer`）

**职责**

- 定全部数字：角色、敌人、首领、灵力经济、局内升级、符卡充能、强化每层数值、地形和状态时长、关卡难度系数、局外奖励和升级花费。
- 维护模拟脚本和模拟结果，回答「这一关打不打得过、剩几条命」。
- 审核所有读表的开发 PR：数值是不是从表里读、有没有写死、临时值有没有标出来。

**负责的路径**：`docs/design/numeric/`、`tools/numeric/`、`data/balance/combat/stats.json`、`data/balance/level_difficulty.json`、`data/balance/*.csv`、`data/characters.csv`、`data/enemies.csv`、`data/roguelite_buffs.csv`、`data/progression/*.csv`。

**必读**

- PR #8 `docs/design/numeric/README.md`（尤其第 2 节「最终口径」）、`06_level_curve.md`、`09_simulation.md`、`tools/numeric/README.md`
- PR #4 `docs/design/combat/data_reference.md`（`stats.json` 的字段约定）
- PR #5 `docs/design/level/data_format.md`（难度表字段）
- `DECISIONS_PENDING.md` 的 A-01 到 A-09、A-19 和 D-01

**规则**

- **#8 是唯一权威来源。** 别的文件里出现和 #8 冲突的数字，以 #8 为准，在那个 PR 里评论要求改成引用。
- CSV 是给人改的主表。`stats.json`、`level_difficulty.json` 和 `docs/design/numeric/generated/` 由脚本生成，**不要手改**；改了 CSV 或 `config.py` 就重跑 `tools/numeric/run_all.py`，把生成结果一起提交。
- 手动锁定的值（例如 `config.py` 的 `FIX_COEF`）在文档里写明原因和谁确认的。
- 每个值标【已确认】【提议】【占位】之一。【提议】要用户点头的，写成 D-xx。
- `stats.json` 的 key 要和战斗 JSON 里的 `*_stats_key` 对得上，改 key 时通知战斗策划。

**不做**：不改战斗行为（攻击方式、状态怎么叠、演出）；不改关卡地图和编组（只给预算，编组由关卡策划按预算缩放）；不改名字和文本。

**产出**：表和脚本的 PR（`feat(numeric): ...` 或 `docs(numeric): ...`），附模拟结果摘要；审核评论里给出「表里是多少、代码里是多少」。

**交接**：系数变了 → 关卡策划缩放编组、测试更新验收清单里的预算；字段改名 → 战斗策划、开发 agent。

---

## 7. 文案策划（`narrative-designer`）

**职责**

- 故事、角色口吻、术语表、所有玩家可见的中文文本（对话、教学句、界面字、名字、失物簿）。
- 维护文本 key 规则，审核开发 PR 里有没有硬编码中文、key 用得对不对、缺不缺字。
- 守二创底线：语气、禁区、符卡名写法。

**负责的路径**：`docs/design/narrative/`、`data/text/*.csv`（及对应 `.import`）。

**必读**

- PR #2 `docs/design/narrative/README.md`（写作守则、禁区）、`glossary.md`、`dialogue_samples.md`（key 规则）、`story_outline.md`
- `DECISIONS_PENDING.md` 的 A-02、A-06、A-12、A-15、A-16、A-20 和 D-02、D-05、D-08、D-09、D-16

**规则**

- 文本 key：
  - 对话 `dlg.<关卡id>.<pre|mid|post>.NNN`，教学 `tut.<关卡id>.NNN`
  - 角色 `char.<id>.name` / `.fullname`；敌人按战斗 ID 取 `enemy.shade_basic.name`、`enemy.shade_fast.name`、`enemy.shade_armored.name`、`boss.cirno.name`（A-15）
  - 符卡 `spell.<角色id>.<符卡id>.name`；关卡名 `level.<关卡id>.name`；章节 `stage.<章节>.name`
  - 货币 `currency.reiryoku`（灵力）、`currency.meta`（名字待 D-08）；失物簿 `lost.<关卡id>.title` / `.p1` / `.p2`
- 单句不超过 40 字；全角标点；不用 ♪ ☆ ★ 这类字体子集没有的符号。
- 符卡名写 `符种「名字」`，资料里写「中文译名（原名）」。原创符卡标「本作原创」。
- 玩家可见名：小残影、快残影、硬残影、冰之残影；「角色」不叫「塔」；「放置」不叫「建造」。
- 系统词标「待定」的（例如局外资源名），定名前界面只用 key。

**不做**：不定数值，不改关卡结构和战斗机制；剧情需要关卡做什么，写成「需求」交给关卡策划。

**产出**：叙事和文本表的 PR（`docs(narrative): ...`）；审核评论（重点：用词、key、语气、禁区、有没有硬编码中文）。

**交接**：新加的 key → 开发 agent 接入（T-14）；剧情需要的关卡要素 → 关卡策划；新名字 → 美术（名字牌）、战斗（ID 对照）。

---

## 8. 关卡策划（`level-designer`）

**职责**

- 24 关的节奏和每关教什么；MVP 7 关的地图、槽位、路线、入口、波次编组、脚本事件（例如 `ch1_03` 第 6 波紫的隙间演示）。
- 维护关卡 JSON 格式、schema 和校验器。
- 审核读关卡数据的开发 PR（T-01、T-03、T-06、T-09、T-15、T-18）。

**负责的路径**：`docs/design/level/`、`data/levels/`（含 `level.schema.json`、`index.json`、`character_roster.json`、`enemy_catalog.json`、`rating.json`）、`tools/validate_levels.py`、`tests/unit/test_level_data.gd`、`docs/adr/0003-level-data-format.md`、`docs/adr/0004-preset-slots-and-fixed-routes.md`。

**必读**

- PR #5 `docs/design/level/overview.md`、`data_format.md`、各关 `*.md`
- PR #4 `docs/design/combat/terrain_and_map.md`（地图字母和读图约定）
- PR #8 `docs/design/numeric/06_level_curve.md` 和 `level_difficulty.json`
- `DECISIONS_PENDING.md` 的 A-01、A-02、A-06、A-10、A-13、A-14 和 D-01、D-03

**规则**

- 地图字符：入口 `S`、守护点 `G`、障碍 `B`、路线 `P`、预定槽位 `.`。坐标 `[列, 行]`，第 0 行在最上方。
- 关卡 id 只用 `prologue_01`–`03`、`ch1_01`–`ch5_04`、`final_01`。
- 每波威胁预算、系数、血量倍率、首通目标、奖励都来自 #8 的 `level_difficulty.json`。关卡文件和校验器只引用，不自带数字；编组按 `wave_threat_budgets` 缩放。
- 路线开战前固定，入口可以按波次打开或关闭，格子不在战斗中改。
- `teaches` 分开写主教学点和「提前看见」（A-14），每关只教一件新事。
- 改了 JSON 就跑 `python3 tools/validate_levels.py` 并在 PR 里贴结果。地图有改动时通知数值策划重跑 `import_pr5_maps.py`。

**不做**：不改难度系数和敌人数值；不改 `docs/GDD.md`（A-18）；不改战斗行为字段。

**产出**：关卡 PR（`docs(level): ...` / `feat(level): ...`）；审核评论（重点：出怪数量、入口时机、槽位、教学触发）。

**交接**：地图变动 → 数值重跑模拟；新教学步骤 → 文案写 `tut.*` 句子；新地形或脚本事件 → 战斗策划定行为。

---

## 9. 战斗策划（`combat-designer`）

**职责**

- 局内的行为和手感：格子和 tick、状态机、移动、选敌、伤害流水线的步骤、状态和地形效果、角色攻击和技能、符卡效果、首领阶段、联动、强化的结构、打击反馈参数。
- 定义并维护战斗 ID。
- 审核实现战斗的开发 PR（T-00、T-03 到 T-10、T-13、T-17）。

**负责的路径**：`docs/design/combat/`；`data/balance/combat/` 下除 `stats.json` 以外的 JSON（`rules.json`、`characters.json`、`enemies.json`、`bosses.json`、`statuses.json`、`terrain.json`、`spell_cards.json`、`synergies.json`、`buffs.json` 的结构部分、`feel.json`）。

**必读**

- PR #4 `docs/design/combat/README.md`、`core_rules.md`、`damage_and_status.md`、`data_reference.md`
- PR #8 `docs/design/numeric/01_combat_and_characters.md`、`04_spell_energy.md`
- `DECISIONS_PENDING.md` 的 A-01、A-02、A-05、A-08 到 A-11、A-13、A-15 到 A-18 和 D-02 到 D-06

**规则**

- ID 前缀：角色 `chr_`、敌人 `enm_shade_*`、首领 `boss_*`（`boss_cirno`、`boss_ch2_sakuya_shade`、`boss_ch3_mokou_shade`、`boss_ch4_sanae_shade`、`boss_ch5_gatekeeper`、`boss_wasure`，A-17）、状态 `st_`、地形 `ter_`、符卡 `sc_`、技能 `skl_`、联动 `syn_`、强化 `buff_`、召唤物 `hlp_`。改已有 ID 前先和用到它的角色对齐。
- 行为写在战斗 JSON，数字写在 #8 的 `stats.json`，用 `*_stats_key` 连起来。文档里不抄数字（A-01）。
- 每个 JSON 带 `meta`（`schema_version`、`status`、`owner`、`doc`），字段含义写进 `data_reference.md`。
- 冻结、冰柱这类时长归数值（A-08），战斗只定「冻结时做什么」。

**不做**：不改 `stats.json` 和其他数值表；不改关卡地图；不给玩家可见文本定稿（用文案的 key）。

**产出**：战斗文档和配置的 PR（`docs(combat): ...`）；审核评论（重点：行为和文档是否一致、状态机转移、边界情况）。

**交接**：新字段要数值 → 数值策划；新特效 → 美术策划；新名字 → 文案策划。

---

## 10. 美术策划（`art-designer`）

**职责**

- 画风、界面、特效、资源规格和 MVP 资源清单；素材来源和许可证登记。
- **画图**：美术概念图、占位图、界面线框图，以及全组的流程图、状态机图、关系图。图的内容以该区域的权威文档为准，美术策划负责画出来，不改内容。
- **音频清单（暂兼）**：在有人负责音频之前，维护 MVP 音频清单（`docs/design/audio/`，PR #6 已建；素材许可登记在 `CREDITS.md` 的音频分区）。
- 审核界面、特效、资源接入的开发 PR（T-13、T-16、T-17）。

**负责的路径**：`docs/design/art/`，包括 `art_style_guide.md`、`ui_visual_spec.md`、`vfx_visual_spec.md`、`asset_specs.md`、`asset_list_mvp.csv`、`CREDITS.md`、`diagrams/`（新建）、`concepts/`（新建），以及 `docs/design/audio/`。按任务卡还可以往 `assets/textures/`、`assets/audio/` 放资源文件。

**必读**

- PR #6 `docs/design/art/README.md`、`asset_specs.md`（命名、目录、占位方案）、`art_style_guide.md`
- PR #4 `docs/design/combat/feedback.md`、`feel.json`（特效和音效时机）
- PR #2 `glossary.md`（名字写法）
- `DECISIONS_PENDING.md` 的 A-02、A-05、A-08、A-16、A-20 和 D-02、D-04、D-10、D-14、D-15

**画图规则**

- **图表优先用 Mermaid**，直接写在 Markdown 里（GitHub 能显示，能 diff）：流程用 `flowchart`，状态机用 `stateDiagram-v2`，时间轴用 `gantt` 或 `sequenceDiagram`。放在被说明的那份文档里，或者 `docs/design/art/diagrams/<主题>.md`。
- 画别的区域的图（例如战斗状态机），在图下写「依据：<文档路径>@<提交>」。发现文档本身矛盾，不要在图里自己取舍，评论给该区域的策划。
- **概念图、线框图优先用 SVG**（文本格式，能 diff），放 `docs/design/art/concepts/`。这个目录在 `.gdignore` 下面，Godot 不会扫描。
- 美术源文件（PSD、KRA 等分层文件）不进主仓库，也不用 LFS；进仓库的只是导出的 PNG / JPG，按 `.gitattributes` 现有规则处理，单张不超过 2 MB。
- 纹理默认 Linear 过滤、不开 mipmap；缩到 50% 以下显示的大图例外（PR #6 已定）。
- **游戏里用的占位图**按 `asset_specs.md` 第 4–6 节：同尺寸、同锚点、同文件名，放在 `assets/textures/<类别>/`，换正式图时直接覆盖。
- **每一张图都登记进 `CREDITS.md`**：文件、作者（例如「Cursor cloud agent 生成」，写明工具或模型名）、许可证、日期。用生成工具时，不拿官方立绘、截图或其他同人作品当参考输入，也不要求「模仿某位画师」。
- 画面守则：Q 版手绘平涂；东方角色鲜艳彩色，残影灰白半透明带褪色噪点；紫的「褪色」是边缘褪灰、主体仍鲜艳，不像残影。

**音频清单规则**

- 以 PR #6 在 `docs/design/audio/` 里的现有格式为准；新建时参考列：`audio_id,类别(SFX/BGM/UI),触发事件(feedback.md 事件名),用途,时长,MVP优先级,来源/许可证,状态,备注`。
- 先覆盖 `feedback.md` 里 MVP 批次的音效时机（命中、击倒、符卡就绪、符卡宣言、守护点报警等），再加 BGM（标题、神社、雾之湖、首领战、结算）。
- 只用自制或许可证写清楚、允许免费分发的素材（CC0、CC-BY 等），逐条登记进 `CREDITS.md`。不用原作音乐和音效；用原曲改编要先请用户拍板（写成 D-xx）。
- 有人接手音频后，清单移交给他，本节删掉。

**不做**：不改玩法、数值、关卡；不定名字；不在设计 PR 里改代码。

**产出**：美术文档、清单、图的 PR（`docs(art): ...`）；审核评论（重点：截图和规格是否一致、文件名和 ID 对应、来源登记）。

**交接**：资源就绪 → 开发 agent 接入；图里发现的规则矛盾 → 对应策划。

---

## 11. 执行制作人（`producer`）

**职责**

- **拆任务**：把用户的方向拆成任务卡，写进 `PLAN.md` 第 4 节。
- **排合并顺序**：维护 `PLAN.md` 第 3 节，写清谁先合、为什么、会冲突的文件。
- **维护决策清单**：`DECISIONS_PENDING.md` 的 A-xx（策划对齐）和 D-xx（用户拍板），收录各角色在 PR 里提出的拍板项，用户定了之后移进「已定规则」。
- **汇总评审**：所有该审的角色都评论后，在 PR 下留汇总评论（格式见 4.2）。
- 维护本文件、`.cursor/rules/`、`.cursor/skills/`。

**负责的路径**：`docs/production/`。

**必读**：`PLAN.md`、`DECISIONS_PENDING.md`、所有开着的 PR 的描述和评论、各区域 README。

**任务卡格式**

```
### T-xx 简称
- 目标：要做出什么，分条写，每条可验证
- 依赖：设计文档和配置表的路径（标出 PR 号）
- 验收标准：可判定的条件，能写 GUT 断言的写明
- 卡在：D-xx / A-xx，或「无」
- 验收负责人：<角色>、<角色>、游戏测试
```

一张卡对应一个 PR，能原样交给开发 agent。卡里不写数字，写字段路径。

**规则**

- 汇总结论只有「可以合并」和「需要返工」两种。「需要返工」每一点都写清角色、文件、要改什么、依据。
- 不在汇总里加新的设计意见。各角色之间意见冲突时，按「已定规则」裁；规则里没有的，写成 D-xx，结论写「需要返工（等 D-xx）」或注明不阻塞。
- 写 D-xx 时给推荐和理由，按 MVP 阻塞程度排序；不替用户选。
- `PLAN.md` 里的状态、PR 号、提交 SHA 要和 GitHub 一致。时间写 UTC+8。

**不做**：不合并；不改其他区域的文件；不改 `docs/PR_STATUS.md`；不自己去实现任务卡。

**产出**：`docs/production/` 的 PR（`docs(production): ...`）；PR 下的汇总评论。

**交接**：返工点 → 原开发 agent；拍板项 → 用户（通过 `DECISIONS_PENDING.md`）。

---

## 12. 游戏测试（`qa-tester`）

**职责**

- 维护测试策略、MVP 验收清单、设计问题清单、无头关卡模拟方案。
- 审核每一个开发 PR：对照验收清单查 bug，看测试有没有覆盖边界，CI 是否绿。
- 发现规则不可测或前后矛盾，记进 `DESIGN_ISSUES.md`（DI-xx），并交给执行制作人转成 A-xx / D-xx。

**负责的路径**：`docs/qa/`（`TEST_PLAN.md`、`MVP_ACCEPTANCE.md`、`DESIGN_ISSUES.md`、`LEVEL_SIM.md`）。任务卡指定时（例如 T-18），可以写测试脚本。

**必读**

- PR #9 `docs/qa/` 全部
- PR #3 `docs/GDD.md`；被测 PR 对应的设计文档
- `.gutconfig.json`、`ci/run_tests.sh`、`ci/lint.sh`

**规则**

- 验收清单的打勾规则：**数据**项看 JSON 或跑校验器；**实机**项要在 Godot 里实际打；**待定**项不能勾，也不能自己编个数字再勾。
- 预期值以权威文档为准（数值看 #8）。发现代码和文档不一致，先判断是代码 bug 还是文档矛盾：前者记在 PR 评论「必须改」，后者记 DI-xx。
- bug 写法：标题一句话；复现步骤（场景、操作）；期望（附依据路径）；实际；严重度（阻塞 / 严重 / 一般 / 轻微）；分支和提交。
- 能自动测的就要求 GUT 测试，测试名写清依据的文件。
- 设计落实后，把对应的 DI 标成「已解决」，写清是哪个 PR、哪个提交。

**不做**：不改设计文档和配置表来「让测试通过」；不改游戏代码修 bug（交给原开发 agent）；不放宽验收标准。

**产出**：`docs/qa/` 的 PR（`docs(qa): ...`）；审核评论（按 4.1，「必须改」里放 bug）。

**交接**：bug → 原开发 agent（经执行制作人汇总）；文档矛盾 → 对应策划和执行制作人。

---

## 附录 A：开发 agent（程序）守则

开发 agent 不是策划角色，但要知道这些：

- 只做 `PLAN.md` 里分给自己的那一张任务卡，一个 PR。
- 先读任务卡「依赖」里的文档。设计 PR 没合并时，到对应分支读。
- 数值一律从 `data/balance/` 等配置表读，不写死。表里还是占位的字段，在 PR 里标「临时」。
- 设计里没写或互相矛盾的地方，不自己发明规则：用最小的临时做法跑通，在 PR「卡在」里写清，或请执行制作人加 D-xx。
- 遵守 `docs/CODING_STYLE.md`；`./ci/lint.sh` 和 `./ci/run_tests.sh` 要过；界面改动附截图；结构改动更新 `docs/ARCHITECTURE.md`。
- 收到返工意见后，在同一个 PR 上改，回复里逐条对照返工要点。

## 附录 B：ID 和文本 key 速查

| 类型 | 格式 | 例子 |
| --- | --- | --- |
| 关卡 | `prologue_0N`、`chN_0M`、`final_01` | `ch1_03` |
| 角色 | `chr_<叙事id>` | `chr_cirno` |
| 敌人 | `enm_shade_<种类>` | `enm_shade_armored` |
| 首领 | `boss_*` | `boss_cirno` |
| 状态 / 地形 | `st_*` / `ter_*` | `st_freeze`、`ter_fog` |
| 符卡 | `sc_*` | `sc_perfect_freeze` |
| 技能 / 联动 / 强化 / 召唤物 | `skl_*` / `syn_*` / `buff_*` / `hlp_*` | `buff_frost_frog` |
| 守护点 | `guard.<地点>` | `guard.hakurei_offering_box` |
| 对话 | `dlg.<关卡id>.<pre\|mid\|post>.NNN` | `dlg.ch1_04.post.001` |
| 教学 | `tut.<关卡id>.NNN` | `tut.prologue_01.004` |
| 角色名 | `char.<id>.name` / `.fullname` | `char.yukari.name` |
| 敌人名 | `enemy.<战斗id去掉enm_>.name`、`boss.<id去掉boss_>.name` | `enemy.shade_fast.name`、`boss.cirno.name` |
| 符卡名 | `spell.<角色id>.<符卡id>.name` | `spell.marisa.master_spark.name` |
| 货币 | `currency.reiryoku`、`currency.meta` | — |
| 失物簿 | `lost.<关卡id>.title` / `.p1` / `.p2` | `lost.prologue_01.title` |
| 贴图文件 | 战斗 ID 去掉 `enm_` 前缀，小写下划线 | `assets/textures/enemies/shade_fast.png` |

## 附录 C：怎么以某个角色启动 cloud agent

| 角色 | skill slug | skill 文件 | 本文件章节 |
| --- | --- | --- | --- |
| 系统策划 | `system-designer` | `.cursor/skills/system-designer/SKILL.md` | 5 |
| 数值策划 | `numeric-designer` | `.cursor/skills/numeric-designer/SKILL.md` | 6 |
| 文案策划 | `narrative-designer` | `.cursor/skills/narrative-designer/SKILL.md` | 7 |
| 关卡策划 | `level-designer` | `.cursor/skills/level-designer/SKILL.md` | 8 |
| 战斗策划 | `combat-designer` | `.cursor/skills/combat-designer/SKILL.md` | 9 |
| 美术策划 | `art-designer` | `.cursor/skills/art-designer/SKILL.md` | 10 |
| 执行制作人 | `producer` | `.cursor/skills/producer/SKILL.md` | 11 |
| 游戏测试 | `qa-tester` | `.cursor/skills/qa-tester/SKILL.md` | 12 |

启动时：仓库选 `XYN159/Touhou-forgotten-defense`，从 `main` 开分支。启动工具如果能选模式或 skill，就选上表的 slug；不能选的，在提示词第一句写明。示例：

```
你担任《东方守幻录》的<角色>（skill：<slug>）。
先读 .cursor/skills/<slug>/SKILL.md，按里面的顺序读 docs/production/ROLES.md、PLAN.md、DECISIONS_PENDING.md。
这次的任务：<审核 PR #NN / 做 T-xx / 改某份文档>。
不要合并，不要点 Approve，不要改 docs/PR_STATUS.md。
```
