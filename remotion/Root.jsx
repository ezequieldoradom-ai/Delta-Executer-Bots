import React from 'react';
import { Composition } from 'remotion';
import { DeltaIntro } from './DeltaIntro';
import { TunelVideo } from './tunel/TunelVideo';
import { DURATION } from './tunel/timing';
import { AgujeroVideo, DURATION as AGUJERO_DURATION } from './agujero/AgujeroVideo';
import { Episodio01, DURATION as CIV01_DURATION } from './civilizacion/Episodio01';
import { Episodio02, DURATION as CIV02_DURATION } from './civilizacion/Episodio02';
import { Dia03, DURATION as CIV03_DURATION } from './civilizacion/Dia03';
import { Dia04, DURATION as CIV04_DURATION } from './civilizacion/Dia04';
import { Dia05, MiniaturaDia05, DURATION as CIV05_DURATION } from './civilizacion/Dia05';
import { Edad20000, DURATION as YT20000_DURATION } from './yt/Edad20000';
import { MiniaturaA, MiniaturaB, MiniaturaC, MiniaturaFosaA, MiniaturaFosaB, MiniaturaFosaC } from './yt/Miniaturas';
import { Fosa, DURATION as FOSA_DURATION } from './yt/Fosa';
import { Short20000, SHORT_20000_DURATION, ShortFosa, SHORT_FOSA_DURATION, ShortFuturo, SHORT_FUT_DURATION } from './yt/Clips';
import { Futuro, DURATION as FUTURO_DURATION } from './yt/Futuro';
import { DemoCine, DEMO_DURATION } from './yt/DemoCine';
import { MiniaturaDia04 } from './civilizacion/MiniaturaDia04';

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
      <Composition
        id="Civilizacion04"
        component={Dia04}
        durationInFrames={Math.round(CIV04_DURATION * FPS)}
        fps={FPS}
        width={1080}
        height={1920}
      />
      <Composition
        id="Civilizacion05"
        component={Dia05}
        durationInFrames={Math.round(CIV05_DURATION * FPS)}
        fps={FPS}
        width={1080}
        height={1920}
      />
      <Composition id="Miniatura-Dia05" component={MiniaturaDia05} durationInFrames={1} fps={FPS} width={1080} height={1920} />
      <Composition
        id="YT-Despertar20000"
        component={Edad20000}
        durationInFrames={Math.round(YT20000_DURATION * FPS)}
        fps={FPS}
        width={1920}
        height={1080}
      />
      <Composition
        id="YT-FosaMarianas"
        component={Fosa}
        durationInFrames={Math.round(FOSA_DURATION * FPS)}
        fps={FPS}
        width={1920}
        height={1080}
      />
      <Composition id="YT-Futuro5s" component={Futuro} durationInFrames={Math.round(FUTURO_DURATION * FPS)} fps={FPS} width={1920} height={1080} />
      <Composition id="Miniatura-Dia04" component={MiniaturaDia04} durationInFrames={1} fps={FPS} width={1080} height={1920} />
      <Composition id="Demo-Cine" component={DemoCine} durationInFrames={Math.round(DEMO_DURATION * FPS)} fps={FPS} width={1920} height={1080} />
      <Composition id="Short-Futuro" component={ShortFuturo} durationInFrames={Math.round(SHORT_FUT_DURATION * FPS)} fps={FPS} width={1080} height={1920} />
      <Composition id="Short-20000" component={Short20000} durationInFrames={Math.round(SHORT_20000_DURATION * FPS)} fps={FPS} width={1080} height={1920} />
      <Composition id="Short-Fosa" component={ShortFosa} durationInFrames={Math.round(SHORT_FOSA_DURATION * FPS)} fps={FPS} width={1080} height={1920} />
      {[
        ['Miniatura-20000-A', MiniaturaA],
        ['Miniatura-20000-B', MiniaturaB],
        ['Miniatura-20000-C', MiniaturaC],
        ['Miniatura-Fosa-A', MiniaturaFosaA],
        ['Miniatura-Fosa-B', MiniaturaFosaB],
        ['Miniatura-Fosa-C', MiniaturaFosaC],
      ].map(([id, comp]) => (
        <Composition key={id} id={id} component={comp} durationInFrames={1} fps={FPS} width={1920} height={1080} />
      ))}
    </>
  );
};
