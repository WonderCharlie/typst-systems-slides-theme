// Touying combined dual-screen speaker-note contract.

#import "../lib.typ": runtime, systems-slides-theme

#show: systems-slides-theme.with(
  runtime.presenter-view(side: right),
  title: [PRESENTER VIEW],
  author: [Theme Contract],
  date: datetime(year: 2036, month: 8, day: 9),
)

= Presenter Section

== Audience slide

PRESENTER_AUDIENCE_CONTENT

#runtime.speaker-note[PRESENTER_PRIVATE_NOTE]
