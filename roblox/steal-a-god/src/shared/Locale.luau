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
	gotMutation = { es = "🧬 ¡%s ha conseguido un dios mutado: %s %s!", en = "🧬 %s got a mutated god: %s %s!" },
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
	run = { es = "¡CORRE!", en = "RUN!" },
	guardianDist = { es = "Guardián a %d bloques", en = "Guardian %d studs away" },
	dropPack = { es = "Soltar sobre", en = "Drop pack" },
	offlineTitle = { es = "¡Has ganado mientras no estabas!", en = "You earned while you were away!" },
	offlineSub = { es = "Tus dioses siguieron trabajando %s", en = "Your gods kept working for %s" },
	claim = { es = "¡RECLAMAR!", en = "CLAIM!" },
	nightIn = { es = "Noche en", en = "Night in" },
	dawnIn = { es = "Amanece en", en = "Dawn in" },
	recommended = { es = "Velocidad recomendada: %s+", en = "Recommended speed: %s+" },
	new = { es = "NUEVO", en = "NEW" },
	settings = { es = "Ajustes", en = "Settings" },
	sfx = { es = "Efectos de sonido", en = "Sound effects" },
	particlesOpt = { es = "Partículas y efectos", en = "Particles & effects" },
	shakeOpt = { es = "Temblor de cámara", en = "Camera shake" },
	othersAuras = { es = "Auras de otros jugadores", en = "Other players' auras" },
	uiSize = { es = "Tamaño de la interfaz", en = "Interface size" },
	on = { es = "SÍ", en = "ON" },
	off = { es = "NO", en = "OFF" },
	small = { es = "Pequeña", en = "Small" },
	normal = { es = "Normal", en = "Normal" },
	big = { es = "Grande", en = "Large" },
	controls = { es = "Controles", en = "Controls" },
	openSaved = { es = "No tienes un sobre de esa categoría: se abrirá el próximo que llegue", en = "No pack of that tier yet: the next one will open instantly" },
	plotMaxRefund = { es = "Tu parcela ya está al máximo: te damos 2 h de ingresos", en = "Your plot is maxed: you got 2 h of income instead" },
	ownerPasses = { es = "👑 Usar mis pases (solo creador)", en = "👑 Use my passes (creator only)" },
	title1 = { es = "Mortal", en = "Mortal" },
	title2 = { es = "Corredor", en = "Runner" },
	title3 = { es = "Atleta", en = "Athlete" },
	title4 = { es = "Héroe", en = "Hero" },
	title5 = { es = "Semidiós", en = "Demigod" },
	title6 = { es = "Titán", en = "Titan" },
	title7 = { es = "Dios", en = "God" },
	title8 = { es = "Dios Supremo", en = "Supreme God" },
	title9 = { es = "Primordial", en = "Primordial" },
	title10 = { es = "Infinito", en = "Infinite" },
	serverLuck = { es = "🍀 ¡%s ha activado Suerte x3 para todo el servidor durante 10 minutos!", en = "🍀 %s activated 3x Luck for the whole server for 10 minutes!" },
	nightBought = { es = "🌙 ¡%s ha comprado la noche para todo el servidor!", en = "🌙 %s bought the night for the whole server!" },
	endSign = { es = "🔒 MÁS ZONAS PRÓXIMAMENTE", en = "🔒 MORE ZONES COMING SOON" },
	chasing = { es = "¡TE PERSIGUE!", en = "CHASING!" },
	moreZones = { es = "Próxima actualización: Inframundo, Atlántida, Olimpo…", en = "Next update: Underworld, Atlantis, Olympus…" },
	-- cinta con toques de combo
	comboLost = { es = "¡COMBO PERDIDO!", en = "COMBO LOST!" },
	taps = { es = "toques", en = "taps" },
	jumpToLeave = { es = "Salta para bajar de la cinta (%s)", en = "Jump to get off the treadmill (%s)" },
	jumpButton = { es = "botón de saltar", en = "jump button" },
	spaceKey = { es = "Espacio", en = "Space" },
	-- vendedores (dioses junto a la entrada del pasillo)
	music = { es = "Música", en = "Music" },
	talk = { es = "Hablar", en = "Talk" },
	auraShop = { es = "Auras de Hécate", en = "Hecate's Auras" },
	coachShop = { es = "Entrenadores de Quirón", en = "Chiron's Coaches" },
	auraSign = { es = "✨ AURAS", en = "✨ AURAS" },
	coachSign = { es = "🏋️ ENTRENADORES", en = "🏋️ COACHES" },
	auraHint = { es = "Un aura te rodea de poder: más velocidad y más dinero.", en = "An aura surrounds you with power: more speed and more money." },
	coachHint = { es = "Cuentan tus 3 mejores entrenadores. Fusiona 2 iguales para subirlos de nivel.", en = "Your best 3 coaches count. Fuse 2 identical ones to level them up." },
	vendorMoved = { es = "Las auras y los entrenadores los venden Hécate y Quirón, a los lados de los rankings.", en = "Auras and coaches are sold by Hecate and Chiron, next to the leaderboards." },
	youHave = { es = "Tienes", en = "You have" },
	safeFloor = { es = "ZONA SEGURA", en = "SAFE ZONE" },
	nest = { es = "Nido de sobres", en = "Pack nest" },
	-- misiones diarias, racha diaria y tutorial
	missions = { es = "Misiones", en = "Missions" },
	missionsTitle = { es = "Misiones y premios", en = "Missions & rewards" },
	todayMissions = { es = "📜 Misiones de hoy", en = "📜 Today's missions" },
	dailyStreak = { es = "🔥 Racha diaria", en = "🔥 Daily streak" },
	streakDays = { es = "Racha: %d días seguidos", en = "Streak: %d days in a row" },
	streakHint = { es = "Entra cada día: el día 7 te espera un MEGA sobre 🎁", en = "Come back every day: a MEGA pack 🎁 waits on day 7" },
	dailyTitle = { es = "🔥 ¡PREMIO DIARIO!", en = "🔥 DAILY REWARD!" },
	dayN = { es = "DÍA %d", en = "DAY %d" },
	claimDay = { es = "¡RECLAMAR DÍA %d!", en = "CLAIM DAY %d!" },
	claimed = { es = "Reclamado", en = "Claimed" },
	tomorrow = { es = "Mañana: %s", en = "Tomorrow: %s" },
	comeBack = { es = "✅ Premio de hoy reclamado · vuelve en %s", en = "✅ Today's reward claimed · come back in %s" },
	resetIn = { es = "Nuevas en %s", en = "New in %s" },
	reroll = { es = "Cambiar", en = "Swap" },
	sure = { es = "¿Seguro?", en = "Sure?" },
	rerolled = { es = "🔄 Misión cambiada", en = "🔄 Mission swapped" },
	packWord = { es = "Sobre", en = "Pack" },
	megaPack = { es = "MEGA", en = "MEGA" },
	missionDone = { es = "✅ ¡Misión completada: %s! Reclama tu premio en 📜", en = "✅ Mission complete: %s! Claim your reward in 📜" },
	missionAuto = { es = "🎁 Tus misiones completadas de ayer se han reclamado solas", en = "🎁 Yesterday's completed missions were claimed for you" },
	rewardMoney = { es = "🎁 ¡Premio: 💰 $%s!", en = "🎁 Reward: 💰 $%s!" },
	rewardLuck = { es = "🍀 ¡Suerte x2 durante %s min! Mejora los sobres que traes a casa", en = "🍀 2x Luck for %s min! It upgrades the packs you bring home" },
	rewardSpeed = { es = "⚡ ¡Velocidad x3 durante %s min!", en = "⚡ 3x Speed for %s min!" },
	rewardPack = { es = "📦 ¡Un sobre %s te espera en tu altar!", en = "📦 A %s pack is waiting at your altar!" },
	luckUpgrade = { es = "🍀 ¡Tu suerte ha mejorado el sobre a %s!", en = "🍀 Your luck upgraded the pack to %s!" },
	m_steal = { es = "Roba %d sobres", en = "Steal %d packs" },
	m_open = { es = "Abre %d sobres", en = "Open %d packs" },
	m_escape = { es = "Llega a casa con %d sobres", en = "Bring %d packs home" },
	m_train = { es = "Entrena %d min en tu cinta", en = "Train %d min on your treadmill" },
	m_newgod = { es = "Consigue %d dios nuevo", en = "Get %d new god" },
	m_combo = { es = "Acierta %d combos en la cinta", en = "Land %d treadmill combos" },
	m_hit = { es = "Golpea %d veces en el pasillo", en = "Land %d hits in the corridor" },
	tutWelcome = { es = "👋 ¡Bienvenido! Sigue la luz dorada ✨", en = "👋 Welcome! Follow the golden light ✨" },
	tutStep = { es = "PASO", en = "STEP" },
	tut1 = { es = "Sube a tu cinta 🏃 y corre hasta ⚡ %s", en = "Step on your treadmill 🏃 and run to ⚡ %s" },
	tut2 = { es = "Toca los círculos que aparecen en la pantalla antes de que se cierre el aro 🎯", en = "Tap the circles that pop up on screen before the ring closes 🎯" },
	tut3 = { es = "Ve al pasillo y roba un sobre del nido 📦", en = "Go to the corridor and steal a pack from the nest 📦" },
	tut4 = { es = "¡Corre a tu parcela antes de que te pille el guardián!", en = "Run back to your plot before the guardian catches you!" },
	tut5 = { es = "¡Tu sobre está listo! Ábrelo en tu altar 🔮", en = "Your pack is ready! Open it at your altar 🔮" },
	tut5wait = { es = "Tu sobre se abre en tu altar 🔮 Listo en %s", en = "Your pack opens at your altar 🔮 Ready in %s" },
	tut6 = { es = "Abre la Tienda 🛒 y mejora tu cinta (💰 %s)", en = "Open the Shop 🛒 and upgrade your treadmill (💰 %s)" },
	tutGo = { es = "¡Ve!", en = "Go!" },
	tutCorridor = { es = "Pasillo", en = "Corridor" },
	tutHome = { es = "Tu parcela", en = "Your plot" },
	tutHere = { es = "¡Aquí!", en = "Here!" },
	tutNice = { es = "¡BIEN HECHO!", en = "NICE!" },
	tutorialDone = { es = "🎓 ¡Tutorial completado! Premio: 💰 $%s", en = "🎓 Tutorial complete! Reward: 💰 $%s" },
	tutorialDoneBanner = { es = "🎓 ¡YA SABES JUGAR! Ahora, a por todos los dioses ⚡", en = "🎓 YOU KNOW HOW TO PLAY! Now go catch them all ⚡" },
	skip = { es = "Saltar", en = "Skip" },
}

-- Texto de una misión diaria ("Roba 5 sobres"); el entrenamiento se cuenta en segundos y se muestra en minutos
function Locale.mission(id: string, goal: number?): string
	local g = goal or 1
	if id == "train" then
		g = math.max(1, math.floor(g / 60 + 0.5))
	end
	return Locale.t("m_" .. tostring(id), g)
end

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
