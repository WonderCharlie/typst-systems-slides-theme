# Changelog

## Unreleased

- Roadmap 将自动分布限制在相邻条目之间，并新增独立的 `top-spacing` 与 `bottom-spacing`，
  使作者能够固定正文上边界到首项、末项到 Footer 上边界的留白，而不影响中间
  `auto-layout`。

## 0.6.1 - 2026-07-23

- `outline-slide` 现在可直接接收 `chapters`，以统一的 32pt/600 圆点与正文样式生成 Roadmap；
  `current` 只通过主题色或 700 字重强调当前项，不改变字号和布局。
- Roadmap 支持覆盖编号形式、字号、普通字重、间距和强调样式；默认自动布局固定第一项的
  顶部锚点，只均分内部间距与底部余量。
- 产品级 Catalog 增加默认 Roadmap、当前章节高亮和参数覆盖三个场景，现为 30 个逻辑场景、
  47 个物理页面。

## 0.6.0 - 2026-07-22

- BREAKING：`outline-slide` 的默认一级标记由无标记改为与 `points` 一致的实心圆；需要数字时
  显式传入 `numbered` 与 `numbering`。
- `outline-slide` 新增 `auto-layout`，在有限正文高度中用 fraction 间距均匀分布 Roadmap
  条目，并拒绝与显式 `vspace` 同时使用。
- 为 `page-frame` 增加只作用于正文的 `body-inset`，并禁止可见 chrome 页面通过物理
  `margin` 移动标题或 Footer；增加正文内缩下 Footer 贴底稳定性测试。

## 0.5.0 - 2026-07-22

- Footer Logo 改用与标题、日期、页码一致的全高度槽位垂直居中，移除固定 `logo-dy`；
  新增对称 Logo 与 72/96/144/288 DPI 底边填充契约测试。
- 将初始化 Starter 收敛为标题、目录、默认 Points 与原生 figure 四页骨架。
- 移除 Starter 对 Theme 源码仓库字体路径的回退，初始化 Deck 仅使用自身 `fonts/`。
- 让产品级 Catalog 实际消费稳定的 `panel` 接口，并清理无消费者的媒体资产副本。
- 清理拆仓后失效的真实 Deck 编辑器任务，并验证每个 VS Code Make Task 的目标存在。

## 0.4.0

- 包、Theme 目录和本地安装坐标统一采用 `systems-slides-template`；公开 Theme 入口采用
  `systems-slides-theme`。
- 将用户指南扩展为 13 个任务章节，覆盖从零初始化、Typst 原生内容、Theme 页面与布局、
  渐进展示、页面表面、演讲者工具、24 个页面配方、Catalog 全场景映射和故障排查；
  新增可编译五页 Guide 示例与文档契约检查。
- 将项目整理为可通过 `@local/systems-slides-template` 安装和初始化的独立 Touying Slides Theme，
  继续依赖官方 `@preview/touying:0.7.4`。
- 增加安全的物理快照安装、同版本替换、卸载和隔离生命周期验证。
- 提供可直接编译的 Starter，以及 metadata、section、Deck 资源路径、Poppins 部署副本和
  VS Code/Tinymist 配置。
- Starter 使用公共 typography tones 演示一组可复制的架构图与数据图形配色，不增加
  Theme 专用 Chart API。
- Starter 不再转发冗余日期字段，新 Deck 默认由 Theme 在每次编译时取得当天日期；
  产品级 Catalog 与测试夹具仍使用固定日期保证回归可复现。
- 稳定公共入口覆盖页面生命周期、page frame/layer/mark、自然余高 flow、嵌套 region
  与 split、四级 Points、内容容器及受控 runtime/typography 命名空间。
- Theme 为原生文本、列表、image、figure 和 caption 提供系统论文演示默认样式，同时
  保留原生 figure 编号、label 与引用语义。
- 普通页标题采用严格单行契约：从 40pt 按扣除 page mark 与章节进度后的实际宽度缩至
  最低 30pt，仍无法容纳时给出明确编译错误，详细说明进入 lead 或正文。
- Footer 文字按紫色区域的真实高度垂直居中，不再施加与字体行框重复的光学偏移。
- Catalog Footer wordmark 使用完整 SVG 画布，避免最右侧字形被资源边界裁切。
- 支持 speaker notes、PDFPC、Touying 渐进显示和观众/备注双画布。
- 公共 API 增加 Tinymist 可读取的中文 hover 和 signature help 文档。
- 提供围绕虚构 Relay 系统论文构建的 28 个逻辑场景、45 个物理页产品级 Catalog，覆盖
  渐进状态、媒体、原生表格与引用、技术内容、布局和页面表面；真实 Deck 与作者级 Catalog
  迁入独立 Slides 工作区，通过版本化 `@local` 包消费 Theme。Catalog 不进入安装快照。
- 为 `body-flow` 增加默认不改变布局的 `outer-gutter`，允许正文首尾空间与内部 gutter、
  弹性轨道按同一有限余高预算分配；callback-style slide 中的 `runtime.uncover` 保留
  槽位，`runtime.only` 仍触发动态重排。
- 增加公共边界、布局诊断、内容变化、安装和编辑器文档测试；真实 Deck 验收由 Slides 工作区维护。
