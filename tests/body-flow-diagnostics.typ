// Negative diagnostic fixture for `body-flow`.
// Compile with `--input case=<name>`; the empty case is a positive control.

#import "../lib.typ": body-flow, layout-profile, region, row-split

#set page(width: 320pt, height: 180pt, margin: 10pt)
#set text(size: 10pt)

#let selected = sys.inputs.at("case", default: "")

#if selected == "unbounded-width" {
  context {
    let _ = measure(body-flow(
      ([unbounded auto], [unbounded flex]),
      rows: (auto, 1fr),
    ))
    []
  }
} else if selected == "track-count" {
  body-flow(
    ([first], [second]),
    profile: layout-profile(name: "count-mismatch"),
    rows: (1fr,),
  )
} else if selected == "auto-exhausted" {
  block(
    width: 240pt,
    height: 60pt,
    body-flow(
      (
        block(width: 100%, height: 60pt, [AUTO CONTENT]),
        [FLEX CONTENT],
      ),
      profile: layout-profile(name: "auto-exhausted"),
      rows: (auto, 1fr),
    ),
  )
} else if selected == "fractional-gutter-exhausted" {
  block(
    width: 240pt,
    height: 60pt,
    body-flow(
      (
        block(width: 100%, height: 30pt, [FIRST AUTO]),
        block(width: 100%, height: 30pt, [SECOND AUTO]),
      ),
      profile: layout-profile(name: "fractional-gutter-exhausted"),
      rows: (auto, auto),
      gutter: 1fr,
    ),
  )
} else if selected == "fractional-outer-gutter-exhausted" {
  block(
    width: 240pt,
    height: 60pt,
    body-flow(
      (
        block(width: 100%, height: 30pt, [FIRST AUTO]),
        block(width: 100%, height: 30pt, [SECOND AUTO]),
      ),
      profile: layout-profile(name: "fractional-outer-gutter-exhausted"),
      rows: (auto, auto),
      gutter: 0pt,
      outer-gutter: 1fr,
    ),
  )
} else if selected == "outer-gutter-count" {
  body-flow(
    ([first], [second]),
    profile: layout-profile(name: "outer-gutter-count"),
    rows: (auto, auto),
    outer-gutter: (4pt,),
  )
} else if selected == "nested-finite-budget" {
  block(
    width: 240pt,
    height: 50pt,
    body-flow(
      (
        [fixed header],
        region(
          row-split(
            ([nested first], [nested second]),
            name: "nested-remainder",
            rows: (30pt, 30pt),
            gutter: 10pt,
            width: 100%,
            height: 100%,
          ),
          name: "finite-remainder",
        ),
      ),
      profile: layout-profile(name: "nested-finite"),
      rows: (20pt, 1fr),
      // This fixture isolates the nested split's explicit 10pt gutter from
      // body-flow's ordinary 20pt content rhythm.
      gutter: 0pt,
    ),
  )
} else if selected == "" {
  block(
    width: 240pt,
    height: 120pt,
    body-flow(
      ([valid auto], [valid flex]),
      profile: layout-profile(name: "positive-control"),
      rows: (auto, 1fr),
      gutter: 8pt,
    ),
  )
} else {
  panic("body-flow-diagnostics: unknown case " + repr(selected))
}
