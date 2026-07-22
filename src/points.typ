// Local, layout-independent multilevel bullet semantics.
//
// `point` describes content and its level in a flat, depth-first sequence.
// `points` renders that hierarchy in the normal flow of its caller. Neither
// function knows the slide size, body anchor, header, footer, or any page-space
// coordinate. Theme-owned defaults cover list-local typography, indentation,
// markers, and rhythm; callers override stable arguments directly.

// List-local design defaults. Keeping them here means the core can be imported
// and tested without loading Touying, the page master, or any slide geometry.
#let default-points-font = "Poppins"
#let default-points-ink = rgb("#000000")

#let max-point-level = 4

#let normalize-style(style) = {
  assert(type(style) == dictionary, message: "point style must be a dictionary")
  let result = style
  if "color" in result {
    let color = result.at("color")
    let _ = result.remove("color")
    result.insert("fill", color)
  }
  result
}

#let level-value(values, level, fallback) = {
  if level <= values.len() {
    let value = values.at(level - 1)
    if value == auto { fallback } else { value }
  } else {
    fallback
  }
}

// Internal defaults for the public Points renderer. Deck authors customize
// the stable `points` arguments directly instead of selecting hidden presets.
#let points-defaults(
  indents: (0pt, 36pt, 72pt, 108pt),
  text-offsets: (18pt, 18pt, 18pt, 18pt),
  text-styles: (
    (font: default-points-font, size: 28pt, weight: "regular", fill: default-points-ink),
    (font: default-points-font, size: 24pt, weight: "regular", fill: default-points-ink),
    (font: default-points-font, size: 20pt, weight: "regular", fill: default-points-ink),
    (font: default-points-font, size: 18pt, weight: "regular", fill: default-points-ink),
  ),
  markers: ([•], [•], [◦], [-]),
  marker-styles: (
    (font: default-points-font, size: 28pt, weight: "regular", fill: default-points-ink),
    (font: default-points-font, size: 24pt, weight: "regular", fill: default-points-ink),
    (font: default-points-font, size: 20pt, weight: "regular", fill: default-points-ink),
    (font: default-points-font, size: 18pt, weight: "regular", fill: default-points-ink),
  ),
  leading: 0.38em,
  gap: 45pt,
  level-gaps: (45pt, 44.65pt, 30pt, 24pt),
  nest-gap: 15pt,
  marker-frame-ratio: 0.94,
) = {
  for values in (indents, text-offsets, text-styles, markers, marker-styles) {
    assert(
      values.len() == max-point-level,
      message: "Points defaults must configure exactly four levels",
    )
  }
  assert(
    level-gaps.len() == max-point-level,
    message: "Points defaults must provide four sibling gaps",
  )
  (
    indents: indents,
    text-offsets: text-offsets,
    text-styles: text-styles,
    markers: markers,
    marker-styles: marker-styles,
    leading: leading,
    gap: gap,
    level-gaps: level-gaps,
    nest-gap: nest-gap,
    marker-frame-ratio: marker-frame-ratio,
  )
}

// The template default is a list-local style object rather than a page layout
// contract; it never inspects the surrounding slide or narrative.
#let default-points = points-defaults()

/// 构造扁平的多级 Bullet 条目。
/// 层级由显式 `level` 表达，不创建私有 children 树。
///
/// - body (content): 条目正文；必填。允许任意 Typst 内容和手动换行；局部行内样式是最高优先级；一个 point 只描述一个条目。
/// - level (int): 条目层级，默认 `1`；允许 `1` 至 `4`，且不继承前项。
///   列表首项必须为一级，后续最多增加一级。
/// - style (dictionary): 当前条目正文样式覆盖；默认空字典。允许 Typst text 字段；`color` 转为 `fill`；
///   优先于 Theme 默认、列表级和层级级样式，低于正文局部样式；必须为字典。
/// - marker (content, auto): 当前条目标记覆盖；默认 `auto`。允许任意 content；`auto` 继承已解析标记；显式值拥有标记内容最高优先级；不改变标记样式。
/// - marker-style (dictionary): 当前条目标记样式覆盖；默认空字典。允许 Typst text 字段；`color` 转为 `fill`；
///   优先于 Theme 默认、列表级和层级级标记样式；必须为字典且不影响正文。
/// -> dictionary
#let point(
  body,
  level: 1,
  style: (:),
  marker: auto,
  marker-style: (:),
) = {
  assert(type(level) == int, message: "point level must be an integer")
  assert(
    level >= 1 and level <= max-point-level,
    message: "point level must be between 1 and 4",
  )
  assert(type(style) == dictionary, message: "point style must be a dictionary")
  assert(
    type(marker-style) == dictionary,
    message: "point marker-style must be a dictionary",
  )
  (
    body: body,
    level: level,
    style: style,
    marker: marker,
    marker-style: marker-style,
  )
}

