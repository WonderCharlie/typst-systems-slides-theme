// Stable slide lifecycle for the systems-slides-template theme.

#import "@preview/touying:0.7.4": (
  cols,
  components,
  config-common,
  config-page,
  config-store,
  touying-slide,
  touying-slide-wrapper,
  utils,
)
#import "../themes/systems-slides-template/tokens.typ": (
  deep-purple,
  font-sans,
  ink,
  purple,
  white,
)
#import "../themes/systems-slides-template/master.typ": master-header
#import "../themes/systems-slides-template/geometry.typ": systems-layout
#import "../themes/systems-slides-template/marks.typ": validate-page-marks
#import "media.typ": render-media
#import "runtime.typ": page-frame-config
#import "layouts.typ": _layout-debug-container

#let passthrough(..parts) = parts.pos().sum(default: none)

/// 创建遵循 Touying 生命周期的标准正文页。
/// 页面保留 Theme chrome、计数、分步展示和局部 page-frame 能力。
///
/// - title (auto, none, content, function): 页面标题；默认 `auto` 使用当前二级 heading，`none` 隐藏默认 header。
///   frame 和后置 config 可覆盖结果。
/// - align (any, auto): 正文整体对齐；默认 `auto` 保持自然流，仅包装正文而不改变 master chrome。
/// - frame (auto, dictionary): 内容无关的 `page-frame`；默认 `auto` 继承 Theme，不能传普通字典或叙事角色配置。
/// - marks (array): 当前逻辑页的 `page-mark` 数组，默认空；由 Theme chrome 渲染并在全部 subslides 保持一致。
/// - counted (auto, bool): 是否推进逻辑页计数；默认 `auto` 继承 Theme，`false` 冻结计数但不删除物理页。
/// - config (dictionary): Touying 单页配置，默认空字典；作为高级逃生口最后覆盖普通页面设置。
/// - repeat (auto, int): subslide 数，默认 `auto` 由 Touying 推导；无法自动检测的回调动画需传足够大的正整数。
/// - setting (function): 正文转换函数，默认恒等函数；在 Theme 正文字体安装后应用且必须返回 content。
/// - composer (auto, function, array, int): 多个 body 的组合器；默认 `auto` 使用 Touying 策略，整数列数必须为正。
/// - bodies (arguments): 零个或多个正文片段，按 composer 组合；最终内容必须适合页面可用区域。
///
/// -> content
#let slide(
  title: auto,
  align: auto,
  frame: auto,
  marks: (),
  counted: auto,
  config: (:),
  repeat: auto,
  setting: body => body,
  composer: auto,
  ..bodies,
) = touying-slide-wrapper(self => {
  assert(
    title in (auto, none) or type(title) in (content, function),
    message: "slide.title must be auto, none, content, or a function",
  )
  assert(
    align == auto or type(align) == alignment,
    message: "slide.align must be an alignment or auto; got " + repr(align),
  )
  assert(type(config) == dictionary, message: "slide.config must be a dictionary")
  validate-page-marks(marks)
  assert(
    counted == auto or type(counted) == bool,
    message: "slide.counted must be a boolean or auto; got " + repr(counted),
  )
  assert(
    repeat == auto or (type(repeat) == int and repeat > 0),
    message: "slide.repeat must be auto or a positive integer; got " + repr(repeat),
  )
  assert(type(setting) == function, message: "slide.setting must be a function")
  assert(
    composer == auto or type(composer) in (function, array, int),
    message: "slide.composer must be auto, a function, an array, or an integer",
  )
  if type(composer) == int {
    assert(composer > 0, message: "slide.composer integer must be positive")
  }
  let header = if title == none { none } else {
    state => master-header(state, title: title)
  }
  // Resolve delayed page-layer callbacks against the same per-slide config
  // that Touying applies during rendering. This keeps `config-store` useful as
  // an advanced escape hatch without making a semantic page wrapper necessary.
  let frame-state = utils.merge-dicts(self, config)
  let frame-config = page-frame-config(frame-state, frame: frame)
  let marks-config = config-store(page-marks: marks)
  let counted-config = if counted == auto {
    (:)
  } else {
    config-common(freeze-slide-counter: not counted)
  }
  let effective = utils.merge-dicts(
    self,
    config-page(header: header),
    frame-config,
    marks-config,
    counted-config,
  )
  let local-setting = body => {
    set text(font: font-sans, size: 24pt, fill: ink)
    show: setting
    let standard-body = title != none and (
      frame == auto or (frame.chrome != false and frame.margin == auto)
    )
    let flowed = if standard-body {
      pad(top: systems-layout.body.content-inset-top, body)
    } else {
      body
    }
    let aligned = if align == auto { flowed } else { std.align(align, flowed) }
    let body-inset = if frame == auto { auto } else { frame.body-inset }
    let inset-body = if body-inset == auto {
      aligned
    } else {
      block(
        width: 100%,
        height: 100%,
        above: 0pt,
        below: 0pt,
        inset: body-inset,
        aligned,
      )
    }
    _layout-debug-container(inset-body, "theme-body", "Theme body")
  }
  touying-slide(
    self: effective,
    config: config,
    repeat: repeat,
    setting: local-setting,
    composer: composer,
    ..bodies,
  )
})

