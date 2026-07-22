// Touying lifecycle contract.
//
// A counted title slide is page/slide 1. A level-two heading then creates the
// ordinary slide numbered 2. Explicit `slide` calls, alignment, and a
// chrome-free structural frame share the same counter.

#import "../lib.typ": lead, page-frame, page-mark, slide, systems-slides-theme, title-slide

#show: systems-slides-theme.with(
  title: [LIFECYCLE TITLE],
  short-title: [Lifecycle],
  author: [Theme Contract],
  date: datetime(year: 2032, month: 4, day: 5),
  footer-title: [LIFECYCLE-FOOTER],
  footer-date-format: "[month repr:numerical padding:zero]/[day padding:zero]/[year]",
  section-progress: false,
  section-slides: false,
)

#title-slide(counted: true)

= Lifecycle Section

== Heading-created normal slide

#lead([LIFECYCLE_PAGE_TWO])

The level-two heading supplies this slide's title through Touying's normal
heading lifecycle.

#slide(
  title: [Explicit normal slide],
  marks: (page-mark([LIFECYCLE_PAGE_MARK], height: 60pt, name: "lifecycle mark"),),
)[
  #lead([LIFECYCLE_PAGE_THREE])

  The public slide wrapper shares the same page master and counter lifecycle.
]

#slide(title: [Aligned normal slide], align: center)[
  ALIGNED_SLIDE_STABLE
]

#slide(
  title: none,
  align: center + horizon,
  frame: page-frame(name: "chrome-free lifecycle page", header: none),
)[FRAME_BODY_STABLE]
