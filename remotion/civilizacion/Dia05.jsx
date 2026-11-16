import React from 'react';
import {AbsoluteFill, Img, random, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, Scene, lin, r, useT} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, Heart, ProgressBar} from '../tunel/Visuals';
import {Hud, IslandWorld, Ocean, Villager, popScale} from './Island';
import {Landmarks, SPOTS} from './Landmarks';
import {makeWa} from './words';
import WORDS from '../../public/civilizacion-05.words.json';

const Wa = makeWa(WORDS);
export const DURATION = WORDS[WORDS.length - 1].end + 0.9;
const DAY = 5;
const PREV = 188;
const POP = 265; // 1 fundador + 108 TikTok + 91 Instagram + 65 YouTube
const BIG = 1.35;

// Coco dorado escondido: segundos en los que aparece
export const COCO = [21.0, 22.5];

const CHUNKS = chunkWords(WORDS, [
  'cinco', 'dos', 'días', 'dylan', 'sesenta', 'cinco', 'siete', 'muralla', 'ejército', 'trabajar',
  'piedras', 'lanzas', 'hondas', 'escudos', 'jericó', 'mil', 'noche', 'velas', 'negras', 'cerca',
  'débil', 'sur', 'abierta', 'youtube', 'aprendedconmigo', 'años', 'marianas', 'coco', 'dorado',
  'escondido', 'segundo', 'exacto', 'próximo',
]);

const cam = (zoom, fx = 540, fy = 975, cy = 960) => `translate(540 ${cy}) scale(${zoom}) translate(${-fx} ${-fy})`;

// ---------- Muralla alrededor de la isla, con hueco en la playa del sur ----------
const WALL_RX = 450 * BIG - 40;
const WALL_RY = 300 * BIG - 34;
const GAP = [Math.PI * 0.38, Math.PI * 0.62]; // abajo (sur)
const BLOCKS = Array.from({length: 64}).map((_, i) => (i / 64) * Math.PI * 2 - Math.PI / 2);

const Wall = ({k, night = 0}) => (
  <g>
    {BLOCKS.map((a, i) => {
      const norm = (a + Math.PI * 2) % (Math.PI * 2);
      if (norm > GAP[0] && norm < GAP[1]) return null;
      if (i / BLOCKS.length > k) return null;
      const x = 540 + Math.cos(a) * WALL_RX;
      const y = 975 + Math.sin(a) * WALL_RY;
      const ang = (Math.atan2(Math.cos(a) * WALL_RY, -Math.sin(a) * WALL_RX) * 180) / Math.PI;
      const tower = i % 8 === 0;
      return (
        <g key={i} transform={`translate(${x} ${y}) rotate(${ang})`}>
          <rect x={-30} y={tower ? -46 : -26} width={60} height={tower ? 46 : 26} fill={night ? '#6b6f80' : '#a8a29a'} stroke="#5a554d" strokeWidth={3} />
          {[-20, 0, 20].map((dx) => (
            <rect key={dx} x={dx - 6} y={(tower ? -46 : -26) - 10} width={12} height={10} fill={night ? '#6b6f80' : '#a8a29a'} stroke="#5a554d" strokeWidth={2} />
          ))}
        </g>
      );
    })}
  </g>
);

// Aldeanos entrenando con lanzas en la playa
const Trainees = ({t}) => (
  <g>
    {Array.from({length: 7}).map((_, i) => {
      const x = 300 + i * 70;
      const y = 1230 + (i % 2) * 22;
      const thrust = Math.max(0, Math.sin(t * 6 + i * 0.9)) * 14;
      return (
        <g key={i}>
          <Villager x={x} y={y} t={t} seed={i + 40} s={1.4} shirt={['#8a5a2c', '#a0703f', '#6b4428'][i % 3]} wave={thrust * 2} />
          <line x1={x + 14 + thrust} y1={y - 30} x2={x + 46 + thrust} y2={y - 78} stroke="#6b3f1f" strokeWidth={4} />
          <path d={`M${x + 44 + thrust} ${y - 80} l6 -14 l4 16 Z`} fill="#c9d1e0" />
        </g>
      );
    })}
  </g>
);

