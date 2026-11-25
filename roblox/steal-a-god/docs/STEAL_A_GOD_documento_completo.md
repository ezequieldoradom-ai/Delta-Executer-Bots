# Steal a God ⚡ (Roba un Dios) — Documento completo del juego de Roblox

> Documento para explicar el juego a otra IA o a otro desarrollador. Contiene la idea, todas las mecánicas, los números, la arquitectura del código, los IDs de Roblox y cómo se publica. El código completo va en el archivo aparte `STEAL_A_GOD_codigo_completo.txt`.

---

## 1. Resumen en una frase

Juego de Roblox del género **simulador incremental** (estilo "Steal a Brainrot" / "Steal an Anime Pack") con temática de **mitología**: entrenas tu **velocidad** en una cinta, corres por un **pasillo gigante dividido en zonas**, **robas sobres** custodiados por **guardianes gigantes** que te persiguen, los llevas a tu **parcela**, los abres en **altares** con cuenta atrás y te salen **dioses** de distintas **rarezas** y **kilos** que pasean por tu parcela y te dan **dinero por segundo**. Hay combate con **bates/armas mitológicas** en el pasillo, ciclo **día/noche**, **índice** de colección con recompensas, **rankings globales**, **Robux** y soporte de **móvil, PC y consola (PS5/Xbox)**.

- Nombre: **Steal a God ⚡** (en español: **Roba un Dios**)
- Idiomas: inglés y español (cada jugador ve su idioma automáticamente)
- Plataformas: móvil, tablet, PC, consola (activada), VR activada por defecto de Roblox
- Jugadores por servidor: **6** (una parcela por jugador)
- Clasificación de edad asignada por Roblox: **13+**
- Género recomendado en Roblox: **Simulación → Simulador incremental** (alternativa: Tycoon)

---

## 2. Datos técnicos de la experiencia en Roblox

| Dato | Valor |
|---|---|
| Universe ID (experiencia) | `2181650191` |
| Place ID (lugar) | `6031775954` |
| ID del dueño (usuario Roblox) | `2054465776` |
| Herramienta para compilar | Rojo 7.4.4 (`rojo build default.project.json -o build/StealAGod.rbxlx`) |
| Publicación | Roblox Open Cloud, Place Publishing API (`POST /universes/v1/{universe}/places/{place}/versions?versionType=Published`, cabecera `x-api-key`, cuerpo = .rbxlx) |
| Pruebas automáticas | Roblox Open Cloud **Luau Execution** (se ejecuta un script en un servidor real de Roblox y devuelve el resultado) |
| Lenguaje | Luau (Roblox) |
| Repositorio | `roblox/steal-a-god/` dentro del repo `Delta-Executer-Bots` (rama `claude/instala-remotion-8aoip0`) |

El dueño trabaja **solo desde un iPhone** (no tiene Roblox Studio), por eso todo se construye por código, se compila con Rojo y se sube con la API de Open Cloud.

---

## 3. Estructura del proyecto (Rojo)

