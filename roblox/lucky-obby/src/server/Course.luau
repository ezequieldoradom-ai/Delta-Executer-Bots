-- Recorrido de la carrera: se genera de nuevo en cada ronda (semilla) en línea recta hacia +Z.
-- Cada tramo empieza con una zona de descanso; cada CHECKPOINT_EVERY tramos esa zona es un punto de control.
-- Contrato con el cliente (lo anima y detecta él):
--   Kill       tocar = volver a tu punto de control
--   Spin       gira sobre Y (Speed, BaseCF)
--   Move       va y viene por X (Amp, Period, Phase, BaseCF) y te lleva con ella
--   JumpPad    impulsor (Power)
--   Belt       cinta que arrastra (Belt = velocidad)
local CollectionService = game:GetService("CollectionService")

local Course = {}
local C, K
local folder = nil

Course.checkpoints = {} -- [i] = { pos = Vector3 (encima), z0, z1 } (0 = salida)
Course.finishZ = 0
Course.length = 0

local function part(props, parent)
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
	p.Parent = parent or folder
	return p
end

local THEMES = {
	{ floor = Color3.fromRGB(110, 205, 120), alt = Color3.fromRGB(255, 220, 90), mat = Enum.Material.SmoothPlastic },
	{ floor = Color3.fromRGB(120, 170, 255), alt = Color3.fromRGB(255, 140, 200), mat = Enum.Material.SmoothPlastic },
	{ floor = Color3.fromRGB(255, 180, 90), alt = Color3.fromRGB(120, 230, 255), mat = Enum.Material.SmoothPlastic },
	{ floor = Color3.fromRGB(200, 130, 255), alt = Color3.fromRGB(140, 255, 170), mat = Enum.Material.SmoothPlastic },
}
local LAVA = Color3.fromRGB(255, 70, 40)

local function kill(props)
	props.Color = LAVA
	props.Material = Enum.Material.Neon
	props.Tags = props.Tags or {}
	table.insert(props.Tags, "Kill")
	return part(props)
end

-- Obstáculos: z de a a b (mundo), y = altura del recorrido; rng = Random de la ronda
local OB = {}
function OB.stones(a, b, y, th, rng)
	for row = 0, 3 do
		local z = a + 4 + row * (b - a - 6) / 3
		local must = rng:NextInteger(1, 3)
		for k, x in ipairs({ -6, 0, 6 }) do
			if k == must or rng:NextNumber() < 0.8 then
				part({ Name = "Stone", Size = Vector3.new(3.6, 1, 3.6), CFrame = CFrame.new(x + rng:NextNumber(-1, 1), y - 0.5, z), Color = (row % 2 == 0) and th.floor or th.alt, Material = th.mat })
			end
		end
	end
end
function OB.lava(a, b, y, th, rng)
	part({ Name = "Floor", Size = Vector3.new(C.WIDTH, 1, b - a), CFrame = CFrame.new(0, y - 0.5, (a + b) / 2), Color = th.floor, Material = th.mat })
	for i = 1, 3 do
		local z = a + (b - a) * i / 4
		kill({ Name = "LavaStrip", Size = Vector3.new(C.WIDTH, 0.4, rng:NextNumber(2.4, 3.4)), CFrame = CFrame.new(0, y + 0.15, z) })
	end
end
function OB.spinners(a, b, y, th, rng)
	part({ Name = "Floor", Size = Vector3.new(C.WIDTH, 1, b - a), CFrame = CFrame.new(0, y - 0.5, (a + b) / 2), Color = th.floor, Material = th.mat })
	for i = 1, 2 do
		local z = a + (b - a) * i / 3
		local base = CFrame.new(0, y + 1.4, z)
		part({ Name = "Hub", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.6, 1.8, 1.8), CFrame = CFrame.new(0, y + 1.3, z) * CFrame.Angles(0, 0, math.rad(90)), Color = th.alt, Material = Enum.Material.Metal })
		kill({ Name = "SpinBar", Size = Vector3.new(C.WIDTH - 1, 0.9, 0.9), CFrame = base, Tags = { "Spin" }, Attrs = { Speed = rng:NextNumber(1.6, 2.6) * (i % 2 == 0 and -1 or 1), BaseCF = base } })
	end
