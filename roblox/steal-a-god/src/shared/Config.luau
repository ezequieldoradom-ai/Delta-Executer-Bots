-- Steal a God ⚡ Roba un Dios — configuración del juego
-- Todo lo que se puede ajustar (zonas, rarezas, dioses, precios, Robux) está aquí.

local Config = {}

---------------------------------------------------------------------
-- CICLO DE DÍA Y NOCHE
---------------------------------------------------------------------
Config.DAY_SECONDS = 300 -- 5 minutos de día
Config.NIGHT_SECONDS = 20 -- 20 segundos de noche
Config.NIGHT_WARNING = 10 -- aviso antes de que anochezca
Config.NIGHT_TREADMILL_MULT = 3 -- la cinta da x3 de noche
Config.NIGHT_OPEN_MULT = 10 -- los sobres se abren x10 más rápido de noche

---------------------------------------------------------------------
-- RAREZAS (14)
---------------------------------------------------------------------
-- open = segundos para abrir el sobre · income = dinero por segundo del dios
Config.RARITIES = {
	{ id = 1, es = "Común", en = "Common", color = Color3.fromRGB(170, 170, 170), open = 10 },
	{ id = 2, es = "Poco común", en = "Uncommon", color = Color3.fromRGB(80, 200, 90), open = 30 },
	{ id = 3, es = "Rara", en = "Rare", color = Color3.fromRGB(60, 140, 255), open = 60 },
	{ id = 4, es = "Épica", en = "Epic", color = Color3.fromRGB(170, 80, 255), open = 180 },
	{ id = 5, es = "Legendaria", en = "Legendary", color = Color3.fromRGB(255, 200, 40), open = 600 },
	{ id = 6, es = "Mítica", en = "Mythic", color = Color3.fromRGB(255, 60, 70), open = 1800 },
	{ id = 7, es = "Divina", en = "Divine", color = Color3.fromRGB(255, 248, 225), open = 3600 },
	{ id = 8, es = "Celestial", en = "Celestial", color = Color3.fromRGB(90, 230, 255), open = 10800 },
	{ id = 9, es = "Primordial", en = "Primordial", color = Color3.fromRGB(255, 120, 200), open = 28800, rainbow = true },
	{ id = 10, es = "Secreta", en = "Secret", color = Color3.fromRGB(25, 25, 35), open = 86400, sparkle = true },
	{ id = 11, es = "Godlike", en = "Godlike", color = Color3.fromRGB(255, 170, 0), open = 172800, sparkle = true },
	{ id = 12, es = "Omnipotente", en = "Omnipotent", color = Color3.fromRGB(255, 255, 255), open = 345600, sparkle = true },
	{ id = 13, es = "Infinita", en = "Infinite", color = Color3.fromRGB(120, 90, 255), open = 604800, rainbow = true },
	{ id = 14, es = "???", en = "???", color = Color3.fromRGB(0, 0, 0), open = 604800, sparkle = true },
}
for _, r in ipairs(Config.RARITIES) do
	r.income = 4 * 6 ^ (r.id - 1)
end
Config.ANNOUNCE_CHAT_FROM = 6 -- Mítica o más: aviso en el chat del servidor
Config.ANNOUNCE_BIG_FROM = 10 -- Secreta o más: cartel + haz de luz
Config.ANNOUNCE_GLOBAL_FROM = 11 -- Godlike o más: aviso en todos los servidores

---------------------------------------------------------------------
-- MITOLOGÍAS (completar una entera da arma + multiplicador)
---------------------------------------------------------------------
Config.MYTHS = {
	celtic = { es = "Celta", en = "Celtic", weapon = "druid", bonus = 0.10 },
	egyptian = { es = "Egipcia", en = "Egyptian", weapon = "anubis", bonus = 0.15 },
	aztec = { es = "Azteca", en = "Aztec", weapon = "macuahuitl", bonus = 0.20 },
	babylonian = { es = "Babilónica", en = "Babylonian", weapon = "marduk", bonus = 0.25 },
	greek = { es = "Griega", en = "Greek", weapon = "trident", bonus = 0.35 },
	norse = { es = "Nórdica", en = "Norse", weapon = "mjolnir", bonus = 0.50 },
}

---------------------------------------------------------------------
-- ARMAS (empuje)
---------------------------------------------------------------------
Config.WEAPONS = {
	bat = { order = 0, es = "Bate de madera", en = "Wooden Bat", power = 1, color = Color3.fromRGB(150, 100, 55) },
	druid = { order = 1, es = "Bastón druida", en = "Druid Staff", power = 1.5, color = Color3.fromRGB(70, 150, 60) },
	anubis = { order = 2, es = "Cetro de Anubis", en = "Scepter of Anubis", power = 2, color = Color3.fromRGB(40, 40, 50) },
	macuahuitl = { order = 3, es = "Macuahuitl", en = "Macuahuitl", power = 2.5, color = Color3.fromRGB(30, 30, 30) },
	marduk = { order = 4, es = "Maza de Marduk", en = "Mace of Marduk", power = 3, color = Color3.fromRGB(200, 150, 50) },
	trident = { order = 5, es = "Tridente de Poseidón", en = "Trident of Poseidon", power = 4, color = Color3.fromRGB(60, 200, 220) },
	mjolnir = { order = 6, es = "Mjölnir", en = "Mjölnir", power = 6, color = Color3.fromRGB(160, 170, 190), lightning = true },
}
Config.HIT_RANGE = 9
Config.HIT_COOLDOWN = 2
Config.HIT_INVULN = 1
Config.LAUNCH_TIME = 1.3 -- segundos en el aire cuando un guardián te atrapa
Config.LAUNCH_DIST = { 55, 80 } -- studs que vuelas hacia atrás por el pasillo
Config.NEWBIE_PROTECTION = 600 -- segundos de juego protegidos