```
roblox/steal-a-god/
├── default.project.json          (mapa de Rojo: qué carpeta va a qué servicio)
├── src/
│   ├── shared/   → ReplicatedStorage.Shared  (lo usan servidor y cliente)
│   │   ├── Config.luau     configuración: zonas, rarezas, 64 dioses, precios, Robux, kilos, modelos, texturas
│   │   ├── Format.luau     números absurdos (1.5K, 2M, 3B, 4T, 5Qa, 6Qi, 7Sx...) y tiempos
│   │   ├── Locale.luau     textos en español e inglés
│   │   └── GodModel.luau   construye la figura de cada dios con piezas, accesorios, auras y animación
│   ├── server/   → ServerScriptService.Server (Script con módulos hijos)
│   │   ├── init.server.luau  arranque: carga módulos en orden y los inicia
│   │   ├── Net.luau          crea los RemoteEvents
│   │   ├── Data.luau         guardado con DataStore (perfil del jugador, progreso offline)
│   │   ├── Models.luau       carga modelos 3D subidos (Blender) con InsertService
│   │   ├── Avatars.luau      convierte cada dios/guardián en avatar R15 con accesorios y animaciones oficiales
│   │   ├── World.luau        construye el mapa: plaza, 6 parcelas, pasillo con 6 zonas, guardianes, rankings
│   │   ├── Core.luau         jugadores, velocidad, cinta, combo, dinero, índice, entrenadores, auras, AFK, estado
│   │   ├── Packs.luau        sobres: aparición, robo, persecución, entrega, altares, apertura, avisos globales
│   │   ├── Combat.luau       bate y armas mitológicas, empujones, robar sobres de un golpe
│   │   ├── DayNight.luau     ciclo día (5 min) / noche (15 s)
│   │   ├── Boards.luau       rankings globales (OrderedDataStore)
│   │   └── Shop.luau         Robux: pases y productos (ProcessReceipt)
│   └── client/   → StarterPlayerScripts.Client (LocalScript)
│       └── init.client.luau  toda la interfaz, animaciones, efectos, controles PC/mando, ajustes
├── tools/
│   ├── lx.py                 lanza un script Luau en un servidor de Roblox (Luau Execution) y muestra el resultado
│   ├── test_full.luau        batería de pruebas automática (arranca el servidor y prueba cada sistema)
│   ├── export_scene.luau     exporta todas las piezas del mapa para renderizarlas en 3D fuera de Roblox
│   ├── upload_model.py       sube un .fbx a la cuenta como Modelo (Open Cloud Assets API)
│   ├── render/               visor three.js + Playwright para capturas 3D de la escena exportada
│   ├── blender/gen.py        generador de personajes 3D en Blender (Zeus, Thor, Anubis, Minotauro)
│   └── vfx/                  texturas de efectos generadas (brillo, destello, anillo, humo, runas, chispa, llama, studs, madera)
└── docs/                     este documento
```

**Comunicación cliente-servidor** (RemoteEvents en `ReplicatedStorage.Remotes`):
- `State` (servidor → cliente, 2 veces por segundo): todo el estado del jugador.
- `Announce` (servidor → cliente): avisos para el chat y carteles grandes.
- `Toast` (servidor → cliente): mensajes cortos.
- `Reveal` (servidor → cliente): animación al abrir un sobre (dios, si es nuevo, kilos).
- `Knock` (servidor → cliente): empujón al recibir un golpe (el cliente aplica la velocidad).
- `Offer` (servidor → cliente): ofrecer compra ("Salvar el sobre") o el popup de dinero sin conexión.
- `Action` (cliente → servidor): comprar, fusionar, equipar, AFK, reconectar, soltar sobre, reclamar dinero offline, guardar ajustes.
- `Combo` (cliente → servidor): acierto en el minijuego de la cinta.

Los textos del servidor se envían como **clave + argumentos** (`{rarity=n}`, `{zone=n}`, `{god=id}`...) y el cliente los traduce a su idioma. Los carteles del mundo (sobres, altares, guardianes, zonas, cabeza de jugadores) llevan atributos y la etiqueta `Loc`; el cliente rellena el texto en su idioma.

---

## 4. Bucle de juego

1. Apareces en tu **parcela** (zona segura).
2. Te subes a tu **cinta de correr** → ganas **velocidad** por segundo. Minijuego de **combo**: una barra con un marcador que oscila; si pulsas **¡TOCA!** cuando está en la zona verde, sube el combo (hasta x5).
3. Con la velocidad te mueves más rápido y desbloqueas **zonas** del pasillo (cada zona exige una velocidad mínima; si no la tienes te empuja hacia atrás).
4. En cada zona hay **sobres** en el suelo. Al robar uno (ProximityPrompt), el **guardián** de esa zona te **persigue**.
   - Si tu velocidad (estadística) ≥ la velocidad del guardián → corre al 82 % de tu velocidad (escapas).
   - Si no → corre al 118 % + 4 (te alcanza). Si te alcanza: pierdes el sobre y vuelves a tu parcela (o puedes comprar "Salvar el sobre").
5. Si llegas a tu parcela con el sobre, se coloca en un **altar** con una **cuenta atrás** según la rareza.
6. Cuando termina, lo abres → animación espectacular → te sale un **dios** (rareza del sobre, kilos del sobre).
7. Los mejores dioses (por dinero) ocupan tu parcela (capacidad = pedestales), **pasean** libremente y generan **dinero por segundo**.
8. El dinero compra mejoras (cinta, parcela, altares, entrenadores, auras) → más velocidad → mejores zonas → mejores dioses.
9. Cada 5 minutos llega la **noche** (15 s): pasillo cerrado, boosts, y al **amanecer** se renuevan todos los sobres y se avisa en el chat de los buenos.