end
function OB.movers(a, b, y, th, rng)
	for i = 1, 3 do
		local z = a + (b - a) * (i - 0.5) / 3
		local base = CFrame.new(0, y - 0.5, z)
		part({ Name = "Mover", Size = Vector3.new(6, 1, 6), CFrame = base, Color = th.alt, Material = th.mat, Tags = { "Move" }, Attrs = { Amp = 5.5, Period = rng:NextNumber(2.8, 3.8), Phase = rng:NextNumber(0, 6.28), BaseCF = base } })
	end
end
function OB.beams(a, b, y, th, rng)
	for _, x in ipairs({ -6, 0, 6 }) do
		part({ Name = "Beam", Size = Vector3.new(rng:NextNumber(1.6, 2.4), 1, b - a), CFrame = CFrame.new(x, y - 0.5, (a + b) / 2), Color = th.alt, Material = th.mat })
	end
end
function OB.pads(a, b, y, th)
	part({ Name = "Floor", Size = Vector3.new(C.WIDTH, 1, 10), CFrame = CFrame.new(0, y - 0.5, a + 5), Color = th.floor, Material = th.mat })
	for _, x in ipairs({ -5, 5 }) do
		part({ Name = "JumpPad", Size = Vector3.new(4.5, 0.4, 4.5), CFrame = CFrame.new(x, y + 0.2, a + 7), Color = Color3.fromRGB(90, 255, 140), Material = Enum.Material.Neon, Tags = { "JumpPad" }, Attrs = { Power = 80 } })
	end
	part({ Name = "High", Size = Vector3.new(C.WIDTH, 1, 12), CFrame = CFrame.new(0, y + 12, a + 19), Color = th.alt, Material = th.mat })
	part({ Name = "Step", Size = Vector3.new(C.WIDTH, 1, 6), CFrame = CFrame.new(0, y + 6, b - 5), Color = th.floor, Material = th.mat })
end
function OB.belts(a, b, y, th, rng)
	local belt = part({ Name = "Belt", Size = Vector3.new(C.WIDTH - 4, 1, b - a), CFrame = CFrame.new(0, y - 0.5, (a + b) / 2), Color = Color3.fromRGB(40, 40, 52), Material = Enum.Material.DiamondPlate, Tags = { "Belt" }, Attrs = { Belt = Vector3.new(0, 0, -rng:NextNumber(8, 12)) } })
	belt.AssemblyLinearVelocity = belt:GetAttribute("Belt")
	for _, x in ipairs({ -(C.WIDTH / 2 - 1), C.WIDTH / 2 - 1 }) do
		kill({ Name = "BeltLava", Size = Vector3.new(2, 0.8, b - a), CFrame = CFrame.new(x, y - 0.3, (a + b) / 2) })
	end
end
function OB.pillars(a, b, y, th, rng)
	for i = 1, 6 do
		local z = a + 2 + (b - a - 4) * (i - 0.5) / 6
		local x = (i % 2 == 0 and 4 or -4) + rng:NextNumber(-1.5, 1.5)
		local h = rng:NextNumber(-1.5, 2.2)
		part({ Name = "Pillar", Size = Vector3.new(4, 16, 4), CFrame = CFrame.new(x, y + h - 8, z), Color = (i % 2 == 0) and th.floor or th.alt, Material = th.mat })
	end
end
function OB.sweepers(a, b, y, th, rng)
	part({ Name = "Floor", Size = Vector3.new(C.WIDTH, 1, b - a), CFrame = CFrame.new(0, y - 0.5, (a + b) / 2), Color = th.floor, Material = th.mat })
	for i = 1, 3 do
		local z = a + (b - a) * (i - 0.5) / 3
		local base = CFrame.new(0, y + 2, z)
		part({ Name = "Sweeper", Size = Vector3.new(5, 4, 2), CFrame = base, Color = th.alt, Material = Enum.Material.SmoothPlastic, Tags = { "Move" }, Attrs = { Amp = C.WIDTH / 2 - 2.5, Period = rng:NextNumber(1.8, 2.6), Phase = rng:NextNumber(0, 6.28), BaseCF = base } })
	end
end
Course.TYPES = { "stones", "lava", "spinners", "movers", "beams", "pads", "belts", "pillars", "sweepers" }

