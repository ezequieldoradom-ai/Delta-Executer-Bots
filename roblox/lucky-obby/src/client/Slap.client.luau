-- Lucky Obby Race — "¿QUIÉN HA SIDO?" en tu pantalla (Shadow). Ver src/server/Slap.luau.
--   · Botón DAR GUANTAZO (E / □ / clic) para los de pie · barra de fuerza con el cuadradito rojo para el que pega
--   · Esquiva de 0,4 s para el sentado: clic en un punto al azar (PC/móvil) o △ ○ ✕ □ al azar (mando)
--   · Panel "¿Quién ha sido?" con los nombres · cámara fija mirando al frente para el sentado
--   · Primer plano del guantazo para todos los de cerca menos el sentado, con sonidos (y meme si es supremo)
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Net = Remotes:WaitForChild("Slap")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Locale = require(ReplicatedStorage.Shared:WaitForChild("Locale"))
pcall(function()
	Locale.detect(player.LocaleId)
end)
local function L(es, en)
	return Locale.lang() == "es" and es or en
end

local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 215, 70)

-- SONIDOS (Config.SLAP_SFX si existe; si no, los de serie de Roblox) ------------------
local SFXID = Config.SLAP_SFX or {}
local function snd(id, vol, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol
	s.PlaybackSpeed = speed or 1
	s.Parent = SoundService
	return s
end
local S = {
	slap = snd(SFXID.slap or "rbxasset://sounds/action_jump_land.mp3", 1, 1.6),
	slapBig = snd(SFXID.slapBig or "rbxasset://sounds/impact_explosion_03.mp3", 0.5, 2.2),
	meme = snd(SFXID.meme or "rbxasset://sounds/oof.ogg", 1, 1),
	boom = snd(SFXID.boom or "rbxasset://sounds/impact_explosion_03.mp3", 0.9, 0.8),
	whoosh = snd(SFXID.whoosh or "rbxasset://sounds/action_jump.mp3", 0.8, 1.8),
	tick = snd("rbxasset://sounds/action_footsteps_plastic.mp3", 0.4, 2),
	ouch = snd(SFXID.ouch or "rbxasset://sounds/ouch.ogg", 1, 1),
	oof = snd(SFXID.oof or "rbxasset://sounds/oof.ogg", 1, 1),
	jump = snd("rbxasset://sounds/action_jump.mp3", 0.9, 0.9),
	land = snd("rbxasset://sounds/action_jump_land.mp3", 1, 0.7),
	swoosh = snd("rbxasset://sounds/action_falling.ogg", 0.5, 1.6),
}
local function play(name, pitch, vol)
	local s = S[name]
	if s then
		if pitch then
			s.PlaybackSpeed = pitch
		end
		if vol then
			s.Volume = vol
		end
		s:Play()
	end
end

-- INTERFAZ ---------------------------------------------------------------------------
local gui = Instance.new("ScreenGui")
gui.Name = "SlapGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")
local uiScale = Instance.new("UIScale")
uiScale.Parent = gui
local function rescale()
	local h = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 720
	uiScale.Scale = math.clamp(h / 760, 0.55, 1)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local function corner(p, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 14)
	c.Parent = p
end
local function stroke(p, col, th)
	local s = Instance.new("UIStroke")
	s.Color = col or WHITE
	s.Thickness = th or 3
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = p
	return s
end
local function text(parent, props)
	local l = Instance.new(props.Button and "TextButton" or "TextLabel")
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.LuckiestGuy
	l.TextScaled = true
	l.TextColor3 = WHITE
	l.TextStrokeTransparency = 0.3
	for k, v in pairs(props) do
		if k ~= "Button" then
			l[k] = v
		end
	end
	l.Parent = parent
	return l
end

-- panel de la mesa (abajo a la izquierda)
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0, 0)
panel.Position = UDim2.new(0, 14, 0, 120) -- arriba a la izquierda (abajo va el panel de estadísticas)
panel.Size = UDim2.fromOffset(300, 92)
panel.BackgroundColor3 = Color3.fromRGB(40, 22, 60)
panel.BackgroundTransparency = 0.15
panel.Visible = false
panel.Parent = gui
corner(panel, 16)
stroke(panel, Color3.fromRGB(255, 120, 200), 3)
local panelTitle = text(panel, { Size = UDim2.new(1, -90, 0, 30), Position = UDim2.fromOffset(10, 6), Text = "🖐️ ¿QUIÉN HA SIDO?", TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD })
local panelInfo = text(panel, { Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 40), Text = "", TextXAlignment = Enum.TextXAlignment.Left, Font = Enum.Font.FredokaOne, TextWrapped = true })
local leaveBtn = text(panel, { Button = true, Size = UDim2.fromOffset(74, 30), Position = UDim2.new(1, -82, 0, 6), Text = L("SALIR", "LEAVE"), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(200, 60, 80) })
corner(leaveBtn, 10)
leaveBtn.Activated:Connect(function()
	Net:FireServer("leave")
end)

-- botón DAR GUANTAZO
local slapBtn = text(gui, { Button = true, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -120), Size = UDim2.fromOffset(380, 80), Text = "🖐️ " .. L("DAR GUANTAZO", "SLAP!"), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(230, 70, 120), Visible = false })
corner(slapBtn, 22)
local slapStroke = stroke(slapBtn, WHITE, 4)

