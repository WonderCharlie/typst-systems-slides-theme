// Purpose: compare alternatives and reveal process evidence without moving established geometry.
// Public API: slide, runtime.alternatives, runtime.uncover, column-split, region.
// Defaults: Theme typography and colors; fixed tracks are specified only where cross-state stability matters.
// Stable regions: comparison columns, pipeline tracks, and the timeline axis remain invariant.
#import "@local/systems-slides-template:0.6.2": (
  callout,
  column-split,
  region,
  runtime,
  slide,
  typography,
)
#import "../globals.typ": asset-path

#slide(title: [Stable Before/After Comparison], repeat: 3)[
  #runtime.alternatives(start: 1)[
    #column-split(
      (
        region([
          #text(size: 20pt, weight: "semibold")[Baseline]
          #v(12pt)
          #image(asset-path("diagrams/baseline-timeline.svg"), width: 100%)
        ]),
        region(callout([Relay evidence appears in the second state without moving the baseline.], title: [Question]), align: center + horizon),
      ), columns: (1fr, 1fr), gutter: 30pt, height: 295pt,
    )
  ][
    #column-split(
      (
        region([
          #text(size: 20pt, weight: "semibold")[Baseline]
          #v(12pt)
          #image(asset-path("diagrams/baseline-timeline.svg"), width: 100%)
        ]),
        region([
          #text(size: 20pt, weight: "semibold", fill: typography.tone-primary)[Relay]
          #v(12pt)
          #image(asset-path("diagrams/relay-timeline.svg"), width: 100%)
        ]),
      ), columns: (1fr, 1fr), gutter: 30pt, height: 295pt,
    )
  ][
    #column-split(
      (
        region([
          #text(size: 20pt, weight: "semibold")[Baseline]
          #v(12pt)
          #image(asset-path("diagrams/baseline-timeline.svg"), width: 100%)
          #v(16pt)
          #text(size: 20pt, weight: "semibold", fill: typography.tone-danger)[visible idle time]
        ]),
        region([
          #text(size: 20pt, weight: "semibold", fill: typography.tone-primary)[Relay]
          #v(12pt)
          #image(asset-path("diagrams/relay-timeline.svg"), width: 100%)
          #v(16pt)
          #text(size: 20pt, weight: "semibold", fill: typography.tone-green)[network delay overlaps compute]
        ]),
      ), columns: (1fr, 1fr), gutter: 30pt, height: 295pt,
    )
  ]
]

#slide(title: [Fixed-Track Pipeline], repeat: 3)[
  #runtime.alternatives(start: 1)[
    #grid(
      columns: (1fr, 24pt, 1fr, 24pt, 1fr, 24pt, 1fr, 24pt, 1fr), gutter: 5pt,
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Receive]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Trace]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-faint-grey, align(center + horizon)[Prefetch]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-faint-grey, align(center + horizon)[Execute]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-faint-grey, align(center + horizon)[Commit]),
    )
    #v(45pt)
    #callout([Trace the request before scheduling dependent operations.], title: [State 1])
  ][
    #grid(
      columns: (1fr, 24pt, 1fr, 24pt, 1fr, 24pt, 1fr, 24pt, 1fr), gutter: 5pt,
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Receive]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Trace]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Prefetch]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Execute]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-faint-grey, align(center + horizon)[Commit]),
    )
    #v(45pt)
    #callout([Prefetch critical I/O while independent work stays executable.], title: [State 2])
  ][
    #grid(
      columns: (1fr, 24pt, 1fr, 24pt, 1fr, 24pt, 1fr, 24pt, 1fr), gutter: 5pt,
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Receive]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Trace]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Prefetch]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Execute]]), [→],
      block(height: 90pt, inset: 8pt, radius: 6pt, fill: typography.tone-primary.transparentize(88%), align(center + horizon)[#strong[Commit]]),
    )
    #v(45pt)
    #callout([Only dependency-critical I/O remains on the visible path.], title: [Complete pipeline], tone: typography.tone-green)
  ]
]

#slide(title: [Stable Timeline], repeat: 2)[
  #grid(
    columns: (1fr, 1fr, 1fr, 1fr), rows: (54pt, 8pt, 94pt), gutter: 0pt,
    align(center + bottom)[Request], align(center + bottom)[Trace],
    runtime.uncover(2)[#align(center + bottom)[Prefetch]],
    runtime.uncover(2)[#align(center + bottom)[Commit]],
    line(length: 100%, stroke: 3pt + typography.tone-primary),
    line(length: 100%, stroke: 3pt + typography.tone-primary),
    line(length: 100%, stroke: 3pt + typography.tone-primary),
    line(length: 100%, stroke: 3pt + typography.tone-primary),
    align(center + top)[0 ms], align(center + top)[2 ms], align(center + top)[5 ms], align(center + top)[8 ms],
  )
  #v(38pt)
  #callout([The four tracks and axis are allocated from the first state; only event content is uncovered.], title: [Stable time geometry])
]
