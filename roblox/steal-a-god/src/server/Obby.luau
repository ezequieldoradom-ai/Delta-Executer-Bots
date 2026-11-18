-- Ascenso al Olimpo: obby gigante en una isla flotante, con portal en la plaza.
-- 100 etapas en espiral alrededor del monte Olimpo (10 tramos, uno por mitología); arriba, un puente
-- lleva al templo de la cima con el Sobre del Olimpo.
--
-- Contrato con el cliente (src/client/ObbyFx.luau anima y detecta; el servidor nunca mueve nada):
--   workspace.Obby.Pads.CP<i>  puntos de control 0..100 (atributo Stage)
--   ObbyKill    toca y vuelves a tu punto de control
--   ObbySpin    gira sobre su eje Y (Speed rad/s; BaseCF)
--   ObbyMove    va y viene por su eje X local (Amp, Period, Phase; BaseCF)
--   ObbySwing   modelo péndulo (Pivot CFrame, Amp rad, Period, Phase)
--   ObbyVanish  baldosa que se cae al pisarla (Delay) y vuelve
--   ObbyPad     impulsor de salto (Power)
--   ObbyBelt    cinta que arrastra (Belt = velocidad Vector3)
--   ObbyWind    zona de viento (Push = velocidad lateral Vector3, Period)
-- Todo lo que se mueve usa workspace:GetServerTimeNow() para verse igual en todos los clientes.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local Obby = {}
local G, C, O

Obby.pads = {} -- [i] = Part (0 = salida)
Obby.folder = nil
Obby.summit = nil -- { pos, radius }

---------------------------------------------------------------------
-- Ayudantes de construcción
---------------------------------------------------------------------
local stageFolder
local function P(props, parent)
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Class" and k ~= "Tags" and k ~= "Attrs" then
			p[k] = v
		end
	end
	for k, v in pairs(props.Attrs or {}) do
		p:SetAttribute(k, v)
	end
	for _, t in ipairs(props.Tags or {}) do
		CollectionService:AddTag(p, t)
	end
	p.Parent = parent or stageFolder
	return p
end

local function lerp(a, b, k)
	return a + (b - a) * k
end

-- Punto del recorrido a s studs de la salida (espiral que sube)
local function pathPoint(s)
	local th = s / O.RADIUS
	local total = O.STAGES * O.STAGE_LEN
	return O.CENTER + Vector3.new(O.RADIUS * math.cos(th), O.START_UP + O.CLIMB * s / total, O.RADIUS * math.sin(th))
end
Obby.pathPoint = pathPoint

-- Marco del punto de control i: en su sitio, mirando hacia donde sigue el recorrido
function Obby.padCF(i)
	local p = pathPoint(i * O.STAGE_LEN)
	local q = pathPoint(i * O.STAGE_LEN + 2)
	return CFrame.lookAt(p, Vector3.new(q.X, p.Y, q.Z))
end

-- Dónde aparece el jugador en su punto de control
function Obby.spawnCF(i)
	i = math.clamp(i or 0, 0, O.STAGES)
	return Obby.padCF(i) * CFrame.new(0, 4, 1)
end

function Obby.sectionOf(stage)
	return math.clamp(math.floor(math.max(stage - 1, 0) / O.PER_SECTION) + 1, 1, #O.SECTIONS)
end

local function kill(props)
	props.Color = O.KILL_COLOR
	props.Material = Enum.Material.Neon
	props.Tags = props.Tags or {}
	table.insert(props.Tags, "ObbyKill")
	return P(props)
end

---------------------------------------------------------------------
-- Obstáculos: cada uno va de la salida (z = 0) a la llegada (z = D) del marco de la etapa,
-- subiendo `rise`. k = dificultad (0 al principio, 1 al final).
---------------------------------------------------------------------
local OB = {}

local function floorSlab(st, z0, z1, width, color)
	local len = z1 - z0
	local y0, y1 = st.rise * z0 / st.D, st.rise * z1 / st.D
	local tilt = math.atan2(y1 - y0, len)
	return P({ Name = "Floor", Size = Vector3.new(width, 1, len), CFrame = st.at(0, (y0 + y1) / 2 - 0.5, (z0 + z1) / 2) * CFrame.Angles(tilt, 0, 0), Color = color or st.th.floor, Material = st.th.mat })
end

-- 1) Piedras para saltar, cada vez más pequeñas y separadas
function OB.stones(st)
	local n = 4
	local size = lerp(4.6, 2.6, st.k)
	for j = 1, n do
		local z = 6 + (st.D - 12) * (j - 0.5) / n
		local x = math.sin(j * 1.9 + st.i) * lerp(1.5, 4, st.k)
		P({ Name = "Stone", Size = Vector3.new(size, 1.2, size), CFrame = st.at(x, st.rise * z / st.D - 0.6, z), Color = st.th.floor, Material = st.th.mat })
	end
end

-- 2) Suelo con franjas de lava que hay que saltar
function OB.lava(st)
	floorSlab(st, 5, st.D - 5, 9)
	local n = 3 + math.floor(st.k * 2.99)
	local w = lerp(2, 3.6, st.k)
	for j = 1, n do
		local z = 8 + (st.D - 16) * (j - 0.5) / n
		kill({ Name = "LavaStrip", Size = Vector3.new(9, 0.5, w), CFrame = st.at(0, st.rise * z / st.D + 0.1, z) * CFrame.Angles(math.atan2(st.rise, st.D), 0, 0) })
	end
end

