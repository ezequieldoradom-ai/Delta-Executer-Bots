import React from 'react';
import {AbsoluteFill, random} from 'remotion';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, fmt, lin, r, useT} from './lib';
import {Astronaut, Camera, EarthDefs, EarthSection, R, SvgLabel, tunnelY} from './Visuals';

// =====================================================================
// 1. GANCHO (0 – 9 s): un agujero visto desde arriba que brilla al fondo
// =====================================================================
const GRASS = Array.from({length: 260}).map((_, i) => {
  const a = random(`ga${i}`) * Math.PI * 2;
  const d = 380 + random(`gd${i}`) * 900;
  return {x: 540 + Math.cos(a) * d, y: 800 + Math.sin(a) * d, l: 10 + random(`gl${i}`) * 18, k: random(`gk${i}`)};
});

export const HookScene = () => {
  const t = useT();
  const zoom = lin(t, 0, 9, 1, 1.5);
  const shakeAmt = t > 7.35 ? lin(t, 7.35, 8.4, 22, 0) : 0;
  const shakeX = Math.sin(t * 95) * shakeAmt;
  const shakeY = Math.cos(t * 77) * shakeAmt;
  const rings = Array.from({length: 12}).map((_, k) => {
    const ph = (k / 12 + t * 0.3) % 1;
    return {rad: 18 + 315 * Math.pow(ph, 2.4), ph};
  });
  const glow = 0.6 + 0.4 * Math.sin(t * 4);

  // El astronauta salta al agujero
  const fall = r(t, 2.9, 4.3, 0, 1, Easing2);
  const minutes = lin(t, 3.9, 6.5, 0, 38);
  const mm = String(Math.floor(minutes)).padStart(2, '0');
  const ss = String(Math.floor((minutes % 1) * 60)).padStart(2, '0');

  return (
    <AbsoluteFill>
      <AbsoluteFill style={{scale: String(zoom), translate: `${shakeX}px ${shakeY}px`}}>
        <AbsoluteFill
          style={{background: 'radial-gradient(circle at 50% 42%, #5a9a46 0%, #3a6a2f 35%, #1a3517 100%)'}}
        />
        <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
          <defs>
            <radialGradient id="hole">
              <stop offset="0" stopColor="#ff9a2e" stopOpacity={0.9 * glow} />
              <stop offset="0.12" stopColor="#5a1d08" />
              <stop offset="0.55" stopColor="#0b0604" />
              <stop offset="0.93" stopColor="#1c130c" />
              <stop offset="1" stopColor="#3a2716" />
            </radialGradient>
          </defs>
          {GRASS.map((g, i) => (
            <line
              key={i}
              x1={g.x}
              y1={g.y}
              x2={g.x + Math.sin(t * 2 + i) * 3}
              y2={g.y - g.l}
              stroke={g.k > 0.5 ? '#7cc46a' : '#4f8f40'}
              strokeWidth={3}
              strokeLinecap="round"
            />
          ))}
          <g transform="translate(540 800)">
            <circle r={372} fill="#5b3f27" />
            <circle r={356} fill="#3d2a19" />
            <circle r={340} fill="url(#hole)" />
            {rings.map((g, k) => (
              <circle
                key={k}
                r={g.rad}
                fill="none"
                stroke={g.ph < 0.35 ? '#ff8a2a' : '#7a5332'}
                strokeOpacity={g.ph < 0.35 ? 0.55 * (1 - g.ph) : 0.35 * g.ph}
                strokeWidth={2 + 5 * g.ph}
              />
            ))}
            <circle r={40 + 10 * glow} fill="#ffd27a" opacity={0.35 * glow} style={{filter: 'blur(14px)'}} />
          </g>
          {t >= 2.9 && fall < 1 ? (
            <Astronaut
              x={540 + Math.sin(fall * 6) * 30 * (1 - fall)}
              y={lin(fall, 0, 1, 330, 800)}
              size={lin(fall, 0, 1, 230, 8)}
              rot={fall * 540}
              wave={Math.sin(t * 20) * 25}
            />
          ) : null}
        </svg>
      </AbsoluteFill>

      <Pop at={0.05} out={2.7} style={{top: 270, left: 0, right: 0}}>
        <BigText size={92}>
          UN TÚNEL QUE
          <br />
          <span style={{color: C.accent}}>ATRAVIESA LA TIERRA</span>
        </BigText>
      </Pop>

      <Pop at={3.74} out={7.2} style={{top: 640, left: 0, right: 0, flexDirection: 'column'}}>
        <BigText size={210} color={C.accent} stroke={14}>
          {mm}:{ss}
        </BigText>
        <Pill size={50} style={{marginTop: 20}}>MINUTOS AL OTRO LADO</Pill>
      </Pop>

      {t >= 7.35 ? (
        <AbsoluteFill style={{background: C.red, opacity: lin(t, 7.35, 7.9, 0.55, 0.12), mixBlendMode: 'multiply'}} />
      ) : null}
      <Pop at={7.35} style={{top: 560, left: 0, right: 0, flexDirection: 'column'}}>
        <Skull t={t} />
        <BigText size={140} color={C.red} style={{marginTop: 10, translate: `${shakeX * 0.6}px 0`}}>
          ¿O MUERES?
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

const Easing2 = (x) => x * x;

const Skull = ({t}) => {
  const jaw = Math.abs(Math.sin(t * 14)) * 10;
  return (
    <svg width={240} height={260} viewBox="-120 -130 240 260">
      <path d="M-95 0 A95 100 0 1 1 95 0 L95 30 Q95 55 70 60 L-70 60 Q-95 55 -95 30 Z" fill="#fff" stroke="#05060f" strokeWidth={10} />
      <ellipse cx={-40} cy={0} rx={28} ry={32} fill="#05060f" />
      <ellipse cx={40} cy={0} rx={28} ry={32} fill="#05060f" />
      <path d="M0 30 L-12 50 L12 50 Z" fill="#05060f" />
      <g transform={`translate(0 ${jaw})`}>
        <rect x={-60} y={66} width={120} height={46} rx={14} fill="#fff" stroke="#05060f" strokeWidth={10} />
        {[-30, 0, 30].map((x) => (
          <line key={x} x1={x} y1={70} x2={x} y2={108} stroke="#05060f" strokeWidth={8} />
        ))}
      </g>
    </svg>
  );
};

// =====================================================================
// 2. EL TÚNEL Y EL SALTO (9 – 19.75 s)
// =====================================================================
export const TunnelIntroScene = () => {
  const t = useT();
  const tunnel = r(t, 9.15, 10.8, 0, 1, INOUT);
  const km = lin(t, 9.2, 11.4, 0, 12742);
  const zoomIn = r(t, 15.28, 16.6, 0, 1, INOUT);
  const zoom = r(t, 9.05, 9.8, 0.7, 1) + zoomIn * 1.9;
  const fy = zoomIn * -400;

  // caída lenta al principio (casi no se mueve)
  const theta = lin(t, 15.28, 19.75, 0, 0.42) ** 1.6;
  const personY = t < 15.28 ? -R - 60 : tunnelY(theta) - lin(t, 15.28, 15.9, 50, 0);
  const labelsOut = lin(t, 15.0, 15.4, 1, 0);

  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        <EarthDefs />
        <Camera zoom={zoom} fy={fy}>
          <g transform={`rotate(${lin(t, 9.05, 9.8, -30, 0)})`}>
            <EarthSection t={t} tunnel={tunnel} />
          </g>
          {t >= 15.0 ? (
            <g opacity={lin(t, 15.0, 15.3, 0, 1)}>
              <FloatingStuff t={t} y={personY} />
              <Astronaut
                y={personY}
                size={46}
                rot={Math.sin(t * 1.3) * 25 + lin(t, 16.3, 19.7, 0, 90)}
                wave={Math.sin(t * 3) * 20}
              />
            </g>
          ) : null}
        </Camera>

        {/* Cota de 12.742 km */}
        <g opacity={Math.min(lin(t, 9.2, 9.5, 0, 1), labelsOut)}>
          <line x1={600} y1={340} x2={600} y2={340 + 880 * tunnel} stroke={C.accent} strokeWidth={6} strokeDasharray="18 12" />
          <path d="M585 355 L600 335 L615 355" fill="none" stroke={C.accent} strokeWidth={6} />
          {tunnel > 0.98 ? <path d="M585 1205 L600 1225 L615 1205" fill="none" stroke={C.accent} strokeWidth={6} /> : null}
        </g>
      </svg>

      <Pop at={9.4} out={15.0} style={{top: 690, left: 630}}>
        <Pill size={58}>{fmt(km)} km</Pill>
      </Pop>
      <Pop at={11.86} out={15.0} style={{top: 220, left: 0, right: 0}}>
        <Pill color={C.cyan}>POLO NORTE</Pill>
      </Pop>
      <Pop at={12.82} out={15.0} style={{top: 1250, left: 0, right: 0}}>
        <Pill color={C.cyan}>POLO SUR</Pill>
      </Pop>
      <Pop at={13.8} out={15.0} style={{top: 700, left: 40}}>
        <NoAirBadge />
      </Pop>

      <Pop at={18.54} out={19.6} style={{top: 1180, left: 0, right: 0}}>
        <Pill color={C.cyan} size={56}>
          INGRAVIDEZ · 0 g
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

const NoAirBadge = () => (
  <div
    style={{
      background: C.panel,
      border: `4px solid ${C.red}`,
      borderRadius: 30,
      padding: '18px 26px',
      display: 'flex',
      alignItems: 'center',
      gap: 16,
      fontFamily: FONT,
      fontWeight: 900,
      fontSize: 48,
      color: '#fff',
    }}
  >
    <svg width={70} height={70} viewBox="-35 -35 70 70">
      <path d="M-22 -8 Q-5 -20 8 -8 T28 -8" fill="none" stroke="#9fd8ff" strokeWidth={6} strokeLinecap="round" />
      <path d="M-26 8 Q-9 -4 4 8 T24 8" fill="none" stroke="#9fd8ff" strokeWidth={6} strokeLinecap="round" />
      <circle r={31} fill="none" stroke={C.red} strokeWidth={6} />
      <line x1={-22} y1={22} x2={22} y2={-22} stroke={C.red} strokeWidth={6} />
    </svg>
    SIN AIRE
  </div>
);

const FloatingStuff = ({t, y}) => {
  const items = [
    {a: 0, d: 50, kind: 'phone'},
    {a: 2.1, d: 58, kind: 'cap'},
    {a: 4.2, d: 46, kind: 'coin'},
  ];
  return (
    <g>
      {items.map((it, i) => {
        const a = it.a + t * 0.9;
        const x = Math.cos(a) * it.d;
        const yy = y + Math.sin(a) * it.d * 0.8;
        const rot = t * 60 * (i % 2 ? 1 : -1);
        return (
          <g key={i} transform={`translate(${x} ${yy}) rotate(${rot})`}>
            {it.kind === 'phone' ? (
              <>
                <rect x={-6} y={-11} width={12} height={22} rx={3} fill="#222" />
                <rect x={-4.5} y={-8.5} width={9} height={16} rx={1.5} fill="#5ee7ff" />
              </>
            ) : it.kind === 'cap' ? (
              <>
                <path d="M-10 2 A10 10 0 0 1 10 2 Z" fill={C.red} />
                <rect x={4} y={0} width={12} height={3.5} rx={1.5} fill={C.red} />
              </>
            ) : (
              <circle r={6} fill={C.accent} stroke="#b88a00" strokeWidth={2} />
            )}
          </g>
        );
      })}
    </g>
  );
};

// =====================================================================
// 3. LA GRAVEDAD AUMENTA AL BAJAR (19.75 – 29.35 s)
// =====================================================================
// Gravedad (m/s²) frente a profundidad (km), aproximación del modelo PREM
const G_DATA = [
  [0, 9.82], [400, 9.97], [700, 10.0], [1000, 9.95], [1500, 9.9], [2000, 9.96],
  [2500, 10.2], [2891, 10.68], [3500, 9.3], [4000, 8.0], [4500, 6.6], [5150, 4.4],
  [5700, 2.5], [6371, 0],
];
const gAt = (d) => {
  for (let i = 0; i < G_DATA.length - 1; i++) {
    const [d0, g0] = G_DATA[i];
    const [d1, g1] = G_DATA[i + 1];
    if (d <= d1) {
      const u = (d - d0) / (d1 - d0);
      const s = u * u * (3 - 2 * u);
      return g0 + (g1 - g0) * s;
    }
  }
  return 0;
};

const CH = {x0: 150, x1: 960, y0: 1240, y1: 540, gMax: 12, dMax: 6371};
const px = (d) => CH.x0 + ((CH.x1 - CH.x0) * d) / CH.dMax;
const py = (g) => CH.y0 - ((CH.y0 - CH.y1) * g) / CH.gMax;

const curvePath = (dEnd) => {
  const pts = [];
  for (let d = 0; d <= dEnd; d += 40) {
    pts.push(`${px(d).toFixed(1)},${py(gAt(d)).toFixed(1)}`);
  }
  pts.push(`${px(dEnd).toFixed(1)},${py(gAt(dEnd)).toFixed(1)}`);
  return `M${pts.join(' L')}`;
};

export const GravityScene = () => {
  const t = useT();
  const axes = r(t, 19.9, 20.6, 0, 1);
  const depth =
    t < 26.9 ? r(t, 21.49, 24.2, 0, 2891, INOUT) : r(t, 26.93, 29.0, 2891, 6371, INOUT);
  const zones = lin(t, 25.38, 25.8, 0, 1);
  const peak = r(t, 24.26, 24.7, 0, 1, BACK);

  return (
    <AbsoluteFill>
      <Pop at={19.85} style={{top: 230, left: 0, right: 0}}>
        <BigText size={78}>
          ¿QUÉ PASA CON LA <span style={{color: C.accent}}>GRAVEDAD</span>?
        </BigText>
      </Pop>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        <g opacity={zones}>
          <rect x={px(0)} y={CH.y1} width={px(2891) - px(0)} height={CH.y0 - CH.y1} fill="#ff6a2a" opacity={0.16} />
          <rect x={px(2891)} y={CH.y1} width={px(6371) - px(2891)} height={CH.y0 - CH.y1} fill="#ffd34d" opacity={0.18} />
          <SvgLabel x={(px(0) + px(2891)) / 2} y={CH.y1 + 50} size={32} color="#ffb28a">
            MANTO
          </SvgLabel>
          <SvgLabel x={(px(2891) + px(6371)) / 2} y={CH.y1 + 50} size={32} color={C.accent}>
            NÚCLEO
          </SvgLabel>
        </g>

        <g opacity={axes}>
          <line x1={CH.x0} y1={CH.y0} x2={CH.x0 + (CH.x1 - CH.x0) * axes} y2={CH.y0} stroke="#fff" strokeWidth={5} />
          <line x1={CH.x0} y1={CH.y0} x2={CH.x0} y2={CH.y0 - (CH.y0 - CH.y1) * axes} stroke="#fff" strokeWidth={5} />
          {[0, 5, 10].map((g) => (
            <g key={g}>
              <line x1={CH.x0 - 12} x2={CH.x1} y1={py(g)} y2={py(g)} stroke="#fff" strokeOpacity={0.12} strokeWidth={2} />
              <SvgLabel x={CH.x0 - 22} y={py(g) + 12} size={30} anchor="end">
                {g}
              </SvgLabel>
            </g>
          ))}
          <SvgLabel x={px(0)} y={CH.y0 + 52} size={30}>
            SUPERFICIE
          </SvgLabel>
          <SvgLabel x={px(6371) - 20} y={CH.y0 + 52} size={30}>
            CENTRO
          </SvgLabel>
          <SvgLabel x={(CH.x0 + CH.x1) / 2} y={CH.y0 + 110} size={34} color={C.cyan}>
            PROFUNDIDAD →
          </SvgLabel>
          <SvgLabel x={CH.x0 - 40} y={CH.y1 - 30} size={30} color={C.cyan} anchor="start">
            GRAVEDAD (m/s²)
          </SvgLabel>
        </g>

        {/* Lo que esperarías: baja en línea recta */}
        <g opacity={lin(t, 22.25, 22.6, 0, 1) * lin(t, 25.3, 25.8, 1, 0.35)}>
          <line
            x1={px(0)}
            y1={py(9.82)}
            x2={px(0) + (px(6371) - px(0)) * r(t, 22.25, 23.4, 0, 1)}
            y2={py(9.82) + (py(0) - py(9.82)) * r(t, 22.25, 23.4, 0, 1)}
            stroke="#aab"
            strokeWidth={6}
            strokeDasharray="16 14"
          />
          <SvgLabel x={px(3600)} y={py(4.2)} size={30} color="#c8c8d8">
            LO QUE ESPERARÍAS
          </SvgLabel>
        </g>

        {depth > 0 ? (
          <>
            <path
              d={curvePath(depth)}
              fill="none"
              stroke={C.accent}
              strokeWidth={11}
              strokeLinecap="round"
              strokeLinejoin="round"
              style={{filter: 'drop-shadow(0 0 12px rgba(255,210,63,0.7))'}}
            />
            <Astronaut x={px(depth)} y={py(gAt(depth)) - 46} size={44} rot={Math.sin(t * 4) * 12} />
          </>
        ) : null}

        {t >= 24.26 ? (
          <g transform={`translate(${px(2891)} ${py(10.68)}) scale(${peak})`}>
            <circle r={22} fill={C.hot} stroke="#fff" strokeWidth={6} />
          </g>
        ) : null}
      </svg>

      <Pop at={24.26} style={{top: py(10.68) + 40, left: px(2891) + 20, flexDirection: 'column'}}>
        <Pill color={C.hot} text="#fff" size={56}>
          ▲ +10 %
        </Pill>
      </Pop>
      <Pop at={27.0} style={{top: py(2) - 40, left: 560}}>
        <Pill color={C.cyan} size={40}>
          0 EN EL CENTRO
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

