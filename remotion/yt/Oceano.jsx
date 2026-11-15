import React from 'react';
import {random} from 'remotion';

// Dibujos para el vídeo de la Fosa de las Marianas (lienzo 1920x1080)

const GLOW = (c, r) => ({filter: `drop-shadow(0 0 ${r}px ${c})`});

export const Submarine = ({x, y, s = 1, t, lights = 0}) => (
  <g transform={`translate(${x} ${y + Math.sin(t * 1.3) * 6}) scale(${s})`}>
    {lights > 0 ? (
      <path d="M150 -10 L900 -220 L900 220 Z" fill="#fff8d0" opacity={0.12 * lights} />
    ) : null}
    <ellipse cx={0} cy={0} rx={150} ry={95} fill="#f2c94c" stroke="#7a5a10" strokeWidth={6} />
    <rect x={-60} y={-130} width={110} height={50} rx={18} fill="#e0b43a" stroke="#7a5a10" strokeWidth={6} />
    <circle cx={70} cy={-10} r={46} fill="#1b3a5a" stroke="#c9d1e0" strokeWidth={10} />
    <circle cx={58} cy={-24} r={14} fill="#fff" opacity={0.5} />
    <circle cx={-50} cy={0} r={22} fill="#1b3a5a" stroke="#c9d1e0" strokeWidth={6} />
    <rect x={-190} y={-20} width={50} height={40} rx={8} fill="#7d8597" />
    <g transform={`translate(-200 0) rotate(${t * 600})`}>
      <rect x={-6} y={-40} width={12} height={80} rx={6} fill="#5a6478" />
    </g>
    <circle cx={146} cy={-10} r={10} fill={lights > 0 ? '#fff8d0' : '#7d8597'} style={lights > 0 ? GLOW('#fff8d0', 20) : undefined} />
  </g>
);

export const Fish = ({x, y, s = 1, color = '#ffb02e', t = 0, flip = false}) => (
  <g transform={`translate(${x} ${y}) scale(${flip ? -s : s} ${s})`}>
    <ellipse cx={0} cy={0} rx={30} ry={14} fill={color} />
    <path d={`M-26 0 L-48 ${-14 + Math.sin(t * 10 + x) * 4} L-48 ${14 + Math.sin(t * 10 + x) * 4} Z`} fill={color} />
    <circle cx={16} cy={-3} r={3.5} fill="#0b0b14" />
  </g>
);

export const FishSchool = ({t, cx, cy, n = 30, spread = 260, color}) => (
  <g>
    {Array.from({length: n}).map((_, i) => {
      const a = random(`fa${i}`) * Math.PI * 2 + t * 0.4;
      const d = random(`fd${i}`) * spread;
      return <Fish key={i} x={cx + Math.cos(a) * d * 1.6} y={cy + Math.sin(a) * d * 0.6} s={0.6 + random(`fs${i}`) * 0.6} t={t} color={color ?? ['#ffb02e', '#ff5a36', '#ffd23f', '#5ee7ff'][i % 4]} flip={Math.sin(a) > 0} />;
    })}
  </g>
);

