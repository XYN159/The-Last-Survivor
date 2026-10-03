# ADR-0009：标题画面先用霞鹜文楷，战斗顶栏改成状态条

- 状态：提议
- 日期：2026-10-03

## 背景

美术交了战斗 HUD 与标题画面的规范和四张图：竖版灵梦立绘 `reimu_portrait.png`（720×960）、状态条框 `bar_frame.png`、按钮底板 `button_plate.png` 和等级名牌 `level_plate.png`。规范要求：

- 左下角立绘完整显示（Contain），不能像以前那样铺满裁切，把蝴蝶结和头顶裁掉。
- 灵力、生命、波次／布阵是三条带颜色填充的状态条，文字是真实文字，不烘焙进图片。
- 标题画面中文和小号英文都用霞鹜文楷（LXGW WenKai），任意两行之间不少于 14 px，禁止负行距。

ADR-0007 当时把霞鹜文楷留给 T-20 的全局主题。

## 决定

- 霞鹜文楷 v1.521 Regular 放进 `assets/fonts/LXGWWenKai-Regular.ttf`，许可证原文在 `assets/fonts/LXGWWenKai-OFL.txt`（SIL OFL 1.1）。
- 字体只通过场景主题挂在三处：标题画面根节点 `MainMenu`、战斗顶栏 `TopBar`、选中单位面板 `UnitPanel`。全局 `AppTheme` 仍然是 Noto Sans SC，其余战斗文字不变。T-20 统一主题时再决定要不要全局换字体，并另写 ADR。
- 三条状态条：深色凹槽 `ColorRect`，上面一层从左往右的彩色填充，再盖 `bar_frame.png` 的九宫格（左右锁 72 px），最上面是原来的 `%SpiritLabel`、`%LifeLabel`、`%WaveLabel`。填充长度在 `battle_board.gd` 的 `_refresh_bars()` 里改 `anchor_right`。
  - 生命 = 当前生命 ÷ 最大生命。
  - 灵力 = 当前灵力 ÷ max(开局灵力, 当前灵力)。花掉就变短，攒得比开局多就保持满条。不在数值表里新增灵力上限。
  - 波次／布阵 = 剩余秒数 ÷ 这段计时的总长。`BattleSim.view_state()` 新增只读字段 `phase_duration`，每次给计时器赋新值时一起记下；没有计时（最后一波）时为 0，条显示满。它不参与 `tick()`、奖励和出波时间。
- 原来的顶部大框 `TopFrame` 去掉。三条状态条自带框，再套一个大框会框中套框。
- 立绘槽是 210×280 的竖版 3:4，`stretch_mode` 用 `KEEP_ASPECT_CENTERED`。旧的横版 `portrait_frame.png` 形状不对，不再盖在立绘上，改用一圈细边的深色底板垫在立绘外面。旧图 `reimu_portrait.jpg` 和 `portrait_frame.png` 暂时留在仓库里。
- 单位面板：等级行垫 `level_plate.png`；「升级」「出售」「关闭」三个按钮用空样式，`button_plate.png` 作为按钮的子节点并打开 `show_behind_parent`，画在文字下面。按钮底板按 3:1 原比例等比缩放，不用九宫格拉宽，免得角花挤到文字。

## 后果

- 标题和顶栏、单位面板的字体和其他战斗文字不同。这是有意的过渡状态。
- 霞鹜文楷完整字库约 25 MB（Git LFS），安装包会变大。以后需要时可以和 Noto 一样做子集。
- 规范里的低量警示（生命低于 25% 呼吸变色、倒计时最后 10 秒变橙）这次没做，条始终用主色。
- `tests/unit/test_battle_board.gd` 检查立绘路径和拉伸方式、三条文字和填充比例、单位面板的底板；`tests/unit/test_scenes.gd` 检查标题的行距不为负、字体是霞鹜文楷。
