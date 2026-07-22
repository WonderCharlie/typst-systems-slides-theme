#import "../lib.typ": page-mark, slide, systems-slides-theme

#let case = sys.inputs.at("case", default: "valid")

#show: systems-slides-theme.with(
  title: [Title Contract Fixture],
  author: [Theme validation],
  date: datetime(year: 2026, month: 7, day: 22),
  section-progress: false,
  section-slides: false,
)

#if case == "valid" {
  slide(title: [A Valid Single-Line Title])[Reference body]
} else if case == "too-long" {
  slide(title: [This deliberately excessive systems-slides-template slide title cannot fit inside the title band even at the documented thirty point minimum size])[Reference body]
} else if case == "explicit-break" {
  slide(title: [Explicit line break #linebreak() is forbidden])[Reference body]
} else if case == "mark-capacity" {
  slide(
    title: [Dependency-Aware Scheduling Preserves Ordering],
    marks: (page-mark([AN INTENTIONALLY WIDE PAGE MARK], height: 24pt),),
  )[Reference body]
} else {
  panic("unknown title contract case")
}
