// Content-agnostic, nestable layout primitives.
//
// This module deliberately knows nothing about slide narratives, typography,
// paper assets, conferences, Touying page roles, or Points.  It only describes
// regions, tracks, gutters, alignment, fitting, and overflow policy.

#let _align-content = align
#let _layout-region-kind = "systems-slides-template/layout-region"
#let _layout-profile-kind = "systems-slides-template/layout-profile"
#let _epsilon = 0.01pt
#let _split-gutter = 28pt

// Opt-in compile-time inspection remains inside this import-free engine. The
// Theme lifecycle and body-flow reuse these private helpers, while the stable
// public API stays unchanged.
#let _layout-debug-mode = {
  // Preview and release builds stay clean by default. Layout diagnostics are
  // enabled only by an explicit compile input such as `layout-debug=labels`.
  let value = sys.inputs.at("layout-debug", default: "off")
  assert(
    value in ("off", "boxes", "labels"),
    message: "layout-debug must be off, boxes, or labels; got " + repr(value),
  )
  value
}

#let _layout-debug-enabled() = _layout-debug-mode != "off"

#let _layout-debug-palette(kind) = if kind == "theme-body" {
  (line: rgb("#6941C6"), fill: rgb("#6941C6").transparentize(94%))
} else if kind == "body-flow" {
  (line: rgb("#2563EB"), fill: rgb("#2563EB").transparentize(94%))
} else if kind in ("row-split", "row-region") {
  (line: rgb("#D97706"), fill: rgb("#F59E0B").transparentize(93%))
} else {
  (line: rgb("#059669"), fill: rgb("#10B981").transparentize(93%))
}

#let _layout-debug-frame-args(kind) = if not _layout-debug-enabled() {
  (:)
} else {
  let colors = _layout-debug-palette(kind)
  (fill: colors.fill, stroke: 0.8pt + colors.line)
}

#let _layout-debug-overlay(kind, label) = if _layout-debug-mode != "labels" {
  none
} else {
  let colors = _layout-debug-palette(kind)
  place(
    top + left,
    dx: 2.5pt,
    dy: 2.5pt,
    box(
      inset: (x: 3pt, y: 1.5pt),
      fill: colors.line.transparentize(8%),
      radius: 1.5pt,
      text(
        font: "Poppins",
        size: 6pt,
        weight: "medium",
        fill: white,
        label,
      ),
    ),
  )
}

#let _layout-debug-container(body, kind, label) = if not _layout-debug-enabled() {
  body
} else {
  layout(size => {
    if size.width.pt() == calc.inf or size.height.pt() == calc.inf {
      body
    } else {
      block(
        width: size.width,
        height: size.height,
        above: 0pt,
        below: 0pt,
        .._layout-debug-frame-args(kind),
        [#body#_layout-debug-overlay(kind, label)],
      )
    }
  })
}

#let _default-values = (
  rows: none,
  columns: none,
  // A split is an intentional structural boundary. Keep its standard gutter
  // inside the layout engine instead of making every deck invent an alias.
  gutter: _split-gutter,
  align: top + left,
  width: 100%,
  height: none,
  inset: 0pt,
  fit: "flow",
  overflow: "visible",
)

#let _region-defaults = (
  width: none,
  height: none,
  inset: 0pt,
)

#let _inherit(value, fallback) = if value == auto { fallback } else { value }

#let _profile-label(profile) = {
  let name = profile.at("name", default: none)
  if name == none { "layout-profile" } else { "layout-profile \"" + name + "\"" }
}

#let _validate-fit(value, owner: "region") = {
  assert(
    value in ("flow", "contain", "cover", "stretch"),
    message: owner + ": fit must be flow, contain, cover, or stretch; got " + repr(value),
  )
}

#let _validate-overflow(value, owner: "region") = {
  assert(
    value in ("visible", "clip", "error"),
    message: owner + ": overflow must be visible, clip, or error; got " + repr(value),
  )
}

#let _merge-profile(profile) = {
  if profile == none { return _default-values }
  assert(type(profile) == dictionary, message: "layout profile must be a dictionary")
  assert(
    profile.at("kind", default: none) == _layout-profile-kind,
    message: "expected a value created by layout-profile",
  )

  let base = profile.at("base", default: none)
  let merged = if base == none { _default-values } else { _merge-profile(base) }
  for key in _default-values.keys() {
    let value = profile.at(key, default: auto)
    if value != auto { merged.insert(key, value) }
  }
  merged
}

