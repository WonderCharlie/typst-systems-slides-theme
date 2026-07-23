// Roadmap and section-progress contract.
//
// The first three pages exercise the consumer-facing Roadmap modes. The
// section progress dots remain derived from outlined level-one headings.

#import "../lib.typ": lead, outline-slide, systems-slides-theme, title-slide

#show: systems-slides-theme.with(
  title: [NAVIGATION TITLE],
  short-title: [Navigation],
  author: [Theme Contract],
  date: datetime(year: 2033, month: 5, day: 6),
  footer-title: [NAVIGATION-FOOTER],
  section-progress: true,
  section-slides: false,
)

#title-slide(counted: true)
#let chapters = (
  [Problem],
  [Observation],
  [Design],
  [Implementation],
  [Evaluation],
  [Conclusion],
)

#outline-slide(title: [Default Roadmap], chapters: chapters)
#outline-slide(title: [Current Roadmap], chapters: chapters, current: 3)
#outline-slide(
  title: [Numbered Roadmap],
  chapters: chapters,
  current: 5,
  numbering: "1.",
  size: 28pt,
  weight: 500,
  spacing: 18pt,
  current-style: (fill: rgb("16835d"), weight: 700),
)
#outline-slide(title: [Fixed Roadmap], chapters: chapters, auto-layout: false)
#outline-slide(
  title: [Manual Outer Spacing],
  chapters: chapters,
  top-spacing: 20pt,
  bottom-spacing: 42pt,
)

= Alpha Section

== Alpha slide

#lead([NAVIGATION_ALPHA])

= Beta Section

== Beta slide

#lead([NAVIGATION_BETA])

= Gamma Section

== Gamma slide

#lead([NAVIGATION_GAMMA])

#context {
  let sections = query(heading.where(level: 1, outlined: true))
  assert(
    sections.len() == 3,
    message: "the navigation fixture must expose exactly three automatic sections",
  )
  []
}
