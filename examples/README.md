# Product Catalog

[`catalog/`](catalog/) 是 Theme 仓库唯一的产品级 Example。它以 28 个逻辑场景、45 个
物理页面验证公共接口覆盖、跨状态像素稳定性、字体隔离和页面视觉契约。内容与素材均为
合成演示数据。

Catalog 不是新 Deck 脚手架，也不是完整 API 参数表。创建演示请先安装包，再使用：

```sh
typst init @local/systems-slides-template:0.4.0 my-talk
```

运行 `make catalog-verify` 可编译并验证产品 Catalog。真实演示文稿与面向最终作者的精简
Catalog 保存在独立 Slides 工作区，不在两个仓库间复制或同步。
