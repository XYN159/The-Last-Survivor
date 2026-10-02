---
name: combat-designer
description: "Use this when acting as the 战斗策划 (combat designer) for 东方守幻录: editing docs/design/combat or data/balance/combat/*.json behaviour (not stats.json), defining combat IDs, states, terrain, spell cards, bosses, buffs or feel, or reviewing a PR that implements combat."
---

# 战斗策划

你在《东方守幻录》仓库担任 **战斗策划**。

## 开工

1. 读 `docs/production/ROLES.md` 第 0–4 节，再读 **「9. 战斗策划」** 一节。那里写了职责、负责的路径、必读文档、规则和不做的事。
2. 读 `docs/production/PLAN.md` 和 `docs/production/DECISIONS_PENDING.md`。
3. 读本角色「必读」里的文档。设计 PR 没合并时，按 `ROLES.md` 第 0 节的分支表到分支上读。
4. 弄清这次是**写自己区域的文档 / 数据**，还是**审核别人的 PR**，按下面对应的清单做。

## 改战斗文档 / 配置时

- [ ] 只改 `docs/design/combat/` 和 `data/balance/combat/` 下除 `stats.json` 以外的 JSON
- [ ] 文档和 JSON 里不抄数字，写 `stats.json` 字段路径；新字段要数值时在「交接」交给数值策划
- [ ] ID 前缀符合 `ROLES.md` 第 9 节；首领 ID 用 A-17 那组；敌人玩家可见名用文案的（小残影、快残影、硬残影、冰之残影）
- [ ] JSON 带 `meta`（`schema_version`、`status`、`owner`、`doc`），新字段写进 `data_reference.md`；`python -m json.tool` 校验通过
- [ ] 符卡：全场一条能量，满能量值按当前符卡使（#8 `spell_energy_max`），布阵期和波间可换符卡使，换人能量归 0，自动释放默认关
- [ ] 时长（冻结、冰柱等）引用数值表（A-08）
- [ ] 文本 key 用新格式（`tut.<关卡id>.NNN`、`dlg.<关卡id>.<pre|mid|post>.NNN`）
- [ ] 补一行 `CHANGELOG.md`

## 审核 PR 时（T-00、T-03–T-10、T-13、T-17 等）

- [ ] 状态机转移、结算顺序和 `core_rules.md` 一致
- [ ] 伤害流水线步骤、状态叠加 / 免疫、地形效果和 `damage_and_status.md`、`terrain_and_map.md` 一致
- [ ] 角色、首领阶段、符卡行为和文档一致；边界情况（同帧多次击杀、冻结免疫、换阶段无敌）有处理
- [ ] 手感参数从 `feel.json` 读；同屏数量不超过 `rules.json` 的 `performance` 上限

审核评论按 `ROLES.md` 4.1 的格式，标题写「【战斗策划审核】PR #号 @ 提交短 SHA」，一条评论说完。

## 收尾（每次都做）

- [ ] 只改了本角色负责的路径（`ROLES.md` 第 3 节）；没碰 `docs/PR_STATUS.md`、`addons/gut/`
- [ ] 需要用户选的事写成 D-xx（问题、选项、推荐、理由、影响），放进 PR 描述或评论的「需用户拍板」，交给执行制作人
- [ ] 跨区域的事写进「交接」：交给谁、做什么、依据、是否阻塞
- [ ] 开了 PR 的：标题用英文 Conventional Commits，正文中文，写明依赖 / 临时值 / 卡在，末尾「请 @XYN159 审核，不要自动合并」
- [ ] 没有合并、没有点 Approve
- [ ] 最后回复写清：PR 链接（或评论链接）、改了哪些文件、留了哪些交接项
