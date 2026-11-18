-- Steal a God ⚡ — cielos con personalidad en cada zona (solo en la pantalla de cada jugador).
-- Petición del dueño: "cielos con efectos distintos". Lo arranca Fx.start (módulo hermano).
--   · Cambia nubes (color, cantidad), tamaño del sol, estrellas y rayos de sol según la zona en la que estás.
--   · Efectos en el cielo de cada zona: auroras, ceniza volcánica, linternas, estrellas fugaces, planetas…
--   · Desplaza las texturas etiquetadas "FxScroll" (suelo de galaxia de la zona cósmica).
-- La atmósfera y el tinte de color de cada zona los sigue poniendo init.client (zoneMood); aquí no se tocan.
local Players = game:GetService("Players")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")

local ZoneSky = {}
local Config
local started = false

local rgb = Color3.fromRGB
-- [0] = plaza / obby
local LOOKS = {
	[0] = { clouds = rgb(255, 255, 255), cover = 0.5, density = 0.6, sun = 21, rays = 0.08 },
	[1] = { clouds = rgb(255, 245, 225), cover = 0.55, density = 0.55, sun = 26, rays = 0.22, fx = "goldDust" }, -- griega: luz dorada
	[2] = { clouds = rgb(200, 255, 220), cover = 0.7, density = 0.75, sun = 18, rays = 0.1, fx = "aurora", color = rgb(90, 255, 160), color2 = rgb(60, 180, 255) }, -- celta
	[3] = { clouds = rgb(255, 215, 160), cover = 0.25, density = 0.4, sun = 45, rays = 0.3, fx = "goldDust" }, -- egipcia: sol enorme
	[4] = { clouds = rgb(120, 70, 60), cover = 0.85, density = 0.9, sun = 16, rays = 0.05, fx = "ash" }, -- azteca: volcán
	[5] = { clouds = rgb(255, 170, 200), cover = 0.6, density = 0.6, sun = 22, rays = 0.15, fx = "lanterns" }, -- babilonia: atardecer
	[6] = { clouds = rgb(150, 90, 255), cover = 0.75, density = 0.85, sun = 10, rays = 0.02, fx = "cosmic", color = rgb(190, 90, 255), color2 = rgb(60, 220, 255) }, -- cósmica
}

local folder -- efectos del cielo (solo en este cliente)
local fxByZone = {} -- [zona] = { instancias que se encienden al estar en ella }
local scrollers = {}
local current = -1

