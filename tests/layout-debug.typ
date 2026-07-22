// Positive contract for explicit, compile-time layout inspection overlays.

#import "../lib.typ": (
  body-flow,
  column-split,
  layout-profile,
  region,
  slide,
  systems-slides-theme,
)

#show: systems-slides-theme.with(
  title: [Layout Debug Contract],
  author: [Systems Slides Template],
  date: datetime(year: 2026, month: 7, day: 21),
)

#slide(title: [Layout debug contract])[
  #body-flow(
    (
      region([Natural introduction], name: "natural lead"),
      region(
        column-split(
          (
            region([LEFT DEBUG REGION], name: "left media"),
            region([RIGHT DEBUG REGION], name: "right points"),
          ),
          name: "debug columns",
          columns: (1fr, 1fr),
          gutter: 12pt,
          width: 100%,
          height: 100%,
        ),
        name: "remaining content",
      ),
    ),
    profile: layout-profile(
      name: "debug flow",
      rows: (auto, 1fr),
      gutter: 10pt,
    ),
  )
]
