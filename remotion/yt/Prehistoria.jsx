import React from 'react';
import {random} from 'remotion';

// Dibujos para el vídeo de la Edad de Hielo (lienzo 1920x1080, vista lateral)

export const SKY = {
  day: ['#9fc3e6', '#dbe9f5'],
  dusk: ['#2b2f6b', '#f2a07b'],
  night: ['#05081f', '#1a2150'],
  dream: ['#1a0a3a', '#4b2a7a'],
};

// Paisaje de estepa helada con montañas, nieve y viento
export const Tundra = ({t, sky = 'day', pan = 0, snow = 1, ground = '#eef3f8', grass = true}) => {
  const [a, b] = SKY[sky];
  const night = sky === 'night';
  return (
    <g>
      <defs>
        <linearGradient id={`sky-${sky}`} x1="0" y1="0" x2="0" y2="1">
          <stop offset="0" stopColor={a} />
          <stop offset="1" stopColor={b} />
        </linearGradient>
      </defs>
      <rect x={0} y={0} width={1920} height={1080} fill={`url(#sky-${sky})`} />
      {night
        ? Array.from({length: 160}).map((_, i) => (
            <circle key={i} cx={random(`ts${i}`) * 1920} cy={random(`ty${i}`) * 620} r={0.8 + random(`tr${i}`) * 2} fill="#fff" opacity={0.3 + 0.6 * Math.abs(Math.sin(t * 1.5 + i))} />
          ))
        : null}
      {/* Montañas lejanas */}
      <g transform={`translate(${(-pan * 0.2) % 1920} 0)`}>
        {[0, 1920].map((ox) => (
          <g key={ox} transform={`translate(${ox} 0)`}>
            <path d="M0 640 L180 430 L330 560 L520 360 L700 540 L880 400 L1060 580 L1260 380 L1460 560 L1640 420 L1920 600 L1920 760 L0 760 Z" fill={night ? '#2a3366' : '#b8c8dc'} />
            <path d="M520 360 L470 420 L500 415 L530 440 L565 410 L600 430 Z M1260 380 L1210 440 L1245 432 L1275 455 L1300 430 Z M880 400 L845 445 L880 440 L910 455 Z" fill="#fff" opacity={0.9} />
          </g>
        ))}
      </g>
      {/* Colinas cercanas */}
      <g transform={`translate(${(-pan * 0.5) % 1920} 0)`}>
        {[0, 1920].map((ox) => (
          <path key={ox} transform={`translate(${ox} 0)`} d="M0 760 Q240 660 520 740 T1100 730 T1600 720 T1920 750 L1920 1080 L0 1080 Z" fill={night ? '#3b4475' : '#dfe8f1'} />
        ))}
      </g>
      <rect x={0} y={800} width={1920} height={280} fill={night ? '#4a5385' : ground} />
      {grass
        ? Array.from({length: 120}).map((_, i) => {
            const x = ((random(`gx${i}`) * 2200 - pan) % 2200 + 2200) % 2200 - 140;
            const y = 815 + random(`gy${i}`) * 250;
            return <path key={i} d={`M${x} ${y} l${-6 + Math.sin(t * 2 + i) * 4} -${18 + random(`gh${i}`) * 14} M${x} ${y} l${4 + Math.sin(t * 2 + i) * 4} -${14 + random(`gk${i}`) * 12}`} stroke={night ? '#6a7090' : '#a8a27a'} strokeWidth={3} strokeLinecap="round" />;
          })
        : null}
      {/* Nieve y viento */}
      {Array.from({length: Math.round(120 * snow)}).map((_, i) => {
        const x = ((random(`sx${i}`) * 1920 + t * (60 + random(`sv${i}`) * 80)) % 2000) - 40;
        const y = (random(`sy${i}`) * 1080 + t * (40 + random(`sw${i}`) * 60)) % 1080;
        return <circle key={i} cx={x} cy={y} r={1.5 + random(`sr${i}`) * 3} fill="#fff" opacity={0.8} />;
      })}
    </g>
  );
};