// A reusable spatial policy. `auto` inherits from `base`; `none` is an
// intentional value for rows/columns/height and means natural/derived sizing.

/// 构造可继承且与内容语义无关的行列布局策略。
/// profile 只保存空间规则，不直接渲染内容。
///
/// - base (dictionary, none): 父布局策略；默认 `none`。允许 `layout-profile` 构造值；`none` 从内置默认开始；
///   当前非 `auto` 字段覆盖父值；必须具有合法 kind。
/// - name (str, none): 诊断名称，默认 `none` 使用通用名称。
///   名称不从 base 继承，只出现在错误信息中。
/// - rows (array, none, auto): 行轨道；默认 `auto`。允许由 length、ratio、relative、fraction 或 `auto` 组成的数组；
///   `auto` 继承、`none` 表示自然派生；显式值覆盖 base；不可与解析后的 columns 同时定义。
/// - columns (array, none, auto): 列轨道；默认 `auto`。允许由 length、ratio、relative、fraction 或 `auto` 组成的数组；
///   `auto` 继承；`none` 交由消费该 profile 的横向布局派生。 `column-split` 会派生等宽 `1fr` 列。 显式值覆盖 base；
///   不可与解析后的 rows 同时定义。
/// - gutter (length, ratio, relative, fraction, array, auto): sibling 间距；
///   默认 `auto`；无父 profile 时解析为 `28pt`。
///   `fraction` 分配有限主轴余量；允许单值或 N-1 项数组；`auto` 继承；
///   split 显式值最终优先；值不得为负且数组长度必须匹配区域边界数。
/// - align (any, array, auto): 区域内容对齐；默认 `auto`。允许单一 Typst alignment 或逐区域 alignment 数组；`auto` 继承；
///   split 和 region 显式值依次覆盖；数组长度必须等于区域数。
/// - width (length, ratio, relative, none, auto): 容器宽度；默认 `auto`。允许固定/相对宽度；`auto` 继承、`none` 使用自然宽度；
///   split 显式值优先；百分比或分数列需要有限宽度。
/// - height (length, ratio, relative, none, auto): 容器高度，默认 `auto`。
///   允许固定/相对高度；`auto` 继承，`none` 使用自然高度；
///   split 显式值优先；百分比或分数行需要有限高度。
/// - inset (length, relative, dictionary, auto): 容器内边距；默认 `auto`。允许 Typst block inset 值；`auto` 继承；
///   split 或 region 显式值优先；它与 sibling gutter 是独立概念。
/// - fit (str, array, auto): 内容适配；默认 `auto`。允许 `"flow"`、`"contain"`、`"cover"`、`"stretch"` 或逐区域数组；
///   `auto` 继承；split/region 显式值优先；非 flow 需要有限宽高。
/// - overflow (str, array, auto): 溢出策略，默认 `auto` 继承。
///   允许 `"visible"`、`"clip"`、`"error"` 或逐区域数组；
///   split/region 显式值优先；clip/error 需要有限尺寸。
/// -> dictionary
#let layout-profile(
  base: none,
  name: none,

  // Axis tracks and sibling spacing.
  rows: auto,
  columns: auto,
  gutter: auto,
  align: auto,

  // Container geometry and content policy.
  width: auto,
  height: auto,
  inset: auto,
  fit: auto,
  overflow: auto,
) = {
  if base != none {
    assert(type(base) == dictionary, message: "layout-profile base must be a layout-profile")
    assert(
      base.at("kind", default: none) == _layout-profile-kind,
      message: "layout-profile base must be a value created by layout-profile",
    )
  }
  let owner = if name == none { "layout-profile" } else { "layout-profile \"" + name + "\"" }
  let inherited = if base == none { _default-values } else { _merge-profile(base) }
  let resolved-rows = _inherit(rows, inherited.rows)
  let resolved-columns = _inherit(columns, inherited.columns)
  assert(
    not (resolved-rows != none and resolved-columns != none),
    message: owner + ": rows and columns cannot both be defined",
  )
  if fit != auto {
    if type(fit) == array {
      for value in fit { _validate-fit(value, owner: owner) }
    } else {
      _validate-fit(fit, owner: owner)
    }
  }
  if overflow != auto {
    if type(overflow) == array {
      for value in overflow { _validate-overflow(value, owner: owner) }
    } else {
      _validate-overflow(overflow, owner: owner)
    }
  }

  (
    kind: _layout-profile-kind,
    base: base,
    name: name,
    rows: rows,
    columns: columns,
    gutter: gutter,
    align: align,
    width: width,
    height: height,
    inset: inset,
    fit: fit,
    overflow: overflow,
  )
}

