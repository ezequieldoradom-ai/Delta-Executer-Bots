# Lucky Obby Race — bugs confirmados (revisión del 22-11-2026)

Revisión del código con Fable 5.2 y Opus 5.5 por separado; cada fallo lo comprobaron a ciegas dos verificadores (uno de cada modelo).
Todos los de esta lista los dieron por reales los dos verificadores. Rutas relativas a `roblox/lucky-obby/`. Las líneas son de la versión revisada (commit ab8ef00) y pueden haberse movido.

Nota: z1-c4 y z2-c9 son el mismo fallo (los bots no pasan por Race.finish). En z1-c3 solo es real la parte de la cuenta atrás. z2-c11 no se pudo comprobar en un cliente real.

## [ALTA] Un punto de control saltado impide llegar a la meta (z1-c1)
- Dónde: `src/server/Race.luau:167`
- Qué pasa: El servidor solo registra un punto de control si, en una muestra cada 0,2 s, la raíz está dentro de una franja de 6 studs de largo y de altura limitada (Course.checkpointAt), y exige orden estricto (cp == s.cp + 1). Con Turbo/Corona (más de 6 studs por muestra), empujones (70 studs/s), Supersalto (pasa por encima) o el salto desde el escalón final del tramo 'pads', la franja se cruza sin muestra dentro. Desde entonces no cuenta ningún punto posterior y la meta falla por s.cp >= lastCp (línea 175).
- Cómo se reproduce: Un jugador usa Supersalto o Turbo, recibe un empujón, o salta desde el escalón 'Step' justo antes de un punto de control. No sale el aviso; sigue hasta la meta y no pasa nada: se queda sin puesto ni monedas, y si cae reaparece varios tramos atrás.
- Verificación: Confirmado. Race.step muestrea cada 0,2 s (Race.luau:401-404) y Course.checkpointAt exige Z entre z0 y z1 (6 studs, Course.luau:189) y Y < cp.pos.Y+8 (Course.luau:300). El orden es estricto, cp == s.cp+1 (Race.luau:173), y la meta pide s.cp >= lastCp (Race.luau:181). Con Turbo (BOOST_SPEED 36, Config.luau:75) se recorren 7,2 studs por muestra y con Corona (32) 6,4: más que la franja. El Supersalto (Items.luau:352: 45 de avance y 95 hacia arriba) sube unos 23 studs, fuera de la ventana de Y, y avanza unos 45 en el aire. Saltar desde el 'Step' (y+6, Course.luau:106) deja la raíz por encima de y+11 justo sobre la franja. No hay aviso en Race, solo en Obbies. La única forma de recuperarlo es volver a pie o morir y reaparecer en el punto anterior.

## [ALTA] El buzón permite congelar el servidor con un mensaje gigante (z2-c7)
- Dónde: `src/server/Feedback.luau:96`
- Qué pasa: El texto se recorta con gsub("%s+$") antes de comprobar el tamaño y el cooldown. El patrón es cuadrático con rachas largas de espacios (40.000 espacios = 10,5 s) en una sola llamada en C que no cede. Como el cooldown se mira después, se puede repetir sin límite.
- Cómo se reproduce: Un tramposo hace Remotes.Feedback:InvokeServer("send", "idea", "x" .. string.rep(" ", 150000) .. "x") y el servidor se queda congelado minutos para todos, repetible a voluntad.
- Verificación: Confirmado en el código. En Feedback.luau:96 se hace gsub('%s+$') sobre el texto completo antes de comprobar el tamaño (100) y el cooldown (101). Con una racha de n espacios seguida de otro carácter, el gsub de Lua/Luau intenta casar en cada posición: max_expand recorre la racha y retrocede comprobando '$', lo que es O(n²) dentro de una sola llamada en C que no cede. Como el cooldown se mira después, se puede repetir. No pude medir tiempos (no hay intérprete de Luau aquí), pero el coste cuadrático es claro y un payload de decenas de KB por RemoteFunction es viable.

