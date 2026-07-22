// Purpose: establish the Theme lifecycle, stable chrome, and native Typst content.
// Public API: title-slide, outline-slide, slide, page-mark, lead, points, split.
// Defaults: Theme owns type, color, title rule, body boundary, Footer, tables, and raw code.
// Stable regions: chrome never depends on body content or presentation state.
#import "@local/systems-slides-template:0.4.0": (
  callout,
  column-split,
  lead,
  outline-slide,
  page-mark,
  panel,
  point,
  points,
  region,
  slide,
  title-slide,
  typography,
)
#import "../globals.typ": asset-path

#title-slide(
  title-lines: (
    [Relay: Dependency-Aware I/O Scheduling],
    [for Data-Intensive Services],
  ),
  author-lines: ([Systems Slides Template Contributors], [Synthetic research demonstration]),
  subtitle: [An executable Catalog of Theme layout capabilities],
  affiliations: (
    asset-path("marks/synthetic-institute.svg"),
    text(size: 18pt, weight: "bold", fill: typography.tone-primary)[OPEN SYSTEMS CONSORTIUM],
  ),
  event-mark: asset-path("marks/relay-event.svg"),
  counted: false,
)

#outline-slide(title: [Catalog Roadmap], level: 1, spacing: 20pt)

#slide(
  title: [Stable Slide Chrome],
  marks: (page-mark(asset-path("marks/dependency-mark.svg")),),
)[
  #lead([Remote I/O is part of the request critical path.])
  #v(18pt)
  #column-split(
    (
      region([
        #panel(
          title: [Body region],
          stroke-tone: typography.tone-light-grey,
        )[
          Text, figures, tables, formulas, and splits share one finite body boundary.
          #v(18pt)
          #line(length: 100%, stroke: 1pt + typography.tone-light-grey)
          #v(12pt)
          Authors never need header or Footer coordinates.
        ]
      ], align: center + horizon),
      region(points((
        point([Theme renders the title and rule.]),
        point([The page mark owns a title-area slot.]),
        point([Footer metadata and page number stay stable.]),
        point([Body content starts below the measured rule.]),
      ), gap: 10pt), align: left + top, overflow: "error"),
    ),
    columns: (1.15fr, 0.85fr),
    gutter: 30pt,
    height: 300pt,
  )
]

#slide(title: [Native Typst Content])[
  #column-split(
    (
      region([
        Relay exposes only dependency-critical delay:
        #v(13pt)
        #align(center)[$L_"request" = L_"critical" + max(0, C_"ready" - L_"hidden") + L_"commit"$]
        #v(18pt)
        #link("https://example.invalid/relay")[#text(fill: typography.tone-link)[Synthetic artifact and source]]
        #v(16pt)
        #callout(
          [The Theme supplies presentation defaults without replacing native formula, link, emphasis, or reference semantics.],
          title: [Native first],
        )
      ]),
      region([
        #raw(
          "for request in ready_queue:\n  trace(request.dependencies)\n  prefetch(request.blocking_io)\n  run(request.independent_work)\n  commit_in_order(request)",
          block: true,
          lang: "text",
        )
        #v(18pt)
        #points((
          point([Poppins is the Theme text face.]),
          point([Source Code Pro is the bundled code face.]),
          point([System fonts remain disabled.]),
        ))
      ]),
    ),
    columns: (1.08fr, 0.92fr),
    gutter: 30pt,
  )
]
