// Shared header, footer, and section-progress chrome.

#import "@preview/touying:0.7.4": utils
#import "tokens.typ": (
  deep-purple,
  font-sans,
  grey,
  purple,
  white,
)
#import "geometry.typ": systems-layout
#import "marks.typ": render-page-marks
#import "../../src/media.typ": render-media

#let default-footer-date-format = "[month repr:numerical padding:zero]/[day padding:zero]/[year repr:last_two]"

#let resolved-footer-title(self) = {
  let explicit = self.store.at("footer-title", default: auto)
  if explicit != auto {
    explicit
  } else {
    // The footer follows the document title by contract. `short-title` remains
    // metadata for callers that need it, but never silently changes the master.
    self.info.title
  }
}

#let resolved-date(self) = {
  if type(self.info.date) == datetime {
    self.info.date.display(self.store.at(
      "footer-date-format",
      default: default-footer-date-format,
    ))
  } else {
    self.info.date
  }
}

// A query-driven section indicator. Level-one outlined headings are the sole
// source of truth: adding, removing, or reordering a section updates both the
// number of dots and the current solid prefix at compile time.
#let section-progress-dots(
  self,
  radius: 3.2pt,
  gap: 7pt,
  active: auto,
  inactive: auto,
  stroke-width: 1pt,
) = context {
  let active-color = if active == auto { self.colors.primary } else { active }
  let inactive-color = if inactive == auto { active-color } else { inactive }
  let current-page = here().page()
  let sections = query(heading).filter(it => (
    it.level == 1 and it.outlined != false
  ))

  if sections.len() > 0 {
    stack(
      dir: ltr,
      spacing: gap,
      ..sections.map(section => {
        let reached = section.location().page() <= current-page
        link(
          section.location(),
          circle(
            radius: radius,
            fill: if reached { active-color } else { none },
            stroke: stroke-width + if reached { active-color } else { inactive-color },
          ),
        )
      }),
    )
  }
}

#let master-header(
  self,
  title: auto,
) = {
  let title-content = if title == auto {
    utils.display-current-heading(level: self.slide-level)
  } else {
    utils.call-or-display(self, title)
  }
  let title-rendered = layout(size => {
    let render-at(font-size) = box(
      text(
        font: font-sans,
        size: font-size,
        weight: "bold",
        fill: self.store.at("title-color", default: purple),
        title-content,
      ),
    )
    let regular = render-at(systems-layout.title.size)
    let regular-size = measure(regular)
    assert(
      regular-size.height <= systems-layout.title.single-line-height,
      message: "slide title must be a single line; remove explicit line breaks or shorten it",
    )
    let fitted-size = if regular-size.width <= size.width {
      systems-layout.title.size
    } else {
      systems-layout.title.size * (size.width / regular-size.width)
    }
    assert(
      fitted-size >= systems-layout.title.min-size,
      message: "slide title does not fit on one line at the 30pt minimum; shorten it or move detail into lead/body content",
    )
    render-at(fitted-size)
  })
  let show-progress = self.store.at("section-progress", default: false)
  let marks = self.store.at("page-marks", default: ())
  let mark-content = render-page-marks(
    self,
    marks,
    slot: "header-end",
  )
  // This invisible carrier reserves only horizontal space in the title row.
  // The visible mark is positioned independently against the complete title
  // region below, so neither its height nor its centering can move the title.
  let mark-slot = if mark-content == none { none } else { context {
    let natural-size = measure(mark-content)
    block(
      width: natural-size.width,
      height: systems-layout.title.size,
      above: 0pt,
      below: 0pt,
    )
  } }
  let progress-content = if show-progress { section-progress-dots(self) } else { none }
  let end-content = if progress-content == none {
    mark-slot
  } else if mark-slot == none {
    progress-content
  } else {
    grid(
      columns: (auto, auto),
      gutter: 12pt,
      align: right + horizon,
      progress-content,
      mark-slot,
    )
  }
  // A fixed row makes title geometry independent of optional progress and
  // page-mark content. The layout cell supplies the exact remaining width to
  // the single-line fitter after both right-side slots have been reserved.
  let title-row = grid(
    columns: (1fr, auto),
    rows: (systems-layout.title.row-height,),
    gutter: 18pt,
    align(left + top, title-rendered),
    align(
      right + horizon,
      if end-content == none { block(width: 0pt, height: 0pt) } else { end-content },
    ),
  )

  let header-base = move(
    dy: 21pt,
    block(
      width: 100%,
      height: systems-layout.title.band-height,
      above: 0pt,
      below: 0pt,
      inset: (top: 10pt, bottom: 7pt),
      grid(
        columns: 1,
        rows: (1fr, auto),
        block(
          width: 100%,
          inset: (
            left: systems-layout.title.x,
            right: systems-layout.title.mark-right-inset,
          ),
          move(dy: systems-layout.title.row-optical-dy, title-row),
        ),
        pad(
          left: systems-layout.title.rule-x,
          right: systems-layout.slide.width
            - systems-layout.title.rule-x
            - systems-layout.title.rule-width,
          move(
            dy: systems-layout.title.rule-optical-dy,
            line(
              length: 100%,
              stroke: systems-layout.title.rule-stroke
                + self.store.at("rule-color", default: grey),
            ),
          ),
        ),
      ),
    ),
  )

  if mark-content == none {
    header-base
  } else {
    context {
      let mark-size = measure(mark-content)
      let mark-y = (systems-layout.title.rule-y - mark-size.height) / 2
      assert(
        mark-y >= 0pt,
        message: "page-mark is taller than the available title region; reduce page-mark.height",
      )
      header-base
      place(
        top + right,
        dx: -systems-layout.title.mark-right-inset,
        dy: mark-y,
        mark-content,
      )
    }
  }
}

#let master-footer(
  self,
) = {
  let spec = systems-layout.footer
  let footer-slot(body, horizontal: left) = block(
    width: 100%,
    height: 100%,
    above: 0pt,
    below: 0pt,
    align(horizontal + horizon, body),
  )
  let footer-text(body, horizontal: left, fit-width: none) = {
    let rendered = text(
      font: font-sans,
      size: spec.text-size,
      fill: white,
      body,
    )
    if fit-width != none {
      rendered = utils.fit-to-width(width: fit-width, grow: false, rendered)
    }
    footer-slot(rendered, horizontal: horizontal)
  }

  let footer-logo = self.store.at("footer-logo", default: none)
  let footer-logo-width = self.store.at("footer-logo-width", default: none)
  let resolved-logo-width = if footer-logo-width == none {
    spec.logo-width
  } else {
    footer-logo-width
  }
  let asset-resolver = self.store.at("asset-resolver", default: path => path)

  block(
    width: 100%,
    height: spec.height,
    above: 0pt,
    below: 0pt,
    fill: deep-purple,
    inset: (left: spec.inset-left, right: spec.inset-right),
    grid(
      columns: spec.columns,
      rows: (spec.height,),
      gutter: 0pt,
      footer-slot(
        if footer-logo == none {
          []
        } else {
          move(
            dx: spec.logo-dx,
            render-media(
              footer-logo,
              width: resolved-logo-width,
              height: spec.logo-height,
              resolver: asset-resolver,
            ),
          )
        },
      ),
      footer-text(resolved-footer-title(self), fit-width: spec.title-width),
      footer-text(resolved-date(self)),
      [],
      footer-text(
        context utils.slide-counter.display("1"),
        horizontal: right,
      ),
    ),
  )
}
