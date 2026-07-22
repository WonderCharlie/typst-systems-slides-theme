# 11 · Speaker Notes、PDFPC 与 Presenter View

读完本章，你可以为页面添加备注、导出 PDFPC，并生成观众与演讲者双画布版本。

## Speaker note

备注必须紧邻所属 slide；多次调用会累积：

```typst
#slide(title: [Evaluation Result])[
  #points((point([P99 latency falls by 28%.]),))
]
#runtime.speaker-note[先解释 baseline，再指出改善来自重叠而非更快的设备。]
```

备注可限定子页。完整 mode、setting 和 subslide 规则请悬停
`runtime.speaker-note`。

## PDFPC

```sh
make pdfpc
```

该命令先生成普通观众 PDF，再生成 `build/slides.pdfpc`。PDFPC 文件保存逻辑 slide、
物理子页与 speaker notes 的关系，不替代 PDF。

## Presenter view

把 `runtime.presenter-view(...)` 作为高级 Touying 配置片段传给 Theme，可生成左右双画布：

```typst
#let deck-theme = systems-slides-theme.with(
  ..runtime.presenter-view(side: right),
  title: deck-meta.title,
)
```

观众侧仍是普通 16:9 页面，备注侧显示演讲者内容，整体页面宽度变为两张画布之和。
归档和公开版本通常发布普通 PDF；备注可能包含未公开信息，发布前检查 PDFPC 与
presenter 产物。Starter 和测试中的 presenter fixture 是完整可执行规范源。