## [MEDIA] El Portal lleva al siguiente punto de control pero no lo registra (z1-c2)
- Dónde: `src/server/Items.luau:444`
- Qué pasa: USE.portal mueve el HRP a cp.pos y devuelve true sin llamar a G.Race.setCheckpoint. El registro depende de que Race.step, cada 0,2 s, pille al jugador dentro de la zona; a 20 studs/s sale de ella en 0,15 s. Si no se registra, por el orden estricto ningún punto posterior cuenta.
- Cómo se reproduce: Un jugador que va corriendo usa el Portal, aparece en el siguiente punto de control y sale de la zona antes de la siguiente muestra (aprox. 1 de cada 4 veces). No recibe aviso, al caer vuelve al punto anterior y no puede terminar la carrera.
- Verificación: Confirmado. USE.portal (Items.luau:434-447) mueve el HRP a cp.pos, en el centro de la franja de 6 studs, y no llama a G.Race.setCheckpoint, a diferencia de USE.swap (Items.luau:229-230). El registro depende de que Race.step (cada 0,2 s y sin sincronizar con el uso) pille al jugador dentro. Si sigue corriendo a 20 studs/s sale en unos 0,15 s, y además el cliente tiene la propiedad de red, lo que añade más retraso. Si se pierde, pasa como en z1-c1: ningún punto posterior cuenta y no puede llegar a la meta. El SelfTest (SelfTest.luau:545-547) solo comprueba la posición, no s.cp. Es menos frecuente porque el Portal es legendario.

## [MEDIA] Los bots que llegan no pasan por Race.finish: sin ganador ni acortamiento y puesto incoherente (z1-c4)
- Dónde: `src/server/Race.luau:117`
- Qué pasa: Los bots marcan sess.finished = true directamente (Bots.luau:630) sin pasar por Race.finish ni entrar en Race.finishers. El puesto del humano suma los bots llegados, así que nadie obtiene place == 1: no hay aviso de ganador ni se acorta la carrera (AFTER_WINNER). Además Race.rankOf ordena solo por finishers, así que el mensaje dice 'Has llegado 2º' pero los resultados le ponen '1.'.
- Cómo se reproduce: Carrera con humanos y bots; un bot llega primero. El humano A llega después: ve '¡Has llegado 2º!' sin victoria, pero en resultados sale primero. Si otro humano está AFK, todos esperan los 330 s completos.
- Verificación: Confirmado. Bots.luau:629-633 pone sess.finished = true sin llamar a Race.finish ni meter al bot en Race.finishers. En Race.finish el puesto suma los bots llegados (Race.luau:110-115), así que si un bot llega primero ningún humano tiene place == 1: no se lanza 'winner' ni se acorta la carrera con AFTER_WINNER (Race.luau:123-126). El bucle sigue mientras racerCount() > 0 (Race.luau:279), así que un humano AFK alarga la carrera hasta los 330 s. Además Race.rankOf da prioridad a los que están en finishers (Race.luau:42-46), así que al humano le pone por delante del bot: el mensaje dice '2º' y los resultados le ponen '1.'.

## [MEDIA] Guardado con SetAsync sin reintento: un fallo se da por hecho y se pierden datos (z1-c5)
- Dónde: `src/server/Data.luau:90`
- Qué pasa: Data.save marca savedAt = ahora y dirty = false antes de SetAsync y no reintenta si falla; el bucle no lo vuelve a intentar hasta 120 s. Data.release y BindToClose hacen un único intento e ignoran el resultado, y release borra el perfil de memoria. Además se usa SetAsync a ciegas, sin UpdateAsync ni bloqueo de sesión, así que otro servidor puede leer datos viejos y pisar los nuevos.
- Cómo se reproduce: Un jugador gana monedas o compra suerte y sale; el SetAsync de salida falla por un error transitorio (o queda encolado y entra enseguida en otro servidor que lee la copia antigua). Pierde todo lo conseguido desde el último guardado correcto.
- Verificación: Confirmado. Data.save pone savedAt = ahora y dirty = false antes de SetAsync, y el resultado del pcall solo se devuelve (Data.luau:96-101). Nadie lo comprueba: el bucle no vuelve a intentarlo hasta pasados 120 s salvo que haya otro cambio (Data.luau:179). Data.release hace un solo intento y borra el perfil (Data.luau:130-133), igual que BindToClose (Data.luau:189-191). Se usa SetAsync a ciegas, sin UpdateAsync ni bloqueo de sesión, así que si el jugador entra rápido en otro servidor puede leer la copia vieja y pisar la nueva al guardar. Un fallo transitorio al salir pierde lo ganado desde el último guardado correcto.

