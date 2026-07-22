# 10 · 页面表面、Chrome、Page Mark 与调试

读完本章，你可以创建全页背景/蒙版、控制 chrome，并用调试层定位 region 和剩余空间。

## page-frame 与 page-layer

`page-frame` 描述页面表面、chrome、计数和溢出策略；`page-layer` 描述不参与正文流的
background、overlay 或 foreground 内容。

```typst
#slide(
  title: none,
  frame: page-frame(
    chrome: false,
    fill: typography.tone-deep,
    background: page-layer(background-art, area: "page"),
    overlay: page-layer(rect(fill: black.transparentize(55%)), area: "page"),
  ),
)[
  #align(center + horizon, text(fill: white, size: 38pt)[One clear statement])
]
```

overlay 必须覆盖整页，包括标题、正文、page mark 和 Footer；background/foreground 可用
`area: "page"` 或 `"body"`。页面层不占正文空间，也不代表 Question、Insight、Goal 或
Conclusion。叙事语义由 Deck 的标题和内容表达。

保留标题或 Footer 时，使用 `body-inset` 调整正文留白；它只作用于 Theme 正文区域，
不会移动固定 chrome。物理 `margin` 仅用于 `chrome: false` 的全画布页面，Theme 会拒绝
在可见 chrome 下使用它，避免 Footer 与页面底边之间出现缝隙。

```typst
#slide(
  frame: page-frame(body-inset: (left: 3%, right: 3%, top: 12%, bottom: 8%)),
)[正文内容]
```

`chrome: false` 隐藏普通 header/footer；counted、fill 和 overflow detection 是页面生命周期
选择。普通页面不应重设物理页面尺寸。

## Page mark

`page-mark` 由 `slide(marks: (...))` 放入标题区右侧槽位，默认按标题带高度等比缩放并
垂直居中。它减少标题可用宽度但不改变标题纵向位置。标识过宽导致标题低于 30pt 仍
无法单行容纳时，应缩短标题或缩小 mark，而不是覆盖 master。

## 布局调试

初始化 Deck 执行：

```sh
make debug
```

输出 `build/slides-layout-debug.pdf`。仓库维护者也可显式传：

```sh
typst compile --input layout-debug=boxes main.typ build/debug-boxes.pdf
typst compile --input layout-debug=labels main.typ build/debug-labels.pdf
```

- `off`：无调试层，普通 Preview/PDF 的默认行为。
- `boxes`：半透明显示容器边界。
- `labels`：同时显示 Theme body、body-flow、row-split、column-split 和 region 名称。

```typst
#body-flow(
  (
    region(lead[Measured first.], name: "lead"),
    region(
      column-split(
        (region(left, name: "left"), region(right, name: "right")),
        columns: (1fr, 1fr),
        name: "evidence-columns",
      ),
      name: "evidence",
    ),
  ),
  rows: (auto, 1fr),
  name: "page-flow",
)
```

正常输出只显示内容；labels 输出叠加层次化区域。用边界判断 inset、gutter 和剩余空间，
不要把调试框当坐标测量器：当前调试 PDF不显示精确 x/y/width/height 数值。详见
[布局调试说明](../LAYOUT_DEBUG.md)。Catalog 第 44 页展示无 chrome 表面。
