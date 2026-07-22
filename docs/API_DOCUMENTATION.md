# Tinymist API 文档规范

稳定公共 API 的签名、参数类型、默认值、特殊值和必要约束，只维护在函数声明前紧邻的
连续 `///` 块中。Tinymist 使用它生成 hover 和 signature help；Markdown 指南只展示
决策与典型调用，不复制完整参数表。

## 推荐格式

```typst
/// 在有限正文框中按行分配区域；适用于自然内容之后需要占满余高的布局。
///
/// - regions (array): 必填的内容区域，接受 content 或 region。
///   数量必须与最终轨道一致。
/// - rows (array, auto, none): 行轨道，默认 `auto` 继承 profile。
///   `none` 推导自然轨道；显式数组优先。
/// -> content
#let example-flow(regions, rows: auto) = { /* implementation */ }
```

规则：

1. 第一行说明用途、适用场景或关键误用风险，不复述函数名。
2. 参数按真实签名顺序写成 `- name (types): description`；`..args` 写作 `args`。
3. prose 只保留理解调用所需的信息：必填/默认、`auto`/`none` 等特殊值、关键覆盖顺序和
   真实约束；不机械添加“职责、允许、特殊值、覆盖/继承、约束”等标签。
4. 单行不超过 100 个字符；较长参数使用连续的 `///   ` 缩进续行。
5. 两个参数之间不得插入空 `///` 行，否则 Tinymist 可能丢失前一参数的提示。
6. 文档块最后且仅有一个 `-> return-type`。
7. `///` 与声明之间没有普通注释或空行；普通维护注释应与它隔开。
8. 稳定 facade 保留真实函数签名，不用无签名别名代替。
9. 返回字典字段若与构造参数相同，不再维护第二份字段文档。
10. 普通 `//` 只解释设计原因、模块边界和代码无法表达的不变量；长签名可用它分组。

Tinymist 结构化类型必须使用当前编辑器能够识别的词汇；alignment 等未被识别的运行时
类型记为 `any`，并在 prose 中说明实际接受 Typst alignment。允许的类型表由
`tests/check-tinymist-docs.py` 维护。

## 覆盖范围

检查对象由测试中的显式 allowlist 定义，共 27 个稳定绑定、193 个参数，包括顶层
Theme、页面、page frame、布局、body flow、Points、容器、文本 helper，以及
`runtime` 的备注与渐进展示能力。内部
master、geometry、token、资源渲染 helper、Example 辅助函数和 Fixture 不属于稳定文档。

## VS Code / Tinymist

Starter 已开启 hover、参数提示、文档渲染和多文件主入口解析。源码文档更新后，本机
已安装包不会自动变化；验证安装版本前先执行：

```sh
make reinstall
make tinymist-installed-docs-check
```

静态验证：

```sh
make comment-check
make tinymist-docs-static-check
```

真实 LSP 验证需要本机 Tinymist：

```sh
make tinymist-docs-check
```
