import React from 'react';
import {AbsoluteFill, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, Scene, lin, r, useT} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, Check, Heart, ProgressBar} from '../tunel/Visuals';
import {Hud, IslandWorld, Ocean, Villager, popScale} from './Island';
import WORDS from '../../public/civilizacion-02.words.json';
import {makeW} from './words';

const W = makeW(WORDS);

export const DURATION = WORDS[WORDS.length - 1].end + 0.8;
const POP = 58; // 1 fundador + 17 TikTok + 40 Instagram

const CHUNKS = chunkWords(WORDS, [
  'persona', 'ocho', 'problema', 'construido', 'cazadores', 'pescadores', 'doctora', 'herrero',
  'hierro', 'alan', 'cultivos', 'mil', 'catalina', 'kiosco', 'thiago', 'millonario', 'conchas',
  'visionario', 'dylan', 'horizonte', 'manda', 'jorge', 'líder', 'ángel', 'juandi', 'frainel',
  'fuerte', 'elecciones', 'jefe', 'likes', 'gobernará', 'aldea', 'aprende', 'oficio', 'ideas', 'realidad', 'reglas', 'seguirme', 'mañana', 'historia',
]);

// Habitantes reales (de los comentarios), con su sitio en la isla
const CAST = [
  {n: 'MELISA', x: 430, y: 900, prop: 'cross', shirt: '#ffffff'},
  {n: 'OSVALDO', x: 492, y: 1022, prop: 'hammer', shirt: '#7d8597'},
  {n: 'THEYY', x: 282, y: 868, prop: 'spear', shirt: '#8a5a2c'},
  {n: 'SAMI', x: 345, y: 818, prop: 'spear', shirt: '#a0703f'},
  {n: 'JUANDI', x: 408, y: 876, prop: 'spear', shirt: '#6b3f1f'},
  {n: 'EMII', x: 250, y: 1172, prop: 'rod', shirt: C.cyan},
  {n: 'TESERACTO', x: 842, y: 1192, prop: 'spear', shirt: '#2f5fa8'},
  {n: 'ALAN', x: 800, y: 962, prop: 'hoe', shirt: '#e8c547'},
  {n: 'CATALINA', x: 642, y: 892, shirt: C.pink},
  {n: 'THIAGO', x: 708, y: 910, prop: 'shells', shirt: C.accent},
  {n: 'DYLAN', x: 560, y: 712, shirt: '#a78bfa'},
  {n: 'GERARDO', x: 515, y: 1142, shirt: C.red},
  {n: 'RAFA', x: 612, y: 1142, shirt: '#ffd23f'},
  {n: 'PABLO', x: 720, y: 1080, prop: 'bike', shirt: C.green},
  {n: 'JOSEP', x: 582, y: 958, shirt: C.hot},
  {n: 'JULIA', x: 410, y: 1062, shirt: '#ff9ad5'},
  {n: 'JORGE', x: 610, y: 800, shirt: '#3ddc84'},
  {n: 'ÁNGEL', x: 470, y: 790, shirt: '#5ec8ff'},
  {n: 'FRAINEL', x: 690, y: 828, shirt: '#333'},
];

const FOUNDERS = [
  'MELISA · DOCTORA', 'OSVALDO · HERRERO', 'THEYY · CAZADOR', 'SAMI · CAZADORA', 'JUANDI · CAZADOR LÍDER',
  'EMII · PESCADOR', 'TESERACTO · GUARDIA COSTERO', 'ALAN · GRANJERO', 'CATALINA · KIOSQUERA', 'THIAGO · MILLONARIO',
  'DYLAN · VISIONARIO', 'GERARDO · FUTBOLISTA', 'RAFA · FUTBOLISTA', 'PABLO · CICLISTA', 'JORGE · LÍDER',
  'ÁNGEL · EXPLORADOR', 'FRAINEL · GUERRERO', 'JOSEP · GUARDIÁN DEL FUEGO', 'JULIA · CONSTRUCTORA',
  'DAVID · COCINERO', 'CIANTINI · RECOLECTORA', 'ESDRAS · EXPLORADOR', 'JULEN · CHAMÁN', 'PAINT · PRIMITIVO',
];

