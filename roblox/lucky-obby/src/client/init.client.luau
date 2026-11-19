-- Lucky Obby Race — cliente: pantalla, lucky block, usar objetos, efectos y el mundo que se mueve
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local LocalizationService = game:GetService("LocalizationService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Locale = require(Shared:WaitForChild("Locale"))
pcall(function()
	Locale.detect(LocalizationService.RobloxLocaleId)
end)
local t = Locale.t
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Use = Remotes:WaitForChild("Use")

local state = { state = "waiting", left = 0, rank = 0, total = 0 }
local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 210, 63)

---------------------------------------------------------------------
-- Ayudantes de interfaz
---------------------------------------------------------------------
local function new(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
	if props and props.Parent then
		o.Parent = props.Parent
	end
	return o
end
local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 12) })
end
local function stroke(c, th)
	return new("UIStroke", { Color = c or Color3.fromRGB(20, 12, 36), Thickness = th or 3 })
end
local function label(props)
	local l = new("TextLabel", { BackgroundTransparency = 1, Font = Enum.Font.FredokaOne, TextScaled = true, TextColor3 = props.TextColor3 or WHITE, Text = props.Text or "", Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.new(), ZIndex = props.ZIndex or 2, Parent = props.Parent })
	new("UIStroke", { Color = Color3.fromRGB(20, 12, 36), Thickness = 3, Parent = l })
	return l
end
local function bump(gui, k)
	local sc = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = gui })
	sc.Scale = k or 1.2
	TweenService:Create(sc, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local gui = new("ScreenGui", { Name = "LuckyHUD", ResetOnSpawn = false, IgnoreGuiInset = false, Parent = player:WaitForChild("PlayerGui") })
local uiScale = new("UIScale", { Parent = gui })
local function rescale()
	local h = workspace.CurrentCamera and workspace.CurrentCamera.ViewportSize.Y or 720
	uiScale.Scale = math.clamp(h / 760, 0.55, 1)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local function sound(id, vol, speed)
	local s = new("Sound", { SoundId = id, Volume = vol or 0.5, PlaybackSpeed = speed or 1, Parent = SoundService })
	return s
end
local SFX = {
	click = sound("rbxasset://sounds/electronicpingshort.wav", 0.3, 1.4),
	pop = sound("rbxasset://sounds/action_jump.mp3", 0.45, 1.3),
	whoosh = sound("rbxasset://sounds/swordslash.wav", 0.5, 0.8),
	reward = sound("rbxasset://sounds/electronicpingshort.wav", 0.6, 0.8),
	hit = sound("rbxasset://sounds/collide.wav", 0.8, 0.9),
}
local function play(name, pitch)
	local s = SFX[name]
	if s then
		s.PlaybackSpeed = pitch or s.PlaybackSpeed
		s:Play()
	end
end

-- Arriba: estado de la ronda · debajo: barra de progreso
local top = new("Frame", { BackgroundColor3 = Color3.fromRGB(30, 22, 54), BackgroundTransparency = 0.15, Size = UDim2.fromOffset(560, 60), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0), Parent = gui }, { corner(18), stroke(GOLD, 3) })
local topLabel = label({ Parent = top, Size = UDim2.new(1, -24, 1, -10), Position = UDim2.fromOffset(12, 5) })
local barBack = new("Frame", { BackgroundColor3 = Color3.fromRGB(30, 22, 54), Size = UDim2.fromOffset(520, 12), Position = UDim2.new(0.5, 0, 0, 78), AnchorPoint = Vector2.new(0.5, 0), Visible = false, Parent = gui }, { corner(6), stroke(WHITE, 2) })
local barFill = new("Frame", { BackgroundColor3 = Color3.fromRGB(110, 255, 150), Size = UDim2.fromScale(0, 1), Parent = barBack }, { corner(6) })
-- Centro: avisos grandes
local big = label({ Parent = gui, Size = UDim2.fromOffset(900, 110), Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 5 })
local function shout(text, color, seconds)
	big.Text = text
	big.TextColor3 = color or WHITE
	big.Visible = true
	bump(big, 1.5)
	local my = text
	task.delay(seconds or 1.6, function()
		if big.Text == my then
			big.Visible = false
		end
	end)
