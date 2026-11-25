-- Rankings globales (cada minuto) de velocidad, dinero y tiempo jugado
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")

local Boards = {}
local G

local stores = {}
local names = {}
local lastTop10 = { speed = {}, money = {}, time = {} }

-- Las cifras absurdas no caben en un entero: se guardan en escala logarítmica
local function encode(v)
	return math.floor(math.log10(math.max(1, v)) * 1e9)
end
local function decode(x)
	return 10 ^ (x / 1e9)
end

local function nameOf(userId)
	if names[userId] then
		return names[userId]
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(userId)
	end)
	names[userId] = ok and n or ("#" .. userId)
	return names[userId]
end

local COLORS = {
	Color3.fromRGB(255, 215, 0),
	Color3.fromRGB(200, 205, 215),
	Color3.fromRGB(205, 127, 50),
}

local function render(board, rows, fmt)
	for _, c in ipairs(board.list:GetChildren()) do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	for i, row in ipairs(rows) do
		local l = Instance.new("TextLabel")
		l.LayoutOrder = i
		l.Size = UDim2.new(1, 0, 0, 34)
		l.BackgroundTransparency = i % 2 == 0 and 1 or 0.85
		l.BackgroundColor3 = Color3.new(1, 1, 1)
		l.Font = Enum.Font.GothamBold
		l.TextSize = 24
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = COLORS[i] or Color3.new(1, 1, 1)
		l.Text = string.format("  #%d  %s  —  %s", i, row.name, fmt(row.value))
		l.Parent = board.list
	end
end

local function update()
	-- 1) subir los datos de los jugadores de este servidor
	for player in pairs(G.Core.sessions) do
		local d = G.Data.profiles[player]
		if d then
			local key = tostring(player.UserId)
			pcall(function()
				stores.speed:SetAsync(key, encode(d.bestSpeed))
			end)
			pcall(function()
				stores.money:SetAsync(key, encode(d.totalMoney))
			end)
			pcall(function()
				stores.time:SetAsync(key, math.floor(d.playtime))
			end)
		end
	end
	-- 2) leer el top 50 de cada uno
	local defs = {
		{ id = "speed", fmt = function(x)
			return "⚡ " .. G.Format.num(decode(x))
		end },
		{ id = "money", fmt = function(x)
			return "💰 " .. G.Format.num(decode(x))
		end },
		{ id = "time", fmt = function(x)
			return "⏱️ " .. G.Format.time(x)
		end },
	}
	for _, def in ipairs(defs) do
		local ok, pages = pcall(function()
			return stores[def.id]:GetSortedAsync(false, 50)
		end)
		if ok and pages then
			local rows = {}
			local top10 = {}
			for _, entry in ipairs(pages:GetCurrentPage()) do
				local uid = tonumber(entry.key)
				table.insert(rows, { name = uid and nameOf(uid) or entry.key, value = entry.value })
				if #rows <= 10 and uid then
					top10[uid] = true
				end
			end
			render(G.World.boards[def.id], rows, def.fmt)
			-- aviso al entrar en el top 10
			for player in pairs(G.Core.sessions) do
				local uid = player.UserId
				if top10[uid] and not lastTop10[def.id][uid] and next(lastTop10[def.id]) ~= nil then
					G.Net.announce("all", "top10", { player.DisplayName, { stat = def.id } }, { color = "#FFD23F", big = true })
				end
			end
			lastTop10[def.id] = top10
		end
	end
end

function Boards.init(g)
	G = g
	local ok = pcall(function()
		stores.speed = DataStoreService:GetOrderedDataStore("LB_Speed_v1")
		stores.money = DataStoreService:GetOrderedDataStore("LB_Money_v1")
		stores.time = DataStoreService:GetOrderedDataStore("LB_Time_v1")
	end)
	Boards.enabled = ok
	G.World.boards.speed.title.Text = "⚡ SPEED / VELOCIDAD"
	G.World.boards.money.title.Text = "💰 MONEY / DINERO"
	G.World.boards.time.title.Text = "⏱️ TIME / TIEMPO"
end

function Boards.start()
	if not Boards.enabled then
		return
	end
	task.spawn(function()
		task.wait(10)
		while true do
			pcall(update)
			task.wait(60)
		end
	end)
end

return Boards
