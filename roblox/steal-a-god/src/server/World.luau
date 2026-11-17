-- Construcción del mundo: zona segura con parcelas, plaza, pasillo con 6 zonas y guardianes
local Lighting = game:GetService("Lighting")
local CollectionService = game:GetService("CollectionService")

local World = {}
local G

World.PLOT_SIZE = 56
World.SAFE_Z = 102 -- por debajo de esta Z estás a salvo
World.plots = {}
World.zoneParts = {}
World.guardians = {}
World.boards = {}

local root

local function part(props)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or root
	return p
end

local function billboard(adornee, text, color, size, offset)
	local bb = Instance.new("BillboardGui")
	size = size or UDim2.fromOffset(260, 60)
	-- tamaño en studs: se hace pequeño con la distancia, como un objeto real
	bb.Size = UDim2.fromScale(size.X.Offset / 24, size.Y.Offset / 24)
	bb.StudsOffset = offset or Vector3.new(0, 4, 0)
	bb.AlwaysOnTop = false
	bb.LightInfluence = 0
	bb.MaxDistance = 90
	bb.Adornee = adornee
	local label = Instance.new("TextLabel")
	label.Name = "Label"
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.Font = Enum.Font.FredokaOne
	label.TextScaled = true
	label.RichText = true
	label.Text = text
	label.TextColor3 = color or Color3.new(1, 1, 1)
	label.TextStrokeTransparency = 0.2
	label.Parent = bb
	bb.Parent = adornee
	return bb
end
World.billboard = billboard

function World.zoneStart(i)
	return G.Config.CORRIDOR_START + (i - 1) * G.Config.ZONE_LENGTH
end

