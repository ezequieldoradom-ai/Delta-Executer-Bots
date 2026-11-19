-- Textos en español e inglés (según el idioma del jugador)
local Locale = {}

local isSpanish = true
function Locale.setSpanish(on)
	isSpanish = on
end
function Locale.detect(localeId)
	isSpanish = type(localeId) == "string" and localeId:sub(1, 2) == "es"
end
function Locale.lang()
	return isSpanish and "es" or "en"
end

local T = {
	waiting = { es = "Esperando jugadores…", en = "Waiting for players…" },
	nextRace = { es = "Siguiente carrera en %s", en = "Next race in %s" },
	breakTime = { es = "☕ Descanso · %s", en = "☕ Break · %s" },
	joinOpen = { es = "🏁 ¡Entra a la carrera! · %s", en = "🏁 Join the race! · %s" },
	joinedWait = { es = "✅ Apuntado · sale en %s", en = "✅ Joined · starts in %s" },
	raceOn = { es = "🏁 Carrera en curso", en = "🏁 Race in progress" },
	go = { es = "¡YA!", en = "GO!" },
	racing = { es = "⏱ %s · %sº de %s", en = "⏱ %s · #%s of %s" },
	finishedPos = { es = "🏁 ¡Has llegado %sº!", en = "🏁 You finished #%s!" },
	hurry = { es = "⚠️ ¡%s ha llegado! Quedan %s s", en = "⚠️ %s finished! %s s left" },
	results = { es = "🏆 Resultados", en = "🏆 Results" },
	winner = { es = "🏆 ¡%s gana la carrera!", en = "🏆 %s wins the race!" },
	coins = { es = "+%s 🪙", en = "+%s 🪙" },
	lucky = { es = "🎁 ¡LUCKY BLOCK!", en = "🎁 LUCKY BLOCK!" },
	use = { es = "Usar", en = "Use" },
	noItem = { es = "Sin objeto", en = "No item" },
	shieldOn = { es = "🛡️ ¡Escudo activo!", en = "🛡️ Shield up!" },
	blocked = { es = "🛡️ ¡Bloqueado!", en = "🛡️ Blocked!" },
	hitBy = { es = "💥 ¡%s te ha dado con %s!", en = "💥 %s hit you with %s!" },
	youHit = { es = "🎯 ¡Le has dado a %s!", en = "🎯 You hit %s!" },
	swapped = { es = "🔀 ¡Cambiazo con %s!", en = "🔀 Swapped with %s!" },
	frozen = { es = "❄️ ¡%s os ha congelado!", en = "❄️ %s froze everyone!" },
	slipped = { es = "🍌 ¡Has resbalado!", en = "🍌 You slipped!" },
	checkpoint = { es = "✅ Punto de control", en = "✅ Checkpoint" },
	lobby = { es = "Vestíbulo", en = "Lobby" },
	wins = { es = "Victorias", en = "Wins" },
	coinsName = { es = "Monedas", en = "Coins" },
}
Locale.T = T

function Locale.t(key, ...)
	local e = T[key]
	local s = e and (isSpanish and e.es or e.en) or key
	if select("#", ...) > 0 then
		local ok, out = pcall(string.format, s, ...)
		return ok and out or s
	end
	return s
end

function Locale.name(item)
	return item and (isSpanish and item.es or item.en) or "?"
end

return Locale
