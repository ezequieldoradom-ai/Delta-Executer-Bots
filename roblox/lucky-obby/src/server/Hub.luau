-- Lucky Obby Race — zona segura del vestíbulo (Shadow, petición del dueño)
--   · Dos tablones de clasificación: 🏆 VICTORIAS y 🪙 MONEDAS (mundiales con OrderedDataStore; en Studio, los del servidor)
--   · Santuario de la SUERTE: pulsa E para gastar monedas y subir de nivel → objetos más fuertes en el lucky block
--   · Tablón de cómo se juega y los 7 objetos
-- Todo en un anillo alrededor del vestíbulo, mirando al centro, sin tapar el arco de salida (+Z).
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Hub = {}
local G, C, K

local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 205, 60)

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

-- Tablón con marco, columnas y una SurfaceGui; devuelve el Frame de contenido
local function board(parent, cf, w, h, title, color)
	local back = part({ Name = "Board", Size = Vector3.new(w, h, 1), CFrame = cf, Color = Color3.fromRGB(28, 24, 44), Material = Enum.Material.SmoothPlastic }, parent)
	part({ Name = "BoardTrim", Size = Vector3.new(w + 1, 0.8, 1.4), CFrame = cf * CFrame.new(0, h / 2 + 0.4, 0), Color = color, Material = Enum.Material.Neon, CanCollide = false }, parent)
	part({ Name = "BoardTrim", Size = Vector3.new(w + 1, 0.8, 1.4), CFrame = cf * CFrame.new(0, -h / 2 - 0.4, 0), Color = color, Material = Enum.Material.Neon, CanCollide = false }, parent)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "BoardPost", Size = Vector3.new(1.4, h + 6, 1.4), CFrame = cf * CFrame.new(sx * (w / 2 + 0.7), -3, 0.2), Color = WHITE, Material = Enum.Material.SmoothPlastic }, parent)
	end
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.LightInfluence = 0
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	sg.Parent = back
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Size = UDim2.new(1, 0, 0.16, 0)
	t.Font = Enum.Font.LuckiestGuy
	t.TextScaled = true
	t.Text = title
	t.TextColor3 = color
	t.TextStrokeTransparency = 0.3
	t.Parent = sg
	local body = Instance.new("Frame")
	body.BackgroundTransparency = 1
	body.Size = UDim2.new(1, -30, 0.82, -10)
	body.Position = UDim2.new(0, 15, 0.17, 0)
	body.Parent = sg
	return body, back
end

local function row(body, i, n, left, right, color)
	local l = body:FindFirstChild("Row" .. i)
	if not l then
		l = Instance.new("TextLabel")
		l.Name = "Row" .. i
		l.BackgroundTransparency = i % 2 == 0 and 1 or 0.9
		l.BackgroundColor3 = WHITE
		l.Size = UDim2.new(1, 0, 1 / n, -2)
		l.Position = UDim2.new(0, 0, (i - 1) / n, 0)
		l.Font = Enum.Font.FredokaOne
		l.TextScaled = true
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.Parent = body
	end
	l.TextColor3 = color or WHITE
	l.Text = left == "" and "" or string.format("  %s   —   %s", left, right)
end

-- CLASIFICACIONES ------------------------------------------------------------
local boards = {} -- { body, stat, store }
local MEDAL = { Color3.fromRGB(255, 215, 0), Color3.fromRGB(205, 210, 220), Color3.fromRGB(215, 140, 70) }
local names = {}
local function nameOf(id)
	if names[id] then
		return names[id]
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(id)
	end)
	names[id] = ok and n or ("#" .. id)
	return names[id]
end

local function refreshBoards()
	for _, b in ipairs(boards) do
		local rows = {}
		-- 1) subir los datos de quien está en el servidor
		if b.store then
			for p, d in pairs(G.Data.profiles) do
				if typeof(p) == "Instance" and p.UserId > 0 then
					pcall(function()
						b.store:SetAsync(tostring(p.UserId), d[b.stat] or 0)
					end)
				end
			end
			local ok, pages = pcall(function()
				return b.store:GetSortedAsync(false, 10)
			end)
			if ok and pages then
				for _, e in ipairs(pages:GetCurrentPage()) do
					table.insert(rows, { name = nameOf(tonumber(e.key) or 0), value = e.value })
				end
			end
		end
		-- 2) sin DataStore (Studio) o vacío: los jugadores del servidor
		if #rows == 0 then
			for p, d in pairs(G.Data.profiles) do
				if typeof(p) == "Instance" then
					table.insert(rows, { name = p.DisplayName, value = d[b.stat] or 0 })
				end
			end
			table.sort(rows, function(a, c)
				return a.value > c.value
			end)
		end
		for i = 1, 10 do
			local r = rows[i]
			row(b.body, i, 10, r and string.format("#%d  %s", i, r.name) or "", r and tostring(r.value) or "", MEDAL[i])
		end
	end
