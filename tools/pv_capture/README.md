# 宣传 PV 实机录制

给 60 秒玩法 PV 录 R1–R9。这里只新增演示脚本，不改战斗规则、不改数值、不加灵力。

演示按真实灵力顺序走：开局 150，灵梦 50，第二位 75，第三位 100，升级 40 然后 80。开局只够放两位。第三位和升级要等击散残影攒够灵力。

视频和对照表不要提交进仓库。`record_all.sh` 默认写到 `/opt/cursor/artifacts/pv/`。

## 录一段

先装 Godot（版本以仓库根目录的 `godot-version.txt` 为准）：

```bash
ci/install_godot.sh
```

再录。不要加 `--headless`，否则画面是黑的。脚本会自己开 `xvfb-run`，并用 OpenGL3（这台机器没有 Vulkan）。

```bash
tools/pv_capture/record_all.sh test
tools/pv_capture/record_all.sh R3
tools/pv_capture/record_all.sh all
```

`test` 是 2 秒测试片，用来确认不是黑屏。`all` 会把 R1–R9 都录完。R9 是 R3、R5 的 2560×1440 版。

每一段旁边有一份 `Rn_timeline.txt`：第几秒点了什么，后期按它对拍子。

## 片段

| 命令里的名字 | 画面 |
| --- | --- |
| R1 | 主界面 → 出击 → 章节 → 关卡地图 → 关卡详情 → 编队 → 剧情页 |
| R2 | 进关暗幕和上下栏，停在布阵 |
| R3 | 第一位灵梦，直路中段左 |
| R4a | 第二位，直路中段右 |
| R4b | 第三位，靠入口。要等灵力够 100 |
| R5 | 把正对残影的灵梦升到 Lv3，看三轮三张符札 |
| R6x2 / R6x1 | 第 3 波混战，×2 和 ×1 各一份 |
| R7 | 最后几只残影、结算卡，再点「继续」看结算原画 |
| R8 | 单独一局，只放一位，让残影走到赛钱箱 |
| R9place / R9upgrade | R3、R5 的 2560×1440 |

战斗片段直接打开 `scenes/battle/battle_board.tscn`（关卡 `prologue_01`），不播关前视频。点击用 `Input.parse_input_event`，坐标取按钮或格子的实际位置（界面流程的按钮就是 `data/ui/original_screens.json` 里的点击区）。不显示鼠标。

镜头不推不摇。每段前后尽量多留约 1 秒。R2 的进关从第一帧就开始，前面没有可垫的 1 秒。