// ---------- Animales (vista lateral, mirando a la derecha, pies en y=0) ----------
export const Mammoth = ({x, y, s = 1, t = 0, walk = 0, flip = false}) => {
  const step = Math.sin(t * 4 + x) * 10 * walk;
  return (
    <g transform={`translate(${x} ${y}) scale(${flip ? -s : s} ${s})`}>
      <ellipse cx={0} cy={4} rx={130} ry={14} fill="#000" opacity={0.15} />
      {[-70, -30, 40, 80].map((lx, i) => (
        <rect key={lx} x={lx - 18} y={-120} width={36} height={120} rx={14} fill="#5a3a22" transform={`rotate(${(i % 2 ? 1 : -1) * step} ${lx} -110)`} />
      ))}
      <ellipse cx={0} cy={-170} rx={140} ry={95} fill="#6b4428" />
      <path d="M-140 -160 Q-150 -100 -120 -80 L-110 -140 Z M-60 -80 L-50 -40 L-40 -80 M0 -80 L8 -36 L18 -80 M60 -82 L70 -42 L80 -84" fill="#5a3a22" />
      <ellipse cx={120} cy={-230} rx={70} ry={75} fill="#6b4428" />
      <ellipse cx={95} cy={-255} rx={30} ry={40} fill="#5a3a22" />
      <path d={`M175 -215 Q205 -150 ${185 + Math.sin(t * 2) * 10} -70 Q182 -55 172 -62 Q186 -150 155 -200 Z`} fill="#5a3a22" />
      <path d="M160 -190 Q235 -150 225 -95 Q215 -140 160 -172 Z" fill="#f4ecd8" stroke="#cdbf9e" strokeWidth={3} />
      <circle cx={150} cy={-245} r={5} fill="#1a1a1a" />
      <path d="M-120 -230 Q-80 -270 -10 -262 Q60 -275 110 -300" fill="none" stroke="#7b5233" strokeWidth={14} strokeLinecap="round" />
    </g>
  );
};

export const WoollyRhino = ({x, y, s = 1, t = 0, walk = 0}) => {
  const step = Math.sin(t * 5 + x) * 10 * walk;
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`}>
      <ellipse cx={0} cy={4} rx={110} ry={12} fill="#000" opacity={0.15} />
      {[-60, -25, 35, 65].map((lx, i) => (
        <rect key={lx} x={lx - 14} y={-70} width={28} height={70} rx={10} fill="#5b4632" transform={`rotate(${(i % 2 ? 1 : -1) * step} ${lx} -66)`} />
      ))}
      <ellipse cx={-5} cy={-110} rx={110} ry={62} fill="#7a6045" />
      <path d="M-70 -165 Q0 -190 70 -160" fill="none" stroke="#8a6f50" strokeWidth={18} strokeLinecap="round" />
      <ellipse cx={105} cy={-100} rx={50} ry={38} fill="#7a6045" />
      <path d="M140 -110 L205 -175 L160 -90 Z" fill="#e8dcc2" stroke="#b5a37e" strokeWidth={3} />
      <path d="M118 -128 L140 -150 L132 -118 Z" fill="#e8dcc2" />
      <circle cx={110} cy={-112} r={4} fill="#1a1a1a" />
    </g>
  );
};

export const GiantDeer = ({x, y, s = 1, t = 0, walk = 0}) => {
  const step = Math.sin(t * 5 + x) * 12 * walk;
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`}>
      <ellipse cx={0} cy={4} rx={90} ry={10} fill="#000" opacity={0.15} />
      {[-55, -30, 40, 62].map((lx, i) => (
        <rect key={lx} x={lx - 8} y={-120} width={16} height={120} rx={6} fill="#7a4e2a" transform={`rotate(${(i % 2 ? 1 : -1) * step} ${lx} -116)`} />
      ))}
      <ellipse cx={0} cy={-150} rx={90} ry={45} fill="#a0693a" />
      <path d="M60 -170 L95 -250 L120 -245 L90 -160 Z" fill="#a0693a" />
      <ellipse cx={118} cy={-255} rx={36} ry={20} fill="#a0693a" />
      <circle cx={122} cy={-262} r={4} fill="#1a1a1a" />
      {/* Cornamenta enorme */}
      <g fill="#d9c49a" stroke="#a88d5c" strokeWidth={3}>
        <path d="M100 -270 Q40 -330 -60 -320 Q-30 -300 10 -300 Q-20 -350 -10 -380 Q20 -330 40 -310 Q30 -360 60 -385 Q65 -330 80 -300 Q100 -340 130 -355 Q115 -300 100 -270 Z" />
        <path d="M110 -272 Q170 -330 250 -320 Q225 -300 190 -298 Q225 -345 220 -380 Q190 -330 170 -310 Q185 -360 160 -390 Q150 -330 140 -300 Z" />
      </g>
    </g>
  );
};

