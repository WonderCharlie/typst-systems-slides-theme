// Finite, content-neutral body flow.
//
// Ordinary Typst content should remain in normal document flow. `body-flow`
// is only needed when one or more later rows must consume the finite remainder
// of the current body box. It owns that complete box, measures `auto` rows, and
// delegates the actual track rendering to the independent layout engine.

#import "layouts.typ": (
  _layout-debug-frame-args,
  _layout-debug-overlay,
  default-layout-profile,
  layout-profile,
  row-split,
)

#let _layout-profile-kind = "systems-slides-template/layout-profile"
#let _epsilon = 0.01pt
#let _content-gutter = 20pt

#let _flow-defaults = (
  rows: none,
  // Natural text followed by a remaining-space region uses the ordinary
  // content rhythm. Tighter pages may still override this locally.
  gutter: _content-gutter,
  align: top + left,
  inset: 0pt,
  overflow: "visible",
)

#let _default-body-flow-profile = layout-profile(gutter: _content-gutter)

#let _inherit(value, fallback) = if value == auto { fallback } else { value }

#let _merge-flow-profile(profile) = {
  assert(type(profile) == dictionary, message: "body-flow: profile must be a layout-profile")
  assert(
    profile.at("kind", default: none) == _layout-profile-kind,
    message: "body-flow: profile must be a value created by layout-profile",
  )
  let base = profile.at("base", default: none)
  let merged = if base == none { _flow-defaults } else { _merge-flow-profile(base) }
  let columns = profile.at("columns", default: auto)
  assert(
    columns in (auto, none),
    message: "body-flow: cannot consume a layout-profile that defines columns",
  )
  for key in _flow-defaults.keys() {
    let value = profile.at(key, default: auto)
    if value != auto { merged.insert(key, value) }
  }
  merged
}

#let _owner(profile) = {
  let name = profile.at("name", default: none)
  if name == none { "body-flow" } else { "body-flow \"" + name + "\"" }
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

#let _resolve-rows(value, count, owner) = {
  if value == none { return (auto,) * count }
  assert(type(value) == array, message: owner + ": rows must be none or an array")
  assert(
    value.len() == count,
    message: owner + ": rows defines " + str(value.len()) + " tracks but received "
      + str(count) + " regions",
  )
  value.map(track => _validate-track(track, "rows", owner))
}

#let _resolve-gutters(value, count, owner) = {
  let expected = calc.max(0, count - 1)
  let gutters = if type(value) == array {
    assert(
      value.len() == expected,
      message: owner + ": gutter must be one value or " + str(expected)
        + " values for " + str(count) + " regions; got " + str(value.len()),
    )
    value
  } else {
    (value,) * expected
  }
  gutters.map(gutter => _validate-track(gutter, "gutter", owner))
}

#let _resolve-outer-gutters(value, owner) = {
  let gutters = if type(value) == array {
    assert(
      value.len() == 2,
      message: owner + ": outer-gutter must be one value or a two-item (top, bottom) array; got "
        + str(value.len()),
    )
    value
  } else {
    (value, value)
  }
  gutters.map(gutter => _validate-track(gutter, "outer-gutter", owner))
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

#let _fraction-weight(track) = if type(track) == fraction { track / 1fr } else { 0.0 }

#let _auto-height(value, width) = measure(
  width: width,
  row-split(
    (value,),
    profile: default-layout-profile,
    rows: (auto,),
    gutter: 0pt,
    width: width,
    height: none,
    inset: 0pt,
    fit: "flow",
    overflow: "visible",
  ),
).height