-- barra de fuerza
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -140)
bar.Size = UDim2.fromOffset(560, 48)
bar.BackgroundColor3 = Color3.fromRGB(25, 20, 35)
bar.Visible = false
bar.Parent = gui
corner(bar, 12)
stroke(bar, WHITE, 4)
local barGrad = Instance.new("Frame")
barGrad.Size = UDim2.new(1, -8, 1, -8)
barGrad.Position = UDim2.fromOffset(4, 4)
barGrad.BackgroundColor3 = WHITE
barGrad.Parent = bar
corner(barGrad, 9)
local g = Instance.new("UIGradient")
g.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(90, 220, 120)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(255, 120, 40)),
})
g.Parent = barGrad
local red = Instance.new("Frame")
red.AnchorPoint = Vector2.new(0.5, 0.5)
red.BackgroundColor3 = Color3.fromRGB(230, 20, 30)
red.Size = UDim2.fromScale(0.07, 1.15)
red.Position = UDim2.fromScale(0.5, 0.5)
red.ZIndex = 2
red.Parent = barGrad
stroke(red, Color3.fromRGB(80, 0, 0), 2)
local marker = Instance.new("Frame")
marker.AnchorPoint = Vector2.new(0.5, 0.5)
marker.BackgroundColor3 = WHITE
marker.Size = UDim2.new(0, 8, 1.7, 0)
marker.Position = UDim2.fromScale(0, 0.5)
marker.ZIndex = 3
marker.Parent = barGrad
corner(marker, 4)
stroke(marker, Color3.new(0, 0, 0), 2)
local barTitle = text(bar, { AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 0, -8), Size = UDim2.fromOffset(560, 40), Text = L("💪 ¡PÁRALA! (el rojo = 💀 SUPREMO)", "💪 STOP IT! (red = 💀 SUPREME)") })
local _ = barTitle
-- capa invisible a pantalla completa para parar la barra con un toque/clic
local tapGui = Instance.new("ScreenGui")
tapGui.Name = "SlapTap"
tapGui.ResetOnSpawn = false
tapGui.IgnoreGuiInset = true
tapGui.DisplayOrder = 0
tapGui.Parent = gui.Parent
local tapLayer = text(tapGui, { Button = true, Size = UDim2.fromScale(1, 1), Text = "", Visible = false })

-- esquiva
local dodgeBtn = text(gui, { Button = true, AnchorPoint = Vector2.new(0.5, 0.5), Size = UDim2.fromOffset(130, 130), Text = "💨", BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(255, 70, 90), Visible = false, ZIndex = 10 })
corner(dodgeBtn, 65)
stroke(dodgeBtn, WHITE, 5)
local dodgeLabel = text(dodgeBtn, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 1, 4), Size = UDim2.fromOffset(200, 34), Text = L("¡ESQUIVA!", "DODGE!"), ZIndex = 10 })
local _2 = dodgeLabel

-- ¿quién ha sido?
local guessPanel = Instance.new("Frame")
guessPanel.AnchorPoint = Vector2.new(0.5, 0.5)
guessPanel.Position = UDim2.fromScale(0.5, 0.55)
guessPanel.Size = UDim2.fromOffset(600, 330)
guessPanel.BackgroundColor3 = Color3.fromRGB(40, 22, 60)
guessPanel.BackgroundTransparency = 0.05
guessPanel.Visible = false
guessPanel.Parent = gui
corner(guessPanel, 20)
stroke(guessPanel, GOLD, 4)
local guessTitle = text(guessPanel, { Size = UDim2.new(1, -20, 0, 54), Position = UDim2.fromOffset(10, 8), Text = L("🤔 ¿QUIÉN HA SIDO?", "🤔 WHO WAS IT?"), TextColor3 = GOLD })
local guessList = Instance.new("Frame")
guessList.BackgroundTransparency = 1
guessList.Position = UDim2.fromOffset(20, 70)
guessList.Size = UDim2.new(1, -40, 1, -90)
guessList.Parent = guessPanel
local layout = Instance.new("UIGridLayout")
layout.CellSize = UDim2.fromOffset(160, 210)
layout.CellPadding = UDim2.fromOffset(16, 10)
layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
layout.SortOrder = Enum.SortOrder.LayoutOrder
layout.Parent = guessList
local gGrad = Instance.new("UIGradient")
gGrad.Rotation = 90
gGrad.Color = ColorSequence.new(Color3.fromRGB(90, 55, 150), Color3.fromRGB(30, 18, 50))
gGrad.Parent = guessPanel

-- foto de perfil (los bots no tienen: robot)
local function headshot(parent, userId, size)
	local frame = Instance.new("Frame")
	frame.Size = UDim2.fromOffset(size, size)
	frame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	frame.Parent = parent
	Instance.new("UICorner", frame).CornerRadius = UDim.new(1, 0)
	local st = Instance.new("UIStroke")
	st.Thickness = 3
	st.Color = GOLD
	st.Parent = frame
	if userId and userId > 0 then
		local img = Instance.new("ImageLabel")
		img.BackgroundTransparency = 1
		img.Size = UDim2.fromScale(1, 1)
		img.Image = string.format("rbxthumb://type=AvatarHeadShot&id=%d&w=150&h=150", userId)
		img.Parent = frame
		Instance.new("UICorner", img).CornerRadius = UDim.new(1, 0)
	else
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.TextScaled = true
		l.Text = "🤖"
		l.Parent = frame
	end
	return frame, st
end

-- REVELACIÓN para toda la mesa: "X dice que fue... Y" → ✅ / ❌
local reveal = Instance.new("Frame")
reveal.AnchorPoint = Vector2.new(0.5, 0)
reveal.Position = UDim2.new(0.5, 0, 0, 150)
reveal.Size = UDim2.fromOffset(560, 150)
reveal.BackgroundColor3 = Color3.fromRGB(30, 20, 50)
reveal.BackgroundTransparency = 0.08
reveal.Visible = false
reveal.ZIndex = 12
reveal.Parent = gui
corner(reveal, 22)
local revealStroke = stroke(reveal, GOLD, 4)
local revealText = text(reveal, { Position = UDim2.fromOffset(150, 14), Size = UDim2.new(1, -165, 0, 46), Text = "", ZIndex = 13, TextXAlignment = Enum.TextXAlignment.Left })
local revealName = text(reveal, { Position = UDim2.fromOffset(150, 60), Size = UDim2.new(1, -165, 0, 54), Text = "", ZIndex = 13, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left })
local revealVerdict = text(reveal, { Position = UDim2.fromOffset(150, 112), Size = UDim2.new(1, -165, 0, 30), Text = "", ZIndex = 13, Font = Enum.Font.FredokaOne, TextXAlignment = Enum.TextXAlignment.Left })
local revealPic = nil
local revealScale = Instance.new("UIScale")
revealScale.Parent = reveal
local revealId = 0

