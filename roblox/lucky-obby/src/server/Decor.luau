-- Lucky Obby Race — decoración (Shadow). Solo lo visual: no cambia por dónde se corre ni cómo se gana.
--   · Ambiente: atmósfera, brillo, rayos de sol y nubes.
--   · Vestíbulo: isla flotante de roca y hierba, arco arcoíris, lucky block gigante que gira y confeti de colores.
--   · Recorrido (cada ronda): islas flotantes a los lados, lucky blocks gigantes, arcos arcoíris en los puntos
--     de control y una meta épica con confeti. Se engancha a Course.build sin tocar Course.luau.
-- Todo es Anchored, sin colisión y sin consultas: no estorba a la física ni a los objetos.
local CollectionService = game:GetService("CollectionService")
local Lighting = game:GetService("Lighting")

local Decor = {}
-- disposición del vestíbulo (la usan también Hub, Extras, Lobby y Slap)
Decor.LOBBY_R = 58 -- radio del suelo del vestíbulo
Decor.HILL = Vector3.new(76, 0, -134) -- arena del "Rey de la colina" (a la derecha)
Decor.PLAZA = Vector3.new(-125, 0, -40) -- plaza de "¿Quién ha sido?" (a un lado, no detrás de los tablones)
Decor.ISLAND_CENTER = Vector3.new(-55, 0, -70)
Decor.ISLAND_R = 175
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
	Lighting.Brightness = 2.6
	Lighting.OutdoorAmbient = Color3.fromRGB(165, 150, 200)
	Lighting.ClockTime = 14.5
	-- CIELO GALÁCTICO (textura de nebulosa propia del dueño) sin sol ni luna; lo animan los clientes (GalaxySky)
	local skyObj = Lighting:FindFirstChildOfClass("Sky") or Instance.new("Sky")
	local GAL = "rbxassetid://102219515094576"
	skyObj.SkyboxBk, skyObj.SkyboxDn, skyObj.SkyboxFt = GAL, GAL, GAL
	skyObj.SkyboxLf, skyObj.SkyboxRt, skyObj.SkyboxUp = GAL, GAL, GAL
	skyObj.CelestialBodiesShown = false
	skyObj.StarCount = 3000
	skyObj.Parent = Lighting
	pcall(function()
		local cl = workspace.Terrain:FindFirstChildOfClass("Clouds")
		if cl then
			cl:Destroy()
		end
	end)
	local atm = Lighting:FindFirstChildOfClass("Atmosphere") or Instance.new("Atmosphere")
	atm.Density = 0.12
	atm.Haze = 0
	atm.Glare = 0
	atm.Color = Color3.fromRGB(150, 120, 230)
	atm.Decay = Color3.fromRGB(90, 60, 160)
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

end