## [MEDIA] Reiniciar el personaje en la cuenta atrás permite salir antes que los demás (z1-c6)
- Dónde: `src/server/Race.luau:354`
- Qué pasa: En la cuenta atrás los inscritos tienen WalkSpeed 0 y JumpHeight 0, pero el manejador de CharacterAdded trata 'countdown' como 'racing': recoloca en la salida y pone hum.WalkSpeed = Race.WALK (20) con salto normal. Con RespawnTime 1,5 s cualquiera puede reiniciar y correr durante el resto de la cuenta atrás.
- Cómo se reproduce: Empieza la cuenta atrás de 5 s; un jugador pulsa Esc > Reiniciar personaje, reaparece a los ~1,5 s con velocidad 20 y corre unos 3 s (50-70 studs) antes del '¡YA!'.
- Verificación: Confirmado. RespawnTime es 1,5 s (default.project.json:28). En la cuenta atrás los inscritos tienen setWalk(p, 0, 0) (Race.luau:266), pero el manejador de CharacterAdded trata 'countdown' igual que 'racing': lleva al jugador al punto 0 (inicio de la salida) y pone hum.WalkSpeed = Race.WALK (Race.luau:364-367). El personaje nuevo trae JumpHeight por defecto. El cliente no bloquea los controles en la cuenta atrás: Extras.client solo lanza el vuelo de cámara. Quien se reinicia puede correr unos 3 s (unos 60 studs) antes del '¡YA!'.

## [MEDIA] Las barras giratorias casi no giran: el ángulo pierde precisión (z1-c7)
- Dónde: `src/client/init.client.luau:430`
- Qué pasa: El giro usa CFrame.Angles(0, T * it.speed, 0) con T = workspace:GetServerTimeNow() (~1,8e9). El ángulo (~3e9-4,7e9 rad) en float32 tiene resolución de 256-512 rad, así que solo cambia cada 100-200 s, con saltos bruscos. Arreglo: reducir el ángulo antes, p. ej. (T * speed) % (2*math.pi).
- Cómo se reproduce: Carrera con tramo 'spinners': las barras de lava parecen quietas y de vez en cuando saltan de golpe unos 268°, pudiendo matar sin aviso a quien está al lado.
- Verificación: Confirmado en el código; la parte del motor es casi segura. init.client.luau:427 y 451 usan CFrame.Angles(0, T * it.speed, 0) con T = workspace:GetServerTimeNow(), un tiempo Unix de unos 1,79e9, y una velocidad de 1,6 a 2,6 (Course.luau:85): el ángulo queda entre 2,9e9 y 4,7e9 rad, sin reducir. CFrame trabaja internamente en float32, cuya resolución a esa magnitud es de 256-512 rad. El ángulo solo cambia cada 100-300 s y salta 256 rad (unos 268° módulo 2π), que es lo que dice el informe. Los Move no fallan porque calculan math.sin en double. Arreglo: (T * speed) % (2*math.pi).

