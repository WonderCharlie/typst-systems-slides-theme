// Content-neutral page-frame inheritance and Touying lifecycle contract.

#import "../lib.typ": page-frame, page-layer, runtime, slide, systems-slides-theme

#let base-frame = page-frame(
  name: "base",
  background: page-layer(
    state => text(size: 9pt, fill: rgb("6b7280"), [FRAME_BACKGROUND #(state.info.title)]),
    name: "background",
    align: left + top,
    inset: 8pt,
  ),
  foreground: page-layer(
    [FRAME_FOREGROUND],
    name: "foreground",
    area: "body",
    align: right + bottom,
    inset: 18pt,
  ),
  chrome: false,
  section-progress: false,
  margin: (left: 50pt, right: 50pt, top: 94pt, bottom: 48pt),
  fill: rgb("fbfbfe"),
  width: 960pt,
  height: 540pt,
  header-ascent: 0pt,
  footer-descent: 0pt,
  clip: false,
  detect-overflow: true,
)

#let layered-frame = page-frame(
  base: base-frame,
  name: "layered",
  overlay: page-layer(
    [FRAME_OVERLAY],
    name: "overlay",
    align: center + horizon,
  ),
  chrome: true,
  header: state => text(size: 20pt, weight: "bold", fill: state.colors.primary, [FRAME_HEADER]),
  footer: auto,
)

#let chrome-free-frame = page-frame(
  base: base-frame,
  name: "chrome-free",
  background: none,
  overlay: none,
  foreground: none,
  chrome: false,
  margin: (x: 64pt, y: 64pt),
)

#assert(layered-frame.width == 960pt)
#assert(layered-frame.height == 540pt)
#assert(layered-frame.chrome == true)
#assert(layered-frame.section-progress == false)
#assert(layered-frame.overlay.area == "page")
#assert(layered-frame.foreground.area == "body")
#assert(layered-frame.detect-overflow == true)
#assert(chrome-free-frame.chrome == false)
#assert(chrome-free-frame.background == none)

#show: systems-slides-theme.with(
  title: [PAGE FRAME CONTRACT],
  author: [Lifecycle Contract],
  date: datetime(year: 2037, month: 9, day: 10),
  footer-title: [PAGE-FRAME-FOOTER],
  section-progress: false,
  section-slides: false,
)

#slide(
  title: [TITLE_MUST_BE_REPLACED_BY_FRAME_HEADER],
  frame: layered-frame,
  counted: false,
)[
  FRAME_BODY_FIRST

  #runtime.pause

  FRAME_BODY_SECOND
]
#runtime.speaker-note[FRAME_ATTACHED_NOTE]

#slide(
  title: [CHROME_MUST_BE_HIDDEN],
  frame: chrome-free-frame,
  counted: true,
)[
  CHROME_FREE_BODY

  #runtime.uncover("1-")[TOUYING_UNCOVER_REMAINS_NATIVE]
]

#slide(title: [DEFAULT_FRAME_INHERITS_THEME])[
  DEFAULT_FRAME_BODY
]
