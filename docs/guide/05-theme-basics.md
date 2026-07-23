# 05 · Theme 配置与页面生命周期

读完本章，你可以配置整份 Deck，选择正确的页面入口，并处理标题、页码和 page mark。

## 安装 Theme

Starter 在 `globals.typ` 使用 `systems-slides-theme.with(...)` 绑定元数据和全局选择：

```typst
#let deck-theme = systems-slides-theme.with(
  title: deck-meta.title,
  author: deck-meta.author,
  institution: deck-meta.institution,
  footer-title: auto,
  section-progress: true,
)
```

Theme 安装 Touying 生命周期、16:9 页面、字体、标题区、Footer、原生内容默认值和章节
进度。完整参数请悬停 `systems-slides-theme`。调用处显式配置优先于默认值，单页内容的
局部 `set`/原生参数又只影响其作用域。

日期默认是 `datetime.today()`，因此每次编译自动更新。需要可复现归档时显式传入固定
`datetime(year: ..., month: ..., day: ...)`。Footer logo 和 page mark 应接收 Deck 创建的
原生 path；不要修改 master 坐标。

## 页面入口

- `title-slide`：标题、作者、机构和活动标识；通常 `counted: false`。
- `outline-slide`：接收章节内容生成 Roadmap；默认使用统一的 32pt/600 圆点与正文样式。
- `section-slide`：显式章节分隔页；普通 Deck 不必启用自动章节页。
- `slide`：普通或特殊页面，支持 title、marks、计数、repeat 和 callback-style body。
- `== Title`：Touying 标题驱动页面；显式 `slide` 更适合需要 marks、repeat 或页面配置的场景。

逻辑页面是作者表达的一张 slide；渐进状态会生成多个物理 PDF 页面。`counted` 控制
页面计数，不等同于 PDF 物理页数。

推荐把章节内容直接交给 Roadmap，Theme 同时控制标记、正文、缩进、基线和垂直分布：

```typst
#outline-slide(
  title: [Roadmap],
  chapters: (
    [Problem],
    [Evidence],
    [Design],
    [Implementation],
    [Evaluation],
    [Conclusion],
  ),
  current: 3,
)
```

默认 `auto-layout: true` 只把正文余高均分给相邻条目之间的间距。第一项之前和最后一项
之后的留白分别由 `top-spacing` 与 `bottom-spacing` 显式控制，默认分别为 `0pt` 和
`12pt`。`top-spacing` 从 Theme 的正文内容上边界开始量取；`bottom-spacing` 从最后一项的
布局下边缘量到 Footer 紫色区域的上边界，而不是量到物理页面底边。它们不会参与自动分配，
因此作者可以稳定控制 Roadmap 的上下边界。关闭自动布局后，中间改用固定 `spacing`，首尾
留白仍保持不变。`current` 默认通过主题紫色和 700 字重突出当前项，不会改变字号或推动
其他条目。

```typst
#outline-slide(
  title: [Roadmap],
  chapters: chapters,
  top-spacing: 14pt,
  bottom-spacing: 22pt,
)
```

需要数字 Roadmap 时传 `numbering: "1."`；字号、普通字重、中间间距、首尾留白和
`current-style` 均可局部覆盖，但强调样式只能改变颜色与字重。

不显式传 `chapters` 时，组件仍可查询 `level` 对应的 outlined headings。Roadmap 的规则只
作用于本次 `outline-slide` 调用，不修改 Typst 原生列表或 `points`。

## 标题契约

普通标题严格单行：Theme 从 40pt 自动缩至最低 30pt，并先扣除 page mark 与章节进度的
宽度。仍无法容纳或包含显式换行时直接编译失败。缩短核心判断，把限定条件移入 `lead`
或正文；不要裁剪、继续缩小或修改标题轨道。

```typst
#slide(
  title: [Dependency-Aware Scheduling Preserves Ordering],
  marks: (page-mark(asset-path("badges/artifact.svg")),),
)[
  #lead[Across compute and remote storage boundaries.]
]
```

Page mark 属于标题 chrome，不进入正文流，也不应移动相同标题的垂直位置。

Catalog 对应场景：Cover（第 1 页）、三种 Roadmap（第 2–4 页）、Stable Slide Chrome
（第 5 页）和 Long Technical Title（第 45 页）。