-- 3) Vigas estrechas en zigzag
function OB.beams(st)
	local w = lerp(2.4, 1.1, st.k)
	local pts = { Vector3.new(0, 0, 4), Vector3.new(6, 0, st.D / 3), Vector3.new(-6, 0, 2 * st.D / 3), Vector3.new(0, 0, st.D - 4) }
	for j = 1, #pts do
		pts[j] = Vector3.new(pts[j].X, st.rise * pts[j].Z / st.D, pts[j].Z)
	end
	for j = 1, #pts - 1 do
		local a, b = pts[j], pts[j + 1]
		local mid = (a + b) / 2
		local len = (b - a).Magnitude
		local cf = st.at(mid.X, mid.Y - 0.4, mid.Z)
		local dirLocal = Vector3.new(b.X - a.X, b.Y - a.Y, -(b.Z - a.Z))
		local look = st.F:VectorToWorldSpace(dirLocal)
		P({ Name = "Beam", Size = Vector3.new(w, 0.8, len + w), CFrame = CFrame.lookAt(cf.Position, cf.Position + look), Color = st.th.floor, Material = st.th.mat })
		if j > 1 then
			P({ Name = "BeamJoint", Size = Vector3.new(3.2, 0.8, 3.2), CFrame = st.at(a.X, a.Y - 0.4, a.Z), Color = st.th.accent, Material = Enum.Material.SmoothPlastic })
		end
	end
end

-- 4) Barras de fuego que giran (hay que saltarlas)
function OB.spinners(st)
	floorSlab(st, 5, st.D - 5, 13)
	local n = st.k > 0.55 and 3 or 2
	for j = 1, n do
		local z = 6 + (st.D - 12) * (j - 0.5) / n
		local y = st.rise * z / st.D
		local base = st.at(0, y + 1.4, z)
		P({ Name = "SpinHub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.4, 1.6, 1.6), CFrame = st.at(0, y + 1.2, z) * CFrame.Angles(0, 0, math.rad(90)), Color = st.th.accent, Material = Enum.Material.Metal })
		local speed = lerp(1.5, 3.3, st.k) * (j % 2 == 0 and -1 or 1)
		kill({ Name = "SpinBar", Size = Vector3.new(12.5, 0.9, 0.9), CFrame = base, Tags = { "ObbySpin" }, Attrs = { Speed = speed, BaseCF = base } })
	end
end

-- 5) Plataformas que van y vienen por encima del vacío
function OB.movers(st)
	local n = 3
	local size = lerp(6.5, 4.6, st.k)
	for j = 1, n do
		local z = 6 + (st.D - 12) * (j - 0.5) / n
		local base = st.at(0, st.rise * z / st.D - 0.6, z)
		P({ Name = "Mover", Size = Vector3.new(size, 1.2, size), CFrame = base, Color = st.th.accent, Material = Enum.Material.SmoothPlastic, Tags = { "ObbyMove" }, Attrs = { Amp = lerp(4.5, 8.5, st.k), Period = lerp(4.4, 2.8, st.k), Phase = j * 1.3 + st.i, BaseCF = base } })
	end
end

-- 6) Baldosas que se caen al pisarlas
function OB.vanish(st)
	local n = 6
	for j = 1, n do
		local z = 5 + (st.D - 10) * (j - 0.5) / n
		local x = (j % 2 == 0) and 1.2 or -1.2
		P({ Name = "VanishTile", Size = Vector3.new(4, 1, 4), CFrame = st.at(x, st.rise * z / st.D - 0.5, z), Color = st.th.floor:Lerp(Color3.new(1, 1, 1), 0.35), Material = Enum.Material.Glass, Transparency = 0.15, Tags = { "ObbyVanish" }, Attrs = { Delay = lerp(0.7, 0.32, st.k) } })
	end
end

-- 7) Impulsores de salto hasta una plataforma alta
function OB.pads(st)
	P({ Name = "LowFloor", Size = Vector3.new(8, 1, 10), CFrame = st.at(0, -0.5, 10), Color = st.th.floor, Material = st.th.mat })
	P({ Name = "JumpPad", Size = Vector3.new(4.5, 0.4, 4.5), CFrame = st.at(0, 0.2, 12), Color = Color3.fromRGB(90, 255, 140), Material = Enum.Material.Neon, Tags = { "ObbyPad" }, Attrs = { Power = 82 } })
	P({ Name = "HighFloor", Size = Vector3.new(8, 1, 9), CFrame = st.at(0, 13, 22), Color = st.th.floor, Material = st.th.mat })
	P({ Name = "StepDown", Size = Vector3.new(6, 1, 6), CFrame = st.at(0, lerp(9, 8, st.k), 31), Color = st.th.accent, Material = Enum.Material.SmoothPlastic })
	P({ Name = "StepDown", Size = Vector3.new(5, 1, 5), CFrame = st.at(0, st.rise + 2.5, st.D - 7.5), Color = st.th.floor, Material = st.th.mat })
end

-- 8) Cintas que te arrastran hacia atrás, con lava a los lados
function OB.belts(st)
	local slab = floorSlab(st, 5, st.D - 5, 7)
	local push = st.F:VectorToWorldSpace(Vector3.new(0, 0, 1)) * lerp(7, 14, st.k)
	slab.Name = "Belt"
	slab.Color = Color3.fromRGB(40, 40, 50)
	slab.Material = Enum.Material.DiamondPlate
	slab:SetAttribute("Belt", push)
	slab.AssemblyLinearVelocity = push
	CollectionService:AddTag(slab, "ObbyBelt")
	for side = -1, 1, 2 do
		kill({ Name = "BeltLava", Size = Vector3.new(1.4, 0.6, st.D - 10), CFrame = slab.CFrame * CFrame.new(side * 4.2, 0.4, 0) })
	end
