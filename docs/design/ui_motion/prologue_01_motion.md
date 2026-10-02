# 序章第一关动效说明

这份文档归动效师。它说明「神社的直路」（`prologue_01`）里每个反馈什么时候出现、长什么样、避开了哪里，以及时长写在哪个字段。

玩法数字和波次规则不在这里，也没有改。背景插画归美术策划，这里只管东西怎么动。

## 总规则

- 样子只用三种东西：符札（纸色长条、朱红边、朱印）、结界（朱红和纸色的同心环，带刻度）、和风光点（暖金或灵力青的圆点，带柔光）。不用准星、扫描线、数字故障这类科幻样子。
- 动效不挡路线，不挡生命。路线是第 3 列，生命在顶栏中间。暗角只压左右两边和底部，顶部一点不压，见 `assets/shaders/edge_vignette.gdshader`。
- 竖屏 1080×1920。棋盘区域是 (92, 140) 到 (988, 1676)，每格 128 像素。
- 战斗里的特效跟着「真实时间 × 倍速」走，倍速 ×2 时特效也快一倍。界面动效（按钮、栏、结算）只跟真实时间走，倍速不影响手感。
- 颜色沿用 PR #6 `ui_visual_spec.md` 的色板：和纸白 #F5EFE2、朱红 #C8323C、墨 #2B2B33、金 #D4A94F、灵力 #5CCBF0、生命 #E8505B。
- 没用明日方舟或东方 Project 的官方素材。所有形状都是代码画的圆、线和矩形。

## 时长放在哪里

| 文件 | 内容 | 状态 |
| --- | --- | --- |
| `data/prototype/ui_motion.json` | 进关、放置、按钮、受击、提示、结算、离场的时长和幅度 | 临时。动效师先给，正式数字等数值策划（#8）定，定了只改这份文件 |
| `data/prototype/combat/feel.json` | 闪白、伤害数字、击杀光点、灵力栏弹跳、升级闪光 | 新加的 `heavy_pop_scale`、`kill_burst`、`spirit_counter_bump`、`level_up` 照抄 PR #4 `cursor/docs-combat-rules-354a` @ `ad8ab29`，同样是临时 |

脚本里只留读不到文件时的保底值，和 JSON 里一样。读表用 `MotionConfig`（`scripts/ui/motion_config.gd`）。

## 一、进关

触发：标题点「开始」，或结算点「再打一次」。

| 顺序 | 玩家看见 | 字段（`ui_motion.json` 的 `entry`） |
| --- | --- | --- |
| 1 | 上一个画面先合上一层暗幕（标题按钮按下后约 0.25 秒）。新画面一出来，暗幕从全黑淡开 | `veil_fade_sec`；离场是 `transition.leave_sec` |
| 2 | 顶栏从上方滑进来，底栏从下方滑进来；棋盘同时淡入 | `bar_slide_sec`、`board_fade_sec` |
| 3 | 左边空地上垂下一张竖写的关名符札「神社的直路」，带一根挂绳和朱印，落下时轻轻摆两下，停一会儿后上提淡出 | `ofuda_delay_sec`、`ofuda_drop_px`、`ofuda_drop_sec`、`ofuda_hold_sec`、`ofuda_fade_sec` |
| 4 | 守护点上张开一圈结界环（朱红外环、纸色内环、12 道刻度），然后散掉 | `barrier_delay_sec`、`barrier_sec` |
| 5 | 三个可放置格子依次亮一下，像有人用灯扫了一遍 | `slot_sweep_step_sec`、`slot_sweep_sec` |

避开：符札挂在第 0、1 列（不能放置的空地），y 从 216 开始，在顶栏下面，不碰第 2 列的格子和第 3 列的路线。玩家一按「开始」，符札提前 0.4 秒淡掉，不和战斗抢注意力。

## 二、可放置格子和选格

- 空着的可放置格子一直在「呼吸」：淡金色 #FFF3B0，亮度在 14% 到 34% 之间来回，一个来回 0.8 秒（PR #6 的格子光规格）。字段 `slot.breath_sec`。
- 点中一格：选框从外向里收紧到格子上。选框是墨色细描边、5 像素金边、里面一圈纸色细线，四个角各一枚朱印小方块。字段 `slot.select_snap_sec`。
- 已经放了角色的格子不再呼吸，免得和角色抢。

## 三、放下角色

触发：选好格子后点角色头像，放置成功。

| 玩家看见 | 字段 |
| --- | --- |
| 角色从 1.35 倍大「按」到 1 倍，最后稍微压扁再弹回，像盖章 | `place.land_sec`、`place.land_from_scale` |
| 脚下张开一圈封印环：朱红外环、纸色内环、8 道转动的刻度，四张小符札向四角飞出并转动 | `place.seal_sec` |
| 6 颗暖金光点从格子里飘起来 | `place.mote_count`、`place.mote_sec` |
| 灵力数字闪金并弹一下 | `feel.json` 的 `spirit_counter_bump` |

放置失败（没选格子、灵力不够、点了路线格）时，底部提示文字左右抖一下并闪淡红，字段 `hint.shake_px`、`hint.shake_sec`。提示换字时淡入，字段 `hint.fade_sec`。

