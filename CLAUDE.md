# Aprende — guía de producción de vídeos

## Comunicación
- Hablar SIEMPRE en español con el usuario.
- Antes de ejecutar algo nuevo (guion, voz, render), proponerlo y esperar su "dale".

## Formato
- Render a 1080p y 60 fps (`--browser-executable=/opt/pw-browsers/chromium`).
- Si el mp4 pasa de ~70 MB, enviar versión ligera (libx264 crf 25, aac 160k).
- Voz: `npm run voz -- guiones/<guion>.txt <nombre>` (ElevenLabs, caché por fragmentos).

## Estilo visual (desde el Día 6 y el vídeo de "5 segundos en el futuro")
Estilo CINEMATOGRÁFICO en todo:
- Luz volumétrica (haces de lámpara/luna, polvo o chispas flotando).
- Profundidad de campo (fondo desenfocado; en la isla, efecto miniatura arriba/abajo).
- Cámara viva: zoom lento, movimiento suave de cámara en mano, movimientos por fotogramas clave.
- Sombras, reflejos, niebla, viñeta, grano SUAVE (el grano fuerte dispara el peso del archivo) y tono cálido.
- Cámara lenta en momentos clave.
- Referencias: `remotion/yt/DemoCine.jsx` (vídeos largos) y `remotion/civilizacion/DemoCivCine.jsx` (la isla).
- En la isla el efecto miniatura es pesado: usar `--timeout=180000` y versión ligera en días largos.

## La civilización (shorts verticales 1080x1920)
- Títulos "Día N". Seguir = unirse; comentar oficio/idea es opcional.
- Habitantes = 1 fundador + seguidores TikTok (@aprended) + Instagram (@aprendedconmigo) + YouTube (@aprendedconmigo).
- El comentario con más likes del día anterior se hace realidad. Sin votaciones.
- Cada vídeo: gancho fuerte, acción y un OBJETO ESCONDIDO (el primero en comentar el segundo exacto sale en el siguiente).
- No centrarse demasiado en personas concretas.
- Dylan: jefe y vidente. Profecía de las velas negras (Día 7 = la batalla).
- Mantener el kiosko y el sacapuntas separados.

## YouTube largo (16:9)
- "¿Qué pasaría si…?" de 8–10+ min (anuncios a mitad), capítulos, pantalla final de 12 s.
- Al final: promocionar La civilización y los otros vídeos del canal.
- De cada vídeo, un short de ~25 s con gancho que deje la duda y mande al vídeo completo (fondo con el vídeo en movimiento, no fijo).
