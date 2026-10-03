# ADR-0003：关卡用 JSON 描述，加载器以后再写

- 状态：提议
- 日期：2026-09-27
- 补充：预定槽位、固定路线和星级见 ADR-0004。星级按剩余生命的绝对值，阈值以 `stars.thresholds_lives_left` 为准，按顺序对应 3 星、2 星、1 星。首通目标不参与星级。这篇里关于「任意空地可放」的说法以 ADR-0004 为准。

## 背景

游戏已从竖屏车道改为东方 Project 二次创作塔防。制作人已经定了关卡规模：7 列 × 12 行、一共 24 关、星级只看剩余生命。叙事初稿（尚未合并）定了角色 id 和符卡 id，但还没有敌人 id，也没有威胁预算。

车道关卡如果继续写进场景脚本，后面改一张图就要改代码。数值文件 `data/balance/starting_balance.json` 描述的是小队人数和加人门，对不上塔防。

## 决定

- 关卡放在 `data/levels/`。单关一个 JSON，另有索引、敌人图鉴、角色名单和星级规则。格式写在 `data/levels/level.schema.json`。
- 给人看的说明写在 `docs/design/level/`。地图上的好位置既出现在说明里，也出现在 JSON 里。
- 设计期用 `tools/validate_levels.py` 做严校验：地图必须是 7×12，路径必须连续。难度表在的时候，每一波威胁和全关合计必须和它对上；难度表还不在仓库里时，只警告并跳过这项。CI 会跑它。
- 游戏内加载器这次不写。以后写的时候要照 `BalanceConfig`：每个字段有默认值和地板，读坏了只警告，不让游戏闪退。严校验留在设计期，宽读取留在运行时。
- 威胁预算和首通剩余生命归数值策划，放在 PR #8（分支 `numeric/touhou-td-framework`）的 `data/balance/level_difficulty.json`。本 PR 不附带这份文件，要在 #8 之后合并。用到的字段是 `levels.<level_id>.threat_budget_coef`、`wave_threat_budgets`、`threat_budget_total`、`target_lives_first_clear`。这里不抄系数、预算和首通数字。开局灵力和每活过一波加的灵力以 `data/balance/combat/stats.json` 的 `economy` 为准。
- 地图字段跟战斗策划的读图约定一致：`cells` 用 `P` `.` `B` `S` `G`，路线是 `[列, 行]`，地形用 `ter_*`。敌人、角色、状态用 `enm_`、`chr_`、`st_`。生命、护甲、漏怪扣命和威胁点不写进关卡图鉴。权威表是 `data/balance/combat/stats.json` 的 `enemies` 和 `bosses`。图鉴只留指向这些字段的路径。
- 不删除车道场景和旧的 GDD 正文。那些内容已经对不上新关卡，替换等制作人点头。

这次故意不做的：

- 不把关卡读进战斗场景。
- 不改 `data/balance/starting_balance.json` 的车道字段。
- 不发明困难模式、击破回复灵力、村民失败人数的正式字段。

## 后果

- 改一张已经画完的图，要同时改 JSON、说明，并让校验通过。
- 战斗和数值接进来之前，这些文件不会影响现在能玩的标题和车道。
- 若以后推翻格子尺寸或星级区间，新写一篇 ADR，并改 schema。不要只改某一关的数字把规则带过去。
