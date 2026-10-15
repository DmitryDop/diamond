import { readFile, writeFile } from 'node:fs/promises';
import { optimize } from './.svg-tools/node_modules/svgo/lib/svgo.js';

const original = await readFile(new URL('./checkpoints/2026-10-15-logo-favicon/logo-original.svg', import.meta.url), 'utf8');
const unclipped = original.replace(/<g clip-path="[^"]+">/, '').replace('</g>', '').replace(/<defs>[\s\S]*?<\/defs>/, '').replace('fill="none"', 'fill="white"');
// Keep paths separate: merging touching outlines changes edge antialiasing in Chrome.
const settings = { multipass: true, floatPrecision: 4, plugins: [{ name: 'preset-default', params: { overrides: { mergePaths: false } } }] };
for (const [name, source] of [['clipped', original], ['optimized', unclipped]]) {
  const { data } = optimize(source, settings);
  if (!data.includes('viewBox="0 0 203 48"')) throw new Error('Logo viewBox changed');
  await writeFile(new URL(`./logo-${name}.svg`, import.meta.url), data);
  console.log(`${name}: ${Buffer.byteLength(data)} bytes (original ${Buffer.byteLength(original)} bytes)`);
}