end
big.Visible = false
-- Avisos pequeños
local feed = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(520, 200), Position = UDim2.new(0.5, 0, 0, 100), AnchorPoint = Vector2.new(0.5, 0), Parent = gui }, { new("UIListLayout", { Padding = UDim.new(0, 6), HorizontalAlignment = Enum.HorizontalAlignment.Center }) })
local function toast(text, color)
	local l = label({ Parent = feed, Text = text, Size = UDim2.fromOffset(520, 34), TextColor3 = color or WHITE, ZIndex = 4 })
	task.delay(3, function()
		TweenService:Create(l, TweenInfo.new(0.4), { TextTransparency = 1 }):Play()
		task.wait(0.45)
		l:Destroy()
	end)
end

-- Abajo a la derecha: el objeto (botón grande para usarlo)
local itemBtn = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(40, 30, 70), Size = UDim2.fromOffset(150, 150), Position = UDim2.new(1, -24, 1, -190), AnchorPoint = Vector2.new(1, 1), Parent = gui }, { corner(30), stroke(GOLD, 4) })
local itemIcon = label({ Parent = itemBtn, Size = UDim2.new(1, -30, 1, -50), Position = UDim2.fromOffset(15, 8), ZIndex = 3 })
local itemName = label({ Parent = itemBtn, Size = UDim2.new(1, -10, 0, 30), Position = UDim2.new(0, 5, 1, -38), ZIndex = 3 })
local keyHint = label({ Parent = itemBtn, Text = "E", Size = UDim2.fromOffset(36, 36), Position = UDim2.new(0, -12, 0, -12), TextColor3 = GOLD, ZIndex = 4 })
keyHint.Visible = UserInputService.KeyboardEnabled

