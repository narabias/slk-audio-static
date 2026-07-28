import { cp, mkdir, stat } from 'node:fs/promises';
import { dirname, resolve } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = resolve(dirname(fileURLToPath(import.meta.url)), '..');

const copies = [
  ['node_modules/silk-wasm/lib/index.mjs', 'vendor/silk/index.mjs'],
  ['node_modules/silk-wasm/lib/silk.wasm', 'vendor/silk/silk.wasm'],
  ['node_modules/@ffmpeg/ffmpeg/dist/umd/ffmpeg.js', 'vendor/ffmpeg/ffmpeg.js'],
  ['node_modules/@ffmpeg/ffmpeg/dist/umd/814.ffmpeg.js', 'vendor/ffmpeg/814.ffmpeg.js'],
  ['node_modules/@ffmpeg/core/dist/umd/ffmpeg-core.js', 'vendor/ffmpeg/ffmpeg-core.js'],
  ['node_modules/@ffmpeg/core/dist/umd/ffmpeg-core.wasm', 'vendor/ffmpeg/ffmpeg-core.wasm'],
];

const optionalLicenses = [
  ['node_modules/silk-wasm/LICENSE', 'vendor/licenses/silk-wasm-LICENSE.txt'],
  ['node_modules/@ffmpeg/ffmpeg/LICENSE', 'vendor/licenses/ffmpeg-wrapper-LICENSE.txt'],
  ['node_modules/@ffmpeg/core/LICENSE', 'vendor/licenses/ffmpeg-core-LICENSE.txt'],
];

async function copyFile(fromRelative, toRelative, required = true) {
  const from = resolve(root, fromRelative);
  const to = resolve(root, toRelative);
  try {
    await stat(from);
  } catch {
    if (required) throw new Error(`缺少依赖文件：${fromRelative}`);
    return;
  }
  await mkdir(dirname(to), { recursive: true });
  await cp(from, to);
  console.log(`copied ${toRelative}`);
}

for (const [from, to] of copies) await copyFile(from, to, true);
for (const [from, to] of optionalLicenses) await copyFile(from, to, false);
console.log('Vendor files are ready.');
