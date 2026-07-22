// 标题页与目录页；公共 API 由 globals.typ 统一提供。
#import "../globals.typ": asset-path, outline-slide, runtime, title-slide

#title-slide(
  subtitle: [A minimal Typst + Touying starter for systems talks],
  event-mark: asset-path("example-mark.svg"),
  counted: false,
)
#runtime.speaker-note[Introduce the question, the audience, and the one-sentence contribution.]

#outline-slide(
  title: [Roadmap],
  level: 1,
  numbered: (true,),
  numbering: ("1.",),
)
#runtime.speaker-note[Preview the question, evidence, and conclusion that organize the talk.]
