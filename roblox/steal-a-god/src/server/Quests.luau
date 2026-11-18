-- Fase 2: racha diaria, misiones diarias y tutorial para jugadores nuevos.
-- Las tablas de premios y misiones están en Config.QUESTS (el cliente las usa para dibujarlas).
-- Los días son días UTC: math.floor(os.time() / 86400).
local Quests = {}
local G
local C
local Q

local DAY = 86400
local function today()
	return math.floor(os.time() / DAY)
end
Quests.today = today

---------------------------------------------------------------------
-- Premios
---------------------------------------------------------------------
-- Mejor zona a la que puede entrar el jugador (los sobres de premio salen de ella)
local function bestZone(d)
	local z = 1
	for i, zone in ipairs(C.ZONES) do
		if d.speed >= zone.req then
			z = i
		end
	end
	return z
end

local function moneyAmount(player, secs)
	return math.max(Q.MONEY_MIN, math.floor(G.Core.income(player) * secs))
end

-- Entrega un premio. Devuelve { claveDelAviso, argumento } para G.Net.toast.
function Quests.give(player, reward)
	local d = G.Data.profiles[player]
	if not d or type(reward) ~= "table" then
		return { "bought" }
	end
	if reward.kind == "money" then
		local amount = moneyAmount(player, reward.secs or 300)
		G.Core.addMoney(player, amount)
		return { "rewardMoney", G.Format.num(amount) }
	elseif reward.kind == "luck" then
		d.boosts.luck = math.max(os.time(), d.boosts.luck or 0) + (reward.mins or 10) * 60
		G.Core.invalidate(player)
		return { "rewardLuck", reward.mins or 10 }
	elseif reward.kind == "speed" then
		d.boosts.speed = math.max(os.time(), d.boosts.speed or 0) + (reward.mins or 5) * 60
		G.Core.invalidate(player)
		return { "rewardSpeed", reward.mins or 5 }
	elseif reward.kind == "pack" then
		-- la suerte del jugador (pase o boost) también cuenta en los sobres de premio
		local luck = (reward.luck or 1) * G.Core.personalLuck(player)
		local r = C.rollRarity(bestZone(d), luck)
		local ok = G.Packs.givePack(player, { r = r, rem = C.RARITIES[r].open, dawn = reward.big == true, kg = C.rollKg(), luck = C.packLuck(bestZone(d), r, reward.big == true) })
		if not ok then
			-- altares y cola llenos: se cambia por 15 min de ingresos
			local amount = math.max(1000, math.floor(G.Core.income(player) * 900))
			G.Core.addMoney(player, amount)
			return { "rewardMoney", G.Format.num(amount) }
		end
		return { "rewardPack", { rarity = r } }
	end
	return { "bought" }
end

---------------------------------------------------------------------
-- Misiones del día
---------------------------------------------------------------------
-- ¿Puede conseguir un dios que aún no tiene en las zonas a las que llega? (si no, no se le pide)
local function canGetNewGod(d)
	local reachable = {}
	for i = 1, bestZone(d) do
		for r in pairs(C.ZONES[i].weights) do
			reachable[r] = true
		end
	end
	for _, g in ipairs(C.GODS) do
		if reachable[g.r] and not g.dawnOnly and (d.gods[g.id] or 0) <= 0 then
			return true
		end
	end
	return false
end

-- Misiones que se le pueden dar a este jugador (sin las que ya tiene en la lista `skip`)
local function candidates(d, skip)
	local list = {}
	for _, def in ipairs(Q.POOL) do
		if not (skip and skip[def.id]) and (def.id ~= "newgod" or canGetNewGod(d)) then
			table.insert(list, def)
		end
	end
	return list
end

