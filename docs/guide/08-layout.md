# 08 · 自然流、body-flow、region 与 split

读完本章，你可以按空间需求选择最小布局能力，并理解有限尺寸、`auto`、百分比和 `fr`。

## 决策流程

```text
普通内容顺序排列
  → 自然流
后续区域必须取得正文剩余高度
  → body-flow
需要纵向或横向轨道
  → row-split / column-split
需要局部尺寸、inset、align、fit 或 overflow
  → region
需要整页背景、蒙版或 chrome 控制
  → page-frame / page-layer
```

## 自然流优先

`lead`、`points`、原生 figure、table、公式和代码默认从上到下排列。内容只需自然高度时
不要使用 split，也不要连续写 `v(...)`、空 block 或绝对坐标模拟布局。

## 轨道和有限父尺寸

`auto` 取内容自然尺寸，固定 length 直接占用空间，`em` 等 relative length 跟随当前
文字尺度，percentage/ratio 相对父尺寸，`fr` 按权重分配扣除固定轨道、自然轨道和
gutter 后的剩余空间。`fr` 和百分比只有在父容器提供有限宽高时才有意义。

`row-split` 从上到下，`column-split` 从左到右：

```typst
#column-split(
  (
    region(image(asset-path("figures/design.svg"), fit: "contain"), fit: "contain"),
    region(points(items), align: left + horizon),
  ),
  columns: (2fr, 1fr),
  gutter: 24pt,
)
```

区域数必须匹配 rows/columns 轨道数。split 可以嵌套；结构仍与内容语义无关。

## region 的局部策略

- `inset`：先从区域内部扣除的固定安全距离。
- `align`：内容在分配区域内的对齐。
- `fit: "flow"`：自然排版，不缩放。
- `fit: "contain"`：保持比例完整容纳。
- `fit: "cover"`：保持比例填满并允许裁剪。
- `fit: "stretch"`：独立缩放两个轴，通常不用于图片。
- `overflow: "visible"`：允许超出边界。
- `overflow: "clip"`：裁掉边界外内容。
- `overflow: "error"`：空间不足立即报错，适合有限契约。

`fit`/严格 overflow 需要有限区域。`name` 只用于诊断标签，不改变布局。

## body-flow 与正文剩余高度

大部分页面不需要 `body-flow`。它只在后续区域必须获得 Theme 正文框的剩余高度时使用：

```typst
#body-flow(
  (
    region(points(items)),
    region(image(asset-path("figures/result.svg"), fit: "contain"), fit: "contain"),
  ),
  rows: (auto, 1fr),
)
```

前置文字、Points 或表格若参与高度预算，必须放进同一个 flow。`auto` 先测量自然高度，
`1fr` 得到余高；空间不足时应修剪内容或拆页，而不是让弹性空间退化为零。

## 均匀分布自然区域

所有 region 都保持自然高度时，可把剩余空间分给内部与外侧 gutter：

```typst
#body-flow(
  (region(first), region(second), region(third)),
  rows: (auto, auto, auto),
  inset: (top: 12pt, bottom: 12pt),
  outer-gutter: 2fr,
  gutter: 3fr,
)
```

`inset` 是不可压缩安全距离；`outer-gutter` 只在首 region 上方和末 region 下方；`gutter`
只在相邻 region 之间。上例上下各 2 份，两个内部间距各 3 份。数组可为每个 gutter
提供不同策略。

## profile

`layout-profile` 保存真正跨页稳定的空间策略；调用参数覆盖 profile，region 自身策略最
局部。普通用户通常不需要感知 profile，更不应按页码或叙事角色创建 profile。

Catalog 第 20、24、37、39–45 页展示不同 split 组合，第 17–19 页验证 fraction gutter。
