# Assets

将当前演示文稿专用的 SVG、PNG、PDF 或其他媒体放在这里。section 从
`globals.typ` 导入 `asset-path`，继续使用原生媒体接口，例如：

```typst
#image(asset-path("diagrams/architecture.svg"))
#figure(image(asset-path("plots/result.svg")), caption: [Result])
```

`asset-path` 只把输入锚定到这个 deck 的 `assets/` 并返回原生 Typst `path`，不设置
图片尺寸、caption 或布局。`example-mark.svg` 是 starter 对 Theme 原生 path 槽位的最小示例，
可以直接替换或删除。

不要把模板实现或其他 deck 的素材复制到本目录。
