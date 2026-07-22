// Purpose: prove stable vertical composition under real Touying state changes.
// Public API: slide, body-flow, region, points, runtime.uncover, runtime.only, runtime.alternatives.
// Defaults: natural flow and intrinsic image sizing; explicit heights only reserve stable evidence regions.
// Stable regions: chart on pages 5–7, bottom image on 8–10, bottom stack on 14–16, and distributed Points on 17–19.
#import "@local/systems-slides-template:0.6.0": (
  body-flow,
  point,
  points,
  region,
  runtime,
  slide,
  typography,
)
#import "../globals.typ": asset-path

#slide(title: [Fixed Evidence, Progressive Interpretation], repeat: 3)[
  #align(center)[#image(asset-path("charts/p99-latency.svg"), height: 225pt)]
  #v(18pt)
  #stack(
    dir: ttb,
    spacing: 12pt,
    [Relay reduces synthetic P99 latency by #text(weight: "bold", fill: typography.tone-danger)[31%].],
    runtime.uncover("2-")[The benefit grows as queue depth increases.],
    runtime.uncover(3)[CPU overhead remains below 3% in the same synthetic study.],
  )
]

#slide(title: [Progressive Requirements, Fixed Architecture], repeat: 3)[
  #runtime.only(1)[#points((point([Preserve storage ordering.]),))]
  #runtime.only(2)[#points((
    point([Preserve storage ordering.]),
    point([Avoid unnecessary synchronization.]),
  ))]
  #runtime.only(3)[#points((
    point([Preserve storage ordering.]),
    point([Avoid unnecessary synchronization.]),
    point([Require no application changes.]),
  ))]
  #v(1fr)
  #align(center + bottom)[#image(asset-path("diagrams/architecture.svg"), width: 650pt)]
]

#slide(title: [Reserve, Release, and Replace], repeat: 3)[
  #grid(
    columns: (1fr, 1fr, 1fr),
    gutter: 20pt,
    block(height: 268pt, inset: 14pt, radius: 7pt, fill: typography.tone-faint-grey)[
      #text(weight: "semibold", fill: typography.tone-primary)[RESERVE · uncover]
      #v(18pt)
      Critical I/O is issued first.
      #v(18pt)
      #runtime.uncover("2-")[Dependency evidence appears here without moving this explanation.]
    ],
    block(height: 268pt, inset: 14pt, radius: 7pt, fill: typography.tone-faint-grey)[
      #text(weight: "semibold", fill: typography.tone-blue)[RELEASE · only]
      #v(18pt)
      #runtime.only(2)[A transient queue annotation exists only in state two.]
      #v(18pt)
      The following prose occupies naturally released space.
    ],
    block(height: 268pt, inset: 14pt, radius: 7pt, fill: typography.tone-faint-grey)[
      #text(weight: "semibold", fill: typography.tone-green)[REPLACE · alternatives]
      #v(18pt)
      #runtime.alternatives(start: 1)[Arrival order][Dependency order][Critical-path order]
      #v(18pt)
      One fixed outer region hosts three candidate contents.
    ],
  )
]

#slide(title: [Bottom-Aligned Layer Growth], repeat: 3)[
  #v(1fr)
  #align(center + bottom)[
    #runtime.alternatives(start: 1)[
      #image(asset-path("diagrams/stack-stage-1.svg"), width: 760pt)
    ][
      #image(asset-path("diagrams/stack-stage-2.svg"), width: 760pt)
    ][
      #image(asset-path("diagrams/stack-stage-3.svg"), width: 760pt)
    ]
  ]
]

#slide(title: [Progressive Points in Stable Free Space], repeat: 3, self => [
  #body-flow(
    (
      region(points((
        point([Preserve storage ordering.]),
      ))),
      region(runtime.uncover("2-", self: self)[
        #points((
          point([Avoid unnecessary synchronization.]),
          point([Keep dependency-critical I/O explicit.], level: 2),
        ))
      ]),
      region(runtime.uncover("3-", self: self)[
        #block(width: 620pt)[
          #points((
            point([Require no application changes while preserving existing deployment interfaces.]),
          ))
        ]
      ]),
    ),
    rows: (auto, auto, auto),
    gutter: 3fr,
    outer-gutter: 2fr,
    // Inset is fixed safety space; outer/internal gutters share the remainder.
    inset: (top: 12pt, bottom: 12pt),
  )
])
