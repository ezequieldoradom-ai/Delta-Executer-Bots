-- Lucky Obby Race — cielo galáctico vivo (Shadow). Solo visual y en tu pantalla:
--   · Planetas gigantes lejanos (con anillos y brillo) que giran despacio alrededor del mapa.
--   · Estrellas fugaces cada pocos segundos (bola de neón con estela).
--   · Polvo de estrellas que brilla alrededor de la cámara y una aurora que ondula.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local folder = Instance.new("Folder")
folder.Name = "GalaxySky"
folder.Parent = workspace.CurrentCamera

local CENTER = Vector3.new(-55, 0, -70) -- centro del mapa (Decor.ISLAND_CENTER)

local function part(props)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = folder
	return p
end

-- PLANETAS
local planets = {}
local DEFS = {
	{ r = 120, dist = 900, h = 260, color = Color3.fromRGB(255, 120, 200), ring = true, speed = 0.004, phase = 0.3 },
	{ r = 70, dist = 800, h = 180, color = Color3.fromRGB(110, 170, 255), ring = false, speed = -0.006, phase = 2.2 },
	{ r = 45, dist = 700, h = 330, color = Color3.fromRGB(255, 190, 90), ring = true, speed = 0.008, phase = 4.1 },
	{ r = 28, dist = 650, h = 120, color = Color3.fromRGB(140, 255, 210), ring = false, speed = -0.01, phase = 5.3 },
}
for _, d in ipairs(DEFS) do
	local body = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * d.r * 2, Color = d.color, Material = Enum.Material.SmoothPlastic })
	local glow = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * (d.r * 2 + 10), Color = d.color, Material = Enum.Material.Neon, Transparency = 0.85 })
	local ring
	if d.ring then
		ring = part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, d.r * 4, d.r * 4), Color = d.color:Lerp(Color3.new(1, 1, 1), 0.5), Material = Enum.Material.Neon, Transparency = 0.45 })
	end
	table.insert(planets, { d = d, body = body, glow = glow, ring = ring })
end

-- AURORA (cintas de neón semitransparentes que ondulan arriba)
local auroras = {}
for i = 1, 5 do
	local a = part({ Size = Vector3.new(500, 40, 1), Color = Color3.fromHSV(0.75 + i * 0.04, 0.6, 1), Material = Enum.Material.Neon, Transparency = 0.82 })
	table.insert(auroras, { p = a, i = i })
end

-- POLVO DE ESTRELLAS alrededor de la cámara
local dustHolder = part({ Size = Vector3.new(160, 60, 160), Transparency = 1 })
local dust = Instance.new("ParticleEmitter")
dust.Shape = Enum.ParticleEmitterShape.Box
dust.Texture = "rbxasset://textures/particles/sparkles_main.dds"
dust.Rate = 40
dust.Lifetime = NumberRange.new(3, 6)
dust.Speed = NumberRange.new(0, 1)
dust.SpreadAngle = Vector2.new(180, 180)
dust.LightEmission = 1
dust.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, 0.45), NumberSequenceKeypoint.new(1, 0) })
dust.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(190, 150, 255))
dust.Parent = dustHolder

-- ESTRELLAS FUGACES
local shooting = {}
local nextShoot = os.clock() + 2
local function spawnShootingStar()
	local cam = workspace.CurrentCamera
	local base = cam and cam.CFrame.Position or CENTER
	local ang = math.random() * math.pi * 2
	local from = base + Vector3.new(math.cos(ang) * 400, 180 + math.random() * 140, math.sin(ang) * 400)
	local dir = (Vector3.new(-math.cos(ang), -0.35, -math.sin(ang)) + Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 0.8).Unit
	local head = part({ Shape = Enum.PartType.Ball, Size = Vector3.one * 4, Color = Color3.fromRGB(255, 250, 220), Material = Enum.Material.Neon })
	local a0 = Instance.new("Attachment")
	a0.Position = Vector3.new(0, 1.5, 0)
	a0.Parent = head
	local a1 = Instance.new("Attachment")
	a1.Position = Vector3.new(0, -1.5, 0)
	a1.Parent = head
	local tr = Instance.new("Trail")
	tr.Attachment0, tr.Attachment1 = a0, a1
	tr.Lifetime = 0.6
	tr.LightEmission = 1
	tr.FaceCamera = true
	tr.Color = ColorSequence.new(Color3.fromRGB(255, 255, 255), Color3.fromRGB(180, 130, 255))
	tr.Transparency = NumberSequence.new(0, 1)
	tr.WidthScale = NumberSequence.new(1, 0)
	tr.Parent = head
	head.CFrame = CFrame.new(from)
	table.insert(shooting, { p = head, pos = from, dir = dir, t0 = os.clock(), life = 2.2 })
end

RunService.RenderStepped:Connect(function(dt)
	local t = os.clock()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or CENTER
	-- planetas en órbita lenta (siempre lejos: siguen a la cámara para que parezcan "en el cielo")
	for _, pl in ipairs(planets) do
		local d = pl.d
		local ang = d.phase + t * d.speed
		local pos = Vector3.new(camPos.X, 0, camPos.Z) + Vector3.new(math.cos(ang) * d.dist, d.h, math.sin(ang) * d.dist)
		pl.body.CFrame = CFrame.new(pos) * CFrame.Angles(0, t * 0.05, 0)
		pl.glow.CFrame = pl.body.CFrame
		if pl.ring then
			pl.ring.CFrame = CFrame.new(pos) * CFrame.Angles(0.35, ang, math.rad(90) + 0.25)
		end
	end
	for _, a in ipairs(auroras) do
		local ph = t * 0.15 + a.i
		a.p.CFrame = CFrame.new(Vector3.new(camPos.X, 260 + a.i * 14, camPos.Z) + Vector3.new(math.sin(ph) * 60, math.sin(ph * 1.7) * 10, -300 + a.i * 30)) * CFrame.Angles(math.sin(ph) * 0.15, 0, math.sin(ph * 0.7) * 0.1)
		a.p.Transparency = 0.78 + math.sin(t * 0.8 + a.i) * 0.08
	end
	dustHolder.CFrame = CFrame.new(camPos)
	-- estrellas fugaces
	if t > nextShoot then
		nextShoot = t + 2.5 + math.random() * 4
		spawnShootingStar()
	end
	for i = #shooting, 1, -1 do
		local s = shooting[i]
		local age = t - s.t0
		if age > s.life then
			s.p:Destroy()
			table.remove(shooting, i)
		else
			s.pos += s.dir * 420 * dt
			s.p.CFrame = CFrame.lookAt(s.pos, s.pos + s.dir) * CFrame.Angles(math.rad(90), 0, 0)
		end
	end
end)
local _ = player
