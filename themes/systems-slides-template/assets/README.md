# Theme assets

本目录只保存 `systems-slides-template` Theme 自身的视觉与排版依赖，不保存论文、会议或 Deck
内容。字体目录是唯一源码：Poppins 用于演示文本，Source Code Pro 用于 `raw` 代码，New
Computer Modern 与 Libertinus Serif 用于 Typst 原生数学内容。每个字体目录同时保存其许可。

Typst 与 Tinymist 不会自动把 package resource 注册为字体。安装工具生成 package 快照时，
会将完整 `assets/fonts/` 物化到 `template/fonts/`；初始化后的 Deck 通过自身 `fonts/`
发现这些部署副本。部署副本不得在仓库中独立维护。