export const Diver = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s}) rotate(80)`}>
    <rect x={-14} y={-60} width={28} height={70} rx={12} fill="#1a1a2e" />
    <rect x={-22} y={-50} width={14} height={50} rx={6} fill="#c9d1e0" />
    <circle cx={0} cy={-76} r={18} fill="#1a1a2e" />
    <rect x={-12} y={-84} width={24} height={12} rx={4} fill="#5ec8ff" />
    <path d={`M-10 10 L-14 ${50 + Math.sin(t * 6) * 8} L-2 50 Z M10 10 L14 ${50 - Math.sin(t * 6) * 8} L2 50 Z`} fill="#ffd23f" />
  </g>
);

export const Jelly = ({x, y, s = 1, t, color = '#c084fc'}) => {
  const p = Math.sin(t * 2 + x) * 0.12;
  return (
    <g transform={`translate(${x} ${y + Math.sin(t + x) * 10}) scale(${s})`} style={GLOW(color, 16)}>
      <path d={`M-40 0 Q-40 -50 0 -52 Q40 -50 40 0 Q20 ${8 + p * 40} 0 4 Q-20 ${8 - p * 40} -40 0 Z`} fill={color} opacity={0.75} />
      {[-24, -8, 8, 24].map((tx, i) => (
        <path key={tx} d={`M${tx} 4 Q${tx + Math.sin(t * 3 + i) * 12} 40 ${tx} 80`} fill="none" stroke={color} strokeWidth={3} opacity={0.7} />
      ))}
    </g>
  );
};

export const GlowFish = ({x, y, s = 1, t, color = '#5ee7ff'}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <ellipse cx={0} cy={0} rx={34} ry={12} fill="#0d1a2e" />
    {[-20, -6, 8, 22].map((dx, i) => (
      <circle key={dx} cx={dx} cy={8} r={3.5} fill={color} opacity={0.5 + 0.5 * Math.sin(t * 5 + i + x)} style={GLOW(color, 8)} />
    ))}
    <circle cx={22} cy={-3} r={5} fill={color} style={GLOW(color, 6)} />
  </g>
);

export const SpermWhale = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d={`M-420 10 Q-470 ${-20 + Math.sin(t * 2) * 30} -520 ${-60 + Math.sin(t * 2) * 40} Q-480 10 -520 ${80 + Math.sin(t * 2) * 40} Q-470 40 -420 30 Z`} fill="#4a5568" />
    <path d="M-430 0 Q-300 -120 60 -110 L300 -100 Q340 -96 340 -40 L340 50 Q330 90 260 90 L-200 80 Q-380 70 -430 30 Z" fill="#5a6478" />
    <path d="M100 85 Q150 120 260 92" fill="none" stroke="#3a4250" strokeWidth={10} />
    <circle cx={170} cy={-10} r={8} fill="#0b0b14" />
    {[0, 1, 2, 3, 4].map((i) => (
      <path key={i} d={`M${-150 + i * 60} ${-40 + (i % 2) * 30} a14 14 0 1 0 1 0`} fill="none" stroke="#c9d1e0" strokeWidth={3} opacity={0.5} />
    ))}
  </g>
);

export const GiantSquid = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d="M0 -60 Q120 -60 260 0 Q120 60 0 60 Q-20 0 0 -60 Z" fill="#c0392b" />
    <path d="M230 -10 L320 -70 L300 0 L320 70 L230 10 Z" fill="#a83226" />
    <circle cx={30} cy={-10} r={30} fill="#f4f1e8" />
    <circle cx={34} cy={-10} r={16} fill="#0b0b14" />
    {Array.from({length: 8}).map((_, i) => (
      <path key={i} d={`M0 ${-40 + i * 11} Q${-150} ${-80 + i * 22 + Math.sin(t * 2 + i) * 30} ${-320 - (i % 3) * 40} ${-120 + i * 34 + Math.sin(t * 1.5 + i) * 40}`} fill="none" stroke="#c0392b" strokeWidth={10 - (i % 3) * 2} strokeLinecap="round" />
    ))}
  </g>
);

export const Anglerfish = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d="M40 -90 Q120 -170 150 -110" fill="none" stroke="#3a3a4a" strokeWidth={6} />
    <circle cx={152} cy={-106} r={14} fill="#c8ffef" style={GLOW('#7fffd4', 24)} opacity={0.7 + 0.3 * Math.sin(t * 4)} />
    <path d="M-120 0 Q-110 -110 20 -100 Q110 -90 120 0 Q110 90 0 90 Q-110 90 -120 0 Z" fill="#2a2f3e" />
    <path d="M-120 0 L-190 -50 L-180 0 L-190 50 Z" fill="#2a2f3e" />
    <path d="M30 10 Q90 -10 120 20 Q90 70 30 40 Z" fill="#0b0b14" />
    {Array.from({length: 8}).map((_, i) => (
      <path key={i} d={`M${40 + i * 10} ${14 + (i % 2) * 2} l4 14 l4 -14`} fill="#f4f1e8" />
    ))}
    <circle cx={40} cy={-30} r={10} fill="#e8f6ff" />
    <circle cx={42} cy={-30} r={5} fill="#0b0b14" />
  </g>
);

export const Viperfish = ({x, y, s = 1}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d="M-160 0 Q-60 -40 60 -30 Q110 -20 120 0 Q110 20 60 30 Q-60 40 -160 0 Z" fill="#1f2a44" />
    <path d="M-160 0 L-200 -26 L-196 0 L-200 26 Z" fill="#1f2a44" />
    {[0, 1, 2, 3].map((i) => (
      <path key={i} d={`M${82 + i * 9} -14 L${86 + i * 9} ${30 + (i % 2) * 14} L${90 + i * 9} -14 Z`} fill="#f4f1e8" />
    ))}
    {[0, 1, 2, 3, 4, 5].map((i) => (
      <circle key={i} cx={-120 + i * 34} cy={18} r={3} fill="#5ee7ff" style={GLOW('#5ee7ff', 6)} />
    ))}
    <circle cx={70} cy={-14} r={7} fill="#e8f6ff" />
  </g>
);

export const GoblinShark = ({x, y, s = 1, t, jaw = 0}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d="M-300 0 Q-150 -70 120 -50 L260 -40 Q290 -30 260 -20 L140 -10 Q120 30 0 40 Q-160 50 -300 0 Z" fill="#e8a3a3" />
    <path d="M-300 0 L-380 -70 L-350 0 L-380 50 Z" fill="#d48d8d" />
    <path d="M-60 -50 L-20 -110 L10 -48 Z" fill="#d48d8d" />
    <g transform={`translate(${jaw * 60} ${jaw * 26})`}>
      <path d="M120 0 Q170 20 210 4 Q170 40 120 30 Z" fill="#c97b7b" />
      {[0, 1, 2, 3].map((i) => (
        <path key={i} d={`M${130 + i * 18} 6 l5 12 l5 -12`} fill="#fff" />
      ))}
    </g>
    <circle cx={110} cy={-30} r={6} fill="#0b0b14" />
  </g>
);

export const VampireSquid = ({x, y, s = 1, t, umbrella = 0}) => (
  <g transform={`translate(${x} ${y}) scale(${s}) rotate(${umbrella * 180})`}>
    <ellipse cx={0} cy={-60} rx={46} ry={66} fill="#7a1f3d" />
    <ellipse cx={-30} cy={-110} rx={16} ry={10} fill="#7a1f3d" />
    <ellipse cx={30} cy={-110} rx={16} ry={10} fill="#7a1f3d" />
    <circle cx={-18} cy={-40} r={12} fill="#5ee7ff" style={GLOW('#5ee7ff', 10)} />
    <circle cx={18} cy={-40} r={12} fill="#5ee7ff" style={GLOW('#5ee7ff', 10)} />
    <path d={`M-90 0 Q-60 ${70 + Math.sin(t * 2) * 10} 0 60 Q60 ${70 - Math.sin(t * 2) * 10} 90 0 Q0 ${30 - umbrella * 60} -90 0 Z`} fill="#5a1530" />
  </g>
);

export const Titanic = ({x, y, s = 1}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`} opacity={0.9}>
    <path d="M-500 0 L-460 -160 L260 -170 L380 -120 L400 0 Z" fill="#2a2f3e" />
    <path d="M-460 -160 L260 -170 L380 -120 L-470 -120 Z" fill="#3a2a1a" />
    <rect x={-300} y={-230} width={300} height={70} fill="#2f3546" />
    {[-260, -170, -80].map((cx) => (
      <rect key={cx} x={cx} y={-330} width={50} height={110} fill="#5a3a1a" />
    ))}
    {Array.from({length: 16}).map((_, i) => (
      <circle key={i} cx={-420 + i * 50} cy={-90} r={8} fill="#141824" />
    ))}
    <path d="M-500 0 Q-300 30 400 0 L400 40 L-500 40 Z" fill="#3a4250" />
  </g>
);