-- Vestíbulo
local function lobby()
	local f = Instance.new("Folder")
	f.Name = "LobbyDecor"
	local c = C.LOBBY - Vector3.new(0, 4, 0)
	local rng = Random.new(77)
	-- GRAN PLATAFORMA DE OBBY flotando en la galaxia: suelo a cuadros de colores (como el vestíbulo)
	-- y una muralla de bloques arcoíris alrededor (con almenas de neón)
	local mid = Decor.ISLAND_CENTER
	local RR = Decor.ISLAND_R
	part({ Name = "Platform", Shape = Enum.PartType.Cylinder, Size = Vector3.new(4, RR * 2, RR * 2), CFrame = CFrame.new(mid.X, -1.5, mid.Z) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(245, 240, 232), Material = Enum.Material.SmoothPlastic, CanCollide = true }, f)
	part({ Name = "PlatformUnder", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, RR * 2 - 6, RR * 2 - 6), CFrame = CFrame.new(mid.X, -4, mid.Z) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(170, 100, 255), Material = Enum.Material.Neon }, f)
	local PASTEL = {
		Color3.fromRGB(255, 150, 160), Color3.fromRGB(255, 200, 120), Color3.fromRGB(255, 235, 130),
		Color3.fromRGB(150, 230, 150), Color3.fromRGB(130, 200, 255), Color3.fromRGB(200, 160, 255),
	}
	local TILE = 10
	local lobbyC = Vector3.new(c.X, 0, c.Z)
	for ix = -math.ceil(RR / TILE), math.ceil(RR / TILE) do
		for iz = -math.ceil(RR / TILE), math.ceil(RR / TILE) do
			if (ix + iz) % 2 == 0 then
				local x, z = mid.X + ix * TILE, mid.Z + iz * TILE
				local pp = Vector3.new(x, 0, z)
				local inside = (pp - Vector3.new(mid.X, 0, mid.Z)).Magnitude + TILE * 0.75 < RR - 4
				local inLobby = (pp - lobbyC).Magnitude < Decor.LOBBY_R + TILE * 0.75
				local inPlaza = Decor.PLAZA and (pp - Vector3.new(Decor.PLAZA.X, 0, Decor.PLAZA.Z)).Magnitude < 44 + TILE * 0.75
				if inside and not inLobby and not inPlaza then
					local ang = math.atan2(x - mid.X, z - mid.Z)
					local sector = math.floor(((ang + math.pi) / (2 * math.pi)) * #PASTEL) % #PASTEL + 1
					part({ Name = "FloorTile", Size = Vector3.new(TILE - 0.3, 0.06, TILE - 0.3), CFrame = CFrame.new(x, 0.53, z), Color = PASTEL[sector], Material = Enum.Material.SmoothPlastic }, f)
				end
			end
		end
	end
	-- muralla
	local segLen = 8
	local nSeg = math.floor(2 * math.pi * (RR - 2) / segLen)
	for k = 0, nSeg - 1 do
		local ang = k / nSeg * math.pi * 2
		local pos = Vector3.new(mid.X + math.cos(ang) * (RR - 2), 0, mid.Z + math.sin(ang) * (RR - 2))
		local cf = CFrame.lookAt(pos, Vector3.new(mid.X, 0, mid.Z))
		local h = 12
		local col = RAINBOW[(k % #RAINBOW) + 1]
		part({ Name = "Wall", Size = Vector3.new(segLen + 0.2, h, 3), CFrame = cf * CFrame.new(0, h / 2 + 0.5, 0), Color = col, Material = Enum.Material.SmoothPlastic, CanCollide = true, CastShadow = true }, f)
		part({ Name = "WallCap", Size = Vector3.new(segLen + 0.3, 0.5, 3.4), CFrame = cf * CFrame.new(0, h + 0.75, 0), Color = col:Lerp(Color3.new(1, 1, 1), 0.5), Material = Enum.Material.Neon }, f)
		if k % 2 == 0 then -- almena
			part({ Name = "Merlon", Size = Vector3.new(segLen * 0.55, 3, 3), CFrame = cf * CFrame.new(0, h + 2.5, 0), Color = col, Material = Enum.Material.SmoothPlastic, CanCollide = true }, f)
		end
	end
	-- árboles y flores por la isla (fuera de las zonas de juego)
	local rngD = Random.new(11)
	local mid = Decor.ISLAND_CENTER
	for _ = 1, 40 do
		local a = rngD:NextNumber(0, math.pi * 2)
		local d = rngD:NextNumber(30, Decor.ISLAND_R - 12)
		local p = mid + Vector3.new(math.cos(a) * d, 0, math.sin(a) * d)
		local nearLobby = (Vector3.new(p.X, 0, p.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude < Decor.LOBBY_R + 8
		local nearPlaza = Decor.PLAZA and (Vector3.new(p.X, 0, p.Z) - Vector3.new(Decor.PLAZA.X, 0, Decor.PLAZA.Z)).Magnitude < 52
		local onPath = Decor.PLAZA and (function()
			local A, Bp = Vector3.new(c.X, 0, c.Z), Vector3.new(Decor.PLAZA.X, 0, Decor.PLAZA.Z)
			local ab = Bp - A
			local t = math.clamp((Vector3.new(p.X, 0, p.Z) - A):Dot(ab) / ab:Dot(ab), 0, 1)
			return (A + ab * t - Vector3.new(p.X, 0, p.Z)).Magnitude < 12
		end)()
		local nearHill = (Vector3.new(p.X, 0, p.Z) - Vector3.new(Decor.HILL.X, 0, Decor.HILL.Z)).Magnitude < 36
		local onHillPath = (function()
			local A, Bp = Vector3.new(c.X, 0, c.Z), Vector3.new(Decor.HILL.X, 0, Decor.HILL.Z)
			local ab = Bp - A
			local t = math.clamp((Vector3.new(p.X, 0, p.Z) - A):Dot(ab) / ab:Dot(ab), 0, 1)
			return (A + ab * t - Vector3.new(p.X, 0, p.Z)).Magnitude < 12
		end)()
		if not nearLobby and not nearPlaza and not onPath and not nearHill and not onHillPath then
			local h = rngD:NextNumber(7, 13)
			local trunk = part({ Name = "Trunk", Size = Vector3.new(1.8, h, 1.8), CFrame = CFrame.new(p + Vector3.new(0, h / 2 + 0.5, 0)), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood, CastShadow = true }, f)
			local _ = trunk
			for k = 0, 2 do -- copa de bloques (estilo obby)
				local s = rngD:NextNumber(6, 9) - k * 1.8
				part({ Name = "Leaves", Size = Vector3.new(s, s * 0.8, s), CFrame = CFrame.new(p + Vector3.new(rngD:NextNumber(-1.5, 1.5), h + 1 + k * 2.2, rngD:NextNumber(-1.5, 1.5))), Color = Color3.fromRGB(70, 160 + rngD:NextInteger(-20, 40), 75), Material = Enum.Material.Grass, CastShadow = true }, f)
			end
		end
	end
	-- arco arcoíris hacia la salida de la carrera (+Z) y lucky block gigante en el centro
	rainbowArch(CFrame.new(c + Vector3.new(0, 1, Decor.LOBBY_R - 4)), 16, 18, f)
	luckyBlock(CFrame.new(c + Vector3.new(0, 16, 0)), 7, f)
	confetti(f, CFrame.new(c + Vector3.new(0, 30, 0)), Vector3.new(90, 1, 90), 25)
	local _ = island
	local _2 = rng
	f.Parent = workspace
end

-- BIOMAS ---------------------------------------------------------------------
-- Cada tramo de 3 segmentos (de punto de control a punto de control) es un mundo distinto. El suelo cambia de
-- color y material, pero con el rozamiento del plástico (el hielo NO resbala: la jugabilidad no cambia).
local SAME_FEEL = PhysicalProperties.new(0.7, 0.3, 0.5)
Decor.BIOMES = {
	meadow = { floor = Color3.fromRGB(105, 200, 85), alt = Color3.fromRGB(255, 215, 90), mat = Enum.Material.Grass, altMat = Enum.Material.WoodPlanks, trim = Color3.fromRGB(255, 240, 120) },
	candy = { floor = Color3.fromRGB(255, 165, 210), alt = Color3.fromRGB(140, 220, 255), mat = Enum.Material.SmoothPlastic, altMat = Enum.Material.SmoothPlastic, trim = Color3.fromRGB(255, 90, 190) },
	volcano = { floor = Color3.fromRGB(70, 55, 55), alt = Color3.fromRGB(150, 75, 45), mat = Enum.Material.Basalt, altMat = Enum.Material.CrackedLava, trim = Color3.fromRGB(255, 230, 120) },
	ice = { floor = Color3.fromRGB(205, 238, 255), alt = Color3.fromRGB(125, 195, 255), mat = Enum.Material.Ice, altMat = Enum.Material.Glacier, trim = Color3.fromRGB(140, 240, 255) },
	galaxy = { floor = Color3.fromRGB(50, 32, 95), alt = Color3.fromRGB(125, 75, 225), mat = Enum.Material.Glass, altMat = Enum.Material.Foil, trim = Color3.fromRGB(210, 130, 255) },
	heaven = { floor = Color3.fromRGB(250, 246, 232), alt = Color3.fromRGB(255, 205, 80), mat = Enum.Material.Marble, altMat = Enum.Material.Foil, trim = Color3.fromRGB(255, 220, 90) },
	haunted = { floor = Color3.fromRGB(105, 110, 118), alt = Color3.fromRGB(110, 70, 140), mat = Enum.Material.Slate, altMat = Enum.Material.Cobblestone, trim = Color3.fromRGB(110, 255, 140) },
	desert = { floor = Color3.fromRGB(235, 200, 130), alt = Color3.fromRGB(200, 140, 80), mat = Enum.Material.Sand, altMat = Enum.Material.Sandstone, trim = Color3.fromRGB(255, 160, 60) },
}
local ALT_NAMES = { Mover = true, Beam = true, High = true, Hub = true, Sweeper = true }
local KEEP = { StartPad = true, StartLine = true, CPRing = true, FinishPad = true, FinishPole = true, FinishBanner = true, Belt = true }
local BIOME_ORDER_MID = { "candy", "volcano", "ice", "galaxy", "haunted", "desert" }

local function emitter(parent, props)
	local pe = Instance.new("ParticleEmitter")
	for k, v in pairs(props) do
		pe[k] = v
	end
	pe.Parent = parent
	return pe
end
local function ball(parent, cf, size, color, mat)
	return part({ Name = "Prop", Shape = Enum.PartType.Ball, Size = Vector3.new(size, size, size), CFrame = cf, Color = color, Material = mat or Enum.Material.SmoothPlastic }, parent)
end
local function cyl(parent, cf, h, r, color, mat) -- cilindro vertical de altura h y radio r
	return part({ Name = "Prop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), CFrame = cf * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = mat or Enum.Material.SmoothPlastic }, parent)
end
local function biomeIsland(pos, r, parent, topColor, topMat, rockColor, rockMat)
	cyl(parent, CFrame.new(pos), 2, r, topColor, topMat)
	for k = 0, 3 do
		cyl(parent, CFrame.new(pos - Vector3.new(0, 1.5 + k * r * 0.35, 0)), r * 0.35 + 0.5, r * (1 - k * 0.22), rockColor:Lerp(Color3.new(0, 0, 0), k * 0.08), rockMat)
	end
end

-- Un adorno grande del bioma en pos (a un lado del recorrido)
local PROPS = {}
function PROPS.meadow(pos, d, rng)
	biomeIsland(pos, rng:NextNumber(8, 13), d, Color3.fromRGB(95, 195, 80), Enum.Material.Grass, Color3.fromRGB(130, 100, 75), Enum.Material.Rock)
	for _ = 1, rng:NextInteger(1, 3) do -- árboles
		local p = pos + Vector3.new(rng:NextNumber(-5, 5), 1, rng:NextNumber(-5, 5))
		local h = rng:NextNumber(6, 10)
		cyl(d, CFrame.new(p + Vector3.new(0, h / 2, 0)), h, 0.8, Color3.fromRGB(110, 75, 45), Enum.Material.Wood)
		ball(d, CFrame.new(p + Vector3.new(0, h + 2, 0)), rng:NextNumber(6, 9), Color3.fromRGB(70, 175 + rng:NextInteger(-20, 30), 75), Enum.Material.Grass)
	end
	for _ = 1, 5 do -- flores
		ball(d, CFrame.new(pos + Vector3.new(rng:NextNumber(-7, 7), 1.6, rng:NextNumber(-7, 7))), 1.2, RAINBOW[rng:NextInteger(1, #RAINBOW)], Enum.Material.Neon)
	end
end
function PROPS.candy(pos, d, rng)
	biomeIsland(pos, rng:NextNumber(7, 12), d, Color3.fromRGB(255, 190, 225), Enum.Material.SmoothPlastic, Color3.fromRGB(150, 95, 70), Enum.Material.Slate)
	if rng:NextNumber() < 0.5 then -- piruleta gigante
		local h = rng:NextNumber(12, 18)
		cyl(d, CFrame.new(pos + Vector3.new(0, h / 2, 0)), h, 0.6, Color3.new(1, 1, 1))
		local col = RAINBOW[rng:NextInteger(1, #RAINBOW)]
		local face = CFrame.new(pos + Vector3.new(0, h + 4, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0)
		for k = 0, 3 do
			part({ Name = "Prop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.2 + k * 0.1, 10 - k * 2.2, 10 - k * 2.2), CFrame = face, Color = k % 2 == 0 and col or Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic }, d)
		end
	else -- bastón de caramelo a rayas y algodón de azúcar
		for k = 0, 7 do
			part({ Name = "Prop", Size = Vector3.new(1.6, 1.6, 1.6), CFrame = CFrame.new(pos + Vector3.new(0, 1.8 + k * 1.6, 0)) * CFrame.Angles(0, k * 0.4, 0), Color = k % 2 == 0 and Color3.fromRGB(255, 60, 80) or Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic }, d)
		end
		ball(d, CFrame.new(pos + Vector3.new(4, 3, 3)), 5, Color3.fromRGB(255, 200, 240))
		ball(d, CFrame.new(pos + Vector3.new(5.5, 4, 1.5)), 4, Color3.fromRGB(200, 220, 255))
	end
end
function PROPS.volcano(pos, d, rng)
	biomeIsland(pos, rng:NextNumber(8, 13), d, Color3.fromRGB(55, 45, 45), Enum.Material.Basalt, Color3.fromRGB(45, 35, 35), Enum.Material.Basalt)
	for k = 0, 4 do -- cono del volcán
		cyl(d, CFrame.new(pos + Vector3.new(0, 2 + k * 2.4, 0)), 2.4, 7 - k * 1.3, Color3.fromRGB(60 - k * 4, 45, 42), Enum.Material.Basalt)
	end
	local top = part({ Name = "Crater", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 3.4, 3.4), CFrame = CFrame.new(pos + Vector3.new(0, 13.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 110, 30), Material = Enum.Material.Neon }, d)
	emitter(top, { Rate = 6, Lifetime = NumberRange.new(4, 6), Speed = NumberRange.new(4, 7), SpreadAngle = Vector2.new(15, 15), EmissionDirection = Enum.NormalId.Right, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3), NumberSequenceKeypoint.new(1, 9) }), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 1) }), Color = ColorSequence.new(Color3.fromRGB(90, 80, 80), Color3.fromRGB(40, 35, 35)), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-30, 30) })
	emitter(top, { Rate = 14, Lifetime = NumberRange.new(1.5, 2.5), Speed = NumberRange.new(10, 18), SpreadAngle = Vector2.new(25, 25), EmissionDirection = Enum.NormalId.Right, Acceleration = Vector3.new(0, -20, 0), LightEmission = 1, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }), Color = ColorSequence.new(Color3.fromRGB(255, 220, 90), Color3.fromRGB(255, 70, 20)) })
	local l = Instance.new("PointLight")
	l.Color = Color3.fromRGB(255, 110, 40)
	l.Range = 26
	l.Brightness = 2
	l.Parent = top
	-- cascada de lava que cae de la isla
	part({ Name = "LavaFall", Size = Vector3.new(2.5, 26, 1), CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-3, 3), -12, 6)), Color = Color3.fromRGB(255, 90, 25), Material = Enum.Material.Neon, Transparency = 0.15 }, d)
end
function PROPS.ice(pos, d, rng)
	biomeIsland(pos, rng:NextNumber(8, 13), d, Color3.fromRGB(235, 245, 255), Enum.Material.Snow, Color3.fromRGB(150, 190, 225), Enum.Material.Glacier)
	for _ = 1, rng:NextInteger(3, 5) do -- cristales con núcleo brillante
		local h = rng:NextNumber(5, 14)
		local w = rng:NextNumber(1.6, 3)
		local cf = CFrame.new(pos + Vector3.new(rng:NextNumber(-6, 6), h / 2, rng:NextNumber(-6, 6))) * CFrame.Angles(rng:NextNumber(-0.35, 0.35), rng:NextNumber(0, 6), rng:NextNumber(-0.35, 0.35))
		part({ Name = "Crystal", Size = Vector3.new(w, h, w), CFrame = cf, Color = Color3.fromRGB(150, 225, 255), Material = Enum.Material.Glass, Transparency = 0.25, Reflectance = 0.2 }, d)
		part({ Name = "CrystalCore", Size = Vector3.new(w * 0.4, h * 0.85, w * 0.4), CFrame = cf, Color = Color3.fromRGB(120, 230, 255), Material = Enum.Material.Neon, Transparency = 0.3 }, d)
	end
end
function PROPS.galaxy(pos, d, rng)
	local r = rng:NextNumber(7, 14)
	local col = ({ Color3.fromRGB(255, 120, 200), Color3.fromRGB(110, 170, 255), Color3.fromRGB(255, 170, 80), Color3.fromRGB(140, 255, 210) })[rng:NextInteger(1, 4)]
	local planet = ball(d, CFrame.new(pos + Vector3.new(0, 6, 0)), r * 2, col, Enum.Material.SmoothPlastic)
	ball(d, planet.CFrame, r * 2 + 0.6, col, Enum.Material.ForceField)
	part({ Name = "Ring", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, r * 3.6, r * 3.6), CFrame = planet.CFrame * CFrame.Angles(rng:NextNumber(-0.4, 0.4), 0, math.rad(90) + rng:NextNumber(-0.4, 0.4)), Color = Color3.fromRGB(230, 210, 255), Material = Enum.Material.Neon, Transparency = 0.45 }, d)
	for _ = 1, 2 do -- lunas
		local a = rng:NextNumber(0, 6.28)
		ball(d, CFrame.new(planet.Position + Vector3.new(math.cos(a) * r * 2.1, rng:NextNumber(-4, 6), math.sin(a) * r * 2.1)), rng:NextNumber(2, 4), Color3.fromRGB(220, 220, 235), Enum.Material.Slate)
	end
	local at = Instance.new("Attachment")
	at.Parent = planet
	emitter(at, { Rate = 5, Lifetime = NumberRange.new(2, 4), Speed = NumberRange.new(0.5, 1.5), SpreadAngle = Vector2.new(180, 180), LightEmission = 1, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.5, r * 0.08), NumberSequenceKeypoint.new(1, 0) }), Color = ColorSequence.new(Color3.new(1, 1, 1), col) })
