// Systems Slides Theme entry point, organized after Touying's Metropolis theme:
// page configuration, lifecycle methods, metadata, colors, and store values
// are registered independently, then caller overrides are merged last.

#import "@preview/touying:0.7.4": (
  config-colors,
  config-common,
  config-info,
  config-methods,
  config-page,
  config-store,
  touying-slides,
  utils,
)
#import "tokens.typ": (
  font-sans,
  font-mono,
  faint-grey,
  dark-grey,
  grey,
  ink,
  light-grey,
  purple,
  slide-height,
  slide-width,
  white,
)
#import "../../src/media.typ": identity-asset-resolver
#import "geometry.typ": systems-layout
#import "master.typ": default-footer-date-format, master-footer, master-header
#import "../../src/slides.typ": section-slide, slide

/// 安装 systems-slides-template 的 Touying Theme，统一演示文稿的视觉、原生内容默认值和页面生命周期。
/// 最后的 Touying 配置片段可用于高级覆盖。
///
/// - title (content): 完整文档标题，默认 `[Paper Title]`；写入 Touying info，并在 `footer-title: auto` 时用于页脚。
/// - short-title (auto, content): 短标题元数据，默认 `auto` 交由 Touying 解析；不替代页脚标题。
/// - author (content): 作者元数据，默认 `[Author Name]`；单页标题页可用 `author-lines` 改变展示。
/// - institution (none, content): 机构元数据，默认 `none`；标题页不会自动渲染该字段。
/// - date (datetime, content): 页脚日期，默认 `datetime.today()`；datetime 按日期格式渲染，归档构建应传固定日期。
/// - footer-title (auto, content): 页脚中部标题；默认 `auto` 使用完整文档标题，不读取 short title。
/// - footer-logo (none, str, any, content): 页脚左侧标识；
///   默认 `none` 隐藏。path/content 直接使用，字符串经 asset resolver 解析。
/// - footer-logo-width (none, length): 标识宽度覆盖；默认 `none` 使用 master 槽位宽度，显式长度不得超出页脚。
/// - footer-date-format (str): datetime 的页脚格式；默认内建格式，非 datetime 内容不使用它。
/// - title-color (color): 普通页标题颜色，默认主题紫色；后置 Touying store 配置仍可覆盖。
/// - rule-color (color): 标题分隔线颜色，默认主题灰色；后置 store 配置仍可覆盖。
/// - image-max-width (ratio, relative, length): 原生图片的最大宽度，默认 `100%`。 百分比和相对长度以当前内容区域为基准。
/// - image-grow (bool): 是否放大小于可用宽度的图片；默认 `false`，仅在超宽时缩小，显式 image 宽度优先。
/// - figure-gap (length): 原生 figure 内容与 caption 的默认间距，默认 `8pt`；单个 figure 可覆盖。
/// - figure-caption-size (length): 原生 caption 默认字号，默认 `18pt`；caption 内局部 text 样式优先。
/// - figure-caption-fill (color): 原生 caption 默认颜色，默认主题正文色；局部文字颜色优先。
/// - figure-caption-align (any): 原生 caption 默认对齐，默认居中；位置仍由 figure.caption 的 position 决定。
/// - list-indent (length): 原生 list/enum 整体缩进，默认 `0pt`；不影响自定义 Points。
/// - list-body-indent (length): 原生列表标记到正文的距离，默认 `18pt`。 该距离必须能容纳标记。
/// - list-spacing (length): 原生非紧凑列表同级间距，默认 `14pt`；局部列表设置优先。
/// - table-text-size (length): 原生 table 单元格字号，默认 `18pt`；局部 text 样式优先，正文表格不应再缩小。
/// - table-inset (length, dictionary): 原生 table 单元格内边距，默认 `(x: 10pt, y: 7pt)`；显式 table.inset 可覆盖。
/// - table-stroke (none, any): 原生 table 默认分隔线，默认为 `0.7pt` 浅灰线；`none` 关闭分隔线，其他值应是 Typst stroke。
/// - table-header-fill (none, color): 首行表头背景，默认 Theme 浅灰；`none` 关闭表头填充，仅通过 table 原生 fill 规则生效。
/// - table-header-weight (str, int): 首行表头字重，默认 `"semibold"`；局部单元格文字样式优先。
/// - code-font (str): raw 代码字体，默认 Theme 随包分发的 `"Source Code Pro"`；不应指向系统字体。
/// - code-size (length): raw 代码默认字号，默认 `16pt`；局部 text/raw 样式优先。
/// - footnote-size (length): 原生脚注默认字号，默认 `14pt`；脚注内容的局部 text 样式优先。
/// - asset-resolver (function): 兼容字符串 Theme 槽位的解析器，默认原样返回；Deck path 不经过它，也不应借此实现项目路径前缀。
/// - section-progress (bool): 是否显示一级章节进度，默认 `false`；后置 store 配置可覆盖。
/// - section-slides (bool): 是否为一级章节自动插入分隔页，默认 `false`；启用会改变物理页数。
/// - args (arguments): 后置 Touying 配置片段，默认空；同名配置覆盖 Theme 默认且必须可被 Touying 合并。
/// - body (content): 必填的整份演示文稿内容；在 Theme 配置安装后原样渲染。
///
/// -> content
#let systems-slides-theme(
  // Document metadata.
  title: [Paper Title],
  short-title: auto,
  author: [Author Name],
  institution: none,
  date: datetime.today(),

  // Footer and slide chrome.
  footer-title: auto,
  footer-logo: none,
  footer-logo-width: none,
  footer-date-format: default-footer-date-format,
  title-color: purple,
  rule-color: grey,

  // Native image and figure defaults.
  image-max-width: 100%,
  image-grow: false,
  figure-gap: 8pt,
  figure-caption-size: 18pt,
  figure-caption-fill: ink,
  figure-caption-align: center,

  // Native list and table defaults.
  list-indent: 0pt,
  list-body-indent: 18pt,
  list-spacing: 14pt,
  table-text-size: 18pt,
  table-inset: (x: 10pt, y: 7pt),
  table-stroke: 0.7pt + light-grey,
  table-header-fill: faint-grey,
  table-header-weight: "semibold",

  // Code, notes, assets, and lifecycle.
  code-font: font-mono,
  code-size: 16pt,
  footnote-size: 14pt,
  asset-resolver: identity-asset-resolver,
  section-progress: false,
  section-slides: false,
  ..args,
  body,
) = {
  show: touying-slides.with(
    config-page(
      width: slide-width,
      height: slide-height,
      margin: (
        left: systems-layout.body.left,
        right: slide-width - systems-layout.body.right,
        top: systems-layout.body.top,
        bottom: slide-height - systems-layout.body.bottom,
      ),
      header: master-header,
      footer: master-footer,
      footer-descent: 0pt,
      fill: white,
      numbering: none,
    ),
    config-common(
      slide-level: 2,
      slide-fn: slide,
      new-section-slide-fn: if section-slides { section-slide } else { none },
      new-subsection-slide-fn: none,
      receive-body-for-new-section-slide-fn: false,
      breakable: false,
      clip: false,
      detect-overflow: true,
      zero-margin-header: true,
      zero-margin-footer: true,
      show-strong-with-alert: false,
      reset-page-counter-to-slide-counter: true,
      auto-offset-for-heading: false,
      nontight-list-enum-and-terms: false,
    ),
    config-methods(
      init: (self: none, body) => {
        set text(font: font-sans, size: 24pt, fill: ink)
        set par(leading: 0.48em, spacing: 0pt)
        set list(indent: list-indent, body-indent: list-body-indent, spacing: list-spacing)
        set enum(indent: list-indent, body-indent: list-body-indent, spacing: list-spacing)
        set table(
          inset: table-inset,
          stroke: table-stroke,
          fill: (_, row) => if row == 0 { table-header-fill } else { none },
        )
        show table.cell: set text(font: font-sans, size: table-text-size)
        show table.cell.where(y: 0): set text(
          weight: table-header-weight,
          fill: dark-grey,
        )
        show raw: set text(font: code-font, size: code-size)
        show footnote.entry: set text(font: font-sans, size: footnote-size)
        // Native images keep their intrinsic size whenever they fit and are
        // only reduced when they exceed the current content area's width.
        show image: image-body => utils.fit-to-width(
          width: image-max-width,
          grow: image-grow,
          shrink: true,
          image-body,
        )
        // Slides use Typst's native figure as the only captioned-media
        // interface. The Theme supplies presentation defaults through normal
        // set/show rules; a deck can override them locally without learning a
        // second figure API. Numbering, supplement, outline and labels remain
        // native Typst semantics and are intentionally not reset here.
        set figure(gap: figure-gap)
        show figure.caption: set text(
          font: font-sans,
          size: figure-caption-size,
          fill: figure-caption-fill,
        )
        show figure.caption: set align(figure-caption-align)
        body
      },
      alert: utils.alert-with-primary-color,
    ),
    config-info(
      title: title,
      short-title: short-title,
      author: author,
      institution: institution,
      date: date,
    ),
    config-colors(
      primary: purple,
      neutral-light: light-grey,
      neutral-lightest: white,
      neutral-darkest: ink,
    ),
    config-store(
      footer-title: footer-title,
      footer-logo: footer-logo,
      footer-logo-width: footer-logo-width,
      footer-date-format: footer-date-format,
      title-color: title-color,
      rule-color: rule-color,
      asset-resolver: asset-resolver,
      section-progress: section-progress,
    ),
    // Keep this last: config-page/common/info/colors/store values supplied by
    // a deck must be able to override every theme default.
    ..args,
  )

  body
}
