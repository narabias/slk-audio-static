# 第三方组件说明

本项目的页面代码为原生 HTML、CSS 和 JavaScript。音频转换依赖以下第三方项目：

- `silk-wasm 3.7.1`：腾讯 SILK 编解码 WebAssembly 封装，MIT License。
- `@ffmpeg/ffmpeg 0.12.15`：FFmpeg WebAssembly 的浏览器包装器。
- `@ffmpeg/core 0.12.10`：单线程 FFmpeg WebAssembly 核心。

运行 `npm run setup:vendor` 后，依赖包中提供的许可证文件会复制到 `vendor/licenses/`。

FFmpeg 及其编译进核心的库可能适用 LGPL、GPL 或其他第三方许可要求。公开或商业分发前，请保留许可证文件，并根据实际用途自行进行许可证与专利合规审查。

SILK 编解码技术也可能涉及不同地区的专利或平台兼容性问题。本项目不代表腾讯、微信、Skype 或 FFmpeg 官方。
