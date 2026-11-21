-- Lucky Obby Race — sala de espera en tu pantalla (Shadow)
--   · 👀 VER CARRERA: la cámara sigue a los que corren (◀ ▶ para cambiar)
--   · 🐻 FLAPPY BEAR: toca / clic / espacio / (A) para volar entre los tubos
--   · 🚪 SALIR: vuelves al vestíbulo
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Net = Remotes:WaitForChild("Wait")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local Locale = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Locale"))
local es = Locale.code(player.LocaleId) == "es"
local function L(a, b)
	return es and a or b
end

local BANGERS = Font.new("rbxasset://fonts/families/Bangers.json")
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 210, 70)

local function snd(id, vol, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol
	s.PlaybackSpeed = speed or 1
	s.Parent = SoundService
	return s
end
local S = {
	flap = snd("rbxasset://sounds/action_jump.mp3", 0.4, 1.6),
	point = snd("rbxasset://sounds/electronicpingshort.wav", 0.35, 1.5),
	hit = snd("rbxasset://sounds/collide.wav", 0.6, 1),
	click = snd("rbxasset://sounds/electronicpingshort.wav", 0.3, 1.2),
}

local gui = Instance.new("ScreenGui")
gui.Name = "WaitRoomGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 12
gui.Enabled = false
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
local function stroke(o, col, t)
	local s = Instance.new("UIStroke")
	s.Color = col or WHITE
	s.Thickness = t or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
	return s
end
local function button(parent, text, color, size, pos, anchor)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos
	b.AnchorPoint = anchor or Vector2.zero
	b.BackgroundColor3 = color
	b.FontFace = BANGERS
	b.TextScaled = true
	b.TextColor3 = WHITE
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 14)
	stroke(b, WHITE, 2)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop, pad.PaddingBottom = UDim.new(0, 6), UDim.new(0, 6)
	pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 8), UDim.new(0, 8)
	pad.Parent = b
	return b
end

-- BARRA DE ABAJO: estado + botones -------------------------------------------------------
local bar = Instance.new("Frame")
bar.AnchorPoint = Vector2.new(0.5, 1)
bar.Position = UDim2.new(0.5, 0, 1, -18)
bar.Size = UDim2.fromOffset(640, 118)
bar.BackgroundColor3 = Color3.fromRGB(26, 18, 46)
bar.BackgroundTransparency = 0.1
bar.Parent = gui
corner(bar, 18)
stroke(bar, GOLD, 3)
local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Position = UDim2.fromOffset(16, 8)
status.Size = UDim2.new(1, -32, 0, 34)
status.FontFace = FREDOKA
status.TextScaled = true
status.TextColor3 = GOLD
status.Text = ""
status.Parent = bar
local watchB = button(bar, L("👀 VER CARRERA", "👀 WATCH RACE"), Color3.fromRGB(70, 130, 230), UDim2.fromOffset(196, 58), UDim2.fromOffset(16, 50))
local flappyB = button(bar, "🐻 FLAPPY BEAR", Color3.fromRGB(230, 140, 40), UDim2.fromOffset(196, 58), UDim2.new(0.5, 0, 0, 50), Vector2.new(0.5, 0))
local leaveB = button(bar, L("🚪 SALIR", "🚪 LEAVE"), Color3.fromRGB(200, 60, 80), UDim2.fromOffset(196, 58), UDim2.new(1, -16, 0, 50), Vector2.new(1, 0))

-- VER LA CARRERA ----------------------------------------------------------------------
local spect = Instance.new("Frame")
spect.AnchorPoint = Vector2.new(0.5, 0)
spect.Position = UDim2.new(0.5, 0, 0, 92)
spect.Size = UDim2.fromOffset(460, 56)
spect.BackgroundColor3 = Color3.fromRGB(26, 18, 46)
spect.BackgroundTransparency = 0.15
spect.Visible = false
spect.Parent = gui
corner(spect, 14)
stroke(spect, Color3.fromRGB(120, 180, 255), 2)
local prevB = button(spect, "◀", Color3.fromRGB(70, 130, 230), UDim2.fromOffset(56, 44), UDim2.fromOffset(6, 6))
local nextB = button(spect, "▶", Color3.fromRGB(70, 130, 230), UDim2.fromOffset(56, 44), UDim2.new(1, -62, 0, 6))
local who = Instance.new("TextLabel")
who.BackgroundTransparency = 1
who.Position = UDim2.fromOffset(70, 6)
who.Size = UDim2.new(1, -140, 1, -12)
who.FontFace = FREDOKA
who.TextScaled = true
who.TextColor3 = WHITE
who.Text = ""
who.Parent = spect

