import React from 'react';
import {AbsoluteFill, interpolate, random, staticFile, useCurrentFrame, useVideoConfig} from 'remotion';
import {Audio} from '@remotion/media';
import {BigText, C, FONT, INOUT, lin, r} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import WORDS from '../../public/yt-futuro.words.json';

// Demo de estilo "cinematográfico" (sin material externo): luz volumétrica,
// profundidad de campo, cámara lenta, grano, viñeta y reflejos.

const CUT = 9.95;
export const DEMO_DURATION = 11;
const FUT = '#5ee7ff';
const W = WORDS.filter((w) => w.end <= CUT + 0.05);
const CHUNKS = chunkWords(W, ['vaso', 'resbala', 'romperse', 'cristales', 'golpe'], 5, 32);
const at = (word) => W.find((w) => w.text.toLowerCase().startsWith(word)).start;

const SLIP = at('resbala');
const BREAK = at('romperse');
const FLOOR = 905;

// Trayectoria real del vaso: cae a cámara lenta y nunca llega al suelo en la demo
const realGlass = (t) => {
  if (t < SLIP) return {x: 1120, y: 470, rot: 0};
  const k = t - SLIP;
  return {x: 1120 + k * 18, y: 470 + k * k * 9, rot: k * 9};
};
// Trayectoria "futura": la misma caída en tiempo real, hasta romperse
const ghostGlass = (t) => {
  const k = Math.min(1, (t - (BREAK - 0.55)) / 0.55);
  return {x: 1120 + k * 70, y: 470 + k * k * (FLOOR - 470 - 60), rot: k * 70};
};

const Defs = () => (
  <defs>
    <linearGradient id="wall" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stopColor="#0d0b14" />
      <stop offset="0.6" stopColor="#1c1622" />
      <stop offset="1" stopColor="#120e16" />
    </linearGradient>
    <radialGradient id="lamp" cx="0.58" cy="0.05" r="0.75">
      <stop offset="0" stopColor="#ffd9a0" stopOpacity="0.55" />
      <stop offset="0.35" stopColor="#ffb866" stopOpacity="0.18" />
      <stop offset="1" stopColor="#000" stopOpacity="0" />
    </radialGradient>
    <linearGradient id="cone" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stopColor="#ffe2b0" stopOpacity="0.32" />
      <stop offset="1" stopColor="#ffe2b0" stopOpacity="0" />
    </linearGradient>
    <linearGradient id="marble" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stopColor="#3a3340" />
      <stop offset="0.5" stopColor="#4b4352" />
      <stop offset="1" stopColor="#2a2430" />
    </linearGradient>
    <linearGradient id="cabinet" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stopColor="#2c1d14" />
      <stop offset="1" stopColor="#140c08" />
    </linearGradient>
    <linearGradient id="floor" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stopColor="#24202a" />
      <stop offset="1" stopColor="#0a080c" />
    </linearGradient>
    <linearGradient id="glassBody" x1="0" y1="0" x2="1" y2="0">
      <stop offset="0" stopColor="#ffffff" stopOpacity="0.55" />
      <stop offset="0.15" stopColor="#d8f0ff" stopOpacity="0.12" />
      <stop offset="0.7" stopColor="#d8f0ff" stopOpacity="0.06" />
      <stop offset="0.9" stopColor="#ffffff" stopOpacity="0.4" />
      <stop offset="1" stopColor="#ffffff" stopOpacity="0.15" />
    </linearGradient>
    <linearGradient id="water" x1="0" y1="0" x2="0" y2="1">
      <stop offset="0" stopColor="#bfe6ff" stopOpacity="0.55" />
      <stop offset="1" stopColor="#6aa8d8" stopOpacity="0.35" />
    </linearGradient>
    <linearGradient id="skin" x1="0" y1="0" x2="1" y2="1">
      <stop offset="0" stopColor="#e9b892" />
      <stop offset="1" stopColor="#9c6a4a" />
    </linearGradient>
    <radialGradient id="vignette" cx="0.5" cy="0.5" r="0.75">
      <stop offset="0.55" stopColor="#000" stopOpacity="0" />
      <stop offset="1" stopColor="#000" stopOpacity="0.85" />
    </radialGradient>
    <filter id="bg-blur">
      <feGaussianBlur stdDeviation="7" />
    </filter>
    <filter id="soft">
      <feGaussianBlur stdDeviation="3" />
    </filter>
    <filter id="glow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur stdDeviation="10" result="b" />
      <feMerge>
        <feMergeNode in="b" />
        <feMergeNode in="SourceGraphic" />
      </feMerge>
    </filter>
  </defs>
);

