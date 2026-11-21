-- Lucky Obby Race — traducción al inglés de TODO lo que llega en español (carteles, avisos del servidor,
-- paneles, botones del mapa, bocadillos de los NPC). La usa AutoTranslate.client para los que no juegan en español.
-- Se traduce línea a línea: frase exacta → patrón (con nombres/números) → trozos sueltos.
local Translate = {}

local EXACT = {
	-- vestíbulo / paneles
	["🍀 SUERTE / LUCK"] = "🍀 LUCK",
	["🎁 CÓMO SE JUEGA"] = "🎁 HOW TO PLAY",
	["🏁 Llega el primero a la meta"] = "🏁 Be the first to reach the finish",
	["🎁 Cada 10 s recibes un lucky block (E / botón)"] = "🎁 Every 10 s you get a lucky block (E / button)",
	["⚪ Común  🔵 Raro  🟣 Épico  🟡 Legendario  🔴 Mítico"] = "⚪ Common  🔵 Rare  🟣 Epic  🟡 Legendary  🔴 Mythic",
	["17 objetos: cuanto mejor, más difícil que salga"] = "17 items: the better, the rarer",
	["🍀 Más suerte = objetos más fuertes"] = "🍀 More luck = stronger items",
	["💰 Monedas por puesto: 50 · 30 · 20"] = "💰 Coins per place: 50 · 30 · 20",
	["🏆 VICTORIAS"] = "🏆 WINS",
	["💰 MONEDAS"] = "💰 COINS",
	["⏱ RÉCORDS"] = "⏱ RECORDS",
	["🍀 ¿QUÉ ES LA SUERTE?"] = "🍀 WHAT IS LUCK?",
	["Con monedas subes tu nivel de suerte (máx. 10)"] = "Spend coins to level up your luck (max 10)",
	["Más suerte = más objetos raros, épicos,"] = "More luck = more rare, epic,",
	["legendarios y míticos en la carrera"] = "legendary and mythic items in the race",
	["Ve al trébol 🍀 y pulsa E (o tócalo)"] = "Go to the clover 🍀 and press E (or tap it)",
	["🖐️ REYES DEL GUANTAZO"] = "🖐️ SLAP KINGS",
	["👑 REYES DE LA COLINA"] = "👑 HILL KINGS",
	["Comprar +1 de suerte 🍀"] = "Buy +1 luck 🍀",
	["Más objetos raros en la carrera"] = "More rare items in the race",
	["Comprar / Equipar"] = "Buy / Equip",
	["Jugar / Salir"] = "Play / Leave",
	["Entrar a la carrera"] = "Join the race",
	-- plaza / carrera
	["🏁 PISA EL PORTAL PARA CORRER"] = "🏁 STEP ON THE PORTAL TO RACE",
	["🏁 ¡PISA EL PORTAL Y CORRE!"] = "🏁 STEP ON THE PORTAL AND RACE!",
	["☕ DESCANSO · ENSEGUIDA SE ABRE"] = "☕ BREAK · OPENING SOON",
	["🏁 CARRERA EN CURSO"] = "🏁 RACE IN PROGRESS",
	["🖐️ ¿QUIÉN HA SIDO? →"] = "🖐️ WHO SLAPPED ME? →",
	["👑 REY DE LA COLINA →"] = "👑 KING OF THE HILL →",
	["✅ ¡Apuntado a la carrera!"] = "✅ You joined the race!",
	["🚪 Has salido de la carrera"] = "🚪 You left the race",
	-- objetos y estelas
	["🚀 ¡TURBO!"] = "🚀 BOOST!",
	["👻 ¡Modo fantasma!"] = "👻 Ghost mode!",
	["🌀 ¡Portal!"] = "🌀 Portal!",
	["🍯 ¡Pegado en la miel!"] = "🍯 Stuck in honey!",
	["Estela quitada"] = "Trail removed",
	-- Rey de la colina
	["👑 REY DE LA COLINA 👑"] = "👑 KING OF THE HILL 👑",
	["👑 REY DE LA COLINA"] = "👑 KING OF THE HILL",
	["👑 IR AL REY DE LA COLINA"] = "👑 GO TO KING OF THE HILL",
	["👑 Rey de la colina (máx. 10)"] = "👑 King of the Hill (max 10)",
	["⏳ Partida en curso: espera a que termine para entrar"] = "⏳ Match in progress: wait for it to end to join",
	["👑 ¡A por la colina! Empuja con guantazos y no te caigas"] = "👑 Go for the hill! Push the others and don't fall off",
	["💥 ¡Te han echado de la arena!"] = "💥 You were knocked out of the arena!",
	["🚫 Arena llena (10/10)"] = "🚫 Arena full (10/10)",
	["👑 ¡Pulsa en el poste para entrar a la arena!"] = "👑 Use the post to enter the arena!",
	["💀 ¡Eliminado!"] = "💀 Eliminated!",
	["💥 ¡Te has caído de la arena!"] = "💥 You fell out of the arena!",
	-- ¿Quién ha sido?
	["🖐️ ¿QUIÉN HA SIDO? 🖐️"] = "🖐️ WHO SLAPPED ME? 🖐️",
	["🖐️ ¿QUIÉN HA SIDO?"] = "🖐️ WHO SLAPPED ME?",
	["¿Quién ha sido? (máx. 4)"] = "Who slapped me? (max 4)",
	["🖐️ ¡Empieza la partida! Si te quedas sin vida o te dan un SUPREMO, eliminado"] = "🖐️ Match started! Run out of health or take a SUPREME slap and you're out",
	["🖐️ ¡Empieza la partida! Al que le den un guantazo SUPREMO, eliminado"] = "🖐️ Match started! Take a SUPREME slap and you're out",
	["🚫 Mesa llena (4/4)"] = "🚫 Table full (4/4)",
	["💀 ¡ELIMINADO! Espera a la siguiente partida"] = "💀 ELIMINATED! Wait for the next match",
	["🖐️ ¡Te toca dar el guantazo!"] = "🖐️ Your turn to slap!",
	-- obbys normales
	["🏅 OBBYS COMPLETADOS"] = "🏅 OBBIES COMPLETED",
	["⚠️ Te falta un punto de control: vuelve atrás"] = "⚠️ You missed a checkpoint: go back",
	-- buzón
	["📬 BUZÓN (solo tú lo ves)"] = "📬 INBOX (only you can see it)",
	["Todavía no hay mensajes"] = "No messages yet",
	-- bocadillos de los NPC
	["hola!"] = "hi!", ["holaa 👋"] = "hii 👋", ["q tal?"] = "sup?", ["hola :D"] = "hello :D", ["holiii"] = "hiii", ["buenass"] = "heyy",
	["suerte!"] = "good luck!", ["vamooos"] = "let's gooo", ["a ganar 😎"] = "time to win 😎", ["vamos vamos"] = "go go go", ["esta la gano yo"] = "i'm winning this one",
	["casi 😭"] = "so close 😭", ["uff"] = "oof", ["jajaja me caí"] = "lol i fell", ["otra vez no"] = "not again", ["nooo la lava"] = "nooo the lava",
	["llegué!!"] = "made it!!", ["siii"] = "yesss",
	["toma!"] = "take that!", ["jajaja"] = "hahaha", ["pum"] = "bam", ["eso dolió"] = "that hurt",
	["fuiste tú 👀"] = "it was you 👀", ["seguro que fue este"] = "pretty sure it was this one", ["a ver..."] = "let's see...",
	["fuera!"] = "get out!", ["jaja adios"] = "lol bye", ["mi colina 😤"] = "my hill 😤", ["sal de ahí"] = "get off",
	["alguien carrera?"] = "anyone wanna race?", ["q aburrido"] = "so bored", ["me encanta este juego"] = "i love this game",
	["vamos a la colina?"] = "wanna go to the hill?", ["quien juega guantazos?"] = "who's up for slaps?",
}

