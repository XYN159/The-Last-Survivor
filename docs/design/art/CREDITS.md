# 素材来源和许可证登记

> 本作是 東方Project（东方 Project）的二次创作同人游戏。东方 Project 的原作权利归 上海アリス幻樂団（上海爱丽丝幻乐团）/ ZUN 所有。本作为个人制作的免费作品，与官方无关，不以营利为目的。本作不使用任何官方素材（立绘、音乐、截图、游戏内素材等）。
> 依据：ZUN《東方Projectの二次創作ガイドライン》（2024-05-31 更新，<https://touhou-project.news/guideline/>）。

## 规则

1. **游戏里用到的每一个图片、字体、特效贴图都要在下表登记一行**，包括自己画的和占位图。音乐、音效以后也登记在这里（或另开一张同样格式的表）。
2. 没登记的素材不能合并进 `main`。
3. **不登记、也不使用**任何官方游戏素材，或从别的同人作品截取的图。
4. 第三方素材：把许可证原文放在素材旁边（例如 `assets/fonts/OFL.txt`），或者在「许可证文件 / 存档」一列写清存档位置（下载页截图、保存的网页）。
5. CC-BY 类许可证要求署名的，按「作者」和「来源链接」两列在游戏的「关于」页里显示。
6. AI 生成的图，「AI 生成」一列写「是」，并在 GitHub Release 发布页说明。
7. 换掉一个素材时，不删旧行，把旧行的「状态」改成「已替换」，再加新行。

## 登记表

| 资源 | 文件路径 | 作者 / 来源 | 来源链接 | 许可证 | 许可证文件 / 存档 | 是否修改 | AI 生成 | 状态 | 登记日期 | 备注 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Noto Sans SC Regular（子集） | `assets/fonts/NotoSansSC-Regular.ttf` | Adobe（Copyright 2014-2021 Adobe, with Reserved Font Name 'Source'），Google Fonts 发布 | <https://fonts.google.com/noto/specimen/Noto+Sans+SC> | SIL Open Font License 1.1 | `assets/fonts/OFL.txt` | 是：只保留基本拉丁、中日韩统一表意文字（U+4E00–U+9FFF）等常用区的子集 | 否 | 使用中 | 2026-09-27 | 界面中文字体，由 `scripts/autoload/app_theme.gd` 加载。子集不含 ★ ☆ ♪ |
| 工程图标 | `icon.svg` | 脚手架自带，仓库自制 | — | 随仓库 | — | — | 否 | 使用中（待替换） | 2026-09-27 | 旧题材的图标，换成《东方守幻录》图标时改这一行 |

<!--
新增一行时复制下面的模板：
| 资源名 | `assets/textures/...` | 作者名 / 自制 | 链接或 — | CC0 / CC-BY 4.0 / 自制 / ... | 许可证文件路径或存档说明 | 否 / 是：改了什么 | 否 / 是 | 占位 / 草稿 / 使用中 / 已替换 | YYYY-MM-DD | 用途等 |
-->

## 不在游戏安装包里的第三方内容（仅记录）

| 内容 | 路径 | 许可证 | 说明 |
| --- | --- | --- | --- |
| GUT 测试插件及其自带字体 | `addons/gut/`（字体许可证 `addons/gut/fonts/OFL.txt`，插件许可证 `addons/gut/LICENSE.md`） | MIT；字体 SIL OFL 1.1 | 只用于单元测试，导出时被排除（见 `docs/ARCHITECTURE.md`「导出」） |
