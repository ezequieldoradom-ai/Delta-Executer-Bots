-- Lucky Obby Race — pantalla de carga (Shadow). Sale nada más entrar, mientras se carga el mapa.
-- Barra de progreso real (lo que falta por descargar), lucky blocks girando, consejos y botón SALTAR.
local ContentProvider = game:GetService("ContentProvider")
local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
player:SetAttribute("Loading", true)
pcall(function()
	ReplicatedFirst:RemoveDefaultLoadingScreen()
end)

local es = true
pcall(function()
	es = string.sub(player.LocaleId or "es", 1, 2) == "es"
end)
local function L(a, b)
	return es and a or b
end

local BANGERS = Font.new("rbxasset://fonts/families/Bangers.json")
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local WHITE = Color3.new(1, 1, 1)

local gui = Instance.new("ScreenGui")
gui.Name = "LoadingScreen"
gui.IgnoreGuiInset = true
gui.ResetOnSpawn = false
gui.DisplayOrder = 100
gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
gui.Parent = player:WaitForChild("PlayerGui")

local bg = Instance.new("Frame")
bg.Size = UDim2.fromScale(1, 1)
bg.BackgroundColor3 = WHITE
bg.BorderSizePixel = 0
bg.Parent = gui
local grad = Instance.new("UIGradient")
grad.Rotation = 35
grad.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(40, 20, 90)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(110, 40, 160)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(20, 60, 140)),
})
grad.Parent = bg

-- el contenido (título, consejos, barra) va en un marco de 1280x760 que se escala a la pantalla
local content = Instance.new("Frame")
content.AnchorPoint = Vector2.new(0.5, 0.5)
content.Position = UDim2.fromScale(0.5, 0.5)
content.Size = UDim2.fromOffset(1280, 760)
content.BackgroundTransparency = 1
content.ZIndex = 5
content.Parent = bg
local scale = Instance.new("UIScale")
scale.Parent = content
local function rescale()
	local cam = workspace.CurrentCamera
	local v = cam and cam.ViewportSize or Vector2.new(1280, 720)
	scale.Scale = math.clamp(math.min(v.X / 1280, v.Y / 760), 0.35, 1.5)
end
rescale()
if workspace.CurrentCamera then
	workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)
end

-- estrellitas de fondo
local stars = {}
local rng = Random.new()
for i = 1, 40 do
	local s = Instance.new("Frame")
	s.BackgroundColor3 = WHITE
	s.BorderSizePixel = 0
	local sz = rng:NextInteger(2, 5)
	s.Size = UDim2.fromOffset(sz, sz)
	s.Position = UDim2.fromScale(rng:NextNumber(), rng:NextNumber())
	s.BackgroundTransparency = rng:NextNumber(0.2, 0.7)
	s.Parent = bg
	Instance.new("UICorner", s).CornerRadius = UDim.new(1, 0)
	stars[i] = { f = s, ph = rng:NextNumber(0, 6), sp = rng:NextNumber(0.01, 0.04) }
end

-- lucky blocks girando
local blocks = {}
for i = 1, 6 do
	local b = Instance.new("TextLabel")
	b.AnchorPoint = Vector2.new(0.5, 0.5)
	b.Size = UDim2.fromOffset(70, 70)
	b.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
	b.Text = "?"
	b.FontFace = BANGERS
	b.TextScaled = true
	b.TextColor3 = WHITE
	b.TextStrokeTransparency = 0
	b.TextStrokeColor3 = Color3.fromRGB(160, 90, 0)
	b.BackgroundTransparency = 0.15
	b.Parent = bg
	Instance.new("UICorner", b).CornerRadius = UDim.new(0, 10)
	local st = Instance.new("UIStroke")
	st.Thickness = 4
	st.Color = Color3.fromRGB(255, 140, 0)
	st.Parent = b
	blocks[i] = { f = b, ph = i * 1.05 }
end

local title = Instance.new("TextLabel")
title.AnchorPoint = Vector2.new(0.5, 0.5)
title.Position = UDim2.fromScale(0.5, 0.4)
title.Size = UDim2.fromOffset(820, 150)
title.BackgroundTransparency = 1
title.FontFace = BANGERS
title.TextScaled = true
title.RichText = true
title.Text = '<font color="#FFD54A">LUCKY</font> OBBY <font color="#FF4A5A">RACE</font>'
title.TextColor3 = WHITE
title.TextStrokeTransparency = 0
title.Parent = content
local tScale = Instance.new("UIScale")
tScale.Parent = title