const Carriers = ({t}) => (
  <g>
    {Array.from({length: 6}).map((_, i) => {
      const u = (t * 0.12 + i / 6) % 1;
      const a = -Math.PI / 2 + (i % 2 ? -1 : 1) * (0.4 + u * 2.2);
      const x = 540 + Math.cos(a) * (WALL_RX - 70);
      const y = 975 + Math.sin(a) * (WALL_RY - 55);
      return (
        <g key={i}>
          <Villager x={x} y={y} t={t * 2} seed={i + 60} s={1.3} />
          <rect x={x - 12} y={y - 64} width={24} height={16} rx={4} fill="#a8a29a" stroke="#5a554d" strokeWidth={2} />
        </g>
      );
    })}
  </g>
);

const GoldenCoconut = ({x, y, s = 1, t}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <circle r={16} fill="#fff2a8" opacity={0.35 + 0.25 * Math.sin(t * 12)} style={{filter: 'blur(6px)'}} />
    <circle r={10} fill="#e8b923" stroke="#a87b0a" strokeWidth={2} />
    <circle cx={-3} cy={-3} r={3} fill="#fff6c8" />
    {[0, 1, 2].map((k) => (
      <circle key={k} cx={Math.cos(k * 2.1) * 3} cy={2 + Math.sin(k * 2.1) * 3} r={1.4} fill="#7a5a08" />
    ))}
  </g>
);

