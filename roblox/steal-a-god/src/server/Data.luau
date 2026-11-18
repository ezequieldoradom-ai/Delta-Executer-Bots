-- Guardado del progreso con DataStore, con:
--  * diferencia entre jugador nuevo, partida existente y ERROR de lectura (nunca se sobrescribe por un error)
--  * bloqueo de sesión (si el jugador está en otro servidor, no se pisan las partidas)
--  * validación de tipos y rangos de todo lo cargado
--  * reintentos al guardar y al salir
--  * límite de tamaño de la colección
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Data = {}
-- En Roblox Studio (Play) se juega con una partida en memoria que nunca se guarda:
-- las pruebas no tocan las partidas reales y funcionan sin "acceso de Studio a las API".
Data.STUDIO_MEMORY = RunService:IsStudio()
Data.profiles = {} -- [player] = datos
Data.elapsed = {} -- [player] = segundos fuera del juego
Data.KEY_PREFIX = "u_"
Data.STORE_NAME = "StealAGod_v1"
Data.LOCK_TIMEOUT = 600 -- un bloqueo sin renovar durante 10 min se considera abandonado
Data.GODLIST_MAX = 600 -- máximo de dioses guardados (se quitan los de menor valor)
Data.RECEIPTS_MAX = 60 -- compras recientes recordadas (evita entregas dobles)

local store = nil
local function getStore()
	if store == nil then
		local ok, res = pcall(function()
			return DataStoreService:GetDataStore(Data.STORE_NAME)
		end)
		store = ok and res or false
	end
	return store or nil
end

local function key(player)
	return Data.KEY_PREFIX .. player.UserId
end

local function defaults()
	return {
		v = 2,
		money = 0,
		totalMoney = 0,
		speed = 0,
		bestSpeed = 0,
		playtime = 0,
		treadmill = 1,
		plot = 1,
		altars = 3,
		altarPacks = {},
		queue = {},
		gods = {},
		godList = {},
		coaches = {},
		auras = {},
		aura = nil,
		weapon = "bat",
		settings = { sfx = true, music = true, particles = true, shake = true, othersAuras = true, ui = 2 },
		boosts = { speed = 0, shield = 0, luck = 0 }, -- fin de boosts comprados o ganados (os.time)
		openTokens = {}, -- "Abrir ya" pendientes por categoría
		receipts = {}, -- PurchaseId ya entregados
		-- misiones del día (day = día UTC, rr = cambios usados hoy), racha diaria y tutorial
		missions = { day = 0, rr = 0, list = {} }, -- list = { { id, goal, progress, claimed } }
		daily = { last = 0, streak = 0 }, -- last = último día UTC reclamado
		tutorial = 0, -- 0 = sin decidir (se decide al entrar), 1..6 = paso, 7 = terminado
		savedAt = os.time(),
	}
end

---------------------------------------------------------------------
-- Validación
---------------------------------------------------------------------
local function num(v, default, lo, hi)
	if type(v) ~= "number" or v ~= v or v == math.huge or v == -math.huge then
		return default
	end
	if lo and v < lo then
		v = lo
	end
	if hi and v > hi then
		v = hi
	end
	return v
end

local function packList(list, C, max)
	local out = {}
	if type(list) ~= "table" then
		return out
	end
	for _, p in ipairs(list) do
		if type(p) == "table" and C.RARITIES[p.r] then
			table.insert(out, { r = p.r, rem = num(p.rem, 0, 0, 7 * 86400), dawn = p.dawn == true, kg = num(p.kg, 100, 1, 5000) })
			if #out >= max then
				break
			end
		end
	end
	return out
end

