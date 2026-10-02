# 设计问题：规则不可测，或前后矛盾

写于 2026-10-02。只读了这些材料，没有改它们：

- PR #3（分支 `docs/gdd-touhou-td`）：`docs/GDD.md`、`docs/ROADMAP.md`
- PR #4（分支 `cursor/docs-combat-rules-354a`）：`docs/design/combat/`、`data/balance/combat/`
- PR #5（分支 `cursor/design-level-framework-01a3`）：`docs/design/level/`、`data/levels/`、`data/balance/level_difficulty.json`、`tools/validate_levels.py`
- PR #6（分支 `docs/art-framework`）：`docs/design/art/`
- PR #2（分支 `docs/touhou-narrative-draft`）：`docs/design/narrative/`、`data/text/`
- 没有开 PR 的分支 `numeric/touhou-td-framework`：PR #5 把难度表的权威指到这里。下面引用它时会写明「数值分支，无 PR」
- `main`：标题画面和车道占位。`docs/GDD.md` 仍是已作废的车道玩法

没有找到「塔防核心原型」的 PR。验收不能依赖那份还没合并的代码。

每一条都是：现在无法写成一条可判定的通过条件，或者两份文档让测试员会得出相反的结论。建议的澄清方式是请制作人定一句「以哪份为准」，再让另一份改掉，而不是由测试补一个数字。

条目编号 DI-01 起，给 `MVP_ACCEPTANCE.md` 和 `LEVEL_SIM.md` 引用。

---

## DI-01 同一项数字有两三套值，测试无法选边

**出处**

- PR #3 `docs/GDD.md`「局内塔防」：开局灵力、击杀掉落、放置费用、升级费用都写「由数值策划定，这里不写数字」。伤害公式只写了 `伤害 = max(攻击 − 护甲, 攻击 × 0.2)`，没有「最少 1 点」
- PR #4 `data/balance/combat/stats.json`：文件 `meta.status` 是 `placeholder_pending_balance_design`。`economy.starting_spirit` 是 100。小残影血量 30、灵力掉落 5、威胁点 1；快残影血量 35、移速 2.0、掉落 4、威胁点 2；硬残影血量 70、移速 0.7、护甲 8、威胁点 3；`boss_cirno` 血量 1500、移速 0.5、护甲 3、漏怪 5、威胁点 20、击杀掉落 0。灵梦费用 50、攻击 10，`level_attack_mult` 是 `[1.0, 1.5, 2.2]`。另有顶层 `min_damage` 1
- PR #4 `docs/design/combat/README.md`「9.1 数值策划」：快残影血量 35 和移速 2.0 已确认；开局灵力、掉落、漏怪、费用递增仍请数值确认。同文件「已拍板」第 14 条又说硬残影不在 MVP
- PR #5 `docs/design/level/overview.md`「难度怎么爬」、`data/levels/*.json` 的 `params`、`data/balance/level_difficulty.json`：开局灵力写 150，每活过一波再加 20。图鉴威胁点是小残影 1、快残影 1、硬残影 4、冰之残影不占预算（`threat_points: null`）
- 数值分支（无 PR）`docs/design/numeric/README.md`「已确认的值」、`docs/design/numeric/03_spirit_economy.md`：开局灵力 150 已确认，并写明「PR #4 占位 100，以用户为准」。小残影血量 60、快残影掉落 5、威胁点 1；硬残影血量 200、移速 0.6、护甲 10、掉落 15、威胁点 4；冰之残影血量 3000、移速 0.4、护甲 5、掉落 100、漏怪 10、威胁点 0。灵梦费用 80、攻击 20。局内升级倍率写成 1.0 / 1.4 / 1.8。琪露诺普攻减速写成 20%。PR #4 `docs/design/combat/characters.md` 和 `characters.json` 的 `chr_cirno.attack.applies_statuses` 则是 `st_slow` 强度 0.35、持续 2 秒。该分支生成的 `stats.json` 把 Boss 放在 `bosses` 段，PR #4 的 `stats.json` 把 `boss_cirno` 放在 `enemies` 段

**问题**

无头模拟和人工验收都要回答「开局有多少灵力、一只小残影多少血、漏一只扣几条命」。现在选 PR #4 的表和选数值分支的表，会得到相反的通关结论。PR #3 又明确不许测试员自己填这些数。快残影的血量 35 和移速 2.0 是少数两边都写了的已确认项，其余不能当成定案。