## [MEDIA] La corona destruida deja la colina rota (y bloqueada en "result") (z2-c1)
- Dónde: `src/server/KingHill.luau:147`
- Qué pasa: La corona es un único BillboardGui cacheado en `crown` y metido en la cabeza del líder. Si ese personaje se destruye (Bots.removeBot hace bot.Character:Destroy(), o el líder se va del juego), la corona se destruye con él y `crown` apunta a una instancia destruida. Cualquier `crown.Parent = ...` lanza "Parent property is locked". finish() llama a updateCrown() antes de broadcast() y del task.delay que vuelve a "idle", así que la fase se queda en "result" para siempre; la vigilancia avisa del error cada 0,2 s.
- Cómo se reproduce: Un bot va primero en la colina con la corona y balance() lo retira al entrar otro jugador. Desde entonces no hay corona, la consola se llena de errores y, al acabar la partida, la colina se queda en "result": Hill.join responde siempre "Partida en curso".
- Verificación: Confirmado. removeBot (Bots.luau:311-323) llama a pcall(Hill.leave) y luego a bot.Character:Destroy() sin mover la corona. La corona se destruye con la cabeza y `crown` sigue apuntando a ella (KingHill.luau:120-150). balance() retira bots de la colina sin mirar si están jugando (Bots.luau:942, TARGET pasa de 4 a 3 a 2). Cualquier asignación a Parent sobre una instancia destruida lanza 'Parent property is locked' (también `= nil`). finish() (KingHill.luau:297) llama a updateCrown antes de broadcast y del task.delay que vuelve a 'idle', así que la fase se queda en 'result'. refresh() solo hace broadcast en 'result' (319-323) y Hill.join rechaza en 'result' (184).

## [MEDIA] Se puede forzar el GUANTAZO SUPREMO mandando la posición del rojo (z2-c2)
- Dónde: `src/server/Slap.luau:548`
- Qué pasa: Slap.stop acepta la posición que manda el cliente si está a menos de 0,18 de la calculada por el servidor y usa exactamente ese valor. El cliente conoce el rojo (evento "bar", red = st.redPos), y 0,18 es unas 10 veces la franja del supremo (±0,019). Mandar stop con pos = rojo da dist = 0 y siempre supremo.
- Cómo se reproduce: Un tramposo espera a que la barra esté cerca del rojo y hace FireServer("stop", data.red): todos sus golpes son SUPREMO, gana todas las mesas (+25 monedas) y sube sin tope en el ranking de guantazos.
- Verificación: Confirmado. Slap.stop (Slap.luau:543-551) usa clientPos tal cual si está a menos de 0,18 de alguna posición calculada. El cliente recibe red = st.redPos en el evento 'bar' (502). Con un periodo de 0,6 s la barra pasa a menos de 0,18 del rojo en buena parte del ciclo, así que mandar stop(red) da dist=0 y st.supreme=true (557-559). Hace falta un exploit. Las monedas tienen tope (reward, 72-88), pero addSlapWin (340) no lo tiene.

## [MEDIA] Mesa bloqueada en "result" si el que pega se va tras una esquiva (z2-c3)
- Dónde: `src/server/Slap.luau:670`
- Qué pasa: En la rama de esquiva, resolve pone "result", espera 1,6 s y, si el que pegó ya no está, solo llama a refresh(st). Slap.leave no toca la fase si es "result" y refresh, con partida en curso y el sentado válido, solo hace broadcast. La fase se queda en "result": Slap.request y el IDLE_PICK exigen "waiting". La rama de acierto sí hace setPhase("waiting").
- Cómo se reproduce: Mesa de 3: B esquiva el guantazo de A, y A pulsa SALIR, se desconecta o balance() lo retira (si es bot) en menos de 1,6 s. La mesa queda sin botón de pegar ni turno automático hasta que alguien se vaya.
- Verificación: Confirmado. En la rama de esquiva (Slap.luau:654-672): setPhase('result'), wait(1,6) y, si el que pegó ya no está, solo refresh(st). Slap.leave solo cambia la fase si es 'charging'/'windup' (447) y no cambia st.round. Con 2 o más que quedan, match=true y el sentado válido, refresh solo hace broadcast (422-423). La fase se queda en 'result', y tanto Slap.request (1005) como IDLE_PICK (980) exigen 'waiting'. removeBot también llama a Slap.leave (Bots.luau:318).