const Glass = ({x, y, rot, blur = 0, ghost = false}) => (
  <g transform={`translate(${x} ${y}) rotate(${rot})`} style={ghost ? {filter: `drop-shadow(0 0 18px ${FUT})`} : undefined}>
    <g style={blur ? {filter: `blur(${blur}px)`} : undefined}>
      <path d="M-52 -80 L52 -80 L42 78 Q0 88 -42 78 Z" fill={ghost ? 'rgba(94,231,255,0.18)' : 'url(#glassBody)'} stroke={ghost ? FUT : 'rgba(255,255,255,0.75)'} strokeWidth={3} />
      {!ghost ? <path d="M-46 -6 L46 -6 L42 74 Q0 84 -42 74 Z" fill="url(#water)" /> : null}
      {!ghost ? <ellipse cx={0} cy={-6} rx={46} ry={7} fill="rgba(230,247,255,0.55)" /> : null}
      <ellipse cx={0} cy={-80} rx={52} ry={9} fill="none" stroke={ghost ? FUT : 'rgba(255,255,255,0.85)'} strokeWidth={3} />
      <path d="M-38 -66 L-31 64" stroke="#fff" strokeWidth={7} strokeLinecap="round" opacity={ghost ? 0.4 : 0.75} />
      <path d="M34 -60 L30 20" stroke="#fff" strokeWidth={3} strokeLinecap="round" opacity={0.4} />
      <ellipse cx={0} cy={78} rx={40} ry={8} fill={ghost ? FUT : 'rgba(255,255,255,0.35)'} opacity={0.6} />
    </g>
  </g>
);

const Shards = ({t}) => {
  const k = Math.max(0, t - BREAK);
  return (
    <g style={{filter: `drop-shadow(0 0 12px ${FUT})`}}>
      {Array.from({length: 26}).map((_, i) => {
        const a = -Math.PI * (0.05 + random(`a${i}`) * 0.9);
        const v = 260 + random(`v${i}`) * 520;
        const g = 1500;
        const tt = Math.min(k, 0.9);
        let x = 1190 + Math.cos(a) * v * tt;
        let y = FLOOR - 20 + Math.sin(a) * v * tt + 0.5 * g * tt * tt;
        y = Math.min(y, FLOOR + 30 + random(`f${i}`) * 90);
        const s = 0.6 + random(`s${i}`) * 1.6;
        return <path key={i} d="M0 -14 L10 8 L-9 10 Z" fill="rgba(94,231,255,0.55)" stroke="#d6fbff" strokeWidth={1.5} transform={`translate(${x} ${y}) rotate(${i * 53 + tt * 720 * (random(`r${i}`) - 0.5)}) scale(${s})`} />;
      })}
      {Array.from({length: 40}).map((_, i) => {
        const a = -Math.PI * random(`wa${i}`);
        const v = 200 + random(`wv${i}`) * 700;
        const tt = Math.min(k, 0.7);
        const x = 1190 + Math.cos(a) * v * tt;
        const y = Math.min(FLOOR - 10 + Math.sin(a) * v * tt + 750 * tt * tt, FLOOR + 40 + random(`wf${i}`) * 80);
        return <circle key={i} cx={x} cy={y} r={2 + random(`wr${i}`) * 5} fill="#bff6ff" opacity={0.7} />;
      })}
      <ellipse cx={1190} cy={FLOOR + 60} rx={lin(k, 0, 1.2, 20, 260)} ry={lin(k, 0, 1.2, 4, 46)} fill="rgba(94,231,255,0.18)" />
    </g>
  );
};

const Dust = ({t}) => (
  <g>
    {Array.from({length: 70}).map((_, i) => {
      const x = 760 + random(`dx${i}`) * 820 + Math.sin(t * 0.3 + i) * 30;
      const y = ((random(`dy${i}`) * 900 - t * (6 + random(`dv${i}`) * 10)) % 900 + 900) % 900;
      return <circle key={i} cx={x} cy={y} r={0.8 + random(`dr${i}`) * 2.2} fill="#ffe7c2" opacity={0.15 + 0.35 * random(`do${i}`) * (0.6 + 0.4 * Math.sin(t * 2 + i))} />;
    })}
  </g>
);

