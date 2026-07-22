# 本地安装与初始化

`systems-slides-template` 作为 Typst 本地包使用：主题名是
`@local/systems-slides-template:0.6.0`，底层演示框架始终来自官方
`@preview/touying:0.7.4`。仓库不包含 Touying 副本。

## 环境要求

- Typst 0.15.0 或更新版本；
- GNU Make；
- Python 3.11 或更新版本；
- 首次编译时能够读取缓存或下载 `@preview/touying:0.7.4`。

不要在系统中另行安装字体。`themes/systems-slides-template/assets/fonts/` 是唯一字体源：Poppins
用于演示文本，Source Code Pro 用于代码，New Computer Modern 与 Libertinus Serif 用于
原生数学排版。仓库编译和初始化 Deck 都显式禁用系统字体与 Typst 内嵌字体，并使用部署副本。

`make install` 的安装生命周期检查只使用 macOS/POSIX 基础文本工具和 Poppler 的
`pdfinfo`，不要求安装 `rg`。默认完整开发验证还会使用 `rg` 和 `pdftotext`，但不
需要额外 Python 包；真实 Deck 的附加视觉验证依赖由其 Slides 工作区自行管理。

## 首次安装

进入仓库根目录：

```sh
make install
make install-check
make install-path
```

`make install` 根据 [`../packaging/install-files.txt`](../packaging/install-files.txt)
创建物理快照，再安装到 Typst 报告的用户 package root：

```text
<package-root>/local/systems-slides-template/0.6.0/
```

它不是指向 Git 工作区的符号链接。安装包只包含运行和初始化所需的七个根：

```text
typst.toml  lib.typ  LICENSE  thumbnail.png  src/  themes/  template/
```

产品级 Catalog、测试、文档、开发工具、根 Makefile 和生成物都不会
进入用户 package 目录；它们仍保留在 Git 仓库中用于教学和回归。不要硬编码平台
路径；`make install-path` 会显示当前 Typst 实际使用的位置。

## 创建并编译演示文稿

安装后可在任意目录执行标准命令：

```sh
typst init @local/systems-slides-template:0.6.0 my-talk
cd my-talk
make
```

输出为 `build/slides.pdf`。初始化项目中的常用命令：

```sh
make             # 编译 PDF
make watch       # 持续编译
make pdfpc       # 导出 build/slides.pdfpc
make clean       # 删除该项目的 build/
```

初始化出的 `globals.typ` 继续导入同一个 `@local/systems-slides-template:0.6.0`，因此项目
不依赖模板仓库路径。字体唯一源属于 Theme；安装工具会在包快照中为 starter 物化完整
字体部署，因此初始化项目自带可直接供 Typst/Tinymist 发现的字体与编辑器配置。

维护者可显式运行：

```sh
make font-isolation-check
```

该检查使用 `--ignore-system-fonts --ignore-embedded-fonts` 编译 Starter、Catalog 和从本地包初始化的
独立 Deck，将任何 Typst 字体警告视为失败，要求数学字体精确为 `NewCMMath-Regular`，并拒绝 PDF 中的 Arial、Helvetica、Avenir、
Menlo、Monaco、DejaVu Sans Mono 或 Liberation Sans。

## 更新与同版本替换

取得源码更新后先验证：

```sh
make validate
make install
make install-check
```

安装器把版本视为不可变标识：

- 目标不存在时，`make install` 创建它；
- 内容相同时，重复安装是幂等操作；
- 同版本内容不同时，`make install` 拒绝覆盖；
- 确认要用当前工作区替换同版本时，显式运行 `make reinstall`。

```sh
make reinstall
make install-check
```

公共接口发布新版本时，应同步更新 `typst.toml`、starter 的 `@local` 自引用、文档
和版本测试，再安装为新版本目录。

## 安全卸载

```sh
make uninstall
```

卸载只删除由安装器标记、且与当前包名和版本完全一致的目录。它不会删除 package
root、其他包、其他版本或仓库。若安装内容被人工修改，卸载会拒绝继续；先检查并
用 `make reinstall` 恢复受管理快照。

## 维护者的隔离快照

以下命令只在根 `build/` 中生成物理包，不改动用户安装：

```sh
make package          # build/dist/packages/local/systems-slides-template/0.6.0/
make package-check    # 生成并校验发行快照
make package-stage    # build/packages/local/systems-slides-template/0.6.0/
make local-install-check
```

`local-install-check` 在临时 package root 中覆盖安装、`typst init`、PDF/PDFPC 编译、
同版本保护、替换、卸载和路径逃逸防护。`make init-check` 是它的等价验证入口。

## 常见问题

### 找不到 `@local/systems-slides-template:0.6.0`

运行：

```sh
make install-path
make install-check
```

前者显示目标，后者从真实用户 package root 初始化并编译一次 starter。

### 找不到 `@preview/touying:0.7.4`

这表示本地 Theme 已被找到，但官方 Touying 尚未缓存且当前环境无法下载。恢复
Typst 的 package 网络访问或预先缓存该官方包；不要复制 Touying 源码进本仓库，
也不要把 `systems-slides-template` 改写成 `@preview` 自引用。

### Tinymist 仍显示旧文档

本地安装是物理快照，修改源码不会自动同步：

```sh
make reinstall
make tinymist-installed-docs-check
```

然后重载 VS Code 窗口。