function World.zoneAt(z)
	if z < G.Config.CORRIDOR_START then
		return 0
	end
	return math.clamp(math.floor((z - G.Config.CORRIDOR_START) / G.Config.ZONE_LENGTH) + 1, 1, #G.Config.ZONES)
end

function World.inCorridor(pos)
	return pos.Z >= G.Config.CORRIDOR_START - 2 and math.abs(pos.X) <= G.Config.CORRIDOR_HALF_WIDTH + 4
end

---------------------------------------------------------------------
-- Iluminación cinematográfica
---------------------------------------------------------------------
local function setupLighting()
	Lighting.ClockTime = 14
	Lighting.Brightness = 2.5
	Lighting.OutdoorAmbient = Color3.fromRGB(140, 130, 150)
	Lighting.Ambient = Color3.fromRGB(70, 60, 80)
	local atm = Instance.new("Atmosphere")
	atm.Density = 0.32
	atm.Haze = 1.6
	atm.Glare = 0.4
	atm.Color = Color3.fromRGB(255, 225, 190)
	atm.Decay = Color3.fromRGB(120, 90, 160)
	atm.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.8
	bloom.Size = 30
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.12
	rays.Spread = 0.8
	rays.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Grade"
	cc.Saturation = 0.15
	cc.Contrast = 0.08
	cc.TintColor = Color3.fromRGB(255, 244, 230)
	cc.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.StarCount = 4000
	sky.Parent = Lighting
end

---------------------------------------------------------------------
-- Parcelas
---------------------------------------------------------------------
local PLOT_TIERS = {
	{ upTo = 2, color = Color3.fromRGB(120, 120, 125), mat = Enum.Material.Slate, trim = Color3.fromRGB(90, 90, 95), columns = 2 },
	{ upTo = 4, color = Color3.fromRGB(200, 190, 170), mat = Enum.Material.Limestone, trim = Color3.fromRGB(170, 160, 140), columns = 4 },
	{ upTo = 9, color = Color3.fromRGB(235, 235, 240), mat = Enum.Material.Marble, trim = Color3.fromRGB(210, 210, 215), columns = 6 },
	{ upTo = 14, color = Color3.fromRGB(240, 240, 245), mat = Enum.Material.Marble, trim = Color3.fromRGB(230, 190, 70), columns = 8 },
	{ upTo = 19, color = Color3.fromRGB(250, 220, 120), mat = Enum.Material.Foil, trim = Color3.fromRGB(255, 240, 180), columns = 8 },
	{ upTo = 24, color = Color3.fromRGB(200, 240, 255), mat = Enum.Material.Glass, trim = Color3.fromRGB(90, 230, 255), columns = 10 },
	{ upTo = 99, color = Color3.fromRGB(255, 255, 255), mat = Enum.Material.Neon, trim = Color3.fromRGB(255, 220, 120), columns = 12 },
}

local function tierFor(level)
	for _, t in ipairs(PLOT_TIERS) do
		if level <= t.upTo then
			return t
		end
	end
	return PLOT_TIERS[#PLOT_TIERS]
end

-- Disposición dentro de la parcela (coordenadas locales; +Z mira hacia la plaza)
local function pedestalOffset(i)
	local col = (i - 1) % 6
	local row = math.floor((i - 1) / 6)
	return Vector3.new(-13.75 + col * 5.5, 0, 11 - row * 5.2)
end

local function altarOffset(i)
	return Vector3.new(-22.5 + (i - 1) * 5, 0, -23)
end

-- 6 parcelas: 3 a cada lado de la plaza, mirando al centro
local PLOT_SPOTS = {
	{ x = -66, z = -58, yaw = 90 },
	{ x = -66, z = 0, yaw = 90 },
	{ x = -66, z = 58, yaw = 90 },
	{ x = 66, z = -58, yaw = -90 },
	{ x = 66, z = 0, yaw = -90 },
	{ x = 66, z = 58, yaw = -90 },
}

local function buildPlot(index)
	local spot = PLOT_SPOTS[index]
	local cf = CFrame.new(spot.x, 0, spot.z) * CFrame.Angles(0, math.rad(spot.yaw), 0)
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	local folder = Instance.new("Folder")
	folder.Name = "Plot" .. index
	folder.Parent = root
	local plot = { index = index, cf = cf, center = cf.Position, folder = folder, owner = nil, pedestals = {}, altars = {}, decor = {} }
	local S = World.PLOT_SIZE

	plot.base = part({ Name = "Base", Size = Vector3.new(S, 1, S), CFrame = at(0, 0.5, 0), Parent = folder })
	plot.sign = part({ Name = "Sign", Size = Vector3.new(1, 1, 1), CFrame = at(0, 13, S / 2 - 2), Transparency = 1, CanCollide = false, Parent = folder })
	plot.signGui = billboard(plot.sign, "", Color3.new(1, 1, 1), UDim2.fromOffset(380, 84), Vector3.new(0, 0, 0))
	plot.signGui.MaxDistance = 160

	plot.spawn = at(0, 4, S / 2 - 6).Position
	plot.spawnCF = CFrame.lookAt(plot.spawn, at(0, 4, 0).Position)

	-- Cinta de correr (esquina delantera)
	plot.treadmill = part({ Name = "Treadmill", Size = Vector3.new(7, 1, 13), CFrame = at(-S / 2 + 6, 1.4, S / 2 - 9), Color = Color3.fromRGB(35, 35, 45), Material = Enum.Material.SmoothPlastic, Parent = folder })
	for k = -1, 1, 2 do
		part({ Name = "Rail", Size = Vector3.new(0.5, 3, 13), CFrame = plot.treadmill.CFrame * CFrame.new(k * 3.8, 1.5, 0), Color = Color3.fromRGB(90, 230, 255), Material = Enum.Material.Neon, Parent = folder })
	end
	plot.treadmillGui = billboard(plot.treadmill, "", Color3.fromRGB(90, 230, 255), UDim2.fromOffset(200, 46), Vector3.new(0, 6, 0))

	-- Pedestales (hasta 36): sin colisión para poder pasar entre ellos
	for i = 1, 36 do
		local o = pedestalOffset(i)
		local p = part({ Name = "Pedestal" .. i, Size = Vector3.new(3.8, 1.2, 3.8), CFrame = at(o.X, 1.6, o.Z), Material = Enum.Material.Marble, Color = Color3.fromRGB(230, 230, 235), Transparency = 1, CanCollide = false, Parent = folder })
		plot.pedestals[i] = { part = p, statue = nil, godId = nil }
	end

	-- Altares para abrir sobres (hasta 8 + 2 del pase), al fondo
	for i = 1, G.Config.ALTARS_MAX + 2 do
		local o = altarOffset(i)
		local a = part({ Name = "Altar" .. i, Size = Vector3.new(4, 3.4, 4), CFrame = at(o.X, 2.7, o.Z), Material = Enum.Material.Basalt, Color = Color3.fromRGB(60, 55, 70), Parent = folder })
		local prompt = Instance.new("ProximityPrompt")
		prompt.ObjectText = "Altar"
		prompt.ActionText = "Open"
		prompt.HoldDuration = 0.4
		prompt.MaxActivationDistance = 10
		prompt.RequiresLineOfSight = false
		prompt.Enabled = false
		prompt.Parent = a
		local gui = billboard(a, "", Color3.new(1, 1, 1), UDim2.fromOffset(150, 60), Vector3.new(0, 4.5, 0))
		gui:SetAttribute("Altar", true)
		CollectionService:AddTag(gui, "Loc")
		prompt:SetAttribute("Kind", "open")
		CollectionService:AddTag(prompt, "LocPrompt")
		local glow = part({ Name = "Glow", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = a.Position + Vector3.new(0, 3, 0), Material = Enum.Material.Neon, Transparency = 1, CanCollide = false, Parent = folder })
		plot.altars[i] = { part = a, prompt = prompt, gui = gui, glow = glow }
	end

	World.plots[index] = plot
	World.styleplot(plot, 1)
	return plot
end

-- ¿Está esta posición dentro de la parcela?
function World.inPlot(plot, pos)
	local rel = plot.cf:PointToObjectSpace(pos)
	local h = World.PLOT_SIZE / 2 + 1
	return math.abs(rel.X) <= h and math.abs(rel.Z) <= h
end

function World.styleplot(plot, level)
	local t = tierFor(level)
	plot.base.Color = t.color
	plot.base.Material = t.mat
	for _, d in ipairs(plot.decor) do
		d:Destroy()
	end
	plot.decor = {}
	local S = World.PLOT_SIZE
	local half = S / 2 - 1.5
	local n = t.columns
	local perSide = math.max(1, math.ceil(n / 2))
	for i = 1, n do
		local side = (i % 2 == 0) and 1 or -1
		local k = math.ceil(i / 2)
		local z = perSide == 1 and -half or (-half + (k - 1) * (2 * half / (perSide - 1)))
		local h = level <= 2 and (5 + (i * 3) % 6) or 14
		local col = part({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 2.4, 2.4), CFrame = plot.cf * CFrame.new(side * half, 1 + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), Color = t.color, Material = t.mat, Parent = plot.folder })
		table.insert(plot.decor, col)
		if level > 2 then
			local cap = part({ Name = "Cap", Size = Vector3.new(3.2, 0.8, 3.2), CFrame = plot.cf * CFrame.new(side * half, 1.4 + h, z), Color = t.trim, Material = (t.mat == Enum.Material.Neon) and Enum.Material.Neon or Enum.Material.SmoothPlastic, Parent = plot.folder })
			table.insert(plot.decor, cap)
		end
	end
	-- Borde (abierto por delante, hacia la plaza)
	for _, e in ipairs({ { 0, -S / 2, S, 1 }, { -S / 2, 0, 1, S }, { S / 2, 0, 1, S } }) do
		local b = part({ Name = "Trim", Size = Vector3.new(e[3], 1.2, e[4]), CFrame = plot.cf * CFrame.new(e[1], 1.6, e[2]), Color = t.trim, Material = Enum.Material.SmoothPlastic, Parent = plot.folder })
		table.insert(plot.decor, b)
	end
	if level >= 20 then
		local halo = part({ Name = "Halo", Size = Vector3.new(S + 6, 0.4, S + 6), CFrame = plot.cf * CFrame.new(0, -0.3, 0), Color = t.trim, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Parent = plot.folder })
		table.insert(plot.decor, halo)
	end
end

function World.pedestalVisible(plot, count)
	for i, ped in ipairs(plot.pedestals) do
		ped.part.Transparency = i <= count and 0 or 1
	end
end

function World.altarVisible(plot, count)
	for i, a in ipairs(plot.altars) do
		local on = i <= count
		a.part.Transparency = on and 0 or 0.85
		a.gui.Enabled = on
	end
end

-- Estatua del dios sobre su pedestal, mirando a la plaza
function World.setStatue(plot, i, god)
	local ped = plot.pedestals[i]
	if not ped then
		return
	end
	if ped.godId == (god and god.id) then
		return
	end
	if ped.statue then
		ped.statue:Destroy()
		ped.statue = nil
	end
	ped.godId = god and god.id or nil
	if not god then
		return
	end
	local rarity = G.Config.RARITIES[god.r]
	local m = G.GodModel.build(god, rarity.color)
	G.GodModel.decorate(m, rarity)
	m:SetAttribute("Income", rarity.income)
	m:SetAttribute("Rarity", god.r)
	local lift = god.r >= 8 and 1.2 or 0
	local top = ped.part.CFrame * CFrame.new(0, 0.6 + lift, 0)
	m:ScaleTo(0.8)
	m:PivotTo(top * CFrame.Angles(0, math.rad(180), 0))
	local torso = m:FindFirstChild("Torso")
	if torso then
		local tag = billboard(torso, string.format("<b>%s</b>", god.name), rarity.id == 10 and Color3.fromRGB(210, 140, 255) or rarity.color, UDim2.fromOffset(130, 30), Vector3.new(0, 3.6, 0))
		tag.MaxDistance = 50
	end
	if lift > 0 then
		part({ Name = "Levitate", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 3.4, 3.4), CFrame = ped.part.CFrame * CFrame.new(0, 0.75, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = rarity.color, Material = Enum.Material.Neon, Transparency = 0.3, CanCollide = false, Parent = m })
	end
	m.Parent = plot.folder
	ped.statue = m
end

---------------------------------------------------------------------
-- Plaza central: rankings
---------------------------------------------------------------------
local function buildBoard(name, x, color)
	local p = part({ Name = "Board_" .. name, Size = Vector3.new(26, 34, 1.5), Position = Vector3.new(x, 18, -112), Color = Color3.fromRGB(25, 22, 35), Material = Enum.Material.SmoothPlastic })
	p.CFrame = CFrame.new(p.Position) * CFrame.Angles(0, math.rad(180), 0)
	part({ Name = "Trim", Size = Vector3.new(27, 1, 2), Position = Vector3.new(x, 35.5, -112), Color = color, Material = Enum.Material.Neon })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.CanvasSize = Vector2.new(520, 680)
	sg.LightInfluence = 0
	sg.Parent = p
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 70)
	title.BackgroundTransparency = 1
	title.Font = Enum.Font.FredokaOne
	title.TextScaled = true
	title.TextColor3 = color
	title.Text = name
	title.Parent = sg
	local list = Instance.new("ScrollingFrame")
	list.Name = "List"
	list.Position = UDim2.fromOffset(10, 80)
	list.Size = UDim2.new(1, -20, 1, -90)
	list.BackgroundTransparency = 1
	list.ScrollBarThickness = 6
	list.AutomaticCanvasSize = Enum.AutomaticSize.Y
	list.CanvasSize = UDim2.new()
	list.Parent = sg
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 4)
	layout.Parent = list
	return { part = p, gui = sg, list = list, title = title }