#let default-layout-profile = layout-profile(
  name: "default",
  rows: none,
  columns: none,
  gutter: _split-gutter,
  align: top + left,
  width: 100%,
  height: none,
  inset: 0pt,
  fit: "flow",
  overflow: "visible",
)

// A leaf descriptor consumed by row-split/column-split. Its body may be any
// Typst content, including a nested split. Plain content passed to a split is
// normalized to this descriptor automatically.

/// 构造行列 split 的内容无关叶区域。
/// 区域可承载文本、列表、表格、公式、媒体或嵌套 split。
///
/// - body (content): 必填的任意 Typst 内容；自身样式不会被布局改写。
///   每个 region 对应父 split 的一个轨道。
/// - profile (dictionary, none): 区域专属策略；默认 `none`。允许 `layout-profile`；`none` 使用父 split 和区域默认；
///   区域显式参数继续覆盖；必须具有合法 kind。
/// - name (str, none): 诊断名称，默认 `none` 使用父级生成的序号名。
///   名称不继承，只影响错误信息。
/// - width (length, ratio, relative, none, auto): 区域内容宽度；默认 `auto`。允许固定/相对宽度；
///   `auto` 从 profile 解析，`none` 使用自然宽度；严格适配可能需要有限宽度。
/// - height (length, ratio, relative, none, auto): 区域内容高度；默认 `auto`。允许固定/相对高度；
///   `auto` 从 profile 解析，`none` 使用自然高度；严格适配可能需要有限高度。
/// - inset (length, relative, dictionary, auto): 区域内边距；默认 `auto`。允许长度或按边字典；`auto` 从 profile 解析；
///   区域值覆盖 profile；它不等同于父 split gutter。
/// - align (any, auto): 轨道内对齐，默认 `auto` 继承父 split。
///   接受 Typst alignment，且不改变内容适配策略。
/// - fit (str, auto): 内容适配，默认 `auto` 继承父 split。
///   允许 `"flow"`、`"contain"`、`"cover"`、`"stretch"`；
///   区域值覆盖父策略；非 flow 需要有限宽高。
/// - overflow (str, auto): 溢出策略；默认 `auto`。允许 `"visible"`、`"clip"`、`"error"`；`auto` 继承父 split；
///   区域值覆盖父策略；clip/error 需要有限轨道和交叉轴尺寸。
/// -> dictionary
#let region(
  body,
  profile: none,
  name: none,

  // Region geometry.
  width: auto,
  height: auto,
  inset: auto,
  align: auto,

  // Content sizing and overflow.
  fit: auto,
  overflow: auto,
) = {
  if profile != none {
    assert(type(profile) == dictionary, message: "region profile must be a layout-profile")
    assert(
      profile.at("kind", default: none) == _layout-profile-kind,
      message: "region profile must be a value created by layout-profile",
    )
  }
  if fit != auto { _validate-fit(fit, owner: "region") }
  if overflow != auto { _validate-overflow(overflow, owner: "region") }
  (
    kind: _layout-region-kind,
    body: body,
    profile: profile,
    name: name,
    width: width,
    height: height,
    inset: inset,
    align: align,
    fit: fit,
    overflow: overflow,
  )
}

#let _normalize-region(value) = if type(value) == dictionary and value.at("kind", default: none) == _layout-region-kind {
  value
} else {
  region(value)
}

#let _owner-name(kind, name) = if name == none { kind } else { kind + " \"" + name + "\"" }

#let _resolve-sequence(value, count, label, owner) = {
  if type(value) == array {
    assert(
      value.len() == count,
      message: owner + ": " + label + " array must match the number of regions; expected "
        + str(count) + ", got " + str(value.len()),
    )
    value
  } else {
    (value,) * count
  }
}

#let _resolve-gutters(value, count, owner) = {
  let expected = calc.max(0, count - 1)
  if type(value) == array {
    assert(
      value.len() == expected,
      message: owner + ": gutter must be one value or " + str(expected)
        + " values for " + str(count) + " regions; got " + str(value.len()),
    )
    value
  } else {
    (value,) * expected
  }
}

