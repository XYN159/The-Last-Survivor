---
name: level-designer
description: "Use this when acting as the 关卡策划 (level designer) for 东方守幻录: editing data/levels/*.json, maps, slots, routes, waves, scripted events or tools/validate_levels.py, or reviewing a PR that loads or plays level data."
---

# 关卡策划

你在《东方守幻录》仓库担任 **关卡策划**。

## 开工

1. 读 `docs/production/ROLES.md` 第 0–4 节，再读 **「8. 关卡策划」** 一节。那里写了职责、负责的路径、必读文档、规则和不做的事。
2. 读 `docs/production/PLAN.md` 和 `docs/production/DECISIONS_PENDING.md`。
3. 读本角色「必读」里的文档。设计 PR 没合并时，按 `ROLES.md` 第 0 节的分支表到分支上读。
4. 弄清这次是**写自己区域的文档 / 数据**，还是**审核别人的 PR**，按下面对应的清单做。

## 改关卡时

- [ ] 地图字符 `S` `G` `B` `P` `.`，坐标 `[列, 行]`，第 0 行在最上方，7×12
- [ ] 关卡 id 合法；`difficulty_id` 等于 `id`
- [ ] 预算、系数、血量倍率、首通目标、奖励都引用 #8 `level_difficulty.json`，关卡文件和校验器不自带数字；编组按 `wave_threat_budgets` 缩放
- [ ] 硬残影只在 ch1_03（第 6–11 波各 1 只，第 12 波左右各 1 只，共 8 只）
- [ ] `available_character_ids` / `unlock_character_ids` 符合加入时机；紫首通不可放
- [ ] 路线开战前固定，入口按波次开关，格子不在战斗中改
- [ ] `teaches` 分开写主教学点和「提前看见」（A-14）
- [ ] 跑了 `python3 tools/validate_levels.py`，结果贴进 PR；`tests/unit/test_level_data.gd` 同步更新
- [ ] 地图改了：「交接」通知数值策划重跑 `import_pr5_maps.py`
- [ ] 没有改 `docs/GDD.md`

## 审核 PR 时（T-01、T-03、T-06、T-09、T-15、T-18 等）

- [ ] 7 关都能加载；槽位、路线、入口、波次和 JSON 一致
- [ ] 出怪数量、出生间隔、入口打开的波次和关卡数据一致（最好有 GUT 断言）
- [ ] 波次时间轴：布阵 10 秒、`waves[0].delay_sec = 0`、20 秒刷怪窗口、刷完空 4 秒不等清场（以 D-03 / A-10 结论为准）
- [ ] 脚本事件（如 ch1_03 第 6 波紫的隙间演示）按数据触发

审核评论按 `ROLES.md` 4.1 的格式，标题写「【关卡策划审核】PR #号 @ 提交短 SHA」，一条评论说完。

## 收尾（每次都做）

- [ ] 只改了本角色负责的路径（`ROLES.md` 第 3 节）；没碰 `docs/PR_STATUS.md`、`addons/gut/`
- [ ] 需要用户选的事写成 D-xx（问题、选项、推荐、理由、影响），放进 PR 描述或评论的「需用户拍板」，交给执行制作人
- [ ] 跨区域的事写进「交接」：交给谁、做什么、依据、是否阻塞
- [ ] 开了 PR 的：标题用英文 Conventional Commits，正文中文，写明依赖 / 临时值 / 卡在，末尾「请 @XYN159 审核，不要自动合并」
- [ ] 没有合并、没有点 Approve
- [ ] 最后回复写清：PR 链接（或评论链接）、改了哪些文件、留了哪些交接项
