#import "@preview/touying:0.7.4": config-store
#import "../lib.typ": page-mark, slide, systems-slides-theme

#show: systems-slides-theme.with(
  title: [Page Mark Stability Fixture],
  author: [Theme validation],
  date: datetime(year: 2026, month: 7, day: 22),
  section-progress: false,
  section-slides: false,
)

#slide(title: [Identical Fixture Title])[Reference body]

#slide(
  title: [Identical Fixture Title],
  marks: (page-mark([MARK], height: 24pt),),
)[Reference body]

= Fixture Section

#slide(
  title: [Identical Fixture Title],
  config: config-store(section-progress: true),
)[Reference body]

#slide(
  title: [Identical Fixture Title],
  marks: (page-mark([MARK], height: 24pt),),
  config: config-store(section-progress: true),
)[Reference body]
