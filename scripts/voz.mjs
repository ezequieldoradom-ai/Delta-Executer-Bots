// Genera la voz en off de un video con ElevenLabs (voz "Dan", eleven_v4)
// y guarda el audio + los tiempos de cada palabra para los subtítulos.
//
// Uso:  node scripts/voz.mjs guiones/mi-video.txt mi-video
// Crea: public/mi-video.mp3 y public/mi-video.words.json
//
// La clave se lee de ELEVENLABS_API_KEY. En la sesión de Claude Code en la
// nube no hace falta: el proxy de red la añade a cada petición.
import fs from 'node:fs';
import path from 'node:path';

const VOICE_ID = '9F4C8ztpNUmXkdDDbz3J'; // Dan - Upbeat, Dynamic and Friendly (es)
const MODEL_ID = 'eleven_v4';

const [, , scriptPath, name] = process.argv;
if (!scriptPath || !name) {
  console.error('Uso: node scripts/voz.mjs <guion.txt> <nombre>');
  process.exit(1);
}
const text = fs.readFileSync(scriptPath, 'utf8').trim();

const res = await fetch(
  `https://api.elevenlabs.io/v1/text-to-speech/${VOICE_ID}/with-timestamps?output_format=mp3_44100_192`,
  {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'xi-api-key': process.env.ELEVENLABS_API_KEY ?? 'proxy-injected',
    },
    body: JSON.stringify({text, model_id: MODEL_ID}),
  },
);
if (!res.ok) {
  console.error(`ElevenLabs ${res.status}: ${await res.text()}`);
  process.exit(1);
}
const data = await res.json();

// Agrupa los caracteres en palabras con su inicio y fin (segundos)
const a = data.normalized_alignment ?? data.alignment;
const words = [];
let cur = null;
a.characters.forEach((ch, i) => {
  if (/\s/.test(ch)) {
    cur = null;
    return;
  }
  if (!cur) {
    cur = {text: '', start: a.character_start_times_seconds[i], end: 0};
    words.push(cur);
  }
  cur.text += ch;
  cur.end = a.character_end_times_seconds[i];
});

const outDir = path.join(path.dirname(new URL(import.meta.url).pathname), '..', 'public');
fs.writeFileSync(path.join(outDir, `${name}.mp3`), Buffer.from(data.audio_base64, 'base64'));
fs.writeFileSync(path.join(outDir, `${name}.words.json`), JSON.stringify(words, null, 1));
console.log(`OK: public/${name}.mp3 (${words.length} palabras, ${words.at(-1)?.end.toFixed(1)} s)`);
