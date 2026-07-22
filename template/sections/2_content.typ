// 两张内容页只展示最常用的自然流、Points 和原生 figure。
#import "../globals.typ": asset-path, point, points, runtime, slide

= Problem framing

#slide(title: [Frame the Problem Before the Mechanism])[
  State the system constraint, then make its consequence explicit.

  #points((
    point([The critical path includes communication.]),
    point([Latency determines when dependent work may start.], level: 2),
    point([Bandwidth determines how quickly an exposed transfer completes.], level: 2),
  ))
]
#runtime.speaker-note[Connect the system constraint to the metric the audience should watch.]

= Native media

#slide(title: [Use Native Images and Figures])[
  #figure(
    image(asset-path("example-mark.svg"), height: 185pt),
    caption: [A deck-owned SVG rendered through Typst's native figure.],
    numbering: "1",
  ) <starter-figure>

  Figure @starter-figure keeps Typst's native numbering and reference semantics.
]
#runtime.speaker-note[Replace the sample SVG and caption with evidence from the presentation.]
