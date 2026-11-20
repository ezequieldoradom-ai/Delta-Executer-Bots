-- Lucky Obby Race — 👑 Rey de la colina en tu pantalla (Shadow). Ver src/server/KingHill.luau.
--   · Panel arriba a la izquierda: jugadores, puntos en la colina, tiempo y cuenta atrás.
--   · Botón 👊 EMPUJAR (E / □ / R2 o tocar) mientras juegas.
--   · Avisos, sonido de guantazo y fiesta para el ganador.
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Net = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Hill")
local Locale = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Locale"))
pcall(function()
	Locale.detect(player.LocaleId)
end)
local function L(es, en)
	return Locale.lang() == "es" and es or en
end
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 215, 70)
local BANGERS = Font.new("rbxasset://fonts/families/Bangers.json")
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")

local function snd(id, vol, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol
	s.PlaybackSpeed = speed or 1
	s.Parent = SoundService
	return s
end
local S = {
	slap = snd("rbxasset://sounds/action_jump_land.mp3", 1, 1.6),
	whoosh = snd("rbxasset://sounds/action_jump.mp3", 0.6, 1.8),
	boom = snd("rbxasset://sounds/impact_explosion_03.mp3", 0.5, 1.3),
	tick = snd("rbxasset://sounds/action_footsteps_plastic.mp3", 0.4, 2),
	fall = snd("rbxasset://sounds/action_falling.ogg", 1, 1.1),
	oof = snd("rbxasset://sounds/oof.ogg", 1, 1),
}

local gui = Instance.new("ScreenGui")
gui.Name = "HillGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 8
gui.Parent = player:WaitForChild("PlayerGui")
local scale = Instance.new("UIScale")
scale.Parent = gui
local function rescale()
	local v = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.clamp(math.min(v.X / 1280, v.Y / 760), 0.55, 1)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = o
end
local function stroke(o, col, th)
	local s = Instance.new("UIStroke")
	s.Color = col or WHITE
	s.Thickness = th or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end
local function label(parent, props)
	local l = Instance.new(props.Button and "TextButton" or "TextLabel")
	l.BackgroundTransparency = 1
	l.FontFace = FREDOKA
	l.TextScaled = true
	l.TextColor3 = WHITE
	l.TextStrokeTransparency = 0.4
	for k, v in pairs(props) do
		if k ~= "Button" then
			l[k] = v
		end
	end
	l.Parent = parent
	return l
end

-- PANEL ------------------------------------------------------------------------------
local panel = Instance.new("Frame")
panel.Position = UDim2.new(0, 14, 0, 120)
panel.Size = UDim2.fromOffset(280, 236)
panel.BackgroundColor3 = Color3.fromRGB(40, 28, 10)
panel.BackgroundTransparency = 0.12
panel.Visible = false
panel.Parent = gui
corner(panel, 16)
stroke(panel, GOLD, 3)
local title = label(panel, { Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -96, 0, 28), FontFace = BANGERS, TextColor3 = GOLD, TextXAlignment = Enum.TextXAlignment.Left, Text = "👑 REY DE LA COLINA" })
local leave = label(panel, { Button = true, Position = UDim2.new(1, -82, 0, 6), Size = UDim2.fromOffset(72, 28), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(200, 60, 80), FontFace = BANGERS, Text = L("SALIR", "LEAVE") })
corner(leave, 10)
leave.Activated:Connect(function()
	Net:FireServer("leave")
end)
local info = label(panel, { Position = UDim2.fromOffset(12, 38), Size = UDim2.new(1, -24, 0, 22), TextXAlignment = Enum.TextXAlignment.Left, Text = "" })
local list = Instance.new("Frame")
list.BackgroundTransparency = 1
list.Position = UDim2.fromOffset(12, 66)
list.Size = UDim2.new(1, -24, 1, -74)
list.Parent = panel
local rows = {}
for i = 1, 10 do
	rows[i] = label(list, { Position = UDim2.new(0, 0, 0, (i - 1) * 16.4), Size = UDim2.new(1, 0, 0, 15), TextXAlignment = Enum.TextXAlignment.Left, Text = "" })
