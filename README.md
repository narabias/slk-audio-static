# 纯静态 SLK 音频转换器

这是一个不使用 Vite、Webpack、React 或后端 API 的浏览器工具：

- 音频 → 腾讯 SILK/SLK
- SILK/SLK → WAV
- SILK/SLK → MP3
- 所有音频数据只在用户浏览器中处理
- 可直接部署到 GitHub Pages
- FFmpeg 仅在浏览器原生解码失败或输出 MP3 时按需加载

## 最省事的 GitHub Pages 部署

1. 新建一个 GitHub 仓库。
2. 把本目录中的全部文件上传到仓库根目录。
3. 仓库进入 `Settings → Pages`。
4. `Build and deployment → Source` 选择 **GitHub Actions**。
5. 推送到 `main` 或 `master` 后，等待 `Deploy static SLK converter` 工作流完成。

本地不需要安装 Node.js。更详细步骤见 [`DEPLOY.md`](./DEPLOY.md)。

工作流只负责下载固定版本的 WASM 运行库并发布静态文件。网站运行时没有服务器端音频计算。

## 不使用 GitHub Actions，直接从仓库目录发布

电脑需要安装 Node.js 18 或更高版本。Node 只用于第一次准备第三方静态文件，不参与网站运行。

Windows：

    prepare.bat

macOS / Linux：

    ./prepare.sh

或者：

    npm run setup:vendor

随后把整个目录（包括生成后的 `vendor/`）提交到仓库，再把 Pages Source 设置为从分支根目录发布。

> `.gitignore` 默认忽略大型 vendor 文件。如果你选择从分支直接发布，需要删除 `.gitignore` 中的 vendor 忽略规则，或者使用 `git add -f vendor/ffmpeg vendor/silk vendor/licenses` 强制提交。

## 本地测试

浏览器不能稳定地通过 `file://` 加载 WASM。请使用任意静态服务器：

    npx serve .

或：

    python -m http.server 8080

然后访问终端显示的本地地址。

## 转换路线

### 音频 → SLK

1. 优先用 Web Audio API 解码并重采样为单声道 16-bit PCM。
2. 如果浏览器不能解码该格式，才加载 FFmpeg WASM。
3. PCM 交给 `silk-wasm` 编码为腾讯 SILK/SLK。

因此，大多数标准 WAV、MP3 和浏览器原生支持的 M4A 在 Chrome/Edge 中不会加载 FFmpeg。不同浏览器支持的音频格式可能不同。

### SLK → 音频

- 输出 WAV：`silk-wasm` 解码后由 JavaScript 添加 WAV 头，不加载 FFmpeg。
- 输出 MP3：先生成 WAV，再按需加载 FFmpeg 编码 MP3。

## 需要注意

- SLK 一般不可靠地保存可供网页识别的采样率。默认使用 24000 Hz；若速度或音调异常，可选择 16000、12000、8000 等重新解码。
- SILK 更适合语音，不适合追求音乐保真的场景。
- FFmpeg 核心约 32 MB，但只有需要时才加载，并由浏览器缓存。
- 所有处理都占用本机内存。手机建议使用较短、较小的文件。
- GitHub Pages 会正确提供 HTTPS；WASM 和 Web Audio 可以正常使用。

## 目录结构

    index.html
    styles.css
    app.js
    vendor/
      silk/
      ffmpeg/
      licenses/
    tools/prepare-vendor.mjs
    .github/workflows/pages.yml

## 版本

- silk-wasm: 3.7.1
- @ffmpeg/ffmpeg: 0.12.15
- @ffmpeg/core: 0.12.10（单线程，无需 SharedArrayBuffer 或 COOP/COEP 响应头）
