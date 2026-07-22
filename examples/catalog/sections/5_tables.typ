// Purpose: specify professional defaults and stable presentation patterns for native Typst tables.
// Public API: slide, column-split, region, runtime; table and figure stay native Typst.
// Defaults: 18pt cell text, header fill/weight, insets, rules, caption type and spacing.
// Stable regions: progressive results retain table bounds, rows, columns, caption, and existing cells.
#import "@local/systems-slides-template:0.6.1": (
  callout,
  column-split,
  region,
  runtime,
  slide,
  typography,
)
#import "../globals.typ": asset-path

#slide(title: [Experimental Configuration])[
  #align(center)[
    #figure(
      kind: table,
      caption: [Experimental configuration],
      numbering: "1",
      table(
        columns: (1.5fr, 1fr, 1fr),
        align: (left, right, right),
        table.header([Configuration], [Baseline], [Relay]),
        [Nodes], [32], [32],
        [Storage targets], [8], [8],
        [Network (Gb/s)], [100], [100],
        [Queue depth], [64], [64],
        [Dependency tracking], [—], [Enabled],
      ),
    ) <experimental-configuration>
  ]
  #v(16pt)
  Configuration @experimental-configuration uses only native data, columns, and semantic alignment.
]

#slide(title: [Progressive Results Table], repeat: 3)[
  #align(center)[
    #figure(
      kind: table,
      caption: [Synthetic evaluation results],
      numbering: "1",
      table(
        columns: (1.6fr, 1fr, 1fr),
        rows: (auto, 48pt, 48pt, 48pt),
        align: (left, right, right),
        table.header([Metric], [Baseline], [Relay]),
        [P99 latency (ms)], [12.4], runtime.uncover("2-")[8.6],
        [Throughput (Mops/s)], [1.00], runtime.uncover("2-")[1.42],
        [CPU overhead (%)], [—], runtime.uncover("2-")[2.8],
      ),
    ) <synthetic-results>
  ]
  #v(22pt)
  #runtime.uncover(3)[
    #callout(
      [Relay lowers synthetic P99 latency while keeping host overhead below 3%.],
      title: [Best result],
      tone: typography.tone-green,
    )
  ]
]

#slide(title: [Chart and Exact Values])[
  #column-split(
    (
      region(image(asset-path("charts/p99-latency.svg"), width: 100%), align: center + horizon),
      region([
        #table(
          columns: (1.4fr, 1fr, 1fr),
          align: (left, right, right),
          table.header([Queue], [Base], [Relay]),
          [16], [6.8], [5.7],
          [32], [9.1], [6.7],
          [64], [12.4], [8.6],
        )
        #v(20pt)
        #callout([The same color semantics and synthetic values are used by both views.], title: [Takeaway])
      ], align: center + horizon),
    ), columns: (1.25fr, 0.75fr), gutter: 28pt, height: 300pt,
  )
]

#slide(title: [Curating Wide Tables])[
  #column-split(
    (
      region([
        #text(size: 20pt, weight: "semibold", fill: typography.tone-primary)[BODY PAGE]
        #v(14pt)
        #table(
          columns: (1.5fr, 1fr, 1fr, 1fr),
          align: (left, right, right, right),
          table.header([Workload], [P50], [P99], [CPU]),
          [Search], [3.1], [8.6], [2.8%],
          [Graph], [4.4], [10.2], [2.5%],
          [Analytics], [5.2], [11.8], [2.9%],
        )
      ]),
      region([
        #text(size: 20pt, weight: "semibold", fill: typography.tone-primary)[AUTHORING DECISION]
        #v(16pt)
        - Keep only columns needed for the claim.
        - Group secondary metrics on another page.
        - Move the complete table to Appendix.
        - Never solve width by reducing body text below 18pt.
      ]),
    ), columns: (1.2fr, 0.8fr), gutter: 30pt, height: 290pt,
  )
]
