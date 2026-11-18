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
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Parent" and k ~= "Class" then
			p[k] = v
		end
	end
	p.Parent = props.Parent or root
	return p
end

-- Texturas propias encima del material (se tiñen con color)
local N = Enum.NormalId
local FACES_ALL = { N.Front, N.Back, N.Left, N.Right, N.Top, N.Bottom }
local FACES_SIDES = { N.Front, N.Back, N.Left, N.Right }
local FACES_TOP = { N.Top }
local function skin(p, key, tileU, color, transparency, faces, tileV)
	for _, f in ipairs(faces or FACES_ALL) do
		local t = Instance.new("Texture")
		t.Name = "Skin_" .. key
		t.Texture = G.Config.VFX[key]
		t.Face = f
		t.StudsPerTileU = tileU
		t.StudsPerTileV = tileV or tileU
		t.Color3 = color or Color3.new(1, 1, 1)
		t.Transparency = transparency or 0
		t:SetAttribute("BaseT", t.Transparency)
		t.Parent = p
	end
	return p
end
World.skin = skin
World.FACES = { all = FACES_ALL, sides = FACES_SIDES, top = FACES_TOP }
World.part = part -- part({ Name=..., Size=..., CFrame/Position=..., Color=..., Material=..., Parent=... }) → Part anclada
function World.getRoot()
	return root -- carpeta workspace.World
end

local function brazier(pos, color, parent, scale)
	scale = scale or 1
	local list = {}
	local function add(pp)
		pp.Parent = parent or root
		table.insert(list, pp)
		return pp
	end
	add(part({ Name = "BrazierBase", Size = Vector3.new(3.4, 1, 3.4) * scale, Position = pos + Vector3.new(0, 0.5, 0) * scale, Color = Color3.fromRGB(60, 50, 45), Material = Enum.Material.Slate, Parent = parent }))
	add(part({ Name = "BrazierPole", Size = Vector3.new(1, 6, 1) * scale, Position = pos + Vector3.new(0, 4, 0) * scale, Color = Color3.fromRGB(70, 55, 40), Material = Enum.Material.Metal, Parent = parent }))
	local bowl = add(part({ Name = "BrazierBowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.4, 4, 4) * scale, CFrame = CFrame.new(pos + Vector3.new(0, 7.4, 0) * scale) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil, Parent = parent }))
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0.6 * scale, 0, 0)
	att.Parent = bowl
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = G.Config.VFX.flame
	fire.Rate = 22
	fire.Lifetime = NumberRange.new(0.5, 0.9)
	fire.Speed = NumberRange.new(2, 4)
	fire.Acceleration = Vector3.new(0, 9, 0)
	fire.SpreadAngle = Vector2.new(25, 25)
	fire.EmissionDirection = Enum.NormalId.Right
	fire.LightEmission = 1
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 220, 130), color or Color3.fromRGB(255, 90, 30))
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.6 * scale), NumberSequenceKeypoint.new(1, 0.3) })
	fire.Transparency = NumberSequence.new(0.05, 1)
	fire.Parent = att
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 180, 100)
	light.Range = 18 * scale
	light.Brightness = 1.6
	light.Shadows = false
	light.Parent = att
	return list
end
World.brazier = brazier -- brazier(pos, colorLlama, parent, escala) → lista de piezas

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
	-- Luz viva y limpia (los números están en Config.LIGHT para que servidor y cliente coincidan)
	local L = G.Config.LIGHT
	Lighting.ClockTime = L.day.clock
	Lighting.Brightness = L.day.brightness
	Lighting.OutdoorAmbient = L.day.outdoor
	Lighting.Ambient = L.day.ambient
	Lighting.ShadowSoftness = 0.3
	Lighting.EnvironmentDiffuseScale = 1
	Lighting.EnvironmentSpecularScale = 1
	local atm = Instance.new("Atmosphere")
	atm.Density = L.atmo.density
	atm.Haze = L.atmo.haze
	atm.Glare = L.atmo.glare
	atm.Color = L.atmo.color
	atm.Decay = L.atmo.decay
	atm.Parent = Lighting
	local bloom = Instance.new("BloomEffect")
	bloom.Intensity = 0.75
	bloom.Size = 26
	bloom.Threshold = 1.7
	bloom.Parent = Lighting
	local rays = Instance.new("SunRaysEffect")
	rays.Intensity = 0.08
	rays.Spread = 0.7
	rays.Parent = Lighting
	local cc = Instance.new("ColorCorrectionEffect")
	cc.Name = "Grade"
	cc.Saturation = L.saturation
	cc.Contrast = L.contrast
	cc.TintColor = L.day.tint
	cc.Parent = Lighting
	local sky = Instance.new("Sky")
	sky.StarCount = 4000
	sky.Parent = Lighting
	-- nubes en movimiento
	pcall(function()
		local clouds = Instance.new("Clouds")
		clouds.Cover = 0.5
		clouds.Density = 0.6
		clouds.Color = Color3.new(1, 1, 1)
		clouds.Parent = workspace.Terrain
	end)
end

-- Detalles celestiales que enriquecen la plaza sin sustituir su estilo
-- mitológico, luminoso y de mármol original. Todo es decorativo y no colisionable.
local function buildFountainCrown(center)
	local gold = Color3.fromRGB(255, 211, 105)
	local ice = Color3.fromRGB(155, 225, 255)
	local crownFolder = Instance.new("Folder")
	crownFolder.Name = "CelestialFountainDetails"
	crownFolder.Parent = root
	for i = 1, 16 do
		local angle = (i - 1) / 16 * math.pi * 2
		local pos = center + Vector3.new(math.cos(angle) * 13.5, 18.5, math.sin(angle) * 13.5)
		local orb = part({
			Name = "CrownLight", Shape = Enum.PartType.Ball, Size = Vector3.new(0.85, 0.85, 0.85),
			Position = pos, Color = i % 2 == 0 and gold or ice, Material = Enum.Material.Neon,
			CanCollide = false, Parent = crownFolder,
		})
		if i % 4 == 0 then
			local light = Instance.new("PointLight")
			light.Color = orb.Color
			light.Range = 10
			light.Brightness = 0.65
			light.Shadows = false
			light.Parent = orb
		end
	end
	local heart = part({
		Name = "FountainHeart", Shape = Enum.PartType.Ball, Size = Vector3.new(2.2, 2.2, 2.2),
		Position = center + Vector3.new(0, 22, 0), Color = gold, Material = Enum.Material.Neon,
		CanCollide = false, Parent = crownFolder,
	})
	local heartLight = Instance.new("PointLight")
	heartLight.Color = Color3.fromRGB(255, 220, 150)
	heartLight.Range = 24
	heartLight.Brightness = 1.1
	heartLight.Shadows = false
	heartLight.Parent = heart
	-- Cuatro columnas finas enmarcan la fuente como un pequeño santuario.
	for _, sx in ipairs({ -1, 1 }) do
		for _, sz in ipairs({ -1, 1 }) do
			local pos = center + Vector3.new(sx * 21, 8, sz * 21)
			part({ Name = "SanctuaryColumn", Size = Vector3.new(1.5, 16, 1.5), Position = pos,
				Color = Color3.fromRGB(232, 222, 201), Material = Enum.Material.Marble,
				CanCollide = false, Parent = crownFolder })
			part({ Name = "SanctuaryCapital", Size = Vector3.new(2.4, 0.7, 2.4), Position = pos + Vector3.new(0, 8.2, 0),
				Color = gold, Material = Enum.Material.Foil, CanCollide = false, Parent = crownFolder })
		end
	end
end

