import React from 'react';
import {AbsoluteFill, random} from 'remotion';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, fmt, lin, r, useT} from './lib';
import {
  Astronaut,
  Camera,
  Check,
  EarthDefs,
  EarthSection,
  Heart,
  R,
  SvgLabel,
  VMAX,
  minutesAt,
  speedAt,
  tunnelY,
} from './Visuals';

const PI = Math.PI;

// =====================================================================
// 4. EL VIAJE: centro, salida por las antípodas y péndulo (29.35 – 54.8 s)
// =====================================================================
const thetaAt = (t) => {
  if (t < 34.4) return lin(t, 29.35, 34.4, 0.25, PI / 2);
  if (t < 38.85) return lin(t, 34.4, 38.85, PI / 2, PI / 2 + 0.06); // cámara lenta
  if (t < 40.9) return lin(t, 38.85, 40.9, PI / 2 + 0.06, PI / 2 + 0.55);
  if (t < 47.81) return lin(t, 40.9, 47.81, PI / 2 + 0.55, PI);
  if (t < 51.55) return PI;
  return lin(t, 51.55, 55.0, PI, 5 * PI);
};

const CY = 830;

export const JourneyScene = () => {
  const t = useT();
  const theta = thetaAt(t);
  const y = tunnelY(theta);
  const speed = speedAt(theta);
  const minutes = minutesAt(Math.min(theta, PI));

  const zoomBottom = t < 50 ? r(t, 44.44, 45.9, 0, 1, INOUT) : r(t, 51.55, 52.2, 1, 0, INOUT);
  const zoom = 1 + zoomBottom * 1.4;
  const fy = zoomBottom * 370;

  const rot =
    theta <= PI
      ? lin(theta, PI / 2, PI, 0, 180) + Math.sin(t * 2.2) * 14
      : 180 + (theta - PI) * 180 + Math.sin(t * 3) * 10;

  const ghosts = speed > 8000 && t < 41 ? [1, 2, 3, 4, 5] : t > 51.6 ? [1, 2, 3, 4, 5, 6] : [];
  const ghostStep = t > 51.6 ? 0.18 : 0.06;
  const slowMo = t > 34.5 && t < 38.85;
  const panelsOut = 44.3;

  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        <EarthDefs />
        <Camera cy={CY} zoom={zoom} fy={fy}>
          <EarthSection t={t} />

          {/* Gravedad cero en el centro: tirones iguales en todas direcciones */}
          {t > 37.1 && t < 38.9 ? (
            <g opacity={Math.min(lin(t, 37.1, 37.35, 0, 1), lin(t, 38.6, 38.9, 1, 0))}>
              {[0, 1, 2].map((k) => {
                const ph = (t * 1.2 + k / 3) % 1;
                return <circle key={k} r={30 + ph * 170} fill="none" stroke={C.cyan} strokeWidth={5} opacity={1 - ph} />;
              })}
              {Array.from({length: 8}).map((_, k) => (
                <g key={k} transform={`rotate(${k * 45})`}>
                  <line x1={0} y1={-70} x2={0} y2={-150} stroke="#fff" strokeWidth={7} strokeLinecap="round" />
                  <path d="M-14 -136 L0 -158 L14 -136" fill="none" stroke="#fff" strokeWidth={7} strokeLinecap="round" />
                </g>
              ))}
            </g>
          ) : null}

          {ghosts.map((k) => (
            <Astronaut key={k} y={tunnelY(theta - k * ghostStep)} size={44} rot={rot} opacity={0.32 - k * 0.05} />
          ))}
          {speed > 12000 && t < 41
            ? [-9, 0, 9].map((dx, i) => (
                <line
                  key={i}
                  x1={dx}
                  x2={dx}
                  y1={y - 40 - (speed / VMAX) * 70}
                  y2={y - 40 - (speed / VMAX) * 70 - 60 * (speed / VMAX)}
                  stroke="#fff"
                  strokeOpacity={0.7}
                  strokeWidth={3}
                  strokeLinecap="round"
                />
              ))
            : null}
          <Astronaut y={y} size={44} rot={rot} wave={Math.sin(t * (t > 48.2 && t < 50.4 ? 18 : 4)) * 25} />
        </Camera>
      </svg>

      {slowMo ? (
        <div
          style={{
            position: 'absolute',
            top: 280,
            left: 0,
            right: 0,
            display: 'flex',
            justifyContent: 'center',
            opacity: 0.6 + 0.4 * Math.sin(t * 8),
          }}
        >
          <Pill color="rgba(255,255,255,0.15)" text="#fff" size={34}>
            ● CÁMARA LENTA
          </Pill>
        </div>
      ) : null}

      {/* Paneles: tiempo y velocidad */}
      <Pop at={29.6} out={panelsOut} style={{top: 240, left: 40}}>
        <Panel
          title="TIEMPO"
          value={`${String(Math.floor(minutes)).padStart(2, '0')}:${String(Math.floor((minutes % 1) * 60)).padStart(2, '0')}`}
          unit="MIN"
          glow={t > 42.94 ? lin(t, 42.94, 44.2, 1, 0) : 0}
        />
      </Pop>
      <Pop at={29.75} out={panelsOut} style={{top: 240, right: 40}}>
        <Speedometer speed={speed} />
      </Pop>

      {/* De Madrid a Barcelona en un minuto */}
      <Pop at={34.74} out={36.95} style={{top: 1180, left: 60, right: 60}}>
        <MadridBarcelona t={t} />
      </Pop>

      <Pop at={37.16} out={38.7} style={{top: 1180, left: 0, right: 0}}>
        <Pill color={C.cyan} size={60}>
          GRAVEDAD = 0
        </Pill>
      </Pop>
      <Pop at={38.85} out={40.9} style={{top: 1180, left: 0, right: 0}}>
        <Pill color="#fff" size={56}>
          INERCIA ↓
        </Pill>
      </Pop>
      <Pop at={41.28} out={42.8} style={{top: 1180, left: 0, right: 0}}>
        <Pill color={C.hot} text="#fff" size={56}>
          FRENANDO…
        </Pill>
      </Pop>

      <Pop at={46.12} out={48.1} style={{top: 520, left: 0, right: 0}}>
        <Pill size={60}>QUIETO · 0 km/h</Pill>
      </Pop>
      <Pop at={48.2} out={50.3} style={{top: 470, left: 0, right: 0}}>
        <Countdown t={t} />
      </Pop>
      {t > 50.39 && t < 51.6 ? (
        <AbsoluteFill style={{background: C.red, opacity: lin(t, 50.39, 51.6, 0.35, 0), mixBlendMode: 'multiply'}} />
      ) : null}
      <Pop at={50.39} out={51.5} style={{top: 520, left: 0, right: 0}}>
        <BigText size={120} color={C.red}>
          ¡SI FALLAS…!
        </BigText>
      </Pop>
      <Pop at={52.85} out={53.75} style={{top: 260, left: 0, right: 0}}>
        <BigText size={100}>Y OTRA…</BigText>
      </Pop>
      <Pop at={53.87} style={{top: 230, left: 0, right: 0, flexDirection: 'column'}}>
        <InfinityLoop t={t} />
        <BigText size={92} color={C.accent} style={{marginTop: -10}}>
          PARA SIEMPRE
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

const Panel = ({title, value, unit, glow}) => (
  <div
    style={{
      width: 330,
      background: C.panel,
      border: `3px solid ${glow > 0 ? C.accent : 'rgba(255,255,255,0.18)'}`,
      borderRadius: 30,
      padding: '18px 24px',
      fontFamily: FONT,
      color: '#fff',
      scale: String(1 + glow * 0.25),
      boxShadow: glow > 0 ? `0 0 ${60 * glow}px ${C.accent}` : 'none',
    }}
  >
    <div style={{fontWeight: 800, fontSize: 28, color: C.cyan, letterSpacing: 2}}>{title}</div>
    <div style={{fontWeight: 900, fontSize: 84, lineHeight: 1.05, color: glow > 0 ? C.accent : '#fff'}}>
      {value}
      <span style={{fontSize: 34, marginLeft: 10}}>{unit}</span>
    </div>
  </div>
);

const Speedometer = ({speed}) => {
  const a = -120 + (speed / VMAX) * 240;
  return (
    <div
      style={{
        width: 330,
        background: C.panel,
        border: '3px solid rgba(255,255,255,0.18)',
        borderRadius: 30,
        padding: '14px 20px 16px',
        fontFamily: FONT,
        color: '#fff',
        display: 'flex',
        flexDirection: 'column',
        alignItems: 'center',
      }}
    >
      <svg width={260} height={120} viewBox="-130 -120 260 130">
        <path d="M-105 0 A105 105 0 1 1 105 0" fill="none" stroke="rgba(255,255,255,0.15)" strokeWidth={16} transform="rotate(0)" />
        <path
          d="M-105 0 A105 105 0 0 1 105 0"
          fill="none"
          stroke="url(#spd)"
          strokeWidth={16}
          strokeDasharray={`${(speed / VMAX) * 330} 400`}
          strokeLinecap="round"
        />
        <defs>
          <linearGradient id="spd">
            <stop offset="0" stopColor={C.cyan} />
            <stop offset="1" stopColor={C.hot} />
          </linearGradient>
        </defs>
        <g transform={`rotate(${a * 0.75})`}>
          <line x1={0} y1={0} x2={0} y2={-90} stroke="#fff" strokeWidth={7} strokeLinecap="round" />
        </g>
        <circle r={12} fill="#fff" />
      </svg>
      <div style={{fontWeight: 900, fontSize: 56, lineHeight: 1}}>
        {fmt(Math.round(speed / 100) * 100)}
        <span style={{fontSize: 26, marginLeft: 8}}>km/h</span>
      </div>
    </div>
  );
};

const MadridBarcelona = ({t}) => {
  const p = r(t, 34.9, 35.9, 0, 1, INOUT);
  return (
    <div
      style={{
        background: C.panel,
        borderRadius: 30,
        border: '3px solid rgba(255,255,255,0.18)',
        padding: '20px 30px',
        fontFamily: FONT,
        color: '#fff',
        display: 'flex',
        alignItems: 'center',
        justifyContent: 'space-between',
        gap: 20,
      }}
    >
      <svg width={600} height={110} viewBox="0 0 600 110">
        <line x1={40} y1={70} x2={560} y2={70} stroke="rgba(255,255,255,0.2)" strokeWidth={6} strokeDasharray="12 12" />
        <line x1={40} y1={70} x2={40 + 520 * p} y2={70} stroke={C.accent} strokeWidth={8} strokeLinecap="round" />
        <circle cx={40} cy={70} r={14} fill={C.cyan} />
        <circle cx={560} cy={70} r={14} fill={p > 0.98 ? C.accent : '#fff'} />
        <circle cx={40 + 520 * p} cy={70} r={10} fill="#fff" style={{filter: 'drop-shadow(0 0 10px #fff)'}} />
        <SvgLabel x={40} y={34} size={28} anchor="start">
          MADRID
        </SvgLabel>
        <SvgLabel x={560} y={34} size={28} anchor="end">
          BARCELONA
        </SvgLabel>
      </svg>
      <div style={{fontWeight: 900, fontSize: 60, color: C.accent, opacity: lin(t, 36.0, 36.2, 0, 1)}}>1 MIN</div>
    </div>
  );
};

const Countdown = ({t}) => {
  const p = lin(t, 48.2, 50.2, 1, 0);
  const c = 2 * PI * 80;
  return (
    <div style={{display: 'flex', alignItems: 'center', gap: 24}}>
      <svg width={190} height={190} viewBox="-95 -95 190 190">
        <circle r={80} fill={C.panel} stroke="rgba(255,255,255,0.2)" strokeWidth={14} />
        <circle
          r={80}
          fill="none"
          stroke={p < 0.35 ? C.red : C.accent}
          strokeWidth={14}
          strokeDasharray={`${c * p} ${c}`}
          strokeLinecap="round"
          transform="rotate(-90)"
        />
        <text y={22} textAnchor="middle" fontFamily={FONT} fontWeight={900} fontSize={64} fill="#fff">
          1 s
        </text>
      </svg>
      <BigText size={72}>¡AGÁRRATE!</BigText>
    </div>
  );
};

const InfinityLoop = ({t}) => {
  const p = r(t, 53.87, 54.7, 0, 1);
  const pts = [];
  for (let i = 0; i <= 120; i++) {
    const u = (i / 120) * 2 * PI;
    const d = 1 + Math.sin(u) ** 2;
    pts.push(`${((160 * Math.cos(u)) / d).toFixed(1)},${((160 * Math.sin(u) * Math.cos(u)) / d).toFixed(1)}`);
  }
  const dot = (t * 0.9) % 1;
  const ui = dot * 2 * PI;
  const dd = 1 + Math.sin(ui) ** 2;
  return (
    <svg width={400} height={200} viewBox="-200 -100 400 200">
      <path
        d={`M${pts.join(' L')}`}
        fill="none"
        stroke={C.cyan}
        strokeWidth={16}
        strokeLinecap="round"
        pathLength={1}
        strokeDasharray={`${p} 1`}
      />
      <circle cx={(160 * Math.cos(ui)) / dd} cy={(160 * Math.sin(ui) * Math.cos(ui)) / dd} r={16} fill="#fff" opacity={p} />
    </svg>
  );
};

// =====================================================================
// 5. ¿EL PROBLEMA? (54.8 – 55.95 s)
// =====================================================================
export const ProblemScene = () => {
  const t = useT();
  const g = Math.sin(t * 60) * lin(t, 55.0, 55.5, 16, 2);
  return (
    <AbsoluteFill style={{justifyContent: 'center', alignItems: 'center'}}>
      <Pop at={54.85} style={{top: 520, left: 0, right: 0, flexDirection: 'column'}}>
        <svg width={260} height={230} viewBox="-130 -120 260 230">
          <path d="M0 -105 L120 100 L-120 100 Z" fill={C.accent} stroke="#05060f" strokeWidth={10} strokeLinejoin="round" />
          <rect x={-11} y={-45} width={22} height={95} rx={10} fill="#05060f" />
          <circle cx={0} cy={75} r={13} fill="#05060f" />
        </svg>
        <div style={{position: 'relative', marginTop: 20, width: 1000}}>
          {[
            {c: C.red, dx: g, dy: 4},
            {c: C.cyan, dx: -g, dy: -4},
          ].map((l, i) => (
            <BigText key={i} size={140} color={l.c} style={{position: 'absolute', left: 0, right: 0, translate: `${l.dx}px ${l.dy}px`, opacity: 0.7}}>
              ¿EL
              <br />
              PROBLEMA?
            </BigText>
          ))}
          <BigText size={140}>
            ¿EL
            <br />
            PROBLEMA?
          </BigText>
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 6. CON AIRE TE QUEDAS ATRAPADO (55.95 – 59.15 s)
// =====================================================================
const AIR = Array.from({length: 70}).map((_, i) => ({
  y: -R + random(`ay${i}`) * 2 * R,
  x: -10 + random(`ax${i}`) * 20,
  p: random(`ap${i}`) * 10,
}));

export const AirScene = () => {
  const t = useT();
  const s = Math.max(0, t - 56.1);
  const amp = Math.exp(-s * 1.5);
  const y = -R * amp * Math.cos(s * 2 * PI * 0.85);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        <EarthDefs />
        <Camera cy={860} zoom={0.95}>
          <EarthSection t={t} />
          {AIR.map((a, i) => (
            <circle key={i} cx={a.x + Math.sin(t * 7 + a.p) * 3} cy={a.y + Math.cos(t * 5 + a.p) * 6} r={3} fill="#bfe9ff" opacity={0.8} />
          ))}
          <line x1={-60} x2={60} y1={0} y2={0} stroke="#fff" strokeDasharray="8 8" strokeWidth={3} opacity={lin(t, 57.5, 58, 0, 0.8)} />
          <Astronaut y={y} size={44} rot={Math.sin(t * 3) * 20} />
        </Camera>
      </svg>
      <Pop at={56.04} style={{top: 270, left: 0, right: 0}}>
        <Pill color={C.cyan} size={60}>
          CON AIRE…
        </Pill>
      </Pop>
      <Pop at={57.6} style={{top: 1290, left: 0, right: 0}}>
        <Pill color={C.red} text="#fff" size={52}>
          ATRAPADO EN EL CENTRO
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 7. EL CALOR DEL NÚCLEO (59.15 – 64.2 s)
// =====================================================================
export const HeatScene = () => {
  const t = useT();
  const zoom = r(t, 59.2, 60.4, 1, 2.6, INOUT);
  const temp = r(t, 59.4, 61.4, 15, 5000, INOUT);
  const compare = lin(t, 61.85, 62.25, 0, 1);
  const shimmer = Math.sin(t * 9) * 3;
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{opacity: 1 - compare}}>
        <svg width={1080} height={1920} viewBox="0 0 1080 1920">
          <EarthDefs />
          <Camera cy={830} zoom={zoom}>
            <g transform={`translate(${shimmer} 0)`}>
              <EarthSection t={t} heat={lin(t, 59.5, 60.5, 0, 1)} />
            </g>
          </Camera>
        </svg>
        <div style={{position: 'absolute', top: 360, right: 60}}>
          <Thermo p={lin(temp, 15, 5000, 0.08, 1)} />
        </div>
        <Pop at={59.4} style={{top: 1180, left: 0, right: 0}}>
          <BigText size={150} color={C.accent} stroke={14}>
            +{fmt(Math.round(temp / 10) * 10)} °C
          </BigText>
        </Pop>
      </AbsoluteFill>

      {compare > 0 ? (
        <AbsoluteFill style={{opacity: compare}}>
          <div
            style={{
              position: 'absolute',
              top: 420,
              left: 0,
              right: 0,
              display: 'flex',
              justifyContent: 'center',
              alignItems: 'center',
              gap: 30,
            }}
          >
            <Orb t={t} kind="core" at={62.0} />
            <BigText size={110} color={C.accent}>
              =
            </BigText>
            <Orb t={t} kind="sun" at={62.3} />
          </div>
          <Pop at={62.6} style={{top: 1050, left: 0, right: 0}}>
            <BigText size={70}>
              EL NÚCLEO ARDE COMO
              <br />
              <span style={{color: C.accent}}>LA SUPERFICIE DEL SOL</span>
            </BigText>
          </Pop>
        </AbsoluteFill>
      ) : null}
    </AbsoluteFill>
  );
};

const Thermo = ({p}) => (
  <svg width={110} height={560} viewBox="0 0 110 560">
    <rect x={30} y={10} width={50} height={460} rx={25} fill={C.panel} stroke="#fff" strokeWidth={6} />
    <rect x={42} y={30 + 430 * (1 - p)} width={26} height={430 * p} rx={13} fill={C.red} />
    <circle cx={55} cy={500} r={48} fill={C.red} stroke="#fff" strokeWidth={6} />
  </svg>
);

const Orb = ({t, kind, at}) => {
  const s = r(t, at, at + 0.5, 0, 1, BACK);
  const pulse = 1 + Math.sin(t * 6) * 0.03;
  const isSun = kind === 'sun';
  return (
    <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', scale: String(s)}}>
      <div
        style={{
          width: 330,
          height: 330,
          borderRadius: '50%',
          scale: String(pulse),
          background: isSun
            ? 'radial-gradient(circle at 40% 38%, #fff7c2 0%, #ffd23f 35%, #ff8a1f 75%, #ff5a1f 100%)'
            : 'radial-gradient(circle at 45% 42%, #ffffff 0%, #fff3b0 30%, #ffb22e 75%, #ff7a1a 100%)',
          boxShadow: isSun
            ? '0 0 90px 30px rgba(255,170,40,0.8), 0 0 200px 60px rgba(255,120,30,0.35)'
            : '0 0 70px 20px rgba(255,220,120,0.7)',
        }}
      />
      <div style={{fontFamily: FONT, fontWeight: 900, fontSize: 46, color: '#fff', marginTop: 40}}>
        {isSun ? 'SOL' : 'NÚCLEO'}
      </div>
      <div style={{fontFamily: FONT, fontWeight: 800, fontSize: 40, color: C.accent}}>
        {isSun ? '≈ 5.500 °C' : '≈ 5.200 °C'}
      </div>
    </div>
  );
};

// =====================================================================
// 8. LO MÁS HONDO QUE HEMOS CAVADO (64.2 – 69.85 s)
// =====================================================================
export const DepthScene = () => {
  const t = useT();
  const bar = r(t, 64.3, 65.2, 0, 1, INOUT);
  const lens = r(t, 65.4, 66.0, 0, 1, BACK);
  const drill = r(t, 65.8, 66.9, 0, 1, INOUT);
  const top = 300;
  const h = 1060;
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        <defs>
          <linearGradient id="depthBar" x1="0" y1="0" x2="0" y2="1">
            <stop offset="0" stopColor="#7a4b2c" />
            <stop offset="0.02" stopColor="#c0441f" />
            <stop offset="0.3" stopColor="#ff8a1f" />
            <stop offset="0.45" stopColor="#ffd34d" />
            <stop offset="0.5" stopColor="#ffffff" />
            <stop offset="0.55" stopColor="#ffd34d" />
            <stop offset="0.7" stopColor="#ff8a1f" />
            <stop offset="0.98" stopColor="#c0441f" />
            <stop offset="1" stopColor="#7a4b2c" />
          </linearGradient>
          <clipPath id="lensClip">
            <circle cx={660} cy={600} r={230} />
          </clipPath>
        </defs>
        <rect x={110} y={top} width={120} height={h * bar} rx={18} fill="url(#depthBar)" />
        <rect x={104} y={top - 4} width={132} height={6} fill={C.red} opacity={lens} />

        {lens > 0 ? (
          <g opacity={Math.min(1, lens)}>
            <line x1={236} y1={top} x2={470} y2={460} stroke="#fff" strokeWidth={4} strokeDasharray="10 8" />
            <line x1={236} y1={top} x2={470} y2={740} stroke="#fff" strokeWidth={4} strokeDasharray="10 8" />
            <g transform={`translate(660 600) scale(${lens}) translate(-660 -600)`}>
              <g clipPath="url(#lensClip)">
                <rect x={420} y={360} width={480} height={480} fill="#2a1b10" />
                <rect x={420} y={360} width={480} height={130} fill="#0f1a3a" />
                <rect x={420} y={480} width={480} height={24} fill="#3fa35b" />
                <rect x={420} y={504} width={480} height={340} fill="#7a4b2c" />
                {Array.from({length: 10}).map((_, i) => (
                  <line key={i} x1={420} x2={900} y1={530 + i * 32} y2={536 + i * 32} stroke="#5b3a22" strokeWidth={4} />
                ))}
                <rect x={646} y={500} width={28} height={250 * drill} fill="#0a0d1c" stroke={C.red} strokeWidth={5} />
                <path d="M630 470 L690 470 L680 500 L640 500 Z" fill="#b8c2d6" />
                <rect x={655} y={400} width={10} height={70} fill="#b8c2d6" />
              </g>
              <circle cx={660} cy={600} r={230} fill="none" stroke="#fff" strokeWidth={12} />
              <line x1={820} y1={765} x2={900} y2={850} stroke="#fff" strokeWidth={26} strokeLinecap="round" />
              {drill > 0.95 ? (
                <SvgLabel x={700} y={760} size={44} color={C.red} anchor="start">
                  12 km
                </SvgLabel>
              ) : null}
            </g>
          </g>
        ) : null}
      </svg>

      <Pop at={64.5} style={{top: 1275, left: 260}}>
        <Pill color="#fff" size={44}>
          TÚNEL: 12.742 km
        </Pill>
      </Pop>
      <Pop at={66.4} style={{top: 860, left: 430}}>
        <Pill color={C.red} text="#fff" size={40}>
          POZO DE KOLA (RUSIA)
        </Pill>
      </Pop>
      <Pop at={67.38} style={{top: 960, left: 300, flexDirection: 'column'}}>
        <BigText size={170} color={C.accent} stroke={14}>
          0,1 %
        </BigText>
        <BigText size={48} style={{marginTop: 14}}>
          NI ESO HEMOS CAVADO
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 9. CIERRE: SÍGUEME Y COMENTA (69.85 – 80.8 s)
// =====================================================================
const COMMENTS = [
  {user: '@curioso_23', text: '¿Y si la Luna desapareciera?', base: 820},
  {user: '@ana.rv', text: '¿Qué hay dentro de un agujero negro?', base: 640},
  {user: '@leo_x', text: '¿Y si nunca durmieras?', base: 410},
];

export const OutroScene = () => {
  const t = useT();
  const burst = lin(t, 70.12, 71.0, 0, 1);
  const tapped = t > 72.4;
  const press = t > 72.3 && t < 72.6 ? 0.9 : 1;
  const handX = r(t, 71.4, 72.25, 980, 640, INOUT);
  const handY = r(t, 71.4, 72.25, 1350, 860, INOUT);
  const up = r(t, 74.2, 74.8, 0, 1, INOUT);

  return (
    <AbsoluteFill>
      <AbsoluteFill style={{translate: `0px ${-160 * up}px`}}>
        {/* Explosión de rayos: "te voló la cabeza" */}
        <svg width={1080} height={1920} viewBox="0 0 1080 1920" style={{position: 'absolute'}}>
          <g transform="translate(540 430)" opacity={1 - burst}>
            {Array.from({length: 16}).map((_, k) => (
              <line
                key={k}
                x1={0}
                y1={-160 - burst * 140}
                x2={0}
                y2={-200 - burst * 260}
                stroke={k % 2 ? C.accent : C.pink}
                strokeWidth={12}
                strokeLinecap="round"
                transform={`rotate(${k * 22.5})`}
              />
            ))}
          </g>
        </svg>

        <Pop at={69.9} style={{top: 290, left: 0, right: 0, flexDirection: 'column'}}>
          <div
            style={{
              width: 250,
              height: 250,
              borderRadius: 70,
              background: `linear-gradient(135deg, ${C.accent}, ${C.hot} 60%, ${C.pink})`,
              display: 'flex',
              alignItems: 'center',
              justifyContent: 'center',
              fontFamily: FONT,
              fontWeight: 900,
              fontSize: 190,
              color: '#0b0b14',
              boxShadow: '0 20px 80px rgba(255,90,54,0.55)',
              rotate: `${Math.sin(t * 2.5) * 4}deg`,
            }}
          >
            A
          </div>
          <BigText size={120} style={{marginTop: 30}}>
            APRENDE
          </BigText>
        </Pop>

        <Pop at={70.6} style={{top: 800, left: 0, right: 0}}>
          <div
            style={{
              display: 'flex',
              alignItems: 'center',
              gap: 18,
              padding: '26px 70px',
              borderRadius: 80,
              background: tapped ? 'rgba(255,255,255,0.18)' : C.pink,
              border: tapped ? '4px solid rgba(255,255,255,0.5)' : '4px solid transparent',
              fontFamily: FONT,
              fontWeight: 900,
              fontSize: 64,
              color: '#fff',
              scale: String(press),
              boxShadow: tapped ? 'none' : `0 0 ${40 + 20 * Math.sin(t * 6)}px ${C.pink}`,
            }}
          >
            {tapped ? <Check size={64} /> : <span style={{fontSize: 74, lineHeight: 0.8}}>+</span>}
            {tapped ? 'SIGUIENDO' : 'SEGUIR'}
          </div>
        </Pop>
        {t > 71.3 && t < 73.6 ? (
          <svg
            width={120}
            height={140}
            viewBox="0 0 120 140"
            style={{position: 'absolute', left: handX, top: handY, opacity: lin(t, 73.1, 73.6, 1, 0), scale: String(press)}}
          >
            <path
              d="M38 10 C38 2 54 2 54 10 L54 60 L58 60 L58 40 C58 33 72 33 72 40 L72 62 L76 62 L76 46 C76 39 90 39 90 46 L90 66 L94 66 L94 56 C94 49 108 49 108 56 L108 98 C108 122 92 134 70 134 L58 134 C42 134 34 126 26 112 L8 82 C4 74 14 66 22 72 L38 88 Z"
              fill="#fff"
              stroke="#05060f"
              strokeWidth={6}
              strokeLinejoin="round"
            />
          </svg>
        ) : null}
      </AbsoluteFill>

      {/* Comentarios */}
      <Pop at={74.31} style={{top: 830, left: 40, right: 40}}>
        <div
          style={{
            display: 'flex',
            alignItems: 'center',
            gap: 18,
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: t < 75.63 ? 60 : 42,
            color: '#fff',
          }}
        >
          <svg width={74} height={70} viewBox="0 0 74 70">
            <path d="M8 6 H66 Q70 6 70 10 V46 Q70 50 66 50 H30 L14 64 V50 H8 Q4 50 4 46 V10 Q4 6 8 6 Z" fill={C.cyan} />
            {[22, 37, 52].map((x, i) => (
              <circle key={x} cx={x} cy={28} r={5} fill="#05060f" opacity={0.4 + 0.6 * Math.abs(Math.sin(t * 6 - i))} />
            ))}
          </svg>
          {t < 75.63 ? 'COMENTA' : '¿QUÉ EXPLICO EN EL PRÓXIMO VIDEO?'}
        </div>
      </Pop>
      {COMMENTS.map((c, i) => (
        <Pop key={i} at={75.9 + i * 0.3} style={{top: 940 + i * 140, left: 40, right: 40}}>
          <CommentCard t={t} c={c} winner={i === 0} />
        </Pop>
      ))}
      <Pop at={79.69} style={{top: 1000, left: 0, right: 0}}>
        <div
          style={{
            rotate: '-8deg',
            border: `10px solid ${C.red}`,
            borderRadius: 24,
            padding: '10px 36px',
            fontFamily: FONT,
            fontWeight: 900,
            fontSize: 78,
            color: C.red,
            background: 'rgba(255,255,255,0.92)',
          }}
        >
          ¡SIGUIENTE VIDEO!
        </div>
      </Pop>
    </AbsoluteFill>
  );
};

const CommentCard = ({t, c, winner}) => {
  const grow = lin(t, 75.9, 80.8, 0, 1);
  const boost = winner ? r(t, 77.98, 78.9, 0, 1) : 0;
  const likes = Math.round(c.base * (1 + grow * 2) + boost * 11000);
  const likeTxt = likes >= 1000 ? `${(likes / 1000).toFixed(1).replace('.', ',')} K` : String(likes);
  const hl = winner && t > 77.98;
  return (
    <div
      style={{
        width: '100%',
        boxSizing: 'border-box',
        display: 'flex',
        alignItems: 'center',
        gap: 20,
        background: hl ? 'rgba(255,210,63,0.16)' : C.panel,
        border: `4px solid ${hl ? C.accent : 'rgba(255,255,255,0.15)'}`,
        borderRadius: 28,
        padding: '18px 24px',
        fontFamily: FONT,
        color: '#fff',
        scale: hl ? String(1 + 0.04 * boost) : '1',
      }}
    >
      <div
        style={{
          width: 72,
          height: 72,
          borderRadius: '50%',
          background: `linear-gradient(135deg, ${C.cyan}, ${C.pink})`,
          flexShrink: 0,
        }}
      />
      <div style={{flex: 1}}>
        <div style={{fontWeight: 800, fontSize: 26, color: '#b9c3dd', display: 'flex', gap: 12, alignItems: 'center'}}>
          {c.user}
          {hl ? (
            <span style={{background: C.accent, color: '#0b0b14', borderRadius: 12, padding: '2px 12px', fontSize: 22, fontWeight: 900}}>
              MÁS VOTADO
            </span>
          ) : null}
        </div>
        <div style={{fontWeight: 800, fontSize: 36}}>{c.text}</div>
      </div>
      <div style={{display: 'flex', flexDirection: 'column', alignItems: 'center', scale: String(1 + 0.3 * Math.sin(boost * PI))}}>
        <Heart size={44} color={hl ? C.pink : '#c9cfe0'} />
        <div style={{fontWeight: 900, fontSize: 26}}>{likeTxt}</div>
      </div>
    </div>
  );
};
