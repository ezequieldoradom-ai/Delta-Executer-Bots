// Genera la voz en off de un video con ElevenLabs (voz "Dan", eleven_v4)
// y guarda el audio + los tiempos de cada palabra para los subtítulos.
//
// Uso:  node scripts/voz.mjs guiones/mi-video.txt mi-video
// Crea: public/mi-video.mp3 y public/mi-video.words.json
//
// La clave se lee de ELEVENLABS_API_KEY. En la sesión de Claude Code en la
// nube no hace falta: el proxy de red la añade a cada petición.
import fs from 'node:fs';
import os from 'node:os';
import path from 'node:path';
import {execFileSync} from 'node:child_process';
import crypto from 'node:crypto';

const VOICE_ID = '9F4C8ztpNUmXkdDDbz3J'; // Dan - Upbeat, Dynamic and Friendly (es)
const MODEL_ID = 'eleven_v4';

const [, , scriptPath, name] = process.argv;
if (!scriptPath || !name) {
  console.error('Uso: node scripts/voz.mjs <guion.txt> <nombre>');
  process.exit(1);
}
const text = fs.readFileSync(scriptPath, 'utf8').trim();

// Los textos largos se generan por trozos (párrafos) y luego se unen
const MAX = 1500;
const chunks = [];
for (const para of text.split(/\n\s*\n/)) {
  const last = chunks[chunks.length - 1];
  if (last && last.length + para.length + 2 <= MAX) chunks[chunks.length - 1] = `${last}\n\n${para}`;
  else chunks.push(para);
}

const tts = async (part, prev, attempt = 1) => {
  const res = await fetch(
    `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}/with-timestamps?output_format=mp3_44100_192`,
    {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        'xi-api-key': process.env.ELEVENLABS_API_KEY ?? 'proxy-injected',
      },
      body: JSON.stringify({text: part, model_id: MODEL_ID, ...(prev ? {previous_text: prev} : {})}),
    },
  );
  if (!res.ok) {
    const msg = `ElevenLabs ${res.status}: ${await res.text()}`;
    if (res.status >= 500 && attempt < 4) {
      console.error(`${msg} · reintento ${attempt}`);
      await new Promise((ok) => setTimeout(ok, 3000 * attempt));
      return tts(part, prev, attempt + 1);
    }
    console.error(msg);
    process.exit(1);
  }
  return res.json();
};

const ff = (args) => execFileSync('npx', ['remotion', ...args], {encoding: 'utf8'}).trim();
const tmp = fs.mkdtempSync(path.join(os.tmpdir(), 'voz-'));
// Caché por trozo: si el texto de un trozo no cambia, no se vuelve a pagar
const cacheDir = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'out', 'voz-cache', name);
fs.mkdirSync(cacheDir, {recursive: true});
const keyOf = (part) => crypto.createHash('sha1').update(`${VOICE_ID}|${MODEL_ID}|${part}`).digest('hex').slice(0, 16);

const words = [];
const files = [];
let offset = 0;
for (let c = 0; c < chunks.length; c++) {
  const key = keyOf(chunks[c]);
  const file = path.join(cacheDir, `${key}.mp3`);
  const meta = path.join(cacheDir, `${key}.json`);
  if (!fs.existsSync(file) || !fs.existsSync(meta)) {
    const data = await tts(chunks[c], chunks[c - 1]);
    fs.writeFileSync(file, Buffer.from(data.audio_base64, 'base64'));
    // Agrupa los caracteres en palabras con su inicio y fin (segundos)
    const a = data.normalized_alignment ?? data.alignment;
    const local = [];
    let cur = null;
    a.characters.forEach((ch, i) => {
      if (/\s/.test(ch)) {
        cur = null;
        return;
      }
      if (!cur) {
        cur = {text: '', start: a.character_start_times_seconds[i], end: 0};
        local.push(cur);
      }
      cur.text += ch;
      cur.end = a.character_end_times_seconds[i];
    });
    const duration = Number(ff(['ffprobe', '-v', 'error', '-show_entries', 'format=duration', '-of', 'csv=p=0', file]));
    fs.writeFileSync(meta, JSON.stringify({words: local, duration}));
    console.log(`Parte ${c + 1}/${chunks.length} generada`);
  } else {
    console.log(`Parte ${c + 1}/${chunks.length} reutilizada (sin coste)`);
  }
  const {words: local, duration} = JSON.parse(fs.readFileSync(meta, 'utf8'));
  for (const w of local) words.push({...w, start: w.start + offset, end: w.end + offset});
  files.push(file);
  offset += duration;
}

const outDir = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'public');
const outMp3 = path.join(outDir, `${name}.mp3`);
if (files.length === 1) fs.copyFileSync(files[0], outMp3);
else {
  const list = path.join(tmp, 'lista.txt');
  fs.writeFileSync(list, files.map((f) => `file '${f}'`).join('\n'));
  ff(['ffmpeg', '-y', '-loglevel', 'error', '-f', 'concat', '-safe', '0', '-i', list, '-c', 'copy', outMp3]);
}
fs.writeFileSync(path.join(outDir, `${name}.words.json`), JSON.stringify(words, null, 1));
console.log(`OK: public/${name}.mp3 (${words.length} palabras, ${words.at(-1)?.end.toFixed(1)} s)`);