**建议澄清**

制作人指定一份权威表（建议就是以后要合并的那份 `data/balance/combat/stats.json`），并写清每个字段是「已确认」还是「仍是占位」。占位字段在验收清单里继续标待定。PR #4 和数值分支冲突的键至少包括：`economy.starting_spirit`、各敌人的 `hp` / `spirit_drop` / `threat_points` / `leak_damage`、`boss_cirno` 整行、角色 `cost` 和 `base_attack`、升级倍率、`min_damage` 是否叠在 GDD 公式后面。

---

## DI-02 MVP 出不出硬残影，出几只

**出处**

- PR #3 `docs/GDD.md`「MVP」、`docs/ROADMAP.md` 第 2 节：路上的敌人是小残影、快残影。`ch1_04` 的 Boss 是冰之残影。没有写硬残影
- PR #4 `docs/design/combat/README.md`「已拍板」第 14 条；`data/balance/combat/enemies.json` 里 `enm_shade_armored.status` 是 `post_mvp`：硬残影 MVP 之后才出现
- PR #5 `data/levels/ch1_03.json`：`new_enemy_ids` 含 `enm_shade_armored`，第 6 到 11 波各 1 只、第 12 波 2 只，合计 8 只。`docs/design/level/overview.md` 的 24 关表却写第一章第 3 关「只有小残影和快残影」，同文后面又写「少量出现硬残影，共 8 只」
- PR #2 `docs/design/narrative/story_outline.md`「残影种类」和第一章 `ch1_03`：硬残影在第二章正式使用，`ch1_03`「只预告一两只」
- PR #6 `docs/design/art/README.md`「已定」第 5 条：美术按 3 种残影准备，待制作人最终确认；硬残影无论如何在第二章第 1 关登场
- 数值分支（无 PR）`docs/design/numeric/README.md`「最终口径」：把「ch1_03 共 8 只硬残影」写成制作人已定

**问题**

`ch1_03` 的验收无法写。按 PR #3 / PR #4，出现硬残影就是缺陷；按 PR #5 的 JSON，不出现 8 只就是缺陷；按 PR #2，出现超过一两只也是缺陷。总览表自己的两句话还互相矛盾。护甲飘字（PR #4 `feedback.md` 的 `armor_spark`）是否属于 MVP，也跟着悬空。

**建议澄清**

制作人用一句话定案：MVP 七关里硬残影出现在哪一关、一共几只、其他关是否禁止出现。然后只改不一致的那几份（GDD 的 MVP 敌人句、`enemies.json` 的 `status`、叙事的「一两只」、关卡总览表那一行、美术的「待确认」）。

---

## DI-03 「每波约 20 秒」有两种计时，而且下一波是否等清场相反

**出处**

- PR #3 `docs/GDD.md`「局内塔防」：每波大约 20 秒。10 波大约 4 到 5 分钟，20 波大约 8 到 10 分钟。没有写这 20 秒从哪量到哪
- PR #4 `docs/design/combat/core_rules.md` 4.3：20 秒是「这一波出怪和清怪合在一起」的目标，不是走路时间。同文 4.2：`next_wave_delay_sec` 是「出完最后一只之后」再等多久，推荐 8 到 15 秒；场上清空后空档改成 `min(剩余时间, 4 秒)`。叫波才允许上一波没打完的敌人留在场上
- PR #4 `data/balance/combat/rules.json`：`battle_flow.wave_target_sec` 20，`intermission_sec` 4，`intermission_min_sec` 3，`intermission_max_sec` 5
- PR #5 `docs/design/level/data_format.md`「波次」：`duration_sec` 固定 20，意思是刷怪窗口。`ends_when: spawn_window` 的说明是刷完并经过波间空隙就结束。`tools/validate_levels.py` 的 `timing_problems` 强制 `duration_sec == 20` 且 `delay_sec == 4`。七关 JSON 都是这样写的
- 数值分支（无 PR）`docs/design/numeric/09_simulation.md`「波次节奏」：按 PR #5，窗口结束加 4 秒就来下一波，不等清场。生成的 `sim_results.md` 里 MVP 各关大约 24 秒/波

**问题**

体验验收要求「每波约 20 秒、波间 3 到 5 秒」。若按战斗 4.3 去量「从本波第一只出现到本波敌人全部离开」，20 秒里还要含清场，和关卡里 18 到 22 秒的刷怪窗口不是同一个钟。若按关卡去量，下一波在刷完后 4 秒就开始，场上可以叠两波，战斗 4.2 又说只有叫波才重叠。两种做法的通关难度差很多，DI-06 的模拟就是按「不等清场」跑的。

