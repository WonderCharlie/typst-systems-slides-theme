#import "@local/systems-slides-template:0.6.0": systems-slides-theme

#let asset-path(relative) = {
  assert(type(relative) == str, message: "catalog asset path must be a string")
  assert(relative != "", message: "catalog asset path must be non-empty")
  assert(not relative.starts-with("/"), message: "catalog asset path must be relative to assets/")
  assert(not relative.contains("\\"), message: "catalog asset path must use forward slashes")
  let parts = relative.split("/")
  assert(parts.all(part => part not in ("", ".", "..")), message: "catalog asset path must stay below assets/")
  path("assets/" + relative)
}

#let relay-title = [Relay: Dependency-Aware I/O Scheduling for Data-Intensive Services]

#let catalog-theme = systems-slides-theme.with(
  title: relay-title,
  short-title: [Relay],
  author: [Systems Slides Template Contributors],
  institution: [Synthetic Research Institute],
  date: datetime(year: 2026, month: 7, day: 22),
  footer-title: auto,
  footer-logo: asset-path("marks/relay-footer.svg"),
  footer-logo-width: 54pt,
  section-progress: true,
  section-slides: false,
)
