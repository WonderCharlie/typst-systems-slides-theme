// Curated namespace for Touying's author-facing presentation runtime.
//
// Wrappers retain Touying's exact author-facing signatures so Tinymist can
// expose parameter documentation. Animation, subslide allocation, notes,
// counters, and PDFPC metadata remain implemented by Touying.

/// 为当前幻灯片附加演讲者备注。
/// 多次调用会累积；备注必须紧邻所属 slide。
///
/// - mode (str): 备注源码模式；默认 `"typ"`；允许 `"typ"` 或 `"md"`；调用值覆盖 Touying 默认解析模式；其他字符串不受支持。
/// - setting (function): 备注显示前的转换函数；默认恒等函数 `it => it`；显式函数完全替代默认转换；必须接受备注并返回可显示内容。
/// - subslide (none, auto, int, array, str): 备注适用的子页；默认 `auto`，按当前位置的 pause 自动确定；
///   `none` 表示所有子页，整数、数组或范围字符串显式限定；必须符合 Touying 的子页规格。
/// - note (content): 必填备注内容；无默认值；保留其中的 Typst 样式及渐进内容；必须紧邻目标 slide 才能被正确附着。
/// -> content
#let speaker-note(
  mode: "typ",
  setting: it => it,
  subslide: auto,
  note,
) = {
  import "runtime.typ" as runtime
  runtime.speaker-note(
    note,
    mode: mode,
    setting: setting,
    subslide: subslide,
  )
}

/// 将后续内容推进到下一个子页，等价于 `jump(1, relative: true)`。
/// 空间保留和阶段计数遵循 Touying。
///
/// -> content
#let pause = {
  import "runtime.typ" as runtime
  runtime.pause
}

/// 将当前动画位置跳转到指定子页。
/// `pause` 与 `meanwhile` 都建立在该接口之上。
///
/// - n (int): 跳转位置或偏移量；无默认值；`relative: false` 要求大于等于 1；`true` 要求非零相对偏移；显式值直接交给 Touying 校验。
/// - relative (bool): 是否把 `n` 解释为相对偏移；默认 `false`，表示绝对跳转；仅允许 `true` 或 `false`；设为 `true` 会覆盖默认绝对语义。
/// -> content
#let jump(n, relative: false) = {
  import "runtime.typ" as runtime
  runtime.jump(n, relative: relative)
}

/// 把后续内容重新并入第一个子页，等价于 `jump(1)`。
/// 并行阶段和计数遵循 Touying。
///
/// -> content
#let meanwhile = {
  import "runtime.typ" as runtime
  runtime.meanwhile
}

/// 在指定子页显示内容，并在隐藏阶段保留版面空间。
/// 测量布局中须使用 callback-style slide、传入 `self` 并显式设置 `repeat`。
///
/// - visible-subslides (int, array, str, label, dictionary, auto): 必填可见范围。
///   支持单个子页、数组、范围字符串和 waypoint；
///   `auto` 使用当前位置；必须符合 Touying 子页规格。
/// - uncover-cont (content): 必填待显示内容；隐藏时由 cover 函数处理但仍占据原空间。
///   内容自身样式继续继承调用环境。
/// - cover-fn (function, auto): 隐藏阶段的覆盖函数；默认 `auto`，继承 Theme 的 cover 方法；
///   传入函数会完全覆盖 Theme 方法，且必须接受并返回内容。
/// - self (dictionary, none): callback-style slide 提供的当前 Touying 状态；默认 `none` 使用自动标记路径；
///   测量布局必须显式传入，并由 `slide.repeat` 决定物理页数。
/// -> content
#let uncover(visible-subslides, uncover-cont, cover-fn: auto, self: none) = {
  import "runtime.typ" as runtime
  if self == none {
    runtime.uncover(
      visible-subslides,
      uncover-cont,
      cover-fn: cover-fn,
    )
  } else {
    runtime.uncover-callback(
      self,
      visible-subslides,
      uncover-cont,
      cover-fn: cover-fn,
    )
  }
}

/// 仅在指定子页插入内容。
/// 隐藏阶段不保留空间，周围布局会重新排版。
///
/// - visible-subslides (int, array, str, label, dictionary, auto): 必填可见范围。
///   支持单个子页、数组、范围字符串和 waypoint；
///   `auto` 使用当前位置；显式值覆盖自动阶段，必须符合 Touying 子页规格。
/// - only-cont (content): 必填待显示内容；不可见时内容完全不存在且不占空间。
///   内容自身样式继续继承调用环境。
/// -> content
#let only(visible-subslides, only-cont) = {
  import "runtime.typ" as runtime
  runtime.only(visible-subslides, only-cont)
}

/// 按子页依次显示多个候选内容，并为候选内容保留共同的显示区域。
///
/// - start (int, auto): 顺序模式的起始子页；默认 `auto`，从当前位置自动分配；显式正整数覆盖自动分配；使用 `at` 时不再决定候选映射。
/// - repeat-last (bool): 最后一项是否持续到后续子页；默认 `true`；仅允许布尔值；`false` 只在最后一项自己的范围内显示。
/// - position (any): 候选内容在共同区域中的对齐；默认 `bottom + left`；允许任意 Typst alignment；显式值覆盖默认对齐但不改变区域尺寸。
/// - stretch (bool): 是否按所有候选的最大宽高预留空间；默认 `false`；仅允许布尔值；零尺寸或 context 内容应保持 `false`。
/// - at (none, array): 可选 waypoint 或子页规格数组；默认 `none`，使用 `start` 顺序分配；显式数组覆盖顺序映射，长度必须与候选内容数量一致。
/// - args (arguments): 一个或多个候选内容块；无默认值；按书写顺序或 `at` 一一映射；至少应提供一个候选，且命名参数不得与显式参数冲突。
/// -> content
#let alternatives(
  start: auto,
  repeat-last: true,
  position: bottom + left,
  stretch: false,
  at: none,
  ..args,
) = {
  import "runtime.typ" as runtime
  runtime.alternatives(
    start: start,
    repeat-last: repeat-last,
    position: position,
    stretch: stretch,
    at: at,
    ..args,
  )
}

/// 生成观众画布与演讲者备注画布的 Touying 全局配置片段。
/// 返回值应作为 Theme 参数传入。
///
/// - side (any, none): 备注画布相对观众页的位置；默认 `right`；
///   仅允许 Typst alignment 值 `right`、`bottom` 或 `none`，其中 `none` 关闭双画布；
///   返回配置覆盖 Theme 的同名备注视图设置，后置局部配置仍可再次覆盖。
/// -> dictionary
#let presenter-view(side: right) = {
  import "runtime.typ" as runtime
  runtime.presenter-view(side: side)
}