---------------------------------------------------------------------
-- Parcelas
---------------------------------------------------------------------
local PLOT_TIERS = {
	{ upTo = 2, color = Color3.fromRGB(176, 118, 68), mat = Enum.Material.WoodPlanks, trim = Color3.fromRGB(120, 75, 40), columns = 4, planks = true },
	{ upTo = 4, color = Color3.fromRGB(225, 195, 150), mat = Enum.Material.Sandstone, trim = Color3.fromRGB(190, 140, 80), columns = 4 },
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

-- Cartel de mejora (suerte en la parcela, cinta delante): tablero con marco brillante, dos postes,
-- emblema que flota y un aviso para mejorar. El cliente escribe el texto en su idioma (etiqueta UpgradeSign)
-- y solo el dueño de la parcela ve el aviso (atributo Owner del ProximityPrompt).
local function upgradeSign(plot, kind, cf, color)
	local folder = plot.folder
	local wood = Color3.fromRGB(58, 40, 30)
	local board = part({ Name = kind == "luck" and "LuckSign" or "TreadSign", Size = Vector3.new(7.2, 4.6, 0.5), CFrame = cf * CFrame.new(0, 5, 0), Color = Color3.fromRGB(34, 26, 48), Material = Enum.Material.Slate, Parent = folder })
	part({ Name = "SignFrame", Size = Vector3.new(7.9, 5.3, 0.3), CFrame = cf * CFrame.new(0, 5, -0.25), Color = color, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	part({ Name = "SignCrest", Size = Vector3.new(8.4, 0.6, 0.9), CFrame = cf * CFrame.new(0, 7.75, 0), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil, Parent = folder })
	for k = -1, 1, 2 do
		local post = part({ Name = "SignPost", Size = Vector3.new(0.6, 7.6, 0.6), CFrame = cf * CFrame.new(k * 3.7, 3.8, -0.1), Color = wood, Material = Enum.Material.Wood, Parent = folder })
		skin(post, "planks", 2, Color3.new(1, 1, 1), 0.2)
	end
	local emblem = part({ Name = "SignEmblem", Shape = Enum.PartType.Ball, Size = Vector3.new(1.3, 1.3, 1.3), CFrame = cf * CFrame.new(0, 9, 0), Color = color, Material = Enum.Material.Neon, CanCollide = false, Parent = folder })
	emblem:SetAttribute("BobAmp", 0.35)
	CollectionService:AddTag(emblem, "FxBob")
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 12
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = emblem
	local gui = Instance.new("SurfaceGui")
	gui.Name = "SignGui"
	gui.Face = Enum.NormalId.Back -- mira hacia +Z del cartel (hacia quien llega)
	gui.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	gui.PixelsPerStud = 60
	gui.LightInfluence = 0
	gui.MaxDistance = 90
	gui:SetAttribute("Kind", kind)
	local function line(name, y, h, textColor)
		local l = Instance.new("TextLabel")
		l.Name = name
		l.BackgroundTransparency = 1
		l.Size = UDim2.new(0.92, 0, h, 0)
		l.Position = UDim2.new(0.04, 0, y, 0)
		l.TextScaled = true
		l.RichText = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = textColor
		l.TextStrokeTransparency = 0.3
		l.Text = ""
		l.Parent = gui
		return l
	end
	line("Title", 0.05, 0.26, color:Lerp(Color3.new(1, 1, 1), 0.35))
	line("Body", 0.36, 0.34, Color3.new(1, 1, 1))
	line("Cost", 0.73, 0.22, Color3.fromRGB(110, 255, 140))
	gui.Parent = board
	CollectionService:AddTag(gui, "UpgradeSign")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Upgrade"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 11
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Kind", kind == "luck" and "upgradeLuck" or "upgradeTreadmill")
	CollectionService:AddTag(prompt, "LocPrompt")
	prompt.Parent = board
	prompt.Triggered:Connect(function(player)
		G.Core.useSign(player, plot, kind)
	end)
	return { part = board, gui = gui, prompt = prompt }
end

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

	-- Cinta de correr: FUERA de la parcela, justo delante y a un lado de la entrada, paralela a la fachada
	-- (corres mirando hacia la puerta). Delante, hacia la plaza, su cartel para mejorarla.
	local treadAt = at(-17, 1.4, S / 2 + 8) * CFrame.Angles(0, math.rad(90), 0)
	part({ Name = "TreadBase", Size = Vector3.new(9.4, 1.4, 15.4), CFrame = treadAt * CFrame.new(0, -0.75, 0), Color = Color3.fromRGB(205, 195, 175), Material = Enum.Material.Marble, Parent = folder })
	plot.treadmill = part({ Name = "Treadmill", Size = Vector3.new(7, 1, 13), CFrame = treadAt, Color = Color3.fromRGB(35, 35, 45), Material = Enum.Material.SmoothPlastic, Parent = folder })
	for k = -1, 1, 2 do
		part({ Name = "Rail", Size = Vector3.new(0.5, 3, 13), CFrame = plot.treadmill.CFrame * CFrame.new(k * 3.8, 1.5, 0), Color = Color3.fromRGB(90, 230, 255), Material = Enum.Material.Neon, Parent = folder })
	end
	plot.treadmillGui = billboard(plot.treadmill, "", Color3.fromRGB(90, 230, 255), UDim2.fromOffset(200, 46), Vector3.new(0, 6, 0))
	-- chasis metálico, consola con pantalla y faldones
	local tcf = plot.treadmill.CFrame
	for k = -1, 1, 2 do
		part({ Name = "TreadSkirt", Size = Vector3.new(0.8, 1.6, 13.4), CFrame = tcf * CFrame.new(k * 3.9, -0.1, 0), Color = Color3.fromRGB(70, 75, 90), Material = Enum.Material.DiamondPlate, Parent = folder })
		part({ Name = "TreadPost", Size = Vector3.new(0.6, 4.4, 0.6), CFrame = tcf * CFrame.new(k * 3.6, 2.4, 6.2), Color = Color3.fromRGB(60, 62, 75), Material = Enum.Material.Metal, Parent = folder })
	end
	local console = part({ Name = "TreadConsole", Size = Vector3.new(7.4, 1.6, 1.4), CFrame = tcf * CFrame.new(0, 4.6, 6.3) * CFrame.Angles(math.rad(25), 0, 0), Color = Color3.fromRGB(45, 48, 60), Material = Enum.Material.Metal, Parent = folder })
	part({ Name = "TreadScreen", Size = Vector3.new(5, 0.9, 0.1), CFrame = console.CFrame * CFrame.new(0, 0, -0.72), Color = Color3.fromRGB(90, 230, 255), Material = Enum.Material.Neon, Parent = folder })
	plot.treadSign = upgradeSign(plot, "treadmill", at(-17, 0.4, S / 2 + 14.5), Color3.fromRGB(90, 230, 255))
	-- Cartel de la suerte: dentro de la parcela, en la esquina delantera (donde antes estaba la cinta)
	plot.luckSign = upgradeSign(plot, "luck", at(-20, 1, S / 2 - 9) * CFrame.Angles(0, math.rad(20), 0), Color3.fromRGB(90, 255, 120))

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
		-- altares a 5 studs: cartel más estrecho y a alturas alternas (par/impar) para que no se monten
		local gui = billboard(a, "", Color3.new(1, 1, 1), UDim2.fromOffset(118, 54), Vector3.new(0, i % 2 == 0 and 7.4 or 4.6, 0))
		gui:SetAttribute("Altar", true)
		CollectionService:AddTag(gui, "Loc")
		prompt:SetAttribute("Kind", "open")
		CollectionService:AddTag(prompt, "LocPrompt")
		local glow = part({ Name = "Glow", Shape = Enum.PartType.Ball, Size = Vector3.new(2.4, 2.4, 2.4), Position = a.Position + Vector3.new(0, 3, 0), Material = Enum.Material.Neon, Transparency = 1, CanCollide = false, Parent = folder })
		-- relieve tallado en los lados y losa dorada encima
		skin(a, "carved", 4, Color3.fromRGB(255, 215, 130), 0, FACES_SIDES, 3.4)
		local top = part({ Name = "AltarTop", Size = Vector3.new(4.6, 0.5, 4.6), CFrame = at(o.X, 4.65, o.Z), Material = Enum.Material.Foil, Color = Color3.fromRGB(240, 196, 92), CanCollide = false, Parent = folder })
		skin(top, "meander", 0.5, Color3.new(1, 1, 1), 0.2, FACES_SIDES)
		plot.altars[i] = { part = a, prompt = prompt, gui = gui, glow = glow, top = top }
	end

	folder:SetAttribute("PlotCF", cf)
	folder:SetAttribute("PlotSize", World.PLOT_SIZE)
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

-- Suelo de cada nivel de parcela: textura y tamaño de baldosa
local PLOT_FLOORS = {
	{ key = "planks", tile = 8 },
	{ key = "paving", tile = 7, grime = true },
	{ key = "paving", tile = 7 },
	{ key = "paving", tile = 7 },
	{ key = "paving", tile = 9 },
	{ key = "hexgrid", tile = 14 },
	{ key = "hexgrid", tile = 10 },
}

function World.styleplot(plot, level)
	local t, tierIndex = PLOT_TIERS[#PLOT_TIERS], #PLOT_TIERS
	for i, tt in ipairs(PLOT_TIERS) do
		if level <= tt.upTo then
			t, tierIndex = tt, i
			break
		end
	end
	plot.base.Color = t.color
	plot.base.Material = t.mat
	for _, c in ipairs(plot.base:GetChildren()) do
		if c:IsA("Texture") then
			c:Destroy()
		end
	end
	local fl = PLOT_FLOORS[tierIndex]
	skin(plot.base, fl.key, fl.tile, t.color:Lerp(Color3.new(1, 1, 1), 0.25), 0, FACES_TOP)
	if fl.grime then
		skin(plot.base, "grime", 30, Color3.new(1, 1, 1), 0.35, FACES_TOP)
	end
	for _, d in ipairs(plot.decor) do
		d:Destroy()
	end
	plot.decor = {}
	local S = World.PLOT_SIZE
	local cf = plot.cf
	local wood = tierIndex == 1
	local stoneMat = wood and Enum.Material.Wood or (t.mat == Enum.Material.Neon and Enum.Material.Marble or t.mat)
	local stoneColor = wood and Color3.fromRGB(150, 100, 60) or t.color
	local trimMat = (t.mat == Enum.Material.Neon or t.mat == Enum.Material.Glass) and Enum.Material.Neon or (tierIndex >= 4 and Enum.Material.Foil or stoneMat)
	local function add(props)
		props.Parent = plot.folder
		local pp = part(props)
		table.insert(plot.decor, pp)
		return pp
	end

	-- murete con remate alrededor (abierto por delante, hacia la plaza)
	local wallH = wood and 3 or 3.6
	for _, e in ipairs({ { 0, -S / 2, S, 1.4 }, { -S / 2, 0, 1.4, S }, { S / 2, 0, 1.4, S } }) do
		local w = add({ Name = "LowWall", Size = Vector3.new(e[3], wallH, e[4]), CFrame = cf * CFrame.new(e[1], 1 + wallH / 2, e[2]), Color = stoneColor, Material = stoneMat })
		skin(w, wood and "planks" or (tierIndex == 2 and "bricks" or "ashlar"), wood and 6 or 5, stoneColor, 0, FACES_SIDES)
		local cap = add({ Name = "Coping", Size = Vector3.new(e[3] + 0.6, 0.6, e[4] + 0.6), CFrame = cf * CFrame.new(e[1], 1.3 + wallH, e[2]), Color = t.trim, Material = trimMat })
		if tierIndex >= 3 then
			skin(cap, "meander", 0.6, Color3.new(1, 1, 1), 0.2, FACES_SIDES)
		end
	end

	-- pared del fondo (detrás de los altares) con frontón de templo desde el nivel 3
	local backH = wood and 7 or (8 + math.min(tierIndex, 6) * 1.5)
	local back = add({ Name = "BackWall", Size = Vector3.new(S, backH, 1.6), CFrame = cf * CFrame.new(0, 1 + backH / 2, -S / 2 - 0.8), Color = stoneColor, Material = stoneMat })
	skin(back, wood and "planks" or "ashlar", wood and 6 or 7, stoneColor, 0, { Enum.NormalId.Front, Enum.NormalId.Back })
	if not wood then
		skin(back, "grime", 24, Color3.new(1, 1, 1), 0.5, { Enum.NormalId.Front })
		-- paneles tallados y pilastras
		for k = -2, 2 do
			local x = k * (S / 5)
			add({ Name = "BackPilaster", Size = Vector3.new(2, backH, 2), CFrame = cf * CFrame.new(x + S / 10, 1 + backH / 2, -S / 2 + 0.2), Color = t.trim, Material = trimMat })
			local panel = add({ Name = "BackPanel", Size = Vector3.new(S / 5 - 4, backH * 0.55, 0.3), CFrame = cf * CFrame.new(x, 1 + backH * 0.55, -S / 2 + 0.1), Color = stoneColor:Lerp(Color3.new(0, 0, 0), 0.12), Material = stoneMat })
			skin(panel, "carved", S / 5 - 4, t.trim, 0, { Enum.NormalId.Front }, backH * 0.55)
		end
		add({ Name = "BackPilaster", Size = Vector3.new(2, backH, 2), CFrame = cf * CFrame.new(-S / 2 + 1, 1 + backH / 2, -S / 2 + 0.2), Color = t.trim, Material = trimMat })
		local cornice = add({ Name = "BackCornice", Size = Vector3.new(S + 2, 1.4, 3), CFrame = cf * CFrame.new(0, 1.7 + backH, -S / 2), Color = t.trim, Material = trimMat })
		skin(cornice, "meander", 1.4, Color3.new(1, 1, 1), 0.15, { Enum.NormalId.Front })
		if tierIndex >= 3 then
			local ph = 6 + tierIndex
			for _, sgn in ipairs({ -1, 1 }) do
				add({ Name = "Pediment", Class = "WedgePart", Size = Vector3.new(2.4, ph, S / 2 + 1), CFrame = cf * CFrame.new(sgn * (S / 4 + 0.5), 2.4 + backH + ph / 2, -S / 2) * CFrame.Angles(0, math.rad(-sgn * 90), 0), Color = stoneColor, Material = stoneMat })
			end
		end
	end

	-- columnas a los lados, con basa y capitel
	local half = S / 2 - 1.5
	local n = t.columns
	local perSide = math.max(1, math.ceil(n / 2))
	for i = 1, n do
		local side = (i % 2 == 0) and 1 or -1
		local k = math.ceil(i / 2)
		local z = perSide == 1 and -half or (-half + (k - 1) * (2 * half / (perSide - 1)))
		local h = wood and (5 + (i * 3) % 6) or (12 + tierIndex)
		add({ Name = "Column", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, 2.4, 2.4), CFrame = cf * CFrame.new(side * half, 1 + h / 2, z) * CFrame.Angles(0, 0, math.rad(90)), Color = t.color, Material = wood and Enum.Material.Wood or t.mat })
		if not wood then
			add({ Name = "ColumnBase", Size = Vector3.new(3.4, 1, 3.4), CFrame = cf * CFrame.new(side * half, 1.5, z), Color = t.trim, Material = trimMat })
			add({ Name = "Cap", Size = Vector3.new(3.4, 0.9, 3.4), CFrame = cf * CFrame.new(side * half, 1.45 + h, z), Color = t.trim, Material = trimMat })
		end
	end

	-- pórtico de entrada (delante, mirando a la plaza)
	local gateH = wood and 9 or 12 + tierIndex
	for _, sgn in ipairs({ -1, 1 }) do
		local pillar = add({ Name = "GatePillar", Size = Vector3.new(2.6, gateH, 2.6), CFrame = cf * CFrame.new(sgn * 10, 1 + gateH / 2, S / 2 - 1.3), Color = stoneColor, Material = stoneMat })
		skin(pillar, wood and "planks" or "ashlar", 4, stoneColor, 0, FACES_SIDES)
		add({ Name = "GateCap", Size = Vector3.new(3.4, 1, 3.4), CFrame = cf * CFrame.new(sgn * 10, 1.5 + gateH, S / 2 - 1.3), Color = t.trim, Material = trimMat })
		if tierIndex >= 3 then
			for _, pp in ipairs(brazier((cf * CFrame.new(sgn * 15, 1, S / 2 - 2)).Position, nil, plot.folder, 0.8)) do
				table.insert(plot.decor, pp)
			end
		end
	end
	local lintel = add({ Name = "GateLintel", Size = Vector3.new(23.4, 1.6, 3), CFrame = cf * CFrame.new(0, 2.8 + gateH, S / 2 - 1.3), Color = t.trim, Material = trimMat })
	skin(lintel, "meander", 1.6, Color3.new(1, 1, 1), 0.15, { Enum.NormalId.Front, Enum.NormalId.Back })

	-- alfombra central hasta los altares
	local rug = add({ Name = "Rug", Size = Vector3.new(6, 0.12, S - 8), CFrame = cf * CFrame.new(0, 1.06, 2), Color = tierIndex >= 5 and t.trim or Color3.fromRGB(150, 35, 45), Material = Enum.Material.Fabric, CanCollide = false })
	skin(rug, "meander", 1.4, Color3.fromRGB(255, 215, 120), 0.1, FACES_TOP, 1.4)
	if level >= 20 then
		add({ Name = "Halo", Size = Vector3.new(S + 6, 0.4, S + 6), CFrame = cf * CFrame.new(0, -0.3, 0), Color = t.trim, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false })
	end
end

function World.pedestalVisible(plot, count)
	plot.folder:SetAttribute("Capacity", count)
end

function World.altarVisible(plot, count)
	for i, a in ipairs(plot.altars) do
		local on = i <= count
		a.part.Transparency = on and 0 or 0.85
		a.gui.Enabled = on
		for _, d in ipairs(a.part:GetChildren()) do
			if d:IsA("Texture") then
				d.Transparency = on and (d:GetAttribute("BaseT") or 0) or 1
			end
		end
		if a.top then
			a.top.Transparency = on and 0 or 0.85
		end
	end
end

-- El dios aparece en su sitio de la parcela; el cliente lo hace pasear libremente
-- Aspecto de un dios mutado: cuerpo del material de la mutación, partículas y luz.
-- No toca la ropa del catálogo (accesorios) ni las piezas invisibles.
local MUTATION_LOOK = {
	gold = { material = Enum.Material.Foil, color = Color3.fromRGB(255, 205, 60), particle = "sparkle", rate = 7 },
	ice = { material = Enum.Material.Ice, color = Color3.fromRGB(175, 225, 255), particle = "sparkle", rate = 6, fall = true },
	diamond = { material = Enum.Material.Glass, color = Color3.fromRGB(200, 245, 255), particle = "sparkle", rate = 10 },
	lava = { material = Enum.Material.CrackedLava, color = Color3.fromRGB(255, 110, 40), particle = "flame", rate = 9 },
	rainbow = { material = Enum.Material.Neon, color = Color3.fromRGB(255, 120, 200), particle = "sparkle", rate = 12, rainbow = true },
	-- mitológicas: segundo emisor (extra) para que se distingan de un vistazo
	storm = { material = Enum.Material.Glass, color = Color3.fromRGB(150, 210, 255), particle = "sparkle", rate = 10,
		extra = { tex = "streak", rate = 14, life = 0.25, speed = 14, size = 2.2, parallel = true, colors = { Color3.new(1, 1, 1), Color3.fromRGB(90, 170, 255) } } },
	underworld = { material = Enum.Material.Basalt, color = Color3.fromRGB(45, 40, 55), particle = "flame", rate = 12,
		extra = { tex = "smoke", rate = 5, life = 1.8, speed = 2, size = 3.5, emission = 0.2, colors = { Color3.fromRGB(60, 255, 120), Color3.fromRGB(20, 40, 30) } } },
	cosmic = { material = Enum.Material.ForceField, color = Color3.fromRGB(150, 90, 255), particle = "sparkle", rate = 16,
		extra = { tex = "glow", rate = 4, life = 2.5, speed = 0.6, size = 4, emission = 0.6, colors = { Color3.fromRGB(80, 220, 255), Color3.fromRGB(190, 80, 255), Color3.fromRGB(255, 90, 200) } } },
	divine = { material = Enum.Material.Foil, color = Color3.fromRGB(255, 240, 190), particle = "sparkle", rate = 18,
		extra = { tex = "rays", rate = 1.2, life = 2.6, speed = 0, size = 7, emission = 0.55, locked = true, colors = { Color3.fromRGB(255, 250, 220), Color3.fromRGB(255, 200, 80) } } },
}
function World.applyMutation(m, mut)
	local def = mut and G.Config.MUTATION_BY_ID[mut]
	local look = mut and MUTATION_LOOK[mut]
	if not def or not look then
		return
	end
	m:SetAttribute("Mutation", mut)
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") and p.Transparency < 0.95 and p.Name ~= "HumanoidRootPart" and not p:FindFirstAncestorOfClass("Accessory") then
			p.Material = look.material
			p.Color = look.color
			if look.rainbow then
				p:SetAttribute("RainbowSpeed", 0.35)
				p:SetAttribute("RainbowSat", 0.6)
				CollectionService:AddTag(p, "FxRainbow")
			end
		end
	end
	local anchor = m:FindFirstChild("UpperTorso") or m:FindFirstChild("Torso") or m.PrimaryPart
	if not anchor then
		return
	end
	local att = Instance.new("Attachment")
	att.Name = "MutationFX"
	att.Parent = anchor
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = G.Config.VFX[look.particle]
	pe.Rate = look.rate
	pe.Lifetime = NumberRange.new(0.8, 1.6)
	pe.Speed = look.fall and NumberRange.new(0.5, 1.5) or NumberRange.new(1, 3)
	pe.Acceleration = look.fall and Vector3.new(0, -3, 0) or Vector3.new(0, 4, 0)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 0.8
	pe.Color = ColorSequence.new(def.color, Color3.new(1, 1, 1))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, look.particle == "flame" and 1.6 or 0.9), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new(0.1, 1)
	pe.Parent = att
	if look.rainbow then
		CollectionService:AddTag(pe, "FxRainbow")
	end
	local x = look.extra
	if x then
		local kp = {}
		for k, c in ipairs(x.colors) do
			kp[k] = ColorSequenceKeypoint.new((k - 1) / math.max(1, #x.colors - 1), c)
		end
		local e = Instance.new("ParticleEmitter")
		e.Name = "MutationExtra"
		e.Texture = G.Config.VFX[x.tex]
		e.Rate = x.rate
		e.Lifetime = NumberRange.new(x.life * 0.8, x.life)
		e.Speed = NumberRange.new(x.speed * 0.7, x.speed)
		e.SpreadAngle = Vector2.new(180, 180)
		e.Rotation = NumberRange.new(0, 360)
		e.RotSpeed = NumberRange.new(-30, 30)
		e.LightEmission = x.emission or 1
		e.LightInfluence = 0
		e.LockedToPart = x.locked == true
		e.ZOffset = x.locked and -1.5 or 0
		if x.parallel then
			e.Orientation = Enum.ParticleOrientation.VelocityParallel
		end
		e.Color = #kp > 1 and ColorSequence.new(kp) or ColorSequence.new(x.colors[1])
		e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, x.size * 0.6), NumberSequenceKeypoint.new(0.5, x.size), NumberSequenceKeypoint.new(1, x.size * 0.4) })
		e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.35), NumberSequenceKeypoint.new(0.75, 0.55), NumberSequenceKeypoint.new(1, 1) })
		e.Parent = att
	end
	local light = Instance.new("PointLight")
	light.Color = def.color
	light.Range = 10
	light.Brightness = 1.2
	light.Shadows = false
	light.Parent = att