---------------------------------------------------------------------
-- Lucky block: la caja gira pasando objetos y se para en el tuyo
---------------------------------------------------------------------
local rolling = false
local function rollAnim(final, seconds)
	rolling = true
	shout(t("lucky"), GOLD, 1)
	play("pop", 1.1)
	local t0 = os.clock()
	local i = 0
	while os.clock() - t0 < seconds do
		i += 1
		local it = Config.ITEMS[(i % #Config.ITEMS) + 1]
		itemIcon.Text = it.icon
		itemName.Text = ""
		itemBtn.Rotation = math.sin(i) * 8
		play("click", 1 + (os.clock() - t0) / seconds)
		task.wait(0.05 + 0.12 * ((os.clock() - t0) / seconds) ^ 2)
	end
	itemBtn.Rotation = 0
	local it = Config.ITEM_BY_ID[final]
	if it then
		itemIcon.Text = it.icon
		itemName.Text = Locale.name(it)
		itemBtn.BackgroundColor3 = it.color:Lerp(Color3.fromRGB(30, 20, 50), 0.55)
		-- rareza: de raro para arriba se anuncia en grande con su color
		local rr = Config.RARITY and Config.RARITY[it.rarity or 1]
		if rr and (it.rarity or 1) >= 2 then
			local stars = string.rep("⭐", it.rarity - 1)
			shout(stars .. " " .. string.upper(Locale.lang() == "es" and rr.es or rr.en) .. " " .. stars, rr.color, it.rarity >= 4 and 2 or 1.2)
			if it.rarity >= 4 then
				play("reward", 0.8)
			end
		end
	end
	bump(itemBtn, 1.35)
	play("reward", 1.2)
	rolling = false
end

-- Punto al que apuntas: ratón en PC, centro de la cámara en móvil y mando
local function aimPoint()
	local cam = workspace.CurrentCamera
	if UserInputService.MouseEnabled and not UserInputService.TouchEnabled then
		local m = UserInputService:GetMouseLocation()
		local ray = cam:ViewportPointToRay(m.X, m.Y)
		local params = RaycastParams.new()
		params.FilterDescendantsInstances = { player.Character }
		params.FilterType = Enum.RaycastFilterType.Exclude
		local hit = workspace:Raycast(ray.Origin, ray.Direction * 300, params)
		return hit and hit.Position or (ray.Origin + ray.Direction * 120)
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local look = cam.CFrame.LookVector
	local from = hrp and hrp.Position or cam.CFrame.Position
	return from + Vector3.new(look.X, 0, look.Z).Unit * 60 + Vector3.new(0, 2, 0)
end

local function useItem()
	if not state.item or rolling or not state.racing then
		return false
	end
	Use:FireServer(aimPoint())
	play("whoosh", 1.2)
	bump(itemBtn, 0.8)
	return true
end
itemBtn.Activated:Connect(useItem)
ContextActionService:BindAction("LuckyUse", function(_, st)
	if st == Enum.UserInputState.Begin and useItem() then
		return Enum.ContextActionResult.Sink
	end
	return Enum.ContextActionResult.Pass
end, false, Enum.KeyCode.E, Enum.KeyCode.ButtonR2, Enum.KeyCode.ButtonX)

---------------------------------------------------------------------
-- Mensajes del servidor
---------------------------------------------------------------------
local frozenUntil = 0
local iceCC = new("ColorCorrectionEffect", { TintColor = WHITE, Parent = game:GetService("Lighting") })

Remotes:WaitForChild("Knock").OnClientEvent:Connect(function(vel)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum and typeof(vel) == "Vector3" then
		hum.PlatformStand = true
		hrp.AssemblyLinearVelocity = vel
		hrp.AssemblyAngularVelocity = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5) * 8
		play("hit", 1)
		task.delay(0.7, function()
			if hum.Parent then
				hum.PlatformStand = false
				hrp.AssemblyAngularVelocity = Vector3.zero
				hum:ChangeState(Enum.HumanoidStateType.GettingUp)
			end
		end)
	end
end)

Remotes:WaitForChild("Event").OnClientEvent:Connect(function(kind, d)
	d = type(d) == "table" and d or {}
	if kind == "launch" and typeof(d.vel) == "Vector3" then -- supersalto (sin caerse)
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if hrp and hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			hrp.AssemblyLinearVelocity = d.vel
			play("whoosh", 0.9)
		end
	elseif kind == "toast" then -- avisos del vestíbulo y de los objetos
		toast(tostring(d.text or ""), Color3.fromRGB(140, 255, 160))
		play("pop", 1.1)
	elseif kind == "lucky" then
		task.spawn(rollAnim, d.item, d.roll or 1)
	elseif kind == "hitBy" then
		local it = Config.ITEM_BY_ID[d.item]
		toast(t("hitBy", d.name or "?", it and (it.icon .. " " .. Locale.name(it)) or "?"), Color3.fromRGB(255, 120, 120))
	elseif kind == "youHit" then
		toast(t("youHit", d.name or "?"), Color3.fromRGB(120, 255, 150))
		play("reward", 1.5)
	elseif kind == "blocked" then
		shout(t("blocked"), Color3.fromRGB(120, 220, 255), 1)
	elseif kind == "shieldOn" then
		toast(t("shieldOn"), Color3.fromRGB(120, 220, 255))
	elseif kind == "swapped" then
		shout(t("swapped", d.name or "?"), Color3.fromRGB(210, 140, 255), 1.4)
	elseif kind == "frozen" then
		if d.by ~= player.UserId then
			frozenUntil = os.clock() + (d.time or 2)
			iceCC.TintColor = Color3.fromRGB(170, 220, 255)
			shout(t("frozen", d.name or "?"), Color3.fromRGB(170, 230, 255), d.time or 2)
		end
	elseif kind == "slipped" then
		toast(t("slipped"), Color3.fromRGB(255, 220, 90))
	elseif kind == "checkpoint" then
		toast(t("checkpoint"), Color3.fromRGB(110, 255, 150))
		play("reward", 1.3)
	elseif kind == "finished" then
		shout(t("finishedPos", d.place or "?"), GOLD, 3)
		toast(t("coins", d.coins or 0), GOLD)
		play("reward", 0.8)
	elseif kind == "winner" then
		toast(t("winner", d.name or "?"), GOLD)
	elseif kind == "results" then
		local lines = { t("results") }
		for i, r in ipairs(d.list or {}) do
			if i > 5 then
				break
			end
			table.insert(lines, string.format("%d. %s", r.rank or i, r.name or "?"))
		end
		shout(table.concat(lines, "\n"), WHITE, 5)
		big.Size = UDim2.fromOffset(700, 320)
		task.delay(5, function()
			big.Size = UDim2.fromOffset(900, 110)
		end)
	elseif kind == "gustFx" and typeof(d.pos) == "Vector3" then
		local p = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, Shape = Enum.PartType.Ball, Size = Vector3.new(4, 4, 4), CFrame = CFrame.new(d.pos), Color = Color3.fromRGB(220, 245, 255), Material = Enum.Material.Neon, Transparency = 0.4, Parent = workspace })
		TweenService:Create(p, TweenInfo.new(0.5), { Size = Vector3.new(40, 40, 40), Transparency = 1 }):Play()
		task.delay(0.55, function()
			p:Destroy()
		end)
	end