end

-- BOTÓN EMPUJAR ----------------------------------------------------------------------
local push = label(gui, { Button = true, AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, 0, 1, -30), Size = UDim2.fromOffset(260, 64), BackgroundTransparency = 0, BackgroundColor3 = Color3.fromRGB(230, 120, 40), FontFace = BANGERS, Text = "👊 " .. L("EMPUJAR", "PUSH") .. " (E)", Visible = false })
corner(push, 20)
local pushStroke = stroke(push, WHITE, 3)
local pushScale = Instance.new("UIScale")
pushScale.Parent = push
local lastPush = 0
local function doPush()
	if os.clock() - lastPush < 0.8 then
		return
	end
	lastPush = os.clock()
	Net:FireServer("push")
	S.whoosh:Play()
	pushScale.Scale = 0.85
	TweenService:Create(pushScale, TweenInfo.new(0.25, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end
push.Activated:Connect(doPush)
ContextActionService:BindActionAtPriority("HillPush", function(_, st)
	if st == Enum.UserInputState.Begin and push.Visible then
		doPush()
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, 3000, Enum.KeyCode.E, Enum.KeyCode.ButtonX, Enum.KeyCode.ButtonR2)
RunService.RenderStepped:Connect(function()
	if push.Visible then
		local ready = os.clock() - lastPush >= 0.8
		push.BackgroundColor3 = ready and Color3.fromRGB(230, 120, 40) or Color3.fromRGB(110, 80, 60)
		pushStroke.Color = ready and Color3.fromHSV((os.clock() * 0.5) % 1, 0.5, 1) or WHITE
	end
end)

-- AVISOS -----------------------------------------------------------------------------
local big = label(gui, { AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.22), Size = UDim2.fromOffset(560, 54), FontFace = BANGERS, Text = "", TextTransparency = 1, TextStrokeTransparency = 1 })
local function shout(t, color, secs)
	big.Text = t
	big.TextColor3 = color or WHITE
	big.TextTransparency, big.TextStrokeTransparency = 0, 0.3
	local my = t
	task.delay(secs or 2, function()
		if big.Text == my then
			TweenService:Create(big, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end
local msgL = label(gui, { AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, 208), Size = UDim2.fromOffset(640, 30), Text = "", TextTransparency = 1, TextStrokeTransparency = 1 })
local function msg(t)
	msgL.Text = t
	msgL.TextTransparency, msgL.TextStrokeTransparency = 0, 0.4
	local my = t
	task.delay(3, function()
		if msgL.Text == my then
			TweenService:Create(msgL, TweenInfo.new(0.4), { TextTransparency = 1, TextStrokeTransparency = 1 }):Play()
		end
	end)
end

-- ESTADO -----------------------------------------------------------------------------
local state = nil
local lastPhase = nil
local function setPrompt(enabled)
	local f = workspace:FindFirstChild("KingHill")
	local pp = f and f:FindFirstChild("HillPrompt", true)
	if pp then
		pp.Enabled = enabled
	end
end
local function render()
	panel.Visible = state ~= nil
	setPrompt(state == nil)
	if not state then
		push.Visible = false
		return
	end
	local me
	for _, m in ipairs(state.members or {}) do
		if m.id == player.UserId then
			me = m
		end
	end
	title.Text = string.format("👑 %s · %d/%d", L("COLINA", "HILL"), #(state.members or {}), state.max or 10)
	if state.phase == "starting" then
		info.Text = string.format(L("⏳ Empieza en %d s…", "⏳ Starts in %d s…"), state.startsIn or 0)
	elseif state.phase == "playing" then
		info.Text = me and me.alive and string.format(L("⏱ %d s · ¡a por la colina dorada!", "⏱ %d s · get the golden hill!"), state.timeLeft or 0) or string.format(L("💀 Eliminado · ⏱ %d s", "💀 Out · ⏱ %d s"), state.timeLeft or 0)
	elseif state.phase == "result" then
		info.Text = L("🏆 ¡Fin de la partida!", "🏆 Match over!")
	else
		info.Text = L("Esperando a otro jugador…", "Waiting for another player…")
	end
	for i, r in ipairs(rows) do
		local m = state.members and state.members[i]
		if m then
			r.Text = string.format("%s %s  %s", m.alive and "🟢" or (state.phase == "playing" and "💀" or "⚪"), m.name, (state.phase == "playing" or state.phase == "result") and (m.score .. " s") or "")
			r.TextColor3 = m.id == player.UserId and GOLD or WHITE
		else
			r.Text = ""
		end
	end
	push.Visible = state.phase == "playing" and me ~= nil and me.alive
	if state.phase ~= lastPhase then
		if state.phase == "playing" then
			shout("👑 " .. L("¡A LA COLINA!", "KING OF THE HILL!"), GOLD, 1.6)
			S.boom:Play()
		elseif state.phase == "starting" then
			S.tick:Play()
		end
		lastPhase = state.phase
	end
end

Net.OnClientEvent:Connect(function(kind, d)
	if kind == "state" then
		state = type(d) == "table" and d or nil
		if not state then
			lastPhase = nil
		end
		render()
	elseif kind == "msg" then
		msg(tostring(d))
	elseif kind == "fall" and type(d) == "table" then
		-- caída: silbido + "oof" en el sitio (si eres tú, más fuerte y sin posición)
		if d.me then
			S.fall:Play()
			task.delay(0.35, function()
				S.oof:Play()
			end)
		elseif typeof(d.pos) == "Vector3" then
			local a = Instance.new("Part")
			a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency = true, false, false, false, 1
			a.Size = Vector3.one
			a.CFrame = CFrame.new(d.pos)
			a.Parent = workspace.CurrentCamera
			for _, k in ipairs({ "fall", "oof" }) do
				local s = S[k]:Clone()
				s.RollOffMaxDistance = 150
				s.Parent = a
				task.delay(k == "oof" and 0.35 or 0, function()
					s:Play()
				end)
			end
			task.delay(4, function()
				a:Destroy()
			end)
		end
	elseif kind == "pushFx" and type(d) == "table" and typeof(d.pos) == "Vector3" then
		-- sonido del guantazo en el sitio (más fuerte si da a alguien)
		local a = Instance.new("Part")
		a.Anchored, a.CanCollide, a.CanQuery, a.CanTouch, a.Transparency = true, false, false, false, 1
		a.Size = Vector3.one
		a.CFrame = CFrame.new(d.pos)
		a.Parent = workspace.CurrentCamera
		local s = (d.hit and S.slap or S.whoosh):Clone()
		s.RollOffMaxDistance = 120
		s.Parent = a
		s:Play()
		task.delay(3, function()
			a:Destroy()
		end)
	elseif kind == "winner" and type(d) == "table" then
		local me = d.id == player.UserId
		shout(me and L("👑 ¡ERES EL REY DE LA COLINA!", "👑 YOU ARE THE KING OF THE HILL!") or ("👑 " .. tostring(d.name) .. L(" ES EL REY", " IS THE KING")), GOLD, 3)
		S.boom:Play()
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
			pe.Speed = NumberRange.new(10, 20)
			pe.SpreadAngle = Vector2.new(60, 60)
			pe.Acceleration = Vector3.new(0, -20, 0)
			pe.LightEmission = 1
			pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150), Color3.fromRGB(255, 180, 40))
			pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
			pe.Parent = at
			for k = 0, 3 do
				task.delay(k * 0.35, function()
					pe:Emit(70)
				end)
			end
			task.delay(4, function()
				at:Destroy()
			end)
		end
	end
end)