local watching = false
local idx = 1
local function racers()
	-- todos los que están en el recorrido de la carrera (jugadores y corredores NPC)
	local list = {}
	local C = Config.COURSE
	local function consider(model, name)
		local h = model and model:FindFirstChild("HumanoidRootPart")
		local hum = model and model:FindFirstChildOfClass("Humanoid")
		if h and hum and math.abs(h.Position.X) < C.WIDTH and h.Position.Y > C.START.Y - 30 and h.Position.Z > C.START.Z - 20 then
			table.insert(list, { hum = hum, name = name, z = h.Position.Z })
		end
	end
	for _, p in ipairs(Players:GetPlayers()) do
		if p ~= player then
			consider(p.Character, p.DisplayName)
		end
	end
	for _, m in ipairs(CollectionService:GetTagged("LuckyBot")) do
		local hum = m:FindFirstChildOfClass("Humanoid")
		consider(m, hum and hum.DisplayName or m.Name)
	end
	table.sort(list, function(a, b)
		return a.z > b.z -- el primero, el que va delante
	end)
	return list
end
local function myHum()
	local c = player.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function stopWatching()
	watching = false
	spect.Visible = false
	watchB.Text = L("👀 VER CARRERA", "👀 WATCH RACE")
	local h = myHum()
	if h then
		workspace.CurrentCamera.CameraSubject = h
	end