// Accesorios de cada oficio (coordenadas relativas al aldeano)
const Prop = ({kind, t}) => {
  if (kind === 'spear') return <line x1={12} y1={8} x2={20} y2={-58} stroke="#6b3f1f" strokeWidth={3} strokeLinecap="round" />;
  if (kind === 'rod')
    return (
      <g>
        <line x1={10} y1={-20} x2={-40} y2={-60} stroke="#6b3f1f" strokeWidth={2.5} />
        <path d={`M-40 -60 Q-48 -30 ${-46 + Math.sin(t * 2) * 3} 4`} fill="none" stroke="#fff" strokeWidth={1.2} />
      </g>
    );
  if (kind === 'hammer')
    return (
      <g transform={`rotate(${Math.sin(t * 8) * 30} 8 -20)`}>
        <line x1={8} y1={-20} x2={20} y2={-36} stroke="#6b3f1f" strokeWidth={3} />
        <rect x={14} y={-44} width={14} height={8} rx={2} fill="#9aa3b8" transform="rotate(-40 20 -40)" />
      </g>
    );
  if (kind === 'hoe')
    return (
      <g>
        <line x1={12} y1={6} x2={18} y2={-46} stroke="#6b3f1f" strokeWidth={3} />
        <rect x={14} y={-50} width={14} height={5} fill="#9aa3b8" />
      </g>
    );
  if (kind === 'cross')
    return (
      <g transform="translate(0 -18)">
        <rect x={-2} y={-6} width={4} height={12} fill={C.red} />
        <rect x={-6} y={-2} width={12} height={4} fill={C.red} />
      </g>
    );
  if (kind === 'shells')
    return (
      <g transform="translate(18 0)">
        {[0, 1, 2, 3, 4].map((k) => (
          <path key={k} d="M0 0 Q5 -10 10 0 Z" fill={k % 2 ? '#ffd9c2' : '#fff1e0'} stroke="#d9a47a" strokeWidth={0.8} transform={`translate(${(k % 3) * 8} ${-Math.floor(k / 3) * 6})`} />
        ))}
      </g>
    );
  if (kind === 'bike')
    return (
      <g transform="translate(0 4)">
        <circle cx={-12} cy={0} r={7} fill="none" stroke="#333" strokeWidth={2} />
        <circle cx={12} cy={0} r={7} fill="none" stroke="#333" strokeWidth={2} />
        <path d="M-12 0 L-2 -10 L12 0 M-2 -10 L6 -10" fill="none" stroke={C.red} strokeWidth={2} />
      </g>
    );
  return null;
};

const Cast = ({t, focus = []}) => (
  <g>
    {/* Kiosco de Catalina */}
    <g transform="translate(642 872)">
      <rect x={-26} y={-16} width={52} height={16} fill="#a0703f" />
      <rect x={-28} y={-42} width={4} height={28} fill="#6b3f1f" />
      <rect x={24} y={-42} width={4} height={28} fill="#6b3f1f" />
      {[0, 1, 2, 3].map((k) => (
        <rect key={k} x={-30 + k * 15} y={-48} width={15} height={10} fill={k % 2 ? '#fff' : C.pink} />
      ))}
    </g>
    {/* Coco de Gerardo y Rafa */}
    <circle cx={563 + Math.sin(t * 3) * 34} cy={1132 - Math.abs(Math.cos(t * 3)) * 26} r={7} fill="#7a4a24" stroke="#5a3418" strokeWidth={1.5} />
    {/* Roca de Dylan */}
    <ellipse cx={560} cy={716} rx={30} ry={12} fill="#9aa3b8" />
    {CAST.map((c, i) => (
      <g key={c.n}>
        <Villager x={c.x} y={c.y} t={t} seed={i + 3} s={1.5} shirt={c.shirt} tag={focus.includes(c.n) ? c.n : undefined} wave={c.n === 'DYLAN' ? 60 : 0} />
        <g transform={`translate(${c.x} ${c.y}) scale(1.5)`}>
          <Prop kind={c.prop} t={t} />
        </g>
      </g>
    ))}
  </g>
);

// Quién lleva etiqueta con su nombre en cada plano
const FOCUS = [
  [W('ya', 1), ['THEYY', 'SAMI', 'JUANDI']],
  [W('pescadores', 0), ['EMII', 'TESERACTO']],
  [W('una', 1), ['MELISA']],
  [W('hasta', 0), ['OSVALDO']],
  [W('alan', 0), ['ALAN']],
  [W('catalina', 0), ['CATALINA']],
  [W('thiago', 0), ['THIAGO']],
  [W('y', 3), ['DYLAN']],
  [(W('y', 3) + 4.96), []],
];
const focusAt = (t) => {
  let f = [];
  for (const [at, names] of FOCUS) if (t >= at) f = names;
  return f;
};

