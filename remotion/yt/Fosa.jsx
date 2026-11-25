import React from 'react';
import {AbsoluteFill, random, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, Scene, lin, r, useT} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, Check, ProgressBar} from '../tunel/Visuals';
import {makeWa} from '../civilizacion/words';
import {
  Amphipod, Anglerfish, Diver, FishSchool, GiantSquid, GlowFish, GoblinShark, Jelly, PlasticBag, Snailfish,
  SpermWhale, Submarine, Titanic, Trieste, Vent, VampireSquid, Viperfish, Fish,
} from './Oceano';
import WORDS from '../../public/yt-fosa.words.json';
import PARAS from '../../public/yt-fosa.paras.json';

const Wa = makeWa(WORDS);
const P = PARAS;
const VOICE_END = WORDS[WORDS.length - 1].end;
const END_SCREEN = 12; // segundos de pantalla final para los elementos de YouTube
export const DURATION = VOICE_END + 1 + END_SCREEN;

const CHUNKS = chunkWords(
  WORDS,
  [
    'submarino', 'kilómetros', 'marianas', 'mirando', 'aprende', 'luz', 'rojo', 'metros', 'apnea', 'crepúsculo',
    'migración', 'brillar', 'luz', 'medianoche', 'cachalote', 'calamar', 'gigante', 'rape', 'víbora', 'duende',
    'vampiro', 'paraguas', 'titanic', 'abisal', 'nieve', 'marina', 'chimeneas', 'grados', 'hadal', 'hades',
    'caracol', 'everest', 'presión', 'coche', 'implosionaría', 'milésimas', 'esfera', 'pesos', 'plástico',
    'trieste', 'cameron', 'luna', 'suscríbete',
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

const Card = ({children, border = C.accent, style}) => (
  <div style={{background: 'rgba(4,10,24,0.86)', border: `4px solid ${border}`, borderRadius: 26, padding: '14px 26px', fontFamily: FONT, color: '#fff', fontWeight: 900, ...style}}>{children}</div>
);

const fmt = (n) => String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');

// ---------- Profundidad a lo largo del vídeo ----------
const KEYS = () => [
  [0, 0],
  [P[2], 0],
  [P[3], 50],
  [P[3] + 4, 100],
  [P[4], 200],
  [P[6], 1000],
  [P[7], 1500],
  [P[8], 2200],
  [P[9], 2600],
  [P[10], 3800],
  [P[11], 4000],
  [P[13], 6000],
  [P[14], 7000],
  [Wa('ocho', P[14]) + 0.5, 8000],
  [P[15], 10900],
];
const depthAt = (t) => {
  const k = KEYS();
  for (let i = 0; i < k.length - 1; i++) {
    if (t <= k[i + 1][0]) return lin(t, k[i][0], k[i + 1][0], k[i][1], k[i + 1][1]);
  }
  return 10900;
};

const STOPS = [
  [0, [47, 169, 224]],
  [200, [13, 79, 143]],
  [1000, [6, 24, 58]],
  [4000, [3, 10, 28]],
  [11000, [1, 4, 9]],
];
const waterAt = (d) => {
  for (let i = 0; i < STOPS.length - 1; i++) {
    const [d0, c0] = STOPS[i];
    const [d1, c1] = STOPS[i + 1];
    if (d <= d1) {
      const k = (d - d0) / (d1 - d0);
      return `rgb(${c0.map((c, j) => Math.round(c + (c1[j] - c) * k)).join(',')})`;
    }
  }
  return 'rgb(1,4,9)';
};

const ZONES = [
  [0, 'LUZ'],
  [200, 'CREPÚSCULO'],
  [1000, 'MEDIANOCHE'],
  [4000, 'ABISAL'],
  [6000, 'HADAL'],
];

const Gauge = ({d}) => {
  const H = 640;
  const y = (v) => 140 + Math.sqrt(v / 11000) * H;
  return (
    <g>
      <rect x={1790} y={130} width={20} height={H + 20} rx={10} fill="rgba(255,255,255,0.15)" />
      {ZONES.map(([v, name]) => (
        <g key={name}>
          <line x1={1780} x2={1820} y1={y(v)} y2={y(v)} stroke="#fff" strokeWidth={3} opacity={0.6} />
          <text x={1770} y={y(v) + 8} textAnchor="end" fontFamily={FONT} fontWeight={800} fontSize={20} fill="#fff" opacity={0.7}>
            {name}
          </text>
        </g>
      ))}
      <rect x={1790} y={130} width={20} height={y(d) - 130} rx={10} fill={C.accent} />
      <circle cx={1800} cy={y(d)} r={16} fill={C.accent} stroke="#05060f" strokeWidth={4} />
    </g>
  );
};

const Snow = ({t, d, speed = 1}) => (
  <g>
    {Array.from({length: 90}).map((_, i) => {
      const x = random(`ms${i}`) * 1920 + Math.sin(t + i) * 10;
      const y = ((random(`my${i}`) * 1080 - t * (30 + random(`mv${i}`) * 40) * speed) % 1080 + 1080) % 1080;
      return <circle key={i} cx={x} cy={y} r={1.5 + random(`mr${i}`) * 2.5} fill="#e8f6ff" opacity={lin(d, 0, 400, 0.2, 0.6)} />;
    })}
  </g>
);

const ChapterBanner = ({at, n, title}) => {
  const t = useT();
  const k = Math.min(r(t, at, at + 0.5, 0, 1, INOUT), r(t, at + 2.6, at + 3.1, 1, 0, INOUT));
  return (
    <div style={{position: 'absolute', top: 30, left: 0, translate: `${(k - 1) * 1000}px 0`, display: 'flex', fontFamily: FONT, boxShadow: '0 20px 60px rgba(0,0,0,0.5)'}}>
      <div style={{background: C.accent, color: '#0b0b14', fontWeight: 900, fontSize: 34, padding: '18px 26px', display: 'flex', alignItems: 'center'}}>CAPÍTULO {n}</div>
      <div style={{background: 'rgba(4,10,24,0.92)', color: '#fff', fontWeight: 900, fontSize: 52, padding: '14px 40px 14px 30px'}}>{title}</div>
    </div>
  );
};

// =====================================================================
// 1. GANCHO
// =====================================================================
const HookScene = () => {
  const t = useT();
  const cam = r(t, 0, P[1], 0, 1, INOUT);
  const eyes = Wa('mirando', 10);
  return (
    <AbsoluteFill>
      <svg {...CANVAS}>
        <g transform={`translate(0 ${-cam * 500})`}>
          <rect x={0} y={-200} width={1920} height={560} fill="#8fd0ff" />
          <rect x={0} y={360} width={1920} height={2200} fill="url(#deep)" />
          <defs>
            <linearGradient id="deep" x1="0" y1="0" x2="0" y2="1">
              <stop offset="0" stopColor="#2fa9e0" />
              <stop offset="0.35" stopColor="#0d4f8f" />
              <stop offset="1" stopColor="#010409" />
            </linearGradient>
          </defs>
          {Array.from({length: 24}).map((_, i) => (
            <path key={i} d={`M${(i * 90 + t * 40) % 2000 - 60} 360 q22 -12 44 0 q22 12 44 0`} fill="none" stroke="#e8f6ff" strokeWidth={5} />
          ))}
          <Submarine x={960} y={450} s={0.9} t={t} />
          <line x1={1500} y1={420} x2={1500} y2={2000} stroke={C.accent} strokeWidth={6} strokeDasharray="20 14" />
          <path d="M1480 1980 L1500 2020 L1520 1980" fill="none" stroke={C.accent} strokeWidth={6} />
          {t > eyes - 0.2
            ? [
                [400, 1260],
                [760, 1400],
                [1240, 1320],
                [1620, 1440],
              ].map(([x, y], i) => (
                <g key={i} opacity={lin(t, eyes - 0.2 + i * 0.2, eyes + 0.3 + i * 0.2, 0, 1) * (Math.sin(t * 3 + i) > -0.9 ? 1 : 0.1)}>
                  <ellipse cx={x - 22} cy={y} rx={12} ry={8} fill="#c8ffef" style={{filter: 'drop-shadow(0 0 12px #7fffd4)'}} />
                  <ellipse cx={x + 22} cy={y} rx={12} ry={8} fill="#c8ffef" style={{filter: 'drop-shadow(0 0 12px #7fffd4)'}} />
                </g>
              ))
            : null}
        </g>
      </svg>
      <Pop at={Wa('once') - 0.1} out={Wa('marianas', 5) - 0.4} style={{top: 420, left: 1540}}>
        <Title size={90} color={C.accent}>
          11 km
        </Title>
      </Pop>
      <Pop at={Wa('marianas', 5) - 0.2} out={Wa('aviso') - 0.2} style={{top: 140, left: 0, right: 0}}>
        <Title size={100}>FOSA DE LAS MARIANAS</Title>
      </Pop>
      <Pop at={eyes - 0.1} style={{top: 140, left: 0, right: 0}}>
        <Title size={90} color="#c8ffef">
          …LO QUE TE ESTÁ MIRANDO
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 2. FIRMA DEL CANAL
// =====================================================================
const BrandSting = () => {
  const t = useT();
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 45%, #0d4f8f, #010409)'}}>
      <svg {...CANVAS}>
        {Array.from({length: 40}).map((_, i) => {
          const u = ((t - P[1]) * (0.5 + random(`bb${i}`)) + random(`bu${i}`)) % 1;
          return <circle key={i} cx={random(`bx${i}`) * 1920} cy={1100 - u * 1200} r={4 + random(`br${i}`) * 14} fill="none" stroke="#bfe9ff" strokeWidth={3} opacity={0.6 * (1 - u)} />;
        })}
      </svg>
      <Pop at={P[1]} style={{top: 260, left: 0, right: 0, flexDirection: 'column', gap: 26}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 18}}>
          <div style={{width: 90, height: 90, borderRadius: 26, background: `linear-gradient(135deg, ${C.accent}, ${C.hot} 60%, ${C.pink})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 66, color: '#0b0b14'}}>A</div>
          <Pill color="#fff" size={44}>
            HOY, EN APRENDE
          </Pill>
        </div>
        <Title size={84}>¿QUÉ PASARÍA SI BAJARAS A LA</Title>
        <Title size={140} color={C.accent}>
          FOSA DE LAS MARIANAS?
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 3. EL DESCENSO (de 0 a 10.900 m)
// =====================================================================
const DescentScene = () => {
  const t = useT();
  const d = depthAt(t);
  const lights = r(t, P[6] - 1, P[6] + 1, 0, 1);
  const between = (a, b) => t >= a && t < b;
  const swim = (a, b, x0, x1) => lin(t, a, b, x0, x1);

  return (
    <AbsoluteFill style={{background: waterAt(d)}}>
      <svg {...CANVAS}>
        {d < 300
          ? Array.from({length: 7}).map((_, i) => (
              <path key={i} d={`M${200 + i * 260} -20 L${120 + i * 260 + Math.sin(t + i) * 40} 1100 L${260 + i * 260 + Math.sin(t + i) * 40} 1100 Z`} fill="#fff" opacity={lin(d, 0, 300, 0.12, 0)} />
            ))
          : null}
        <Snow t={t} d={d} speed={1 + (d > 4000 ? 1.5 : 0)} />

        {/* Zona de luz */}
        {between(P[2], P[4]) ? <FishSchool t={t} cx={swim(P[2], P[4], 1500, 900)} cy={300} n={34} spread={240} /> : null}
        {between(Wa('rojo', P[2]) - 0.5, P[3]) ? (
          <g transform="translate(1250 680) scale(3)">
            <Fish x={0} y={0} t={t} color={lin(t, Wa('rojo', P[2]), Wa('marrón') + 0.3, 0, 1) < 1 ? `rgb(${Math.round(lin(t, Wa('rojo', P[2]), Wa('marrón') + 0.3, 230, 120))},${Math.round(lin(t, Wa('rojo', P[2]), Wa('marrón') + 0.3, 50, 80))},${Math.round(lin(t, Wa('rojo', P[2]), Wa('marrón') + 0.3, 50, 60))})` : '#784a3c'} />
          </g>
        ) : null}
        {between(P[3], P[4]) ? (
          <>
            <Diver x={swim(P[3], P[4], 1300, 1100)} y={380} s={1.4} t={t} />
            <Diver x={swim(P[3], P[4], 900, 760)} y={700} s={1.4} t={t} />
          </>
        ) : null}

        {/* Crepúsculo: migración y bioluminiscencia */}
        {between(P[4], P[5])
          ? Array.from({length: 120}).map((_, i) => {
              const x = 700 + random(`mg${i}`) * 1100;
              const y = ((random(`mh${i}`) * 1100 - (t - P[4]) * (120 + random(`mi${i}`) * 120)) % 1100 + 1100) % 1100;
              return <ellipse key={i} cx={x} cy={y} rx={6} ry={3} fill="#9fd8ff" opacity={0.6} />;
            })
          : null}
        {between(P[5], P[6]) ? (
          <>
            <Jelly x={1250} y={300} s={1.6} t={t} />
            <Jelly x={1550} y={600} s={1.1} t={t} color="#5ee7ff" />
            <Jelly x={980} y={760} s={0.9} t={t} color="#ff6ad5" />
            {[0, 1, 2, 3, 4].map((i) => (
              <GlowFish key={i} x={swim(P[5], P[6], 1900 - i * 80, 700 - i * 80)} y={420 + i * 70} s={1.4} t={t} color={i % 2 ? '#5ee7ff' : '#7fffd4'} />
            ))}
          </>
        ) : null}

        {/* Medianoche: cachalote y calamar gigante */}
        {between(P[7], P[8]) ? (
          <>
            <SpermWhale x={swim(P[7], Wa('calamar', P[7]), 2600, 1100)} y={320} s={1.2} t={t} />
            {t > Wa('calamar', P[7]) - 0.5 ? <GiantSquid x={swim(Wa('calamar', P[7]), P[8], 1700, 1300)} y={720} s={1.1} t={t} /> : null}
          </>
        ) : null}
        {between(P[8], P[9]) ? (
          <g opacity={t > Wa('desaparecen') + 0.4 ? lin(t, Wa('desaparecen') + 0.4, Wa('desaparecen') + 0.8, 1, 0) : 1}>
            <g opacity={t < Wa('rape') - 0.2 ? 0.25 : 1}>
              <Anglerfish x={1250} y={560} s={1.8} t={t} />
            </g>
            {t > Wa('desaparecen') - 0.6 ? <Fish x={swim(Wa('desaparecen') - 1.5, Wa('desaparecen'), 1700, 1400)} y={420} s={0.9} t={t} color="#9fd8ff" flip /> : null}
          </g>
        ) : null}
        {between(P[9], P[10]) ? (
          <>
            {t > Wa('víbora') - 0.3 ? <Viperfish x={swim(Wa('víbora'), P[10], 1400, 1100)} y={300} s={1.6} /> : null}
            {t > Wa('duende') - 0.3 ? (
              <GoblinShark x={swim(Wa('duende'), P[10], 2100, 1300)} y={620} s={1.2} t={t} jaw={t > Wa('resorte') - 0.3 && t < Wa('resorte') + 0.6 ? 1 : 0} />
            ) : null}
            {t > Wa('vampiro') - 0.3 ? <VampireSquid x={1550} y={860} s={1.2} t={t} umbrella={r(t, Wa('paraguas') - 0.2, Wa('paraguas') + 0.6, 0, 1, INOUT)} /> : null}
          </>
        ) : null}
        {between(P[10], P[11]) ? <Titanic x={swim(P[10], P[11], 1900, 1500)} y={900} s={1.3} /> : null}

        {/* Llanura abisal y chimeneas */}
        {t >= P[11] && t < P[13] ? (
          <path d={`M0 ${lin(t, P[11], P[11] + 3, 1200, 900)} Q500 ${lin(t, P[11], P[11] + 3, 1180, 880)} 960 ${lin(t, P[11], P[11] + 3, 1200, 900)} T1920 ${lin(t, P[11], P[11] + 3, 1190, 890)} L1920 1080 L0 1080 Z`} fill="#1a1612" />
        ) : null}
        {between(P[12], P[13]) ? <Vent x={1350} y={910} s={1.2} t={t} /> : null}

        {/* Zona hadal: paredes de la fosa */}
        {t >= P[13] ? (
          <>
            <path d={`M0 0 L${lin(t, P[13], P[13] + 4, 0, 380)} 0 L${lin(t, P[13], P[13] + 4, 0, 300)} 1080 L0 1080 Z`} fill="#0b0906" />
            <path d={`M1920 0 L${lin(t, P[13], P[13] + 4, 1920, 1560)} 0 L${lin(t, P[13], P[13] + 4, 1920, 1640)} 1080 L1920 1080 Z`} fill="#0b0906" />
          </>
        ) : null}
        {between(Wa('caracol') - 1, P[15]) ? <Snailfish x={swim(Wa('caracol') - 1, P[15], 1450, 1150)} y={620} s={1.6} t={t} /> : null}

        <Submarine x={480} y={520} s={0.9} t={t} lights={lights} />
        <Gauge d={d} />
      </svg>

      {/* Indicador digital */}
      <div style={{position: 'absolute', top: 140, left: 60, fontFamily: FONT, background: 'rgba(4,10,24,0.6)', borderRadius: 20, padding: '10px 22px'}}>
        <div style={{fontSize: 22, fontWeight: 800, color: '#9fd8ff'}}>PROFUNDIDAD</div>
        <div style={{fontFamily: 'JetBrains Mono, monospace', fontSize: 64, fontWeight: 800, color: '#fff'}}>−{fmt(d)} m</div>
        <div style={{fontSize: 24, fontWeight: 800, color: C.accent}}>PRESIÓN ×{fmt(1 + d / 10)}</div>
      </div>

      {/* Rótulos */}
      <Pop at={Wa('rojo', P[2]) - 0.1} out={P[3] - 0.2} style={{top: 560, left: 1050}}>
        <Pill color={C.red} text="#fff" size={40}>
          EL ROJO DESAPARECE A ~10 m
        </Pill>
      </Pop>
      <Pop at={Wa('apnea') - 0.1} out={P[4] - 0.2} style={{top: 360, left: 760}}>
        <Card>
          APNEA: <span style={{color: C.accent}}>+200 m</span>
        </Card>
      </Pop>
      <Pop at={Wa('botellas') - 0.1} out={P[4] - 0.2} style={{top: 470, left: 760}}>
        <Card border="#5ec8ff">
          CON BOTELLAS: <span style={{color: '#5ec8ff'}}>~330 m</span>
        </Card>
      </Pop>
      <Pop at={Wa('migración') - 0.1} out={P[5] - 0.2} style={{top: 330, left: 880}}>
        <Card border="#9fd8ff" style={{fontSize: 46}}>
          LA MAYOR MIGRACIÓN DEL PLANETA
        </Card>
      </Pop>
      <Pop at={Wa('tres', P[5]) - 0.1} out={P[6] - 0.2} style={{top: 160, left: 720}}>
        <Title size={84} color="#7fffd4">
          3 DE CADA 4 BRILLAN
        </Title>
      </Pop>
      <Pop at={P[6] + 1} out={P[7] - 0.2} style={{top: 330, left: 820}}>
        <Card border="#fff" style={{fontSize: 44, textAlign: 'center'}}>
          SIN LUZ SOLAR · 4 °C
          <br />
          <span style={{color: C.accent}}>PRESIÓN ×100</span>
        </Card>
      </Pop>
      <Pop at={Wa('cachalote', P[7]) - 0.1} out={Wa('calamar', P[7]) - 0.3} style={{top: 560, left: 760}}>
        <Card border="#9aa3b8" style={{fontSize: 40}}>
          CACHALOTE · +2.000 m · +1 HORA SIN RESPIRAR
        </Card>
      </Pop>
      <Pop at={Wa('calamar', P[7]) - 0.1} out={P[8] - 0.2} style={{top: 180, left: 820}}>
        <Card border={C.red} style={{fontSize: 42}}>
          CALAMAR GIGANTE · HASTA <span style={{color: C.red}}>13 m</span>
        </Card>
      </Pop>
      <Pop at={Wa('rape') - 0.1} out={P[9] - 0.2} style={{top: 180, left: 760}}>
        <Pill color="#7fffd4" size={44}>
          RAPE ABISAL
        </Pill>
      </Pop>
      {[
        ['víbora', 'PEZ VÍBORA', 180, 1050, '#5ee7ff'],
        ['duende', 'TIBURÓN DUENDE', 460, 1300, '#e8a3a3'],
        ['vampiro', 'CALAMAR VAMPIRO', 700, 1340, '#ff6ad5'],
      ].map(([w, label, top, left, col]) => (
        <Pop key={w} at={Wa(w) - 0.1} out={P[10] - 0.2} style={{top, left}}>
          <Pill color={col} size={36}>
            {label}
          </Pill>
        </Pop>
      ))}
      <Pop at={Wa('titanic') - 0.1} out={P[11] - 0.2} style={{top: 260, left: 1050}}>
        <Title size={80}>
          TITANIC · <span style={{color: C.accent}}>3.800 m</span>
        </Title>
      </Pop>
      <Pop at={Wa('nieve', P[11]) - 0.1} out={P[12] - 0.2} style={{top: 260, left: 860}}>
        <Title size={90} color="#e8f6ff">
          NIEVE MARINA
        </Title>
      </Pop>
      <Pop at={Wa('cuatrocientos') - 0.1} out={P[13] - 0.2} style={{top: 200, left: 760, flexDirection: 'column', gap: 12, alignItems: 'flex-start'}}>
        <Card border={C.hot} style={{fontSize: 46}}>
          AGUA A <span style={{color: C.hot}}>+400 °C</span> SIN HERVIR
        </Card>
        {t > Wa('sol', P[12]) - 0.2 ? (
          <Card border={C.green} style={{fontSize: 40}}>
            VIDA SIN SOL · DESCUBIERTA EN 1977
          </Card>
        ) : null}
      </Pop>
      <Pop at={Wa('hadal') - 0.1} out={P[14] - 0.2} style={{top: 260, left: 0, right: 0}}>
        <Title size={100}>
          ZONA <span style={{color: C.red}}>HADAL</span>
        </Title>
      </Pop>
      <Pop at={Wa('caracol') - 0.1} out={P[15] - 0.2} style={{top: 280, left: 760}}>
        <Card border="#f2d6e0" style={{fontSize: 44}}>
          PEZ CARACOL · <span style={{color: '#f2d6e0'}}>+8.000 m</span>
        </Card>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 4. EL FONDO: Everest y presión
// =====================================================================
const BottomScene = () => {
  const t = useT();
  const pressure = t >= P[16];
  const SCALE = 0.07; // px por metro
  const SURF = 120;
  const yOf = (m) => SURF + m * SCALE;
  const ev = r(t, Wa('everest') - 0.2, Wa('everest') + 1.2, 0, 1, INOUT);
  return (
    <AbsoluteFill style={{background: pressure ? 'radial-gradient(circle, #1a0a12, #010409)' : 'linear-gradient(#0d4f8f, #010409 70%)'}}>
      {!pressure ? (
        <>
          <svg {...CANVAS}>
            <rect x={0} y={0} width={1920} height={SURF} fill="#8fd0ff" />
            <line x1={0} x2={1920} y1={SURF} y2={SURF} stroke="#e8f6ff" strokeWidth={6} />
            <path d={`M0 ${yOf(3000)} L600 ${yOf(4000)} L820 ${yOf(10900)} L1100 ${yOf(10900)} L1320 ${yOf(5000)} L1920 ${yOf(3500)} L1920 1080 L0 1080 Z`} fill="#1a1612" />
            {/* Everest dentro de la fosa */}
            <g opacity={ev}>
              <path d={`M720 ${yOf(10900)} L960 ${yOf(10900) - 8849 * SCALE * ev} L1200 ${yOf(10900)} Z`} fill="#9aa3b8" stroke="#fff" strokeWidth={4} />
              <path d={`M960 ${yOf(10900) - 8849 * SCALE * ev} l-40 60 l40 -14 l40 14 Z`} fill="#fff" />
            </g>
            <line x1={1240} x2={1240} y1={SURF} y2={yOf(10900) - 8849 * SCALE * ev} stroke={C.accent} strokeWidth={6} strokeDasharray="14 10" opacity={ev} />
          </svg>
          <Pop at={P[15] + 0.6} style={{top: 150, left: 60}}>
            <Card style={{fontSize: 46}}>
              −10.900 m · <span style={{color: C.accent}}>EL PUNTO MÁS PROFUNDO</span>
            </Card>
          </Pop>
          <Pop at={Wa('everest') + 0.6} style={{top: 140, left: 1270}}>
            <Card border={C.accent} style={{fontSize: 44}}>
              LA CIMA DEL EVEREST, A
              <br />
              <span style={{color: C.accent}}>+2 km BAJO EL AGUA</span>
            </Card>
          </Pop>
        </>
      ) : (
        <>
          <svg {...CANVAS}>
            <g transform="translate(700 620)">
              <rect x={-60} y={0} width={120} height={300} rx={50} fill="#e8b48c" />
              <rect x={-44} y={14} width={88} height={60} rx={20} fill="#f6d7c3" />
              <g transform={`translate(0 ${-30 - Math.abs(Math.sin(t * 2)) * 10})`}>
                <path d="M-170 0 L-150 -70 L-90 -110 L90 -110 L150 -70 L170 0 Z" fill={C.red} stroke="#05060f" strokeWidth={6} />
                <rect x={-80} y={-100} width={70} height={36} rx={6} fill="#9ed6ff" />
                <rect x={10} y={-100} width={70} height={36} rx={6} fill="#9ed6ff" />
                <circle cx={-110} cy={0} r={34} fill="#1a1a1a" />
                <circle cx={110} cy={0} r={34} fill="#1a1a1a" />
              </g>
            </g>
          </svg>
          <Pop at={P[16] + 0.2} style={{top: 260, left: 960}}>
            <Title size={180} color={C.accent}>
              ×1.000
            </Title>
          </Pop>
          <Pop at={Wa('coche', P[16]) - 0.1} style={{top: 520, left: 980}}>
            <Card border={C.red} style={{fontSize: 50}}>
              = UN COCHE EN CADA cm²
              <br />
              <span style={{fontSize: 36, color: '#b9c3dd'}}>DE TU CUERPO</span>
            </Card>
          </Pop>
        </>
      )}
    </AbsoluteFill>
  );
};

// =====================================================================
// 5. ¿Y SI EL SUBMARINO FALLARA?
// =====================================================================
const ImplosionScene = () => {
  const t = useT();
  const crack = Wa('crujido');
  const boom = Wa('implosionaría');
  const sphere = Wa('esfera');
  const weights = Wa('pesos');
  const alarm = t > crack && t < boom + 1 ? (Math.sin(t * 14) > 0 ? 0.35 : 0) : 0;
  const flash = t > boom && t < boom + 0.8 ? lin(t, boom, boom + 0.8, 1, 0) : 0;
  const rise = r(t, weights + 1, P[18] - 0.5, 0, 1, INOUT);
  const showSub = t < boom || t > sphere - 0.5;
  return (
    <AbsoluteFill style={{background: '#010409'}}>
      <svg {...CANVAS}>
        {showSub ? (
          <g transform={`translate(0 ${-rise * 500})`}>
            <Submarine x={960} y={560} s={2} t={t} lights={1} />
            {t > crack && t < boom
              ? [0, 1, 2].map((i) => (
                  <path key={i} d={`M${880 + i * 60} ${450 + i * 20} l20 30 l-14 20 l24 34`} fill="none" stroke="#0b0b14" strokeWidth={6} opacity={lin(t, crack + i * 0.4, crack + i * 0.4 + 0.2, 0, 1)} />
                ))
              : null}
            {t > weights - 0.2 ? (
              <g transform={`translate(0 ${r(t, weights, weights + 1.2, 0, 600, (x) => x * x)})`}>
                <rect x={860} y={760} width={70} height={50} rx={6} fill="#5a6478" />
                <rect x={1000} y={760} width={70} height={50} rx={6} fill="#5a6478" />
              </g>
            ) : null}
          </g>
        ) : (
          <g>
            {Array.from({length: 26}).map((_, i) => {
              const a = (i / 26) * Math.PI * 2;
              const k = r(t, boom, boom + 0.25, 1, 0);
              return <line key={i} x1={960 + Math.cos(a) * 420 * k} y1={560 + Math.sin(a) * 420 * k} x2={960 + Math.cos(a) * (420 * k + 60)} y2={560 + Math.sin(a) * (420 * k + 60)} stroke="#f2c94c" strokeWidth={10} />;
            })}
          </g>
        )}
        {t > sphere - 0.3 && t < weights - 0.3 ? (
          <g transform="translate(1500 520)">
            <circle r={150} fill="none" stroke={C.accent} strokeWidth={14} />
            {Array.from({length: 12}).map((_, i) => {
              const a = (i / 12) * Math.PI * 2;
              return (
                <g key={i} transform={`rotate(${(a * 180) / Math.PI})`}>
                  <line x1={260} x2={170} y1={0} y2={0} stroke="#9fd8ff" strokeWidth={8} />
                  <path d="M180 -14 L160 0 L180 14" fill="none" stroke="#9fd8ff" strokeWidth={8} />
                </g>
              );
            })}
          </g>
        ) : null}
      </svg>
      {alarm ? <AbsoluteFill style={{background: C.red, opacity: alarm}} /> : null}
      {flash ? <AbsoluteFill style={{background: '#fff', opacity: flash}} /> : null}
      <Pop at={P[17] + 0.4} out={boom - 0.2} style={{top: 140, left: 0, right: 0}}>
        <Title size={100} color={C.red}>
          ¿Y SI FALLARA?
        </Title>
      </Pop>
      <Pop at={boom + 0.3} out={sphere - 0.4} style={{top: 400, left: 0, right: 0, flexDirection: 'column'}}>
        <Title size={130} color={C.red}>
          IMPLOSIÓN
        </Title>
        <Title size={70}>EN MILÉSIMAS DE SEGUNDO</Title>
      </Pop>
      <Pop at={sphere - 0.2} out={weights - 0.3} style={{top: 140, left: 1200}}>
        <Card style={{fontSize: 44}}>LA ESFERA REPARTE LA PRESIÓN</Card>
      </Pop>
      <Pop at={weights} style={{top: 140, left: 0, right: 0}}>
        <Title size={84} color={C.green}>
          SUELTA LOS PESOS… Y A SUBIR
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 6. VIDA Y PLÁSTICO EN EL FONDO
// =====================================================================
const LifeScene = () => {
  const t = useT();
  const plastic = Wa('plástico', P[18]);
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#02060f, #0b0906)'}}>
      <svg {...CANVAS}>
        <path d="M0 860 Q480 820 960 860 T1920 850 L1920 1080 L0 1080 Z" fill="#1a1612" />
        <ellipse cx={960} cy={700} rx={700} ry={300} fill="#fff8d0" opacity={0.05} />
        {Array.from({length: 10}).map((_, i) => (
          <Amphipod key={i} x={((random(`am${i}`) * 1800 + t * (20 + i * 4)) % 1900)} y={840 + (i % 3) * 30} s={1 + (i % 2) * 0.4} t={t} />
        ))}
        {t > plastic - 0.5 ? <PlasticBag x={lin(t, plastic - 0.5, P[19], 1500, 1150)} y={560} s={1.8} t={t} /> : null}
      </svg>
      <Pop at={P[18] + 0.5} out={plastic - 0.4} style={{top: 160, left: 0, right: 0}}>
        <Title size={90}>Y AUN ASÍ… HAY VIDA</Title>
      </Pop>
      <Pop at={plastic - 0.1} style={{top: 160, left: 0, right: 0}}>
        <Title size={90} color={C.red}>
          PLÁSTICO EN EL PUNTO MÁS PROFUNDO
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 7. LOS PRIMEROS EN BAJAR
// =====================================================================
const HistoryScene = () => {
  const t = useT();
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#0d4f8f, #02060f)'}}>
      <svg {...CANVAS}>
        <Snow t={t} d={3000} />
        <Trieste x={620} y={lin(t, P[19], P[20], 380, 640)} s={1.1} t={t} />
      </svg>
      <div style={{position: 'absolute', top: 220, right: 120, display: 'flex', flexDirection: 'column', gap: 24}}>
        <div style={{scale: String(r(t, Wa('sesenta', P[19]) - 0.3, Wa('sesenta', P[19]) + 0.1, 0, 1, BACK))}}>
          <Card style={{fontSize: 44}}>
            <span style={{color: C.accent}}>1960</span> · TRIESTE
            <div style={{fontSize: 32, color: '#b9c3dd'}}>~5 h BAJANDO · ~20 min EN EL FONDO</div>
          </Card>
        </div>
        <div style={{scale: String(r(t, Wa('cameron') - 0.3, Wa('cameron') + 0.1, 0, 1, BACK))}}>
          <Card border="#5ec8ff" style={{fontSize: 44}}>
            <span style={{color: '#5ec8ff'}}>2012</span> · JAMES CAMERON
            <div style={{fontSize: 32, color: '#b9c3dd'}}>EN SOLITARIO</div>
          </Card>
        </div>
      </div>
    </AbsoluteFill>
  );
};

// =====================================================================
// 8. LO QUE AÚN NO SABEMOS
// =====================================================================
const UnknownScene = () => {
  const t = useT();
  const eyes = Wa('mirando', P[20]);
  const dark = t > Wa('oscuridad', P[20]) - 0.3;
  return (
    <AbsoluteFill style={{background: dark ? '#010409' : 'linear-gradient(#141a3a, #02060f)'}}>
      <svg {...CANVAS}>
        {!dark ? (
          <>
            <circle cx={560} cy={480} r={230} fill="#c9ccd6" />
            {[[-60, -40, 40], [70, 50, 30], [-20, 90, 22], [90, -80, 18]].map(([dx, dy, rr], i) => (
              <circle key={i} cx={560 + dx} cy={480 + dy} r={rr} fill="#a9adba" />
            ))}
            <rect x={1130} y={250} width={460} height={460} rx={30} fill="#06183a" stroke="#5ec8ff" strokeWidth={6} />
            {Array.from({length: 36}).map((_, i) => (
              <text key={i} x={1170 + (i % 6) * 75} y={300 + Math.floor(i / 6) * 75} fontFamily={FONT} fontWeight={900} fontSize={40} fill="#5ec8ff" opacity={i % 7 === 0 ? 1 : 0.35}>
                ?
              </text>
            ))}
          </>
        ) : (
          Array.from({length: 14}).map((_, i) => {
            const x = 200 + random(`ex${i}`) * 1520;
            const y = 200 + random(`ey${i}`) * 560;
            const o = lin(t, eyes - 1 + i * 0.12, eyes - 0.6 + i * 0.12, 0, 1) * (Math.sin(t * 2 + i * 3) > -0.92 ? 1 : 0.05);
            return (
              <g key={i} opacity={o}>
                <ellipse cx={x - 18} cy={y} rx={10} ry={7} fill="#c8ffef" style={{filter: 'drop-shadow(0 0 12px #7fffd4)'}} />
                <ellipse cx={x + 18} cy={y} rx={10} ry={7} fill="#c8ffef" style={{filter: 'drop-shadow(0 0 12px #7fffd4)'}} />
              </g>
            );
          })
        )}
      </svg>
      {!dark ? (
        <>
          <Pop at={Wa('luna', P[20]) - 0.1} style={{top: 760, left: 380}}>
            <Pill color="#c9ccd6" size={40}>
              LA LUNA: MAPEADA
            </Pill>
          </Pop>
          <Pop at={Wa('fondo', P[20]) - 0.1} style={{top: 760, left: 1150}}>
            <Pill color="#5ec8ff" size={40}>
              EL FONDO DEL MAR: ¿?
            </Pill>
          </Pop>
        </>
      ) : null}
    </AbsoluteFill>
  );
};

// =====================================================================
// 9. CIERRE Y PANTALLA FINAL
// =====================================================================
const PLACES = ['EL ESPACIO', 'UN VOLCÁN', 'LA ANTÁRTIDA', 'EL CENTRO DE LA TIERRA'];

const OutroScene = () => {
  const t = useT();
  const tapAt = Wa('suscríbete') + 0.5;
  const tapped = t > tapAt;
  const tap = t > tapAt - 0.15 && t < tapAt + 0.15 ? 0.9 : 1;
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 40%, #0d4f8f, #010409)'}}>
      <Pop at={P[21]} style={{top: 150, left: 0, right: 0, flexDirection: 'column'}}>
        <div style={{width: 150, height: 150, borderRadius: 44, background: `linear-gradient(135deg, ${C.accent}, ${C.hot} 60%, ${C.pink})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 110, color: '#0b0b14'}}>A</div>
        <div style={{marginTop: 20, display: 'flex', alignItems: 'center', gap: 16, padding: '20px 60px', borderRadius: 60, background: tapped ? 'rgba(255,255,255,0.2)' : '#e62117', fontFamily: FONT, fontWeight: 900, fontSize: 56, color: '#fff', scale: String(tap)}}>
          {tapped ? <Check size={56} /> : null}
          {tapped ? 'SUSCRITO' : 'SUSCRIBIRSE'}
        </div>
      </Pop>
      <Pop at={Wa('dónde', P[21]) - 0.2} style={{top: 560, left: 0, right: 0, flexDirection: 'column', gap: 24}}>
        <Title size={72}>¿A DÓNDE VIAJAMOS EN EL PRÓXIMO VÍDEO?</Title>
        <div style={{display: 'flex', gap: 20}}>
          {PLACES.map((p, i) => (
            <div key={p} style={{scale: String(r(t, Wa('dónde', P[21]) + i * 0.2, Wa('dónde', P[21]) + i * 0.2 + 0.4, 0, 1, BACK))}}>
              <Pill color={[C.cyan, C.hot, '#fff', C.accent][i]} size={40}>
                {p}
              </Pill>
            </div>
          ))}
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

const EndScreen = () => {
  const t = useT();
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 40%, #0d4f8f, #010409)'}}>
      <svg {...CANVAS}>
        <Snow t={t} d={2000} />
      </svg>
      <div style={{position: 'absolute', top: 110, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Title size={70}>¿SIGUES CON GANAS DE MÁS?</Title>
      </div>
      {/* Huecos para los elementos de pantalla final de YouTube */}
      <div style={{position: 'absolute', top: 300, left: 200, width: 820, height: 461, borderRadius: 20, border: '6px dashed rgba(255,255,255,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 48, color: 'rgba(255,255,255,0.7)'}}>MIRA ESTE VÍDEO</div>
      <div style={{position: 'absolute', top: 340, left: 1240, width: 380, height: 380, borderRadius: '50%', border: '6px dashed rgba(255,255,255,0.5)', display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 44, color: 'rgba(255,255,255,0.7)', textAlign: 'center'}}>SUSCRÍBETE</div>
    </AbsoluteFill>
  );
};

const CHAPTERS = [
  [2, 'ZONA DE LUZ · 0 m'],
  [4, 'ZONA DEL CREPÚSCULO · 200 m'],
  [6, 'ZONA DE MEDIANOCHE · 1.000 m'],
  [11, 'ZONA ABISAL · 4.000 m'],
  [13, 'ZONA HADAL · 6.000 m'],
  [15, 'EL FONDO · 10.900 m'],
  [17, '¿Y SI FALLARA?'],
  [20, 'LO QUE AÚN NO SABEMOS'],
];

// =====================================================================
export const Fosa = () => (
  <AbsoluteFill style={{backgroundColor: '#010409'}}>
    <Scene name="Gancho" start={0} end={P[1]} fadeOut={false}>
      <HookScene />
    </Scene>
    <Scene name="Firma" start={P[1]} end={P[2]}>
      <BrandSting />
    </Scene>
    <Scene name="Descenso" start={P[2]} end={P[15]}>
      <DescentScene />
    </Scene>
    <Scene name="El fondo" start={P[15]} end={P[17]}>
      <BottomScene />
    </Scene>
    <Scene name="¿Y si fallara?" start={P[17]} end={P[18]}>
      <ImplosionScene />
    </Scene>
    <Scene name="Vida y plástico" start={P[18]} end={P[19]}>
      <LifeScene />
    </Scene>
    <Scene name="Los primeros" start={P[19]} end={P[20]}>
      <HistoryScene />
    </Scene>
    <Scene name="Lo desconocido" start={P[20]} end={P[21]}>
      <UnknownScene />
    </Scene>
    <Scene name="Cierre" start={P[21]} end={VOICE_END + 1}>
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
    <Brand hideAt={P[21]} pos={{top: 30, right: 40}} />
    <ProgressBar />
    <Captions chunks={CHUNKS} top={890} width={1600} fontSize={60} />
    <Audio src={staticFile('yt-fosa.mp3')} />
  </AbsoluteFill>
);