local TRAILS = { ["Arcoíris"] = "Rainbow", ["Fuego"] = "Fire", ["Hielo"] = "Ice", ["Tóxica"] = "Toxic", ["Galaxia"] = "Galaxy", ["Oro"] = "Gold" }
local function trail(n)
	return TRAILS[n] or n
end
local TRAILS_UP = {}
for es, en in pairs(TRAILS) do
	TRAILS_UP[string.upper(es)] = string.upper(en)
	TRAILS_UP[es:upper():gsub("Í", "I"):gsub("Ó", "O")] = string.upper(en)
end

-- patrones (Lua) con nombres o números
local PATTERNS = {
	{ "^⏳ ¡La partida empieza en (%d+) s! Aún puede entrar gente$", "⏳ Match starts in %1 s! People can still join" },
	{ "^🔥 ¡Mesa llena! Empieza en (%d+) s$", "🔥 Table full! Starting in %1 s" },
	{ "^💨 ¡(.+) lo ha esquivado! Se sienta (.+)$", "💨 %1 dodged it! %2 takes the seat" },
	{ "^💀 ¡GUANTAZO SUPREMO de (.+)! (.+) eliminado$", "💀 SUPREME SLAP by %1! %2 eliminated" },
	{ "^🥊 ¡K%.O%.! (.+) se ha quedado sin vida%. ¡Eliminado!$", "🥊 K.O.! %1 ran out of health. Eliminated!" },
	{ "^🎯 ¡(.+) ha acertado! Fue (.+)%. ¡Se sienta!$", "🎯 %1 guessed right! It was %2. They take the seat!" },
	{ "^💥 (.+) eliminado$", "💥 %1 eliminated" },
	{ "^❌ (.+) ha fallado %(fue (.+)%)%. Sigue sentado$", "❌ %1 guessed wrong (it was %2). Still in the seat" },
	{ "^❌ (.+) ha fallado%. Sigue sentado$", "❌ %1 guessed wrong. Still in the seat" },
	{ "^☄️ ¡(.+) ha invocado una lluvia de meteoritos!$", "☄️ %1 summoned a meteor shower!" },
	{ "^👑 ¡(.+) lleva la CORONA DORADA!$", "👑 %1 has the GOLDEN CROWN!" },
	{ "^🍀 ¡Suerte nivel (%d+)! Objetos más fuertes$", "🍀 Luck level %1! Stronger items" },
	{ "^(%S+) OBBY FÁCIL$", "%1 EASY OBBY" },
	{ "^(%S+) OBBY MEDIO$", "%1 MEDIUM OBBY" },
	{ "^(%S+) OBBY DIFÍCIL$", "%1 HARD OBBY" },
}
-- con función (necesitan traducir el nombre de la estela)
local FN_PATTERNS = {
	{ "^(.-) ¡Estela (.+) equipada!$", function(icon, n)
		return icon .. " " .. trail(n) .. " trail equipped!"
	end },
	{ "^(.-) ¡Has comprado la estela (.+)!$", function(icon, n)
		return icon .. " You bought the " .. trail(n) .. " trail!"
	end },
	{ "^(.-) (%S+) · 💰(%d+)$", function(icon, n, price)
		return icon .. " " .. trail(n) .. " · 💰" .. price
	end },
	{ "^(%S+) (%S+)$", function(icon, n) -- "🌈 ARCOÍRIS" (cartel del puesto de estelas)
		local up = TRAILS_UP[n]
		return up and (icon .. " " .. up) or nil
	end },
}
-- trozos dentro de textos compuestos (rótulos con estado, etc.)
local PIECES = {
	{ "⚔️ PARTIDA EN CURSO", "⚔️ MATCH IN PROGRESS" },
	{ "⏳ ¡EMPIEZA YA! ENTRA", "⏳ STARTING! JOIN NOW" },
	{ "¡ENTRA A JUGAR!", "JOIN TO PLAY!" },
	{ " tramos · 💰", " stages · 💰" },
	{ "👑 REY DE LA COLINA 👑", "👑 KING OF THE HILL 👑" },
	{ "👑 REY DE LA COLINA", "👑 KING OF THE HILL" },
	{ "🖐️ ¿QUIÉN HA SIDO?", "🖐️ WHO SLAPPED ME?" },
}

