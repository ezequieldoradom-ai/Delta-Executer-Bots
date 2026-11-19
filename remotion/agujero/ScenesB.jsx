import React from 'react';
import {AbsoluteFill, random} from 'remotion';
import {BACK, BigText, C, FONT, INOUT, Pill, Pop, lin, r, useT} from '../tunel/lib';
import {BHDefs, Bed, Desk, Floor, Globe, Lamp, MiniHole, Person, Poster, RoomWindow, WallTiles} from './Parts';

const PI = Math.PI;

// Latido: pulso rojo en los bordes para crear tensión
const Heartbeat = ({t, from, to, max = 0.5}) => {
  if (t < from || t > to + 0.3) return null;
  const beat = Math.pow(Math.max(0, Math.sin(t * 7.5)), 8);
  const k = lin(t, from, to, 0.4, 1) * lin(t, to, to + 0.3, 1, 0);
  return (
    <AbsoluteFill
      style={{
        background: 'radial-gradient(circle at 50% 42%, transparent 45%, rgba(200,0,40,1) 120%)',
        opacity: max * k * (0.35 + 0.65 * beat),
      }}
    />
  );
};

// =====================================================================
// 5. LA DUDA: ¿cómo puede algo tan pequeño…? (34.3 – 43.1 s)
// =====================================================================
export const QuestionScene = () => {
  const t = useT();
  const zoom = r(t, 34.3, 43.1, 1, 2.6, INOUT);
  const lens = r(t, 39.12, 39.6, 0, 1, BACK);
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        <BHDefs />
        <g transform={`translate(540 800) scale(${zoom})`}>
          <MiniHole t={t} r={24} />
          {[0, 1, 2].map((k) => {
            const ph = (t * 0.6 + k / 3) % 1;
            return <circle key={k} r={30 + ph * 140} fill="none" stroke="#fff" strokeOpacity={0.25 * (1 - ph)} strokeWidth={2} />;
          })}
        </g>
        {lens > 0 ? (
          <g transform={`translate(540 800) scale(${lens})`} opacity={lin(t, 42.9, 43.1, 1, 0)}>
            <circle r={210} fill="none" stroke="#fff" strokeWidth={14} />
            <line x1={150} y1={150} x2={270} y2={270} stroke="#fff" strokeWidth={34} strokeLinecap="round" />
          </g>
        ) : null}
      </svg>

      <Pop at={34.45} out={35.6} style={{top: 260, left: 0, right: 0}}>
        <BigText size={120}>PERO ESPERA…</BigText>
      </Pop>
      <Pop at={35.68} out={39.0} style={{top: 240, left: 0, right: 0}}>
        <BigText size={84}>
          ¿CÓMO PUEDE ALGO
          <br />
          <span style={{color: C.cyan}}>TAN PEQUEÑO</span>
          <br />
          TENER TANTA <span style={{color: C.accent}}>FUERZA</span>?
        </BigText>
      </Pop>
      <Pop at={39.12} style={{top: 260, left: 0, right: 0}}>
        <BigText size={82}>
          UN <span style={{color: C.accent}}>DETALLE</span>
          <br />
          LO CAMBIA TODO
        </BigText>
      </Pop>

      {/* Ideas descartadas */}
      <div style={{position: 'absolute', top: 1110, left: 0, right: 0, display: 'flex', justifyContent: 'center', gap: 18}}>
        {[
          ['¿ENERGÍA?', 41.3],
          ['¿VELOCIDAD?', 41.75],
          ['¿MAGIA?', 42.2],
        ].map(([w, at]) => (
          <Crossed key={w} t={t} at={at}>
            {w}
          </Crossed>
        ))}
      </div>
      <Heartbeat t={t} from={34.4} to={43.0} max={0.45} />
    </AbsoluteFill>
  );
};

const Crossed = ({t, at, children}) => {
  if (t < at) return null;
  const s = r(t, at, at + 0.3, 0, 1, BACK);
  const strike = r(t, at + 0.2, at + 0.4, 0, 1);
  return (
    <div style={{position: 'relative', scale: String(s), fontFamily: FONT, fontWeight: 900, fontSize: 44, color: '#fff', background: 'rgba(8,12,30,0.85)', borderRadius: 18, padding: '8px 18px'}}>
      {children}
      <div style={{position: 'absolute', left: 10, top: '50%', height: 8, width: `calc(${strike * 100}% - 20px)`, background: C.red, rotate: '-6deg', borderRadius: 4}} />
    </div>
  );
};