**建议澄清**

定一件事，并改掉另一份：

1. 20 秒是刷怪窗口，还是「出怪加清完」的整段。
2. 没点叫波时，下一波是否必须等场上清空。
3. 关卡字段 `delay_sec` / `next_wave_delay_sec` 对应战斗状态机里的哪一段（`waiting` 的 8 到 15 秒，还是清空之后的 3 到 5 秒空档）。

在这三句写齐之前，`MVP_ACCEPTANCE.md` 的实机节奏条目标待定。JSON 里「写了 20 和 4」只能证明表填了，不能证明手感对。

---

## DI-04 第一波开始前，玩家等的是 10 秒还是 14 秒

**出处**

- PR #4 `docs/design/combat/core_rules.md` 4.1：`deploy` 倒计时 10 秒结束，或玩家点「开始」，就进入 `spawning`
- PR #4 `data/balance/combat/rules.json`：`battle_flow.deploy_time_sec` 是 10
- PR #5 `docs/design/level/overview.md`「难度怎么爬」、`data_format.md`：布阵 10 秒和第一波的 4 秒开战空隙是分开的。七关 JSON 的 `deploy_time_sec` 是 10，`waves[0].delay_sec` 是 4
- 序章三关 `deploy_wait_for_player` 为 true。PR #4 4.3 说这是让布阵倒计时暂停，直到玩家放完。PR #2 `data/text/dialogue_zh.csv` 的 `tut.prologue_01.004` 备注也是「玩家放好之前不出怪」

**问题**

「布阵 10 秒」可以测，但「点开始之后、第一只残影出现之前还有没有 4 秒」两份文档不一致。序章还要先等玩家放置，再跑倒计时。体验计时的起点不唯一，就不能判定过关或失败。

**建议澄清**

用时间轴写死序章和普通关各一条，例如：放好角色 → 10 秒倒计时（可提前开始）→ 是否再空 4 秒 → 第一只出现。序章的「等放置」期间倒计时停在满格还是停在 0，也要一句。

---

## DI-05 从当前波重来时，快照里有哪些东西

**出处**

- PR #3 `docs/GDD.md`「核心循环」、`docs/ROADMAP.md` 第 1 节：恢复这一波开始时的基地生命、灵力、角色摆放、局内等级、已选强化
- PR #4 `docs/design/combat/core_rules.md` 5.2、`docs/design/combat/README.md`「已拍板」第 5 条：快照包括灵力、已放角色、强化、符卡充能。没有写守护点生命，也没有单独写局内等级

**问题**

若快照不恢复守护点生命，生命已经到 0 再「从当前波重来」会立刻再判负，这个按钮无法测成「能接着打」。若快照不恢复符卡充能，和战斗已拍板不符。若快照不恢复局内等级，又和总纲不符。

**建议澄清**

做一张快照字段表，每项写「恢复 / 不恢复」：守护点生命、灵力、场上角色及其等级、强化层数、符卡充能、符卡使是谁、地形（冰柱、冰面、浓雾）、Boss 当前血量和阶段。程序按这张表做，测试按这张表断言。

---

## DI-06 第一章首领关的入场和血量规则

**状态（2026-10-02）**：入场波和血量倍率已定。`enter_wave` 是 11，Boss 血量不乘关卡倍率。#8 `ac47c18` 把系数锁定为 0.74：5 个种子平均剩余 10.0，平滑期望 11.9，最差种子 −9。通关类验收可以按这一套查「文档和 JSON 是不是同一波」。最差种子会输，不能把「每个种子都过关」写成通过条件。漏一次扣多少仍见 DI-07。出怪数量还没按 0.74 的每波预算重排。

旧标题是「按现稿数值模拟判为打不过，入场规则仍待拍板」。下面的出处是当时的记录。

**出处**

