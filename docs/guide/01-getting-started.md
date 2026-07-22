# 01 · 从零创建第一份演示

读完本章，你可以安装 Theme、初始化 Deck、修改内容、预览并找到最终 PDF。

## 1. 检查环境

```sh
typst --version
make --version
```

安装 VS Code 后启用 Tinymist 扩展。Theme 自带 Poppins、Source Code Pro、New Computer
Modern 与 Libertinus Serif；不要另外安装同名字体。完整要求见 [安装文档](../INSTALL.md)。

## 2. 安装并初始化

在模板仓库根目录执行：

```sh
make install
typst init @local/systems-slides-template:0.6.0 my-talk
cd my-talk
make
```

初始 PDF 位于 `build/slides.pdf`。`make watch` 在保存时重编译，`make clean` 只删除当前
Deck 的 `build/`。

## 3. 修改第一份 Deck

在 `metadata.typ` 修改标题、短标题、作者与机构。日期默认由 Theme 在每次编译时调用
`datetime.today()`；归档版本可在 `globals.typ` 的 Theme 配置中传固定 `datetime(...)`。

标题页和目录页位于 `sections/1_frontmatter.typ`。普通内容位于
`sections/2_content.typ`：

```typst
= Motivation

#slide(title: [Remote I/O Exposes the Dependency Chain])[
  #lead[先说明约束，再介绍机制。]
  #points((
    point([Dependent work waits for remote data.]),
    point([Independent work may overlap the transfer.], level: 2),
  ))
]
```

`= Motivation` 建立章节；`slide` 创建普通页面。正文按书写顺序自然向下排列，无需
split。添加图片时继续使用原生 Typst：

```typst
#figure(
  image(asset-path("figures/architecture.svg"), fit: "contain"),
  caption: [Scheduling architecture],
) <architecture>
```

把文件放进 `assets/figures/`；`asset-path` 只返回锚定到本 Deck 的原生 path。

## 4. VS Code 预览

在 VS Code 中打开初始化后的 Deck 根目录，而不是单独打开 section。打开 `main.typ`，
运行 Tinymist Preview。`.vscode/settings.json` 已统一配置主入口和随 Deck 部署的字体。

## 5. 一个可执行的五页结果

[完整示例](examples/first-deck.typ) 包含标题页、目录、Points、原生 figure 与引用，共五个
物理页面；配套 SVG 位于 [assets](examples/assets/architecture.svg)。仓库通过
`make guide-examples-check` 编译它，避免文档代码失效。

下一步阅读 [Deck 结构](04-deck-structure.md)；若安装或预览失败，直接查看
[故障排查](13-troubleshooting.md)。
