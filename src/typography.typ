// Public, content-only typography semantics for the systems-slides-template theme.
//
// This module owns text appearance, not page placement.  In particular it
// does not import Touying, the page master, or the list renderer.

#import "../themes/systems-slides-template/tokens.typ" as _tokens
#import "../themes/systems-slides-template/geometry.typ" as _geometry

// Inline semantic emphasis.  The surrounding text owns any property that is
// not named here, so local content styling continues to compose naturally.

/// 将任意行内内容渲染为危险/错误强调，不承担页面定位。
///
/// - body (content): 必填的任意 Typst 内容。
///   本函数改为红色粗体，其余文字属性继承调用位置。
/// -> content
#let danger(
  body,
) = text(weight: "bold", fill: _tokens.red, body)
// Named tones let slide content share the theme palette without exposing raw
// RGB values in page content.
#let font-family = _tokens.font-sans
#let tone-primary = _tokens.purple
#let tone-deep = _tokens.deep-purple
#let tone-ink = _tokens.ink
#let tone-white = _tokens.white
#let tone-danger = _tokens.red
#let tone-cyan = _tokens.cyan
#let tone-blue = _tokens.blue
#let tone-amber = _tokens.amber
#let tone-yellow = _tokens.yellow
#let tone-green = _tokens.green
#let tone-chart-blue = _tokens.chart-blue
#let tone-link = _tokens.link-blue
#let tone-grey = _tokens.grey
#let tone-mid-grey = _tokens.mid-grey
#let tone-dark-grey = _tokens.dark-grey
#let tone-light-grey = _tokens.light-grey
#let tone-faint-grey = _tokens.faint-grey

// A lead is a typography primitive. Its parent layout decides where the block
// starts; this function controls only its width and internal line rhythm.

/// 渲染演示页的引导文字块。
/// 本接口只控制文字宽度和内部行距，不决定页面坐标。
///
/// - body (content): 必填的任意 Typst 引导内容。
///   局部行内样式仍可覆盖，页面位置由外层布局负责。
/// - compact (bool): 是否压缩多行行距；默认 `false`。允许 `true`/`false`；`true` 将 `leading` 乘以 `0.72`；
///   显式值仅覆盖行距派生规则；不改变字号、字重或宽度。
/// - alignment (any): 块内对齐，默认 `left`；接受 Typst alignment。
///   本参数不决定块在页面中的位置。
/// - width (length, ratio, relative): 文字块宽度，默认 `100%` 跟随父容器。
///   接受非负长度、百分比或相对长度；
///   百分比和相对长度相对调用位置可用宽度解析。
/// - leading (length): 基础段落行距；默认使用 Theme 的 lead 行距。允许非负 Typst 长度；相对单位随文字缩放；
///   显式值覆盖 Theme 默认，随后可受 `compact` 派生；只作用于当前块。
/// -> content
#let lead(
  body,
  compact: false,
  alignment: left,
  width: 100%,
  leading: _geometry.systems-layout.lead.leading,
) = {
  // Compact mode tightens only multiline leading. The default path preserves
  // the calibrated master rhythm; width, font size, and weight stay stable in
  // both modes.
  let resolved-leading = if compact { leading * 0.72 } else { leading }
  block(
    width: width,
    above: 0pt,
    below: 0pt,
    align(alignment, [
      #set par(leading: resolved-leading, spacing: 0pt)
      #text(
        font: _geometry.systems-layout.lead.font,
        size: _geometry.systems-layout.lead.size,
        weight: _geometry.systems-layout.lead.weight,
        body,
      )
    ]),
  )
}
