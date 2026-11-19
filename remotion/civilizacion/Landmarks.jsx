import React from 'react';
import {C} from '../tunel/lib';

// Monumentos fijos de la isla. Cada uno en su sitio para que no se pisen.
export const SPOTS = {
  kiosk: {x: 375, y: 790}, // Kiosco de Catalina (noroeste)
  sharpener: {x: 725, y: 775}, // Sacapuntas gigante (noreste)
  dylanRock: {x: 555, y: 712}, // Roca del visionario (norte)
};

export const Sharpener = ({s = 1, t}) => (
  <g transform={`scale(${s})`}>
    <defs>
      <linearGradient id="steel" x1="0" y1="0" x2="1" y2="1">
        <stop offset="0" stopColor="#f4f7fb" />
        <stop offset="0.45" stopColor="#b9c2d0" />
        <stop offset="0.55" stopColor="#e6ebf2" />
        <stop offset="1" stopColor="#8a94a6" />
      </linearGradient>
    </defs>
    <ellipse cx={0} cy={6} rx={70} ry={14} fill="#000" opacity={0.25} />
    <path d="M-60 0 L60 0 L60 -70 L-60 -70 Z" fill="url(#steel)" stroke="#5a6478" strokeWidth={3} />
    <path d="M-60 -70 L-40 -88 L80 -88 L60 -70 Z" fill="#dfe5ee" stroke="#5a6478" strokeWidth={3} />
    <path d="M60 0 L80 -18 L80 -88 L60 -70 Z" fill="#9aa3b8" stroke="#5a6478" strokeWidth={3} />
    <circle cx={-10} cy={-35} r={22} fill="#2a2f3e" />
    <circle cx={-10} cy={-35} r={10} fill="#151821" />
    <rect x={-48} y={-62} width={70} height={8} rx={2} fill="#c9d1e0" stroke="#5a6478" strokeWidth={2} />
    <circle cx={30} cy={-58} r={5} fill="#7d8597" />
    <path d={`M-50 -66 L${-20 + Math.sin(t * 3) * 40} -66`} stroke="#fff" strokeWidth={4} opacity={0.7} />
  </g>
);

export const Kiosk = ({s = 1}) => (
  <g transform={`scale(${s})`}>
    <ellipse cx={0} cy={4} rx={40} ry={9} fill="#000" opacity={0.2} />
    <rect x={-30} y={-22} width={60} height={22} fill="#a0703f" />
    <rect x={-33} y={-56} width={5} height={36} fill="#6b3f1f" />
    <rect x={28} y={-56} width={5} height={36} fill="#6b3f1f" />
    {[0, 1, 2, 3].map((k) => (
      <rect key={k} x={-36 + k * 18} y={-64} width={18} height={12} fill={k % 2 ? '#fff' : C.pink} />
    ))}
    <rect x={-22} y={-30} width={10} height={8} fill="#ffd23f" />
    <rect x={-6} y={-30} width={10} height={8} fill="#3ddc84" />
    <rect x={10} y={-30} width={10} height={8} fill="#5ec8ff" />
  </g>
);

export const Landmarks = ({t, sharpener = true, kiosk = true, rock = true}) => (
  <g>
    {rock ? <ellipse cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y + 4} rx={30} ry={12} fill="#9aa3b8" /> : null}
    {kiosk ? (
      <g transform={`translate(${SPOTS.kiosk.x} ${SPOTS.kiosk.y})`}>
        <Kiosk s={1.1} />
      </g>
    ) : null}
    {sharpener ? (
      <g transform={`translate(${SPOTS.sharpener.x} ${SPOTS.sharpener.y})`}>
        <Sharpener s={0.9} t={t} />
      </g>
    ) : null}
  </g>
);
