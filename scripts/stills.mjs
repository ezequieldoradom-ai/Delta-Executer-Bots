// Renderiza varios fotogramas de prueba con un solo bundle.
// Uso: node scripts/stills.mjs <Composición> <carpeta> <escala> <seg1> <seg2> ...
import {bundle} from '@remotion/bundler';
import {renderStill, selectComposition} from '@remotion/renderer';
import path from 'node:path';

const [, , id, dir, scale, ...secs] = process.argv;
const serveUrl = await bundle({entryPoint: path.resolve('remotion/index.jsx')});
const opts = {serveUrl, browserExecutable: '/opt/pw-browsers/chromium'};
const composition = await selectComposition({...opts, id});
for (const s of secs) {
  const frame = Math.min(composition.durationInFrames - 1, Math.round(Number(s) * composition.fps));
  try {
    await renderStill({...opts, composition, frame, output: `${dir}/${id}-${s}.png`, scale: Number(scale)});
    console.log('ok', s);
  } catch (e) {
    console.log('ERROR', s, e.message.split('\n')[0]);
  }
}
