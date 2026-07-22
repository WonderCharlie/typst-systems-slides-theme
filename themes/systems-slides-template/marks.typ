// Page-scoped marks rendered by the systems-slides-template Theme chrome.
//
// A mark is neither slide prose nor a page layout container. It describes
// auxiliary content attached to a named Theme slot, so the master owns its
// placement while the deck owns the actual content.

#import "@preview/touying:0.7.4": utils

#let page-mark-kind = "systems-slides-template/page-mark"
#let default-page-mark-height = 50.5pt

/// 构造绑定到当前 slide 的页面标识。
/// 标识不参与正文流，由 Theme master 在具名 chrome 槽位中渲染。
///
/// - body (content, str, any, function): 必填的内容、path、字符串路径或 Touying 状态回调；
///   字符串经 resolver，回调必须返回可渲染内容或图片路径。
/// - slot (str): Theme 槽位，默认且当前仅支持 `"header-end"`；未知值在编译期报错。
/// - height (length, auto): 排版高度，默认 `auto` 解析为 Theme 的 `50.5pt`；
///   正长度可覆盖但不能超过 title 区，图片等比缩放后在标题区垂直居中。
/// - name (str, none): 可选诊断名称，默认 `none`；只影响错误信息。
/// - resolver (auto, function): 字符串路径解析器，默认 `auto` 继承 Theme；原生 path/content 不调用它。
///
/// -> dictionary
#let page-mark(
  body,
  slot: "header-end",
  height: auto,
  name: none,
  resolver: auto,
) = {
  let owner = if name == none { "page-mark" } else { "page-mark \"" + name + "\"" }
  assert(
    type(body) in (content, str, path, function),
    message: owner + ": body must be content, a string, a path, or a function",
  )
  assert(
    slot in ("header-end",),
    message: owner + ": slot must be header-end; got " + repr(slot),
  )
  assert(
    height == auto or (type(height) == length and height > 0pt),
    message: owner + ": height must be auto or a positive length; got " + repr(height),
  )
  assert(
    name == none or type(name) == str,
    message: "page-mark.name must be a string or none",
  )
  assert(
    resolver == auto or type(resolver) == function,
    message: "page-mark.resolver must be auto or a function",
  )

  (
    kind: page-mark-kind,
    body: body,
    slot: slot,
    height: height,
    name: name,
    resolver: resolver,
  )
}

#let validate-page-marks(marks) = {
  assert(type(marks) == array, message: "slide.marks must be an array")
  for (index, mark) in marks.enumerate() {
    assert(
      type(mark) == dictionary and mark.at("kind", default: none) == page-mark-kind,
      message: "slide.marks item " + repr(index) + " must be created by page-mark",
    )
  }
}

#let render-page-marks(self, marks, slot: "header-end") = {
  let selected = marks.filter(mark => mark.slot == slot)
  if selected.len() == 0 { return none }

  let rendered = selected.map(mark => {
    let resolved-height = if mark.height == auto {
      default-page-mark-height
    } else {
      mark.height
    }
    let body = if type(mark.body) == function {
      utils.call-or-display(self, mark.body)
    } else {
      mark.body
    }
    let owner = if mark.name == none { "page-mark" } else { "page-mark \"" + mark.name + "\"" }
    assert(
      type(body) in (content, str, path),
      message: owner + ": callback must return content, a string, or a path",
    )
    if type(body) in (str, path) {
      let resolved = if type(body) == path {
        body
      } else {
        let resolver = if mark.resolver == auto {
          self.store.at("asset-resolver", default: path => path)
        } else {
          mark.resolver
        }
        (resolver)(body)
      }
      assert(
        type(resolved) in (str, path),
        message: owner + ": resolver must return a string or path",
      )
      image(resolved, height: resolved-height, fit: "contain")
    } else if body.func() == image {
      context {
        let natural = measure(body)
        assert(natural.height > 0pt, message: owner + ": image must have positive height")
        let factor = (resolved-height / natural.height) * 100%
        scale(x: factor, y: factor, reflow: true, body)
      }
    } else {
      block(
        height: resolved-height,
        above: 0pt,
        below: 0pt,
        align(center + horizon, body),
      )
    }
  })

  if rendered.len() == 1 {
    rendered.first()
  } else {
    grid(
      columns: (auto,) * rendered.len(),
      gutter: 8pt,
      align: right + horizon,
      ..rendered,
    )
  }
}