local function zoneOf(pos)
	if not pos or pos.Y > 400 then
		return 0 -- isla del Olimpo o sin personaje
	end
	local start = Config.CORRIDOR_START
	if pos.Z < start then
		return 0
	end
	return math.clamp(math.floor((pos.Z - start) / Config.ZONE_LENGTH) + 1, 1, #Config.ZONES)
end

local function zoneCenterZ(i)
	return Config.CORRIDOR_START + (i - 0.5) * Config.ZONE_LENGTH
end

local function anchorPart(name, cf, size)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	p.Transparency = 1
	p.Size = size or Vector3.new(1, 1, 1)
	p.CFrame = cf
	p.Parent = folder
	return p
end

local function emitter(parent, props)
	local e = Instance.new("ParticleEmitter")
	e.LightInfluence = 0
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Enabled = false
	e.Parent = parent
	return e
end

-- Construye los efectos de una zona (apagados hasta que entras en ella)
local function build(i, look)
	local VFX = Config.VFX
	local list = {}
	local cz = zoneCenterZ(i)
	local W = Config.CORRIDOR_HALF_WIDTH
	if look.fx == "aurora" or look.fx == "cosmic" then
		-- cortinas de aurora: haces anchos y curvos muy por encima de las murallas, que ondulan
		for k = 1, 3 do
			local a = anchorPart("Aurora", CFrame.new(-150, 95 + k * 14, cz - 60 + k * 30))
			local b = anchorPart("Aurora", CFrame.new(150, 105 + k * 12, cz - 30 + k * 22))
			local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
			a0.Parent, a1.Parent = a, b
			local beam = Instance.new("Beam")
			beam.Attachment0, beam.Attachment1 = a0, a1
			beam.Texture = VFX.aurora or VFX.smoke
			beam.TextureMode = Enum.TextureMode.Wrap
			beam.TextureLength = 90
			beam.TextureSpeed = 0.15 + k * 0.05
			beam.Width0, beam.Width1 = 55, 40
			beam.CurveSize0, beam.CurveSize1 = 50, -35
			beam.FaceCamera = true
			beam.LightEmission = 1
			beam.LightInfluence = 0
			beam.Segments = 30
			beam.Color = ColorSequence.new(look.color, look.color2)
			beam.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.15), NumberSequenceKeypoint.new(0.75, 0.2), NumberSequenceKeypoint.new(1, 1) })
			beam.Enabled = false
			beam.Parent = a
			table.insert(list, beam)
		end
	end
	if look.fx == "cosmic" then
		-- estrellas fugaces y dos planetas en el horizonte
		local sky = anchorPart("ShootingStars", CFrame.new(0, 240, cz), Vector3.new(500, 1, 260))
		table.insert(list, emitter(sky, {
			Texture = VFX.streak, Rate = 2.5, Lifetime = NumberRange.new(0.8, 1.3), Speed = NumberRange.new(160, 230),
			EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(35, 35), Orientation = Enum.ParticleOrientation.VelocityParallel,
			LightEmission = 1, Color = ColorSequence.new(Color3.new(1, 1, 1), look.color2),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.2, 2.6), NumberSequenceKeypoint.new(1, 0) }),
		}))
		for k, info in ipairs({ { x = -230, y = 170, r = 90, c = rgb(170, 90, 255) }, { x = 210, y = 210, r = 55, c = rgb(80, 220, 255) } }) do
			local planet = Instance.new("Part")
			planet.Name = "Planet"
			planet.Shape = Enum.PartType.Ball
			planet.Anchored, planet.CanCollide, planet.CanQuery, planet.CanTouch, planet.CastShadow = true, false, false, false, false
			planet.Material = Enum.Material.Neon
			planet.Color = info.c
			planet.Size = Vector3.new(info.r, info.r, info.r)
			planet.CFrame = CFrame.new(info.x, info.y, cz + (k == 1 and 120 or -80))
			planet.Transparency = 1
			planet:SetAttribute("On", 0.15)
			planet.Parent = folder
			table.insert(list, planet)
		end
	elseif look.fx == "ash" then
		-- ceniza que cae y brasas que flotan (alrededor de la cámara: ver ZoneSky.step)
		local cloud = anchorPart("Ash", CFrame.new(0, 60, cz), Vector3.new(W * 2, 1, Config.ZONE_LENGTH))
		table.insert(list, emitter(cloud, {
			Texture = VFX.smoke, Rate = 30, Lifetime = NumberRange.new(5, 8), Speed = NumberRange.new(4, 8),
			EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(25, 25), RotSpeed = NumberRange.new(-60, 60),
			LightEmission = 0, Color = ColorSequence.new(rgb(70, 60, 60), rgb(30, 25, 25)),
			Size = NumberSequence.new(0.5, 0.9), Transparency = NumberSequence.new(0.3, 1),
		}))
		table.insert(list, emitter(cloud, {
			Texture = VFX.sparkle, Rate = 14, Lifetime = NumberRange.new(4, 6), Speed = NumberRange.new(3, 6),
			EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(40, 40),
			LightEmission = 1, Color = ColorSequence.new(rgb(255, 200, 90), rgb(255, 60, 20)),
			Size = NumberSequence.new(0.5, 0), Transparency = NumberSequence.new(0, 1),
		}))
	elseif look.fx == "lanterns" then
		-- linternas de papel que suben al cielo del atardecer
		local ground = anchorPart("Lanterns", CFrame.new(0, 2, cz), Vector3.new(W * 2 + 120, 1, Config.ZONE_LENGTH))
		table.insert(list, emitter(ground, {
			Texture = VFX.glow, Rate = 6, Lifetime = NumberRange.new(14, 20), Speed = NumberRange.new(4, 7),
			EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(10, 10), Drag = 0.05,
			LightEmission = 0.9, Color = ColorSequence.new(rgb(255, 190, 90), rgb(255, 120, 60)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.05, 2.2), NumberSequenceKeypoint.new(1, 1.4) }),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.2), NumberSequenceKeypoint.new(0.8, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		}))
	elseif look.fx == "goldDust" then
		-- polvo dorado suspendido en la luz
		local air = anchorPart("GoldDust", CFrame.new(0, 25, cz), Vector3.new(W * 2, 40, Config.ZONE_LENGTH))
		table.insert(list, emitter(air, {
			Texture = VFX.sparkle, Rate = 22, Lifetime = NumberRange.new(4, 7), Speed = NumberRange.new(0.3, 1),
			SpreadAngle = Vector2.new(180, 180), RotSpeed = NumberRange.new(-60, 60),
			LightEmission = 1, Color = ColorSequence.new(rgb(255, 245, 200), rgb(255, 200, 90)),
			Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.3, 0.5), NumberSequenceKeypoint.new(1, 0) }),
		}))
	end
	fxByZone[i] = list
