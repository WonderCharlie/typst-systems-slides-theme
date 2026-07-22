// Native Typst media/list contract under the systems-slides-template Theme.
// The Theme may provide presentation defaults, but must not replace native
// figure numbering, labels, references, or image intrinsic-size behavior.

#import "../lib.typ": systems-slides-theme

#show: systems-slides-theme.with(
  title: [Native Theme Contract],
  author: [Public API Test],
  date: datetime(year: 2032, month: 1, day: 2),
)

= Native contracts

== Native figure numbering and references

#figure(
  rect(width: 52pt, height: 24pt, fill: rgb("#d9d9d9")),
  supplement: [Figure],
  numbering: "1",
  caption: [Native caption remains referenceable],
) <native-figure>

Reference check: @native-figure.

- Native list item one
- Native list item two
