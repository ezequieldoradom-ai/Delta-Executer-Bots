-- Lucky Obby Race — configuración compartida (servidor y cliente)
-- Carrera por rondas en un obby que cambia en cada ronda. Cada pocos segundos te toca un lucky block con un
-- objeto (piedra, arco, cáscara, soplido, escudo, cambiazo, congelación) para fastidiar a los demás o
-- protegerte. Los de detrás reciben objetos mejores (así nadie se rinde). Caer te devuelve a tu punto de control.
local Config = {}

Config.ROUND = {
	MIN_PLAYERS = 1, -- para empezar (con 1 se puede practicar solo)
	INTERMISSION = 15, -- espera en el vestíbulo entre carreras
	COUNTDOWN = 3, -- 3, 2, 1, ¡YA!
	RACE_TIME = 180, -- tiempo máximo de carrera
	AFTER_WINNER = 25, -- cuando llega el primero, los demás tienen estos segundos
	RESULTS = 6, -- pantalla de resultados
}

Config.COURSE = {
	START = Vector3.new(0, 60, 0), -- salida (la carrera avanza hacia +Z)
	SEGMENTS = 16,
	SEG_LEN = 38,
	WIDTH = 18,
	CHECKPOINT_EVERY = 3, -- un punto de control cada 3 tramos
	FALL = 26, -- si caes más de esto por debajo del recorrido, vuelves a tu punto de control
	LOBBY = Vector3.new(0, 4, -90),
}

Config.LUCKY_EVERY = 9 -- segundos entre lucky blocks (si no llevas ya un objeto)
Config.ROLL_TIME = 1.1 -- la caja gira antes de enseñar el objeto
Config.KNOCK = 70 -- fuerza de empuje base
Config.SHIELD_TIME = 8
Config.FREEZE_TIME = 2
Config.SLIP_TIME = 1.2

-- Objetos: tier 1 = flojos (los dan más al primero), 2 = medios, 3 = fuertes (los dan más al último)
Config.ITEMS = {
	{ id = "rock", icon = "🪨", es = "Piedra", en = "Rock", tier = 1, color = Color3.fromRGB(150, 140, 130) },
	{ id = "banana", icon = "🍌", es = "Cáscara", en = "Banana peel", tier = 1, color = Color3.fromRGB(255, 220, 60) },
	{ id = "shield", icon = "🛡️", es = "Escudo", en = "Shield", tier = 1, color = Color3.fromRGB(90, 200, 255) },
	{ id = "bow", icon = "🏹", es = "Arco", en = "Bow", tier = 2, color = Color3.fromRGB(190, 130, 70) },
	{ id = "gust", icon = "🌬️", es = "Soplido", en = "Gust", tier = 2, color = Color3.fromRGB(200, 240, 255) },
	{ id = "swap", icon = "🔀", es = "Cambiazo", en = "Swap", tier = 3, color = Color3.fromRGB(200, 110, 255) },
	{ id = "freeze", icon = "❄️", es = "Congelación", en = "Freeze", tier = 3, color = Color3.fromRGB(150, 230, 255) },
}
Config.ITEM_BY_ID = {}
for _, it in ipairs(Config.ITEMS) do
	Config.ITEM_BY_ID[it.id] = it
end

-- Peso de cada objeto según tu puesto: p = 0 si vas primero, 1 si vas último
function Config.itemWeight(item, p)
	if item.tier == 1 then
		return 0.25 + 1.2 * (1 - p)
	elseif item.tier == 2 then
		return 0.7
	end
	return 0.05 + 1.3 * p * p
end

function Config.rollItem(p, rng)
	rng = rng or math.random
	local total = 0
	for _, it in ipairs(Config.ITEMS) do
		total += Config.itemWeight(it, p)
	end
	local x = rng() * total
	for _, it in ipairs(Config.ITEMS) do
		x -= Config.itemWeight(it, p)
		if x <= 0 then
			return it.id
		end
	end
	return Config.ITEMS[1].id
end

-- Monedas por puesto (y por terminar o participar)
Config.REWARDS = { 50, 30, 20 }
Config.REWARD_FINISH = 10
Config.REWARD_PLAY = 3

return Config