end

---------------------------------------------------------------------
-- Pasillo con zonas
---------------------------------------------------------------------
local function decorZone(i, z0, zone)
	local L = G.Config.ZONE_LENGTH
	local function side(fn)
		for k = 0, 5 do
			local z = z0 + 20 + k * 34
			fn(-50 - (k % 2) * 8, z)
			fn(50 + (k % 2) * 8, z)
		end
	end
	if i == 1 then -- columnas griegas
		side(function(x, z)
			local c = part({ Size = Vector3.new(22, 3.5, 3.5), Shape = Enum.PartType.Cylinder, Position = Vector3.new(x, 11, z), Color = zone.accent, Material = Enum.Material.Marble })
			c.CFrame = CFrame.new(c.Position) * CFrame.Angles(0, 0, math.rad(90))
		end)
	elseif i == 2 then -- árboles celtas
		side(function(x, z)
			part({ Size = Vector3.new(3, 20, 3), Position = Vector3.new(x, 10, z), Color = Color3.fromRGB(80, 55, 35), Material = Enum.Material.Wood })
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(16, 16, 16), Position = Vector3.new(x, 24, z), Color = Color3.fromRGB(40, 100, 50), Material = Enum.Material.Grass })
		end)
	elseif i == 3 then -- pirámides
		for _, x in ipairs({ -120, 120 }) do
			for s = 0, 6 do
				local w = 90 - s * 13
				part({ Size = Vector3.new(w, 8, w), Position = Vector3.new(x, 4 + s * 8, z0 + L / 2), Color = zone.accent, Material = Enum.Material.Sand })
			end
		end
	elseif i == 4 then -- templo azteca escalonado + selva
		for _, x in ipairs({ -110, 110 }) do
			for s = 0, 5 do
				local w = 70 - s * 11
				part({ Size = Vector3.new(w, 7, w), Position = Vector3.new(x, 3.5 + s * 7, z0 + L / 2), Color = zone.accent, Material = Enum.Material.Cobblestone })
			end
		end
		side(function(x, z)
			part({ Shape = Enum.PartType.Ball, Size = Vector3.new(14, 10, 14), Position = Vector3.new(x, 5, z), Color = Color3.fromRGB(30, 110, 50), Material = Enum.Material.Grass })
		end)
	elseif i == 5 then -- zigurat y muros azules de Babilonia
		for s = 0, 4 do
			local w = 100 - s * 18
			part({ Size = Vector3.new(w, 10, w), Position = Vector3.new(-130, 5 + s * 10, z0 + L / 2), Color = zone.ground, Material = Enum.Material.Brick })
		end
		side(function(x, z)
			part({ Size = Vector3.new(6, 26, 30), Position = Vector3.new(x, 13, z), Color = zone.accent, Material = Enum.Material.Glass })
		end)
	elseif i == 6 then -- pinos nevados
		side(function(x, z)
			part({ Size = Vector3.new(2.5, 10, 2.5), Position = Vector3.new(x, 5, z), Color = Color3.fromRGB(80, 55, 35), Material = Enum.Material.Wood })
			for s = 0, 3 do
				local w = 14 - s * 3
				part({ Size = Vector3.new(w, 4, w), Position = Vector3.new(x, 11 + s * 4, z), Color = s == 3 and Color3.new(1, 1, 1) or Color3.fromRGB(30, 80, 60), Material = s == 3 and Enum.Material.Snow or Enum.Material.Grass })
			end
		end)
	end