## [MEDIA] Reiniciar el personaje recupera toda la vida en plena partida de guantazos (z2-c4)
- Dónde: `src/server/Slap.luau:942`
- Qué pasa: Morir por Reiniciar no cuenta como eliminación: el CharacterAdded solo recoloca (hold) o vuelve a sentar (seatPlayer) al jugador con el personaje nuevo a 100 de vida. El botón de reinicio no está desactivado, y seatPlayer no vuelve a apagar el script Health, así que el sentado que reaparece también regenera vida.
- Cómo se reproduce: Con 15-20 de vida, el jugador pulsa Esc y Reiniciar; reaparece en su sitio con 100 de vida y sigue en la partida. Repitiéndolo solo se le puede eliminar con un SUPREMO.
- Verificación: Confirmado. No hay ResetButtonCallback ni CharacterAutoLoads ni Died en Slap (grep vacío). El CharacterAdded (Slap.luau:935-952) solo llama a seatPlayer/hold con el personaje nuevo, que nace a MaxHealth, y no lo elimina de la partida (stationOf se mantiene). seatPlayer (260-275) no llama a setRegen(false), así que el sentado que reaparece regenera vida. Solo un SUPREMO o un golpe recibido mientras está muerto lo eliminan.

## [MEDIA] Cuenta atrás fantasma al empezar la partida: los bots no pegan en 15 s (z2-c8)
- Dónde: `src/server/Slap.luau:380`
- Qué pasa: Al acabar la cuenta atrás se pone st.countdown = nil y se llama a refresh(); como st.match aún es false, refresh() crea otra cuenta atrás que hace broadcast cada segundo durante 15 s con la partida ya en marcha. Cada broadcast cambia bot.station y anula las peticiones de pegar de los bots (retraso mínimo 1,2 s). Al final vuelve a llamar a refresh() en mitad de la partida y deja st.startNow = true.
- Cómo se reproduce: 1 jugador + 2 bots: al jugador le toca sentarse y nadie le pega durante 18-21 s en cada partida; en mesas solo de bots se quedan todos quietos unos 16 s.
- Verificación: Confirmado. Al acabar la cuenta atrás (Slap.luau:380-384) se pone countdown=nil y startNow=true y se llama a refresh. Como st.match aún es false y st.countdown es nil (365), se crea otra cuenta atrás (setPhase('starting') y una tarea que hace broadcast cada segundo) antes de que el bloque startNow (394-407) arranque la partida. Cada broadcast cambia bot.station por una tabla nueva (Bots.luau:769) y anula el request pendiente, cuyo retraso mínimo es de 1,2 s o 3 s (779-781). Al terminar, deja startNow=true y llama a refresh en mitad de la partida. Además, la siguiente partida empezará sin esperar la cuenta atrás.

## [MEDIA] Si un bot llega primero a la meta, la carrera no se acorta a 35 s (z2-c9)
- Dónde: `src/server/Bots.luau:632`
- Qué pasa: Race.finish cuenta como puesto a los bots que ya llegaron, así que el primer humano sale con puesto 2: no hay aviso de ganador, no se aplica AFTER_WINNER y recibe premio de segundo. La carrera sigue hasta que lleguen todos los humanos o pasen 330 s. La cabecera dice que los bots no cuentan en el puesto.
- Cómo se reproduce: Un bot llega primero; el jugador A llega segundo (30 monedas, sin victoria) y, como B va lento o está AFK, la carrera dura hasta 5,5 min en vez de 35 s.
- Verificación: Confirmado. El bot al llegar solo pone sess.finished=true (Bots.luau:629-633) y no llama a Race.finish, así que no hay anuncio de ganador ni se aplica AFTER_WINNER. Race.finish suma a los bots que ya llegaron (Race.luau:111-115), de modo que el primer humano es 2.º y no se ejecuta el bloque de place==1 (120-126). El bucle sigue mientras haya corredores sin terminar o hasta RACE_TIME=330 (278-280; Config.luau:13). Que los bots cuenten en el puesto contradice la cabecera de Bots.luau:5.

