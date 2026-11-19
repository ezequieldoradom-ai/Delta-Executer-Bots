-- Lucky Obby Race — la plaza del vestíbulo (Shadow, petición del dueño)
--   · Suelo con mosaico: anillos de colores, rayos arcoíris y un centro dorado (no un suelo liso).
--   · Dos caminos cortos con señales: 🏁 OBBY (termina en un portal: pisarlo te apunta a la carrera)
--     y 🖐️ ¿QUIÉN HA SIDO? (hasta la plaza de los guantazos).
local Players = game:GetService("Players")

local Plaza = {}
local G

local RAINBOW = {
	Color3.fromRGB(255, 80, 90), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 220, 70),
	Color3.fromRGB(90, 210, 110), Color3.fromRGB(70, 160, 255), Color3.fromRGB(170, 100, 255),
}

local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = props.CanCollide == true
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "CanCollide" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end
local function disc(parent, center, r, y, color, mat, thick)
	return part({ Name = "Mosaic", Shape = Enum.PartType.Cylinder, Size = Vector3.new(thick or 0.06, r * 2, r * 2), CFrame = CFrame.new(center.X, y, center.Z) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = mat or Enum.Material.SmoothPlastic }, parent)
end
local function label(parent, face, text, color, ppStud)
	local sg = Instance.new("SurfaceGui")
	sg.Face = face
	sg.LightInfluence = 0
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = ppStud or 30
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.Font = Enum.Font.LuckiestGuy
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.Text = text
	l.Parent = sg
	sg.Parent = parent
end

-- Cartel de madera con flecha, mirando hacia `lookFrom` (de donde viene la gente)
local function signpost(parent, base, dir, text, color)
	local look = CFrame.lookAt(base, base - dir) -- la cara Front mira al vestíbulo
	part({ Name = "SignPole", Size = Vector3.new(0.8, 9, 0.8), CFrame = look * CFrame.new(0, 4.5, 0), Color = Color3.fromRGB(110, 75, 45), Material = Enum.Material.Wood, CanCollide = true }, parent)
	local board = part({ Name = "SignBoard", Size = Vector3.new(12, 3.2, 0.5), CFrame = look * CFrame.new(0, 7.6, -0.6), Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.WoodPlanks }, parent)
	part({ Name = "SignTrim", Size = Vector3.new(12.4, 0.3, 0.6), CFrame = look * CFrame.new(0, 9.3, -0.6), Color = color, Material = Enum.Material.Neon }, parent)
	label(board, Enum.NormalId.Front, text, Color3.new(1, 1, 1), 28)
	label(board, Enum.NormalId.Back, text, Color3.new(1, 1, 1), 28)
end