end
local function show()
	local list = racers()
	if #list == 0 then
		who.Text = L("Nadie corriendo ahora mismo", "Nobody racing right now")
		local h = myHum()
		if h then
			workspace.CurrentCamera.CameraSubject = h
		end
		return
	end
	idx = ((idx - 1) % #list) + 1
	local r = list[idx]
	workspace.CurrentCamera.CameraSubject = r.hum
	who.Text = string.format("%d/%d · %s", idx, #list, r.name)
end
watchB.Activated:Connect(function()
	S.click:Play()
	if watching then
		stopWatching()
	else
		watching = true
		spect.Visible = true
		watchB.Text = L("🙈 DEJAR DE VER", "🙈 STOP WATCHING")
		idx = 1
		show()
	end
end)
prevB.Activated:Connect(function()
	idx -= 1
	show()
end)
nextB.Activated:Connect(function()
	idx += 1
	show()
end)
-- si el corredor que miras sale del recorrido, se pasa al siguiente
task.spawn(function()
	while true do
		task.wait(1)
		if watching then
			local subj = workspace.CurrentCamera.CameraSubject
			local ok = false
			for _, r in ipairs(racers()) do
				if r.hum == subj then
					ok = true
				end
			end
			if not ok then
				show()
			end
		end
	end
end)

-- FLAPPY BEAR ----------------------------------------------------------------------------
local W, H = 420, 560
local fb = Instance.new("Frame")
fb.AnchorPoint = Vector2.new(0.5, 0.5)
fb.Position = UDim2.fromScale(0.5, 0.45)
fb.Size = UDim2.fromOffset(W, H)
fb.BackgroundColor3 = Color3.fromRGB(110, 190, 255)
fb.ClipsDescendants = true
fb.Visible = false
fb.Parent = gui
corner(fb, 18)
stroke(fb, WHITE, 4)
local sky = Instance.new("UIGradient")
sky.Rotation = 90
sky.Color = ColorSequence.new(Color3.fromRGB(120, 200, 255), Color3.fromRGB(255, 200, 150))
sky.Parent = fb
local ground = Instance.new("Frame")
ground.Size = UDim2.new(1, 0, 0, 40)
ground.Position = UDim2.new(0, 0, 1, -40)
ground.BackgroundColor3 = Color3.fromRGB(110, 200, 90)
ground.BorderSizePixel = 0
ground.ZIndex = 3
ground.Parent = fb
local bear = Instance.new("TextLabel")
bear.BackgroundTransparency = 1
bear.Size = UDim2.fromOffset(44, 44)
bear.AnchorPoint = Vector2.new(0.5, 0.5)
bear.Text = "🐻"
bear.TextScaled = true
bear.ZIndex = 4
bear.Parent = fb
local scoreL = Instance.new("TextLabel")
scoreL.BackgroundTransparency = 1
scoreL.Size = UDim2.new(1, 0, 0, 60)
scoreL.Position = UDim2.fromOffset(0, 14)
scoreL.FontFace = BANGERS
scoreL.TextScaled = true
scoreL.TextColor3 = WHITE
scoreL.TextStrokeTransparency = 0
scoreL.ZIndex = 5
scoreL.Text = "0"
scoreL.Parent = fb
local hint = Instance.new("TextLabel")
hint.BackgroundTransparency = 1
hint.AnchorPoint = Vector2.new(0.5, 0.5)
hint.Position = UDim2.fromScale(0.5, 0.62)
hint.Size = UDim2.new(1, -40, 0, 70)
hint.FontFace = FREDOKA
hint.TextScaled = true
hint.TextWrapped = true
hint.TextColor3 = WHITE
hint.TextStrokeTransparency = 0.2
hint.ZIndex = 5
hint.Parent = fb
local closeF = button(fb, "X", Color3.fromRGB(200, 60, 80), UDim2.fromOffset(44, 44), UDim2.new(1, -10, 0, 10), Vector2.new(1, 0))
closeF.ZIndex = 6
local tap = Instance.new("TextButton")
tap.BackgroundTransparency = 1
tap.Text = ""
tap.Size = UDim2.fromScale(1, 1)
tap.ZIndex = 2
tap.Parent = fb

local GRAV, FLAP, SPEED, GAP, PIPE_W = 1500, -430, 170, 165, 64
local by, vy, pipes, score, best, alive, started, spawnX = H / 2, 0, {}, 0, 0, false, false, 0
local function clearPipes()
	for _, p in ipairs(pipes) do
		p.top:Destroy()
		p.bot:Destroy()
	end
	table.clear(pipes)
end
local function newPipe(x)
	local gapY = math.random(110, H - 40 - 110)
	local function col(y0, h)
		local f = Instance.new("Frame")
		f.BackgroundColor3 = Color3.fromRGB(80, 200, 90)
		f.BorderSizePixel = 0
		f.Size = UDim2.fromOffset(PIPE_W, h)
		f.Position = UDim2.fromOffset(x, y0)
		f.ZIndex = 3
		f.Parent = fb
		corner(f, 8)
		stroke(f, Color3.fromRGB(30, 110, 40), 3)
		return f
	end
	local topH = gapY - GAP / 2
	local botY = gapY + GAP / 2
	table.insert(pipes, { x = x, gapY = gapY, top = col(-10, topH + 10), bot = col(botY, H - 40 - botY), passed = false })
end
local function reset()
	clearPipes()
	by, vy, score, alive, started = H / 2, 0, 0, true, false
	scoreL.Text = "0"
	hint.Text = L("¡Toca, haz clic o pulsa ESPACIO para volar!", "Tap, click or press SPACE to fly!")
	hint.Visible = true
	spawnX = W + 40
	for i = 0, 2 do
		newPipe(W + 80 + i * 210)
	end
end
local function flap()
	if not fb.Visible then
		return
	end
	if not alive then
		reset()
		return
	end
	started = true
	hint.Visible = false
	vy = FLAP
	S.flap:Play()
end
local function gameOver()
	alive = false
	S.hit:Play()
	best = math.max(best, score)
	hint.Text = string.format(L("💥 ¡Choque! Puntos: %d · Récord: %d\nToca para volver a jugar", "💥 Crash! Score: %d · Best: %d\nTap to play again"), score, best)
	hint.Visible = true
end
tap.Activated:Connect(flap)
local function openFlappy(on)
	fb.Visible = on
	flappyB.Text = on and L("🐻 CERRAR JUEGO", "🐻 CLOSE GAME") or "🐻 FLAPPY BEAR"
	if on then
		reset()
		ContextActionService:BindActionAtPriority("FlappyFlap", function(_, st)
			if st == Enum.UserInputState.Begin then
				flap()
			end
			return Enum.ContextActionResult.Sink
		end, false, 3500, Enum.KeyCode.Space, Enum.KeyCode.ButtonA, Enum.KeyCode.Up, Enum.KeyCode.W)
	else
		ContextActionService:UnbindAction("FlappyFlap")
		clearPipes()
	end
end
flappyB.Activated:Connect(function()
	S.click:Play()
	openFlappy(not fb.Visible)
end)
closeF.Activated:Connect(function()
	openFlappy(false)
end)
RunService.RenderStepped:Connect(function(dt)
	if not fb.Visible then
		return
	end
	dt = math.min(dt, 1 / 30)
	if alive and started then
		vy += GRAV * dt
		by += vy * dt
		for i = #pipes, 1, -1 do
			local p = pipes[i]
			p.x -= SPEED * dt
			p.top.Position = UDim2.fromOffset(p.x, -10)
			p.bot.Position = UDim2.fromOffset(p.x, p.gapY + GAP / 2)
			if not p.passed and p.x + PIPE_W < 90 - 18 then
				p.passed = true
				score += 1
				scoreL.Text = tostring(score)
				S.point:Play()
			end
			-- choque (caja del oso más pequeña que el emoji, para que sea justo)
			if 90 + 16 > p.x and 90 - 16 < p.x + PIPE_W and (by - 16 < p.gapY - GAP / 2 or by + 16 > p.gapY + GAP / 2) then
				gameOver()
			end
			if p.x < -PIPE_W - 10 then
				p.top:Destroy()
				p.bot:Destroy()
				table.remove(pipes, i)
				local last = pipes[#pipes]
				newPipe((last and last.x or W) + 210)
			end
		end
		if by > H - 40 - 18 or by < 10 then
			gameOver()
		end
	elseif not started then
		by = H / 2 + math.sin(os.clock() * 3) * 10 -- flota esperando
	end
	bear.Position = UDim2.fromOffset(90, by)
	bear.Rotation = math.clamp(vy / 12, -25, 70)
end)

-- SALIR ---------------------------------------------------------------------------------
local leaveAsk = 0
leaveB.Activated:Connect(function()
	S.click:Play()
	if os.clock() - leaveAsk < 2.5 then
		Net:FireServer("leave")
	else
		leaveAsk = os.clock()
		leaveB.Text = L("¿SEGURO?", "SURE?")
		task.delay(2.5, function()
			leaveB.Text = L("🚪 SALIR", "🚪 LEAVE")
		end)
	end
end)

-- ESTADO: se muestra mientras esperas --------------------------------------------------
local function refresh()
	local on = player:GetAttribute("Waiting") == true
	if gui.Enabled ~= on then
		gui.Enabled = on
		if not on then
			openFlappy(false)
			stopWatching()
		end
	end
end
player:GetAttributeChangedSignal("Waiting"):Connect(refresh)
refresh()
Remotes:WaitForChild("State").OnClientEvent:Connect(function(s)
	if type(s) ~= "table" or not gui.Enabled then
		return
	end
	local left = math.ceil(s.left or 0)
	if s.state == "joining" then
		status.Text = s.joined and string.format(L("✅ Apuntado · la carrera sale en %d s", "✅ Signed up · race starts in %d s"), left) or L("⏳ Apuntándote…", "⏳ Signing you up…")
	elseif s.state == "break" then
		status.Text = string.format(L("☕ Descanso · se abre la inscripción en %d s", "☕ Break · sign-up opens in %d s"), left)
	elseif s.state == "results" then
		status.Text = L("🏆 Resultados · enseguida empieza la siguiente", "🏆 Results · next race soon")
	else
		status.Text = L("🏁 Carrera en curso · espera a la siguiente", "🏁 Race in progress · wait for the next one")
	end
end)
