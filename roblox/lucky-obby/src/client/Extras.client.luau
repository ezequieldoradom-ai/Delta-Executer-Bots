-- Lucky Obby Race — efectos extra en tu pantalla (Shadow)
--   · Las cajas lucky del recorrido giran y flotan; al cogerlas estallan en chispas.
--   · Cuenta atrás: la cámara vuela desde la meta hasta tu sitio en la salida enseñando el recorrido.
--   · Meta: lluvia de confeti a tu alrededor y golpe de cámara.
--   · Nuevo récord: cartel grande con tu tiempo.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Locale = require(ReplicatedStorage.Shared:WaitForChild("Locale"))
pcall(function()
	Locale.detect(player.LocaleId)
end)
local es = function()
	return Locale.lang() == "es"
end

local RAINBOW = {
	Color3.fromRGB(255, 80, 90), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 230, 70),
	Color3.fromRGB(90, 220, 110), Color3.fromRGB(70, 170, 255), Color3.fromRGB(170, 100, 255),
}

-- CAJAS QUE GIRAN ------------------------------------------------------------
RunService.RenderStepped:Connect(function()
	local t = os.clock()
	for _, b in ipairs(CollectionService:GetTagged("LuckyBox")) do
		local base = b:GetAttribute("BaseCF")
		if typeof(base) == "CFrame" then
			local ph = base.Position.Z * 0.13 + base.Position.X
			b.CFrame = base * CFrame.new(0, math.sin(t * 2 + ph) * 0.5, 0) * CFrame.Angles(0, t * 1.6 + ph, math.rad(12))
		end
	end
end)

-- estallido de chispas en un punto
local function burst(pos, colors, n, speed)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
	p.Size = Vector3.new(1, 1, 1)
	p.CFrame = CFrame.new(pos)
	p.Parent = workspace.CurrentCamera
	local kp = {}
	for i, c in ipairs(colors) do
		kp[i] = ColorSequenceKeypoint.new((i - 1) / math.max(1, #colors - 1), c)
	end
	if #kp == 1 then
		kp[2] = ColorSequenceKeypoint.new(1, colors[1])
	end
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.6, 1.4)
	pe.Speed = NumberRange.new(speed * 0.5, speed)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.Acceleration = Vector3.new(0, -18, 0)
	pe.LightEmission = 1
	pe.Rotation = NumberRange.new(0, 360)
	pe.RotSpeed = NumberRange.new(-200, 200)
	pe.Color = ColorSequence.new(kp)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
	pe.Parent = p
	pe:Emit(n)
	task.delay(2, function()
		p:Destroy()
	end)
end

-- CARTEL GRANDE (récord) -----------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "ExtrasFx"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 6
gui.Parent = player:WaitForChild("PlayerGui")
local banner = Instance.new("TextLabel")
banner.AnchorPoint = Vector2.new(0.5, 0.5)
banner.Position = UDim2.fromScale(0.5, 0.72)
banner.Size = UDim2.fromScale(0.7, 0.1)
banner.BackgroundTransparency = 1
banner.Font = Enum.Font.LuckiestGuy
banner.TextScaled = true
banner.TextColor3 = Color3.new(1, 1, 1)
banner.TextStrokeTransparency = 0.2
banner.TextTransparency = 1
banner.Parent = gui
local bgrad = Instance.new("UIGradient")
bgrad.Color = ColorSequence.new(Color3.fromRGB(140, 240, 255), Color3.fromRGB(255, 230, 120))
bgrad.Parent = banner
local bscale = Instance.new("UIScale")
bscale.Parent = banner

local function fmtTime(t)
	return string.format("%d:%05.2f", math.floor(t / 60), t % 60)
end

local function showBanner(text, secs)
	banner.Text = text
	bscale.Scale = 2
	banner.TextTransparency = 1
	TweenService:Create(bscale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	TweenService:Create(banner, TweenInfo.new(0.3), { TextTransparency = 0 }):Play()
	task.delay(secs, function()
		TweenService:Create(banner, TweenInfo.new(0.6), { TextTransparency = 1 }):Play()
	end)
end

-- VUELO DE CÁMARA EN LA CUENTA ATRÁS -----------------------------------------
local flying = false
local function flyover(seconds)
	local course = workspace:FindFirstChild("Course")
	local cam = workspace.CurrentCamera
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if flying or not course or not hrp then
		return
	end
	flying = true
	local y = Config.COURSE.START.Y
	local z1 = course:GetAttribute("FinishZ") or (Config.COURSE.START.Z + 600)
	local z0 = hrp.Position.Z
	cam.CameraType = Enum.CameraType.Scriptable
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / seconds, 0, 1)
		local e = 1 - (1 - a) ^ 3 -- rápido al principio, frena al llegar
		local z = z1 + (z0 - z1) * e
		local h = 45 * (1 - e) + 9 * e
		local side = 30 * (1 - e)
		local pos = Vector3.new(side, y + h, z - 14 - 30 * (1 - e))
		local look = Vector3.new(0, y + 2, z + 30 * (1 - e) + 6)
		cam.CFrame = CFrame.lookAt(pos, look)
		if a >= 1 then
			conn:Disconnect()
			cam.CameraType = Enum.CameraType.Custom
			flying = false
		end
	end)
