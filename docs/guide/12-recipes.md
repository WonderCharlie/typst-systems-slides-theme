# 12 · 常用页面配方与 Catalog 映射

读完本章，你可以从表达目标反查最小接口和可执行 Catalog 页面。代码列只展示关键调用；
完整上下文以链接的 Catalog 源文件为准。

## 页面配方索引

| 配方与目的 | 推荐接口 / 最小调用 | Catalog | 预期与适用条件 | 不推荐 / 常见错误 |
| --- | --- | ---: | --- | --- |
| 标题页：交代身份 | `title-slide(subtitle: [...])` | 1 | 无普通正文 chrome；开场使用 | 用普通 slide 手排 metadata；重复计数 |
| 目录页：展示章节 | `outline-slide(chapters: (...))` | 2–4 | 默认圆点、统一字形与垂直分布；可突出当前项 | 手写目录或分别修饰标记与正文 |
| 普通 Points | `points((point([...]),))` | 5 | 自然流、多级节奏 | 用空 block 调间距；层级跳跃 |
| lead + Points | `lead[...]` 后写 `points(...)` | 5、45 | 先限定问题再列证据 | 为自然流增加 split |
| 上文下图 | `body-flow(... rows: (auto, 1fr))` | 10–12、25 | 图片必须取得余高 | 把前置文字放 flow 外导致溢出 |
| 上图、文字渐进 | 固定 image + `runtime.uncover` | 7–9 | 图像像素不动 | 用 `only` 导致内容重排 |
| 左图右文 | `column-split(... columns: (2fr, 1fr))` | 26 | 不等宽证据列 | chart-with-points 等耦合组件 |
| 左右观点对比 | 两个 `region` + `column-split` | 27–29 | 列边界跨状态不变 | 每个状态重建不同 grid |
| 双图对比 | 两个原生 `figure/image` region | 22、26 | 图片保持比例 | `stretch` 拉伸媒体 |
| 2×2 矩阵 | 嵌套 row/column split | 47 | 标题基线与边界一致 | `place`/`move` 手调坐标 |
| 表格与解释 | 原生 `table` + `column-split` | 35、39 | 精确值与结论相邻 | 新建 Theme 表格 wrapper |
| 代码与结果 | 原生 `raw` + 解释 region | 41 | 代码块几何固定 | 依赖 Menlo/Monaco；超过约 15 行 |
| 公式与推导 | 原生 math + symbols + callout | 42 | 公式、定义、结论三级关系 | 为公式创建组件；解释推动公式移动 |
| 引用与 bibliography | `cite`/`bibliography` | 43 | 原生引用与来源 | 手写 `[Author, year]` |
| 全页背景 | `page-frame(background: page-layer(...))` | 46 | layer 不参与正文流 | 在正文 region 模拟整页背景 |
| 页面蒙版 | `page-frame(overlay: page-layer(..., area: "page"))` | 46 | 标题/Footer 同时被覆盖 | overlay 只覆盖 body |
| 底部固定、向上增长 | 最终轨道 + `uncover` | 16–18 | 既有底层像素不变 | 随状态重新测量整个结构 |
| 多阶段系统图 | 固定 pipeline 轨道 + `uncover` | 30–32 | 未变化节点不移动 | 每页复制不同坐标图 |
| 均匀分布 Points | `body-flow(... gutter: 3fr, outer-gutter: 2fr)` | 19–21 | 自然项与自由空间分离 | 给 points 增加 height/distribution |
| 长标题与 lead | 短单行 claim + `lead` | 45 | 标题 ≥30pt 且单行 | 双行标题或继续缩小 |
| Evaluation 图表和解释 | 原生 image/chart + Points region | 39、44 | 趋势和结论分工 | 图表与 Points 耦合为新接口 |
| Conclusion 页面 | 普通 slide + Points + page mark | 5、45 | 叙事语义留在 Deck | 新增 conclusion-slide |
| Speaker notes | slide 后接 `runtime.speaker-note` | Starter | 备注绑定所属 slide | 备注离目标页太远 |
| Presenter view | Theme 中展开 `runtime.presenter-view(...)` | Fixture | 双画布、观众内容不变 | 把备注画进普通 PDF |

## Guide—Catalog 可执行映射

