// Negative contract fixture for the content-agnostic layout system.
//
// Compile with `--input case=<name>` to select one intended failure. With no
// input, the fixture renders a small valid layout so syntax/import regressions
// are distinguishable from the diagnostics under test.

#import "../lib.typ": column-split, layout-profile, page-frame, page-layer, region, row-split

#set page(width: 320pt, height: 180pt, margin: 10pt)
#set text(size: 10pt)

#let selected = sys.inputs.at("case", default: "")
#let two = ([first], [second])
#let three = ([first], [second], [third])

#if selected == "row-track-count" {
  row-split(
    two,
    name: "row-count",
    rows: (1fr,),
    width: 200pt,
    height: 100pt,
  )
} else if selected == "column-track-count" {
  column-split(
    two,
    name: "column-count",
    columns: (1fr,),
    width: 200pt,
    height: 100pt,
  )
} else if selected == "gutter-count" {
  row-split(
    three,
    name: "gutter-count",
    rows: (20pt, 20pt, 20pt),
    gutter: (5pt,),
    width: 200pt,
    height: 80pt,
  )
} else if selected == "align-count" {
  row-split(
    two,
    name: "align-count",
    rows: (40pt, 40pt),
    align: (top + left,),
    width: 200pt,
    height: 80pt,
  )
} else if selected == "fit-count" {
  row-split(
    two,
    name: "fit-count",
    rows: (40pt, 40pt),
    fit: ("flow",),
    width: 200pt,
    height: 80pt,
  )
} else if selected == "overflow-count" {
  row-split(
    two,
    name: "overflow-count",
    rows: (40pt, 40pt),
    overflow: ("visible",),
    width: 200pt,
    height: 80pt,
  )
} else if selected == "column-profile-on-row" {
  let column-profile = layout-profile(
    name: "column-only",
    columns: (1fr, 1fr),
  )
  row-split(
    two,
    profile: column-profile,
    name: "profile-direction",
    height: 100pt,
  )
} else if selected == "row-profile-on-column" {
  let row-profile = layout-profile(
    name: "row-only",
    rows: (1fr, 1fr),
    height: 100pt,
  )
  column-split(
    two,
    profile: row-profile,
    name: "profile-direction",
    width: 200pt,
  )
} else if selected == "inherited-profile-axis" {
  let row-base = layout-profile(
    name: "row-base",
    rows: (1fr,),
  )
  layout-profile(
    base: row-base,
    name: "mixed-derived",
    columns: (1fr,),
  )
} else if selected == "invalid-fit" {
  row-split(
    ([body],),
    name: "invalid-fit",
    rows: (40pt,),
    fit: "squash",
    width: 200pt,
    height: 40pt,
  )
} else if selected == "invalid-overflow" {
  row-split(
    ([body],),
    name: "invalid-overflow",
    rows: (40pt,),
    overflow: "hide",
    width: 200pt,
    height: 40pt,
  )
} else if selected == "fractional-rows-no-height" {
  row-split(
    two,
    name: "fractional-rows",
    rows: (1fr, 1fr),
    width: 200pt,
    height: none,
  )
} else if selected == "fixed-budget" {
  row-split(
    two,
    name: "fixed-budget",
    rows: (80pt, 40pt),
    gutter: 10pt,
    width: 200pt,
    height: 100pt,
  )
} else if selected == "strict-auto" {
  row-split(
    (
      region(
        [strict content],
        name: "strict-auto",
        overflow: "clip",
      ),
    ),
    name: "strict-auto-parent",
    rows: (auto,),
    width: 200pt,
    height: 80pt,
  )
} else if selected == "content-overflow" {
  row-split(
    (
      region(
        block(
          width: 120pt,
          height: 30pt,
          [ordinary native content with deterministic overflow],
        ),
        name: "overflowing-content",
        fit: "flow",
        overflow: "error",
      ),
    ),
    name: "content-overflow-parent",
    rows: (20pt,),
    width: 100pt,
    height: 20pt,
  )
} else if selected == "nested-fixed-budget" {
  row-split(
    (
      region(
        row-split(
          ([nested first], [nested second]),
          name: "nested-budget",
          rows: (30pt, 30pt),
          gutter: 10pt,
          width: 100%,
          height: 100%,
        ),
        name: "nested-container",
      ),
    ),
    name: "outer-budget",
    rows: (50pt,),
    width: 200pt,
    height: 50pt,
  )
} else if selected == "page-layer-invalid-area" {
  page-layer([mask], name: "invalid-area", area: "title")
} else if selected == "overlay-body-area" {
  page-frame(
    name: "invalid-overlay",
    overlay: page-layer([mask], area: "body"),
  )
} else if selected == "margin-with-chrome" {
  page-frame(
    name: "moving-chrome",
    chrome: true,
    margin: 32pt,
  )
} else if selected == "media-overflow" {
  row-split(
    (
      region(
        rect(width: 120pt, height: 60pt, fill: gray),
        name: "oversized-media",
        overflow: "error",
      ),
    ),
    rows: (50pt,),
    width: 100pt,
    height: 50pt,
  )
} else if selected == "" {
  row-split(
    (
      [valid header],
      column-split(
        ([valid left], [valid right]),
        columns: (1fr, 1fr),
        gutter: 8pt,
        width: 100%,
        height: 100%,
      ),
    ),
    rows: (20pt, 1fr),
    gutter: 8pt,
    width: 100%,
    height: 100%,
  )
} else {
  panic("layout-diagnostics: unknown case " + repr(selected))
}