#let point-row(
  item,
  level,
  width,
  defaults,
  base-style,
  level-styles,
  base-marker,
  level-markers,
  base-marker-style,
  level-marker-styles,
  leading,
) = {
  let index = level - 1
  let default-text-style = normalize-style(defaults.text-styles.at(index))
  let item-style = normalize-style(item.at("style", default: (:)))
  let text-style = (
    default-text-style
    + normalize-style(base-style)
    + normalize-style(level-value(level-styles, level, (:)))
    + item-style
  )

  let default-marker = defaults.markers.at(index)
  let interface-marker = if base-marker == auto { default-marker } else { base-marker }
  let configured-marker = level-value(level-markers, level, interface-marker)
  let item-marker = item.at("marker", default: auto)
  let resolved-marker = if item-marker == auto { configured-marker } else { item-marker }
  let marker-style = (
    normalize-style(defaults.marker-styles.at(index))
    + normalize-style(base-marker-style)
    + normalize-style(level-value(level-marker-styles, level, (:)))
    + normalize-style(item.at("marker-style", default: (:)))
  )
  let tight-marker-style = marker-style + (
    top-edge: "bounds",
    bottom-edge: "bounds",
  )
  let first-line-frame = text-style.at("size") * defaults.marker-frame-ratio
  let indent = defaults.indents.at(index)
  let marker-column = defaults.text-offsets.at(index)

  block(
    width: width,
    breakable: false,
    above: 0pt,
    below: 0pt,
    grid(
      columns: (indent, marker-column, 1fr),
      column-gutter: 0pt,
      row-gutter: 0pt,
      inset: 0pt,
      align: top + left,
      [],
      block(
        width: 100%,
        above: 0pt,
        below: 0pt,
        [
          // Keep the original line-box height as an invisible strut while the
          // visible glyph is centered independently in the text's first line.
          #hide(text(..marker-style, resolved-marker))
          #place(
            top + left,
            block(
              width: 100%,
              height: first-line-frame,
              above: 0pt,
              below: 0pt,
              align(left + horizon, text(..tight-marker-style, resolved-marker)),
            ),
          )
        ],
      ),
      block(
        width: 100%,
        above: 0pt,
        below: 0pt,
        [
          #set par(leading: leading, spacing: 0pt)
          #text(..text-style, item.body)
        ],
      ),
    ),
  )
}

#let point-plan(items, gap, level-gaps, nest-gap) = {
  let result = ()
  let previous-level = none

  for (index, item) in items.enumerate() {
    assert(type(item) == dictionary, message: "points items must be made with point(...)")
    assert("body" in item, message: "each points item must contain a body")
    let level = item.at("level", default: 1)
    assert(type(level) == int, message: "point level must be an integer")
    assert(
      level >= 1 and level <= max-point-level,
      message: "point level must be between 1 and 4",
    )

    if index == 0 {
      assert(level == 1, message: "a points list must begin at level one")
    } else {
      assert(
        level <= previous-level + 1,
        message: "point levels cannot skip a hierarchy level",
      )
      let boundary-gap = if level == previous-level + 1 {
        nest-gap
      } else {
        level-value(level-gaps, level, gap)
      }
      result.push((kind: "gap", value: boundary-gap))
    }
    result.push((kind: "row", item: item, level: level))
    previous-level = level
  }
  result
}