升级：角色弹大一下，格子上一圈金环扩散，字段 `feel.json` 的 `level_up`。卖出：格子上一圈灰环，6 颗灰色光点飘散，字段 `sell.mote_count`、`sell.mote_sec`。角色面板打开时从 0.9 倍弹出，字段 `panel.pop_sec`。

## 四、按钮按下

所有战斗按钮（角色头像、开始、倍速、升级、卖出、再打一次、返回标题）和标题的「开始」都挂了同一个 `ButtonMotion`。

| 玩家看见 | 字段（`button`） |
| --- | --- |
| 手指移上去放大到 1.05 倍（禁用的按钮不放大） | `hover_scale` |
| 按下缩到 0.94 倍 | `press_scale`、`press_sec` |
| 松开带一点回弹地恢复 | `release_sec` |
| 点成功时整块闪一层纸白光，四角的金色括角向外张开 | `flash_sec`、`ring_px` |

结算卡上的按钮样式在 `assets/themes/ofuda.tres`：「再打一次」是朱红底，「返回标题」是纸色底朱红边，按下时颜色变深。底栏按钮的底色这一轮没换，仍是引擎默认样子，等 T-20 统一主题。

## 五、打中和受击

| 情况 | 玩家看见 | 字段 |
| --- | --- | --- |
| 角色打中敌人 | 敌人身上闪白（原有）。命中点溅出 3 颗金色小光点 | `feel.json` 的 `hit_flash`；`hit.spark_count`、`hit.spark_sec` |
| 伤害数字 | 从 0.6 倍弹到 1 倍，最后 0.2 秒淡出。重击弹到 1.4 倍 | `damage_number.pop_sec`、`from_scale`、`fade_sec`；`feel.json` 的 `heavy_pop_scale` |
| 敌人被打倒 | 原地一圈灰色散环，然后 6 颗灵力青光点沿弧线飞向顶栏的灵力数字；到达时灵力数字闪金弹一下 | `kill.puff_sec`；`feel.json` 的 `kill_burst`、`spirit_counter_bump` |
| 敌人漏到守护点 | 守护点一圈红色结界裂开（红环加 6 道裂纹）；生命数字左右抖并闪红；左右两边和底部压一层暗红 | `guard_hit.ring_sec`、`shake_px`、`shake_sec`；暗红是原有的 `feel.json` `guard_damage_vignette`，这一轮改成只压边缘 |
| 新一波开始 | 顶栏波次文字闪金放大一下 | `wave_label.pop_scale`、`wave_label.pop_sec` |

同时在飞的光点最多 60 颗（`kill_burst.max_active_orbs`）。超过时少飞几颗，但每颗放大到 1.5～2 倍，让玩家仍然看得出「打倒了一只」。

避开：光点的弧线从敌人身上往上走，不停在路线上。受击的暗红只在左右边缘，生命数字本身不被盖住。

## 六、结算出现

触发：最后一波打完还有生命（守住了），或生命归零（失守了）。

| 顺序 | 玩家看见 | 字段（`result`） |
| --- | --- | --- |
| 1 | 画面压暗 | `dim_sec` |
| 2 | 结算卡片像一张符札从中间一条线上下展开：纸色底、朱红边、里面一圈金线，左上角一枚朱印 | `card_sec` |
| 3 | 标题从 1.4 倍「盖」下来。守住了是朱红字，失守了是灰字 | `title_delay_sec`、`title_from_scale`、`title_sec` |
| 4 | 标题四周画出一圈结界：24 段虚线弧和一圈细环，8 张小符札绕着慢慢转。守住了是金色，失守了是灰色 | `seal_sec`、`seal_spin_per_sec` |
| 5 | 关卡名、生命和灵力，以及「再打一次」「返回标题」按钮依次浮上来 | `button_delay_sec`、`button_stagger_sec`、`button_sec` |
| 6 | 背后飘和风光点：守住了是暖金色往上飘，失守了是灰色往下落 | 粒子写在场景 `ResultMotes` 上，数量 16，寿命 3 秒 |

点「再打一次」或「返回标题」：暗幕合上 0.25 秒再换画面（`transition.leave_sec`）。

## 不在这一轮

这些仍归 T-20，这一关没做：

- 完整的霞鹜文楷字体（现在仍是 Noto Sans SC 子集）
- 金色标题字
- 三十个樱花粒子

## 截图怎么重拍

```bash
MOTION_CAPTURE_DIR=/tmp/motion godot --path . --resolution 1080x1920 -s res://tests/capture/motion_capture.gd
```

脚本按真实时间跑一局守住、一局失守，在动效播到一半时存 11 张图。它跳过了等待，战斗是瞬间算完的，所以有几张图里关名符札还没淡出，真实游戏里开战时它已经淡掉了。

## 来源

- PR #4 `cursor/docs-combat-rules-354a` @ `ad8ab29`：`feel.json` 的击杀光点、灵力栏弹跳、升级闪光、重击数字倍率
- PR #6 @ `fe0f3d5`：`ui_visual_spec.md` 的色板和格子呼吸光，`vfx_visual_spec.md` 的伤害数字和击杀光点，`art_style_guide.md` 的放置「落下压扁」