end

-- 9) Martillos que se balancean
function OB.pendulums(st)
	floorSlab(st, 5, st.D - 5, 10)
	local n = st.k > 0.5 and 3 or 2
	for j = 1, n do
		local z = 6 + (st.D - 12) * (j - 0.5) / n
		local y = st.rise * z / st.D
		local pivot = st.at(0, y + 14, z)
		local m = Instance.new("Model")
		m.Name = "Pendulum"
		P({ Name = "Arm", Size = Vector3.new(0.6, 11, 0.6), CFrame = pivot * CFrame.new(0, -5.5, 0), Color = Color3.fromRGB(70, 66, 76), Material = Enum.Material.Metal }, m)
		local head = P({ Name = "Hammer", Size = Vector3.new(3.2, 3.2, 3.2), CFrame = pivot * CFrame.new(0, -12, 0), Color = O.KILL_COLOR, Material = Enum.Material.Neon }, m)
		CollectionService:AddTag(head, "ObbyKill")
		m:SetAttribute("Pivot", pivot)
		m:SetAttribute("Amp", math.rad(lerp(48, 66, st.k)))
		m:SetAttribute("Period", lerp(3, 2, st.k))
		m:SetAttribute("Phase", j * 1.7 + st.i)
		CollectionService:AddTag(m, "ObbySwing")
		m.Parent = stageFolder
		-- soporte arriba (solo adorno)
		P({ Name = "SwingBeam", Size = Vector3.new(14, 0.8, 0.8), CFrame = pivot * CFrame.new(0, 0.6, 0), Color = st.th.accent, Material = Enum.Material.Metal, CanCollide = false })
	end
end

-- 10) Escalada por una celosía hasta lo alto y bajada por escalones
function OB.truss(st)
	P({ Name = "TrussBase", Size = Vector3.new(8, 1, 6), CFrame = st.at(0, -0.5, 8), Color = st.th.floor, Material = st.th.mat })
	P({ Class = "TrussPart", Name = "Truss", Size = Vector3.new(2, 14, 2), CFrame = st.at(0, 7, 12), Color = st.th.accent })
	P({ Name = "TrussTop", Size = Vector3.new(8, 1, 7), CFrame = st.at(0, 13.5, 16.5), Color = st.th.floor, Material = st.th.mat })
	for j = 1, 3 do
		local z = 22 + j * 5
		P({ Name = "Step", Size = Vector3.new(4.5, 1, 4.5), CFrame = st.at((j % 2 == 0) and 2 or -2, 13 - j * 3 + st.rise * 0.3, z), Color = st.th.accent, Material = Enum.Material.SmoothPlastic })
	end
end

-- 11) Puente estrecho con ráfagas de viento que empujan de lado
function OB.wind(st)
	local w = lerp(4, 2.4, st.k)
	floorSlab(st, 4, st.D - 4, w)
	local zc = st.D / 2
	local zone = P({ Name = "WindZone", Size = Vector3.new(16, 8, st.D - 12), CFrame = st.at(0, st.rise / 2 + 3, zc), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false })
	local side = (st.i % 2 == 0) and 1 or -1
	zone:SetAttribute("Push", st.F:VectorToWorldSpace(Vector3.new(side * lerp(6, 11, st.k), 0, 0)))
	zone:SetAttribute("Period", lerp(3.2, 2.2, st.k))
	CollectionService:AddTag(zone, "ObbyWind")
	-- banderas que señalan hacia dónde sopla
	for j = 1, 3 do
		local z = 8 + (st.D - 16) * (j - 0.5) / 3
		P({ Name = "WindFlag", Size = Vector3.new(2.4, 1.2, 0.1), CFrame = st.at(-side * (w / 2 + 0.8) + side * 1.2, st.rise * z / st.D + 3.4, z), Color = st.th.accent, Material = Enum.Material.Fabric, CanCollide = false })
		P({ Name = "WindPole", Size = Vector3.new(0.25, 4, 0.25), CFrame = st.at(-side * (w / 2 + 0.8), st.rise * z / st.D + 2, z), Color = Color3.fromRGB(90, 80, 70), Material = Enum.Material.Wood, CanCollide = false })
	end
end

Obby.TYPES = { "stones", "lava", "beams", "spinners", "movers", "vanish", "pads", "belts", "pendulums", "truss", "wind" }

