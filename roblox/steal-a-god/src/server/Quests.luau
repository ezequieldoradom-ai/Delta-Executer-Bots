-- Fase 2: racha diaria, misiones diarias y tutorial para jugadores nuevos
local Quests = {}
local G
local C

local DAY = 86400
local function today()
	return math.floor(os.time() / DAY)
end
Quests.today = today

---------------------------------------------------------------------
-- Racha diaria (7 días que se repiten)
---------------------------------------------------------------------
-- kind: money (segundos de ingresos), luck/speed (minutos de boost), pack (sobre de tu mejor zona)
Quests.DAILY = {
	{ kind = "money", secs = 300 },
	{ kind = "luck", mins = 10 },
	{ kind = "money", secs = 900 },
	{ kind = "speed", mins = 10 },
	{ kind = "pack", luck = 2 },
	{ kind = "money", secs = 1800 },
	{ kind = "pack", luck = 5, big = true },
}

---------------------------------------------------------------------
-- Misiones diarias: 3 al día, distintas para cada jugador
---------------------------------------------------------------------
Quests.POOL = {
	{ id = "steal", goal = 5, reward = { kind = "money", secs = 600 } },
	{ id = "open", goal = 5, reward = { kind = "luck", mins = 10 } },
	{ id = "escape", goal = 3, reward = { kind = "speed", mins = 10 } },
	{ id = "train", goal = 180, reward = { kind = "money", secs = 600 } },
	{ id = "newgod", goal = 1, reward = { kind = "pack", luck = 2 } },
	{ id = "combo", goal = 3, reward = { kind = "money", secs = 450 } },
	{ id = "hit", goal = 5, reward = { kind = "money", secs = 300 } },
}

-- Tutorial: 1 cinta → 2 combo → 3 robar → 4 volver → 5 abrir → 6 mejorar cinta → 7 terminado
Quests.TUTORIAL_DONE = 7

local function bestZone(d)
	local z = 1
	for i, zone in ipairs(C.ZONES) do
		if d.speed >= zone.req then
			z = i
		end
	end
	return z
end

-- Entrega un premio y devuelve una descripción para el aviso
function Quests.give(player, reward)
	local d = G.Data.profiles[player]
	if reward.kind == "money" then
		local amount = math.max(500, G.Core.income(player) * reward.secs)
		G.Core.addMoney(player, amount)
		return { "rewardMoney", G.Format.num(amount) }
	elseif reward.kind == "luck" then
		d.boosts.luck = math.max(os.time(), d.boosts.luck or 0) + reward.mins * 60
		G.Core.invalidate(player)
		return { "rewardLuck", reward.mins }
	elseif reward.kind == "speed" then
		d.boosts.speed = math.max(os.time(), d.boosts.speed or 0) + reward.mins * 60
		G.Core.invalidate(player)
		return { "rewardSpeed", reward.mins }
	elseif reward.kind == "pack" then
		local r = C.rollRarity(bestZone(d), reward.luck or 1)
		if not G.Packs.givePack(player, { r = r, rem = C.RARITIES[r].open, dawn = reward.big == true, kg = C.rollKg() }) then
			-- sin sitio: se cambia por dinero
			local amount = math.max(1000, G.Core.income(player) * 900)
			G.Core.addMoney(player, amount)
			return { "rewardMoney", G.Format.num(amount) }
		end
		return { "rewardPack", { rarity = r } }
	end
	return { "bought" }
end