end

function World.setStatue(plot, i, entry)
	local ped = plot.pedestals[i]
	if not ped then
		return
	end
	local key = entry and (entry.god.id .. ":" .. entry.kg .. ":" .. tostring(entry.mut)) or nil
	if ped.key == key then
		return
	end
	if ped.statue then
		ped.statue:Destroy()
		ped.statue = nil
	end
	ped.key = key
	if not entry then
		return
	end
	local god, kg = entry.god, entry.kg
	local rarity = G.Config.RARITIES[god.r]
	local mutDef = entry.mut and G.Config.MUTATION_BY_ID[entry.mut]
	local income = rarity.income * G.Config.kgMult(kg) * G.Config.mutMult(entry.mut)
	local m = G.GodModel.build(god, rarity.color)
	G.GodModel.decorate(m, rarity)
	World.applyMutation(m, entry.mut)
	m:SetAttribute("Income", income)
	m:SetAttribute("Rarity", god.r)
	m:SetAttribute("Kg", kg)
	m:SetAttribute("Slot", i)
	local scale = (m:GetAttribute("Avatar") and 0.85 or 0.7) * G.Config.kgScale(kg)
	m:ScaleTo(scale)
	local o = pedestalOffset(i)
	local lift = god.r >= 8 and 1.2 * scale or 0
	local pivotH = (m:GetAttribute("PivotH") or 0) * scale
	m:PivotTo(plot.cf * CFrame.new(o.X * 0.9, 1 + pivotH + lift, o.Z * 0.9) * CFrame.Angles(0, math.rad(180), 0))
	local head = m:FindFirstChild("Head") or m:FindFirstChild("Torso")
	if head then
		local color = rarity.id == 10 and Color3.fromRGB(210, 140, 255) or rarity.color
		local mutLine = mutDef and string.format('<font color="#%s">%s x%d</font> ', mutDef.color:ToHex(), mutDef.icon, mutDef.mult) or ""
		local tag = billboard(head, string.format("<b>%s</b> <font size=\"13\" color=\"#FFE9A8\">%d kg</font>\n%s<font color=\"#6CFF7A\">$%s/s</font>", god.name, kg, mutLine, G.Format.num(income)), color, UDim2.fromOffset(136, 46), Vector3.new(0, 2.2 * scale + 1.2, 0))
		tag.MaxDistance = 45 -- con la parcela llena, de lejos solo se veía una maraña de carteles
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
	-- marco de mármol con columnas y frontón dorado
	for _, sx in ipairs({ -1, 1 }) do
		local col = part({ Name = "BoardColumn", Size = Vector3.new(2.4, 37, 2.4), Position = Vector3.new(x + sx * 14.2, 18.5, -112), Color = Color3.fromRGB(235, 228, 212), Material = Enum.Material.Marble })
		skin(col, "grime", 14, Color3.new(1, 1, 1), 0.5, FACES_SIDES)
		part({ Name = "BoardCap", Size = Vector3.new(3.2, 1, 3.2), Position = Vector3.new(x + sx * 14.2, 37.5, -112), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil })
	end
	local lintel = part({ Name = "BoardLintel", Size = Vector3.new(32, 1.8, 3), Position = Vector3.new(x, 38.8, -112), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil })
	skin(lintel, "meander", 1.8, Color3.new(1, 1, 1), 0.15, FACES_SIDES)
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
-- Murallas altas de fortaleza, con estilo propio de cada mitología
local WALL_H = 56
local GOLD = Color3.fromRGB(240, 196, 92)
local WALL_THEMES = {
	{ -- griega: mármol blanco, oro y estandartes azules
		body = Color3.fromRGB(236, 228, 212), bodyMat = Enum.Material.Marble,
		trim = GOLD, trimMat = Enum.Material.Foil,
		pillar = Color3.fromRGB(248, 244, 234), pillarMat = Enum.Material.Marble,
		panel = Color3.fromRGB(205, 196, 178), banner = Color3.fromRGB(45, 95, 200),
		glow = Color3.fromRGB(120, 200, 255), floorMat = Enum.Material.Marble,
	},
	{ -- celta: piedra con musgo, madera y runas verdes
		body = Color3.fromRGB(96, 104, 98), bodyMat = Enum.Material.Slate,
		trim = Color3.fromRGB(70, 140, 60), trimMat = Enum.Material.Grass,
		pillar = Color3.fromRGB(88, 62, 40), pillarMat = Enum.Material.Wood,
		panel = Color3.fromRGB(72, 80, 76), banner = Color3.fromRGB(30, 110, 60),
		glow = Color3.fromRGB(90, 255, 150), floorMat = Enum.Material.Cobblestone,
	},
	{ -- egipcia: arenisca, lapislázuli y oro
		body = Color3.fromRGB(228, 190, 120), bodyMat = Enum.Material.Sandstone,
		trim = GOLD, trimMat = Enum.Material.Foil,
		pillar = Color3.fromRGB(240, 210, 150), pillarMat = Enum.Material.Sandstone,
		panel = Color3.fromRGB(200, 160, 95), banner = Color3.fromRGB(30, 60, 160),
		glow = Color3.fromRGB(255, 210, 90), floorMat = Enum.Material.Sand,
	},
	{ -- azteca: roca tallada, jade y rojo
		body = Color3.fromRGB(150, 140, 115), bodyMat = Enum.Material.Limestone,
		trim = Color3.fromRGB(50, 170, 140), trimMat = Enum.Material.Marble,
		pillar = Color3.fromRGB(125, 115, 92), pillarMat = Enum.Material.Rock,
		panel = Color3.fromRGB(120, 110, 90), banner = Color3.fromRGB(185, 40, 35),
		glow = Color3.fromRGB(60, 255, 210), floorMat = Enum.Material.Cobblestone,
	},
	{ -- babilonia: ladrillo vidriado azul y oro (puerta de Ishtar)
		body = Color3.fromRGB(40, 80, 185), bodyMat = Enum.Material.Brick,
		trim = GOLD, trimMat = Enum.Material.Foil,
		pillar = Color3.fromRGB(225, 190, 95), pillarMat = Enum.Material.Brick,
		panel = Color3.fromRGB(30, 60, 150), banner = Color3.fromRGB(245, 205, 80),
		glow = Color3.fromRGB(255, 220, 110), floorMat = Enum.Material.Slate,
	},
	{ -- cósmica: basalto oscuro y neón violeta
		body = Color3.fromRGB(34, 26, 56), bodyMat = Enum.Material.Basalt,
		trim = Color3.fromRGB(170, 90, 255), trimMat = Enum.Material.Neon,
		pillar = Color3.fromRGB(50, 38, 80), pillarMat = Enum.Material.Basalt,
		panel = Color3.fromRGB(24, 18, 40), banner = Color3.fromRGB(95, 40, 160),
		glow = Color3.fromRGB(120, 230, 255), floorMat = Enum.Material.Glass,
	},
}
World.WALL_H = WALL_H
World.WALL_THEMES = WALL_THEMES -- paleta de cada zona (body, trim, pillar, panel, banner, glow, materiales)
World.GOLD = GOLD