#let _validate-track(value, label, owner) = {
  let kind = type(value)
  assert(
    value == auto or kind in (length, ratio, relative, fraction),
    message: owner + ": " + label + " contains unsupported track " + repr(value),
  )
  if kind == length {
    assert(value >= 0pt, message: owner + ": " + label + " tracks cannot be negative")
  } else if kind == ratio {
    assert(value >= 0%, message: owner + ": " + label + " tracks cannot be negative")
  } else if kind == relative {
    assert(
      value.length >= 0pt and value.ratio >= 0%,
      message: owner + ": " + label + " tracks cannot be negative",
    )
  } else if kind == fraction {
    assert(value > 0fr, message: owner + ": fractional " + label + " tracks must be positive")
  }
  value
}

#let _resolve-tracks(value, count, label, owner, derived) = {
  if value == none {
    return (derived,) * count
  }
  assert(
    type(value) == array,
    message: owner + ": " + label + " must be none or an array with one track per region",
  )
  assert(
    value.len() == count,
    message: owner + ": " + label + " defines " + str(value.len()) + " tracks but received "
      + str(count) + " regions",
  )
  value.map(track => _validate-track(track, label, owner))
}

#let _fixed-size(track, extent) = {
  let kind = type(track)
  if kind == length {
    track
  } else if kind == ratio {
    track * extent
  } else if kind == relative {
    track.length + track.ratio * extent
  } else {
    0pt
  }
}

#let _fixed-budget(tracks, gutters, extent) = (
  tracks.fold(0pt, (sum, track) => sum + _fixed-size(track, extent))
  + gutters.fold(0pt, (sum, gutter) => sum + _fixed-size(gutter, extent))
)

#let _has-flex-or-ratio(values) = values.any(value => type(value) in (ratio, relative, fraction))

#let _region-label(value, fallback) = {
  let name = value.at("name", default: none)
  if name == none { fallback } else { "region \"" + name + "\"" }
}

#let _resolve-region(value, parent, parent-align, parent-fit, parent-overflow, index, owner) = {
  let own-profile = _merge-profile(value.at("profile", default: none))
  let has-profile = value.at("profile", default: none) != none
  // Container width/height/inset belong only to the split itself. A leaf uses
  // the built-in region defaults unless it selects its own profile explicitly.
  let from-profile(key) = if has-profile { own-profile.at(key) } else { _region-defaults.at(key) }
  let align-value = _inherit(value.at("align", default: auto), parent-align)
  let fit-value = _inherit(value.at("fit", default: auto), parent-fit)
  let overflow-value = _inherit(value.at("overflow", default: auto), parent-overflow)
  let width-value = _inherit(value.at("width", default: auto), from-profile("width"))
  let height-value = _inherit(value.at("height", default: auto), from-profile("height"))
  let inset-value = _inherit(value.at("inset", default: auto), from-profile("inset"))
  if value.at("align", default: auto) == auto and has-profile { align-value = own-profile.align }
  if value.at("fit", default: auto) == auto and has-profile { fit-value = own-profile.fit }
  if value.at("overflow", default: auto) == auto and has-profile { overflow-value = own-profile.overflow }
  _validate-fit(fit-value, owner: _region-label(value, owner + " region " + str(index + 1)))
  _validate-overflow(overflow-value, owner: _region-label(value, owner + " region " + str(index + 1)))
  (
    body: value.body,
    name: value.at("name", default: none),
    width: width-value,
    height: height-value,
    inset: inset-value,
    align: align-value,
    fit: fit-value,
    overflow: overflow-value,
  )
}