-- textos grandes
local big = text(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.28), Size = UDim2.fromOffset(900, 110), Text = "", TextTransparency = 1, TextStrokeTransparency = 1, ZIndex = 9 })
local bigScale = Instance.new("UIScale")
bigScale.Parent = big
local function shout(t, color, secs)
	big.Text = t
	big.TextColor3 = color or WHITE
	big.TextTransparency, big.TextStrokeTransparency = 0, 0.2
	bigScale.Scale = 1.8
	TweenService:Create(bigScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local my = t
	task.delay(secs or 1.5, function()
		if big.Text == my then
			TweenService:Create(big, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
local msgLabel = text(gui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 208), Size = UDim2.fromOffset(760, 36), Text = "", TextTransparency = 1, TextStrokeTransparency = 1, Font = Enum.Font.FredokaOne })
local function msg(t)
	msgLabel.Text = t
	msgLabel.TextTransparency, msgLabel.TextStrokeTransparency = 0, 0.3
	local my = t
	task.delay(3.5, function()
		if msgLabel.Text == my then
			TweenService:Create(msgLabel, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
local flash = Instance.new("Frame")
flash.Size = UDim2.fromScale(1, 1)
flash.BackgroundColor3 = WHITE
flash.BackgroundTransparency = 1
flash.ZIndex = 8
flash.Parent = gui
local function doFlash(color, alpha)
	flash.BackgroundColor3 = color
	flash.BackgroundTransparency = alpha
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
end

-- ESTADO ------------------------------------------------------------------------------
local station = nil -- info de mi mesa (o nil)
local charging = nil -- { t0, period }
local cine = false -- primer plano en curso
local punch = Vector3.zero -- golpe de cámara (pitch, yaw, roll) que se va calmando
local shake = 0

local function amSeated()
	return station and station.seated == player.UserId and station.phase ~= "idle"
end

local function lockSeat()
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hum then
		hum:SetStateEnabled(Enum.HumanoidStateType.Jumping, not amSeated())
	end
	local plaza = workspace:FindFirstChild("SlapPlaza")
	if plaza then
		for _, pp in ipairs(plaza:GetDescendants()) do
			if pp:IsA("ProximityPrompt") then
				pp.Enabled = station == nil
			end
		end
	end
end
local function updateUI()
	lockSeat()
	panel.Visible = station ~= nil
	if not station then
		slapBtn.Visible = false
		return
	end
	local n = #(station.members or {})
	local seatedName = "?"
	for _, m in ipairs(station.members or {}) do
		if m.id == station.seated then
			seatedName = m.name
		end
	end
	panelTitle.Text = string.format("🖐️ %s %d · %d/%d", L("MESA", "TABLE"), station.id or 0, n, station.max or 4)
	if station.phase == "idle" then
		panelInfo.Text = L("Esperando a otro jugador…", "Waiting for another player…")
	elseif amSeated() then
		panelInfo.Text = L("Estás sentado. ¡Alguien te va a dar!", "You're seated. Someone's going to slap you!")
	elseif station.phase == "guessing" then
		panelInfo.Text = L("🤔 ", "🤔 ") .. seatedName .. L(" está adivinando…", " is guessing…")
	elseif station.slapper == player.UserId then
		panelInfo.Text = L("¡Te toca pegar! Para la barra", "Your turn! Stop the bar")
	else
		panelInfo.Text = L("Sentado: ", "Seated: ") .. seatedName
	end
	slapBtn.Visible = station.phase == "waiting" and not amSeated() and charging == nil
end

-- CÁMARA -----------------------------------------------------------------------------
local camLocked = false
RunService:BindToRenderStep("SlapCamera", Enum.RenderPriority.Camera.Value + 1, function(dt)
	local cam = workspace.CurrentCamera
	if cine then
		return
	end
	if amSeated() then
		local char = player.Character
		local head = char and char:FindFirstChild("Head")
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		if head and hrp then
			camLocked = true
			cam.CameraType = Enum.CameraType.Scriptable
			local look = hrp.CFrame.LookVector
			local s = shake > 0 and Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * shake or Vector3.zero
			cam.CFrame = CFrame.lookAt(head.Position + look * 0.7 + s, head.Position + look * 12 + Vector3.new(0, -1.5, 0)) * CFrame.Angles(punch.X, punch.Y, punch.Z)
			cam.FieldOfView = 70 + punch.Magnitude * 25
		end
	elseif camLocked then
		camLocked = false
		cam.CameraType = Enum.CameraType.Custom
	end
	if shake > 0 then
		shake = math.max(0, shake - dt * 2.5)
	end
	punch = punch * math.max(0, 1 - dt * 5) -- vuelve al centro
end)

-- BARRA DE FUERZA --------------------------------------------------------------------
local function tri(x)
	x = x % 2
	return x <= 1 and x or 2 - x
end
local function barPos()
	return charging and tri((os.clock() - charging.t0) / charging.period) or 0
end
local function stopBar()
	if not charging then
		return
	end
	local pos = barPos()
	charging = nil
	bar.Visible = false
	tapLayer.Visible = false
	Net:FireServer("stop", pos)
	play("whoosh", 1.2)
	updateUI()
end
tapLayer.Activated:Connect(stopBar)
RunService.RenderStepped:Connect(function()
	if charging then
		marker.Position = UDim2.fromScale(barPos(), 0.5)
	end
	if slapBtn.Visible then
		local t = os.clock()
		slapStroke.Color = Color3.fromHSV((t * 0.5) % 1, 0.5, 1)
		slapBtn.Rotation = math.sin(t * 8) * 2
	end
end)

-- acción principal (E / □ / R2): pegar o parar la barra
ContextActionService:BindActionAtPriority("SlapAct", function(_, st)
	if st ~= Enum.UserInputState.Begin then
		return Enum.ContextActionResult.Pass
	end
	if charging then
		stopBar()
		return Enum.ContextActionResult.Sink
	elseif slapBtn.Visible then
		Net:FireServer("slap")
		slapBtn.Visible = false
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, 3000, Enum.KeyCode.E, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonR2)
slapBtn.Activated:Connect(function()
	Net:FireServer("slap")
	slapBtn.Visible = false
end)

-- ESQUIVA ----------------------------------------------------------------------------
local PADKEYS = {
	{ key = Enum.KeyCode.ButtonY, sym = "△", color = Color3.fromRGB(60, 210, 160) },
	{ key = Enum.KeyCode.ButtonB, sym = "○", color = Color3.fromRGB(255, 80, 90) },
	{ key = Enum.KeyCode.ButtonA, sym = "✕", color = Color3.fromRGB(90, 150, 255) },
	{ key = Enum.KeyCode.ButtonX, sym = "□", color = Color3.fromRGB(240, 120, 220) },
}
local dodging = nil -- { t0, key, done }
local dodgeImg = Instance.new("ImageLabel")
dodgeImg.BackgroundTransparency = 1
dodgeImg.AnchorPoint = Vector2.new(0.5, 0.5)
dodgeImg.Position = UDim2.fromScale(0.5, 0.5)
dodgeImg.Size = UDim2.fromScale(0.7, 0.7)
dodgeImg.ZIndex = 11
dodgeImg.Visible = false
dodgeImg.Parent = dodgeBtn
local function finishDodge(ok)
	if not dodging or dodging.done then
		return
	end
	dodging.done = true
	dodgeBtn.Visible = false
	ContextActionService:UnbindAction("SlapDodge")
	Net:FireServer("dodge", ok and dodging.key or 0)
	if ok then
		play("whoosh", 1.5)
	end
end
dodgeBtn.Activated:Connect(function()
	finishDodge(dodging ~= nil and os.clock() - dodging.t0 <= dodging.window)
end)
local function startDodge(d)
	local window = tonumber(d.window) or 0.4
	dodging = { t0 = os.clock(), key = d.key or 1, window = window, done = false }
	local lastType = UserInputService:GetLastInputType()
	local pad = lastType.Name:find("Gamepad") ~= nil
	local k = PADKEYS[dodging.key] or PADKEYS[1]
	dodgeBtn.Visible = true
	dodgeBtn.Size = UDim2.fromOffset(130, 130)
	if pad then
		dodgeBtn.Position = UDim2.fromScale(0.5, 0.5)
		dodgeBtn.Text = k.sym
		dodgeBtn.BackgroundColor3 = k.color
		local img = ""
		pcall(function()
			img = UserInputService:GetImageForKeyCode(k.key)
		end)
		dodgeImg.Image = img
		dodgeImg.Visible = img ~= ""
		if img ~= "" then
			dodgeBtn.Text = ""
		end
		ContextActionService:BindActionAtPriority("SlapDodge", function(_, st, input)
			if st == Enum.UserInputState.Begin then
				finishDodge(input.KeyCode == k.key and os.clock() - dodging.t0 <= window)
			end
			return Enum.ContextActionResult.Sink
		end, false, 4000, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonX)
	else
		dodgeBtn.Position = UDim2.fromScale(0.12 + math.random() * 0.76, 0.18 + math.random() * 0.64)
		dodgeBtn.Text = "💨"
		dodgeImg.Visible = false
		dodgeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default -- por si el ratón está bloqueado (shift-lock)
	end
	TweenService:Create(dodgeBtn, TweenInfo.new(window, Enum.EasingStyle.Linear), { Size = UDim2.fromOffset(70, 70) }):Play()
	local my = dodging
	task.delay(window, function()
		if dodging == my then
			finishDodge(false)
		end
	end)
end

-- ADIVINAR ---------------------------------------------------------------------------
local function startGuess(d)
	for _, c in ipairs(guessList:GetChildren()) do
		if c:IsA("GuiObject") then
			c:Destroy()
		end
	end
	for i, o in ipairs(d.options or {}) do
		local b = text(guessList, { Button = true, LayoutOrder = i, Text = "", BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(70, 45, 115), AutoButtonColor = true })
		corner(b, 18)
		local bs = stroke(b, WHITE, 2)
		local pic = headshot(b, tonumber(o.id), 110)
		pic.AnchorPoint = Vector2.new(0.5, 0)
		pic.Position = UDim2.new(0.5, 0, 0, 14)
		text(b, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 132), Size = UDim2.new(1, -14, 0, 34), Text = tostring(o.name) })
		text(b, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 168), Size = UDim2.new(1, -30, 0, 26), Text = L("👉 ¡FUE ÉL!", "👉 IT WAS THEM!"), TextColor3 = GOLD, Font = Enum.Font.FredokaOne })
		local sc = Instance.new("UIScale")
		sc.Parent = b
		b.MouseEnter:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.15), { Scale = 1.06 }):Play()
			bs.Color = GOLD
			play("tick", 2.2)
		end)
		b.MouseLeave:Connect(function()
			TweenService:Create(sc, TweenInfo.new(0.15), { Scale = 1 }):Play()
			bs.Color = WHITE
		end)
		-- entrada en cascada
		sc.Scale = 0.3
		task.delay(0.06 * i, function()
			TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		end)
		b.Activated:Connect(function()
			guessPanel.Visible = false
			Net:FireServer("guess", o.id)
		end)
	end
	guessPanel.Visible = true
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	local padKeys = { Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonY }
	local opts = d.options or {}
	if UserInputService.GamepadEnabled then
		for i, b in ipairs(guessList:GetChildren()) do
			local _ = i
			if b:IsA("TextButton") then
				local idx = b.LayoutOrder
				local key = padKeys[idx]
				local ok, img = pcall(function()
					return UserInputService:GetImageForKeyCode(key)
				end)
				if key and ok and img ~= "" then
					local icon = Instance.new("ImageLabel")
					icon.BackgroundTransparency = 1
					icon.Size = UDim2.fromOffset(40, 40)
					icon.Position = UDim2.new(1, -48, 0.5, -20)
					icon.Image = img
					icon.Parent = b
				end
			end
		end
		ContextActionService:BindActionAtPriority("SlapGuess", function(_, st, input)
			if st ~= Enum.UserInputState.Begin then
				return Enum.ContextActionResult.Pass
			end
			local i = table.find(padKeys, input.KeyCode)
			if i and opts[i] and guessPanel.Visible then
				guessPanel.Visible = false
				Net:FireServer("guess", opts[i].id)
				return Enum.ContextActionResult.Sink
			end
			return Enum.ContextActionResult.Pass
		end, false, 4000, table.unpack(padKeys))
	end
	local t0, secs = os.clock(), tonumber(d.time) or 10
	task.spawn(function()
		while guessPanel.Visible and os.clock() - t0 < secs do
			guessTitle.Text = string.format("%s · %d", L("🤔 ¿QUIÉN HA SIDO?", "🤔 WHO WAS IT?"), math.ceil(secs - (os.clock() - t0)))
			task.wait(0.2)
		end
		guessPanel.Visible = false
		ContextActionService:UnbindAction("SlapGuess")
	end)
