-- Lucky Obby Race — configuración compartida (servidor y cliente)
-- Carrera por rondas en un obby que cambia en cada ronda. Cada pocos segundos te toca un lucky block con un
-- objeto (piedra, arco, cáscara, soplido, escudo, cambiazo, congelación) para fastidiar a los demás o
-- protegerte. Los de detrás reciben objetos mejores (así nadie se rinde). Caer te devuelve a tu punto de control.
local Config = {}

Config.ROUND = {
	MIN_PLAYERS = 1, -- para empezar (con 1 se puede practicar solo)
	INTERMISSION = 15, -- espera en el vestíbulo entre carreras
	COUNTDOWN = 5, -- 5…1, ¡YA! (la cámara vuela por el recorrido mientras)
	RACE_TIME = 330, -- tiempo máximo de carrera
	AFTER_WINNER = 35, -- cuando llega el primero, los demás tienen estos segundos
	RESULTS = 6, -- pantalla de resultados
}

Config.COURSE = {
	START = Vector3.new(0, 60, 0), -- salida (la carrera avanza hacia +Z)
	SEGMENTS = 30, -- obby largo: 10 tramos de 3 (un bioma por tramo)
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

-- RAREZAS: cuanto mejor es el objeto, menos sale (y más a los que van detrás o tienen más suerte)
Config.RARITY = {
	{ es = "Común", en = "Common", color = Color3.fromRGB(200, 200, 210), weight = 100 },
	{ es = "Raro", en = "Rare", color = Color3.fromRGB(80, 170, 255), weight = 42 },
	{ es = "Épico", en = "Epic", color = Color3.fromRGB(190, 90, 255), weight = 16 },
	{ es = "Legendario", en = "Legendary", color = Color3.fromRGB(255, 190, 40), weight = 5 },
	{ es = "Mítico", en = "Mythic", color = Color3.fromRGB(255, 70, 110), weight = 1.4 },
}

Config.ITEMS = {
	-- comunes
	{ id = "rock", icon = "🥌", es = "Piedra", en = "Rock", rarity = 1, color = Color3.fromRGB(150, 140, 130) },
	{ id = "banana", icon = "🍌", es = "Cáscara", en = "Banana peel", rarity = 1, color = Color3.fromRGB(255, 220, 60) },
	{ id = "boost", icon = "🚀", es = "Turbo", en = "Turbo", rarity = 1, color = Color3.fromRGB(255, 140, 60) },
	{ id = "jump", icon = "🦘", es = "Supersalto", en = "Super jump", rarity = 1, color = Color3.fromRGB(120, 255, 140) },
	{ id = "glue", icon = "🍯", es = "Miel", en = "Honey trap", rarity = 1, color = Color3.fromRGB(255, 170, 40) },
	-- raros
	{ id = "shield", icon = "🛡️", es = "Escudo", en = "Shield", rarity = 2, color = Color3.fromRGB(90, 200, 255) },
	{ id = "bow", icon = "🏹", es = "Arco", en = "Bow", rarity = 2, color = Color3.fromRGB(190, 130, 70) },
	{ id = "gust", icon = "🌬️", es = "Soplido", en = "Gust", rarity = 2, color = Color3.fromRGB(200, 240, 255) },
	{ id = "bomb", icon = "💣", es = "Bomba", en = "Bomb", rarity = 2, color = Color3.fromRGB(90, 90, 110) },
	-- épicos
	{ id = "ghost", icon = "👻", es = "Fantasma", en = "Ghost", rarity = 3, color = Color3.fromRGB(220, 220, 255) },
	{ id = "lightning", icon = "⚡", es = "Rayo", en = "Lightning", rarity = 3, color = Color3.fromRGB(255, 240, 90) },
	{ id = "tornado", icon = "🌪️", es = "Tornado", en = "Tornado", rarity = 3, color = Color3.fromRGB(170, 200, 210) },
	-- legendarios
	{ id = "swap", icon = "🔀", es = "Cambiazo", en = "Swap", rarity = 4, color = Color3.fromRGB(200, 110, 255) },
	{ id = "freeze", icon = "❄️", es = "Congelación", en = "Freeze", rarity = 4, color = Color3.fromRGB(150, 230, 255) },
	{ id = "portal", icon = "🌀", es = "Portal", en = "Portal", rarity = 4, color = Color3.fromRGB(120, 90, 255) },
	-- míticos
	{ id = "meteor", icon = "☄️", es = "Lluvia de meteoritos", en = "Meteor shower", rarity = 5, color = Color3.fromRGB(255, 90, 40) },
	{ id = "crown", icon = "👑", es = "Corona dorada", en = "Golden crown", rarity = 5, color = Color3.fromRGB(255, 205, 50) },
}
Config.ITEM_BY_ID = {}
for _, it in ipairs(Config.ITEMS) do
	Config.ITEM_BY_ID[it.id] = it
	it.tier = it.rarity -- compatibilidad
end

-- Duraciones de los objetos nuevos
Config.BOOST_TIME, Config.BOOST_SPEED = 3, 36
Config.GHOST_TIME = 5
Config.CROWN_TIME = 8
Config.GLUE_TIME = 2.5

-- Peso de cada objeto según tu puesto: p = 0 si vas primero, 1 si vas último.
-- Base por rareza (100 · 42 · 16 · 5 · 1,4) y los de detrás multiplican las rarezas altas (el último, x4 los míticos).
function Config.itemWeight(item, p)
	local r = item.rarity or 1
	local base = Config.RARITY[r].weight
	return base * math.max(0.15, 1 + (r - 1) * (p - 0.35) * 1.2)
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

-- SUERTE (se compra en el vestíbulo con monedas): sube la probabilidad de objetos fuertes.
-- Cada nivel acerca tu "puesto" de reparto al de los últimos (que reciben Cambiazo y Congelación).
Config.LUCK = { MAX = 10, STEP = 0.08 }
function Config.luckCost(level) -- precio para pasar de level a level+1
	return math.floor(40 * 1.55 ^ level)
end
function Config.luckP(p, level)
	return math.min(1, p + (1 - p) * (level or 0) * Config.LUCK.STEP)
end

-- Monedas por puesto (y por terminar o participar)
Config.REWARDS = { 50, 30, 20 }
Config.REWARD_FINISH = 10
Config.REWARD_PLAY = 3

return Config