- PR #5 `data/levels/ch1_04.json`：`enter_wave` 是 5，`prelude_wave_ids` 是前 4 波，`hp` 不写在关卡里。`data/balance/level_difficulty.json` 的 `ch1_04.hp_multiplier` 是 `1.90`，`threat_budget_coef` 是 `0.70`，`expected_first_clear_lives` 是 `10-11` 且状态仍等制作人确认
- PR #5 `docs/design/level/overview.md`「请制作人拍板」第 6 条：按第 5 波入场且血量乘关卡倍率，系数降到多低都打不过，平均漏 2 次。建议改成第 11 波（倒数第 5 波）入场，血量不乘倍率。文中写系数 0.70 大约剩 18 条命，0.75 大约剩 12 条，0.80 会崩。JSON 这一轮仍是第 5 波
- 数值分支（无 PR）`docs/design/numeric/06_level_curve.md`：现行规则写成「血量 3000 × 1.90 = 5700、第 5 波入场、漏一次扣 10」。系数 0.25 时模拟剩余 −0.4，5 个种子全输。建议方案（不乘倍率、第 11 波入场）在系数 0.75 时剩余 12.4，系数 0.70 时剩余 18.2。同文也写了这仍待制作人拍板
- PR #4 `data/balance/combat/stats.json` 的 `boss_cirno.hp` 是 1500，不是 3000。乘 1.90 也得不到 5700。所以「打不过」这个结论绑在数值分支那套血量上，不是绑在 PR #4 的占位血量上

**问题**

MVP 最后一关不能同时满足「按现有 JSON 原样验收」和「首通还剩大约 10 到 11 条命」。两条都写在 PR #5 里。在制作人改 `enter_wave` 或改血量规则之前，人工试玩失败不能算程序缺陷，试玩成功也不能算数值已经定案。

**建议澄清**

拍板三件事再改一处 JSON：入场波、Boss 血量乘不乘 `hp_multiplier`、漏一次扣多少（见 DI-07）。拍板前 `ch1_04` 的通关类验收条目标待定，只检查「数据文件和文档描述的是同一套入场波」。

---

## DI-07 漏怪扣多少命未定，校验器指向的路径在 PR #4 里不存在

**出处**

- PR #3 `docs/GDD.md` 清单第 8 条：漏过一只残影扣几点，仍是「待你补充」。Boss 每次扣几点「见数值策划文档」
- PR #4 `docs/design/combat/core_rules.md` 5.1：普通 1、快 1、硬 2、Boss 每次 5，标记为占位。数字在 `stats.json` 的 `enemies.*.leak_damage`，`boss_cirno` 也在 `enemies` 里
- PR #5 `data/levels/ch1_04.json` 的 `bosses[0].leak.lives_source` 是 `data/balance/combat/stats.json#/bosses/boss_cirno/leak_damage`。`tools/validate_levels.py` 的 `timing_problems` 强制这条路径。`data/levels/rating.json` 说权威字段在 `stats.json` 的 `enemies` 和 `bosses`
- 数值分支（无 PR）的 `stats.json` 才有 `bosses.boss_cirno.leak_damage`（值是 10，状态不是完全确认）。PR #4 的文件没有 `bosses` 这一段，按 PR #5 的指针会取不到数

**问题**

「漏一只扣几条命」不能写进通过条件。就算以后要自动检查指针，现在 PR #4 和 PR #5 的 JSON 结构对不上，校验会在合并时失败，或悄悄读到另一份表的 5 点或 10 点。

**建议澄清**

总纲第 8 条给出每个 MVP 敌人的 `leak_damage`（含 Boss 折返）。`stats.json` 只保留一个位置，关卡里的 `lives_source` 改成那个位置。在此之前验收只检查「关卡文件没有自己抄一个扣血数字」。

---

## DI-08 2 星比例、首通该剩多少命，几份文档不是同一个目标

**出处**

- PR #3 `docs/GDD.md`「关卡推进」：通关 1 星；剩余生命 ≥ 一半（10/20）为 2 星；20/20 为 3 星。并写「这是现在用的数，数值策划以后可以改」
- PR #5 `data/levels/rating.json`：`two_star_lives_ratio` 0.5，`two_star_ratio_status` 是 `pending_numbers`。`first_clear` 普通关 `11-13`、首领关 `10-11`，状态是等制作人确认，并写明这不是星级分档。序章也用 `11-13`（见 `level_difficulty.json` 的 `prologue_01`）
- PR #2 `docs/design/narrative/lost_and_found.md`、`story_outline.md`：2 星要「达到一定比例」，比例不写数字。1 星解锁失物簿标题和第一段，2 星解锁全文。某一章全部 3 星解锁外观，同段又写「要凑满几颗星由系统定」
- PR #5 `docs/adr/0004-preset-slots-and-fixed-routes.md`：2 星比例按 50% 占位，不把重打奖励写成已确认
- 数值分支（无 PR）`docs/design/numeric/README.md`「最终口径」：2 星按剩余 ≥ 10。首通目标却是序章 18 / 17 / 16，第一章 14 / 13 / 12 / 11，终章 10。和 PR #5 的「普通关一律 11 到 13、序章也包括在内」不是同一组目标

