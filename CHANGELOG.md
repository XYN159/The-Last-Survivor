# 更新日志

格式遵循 [Keep a Changelog](https://keepachangelog.com/zh-CN/1.1.0/)，版本号遵循[语义化版本](https://semver.org/lang/zh-CN/)。

## [Unreleased]

### 变更

- 2026-10-03 按用户拍板改战斗文档：射程改为格子加朝向；波次改为连续时间轴（Q2）；放置改为点格子、点头像、再选方向，同名只能一个（Q3、Q3b）；局内升级改为撤退再部署（Q6）；伤害保底改为 5%，通用暴击去掉（Q14）；共用符卡条删除，符卡名挂到角色技能（Q5）；Boss 漏过扣 2 命（Q4），两阶段、冻结减半、不免疫待 P4，三阶段钻石风暴标为旧稿待 P4；主线三选一和局内强化池移出主线，留给肉鸽（Q12）。四人机制细则待 P2。PR #15 曾把 D-05、D-06、D-18、D-19 写成锁定，用户并没有拍这四条，战斗文档不再把它们写成已定。
- （已更正，见上一条，不再当已定）2026-10-02 文档曾记下：冰之残影第三阶段用雪符「钻石风暴」；被冻住的角色不能连点破冰；MVP 先做符札引爆，以及寒气、分裂弹、会心、锐利、连射、充能、修补；刷怪窗口里可以叫下一波；美铃放在紧贴路线的 `.` 格。
- 波次空档改为固定 4 秒，从 20 秒刷怪窗口结束起算，不再用 3 到 5 秒，也不再从最后一只出生起算。叫波奖励一次最多 20。
- 对外名称从 The Last Survivor（最后的幸存者）改为《东方守幻录》。英文仓库名是 touhou-forgotten-defense。定位改为东方Project 同人、个人免费非商业的竖屏角色塔防，不是弹幕射击。调试 APK 文件名改为 `touhou-forgotten-defense-*`，Android 包名改为 `com.xyn159.touhouforgottendefense`。
- GitHub 首页的 `README.md` 整份改写成《东方守幻录》的介绍。

### 新增

- 加入东方同人塔防的战斗规则草案（`docs/design/combat/`）和配置表（`data/balance/combat/`）。游戏尚未读取。数值不在这批表里，全部引用数值策划 PR #8 的 `stats.json`，需先合 PR #8。

### 变更

- 战斗草案记下制作人和用户拍板的条目：符卡使方案 A+（换人清能量）、同名角色最多 3 个、MVP 冻结来源、紫在 `ch1_03` 第 6 波用隙间演示并于 `ch1_04` 打完加入、Boss 扣生命后折返、强化 2 层质变且每 5 波三选一只管当局、失败可从当前波的快照重来、符卡自动释放是全局开关、角色只能放在地图的 `.` 槽位。
- 2026-10-02 对齐 PR #8、PR #5、PR #9 和 PR #2：删掉草案自带的 `stats.json`，规则只写 PR #8 的字段名；漏怪伤害读 `bosses` 段；能量满值按符卡使读 `spell_energy_max`；多发攻击的攻击和护甲都按发数平分；冻结时长交给数值；灵梦默认符卡改为 梦符「封魔阵」；美铃改成阻挡 2 个敌人；硬残影进 MVP（只在 `ch1_03`）；魔理沙改为 `prologue_01` 打完加入；残影名和文本 key 跟随 PR #2 术语表（如小残影、`enemy.shade_basic.name`、`enemy.boss_cirno.name`）；新增 MVP 之后的扑人残影、飞行残影。
- 琪露诺在第一章第 1 关 `ch1_01` 打完后加入。第一章 Boss 是冰之残影（琪露诺的复制体，ID 仍是 `boss_cirno`）。地图字母和关卡策划 PR #5 一致：`P` 是路线，`.` 是可放置。
- 建立 Godot 4.7.2 竖屏工程，包含标题画面和占位战斗车道。
- 加入 GDScript 格式检查、GUT 单元测试，以及调试版 Android APK 的持续集成。CI 固定在 Ubuntu 24.04 上运行。
- 写好协作文档、玩法草案、架构说明和架构决定记录。
- 加入 Cursor 工作区配置（推荐 godot-tools、语言服务器端口 6005、从编辑器启动游戏），并写好每天并排改游戏的说明 `docs/DEV_LOOP.md`。
- 把 Cursor 里的 Godot 路径改成这台 Windows 电脑上的 `D:/Godot_v4.7.2-stable_win64.exe/Godot_v4.7.2-stable_win64.exe`。

[Unreleased]: https://github.com/XYN159/touhou-forgotten-defense/compare/main...HEAD