| Guide 章节 | 使用能力 | Catalog 场景 | 物理页码 | 源文件 |
| --- | --- | --- | ---: | --- |
| 05 | title-slide | Cover | 1 | [1_foundations.typ](../../examples/catalog/sections/1_foundations.typ) |
| 05 | outline-slide | Default Roadmap | 2 | [1_foundations.typ](../../examples/catalog/sections/1_foundations.typ) |
| 05 | outline-slide/current | Current Roadmap | 3 | [1_foundations.typ](../../examples/catalog/sections/1_foundations.typ) |
| 05 | outline-slide overrides | Roadmap Parameter Overrides | 4 | [1_foundations.typ](../../examples/catalog/sections/1_foundations.typ) |
| 05、07 | chrome、page-mark、Points | Stable Slide Chrome | 5 | [1_foundations.typ](../../examples/catalog/sections/1_foundations.typ) |
| 03、06 | 原生文字、公式、代码、链接 | Native Typst Content | 6 | [1_foundations.typ](../../examples/catalog/sections/1_foundations.typ) |
| 09 | 固定图片、渐进 Points | Fixed Evidence, Progressive Interpretation | 7–9 | [2_progressive_vertical.typ](../../examples/catalog/sections/2_progressive_vertical.typ) |
| 08、09 | 自然文字、沉底图片 | Progressive Requirements, Fixed Architecture | 10–12 | [2_progressive_vertical.typ](../../examples/catalog/sections/2_progressive_vertical.typ) |
| 09 | uncover、only、alternatives | Reserve, Release, and Replace | 13–15 | [2_progressive_vertical.typ](../../examples/catalog/sections/2_progressive_vertical.typ) |
| 09 | 底部稳定结构增长 | Bottom-Aligned Layer Growth | 16–18 | [2_progressive_vertical.typ](../../examples/catalog/sections/2_progressive_vertical.typ) |
| 08、09 | fraction/outer gutter | Progressive Points in Stable Free Space | 19–21 | [2_progressive_vertical.typ](../../examples/catalog/sections/2_progressive_vertical.typ) |
| 06、08 | 原生 image、contain | Native Image Ratios | 22 | [3_media_and_figures.typ](../../examples/catalog/sections/3_media_and_figures.typ) |
| 06 | figure.caption position | Caption Placement | 23 | [3_media_and_figures.typ](../../examples/catalog/sections/3_media_and_figures.typ) |
| 06 | figure、label、ref | Native Figure References | 24 | [3_media_and_figures.typ](../../examples/catalog/sections/3_media_and_figures.typ) |
| 06、08 | 主图与 takeaway | Dominant Figure and Takeaway | 25 | [3_media_and_figures.typ](../../examples/catalog/sections/3_media_and_figures.typ) |
| 08 | 不等宽 column split | Unequal Evidence Columns | 26 | [3_media_and_figures.typ](../../examples/catalog/sections/3_media_and_figures.typ) |
| 09 | 稳定对比列 | Stable Before/After Comparison | 27–29 | [4_comparison_and_pipeline.typ](../../examples/catalog/sections/4_comparison_and_pipeline.typ) |
| 09 | 固定 pipeline 轨道 | Fixed-Track Pipeline | 30–32 | [4_comparison_and_pipeline.typ](../../examples/catalog/sections/4_comparison_and_pipeline.typ) |
| 09 | 稳定 timeline | Stable Timeline | 33–34 | [4_comparison_and_pipeline.typ](../../examples/catalog/sections/4_comparison_and_pipeline.typ) |
| 06 | Theme 默认原生 table | Experimental Configuration | 35 | [5_tables.typ](../../examples/catalog/sections/5_tables.typ) |
| 06、09 | 渐进表格 | Progressive Results Table | 36–38 | [5_tables.typ](../../examples/catalog/sections/5_tables.typ) |
| 06、08 | 图表与精确值 | Chart and Exact Values | 39 | [5_tables.typ](../../examples/catalog/sections/5_tables.typ) |
| 06 | 宽表信息收敛 | Curating Wide Tables | 40 | [5_tables.typ](../../examples/catalog/sections/5_tables.typ) |
| 06、08 | raw 与解释分栏 | Pseudocode with Explanation | 41 | [6_technical_content.typ](../../examples/catalog/sections/6_technical_content.typ) |
| 06、08 | math、符号、结论 | Formula, Symbols, and Conclusion | 42 | [6_technical_content.typ](../../examples/catalog/sections/6_technical_content.typ) |
| 06 | quote、footnote、cite | Quotes, Footnotes, and Sources | 43 | [6_technical_content.typ](../../examples/catalog/sections/6_technical_content.typ) |
| 06、08 | metrics 与解释 | Metrics Dashboard | 44 | [6_technical_content.typ](../../examples/catalog/sections/6_technical_content.typ) |
| 05 | 单行长标题与 lead | Long Single-Line Title Contract | 45 | [7_surfaces.typ](../../examples/catalog/sections/7_surfaces.typ) |
| 10 | 无 chrome 整页表面 | Titleless Technical Canvas | 46 | [7_surfaces.typ](../../examples/catalog/sections/7_surfaces.typ) |
| 08 | 嵌套 2×2 split | 2×2 Evidence Matrix | 47 | [7_surfaces.typ](../../examples/catalog/sections/7_surfaces.typ) |

映射覆盖 Catalog 的 30 个逻辑场景和 47 个物理页面。`tests/guide-check.py` 会验证场景、
页码和源文件；Catalog 数量变化时必须同步更新本表。视觉总览可由 `build/catalog.pdf`
查看，Guide 不复制完整场景源码。