**问题**

满命 3 星、通关才有 1 星，这几份是对齐的，可以测。2 星能不能用「剩 10 条命」当唯一标准，PR #3 说能、PR #5 说还是占位。首通手感更不能测：序章第 1 关若剩 12 条命，按 PR #5 的 `11-13` 算达标，按数值分支的目标 18 算差一截。失物簿「本章全 3 星才给外观」和「几颗星另定」也写在同一段。

**建议澄清**

分开拍两件事。星级只定 `rating.json` 里的三档，并改掉 `pending_numbers` 或改掉 GDD 里的 10/20，使二者相同。首通剩余生命另定一张表（至少把序章和首领关分开），标明它不参与星级。外观解锁用的星数单独一句，不要和 2 星比例混在一段里。

---

## DI-09 局外奖励的数字，总纲不许写，数值分支已经写了比例

**出处**

- PR #3 `docs/GDD.md` 清单第 5、14 条：资源名称、第一次给多少、重打给多少都不写数字。只定了「重打比第一次少」「每个角色 1 到 20 级」
- PR #2 `docs/design/narrative/glossary.md`：局外资源名待定，候选「忆晶」「赛钱」「幻想碎片」，key 暂用 `currency.meta`
- PR #5 `data/balance/level_difficulty.json`：`reward_meta_first_clear` 和 `reward_meta_replay` 都是 `pending_numbers`
- 数值分支（无 PR）`docs/design/numeric/README.md`「最终口径」：写了重打 50% / 30% / 20%。这和「不写数字」冲突

**问题**

MVP 验收不能检查「过关弹出 +N 个某资源」。写了具体比例的那份还没有 PR，不能当成制作人已经同意。测试若按 50% 做断言，就是在把草案写成定案。

**建议澄清**

每关两个整数（首通、重打）写入难度表、替换 `pending_numbers` 之后，才能勾数量。在那之前只测「重打拿到的数量严格少于首通」，而且只有两边都是数字时才比较；现在两边都不是数字，数量仍待定。

**用户补记（2026-10-02）**：界面和测试先用文本 key `currency.meta`。中文显示名仍未选定，不把「忆晶」「赛钱」「幻想碎片」写成定案。验收不断言某一个中文名。

---

## DI-10 第二章以后，谁是首领、谁在哪一关加入，叙事和关卡不是一套

**出处**

- PR #2 `docs/design/narrative/story_outline.md`「关卡与加入对照」：`ch2_04` 的 Boss 是咲夜本人；`ch3_04` 的 Boss 是妹红本人；文若可玩则 `ch4_04` 的 Boss 是早苗本人，文若不可玩则早苗在 `ch4_01` 打完加入，`ch4_04` 改成一只大飞行残影。同文「加入套路」又说 Boss 关本关不能放即将加入的人
- PR #5 `docs/design/level/overview.md`「首领不是已经入队的人」、`data/levels/enemy_catalog.json`：第二章到第四章的首领是残影复制体（`boss_ch2_sakuya_shade`、`boss_ch3_mokou_shade`、`boss_ch4_sanae_shade`），不能是本人。早苗提案是通关 `ch4_04` 后加入，文不进解锁链。这些行的状态是 `pending_文案策划`
- PR #4 `docs/design/combat/README.md`「最终 ID 清单」预留的是 `boss_sakuya`、`boss_mokou`、`boss_sanae` 这种 id，和 PR #5 的 `boss_ch2_*_shade` 不是同一套名字
- PR #3 `docs/GDD.md` 清单第 18 条：第二章及以后第 1 关后加入的是谁，仍待定

**问题**

MVP 七关的加入时机（灵梦、魔理沙、琪露诺、紫）在 PR #2、#3、#5 里已经对齐，不放进这条。从第二章起，测试无法写「这一关的首领 id 是什么、胜利后谁进入可放置名单」。叙事把「Boss 是她本人」和「本关不能放她」放在一起，关卡则改成「Boss 是复制体、本人在通关后加入」。两套都能自圆其说，但不能同时当预期结果。