end

-- Guardianes construidos con piezas
function World.makeGuardian(i)
	local zone = G.Config.ZONES[i]
	local gd = zone.guardian
	local s = 1 + (i - 1) * 0.12
	local m = Instance.new("Model")
	m.Name = "Guardian" .. i
	local rootPart = part({ Name = "Root", Size = Vector3.new(8 * s, 8 * s, 12 * s), Position = Vector3.new(0, 9 * s, 0), Color = gd.color, Material = Enum.Material.SmoothPlastic, CanCollide = false, Parent = m })
	local function add(name, size, offset, color, mat, shape)
		local p = part({ Name = name, Size = size * s, Color = color or gd.color, Material = mat or Enum.Material.SmoothPlastic, CanCollide = false, Parent = m })
		if shape then
			p.Shape = shape
		end
		p.CFrame = rootPart.CFrame * CFrame.new(offset * s)
		local w = Instance.new("WeldConstraint")
		w.Part0 = rootPart
		w.Part1 = p
		w.Parent = p
		p.Anchored = false
		return p
	end
	-- patas
	for _, o in ipairs({ Vector3.new(-3, -6, -4), Vector3.new(3, -6, -4), Vector3.new(-3, -6, 4), Vector3.new(3, -6, 4) }) do
		add("Leg", Vector3.new(2.4, 5, 2.4), o)
	end
	local headColor = gd.color
	if gd.kind == "sphinx" then
		headColor = Color3.fromRGB(230, 200, 140)
	end
	local head
	if gd.kind ~= "dullahan" then
		head = add("Head", Vector3.new(6, 6, 6), Vector3.new(0, 4, -8), headColor)
		add("EyeL", Vector3.new(1, 1, 0.4), Vector3.new(-1.5, 5, -11.1), Color3.fromRGB(255, 60, 40), Enum.Material.Neon)
		add("EyeR", Vector3.new(1, 1, 0.4), Vector3.new(1.5, 5, -11.1), Color3.fromRGB(255, 60, 40), Enum.Material.Neon)
	else
		add("Flame", Vector3.new(3, 3, 3), Vector3.new(0, 6, -6), Color3.fromRGB(120, 255, 120), Enum.Material.Neon, Enum.PartType.Ball)
	end
	if gd.kind == "minotaur" then
		add("HornL", Vector3.new(1, 1, 4), Vector3.new(-3.5, 7.5, -8), Color3.fromRGB(240, 230, 210))
		add("HornR", Vector3.new(1, 1, 4), Vector3.new(3.5, 7.5, -8), Color3.fromRGB(240, 230, 210))
	elseif gd.kind == "sphinx" then
		add("Nemes", Vector3.new(7, 3, 6.5), Vector3.new(0, 7, -7.5), Color3.fromRGB(40, 70, 170))
	elseif gd.kind == "jaguar" then
		for k = 1, 6 do
			add("Spot", Vector3.new(1.4, 0.3, 1.4), Vector3.new(-2.5 + (k % 3) * 2.5, 4.1, -3 + math.floor(k / 3) * 3), Color3.fromRGB(40, 25, 15))
		end
	elseif gd.kind == "lamassu" then
		add("WingL", Vector3.new(0.5, 6, 12), Vector3.new(-4.5, 5, 0), Color3.fromRGB(220, 200, 150))
		add("WingR", Vector3.new(0.5, 6, 12), Vector3.new(4.5, 5, 0), Color3.fromRGB(220, 200, 150))
		add("Beard", Vector3.new(4, 3, 1), Vector3.new(0, 1.5, -11), Color3.fromRGB(60, 40, 30))
	elseif gd.kind == "fenrir" then
		add("EarL", Vector3.new(1.5, 3, 1), Vector3.new(-2, 8, -7), gd.color)
		add("EarR", Vector3.new(1.5, 3, 1), Vector3.new(2, 8, -7), gd.color)
		add("Chain", Vector3.new(8.5, 1, 1), Vector3.new(0, 1, -5), Color3.fromRGB(180, 180, 190), Enum.Material.Metal)
	end
	add("Tail", Vector3.new(1, 1, 6), Vector3.new(0, 2, 9))
	m.PrimaryPart = rootPart
	-- contorno amenazante y materiales
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and p.Material == Enum.Material.SmoothPlastic then
			p.Material = (gd.kind == "fenrir" or gd.kind == "jaguar") and Enum.Material.Fabric or Enum.Material.Slate
		end
	end
	local hl = Instance.new("Highlight")
	hl.OutlineColor = Color3.fromRGB(255, 60, 50)
	hl.FillColor = Color3.fromRGB(255, 40, 40)
	hl.FillTransparency = 0.9
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = m
	local smoke = Instance.new("ParticleEmitter")
	smoke.Rate = 6
	smoke.Lifetime = NumberRange.new(1.5, 2.5)
	smoke.Speed = NumberRange.new(1, 3)
	smoke.Color = ColorSequence.new(Color3.fromRGB(80, 20, 20))
	smoke.Transparency = NumberSequence.new(0.6, 1)
	smoke.Size = NumberSequence.new(2, 5)
	smoke.Parent = rootPart
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 80, 60)
	light.Range = 18
	light.Brightness = 2
	light.Parent = head or rootPart
	local gbb = billboard(rootPart, "", Color3.fromRGB(255, 90, 80), UDim2.fromOffset(260, 60), Vector3.new(0, 10 * s, 0))
	gbb:SetAttribute("Guardian", i)
	CollectionService:AddTag(gbb, "Loc")
	m.Parent = root
	return m, 9 * s
