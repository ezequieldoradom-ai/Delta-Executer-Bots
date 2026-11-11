import React from 'react';
import {random} from 'remotion';
import {C} from '../tunel/lib';

// Centro del agujero negro en la habitación (coordenadas del lienzo 1080x1920)
export const H = {x: 540, y: 720};

export const BHDefs = () => (
  <defs>
    <radialGradient id="bhHalo">
      <stop offset="0" stopColor="#000" stopOpacity="1" />
      <stop offset="0.2" stopColor="#ff9a3c" stopOpacity="0.45" />
      <stop offset="0.45" stopColor="#7a2cff" stopOpacity="0.12" />
      <stop offset="1" stopColor="#000" stopOpacity="0" />
    </radialGradient>
    <radialGradient id="ocean" cx="0.38" cy="0.35">
      <stop offset="0" stopColor="#4fb3ff" />
      <stop offset="0.7" stopColor="#1f6fd1" />
      <stop offset="1" stopColor="#0d3a7a" />
    </radialGradient>
    <radialGradient id="shade" cx="0.3" cy="0.3">
      <stop offset="0.55" stopColor="#000" stopOpacity="0" />
      <stop offset="1" stopColor="#000" stopOpacity="0.55" />
    </radialGradient>
    <radialGradient id="heat">
      <stop offset="0" stopColor="#ffffff" stopOpacity="1" />
      <stop offset="0.3" stopColor="#ffe08a" stopOpacity="0.9" />
      <stop offset="0.65" stopColor="#ff6a1f" stopOpacity="0.6" />
      <stop offset="1" stopColor="#ff3d1f" stopOpacity="0" />
    </radialGradient>
  </defs>
);

// Agujero negro diminuto con anillo de fotones y halo
export const MiniHole = ({t, r = 24, glow = 1}) => (
  <g>
    <circle r={r * 7} fill="url(#bhHalo)" opacity={0.9 * glow} />
    {[0, 1, 2].map((k) => (
      <circle
        key={k}
        r={r * (2.1 + k * 0.9)}
        fill="none"
        stroke="#ffb35a"
        strokeOpacity={(0.32 - k * 0.08) * glow}
        strokeWidth={2.5}
        strokeDasharray="12 18"
        transform={`rotate(${t * (70 + k * 30) * (k % 2 ? -1 : 1)})`}
      />
    ))}
    <circle r={r * 1.35} fill="none" stroke="#ffd08a" strokeWidth={r * 0.25} opacity={0.9 * glow} style={{filter: 'blur(2px)'}} />
    <circle r={r} fill="#000" />
  </g>
);

// Atrae un objeto dibujado en (ax, ay) hacia H estirándolo en dirección radial
export const Suck = ({ax, ay, p, extra = 1, children}) => {
  if (p >= 1) return null;
  const e = p * p;
  const dx = ax - H.x;
  const dy = ay - H.y;
  const ang = (Math.atan2(dy, dx) * 180) / Math.PI;
  const px = H.x + dx * (1 - e);
  const py = H.y + dy * (1 - e);
  const sr = 1 + 5 * e * extra;
  const st = Math.max(0.12, 1 - 0.85 * e);
  return (
    <g
      opacity={p > 0.85 ? (1 - p) / 0.15 : 1}
      transform={`translate(${px} ${py}) rotate(${ang}) scale(${sr} ${st}) rotate(${-ang}) translate(${-ax} ${-ay})`}
    >
      {children}
    </g>
  );
};