---------------------------------------------------------------------
-- DIOSES (64)
---------------------------------------------------------------------
Config.GODS = {
	-- 1 Común
	{ id = "pan", name = "Pan", r = 1, myth = "greek", factEs = "Dios de los pastores; su grito daba 'pánico'.", factEn = "God of shepherds; his shout gave us the word 'panic'." },
	{ id = "eolo", name = "Eolo", r = 1, myth = "greek", factEs = "Guardaba los vientos en un odre.", factEn = "Kept the winds inside a leather bag." },
	{ id = "iris", name = "Iris", r = 1, myth = "greek", factEs = "Mensajera de los dioses; el arcoíris era su camino.", factEn = "Messenger of the gods; the rainbow was her road." },
	{ id = "bastet", name = "Bastet", r = 1, myth = "egyptian", factEs = "Diosa gata protectora del hogar.", factEn = "Cat goddess who protected the home." },
	{ id = "sobek", name = "Sobek", r = 1, myth = "egyptian", factEs = "Dios cocodrilo del Nilo.", factEn = "Crocodile god of the Nile." },
	{ id = "heimdall", name = "Heimdall", r = 1, myth = "norse", factEs = "Vigila el puente arcoíris Bifröst.", factEn = "Guards the rainbow bridge Bifröst." },
	-- 2 Poco común
	{ id = "eos", name = "Eos", r = 2, myth = "greek", factEs = "Diosa del amanecer.", factEn = "Goddess of the dawn." },
	{ id = "selene", name = "Selene", r = 2, myth = "greek", factEs = "Conducía la Luna en su carro.", factEn = "Drove the Moon across the sky." },
	{ id = "bragi", name = "Bragi", r = 2, myth = "norse", factEs = "Dios de la poesía.", factEn = "God of poetry." },
	{ id = "khonsu", name = "Khonsu", r = 2, myth = "egyptian", factEs = "Dios de la Luna y el tiempo.", factEn = "God of the Moon and time." },
	{ id = "brigid", name = "Brigid", r = 2, myth = "celtic", factEs = "Diosa del fuego y la forja.", factEn = "Goddess of fire and the forge." },
	{ id = "xochiquetzal", name = "Xochiquétzal", r = 2, myth = "aztec", factEs = "Diosa de las flores.", factEn = "Goddess of flowers." },
	-- 3 Rara
	{ id = "hermes", name = "Hermes", r = 3, myth = "greek", factEs = "El dios más rápido, con sandalias aladas.", factEn = "The fastest god, with winged sandals." },
	{ id = "artemisa", name = "Artemisa", r = 3, myth = "greek", factEs = "Diosa de la caza.", factEn = "Goddess of the hunt." },
	{ id = "apolo", name = "Apolo", r = 3, myth = "greek", factEs = "Dios del sol y la música.", factEn = "God of the sun and music." },
	{ id = "horus", name = "Horus", r = 3, myth = "egyptian", factEs = "Dios halcón del cielo.", factEn = "Falcon god of the sky." },
	{ id = "freya", name = "Freya", r = 3, myth = "norse", factEs = "Viajaba en un carro tirado por gatos.", factEn = "Rode a chariot pulled by cats." },
	{ id = "tyr", name = "Tyr", r = 3, myth = "norse", factEs = "Perdió su mano para encadenar a Fenrir.", factEn = "Lost his hand chaining Fenrir." },
	{ id = "cernunnos", name = "Cernunnos", r = 3, myth = "celtic", factEs = "Dios astado de los bosques.", factEn = "Horned god of the forests." },
	{ id = "tlaloc", name = "Tláloc", r = 3, myth = "aztec", factEs = "Dios de la lluvia.", factEn = "God of rain." },
	{ id = "shamash", name = "Shamash", r = 3, myth = "babylonian", factEs = "Dios del sol y la justicia.", factEn = "God of the sun and justice." },
	-- 4 Épica
	{ id = "atenea", name = "Atenea", r = 4, myth = "greek", factEs = "Nació adulta y con armadura.", factEn = "Born fully grown and armored." },
	{ id = "ares", name = "Ares", r = 4, myth = "greek", factEs = "Dios de la guerra.", factEn = "God of war." },
	{ id = "hefesto", name = "Hefesto", r = 4, myth = "greek", factEs = "Forjaba las armas de los dioses.", factEn = "Forged the weapons of the gods." },
	{ id = "anubis", name = "Anubis", r = 4, myth = "egyptian", factEs = "Pesaba el corazón de los muertos.", factEn = "Weighed the hearts of the dead." },
	{ id = "isis", name = "Isis", r = 4, myth = "egyptian", factEs = "La gran diosa de la magia.", factEn = "The great goddess of magic." },
	{ id = "loki", name = "Loki", r = 4, myth = "norse", factEs = "El embaucador que cambiaba de forma.", factEn = "The shapeshifting trickster." },
	{ id = "quetzalcoatl", name = "Quetzalcóatl", r = 4, myth = "aztec", factEs = "La serpiente emplumada.", factEn = "The feathered serpent." },
	{ id = "morrigan", name = "Morrígan", r = 4, myth = "celtic", factEs = "Se convertía en cuervo en las batallas.", factEn = "Turned into a crow in battle." },
	{ id = "ishtar", name = "Ishtar", r = 4, myth = "babylonian", factEs = "Diosa del amor y la guerra.", factEn = "Goddess of love and war." },
	-- 5 Legendaria
	{ id = "poseidon", name = "Poseidón", r = 5, myth = "greek", factEs = "Su tridente provocaba terremotos.", factEn = "His trident caused earthquakes." },
	{ id = "hades", name = "Hades", r = 5, myth = "greek", factEs = "Rey del Inframundo.", factEn = "King of the Underworld." },
	{ id = "hera", name = "Hera", r = 5, myth = "greek", factEs = "Reina de los dioses.", factEn = "Queen of the gods." },
	{ id = "ra", name = "Ra", r = 5, myth = "egyptian", factEs = "Cruzaba el cielo en una barca solar.", factEn = "Sailed the sky in a solar boat." },
	{ id = "thor", name = "Thor", r = 5, myth = "norse", factEs = "Su martillo volvía siempre a su mano.", factEn = "His hammer always returned to his hand." },
	{ id = "huitzilopochtli", name = "Huitzilopochtli", r = 5, myth = "aztec", factEs = "Dios del sol y la guerra azteca.", factEn = "Aztec god of sun and war." },
	{ id = "dagda", name = "Dagda", r = 5, myth = "celtic", factEs = "Su caldero nunca se vaciaba.", factEn = "His cauldron was never empty." },
	{ id = "enki", name = "Enki", r = 5, myth = "babylonian", factEs = "Dios del agua y la sabiduría.", factEn = "God of water and wisdom." },
	-- 6 Mítica
	{ id = "odin", name = "Odín", r = 6, myth = "norse", factEs = "Dio un ojo a cambio de sabiduría.", factEn = "Gave an eye for wisdom." },
	{ id = "osiris", name = "Osiris", r = 6, myth = "egyptian", factEs = "Volvió de la muerte para reinar.", factEn = "Returned from death to rule." },
	{ id = "cronos", name = "Cronos", r = 6, myth = "greek", factEs = "El titán del tiempo.", factEn = "The titan of time." },
	{ id = "tiamat", name = "Tiamat", r = 6, myth = "babylonian", factEs = "La dragona del océano primordial.", factEn = "Dragon of the primordial sea." },
	{ id = "tezcatlipoca", name = "Tezcatlipoca", r = 6, myth = "aztec", factEs = "El espejo humeante de la noche.", factEn = "The smoking mirror of the night." },
	-- 7 Divina
	{ id = "hiperion", name = "Hiperión", r = 7, myth = "greek", factEs = "Titán de la luz.", factEn = "Titan of light." },
	{ id = "atlas", name = "Atlas", r = 7, myth = "greek", factEs = "Sostiene el cielo sobre sus hombros.", factEn = "Holds the sky on his shoulders." },
	{ id = "set", name = "Set", r = 7, myth = "egyptian", factEs = "Dios del caos y las tormentas.", factEn = "God of chaos and storms." },
	{ id = "marduk", name = "Marduk", r = 7, myth = "babylonian", factEs = "Venció a Tiamat y creó el mundo.", factEn = "Defeated Tiamat and made the world." },
	{ id = "danu", name = "Danu", r = 7, myth = "celtic", factEs = "La madre de los dioses celtas.", factEn = "Mother of the Celtic gods." },
	-- 8 Celestial
	{ id = "urano", name = "Urano", r = 8, myth = "greek", factEs = "El cielo en persona.", factEn = "The sky itself." },
	{ id = "nut", name = "Nut", r = 8, myth = "egyptian", factEs = "Su cuerpo era la bóveda estrellada.", factEn = "Her body was the starry sky." },
	{ id = "ymir", name = "Ymir", r = 8, myth = "norse", factEs = "Con su cuerpo se creó el mundo.", factEn = "The world was made from his body." },
	-- 9 Primordial
	{ id = "gaia", name = "Gaia", r = 9, myth = "greek", factEs = "La Tierra, madre de todo.", factEn = "The Earth, mother of all." },
	{ id = "erebo", name = "Érebo", r = 9, myth = "greek", factEs = "La oscuridad primordial.", factEn = "The primordial darkness." },
	{ id = "nun", name = "Nun", r = 9, myth = "egyptian", factEs = "Las aguas del caos original.", factEn = "The waters of original chaos." },
	-- 10 Secreta
	{ id = "zeus", name = "Zeus", r = 10, myth = "greek", factEs = "Rey del Olimpo y señor del rayo.", factEn = "King of Olympus, lord of lightning." },
	{ id = "nyx", name = "Nyx", r = 10, myth = "greek", factEs = "Diosa de la noche; hasta Zeus la temía.", factEn = "Goddess of night; even Zeus feared her.", dawnOnly = true },
	{ id = "prometeo", name = "Prometeo", r = 10, myth = "greek", factEs = "Robó el fuego a los dioses.", factEn = "Stole fire from the gods." },
	-- 11 Godlike
	{ id = "caos", name = "Caos", r = 11, myth = "greek", factEs = "Lo primero que existió.", factEn = "The first thing that ever existed." },
	{ id = "fanes", name = "Fanes", r = 11, myth = "greek", factEs = "Nació de un huevo cósmico.", factEn = "Hatched from a cosmic egg." },
	{ id = "atum", name = "Atum", r = 11, myth = "egyptian", factEs = "Se creó a sí mismo.", factEn = "Created himself." },
	-- 12 Omnipotente
	{ id = "ananke", name = "Ananké", r = 12, myth = "greek", factEs = "El destino; ni los dioses podían desobedecerla.", factEn = "Fate; not even gods could defy her." },
	{ id = "ometeotl", name = "Ometéotl", r = 12, myth = "aztec", factEs = "El dios dual creador de todo.", factEn = "The dual creator of everything." },
	-- 13 Infinita
	{ id = "ouroboros", name = "Ouroboros", r = 13, myth = "cosmic", factEs = "La serpiente que se muerde la cola: el infinito.", factEn = "The serpent eating its own tail: infinity." },
	-- 14 ???
	{ id = "unknown", name = "???", r = 14, myth = "cosmic", factEs = "Nadie sabe quién es… todavía.", factEn = "Nobody knows who this is… yet." },
}
Config.GOD_BY_ID = {}
Config.GODS_BY_RARITY = {}
for i, g in ipairs(Config.GODS) do
	g.index = i
	Config.GOD_BY_ID[g.id] = g
	Config.GODS_BY_RARITY[g.r] = Config.GODS_BY_RARITY[g.r] or {}
	table.insert(Config.GODS_BY_RARITY[g.r], g)