end

local function buildCorridor()
	local C = G.Config
	local L = C.ZONE_LENGTH
	local W = C.CORRIDOR_HALF_WIDTH
	for i, zone in ipairs(C.ZONES) do
		local z0 = World.zoneStart(i)
		local zp = {}
		zp.floor = part({ Name = "Zone" .. i, Size = Vector3.new(W * 2 + 200, 4, L), Position = Vector3.new(0, -2, z0 + L / 2), Color = zone.ground, Material = (i == 3) and Enum.Material.Sand or (i == 6 and Enum.Material.Snow or Enum.Material.Grass) })
		-- muros invisibles a los lados del pasillo y bordes visibles
		for _, k in ipairs({ -1, 1 }) do
			part({ Name = "Wall", Size = Vector3.new(2, 60, L), Position = Vector3.new(k * (W + 1), 30, z0 + L / 2), Transparency = 1 })
			part({ Name = "Edge", Size = Vector3.new(2, 2, L), Position = Vector3.new(k * (W + 1), 1, z0 + L / 2), Color = zone.accent, Material = Enum.Material.SmoothPlastic })
		end
		-- arco de entrada con el requisito de velocidad
		local archColor = zone.accent
		part({ Name = "ArchL", Size = Vector3.new(4, 30, 4), Position = Vector3.new(-W, 15, z0), Color = archColor, Material = Enum.Material.Marble })
		part({ Name = "ArchR", Size = Vector3.new(4, 30, 4), Position = Vector3.new(W, 15, z0), Color = archColor, Material = Enum.Material.Marble })
		local top = part({ Name = "ArchTop", Size = Vector3.new(W * 2 + 4, 5, 5), Position = Vector3.new(0, 32, z0), Color = archColor, Material = Enum.Material.Marble })
		zp.sign = billboard(top, "", Color3.new(1, 1, 1), UDim2.fromOffset(520, 110), Vector3.new(0, 8, 0))
		zp.sign.MaxDistance = 140
		zp.sign:SetAttribute("Zone", i)
		CollectionService:AddTag(zp.sign, "Loc")
		if i > 1 then
			zp.curtain = part({ Name = "Curtain", Size = Vector3.new(W * 2, 30, 0.6), Position = Vector3.new(0, 15, z0), Color = Color3.fromRGB(255, 80, 80), Material = Enum.Material.ForceField, Transparency = 0.4, CanCollide = false })
		end
		-- puntos donde aparecen los sobres
		zp.spots = {}
		for row = 0, 1 do
			for col = -1, 1 do
				table.insert(zp.spots, Vector3.new(col * 22, 2.5, z0 + 65 + row * 70))
			end
		end
		zp.guardianHome = Vector3.new(0, 0, z0 + L - 25)
		decorZone(i, z0, zone)
		World.zoneParts[i] = zp
	end
	-- fin del pasillo (más zonas próximamente)
	local zEnd = World.zoneStart(#C.ZONES + 1)
	local wall = part({ Name = "EndWall", Size = Vector3.new(W * 2 + 4, 60, 4), Position = Vector3.new(0, 30, zEnd), Color = Color3.fromRGB(20, 15, 35), Material = Enum.Material.ForceField })
	World.endSign = billboard(wall, "", Color3.fromRGB(180, 160, 255), UDim2.fromOffset(520, 110), Vector3.new(0, 0, 0))
	World.endSign.MaxDistance = 140
	World.endSign:SetAttribute("EndSign", true)
	CollectionService:AddTag(World.endSign, "Loc")
	-- niebla de la noche en la entrada del pasillo
	World.nightGate = part({ Name = "NightGate", Size = Vector3.new(W * 2 + 4, 40, 2), Position = Vector3.new(0, 20, C.CORRIDOR_START - 4), Color = Color3.fromRGB(30, 10, 60), Material = Enum.Material.ForceField, Transparency = 1, CanCollide = false })
end

function World.init(g)
	G = g
	root = Instance.new("Folder")
	root.Name = "World"
	root.Parent = workspace
	setupLighting()
	-- suelo de la zona segura
	part({ Name = "SafeGround", Size = Vector3.new(260, 4, 270), Position = Vector3.new(0, -2, -5), Color = Color3.fromRGB(120, 175, 95), Material = Enum.Material.Grass })
	part({ Name = "Plaza", Size = Vector3.new(76, 0.4, 216), Position = Vector3.new(0, 0.2, -2), Color = Color3.fromRGB(225, 220, 205), Material = Enum.Material.Marble })
	for k = -3, 3 do
		part({ Name = "PlazaLine", Size = Vector3.new(76, 0.45, 1), Position = Vector3.new(0, 0.22, k * 28), Color = Color3.fromRGB(230, 190, 80), Material = Enum.Material.SmoothPlastic })
	end
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(12, 1, 12)
	spawn.Position = Vector3.new(0, 0.5, 30)
	spawn.Transparency = 1
	spawn.CanCollide = false
	spawn.Neutral = true
	spawn.Parent = root
	for i = 1, G.Config.MAX_PLAYERS_PLOTS do
		buildPlot(i)
	end
	World.boards.speed = buildBoard("SPEED", -28, Color3.fromRGB(90, 230, 255))
	World.boards.money = buildBoard("MONEY", 0, Color3.fromRGB(255, 210, 60))
	World.boards.time = buildBoard("TIME", 28, Color3.fromRGB(180, 140, 255))
	buildCorridor()
	for i = 1, #G.Config.ZONES do
		local model, height = World.makeGuardian(i)
		local home = World.zoneParts[i].guardianHome
		model:PivotTo(CFrame.new(home + Vector3.new(0, height, 0)) * CFrame.Angles(0, 0, 0))
		World.guardians[i] = { model = model, height = height, home = home + Vector3.new(0, height, 0), zone = i }
	end
end

return World
