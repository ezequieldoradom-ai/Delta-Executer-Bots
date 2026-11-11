import React from 'react';
import {AbsoluteFill, random, useCurrentFrame, useVideoConfig} from 'remotion';
import {C, FONT, lin} from './lib';

// ---------- Fondo espacial con estrellas ----------
const STARS = Array.from({length: 160}).map((_, i) => ({
  x: random(`sx${i}`) * 1080,
  y: random(`sy${i}`) * 1920,
  r: 0.8 + random(`sr${i}`) * 2.4,
  p: random(`sp${i}`) * Math.PI * 2,
  s: 0.6 + random(`ss${i}`) * 2,
}));

export const SpaceBackground = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  return (
    <AbsoluteFill
      style={{
        background:
          'radial-gradient(circle at 50% 38%, #1a2456 0%, #0b1030 45%, #04050d 100%)',
      }}
    >
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        {STARS.map((s, i) => (
          <circle
            key={i}
            cx={s.x}
            cy={(s.y + t * 6 * s.r) % 1920}
            r={s.r}
            fill="#fff"
            opacity={0.25 + 0.6 * (0.5 + 0.5 * Math.sin(t * s.s + s.p))}
          />
        ))}
      </svg>
    </AbsoluteFill>
  );
};

// ---------- Astronauta (coordenadas SVG, centrado en el torso) ----------
export const Astronaut = ({x = 0, y = 0, size = 60, rot = 0, wave = 0, opacity = 1}) => {
  const k = size / 60;
  return (
    <g transform={`translate(${x} ${y}) rotate(${rot}) scale(${k})`} opacity={opacity}>
      <rect x={-17} y={-10} width={34} height={34} rx={9} fill="#9fb0c8" />
      <g transform={`rotate(${-35 - wave} -14 0)`}>
        <rect x={-30} y={-4} width={12} height={28} rx={6} fill="#f2f5fa" />
      </g>
      <g transform={`rotate(${35 + wave} 14 0)`}>
        <rect x={18} y={-4} width={12} height={28} rx={6} fill="#f2f5fa" />
      </g>
      <g transform={`rotate(${-10 + wave * 0.4} -7 24)`}>
        <rect x={-13} y={20} width={11} height={22} rx={5.5} fill="#e6ebf2" />
      </g>
      <g transform={`rotate(${10 - wave * 0.4} 7 24)`}>
        <rect x={2} y={20} width={11} height={22} rx={5.5} fill="#e6ebf2" />
      </g>
      <rect x={-15} y={-8} width={30} height={36} rx={11} fill="#ffffff" />
      <rect x={-8} y={2} width={16} height={9} rx={3} fill={C.hot} />
      <circle cx={0} cy={-24} r={18} fill="#ffffff" stroke="#c7d2e2" strokeWidth={2} />
      <ellipse cx={3} cy={-24} rx={12} ry={9} fill="#18306e" />
      <ellipse cx={-1} cy={-27} rx={4.5} ry={2.6} fill="#ffffff" opacity={0.75} />
    </g>
  );
};

// ---------- Corte transversal de la Tierra (coordenadas: centro 0,0, R=440) ----------
export const R = 440;

export const EarthDefs = () => (
  <defs>
    <radialGradient id="atmo">
      <stop offset="0.88" stopColor="#5ab8ff" stopOpacity="0" />
      <stop offset="0.95" stopColor="#5ab8ff" stopOpacity="0.35" />
      <stop offset="1" stopColor="#5ab8ff" stopOpacity="0" />
    </radialGradient>
    <radialGradient id="mantle">
      <stop offset="0.5" stopColor="#ff8a1f" />
      <stop offset="0.8" stopColor="#e5481f" />
      <stop offset="1" stopColor="#9c2a1a" />
    </radialGradient>
    <radialGradient id="outerCore">
      <stop offset="0.3" stopColor="#ffe27a" />
      <stop offset="1" stopColor="#ffa21f" />
    </radialGradient>
    <radialGradient id="innerCore">
      <stop offset="0" stopColor="#ffffff" />
      <stop offset="0.6" stopColor="#fff3b0" />
      <stop offset="1" stopColor="#ffd34d" />
    </radialGradient>
    <radialGradient id="coreHalo">
      <stop offset="0" stopColor="#fff2a8" stopOpacity="0.9" />
      <stop offset="1" stopColor="#ff8a1f" stopOpacity="0" />
    </radialGradient>
    <linearGradient id="tunnelGrad" x1="0" x2="1">
      <stop offset="0" stopColor="#5ee7ff" stopOpacity="0.9" />
      <stop offset="0.18" stopColor="#0a0d1c" />
      <stop offset="0.82" stopColor="#0a0d1c" />
      <stop offset="1" stopColor="#5ee7ff" stopOpacity="0.9" />
    </linearGradient>
  </defs>
);

