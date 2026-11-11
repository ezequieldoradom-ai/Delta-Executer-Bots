import React, {createContext, useContext} from 'react';
import {
  AbsoluteFill,
  Easing,
  Sequence,
  interpolate,
  useCurrentFrame,
  useVideoConfig,
} from 'remotion';
import {loadFont} from '@remotion/google-fonts/Montserrat';

export const {fontFamily: FONT} = loadFont('normal', {
  weights: ['600', '800', '900'],
  subsets: ['latin'],
});

export const C = {
  accent: '#ffd23f',
  hot: '#ff5a36',
  cyan: '#5ee7ff',
  red: '#ff2d55',
  green: '#3ddc84',
  pink: '#ff3d81',
  white: '#ffffff',
  panel: 'rgba(8, 12, 30, 0.78)',
};

const CL = {extrapolateLeft: 'clamp', extrapolateRight: 'clamp'};
export const EASE = Easing.bezier(0.16, 1, 0.3, 1);
export const BACK = Easing.bezier(0.34, 1.56, 0.64, 1);
export const INOUT = Easing.bezier(0.65, 0, 0.35, 1);

// Interpolación con easing y clamp, en segundos absolutos del video
export const r = (t, a, b, x, y, easing = EASE) =>
  interpolate(t, [a, b], [x, y], {...CL, easing});
export const lin = (t, a, b, x, y) => interpolate(t, [a, b], [x, y], CL);

// 12742 -> "12.742"
export const fmt = (n) =>
  String(Math.round(n)).replace(/\B(?=(\d{3})+(?!\d))/g, '.');

// Cada escena conoce su segundo de inicio para trabajar en tiempo absoluto
export const SceneStart = createContext(0);
export const useT = () => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  return frame / fps + useContext(SceneStart);
};

export const Scene = ({name, start, end, children, fadeOut = true}) => {
  const {fps} = useVideoConfig();
  const from = Math.round(start * fps);
  const durationInFrames = Math.round(end * fps) - from;
  return (
    <Sequence name={name} from={from} durationInFrames={durationInFrames}>
      <SceneStart.Provider value={from / fps}>
        <SceneFade dur={durationInFrames / fps} fadeOut={fadeOut}>
          {children}
        </SceneFade>
      </SceneStart.Provider>
    </Sequence>
  );
};

const SceneFade = ({dur, fadeOut, children}) => {
  const frame = useCurrentFrame();
  const {fps} = useVideoConfig();
  const s = frame / fps;
  return (
    <AbsoluteFill
      style={{
        opacity: Math.min(
          lin(s, 0, 0.2, 0, 1),
          fadeOut ? lin(s, dur - 0.15, dur, 1, 0) : 1,
        ),
        scale: String(r(s, 0, 0.5, 1.08, 1)),
      }}
    >
      {children}
    </AbsoluteFill>
  );
};

// Elemento que aparece con rebote en `at` y desaparece en `out`
export const Pop = ({at, out, style, children}) => {
  const t = useT();
  if (t < at || (out !== undefined && t > out + 0.3)) {
    return null;
  }
  const inP = r(t, at, at + 0.45, 0, 1, BACK);
  const outP = out === undefined ? 1 : r(t, out, out + 0.3, 1, 0);
  return (
    <div
      style={{
        position: 'absolute',
        display: 'flex',
        justifyContent: 'center',
        alignItems: 'center',
        ...style,
        opacity: Math.min(lin(t, at, at + 0.12, 0, 1), outP),
        scale: String((0.5 + 0.5 * inP) * (0.7 + 0.3 * outP)),
      }}
    >
      {children}
    </div>
  );
};

export const Pill = ({children, color = C.accent, text = '#0b0b14', size = 46, style}) => (
  <div
    style={{
      fontFamily: FONT,
      fontWeight: 900,
      fontSize: size,
      color: text,
      background: color,
      padding: `${size * 0.28}px ${size * 0.6}px`,
      borderRadius: size,
      letterSpacing: 1,
      whiteSpace: 'nowrap',
      boxShadow: '0 10px 40px rgba(0,0,0,0.45)',
      ...style,
    }}
  >
    {children}
  </div>
);

export const BigText = ({children, size = 120, color = C.white, stroke = 10, style}) => (
  <div
    style={{
      fontFamily: FONT,
      fontWeight: 900,
      fontSize: size,
      lineHeight: 1,
      color,
      textAlign: 'center',
      WebkitTextStroke: `${stroke}px #05060f`,
      paintOrder: 'stroke fill',
      textShadow: '0 12px 50px rgba(0,0,0,0.6)',
      ...style,
    }}
  >
    {children}
  </div>
);