local tip = Instance.new("TextLabel")
tip.AnchorPoint = Vector2.new(0.5, 0.5)
tip.Position = UDim2.fromScale(0.5, 0.56)
tip.Size = UDim2.fromOffset(760, 34)
tip.BackgroundTransparency = 1
tip.FontFace = FREDOKA
tip.TextScaled = true
tip.TextColor3 = Color3.fromRGB(230, 220, 255)
tip.TextStrokeTransparency = 0.5
tip.Parent = content
local TIPS = {
	L("🎁 Cada 10 s te toca un lucky block: ¡úsalo con E!", "🎁 Every 10 s you get a lucky block: use it with E!"),
	L("🖐️ En la plaza, adivina quién te ha dado el guantazo", "🖐️ In the plaza, guess who slapped you"),
	L("👑 En el Rey de la colina, ¡no te caigas de la arena!", "👑 In King of the Hill, don't fall off!"),
	L("🍀 Sube tu suerte para conseguir objetos míticos", "🍀 Level up your luck for mythic items"),
	L("💀 El rojo de la barra es el guantazo SUPREMO", "💀 The red spot on the bar is the SUPREME slap"),
	L("🌈 Compra estelas con tus monedas en el vestíbulo", "🌈 Buy trails with your coins in the lobby"),
}
local tipI = math.random(1, #TIPS)
tip.Text = TIPS[tipI]

local barBack = Instance.new("Frame")
barBack.AnchorPoint = Vector2.new(0.5, 0.5)
barBack.Position = UDim2.fromScale(0.5, 0.66)
barBack.Size = UDim2.fromOffset(560, 26)
barBack.BackgroundColor3 = Color3.fromRGB(25, 15, 45)
barBack.Parent = content
Instance.new("UICorner", barBack).CornerRadius = UDim.new(1, 0)
local bs = Instance.new("UIStroke")
bs.Thickness = 3
bs.Color = WHITE
bs.Parent = barBack
local fill = Instance.new("Frame")
fill.Size = UDim2.fromScale(0, 1)
fill.BackgroundColor3 = WHITE
fill.Parent = barBack
Instance.new("UICorner", fill).CornerRadius = UDim.new(1, 0)
local fg = Instance.new("UIGradient")
fg.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 90)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 70)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 220, 110)),
})
fg.Parent = fill
local pct = Instance.new("TextLabel")
pct.AnchorPoint = Vector2.new(0.5, 0)
pct.Position = UDim2.new(0.5, 0, 1, 6)
pct.Size = UDim2.fromOffset(400, 24)
pct.BackgroundTransparency = 1
pct.FontFace = FREDOKA
pct.TextScaled = true
pct.TextColor3 = WHITE
pct.Text = L("Cargando el mapa… 0%", "Loading the map… 0%")
pct.Parent = barBack

local skip = Instance.new("TextButton")
skip.AnchorPoint = Vector2.new(1, 1)
skip.Position = UDim2.new(1, -28, 1, -28)
skip.Size = UDim2.fromOffset(170, 52)
skip.BackgroundColor3 = Color3.fromRGB(255, 200, 50)
skip.BackgroundTransparency = 0
skip.ZIndex = 6
skip.TextStrokeTransparency = 1
skip.FontFace = BANGERS
skip.TextScaled = true
skip.TextColor3 = Color3.fromRGB(70, 25, 110)
skip.Text = L("SALTAR ⏭", "SKIP ⏭")
skip.Visible = false
skip.Parent = bg
Instance.new("UICorner", skip).CornerRadius = UDim.new(1, 0)
local ks = Instance.new("UIStroke")
ks.Thickness = 3
ks.Color = WHITE
ks.Parent = skip
local kp = Instance.new("UIPadding")
kp.PaddingTop, kp.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10)
kp.Parent = skip

-- sonido: música suave de fondo, clic al saltar y campanita al terminar
local SoundService = game:GetService("SoundService")
local function snd(id, vol, looped)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol
	s.Looped = looped or false
	s.Parent = SoundService
	return s