end
function PROPS.heaven(pos, d, rng)
	for _ = 1, 6 do -- nube
		ball(d, CFrame.new(pos + Vector3.new(rng:NextNumber(-8, 8), rng:NextNumber(-1.5, 1.5), rng:NextNumber(-8, 8))), rng:NextNumber(6, 11), Color3.new(1, 1, 1), Enum.Material.SmoothPlastic)
	end
	if rng:NextNumber() < 0.6 then -- templete dorado
		for k = 0, 3 do
			local a = k * math.pi / 2 + math.pi / 4
			cyl(d, CFrame.new(pos + Vector3.new(math.cos(a) * 4, 7, math.sin(a) * 4)), 10, 0.8, Color3.fromRGB(250, 245, 235), Enum.Material.Marble)
		end
		cyl(d, CFrame.new(pos + Vector3.new(0, 12.5, 0)), 1, 6.5, Color3.fromRGB(255, 205, 80), Enum.Material.Foil)
	else -- moneda gigante que gira
		local coin = part({ Name = "Coin", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 8, 8), CFrame = CFrame.new(pos + Vector3.new(0, 9, 0)), Color = Color3.fromRGB(255, 205, 50), Material = Enum.Material.Foil }, d)
		table.insert(spinners, { part = coin, base = coin.CFrame, phase = rng:NextNumber(0, 6) })
	end