local function rollMissions(player, d)
	local rng = Random.new(today() * 7919 + (player.UserId % 100000))
	local pool = table.clone(Quests.POOL)
	local list = {}
	for _ = 1, 3 do
		local m = table.remove(pool, rng:NextInteger(1, #pool))
		table.insert(list, { id = m.id, goal = m.goal, progress = 0, claimed = false })
	end
	d.missions = { day = today(), list = list }
end

function Quests.onJoin(player)
	local d = G.Data.profiles[player]
	if not d then
		return
	end
	if (d.missions.day or 0) ~= today() then
		rollMissions(player, d)
	end
	-- los jugadores que ya tenían progreso no necesitan el tutorial
	if d.tutorial == 0 then
		local hasGods = next(d.gods) ~= nil
		d.tutorial = (hasGods or d.playtime > 600) and Quests.TUTORIAL_DONE or 1
	end
end

function Quests.dailyState(d)
	local t = today()
	local last = d.daily.last or 0
	local streak = d.daily.streak or 0
	local canClaim = last ~= t
	local nextStreak = (last == t - 1) and streak + 1 or 1
	if not canClaim then
		nextStreak = streak
	end
	return canClaim, nextStreak
end

---------------------------------------------------------------------
-- Progreso de misiones y tutorial
---------------------------------------------------------------------
function Quests.event(player, kind, amount)
	local d = G.Data.profiles[player]
	if not d then
		return
	end
	if (d.missions.day or 0) ~= today() then
		rollMissions(player, d)
	end
	for _, m in ipairs(d.missions.list) do
		if m.id == kind and not m.claimed and m.progress < m.goal then
			m.progress = math.min(m.goal, m.progress + (amount or 1))
			if m.progress >= m.goal then
				G.Net.toast(player, "missionDone")
			end
		end
	end
	-- tutorial
	local step = d.tutorial or Quests.TUTORIAL_DONE
	if (step == 3 and kind == "steal") or (step == 4 and kind == "escape") or (step == 5 and kind == "open") then
		Quests.advance(player)
	end
end

function Quests.advance(player)
	local d = G.Data.profiles[player]
	if not d or d.tutorial >= Quests.TUTORIAL_DONE then
		return
	end
	d.tutorial += 1
	if d.tutorial >= Quests.TUTORIAL_DONE then
		local msg = Quests.give(player, { kind = "money", secs = 600 })
		G.Net.toast(player, "tutorialDone", msg[2])
	end
end

-- Comprobaciones de tutorial que dependen del estado (cada segundo)
function Quests.tick(player, s, d)
	local step = d.tutorial or Quests.TUTORIAL_DONE
	if step == 1 and s.onTreadmill and d.speed >= 30 then
		Quests.advance(player)
	elseif step == 2 and (s.combo or 1) > 1 then
		Quests.advance(player)
	elseif step == 3 and s.carrying then
		Quests.advance(player)
	elseif step == 6 and d.treadmill >= 2 then
		Quests.advance(player)
	end
	if s.onTreadmill then
		Quests.event(player, "train", 1)
	end
end

---------------------------------------------------------------------
-- Acciones del cliente
---------------------------------------------------------------------
function Quests.claimDaily(player)
	local d = G.Data.profiles[player]
	local canClaim, streak = Quests.dailyState(d)
	if not canClaim then
		return false
	end
	d.daily.last = today()
	d.daily.streak = streak
	local reward = Quests.DAILY[((streak - 1) % #Quests.DAILY) + 1]
	local msg = Quests.give(player, reward)
	G.Net.toast(player, msg[1], msg[2])
	return true
end

function Quests.claimMission(player, index)
	local d = G.Data.profiles[player]
	index = tonumber(index)
	local m = index and d.missions.list[index]
	if not m or m.claimed or m.progress < m.goal then
		return false
	end
	m.claimed = true
	for _, def in ipairs(Quests.POOL) do
		if def.id == m.id then
			local msg = Quests.give(player, def.reward)
			G.Net.toast(player, msg[1], msg[2])
		end
	end
	return true
end

function Quests.skipTutorial(player)
	local d = G.Data.profiles[player]
	d.tutorial = Quests.TUTORIAL_DONE
end

-- Datos para el cliente
function Quests.state(player)
	local d = G.Data.profiles[player]
	local canClaim, streak = Quests.dailyState(d)
	local list = {}
	for i, m in ipairs(d.missions.list) do
		local def
		for _, p in ipairs(Quests.POOL) do
			if p.id == m.id then
				def = p
			end
		end
		list[i] = { id = m.id, goal = m.goal, progress = m.progress, claimed = m.claimed, reward = def and def.reward }
	end
	return {
		dailyCan = canClaim,
		dailyStreak = streak,
		dailyRewards = Quests.DAILY,
		missions = list,
		tutorial = d.tutorial,
	}
end

function Quests.init(g)
	G = g
	C = g.Config
	local actions = G.Core.actions
	actions.claimDaily = Quests.claimDaily
	actions.claimMission = Quests.claimMission
	actions.skipTutorial = Quests.skipTutorial
end

return Quests