// =====================================================================
// 6. LA BALANZA Y LA REVELACIÓN (43.1 – 61.0 s)
// =====================================================================
const PIV = {x: 540, y: 600};
const L = 350;

const Mountain = () => (
  <g>
    <path d="M-90 0 L-20 -130 L20 -70 L45 -100 L100 0 Z" fill="#7d8597" />
    <path d="M-20 -130 L-42 -90 L-24 -96 L-12 -84 L2 -102 Z" fill="#fff" />
  </g>
);
const Ocean = () => (
  <g>
    <path d="M-90 0 L-90 -60 Q-60 -85 -30 -60 Q0 -35 30 -60 Q60 -85 90 -60 L90 0 Z" fill="#2f7fd1" />
    <path d="M-90 -60 Q-60 -85 -30 -60 Q0 -35 30 -60 Q60 -85 90 -60" fill="none" stroke="#9fd8ff" strokeWidth={8} />
  </g>
);

export const BalanceScene = () => {
  const t = useT();
  const wob = (at) => (t > at && t < at + 1 ? Math.sin((t - at) * 18) * 3 * (1 - (t - at)) : 0);
  const balanced = r(t, 53.96, 54.9, 0, 1, BACK);
  const a = (22 + wob(45.95) + wob(46.85)) * (1 - balanced); // grados, izquierda abajo
  const rad = (a * PI) / 180;
  const left = {x: PIV.x - L * Math.cos(rad), y: PIV.y + L * Math.sin(rad)};
  const right = {x: PIV.x + L * Math.cos(rad), y: PIV.y - L * Math.sin(rad)};
  const HANG = 190;

  const drop = (at) => r(t, at, at + 0.45, -700, 0, (x) => x * x);
  const away = r(t, 52.9, 53.4, 0, 1, INOUT);
  const earthDrop = drop(53.96);

  // Transición a la palma
  const palm = lin(t, 55.3, 55.7, 0, 1);
  const shrink = r(t, 55.6, 58.8, 1, 0, INOUT);

  return (
    <AbsoluteFill>
      <AbsoluteFill style={{opacity: 1 - palm}}>
        <svg width={1080} height={1920} viewBox="0 0 1080 1920">
          <BHDefs />
          {/* Soporte */}
          <rect x={526} y={PIV.y} width={28} height={640} fill="#c9d1e4" />
          <path d="M400 1260 L680 1260 L630 1220 L450 1220 Z" fill="#c9d1e4" />
          <g transform={`translate(${PIV.x} ${PIV.y}) rotate(${-a})`}>
            <rect x={-L - 10} y={-10} width={2 * L + 20} height={20} rx={10} fill="#e8ecf5" />
          </g>
          <circle cx={PIV.x} cy={PIV.y} r={24} fill={C.accent} stroke="#05060f" strokeWidth={6} />
          {[left, right].map((p, i) => (
            <g key={i}>
              <line x1={p.x} y1={p.y} x2={p.x - 110} y2={p.y + HANG} stroke="#c9d1e4" strokeWidth={4} />
              <line x1={p.x} y1={p.y} x2={p.x + 110} y2={p.y + HANG} stroke="#c9d1e4" strokeWidth={4} />
              <path d={`M${p.x - 130} ${p.y + HANG} Q${p.x} ${p.y + HANG + 70} ${p.x + 130} ${p.y + HANG} Z`} fill="#e8ecf5" />
            </g>
          ))}
          {/* Izquierda: el agujero negro */}
          <g transform={`translate(${left.x} ${left.y + HANG - 40})`}>
            <MiniHole t={t} r={20} />
          </g>
          {/* Derecha: montaña, océano y después la Tierra */}
          <g transform={`translate(${right.x} ${right.y + HANG + 6})`}>
            {t > 45.76 ? (
              <g opacity={1 - away} transform={`translate(${away * 500} ${drop(45.76) + away * 200}) rotate(${away * 90})`}>
                <Mountain />
              </g>
            ) : null}
            {t > 46.64 ? (
              <g opacity={1 - away} transform={`translate(${away * 500} ${drop(46.64) - 100 + away * 200}) scale(0.8)`}>
                <Ocean />
              </g>
            ) : null}
            {t > 53.96 ? (
              <g transform={`translate(0 ${earthDrop - 110})`}>
                <Globe r={105} t={t} id="bal" />
              </g>
            ) : null}
          </g>
        </svg>

        <Pop at={43.25} out={53.9} style={{top: 1270, left: 0, right: 0}}>
          <Pill color="rgba(255,255,255,0.15)" text="#fff" size={40}>
            ¿QUÉ PESA MÁS?
          </Pill>
        </Pop>
        <Pop at={45.76} out={46.5} style={{top: 260, left: 0, right: 0}}>
          <BigText size={100}>¿UNA MONTAÑA?</BigText>
        </Pop>
        <Pop at={46.64} out={47.8} style={{top: 260, left: 0, right: 0}}>
          <BigText size={100}>¿UN OCÉANO?</BigText>
        </Pop>
        <Pop at={47.92} out={50.0} style={{top: 260, left: 0, right: 0}}>
          <BigText size={100} color={C.red}>
            NI DE LEJOS
          </BigText>
        </Pop>
        <Pop at={50.16} out={53.8} style={{top: 260, left: 0, right: 0}}>
          <BigText size={88}>
            ESTA <span style={{color: C.cyan}}>MONEDA</span>
            <br />
            PESA LO MISMO QUE…
          </BigText>
        </Pop>
        <Pop at={53.96} style={{top: 230, left: 0, right: 0, flexDirection: 'column'}}>
          <BigText size={110} color={C.accent}>
            LA TIERRA ENTERA
          </BigText>
          <div style={{fontFamily: 'JetBrains Mono, monospace', fontWeight: 800, fontSize: 38, color: '#fff', marginTop: 16, background: 'rgba(0,0,0,0.5)', padding: '6px 16px', borderRadius: 12}}>
            6.000.000.000.000.000.000.000.000 kg
          </div>
        </Pop>
        {t > 53.96 && t < 54.6 ? <AbsoluteFill style={{background: '#fff', opacity: lin(t, 53.96, 54.6, 0.7, 0)}} /> : null}
        <Heartbeat t={t} from={50.1} to={53.9} max={0.6} />
      </AbsoluteFill>

      {palm > 0 ? (
        <AbsoluteFill style={{opacity: palm}}>
          <svg width={1080} height={1920} viewBox="0 0 1080 1920">
            <BHDefs />
            <Hand y={r(t, 58.0, 59.0, 1500, 0, INOUT)} />
            <g transform={`translate(540 ${lin(shrink, 0, 1, 1095, 720)})`}>
              {shrink > 0.06 ? (
                <Globe r={260 * shrink} t={t} id="palm" />
              ) : (
                <MiniHole t={t} r={14} />
              )}
            </g>
          </svg>
          <Pop at={55.5} style={{top: 240, left: 0, right: 0}}>
            <BigText size={84}>
              SI APLASTARAS
              <br />
              <span style={{color: C.cyan}}>LA TIERRA…</span>
            </BigText>
          </Pop>
          <Pop at={59.6} style={{top: 1260, left: 0, right: 0}}>
            <Pill color={C.accent} size={52}>
              CABE EN TU MANO · 1,8 cm
            </Pill>
          </Pop>
        </AbsoluteFill>
      ) : null}
    </AbsoluteFill>
  );
};

