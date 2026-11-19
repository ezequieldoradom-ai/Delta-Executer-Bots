import React from 'react';
import {AbsoluteFill, random} from 'remotion';
import {BigText, C, FONT, Pill} from '../tunel/lib';
import {IslandWorld, Ocean, Villager} from './Island';
import {Landmarks, SPOTS} from './Landmarks';
import {Ship} from './Dia05';

// Portada vertical del Día 4: la visión de Dylan
const PURPLE = '#a78bfa';
const cam = (zoom, fx, fy, cy) => `translate(540 ${cy}) scale(${zoom}) translate(${-fx} ${-fy})`;

export const MiniaturaDia04 = () => {
  const t = 8;
  const dx = SPOTS.dylanRock.x;
  const dy = SPOTS.dylanRock.y;
  return (
    <AbsoluteFill style={{background: '#12062a', overflow: 'hidden'}}>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <defs>
          <linearGradient id="sky4" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#1a0838" />
            <stop offset="1" stopColor="#3a1466" />
          </linearGradient>
          <radialGradient id="aura4">
            <stop offset="0" stopColor={PURPLE} stopOpacity="0.85" />
            <stop offset="1" stopColor={PURPLE} stopOpacity="0" />
          </radialGradient>
        </defs>
        <Ocean t={t} night={1} />
        {/* Cielo tormentoso con el horizonte */}
        <rect x={0} y={0} width={1080} height={1010} fill="url(#sky4)" />
        {Array.from({length: 9}).map((_, i) => (
          <ellipse key={i} cx={random(`c${i}`) * 1080} cy={700 + random(`cy${i}`) * 260} rx={260 + random(`cr${i}`) * 200} ry={60 + random(`ch${i}`) * 40} fill="#2a0f4a" opacity={0.75} />
        ))}
        <path d="M820 640 L770 790 L815 785 L760 940" fill="none" stroke="#e9d5ff" strokeWidth={8} strokeLinejoin="round" style={{filter: `drop-shadow(0 0 16px ${PURPLE})`}} />
        <rect x={0} y={1002} width={1080} height={12} fill={PURPLE} opacity={0.45} />
        {/* Barcos de la visión en el horizonte */}
        <g opacity={0.8} style={{filter: `drop-shadow(0 0 22px ${PURPLE})`}}>
          {[[290, 1015, 0.9], [540, 1030, 1.15], [790, 1015, 0.9]].map(([x, y, s], k) => (
            <Ship key={k} x={x} y={y} s={s} o={1} />
          ))}
        </g>
        {/* La isla abajo, de noche */}
        <g transform={cam(1.0, 540, 975, 1580)}>
          <IslandWorld t={t} pop={188} maxShown={70} size={1.35}>
            <Landmarks t={t} rock={false} />
          </IslandWorld>
          <rect x={-1000} y={-1000} width={3000} height={4000} fill="#12062a" opacity={0.35} />
          {/* Rayo de la visión desde Dylan hacia los barcos */}
          <path d={`M${dx - 30} ${dy - 90} L${dx - 340} ${dy - 420} L${dx + 340} ${dy - 420} L${dx + 30} ${dy - 90} Z`} fill={PURPLE} opacity={0.22} />
          <circle cx={dx} cy={dy - 50} r={170} fill="url(#aura4)" />
          <ellipse cx={dx} cy={dy + 4} rx={40} ry={16} fill="#9aa3b8" />
          <g transform={`translate(${dx} ${dy}) scale(1.4) translate(${-dx} ${-dy})`}>
            <Villager x={dx} y={dy} t={t} seed={7} s={1.7} shirt={PURPLE} crown wave={50} />
          </g>
          {[-9, 9].map((ex) => (
            <circle key={ex} cx={dx + ex} cy={dy - 66} r={6} fill="#f5e9ff" style={{filter: `drop-shadow(0 0 10px ${PURPLE})`}} />
          ))}
        </g>
      </svg>
      <div style={{position: 'absolute', top: 40, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <Pill color="rgba(255,255,255,0.14)" text="#fff" size={34} style={{border: '2px solid rgba(255,255,255,0.3)'}}>
          188 HABITANTES · LA CIVILIZACIÓN
        </Pill>
      </div>
      <div style={{position: 'absolute', top: 130, left: 30, right: 30, display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 18}}>
        <BigText size={200} color="#fff">DÍA 4</BigText>
        <BigText size={104} color={PURPLE}>
          DYLAN HA
          <br />
          <span style={{color: C.accent}}>VISTO ALGO…</span>
        </BigText>
        <div style={{marginTop: 10, background: C.red, borderRadius: 999, padding: '14px 40px', fontFamily: FONT, fontWeight: 900, fontSize: 60, color: '#fff', border: '6px solid #05060f', boxShadow: `0 0 50px ${C.red}`}}>LLEGAN EN 3 DÍAS</div>
      </div>
    </AbsoluteFill>
  );
};
