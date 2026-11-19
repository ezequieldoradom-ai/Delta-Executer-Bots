-- Lucky Obby Race — ambiente de cada bioma (Shadow). Solo visual y solo en tu pantalla:
-- al entrar en un tramo cambian la luz, la hora, la niebla y el color, cae su clima alrededor de la cámara
-- (pétalos, virutas, brasas, nieve, estrellas, polvo dorado) y aparece su nombre en grande.
-- Lee del recorrido (workspace.Course) los atributos Biomes, SecZ0 y SecLen que pone Decor en el servidor.
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Locale = require(ReplicatedStorage.Shared:WaitForChild("Locale"))
pcall(function()
	Locale.detect(player.LocaleId)
end)

local SMOKE = "rbxasset://textures/particles/smoke_main.dds"
local SPARK = "rbxasset://textures/particles/sparkles_main.dds"
local FIRE = "rbxasset://textures/particles/fire_main.dds"

local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- clima: fall = cae desde arriba; rise = sube desde abajo; float = flota alrededor
local LOOKS = {
	meadow = {
		es = "🌼 PRADERA", en = "🌼 MEADOW", color = rgb(150, 255, 120),
		clock = 14.5, atm = rgb(200, 230, 255), decay = rgb(255, 230, 200), density = 0.3, haze = 1.2, tint = rgb(255, 255, 245), sat = 0.2, ambient = rgb(150, 150, 170),
		fx = { mode = "fall", tex = SMOKE, rate = 20, size = 0.35, colors = { rgb(255, 170, 220), rgb(255, 255, 160) }, speed = 2, light = 0.2 },
	},
	candy = {
		es = "🍭 MUNDO CARAMELO", en = "🍭 CANDY LAND", color = rgb(255, 140, 210),
		clock = 13, atm = rgb(255, 205, 235), decay = rgb(255, 180, 230), density = 0.35, haze = 1.6, tint = rgb(255, 235, 250), sat = 0.35, ambient = rgb(185, 150, 180),
		fx = { mode = "fall", tex = SMOKE, rate = 35, size = 0.3, colors = { rgb(255, 90, 160), rgb(120, 220, 255), rgb(255, 240, 120), rgb(160, 255, 170) }, speed = 3, light = 0.5, spin = true },
	},
	volcano = {
		es = "🌋 VOLCÁN", en = "🌋 VOLCANO", color = rgb(255, 120, 40),
		clock = 17.9, atm = rgb(140, 70, 50), decay = rgb(255, 90, 40), density = 0.45, haze = 2.2, tint = rgb(255, 215, 190), sat = 0.15, ambient = rgb(140, 80, 60),
		fx = { mode = "rise", tex = FIRE, rate = 45, size = 0.3, colors = { rgb(255, 220, 100), rgb(255, 80, 20) }, speed = 6, light = 1 },
	},
	ice = {
		es = "❄️ GLACIAR", en = "❄️ GLACIER", color = rgb(150, 230, 255),
		clock = 10, atm = rgb(210, 235, 255), decay = rgb(180, 220, 255), density = 0.42, haze = 2, tint = rgb(225, 240, 255), sat = 0, ambient = rgb(160, 180, 210),
		fx = { mode = "fall", tex = SMOKE, rate = 70, size = 0.4, colors = { rgb(255, 255, 255), rgb(220, 240, 255) }, speed = 5, light = 0.3 },
	},
	galaxy = {
		es = "🌌 GALAXIA", en = "🌌 GALAXY", color = rgb(200, 140, 255),
		clock = 0, atm = rgb(70, 40, 120), decay = rgb(140, 80, 220), density = 0.3, haze = 1.5, tint = rgb(225, 210, 255), sat = 0.3, ambient = rgb(120, 100, 170),
		fx = { mode = "float", tex = SPARK, rate = 40, size = 0.5, colors = { rgb(255, 255, 255), rgb(200, 160, 255), rgb(130, 200, 255) }, speed = 0.6, light = 1 },
	},
	heaven = {
		es = "☁️ CIELO DORADO", en = "☁️ GOLDEN SKY", color = rgb(255, 220, 90),
		clock = 16.8, atm = rgb(255, 235, 200), decay = rgb(255, 210, 140), density = 0.32, haze = 1.4, tint = rgb(255, 245, 220), sat = 0.25, ambient = rgb(180, 165, 140),
		fx = { mode = "float", tex = SPARK, rate = 35, size = 0.45, colors = { rgb(255, 240, 160), rgb(255, 200, 70) }, speed = 1, light = 1 },
	},
	haunted = {
		es = "👻 CEMENTERIO ENCANTADO", en = "👻 HAUNTED GRAVEYARD", color = rgb(130, 255, 150),
		clock = 18.3, atm = rgb(90, 120, 105), decay = rgb(150, 100, 200), density = 0.45, haze = 2.6, tint = rgb(220, 240, 230), sat = -0.1, ambient = rgb(150, 170, 160),
		fx = { mode = "float", tex = SMOKE, rate = 30, size = 0.6, colors = { rgb(140, 255, 170), rgb(170, 120, 255) }, speed = 0.8, light = 0.8 },
	},
	desert = {
		es = "🏜️ DESIERTO", en = "🏜️ DESERT", color = rgb(255, 200, 110),
		clock = 12.5, atm = rgb(240, 210, 160), decay = rgb(255, 190, 120), density = 0.4, haze = 2.4, tint = rgb(255, 238, 210), sat = 0.1, ambient = rgb(180, 160, 130),
		fx = { mode = "fall", tex = SMOKE, rate = 45, size = 0.3, colors = { rgb(240, 210, 150), rgb(210, 170, 110) }, speed = 2, light = 0, wind = true },
	},
}