local function torch(pos, k, color)
	local holder = part({ Name = "TorchHolder", Size = Vector3.new(2.4, 1, 2.4), Position = pos, Color = Color3.fromRGB(60, 45, 35), Material = Enum.Material.Metal, CanCollide = false })
	part({ Name = "TorchArm", Size = Vector3.new(3, 0.6, 0.6), Position = pos + Vector3.new(k * 1.5, -0.8, 0), Color = Color3.fromRGB(60, 45, 35), Material = Enum.Material.Metal, CanCollide = false })
	local att = Instance.new("Attachment")
	att.Position = Vector3.new(0, 0.8, 0)
	att.Parent = holder
	local fire = Instance.new("ParticleEmitter")
	fire.Texture = G.Config.VFX.flame
	fire.Rate = 14
	fire.Lifetime = NumberRange.new(0.4, 0.7)
	fire.Speed = NumberRange.new(1, 3)
	fire.Acceleration = Vector3.new(0, 8, 0)
	fire.SpreadAngle = Vector2.new(20, 20)
	fire.LightEmission = 1
	fire.Color = ColorSequence.new(Color3.fromRGB(255, 210, 120), color)
	fire.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.2), NumberSequenceKeypoint.new(1, 0.3) })
	fire.Transparency = NumberSequence.new(0.1, 1)
	fire.Parent = att
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 190, 110)
	light.Range = 22
	light.Brightness = 1.4
	light.Shadows = false
	light.Parent = att
