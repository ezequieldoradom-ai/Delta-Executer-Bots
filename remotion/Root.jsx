import React from 'react';
import { Composition } from 'remotion';
import { DeltaIntro } from './DeltaIntro';
import { TunelVideo } from './tunel/TunelVideo';

export const RemotionRoot = () => {
  return (
    <>
      <Composition
        id="DeltaIntro"
        component={DeltaIntro}
        durationInFrames={90}
        fps={30}
        width={1280}
        height={720}
        defaultProps={{ title: 'Delta Executer' }}
      />
      <Composition
        id="TunelTierra"
        component={TunelVideo}
        durationInFrames={2424}
        fps={30}
        width={1080}
        height={1920}
      />
    </>
  );
};
