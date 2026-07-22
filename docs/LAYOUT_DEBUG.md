# VS Code 布局调试预览

模板只通过显式编译输入控制调试绘制，不修改 slide、region 或正文调用，也不会把
蒙版写入普通 Tinymist Preview 或 PDF 构建产物。

## 仓库开发

以文件夹方式打开仓库并启动 Tinymist Preview 时，页面保持无蒙版的正常视觉。需要
检查公共容器边界时运行 `make layout-debug-check`，生成的诊断 Fixture 显示：

- 紫色：Theme 正文区；
- 蓝色：`body-flow`；
- 橙色：纵向 split 与 row region；
- 绿色：横向 split 与 column region。

Tinymist Preview 仍可正常使用源码/预览导航。普通 `make`、`typst compile` 和导出的
PDF 都保持无蒙版模式。

## 初始化后的 slides 工程

`typst init @local/systems-slides-template:0.6.0 my-talk` 生成的项目直接对 `main.typ` 启动
Tinymist Preview 即可。需要静态布局诊断时，命令面板中的
**Tasks: Run Task → slides: build layout debug PDF** 会额外生成：

```text
build/slides-layout-debug.pdf
```

正式 `make`、`make pdfpc` 与普通 Tinymist workspace 均不会启用蒙版。

## 调试模式

模板默认使用 `off`。命令行可显式选择诊断模式：

```sh
typst compile --input layout-debug=boxes main.typ build/debug.pdf
typst compile --input layout-debug=labels main.typ build/debug.pdf
```

`boxes` 只显示边界，`labels` 同时显示名称；删除该输入或使用
`layout-debug=off` 即恢复干净输出。

复杂页面建议为结构容器提供稳定诊断名：

```typst
#body-flow(
  (
    region(lead[Editable introduction], name: "natural lead"),
    region(
      column-split(
        (
          region(figure(image("result.svg"), caption: [Result]), name: "result figure"),
          region(points(...), name: "result explanation"),
        ),
        name: "result columns",
      ),
      name: "remaining content",
    ),
  ),
  profile: layout-profile(name: "result flow", rows: (auto, 1fr)),
)
```

`name` 只进入诊断标签和错误信息，不决定内容语义或布局。

## Chrome DevTools 式 hover 的实现边界

当前静态诊断 PDF 已实现层次化颜色和容器标签，但 Typst 输出本身不会响应鼠标 hover。
若要实现“悬停只高亮一个 region、点击锁定、查看父级和属性面板”，需要单独的 VS
Code companion previewer；不应把 JavaScript 或编辑器状态放入 Theme。

推荐协议保持三层分离：

```text
Typst instrumentation
  └── id / parent / kind / name / depth / rendered bounds
        ↓
Tinymist SVG preview stream
        ↓
VS Code WebView inspector
  └── hover / pin / breadcrumb / property panel / source jump
```

实现时应：

1. 增加仅供开发使用的 `layout-debug=inspect` 输出，把稳定 region id、父 id 和类型附着
   到调试 SVG 命中区域；普通 `off/boxes/labels` 行为不变。
2. 建立独立 VS Code 扩展，以 WebView 承载预览；通过事件委托处理 region 的
   `pointerenter`、`pointerleave` 和 `click`，不要逐节点重建页面。
3. WebView 维护当前 hover、锁定节点、祖先链、透明度和类型过滤器；选中节点时只改变
   DOM 覆盖层，不重新运行 Typst 排版。
4. 扩展通过 `vscode.postMessage` 接收选中 id，再调用编辑器 API 跳转到对应源码；没有
   稳定源码位置时退化为搜索唯一的 `name`，因此诊断名应在一页内唯一。
5. companion extension 放在开发工具或独立仓库中，不进入 `@local/systems-slides-template` 安装
   快照，也不 fork Touying 或 Tinymist。

这种边界使 Theme 继续只负责排版和可观测区域，编辑器扩展只负责交互。