export const CaveLion = ({x, y, s = 1, t = 0, walk = 0, roar = 0}) => {
  const step = Math.sin(t * 6 + x) * 12 * walk;
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`}>
      <ellipse cx={0} cy={4} rx={100} ry={10} fill="#000" opacity={0.15} />
      {[-60, -35, 40, 62].map((lx, i) => (
        <rect key={lx} x={lx - 10} y={-80} width={20} height={80} rx={8} fill="#b8894e" transform={`rotate(${(i % 2 ? 1 : -1) * step} ${lx} -76)`} />
      ))}
      <path d={`M-90 -110 Q-150 -${150 + Math.sin(t * 3) * 10} -170 -100`} fill="none" stroke="#b8894e" strokeWidth={10} strokeLinecap="round" />
      <ellipse cx={0} cy={-110} rx={95} ry={42} fill="#d0a060" />
      <ellipse cx={100} cy={-140} rx={45} ry={40} fill="#d0a060" />
      <path d={`M120 -128 L150 ${-120 + roar * 20} L125 -110 Z`} fill="#7a1a1a" opacity={roar > 0 ? 1 : 0} />
      <circle cx={112} cy={-152} r={5} fill="#1a1a1a" />
      <path d="M80 -175 L88 -192 L98 -176 Z" fill="#c08e52" />
    </g>
  );
};

export const Wolf = ({x, y, s = 1, t = 0, walk = 0}) => {
  const step = Math.sin(t * 8 + x) * 14 * walk;
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`}>
      {[-40, -22, 28, 42].map((lx, i) => (
        <rect key={lx} x={lx - 6} y={-50} width={12} height={50} rx={5} fill="#6b6f7a" transform={`rotate(${(i % 2 ? 1 : -1) * step} ${lx} -46)`} />
      ))}
      <path d="M-55 -70 Q-90 -90 -100 -60" fill="none" stroke="#7d828f" strokeWidth={10} strokeLinecap="round" />
      <ellipse cx={0} cy={-70} rx={60} ry={24} fill="#8a8f9c" />
      <path d="M45 -80 L90 -95 L100 -80 L80 -66 L50 -62 Z" fill="#8a8f9c" />
      <path d="M58 -92 L64 -112 L72 -92 Z" fill="#6b6f7a" />
      <circle cx={78} cy={-86} r={3} fill="#1a1a1a" />
    </g>
  );
};

