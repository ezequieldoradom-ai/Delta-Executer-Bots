import React from 'react';
import {AbsoluteFill, random, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, Scene, lin, r, useT} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, Check, Heart, ProgressBar} from '../tunel/Visuals';
import {Hud, IslandWorld, Ocean, Villager} from './Island';
import {Landmarks, SPOTS} from './Landmarks';
import {makeW} from './words';
import WORDS from '../../public/civilizacion-04.words.json';

const W = makeW(WORDS);
export const DURATION = WORDS[WORDS.length - 1].end + 0.9;
const DAY = 4;
const POP = 188;
const BIG = 1.35; // tamaño de la isla tras crecer
const PURPLE = '#b46cff';

const CHUNKS = chunkWords(WORDS, [
  'cuatro', 'dylan', 'visionario', 'gritando', 'visión', 'buena', 'ocho', 'agrande', 'isla', 'tembló',
  'lava', 'creció', 'surtsey', 'menos', 'lejos', 'llamas', 'negras', 'horizonte', 'tres', 'días',
  'nunca', 'equivocado', 'muralla', 'ejército', 'huimos', 'likes', 'mañana', 'pueblo', 'todos', 'aprende',
]);

const cam = (zoom, fx = 540, fy = 975, cy = 920) => `translate(540 ${cy}) scale(${zoom}) translate(${-fx} ${-fy})`;

// Dylan en primer plano, con ojos de vidente
const Dylan = ({t, x, y, s, glow = 0, crown = true}) => (
  <g transform={`translate(${x} ${y})`}>
    <Villager x={0} y={0} t={0} seed={7} s={s} shirt="#a78bfa" crown={crown} />
    {glow > 0 ? (
      <g opacity={glow}>
        {[-3.2, 3.2].map((ex) => (
          <g key={ex}>
            <ellipse cx={ex * s} cy={-35 * s} rx={1.9 * s} ry={1.3 * s} fill="#f3e8ff" style={{filter: `drop-shadow(0 0 ${2.5 * s}px ${PURPLE})`}} />
            <path
              d={`M${ex * s} ${-35 * s} L${ex * s * 9 + (ex > 0 ? 200 : -200)} ${-35 * s - 60} L${ex * s * 9 + (ex > 0 ? 200 : -200)} ${-35 * s + 60} Z`}
              fill={PURPLE}
              opacity={0.12 + 0.06 * Math.sin(t * 9)}
            />
          </g>
        ))}
      </g>
    ) : null}
  </g>
);

// Aura de visión: anillos y chispas moradas
const VisionAura = ({t, x, y, k = 1, r0 = 80}) => (
  <g opacity={k}>
    {[0, 1, 2, 3].map((i) => {
      const ph = (t * 0.7 + i / 4) % 1;
      return <circle key={i} cx={x} cy={y} r={r0 + ph * 420} fill="none" stroke={PURPLE} strokeWidth={6 * (1 - ph)} opacity={0.8 * (1 - ph)} />;
    })}
    {Array.from({length: 40}).map((_, i) => {
      const a = random(`va${i}`) * Math.PI * 2 + t * (0.3 + random(`vs${i}`) * 0.6);
      const d = r0 + 40 + random(`vd${i}`) * 380;
      return <circle key={i} cx={x + Math.cos(a) * d} cy={y + Math.sin(a) * d * 0.8} r={2 + random(`vr${i}`) * 5} fill={i % 3 ? '#e9d5ff' : PURPLE} opacity={0.4 + 0.5 * Math.sin(t * 4 + i)} />;
    })}
  </g>
);

const DreamOverlay = ({t, k}) => (
  <AbsoluteFill style={{pointerEvents: 'none', opacity: k}}>
    <AbsoluteFill style={{background: `radial-gradient(circle at 50% 45%, rgba(180,108,255,0.10) 30%, rgba(60,0,110,0.75) 100%)`}} />
    <AbsoluteFill style={{background: 'repeating-linear-gradient(0deg, rgba(255,255,255,0.03) 0 2px, transparent 2px 6px)', translate: `0 ${(t * 60) % 6}px`}} />
  </AbsoluteFill>
);

const FactCard = ({title, text, icon}) => (
  <div style={{display: 'flex', alignItems: 'center', gap: 18, background: 'rgba(8,12,30,0.9)', border: `4px solid ${C.accent}`, borderRadius: 28, padding: '16px 24px', fontFamily: FONT, color: '#fff'}}>
    {icon}
    <div style={{background: C.accent, color: '#0b0b14', fontWeight: 900, fontSize: 30, borderRadius: 16, padding: '6px 14px'}}>{title}</div>
    <div style={{fontWeight: 800, fontSize: 34, lineHeight: 1.15}}>{text}</div>
  </div>
);

