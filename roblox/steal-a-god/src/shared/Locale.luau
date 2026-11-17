-- Textos en inglés y español. Cada jugador lo ve en el idioma de su Roblox.
local Locale = {}

local T = {
	money = { es = "Dinero", en = "Money" },
	speed = { es = "Velocidad", en = "Speed" },
	time = { es = "Tiempo", en = "Time" },
	day = { es = "Día", en = "Day" },
	night = { es = "Noche", en = "Night" },
	index = { es = "Índice", en = "Index" },
	shop = { es = "Tienda", en = "Shop" },
	upgrades = { es = "Mejoras", en = "Upgrades" },
	robux = { es = "Robux", en = "Robux" },
	afk = { es = "AFK", en = "AFK" },
	afkOn = { es = "Modo AFK activado: entrenas solo en tu cinta", en = "AFK mode on: you train on your treadmill" },
	afkOff = { es = "Modo AFK desactivado", en = "AFK mode off" },
	close = { es = "Cerrar", en = "Close" },
	buy = { es = "Comprar", en = "Buy" },
	owned = { es = "Tuyo", en = "Owned" },
	equip = { es = "Equipar", en = "Equip" },
	equipped = { es = "Equipada", en = "Equipped" },
	fuse = { es = "Fusionar 2", en = "Fuse 2" },
	soon = { es = "Próximamente", en = "Coming soon" },
	max = { es = "MÁX.", en = "MAX" },
	tap = { es = "¡TOCA!", en = "TAP!" },
	combo = { es = "Combo", en = "Combo" },
	steal = { es = "Robar", en = "Steal" },
	open = { es = "Abrir", en = "Open" },
	treadmill = { es = "Cinta", en = "Treadmill" },
	plot = { es = "Parcela", en = "Plot" },
	altar = { es = "Altar", en = "Altar" },
	coaches = { es = "Entrenadores", en = "Coaches" },
	auras = { es = "Auras", en = "Auras" },
	passes = { es = "Pases", en = "Passes" },
	products = { es = "Compras", en = "Purchases" },
	level = { es = "Nivel", en = "Level" },
	perSec = { es = "/s", en = "/s" },
	pedestals = { es = "pedestales", en = "pedestals" },
	needSpeed = { es = "Necesitas %s de velocidad para entrar en %s", en = "You need %s speed to enter %s" },
	nightClosed = { es = "🌙 Es de noche: el pasillo está cerrado", en = "🌙 It's night: the corridor is closed" },
	nightSoon = { es = "🌙 Anochece en %d segundos… ¡vuelve a tu parcela!", en = "🌙 Night falls in %d seconds… head home!" },
	nightStart = { es = "🌙 ¡Es de noche! Velocidad x3 en la cinta y sobres x10 más rápidos", en = "🌙 Night! 3x treadmill speed and packs open 10x faster" },
	dawn = { es = "🌅 ¡Amanece! Los sobres se han renovado.", en = "🌅 Dawn! The packs have been refreshed." },
	packSpawned = { es = "Ha aparecido un sobre %s en %s (Zona %d)", en = "A %s pack appeared in %s (Zone %d)" },
	packSpawnedBig = { es = "⚡ ¡Un sobre %s ha aparecido en %s (Zona %d)!", en = "⚡ A %s pack appeared in %s (Zone %d)!" },
	packGlobal = { es = "🌍 ¡Un sobre %s ha aparecido en el servidor de %s!", en = "🌍 A %s pack appeared in %s's server!" },
	stoleBig = { es = "🏃 %s ha robado el sobre %s… ¡%s le persigue!", en = "🏃 %s stole the %s pack… %s is chasing!" },
	escaped = { es = "✅ %s ha escapado con el sobre %s", en = "✅ %s escaped with the %s pack" },
	caught = { es = "💀 %s ha atrapado a %s", en = "💀 %s caught %s" },
	batSteal = { es = "💥 %s le ha quitado el sobre %s a %s de un golpe", en = "💥 %s knocked the %s pack out of %s's hands" },
	gotGod = { es = "✨ %s ha conseguido a %s (%s)", en = "✨ %s got %s (%s)" },
	gotGodGlobal = { es = "🌍 ✨ %s ha conseguido a %s (%s) %s", en = "🌍 ✨ %s got %s (%s) %s" },
	top10 = { es = "🏆 ¡%s ha entrado en el Top 10 de %s!", en = "🏆 %s entered the Top 10 for %s!" },
	carrying = { es = "Llevas un sobre %s · ¡vuelve a tu parcela!", en = "Carrying a %s pack · get back to your plot!" },
	altarsFull = { es = "Altares llenos: el sobre espera en la cola", en = "Altars full: the pack waits in the queue" },
	queueFull = { es = "Tienes demasiados sobres esperando", en = "You have too many packs waiting" },
	notEnough = { es = "No tienes suficiente dinero", en = "Not enough money" },
	bought = { es = "¡Comprado!", en = "Purchased!" },
	newbie = { es = "Protegido (jugador nuevo)", en = "Protected (new player)" },
	combatZone = { es = "⚔️ ZONA DE COMBATE", en = "⚔️ COMBAT ZONE" },
	safeZone = { es = "🛡️ Zona segura", en = "🛡️ Safe zone" },
	indexTitle = { es = "Índice de dioses", en = "God Index" },
	indexProgress = { es = "%d / %d dioses", en = "%d / %d gods" },
	nextReward = { es = "Siguiente premio a los %d dioses: %s", en = "Next reward at %d gods: %s" },
	odds = { es = "Probabilidades", en = "Odds" },
	gotNew = { es = "¡NUEVO!", en = "NEW!" },
	weaponUnlocked = { es = "¡Has completado la mitología %s! Nueva arma: %s", en = "You completed the %s mythology! New weapon: %s" },
	shield = { es = "Escudo divino activo", en = "Divine Shield active" },
	savePackAsk = { es = "¡El guardián te ha alcanzado! ¿Salvar el sobre?", en = "The guardian caught you! Save the pack?" },
	leaderSpeed = { es = "⚡ VELOCIDAD", en = "⚡ SPEED" },
	leaderMoney = { es = "💰 DINERO", en = "💰 MONEY" },
	leaderTime = { es = "⏱️ TIEMPO JUGADO", en = "⏱️ TIME PLAYED" },
	zone = { es = "Zona", en = "Zone" },
	requires = { es = "Requiere", en = "Requires" },
	queue = { es = "En cola", en = "Queued" },
	ready = { es = "¡LISTO!", en = "READY!" },
	income = { es = "Ingresos", en = "Income" },
	serverLuck = { es = "🍀 ¡%s ha activado Suerte x3 para todo el servidor durante 10 minutos!", en = "🍀 %s activated 3x Luck for the whole server for 10 minutes!" },
	nightBought = { es = "🌙 ¡%s ha comprado la noche para todo el servidor!", en = "🌙 %s bought the night for the whole server!" },
	endSign = { es = "🔒 MÁS ZONAS PRÓXIMAMENTE", en = "🔒 MORE ZONES COMING SOON" },
	chasing = { es = "¡TE PERSIGUE!", en = "CHASING!" },
	moreZones = { es = "Próxima actualización: Inframundo, Atlántida, Olimpo…", en = "Next update: Underworld, Atlantis, Olympus…" },
}

local isSpanish = nil

function Locale.setSpanish(v: boolean)
	isSpanish = v
end

function Locale.lang(): string
	return isSpanish and "es" or "en"
end

function Locale.t(key: string, ...): string
	local e = T[key]
	local s = e and (isSpanish and e.es or e.en) or key
	if select("#", ...) > 0 then
		local ok, res = pcall(string.format, s, ...)
		if ok then
			return res
		end
	end
	return s
end

-- Nombre de algo que tiene campos es/en (zonas, rarezas, armas...)
function Locale.name(item): string
	if not item then
		return "?"
	end
	return (isSpanish and item.es or item.en) or item.name or "?"
end

return Locale