**建议澄清**

MVP 之后另开一次拍板，输出一张表：关卡 id、首领 id、显示名、通关后加入谁、本关可放置名单。在表定稿前，第二章及以后的关卡不要进 MVP 验收。PR #4 的预留 id 和 PR #5 的 shade id 选定一种。

---

## DI-11 路线在战斗中会不会移动

**出处**

- PR #5 `docs/adr/0004-preset-slots-and-fixed-routes.md`、`docs/design/level/overview.md`：路线几何开战前固定。第五章用入口开关，不用「路会移动」。校验明确不做战斗中改路径
- PR #2 `docs/design/narrative/story_outline.md`：`ch5_01`「路只轻轻挪一次」，`ch5_02`「路移动两次」。给关卡策划的对接点写「第二章馆内路线变形、第五章移动路线」
- 数值分支（无 PR）`docs/design/numeric/09_simulation.md` 局限：馆内路线变形没有模拟

**问题**

「战斗中格子变不变」是关卡模拟和原型的分叉。按 PR #5，移动路线是缺陷；按叙事大纲的第五章段落，完全不移动又对不上剧情需求。这不是 MVP 七关的地图（那些图已经画成固定路线），但现在不加一句，后面的测试会把两种都当成规格。

**建议澄清**

制作人确认 ADR-0004：全游戏路线几何开战前固定，叙事里「路会移动」改成「另一条已经画好的路，到某一波才开始出怪」。若第五章确实要改格子，就撤掉 ADR 里「不再做 path_shifts」那句，并单独立项，不要留在两边。

---

## DI-12 放置手势和符卡按钮：教学句子和战斗规则相反

**出处**

- PR #2 `data/text/dialogue_zh.csv`：`tut.prologue_01.004` 是「拖动灵梦的头像，放到发光的格子上」；`tut.prologue_01.008` 是「点击灵梦，发动符卡」
- PR #4 `docs/design/combat/core_rules.md` 6.1 和 6.3：点空的 `.` 格，再点头像放置。符卡按钮在底部，放的是当前符卡使的默认符卡。同目录 `README.md` 第 6 节第 7、8 条已经点名这两句教学要改
- PR #4「已拍板」第 1 条：符卡使用是方案 A+，布阵期和波间可以换符卡使，波次中不能换
- PR #6 `docs/design/art/README.md`「待确认」第 9、10 条：放置是拖头像还是点格子再点头像，符卡按钮放谁的符卡，仍标待确认

**问题**

序章教学是 MVP 学习曲线的第一关。文案、战斗、美术三处对「玩家的手指要做什么」给出了不同预期。照抄 CSV 去做自动化点击，会和战斗规则相反；照战斗规则做，现有教学句又是错的。美术若仍按待确认排按钮位置，界面测试没有坐标可对。

**建议澄清**

制作人定操作（建议直接沿用已经拍板的「点格子再点头像」和底部符卡按钮），文案改 `tut.prologue_01.004` 和 `tut.prologue_01.008`，美术划掉待确认第 9、10 条。测试以改完后的教学句为通过条件。

---

## DI-13 第三张符卡和连点破冰：用户已定，设计文档还没改

**状态**：用户已拍板（2026-10-02）。战斗、文案文档还没改成同一句，**不标已解决**。

**用户原话**（回答「第三阶段用不用雪符「钻石风暴」；被冻住能不能连点破冰」）：「用，能」。

- 第三阶段用雪符「钻石风暴」。
- 被冻住可以连点破冰。这句覆盖先前「不能连点」的推荐。
- 点几次，用户没有另给。`core_rules.md` 6.2 草案写过 3 下。测试按战斗配置里的次数字段，不把 3 写成用户新定的数，也不改成别的数。

**出处**

- PR #4 `docs/design/combat/README.md`「需要制作人拍板」第 6 条：雪符「钻石风暴」认可 / 改掉 / 只做两阶段，推荐认可，但还没划掉。第 8 条：被冻住的角色能不能连点 3 下破冰，推荐能，也还没划掉
- 同 PR `data/balance/combat/bosses.json`：`boss_cirno` 已有三阶段，第三段就是 `sc_boss_cirno_diamond_blizzard`。`core_rules.md` 6.2 把连点 3 下写成草案默认值
- PR #5 `data/levels/ch1_04.json`：三阶段血量比例 1.00–0.66、0.66–0.33、0.33–0，第三张牌是钻石风暴
- PR #2 `docs/design/narrative/story_outline.md` 第一章 `ch1_04`：只写了冰符「冰瀑」和冻符「完美冻结」。`data/text/dialogue_zh.csv` 的 `tut.ch1_04.001` 写「击破它的每一张符卡」，没有第三张的宣言句
- PR #6 特效规格按三阶段在做
- PR #11 `docs/production/DECISIONS_PENDING.md` 的 D-05 仍写着待拍板，推荐仍是「不能连点」。以用户这句为准，等执行制作人改清单