export const DemoCine = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  // Cámara: acercamiento lento + vaivén de cámara en mano
  const zoom = r(t, 0, CUT, 1.0, 1.22, INOUT);
  const fx = 1100 + r(t, SLIP, CUT, 0, 60, INOUT);
  const fy = 560 + r(t, SLIP, CUT, 0, 120, INOUT);
  const sx = Math.sin(t * 1.3) * 6 + Math.sin(t * 3.1) * 2;
  const sy = Math.cos(t * 1.1) * 5 + Math.sin(t * 2.7) * 2;
  const g = realGlass(t);
  const ghostOn = t > BREAK - 0.6 && t < CUT + 0.2;
  const gg = ghostGlass(t);
  const handAway = r(t, SLIP, SLIP + 1.4, 0, 1, INOUT);
  const end = lin(t, CUT, CUT + 0.3, 0, 1);
  const grain = Math.floor(frame / 2);
  const flash = t > BREAK - 0.05 && t < BREAK + 0.25 ? lin(t, BREAK - 0.05, BREAK + 0.25, 0.5, 0) : 0;

  return (
    <AbsoluteFill style={{background: '#000'}}>
      <svg width={1920} height={1080} viewBox="0 0 1920 1080" style={{position: 'absolute'}}>
        <Defs />
        <g transform={`translate(${960 + sx} ${540 + sy}) scale(${zoom}) translate(${-fx} ${-fy})`}>
          {/* Fondo desenfocado (profundidad de campo) */}
          <g filter="url(#bg-blur)">
            <rect x={-200} y={-200} width={2400} height={1000} fill="url(#wall)" />
            {Array.from({length: 18}).map((_, i) =>
              Array.from({length: 6}).map((__, j) => (
                <rect key={`${i}-${j}`} x={i * 120 - 120 + (j % 2) * 60} y={140 + j * 70} width={116} height={66} rx={4} fill="#2a2330" opacity={0.6} />
              )),
            )}
            <rect x={240} y={-60} width={560} height={300} fill="url(#cabinet)" />
            <rect x={1460} y={-60} width={520} height={300} fill="url(#cabinet)" />
            {[0, 1, 2].map((i) => (
              <circle key={i} cx={360 + i * 180} cy={420 + (i % 2) * 30} r={26 + i * 6} fill="#ffcf8a" opacity={0.35} />
            ))}
            <rect x={1520} y={360} width={220} height={240} rx={14} fill="#0a1830" />
            <circle cx={1660} cy={420} r={22} fill="#f7f3e0" opacity={0.85} />
          </g>
          {/* Luz de la lámpara */}
          <rect x={-200} y={-200} width={2400} height={1400} fill="url(#lamp)" />
          <path d={`M1060 -40 L1180 -40 L1500 ${FLOOR} L740 ${FLOOR} Z`} fill="url(#cone)" style={{mixBlendMode: 'screen'}} />
          <Dust t={t} />
          {/* Encimera de mármol */}
          <rect x={-200} y={600} width={1560} height={26} fill="url(#marble)" />
          <rect x={-200} y={600} width={1560} height={4} fill="#8a8094" opacity={0.6} />
          <rect x={-200} y={626} width={1560} height={279} fill="url(#cabinet)" />
          {[120, 520, 920].map((x) => (
            <g key={x}>
              <rect x={x} y={650} width={360} height={230} rx={6} fill="none" stroke="#3a281d" strokeWidth={4} />
              <rect x={x + 160} y={690} width={40} height={8} rx={4} fill="#c9a77a" opacity={0.7} />
            </g>
          ))}
          {/* Suelo con reflejo */}
          <rect x={-200} y={FLOOR} width={2400} height={500} fill="url(#floor)" />
          {Array.from({length: 14}).map((_, i) => (
            <line key={i} x1={i * 180 - 300} y1={FLOOR} x2={i * 260 - 900} y2={1400} stroke="#000" strokeWidth={3} opacity={0.35} />
          ))}
          <ellipse cx={1120} cy={FLOOR + 40} rx={360} ry={50} fill="#ffcf8a" opacity={0.08} filter="url(#soft)" />
          {/* Reflejo del vaso en el suelo */}
          {t > SLIP ? (
            <g opacity={lin(g.y, 470, FLOOR - 80, 0.05, 0.3)} transform={`translate(0 ${2 * FLOOR}) scale(1 -1)`} filter="url(#soft)">
              <Glass x={g.x} y={g.y} rot={g.rot} />
            </g>
          ) : null}
          {/* Sombra del vaso */}
          <ellipse cx={g.x + 20} cy={t < SLIP ? 600 : FLOOR + 10} rx={t < SLIP ? 60 : lin(g.y, 470, FLOOR, 30, 70)} ry={t < SLIP ? 8 : lin(g.y, 470, FLOOR, 5, 12)} fill="#000" opacity={t < SLIP ? 0.5 : lin(g.y, 470, FLOOR, 0.15, 0.6)} filter="url(#soft)" />
          {/* El futuro: el vaso cayendo en tiempo real y rompiéndose */}
          {ghostOn ? (
            <g opacity={lin(t, BREAK - 0.6, BREAK - 0.4, 0, 0.9)}>
              {t < BREAK ? <Glass {...gg} ghost /> : <Shards t={t} />}
            </g>
          ) : null}
          {/* Mano y brazo (entran desenfocados desde arriba) */}
          <g transform={`translate(${handAway * 40} ${-handAway * 120})`} style={{filter: 'blur(2px)'}}>
            <path d="M1700 -100 Q1420 260 1230 420 L1190 520 Q1240 560 1290 520 L1340 440 Q1560 330 1820 40 Z" fill="url(#skin)" />
            <path d="M1185 430 Q1160 470 1175 520 Q1200 540 1215 515 Q1205 480 1220 445 Z" fill="#d9a07c" />
            <path d="M1700 -100 L1820 40 L1900 -20 L1780 -160 Z" fill="#1f3b5a" />
          </g>
          {/* El vaso real */}
          <Glass x={g.x} y={g.y} rot={g.rot} blur={t > SLIP ? Math.min(2.5, (t - SLIP) * 0.6) : 0} />
          {ghostOn ? (
            <g transform={`translate(${t < BREAK ? gg.x : 1190} ${t < BREAK ? gg.y - 150 : FLOOR - 140})`} opacity={lin(t, BREAK - 0.5, BREAK - 0.3, 0, 1)} filter="url(#glow)">
              <rect x={-62} y={-28} width={124} height={56} rx={28} fill={FUT} />
              <text x={0} y={12} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={32} fill="#05060f">
                +5 s
              </text>
            </g>
          ) : null}
        </g>
        {/* Destello del impacto "futuro" */}
        <rect x={0} y={0} width={1920} height={1080} fill={FUT} opacity={flash * 0.35} style={{mixBlendMode: 'screen'}} />
        {/* Gradación, viñeta, franjas de cine y grano */}
        <rect x={0} y={0} width={1920} height={1080} fill="#ff9a3d" opacity={0.06} style={{mixBlendMode: 'overlay'}} />
        <rect x={0} y={0} width={1920} height={1080} fill="url(#vignette)" />
        <filter id="grain">
          <feTurbulence type="fractalNoise" baseFrequency="0.85" numOctaves="2" seed={grain} />
          <feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 0.09 0" />
        </filter>
        <rect x={0} y={0} width={1920} height={1080} filter="url(#grain)" />
        <rect x={0} y={0} width={1920} height={90} fill="#000" />
        <rect x={0} y={990} width={1920} height={90} fill="#000" />
      </svg>
      {/* Indicador de cámara lenta */}
      {t > SLIP + 0.3 && t < CUT ? (
        <div style={{position: 'absolute', top: 112, left: 60, fontFamily: FONT, fontWeight: 800, fontSize: 30, color: '#fff', opacity: 0.8, letterSpacing: 4}}>
          <span style={{color: C.red}}>●</span> CÁMARA LENTA · 240 FPS
        </div>
      ) : null}
      {t < CUT ? <Captions chunks={CHUNKS} top={860} width={1500} fontSize={58} /> : null}
      {t > CUT ? (
        <AbsoluteFill style={{background: `rgba(0,0,0,${end * 0.6})`, justifyContent: 'center', alignItems: 'center', flexDirection: 'column', gap: 20}}>
          <div style={{opacity: end, scale: String(interpolate(end, [0, 1], [0.85, 1]))}}>
            <BigText size={70}>¿Y SI PUDIERAS VER</BigText>
          </div>
          <div style={{opacity: end, scale: String(interpolate(end, [0, 1], [0.85, 1]))}}>
            <BigText size={130} color={FUT}>
              5 SEGUNDOS EN EL FUTURO?
            </BigText>
          </div>
        </AbsoluteFill>
      ) : null}
      <Audio src={staticFile('yt-futuro.mp3')} volume={(f) => interpolate(f / fps, [CUT - 0.15, CUT + 0.1], [1, 0], {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'})} />
    </AbsoluteFill>
  );
};