---

## 5. Mapa (compacto, estilo simulador)

- **Plaza central** de mármol (x −38..38, z −110..106) con **fuente** (agua brillante y chorros de partículas), **farolillos** cálidos, **flores** y **árboles** alrededor.
- **6 parcelas** de 56×56 studs: 3 a cada lado de la plaza (x = ±66, z = −58 / 0 / 58), **mirando al centro**. Cada parcela: suelo de **madera** cálida (mejora de material con el nivel), cinta de correr en la esquina delantera, dioses paseando por el centro, hasta 10 altares al fondo, columnas y borde.
- **3 paneles de ranking** al fondo de la plaza (velocidad, dinero, tiempo jugado).
- **Pasillo/pista** que empieza en z = 110, **140 studs de ancho**, suelo con textura de **studs clásicos de Roblox**, muros de color con franja de **neón**, **arcos de neón** en cada cambio de zona, decoración temática fuera de los muros.
- Cada zona mide **200 studs** de largo. Al final de la zona 6 hay un muro "Más zonas próximamente".
- **Luz de atardecer** dorada (ClockTime 16.3), Atmosphere cálida, Bloom, SunRays, corrección de color. Al entrar en cada zona el cliente cambia el **tinte y la atmósfera** al color de la zona.

### Zonas (v1: 6 zonas, se planean 12)

| # | Zona | Velocidad mínima | Guardián | Velocidad del guardián | Color |
|---|---|---|---|---|---|
| 1 | Arcadia griega | 0 | Minotauro | 30 | verde vivo |
| 2 | Bosque celta | 1K | Dullahan (sin cabeza) | 20K | esmeralda |
| 3 | Desierto de Egipto | 50K | Esfinge | 150K | amarillo arena |
| 4 | Selva azteca | 2M | Jaguar guerrero | 6M | naranja |
| 5 | Babilonia | 100M | Lamassu | 300M | azul |
| 6 | Fiordos nórdicos | 5B | Fenrir | 15B | morado cósmico |

Planeadas para actualizaciones: Inframundo (Cerbero), Atlántida (Kraken), Forja de Hefesto (Cíclope), Ragnarök (Jörmungandr), Olimpo (Tifón), El Vacío (Ouroboros) con velocidades 250B, 10T, 500T, 25Qa, 1Qi, 100Sx.

---

## 6. Rarezas (14)

| # | Rareza | Tiempo de apertura | Dinero/s base (100 kg) |
|---|---|---|---|
| 1 | Común | 10 s | 4 |
| 2 | Poco común | 30 s | 24 |
| 3 | Rara | 1 min | 144 |
| 4 | Épica | 3 min | 864 |
| 5 | Legendaria | 10 min | 5.2K |
| 6 | Mítica | 30 min | 31K |
| 7 | Divina | 1 h | 187K |
| 8 | Celestial | 3 h | 1.1M |
| 9 | Primordial | 8 h | 6.7M |
| 10 | Secreta | 24 h | 40M |
| 11 | Godlike | 2 días | 242M |
| 12 | Omnipotente | 4 días | 1.45B |
| 13 | Infinita | 7 días | 8.7B |
| 14 | ??? | 7 días | 52B |

Fórmula de dinero: `4 * 6^(rareza-1)` × (kilos/100) × multiplicadores.

**Probabilidades por zona** (pesos):
- Z1: Común 70, Poco común 25, Rara 4.5, Épica 0.5
- Z2: Común 30, Poco común 45, Rara 20, Épica 4.5, Legendaria 0.5
- Z3: Poco común 30, Rara 45, Épica 20, Legendaria 4.5, Mítica 0.5
- Z4: Rara 30, Épica 45, Legendaria 20, Mítica 4.5, Divina 0.5
- Z5: Épica 30, Legendaria 45, Mítica 20, Divina 4.5, Celestial 0.5
- Z6: Legendaria 30, Mítica 45, Divina 20, Celestial 4.4, Primordial 0.6
- Rarezas "imposibles" (zona 3+): Secreta 1/100K, Godlike 1/10M, Omnipotente 1/1B, Infinita 1/100T, ??? 1/1Qa (escalado por zona/6 y por suerte).
- La **suerte** multiplica el peso de las dos rarezas más altas de la zona y las imposibles.
- Las probabilidades se muestran en el juego (Índice → Probabilidades), como exige Roblox.

