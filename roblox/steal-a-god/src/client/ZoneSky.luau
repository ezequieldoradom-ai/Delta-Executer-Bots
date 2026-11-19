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

---------------------------------------------------------------------
-- AIRE MÍSTICO (petición del dueño: "efectos compatibles con cada bioma, muy épico y místico").
-- Un volumen invisible que sigue a la cámara y suelta las partículas del bioma alrededor del jugador
-- (así se ven siempre, en cualquier punto de la zona, con pocos emisores). Y columnas de luz que bajan del cielo.
---------------------------------------------------------------------
local AIR = {
	[1] = { -- griega: motas doradas y plumas de luz que caen despacio
		{ tex = "sparkle", rate = 18, life = { 4, 7 }, speed = { 0.3, 1 }, size = 0.45, colors = { rgb(255, 250, 220), rgb(255, 205, 90) }, up = 0.4 },
		{ tex = "glow", rate = 4, life = { 6, 9 }, speed = { 0.5, 1.2 }, size = 1.4, colors = { rgb(255, 240, 190), rgb(255, 255, 255) }, up = -0.6, alpha = 0.45 },
	},
	[2] = { -- celta: luciérnagas y fuegos fatuos verdes que bailan
		{ tex = "glow", rate = 16, life = { 3, 6 }, speed = { 0.6, 1.6 }, size = 0.55, colors = { rgb(200, 255, 120), rgb(90, 255, 150) }, up = 0.3, twinkle = true },
		{ tex = "glow", rate = 2, life = { 6, 9 }, speed = { 1, 2 }, size = 2.4, colors = { rgb(120, 255, 200), rgb(60, 200, 255) }, up = 0.6, alpha = 0.35 },
		{ tex = "smoke", rate = 3, life = { 6, 9 }, speed = { 0.3, 0.8 }, size = 9, colors = { rgb(170, 255, 210), rgb(120, 200, 170) }, up = 0.1, alpha = 0.85, emission = 0.3, low = true },
	},
	[3] = { -- egipcia: arena que vuela con el viento y jeroglíficos dorados que flotan
		{ tex = "smoke", rate = 6, life = { 3, 5 }, speed = { 8, 14 }, size = 5, colors = { rgb(255, 215, 150), rgb(220, 170, 100) }, wind = Vector3.new(14, 1, 4), alpha = 0.75, emission = 0.1, low = true },
		{ tex = "sparkle", rate = 14, life = { 3, 5 }, speed = { 6, 10 }, size = 0.3, colors = { rgb(255, 235, 170), rgb(255, 190, 80) }, wind = Vector3.new(12, 0, 3) },
		{ tex = "runes", rate = 1.2, life = { 6, 8 }, speed = { 0.4, 1 }, size = 3, colors = { rgb(255, 215, 110), rgb(255, 170, 60) }, up = 0.5, alpha = 0.35, spin = 25 },
	},
	[4] = { -- azteca: ascuas, espíritus de jade y ceniza
		{ tex = "sparkle", rate = 20, life = { 3, 5 }, speed = { 1.5, 3.5 }, size = 0.45, colors = { rgb(255, 210, 110), rgb(255, 70, 20) }, up = 2.2 },
		{ tex = "glow", rate = 3, life = { 5, 8 }, speed = { 1, 2 }, size = 1.8, colors = { rgb(90, 255, 210), rgb(40, 180, 140) }, up = 1, alpha = 0.4, twinkle = true },
	},
	[5] = { -- babilonia: runas doradas que giran y polvo de estrellas rosado
		{ tex = "runes", rate = 1.5, life = { 6, 9 }, speed = { 0.3, 0.9 }, size = 3.6, colors = { rgb(255, 225, 120), rgb(255, 160, 210) }, up = 0.4, alpha = 0.3, spin = 35 },
		{ tex = "sparkle", rate = 16, life = { 4, 6 }, speed = { 0.4, 1.2 }, size = 0.4, colors = { rgb(255, 210, 240), rgb(255, 220, 120) }, up = 0.5 },
	},
	[6] = { -- cósmica: polvo estelar, nebulosa y destellos de energía
		{ tex = "sparkle", rate = 26, life = { 3, 6 }, speed = { 0.3, 1.2 }, size = 0.5, colors = { rgb(200, 240, 255), rgb(200, 120, 255) }, up = 0.2, twinkle = true },
		{ tex = "smoke", rate = 3, life = { 7, 10 }, speed = { 0.4, 1 }, size = 14, colors = { rgb(160, 80, 255), rgb(60, 200, 255) }, up = 0.2, alpha = 0.82, emission = 0.8 },
		{ tex = "streak", rate = 4, life = { 0.4, 0.7 }, speed = { 18, 28 }, size = 1.6, colors = { rgb(255, 255, 255), rgb(120, 230, 255) }, parallel = true },
	},
}
-- columnas de luz que bajan del cielo en cada zona (color del bioma)
local PILLARS = {
	[1] = rgb(255, 225, 140), [2] = rgb(120, 255, 170), [3] = rgb(255, 205, 110),
	[4] = rgb(90, 255, 210), [5] = rgb(255, 200, 120), [6] = rgb(180, 110, 255),
}

local airPart -- sigue a la cámara
local airByZone = {}

