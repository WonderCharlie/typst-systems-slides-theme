// Purpose: verify constrained titles, chrome-free pages, and regular evidence matrices.
// Public API: slide, page-frame, page-mark, column-split, row-split, region.
// Defaults: title fitting stays on one line and never drops below 30pt; image ratio and Footer remain Theme-owned.
// Stable regions: title/body boundaries and the four matrix cells use deterministic tracks.
#import "@local/systems-slides-template:0.6.1": (
  column-split,
  lead,
  page-frame,
  page-mark,
  point,
  points,
  region,
  row-split,
  slide,
  typography,
)
#import "../globals.typ": asset-path

#slide(
  title: [Dependency-Aware Scheduling Preserves Ordering],
)[
  #lead([Across compute and remote storage boundaries, ordering remains explicit while the title stays within its single-line slot.])
  #v(28pt)
  #points((
    point([The Theme shrinks long titles only as far as 30pt.]),
    point([Details that do not fit belong in lead or body content.]),
    point([Chapter progress keeps its own title-area slot.]),
  ))
]

#slide(
  title: none,
  frame: page-frame(name: "titleless canvas", chrome: false, margin: 32pt, fill: typography.tone-faint-grey),
)[
  #row-split(
    (
      region([#text(size: 38pt, weight: "bold", fill: typography.tone-primary)[Titleless technical canvas]]),
      region(column-split(
        (
          region(image(asset-path("diagrams/architecture.svg"), width: 100%), align: center + horizon),
          region([
            #lead([Use a chrome-free surface only when the whole page is the composition.])
            #v(20pt)
            Ordinary text, figures, and native layout remain available; the Theme changes the page surface, not the content model.
          ], align: left + horizon),
        ), columns: (1.15fr, 0.85fr), gutter: 30pt, height: 100%,
      )),
    ), rows: (auto, 1fr), gutter: 22pt, height: 430pt,
  )
]

#slide(title: [2×2 Evidence Matrix])[
  #row-split(
    (
      region(column-split(
        (
          region([#strong[Request path]#v(8pt)#align(center)[#image(asset-path("diagrams/end-to-end-path.svg"), width: 100%)]#v(8pt)#text(size: 20pt)[Critical I/O is explicit.]]),
          region([#strong[Deployment]#v(8pt)#align(center)[#image(asset-path("diagrams/deployment-topology.svg"), height: 115pt)]#v(8pt)#text(size: 20pt)[No device modification is required.]]),
        ), columns: (1fr, 1fr), gutter: 22pt, height: 100%,
      )),
      region(column-split(
        (
          region([#strong[Tail latency]#v(8pt)#align(center)[#image(asset-path("charts/p99-latency.svg"), height: 120pt)]#v(8pt)#text(size: 20pt)[Relay improves the high-load regime.]]),
          region([#strong[Storage foundation]#v(8pt)#align(center)[#image(asset-path("diagrams/stack-stage-3.svg"), height: 120pt)]#v(8pt)#text(size: 20pt)[Existing lower layers remain unchanged.]]),
        ), columns: (1fr, 1fr), gutter: 22pt, height: 100%,
      )),
    ), rows: (1fr, 1fr), gutter: 18pt, height: 320pt,
  )
]
