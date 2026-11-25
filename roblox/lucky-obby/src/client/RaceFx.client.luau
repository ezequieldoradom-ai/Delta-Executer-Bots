-- Lucky Obby Race — efectos de la carrera (Shadow)
--   · Salida: golpe de cámara + confeti + bocina al "¡YA!"
--   · Punto de control: estallido verde + dos notas que suben
--   · Meta: confeti alrededor, fanfarria y zoom lento
--   · Te dan con un objeto: temblor + destello rojo
--   · Caída fuerte: polvo y golpe al aterrizar · Correr rápido: la cámara se abre (sensación de velocidad)
--   · Morir: fundido oscuro y al reaparecer, destello blanco
local Lighting = game:GetService("Lighting")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local function snd(id, vol, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol
	s.PlaybackSpeed = speed or 1
	s.Parent = SoundService
	return s
end
local S = {
	go = snd("rbxasset://sounds/electronicpingshort.wav", 0.7, 0.6),
	ding = snd("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.2),
	ding2 = snd("rbxasset://sounds/electronicpingshort.wav", 0.5, 1.6),
	fanfare = snd("rbxasset://sounds/victory.wav", 0.7, 1),
	hit = snd("rbxasset://sounds/collide.wav", 0.9, 0.7),
	land = snd("rbxasset://sounds/action_jump_land.mp3", 0.7, 0.8),
	swoosh = snd("rbxasset://sounds/swordslash.wav", 0.4, 1.3),
}

-- destellos de pantalla
local cc = Instance.new("ColorCorrectionEffect")
cc.Name = "RaceFxCC"
cc.Parent = Lighting
local function flash(color, strength, time)
	cc.TintColor = color
	cc.Brightness = strength or 0.15
	TweenService:Create(cc, TweenInfo.new(time or 0.4), { TintColor = Color3.new(1, 1, 1), Brightness = 0 }):Play()
end

-- cámara: temblor y golpe de zoom (encima de la cámara normal)
local shake, fovKick = 0, 0
local racing = false
local speedFov = 0
RunService:BindToRenderStep("RaceFx", Enum.RenderPriority.Camera.Value + 2, function(dt)
	local cam = workspace.CurrentCamera
	if not cam or cam.CameraType ~= Enum.CameraType.Custom then
		return
	end
	if shake > 0 then
		local a = shake * 0.35
		cam.CFrame = cam.CFrame * CFrame.Angles((math.random() - 0.5) * a * 0.1, (math.random() - 0.5) * a * 0.1, 0) * CFrame.new((math.random() - 0.5) * a, (math.random() - 0.5) * a, 0)
		shake = math.max(0, shake - dt * 3)
	end
	-- sensación de velocidad: solo en carrera (fuera, la cámara es cosa de otros minijuegos)
	local target = 0
	if racing then
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			local v = hrp.AssemblyLinearVelocity
			local flat = Vector3.new(v.X, 0, v.Z).Magnitude
			target = math.clamp((flat - 18) * 0.9, 0, 12)
		end
	end
	speedFov += (target - speedFov) * math.min(1, dt * 4)
	fovKick = math.max(0, fovKick - dt * 30)
	if racing or fovKick > 0.01 or speedFov > 0.05 then
		cam.FieldOfView = 70 + speedFov + fovKick
	end
end)

-- confeti / estallidos
local function burst(pos, colors, n, speed)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch = true, false, false, false
	p.Transparency = 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(pos)
	p.Parent = workspace
	local e = Instance.new("ParticleEmitter")
	e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	local keys = {}
	for i, c in ipairs(colors) do
		table.insert(keys, ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), c))
	end
	if #keys == 1 then
		table.insert(keys, ColorSequenceKeypoint.new(1, colors[1]))
	end
	e.Color = ColorSequence.new(keys)
	e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6), NumberSequenceKeypoint.new(1, 0) })
	e.Speed = NumberRange.new(speed * 0.5, speed)
	e.SpreadAngle = Vector2.new(180, 180)
	e.Lifetime = NumberRange.new(0.6, 1.2)
	e.Acceleration = Vector3.new(0, -25, 0)
	e.Rate = 0
	e.LightEmission = 0.6
	e.Parent = p
	e:Emit(n)
	task.delay(1.6, function()
		p:Destroy()
	end)
