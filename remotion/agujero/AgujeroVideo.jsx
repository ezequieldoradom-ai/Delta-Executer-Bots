import React from 'react';
import {AbsoluteFill, staticFile} from 'remotion';
import {Audio} from '@remotion/media';
import {Scene} from '../tunel/lib';
import {Captions, chunkWords} from '../tunel/Captions';
import {Brand, ProgressBar, SpaceBackground} from '../tunel/Visuals';
import {OutroScene} from '../tunel/ScenesB';
import {CityScene, RoomScene} from './ScenesA';
import {BalanceScene, CalmScene, CollapseScene, DiskScene, QuestionScene} from './ScenesB';
import WORDS from '../../public/agujero-moneda.words.json';

// Tiempos de cada palabra generados por ElevenLabs (npm run voz)
export const DURATION = 96.0;

const CHUNKS = chunkWords(WORDS, [
  'moneda', 'habitación', 'final', 'superlenta', 'millonésima', 'tú', 'espagueti',
  'décima', 'ciudad', 'fuerza', 'detalle', 'todo', 'montaña', 'océano', 'lejos',
  'tierra', 'entera', 'mano', 'principio', 'planeta', 'parten', 'millones', 'minutos',
  'existe', 'fuego', 'negra', 'verdad', 'sepamos', 'aprende', 'comentarios',
  'próximo', 'likes', 'siguiente',
]);

const COMMENTS = [
  {user: '@curioso_23', text: '¿Y si el Sol se apagara?', base: 820},
  {user: '@ana.rv', text: '¿Y si la Luna desapareciera?', base: 640},
  {user: '@leo_x', text: '¿Y si nunca durmieras?', base: 410},
];

export const AgujeroVideo = () => {
  return (
    <AbsoluteFill style={{backgroundColor: '#04050d'}}>
      <SpaceBackground />
      <Scene name="Habitación" start={0} end={28.7}>
        <RoomScene />
      </Scene>
      <Scene name="Ciudad" start={28.7} end={34.3}>
        <CityScene />
      </Scene>
      <Scene name="La duda" start={34.3} end={43.1}>
        <QuestionScene />
      </Scene>
      <Scene name="Balanza" start={43.1} end={61.0}>
        <BalanceScene />
      </Scene>
      <Scene name="El planeta cae" start={61.0} end={72.0}>
        <CollapseScene />
      </Scene>
      <Scene name="Disco de fuego" start={72.0} end={79.4}>
        <DiskScene />
      </Scene>
      <Scene name="¿Podría pasar?" start={79.4} end={84.35}>
        <CalmScene />
      </Scene>
      {/* Mismo cierre que el video del túnel, desplazado a los tiempos de esta voz */}
      <Scene name="Cierre" start={84.35} end={DURATION} fadeOut={false} timeBase={69.55}>
        <OutroScene comments={COMMENTS} />
      </Scene>
      <Brand hideAt={84.0} />
      <ProgressBar />
      <Captions chunks={CHUNKS} />
      <Audio src={staticFile('agujero-moneda.mp3')} />
    </AbsoluteFill>
  );
};