## [BAJA] Los tablones mundiales se pisan con ceros si los datos del jugador no cargaron (z1-c10)
- Dónde: `src/server/Hub.luau:127`
- Qué pasa: Si Data.load falla los tres intentos, el perfil queda con coins=0, wins=0 y loaded=false para no guardarlo. Pero refreshBoards sube a los OrderedDataStore (victorias, monedas, colina, guantazos) el valor de todos los perfiles sin mirar d.loaded.
- Cómo se reproduce: Un jugador con muchas victorias entra durante un fallo de DataStore; al refrescarse los tablones se escribe 0 para su UserId y desaparece del top mundial hasta otra sesión en la que cargue bien.
- Verificación: Confirmado. Si GetAsync falla tres veces, Data.load deja coins, wins, etc. a 0 y loaded = false (Data.luau:37-53). refreshBoards recorre G.Data.profiles sin mirar d.loaded y hace SetAsync en los OrderedDataStore de victorias, monedas, colina y guantazos aunque el valor sea 0; solo el de mejor tiempo (asc) salta los ceros (Hub.luau:125-131, tablones en 347-363). El jugador desaparece del top hasta otra sesión que cargue bien. Solo ocurre con fallos de DataStore.

## [BAJA] A partir del 13.º inscrito la parrilla cae fuera de la plataforma de salida (z1-c11)
- Dónde: `src/server/Race.luau:259`
- Qué pasa: La parrilla usa filas de 6 en z = -6 - fila*3,5; la tercera fila queda en z = -13, pero StartPad (22 studs centrada en z = 0) termina en z = -11. Esos jugadores aparecen en el aire con WalkSpeed 0.
- Cómo se reproduce: Con 13 o más inscritos, los de la tercera fila caen al vacío en la cuenta atrás; su cliente los recoloca amontonados en el centro de la salida y pierden el vuelo de cámara.
- Verificación: Confirmado. StartPad mide 22 studs y está centrada en START.Z (Course.luau:168), así que va de z = -11 a 11. La parrilla pone las filas en z = -6 - fila*3,5 (Race.luau:263-265): la tercera fila (inscritos 13 a 18) queda en z = -13, 2 studs fuera, con WalkSpeed 0, y cae. El cliente la devuelve a Checkpoint 0 = (0, y+3, 0) (init.client.luau:484-486 y 409-415), todos al mismo punto. Hacen falta 13 o más humanos inscritos. Pasa algo parecido con los bots a partir del 9.º (z = -15,5, Bots.luau:719).

## [BAJA] Al acabar la ronda se teletransporta/modifica a quien ya había salido de la carrera (z1-c3)
- Dónde: `src/server/Race.luau:297`
- Qué pasa: El bucle final de resultados (297-303) y el de la salida (267-269) recorren la lista original de inscritos sin mirar s.racing: cambian WalkSpeed/JumpHeight y teletransportan al vestíbulo también a quien abandonó con el botón (y puede estar en un minijuego) y a quien ya llegó a la meta.
- Cómo se reproduce: Un jugador pulsa 'Salir de la carrera' y se sienta en una mesa de '¿Quién ha sido?' (WalkSpeed 0). Al terminar la carrera aparece de golpe en el vestíbulo con velocidad 16 mientras la mesa le sigue contando. Si sale en la cuenta atrás, al dar la salida recibe WalkSpeed 20 donde esté.
- Verificación: Solo en parte. Lo que se describe del final de la ronda ya no pasa: el bucle de resultados comprueba wasOnCourse = s.racing and not s.finished antes de cambiar la velocidad y teletransportar (Race.luau:306-312), así que no toca a quien salió con el botón ni a quien ya llegó. Lo de la cuenta atrás sí es real: Race.quit permite salir en 'countdown' (Race.luau:145), pero al dar la salida se hace setWalk(p, Race.WALK, 7.2) a toda la lista sin mirar s.racing (Race.luau:273-275). Quien salió se queda con WalkSpeed 20 donde esté; LobbySpeed solo toca 16/24 (LobbySpeed.luau:40-44), así que tampoco se le corrige. Si en esos 5 s se sentó en una mesa (WalkSpeed 0), se le libera. Es poco probable y el impacto es bajo.

