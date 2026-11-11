// Frases de la voz en off con su inicio y fin (segundos), medidos sobre
// public/tunel-voz.mp3 con detección de silencios.
// Sintaxis: `38{14}` = se muestra "38" pero dura como 14 letras habladas.
// `*palabra` = palabra destacada siempre en color.
export const SEGMENTS = [
  [0.0, 1.49, 'Este agujero atraviesa'],
  [1.6, 2.51, 'la *Tierra *entera.'],
  [2.88, 3.58, 'Si saltas,'],
  [3.74, 6.91, 'sales al otro lado del planeta en *38{14} *minutos…'],
  [7.35, 8.73, 'o *mueres en el intento.'],
  [9.15, 11.67, 'Un túnel de *12.700{19} *kilómetros,'],
  [11.86, 12.7, 'de *Polo *Norte'],
  [12.82, 13.45, 'a *Polo *Sur,'],
  [13.8, 14.82, '*sin *aire dentro.'],
  [15.28, 15.9, 'Saltas…'],
  [16.32, 18.2, 'y desde el primer segundo *flotas,'],
  [18.54, 19.51, 'como un *astronauta.'],
  [19.96, 21.03, 'Y aquí viene lo *raro:'],
  [21.49, 22.03, 'al bajar,'],
  [22.25, 23.87, 'la gravedad no se debilita.'],
  [24.26, 24.97, '*Aumenta.'],
  [25.38, 26.02, 'El *núcleo'],
  [26.14, 26.82, 'es tan *denso'],
  [26.93, 29.16, 'que tira de ti *más *fuerte que en la superficie.'],
  [29.57, 34.4, 'A los *19{10} *minutos cruzas el centro de la Tierra a casi *10{4} *kilómetros *por *segundo.'],
  [34.74, 35.85, 'De Madrid a Barcelona'],
  [36.0, 36.73, 'en *un *minuto.'],
  [37.16, 38.47, 'Ahí la gravedad es *cero…'],
  [38.85, 40.9, 'pero la *inercia te empuja hacia el otro lado.'],
  [41.28, 42.68, 'Luego la gravedad te *frena,'],
  [42.94, 44.3, 'y a los *38{14} *minutos'],
  [44.44, 45.68, 'asomas por el otro lado,'],
  [46.12, 46.41, '*quieto,'],
  [46.85, 47.81, 'justo en el borde.'],
  [48.2, 49.99, 'Tienes *un *segundo para agarrarte.'],
  [50.39, 51.14, 'Si *fallas…'],
  [51.55, 52.31, 'caes otra vez.'],
  [52.85, 53.31, 'Y otra.'],
  [53.87, 54.49, '*Para *siempre.'],
  [55.03, 55.6, '¿El *problema?'],
  [56.04, 56.52, 'Con *aire,'],
  [56.69, 58.95, 'el rozamiento te dejaría *atrapado en el centro.'],
  [59.31, 61.71, 'El núcleo está a más de *5.000{9} *grados,'],
  [62.0, 63.98, 'tan caliente como la superficie del *Sol.'],
  [64.35, 67.1, 'Y lo más hondo que hemos cavado son *12{4} *kilómetros.'],
  [67.38, 69.58, 'Ni el *0,1{7} *% del camino.'],
  [70.12, 73.98, 'Si te voló la cabeza, *sígueme en *Aprende para más preguntas imposibles.'],
  [74.31, 75.36, 'Y dime en *comentarios:'],
  [75.63, 77.62, '¿qué quieres que explique en el *próximo *video?'],
  [77.98, 79.42, 'El comentario con *más *likes…'],
  [79.69, 80.5, 'es el *siguiente.'],
];

export const DURATION = 80.8;

const parseWord = (raw) => {
  let w = raw;
  const strong = w.startsWith('*');
  if (strong) {
    w = w.slice(1);
  }
  let weight = null;
  const m = w.match(/^(.*)\{(\d+)\}(.*)$/);
  if (m) {
    w = m[1] + m[3];
    weight = Number(m[2]);
  }
  return {text: w, strong, weight: (weight ?? w.length) + 1};
};

// Reparte cada frase en palabras con tiempos proporcionales a su longitud
// y las agrupa en bloques cortos para los subtítulos.
const MAX_WORDS = 4;
const MAX_CHARS = 22;

export const CHUNKS = SEGMENTS.flatMap(([start, end, text]) => {
  const words = text.split(' ').map(parseWord);
  const total = words.reduce((a, w) => a + w.weight, 0);
  let acc = start;
  const timed = words.map((w) => {
    const d = ((end - start) * w.weight) / total;
    const out = {...w, start: acc, end: acc + d};
    acc += d;
    return out;
  });
  const chunks = [];
  let cur = [];
  for (const w of timed) {
    const len = cur.reduce((a, x) => a + x.text.length + 1, 0) + w.text.length;
    if (cur.length && (cur.length >= MAX_WORDS || len > MAX_CHARS)) {
      chunks.push(cur);
      cur = [];
    }
    cur.push(w);
  }
  if (cur.length) {
    chunks.push(cur);
  }
  return chunks.map((ws, i) => ({
    words: ws,
    start: ws[0].start,
    // el bloque se queda en pantalla hasta que empieza el siguiente
    end: i < chunks.length - 1 ? ws[ws.length - 1].end : end + 0.3,
  }));
});
