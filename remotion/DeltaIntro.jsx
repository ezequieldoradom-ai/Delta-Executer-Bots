import React from 'react';
import { AbsoluteFill, interpolate, spring, useCurrentFrame, useVideoConfig } from 'remotion';

export const DeltaIntro = ({ title }) => {
  const frame = useCurrentFrame();
  const { fps } = useVideoConfig();

  const scale = spring({ frame, fps, config: { damping: 12 } });
  const opacity = interpolate(frame, [0, 20], [0, 1], { extrapolateRight: 'clamp' });

  return (
    <AbsoluteFill
      style={{
        backgroundColor: '#0f172a',
        justifyContent: 'center',
        alignItems: 'center',
      }}
    >
      <h1
        style={{
          color: 'white',
          fontFamily: 'sans-serif',
          fontSize: 100,
          opacity,
          transform: `scale(${scale})`,
        }}
      >
        {title}
      </h1>
    </AbsoluteFill>
  );
};
