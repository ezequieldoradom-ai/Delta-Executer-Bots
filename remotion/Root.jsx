import React from 'react';
import { Composition } from 'remotion';
import { DeltaIntro } from './DeltaIntro';

export const RemotionRoot = () => {
  return (
    <Composition
      id="DeltaIntro"
      component={DeltaIntro}
      durationInFrames={90}
      fps={30}
      width={1280}
      height={720}
      defaultProps={{ title: 'Delta Executer' }}
    />
  );
};
