import React from 'react';
import { Composition } from 'remotion';
import { DeltaIntro } from './DeltaIntro';
import { TunelVideo } from './tunel/TunelVideo';
import { DURATION } from './tunel/timing';
import { AgujeroVideo, DURATION as AGUJERO_DURATION } from './agujero/AgujeroVideo';

// Formato por defecto de los videos de Aprende: vertical 1080x1920 a 60 fps
const FPS = 60;

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
        durationInFrames={Math.round(DURATION * FPS)}
        fps={FPS}
        width={1080}
        height={1920}
      />
      <Composition
        id="AgujeroMoneda"
        component={AgujeroVideo}
        durationInFrames={Math.round(AGUJERO_DURATION * FPS)}
        fps={FPS}
        width={1080}
        height={1920}
      />
    </>
  );
};
