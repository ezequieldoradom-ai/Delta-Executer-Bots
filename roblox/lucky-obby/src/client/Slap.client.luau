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
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 14, 1, -200)
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
local tapLayer = text(gui, { Button = true, Size = UDim2.fromScale(1, 1), Text = "", Visible = false, ZIndex = 0 })

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
guessPanel.Size = UDim2.fromOffset(460, 300)
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
local layout = Instance.new("UIListLayout")
layout.Padding = UDim.new(0, 10)
layout.Parent = guessList

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
local msgLabel = text(gui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 120), Size = UDim2.fromOffset(760, 40), Text = "", TextTransparency = 1, TextStrokeTransparency = 1, Font = Enum.Font.FredokaOne })
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
local shake = 0

local function amSeated()
	return station and station.seated == player.UserId and station.phase ~= "idle"
end

local function updateUI()
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
			cam.CFrame = CFrame.lookAt(head.Position + look * 0.7 + s, head.Position + look * 12 + Vector3.new(0, -1.5, 0))
			cam.FieldOfView = 70
		end
	elseif camLocked then
		camLocked = false
		cam.CameraType = Enum.CameraType.Custom
	end
	if shake > 0 then
		shake = math.max(0, shake - dt * 2.5)
	end
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
local function finishDodge(ok)
	if not dodging or dodging.done then
		return
	end
	dodging.done = true
	dodgeBtn.Visible = false
	ContextActionService:UnbindAction("SlapDodge")
	Net:FireServer("dodge", ok)
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
		ContextActionService:BindActionAtPriority("SlapDodge", function(_, st, input)
			if st == Enum.UserInputState.Begin then
				finishDodge(input.KeyCode == k.key and os.clock() - dodging.t0 <= window)
			end
			return Enum.ContextActionResult.Sink
		end, false, 4000, Enum.KeyCode.ButtonY, Enum.KeyCode.ButtonB, Enum.KeyCode.ButtonA, Enum.KeyCode.ButtonX)
	else
		dodgeBtn.Position = UDim2.fromScale(0.12 + math.random() * 0.76, 0.18 + math.random() * 0.64)
		dodgeBtn.Text = "💨"
		dodgeBtn.BackgroundColor3 = Color3.fromRGB(255, 70, 90)
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
	for _, o in ipairs(d.options or {}) do
		local b = text(guessList, { Button = true, Size = UDim2.new(1, 0, 0, 56), Text = "👉 " .. tostring(o.name), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(90, 60, 140) })
		corner(b, 14)
		stroke(b, WHITE, 2)
		b.Activated:Connect(function()
			guessPanel.Visible = false
			Net:FireServer("guess", o.id)
		end)
	end
	guessPanel.Visible = true
	local t0, secs = os.clock(), tonumber(d.time) or 10
	task.spawn(function()
		while guessPanel.Visible and os.clock() - t0 < secs do
			guessTitle.Text = string.format("%s · %d", L("🤔 ¿QUIÉN HA SIDO?", "🤔 WHO WAS IT?"), math.ceil(secs - (os.clock() - t0)))
			task.wait(0.2)
		end
		guessPanel.Visible = false
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

local function onHit(d)
	local victimChar = charOf(d.victim)
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
	if isVictim then
		-- el sentado no ve el primer plano: solo el golpe
		shake = 0.6 + power * 1.4
		doFlash(d.supreme and Color3.fromRGB(255, 30, 30) or WHITE, 0.25)
		shout(d.supreme and L("💀 ¡GUANTAZO SUPREMO!", "💀 SUPREME SLAP!") or "💥 ¡PAM!", d.supreme and Color3.fromRGB(255, 70, 70) or GOLD, 1.4)
		return
	end
	-- primer plano (para todos los de cerca menos el sentado)
	if not head or cine then
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
		local dist = d.supreme and (6 + a * 18) or (4.2 - a * 1.2)
		local jitter = a < 0.25 and Vector3.new(math.random() - 0.5, math.random() - 0.5, 0) * (0.25 + power * 0.6) or Vector3.zero
		cam.CFrame = CFrame.lookAt(target + fwd * dist + right * (dist * 0.45) + Vector3.new(0, 0.6, 0) + jitter, target - fwd * 0.8)
		cam.FieldOfView = 50 - a * 6
		if a >= 1 then
			conn:Disconnect()
			cam.FieldOfView = oldFov
			cam.CameraType = oldType == Enum.CameraType.Scriptable and Enum.CameraType.Custom or oldType
			cine = false
		end
	end)
end

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
	elseif kind == "msg" then
		msg(tostring(d))
	end
end)
