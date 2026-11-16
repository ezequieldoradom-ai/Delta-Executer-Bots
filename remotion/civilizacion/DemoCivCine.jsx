import React from 'react';
import {AbsoluteFill, interpolate, random, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Audio} from '@remotion/media';
import {BigText, C, FONT, INOUT, Pill, lin, r} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Hud, IslandWorld, Ocean, Villager} from './Island';
import {Landmarks, SPOTS} from './Landmarks';
import {Ship, Wall} from './Dia05';
import WORDS from '../../public/civilizacion-05.words.json';

// Prueba: La civilización en estilo cinematográfico (escena nocturna del Día 5)
const A0 = 38.0; // segundo del audio original donde empieza la prueba
const A1 = 50.6;
export const DEMO_CIV_DURATION = A1 - A0 + 0.6;
const W = WORDS.filter((w) => w.start >= A0 - 0.01 && w.end <= A1 + 0.05).map((w) => ({...w, start: w.start - A0, end: w.end - A0}));
const CHUNKS = chunkWords(W, ['dylan', 'horizonte', 'velas', 'negras', 'débil', 'sur'], 4, 22);
const at = (word, after = 0) => W.find((w) => w.start >= after && w.text.toLowerCase().replace(/[^a-záéíóúñ]/g, '') === word).start;

const BIG = 1.35;
const WALL_RX = 450 * BIG - 40;
const WALL_RY = 300 * BIG - 34;
const TOWERS = Array.from({length: 8})
  .map((_, i) => (i / 8) * Math.PI * 2 - Math.PI / 2)
  .filter((a) => {
    const n = (a + Math.PI * 2) % (Math.PI * 2);
    return !(n > Math.PI * 0.38 && n < Math.PI * 0.62);
  });
const GAP = {x: 540, y: 975 + WALL_RY};

// Cámara por fotogramas clave: [segundo, zoom, foco x, foco y]
const KEYS = () => [
  [0, 0.78, 540, 1000],
  [at('dylan') + 0.1, 0.8, 540, 980],
  [at('horizonte') + 0.4, 1.75, SPOTS.dylanRock.x, SPOTS.dylanRock.y - 30],
  [at('velas') + 0.2, 1.6, SPOTS.dylanRock.x, SPOTS.dylanRock.y],
  [at('entonces') + 0.2, 0.85, 540, 1480],
  [at('punto') + 0.1, 1.45, GAP.x, GAP.y],
  [A1 - A0 + 0.6, 1.55, GAP.x, GAP.y + 10],
];
const camAt = (t) => {
  const k = KEYS();
  for (let i = 0; i < k.length - 1; i++) {
    if (t <= k[i + 1][0]) {
      const p = r(t, k[i][0], k[i + 1][0], 0, 1, INOUT);
      return [0, 1, 2, 3].map((j) => (j === 0 ? 0 : k[i][j] + (k[i + 1][j] - k[i][j]) * p));
    }
  }
  return k[k.length - 1];
};

const Torch = ({x, y, t, i}) => {
  const f = 1 + Math.sin(t * 15 + i) * 0.12 + Math.sin(t * 7.7 + i * 2) * 0.08;
  return (
    <g transform={`translate(${x} ${y})`}>
      <circle r={110 * f} fill="url(#torchGlow)" style={{mixBlendMode: 'screen'}} />
      <rect x={-3} y={-6} width={6} height={30} fill="#5a3a1a" />
      <g transform={`scale(1 ${f})`}>
        <path d="M-9 -4 C-12 -18 -3 -24 0 -36 C4 -24 12 -18 9 -4 Z" fill="#ff8a1a" />
        <path d="M-4 -4 C-6 -12 -1 -16 0 -24 C2 -16 6 -12 4 -4 Z" fill="#ffe27a" />
      </g>
    </g>
  );
};

const Embers = ({t}) => (
  <g>
    {TOWERS.flatMap((a, ti) =>
      Array.from({length: 5}).map((_, i) => {
        const x0 = 540 + Math.cos(a) * WALL_RX;
        const y0 = 975 + Math.sin(a) * WALL_RY - 70;
        const u = ((t * (0.35 + random(`eu${ti}${i}`) * 0.3) + random(`eo${ti}${i}`)) % 1);
        return <circle key={`${ti}-${i}`} cx={x0 + Math.sin(t * 2 + i) * 14 + (random(`ex${ti}${i}`) - 0.5) * 30} cy={y0 - u * 160} r={1.6 + random(`er${ti}${i}`) * 2} fill="#ffc46b" opacity={(1 - u) * 0.9} />;
      }),
    )}
  </g>
);

