// Content-neutral page layers and inheritable page-frame profiles.
//
// These constructors only describe page surfaces and lifecycle policy. They do
// not render a slide, inspect narrative content, or implement Touying runtime
// behavior. `src/runtime.typ` consumes the returned dictionaries.

#let _page-layer-kind = "systems-slides-template/page-layer"
#let _page-frame-kind = "systems-slides-template/page-frame"

#let _frame-defaults = (
  background: auto,
  overlay: auto,
  foreground: auto,
  chrome: auto,
  section-progress: auto,
  header: auto,
  footer: auto,
  margin: auto,
  fill: auto,
  width: auto,
  height: auto,
  header-ascent: auto,
  footer-descent: auto,
  clip: auto,
  detect-overflow: auto,
)

#let _owner(kind, name) = if name == none {
  kind
} else {
  kind + " \"" + name + "\""
}

#let _is-layer-value(value) = {
  if value in (auto, none) {
    true
  } else if type(value) == dictionary {
    if value.at("kind", default: none) != _page-layer-kind {
      false
    } else {
      for key in ("body", "name", "area", "align", "inset") {
        if key not in value { return false }
      }
      true
    }
  } else {
    type(value) in (content, function, str)
  }
}

#let _is-inset(value) = value == auto or type(value) in (
  length,
  ratio,
  relative,
  dictionary,
)

#let _is-page-spacing(value) = value == auto or type(value) in (
  length,
  ratio,
  relative,
  dictionary,
)

#let _is-page-offset(value) = value == auto or type(value) in (
  length,
  ratio,
  relative,
)

#let _resolved(base, key, value) = if value == auto {
  base.at(key, default: auto)
} else {
  value
}

/// 构造与正文流解耦的页面视觉层。
/// 需要 Touying 状态、整页对齐或独立 inset 时使用；简单内容可直接传给 `page-frame`。
///
/// - body (content, str, function, none): 必填的层内容或延迟回调；`none` 生成空层，回调接收 Touying self 并须返回可显示内容。
/// - name (str, none): 可选诊断名称，默认 `none`；不改变渲染。
/// - area (str): 占据 `"page"` 或 `"body"`，默认整页；overlay 只能使用 page，body 仅适合局部 background/foreground。
/// - align (any, auto): 层内 Typst alignment，默认 `auto` 保持左上自然流向；在 inset 后的区域中生效。
/// - inset (length, ratio, relative, dictionary, auto): 相对所选 area 的内缩；
///   默认 `auto` 不增加 padding；字典键遵循 Typst pad。
///
/// -> dictionary
#let page-layer(
  body,
  name: none,
  area: "page",
  align: auto,
  inset: auto,
) = {
  let owner = _owner("page-layer", name)
  assert(
    name == none or type(name) == str,
    message: "page-layer.name must be a string or none",
  )
  assert(
    type(body) in (content, function, str) or body == none,
    message: owner + ": body must be content, a string, a function, or none",
  )
  assert(
    area in ("page", "body"),
    message: owner + ": area must be page or body; got " + repr(area),
  )
  assert(
    align == auto or type(align) == alignment,
    message: owner + ": align must be an alignment or auto; got " + repr(align),
  )
  assert(
    _is-inset(inset),
    message: owner + ": inset must be a length, ratio, relative value, dictionary, or auto; got " + repr(inset),
  )

  (
    kind: _page-layer-kind,
    body: body,
    name: name,
    area: area,
    align: align,
    inset: inset,
  )
}