### Avisos
- Mítica o más: aviso en el chat del servidor (color de la rareza).
- Secreta o más: además cartel grande en pantalla y haz de luz en el mapa.
- Godlike o más: aviso en **todos los servidores** (MessagingService).

---

## 7. Dioses (64) — solo mitologías antiguas (sin religiones vivas)

- **Común:** Pan, Eolo, Iris, Bastet, Sobek, Heimdall
- **Poco común:** Eos, Selene, Bragi, Khonsu, Brigid, Xochiquétzal
- **Rara:** Hermes, Artemisa, Apolo, Horus, Freya, Tyr, Cernunnos, Tláloc, Shamash
- **Épica:** Atenea, Ares, Hefesto, Anubis, Isis, Loki, Quetzalcóatl, Morrígan, Ishtar
- **Legendaria:** Poseidón, Hades, Hera, Ra, Thor, Huitzilopochtli, Dagda, Enki
- **Mítica:** Odín, Osiris, Cronos, Tiamat, Tezcatlipoca
- **Divina:** Hiperión, Atlas, Set, Marduk, Danu
- **Celestial:** Urano, Nut, Ymir
- **Primordial:** Gaia, Érebo, Nun
- **Secreta:** Zeus, Nyx (solo en sobres del amanecer), Prometeo
- **Godlike:** Caos, Fanes, Atum
- **Omnipotente:** Ananké, Ometéotl
- **Infinita:** Ouroboros
- **???:** dios misterioso (silueta negra con "?")

Cada dios tiene un **dato real** de su mitología (en español e inglés) que sale en su carta.

**Aspecto:** cada dios es un **avatar R15 de Roblox** (HumanoidDescription con colores de piel/ropa según mitología) con **accesorios** soldados hechos con piezas: cabezas de animal (Bastet gata, Anubis/Set chacal, Horus/Ra halcón, Sobek cocodrilo, Tiamat dragón), coronas, laureles, nemes egipcio, cascos (alados), plumas aztecas, cuernos, barbas, alas, escudos y objetos en la mano (rayo de Zeus, tridente de Poseidón, martillo de Thor/Hefesto, arco, lira, antorcha, guadaña, báculo con ankh, globo de Atlas...). Usan las **animaciones oficiales de Roblox** (idle 507766666, walk 507777826, run 507767714).

**Efectos de rareza en cada dios:** contorno (Highlight) del color de la rareza, anillo de luz en los pies, chispas que suben (textura de destello), aura de brillo desde Legendaria, **círculo de runas girando** bajo los pies desde Mítica, orbes girando desde Celestial, levitan desde Celestial.

Además hay **modelos 3D hechos en Blender** (Zeus, Thor, Anubis, Minotauro) subidos a la cuenta; se usan como plantillas alternativas.

---

## 8. Kilos

- Cada sobre (y el dios que sale) tiene un **peso aleatorio**: base 40–160 kg; 10 % "pesado" ×1.5–3; 1 % "gigante" ×3–6; 0.1 % "titánico" ×6–10 (máximo ~1.500 kg).
- Resultado aproximado: 6 % ≥ 200 kg, 0.4 % ≥ 500 kg.
- **Dinero** × (kg/100). **Tamaño** × (0.75 + kg/400), entre 0.75 y 2.6.
- El sobre también es más grande según sus kilos y muestra "245 KG" en su cara.

---

## 9. Parcela

- Nivel 1 a 25. Cada nivel = **1 dios más** en la parcela (pedestales = 2 + nivel; +5 con pase).
- Coste: `100 * 5^(nivel-2)`.
- Aspecto según nivel: madera cálida (1-2), arenisca (3-4), mármol (5-9), mármol con oro (10-14), dorado (15-19), celestial de cristal con halo de neón (20-24), palacio de neón (25).
- **Altares** para abrir sobres: 3 de inicio, hasta 8 comprando (`500 * 30^(n-4)`), +2 con pase. Cola de hasta 10 sobres esperando.
- Los dioses pasean libremente por la parcela (animación en el cliente, con animaciones oficiales), cartel encima con **nombre, kilos y "$X/s"** en verde, y textos **"+$X"** saltando cada pocos segundos.
- Dinero sin conexión: al volver, **50 % de los ingresos** del tiempo fuera (máximo 8 h), con un popup **¡RECLAMAR!**.