const Fog = ({t}) => (
  <g style={{filter: 'blur(28px)'}}>
    {Array.from({length: 7}).map((_, i) => (
      <ellipse key={i} cx={((i * 380 + t * (14 + i * 3)) % 1800) - 300} cy={500 + i * 230} rx={420} ry={60} fill="#b8c8ff" opacity={0.08} />
    ))}
  </g>
);

const World = ({t}) => {
  const [, zoom, fx, fy] = camAt(t);
  const sx = Math.sin(t * 1.2) * 5 + Math.sin(t * 2.9) * 2;
  const sy = Math.cos(t * 1.0) * 4 + Math.sin(t * 2.3) * 2;
  const vel = at('velas');
  const weak = at('punto');
  const pulse = t > weak - 0.2 ? 0.5 + 0.5 * Math.sin(t * 7) : 0;
  return (
    <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
      <defs>
        <radialGradient id="torchGlow">
          <stop offset="0" stopColor="#ffb347" stopOpacity="0.55" />
          <stop offset="0.4" stopColor="#ff7a1a" stopOpacity="0.18" />
          <stop offset="1" stopColor="#ff7a1a" stopOpacity="0" />
        </radialGradient>
        <radialGradient id="redGlow">
          <stop offset="0" stopColor={C.red} stopOpacity="0.6" />
          <stop offset="1" stopColor={C.red} stopOpacity="0" />
        </radialGradient>
        <radialGradient id="lantern">
          <stop offset="0" stopColor="#ff5a36" stopOpacity="0.7" />
          <stop offset="1" stopColor="#ff5a36" stopOpacity="0" />
        </radialGradient>
      </defs>
      <g transform={`translate(${540 + sx} ${960 + sy}) scale(${zoom}) translate(${-fx} ${-fy})`}>
        <g transform="translate(-540 -960) scale(2)">
          <Ocean t={t} night={1} />
        </g>
        {/* Reflejo de la luna en el agua */}
        {Array.from({length: 26}).map((_, i) => (
          <rect key={i} x={860 + Math.sin(t * 2 + i) * 30 - i * 4} y={-200 + i * 34} width={120 - i * 2 + Math.sin(t * 3 + i) * 30} height={5} rx={3} fill="#e8f0ff" opacity={0.25 * (1 - i / 26)} />
        ))}
        <IslandWorld t={t} pop={265} maxShown={70} size={BIG}>
          <Landmarks t={t} rock={false} />
        </IslandWorld>
        <Wall k={1} night={1} />
        {/* Noche: oscurecemos todo menos las luces */}
        <rect x={-1500} y={-1500} width={4200} height={5000} fill="#06103a" opacity={0.5} style={{mixBlendMode: 'multiply'}} />
        <rect x={-1500} y={-1500} width={4200} height={5000} fill="#0a1450" opacity={0.25} />
        <circle cx={540} cy={1000} r={140} fill="url(#torchGlow)" style={{mixBlendMode: 'screen'}} />
        {TOWERS.map((a, i) => (
          <Torch key={i} i={i} t={t} x={540 + Math.cos(a) * WALL_RX} y={975 + Math.sin(a) * WALL_RY - 50} />
        ))}
        <Embers t={t} />
        <ellipse cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y + 4} rx={30} ry={12} fill="#9aa3b8" />
        <circle cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y - 40} r={90} fill="#a78bfa" opacity={0.18 + 0.06 * Math.sin(t * 4)} style={{filter: 'blur(14px)'}} />
        <Villager x={SPOTS.dylanRock.x} y={SPOTS.dylanRock.y} t={t} seed={7} s={1.7} shirt="#a78bfa" crown wave={50} />
        {/* Barcos con farolillos rojos acercándose por el sur */}
        {[0, 1, 2].map((k) => {
          const x = 300 + k * 240;
          const y = lin(t, 0, A1 - A0 + 0.6, 1780, 1660) - (k % 2) * 50;
          return (
            <g key={k} opacity={lin(t, vel - 1.2, vel - 0.2, 0.35, 1)}>
              <circle cx={x + 40} cy={y - 10} r={70} fill="url(#lantern)" style={{mixBlendMode: 'screen'}} />
              <Ship x={x} y={y + Math.sin(t * 2 + k) * 5} s={0.8} o={0.95} />
              <circle cx={x + 50} cy={y - 8} r={6} fill="#ffb08a" />
            </g>
          );
        })}
        {pulse > 0 ? (
          <g>
            <circle cx={GAP.x} cy={GAP.y} r={200} fill="url(#redGlow)" opacity={pulse} style={{mixBlendMode: 'screen'}} />
            <ellipse cx={GAP.x} cy={GAP.y} rx={110} ry={50} fill="none" stroke={C.red} strokeWidth={8} opacity={0.4 + 0.6 * pulse} />
          </g>
        ) : null}
        <Fog t={t} />
      </g>
    </svg>
  );
};

