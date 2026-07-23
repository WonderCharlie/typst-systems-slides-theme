// Purpose: exercise code, formulas, citations, and compact metrics with native Typst semantics.
// Public API: slide, column-split, region, callout, typography.
// Defaults: Theme-owned Source Code Pro, native math, body type, colors, and spacing.
// Stable regions: code and formula canvases keep fixed geometry while explanations remain adjacent.
#import "@local/systems-slides-template:0.6.2": (
  callout,
  column-split,
  region,
  slide,
  typography,
)
#import "../globals.typ": asset-path

#slide(title: [Pseudocode with Explanation])[
  #column-split(
    (
      region([
        #raw(
          "01  schedule(request):\n02    deps = trace(request)\n03    for io in deps.blocking:\n04      prefetch(io)\n05    while deps.pending:\n06      run_ready_work()\n07    commit_in_order(request)",
          block: true,
          lang: "text",
        )
      ], align: left + horizon),
      region([
        #callout([Lines 2–4 expose dependency-critical I/O before independent computation begins.], title: [Critical step])
        #v(18pt)
        Code stays at 16pt or larger, contains fewer than 15 lines, and never depends on Monaco or Menlo.
      ], align: left + horizon),
    ), columns: (1.15fr, 0.85fr), gutter: 30pt, height: 280pt,
  )
]

#slide(title: [Formula, Symbols, and Conclusion])[
  #align(center)[
    #figure(
      kind: math.equation,
      numbering: "(1)",
      caption: [Visible request latency],
      $L_"request" = L_"critical" + max(0, C_"ready" - L_"hidden") + L_"commit"$,
    ) <visible-latency>
  ]
  #v(20pt)
  #column-split(
    (
      region([
        $L_"critical"$: dependency-critical I/O latency
        #linebreak()
        $C_"ready"$: independent computation available to overlap
      ]),
      region(callout([@visible-latency isolates the delay that scheduling can actually hide.], title: [Conclusion])),
    ), columns: (1fr, 1fr), gutter: 28pt,
  )
]

#slide(title: [Quotes, Footnotes, and Sources])[
  #column-split(
    (
      region([
        #quote(block: true)[
          Dependency-aware scheduling should expose only storage operations that prevent forward progress.
        ]
        #v(18pt)
        A formal source uses native citation syntax @relay-design-note. A longer qualification belongs in a footnote#footnote[All measurements and citations in this Catalog are synthetic and exist only to exercise presentation semantics.#v(16pt)].
      ], align: left + top, overflow: "error"),
      region([
        #callout(
          [Use direct links for artifacts, native footnotes for qualifications, and a bibliography for formal publication metadata.],
          title: [Source hierarchy],
        )
        #v(22pt)
        #bibliography(asset-path("references.bib"), title: none, style: "ieee")
      ], align: left + top, overflow: "error"),
    ),
    columns: (1fr, 1fr),
    gutter: 28pt,
    height: 300pt,
  )
]

#slide(title: [Metrics Dashboard])[
  #grid(
    columns: (1fr, 1fr, 1fr), gutter: 22pt,
    block(height: 155pt, inset: 18pt, radius: 8pt, fill: typography.tone-primary.transparentize(91%))[
      #text(size: 40pt, weight: "bold", fill: typography.tone-primary)[31%]
      #v(8pt)
      Lower synthetic P99 latency
    ],
    block(height: 155pt, inset: 18pt, radius: 8pt, fill: typography.tone-blue.transparentize(91%))[
      #text(size: 40pt, weight: "bold", fill: typography.tone-blue)[1.42×]
      #v(8pt)
      Higher synthetic throughput
    ],
    block(height: 155pt, inset: 18pt, radius: 8pt, fill: typography.tone-green.transparentize(91%))[
      #text(size: 40pt, weight: "bold", fill: typography.tone-green)[2.8%]
      #v(8pt)
      Host CPU overhead
    ],
  )
  #v(32pt)
  #callout([Relay hides remote-I/O delay without trading it for excessive host work.], title: [Interpretation])
]