end

-- EL GUANTAZO (primer plano para los de cerca) ----------------------------------------
local function charOf(userId)
	local p = Players:GetPlayerByUserId(userId or 0)
	return p and p.Character
end
local function soundAt(pos, name, pitch, vol)
	local base = S[name]
	if not base then
		return
	end
	local a = Instance.new("Part")
	a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency = true, false, false, false, 1
	a.Size = Vector3.one
	a.CFrame = CFrame.new(pos)
	a.Parent = workspace.CurrentCamera
	local s = base:Clone()
	s.PlaybackSpeed = pitch or base.PlaybackSpeed
	s.Volume = vol or base.Volume
	s.RollOffMaxDistance = 140
	s.Parent = a
	s:Play()
	task.delay(4, function()
		a:Destroy()
	end)
end

-- CINEMÁTICA DEL SALTO -----------------------------------------------------------------
local bars = {}
for i, y in ipairs({ 0, 1 }) do
	local b = Instance.new("Frame")
	b.AnchorPoint = Vector2.new(0, y)
	b.Position = UDim2.fromScale(0, y)
	b.Size = UDim2.new(1, 0, 0, 0)
	b.BackgroundColor3 = Color3.new(0, 0, 0)
	b.BorderSizePixel = 0
	b.ZIndex = 7
	b.Parent = gui
	bars[i] = b
