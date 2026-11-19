-- Vestíbulo: plataforma flotante con punto de aparición, cartel del juego y adornos
local Lobby = {}

function Lobby.init(G)
	local C = G.Config.COURSE
	local f = Instance.new("Folder")
	f.Name = "Lobby"
	local function part(props)
		local p = Instance.new(props.Class or "Part")
		p.Anchored = true
		p.TopSurface = Enum.SurfaceType.Smooth
		p.BottomSurface = Enum.SurfaceType.Smooth
		for k, v in pairs(props) do
			if k ~= "Class" then
				p[k] = v
			end
		end
		p.Parent = f
		return p
	end
	local c = C.LOBBY - Vector3.new(0, 4, 0)
	part({ Name = "LobbyFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, 116, 116), CFrame = CFrame.new(c) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(245, 245, 250), Material = Enum.Material.SmoothPlastic })
	part({ Name = "LobbyRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, 118, 118), CFrame = CFrame.new(c - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Neon })
	local spawn = Instance.new("SpawnLocation")
	spawn.Anchored = true
	spawn.Size = Vector3.new(10, 1, 10)
	spawn.CFrame = CFrame.new(c + Vector3.new(0, 1.1, 0))
	spawn.Color = Color3.fromRGB(110, 205, 120)
	spawn.Material = Enum.Material.SmoothPlastic
	spawn.Neutral = true
	spawn.Duration = 0
	spawn.Parent = f
	-- columnas de colores y cartel del juego mirando a la carrera
	local colors = { Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(90, 220, 120), Color3.fromRGB(90, 160, 255), Color3.fromRGB(200, 110, 255), Color3.fromRGB(255, 140, 200) }
	-- huecos sin pilar donde salen los caminos (al obby: +Z; a la plaza de guantazos: hacia Decor.PLAZA)
	local Decor = require(script.Parent.Decor)
	local gaps = { math.pi / 2 }
	if Decor.PLAZA then
		table.insert(gaps, math.atan2(Decor.PLAZA.Z - c.Z, Decor.PLAZA.X - c.X))
	end
	for i = 1, 12 do
		local a = i / 12 * math.pi * 2
		local blocked = false
		for _, g in ipairs(gaps) do
			local d = math.abs((a - g + math.pi) % (2 * math.pi) - math.pi)
			if d < math.rad(22) then
				blocked = true
			end
		end
		if blocked then
			continue
		end
		part({ Name = "Pillar", Size = Vector3.new(2, 8 + (i % 3) * 3, 2), CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 55, 4 + (i % 3) * 1.5, math.sin(a) * 55)), Color = colors[(i - 1) % #colors + 1], Material = Enum.Material.SmoothPlastic })
		part({ Name = "LuckyBlock", Size = Vector3.new(2.6, 2.6, 2.6), CFrame = CFrame.new(c + Vector3.new(math.cos(a) * 55, 10 + (i % 3) * 3, math.sin(a) * 55)) * CFrame.Angles(0, a, math.rad(45)), Color = Color3.fromRGB(255, 210, 60), Material = Enum.Material.Neon })
	end
	local sign = part({ Name = "Sign", Size = Vector3.new(30, 8, 1), CFrame = CFrame.lookAt(c + Vector3.new(0, 23.5, 54), c + Vector3.new(0, 23.5, 0)), Color = Color3.fromRGB(30, 26, 45), Material = Enum.Material.SmoothPlastic })
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Front
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 25
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(255, 220, 70)
	l.Text = "🎁 LUCKY OBBY RACE 🏁"
	l.Parent = sg
	sg.Parent = sign
	f.Parent = workspace
end

return Lobby