// Personaje "tú" (centro en el torso)
export const Person = ({x, y, s = 1, wave = 0, scared = 0}) => (
  <g transform={`translate(${x} ${y}) scale(${s})`}>
    <rect x={-30} y={50} width={24} height={110} rx={12} fill="#2c3550" transform={`rotate(${-4 - scared * 10} -18 50)`} />
    <rect x={6} y={50} width={24} height={110} rx={12} fill="#2c3550" transform={`rotate(${4 + scared * 10} 18 50)`} />
    <rect x={-38} y={160} width={36} height={16} rx={8} fill="#111" />
    <rect x={2} y={160} width={36} height={16} rx={8} fill="#111" />
    <rect x={-66} y={-46} width={22} height={96} rx={11} fill="#f2c29b" transform={`rotate(${20 + wave + scared * 60} -55 -40)`} />
    <rect x={44} y={-46} width={22} height={96} rx={11} fill="#f2c29b" transform={`rotate(${-20 - wave - scared * 60} 55 -40)`} />
    <rect x={-46} y={-56} width={92} height={120} rx={30} fill={C.cyan} />
    <rect x={-46} y={-56} width={92} height={36} rx={18} fill="#3cc7e6" />
    <circle cx={0} cy={-104} r={46} fill="#f2c29b" />
    <path d="M-46 -112 C-44 -160 44 -164 46 -112 C30 -132 -20 -136 -46 -112 Z" fill="#3a2418" />
    <circle cx={-16} cy={-104} r={scared ? 7 : 5} fill="#1a1a1a" />
    <circle cx={16} cy={-104} r={scared ? 7 : 5} fill="#1a1a1a" />
    {scared > 0.5 ? (
      <ellipse cx={0} cy={-80} rx={9} ry={12} fill="#5a1a1a" />
    ) : (
      <path d="M-14 -84 Q0 -74 14 -84" fill="none" stroke="#5a1a1a" strokeWidth={5} strokeLinecap="round" />
    )}
  </g>
);

// Planeta Tierra visto desde el espacio
const CONTINENTS = Array.from({length: 7}).map((_, i) => ({
  x: random(`cx${i}`) * 2 - 1,
  y: random(`cy${i}`) * 1.4 - 0.7,
  blobs: Array.from({length: 5}).map((__, k) => ({
    dx: (random(`bx${i}${k}`) - 0.5) * 0.5,
    dy: (random(`by${i}${k}`) - 0.5) * 0.4,
    rx: 0.12 + random(`br${i}${k}`) * 0.18,
    ry: 0.08 + random(`bh${i}${k}`) * 0.14,
  })),
}));

export const Globe = ({r, t, id = 'g'}) => {
  const shift = ((t * 0.05) % 2) - 1;
  return (
    <g>
      <defs>
        <clipPath id={`clip-${id}`}>
          <circle r={r} />
        </clipPath>
      </defs>
      <circle r={r * 1.08} fill="#5ab8ff" opacity={0.18} />
      <circle r={r} fill="url(#ocean)" />
      <g clipPath={`url(#clip-${id})`}>
        {[-2, 0, 2].map((o) =>
          CONTINENTS.map((c, i) =>
            c.blobs.map((b, k) => (
              <ellipse
                key={`${o}${i}${k}`}
                cx={(c.x + b.dx + o - shift) * r}
                cy={(c.y + b.dy) * r}
                rx={b.rx * r}
                ry={b.ry * r}
                fill={k % 2 ? '#3fa35b' : '#5cbf6a'}
              />
            )),
          ),
        )}
        {[0, 1, 2, 3].map((k) => (
          <ellipse
            key={k}
            cx={((((random(`cl${k}`) * 2 - 1 - shift * 1.3 + 3) % 2) - 1) * r)}
            cy={(random(`cm${k}`) * 1.4 - 0.7) * r}
            rx={r * 0.35}
            ry={r * 0.06}
            fill="#fff"
            opacity={0.55}
          />
        ))}
        <circle r={r} fill="url(#shade)" />
      </g>
    </g>
  );
};

// Habitación (dibujo base, sin succión). Cada pieza se exporta para animarla.
export const WallTiles = Array.from({length: 7 * 10}).map((_, i) => {
  const col = i % 7;
  const row = Math.floor(i / 7);
  return {x: col * 155, y: 150 + row * 100, w: 155, h: 100, k: random(`wt${i}`)};
});

