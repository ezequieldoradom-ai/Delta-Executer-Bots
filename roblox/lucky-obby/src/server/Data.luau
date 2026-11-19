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
		for _, n in ipairs({ "🏆", "🪙" }) do
			local v = Instance.new("IntValue")
			v.Name = n
			v.Parent = ls
		end
		ls.Parent = player
	end
	ls["🏆"].Value = d.wins
	ls["🪙"].Value = d.coins
end

function Data.load(player)
	local d = { coins = 0, wins = 0, luck = 0, best = 0, trails = {}, trail = "" }
	if store and typeof(player) == "Instance" then
		local ok, raw = pcall(function()
			return store:GetAsync(key(player))
		end)
		if ok and type(raw) == "table" then
			d.coins = math.max(0, math.floor(tonumber(raw.coins) or 0))
			d.wins = math.max(0, math.floor(tonumber(raw.wins) or 0))
			d.luck = math.clamp(math.floor(tonumber(raw.luck) or 0), 0, 10)
			d.best = math.max(0, tonumber(raw.best) or 0) -- mejor tiempo en segundos (0 = sin récord)
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

function Data.save(player)
	local d = Data.profiles[player]
	if not d or not store or typeof(player) ~= "Instance" then
		return false
	end
	local ok = pcall(function()
		store:SetAsync(key(player), { coins = d.coins, wins = d.wins, luck = d.luck or 0, best = d.best or 0, trails = d.trails or {}, trail = d.trail or "" })
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
			task.wait(120)
			for p in pairs(Data.profiles) do
				Data.save(p)
			end
		end
	end)
	game:BindToClose(function()
		if RunService:IsStudio() then
			return
		end
		for p in pairs(Data.profiles) do
			Data.save(p)
		end
	end)
end

return Data