-- Corrige cualquier dato roto o manipulado
function Data.sanitize(raw, C)
	local d = defaults()
	if type(raw) ~= "table" then
		return d
	end
	d.money = num(raw.money, 0, 0)
	d.totalMoney = num(raw.totalMoney, d.money, 0)
	d.speed = num(raw.speed, 0, 0)
	d.bestSpeed = math.max(num(raw.bestSpeed, 0, 0), d.speed)
	d.playtime = num(raw.playtime, 0, 0)
	d.treadmill = math.floor(num(raw.treadmill, 1, 1, C.TREADMILL_MAX))
	d.plot = math.floor(num(raw.plot, 1, 1, C.PLOT_MAX))
	d.altars = math.floor(num(raw.altars, C.ALTARS_BASE, C.ALTARS_BASE, C.ALTARS_MAX))
	d.altarPacks = packList(raw.altarPacks, C, C.ALTARS_MAX + 2)
	d.queue = packList(raw.queue, C, C.PACK_QUEUE_MAX)
	if type(raw.gods) == "table" then
		for id, count in pairs(raw.gods) do
			if C.GOD_BY_ID[id] then
				d.gods[id] = math.floor(num(count, 0, 0, 1e9))
			end
		end
	end
	if type(raw.godList) == "table" then
		for _, e in ipairs(raw.godList) do
			if type(e) == "table" and C.GOD_BY_ID[e.id] then
				-- mutación solo si existe (Dorado, Hielo, Diamante, Lava, Arcoíris)
				local mut = (type(e.mut) == "string" and C.MUTATION_BY_ID[e.mut]) and e.mut or nil
				table.insert(d.godList, { id = e.id, kg = math.floor(num(e.kg, 100, 1, 5000)), mut = mut })
			end
		end
	else
		-- versiones antiguas: los dioses no tenían kilos
		for id, count in pairs(d.gods) do
			for _ = 1, math.min(count, 50) do
				table.insert(d.godList, { id = id, kg = 100 })
			end
		end
	end
	if type(raw.coaches) == "table" then
		for k, v in pairs(raw.coaches) do
			local id, tier = tostring(k):match("^(%w+):(%d+)$")
			if id and tonumber(tier) and C.COACH_TIERS[tonumber(tier)] then
				d.coaches[k] = math.floor(num(v, 0, 0, 1e6))
			end
		end
	end
	if type(raw.auras) == "table" then
		for id in pairs(raw.auras) do
			if C.AURA_BY_ID[id] then
				d.auras[id] = true
			end
		end
	end
	d.aura = (raw.aura and d.auras[raw.aura]) and raw.aura or nil
	d.weapon = (type(raw.weapon) == "string" and C.WEAPONS[raw.weapon]) and raw.weapon or "bat"
	if type(raw.settings) == "table" then
		for _, k in ipairs({ "sfx", "music", "particles", "shake", "othersAuras" }) do
			d.settings[k] = raw.settings[k] ~= false
		end
		d.settings.ui = math.floor(num(raw.settings.ui, 2, 1, 3))
		d.settings.ownerPasses = raw.settings.ownerPasses == true
	end
	if type(raw.boosts) == "table" then
		d.boosts.speed = num(raw.boosts.speed, 0, 0)
		d.boosts.shield = num(raw.boosts.shield, 0, 0)
		d.boosts.luck = num(raw.boosts.luck, 0, 0)
	end
	-- misiones: solo ids conocidos, sin repetir, con el progreso dentro de su meta
	if type(raw.missions) == "table" then
		local m = raw.missions
		d.missions.day = math.floor(num(m.day, 0, 0, 1e7))
		d.missions.rr = math.floor(num(m.rr, 0, 0, 100))
		if type(m.list) == "table" then
			local seen = {}
			for _, e in ipairs(m.list) do
				local def = type(e) == "table" and C.QUEST_BY_ID[e.id]
				if def and not seen[e.id] then
					seen[e.id] = true
					local goal = math.floor(num(e.goal, def.goal, 1, 1e6))
					table.insert(d.missions.list, { id = e.id, goal = goal, progress = math.floor(num(e.progress, 0, 0, goal)), claimed = e.claimed == true })
					if #d.missions.list >= C.QUESTS.PER_DAY then
						break
					end
				end
			end
		end
	end
	if type(raw.daily) == "table" then
		d.daily.last = math.floor(num(raw.daily.last, 0, 0, 1e7))
		d.daily.streak = math.floor(num(raw.daily.streak, 0, 0, 1e6))
	end
	d.tutorial = math.floor(num(raw.tutorial, 0, 0, C.QUESTS.TUTORIAL_DONE))
	if type(raw.openTokens) == "table" then
		for _, tier in ipairs({ "low", "mid", "high" }) do
			d.openTokens[tier] = math.floor(num(raw.openTokens[tier], 0, 0, 1000))
		end
	end
	if type(raw.receipts) == "table" then
		for _, id in ipairs(raw.receipts) do
			if type(id) == "string" then
				table.insert(d.receipts, id)
			end
		end
	end
	d.savedAt = num(raw.savedAt, os.time(), 0)
	return d
end

-- Mantiene la colección dentro de un tamaño razonable: se quitan los de menos valor,
-- pero el índice (d.gods) no cambia.
function Data.trimGodList(d, C)
	if #d.godList <= Data.GODLIST_MAX then
		return
	end
	table.sort(d.godList, function(a, b)
		return C.RARITIES[C.GOD_BY_ID[a.id].r].income * a.kg * C.mutMult(a.mut) > C.RARITIES[C.GOD_BY_ID[b.id].r].income * b.kg * C.mutMult(b.mut)
	end)
	for i = #d.godList, Data.GODLIST_MAX + 1, -1 do
		d.godList[i] = nil
	end