-- Construye un recorrido nuevo (destruye el anterior)
function Course.build(seed)
	if folder then
		folder:Destroy()
	end
	local rng = Random.new(seed or os.time())
	folder = Instance.new("Folder")
	folder.Name = "Course"
	local y = C.START.Y
	local z = C.START.Z
	table.clear(Course.checkpoints)
	-- salida (punto de control 0)
	part({ Name = "StartPad", Size = Vector3.new(C.WIDTH + 6, 1, 22), CFrame = CFrame.new(0, y - 0.5, z), Color = Color3.fromRGB(240, 240, 250), Material = Enum.Material.SmoothPlastic })
	part({ Name = "StartLine", Size = Vector3.new(C.WIDTH + 6, 0.12, 1.2), CFrame = CFrame.new(0, y + 0.06, z + 10), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.Neon })
	Course.checkpoints[0] = { pos = Vector3.new(0, y + 3, z), z0 = z - 11, z1 = z + 11 }
	z += 11
	-- tipos al azar sin repetir el anterior
	local last
	local kinds = {}
	for i = 1, C.SEGMENTS do
		local kind
		repeat
			kind = Course.TYPES[rng:NextInteger(1, #Course.TYPES)]
		until kind ~= last
		last = kind
		kinds[i] = kind
		local th = THEMES[(math.floor((i - 1) / C.CHECKPOINT_EVERY) % #THEMES) + 1]
		local cp = (i - 1) % C.CHECKPOINT_EVERY == 0 and i > 1
		local rest = part({ Name = cp and "Checkpoint" or "Rest", Size = Vector3.new(C.WIDTH, 1, 6), CFrame = CFrame.new(0, y - 0.5, z + 3), Color = cp and Color3.fromRGB(245, 245, 255) or th.floor:Lerp(Color3.new(1, 1, 1), 0.3), Material = th.mat })
		if cp then
			local idx = #Course.checkpoints + 1
			rest:SetAttribute("Checkpoint", idx)
			part({ Name = "CPRing", Size = Vector3.new(C.WIDTH - 2, 0.14, 4), CFrame = CFrame.new(0, y + 0.07, z + 3), Color = Color3.fromRGB(110, 255, 150), Material = Enum.Material.Neon, CanCollide = false, Transparency = 0.35 })
			Course.checkpoints[idx] = { pos = Vector3.new(0, y + 3, z + 3), z0 = z, z1 = z + 6 }
		end
		OB[kind](z + 6, z + C.SEG_LEN, y, th, rng)
		z += C.SEG_LEN
	end
	-- meta
	part({ Name = "FinishPad", Size = Vector3.new(C.WIDTH + 10, 1, 24), CFrame = CFrame.new(0, y - 0.5, z + 12), Color = Color3.fromRGB(255, 220, 90), Material = Enum.Material.SmoothPlastic })
	for side = -1, 1, 2 do
		part({ Name = "FinishPole", Size = Vector3.new(1.6, 16, 1.6), CFrame = CFrame.new(side * (C.WIDTH / 2 + 3), y + 8, z + 4), Color = Color3.fromRGB(255, 255, 255), Material = Enum.Material.SmoothPlastic })
	end
	local banner = part({ Name = "FinishBanner", Size = Vector3.new(C.WIDTH + 8, 4, 0.6), CFrame = CFrame.new(0, y + 15, z + 4), Color = Color3.fromRGB(30, 30, 40), Material = Enum.Material.SmoothPlastic })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 30
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(255, 230, 90)
	l.Text = "🏁 FINISH 🏁"
	l.Parent = sg
	sg.Parent = banner
	Course.finishZ = z + 2
	Course.length = z - C.START.Z
	folder:SetAttribute("Seed", seed or 0)
	folder:SetAttribute("FinishZ", Course.finishZ)
	folder.Parent = workspace
	Course.kinds = kinds
	return folder
end

-- ¿En qué punto de control está esta posición? (nil si en ninguno)
function Course.checkpointAt(pos)
	for i, cp in pairs(Course.checkpoints) do
		if pos.Z >= cp.z0 and pos.Z <= cp.z1 and math.abs(pos.X) <= C.WIDTH / 2 + 3 and pos.Y > cp.pos.Y - 6 and pos.Y < cp.pos.Y + 8 then
			return i
		end
	end
	return nil
end

function Course.init(g)
	C = g.Config.COURSE
	K = g.Config
end

return Course