const Hand = ({y}) => (
  <g transform={`translate(540 ${960 + y})`}>
    <rect x={-150} y={20} width={300} height={260} rx={110} fill="#f2c29b" />
    {[-120, -60, 0, 60].map((x, i) => (
      <rect key={x} x={x + 6} y={-120 + Math.abs(i - 1.5) * 26} width={54} height={180} rx={27} fill="#f2c29b" stroke="#d9a47a" strokeWidth={3} />
    ))}
    <rect x={120} y={40} width={56} height={160} rx={28} fill="#f2c29b" stroke="#d9a47a" strokeWidth={3} transform="rotate(-40 140 140)" />
    <rect x={-150} y={260} width={300} height={500} fill="#f2c29b" />
    <ellipse cx={0} cy={-55} rx={120} ry={40} fill="#e8b48c" />
  </g>
);

// =====================================================================
// 7. EL PLANETA CAE (61.0 – 72.0 s)
// =====================================================================
export const CollapseScene = () => {
  const t = useT();
  const E = {x: 540, y: 900, r: 330};
  const P = {x: 540, y: E.y - E.r}; // el agujero, en la superficie
  const zoom = r(t, 61.0, 62.8, 5, 1, INOUT);
  const fall = r(t, 64.8, 71.8, 0, 1, (x) => x * x);
  const cracks = r(t, 67.52, 68.8, 0, 1);
  const heat = r(t, 69.36, 71.5, 0, 1);
  const temp = r(t, 69.4, 71.2, 0, 1000000, INOUT);

  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        <BHDefs />
        <g transform={`translate(${P.x} ${P.y}) scale(${zoom}) translate(${-P.x} ${-P.y})`}>
          {/* La Tierra se deforma hacia el agujero */}
          <g transform={`translate(${P.x} ${P.y}) scale(${1 - 0.25 * fall} ${1 - 0.55 * fall}) translate(${-P.x} ${-P.y})`}>
            <g transform={`translate(${E.x} ${E.y})`}>
              <Globe r={E.r} t={t} id="col" />
            </g>
            {cracks > 0
              ? Array.from({length: 11}).map((_, k) => {
                  const a = PI / 2 + ((k - 5) / 5) * 1.25;
                  const pts = [0, 0.25, 0.5, 0.75, 1].map((u, j) => {
                    const len = 2 * E.r * cracks * u;
                    const jit = (random(`cr${k}${j}`) - 0.5) * 50 * u;
                    return `${P.x + Math.cos(a) * len + jit},${P.y + Math.sin(a) * len}`;
                  });
                  return (
                    <polyline
                      key={k}
                      points={pts.join(' ')}
                      fill="none"
                      stroke="#ffb02e"
                      strokeWidth={9}
                      strokeLinejoin="round"
                      style={{filter: 'drop-shadow(0 0 10px #ff7a1a)'}}
                    />
                  );
                })
              : null}
            {heat > 0 ? <circle cx={P.x} cy={P.y} r={80 + 420 * heat} fill="url(#heat)" opacity={0.9} /> : null}
          </g>
          {/* Material cayendo hacia el agujero */}
          {t > 64.9
            ? Array.from({length: 60}).map((_, i) => {
                const a = PI / 2 + (random(`fa${i}`) - 0.5) * 2.6;
                const d0 = 80 + random(`fd${i}`) * 520;
                const u = (random(`fu${i}`) + (t - 64.9) * (0.5 + random(`fs${i}`))) % 1;
                const d = d0 * (1 - u * u);
                const sw = (1 - u) * 3 + 1;
                return (
                  <circle
                    key={i}
                    cx={P.x + Math.cos(a + u * 1.2) * d}
                    cy={P.y + Math.sin(a + u * 1.2) * d}
                    r={sw * 2}
                    fill={heat > 0.3 ? '#ffd27a' : '#c9a27a'}
                    opacity={0.9}
                  />
                );
              })
            : null}
          <g transform={`translate(${P.x} ${P.y - 4})`}>
            <MiniHole t={t} r={8 + 22 * fall} glow={1 + heat} />
          </g>
          {zoom > 1.6 ? (
            <g opacity={lin(zoom, 1.6, 3, 0, 1)}>
              <circle cx={P.x} cy={P.y} r={60} fill="none" stroke={C.accent} strokeWidth={4} />
            </g>
          ) : null}
        </g>
      </svg>
      <Pop at={61.3} out={64.6} style={{top: 240, left: 0, right: 0}}>
        <BigText size={86}>
          TU HABITACIÓN
          <br />
          <span style={{color: C.accent}}>ERA SOLO EL PRINCIPIO</span>
        </BigText>
      </Pop>
      <Pop at={64.8} out={69.2} style={{top: 260, left: 0, right: 0}}>
        <BigText size={92} color={C.cyan}>
          TODO EL PLANETA CAE
        </BigText>
      </Pop>
      <Pop at={69.36} style={{top: 240, left: 0, right: 0}}>
        <BigText size={130} color={C.accent} stroke={14}>
          +{Math.round(temp).toString().replace(/\B(?=(\d{3})+(?!\d))/g, '.')} °C
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 8. EL DISCO DE FUEGO (72.0 – 79.4 s)
// =====================================================================
export const DiskScene = () => {
  const t = useT();
  const cx = 540;
  const cy = 820;
  const grow = r(t, 72.0, 73.2, 0.3, 1, INOUT);
  const spin = t * 50;
  const rings = [0, 1, 2, 3, 4, 5, 6];
  const moonA = t * 0.45 + 2.2;
  const moonFront = Math.sin(moonA) > 0;
  const Moon = () => (
    <g transform={`translate(${cx + Math.cos(moonA) * 470} ${cy + Math.sin(moonA) * 150})`} opacity={lin(t, 75.6, 76.2, 0, 1)}>
      <circle r={30} fill="#c9ccd6" />
      <circle cx={-8} cy={-6} r={7} fill="#a9adba" />
      <circle cx={10} cy={8} r={5} fill="#a9adba" />
    </g>
  );
  const Disk = ({half}) => (
    <g clipPath={`url(#half-${half})`}>
      {rings.map((k) => {
        const rx = (140 + k * 48) * grow;
        return (
          <ellipse
            key={k}
            cx={cx}
            cy={cy}
            rx={rx}
            ry={rx * 0.26}
            fill="none"
            stroke={k < 2 ? '#fff6cf' : k < 4 ? '#ffc04a' : '#ff6a1f'}
            strokeOpacity={1 - k * 0.11}
            strokeWidth={34 - k * 3}
            strokeDasharray={`${60 + k * 10} ${20 + k * 6}`}
            strokeDashoffset={spin * (1.6 - k * 0.18)}
          />
        );
      })}
    </g>
  );
  return (
    <AbsoluteFill>
      <svg width={1080} height={1920} viewBox="0 0 1080 1920">
        <BHDefs />
        <defs>
          <clipPath id="half-back">
            <rect x={0} y={0} width={1080} height={cy} />
          </clipPath>
          <clipPath id="half-front">
            <rect x={0} y={cy} width={1080} height={1920} />
          </clipPath>
        </defs>
        <g transform={`rotate(-10 ${cx} ${cy})`}>
          <circle cx={cx} cy={cy} r={460 * grow} fill="url(#bhHalo)" opacity={0.8} />
          {!moonFront ? <Moon /> : null}
          <Disk half="back" />
          {/* Anillo de fotones (la luz que rodea el agujero por arriba) */}
          <ellipse cx={cx} cy={cy - 20} rx={120 * grow} ry={95 * grow} fill="none" stroke="#ffd08a" strokeWidth={18} opacity={0.85} style={{filter: 'blur(3px)'}} />
          <circle cx={cx} cy={cy} r={86 * grow} fill="#000" />
          <Disk half="front" />
          {moonFront ? <Moon /> : null}
        </g>
      </svg>
      <Pop at={72.1} out={74.3} style={{top: 240, left: 0, right: 0}}>
        <Pill color="#fff" size={50}>
          EN CUESTIÓN DE MINUTOS…
        </Pill>
      </Pop>
      <Pop at={74.48} style={{top: 230, left: 0, right: 0}}>
        <BigText size={96}>
          LA TIERRA
          <br />
          <span style={{color: C.red}}>YA NO EXISTE</span>
        </BigText>
      </Pop>
      <Pop at={76.2} style={{top: 1180, left: 640}}>
        <Pill color="#c9ccd6" size={36}>
          LA LUNA, SOLA
        </Pill>
      </Pop>
    </AbsoluteFill>
  );
};

// =====================================================================
// 9. ¿PODRÍA PASAR? …QUE SEPAMOS (79.4 – 84.35 s)
// =====================================================================
export const CalmScene = () => {
  const t = useT();
  const sus = t > 83.4;
  const zoom = sus ? r(t, 83.5, 84.35, 1, 1.9, INOUT) : 1;
  const flick = sus && Math.sin(t * 60) > 0.6 ? 0.5 : 0;
  return (
    <AbsoluteFill>
      <AbsoluteFill style={{scale: String(zoom), transformOrigin: '330px 860px'}}>
        <svg width={1080} height={1920} viewBox="0 0 1080 1920">
          <BHDefs />
          {WallTiles.map((w, i) => (
            <rect key={i} x={w.x} y={w.y} width={w.w + 1} height={w.h + 1} fill={w.k > 0.5 ? '#2d3363' : '#2a305c'} />
          ))}
          <Floor />
          <RoomWindow t={t} />
          <Poster />
          <Desk />
          <Lamp />
          <Bed />
          <Person x={400} y={1000} wave={Math.sin(t * 2) * 8} />
          {sus ? (
            <g transform={`translate(330 840) scale(${r(t, 83.5, 83.9, 0, 1, BACK)})`}>
              <MiniHole t={t} r={8} />
            </g>
          ) : null}
        </svg>
      </AbsoluteFill>
      {flick ? <AbsoluteFill style={{background: '#000', opacity: flick}} /> : null}
      <Pop at={79.55} out={81.4} style={{top: 240, left: 0, right: 0}}>
        <BigText size={90}>
          ¿PODRÍA PASAR
          <br />
          <span style={{color: C.cyan}}>DE VERDAD?</span>
        </BigText>
      </Pop>
      <Pop at={81.6} out={83.3} style={{top: 260, left: 0, right: 0}}>
        <BigText size={80}>
          <span style={{color: C.green}}>TRANQUILO</span>
          <br />
          NO SE CONOCE
          <br />
          NINGUNA FORMA
        </BigText>
      </Pop>
      <Pop at={83.45} style={{top: 260, left: 0, right: 0}}>
        <BigText size={110} color={C.red}>
          …QUE SEPAMOS
        </BigText>
      </Pop>
    </AbsoluteFill>
  );
};
