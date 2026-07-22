// Contract fixture for the flat-level `points` component.
//
// Compile-time measurements guard spacing semantics; visible examples make
// typography, inheritance, hierarchy, and marker independence easy to inspect.

#import "../lib.typ": (
  point,
  points,
  systems-slides-theme,
  typography,
)

#show: systems-slides-theme.with(
  title: [Points Contract],
  author: [Template QA],
)

#let rhythm-items = (
  point([Root A owns its complete subtree.]),
  point([Child A1], level: 2),
  point([Child A2], level: 2),
  point([Root B follows the last visible child.]),
)

#let measured-points(..args) = measure(
  block(width: 760pt, points(rhythm-items, style: (size: 18pt), ..args)),
).height

#let deep-return-items = (
  point([Root]),
  point([Level two], level: 2),
  point([Level three], level: 3),
  point([Level four], level: 4),
  point([Return directly to level two], level: 2),
  point([Return to level one]),
)

#let measured-deep-return(..args) = measure(
  block(width: 760pt, points(deep-return-items, style: (size: 18pt), ..args)),
).height

== Flat-Level Spacing Contract

#context {
  let tolerance = 0.01pt
  let all-zero = measured-points(level-gaps: (0pt, 0pt), nest-gap: 0pt)
  let root-zero = measured-points(level-gaps: (0pt, 7pt), nest-gap: 13pt)
  let root-sentinel = measured-points(level-gaps: (31pt, 7pt), nest-gap: 13pt)
  assert(
    calc.abs((root-sentinel - root-zero) - 31pt) < tolerance,
    message: "root sibling gap must be applied exactly once after the descendant span",
  )

  let child-zero = measured-points(level-gaps: (31pt, 0pt), nest-gap: 13pt)
  let child-sentinel = measured-points(level-gaps: (31pt, 7pt), nest-gap: 13pt)
  assert(
    calc.abs((child-sentinel - child-zero) - 7pt) < tolerance,
    message: "child sibling gap must be applied exactly once",
  )

  let nest-zero = measured-points(level-gaps: (31pt, 7pt), nest-gap: 0pt)
  let nest-sentinel = measured-points(level-gaps: (31pt, 7pt), nest-gap: 13pt)
  assert(
    calc.abs((nest-sentinel - nest-zero) - 13pt) < tolerance,
    message: "nest gap must be applied exactly once",
  )
  assert(
    calc.abs((nest-sentinel - all-zero) - 51pt) < tolerance,
    message: "sibling and nesting gaps must not stack at one boundary",
  )

  let explicit-child-gap = measured-points(
    gap: 5pt,
    level-gaps: (31pt, 5pt),
    nest-gap: 13pt,
  )
  let fallback-child-gap = measured-points(
    gap: 5pt,
    level-gaps: (31pt,),
    nest-gap: 13pt,
  )
  assert(
    calc.abs(explicit-child-gap - fallback-child-gap) < tolerance,
    message: "missing level-gaps entries must fall back to gap",
  )
  let auto-child-gap = measured-points(
    gap: 5pt,
    level-gaps: (31pt, auto),
    nest-gap: 13pt,
  )
  assert(
    calc.abs(explicit-child-gap - auto-child-gap) < tolerance,
    message: "auto level-gaps entries must fall back to gap",
  )

  let deep-zero = measured-deep-return(
    level-gaps: (0pt, 0pt, 0pt, 0pt),
    nest-gap: 0pt,
  )
  let deep-level-two = measured-deep-return(
    level-gaps: (0pt, 17pt, 0pt, 0pt),
    nest-gap: 0pt,
  )
  assert(
    calc.abs((deep-level-two - deep-zero) - 17pt) < tolerance,
    message: "a deep return must use the target level's sibling gap exactly once",
  )
  let deep-level-one = measured-deep-return(
    level-gaps: (19pt, 0pt, 0pt, 0pt),
    nest-gap: 0pt,
  )
  assert(
    calc.abs((deep-level-one - deep-zero) - 19pt) < tolerance,
    message: "returning to level one must use the level-one sibling gap exactly once",
  )
  let deep-nesting = measured-deep-return(
    level-gaps: (0pt, 0pt, 0pt, 0pt),
    nest-gap: 11pt,
  )
  assert(
    calc.abs((deep-nesting - deep-zero) - 33pt) < tolerance,
    message: "nest-gap must apply once for each one-level descent and never on returns",
  )
}

