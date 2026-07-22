# 04 · Deck 目录和文件职责

读完本章，你可以安全拆分一份演示，并理解预览、字体、资源和构建入口。

```text
my-talk/
├── main.typ          唯一编译入口，include sections
├── globals.typ       公共导入、Theme 配置、asset-path、跨页常量
├── metadata.typ      标题、作者和机构
├── sections/         按论证顺序保存页面内容
├── assets/           本 Deck 的图片、SVG、数据与 bibliography
├── fonts/            初始化时物化的 Theme 字体副本
├── .vscode/          Tinymist 主入口、字体和预览设置
├── Makefile          pdf/watch/debug/pdfpc/clean
└── build/            生成物，不提交 Git
```

`main.typ` 先安装 `deck-theme`，再按顺序 include section。section 不是独立文档，不应单独
编译或预览。Deck 只从 `@local/systems-slides-template:0.6.1` 公共入口导入；不要引用包的
`src/`、`themes/`、master 或 geometry。

## 资源路径

Starter 在 `globals.typ` 定义 `asset-path(relative)`。它验证输入后返回
`path("assets/" + relative)`，不负责渲染、尺寸、caption 或布局：

```typst
#image(asset-path("figures/result.svg"), fit: "contain")
```

Deck 的 assets 不属于 Theme；Theme 字体则由安装包部署到 `fonts/`，并由 Makefile 和
Tinymist 使用同一路径。不要写绑定某台电脑用户目录的绝对路径。

## 章节组织

一级标题建立章节和目录上下文，普通页面用 `slide`：

```typst
= Evaluation
#include "sections/7_evaluation.typ"
```

文件按内容规模拆分，而不是“一页一个私有布局组件”。跨页确需复用的最终内容可命名为
`*-snapshot`；只使用一次的组合应直接写在对应 section。

## 构建命令

- `make`：生成 `build/slides.pdf`。
- `make watch`：持续预览。
- `make pdfpc`：生成 `build/slides.pdfpc`。
- `make debug`：生成独立布局调试 PDF。
- `make clean`：经过路径保护后只删除当前 Deck 的 `build/`。
