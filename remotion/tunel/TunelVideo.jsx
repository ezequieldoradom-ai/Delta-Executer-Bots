import React from 'react';
import {AbsoluteFill, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {Scene} from './lib';
import {Captions} from './Captions';
import {Brand, ProgressBar, SpaceBackground} from './Visuals';
import {GravityScene, HookScene, TunnelIntroScene} from './ScenesA';
import {AirScene, DepthScene, HeatScene, JourneyScene, OutroScene, ProblemScene} from './ScenesB';

// "¿Qué pasaría si saltaras por un túnel que atraviesa la Tierra?" — cuenta Aprende
export const TunelVideo = () => {
  return (
    <AbsoluteFill style={{backgroundColor: '#04050d'}}>
      <SpaceBackground />
      <Scene name="Gancho" start={0} end={9.05}>
        <HookScene />
      </Scene>
      <Scene name="El túnel" start={9.05} end={19.75}>
        <TunnelIntroScene />
      </Scene>
      <Scene name="Gravedad" start={19.75} end={29.35}>
        <GravityScene />
      </Scene>
      <Scene name="El viaje" start={29.35} end={54.8}>
        <JourneyScene />
      </Scene>
      <Scene name="El problema" start={54.8} end={55.95}>
        <ProblemScene />
      </Scene>
      <Scene name="Con aire" start={55.95} end={59.15}>
        <AirScene />
      </Scene>
      <Scene name="Calor" start={59.15} end={64.2}>
        <HeatScene />
      </Scene>
      <Scene name="Profundidad" start={64.2} end={69.85}>
        <DepthScene />
      </Scene>
      <Scene name="Cierre" start={69.85} end={80.8} fadeOut={false}>
        <OutroScene />
      </Scene>
      <Brand />
      <ProgressBar />
      <Captions />
      <Audio src={staticFile('tunel-voz.mp3')} />
    </AbsoluteFill>
  );
};
