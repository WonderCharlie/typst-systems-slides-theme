// Optional section-divider and uncounted-title lifecycle contract.

#import "../lib.typ": systems-slides-theme, title-slide

#show: systems-slides-theme.with(
  title: [SECTION LIFECYCLE],
  author: [Theme Contract],
  date: datetime(year: 2035, month: 7, day: 8),
  section-progress: true,
  section-slides: true,
)

#title-slide(counted: false)

= Alpha Section

== Alpha content

ALPHA_CONTENT_BODY

= Beta Section

== Beta content

BETA_CONTENT_BODY
