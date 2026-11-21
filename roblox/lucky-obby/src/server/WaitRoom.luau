-- Lucky Obby Race — SALA DE ESPERA de la carrera (Shadow)
--   · Si pisas el portal de la carrera cuando ya está en marcha, vas a esta sala flotante.
--   · Desde aquí puedes ver la carrera (cámara siguiendo a los corredores) y jugar a Flappy Bear.
--   · Cuando se abre la inscripción te apunta solo; al empezar, la carrera te lleva a la salida.
--   · Botón SALIR: vuelves al vestíbulo.
local Players = game:GetService("Players")

local WaitRoom = {}
local G, C
WaitRoom.CENTER = Vector3.new(0, 150, -260)
WaitRoom.waiting = {} -- [player] = true
local waiting = WaitRoom.waiting

local function hrpOf(p)
	local c = p.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

local function build()
	local f = Instance.new("Folder")
	f.Name = "WaitRoom"
	local c = WaitRoom.CENTER
	local S = 44
	part({ Name = "Floor", Size = Vector3.new(S, 1, S), CFrame = CFrame.new(c - Vector3.new(0, 0.5, 0)), Color = Color3.fromRGB(60, 40, 110), Material = Enum.Material.SmoothPlastic }, f)
	-- suelo a cuadros suaves
	for i = -2, 2 do
		for j = -2, 2 do
			if (i + j) % 2 == 0 then
				part({ Name = "Tile", Size = Vector3.new(S / 5 - 0.2, 0.1, S / 5 - 0.2), CFrame = CFrame.new(c + Vector3.new(i * S / 5, 0.05, j * S / 5)), Color = Color3.fromRGB(90, 60, 150), Material = Enum.Material.SmoothPlastic, CanCollide = false }, f)
			end
		end
	end
	-- paredes de cristal con borde de neón (no te caes)
	for _, w in ipairs({ { Vector3.new(0, 0, S / 2), Vector3.new(S, 10, 1) }, { Vector3.new(0, 0, -S / 2), Vector3.new(S, 10, 1) }, { Vector3.new(S / 2, 0, 0), Vector3.new(1, 10, S) }, { Vector3.new(-S / 2, 0, 0), Vector3.new(1, 10, S) } }) do
		part({ Name = "Glass", Size = w[2], CFrame = CFrame.new(c + w[1] + Vector3.new(0, 5, 0)), Color = Color3.fromRGB(180, 220, 255), Material = Enum.Material.Glass, Transparency = 0.7 }, f)
		part({ Name = "Trim", Size = Vector3.new(w[2].X + 0.4, 0.5, w[2].Z + 0.4), CFrame = CFrame.new(c + w[1] + Vector3.new(0, 10.2, 0)), Color = Color3.fromRGB(255, 200, 70), Material = Enum.Material.Neon, CanCollide = false }, f)
	end
	-- bancos
	for _, x in ipairs({ -12, 12 }) do
		for _, z in ipairs({ -12, 12 }) do
			part({ Name = "Bench", Size = Vector3.new(8, 1, 3), CFrame = CFrame.new(c + Vector3.new(x, 1.5, z)), Color = Color3.fromRGB(255, 170, 60), Material = Enum.Material.SmoothPlastic }, f)
			for _, lx in ipairs({ -3.5, 3.5 }) do
				part({ Name = "BenchLeg", Size = Vector3.new(0.6, 1.5, 2.6), CFrame = CFrame.new(c + Vector3.new(x + lx, 0.75, z)), Color = Color3.fromRGB(60, 40, 90), Material = Enum.Material.SmoothPlastic }, f)
			end
		end
	end
	-- cartel flotante
	local sign = part({ Name = "Sign", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(c + Vector3.new(0, 12, 0)), Transparency = 1, CanCollide = false }, f)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromOffset(380, 96) -- tamaño fijo en pantalla: de cerca no lo tapa todo
	bb.LightInfluence = 0
	bb.MaxDistance = 120
	bb.Parent = sign
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.RichText = true
	l.Font = Enum.Font.LuckiestGuy
	l.TextColor3 = Color3.fromRGB(255, 220, 80)
	l.TextStrokeTransparency = 0
	l.Text = '⏳ SALA DE ESPERA\n<font color="#FFFFFF">Siguiente carrera en breve</font>'
	l.Parent = bb
	-- luz cálida
	local lamp = part({ Name = "Lamp", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(c + Vector3.new(0, 12, 0)), Transparency = 1, CanCollide = false }, f)
	local pl = Instance.new("PointLight")
	pl.Range = 40
	pl.Brightness = 1.2
	pl.Color = Color3.fromRGB(255, 220, 170)
	pl.Parent = lamp
	f.Parent = workspace
end

local function spot()
	local c = WaitRoom.CENTER
	return CFrame.new(c + Vector3.new(math.random(-8, 8), 3, math.random(-8, 8)))
end

function WaitRoom.enter(p)
	if waiting[p] or G.Race.isRacing(p) then
		return false
	end
	local hrp = hrpOf(p)
	if not hrp then
		return false
	end
	if G.Slap and G.Slap.stationOf(p) then
		G.Slap.leave(p)
	end
	if G.Hill and G.Hill.memberOf(p) then
		G.Hill.leave(p)
	end
	if G.Obbies and G.Obbies.sessions[p] then
		G.Obbies.leave(p, false)
	end
	waiting[p] = true
	p:SetAttribute("Waiting", true)
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = spot()
	G.Net.Event:FireClient(p, "toast", { text = "⏳ Carrera en curso: te apuntamos a la siguiente" })
	return true
end

function WaitRoom.leave(p, toLobby)
	if not waiting[p] then
		return
	end
	waiting[p] = nil
	p:SetAttribute("Waiting", nil)
	if G.Race.joined and G.Race.state == "joining" then
		G.Race.setJoined(p, false)
	end
	if toLobby then
		local hrp = hrpOf(p)
		if hrp then
			local L = C.COURSE.LOBBY
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(L + Vector3.new(math.random(-6, 6), 3, math.random(-6, 6)))
		end
	end
end

function WaitRoom.init(g)
	G = g
	C = g.Config
	G.WaitRoom = WaitRoom
	build()
	G.Net.Wait.OnServerEvent:Connect(function(p, kind)
		if kind == "leave" then
			WaitRoom.leave(p, true)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		waiting[p] = nil
	end)
	-- si mueres en la sala, reapareces en la sala
	local function onPlayer(p)
		p.CharacterAdded:Connect(function(char)
			task.wait(0.4)
			local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
			if waiting[p] and hrp then
				hrp.CFrame = spot()
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
	task.spawn(function()
		while true do
			task.wait(0.3)
			local state = G.Race.state
			for p in pairs(waiting) do
				if not p.Parent then
					waiting[p] = nil
					continue
				end
				-- la carrera empezó con él dentro: ya no espera (la carrera le ha llevado a la salida)
				if G.Race.isRacing(p) then
					waiting[p] = nil
					p:SetAttribute("Waiting", nil)
					continue
				end
				-- se abre la inscripción: apuntado solo
				if state == "joining" and not G.Race.joined[p] then
					if G.Race.setJoined(p, true) then
						G.Net.Event:FireClient(p, "toast", { text = "✅ ¡Apuntado a la carrera!" })
					end
				end
				-- se ha ido de la sala (o se cayó): fuera de la espera
				local hrp = hrpOf(p)
				local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 and (hrp.Position - WaitRoom.CENTER).Magnitude > 60 then
					WaitRoom.leave(p, false)
				end
			end
		end
	end)
end

return WaitRoom
