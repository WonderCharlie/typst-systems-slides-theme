// Measured page contract for the systems-slides-template theme.
//
// The values define the calibrated systems-slides-template master. Page-level components
// may consume these global regions; content semantics such as `points` do not.

#import "tokens.typ": (
  slide-width,
  slide-height,
  footer-y,
  font-sans,
  title-rule-stroke,
  title-rule-width,
  title-rule-x,
  title-rule-y,
  type-lead,
)

#let content-left = 34.416pt
#let content-right = 938.416pt
#let content-width = content-right - content-left
#let body-top = title-rule-y + title-rule-stroke / 2
#let body-content-top = 79.56pt
#let body-content-inset-top = body-content-top - body-top
#let content-bottom = footer-y

#let systems-layout = (
  slide: (
    width: slide-width,
    height: slide-height,
  ),
  title: (
    x: 34.416pt,
    visible-y: 19.21pt,
    size: 40pt,
    min-size: 30pt,
    single-line-height: 46pt,
    row-height: 66pt,
    band-height: 78pt,
    rule-x: title-rule-x,
    rule-y: title-rule-y,
    rule-width: title-rule-width,
    rule-stroke: title-rule-stroke,
    // Compensates for the header grid's intrinsic line position so the
    // rendered stroke center lands at the measured absolute rule-y.
    rule-optical-dy: 6.438pt,
    // The fixed row isolates title geometry from optional page marks and
    // section progress. This correction restores the measured title anchor.
    row-optical-dy: 17.967pt,
    // The source PNG has a sub-point white edge; 20.25pt layout inset yields
    // the measured 20.75pt visible-pixel clearance at the page edge.
    mark-right-inset: 20.25pt,
  ),
  body: (
    left: content-left,
    right: content-right,
    // The 576 DPI reference raster places the 0.5pt rule at y=68.375--
    // 68.875pt. The body begins at the rule's lower edge, not at the first
    // ordinary content baseline.
    top: body-top,
    // Ordinary flow retains the measured 79.56pt content anchor through an
    // explicit inset. Page layers can therefore address the complete body
    // region without changing the established text rhythm.
    content-top: body-content-top,
    content-inset-top: body-content-inset-top,
    bottom: content-bottom,
    width: content-width,
    height: content-bottom - body-top,
  ),
  footer: (
    y: footer-y,
    height: slide-height - footer-y,
    inset-left: 12pt,
    inset-right: 24pt,
    columns: (214.58pt, 601.3pt, auto, 36.573pt, 20pt),
    title-width: 601.3pt,
    text-size: 12.024pt,
    logo-width: 59.25pt,
    logo-height: 31.5pt,
    logo-dx: -0.254pt,
    logo-dy: 2.182pt,
  ),
  lead: (
    font: font-sans,
    size: type-lead,
    weight: "regular",
    leading: 0.38em,
  ),
)
