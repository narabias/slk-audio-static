## JavaScript 文件名说明

源码包将 JavaScript 保存为 `.js.txt`：

```text
app.js.txt
tools/prepare-vendor.mjs.txt
```

直接使用仓库自带的 GitHub Actions 部署时不需要改名，工作流会自动恢复正确后缀。

# GitHub Pages 部署清单

## 推荐方式：直接上传源码

本方式不要求你的电脑安装 Node.js，也不要求 Vite 或其他构建工具。

1. 在 GitHub 新建仓库。
2. 将压缩包解压后的**全部文件和目录**上传到仓库根目录，包括 `.github/`。
3. 打开仓库 `Settings → Pages`。
4. 在 `Build and deployment → Source` 选择 **GitHub Actions**。
5. 打开 `Actions` 页面，等待 `Deploy static SLK converter` 成功完成。
6. 回到 `Settings → Pages`，打开 GitHub 给出的站点地址。

工作流只在发布阶段下载固定版本的 `silk-wasm` 和 `ffmpeg.wasm` 静态运行文件。用户转换音频时，所有计算都发生在浏览器内，不会把文件传给 GitHub Actions 或其他服务器。

## 你不需要准备

- 不需要后端服务器
- 不需要数据库
- 不需要 API 密钥
- 不需要 Vite、Webpack 或 React
- 不需要在本地安装 FFmpeg
- 使用推荐部署方式时，不需要在本地安装 Node.js

## 首次访问与缓存

- SILK 核心会作为静态 WASM 文件由浏览器加载。
- FFmpeg 核心大约 32 MB，只有浏览器原生解码失败或选择输出 MP3 时才加载。
- 加载成功后，浏览器通常会缓存静态资源。

## 常见问题

### Actions 没有运行

确认 `.github/workflows/pages.yml` 已上传，并在仓库的 `Actions` 设置中允许 GitHub Actions。

### Pages 显示 404

确认工作流已经成功完成，并且 `Settings → Pages → Source` 选择的是 `GitHub Actions`，不是分支发布。

### 想从分支目录直接发布

先在电脑安装 Node.js 18 或更高版本，然后运行：

    npm run setup:vendor

这会把第三方静态运行文件复制到 `vendor/`。随后需要把这些文件一并提交到仓库。

### 文件是否上传到服务器

不会。GitHub Pages 只负责发送 HTML、JavaScript 和 WASM 静态文件。用户选择的音频由网页在本机浏览器内读取和处理。
