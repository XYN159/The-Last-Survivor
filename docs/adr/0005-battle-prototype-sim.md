# ADR-0005：塔防原型把规则和画面分开，数据先放在 data/prototype

- 状态：已接受
- 日期：2026-10-02

编号跳过 0003 和 0004。那两篇在还没合并的关卡设计分支上，避免和它们抢同一个文件名。

## 背景

标题画面的「开始」原来进入一条旧车道。战斗规则、关卡格式和画面尺寸都写在还没合并的设计分支里，main 上没有那些 JSON。如果把原型数字写进 `data/balance/` 或 `docs/design/`，和那些分支合并时会打架。

这一局要能放人、打怪、扣命、分出胜负，并且以后能无头跑完一整关，用来试关卡。画面上的闪白和飘字不能反过来影响结算。

## 决定

- 规则放在 `BattleSim`。它只认 tick，不认识按钮和颜色。画面脚本 `battle_board.gd` 每帧调用它，再把结果画出来。
- 伤害、波次、灵力和胜负的测试直接调用 `BattleSim`，不启动整幅画面。
- `scripts/battle/simulate_level.gd` 可以用无头 Godot 按关卡里的建议摆位跑完这一关。
- 原型数据放在 `data/prototype/`，字段名跟战斗表和关卡表一致。`CombatCatalog.USE_OFFICIAL_TABLES` 为 false。改成 true 后改读正式路径。
- 正式路径依赖三份都已经合并：#4 的 `rules.json`、`characters.json`、`enemies.json`、`feel.json`，#5 的 `data/levels`，#8 的 `stats.json` 和 `level_difficulty.json`。只合了其中一份就打开开关，会缺文件。
- 开关打开时，缺文件或缺关键字段用 `push_error`，不要悄悄填默认值。关键字段是攻击、费用、射程、间隔、血量、移速、护甲、漏怪伤害、血量倍率。
- 不改 `docs/design/`、`data/balance/`、`docs/GDD.md` 里标成「待你补充」的设定、`docs/ROADMAP.md`。
- 这一版不做符卡、结界、三选一，也不做「从当前波重来」，也不做刷怪窗口里的提前叫波。失败后只能整关再打，或回标题。
- `deploy_wait_for_player` 留到切正式序章之前再读。原型关用不上。

## 后果

- 调这一关的怪和费用，改 JSON 即可，不用改场景。
- 正式表三份都合并后才能把开关改成 true，并确认正式关卡里没有 `suggested_opening` 这个原型字段。开关打开后，缺文件或缺上面列出的关键字段会报错，不再用默认值顶上。
- 玩家能看见的字走 `locale/game_zh.csv`，在 `project.godot` 里登记。`enm_shade_fast` 的名字是「快残影」，key 是 `enemy.shade_fast.name`。
- 旧车道场景还留在仓库里，只是标题不再进入它。保护小队人数和物资的旧测试不再保留。
