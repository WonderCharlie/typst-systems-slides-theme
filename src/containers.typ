// Small, content-neutral containers for slide bodies.

#import "../themes/systems-slides-template/tokens.typ": white, deep-purple, red, faint-grey

/// 渲染与页面位置无关的通用视觉面板，可承载任意 Typst 内容。
///
/// - body (content): 面板正文；必填，无特殊值；内容的局部样式保持最高优先级；必须适配面板可用宽度。
/// - title (content, none): 可选标题；默认 `none`；`none` 移除标题及其后间距，显式内容覆盖默认；标题存在时使用面板标题样式。
/// - tone (color, gradient, tiling, none): 背景填充；默认浅灰；`none` 表示透明，显式值覆盖默认；应与正文保持足够对比度。
/// - stroke-tone (color, none): 边框颜色；默认 `none`；`none` 移除边框，显式颜色生成 `1pt` 边框；不控制边框宽度。
/// - title-tone (color): 标题颜色；默认深紫色，无特殊值；显式值只覆盖标题颜色；`title: none` 时不产生效果。
/// - inset (length, relative, dictionary): 内边距；默认 `14pt`；`0pt` 表示无内边距，显式值覆盖默认；不得将正文挤压至不可读宽度。
/// -> content
#let panel(
  body,
  title: none,
  tone: faint-grey,
  stroke-tone: none,
  title-tone: deep-purple,
  inset: 14pt,
) = block(
  width: 100%,
  above: 0pt,
  below: 0pt,
  fill: tone,
  stroke: if stroke-tone == none { none } else { 1pt + stroke-tone },
  radius: 7pt,
  inset: inset,
  [
    #if title != none {
      block(below: 10pt, text(size: 20pt, weight: "bold", fill: title-tone, title))
    }
    #body
  ],
)

/// 渲染通用强调框，以独立的边框色和背景承载任意内容。
///
/// - body (content): 强调框正文；必填，无特殊值；内容局部样式保持最高优先级；必须适配容器宽度。
/// - title (content, none): 可选标题；默认 `none`；`none` 移除标题及间距，显式值覆盖默认；标题存在时采用强调样式。
/// - tone (color): 边框与标题强调色；默认红色，无特殊值；显式值覆盖默认；应与背景保持对比度。
/// - fill-tone (color, gradient, tiling, none): 背景填充；默认白色；`none` 表示透明，显式值覆盖默认；不会自动改变正文颜色。
/// -> content
#let callout(
  body,
  title: none,
  tone: red,
  fill-tone: white,
) = block(
  width: 100%,
  above: 0pt,
  below: 0pt,
  inset: 14pt,
  radius: 7pt,
  fill: fill-tone,
  stroke: 2pt + tone,
  [
    #if title != none {
      block(below: 6pt, text(size: 18pt, weight: "bold", fill: tone, title))
    }
    #text(size: 20pt, body)
  ],
)
