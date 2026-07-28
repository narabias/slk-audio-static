# 第三方开源组件、许可证与源码说明

本网页的音频处理在浏览器本地运行。发布目录中包含或按需加载以下第三方 JavaScript / WebAssembly 组件。请勿删除本文件及 `LICENSES/` 目录。

## 1. silk-wasm 3.7.1

- 用途：腾讯 SILK/SLK 编码、解码的浏览器 WebAssembly 封装。
- 上游项目：https://github.com/idranme/silk-wasm
- npm：https://www.npmjs.com/package/silk-wasm/v/3.7.1
- 封装层许可证：MIT License。
- 完整文本：[`LICENSES/silk-wasm-MIT.txt`](./LICENSES/silk-wasm-MIT.txt)

Copyright (c) 2024 idranme。

### SILK 编解码核心

`silk-wasm` 的 WebAssembly 编解码核心包含源自 SILK Codec / Skype SILK SDK 的代码。二进制再分发需要在文档或随附材料中保留相应版权、条件和免责声明。

- Skype SILK 声明：[`LICENSES/SILK-Skype-NOTICE.txt`](./LICENSES/SILK-Skype-NOTICE.txt)
- libSilkCodec 中的 BSD 2-Clause 文本：[`LICENSES/SILK-BSD-2-Clause.txt`](./LICENSES/SILK-BSD-2-Clause.txt)
- 对应上游源码：https://github.com/idranme/silk-wasm/tree/main/binding/libSilkCodec/silk

SILK 声明明确说明：该许可没有授予任何明示或默示的专利许可。不同地区的专利与格式兼容问题需要由部署者自行评估。

## 2. @ffmpeg/ffmpeg 0.12.15

- 用途：在浏览器 Worker 中控制 FFmpeg WebAssembly 核心。
- 上游项目：https://github.com/ffmpegwasm/ffmpeg.wasm
- npm：https://www.npmjs.com/package/@ffmpeg/ffmpeg/v/0.12.15
- 许可证：MIT License。
- 完整文本：[`LICENSES/ffmpeg-wasm-MIT.txt`](./LICENSES/ffmpeg-wasm-MIT.txt)

Copyright (c) 2019 Jerome Wu。

## 3. @ffmpeg/core 0.12.10

- 用途：单线程 FFmpeg WebAssembly 核心；仅在浏览器原生解码失败或需要输出 MP3 时加载。
- 上游项目：https://github.com/ffmpegwasm/ffmpeg.wasm
- npm：https://www.npmjs.com/package/@ffmpeg/core/v/0.12.10
- npm 包声明许可证：GPL-2.0-or-later。
- GPL v2 完整文本：[`LICENSES/ffmpeg-core-GPL-2.0.txt`](./LICENSES/ffmpeg-core-GPL-2.0.txt)
- 源码与构建脚本：https://github.com/ffmpegwasm/ffmpeg.wasm

公开提供 `ffmpeg-core.wasm` 等目标代码时，应同时让接收者能够取得相应源码、构建脚本和许可证条款。此项目保留上游链接和许可证文本；正式商业分发前，建议根据最终发布方式进行独立的开源合规审查。

## 4. 非隶属声明

本项目不是腾讯、微信、QQ、Skype、Microsoft、FFmpeg 或 ffmpeg.wasm 的官方产品，也不代表上述项目或组织对本网站进行认可或背书。“FFmpeg”等名称和标识归各自权利人所有。

## 5. 本项目自身代码

第三方组件的许可证不等于本项目页面代码的许可证。若仓库根目录没有另行放置 `LICENSE`，则本项目自有 HTML、CSS、JavaScript 默认不自动授予他人复制、修改或再分发权利。
