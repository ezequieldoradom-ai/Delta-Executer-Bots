import React from 'react';
import {random} from 'remotion';
import {BACK, C, FONT, r} from '../tunel/lib';

// =====================================================================
// La isla de la civilización. Todo lo que aparece depende de `pop`
// (habitantes), así que cada episodio solo necesita el número nuevo.
// =====================================================================
export const ISLAND = {x: 540, y: 980, rx: 450, ry: 300};

// Aparición de un elemento cuando la población supera `th`
const appear = (pop, th) => {
  if (pop < th) return 0;
  const k = Math.min(1, (pop - th) / (th * 0.12 + 1.5));
  return BACK(k);
};

// ---------- Sprites ----------
export const Fire = ({x, y, t, s = 1}) => {
  const f = 1 + Math.sin(t * 13) * 0.12 + Math.sin(t * 7.3) * 0.08;
  return (
    <g transform={`translate(${x} ${y}) scale(${s})`}>
      <circle r={70} fill="#ffb347" opacity={0.18 + 0.05 * Math.sin(t * 9)} />
      <rect x={-22} y={-4} width={44} height={9} rx={4} fill="#6b3f1f" transform="rotate(18)" />
      <rect x={-22} y={-4} width={44} height={9} rx={4} fill="#7a4a24" transform="rotate(-18)" />
      <g transform={`scale(1 ${f})`}>
        <path d="M-14 0 C-18 -18 -6 -26 0 -40 C6 -26 18 -18 14 0 Z" fill="#ff7a1a" />
        <path d="M-7 0 C-9 -10 -2 -16 0 -24 C3 -16 9 -10 7 0 Z" fill="#ffe27a" />
      </g>
    </g>
  );
};

const Palm = ({x, y, t, s = 1}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <ellipse cx={0} cy={4} rx={26} ry={8} fill="#000" opacity={0.15} />
    <path d="M0 0 Q-8 -40 6 -86" fill="none" stroke="#8a5a2c" strokeWidth={10} strokeLinecap="round" />
    <g transform={`translate(6 -86) rotate(${Math.sin(t * 1.4 + x) * 5})`}>
      {[-150, -110, -60, -20, 30].map((a) => (
        <path key={a} d="M0 0 Q22 -14 48 4 Q22 -4 0 0 Z" fill="#2f9e4f" transform={`rotate(${a + 90})`} />
      ))}
      <circle r={5} fill="#7a4a24" />
    </g>
  </g>
);

const SHIRTS = ['#5ee7ff', '#ff5a36', '#ffd23f', '#3ddc84', '#ff3d81', '#a78bfa', '#ffffff'];

export const Villager = ({x, y, t, seed = 0, s = 1, crown = false, tag, shirt, wave = 0}) => {
  const bob = Math.abs(Math.sin(t * 6 + seed)) * 2;
  return (
    <g transform={`translate(${x} ${y - bob}) scale(${s})`}>
      <ellipse cx={0} cy={bob + 1} rx={11} ry={4} fill="#000" opacity={0.2} />
      <rect x={-6} y={-8} width={4} height={10} rx={2} fill="#2c3550" />
      <rect x={2} y={-8} width={4} height={10} rx={2} fill="#2c3550" />
      <rect x={-8} y={-26} width={16} height={20} rx={6} fill={shirt ?? SHIRTS[seed % SHIRTS.length]} />
      <rect x={6} y={-24} width={4} height={13} rx={2} fill="#f2c29b" transform={`rotate(${-20 - wave} 8 -24)`} />
      <rect x={-10} y={-24} width={4} height={13} rx={2} fill="#f2c29b" transform="rotate(15 -8 -24)" />
      <circle cx={0} cy={-34} r={8} fill={seed % 3 === 0 ? '#c68b59' : '#f2c29b'} />
      <path d="M-8 -36 Q0 -46 8 -36 Q2 -40 -8 -36 Z" fill={seed % 2 ? '#3a2418' : '#1a1a1a'} />
      {crown ? <path d="M-8 -42 L-8 -50 L-4 -45 L0 -52 L4 -45 L8 -50 L8 -42 Z" fill={C.accent} stroke="#b88a00" strokeWidth={1.2} /> : null}
      {tag ? (
        <g transform="translate(0 -62)">
          <rect x={-tag.length * 5.6 - 10} y={-15} width={tag.length * 11.2 + 20} height={26} rx={13} fill="#fff" />
          <text y={4} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={15} fill="#0b0b14">
            {tag}
          </text>
        </g>
      ) : null}
    </g>
  );
};