/// 在普通文档流中渲染最多四级的 Bullet 序列。
/// 每个同级或跨级边界只应用一次间距。
///
/// - items (array): 必填的 `point` 非空数组，按深度优先顺序排列。
///   首项必须为一级，且层级不可跳跃。
/// - width (length, ratio): 列表块宽度，默认 `100%` 使用父容器宽度。
///   固定或相对宽度必须能在父容器中解析。
/// - leading (length, auto): 条目内部多行文本的行距；默认 `auto` 使用 Theme 的 `0.38em`；显式长度只影响条目内部换行，不参与条目之间的 gap。
/// - gap (length, auto): 所有层级共用的默认同级条目间距；默认 `auto` 使用 Theme 节奏。显式长度成为层级缺省值。 `level-gaps` 可继续覆盖它；
///   同一边界只应用一次。
/// - level-gaps (array): 分层同级间距覆盖；默认空数组使用 Theme 的四级节奏。允许最多四项长度或 `auto`；缺失或 `auto` 项回退解析后的 gap；
///   第 n 项对应第 n 层。
/// - nest-gap (length, auto): 父项到直接子项的间距；默认 `auto` 使用 Theme 节奏。显式长度直接覆盖；仅用于层级增加一级的边界。
/// - style (dictionary): 全层级正文统一覆盖；默认空字典。允许 text 字段；`color` 转为 `fill`；优先于 Theme 默认、低于层级和条目样式；必须为字典。
/// - level-styles (array): 分层正文样式；默认空数组。允许最多四个字典或 `auto`；空、缺失或 `auto` 使用 Theme 默认或统一 style；低于条目样式。
/// - marker (content, auto): 全层级统一标记；默认 `auto` 使用 Theme 标记。低于分层标记和条目标记；只影响标记内容。
/// - level-markers (array): 分层标记覆盖；默认空数组。允许最多四个 content 或 `auto`；
///   空、缺失或 `auto` 回退统一 marker 或 Theme 标记；低于条目标记。
/// - marker-style (dictionary): 全层级标记样式，默认空字典。
///   允许 text 字段；`color` 转为 `fill`；优先于 Theme 默认、低于分层和条目标记样式；
///   不影响正文。
/// - level-marker-styles (array): 分层标记样式；默认空数组。允许最多四个字典或 `auto`；空、缺失或 `auto` 使用 Theme 默认或统一样式；
///   低于条目样式。
/// -> content
#let points(
  items,

  // Block geometry and vertical rhythm.
  width: 100%,
  leading: auto,
  gap: auto,
  level-gaps: (),
  nest-gap: auto,

  // Body text overrides.
  style: (:),
  level-styles: (),

  // Marker content and style overrides.
  marker: auto,
  level-markers: (),
  marker-style: (:),
  level-marker-styles: (),
) = {
  assert(type(items) == array and items.len() > 0, message: "points requires a non-empty array")
  assert(type(level-gaps) == array, message: "level-gaps must be an array")
  assert(type(style) == dictionary, message: "style must be a dictionary")
  assert(type(level-styles) == array, message: "level-styles must be an array")
  assert(type(level-markers) == array, message: "level-markers must be an array")
  assert(type(marker-style) == dictionary, message: "marker-style must be a dictionary")
  assert(type(level-marker-styles) == array, message: "level-marker-styles must be an array")
  assert(
    level-gaps.len() <= max-point-level
    and level-styles.len() <= max-point-level
    and level-markers.len() <= max-point-level
    and level-marker-styles.len() <= max-point-level,
    message: "points level override tables support at most four entries",
  )

  // Hierarchy is one flat, depth-first stream. Adjacent levels determine the
  // single applicable boundary gap, so styling never selects another geometry
  // path and no private tree representation is needed.
  let defaults = default-points
  let resolved-gap = if gap != auto {
    gap
  } else {
    defaults.gap
  }
  let resolved-level-gaps = if level-gaps.len() > 0 {
    level-gaps
  } else if gap != auto {
    ()
  } else {
    defaults.level-gaps
  }
  let resolved-nest-gap = if nest-gap != auto {
    nest-gap
  } else {
    defaults.nest-gap
  }
  let resolved-leading = if leading == auto {
    defaults.leading
  } else {
    leading
  }
  let plan = point-plan(items, resolved-gap, resolved-level-gaps, resolved-nest-gap)

  block(width: width, breakable: false, above: 0pt, below: 0pt, [
    #for entry in plan {
      if entry.kind == "gap" {
        v(entry.value, weak: false)
      } else {
        point-row(
          entry.item,
          entry.level,
          width,
          defaults,
          style,
          level-styles,
          marker,
          level-markers,
          marker-style,
          level-marker-styles,
          resolved-leading,
        )
      }
    }
  ])
}