end
local function letterbox(on)
	for _, b in ipairs(bars) do
		TweenService:Create(b, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, on and 0.11 or 0, 0) }):Play()
	end
end
local STYLE_NAME = {
	clasico = { "🖐️ GUANTAZO CLÁSICO", "🖐️ CLASSIC SLAP" },
	giratorio = { "🌀 GUANTAZO GIRATORIO", "🌀 SPINNING SLAP" },
	voltereta = { "🤸 VOLTERETA MORTAL", "🤸 FLIP SLAP" },
	doble = { "✌️ DOBLE GUANTAZO", "✌️ DOUBLE SLAP" },
	gancho = { "🥊 GANCHO AL CIELO", "🥊 UPPERCUT SLAP" },
	supremo = { "💀 GUANTAZO SUPREMO", "💀 SUPREME SLAP" },
}
local windupConn = nil
local function endWindup()
	if windupConn then
		windupConn:Disconnect()
		windupConn = nil
		letterbox(false)
		local cam = workspace.CurrentCamera
		cam.FieldOfView = 70
		cam.CameraType = Enum.CameraType.Custom
		cine = false
	end
end
local function onWindup(d)
	if cine or not station or station.id ~= d.station or (dodging and not dodging.done) then
		return
	end
	local sChar = typeof(d.slapperChar) == "Instance" and d.slapperChar
	local vChar = typeof(d.victimChar) == "Instance" and d.victimChar
	local sh = sChar and sChar:FindFirstChild("HumanoidRootPart")
	local vh = vChar and vChar:FindFirstChild("Head")
	if not sh or not vh then
		return
	end
	local names = STYLE_NAME[d.style] or STYLE_NAME.clasico
	shout(L(names[1], names[2]), d.style == "supremo" and Color3.fromRGB(255, 70, 70) or GOLD, 1.2)
	soundAt(sh.Position, "jump", 0.8, 1)
	soundAt(sh.Position, "swoosh", 1.2 + (tonumber(d.power) or 0.5) * 0.6, 0.6)
	cine = true
	letterbox(true)
	local cam = workspace.CurrentCamera
	cam.CameraType = Enum.CameraType.Scriptable
	local air = math.max(0.5, tonumber(d.air) or 1)
	local seatCF = typeof(d.seatCF) == "CFrame" and d.seatCF or CFrame.new(vh.Position)
	local t0 = os.clock()
	local side = math.random() < 0.5 and -1 or 1
	-- tres planos según el estilo: contrapicado girando, lateral y cenital
	local shot = math.random(1, 3)
	windupConn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / air, 0, 1)
		local target = sh.Parent and sh.Position or vh.Position
		local mid = target:Lerp(vh.Position, 0.35)
		local pos
		if shot == 1 then -- contrapicado que gira alrededor del que salta
			local ang = side * (a * 2.4) + 0.6
			pos = target + Vector3.new(math.cos(ang) * 11, -3 + a * 2, math.sin(ang) * 11)
		elseif shot == 2 then -- lateral, se acerca
			pos = mid + seatCF.RightVector * side * (16 - a * 7) + Vector3.new(0, 3, 0)
		else -- desde arriba, bajando con él
			pos = target + seatCF.LookVector * -6 + Vector3.new(0, 12 - a * 6, 0)
		end
		cam.CFrame = CFrame.lookAt(pos, mid)
		cam.FieldOfView = 62 - a * 18
		if a >= 1 then
			endWindup()
		end
	end)
