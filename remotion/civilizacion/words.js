// Busca en qué segundo empieza una palabra de la voz en off.
// W('jefe') -> primera vez que se dice "jefe"; W('pero', 1) -> la segunda.
// Así las animaciones quedan sincronizadas aunque se regenere la voz.
const clean = (w) => w.toLowerCase().replace(/[^a-záéíóúñü0-9]/gi, '');

export const makeW = (words) => (word, nth = 0) => {
  const target = clean(word);
  let seen = 0;
  for (const w of words) {
    if (clean(w.text) === target) {
      if (seen === nth) return w.start;
      seen++;
    }
  }
  throw new Error(`La palabra "${word}" (${nth}) no está en la voz`);
};
