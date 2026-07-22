// Stable package exports. Keep the flat surface intentionally small; advanced
// visual primitives remain available through named module namespaces.

// Touying theme and lifecycle.
#import "../themes/systems-slides-template/theme.typ": systems-slides-theme
#import "../themes/systems-slides-template/marks.typ": page-mark
#import "slides.typ": slide, title-slide, outline-slide, section-slide
#import "page-frame.typ": page-frame, page-layer
#import "runtime-api.typ" as runtime

// Content-neutral page geometry and structural composition.
#import "layouts.typ": layout-profile, region, row-split, column-split
#import "flow.typ": body-flow

// Independent multilevel Points engine. Theme defaults are internal; authors
// customize the stable renderer directly instead of selecting profiles.
#import "points.typ": point, points

// Native Typst `image`, `figure`, and `figure.caption` are the only public
// media aliases. Theme-owned path/content slots use a private renderer.
#import "typography-api.typ" as typography
#import "typography.typ": lead
#import "containers.typ": panel, callout