-- estado por defecto (vestíbulo): lo que haya puesto el servidor
task.wait(2)
local atm = Lighting:FindFirstChildOfClass("Atmosphere")
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "BiomeTint"
cc.Parent = Lighting
local DEFAULT = {
	clock = Lighting.ClockTime, ambient = Lighting.OutdoorAmbient, tint = Color3.new(1, 1, 1), sat = 0,
	atm = atm and atm.Color, decay = atm and atm.Decay, density = atm and atm.Density, haze = atm and atm.Haze,
}

local INFO = TweenInfo.new(1.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut)
local function applyLight(L)
	local clock = L.clock
	-- la hora va por el camino corto (de 14,5 a 0 pasa por la tarde y la noche, no por la mañana)
	if clock < Lighting.ClockTime - 12 then
		clock += 24
	end
	TweenService:Create(Lighting, INFO, { ClockTime = clock, OutdoorAmbient = L.ambient }):Play()
	TweenService:Create(cc, INFO, { TintColor = L.tint, Saturation = L.sat }):Play()
	if atm and L.atm then
		TweenService:Create(atm, INFO, { Color = L.atm, Decay = L.decay, Density = L.density, Haze = L.haze }):Play()
	end
end

-- emisor que sigue a la cámara
local holder = Instance.new("Part")
holder.Name = "BiomeWeather"
holder.Anchored = true
holder.CanCollide = false
holder.CanQuery = false
holder.CanTouch = false
holder.Transparency = 1
holder.Size = Vector3.new(80, 1, 80)
holder.Parent = workspace.CurrentCamera
local pe = Instance.new("ParticleEmitter")
pe.Shape = Enum.ParticleEmitterShape.Box
pe.Enabled = false
pe.Parent = holder
local mode = "fall"

