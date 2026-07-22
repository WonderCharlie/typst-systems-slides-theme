// Special-slide config resolution contract.
//
// Per-slide Touying config must be merged before title metadata and asset-store
// values are read by a content-neutral page layer.

#import "../lib.typ": page-frame, page-layer, slide, systems-slides-theme, title-slide
#import "@preview/touying:0.7.4": config-info, config-store

#show: systems-slides-theme.with(
  title: [GLOBAL TITLE MUST NOT WIN],
  author: [GLOBAL AUTHOR MUST NOT WIN],
  date: datetime(year: 2034, month: 6, day: 7),
)

#title-slide(
  config: config-info(
    title: [LOCAL TITLE WINS],
    author: [LOCAL AUTHOR WINS],
  ),
)

#let resolver-frame = page-frame(
  name: "per-slide resolver frame",
  background: page-layer(state => {
    let resolver = state.store.at("asset-resolver", default: name => name)
    resolver("virtual-artifact")
  }),
)

#slide(
  config: config-store(
    asset-resolver: name => text(size: 8pt, [RESOLVED ARTIFACT]),
  ),
  title: [Per-slide resolver],
  frame: resolver-frame,
)[SPECIAL CONFIG BODY]