**问题**

「用不用第三张牌」「能不能连点破冰」这两句已经能测。还不能勾的是：文案没有第三张的宣言 key，战斗 README 仍把这两条放在待拍板里。次数在用户这句话里没有出现，不能靠测试改表。

**还要谁改**

- 战斗策划：划掉待拍板第 6、8 条。第三阶段是雪符「钻石风暴」。被冻住可以连点破冰。次数仍留在现有字段里。
- 文案策划：补雪符「钻石风暴」的名字和宣言 key。
- 执行制作人：把上面两句写入已定规则，改掉 D-05 里「不能连点」。

---

## DI-14 紫的「换位演示一次」没有落到某一关、某一波

**出处**

- PR #4 `docs/design/combat/README.md`「已拍板」第 4 条：第一章里先通过隙间探头演示一次换位。`data/balance/combat/characters.json` 的 `chr_yukari.before_unlock` 是 `chapter1_gap_peek_once`，`unlock` 是 `chapter1_boss_clear`，`mvp_use` 是 `replay_cleared_levels`
- PR #4 没有写这次演示发生在 `ch1_01` 到 `ch1_04` 的哪一关、哪一波、换哪两个对象
- PR #2 的序章和第一章有多次「从隙间探头」的台词，那些是说话，不是可断言的换位
- PR #5 `data/levels/character_roster.json`：紫 `joins_at_level` 是 `ch2_01`。七关首通名单没有她。这和「MVP 首通不能放紫」一致，不解决「演示发生在哪」

**问题**

「演示了一次」没有观察点：没有关卡 id，没有预期被换位的单位，没有失败时怎么看出来没演。自动化和人工都无法勾这条。`mvp_use` 只说明重打已通关关卡能放她；第二章首通能不能放，要靠 PR #5 的名单，字段本身没有写「出了 MVP 之后限制解除」。

**建议澄清**

指定一个关卡 id 和一个触发点（例如某波开始后的剧情事件），写明被移动的是敌人还是角色、移动到哪一格、这一下是否造成伤害。并写明 `mvp_use` 到 `ch2_01` 首通是否还有效。在写明之前，验收只检查七关首通的可放置名单里没有 `chr_yukari`。

---

## DI-15 敌人显示名和「死亡后裂出什么」对不上

**出处**

- PR #2 `docs/design/narrative/glossary.md`「敌人名」：小残影、快残影、硬残影、飞行残影已定名。第五章暂名是「遗忘之影」「堆积体」「结界之渣」。堆积体的说明在 `story_outline.md` 是被打散时裂出小残影
- PR #4 `docs/design/combat/enemies_and_bosses.md`：显示名仍多处写「普通残影」。`enm_shade_heap` 死亡分裂出 3 个快残影。文本 key 建议是 `enemy.shade_fast.name` 这种
- PR #5 `data/levels/enemy_catalog.json`：遗忘残影、堆积残影、结界残影，名字状态 `pending_文案策划`。堆积残影的 `splits_into` 是 3 个 `enm_shade_fast`，备注写文案那边是小残影，孩子算不算进威胁还没定
- PR #2 的 key 是 `enemy.small.name`、`enemy.fast.name`，和 PR #4 建议的 `enemy.shade_basic.name` 不是同一个 key

**问题**

MVP 可以先只断言小残影、快残影、冰之残影三个已定名。一旦第五章或图鉴进测试，同一个 id 会有两个中文名、两个文本 key，分裂物还会改变威胁预算（DI-01 的威胁点也无法加总）。「孩子算不算威胁」没定，关卡校验的威胁合计就不可重复。

**建议澄清**

文案定稿一张表：id、玩家可见名、文本 key。战斗和关卡只引用这张表。堆积体分裂出的 id 和只数定一个，并写明这几只加不加入当波威胁。MVP 测试在表定稿前不要断言第五章名字。