export const DemoCivCine = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const grain = Math.floor(frame / 2);
  const weak = at('punto');
  return (
    <AbsoluteFill style={{background: '#020414', overflow: 'hidden'}}>
      <World t={t} />
      {/* Profundidad de campo: copia desenfocada arriba y abajo (efecto miniatura) */}
      <AbsoluteFill style={{filter: 'blur(9px)', WebkitMaskImage: 'linear-gradient(#000 0%, transparent 30%, transparent 66%, #000 100%)', maskImage: 'linear-gradient(#000 0%, transparent 30%, transparent 66%, #000 100%)'}}>
        <World t={t} />
      </AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <defs>
          <radialGradient id="vig" cx="0.5" cy="0.5" r="0.75">
            <stop offset="0.5" stopColor="#000" stopOpacity="0" />
            <stop offset="1" stopColor="#000" stopOpacity="0.8" />
          </radialGradient>
          <radialGradient id="moonGlow">
            <stop offset="0" stopColor="#e8f0ff" stopOpacity="0.5" />
            <stop offset="1" stopColor="#e8f0ff" stopOpacity="0" />
          </radialGradient>
          <filter id="grainC">
            <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="1" seed={grain} />
            <feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.05 0" />
          </filter>
        </defs>
        {/* Luz de luna desde arriba a la derecha */}
        <circle cx={980} cy={-40} r={520} fill="url(#moonGlow)" style={{mixBlendMode: 'screen'}} />
        <rect x={0} y={0} width={1080} height={1920} fill="#ff9a3d" opacity={0.05} style={{mixBlendMode: 'overlay'}} />
        <rect x={0} y={0} width={1080} height={1920} fill="url(#vig)" />
        <rect x={0} y={0} width={1080} height={1920} filter="url(#grainC)" />
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={265} day={5} />
      </div>
      {t > at('velas') - 0.1 && t < weak - 0.3 ? (
        <div style={{position: 'absolute', top: 400, left: 0, right: 0, display: 'flex', justifyContent: 'center', opacity: lin(t, at('velas') - 0.1, at('velas') + 0.2, 0, 1), scale: String(r(t, at('velas') - 0.1, at('velas') + 0.4, 0.7, 1))}}>
          <BigText size={88}>
            LAS VELAS NEGRAS,
            <br />
            <span style={{color: C.red}}>MÁS CERCA</span>
          </BigText>
        </div>
      ) : null}
      {t > weak - 0.1 ? (
        <div style={{position: 'absolute', top: 400, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 14, opacity: lin(t, weak - 0.1, weak + 0.15, 0, 1), scale: String(r(t, weak - 0.1, weak + 0.4, 0.7, 1))}}>
          <BigText size={110} color={C.red}>
            PUNTO DÉBIL
          </BigText>
          <Pill color="#fff" size={44}>
            LA PLAYA DEL SUR
          </Pill>
        </div>
      ) : null}
      <div style={{position: 'absolute', top: 150, left: 40, fontFamily: FONT, fontWeight: 800, fontSize: 26, color: '#fff', opacity: 0.75, letterSpacing: 3}}>PRUEBA · ESTILO CINE</div>
      <Captions chunks={CHUNKS} />
      <Audio
        src={staticFile('civilizacion-05.mp3')}
        trimBefore={Math.round(A0 * fps)}
        volume={(f) => interpolate(f / fps, [0, 0.15, A1 - A0 + 0.2, A1 - A0 + 0.5], [0, 1, 1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})}
      />
    </AbsoluteFill>
  );
};
