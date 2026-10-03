# 概念图来源

制作人已选定：**博丽灵梦 v2、雾雨魔理沙 v2、琪露诺 v2、八云紫 v2**（标准平涂）。紫的「半褪」沿用按 v2 画的 `yukari/yukari_halffaded.png`，不另画。

v1 和 v3 **未选**，文件留在这里作参考，不删除。四张已选的 v2 原图没有改过。

这些图还不是游戏里的正式立绘，不进 `assets/`。等美术规范 PR #6 合并后，再把要用的那几张登记进 `docs/design/art/CREDITS.md`。这一轮不改那份表。

## 怎么做的

| 项目 | 说明 |
| --- | --- |
| 工具 | Cursor 云端代理的内置生图。调用时没有返回底层模型的名字，这里不猜。 |
| 后期 | 用 Python（Pillow）从画面四边去掉浅奶油色背景，改成透明。白色衣服留着，没有抠穿。每张图右下角再贴一块 128×128 的棋盘格预览：按人物外接框缩进格子，浅奶油底，深紫黑描边，上面标了「128」。 |
| 总览 | `overview.png` 用 12 张立绘重排，不含右下角小格。说明文字用仓库里已有的 `assets/fonts/NotoSansSC-Regular.ttf`（SIL Open Font License 1.1）重新绘制。这次没有改字体文件本身。 |
| 参考图 | 没有使用官方立绘、游戏截图，也没有使用任何同人画师的作品。魔理沙、琪露诺、紫在对齐画风时，参考的是本轮自己生成的灵梦图，提示词写明不要抄红白巫女服。紫的半褪参考的是本轮自己的紫 v2。 |

半褪不是在 v2 上改像素，而是按 v2 重新生成的示意。脸、金发、软帽、紫白裙子、阳伞和扇子一致；扇子的高低和 v2 不完全相同。褪色只画在袖口、裙摆最下一圈和帽带边缘。

## 许可

- 东方 Project 的权利归上海爱丽丝幻乐团 / ZUN。这些图是《东方守幻录》的个人免费非商业概念稿。
- 原创生成。没有描图，没有拼贴，没有把官方素材或别人的画喂进模型。
- 图上没有写「官方」，也没有画低俗或丑化的内容。
- AI 生成：是。
- 没有使用来源或许可无法确认的素材。
- 用途：制作人已选定 v2。图仍只留在本仓库的概念目录里，不放进 `assets/`，不打进游戏。

## 文件

画风要点（三版之间要能看出来，不是只换姿势）：

| 版本 | 区别 | 状态 |
| --- | --- | --- |
| v1 | 大约 2 头身，描边最粗，几乎不画阴影，表情更开朗 | 未选，保留作参考 |
| v2 | 大约 2.5 头身，中等描边，一层硬边阴影，表情平稳。最接近风格指南。半褪按这一版 | 已选 |
| v3 | 大约 3.5 头身，描边更细，颜色略深，表情更有个性 | 未选，保留作参考 |

| 文件 | 内容 | 状态 |
| --- | --- | --- |
| `reimu/reimu_v1.png` | 博丽灵梦 v1 | 未选，保留作参考 |
| `reimu/reimu_v2.png` | 博丽灵梦 v2 | 已选 |
| `reimu/reimu_v3.png` | 博丽灵梦 v3 | 未选，保留作参考 |
| `marisa/marisa_v1.png` | 雾雨魔理沙 v1 | 未选，保留作参考 |
| `marisa/marisa_v2.png` | 雾雨魔理沙 v2 | 已选 |
| `marisa/marisa_v3.png` | 雾雨魔理沙 v3 | 未选，保留作参考 |
| `cirno/cirno_v1.png` | 琪露诺 v1 | 未选，保留作参考 |
| `cirno/cirno_v2.png` | 琪露诺 v2 | 已选 |
| `cirno/cirno_v3.png` | 琪露诺 v3 | 未选，保留作参考 |
| `yukari/yukari_v1.png` | 八云紫 v1，正常状态 | 未选，保留作参考 |
| `yukari/yukari_v2.png` | 八云紫 v2，正常状态（半褪的底稿） | 已选 |
| `yukari/yukari_v3.png` | 八云紫 v3，正常状态 | 未选，保留作参考 |
| `yukari/yukari_halffaded.png` | 八云紫半褪示意，按 v2 | 已选，沿用这张 |
| `overview.png` | 12 版排在一起，不含半褪。中文用 Noto Sans SC 绘制 | 说明图 |