---

## 10. Velocidad y cinta

- Ganancia por segundo en la cinta: `5 * 3^(nivel-1)` × combo × multiplicadores (× 3 de noche).
- Coste del nivel de cinta: `20 * 4^(nivel-2)`, máximo nivel 40.
- **Velocidad real del personaje** (WalkSpeed) = `16 + 9*log10(1+velocidad)`, máximo 110 (Roblox no soporta velocidades absurdas reales; el número es la estadística, el movimiento crece poco a poco).
- Combo: cada acierto +0.5 (máx x5); se pierde tras 2.2 s sin acertar; mínimo 0.3 s entre toques.
- Efectos: el personaje **corre en la cinta** (animación), la **banda se mueve**, estela blanca al correr rápido, el campo de visión se abre con la velocidad.

---

## 11. Multiplicadores

- **Índice** (dioses distintos): 5 → +10 % dinero; 10 → +10 % velocidad; 15 → +25 % dinero; 20 → +25 % velocidad; 30 → +50 % dinero; 40 → +50 % velocidad; 50 → ×2 dinero; 64 (todos) → ×2 dinero y ×2 velocidad.
- **Mitología completa** → arma mejor + bonus de velocidad y dinero:
  - Celta: Bastón druida (empuje ×1.5, +10 %)
  - Egipcia: Cetro de Anubis (×2, +15 %)
  - Azteca: Macuahuitl (×2.5, +20 %)
  - Babilónica: Maza de Marduk (×3, +25 %)
  - Griega: Tridente de Poseidón (×4, +35 %)
  - Nórdica: Mjölnir (×6, +50 %, rayo al golpear)
- **Entrenadores (héroes)**: Hércules (+10 %, 1K), Aquiles (+15 %, 50K), Perseo (+20 %, 2.5M), Teseo (+25 %, 100M). Se fusionan 2 iguales para subir de nivel: Normal ×1, Dorado ×2.5, Divino ×6, Mutado ×15. Cuentan los 3 mejores.
- **Auras** (una equipada): Rayo de Zeus (+25 % vel., 10K), Fuego del Inframundo (+25 % dinero, 250K), Sol de Ra (+60 % vel., 20M), Escarcha nórdica (+60 % dinero, 1B), Marea de Poseidón (+50 % ambos, 50B), Aura Divina (+150 % ambos, 5T).
- Pases y productos de Robux (sección 15).

---

## 12. Día y noche

- Día: 5 minutos. Aviso 10 s antes de la noche.
- Noche: 15 segundos. El pasillo se cierra (te devuelve a tu parcela), los sobres que llevabas se pierden. **Cinta ×3** y **sobres se abren ×10 más rápido**.
- Amanecer: se renuevan todos los sobres (6 por zona, 1 por zona es "sobre del amanecer" con ×3 de suerte; Nyx solo sale en estos). Aviso en el chat de los sobres Míticos o mejores con su zona.

---

## 13. Combate

- Todos llevan un **bate** (Tool). Solo se puede golpear **dentro del pasillo** (zona de combate); parcelas y plaza son zona segura.
- Se puede golpear a cualquiera en el pasillo, lleve sobre o no. Si lleva sobre, lo suelta en el suelo (cualquiera puede cogerlo).
- Empuje: dirección × 70 × potencia del arma + impulso hacia arriba (lo aplica el cliente de la víctima).
- Espera de 2 s entre golpes, 1 s de invulnerabilidad tras recibir uno, jugadores nuevos protegidos sus primeros 10 minutos, escudo divino (Robux) 3 minutos.
- Botón / tecla **"Soltar sobre"** para tirarlo tú mismo.

---

## 14. Rankings y títulos

- Rankings globales (Top 50, se actualizan cada minuto) de **velocidad**, **dinero total** y **tiempo jugado**, en paneles de la plaza. Las cifras enormes se guardan en escala logarítmica en el OrderedDataStore.
- Aviso cuando un jugador entra en el Top 10.
- Leaderstats del servidor en tiempo real (⚡, 💰, ⏱️).
- Encima de cada jugador: **título** según su mejor velocidad (Mortal, Corredor, Atleta, Héroe, Semidiós, Titán, Dios, Dios Supremo, Primordial, Infinito) y su **$/s**.

