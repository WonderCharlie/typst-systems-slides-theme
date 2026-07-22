// Internal rendering bridge for Theme-owned media slots.
//
// Author content uses Typst's native `image`, `figure`, and `figure.caption`
// elements directly. This file exists only because title slides, page marks,
// and the footer accept either a path or already-rendered content through the
// Theme asset resolver; none of these helpers are exported from `lib.typ`.

#let identity-asset-resolver(path) = path

#let render-media(
  media,
  width: none,
  height: none,
  fit: "contain",
  resolver: identity-asset-resolver,
) = {
  if media == none { return [] }
  let resolved = if type(media) == str { resolver(media) } else { media }
  if type(resolved) in (str, path) {
    if width == none and height == none { return image(resolved, fit: fit) }
    if width == none { return image(resolved, height: height, fit: fit) }
    if height == none { return image(resolved, width: width, fit: fit) }
    return image(resolved, width: width, height: height, fit: fit)
  }
  if width == none and height == none { resolved }
  else if width == none { box(height: height, align(center + horizon, resolved)) }
  else if height == none { box(width: width, align(center + horizon, resolved)) }
  else { box(width: width, height: height, align(center + horizon, resolved)) }
}
