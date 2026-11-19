import React from 'react';
import {AbsoluteFill, Img, random, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, Scene, lin, r, useT} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, Check, ProgressBar} from '../tunel/Visuals';
import {makeWa} from '../civilizacion/words';
import {Human} from './Prehistoria';
import {IslandWorld, Villager} from '../civilizacion/Island';
import {Landmarks, SPOTS} from '../civilizacion/Landmarks';
import {Ship, Wall} from '../civilizacion/Dia05';
import WORDS from '../../public/yt-futuro.words.json';
import PARAS from '../../public/yt-futuro.paras.json';

// ¿Qué pasaría si pudieras ver 5 segundos en el futuro? (vídeo largo 16:9)
// Lenguaje visual: lo que pasa AHORA se dibuja normal; lo que pasará dentro
// de 5 segundos aparece como un "fantasma" cian y transparente.

const Wa = makeWa(WORDS);
const P = PARAS;
const VOICE_END = WORDS[WORDS.length - 1].end;
const END_SCREEN = 12;
export const DURATION = VOICE_END + 1 + END_SCREEN;
const FUT = '#5ee7ff';

const CHUNKS = chunkWords(
  WORDS,
  [
    'vaso', 'romperse', 'atrapas', 'cinco', 'futuro', 'imparable', 'cabeza', 'helado', 'hacerlo', 'aprende', 'reglas',
    'cambia', 'tráfico', 'catorce', 'setenta', 'vidas', 'jugar', 'tijera', 'robot', 'japón', 'penalti', 'portero',
    'intocable', 'carismática', 'problema', 'paradoja', 'dinero', 'casino', 'ruleta', 'bolsa', 'eternidad', 'ricas',
    'cuenta', 'ejército', 'arma', 'libre', 'sorprendería', 'sorpresa', 'placer', 'agotador', 'real', 'normales',
    'poquito', 'décima', 'pasado', 'prediciendo', 'civilización', 'habitante', 'dylan', 'velas', 'seguirme',
    'veinte', 'marianas', 'suscríbete',
  ],
  6,
  40,
);

const CANVAS = {width: 1920, height: 1080, viewBox: '0 0 1920 1080', style: {position: 'absolute'}};

const Title = ({children, size = 96, color = '#fff', style}) => (
  <BigText size={size} color={color} stroke={12} style={style}>
    {children}
  </BigText>
);

const Card = ({children, border = FUT, style}) => (
  <div style={{background: 'rgba(8,10,30,0.86)', border: `4px solid ${border}`, borderRadius: 26, padding: '14px 28px', fontFamily: FONT, color: '#fff', fontWeight: 900, ...style}}>{children}</div>
);

// Lo que todavía no ha pasado: cian, transparente y brillante
const GHOST_FILTER = 'grayscale(1) sepia(1) hue-rotate(150deg) saturate(5) brightness(1.15) drop-shadow(0 0 14px #5ee7ff)';
const Ghost = ({children, o = 0.55}) => (
  <g opacity={o} style={{filter: GHOST_FILTER}}>
    {children}
  </g>
);
const FutTag = ({x, y, label = '+5 s', o = 1}) => (
  <g transform={`translate(${x} ${y})`} opacity={o}>
    <rect x={-56} y={-26} width={112} height={52} rx={26} fill={FUT} />
    <text x={0} y={12} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={30} fill="#05060f">
      {label}
    </text>
  </g>
);

const Stars = ({t, n = 70, color = '#fff', seed = 's'}) => (
  <g>
    {Array.from({length: n}).map((_, i) => (
      <circle key={i} cx={random(`${seed}x${i}`) * 1920} cy={random(`${seed}y${i}`) * 1080} r={1 + random(`${seed}r${i}`) * 2.5} fill={color} opacity={0.25 + 0.35 * (0.5 + 0.5 * Math.sin(t * 2 + i))} />
    ))}
  </g>
);

const Bg = ({a = '#1b1046', b = '#05060f', children}) => (
  <AbsoluteFill style={{background: `radial-gradient(circle at 50% 40%, ${a}, ${b})`}}>{children}</AbsoluteFill>
);

// Reloj "+5 s" fijo en una esquina: el poder siempre activo
const FutureClock = () => {
  const t = useT();
  const k = (t % 5) / 5;
  const a = k * Math.PI * 2 - Math.PI / 2;
  return (
    <div style={{position: 'absolute', top: 990, right: 40, display: 'flex', alignItems: 'center', gap: 12}}>
      <svg width={74} height={74} viewBox="-37 -37 74 74">
        <circle r={32} fill="rgba(5,6,15,0.7)" stroke="rgba(94,231,255,0.35)" strokeWidth={6} />
        <path d={`M0 -32 A32 32 0 ${k > 0.5 ? 1 : 0} 1 ${32 * Math.cos(a)} ${32 * Math.sin(a)}`} fill="none" stroke={FUT} strokeWidth={6} strokeLinecap="round" />
        <line x1={0} y1={0} x2={22 * Math.cos(a)} y2={22 * Math.sin(a)} stroke="#fff" strokeWidth={4} strokeLinecap="round" />
      </svg>
      <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 34, color: FUT, textShadow: '0 0 18px rgba(94,231,255,0.7)'}}>+5 s</div>
    </div>
  );
};

const ChapterBanner = ({at, n, title}) => {
  const t = useT();
  const k = Math.min(r(t, at, at + 0.5, 0, 1, INOUT), r(t, at + 2.6, at + 3.1, 1, 0, INOUT));
  return (
    <div style={{position: 'absolute', top: 30, left: 0, translate: `${(k - 1) * 1000}px 0`, display: 'flex', fontFamily: FONT, boxShadow: '0 20px 60px rgba(0,0,0,0.5)'}}>
      <div style={{background: FUT, color: '#0b0b14', fontWeight: 900, fontSize: 34, padding: '18px 26px', display: 'flex', alignItems: 'center'}}>CAPÍTULO {n}</div>
      <div style={{background: 'rgba(8,10,30,0.92)', color: '#fff', fontWeight: 900, fontSize: 52, padding: '14px 40px 14px 30px'}}>{title}</div>
    </div>
  );
};

const Glass = ({x, y, rot = 0, s = 1}) => (
  <g transform={`translate(${x} ${y}) rotate(${rot}) scale(${s})`}>
    <path d="M-34 -50 L34 -50 L26 50 L-26 50 Z" fill="rgba(200,240,255,0.55)" stroke="#e8f8ff" strokeWidth={5} strokeLinejoin="round" />
    <path d="M-26 -10 L26 -10 L22 46 L-22 46 Z" fill="rgba(94,200,255,0.5)" />
    <path d="M-20 -40 L-16 30" stroke="#fff" strokeWidth={5} strokeLinecap="round" opacity={0.7} />
  </g>
);

const Shards = ({x, y, k = 1}) => (
  <g transform={`translate(${x} ${y})`}>
    {Array.from({length: 11}).map((_, i) => {
      const a = (i / 11) * Math.PI - Math.PI;
      const d = (40 + random(`sh${i}`) * 130) * k;
      return <path key={i} d="M0 -12 L10 6 L-8 8 Z" fill="rgba(200,240,255,0.8)" stroke="#fff" strokeWidth={2} transform={`translate(${Math.cos(a) * d} ${Math.sin(a) * d * 0.25}) rotate(${i * 47}) scale(${0.8 + random(`ss${i}`)})`} />;
    })}
  </g>
);

