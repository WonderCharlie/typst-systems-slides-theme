#import "../lib.typ": body-flow, point, points, region, runtime, slide, systems-slides-theme

#show: systems-slides-theme.with(
  title: [Body Flow Distribution Fixture],
  author: [Theme validation],
  date: datetime(year: 2026, month: 7, day: 22),
  section-progress: false,
  section-slides: false,
)

#let group(fill, body, bottom-inset: 0pt) = block(
  width: 100%,
  fill: fill,
  inset: (bottom: bottom-inset),
  body,
)

#slide(title: [Distributed Natural Regions], repeat: 3, self => [
  #body-flow(
    (
      region(group(rgb("fde8e8"), points((
        point([Preserve storage ordering.]),
      )))),
      region(group(rgb("e8efff"), runtime.uncover("2-", self: self)[
        #points((
          point([Avoid unnecessary synchronization.]),
          point([Keep dependency-critical I/O explicit.], level: 2),
        ))
      ])),
      region(group(
        rgb("e6f6ec"),
        runtime.uncover("3-", self: self)[
          #block(width: 620pt)[
            #points((
              point([Require no application changes while preserving existing deployment interfaces.]),
            ))
          ]
        ],
        bottom-inset: 7pt,
      )),
    ),
    rows: (auto, auto, auto),
    gutter: 3fr,
    outer-gutter: 2fr,
    inset: (top: 12pt, bottom: 12pt),
  )
])
