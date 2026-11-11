import React from 'react';
import {AbsoluteFill, random} from 'remotion';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, lin, r, useT} from '../tunel/lib';
import {BHDefs, Bed, Desk, Floor, H, Lamp, MiniHole, Person, Poster, RoomWindow, Suck, WallTiles} from './Parts';

const easeIn = (x) => x * x;

// =====================================================================
// 1-3. LA HABITACIÓN: aparece la moneda, cámara superlenta y succión (0 – 28.7 s)
// =====================================================================
const AIR = Array.from({length: 90}).map((_, i) => ({
  a: random(`aa${i}`) * Math.PI * 2,
  d: 250 + random(`ad${i}`) * 700,
  sp: 0.6 + random(`as${i}`) * 0.9,
  ph: random(`ap${i}`),
}));

export const RoomScene = () => {
  const t = useT();

  // Momentos clave (segundos de la voz)
  const slow = t >= 12.6 && t < 17.68; // cámara superlenta
  const chaos = t >= 17.68;
  const tremble = t > 7.64 ? lin(t, 7.64, 8.4, 6, 1.5) + (chaos ? lin(t, 17.7, 28.5, 3, 14) : 0) : 0;
  const shx = Math.sin(t * 70) * tremble;
  const shy = Math.cos(t * 53) * tremble;
  const zoom = r(t, 0, 12, 1, 1.1, INOUT) + (chaos ? r(t, 25.5, 28.6, 0, 0.35, INOUT) : 0);

  // Progreso de succión de cada objeto
  const pWindow = r(t, 19.9, 21.2, 0, 1, easeIn);
  const pLamp = r(t, 20.1, 21.5, 0, 1, easeIn);
  const pBed = r(t, 20.64, 22.1, 0, 1, easeIn);
  const pPoster = r(t, 21.5, 22.6, 0, 1, easeIn);
  const pDesk = r(t, 21.8, 23.1, 0, 1, easeIn);
  const pFloor = r(t, 22.3, 24.0, 0, 1, easeIn);
  const pPerson = t < 26.08 ? r(t, 22.72, 25.6, 0, 0.62, INOUT) : r(t, 26.08, 28.5, 0.62, 1, easeIn);
  const spaghetti = r(t, 26.08, 28.2, 1, 3.2, INOUT);

  // La moneda se convierte en agujero negro
  const coinIn = r(t, 0.25, 0.9, 0, 1, BACK);
  const morph = r(t, 2.55, 3.1, 0, 1, INOUT);
  const flicker = t > 7.64 && t < 8.6 ? (Math.sin(t * 55) > 0.2 ? 0.55 : 0) : 0;

  return (
    <AbsoluteFill>
      <AbsoluteFill
        style={{
          scale: String(zoom),
          translate: `${shx}px ${shy}px`,
          filter: slow ? 'saturate(0.25) contrast(1.1)' : chaos ? 'saturate(1.25)' : 'none',
          transformOrigin: `${H.x}px ${H.y}px`,
        }}
      >
        <svg width={1080} height={1920} viewBox="0 0 1080 1920">
          <BHDefs />
          {/* Pared: se rompe en bloques */}
          {WallTiles.map((w, i) => {
            const dist = Math.hypot(w.x + w.w / 2 - H.x, w.y + w.h / 2 - H.y);
            const st = 21.6 + dist / 900 + w.k * 0.3;
            const p = r(t, st, st + 1.4, 0, 1, easeIn);
            return (
              <Suck key={i} ax={w.x + w.w / 2} ay={w.y + w.h / 2} p={p}>
                <rect x={w.x} y={w.y} width={w.w + 1} height={w.h + 1} fill={w.k > 0.5 ? '#2d3363' : '#2a305c'} />
                <rect x={w.x + 6} y={w.y + 6} width={w.w - 12} height={w.h - 12} fill="none" stroke="#353c72" strokeWidth={3} />
              </Suck>
            );
          })}
          {/* Grietas de la pared */}
          {t > 21.3 && t < 23.5
            ? Array.from({length: 9}).map((_, k) => {
                const a = (k / 9) * Math.PI * 2 + 0.3;
                const len = r(t, 21.3, 21.9, 0, 520);
                return (
                  <polyline
                    key={k}
                    points={[0, 0.3, 0.6, 1].map((u, j) => `${H.x + Math.cos(a + (j % 2 ? 0.08 : -0.06)) * len * u},${H.y + Math.sin(a + (j % 2 ? 0.08 : -0.06)) * len * u}`).join(' ')}
                    fill="none"
                    stroke="#0a0b18"
                    strokeWidth={6}
                  />
                );
              })
            : null}
          <Suck ax={540} ay={1280} p={pFloor}>
            <Floor />
          </Suck>
          <Suck ax={260} ay={485} p={pWindow}>
            <RoomWindow t={t} />
          </Suck>
          <Suck ax={800} ay={435} p={pPoster}>
            <Poster />
          </Suck>
          <Suck ax={250} ay={1040} p={pDesk}>
            <Desk />
          </Suck>
          <Suck ax={150} ay={830} p={pLamp}>
            <Lamp />
          </Suck>
          <Suck ax={840} ay={1030} p={pBed}>
            <Bed />
          </Suck>

          {/* Corrientes de aire hacia el agujero */}
          {t > 19.7
            ? AIR.map((a, i) => {
                const u = (a.ph + (t - 19.7) * a.sp) % 1;
                const d = a.d * (1 - u * u);
                const x = H.x + Math.cos(a.a) * d;
                const y = H.y + Math.sin(a.a) * d;
                const tail = 40 + 120 * u;
                return (
                  <line
                    key={i}
                    x1={x}
                    y1={y}
                    x2={x + Math.cos(a.a) * tail}
                    y2={y + Math.sin(a.a) * tail}
                    stroke="#cfe9ff"
                    strokeOpacity={0.5 * Math.sin(u * Math.PI) * lin(t, 19.7, 20.2, 0, 1)}
                    strokeWidth={4}
                    strokeLinecap="round"
                  />
                );
              })
            : null}

          {/* Tú */}
          <Suck ax={400} ay={1000} p={pPerson} extra={spaghetti}>
            <Person x={400} y={1000} s={1} wave={Math.sin(t * 3) * 6} scared={t > 7.64 ? 1 : 0} />
          </Suck>

          {/* Moneda -> agujero negro */}
          <g transform={`translate(${H.x} ${H.y})`}>
            {morph < 1 ? (
              <g opacity={1 - morph} transform={`scale(${coinIn * (1 - morph * 0.5)} ${coinIn})`}>
                <g transform={`scale(${Math.abs(Math.cos(t * 5))} 1)`}>
                  <circle r={30} fill="#f2c94c" stroke="#b8860b" strokeWidth={5} />
                  <circle r={20} fill="none" stroke="#d4a017" strokeWidth={3} />
                </g>
              </g>
            ) : null}
            {morph > 0 ? (
              <g transform={`scale(${morph * (chaos ? 1 + lin(t, 17.7, 28.6, 0, 0.8) : 1)})`}>
                <MiniHole t={t} r={22} glow={1 + (chaos ? 0.6 : 0)} />
              </g>
            ) : null}
            {t > 2.55 && t < 3.3 ? <circle r={lin(t, 2.55, 3.3, 10, 380)} fill="none" stroke="#fff" strokeWidth={10} opacity={lin(t, 2.55, 3.3, 0.9, 0)} /> : null}
          </g>
        </svg>
      </AbsoluteFill>

      {flicker ? <AbsoluteFill style={{background: '#000', opacity: flicker}} /> : null}
      {t > 7.64 && t < 12.6 ? (
        <AbsoluteFill style={{background: 'radial-gradient(circle at 50% 38%, transparent 40%, rgba(160,0,30,0.45) 100%)', opacity: lin(t, 7.64, 8.2, 0, 1)}} />
      ) : null}

      {/* Etiqueta de tamaño */}
      <Pop at={3.1} out={7.5} style={{top: H.y + 60, left: H.x + 50}}>
        <Pill color="#fff" size={40}>
          ≈ 2 cm
        </Pill>
      </Pop>

      {/* Pequeño. Silencioso. Inofensivo… ¿verdad? */}
      <div style={{position: 'absolute', top: 240, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 14}}>
        {[
          ['PEQUEÑO', 4.32],
          ['SILENCIOSO', 5.28],
          ['INOFENSIVO…', 6.56],
        ].map(([w, at]) => (
          <Chip key={w} t={t} at={at} out={7.64}>
            {w}
          </Chip>
        ))}
      </div>
      <Pop at={7.64} out={12.4} style={{top: 210, left: 0, right: 0}}>
        <BigText size={130} color={C.red} style={{translate: `${shx}px 0`}}>
          ¿VERDAD?
        </BigText>
      </Pop>
      <Pop at={8.56} out={12.4} style={{top: 1250, left: 0, right: 0}}>
        <Pill color={C.accent} size={46}>
          QUÉDATE HASTA EL FINAL ↓
        </Pill>
      </Pop>

      {/* Cámara superlenta */}
      {slow ? <SlowMoOverlay t={t} /> : null}

      {/* Marca de tiempo */}
      <Pop at={17.68} style={{top: 220, left: 0, right: 0}}>
        <Stamp t={t} />
      </Pop>
      <Pop at={26.3} style={{top: 1250, left: 0, right: 0}}>
        <Pill color={C.accent} size={50}>
          ESPAGUETIFICACIÓN
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

const Chip = ({t, at, out, children}) => {
  if (t < at) return <div style={{width: 0}} />;
  const s = r(t, at, at + 0.35, 0, 1, BACK);
  const o = lin(t, out, out + 0.25, 1, 0);
  return (
    <div
      style={{
        fontFamily: FONT,
        fontWeight: 900,
        fontSize: 44,
        color: '#0b0b14',
        background: '#fff',
        borderRadius: 40,
        padding: '10px 24px',
        scale: String(s),
        opacity: o,
        boxShadow: '0 10px 30px rgba(0,0,0,0.4)',
      }}
    >
      {children}
    </div>
  );
};

const SlowMoOverlay = ({t}) => {
  const digits = `0,00000${Math.floor((t * 7) % 10)}`;
  const slam = r(t, 16.08, 16.5, 0, 1, BACK);
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{border: '26px solid rgba(0,0,0,0.85)', boxShadow: 'inset 0 0 220px rgba(0,0,0,0.9)'}} />
      <div style={{position: 'absolute', top: 230, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <div style={{display: 'flex', alignItems: 'center', gap: 16, fontFamily: FONT, fontWeight: 900, fontSize: 40, color: '#fff'}}>
          <div style={{width: 26, height: 26, borderRadius: 13, background: C.red, opacity: Math.sin(t * 8) > 0 ? 1 : 0.2}} />
          REC · ×1.000.000
        </div>
      </div>
      <div style={{position: 'absolute', top: 300, left: 0, right: 0, display: 'flex', justifyContent: 'center'}}>
        <div
          style={{
            fontFamily: 'JetBrains Mono, monospace',
            fontWeight: 800,
            fontSize: 92,
            color: C.accent,
            background: 'rgba(0,0,0,0.6)',
            padding: '6px 28px',
            borderRadius: 20,
          }}
        >
          {digits} s
        </div>
      </div>
      {t > 16.08 ? (
        <div style={{position: 'absolute', top: 1180, left: 0, right: 0, display: 'flex', justifyContent: 'center', scale: String(0.6 + 0.4 * slam), opacity: slam}}>
          <BigText size={96} color={C.cyan}>
            CÁMARA SUPERLENTA
          </BigText>
        </div>
      ) : null}
    </AbsoluteFill>
  );
};

const Stamp = ({t}) => {
  const tenth = t >= 28.6;
  return (
    <div
      style={{
        display: 'flex',
        alignItems: 'center',
        gap: 14,
        fontFamily: FONT,
        fontWeight: 900,
        fontSize: 54,
        color: '#fff',
        background: 'rgba(8,12,30,0.85)',
        border: `4px solid ${C.red}`,
        borderRadius: 50,
        padding: '10px 30px',
      }}
    >
      <svg width={52} height={52} viewBox="-26 -26 52 52">
        <circle r={21} fill="none" stroke="#fff" strokeWidth={5} />
        <line x1={0} y1={0} x2={0} y2={-14} stroke="#fff" strokeWidth={5} strokeLinecap="round" transform={`rotate(${t * 40})`} />
        <rect x={-5} y={-30} width={10} height={6} rx={2} fill="#fff" />
      </svg>
      <span>
        {tenth ? '0,1' : '0,000001'} <span style={{color: C.accent}}>s</span>
      </span>
    </div>
  );
};

// =====================================================================
// 4. UNA DÉCIMA DE SEGUNDO: la ciudad se hunde (28.7 – 34.3 s)
// =====================================================================
const BUILDINGS = Array.from({length: 18}).map((_, i) => ({
  x: -30 + i * 66 + random(`bx${i}`) * 30,
  w: 54 + random(`bw${i}`) * 60,
  h: 140 + random(`bh${i}`) * 360,
  c: ['#1d2550', '#232c5e', '#1a2048', '#2a3366'][i % 4],
  seed: i,
}));

export const CityScene = () => {
  const t = useT();
  const D = r(t, 29.0, 34.0, 0, 620, INOUT);
  const W = lin(t, 29.0, 34.0, 110, 340);
  const GY = 1180;
  const gy = (x) => GY + D * Math.exp(-(((x - 540) / W) ** 2));
  const slope = (x) => (gy(x + 1) - gy(x - 1)) / 2;
  const groundPts = Array.from({length: 109}).map((_, i) => `${i * 10},${gy(i * 10).toFixed(1)}`);
  const holeY = gy(540) - 10;

  return (
    <AbsoluteFill>
      <AbsoluteFill style={{background: 'linear-gradient(#060a22 0%, #121a46 60%, #2a2050 100%)'}} />
      <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
        <BHDefs />
        <circle cx={860} cy={360} r={60} fill="#fdf3c4" opacity={0.9} />
        {/* Edificios inclinándose hacia el centro */}
        {BUILDINGS.map((b) => {
          const pull = r(t, 29.0 + Math.abs(b.x - 540) / 900, 34.2, 0, 1, (x) => x * x);
          const bx = 540 + (b.x - 540) * (1 - 0.55 * pull);
          const by = gy(bx);
          const ang = (Math.atan(slope(bx)) * 180) / Math.PI;
          const lean = (b.x < 540 ? 1 : -1) * 25 * pull;
          const gone = Math.abs(bx - 540) < 60 && pull > 0.6;
          if (gone) return null;
          return (
            <g key={b.seed} transform={`translate(${bx} ${by}) rotate(${ang + lean}) scale(${1 - 0.3 * pull} ${1 + 0.6 * pull})`}>
              <rect x={-b.w / 2} y={-b.h} width={b.w} height={b.h} fill={b.c} stroke="#0b1030" strokeWidth={3} />
              {Array.from({length: Math.floor(b.h / 34)}).map((_, row) =>
                [0, 1, 2].map((col) =>
                  random(`win${b.seed}-${row}-${col}`) > 0.45 ? (
                    <rect key={`${row}-${col}`} x={-b.w / 2 + 8 + col * ((b.w - 16) / 3)} y={-b.h + 12 + row * 34} width={(b.w - 16) / 3 - 6} height={16} fill="#ffd27a" opacity={0.85} />
                  ) : null,
                ),
              )}
            </g>
          );
        })}
        {/* Suelo hundiéndose */}
        <path d={`M0,1920 L${groundPts.join(' L')} L1080,1920 Z`} fill="#141020" />
        <polyline points={groundPts.join(' ')} fill="none" stroke={C.hot} strokeWidth={6} opacity={0.8} />
        {/* Escombros cayendo */}
        {Array.from({length: 40}).map((_, i) => {
          const u = (random(`dbu${i}`) + (t - 29) * (0.4 + random(`dbs${i}`) * 0.6)) % 1;
          const sx = random(`dbx${i}`) * 1080;
          const x = sx + (540 - sx) * u * u;
          const y = gy(sx) - 60 + (holeY - gy(sx) + 60) * u * u;
          return t > 29.4 ? <rect key={i} x={x} y={y} width={10} height={10} fill="#8a7a9a" transform={`rotate(${t * 200 + i * 30} ${x + 5} ${y + 5})`} /> : null;
        })}
        <g transform={`translate(540 ${holeY})`}>
          <MiniHole t={t} r={30} glow={1.5} />
        </g>
      </svg>
      <Pop at={28.75} style={{top: 220, left: 0, right: 0}}>
        <div
          style={{
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: 54,
            color: '#fff',
            background: 'rgba(8,12,30,0.85)',
            border: `4px solid ${C.red}`,
            borderRadius: 50,
            padding: '10px 30px',
          }}
        >
          0,1 <span style={{color: C.accent}}>s</span>
        </div>
      </Pop>
      <Pop at={32.08} style={{top: 340, left: 0, right: 0}}>
        <BigText size={100} color={C.accent}>
          TODA TU CIUDAD
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};