// ---------- Personas (pies en y=0) ----------
export const Human = ({x, y, s = 1, t = 0, fur = '#8a5a2c', skin = '#d9a77a', modern = false, wave = 0, spear = false, walk = 0, flip = false, hair = '#2a1a10'}) => {
  const step = Math.sin(t * 7 + x) * 16 * walk;
  return (
    <g transform={`translate(${x} ${y}) scale(${flip ? -s : s} ${s})`}>
      <ellipse cx={0} cy={3} rx={26} ry={6} fill="#000" opacity={0.18} />
      <rect x={-14} y={-62} width={12} height={62} rx={6} fill={modern ? '#2c3550' : '#6b4428'} transform={`rotate(${step} -8 -58)`} />
      <rect x={2} y={-62} width={12} height={62} rx={6} fill={modern ? '#2c3550' : '#6b4428'} transform={`rotate(${-step} 8 -58)`} />
      <path d="M-24 -60 L24 -60 L20 -128 Q0 -138 -20 -128 Z" fill={modern ? '#5ee7ff' : fur} />
      {!modern ? <path d="M-24 -60 L-18 -50 L-10 -60 L-2 -50 L6 -60 L14 -50 L24 -60" fill={fur} stroke="#5a3a1a" strokeWidth={2} /> : null}
      <rect x={18} y={-126} width={10} height={52} rx={5} fill={skin} transform={`rotate(${-20 - wave} 22 -124)`} />
      <rect x={-28} y={-126} width={10} height={52} rx={5} fill={skin} transform="rotate(15 -22 -124)" />
      {spear ? <line x1={30} y1={-40} x2={60} y2={-200} stroke="#7a4e2a" strokeWidth={5} /> : null}
      {spear ? <path d="M56 -200 L66 -228 L68 -196 Z" fill="#8a8f9c" /> : null}
      <circle cx={0} cy={-150} r={22} fill={skin} />
      <path d={modern ? 'M-22 -156 Q0 -184 22 -156 Q8 -168 -22 -156 Z' : 'M-24 -150 Q-26 -184 0 -178 Q26 -184 24 -148 Q20 -168 0 -170 Q-20 -168 -24 -150 Z'} fill={hair} />
      <circle cx={8} cy={-152} r={2.8} fill="#1a1a1a" />
    </g>
  );
};

export const Fire = ({x, y, s = 1, t}) => {
  const f = 1 + Math.sin(t * 13) * 0.12 + Math.sin(t * 7.3) * 0.08;
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`}>
      <circle r={110} fill="#ffb347" opacity={0.18 + 0.05 * Math.sin(t * 9)} />
      <rect x={-40} y={-6} width={80} height={14} rx={6} fill="#6b3f1f" transform="rotate(14)" />
      <rect x={-40} y={-6} width={80} height={14} rx={6} fill="#7a4a24" transform="rotate(-14)" />
      <g transform={`scale(1 ${f})`}>
        <path d="M-26 0 C-34 -34 -10 -50 0 -78 C10 -50 34 -34 26 0 Z" fill="#ff7a1a" />
        <path d="M-13 0 C-17 -20 -4 -30 0 -46 C5 -30 17 -20 13 0 Z" fill="#ffe27a" />
      </g>
    </g>
  );
};

// Punta solutrense en hoja de laurel
export const LaurelPoint = ({s = 1}) => (
  <g transform={`scale(${s})`}>
    <path d="M0 -120 Q36 -40 0 120 Q-36 -40 0 -120 Z" fill="#c9c2b4" stroke="#7d7568" strokeWidth={3} />
    {Array.from({length: 9}).map((_, i) => (
      <path key={i} d={`M0 ${-100 + i * 24} l${i % 2 ? 18 : -18} 10`} stroke="#9a9283" strokeWidth={2} />
    ))}
  </g>
);

// Pintura rupestre (bisonte en ocre)
export const CaveBison = ({s = 1, color = '#9c3b1b'}) => (
  <g transform={`scale(${s})`} fill={color} opacity={0.85}>
    <path d="M-120 0 Q-130 -60 -80 -80 Q-40 -120 20 -100 Q70 -110 100 -70 Q130 -40 110 0 L95 0 L90 40 L78 40 L80 0 L-60 0 L-62 40 L-75 40 L-80 0 Z" />
    <path d="M100 -70 Q140 -80 150 -50 Q140 -30 115 -35 Z" />
    <path d="M120 -82 Q130 -105 115 -110" fill="none" stroke={color} strokeWidth={6} />
  </g>
);