---

## DI-16 `main` 上的总纲仍是车道玩法，不能拿来当塔防的预期

**出处**

- `main` 的 `docs/GDD.md`：小队穿过竖屏车道、门、基地建筑。`scenes/battle/battle_lane.tscn` 仍是不会动的车道
- PR #3 `docs/GDD.md`「明确不做」：车道、门、加人、基地建筑已作废
- PR #3「现在打开游戏会看到什么」：标题画面点开始仍进占位车道，那是脚手架，不是玩法

**问题**

在 PR #3 合并前，只读 `main` 的人会把「车道上显示小队人数」当成正确行为，把格子塔防当成做错了。现有 GUT 用例（`tests/unit/test_scenes.gd` 等）锁的是这块脚手架。塔防 PR 若没有改测试，CI 会继续保护旧画面。

**建议澄清**

合并顺序上，先让 PR #3 的总纲进入 `main`，或在塔防原型 PR 里写明「预期已从车道改为格子，旧场景测试应删除或改写」。QA 从本目录起，塔防预期以 PR #3 及战斗、关卡稿为准，不以 `main` 的 `docs/GDD.md` 为准。

---

## DI-17 「每关只教一件新事」和序章第 3 关、第一章第 1 关的教学内容对不上

**出处**

- PR #5 `docs/design/level/overview.md`「设计目标」：每一关只加一件新事
- 同文 24 关表：`prologue_03` 要学会「弯路上拐角和直路不是同一格」，同时又是「第一次三选一」
- 同表 `ch1_01`：要学会「雾里要贴着路放」，又要认识快残影（从第 6 波起）。`data/levels/ch1_01.json` 的 `teaches` 同时写了雾、快残影、以及通关后琪露诺才加入
- 同文四关节奏：第 1 关是教学，新残影只来很少；第 2 关没有新规则。按这句，快残影应算 `ch1_01` 的那一件新事，浓雾算不算第二件，文中没有拆开

**问题**

验收清单要求检查「每关只教一个新东西」。`prologue_01`（只会放置和自动攻击）和 `prologue_02`（只会魔理沙穿透）可以对着这一句打勾。`prologue_03` 和 `ch1_01` 若严格按「只一件」，则现在的关卡说明自己就不通过；若把「弯路加三选一」算成一件「序章毕业」，这句话又没有定义。测试员不能自己把两件并成一件。

**建议澄清**

给 `prologue_03` 和 `ch1_01` 各指定一个主教学点，另一个改成「提前看见、不要求会用」或挪到下一关。改完之后，`MVP_ACCEPTANCE.md` 里这两关的学习曲线才能打勾。其余五关仍按总览表那一行验收。

---

## 不单列、但验收时要避开的待定项

下面这些是文档自己标了「待你补充」或「待拍板」，没有和另一份文档打成相反的通过条件。验收清单里标待定即可，不要补数字：

- 结算画面的信息条目（过关与否、剩余生命、星级、局外资源）用户没有逐条改口，仍按制作人推荐当工作假设。画面和字体另有用户原话，见下面「结算画面」。星星解锁哪一套外观哪一段故事仍待定（PR #3 清单第 15 条）
- 结算画面（2026-10-02 用户原话：「结算画面显示给美术，要东方风梦幻mvp图片，字体也要灵活有游戏感和赛博朋克感。」）：画什么交给美术策划，字体交给动效师。图片要东方风、梦幻，供 MVP 用。字体要灵活，同时有游戏感和赛博朋克感。这和交接里 T-20「字体必须是东方风格」不是同一句，测试不选字体。好不好看由用户和动效师判断，测试不代替
- 局内 2 次升级每次提升什么（PR #3 清单第 10 条）。数值分支写了每次攻击 +40%，那是草案
- 强化池的最终名单（PR #3 清单第 11 条；PR #4 `buffs.json` 是草案）
- 符卡充能要打多少下、每张符卡的效果细节（PR #3 清单第 13 条）。PR #4 有占位系数，`rules.json` 有「普通约 60 秒、危急约 40 秒充满」的目标，不是已测过的定值
- 大妖精、蕾米莉亚、射命丸文、落野忘是否可玩（PR #2 待拍板清单）
- 第三章褪色村民算不算失败（PR #2、PR #5 都标待定）
- GitHub 免费发布算不算二次创作指南允许的渠道（PR #3 清单第 1 条）。这不是玩法测试
