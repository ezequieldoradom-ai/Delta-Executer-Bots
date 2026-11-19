import React from 'react';
import {AbsoluteFill, staticFile, random} from 'remotion';
import {Audio} from '@remotion/media';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, Scene, lin, r, useT} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, Check, Heart, ProgressBar, SpaceBackground} from '../tunel/Visuals';
import {Fire, Hud, IslandWorld, Ocean, Villager, popScale} from './Island';
import WORDS from '../../public/civilizacion-01.words.json';

export const DURATION = 75.3;

const CHUNKS = chunkWords(WORDS, [
  'isla', 'vacía', 'persona', 'ti', 'reglas', 'seguidor', 'habitante', 'diez', 'tribu', 'fuego',
  'jefe', 'cien', 'aldea', 'animales', 'problemas', 'mil', 'pueblo', 'mercado', 'leyes', 'límite',
  'ciudad', 'reino', 'océano', 'luna', 'estrellas', 'reales', 'nombre', 'oficio', 'hoguera',
  'esperando', 'aprende', 'dos', 'civilización', 'likes', 'oficial',
]);

// Habitantes que se muestran en cada momento
const popAt = (t) => {
  if (t < 18.4) return 1;
  if (t < 25.3) return popScale(t, 18.4, 20.0, 1, 10);
  if (t < 31.4) return popScale(t, 25.3, 27.0, 10, 100);
  return popScale(t, 31.4, 33.2, 100, 1000);
};

const Camera = ({zoom, fx = 540, fy = 980, cy = 900, children}) => (
  <g transform={`translate(540 ${cy}) scale(${zoom}) translate(${-fx} ${-fy})`}>{children}</g>
);

// =====================================================================
// 1. LA ISLA VACÍA (0 – 9.2 s)
// =====================================================================
const IntroScene = () => {
  const t = useT();
  const zoom = t < 2.8 ? r(t, 0, 2.8, 0.55, 1) : r(t, 2.88, 4.6, 1, 2.8, INOUT);
  const fx = lin(t, 2.88, 4.6, 540, 580);
  const fy = lin(t, 2.88, 4.6, 980, 960);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <Camera zoom={zoom} fx={fx} fy={fy}>
          <IslandWorld t={t} pop={1} />
        </Camera>
      </svg>
      <Pop at={0.1} out={2.8} style={{top: 260, left: 0, right: 0}}>
        <BigText size={100}>
          UNA ISLA
          <br />
          <span style={{color: C.cyan}}>VACÍA</span>
        </BigText>
      </Pop>
      <Pop at={3.56} out={6.0} style={{top: 1190, left: 0, right: 0}}>
        <Pill color={C.accent} size={52}>
          HABITANTE Nº 1
        </Pill>
      </Pop>
      <Pop at={6.84} style={{top: 1170, left: 0, right: 0}}>
        <BigText size={86}>
          SU DESTINO
          <br />
          DEPENDE DE <span style={{color: C.accent}}>TI</span>
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 2. LAS REGLAS (9.2 – 18.0 s)
// =====================================================================
const RulesScene = () => {
  const t = useT();
  const tap = t > 12.3 && t < 12.6 ? 0.9 : 1;
  const tapped = t > 12.45;
  const drop = r(t, 13.2, 14.0, -400, 0, (x) => x * x);
  const eq = r(t, 16.0, 16.5, 0, 1, BACK);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <Camera zoom={1.9} fx={560} fy={980} cy={1000}>
          <IslandWorld t={t} pop={1} />
          {t > 13.2 ? <Villager x={500} y={990 + drop} t={t} seed={4} s={1.5} wave={Math.sin(t * 8) * 30} /> : null}
          {t > 14.0 && t < 15.0 ? <circle cx={500} cy={990} r={lin(t, 14.0, 15.0, 10, 90)} fill="none" stroke="#fff" strokeWidth={4} opacity={lin(t, 14, 15, 1, 0)} /> : null}
        </Camera>
      </svg>
      <Pop at={9.28} style={{top: 230, left: 0, right: 0}}>
        <Pill color="#fff" size={56}>
          LAS REGLAS
        </Pill>
      </Pop>
      <Pop at={11.0} out={15.9} style={{top: 380, left: 0, right: 0}}>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 16,
            padding: '22px 60px',
            borderRadius: 80,
            background: tapped ? 'rgba(255,255,255,0.25)' : C.pink,
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: 60,
            color: '#fff',
            scale: String(tap),
          }}
        >
          {tapped ? <Check size={60} /> : '+'} {tapped ? 'SIGUIENDO' : 'SEGUIR'}
        </div>
      </Pop>
      <Pop at={13.36} out={15.9} style={{top: 1220, left: 0, right: 0}}>
        <Pill color={C.green} size={50}>
          +1 HABITANTE
        </Pill>
      </Pop>
      {t > 16.0 ? (
        <div style={{position: 'absolute', top: 380, left: 0, right: 0, display: 'flex', justifyContent: 'center', scale: String(eq), opacity: Math.min(1, eq)}}>
          <div style={{display: 'flex', alignItems: 'center', gap: 24, background: 'rgba(8,12,30,0.85)', borderRadius: 40, padding: '20px 36px'}}>
            <BigText size={62} color={C.pink} style={{whiteSpace: 'nowrap'}}>
              1 SEGUIDOR
            </BigText>
            <BigText size={62}>=</BigText>
            <BigText size={62} color={C.accent} style={{whiteSpace: 'nowrap'}}>
              1 HABITANTE
            </BigText>
          </div>
        </div>
      ) : null}
    </AbsoluteFill>
  );
};