end
World.torch = torch -- torch(pos, k, colorLlama): antorcha de pared (k = -1/1 lado del brazo)

local function buildWall(i, z0, zone, k)
	local C = G.Config
	local L = C.ZONE_LENGTH
	local W = C.CORRIDOR_HALF_WIDTH
	local t = WALL_THEMES[i] or WALL_THEMES[#WALL_THEMES]
	local zc = z0 + L / 2
	local face = k * (W + 1) -- cara interior de la muralla
	local function at(inset, y, z)
		return Vector3.new(face + k * inset, y, z)
	end
	local inner = { k < 0 and Enum.NormalId.Right or Enum.NormalId.Left }
	local outerAndInner = { Enum.NormalId.Right, Enum.NormalId.Left }
	-- cuerpo principal, zócalo, cornisa y almenas
	local body = part({ Name = "WallVisible", Size = Vector3.new(8, WALL_H, L), Position = at(4, WALL_H / 2, zc), Color = t.body, Material = t.bodyMat })
	skin(body, i == 5 and "bricks" or "ashlar", i == 5 and 8 or 14, t.body:Lerp(Color3.new(1, 1, 1), 0.2), 0, outerAndInner)
	skin(body, "grime", 46, Color3.new(1, 1, 1), 0.3, inner)
	local plinth = part({ Name = "WallPlinth", Size = Vector3.new(3, 7, L), Position = at(-1.4, 3.5, zc), Color = t.pillar, Material = t.pillarMat })
	skin(plinth, "ashlar", 7, t.pillar, 0, inner)
	for _, y in ipairs({ 21.5, WALL_H - 10 }) do
		local band = part({ Name = "WallBand", Size = Vector3.new(1.4, 1.6, L), Position = at(-0.6, y, zc), Color = t.trim, Material = t.trimMat })
		if t.trimMat ~= Enum.Material.Neon then
			skin(band, "meander", 1.6, Color3.new(1, 1, 1), 0.1, inner)
		end
	end
	part({ Name = "WallCornice", Size = Vector3.new(11, 2.4, L), Position = at(3.5, WALL_H + 1.2, zc), Color = t.pillar, Material = t.pillarMat })
	part({ Name = "WallNeon", Size = Vector3.new(0.6, 0.8, L), Position = at(-2.2, WALL_H + 0.4, zc), Color = t.glow, Material = Enum.Material.Neon })
	for m = 0, math.floor(L / 10) - 1 do
		part({ Name = "Merlon", Size = Vector3.new(4, 5, 5), Position = at(1.5, WALL_H + 4.9, z0 + 5 + m * 10), Color = t.body, Material = t.bodyMat })
	end
	-- pilastras cada 25 studs con capitel dorado; entre ellas paneles, estandartes y antorchas
	local step = 25
	for p = 0, L / step do
		local z = z0 + p * step
		local pil = part({ Name = "Pilaster", Size = Vector3.new(3, WALL_H - 4, 5), Position = at(-1.5, (WALL_H - 4) / 2 + 2, z), Color = t.pillar, Material = t.pillarMat })
		skin(pil, "grime", 20, Color3.new(1, 1, 1), 0.35, inner)
		part({ Name = "PilasterCap", Size = Vector3.new(4.2, 2.4, 7), Position = at(-2, WALL_H - 1.5, z), Color = t.trim, Material = t.trimMat })
		part({ Name = "PilasterBase", Size = Vector3.new(4.2, 3, 7), Position = at(-2, 1.5, z), Color = t.trim, Material = t.trimMat })
		if p < L / step then
			local zm = z + step / 2
			-- panel hundido con un emblema que brilla
			local panel = part({ Name = "WallPanel", Size = Vector3.new(0.4, 22, 16), Position = at(-0.1, 33, zm), Color = t.panel, Material = t.bodyMat })
			skin(panel, "carved", 16, t.trim, 0, inner, 22)
			local emblem = part({ Name = "WallEmblem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 6, 6), Position = at(-0.4, 38, zm), Color = t.glow, Material = Enum.Material.Neon, CanCollide = false })
			emblem.CFrame = CFrame.new(emblem.Position)
			part({ Name = "EmblemRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 8, 8), Position = at(-0.25, 38, zm), Color = t.trim, Material = t.trimMat, CanCollide = false }).CFrame = CFrame.new(at(-0.25, 38, zm))
			if p % 2 == 0 then
				-- estandarte colgante con borde dorado
				part({ Name = "Banner", Size = Vector3.new(0.3, 16, 9), Position = at(-0.8, 11.5, zm), Color = t.banner, Material = Enum.Material.Fabric, CanCollide = false })
				part({ Name = "BannerTrim", Size = Vector3.new(0.35, 1.2, 9.6), Position = at(-0.85, 19.2, zm), Color = GOLD, Material = Enum.Material.Foil, CanCollide = false })
				part({ Name = "BannerTip", Size = Vector3.new(0.35, 1.2, 9.6), Position = at(-0.85, 4, zm), Color = GOLD, Material = Enum.Material.Foil, CanCollide = false })
			else
				torch(at(-2.6, 14, zm), k, t.glow)
			end
		end
	end
	-- acera de piedra al pie de la muralla
	local walk = part({ Name = "WallWalk", Size = Vector3.new(10, 0.4, L), Position = at(-5.5, 0.2, zc), Color = t.panel:Lerp(Color3.new(1, 1, 1), 0.35), Material = t.floorMat })
	skin(walk, "paving", 5, t.panel:Lerp(Color3.new(1, 1, 1), 0.5), 0, FACES_TOP)
	return t
end

-- Muralla recta entre dos puntos (para rodear la zona segura). n = hacia dentro.
local function wallSegment(A, B, n, t, H)
	local mid = (A + B) / 2
	local len = (B - A).Magnitude
	local out = -n
	local cf = CFrame.fromMatrix(Vector3.new(mid.X, 0, mid.Z), out, Vector3.yAxis)
	local function at(x, y, z)
		return cf * CFrame.new(x, y, z)
	end
	local inner = { Enum.NormalId.Left }
	local body = part({ Name = "RampartBody", Size = Vector3.new(8, H, len), CFrame = at(4, H / 2, 0), Color = t.body, Material = t.bodyMat })
	skin(body, "ashlar", 14, t.body:Lerp(Color3.new(1, 1, 1), 0.2), 0, { Enum.NormalId.Left, Enum.NormalId.Right })
	skin(body, "grime", 46, Color3.new(1, 1, 1), 0.3, inner)
	local plinth = part({ Name = "RampartPlinth", Size = Vector3.new(3, 7, len), CFrame = at(-1.4, 3.5, 0), Color = t.pillar, Material = t.pillarMat })
	skin(plinth, "ashlar", 7, t.pillar, 0, inner)
	for _, y in ipairs({ 21.5, H - 10 }) do
		local band = part({ Name = "RampartBand", Size = Vector3.new(1.4, 1.6, len), CFrame = at(-0.6, y, 0), Color = t.trim, Material = t.trimMat })
		skin(band, "meander", 1.6, Color3.new(1, 1, 1), 0.1, inner)
	end
	part({ Name = "RampartCornice", Size = Vector3.new(11, 2.4, len), CFrame = at(3.5, H + 1.2, 0), Color = t.pillar, Material = t.pillarMat })
	part({ Name = "RampartNeon", Size = Vector3.new(0.6, 0.8, len), CFrame = at(-2.2, H + 0.4, 0), Color = t.glow, Material = Enum.Material.Neon })
	for m = 0, math.floor(len / 10) - 1 do
		part({ Name = "Merlon", Size = Vector3.new(4, 5, 5), CFrame = at(1.5, H + 4.9, -len / 2 + 5 + m * 10), Color = t.body, Material = t.bodyMat })
	end
	local count = math.max(1, math.floor(len / 25 + 0.5))
	local step = len / count
	for p = 0, count do
		local z = -len / 2 + p * step
		local pil = part({ Name = "Pilaster", Size = Vector3.new(3, H - 4, 5), CFrame = at(-1.5, (H - 4) / 2 + 2, z), Color = t.pillar, Material = t.pillarMat })
		skin(pil, "grime", 20, Color3.new(1, 1, 1), 0.35, inner)
		part({ Name = "PilasterCap", Size = Vector3.new(4.2, 2.4, 7), CFrame = at(-2, H - 1.5, z), Color = t.trim, Material = t.trimMat })
		part({ Name = "PilasterBase", Size = Vector3.new(4.2, 3, 7), CFrame = at(-2, 1.5, z), Color = t.trim, Material = t.trimMat })
		if p < count then
			local zm = z + step / 2
			local panel = part({ Name = "RampartPanel", Size = Vector3.new(0.4, 22, step - 9), CFrame = at(-0.1, 33, zm), Color = t.panel, Material = t.bodyMat })
			skin(panel, "carved", step - 9, t.trim, 0, inner, 22)
			part({ Name = "RampartEmblem", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 6, 6), CFrame = at(-0.4, 38, zm), Color = t.glow, Material = Enum.Material.Neon, CanCollide = false })
			part({ Name = "EmblemRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 8, 8), CFrame = at(-0.25, 38, zm), Color = t.trim, Material = t.trimMat, CanCollide = false })
			if p % 2 == 0 then
				part({ Name = "Banner", Size = Vector3.new(0.3, 16, 9), CFrame = at(-0.8, 11.5, zm), Color = t.banner, Material = Enum.Material.Fabric, CanCollide = false })
				part({ Name = "BannerTrim", Size = Vector3.new(0.35, 1.2, 9.6), CFrame = at(-0.85, 19.2, zm), Color = GOLD, Material = Enum.Material.Foil, CanCollide = false })
				part({ Name = "BannerTip", Size = Vector3.new(0.35, 1.2, 9.6), CFrame = at(-0.85, 4, zm), Color = GOLD, Material = Enum.Material.Foil, CanCollide = false })
			else
				torch(at(-2.6, 14, zm).Position, 0, t.glow)
			end
		end
	end
	-- colisión alta invisible para que nadie salga del mapa
	part({ Name = "RampartBlock", Size = Vector3.new(4, 120, len), CFrame = at(4, 60, 0), Transparency = 1 })
end

local function tower(pos, t, H)
	local base = part({ Name = "Tower", Size = Vector3.new(16, H, 16), Position = pos + Vector3.new(0, H / 2, 0), Color = t.body, Material = t.bodyMat })
	skin(base, "ashlar", 12, t.body:Lerp(Color3.new(1, 1, 1), 0.2), 0, FACES_SIDES)
	skin(base, "grime", 30, Color3.new(1, 1, 1), 0.3, FACES_SIDES)
	for _, y in ipairs({ 6, H * 0.55 }) do
		local band = part({ Name = "TowerBand", Size = Vector3.new(16.8, 1.8, 16.8), Position = pos + Vector3.new(0, y, 0), Color = t.trim, Material = t.trimMat })
		skin(band, "meander", 1.8, Color3.new(1, 1, 1), 0.1, FACES_SIDES)
	end
	part({ Name = "TowerCrown", Size = Vector3.new(19, 2.4, 19), Position = pos + Vector3.new(0, H + 1.2, 0), Color = t.pillar, Material = t.pillarMat })
	for _, o in ipairs({ { -1, -1 }, { -1, 1 }, { 1, -1 }, { 1, 1 }, { 0, -1 }, { 0, 1 }, { -1, 0 }, { 1, 0 } }) do
		part({ Name = "Merlon", Size = Vector3.new(4, 5, 4), Position = pos + Vector3.new(o[1] * 7.5, H + 4.9, o[2] * 7.5), Color = t.body, Material = t.bodyMat })
	end
	local glowWin = part({ Name = "TowerWindow", Size = Vector3.new(16.4, 6, 2.4), Position = pos + Vector3.new(0, H * 0.75, 0), Color = t.glow, Material = Enum.Material.Neon })
	glowWin.Size = Vector3.new(16.2, 5, 2.4)
	part({ Name = "TowerWindow", Size = Vector3.new(2.4, 5, 16.2), Position = pos + Vector3.new(0, H * 0.75, 0), Color = t.glow, Material = Enum.Material.Neon })
	brazier(pos + Vector3.new(0, H + 2.4, 0), nil, nil, 1.4)
end

-- Muralla que rodea la zona segura y se une a la del pasillo
local function buildRamparts()
	local t = WALL_THEMES[1]
	local H = WALL_H
	local X, ZB, ZF = 128, -138, G.Config.CORRIDOR_START
	local CW = G.Config.CORRIDOR_HALF_WIDTH + 9
	wallSegment(Vector3.new(-X, 0, ZB), Vector3.new(X, 0, ZB), Vector3.new(0, 0, 1), t, H) -- fondo
	wallSegment(Vector3.new(-X, 0, ZB), Vector3.new(-X, 0, ZF), Vector3.new(1, 0, 0), t, H) -- izquierda
	wallSegment(Vector3.new(X, 0, ZB), Vector3.new(X, 0, ZF), Vector3.new(-1, 0, 0), t, H) -- derecha
	wallSegment(Vector3.new(-X, 0, ZF), Vector3.new(-CW, 0, ZF), Vector3.new(0, 0, -1), t, H) -- frente izquierda
	wallSegment(Vector3.new(CW, 0, ZF), Vector3.new(X, 0, ZF), Vector3.new(0, 0, -1), t, H) -- frente derecha
	for _, c in ipairs({ { -X, ZB }, { X, ZB }, { -X, ZF }, { X, ZF } }) do
		tower(Vector3.new(c[1], 0, c[2]), t, H + 16)
	end
	-- torres que flanquean la entrada al pasillo
	tower(Vector3.new(-CW - 4, 0, ZF + 4), t, H + 22)
	tower(Vector3.new(CW + 4, 0, ZF + 4), t, H + 22)
end

local function decorZone(i, z0, zone)
	local L = G.Config.ZONE_LENGTH
	local function side(fn)
		for k = 0, 5 do
			local z = z0 + 20 + k * 34
			local Wd = G.Config.CORRIDOR_HALF_WIDTH
			fn(-(Wd + 20) - (k % 2) * 10, z)
			fn(Wd + 20 + (k % 2) * 10, z)
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
		for _, x in ipairs({ -(G.Config.CORRIDOR_HALF_WIDTH + 75), G.Config.CORRIDOR_HALF_WIDTH + 75 }) do
			for s = 0, 6 do
				local w = 90 - s * 13
				part({ Size = Vector3.new(w, 8, w), Position = Vector3.new(x, 4 + s * 8, z0 + L / 2), Color = zone.accent, Material = Enum.Material.Sand })
			end
		end
	elseif i == 4 then -- templo azteca escalonado + selva
		for _, x in ipairs({ -(G.Config.CORRIDOR_HALF_WIDTH + 65), G.Config.CORRIDOR_HALF_WIDTH + 65 }) do
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
			part({ Size = Vector3.new(w, 10, w), Position = Vector3.new(-(G.Config.CORRIDOR_HALF_WIDTH + 80), 5 + s * 10, z0 + L / 2), Color = zone.ground, Material = Enum.Material.Brick })
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
local function guardianFX(m, body, s, gd, i)
	local VFX = G.Config.VFX
	local hl = Instance.new("Highlight")
	hl.OutlineColor = Color3.fromRGB(255, 60, 50)
	hl.FillColor = Color3.fromRGB(255, 40, 40)
	hl.FillTransparency = 0.88
	hl.DepthMode = Enum.HighlightDepthMode.Occluded
	hl.Parent = m
	local att = Instance.new("Attachment")
	att.Parent = body
	local flames = Instance.new("ParticleEmitter")
	flames.Texture = VFX.flame
	flames.Rate = 40
	flames.Lifetime = NumberRange.new(0.5, 0.9)
	flames.Speed = NumberRange.new(2, 5)
	flames.Acceleration = Vector3.new(0, 12, 0)
	flames.SpreadAngle = Vector2.new(70, 70)
	flames.LightEmission = 1
	flames.Color = ColorSequence.new(Color3.fromRGB(255, 150, 50), Color3.fromRGB(200, 20, 20))
	flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3 * s), NumberSequenceKeypoint.new(1, 0.5) })
	flames.Transparency = NumberSequence.new(0.1, 1)
	flames.Parent = att
	local smoke = Instance.new("ParticleEmitter")
	smoke.Texture = VFX.smoke
	smoke.Rate = 8
	smoke.Lifetime = NumberRange.new(1.5, 2.5)
	smoke.Speed = NumberRange.new(1, 3)
	smoke.RotSpeed = NumberRange.new(-40, 40)
	smoke.Color = ColorSequence.new(Color3.fromRGB(60, 15, 15))
	smoke.Transparency = NumberSequence.new(0.5, 1)
	smoke.Size = NumberSequence.new(3 * s, 7 * s)
	smoke.Parent = att
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 70, 50)
	light.Range = 26
	light.Brightness = 3
	light.Parent = att
	local gbb = billboard(body, "", Color3.fromRGB(255, 90, 80), UDim2.fromOffset(260, 60), Vector3.new(0, 6 * s, 0))
	gbb:SetAttribute("Guardian", i)
	CollectionService:AddTag(gbb, "Loc")
end

function World.makeGuardian(i)
	local zone = G.Config.ZONES[i]
	local gd = zone.guardian
	local GMYTH = { minotaur = "greek", dullahan = "celtic", sphinx = "egyptian", jaguar = "aztec", lamassu = "babylonian", fenrir = "norse" }
	local av = G.Avatars and G.Avatars.make({ id = "g_" .. gd.kind, myth = GMYTH[gd.kind] or "greek", r = 0, name = gd.en })
	if av then
		local m = av:Clone()
		m.Name = "Guardian" .. i
		local k = 4.4 + i * 0.3
		m:ScaleTo(k)
		local h = (m:GetAttribute("PivotH") or 3) * k
		local rp = m.PrimaryPart
		-- Marca de fuego bajo los pies. Va FUERA del modelo (soldada a la raíz): dentro del avatar
		-- se reescalaba con él y acababa siendo un disco rojo de 70-120 studs que tapaba el suelo.
		local ring = part({ Name = "Scorch" .. i, Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 3.2 * k, 3.2 * k), CFrame = rp.CFrame * CFrame.new(0, -h + 0.08, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 50, 30), Material = Enum.Material.Neon, Transparency = 0.7, CanCollide = false, CanQuery = false, CanTouch = false, Massless = true, Parent = root })
		local dec = Instance.new("Decal")
		dec.Face = Enum.NormalId.Right
		dec.Texture = G.Config.VFX.runes
		dec.Color3 = Color3.fromRGB(255, 80, 40)
		dec.Parent = ring
		ring.Anchored = false
		local w = Instance.new("WeldConstraint")
		w.Part0 = rp
		w.Part1 = ring
		w.Parent = ring
		guardianFX(m, m:FindFirstChild("UpperTorso") or rp, k / 3, gd, i)
		m.Parent = root
		return m, h
	end
	local tmpl = G.GodModel.template(gd.kind)
	if tmpl then
		local m = tmpl:Clone()
		m.Name = "Guardian" .. i
		local k = (13 + i * 1.5) / 7.8
		m:ScaleTo(k)
		local rp = m.PrimaryPart
		local ring = part({ Name = "Scorch", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.15, 9 * k, 9 * k), CFrame = rp.CFrame * CFrame.new(0, 0.05, 0) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 50, 30), Material = Enum.Material.Neon, Transparency = 0.55, CanCollide = false, Parent = m })
		local dec = Instance.new("Decal")
		dec.Face = Enum.NormalId.Right
		dec.Texture = G.Config.VFX.runes
		dec.Color3 = Color3.fromRGB(255, 80, 40)
		dec.Parent = ring
		guardianFX(m, m:FindFirstChild("Body") or rp, k * 0.6, gd, i)
		m.Parent = root
		return m, 0
	end
	local s = 1.4 + (i - 1) * 0.15
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
	local flames = Instance.new("ParticleEmitter")
	flames.Rate = 45
	flames.Lifetime = NumberRange.new(0.5, 1)
	flames.Speed = NumberRange.new(2, 6)
	flames.Acceleration = Vector3.new(0, 10, 0)
	flames.SpreadAngle = Vector2.new(60, 60)
	flames.LightEmission = 1
	flames.Color = ColorSequence.new(Color3.fromRGB(255, 120, 40), Color3.fromRGB(180, 20, 20))
	flames.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 2.5 * s), NumberSequenceKeypoint.new(1, 0) })
	flames.Transparency = NumberSequence.new(0.2, 1)
	flames.Parent = rootPart
	local scorch = part({ Name = "Scorch", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 16 * s, 16 * s), Color = Color3.fromRGB(255, 40, 30), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, Parent = m })
	scorch.CFrame = rootPart.CFrame * CFrame.new(0, -8.9 * s, 0) * CFrame.Angles(0, 0, math.rad(90))
	local sw = Instance.new("WeldConstraint")
	sw.Part0 = rootPart
	sw.Part1 = scorch
	sw.Parent = scorch
	scorch.Anchored = false
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
		zp.floor = part({ Name = "Zone" .. i, Size = Vector3.new(W * 2 + 260, 4, L), Position = Vector3.new(0, -2, z0 + L / 2), Color = zone.ground, Material = Enum.Material.SmoothPlastic })
		local tex = Instance.new("Texture")
		tex.Texture = C.VFX.studs
		tex.Face = Enum.NormalId.Top
		tex.StudsPerTileU = 4
		tex.StudsPerTileV = 4
		tex.Transparency = 0.15
		tex.Parent = zp.floor
		-- pista central más clara
		World.zoneRunway = part({ Name = "Runway", Size = Vector3.new(W * 2, 0.2, L), Position = Vector3.new(0, 0.1, z0 + L / 2), Color = zone.ground:Lerp(Color3.new(1, 1, 1), 0.18), Material = (WALL_THEMES[i] or WALL_THEMES[1]).floorMat })
		skin(World.zoneRunway, i == 6 and "hexgrid" or "paving", i == 6 and 16 or 14, zone.ground:Lerp(Color3.new(1, 1, 1), 0.45), 0.15, FACES_TOP)
		-- muros: bajos y de color, con franja de neón; colisión invisible alta
		for _, k in ipairs({ -1, 1 }) do
			part({ Name = "Wall", Size = Vector3.new(2, 80, L), Position = Vector3.new(k * (W + 3), 40, z0 + L / 2), Transparency = 1 })
			buildWall(i, z0, zone, k)
		end
		-- arco de neón en la entrada de la zona
		local archColor = zone.ground:Lerp(Color3.new(1, 1, 1), 0.3)
		for _, k in ipairs({ -1, 1 }) do
			part({ Name = "ArchPillar", Size = Vector3.new(10, 70, 10), Position = Vector3.new(k * (W + 3), 35, z0), Color = zone.accent, Material = Enum.Material.Marble })
			part({ Name = "ArchNeon", Size = Vector3.new(1.2, 70, 10.6), Position = Vector3.new(k * (W + 3) - k * 5.2, 35, z0), Color = archColor, Material = Enum.Material.Neon })
		end
		part({ Name = "ArchNeonTop", Size = Vector3.new(W * 2 + 16, 1.2, 10.6), Position = Vector3.new(0, 69, z0), Color = archColor, Material = Enum.Material.Neon })
		local top = part({ Name = "ArchTop", Size = Vector3.new(W * 2 + 16, 8, 10), Position = Vector3.new(0, 73.5, z0), Color = (WALL_THEMES[i] or WALL_THEMES[1]).pillar, Material = (WALL_THEMES[i] or WALL_THEMES[1]).pillarMat })
		-- Medallón rúnico frontal: mantiene la paleta propia de cada mitología.
		local medallion = part({ Name = "DivineMedallion", Shape = Enum.PartType.Cylinder,
			Size = Vector3.new(0.65, 9, 9), Position = Vector3.new(0, 73.5, z0 - 5.3),
			CFrame = CFrame.new(0, 73.5, z0 - 5.3) * CFrame.Angles(0, math.rad(90), 0),
			Color = Color3.fromRGB(238, 202, 112), Material = Enum.Material.Foil,
			CanCollide = false })
		local sigil = part({ Name = "MedallionCore", Shape = Enum.PartType.Ball, Size = Vector3.new(2.8, 2.8, 2.8),
			Position = Vector3.new(0, 73.5, z0 - 5.85), Color = zone.accent, Material = Enum.Material.Neon,
			CanCollide = false })
		local sigilLight = Instance.new("PointLight")
		sigilLight.Color = zone.accent
		sigilLight.Range = 18
		sigilLight.Brightness = 0.8
		sigilLight.Shadows = false
		sigilLight.Parent = sigil
		local topGlow = part({ Name = "ArchGoldLine", Size = Vector3.new(W * 2 + 16, 0.35, 10.8),
			Position = Vector3.new(0, 77.7, z0), Color = Color3.fromRGB(255, 215, 125),
			Material = Enum.Material.Neon, Transparency = 0.28, CanCollide = false })
		zp.sign = billboard(top, "", Color3.new(1, 1, 1), UDim2.fromOffset(520, 110), Vector3.new(0, 8, 0))
		zp.sign.MaxDistance = 140
		zp.sign:SetAttribute("Zone", i)
		CollectionService:AddTag(zp.sign, "Loc")
		-- (sin cortina de campo de fuerza entre zonas: el dueño quiere pasar libremente de una a otra)
		-- puntos donde aparecen los sobres
		zp.spots = {}
		for row = 0, 1 do
			for col = -1, 1 do
				table.insert(zp.spots, Vector3.new(col * 42, 2.5, z0 + 65 + row * 70))
			end
		end
		zp.guardianHome = Vector3.new(0, 0, z0 + L - 25)
		decorZone(i, z0, zone)
		World.zoneParts[i] = zp
	end
	-- fin del pasillo (más zonas próximamente)
	local zEnd = World.zoneStart(#C.ZONES + 1)
	local wall = part({ Name = "EndWall", Size = Vector3.new(W * 2 + 4, 76, 4), Position = Vector3.new(0, 38, zEnd), Color = Color3.fromRGB(20, 15, 35), Material = Enum.Material.ForceField })
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
	local ground = part({ Name = "SafeGround", Size = Vector3.new(260, 4, 270), Position = Vector3.new(0, -2, -5), Color = Color3.fromRGB(120, 175, 95), Material = Enum.Material.Grass })
	skin(ground, "grass", 9, Color3.fromRGB(170, 215, 120), 0.2, FACES_TOP)
	skin(ground, "grime", 70, Color3.fromRGB(60, 90, 40), 0.55, FACES_TOP)
	local plaza = part({ Name = "Plaza", Size = Vector3.new(76, 0.4, 216), Position = Vector3.new(0, 0.2, -2), Color = Color3.fromRGB(225, 220, 205), Material = Enum.Material.Marble })
	skin(plaza, "paving", 10, Color3.fromRGB(245, 238, 222), 0, FACES_TOP)
	skin(plaza, "grime", 50, Color3.new(1, 1, 1), 0.55, FACES_TOP)
	-- franjas con greca dorada y bordillo a los lados de la plaza
	for k = -3, 3 do
		local line = part({ Name = "PlazaLine", Size = Vector3.new(76, 0.45, 2.4), Position = Vector3.new(0, 0.22, k * 28), Color = Color3.fromRGB(230, 190, 80), Material = Enum.Material.Foil })
		skin(line, "meander", 2.4, Color3.fromRGB(255, 245, 210), 0, FACES_TOP)
	end
	for _, x in ipairs({ -37, 37 }) do
		local curb = part({ Name = "PlazaCurb", Size = Vector3.new(2.4, 0.6, 216), Position = Vector3.new(x, 0.3, -2), Color = Color3.fromRGB(215, 205, 185), Material = Enum.Material.Marble })
		skin(curb, "meander", 2.4, Color3.fromRGB(240, 196, 92), 0, FACES_TOP)
	end
	-- braseros que marcan la entrada al pasillo
	for _, x in ipairs({ -26, 26 }) do
		brazier(Vector3.new(x, 0, 96), nil, nil, 1.2)
	end
	-- Fuente central con agua brillante
	local F = Vector3.new(0, 0, 68)
	part({ Name = "FountainBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 26, 26), CFrame = CFrame.new(F + Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(235, 225, 205), Material = Enum.Material.Marble })
	part({ Name = "FountainWater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 23, 23), CFrame = CFrame.new(F + Vector3.new(0, 2.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(90, 200, 255), Material = Enum.Material.Glass, Transparency = 0.25 })
	part({ Name = "FountainPillar", Shape = Enum.PartType.Cylinder, Size = Vector3.new(8, 3, 3), CFrame = CFrame.new(F + Vector3.new(0, 5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(235, 225, 205), Material = Enum.Material.Marble })
	local bowl = part({ Name = "FountainBowl", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2, 10, 10), CFrame = CFrame.new(F + Vector3.new(0, 9, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 200, 90), Material = Enum.Material.Foil })
	local spray = Instance.new("ParticleEmitter")
	spray.Texture = G.Config.VFX.sparkle
	spray.Rate = 60
	spray.Lifetime = NumberRange.new(1, 1.6)
	spray.Speed = NumberRange.new(10, 14)
	spray.SpreadAngle = Vector2.new(18, 18)
	spray.Acceleration = Vector3.new(0, -22, 0)
	spray.EmissionDirection = Enum.NormalId.Right
	spray.LightEmission = 0.8
	spray.Color = ColorSequence.new(Color3.fromRGB(150, 230, 255), Color3.new(1, 1, 1))
	spray.Size = NumberSequence.new(0.6, 0.1)
	spray.Parent = bowl
	local fl = Instance.new("PointLight")
	fl.Color = Color3.fromRGB(120, 210, 255)
	fl.Range = 20
	fl.Parent = bowl
	buildFountainCrown(F)
	-- Farolillos cálidos a los lados de la plaza
	for z = -96, 96, 32 do
		for _, x in ipairs({ -36, 36 }) do
			-- farola de hierro con farolillo de cristal
			part({ Name = "LampFoot", Size = Vector3.new(1.8, 1.2, 1.8), Position = Vector3.new(x, 0.6, z), Color = Color3.fromRGB(45, 40, 38), Material = Enum.Material.Slate })
			part({ Name = "LampPost", Shape = Enum.PartType.Cylinder, Size = Vector3.new(10, 0.7, 0.7), CFrame = CFrame.new(x, 5.6, z) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(40, 38, 42), Material = Enum.Material.Metal })
			part({ Name = "LampRing", Size = Vector3.new(1.6, 0.3, 1.6), Position = Vector3.new(x, 9.4, z), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil })
			part({ Name = "LampCage", Size = Vector3.new(1.9, 2.2, 1.9), Position = Vector3.new(x, 10.7, z), Color = Color3.fromRGB(255, 225, 170), Material = Enum.Material.Glass, Transparency = 0.45 })
			part({ Name = "LampRoof", Class = "WedgePart", Size = Vector3.new(2.4, 0.9, 1.2), CFrame = CFrame.new(x, 12.25, z + 0.6) * CFrame.Angles(0, math.rad(180), 0), Color = Color3.fromRGB(40, 38, 42), Material = Enum.Material.Metal })
			part({ Name = "LampRoof", Class = "WedgePart", Size = Vector3.new(2.4, 0.9, 1.2), CFrame = CFrame.new(x, 12.25, z - 0.6), Color = Color3.fromRGB(40, 38, 42), Material = Enum.Material.Metal })
			local lamp = part({ Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), Position = Vector3.new(x, 10.7, z), Color = Color3.fromRGB(255, 190, 90), Material = Enum.Material.Neon })
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(255, 170, 80)
			pl.Range = 22
			pl.Brightness = 2
			pl.Shadows = false
			pl.Parent = lamp
		end
	end
	-- Parterres de flores y árboles alrededor
	local flowerColors = { Color3.fromRGB(255, 120, 170), Color3.fromRGB(255, 220, 90), Color3.fromRGB(180, 120, 255), Color3.fromRGB(255, 255, 255) }
	for k = 0, 9 do
		local a = k / 10 * math.pi * 2
		local p0 = F + Vector3.new(math.cos(a) * 17, 0.6, math.sin(a) * 17)
		part({ Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.new(3, 2.2, 3), Position = p0, Color = Color3.fromRGB(70, 160, 70), Material = Enum.Material.Grass })
		part({ Name = "Flower", Shape = Enum.PartType.Ball, Size = Vector3.new(0.9, 0.9, 0.9), Position = p0 + Vector3.new(0, 1.2, 0), Color = flowerColors[k % 4 + 1], Material = Enum.Material.Neon })
	end
	for _, x in ipairs({ -118, 118 }) do
		for z = -120, 100, 36 do
			part({ Name = "Trunk", Size = Vector3.new(2.5, 14, 2.5), Position = Vector3.new(x, 7, z), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood })
			part({ Name = "Leaves", Shape = Enum.PartType.Ball, Size = Vector3.new(14, 12, 14), Position = Vector3.new(x, 17, z), Color = Color3.fromRGB(90, 175, 80), Material = Enum.Material.Grass })
			part({ Name = "Leaves2", Shape = Enum.PartType.Ball, Size = Vector3.new(9, 8, 9), Position = Vector3.new(x + 3, 22, z - 2), Color = Color3.fromRGB(120, 195, 90), Material = Enum.Material.Grass })
		end
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
	buildRamparts()
	for i = 1, #G.Config.ZONES do
		local model, height = World.makeGuardian(i)
		local home = World.zoneParts[i].guardianHome
		model:PivotTo(CFrame.new(home + Vector3.new(0, height, 0)) * CFrame.Angles(0, 0, 0))
		World.guardians[i] = { model = model, height = height, home = home + Vector3.new(0, height, 0), zone = i }
	end
end

return World