// =====================================================================
// 1. GANCHO: Dylan despierta gritando
// =====================================================================
const HookScene = () => {
  const t = useT();
  const wake = W('despertó');
  const rise = r(t, wake, wake + 0.35, 260, 0, BACK);
  const shake = t > wake && t < wake + 1.2 ? Math.sin(t * 70) * lin(t, wake, wake + 1.2, 16, 0) : 0;
  const glow = r(t, W('visión') - 0.2, W('visión') + 0.4, 0, 1);
  const zoom = r(t, 0, W('visión'), 1, 1.25, INOUT) + r(t, W('visión'), W('pero') - 0.1, 0, 0.5, INOUT);
  const bad = t > W('no') ? lin(t, W('no'), W('buena') + 0.4, 0, 0.45) : 0;
  return (
    <AbsoluteFill style={{background: 'linear-gradient(#070a24, #1a1040)'}}>
      <AbsoluteFill style={{scale: String(zoom), transformOrigin: '540px 1000px', translate: `${shake}px ${shake * 0.4}px`}}>
        <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
          {Array.from({length: 70}).map((_, i) => (
            <circle key={i} cx={random(`hs${i}`) * 1080} cy={random(`hy${i}`) * 900} r={1 + random(`hr${i}`) * 2.5} fill="#fff" opacity={0.3 + 0.5 * Math.sin(t * 2 + i)} />
          ))}
          <circle cx={850} cy={330} r={70} fill="#fdf3c4" opacity={0.9} />
          <circle cx={880} cy={310} r={64} fill="#0d0c2c" />
          {/* Cabaña por dentro: paredes de madera */}
          <rect x={0} y={900} width={1080} height={1020} fill="#3a2418" />
          {Array.from({length: 9}).map((_, i) => (
            <line key={i} x1={0} x2={1080} y1={950 + i * 110} y2={950 + i * 110} stroke="#2a180e" strokeWidth={8} />
          ))}
          {/* Antorcha en la pared */}
          <g transform="translate(170 1050)">
            <rect x={-6} y={0} width={12} height={70} fill="#6b3f1f" />
            <path d={`M-16 0 C-20 -26 -6 -36 0 ${-58 - Math.sin(t * 14) * 8} C6 -36 20 -26 16 0 Z`} fill="#ffb02e" />
            <circle r={110} fill="#ffb02e" opacity={0.12} />
          </g>
          <VisionAura t={t} x={540} y={1000} k={glow} />
          {/* Cama */}
          <rect x={220} y={1290} width={640} height={60} rx={20} fill="#6b3f1f" />
          <rect x={250} y={1200} width={160} height={70} rx={30} fill="#f0f2f8" />
          <g transform={`translate(${shake} ${rise})`}>
            <Dylan t={t} x={540} y={1260} s={7} glow={glow} crown />
          </g>
          <rect x={240} y={1230} width={600} height={90} rx={30} fill="#5b3fa8" />
          {t > wake && t < wake + 1.6 ? (
            <g opacity={lin(t, wake + 1.0, wake + 1.6, 1, 0)}>
              {[-1, 1].map((sd) =>
                [0, 1, 2].map((k) => (
                  <line key={`${sd}${k}`} x1={540 + sd * (110 + k * 8)} y1={940 + k * 40} x2={540 + sd * (190 + k * 20)} y2={900 + k * 50} stroke="#fff" strokeWidth={10} strokeLinecap="round" />
                )),
              )}
            </g>
          ) : null}
        </svg>
      </AbsoluteFill>
      {bad > 0 ? <AbsoluteFill style={{background: 'radial-gradient(circle, transparent 40%, rgba(200,0,40,1) 130%)', opacity: bad}} /> : null}
      <Pop at={0.05} out={W('esta') - 0.1} style={{top: 760, left: 0, right: 0}}>
        <BigText size={170} color={C.accent} stroke={14}>
          DÍA {DAY}
        </BigText>
      </Pop>
      <Pop at={W('esta') - 0.05} style={{top: 260, left: 0, right: 0, flexDirection: 'column'}}>
        <BigText size={120} color="#e9d5ff" style={{textShadow: `0 0 40px ${PURPLE}, 0 0 80px ${PURPLE}`}}>
          LA PROFECÍA
        </BigText>
        <div style={{marginTop: 12}}>
          <Pill color={PURPLE} text="#fff" size={40}>
            DÍA {DAY}
          </Pill>
        </div>
      </Pop>
      <Pop at={wake} out={W('ha') - 0.1} style={{top: 560, left: 0, right: 0}}>
        <BigText size={140} color={C.red} style={{translate: `${shake * 2}px 0`}}>
          ¡¡AAAH!!
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 2. LA ISLA CRECE (comentario ganador)
// =====================================================================
const LAVA = Array.from({length: 28}).map((_, i) => ({a: (i / 28) * Math.PI * 2 + random(`la${i}`) * 0.2, k: random(`lk${i}`)}));

const Volcano = ({t}) => (
  <svg width={110} height={100} viewBox="-55 -60 110 100">
    <path d="M-50 36 L-14 -26 L14 -26 L50 36 Z" fill="#5a3d26" />
    <path d="M-14 -26 L14 -26 L8 -14 L-8 -14 Z" fill="#ff6a1f" />
    {[0, 1, 2, 3].map((i) => {
      const u = (t * 1.2 + i / 4) % 1;
      return <circle key={i} cx={(i - 1.5) * 10 * u} cy={-30 - u * 30} r={5 + u * 6} fill={i % 2 ? '#ffb02e' : '#ff5a1f'} opacity={1 - u} />;
    })}
  </svg>
);

const GrowthScene = () => {
  const t = useT();
  const quake = W('tembló');
  const lavaAt = W('lava');
  const size = r(t, lavaAt + 0.2, W('creció') + 0.6, 1, BIG, INOUT);
  const zoom = lin(size, 1, BIG, 1.0, 0.8);
  const shakeK = t > quake && t < W('creció') + 0.8 ? lin(t, quake, quake + 0.4, 0, 14) * lin(t, W('creció'), W('creció') + 0.8, 1, 0) : 0;
  const sx = Math.sin(t * 75) * shakeK;
  const sy = Math.cos(t * 61) * shakeK;
  const lava = r(t, lavaAt - 0.2, lavaAt + 0.4, 0, 1) * lin(t, W('creció') + 0.8, W('esto') + 1.5, 1, 0);
  return (
    <AbsoluteFill style={{translate: `${sx}px ${sy}px`}}>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} />
        <g transform={cam(zoom, 540, 975, 960)}>
          <IslandWorld t={t} pop={POP} maxShown={60} size={size}>
            <Landmarks t={t} />
          </IslandWorld>
          {lava > 0
            ? LAVA.map((l, i) => {
                const rx = 450 * size + 10;
                const ry = 300 * size + 10;
                const x = 540 + Math.cos(l.a) * rx;
                const y = 975 + Math.sin(l.a) * ry;
                const pulse = 1 + 0.25 * Math.sin(t * 8 + i);
                return (
                  <g key={i} opacity={lava}>
                    <circle cx={x} cy={y} r={26 * pulse} fill="#ff6a1f" opacity={0.85} />
                    <circle cx={x} cy={y} r={12 * pulse} fill="#ffe27a" />
                    <circle cx={x + Math.sin(t * 2 + i) * 10} cy={y - 30 - ((t * 40 + i * 13) % 60)} r={14} fill="#e8ecf5" opacity={0.35} />
                  </g>
                );
              })
            : null}
        </g>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={POP} day={DAY} highlight={t < W('ocho') + 0.6 && t > W('ya') ? 0.7 : 0} />
      </div>
      <Pop at={W('comentario') - 0.1} out={quake - 0.1} style={{top: 400, left: 60, right: 60, flexDirection: 'column'}}>
        <Pill color={C.accent} size={38}>
          COMENTARIO MÁS VOTADO
        </Pill>
        <div style={{width: '100%', boxSizing: 'border-box', marginTop: 14, display: 'flex', alignItems: 'center', gap: 18, background: 'rgba(8,12,30,0.92)', border: `4px solid ${C.accent}`, borderRadius: 26, padding: '14px 22px', fontFamily: FONT, color: '#fff'}}>
          <div style={{width: 64, height: 64, borderRadius: 32, background: `linear-gradient(135deg, ${C.cyan}, ${C.pink})`, flexShrink: 0}} />
          <div style={{flex: 1}}>
            <div style={{fontSize: 24, fontWeight: 800, color: '#b9c3dd'}}>@lolorman3</div>
            <div style={{fontSize: 44, fontWeight: 900}}>Que se agrande la isla</div>
          </div>
          <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', scale: String(1 + 0.15 * Math.abs(Math.sin(t * 6)))}}>
            <Heart size={50} color={C.pink} />
            <div style={{fontWeight: 900, fontSize: 26}}>23</div>
          </div>
        </div>
      </Pop>
      <Pop at={quake} out={lavaAt - 0.1} style={{top: 420, left: 0, right: 0}}>
        <BigText size={110} color={C.hot} style={{translate: `${sx}px 0`}}>
          ¡TERREMOTO!
        </BigText>
      </Pop>
      <Pop at={lavaAt} out={W('creció') - 0.1} style={{top: 420, left: 0, right: 0}}>
        <BigText size={110} color={C.hot}>
          ¡LAVA!
        </BigText>
      </Pop>
      <Pop at={W('creció') - 0.05} out={W('esto') - 0.1} style={{top: 400, left: 0, right: 0}}>
        <BigText size={100} color={C.green}>
          ¡LA ISLA CRECE!
        </BigText>
      </Pop>
      <Pop at={W('esto') - 0.05} style={{top: 420, left: 50, right: 50}}>
        <FactCard icon={<Volcano t={t} />} title="REAL" text="1963: un volcán creó la isla de Surtsey, junto a Islandia" />
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 3. LA VISIÓN
// =====================================================================
const Fireworks = ({t, from}) => (
  <g>
    {[0, 1, 2, 3, 4].map((k) => {
      const t0 = from + k * 0.35;
      const u = (t - t0) / 1.2;
      if (u < 0 || u > 1) return null;
      const cx = 220 + random(`fx${k}`) * 640;
      const cy = 420 + random(`fy${k}`) * 260;
      const col = [C.accent, C.pink, C.cyan, C.green, C.hot][k];
      return (
        <g key={k} opacity={1 - u}>
          {Array.from({length: 16}).map((_, i) => {
            const a = (i / 16) * Math.PI * 2;
            const d = 20 + u * 150;
            return <circle key={i} cx={cx + Math.cos(a) * d} cy={cy + Math.sin(a) * d + u * u * 40} r={6} fill={col} />;
          })}
        </g>
      );
    })}
  </g>
);

const Ship = ({x, y, s = 1, o = 1}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`} opacity={o}>
    <path d="M-90 0 L90 0 L66 38 L-66 38 Z" fill="#0b0b14" />
    <line x1={-20} y1={0} x2={-20} y2={-170} stroke="#0b0b14" strokeWidth={8} />
    <line x1={40} y1={0} x2={40} y2={-130} stroke="#0b0b14" strokeWidth={7} />
    <path d="M-16 -160 Q50 -110 -16 -40 Z" fill="#111" stroke="#3a3a4a" strokeWidth={2} />
    <path d="M44 -122 Q92 -88 44 -36 Z" fill="#111" stroke="#3a3a4a" strokeWidth={2} />
    <circle cx={6} cy={-104} r={12} fill="#e8ecf5" opacity={0.8} />
    <path d="M-20 -170 L10 -162 L-20 -154 Z" fill={C.red} />
  </g>
);

const Flames = ({t, y0, k}) => (
  <g opacity={k}>
    {Array.from({length: 26}).map((_, i) => {
      const x = i * 44 - 20;
      const h = 60 + random(`fl${i}`) * 90 + Math.sin(t * 9 + i) * 20;
      const y = y0 + (i % 3) * 120;
      return (
        <g key={i}>
          <path d={`M${x - 26} ${y} C${x - 30} ${y - h * 0.5} ${x - 6} ${y - h * 0.7} ${x} ${y - h} C${x + 6} ${y - h * 0.7} ${x + 30} ${y - h * 0.5} ${x + 26} ${y} Z`} fill="#ff5a1f" opacity={0.85} />
          <path d={`M${x - 12} ${y} C${x - 14} ${y - h * 0.3} ${x - 3} ${y - h * 0.45} ${x} ${y - h * 0.6} C${x + 3} ${y - h * 0.45} ${x + 14} ${y - h * 0.3} ${x + 12} ${y} Z`} fill="#ffe27a" />
        </g>
      );
    })}
  </g>
);

const VisionScene = () => {
  const t = useT();
  const dream = t >= W('porque') - 0.1 && t < W('nadie') - 0.1;
  const dreamK = dream ? Math.min(lin(t, W('porque') - 0.1, W('porque') + 0.4, 0, 1), lin(t, W('nadie') - 0.5, W('nadie') - 0.1, 1, 0)) : 0;
  const part =
    t < W('porque') - 0.1 ? 'party' : t < W('vio', 1) - 0.1 ? 'far' : t < W('velas') - 0.1 ? 'fire' : t < W('y', 5) - 0.1 ? 'ships' : t < W('nadie') - 0.1 ? 'three' : t < W('pero', 1) - 0.1 ? 'doubt' : 'dylan';
  const glitch = dream && Math.sin(t * 23) > 0.92 ? 12 : 0;
  const flash = t > W('porque') - 0.15 && t < W('porque') + 0.25 ? lin(t, W('porque') - 0.15, W('porque') + 0.25, 1, 0) : 0;

  let world = null;
  if (part === 'party' || part === 'doubt') {
    const zoom = part === 'party' ? r(t, W('menos') - 0.1, W('menos') + 0.8, 0.8, 3.2, INOUT) : 0.8;
    world = (
      <>
        <Ocean t={t} night={1} />
        {part === 'party' && t < W('menos') + 0.5 ? <Fireworks t={t} from={W('todos')} /> : null}
        <g transform={cam(zoom, part === 'party' ? lin(zoom, 0.8, 3.2, 540, SPOTS.dylanRock.x) : 540, part === 'party' ? lin(zoom, 0.8, 3.2, 975, SPOTS.dylanRock.y - 30) : 975, 960)}>
          <IslandWorld t={t} pop={POP} maxShown={60} size={BIG}>
            <Landmarks t={t} rock={false} />
          </IslandWorld>
          <ellipse cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y + 4} rx={30} ry={12} fill="#9aa3b8" />
          <Villager x={SPOTS.dylanRock.x} y={SPOTS.dylanRock.y} t={t} seed={7} s={1.6} shirt="#a78bfa" crown />
          <rect x={-1000} y={-1000} width={3000} height={4000} fill="#050a2a" opacity={0.35} />
          {part === 'doubt'
            ? Array.from({length: 9}).map((_, i) => {
                const x = 330 + random(`dq${i}`) * 420;
                const y = 840 + random(`dy${i}`) * 260;
                const s = r(t, W('nadie') + i * 0.12, W('nadie') + i * 0.12 + 0.3, 0, 1, BACK);
                return (
                  <g key={i} transform={`translate(${x} ${y}) scale(${s})`}>
                    <circle r={18} fill="#fff" />
                    <text y={9} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={26} fill="#0b0b14">
                      ?
                    </text>
                  </g>
                );
              })
            : null}
        </g>
      </>
    );
  } else if (part === 'far' || part === 'fire' || part === 'ships') {
    const zoom = part === 'far' ? r(t, W('porque'), W('lejos'), 0.8, 0.28, INOUT) : 0.28;
    world = (
      <>
        <rect x={0} y={0} width={1080} height={1920} fill="#0a0626" />
        <Ocean t={t} night={1} />
        <g transform={cam(zoom, 540, 975, 900)}>
          <IslandWorld t={t} pop={POP} maxShown={30} size={BIG}>
            <Landmarks t={t} />
          </IslandWorld>
          {part === 'far'
            ? [0, 1, 2, 3].map((i) => {
                const ph = (t * 0.5 + i / 4) % 1;
                return <ellipse key={i} cx={540} cy={975} rx={700 + ph * 2600} ry={480 + ph * 1800} fill="none" stroke="#e9d5ff" strokeWidth={30} opacity={0.6 * (1 - ph)} />;
              })
            : null}
        </g>
        {part !== 'far' ? <Flames t={t} y0={part === 'fire' ? lin(t, W('vio', 1), W('llamas') + 0.6, 1950, 1350) : 1350} k={1} /> : null}
        {part !== 'far' ? <Flames t={t + 3} y0={part === 'fire' ? lin(t, W('vio', 1), W('llamas') + 0.6, -200, 260) : 260} k={0.8} /> : null}
        {part === 'ships'
          ? [0, 1, 2].map((k) => {
              const p = lin(t, W('velas') + k * 0.25, W('y', 5), 0, 1);
              const flick = 0.55 + 0.45 * Math.sin(t * 30 + k * 2);
              return <Ship key={k} x={180 + k * 360} y={1250 - p * 120 - (k % 2) * 60} s={0.9 + p * 0.5} o={Math.min(1, p * 3) * flick} />;
            })
          : null}
      </>
    );
  } else if (part === 'three') {
    world = <rect x={0} y={0} width={1080} height={1920} fill="#12052e" />;
  }

  return (
    <AbsoluteFill>
      <AbsoluteFill style={{translate: `${glitch}px 0`}}>
        <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
          {world}
          {part === 'dylan' ? (
            <>
              <rect x={0} y={0} width={1080} height={1920} fill="#0a0626" />
              <VisionAura t={t} x={540} y={1000} k={1} r0={140} />
              <g transform={`translate(540 1000) scale(${r(t, W('pero', 1), W('pero', 1) + 1.6, 1, 1.25)}) translate(-540 -1000)`}>
                <Dylan t={t} x={540} y={1300} s={8} glow={1} crown />
              </g>
            </>
          ) : null}
        </svg>
      </AbsoluteFill>
      <DreamOverlay t={t} k={dreamK} />
      {flash > 0 ? <AbsoluteFill style={{background: '#f3e8ff', opacity: flash}} /> : null}

      {part === 'party' ? (
        <>
          <Pop at={W('todos') - 0.05} out={W('menos') - 0.1} style={{top: 380, left: 0, right: 0}}>
            <BigText size={90} color={C.accent}>
              ¡FIESTA EN LA ALDEA!
            </BigText>
          </Pop>
          <Pop at={W('menos') - 0.05} style={{top: 380, left: 0, right: 0}}>
            <BigText size={100}>
              …MENOS <span style={{color: '#e9d5ff'}}>DYLAN</span>
            </BigText>
          </Pop>
        </>
      ) : null}
      {dream ? (
        <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center', opacity: dreamK}}>
          <Pill color={PURPLE} text="#fff" size={40} style={{boxShadow: `0 0 40px ${PURPLE}`}}>
            LA VISIÓN DE DYLAN
          </Pill>
        </div>
      ) : null}
      {part === 'far' ? (
        <Pop at={W('grande') - 0.1} style={{top: 360, left: 0, right: 0}}>
          <BigText size={80} color="#e9d5ff">
            SE VE DESDE
            <br />
            MUY LEJOS…
          </BigText>
        </Pop>
      ) : null}
      {part === 'fire' ? (
        <Pop at={W('vio', 1) - 0.05} style={{top: 380, left: 0, right: 0}}>
          <BigText size={110} color={C.hot}>
            EL MAR EN LLAMAS
          </BigText>
        </Pop>
      ) : null}
      {part === 'ships' ? (
        <Pop at={W('velas') - 0.05} style={{top: 380, left: 0, right: 0}}>
          <BigText size={100} color="#fff">
            VELAS NEGRAS
          </BigText>
        </Pop>
      ) : null}
      {part === 'three' ? (
        <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center'}}>
          {t > W('tres', 1) - 0.1 ? (
            <div
              style={{
                fontFamily: FONT,
                fontWeight: 900,
                fontSize: 760,
                lineHeight: 1,
                color: '#f3e8ff',
                textShadow: `0 0 60px ${PURPLE}, 0 0 140px ${PURPLE}`,
                scale: String(r(t, W('tres', 1) - 0.1, W('tres', 1) + 0.4, 2.2, 1, BACK) * (1 + 0.04 * Math.sin(t * 8))),
                opacity: lin(t, W('tres', 1) - 0.1, W('tres', 1) + 0.2, 0, 1),
                marginTop: -200,
              }}
            >
              3
            </div>
          ) : (
            <BigText size={90} color="#e9d5ff" style={{marginTop: -200}}>
              …Y UN NÚMERO
            </BigText>
          )}
          {t > W('tres', 2) - 0.1 ? (
            <div style={{position: 'absolute', top: 1150}}>
              <BigText size={120} color={C.accent}>
                DÍAS
              </BigText>
            </div>
          ) : null}
        </AbsoluteFill>
      ) : null}
      {part === 'doubt' ? (
        <Pop at={W('nadie') - 0.05} style={{top: 380, left: 0, right: 0}}>
          <BigText size={96}>¿SERÁ VERDAD?</BigText>
        </Pop>
      ) : null}
      {part === 'dylan' ? (
        <Pop at={W('nunca') - 0.1} style={{top: 330, left: 0, right: 0}}>
          <BigText size={92} color="#e9d5ff" style={{textShadow: `0 0 40px ${PURPLE}`}}>
            DYLAN NUNCA
            <br />
            SE HA EQUIVOCADO
          </BigText>
        </Pop>
      ) : null}
    </AbsoluteFill>
  );
};

// =====================================================================
// 4. EL PLAN: quedan 3 días
// =====================================================================
const Hourglass = ({t, p}) => (
  <svg width={260} height={340} viewBox="-130 -170 260 340">
    <rect x={-110} y={-160} width={220} height={22} rx={8} fill="#a0703f" />
    <rect x={-110} y={138} width={220} height={22} rx={8} fill="#a0703f" />
    <path d="M-90 -138 L90 -138 L12 -6 L12 6 L90 138 L-90 138 L-12 6 L-12 -6 Z" fill="rgba(200,230,255,0.25)" stroke="#e8ecf5" strokeWidth={6} />
    <path d={`M${-80 * (1 - p)} ${-128 + 110 * p} L${80 * (1 - p)} ${-128 + 110 * p} L6 -8 L-6 -8 Z`} fill={C.accent} />
    <path d={`M-80 132 L80 132 L${80 - 50 * p} ${132 - 90 * p} L${-80 + 50 * p} ${132 - 90 * p} Z`} fill={C.accent} />
    <line x1={0} y1={-6} x2={0} y2={132 - 90 * p} stroke={C.accent} strokeWidth={4} strokeDasharray="6 6" strokeDashoffset={-t * 60} />
  </svg>
);

const OPTION_ICONS = {
  muralla: (
    <svg width={110} height={90} viewBox="0 0 110 90">
      {[0, 1, 2].map((row) =>
        [0, 1, 2, 3].map((c) => <rect key={`${row}${c}`} x={(row % 2 ? -12 : 0) + c * 30} y={20 + row * 22} width={28} height={20} fill="#9aa3b8" stroke="#5a6478" strokeWidth={2} />),
      )}
      {[0, 1, 2].map((c) => (
        <rect key={c} x={6 + c * 38} y={4} width={22} height={16} fill="#9aa3b8" stroke="#5a6478" strokeWidth={2} />
      ))}
    </svg>
  ),
  ejercito: (
    <svg width={110} height={90} viewBox="-55 -45 110 90">
      <line x1={-36} y1={40} x2={30} y2={-40} stroke="#8a5a2c" strokeWidth={6} />
      <path d="M30 -40 L38 -30 L24 -28 Z" fill="#c9d1e0" />
      <path d="M-30 -30 L30 -30 L30 4 Q30 34 0 44 Q-30 34 -30 4 Z" fill={C.red} stroke="#fff" strokeWidth={4} />
      <path d="M0 -24 L0 36 M-22 0 L22 0" stroke="#fff" strokeWidth={6} />
    </svg>
  ),
  huir: (
    <svg width={110} height={90} viewBox="-55 -50 110 90">
      <path d="M-46 14 L46 14 L32 36 L-32 36 Z" fill="#8a5a2c" />
      <line x1={0} y1={14} x2={0} y2={-44} stroke="#6b3f1f" strokeWidth={5} />
      <path d="M4 -40 Q40 -14 4 8 Z" fill="#fff" />
      <path d="M-52 40 q10 -6 20 0 q10 6 20 0 q10 -6 20 0 q10 6 20 0 q10 -6 20 0" fill="none" stroke="#5ec8ff" strokeWidth={4} />
    </svg>
  ),
};

const PlanScene = () => {
  const t = useT();
  const sand = lin(t, W('así', 1), W('faltan'), 0.05, 0.4);
  const opts = [
    ['construimos', 'MURALLA', 'muralla', '#c9d1e0'],
    ['entrenamos', 'EJÉRCITO', 'ejercito', C.red],
    ['huimos', 'HUIR', 'huir', C.cyan],
  ];
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={0.85} />
        <g transform={cam(0.8, 540, 975, 1000)} opacity={0.55}>
          <IslandWorld t={t} pop={POP} maxShown={60} size={BIG}>
            <Landmarks t={t} />
          </IslandWorld>
        </g>
      </svg>
      <Pop at={W('así', 1) - 0.1} style={{top: 240, left: 0, right: 0, flexDirection: 'column'}}>
        <Hourglass t={t} p={sand} />
        <div style={{marginTop: -6}}>
          <BigText size={96} color={C.accent}>
            QUEDAN 3 DÍAS
          </BigText>
        </div>
      </Pop>
      <div style={{position: 'absolute', top: 820, left: 30, right: 30, display: 'flex', justifyContent: 'space-between'}}>
        {opts.map(([w, label, icon, col]) => {
          const at = W(w) - 0.05;
          const s = r(t, at, at + 0.4, 0, 1, BACK);
          const hot = t > W(w) && t < W(w) + 1.2;
          return (
            <div
              key={w}
              style={{
                width: 320,
                height: 300,
                borderRadius: 30,
                background: 'rgba(8,12,30,0.88)',
                border: `5px solid ${hot ? col : 'rgba(255,255,255,0.2)'}`,
                boxShadow: hot ? `0 0 40px ${col}` : 'none',
                display: 'flex',
                flexDirection: 'column',
                alignItems: 'center',
                justifyContent: 'center',
                gap: 18,
                scale: String(s),
                opacity: Math.min(1, s),
              }}
            >
              <div style={{scale: '1.5'}}>{OPTION_ICONS[icon]}</div>
              <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 44, color: '#fff'}}>{label}</div>
            </div>
          );
        })}
      </div>
      <Pop at={W('comenta') - 0.1} style={{top: 1180, left: 0, right: 0}}>
        <Pill color={C.pink} text="#fff" size={52}>
          COMENTA TU PLAN
        </Pill>
      </Pop>
      <Pop at={W('hará') - 0.1} style={{top: 1270, left: 0, right: 0}}>
        <Pill color={C.accent} size={44}>
          MÁS LIKES = SE HACE MAÑANA
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 5. CIERRE
// =====================================================================
const TORCHES = Array.from({length: 10}).map((_, i) => {
  const a = (i / 10) * Math.PI * 2;
  return {x: 540 + Math.cos(a) * 470, y: 975 + Math.sin(a) * 320};
});

const OutroScene = () => {
  const t = useT();
  const tapAt = W('sígueme') + 0.3;
  const tap = t > tapAt - 0.15 && t < tapAt + 0.15 ? 0.9 : 1;
  const tapped = t > tapAt;
  const pop = POP + (tapped ? 1 : 0);
  const fill = r(t, W('faltan') + 0.1, W('faltan') + 1.3, 0, POP / 1000);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <Ocean t={t} night={0.8} />
        <g transform={cam(0.82, 540, 975, 1000)}>
          <IslandWorld t={t} pop={pop} maxShown={60} size={BIG}>
            <Landmarks t={t} rock={false} />
          </IslandWorld>
          <ellipse cx={SPOTS.dylanRock.x} cy={SPOTS.dylanRock.y + 4} rx={30} ry={12} fill="#9aa3b8" />
          <Villager x={SPOTS.dylanRock.x} y={SPOTS.dylanRock.y} t={t} seed={7} s={1.6} shirt="#a78bfa" crown />
          <rect x={-1000} y={-1000} width={3000} height={4000} fill="#050a2a" opacity={0.3} />
          {TORCHES.map((p, i) => (
            <g key={i} transform={`translate(${p.x} ${p.y})`}>
              <circle r={60} fill="#ffb02e" opacity={0.15 + 0.05 * Math.sin(t * 8 + i)} />
              <rect x={-3} y={-30} width={6} height={30} fill="#6b3f1f" />
              <path d={`M-9 -30 C-11 -44 -3 -50 0 ${-62 - Math.sin(t * 12 + i) * 6} C3 -50 11 -44 9 -30 Z`} fill="#ffb02e" />
            </g>
          ))}
        </g>
      </svg>
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Hud pop={pop} day={DAY} highlight={tapped ? lin(t, tapAt, tapAt + 1.2, 1, 0) : 0} />
      </div>
      <Pop at={W('faltan')} out={W('y', 6) - 0.1} style={{top: 390, left: 70, right: 70, flexDirection: 'column'}}>
        <div style={{width: '100%', height: 54, borderRadius: 30, background: 'rgba(8,12,30,0.85)', border: '4px solid #fff', overflow: 'hidden'}}>
          <div style={{width: `${fill * 100}%`, height: '100%', background: `linear-gradient(90deg, ${C.green}, ${C.accent})`}} />
        </div>
        <div style={{display: 'flex', justifyContent: 'space-between', width: '100%', fontFamily: FONT, fontWeight: 900, fontSize: 32, color: '#fff', marginTop: 8, textShadow: '0 3px 10px #000'}}>
          <span>ALDEA · 188</span>
          <span>PUEBLO · 1.000</span>
        </div>
        <BigText size={72} color={C.accent} style={{marginTop: 10}}>
          ¡FALTAN 812!
        </BigText>
      </Pop>
      <Pop at={W('y', 6) - 0.05} out={W('sígueme') - 0.15} style={{top: 420, left: 0, right: 0}}>
        <BigText size={90} color={C.red}>
          VAMOS A NECESITAR
          <br />A TODOS
        </BigText>
      </Pop>
      <Pop at={W('sígueme') - 0.1} style={{top: 420, left: 0, right: 0}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 16, padding: '22px 64px', borderRadius: 80, background: tapped ? 'rgba(255,255,255,0.25)' : C.pink, fontFamily: FONT, fontWeight: 900, fontSize: 62, color: '#fff', scale: String(tap), boxShadow: tapped ? 'none' : `0 0 ${40 + 20 * Math.sin(t * 6)}px ${C.pink}`}}>
          {tapped ? <Check size={62} /> : '+'} {tapped ? 'SIGUIENDO' : 'SEGUIR'}
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
export const Dia04 = () => (
  <AbsoluteFill style={{backgroundColor: '#070a24'}}>
    <Scene name="Gancho: la profecía" start={0} end={W('pero') - 0.2} fadeOut={false}>
      <HookScene />
    </Scene>
    <Scene name="La isla crece" start={W('pero') - 0.2} end={W('todos') - 0.2}>
      <GrowthScene />
    </Scene>
    <Scene name="La visión" start={W('todos') - 0.2} end={W('así', 1) - 0.2} fadeOut={false}>
      <VisionScene />
    </Scene>
    <Scene name="El plan" start={W('así', 1) - 0.2} end={W('faltan') - 0.2}>
      <PlanScene />
    </Scene>
    <Scene name="Cierre" start={W('faltan') - 0.2} end={DURATION} fadeOut={false}>
      <OutroScene />
    </Scene>
    <Brand hideAt={DURATION} />
    <ProgressBar />
    <Captions chunks={CHUNKS} />
    <Audio src={staticFile('civilizacion-04.mp3')} />
  </AbsoluteFill>
);