end

-- BOTÓN "ENTRAR A LA CARRERA" (fase de inscripción) -----------------------------
-- Arriba, bajo el marcador: pequeño, con letra de cómic (Bangers), degradado dorado que se mueve,
-- borde arcoíris, brillo que lo recorre y la cuenta atrás en una pastilla a la derecha.
local BANGERS = Font.new("rbxasset://fonts/families/Bangers.json", Enum.FontWeight.Regular)
local joinBtn = Instance.new("TextButton")
joinBtn.Name = "JoinRace"
joinBtn.AnchorPoint = Vector2.new(0.5, 0)
joinBtn.Position = UDim2.new(0.5, 0, 0, 122)
joinBtn.Size = UDim2.fromOffset(250, 44)
joinBtn.BackgroundColor3 = Color3.new(1, 1, 1)
joinBtn.Text = ""
joinBtn.AutoButtonColor = false
joinBtn.ClipsDescendants = true
joinBtn.Visible = false
joinBtn.Parent = gui
Instance.new("UICorner", joinBtn).CornerRadius = UDim.new(1, 0)
local joinBg = Instance.new("UIGradient")
joinBg.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 40)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 40)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 40)),
})
joinBg.Parent = joinBtn
local joinStroke = Instance.new("UIStroke")
joinStroke.Thickness = 3
joinStroke.Color = Color3.new(1, 1, 1)
joinStroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
joinStroke.Parent = joinBtn
local joinText = Instance.new("TextLabel")
joinText.BackgroundTransparency = 1
joinText.Position = UDim2.fromOffset(14, 3)
joinText.Size = UDim2.new(1, -62, 1, -6)
joinText.FontFace = BANGERS
joinText.TextScaled = true
joinText.TextColor3 = Color3.new(1, 1, 1)
joinText.TextStrokeTransparency = 0
joinText.TextStrokeColor3 = Color3.fromRGB(120, 30, 0)
joinText.ZIndex = 3
joinText.Parent = joinBtn
local joinTextGrad = Instance.new("UIGradient")
joinTextGrad.Rotation = 90
joinTextGrad.Color = ColorSequence.new(Color3.new(1, 1, 1), Color3.fromRGB(255, 240, 150))
joinTextGrad.Parent = joinText
local joinPill = Instance.new("TextLabel")
joinPill.AnchorPoint = Vector2.new(1, 0.5)
joinPill.Position = UDim2.new(1, -5, 0.5, 0)
joinPill.Size = UDim2.fromOffset(36, 34)
joinPill.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
joinPill.FontFace = BANGERS
joinPill.TextScaled = true
joinPill.TextColor3 = Color3.fromRGB(255, 230, 90)
joinPill.ZIndex = 3
joinPill.Parent = joinBtn
Instance.new("UICorner", joinPill).CornerRadius = UDim.new(1, 0)
local shine = Instance.new("Frame")
shine.Size = UDim2.new(0, 26, 2, 0)
shine.AnchorPoint = Vector2.new(0.5, 0.5)
shine.Position = UDim2.fromScale(-0.2, 0.5)
shine.Rotation = 20
shine.BackgroundColor3 = Color3.new(1, 1, 1)
shine.BackgroundTransparency = 0.45
shine.BorderSizePixel = 0
shine.ZIndex = 2
shine.Parent = joinBtn
local joinScale = Instance.new("UIScale")
joinScale.Parent = joinBtn
local joined = false
local function toggleJoin()
	if joinBtn.Visible then
		Remotes.Join:FireServer(not joined)
	end