-- Saca una al azar según su peso y la quita de la lista
local function pick(list, rng)
	local total = 0
	for _, def in ipairs(list) do
		total += def.weight or 1
	end
	local x = rng:NextNumber() * total
	for i, def in ipairs(list) do
		x -= def.weight or 1
		if x <= 0 then
			return table.remove(list, i)
		end
	end
	return table.remove(list, #list)
end

-- Las misiones de un día son siempre las mismas para el mismo jugador (no se arreglan entrando y saliendo)
local function rollMissions(player, d)
	local day = today()
	local rng = Random.new(day * 7919 + (player.UserId % 100000))
	local pool = candidates(d)
	local list = {}
	for _ = 1, math.min(Q.PER_DAY, #pool) do
		local def = pick(pool, rng)
		table.insert(list, { id = def.id, goal = def.goal, progress = 0, claimed = false })
	end
	d.missions = { day = day, rr = 0, list = list }
end

-- ¿Son las misiones de hoy? (day = t + 1: las sacó otro servidor con el reloj algo adelantado que ya
-- pasó la medianoche; si se tomaran por "viejas", aquí se volverían a sacar las de ayer sin reclamar)
local function isCurrentDay(day)
	local t = today()
	return day == t or day == t + 1
end

-- Cambio de día: las misiones completadas sin reclamar se pagan solas y salen las nuevas
local function ensureDay(player, d)
	-- (una lista vacía de hoy solo sale de una partida rota o de un cambio en Config: se vuelven a sacar)
	if isCurrentDay(d.missions.day) and #d.missions.list > 0 then
		return
	end
	local paid = 0
	if d.missions.day ~= 0 and not isCurrentDay(d.missions.day) then
		for _, m in ipairs(d.missions.list) do
			local def = C.QUEST_BY_ID[m.id]
			if def and not m.claimed and m.progress >= m.goal then
				m.claimed = true
				Quests.give(player, def.reward)
				paid += 1
			end
		end
	end
	rollMissions(player, d)
	if paid > 0 then
		G.Net.toast(player, "missionAuto")
	end
end
Quests.ensureDay = ensureDay

---------------------------------------------------------------------
-- Racha diaria
---------------------------------------------------------------------
-- Devuelve: ¿puede reclamar hoy? y la racha que tendrá al reclamar (o la que tiene si ya reclamó)
function Quests.dailyState(d)
	local t = today()
	local last = d.daily.last or 0
	local streak = d.daily.streak or 0
	-- (t + 1: otro servidor con el reloj un segundo adelantado ya pasó la medianoche; más allá, es un dato roto)
	if last == t or last == t + 1 then
		return false, math.max(1, streak)
	end
	return true, (last == t - 1) and streak + 1 or 1
end

-- Premio del día N de la racha (el ciclo de 7 días se repite)
function Quests.dailyReward(streak)
	return Q.DAILY[((math.max(1, streak) - 1) % #Q.DAILY) + 1]
end

---------------------------------------------------------------------
-- Tutorial
---------------------------------------------------------------------
function Quests.advance(player)
	local d = G.Data.profiles[player]
	if not d or d.tutorial < 1 or d.tutorial >= Q.TUTORIAL_DONE then
		return
	end
	d.tutorial += 1
	if d.tutorial >= Q.TUTORIAL_DONE then
		-- el premio solo se da aquí, al pasar del paso 6 al 7 (una vez)
		local msg = Quests.give(player, Q.TUTORIAL_REWARD)
		G.Net.toast(player, "tutorialDone", msg[2])
	end
end

---------------------------------------------------------------------
-- Progreso: cada sistema avisa con Quests.event(jugador, tipo, cantidad)
-- tipos: steal, escape, open, newgod, combo, hit, train
---------------------------------------------------------------------
function Quests.event(player, kind, amount)
	local d = G.Data.profiles[player]
	if not d then
		return
	end
	ensureDay(player, d)
	amount = tonumber(amount) or 1
	for _, m in ipairs(d.missions.list) do
		if m.id == kind and not m.claimed and m.progress < m.goal then
			m.progress = math.min(m.goal, m.progress + amount)
			if m.progress >= m.goal then
				G.Net.toast(player, "missionDone", { mission = m.id, goal = m.goal })
			end
		end
	end
	local step = d.tutorial
	if (step == 2 and kind == "combo") or (step == 3 and kind == "steal") or (step == 4 and kind == "escape") or (step == 5 and kind == "open") then
		Quests.advance(player)
	end
end

-- Cada segundo (desde Core): cambio de día, minutos de entrenamiento y pasos del tutorial que dependen del estado
function Quests.tick(player, s, d)
	ensureDay(player, d)
	local step = d.tutorial
	if step >= 1 and step < Q.TUTORIAL_DONE then
		if step == 1 then
			-- con la velocidad del primer guardián ya se le escapa al volver a casa
			if s.onTreadmill and d.speed >= C.ZONES[1].guardian.speed then
				Quests.advance(player)
			end
		elseif step == 2 then
			if (s.combo or 1) > 1 then
				Quests.advance(player)
			end
		elseif step == 3 then
			-- por si lo coge de nuevo del suelo (robar el mismo sobre otra vez no cuenta como misión)
			if s.carrying then
				Quests.advance(player)
			end
		elseif step == 4 then
			-- lo perdió (guardián, golpe o noche): vuelta a robar uno
			if not s.carrying then
				d.tutorial = 3
			end
		elseif step == 5 then
			if #d.altarPacks == 0 and #d.queue == 0 then
				d.tutorial = 3
			end
		elseif step == 6 then
			if d.treadmill >= 2 then
				Quests.advance(player)
			end
		end
	end
	if s.onTreadmill and not s.afk then
		Quests.event(player, "train", 1)
	end
end

-- Un sobre llegó a casa sin escapar (compra de "Salvar el sobre"): en el tutorial ya puede abrirlo.
-- (no cuenta para la misión de escapar)
function Quests.packHome(player)
	local d = G.Data.profiles[player]
	if d and (d.tutorial == 3 or d.tutorial == 4) then
		d.tutorial = 5
	end
end

function Quests.onJoin(player)
	local d = G.Data.profiles[player]
	if not d then
		return
	end
	ensureDay(player, d)
	-- los jugadores que ya tenían progreso no necesitan el tutorial
	if d.tutorial == 0 then
		local hasGods = next(d.gods) ~= nil
		d.tutorial = (hasGods or d.playtime > 600) and Q.TUTORIAL_DONE or 1
	end
end

---------------------------------------------------------------------
-- Acciones del cliente (siempre validadas aquí)
---------------------------------------------------------------------
function Quests.claimDaily(player)
	local d = G.Data.profiles[player]
	if not d then
		return false
	end
	local canClaim, streak = Quests.dailyState(d)
	if not canClaim then
		return false
	end
	-- primero se apunta el día: aunque algo falle después, nunca se cobra dos veces
	d.daily.last = today()
	d.daily.streak = streak
	local msg = Quests.give(player, Quests.dailyReward(streak))
	G.Net.toast(player, msg[1], msg[2])
	return true
end

function Quests.claimMission(player, index)
	local d = G.Data.profiles[player]
	if not d then
		return false
	end
	ensureDay(player, d)
	index = tonumber(index)
	local m = index and d.missions.list[index]
	local def = m and C.QUEST_BY_ID[m.id]
	if not m or not def or m.claimed or m.progress < m.goal then
		return false
	end
	m.claimed = true
	local msg = Quests.give(player, def.reward)
	G.Net.toast(player, msg[1], msg[2])
	return true
end

-- Cambia una misión sin terminar por otra (Q.REROLLS al día)
function Quests.rerollMission(player, index)
	local d = G.Data.profiles[player]
	if not d then
		return false
	end
	ensureDay(player, d)
	index = tonumber(index)
	local m = index and d.missions.list[index]
	if not m or m.claimed or m.progress >= m.goal or d.missions.rr >= Q.REROLLS then
		return false
	end
	local skip = {}
	for _, other in ipairs(d.missions.list) do
		skip[other.id] = true
	end
	local pool = candidates(d, skip)
	if #pool == 0 then
		return false
	end
	local def = pick(pool, Random.new())
	d.missions.list[index] = { id = def.id, goal = def.goal, progress = 0, claimed = false }
	d.missions.rr += 1
	G.Net.toast(player, "rerolled")
	return true
end

function Quests.skipTutorial(player)
	local d = G.Data.profiles[player]
	if d and d.tutorial < Q.TUTORIAL_DONE then
		d.tutorial = Q.TUTORIAL_DONE
	end
end

---------------------------------------------------------------------
-- Datos para el cliente (pequeños: las tablas fijas las lee de Config.QUESTS)
---------------------------------------------------------------------
function Quests.state(player)
	local d = G.Data.profiles[player]
	if not d then
		return nil
	end
	ensureDay(player, d)
	local canClaim, streak = Quests.dailyState(d)
	local list = {}
	for i, m in ipairs(d.missions.list) do
		list[i] = { id = m.id, goal = m.goal, progress = m.progress, claimed = m.claimed }
	end
	return {
		day = d.missions.day,
		dailyCan = canClaim,
		streak = streak,
		missions = list,
		rr = math.max(0, Q.REROLLS - d.missions.rr),
		tutorial = d.tutorial,
	}
end

-- Firma para mandar el estado solo cuando cambia
function Quests.signature(q)
	if not q then
		return ""
	end
	local parts = { q.day, tostring(q.dailyCan), q.streak, q.rr, q.tutorial }
	for _, m in ipairs(q.missions) do
		table.insert(parts, string.format("%s:%s:%s:%s", m.id, tostring(m.goal), tostring(m.progress), tostring(m.claimed)))
	end
	return table.concat(parts, "|")
end

function Quests.init(g)
	G = g
	C = g.Config
	Q = C.QUESTS
	local actions = G.Core.actions
	actions.claimDaily = Quests.claimDaily
	actions.claimMission = Quests.claimMission
	actions.rerollMission = Quests.rerollMission
	actions.skipTutorial = Quests.skipTutorial
end

return Quests