end
local CONFETTI = { Color3.fromRGB(255, 80, 120), Color3.fromRGB(255, 220, 70), Color3.fromRGB(90, 220, 255), Color3.fromRGB(120, 255, 140) }
local function myPos()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	return hrp and hrp.Position
end

-- eventos de la carrera
Remotes:WaitForChild("Event").OnClientEvent:Connect(function(kind, d)
	d = type(d) == "table" and d or {}
	local pos = myPos()
	if kind == "checkpoint" then
		if pos then
			burst(pos, { Color3.fromRGB(110, 255, 150), Color3.fromRGB(255, 255, 255) }, 40, 18)
		end
		fovKick = 6
		task.delay(0.12, function()
			S.ding2:Play()
		end)
	elseif kind == "finished" then
		S.fanfare:Play()
		fovKick = 10
		flash(Color3.fromRGB(255, 240, 180), 0.2, 0.8)
		if pos then
			for i = 0, 2 do
				task.delay(i * 0.35, function()
					local p2 = myPos() or pos
					burst(p2 + Vector3.new(math.random(-4, 4), 3, math.random(-4, 4)), CONFETTI, 70, 35)
				end)
			end
		end
	elseif kind == "hitBy" then
		shake = 1.4
		S.hit:Play()
		flash(Color3.fromRGB(255, 140, 140), 0.12, 0.5)
	elseif kind == "launch" then
		fovKick = 12
		S.swoosh:Play()
	elseif kind == "frozen" and d.by ~= player.UserId then
		shake = 0.6
	end
end)

local lastKey = ""
Remotes:WaitForChild("State").OnClientEvent:Connect(function(s)
	if type(s) ~= "table" then
		return
	end
	racing = s.racing == true and s.state == "racing" and not s.finished
	if s.state == "racing" and s.racing and lastKey ~= "go" then
		lastKey = "go"
		S.go:Play()
		fovKick = 14
		shake = 0.5
		local pos = myPos()
		if pos then
			burst(pos + Vector3.new(0, 4, 4), CONFETTI, 60, 30)
		end
	elseif s.state ~= "racing" then
		lastKey = s.state or ""
	end
end)

-- aterrizajes fuertes, muerte y reaparición
local function hookChar(char)
	local hum = char:WaitForChild("Humanoid", 10)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hum or not hrp then
		return
	end
	flash(Color3.fromRGB(255, 255, 255), 0.25, 0.6) -- aparecer
	local fallSpeed = 0
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Freefall then
			fallSpeed = 0
		elseif new == Enum.HumanoidStateType.Landed then
			if fallSpeed > 55 then
				S.land.PlaybackSpeed = 0.7 + math.random() * 0.15
				S.land:Play()
				shake = math.min(1, fallSpeed / 110)
				burst(hrp.Position - Vector3.new(0, 2.6, 0), { Color3.fromRGB(230, 220, 200), Color3.fromRGB(200, 190, 170) }, 18, 10)
			end
		end
	end)
	local conn
	conn = RunService.Heartbeat:Connect(function()
		if not hrp.Parent then
			conn:Disconnect()
			return
		end
		local vy = -hrp.AssemblyLinearVelocity.Y
		if vy > fallSpeed then
			fallSpeed = vy
		end
	end)
	hum.Died:Connect(function()
		cc.TintColor = Color3.fromRGB(120, 80, 90)
		cc.Brightness = -0.1
		TweenService:Create(cc, TweenInfo.new(2.5), { TintColor = Color3.new(1, 1, 1), Brightness = 0 }):Play()
		shake = 0.8
	end)
end
player.CharacterAdded:Connect(hookChar)
if player.Character then
	task.spawn(hookChar, player.Character)
end