end

function Data.addReceipt(d, purchaseId)
	table.insert(d.receipts, purchaseId)
	while #d.receipts > Data.RECEIPTS_MAX do
		table.remove(d.receipts, 1)
	end
end

function Data.hasReceipt(d, purchaseId)
	for _, id in ipairs(d.receipts) do
		if id == purchaseId then
			return true
		end
	end
	return false
end

---------------------------------------------------------------------
-- Carga con bloqueo de sesión
-- Devuelve: datos (o nil si hubo error y NO se debe jugar)
---------------------------------------------------------------------
function Data.load(player, C)
	if Data.STUDIO_MEMORY then
		local d = Data.sanitize(nil, C)
		Data.elapsed[player] = 0
		Data.profiles[player] = d
		return d, "new"
	end
	local s = getStore()
	if not s then
		return nil, "datastore"
	end
	local result, status = nil, nil
	for attempt = 1, 6 do
		local ok, err = pcall(function()
			s:UpdateAsync(key(player), function(old)
				local lock = type(old) == "table" and old._lock or nil
				if lock and lock.job ~= game.JobId and (os.time() - (lock.t or 0)) < Data.LOCK_TIMEOUT then
					status = "locked"
					return nil -- no tocar: la partida está abierta en otro servidor
				end
				status = old == nil and "new" or "existing"
				result = old
				local claimed = type(old) == "table" and old or {}
				claimed._lock = { job = game.JobId, t = os.time() }
				return claimed
			end)
		end)
		if ok and status ~= "locked" then
			break
		end
		if not ok then
			status = "error"
			warn("Error al cargar datos", player.UserId, err)
		end
		task.wait(math.min(2 * attempt, 6))
	end
	if status == "error" or status == "locked" or status == nil then
		-- Si sigue bloqueada tras ~30 s, el otro servidor seguramente ya se cerró:
		-- tomamos el bloqueo una última vez, sin perder datos.
		if status == "locked" then
			local ok = pcall(function()
				s:UpdateAsync(key(player), function(old)
					result = old
					status = old == nil and "new" or "existing"
					local claimed = type(old) == "table" and old or {}
					claimed._lock = { job = game.JobId, t = os.time() }
					return claimed
				end)
			end)
			if not ok then
				return nil, "error"
			end
		else
			return nil, status or "error"
		end
	end
	local d = Data.sanitize(result, C)
	local elapsed = status == "existing" and math.max(0, os.time() - d.savedAt) or 0
	Data.elapsed[player] = elapsed
	for _, pack in ipairs(d.altarPacks) do
		pack.rem = math.max(0, pack.rem - elapsed)
	end
	Data.trimGodList(d, C)
	Data.profiles[player] = d
	return d, status
end

---------------------------------------------------------------------
-- Guardado (solo si el bloqueo sigue siendo nuestro)
---------------------------------------------------------------------
function Data.save(player, releaseLock)
	local d = Data.profiles[player]
	if d and Data.STUDIO_MEMORY then
		return true -- partida de prueba: no se guarda
	end
	local s = getStore()
	if not d or not s then
		return false
	end
	d.savedAt = os.time()
	local lostLock = false
	local ok, err = pcall(function()
		s:UpdateAsync(key(player), function(old)
			local lock = type(old) == "table" and old._lock or nil
			if lock and lock.job ~= game.JobId and (os.time() - (lock.t or 0)) < Data.LOCK_TIMEOUT then
				lostLock = true
				return nil -- otro servidor tiene la partida: no la pisamos
			end
			local copy = table.clone(d)
			copy._lock = (not releaseLock) and { job = game.JobId, t = os.time() } or nil
			return copy
		end)
	end)
	if not ok then
		warn("Error al guardar", player.UserId, err)
	end
	return ok and not lostLock
end

-- Al salir: guarda con reintentos y libera el bloqueo
function Data.release(player)
	if not Data.profiles[player] then
		return true
	end
	local saved = false
	for attempt = 1, 4 do
		if Data.save(player, true) then
			saved = true
			break
		end
		task.wait(attempt)
	end
	Data.profiles[player] = nil
	Data.elapsed[player] = nil
	return saved
end

-- Para jugadores que salieron mientras se cargaba su partida
function Data.discard(player)
	local s = not Data.STUDIO_MEMORY and getStore()
	if s then
		pcall(function()
			s:UpdateAsync(key(player), function(old)
				if type(old) == "table" and old._lock and old._lock.job == game.JobId then
					old._lock = nil
					return old
				end
				return nil
			end)
		end)
	end
	Data.profiles[player] = nil
	Data.elapsed[player] = nil
end

return Data