#let _fit-body(body, fit, overflow, align, label) = {
  if fit == "flow" and overflow == "visible" { return body }
  layout(size => {
    let needed = measure(width: size.width, body)
    let finite-width = size.width.pt() != calc.inf
    let finite-height = size.height.pt() != calc.inf

    if fit in ("contain", "cover", "stretch") {
      assert(
        finite-width and finite-height,
        message: label + ": fit " + repr(fit) + " requires finite width and height",
      )
    }

    if fit == "flow" {
      if overflow == "error" {
        assert(
          (not finite-width or needed.width <= size.width + _epsilon)
            and (not finite-height or needed.height <= size.height + _epsilon),
          message: label + ": content needs " + repr(needed.width) + " x " + repr(needed.height)
            + ", but the region provides " + repr(size.width) + " x " + repr(size.height)
            + "; use fit: \"contain\", overflow: \"clip\", or increase the track",
        )
      }
      block(
        width: 100%,
        height: 100%,
        breakable: false,
        clip: overflow == "clip",
        _align-content(align, body),
      )
    } else {
      let sx = if needed.width == 0pt { 1.0 } else { size.width / needed.width }
      let sy = if needed.height == 0pt { 1.0 } else { size.height / needed.height }
      let transformed = if fit == "contain" {
        let factor = calc.min(1.0, sx, sy)
        scale(x: factor * 100%, y: factor * 100%, reflow: true, body)
      } else if fit == "cover" {
        let factor = calc.max(sx, sy)
        scale(x: factor * 100%, y: factor * 100%, reflow: true, body)
      } else {
        scale(x: sx * 100%, y: sy * 100%, reflow: true, body)
      }
      block(
        width: 100%,
        height: 100%,
        breakable: false,
        clip: fit == "cover" or overflow == "clip",
        _align-content(align, transformed),
      )
    }
  })
}

#let _render-region(value, track, owner, direction, cross-size, index) = {
  let strict = value.fit != "flow" or value.overflow != "visible"
  let label = if value.name == none { owner + " region" } else { "region \"" + value.name + "\"" }
  if strict and track == auto {
    assert(
      false,
      message: label + ": fit/overflow policies require a finite, non-auto "
        + (if direction == "row" { "row" } else { "column" }) + " track",
    )
  }
  if strict and cross-size == none {
    assert(
      (direction == "row" and value.width != none)
        or (direction == "column" and value.height != none),
      message: label + ": fit/overflow policies require a finite width and height",
    )
  }
  let rendered = if strict {
    _fit-body(value.body, value.fit, value.overflow, value.align, label)
  } else {
    value.body
  }
  let framed = block(
    width: if value.width == none { auto } else { value.width },
    height: if value.height == none { auto } else { value.height },
    above: 0pt,
    below: 0pt,
    breakable: value.height == none,
    rendered,
  )
  grid.cell(
    align: value.align,
    inset: value.inset,
    .._layout-debug-frame-args(direction + "-region"),
    [#framed#_layout-debug-overlay(
      direction + "-region",
      if value.name == none { owner + " · region " + str(index + 1) } else { value.name },
    )],
  )
}