local function plainReplace(s, a, b)
	local i = 1
	while true do
		local x, y = string.find(s, a, i, true)
		if not x then
			return s
		end
		s = string.sub(s, 1, x - 1) .. b .. string.sub(s, y + 1)
		i = x + #b
	end
end

local function line(s)
	local lead, body, trail2 = string.match(s, "^(%s*)(.-)(%s*)$")
	if body == "" then
		return s
	end
	local e = EXACT[body]
	if e then
		return lead .. e .. trail2
	end
	for _, p in ipairs(PATTERNS) do
		if string.find(body, p[1]) then
			return lead .. string.gsub(body, p[1], p[2]) .. trail2
		end
	end
	for _, p in ipairs(FN_PATTERNS) do
		local caps = { string.match(body, p[1]) }
		if #caps > 0 then
			local out = p[2](table.unpack(caps))
			if out then
				return lead .. out .. trail2
			end
		end
	end
	local out = body
	for _, p in ipairs(PIECES) do
		out = plainReplace(out, p[1], p[2])
	end
	return lead .. out .. trail2
end

function Translate.tr(s)
	if type(s) ~= "string" or s == "" then
		return s
	end
	if not string.find(s, "\n", 1, true) then
		return line(s)
	end
	local parts = {}
	for piece in string.gmatch(s .. "\n", "(.-)\n") do
		table.insert(parts, line(piece))
	end
	return table.concat(parts, "\n")
end

return Translate