#points(
  rhythm-items,
  gap: 18pt,
  level-gaps: (31pt, 7pt),
  nest-gap: 13pt,
  style: (size: 20pt),
)

== Multiline Content and Style Priority

#let multiline-items = (
  point([First line\ Second line with #text(weight: "bold")[inline emphasis].]),
  point([The sibling begins only after the complete multiline row.]),
)

#context {
  let tolerance = 0.01pt
  let one-zero = measure(block(
    width: 760pt,
    points((multiline-items.first(),), gap: 0pt),
  )).height
  let one-large = measure(block(
    width: 760pt,
    points((multiline-items.first(),), gap: 37pt),
  )).height
  assert(
    calc.abs(one-large - one-zero) < tolerance,
    message: "gap must not change a single multiline item",
  )

  let two-zero = measure(block(width: 760pt, points(multiline-items, gap: 0pt))).height
  let two-large = measure(block(width: 760pt, points(multiline-items, gap: 37pt))).height
  assert(
    calc.abs((two-large - two-zero) - 37pt) < tolerance,
    message: "one sibling boundary must contribute one gap",
  )
}

#grid(
  columns: (1fr, 1fr),
  column-gutter: 34pt,
  [
    #set text(fill: rgb("596275"), size: 17pt)
    #block(below: 8pt, text(size: 18pt, weight: "bold", fill: typography.tone-primary)[Template default style])
    #points((
      point(
        [The Theme default supplies color, size, and regular weight;#linebreak()item-local inline emphasis can still override it.],
      ),
    ))
  ],
  [
    #set text(fill: rgb("596275"), size: 17pt)
    #block(below: 8pt, text(size: 18pt, weight: "bold", fill: typography.tone-primary)[Priority chain])
    #points(
      (
        point(
          [Item red; #text(fill: rgb("178c4a"))[inline green wins].],
          style: (fill: rgb("c0392b"), size: 22pt),
        ),
        point([Level-two purple overrides interface blue.], level: 2),
        point([Interface blue overrides external grey.], level: 3),
      ),
      gap: 8pt,
      nest-gap: 7pt,
      style: (fill: rgb("2367c9"), size: 18pt),
      level-styles: (
        (weight: "medium"),
        (fill: rgb("7f3fbf"), size: 20pt),
      ),
    )
  ],
)

== Marker and Text Styles Are Independent

#points(
  (
    point([Level one uses the default marker.]),
    point([Level two uses its level marker and style.], level: 2),
    point(
      [Level three overrides only this marker.],
      level: 3,
      marker: [◆],
      marker-style: (fill: rgb("d35400"), size: 19pt),
    ),
    point([Level four verifies the supported maximum depth.], level: 4),
  ),
  gap: 10pt,
  nest-gap: 8pt,
  style: (color: rgb("333333"), size: 20pt),
  level-styles: (
    (weight: "bold"),
    (size: 19pt),
    (size: 18pt),
    (size: 17pt),
  ),
  marker: [●],
  level-markers: ([●], [○], [◇], [▪]),
  marker-style: (fill: rgb("2367c9"), size: 17pt),
  level-marker-styles: (
    (fill: rgb("2367c9")),
    (fill: rgb("7f3fbf")),
    (fill: rgb("2367c9")),
    (fill: rgb("596275")),
  ),
)

== Default Four-Level Optical Alignment

// No marker or typography overrides: this is the visual acceptance fixture
// for the template defaults used by a plain flat-level `points(...)` call.
#block(
  width: 760pt,
  points((
    point([Default level one marker centers on the first line.]),
    point([Default level two marker centers on the first line.], level: 2),
    point([Default level three marker centers on the first line.], level: 3),
    point([Default level four marker centers on the first line.], level: 4),
  )),
)
