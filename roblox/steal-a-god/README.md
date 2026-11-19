# Steal a God ⚡ Roba un Dios (Roblox)

Juego de Roblox: entrena tu velocidad en la cinta, roba sobres de dioses a los guardianes de cada zona,
ábrelos en los altares de tu parcela y completa el índice.

## Estructura
- `src/shared` — configuración (zonas, rarezas, dioses, precios, Robux), formato de números e idiomas (es/en).
- `src/server` — mundo, datos, núcleo (velocidad, dinero, índice, AFK), sobres y guardianes, combate, día/noche, rankings y tienda.
- `src/client` — interfaz para móvil, minijuego de la cinta, avisos, efectos.

## Publicar
```
rojo build default.project.json -o build/StealAGod.rbxlx
curl -X POST "https://apis.roblox.com/universes/2181650191/places/6031775954/versions?versionType=Published" \
  -H "x-api-key: <clave>" -H "Content-Type: application/xml" --data-binary @build/StealAGod.rbxlx
```
(La URL correcta lleva `/universes/v1/`.)

## Robux
Crea los pases y productos en create.roblox.com y pon sus IDs en `src/shared/Config.luau` (`Config.PASSES` y `Config.PRODUCTS`).
