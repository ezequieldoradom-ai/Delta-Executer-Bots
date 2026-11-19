-- Lucky Obby Race — decoración (Shadow). Solo lo visual: no cambia por dónde se corre ni cómo se gana.
--   · Ambiente: atmósfera, brillo, rayos de sol y nubes.
--   · Vestíbulo: isla flotante de roca y hierba, arco arcoíris, lucky block gigante que gira y confeti de colores.
--   · Recorrido (cada ronda): islas flotantes a los lados, lucky blocks gigantes, arcos arcoíris en los puntos
--     de control y una meta épica con confeti. Se engancha a Course.build sin tocar Course.luau.
-- Todo es Anchored, sin colisión y sin consultas: no estorba a la física ni a los objetos.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Decor = {}
local G, C

local RAINBOW = {
	Color3.fromRGB(255, 80, 90), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 230, 70),
	Color3.fromRGB(90, 220, 110), Color3.fromRGB(70, 170, 255), Color3.fromRGB(170, 100, 255),
}

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = props.CastShadow == true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "CanCollide" and k ~= "CastShadow" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end

-- Cara "?" de un lucky block (las cuatro caras laterales y la de arriba)
local function questionFaces(p)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.LightInfluence = 0
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 20
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.TextScaled = true
		l.Font = Enum.Font.LuckiestGuy
		l.Text = "?"
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeColor3 = Color3.fromRGB(150, 80, 0)
		l.TextStrokeTransparency = 0
		l.Parent = sg
		sg.Parent = p
	end
end

-- Lucky block gigante que gira y flota (lo anima el cliente con las etiquetas FxSpin/FxBob si existen;
-- si no, gira el servidor con un bucle ligero)
local spinners = {}
local function luckyBlock(cf, size, parent)
	local b = part({ Name = "GiantLuckyBlock", Size = Vector3.new(size, size, size), CFrame = cf, Color = Color3.fromRGB(255, 205, 50), Material = Enum.Material.SmoothPlastic, CastShadow = true }, parent)
	questionFaces(b)
	local edge = Instance.new("SelectionBox")
	edge.Adornee = b
	edge.LineThickness = size * 0.04
	edge.Color3 = Color3.fromRGB(255, 140, 0)
	edge.Parent = b
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 210, 90)
	light.Range = size * 2.5
	light.Brightness = 1.2
	light.Parent = b
	local at = Instance.new("Attachment")
	at.Parent = b
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 6
	pe.Lifetime = NumberRange.new(1.5, 2.5)
	pe.Speed = NumberRange.new(2, 4)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 170, 40))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, size * 0.12), NumberSequenceKeypoint.new(1, 0) })
	pe.Parent = at
	table.insert(spinners, { part = b, base = cf, phase = math.random() * 6 })
	return b
end

