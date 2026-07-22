# 02 · Typst、Touying、Theme 与 Deck

读完本章，你可以判断一项需求应由哪一层负责，避免在 Deck 中重做 Theme 或 Typst。

| 层次 | 负责 | 不负责 |
| --- | --- | --- |
| Typst | 文本、图片、figure、table、grid、公式、代码、引用、内容编程 | 幻灯片阶段与演讲者生命周期 |
| Touying | slide/subslide、渐进状态、speaker note、PDFPC、presenter view | 本项目的视觉与页面 master |
| Theme | 字体、颜色、标题、Footer、Points、有限布局、页面层、调试 | 推断 Motivation、Conclusion 等叙事角色 |
| Deck | metadata、sections、assets、局部覆盖和论证内容 | 复制 `src/`、master 或公共组件实现 |

## 判断来源

- 写 `image(...)`、`figure(...)`、`table(...)`、数学或 `raw`：Typst 原生能力，Theme 只改变默认样式。
- 写 `runtime.uncover`、`speaker-note`：Touying 行为通过 Theme 的受控 namespace 暴露。
- 写 `body-flow`、`region`、split、`page-frame`：Theme 补充的 Slides 空间能力。
- 写文案、选择素材、决定某页是不是结论：Deck 决策。

局部原生参数始终优先于 Theme 默认值。例如 Theme 提供 caption 字号和颜色，但
`figure.caption(position: top)` 仍由调用页决定位置。全局配置放 `globals.typ`，单页差异
留在 section；不要修改 master 坐标来解决内容问题。

## 默认优先原则

先使用自然流和 Theme 默认值。只有遇到可观察的空间要求时再增加抽象：需要余高才用
`body-flow`，需要轨道才用 split，需要有限局部策略才用 `region`，需要整页表面才用
`page-frame`。这一顺序使内容替换后仍能自动重排。
