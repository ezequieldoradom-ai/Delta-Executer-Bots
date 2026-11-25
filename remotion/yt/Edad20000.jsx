import React from 'react';
import {AbsoluteFill, random, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, Scene, lin, r, useT} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, Check, ProgressBar} from '../tunel/Visuals';
import {makeWa} from '../civilizacion/words';
import {CaveBison, CaveLion, Fire, GiantDeer, Human, LaurelPoint, Mammoth, Tundra, Wolf, WoollyRhino} from './Prehistoria';
import WORDS from '../../public/yt-20000.words.json';
import PARAS from '../../public/yt-20000.paras.json';

const Wa = makeWa(WORDS);
const P = PARAS;
export const DURATION = WORDS[WORDS.length - 1].end + 1.5;
const ICE = '#cfe8ff';

const CHUNKS = chunkWords(
  WORDS,
  [
    'frío', 'mamuts', 'veinte', 'mil', 'años', 'sobrevivirías', 'valioso', 'hielo', 'glacial', 'seis', 'grados',
    'congelador', 'kilómetros', 'eiffel', 'metros', 'doggerland', 'beringia', 'estepa', 'gigantes', 'mamut',
    'rinocerontes', 'ciervos', 'leones', 'lobos', 'dientes', 'sable', 'jabón', 'hipotermia', 'refugio', 'fuego',
    'agua', 'mechero', 'sílex', 'pirita', 'humanos', 'neandertales', 'cerebro', 'millones', 'solutrenses',
    'laurel', 'hueso', 'cuevas', 'idioma', 'confianza', 'agricultura', 'vía', 'láctea', 'antibióticos',
    'historia', 'dióxido', 'carbono', 'metal', 'gérmenes', 'superpoder', 'antepasados', 'suscríbete', 'aprende',
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
  <div style={{background: 'rgba(8,12,30,0.88)', border: `4px solid ${border}`, borderRadius: 28, padding: '18px 28px', fontFamily: FONT, color: '#fff', ...style}}>{children}</div>
);

const Cross = ({s = 1, color = C.red}) => (
  <svg width={160 * s} height={160 * s} viewBox="-80 -80 160 160">
    <path d="M-60 -60 L60 60 M60 -60 L-60 60" stroke={color} strokeWidth={22} strokeLinecap="round" />
  </svg>
);

// =====================================================================
// CAPÍTULOS
// =====================================================================
const CHAPTERS = [
  [1, 1, '¿DÓNDE ESTÁS?'],
  [2, 5, 'LOS GIGANTES'],
  [3, 7, 'LAS PRIMERAS 24 HORAS'],
  [4, 9, 'LOS OTROS HUMANOS'],
  [5, 13, 'TU NUEVA VIDA'],
  [6, 16, '¿PODRÍAS CAMBIAR LA HISTORIA?'],
  [7, 19, 'TU SUPERPODER'],
  [8, 22, 'LO QUE VINO DESPUÉS'],
];

const ChapterBanner = ({n, title}) => {
  const t = useT();
  const at = P[CHAPTERS.find((c) => c[0] === n)[1]];
  const k = Math.min(r(t, at, at + 0.5, 0, 1, INOUT), r(t, at + 2.6, at + 3.1, 1, 0, INOUT));
  return (
    <div style={{position: 'absolute', top: 30, left: 0, translate: `${(k - 1) * 900}px 0`, display: 'flex', alignItems: 'stretch', fontFamily: FONT, boxShadow: '0 20px 60px rgba(0,0,0,0.5)'}}>
      <div style={{background: C.accent, color: '#0b0b14', fontWeight: 900, fontSize: 34, padding: '18px 26px', display: 'flex', alignItems: 'center'}}>CAPÍTULO {n}</div>
      <div style={{background: 'rgba(8,12,30,0.92)', color: '#fff', fontWeight: 900, fontSize: 52, padding: '14px 40px 14px 30px'}}>{title}</div>
    </div>
  );
};

// =====================================================================
// 1. GANCHO
// =====================================================================
const HookScene = () => {
  const t = useT();
  const open = r(t, 0.3, 2.2, 0, 1, INOUT);
  const herd = lin(t, Wa('manada') - 1, P[1], -300, 900);
  const titleAt = Wa('planeta', 25) + 0.3;
  return (
    <AbsoluteFill>
      <svg {...CANVAS}>
        <Tundra t={t} pan={t * 30} snow={1.4} />
        {[0, 1, 2, 3].map((k) => (
          <Mammoth key={k} x={herd + k * 210 - (k % 2) * 60} y={760 + (k % 2) * 14} s={0.42 - (k % 2) * 0.06} t={t} walk={1} />
        ))}
        {/* Vaho del aliento */}
        {t > 2 && t < 9
          ? [0, 1, 2].map((k) => {
              const u = ((t - 2) * 0.7 + k / 3) % 1;
              return <circle key={k} cx={960 + u * 120} cy={980 - u * 90} r={30 + u * 70} fill="#fff" opacity={0.35 * (1 - u)} />;
            })
          : null}
      </svg>
      {/* Párpados que se abren */}
      <div style={{position: 'absolute', left: 0, right: 0, top: 0, height: 540 * (1 - open), background: '#000', borderRadius: '0 0 50% 50% / 0 0 30% 30%'}} />
      <div style={{position: 'absolute', left: 0, right: 0, bottom: 0, height: 540 * (1 - open), background: '#000', borderRadius: '50% 50% 0 0 / 30% 30% 0 0'}} />
      <AbsoluteFill style={{backdropFilter: `blur(${(1 - open) * 12}px)`, pointerEvents: 'none'}} />
      <Pop at={Wa('veinte')} out={Wa('sobrevivirías') - 0.2} style={{top: 260, left: 0, right: 0}}>
        <Title size={150} color={ICE}>
          HACE 20.000 AÑOS
        </Title>
      </Pop>
      <Pop at={Wa('sobrevivirías') - 0.05} out={Wa('quédate') - 0.2} style={{top: 280, left: 0, right: 0}}>
        <Title size={150} color={C.accent}>
          ¿SOBREVIVIRÍAS?
        </Title>
      </Pop>
      <Pop at={Wa('única', Wa('quédate')) - 0.05} out={titleAt - 0.2} style={{top: 300, left: 0, right: 0}}>
        <Card border={C.accent} style={{fontSize: 56, fontWeight: 900, textAlign: 'center'}}>
          LA ÚNICA COSA QUE TE HARÍA
          <br />
          <span style={{color: C.accent}}>EL HUMANO MÁS VALIOSO DEL PLANETA</span>
        </Card>
      </Pop>
      <Pop at={titleAt} style={{top: 200, left: 0, right: 0, flexDirection: 'column'}}>
        <Title size={70}>¿QUÉ PASARÍA SI</Title>
        <Title size={120} color={C.accent}>
          DESPERTARAS HACE
          <br />
          20.000 AÑOS?
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 2. ¿DÓNDE ESTÁS? (máquina del tiempo)
// =====================================================================
const WhereScene = () => {
  const t = useT();
  const k = r(t, P[1] + 1.2, Wa('glacial') - 0.5, 0, 1, INOUT);
  const year = Math.round(2026 - k * (2026 + 18000));
  const label = year >= 0 ? `AÑO ${year}` : `${String(-year).replace(/\B(?=(\d{3})+(?!\d))/g, '.')} a. C.`;
  const frost = r(t, Wa('hielo'), Wa('hielo') + 1.5, 0, 1);
  return (
    <AbsoluteFill style={{background: `linear-gradient(${frost > 0.5 ? '#0c2a4a' : '#0a0626'}, ${frost > 0.5 ? '#5b8fbf' : '#2a1a5a'})`}}>
      <svg {...CANVAS}>
        {Array.from({length: 12}).map((_, i) => (
          <circle key={i} cx={960} cy={540} r={60 + i * 70} fill="none" stroke={frost > 0.5 ? ICE : '#b46cff'} strokeWidth={4} strokeDasharray="30 40" opacity={0.5 - i * 0.03} transform={`rotate(${(i % 2 ? -1 : 1) * t * (40 + i * 8) * (1 - k * 0.5)} 960 540)`} />
        ))}
        {frost > 0
          ? Array.from({length: 40}).map((_, i) => (
              <path key={i} d={`M${random(`fr${i}`) * 1920} ${random(`fy${i}`) * 1080} l12 0 m-6 -6 l0 12 m-4 -4 l8 8 m0 -8 l-8 8`} stroke="#fff" strokeWidth={2} opacity={frost * 0.6} />
            ))
          : null}
      </svg>
      <div style={{position: 'absolute', top: 330, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <div style={{fontFamily: 'JetBrains Mono, monospace', fontWeight: 800, fontSize: 150, color: '#fff', textShadow: `0 0 40px ${frost > 0.5 ? ICE : '#b46cff'}`, filter: `blur(${k > 0.05 && k < 0.95 ? 2 : 0}px)`}}>{label}</div>
      </div>
      <Pop at={Wa('glacial') - 0.3} style={{top: 560, left: 0, right: 0, flexDirection: 'column'}}>
        <Title size={90} color={ICE}>
          ÚLTIMO MÁXIMO GLACIAL
        </Title>
        <div style={{marginTop: 14}}>
          <Pill color="#fff" size={40}>
            EL MOMENTO MÁS FRÍO DE LOS ÚLTIMOS 100.000 AÑOS
          </Pill>
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 3. EL FRÍO Y EL HIELO
// =====================================================================
const Eiffel = ({x, y, s = 1}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <path d="M-40 0 L-8 -100 L-4 -150 L0 -170 L4 -150 L8 -100 L40 0 L26 0 L10 -40 L-10 -40 L-26 0 Z" fill="#7d6a52" />
    <rect x={-22} y={-62} width={44} height={6} fill="#7d6a52" />
    <rect x={-12} y={-104} width={24} height={5} fill="#7d6a52" />
  </g>
);

const ColdScene = () => {
  const t = useT();
  const temp = r(t, Wa('seis', P[2]), Wa('seis', P[2]) + 1.2, 15, 9);
  const iceAt = Wa('enterrados', P[2]);
  const ice = r(t, iceAt, iceAt + 2.5, 0, 1, INOUT);
  const towers = Wa('nueve', P[2]);
  const thermo = t < iceAt - 0.2;
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#5b8fbf, #dbe9f5)'}}>
      <svg {...CANVAS}>
        {thermo ? (
          <g transform="translate(560 140)">
            <rect x={-40} y={0} width={80} height={560} rx={40} fill="rgba(255,255,255,0.6)" stroke="#fff" strokeWidth={8} />
            <rect x={-22} y={20 + (1 - (temp + 10) / 40) * 520} width={44} height={(temp + 10) / 40 * 520} rx={22} fill={temp > 12 ? C.red : '#5ec8ff'} />
            <circle cx={0} cy={600} r={70} fill={temp > 12 ? C.red : '#5ec8ff'} stroke="#fff" strokeWidth={8} />
          </g>
        ) : (
          <g>
            <rect x={0} y={900} width={1920} height={180} fill="#9aa3b8" />
            {/* Capa de hielo de 3 km */}
            <path d={`M0 900 L0 ${900 - 620 * ice} Q500 ${880 - 700 * ice} 1100 ${900 - 560 * ice} L1300 900 Z`} fill={ICE} stroke="#fff" strokeWidth={6} />
            {Array.from({length: 8}).map((_, i) => (
              <path key={i} d={`M${100 + i * 130} ${900 - (120 + (i % 3) * 90) * ice} l40 20`} stroke="#9ec9f0" strokeWidth={5} opacity={ice} />
            ))}
            <line x1={1180} y1={900} x2={1180} y2={900 - 620 * ice} stroke={C.accent} strokeWidth={6} strokeDasharray="16 10" />
            {t > towers - 0.1
              ? Array.from({length: 9}).map((_, i) => {
                  const s = r(t, towers + i * 0.12, towers + i * 0.12 + 0.3, 0, 1, BACK);
                  return <Eiffel key={i} x={1460} y={900 - i * 69} s={0.4 * s} />;
                })
              : null}
            <Human x={1640} y={900} s={0.35} t={t} />
          </g>
        )}
      </svg>
      {thermo ? (
        <>
          <Pop at={Wa('seis', P[2]) - 0.05} style={{top: 260, left: 760}}>
            <Title size={200} color="#1a5fa8">
              −6 °C
            </Title>
          </Pop>
          <Pop at={Wa('congelador', P[2]) - 0.05} style={{top: 520, left: 760}}>
            <Pill color="#fff" size={48}>
              = UN CONGELADOR GIGANTE
            </Pill>
          </Pop>
        </>
      ) : (
        <>
          <Pop at={iceAt + 0.3} style={{top: 140, left: 80}}>
            <Card border={ICE} style={{fontSize: 48, fontWeight: 900}}>
              HIELO DE HASTA <span style={{color: '#5ec8ff'}}>3 KM</span> DE GROSOR
            </Card>
          </Pop>
          <Pop at={towers} style={{top: 140, left: 1270}}>
            <Pill color={C.accent} size={40}>
              = 9 TORRES EIFFEL
            </Pill>
          </Pop>
        </>
      )}
    </AbsoluteFill>
  );
};

// =====================================================================
// 4. EL MAR, 120 METROS MÁS BAJO
// =====================================================================
const SeaScene = () => {
  const t = useT();
  const drop = r(t, P[3] + 1, Wa('metros', P[3]) + 1, 0, 1, INOUT);
  const bering = t > Wa('beringia') - 2.5;
  const level = 520 + drop * 170;
  const walkerK = lin(t, Wa('andando', P[3]), Wa('andando', P[3]) + 6, 0, 1);
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#9fc3e6, #dbe9f5 60%)'}}>
      <svg {...CANVAS}>
        <rect x={0} y={level} width={1920} height={1080 - level} fill="#2f7fd1" opacity={0.85} />
        {Array.from({length: 18}).map((_, i) => (
          <path key={i} d={`M${(i * 120 + t * 30) % 1980 - 60} ${level + 8} q20 -10 40 0 q20 10 40 0`} fill="none" stroke="#bfe9ff" strokeWidth={4} />
        ))}
        {/* Relieve: dos tierras y el fondo entre ellas */}
        <path d="M0 400 L520 420 L640 560 Q960 760 1280 560 L1400 420 L1920 400 L1920 1080 L0 1080 Z" fill={bering ? '#8a7a5c' : '#6cc25a'} />
        <path d="M640 560 Q960 760 1280 560 L1280 1080 L640 1080 Z" fill="#c9b27a" />
        <rect x={0} y={level} width={1920} height={1080 - level} fill="#2f7fd1" opacity={0.55 * (1 - drop)} />
        {walkerK > 0 && walkerK < 1 && !bering ? <Human x={600 + walkerK * 720} y={650 + Math.sin(walkerK * Math.PI) * 30} s={0.45} t={t} walk={1} /> : null}
        {bering ? <Mammoth x={lin(t, Wa('beringia') - 1, P[4], 560, 1360)} y={660} s={0.35} t={t} walk={1} /> : null}
        <line x1={1700} y1={520} x2={1700} y2={level} stroke={C.accent} strokeWidth={6} strokeDasharray="14 8" opacity={drop} />
      </svg>
      <div style={{position: 'absolute', top: 300, left: 140}}>
        <Pill color="#fff" size={44}>
          {bering ? 'ASIA' : 'FRANCIA'}
        </Pill>
      </div>
      <div style={{position: 'absolute', top: 300, right: 140}}>
        <Pill color="#fff" size={44}>
          {bering ? 'AMÉRICA' : 'INGLATERRA'}
        </Pill>
      </div>
      <Pop at={Wa('metros', P[3]) - 0.2} style={{top: 420, left: 1500}}>
        <Title size={90} color={C.accent}>
          −120 m
        </Title>
      </Pop>
      <Pop at={Wa('doggerland') - 0.1} out={Wa('beringia') - 2.6} style={{top: 140, left: 0, right: 0}}>
        <Title size={110} color={C.accent}>
          DOGGERLAND
        </Title>
      </Pop>
      <Pop at={Wa('beringia') - 0.1} style={{top: 140, left: 0, right: 0}}>
        <Title size={110} color={C.accent}>
          BERINGIA
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 5. LA ESTEPA HELADA
// =====================================================================
const SteppeScene = () => {
  const t = useT();
  const thud = Wa('solo', P[4]);
  const shake = t > thud && t < thud + 0.8 ? Math.sin(t * 60) * lin(t, thud, thud + 0.8, 14, 0) : 0;
  return (
    <AbsoluteFill style={{translate: `${shake}px ${shake * 0.5}px`}}>
      <svg {...CANVAS}>
        <Tundra t={t} pan={t * 80} snow={0.8} ground="#d8dcc4" sky="dusk" />
        {t > thud ? (
          <g opacity={lin(t, thud, thud + 0.6, 0, 1)}>
            <rect x={0} y={0} width={1920} height={1080} fill="#000" opacity={0.35} />
            {[300, 880, 1500].map((x, i) => (
              <g key={x} transform={`translate(${x} ${640 + i * 30})`}>
                <circle cx={-14} cy={0} r={8} fill="#ffe27a" opacity={0.6 + 0.4 * Math.sin(t * 6 + i)} />
                <circle cx={14} cy={0} r={8} fill="#ffe27a" opacity={0.6 + 0.4 * Math.sin(t * 6 + i)} />
              </g>
            ))}
          </g>
        ) : null}
      </svg>
      <Pop at={Wa('estepa', P[4]) - 0.1} out={thud - 0.2} style={{top: 160, left: 0, right: 0}}>
        <Title size={110} color="#fff">
          ESTEPA HELADA
        </Title>
      </Pop>
      <Pop at={thud} style={{top: 160, left: 0, right: 0}}>
        <Title size={110} color={C.red}>
          NO ESTÁS SOLO…
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 6. LOS GIGANTES (comparativa de tamaños)
// =====================================================================
const GiantsScene = () => {
  const t = useT();
  const m = Wa('mamuts', P[5]);
  const rh = Wa('rinocerontes', P[5]);
  const de = Wa('ciervos', P[5]);
  const li = Wa('leones', P[5]);
  const am = Wa('américa', P[5]);
  const show = (at) => r(t, at, at + 0.5, 0, 1, BACK);
  const usa = t > am - 0.2;
  const GROUND = 900;
  const PX = 160; // píxeles por metro
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#dbe9f5, #f4f8fb)'}}>
      <svg {...CANVAS}>
        {[1, 2, 3, 4].map((mts) => (
          <g key={mts}>
            <line x1={60} x2={1860} y1={GROUND - mts * PX} y2={GROUND - mts * PX} stroke="#9ab" strokeWidth={2} strokeDasharray="10 10" />
            <text x={70} y={GROUND - mts * PX - 10} fontFamily={FONT} fontWeight={900} fontSize={28} fill="#678">
              {mts} m
            </text>
          </g>
        ))}
        <rect x={0} y={GROUND} width={1920} height={180} fill="#e6ebe0" />
        <Human x={150} y={GROUND} s={1.6} t={t} />
        {!usa ? (
          <>
            <g transform={`translate(0 ${(1 - show(m)) * 600})`}>
              <Mammoth x={560} y={GROUND} s={2.05} t={t} />
            </g>
            <g transform={`translate(0 ${(1 - show(rh)) * 600})`}>
              <WoollyRhino x={1200} y={GROUND} s={1.25} t={t} />
            </g>
            <g transform={`translate(0 ${(1 - show(de)) * 700})`}>
              <GiantDeer x={1500} y={GROUND} s={1.1} t={t} />
            </g>
            <g transform={`translate(0 ${(1 - show(li)) * 600})`}>
              <CaveLion x={1760} y={GROUND} s={0.9} t={t} roar={t > li + 0.3 && t < li + 1.2 ? 1 : 0} />
            </g>
            {t > Wa('lobos', P[5]) ? <Wolf x={1040} y={GROUND} s={1.0} t={t} /> : null}
          </>
        ) : null}
      </svg>
      {!usa ? (
        <>
          <Pop at={m} out={am - 0.3} style={{top: 140, left: 420}}>
            <Pill color="#6b4428" text="#fff" size={36}>
              MAMUT · 4 m
            </Pill>
          </Pop>
          <Pop at={rh} out={am - 0.3} style={{top: 560, left: 1060}}>
            <Pill color="#7a6045" text="#fff" size={32}>
              RINOCERONTE LANUDO
            </Pill>
          </Pop>
          <Pop at={de} out={am - 0.3} style={{top: 300, left: 1300}}>
            <Pill color="#a0693a" text="#fff" size={32}>
              CIERVO GIGANTE · CUERNOS DE 3 m
            </Pill>
          </Pop>
          <Pop at={li} out={am - 0.3} style={{top: 660, left: 1580}}>
            <Pill color="#d0a060" size={32}>
              LEÓN DE LAS CAVERNAS
            </Pill>
          </Pop>
        </>
      ) : (
        <Pop at={am - 0.1} style={{top: 260, left: 0, right: 0, flexDirection: 'column', gap: 24}}>
          <Title size={80}>Y EN AMÉRICA…</Title>
          <div style={{display: 'flex', gap: 24}}>
            <Pill color={C.red} text="#fff" size={52}>
              TIGRES DIENTES DE SABLE
            </Pill>
            <Pill color="#8a6a3a" text="#fff" size={52}>
              PEREZOSOS GIGANTES
            </Pill>
          </div>
        </Pop>
      )}
      <Pop at={P[5] + 0.4} out={m - 0.2} style={{top: 200, left: 0, right: 0}}>
        <Title size={130} color={C.accent}>
          UN MUNDO DE GIGANTES
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 7. NO ERES EL REY
// =====================================================================
const NotKingScene = () => {
  const t = useT();
  const soap = Wa('jabón', P[6]);
  return (
    <AbsoluteFill>
      <svg {...CANVAS}>
        <Tundra t={t} pan={0} snow={0.6} />
        <Mammoth x={330} y={880} s={1.1} t={t} />
        <CaveLion x={1600} y={900} s={1.1} t={t} flip />
        <Wolf x={1250} y={920} s={1.1} t={t} />
        <Human x={960} y={900} s={0.9} t={t} modern />
        {t > soap
          ? Array.from({length: 10}).map((_, i) => {
              const u = ((t - soap) * 0.5 + i / 10) % 1;
              return <circle key={i} cx={960 + Math.sin(i * 3 + t) * 60} cy={760 - u * 260} r={10 + (i % 3) * 6} fill="#e8f6ff" stroke="#9ed6ff" strokeWidth={3} opacity={1 - u} />;
            })
          : null}
      </svg>
      <Pop at={P[6] + 0.3} style={{top: 140, left: 0, right: 0}}>
        <Title size={110}>
          ERES <span style={{color: C.red}}>UN ANIMAL MÁS</span>
        </Title>
      </Pop>
      <Pop at={soap - 0.1} style={{top: 300, left: 0, right: 0}}>
        <Title size={80} color="#9ed6ff">
          …Y OLIENDO A JABÓN
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 8. LAS PRIMERAS 24 HORAS
// =====================================================================
const FirstDayScene = () => {
  const t = useT();
  const night = r(t, P[7], P[8], 0, 1);
  const body = r(t, Wa('hipotermia') - 1, Wa('hipotermia') + 1, 37, 34.5);
  const needs = [
    ['refugio', 'REFUGIO', '#a0703f'],
    ['fuego', 'FUEGO', C.hot],
    ['agua', 'AGUA', '#5ec8ff'],
  ];
  return (
    <AbsoluteFill>
      <svg {...CANVAS}>
        <Tundra t={t} sky={night > 0.5 ? 'night' : 'dusk'} snow={1.6} />
        <Human x={960} y={900} s={0.9} t={t} modern />
      </svg>
      <div style={{position: 'absolute', top: 160, left: 120}}>
        <Card border={body < 35.5 ? C.red : '#fff'} style={{fontSize: 44, fontWeight: 900, textAlign: 'center'}}>
          TU CUERPO
          <div style={{fontSize: 110, color: body < 35.5 ? '#5ec8ff' : '#fff'}}>{body.toFixed(1).replace('.', ',')} °C</div>
          {body < 35.5 ? <div style={{color: C.red}}>¡HIPOTERMIA!</div> : null}
        </Card>
      </div>
      <Pop at={P[7] + 0.4} out={Wa('refugio') - 0.3} style={{top: 160, left: 760}}>
        <Title size={84} color={C.accent}>
          TU MAYOR ENEMIGO:
          <br />
          EL FRÍO
        </Title>
      </Pop>
      <div style={{position: 'absolute', top: 200, right: 120, display: 'flex', flexDirection: 'column', gap: 18}}>
        {needs.map(([w, label, col]) => {
          const at = Wa(w, P[7]);
          return (
            <div key={w} style={{scale: String(r(t, at, at + 0.4, 0, 1, BACK)), display: 'flex', alignItems: 'center', gap: 16, background: 'rgba(8,12,30,0.88)', border: `4px solid ${col}`, borderRadius: 24, padding: '12px 28px', fontFamily: FONT, fontWeight: 900, fontSize: 56, color: '#fff'}}>
              <div style={{width: 34, height: 34, borderRadius: 17, background: col}} />
              {label}
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

// =====================================================================
// 9. EL AGUA Y EL FUEGO
// =====================================================================
const FireScene = () => {
  const t = useT();
  const germs = t < Wa('mechero') - 0.3;
  const lighter = t >= Wa('mechero') - 0.3 && t < Wa('frotando') - 0.3;
  const sticks = t >= Wa('frotando') - 0.3 && t < Wa('sílex') - 0.3;
  const flint = t >= Wa('sílex') - 0.3 && t < P[9];
  const search = t >= P[9];
  const strike = Math.max(0, Math.sin(t * 9));
  return (
    <AbsoluteFill style={{background: search ? 'linear-gradient(#2b2f6b, #f2a07b)' : 'radial-gradient(circle at 50% 50%, #2a2018, #0b0806)'}}>
      <svg {...CANVAS}>
        {search ? <Tundra t={t} sky="dusk" snow={0.5} /> : null}
        {germs ? (
          <g transform="translate(960 560)">
            <path d="M0 -260 C120 -100 170 -20 170 60 A170 170 0 0 1 -170 60 C-170 -20 -120 -100 0 -260 Z" fill="#5ec8ff" opacity={0.85} />
            {Array.from({length: 9}).map((_, i) => {
              const a = i * 0.7 + t;
              return (
                <g key={i} transform={`translate(${Math.cos(a) * (40 + (i % 3) * 30)} ${60 + Math.sin(a * 1.3) * 60})`}>
                  <ellipse rx={18} ry={12} fill="#3ddc84" />
                  <circle cx={-5} cy={-3} r={3} fill="#0b0b14" />
                  <circle cx={5} cy={-3} r={3} fill="#0b0b14" />
                </g>
              );
            })}
          </g>
        ) : null}
        {lighter ? (
          <g transform="translate(960 560)">
            <rect x={-60} y={-120} width={120} height={240} rx={20} fill="#ff5a36" />
            <rect x={-60} y={-160} width={120} height={50} rx={8} fill="#c9d1e0" />
            <g transform="translate(-50 -50)">
              <Cross s={1.6} />
            </g>
          </g>
        ) : null}
        {sticks ? (
          <g transform="translate(960 640)">
            <rect x={-300} y={20} width={600} height={40} rx={12} fill="#8a5a2c" />
            <rect x={-12} y={-260} width={24} height={300} rx={10} fill="#a0703f" transform={`rotate(${Math.sin(t * 30) * 4} 0 30)`} />
            {[0, 1, 2].map((i) => {
              const u = (t * 0.8 + i / 3) % 1;
              return <circle key={i} cx={Math.sin(i + t) * 20} cy={10 - u * 160} r={10 + u * 26} fill="#9aa3b8" opacity={0.5 * (1 - u)} />;
            })}
          </g>
        ) : null}
        {flint ? (
          <g transform="translate(960 560)">
            <path d="M-260 40 L-120 -60 L-60 20 L-140 110 Z" fill="#5a6070" stroke="#2a2f3a" strokeWidth={6} transform={`rotate(${-strike * 18} -100 20)`} />
            <path d="M80 -30 L230 -40 L250 60 L120 90 Z" fill="#c9a43a" stroke="#7a6418" strokeWidth={6} />
            {strike > 0.85
              ? Array.from({length: 16}).map((_, i) => {
                  const a = (i / 16) * Math.PI * 2;
                  return <line key={i} x1={0} y1={0} x2={Math.cos(a) * 90} y2={Math.sin(a) * 90} stroke="#ffe27a" strokeWidth={6} strokeLinecap="round" />;
                })
              : null}
          </g>
        ) : null}
        {search ? (
          <g>
            {[0, 1, 2, 3, 4].map((i) => {
              const u = (t * 0.25 + i / 5) % 1;
              return <circle key={i} cx={1500 + Math.sin(u * 6) * 20} cy={740 - u * 380} r={20 + u * 60} fill="#9aa3b8" opacity={0.6 * (1 - u)} />;
            })}
            <Human x={700} y={900} s={0.9} t={t} modern walk={1} />
          </g>
        ) : null}
      </svg>
      {germs ? (
        <Pop at={P[8] + 0.6} style={{top: 140, left: 0, right: 0}}>
          <Title size={90}>
            AGUA SIN HERVIR = <span style={{color: C.green}}>GÉRMENES</span>
          </Title>
        </Pop>
      ) : null}
      {lighter ? (
        <Pop at={Wa('mechero') - 0.3} style={{top: 140, left: 0, right: 0}}>
          <Title size={110} color={C.red}>
            SIN MECHERO
          </Title>
        </Pop>
      ) : null}
      {sticks ? (
        <Pop at={Wa('frotando') - 0.3} style={{top: 140, left: 0, right: 0}}>
          <Title size={90}>NO ES COMO EN LAS PELÍCULAS</Title>
        </Pop>
      ) : null}
      {flint ? (
        <>
          <Pop at={Wa('sílex') - 0.2} style={{top: 760, left: 560}}>
            <Pill color="#c9d1e0" size={44}>
              SÍLEX
            </Pill>
          </Pop>
          <Pop at={Wa('pirita') - 0.2} style={{top: 760, left: 1120}}>
            <Pill color="#e8c547" size={44}>
              PIRITA
            </Pill>
          </Pop>
          <Pop at={Wa('probablemente', P[8]) - 0.1} style={{top: 140, left: 0, right: 0}}>
            <Title size={90} color={C.red}>
              ¿TÚ? PROBABLEMENTE NO
            </Title>
          </Pop>
        </>
      ) : null}
      {search ? (
        <Pop at={P[9] + 0.5} style={{top: 140, left: 0, right: 0}}>
          <Title size={110} color={C.accent}>
            BUSCA A OTROS HUMANOS
          </Title>
        </Pop>
      ) : null}
    </AbsoluteFill>
  );
};

// =====================================================================
// 10. LOS OTROS HUMANOS
// =====================================================================
const HumansScene = () => {
  const t = useT();
  const solu = t >= P[11];
  const point = Wa('laurel');
  const needle = Wa('agujas');
  const thrower = Wa('lanzadores');
  const paint = Wa('pintaban');
  const throwK = lin(t, thrower + 0.6, thrower + 2.0, 0, 1);
  return (
    <AbsoluteFill>
      <svg {...CANVAS}>
        {!solu ? (
          <>
            <rect x={0} y={0} width={1920} height={1080} fill="#1a2040" />
            <Human x={720} y={900} s={2.4} t={t} />
            <Human x={1200} y={900} s={2.4} t={t} modern />
            <text x={960} y={560} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={160} fill={C.accent}>
              =
            </text>
          </>
        ) : (
          <>
            <rect x={0} y={0} width={1920} height={1080} fill="#2a1c12" />
            {/* Pared de la cueva */}
            <path d="M0 0 L1920 0 L1920 420 Q1500 520 960 470 Q400 420 0 520 Z" fill="#5a4030" />
            {t > paint ? (
              <g opacity={lin(t, paint, paint + 1, 0, 1)}>
                <g transform="translate(560 260)">
                  <CaveBison s={1.2} />
                </g>
                <g transform="translate(1340 230) scale(-1 1)">
                  <CaveBison s={0.9} color="#3a2418" />
                </g>
              </g>
            ) : null}
            <rect x={0} y={860} width={1920} height={220} fill="#3a2a1c" />
            <Fire x={960} y={880} s={1.3} t={t} />
            {[620, 760, 1160, 1300, 1440].map((x, i) => (
              <Human key={x} x={x} y={900 - (i % 2) * 10} s={0.9} t={t} fur={['#8a5a2c', '#a0703f', '#6b4428'][i % 3]} wave={i === 2 ? Math.sin(t * 3) * 20 : 0} spear={i === 4} />
            ))}
            {t > thrower ? (
              <g>
                <line x1={300 + throwK * 1500} y1={620 - Math.sin(throwK * Math.PI) * 200} x2={360 + throwK * 1500} y2={600 - Math.sin(throwK * Math.PI) * 200} stroke="#7a4e2a" strokeWidth={8} opacity={throwK > 0 && throwK < 1 ? 1 : 0} />
              </g>
            ) : null}
          </>
        )}
      </svg>
      {!solu ? (
        <>
          <Pop at={P[10] + 1} style={{top: 120, left: 0, right: 0}}>
            <Title size={90}>
              SOLO QUEDA <span style={{color: C.accent}}>NUESTRA ESPECIE</span>
            </Title>
          </Pop>
          <Pop at={Wa('neandertales') - 0.1} out={Wa('personas', P[10]) - 0.2} style={{top: 260, left: 0, right: 0}}>
            <Pill color="#c9d1e0" size={40}>
              NEANDERTALES: DESAPARECIDOS HACE +40.000 AÑOS
            </Pill>
          </Pop>
          <Pop at={Wa('cerebro', P[10]) - 0.1} style={{top: 260, left: 0, right: 0}}>
            <Pill color={C.accent} size={44}>
              MISMO CUERPO · MISMO CEREBRO · MISMA INTELIGENCIA
            </Pill>
          </Pop>
        </>
      ) : (
        <>
          <Pop at={P[11] + 0.4} out={Wa('solutrenses') - 0.2} style={{top: 520, left: 0, right: 0}}>
            <Card style={{fontSize: 48, fontWeight: 900, textAlign: 'center'}}>
              EN TODO EL PLANETA: <span style={{color: C.accent}}>UNOS POCOS MILLONES</span>
              <br />
              <span style={{fontSize: 34, color: '#b9c3dd'}}>HOY: MÁS DE 8.000 MILLONES</span>
            </Card>
          </Pop>
          <Pop at={Wa('solutrenses') - 0.1} style={{top: 520, left: 0, right: 0}}>
            <Title size={110} color={C.accent}>
              LOS SOLUTRENSES
            </Title>
          </Pop>
          <Pop at={point - 0.2} out={needle - 0.2} style={{top: 140, left: 1560}}>
            <svg width={200} height={300} viewBox="-100 -150 200 300">
              <LaurelPoint s={1} />
            </svg>
          </Pop>
          <Pop at={needle - 0.2} out={thrower - 0.2} style={{top: 140, left: 1560}}>
            <svg width={200} height={300} viewBox="-100 -150 200 300">
              <rect x={-6} y={-130} width={12} height={260} rx={6} fill="#efe6d2" stroke="#b5a37e" strokeWidth={3} />
              <ellipse cx={0} cy={-110} rx={3} ry={8} fill="#2a1c12" />
            </svg>
          </Pop>
        </>
      )}
    </AbsoluteFill>
  );
};

// =====================================================================
// 11. GANARTE SU CONFIANZA
// =====================================================================
const TrustScene = () => {
  const t = useT();
  const trust = r(t, Wa('confianza') - 0.5, P[13], 0.05, 1);
  return (
    <AbsoluteFill>
      <svg {...CANVAS}>
        <Tundra t={t} sky="dusk" snow={0.4} />
        <Fire x={1300} y={900} s={1.1} t={t} />
        {[1150, 1430, 1560].map((x, i) => (
          <Human key={x} x={x} y={900} s={0.9} t={t} fur={['#8a5a2c', '#a0703f', '#6b4428'][i]} />
        ))}
        <Human x={lin(t, P[12], P[12] + 4, 300, 820)} y={900} s={0.9} t={t} modern walk={t < P[12] + 4 ? 1 : 0} />
        {t > Wa('leña') - 0.2 ? (
          <g transform={`translate(${lin(t, P[12], P[12] + 4, 300, 820) + 30} 760)`}>
            {[0, 1, 2].map((i) => (
              <rect key={i} x={-40} y={-i * 16} width={80} height={14} rx={6} fill="#8a5a2c" />
            ))}
          </g>
        ) : null}
        {t < Wa('ganarte', P[12])
          ? [1150, 1430, 1560].map((x, i) => (
              <g key={x} transform={`translate(${x + 30} 680)`}>
                <ellipse rx={50} ry={34} fill="#fff" />
                <text y={14} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={40} fill="#0b0b14">
                  {['?!', '??', '¿?'][i]}
                </text>
              </g>
            ))
          : null}
      </svg>
      <Pop at={Wa('idioma') - 0.1} out={Wa('ganarte', P[12]) - 0.2} style={{top: 140, left: 0, right: 0}}>
        <Title size={90}>NO HABLAS SU IDIOMA</Title>
      </Pop>
      <Pop at={Wa('ganarte', P[12]) - 0.1} style={{top: 140, left: 460, right: 460, flexDirection: 'column'}}>
        <Title size={70}>CONFIANZA</Title>
        <div style={{width: '100%', height: 46, borderRadius: 26, border: '4px solid #fff', background: 'rgba(8,12,30,0.8)', overflow: 'hidden', marginTop: 12}}>
          <div style={{width: `${trust * 100}%`, height: '100%', background: `linear-gradient(90deg, ${C.red}, ${C.accent}, ${C.green})`}} />
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 12. TU NUEVA VIDA (comida, día a día, Vía Láctea)
// =====================================================================
const FOODS = [
  ['carne', 'CARNE', '#c0392b'],
  ['pescado', 'PESCADO', '#5ec8ff'],
  ['raíces', 'RAÍCES', '#a0703f'],
  ['frutos', 'FRUTOS', '#ff3d81'],
  ['miel', 'MIEL', '#e8c547'],
];

const DailyScene = () => {
  const t = useT();
  const sky = t > Wa('noche', P[14]) - 0.5;
  const no = Wa('pan', P[14]);
  return (
    <AbsoluteFill>
      <svg {...CANVAS}>
        <Tundra t={t} sky={sky ? 'night' : 'day'} pan={sky ? 0 : t * 40} snow={0.3} />
        {sky ? (
          <g opacity={lin(t, Wa('noche', P[14]) - 0.5, Wa('láctea') + 0.5, 0, 1)}>
            <path d="M-100 700 Q600 200 2000 -50" fill="none" stroke="#e9e2ff" strokeWidth={180} opacity={0.18} style={{filter: 'blur(30px)'}} />
            {Array.from({length: 260}).map((_, i) => {
              const u = random(`mw${i}`);
              const x = -100 + u * 2100;
              const y = 700 - u * 750 + (random(`mv${i}`) - 0.5) * 220;
              return <circle key={i} cx={x} cy={y} r={0.8 + random(`mr${i}`) * 2} fill="#fff" opacity={0.5 + 0.5 * Math.sin(t * 2 + i)} />;
            })}
            <Fire x={960} y={900} s={1.2} t={t} />
            {[800, 1120].map((x) => (
              <Human key={x} x={x} y={900} s={0.8} t={t} flip={x > 960} />
            ))}
          </g>
        ) : null}
      </svg>
      {!sky ? (
        <>
          <div style={{position: 'absolute', top: 160, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 18}}>
            {FOODS.map(([w, label, col]) => {
              const at = Wa(w, P[14]);
              return (
                <div key={w} style={{scale: String(r(t, at, at + 0.4, 0, 1, BACK))}}>
                  <Pill color={col} text={col === '#e8c547' ? '#0b0b14' : '#fff'} size={44}>
                    {label}
                  </Pill>
                </div>
              );
            })}
          </div>
          <Pop at={no - 0.1} out={Wa('caminarías') - 0.2} style={{top: 300, left: 0, right: 0, gap: 24}}>
            {['PAN', 'AZÚCAR', 'LECHE'].map((x) => (
              <div key={x} style={{position: 'relative'}}>
                <Pill color="rgba(255,255,255,0.85)" size={44}>
                  {x}
                </Pill>
                <div style={{position: 'absolute', left: -10, right: -10, top: '50%', height: 10, background: C.red, rotate: '-8deg', borderRadius: 5}} />
              </div>
            ))}
          </Pop>
          <Pop at={Wa('agricultura', P[14]) - 0.1} out={Wa('caminarías') - 0.2} style={{top: 440, left: 0, right: 0}}>
            <Card style={{fontSize: 46, fontWeight: 900}}>
              AGRICULTURA: <span style={{color: C.accent}}>DENTRO DE ~8.000 AÑOS</span>
            </Card>
          </Pop>
        </>
      ) : (
        <Pop at={Wa('láctea') - 0.6} style={{top: 140, left: 0, right: 0}}>
          <Title size={100} color="#e9e2ff">
            LA VÍA LÁCTEA, SIN CONTAMINACIÓN
          </Title>
        </Pop>
      )}
    </AbsoluteFill>
  );
};

// =====================================================================
// 13. LOS PELIGROS
// =====================================================================
const DangerScene = () => {
  const t = useT();
  const items = [
    ['herida', 'HERIDA INFECTADA'],
    ['pierna', 'PIERNA ROTA'],
    ['parto', 'PARTO COMPLICADO'],
  ];
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 50%, #3a0a12, #0b0204)'}}>
      <div style={{position: 'absolute', top: 200, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 30}}>
        {items.map(([w, label]) => {
          const at = Wa(w, P[15]);
          return (
            <div key={w} style={{scale: String(r(t, at, at + 0.4, 0, 1, BACK))}}>
              <Card border={C.red} style={{fontSize: 52, fontWeight: 900}}>
                {label}
              </Card>
            </div>
          );
        })}
      </div>
      <Pop at={Wa('mortales', P[15]) - 0.1} style={{top: 420, left: 0, right: 0}}>
        <Title size={120} color={C.red}>
          = MORTAL
        </Title>
      </Pop>
      <Pop at={Wa('médicos', P[15]) - 0.1} style={{top: 620, left: 0, right: 0, gap: 20}}>
        {['SIN MÉDICOS', 'SIN ANTIBIÓTICOS', 'SIN HOSPITALES'].map((x) => (
          <Pill key={x} color="#fff" size={40}>
            {x}
          </Pill>
        ))}
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 14. ¿PODRÍAS CAMBIAR LA HISTORIA?
// =====================================================================
const ChangeScene = () => {
  const t = useT();
  const idea1 = t >= P[17] && t < P[18];
  const idea2 = t >= P[18];
  const co2 = Wa('dióxido');
  const fail1 = Wa('imposible', P[17]);
  const fail2 = Wa('probablemente', P[18]);
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#141a3a, #2a2f6b)'}}>
      {!idea1 && !idea2 ? (
        <Pop at={P[16] + 0.3} style={{top: 320, left: 140, right: 140}}>
          <Title size={110}>
            CON TODO LO QUE SABES…
            <br />
            <span style={{color: C.accent}}>¿PODRÍAS CAMBIAR LA HISTORIA?</span>
          </Title>
        </Pop>
      ) : null}
      {idea1 ? (
        <>
          <Pop at={P[17] + 0.3} style={{top: 120, left: 0, right: 0}}>
            <Title size={80}>
              IDEA 1: <span style={{color: C.green}}>INVENTAR LA AGRICULTURA</span>
            </Title>
          </Pop>
          <Pop at={co2 - 0.2} style={{top: 300, left: 360, right: 360, flexDirection: 'column', gap: 18}}>
            <Card border="#5ec8ff" style={{width: '100%', boxSizing: 'border-box'}}>
              <div style={{fontSize: 40, fontWeight: 900, marginBottom: 14}}>CO₂ EN EL AIRE</div>
              {[
                ['EDAD DE HIELO', 190, '#5ec8ff'],
                ['HOY', 420, C.hot],
              ].map(([label, v, col], i) => (
                <div key={label} style={{display: 'flex', alignItems: 'center', gap: 20, marginTop: 10}}>
                  <div style={{width: 300, fontSize: 32, fontWeight: 800}}>{label}</div>
                  <div style={{height: 50, width: `${(v / 420) * 100 * r(t, co2 + i * 0.4, co2 + i * 0.4 + 0.8, 0, 1) * 0.7}%`, background: col, borderRadius: 12}} />
                  <div style={{fontSize: 36, fontWeight: 900}}>~{v} ppm</div>
                </div>
              ))}
            </Card>
          </Pop>
          <Pop at={fail1 - 0.2} style={{top: 760, left: 0, right: 0}}>
            <Pill color={C.red} text="#fff" size={52}>
              CASI IMPOSIBLE EN LA EDAD DE HIELO
            </Pill>
          </Pop>
        </>
      ) : null}
      {idea2 ? (
        <>
          <Pop at={P[18] + 0.3} style={{top: 120, left: 0, right: 0}}>
            <Title size={80}>
              IDEA 2: <span style={{color: '#c9d1e0'}}>METAL, RUEDA, VAPOR…</span>
            </Title>
          </Pop>
          <Pop at={Wa('horno') - 0.2} style={{top: 320, left: 0, right: 0}}>
            <Card border={C.hot} style={{fontSize: 64, fontWeight: 900}}>
              HORNO A <span style={{color: C.hot}}>+1.000 °C</span>
            </Card>
          </Pop>
          <Pop at={fail2 - 0.2} style={{top: 520, left: 0, right: 0}}>
            <Cross s={1.4} />
          </Pop>
          <Pop at={Wa('solo', P[18]) - 0.2} style={{top: 740, left: 0, right: 0}}>
            <Pill color="#fff" size={46}>
              SABES USAR LAS COSAS… NO FABRICARLAS
            </Pill>
          </Pop>
        </>
      ) : null}
    </AbsoluteFill>
  );
};

// =====================================================================
// 15. TU SUPERPODER: LOS GÉRMENES
// =====================================================================
const RULES = [
  ['hervir', 'HERVIR EL AGUA'],
  ['heridas', 'LAVAR LAS HERIDAS'],
  ['manos', 'LAVARSE LAS MANOS'],
  ['carne', 'NO COMER CARNE EN MAL ESTADO'],
];

const SuperScene = () => {
  const t = useT();
  const healer = t >= P[21];
  const germAt = Wa('gérmenes', P[19]);
  return (
    <AbsoluteFill style={{background: healer ? 'linear-gradient(#2b2f6b, #f2a07b)' : 'radial-gradient(circle at 50% 50%, #0f2a1c, #050a08)'}}>
      <svg {...CANVAS}>
        {!healer && t > germAt - 0.3
          ? Array.from({length: 24}).map((_, i) => {
              const x = 200 + random(`gm${i}`) * 1520 + Math.sin(t * 2 + i) * 20;
              const y = 160 + random(`gn${i}`) * 700 + Math.cos(t * 1.7 + i) * 20;
              const s = r(t, germAt + i * 0.03, germAt + i * 0.03 + 0.4, 0, 1, BACK);
              return (
                <g key={i} transform={`translate(${x} ${y}) scale(${s})`} opacity={0.5}>
                  <ellipse rx={30} ry={20} fill="#3ddc84" />
                  {[0, 1, 2, 3, 4, 5].map((k) => (
                    <line key={k} x1={0} y1={0} x2={Math.cos(k) * 42} y2={Math.sin(k) * 30} stroke="#3ddc84" strokeWidth={4} />
                  ))}
                  <circle cx={-8} cy={-4} r={4} fill="#0b0b14" />
                  <circle cx={8} cy={-4} r={4} fill="#0b0b14" />
                </g>
              );
            })
          : null}
        {healer ? (
          <g>
            <Tundra t={t} sky="dusk" snow={0.2} />
            <Fire x={960} y={900} s={1.1} t={t} />
            <Human x={960} y={860} s={1.2} t={t} modern wave={20} />
            <path d="M920 650 Q960 610 1000 650" fill="none" stroke={C.green} strokeWidth={10} />
            {[640, 780, 1140, 1280].map((x, i) => (
              <Human key={x} x={x} y={900} s={0.85} t={t} fur={['#8a5a2c', '#a0703f'][i % 2]} flip={x > 960} />
            ))}
          </g>
        ) : null}
      </svg>
      {!healer ? (
        <>
          <Pop at={P[19] + 0.2} out={germAt - 0.3} style={{top: 360, left: 0, right: 0}}>
            <Title size={110}>PERO HAY UNA COSA QUE SÍ SABES…</Title>
          </Pop>
          <Pop at={germAt - 0.1} style={{top: 120, left: 0, right: 0}}>
            <Title size={110} color={C.green}>
              LOS GÉRMENES EXISTEN
            </Title>
          </Pop>
          <div style={{position: 'absolute', top: 300, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 16}}>
            {RULES.map(([w, label]) => {
              const at = t > P[20] ? Wa(w, P[20]) : 1e9;
              return (
                <div key={w} style={{scale: String(r(t, at, at + 0.4, 0, 1, BACK)), display: 'flex', alignItems: 'center', gap: 18, background: 'rgba(8,12,30,0.9)', border: `4px solid ${C.green}`, borderRadius: 24, padding: '10px 28px', fontFamily: FONT, fontWeight: 900, fontSize: 48, color: '#fff'}}>
                  <Check size={52} color={C.green} />
                  {label}
                </div>
              );
            })}
          </div>
          <Pop at={Wa('superpoder') - 0.1} style={{top: 120, left: 0, right: 0}}>
            <Title size={130} color={C.accent} style={{textShadow: `0 0 50px ${C.accent}`}}>
              TU SUPERPODER
            </Title>
          </Pop>
        </>
      ) : (
        <Pop at={P[21] + 1} style={{top: 140, left: 0, right: 0, gap: 30}}>
          <Pill color={C.green} size={56}>
            LA CURANDERA
          </Pill>
          <Pill color={C.accent} size={56}>
            EL SABIO
          </Pill>
        </Pop>
      )}
    </AbsoluteFill>
  );
};

// =====================================================================
// 16. LO QUE VINO DESPUÉS (línea temporal)
// =====================================================================
const MARKS = [
  ['retroceder', -19000, 'EL HIELO SE RETIRA', '#5ec8ff'],
  ['mar', -15000, 'EL MAR SUBE +100 m', '#2f7fd1'],
  ['mamuts', -11000, 'ADIÓS A LOS GIGANTES', '#a0693a'],
  ['agricultura', -10000, 'AGRICULTURA', C.green],
  ['ciudades', -7000, 'PRIMERAS CIUDADES', C.accent],
  ['escritura', -3200, 'ESCRITURA', '#fff'],
  ['hoy', 2026, 'HOY', C.pink],
];

const AfterScene = () => {
  const t = useT();
  const X0 = 330;
  const X1 = 1680;
  const xOf = (y) => X0 + ((y + 18000) / 20026) * (X1 - X0);
  const cursor = r(t, P[22] + 0.5, P[23] - 0.5, -18000, 2026, (x) => x);
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#0c2a4a, #5b8fbf)'}}>
      <svg {...CANVAS}>
        <line x1={X0} x2={X1} y1={600} y2={600} stroke="#fff" strokeWidth={8} strokeLinecap="round" />
        <line x1={X0} x2={xOf(cursor)} y1={600} y2={600} stroke={C.accent} strokeWidth={12} strokeLinecap="round" />
        <circle cx={xOf(cursor)} cy={600} r={18} fill={C.accent} />
        <text x={X0} y={660} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={30} fill="#fff">
          18.000 a. C.
        </text>
        {MARKS.map(([w, year, label, col], i) => {
          const at = Wa(w, P[22]);
          const s = r(t, at, at + 0.4, 0, 1, BACK);
          const lift = [-110, 110, -230, 230, -110, 110, -230][i];
          return (
            <g key={w} transform={`translate(${xOf(year)} 600) scale(${s})`}>
              <line x1={0} y1={0} x2={0} y2={lift} stroke={col} strokeWidth={5} />
              <circle r={14} fill={col} />
              <text y={lift < 0 ? lift - 20 : lift + 48} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={34} fill={col} stroke="#05060f" strokeWidth={6} paintOrder="stroke">
                {label}
              </text>
            </g>
          );
        })}
      </svg>
      <Pop at={P[22] + 0.3} style={{top: 120, left: 0, right: 0}}>
        <Title size={90}>20.000 AÑOS DESPUÉS…</Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 17. SON TUS ANTEPASADOS
// =====================================================================
const AncestorsScene = () => {
  const t = useT();
  const final = t >= P[24];
  return (
    <AbsoluteFill>
      <svg {...CANVAS}>
        <Tundra t={t} sky={final ? 'night' : 'dusk'} snow={0.3} />
        {Array.from({length: 7}).map((_, i) => {
          const at = P[23] + 1 + i * 0.35;
          const s = r(t, at, at + 0.4, 0, 1, BACK);
          const modern = i >= 5;
          return (
            <g key={i} opacity={s} transform={`translate(${260 + i * 230} 0)`}>
              <Human x={0} y={900} s={0.95} t={t} modern={modern} fur={['#6b4428', '#8a5a2c', '#a0703f', '#7a4e2a', '#8a5a2c'][i % 5]} wave={i === 6 ? 25 : 0} />
            </g>
          );
        })}
        {final ? <Fire x={960} y={960} s={0.9} t={t} /> : null}
      </svg>
      <Pop at={Wa('antepasados') - 0.1} style={{top: 160, left: 0, right: 0}}>
        <Title size={130} color={C.accent}>
          SON TUS ANTEPASADOS
        </Title>
      </Pop>
      <Pop at={Wa('lo', P[24] + 8) - 0.1} style={{top: 360, left: 0, right: 0}}>
        <Title size={80} color="#fff">
          ELLOS LO CONSIGUIERON
        </Title>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 18. CIERRE
// =====================================================================
const ERAS = ['ANTIGUO EGIPTO', 'DINOSAURIOS', 'IMPERIO ROMANO', 'EDAD MEDIA'];

const OutroScene = () => {
  const t = useT();
  const tapAt = Wa('suscríbete') + 0.5;
  const tapped = t > tapAt;
  const tap = t > tapAt - 0.15 && t < tapAt + 0.15 ? 0.9 : 1;
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#141a3a, #2a2f6b)'}}>
      <Pop at={P[25]} style={{top: 140, left: 0, right: 0, flexDirection: 'column'}}>
        <div style={{width: 160, height: 160, borderRadius: 46, background: `linear-gradient(135deg, ${C.accent}, ${C.hot} 60%, ${C.pink})`, display: 'flex', alignItems: 'center', justifyContent: 'center', fontFamily: FONT, fontWeight: 900, fontSize: 120, color: '#0b0b14'}}>A</div>
        <div style={{marginTop: 20, display: 'flex', alignItems: 'center', gap: 16, padding: '20px 60px', borderRadius: 60, background: tapped ? 'rgba(255,255,255,0.2)' : '#e62117', fontFamily: FONT, fontWeight: 900, fontSize: 56, color: '#fff', scale: String(tap)}}>
          {tapped ? <Check size={56} /> : null}
          {tapped ? 'SUSCRITO' : 'SUSCRIBIRSE'}
        </div>
      </Pop>
      <Pop at={Wa('época', P[25]) - 0.3} style={{top: 560, left: 0, right: 0, flexDirection: 'column', gap: 24}}>
        <Title size={72}>¿A QUÉ ÉPOCA QUIERES DESPERTAR?</Title>
        <div style={{display: 'flex', gap: 20}}>
          {ERAS.map((e, i) => (
            <div key={e} style={{scale: String(r(t, Wa('época', P[25]) + i * 0.2, Wa('época', P[25]) + i * 0.2 + 0.4, 0, 1, BACK))}}>
              <Pill color={[C.accent, C.green, C.red, C.cyan][i]} text={i === 2 ? '#fff' : '#0b0b14'} size={40}>
                {e}
              </Pill>
            </div>
          ))}
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
export const Edad20000 = () => (
  <AbsoluteFill style={{backgroundColor: '#0b0b14'}}>
    <Scene name="Gancho" start={0} end={P[1]} fadeOut={false}>
      <HookScene />
    </Scene>
    <Scene name="¿Dónde estás?" start={P[1]} end={P[2]}>
      <WhereScene />
    </Scene>
    <Scene name="Frío y hielo" start={P[2]} end={P[3]}>
      <ColdScene />
    </Scene>
    <Scene name="El mar" start={P[3]} end={P[4]}>
      <SeaScene />
    </Scene>
    <Scene name="Estepa" start={P[4]} end={P[5]}>
      <SteppeScene />
    </Scene>
    <Scene name="Gigantes" start={P[5]} end={P[6]}>
      <GiantsScene />
    </Scene>
    <Scene name="No eres el rey" start={P[6]} end={P[7]}>
      <NotKingScene />
    </Scene>
    <Scene name="Primeras 24 h" start={P[7]} end={P[8]}>
      <FirstDayScene />
    </Scene>
    <Scene name="Agua y fuego" start={P[8]} end={P[10]}>
      <FireScene />
    </Scene>
    <Scene name="Los otros humanos" start={P[10]} end={P[12]}>
      <HumansScene />
    </Scene>
    <Scene name="Confianza" start={P[12]} end={P[13]}>
      <TrustScene />
    </Scene>
    <Scene name="Día a día" start={P[13]} end={P[15]}>
      <DailyScene />
    </Scene>
    <Scene name="Peligros" start={P[15]} end={P[16]}>
      <DangerScene />
    </Scene>
    <Scene name="Cambiar la historia" start={P[16]} end={P[19]}>
      <ChangeScene />
    </Scene>
    <Scene name="Superpoder" start={P[19]} end={P[22]}>
      <SuperScene />
    </Scene>
    <Scene name="Después" start={P[22]} end={P[23]}>
      <AfterScene />
    </Scene>
    <Scene name="Antepasados" start={P[23]} end={P[25]}>
      <AncestorsScene />
    </Scene>
    <Scene name="Cierre" start={P[25]} end={DURATION} fadeOut={false}>
      <OutroScene />
    </Scene>
    {CHAPTERS.map(([n, , title]) => (
      <Scene key={n} name={`Capítulo ${n}`} start={P[CHAPTERS.find((c) => c[0] === n)[1]]} end={P[CHAPTERS.find((c) => c[0] === n)[1]] + 3.2} fadeOut={false}>
        <ChapterBanner n={n} title={title} />
      </Scene>
    ))}
    <Brand hideAt={P[25]} pos={{top: 30, right: 40}} />
    <ProgressBar />
    <Captions chunks={CHUNKS} top={890} width={1600} fontSize={60} />
    <Audio src={staticFile('yt-20000.mp3')} />
  </AbsoluteFill>
);
