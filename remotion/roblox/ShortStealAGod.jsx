import React from 'react';
import {AbsoluteFill, Audio, Img, OffthreadVideo, Sequence, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {BACK, BigText, C, FONT, Pill, lin, r} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import WORDS from '../../public/sag-short-01.words.json';

// Short promocional de Steal a God (vertical 1080×1920, 60 fps, ~23 s).
// Guion: guiones/sag-short-01.txt · voz: public/sag-short-01.mp3 (npm run voz)
// Imágenes: grabaciones reales del juego en public/sag/clips/clipN_*.mp4 (las graba Shadow en Studio).
// Mientras no estén (CLIPS = false), cada escena usa una imagen del juego con movimiento de cámara.
// Estilo cinematográfico de la casa: cámara viva (zoom lento + mano), viñeta, grano suave y tono cálido.

export const CLIPS = false;

const VOICE_AT = 0.85; // la voz entra tras el "HEY!!" del Minotauro
const END_HOLD = 2.8; // pantalla final
const VOICE_LEN = WORDS[WORDS.length - 1].end;
export const SAG_SHORT_DURATION = VOICE_AT + VOICE_LEN + END_HOLD;

const W = WORDS.map((w) => ({...w, start: w.start + VOICE_AT, end: w.end + VOICE_AT}));
const clean = (s) => s.toLowerCase().replace(/[¿¡!?.,…:]/g, '');
// inicio de la primera palabra que empieza por `word` después del segundo `after`
const at = (word, after = 0) => W.find((w) => w.start > after && clean(w.text).startsWith(word)).start;
const CHUNKS = chunkWords(W, ['dios', 'guardián', 'suerte', 'legendaria', 'mutado', 'olimpo', 'premio', 'steal', 'god'], 4, 22);

// Escenas: clip (grabación real) o imagen provisional, encuadre horizontal y cortes en cada frase de la voz
const CUT_GUARD = at('y'); // "y su guardián vino a por mí"
const CUT_OPEN = at('pero'); // "Pero al abrirlo…"
const CUT_MUT = at('encima') - 0.25; // "¡Y encima salió mutado!"
const CUT_OLY = at('y', CUT_MUT + 0.5); // "Y en la cima del Olimpo…"
const CUT_END = at('búscalo'); // "Búscalo en Roblox…"
const SCENES = [
  {from: 0, to: CUT_GUARD, clip: 'clip1_robo.mp4', img: 'principal.jpg', pos: '50%'},
  {from: CUT_GUARD, to: CUT_OPEN, clip: 'clip2_huida.mp4', img: 'plaza.png', pos: '50%'},
  {from: CUT_OPEN, to: CUT_MUT, clip: 'clip3_apertura.mp4', img: 'etapa.png', pos: '50%'},
  {from: CUT_MUT, to: CUT_OLY, clip: 'clip4_mutacion.mp4', img: 'mutaciones.jpg', pos: '62%'},
  {from: CUT_OLY, to: CUT_END, clip: 'clip5_olimpo.mp4', img: 'isla.png', pos: '50%'},
  {from: CUT_END, to: SAG_SHORT_DURATION, clip: 'clip6_plaza.mp4', img: 'plaza.png', pos: '50%', end: true},
];

// Cámara viva: zoom lento + temblor suave de cámara en mano
const camera = (t, from, to, seed = 1) => {
  const k = (t - from) / Math.max(0.01, to - from);
  const zoom = 1.06 + 0.1 * k;
  const x = Math.sin(t * 1.3 + seed) * 6 + Math.sin(t * 3.1 + seed * 2) * 2;
  const y = Math.cos(t * 1.1 + seed) * 5 + Math.sin(t * 2.7 + seed) * 2;
  return `translate(${x}px, ${y}px) scale(${zoom})`;
};

const Shot = ({s, i}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps + s.from;
  const fadeIn = lin(t, s.from, s.from + 0.12, 0, 1);
  const style = {position: 'absolute', width: '100%', height: '100%', objectFit: 'cover', objectPosition: `${s.pos} 50%`, transform: camera(t, s.from, s.to, i + 1)};
  return (
    <AbsoluteFill style={{opacity: fadeIn, filter: s.end ? `blur(${lin(t, s.from, s.from + 0.4, 0, 14)}px) brightness(${lin(t, s.from, s.from + 0.4, 1, 0.55)})` : 'none'}}>
      {CLIPS ? (
        <OffthreadVideo src={staticFile(`sag/clips/${s.clip}`)} muted playbackRate={1} style={style} />
      ) : (
        <Img src={staticFile(`sag/${s.img}`)} style={style} />
      )}
    </AbsoluteFill>
  );
};

// Destello blanco en cada corte
const Flash = ({t}) => {
  let a = 0;
  for (const s of SCENES) {
    if (s.from > 0) a = Math.max(a, lin(t, s.from, s.from + 0.18, 0.55, 0) * (t >= s.from ? 1 : 0));
  }
  return a > 0 ? <AbsoluteFill style={{background: '#fff', opacity: a}} /> : null;
};

// Viñeta, grano suave y tono cálido
const Grade = ({frame}) => (
  <AbsoluteFill style={{pointerEvents: 'none'}}>
    <AbsoluteFill style={{background: 'radial-gradient(ellipse at 50% 45%, rgba(0,0,0,0) 45%, rgba(0,0,0,0.62) 100%)'}} />
    <AbsoluteFill style={{background: 'linear-gradient(180deg, rgba(255,170,90,0.10), rgba(0,0,0,0) 40%, rgba(255,140,60,0.08))', mixBlendMode: 'soft-light'}} />
    <svg width={1080} height={1920} style={{position: 'absolute', opacity: 0.07, mixBlendMode: 'overlay'}}>
      <filter id="sagGrain">
        <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed={Math.floor(frame / 2)} />
      </filter>
      <rect width={1080} height={1920} filter="url(#sagGrain)" />
    </svg>
  </AbsoluteFill>
);

const Hook = ({t}) => {
  const s = SCENES[0];
  if (t > s.to + 0.2) return null;
  return (
    <div style={{position: 'absolute', top: 230, left: 40, right: 40, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14, scale: String(r(t, 0.05, 0.5, 0.6, 1, BACK)), opacity: lin(t, s.to - 0.1, s.to + 0.2, 1, 0)}}>
      <BigText size={118} color={C.accent}>
        ROBÉ UN DIOS
      </BigText>
      <BigText size={64}>EN ROBLOX 😱</BigText>
    </div>
  );
};

const PopWord = ({t, at: a, until, children, color = '#fff', size = 130, top = 330, rot = -4}) => {
  if (t < a || t > until) return null;
  return (
    <div style={{position: 'absolute', top, left: 0, right: 0, display: 'flex', justifyContent: 'center', rotate: `${rot}deg`, scale: String(r(t, a, a + 0.3, 0.3, 1, BACK)), opacity: lin(t, until - 0.15, until, 1, 0)}}>
      <BigText size={size} color={color}>
        {children}
      </BigText>
    </div>
  );
};

const EndCard = ({t}) => {
  const s = SCENES[5];
  if (t < s.from) return null;
  const k = lin(t, s.from, s.from + 0.4, 0, 1);
  const pulse = 1 + 0.03 * Math.sin(t * 7);
  return (
    <AbsoluteFill>
      <div style={{position: 'absolute', top: 300, left: 0, right: 0, display: 'flex', justifyContent: 'center', opacity: k, scale: String(r(t, s.from, s.from + 0.5, 0.5, 1, BACK) * pulse)}}>
        <Img src={staticFile('sag/icon.png')} style={{width: 620, height: 620, borderRadius: 64, boxShadow: '0 0 90px rgba(255,210,90,0.85), 0 30px 80px rgba(0,0,0,0.6)'}} />
      </div>
      <div style={{position: 'absolute', top: 1000, left: 40, right: 40, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 26, opacity: lin(t, s.from + 0.3, s.from + 0.7, 0, 1), scale: String(r(t, s.from + 0.3, s.from + 0.8, 0.7, 1, BACK))}}>
        <BigText size={104} color="#ffd23f" style={{whiteSpace: 'nowrap'}}>
          STEAL A GOD ⚡
        </BigText>
        <Pill color="#e11d48" text="#fff" size={58} style={{boxShadow: `0 0 ${40 + 20 * Math.sin(t * 6)}px #e11d48`}}>
          BÚSCALO EN ROBLOX
        </Pill>
        <BigText size={66}>¿QUÉ DIOS TE TOCARÁ?</BigText>
      </div>
    </AbsoluteFill>
  );
};

export const ShortStealAGod = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const endFrom = SCENES[5].from;
  return (
    <AbsoluteFill style={{background: '#05060f', overflow: 'hidden', fontFamily: FONT}}>
      {SCENES.map((s, i) => (
        <Sequence key={i} from={Math.round(s.from * fps)} durationInFrames={Math.max(1, Math.round((s.to - s.from) * fps))} layout="none">
          <Shot s={s} i={i} />
        </Sequence>
      ))}
      <Flash t={t} />
      <Grade frame={frame} />
      <Hook t={t} />
      <PopWord t={t} at={at('vino') - 0.1} until={SCENES[1].to} color="#ff5a5a" size={140}>
        ¡A VOLAR!
      </PopWord>
      <PopWord t={t} at={SCENES[3].from + 0.25} until={SCENES[3].to} color="#ffe066" size={190} top={300} rot={5}>
        x20 😳
      </PopWord>
      <PopWord t={t} at={SCENES[4].from + 0.2} until={SCENES[4].to} color="#7cf0ff" size={120} top={250} rot={0}>
        100 ETAPAS
      </PopWord>
      {t < endFrom ? <Captions chunks={CHUNKS} top={1340} width={980} fontSize={84} /> : null}
      <EndCard t={t} />
      {/* audio: grito del Minotauro, voz y la música del juego */}
      <Sequence from={0} durationInFrames={Math.round(1.1 * fps)} layout="none">
        <Audio src={staticFile('sag/shouts.ogg')} volume={1} />
      </Sequence>
      <Sequence from={Math.round(VOICE_AT * fps)} layout="none">
        <Audio src={staticFile('sag-short-01.mp3')} volume={1} />
      </Sequence>
      <Audio src={staticFile('sag/bgm.ogg')} volume={(f) => (f / fps < endFrom ? 0.22 : 0.4)} />
    </AbsoluteFill>
  );
};
