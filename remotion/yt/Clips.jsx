import React from 'react';
import {AbsoluteFill, Freeze, OffthreadVideo, Sequence, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {BACK, BigText, C, FONT, Pill, lin, r} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import W20000 from '../../public/yt-20000.words.json';
import WFOSA from '../../public/yt-fosa.words.json';

// Shorts sacados de los vídeos largos ya renderizados (sin volver a generarlos).
// Cada short une fragmentos del vídeo original y termina antes de la respuesta.

const END_CARD = 4.5; // segundos de pantalla final pidiendo ver el vídeo completo
const CROP = 860 / 1080; // recorta los subtítulos pequeños del vídeo original

const remapWords = (words, segments) => {
  const out = [];
  let acc = 0;
  for (const [a, b] of segments) {
    for (const w of words) {
      if (w.start >= a - 0.01 && w.end <= b + 0.05) out.push({...w, start: w.start - a + acc, end: w.end - a + acc});
    }
    acc += b - a;
  }
  return out;
};

const clipLength = (segments) => segments.reduce((s, [a, b]) => s + (b - a), 0);

const Feed = ({src, segments, fps, blur = false}) => {
  let acc = 0;
  const last = segments[segments.length - 1];
  const total = clipLength(segments);
  const style = blur
    ? {position: 'absolute', height: 1920, width: 3413, left: -1166, top: 0, filter: 'blur(40px) brightness(0.45) saturate(1.3)'}
    : {position: 'absolute', width: 1080, height: 608, left: 0, top: 0};
  return (
    <>
      {segments.map(([a, b], i) => {
        const from = Math.round(acc * fps);
        acc += b - a;
        return (
          <Sequence key={i} from={from} durationInFrames={Math.round((b - a) * fps)} layout="none">
            <OffthreadVideo src={src} trimBefore={Math.round(a * fps)} muted={blur} style={style} />
          </Sequence>
        );
      })}
      <Sequence from={Math.round(total * fps)} layout="none">
        <Freeze frame={0}>
          <OffthreadVideo src={src} trimBefore={Math.round((last[1] - 0.05) * fps)} muted style={style} />
        </Freeze>
      </Sequence>
    </>
  );
};

export const ClipShort = ({src, words, segments, chip, hook, hookSub, question, accent = C.accent}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const total = clipLength(segments);
  const end = t >= total;
  const k = lin(t, total, total + 0.4, 0, 1);
  const chunks = chunkWords(remapWords(words, segments), [], 4, 22);
  const tap = t > total + 2.6 && t < total + 2.9 ? 0.92 : 1;
  return (
    <AbsoluteFill style={{background: '#05060f', overflow: 'hidden'}}>
      <Feed src={src} segments={segments} fps={fps} blur />
      {/* Vídeo principal, recortado para quitar los subtítulos originales */}
      <div
        style={{
          position: 'absolute',
          top: 640,
          left: 0,
          width: 1080,
          height: 608 * CROP,
          overflow: 'hidden',
          borderTop: `6px solid ${accent}`,
          borderBottom: `6px solid ${accent}`,
          boxShadow: '0 30px 80px rgba(0,0,0,0.6)',
          filter: end ? `blur(${k * 10}px) brightness(${1 - k * 0.5})` : 'none',
        }}
      >
        <Feed src={src} segments={segments} fps={fps} />
      </div>

      {/* Cabecera */}
      <div style={{position: 'absolute', top: 170, left: 0, right: 0, display: 'flex', justifyContent: 'center', opacity: 1 - k}}>
        <Pill color="rgba(255,255,255,0.14)" text="#fff" size={34} style={{border: '2px solid rgba(255,255,255,0.3)'}}>
          {chip}
        </Pill>
      </div>
      <div style={{position: 'absolute', top: 270, left: 40, right: 40, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 10, opacity: 1 - k, scale: String(r(t, 0, 0.5, 0.8, 1, BACK))}}>
        <BigText size={92} color={accent}>
          {hook}
        </BigText>
        <BigText size={50}>{hookSub}</BigText>
      </div>

      {!end ? <Captions chunks={chunks} top={1200} width={980} fontSize={80} /> : null}

      {/* Pantalla final: déjales con la duda */}
      {end ? (
        <AbsoluteFill style={{background: `rgba(5,6,15,${k * 0.55})`}}>
          <div style={{position: 'absolute', top: 260, left: 40, right: 40, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16, scale: String(r(t, total, total + 0.5, 0.6, 1, BACK)), opacity: k}}>
            <BigText size={question.length > 14 ? 96 : 120} color={accent}>
              {question}
            </BigText>
          </div>
          <div style={{position: 'absolute', top: 1180, left: 40, right: 40, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 22, opacity: lin(t, total + 0.6, total + 1, 0, 1), scale: String(r(t, total + 0.6, total + 1.1, 0.7, 1, BACK))}}>
            <BigText size={64}>LA RESPUESTA, EN EL</BigText>
            <div style={{display: 'flex', alignItems: 'center', gap: 18, background: '#dc2626', borderRadius: 999, padding: '20px 44px', fontFamily: FONT, fontWeight: 900, fontSize: 64, color: '#fff', boxShadow: `0 0 ${40 + 20 * Math.sin(t * 6)}px #dc2626`, scale: String(tap)}}>
              <svg width={64} height={64} viewBox="0 0 24 24">
                <path d="M7 4.5v15l12-7.5z" fill="#fff" />
              </svg>
              VÍDEO COMPLETO
            </div>
            <BigText size={56} color={C.accent}>
              YOUTUBE · @aprendedconmigo
            </BigText>
            <Pill color="#fff" size={40}>
              ENLACE EN MI PERFIL
            </Pill>
          </div>
        </AbsoluteFill>
      ) : null}
    </AbsoluteFill>
  );
};

// ---------- Short 1: ¿Qué pasaría si despertaras hace 20.000 años? ----------
const SEG_20000 = [
  [333.15, 368.6], // la gran pregunta + por qué no podrías inventar la agricultura
  [394.0, 398.72], // "Pero hay una cosa que sí sabes. Algo que nadie en ese mundo sabe." -> corte
];
export const SHORT_20000_DURATION = clipLength(SEG_20000) + END_CARD;
export const Short20000 = () => (
  <ClipShort
    src={staticFile('clips/20000.mp4')}
    words={W20000}
    segments={SEG_20000}
    chip="FRAGMENTO · HACE 20.000 AÑOS"
    hook="¿PODRÍAS CAMBIAR LA HISTORIA?"
    hookSub="Despiertas en plena Edad de Hielo…"
    question="¿QUÉ SABES TÚ QUE NADIE MÁS SABE?"
  />
);

// ---------- Short 2: ¿Qué pasaría si bajaras a la Fosa de las Marianas? ----------
const SEG_FOSA = [
  [330.3, 384.2], // el fondo, el Everest, la presión y el crujido del casco -> corte
];
export const SHORT_FOSA_DURATION = clipLength(SEG_FOSA) + END_CARD;
export const ShortFosa = () => (
  <ClipShort
    src={staticFile('clips/fosa.mp4')}
    words={WFOSA}
    segments={SEG_FOSA}
    chip="FRAGMENTO · FOSA DE LAS MARIANAS"
    hook="−10.900 METROS"
    hookSub="El punto más profundo del planeta"
    question="¿SOBREVIVIRÍAS?"
    accent="#5ee7ff"
  />
);

// ---------- Short 3: ¿Qué pasaría si pudieras ver 5 segundos en el futuro? ----------
import WFUT from '../../public/yt-futuro.words.json';
const SEG_FUT = [
  [0, 13.85], // el vaso que ya has visto romperse… y lo atrapas
  [17.35, 19.95], // "puedes ver cinco segundos en el futuro"
  [31.45, 38.1], // "…algo que te va a dejar helado: tú ya puedes hacerlo" -> corte
];
export const SHORT_FUT_DURATION = clipLength(SEG_FUT) + END_CARD;
export const ShortFuturo = () => (
  <ClipShort
    src={staticFile('clips/futuro.mp4')}
    words={WFUT}
    segments={SEG_FUT}
    chip="FRAGMENTO · 5 SEGUNDOS EN EL FUTURO"
    hook="¿VER EL FUTURO?"
    hookSub="Tienes 5 segundos de ventaja…"
    question="¿CÓMO ES POSIBLE?"
    accent="#5ee7ff"
  />
);