// Cámara que salta de personaje en personaje
const SHOTS = [
  {t: 0, x: 575, y: 975, z: 2.8},
  {t: 4.04, x: 540, y: 975, z: 1},
  {t: 11.68, x: 346, y: 850, z: 2.6},
  {t: 12.84, x: 545, y: 1140, z: 1.45},
  {t: 13.84, x: 430, y: 890, z: 2.8},
  {t: 14.68, x: 495, y: 1005, z: 2.8},
  {t: 19.64, x: 800, y: 960, z: 2.6},
  {t: 24.68, x: 672, y: 890, z: 2.6},
  {t: 29.64, x: 560, y: 720, z: 2.9},
  {t: 34.69, x: 540, y: 975, z: 1},
];
const cam = (t) => {
  let i = 0;
  while (i < SHOTS.length - 1 && t >= SHOTS[i + 1].t) i++;
  const a = SHOTS[Math.max(0, i - 1)];
  const b = SHOTS[i];
  if (i === 0) return b;
  const k = r(t, b.t, b.t + 0.7, 0, 1, INOUT);
  return {x: a.x + (b.x - a.x) * k, y: a.y + (b.y - a.y) * k, z: a.z + (b.z - a.z) * k};
};

const Camera = ({c, cy = 880, children}) => (
  <g transform={`translate(540 ${cy}) scale(${c.z}) translate(${-c.x} ${-c.y})`}>{children}</g>
);