end
joinBtn.Activated:Connect(toggleJoin)
game:GetService("ContextActionService"):BindAction("LuckyJoin", function(_, st)
	if st == Enum.UserInputState.Begin and joinBtn.Visible then
		toggleJoin()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.ButtonY)
RunService.RenderStepped:Connect(function()
	if joinBtn.Visible then
		local t = os.clock()
		joinScale.Scale = joined and 1 or (1 + math.abs(math.sin(t * 4)) * 0.07)
		joinStroke.Color = joined and Color3.fromRGB(120, 255, 150) or Color3.fromHSV((t * 0.5) % 1, 0.7, 1)
		joinBg.Offset = Vector2.new(math.sin(t * 1.5) * 0.5, 0)
		shine.Position = UDim2.fromScale(((t * 0.8) % 1.6) - 0.3, 0.5)
		shine.Visible = not joined
	end
end)

local lastState = nil
Remotes:WaitForChild("State").OnClientEvent:Connect(function(s)
	if type(s) ~= "table" then
		return
	end
	-- botón de inscripción
	joined = s.joined == true
	joinBtn.Visible = s.state == "joining"
	if joinBtn.Visible then
		local left = math.ceil(s.left or 0)
		joinPill.Text = tostring(left)
		if joined then
			joinBg.Color = ColorSequence.new(Color3.fromRGB(40, 150, 80), Color3.fromRGB(70, 200, 110))
			joinText.Text = es() and "✅ ¡DENTRO! (salir)" or "✅ IN! (leave)"
		else
			joinBg.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 90, 40)),
				ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 200, 40)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 90, 40)),
			})
			joinText.Text = es() and "🏁 ENTRAR A LA CARRERA" or "🏁 JOIN THE RACE"
		end
	end
	if s.state == "countdown" and lastState ~= "countdown" and s.racing then
		local secs = math.max(1.5, (s.left or Config.ROUND.COUNTDOWN) - 1)
		task.spawn(flyover, secs)
	end
	lastState = s.state
end)

-- MENSAJES -------------------------------------------------------------------
Remotes:WaitForChild("Event").OnClientEvent:Connect(function(kind, d)
	d = type(d) == "table" and d or {}
	if kind == "boxPop" and typeof(d.pos) == "Vector3" then
		burst(d.pos, { Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 170, 40) }, 30, 14)
	elseif kind == "finished" then
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if hrp then
			for k = 0, 4 do
				task.delay(k * 0.25, function()
					burst(hrp.Position + Vector3.new(math.random(-6, 6), 8 + k, math.random(-6, 6)), RAINBOW, 60, 22)
				end)
			end
		end
		local cam = workspace.CurrentCamera
		local fov = cam.FieldOfView
		cam.FieldOfView = fov + 18
		TweenService:Create(cam, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { FieldOfView = fov }):Play()
	elseif kind == "record" and type(d.time) == "number" then
		local old = type(d.old) == "number" and d.old > 0 and d.old or nil
		local txt = (es() and "⏱ ¡NUEVO RÉCORD! " or "⏱ NEW RECORD! ") .. fmtTime(d.time)
		if old then
			txt ..= string.format("  (-%.2f s)", old - d.time)
		end
		task.delay(1.5, showBanner, txt, 3.5)
	end
end)