#let _split(
  direction,
  regions,
  profile,
  name,
  tracks-arg,
  gutter-arg,
  align-arg,
  width-arg,
  height-arg,
  inset-arg,
  fit-arg,
  overflow-arg,
) = {
  let kind = if direction == "row" { "row-split" } else { "column-split" }
  let owner = _owner-name(kind, name)
  assert(type(regions) == array, message: owner + ": regions must be an array")
  assert(regions.len() > 0, message: owner + ": requires at least one region")

  let resolved-profile = _merge-profile(profile)
  if direction == "row" {
    assert(
      resolved-profile.columns == none,
      message: owner + " cannot consume " + _profile-label(profile) + " because it defines columns",
    )
  } else {
    assert(
      resolved-profile.rows == none,
      message: owner + " cannot consume " + _profile-label(profile) + " because it defines rows",
    )
  }

  let profile-tracks = if direction == "row" { resolved-profile.rows } else { resolved-profile.columns }
  let tracks-value = _inherit(tracks-arg, profile-tracks)
  let gutter-value = _inherit(gutter-arg, resolved-profile.gutter)
  let align-value = _inherit(align-arg, resolved-profile.align)
  let width-value = _inherit(width-arg, resolved-profile.width)
  let height-value = _inherit(height-arg, resolved-profile.height)
  let inset-value = _inherit(inset-arg, resolved-profile.inset)
  let fit-value = _inherit(fit-arg, resolved-profile.fit)
  let overflow-value = _inherit(overflow-arg, resolved-profile.overflow)

  let count = regions.len()
  let derived = if direction == "row" { auto } else { 1fr }
  let tracks = _resolve-tracks(tracks-value, count, if direction == "row" { "rows" } else { "columns" }, owner, derived)
  let gutters = _resolve-gutters(gutter-value, count, owner)
  for gutter in gutters { let _ = _validate-track(gutter, "gutter", owner) }

  if direction == "row" and height-value == none and _has-flex-or-ratio(tracks + gutters) {
    assert(false, message: owner + ": fractional or percentage rows/gutters require a finite height")
  }
  if direction == "column" and width-value == none and _has-flex-or-ratio(tracks + gutters) {
    assert(false, message: owner + ": fractional or percentage columns/gutters require a finite width")
  }

  let aligns = _resolve-sequence(align-value, count, "align", owner)
  let fits = _resolve-sequence(fit-value, count, "fit", owner)
  let overflows = _resolve-sequence(overflow-value, count, "overflow", owner)
  for value in fits { _validate-fit(value, owner: owner) }
  for value in overflows { _validate-overflow(value, owner: owner) }
  let normalized = regions.map(_normalize-region)
  let cells = ()
  for (index, value) in normalized.enumerate() {
    let resolved = _resolve-region(
      value,
      resolved-profile,
      aligns.at(index),
      fits.at(index),
      overflows.at(index),
      index,
      owner,
    )
    cells.push(_render-region(
      resolved,
      tracks.at(index),
      owner,
      direction,
      if direction == "row" { width-value } else { height-value },
      index,
    ))
  }

  let render-grid() = if direction == "row" {
    grid(
      columns: (1fr,),
      rows: tracks,
      row-gutter: gutters,
      column-gutter: 0pt,
      ..cells,
    )
  } else {
    grid(
      columns: tracks,
      rows: if height-value == none { (auto,) } else { (1fr,) },
      column-gutter: gutters,
      row-gutter: 0pt,
      ..cells,
    )
  }

  let needs-budget-check = (
    (direction == "row" and height-value != none)
    or (direction == "column" and width-value != none)
  )
  let budget-probe = if needs-budget-check {
    hide(layout(size => {
      let extent = if direction == "row" { size.height } else { size.width }
      if extent.pt() != calc.inf {
        let fixed = _fixed-budget(tracks, gutters, extent)
        assert(
          fixed <= extent + _epsilon,
          message: owner + ": fixed/percentage tracks and gutters require " + repr(fixed)
            + ", but only " + repr(extent) + " is available; reduce tracks/gutter or use fr/auto",
        )
      }
      []
    }))
  } else {
    []
  }
  let constrained = block(
    width: if width-value == none { auto } else { width-value },
    height: if height-value == none { auto } else { height-value },
    inset: inset-value,
    above: 0pt,
    below: 0pt,
    .._layout-debug-frame-args(kind),
    [#budget-probe#render-grid()#_layout-debug-overlay(kind, owner)],
  )
  constrained
}

// Split top-to-bottom. `rows` accepts one track per region; `gutter` accepts a
// scalar or exactly N-1 values. Nested column-split/row-split values are just
// ordinary region bodies.

/// 将任意数量的区域从上到下排列，并允许在区域中继续嵌套行列布局。
///
/// - regions (array): 从上到下的内容区域；必填。允许普通 content 或 `region`；普通内容自动包装；region 字段覆盖父策略；数组必须非空且轨道数匹配。
/// - profile (dictionary): 纵向布局策略，默认 `default-layout-profile`。
///   必须由 `layout-profile` 构造，且不得定义 columns；
///   后续显式参数覆盖 profile；该 profile 不得定义 columns。
/// - name (str, none): split 诊断名称，默认 `none` 使用通用名称。
///   名称不从 profile 继承，只影响错误信息。
/// - rows (array, none, auto): 每个区域的行轨道；默认 `auto`。允许 length、ratio、relative、fraction、`auto`；
///   `auto` 继承，`none` 派生自然轨道；项数必须等于 regions 数量。
/// - gutter (length, ratio, relative, fraction, array, auto): 相邻行间距；默认 `auto`；内建 profile 使用 `28pt`。
///   `fraction` 分配有限高度余量；允许单值或 N-1 项数组。
///   `auto` 继承 profile；值不得为负，数组长度必须匹配。
/// - align (any, array, auto): 行轨道内对齐，默认 `auto`。
///   允许单一 Typst alignment 或逐区域 alignment 数组；
///   `auto` 继承 profile；region.align 最终优先；数组长度必须等于区域数。
/// - width (length, ratio, relative, none, auto): split 宽度，默认 `auto` 继承。
///   接受固定/相对值；`none` 使用自然宽度；
///   调用值覆盖 profile；严格适配需要有限交叉轴宽度。
/// - height (length, ratio, relative, none, auto): split 高度；默认 `auto`。允许固定/相对值；
///   `auto` 继承，`none` 使用自然高度；fraction 或 percentage 行需要有限高度。
/// - inset (length, relative, dictionary, auto): split 内边距；默认 `auto`。允许长度或按边字典；`auto` 继承 profile；
///   调用值覆盖 profile，但不替代 region inset。
/// - fit (str, array, auto): 区域默认适配；默认 `auto`。允许 flow/contain/cover/stretch 或逐区域数组；`auto` 继承；
///   region.fit 最终优先；数组须匹配且非 flow 需要有限尺寸。
/// - overflow (str, array, auto): 区域默认溢出；默认 `auto`。允许 visible/clip/error 或逐区域数组；`auto` 继承；
///   region.overflow 最终优先；数组须匹配且严格策略需要有限尺寸。
/// -> content
#let row-split(
  regions,
  profile: default-layout-profile,
  name: none,

  // Vertical tracks and sibling placement.
  rows: auto,
  gutter: auto,
  align: auto,

  // Container geometry and region policy.
  width: auto,
  height: auto,
  inset: auto,
  fit: auto,
  overflow: auto,
) = _split(
  "row",
  regions,
  profile,
  name,
  rows,
  gutter,
  align,
  width,
  height,
  inset,
  fit,
  overflow,
)

