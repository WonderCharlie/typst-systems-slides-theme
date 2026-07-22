// 唯一编译入口：全局 Theme 配置位于 globals.typ，演示元数据位于 metadata.typ。
#import "globals.typ": deck-theme

#show: deck-theme

// 一级标题用于目录与章节进度，二级标题由各 slide 显式设置。
#set heading(numbering: "1.")

#include "sections/1_frontmatter.typ"
#include "sections/2_content.typ"
