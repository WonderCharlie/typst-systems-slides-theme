# 03 · 制作 Slides 所需的 Typst 基础

读完本章，你可以阅读 Starter 和 Catalog 的 Typst 源码，并编写常见演示内容。

## 标记模式与代码模式

普通文字直接书写；`#` 把表达式结果插入内容：

```typst
Latency is #text(fill: red)[visible] to the application.
#let metric = 8.6
Measured latency: #metric ms.
```

`[ ... ]` 是 content，`"..."` 是 string，`(...)` 可表示 array 或具名 dictionary：

```typst
#let labels = ([Baseline], [Relay])
#let metadata = (title: [Relay], author: [A. Researcher])
```

函数用位置参数和具名参数调用：

```typst
#let metric-row(label, value, emphasized: false) = [#label: #value]
#metric-row([P99], [8.6 ms], emphasized: true)
```

## 条件、循环与作用域

```typst
#for item in labels [
  - #item
]
#if labels.len() > 1 [Comparison is available.]
```

花括号建立代码作用域，内容块保留排版内容。不要把一次页面布局抽成函数；只有数据或
跨页稳定内容确实复用时才提取变量。

## import、include 与项目 root

`import` 取得绑定，`include` 把另一个文件的内容放在当前位置：

```typst
#import "globals.typ": deck-theme
#include "sections/2_results.typ"
```

只编译 `main.typ`。相对路径以定义它的源文件为锚；Deck 资源统一经 `asset-path` 返回
原生 path，避免 section 层级改变路径。

## set 与 show

`set` 改变元素默认值，`show` 转换匹配内容。Theme 已安装全局规则，Deck 通常只在局部
内容块覆盖：

```typst
#block[
  #set text(fill: navy)
  Only this block uses navy text.
]
```

不要在 section 中建立一套全局 Theme。

## label、ref 与查询

元素后的 `<label>` 创建标签，`@label` 生成原生引用：

```typst
#figure(rect(width: 80pt, height: 30pt), caption: [Architecture]) <arch>
As shown in @arch, scheduling separates ready work.
```

引用、bibliography 和查询由 Typst 提供；Theme 保留它们的编号和语义。进一步内容见
[原生技术内容](06-native-content.md)。