单张都是 1024×1024 的 PNG，透明底，小于 2 MB。

## 生图提示词

提示词用英文，因为生图接口对英文更稳。负面要求写在同一段里：不要文字、不要水印、不要多余的人、手不要多指。

### 博丽灵梦 v1

A single full-body character concept of an original cute chibi shrine maiden, hand-drawn flat cel animation style, not 3D, not painterly, not pixel art. Extreme super-deformed proportion: about 2 heads tall, the round head is nearly half her total height, short stubby body and legs. Very thick even sticker-like ink outlines in deep purple-black. Almost no shading, only flat base color plus one hard-edged darker shadow. Face is symmetrical and adorable: huge glossy dark eyes with two white catchlights, tiny smile, soft pink blush, small nose dot. Jet-black hair with straight bangs and an enormous red hair bow behind the head, the bow has a thin gold edge and is a big readable silhouette. Costume: white kosode top, bright shrine-red pleated hakama skirt, red collar ribbon, and detached white sleeves floating separate from the shoulders with a clear gap, tied by thin red cords. White socks and simple red shoes. She holds a wooden gohei wand with white zigzag paper streamers in one hand; the other hand is a simple closed cute fist with a normal thumb, no extra fingers. Colors: vivid red, white, dark hair, gold bow edge. Standing front view, both feet fully visible, centered, generous empty margin. Background is a completely flat pale cream color, no scenery, no ground shadow, no pattern, no text, no letters, no watermark, no signature, no border, no UI. Exactly one person, two arms, two legs, two eyes, one mouth.

### 博丽灵梦 v2

A single full-body character concept of an original cute chibi shrine maiden, hand-drawn flat cel animation style, clean ink and flat color, not 3D, not thick paint, not pixel art. Classic chibi proportion about 2.5 heads tall: large cute head, short body, both feet visible. Medium-weight clean even outlines in deep purple-black. Flat colors with exactly one hard-edged shadow layer, slightly cooler and darker than the base, light coming from the upper left, plus one small hair highlight. No gradients, no realistic lighting. Face symmetrical and pretty: large refined dark eyes with a clear iris and catchlight, gentle closed-mouth smile, soft blush. Jet-black hair, straight bangs, shoulder length, enormous red bow at the back of the head with a thin gold trim, the bow is a signature silhouette. Costume clearly readable: white top, vivid shrine-red pleated skirt, red neck ribbon, detached puffy white sleeves floating off the shoulders (gap between shoulder and sleeve) tied with red cords, white socks, red shoes. Wooden gohei with white zigzag papers in her left hand. Other hand relaxed, correct simple fingers, no extra digits. Standing in a slight three-quarter view facing the viewer, calm and kind. Centered full body with margin. Background completely flat pale cream, empty, no scenery, no text, no watermark, no signature, no letters, no border. Exactly one character.

### 博丽灵梦 v3

A single full-body character concept of an original cute shrine maiden in a taller Q-style, still chibi not realistic. Proportion about 3.5 heads tall: big head but a slightly longer readable body and legs, both feet visible. Thin delicate clean ink outlines in deep purple-black, finer than a sticker style. Flat cel colors, one hard shadow only, slightly deeper muted shrine red and warm white, still obviously red-and-white, no airbrush gradients. Expression: focused and a little serious, small determined closed mouth, sharp pretty eyes, symmetrical face, not angry. Jet-black hair with straight bangs and a large red bow with a thin gold edge behind the head. White miko top, red pleated hakama, red collar ribbon, detached white sleeves clearly separated from the shoulders with red tying cords, white socks, red shoes. She holds a gohei wand with distinct white paper streamers. Hands are elegant and anatomically simple, no extra fingers. Standing pose with weight on one side, full body centered with margin. Background is flat pale cream only. No text, no letters, no watermark, no signature, no scenery, no border. Exactly one person.