/// 在有限正文框中先测量自然高度区域，再把剩余高度分给弹性纵向轨道或间距。
/// 普通内容应留在自然流中；只有需要共享剩余空间时才使用本组件。
///
/// - regions (array): 必填的非空纵向区域数组；普通 content 自动视为匿名 region，数量须与最终 rows 一致。
/// - profile (dictionary, none): 可复用纵向 layout-profile，默认 `none` 使用 20pt gutter；
///   不得定义 columns，父框须有有限宽高。
/// - rows (array, none, auto): 轨道数组；默认 `auto` 继承 profile，`none` 全部推导为自然高度。 显式数组优先，且项数必须匹配 regions。
/// - gutter (length, ratio, relative, fraction, array, auto): 相邻区域间距；
///   默认 `auto` 继承 profile，`fraction` 在有限余高中分配自由空间。 数组必须恰有 N-1 项，并计入高度预算。
/// - outer-gutter (length, ratio, relative, fraction, array): 正文首尾的外侧空间，默认 `0pt`。
///   标量同时作用于上下边缘；二元数组依次表示顶部和底部。
///   fraction 与 rows、gutter 按权重共享剩余高度。
/// - align (any, array, auto): 单一或逐区域 Typst alignment；默认 `auto` 继承 profile，region 局部 align 最终优先。
/// - inset (length, relative, dictionary, auto): 整个 flow 的内边距；
///   默认 `auto` 继承 profile，会减少轨道可用空间但不替代 region inset。
/// - overflow (str, array, auto): 默认或逐区域的 visible/clip/error；
///   `auto` 继承 profile，region 局部值优先，数组长度须匹配。
///
/// -> content
#let body-flow(
  regions,
  profile: none,
  rows: auto,
  gutter: auto,
  outer-gutter: 0pt,
  align: auto,
  inset: auto,
  overflow: auto,
) = {
  assert(type(regions) == array, message: "body-flow: regions must be an array")
  assert(regions.len() > 0, message: "body-flow: requires at least one region")
  let effective-profile = if profile == none { _default-body-flow-profile } else { profile }
  let inherited = _merge-flow-profile(effective-profile)
  let owner = _owner(effective-profile)
  let resolved-rows = _resolve-rows(_inherit(rows, inherited.rows), regions.len(), owner)
  let resolved-gutters = _resolve-gutters(_inherit(gutter, inherited.gutter), regions.len(), owner)
  let resolved-outer-gutters = _resolve-outer-gutters(outer-gutter, owner)
  let resolved-align = _inherit(align, inherited.align)
  let resolved-inset = _inherit(inset, inherited.inset)
  let resolved-overflow = _inherit(overflow, inherited.overflow)

  layout(size => {
    assert(
      size.width.pt() != calc.inf,
      message: owner + ": requires a finite parent width",
    )

    // Touying's non-breakable page container first measures slide content with
    // a finite width but infinite height, then lays it out again in the real
    // finite body box. During that probe, report only the natural/fixed height
    // that participates in overflow measurement. Flexible regions are rendered
    // exclusively during the second, finite pass where their remainder exists.
    if size.height.pt() == calc.inf {
      let probe-fixed = (
        resolved-rows.fold(0pt, (sum, track) => sum + _fixed-size(track, 0pt))
          + resolved-gutters.fold(0pt, (sum, track) => sum + _fixed-size(track, 0pt))
          + resolved-outer-gutters.fold(0pt, (sum, track) => sum + _fixed-size(track, 0pt))
      )
      let probe-auto = resolved-rows.enumerate().fold(0pt, (sum, entry) => {
        let (index, track) = entry
        if track == auto { sum + _auto-height(regions.at(index), size.width) } else { sum }
      })
      return block(
        width: size.width,
        height: calc.max(0.01pt, probe-fixed + probe-auto),
        above: 0pt,
        below: 0pt,
      )
    }

    return block(
      width: size.width,
      height: size.height,
      inset: resolved-inset,
      above: 0pt,
      below: 0pt,
      .._layout-debug-frame-args("body-flow"),
      [#layout(inner-size => {
        let fixed = (
          resolved-rows.fold(0pt, (sum, track) => sum + _fixed-size(track, inner-size.height))
            + resolved-gutters.fold(0pt, (sum, track) => sum + _fixed-size(track, inner-size.height))
            + resolved-outer-gutters.fold(
              0pt,
              (sum, track) => sum + _fixed-size(track, inner-size.height),
            )
        )
        let auto-needed = resolved-rows.enumerate().fold(0pt, (sum, entry) => {
          let (index, track) = entry
          if track == auto { sum + _auto-height(regions.at(index), inner-size.width) } else { sum }
        })
        let has-flex-rows = resolved-rows.any(track => type(track) == fraction)
        let has-flex-gutters = resolved-gutters.any(track => type(track) == fraction)
        let has-flex-outer-gutters = resolved-outer-gutters.any(track => type(track) == fraction)
        let has-flex = has-flex-rows or has-flex-gutters or has-flex-outer-gutters
        let remaining = inner-size.height - fixed - auto-needed
        assert(
          remaining >= -_epsilon,
          message: owner + ": auto rows and fixed spacing need " + repr(fixed + auto-needed)
            + ", but the finite body provides only " + repr(inner-size.height),
        )
        if has-flex {
          let flexible-kinds = ()
          if has-flex-rows { flexible-kinds.push("rows") }
          if has-flex-gutters { flexible-kinds.push("gutters") }
          if has-flex-outer-gutters { flexible-kinds.push("outer gutters") }
          let flexible-kind = if flexible-kinds.len() == 1 {
            "fractional " + flexible-kinds.first()
          } else {
            "fractional " + flexible-kinds.join(", ")
          }
          assert(
            remaining > _epsilon,
            message: owner + ": auto rows consume the finite body and leave no positive height for "
              + flexible-kind,
          )
        }

        let fraction-weight = (resolved-rows + resolved-gutters + resolved-outer-gutters).fold(
          0.0,
          (sum, track) => sum + _fraction-weight(track),
        )
        let outer-sizes = resolved-outer-gutters.map(track => {
          let fixed-size = _fixed-size(track, inner-size.height)
          if type(track) == fraction {
            remaining * (_fraction-weight(track) / fraction-weight)
          } else {
            fixed-size
          }
        })
        let top-outer = outer-sizes.first()
        let bottom-outer = outer-sizes.last()
        let flow-height = inner-size.height - top-outer - bottom-outer

        return block(
          width: inner-size.width,
          height: inner-size.height,
          above: 0pt,
          below: 0pt,
          grid(
            columns: (1fr,),
            rows: (top-outer, flow-height, bottom-outer),
            gutter: 0pt,
            grid.cell(
              y: 1,
              inset: 0pt,
              row-split(
                regions,
                profile: effective-profile,
                name: owner,
                rows: resolved-rows,
                gutter: resolved-gutters,
                align: resolved-align,
                width: inner-size.width,
                height: flow-height,
                inset: 0pt,
                overflow: resolved-overflow,
              ),
            ),
          ),
        )
      })#_layout-debug-overlay("body-flow", owner)],
    )
  })
}
