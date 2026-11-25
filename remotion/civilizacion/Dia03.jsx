import React from 'react';
import {AbsoluteFill, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, Scene, lin, r, useT} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, Check, Heart, ProgressBar} from '../tunel/Visuals';
import {Hud, IslandWorld, Ocean, Villager, popScale} from './Island';
import {makeW} from './words';
import WORDS from '../../public/civilizacion-03.words.json';

const W = makeW(WORDS);
export const DURATION = WORDS[WORDS.length - 1].end + 0.8;
const DAY = 3;
const PREV = 58;
const POP = 167; // 1 fundador + 93 TikTok + 73 Instagram

const CHUNKS = chunkWords(WORDS, [
  'tres', 'ocho', 'siete', 'tribu', 'aldea', 'chozas', 'campos', 'animales', 'pozo', 'historia',
  'jefe', 'dylan', 'visionario', 'autoridad', 'ideas', 'regla', 'likes', 'realidad', 'sacapuntas',
  'inoxidable', 'gigante', 'trece', 'futuro', 'manos', 'construcción', 'invento', 'desastre',
  'mañana', 'pueblo', 'aprende',
]);

// Comentarios del Día 2 (resumidos). Se excluyen los inapropiados o políticos.
const COMMENTS = [
  ['dylnxz_', 'Quiero liderar con ideas', 12],
  ['sacapuntas_de_acero_inoxidable', 'sacapuntas de acero inoxidable', 11],
  ['Err Balaa', 'Una isla segura, organizada y próspera', 9],
  ['teseracto34', 'Protejo la costa de invasores', 8],
  ['samiravargas__', 'Con los cazadores traemos comida', 2],
  ['luisda_rss010', 'Construir botes y explorar el océano', 1],
  ['hechybenavides', 'Soy Yesi y quiero ser princesa', 1],
  ['mateo_bojorquez', 'El chistoso de la isla', 1],
  ['diego_palian', 'Quiero ser minero', 1],
  ['elpatron._93', 'Prometo bajar los precios', 1],
  ['emmanuelreyes0841', 'Ángel Reyes se compromete', 1],
  ['David.cr', 'Un cocodrilo grande ofensivo', 1],
  ['Micael brawl', 'Soy constructor', 1],
  ['Leovr', 'El jefe debe ser el primero', 1],
  ['k.l.4.5.6', 'Cultivador y pastor', 0],
  ['vic._.tor_03', 'Quiero ser el médico', 0],
  ['esdras__rmos', 'Quiero ser explorador', 0],
  ['j____lugo', 'Quiero ser batmannn', 0],
  ['jazmin_star8', 'Quiero ser enfermera', 0],
  ['sktesponjax_', 'Marcela, científica', 0],
  ['gerardo._.pv', 'Os sacaré de la pobreza', 0],
  ['shesho_rb', 'Presidente y prota', 0],
  ['chris42011_011', 'Mejor economía, barcos y casas', 0],
  ['lyxs_npc', 'Entro como cocinero', 0],
  ['ayderg21', 'Ayde, la chef', 0],
  ['victor_rb99', 'Debo ser el jefe porque sí', 0],
  ['Ana', 'Quiero ser gimnasta', 0],
  ['Pabloespiurb013', 'Ciclista de trucos', 0],
  ['Parisinho', 'Minero con perro pastor alemán', 0],
  ['beltri', 'Quiero un patinete', 0],
  ['Iker_fishing', 'Pescadorrr', 0],
  ['Alberto_sg', 'Quiero ser militar', 0],
  ['BM', 'Votadme: 40% de descuento', 0],
  ['Jose', 'Guardián del fuego', 0],
  ['pericles2016', 'Hago de todo, dadle like', 0],
  ['Al3x_012qlss', 'Quiero ser obrero', 0],
  ['pablitoo_613', 'Pablo, pescador', 0],
  ['Diego_Bustos010', 'Quiero ser soldado', 0],
  ['Realista', 'Escuelas, granjas y barcos', 0],
  ['alexburgos', 'Alex, explorador', 0],
  ['LeoSR8', 'Un parque de atracciones', 0],
  ['dylan noel', 'El mejor cocinero del mundo', 0],
  ['Psicólogo', 'Psicólogo y biólogo de la isla', 0],
];

const ISLAND_CAM = (t, zoom, cy = 900) => `translate(540 ${cy}) scale(${zoom}) translate(-540 -975)`;