#let normalize-lines(value, fallback) = {
  let resolved = if value == auto { fallback } else { value }
  if type(resolved) == array { resolved } else { (resolved,) }
}

#let normalize-media-list(value) = {
  if value == none { () } else if type(value) == array { value } else { (value,) }
}

/// 创建无普通页 chrome 的标题页。
/// 标题、作者、活动标识和机构标识来自 Theme 元数据及本页参数。
///
/// - config (dictionary): Touying 标题页配置，默认空字典；在标题页预设之后合并并具有更高优先级。
/// - title-lines (auto, content, array): 主标题分行，默认 `auto` 使用文档标题；数组每项生成独立行。
/// - author-lines (auto, content, array): 作者分行，默认 `auto` 使用作者元数据；数组每项生成独立行。
/// - subtitle (none, content): 主标题后的副标题，默认 `none` 不创建该行。
/// - affiliations (array): 下半区机构标识，默认空数组隐藏；path 直接加载，字符串经 Theme resolver，显式轨道数须匹配标识数。
/// - affiliation-layout (auto, dictionary): 机构标识的列宽、间距、尺寸与光学偏移；默认 `auto`，显式字段浅合并覆盖内建布局。
/// - event-mark (none, str, any, content): 左上活动标识，默认 `none`；path 直接加载，字符串经 Theme resolver。
/// - event-layout (auto, dictionary): 活动标识槽位与光学偏移；默认 `auto`，显式字段浅合并覆盖内建布局。
/// - extra (none, content): 作者行后的辅助内容，默认 `none` 不创建该行。
/// - counted (bool): 标题页是否参与逻辑计数，默认 `true`；`false` 冻结计数但保留物理页。
///
/// -> content
#let title-slide(
  config: (:),
  title-lines: auto,
  author-lines: auto,
  subtitle: none,
  affiliations: (),
  affiliation-layout: auto,
  event-mark: none,
  event-layout: auto,
  extra: none,
  counted: true,
) = touying-slide-wrapper(self => {
  // Special-slide config is merged before resolving metadata or store values,
  // matching Touying's theme contract for per-slide overrides.
  let effective = utils.merge-dicts(
    self,
    config-common(freeze-slide-counter: not counted),
    config-page(
      margin: 0pt,
      header: none,
      footer: none,
      fill: white,
    ),
    config-common(detect-overflow: false),
    config,
  )
  let lines = normalize-lines(title-lines, effective.info.title)
  let authors = normalize-lines(author-lines, effective.info.author)
  let marks = normalize-media-list(affiliations)
  let event = event-mark
  let asset-resolver = effective.store.at("asset-resolver", default: path => path)
  let default-event-layout = (
    width: 156pt,
    height: 82pt,
    dx: 0pt,
    dy: 0pt,
  )
  let resolved-event-layout = if event-layout == auto {
    default-event-layout
  } else {
    assert(type(event-layout) == dictionary, message: "event-layout must be auto or a dictionary")
    utils.merge-dicts(default-event-layout, event-layout)
  }
  let default-affiliation-layout = (
    columns: auto,
    gutter: 28pt,
    height: 70pt,
    dx: 0pt,
    dy: 0pt,
    vertical: "center",
  )
  let resolved-affiliation-layout = if affiliation-layout == auto {
    default-affiliation-layout
  } else {
    assert(
      type(affiliation-layout) == dictionary,
      message: "affiliation-layout must be auto or a dictionary",
    )
    utils.merge-dicts(default-affiliation-layout, affiliation-layout)
  }
  assert(
    resolved-affiliation-layout.vertical in ("center", "bottom"),
    message: "affiliation-layout.vertical must be center or bottom",
  )
  let title-blocks = lines.map(line => utils.fit-to-width(
    width: 880pt,
    grow: false,
    text(
      font: font-sans,
      size: 40pt,
      weight: "bold",
      fill: white,
      line,
    ),
  ))
  if subtitle != none {
    title-blocks.push(text(font: font-sans, size: 24pt, fill: white, subtitle))
  }
  let author-blocks = authors.map(line => text(font: font-sans, size: 24pt, line))
  if extra != none {
    author-blocks.push(text(font: font-sans, size: 18pt, fill: ink, extra))
  }
  touying-slide(
    self: effective,
    composer: passthrough,
    grid(
      columns: 1,
      // The calibrated master uses a measured 317.42 pt color band. Keeping the
      // boundary explicit avoids cumulative ratio rounding at high DPI.
      rows: (317.42pt, 1fr),
      block(
        width: 100%,
        height: 100%,
        fill: deep-purple,
        inset: (x: 42pt, y: 22pt),
        grid(
          columns: 1,
          rows: (auto, 1fr),
          align(left, move(
            dx: resolved-event-layout.dx,
            dy: resolved-event-layout.dy,
            render-media(
              event,
              width: resolved-event-layout.width,
              height: resolved-event-layout.height,
              resolver: asset-resolver,
            ),
          )),
          align(center + horizon, move(
            dx: 10pt,
            // Compensates for the measured band and event-row height while
            // retaining the source title baselines.
            dy: 2.3545pt,
            stack(
              dir: ttb,
              spacing: 43.8pt,
              ..title-blocks,
            ),
          )),
        ),
      ),
      block(
        width: 100%,
        height: 100%,
        inset: (left: 28pt, right: 28pt, top: 24pt, bottom: 18pt),
        grid(
          columns: 1,
          rows: (auto, 1fr),
          align(center, move(
            dx: -1.9pt,
            // The lower band begins 6.58 pt earlier than the old 3:2 split.
            // This optical offset preserves the measured author baselines.
            dy: 7.54pt,
            stack(
              dir: ttb,
              spacing: 22pt,
              ..author-blocks,
            ),
          )),
          if marks.len() == 0 {
            []
          } else {
            let mark-columns = if resolved-affiliation-layout.columns == auto {
              (1fr,) * marks.len()
            } else {
              assert(
                type(resolved-affiliation-layout.columns) == array,
                message: "affiliation-layout.columns must be auto or an array",
              )
              assert(
                resolved-affiliation-layout.columns.len() == marks.len(),
                message: "affiliation-layout.columns must match affiliations length",
              )
              resolved-affiliation-layout.columns
            }
            let strip = grid(
              columns: mark-columns,
              gutter: resolved-affiliation-layout.gutter,
              ..marks.map(mark => align(
                center + horizon,
                render-media(
                  mark,
                  width: 100%,
                  height: resolved-affiliation-layout.height,
                  resolver: asset-resolver,
                ),
              )),
            )
            let positioned = move(
              dx: resolved-affiliation-layout.dx,
              dy: resolved-affiliation-layout.dy,
              strip,
            )
            if resolved-affiliation-layout.vertical == "bottom" {
              align(left + bottom, positioned)
            } else {
              align(left + horizon, positioned)
            }
          },
        ),
      ),
    ),
  )
})

