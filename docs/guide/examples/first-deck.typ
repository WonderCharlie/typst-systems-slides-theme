#import "@local/systems-slides-template:0.4.0": (
  lead,
  outline-slide,
  point,
  points,
  slide,
  systems-slides-theme,
  title-slide,
)

#let asset-path(relative) = {
  assert(type(relative) == str and relative != "")
  assert(not relative.starts-with("/") and not relative.contains(".."))
  path("assets/" + relative)
}

#show: systems-slides-theme.with(
  title: [Relay: Scheduling Dependent I/O],
  author: [A. Researcher],
  institution: [Example Systems Lab],
  date: datetime.today(),
  section-progress: true,
)

#title-slide(subtitle: [A five-page executable guide example], counted: false)
#outline-slide(title: [Roadmap], level: 1)

= Problem

#slide(title: [Remote I/O Exposes the Dependency Chain])[
  #lead[Explain the constraint before introducing the mechanism.]
  #points((
    point([Dependent computation waits for remote data.]),
    point([Independent work can overlap the transfer.], level: 2),
  ))
]

= Evidence

#slide(title: [The Scheduler Separates Ready and Blocked Work])[
  #figure(
    image(asset-path("architecture.svg"), fit: "contain"),
    caption: [Synthetic scheduling architecture],
  ) <guide-architecture>
]

= Result

#slide(title: [Dependency Awareness Reduces Visible Latency])[
  The architecture in @guide-architecture moves independent work off the visible path.

  #points((
    point([Preserve storage ordering.]),
    point([Avoid unnecessary synchronization.]),
    point([Require no application changes.]),
  ))
]