// =====================================================================
// 1-2. LA ISLA CRECE Y SUS HABITANTES (0 – (W('y', 3) + 4.86) s)
// =====================================================================
const IslandTour = () => {
  const t = useT();
  const pop = t < (W('hoy', 0) + 0.06) ? 1 : popScale(t, (W('hoy', 0) + 0.06), (W('ocho', 0) + 0.22), 1, POP);
  const c = cam(t);
  const castIn = t > (W('hoy', 0) + 0.36);
  const rosterDim = t > W('pero', 0) && t < (W('ya', 1) + 0.07) ? Math.min(lin(t, W('pero', 0), (W('pero', 0) + 0.31), 0, 0.6), lin(t, (W('pero', 0) + 2.31), (W('ya', 1) + 0.07), 0.6, 0)) : 0;
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <Camera c={c}>
          <IslandWorld t={t} pop={pop} maxShown={castIn ? 26 : 1} />
          {castIn ? (
            <g opacity={lin(t, (W('hoy', 0) + 0.36), (W('hoy', 0) + 1.56), 0, 1)}>
              <Cast t={t} focus={focusAt(t)} />
            </g>
          ) : null}
        </Camera>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={pop} day={2} highlight={t > (W('hoy', 0) + 0.06) && t < (W('ocho', 0) + 0.62) ? 0.7 : 0} />
      </div>
      <Pop at={0.1} out={(W('hoy', 0) - 0.14)} style={{top: 400, left: 0, right: 0}}>
        <Pill color="#fff" size={46}>
          DÍA 1: 1 HABITANTE
        </Pill>
      </Pop>
      <Pop at={(W('hoy', 0) + 0.56)} out={(W('ocho', 0) + 0.52)} style={{top: 400, left: 0, right: 0}}>
        <div style={{display: 'flex', gap: 16}}>
          <Pill color="#111" text="#fff" size={44} style={{border: `4px solid ${C.cyan}`}}>
            TIKTOK +17
          </Pill>
          <Pill color="#111" text="#fff" size={44} style={{border: `4px solid ${C.pink}`}}>
            INSTAGRAM +40
          </Pill>
        </div>
      </Pop>
      <Pop at={W('y', 1)} out={(W('y', 1) + 2.64)} style={{top: 390, left: 0, right: 0, flexDirection: 'column'}}>
        <svg width={170} height={150} viewBox="-85 -80 170 150">
          <path d="M-60 40 L-60 -20 L-30 10 L0 -40 L30 10 L60 -20 L60 40 Z" fill={C.accent} stroke="#05060f" strokeWidth={8} strokeLinejoin="round" />
          <text y={34} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={60} fill="#05060f">
            ?
          </text>
        </svg>
        <BigText size={80} color={C.red}>
          PRIMER GRAN PROBLEMA
        </BigText>
      </Pop>

      {/* Habitantes fundadores */}
      {rosterDim > 0 ? <AbsoluteFill style={{background: '#050a2a', opacity: rosterDim}} /> : null}
      <Pop at={(W('pero', 0) + 0.11)} out={(W('pero', 0) + 2.36)} style={{top: 380, left: 40, right: 40, flexDirection: 'column'}}>
        <BigText size={64} color={C.accent}>
          HABITANTES FUNDADORES
        </BigText>
        <div style={{display: 'flex', flexWrap: 'wrap', gap: 10, justifyContent: 'center', marginTop: 24}}>
          {FOUNDERS.map((f, i) => (
            <div
              key={f}
              style={{
                fontFamily: FONT,
                fontWeight: 800,
                fontSize: 26,
                color: '#0b0b14',
                background: i % 3 === 0 ? C.cyan : i % 3 === 1 ? '#fff' : C.accent,
                borderRadius: 30,
                padding: '6px 16px',
                scale: String(r(t, (W('pero', 0) + 0.21) + i * 0.05, (W('pero', 0) + 0.51) + i * 0.05, 0, 1, BACK)),
              }}
            >
              {f}
            </div>
          ))}
        </div>
      </Pop>

      {/* Oficios, en resumen */}
      {[
        [W('ya', 1), (W('ya', 1) + 1.07), 'CAZADORES', 'THEYY · SAMI · JUANDI', '#a0703f'],
        [W('pescadores', 0), (W('pescadores', 0) + 0.91), 'PESCA Y COSTA', 'EMII · TESERACTO', C.cyan],
        [W('una', 1), (W('una', 1) + 0.76), 'DOCTORA', 'MELISA', '#fff'],
        [W('hasta', 0), (W('aunque', 0) + 3.54), 'HERRERO', 'OSVALDO', '#c9ccd6'],
        [W('alan', 0), (W('como', 0) + 2.76), 'GRANJERO', 'ALAN', '#e8c547'],
        [W('catalina', 0), (W('catalina', 0) + 1.87), 'KIOSQUERA', 'CATALINA', C.pink],
        [W('thiago', 0), (W('en', 1) + 1.06), 'MILLONARIO', 'THIAGO', C.accent],
        [W('y', 3), (W('y', 3) + 4.76), 'VISIONARIO', 'DYLAN', '#a78bfa'],
      ].map(([at, out, role, who, col]) => (
        <Pop key={role} at={at} out={out} style={{top: 1210, left: 0, right: 0, flexDirection: 'column'}}>
          <Pill color={col} size={52}>
            {role}
          </Pill>
          <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 34, color: '#fff', marginTop: 8, textShadow: '0 4px 16px #000'}}>{who}</div>
        </Pop>
      ))}
      {/* Datos curiosos */}
      <Pop at={W('aunque', 0)} out={(W('aunque', 0) + 3.44)} style={{top: 400, left: 60, right: 60}}>
        <FactCard title="DATO" text="El hierro empezó a usarse hace unos 3.000 años" />
      </Pop>
      <Pop at={W('como', 0)} out={(W('como', 0) + 2.66)} style={{top: 400, left: 60, right: 60}}>
        <FactCard title="DATO" text="La agricultura nació hace unos (W('ya', 1) + 0.32) años" />
      </Pop>
      <Pop at={W('en', 1)} out={(W('en', 1) + 1.06)} style={{top: 400, left: 60, right: 60}}>
        <FactCard title="DATO" text="Las conchas se usaron como dinero durante siglos" />
      </Pop>
    </AbsoluteFill>
  );
};

const FactCard = ({title, text}) => (
  <div
    style={{
      display: 'flex',
      alignItems: 'center',
      gap: 18,
      background: 'rgba(8,12,30,0.9)',
      border: `4px solid ${C.accent}`,
      borderRadius: 28,
      padding: '16px 24px',
      fontFamily: FONT,
      color: '#fff',
    }}
  >
    <div style={{background: C.accent, color: '#0b0b14', fontWeight: 900, fontSize: 30, borderRadius: 16, padding: '6px 14px'}}>{title}</div>
    <div style={{fontWeight: 800, fontSize: 36, lineHeight: 1.15}}>{text}</div>
  </div>
);

