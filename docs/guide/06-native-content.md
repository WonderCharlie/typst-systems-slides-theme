# 06 · 原生内容：媒体、表格、公式、代码与引用

读完本章，你可以用 Typst 原生接口制作系统研究演示的主要技术内容，并理解 Theme
提供了哪些默认值。

## 文字、强调与链接

普通文字、`*粗体*`、`_斜体_`、`#text(fill: ...)[...]`、`#link(...)` 和 `#footnote[...]`
均为 Typst 原生内容。`typography.danger[...]` 是 Theme 提供的少量语义强调 helper；
颜色 tones 可用于 Deck 自己的 SVG、图形或原生元素。

原生 list/enum 适合简单列表；需要 1–4 级、独立 marker 和父子节奏时使用 `points`。
`panel` 和 `callout` 是 Theme 提供的内容容器，只管理背景、边框、inset 和可选标题，
不决定它们在页面中的位置；用自然流或 split 放置它们。

## image、figure 与 caption

```typst
#figure(
  image(asset-path("figures/result.svg"), fit: "contain"),
  caption: figure.caption(position: top)[P99 latency by workload],
) <latency-result>
```

Theme 为原生 image 提供“保持固有比例、只缩不放”的默认策略，并为 figure/caption 提供
字号、颜色、对齐与间距。原生 width、height、fit、caption position、编号、label 和
`@latency-result` 仍然有效。图片需要取得有限余高时，把 image 放入 `region(...,
fit: "contain")`；不要创建 media wrapper。

## table 与 grid

`table` 表达语义数据，Theme 提供 18pt 正文、表头、inset 与分隔线默认值；列宽、对齐、
fill 和 stroke 仍由原生参数覆盖：

```typst
#figure(
  kind: table,
  caption: [Experimental configuration],
  table(
    columns: (1.4fr, 1fr, 1fr),
    table.header([Configuration], [Baseline], [Relay]),
    [Workers], [16], [16],
    [Storage], [Remote], [Remote],
  ),
) <configuration>
```

演示表格优先保留 2–5 列和不超过 6 行；宽表应选列、分组或移入 Appendix，而不是缩小
整表。`grid` 只负责规则排列，不提供表格语义。

## 公式与代码

公式使用 Typst 数学；raw 使用随 Theme 分发的 Source Code Pro：

```typst
$ L_(visible) = max(0, L_(remote) - C_(independent)) $ <visible-latency>

#raw(
  "schedule(request)\n  expose(request.dependencies)",
  block: true,
  lang: "typ",
)
```

代码建议不小于 16pt、每页约 15 行以内；高亮不应改变代码块几何。公式、符号解释和
结论应形成稳定的三个区域，新增解释时不要移动核心公式。

## 引用与 bibliography

`quote`、`footnote`、`cite`、`bibliography`、label 和 ref 都是 Typst 原生能力。把 `.bib`
放入 assets：

```typst
Dependency-aware scheduling follows prior overlap analysis @relay-note.
#bibliography(asset-path("references.bib"), title: none, style: "ieee")
```

不要手写 `[Author, year]` 模拟 citation。Catalog 第 20–24 页展示媒体，第 33–38 页展示
表格，第 39–42 页展示代码、公式、引用和 metrics。