end

local function onHit(d)
	endWindup()
	local victimChar = (typeof(d.victimChar) == "Instance" and d.victimChar) or charOf(d.victim)
	local head = victimChar and victimChar:FindFirstChild("Head")
	local hrp = victimChar and victimChar:FindFirstChild("HumanoidRootPart")
	local isVictim = d.victim == player.UserId
	local power = tonumber(d.power) or 0.5
	if d.dodged then
		if head then
			soundAt(head.Position, "whoosh", 1.3, 1)
		end
		shout(L("💨 ¡ESQUIVADO!", "💨 DODGED!"), Color3.fromRGB(140, 230, 255), 1.4)
		return
	end
	-- sonido del guantazo (más fuerte = más grave y alto)
	if head then
		soundAt(head.Position, "slap", 1.9 - power * 0.6, 0.6 + power * 0.6)
		if power > 0.6 or d.supreme then
			soundAt(head.Position, "slapBig", 2.4 - power, 0.3 + power * 0.4)
		end
		if d.supreme then
			soundAt(head.Position, "meme", 1, 1)
			task.delay(0.15, function()
				soundAt(head.Position, "boom", 0.8, 1)
			end)
		end
	end
	if head and not d.supreme then
		task.delay(0.08, function()
			soundAt(head.Position, math.random() < 0.5 and "ouch" or "oof", 0.85 + math.random() * 0.5, 0.9)
		end)
	end
	if d.style == "doble" and head then
		task.delay(0.16, function()
			soundAt(head.Position, "slap", 1.5, 0.9)
		end)
	end
	if isVictim then
		-- el sentado no ve el primer plano: solo el golpe, que le gira la cámara de golpe
		shake = 0.6 + power * 1.4
		local side = math.random() < 0.5 and -1 or 1
		if d.style == "gancho" then
			punch = Vector3.new(0.35 + power * 0.4, 0, side * 0.15)
		elseif d.supreme then
			punch = Vector3.new(0.3, side * 1.1, side * 0.6)
		else
			punch = Vector3.new(0.05, side * (0.25 + power * 0.55), side * (0.15 + power * 0.3))
		end
		doFlash(d.supreme and Color3.fromRGB(255, 30, 30) or WHITE, 0.25)
		shout(d.supreme and L("💀 ¡GUANTAZO SUPREMO!", "💀 SUPREME SLAP!") or "💥 ¡PAM!", d.supreme and Color3.fromRGB(255, 70, 70) or GOLD, 1.4)
		return
	end
	-- primer plano: solo para los de esta mesa que no están ocupados (no se roba la cámara a nadie más)
	if not head or cine or not station or station.id ~= d.station or charging or (dodging and not dodging.done) then
		return
	end
	local myChar = player.Character
	local myHrp = myChar and myChar:FindFirstChild("HumanoidRootPart")
	if myHrp and (myHrp.Position - head.Position).Magnitude > 110 then
		return
	end
	cine = true
	local cam = workspace.CurrentCamera
	local oldType, oldFov = cam.CameraType, cam.FieldOfView
	cam.CameraType = Enum.CameraType.Scriptable
	local seatCF = typeof(d.seatCF) == "CFrame" and d.seatCF or (hrp and hrp.CFrame or CFrame.new(head.Position))
	local fwd, right = seatCF.LookVector, seatCF.RightVector
	local h0 = head.Position
	doFlash(WHITE, d.supreme and 0.1 or 0.45)
	shout(d.supreme and L("💀 ¡GUANTAZO SUPREMO!", "💀 SUPREME SLAP!") or string.format("💥 ¡PAM! %d%%", math.floor(power * 100)), d.supreme and Color3.fromRGB(255, 70, 70) or GOLD, d.supreme and 2.2 or 1.3)
	local secs = d.supreme and 2.4 or 1.5
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local a = math.clamp((os.clock() - t0) / secs, 0, 1)
		local target = h0
		if d.supreme and hrp and hrp.Parent then
			target = hrp.Position -- seguimos al que sale volando
		end
		local dist = d.supreme and (8 + a * 18) or (9 - a * 2.5)
		local jitter = a < 0.25 and Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * (0.25 + power * 0.6) or Vector3.zero
		cam.CFrame = CFrame.lookAt(target + fwd * dist * 0.55 + right * (dist * 0.85) + Vector3.new(0, 2.2, 0) + jitter, target - fwd * 1.6 + Vector3.new(0, -0.4, 0))
		cam.FieldOfView = 55 - a * 8
		if a >= 1 then
			conn:Disconnect()
			cam.FieldOfView = oldFov
			cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
			cine = false
		end
	end)
end

-- ANIMACIONES (brazo del que pega y cabeza del que recibe; se aplican sobre la animación normal) ----
local POSES = {
	windup = CFrame.Angles(math.rad(35), math.rad(-95), math.rad(150)),
	strike = CFrame.Angles(math.rad(-10), math.rad(75), math.rad(80)),
	backhand = CFrame.Angles(math.rad(-5), math.rad(-60), math.rad(95)),
	uppercut = CFrame.Angles(math.rad(-150), math.rad(10), math.rad(20)),
	rest = CFrame.new(),
}
local anims = {} -- [userId .. kind] = { who, kind, from, to, t0, dur, style }
local function jointOf(char, kind)
	if kind == "root" then
		local lt = char:FindFirstChild("LowerTorso")
		local j = lt and lt:FindFirstChild("Root")
		if not j then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			j = hrp and hrp:FindFirstChild("RootJoint")
		end
		return j
	end
	if kind == "waist" then
		local ut = char:FindFirstChild("UpperTorso")
		local j = ut and ut:FindFirstChild("Waist")
		if not j then
			local hrp = char:FindFirstChild("HumanoidRootPart")
			j = hrp and hrp:FindFirstChild("RootJoint")
		end
		return j
	end
	if kind == "larm" then
		local arm = char:FindFirstChild("LeftUpperArm")
		local j = arm and arm:FindFirstChild("LeftShoulder")
		if not j then
			local torso = char:FindFirstChild("Torso")
			j = torso and torso:FindFirstChild("Left Shoulder")
		end
		return j
	end
	if kind == "rarm" then
		kind = "arm"
	end
	if kind == "arm" then
		local arm = char:FindFirstChild("RightUpperArm")
		local j = arm and arm:FindFirstChild("RightShoulder")
		if not j then
			local torso = char:FindFirstChild("Torso")
			j = torso and torso:FindFirstChild("Right Shoulder")
		end
		return j
	end
	local head = char:FindFirstChild("Head")
	local j = head and head:FindFirstChild("Neck")
	if not j then
		local torso = char:FindFirstChild("Torso")
		j = torso and torso:FindFirstChild("Neck")
	end
	return j