-- Tipo de obstáculo de cada etapa: las tres primeras, fáciles; luego todos se van alternando
function Obby.typeOf(i)
	if i <= 3 then
		return ({ "stones", "lava", "beams" })[i]
	end
	local T = Obby.TYPES
	return T[((i - 1) * 5 + math.floor((i - 1) / 11)) % #T + 1]
end

---------------------------------------------------------------------
-- Construcción
---------------------------------------------------------------------
local function buildPad(i)
	local cf = Obby.padCF(i)
	local sec = Obby.sectionOf(math.max(i, 1))
	local th = O.SECTIONS[sec]
	local gate = i > 0 and i % O.PER_SECTION == 0
	local size = (i == 0 or gate) and Vector3.new(18, 1.4, 14) or Vector3.new(13, 1.2, 10)
	local pad = P({ Name = "CP" .. i, Size = size, CFrame = cf * CFrame.new(0, -size.Y / 2, 0), Color = th.floor, Material = th.mat, Attrs = { Stage = i } }, Obby.padFolder)
	-- aro brillante del punto de control y su número
	P({ Name = "CPRing" .. i, Size = Vector3.new(size.X - 2, 0.15, size.Z - 2), CFrame = cf * CFrame.new(0, 0.07, 0), Color = Color3.fromRGB(110, 255, 150), Material = Enum.Material.Neon, CanCollide = false, Transparency = 0.45 }, Obby.padFolder)
	if i > 0 then
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(4, 2)
		bb.StudsOffset = Vector3.new(0, 4.5, 0)
		bb.MaxDistance = 70
		bb.LightInfluence = 0
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.TextScaled = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeTransparency = 0.2
		l.Text = tostring(i)
		l.Parent = bb
		bb.Parent = pad
	end
	if gate then
		-- arco de fin de tramo con el nombre del tramo siguiente
		local nextTh = O.SECTIONS[math.min(sec + 1, #O.SECTIONS)]
		for side = -1, 1, 2 do
			P({ Name = "GateColumn", Size = Vector3.new(1.6, 14, 1.6), CFrame = cf * CFrame.new(side * 8, 7, 0), Color = nextTh.accent, Material = Enum.Material.Marble }, Obby.padFolder)
		end
		P({ Name = "GateLintel", Size = Vector3.new(18.5, 1.6, 2.2), CFrame = cf * CFrame.new(0, 14.6, 0), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil }, Obby.padFolder)
		local sign = P({ Name = "GateSign", Size = Vector3.new(12, 3, 0.4), CFrame = cf * CFrame.new(0, 12, 0), Color = Color3.fromRGB(30, 22, 44), Material = Enum.Material.Slate, CanCollide = false }, Obby.padFolder)
		sign:SetAttribute("Section", math.min(sec + 1, #O.SECTIONS))
		sign:SetAttribute("Stage", i)
		CollectionService:AddTag(sign, "ObbyGateSign")
	end
	Obby.pads[i] = pad
	return pad
end

local function buildStage(i)
	stageFolder = Instance.new("Folder")
	stageFolder.Name = "Stage" .. i
	local a, b = Obby.padCF(i - 1), Obby.padCF(i)
	local p0, p1 = a.Position, b.Position
	local F = CFrame.lookAt(p0, Vector3.new(p1.X, p0.Y, p1.Z))
	local D = (Vector3.new(p1.X, 0, p1.Z) - Vector3.new(p0.X, 0, p0.Z)).Magnitude
	local st = {
		i = i,
		F = F,
		D = D,
		rise = p1.Y - p0.Y,
		k = (i - 1) / (O.STAGES - 1),
		th = O.SECTIONS[Obby.sectionOf(i)],
		at = function(x, y, z)
			return F * CFrame.new(x, y, -z)
		end,
	}
	local kind = Obby.typeOf(i)
	OB[kind](st)
	stageFolder:SetAttribute("Kind", kind)
	stageFolder.Parent = Obby.stagesFolder
	return stageFolder
end

-- Isla flotante, monte del Olimpo, nubes y templo de la cima
local function buildIsland()
	local f = Instance.new("Folder")
	f.Name = "Island"
	f.Parent = Obby.folder
	local c = O.CENTER
	local rock = Color3.fromRGB(120, 112, 104)
	-- isla: disco de hierba y roca que se estrecha hacia abajo
	P({ Name = "IslandTop", Shape = Enum.PartType.Cylinder, Size = Vector3.new(6, 380, 380), CFrame = CFrame.new(c + Vector3.new(0, -3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(96, 170, 80), Material = Enum.Material.Grass }, f)
	for j = 1, 5 do
		local r = 370 - j * 62
		P({ Name = "IslandRock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(18, r, r), CFrame = CFrame.new(c + Vector3.new(0, -6 - j * 16, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = rock:Lerp(Color3.new(0, 0, 0), j * 0.06), Material = Enum.Material.Rock }, f)
	end
	-- monte del Olimpo en el centro: tramos de roca cada vez más estrechos hasta la cima
	local top = Obby.padCF(O.STAGES).Position.Y
	local h = top - c.Y - 4
	local n = 7
	for j = 0, n - 1 do
		local r = lerp(170, 54, j / (n - 1))
		local y0 = c.Y + h * j / n
		P({ Name = "Mountain", Shape = Enum.PartType.Cylinder, Size = Vector3.new(h / n + 2, r, r), CFrame = CFrame.new(c.X, y0 + h / n / 2, c.Z) * CFrame.Angles(0, 0, math.rad(90)), Color = rock:Lerp(Color3.fromRGB(235, 235, 240), j / n * 0.6), Material = j >= n - 2 and Enum.Material.Snow or Enum.Material.Rock }, f)
	end
	-- anillos de nubes alrededor del monte
	for j = 1, 9 do
		local y = c.Y + 30 + j * 34
		local ang = j * 1.3
		local rr = 210 + (j % 3) * 24 -- por fuera del recorrido (radio 135 ± obstáculos)
		P({ Name = "Cloud", Shape = Enum.PartType.Ball, Size = Vector3.new(40, 14, 40), CFrame = CFrame.new(c + Vector3.new(math.cos(ang) * rr, y - c.Y + 0, math.sin(ang) * rr)), Color = Color3.fromRGB(250, 250, 255), Material = Enum.Material.SmoothPlastic, Transparency = 0.35, CanCollide = false, CanQuery = false, CastShadow = false }, f)
	end
	-- templo de la cima: plataforma redonda, columnas y el Sobre del Olimpo sobre su altar
	local summit = Vector3.new(c.X, top, c.Z)
	P({ Name = "SummitFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 56, 56), CFrame = CFrame.new(summit - Vector3.new(0, 1, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(245, 240, 228), Material = Enum.Material.Marble }, f)
	P({ Name = "SummitRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, 58, 58), CFrame = CFrame.new(summit - Vector3.new(0, 1.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil }, f)
	-- columnas giradas para que el puente entre justo por un hueco entre dos
	local lastPad = Obby.padCF(O.STAGES).Position
	local bridgeAng = math.atan2(lastPad.Z - summit.Z, lastPad.X - summit.X)
	for j = 1, 10 do
		local ang = bridgeAng + (j - 0.5) / 10 * math.pi * 2
		local pos = summit + Vector3.new(math.cos(ang) * 24, 9, math.sin(ang) * 24)
		P({ Name = "SummitColumn", Shape = Enum.PartType.Cylinder, Size = Vector3.new(18, 2.6, 2.6), CFrame = CFrame.new(pos) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(250, 248, 240), Material = Enum.Material.Marble }, f)
	end
	P({ Name = "SummitCrown", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 54, 54), CFrame = CFrame.new(summit + Vector3.new(0, 18.6, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil, CanCollide = false }, f)
	local altar = P({ Name = "SummitAltar", Size = Vector3.new(7, 3, 7), CFrame = CFrame.new(summit + Vector3.new(0, 1.5, 0)), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil }, f)
	local pack = P({ Name = "OlympusPack", Size = Vector3.new(4.5, 6, 0.8), CFrame = CFrame.new(summit + Vector3.new(0, 7, 0)), Color = Color3.fromRGB(255, 220, 110), Material = Enum.Material.Foil, CanCollide = false, Tags = { "FxSpin", "FxBob" }, Attrs = { SpinSpeed = 1.2 } }, f)
	local light = Instance.new("PointLight")
	light.Color = Color3.fromRGB(255, 220, 140)
	light.Range = 30
	light.Brightness = 3
	light.Parent = pack
	local beam = P({ Name = "SummitBeam", Shape = Enum.PartType.Cylinder, Size = Vector3.new(400, 5, 5), CFrame = CFrame.new(summit + Vector3.new(0, 200, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 236, 170), Material = Enum.Material.Neon, Transparency = 0.6, CanCollide = false, CanQuery = false, CastShadow = false }, f)
	beam.Name = "SummitBeam"
	Obby.summit = { pos = summit, radius = 9, altar = altar }
	-- puente desde el último punto de control hasta el templo
	local last = Obby.padCF(O.STAGES).Position
	local from = Vector3.new(last.X, top - 0.5, last.Z)
	local to = Vector3.new(summit.X, top - 0.5, summit.Z)
	local dir = (to - from)
	local len = dir.Magnitude - 26
	local mid = from + dir.Unit * (len / 2 + 4)
	P({ Name = "SummitBridge", Size = Vector3.new(8, 1, len), CFrame = CFrame.lookAt(mid, to), Color = Color3.fromRGB(250, 236, 200), Material = Enum.Material.Marble }, f)
	for side = -1, 1, 2 do
		P({ Name = "BridgeRail", Size = Vector3.new(0.6, 1.4, len), CFrame = CFrame.lookAt(mid, to) * CFrame.new(side * 4.2, 1.2, 0), Color = Color3.fromRGB(240, 196, 92), Material = Enum.Material.Foil }, f)
	end
	-- portal de vuelta a la plaza junto a la salida y otro en la cima
	return f
end

-- Portal: arco con disco que gira y aviso para usarlo
local function portal(cf, kind, parent, scale)
	scale = scale or 1
	local f = Instance.new("Model")
	f.Name = kind == "obbyEnter" and "ObbyPortal" or "ObbyExit"
	local gold = Color3.fromRGB(240, 196, 92)
	for side = -1, 1, 2 do
		P({ Name = "PortalColumn", Size = Vector3.new(2.2, 15, 2.2) * scale, CFrame = cf * CFrame.new(side * 7.5 * scale, 7.5 * scale, 0), Color = Color3.fromRGB(245, 240, 230), Material = Enum.Material.Marble }, f)
		P({ Name = "PortalCap", Size = Vector3.new(3, 1, 3) * scale, CFrame = cf * CFrame.new(side * 7.5 * scale, 15.4 * scale, 0), Color = gold, Material = Enum.Material.Foil }, f)
	end
	P({ Name = "PortalLintel", Size = Vector3.new(18, 1.6, 2.6) * scale, CFrame = cf * CFrame.new(0, 16.6 * scale, 0), Color = gold, Material = Enum.Material.Foil }, f)
	local disc = P({ Name = "PortalDisc", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.4, 12, 12) * scale, CFrame = cf * CFrame.new(0, 7.6 * scale, 0) * CFrame.Angles(0, math.rad(90), 0), Color = kind == "obbyEnter" and Color3.fromRGB(150, 210, 255) or Color3.fromRGB(255, 220, 140), Material = Enum.Material.Neon, Transparency = 0.25, CanCollide = false }, f)
	local ring = P({ Name = "PortalRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 13.4, 13.4) * scale, CFrame = disc.CFrame, Color = gold, Material = Enum.Material.Neon, Transparency = 0.5, CanCollide = false, Tags = { "FxSpin" }, Attrs = { SpinSpeed = 0.8, SpinAxis = "X" } }, f)
	ring.Name = "PortalRing"
	local light = Instance.new("PointLight")
	light.Color = disc.Color
	light.Range = 18
	light.Brightness = 2
	light.Parent = disc
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = kind == "obbyEnter" and "Climb" or "Back"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 12
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Kind", kind)
	CollectionService:AddTag(prompt, "LocPrompt")
	prompt.Parent = disc
	prompt.Triggered:Connect(function(player)
		if kind == "obbyEnter" then
			G.Core.handleAction(player, "obbyEnter")
		else
			G.Core.handleAction(player, "obbyLeave")
		end
	end)
	if kind == "obbyEnter" then
		local bb = Instance.new("BillboardGui")
		bb.Name = "PortalSign"
		bb.Size = UDim2.fromScale(16, 4)
		bb.StudsOffset = Vector3.new(0, 11 * scale, 0)
		bb.MaxDistance = 150
		bb.LightInfluence = 0
		local l = Instance.new("TextLabel")
		l.Name = "Label"
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.TextScaled = true
		l.RichText = true
		l.Font = Enum.Font.FredokaOne
		l.TextColor3 = Color3.fromRGB(255, 236, 170)
		l.TextStrokeTransparency = 0.2
		l.Text = ""
		l.Parent = bb
		bb:SetAttribute("ObbyPortal", true)
		CollectionService:AddTag(bb, "Loc")
		bb.Parent = disc
	end
	f.Parent = parent
	return f
end

function Obby.build()
	local old = workspace:FindFirstChild("Obby")
	if old then
		old:Destroy()
	end
	Obby.folder = Instance.new("Folder")
	Obby.folder.Name = "Obby"
	Obby.padFolder = Instance.new("Folder")
	Obby.padFolder.Name = "Pads"
	Obby.padFolder.Parent = Obby.folder
	Obby.stagesFolder = Instance.new("Folder")
	Obby.stagesFolder.Name = "Stages"
	Obby.stagesFolder.Parent = Obby.folder
	stageFolder = Obby.folder
	for i = 0, O.STAGES do
		buildPad(i)
	end
	for i = 1, O.STAGES do
		buildStage(i)
	end
	stageFolder = Obby.folder
	buildIsland()
	-- salida: portal de vuelta detrás del primer punto de control
	portal(Obby.padCF(0) * CFrame.new(0, 0, 4.5) * CFrame.Angles(0, math.rad(180), 0), "obbyLeave", Obby.folder, 0.7)
	-- cima: portal de vuelta en el templo
	if Obby.summit then
		portal(CFrame.new(Obby.summit.pos + Vector3.new(0, 0, -14)), "obbyLeave", Obby.folder, 0.7)
	end
	-- plaza: portal de entrada mirando hacia la fuente
	portal(CFrame.lookAt(O.PORTAL, O.PORTAL + (O.FACING or Vector3.new(0, 0, 1))), "obbyEnter", Obby.folder, 1)
	Obby.folder:SetAttribute("Stages", O.STAGES)
	Obby.folder.Parent = workspace
	return Obby.folder
end

---------------------------------------------------------------------
-- Jugadores: entrar, salir, puntos de control y premios
---------------------------------------------------------------------
local function today()
	return G.Quests and G.Quests.today and G.Quests.today() or math.floor(os.time() / 86400)
end

local function obbyData(d)
	d.obby = d.obby or { stage = 0, wins = 0, best = 0, day = 0, secs = {}, top = 0 }
	return d.obby
end

local function bestZone(d)
	local z = 1
	for i, zone in ipairs(C.ZONES) do
		if d.speed >= zone.req then
			z = i
		end
	end
	return z
end

local function hrpOf(player)
	local char = typeof(player) == "Instance" and player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

function Obby.enter(player)
	local s = G.Core.sessions[player]
	local d = G.Data.profiles[player]
	if not s or not d then
		return false
	end
	if s.carrying then
		G.Net.toast(player, "obbyNoCarry")
		return false
	end
	if s.afk then
		G.Core.setAfk(player, false)
	end
	if s.locked then
		G.Core.leaveTreadmill(player)
	end
	local od = obbyData(d)
	s.inObby = true
	s.obbyLastCp = os.clock()
	s.obbyRunStart = od.stage == 0 and os.clock() or nil
	local hrp = hrpOf(player)
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = Obby.spawnCF(od.stage)
	end
	return true
end

function Obby.leave(player)
	local s = G.Core.sessions[player]
	if not s or not s.inObby then
		return false
	end
	s.inObby = false
	s.obbyRunStart = nil
	local hrp = hrpOf(player)
	if hrp and s.plot then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = s.plot.spawnCF
	end
	return true
end

-- Llega al punto de control i (solo el siguiente, y no demasiado deprisa)
function Obby.reach(player, i)
	local s = G.Core.sessions[player]
	local d = G.Data.profiles[player]
	if not s or not d or not s.inObby then
		return false
	end
	local od = obbyData(d)
	if i ~= od.stage + 1 or i > O.STAGES then
		return false
	end
	local now = os.clock()
	if now - (s.obbyLastCp or 0) < O.MIN_STAGE_TIME then
		return false
	end
	s.obbyLastCp = now
	od.stage = i
	-- fin de tramo: dinero (una vez al día por tramo)
	if i % O.PER_SECTION == 0 and i < O.STAGES then
		local sec = i / O.PER_SECTION
		local day = today()
		if od.day ~= day or #od.secs == 0 then
			od.day = day
			od.secs = table.create(O.STAGES / O.PER_SECTION - 1, false) -- lista seguida (el DataStore no guarda huecos)
		end
		if not od.secs[sec] then
			od.secs[sec] = true
			local amount = math.max(1000, math.floor(G.Core.income(player) * O.SECTION_MONEY_SECS * (1 + sec * 0.25)))
			G.Core.addMoney(player, amount)
			G.Net.toast(player, "obbySectionReward", sec, G.Format.num(amount))
		else
			G.Net.toast(player, "obbySectionDone", sec)
		end
	end
	return true
end

-- Llega al altar de la cima con las 100 etapas hechas
function Obby.finish(player)
	local s = G.Core.sessions[player]
	local d = G.Data.profiles[player]
	if not s or not d or not s.inObby then
		return false
	end
	local od = obbyData(d)
	if od.stage < O.STAGES then
		return false
	end
	local day = today()
	if od.day ~= day or #od.secs == 0 then
		od.day = day
		od.secs = table.create(O.STAGES / O.PER_SECTION - 1, false)
	end
	local time = s.obbyRunStart and (os.clock() - s.obbyRunStart) or nil
	od.wins = (od.wins or 0) + 1
	if time and (od.best == 0 or time < od.best) then
		od.best = math.floor(time)
	end
	od.stage = 0
	s.obbyRunStart = nil
	if od.top ~= day then
		od.top = day
		-- Sobre del Olimpo: rareza de tu mejor zona con mucha suerte, y suerte enorme al abrirlo
		local z = bestZone(d)
		local r = math.max(O.TOP_MIN_RARITY or 1, C.rollRarity(z, O.TOP_RARITY_LUCK * G.Core.personalLuck(player)))
		local item = { r = r, rem = C.RARITIES[r].open, dawn = true, kg = math.max(200, C.rollKg()), luck = C.packLuck(z, r, true) * O.TOP_PACK_LUCK }
		local amount = math.max(5000, math.floor(G.Core.income(player) * O.TOP_MONEY_SECS))
		G.Core.addMoney(player, amount)
		if not G.Packs.givePack(player, item) then
			G.Core.addMoney(player, amount)
		end
		G.Net.toast(player, "obbyTopReward", { rarity = r }, G.Format.num(amount))
	else
		local amount = math.max(1000, math.floor(G.Core.income(player) * O.SECTION_MONEY_SECS))
		G.Core.addMoney(player, amount)
		G.Net.toast(player, "obbyTopAgain", G.Format.num(amount))
	end
	G.Net.announce("all", "obbyWin", { player.DisplayName, time and G.Format.time(time) or "—" }, { color = "#FFD86B", big = true })
	if G.Quests then
		G.Quests.event(player, "obby", 1)
	end
	return true
end

-- Compra "Saltar etapa": pasa al siguiente punto de control (sin el premio del tramo) y esa subida
-- ya no cuenta para el récord. Si ya estás arriba, se compensa con dinero. Devuelve true si entrega algo.
function Obby.skip(player)
	local s = G.Core.sessions[player]
	local d = G.Data.profiles[player]
	if not s or not d then
		return false
	end
	local od = obbyData(d)
	if od.stage >= O.STAGES then
		local amount = math.max(1000, math.floor(G.Core.income(player) * O.SECTION_MONEY_SECS))
		G.Core.addMoney(player, amount)
		G.Net.toast(player, "obbySkipTop", G.Format.num(amount))
		return true
	end
	od.stage += 1
	s.obbyRunStart = nil -- con saltos no hay récord
	s.obbyLastCp = os.clock()
	local hrp = s.inObby and hrpOf(player)
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = Obby.spawnCF(od.stage)
	end
	G.Net.toast(player, "obbySkipped", od.stage)
	return true
end

---------------------------------------------------------------------
-- Ranking: récord del Olimpo (mejor tiempo del 1 al 100 sin saltar etapas), en la plaza y en la isla
---------------------------------------------------------------------
Obby.boards = {}
local store = nil
local uploaded = {} -- [UserId] = mejor tiempo ya subido
local names = {}

local function nameOf(uid)
	if names[uid] then
		return names[uid]
	end
	local ok, n = pcall(function()
		return Players:GetNameFromUserIdAsync(uid)
	end)
	names[uid] = ok and n or ("#" .. uid)
	return names[uid]
end

local function buildBoard(cf, parent, scale)
	scale = scale or 1
	local m = Instance.new("Model")
	m.Name = "OlympusBoard"
	local gold = Color3.fromRGB(240, 196, 92)
	local board = P({ Name = "BoardFace", Size = Vector3.new(14, 17, 1) * scale, CFrame = cf * CFrame.new(0, 11 * scale, 0), Color = Color3.fromRGB(24, 18, 40), Material = Enum.Material.SmoothPlastic }, m)
	P({ Name = "BoardTrim", Size = Vector3.new(15, 1, 1.6) * scale, CFrame = cf * CFrame.new(0, 20 * scale, 0), Color = gold, Material = Enum.Material.Foil }, m)
	for side = -1, 1, 2 do
		P({ Name = "BoardColumn", Size = Vector3.new(1.8, 21, 1.8) * scale, CFrame = cf * CFrame.new(side * 7.9 * scale, 10.5 * scale, 0), Color = Color3.fromRGB(245, 240, 230), Material = Enum.Material.Marble }, m)
	end
	local sg = Instance.new("SurfaceGui")
	sg.Name = "BoardGui"
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 34
	sg.LightInfluence = 0
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.BackgroundTransparency = 1
	title.Size = UDim2.fromScale(1, 0.15)
	title.TextScaled = true
	title.Font = Enum.Font.FredokaOne
	title.TextColor3 = Color3.fromRGB(255, 220, 120)
	title.Text = "🏛️ OLYMPUS RECORD\nRÉCORD DEL OLIMPO"
	title.Parent = sg
	local list = Instance.new("Frame")
	list.Name = "List"
	list.BackgroundTransparency = 1
	list.Size = UDim2.fromScale(0.94, 0.82)
	list.Position = UDim2.fromScale(0.03, 0.17)
	local layout = Instance.new("UIListLayout")
	layout.SortOrder = Enum.SortOrder.LayoutOrder
	layout.Padding = UDim.new(0, 3)
	layout.Parent = list
	list.Parent = sg
	sg.Parent = board
	m.Parent = parent
	table.insert(Obby.boards, { model = m, list = list, title = title })
	return m
end

local MEDALS = { Color3.fromRGB(255, 215, 0), Color3.fromRGB(200, 205, 215), Color3.fromRGB(205, 127, 50) }
function Obby.renderBoards(rows)
	for _, b in ipairs(Obby.boards) do
		for _, c in ipairs(b.list:GetChildren()) do
			if c:IsA("TextLabel") then
				c:Destroy()
			end
		end
		if #rows == 0 then
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.new(1, 0, 0, 40)
			l.Font = Enum.Font.GothamBold
			l.TextScaled = true
			l.TextColor3 = Color3.fromRGB(230, 220, 255)
			l.Text = "— ¡Sé el primero! / Be the first! —"
			l.Parent = b.list
		end
		for i, row in ipairs(rows) do
			local l = Instance.new("TextLabel")
			l.LayoutOrder = i
			l.Size = UDim2.new(1, 0, 0, 40)
			l.BackgroundTransparency = i % 2 == 0 and 1 or 0.85
			l.BackgroundColor3 = Color3.new(1, 1, 1)
			l.Font = Enum.Font.GothamBold
			l.TextScaled = true
			l.TextXAlignment = Enum.TextXAlignment.Left
			l.TextColor3 = MEDALS[i] or Color3.new(1, 1, 1)
			l.Text = string.format("  #%d  %s  —  ⏱ %s", i, row.name, G.Format.time(row.value))
			l.Parent = b.list
		end
	end
end

local function updateBoards()
	if not store then
		return
	end
	-- subir los récords nuevos de los jugadores de este servidor
	for player in pairs(G.Core.sessions) do
		local d = G.Data.profiles[player]
		local best = d and d.obby and d.obby.best or 0
		if typeof(player) == "Instance" and best > 0 and uploaded[player.UserId] ~= best then
			local ok = pcall(function()
				store:SetAsync(tostring(player.UserId), best)
			end)
			if ok then
				uploaded[player.UserId] = best
			end
		end
	end
	-- leer los 10 mejores (menos tiempo = mejor)
	local ok, pages = pcall(function()
		return store:GetSortedAsync(true, 10, 1)
	end)
	if ok and pages then
		local rows = {}
		for _, entry in ipairs(pages:GetCurrentPage()) do
			local uid = tonumber(entry.key)
			table.insert(rows, { name = uid and nameOf(uid) or entry.key, value = entry.value })
		end
		Obby.renderBoards(rows)
	end
end

-- Cada 0,2 s: ¿ha llegado alguien al siguiente punto de control o a la cima?
local function poll()
	for player, s in pairs(G.Core.sessions) do
		if s.inObby then
			local d = G.Data.profiles[player]
			local hrp = hrpOf(player)
			if d and hrp then
				local od = obbyData(d)
				local nextPad = Obby.pads[od.stage + 1]
				if nextPad then
					local rel = nextPad.CFrame:PointToObjectSpace(hrp.Position)
					if math.abs(rel.X) <= nextPad.Size.X / 2 + 0.5 and math.abs(rel.Z) <= nextPad.Size.Z / 2 + 0.5 and rel.Y > 0 and rel.Y < 9 then
						Obby.reach(player, od.stage + 1)
					end
				elseif od.stage >= O.STAGES and Obby.summit then
					local flat = Vector3.new(hrp.Position.X - Obby.summit.pos.X, 0, hrp.Position.Z - Obby.summit.pos.Z)
					if flat.Magnitude <= Obby.summit.radius and math.abs(hrp.Position.Y - Obby.summit.pos.Y) < 12 then
						Obby.finish(player)
					end
				end
			end
		end
	end
end

function Obby.init(g)
	G = g
	C = g.Config
	O = C.OBBY
	Obby.build()
	-- ranking: junto al portal de la plaza y en la salida de la isla
	buildBoard(CFrame.lookAt(O.BOARD, O.BOARD + (O.BOARD_FACING or Vector3.new(0, 0, 1))), Obby.folder, 0.9)
	local islandBoard = buildBoard(Obby.padCF(0) * CFrame.new(-14, -0.7, 0) * CFrame.Angles(0, math.rad(-90), 0), Obby.folder, 0.8)
	P({ Name = "BoardBase", Size = Vector3.new(14, 1.2, 4), CFrame = Obby.padCF(0) * CFrame.new(-14, -1.3, 0) * CFrame.Angles(0, math.rad(-90), 0), Color = Color3.fromRGB(236, 230, 218), Material = Enum.Material.Marble }, islandBoard)
	Obby.renderBoards({})
	pcall(function()
		store = DataStoreService:GetOrderedDataStore(O.BOARD_STORE)
	end)
	task.spawn(function()
		task.wait(8)
		while true do
			pcall(updateBoards)
			task.wait(60)
		end
	end)
	-- compra "Saltar etapa"
	if G.Shop and G.Shop.handlers then
		G.Shop.handlers.obbySkip = function(player)
			return Obby.skip(player)
		end
	end
	G.Core.actions.obbyEnter = function(player)
		Obby.enter(player)
	end
	G.Core.actions.obbyLeave = function(player)
		Obby.leave(player)
	end
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(poll)
			if not ok then
				warn("[Obby] " .. tostring(err))
			end
		end
	end)
end

return Obby
