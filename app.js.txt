import { encode, decode, isSilk } from './vendor/silk/index.mjs';

const $ = (selector) => document.querySelector(selector);
const elements = {
  modeButtons: [...document.querySelectorAll('[data-mode]')],
  modeHint: $('#mode-hint'),
  engineBadge: $('#engine-badge'),
  fileInput: $('#file-input'),
  dropZone: $('#drop-zone'),
  dropSubtitle: $('#drop-subtitle'),
  fileInfo: $('#file-info'),
  encodeRateField: $('#encode-rate-field'),
  decodeRateField: $('#decode-rate-field'),
  outputFormatField: $('#output-format-field'),
  encodeRate: $('#encode-rate'),
  decodeRate: $('#decode-rate'),
  outputFormat: $('#output-format'),
  convertButton: $('#convert-button'),
  progressWrap: $('#progress-wrap'),
  progressBar: $('#progress-bar'),
  statusText: $('#status-text'),
  result: $('#result'),
  resultName: $('#result-name'),
  resultMeta: $('#result-meta'),
  downloadLink: $('#download-link'),
  audioPreview: $('#audio-preview'),
};

const state = {
  mode: 'audio-to-slk',
  file: null,
  busy: false,
  resultUrl: null,
  ffmpeg: null,
  ffmpegPromise: null,
};

function setMode(mode) {
  if (state.busy) return;
  state.mode = mode;
  state.file = null;
  elements.fileInput.value = '';
  elements.fileInfo.classList.add('hidden');
  clearResult();

  for (const button of elements.modeButtons) {
    button.classList.toggle('active', button.dataset.mode === mode);
  }

  const decoding = mode === 'slk-to-audio';
  elements.encodeRateField.classList.toggle('hidden', decoding);
  elements.decodeRateField.classList.toggle('hidden', !decoding);
  elements.outputFormatField.classList.toggle('hidden', !decoding);
  elements.modeHint.textContent = decoding
    ? '将腾讯 SILK/SLK 解码为 WAV，或进一步转换为 MP3。'
    : '将 WAV、MP3、M4A、FLAC、OGG 等音频转换为腾讯 SILK/SLK。';
  elements.dropSubtitle.textContent = decoding
    ? '请选择 .slk 或 .silk 文件'
    : '支持常见音频格式；浏览器能解码时不会加载 FFmpeg';
  elements.fileInput.accept = decoding
    ? '.slk,.silk,application/octet-stream'
    : 'audio/*,.wav,.mp3,.m4a,.aac,.flac,.ogg,.opus,.wma,.amr';
  updateConvertButton();
}

function updateConvertButton() {
  elements.convertButton.disabled = state.busy || !state.file;
  elements.convertButton.textContent = state.busy ? '正在转换……' : '开始转换';
}

function setStatus(message, progress = null, isError = false) {
  elements.progressWrap.classList.remove('hidden');
  elements.statusText.textContent = message;
  elements.statusText.classList.toggle('error', isError);
  if (progress !== null) {
    elements.progressBar.style.width = `${Math.max(3, Math.min(100, progress))}%`;
  }
}

function clearResult() {
  if (state.resultUrl) URL.revokeObjectURL(state.resultUrl);
  state.resultUrl = null;
  elements.result.classList.add('hidden');
  elements.audioPreview.classList.add('hidden');
  elements.audioPreview.removeAttribute('src');
  elements.downloadLink.removeAttribute('href');
}

function showResult(blob, filename, durationMs, previewable) {
  clearResult();
  const url = URL.createObjectURL(blob);
  state.resultUrl = url;
  elements.resultName.textContent = filename;
  elements.resultMeta.textContent = `${formatBytes(blob.size)} · ${formatDuration(durationMs)}`;
  elements.downloadLink.href = url;
  elements.downloadLink.download = filename;
  if (previewable) {
    elements.audioPreview.src = url;
    elements.audioPreview.classList.remove('hidden');
  }
  elements.result.classList.remove('hidden');
}

function handleFile(file) {
  if (!file || state.busy) return;
  state.file = file;
  clearResult();
  elements.progressWrap.classList.add('hidden');
  elements.fileInfo.textContent = `${file.name} · ${formatBytes(file.size)}`;
  elements.fileInfo.classList.remove('hidden');
  updateConvertButton();
}

async function convert() {
  if (!state.file || state.busy) return;
  state.busy = true;
  updateConvertButton();
  clearResult();
  setStatus('读取文件……', 5);

  try {
    if (state.mode === 'audio-to-slk') {
      await convertAudioToSlk(state.file);
    } else {
      await convertSlkToAudio(state.file);
    }
    setStatus('转换完成', 100);
  } catch (error) {
    console.error(error);
    setStatus(`转换失败：${normalizeError(error)}`, 100, true);
  } finally {
    state.busy = false;
    updateConvertButton();
  }
}