## [BAJA] La congelación se anuncia a todo el servidor, también a quien no corre (z1-c8)
- Dónde: `src/server/Items.luau:247`
- Qué pasa: USE.freeze solo congela a corredores no inmunes y no llegados, pero avisa con FireAllClients('frozen'). El cliente (init.client.luau:257-262 y RaceFx) solo descarta el evento si lo lanzó él mismo: aplica tinte azul, cartel 'os ha congelado' y temblor de cámara a cualquiera.
- Cómo se reproduce: Alguien usa Congelación en la carrera. Los jugadores del vestíbulo, de los minijuegos, los inmunes (Fantasma/Corona) y los ya llegados ven la pantalla azul, el cartel y el temblor aunque se mueven con normalidad.
- Verificación: Confirmado. USE.freeze solo congela a corredores no llegados y no inmunes (Items.luau:238), pero avisa con FireAllClients('frozen') (Items.luau:247). init.client.luau:258-263 y RaceFx.client.luau:147 solo descartan el evento si by == UserId propio: a todos los demás (vestíbulo, minijuegos, inmunes, ya llegados) les ponen el tinte azul, el cartel y el temblor. Es solo visual: el frozenUntil del cliente solo afecta al tinte (init.client.luau:461).

## [BAJA] La cáscara avisa de resbalón aunque el escudo bloquee el golpe (z1-c9)
- Dónde: `src/server/Items.luau:550`
- Qué pasa: Items.knock devuelve false si el escudo o la inmunidad bloquean y true si no; nunca nil. La comprobación '~= nil' siempre se cumple, así que siempre se envía 'slipped'.
- Cómo se reproduce: Un corredor con Escudo pisa una cáscara: no sale despedido y ve '¡Bloqueado!', pero a la vez recibe '¡Has resbalado!'.
- Verificación: Confirmado. Items.knock devuelve false si lo bloquea el escudo o la inmunidad (Items.luau:46-61) y, si no, item ~= nil, que es true para 'banana' (Items.luau:85). Nunca devuelve nil, así que la condición '~= nil' de Items.luau:550 siempre se cumple: siempre se envía 'slipped' y sale '¡Has resbalado!' junto a '¡Bloqueado!'. Hay que comparar con '== true' o '~= false', como hace USE.lightning (Items.luau:408).

## [BAJA] El buzón gasta los 2 minutos de espera aunque el mensaje no se guarde (z2-c10)
- Dónde: `src/server/Feedback.luau:104`
- Qué pasa: last[p] se pone antes de filtrar y guardar; si falla el filtro o UpdateAsync, el jugador queda bloqueado 2 minutos y la sugerencia se pierde. Causas probables: una sola clave "inbox" para todos los servidores y el recorte text:sub(1, 300) por bytes que puede partir una ñ o emoji y dejar UTF-8 inválido.
- Cómo se reproduce: Un mensaje de 300/300 con el corte en mitad de una "ñ" falla al enviarse y al reintentar sale "Espera un poco antes de mandar otro" durante 2 minutos.
- Verificación: Confirmado. last[p] se fija en Feedback.luau:104, antes de filter (105-108) y de add (109). Si el filtro devuelve nil o UpdateAsync falla, el cooldown de 120 s ya está gastado. El recorte por bytes ocurre en el servidor (100) y también en el cliente (Feedback.client.luau:139-141), así que puede partir caracteres multibyte. Que eso haga fallar el filtro es plausible pero no lo puedo verificar. Si falla UpdateAsync, la entrada queda solo en la memoria del servidor.

