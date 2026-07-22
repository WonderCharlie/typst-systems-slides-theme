#import "../lib.typ": column-split, layout-profile, region, row-split

#set page(width: 960pt, height: 540pt, margin: 24pt)
#set text(size: 16pt)

#let frame(body, tone) = block(
  width: 100%,
  height: 100%,
  inset: 8pt,
  fill: tone,
  body,
)

#let nested-profile = layout-profile(
  name: "nested-columns",
  columns: (38%, 1fr, 2fr),
  gutter: (8pt, 12pt),
  align: (top + left, center + horizon, bottom + right),
  width: 100%,
  height: 100%,
  fit: "flow",
  overflow: "visible",
)

#row-split(
  (
    frame([Fixed top row], rgb("#ece8ff")),
    column-split(
      (
        region(frame([38%], rgb("#def3ff")), name: "percentage"),
        region(frame([$ sum_(i=1)^n i $], rgb("#eef8e8")), name: "formula"),
        region(
          frame([
            #table(
              columns: (auto, auto),
              [Metric], [Value],
              [Latency], [12 ms],
            )
          ], rgb("#fff0e7")),
          name: "table",
        ),
      ),
      profile: nested-profile,
    ),
    frame([Flexible footer row], rgb("#f3f3f3")),
  ),
  name: "contract-root",
  rows: (52pt, 1fr, 12%),
  gutter: (10pt, 2%),
  width: 100%,
  height: 100%,
)

#pagebreak()

#let fit-profile = layout-profile(
  name: "fit-policies",
  columns: (1fr, 1fr, 1fr),
  gutter: 12pt,
  align: (center + horizon, center + horizon, center + horizon),
  width: 100%,
  height: 100%,
  fit: ("contain", "cover", "stretch"),
  overflow: ("visible", "clip", "clip"),
)

#column-split(
  (
    region(
      block(width: 220pt, height: 95pt, fill: rgb("#e8e0ff"), align(center + horizon)[CONTAIN]),
      name: "contain-example",
    ),
    region(
      block(width: 90pt, height: 220pt, fill: rgb("#dff3ff"), align(center + horizon)[COVER]),
      name: "cover-example",
    ),
    region(
      block(width: 210pt, height: 70pt, fill: rgb("#e8f4dd"), align(center + horizon)[STRETCH]),
      name: "stretch-example",
    ),
  ),
  profile: fit-profile,
)