end
local music = snd("rbxassetid://92067940679570", 0, true)
music:Play()
TweenService:Create(music, TweenInfo.new(1.5), { Volume = 0.35 }):Play()
local clickS = snd("rbxasset://sounds/electronicpingshort.wav", 0.6)
local readyS = snd("rbxasset://sounds/victory.wav", 0.4)

-- animación
local t0 = os.clock()
local conn = RunService.RenderStepped:Connect(function()
	local t = os.clock() - t0
	grad.Rotation = 35 + math.sin(t * 0.4) * 20
	tScale.Scale = 1 + math.sin(t * 2.4) * 0.03
	for i, b in ipairs(blocks) do
		local a = t * 0.6 + b.ph
		b.f.Position = UDim2.new(0.5 + math.cos(a) * 0.36, 0, 0.36 + math.sin(a) * 0.26, math.sin(t * 3 + i) * 8)
		b.f.Rotation = (t * 60 + i * 40) % 360
	end
	for _, s in ipairs(stars) do
		local y = (s.f.Position.Y.Scale + s.sp * 0.016) % 1
		s.f.Position = UDim2.fromScale(s.f.Position.X.Scale, y)
		s.f.BackgroundTransparency = 0.45 + math.sin(t * 2 + s.ph) * 0.35
	end
end)

-- progreso real: lo que queda en la cola de descarga
local done = false
local function close()
	if done then
		return
	end
	done = true
	player:SetAttribute("Loading", nil)
	readyS:Play()
	TweenService:Create(music, TweenInfo.new(0.8), { Volume = 0 }):Play()
	task.delay(1, function()
		music:Destroy()
	end)
	task.delay(4, function()
		readyS:Destroy()
		clickS:Destroy()
	end)
	TweenService:Create(bg, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	for _, d in ipairs(bg:GetDescendants()) do
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			TweenService:Create(d, TweenInfo.new(0.5), { TextTransparency = 1, TextStrokeTransparency = 1, BackgroundTransparency = 1 }):Play()
		elseif d:IsA("Frame") then
			TweenService:Create(d, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
		elseif d:IsA("UIStroke") then
			TweenService:Create(d, TweenInfo.new(0.5), { Transparency = 1 }):Play()
		end
	end
	task.delay(0.6, function()
		conn:Disconnect()
		gui:Destroy()
	end)
end
skip.Activated:Connect(function()
	clickS:Play()
	close()
end)
skip.MouseEnter:Connect(function()
	TweenService:Create(skip, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(255, 225, 110), Size = UDim2.fromOffset(184, 56) }):Play()
end)
skip.MouseLeave:Connect(function()
	TweenService:Create(skip, TweenInfo.new(0.15), { BackgroundColor3 = Color3.fromRGB(255, 200, 50), Size = UDim2.fromOffset(170, 52) }):Play()
end)

task.delay(1.5, function()
	if not done then
		skip.Visible = true -- se puede saltar enseguida
		skip.Position = UDim2.new(1, -28, 1, 40)
		TweenService:Create(skip, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Position = UDim2.new(1, -28, 1, -28) }):Play()
	end
end)

local shown = 0
local maxQueue = 1
local tipAt = os.clock()
while not done do
	local q = ContentProvider.RequestQueueSize
	maxQueue = math.max(maxQueue, q)
	local loaded = game:IsLoaded()
	local target = loaded and (1 - q / maxQueue) or math.min(0.6, (os.clock() - t0) / 12)
	if loaded and q == 0 then
		target = 1
	end
	shown += (target - shown) * 0.15
	fill.Size = UDim2.fromScale(math.clamp(shown, 0.02, 1), 1)
	pct.Text = L("Cargando el mapa… ", "Loading the map… ") .. math.floor(shown * 100) .. "%"
	if os.clock() - tipAt > 3.5 then
		tipAt = os.clock()
		tipI = tipI % #TIPS + 1
		tip.Text = TIPS[tipI]
	end
	-- listo: mapa cargado y personaje dentro (o máximo 25 s)
	local char = player.Character
	if (shown > 0.97 and char and char:FindFirstChild("HumanoidRootPart") and os.clock() - t0 > 4) or os.clock() - t0 > 25 then
		pct.Text = L("¡Listo!", "Ready!")
		task.wait(0.6)
		close()
	end
	task.wait(0.1)
end