-- Isla flotante: cono de roca con tapa de hierba y unos arbustos
local function island(pos, r, parent, rng)
	local top = part({ Name = "IslandTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, r * 2, r * 2), CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(90, 200, 90), Material = Enum.Material.Grass, CastShadow = true }, parent)
	local depth = r * 1.4
	for k = 0, 3 do
		local rr = r * (1 - k * 0.22)
		part({ Name = "IslandRock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(depth / 4 + 0.5, rr * 2, rr * 2), CFrame = CFrame.new(pos - Vector3.new(0, 1 + depth / 8 + k * depth / 4, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(130 - k * 10, 105 - k * 8, 85 - k * 6), Material = Enum.Material.Rock }, parent)
	end
	for _ = 1, math.max(1, math.floor(r / 4)) do
		local a = rng:NextNumber(0, math.pi * 2)
		local d = rng:NextNumber(0, r * 0.7)
		local s = rng:NextNumber(2.5, 4.5)
		part({ Name = "Bush", Shape = Enum.PartType.Ball, Size = Vector3.new(s, s, s), CFrame = CFrame.new(pos + Vector3.new(math.cos(a) * d, 1 + s * 0.3, math.sin(a) * d)), Color = Color3.fromRGB(60, 160 + rng:NextInteger(-20, 30), 70), Material = Enum.Material.Grass }, parent)
	end
	return top
end

-- Arco arcoíris de neón (seis franjas) de ancho w, centrado en cf
local function rainbowArch(cf, w, h, parent)
	for i, col in ipairs(RAINBOW) do
		local off = (i - 1) * 0.8
		for _, side in ipairs({ -1, 1 }) do
			part({ Name = "ArchSide", Size = Vector3.new(0.8, h - off, 0.8), CFrame = cf * CFrame.new(side * (w / 2 + off), (h - off) / 2, 0), Color = col, Material = Enum.Material.Neon }, parent)
		end
		part({ Name = "ArchTop", Size = Vector3.new(w + off * 2 + 0.8, 0.8, 0.8), CFrame = cf * CFrame.new(0, h - off, 0), Color = col, Material = Enum.Material.Neon }, parent)
	end
end

local function confetti(parent, cf, size, rate)
	local p = part({ Name = "ConfettiSource", Size = size, CFrame = cf, Transparency = 1 }, parent)
	local pe = Instance.new("ParticleEmitter")
	pe.Shape = Enum.ParticleEmitterShape.Box
	pe.Rate = rate
	pe.Lifetime = NumberRange.new(3, 5)
	pe.Speed = NumberRange.new(2, 6)
	pe.EmissionDirection = Enum.NormalId.Bottom
	pe.SpreadAngle = Vector2.new(30, 30)
	pe.Acceleration = Vector3.new(0, -4, 0)
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-200, 200)
	pe.Size = NumberSequence.new(0.35)
	pe.LightEmission = 0.4
	local kp = {}
	for i, col in ipairs(RAINBOW) do
		kp[i] = ColorSequenceKeypoint.new((i - 1) / (#RAINBOW - 1), col)
	end
	pe.Color = ColorSequence.new(kp)
	pe.Parent = p
	return p
end

-- Ambiente general
local function sky()
	Lighting.Brightness = 2.8
	Lighting.OutdoorAmbient = Color3.fromRGB(150, 150, 170)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density = 0.3
	atm.Haze = 1.2
	atm.Glare = 0.4
	atm.Color = Color3.fromRGB(200, 225, 255)
	atm.Decay = Color3.fromRGB(255, 220, 200)
	atm.Parent = Lighting
	local bloom = Lighting:FindFirstChildOfClass("BloomEffect") or Instance.new("BloomEffect")
	bloom.Intensity = 0.6
	bloom.Size = 24
	bloom.Threshold = 1.6
	bloom.Parent = Lighting
	local rays = Lighting:FindFirstChildOfClass("SunRaysEffect") or Instance.new("SunRaysEffect")
	rays.Intensity = 0.1
	rays.Parent = Lighting
	local cc = Lighting:FindFirstChildOfClass("ColorCorrectionEffect") or Instance.new("ColorCorrectionEffect")
	cc.Saturation = 0.2
	cc.Contrast = 0.08
	cc.Parent = Lighting
	pcall(function()
		local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds") or Instance.new("Clouds")
		clouds.Cover = 0.55
		clouds.Density = 0.5
		clouds.Parent = workspace.Terrain
	end)
end

-- Vestíbulo
local function lobby()
	local f = Instance.new("Folder")
	f.Name = "LobbyDecor"
	local c = C.LOBBY - Vector3.new(0, 4, 0)
	local rng = Random.new(77)
	-- la plataforma del vestíbulo se convierte en isla flotante
	for k = 0, 4 do
		local rr = 35 * (1 - k * 0.18)
		part({ Name = "LobbyRock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, rr * 2, rr * 2), CFrame = CFrame.new(c - Vector3.new(0, 4.5 + k * 6.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(135 - k * 10, 110 - k * 8, 90 - k * 6), Material = Enum.Material.Rock }, f)
	end
	-- arco arcoíris hacia la salida de la carrera (+Z) y lucky block gigante en el centro
	rainbowArch(CFrame.new(c + Vector3.new(0, 1, 30)), 16, 18, f)
	luckyBlock(CFrame.new(c + Vector3.new(0, 16, 0)), 7, f)
	confetti(f, CFrame.new(c + Vector3.new(0, 30, 0)), Vector3.new(60, 1, 60), 25)
	-- islitas alrededor
	for i = 1, 6 do
		local a = i / 6 * math.pi * 2 + 0.4
		island(c + Vector3.new(math.cos(a) * 75, rng:NextNumber(-10, 12), math.sin(a) * 75), rng:NextNumber(6, 11), f, rng)
	end
	f.Parent = workspace
end

-- Decora el recorrido recién creado (va dentro de su carpeta: se borra con él en cada ronda)
function Decor.course(folder)
	if not folder then
		return
	end
	local seed = folder:GetAttribute("Seed") or 1
	local rng = Random.new(seed + 99)
	local y = C.START.Y
	local finishZ = folder:GetAttribute("FinishZ") or (C.START.Z + C.SEGMENTS * C.SEG_LEN)
	local d = Instance.new("Folder")
	d.Name = "Decor"
	-- islas y lucky blocks gigantes a los lados, bien lejos del camino
	local z = C.START.Z
	local side = 1
	while z < finishZ do
		side = -side
		local x = side * rng:NextNumber(C.WIDTH / 2 + 30, C.WIDTH / 2 + 70)
		local pos = Vector3.new(x, y + rng:NextNumber(-30, 10), z + rng:NextNumber(-10, 10))
		if rng:NextNumber() < 0.65 then
			island(pos, rng:NextNumber(7, 15), d, rng)
		else
			luckyBlock(CFrame.new(pos + Vector3.new(0, 10, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(6, 10), d)
		end
		z += rng:NextNumber(22, 38)
	end
	-- arcos arcoíris en la salida y en cada punto de control
	for i, cp in pairs(G.Course.checkpoints) do
		rainbowArch(CFrame.new(0, cp.pos.Y - 3, cp.pos.Z - (i == 0 and -9 or 0)), C.WIDTH + 2, 14, d)
	end
	-- meta: arco grande dorado, lucky blocks a los lados y lluvia de confeti
	local fz = finishZ + 10
	rainbowArch(CFrame.new(0, y - 0.5, fz - 6), C.WIDTH + 12, 24, d)
	for _, sx in ipairs({ -1, 1 }) do
		luckyBlock(CFrame.new(sx * (C.WIDTH / 2 + 10), y + 6, fz), 5, d)
	end
	confetti(d, CFrame.new(0, y + 26, fz), Vector3.new(C.WIDTH + 10, 1, 24), 60)
	d.Parent = folder
end

function Decor.init(g)
	G = g
	C = g.Config.COURSE
	sky()
	lobby()
	-- engancharse a cada recorrido nuevo sin tocar Course.luau
	local build = G.Course.build
	G.Course.build = function(...)
		local f = build(...)
		local ok, err = pcall(Decor.course, f)
		if not ok then
			warn("[Decor] " .. tostring(err))
		end
		return f
	end
	-- los lucky blocks gigantes giran y flotan despacio (pocos y anclados: barato)
	task.spawn(function()
		while true do
			local t = os.clock()
			for i = #spinners, 1, -1 do
				local s = spinners[i]
				if s.part.Parent then
					s.part.CFrame = s.base * CFrame.new(0, math.sin(t * 1.2 + s.phase) * 1.2, 0) * CFrame.Angles(0, t * 0.8 + s.phase, 0)
				else
					table.remove(spinners, i)
				end
			end
			task.wait(1 / 20)
		end
	end)
end

return Decor
