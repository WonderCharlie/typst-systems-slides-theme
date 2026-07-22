# systems-slides-template

`systems-slides-template` 是一套面向系统研究、论文报告和技术分享的 Typst/Touying Slides
Theme。它统一 16:9 页面、标题与页脚、章节导航、页面生命周期、结构化布局、四级
Points、页面分层、page mark 和演讲者能力，并尽量让作者继续使用 Typst 原生文本、
`image`、`figure`、表格和公式。

它不是通用 Typst 文档模板，也不是 Touying fork。演示运行时始终来自官方
`@preview/touying:0.7.4`；本项目以 `@local/systems-slides-template:0.6.0` 安装到本机。

## 设计原则

- Deck 只保存内容、元数据和自己的素材；Theme 只保存跨演示稳定的视觉与排版规则。
- 普通正文优先使用 Typst 自然流；只有需要分配剩余高度时才使用 `body-flow`。
- `region` 与 split 只描述空间关系，不推断 Motivation、Insight 或 Conclusion 等叙事角色。
- Points 是唯一的多级列表接口；图片与 caption 使用 Typst 原生 `image` 和 `figure`。
- 根 `lib.typ` 是唯一公共入口；参数契约只在函数声明前的中文 `///` 中维护，并由
  Tinymist 显示。
- 产品级 Catalog 负责验证和教学稳定公共能力，但不能反向决定公共 API；真实 Deck 属于独立 Slides 工作区。

## 最短使用路径

```sh
make install
typst init @local/systems-slides-template:0.6.0 my-talk
cd my-talk
make
```

生成的演示文稿位于 `my-talk/build/slides.pdf`。首次编译需要能够读取或下载官方
Touying 包。

## 主要能力

- `== Title` 或 `slide(...)` 驱动的页面生命周期，以及标题页、目录页和章节页；
- Theme 统一管理字体、颜色、标题区、footer、日期、章节进度和原生 figure 样式；
- Typst 自然流、有限正文流、可嵌套的 region/row/column split；
- 四级 Points，以及可局部覆盖的层级样式、Marker、缩进与间距；
- 整页 overlay、background/foreground、chrome 控制和 page mark；
- Touying speaker notes、渐进显示、PDFPC 与双画布 presenter view；
- 可安装的 Starter，以及用于接口覆盖和视觉契约的 45 页产品级 Catalog。

## 文档入口

| 读者 | 文档 |
| --- | --- |
| 首次安装与升级 | [`docs/INSTALL.md`](docs/INSTALL.md) |
| Deck 作者 | [`template/README.md`](template/README.md) |
| 从零使用、内容、布局与演讲者工具 | [`docs/USER_GUIDE.md`](docs/USER_GUIDE.md) |
| Tinymist API 文档规则 | [`docs/API_DOCUMENTATION.md`](docs/API_DOCUMENTATION.md) |
| 架构、打包与维护 | [`docs/MAINTAINING.md`](docs/MAINTAINING.md) |
| 验证范围与命令 | [`tests/README.md`](tests/README.md) |
| 教学 Catalog | [`examples/catalog/README.md`](examples/catalog/README.md) |

版本变化见 [`CHANGELOG.md`](CHANGELOG.md)。真实演示文稿、项目素材和 Deck 级验证资料
保存在独立的 Slides 工作区，通过固定版本的 `@local` 包消费本 Theme。

## 开发验证

```sh
make validate
```

该目标验证物理安装快照、标准初始化、Starter、产品级 Catalog、公共边界、
布局、演讲者能力、Tinymist 静态文档，以及禁用系统字体时的 Poppins
隔离编译。可单独运行 `make font-isolation-check` 定位字体问题。真实 Deck 的内容与视觉
回归由 Slides 工作区独立执行。

## License

模板代码采用 [`LICENSE`](LICENSE) 中的 MIT License。外部 Deck 的论文、标识和素材不
自动获得同一许可。