// =====================================================================
// 3. ¿QUIÉN MANDA AQUÍ? ((W('y', 3) + 4.86) – (W('y', 6) + 3.44) s)
// =====================================================================
const CANDIDATES = [
  {n: 'JORGE', claim: '"EL LÍDER"', at: W('jorge', 0), shirt: '#3ddc84'},
  {n: 'ÁNGEL', claim: 'EXPLORADOR LÍDER', at: W('ángel', 0), shirt: '#5ec8ff'},
  {n: 'JUANDI', claim: 'CAZADOR LÍDER', at: W('juandi', 0), shirt: '#6b3f1f'},
  {n: 'FRAINEL', claim: 'EL MÁS FUERTE', at: W('y', 6), shirt: '#333'},
];

const LeadersScene = () => {
  const t = useT();
  const lineup = lin(t, (W('llega', 0) + 2.78), (W('jorge', 0) + 0.04), 0, 1);
  const active = [...CANDIDATES].reverse().find((c) => t >= c.at);
  // Ángel y Juandi se mencionan juntos
  const isLit = (c) => active && (c.n === active.n || (active.n === 'JUANDI' && c.n === 'ÁNGEL' && t < W('y', 6)));
  const crownIdx = t > (W('y', 6) + 0.74) ? Math.floor((t * 2.5) % 4) : CANDIDATES.indexOf(active ?? CANDIDATES[0]);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={lineup * 0.7} />
        <g opacity={1 - lineup}>
          <g transform={`translate(540 880) scale(${r(t, (W('y', 3) + 4.86), (W('llega', 0) + 2.78), 1, 1.15)}) translate(-540 -975)`}>
            <IslandWorld t={t} pop={POP} maxShown={26} />
            <Cast t={t} />
          </g>
        </g>
        {lineup > 0 ? (
          <g opacity={lineup}>
            <ellipse cx={540} cy={1200} rx={560} ry={120} fill="#f2d79b" />
            {CANDIDATES.map((c, i) => {
              const x = 165 + i * 250;
              const lit = isLit(c);
              const flex = c.n === 'FRAINEL' && t > W('y', 6) ? 40 + Math.sin(t * 10) * 25 : 0;
              return (
                <g key={c.n}>
                  {lit ? <path d={`M${x - 30} 260 L${x + 30} 260 L${x + 130} 1200 L${x - 130} 1200 Z`} fill="#fff6c2" opacity={0.25} /> : null}
                  <g opacity={lit || t > (W('y', 6) + 0.74) ? 1 : 0.45}>
                    <Villager x={x} y={1150} t={t} seed={i + 30} s={(W('hoy', 0) + 1.16)} shirt={c.shirt} wave={flex || (lit ? Math.sin(t * 6) * 30 : 0)} />
                  </g>
                  {i === crownIdx ? (
                    <g transform={`translate(${x} ${800 + Math.sin(t * 5) * 10}) scale(1.4)`}>
                      <path d="M-40 26 L-40 -14 L-20 6 L0 -26 L20 6 L40 -14 L40 26 Z" fill={C.accent} stroke="#05060f" strokeWidth={6} strokeLinejoin="round" />
                    </g>
                  ) : null}
                </g>
              );
            })}
          </g>
        ) : null}
      </svg>
      <Pop at={W('llega', 0)} out={(W('llega', 0) + 2.78)} style={{top: 400, left: 0, right: 0}}>
        <BigText size={110}>
          ¿QUIÉN MANDA
          <br />
          <span style={{color: C.accent}}>AQUÍ?</span>
        </BigText>
      </Pop>
      {lineup > 0 ? (
        <div style={{position: 'absolute', top: 1230, left: 0, right: 0, display: 'flex', justifyContent: 'space-around', padding: '0 20px', opacity: lineup}}>
          {CANDIDATES.map((c) => (
            <div key={c.n} style={{display: 'flex', flexDirection: 'column', alignItems: 'center', width: 240, opacity: isLit(c) || t > (W('y', 6) + 0.74) ? 1 : 0.5}}>
              <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 46, color: '#fff', WebkitTextStroke: '8px #05060f', paintOrder: 'stroke fill'}}>{c.n}</div>
              <div style={{fontFamily: FONT, fontWeight: 800, fontSize: 22, color: '#0b0b14', background: C.accent, borderRadius: 14, padding: '4px 10px', marginTop: 4, whiteSpace: 'nowrap'}}>{c.claim}</div>
            </div>
          ))}
        </div>
      ) : null}
      <Pop at={(W('jorge', 0) + 0.04)} style={{top: 260 + 150, left: 0, right: 0}}>
        <BigText size={84} color={C.red}>
          ¡LUCHA POR EL PODER!
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 4. ELECCIONES ((W('y', 6) + 3.44) – (W('gobernará', 0) + 2.36) s)
// =====================================================================
const ElectionScene = () => {
  const t = useT();
  const typed = 'Debo ser el jefe porque…';
  const n = Math.floor(lin(t, (W('si', 0) + 0.16), (W('comenta', 0) + 1.28), 0, typed.length));
  const likes = Math.round(r(t, (W('quien', 0) + 0.02), (W('quien', 0) + 2.22), 0, 1247, (x) => x * x));
  const crown = r(t, W('gobernará', 0), (W('gobernará', 0) + 0.56), -500, 0, (x) => x * x);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={0.7} />
      </svg>
      <Pop at={W('así', 0)} style={{top: 260, left: 0, right: 0, flexDirection: 'column'}}>
        <svg width={220} height={200} viewBox="-110 -100 220 200">
          <rect x={-80} y={-20} width={160} height={110} rx={10} fill="#e8ecf5" stroke="#05060f" strokeWidth={8} />
          <rect x={-50} y={-30} width={100} height={14} rx={6} fill="#05060f" />
          <g transform={`translate(0 ${-60 + Math.abs(Math.sin(t * 3)) * 30})`}>
            <rect x={-34} y={-30} width={68} height={44} fill="#fff" stroke="#05060f" strokeWidth={5} />
            <path d="M-16 -8 L-4 4 L18 -18" fill="none" stroke={C.green} strokeWidth={7} strokeLinecap="round" />
          </g>
        </svg>
        <BigText size={110} color={C.accent}>
          ELECCIONES
        </BigText>
      </Pop>
      <Pop at={W('si', 0)} style={{top: 760, left: 60, right: 60}}>
        <div
          style={{
            width: '100%',
            boxSizing: 'border-box',
            display: 'flex',
            alignItems: 'center',
            gap: 20,
            background: t > W('gobernará', 0) ? 'rgba(255,210,63,0.2)' : 'rgba(8,12,30,0.9)',
            border: `5px solid ${t > W('gobernará', 0) ? C.accent : 'rgba(255,255,255,0.2)'}`,
            borderRadius: 30,
            padding: '22px 26px',
            fontFamily: FONT,
            color: '#fff',
            position: 'relative',
          }}
        >
          <div style={{width: 80, height: 80, borderRadius: 40, background: `linear-gradient(135deg, ${C.cyan}, ${C.pink})`, flexShrink: 0}} />
          <div style={{flex: 1}}>
            <div style={{fontSize: 28, fontWeight: 800, color: '#b9c3dd'}}>@tú</div>
            <div style={{fontSize: 42, fontWeight: 900}}>
              {typed.slice(0, n)}
              <span style={{opacity: Math.sin(t * 10) > 0 ? 1 : 0}}>|</span>
            </div>
          </div>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', scale: String(1 + (t > (W('quien', 0) + 0.02) && t < (W('gobernará', 0) - 0.04) ? 0.15 * Math.abs(Math.sin(t * 8)) : 0))}}>
            <Heart size={56} color={likes > 0 ? C.pink : '#c9cfe0'} />
            <div style={{fontWeight: 900, fontSize: 30}}>{likes.toLocaleString('es-ES')}</div>
          </div>
          {t > W('gobernará', 0) ? (
            <svg width={150} height={110} viewBox="-75 -55 150 110" style={{position: 'absolute', top: -95 + crown, left: 30}}>
              <path d="M-60 40 L-60 -20 L-30 10 L0 -40 L30 10 L60 -20 L60 40 Z" fill={C.accent} stroke="#05060f" strokeWidth={8} strokeLinejoin="round" />
            </svg>
          ) : null}
        </div>
      </Pop>
      <Pop at={W('quien', 0)} out={(W('quien', 0) + 2.22)} style={{top: 1000, left: 0, right: 0}}>
        <Pill color={C.pink} text="#fff" size={50}>
          + LIKES = + VOTOS
        </Pill>
      </Pop>
      <Pop at={W('gobernará', 0)} style={{top: 1000, left: 0, right: 0}}>
        <BigText size={80} color={C.accent}>
          ¡GOBIERNA LA ISLA!
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 5. LAS REGLAS: seguir para unirte, comentar ideas, el más votado se cumple
// =====================================================================
const IDEAS = [
  {user: '@tú', text: 'Quiero ser panadero 🍞', likes: 312},
  {user: '@otro', text: 'Idea: ¡construir un barco!', likes: 2480},
];

const RulesScene = () => {
  const t = useT();
  const tapAt = W('seguirme') + 0.3;
  const tap = t > tapAt - 0.15 && t < tapAt + 0.15 ? 0.9 : 1;
  const tapped = t > tapAt;
  const pop = POP;
  const winner = t > W('cada');
  const boat = r(t, W('realidad'), W('realidad') + 0.6, 0, 1, BACK);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <g transform="translate(540 1000) scale(1.05) translate(-540 -975)">
          <IslandWorld t={t} pop={pop} maxShown={26} />
          <Cast t={t} />
          {boat > 0 ? (
            <g transform={`translate(${170 + Math.sin(t * 1.5) * 8} 1250) scale(${boat * 1.6})`}>
              <path d="M-60 0 L60 0 L44 26 L-44 26 Z" fill="#8a5a2c" />
              <line x1={0} y1={0} x2={0} y2={-90} stroke="#6b3f1f" strokeWidth={5} />
              <path d="M4 -86 Q50 -50 4 -14 Z" fill="#fff" />
              <path d={`M0 -90 L26 -84 L0 -78 Z`} fill={C.accent} />
            </g>
          ) : null}
        </g>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={pop} day={2} />
      </div>
      <Pop at={W('recuerda') - 0.1} out={W('si', 1) - 0.2} style={{top: 380, left: 0, right: 0, flexDirection: 'column'}}>
        <Pill color="#fff" size={52}>
          LAS REGLAS
        </Pill>
        <div style={{display: 'flex', alignItems: 'center', gap: 16, marginTop: 18, padding: '20px 56px', borderRadius: 80, background: tapped ? 'rgba(255,255,255,0.25)' : C.pink, fontFamily: FONT, fontWeight: 900, fontSize: 58, color: '#fff', scale: String(tap)}}>
          {tapped ? <Check size={58} /> : '+'} {tapped ? 'SIGUIENDO' : 'SEGUIR'}
        </div>
        <div style={{marginTop: 14}}>
          <Pill color={C.green} size={40}>
            = VIVES EN LA ISLA
          </Pill>
        </div>
      </Pop>
      <Pop at={W('si', 1) - 0.1} style={{top: 360, left: 50, right: 50, flexDirection: 'column'}}>
        <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 40, color: '#fff', background: 'rgba(8,12,30,0.88)', borderRadius: 26, padding: '12px 22px', marginBottom: 14}}>
          OPCIONAL: COMENTA TU OFICIO O TUS IDEAS
        </div>
        {IDEAS.map((c, i) => {
          const hl = winner && i === 1;
          const likes = Math.round(c.likes * r(t, W('comenta', 1) + i * 0.3, W('likes', 1) + 0.5, 0.05, 1));
          return (
            <div
              key={c.user}
              style={{
                width: '100%',
                boxSizing: 'border-box',
                display: 'flex',
                alignItems: 'center',
                gap: 16,
                marginTop: 12,
                background: hl ? 'rgba(255,210,63,0.22)' : 'rgba(8,12,30,0.88)',
                border: `4px solid ${hl ? C.accent : 'rgba(255,255,255,0.15)'}`,
                borderRadius: 24,
                padding: '12px 20px',
                fontFamily: FONT,
                color: '#fff',
                scale: String(r(t, W('comenta', 1) + i * 0.4, W('comenta', 1) + i * 0.4 + 0.4, 0, 1, BACK)),
              }}
            >
              <div style={{width: 56, height: 56, borderRadius: 28, background: `linear-gradient(135deg, ${C.cyan}, ${C.pink})`, flexShrink: 0}} />
              <div style={{flex: 1}}>
                <div style={{fontSize: 22, fontWeight: 800, color: '#b9c3dd', display: 'flex', gap: 10}}>
                  {c.user}
                  {hl ? <span style={{background: C.accent, color: '#0b0b14', borderRadius: 10, padding: '0 10px', fontWeight: 900}}>MÁS LIKES</span> : null}
                </div>
                <div style={{fontSize: 36, fontWeight: 900}}>{c.text.replace(' 🍞', '')}</div>
              </div>
              <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
                <Heart size={40} color={hl ? C.pink : '#c9cfe0'} />
                <div style={{fontWeight: 900, fontSize: 22}}>{likes >= 1000 ? `${(likes / 1000).toFixed(1).replace('.', ',')} K` : likes}</div>
              </div>
            </div>
          );
        })}
      </Pop>
      <Pop at={W('realidad') - 0.1} style={{top: 1220, left: 0, right: 0}}>
        <BigText size={76} color={C.accent}>
          ¡SE HACE REALIDAD!
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 6. CIERRE: faltan 42 para ser aldea
// =====================================================================
const OutroScene = () => {
  const t = useT();
  const tapAt = W('sígueme') + 0.4;
  const tap = t > tapAt - 0.15 && t < tapAt + 0.15 ? 0.9 : 1;
  const tapped = t > tapAt;
  const pop = POP + (tapped ? 1 : 0);
  const fill = r(t, W('faltan', 1) + 0.1, W('faltan', 1) + 1.3, 0, POP / 100);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <g transform="translate(540 950) scale(1.05) translate(-540 -975)">
          <IslandWorld t={t} pop={pop} maxShown={26} />
          <Cast t={t} />
        </g>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={pop} day={2} highlight={tapped ? lin(t, tapAt, tapAt + 1.2, 1, 0) : 0} />
      </div>
      <Pop at={W('faltan', 1)} out={W('sígueme') - 0.2} style={{top: 390, left: 70, right: 70, flexDirection: 'column'}}>
        <div style={{width: '100%', height: 54, borderRadius: 30, background: 'rgba(8,12,30,0.85)', border: '4px solid #fff', overflow: 'hidden'}}>
          <div style={{width: `${fill * 100}%`, height: '100%', background: `linear-gradient(90deg, ${C.green}, ${C.accent})`}} />
        </div>
        <div style={{display: 'flex', justifyContent: 'space-between', width: '100%', fontFamily: FONT, fontWeight: 900, fontSize: 32, color: '#fff', marginTop: 8, textShadow: '0 3px 10px #000'}}>
          <span>TRIBU · 58</span>
          <span>ALDEA · 100</span>
        </div>
        <BigText size={72} color={C.accent} style={{marginTop: 10}}>
          ¡FALTAN 42!
        </BigText>
      </Pop>
      <Pop at={W('sígueme') - 0.1} style={{top: 400, left: 0, right: 0}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 16, padding: '22px 64px', borderRadius: 80, background: tapped ? 'rgba(255,255,255,0.25)' : C.pink, fontFamily: FONT, fontWeight: 900, fontSize: 62, color: '#fff', scale: String(tap), boxShadow: tapped ? 'none' : `0 0 ${40 + 20 * Math.sin(t * 6)}px ${C.pink}`}}>
          {tapped ? <Check size={62} /> : '+'} {tapped ? 'SIGUIENDO' : 'SEGUIR'}
        </div>
      </Pop>
      <Pop at={W('entra') - 0.1} style={{top: 1180, left: 0, right: 0}}>
        <BigText size={86} color={C.accent}>
          ENTRA EN LA HISTORIA
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
export const Episodio02 = () => (
  <AbsoluteFill style={{backgroundColor: '#0d4f8f'}}>
    <Scene name="La isla y sus habitantes" start={0} end={W('pero', 1) - 0.3} fadeOut={false}>
      <IslandTour />
    </Scene>
    <Scene name="¿Quién manda?" start={W('pero', 1) - 0.3} end={W('así') - 0.3}>
      <LeadersScene />
    </Scene>
    <Scene name="Elecciones" start={W('así') - 0.3} end={W('recuerda') - 0.4}>
      <ElectionScene />
    </Scene>
    <Scene name="Reglas" start={W('recuerda') - 0.4} end={W('faltan', 1) - 0.3}>
      <RulesScene />
    </Scene>
    <Scene name="Cierre" start={W('faltan', 1) - 0.3} end={DURATION} fadeOut={false}>
      <OutroScene />
    </Scene>
    <Brand hideAt={DURATION} />
    <ProgressBar />
    <Captions chunks={CHUNKS} />
    <Audio src={staticFile('civilizacion-02.mp3')} />
  </AbsoluteFill>
);