const Ship = ({x, y, s = 1, o = 1}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`} opacity={o}>
    <path d="M-90 0 L90 0 L66 38 L-66 38 Z" fill="#0b0b14" />
    <line x1={-20} y1={0} x2={-20} y2={-170} stroke="#0b0b14" strokeWidth={8} />
    <path d="M-16 -160 Q50 -110 -16 -40 Z" fill="#111" stroke="#3a3a4a" strokeWidth={2} />
    <circle cx={6} cy={-104} r={12} fill="#e8ecf5" opacity={0.8} />
  </g>
);

// =====================================================================
// 1-3. DÍA 5: el contador, el comentario y la construcción
// =====================================================================
const BuildScene = () => {
  const t = useT();
  const pop = t < Wa('somos') ? PREV : popScale(t, Wa('somos'), Wa('cinco', 6) + 0.4, PREV, POP);
  const wallK = r(t, Wa('mientras', 18), Wa('al') - 0.3, 0, 0.92, (x) => x);
  const zoom = r(t, 0, 3, 0.95, 0.8, INOUT);
  const coco = t >= COCO[0] && t < COCO[1];
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <g transform={cam(zoom)}>
          <IslandWorld t={t} pop={pop} maxShown={60} size={BIG}>
            <Landmarks t={t} />
          </IslandWorld>
          <Wall k={wallK} />
          {t > Wa('mientras', 18) - 0.5 ? (
            <>
              <Carriers t={t} />
              <Trainees t={t} />
            </>
          ) : null}
          {coco ? <GoldenCoconut x={540 + Math.cos(-2.6) * (WALL_RX + 22)} y={975 + Math.sin(-2.6) * (WALL_RY + 22)} s={1} t={t} /> : null}
        </g>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={pop} day={DAY} highlight={t > Wa('somos') && t < Wa('ayer') + 0.5 ? 0.8 : 0} />
      </div>
      <Pop at={0.05} out={Wa('y', 0) - 0.2} style={{top: 380, left: 0, right: 0, flexDirection: 'column'}}>
        <Hourglass t={t} />
        <BigText size={110} color={C.accent}>
          QUEDAN 2 DÍAS
        </BigText>
      </Pop>
      <Pop at={Wa('setenta') - 0.1} out={Wa('el', 9) - 0.2} style={{top: 400, left: 0, right: 0, gap: 12, flexWrap: 'wrap'}}>
        <Pill color="#111" text="#fff" size={36} style={{border: `4px solid ${C.cyan}`}}>
          TIKTOK 108
        </Pill>
        <Pill color="#111" text="#fff" size={36} style={{border: `4px solid ${C.pink}`}}>
          INSTAGRAM 91
        </Pill>
        <Pill color="#dc2626" text="#fff" size={36}>
          YOUTUBE 65
        </Pill>
      </Pop>
      <Pop at={Wa('comentario') - 0.1} out={Wa('mientras', 18) - 0.2} style={{top: 400, left: 60, right: 60, flexDirection: 'column'}}>
        <Pill color={C.accent} size={36}>
          COMENTARIO MÁS VOTADO
        </Pill>
        <div style={{width: '100%', boxSizing: 'border-box', marginTop: 14, display: 'flex', alignItems: 'center', gap: 18, background: 'rgba(8,12,30,0.92)', border: `4px solid ${C.accent}`, borderRadius: 26, padding: '14px 22px', fontFamily: FONT, color: '#fff'}}>
          <div style={{width: 64, height: 64, borderRadius: 32, background: `linear-gradient(135deg, ${C.cyan}, ${C.pink})`, flexShrink: 0}} />
          <div style={{flex: 1}}>
            <div style={{fontSize: 24, fontWeight: 800, color: '#b9c3dd'}}>@joako_ignaxio</div>
            <div style={{fontSize: 40, fontWeight: 900, lineHeight: 1.1}}>Construye una muralla mientras entrena un ejército</div>
          </div>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center'}}>
            <Heart size={50} color={C.pink} />
            <div style={{fontWeight: 900, fontSize: 26}}>14</div>
          </div>
        </div>
      </Pop>
      <Pop at={Wa('mientras', 18)} out={Wa('jericó') - 0.3} style={{top: 400, left: 0, right: 0}}>
        <BigText size={92}>
          ¡A <span style={{color: C.accent}}>TRABAJAR!</span>
        </BigText>
      </Pop>
      <Pop at={Wa('jericó') - 0.1} style={{top: 390, left: 50, right: 50}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 18, background: 'rgba(8,12,30,0.9)', border: `4px solid ${C.accent}`, borderRadius: 28, padding: '16px 24px', fontFamily: FONT, color: '#fff'}}>
          <div style={{background: C.accent, color: '#0b0b14', fontWeight: 900, fontSize: 30, borderRadius: 16, padding: '6px 14px'}}>REAL</div>
          <div style={{fontWeight: 800, fontSize: 36, lineHeight: 1.15}}>Jericó ya tenía muralla de piedra hace unos 10.000 años</div>
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

const Hourglass = ({t}) => {
  const p = 0.55 + Math.sin(t) * 0.02;
  return (
    <svg width={160} height={210} viewBox="-130 -170 260 340">
      <rect x={-110} y={-160} width={220} height={22} rx={8} fill="#a0703f" />
      <rect x={-110} y={138} width={220} height={22} rx={8} fill="#a0703f" />
      <path d="M-90 -138 L90 -138 L12 -6 L12 6 L90 138 L-90 138 L-12 6 L-12 -6 Z" fill="rgba(200,230,255,0.25)" stroke="#e8ecf5" strokeWidth={6} />
      <path d={`M${-80 * (1 - p)} ${-128 + 110 * p} L${80 * (1 - p)} ${-128 + 110 * p} L6 -8 L-6 -8 Z`} fill={C.accent} />
      <path d={`M-80 132 L80 132 L${80 - 50 * p} ${132 - 90 * p} L${-80 + 50 * p} ${132 - 90 * p} Z`} fill={C.accent} />
    </svg>
  );
};

// =====================================================================
// 4. LA NOCHE: las velas y el punto débil
// =====================================================================
const NightScene = () => {
  const t = useT();
  const pan = r(t, Wa('velas') - 0.5, Wa('velas') + 1.5, 0, 1, INOUT);
  const weak = Wa('débil');
  const pulse = t > weak - 0.2 ? 0.5 + 0.5 * Math.sin(t * 8) : 0;
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={1} />
        <g transform={cam(0.8 + pan * 0.05, 540, 975 + pan * 120, 900)}>
          <IslandWorld t={t} pop={POP} maxShown={60} size={BIG}>
            <Landmarks t={t} rock={false} />
          </IslandWorld>
          <Wall k={1} night={1} />
          <ellipse cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y + 4} rx={30} ry={12} fill="#9aa3b8" />
          <Villager x={SPOTS.dylanRock.x} y={SPOTS.dylanRock.y} t={t} seed={7} s={1.7} shirt="#a78bfa" crown wave={50} />
          <rect x={-1000} y={-1000} width={3000} height={4000} fill="#050a2a" opacity={0.35} />
          {[0, 1, 2].map((k) => (
            <Ship key={k} x={260 + k * 280} y={lin(t, Wa('velas') - 0.5, Wa('y', 43), 1700, 1560) - (k % 2) * 40} s={0.8} o={lin(t, Wa('velas') - 0.6, Wa('velas'), 0, 0.9) * (0.7 + 0.3 * Math.sin(t * 3 + k))} />
          ))}
          {pulse > 0 ? (
            <g>
              <ellipse cx={540} cy={975 + WALL_RY} rx={110} ry={50} fill="none" stroke={C.red} strokeWidth={10} opacity={0.4 + 0.6 * pulse} />
              <ellipse cx={540} cy={975 + WALL_RY} rx={150} ry={70} fill={C.red} opacity={0.15 * pulse} />
            </g>
          ) : null}
        </g>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={POP} day={DAY} />
      </div>
      <Pop at={Wa('velas') - 0.1} out={weak - 0.3} style={{top: 400, left: 0, right: 0}}>
        <BigText size={90}>
          LAS VELAS NEGRAS,
          <br />
          <span style={{color: C.red}}>MÁS CERCA</span>
        </BigText>
      </Pop>
      <Pop at={weak - 0.1} style={{top: 400, left: 0, right: 0, flexDirection: 'column'}}>
        <BigText size={110} color={C.red}>
          PUNTO DÉBIL
        </BigText>
        <Pill color="#fff" size={44}>
          LA PLAYA DEL SUR
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 5. YOUTUBE: canal nuevo y los dos vídeos largos
// =====================================================================
const YouTubeScene = () => {
  const t = useT();
  const thumbs = [
    ['veinte', staticFile('thumbs/20000.png'), '¿Y si despertaras hace 20.000 años?'],
    ['fosa', staticFile('thumbs/fosa.png'), '¿Y si bajaras a la Fosa de las Marianas?'],
  ];
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 30%, #3a0d12, #05060f)'}}>
      <Pop at={Wa('youtube') - 0.2} style={{top: 260, left: 0, right: 0, flexDirection: 'column', gap: 16}}>
        <div style={{width: 200, height: 140, borderRadius: 40, background: '#dc2626', display: 'flex', alignItems: 'center', justifyContent: 'center', boxShadow: `0 0 ${40 + 20 * Math.sin(t * 5)}px #dc2626`}}>
          <svg width={90} height={90} viewBox="0 0 24 24">
            <path d="M7 4.5v15l12-7.5z" fill="#fff" />
          </svg>
        </div>
        <Pill color={C.accent} size={40}>
          CANAL NUEVO
        </Pill>
        <BigText size={84}>@aprendedconmigo</BigText>
      </Pop>
      <div style={{position: 'absolute', top: 760, left: 60, right: 60, display: 'flex', flexDirection: 'column', gap: 26}}>
        {thumbs.map(([w, src, label]) => {
          const at = Wa(w, 57);
          const s = r(t, at - 0.3, at + 0.2, 0, 1, BACK);
          return (
            <div key={w} style={{display: 'flex', alignItems: 'center', gap: 20, scale: String(s), opacity: Math.min(1, s), background: 'rgba(8,12,30,0.88)', borderRadius: 24, padding: 14, border: '3px solid rgba(255,255,255,0.15)'}}>
              <Img src={src} style={{width: 360, height: 202, borderRadius: 14, objectFit: 'cover'}} />
              <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 34, color: '#fff', lineHeight: 1.15}}>
                {label}
                <div style={{fontSize: 24, color: '#ff6b6b', marginTop: 8}}>▶ VÍDEO LARGO</div>
              </div>
            </div>
          );
        })}
      </div>
    </AbsoluteFill>
  );
};