// =====================================================================
// 3. LA ISLA CRECE: tribu, aldea, pueblo (18.0 – 35.9 s)
// =====================================================================
const GrowthScene = () => {
  const t = useT();
  const pop = popAt(t);
  const zoom = lin(Math.log10(pop), 0, 3, 1.9, 1.02);
  const tier = pop >= 999.5 ? ['1.000', 'PUEBLO', C.accent] : pop >= 99.5 ? ['100', 'ALDEA', C.green] : pop >= 9.5 ? ['10', 'TRIBU', C.hot] : null;
  const tierAt = pop >= 999.5 ? 33.2 : pop >= 99.5 ? 27.0 : 20.0;
  const problems = t > 29.48 && t < 31.2;
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <Camera zoom={zoom} fx={540} fy={990} cy={980}>
          <IslandWorld t={t} pop={pop} />
          {problems ? (
            <g transform="translate(700 1100)">
              <Villager x={-22} y={0} t={t * 3} seed={1} s={1.4} wave={Math.sin(t * 20) * 40} />
              <Villager x={22} y={0} t={t * 3} seed={2} s={1.4} wave={Math.sin(t * 20 + 1) * 40} />
              <g transform={`translate(0 -90) scale(${r(t, 29.5, 29.8, 0, 1, BACK)})`}>
                <circle r={26} fill={C.red} />
                <text y={14} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={40} fill="#fff">
                  !
                </text>
              </g>
            </g>
          ) : null}
        </Camera>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud label="EP" pop={pop} highlight={t > 18.4 && t < 33.4 ? lin(Math.abs(Math.sin(t * 3)), 0, 1, 0.2, 0.6) * (pop < 999 && (t < 20 || (t > 25.3 && t < 27) || (t > 31.4 && t < 33.2)) ? 1 : 0) : 0} />
      </div>
      {tier ? (
        <TierBanner key={tier[1]} t={t} at={tierAt} n={tier[0]} name={tier[1]} color={tier[2]} />
      ) : null}
      {/* Detalles que se van nombrando */}
      <Pop at={20.64} out={21.8} style={{top: 1220, left: 0, right: 0}}>
        <Pill color={C.hot} text="#fff" size={44}>
          FUEGO
        </Pill>
      </Pop>
      <Pop at={21.92} out={23.4} style={{top: 1220, left: 0, right: 0}}>
        <Pill color="#d9b382" size={44}>
          REFUGIOS
        </Pill>
      </Pop>
      <Pop at={23.56} out={25.0} style={{top: 1220, left: 0, right: 0}}>
        <Pill color={C.accent} size={44}>
          EL JEFE
        </Pill>
      </Pop>
      <Pop at={27.12} out={28.4} style={{top: 1220, left: 0, right: 0}}>
        <Pill color="#e8c547" size={44}>
          CULTIVOS
        </Pill>
      </Pop>
      <Pop at={28.56} out={29.4} style={{top: 1220, left: 0, right: 0}}>
        <Pill color="#fff" size={44}>
          ANIMALES
        </Pill>
      </Pop>
      <Pop at={29.6} out={31.1} style={{top: 1220, left: 0, right: 0}}>
        <Pill color={C.red} text="#fff" size={44}>
          ¡PRIMEROS PROBLEMAS!
        </Pill>
      </Pop>
      <Pop at={33.6} out={34.2} style={{top: 1220, left: 0, right: 0}}>
        <Pill color={C.cyan} size={44}>
          MERCADO
        </Pill>
      </Pop>
      <Pop at={34.28} out={34.95} style={{top: 1220, left: 0, right: 0}}>
        <Pill color="#c9ccd6" size={44}>
          HERREROS
        </Pill>
      </Pop>
      <Pop at={35.16} style={{top: 1220, left: 0, right: 0}}>
        <Pill color="#fff" size={44}>
          LEYES
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

const TierBanner = ({t, at, n, name, color}) => {
  const s = r(t, at - 0.2, at + 0.25, 0, 1, BACK);
  return (
    <div style={{position: 'absolute', top: 380, left: 0, right: 0, display: 'flex', justifyContent: 'center', scale: String(s)}}>
      <div style={{display: 'flex', alignItems: 'center', gap: 18}}>
        <BigText size={110} color={color}>
          {n}
        </BigText>
        <BigText size={80}>· {name}</BigText>
      </div>
    </div>
  );
};

// =====================================================================
// 4. SIN LÍMITE: ciudad, reino, barcos, Luna, estrellas (35.9 – 46.1 s)
// =====================================================================
const Skyline = ({t}) => (
  <g>
    <rect x={0} y={0} width={1080} height={1920} fill="#1a1440" />
    <rect x={0} y={0} width={1080} height={1100} fill="url(#dusk)" />
    {Array.from({length: 16}).map((_, i) => {
      const w = 60 + random(`kw${i}`) * 60;
      const h = 200 + random(`kh${i}`) * 520;
      const x = i * 70 - 20;
      const rise = r(t, 38.16 + i * 0.03, 38.7 + i * 0.03, 0, 1, BACK);
      return (
        <g key={i} transform={`translate(${x} 1150) scale(1 ${rise})`}>
          <rect x={0} y={-h} width={w} height={h} fill={i % 2 ? '#2a2f66' : '#232859'} />
          {Array.from({length: Math.floor(h / 40)}).map((__, row) =>
            [0, 1].map((col) =>
              random(`kwn${i}${row}${col}`) > 0.4 ? <rect key={`${row}${col}`} x={10 + col * (w / 2 - 6)} y={-h + 14 + row * 40} width={w / 2 - 20} height={16} fill="#ffd27a" /> : null,
            ),
          )}
        </g>
      );
    })}
    <rect x={0} y={1150} width={1080} height={800} fill="#0d4f8f" />
  </g>
);

const Castle = ({t}) => {
  const s = r(t, 39.2, 39.7, 0, 1, BACK);
  return (
    <g>
      <rect x={0} y={0} width={1080} height={1920} fill="#7cc4f0" />
      <rect x={0} y={1120} width={1080} height={800} fill="#4f9a42" />
      <g transform={`translate(540 1130) scale(${s})`}>
        <rect x={-260} y={-260} width={520} height={260} fill="#c9c2b4" />
        {[-260, -160, -60, 40, 140, 240].map((x) => (
          <rect key={x} x={x} y={-290} width={30} height={30} fill="#c9c2b4" />
        ))}
        {[-300, 220].map((x) => (
          <g key={x}>
            <rect x={x} y={-420} width={80} height={420} fill="#b9b1a2" />
            <path d={`M${x - 10} -420 L${x + 40} -500 L${x + 90} -420 Z`} fill="#2f5fa8" />
            <line x1={x + 40} y1={-500} x2={x + 40} y2={-560} stroke="#333" strokeWidth={4} />
            <path d={`M${x + 40} -560 L${x + 90 + Math.sin(t * 6) * 6} -548 L${x + 40} -536 Z`} fill={C.red} />
          </g>
        ))}
        <path d="M-50 0 L-50 -110 A50 50 0 0 1 50 -110 L50 0 Z" fill="#3a2418" />
      </g>
    </g>
  );
};

const Ships = ({t}) => (
  <g>
    <rect x={0} y={0} width={1080} height={1920} fill="#1d8fd1" />
    {[0, 1, 2].map((k) => {
      const x = ((t - 40.2) * 160 + k * 380) % 1400 - 200;
      const y = 650 + k * 260;
      return (
        <g key={k} transform={`translate(${x} ${y + Math.sin(t * 2 + k) * 8}) scale(${1.2 - k * 0.15})`}>
          <path d="M-110 0 L110 0 L80 50 L-80 50 Z" fill="#8a5a2c" />
          <line x1={0} y1={0} x2={0} y2={-200} stroke="#6b3f1f" strokeWidth={8} />
          <path d="M6 -190 Q90 -120 6 -40 Z" fill="#fff" />
          <path d="M-6 -170 Q-70 -110 -6 -50 Z" fill="#f2efe6" />
          <path d={`M0 -200 L40 -190 L0 -180 Z`} fill={C.red} />
        </g>
      );
    })}
    {Array.from({length: 30}).map((_, i) => (
      <path key={i} d={`M${random(`sx${i}`) * 1080} ${random(`sy${i}`) * 1920} q14 -8 28 0`} fill="none" stroke="#bfe9ff" strokeWidth={4} opacity={0.5} />
    ))}
  </g>
);

const RocketMoon = ({t}) => {
  const up = r(t, 42.2, 43.8, 0, 1, (x) => x * x);
  const y = 1300 - up * 700;
  return (
    <g>
      <circle cx={760} cy={560} r={150} fill="#e8e8f0" />
      <circle cx={710} cy={520} r={26} fill="#c9ccd6" />
      <circle cx={800} cy={610} r={18} fill="#c9ccd6" />
      <g transform={`translate(${540 + up * 200} ${y}) rotate(${up * 30})`}>
        <path d="M0 -110 C30 -70 30 0 22 40 L-22 40 C-30 0 -30 -70 0 -110 Z" fill="#f2f5fa" />
        <circle cx={0} cy={-40} r={13} fill="#5ec8ff" stroke="#9aa3b8" strokeWidth={4} />
        <path d="M-22 10 L-46 50 L-22 40 Z" fill={C.red} />
        <path d="M22 10 L46 50 L22 40 Z" fill={C.red} />
        <path d={`M-16 40 Q0 ${110 + Math.sin(t * 30) * 20} 16 40 Z`} fill="#ffb02e" />
      </g>
      {t > 43.2 ? (
        <g transform={`translate(760 412) scale(${r(t, 43.2, 43.5, 0, 1, BACK)})`}>
          <line x1={0} y1={0} x2={0} y2={-70} stroke="#fff" strokeWidth={5} />
          <rect x={0} y={-70} width={50} height={32} fill={C.accent} />
          <text x={25} y={-46} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={22} fill="#0b0b14">
            A
          </text>
        </g>
      ) : null}
    </g>
  );
};

const Stars = ({t}) => (
  <g>
    {Array.from({length: 260}).map((_, i) => {
      const a = random(`ga${i}`) * Math.PI * 2;
      const d = Math.pow(random(`gd${i}`), 0.6) * 420;
      const arm = a + d / 120 + t * 0.15;
      return <circle key={i} cx={540 + Math.cos(arm) * d} cy={800 + Math.sin(arm) * d * 0.45} r={1.5 + random(`gr${i}`) * 2.5} fill={i % 7 ? '#fff' : '#ffd27a'} opacity={0.8} />;
    })}
    <circle cx={540} cy={800} r={60} fill="#fff3c4" opacity={0.6} style={{filter: 'blur(18px)'}} />
    {[0, 1, 2, 3, 4].map((k) => {
      const a = random(`col${k}`) * Math.PI * 2;
      const d = 150 + random(`cod${k}`) * 250;
      const s = r(t, 44.5 + k * 0.2, 44.8 + k * 0.2, 0, 1, BACK);
      return (
        <g key={k} transform={`translate(${540 + Math.cos(a) * d} ${800 + Math.sin(a) * d * 0.45}) scale(${s})`}>
          <circle r={16} fill={C.accent} opacity={0.35} />
          <circle r={7} fill={C.accent} />
        </g>
      );
    })}
  </g>
);

const BeyondScene = () => {
  const t = useT();
  const part = t < 38.1 ? 0 : t < 39.15 ? 1 : t < 40.2 ? 2 : t < 42.1 ? 3 : t < 43.85 ? 4 : 5;
  const labels = [
    null,
    ['10.000', 'CIUDAD'],
    ['100.000', 'REINO'],
    ['1 MILLÓN', 'CONQUISTAN EL OCÉANO'],
    ['10 MILLONES', 'LA LUNA'],
    ['¿∞?', 'OTRAS ESTRELLAS'],
  ];
  return (
    <AbsoluteFill>
      {part === 5 ? <SpaceBackground /> : null}
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <defs>
          <linearGradient id="dusk" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#1a1440" />
            <stop offset="1" stopColor="#ff7a59" />
          </linearGradient>
        </defs>
        {part === 0 ? (
          <>
            <Ocean t={t} />
            <IslandWorld t={t} pop={1000} />
          </>
        ) : null}
        {part === 1 ? <Skyline t={t} /> : null}
        {part === 2 ? <Castle t={t} /> : null}
        {part === 3 ? <Ships t={t} /> : null}
        {part === 4 ? (
          <>
            <rect x={0} y={0} width={1080} height={1920} fill="#070b24" />
            <RocketMoon t={t} />
          </>
        ) : null}
        {part === 5 ? <Stars t={t} /> : null}
      </svg>
      {part === 0 ? (
        <>
          <Pop at={35.92} out={36.9} style={{top: 300, left: 0, right: 0}}>
            <BigText size={120}>¿Y DESPUÉS?</BigText>
          </Pop>
          <Pop at={37.04} style={{top: 300, left: 0, right: 0}}>
            <BigText size={120} color={C.accent}>
              SIN LÍMITE
            </BigText>
          </Pop>
        </>
      ) : null}
      {labels[part] ? (
        <div key={part} style={{position: 'absolute', top: 260, left: 0, right: 0, display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
          <Pill color={C.accent} size={48}>
            {labels[part][0]} HABITANTES
          </Pill>
          <BigText size={92} style={{marginTop: 18}}>
            {labels[part][1]}
          </BigText>
        </div>
      ) : null}
    </AbsoluteFill>
  );
};

// =====================================================================
// 5. HABITANTES REALES (46.1 – 58.6 s)
// =====================================================================
const EXAMPLES = [
  {user: '@lucia.mz', text: 'Soy Lucía, ¡quiero ser herrera!', tag: 'LUCÍA · HERRERA', k: 5},
  {user: '@marcos_r', text: 'Marcos, ¡quiero ser pescador!', tag: 'MARCOS · PESCADOR', k: 11},
];

const RealScene = () => {
  const t = useT();
  const zoom = r(t, 53.7, 56.3, 1.0, 1.35, INOUT);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <Camera zoom={zoom} fx={540} fy={1000} cy={1010}>
          <IslandWorld
            t={t}
            pop={120}
            tags={[
              ...(t > 56.36 ? [{k: EXAMPLES[0].k, label: EXAMPLES[0].tag}] : []),
              ...(t > 56.9 ? [{k: EXAMPLES[1].k, label: EXAMPLES[1].tag}] : []),
            ]}
          />
        </Camera>
      </svg>
      {/* Episodios en fila */}
      <Pop at={46.16} out={49.8} style={{top: 260, left: 40, right: 40}}>
        <div style={{display: 'flex', gap: 18, justifyContent: 'center'}}>
          {['EP 1', 'EP 2', 'EP 3', 'EP 4'].map((ep, i) => (
            <div
              key={ep}
              style={{
                width: 210,
                height: 250,
                borderRadius: 24,
                background: i === 0 ? C.accent : 'rgba(8,12,30,0.85)',
                border: '4px solid rgba(255,255,255,0.3)',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                fontFamily: FONT,
                fontWeight: 900,
                color: i === 0 ? '#0b0b14' : '#fff',
                scale: String(r(t, 46.3 + i * 0.25, 46.6 + i * 0.25, 0, 1, BACK)),
              }}
            >
              <div style={{fontSize: 38}}>{ep}</div>
              <div style={{fontSize: 90}}>{i === 0 ? '1' : '?'}</div>
              <div style={{fontSize: 22}}>HABITANTES</div>
            </div>
          ))}
        </div>
      </Pop>
      <Pop at={51.52} style={{top: 240, left: 0, right: 0}}>
        <BigText size={92}>
          LOS HABITANTES
          <br />
          SON <span style={{color: C.accent}}>REALES</span>
        </BigText>
      </Pop>
      {EXAMPLES.map((c, i) => (
        <Pop key={c.user} at={53.76 + i * 0.5} out={56.2} style={{top: 470 + i * 130, left: 60, right: 60}}>
          <div
            style={{
              width: '100%',
              display: 'flex',
              alignItems: 'center',
              gap: 18,
              background: 'rgba(8,12,30,0.88)',
              border: '3px solid rgba(255,255,255,0.2)',
              borderRadius: 26,
              padding: '16px 22px',
              fontFamily: FONT,
              color: '#fff',
            }}
          >
            <div style={{width: 64, height: 64, borderRadius: 32, background: `linear-gradient(135deg, ${C.cyan}, ${C.pink})`}} />
            <div>
              <div style={{fontSize: 24, fontWeight: 800, color: '#b9c3dd'}}>{c.user}</div>
              <div style={{fontSize: 36, fontWeight: 800}}>{c.text}</div>
            </div>
          </div>
        </Pop>
      ))}
      <Pop at={56.36} style={{top: 1240, left: 0, right: 0}}>
        <Pill color={C.green} size={44}>
          ¡SALES EN EL PRÓXIMO EPISODIO!
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 6. AHORA MISMO: solo y esperando (58.6 – 64.1 s)
// =====================================================================
const NightScene = () => {
  const t = useT();
  const pop = t < 59.6 ? popScale(t, 58.7, 59.5, 1000, 1) : 1;
  const zoom = r(t, 58.7, 63.8, 1.3, 3.2, INOUT);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={1} />
        <Camera zoom={zoom} fx={575} fy={975} cy={900}>
          <IslandWorld t={t} pop={1} />
          <rect x={0} y={0} width={1080} height={1920} fill="#050a2a" opacity={0.45} />
          <circle cx={540} cy={975} r={150} fill="#ffb347" opacity={0.22 + 0.05 * Math.sin(t * 9)} style={{filter: 'blur(20px)'}} />
          <Fire x={540} y={975} t={t} s={1} />
          <Villager x={590} y={990} t={t} seed={0} s={1.5} />
        </Camera>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={pop} label="EP" />
      </div>
      <Pop at={58.72} out={61.5} style={{top: 400, left: 0, right: 0}}>
        <BigText size={96}>AHORA MISMO…</BigText>
      </Pop>
      <Pop at={63.28} style={{top: 400, left: 0, right: 0}}>
        <BigText size={96} color={C.cyan}>
          ESPERANDO
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 7. CIERRE: habitante nº 2 y nombre de la civilización (64.1 – 75.3 s)
// =====================================================================
const NAMES = [
  {user: '@curioso_23', text: 'Aprendia', base: 520},
  {user: '@ana.rv', text: 'Nueva Aurora', base: 410},
  {user: '@leo_x', text: 'Isla Nova', base: 300},
];

const OutroScene = () => {
  const t = useT();
  const tap = t > 65.9 && t < 66.2 ? 0.9 : 1;
  const tapped = t > 66.05;
  const pop = tapped ? 2 : 1;
  const up = r(t, 67.6, 68.2, 0, 1, INOUT);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={0.6} />
        <Camera zoom={2.2} fx={560} fy={985} cy={1000 - up * 140}>
          <IslandWorld t={t} pop={pop} />
        </Camera>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud label="EP" pop={pop} highlight={tapped ? lin(t, 66.05, 67.5, 1, 0) : 0} />
      </div>
      <Pop at={64.24} out={67.6} style={{top: 400, left: 0, right: 0, flexDirection: 'column'}}>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 16,
            padding: '24px 70px',
            borderRadius: 80,
            background: tapped ? 'rgba(255,255,255,0.25)' : C.pink,
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: 64,
            color: '#fff',
            scale: String(tap),
            boxShadow: tapped ? 'none' : `0 0 ${40 + 20 * Math.sin(t * 6)}px ${C.pink}`,
          }}
        >
          {tapped ? <Check size={64} /> : '+'} {tapped ? 'SIGUIENDO' : 'SEGUIR'}
        </div>
      </Pop>
      <Pop at={66.4} out={67.6} style={{top: 560, left: 0, right: 0}}>
        <BigText size={84} color={C.accent}>
          ¡HABITANTE Nº 2!
        </BigText>
      </Pop>

      <Pop at={67.9} style={{top: 400, left: 40, right: 40}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 16, fontFamily: FONT, fontWeight: 900, fontSize: 44, color: '#fff', background: 'rgba(8,12,30,0.85)', borderRadius: 30, padding: '14px 24px'}}>
          <svg width={64} height={60} viewBox="0 0 74 70">
            <path d="M8 6 H66 Q70 6 70 10 V46 Q70 50 66 50 H30 L14 64 V50 H8 Q4 50 4 46 V10 Q4 6 8 6 Z" fill={C.cyan} />
          </svg>
          ¿CÓMO SE LLAMA NUESTRA CIVILIZACIÓN?
        </div>
      </Pop>
      {NAMES.map((c, i) => (
        <Pop key={c.user} at={69.4 + i * 0.3} style={{top: 540 + i * 130, left: 60, right: 60}}>
          <NameCard t={t} c={c} winner={i === 0} />
        </Pop>
      ))}
      <Pop at={73.36} style={{top: 640, left: 0, right: 0}}>
        <div
          style={{
            rotate: '-8deg',
            border: `10px solid ${C.red}`,
            borderRadius: 24,
            padding: '10px 36px',
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: 76,
            color: C.red,
            background: 'rgba(255,255,255,0.92)',
          }}
        >
          ¡NOMBRE OFICIAL!
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

const NameCard = ({t, c, winner}) => {
  const grow = lin(t, 69.4, 75.3, 0, 1);
  const boost = winner ? r(t, 71.84, 72.8, 0, 1) : 0;
  const likes = Math.round(c.base * (1 + grow * 2) + boost * 8000);
  const likeTxt = likes >= 1000 ? `${(likes / 1000).toFixed(1).replace('.', ',')} K` : String(likes);
  const hl = winner && t > 71.84;
  return (
    <div
      style={{
        width: '100%',
        boxSizing: 'border-box',
        display: 'flex',
        alignItems: 'center',
        gap: 18,
        background: hl ? 'rgba(255,210,63,0.2)' : 'rgba(8,12,30,0.88)',
        border: `4px solid ${hl ? C.accent : 'rgba(255,255,255,0.15)'}`,
        borderRadius: 26,
        padding: '14px 22px',
        fontFamily: FONT,
        color: '#fff',
      }}
    >
      <div style={{width: 60, height: 60, borderRadius: 30, background: `linear-gradient(135deg, ${C.cyan}, ${C.pink})`, flexShrink: 0}} />
      <div style={{flex: 1}}>
        <div style={{fontSize: 24, fontWeight: 800, color: '#b9c3dd', display: 'flex', gap: 10, alignItems: 'center'}}>
          {c.user}
          {hl ? <span style={{background: C.accent, color: '#0b0b14', borderRadius: 10, padding: '2px 10px', fontSize: 20, fontWeight: 900}}>MÁS VOTADO</span> : null}
        </div>
        <div style={{fontSize: 40, fontWeight: 900}}>{c.text}</div>
      </div>
      <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
        <Heart size={42} color={hl ? C.pink : '#c9cfe0'} />
        <div style={{fontWeight: 900, fontSize: 24}}>{likeTxt}</div>
      </div>
    </div>
  );
};

// =====================================================================
export const Episodio01 = () => (
  <AbsoluteFill style={{backgroundColor: '#0d4f8f'}}>
    <Scene name="Isla vacía" start={0} end={9.2}>
      <IntroScene />
    </Scene>
    <Scene name="Reglas" start={9.2} end={18.0}>
      <RulesScene />
    </Scene>
    <Scene name="Crecimiento" start={18.0} end={35.9}>
      <GrowthScene />
    </Scene>
    <Scene name="Sin límite" start={35.9} end={46.1}>
      <BeyondScene />
    </Scene>
    <Scene name="Habitantes reales" start={46.1} end={58.6}>
      <RealScene />
    </Scene>
    <Scene name="Esperando" start={58.6} end={64.1}>
      <NightScene />
    </Scene>
    <Scene name="Cierre" start={64.1} end={DURATION} fadeOut={false}>
      <OutroScene />
    </Scene>
    <Brand hideAt={DURATION} />
    <ProgressBar />
    <Captions chunks={CHUNKS} />
    <Audio src={staticFile('civilizacion-01.mp3')} />
  </AbsoluteFill>
);
