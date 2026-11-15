import {Config} from '@remotion/cli/config';

// Alta calidad: menos compresión para que los degradados no se vean pixelados
Config.setVideoImageFormat('jpeg');
Config.setJpegQuality(95);
Config.setCrf(16);

// Usa los 4 núcleos de la máquina para renderizar más rápido
Config.setConcurrency(4);
