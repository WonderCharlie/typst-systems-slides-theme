// Automatic outline and section-progress contract.
//
// There is no hand-maintained section array in this fixture. Both the roadmap
// and the three progress dots must be derived from outlined level-one headings.

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
#outline-slide(title: [Automatic Roadmap], level: 1)

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