local function applyFx(fx)
	if not fx then
		pe.Enabled = false
		return
	end
	mode = fx.mode
	local kp = {}
	for i, c in ipairs(fx.colors) do
		kp[i] = ColorSequenceKeypoint.new(#fx.colors == 1 and 0 or (i - 1) / (#fx.colors - 1), c)
	end
	if #kp == 1 then
		kp[2] = ColorSequenceKeypoint.new(1, fx.colors[1])
	end
	pe.Texture = fx.tex
	pe.Color = ColorSequence.new(kp)
	pe.Rate = fx.rate
	pe.LightEmission = fx.light
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = fx.spin and NumberRange.new(-180, 180) or NumberRange.new(-20, 20)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.15, fx.size), NumberSequenceKeypoint.new(0.85, fx.size), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(1, 0.6) })
	if mode == "fall" then
		holder.Size = Vector3.new(80, 1, 80)
		pe.EmissionDirection = Enum.NormalId.Bottom
		pe.Speed = NumberRange.new(fx.speed * 0.6, fx.speed)
		pe.Acceleration = fx.wind and Vector3.new(14, 0.5, 4) or Vector3.new(1.5, -1, 0)
		pe.Lifetime = NumberRange.new(5, 8)
		pe.SpreadAngle = Vector2.new(20, 20)
	elseif mode == "rise" then
		holder.Size = Vector3.new(80, 1, 80)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.Speed = NumberRange.new(fx.speed * 0.5, fx.speed)
		pe.Acceleration = Vector3.new(0, 1.5, 0)
		pe.Lifetime = NumberRange.new(4, 7)
		pe.SpreadAngle = Vector2.new(25, 25)
	else
		holder.Size = Vector3.new(70, 30, 70)
		pe.EmissionDirection = Enum.NormalId.Top
		pe.Speed = NumberRange.new(0, fx.speed)
		pe.Acceleration = Vector3.zero
		pe.Lifetime = NumberRange.new(3, 6)
		pe.SpreadAngle = Vector2.new(180, 180)
	end
	pe.Enabled = true
end

-- cartel con el nombre del bioma
local gui = Instance.new("ScreenGui")
gui.Name = "BiomeTitle"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 5
gui.Parent = player:WaitForChild("PlayerGui")
local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.19)
title.Size = UDim2.fromScale(0.6, 0.09)
title.BackgroundTransparency = 1
title.Font = Enum.Font.LuckiestGuy
title.TextScaled = true
title.TextColor3 = Color3.new(1, 1, 1)
title.TextTransparency = 1
title.TextStrokeTransparency = 1
title.Parent = gui
local grad = Instance.new("UIGradient")
grad.Parent = title
local scale = Instance.new("UIScale")
scale.Parent = title
local showId = 0
local function showTitle(L)
	showId += 1
	local my = showId
	title.Text = Locale.lang() == "es" and L.es or L.en
	grad.Color = ColorSequence.new(Color3.new(1, 1, 1), L.color)
	title.TextTransparency = 1
	title.TextStrokeTransparency = 1
	scale.Scale = 1.6
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(title, TweenInfo.new(0.35), { TextTransparency = 0, TextStrokeTransparency = 0.2 }):Play()
	task.delay(2.4, function()
		if showId == my then
			TweenService:Create(title, TweenInfo.new(0.8), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- ¿en qué bioma estoy?
local C = Config.COURSE
local function currentBiome()
	local course = workspace:FindFirstChild("Course")
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not course or not hrp then
		return nil
	end
	local list = course:GetAttribute("Biomes")
	local z0 = course:GetAttribute("SecZ0")
	local len = course:GetAttribute("SecLen")
	if type(list) ~= "string" or not z0 or not len then
		return nil
	end
	local p = hrp.Position
	if p.Y < C.START.Y - 60 or p.Z < C.START.Z - 20 or math.abs(p.X) > 120 then
		return nil -- vestíbulo
	end
	local names = string.split(list, ",")
	local i = math.clamp(math.floor((p.Z - z0) / len) + 1, 1, #names)
	return names[i]
end

local current = false
RunService.RenderStepped:Connect(function()
	local cam = workspace.CurrentCamera
	if cam then
		local base = cam.CFrame.Position
		if mode == "fall" then
			holder.CFrame = CFrame.new(base + Vector3.new(0, 25, 0))
		elseif mode == "rise" then
			holder.CFrame = CFrame.new(base - Vector3.new(0, 18, 0))
		else
			holder.CFrame = CFrame.new(base)
		end
	end
end)

while true do
	local b = currentBiome()
	if b ~= current then
		current = b
		local L = b and LOOKS[b]
		if L then
			applyLight(L)
			applyFx(L.fx)
			showTitle(L)
		else
			applyLight(DEFAULT)
			applyFx(nil)
		end
	end
	task.wait(0.25)
end