end
local function startAnim(d)
	local who = tonumber(d.who) or 0
	if typeof(d.char) == "Instance" then
		who = d.char -- clave: el propio personaje
	end
	if d.pose == "spin" or d.pose == "flip" then -- giro de todo el cuerpo durante el salto
		local turns = d.pose == "spin" and 2 or 1
		anims[tostring(who) .. "root"] = { who = who, kind = "root", spin = d.pose, turns = turns, t0 = os.clock(), dur = math.max(0.3, tonumber(d.time) or 1) }
		return
	end
	if d.pose == "react" then -- el sentado: se dobla al lado del golpe, agita los brazos y rebota
		local pw = tonumber(d.power) or 0.5
		local side = (d.side == -1) and -1 or 1
		local now = os.clock()
		local k = tostring(who)
		anims[k .. "waist"] = { who = who, kind = "waist", from = CFrame.Angles(math.rad(-10 - 20 * pw), side * math.rad(35 + 40 * pw), side * math.rad(18 + 25 * pw)), to = CFrame.new(), t0 = now, dur = 1.1, style = Enum.EasingStyle.Elastic }
		anims[k .. "larm"] = { who = who, kind = "larm", from = CFrame.Angles(math.rad(-60 - 50 * pw), 0, math.rad(-40 - 60 * pw)), to = CFrame.new(), t0 = now, dur = 1.0, style = Enum.EasingStyle.Elastic }
		anims[k .. "rarm2"] = { who = who, kind = "rarm", from = CFrame.Angles(math.rad(-60 - 50 * pw), 0, math.rad(40 + 60 * pw)), to = CFrame.new(), t0 = now, dur = 1.0, style = Enum.EasingStyle.Elastic }
		anims[k .. "neck"] = { who = who, kind = "neck", from = CFrame.Angles(math.rad(-20 - 30 * pw), side * math.rad(50 * pw + 15), side * math.rad(15 * pw)), to = CFrame.new(), t0 = now, dur = 1.0, style = Enum.EasingStyle.Elastic }
		return
	end
	if d.pose == "twist" then -- el que pega: la cintura gira con el golpe y vuelve
		local now = os.clock()
		local k = tostring(who)
		anims[k .. "waist"] = { who = who, kind = "waist", from = CFrame.Angles(0, math.rad(-55), math.rad(-8)), to = CFrame.Angles(0, math.rad(50), math.rad(10)), t0 = now, dur = 0.16, style = Enum.EasingStyle.Quad, chain = { to = CFrame.new(), dur = 0.45, style = Enum.EasingStyle.Back } }
		return
	end
	if d.pose == "coil" then -- al cargar: el torso se echa hacia atrás con el brazo
		local k = tostring(who)
		anims[k .. "waist"] = { who = who, kind = "waist", from = CFrame.new(), to = CFrame.Angles(math.rad(8), math.rad(-55), math.rad(-8)), t0 = os.clock(), dur = 0.35, style = Enum.EasingStyle.Quad, hold = true }
		return
	end
	if d.pose == "jolt" then
		local pw = tonumber(d.power) or 0.5
		anims[tostring(who) .. "neck"] = { who = who, kind = "neck", from = CFrame.Angles(math.rad(-15 - 30 * pw), math.rad(40 * pw), math.rad(12 * pw)), to = CFrame.new(), t0 = os.clock(), dur = 0.9, style = Enum.EasingStyle.Elastic }
		return
	end
	local key = tostring(who) .. "arm"
	local cur = anims[key]
	local from = CFrame.new()
	if cur then
		local a = math.clamp((os.clock() - cur.t0) / cur.dur, 0, 1)
		from = cur.from:Lerp(cur.to, TweenService:GetValue(a, cur.style, Enum.EasingDirection.Out))
	end
	anims[key] = { who = who, kind = "arm", from = from, to = POSES[d.pose] or CFrame.new(), t0 = os.clock(), dur = math.max(0.03, tonumber(d.time) or 0.3), style = Enum.EasingStyle.Quad, rest = d.pose == "rest" }