/// 创建基于 Touying progressive outline 的目录页。
/// 本接口集中控制目录深度、标题和条目垂直节奏。
///
/// - config (dictionary): Touying 目录页配置，默认空字典，传给内部 slide。
/// - level (auto, int): 目录查询层级，默认 `1`；`auto` 使用当前 Touying slide level，显式值应对应已有 heading。
/// - title (none, content, function): 目录页标题，默认 `[Roadmap]`；`none` 隐藏 header。
/// - spacing (length): 一级条目垂直节奏，默认 `26pt`；深层派生为三分之一，透传的 vspace 优先且值不得为负。
/// - setting (function): 目录内容转换函数，默认恒等；在 outline 生成后应用且必须返回 content。
/// - args (arguments): 透传给 progressive outline 的参数；同名值覆盖本函数派生默认。
///
/// -> content
#let outline-slide(
  config: (:),
  level: 1,
  title: [Roadmap],
  spacing: 26pt,
  setting: body => body,
  ..args,
) = slide(title: title, config: config, self => {
  let named = args.named()
  let indent = named.remove("indent", default: (0pt,))
  if type(indent) != array { indent = (indent,) }
  let vspace = named.remove(
    "vspace",
    default: (spacing, spacing / 3, spacing / 3, spacing / 3),
  )
  let numbered = named.remove("numbered", default: (false,))
  let numbering = named.remove("numbering", default: ("1.",))
  setting(components.custom-progressive-outline(
    title: none,
    depth: if level == auto { self.slide-level } else { level },
    level: level,
    indent: indent,
    vspace: vspace,
    numbered: numbered,
    numbering: numbering,
    ..args.pos(),
    ..named,
  ))
})

/// 创建显示当前 heading 与可选说明的章节分隔页。
/// Theme 默认不自动插入该页面，以免改变既有 Deck 页数。
///
/// - config (dictionary): Touying 章节页配置，默认空字典；在章节页预设之后合并。
/// - level (int): 显示的 heading 层级，默认 `1`，应对应当前位置存在的标题。
/// - numbered (bool): 是否显示 heading 编号，默认 `false`；编号格式来自 heading 自身。
/// - counted (bool): 是否参与逻辑页计数，默认 `true`；`false` 冻结计数但保留物理页。
/// - body (none, content): 必填的可选说明内容；传 `none` 时只显示章节标题。
///
/// -> content
#let section-slide(
  config: (:),
  level: 1,
  numbered: false,
  counted: true,
  body,
) = touying-slide-wrapper(self => {
  let effective = utils.merge-dicts(
    self,
    config-common(freeze-slide-counter: not counted),
    config-page(header: none, margin: (x: 68pt, y: 44pt)),
    config,
  )
  let section-title = utils.display-current-heading(
    level: level,
    numbered: numbered,
  )
  touying-slide(
    self: effective,
    composer: passthrough,
    align(center + horizon, stack(
      dir: ttb,
      spacing: 22pt,
      text(
        font: font-sans,
        size: 44pt,
        weight: "bold",
        fill: purple,
        section-title,
      ),
      if body == none { [] } else {
        text(font: font-sans, size: 24pt, fill: ink, body)
      },
    )),
  )
})