// =====================================================================
// 6. EL COCO DORADO
// =====================================================================
const CocoScene = () => {
  const t = useT();
  const spin = Math.sin(t * 3) * 15;
  return (
    <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 40%, #3a2c08, #05060f)'}}>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        {Array.from({length: 40}).map((_, i) => {
          const a = (i / 40) * Math.PI * 2 + t * 0.3;
          const d = 260 + random(`cs${i}`) * 260;
          return <circle key={i} cx={540 + Math.cos(a) * d} cy={700 + Math.sin(a) * d * 0.8} r={3 + random(`cr${i}`) * 4} fill="#fff2a8" opacity={0.3 + 0.5 * Math.sin(t * 4 + i)} />;
        })}
        <g transform={`translate(540 700) rotate(${spin}) scale(${r(t, Wa('coco') - 0.3, Wa('coco') + 0.3, 0, 9, BACK)})`}>
          <GoldenCoconut x={0} y={0} s={1} t={t} />
        </g>
        <text x={760} y={560} fontFamily={FONT} fontWeight={900} fontSize={160} fill="#fff" opacity={lin(t, Wa('escondido') - 0.2, Wa('escondido') + 0.3, 0, 1)} stroke="#05060f" strokeWidth={14} paintOrder="stroke">
          ?
        </text>
      </svg>
      <Pop at={Wa('por') - 0.1} style={{top: 240, left: 0, right: 0}}>
        <BigText size={88} color={C.accent}>
          EL COCO DORADO
        </BigText>
      </Pop>
      <Pop at={Wa('primero') - 0.1} out={Wa('quedan', 70) - 0.2} style={{top: 1060, left: 60, right: 60, flexDirection: 'column', gap: 16}}>
        <BigText size={60}>ENCUÉNTRALO EN EL VÍDEO</BigText>
        <Pill color="#fff" size={40}>
          COMENTA EL SEGUNDO EXACTO
        </Pill>
        <Pill color={C.accent} size={40}>
          ¡SALDRÁS EN EL PRÓXIMO VÍDEO!
        </Pill>
      </Pop>
      <Pop at={Wa('quedan', 70) - 0.1} style={{top: 1080, left: 0, right: 0}}>
        <BigText size={110} color={C.red}>
          QUEDAN 2 DÍAS
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
export const Dia05 = () => (
  <AbsoluteFill style={{backgroundColor: '#0d4f8f'}}>
    <Scene name="Construcción" start={0} end={Wa('al') - 0.2} fadeOut={false}>
      <BuildScene />
    </Scene>
    <Scene name="La noche" start={Wa('al') - 0.2} end={Wa('y', 50) - 0.2}>
      <NightScene />
    </Scene>
    <Scene name="YouTube" start={Wa('y', 50) - 0.2} end={Wa('por') - 0.2}>
      <YouTubeScene />
    </Scene>
    <Scene name="Coco dorado" start={Wa('por') - 0.2} end={DURATION} fadeOut={false}>
      <CocoScene />
    </Scene>
    <Brand hideAt={DURATION} />
    <ProgressBar />
    <Captions chunks={CHUNKS} />
    <Audio src={staticFile('civilizacion-05.mp3')} />
  </AbsoluteFill>
);

