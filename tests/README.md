# 测试边界

`tests/` 只保存小型契约、诊断和安装检查。产品入口是根 `lib.typ`，教学演示在
`examples/catalog/`；真实演示文稿及其视觉回归位于独立 Slides 工作区。测试不保存
另一份模板实现或完整 Deck 副本。

## 编译夹具

`make fixture-check` 将下列 fixture 编译到 `build/tests/`：

| Fixture | 主要契约 |
| --- | --- |
| `theme-api.typ` | 根入口、Theme 元数据、常用内容和 footer |
| `footer-contract.typ` / `footer-contract.py` | Footer 的 500.5pt 起点、全高槽位居中、Logo 可见中心与多 DPI 底边填充 |
| `native-theme.typ` | Theme 下原生 figure 编号、引用、caption 与列表语义 |
| `lifecycle.typ` | 标题驱动页面、显式页面、page mark、frame 与逻辑计数 |
| `navigation.typ` | 六章节 Roadmap 的默认圆点、当前项强调、参数覆盖与首项锚点 |
| `special-config.typ` | 单页配置覆盖 |
| `section-lifecycle.typ` | 自动章节页和逻辑页码 |
| `presenter-view.typ` | 1920 × 540 的观众/备注双画布 |
| `layout-contract.typ` | 嵌套轨道、gutter、fit 和原生内容 |
| `body-flow.typ` | 自然行、剩余高度、内容变化和嵌套 split |
| `points-contract.typ` | 四级扁平 Points、间距和样式 |
| `page-frame.typ` | 页面层、chrome、进度、计数与 Touying 动画共存 |

`make presenter-check` 还验证 starter 的 PDFPC 输出确实包含 speaker note。

## 诊断与边界

| 文件 | 检查内容 |
| --- | --- |
| `layout-diagnostics.*` | 轨道、gutter、尺寸、fit、overflow 和 page-layer area 错误 |
| `body-flow-diagnostics.*` | 有限父尺寸、轨道数量、方向与余量耗尽 |
| `body-flow-variation.sh` | 增加换行/Bullet 后无需手工坐标且页数稳定 |
| `public-api-naming.py` | 精确导出 allowlist、两个命名空间和内容无关命名 |
| `public-boundary.sh` | 单入口、单向依赖、官方 Touying 和安装 allowlist |
| `version-sync.sh` | `@local/systems-slides-template:0.6.1` 与官方 Touying 版本引用 |
| `check-api-comments.py` | 禁止旧双轨注释，并固定 Tinymist 稳定函数/参数清单 |
| `documentation-check.py` | 文档职责、失效链接、版本、退役接口和 `///` 注释风格 |
| `check-tinymist-docs.py` | 中文 `///`、真实签名、100 字符行宽、连续参数、类型词表和返回类型 |
| `tinymist-lsp.py` | 27 个稳定绑定及其全部参数的真实 hover 与 signature help |
| `guide-check.py` | 13 个 Guide 章节、27 个公共绑定、30/47 Catalog 映射和示例边界 |
| `editor-font-config.py` | Tinymist 字体路径与普通/布局调试 workspace 的输入隔离 |
| `catalog-page-boundary.py` | 47 页文本 bbox、标题/正文边界、Footer 垂直居中与窄列 lead 完整性 |
| `title-contract.*` | 标题只能单行、最低 30pt，并对显式换行、超长标题和 mark 挤占给出诊断 |
| `page-mark-title-stability.*` | 相同标题在 page mark/章节进度组合下保持同一 bbox 与 288 DPI 像素 |
| `body-flow-distribution.*` | outer/internal fraction gutter 按 2:3 分配，并在 uncover 状态间保持像素稳定 |
| `local-install.sh` | 物理安装、标准 init、编译、保护、替换和卸载 |
| `fidelity_check.py` | PDF 页数、尺寸与关键文本 |
| `layout-debug.typ` | 调试蒙版的 Theme、正文流及嵌套 split 标签契约 |

## 运行

运行测试需要 Typst、Python 3.11+、`rg`，以及 Poppler 的 `pdfinfo` 和
`pdftotext`；默认验证不需要第三方 Python 包。常用目标：

```sh
make fixture-check
make presenter-check
make layout-diagnostics-check
make body-flow-diagnostics-check
make body-flow-variation-check

make comment-check
make documentation-check
make tinymist-docs-static-check
make guide-check
make version-check
make api-naming-check
make public-check

make package-check
make local-install-check
make core-check
make validate
```

`make validate` 依次覆盖发行快照、Starter、47 页产品级 Catalog、隔离本地安装和核心
契约。生成物统一进入根 `build/`。

Catalog 专项检查同时固定 30 个逻辑场景、47 个 PDF 页面、九组连续 overlay 的
逻辑页码/PDFPC 状态，以及图表、底部基线、对比列和 Pipeline 已有区域的像素稳定性。

真实 Tinymist LSP 检查单独运行，因为它依赖当前机器的编辑器二进制：

```sh
make tinymist-docs-check
TINYMIST=/absolute/path/to/tinymist make tinymist-docs-check

make reinstall
make tinymist-installed-docs-check
```

`tinymist-installed-docs-check` 不会修改安装；它读取已安装的
`@local/systems-slides-template:0.6.1`，所以源码更新后先执行 `make reinstall`。

验证真实用户安装时使用：

```sh
make install
make install-check
```

## 维护原则

- 新公共行为先用最小 fixture 表达，再决定是否需要 catalog 场景。
- 每个错误条件检查明确诊断，不只断言“编译失败”。
- 测试只从公共入口使用作者 API；边界脚本可以读取内部文件进行审计。
- 不自动把当前 PDF 批准为基线。
- 修改 manifest、starter 或安装器后至少运行 `make package-check local-install-check`。
- 修改公共函数后只在函数前维护 `///`，并运行
  `make comment-check documentation-check tinymist-docs-static-check`。
- 修改真实 Deck、项目素材或 Deck 级验证脚手架时，在独立 Slides 工作区运行相应检查。
- 大范围调整运行 `make validate`。