---

## 15. Robux (creados y conectados)

**Pases (una vez, para siempre):**

| Pase | Precio | ID |
|---|---|---|
| Velocidad x2 | 199 | 2092574951 |
| Dinero x2 | 149 | 2092863003 |
| Cinta automática (ganas velocidad aunque no estés en la cinta) | 249 | 2093738959 |
| Suerte x2 | 299 | 2093762893 |
| +5 pedestales y +2 altares | 99 | 2093564933 |
| VIP (+10 % de todo) | 349 | 2094332929 |

**Productos (consumibles):**

| Producto | Precio | ID |
|---|---|---|
| Salvar el sobre (cuando te pilla el guardián) | 25 | 3732903293 |
| Velocidad x3 (15 min) | 49 | 3732903313 |
| Noche para el servidor | 99 | 3732903322 |
| Suerte x3 para el servidor (10 min) | 149 | 3732903331 |
| Dinero: 10 min de ingresos | 49 | 3732903343 |
| Dinero: 2 h de ingresos | 199 | 3732903353 |
| Abrir ya (Común–Épica) | 19 | 3732903365 |
| Abrir ya (Legendaria–Celestial) | 79 | 3732903375 |
| Abrir ya (Primordial+) | 299 | 3732903384 |
| Mejora de parcela instantánea | 79 | 3732903393 |
| Escudo divino (3 min) | 29 | 3732903400 |

Los productos se procesan en `Shop.luau` con `MarketplaceService.ProcessReceipt`.

---

## 16. Interfaz (cliente)

- Estilo de simulador: texto **cursiva gruesa con borde negro** (Gotham Heavy Italic), degradados, tres tipografías (Luckiest Guy para títulos, Fredoka One para botones, Gotham para textos).
- **Abajo a la izquierda:** ⚡ velocidad (×multiplicador), **$dinero +$/s** en verde, multiplicadores de dinero y suerte.
- **Izquierda:** botones anchos de colores: TIENDA (con etiqueta "NUEVO" si puedes comprar algo), ÍNDICE, ROBUX, AFK, AJUSTES. Iconos que flotan, botones que rebotan.
- **Abajo a la derecha:** "🌙 Noche en 4:32" / "☀️ Amanece en 0:12".
- **Arriba:** zona actual (zona segura / zona de combate) y sobre que llevas.
- **Persecución:** pantalla teñida de rojo latiendo, cartel "¡CORRE!", "Guardián a X bloques", botón "Soltar sobre".
- **Título grande al entrar en una zona** con "Velocidad recomendada".
- **Paneles con animación de pop:** Tienda (mejoras, entrenadores, auras), Índice (cartas de los 64 dioses en 3D con ViewportFrame, recompensas, mitologías/armas, probabilidades), Robux (pases y productos), Ajustes.
- **Apertura de sobre:** pantalla oscura, rayos girando del color de la rareza, el sobre tiembla cada vez más (más tiempo cuanto más rara), destello, explosión de partículas, tres ondas expansivas, temblor de cámara y carta con el dios en 3D girando (nombre con degradado, cinta de rareza, kilos, $/s, dato real, "¡NUEVO!").
- **Minijuego de la cinta:** barra con marcador, zona verde, botón ¡TOCA! (+COMBO / MISS).
- **Avisos:** mensajes de sistema en el chat (TextChatService) con el color de la rareza y carteles grandes.
- **Sonidos** sencillos incluidos en Roblox (clic, pop, golpe, recompensa).
- **Ajustes (se guardan):** efectos de sonido, partículas (para móviles lentos), temblor de cámara, auras de otros jugadores, tamaño de interfaz (pequeña/normal/grande).
- **Controles:**
  - Teclado: E tocar (combo), Q soltar sobre, B tienda, I índice, F AFK, G ajustes, X cerrar.
  - Mando PS5/Xbox: R2 o X tocar, L2 soltar, Y tienda, cruceta ↑ índice, ← AFK, → ajustes, B cerrar; navegación de menús con el mando.
