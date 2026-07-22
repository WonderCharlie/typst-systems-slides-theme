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
- `outline-slide`：读取章节结构生成目录。
- `section-slide`：显式章节分隔页；普通 Deck 不必启用自动章节页。
- `slide`：普通或特殊页面，支持 title、marks、计数、repeat 和 callback-style body。
- `== Title`：Touying 标题驱动页面；显式 `slide` 更适合需要 marks、repeat 或页面配置的场景。

逻辑页面是作者表达的一张 slide；渐进状态会生成多个物理 PDF 页面。`counted` 控制
页面计数，不等同于 PDF 物理页数。

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

Catalog 对应场景：Cover（第 1 页）、Roadmap（第 2 页）、Stable Slide Chrome（第 3 页）和
Long Technical Title（第 43 页）。