// Split left-to-right. Derived columns are equal `1fr` tracks; explicit
// `columns` may combine fixed lengths, percentages, relative lengths, and fr.

/// 将任意数量的区域从左到右排列，并允许在区域中继续嵌套行列布局。
///
/// - regions (array): 从左到右的内容区域；必填。允许普通 content 或 `region`；普通内容自动包装；region 字段覆盖父策略；数组必须非空且轨道数匹配。
/// - profile (dictionary): 横向布局策略，默认 `default-layout-profile`。
///   必须由 `layout-profile` 构造，且不得定义 rows；
///   后续显式参数覆盖 profile；该 profile 不得定义 rows。
/// - name (str, none): split 诊断名称，默认 `none` 使用通用名称。
///   名称不从 profile 继承，只影响错误信息。
/// - columns (array, none, auto): 每个区域的列轨道；默认 `auto`。允许 length、ratio、relative、fraction、`auto`；
///   `auto` 继承，`none` 派生等宽 `1fr`；项数必须等于 regions 数量。
/// - gutter (length, ratio, relative, fraction, array, auto): 相邻列间距；默认 `auto`；内建 profile 使用 `28pt`。
///   `fraction` 分配有限宽度余量；允许单值或 N-1 项数组。
///   `auto` 继承 profile；值不得为负，数组长度必须匹配。
/// - align (any, array, auto): 列轨道内对齐，默认 `auto`。
///   允许单一 Typst alignment 或逐区域 alignment 数组；
///   `auto` 继承 profile；region.align 最终优先；数组长度必须等于区域数。
/// - width (length, ratio, relative, none, auto): split 宽度，默认 `auto` 继承。
///   接受固定/相对值；`none` 使用自然宽度；
///   调用值覆盖 profile；fraction 或 percentage 列需要有限宽度。
/// - height (length, ratio, relative, none, auto): split 高度；默认 `auto`。允许固定/相对值；
///   `auto` 继承，`none` 使用自然高度；严格适配需要有限交叉轴高度。
/// - inset (length, relative, dictionary, auto): split 内边距；默认 `auto`。允许长度或按边字典；`auto` 继承 profile；
///   调用值覆盖 profile，但不替代 region inset。
/// - fit (str, array, auto): 区域默认适配；默认 `auto`。允许 flow/contain/cover/stretch 或逐区域数组；`auto` 继承；
///   region.fit 最终优先；数组须匹配且非 flow 需要有限尺寸。
/// - overflow (str, array, auto): 区域默认溢出；默认 `auto`。允许 visible/clip/error 或逐区域数组；`auto` 继承；
///   region.overflow 最终优先；数组须匹配且严格策略需要有限尺寸。
/// -> content
#let column-split(
  regions,
  profile: default-layout-profile,
  name: none,

  // Horizontal tracks and sibling placement.
  columns: auto,
  gutter: auto,
  align: auto,

  // Container geometry and region policy.
  width: auto,
  height: auto,
  inset: auto,
  fit: auto,
  overflow: auto,
) = _split(
  "column",
  regions,
  profile,
  name,
  columns,
  gutter,
  align,
  width,
  height,
  inset,
  fit,
  overflow,
)
