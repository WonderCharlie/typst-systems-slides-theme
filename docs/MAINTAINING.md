# 架构与维护

本项目是可安装的 Touying Slides Theme。Starter、产品级 Catalog 和 Fixture 都是
仓库内消费者，只能单向依赖稳定公共包；真实 Deck 位于独立 Slides 工作区。

## 目录职责

```text
lib.typ                     唯一公共入口
src/                        页面、布局、flow、Points、容器和 runtime facade
themes/systems-slides-template/       Theme、master、视觉 token、profile 与字体源
template/                   typst init 的 Starter
examples/catalog/           稳定公共能力教学（28 个逻辑场景 / 45 个物理页面）
tests/                      小型 Fixture、边界与安装检查
packaging/                  安装快照 allowlist
tools/local-package.py      本地打包、安装、替换与卸载
docs/                       面向用户和维护者的说明
```

依赖方向：

```text
Starter / Product Catalog / Fixture
                  │
                  ▼
               lib.typ
                  │
                  ▼
        src/exports.typ ──▶ src/ + themes/systems-slides-template/
                                      │
                                      ▼
                          @preview/touying:0.7.4
```

公共实现不得引用 Example、Fixture、Deck 资产或仓库外路径。`src/layouts.typ` 不认识
Theme 和内容类型；`src/points.typ` 不认识 Touying 和页面几何；Theme 不决定论文叙事。

## 公共边界

根 `lib.typ` 只重新导出 `src/exports.typ`。新增公共名字前应证明它具有跨 Deck 的独立
内容模型、空间关系或运行时行为；仅改变默认参数时使用 Theme、profile、set/show 或
`.with(...)`，不增加同义包装。

公共名字不得包含会议、论文、页码或叙事阶段。内部 geometry、master、token、素材
渲染和运行时翻译 helper 不从根包导出。签名和参数契约只维护在声明前的 `///` 中。

## Theme 与通用层

- `themes/systems-slides-template/`：页面尺寸、字体颜色、metadata、header/footer、章节进度、
  page mark 和原生元素默认样式。
- `src/slides.typ` 与 `src/runtime*.typ`：Touying 生命周期、备注和渐进展示。
- `src/page-frame.typ`：整页表面、overlay、foreground/background 与 chrome。
- `src/flow.typ` 与 `src/layouts.typ`：有限正文流及内容无关的空间分配。
- `src/points.typ`：四级 Points 的内容模型、marker、缩进和节奏。
- `src/containers.typ`、`src/typography*.typ`：不决定页面位置的内容对象。

普通页标题具有单行不变量：master 在扣除 page mark、章节进度和 gutter 后，以实际剩余
宽度从 40pt 缩至最低 30pt；若仍放不下则必须报错。维护时不得重新引入标题换行、裁剪、
低于 30pt 的缩放或按内容叙事角色区分的标题布局，详细信息应由 Deck 放入 lead/正文。

真实 Deck 的素材、正文、归档日期和视觉差异只属于 Slides 工作区。它们可以证明公共能力
不足，但不能把单页测量值或叙事名字提升为 Theme 默认或公共接口。

## 安装快照与发布

`packaging/install-files.txt` 是安装内容的唯一 allowlist。物理快照只包含运行和初始化
所需文件，不包含 examples、tests、docs、开发工具或生成物。安装器拒绝符号链接、
未知目标和未经明确授权的同版本覆盖。

```sh
make package-check
make local-install-check
make install
make install-check
```

发布新版本时：

1. 更新 `typst.toml` 版本；
2. 同步 Starter 自引用和文档中的包坐标；
3. 更新 CHANGELOG 中对用户或维护者有意义的变化；
4. 运行 `make validate`；
5. 确认 GitHub Actions 在固定 Typst 0.15.0 与 Poppler 环境中通过；
6. 安装并验证新版本；
7. 确认 Theme 与产品 Catalog 的素材允许随目标仓库分发；
8. 提交 tag 或 GitHub Release。

同版本开发替换使用 `make reinstall`，不要把工作树软链接当作正式安装。

## 文档所有权

- 根 README：定位、原则、最短路径和导航；
- `docs/INSTALL.md`：安装生命周期与故障；
- `template/README.md`：Deck/Starter 工作流；
- `docs/USER_GUIDE.md` 与 `docs/guide/`：Deck 作者的统一入口、任务章节、配方和 Catalog 映射；
- 源码 `///`：唯一 API 签名与参数契约；
- 本文：架构、依赖、打包和发布；
- `tests/README.md`：验证范围和最低命令；
- Slides 工作区 Deck validation：带日期的测量、图形清单和差异结论。

普通源码注释只解释原因和不变量，不记录已完成迁移。

修改 Guide 时运行 `make guide-check`。该目标验证 13 个章节、27 个稳定公共绑定的可发现性、
28/45 Catalog 映射、公共导入边界，并在禁用系统/内嵌字体的条件下编译五页独立示例。
Guide 不复制完整参数表；公共签名变化仍以源码 `///` 和 Tinymist 检查为准。

## 修改后的最低验证

最低命令矩阵只维护在 [`../tests/README.md`](../tests/README.md)。大范围修改运行：

```sh
make validate
```

`.github/workflows/validate.yml` 对 `main` push 和 pull request 重跑同一命令。本地通过
不能替代远端检查；真实 Tinymist hover/signature help 仍需具有 Tinymist 二进制的机器
运行 `make tinymist-docs-check`。

真实 Deck 的图形几何与高分辨率视觉检查由 Slides 工作区维护。Theme 仓库构建物统一
进入 `build/`，不得批准当前输出为新基准来掩盖差异。
