# Pendiente (traspaso al PC del usuario, 25-11-2026)

A partir de ahora se trabaja en una sesión de Claude Code en el PC del usuario (pestaña Code de la app de escritorio).
Ya no se usa la sesión de Shadow: no hace falta escribir en ningún buzón ni coordinarse con ella.
Rama de trabajo: `claude/instala-remotion-8aoip0`. Las normas de `CLAUDE.md` siguen valiendo (hablar en español, proponer antes de hacer un guion, una voz o un render…).

## 1. Lucky Obby Race (`roblox/lucky-obby/`)
- Universo 10777751482, lugar 88014747422090. Ya es **público**.
- **Arreglar los bugs confirmados** de `roblox/lucky-obby/docs/BUGS.md`, por orden: primero los dos graves (el buzón puede congelar el servidor; un punto de control saltado impide llegar a la meta). El usuario aún no ha dado el "dale" para arreglarlos.
- Después: pasar `tools/test_full.luau` y el `SelfTest` del servidor y publicar.
- **Lo hace el usuario:** el cuestionario de madurez (Creator Hub → Audience → Maturity & Compliance). Sigue sin clasificar. Respuestas sinceras:
  - violencia leve (empujones, guantazos y objetos de dibujos);
  - miedo leve (el mundo "Cementerio encantado", con fantasmas y lápidas);
  - todo lo demás, No: sin Robux, sin apuestas, y el buzón solo lo lee el dueño.

  Así debería salir 9+.

## 2. Steal a God (`roblox/steal-a-god/`)
- Público. **Lo hace el usuario:** subir las 3 miniaturas de `roblox/steal-a-god/docs/pagina/` en Creator Hub y revisar el cuestionario de madurez (debería salir 9+).

## 3. Short promocional de Steal a God (Remotion)
- Guion aprobado: `guiones/sag-short-01.txt`. Voz hecha: `public/sag-short-01.mp3` y `.words.json`.
- Composición: `remotion/roblox/ShortStealAGod.jsx` (`Short-StealAGod` en `remotion/Root.jsx`).
- Faltan los **clips de juego reales** (vídeo vertical u horizontal, unos 3–5 s cada uno), con estos nombres en `public/sag/clips/`:
  1. `clip1_robo.mp4`: robar un dios de un altar;
  2. `clip2_huida.mp4`: huir con el dios mientras el guardián te persigue (o el golpe que te manda volando);
  3. `clip3_apertura.mp4`: abrir un sobre y ver cómo sube de rareza (¿COMÚN? → ¿POCO COMÚN? → …);
  4. `clip4_mutacion.mp4`: un dios mutado en tu parcela;
  5. `clip5_olimpo.mp4`: el obby del Olimpo (isla flotante, etapas);
  6. `clip6_plaza.mp4`: la plaza o la base con jugadores, para el final.

  Son los nombres de `SCENES` en `ShortStealAGod.jsx`. En el PC se pueden grabar directamente con Roblox abierto.
- Después: poner `CLIPS = true`, renderizar a 1080p y 60 fps (light si pasa de ~70 MB) y hacer la versión en inglés.

## Claves en el PC
En la nube las claves se inyectaban solas (`proxy-injected`); en el PC no. **No pegues claves en el chat.**
- **Voz (ElevenLabs):** `scripts/voz.mjs` lee la variable de entorno `ELEVENLABS_API_KEY`.
- **Roblox Open Cloud:** las herramientas `tools/lx.py`, `tools/preview.py` y `tools/upload_model.py` de cada juego envían la cabecera `x-api-key: proxy-injected`. Hay que cambiarlas para que lean una variable de entorno (por ejemplo `ROBLOX_API_KEY`). Si no, se publica desde Roblox Studio.
- **Render:** `--browser-executable=/opt/pw-browsers/chromium` solo existe en la nube. En Windows, quita esa opción y Remotion usa su propio navegador.
