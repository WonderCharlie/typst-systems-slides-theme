// Public-entry smoke test.
//
// This fixture intentionally imports only `lib.typ`. It must be possible to
// build a useful deck without knowing the theme's internal module layout.

#import "../lib.typ": (
  lead,
  point,
  points,
  systems-slides-theme,
  title-slide,
  typography,
)

#let contract-date = datetime(year: 2031, month: 3, day: 14)
#let contract-logo = rect(
  width: 58pt,
  height: 22pt,
  radius: 2pt,
  fill: typography.tone-white,
  inset: 2pt,
  align(
    center + horizon,
    text(size: 7.5pt, weight: "bold", fill: typography.tone-deep, [LIB-LOGO]),
  ),
)

#show: systems-slides-theme.with(
  title: [THEME API TITLE],
  short-title: [THEME API SHORT TITLE],
  author: [Public API Contract],
  date: contract-date,
  footer-logo: contract-logo,
  footer-date-format: "[year]-[month repr:numerical padding:zero]-[day padding:zero]",
  section-progress: false,
  section-slides: false,
)

#title-slide(counted: true)

= Public API

== Heading-created public slide

#lead([Every element on this page is imported through *lib.typ*.])

#link("https://example.com")[NATIVE LINK REMAINS AVAILABLE]

#points((
  point([The public entry exports the independent list semantics.]),
  point(
    [Nested content remains normal Typst content with #text(fill: typography.tone-primary, weight: "bold")[inline emphasis].],
    level: 2,
  ),
  point([The footer below exercises document-title fallback, date, logo, and slide-number overrides.]),
))