end

---------------------------------------------------------------------
-- ÍNDICE: recompensas por dioses distintos conseguidos
---------------------------------------------------------------------
Config.INDEX_REWARDS = {
	{ count = 5, money = 0.10 },
	{ count = 10, speed = 0.10 },
	{ count = 15, money = 0.25 },
	{ count = 20, speed = 0.25 },
	{ count = 30, money = 0.50 },
	{ count = 40, speed = 0.50 },
	{ count = 50, moneyMult = 2 },
	{ count = #Config.GODS, moneyMult = 2, speedMult = 2 },
}

---------------------------------------------------------------------
-- ZONAS (6 en la v1; las demás llegarán en actualizaciones)
---------------------------------------------------------------------
Config.ZONE_LENGTH = 200
Config.CORRIDOR_START = 110 -- Z donde empieza el pasillo
Config.CORRIDOR_HALF_WIDTH = 70
Config.PACKS_PER_ZONE = 6
Config.ZONES = {
	{
		es = "Arcadia griega", en = "Greek Arcadia", req = 0,
		ground = Color3.fromRGB(110, 205, 85), accent = Color3.fromRGB(250, 244, 228), tint = Color3.fromRGB(255, 238, 210), atmo = Color3.fromRGB(255, 220, 170),
		guardian = { es = "Minotauro", en = "Minotaur", kind = "minotaur", color = Color3.fromRGB(120, 70, 40), speed = 30 },
		weights = { [1] = 70, [2] = 25, [3] = 4.5, [4] = 0.5 },
	},
	{
		es = "Bosque celta", en = "Celtic Forest", req = 1e3,
		ground = Color3.fromRGB(40, 175, 115), accent = Color3.fromRGB(130, 95, 60), tint = Color3.fromRGB(215, 255, 225), atmo = Color3.fromRGB(150, 230, 180),
		guardian = { es = "Dullahan", en = "Dullahan", kind = "dullahan", color = Color3.fromRGB(30, 35, 45), speed = 2e4 },
		weights = { [1] = 30, [2] = 45, [3] = 20, [4] = 4.5, [5] = 0.5 },
	},
	{
		es = "Desierto de Egipto", en = "Egyptian Desert", req = 5e4,
		ground = Color3.fromRGB(250, 205, 95), accent = Color3.fromRGB(235, 170, 60), tint = Color3.fromRGB(255, 225, 180), atmo = Color3.fromRGB(255, 190, 120),
		guardian = { es = "Esfinge", en = "Sphinx", kind = "sphinx", color = Color3.fromRGB(205, 165, 95), speed = 1.5e5 },
		weights = { [2] = 30, [3] = 45, [4] = 20, [5] = 4.5, [6] = 0.5 },
	},
	{
		es = "Selva azteca", en = "Aztec Jungle", req = 2e6,
		ground = Color3.fromRGB(245, 140, 60), accent = Color3.fromRGB(60, 175, 145), tint = Color3.fromRGB(255, 220, 200), atmo = Color3.fromRGB(255, 160, 110),
		guardian = { es = "Jaguar guerrero", en = "Jaguar Warrior", kind = "jaguar", color = Color3.fromRGB(230, 160, 40), speed = 6e6 },
		weights = { [3] = 30, [4] = 45, [5] = 20, [6] = 4.5, [7] = 0.5 },
	},
	{
		es = "Babilonia", en = "Babylon", req = 1e8,
		ground = Color3.fromRGB(60, 115, 230), accent = Color3.fromRGB(245, 205, 80), tint = Color3.fromRGB(210, 220, 255), atmo = Color3.fromRGB(150, 170, 255),
		guardian = { es = "Lamassu", en = "Lamassu", kind = "lamassu", color = Color3.fromRGB(180, 170, 150), speed = 3e8 },
		weights = { [4] = 30, [5] = 45, [6] = 20, [7] = 4.5, [8] = 0.5 },
	},
	{
		es = "Fiordos nórdicos", en = "Norse Fjords", req = 5e9,
		ground = Color3.fromRGB(45, 35, 120), accent = Color3.fromRGB(150, 220, 255), tint = Color3.fromRGB(200, 190, 255), atmo = Color3.fromRGB(120, 90, 220), cosmic = true,
		guardian = { es = "Fenrir", en = "Fenrir", kind = "fenrir", color = Color3.fromRGB(70, 75, 90), speed = 1.5e10 },
		weights = { [5] = 30, [6] = 45, [7] = 20, [8] = 4.4, [9] = 0.6 },
	},
}
-- Probabilidad (1 entre N) de las rarezas "imposibles" en cualquier sobre de zona 3+
Config.ULTRA = {
	{ r = 10, oneIn = 1e5 },
	{ r = 11, oneIn = 1e7 },
	{ r = 12, oneIn = 1e9 },
	{ r = 13, oneIn = 1e14 },
	{ r = 14, oneIn = 1e15 },
}
Config.DAWN_LUCK = 3 -- los sobres del amanecer tienen x3 de suerte (1 por zona)

-- Probabilidades REALES de cada rareza en una zona con una suerte dada.
-- La tirada (Config.rollRarity) usa exactamente esta tabla, así lo que se muestra es lo que pasa.
function Config.odds(zoneIndex, luck)
	luck = luck or 1
	local zone = Config.ZONES[zoneIndex]
	local out = {}
	local rest = 1
	if zoneIndex >= 3 then
		-- las imposibles se comprueban de la más rara a la menos rara
		for k = #Config.ULTRA, 1, -1 do
			local u = Config.ULTRA[k]
			local p = math.min(1, (luck * zoneIndex / 6) / u.oneIn)
			out[u.r] = rest * p
			rest *= (1 - p)
		end
	end
	local maxR = 0
	for r in pairs(zone.weights) do
		maxR = math.max(maxR, r)
	end
	local total = 0
	local weights = {}
	for r, w in pairs(zone.weights) do
		-- la suerte potencia las dos rarezas más altas de la zona
		local ww = (r >= maxR - 1) and w * luck or w
		weights[r] = ww
		total += ww
	end
	for r, w in pairs(weights) do
		out[r] = (out[r] or 0) + rest * w / total
	end
	return out
end

function Config.rollRarity(zoneIndex, luck, rng)
	local odds = Config.odds(zoneIndex, luck)
	local x = (rng or math.random)()
	local last = 1
	for r = #Config.RARITIES, 1, -1 do
		local p = odds[r]
		if p and p > 0 then
			last = r
			x -= p
			if x <= 0 then
				return r
			end
		end
	end
	return last
end

---------------------------------------------------------------------
-- ASCENSO AL OLIMPO: obby gigante en una isla flotante (portal en la plaza).
-- 100 etapas en espiral alrededor del monte Olimpo, en 10 tramos de 10 (uno por mitología).
-- Puntos de control guardados; dentro todos andan igual (WALK) para que los saltos sean justos.
-- Premios: dinero al pasar cada tramo y el Sobre del Olimpo arriba (una vez al día cada uno).
---------------------------------------------------------------------
Config.OBBY = {
	STAGES = 100,
	PER_SECTION = 10,
	CENTER = Vector3.new(0, 900, -900), -- centro de la isla (lejos del mapa: Z < pasillo)
	RADIUS = 135, -- radio de la espiral
	STAGE_LEN = 46, -- largo de cada etapa (studs de recorrido)
	START_UP = 20, -- altura del primer punto de control sobre la isla
	CLIMB = 320, -- lo que sube en total
	WALK = 20, -- velocidad dentro del obby
	FALL = 18, -- si caes más de esto bajo tu punto de control, vuelves a él
	MIN_STAGE_TIME = 1.2, -- segundos mínimos entre puntos de control (anti-trampas)
	-- portal (lado izquierdo) y ranking (lado derecho, enfrente) en los laterales de la plaza, entre las
	-- puertas de las parcelas y sin pisar sus cintas, mirando al centro (en el centro tapaban los rankings)
	PORTAL = Vector3.new(-26, 0, 36),
	FACING = Vector3.new(1, 0, 0),
	BOARD = Vector3.new(26, 0, 22),
	BOARD_FACING = Vector3.new(-1, 0, 0),
	BOARD_STORE = "LB_Olympus_v1", -- OrderedDataStore: mejor tiempo (en segundos) de subir del 1 al 100 sin saltar etapas
	SECTION_MONEY_SECS = 150, -- dinero por tramo superado (segundos de tus ingresos), una vez al día
	TOP_MONEY_SECS = 1800, -- dinero al llegar a la cima
	TOP_RARITY_LUCK = 6, -- suerte para la rareza del Sobre del Olimpo
	TOP_PACK_LUCK = 60, -- y su suerte al abrirlo (× la suerte normal del sobre)
	TOP_MIN_RARITY = 4, -- tras 100 etapas, como poco Épica
	KILL_COLOR = Color3.fromRGB(255, 70, 40),
	SECTIONS = {
		{ es = "Grecia", en = "Greece", floor = Color3.fromRGB(236, 230, 218), mat = Enum.Material.Marble, accent = Color3.fromRGB(240, 196, 92) },
		{ es = "Egipto", en = "Egypt", floor = Color3.fromRGB(222, 186, 122), mat = Enum.Material.Sandstone, accent = Color3.fromRGB(50, 100, 210) },
		{ es = "Asgard", en = "Asgard", floor = Color3.fromRGB(185, 222, 255), mat = Enum.Material.Ice, accent = Color3.fromRGB(110, 220, 255) },
		{ es = "Selva azteca", en = "Aztec jungle", floor = Color3.fromRGB(70, 160, 110), mat = Enum.Material.Slate, accent = Color3.fromRGB(255, 200, 60) },
		{ es = "Bosque celta", en = "Celtic woods", floor = Color3.fromRGB(112, 132, 92), mat = Enum.Material.Cobblestone, accent = Color3.fromRGB(110, 220, 120) },
		{ es = "Babilonia", en = "Babylon", floor = Color3.fromRGB(46, 78, 170), mat = Enum.Material.Brick, accent = Color3.fromRGB(255, 205, 80) },
		{ es = "Inframundo", en = "Underworld", floor = Color3.fromRGB(58, 52, 58), mat = Enum.Material.Basalt, accent = Color3.fromRGB(150, 255, 120) },
		{ es = "Tormenta", en = "Storm", floor = Color3.fromRGB(228, 234, 246), mat = Enum.Material.SmoothPlastic, accent = Color3.fromRGB(110, 190, 255) },
		{ es = "Cosmos", en = "Cosmos", floor = Color3.fromRGB(52, 30, 90), mat = Enum.Material.Glass, accent = Color3.fromRGB(210, 120, 255) },
		{ es = "Olimpo", en = "Olympus", floor = Color3.fromRGB(255, 222, 140), mat = Enum.Material.Foil, accent = Color3.fromRGB(255, 255, 255) },
	},
}

---------------------------------------------------------------------
-- REGALOS GRATIS por tiempo jugado (en esta partida: se reinician al volver a entrar)
-- y BONUS DE AMIGOS (+10 % de dinero por cada amigo en el servidor, máximo 5)
---------------------------------------------------------------------
Config.GIFTS = {
	{ mins = 2, reward = { kind = "money", secs = 120 } },
	{ mins = 5, reward = { kind = "speed", mins = 3 } },
	{ mins = 10, reward = { kind = "money", secs = 300 } },
	{ mins = 15, reward = { kind = "luck", mins = 10 } },
	{ mins = 20, reward = { kind = "pack" } },
	{ mins = 30, reward = { kind = "money", secs = 900 } },
	{ mins = 45, reward = { kind = "luck", mins = 20 } },
	{ mins = 60, reward = { kind = "pack", luck = 3, big = true } },
}
Config.FRIEND_BONUS = 0.1
Config.FRIEND_MAX = 5

---------------------------------------------------------------------
-- SUERTE DE LOS SOBRES Y SUERTE PROPIA
-- Cada sobre trae su suerte (más en zonas lejanas y rarezas altas; x3 al amanecer).
-- Al abrirlo: suerte total T = suerte del sobre × tu nivel de suerte (cartel de la parcela) × pase,
-- premio y suerte del servidor. Con T, cada tirada puede subir el sobre UNA rareza (y seguir tirando):
-- probabilidad por paso = 1,8 % × log10(T) (máx. 42 %), como mucho +4 rarezas y nunca por encima de
-- Primordial (9); los sobres de rareza 10 o más no cambian.
---------------------------------------------------------------------
Config.PACK_LUCK = { zoneBase = { 12, 90, 700, 5000, 35000, 220000 }, perTier = 0.6, spread = { 0.55, 1.6 }, dawn = 3 }
Config.LUCK_MAX = 30
Config.UPGRADE = { per = 0.018, cap = 0.42, maxTiers = 4, maxRarity = 9, lockFrom = 10 }
function Config.zoneMinRarity(zoneIndex)
	local zone = Config.ZONES[zoneIndex]
	local minR = math.huge
	for r in pairs(zone and zone.weights or { [1] = 1 }) do
		minR = math.min(minR, r)
	end
	return minR
end
function Config.packLuck(zoneIndex, rarity, dawn, rng)
	local L = Config.PACK_LUCK
	local base = L.zoneBase[math.clamp(zoneIndex or 1, 1, #L.zoneBase)]
	local tier = math.max(0, (rarity or 1) - Config.zoneMinRarity(zoneIndex or 1))
	local spread = L.spread[1] + (rng or math.random)() * (L.spread[2] - L.spread[1])
	return math.max(1, math.floor(base * (1 + L.perTier * tier) * spread * (dawn and L.dawn or 1)))
end
function Config.luckMult(level) -- tu suerte propia según el nivel del cartel
	return 1.35 ^ ((level or 1) - 1)
end
function Config.luckCost(level) -- precio para llegar a ese nivel
	return math.floor(60 * 4.5 ^ (level - 2))
end
function Config.upgradeChance(T)
	local U = Config.UPGRADE
	return math.clamp(U.per * math.log10(math.max(1, T or 1)), 0, U.cap)
end
-- Rareza final al abrir un sobre de rareza r con suerte total T (rng para las pruebas)
function Config.rollUpgrade(r, T, rng)
	local U = Config.UPGRADE
	if r >= U.lockFrom then
		return r
	end
	local chance = Config.upgradeChance(T)
	local out = r
	for _ = 1, U.maxTiers do
		if out >= U.maxRarity or (rng or math.random)() >= chance then
			break
		end
		out += 1
	end
	return out
end

---------------------------------------------------------------------
-- VELOCIDAD, CINTA Y PARCELA
---------------------------------------------------------------------
Config.TREADMILL_MAX = 40
function Config.treadmillGain(level) -- velocidad por segundo
	return 5 * 3 ^ (level - 1)
end
function Config.treadmillCost(level) -- precio para llegar a ese nivel
	return 20 * 4 ^ (level - 2)
end
Config.COMBO_MAX = 5
-- Combo de la cinta: aparecen toques en la pantalla cada 2-3 s; cada acierto suma.
-- Multiplicador según los aciertos seguidos: 1 → x2, 5 → x3, 15 → x4, 30 → x5 (se mantiene hasta perderlo)
Config.TAP_TIERS = { { hits = 1, mult = 2 }, { hits = 5, mult = 3 }, { hits = 15, mult = 4 }, { hits = 30, mult = 5 } }
Config.TAP_EVERY = { 2, 3 } -- segundos entre toques (al azar)
Config.TAP_LIFE = 1.8 -- segundos que dura cada toque en pantalla
Config.TREADMILL_RELOCK = 1.5 -- segundos tras bajar de la cinta antes de que vuelva a bloquearte
function Config.tapMult(hits)
	local m = 1
	for _, t in ipairs(Config.TAP_TIERS) do
		if hits >= t.hits then
			m = t.mult
		end
	end
	return m
end

-- Velocidad al andar según tu ⚡ (petición del dueño: que se note mucho más):
-- 30 ⚡ ≈ 49 · 2e4 ≈ 111 · 6e6 ≈ 165 · 1.5e10 ≈ 239 (máx. 300). Con "modo lento" se anda a WALK_SLOW.
Config.WALK_SLOW = 16
function Config.walkSpeedFor(speed)
	return math.clamp(16 + 22 * math.log10(1 + speed), 16, 300)
end

Config.PLOT_MAX = 25
function Config.pedestalsFor(level)
	return 2 + level
end
function Config.plotCost(level)
	return 100 * 5 ^ (level - 2)
end
Config.ALTARS_BASE = 3
Config.ALTARS_MAX = 8
function Config.altarCost(n) -- precio del altar número n (4, 5, ...)
	return 500 * 30 ^ (n - 4)
end
Config.PACK_QUEUE_MAX = 10

---------------------------------------------------------------------
-- ENTRENADORES (héroes) — se fusionan 2 iguales para subir de nivel
---------------------------------------------------------------------
Config.COACHES = {
	{ id = "heracles", es = "Hércules", en = "Heracles", cost = 1e3, bonus = 0.10 },
	{ id = "aquiles", es = "Aquiles", en = "Achilles", cost = 5e4, bonus = 0.15 },
	{ id = "perseo", es = "Perseo", en = "Perseus", cost = 2.5e6, bonus = 0.20 },
	{ id = "teseo", es = "Teseo", en = "Theseus", cost = 1e8, bonus = 0.25 },
}
Config.COACH_TIERS = {
	{ es = "Normal", en = "Normal", mult = 1 },
	{ es = "Dorado", en = "Golden", mult = 2.5 },
	{ es = "Divino", en = "Divine", mult = 6 },
	{ es = "Mutado", en = "Mutated", mult = 15 },
}
Config.COACH_EQUIP = 3

---------------------------------------------------------------------
-- AURAS
---------------------------------------------------------------------
Config.AURAS = {
	{ id = "rayo", es = "Rayo de Zeus", en = "Zeus' Lightning", cost = 1e4, speed = 0.25, color = Color3.fromRGB(255, 240, 120) },
	{ id = "fuego", es = "Fuego del Inframundo", en = "Underworld Fire", cost = 2.5e5, money = 0.25, color = Color3.fromRGB(255, 90, 30) },
	{ id = "sol", es = "Sol de Ra", en = "Sun of Ra", cost = 2e7, speed = 0.60, color = Color3.fromRGB(255, 190, 60) },
	{ id = "escarcha", es = "Escarcha nórdica", en = "Norse Frost", cost = 1e9, money = 0.60, color = Color3.fromRGB(150, 220, 255) },
	{ id = "marea", es = "Marea de Poseidón", en = "Poseidon's Tide", cost = 5e10, speed = 0.50, money = 0.50, color = Color3.fromRGB(40, 160, 255) },
	{ id = "divina", es = "Aura Divina", en = "Divine Aura", cost = 5e12, speed = 1.5, money = 1.5, color = Color3.fromRGB(255, 255, 255) },
}
Config.AURA_BY_ID = {}
for _, a in ipairs(Config.AURAS) do
	Config.AURA_BY_ID[a.id] = a
end

---------------------------------------------------------------------
-- ROBUX
-- Pon aquí los IDs cuando crees los pases y productos en create.roblox.com
-- Mientras valgan 0, el botón sale como "Próximamente".
---------------------------------------------------------------------
Config.PASSES = {
	speed2x = { id = 2092574951, price = 199, es = "Velocidad x2", en = "2x Speed" },
	money2x = { id = 2092863003, price = 149, es = "Dinero x2", en = "2x Money" },
	luck2x = { id = 2093762893, price = 299, es = "Suerte x2", en = "2x Luck" },
	moreSlots = { id = 2093564933, price = 99, es = "+5 pedestales y +2 altares", en = "+5 pedestals & +2 altars" },
	vip = { id = 2094332929, price = 349, es = "VIP (+10% de todo)", en = "VIP (+10% everything)" },
}
Config.PRODUCTS = {
	savePack = { id = 3732903293, price = 25, es = "Salvar el sobre", en = "Save the pack" },
	speedBoost = { id = 3732903313, price = 49, es = "Velocidad x3 (15 min)", en = "3x Speed (15 min)" },
	serverNight = { id = 3732903322, price = 99, es = "Noche para el servidor", en = "Night for the server" },
	serverLuck = { id = 3732903331, price = 149, es = "Suerte x3 para el servidor (10 min)", en = "3x Luck for the server (10 min)" },
	moneySmall = { id = 3732903343, price = 49, es = "Dinero: 10 min de ingresos", en = "Money: 10 min of income" },
	moneyBig = { id = 3732903353, price = 199, es = "Dinero: 2 h de ingresos", en = "Money: 2 h of income" },
	openNowLow = { id = 3732903365, price = 19, es = "Abrir ya (Común–Épica)", en = "Open now (Common–Epic)" },
	openNowMid = { id = 3732903375, price = 79, es = "Abrir ya (Legendaria–Celestial)", en = "Open now (Legendary–Celestial)" },
	openNowHigh = { id = 3732903384, price = 299, es = "Abrir ya (Primordial o más)", en = "Open now (Primordial+)" },
	instantUpgrade = { id = 3732903393, price = 79, es = "Mejora de parcela instantánea", en = "Instant plot upgrade" },
	divineShield = { id = 3732903400, price = 29, es = "Escudo divino (3 min)", en = "Divine Shield (3 min)" },
	obbySkip = { id = 3733100507, price = 19, es = "Saltar etapa (Ascenso al Olimpo)", en = "Skip stage (Olympus Climb)" },
}

---------------------------------------------------------------------
-- AFK: antes de que Roblox expulse por inactividad (20 min), el juego
-- te reconecta al mismo juego y sigues en modo AFK.
---------------------------------------------------------------------
Config.AFK_REJOIN_AFTER = 17 * 60

Config.MAX_PLAYERS_PLOTS = 6

---------------------------------------------------------------------
-- KILOS: cada sobre (y su dios) pesa algo distinto.
-- Más kilos = más grande y más dinero (100 kg = x1)
---------------------------------------------------------------------
function Config.rollKg()
	local base = 40 + math.random() * 120
	local x = math.random()
	if x < 0.001 then
		base *= 6 + math.random() * 4 -- titánico
	elseif x < 0.01 then
		base *= 3 + math.random() * 3 -- gigante
	elseif x < 0.1 then
		base *= 1.5 + math.random() * 1.5 -- pesado
	end
	return math.floor(base)
end
function Config.kgMult(kg)
	return (kg or 100) / 100
end

---------------------------------------------------------------------
-- MUTACIONES: al conseguir un dios puede salir mutado y gana más dinero.
-- Porcentajes y multiplicadores tomados de Brainrot Bay (licencia MIT):
-- https://github.com/tothimai196xx-lgtm/brainrot-bay
---------------------------------------------------------------------
Config.MUTATIONS = {
	{ id = "gold", es = "Dorado", en = "Golden", icon = "🟡", chance = 0.05, mult = 2, color = Color3.fromRGB(255, 215, 0) },
	{ id = "ice", es = "Hielo", en = "Frozen", icon = "🧊", chance = 0.03, mult = 3, color = Color3.fromRGB(170, 220, 255) },
	{ id = "diamond", es = "Diamante", en = "Diamond", icon = "💎", chance = 0.025, mult = 4, color = Color3.fromRGB(185, 242, 255) },
	{ id = "lava", es = "Lava", en = "Lava", icon = "🌋", chance = 0.015, mult = 6, color = Color3.fromRGB(255, 90, 30) },
	{ id = "rainbow", es = "Arcoíris", en = "Rainbow", icon = "🌈", chance = 0.01, mult = 8, color = Color3.fromRGB(255, 120, 200), rainbow = true },
	-- mitológicas (más raras que el arcoíris; pedidas por el dueño)
	{ id = "storm", es = "Tormenta", en = "Storm", icon = "⚡", chance = 0.006, mult = 10, color = Color3.fromRGB(120, 200, 255) },
	{ id = "underworld", es = "Inframundo", en = "Underworld", icon = "💀", chance = 0.004, mult = 12, color = Color3.fromRGB(110, 255, 140) },
	{ id = "cosmic", es = "Cósmico", en = "Cosmic", icon = "🌌", chance = 0.0025, mult = 15, color = Color3.fromRGB(170, 110, 255) },
	{ id = "divine", es = "Divino", en = "Divine", icon = "✨", chance = 0.001, mult = 20, color = Color3.fromRGB(255, 236, 160) },
}
Config.MUTATION_BY_ID = {}
for _, m in ipairs(Config.MUTATIONS) do
	Config.MUTATION_BY_ID[m.id] = m
end
-- Tira la mutación de un dios recién conseguido (nil = normal). rng opcional para las pruebas.
function Config.rollMutation(rng)
	local x = (rng or math.random)()
	for _, m in ipairs(Config.MUTATIONS) do
		if x < m.chance then
			return m.id
		end
		x -= m.chance
	end
	return nil
end
function Config.mutMult(id)
	local m = id and Config.MUTATION_BY_ID[id]
	return m and m.mult or 1
end
function Config.kgScale(kg)
	return math.clamp(0.75 + (kg or 100) / 400, 0.75, 2.6)
end
-- Tamaño del SOBRE según sus kilos (se nota mucho más que en el dios): 40 kg ≈ 0.94 · 100 kg ≈ 1.35 · 160 kg ≈ 1.72 · 300 kg ≈ 2.5
function Config.packScale(kg)
	return math.clamp(0.6 + 0.75 * ((kg or 100) / 100) ^ 0.85, 0.85, 3.6)
end

---------------------------------------------------------------------
-- NIDOS: los sobres de cada zona aparecen juntos en un nido
---------------------------------------------------------------------
Config.NEST_OFFSET = 100 -- distancia desde el inicio de la zona hasta el centro del nido
Config.NEST_RADIUS = 9 -- radio del anillo donde se colocan los sobres

---------------------------------------------------------------------
-- VENDEDORES: dos dioses a los lados de los rankings (fondo de la plaza)
---------------------------------------------------------------------
Config.VENDORS = {
	aura = { es = "Hécate", en = "Hecate", titleEs = "Diosa de la magia", titleEn = "Goddess of magic", pos = Vector3.new(-58, 0, -110), color = Color3.fromRGB(190, 110, 255) },
	coach = { es = "Quirón", en = "Chiron", titleEs = "Maestro de héroes", titleEn = "Trainer of heroes", pos = Vector3.new(58, 0, -110), color = Color3.fromRGB(255, 190, 70) },
}

---------------------------------------------------------------------
-- MISIONES DIARIAS, RACHA DIARIA Y TUTORIAL (los usan el servidor y el cliente)
-- Premios: money = segundos de tus ingresos (mínimo MONEY_MIN) · luck = minutos de Suerte x2 ·
-- speed = minutos de Velocidad x3 · pack = sobre de tu mejor zona (luck = suerte de la tirada; big = sobre del amanecer)
---------------------------------------------------------------------
Config.QUESTS = {
	PER_DAY = 3, -- misiones al día
	REROLLS = 1, -- misiones que se pueden cambiar cada día
	MONEY_MIN = 500,
	LUCK_BOOST = 2, -- el boost de suerte multiplica tu suerte por 2
	-- racha diaria: 7 días que se repiten (el día 7, un MEGA sobre del amanecer)
	DAILY = {
		{ kind = "money", secs = 300 },
		{ kind = "luck", mins = 10 },
		{ kind = "money", secs = 900 },
		{ kind = "speed", mins = 5 },
		{ kind = "pack", luck = 2 },
		{ kind = "money", secs = 1800 },
		{ kind = "pack", luck = 5, big = true },
	},
	-- weight = lo a menudo que sale (golpear necesita a otros jugadores en el pasillo: sale poco)
	POOL = {
		{ id = "steal", goal = 5, weight = 3, icon = "📦", reward = { kind = "money", secs = 600 } },
		{ id = "open", goal = 5, weight = 3, icon = "🔮", reward = { kind = "luck", mins = 10 } },
		{ id = "escape", goal = 3, weight = 3, icon = "🏃", reward = { kind = "speed", mins = 5 } },
		{ id = "train", goal = 180, weight = 3, icon = "⚡", reward = { kind = "money", secs = 600 } },
		{ id = "newgod", goal = 1, weight = 2, icon = "✨", reward = { kind = "pack", luck = 2 } },
		{ id = "combo", goal = 10, weight = 3, icon = "🎯", reward = { kind = "money", secs = 450 } },
		{ id = "hit", goal = 3, weight = 1, icon = "🏏", reward = { kind = "money", secs = 300 } },
	},
	-- tutorial: 1 cinta → 2 combo → 3 robar → 4 volver a casa → 5 abrir → 6 mejorar la cinta → 7 terminado
	TUTORIAL_STEPS = 6,
	TUTORIAL_DONE = 7,
	TUTORIAL_REWARD = { kind = "money", secs = 900 },
}
Config.QUEST_BY_ID = {}
for _, q in ipairs(Config.QUESTS.POOL) do
	Config.QUEST_BY_ID[q.id] = q
end

---------------------------------------------------------------------
-- LUZ del mundo (la usan el servidor y el cliente: deben coincidir)
---------------------------------------------------------------------
Config.LIGHT = {
	day = { clock = 14.2, brightness = 3.2, outdoor = Color3.fromRGB(160, 160, 172), ambient = Color3.fromRGB(112, 106, 118), tint = Color3.fromRGB(255, 250, 244) },
	night = { clock = 0.5, brightness = 0.8, outdoor = Color3.fromRGB(60, 55, 115), tint = Color3.fromRGB(175, 175, 255) },
	atmo = { color = Color3.fromRGB(205, 225, 255), decay = Color3.fromRGB(255, 235, 200), density = 0.22, haze = 0.4, glare = 0.3 },
	zoneDensity = 0.26,
	cosmicDensity = 0.42,
	saturation = 0.38,
	contrast = 0.12,
}

---------------------------------------------------------------------
-- SONIDOS propios (subidos a la cuenta del juego). "" = sin sonido
---------------------------------------------------------------------
Config.SOUNDS = {
	chase = "rbxassetid://134426853581343", -- música de persecución original (bucle de 36 s; tools/audio/gen_chase.py)
	bgm = "rbxassetid://123910427829548", -- música de fondo original, alegre y acogedora (bucle de 65 s; tools/audio/gen_bgm.py)
	shouts = "rbxassetid://73369381252356", -- gritos de los guardianes: 6 frases en huecos de 5 s (tools/audio/make_shouts.sh)
}
-- Grito de cada guardián al empezar a perseguirte: hueco del audio "shouts" y duración (s)
Config.SHOUT_SLOT = 5
Config.SHOUTS = {
	minotaur = { slot = 1, len = 2.83, text = "HEY!! That's MY pack!" },
	dullahan = { slot = 2, len = 3.49, text = "HEEEY! You can't escape me!" },
	sphinx = { slot = 3, len = 2.34, text = "HEY! Stop right there, thief!" },
	jaguar = { slot = 4, len = 3.13, text = "HEY!! I see you!" },
	lamassu = { slot = 5, len = 2.8, text = "HEY!! Give that back!" },
	fenrir = { slot = 6, len = 3.13, text = "HEEEY!! Come back here!" },
}
Config.SAFE_Z = 102 -- la línea segura: por debajo de esta Z (la plaza) nadie te persigue (= World.SAFE_Z)


---------------------------------------------------------------------
-- MODELOS 3D (hechos en Blender y subidos a la cuenta del juego)
---------------------------------------------------------------------
Config.MODELS = {
	zeus = { asset = 92086522191115, joints = { LegL = Vector3.new(0.420, 2.300, 0.000), LegR = Vector3.new(-0.420, 2.300, 0.000), ArmL = Vector3.new(1.155, 4.250, 0.000), ArmR = Vector3.new(-1.155, 4.250, 0.000) } },
	thor = { asset = 114769630459171, joints = { LegL = Vector3.new(0.420, 2.300, 0.000), LegR = Vector3.new(-0.420, 2.300, 0.000), ArmL = Vector3.new(1.208, 4.250, 0.000), ArmR = Vector3.new(-1.208, 4.250, 0.000) } },
	anubis = { asset = 109549248325197, joints = { LegL = Vector3.new(0.420, 2.300, 0.000), LegR = Vector3.new(-0.420, 2.300, 0.000), ArmL = Vector3.new(1.050, 4.250, 0.000), ArmR = Vector3.new(-1.050, 4.250, 0.000) } },
	minotaur = { asset = 71616274173148, joints = { LegL = Vector3.new(0.750, 3.300, 0.000), LegR = Vector3.new(-0.750, 3.300, 0.000), ArmL = Vector3.new(1.550, 5.100, 0.000), ArmR = Vector3.new(-1.550, 5.100, 0.000) } },
}
-- Texturas de efectos (brillos, destellos, anillos, runas, humo, chispas, llamas)
Config.VFX = {
	flame = "rbxassetid://70450162736270",
	glow = "rbxassetid://80704845655271",
	ring = "rbxassetid://80633486636219",
	runes = "rbxassetid://75646621572336",
	smoke = "rbxassetid://72641413375480",
	sparkle = "rbxassetid://109708405214367",
	streak = "rbxassetid://95678528492429",
	studs = "rbxassetid://131282324801126",
	planks = "rbxassetid://132280466948067",
	-- texturas propias (escala de grises, se tiñen con Texture.Color3)
	paving = "rbxassetid://131562654980056",
	ashlar = "rbxassetid://94341551083105",
	bricks = "rbxassetid://105882514398300",
	grime = "rbxassetid://91574216540620",
	grass = "rbxassetid://91769058387894",
	meander = "rbxassetid://84040163115849",
	carved = "rbxassetid://78978860082772",
	rays = "rbxassetid://105597901155584",
	hexgrid = "rbxassetid://90091031894278",
	-- subidas desde Studio en Shadow (tools/tex/gen_sky_floor.py)
	galaxy = "rbxassetid://102219515094576",
	cracks = "rbxassetid://134963684813585",
	stars = "rbxassetid://73305394503983",
	aurora = "rbxassetid://102377757057759",
}

return Config