const Tent = ({x, y, s}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <ellipse cx={0} cy={2} rx={34} ry={9} fill="#000" opacity={0.15} />
    <path d="M-32 0 L0 -56 L32 0 Z" fill="#b07a45" />
    <path d="M0 -56 L32 0 L10 0 Z" fill="#8f5f33" />
    <path d="M-8 0 L0 -22 L8 0 Z" fill="#3a2418" />
    <line x1={-4} y1={-62} x2={4} y2={-50} stroke="#6b3f1f" strokeWidth={3} />
  </g>
);

const Hut = ({x, y, s}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <ellipse cx={0} cy={2} rx={40} ry={10} fill="#000" opacity={0.15} />
    <rect x={-28} y={-32} width={56} height={32} fill="#d9b382" />
    <path d="M-36 -30 L0 -62 L36 -30 Z" fill="#c9a43a" />
    <path d="M-36 -30 L0 -62 L36 -30" fill="none" stroke="#a8862a" strokeWidth={3} />
    <rect x={-7} y={-18} width={14} height={18} fill="#6b3f1f" />
  </g>
);

const House = ({x, y, s, roof = '#d9472b'}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <ellipse cx={0} cy={2} rx={44} ry={10} fill="#000" opacity={0.15} />
    <rect x={-32} y={-44} width={64} height={44} fill="#e8e1d4" />
    <rect x={-32} y={-44} width={64} height={44} fill="none" stroke="#b9ad98" strokeWidth={2} />
    <path d="M-40 -42 L0 -74 L40 -42 Z" fill={roof} />
    <rect x={-22} y={-34} width={12} height={12} fill="#5ec8ff" />
    <rect x={10} y={-34} width={12} height={12} fill="#5ec8ff" />
    <rect x={-7} y={-20} width={14} height={20} fill="#7a4a24" />
  </g>
);

const Field = ({x, y, s, crop = '#e8c547'}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d="M-60 -24 L60 -24 L70 24 L-70 24 Z" fill="#8a6a3a" />
    {[-16, -4, 8, 20].map((yy) => (
      <line key={yy} x1={-62} x2={64} y1={yy} y2={yy} stroke={crop} strokeWidth={6} strokeLinecap="round" />
    ))}
  </g>
);

const Sheep = ({x, y, s, t, seed}) => (
  <g transform={`translate(${x + Math.sin(t * 0.8 + seed) * 6} ${y}) scale(${s})`}>
    <ellipse cx={0} cy={2} rx={14} ry={4} fill="#000" opacity={0.15} />
    <rect x={-8} y={-6} width={3} height={7} fill="#333" />
    <rect x={5} y={-6} width={3} height={7} fill="#333" />
    <ellipse cx={0} cy={-12} rx={14} ry={10} fill="#fff" />
    <circle cx={13} cy={-14} r={5} fill="#333" />
  </g>
);

const Well = ({x, y, s}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <ellipse cx={0} cy={-6} rx={20} ry={8} fill="#9aa3b8" />
    <rect x={-20} y={-6} width={40} height={14} fill="#7d8597" />
    <ellipse cx={0} cy={-6} rx={14} ry={5} fill="#2f7fd1" />
    <rect x={-18} y={-40} width={4} height={34} fill="#6b3f1f" />
    <rect x={14} y={-40} width={4} height={34} fill="#6b3f1f" />
    <path d="M-24 -38 L0 -52 L24 -38 Z" fill="#a0703f" />
  </g>
);

