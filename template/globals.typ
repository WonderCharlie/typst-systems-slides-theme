// 所有章节只从本文件取得公共接口，避免直接依赖包内部 src/ 或兼容层。
#import "@local/systems-slides-template:0.6.0": (
  lead,
  outline-slide,
  point,
  points,
  runtime,
  slide,
  systems-slides-theme,
  title-slide,
)
#import "metadata.typ": deck-meta

/// 将 deck 内的相对资源名锚定到当前项目根目录的 `assets/`，只返回原生 Typst `path`，不负责渲染、尺寸、caption 或布局。
///
/// - relative (str): 职责：提供 `assets/` 内部的项目相对资源名；必填；允许使用 `/` 分隔的非空相对路径，例如 `"images/logo.png"`；没有特殊值；每次调用都相对定义本函数的 deck 根目录解析；不得以 `/` 开头、包含反斜杠、空路径段、`.` 或 `..`，因此不能逃逸当前 deck 的 `assets/`。
///
/// -> path
#let asset-path(relative) = {
  assert(type(relative) == str, message: "asset-path.relative must be a string")
  assert(relative != "", message: "asset-path.relative must not be empty")
  assert(not relative.starts-with("/"), message: "asset-path.relative must be relative to assets/")
  assert(not relative.contains("\\"), message: "asset-path.relative must use forward slashes")
  let parts = relative.split("/")
  assert(
    parts.all(part => part not in ("", ".", "..")),
    message: "asset-path.relative must not contain empty, . or .. segments",
  )
  path("assets/" + relative)
}

// 新 deck 的统一 Theme 配置。页面级布局与内容仍由各 section 决定。
#let deck-theme = systems-slides-theme.with(
  title: deck-meta.title,
  short-title: deck-meta.short-title,
  author: deck-meta.author,
  institution: deck-meta.institution,
  footer-title: auto,
  section-progress: true,
  section-slides: false,
)