end

local function setZoneFx(i, on)
	for _, inst in ipairs(fxByZone[i] or {}) do
		if inst:IsA("ParticleEmitter") or inst:IsA("Beam") then
			inst.Enabled = on
		elseif inst:IsA("BasePart") then
			TweenService:Create(inst, TweenInfo.new(1.5), { Transparency = on and (inst:GetAttribute("On") or 0) or 1 }):Play()
		end
	end
end

local function apply(i)
	local look = LOOKS[i] or LOOKS[0]
	local info = TweenInfo.new(2, Enum.EasingStyle.Sine)
	local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
	if clouds then
		TweenService:Create(clouds, info, { Color = look.clouds, Cover = look.cover, Density = look.density }):Play()
	end
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if sky then
		TweenService:Create(sky, info, { SunAngularSize = look.sun }):Play()
	end
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect")
	if rays then
		TweenService:Create(rays, info, { Intensity = look.rays }):Play()
	end
	if current >= 0 then
		setZoneFx(current, false)
	end
	setZoneFx(i, true)
	current = i
end

local function trackScroll(tex)
	if tex:IsA("Texture") then
		table.insert(scrollers, tex)
	end
end

function ZoneSky.start(ctx)
	if started then
		return
	end
	started = true
	Config = ctx and ctx.Config or require(game:GetService("ReplicatedStorage"):WaitForChild("Shared"):WaitForChild("Config"))
	folder = Instance.new("Folder")
	folder.Name = "ZoneSkyFx"
	folder.Parent = workspace
	for i = 1, #Config.ZONES do
		local ok, err = pcall(build, i, LOOKS[i] or LOOKS[0])
		if not ok then
			warn("[SAG] ZoneSky zona " .. i .. ": " .. tostring(err))
		end
	end
	for _, t in ipairs(CollectionService:GetTagged("FxScroll")) do
		trackScroll(t)
	end
	CollectionService:GetInstanceAddedSignal("FxScroll"):Connect(trackScroll)
	local acc = 0
	RunService.RenderStepped:Connect(function(dt)
		-- suelo de galaxia: las capas se desplazan despacio
		for k = #scrollers, 1, -1 do
			local t = scrollers[k]
			if t.Parent then
				t.OffsetStudsU = (t.OffsetStudsU + (t:GetAttribute("ScrollU") or 0) * dt) % t.StudsPerTileU
				t.OffsetStudsV = (t.OffsetStudsV + (t:GetAttribute("ScrollV") or 0) * dt) % t.StudsPerTileV
			else
				table.remove(scrollers, k)
			end
		end
		acc += dt
		if acc < 0.5 then
			return
		end
		acc = 0
		local char = Players.LocalPlayer.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local cam = workspace.CurrentCamera
		local z = zoneOf(hrp and hrp.Position or (cam and cam.CFrame.Position))
		if z ~= current then
			apply(z)
		end
	end)
end

return ZoneSky
