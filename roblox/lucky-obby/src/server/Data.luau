-- Monedas y victorias guardadas (DataStore) y su marcador (leaderstats)
local DataStoreService = game:GetService("DataStoreService")
local RunService = game:GetService("RunService")

local Data = {}
local store = nil
Data.profiles = {} -- [player] = { coins, wins, luck }

local function key(player)
	return "p_" .. tostring(player.UserId)
end

local function stats(player)
	if typeof(player) ~= "Instance" then
		return
	end
	local d = Data.profiles[player]
	local ls = player:FindFirstChild("leaderstats")
	if not ls then
		ls = Instance.new("Folder")
		ls.Name = "leaderstats"
		for _, n in ipairs({ "🏆", "💰" }) do
			local v = Instance.new("IntValue")
			v.Name = n
			v.Parent = ls
		end
		ls.Parent = player
	end
	ls["🏆"].Value = d.wins
	ls["💰"].Value = d.coins
	player:SetAttribute("Best", d.best or 0) -- para el panel de abajo a la izquierda
	player:SetAttribute("Luck", d.luck or 0)
end
Data.refresh = stats

function Data.load(player)
	local d = { coins = 0, wins = 0, luck = 0, best = 0, trails = {}, trail = "", slapWins = 0, hillWins = 0, obbies = 0, obby = {}, loaded = true }
	if store and typeof(player) == "Instance" then
		-- hasta 3 intentos; si todos fallan, el perfil NO se guarda nunca (para no machacar sus datos con ceros)
		local ok, raw
		for attempt = 1, 3 do
			ok, raw = pcall(function()
				return store:GetAsync(key(player))
			end)
			if ok then
				break
			end
			task.wait(attempt * 1.5)
		end
		if not ok then
			d.loaded = false
			warn("[Data] no se pudieron cargar los datos de " .. player.Name .. ": esta sesión no se guardará")
		end
		if not player.Parent then
			return d -- se fue mientras cargaba
		end
		if ok and type(raw) == "table" then
			d.coins = math.max(0, math.floor(tonumber(raw.coins) or 0))
			d.wins = math.max(0, math.floor(tonumber(raw.wins) or 0))
			d.luck = math.clamp(math.floor(tonumber(raw.luck) or 0), 0, 10)
			d.best = math.max(0, tonumber(raw.best) or 0) -- mejor tiempo en segundos (0 = sin récord)
			d.slapWins = math.max(0, math.floor(tonumber(raw.slapWins) or 0)) -- mesas de guantazos ganadas
			d.hillWins = math.max(0, math.floor(tonumber(raw.hillWins) or 0)) -- partidas de rey de la colina ganadas
			d.obbies = math.max(0, math.floor(tonumber(raw.obbies) or 0)) -- obbys normales completados (total)
			if type(raw.obby) == "table" then -- por dificultad
				for _, k in ipairs({ "easy", "medium", "hard" }) do
					d.obby[k] = math.max(0, math.floor(tonumber(raw.obby[k]) or 0))
				end
			end
			if type(raw.trails) == "table" then
				for _, id in ipairs(raw.trails) do
					if type(id) == "string" then
						table.insert(d.trails, id)
					end
				end
			end
			d.trail = type(raw.trail) == "string" and raw.trail or ""
		end
	end
	Data.profiles[player] = d
	stats(player)
	return d
end

function Data.save(player, force)
	local d = Data.profiles[player]
	if not d or not store or typeof(player) ~= "Instance" or d.loaded == false then
		return false
	end
	-- como mucho un guardado cada 10 s por jugador (el límite de Roblox es 1 escritura cada 6 s por clave);
	-- lo que se pida antes queda pendiente y lo guarda el bucle
	if not force and d.savedAt and os.clock() - d.savedAt < 10 then
		d.dirty = true
		return false
	end
	d.savedAt = os.clock()
	d.dirty = false
	local ok = pcall(function()
		store:SetAsync(key(player), { coins = d.coins, wins = d.wins, luck = d.luck or 0, best = d.best or 0, trails = d.trails or {}, trail = d.trail or "", slapWins = d.slapWins or 0, hillWins = d.hillWins or 0, obbies = d.obbies or 0, obby = d.obby or {} })
	end)
	return ok
end

function Data.coins(player)
	local d = Data.profiles[player]
	return d and d.coins or 0
end

function Data.addCoins(player, n)
	local d = Data.profiles[player]
	if d then
		d.coins += math.max(0, math.floor(n))
		stats(player)
	end
end

-- Gasta monedas si alcanzan (devuelve true si se pudo)
function Data.spend(player, n)
	local d = Data.profiles[player]
	if not d or d.coins < n then
		return false
	end
	d.coins -= n
	stats(player)
	return true
end

-- Al salir: último guardado y fuera de la memoria (si no, el bucle seguiría guardando datos viejos
-- y pisaría lo que gane en otro servidor)
function Data.release(player)
	Data.save(player, true)
	Data.profiles[player] = nil
end

function Data.addHillWin(player)
	local d = Data.profiles[player]
	if d then
		d.hillWins = (d.hillWins or 0) + 1
		d.dirty = true
	end
end

function Data.addObby(player, id)
	local d = Data.profiles[player]
	if d then
		d.obbies = (d.obbies or 0) + 1
		d.obby = d.obby or {}
		d.obby[id] = (d.obby[id] or 0) + 1
		d.dirty = true
	end
end

function Data.addSlapWin(player)
	local d = Data.profiles[player]
	if d then
		d.slapWins = (d.slapWins or 0) + 1
		d.dirty = true
	end
end

function Data.addWin(player)
	local d = Data.profiles[player]
	if d then
		d.wins += 1
		stats(player)
	end
end

function Data.init()
	pcall(function()
		store = DataStoreService:GetDataStore("LuckyObby_v1")
	end)
	-- guardado cada 2 minutos y al cerrar el servidor
	task.spawn(function()
		while true do
			task.wait(15)
			for p, d in pairs(Data.profiles) do
				-- pendientes cada 15 s; todos cada 2 min
				if d.dirty or not d.savedAt or os.clock() - d.savedAt > 120 then
					Data.save(p)
				end
			end
		end
	end)
	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		for p in pairs(Data.profiles) do
			Data.save(p, true)
		end
	end)
end

return Data
