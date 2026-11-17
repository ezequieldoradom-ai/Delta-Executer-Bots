-- Guardado del progreso con DataStore
local DataStoreService = game:GetService("DataStoreService")

local Data = {}
Data.profiles = {} -- [player] = datos
Data.elapsed = {} -- [player] = segundos fuera del juego

local store = nil
local function getStore()
	if store == nil then
		local ok, res = pcall(function()
			return DataStoreService:GetDataStore("StealAGod_v1")
		end)
		store = ok and res or false
	end
	return store or nil
end

local function defaults()
	return {
		v = 1,
		money = 0,
		totalMoney = 0,
		speed = 0,
		bestSpeed = 0,
		playtime = 0,
		treadmill = 1,
		plot = 1,
		altars = 3,
		altarPacks = {}, -- { {r=, rem=, dawn=}, ... }
		queue = {}, -- sobres esperando altar
		gods = {}, -- [godId] = cantidad (para el índice)
		godList = nil, -- { {id=, kg=}, ... } cada dios con su peso
		coaches = {}, -- ["heracles:1"] = cantidad
		auras = {}, -- [auraId] = true
		aura = nil,
		weapon = "bat",
		savedAt = os.time(),
	}
end

local function merge(data)
	local d = defaults()
	if type(data) ~= "table" then
		return d
	end
	for k, v in pairs(data) do
		d[k] = v
	end
	return d
end

function Data.load(player)
	local s = getStore()
	local raw = nil
	if s then
		for attempt = 1, 3 do
			local ok, res = pcall(function()
				return s:GetAsync("u_" .. player.UserId)
			end)
			if ok then
				raw = res
				break
			end
			task.wait(attempt)
		end
	end
	local d = merge(raw)
	-- versiones antiguas: convertir los dioses a la lista con kilos
	if type(d.godList) ~= "table" then
		d.godList = {}
		for id, count in pairs(d.gods) do
			for _ = 1, count do
				table.insert(d.godList, { id = id, kg = 100 })
			end
		end
	end
	-- Progreso mientras estabas fuera: los sobres siguen abriéndose
	local elapsed = math.max(0, os.time() - (d.savedAt or os.time()))
	Data.elapsed[player] = raw and elapsed or 0
	for _, pack in ipairs(d.altarPacks) do
		pack.rem = math.max(0, (pack.rem or 0) - elapsed)
	end
	Data.profiles[player] = d
	return d
end

function Data.save(player)
	local d = Data.profiles[player]
	local s = getStore()
	if not d or not s then
		return false
	end
	d.savedAt = os.time()
	local ok = pcall(function()
		s:UpdateAsync("u_" .. player.UserId, function()
			return d
		end)
	end)
	return ok
end

function Data.release(player)
	Data.save(player)
	Data.profiles[player] = nil
	Data.elapsed[player] = nil
end

return Data