async function convertAudioToSlk(file) {
  const targetRate = Number(elements.encodeRate.value);
  const input = new Uint8Array(await file.arrayBuffer());
  setStatus('尝试浏览器原生音频解码……', 15);

  let pcm;
  let usedFfmpeg = false;

  try {
    pcm = await browserDecodeToPcm(input.buffer.slice(0), targetRate);
  } catch (nativeError) {
    console.warn('浏览器原生解码失败，回退 FFmpeg', nativeError);
    setStatus('原生解码不支持该文件，正在加载 FFmpeg……', 22);
    pcm = await ffmpegAudioToPcm(file, targetRate);
    usedFfmpeg = true;
  }

  setStatus('正在编码 SILK……', usedFfmpeg ? 78 : 58);
  const result = await encode(pcm, targetRate);
  const filename = `${baseName(file.name)}.slk`;
  const blob = new Blob([result.data], { type: 'application/octet-stream' });
  showResult(blob, filename, result.duration, false);
}

async function convertSlkToAudio(file) {
  const sampleRate = Number(elements.decodeRate.value);
  const outputFormat = elements.outputFormat.value;
  const input = new Uint8Array(await file.arrayBuffer());

  if (!isSilk(input)) {
    throw new Error('文件头不是可识别的 SILK/SLK');
  }

  setStatus('正在解码 SILK……', 28);
  const result = await decode(input, sampleRate);
  const wav = pcmS16leToWav(result.data, sampleRate, 1);

  if (outputFormat === 'wav') {
    const filename = `${baseName(file.name)}.wav`;
    showResult(new Blob([wav], { type: 'audio/wav' }), filename, result.duration, true);
    return;
  }

  setStatus('正在加载 FFmpeg 并编码 MP3……', 55);
  const mp3 = await ffmpegWavToMp3(wav);
  const filename = `${baseName(file.name)}.mp3`;
  showResult(new Blob([mp3], { type: 'audio/mpeg' }), filename, result.duration, true);
}

async function browserDecodeToPcm(arrayBuffer, targetRate) {
  const AudioContextClass = window.AudioContext || window.webkitAudioContext;
  if (!AudioContextClass || !window.OfflineAudioContext) {
    throw new Error('当前浏览器不支持 Web Audio 解码');
  }

  const context = new AudioContextClass();
  let decoded;
  try {
    decoded = await context.decodeAudioData(arrayBuffer);
  } finally {
    await context.close().catch(() => {});
  }

  const frameCount = Math.max(1, Math.ceil(decoded.duration * targetRate));
  const offline = new OfflineAudioContext(1, frameCount, targetRate);
  const source = offline.createBufferSource();
  source.buffer = decoded;
  source.connect(offline.destination);
  source.start();
  const rendered = await offline.startRendering();
  return float32ToPcmS16le(rendered.getChannelData(0));
}

function float32ToPcmS16le(samples) {
  const output = new Uint8Array(samples.length * 2);
  const view = new DataView(output.buffer);
  for (let i = 0; i < samples.length; i += 1) {
    const sample = Math.max(-1, Math.min(1, samples[i]));
    const value = sample < 0 ? sample * 0x8000 : sample * 0x7fff;
    view.setInt16(i * 2, Math.round(value), true);
  }
  return output;
}

async function loadFFmpeg() {
  if (state.ffmpeg) return state.ffmpeg;
  if (state.ffmpegPromise) return state.ffmpegPromise;

  state.ffmpegPromise = (async () => {
    const wrapperUrl = new URL('./vendor/ffmpeg/ffmpeg.js', import.meta.url).href;
    await loadClassicScript(wrapperUrl);

    const FFmpegClass = window.FFmpegWASM?.FFmpeg;
    if (!FFmpegClass) throw new Error('FFmpeg 包装器加载失败');

    const ffmpeg = new FFmpegClass();
    ffmpeg.on('log', ({ message }) => console.debug('[ffmpeg]', message));
    ffmpeg.on('progress', ({ progress }) => {
      if (Number.isFinite(progress)) {
        elements.progressBar.style.width = `${Math.max(55, Math.min(94, 55 + progress * 39))}%`;
      }
    });

    await ffmpeg.load({
      coreURL: new URL('./vendor/ffmpeg/ffmpeg-core.js', import.meta.url).href,
      wasmURL: new URL('./vendor/ffmpeg/ffmpeg-core.wasm', import.meta.url).href,
    });

    state.ffmpeg = ffmpeg;
    elements.engineBadge.textContent = 'FFmpeg 已加载';
    elements.engineBadge.classList.add('ready');
    return ffmpeg;
  })().catch((error) => {
    state.ffmpegPromise = null;
    throw error;
  });

  return state.ffmpegPromise;
}

function loadClassicScript(src) {
  return new Promise((resolve, reject) => {
    const existing = document.querySelector(`script[data-runtime-src="${src}"]`);
    if (existing) {
      if (existing.dataset.loaded === 'true') resolve();
      else existing.addEventListener('load', resolve, { once: true });
      return;
    }

    const script = document.createElement('script');
    script.src = src;
    script.async = true;
    script.dataset.runtimeSrc = src;
    script.addEventListener('load', () => {
      script.dataset.loaded = 'true';
      resolve();
    }, { once: true });
    script.addEventListener('error', () => reject(new Error(`无法加载 ${src}`)), { once: true });
    document.head.appendChild(script);
  });
}