end)

local lastStateKey = ""
Remotes:WaitForChild("State").OnClientEvent:Connect(function(s)
	if type(s) ~= "table" then
		return
	end
	state = s
	local left = math.ceil(s.left or 0)
	if s.state == "waiting" then
		topLabel.Text = t("waiting")
	elseif s.state == "break" then -- descanso entre carreras
		topLabel.Text = t("breakTime", left)
	elseif s.state == "joining" then -- inscripción (el botón grande lo pone Extras.client)
		topLabel.Text = t(s.joined and "joinedWait" or "joinOpen", left)
	elseif s.state == "intermission" then
		topLabel.Text = t("nextRace", left)
	elseif s.state == "countdown" and not s.racing then
		topLabel.Text = t("raceOn")
	elseif s.state == "racing" and not s.racing then
		lastStateKey = "go"
		topLabel.Text = t("raceOn")
	elseif s.state == "countdown" then
		local key = "cd" .. left
		if key ~= lastStateKey and left > 0 then
			shout(tostring(left), GOLD, 0.8)
			play("click", 0.8)
		end
		lastStateKey = key
		topLabel.Text = tostring(left)
	elseif s.state == "racing" then
		if lastStateKey ~= "go" then
			lastStateKey = "go"
			if s.racing then
				shout(t("go"), Color3.fromRGB(110, 255, 150), 1)
				play("pop", 0.9)
			end
		end
		local e = math.floor(s.elapsed or 0)
		topLabel.Text = s.racing and t("racing", string.format("%d:%02d", e // 60, e % 60), s.rank or 0, s.total or 0) or t("waiting")
	elseif s.state == "results" then
		lastStateKey = "results"
		topLabel.Text = t("results")
	end
	barBack.Visible = s.racing == true
	barFill.Size = UDim2.fromScale(s.progress or 0, 1)
	if not rolling then
		local it = s.item and Config.ITEM_BY_ID[s.item]
		itemIcon.Text = it and it.icon or "🎁"
		itemName.Text = it and Locale.name(it) or (s.racing and "…" or "")
		itemBtn.BackgroundColor3 = it and it.color:Lerp(Color3.fromRGB(30, 20, 50), 0.55) or Color3.fromRGB(40, 30, 70)
	end
	itemBtn.Visible = s.racing == true and not s.finished
end)

---------------------------------------------------------------------
-- El mundo: obstáculos que se mueven (todos igual, con la hora del servidor) y volver al punto de control
---------------------------------------------------------------------
local spins, moves, pads, kills = {}, {}, {}, {}
local function reg(tag, fn)
	for _, p in ipairs(CollectionService:GetTagged(tag)) do
		fn(p)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(fn)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(p)
		spins[p], moves[p], pads[p], kills[p] = nil, nil, nil, nil
	end)
end
reg("Spin", function(p)
	spins[p] = { base = p:GetAttribute("BaseCF") or p.CFrame, speed = p:GetAttribute("Speed") or 2 }
end)
reg("Move", function(p)
	moves[p] = { base = p:GetAttribute("BaseCF") or p.CFrame, amp = p:GetAttribute("Amp") or 5, period = p:GetAttribute("Period") or 3, phase = p:GetAttribute("Phase") or 0 }
end)
reg("JumpPad", function(p)
	pads[p] = p:GetAttribute("Power") or 80
end)
reg("Kill", function(p)
	kills[p] = true
end)
reg("Belt", function(p)
	local v = p:GetAttribute("Belt")
	if typeof(v) == "Vector3" then
		p.AssemblyLinearVelocity = v
	end
end)

local lastRespawn, lastPad = 0, 0
local function respawn()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local cp = player:GetAttribute("Checkpoint")
	if not hrp or typeof(cp) ~= "Vector3" or os.clock() - lastRespawn < 0.6 then
		return
	end
	lastRespawn = os.clock()
	hrp.AssemblyLinearVelocity = Vector3.zero
	char:PivotTo(CFrame.lookAt(cp, cp + Vector3.new(0, 0, 1)))
	play("whoosh", 0.7)
end

local killParams = OverlapParams.new()
killParams.FilterType = Enum.RaycastFilterType.Include
local padParams = OverlapParams.new()
padParams.FilterType = Enum.RaycastFilterType.Include
local listsAt = 0

RunService.Heartbeat:Connect(function()
	local T = workspace:GetServerTimeNow()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local pos = hrp and hrp.Position or Vector3.zero
	for p, it in pairs(spins) do
		if p.Parent then
			p.CFrame = it.base * CFrame.Angles(0, T * it.speed, 0)
		end
	end
	for p, it in pairs(moves) do
		if p.Parent then
			local w = 2 * math.pi / it.period
			p.CFrame = it.base * CFrame.new(it.amp * math.sin(T * w + it.phase), 0, 0)
			p.AssemblyLinearVelocity = it.base.RightVector * (it.amp * w * math.cos(T * w + it.phase))
		end
	end
	if os.clock() > frozenUntil and iceCC.TintColor ~= WHITE then
		iceCC.TintColor = WHITE
	end
	if not hrp or not state.racing or state.finished then
		return
	end
	-- listas para las consultas (se rehacen cada segundo: el recorrido cambia en cada ronda)
	if os.clock() - listsAt > 1 then
		listsAt = os.clock()
		local k, pd = {}, {}
		for p in pairs(kills) do
			if p.Parent then
				table.insert(k, p)
			end
		end
		for p in pairs(pads) do
			if p.Parent then
				table.insert(pd, p)
			end
		end
		killParams.FilterDescendantsInstances = k
		padParams.FilterDescendantsInstances = pd
	end
	-- caída al vacío o lava
	if pos.Y < Config.COURSE.START.Y - Config.COURSE.FALL then
		respawn()
		return
	end
	if #workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, -0.4, 0), Vector3.new(2.2, 5.2, 1.6), killParams) > 0 then
		respawn()
		return
	end
	if os.clock() - lastPad > 0.45 then
		for _, p in ipairs(workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, -3.1, 0), Vector3.new(2.6, 1.6, 2.6), padParams)) do
			lastPad = os.clock()
			local v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, pads[p] or 80, v.Z)
			play("pop", 0.8)
			break
		end
	end
end)

-- Cartel del santuario de la suerte con TU nivel y precio (lo pone el servidor en atributos del jugador)
task.spawn(function()
	local player = game:GetService("Players").LocalPlayer
	while true do
		local hub = workspace:FindFirstChild("Hub")
		local sign = hub and hub:FindFirstChild("LuckSign")
		local gui = sign and sign:FindFirstChildOfClass("BillboardGui")
		local l = gui and gui:FindFirstChild("Label")
		if l then
			local lv = player:GetAttribute("LuckLevel") or 0
			local cost = player:GetAttribute("LuckCost") or -1
			local mult = 1 + lv * Config.LUCK.STEP * 5
			l.Text = string.format('🍀 %s %d <font color="#FFE36B">(x%.1f)</font>\n%s', Locale.lang() == "es" and "SUERTE NV" or "LUCK LV", lv, mult,
				cost >= 0 and string.format("🪙 %d → %s %d", cost, Locale.lang() == "es" and "NV" or "LV", lv + 1) or "MAX")
		end
		task.wait(0.5)
	end
end)
