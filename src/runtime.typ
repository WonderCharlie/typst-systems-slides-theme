// Thin Touying adapter for content-neutral page-frame values.
//
// This module deliberately delegates page creation, subslides, speaker notes,
// counters, overflow measurement, and PDFPC metadata to Touying.

#import "@preview/touying:0.7.4" as _touying
#import "../themes/systems-slides-template/geometry.typ": systems-layout

#let _page-layer-kind = "systems-slides-template/page-layer"
#let _page-frame-kind = "systems-slides-template/page-frame"
#let _required-frame-fields = (
  "background",
  "overlay",
  "foreground",
  "chrome",
  "section-progress",
  "header",
  "footer",
  "body-inset",
  "margin",
  "fill",
  "width",
  "height",
  "header-ascent",
  "footer-descent",
  "clip",
  "detect-overflow",
)

#let _frame-owner(frame) = {
  let name = frame.at("name", default: none)
  if name == none { "page-frame" } else { "page-frame \"" + name + "\"" }
}

#let _layer-owner(layer, fallback) = {
  let name = layer.at("name", default: none)
  if name == none { fallback } else { fallback + " \"" + name + "\"" }
}

#let _render-page-layer(self, value, fallback) = {
  if value == none { return none }

  let body = value
  let alignment-value = auto
  let inset-value = auto
  let area-value = "page"
  let owner = fallback
  if type(value) == dictionary {
    assert(
      value.at("kind", default: none) == _page-layer-kind,
      message: fallback + ": expected a value created by page-layer",
    )
    owner = _layer-owner(value, fallback)
    body = value.body
    area-value = value.area
    alignment-value = value.align
    inset-value = value.inset
  }

  let rendered = _touying.utils.call-or-display(self, body)
  if rendered == none { return none }
  assert(
    type(rendered) in (content, str),
    message: owner + ": callback must return content, a string, or none",
  )

  let padded = if inset-value == auto {
    rendered
  } else {
    pad(inset-value, rendered)
  }
  let inner = if alignment-value == auto {
    padded
  } else {
    std.align(alignment-value, padded)
  }
  let area = if area-value == "body" {
    systems-layout.body
  } else {
    (
      left: 0pt,
      top: 0pt,
      width: 100%,
      height: 100%,
    )
  }
  place(
    left + top,
    dx: area.left,
    dy: area.top,
    block(
      width: area.width,
      height: area.height,
      above: 0pt,
      below: 0pt,
      inset: 0pt,
      inner,
    ),
  )
}

#let _combine-layers(lower, upper) = {
  if lower == none {
    upper
  } else if upper == none {
    lower
  } else {
    lower + upper
  }
}

// Convert a page-frame profile into Touying config fragments. The caller merges
// the result into `self` before invoking `touying-slide`; later raw `config`
// fragments remain the final escape hatch.
#let page-frame-config(
  self,
  frame: auto,
) = {
  if frame == auto { return (:) }
  assert(type(frame) == dictionary, message: "slide.frame must be auto or a page-frame")
  assert(
    frame.at("kind", default: none) == _page-frame-kind,
    message: "slide.frame must be a value created by page-frame",
  )
  for key in _required-frame-fields {
    assert(key in frame, message: "slide.frame is missing field " + key)
  }
  let owner = _frame-owner(frame)

  let page-args = (:)
  let common-args = (:)
  let store-args = (:)

  if frame.chrome == false {
    page-args.insert("header", none)
    page-args.insert("footer", none)
  }
  if frame.header != auto { page-args.insert("header", frame.header) }
  if frame.footer != auto { page-args.insert("footer", frame.footer) }

  if frame.background != auto {
    page-args.insert(
      "background",
      _render-page-layer(self, frame.background, owner + ".background"),
    )
  }

  if frame.overlay != auto {
    let overlay = _render-page-layer(self, frame.overlay, owner + ".overlay")
    let foreground-value = if frame.foreground == auto {
      self.page.at("foreground", default: none)
    } else {
      frame.foreground
    }
    let foreground = if foreground-value == none {
      none
    } else {
      _render-page-layer(self, foreground-value, owner + ".foreground")
    }
    page-args.insert("foreground", _combine-layers(overlay, foreground))
  } else if frame.foreground != auto {
    page-args.insert(
      "foreground",
      _render-page-layer(self, frame.foreground, owner + ".foreground"),
    )
  }

  for key in (
    "margin",
    "fill",
    "width",
    "height",
    "header-ascent",
    "footer-descent",
  ) {
    let value = frame.at(key)
    if value != auto { page-args.insert(key, value) }
  }
  for key in ("clip", "detect-overflow") {
    let value = frame.at(key)
    if value != auto { common-args.insert(key, value) }
  }
  if frame.section-progress != auto {
    store-args.insert("section-progress", frame.section-progress)
  }
  let store-config = if store-args.len() == 0 {
    (:)
  } else {
    _touying.config-store(..store-args)
  }

  _touying.utils.merge-dicts(
    _touying.config-page(..page-args),
    _touying.config-common(..common-args),
    store-config,
  )
}

// Touying runtime adapter. Callback-style slides pass their current self to
// utils.uncover so measured layout/context containers receive rendered content
// rather than an unsupported animation marker.
#let pause = _touying.pause
#let jump = _touying.jump
#let meanwhile = _touying.meanwhile
#let uncover = _touying.uncover
#let uncover-callback(self, visible-subslides, uncover-cont, cover-fn: auto) = (
  _touying.utils.uncover(
    self: self,
    visible-subslides,
    uncover-cont,
    cover-fn: cover-fn,
  )
)
#let only = _touying.only
#let alternatives = _touying.alternatives

// speaker-note 同样直接继承 Touying 的 mode、setting、subslide 与 note 参数。
// 外置备注必须紧邻对应 slide（中间只能有空白），否则上游不会将其附着到该页。
#let speaker-note = _touying.speaker-note

// Build the Touying global config needed for a combined audience/speaker PDF.
#let presenter-view(
  side: right,
) = {
  assert(
    side in (none, bottom, right),
    message: "runtime.presenter-view: side must be none, bottom, or right; got " + repr(side),
  )
  _touying.config-common(show-notes-on-second-screen: side)
}