export const EarthSection = ({t, tunnel = 1, heat = 0}) => {
  const swirl = t * 6;
  const pulse = 0.5 + 0.5 * Math.sin(t * 5);
  const len = 2 * R * tunnel;
  return (
    <g>
      <circle r={R + 40} fill="url(#atmo)" />
      <circle r={R} fill="#2f7fd1" />
      <path
        d={`M ${-R} 0 A ${R} ${R} 0 0 1 ${R} 0`}
        fill="none"
        stroke="#3fa35b"
        strokeWidth={10}
        strokeDasharray="120 60 200 90 80 140"
        transform={`rotate(${-swirl * 0.3})`}
        opacity={0.9}
      />
      <circle r={R - 9} fill="#7a4b2c" />
      <circle r={R - 20} fill="url(#mantle)" />
      {[0, 1, 2, 3, 4, 5].map((i) => (
        <circle
          key={i}
          r={300 + (i % 3) * 40}
          fill="none"
          stroke="#ffd08a"
          strokeOpacity={0.18}
          strokeWidth={6}
          strokeDasharray="60 140"
          transform={`rotate(${swirl * (i % 2 ? 1 : -1) + i * 50})`}
        />
      ))}
      <circle r={240 + 30 * heat} fill="url(#coreHalo)" opacity={0.35 + 0.4 * heat * pulse} />
      <circle r={240} fill="url(#outerCore)" />
      <circle
        r={84}
        fill="url(#innerCore)"
        style={{filter: `drop-shadow(0 0 ${20 + 30 * heat * pulse}px #fff3b0)`}}
      />
      {tunnel > 0 ? (
        <>
          <rect x={-15} y={-R - 6} width={30} height={len + 6} fill="url(#tunnelGrad)" />
          <rect
            x={-15}
            y={-R - 6}
            width={30}
            height={len + 6}
            fill="none"
            stroke="#5ee7ff"
            strokeOpacity={0.35}
            strokeWidth={2}
          />
        </>
      ) : null}
    </g>
  );
};

// Posición física en el túnel: movimiento armónico simple.
// theta = 0 -> Polo Norte, PI/2 -> centro, PI -> Polo Sur
export const tunnelY = (theta) => -R * Math.cos(theta);
export const VMAX = 36000; // km/h aprox. al cruzar el centro
export const speedAt = (theta) => Math.abs(Math.sin(theta)) * VMAX;
export const minutesAt = (theta) => (38 * theta) / Math.PI;

export const Camera = ({cy = 780, zoom = 1, fx = 0, fy = 0, children}) => (
  <g transform={`translate(540 ${cy}) scale(${zoom}) translate(${-fx} ${-fy})`}>{children}</g>
);

// Icono de corazón
export const Heart = ({size = 40, color = C.pink}) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path
      d="M12 21s-7.5-4.6-10-9.3C.3 8.4 2.1 4.5 5.8 4.1c2.2-.2 3.7 1 4.6 2.4.2.3.6.3.8 0 .9-1.4 2.4-2.6 4.6-2.4 3.7.4 5.5 4.3 3.8 7.6C19.5 16.4 12 21 12 21z"
      fill={color}
    />
  </svg>
);

export const Check = ({size = 40, color = '#fff'}) => (
  <svg width={size} height={size} viewBox="0 0 24 24">
    <path d="M4 12.5l5 5L20 6.5" fill="none" stroke={color} strokeWidth={3.5} strokeLinecap="round" strokeLinejoin="round" />
  </svg>
);

// Etiqueta dentro de un SVG
export const SvgLabel = ({x, y, children, size = 34, color = '#fff', anchor = 'middle', opacity = 1}) => (
  <text
    x={x}
    y={y}
    fill={color}
    fontFamily={FONT}
    fontWeight={900}
    fontSize={size}
    textAnchor={anchor}
    opacity={opacity}
    stroke="#05060f"
    strokeWidth={size * 0.18}
    paintOrder="stroke"
  >
    {children}
  </text>
);

export const Brand = ({hideAt = 69.5}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const t = frame / fps;
  const o = Math.min(lin(t, 0.3, 0.8, 0, 1), lin(t, hideAt, hideAt + 0.5, 1, 0));
  return (
    <div
      style={{
        position: 'absolute',
        top: 150,
        left: 40,
        opacity: o,
        display: 'flex',
        alignItems: 'center',
        gap: 12,
        fontFamily: FONT,
        fontWeight: 900,
        fontSize: 34,
        color: '#fff',
        background: 'rgba(5,6,15,0.55)',
        padding: '10px 22px 10px 12px',
        borderRadius: 40,
        border: '2px solid rgba(255,255,255,0.15)',
      }}
    >
      <div
        style={{
          width: 44,
          height: 44,
          borderRadius: 14,
          background: `linear-gradient(135deg, ${C.accent}, ${C.hot})`,
          display: 'flex',
          alignItems: 'center',
          justifyContent: 'center',
          color: '#0b0b14',
          fontSize: 30,
        }}
      >
        A
      </div>
      APRENDE
    </div>
  );
};

export const ProgressBar = () => {
  const frame = useCurrentFrame();
  const {fps, durationInFrames} = useVideoConfig();
  return (
    <div style={{position: 'absolute', top: 0, left: 0, right: 0, height: 10, background: 'rgba(255,255,255,0.12)'}}>
      <div
        style={{
          width: `${(frame / durationInFrames) * 100}%`,
          height: '100%',
          background: `linear-gradient(90deg, ${C.accent}, ${C.hot})`,
        }}
      />
    </div>
  );
};