## [BAJA] El botón 📮 puede quedar debajo de la lista de jugadores de Roblox en PC (z2-c11)
- Dónde: `src/client/Feedback.client.luau:70`
- Qué pasa: Los botones del buzón están arriba a la derecha (UDim2.new(1, -60, 0, 66) y (1, -112, 0, 66)) con IgnoreGuiInset, justo donde Roblox dibuja la lista de jugadores, abierta por defecto en PC y por encima de las ScreenGui. Hay que comprobarlo en un cliente real.
- Cómo se reproduce: En PC a 1920x1080 con la lista abierta, el 📮 queda tapado y el clic se lo lleva la lista; solo se puede usar tras cerrarla con Tab.
- Verificación: Probable, no comprobado en un cliente real. El 📮 está en UDim2.new(1,-60,0,66), con 46x46 e IgnoreGuiInset=true (Feedback.client.luau:28 y 70), y el 📬 en (1,-112,0,66) (216). No se desactiva la PlayerList (no hay SetCoreGuiEnabled) y existen leaderstats (Data.luau:18-21), así que en PC la lista sale abierta arriba a la derecha, justo debajo de la barra superior, en el CoreGui (por encima de las ScreenGui). Ocupa justo esa zona y se lleva los clics.

## [BAJA] Al sentado le llega por red quién le ha pegado (z2-c5)
- Dónde: `src/server/Slap.luau:112`
- Qué pasa: info() oculta el slapper al sentado, pero animAll usa FireAllClients con who = UserId del que pega (poses windup/coil/spin), y el evento "hit" (también al esquivar) se manda a todos los que están cerca, incluido el sentado, con slapper = UserId. Ambos llegan antes de que tenga que adivinar.
- Cómo se reproduce: Un sentado con un remote spy lee d.slapper del "hit" o el who del "anim" y responde "guess" con ese id: acierta siempre, cobra 5 monedas y nunca se queda sentado.
- Verificación: Confirmado. info() oculta el slapper al sentado (289) y 'windup' no se le envía (581-584). Pero animAll hace FireAllClients con who = UserId del que pega (112; llamadas en 568-579). Además, 'hit' se envía a nearbyPlayers(headPos,110), que incluye al propio sentado, con slapper = slapper.UserId (658 y 677) antes de mandar 'guess' (750). Con un remote spy acierta siempre.

## [BAJA] Brazo del que pega congelado en pose de carga si el guantazo se corta (z2-c6)
- Dónde: `src/server/Slap.luau:447`
- Qué pasa: La pose "windup" solo la quita el "rest" que manda resolve(). Si el guantazo se corta durante el windup (el que pega sale y Slap.leave pasa a "waiting", o el sentado se va), resolve no se ejecuta y no llega "rest". En Slap.client las animaciones "arm" sin rest no se borran nunca y se aplican en cada Stepped.
- Cómo se reproduce: B para la barra y salta; mientras está en el aire, él o el sentado pulsa SALIR. En todos los clientes B se queda con el brazo en pose de carga paseando por el vestíbulo hasta que vuelva a pegar o reaparezca.
- Verificación: Confirmado. 'rest' solo se envía desde Slap.resolve (Slap.luau:638). Si el que pega sale durante 'windup', Slap.leave pone la fase en 'waiting' (448) y el task.delay de la esquiva aborta (591). Si se va el sentado, pickSeated cambia el round. En ambos casos resolve no se ejecuta. En el cliente, la animación 'arm' sin rest no se borra (Slap.client.luau:1048-1053; solo se quita con rest/neck/larm/waist) y su clave es el propio personaje, así que se queda aplicada hasta que reaparece o vuelve a pegar. Es un fallo visual.
