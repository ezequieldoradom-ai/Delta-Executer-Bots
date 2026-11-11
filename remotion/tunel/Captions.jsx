import React from 'react';
import {AbsoluteFill, useCurrentFrame, useVideoConfig} from 'remotion';
import {BACK, C, FONT, lin, r} from './lib';
import {CHUNKS as TUNEL_CHUNKS} from './timing';

// Subtítulos estilo TikTok: bloques cortos, palabra activa resaltada
export const Captions = ({chunks: CHUNKS = TUNEL_CHUNKS}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;

  const idx = CHUNKS.findIndex((c, i) => {
    const next = CHUNKS[i + 1];
    return t >= c.start && t < (next ? Math.min(next.start, c.end + 0.6) : c.end);
  });
  if (idx === -1) {
    return null;
  }
  const chunk = CHUNKS[idx];
  const enter = r(t, chunk.start, chunk.start + 0.25, 0, 1, BACK);

  return (
    <AbsoluteFill style={{justifyContent: 'flex-start', alignItems: 'center'}}>
      <div
        style={{
          position: 'absolute',
          top: 1430,
          width: 960,
          display: 'flex',
          flexWrap: 'wrap',
          justifyContent: 'center',
          columnGap: 30,
          rowGap: 4,
          scale: String(0.85 + 0.15 * enter),
          opacity: lin(t, chunk.start, chunk.start + 0.08, 0, 1),
        }}
      >
        {chunk.words.map((w, i) => {
          const active = t >= w.start && t < w.end;
          const said = t >= w.start;
          const color = active ? C.accent : w.strong && said ? C.cyan : C.white;
          return (
            <span
              key={i}
              style={{
                fontFamily: FONT,
                fontWeight: 900,
                fontSize: 82,
                lineHeight: 1.12,
                textTransform: 'uppercase',
                color,
                opacity: said ? 1 : 0.55,
                WebkitTextStroke: '10px #05060f',
                paintOrder: 'stroke fill',
                textShadow: '0 8px 30px rgba(0,0,0,0.55)',
                scale: active ? String(r(t, w.start, w.start + 0.15, 1.08, 1.03)) : '1',
                display: 'inline-block',
              }}
            >
              {w.text}
            </span>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

// Convierte palabras con tiempos ({text,start,end}) en bloques de subtítulos.
// `strong`: palabras (en minúscula, sin signos) que se destacan en color.
export const chunkWords = (words, strong = [], maxWords = 4, maxChars = 22) => {
  const clean = (w) => w.toLowerCase().replace(/[^a-záéíóúñü0-9]/gi, '');
  const chunks = [];
  let cur = [];
  const flush = () => {
    if (cur.length) chunks.push(cur);
    cur = [];
  };
  words.forEach((w, i) => {
    const len = cur.reduce((a, x) => a + x.text.length + 1, 0) + w.text.length;
    const prev = words[i - 1];
    const pause = prev && w.start - prev.end > 0.35;
    if (cur.length && (cur.length >= maxWords || len > maxChars || pause)) flush();
    cur.push({...w, strong: strong.includes(clean(w.text))});
    if (/[.?!:…]$/.test(w.text)) flush();
  });
  flush();
  return chunks.map((ws, i) => ({
    words: ws,
    start: ws[0].start,
    end: i < chunks.length - 1 ? ws[ws.length - 1].end : ws[ws.length - 1].end + 0.6,
  }));
};
