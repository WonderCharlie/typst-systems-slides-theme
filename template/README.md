# Systems Slides Template Starter

这是 `@local/systems-slides-template:0.6.0` 的最小初始化骨架。它固定生成四页：标题页、
目录页、默认 Points 自然流页面，以及使用 Typst 原生 `image` / `figure` / 引用语义的媒体页。
Theme 底层继续使用官方 `@preview/touying:0.7.4`。

## 初始化

先在 Theme 仓库安装本地包，再在任意目录创建 Deck：

```sh
make install
typst init @local/systems-slides-template:0.6.0 my-talk
cd my-talk
make
```

输出为 `build/slides.pdf`。初始化结果是独立项目，不依赖 Theme 源码仓库的位置。

## 文件职责

| 文件 | 职责 |
| --- | --- |
| `metadata.typ` | 标题、作者和机构；日期默认在编译时自动取得 |
| `globals.typ` | 按名导入 Starter 实际使用的公共 API、配置 Theme、定义 `asset-path` |
| `main.typ` | 唯一编译入口和 section 顺序 |
| `sections/1_frontmatter.typ` | 标题页、目录页和演讲者备注 |
| `sections/2_content.typ` | 默认 Points 自然流和原生 figure 示例 |
| `assets/` | 当前 Deck 自己的媒体 |
| `fonts/` | 初始化时从已安装 Theme 包物化的字体副本 |

Starter 只演示最短路径。复杂布局、`body-flow`、region/split、渐进展示、页面层、
`panel`、`callout` 和 Theme 配色请查看 Theme 的 `docs/USER_GUIDE.md` 与产品级 Catalog；
公共函数的参数契约在 VS Code 中通过 Tinymist hover 和参数提示查看。

## 资源路径

`globals.typ` 中的 `asset-path(relative)` 将资源名锚定到当前 Deck 的 `assets/`，只负责返回
原生 Typst `path`。页面继续直接使用：

```typst
#image(asset-path("images/result.svg"))
#figure(image(asset-path("images/result.svg")), caption: [Evaluation result])
```

因此无论单独打开 Deck，还是从外层 workspace 打开，资源路径都不依赖 section 深度。

## 编译与预览

```sh
make          # build/slides.pdf
make watch    # 持续编译
make pdfpc    # build/slides.pdfpc
make debug    # build/slides-layout-debug.pdf
make clean    # 仅删除当前 Deck 的 build/
```

Tinymist 和 Makefile 都只从当前项目的 `fonts/` 发现字体，并禁用系统字体和 Typst 内嵌字体。
不需要安装 Poppins、Source Code Pro 或数学字体，也不需要为每个 Deck 创建独立 workspace。
`sections/*.typ` 由 `main.typ` include；首次预览请打开 `main.typ`，随后即可在 section 中编辑。

演讲者备注使用 `runtime.speaker-note[...]`，`make pdfpc` 会生成同名 `.pdfpc` 文件。Theme
默认使用 `datetime.today()`；归档版本可在 `globals.typ` 中显式传入 `date` 固定日期。