end

function PROPS.haunted(pos, d, rng)
	biomeIsland(pos, rng:NextNumber(8, 12), d, Color3.fromRGB(55, 70, 55), Enum.Material.Grass, Color3.fromRGB(60, 55, 65), Enum.Material.Slate)
	-- árbol muerto con ramas
	local h = rng:NextNumber(9, 13)
	cyl(d, CFrame.new(pos + Vector3.new(0, h / 2, 0)), h, 0.7, Color3.fromRGB(45, 35, 35), Enum.Material.Wood)
	for k = 1, 4 do
		local a = rng:NextNumber(0, 6.28)
		part({ Name = "Branch", Size = Vector3.new(0.5, 0.5, rng:NextNumber(3, 5)), CFrame = CFrame.new(pos + Vector3.new(0, h * (0.5 + k * 0.1), 0)) * CFrame.Angles(0, a, 0) * CFrame.Angles(math.rad(30), 0, 0) * CFrame.new(0, 0, -2), Color = Color3.fromRGB(45, 35, 35), Material = Enum.Material.Wood }, d)
	end
	-- lápidas
	for _ = 1, rng:NextInteger(2, 4) do
		part({ Name = "Tomb", Size = Vector3.new(2.2, 3, 0.6), CFrame = CFrame.new(pos + Vector3.new(rng:NextNumber(-6, 6), 2.4, rng:NextNumber(-6, 6))) * CFrame.Angles(rng:NextNumber(-0.2, 0.2), rng:NextNumber(-0.5, 0.5), 0), Color = Color3.fromRGB(130, 130, 140), Material = Enum.Material.Slate }, d)
	end
	-- fuegos fatuos verdes
	for _ = 1, 2 do
		local w = ball(d, CFrame.new(pos + Vector3.new(rng:NextNumber(-6, 6), rng:NextNumber(4, 8), rng:NextNumber(-6, 6))), 1.2, Color3.fromRGB(120, 255, 150), Enum.Material.Neon)
		local l = Instance.new("PointLight")
		l.Color = Color3.fromRGB(120, 255, 150)
		l.Range = 14
		l.Parent = w
		local at = Instance.new("Attachment")
		at.Parent = w
		emitter(at, { Rate = 8, Lifetime = NumberRange.new(1, 2), Speed = NumberRange.new(0.5, 1.5), EmissionDirection = Enum.NormalId.Top, LightEmission = 1, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) }), Color = ColorSequence.new(Color3.fromRGB(160, 255, 180), Color3.fromRGB(60, 200, 100)) })
		table.insert(spinners, { part = w, base = w.CFrame, phase = rng:NextNumber(0, 6) })
	end
