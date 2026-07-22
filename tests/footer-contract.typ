// Footer geometry fixture: the symmetric white rectangle exposes the visible
// center of the complete logo slot without depending on a branded SVG viewBox.

#import "../lib.typ": slide, systems-slides-theme

#show: systems-slides-theme.with(
  title: [FOOTER CONTRACT TITLE],
  author: [Theme Contract],
  date: datetime(year: 2031, month: 3, day: 14),
  footer-logo: rect(width: 40pt, height: 20pt, fill: white),
  footer-logo-width: 40pt,
  footer-date-format: "[year]-[month repr:numerical padding:zero]-[day padding:zero]",
  section-progress: false,
  section-slides: false,
)

#slide(title: [Footer Geometry Contract])[Footer geometry contract fixture.]
