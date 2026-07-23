// Purpose: demonstrate native media, captions, references, and evidence prioritization.
// Public API: slide, column-split, row-split, region, lead, points.
// Defaults: intrinsic images only shrink, figure captions use Theme type and spacing.
// Stable regions: every media cell has a finite boundary; no image is stretched.
#import "@local/systems-slides-template:0.6.2": (
  column-split,
  lead,
  point,
  points,
  region,
  slide,
  typography,
)
#import "../globals.typ": asset-path

#slide(title: [Native Image Ratios])[
  #column-split(
    (
      region([#align(center)[#image(asset-path("diagrams/architecture.svg"), width: 100%)]#align(center)[#text(size: 20pt)[wide architecture]]], align: center + horizon),
      region([#align(center)[#image(asset-path("photos/server-rack.svg"), height: 245pt)]#align(center)[#text(size: 20pt)[tall rack]]], align: center + horizon),
      region([#align(center)[#image(asset-path("diagrams/device-icon.svg"))]#align(center)[#text(size: 20pt)[intrinsic icon]]], align: center + horizon),
    ),
    columns: (1.5fr, 0.75fr, 0.75fr),
    gutter: 24pt,
    height: 305pt,
  )
]

#slide(title: [Caption Placement])[
  #column-split(
    (
      region([
        #figure(
          image(asset-path("diagrams/architecture.svg"), width: 330pt),
          caption: figure.caption(position: top, [Relay architecture]),
        )
      ], align: center + top),
      region([
        #figure(
          image(asset-path("charts/p99-latency.svg"), width: 330pt),
          caption: [P99 latency under increasing queue depth],
        )
      ], align: center + top),
      region([
        #figure(
          image(asset-path("diagrams/device-icon.svg")),
          caption: [Compact device evidence with a caption that wraps naturally onto multiple lines.],
        )
      ], align: center + top),
    ),
    columns: (1fr, 1fr, 0.7fr),
    gutter: 20pt,
    height: 320pt,
  )
]

#slide(title: [Native Figure References])[
  #lead([@relay-design remains a standard Typst reference, not a Theme-specific media object.])
  #v(22pt)
  #align(center)[
    #figure(
      image(asset-path("diagrams/architecture.svg"), width: 620pt),
      caption: [Dependency-aware scheduling separates critical I/O from overlappable work.],
      numbering: "1",
    ) <relay-design>
  ]
]

#slide(title: [Dominant Figure and Takeaway])[
  #align(center)[#image(asset-path("diagrams/end-to-end-path.svg"), width: 900pt)]
  #v(24pt)
  #lead([Only dependency-critical I/O remains on the visible request path.])
]

#slide(title: [Unequal Evidence Columns])[
  #column-split(
    (
      region([
        #points((
          point([Trace request dependencies before issuing storage work.]),
          point([Prefetch only the operations that block forward progress.]),
          point([Commit in the original persistence order.]),
        ), gap: 10pt)
      ], align: left + top, overflow: "error"),
      region(image(asset-path("diagrams/deployment-topology.svg"), width: 100%), align: center + horizon),
    ),
    columns: (1fr, 2fr),
    gutter: 30pt,
    height: 325pt,
  )
]