export const Vent = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    {[0, 1, 2, 3, 4, 5].map((i) => {
      const u = (t * 0.4 + i / 6) % 1;
      return <circle key={i} cx={Math.sin(u * 6 + i) * 30} cy={-260 - u * 420} r={40 + u * 110} fill="#1a1a1a" opacity={0.75 * (1 - u)} />;
    })}
    <path d="M-80 0 L-50 -220 L-30 -260 L30 -260 L50 -220 L80 0 Z" fill="#3a3330" />
    <ellipse cx={0} cy={-260} rx={30} ry={10} fill="#ff6a1f" opacity={0.8} />
    {Array.from({length: 12}).map((_, i) => {
      const tx = -180 + i * 34 + (i > 5 ? 140 : 0);
      const h = 60 + random(`tw${i}`) * 80;
      return (
        <g key={i}>
          <rect x={tx} y={-h} width={10} height={h} fill="#f4f1e8" />
          <path d={`M${tx - 8} ${-h} Q${tx + 5} ${-h - 34 + Math.sin(t * 3 + i) * 6} ${tx + 18} ${-h} Z`} fill="#e23d3d" />
        </g>
      );
    })}
  </g>
);

export const Snailfish = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`} opacity={0.85}>
    <path d={`M-90 0 Q-60 -40 30 -36 Q80 -30 90 0 Q80 34 30 36 Q-60 40 -90 0 Q-130 ${-10 + Math.sin(t * 4) * 12} -150 ${Math.sin(t * 4) * 20} Z`} fill="#f2d6e0" />
    <circle cx={60} cy={-10} r={6} fill="#0b0b14" />
    <path d="M-20 -30 Q10 -10 -20 30" fill="none" stroke="#e0b8c8" strokeWidth={4} />
  </g>
);

export const Amphipod = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d="M-40 0 Q-30 -26 0 -28 Q30 -26 40 0 Q20 10 0 10 Q-20 10 -40 0 Z" fill="#f2e6d0" />
    {[-28, -14, 0, 14, 28].map((dx, i) => (
      <line key={dx} x1={dx} y1={6} x2={dx + Math.sin(t * 10 + i) * 6} y2={22} stroke="#e0d0b0" strokeWidth={3} />
    ))}
    <path d="M38 -6 Q60 -30 70 -20 M38 -2 Q66 -10 72 2" fill="none" stroke="#e0d0b0" strokeWidth={3} />
  </g>
);

export const PlasticBag = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y + Math.sin(t) * 8}) scale(${s}) rotate(${Math.sin(t * 0.7) * 10})`} opacity={0.85}>
    <path d="M-60 -60 L-40 -60 Q-40 -90 -20 -90 Q0 -90 0 -60 L20 -60 Q20 -90 40 -90 Q60 -90 60 -60 L70 60 Q0 80 -70 60 Z" fill="#e8eef5" stroke="#b9c3d0" strokeWidth={3} />
    <path d="M-40 -20 Q0 -10 40 -24" fill="none" stroke="#b9c3d0" strokeWidth={3} />
  </g>
);

export const Trieste = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y + Math.sin(t * 1.2) * 5}) scale(${s})`}>
    <rect x={-260} y={-160} width={520} height={130} rx={60} fill="#7d8597" stroke="#3a4250" strokeWidth={6} />
    <rect x={-20} y={-200} width={60} height={50} rx={6} fill="#5a6478" />
    <circle cx={0} cy={30} r={70} fill="#c9d1e0" stroke="#3a4250" strokeWidth={6} />
    <circle cx={30} cy={30} r={16} fill="#1b3a5a" stroke="#3a4250" strokeWidth={4} />
    <text x={0} y={-80} textAnchor="middle" fontFamily="sans-serif" fontWeight={900} fontSize={40} fill="#fff">
      TRIESTE
    </text>
  </g>
);
