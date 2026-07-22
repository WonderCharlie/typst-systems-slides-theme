# Systems Slides Template 完整用户指南

这份指南是 Deck 作者的统一入口。它从安装、初始化和第一份演示开始，逐步进入原生
Typst 内容、Theme 页面、布局、渐进展示、页面层、演讲者工具和调试。完整参数、类型、
默认值与特殊值仍只维护在源码 `///` 中；在 VS Code 中悬停函数名即可查看 Tinymist
Hover 和参数提示。

## 四层能力模型

```text
Typst
  文字、image、figure、table、grid、公式、raw、label、ref、cite 与内容编程
    ↓
Touying
  幻灯片生命周期、子页面、渐进展示、speaker note、PDFPC 与 presenter view
    ↓
systems-slides-template Theme
  视觉默认值、标题与 Footer、Points、有限布局、页面层、page mark 与布局调试
    ↓
Deck
  本演示的 metadata、sections、正文、assets、局部覆盖和叙事选择
```

Theme 不重新包装 Typst 原生图片、figure、表格、公式或引用。Deck 作者仍调用原生接口，
Theme 只提供适合系统研究演示的默认字体、颜色、间距与页面区域。
当前本地包坐标是 `@local/systems-slides-template:0.6.0`；安装和升级命令见
[INSTALL](INSTALL.md)。

## 按读者选择路径

- 第一次使用：依次阅读 [01](guide/01-getting-started.md)、[02](guide/02-mental-model.md)、
  [04](guide/04-deck-structure.md)、[05](guide/05-theme-basics.md)。
- 普通 Deck 作者：继续阅读 [06](guide/06-native-content.md)、
  [07](guide/07-points-and-typography.md)、[08](guide/08-layout.md) 和
  [09](guide/09-progressive-slides.md)。
- 高级作者：重点阅读 [10](guide/10-page-surfaces.md)、
  [11](guide/11-speaker-tools.md)、[12](guide/12-recipes.md) 和
  [13](guide/13-troubleshooting.md)。

## 章节目录

1. [从零创建第一份演示](guide/01-getting-started.md)
2. [Typst、Touying、Theme 与 Deck](guide/02-mental-model.md)
3. [制作 Slides 所需的 Typst 基础](guide/03-typst-essentials.md)
4. [Deck 目录和文件职责](guide/04-deck-structure.md)
5. [Theme 配置与页面生命周期](guide/05-theme-basics.md)
6. [原生内容：媒体、表格、公式、代码与引用](guide/06-native-content.md)
7. [Points 与 Typography](guide/07-points-and-typography.md)
8. [自然流、body-flow、region 与 split](guide/08-layout.md)
9. [Touying 渐进展示](guide/09-progressive-slides.md)
10. [页面表面、Chrome、Page Mark 与调试](guide/10-page-surfaces.md)
11. [Speaker Notes、PDFPC 与 Presenter View](guide/11-speaker-tools.md)
12. [常用页面配方与 Catalog 映射](guide/12-recipes.md)
13. [故障排查](guide/13-troubleshooting.md)

## 公共能力导航

页面与 Theme：`systems-slides-theme`、`slide`、`title-slide`、`outline-slide`、
`section-slide`、`page-mark`、`page-frame`、`page-layer`。

内容与布局：`lead`、`point`、`points`、`layout-profile`、`region`、`row-split`、
`column-split`、`body-flow`、`panel`、`callout`、`typography.danger`。

运行时：`runtime.pause`、`runtime.jump`、`runtime.meanwhile`、`runtime.uncover`、
`runtime.only`、`runtime.alternatives`、`runtime.speaker-note`、
`runtime.presenter-view`。

这些名称用于帮助检索，不是参数参考。完整调用契约见
[Tinymist API 文档规范](API_DOCUMENTATION.md)。可执行视觉结果见
[Catalog](../examples/catalog/README.md)，安装与更新见 [INSTALL](INSTALL.md)，架构与发布见
[MAINTAINING](MAINTAINING.md)。