- **AFK:** botón que te pone en la cinta entrenando; para evitar la expulsión de Roblox por inactividad (20 min), a los 17 min el juego te **reconecta** al mismo juego (TeleportService) y vuelves en modo AFK.

---

## 17. Efectos visuales

Texturas propias (generadas con Python/PIL, empaquetadas en un FBX, subidas como modelo y leídas sus TextureID):

| Textura | ID |
|---|---|
| Llama | rbxassetid://70450162736270 |
| Brillo | rbxassetid://80704845655271 |
| Anillo de energía | rbxassetid://80633486636219 |
| Círculo de runas | rbxassetid://75646621572336 |
| Humo | rbxassetid://72641413375480 |
| Destello de estrella | rbxassetid://109708405214367 |
| Chispa / estela | rbxassetid://95678528492429 |
| Suelo de studs | rbxassetid://131282324801126 |
| Madera | rbxassetid://132280466948067 |

Modelos 3D de Blender subidos: Zeus 92086522191115, Thor 114769630459171, Anubis 109549248325197, Minotauro 71616274173148 (cada uno con piezas Body, ArmL, ArmR, LegL, LegR y articulaciones para animarlos).

- Sobres: carta con degradado de la rareza, "?" y kilos; flotan girando; brillo, haz de luz para Secreta+; al cogerlos explosión de destellos y onda; mientras los llevas sueltan chispas.
- Guardianes: **avatares gigantes (~30 studs)** que corren con la animación oficial, con llamas, humo oscuro, luz roja, contorno rojo y círculo de runas de fuego en el suelo:
  - Minotauro (cabeza de toro, hacha)
  - Dullahan (sin cabeza, llama verde, guadaña, alas oscuras)
  - Esfinge (cabeza de león, nemes, báculo)
  - Jaguar guerrero (cabeza felina, plumas, espada)
  - Lamassu (corona alta, barba, alas, lanza)
  - Fenrir (cabeza de lobo)

---

## 18. Datos guardados (DataStore `StealAGod_v1`, clave `u_<UserId>`)

```
money, totalMoney, speed, bestSpeed, playtime,
treadmill (nivel), plot (nivel), altars (comprados),
altarPacks = { {r=rareza, rem=segundos restantes, dawn=bool, kg=número}, ... },
queue = { mismos campos },
gods = { [idDios] = cantidad }        (para el índice)
godList = { {id=, kg=}, ... }          (cada dios con su peso)
coaches = { ["heracles:1"] = cantidad }, auras = { [id] = true }, aura = id equipada,
weapon = "bat" | "druid" | ..., settings = { sfx, particles, shake, othersAuras, ui },
savedAt = os.time()
```
Guardado automático cada 2 minutos, al salir y al cerrar el servidor. Los sobres en altares siguen contando el tiempo mientras estás fuera.

Rankings: OrderedDataStores `LB_Speed_v1`, `LB_Money_v1`, `LB_Time_v1`.

---

## 19. Pruebas automáticas (resultado actual: todo OK)

`tools/test_full.luau` se ejecuta en un servidor real de Roblox (Open Cloud Luau Execution) y comprueba:
cargar módulos, red, avatares, modelos 3D, construir el mundo (6 parcelas, 6 zonas, 6 guardianes), iniciar sistemas, amanecer (36 sobres), construir los 64 dioses, estatuas en parcela, probabilidades (200.000 tiradas por zona), economía, avatares de los 64 dioses, animación, kilos, formato de números, guardianes y ciclo noche/amanecer.

Importante: en el servidor de pruebas los scripts del juego no arrancan solos; la prueba requiere los módulos y los inicia a mano.

---

## 20. Pendiente / ideas futuras

- Hacer pública la experiencia y subir icono y miniatura (solo se puede desde la web de Roblox, no por API).
- Poner "no a la venta" 6 pases antiguos de 2023 que tiene la experiencia.
- 6 zonas más (Inframundo, Atlántida, Forja, Ragnarök, Olimpo, El Vacío) en actualizaciones semanales.
- Mazmorras con boss cada 5 oleadas y sistema de "grados" (F a Σ ×777): descartados por ahora.
- Robar dioses de otras parcelas, reinicios (rebirths), música de fondo, retratos ilustrados de cada dios para las cartas, más modelos 3D propios.
- Promoción cruzada con la serie de vídeos "La civilización" del canal Aprende (@aprended / @aprendedconmigo).
