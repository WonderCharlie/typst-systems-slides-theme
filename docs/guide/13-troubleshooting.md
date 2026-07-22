# 13 · 故障排查

读完本章，你可以按“现象—原因—修复”定位安装、路径、字体、标题、布局和预览问题。

| 现象 | 原因 | 修复 |
| --- | --- | --- |
| 找不到 `@local/systems-slides-template:0.6.0` | 本地包未安装或版本不同 | 在仓库运行 `make install`，再运行 `make install-check` |
| 找不到 Touying | 官方 `@preview/touying:0.7.4` 未缓存且无网络 | 恢复 Typst package 网络或预先缓存官方包，不要复制/fork Touying |
| unknown font / 数学字体变化 | 绕过 Deck Makefile 或字体路径失效 | 使用 `make`；确认 `fonts/`、`.vscode` 和 `--ignore-system-fonts --ignore-embedded-fonts` |
| 图片路径在另一工作区失效 | 使用绝对路径或相对 section 路径 | 文件放 `assets/`，调用 `image(asset-path("..."))` |
| section 无法单独预览 | section 依赖 `main.typ` 安装 Theme 和章节上下文 | 打开 Deck 根目录并预览 `main.typ` |
| Tinymist 显示旧 Hover | 安装的是旧物理快照 | 仓库运行 `make reinstall`，重载 VS Code，再运行 `make tinymist-installed-docs-check` |
| `slide title must be a single line` | 标题含显式换行 | 删除换行，把限定信息移入 lead |
| `slide title does not fit ... 30pt minimum` | 扣除 progress/mark 后仍太长 | 缩短 claim，或缩小/移除 page mark；不要继续缩字 |
| `fractional ... require a finite height` | `fr` 没有有限父尺寸 | 在正文 `body-flow` 中使用，或给 split 明确有限 width/height |
| tracks 与 regions 数量错误 | rows/columns 数量不匹配 | 一条轨道对应一个 region；gutter 数组应为 N−1 |
| fit policy requires finite track | 对 auto 自然轨道使用 contain/cover/严格 overflow | 改为有限轨道或使用 `fit: "flow"` |
| `content needs ... but region provides ...` | `overflow: "error"` 检测到空间不足 | 缩减内容、拆页、增大轨道，媒体可改 `contain` |
| Points level 跳跃 | 从 level 1 直接进入 3/4 | 补齐父层，且相邻最多增加一级 |
| page mark 挤压标题 | mark 占用标题水平槽位 | 缩短标题或减小 mark；标题纵向位置不应改变 |
| uncover 页面稳定、only 页面移动 | 两者隐藏语义不同 | 需要保留槽位用 `uncover`；明确需要释放空间才用 `only` |
| 正文进入 Footer | 内容超过正文安全区或绕过有限布局 | 减少内容，使用 `overflow: "error"`，不要以负间距修补 |
| 普通 PDF 出现彩色调试框 | 构建输入仍是 `layout-debug=boxes/labels` | 重新运行普通 `make`；debug 输出应是独立文件 |
| `make clean` 拒绝执行 | BUILD_DIR 不指向当前 Deck 的 `build/` | 恢复默认路径；不要放宽路径保护 |
| 修改源码但新 Deck 不变化 | 本地安装是物理快照 | 运行 `make reinstall`，然后重新 init 或重新编译 |

仍无法定位时，先运行 `make debug` 查看容器边界，再对照 [布局章节](08-layout.md)。包安装
和升级细节见 [INSTALL](../INSTALL.md)。
