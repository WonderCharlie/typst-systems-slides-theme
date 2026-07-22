# 07 · Points 与 Typography

读完本章，你可以选择原生 list 或 Points，编写稳定多级条目并正确覆盖文字与 marker。

## 何时使用 Points

原生 list/enum 适合简单、文档式列表。`points` 面向演示：支持 1–4 级扁平条目、独立
marker、缩进、同级间距与父子间距。

```typst
#points((
  point([Preserve storage ordering.], level: 1),
  point([Expose dependencies before issuing I/O.], level: 2),
  point([Overlap independent computation.], level: 2),
  point([Require no application changes.], level: 1),
))
```

层级必须从 1 开始，且相邻条目最多增加一级；跳级意味着父项不存在，编译会明确报错。
一级 Point 及其子项在空间布局中应作为一个整体 region，而不是按层级拆散。

## 间距和换行

- `gap`：整体条目间距。
- 逐层 gap：同一层级相邻条目的节奏。
- nest gap：父项到第一个直接子项的距离。

同一边界只应用一次。条目内部手动换行仍是一个 Point，不产生新的列表间距；新增
`point(...)` 才创建条目。默认一级文字为 regular，不会自动粗体。

## 样式覆盖

Theme 管理默认字体、字号、字重和 marker。调用 `points` 的整体设置可覆盖 Theme，逐层
样式覆盖整体，单个 `point` 内容中的显式 `text` 最局部。Marker 样式与正文样式分别
处理；不要为了改默认值创建第二个 Points 包装或等值别名。

`typography` namespace 提供稳定 tones、`font-family` 和 `danger`，用于 Deck 自己的原生
图形或语义强调：

```typst
#text(fill: typography.tone-chart-blue)[Comparison]
#typography.danger[Visible latency]
```

完整 Points 参数和覆盖顺序请悬停 `point`、`points`。Catalog 第 3、8–10、17–19 页展示
普通、渐进与均匀分布 Points。
