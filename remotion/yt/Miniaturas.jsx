import React from 'react';
import {AbsoluteFill} from 'remotion';
import {C, FONT} from '../tunel/lib';
import {Fire, Human, Mammoth, Tundra} from './Prehistoria';

const CANVAS = {width: 1920, height: 1080, viewBox: '0 0 1920 1080', style: {position: 'absolute'}};

const Big = ({children, size, color = '#fff', stroke = 18, style}) => (
  <div
    style={{
      fontFamily: FONT,
      fontWeight: 900,
      fontSize: size,
      lineHeight: 0.95,
      color,
      WebkitTextStroke: `${stroke}px #05060f`,
      paintOrder: 'stroke fill',
      textShadow: '0 14px 40px rgba(0,0,0,0.6)',
      ...style,
    }}
  >
    {children}
  </div>
);

const Arrow = ({x, y, rot = 0, s = 1, color = C.red}) => (
  <g transform={`translate(${x} ${y}) rotate(${rot}) scale(${s})`}>
    <path d="M0 -26 L150 -26 L150 -70 L240 0 L150 70 L150 26 L0 26 Z" fill={color} stroke="#05060f" strokeWidth={10} strokeLinejoin="round" />
  </g>
);

// A: tú frente a un mamut gigante
export const MiniaturaA = () => (
  <AbsoluteFill>
    <svg {...CANVAS}>
      <Tundra t={3} pan={0} snow={1.6} />
      <rect x={0} y={0} width={1920} height={1080} fill="#5ec8ff" opacity={0.12} />
      <Mammoth x={1420} y={1040} s={2.35} t={3} flip />
      <Human x={640} y={1030} s={2.3} t={0} modern />
      <Arrow x={300} y={600} rot={30} s={1.1} />
    </svg>
    <div style={{position: 'absolute', top: 40, left: 50}}>
      <Big size={230} color={C.accent}>
        ¿20.000
        <br />
        AÑOS?
      </Big>
    </div>
  </AbsoluteFill>
);

// B: cara de sorpresa en plena Edad de Hielo
export const MiniaturaB = () => (
  <AbsoluteFill>
    <svg {...CANVAS}>
      <Tundra t={5} pan={300} snow={2} />
      <Mammoth x={1640} y={900} s={1.2} t={5} flip />
      <g transform="translate(560 620)">
        <circle r={380} fill="#5ec8ff" opacity={0.25} />
        <path d="M-300 420 Q-300 200 0 200 Q300 200 300 420 Z" fill="#5ec8ff" />
        <circle cx={0} cy={-40} r={250} fill="#e8b48c" />
        <path d="M-255 -60 Q-260 -330 0 -320 Q260 -330 255 -60 Q220 -230 0 -240 Q-220 -230 -255 -60 Z" fill="#2a1a10" />
        {[-95, 95].map((x) => (
          <g key={x}>
            <ellipse cx={x} cy={-60} rx={62} ry={74} fill="#fff" stroke="#05060f" strokeWidth={8} />
            <circle cx={x + 6} cy={-50} r={26} fill="#05060f" />
            <circle cx={x + 14} cy={-60} r={8} fill="#fff" />
            <path d={`M${x - 60} -160 Q${x} -200 ${x + 60} -165`} fill="none" stroke="#2a1a10" strokeWidth={16} strokeLinecap="round" />
          </g>
        ))}
        <ellipse cx={0} cy={110} rx={56} ry={74} fill="#5a1a1a" stroke="#05060f" strokeWidth={8} />
        <path d="M-160 40 Q-200 60 -190 100" fill="none" stroke="#c97b5a" strokeWidth={10} opacity={0.6} />
      </g>
      {Array.from({length: 18}).map((_, i) => (
        <path key={i} d={`M${200 + (i % 6) * 120} ${380 + Math.floor(i / 6) * 140} l14 0 m-7 -7 l0 14`} stroke="#fff" strokeWidth={4} opacity={0.6} />
      ))}
    </svg>
    <div style={{position: 'absolute', top: 60, right: 60, textAlign: 'right'}}>
      <Big size={190} color="#fff">
        ¿SOBRE-
        <br />
        VIVIRÍAS?
      </Big>
      <div style={{marginTop: 30, display: 'inline-block', background: C.accent, borderRadius: 24, padding: '10px 30px', fontFamily: FONT, fontWeight: 900, fontSize: 80, color: '#0b0b14', border: '8px solid #05060f'}}>HACE 20.000 AÑOS</div>
    </div>
  </AbsoluteFill>
);

// C: 2026 contra 18.000 a. C.
export const MiniaturaC = () => (
  <AbsoluteFill>
    <svg {...CANVAS}>
      <defs>
        <clipPath id="right">
          <path d="M1060 0 L1920 0 L1920 1080 L860 1080 Z" />
        </clipPath>
      </defs>
      <rect x={0} y={0} width={1920} height={1080} fill="#1a1440" />
      {Array.from({length: 12}).map((_, i) => (
        <rect key={i} x={i * 90} y={1080 - (300 + ((i * 137) % 400))} width={80} height={1000} fill={i % 2 ? '#2a2f66' : '#232859'} />
      ))}
      {Array.from({length: 60}).map((_, i) => (
        <rect key={i} x={10 + (i % 12) * 90 + 20} y={500 + Math.floor(i / 12) * 90} width={34} height={22} fill="#ffd27a" opacity={(i * 7) % 3 ? 0.9 : 0.2} />
      ))}
      <Human x={480} y={1040} s={2.4} t={0} modern />
      <g transform="translate(600 640) rotate(12)">
        <rect x={-50} y={-90} width={100} height={180} rx={18} fill="#111" stroke="#c9d1e0" strokeWidth={6} />
        <rect x={-40} y={-76} width={80} height={150} rx={8} fill="#5ec8ff" />
      </g>
      <g clipPath="url(#right)">
        <Tundra t={2} pan={600} snow={1.4} />
        <Mammoth x={1560} y={900} s={1.6} t={2} />
        <Fire x={1180} y={960} s={1.6} t={2} />
        <Human x={1360} y={1000} s={1.6} t={0} />
      </g>
      <path d="M1060 0 L860 1080" stroke="#fff" strokeWidth={18} />
      <path d="M1060 0 L860 1080" stroke={C.accent} strokeWidth={8} />
    </svg>
    <div style={{position: 'absolute', top: 50, left: 60}}>
      <Big size={180} color="#5ec8ff">
        2026
      </Big>
    </div>
    <div style={{position: 'absolute', top: 50, right: 60}}>
      <Big size={150} color={C.accent}>
        18.000 a. C.
      </Big>
    </div>
    <div style={{position: 'absolute', top: 420, left: 830, width: 260, display: 'flex', justifyContent: 'center'}}>
      <Big size={240} color="#fff">
        ?
      </Big>
    </div>
  </AbsoluteFill>
);