// =====================================================================
// 0. GANCHO: el vaso que ya has visto romperse
// =====================================================================
const HookScene = () => {
  const t = useT();
  const slip = Wa('resbala');
  const brk = Wa('romperse');
  const catchT = Wa('atrapas');
  const after = catchT + 1.2;
  const gy = r(t, brk - 0.6, brk, 560, 860, (x) => x * x);
  const ry = t < catchT ? lin(t, slip, catchT, 560, 700) : 700;
  const dark = r(t, after, after + 0.8, 0, 0.72);
  const zoom = r(t, 0, catchT, 1, 1.12, INOUT);
  return (
    <AbsoluteFill style={{background: '#2b2350'}}>
      <svg {...CANVAS}>
        <g transform={`translate(960 600) scale(${zoom}) translate(-960 -600)`}>
          {Array.from({length: 14}).map((_, i) =>
            Array.from({length: 7}).map((__, j) => <rect key={`${i}-${j}`} x={i * 140 + (j % 2) * 70 - 40} y={j * 100} width={134} height={94} rx={8} fill={(i + j) % 3 ? '#352c63' : '#3d3370'} />),
          )}
          <rect x={1300} y={120} width={420} height={300} rx={20} fill="#0d1440" stroke="#5a4f98" strokeWidth={14} />
          <circle cx={1600} cy={200} r={36} fill="#f3f0d8" opacity={0.9} />
          <rect x={0} y={640} width={1920} height={30} fill="#c97b5a" />
          <rect x={0} y={670} width={1920} height={200} fill="#6b3f2a" />
          {[260, 560, 1460, 1760].map((x) => (
            <circle key={x} cx={x} cy={770} r={10} fill="#e8b48c" />
          ))}
          <rect x={0} y={870} width={1920} height={210} fill="#1b1538" />
          {Array.from({length: 10}).map((_, i) => (
            <line key={i} x1={i * 220} y1={870} x2={i * 220 - 120} y2={1080} stroke="#2a2250" strokeWidth={6} />
          ))}
          <Human x={760} y={870} s={2.6} t={t} modern wave={t > catchT ? -60 : 10} />
          {t > brk - 0.6 && t < after + 0.6 ? (
            <Ghost o={lin(t, brk - 0.6, brk - 0.4, 0, 0.75) * lin(t, after, after + 0.6, 1, 0)}>
              {t < brk ? <Glass x={880} y={gy} rot={(t - brk) * 260} /> : <Shards x={880} y={866} k={r(t, brk, brk + 0.25, 0.2, 1)} />}
            </Ghost>
          ) : null}
          {t > brk && t < after + 0.6 ? <FutTag x={880} y={790} o={lin(t, brk, brk + 0.2, 0, 1) * lin(t, after, after + 0.6, 1, 0)} /> : null}
          <Glass x={880 + (t > catchT ? -20 : 0)} y={t < slip ? 560 : ry} rot={t < slip ? 0 : t < catchT ? (t - slip) * 30 : 10} />
          {t > Wa('golpe') && t < catchT ? (
            <text x={1040} y={830} fontFamily={FONT} fontWeight={900} fontSize={90} fill={FUT} opacity={0.6 * lin(t, Wa('golpe'), Wa('golpe') + 0.2, 0, 1)} transform={`rotate(-8 1040 830)`}>
              ¡CRASH!
            </text>
          ) : null}
        </g>
        <rect x={0} y={0} width={1920} height={1080} fill="#05060f" opacity={dark} />
      </svg>
      <Pop at={Wa('aire') - 0.1} out={catchT - 0.2} style={{top: 120, left: 0, right: 0}}>
        <Title size={90}>…PERO SIGUE EN EL AIRE</Title>
      </Pop>
      <Pop at={catchT} out={after} style={{top: 120, left: 0, right: 0}}>
        <Title size={110} color={C.green}>
          ¡ATRAPADO!
        </Title>
      </Pop>
      <Pop at={Wa('cinco', after) - 0.1} out={Wa('poco') - 0.2} style={{top: 260, left: 0, right: 0, flexDirection: 'column', gap: 10}}>
        <Title size={80}>PUEDES VER</Title>
        <Title size={190} color={FUT}>
          5 SEGUNDOS
        </Title>
        <Title size={80}>EN EL FUTURO</Title>
      </Pop>
      <Pop at={Wa('poco') - 0.1} out={Wa('quédate') - 0.2} style={{top: 300, left: 0, right: 0}}>
        <Title size={170} color={C.accent}>
          ¿POCO?
        </Title>
      </Pop>
      <Pop at={Wa('imparable') - 0.1} out={Wa('helado') - 0.5} style={{top: 240, left: 0, right: 0, flexDirection: 'column', gap: 30}}>
        <Pill color={C.green} size={70}>
          IMPARABLE
        </Pill>
        {t > Wa('cabeza') - 0.2 ? (
          <Pill color={C.red} text="#fff" size={70}>
            …O PERDER LA CABEZA
          </Pill>
        ) : null}
      </Pop>
      <Pop at={Wa('cierto') - 0.1} style={{top: 260, left: 0, right: 0, flexDirection: 'column', gap: 10}}>
        <Title size={90}>EN CIERTO MODO…</Title>
        {t > Wa('tú', Wa('cierto')) - 0.1 ? (
          <Title size={150} color={FUT}>
            TÚ YA PUEDES
          </Title>
        ) : null}
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 1. FIRMA
// =====================================================================
const BrandSting = () => {
  const t = useT();
  return (
    <Bg>
      <svg {...CANVAS}>
        <Stars t={t} />
        {Array.from({length: 6}).map((_, i) => (
          <circle key={i} cx={960} cy={540} r={((t * 160 + i * 140) % 840) + 20} fill="none" stroke={FUT} strokeWidth={3} opacity={0.4 * (1 - ((t * 160 + i * 140) % 840) / 840)} />
        ))}
      </svg>
      <Pop at={P[1]} style={{top: 230, left: 0, right: 0, flexDirection: 'column', gap: 26}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 18}}>
          <div style={{width: 90, height: 90, borderRadius: 26, background: `linear-gradient(135deg, ${C.accent}, ${C.hot} 60%, ${C.pink})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 66, color: '#0b0b14'}}>A</div>
          <Pill color="#fff" size={44}>
            HOY, EN APRENDE
          </Pill>
        </div>
        <Title size={84}>¿QUÉ PASARÍA SI PUDIERAS VER</Title>
        <Title size={150} color={FUT}>
          5 SEGUNDOS EN EL FUTURO?
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 2. LAS REGLAS
// =====================================================================
const RulesScene = () => {
  const t = useT();
  const x = 360 + Math.sin((t - P[2]) * 0.5) * 120;
  const xf = 360 + Math.sin((t - P[2] + 5) * 0.5) * 120;
  const rules = [
    [Wa('dos', P[2]), '1', 'VES DOS REALIDADES A LA VEZ'],
    [Wa('hablar', P[2]), '2', 'OYES LAS FRASES ANTES'],
    [Wa('cambias', P[2]), '3', 'SI CAMBIAS EL PRESENTE, CAMBIA EL FUTURO'],
  ];
  return (
    <Bg a="#1d1450">
      <svg {...CANVAS}>
        <Stars t={t} n={40} />
        <rect x={0} y={760} width={1920} height={320} fill="#120b33" />
        <Ghost o={0.5}>
          <Human x={xf} y={780} s={2.2} t={t + 5} modern walk={1} flip={Math.cos((t - P[2] + 5) * 0.5) < 0} />
        </Ghost>
        <Human x={x} y={780} s={2.2} t={t} modern walk={1} flip={Math.cos((t - P[2]) * 0.5) < 0} />
        <text x={x} y={840} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={30} fill="#fff">
          AHORA
        </text>
        <FutTag x={xf} y={300} />
      </svg>
      <Pop at={P[2]} out={rules[0][0] - 0.3} style={{top: 140, left: 760, right: 60}}>
        <Title size={110}>LAS REGLAS</Title>
      </Pop>
      <div style={{position: 'absolute', top: 150, left: 820, right: 60, display: 'flex', flexDirection: 'column', gap: 26}}>
        {rules.map(([at, n, txt]) =>
          t > at - 0.1 ? (
            <div key={n} style={{display: 'flex', alignItems: 'center', gap: 20, scale: String(r(t, at - 0.1, at + 0.35, 0.6, 1, BACK)), opacity: lin(t, at - 0.1, at + 0.1, 0, 1), transformOrigin: 'left center'}}>
              <div style={{width: 80, height: 80, borderRadius: 40, background: FUT, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 48, color: '#05060f', flexShrink: 0}}>{n}</div>
              <Card style={{fontSize: 40}}>{txt}</Card>
            </div>
          ) : null,
        )}
        {t > Wa('vaso', P[2]) - 0.1 ? (
          <div style={{display: 'flex', alignItems: 'center', gap: 16, marginTop: 10, opacity: lin(t, Wa('vaso', P[2]) - 0.1, Wa('vaso', P[2]) + 0.2, 0, 1)}}>
            <div style={{width: 64, height: 64, borderRadius: 32, background: C.green, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
              <Check size={44} />
            </div>
            <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 40, color: C.green}}>EL VASO NO TIENE POR QUÉ ROMPERSE</div>
          </div>
        ) : null}
      </div>
    </Bg>
  );
};

// =====================================================================
// 3-4. TU PRIMER DÍA: la calle
// =====================================================================
const Bike = () => (
  <g>
    <circle cx={-46} cy={-30} r={30} fill="none" stroke="#e8ecf5" strokeWidth={7} />
    <circle cx={46} cy={-30} r={30} fill="none" stroke="#e8ecf5" strokeWidth={7} />
    <path d="M-46 -30 L-6 -80 L40 -80 L46 -30 M-6 -80 L0 -30 L-46 -30" fill="none" stroke={C.hot} strokeWidth={8} strokeLinejoin="round" />
    <circle cx={-6} cy={-130} r={16} fill="#e8b48c" />
    <path d="M-6 -114 L-2 -70" stroke="#3d5afe" strokeWidth={16} strokeLinecap="round" />
  </g>
);
const Dog = ({t}) => (
  <g>
    <ellipse cx={0} cy={-46} rx={50} ry={24} fill="#c98a4b" />
    <circle cx={-52} cy={-70} r={20} fill="#c98a4b" />
    <path d="M-62 -86 L-70 -64 L-56 -70 Z" fill="#8a5a2c" />
    {[-30, -12, 18, 34].map((x, i) => (
      <rect key={x} x={x} y={-30} width={9} height={30} rx={4} fill="#a8703a" transform={`rotate(${Math.sin(t * 14 + i) * 20} ${x + 4} -30)`} />
    ))}
    <path d="M46 -54 Q70 -80 64 -90" fill="none" stroke="#c98a4b" strokeWidth={8} strokeLinecap="round" />
  </g>
);
const Ball = ({r: rr = 26}) => (
  <g>
    <circle r={rr} fill="#fff" stroke="#05060f" strokeWidth={4} />
    <path d={`M0 ${-rr * 0.45} l${rr * 0.42} ${rr * 0.3} l${-rr * 0.16} ${rr * 0.5} l${-rr * 0.52} 0 l${-rr * 0.16} ${-rr * 0.5} Z`} fill="#05060f" />
  </g>
);

const StreetScene = () => {
  const t = useT();
  const PX = 760;
  const SPEED = 260;
  const obs = [
    [Wa('puerta', P[4]) + 1.4, 'door'],
    [Wa('bici', P[4]) + 1.4, 'bike'],
    [Wa('perro', P[4]) + 1.6, 'dog'],
    [Wa('cosas', P[4]) + 1.2, 'ball'],
    [P[5] - 1.2, 'bike'],
  ];
  const dodge = obs.reduce((acc, [at]) => acc + Math.max(0, 1 - Math.abs(t - at) / 0.45), 0);
  const shift = -((t - P[3]) * 120) % 480;
  return (
    <Bg a="#3a2a7a" b="#120b33">
      <svg {...CANVAS}>
        {Array.from({length: 7}).map((_, i) => {
          const bx = ((i * 330 + shift * 0.6) % 2310) - 200;
          const h = 360 + (i * 97) % 260;
          return (
            <g key={i}>
              <rect x={bx} y={760 - h} width={280} height={h} fill={i % 2 ? '#2a2060' : '#33287a'} />
              {Array.from({length: 8}).map((_, j) => (
                <rect key={j} x={bx + 30 + (j % 3) * 80} y={760 - h + 40 + Math.floor(j / 3) * 90} width={46} height={50} fill="#ffd27a" opacity={(i + j) % 3 ? 0.85 : 0.2} />
              ))}
            </g>
          );
        })}
        <rect x={0} y={760} width={1920} height={320} fill="#4a4470" />
        {Array.from({length: 12}).map((_, i) => (
          <rect key={i} x={((i * 200 + shift) % 2400) - 200} y={900} width={110} height={14} fill="#fff" opacity={0.4} />
        ))}
        {obs.map(([at, kind], i) => {
          const draw = (x, ghost) => {
            const el = kind === 'door' ? (
              <g transform={`translate(${x} 790)`}>
                <rect x={-50} y={-210} width={100} height={210} fill="#7a4e2a" stroke="#3b2414" strokeWidth={6} transform={`skewY(${ghost ? 0 : lin(t, at - 0.6, at, 0, -20)})`} />
              </g>
            ) : kind === 'bike' ? (
              <g transform={`translate(${x} 830)`}>
                <Bike />
              </g>
            ) : kind === 'dog' ? (
              <g transform={`translate(${x} 830)`}>
                <Dog t={t} />
              </g>
            ) : (
              <g transform={`translate(${x} ${800 - Math.abs(Math.sin(t * 5)) * 120})`}>
                <Ball />
              </g>
            );
            return el;
          };
          const realX = PX + (at - t) * SPEED;
          const ghostX = PX + (at - (t + 5)) * SPEED;
          return (
            <g key={i}>
              {ghostX > -200 && ghostX < 2100 && t < at ? <Ghost o={0.6}>{draw(ghostX, true)}</Ghost> : null}
              {realX > -200 && realX < 2100 ? draw(realX, false) : null}
            </g>
          );
        })}
        <g transform={`translate(0 ${-dodge * 140})`}>
          <Human x={PX} y={840} s={2} t={t} modern walk={1} />
        </g>
      </svg>
      <Pop at={P[3]} out={P[4] - 0.2} style={{top: 260, left: 0, right: 0}}>
        <Title size={140} color={C.accent}>
          TU PRIMER DÍA
        </Title>
      </Pop>
      <Pop at={Wa('sorpresa', P[4]) - 0.1} out={Wa('caminas', P[4]) - 0.3} style={{top: 140, left: 0, right: 0}}>
        <Title size={84}>NADA TE PILLA POR SORPRESA</Title>
      </Pop>
      <Pop at={Wa('lenta', P[4]) - 0.3} out={P[5] - 0.3} style={{top: 140, left: 0, right: 0}}>
        <Title size={84} color={FUT}>
          TODO VA A CÁMARA LENTA
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 5. EL TRÁFICO
// =====================================================================
const Car = ({color = C.red}) => (
  <g>
    <path d="M-150 -30 L-140 -80 Q-100 -86 -70 -120 L60 -120 Q100 -90 140 -80 L150 -30 Z" fill={color} stroke="#05060f" strokeWidth={6} strokeLinejoin="round" />
    <path d="M-60 -112 L-16 -112 L-16 -82 L-90 -82 Z M0 -112 L50 -112 L80 -82 L0 -82 Z" fill="#bfe9ff" />
    <circle cx={-90} cy={-26} r={30} fill="#1a1a2a" stroke="#c9d1e0" strokeWidth={8} />
    <circle cx={90} cy={-26} r={30} fill="#1a1a2a" stroke="#c9d1e0" strokeWidth={8} />
    <rect x={136} y={-74} width={16} height={14} rx={4} fill="#ffe27a" />
  </g>
);

const TrafficScene = () => {
  const t = useT();
  const acc = Wa('accidente', P[5]);
  const pull = Wa('tirar', P[5]);
  const carX = t < acc ? 300 + ((t - P[5]) * 180) % 900 : lin(t, acc, pull + 0.6, 300, 1180);
  const pedX = 1400 - r(t, pull, pull + 0.5, 0, 160);
  const crash = t > acc - 0.2 && t < pull + 0.6;
  const bars = Wa('reaccionar', P[5]);
  return (
    <Bg a="#26306a" b="#0b0f2a">
      <svg {...CANVAS}>
        <rect x={0} y={640} width={1920} height={440} fill="#35345a" />
        <rect x={0} y={620} width={1920} height={24} fill="#8a87b0" />
        {Array.from({length: 10}).map((_, i) => (
          <rect key={i} x={i * 220 - ((t * 300) % 220)} y={820} width={120} height={14} fill="#fff" opacity={0.6} />
        ))}
        {Array.from({length: 7}).map((_, i) => (
          <rect key={i} x={1310 + i * 0} y={660 + i * 44} width={180} height={22} fill="#fff" opacity={0.8} />
        ))}
        <Ghost o={crash ? 0.7 : 0.45}>
          <g transform={`translate(${Math.min(carX + 5 * 180, 1420)} 900)`}>
            <Car />
          </g>
        </Ghost>
        <g transform={`translate(${carX} 900)`}>
          <Car />
        </g>
        <Human x={pedX} y={720} s={1.6} t={t} modern />
        {crash ? (
          <g opacity={0.5 + 0.5 * Math.sin(t * 16)}>
            <circle cx={1400} cy={760} r={130} fill="none" stroke={C.red} strokeWidth={12} />
            <FutTag x={1400} y={580} label="¡PELIGRO!" />
          </g>
        ) : null}
      </svg>
      <Pop at={P[5]} out={Wa('cincuenta', P[5]) - 0.3} style={{top: 150, left: 0, right: 0}}>
        <Title size={120}>EL TRÁFICO</Title>
      </Pop>
      <Pop at={Wa('cincuenta', P[5]) - 0.1} out={bars - 0.3} style={{top: 130, left: 0, right: 0, gap: 30}}>
        <Card style={{fontSize: 60}}>50 km/h</Card>
        {t > Wa('catorce', P[5]) - 0.1 ? <Card style={{fontSize: 60}}>= 14 m CADA SEGUNDO</Card> : null}
        {t > Wa('setenta', P[5]) - 0.1 ? (
          <Card border={C.accent} style={{fontSize: 60, color: C.accent}}>
            5 s = 70 m
          </Card>
        ) : null}
      </Pop>
      <Pop at={bars - 0.1} out={acc - 0.3} style={{top: 120, left: 300, right: 300, flexDirection: 'column', alignItems: 'stretch', gap: 18}}>
        {[
          ['PERSONA NORMAL', 1, '#fff'],
          ['TÚ', 5, FUT],
        ].map(([lab, s, col], i) => (
          <div key={lab} style={{display: 'flex', alignItems: 'center', gap: 20, opacity: i === 0 || t > Wa('cinco', bars) - 0.1 ? 1 : 0}}>
            <div style={{width: 340, fontFamily: FONT, fontWeight: 900, fontSize: 44, color: '#fff', textAlign: 'right'}}>{lab}</div>
            <div style={{height: 60, width: r(t, bars + i * 1.5, bars + i * 1.5 + 0.8, 0, s * 220), background: col, borderRadius: 30}} />
            <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 50, color: col}}>{s} s</div>
          </div>
        ))}
      </Pop>
      <Pop at={Wa('vidas', P[5]) - 0.2} style={{top: 150, left: 0, right: 0}}>
        <Title size={110} color={C.green}>
          SALVARÍAS VIDAS
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 6. PERO… LO PRIMERO SERÍA JUGAR
// =====================================================================
const PlayScene = () => {
  const t = useT();
  return (
    <Bg a="#4a1460" b="#0b0420">
      <svg {...CANVAS}>
        <Stars t={t} n={50} color={C.accent} seed="pl" />
        {[0, 1].map((i) => (
          <g key={i} transform={`translate(${760 + i * 400} ${640 + Math.sin(t * 3 + i) * 30}) rotate(${t * 120 * (i ? -1 : 1)})`}>
            <rect x={-80} y={-80} width={160} height={160} rx={30} fill="#fff" stroke="#05060f" strokeWidth={8} />
            {(i ? [[-40, -40], [40, 40], [0, 0]] : [[-40, -40], [40, -40], [-40, 40], [40, 40]]).map(([x, y], j) => (
              <circle key={j} cx={x} cy={y} r={16} fill="#05060f" />
            ))}
          </g>
        ))}
      </svg>
      <Pop at={P[6]} out={Wa('jugar', P[6]) - 0.3} style={{top: 200, left: 0, right: 0}}>
        <Title size={100}>PERO SEAMOS SINCEROS…</Title>
      </Pop>
      <Pop at={Wa('jugar', P[6]) - 0.2} style={{top: 180, left: 0, right: 0, flexDirection: 'column'}}>
        <Title size={80}>LO PRIMERO SERÍA</Title>
        <Title size={200} color={C.accent}>
          ¡JUGAR!
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 7. PIEDRA, PAPEL O TIJERA
// =====================================================================
const RPS = ({kind, s = 1}) => (
  <g transform={`scale(${s})`}>
    {kind === 0 ? (
      <g>
        <circle r={80} fill="#e8b48c" stroke="#05060f" strokeWidth={8} />
        {[-45, -15, 15, 45].map((x) => (
          <path key={x} d={`M${x} -60 Q${x + 12} -30 ${x} 0`} fill="none" stroke="#b07a52" strokeWidth={6} />
        ))}
      </g>
    ) : kind === 1 ? (
      <g>
        <rect x={-80} y={-100} width={160} height={200} rx={40} fill="#e8b48c" stroke="#05060f" strokeWidth={8} />
        {[-40, 0, 40].map((x) => (
          <line key={x} x1={x} y1={-90} x2={x} y2={-20} stroke="#b07a52" strokeWidth={6} />
        ))}
      </g>
    ) : (
      <g>
        <rect x={-58} y={-30} width={116} height={110} rx={40} fill="#e8b48c" stroke="#05060f" strokeWidth={8} />
        <rect x={-48} y={-150} width={40} height={140} rx={20} fill="#e8b48c" stroke="#05060f" strokeWidth={8} transform="rotate(-14 -28 -20)" />
        <rect x={8} y={-150} width={40} height={140} rx={20} fill="#e8b48c" stroke="#05060f" strokeWidth={8} transform="rotate(14 28 -20)" />
      </g>
    )}
  </g>
);
const NAMES = ['PIEDRA', 'PAPEL', 'TIJERA'];

const RpsScene = () => {
  const t = useT();
  const s0 = P[7] + 1;
  const ROUND = 1.6;
  const n = Math.max(0, Math.floor((t - s0) / ROUND));
  const ph = t < s0 ? 0 : ((t - s0) % ROUND) / ROUND;
  const opp = Math.floor(random(`rps${n}`) * 3);
  const mine = (opp + 1) % 3;
  const robot = Wa('robot', P[7]);
  const shake = ph < 0.35 ? Math.sin(ph * 60) * 30 : 0;
  return (
    <Bg a="#123a5a" b="#05101e">
      <svg {...CANVAS}>
        <rect x={940} y={160} width={40} height={620} rx={20} fill="rgba(255,255,255,0.12)" />
        <g transform={`translate(560 ${470 + shake})`}>{ph < 0.35 || t < s0 ? <RPS kind={0} s={1.3} /> : <RPS kind={mine} s={1.3} />}</g>
        <g transform={`translate(1360 ${470 + shake}) scale(-1 1)`}>{ph < 0.35 || t < s0 ? <RPS kind={0} s={1.3} /> : <RPS kind={opp} s={1.3} />}</g>
        {t > s0 && ph < 0.35 ? (
          <Ghost o={0.7}>
            <g transform="translate(1360 470) scale(-1 1)">
              <RPS kind={opp} s={1.3} />
            </g>
          </Ghost>
        ) : null}
        {t > s0 && ph < 0.35 ? <FutTag x={1360} y={250} /> : null}
        {t > s0 && ph >= 0.35 ? (
          <g>
            <text x={560} y={720} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={46} fill={C.green}>
              {NAMES[mine]}
            </text>
            <text x={1360} y={720} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={46} fill="#fff" opacity={0.7}>
              {NAMES[opp]}
            </text>
          </g>
        ) : null}
        {t > robot - 0.1 ? (
          <g transform={`translate(1360 ${860 - 0}) scale(${r(t, robot - 0.1, robot + 0.3, 0.3, 1, BACK)})`}>
            <rect x={-80} y={-60} width={160} height={110} rx={24} fill="#c9d1e0" stroke="#05060f" strokeWidth={6} />
            <circle cx={-34} cy={-8} r={18} fill={C.red} />
            <circle cx={34} cy={-8} r={18} fill={C.red} />
            <line x1={0} y1={-60} x2={0} y2={-90} stroke="#c9d1e0" strokeWidth={6} />
            <circle cx={0} cy={-96} r={10} fill={C.accent} />
          </g>
        ) : null}
      </svg>
      <div style={{position: 'absolute', top: 70, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 60, fontFamily: FONT, fontWeight: 900, fontSize: 64, color: '#fff'}}>
        <span style={{color: C.green}}>TÚ {t > s0 ? n + (ph >= 0.35 ? 1 : 0) : 0}</span>
        <span>–</span>
        <span>RIVAL 0</span>
      </div>
      <Pop at={robot - 0.1} out={Wa('margen', P[7]) - 0.3} style={{top: 180, left: 0, right: 0, gap: 20}}>
        <Pill color="#fff" size={44}>
          JAPÓN
        </Pill>
        <Pill color={C.red} text="#fff" size={44}>
          ROBOT QUE GANA SIEMPRE
        </Pill>
        {t > Wa('milésimas', P[7]) - 0.1 ? (
          <Pill color={C.accent} size={44}>
            LEE LA MANO EN MILÉSIMAS
          </Pill>
        ) : null}
      </Pop>
      <Pop at={Wa('margen', P[7]) - 0.4} style={{top: 180, left: 0, right: 0}}>
        <Pill color={FUT} size={56}>
          TÚ: 5 SEGUNDOS DE MARGEN
        </Pill>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 8. EL DEPORTE: el penalti
// =====================================================================
const Keeper = ({x, y, rot = 0}) => (
  <g transform={`translate(${x} ${y}) rotate(${rot})`}>
    <rect x={-40} y={-90} width={80} height={110} rx={20} fill={C.accent} stroke="#05060f" strokeWidth={6} />
    <circle cx={0} cy={-120} r={30} fill="#e8b48c" stroke="#05060f" strokeWidth={5} />
    <rect x={-110} y={-90} width={72} height={24} rx={12} fill={C.accent} transform="rotate(-30 -40 -80)" />
    <rect x={38} y={-90} width={72} height={24} rx={12} fill={C.accent} transform="rotate(30 40 -80)" />
    <circle cx={-104} cy={-130} r={20} fill="#3ddc84" />
    <circle cx={104} cy={-130} r={20} fill="#3ddc84" />
    <rect x={-34} y={18} width={24} height={70} rx={10} fill="#1a1a2a" />
    <rect x={10} y={18} width={24} height={70} rx={10} fill="#1a1a2a" />
  </g>
);

const FootballScene = () => {
  const t = useT();
  const save = Wa('pararías', P[8]);
  const K = save - 0.7;
  const bx = t < K ? 960 : r(t, K, K + 0.5, 960, 640);
  const by = t < K ? 900 : r(t, K, K + 0.5, 900, 470);
  const bounce = t > K + 0.5 ? r(t, K + 0.5, K + 1.2, 0, 1) : 0;
  const kx = r(t, K - 0.35, K + 0.35, 960, 690, INOUT);
  const krot = r(t, K - 0.35, K + 0.35, 0, -60, INOUT);
  const ghostOn = t > Wa('izquierda', P[8]) - 0.2 && t < K + 0.5;
  return (
    <Bg a="#1f7a3a" b="#06200f">
      <svg {...CANVAS}>
        <rect x={0} y={0} width={1920} height={260} fill="#0b2a4a" />
        {Array.from({length: 40}).map((_, i) => (
          <circle key={i} cx={(i * 53) % 1920} cy={120 + (i % 5) * 26} r={10} fill={['#ff5a36', '#ffd23f', '#5ee7ff', '#fff'][i % 4]} opacity={0.6} />
        ))}
        {Array.from({length: 8}).map((_, i) => (
          <rect key={i} x={i * 240} y={260} width={240} height={820} fill={i % 2 ? '#2a8a45' : '#249040'} />
        ))}
        <rect x={500} y={300} width={920} height={380} fill="rgba(255,255,255,0.08)" stroke="#fff" strokeWidth={16} />
        {Array.from({length: 12}).map((_, i) => (
          <line key={i} x1={500 + i * 80} y1={300} x2={500 + i * 80} y2={680} stroke="#fff" strokeWidth={2} opacity={0.3} />
        ))}
        <line x1={300} y1={680} x2={1620} y2={680} stroke="#fff" strokeWidth={8} />
        {ghostOn ? (
          <Ghost o={0.8}>
            <path d="M960 900 Q760 600 640 470" fill="none" stroke="#fff" strokeWidth={10} strokeDasharray="22 16" />
            <g transform="translate(640 470)">
              <Ball r={34} />
            </g>
          </Ghost>
        ) : null}
        {ghostOn ? <FutTag x={640} y={400} /> : null}
        <Keeper x={kx} y={600} rot={krot} />
        <g transform={`translate(${bx + bounce * 260} ${by + bounce * 300 - Math.sin(bounce * Math.PI) * 140})`}>
          <Ball r={34} />
        </g>
      </svg>
      <Pop at={Wa('medio', P[8]) - 0.1} out={Wa('tiran', P[8]) - 0.2} style={{top: 60, left: 0, right: 0, gap: 20}}>
        <Card style={{fontSize: 60}}>EL BALÓN TARDA</Card>
        <Card border={C.accent} style={{fontSize: 60, color: C.accent}}>
          0,5 s
        </Card>
      </Pop>
      <Pop at={Wa('tiran', P[8]) - 0.1} out={Wa('izquierda', P[8]) - 0.4} style={{top: 60, left: 0, right: 0}}>
        <Title size={80}>LOS PORTEROS ADIVINAN</Title>
      </Pop>
      <Pop at={save - 0.1} out={Wa('tenis', P[8]) - 0.3} style={{top: 60, left: 0, right: 0}}>
        <Title size={110} color={C.accent}>
          ¡PARADO!
        </Title>
      </Pop>
      <Pop at={Wa('tenis', P[8]) - 0.1} out={Wa('intocable', P[8]) - 0.3} style={{top: 60, left: 0, right: 0, gap: 24}}>
        <Pill color="#fff" size={56}>
          TENIS
        </Pill>
        {t > Wa('boxeo', P[8]) - 0.1 ? (
          <Pill color={C.red} text="#fff" size={56}>
            BOXEO
          </Pill>
        ) : null}
      </Pop>
      <Pop at={Wa('intocable', P[8]) - 0.1} style={{top: 60, left: 0, right: 0}}>
        <Title size={130} color={FUT}>
          INTOCABLE
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 9. LAS CONVERSACIONES
// =====================================================================
const Bubble = ({x, y, text, ghost, flip}) => (
  <div style={{position: 'absolute', left: x, top: y, maxWidth: 560, padding: '18px 28px', borderRadius: 30, borderBottomLeftRadius: flip ? 30 : 4, borderBottomRightRadius: flip ? 4 : 30, background: ghost ? 'rgba(94,231,255,0.18)' : '#fff', border: ghost ? `4px dashed ${FUT}` : '4px solid #05060f', fontFamily: FONT, fontWeight: 900, fontSize: 40, color: ghost ? FUT : '#05060f', boxShadow: ghost ? `0 0 30px ${FUT}` : 'none'}}>
    {text}
  </div>
);

const TalkScene = () => {
  const t = useT();
  const q = Wa('preguntar', P[9]);
  const joke = Wa('chiste', P[9]);
  const meter = Wa('carismática', P[9]);
  return (
    <Bg a="#5a2a6a" b="#120620">
      <svg {...CANVAS}>
        <rect x={0} y={760} width={1920} height={320} fill="#2a1438" />
        <Human x={560} y={800} s={2.4} t={t} modern />
        <Human x={1360} y={800} s={2.4} t={t} modern flip skin="#c98a5e" hair="#5a2a10" />
      </svg>
      {t > q - 0.2 && t < joke - 0.3 ? (
        <>
          <Bubble x={1100} y={150} text="¿QUÉ HACES ESTE FINDE?" ghost flip />
          {t > q + 1.4 ? <Bubble x={1100} y={300} text="¿QUÉ HACES ESTE FINDE?" flip /> : null}
          <div style={{position: 'absolute', left: 1460, top: 90, fontFamily: FONT, fontWeight: 900, fontSize: 34, color: FUT}}>+5 s</div>
        </>
      ) : null}
      {t > joke - 0.2 && t < meter - 0.3 ? (
        <>
          <Bubble x={280} y={160} text="…y entonces el pato dice…" ghost />
          <Bubble x={1080} y={160} text="(silencio incómodo)" ghost flip />
          {t > Wa('cuentas', P[9]) - 0.2 ? (
            <div style={{position: 'absolute', left: 260, top: 130, width: 1400, height: 160, display: 'flex', alignItems: 'center', justifyContent: 'center'}}>
              <Pill color={C.red} text="#fff" size={60}>
                NO LO CUENTAS
              </Pill>
            </div>
          ) : null}
        </>
      ) : null}
      <Pop at={meter - 0.1} style={{top: 120, left: 0, right: 0, flexDirection: 'column', gap: 18}}>
        <Title size={70}>CARISMA</Title>
        <div style={{width: 900, height: 60, borderRadius: 30, background: 'rgba(255,255,255,0.15)', border: '4px solid #fff', overflow: 'hidden'}}>
          <div style={{height: '100%', width: `${r(t, meter, meter + 1.5, 10, 100)}%`, background: `linear-gradient(90deg, ${C.green}, ${C.accent})`}} />
        </div>
        <Title size={60} color={C.accent}>
          {Math.round(r(t, meter, meter + 1.5, 10, 100))} %
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 10-12. LA PARADOJA: futuros que se ramifican
// =====================================================================
const ParadoxScene = () => {
  const t = useT();
  const branches = [
    [Wa('rompe', P[12]), 230, 'SE ROMPE', C.red],
    [Wa('atrapas', P[12]), 470, 'LO ATRAPAS', C.green],
    [Wa('cortas', P[12]), 710, 'TE CORTAS', C.accent],
  ];
  const many = Wa('diferentes', P[12]);
  const choose = Wa('elegir', P[12]);
  const gone = Wa('existe', P[11]);
  return (
    <Bg a="#2a0f4a" b="#06020f">
      <svg {...CANVAS}>
        <Stars t={t} n={50} />
        {t > many - 0.2
          ? Array.from({length: 26}).map((_, i) => {
              const y = 120 + random(`br${i}`) * 680;
              const k = r(t, many + i * 0.08, many + i * 0.08 + 0.6, 0, 1);
              return <path key={i} d={`M360 470 C800 470 900 ${y} ${360 + 1200 * k} ${y}`} fill="none" stroke={FUT} strokeWidth={3} opacity={0.35} />;
            })
          : null}
        {t > P[11] ? (
          <g>
            <path d={`M360 470 C700 470 800 300 ${lin(t, P[11], P[11] + 1.2, 360, 1500)} 300`} fill="none" stroke="#fff" strokeWidth={8} opacity={t > branches[0][0] ? 0.2 : 1} />
            {t > gone - 0.1 && t < branches[0][0] ? (
              <g transform="translate(1500 300)">
                <path d="M-50 -50 L50 50 M50 -50 L-50 50" stroke={C.red} strokeWidth={18} strokeLinecap="round" />
              </g>
            ) : null}
          </g>
        ) : null}
        {branches.map(([at, y, label, col]) =>
          t > at - 0.2 ? (
            <g key={label}>
              <path d={`M360 470 C800 470 900 ${y} ${lin(t, at - 0.2, at + 0.5, 360, 1460)} ${y}`} fill="none" stroke={col} strokeWidth={10} strokeLinecap="round" />
              <circle cx={1460} cy={y} r={20} fill={col} opacity={lin(t, at + 0.4, at + 0.6, 0, 1)} />
              <text x={1500} y={y + 16} fontFamily={FONT} fontWeight={900} fontSize={46} fill={col} opacity={lin(t, at + 0.4, at + 0.6, 0, 1)}>
                {label}
              </text>
            </g>
          ) : null,
        )}
        <circle cx={360} cy={470} r={34} fill="#fff" />
        <text x={360} y={560} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={40} fill="#fff">
          AHORA
        </text>
        {t > choose - 0.2 ? (
          <g transform={`translate(360 470) scale(${1 + 0.08 * Math.sin(t * 10)})`}>
            <circle r={70} fill="none" stroke={C.pink} strokeWidth={6} opacity={0.8} />
            <circle r={110} fill="none" stroke={C.pink} strokeWidth={4} opacity={0.4} />
          </g>
        ) : null}
      </svg>
      <Pop at={P[10]} out={P[11] + 2} style={{top: 120, left: 0, right: 0}}>
        <Title size={110} color={C.red}>
          PRIMER PROBLEMA
        </Title>
      </Pop>
      <Pop at={gone - 0.1} out={P[12] - 0.3} style={{top: 860, left: 0, right: 0}}>
        <Pill color={C.red} text="#fff" size={44}>
          ESE FUTURO YA NO EXISTE
        </Pill>
      </Pop>
      <Pop at={Wa('paradoja', P[12]) - 0.1} out={Wa('rompe', P[12]) - 0.4} style={{top: 120, left: 0, right: 0}}>
        <Title size={150} color={C.pink}>
          PARADOJA
        </Title>
      </Pop>
      <Pop at={Wa('posibles', P[11]) - 0.4} out={P[12] - 0.3} style={{top: 120, left: 0, right: 0}}>
        <Title size={80}>¿UNO DE MUCHOS FUTUROS?</Title>
      </Pop>
      <Pop at={choose - 0.1} style={{top: 60, left: 0, right: 0}}>
        <Title size={70} color={C.pink}>
          TU CEREBRO ELIGE… CADA SEGUNDO
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 13. EL DINERO
// =====================================================================
const Coin = ({x, y, s = 1, rot = 0}) => (
  <g transform={`translate(${x} ${y}) rotate(${rot}) scale(${s})`}>
    <ellipse rx={40} ry={40} fill={C.accent} stroke="#b8860b" strokeWidth={6} />
    <text y={16} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={44} fill="#b8860b">
      €
    </text>
  </g>
);
const MoneyRain = ({t, n = 40, seed = 'm'}) => (
  <g>
    {Array.from({length: n}).map((_, i) => {
      const y = ((random(`${seed}y${i}`) * 1300 + t * (200 + random(`${seed}v${i}`) * 200)) % 1300) - 100;
      return <Coin key={i} x={random(`${seed}x${i}`) * 1920} y={y} s={0.6 + random(`${seed}s${i}`) * 0.8} rot={t * 90 + i * 30} />;
    })}
  </g>
);

const MoneyScene = () => {
  const t = useT();
  return (
    <Bg a="#3a2a00" b="#0b0800">
      <svg {...CANVAS}>
        <MoneyRain t={t} />
      </svg>
      <Pop at={Wa('dinero', P[13]) - 0.2} style={{top: 300, left: 0, right: 0}}>
        <Title size={200} color={C.accent}>
          EL DINERO
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 14. EL CASINO
// =====================================================================
const Roulette = ({t, spin}) => (
  <g transform={`rotate(${spin})`}>
    <circle r={300} fill="#5a3a1a" stroke="#c9a24a" strokeWidth={14} />
    {Array.from({length: 37}).map((_, i) => {
      const a0 = (i / 37) * Math.PI * 2;
      const a1 = ((i + 1) / 37) * Math.PI * 2;
      const col = i === 0 ? '#1f8a3a' : i % 2 ? '#c21d2e' : '#151520';
      return <path key={i} d={`M0 0 L${Math.cos(a0) * 270} ${Math.sin(a0) * 270} A270 270 0 0 1 ${Math.cos(a1) * 270} ${Math.sin(a1) * 270} Z`} fill={col} stroke="#c9a24a" strokeWidth={2} />;
    })}
    <circle r={150} fill="#7a5226" stroke="#c9a24a" strokeWidth={8} />
    <circle r={40} fill="#c9a24a" />
  </g>
);

const CasinoScene = () => {
  const t = useT();
  const s0 = P[14];
  const spin = (t - s0) * 140;
  const ba = -(t - s0) * 4;
  const close = Wa('cierra', s0);
  const win = Wa('ganarías', s0);
  const cams = Wa('cámaras', s0);
  const out = Wa('volvieras', s0);
  const wins = t < win ? 0 : 1 + (t > Wa('otra', win) ? 1 : 0) + (t > Wa('otra', Wa('otra', win) + 0.1) ? 1 : 0);
  return (
    <Bg a="#2a0a12" b="#0b0204">
      <svg {...CANVAS}>
        <rect x={0} y={0} width={1920} height={1080} fill="#0f4a2a" opacity={0.25} />
        <g transform="translate(600 520)">
          <Roulette t={t} spin={spin} />
          <circle cx={Math.cos(ba) * 230} cy={Math.sin(ba) * 230} r={18} fill="#fff" />
          <Ghost o={0.6}>
            <circle cx={Math.cos(ba - 20) * 210} cy={Math.sin(ba - 20) * 210} r={18} fill="#fff" />
          </Ghost>
        </g>
        {t > cams - 0.2
          ? [[1080, 100], [1800, 100]].map(([x, y], i) => (
              <g key={i} transform={`translate(${x} ${y}) rotate(${(i ? 30 : -30) + Math.sin(t * 2) * 10})`}>
                <rect x={-60} y={-26} width={120} height={52} rx={10} fill="#d0d4e0" />
                <circle cx={60} cy={0} r={22} fill="#1a1a2a" />
                <circle cx={-40} cy={-10} r={8} fill={C.red} opacity={0.5 + 0.5 * Math.sin(t * 8)} />
              </g>
            ))
          : null}
      </svg>
      <Pop at={s0} out={close - 0.3} style={{top: 140, left: 1000, right: 60}}>
        <Title size={110}>EL CASINO</Title>
      </Pop>
      <Pop at={close - 0.1} out={win - 0.3} style={{top: 200, left: 1000, right: 60}}>
        <Card border={C.red} style={{fontSize: 64}}>
          NO VA MÁS
        </Card>
      </Pop>
      <Pop at={win - 0.1} out={out - 0.3} style={{top: 300, left: 1000, right: 60, flexDirection: 'column', gap: 16}}>
        <Title size={70}>GANANCIAS</Title>
        <Title size={130} color={C.accent}>
          +{wins * 3500} €
        </Title>
      </Pop>
      <Pop at={out - 0.1} style={{top: 360, left: 1000, right: 60}}>
        <div style={{rotate: '-10deg', border: `12px solid ${C.red}`, borderRadius: 20, padding: '10px 40px', fontFamily: FONT, fontWeight: 900, fontSize: 100, color: C.red}}>EXPULSADO</div>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 15. LA BOLSA
// =====================================================================
const price = (x) => 760 - x * 0.12 + Math.sin(x * 0.02) * 60 + Math.sin(x * 0.053) * 30 + Math.sin(x * 0.11) * 12;

const StockScene = () => {
  const t = useT();
  const s0 = P[15];
  const off = (t - s0) * 60;
  const NOW = 1100;
  const pts = (a, b) =>
    Array.from({length: Math.ceil((b - a) / 8) + 1})
      .map((_, i) => {
        const x = a + i * 8;
        return `${i ? 'L' : 'M'}${x} ${price(x + off) + off * 0.12}`;
      })
      .join(' ');
  const buy = Wa('comprar', s0);
  const sell = Wa('vender', s0);
  const rich = Wa('meses', s0);
  const fortune = r(t, rich - 0.5, Wa('ricas', s0), 1000, 1000000000, (x) => x * x * x);
  return (
    <Bg a="#0a2a3a" b="#02080c">
      <svg {...CANVAS}>
        {Array.from({length: 9}).map((_, i) => (
          <line key={i} x1={100} x2={1820} y1={140 + i * 90} y2={140 + i * 90} stroke="#fff" strokeWidth={1} opacity={0.08} />
        ))}
        <path d={pts(100, NOW)} fill="none" stroke={C.green} strokeWidth={8} strokeLinejoin="round" />
        <Ghost o={0.85}>
          <path d={pts(NOW, NOW + 500)} fill="none" stroke="#fff" strokeWidth={8} strokeDasharray="18 12" />
        </Ghost>
        <line x1={NOW} x2={NOW} y1={120} y2={860} stroke="#fff" strokeWidth={3} strokeDasharray="10 10" opacity={0.5} />
        <circle cx={NOW} cy={price(NOW + off) + off * 0.12} r={16} fill={C.green} />
        <text x={NOW} y={110} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={30} fill="#fff">
          AHORA
        </text>
        <FutTag x={NOW + 420} y={110} />
        {t > buy - 0.1 && t < rich ? (
          <g transform={`translate(${NOW} ${price(NOW + off) + off * 0.12 + 70})`}>
            <rect x={-90} y={-30} width={180} height={60} rx={30} fill={C.green} />
            <text y={14} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={34} fill="#05060f">
              COMPRA
            </text>
          </g>
        ) : null}
        {t > sell - 0.1 && t < rich ? (
          <g transform={`translate(${NOW + 300} ${price(NOW + 300 + off) + off * 0.12 - 70})`}>
            <rect x={-90} y={-30} width={180} height={60} rx={30} fill={C.red} />
            <text y={14} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={34} fill="#fff">
              VENDE
            </text>
          </g>
        ) : null}
      </svg>
      <Pop at={s0} out={Wa('millonésimas', s0) - 0.3} style={{top: 140, left: 0, right: 0}}>
        <Title size={110}>LA BOLSA</Title>
      </Pop>
      <Pop at={Wa('millonésimas', s0) - 0.1} out={Wa('tendrías', s0) - 0.3} style={{top: 160, left: 0, right: 0, flexDirection: 'column', gap: 14}}>
        <Card style={{fontSize: 50}}>ORDENADORES: 0,000001 s</Card>
      </Pop>
      <Pop at={Wa('tendrías', s0) - 0.1} out={buy - 0.3} style={{top: 160, left: 0, right: 0, flexDirection: 'column', gap: 14}}>
        <Card border={FUT} style={{fontSize: 70, color: FUT}}>
          TÚ: 5 s
        </Card>
        {t > Wa('eternidad', s0) - 0.1 ? <Title size={80}>= UNA ETERNIDAD</Title> : null}
      </Pop>
      <Pop at={rich - 0.3} style={{top: 140, left: 0, right: 0, flexDirection: 'column', gap: 10}}>
        <Title size={60}>TU FORTUNA</Title>
        <Title size={140} color={C.accent}>
          {String(Math.round(fortune)).replace(/\B(?=(\d{3})+(?!\d))/g, '.')} €
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 16-17. ALGUIEN SE DARÍA CUENTA
// =====================================================================
const Jet = () => (
  <g>
    <path d="M-140 0 L120 -16 L160 0 L120 16 Z" fill="#8a93a8" stroke="#05060f" strokeWidth={5} />
    <path d="M-20 -10 L-80 -90 L-50 -90 L40 -10 Z M-20 10 L-80 90 L-50 90 L40 10 Z" fill="#6b7489" stroke="#05060f" strokeWidth={5} />
    <path d="M-140 0 L-170 -50 L-130 -8 Z" fill="#6b7489" />
  </g>
);

const FoundScene = () => {
  const t = useT();
  const s0 = P[16];
  const who = [
    [Wa('banco', s0), 'TU BANCO', '#fff'],
    [Wa('reguladores', s0), 'LOS REGULADORES', C.accent],
    [Wa('poderosa', s0), 'GENTE MUY PODEROSA', C.red],
  ];
  const army = Wa('ejército', s0);
  const arma = Wa('arma', s0);
  const free = Wa('libre', s0);
  return (
    <Bg a="#3a0a14" b="#0b0204">
      <svg {...CANVAS}>
        <Human x={960} y={840} s={2.4} t={t} modern />
        {t < army
          ? Array.from({length: 8}).map((_, i) => {
              const a = (i / 8) * Math.PI * 2 + t * 0.3;
              const k = lin(t, s0 + 0.5 + i * 0.2, s0 + 1 + i * 0.2, 0, 1);
              return (
                <g key={i} transform={`translate(${960 + Math.cos(a) * 560} ${560 + Math.sin(a) * 300})`} opacity={k}>
                  <ellipse rx={50} ry={30} fill="#fff" />
                  <circle cx={Math.cos(a + Math.PI) * 14} cy={Math.sin(a + Math.PI) * 8} r={16} fill="#05060f" />
                </g>
              );
            })
          : null}
        {t > army - 0.2 && t < free - 0.2 ? (
          <g>
            <g transform={`translate(${lin(t, army - 0.2, army + 4, -200, 2100)} 200)`}>
              <Jet />
            </g>
            <g transform={`translate(${lin(t, army + 1, army + 5, -200, 2100)} 330) scale(0.7)`}>
              <Jet />
            </g>
          </g>
        ) : null}
        {t > free - 0.2
          ? Array.from({length: 9}).map((_, i) => <rect key={i} x={760 + i * 50} y={r(t, free - 0.2 + i * 0.04, free + 0.3 + i * 0.04, -600, 380)} width={16} height={480} rx={8} fill="#9aa3b8" />)
          : null}
        {t > free - 0.2 ? <rect x={740} y={r(t, free - 0.2, free + 0.3, -600, 370)} width={440} height={24} rx={10} fill="#9aa3b8" /> : null}
      </svg>
      <Pop at={s0} out={who[0][0] - 0.3} style={{top: 120, left: 0, right: 0}}>
        <Title size={100} color={C.red}>
          ALGUIEN SE DARÍA CUENTA
        </Title>
      </Pop>
      <div style={{position: 'absolute', top: 110, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 22}}>
        {who.map(([at, txt, col]) =>
          t > at - 0.1 && t < army - 0.3 ? (
            <div key={txt} style={{scale: String(r(t, at - 0.1, at + 0.3, 0.4, 1, BACK))}}>
              <Pill color={col} text={col === C.red ? '#fff' : '#05060f'} size={44}>
                {txt}
              </Pill>
            </div>
          ) : null,
        )}
      </div>
      <Pop at={Wa('piloto', s0) - 0.1} out={arma - 0.3} style={{top: 470, left: 0, right: 0, gap: 30}}>
        <Pill color="#fff" size={44}>
          PILOTO
        </Pill>
        {t > Wa('guardaespaldas', s0) - 0.1 ? (
          <Pill color={C.accent} size={44}>
            GUARDAESPALDAS
          </Pill>
        ) : null}
      </Pop>
      <Pop at={arma - 0.2} out={free - 0.3} style={{top: 110, left: 0, right: 0, flexDirection: 'column'}}>
        <Title size={80}>EL ARMA MÁS VALIOSA</Title>
        <Title size={110} color={C.red}>
          DEL MUNDO
        </Title>
      </Pop>
      <Pop at={free - 0.1} style={{top: 110, left: 0, right: 0}}>
        <Title size={110} color={C.red}>
          ¿Y TU LIBERTAD?
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 18. ESCONDERLO
// =====================================================================
const HideScene = () => {
  const t = useT();
  return (
    <Bg a="#141432" b="#040410">
      <svg {...CANVAS}>
        <Human x={960} y={860} s={2.6} t={t} modern />
        <path d="M900 470 Q960 380 1020 470 L1040 560 L880 560 Z" fill="#2a2f50" opacity={0.95} />
        <rect x={0} y={0} width={1920} height={1080} fill="url(#spot)" />
        <defs>
          <radialGradient id="spot">
            <stop offset="0.25" stopColor="#000" stopOpacity="0" />
            <stop offset="0.7" stopColor="#000" stopOpacity="0.85" />
          </radialGradient>
        </defs>
      </svg>
      <Pop at={P[18]} style={{top: 140, left: 0, right: 0, flexDirection: 'column', gap: 16}}>
        <Title size={110}>ESCÓNDELO</Title>
        {t > Wa('poco', P[18]) - 0.1 ? (
          <Pill color={FUT} size={50}>
            SOLO UN POCO. LO JUSTO.
          </Pill>
        ) : null}
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 19-21. EL PRECIO: nunca más una sorpresa
// =====================================================================
const Gift = () => (
  <g>
    <rect x={-80} y={-60} width={160} height={130} rx={10} fill={C.pink} stroke="#05060f" strokeWidth={6} />
    <rect x={-92} y={-90} width={184} height={40} rx={10} fill={C.pink} stroke="#05060f" strokeWidth={6} />
    <rect x={-14} y={-90} width={28} height={160} fill={C.accent} />
    <path d="M0 -90 Q-60 -150 -40 -100 Z M0 -90 Q60 -150 40 -100 Z" fill={C.accent} stroke="#05060f" strokeWidth={4} />
  </g>
);
const Balloons = ({t}) => (
  <g>
    {[[-50, '#ff5a36'], [10, '#5ee7ff'], [60, '#ffd23f']].map(([x, c], i) => (
      <g key={i} transform={`translate(${x} ${Math.sin(t * 2 + i) * 8})`}>
        <line x1={0} y1={-40} x2={-x * 0.4} y2={80} stroke="#fff" strokeWidth={3} />
        <ellipse cx={0} cy={-80} rx={40} ry={50} fill={c} stroke="#05060f" strokeWidth={5} />
      </g>
    ))}
  </g>
);
const Film = () => (
  <g>
    <rect x={-90} y={-70} width={180} height={140} rx={12} fill="#1a1a2a" stroke="#fff" strokeWidth={6} />
    {[-50, 0, 50].map((x) => (
      <rect key={x} x={x - 14} y={-60} width={28} height={14} fill="#fff" />
    ))}
    <text y={28} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={34} fill={C.accent}>
      FIN
    </text>
  </g>
);

const PriceScene = () => {
  const t = useT();
  const items = [
    [Wa('fiesta', P[21]), 'FIESTA SORPRESA', 'b'],
    [Wa('película', P[21]), 'FINAL DE LA PELI', 'f'],
    [Wa('regalo', P[21]), 'UN REGALO', 'g'],
  ];
  const pleasure = Wa('placer', P[21]);
  const lost = Wa('perdido', P[21]);
  const bar = t < lost ? r(t, pleasure, pleasure + 0.8, 0, 100) : r(t, lost, lost + 1, 100, 0);
  return (
    <Bg a="#3a1450" b="#0b0418">
      <svg {...CANVAS}>
        {t > P[21] - 0.2 && t < pleasure - 0.2
          ? items.map(([at, , kind], i) =>
              t > at - 0.2 ? (
                <g key={kind} transform={`translate(${420 + i * 540} 560) scale(${r(t, at - 0.2, at + 0.3, 0.4, 1.3, BACK)})`}>
                  {kind === 'b' ? <Balloons t={t} /> : kind === 'f' ? <Film /> : <Gift />}
                  <FutTag x={0} y={-180} label="YA LO SABÍAS" o={lin(t, at + 0.6, at + 0.9, 0, 1)} />
                </g>
              ) : null,
            )
          : null}
      </svg>
      <Pop at={Wa('grande', P[19]) - 0.2} out={P[20] - 0.2} style={{top: 300, left: 0, right: 0}}>
        <Title size={110} color={C.red}>
          EL PROBLEMA MÁS GRANDE
        </Title>
      </Pop>
      <Pop at={P[20]} out={P[21] - 0.2} style={{top: 260, left: 0, right: 0, flexDirection: 'column', gap: 8}}>
        <Title size={100}>NUNCA MÁS</Title>
        <Title size={140} color={C.accent}>
          TE SORPRENDERÍA
        </Title>
        <Title size={100}>NADA</Title>
      </Pop>
      {t > P[21] - 0.2 && t < pleasure - 0.2 ? (
        <div style={{position: 'absolute', top: 800, left: 0, right: 0, display: 'flex', justifyContent: 'space-around', padding: '0 120px'}}>
          {items.map(([at, txt]) => (
            <div key={txt} style={{opacity: lin(t, at - 0.1, at + 0.2, 0, 1), fontFamily: FONT, fontWeight: 900, fontSize: 40, color: '#fff'}}>{txt}</div>
          ))}
        </div>
      ) : null}
      <Pop at={pleasure - 0.2} style={{top: 200, left: 0, right: 0, flexDirection: 'column', gap: 24}}>
        <Title size={80}>SORPRESA = PLACER</Title>
        <div style={{width: 1000, height: 70, borderRadius: 35, background: 'rgba(255,255,255,0.15)', border: '4px solid #fff', overflow: 'hidden'}}>
          <div style={{height: '100%', width: `${bar}%`, background: `linear-gradient(90deg, ${C.pink}, ${C.accent})`}} />
        </div>
        <Title size={110} color={t > lost ? C.red : C.accent}>
          {Math.round(bar)} %
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 22. DOS REALIDADES A LA VEZ
// =====================================================================
const DoubleScene = () => {
  const t = useT();
  const s0 = P[22];
  const g = lin(t, s0, P[23], 10, 90);
  const steps = [
    [Wa('principio', s0), 'AL PRINCIPIO: DIVERTIDO', C.green],
    [Wa('semana', s0), 'A LA SEMANA: AGOTADOR', C.accent],
    [Wa('mes', s0), 'AL MES: ¿CUÁL ES LA REAL?', C.red],
  ];
  const jx = Math.sin(t * 23) * g * 0.3;
  return (
    <Bg a="#101040" b="#020208">
      <svg {...CANVAS}>
        <g transform={`translate(${jx} 0)`}>
          <Human x={960} y={840} s={2.6} t={t} modern />
        </g>
        <Ghost o={0.6}>
          <g transform={`translate(${g + jx * -1} ${Math.sin(t * 17) * g * 0.2})`}>
            <Human x={960} y={840} s={2.6} t={t + 5} modern wave={60} />
          </g>
        </Ghost>
        {Array.from({length: 8}).map((_, i) => (
          <rect key={i} x={0} y={random(`gl${i}${Math.floor(t * 12)}`) * 1080} width={1920} height={4 + random(`gh${i}${Math.floor(t * 12)}`) * 16} fill={i % 2 ? FUT : C.pink} opacity={(g / 90) * 0.25} />
        ))}
      </svg>
      <Pop at={s0} out={steps[0][0] - 0.3} style={{top: 120, left: 0, right: 0}}>
        <Title size={90}>DOS PELÍCULAS EN UNA PANTALLA</Title>
      </Pop>
      <div style={{position: 'absolute', top: 120, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16}}>
        {steps.map(([at, txt, col]) =>
          t > at - 0.1 && t < Wa('normales', s0) - 0.3 ? (
            <div key={txt} style={{scale: String(r(t, at - 0.1, at + 0.3, 0.5, 1, BACK))}}>
              <Pill color={col} text={col === C.red ? '#fff' : '#05060f'} size={48}>
                {txt}
              </Pill>
            </div>
          ) : null,
        )}
      </div>
      <Pop at={Wa('normales', s0) - 0.6} style={{top: 140, left: 0, right: 0, flexDirection: 'column'}}>
        <Title size={70}>SOLO QUERRÍAS UNA COSA:</Title>
        <Title size={120} color={C.accent}>
          VOLVER A SER NORMAL
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 23-24. EL GIRO
// =====================================================================
const TwistScene = () => {
  const t = useT();
  return (
    <Bg a="#003a4a" b="#00080c">
      <svg {...CANVAS}>
        <Stars t={t} n={90} color={FUT} seed="tw" />
        {Array.from({length: 5}).map((_, i) => (
          <circle key={i} cx={960} cy={540} r={((t * 200 + i * 160) % 900) + 10} fill="none" stroke={FUT} strokeWidth={4} opacity={0.4 * (1 - ((t * 200 + i * 160) % 900) / 900)} />
        ))}
      </svg>
      <Pop at={P[23]} out={P[24] - 0.2} style={{top: 340, left: 0, right: 0}}>
        <Title size={100}>LO QUE TE PROMETÍ…</Title>
      </Pop>
      <Pop at={P[24] - 0.1} style={{top: 240, left: 0, right: 0, flexDirection: 'column', gap: 20}}>
        <Title size={170} color={FUT}>
          TÚ YA VES
        </Title>
        <Title size={170} color={FUT}>
          EL FUTURO
        </Title>
        {t > Wa('poquito', P[24]) - 0.1 ? (
          <Pill color="#fff" size={56}>
            UN POQUITO
          </Pill>
        ) : null}
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 25. LA LUZ TARDA EN LLEGAR AL CEREBRO
// =====================================================================
const Eye = ({x, y, s = 1}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d="M-130 0 Q0 -110 130 0 Q0 110 -130 0 Z" fill="#fff" stroke="#05060f" strokeWidth={8} />
    <circle r={50} fill="#3d7bd9" />
    <circle r={24} fill="#05060f" />
    <circle cx={14} cy={-14} r={9} fill="#fff" />
  </g>
);
const Brain = ({x, y, s = 1, glow = 0}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <circle r={150} fill={C.pink} opacity={0.2 * glow} />
    <path d="M-120 20 Q-150 -60 -80 -100 Q-40 -150 20 -120 Q90 -150 120 -70 Q160 0 110 60 Q60 110 0 90 Q-60 110 -100 70 Q-130 50 -120 20 Z" fill="#ff9ec4" stroke="#05060f" strokeWidth={8} />
    <path d="M-80 -40 Q-40 -10 -60 40 M0 -110 Q-10 -40 20 0 Q50 40 20 80 M60 -80 Q90 -30 70 30" fill="none" stroke="#d45d8f" strokeWidth={8} strokeLinecap="round" />
  </g>
);

const LightScene = () => {
  const t = useT();
  const s0 = P[25];
  const k = ((t - s0) % 2) / 2;
  const late = Wa('tarde', s0);
  return (
    <Bg a="#0a2a4a" b="#02060c">
      <svg {...CANVAS}>
        <g transform={`translate(260 ${430 + Math.sin(t * 3) * 120})`}>
          <Ball r={50} />
        </g>
        <g transform="translate(260 430)" opacity={0.35}>
          <circle r={50} fill="none" stroke="#fff" strokeWidth={4} strokeDasharray="10 8" />
        </g>
        <path d="M320 430 L760 430" stroke={C.accent} strokeWidth={8} strokeDasharray="20 14" strokeDashoffset={-t * 120} />
        <Eye x={860} y={430} />
        <path d="M990 430 Q1150 430 1300 380" fill="none" stroke={C.pink} strokeWidth={10} strokeDasharray="4 18" strokeLinecap="round" strokeDashoffset={-t * 60} />
        <circle cx={lin(k, 0, 1, 990, 1300)} cy={lin(k, 0, 1, 430, 380)} r={14} fill={C.pink} />
        <Brain x={1460} y={380} glow={k > 0.9 ? 1 : 0} />
      </svg>
      <Pop at={Wa('décima', s0) - 0.2} out={Wa('pasado', s0) - 0.3} style={{top: 680, left: 0, right: 0, gap: 24}}>
        <Card border={C.pink} style={{fontSize: 60}}>
          RETRASO: 0,1 s
        </Card>
      </Pop>
      <Pop at={Wa('pasado', s0) - 0.1} out={late - 0.3} style={{top: 120, left: 0, right: 0}}>
        <Title size={84}>TODO LO QUE VES… YA HA PASADO</Title>
      </Pop>
      <Pop at={late - 0.2} style={{top: 120, left: 0, right: 0}}>
        <Title size={100} color={C.red}>
          LLEGARÍAS SIEMPRE TARDE
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 26. EL CEREBRO PREDICE
// =====================================================================
const PredictScene = () => {
  const t = useT();
  const s0 = P[26];
  const fx = Wa('efecto', s0);
  const throwK = t < fx ? ((t - s0) % 3) / 3 : 0;
  const path = (k) => [300 + k * 1300, 800 - Math.sin(k * Math.PI) * 600];
  const [bx, by] = path(throwK);
  const [gx, gy] = path(Math.min(1, throwK + 0.12));
  const dot = ((t - fx) * 600) % 1900;
  const flash = Math.floor((t - fx) * 1.2) !== Math.floor((t - fx - 0.08) * 1.2);
  return (
    <Bg a="#2a1050" b="#05020c">
      <svg {...CANVAS}>
        {t < fx - 0.3 ? (
          <g>
            <path d="M300 800 Q950 -400 1600 800" fill="none" stroke="#fff" strokeWidth={3} strokeDasharray="8 12" opacity={0.3} />
            <Ghost o={0.8}>
              <g transform={`translate(${gx} ${gy})`}>
                <Ball r={40} />
              </g>
            </Ghost>
            <g transform={`translate(${bx} ${by})`}>
              <Ball r={40} />
            </g>
            <Human x={1640} y={960} s={1.8} t={t} modern wave={60} flip />
            <text x={gx} y={gy - 70} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={32} fill={FUT}>
              PREDICCIÓN
            </text>
          </g>
        ) : (
          <g>
            <line x1={0} x2={1920} y1={440} y2={440} stroke="#fff" strokeWidth={2} opacity={0.2} />
            <circle cx={dot} cy={440} r={40} fill={C.accent} />
            <Ghost o={0.7}>
              <circle cx={dot + 90} cy={440} r={40} fill={C.accent} />
            </Ghost>
            {flash ? <circle cx={dot} cy={560} r={40} fill="#fff" /> : null}
            <text x={dot + 90} y={370} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={30} fill={FUT}>
              LO QUE VES
            </text>
          </g>
        )}
      </svg>
      <Pop at={Wa('prediciendo', s0) - 0.2} out={Wa('atrapas', s0) - 0.3} style={{top: 120, left: 0, right: 0}}>
        <Title size={130} color={FUT}>
          PREDICIENDO
        </Title>
      </Pop>
      <Pop at={fx - 0.2} out={Wa('futuro', fx) - 0.3} style={{top: 680, left: 0, right: 0}}>
        <Pill color={C.accent} size={56}>
          EFECTO FLASH-LAG
        </Pill>
      </Pop>
      <Pop at={Wa('futuro', fx) - 0.4} style={{top: 680, left: 0, right: 0}}>
        <Title size={80} color={FUT}>
          TU CEREBRO LO EMPUJA AL FUTURO
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 27. CONCLUSIÓN
// =====================================================================
const ConclusionScene = () => {
  const t = useT();
  const s0 = P[27];
  const price = Wa('precio', s0);
  return (
    <Bg a="#1a2a5a" b="#04060f">
      <svg {...CANVAS}>
        <Stars t={t} n={60} color={FUT} seed="cc" />
      </svg>
      <Pop at={s0} out={price - 0.6} style={{top: 140, left: 0, right: 0, flexDirection: 'column', gap: 30}}>
        <Title size={84}>TODOS VEMOS UN POCO EL FUTURO</Title>
        <div style={{display: 'flex', gap: 40}}>
          <Card border="#fff" style={{fontSize: 64}}>
            TÚ: 0,1 s
          </Card>
          <Card border={FUT} style={{fontSize: 64, color: FUT}}>
            EL PODER: 5 s
          </Card>
        </div>
        {t > Wa('sobrevivir', s0) - 0.1 ? (
          <Pill color={C.green} size={50}>
            LO JUSTO PARA SOBREVIVIR
          </Pill>
        ) : null}
      </Pop>
      <Pop at={price - 0.5} style={{top: 200, left: 0, right: 0, flexDirection: 'column', gap: 16}}>
        <Title size={80}>NO SORPRENDERSE NUNCA MÁS</Title>
        <Title size={130} color={C.red}>
          UN PRECIO ENORME
        </Title>
      </Pop>
    </Bg>
  );
};

// =====================================================================
// 28. LA CIVILIZACIÓN
// =====================================================================
const CivScene = () => {
  const t = useT();
  const s0 = P[28];
  const grow = r(t, Wa('sola', s0), Wa('cientos', s0) + 0.5, 1, 265);
  const wall = Wa('muralla', s0);
  const dylan = Wa('dylan', s0);
  const sails = Wa('velas', s0);
  const S = 0.78;
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#0b3a6a, #04152e)'}}>
      <svg {...CANVAS}>
        {Array.from({length: 30}).map((_, i) => (
          <path key={i} d={`M${(i * 173 + t * 20) % 2000 - 40} ${(i * 97) % 1080} q16 -8 32 0 q16 8 32 0`} fill="none" stroke="#cfe9ff" strokeWidth={3} opacity={0.35} />
        ))}
        <g transform={`translate(${620 - 540 * S} ${520 - 975 * S}) scale(${S})`}>
          <IslandWorld t={t} pop={Math.round(grow)} maxShown={70} size={1.35}>
            <Landmarks t={t} rock={false} />
          </IslandWorld>
          {t > wall - 0.2 ? <Wall k={r(t, wall - 0.2, wall + 1.2, 0, 1)} /> : null}
          <ellipse cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y + 4} rx={30} ry={12} fill="#9aa3b8" />
          <Villager x={SPOTS.dylanRock.x} y={SPOTS.dylanRock.y} t={t} seed={7} s={1.7} shirt="#a78bfa" crown wave={50} />
          {t > dylan - 0.2 ? <circle cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y - 40} r={70 + 10 * Math.sin(t * 6)} fill="none" stroke="#a78bfa" strokeWidth={8} /> : null}
        </g>
        {t > sails - 0.3
          ? [0, 1, 2].map((k) => <Ship key={k} x={lin(t, sails - 0.3, sails + 6, 1500, 1260) + k * 170} y={830 - (k % 2) * 50} s={0.75} o={lin(t, sails - 0.3, sails + 0.3, 0, 1)} />)
          : null}
      </svg>
      <div style={{position: 'absolute', top: 120, left: 1090, right: 40, display: 'flex', flexDirection: 'column', alignItems: 'flex-start', gap: 22}}>
        {t > s0 + 2 ? (
          <div style={{scale: String(r(t, s0 + 2, s0 + 2.4, 0.5, 1, BACK)), transformOrigin: 'left'}}>
            <BigText size={76} color={C.accent} stroke={12} style={{textAlign: 'left', whiteSpace: 'nowrap'}}>
              LA CIVILIZACIÓN
            </BigText>
          </div>
        ) : null}
        {[
          [Wa('habitante', s0), '1 SEGUIDOR = 1 HABITANTE', '#fff'],
          [Wa('cientos', s0), `${Math.round(grow)} HABITANTES`, C.green],
          [Wa('likes', s0), 'LO MÁS VOTADO SE HACE REALIDAD', C.accent],
          [dylan, 'DYLAN, EL VIDENTE', '#a78bfa'],
          [sails, 'VELAS NEGRAS…', C.red],
        ].map(([at, txt, col]) =>
          t > at - 0.2 ? (
            <div key={at} style={{scale: String(r(t, at - 0.2, at + 0.2, 0.5, 1, BACK)), transformOrigin: 'left'}}>
              <Pill color={col} text={col === C.red ? '#fff' : '#05060f'} size={34}>
                {txt}
              </Pill>
            </div>
          ) : null,
        )}
        {t > Wa('seguirme', s0) - 0.2 ? (
          <div style={{marginTop: 10, display: 'flex', flexDirection: 'column', gap: 12, scale: String(r(t, Wa('seguirme', s0) - 0.2, Wa('seguirme', s0) + 0.3, 0.5, 1, BACK)), transformOrigin: 'left'}}>
            <BigText size={64} stroke={10} style={{textAlign: 'left'}}>
              SÍGUEME Y VIVE EN LA ISLA
            </BigText>
            <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 40, color: FUT}}>TikTok @aprended · IG @aprendedconmigo</div>
          </div>
        ) : null}
      </div>
    </AbsoluteFill>
  );
};

// =====================================================================
// 29. MÁS VÍDEOS DEL CANAL
// =====================================================================
const MoreScene = () => {
  const t = useT();
  const s0 = P[29];
  const vids = [
    [Wa('veinte', s0), 'thumbs/20000.png', '¿Y si despertaras hace 20.000 años?'],
    [Wa('fosa', s0), 'thumbs/fosa.png', '¿Y si bajaras a la Fosa de las Marianas?'],
  ];
  return (
    <Bg a="#3a0d12" b="#05060f">
      <div style={{position: 'absolute', top: 90, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Title size={80}>MÁS VIAJES EN EL CANAL</Title>
      </div>
      <div style={{position: 'absolute', top: 240, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 70}}>
        {vids.map(([at, src, title]) => (
          <div key={src} style={{width: 760, opacity: lin(t, at - 0.2, at + 0.1, 0, 1), scale: String(r(t, at - 0.2, at + 0.3, 0.6, 1, BACK)), display: 'flex', flexDirection: 'column', gap: 18}}>
            <div style={{position: 'relative', width: 760, height: 428, borderRadius: 24, overflow: 'hidden', border: '6px solid #fff', boxShadow: '0 30px 80px rgba(0,0,0,0.6)'}}>
              <Img src={staticFile(src)} style={{width: '100%', height: '100%', objectFit: 'cover'}} />
              <div style={{position: 'absolute', right: 14, bottom: 14, background: 'rgba(0,0,0,0.85)', color: '#fff', fontFamily: FONT, fontWeight: 800, fontSize: 28, padding: '4px 12px', borderRadius: 8}}>8:00</div>
            </div>
            <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 38, color: '#fff'}}>{title}</div>
          </div>
        ))}
      </div>
    </Bg>
  );
};

// =====================================================================
// 30. CIERRE
// =====================================================================
const OutroScene = () => {
  const t = useT();
  const s0 = P[30];
  const tapAt = s0 + 1.2;
  const tapped = t > tapAt;
  const tap = t > tapAt - 0.15 && t < tapAt + 0.1 ? 0.9 : 1;
  return (
    <Bg a="#1d1450">
      <svg {...CANVAS}>
        <Stars t={t} n={60} color={FUT} seed="ou" />
      </svg>
      <Pop at={s0} style={{top: 110, left: 0, right: 0, flexDirection: 'column'}}>
        <div style={{width: 140, height: 140, borderRadius: 40, background: `linear-gradient(135deg, ${C.accent}, ${C.hot} 60%, ${C.pink})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 100, color: '#0b0b14'}}>A</div>
        <div style={{marginTop: 20, display: 'flex', alignItems: 'center', gap: 16, padding: '20px 60px', borderRadius: 60, background: tapped ? 'rgba(255,255,255,0.2)' : '#e62117', fontFamily: FONT, fontWeight: 900, fontSize: 56, color: '#fff', scale: String(tap)}}>
          {tapped ? <Check size={56} /> : null}
          {tapped ? 'SUSCRITO' : 'SUSCRIBIRSE'}
        </div>
      </Pop>
      <Pop at={Wa('comentarios', s0) - 0.2} style={{top: 520, left: 0, right: 0, flexDirection: 'column', gap: 10}}>
        <Title size={60}>CON 5 SEGUNDOS DE FUTURO…</Title>
        <Title size={110} color={FUT}>
          ¿QUÉ HARÍAS PRIMERO?
        </Title>
      </Pop>
    </Bg>
  );
};

const EndScreen = () => {
  const t = useT();
  return (
    <Bg>
      <svg {...CANVAS}>
        <Stars t={t} n={60} color={FUT} seed="es" />
      </svg>
      <div style={{position: 'absolute', top: 110, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Title size={70}>¿SIGUES CON GANAS DE MÁS?</Title>
      </div>
      <div style={{position: 'absolute', top: 300, left: 200, width: 820, height: 461, borderRadius: 20, border: '6px dashed rgba(255,255,255,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 48, color: 'rgba(255,255,255,0.7)'}}>MIRA ESTE VÍDEO</div>
      <div style={{position: 'absolute', top: 340, left: 1240, width: 380, height: 380, borderRadius: '50%', border: '6px dashed rgba(255,255,255,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 44, color: 'rgba(255,255,255,0.7)', textAlign: 'center'}}>SUSCRÍBETE</div>
    </Bg>
  );
};

const CHAPTERS = [
  [3, 'TU PRIMER DÍA'],
  [6, 'A JUGAR'],
  [10, 'LA PARADOJA'],
  [13, 'EL DINERO'],
  [16, 'TE DESCUBREN'],
  [19, 'EL PRECIO'],
  [23, 'EL GIRO FINAL'],
];

// =====================================================================
export const Futuro = () => (
  <AbsoluteFill style={{backgroundColor: '#05060f'}}>
    <Scene name="Gancho" start={0} end={P[1]} fadeOut={false}>
      <HookScene />
    </Scene>
    <Scene name="Firma" start={P[1]} end={P[2]}>
      <BrandSting />
    </Scene>
    <Scene name="Reglas" start={P[2]} end={P[3]}>
      <RulesScene />
    </Scene>
    <Scene name="Calle" start={P[3]} end={P[5]}>
      <StreetScene />
    </Scene>
    <Scene name="Tráfico" start={P[5]} end={P[6]}>
      <TrafficScene />
    </Scene>
    <Scene name="Jugar" start={P[6]} end={P[7]}>
      <PlayScene />
    </Scene>
    <Scene name="Piedra papel tijera" start={P[7]} end={P[8]}>
      <RpsScene />
    </Scene>
    <Scene name="Penalti" start={P[8]} end={P[9]}>
      <FootballScene />
    </Scene>
    <Scene name="Conversaciones" start={P[9]} end={P[10]}>
      <TalkScene />
    </Scene>
    <Scene name="Paradoja" start={P[10]} end={P[13]}>
      <ParadoxScene />
    </Scene>
    <Scene name="Dinero" start={P[13]} end={P[14]}>
      <MoneyScene />
    </Scene>
    <Scene name="Casino" start={P[14]} end={P[15]}>
      <CasinoScene />
    </Scene>
    <Scene name="Bolsa" start={P[15]} end={P[16]}>
      <StockScene />
    </Scene>
    <Scene name="Te descubren" start={P[16]} end={P[18]}>
      <FoundScene />
    </Scene>
    <Scene name="Esconderlo" start={P[18]} end={P[19]}>
      <HideScene />
    </Scene>
    <Scene name="El precio" start={P[19]} end={P[22]}>
      <PriceScene />
    </Scene>
    <Scene name="Dos realidades" start={P[22]} end={P[23]}>
      <DoubleScene />
    </Scene>
    <Scene name="El giro" start={P[23]} end={P[25]}>
      <TwistScene />
    </Scene>
    <Scene name="La luz" start={P[25]} end={P[26]}>
      <LightScene />
    </Scene>
    <Scene name="Predicción" start={P[26]} end={P[27]}>
      <PredictScene />
    </Scene>
    <Scene name="Conclusión" start={P[27]} end={P[28]}>
      <ConclusionScene />
    </Scene>
    <Scene name="La civilización" start={P[28]} end={P[29]}>
      <CivScene />
    </Scene>
    <Scene name="Más vídeos" start={P[29]} end={P[30]}>
      <MoreScene />
    </Scene>
    <Scene name="Cierre" start={P[30]} end={VOICE_END + 1}>
      <OutroScene />
    </Scene>
    <Scene name="Pantalla final" start={VOICE_END + 1} end={DURATION} fadeOut={false}>
      <EndScreen />
    </Scene>
    {CHAPTERS.map(([pi, title], i) => (
      <Scene key={pi} name={`Capítulo ${i + 1}`} start={P[pi]} end={P[pi] + 3.2} fadeOut={false}>
        <ChapterBanner at={P[pi]} n={i + 1} title={title} />
      </Scene>
    ))}
    <Scene name="Reloj +5 s" start={Wa('atrapas') + 1} end={P[28]} fadeOut={false}>
      <FutureClock />
    </Scene>
    <Brand hideAt={P[30]} pos={{top: 30, right: 40}} />
    <ProgressBar />
    <Captions chunks={CHUNKS} top={890} width={1600} fontSize={60} />
    <Audio src={staticFile('yt-futuro.mp3')} />
  </AbsoluteFill>
);
