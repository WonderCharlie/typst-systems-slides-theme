// Positive contract for finite natural body flow.
//
// This fixture consumes only the stable package facade.
#import "../lib.typ": (
  body-flow,
  column-split,
  layout-profile,
  point,
  points,
  region,
  row-split,
)

#set page(width: 480pt, height: 300pt, margin: 20pt)
#set text(size: 12pt)
#set par(leading: 0.35em, spacing: 0pt)

#let variant = sys.inputs.at("variant", default: "base")
#assert(variant in ("base", "wrapped", "more-points"), message: "unknown body-flow variant")

#let variable-points = (
  point([The first point participates in normal measurement.]),
  point([A nested point changes the same auto row.], level: 2),
)
#if variant == "more-points" {
  variable-points.push(point([MORE_POINTS_VARIANT adds another measured sibling.]))
  variable-points.push(point([Its nested detail also changes the remaining height.], level: 2))
}

#let cell(label, tone, height: 100%) = block(
  width: 100%,
  height: height,
  inset: 7pt,
  fill: tone,
  align(center + horizon, label),
)

#let finite-flow = layout-profile(
  name: "finite-contract",
  rows: (auto, 1fr),
  gutter: 10pt,
  align: top + left,
  inset: 4pt,
  overflow: "visible",
)

#body-flow(
  (
    region([
      Natural text, a formula $T = L + B / R$, and the table below determine
      this first row's height.

      #if variant == "wrapped" [
        WRAPPED_VARIANT deliberately adds enough editable prose to wrap onto
        another line; the following flexible region must move without a `#v`
        offset or a recalculated body height.
      ]

      #points(
        variable-points,
        gap: 4pt,
        nest-gap: 3pt,
        style: (size: 11pt),
        level-styles: ((size: 11pt), (size: 10pt)),
      )

      #table(
        columns: (auto, auto),
        inset: 2pt,
        [Metric], [Value],
        [Latency], [12 ms],
      )
    ], name: "measured-content"),
    region(
      column-split(
        (
          region(cell([LEFT FLEX], rgb("e7f2ff")), name: "left-column"),
          region(
            row-split(
              (
                region(cell([NESTED AUTO], rgb("f1ebff"), height: 30pt), name: "nested-auto"),
                region(cell([NESTED FLEX], rgb("e9f6e4")), name: "nested-flex"),
              ),
              name: "nested-rows",
              rows: (auto, 1fr),
              gutter: 6pt,
              width: 100%,
              height: 100%,
            ),
            name: "right-column",
          ),
        ),
        name: "remainder-columns",
        columns: (1fr, 1fr),
        gutter: 8pt,
        width: 100%,
        height: 100%,
      ),
      name: "flexible-remainder",
    ),
  ),
  profile: finite-flow,
  // A two-item array addresses the top and bottom edges independently.
  outer-gutter: (0pt, 0pt),
)

#pagebreak()

// Natural-height content remains ordinary Typst flow and needs no wrapper.
Ordinary content before a natural split remains in document flow.

#row-split(
  (
    [Natural row one],
    column-split(
      ([Natural left], [Natural right]),
      columns: (1fr, 1fr),
      gutter: 8pt,
    ),
  ),
  rows: (auto, auto),
  gutter: 8pt,
)