end
function PROPS.desert(pos, d, rng)
	biomeIsland(pos, rng:NextNumber(8, 13), d, Color3.fromRGB(235, 200, 130), Enum.Material.Sand, Color3.fromRGB(190, 140, 90), Enum.Material.Sandstone)
	if rng:NextNumber() < 0.45 then -- pirámide escalonada
		for k = 0, 5 do
			local w = 13 - k * 2.2
			part({ Name = "Pyramid", Size = Vector3.new(w, 2, w), CFrame = CFrame.new(pos + Vector3.new(0, 2 + k * 2, 0)), Color = Color3.fromRGB(225, 185, 115):Lerp(Color3.fromRGB(190, 145, 90), k / 6), Material = Enum.Material.Sandstone }, d)
		end
		part({ Name = "PyramidTop", Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(pos + Vector3.new(0, 13.6, 0)) * CFrame.Angles(0, math.rad(45), math.rad(45)), Color = Color3.fromRGB(255, 210, 70), Material = Enum.Material.Neon }, d)
	else -- cactus
		for _ = 1, rng:NextInteger(2, 3) do
			local p = pos + Vector3.new(rng:NextNumber(-6, 6), 1, rng:NextNumber(-6, 6))
			local h = rng:NextNumber(5, 9)
			local green = Color3.fromRGB(70, 150, 70)
			cyl(d, CFrame.new(p + Vector3.new(0, h / 2, 0)), h, 0.9, green, Enum.Material.Grass)
			for _, sx in ipairs({ -1, 1 }) do
				cyl(d, CFrame.new(p + Vector3.new(sx * 1.6, h * 0.55, 0)), 3, 0.55, green, Enum.Material.Grass)
				part({ Name = "Prop", Size = Vector3.new(1.4, 0.9, 0.9), CFrame = CFrame.new(p + Vector3.new(sx * 1.1, h * 0.4, 0)), Color = green, Material = Enum.Material.Grass }, d)
			end
		end
	end
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
	-- orden de biomas: pradera al principio, cielo dorado al final y el resto barajado
	-- (si hay más tramos que biomas, se vuelve a barajar sin repetir el mismo dos veces seguidas)
	local nSec = math.ceil(C.SEGMENTS / C.CHECKPOINT_EVERY)
	local order = { "meadow" }
	local bag = {}
	for i = 2, nSec - 1 do
		if #bag == 0 then
			bag = table.clone(BIOME_ORDER_MID)
			for k = #bag, 2, -1 do
				local j = rng:NextInteger(1, k)
				bag[k], bag[j] = bag[j], bag[k]
			end
			if bag[#bag] == order[i - 1] then
				bag[1], bag[#bag] = bag[#bag], bag[1]
			end
		end
		order[i] = table.remove(bag)
	end
	order[nSec] = "heaven"
	local z0 = C.START.Z + 11
	local secLen = C.SEG_LEN * C.CHECKPOINT_EVERY
	local function secAt(zz)
		return math.clamp(math.floor((zz - z0) / secLen) + 1, 1, nSec)
	end
	folder:SetAttribute("Biomes", table.concat(order, ","))
	folder:SetAttribute("SecZ0", z0)
	folder:SetAttribute("SecLen", secLen)
	-- 1) vestir las piezas del recorrido con el bioma de su tramo
	for _, p in ipairs(folder:GetChildren()) do
		if p:IsA("BasePart") and CollectionService:HasTag(p, "Kill") then
			-- la lava chisporrotea (en el volcán, más)
			local vol = order[secAt(p.Position.Z)] == "volcano"
			emitter(p, { Rate = vol and 10 or 4, Lifetime = NumberRange.new(0.6, 1.2), Speed = NumberRange.new(3, 7), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(30, 30), Acceleration = Vector3.new(0, -12, 0), LightEmission = 1, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.35), NumberSequenceKeypoint.new(1, 0) }), Color = ColorSequence.new(Color3.fromRGB(255, 230, 120), Color3.fromRGB(255, 80, 20)) })
		elseif p:IsA("BasePart") and p.Name == "JumpPad" then
			part({ Name = "PadGlow", Size = Vector3.new(p.Size.X - 0.5, 9, p.Size.Z - 0.5), CFrame = p.CFrame * CFrame.new(0, 4.7, 0), Color = Color3.fromRGB(120, 255, 160), Material = Enum.Material.ForceField, Transparency = 0.2 }, d)
			emitter(p, { Rate = 18, Lifetime = NumberRange.new(0.8, 1.2), Speed = NumberRange.new(10, 16), EmissionDirection = Enum.NormalId.Top, SpreadAngle = Vector2.new(8, 8), LightEmission = 1, Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) }), Color = ColorSequence.new(Color3.fromRGB(200, 255, 210), Color3.fromRGB(80, 255, 140)) })
		elseif p:IsA("BasePart") and not KEEP[p.Name] then
			local b = Decor.BIOMES[order[secAt(p.Position.Z)]]
			local alt = ALT_NAMES[p.Name] or ((p.Name == "Stone" or p.Name == "Pillar") and math.floor(p.Position.Z / 5) % 2 == 0)
			if p.Name == "Rest" then
				p.Color = b.floor:Lerp(Color3.new(1, 1, 1), 0.25)
				p.Material = b.mat
			elseif p.Name == "Checkpoint" then
				p.Color = b.floor:Lerp(Color3.new(1, 1, 1), 0.55)
				p.Material = b.altMat
			else
				p.Color = alt and b.alt or b.floor
				p.Material = alt and b.altMat or b.mat
			end
			p.CustomPhysicalProperties = SAME_FEEL
			if p.Name == "Floor" or p.Name == "Rest" or p.Name == "Checkpoint" or p.Name == "High" then
				for _, sx in ipairs({ -1, 1 }) do
					part({ Name = "Trim", Size = Vector3.new(0.35, 0.35, p.Size.Z), CFrame = p.CFrame * CFrame.new(sx * (p.Size.X / 2 - 0.15), p.Size.Y / 2 + 0.05, 0), Color = b.trim, Material = Enum.Material.Neon }, d)
				end
			end
		end
	end
	-- 2) adornos del bioma a los dos lados (lejos del camino) y algún lucky block gigante
	local z = C.START.Z - 10
	local side = 1
	while z < finishZ + 20 do
		side = -side
		local biome = order[secAt(z)]
		local x = side * rng:NextNumber(C.WIDTH / 2 + 26, C.WIDTH / 2 + 60)
		local pos = Vector3.new(x, y + rng:NextNumber(-28, 6), z + rng:NextNumber(-8, 8))
		if rng:NextNumber() < 0.82 then
			PROPS[biome](pos, d, rng)
		else
			luckyBlock(CFrame.new(pos + Vector3.new(0, 12, 0)) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), rng:NextNumber(6, 10), d)
		end
		z += rng:NextNumber(18, 30)
	end
	-- 3) arcos en la salida y en cada punto de control
	for i, cp in pairs(G.Course.checkpoints) do
		rainbowArch(CFrame.new(0, cp.pos.Y - 3, cp.pos.Z - (i == 0 and -9 or 0)), C.WIDTH + 2, 14, d)
	end
	-- 4) meta: arco grande, lucky blocks a los lados, columnas de luz y lluvia de confeti
	local fz = finishZ + 10
	rainbowArch(CFrame.new(0, y - 0.5, fz - 6), C.WIDTH + 12, 24, d)
	for _, sx in ipairs({ -1, 1 }) do
		luckyBlock(CFrame.new(sx * (C.WIDTH / 2 + 10), y + 6, fz), 5, d)
		part({ Name = "FinishBeam", Size = Vector3.new(3, 120, 3), CFrame = CFrame.new(sx * (C.WIDTH / 2 + 10), y + 64, fz), Color = Color3.fromRGB(255, 225, 120), Material = Enum.Material.Neon, Transparency = 0.6 }, d)
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
	-- los lucky blocks gigantes, monedas y fuegos fatuos giran y flotan: los anima cada cliente
	-- (etiqueta FxSpin + atributos BaseCF y Phase; ver Extras.client) para no mandar CFrames por la red
	task.spawn(function()
		while true do
			for i = #spinners, 1, -1 do
				local s = spinners[i]
				if s.part.Parent then
					if not s.tagged then
						s.tagged = true
						s.part:SetAttribute("BaseCF", s.base)
						s.part:SetAttribute("Phase", s.phase)
						CollectionService:AddTag(s.part, "FxSpin")
					end
				else
					table.remove(spinners, i)
				end
			end
			task.wait(0.5)
		end
	end)
end

return Decor