### 雾雨魔理沙 v1

参考图：本轮 `reimu_v1`。Match ONLY the drawing style of the reference: thick deep-purple-black sticker outlines, extreme 2-head chibi, flat colors with almost no shading, cute symmetrical face, flat pale cream background, no text. Do NOT copy the reference character. Draw a completely different person: an original cute chibi witch girl. About 2 heads tall, round head nearly half her height. Long bright blonde hair, a side braid, huge cheerful smile, big glossy amber eyes. Tall black pointed witch hat with a wide brim and a white bow on the hat. Black dress, white blouse, white apron. She holds a wooden broom in one hand and a small golden octagonal furnace charm in the other. Hands are simple and correct, no extra fingers. Colors: black-purple dress, white apron, blonde hair. Standing front view, both feet visible, full body centered with margin. Background completely flat pale cream, no scenery, no text, no watermark, no letters, no signature. Exactly one character, two arms, two legs, two eyes.

### 雾雨魔理沙 v2

参考图：本轮 `reimu_v2`。Match ONLY the drawing style of the reference: medium deep-purple-black outlines, about 2.5-head cute chibi, flat cel color with one hard-edged cooler shadow, light from upper left, one small hair highlight, symmetrical pretty face, flat pale cream background, no text. Do NOT copy the shrine maiden. Draw a different character: an original cute chibi witch. Long golden-blonde hair with a side braid, confident closed-mouth smirk, large refined amber eyes. Black pointed witch hat with wide brim and a white ribbon bow. Black vest and skirt, white blouse and white apron. Wooden broom tucked at her side, small golden octagonal mini-furnace in one hand. Correct simple hands, no extra fingers. Standing slight three-quarter view, both feet visible, centered with margin. Background flat pale cream only. No text, no watermark, no letters. Exactly one person.

### 雾雨魔理沙 v3

参考图：本轮 `reimu_v3`。Match ONLY the drawing style of the reference: thin delicate deep-purple-black outlines, taller cute Q-style about 3.5 heads tall still chibi, flat cel with one hard shadow, slightly deeper colors, focused pretty face, flat pale cream background, no text. Do NOT copy the shrine maiden. Draw a different character: an original cute witch girl. Long bright blonde hair, one loose side braid, mischievous grin, sharp pretty amber eyes, symmetrical face. Black pointed wide-brim hat with a white bow, black dress, white collar and white apron, slightly warmer black fabric. She holds a broom and a small golden octagonal furnace. Hands elegant and correct, no extra fingers. Full body, both feet visible, centered with margin. Background flat pale cream. No text, no watermark, no letters, no scenery. Exactly one character.

### 琪露诺 v1

参考图：本轮 `reimu_v1`。Match ONLY the drawing style of the reference: thick sticker outlines, extreme 2-head chibi, flat color, cream background, cute symmetrical face, no text. Do NOT copy the shrine maiden outfit. Draw a different character: a small wholesome child ice fairy, fully clothed in a modest blue dress, innocent and cheerful, like a children's picture book. About 2 heads tall. Short aqua-blue bob hair with a tiny cowlick and a very large blue hair bow on the side of the head. Huge happy smile, big glossy blue eyes. Modest blue dress with a white collar and white puffy short sleeves, light-blue trim, skirt to the knees, fully covered, no bare midriff. Large crystalline ice wings spread behind her, pale icy blue, a clear wide silhouette. She holds a small simple ice crystal. Simple correct hands, no extra fingers. Standing front view, both feet visible, centered. Background flat pale cream. No text, no numbers, no watermark, no letters. Exactly one child character in a wholesome pose.

### 琪露诺 v2

参考图：本轮 `reimu_v2`。Match ONLY the drawing style of the reference: medium outlines, 2.5-head chibi, one hard shadow, cream background, pretty symmetrical face, no text. Do NOT copy the shrine maiden. Draw a small wholesome child ice fairy, fully clothed, modest, innocent. Short light-blue bob, big blue ribbon bow, bright friendly smile, refined blue eyes. Modest blue dress with white collar and white sleeves, light-blue ribbon, knee-length skirt, no bare midriff. Crystalline translucent ice wings spread wide behind her so the silhouette is obviously winged. Small ice flake in one hand. Correct simple hands. Both feet visible, centered, flat pale cream background. No text, no numbers, no watermark. Exactly one wholesome child character.