end

-- SUERTE ---------------------------------------------------------------------
local luckGui
local function luckText(level)
	local nextCost = level < K.LUCK.MAX and K.luckCost(level) or nil
	return level, nextCost
end

local function buildLuck(parent, cf)
	-- templete: base, columnas, trébol gigante que gira y aura verde
	part({ Name = "LuckBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 14, 14), CFrame = cf * CFrame.new(0, 0.7, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 200, 110), Material = Enum.Material.SmoothPlastic }, parent)
	part({ Name = "LuckRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.5, 14.6, 14.6), CFrame = cf * CFrame.new(0, 0.65, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(120, 255, 150), Material = Enum.Material.Neon, CanCollide = false }, parent)
	for k = 0, 3 do
		local a = k * math.pi / 2 + math.pi / 4
		part({ Name = "LuckColumn", Size = Vector3.new(1.4, 12, 1.4), CFrame = cf * CFrame.new(math.cos(a) * 5.5, 7, math.sin(a) * 5.5), Color = WHITE, Material = Enum.Material.Marble }, parent)
	end
	part({ Name = "LuckRoof", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 15, 15), CFrame = cf * CFrame.new(0, 13.4, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = GOLD, Material = Enum.Material.Foil }, parent)
	-- trébol de cuatro hojas (cuatro bolas verdes y un tallo) que flota en el centro
	local clover = Instance.new("Model")
	clover.Name = "Clover"
	local center = cf * CFrame.new(0, 7, 0)
	for k = 0, 3 do
		local a = k * math.pi / 2
		part({ Name = "Leaf", Shape = Enum.PartType.Ball, Size = Vector3.new(2.6, 2.6, 0.8), CFrame = center * CFrame.Angles(0, 0, a) * CFrame.new(0, 1.3, 0), Color = Color3.fromRGB(70, 230, 110), Material = Enum.Material.Neon, CanCollide = false }, clover)
	end
	local stem = part({ Name = "Stem", Size = Vector3.new(0.4, 2.6, 0.4), CFrame = center * CFrame.new(0, -2, 0), Color = Color3.fromRGB(50, 160, 80), Material = Enum.Material.SmoothPlastic, CanCollide = false }, clover)
	clover.PrimaryPart = stem
	clover.Parent = parent
	local at = Instance.new("Attachment")
	at.Parent = stem
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 12
	pe.Lifetime = NumberRange.new(1.5, 2.5)
	pe.Speed = NumberRange.new(1, 3)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(Color3.fromRGB(180, 255, 190), Color3.fromRGB(60, 220, 110))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Parent = at
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(100, 255, 140)
	light.Range = 22
	light.Brightness = 1.5
	light.Parent = stem
	task.spawn(function()
		while clover.Parent do
			local t = os.clock()
			clover:PivotTo(center * CFrame.new(0, math.sin(t * 1.5) * 0.6, 0) * CFrame.Angles(0, t * 1.2, 0))
			task.wait(1 / 20)
		end
	end)
	-- cartel flotante y botón (E / tocar)
	local signPart = part({ Name = "LuckSign", Size = Vector3.new(1, 1, 1), CFrame = cf * CFrame.new(0, 17, 0), Transparency = 1, CanCollide = false }, parent)
	luckGui = Instance.new("BillboardGui")
	luckGui.Size = UDim2.fromScale(16, 5)
	luckGui.LightInfluence = 0
	luckGui.MaxDistance = 140
	luckGui.Parent = signPart
	local l = Instance.new("TextLabel")
	l.Name = "Label"
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.RichText = true
	l.Font = Enum.Font.LuckiestGuy
	l.TextColor3 = Color3.fromRGB(140, 255, 160)
	l.TextStrokeTransparency = 0.2
	l.Text = "🍀 SUERTE / LUCK"
	l.Parent = luckGui
	local pp = Instance.new("ProximityPrompt")
	pp.ActionText = "Mejorar suerte 🍀"
	pp.ObjectText = "Suerte de objetos"
	pp.HoldDuration = 0.3
	pp.MaxActivationDistance = 14
	pp.RequiresLineOfSight = false
	pp.Parent = signPart
	signPart.Position = (cf * CFrame.new(0, 4, 0)).Position
	luckGui.StudsOffsetWorldSpace = Vector3.new(0, 13, 0)
	pp.Triggered:Connect(function(player)
		local d = G.Data.profiles[player]
		if not d then
			return
		end
		local level = d.luck or 0
		if level >= K.LUCK.MAX then
			G.Net.Event:FireClient(player, "toast", { text = "🍀 MAX" })
			return
		end
		local cost = K.luckCost(level)
		if not G.Data.spend(player, cost) then
			G.Net.Event:FireClient(player, "toast", { text = string.format("🪙 %d / %d", d.coins, cost) })
			return
		end
		d.luck = level + 1
		G.Data.save(player)
		G.Net.Event:FireClient(player, "toast", { text = string.format("🍀 ¡Suerte nivel %d! Objetos más fuertes", d.luck) })
		Hub.refreshLuck(player)
	end)
end

-- El cartel de la suerte enseña TU nivel (cada jugador lo ve en su pantalla con el atributo LuckLevel)
function Hub.refreshLuck(player)
	local d = G.Data.profiles[player]
	if d and typeof(player) == "Instance" then
		local level, cost = luckText(d.luck or 0)
		player:SetAttribute("LuckLevel", level)
		player:SetAttribute("LuckCost", cost or -1)
	end
end

-- CÓMO SE JUEGA --------------------------------------------------------------
local function buildHelp(parent, cf)
	local body = board(parent, cf, 22, 18, "🎁 CÓMO SE JUEGA", Color3.fromRGB(120, 200, 255))
	local lines = {
		"🏁 Llega el primero a la meta",
		"🎁 Cada 9 s recibes un lucky block (E / botón)",
		"🪨 Piedra · 🏹 Arco · 🍌 Cáscara · 🌬️ Soplido",
		"🛡️ Escudo · 🔀 Cambiazo · ❄️ Congelación",
		"🍀 Más suerte = objetos más fuertes",
		"🪙 Monedas por puesto: 50 · 30 · 20",
	}
	for i, t in ipairs(lines) do
		row(body, i, #lines, t, "", WHITE)
		body["Row" .. i].Text = "  " .. t
	end
end

function Hub.init(g)
	G = g
	K = g.Config
	C = g.Config.COURSE
	local f = Instance.new("Folder")
	f.Name = "Hub"
	local c = C.LOBBY - Vector3.new(0, 3, 0) -- suelo del vestíbulo
	local function ringCF(angleDeg, r)
		local a = math.rad(angleDeg)
		local pos = c + Vector3.new(math.sin(a) * r, 0, math.cos(a) * r)
		return CFrame.lookAt(pos, Vector3.new(c.X, pos.Y, c.Z))
	end
	-- (0º = hacia la carrera: ahí está el arco; los tablones van detrás y a los lados)
	local winsBody = board(f, ringCF(150, 26) * CFrame.new(0, 11, 0), 20, 16, "🏆 VICTORIAS", GOLD)
	local coinsBody = board(f, ringCF(210, 26) * CFrame.new(0, 11, 0), 20, 16, "🪙 MONEDAS", Color3.fromRGB(255, 170, 60))
	buildHelp(f, ringCF(90, 27) * CFrame.new(0, 11, 0))
	buildLuck(f, ringCF(270, 22))
	f.Parent = workspace
	local wins, coins
	if not RunService:IsStudio() then
		pcall(function()
			wins = DataStoreService:GetOrderedDataStore("LuckyObby_Wins_v1")
			coins = DataStoreService:GetOrderedDataStore("LuckyObby_Coins_v1")
		end)
	end
	table.insert(boards, { body = winsBody, stat = "wins", store = wins })
	table.insert(boards, { body = coinsBody, stat = "coins", store = coins })
	-- nivel de suerte de cada jugador (para su cartel) y refresco de tablones
	local function onPlayer(p)
		task.spawn(function()
			for _ = 1, 50 do
				if G.Data.profiles[p] then
					break
				end
				task.wait(0.2)
			end
			Hub.refreshLuck(p)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
	task.spawn(function()
		task.wait(5)
		while true do
			pcall(refreshBoards)
			task.wait(RunService:IsStudio() and 10 or 90)
		end
	end)
end

return Hub