// =====================================================================
// 1. MURO DE COMENTARIOS + DE TRIBU A ALDEA
// =====================================================================
const CommentWall = ({t, from, to}) => {
  if (t < from - 0.2 || t > to + 0.4) return null;
  const speed = 700; // px por segundo
  const rowH = 118;
  const scroll = (t - from) * speed;
  const o = Math.min(lin(t, from - 0.2, from + 0.1, 0, 1), lin(t, to, to + 0.4, 1, 0));
  return (
    <AbsoluteFill style={{opacity: o}}>
      <AbsoluteFill style={{background: 'linear-gradient(rgba(5,10,42,0.85), rgba(5,10,42,0.55) 50%, rgba(5,10,42,0.85))'}} />
      {COMMENTS.map(([user, text, likes], i) => {
        const y = 1500 + i * rowH - scroll;
        if (y < 300 || y > 1500) return null;
        const side = i % 2 ? 1 : -1;
        const enter = lin(-y, -1500, -1330, 0, 1);
        return (
          <div
            key={user + i}
            style={{
              position: 'absolute',
              top: y,
              left: 60 + (i % 2) * 40,
              right: 100 - (i % 2) * 40,
              display: 'flex',
              alignItems: 'center',
              gap: 16,
              background: i < 2 ? 'rgba(255,210,63,0.22)' : 'rgba(8,12,30,0.92)',
              border: `3px solid ${i < 2 ? C.accent : 'rgba(255,255,255,0.18)'}`,
              borderRadius: 24,
              padding: '10px 18px',
              fontFamily: FONT,
              color: '#fff',
              translate: `${side * (1 - enter) * 300}px 0`,
              rotate: `${side * (1 - enter) * 6}deg`,
              opacity: enter * lin(y, 300, 420, 0, 1),
            }}
          >
            <div style={{width: 52, height: 52, borderRadius: 26, flexShrink: 0, background: `linear-gradient(135deg, ${i % 3 ? C.cyan : C.accent}, ${C.pink})`}} />
            <div style={{flex: 1, minWidth: 0}}>
              <div style={{fontSize: 22, fontWeight: 800, color: '#b9c3dd', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'}}>@{user}</div>
              <div style={{fontSize: 32, fontWeight: 900, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'}}>{text}</div>
            </div>
            {likes > 0 ? (
              <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
                <Heart size={34} color={C.pink} />
                <div style={{fontWeight: 900, fontSize: 20}}>{likes}</div>
              </div>
            ) : null}
          </div>
        );
      })}
    </AbsoluteFill>
  );
};

const VillageScene = () => {
  const t = useT();
  const pop = t < W('hoy') ? PREV : popScale(t, W('hoy'), W('siete') + 0.4, PREV, POP);
  const zoom = r(t, W('tribu'), W('aldea') + 0.4, 1.35, 1.0, INOUT);
  const items = [
    ['chozas', 'CHOZAS', '#d9b382'],
    ['campos', 'CAMPOS', '#e8c547'],
    ['animales', 'ANIMALES', '#fff'],
    ['pozo', 'POZO DE AGUA', C.cyan],
  ];
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <g transform={ISLAND_CAM(t, zoom)}>
          <IslandWorld t={t} pop={pop} maxShown={60} />
          <Villager x={560} y={712} t={t} seed={7} s={1.5} shirt="#a78bfa" />
          <ellipse cx={560} cy={716} rx={30} ry={12} fill="#9aa3b8" />
        </g>
      </svg>
      <CommentWall t={t} from={W('ayer') - 0.2} to={W('y', 2) - 0.1} />
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={pop} day={DAY} highlight={t > W('hoy') && t < W('siete') + 0.6 ? 0.8 : 0} />
      </div>
      <Pop at={0} out={W('ayer') - 0.3} style={{top: 700, left: 0, right: 0}}>
        <BigText size={170} color={C.accent} stroke={14}>
          DÍA {DAY}
        </BigText>
      </Pop>
      <Pop at={W('somos', 2) - 0.1} style={{top: 380, left: 0, right: 0, flexDirection: 'column'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 18}}>
          <BigText size={64} style={{textDecoration: 'line-through', opacity: 0.7}}>
            TRIBU
          </BigText>
          <BigText size={64}>→</BigText>
          <BigText size={110} color={C.green}>
            ALDEA
          </BigText>
        </div>
      </Pop>
      {items.map(([w, label, col], i) => (
        <Pop key={w} at={W(w) - 0.05} out={W('así') - 0.2} style={{top: 1180 - i * 0, left: 70 + (i % 2) * 520, ...(i > 1 ? {top: 1260} : {})}}>
          <Pill color={col} size={40}>
            {label}
          </Pill>
        </Pop>
      ))}
      <Pop at={W('así') - 0.1} out={W('y', 4) - 0.2} style={{top: 520, left: 60, right: 60}}>
        <FactCard title="DATO" text="Çatalhöyük (Turquía): miles de habitantes hace más de 9.000 años" />
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
// 2. EL NUEVO JEFE: DYLAN
// =====================================================================
const LeaderScene = () => {
  const t = useT();
  const reveal = W('dylan');
  const crownY = r(t, reveal, reveal + 0.7, -700, 0, BACK);
  const drum = t < reveal ? Math.sin(t * 40) * lin(t, W('nuevo'), reveal, 0, 10) : 0;
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={t < reveal ? 0.7 : 0.3} />
        <g transform={ISLAND_CAM(t, r(t, W('y', 4), reveal + 0.8, 1, 2.6, INOUT), 960)} opacity={0.9}>
          <IslandWorld t={t} pop={POP} maxShown={60} />
        </g>
        {t > reveal - 0.1 ? (
          <g>
            {Array.from({length: 14}).map((_, k) => (
              <line
                key={k}
                x1={540}
                y1={900}
                x2={540 + Math.cos((k / 14) * Math.PI * 2 + t * 0.4) * 900}
                y2={900 + Math.sin((k / 14) * Math.PI * 2 + t * 0.4) * 900}
                stroke="#fff6c2"
                strokeWidth={50}
                opacity={0.08}
              />
            ))}
          </g>
        ) : null}
        <ellipse cx={540} cy={1180} rx={190} ry={50} fill="#9aa3b8" />
        <g transform={`translate(${drum} 0)`} opacity={t < reveal ? 0.25 : 1}>
          <Villager x={540} y={1150} t={t} seed={7} s={7} shirt="#a78bfa" wave={t > reveal ? 70 + Math.sin(t * 6) * 15 : 0} />
        </g>
        {t > reveal ? (
          <g transform={`translate(540 ${770 + crownY + Math.sin(t * 4) * 8}) scale(2.2)`}>
            <path d="M-40 26 L-40 -14 L-20 6 L0 -26 L20 6 L40 -14 L40 26 Z" fill={C.accent} stroke="#05060f" strokeWidth={5} strokeLinejoin="round" />
            <circle cx={0} cy={10} r={6} fill={C.red} />
          </g>
        ) : (
          <text x={540} y={830} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={220} fill="#fff" opacity={0.85}>
            ?
          </text>
        )}
      </svg>
      <Pop at={W('y', 4)} out={reveal - 0.1} style={{top: 400, left: 0, right: 0}}>
        <BigText size={96}>
          EL NUEVO JEFE
          <br />
          ES…
        </BigText>
      </Pop>
      <Pop at={reveal} style={{top: 380, left: 0, right: 0, flexDirection: 'column'}}>
        <BigText size={150} color={C.accent} stroke={14}>
          DYLAN
        </BigText>
        <div style={{display: 'flex', gap: 14, marginTop: 10}}>
          <Pill color="#a78bfa" size={40}>
            EL VISIONARIO
          </Pill>
          <Pill color={C.pink} text="#fff" size={40}>
            ♥ 12
          </Pill>
        </div>
      </Pop>
      <Pop at={W('prometió') + 0.3} style={{top: 1220, left: 70, right: 70}}>
        <div
          style={{
            width: '100%',
            background: 'linear-gradient(#f6e7c1, #e9d29b)',
            border: '6px solid #8a5a2c',
            borderRadius: 20,
            padding: '18px 26px',
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: 40,
            color: '#3a2418',
            textAlign: 'center',
            lineHeight: 1.2,
          }}
        >
          “No quiero mandar por autoridad.
          <br />
          Quiero liderar con ideas.”
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 3. LA REGLA Y EL SACAPUNTAS GIGANTE
// =====================================================================
const Sharpener = ({s = 1, t}) => (
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

const SharpenerScene = () => {
  const t = useT();
  const land = W('aquí');
  const drop = r(t, land, land + 0.55, -1400, 0, (x) => x * x);
  const shake = t > land + 0.55 && t < land + 1.0 ? Math.sin(t * 80) * lin(t, land + 0.55, land + 1.0, 14, 0) : 0;
  return (
    <AbsoluteFill style={{translate: `${shake}px ${shake * 0.5}px`}}>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <g transform={ISLAND_CAM(t, r(t, land, land + 1.2, 1.0, 1.5, INOUT), 920)}>
          <IslandWorld t={t} pop={POP} maxShown={60} />
          {t > land ? (
            <g transform={`translate(560 ${930 + drop})`}>
              <Sharpener s={1.6} t={t} />
            </g>
          ) : null}
          {t > land + 0.55 && t < land + 1.6 ? (
            <ellipse cx={560} cy={935} rx={lin(t, land + 0.55, land + 1.6, 40, 260)} ry={lin(t, land + 0.55, land + 1.6, 12, 70)} fill="none" stroke="#f2d79b" strokeWidth={10} opacity={lin(t, land + 0.55, land + 1.6, 0.9, 0)} />
          ) : null}
        </g>
      </svg>
      <Pop at={W('pero') - 0.1} out={W('y', 6) - 0.2} style={{top: 400, left: 60, right: 60, flexDirection: 'column'}}>
        <Pill color="#fff" size={44}>
          LA REGLA
        </Pill>
        <BigText size={64} style={{marginTop: 14}}>
          EL COMENTARIO CON
          <br />
          <span style={{color: C.pink}}>MÁS LIKES</span> SE HACE
          <br />
          <span style={{color: C.accent}}>REALIDAD</span>
        </BigText>
      </Pop>
      <Pop at={W('segundo') - 0.1} out={land - 0.1} style={{top: 420, left: 60, right: 60, flexDirection: 'column'}}>
        <BigText size={56}>2º MÁS VOTADO</BigText>
        <div
          style={{
            width: '100%',
            boxSizing: 'border-box',
            marginTop: 16,
            display: 'flex',
            alignItems: 'center',
            gap: 18,
            background: 'rgba(8,12,30,0.92)',
            border: `4px solid ${C.accent}`,
            borderRadius: 26,
            padding: '14px 22px',
            fontFamily: FONT,
            color: '#fff',
          }}
        >
          <div style={{width: 64, height: 64, borderRadius: 32, background: 'linear-gradient(135deg, #c9d1e0, #7d8597)', flexShrink: 0}} />
          <div style={{flex: 1, minWidth: 0}}>
            <div style={{fontSize: 22, fontWeight: 800, color: '#b9c3dd', whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis'}}>@sacapuntas_de_acero_inoxidable</div>
            <div style={{fontSize: 40, fontWeight: 900}}>sacapuntas de acero inoxidable</div>
          </div>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
            <Heart size={44} color={C.pink} />
            <div style={{fontWeight: 900, fontSize: 24}}>11</div>
          </div>
        </div>
      </Pop>
      <Pop at={W('gigante') - 0.1} out={W('aunque') - 0.2} style={{top: 400, left: 0, right: 0}}>
        <BigText size={100} color={C.accent}>
          ¡HECHO REALIDAD!
        </BigText>
      </Pop>
      <Pop at={W('aunque') - 0.05} style={{top: 400, left: 60, right: 60}}>
        <FactCard title="DATO" text="El acero inoxidable se inventó en 1913" />
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 4. ¿QUÉ PASA MAÑANA? TÚ DECIDES
// =====================================================================
const IDEAS = [
  ['construcción', '¿UN CASTILLO?', C.cyan, -1],
  ['invento', '¿UN INVENTO?', C.accent, 1],
  ['desastre', '¿UN VOLCÁN?', C.red, -1],
  ['sea', '¿UN DRAGÓN?', C.green, 1],
];

const TomorrowScene = () => {
  const t = useT();
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={0.5} />
        <g transform={ISLAND_CAM(t, 1.0, 1000)}>
          <IslandWorld t={t} pop={POP} maxShown={60} />
          <g transform="translate(560 930)">
            <Sharpener s={1.2} t={t} />
          </g>
        </g>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={POP} day={DAY} />
      </div>
      <Pop at={W('futuro') - 0.2} style={{top: 380, left: 0, right: 0, flexDirection: 'column'}}>
        <BigText size={90}>
          ¿QUÉ PASA
          <br />
          <span style={{color: C.accent}}>MAÑANA?</span>
        </BigText>
        <div style={{marginTop: 14}}>
          <Pill color={C.pink} text="#fff" size={44}>
            TÚ DECIDES
          </Pill>
        </div>
      </Pop>
      {IDEAS.map(([w, label, col, side], i) => (
        <Pop key={w} at={W(w) - 0.05} style={{top: 1180 + (i % 2) * 0, left: side < 0 ? 60 : 560, ...(i > 1 ? {top: 1270} : {})}}>
          <div style={{rotate: `${side * 4}deg`}}>
            <Pill color={col} size={40} text={col === C.red ? '#fff' : '#0b0b14'}>
              {label}
            </Pill>
          </div>
        </Pop>
      ))}
      <Pop at={W('pasará') - 0.1} style={{top: 760, left: 60, right: 60}}>
        <div
          style={{
            width: '100%',
            boxSizing: 'border-box',
            display: 'flex',
            alignItems: 'center',
            gap: 18,
            background: 'rgba(255,210,63,0.22)',
            border: `5px solid ${C.accent}`,
            borderRadius: 28,
            padding: '16px 24px',
            fontFamily: FONT,
            color: '#fff',
          }}
        >
          <Heart size={64} color={C.pink} />
          <div style={{fontSize: 44, fontWeight: 900}}>MÁS LIKES = PASA MAÑANA</div>
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 5. CIERRE
// =====================================================================
const OutroScene = () => {
  const t = useT();
  const tapAt = W('sígueme') + 0.4;
  const tap = t > tapAt - 0.15 && t < tapAt + 0.15 ? 0.9 : 1;
  const tapped = t > tapAt;
  const pop = POP + (tapped ? 1 : 0);
  const fill = r(t, W('faltan') + 0.1, W('faltan') + 1.3, 0, POP / 1000);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <g transform={ISLAND_CAM(t, 1.05, 950)}>
          <IslandWorld t={t} pop={pop} maxShown={60} />
          <g transform="translate(560 930)">
            <Sharpener s={1.2} t={t} />
          </g>
        </g>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={pop} day={DAY} highlight={tapped ? lin(t, tapAt, tapAt + 1.2, 1, 0) : 0} />
      </div>
      <Pop at={W('faltan')} out={W('sígueme') - 0.2} style={{top: 390, left: 70, right: 70, flexDirection: 'column'}}>
        <div style={{width: '100%', height: 54, borderRadius: 30, background: 'rgba(8,12,30,0.85)', border: '4px solid #fff', overflow: 'hidden'}}>
          <div style={{width: `${fill * 100}%`, height: '100%', background: `linear-gradient(90deg, ${C.green}, ${C.accent})`}} />
        </div>
        <div style={{display: 'flex', justifyContent: 'space-between', width: '100%', fontFamily: FONT, fontWeight: 900, fontSize: 32, color: '#fff', marginTop: 8, textShadow: '0 3px 10px #000'}}>
          <span>ALDEA · 167</span>
          <span>PUEBLO · 1.000</span>
        </div>
        <BigText size={72} color={C.accent} style={{marginTop: 10}}>
          ¡FALTAN 833!
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
export const Dia03 = () => (
  <AbsoluteFill style={{backgroundColor: '#0d4f8f'}}>
    <Scene name="De tribu a aldea" start={0} end={W('y', 4) - 0.3} fadeOut={false}>
      <VillageScene />
    </Scene>
    <Scene name="El nuevo jefe" start={W('y', 4) - 0.3} end={W('pero') - 0.3}>
      <LeaderScene />
    </Scene>
    <Scene name="Sacapuntas" start={W('pero') - 0.3} end={W('y', 7) - 0.3}>
      <SharpenerScene />
    </Scene>
    <Scene name="¿Qué pasa mañana?" start={W('y', 7) - 0.3} end={W('faltan') - 0.3}>
      <TomorrowScene />
    </Scene>
    <Scene name="Cierre" start={W('faltan') - 0.3} end={DURATION} fadeOut={false}>
      <OutroScene />
    </Scene>
    <Brand hideAt={DURATION} />
    <ProgressBar />
    <Captions chunks={CHUNKS} />
    <Audio src={staticFile('civilizacion-03.mp3')} />
  </AbsoluteFill>
);