end
RunService.Stepped:Connect(function()
	local now = os.clock()
	for key, a in pairs(anims) do
		local char
		if typeof(a.who) == "Instance" then
			char = a.who.Parent and a.who or nil
		else
			local p = Players:GetPlayerByUserId(a.who)
			char = p and p.Character
		end
		local j = char and jointOf(char, a.kind)
		local t = math.clamp((now - a.t0) / a.dur, 0, 1)
		if j and a.kind == "root" then
			local e = TweenService:GetValue(t, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
			local ang = e * math.pi * 2 * a.turns
			local cf = a.spin == "spin" and CFrame.Angles(0, ang, 0) or CFrame.Angles(-ang, 0, 0)
			pcall(function()
				j.Transform = j.Transform * cf
			end)
			if t >= 1 then
				anims[key] = nil
			end
			continue
		end
		if j then
			local cf = a.from:Lerp(a.to, TweenService:GetValue(t, a.style, Enum.EasingDirection.Out))
			pcall(function()
				j.Transform = j.Transform * cf
			end)
		end
		if t >= 1 then
			if a.chain then
				anims[key] = { who = a.who, kind = a.kind, from = a.to, to = a.chain.to, t0 = now, dur = a.chain.dur, style = a.chain.style }
			elseif a.rest or a.kind == "neck" or a.kind == "larm" or (a.kind == "waist" and (not a.hold or now - a.t0 > 4)) or key:find("rarm2") then
				anims[key] = nil
			end
		end
	end
end)

-- MENSAJES DEL SERVIDOR --------------------------------------------------------------
Net.OnClientEvent:Connect(function(kind, d)
	if kind == "station" then
		station = type(d) == "table" and d or nil
		if not station then
			charging = nil
			bar.Visible = false
			tapLayer.Visible = false
			guessPanel.Visible = false
		elseif station.phase ~= "guessing" then
			guessPanel.Visible = false
		end
		updateUI()
	elseif kind == "bar" and type(d) == "table" then
		charging = { t0 = os.clock(), period = tonumber(d.period) or 0.9 }
		red.Position = UDim2.fromScale(tonumber(d.red) or 0.5, 0.5)
		red.Size = UDim2.fromScale(tonumber(d.width) or 0.07, 1.15)
		bar.Visible = true
		tapLayer.Visible = true
		slapBtn.Visible = false
		play("tick", 1.5)
	elseif kind == "dodge" and type(d) == "table" then
		startDodge(d)
	elseif kind == "guess" and type(d) == "table" then
		startGuess(d)
	elseif kind == "hit" and type(d) == "table" then
		onHit(d)
	elseif kind == "winner" and type(d) == "table" then
		shout("🏆 " .. tostring(d.name) .. L(" GANA LA MESA ", " WINS TABLE ") .. tostring(d.station or ""), GOLD, 3.5)
		play("boom", 1.4, 0.5)
		doFlash(GOLD, 0.6)
		local w = Players:GetPlayerByUserId(tonumber(d.id) or 0)
		local hrp = w and w.Character and w.Character:FindFirstChild("HumanoidRootPart")
		if hrp then
			local at = Instance.new("Attachment")
			at.Position = Vector3.new(0, 4, 0)
			at.Parent = hrp
			local pe = Instance.new("ParticleEmitter")
			pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
			pe.Rate = 0
			pe.Lifetime = NumberRange.new(1, 2)
			pe.Speed = NumberRange.new(10, 22)
			pe.SpreadAngle = Vector2.new(60, 60)
			pe.Acceleration = Vector3.new(0, -20, 0)
			pe.LightEmission = 1
			pe.Rotation = NumberRange.new(0, 360)
			pe.RotSpeed = NumberRange.new(-200, 200)
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
			pe.Color = ColorSequence.new({
				ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 90)),
				ColorSequenceKeypoint.new(0.33, Color3.fromRGB(255, 230, 70)),
				ColorSequenceKeypoint.new(0.66, Color3.fromRGB(90, 220, 110)),
				ColorSequenceKeypoint.new(1, Color3.fromRGB(70, 170, 255)),
			})
			pe.Parent = at
			for k = 0, 3 do
				task.delay(k * 0.35, function()
					pe:Emit(80)
				end)
			end
			task.delay(4, function()
				at:Destroy()
			end)
		end
	elseif kind == "guessed" and type(d) == "table" then
		revealId += 1
		local my = revealId
		guessPanel.Visible = false
		if revealPic then
			revealPic:Destroy()
		end
		local pic, ps = headshot(reveal, tonumber(d.guessedId), 116)
		pic.Position = UDim2.fromOffset(17, 17)
		pic.ZIndex = 13
		revealPic = pic
		revealStroke.Color = GOLD
		ps.Color = GOLD
		revealText.Text = d.timeout and (tostring(d.seated) .. L(" no ha dicho nadie…", " didn't answer…")) or (tostring(d.seated) .. L(" dice que fue…", " says it was…"))
		revealName.Text = d.timeout and "⏱" or (tostring(d.guessed) .. "…")
		revealVerdict.Text = ""
		reveal.Visible = true
		revealScale.Scale = 0.4
		TweenService:Create(revealScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		play("tick", 1.2)
		task.delay(1.2, function()
			if revealId ~= my then
				return
			end
			if d.correct then
				revealStroke.Color = Color3.fromRGB(110, 255, 140)
				ps.Color = Color3.fromRGB(110, 255, 140)
				revealVerdict.TextColor3 = Color3.fromRGB(110, 255, 140)
				revealVerdict.Text = L("✅ ¡ACIERTO! Ahora se sienta él", "✅ CORRECT! They take the seat")
				play("jump", 1.6, 1)
				task.delay(0.12, function()
					play("tick", 2.6, 0.8)
				end)
				doFlash(Color3.fromRGB(110, 255, 140), 0.7)
			else
				revealStroke.Color = Color3.fromRGB(255, 70, 80)
				ps.Color = Color3.fromRGB(255, 70, 80)
				revealVerdict.TextColor3 = Color3.fromRGB(255, 110, 110)
				revealVerdict.Text = L("❌ ¡FALLO! Fue ", "❌ WRONG! It was ") .. tostring(d.slapper)
				-- sonido de error: zumbido grave doble
				play("tick", 0.45, 1)
				task.delay(0.16, function()
					play("tick", 0.4, 1)
				end)
				play("oof", 0.7, 0.6)
				doFlash(Color3.fromRGB(255, 40, 40), 0.75)
				-- temblor del cartel
				for k = 1, 6 do
					task.delay(k * 0.04, function()
						reveal.Rotation = (k % 2 == 0 and 2 or -2)
					end)
				end
				task.delay(0.3, function()
					reveal.Rotation = 0
				end)
			end
			revealScale.Scale = 1.12
			TweenService:Create(revealScale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
			task.delay(2.2, function()
				if revealId == my then
					reveal.Visible = false
				end
			end)
		end)
	elseif kind == "windup" and type(d) == "table" then
		onWindup(d)
	elseif kind == "anim" and type(d) == "table" then
		startAnim(d)
	elseif kind == "msg" then
		msg(tostring(d))
	end
end)