-- Camino de baldosas de colores de A a B (ancho w) con bordes de luz
local function path(parent, A, Bp, w, colors, mat)
	local dir = (Bp - A).Unit
	local len = (Bp - A).Magnitude
	local n = math.max(1, math.floor(len / 4))
	local step = len / n
	for i = 0, n - 1 do
		local mid = A + dir * (step * (i + 0.5))
		part({ Name = "PathTile", Size = Vector3.new(w, 1, step - 0.25), CFrame = CFrame.lookAt(mid + Vector3.new(0, 0.5, 0), mid + Vector3.new(0, 0.5, 0) + dir), Color = colors[i % #colors + 1], Material = mat or Enum.Material.SmoothPlastic, CanCollide = true }, parent)
	end
	local cf = CFrame.lookAt((A + Bp) / 2 + Vector3.new(0, 1.05, 0), (A + Bp) / 2 + Vector3.new(0, 1.05, 0) + dir)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "PathEdge", Size = Vector3.new(0.4, 0.2, len), CFrame = cf * CFrame.new(sx * (w / 2 - 0.2), 0, 0), Color = Color3.fromRGB(255, 240, 180), Material = Enum.Material.Neon }, parent)
	end
	return dir, len
end

function Plaza.init(g)
	G = g
	local Decor = require(script.Parent.Decor)
	local C = G.Config.COURSE
	local c = C.LOBBY - Vector3.new(0, 4, 0) -- centro del suelo (arriba en y = 1)
	local R = Decor.LOBBY_R
	local f = Instance.new("Folder")
	f.Name = "LobbyPlaza"
	local top = 1.03
	-- SUELO: losas de piedra crema, anillo de baldosas rosas, rayos arcoíris y centro de mármol dorado
	local floor = workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChild("LobbyFloor")
	if floor then
		floor.Material = Enum.Material.Pavement
		floor.Color = Color3.fromRGB(236, 228, 214)
	end
	-- suelo de obby: baldosas a cuadros (blanco y colores pastel por sectores) con borde rosa
	disc(f, c, R - 5, top, Color3.fromRGB(255, 120, 190), Enum.Material.Neon)
	disc(f, c, R - 5.6, top + 0.005, Color3.fromRGB(245, 240, 232), Enum.Material.SmoothPlastic)
	local PASTEL = {
		Color3.fromRGB(255, 150, 160), Color3.fromRGB(255, 200, 120), Color3.fromRGB(255, 235, 130),
		Color3.fromRGB(150, 230, 150), Color3.fromRGB(130, 200, 255), Color3.fromRGB(200, 160, 255),
	}
	local TILE = 6
	local maxR = R - 7
	for ix = -math.ceil(maxR / TILE), math.ceil(maxR / TILE) do
		for iz = -math.ceil(maxR / TILE), math.ceil(maxR / TILE) do
			local x, z = ix * TILE, iz * TILE
			local d = math.sqrt(x * x + z * z)
			if d + TILE * 0.7 < maxR and d > 15 + TILE * 0.5 and (ix + iz) % 2 == 0 then
				local a = math.atan2(x, z)
				local sector = math.floor(((a + math.pi) / (2 * math.pi)) * #PASTEL) % #PASTEL + 1
				part({ Name = "Tile", Size = Vector3.new(TILE - 0.2, 0.06, TILE - 0.2), CFrame = CFrame.new(c.X + x, top + 0.02, c.Z + z), Color = PASTEL[sector], Material = Enum.Material.SmoothPlastic }, f)
			end
		end
	end
	disc(f, c, 15, top + 0.03, Color3.fromRGB(255, 205, 70), Enum.Material.Neon)
	disc(f, c, 14.2, top + 0.04, Color3.fromRGB(250, 246, 235), Enum.Material.Marble)
	disc(f, c, 9, top + 0.05, Color3.fromRGB(255, 215, 90), Enum.Material.Foil)
	disc(f, c, 8.3, top + 0.06, Color3.fromRGB(250, 246, 235), Enum.Material.Marble)

	-- CAMINO AL OBBY (+Z, hacia la salida de la carrera) con PORTAL
	local A1 = Vector3.new(c.X, 0, c.Z + R - 1)
	local B1 = Vector3.new(c.X, 0, c.Z + R + 22)
	local dir1 = path(f, A1, B1, 12, RAINBOW, Enum.Material.SmoothPlastic)
	signpost(f, A1 + Vector3.new(11, 0, -9), dir1, "🏁 OBBY → PORTAL", Color3.fromRGB(255, 200, 60))
	local portalPos = B1 + Vector3.new(0, 1, 3)
	part({ Name = "PortalBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1, 16, 16), CFrame = CFrame.new(portalPos) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(60, 40, 90), Material = Enum.Material.Slate, CanCollide = true }, f)
	part({ Name = "PortalPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 12, 12), CFrame = CFrame.new(portalPos + Vector3.new(0, 0.55, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(120, 255, 160), Material = Enum.Material.Neon }, f)
	-- aro del portal: 20 bloques de neón en círculo (de pie, mirando al camino) y velo de energía dentro
	local ringC = portalPos + Vector3.new(0, 7.2, 0)
	local ringCF = CFrame.lookAt(ringC, ringC + dir1)
	local ring
	for k = 0, 19 do
		local ang = k / 20 * math.pi * 2
		local seg = part({ Name = "PortalRing", Size = Vector3.new(1, 2.1, 1), CFrame = ringCF * CFrame.Angles(0, 0, ang) * CFrame.new(0, 6.2, 0), Color = RAINBOW[k % #RAINBOW + 1], Material = Enum.Material.Neon }, f)
		ring = ring or seg
	end
	part({ Name = "PortalInner", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 11.6, 11.6), CFrame = ringCF * CFrame.Angles(0, math.rad(90), 0), Color = Color3.fromRGB(150, 230, 255), Material = Enum.Material.ForceField, Transparency = 0.05 }, f)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "PortalLeg", Size = Vector3.new(1.4, 2, 1.4), CFrame = ringCF * CFrame.new(sx * 4.4, -5.9, 0), Color = Color3.fromRGB(60, 40, 90), Material = Enum.Material.Slate, CanCollide = true }, f)
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 30
	pe.Lifetime = NumberRange.new(1, 1.6)
	pe.Speed = NumberRange.new(4, 8)
	pe.EmissionDirection = Enum.NormalId.Top
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200), Color3.fromRGB(120, 255, 160))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Parent = part({ Name = "PortalFx", Size = Vector3.new(10, 0.2, 10), CFrame = CFrame.new(portalPos + Vector3.new(0, 0.7, 0)), Transparency = 1 }, f)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(16, 4)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 160
	bb.Parent = ring
	local bl = Instance.new("TextLabel")
	bl.Name = "Label"
	bl.BackgroundTransparency = 1
	bl.Size = UDim2.fromScale(1, 1)
	bl.TextScaled = true
	bl.Font = Enum.Font.LuckiestGuy
	bl.TextColor3 = Color3.fromRGB(255, 230, 90)
	bl.TextStrokeTransparency = 0.2
	bl.Text = "🏁 PISA EL PORTAL PARA CORRER"
	bl.Parent = bb

	-- CAMINO A "¿QUIÉN HA SIDO?" (el camino largo lo pone Slap; aquí, la señal en el borde del vestíbulo)
	if Decor.PLAZA then
		local toPlaza = (Vector3.new(Decor.PLAZA.X, 0, Decor.PLAZA.Z) - Vector3.new(c.X, 0, c.Z)).Unit
		local edge = Vector3.new(c.X, 0, c.Z) + toPlaza * (R + 1)
		local side = Vector3.new(-toPlaza.Z, 0, toPlaza.X)
		signpost(f, edge + side * 9, toPlaza, "🖐️ ¿QUIÉN HA SIDO? →", Color3.fromRGB(255, 120, 200))
	end
	-- bloques de obby flotando por la isla (algunos giran: los anima cada cliente con FxSpin)
	local CS = game:GetService("CollectionService")
	local rng = Random.new(21)
	local mid = Decor.ISLAND_CENTER
	for i = 1, 26 do
		local ang = rng:NextNumber(0, math.pi * 2)
		local dist = rng:NextNumber(70, Decor.ISLAND_R + 40)
		local pos = mid + Vector3.new(math.cos(ang) * dist, rng:NextNumber(14, 48), math.sin(ang) * dist)
		local far = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(c.X, 0, c.Z)).Magnitude > R + 12
		local nearPlaza = Decor.PLAZA and (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(Decor.PLAZA.X, 0, Decor.PLAZA.Z)).Magnitude < 55
		if far and not nearPlaza and pos.Z < -15 then
			local s = rng:NextNumber(4, 9)
			local col = RAINBOW[rng:NextInteger(1, #RAINBOW)]
			local b = part({ Name = "FloatBlock", Size = Vector3.new(s, s * rng:NextNumber(0.3, 1), s), CFrame = CFrame.new(pos) * CFrame.Angles(0, rng:NextNumber(0, 6), 0), Color = col, Material = Enum.Material.SmoothPlastic }, f)
			local edge = Instance.new("SelectionBox")
			edge.Adornee = b
			edge.LineThickness = 0.12
			edge.Color3 = col:Lerp(Color3.new(1, 1, 1), 0.6)
			edge.Parent = b
			if i % 3 == 0 then
				b:SetAttribute("BaseCF", b.CFrame)
				b:SetAttribute("Phase", rng:NextNumber(0, 6))
				CS:AddTag(b, "FxSpin")
			end
		end
	end
	f.Parent = workspace

	-- el portal apunta a la carrera a quien lo pisa durante la inscripción
	local told = {}
	task.spawn(function()
		while true do
			task.wait(0.25)
			local state = G.Race.state
			bl.Text = state == "joining" and "🏁 ¡PISA EL PORTAL Y CORRE!" or (state == "break" and "☕ DESCANSO · ENSEGUIDA SE ABRE" or "🏁 CARRERA EN CURSO")
			if state ~= "joining" then
				table.clear(told)
			else
				for _, p in ipairs(Players:GetPlayers()) do
					local hrp = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
					if hrp and (hrp.Position - portalPos).Magnitude < 8 and not G.Race.joined[p] then
						if G.Race.setJoined(p, true) and not told[p] then
							told[p] = true
							G.Net.Event:FireClient(p, "toast", { text = "✅ ¡Apuntado a la carrera!" })
						end
					end
				end
			end
		end
	end)
end

return Plaza