// =====================================================================
// MINIATURA (portada vertical)
// =====================================================================
export const MiniaturaDia05 = () => {
  const t = 12;
  return (
    <AbsoluteFill style={{background: '#050a2a', overflow: 'hidden'}}>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={1} />
        <g transform={cam(0.95, 540, 975, 1060)}>
          <IslandWorld t={t} pop={POP} maxShown={70} size={BIG}>
            <Landmarks t={t} rock={false} />
          </IslandWorld>
          <Wall k={1} night={1} />
          <ellipse cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y + 4} rx={30} ry={12} fill="#9aa3b8" />
          <Villager x={SPOTS.dylanRock.x} y={SPOTS.dylanRock.y} t={t} seed={7} s={1.7} shirt="#a78bfa" crown wave={50} />
          <rect x={-1000} y={-1000} width={3000} height={4000} fill="#050a2a" opacity={0.3} />
          <ellipse cx={540} cy={975 + WALL_RY} rx={170} ry={80} fill={C.red} opacity={0.25} />
          <ellipse cx={540} cy={975 + WALL_RY} rx={120} ry={55} fill="none" stroke={C.red} strokeWidth={12} />
        </g>
        <ellipse cx={540} cy={1760} rx={620} ry={260} fill={C.red} opacity={0.18} />
        <g style={{filter: `drop-shadow(0 0 18px ${C.red}) drop-shadow(0 0 6px ${C.red})`}}>
          {[[200, 1720, 1.5], [540, 1790, 1.9], [880, 1720, 1.5]].map(([x, y, s], k) => (
            <Ship key={k} x={x} y={y} s={s} o={1} />
          ))}
        </g>
      </svg>
      <div style={{position: 'absolute', top: 130, left: 30, right: 30, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18}}>
        <BigText size={200} color="#fff">DÍA 5</BigText>
        <BigText size={112} color={C.accent}>
          ¿AGUANTARÁ
          <br />
          LA MURALLA?
        </BigText>
        <div style={{marginTop: 10, background: C.red, borderRadius: 999, padding: '14px 40px', fontFamily: FONT, fontWeight: 900, fontSize: 60, color: '#fff', border: '6px solid #05060f', boxShadow: `0 0 50px ${C.red}`}}>QUEDAN 2 DÍAS</div>
      </div>
      <div style={{position: 'absolute', top: 40, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Pill color="rgba(255,255,255,0.14)" text="#fff" size={34} style={{border: '2px solid rgba(255,255,255,0.3)'}}>
          265 HABITANTES · LA CIVILIZACIÓN
        </Pill>
      </div>
    </AbsoluteFill>
  );
};
