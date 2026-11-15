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

// Primera vez que se dice `word` a partir del segundo `after`
export const makeWa = (words) => (word, after = 0) => {
  const target = clean(word);
  for (const w of words) {
    if (w.start >= after && clean(w.text) === target) return w.start;
  }
  throw new Error(`La palabra "${word}" no aparece después de ${after}s`);
};