local function buildAir()
	airPart = Instance.new("Part")
	airPart.Name = "MysticAir"
	airPart.Anchored, airPart.CanCollide, airPart.CanQuery, airPart.CanTouch, airPart.CastShadow = true, false, false, false, false
	airPart.Transparency = 1
	airPart.Size = Vector3.new(70, 26, 70)
	airPart.Parent = folder
	local low = Instance.new("Attachment") -- para la niebla y la arena: pegadas al suelo
	low.Name = "Low"
	low.Position = Vector3.new(0, -10, 0)
	low.Parent = airPart
	for i, list in pairs(AIR) do
		airByZone[i] = {}
		for _, a in ipairs(list) do
			local e = Instance.new("ParticleEmitter")
			e.Texture = Config.VFX[a.tex]
			e.Rate = a.rate
			e.Lifetime = NumberRange.new(a.life[1], a.life[2])
			e.Speed = NumberRange.new(a.speed[1], a.speed[2])
			e.SpreadAngle = Vector2.new(180, 180)
			e.Shape = Enum.ParticleEmitterShape.Box
			e.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
			e.Acceleration = a.wind or Vector3.new(0, a.up or 0, 0)
			e.Drag = a.wind and 0 or 0.4
			e.Rotation = NumberRange.new(0, 360)
			e.RotSpeed = NumberRange.new(-(a.spin or 40), a.spin or 40)
			e.LightEmission = a.emission or 1
			e.LightInfluence = 0
			local kp = {}
			for k, c in ipairs(a.colors) do
				kp[k] = ColorSequenceKeypoint.new((k - 1) / math.max(1, #a.colors - 1), c)
			end
			e.Color = ColorSequence.new(kp)
			local base = a.alpha or 0.1
			if a.twinkle then
				e.Transparency = NumberSequence.new({
					NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.15, base), NumberSequenceKeypoint.new(0.3, 0.7),
					NumberSequenceKeypoint.new(0.45, base), NumberSequenceKeypoint.new(0.65, 0.75), NumberSequenceKeypoint.new(0.8, base), NumberSequenceKeypoint.new(1, 1),
				})
			else
				e.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, base), NumberSequenceKeypoint.new(0.8, base), NumberSequenceKeypoint.new(1, 1) })
			end
			e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, a.size * 0.5), NumberSequenceKeypoint.new(0.5, a.size), NumberSequenceKeypoint.new(1, a.size * 0.6) })
			if a.parallel then
				e.Orientation = Enum.ParticleOrientation.VelocityParallel
			end
			e.Enabled = false
			e.Parent = a.low and low or airPart
			table.insert(airByZone[i], e)
		end
	end
end

local function buildPillars(i)
	fxByZone[i] = fxByZone[i] or {}
	local cz = zoneCenterZ(i)
	local W = Config.CORRIDOR_HALF_WIDTH
	local color = PILLARS[i]
	local rng = Random.new(77 + i)
	for k = 1, 5 do
		local x = rng:NextNumber(-W + 10, W - 10)
		local z = cz + rng:NextNumber(-80, 80)
		local top = anchorPart("LightPillar", CFrame.new(x, 260, z))
		local a0, a1 = Instance.new("Attachment"), Instance.new("Attachment")
		a0.Parent = top
		a1.Position = Vector3.new(0, -258, 0)
		a1.Parent = top
		local b = Instance.new("Beam")
		b.Attachment0, b.Attachment1 = a0, a1
		b.FaceCamera = true
		b.Width0, b.Width1 = 18, 6
		b.LightEmission = 0.6
		b.LightInfluence = 0
		b.Color = ColorSequence.new(color)
		b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.4, 0.8), NumberSequenceKeypoint.new(1, 0.55) })
		b.Segments = 1
		b.Enabled = false
		b:SetAttribute("Phase", k * 1.3)
		b.Parent = top
		table.insert(fxByZone[i], b)
		-- destellos que bajan por la columna
		local e = emitter(top, {
			Texture = Config.VFX.sparkle, Rate = 6, Lifetime = NumberRange.new(4, 5), Speed = NumberRange.new(55, 65),
			EmissionDirection = Enum.NormalId.Bottom, SpreadAngle = Vector2.new(2, 2), LightEmission = 1,
			Color = ColorSequence.new(Color3.new(1, 1, 1), color), Size = NumberSequence.new(1.2, 0.4),
		})
		table.insert(fxByZone[i], e)
		-- círculo de luz donde toca el suelo
		local base = anchorPart("PillarBase", CFrame.new(x, 0.35, z))
		local ring = Instance.new("Attachment")
		ring.Parent = base
		table.insert(fxByZone[i], emitter(ring, {
			Texture = Config.VFX.ring, Rate = 0.6, Lifetime = NumberRange.new(2.5), Speed = NumberRange.new(0.01),
			Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(0, 0),
			LightEmission = 1, Color = ColorSequence.new(color), Size = NumberSequence.new(3, 16),
			Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.3), NumberSequenceKeypoint.new(1, 1) }),
		}))
	end
end

local function setAir(i, on)
	for _, e in ipairs(airByZone[i] or {}) do
		e.Enabled = on
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
		setAir(current, false)
	end
	setZoneFx(i, true)
	setAir(i, true)
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
		local okP, errP = pcall(buildPillars, i)
		if not okP then
			warn("[SAG] ZoneSky columnas " .. i .. ": " .. tostring(errP))
		end
	end
	local okA, errA = pcall(buildAir)
	if not okA then
		warn("[SAG] ZoneSky aire: " .. tostring(errA))
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
		-- el aire místico va delante de la cámara; las columnas de luz respiran
		local camNow = workspace.CurrentCamera
		if airPart and camNow then
			local p = camNow.CFrame.Position + camNow.CFrame.LookVector * 22
			airPart.CFrame = CFrame.new(p.X, math.max(p.Y, 13), p.Z)
		end
		if current > 0 then
			local now = os.clock()
			for _, b in ipairs(fxByZone[current] or {}) do
				local ph = b:IsA("Beam") and b:GetAttribute("Phase")
				if ph then
					local k = 0.5 + 0.5 * math.sin(now * 0.9 + ph)
					b.Width0 = 12 + 10 * k
					b.Width1 = 4 + 4 * k
				end
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