/// 构造可继承、内容无关的页面框架，描述页面层、chrome、尺寸和溢出策略。
/// `auto` 继承 `base` 或当前 Theme；`none` 有意清除对应层或槽位。
///
/// - base (dictionary, none): 父 page-frame，默认 `none`；当前非 auto 字段覆盖父字段，父值必须由本构造器创建。
/// - name (str, none): 可选诊断名称，默认 `none`；不从 base 继承。
/// - background (dictionary, content, str, function, none, auto): fill 之上、正文之下的层；
///   `auto` 继承，`none` 清除，回调在 slide 状态中求值。
/// - overlay (dictionary, content, str, function, none, auto): 正文和 chrome 之上的整页蒙版；
///   `auto` 继承，`none` 清除，page-layer 必须使用 page area。
/// - foreground (dictionary, content, str, function, none, auto): 最上层内容；
///   `auto` 继承，`none` 清除，与 overlay 共存时后绘制。
/// - chrome (bool, auto): header/footer 总开关；`auto` 继承，`false` 关闭，显式 header/footer 仍具有更高优先级。
/// - section-progress (bool, auto): 当前页章节进度开关；`auto` 继承 base 和 Theme store，只影响 header 导航。
/// - header (content, function, none, auto): 页眉或状态回调；
///   `auto` 继承，`none` 隐藏，显式值高于 chrome 和 slide title。
/// - footer (content, function, none, auto): 页脚或状态回调；
///   `auto` 继承，`none` 隐藏，显式值高于 chrome 和 Theme footer。
/// - margin (length, ratio, relative, dictionary, auto): page margin；
///   `auto` 继承，字典必须遵循 Typst page.margin 约束。
/// - fill (color, gradient, tiling, none, auto): 页面底层 paint；`auto` 继承，`none` 透明；图形内容应放在 background。
/// - width (length, auto): 页面物理宽度；`auto` 继承，显式值必须为正且会影响 chrome/presenter view。
/// - height (length, auto): 页面物理高度；`auto` 继承，显式值必须为正且会影响 chrome/presenter view。
/// - header-ascent (length, ratio, relative, auto): 页眉伸入量；`auto` 继承，仅在 header 存在时可见。
/// - footer-descent (length, ratio, relative, auto): 页脚伸入量；`auto` 继承，仅在 footer 存在时可见。
/// - clip (bool, auto): 非 breakable 页的正文裁切；`auto` 继承 Touying，且不改变页面层裁切。
/// - detect-overflow (bool, auto): 非 breakable 页的正文溢出检查；`auto` 继承 Touying，启用会增加测量。
///
/// -> dictionary
#let page-frame(
  base: none,
  name: none,

  // Visual layer stack.
  background: auto,
  overlay: auto,
  foreground: auto,

  // Slide chrome and navigation.
  chrome: auto,
  section-progress: auto,
  header: auto,
  footer: auto,

  // Physical page box.
  margin: auto,
  fill: auto,
  width: auto,
  height: auto,
  header-ascent: auto,
  footer-descent: auto,

  // Touying overflow behavior.
  clip: auto,
  detect-overflow: auto,
) = {
  assert(
    name == none or type(name) == str,
    message: "page-frame.name must be a string or none",
  )
  if base != none {
    assert(type(base) == dictionary, message: "page-frame base must be a page-frame")
    assert(
      base.at("kind", default: none) == _page-frame-kind,
      message: "page-frame base must be a value created by page-frame",
    )
    for key in _frame-defaults.keys() {
      assert(key in base, message: "page-frame base is missing field " + key)
    }
  }

  let inherited = if base == none { _frame-defaults } else { base }
  let values = (
    background: _resolved(inherited, "background", background),
    overlay: _resolved(inherited, "overlay", overlay),
    foreground: _resolved(inherited, "foreground", foreground),
    chrome: _resolved(inherited, "chrome", chrome),
    section-progress: _resolved(inherited, "section-progress", section-progress),
    header: _resolved(inherited, "header", header),
    footer: _resolved(inherited, "footer", footer),
    margin: _resolved(inherited, "margin", margin),
    fill: _resolved(inherited, "fill", fill),
    width: _resolved(inherited, "width", width),
    height: _resolved(inherited, "height", height),
    header-ascent: _resolved(inherited, "header-ascent", header-ascent),
    footer-descent: _resolved(inherited, "footer-descent", footer-descent),
    clip: _resolved(inherited, "clip", clip),
    detect-overflow: _resolved(inherited, "detect-overflow", detect-overflow),
  )
  let owner = _owner("page-frame", name)

  for key in ("background", "overlay", "foreground") {
    assert(
      _is-layer-value(values.at(key)),
      message: owner + ": " + key + " must be a page-layer, content, string, function, none, or auto",
    )
  }
  if type(values.overlay) == dictionary and values.overlay.at("kind", default: none) == _page-layer-kind {
    assert(
      values.overlay.area == "page",
      message: owner + ": overlay must cover the full page; omit area or use area: \"page\"",
    )
  }
  assert(
    values.chrome == auto or type(values.chrome) == bool,
    message: owner + ": chrome must be a boolean or auto; got " + repr(values.chrome),
  )
  assert(
    values.section-progress == auto or type(values.section-progress) == bool,
    message: owner + ": section-progress must be a boolean or auto; got " + repr(values.section-progress),
  )
  for key in ("header", "footer") {
    let value = values.at(key)
    assert(
      value in (auto, none) or type(value) in (content, function),
      message: owner + ": " + key + " must be content, a function, none, or auto",
    )
  }
  assert(
    _is-page-spacing(values.margin),
    message: owner + ": margin must be a length, ratio, relative value, dictionary, or auto",
  )
  assert(
    values.fill in (auto, none) or type(values.fill) in (color, gradient, tiling),
    message: owner + ": fill must be a color, gradient, tiling, none, or auto",
  )
  for key in ("width", "height") {
    let value = values.at(key)
    assert(
      value == auto or type(value) == length,
      message: owner + ": " + key + " must be a length or auto; got " + repr(value),
    )
    if value != auto {
      assert(value > 0pt, message: owner + ": " + key + " must be greater than 0pt")
    }
  }
  for key in ("header-ascent", "footer-descent") {
    assert(
      _is-page-offset(values.at(key)),
      message: owner + ": " + key + " must be a length, ratio, relative value, or auto",
    )
  }
  for key in ("clip", "detect-overflow") {
    let value = values.at(key)
    assert(
      value == auto or type(value) == bool,
      message: owner + ": " + key + " must be a boolean or auto; got " + repr(value),
    )
  }

  (
    kind: _page-frame-kind,
    base: base,
    name: name,
    background: values.background,
    overlay: values.overlay,
    foreground: values.foreground,
    chrome: values.chrome,
    section-progress: values.section-progress,
    header: values.header,
    footer: values.footer,
    margin: values.margin,
    fill: values.fill,
    width: values.width,
    height: values.height,
    header-ascent: values.header-ascent,
    footer-descent: values.footer-descent,
    clip: values.clip,
    detect-overflow: values.detect-overflow,
  )
}