const Stall = ({x, y, s, color}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <rect x={-24} y={-18} width={48} height={18} fill="#a0703f" />
    <rect x={-26} y={-44} width={4} height={30} fill="#6b3f1f" />
    <rect x={22} y={-44} width={4} height={30} fill="#6b3f1f" />
    {[0, 1, 2, 3].map((k) => (
      <rect key={k} x={-28 + k * 14} y={-48} width={14} height={12} fill={k % 2 ? '#fff' : color} />
    ))}
    <circle cx={-10} cy={-22} r={5} fill="#ff5a36" />
    <circle cx={2} cy={-22} r={5} fill="#3ddc84" />
    <circle cx={13} cy={-22} r={5} fill="#ffd23f" />
  </g>
);

const Tower = ({x, y, s, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <ellipse cx={0} cy={2} rx={30} ry={8} fill="#000" opacity={0.15} />
    <rect x={-20} y={-120} width={40} height={120} fill="#c9c2b4" />
    <rect x={-10} y={-100} width={20} height={22} fill="#3a2418" />
    <circle cx={0} cy={-88} r={6} fill={C.accent} transform={`rotate(${Math.sin(t * 3) * 20} 0 -98)`} />
    <path d="M-26 -118 L0 -150 L26 -118 Z" fill="#2f5fa8" />
    <line x1={0} y1={-150} x2={0} y2={-172} stroke="#333" strokeWidth={2} />
    <path d={`M0 -172 L${18 + Math.sin(t * 5) * 3} -166 L0 -160 Z`} fill={C.red} />
  </g>
);

const Smithy = ({x, y, s, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <House x={0} y={0} s={1} roof="#555" />
    <rect x={18} y={-90} width={12} height={30} fill="#7d8597" />
    {[0, 1, 2].map((k) => {
      const u = (t * 0.5 + k / 3) % 1;
      return <circle key={k} cx={24 + u * 18} cy={-96 - u * 70} r={8 + u * 14} fill="#c9ccd6" opacity={0.6 * (1 - u)} />;
    })}
  </g>
);

const Dock = ({x, y, s, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <rect x={0} y={-8} width={120} height={16} fill="#a0703f" />
    {[10, 40, 70, 100].map((xx) => (
      <rect key={xx} x={xx} y={6} width={6} height={14} fill="#6b3f1f" />
    ))}
    <g transform={`translate(150 ${Math.sin(t * 2) * 3})`}>
      <path d="M-34 0 L34 0 L24 16 L-24 16 Z" fill="#8a5a2c" />
      <line x1={0} y1={0} x2={0} y2={-60} stroke="#6b3f1f" strokeWidth={4} />
      <path d="M2 -58 L30 -12 L2 -12 Z" fill="#fff" />
    </g>
  </g>
);

// ---------- Posiciones fijas (semilla) ----------
const inIsland = (k, spread = 0.8) => {
  const a = random(`ia${k}`) * Math.PI * 2;
  const d = Math.sqrt(random(`id${k}`)) * spread;
  return {x: ISLAND.x + Math.cos(a) * ISLAND.rx * 0.85 * d, y: ISLAND.y + Math.sin(a) * ISLAND.ry * 0.78 * d};
};

const FIRE = {x: 540, y: 975};
const PALMS = [
  {x: 150, y: 930}, {x: 210, y: 1130}, {x: 900, y: 880}, {x: 950, y: 1080}, {x: 640, y: 1250}, {x: 360, y: 760},
];
const TENTS = [
  {x: 470, y: 920, th: 4}, {x: 630, y: 930, th: 7}, {x: 560, y: 1060, th: 10},
];
const HUTS = Array.from({length: 8}).map((_, k) => {
  const a = -2.4 + k * 0.62;
  return {x: 540 + Math.cos(a) * 200, y: 975 + Math.sin(a) * 120, th: 14 + k * 11};
});
const FIELDS = [
  {x: 820, y: 1000, th: 30}, {x: 790, y: 1090, th: 50}, {x: 280, y: 1050, th: 70}, {x: 300, y: 870, th: 95},
];
const SHEEP = Array.from({length: 5}).map((_, k) => ({x: 700 + k * 26, y: 1180 - (k % 2) * 20, th: 40 + k * 12}));
const HOUSES = Array.from({length: 12}).map((_, k) => {
  const a = -3.0 + k * 0.52;
  return {x: 540 + Math.cos(a) * 330, y: 980 + Math.sin(a) * 210, th: 150 + k * 70};
});
const STALLS = [
  {x: 430, y: 1010, th: 400, c: C.red}, {x: 480, y: 1050, th: 480, c: C.cyan}, {x: 410, y: 1080, th: 560, c: C.green},
];

export const IslandWorld = ({t, pop, tags = [], maxShown = 70}) => {
  const items = [];
  const add = (y, el) => items.push({y, el});

  PALMS.forEach((p, i) => add(p.y, <Palm key={`p${i}`} x={p.x} y={p.y} t={t} s={1.1} />));
  add(FIRE.y, <Fire key="fire" x={FIRE.x} y={FIRE.y} t={t} s={1 + Math.min(1, pop / 10) * 0.6} />);
  TENTS.forEach((h, i) => {
    const s = appear(pop, h.th) * (pop >= 300 ? Math.max(0, 1 - (pop - 300) / 200) : 1);
    if (s > 0.01) add(h.y, <Tent key={`t${i}`} x={h.x} y={h.y} s={s} />);
  });
  HUTS.forEach((h, i) => {
    const s = appear(pop, h.th);
    if (s > 0.01) add(h.y, <Hut key={`h${i}`} x={h.x} y={h.y} s={s} />);
  });
  FIELDS.forEach((f, i) => {
    const s = appear(pop, f.th);
    if (s > 0.01) add(f.y - 40, <Field key={`f${i}`} x={f.x} y={f.y} s={s} crop={i % 2 ? '#7ccf5a' : '#e8c547'} />);
  });
  SHEEP.forEach((sh, i) => {
    const s = appear(pop, sh.th);
    if (s > 0.01) add(sh.y, <Sheep key={`s${i}`} x={sh.x} y={sh.y} s={s} t={t} seed={i} />);
  });
  if (pop >= 60) add(1120, <Well key="well" x={470} y={1120} s={appear(pop, 60)} />);
  HOUSES.forEach((h, i) => {
    const s = appear(pop, h.th);
    if (s > 0.01) add(h.y, <House key={`ho${i}`} x={h.x} y={h.y} s={s} roof={i % 3 ? '#d9472b' : '#2f5fa8'} />);
  });
  STALLS.forEach((st, i) => {
    const s = appear(pop, st.th);
    if (s > 0.01) add(st.y, <Stall key={`st${i}`} x={st.x} y={st.y} s={s} color={st.c} />);
  });
  if (pop >= 300) add(870, <Smithy key="smith" x={700} y={870} s={appear(pop, 300) * 0.9} t={t} />);
  if (pop >= 650) add(800, <Tower key="tower" x={540} y={800} s={appear(pop, 650)} t={t} />);
  if (pop >= 500) add(1240, <Dock key="dock" x={250} y={1240} s={appear(pop, 500)} t={t} />);

  // Habitantes visibles (como mucho 70 para no saturar)
  const shown = Math.min(Math.floor(pop), maxShown);
  for (let k = 0; k < shown; k++) {
    const home = k === 0 ? {x: 590, y: 990} : inIsland(k);
    const wander = k === 0 ? 0 : 14;
    const x = home.x + Math.sin(t * 0.6 + k) * wander;
    const y = home.y + Math.cos(t * 0.5 + k * 1.3) * wander * 0.5;
    const s = k === 0 ? 1.5 : appear(pop, k + 1) * 1.2;
    const tag = tags.find((tg) => tg.k === k);
    add(
      y,
      <Villager key={`v${k}`} x={x} y={y} t={t} seed={k} s={s} crown={k === 1 && pop >= 10} tag={tag?.label} wave={k === 0 ? Math.sin(t * 2) * 10 : 0} />,
    );
  }

  items.sort((a, b) => a.y - b.y);

  const wave = (k) => Math.sin(t * 1.2 + k) * 6;
  return (
    <g>
      {/* Olas alrededor */}
      {[0, 1, 2].map((k) => (
        <ellipse
          key={k}
          cx={ISLAND.x}
          cy={ISLAND.y + 10}
          rx={ISLAND.rx + 40 + k * 45 + wave(k)}
          ry={ISLAND.ry + 30 + k * 35 + wave(k) * 0.6}
          fill="none"
          stroke="#bfe9ff"
          strokeOpacity={0.35 - k * 0.1}
          strokeWidth={6}
          strokeDasharray="40 30"
          strokeDashoffset={t * 20 * (k % 2 ? 1 : -1)}
        />
      ))}
      <ellipse cx={ISLAND.x} cy={ISLAND.y + 18} rx={ISLAND.rx + 14} ry={ISLAND.ry + 14} fill="#7fd3e6" opacity={0.6} />
      <ellipse cx={ISLAND.x} cy={ISLAND.y} rx={ISLAND.rx} ry={ISLAND.ry} fill="#f2d79b" />
      <ellipse cx={ISLAND.x} cy={ISLAND.y - 12} rx={ISLAND.rx - 50} ry={ISLAND.ry - 46} fill="#6cc25a" />
      <ellipse cx={ISLAND.x - 80} cy={ISLAND.y - 40} rx={160} ry={80} fill="#7fd06a" opacity={0.6} />
      {pop >= 150 ? (
        <path
          d={`M ${ISLAND.x - 330} ${ISLAND.y + 40} Q ${ISLAND.x} ${ISLAND.y - 60} ${ISLAND.x + 330} ${ISLAND.y + 30}`}
          fill="none"
          stroke="#d9c08a"
          strokeWidth={18 * appear(pop, 150)}
          strokeLinecap="round"
        />
      ) : null}
      {items.map((it) => it.el)}
    </g>
  );
};

export const Ocean = ({t, night = 0}) => (
  <g>
    <defs>
      <linearGradient id="sea" x1="0" y1="0" x2="0" y2="1">
        <stop offset="0" stopColor="#1d8fd1" />
        <stop offset="1" stopColor="#0d4f8f" />
      </linearGradient>
    </defs>
    <rect x={0} y={0} width={1080} height={1920} fill="url(#sea)" />
    {Array.from({length: 40}).map((_, i) => {
      const x = (random(`ox${i}`) * 1200 + t * 12) % 1200 - 60;
      const y = random(`oy${i}`) * 1920;
      return (
        <path
          key={i}
          d={`M${x} ${y} q12 -8 24 0 q12 8 24 0`}
          fill="none"
          stroke="#bfe9ff"
          strokeOpacity={0.35 + 0.2 * Math.sin(t * 2 + i)}
          strokeWidth={4}
          strokeLinecap="round"
        />
      );
    })}
    {night > 0 ? <rect x={0} y={0} width={1080} height={1920} fill="#050a2a" opacity={0.55 * night} /> : null}
  </g>
);

// Contador de la serie (arriba)
export const Hud = ({pop, day = 1, highlight = 0, label = 'DÍA'}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 18,
      fontFamily: FONT,
      fontWeight: 900,
      color: '#fff',
      background: 'rgba(8,12,30,0.82)',
      border: `4px solid ${highlight > 0 ? C.accent : 'rgba(255,255,255,0.2)'}`,
      borderRadius: 60,
      padding: '10px 28px 10px 14px',
      boxShadow: highlight > 0 ? `0 0 ${50 * highlight}px ${C.accent}` : '0 10px 30px rgba(0,0,0,0.4)',
      scale: String(1 + 0.15 * highlight),
    }}
  >
    <div style={{background: C.accent, color: '#0b0b14', borderRadius: 40, padding: '6px 18px', fontSize: 34}}>{label} {day}</div>
    <svg width={44} height={44} viewBox="0 0 24 24">
      <circle cx={12} cy={7} r={5} fill="#fff" />
      <path d="M3 22 C3 15 21 15 21 22 Z" fill="#fff" />
    </svg>
    <div style={{fontSize: 54}}>{String(Math.round(pop)).replace(/\B(?=(\d{3})+(?!\d))/g, '.')}</div>
    <div style={{fontSize: 26, color: C.cyan, marginTop: 10}}>HABITANTES</div>
  </div>
);

export const popScale = (t, a, b, p0, p1) => {
  const k = r(t, a, b, 0, 1, (x) => x);
  return Math.exp(Math.log(p0) + (Math.log(p1) - Math.log(p0)) * k);
};
