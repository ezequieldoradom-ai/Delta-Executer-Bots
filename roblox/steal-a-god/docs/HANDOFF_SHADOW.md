# Steal a God — traspaso a la sesión de Claude Code en Shadow (PC con Windows)

Esta nota es para la sesión de Claude Code que corre en el PC de Shadow del dueño. Léela entera antes de tocar nada.
Habla SIEMPRE en español con el usuario (ver `CLAUDE.md` en la raíz del repositorio).

## Qué es el juego
"Steal a God ⚡ / Roba un Dios": simulador de Roblox hecho 100 % por código con Rojo (Luau). El dueño solo tenía
iPhone; ahora tiene este PC en la nube (Shadow) para usar **Roblox Studio** y que tú veas el juego de verdad.
Bucle: entrenar velocidad en una cinta de tu parcela → entrar en un pasillo gigante de 6 zonas mitológicas
(griega, celta, egipcia, azteca, babilónica, nórdica) → robar un sobre del nido de la zona → el guardián gigante te
persigue → llevarlo a tu parcela → se abre en un altar → sale un dios (14 rarezas, con kilos) que da dinero por segundo.
Hay noche/día, índice, bate PvP, pases y productos de Robux, rankings, vendedores (Hécate vende auras, Quirón
entrenadores), música de persecución, efectos de cliente (Fx.luau) y AFK.

- Universo 2181650191 · Place 6031775954 · Versión publicada ahora: **36**.
- Repositorio: `ezequieldoradom-ai/Delta-Executer-Bots`, rama de trabajo **`claude/instala-remotion-8aoip0`**.
  El juego está en `roblox/steal-a-god/`.

## Estructura (Rojo, `default.project.json`)
- `src/shared/` → ReplicatedStorage.Shared: `Config` (todo lo ajustable: rarezas, dioses, zonas, precios, Robux, luz,
  sonidos, texturas), `Locale` (es/en), `GodModel` (figuras de piezas y aspecto de cada dios), `Format`.
- `src/server/` → ServerScriptService.Server: `init.server.luau` (arranque; módulos opcionales AuraFx, PackStyle,
  Vendors), `World` (mapa, parcelas, plaza, murallas, pasillo, guardianes), `Packs` + `PackStyle` (sobres, nidos, 14
  diseños por rareza), `Core` (sesiones, acciones, tick, estado), `Data` (guardado con bloqueo de sesión), `Shop`
  (Robux, recibos idempotentes), `Avatars` (avatares R15 de los dioses; **ropa del catálogo desde `Outfits.luau`**),
  `Vendors`, `AuraFx`, `Combat`, `DayNight`, `Boards`, `Quests` (fase 2, aún sin conectar), `Models`, `Net`.
- `src/client/` → StarterPlayerScripts.Client: `init.client.luau` (HUD y paneles), `Fx.luau` (anima las etiquetas
  FxSpin/FxBob/FxOrbit/FxRainbow/FxGlitch/LocText, estelas), `Music.luau` (música de persecución).
- `tools/`: pruebas y utilidades. `test_full.luau` es la batería de pruebas del servidor (debe acabar en `🎉 TODO OK`).
  `catalog.py`, `preview.py`, `lx.py` usan la API de Roblox con una clave que **solo existe en la sesión en la nube**
  (aquí no funcionarán; no pidas ni busques claves).

## Cómo trabajar aquí con Roblox Studio
1. Instala lo que falte (pide permiso al usuario antes): Rojo 7.4.4 (por ejemplo con
   `winget install Rojo.Rojo` o el .exe de https://github.com/rojo-rbx/rojo/releases) y el **plugin de Rojo** en
   Studio (`rojo plugin install`).
2. Roblox Studio: el usuario inicia sesión él mismo con su cuenta (nunca le pidas la contraseña). Abre el place
   6031775954 (Archivo → Abrir desde Roblox, o desde create.roblox.com → "Editar en Studio").
3. En `roblox/steal-a-god/`: `rojo serve` y en Studio: Plugins → Rojo → Connect. El código del repositorio se
   sincroniza con Studio en vivo.
4. Pulsa **Play** (F5) para probar como jugador: ahí se ven de verdad texturas, partículas, luces, menús, ropa del
   catálogo, auras, sobres y efectos. Haz capturas y corrige lo que se vea mal.
5. Publicar: desde Studio (Archivo → Publicar en Roblox) **solo cuando el usuario diga "dale"**. Antes, guarda los
   cambios en git.

## Prioridades (lo que el dueño quiere)
- Que todo se vea **lo más pulido y épico posible** (referencia: simuladores populares tipo "steal a pack":
  colores vivos, efectos llamativos), con identidad mitológica (dioses, templos, mármol, oro, runas).
- Revisar en Studio, en este orden: ropa del catálogo de dioses/guardianes/vendedores (¿se ve bien puesta? ¿algo
  flota, atraviesa o es enorme?), los 14 diseños de sobres y los nidos, las 6 auras, los santuarios de Hécate y
  Quirón, la luz/atmósfera, los menús en pantalla de móvil, la música de persecución.
- Mejoras que solo se pueden hacer bien viendo: tamaños y transparencias de partículas, posición de prendas,
  usar modelos gratuitos de la Toolbox de Studio (templos, estatuas, árboles) cuando mejoren claramente el resultado
  (comprueba que son gratuitos, sin scripts dentro y de autores fiables).
- **No** hacer personajes que copien personajes de series/anime con derechos (aunque cambien de nombre).

## Coordinación con la sesión en la nube
- La sesión en la nube está terminando la **ropa de los 64 dioses** (`src/server/Outfits.luau`) y la subirá a esta
  rama. Haz `git pull` antes de empezar y a menudo; trabaja en commits pequeños y súbelos (`git push`) para no pisaros.
- No edites `src/server/Outfits.luau` hasta que la sesión en la nube lo haya subido completo (el usuario te lo dirá).
- Mensajes de commit en español.