async function ffmpegAudioToPcm(file, sampleRate) {
  const ffmpeg = await loadFFmpeg();
  const id = crypto.randomUUID().replaceAll('-', '');
  const inputName = `input-${id}.${safeExtension(file.name)}`;
  const outputName = `output-${id}.pcm`;

  try {
    await ffmpeg.writeFile(inputName, new Uint8Array(await file.arrayBuffer()));
    const code = await ffmpeg.exec([
      '-hide_banner', '-loglevel', 'error',
      '-i', inputName,
      '-vn', '-ac', '1', '-ar', String(sampleRate),
      '-c:a', 'pcm_s16le', '-f', 's16le',
      outputName,
    ]);
    if (code !== 0) throw new Error(`FFmpeg 解码失败，退出代码 ${code}`);
    const data = await ffmpeg.readFile(outputName);
    if (typeof data === 'string') throw new Error('FFmpeg 返回了意外文本');
    return new Uint8Array(data);
  } finally {
    await Promise.allSettled([ffmpeg.deleteFile(inputName), ffmpeg.deleteFile(outputName)]);
  }
}

async function ffmpegWavToMp3(wavBytes) {
  const ffmpeg = await loadFFmpeg();
  const id = crypto.randomUUID().replaceAll('-', '');
  const inputName = `input-${id}.wav`;
  const outputName = `output-${id}.mp3`;

  try {
    await ffmpeg.writeFile(inputName, wavBytes);
    const code = await ffmpeg.exec([
      '-hide_banner', '-loglevel', 'error',
      '-i', inputName,
      '-vn', '-c:a', 'libmp3lame', '-b:a', '96k',
      outputName,
    ]);
    if (code !== 0) throw new Error(`FFmpeg MP3 编码失败，退出代码 ${code}`);
    const data = await ffmpeg.readFile(outputName);
    if (typeof data === 'string') throw new Error('FFmpeg 返回了意外文本');
    return new Uint8Array(data);
  } finally {
    await Promise.allSettled([ffmpeg.deleteFile(inputName), ffmpeg.deleteFile(outputName)]);
  }
}

function pcmS16leToWav(pcm, sampleRate, channels = 1) {
  const bytes = pcm instanceof Uint8Array ? pcm : new Uint8Array(pcm);
  const headerSize = 44;
  const buffer = new ArrayBuffer(headerSize + bytes.byteLength);
  const view = new DataView(buffer);

  writeAscii(view, 0, 'RIFF');
  view.setUint32(4, 36 + bytes.byteLength, true);
  writeAscii(view, 8, 'WAVE');
  writeAscii(view, 12, 'fmt ');
  view.setUint32(16, 16, true);
  view.setUint16(20, 1, true);
  view.setUint16(22, channels, true);
  view.setUint32(24, sampleRate, true);
  view.setUint32(28, sampleRate * channels * 2, true);
  view.setUint16(32, channels * 2, true);
  view.setUint16(34, 16, true);
  writeAscii(view, 36, 'data');
  view.setUint32(40, bytes.byteLength, true);
  new Uint8Array(buffer, headerSize).set(bytes);
  return new Uint8Array(buffer);
}

function writeAscii(view, offset, value) {
  for (let i = 0; i < value.length; i += 1) view.setUint8(offset + i, value.charCodeAt(i));
}

function safeExtension(filename) {
  return filename.toLowerCase().match(/\.([a-z0-9]{1,8})$/)?.[1] || 'bin';
}

function baseName(filename) {
  return filename.replace(/\.[^.]+$/, '') || 'audio';
}

function formatBytes(bytes) {
  if (bytes < 1024) return `${bytes} B`;
  if (bytes < 1024 ** 2) return `${(bytes / 1024).toFixed(1)} KB`;
  return `${(bytes / 1024 ** 2).toFixed(1)} MB`;
}

function formatDuration(ms) {
  const seconds = Math.max(0, Math.round(ms / 1000));
  const minutes = Math.floor(seconds / 60);
  const rest = seconds % 60;
  return `${minutes}:${String(rest).padStart(2, '0')}`;
}

function normalizeError(error) {
  if (error instanceof Error) return error.message;
  return String(error);
}

for (const button of elements.modeButtons) {
  button.addEventListener('click', () => setMode(button.dataset.mode));
}
elements.fileInput.addEventListener('change', () => handleFile(elements.fileInput.files?.[0]));
elements.convertButton.addEventListener('click', convert);

for (const eventName of ['dragenter', 'dragover']) {
  elements.dropZone.addEventListener(eventName, (event) => {
    event.preventDefault();
    elements.dropZone.classList.add('dragging');
  });
}
for (const eventName of ['dragleave', 'drop']) {
  elements.dropZone.addEventListener(eventName, (event) => {
    event.preventDefault();
    elements.dropZone.classList.remove('dragging');
  });
}
elements.dropZone.addEventListener('drop', (event) => handleFile(event.dataTransfer?.files?.[0]));
window.addEventListener('beforeunload', () => {
  if (state.resultUrl) URL.revokeObjectURL(state.resultUrl);
});

setMode('audio-to-slk');
