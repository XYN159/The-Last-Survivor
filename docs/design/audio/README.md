# MVP 音频清单（《东方守幻录》）

> 东方 Project 二次创作。原作权利归上海爱丽丝幻乐团 / ZUN。本作免费、非商业，与官方无关。
> 目前没有人专门负责音频。`assets/audio/` 还是空的。这一页先把 MVP 要听到的声音列出来，方便以后找人或自己配。
> 资源表在 [audio_list_mvp.csv](audio_list_mvp.csv)。美术清单在 [../art/README.md](../art/README.md)。

`.gdignore` 让 Godot 不去扫描这个文件夹，避免把 CSV 当成翻译表导入。

## 听感

轻松和风，不吵。战斗里要听得清放置、受击和符卡，但不要压过 BGM 到刺耳。标题和神社、雾之湖的曲子偏安静；首领战可以稍紧一点，仍然不要金属噪音墙。

## 规格

| 项目 | 约定 |
| --- | --- |
| 音效 | `.wav` 或 `.ogg`。短，单声道 |
| BGM | `.ogg`，可以循环。胜利和失败是短乐句，不循环 |
| 采样率 | 44.1 kHz |
| 响度 | 大致按 LUFS。BGM 综合响度约 -18 LUFS。短音效不要顶到 0 dBFS，峰值留大约 1 dB。这是配的时候对照的约定，不是自动检查 |

循环点：BGM 的 `.ogg` 在 Godot 里打开循环后，用 `loop_offset` 指定从哪个采样重新开始。挑一段结尾和开头音量接近、最好落在波形过零的位置，避免「咔」的一声。文件本身如果带了循环元数据，导入后核对一下是不是这段。胜利、失败和全部音效不设循环。

## 命名和目录

- 音效：`sfx_…`
- BGM：`bgm_…`
- 音效放 `assets/audio/sfx/`
- BGM 放 `assets/audio/bgm/`

文件名只用小写英文字母、数字和下划线。

## Godot 导入

- BGM（要循环的那几首）：导入时打开循环。`.ogg` 看 `loop` 和 `loop_offset`。
- 音效，以及胜利、失败短乐句：关闭循环。`.wav` 的 `loop_mode` 用 Disabled。

## 总线

main 上的 `project.godot` 没有 `default_bus_layout`。Godot 默认只有一条 Master。

建议以后在开发 PR 里加 `default_bus_layout.tres`：Master 下面挂 **BGM** 和 **SFX** 两条。BGM 走 BGM，音效和界面声走 SFX，总音量仍由 Master 管。本 PR 不改工程。

## 许可

只用下面三类：

- CC0
- CC-BY（要在游戏「关于」页署名）
- 许可证原文写明可以免费使用，并且允许二次分发

禁止使用东方官方原曲和官方音效。东方原曲的同人编曲，只有编曲者明确授权时才能用。

每一项都登记到 [../art/CREDITS.md](../art/CREDITS.md) 的「音频」分区。没登记的不能进 `main`。

可以参考的公开来源（许可已核对过的才写在这里）：

- [Kenney 的游戏音频](https://kenney.nl/assets)（CC0），例如界面点击、打击、短乐句。用之前仍打开该包页面，确认这一包标的是 CC0。
- [OpenGameArt](https://opengameart.org/) 只挑页面上写明 CC0 或 CC-BY 的单首。不要按「免费」标签整包下载。许可写得含糊的不用。

## 和战斗演出怎么对上

触发时机尽量用战斗策划 `feedback.md` / `feel.json` 里的事件名，和 [../art/vfx_visual_spec.md](../art/vfx_visual_spec.md) 是同一套名字。表里「对应特效或界面 ID」一列写的就是这些名字。关卡上没有单独事件名的（例如延迟路线预告），备注里写了「待战斗策划」。

场景音乐按关卡数据的章节分：序章是神社（`chapter_id` = `prologue`），第一章是雾之湖（`chapter_id` = `ch1`）。首领战只在 `ch1_04`。一共 6 首：标题、神社、雾之湖、首领、胜利短乐句、失败短乐句。

P0 是 MVP 能玩起来必须听到的，控制在 25 条以内。其余放 P1。