export const RoomWindow = ({t}) => (
  <g>
    <rect x={110} y={320} width={300} height={330} rx={10} fill="#e8ecf5" />
    <rect x={126} y={336} width={268} height={298} fill="#0b1638" />
    {[0, 1, 2, 3, 4, 5, 6].map((k) => (
      <circle key={k} cx={140 + random(`ws${k}`) * 240} cy={350 + random(`wy${k}`) * 260} r={2 + random(`wr${k}`) * 2} fill="#fff" opacity={0.5 + 0.5 * Math.sin(t * 2 + k)} />
    ))}
    <circle cx={330} cy={410} r={38} fill="#fdf3c4" />
    <circle cx={346} cy={398} r={34} fill="#0b1638" />
    <rect x={256} y={336} width={8} height={298} fill="#e8ecf5" />
    <rect x={126} y={480} width={268} height={8} fill="#e8ecf5" />
    <path d="M90 300 Q130 480 100 680 L150 680 Q175 480 150 300 Z" fill={C.hot} opacity={0.9} />
    <path d="M430 300 Q390 480 420 680 L370 680 Q345 480 370 300 Z" fill={C.hot} opacity={0.9} />
    <rect x={80} y={292} width={360} height={14} rx={7} fill="#b8bfd0" />
  </g>
);

export const Poster = () => (
  <g>
    <rect x={690} y={300} width={220} height={270} rx={8} fill="#141a3c" stroke="#fff" strokeWidth={8} />
    <circle cx={800} cy={420} r={62} fill="#ffb347" />
    <ellipse cx={800} cy={420} rx={100} ry={22} fill="none" stroke="#ffe0a0" strokeWidth={8} transform="rotate(-18 800 420)" />
    <rect x={730} y={515} width={140} height={16} rx={8} fill="#5ee7ff" />
  </g>
);

export const Lamp = () => (
  <g>
    <rect x={140} y={790} width={14} height={110} fill="#9aa3b8" />
    <path d="M95 790 L200 790 L178 720 L117 720 Z" fill={C.accent} />
    <ellipse cx={147} cy={905} rx={46} ry={10} fill="#9aa3b8" />
    <path d="M100 790 L20 1000 L280 1000 L195 790 Z" fill="#ffe7a0" opacity={0.12} />
  </g>
);

export const Desk = () => (
  <g>
    <rect x={40} y={910} width={420} height={30} rx={6} fill="#a0703f" />
    <rect x={60} y={940} width={22} height={240} fill="#7f552d" />
    <rect x={418} y={940} width={22} height={240} fill="#7f552d" />
    <rect x={250} y={850} width={150} height={60} rx={6} fill="#cfd6e4" />
    <rect x={262} y={858} width={126} height={44} rx={3} fill="#5ee7ff" opacity={0.7} />
    <rect x={240} y={904} width={170} height={8} rx={3} fill="#9aa3b8" />
  </g>
);

export const Bed = () => (
  <g>
    <rect x={600} y={860} width={30} height={330} rx={8} fill="#7f552d" />
    <rect x={600} y={850} width={160} height={40} rx={14} fill="#a0703f" />
    <rect x={620} y={1000} width={440} height={110} rx={20} fill="#f0f2f8" />
    <rect x={700} y={990} width={360} height={130} rx={24} fill={C.pink} />
    <rect x={640} y={950} width={130} height={70} rx={30} fill="#ffffff" />
    <rect x={620} y={1110} width={440} height={30} rx={10} fill="#7f552d" />
  </g>
);

export const Floor = () => (
  <g>
    <rect x={0} y={1150} width={1080} height={260} fill="#6b4a33" />
    {[0, 1, 2, 3, 4].map((k) => (
      <line key={k} x1={0} x2={1080} y1={1190 + k * 45} y2={1190 + k * 45} stroke="#573a27" strokeWidth={4} />
    ))}
    <rect x={0} y={1140} width={1080} height={16} fill="#4d3322" />
  </g>
);