### 琪露诺 v3

参考图：本轮 `reimu_v3`。Match ONLY the drawing style of the reference: thin delicate outlines, taller Q-style about 3.5 heads, one hard shadow, cream background, no text. Do NOT copy the shrine maiden. Draw a small wholesome child ice fairy, fully clothed and modest. Short aqua bob hair, large blue bow, proud cute pout (not angry, not mean), sharp pretty blue eyes, symmetrical face. Blue dress a little deeper in color, white collar, white puffy sleeves, light-blue ice-crystal trim, knee-length, no bare midriff. Clear ice-crystal wings spread to both sides. Hands correct, no extra fingers. Full body both feet visible. Flat pale cream background. No text, no numbers, no watermark, no letters. Exactly one wholesome child.

### 八云紫 v1

参考图：本轮 `reimu_v1`。Match ONLY the drawing style of the reference: thick sticker outlines, extreme 2-head chibi, flat colors, cream background, cute symmetrical face, no text. Do NOT copy the shrine maiden. Draw a different character: an elegant adult woman in a long modest dress. About 2 heads tall chibi. Long wavy golden-blonde hair. White soft mob cap with a bright red ribbon. Gentle smile, large glossy violet eyes, face fully visible and not covered. Long purple and white dress: purple tabard, white blouse, long purple skirt with a white frill at the hem, fully clothed, no cleavage focus. In one hand an open lavender-pink parasol with a white frill; in the other a closed folding fan held down at her side so the face stays clear. Simple correct hands, no extra fingers. Standing front view, both feet visible, centered. Background flat pale cream. No text, no watermark, no letters, no eyes in the background. Exactly one adult woman.

### 八云紫 v2

参考图：本轮 `reimu_v2`。Match ONLY the drawing style of the reference: medium outlines, 2.5-head chibi, one hard-edged shadow, cream background, pretty symmetrical face, no text. Do NOT copy the shrine maiden. Draw an elegant adult woman, fully clothed in a long modest purple-and-white dress. Long wavy golden-blonde hair, white lace-trimmed mob cap with a red ribbon bow. Calm mysterious closed-mouth smile, refined violet eyes, entire face visible. Purple tabard over a white blouse, long purple skirt, white hem frill. Open lavender parasol with white frill in one hand, folding fan held low in the other, fan does not cover the face. Correct hands. Both feet visible, slight three-quarter stance, centered. Flat pale cream background. No text, no watermark, no letters, no background eyes. Exactly one person.

### 八云紫 v3

参考图：本轮 `reimu_v3`。Match ONLY the drawing style of the reference: thin delicate outlines, taller Q-style about 3.5 heads, one hard shadow, slightly deeper colors, cream background, no text. Do NOT copy the shrine maiden. Draw an elegant adult woman in a long modest dress. Long golden-blonde wavy hair, white soft cap with a red ribbon, knowing gentle smile, sharp pretty violet eyes, face fully visible and symmetrical. Deeper purple dress with white blouse and white hem frill, fully clothed. She holds a lavender parasol and a folding fan lowered beside her, not covering her face. Correct elegant hands, no extra fingers. Full body, both feet visible, centered with margin. Flat pale cream background. No text, no watermark, no letters, no background pattern of eyes. Exactly one adult woman.

### 八云紫半褪（按 v2）

参考图：本轮 `yukari_v2`。Edit the reference character into the same picture with one costume change only. Keep the exact same person, face, hair, pose, parasol, fan, mob cap, purple-and-white dress, line weight, and flat cream background. She stays fully opaque, solid, and colorful, not a ghost, not transparent, not gray overall, not faded like a faded photo. Change ONLY these edges to a flat desaturated gray: the sleeve cuffs (the bands at the ends of both sleeves) become gray, the very bottom hem edge of the skirt becomes a gray trim, and the outer edge of the red hat ribbon becomes slightly gray. The main purple dress, golden hair, face, red ribbon body, parasol, and fan stay vivid and saturated. No text, no watermark, no extra people, no extra limbs.
