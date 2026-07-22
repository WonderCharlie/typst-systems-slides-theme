# 09 · Touying 渐进展示

读完本章，你可以创建稳定子页面，理解 `uncover` 与 `only` 的空间差异，并导出正确的
物理 PDF 与 PDFPC 状态。

## 基础阶段

`runtime.pause` 推进一个子页，`runtime.jump` 跳到绝对或相对状态，
`runtime.meanwhile` 把后续内容重新并入第一个状态。`runtime.alternatives` 在共同区域中
替换候选内容。

```typst
#slide(title: [Progressive Result])[
  Baseline
  #runtime.pause
  Relay
]
```

一个逻辑 slide 可生成多个物理 PDF 页面。PDFPC 保存逻辑页面、子页和备注关系。

## uncover 与 only

- `runtime.uncover("2-")[...]`：隐藏时保留最终槽位，适合已有内容像素稳定。
- `runtime.only("2")[...]`：隐藏时移除内容并重新布局，适合作者明确需要移动或释放空间。
- `runtime.alternatives[...] [...]`：外部区域保持一致，只替换内部候选。

有限测量布局中使用 callback-style slide，并显式传入 `self`：

```typst
#slide(title: [Stable Requirements], repeat: 3, self => [
  #body-flow(
    (
      region(points((point([Preserve ordering.]),))),
      region(runtime.uncover("2-", self: self)[
        #points((point([Avoid unnecessary synchronization.]),))
      ]),
      region(runtime.uncover("3-", self: self)[
        #points((point([Require no application changes.]),))
      ]),
    ),
    rows: (auto, auto, auto),
    outer-gutter: 2fr,
    gutter: 3fr,
  )
])
```

`repeat` 声明最终状态数；`self` 让测量阶段使用同一 Touying 状态。一级 Point 与子项放在
同一 region，避免层级被空间分布拆开。

## 常用稳定模式

- 图片固定在上、文字逐条出现：图片是固定 region，Points 使用 uncover 预留最终空间。
- 文字增长、图片沉底：先写自然 Points，再用弹性空白把固有尺寸图片推到底部；图片不要放进 1fr 轨道。
- 底部结构逐层出现：从最终几何开始分配轨道，只 uncover 新层。
- 表格渐进：固定完整表格几何，隐藏单元格内容而不是重建三张不同尺寸的表格。

Catalog 第 5–19、25–32、34–36 页是跨状态稳定性规格。需要主动重排时才用 `only`；
正式论证通常优先 `uncover`。
