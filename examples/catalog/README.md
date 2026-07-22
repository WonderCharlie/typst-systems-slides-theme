# Systems Slides Template Catalog

Catalog 是 Theme 布局能力的可执行规格：30 个逻辑场景生成 47 个物理 PDF 页面。它围绕完全
虚构的 Relay 系统研究报告，展示稳定页面 chrome、自然内容、渐进状态、媒体、原生
`figure`/`table`、代码、公式、来源、组合布局和整页表面。P99 延迟、吞吐量与 CPU 开销均为
合成数据，不代表真实系统或实验结果。

## 构建与验证

编辑 Catalog 时应在 VS Code 中打开仓库根目录；Catalog 继承根目录统一维护的 Tinymist
字体与预览配置，不维护自己的 `.vscode` 副本。

```sh
make catalog
make catalog-verify
make catalog-pdfpc
make font-isolation-check
```

`catalog-verify` 同时验证 30/47 页契约、公共导入边界、原生内容接口、PDFPC 生命周期、
Footer 安全距离、单行标题与 30pt 下限，以及 288 DPI 下声明为稳定的渐进区域。第 45 页
把远端存储边界放入 lead，只在标题区保留能够单行容纳的核心判断。视觉验证只比较应该
保持不变的图像、底部基线、比较列、Pipeline 轨道、Timeline 轴和表格单元格，不冻结整页。

## 目录职责

```text
main.typ       唯一编译入口与七个能力章节
globals.typ    Deck 元数据、Theme 配置、资源路径和跨页常量
sections/      直接导入 @local/systems-slides-template:0.6.1 的 30 个场景
assets/        Catalog 自有的合成图表、图示、照片和品牌资源
```

每个 section 的文件头说明场景目的、公开接口、Theme 默认值和跨状态稳定区域。场景优先使用
原生 Typst `image`、`figure`、`table`、`grid`、数学、`raw`、引用和脚注；Catalog 不维护
第二套组件或参数表。公共函数签名和默认值只在 Theme 源码的 `///` 注释中维护，并由
Tinymist hover 与参数提示展示。

按表达任务反查场景、物理页码和最小调用方式，见
[`docs/guide/12-recipes.md`](../../docs/guide/12-recipes.md)。

字体由 Theme 随包提供：Poppins 用于演示文本，Source Code Pro 用于代码，New Computer
Modern 与 Libertinus Serif 支持原生数学排版。命令行和 Tinymist 都禁用系统字体与 Typst 内嵌字体，因此无需
安装 Arial、Helvetica、Menlo、Monaco 或 Poppins。
