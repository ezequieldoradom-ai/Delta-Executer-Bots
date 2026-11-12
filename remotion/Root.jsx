import React from 'react';
import { Composition } from 'remotion';
import { DeltaIntro } from './DeltaIntro';
import { TunelVideo } from './tunel/TunelVideo';
import { DURATION } from './tunel/timing';
import { AgujeroVideo, DURATION as AGUJERO_DURATION } from './agujero/AgujeroVideo';
import { Episodio01, DURATION as CIV01_DURATION } from './civilizacion/Episodio01';
import { Episodio02, DURATION as CIV02_DURATION } from './civilizacion/Episodio02';
import { Dia03, DURATION as CIV03_DURATION } from './civilizacion/Dia03';

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
      <Composition
        id="Civilizacion01"
        component={Episodio01}
        durationInFrames={Math.round(CIV01_DURATION * FPS)}
        fps={FPS}
        width={1080}
        height={1920}
      />
      <Composition
        id="Civilizacion02"
        component={Episodio02}
        durationInFrames={Math.round(CIV02_DURATION * FPS)}
        fps={FPS}
        width={1080}
        height={1920}
      />
      <Composition
        id="Civilizacion03"
        component={Dia03}
        durationInFrames={Math.round(CIV03_DURATION * FPS)}
        fps={FPS}
        width={1080}
        height={1920}
      />
    </>
  );
};
