-- Steal a God ⚡ Roba un Dios — cliente (interfaz, animaciones y efectos)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local LocalizationService = game:GetService("LocalizationService")
local SoundService = game:GetService("SoundService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Locale = require(Shared:WaitForChild("Locale"))
local GodModel = require(Shared:WaitForChild("GodModel"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Action = Remotes:WaitForChild("Action")

local localeId = ""
pcall(function()
	localeId = LocalizationService.RobloxLocaleId
end)
if localeId == "" then
	localeId = player.LocaleId
end
Locale.setSpanish(string.sub(string.lower(localeId), 1, 2) == "es")
local t = Locale.t

local state = { money = 0, speed = 0, income = 0, combo = 1, gods = {}, coaches = {}, auras = {}, passes = {}, altarPacks = {}, cycleLeft = 0 }
local stateAt = os.clock()

---------------------------------------------------------------------
-- Estilo
---------------------------------------------------------------------
local TITLE = Enum.Font.LuckiestGuy
local BTN = Enum.Font.FredokaOne
local BODY = Enum.Font.GothamBlack
local DARK = Color3.fromRGB(18, 12, 38)
local GOLD = Color3.fromRGB(255, 210, 63)
local CYAN = Color3.fromRGB(94, 231, 255)
local PINK = Color3.fromRGB(255, 90, 180)
local GREEN = Color3.fromRGB(80, 230, 130)
local PURPLE = Color3.fromRGB(170, 110, 255)
local WHITE = Color3.new(1, 1, 1)

local function rcolor(r)
	local rr = Config.RARITIES[r]
	if not rr then
		return WHITE
	end
	return rr.id == 10 and Color3.fromRGB(200, 120, 255) or rr.color
end

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
	return new("UICorner", { CornerRadius = UDim.new(0, r or 14) })
end

local function stroke(color, th, tr)
	return new("UIStroke", { Color = color or GOLD, Thickness = th or 2, Transparency = tr or 0, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function textStroke(color, th)
	return new("UIStroke", { Color = color or Color3.fromRGB(10, 6, 24), Thickness = th or 2.5, ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual })
end

local function gradient(c1, c2, rot)
	return new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 90 })
end

local function darker(c, k)
	k = k or 0.55
	return Color3.new(c.R * k, c.G * k, c.B * k)
end

local function label(props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.Font or BTN,
		TextColor3 = props.TextColor3 or WHITE,
		TextScaled = props.TextSize == nil,
		TextSize = props.TextSize or 14,
		RichText = true,
		TextWrapped = true,
		Text = props.Text or "",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		ZIndex = props.ZIndex or 1,
		LayoutOrder = props.LayoutOrder or 0,
		Rotation = props.Rotation or 0,
		Parent = props.Parent,
	})
	if props.Stroke ~= false then
		textStroke(props.StrokeColor, props.StrokeThickness).Parent = l
	end
	return l
end

-- Sonidos sencillos incluidos en Roblox
local function sound(id, vol, speed)
	local s = new("Sound", { SoundId = id, Volume = vol or 0.5, PlaybackSpeed = speed or 1, Parent = SoundService })
	return s
end
local SFX = {
	click = sound("rbxasset://sounds/electronicpingshort.wav", 0.25, 1.4),
	pop = sound("rbxasset://sounds/action_jump.mp3", 0.4, 1.3),
	whoosh = sound("rbxasset://sounds/swordslash.wav", 0.5, 0.8),
	reward = sound("rbxasset://sounds/electronicpingshort.wav", 0.6, 0.8),
}
local function play(name, pitch)
	local s = SFX[name]
	if s then
		s.PlaybackSpeed = pitch or s.PlaybackSpeed
		s:Play()
	end
end

-- Animación de "rebote" al tocar
local function pressable(gui)
	local scale = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = gui })
	local function to(v, style)
		TweenService:Create(scale, TweenInfo.new(0.12, style or Enum.EasingStyle.Quad), { Scale = v }):Play()
	end
	gui.MouseEnter:Connect(function()
		to(1.05)
	end)
	gui.MouseLeave:Connect(function()
		to(1)
	end)
	gui.MouseButton1Down:Connect(function()
		to(0.9)
	end)
	gui.MouseButton1Up:Connect(function()
		TweenService:Create(scale, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	end)
end

local function bump(gui, amount)
	local scale = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = gui })
	scale.Scale = amount or 1.12
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end

local function button(props)
	local base = props.Color or GOLD
	local b = new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = WHITE,
		Font = BTN,
		TextScaled = true,
		Text = props.Text or "",
		TextColor3 = props.TextColor3 or WHITE,
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}, {
		corner(props.Radius or 14),
		gradient(base, darker(base, 0.65), 90),
		stroke(darker(base, 0.4), 3),
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }),
	})
	textStroke(darker(base, 0.3), 2).Parent = b
	pressable(b)
	if props.OnClick then
		b.Activated:Connect(function()
			play("click")
			props.OnClick()
		end)
	end
	return b
end

local function resolveArg(a)
	if type(a) == "table" then
		if a.rarity then
			return string.upper(Locale.name(Config.RARITIES[a.rarity]))
		elseif a.zone then
			return Locale.name(Config.ZONES[a.zone])
		elseif a.guardian then
			return Locale.name(Config.ZONES[a.guardian].guardian)
		elseif a.god then
			local g = Config.GOD_BY_ID[a.god]
			return g and g.name or "?"
		elseif a.myth then
			return Locale.name(Config.MYTHS[a.myth])
		elseif a.weapon then
			return Locale.name(Config.WEAPONS[a.weapon])
		elseif a.stat then
			return t(a.stat == "speed" and "speed" or (a.stat == "money" and "money" or "time"))
		end
		return "?"
	end
	return tostring(a)
end

local function fmtKey(key, args)
	local r = {}
	for i, a in ipairs(args or {}) do
		r[i] = resolveArg(a)
	end
	return t(key, table.unpack(r))
end

-- Vista 3D de un dios
local function godViewport(parent, god, size, pos, z)
	local vp = new("ViewportFrame", {
		BackgroundTransparency = 1,
		Size = size,
		Position = pos or UDim2.new(),
		Ambient = Color3.fromRGB(170, 160, 190),
		LightColor = Color3.fromRGB(255, 245, 230),
		LightDirection = Vector3.new(-0.4, -1, -0.6),
		ZIndex = z or 1,
		Parent = parent,
	})
	local model = GodModel.build(god, rcolor(god.r))
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("PointLight") then
			d:Destroy()
		end
	end
	model.Parent = vp
	local cam = new("Camera", { FieldOfView = 32, Parent = vp })
	vp.CurrentCamera = cam
	local h = 7 * ((god.id == "ymir") and 1.25 or 1)
	cam.CFrame = CFrame.lookAt(Vector3.new(0, h * 0.55, -h * 2.2), Vector3.new(0, h * 0.5, 0))
	return vp, model
end

---------------------------------------------------------------------
-- Pantalla principal
---------------------------------------------------------------------
local gui = new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })
local uiScale = new("UIScale", { Parent = gui })
local function updateScale()
	local cam = workspace.CurrentCamera
	local h = cam and cam.ViewportSize.Y or 720
	uiScale.Scale = math.clamp(h / 760, 0.5, 1)
end
updateScale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(updateScale)

-- Letra gruesa en cursiva con borde negro (como los simuladores)
local HEAVY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local function heavy(props)
	props.StrokeThickness = props.StrokeThickness or 3
	local l = label(props)
	l.FontFace = HEAVY
	return l
end
local pillGradients = {}

-- Abajo a la izquierda: velocidad y dinero
local stats = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(460, 132), Position = UDim2.new(0, 18, 1, -14), AnchorPoint = Vector2.new(0, 1), Parent = gui })
local speedLabel = heavy({ Parent = stats, Size = UDim2.new(1, 0, 0, 44), Position = UDim2.fromOffset(0, 0), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = CYAN })
local moneyLabel = heavy({ Parent = stats, Size = UDim2.new(1, 0, 0, 54), Position = UDim2.fromOffset(0, 44), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GREEN, StrokeThickness = 3.5 })
local multLabel = heavy({ Parent = stats, Size = UDim2.new(1, 0, 0, 24), Position = UDim2.fromOffset(2, 102), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 200, 90), StrokeThickness = 2 })
local moneyPill = moneyLabel
local speedPill = speedLabel

-- Abajo a la derecha: reloj de la noche
local cyclePill = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(250, 62), Position = UDim2.new(1, -18, 1, -150), AnchorPoint = Vector2.new(1, 1), Parent = gui }, {
	corner(16),
	gradient(Color3.fromRGB(40, 30, 90), Color3.fromRGB(14, 10, 34), 90),
	stroke(Color3.fromRGB(170, 140, 255), 3),
})
local cycleIcon = label({ Parent = cyclePill, Text = "🌙", Font = TITLE, Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(8, 8), Stroke = false })
local cycleLabel = heavy({ Parent = cyclePill, Size = UDim2.new(1, -66, 1, -14), Position = UDim2.fromOffset(58, 7), TextXAlignment = Enum.TextXAlignment.Left })

local zoneLabel = heavy({ Parent = gui, Size = UDim2.new(0, 560, 0, 30), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0) })
local carryLabel = heavy({ Parent = gui, Size = UDim2.new(0, 640, 0, 40), Position = UDim2.new(0.5, 0, 0, 44), AnchorPoint = Vector2.new(0.5, 0) })

-- Mensajes cortos que entran deslizando
local toastHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 540, 0, 240), Position = UDim2.new(0.5, 0, 0, 92), AnchorPoint = Vector2.new(0.5, 0), Parent = gui }, {
	new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }),
})
local function toast(text, color)
	color = color or GOLD
	local f = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, 0, 0, 44), Parent = toastHolder }, {
		corner(14),
		gradient(Color3.fromRGB(40, 26, 80), darker(color, 0.3), 0),
		stroke(color, 2.5),
	})
	label({ Parent = f, Text = text, Size = UDim2.new(1, -20, 1, -10), Position = UDim2.fromOffset(10, 5), TextColor3 = WHITE })
	bump(f, 0.6)
	task.delay(3.2, function()
		local sc = f:FindFirstChildOfClass("UIScale")
		if sc then
			TweenService:Create(sc, TweenInfo.new(0.2), { Scale = 0 }):Play()
		end
		task.wait(0.22)
		f:Destroy()
	end)
	local frames = {}
	for _, c in ipairs(toastHolder:GetChildren()) do
		if c:IsA("Frame") then
			table.insert(frames, c)
		end
	end
	if #frames > 4 then
		frames[1]:Destroy()
	end
end

-- Cartel grande
local banner = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, 0, 0, 100), Position = UDim2.new(0, 0, 0.26, 0), Visible = false, ZIndex = 20, Parent = gui }, { stroke(GOLD, 3) })
local bannerGrad = gradient(Color3.new(0, 0, 0), Color3.new(0, 0, 0), 0)
bannerGrad.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.2, 0.25), NumberSequenceKeypoint.new(0.8, 0.25), NumberSequenceKeypoint.new(1, 1) })
bannerGrad.Parent = banner
local bannerLabel = label({ Parent = banner, Font = TITLE, Size = UDim2.new(1, -60, 1, -20), Position = UDim2.fromOffset(30, 10), ZIndex = 21 })
local bannerToken = 0
local function showBanner(text, color)
	bannerToken += 1
	local my = bannerToken
	bannerLabel.Text = text
	bannerLabel.TextColor3 = color or GOLD
	banner:FindFirstChildOfClass("UIStroke").Color = color or GOLD
	banner.Visible = true
	banner.Size = UDim2.new(1, 0, 0, 0)
	TweenService:Create(banner, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Size = UDim2.new(1, 0, 0, 100) }):Play()
	play("whoosh")
	task.delay(4, function()
		if my == bannerToken then
			TweenService:Create(banner, TweenInfo.new(0.25), { Size = UDim2.new(1, 0, 0, 0) }):Play()
			task.wait(0.26)
			if my == bannerToken then
				banner.Visible = false
			end
		end
	end)
end

---------------------------------------------------------------------
-- Paneles
---------------------------------------------------------------------
local side = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 210, 0, 300), Position = UDim2.new(0, 14, 0.4, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = gui }, {
	new("UIListLayout", { Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center }),
})

local panel = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromScale(0.64, 0.74), Position = UDim2.fromScale(0.5, 0.53), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 10, Parent = gui }, {
	corner(24),
	gradient(Color3.fromRGB(52, 30, 110), Color3.fromRGB(14, 10, 32), 90),
	new("UISizeConstraint", { MinSize = Vector2.new(360, 300), MaxSize = Vector2.new(880, 640) }),
})
local panelStroke = stroke(GOLD, 4)
panelStroke.Parent = panel
local panelScale = new("UIScale", { Parent = panel })
local panelTitle = label({ Parent = panel, Font = TITLE, Size = UDim2.new(1, -130, 0, 48), Position = UDim2.fromOffset(18, 10), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, ZIndex = 11 })
local titleGrad = gradient(GOLD, Color3.fromRGB(255, 130, 60), 90)
titleGrad.Parent = panelTitle
local tabs = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -36, 0, 42), Position = UDim2.fromOffset(18, 62), ZIndex = 11, Parent = panel }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
})
local content = new("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, -122), Position = UDim2.fromOffset(18, 112), ScrollBarThickness = 8, ScrollBarImageColor3 = GOLD, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 11, Parent = panel })

local function closePanel()
	TweenService:Create(panelScale, TweenInfo.new(0.15), { Scale = 0.7 }):Play()
	task.delay(0.15, function()
		panel.Visible = false
	end)
end
button({ Parent = panel, Text = "✕", Size = UDim2.fromOffset(50, 50), Position = UDim2.new(1, -60, 0, 10), Color = Color3.fromRGB(255, 70, 100), ZIndex = 12, Radius = 25, OnClick = closePanel })

local currentPanel, currentTab = nil, nil
local renderers = {}
local signatures = {}

local function clearContent()
	for _, c in ipairs(content:GetChildren()) do
		c:Destroy()
	end
end

local function render(force)
	if not panel.Visible or not currentPanel then
		return
	end
	local sigFn = signatures[currentPanel]
	local sig = sigFn and sigFn(currentTab) or tostring(os.clock())
	if not force and content:GetAttribute("Sig") == sig then
		return
	end
	content:SetAttribute("Sig", sig)
	local pos = content.CanvasPosition
	clearContent()
	renderers[currentPanel](currentTab)
	content.CanvasPosition = pos
end

local tabList = {}
local function setTabs(list)
	tabList = list
	for _, c in ipairs(tabs:GetChildren()) do
		if c:IsA("TextButton") then
			c:Destroy()
		end
	end
	for i, tb in ipairs(list) do
		local on = currentTab == tb.id
		button({ Parent = tabs, Text = tb.text, Size = UDim2.new(0, 180, 1, 0), LayoutOrder = i, ZIndex = 12, Color = on and GOLD or Color3.fromRGB(80, 60, 140), OnClick = function()
			currentTab = tb.id
			setTabs(list)
			content.CanvasPosition = Vector2.zero
			render(true)
		end })
	end
end

local function openPanel(name, title, list, color)
	if panel.Visible and currentPanel == name then
		closePanel()
		return
	end
	currentPanel = name
	currentTab = list and list[1].id or nil
	panelTitle.Text = title
	panelStroke.Color = color or GOLD
	setTabs(list or {})
	panel.Visible = true
	panelScale.Scale = 0.6
	TweenService:Create(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	play("pop")
	content.CanvasPosition = Vector2.zero
	render(true)
end

local function listLayout()
	new("UIListLayout", { Padding = UDim.new(0, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), Parent = content })
end

-- Fila: icono, título, subtítulo y botón
local function row(order, icon, title, subtitle, btnText, btnColor, enabled, onClick, accent)
	accent = accent or Color3.fromRGB(120, 100, 200)
	local f = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, -14, 0, 82), LayoutOrder = order, ZIndex = 11, Parent = content }, {
		corner(16),
		gradient(darker(accent, 0.45), Color3.fromRGB(26, 18, 50), 0),
		stroke(accent, 2.5),
	})
	local ic = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(62, 62), Position = UDim2.fromOffset(10, 10), ZIndex = 12, Parent = f }, { corner(14), gradient(accent, darker(accent, 0.5), 90) })
	label({ Parent = ic, Text = icon, Font = TITLE, Size = UDim2.new(1, -10, 1, -10), Position = UDim2.fromOffset(5, 5), ZIndex = 13, Stroke = false })
	label({ Parent = f, Font = TITLE, Text = title, Size = UDim2.new(0.6, -90, 0, 36), Position = UDim2.fromOffset(84, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, ZIndex = 12 })
	label({ Parent = f, Font = BTN, Text = subtitle, Size = UDim2.new(0.6, -90, 0, 26), Position = UDim2.fromOffset(84, 46), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(215, 205, 245), ZIndex = 12 })
	if btnText then
		local b = button({ Parent = f, Text = btnText, Size = UDim2.new(0.38, -14, 1, -22), Position = UDim2.new(0.62, 0, 0, 11), Color = enabled and (btnColor or GREEN) or Color3.fromRGB(90, 88, 110), ZIndex = 12, OnClick = (enabled and onClick) and function()
			onClick()
		end or nil })
		if not enabled then
			b.AutoButtonColor = false
		end
	end
	return f
end

local function sectionTitle(order, text, color)
	local l = label({ Parent = content, Font = TITLE, Text = text, Size = UDim2.new(1, -14, 0, 36), LayoutOrder = order, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = color or GOLD, ZIndex = 11 })
	return l
end

---------------------------------------------------------------------
-- Tienda
---------------------------------------------------------------------
local function moneyBucket()
	return math.floor(math.log10(math.max(1, state.money or 0)) * 20)
end

signatures.shop = function(tab)
	return table.concat({ tab, moneyBucket(), state.treadmill or 0, state.plot or 0, state.altarsBought or 0, state.aura or "", tostring(state.queue) }, "|") .. (function()
		local s = ""
		for k, v in pairs(state.coaches or {}) do
			s ..= k .. v
		end
		for k in pairs(state.auras or {}) do
			s ..= k
		end
		return s
	end)()
end

renderers.shop = function(tab)
	listLayout()
	if tab == "up" then
		local tm = state.treadmill or 1
		local tmMax = tm >= Config.TREADMILL_MAX
		local tmCost = not tmMax and Config.treadmillCost(tm + 1) or 0
		row(1, "🏃", string.format("%s · %s %d", t("treadmill"), t("level"), tm), string.format("⚡ +%s/s → +%s/s", Format.num(Config.treadmillGain(tm)), tmMax and "—" or Format.num(Config.treadmillGain(tm + 1))), tmMax and t("max") or ("💰 " .. Format.num(tmCost)), CYAN, not tmMax and state.money >= tmCost, function()
			Action:FireServer("buyTreadmill")
		end, CYAN)
		local pl = state.plot or 1
		local plMax = pl >= Config.PLOT_MAX
		local plCost = not plMax and Config.plotCost(pl + 1) or 0
		row(2, "🏛️", string.format("%s · %s %d", t("plot"), t("level"), pl), string.format("%d %s → %d", Config.pedestalsFor(pl), t("pedestals"), plMax and Config.pedestalsFor(pl) or Config.pedestalsFor(pl + 1)), plMax and t("max") or ("💰 " .. Format.num(plCost)), GOLD, not plMax and state.money >= plCost, function()
			Action:FireServer("buyPlot")
		end, GOLD)
		local al = state.altarsBought or Config.ALTARS_BASE
		local alMax = al >= Config.ALTARS_MAX
		local alCost = not alMax and Config.altarCost(al + 1) or 0
		row(3, "🔮", string.format("%s · %d / %d", t("altar"), al, Config.ALTARS_MAX), string.format("%s: %d", t("queue"), state.queue or 0), alMax and t("max") or ("💰 " .. Format.num(alCost)), PURPLE, not alMax and state.money >= alCost, function()
			Action:FireServer("buyAltar")
		end, PURPLE)
	elseif tab == "coach" then
		local order = 0
		local tierColors = { CYAN, GOLD, PINK, Color3.fromRGB(120, 255, 120) }
		for _, co in ipairs(Config.COACHES) do
			order += 1
			row(order, "🏋️", Locale.name(co), string.format("+%d%% ⚡", co.bonus * 100), "💰 " .. Format.num(co.cost), CYAN, state.money >= co.cost, function()
				Action:FireServer("buyCoach", co.id)
			end, CYAN)
			for tier, tierInfo in ipairs(Config.COACH_TIERS) do
				local count = state.coaches[co.id .. ":" .. tier] or 0
				if count > 0 then
					order += 1
					local canFuse = count >= 2 and tier < #Config.COACH_TIERS
					row(order, "⭐", string.format("%s %s ×%d", Locale.name(co), Locale.name(tierInfo), count), string.format("+%s%% ⚡", Format.num(co.bonus * tierInfo.mult * 100)), canFuse and t("fuse") or nil, PINK, canFuse, function()
						Action:FireServer("fuseCoach", co.id, tier)
					end, tierColors[tier])
				end
			end
		end
	elseif tab == "aura" then
		for i, a in ipairs(Config.AURAS) do
			local owned = state.auras[a.id]
			local eq = state.aura == a.id
			local eff = {}
			if a.speed then
				table.insert(eff, string.format("+%d%% ⚡", a.speed * 100))
			end
			if a.money then
				table.insert(eff, string.format("+%d%% 💰", a.money * 100))
			end
			local txt = eq and t("equipped") or (owned and t("equip") or ("💰 " .. Format.num(a.cost)))
			row(i, "✨", Locale.name(a), table.concat(eff, "  "), txt, eq and Color3.fromRGB(90, 88, 110) or a.color, (owned and not eq) or (not owned and state.money >= a.cost), function()
				Action:FireServer(owned and "equipAura" or "buyAura", a.id)
			end, a.color)
		end
	end
end

---------------------------------------------------------------------
-- Robux
---------------------------------------------------------------------
signatures.robux = function(tab)
	local s = tab
	for k, v in pairs(state.passes or {}) do
		s ..= k .. tostring(v)
	end
	return s
end

renderers.robux = function(tab)
	listLayout()
	local green = Color3.fromRGB(80, 220, 120)
	if tab == "passes" then
		local order = 0
		local icons = { speed2x = "⚡", money2x = "💰", autoTreadmill = "🏃", luck2x = "🍀", moreSlots = "📦", vip = "👑" }
		for key, p in pairs(Config.PASSES) do
			order += 1
			local owned = state.passes[key]
			local available = p.id ~= 0
			row(order, icons[key] or "💎", Locale.name(p), string.format("R$ %d", p.price), owned and t("owned") or (available and ("R$ " .. p.price) or t("soon")), green, available and not owned, function()
				MarketplaceService:PromptGamePassPurchase(player, p.id)
			end, Color3.fromRGB(120, 255, 160))
		end
	else
		local order = 0
		local icons = { speedBoost = "⚡", serverLuck = "🍀", serverNight = "🌙", openNowLow = "📦", openNowMid = "🎁", openNowHigh = "💎", instantUpgrade = "🏛️", divineShield = "🛡️", moneySmall = "💵", moneyBig = "💰", savePack = "🆘" }
		for _, key in ipairs({ "speedBoost", "serverLuck", "serverNight", "openNowLow", "openNowMid", "openNowHigh", "instantUpgrade", "divineShield", "moneySmall", "moneyBig", "savePack" }) do
			local p = Config.PRODUCTS[key]
			order += 1
			local available = p.id ~= 0
			row(order, icons[key] or "🛒", Locale.name(p), string.format("R$ %d", p.price), available and ("R$ " .. p.price) or t("soon"), green, available, function()
				MarketplaceService:PromptProductPurchase(player, p.id)
			end, Color3.fromRGB(255, 200, 90))
		end
	end
end

---------------------------------------------------------------------
-- Índice (cartas con el dios en 3D)
---------------------------------------------------------------------
local function ownedCount()
	local n = 0
	for _, g in ipairs(Config.GODS) do
		if (state.gods[g.id] or 0) > 0 then
			n += 1
		end
	end
	return n
end

signatures.index = function(tab)
	local s = tab
	for _, g in ipairs(Config.GODS) do
		s ..= (state.gods[g.id] or 0)
	end
	return s
end

renderers.index = function(tab)
	if tab == "gods" then
		new("UIGridLayout", { CellSize = UDim2.fromOffset(126, 172), CellPadding = UDim2.fromOffset(10, 10), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
		for i, g in ipairs(Config.GODS) do
			local count = state.gods[g.id] or 0
			local rc = rcolor(g.r)
			local owned = count > 0
			local card = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, LayoutOrder = i, ZIndex = 11, Parent = content }, {
				corner(14),
				gradient(owned and darker(rc, 0.85) or Color3.fromRGB(40, 36, 56), owned and darker(rc, 0.3) or Color3.fromRGB(20, 18, 30), 90),
				stroke(rc, owned and 3 or 1.5, owned and 0 or 0.5),
			})
			label({ Parent = card, Font = BTN, Text = Locale.name(Config.RARITIES[g.r]), Size = UDim2.new(1, -8, 0, 18), Position = UDim2.fromOffset(4, 4), TextColor3 = rc, ZIndex = 12 })
			if owned then
				godViewport(card, g, UDim2.new(1, -8, 0, 108), UDim2.fromOffset(4, 22), 12)
				pressable(card)
				card.Activated:Connect(function()
					play("click")
					toast(g.name .. ": " .. (Locale.lang() == "es" and g.factEs or g.factEn), rc)
				end)
			else
				label({ Parent = card, Font = TITLE, Text = "?", Size = UDim2.new(1, -8, 0, 90), Position = UDim2.fromOffset(4, 30), TextColor3 = Color3.fromRGB(90, 85, 120), ZIndex = 12 })
			end
			label({ Parent = card, Font = TITLE, Text = owned and g.name or "???", Size = UDim2.new(1, -8, 0, 24), Position = UDim2.new(0, 4, 1, -46), TextColor3 = owned and WHITE or Color3.fromRGB(120, 115, 150), ZIndex = 12 })
			label({ Parent = card, Font = BTN, Text = owned and ("×" .. count) or "", Size = UDim2.new(1, -8, 0, 18), Position = UDim2.new(0, 4, 1, -22), TextColor3 = GOLD, ZIndex = 12 })
		end
	elseif tab == "rewards" then
		listLayout()
		local n = ownedCount()
		sectionTitle(0, "📖 " .. t("indexProgress", n, #Config.GODS))
		for i, rw in ipairs(Config.INDEX_REWARDS) do
			local parts = {}
			if rw.money then
				table.insert(parts, string.format("+%d%% 💰", rw.money * 100))
			end
			if rw.speed then
				table.insert(parts, string.format("+%d%% ⚡", rw.speed * 100))
			end
			if rw.moneyMult then
				table.insert(parts, string.format("x%d 💰", rw.moneyMult))
			end
			if rw.speedMult then
				table.insert(parts, string.format("x%d ⚡", rw.speedMult))
			end
			local done = n >= rw.count
			row(i, done and "✅" or "🔒", string.format("%d %s", rw.count, Locale.lang() == "es" and "dioses" or "gods"), table.concat(parts, "  "), nil, nil, false, nil, done and GREEN or Color3.fromRGB(110, 100, 160))
		end
		local order = 100
		sectionTitle(order, "⚔️ " .. (Locale.lang() == "es" and "Mitologías y armas" or "Mythologies & weapons"), PINK)
		for key, myth in pairs(Config.MYTHS) do
			local total, have = 0, 0
			for _, g in ipairs(Config.GODS) do
				if g.myth == key then
					total += 1
					if (state.gods[g.id] or 0) > 0 then
						have += 1
					end
				end
			end
			order += 1
			local w = Config.WEAPONS[myth.weapon]
			row(order, have >= total and "✅" or "🏛️", string.format("%s · %d/%d", Locale.name(myth), have, total), string.format("%s · x%s · +%d%%", Locale.name(w), tostring(w.power), myth.bonus * 100), nil, nil, false, nil, have >= total and GREEN or w.color)
		end
	elseif tab == "odds" then
		listLayout()
		for zi, zone in ipairs(Config.ZONES) do
			sectionTitle(zi * 100, string.format("%s %d · %s", t("zone"), zi, Locale.name(zone)), CYAN)
			local total = 0
			for _, w in pairs(zone.weights) do
				total += w
			end
			local order = zi * 100
			for r = 1, #Config.RARITIES do
				local chance = zone.weights[r] and zone.weights[r] / total or nil
				if not chance and zi >= 3 then
					for _, u in ipairs(Config.ULTRA) do
						if u.r == r then
							chance = (zi / 6) / u.oneIn
						end
					end
				end
				if chance then
					order += 1
					local txt = chance >= 0.001 and string.format("%.2f%%", chance * 100) or Format.oneIn(chance)
					label({ Parent = content, LayoutOrder = order, Size = UDim2.new(1, -14, 0, 26), Font = BTN, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rcolor(r), Text = string.format("   ◆ %s — %s", Locale.name(Config.RARITIES[r]), txt), ZIndex = 11 })
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- Botones laterales con iconos que flotan
---------------------------------------------------------------------
local floaters = {}
local badges = {}
local function sideButton(order, emoji, text, color, onClick)
	local b = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, Size = UDim2.fromOffset(200, 60), LayoutOrder = order, Parent = side }, {
		corner(16),
		gradient(color, darker(color, 0.45), 100),
		stroke(darker(color, 0.25), 3.5),
	})
	pressable(b)
	local iconBg = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(52, 52), Position = UDim2.fromOffset(4, 4), Parent = b }, { corner(14), gradient(WHITE, darker(color, 0.8), 90) })
	local icon = label({ Parent = iconBg, Text = emoji, Font = TITLE, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4), Stroke = false })
	heavy({ Parent = b, Text = string.upper(text), Size = UDim2.new(1, -70, 1, -14), Position = UDim2.fromOffset(64, 7), TextXAlignment = Enum.TextXAlignment.Left })
	local badge = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 50, 70), Size = UDim2.fromOffset(58, 22), Position = UDim2.new(1, -40, 0, -10), Visible = false, ZIndex = 3, Parent = b }, { corner(11), stroke(WHITE, 2) })
	heavy({ Parent = badge, Text = t("new"), Size = UDim2.new(1, -6, 1, -4), Position = UDim2.fromOffset(3, 2), ZIndex = 4, StrokeThickness = 1.5 })
	badges[order] = badge
	table.insert(floaters, { gui = icon, phase = order })
	b.Activated:Connect(function()
		play("click")
		onClick()
	end)
	return b
end

sideButton(2, "📖", t("index"), GOLD, function()
	openPanel("index", "📖 " .. t("indexTitle"), { { id = "gods", text = t("index") }, { id = "rewards", text = "🎁" }, { id = "odds", text = "🎲 " .. t("odds") } }, GOLD)
end)
sideButton(1, "🛒", t("shop"), Color3.fromRGB(255, 80, 60), function()
	openPanel("shop", "🛒 " .. t("shop"), { { id = "up", text = t("upgrades") }, { id = "coach", text = t("coaches") }, { id = "aura", text = t("auras") } }, CYAN)
end)
sideButton(3, "💎", t("robux"), GREEN, function()
	openPanel("robux", "💎 Robux", { { id = "passes", text = t("passes") }, { id = "products", text = t("products") } }, GREEN)
end)
local afkButton = sideButton(4, "💤", t("afk"), PURPLE, function()
	Action:FireServer("afk", not state.afk)
end)

---------------------------------------------------------------------
-- Minijuego de la cinta (combo)
---------------------------------------------------------------------
local tread = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(0, 440, 0, 160), Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1), Visible = false, Parent = gui }, {
	corner(20),
	gradient(Color3.fromRGB(20, 60, 90), Color3.fromRGB(14, 12, 40), 90),
	stroke(CYAN, 3),
})
local comboLabel = label({ Parent = tread, Font = TITLE, Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 6), TextColor3 = CYAN })
local bar = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, -40, 0, 28), Position = UDim2.fromOffset(20, 44), Parent = tread }, { corner(14), gradient(Color3.fromRGB(50, 40, 90), Color3.fromRGB(30, 26, 60), 0) })
local target = new("Frame", { BackgroundColor3 = GREEN, Size = UDim2.new(0.18, 0, 1, 0), Parent = bar }, { corner(14), stroke(WHITE, 2, 0.4) })
local marker = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(0, 10, 1, 12), Position = UDim2.new(0, 0, 0, -6), Parent = bar }, { corner(5), stroke(DARK, 2) })
local targetCenter, targetWidth = 0.5, 0.18
local tapButton = button({ Parent = tread, Text = t("tap"), Size = UDim2.new(1, -40, 0, 60), Position = UDim2.fromOffset(20, 84), Color = CYAN })
tapButton.Font = TITLE
local Combo = Remotes:WaitForChild("Combo")
local function markerPos()
	return (math.sin(os.clock() * 2.6) + 1) / 2
end
local function floatText(text, color, parent, pos)
	local l = label({ Parent = parent or gui, Font = TITLE, Text = text, TextColor3 = color, Size = UDim2.fromOffset(200, 44), Position = pos or UDim2.new(0.5, -100, 1, -200), ZIndex = 25 })
	TweenService:Create(l, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { Position = l.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 }):Play()
	local st = l:FindFirstChildOfClass("UIStroke")
	if st then
		TweenService:Create(st, TweenInfo.new(0.8), { Transparency = 1 }):Play()
	end
	task.delay(0.85, function()
		l:Destroy()
	end)
end
tapButton.Activated:Connect(function()
	local m = markerPos()
	if math.abs(m - targetCenter) <= targetWidth / 2 + 0.02 then
		Combo:FireServer()
		play("reward", 1 + (state.combo or 1) * 0.12)
		bump(target, 1.4)
		target.BackgroundColor3 = WHITE
		targetCenter = 0.15 + math.random() * 0.7
		floatText("+COMBO!", GREEN, tread, UDim2.new(0.5, -100, 0, -10))
		task.delay(0.12, function()
			target.BackgroundColor3 = GREEN
		end)
	else
		bump(tread, 0.95)
		floatText("MISS", Color3.fromRGB(255, 90, 100), tread, UDim2.new(0.5, -100, 0, -10))
	end
end)

---------------------------------------------------------------------
-- Apertura de sobres: rayos, temblor, destello, explosión y carta 3D
---------------------------------------------------------------------
local reveal = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 30, Parent = gui })
local rays = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(1000, 1000), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 31, Parent = reveal })
local rayFrames = {}
for k = 0, 11 do
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), Rotation = k * 30, ZIndex = 31, Parent = rays })
	local ray = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(0, 70, 0.5, 0), Position = UDim2.fromScale(0.5, 0), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 31, Parent = holder })
	local g = gradient(WHITE, WHITE, 90)
	g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.35) })
	g.Parent = ray
	table.insert(rayFrames, ray)
end
local packCard = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(190, 260), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 33, Parent = reveal }, { corner(18) })
local packGrad = gradient(WHITE, WHITE, 90)
packGrad.Parent = packCard
local packStroke = stroke(WHITE, 5)
packStroke.Parent = packCard
local packScale = new("UIScale", { Parent = packCard })
local packLabel = label({ Parent = packCard, Font = TITLE, Size = UDim2.new(1, -20, 0, 60), Position = UDim2.new(0, 10, 0.5, -30), ZIndex = 34 })
local flash = new("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40, Parent = reveal })
local godCard = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(380, 540), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 35, Parent = reveal }, { corner(26) })
local godGrad = gradient(WHITE, WHITE, 90)
godGrad.Parent = godCard
local godStroke = stroke(WHITE, 6)
godStroke.Parent = godCard
local godScale = new("UIScale", { Parent = godCard })
local godNew = label({ Parent = godCard, Font = TITLE, Size = UDim2.fromOffset(150, 40), Position = UDim2.new(0.5, -75, 0, -22), TextColor3 = GREEN, ZIndex = 38 })
local godVPHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 280), Position = UDim2.fromOffset(10, 20), ZIndex = 36, Parent = godCard })
local godName = label({ Parent = godCard, Font = TITLE, Size = UDim2.new(1, -20, 0, 62), Position = UDim2.fromOffset(10, 300), ZIndex = 37 })
local godNameGrad = gradient(WHITE, WHITE, 90)
godNameGrad.Parent = godName
local ribbon = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(0.8, 0, 0, 38), Position = UDim2.new(0.1, 0, 0, 364), ZIndex = 37, Parent = godCard }, { corner(19) })
local ribbonLabel = label({ Parent = ribbon, Font = TITLE, Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), ZIndex = 38 })
local godIncome = label({ Parent = godCard, Font = TITLE, Size = UDim2.new(1, -20, 0, 32), Position = UDim2.fromOffset(10, 408), TextColor3 = GOLD, ZIndex = 37 })
local godFact = label({ Parent = godCard, Font = BTN, Size = UDim2.new(1, -36, 0, 80), Position = UDim2.fromOffset(18, 446), TextColor3 = Color3.fromRGB(235, 228, 255), ZIndex = 37, TextSize = 20 })

local revealing = false
local spinModel = nil
local queueReveal = {}

local function shake(power, duration)
	local cam = workspace.CurrentCamera
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		if e > duration then
			conn:Disconnect()
			return
		end
		local k = power * (1 - e / duration)
		cam.CFrame = cam.CFrame * CFrame.new((math.random() - 0.5) * k, (math.random() - 0.5) * k, 0)
	end)
end

local function burst(color, n)
	for k = 1, n do
		local sz = math.random(10, 22)
		local p = new("Frame", { BackgroundColor3 = k % 3 == 0 and WHITE or color, Size = UDim2.fromOffset(sz, sz), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, ZIndex = 39, Parent = reveal }, { corner(4) })
		local a = math.random() * math.pi * 2
		local d = math.random(220, 620)
		TweenService:Create(p, TweenInfo.new(0.9 + math.random() * 0.5, Enum.EasingStyle.Quint), { Position = UDim2.new(0.5, math.cos(a) * d, 0.5, math.sin(a) * d), Rotation = math.random(-360, 360), BackgroundTransparency = 1 }):Play()
		task.delay(1.5, function()
			p:Destroy()
		end)
	end
end

local function doReveal(data)
	local g = Config.GOD_BY_ID[data.god]
	if not g then
		return
	end
	revealing = true
	local rarity = Config.RARITIES[g.r]
	local rc = rcolor(g.r)
	-- 1) oscurecer
	reveal.Visible = true
	reveal.BackgroundTransparency = 1
	godCard.Visible = false
	packCard.Visible = true
	rays.Visible = true
	for _, r in ipairs(rayFrames) do
		r.BackgroundColor3 = rc
	end
	TweenService:Create(reveal, TweenInfo.new(0.4), { BackgroundTransparency = 0.15 }):Play()
	packGrad.Color = ColorSequence.new(rc, darker(rc, 0.35))
	packStroke.Color = WHITE
	packLabel.Text = string.upper(Locale.name(rarity))
	packLabel.TextColor3 = WHITE
	packScale.Scale = 0
	TweenService:Create(packScale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	play("pop")
	-- 2) carga con temblor que aumenta
	local charge = 1.1 + math.min(g.r, 10) * 0.14
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local e = os.clock() - t0
		local k = math.clamp(e / charge, 0, 1)
		rays.Rotation += dt * (30 + k * 260)
		packCard.Rotation = (math.random() - 0.5) * 14 * k
		packCard.Position = UDim2.new(0.5, (math.random() - 0.5) * 18 * k, 0.5, (math.random() - 0.5) * 18 * k)
		packScale.Scale = 1 + 0.12 * k + math.sin(e * 18) * 0.03 * k
		if rarity.rainbow or rarity.sparkle then
			local hue = (os.clock() * 0.5) % 1
			packStroke.Color = Color3.fromHSV(hue, 0.7, 1)
		end
		if e >= charge then
			conn:Disconnect()
		end
	end)
	task.wait(charge)
	-- 3) destello + explosión
	packCard.Visible = false
	packCard.Rotation = 0
	flash.BackgroundTransparency = 0
	TweenService:Create(flash, TweenInfo.new(0.5), { BackgroundTransparency = 1 }):Play()
	burst(rc, 26 + g.r * 4)
	for k = 0, 2 do
		local ring = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(40, 40), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 38, Parent = reveal }, { corner(999), stroke(k == 1 and WHITE or rc, 8 - k * 2) })
		local st = ring:FindFirstChildOfClass("UIStroke")
		TweenService:Create(ring, TweenInfo.new(0.7 + k * 0.2, Enum.EasingStyle.Quart), { Size = UDim2.fromOffset(900 + k * 200, 900 + k * 200) }):Play()
		TweenService:Create(st, TweenInfo.new(0.7 + k * 0.2), { Transparency = 1 }):Play()
		task.delay(1.2, function()
			ring:Destroy()
		end)
	end
	play("whoosh", 1.2)
	if g.r >= Config.ANNOUNCE_BIG_FROM then
		shake(1.4, 1.4)
	elseif g.r >= 5 then
		shake(0.5, 0.5)
	end
	-- 4) carta con el dios en 3D
	for _, c in ipairs(godVPHolder:GetChildren()) do
		c:Destroy()
	end
	local _, model = godViewport(godVPHolder, g, UDim2.fromScale(1, 1), nil, 36)
	spinModel = model
	godGrad.Color = ColorSequence.new(darker(rc, 0.75), Color3.fromRGB(16, 10, 34))
	godStroke.Color = rc
	godName.Text = g.name
	godNameGrad.Color = ColorSequence.new(WHITE, rc)
	ribbon.BackgroundColor3 = rc
	ribbonLabel.Text = string.upper(Locale.name(rarity))
	ribbonLabel.TextColor3 = (g.r == 7 or g.r == 12) and DARK or WHITE
	local kg = data.kg or 100
	godIncome.Text = string.format("⚖️ %d kg   💰 +%s/s", kg, Format.num(rarity.income * (kg / 100) * (state.moneyMult or 1)))
	godFact.Text = Locale.lang() == "es" and g.factEs or g.factEn
	godNew.Text = data.isNew and t("gotNew") or ""
	godCard.Visible = true
	godScale.Scale = 0.2
	TweenService:Create(godScale, TweenInfo.new(0.55, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	play("reward", 0.7)
	if data.isNew then
		bump(godNew, 1.6)
	end
	task.wait(0.4)
	revealing = false
end

reveal.Activated:Connect(function()
	if revealing then
		return
	end
	TweenService:Create(godScale, TweenInfo.new(0.2), { Scale = 0 }):Play()
	TweenService:Create(reveal, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	task.delay(0.26, function()
		reveal.Visible = false
		spinModel = nil
		if #queueReveal > 0 then
			task.spawn(doReveal, table.remove(queueReveal, 1))
		end
	end)
end)

Remotes:WaitForChild("Reveal").OnClientEvent:Connect(function(data)
	if reveal.Visible then
		table.insert(queueReveal, data)
	else
		task.spawn(doReveal, data)
	end
end)

---------------------------------------------------------------------
-- Mensajes del servidor
---------------------------------------------------------------------
local function chat(text, color)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local general = channels and channels:FindFirstChild("RBXGeneral")
	if general then
		pcall(function()
			general:DisplaySystemMessage(string.format('<font color="%s"><b>%s</b></font>', color or "#FFD23F", text))
		end)
	end
end

Remotes:WaitForChild("Announce").OnClientEvent:Connect(function(payload)
	local text = fmtKey(payload.key, payload.args)
	local opts = payload.opts or {}
	local color = opts.color
	if color == "#19191F" then
		color = "#C878FF"
	end
	chat(text, color)
	if opts.big then
		showBanner(text, color and Color3.fromHex(color) or GOLD)
	end
end)

Remotes:WaitForChild("Toast").OnClientEvent:Connect(function(key, args)
	local good = key == "bought" or key == "afkOn"
	toast(fmtKey(key, args), good and GREEN or (key == "notEnough" and Color3.fromRGB(255, 90, 100) or GOLD))
	if good then
		play("reward", 1.2)
	end
end)

Remotes:WaitForChild("Knock").OnClientEvent:Connect(function(vel)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum then
		hum.PlatformStand = true
		hrp.AssemblyLinearVelocity = vel
		shake(0.9, 0.4)
		play("whoosh", 0.7)
		task.delay(0.8, function()
			hum.PlatformStand = false
		end)
	end
end)

local offlinePopup = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(440, 300), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 45, Parent = gui }, {
	corner(26),
	gradient(Color3.fromRGB(40, 120, 60), Color3.fromRGB(12, 30, 20), 90),
	stroke(GREEN, 5),
})
local offlineScale = new("UIScale", { Parent = offlinePopup })
heavy({ Parent = offlinePopup, Text = "", Size = UDim2.new(1, -30, 0, 44), Position = UDim2.fromOffset(15, 16), ZIndex = 46 }).Name = "Title"
heavy({ Parent = offlinePopup, Text = "", Size = UDim2.new(1, -30, 0, 90), Position = UDim2.fromOffset(15, 66), TextColor3 = GREEN, ZIndex = 46, StrokeThickness = 4 }).Name = "Amount"
label({ Parent = offlinePopup, Font = BTN, Text = "", Size = UDim2.new(1, -30, 0, 30), Position = UDim2.fromOffset(15, 160), ZIndex = 46 }).Name = "Sub"
local claimBtn = button({ Parent = offlinePopup, Text = t("claim"), Size = UDim2.new(1, -60, 0, 64), Position = UDim2.new(0, 30, 1, -84), Color = GREEN, ZIndex = 47, OnClick = function()
	Action:FireServer("claimOffline")
	play("reward", 0.9)
	TweenService:Create(offlineScale, TweenInfo.new(0.2), { Scale = 0 }):Play()
	task.delay(0.21, function()
		offlinePopup.Visible = false
	end)
end })
claimBtn.FontFace = HEAVY

Remotes:WaitForChild("Offer").OnClientEvent:Connect(function(key, amount, away)
	if key == "offline" then
		offlinePopup.Title.Text = t("offlineTitle")
		offlinePopup.Amount.Text = "$" .. Format.num(amount or 0)
		offlinePopup.Sub.Text = t("offlineSub", Format.time(away or 0))
		offlinePopup.Visible = true
		offlineScale.Scale = 0.3
		TweenService:Create(offlineScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		play("reward", 0.8)
		return
	end
	local p = Config.PRODUCTS[key]
	if p and p.id ~= 0 then
		showBanner(t("savePackAsk"), Color3.fromRGB(255, 120, 120))
		MarketplaceService:PromptProductPurchase(player, p.id)
	end
end)

local lastMoney = 0
Remotes:WaitForChild("State").OnClientEvent:Connect(function(s)
	if (s.money or 0) > lastMoney + 0.5 and lastMoney > 0 then
		bump(moneyPill, 1.06)
	end
	lastMoney = s.money or 0
	state = s
	stateAt = os.clock()
end)

---------------------------------------------------------------------
-- Carteles del mundo en tu idioma
---------------------------------------------------------------------
local function locLabel(bb)
	local l = bb:FindFirstChild("Label")
	if not l then
		return
	end
	l.Font = TITLE
	if bb:GetAttribute("Overhead") then
		l.FontFace = HEAVY
		l.Text = string.format('<font color="#FFB347">[%s]</font>\n<font color="#7CFF8A">$%s/s</font>', t("title" .. (bb:GetAttribute("Title") or 1)), Format.num(bb:GetAttribute("Income") or 0))
		return
	end
	if bb:GetAttribute("Altar") then
		local r = bb:GetAttribute("Rarity") or 0
		if r > 0 then
			local rem = bb:GetAttribute("Rem") or 0
			l.TextColor3 = rcolor(r)
			l.Text = string.format("%s · %d kg\n%s", Locale.name(Config.RARITIES[r]), bb:GetAttribute("Kg") or 100, rem <= 0 and ("✨ " .. t("ready")) or ("⏳ " .. Format.time(rem)))
		else
			l.Text = ""
		end
	elseif bb:GetAttribute("Guardian") then
		local zone = Config.ZONES[bb:GetAttribute("Guardian")]
		local chasing = bb:GetAttribute("Chasing")
		l.Text = string.format("%s%s", Locale.name(zone.guardian), chasing and ("\n⚠️ " .. t("chasing")) or "")
	elseif bb:GetAttribute("Zone") then
		local zi = bb:GetAttribute("Zone")
		local zone = Config.ZONES[zi]
		local ok = (state.speed or 0) >= zone.req
		l.Text = string.format("%s %d · %s%s", t("zone"), zi, Locale.name(zone), zi > 1 and string.format('\n<font color="%s">%s ⚡ %s</font>', ok and "#5CFF8A" or "#FF5A5A", t("requires"), Format.num(zone.req)) or "")
	elseif bb:GetAttribute("EndSign") then
		l.Text = string.format("%s\n%s", t("endSign"), t("moreZones"))
	elseif bb:GetAttribute("Rarity") then
		local r = bb:GetAttribute("Rarity")
		l.TextColor3 = rcolor(r)
		l.Text = string.format("%s%s\n<font size=\"16\" color=\"#FFE9A8\">⚖️ %d kg</font>", string.upper(Locale.name(Config.RARITIES[r])), bb:GetAttribute("Dawn") and " 🌅" or "", bb:GetAttribute("Kg") or 100)
	end
end

local function locPrompt(p)
	p.ActionText = p:GetAttribute("Kind") == "steal" and t("steal") or t("open")
end
for _, p in ipairs(CollectionService:GetTagged("LocPrompt")) do
	locPrompt(p)
end
CollectionService:GetInstanceAddedSignal("LocPrompt"):Connect(locPrompt)

---------------------------------------------------------------------
-- Efectos de velocidad
---------------------------------------------------------------------
local trail
local function setupTrail(char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	local a0 = new("Attachment", { Position = Vector3.new(0, 1.6, 0), Parent = hrp })
	local a1 = new("Attachment", { Position = Vector3.new(0, -2.2, 0), Parent = hrp })
	trail = new("Trail", { Texture = Config.VFX.streak, TextureMode = Enum.TextureMode.Stretch, Lifetime = 0.45, Attachment0 = a0, Attachment1 = a1, LightEmission = 1, Color = ColorSequence.new(WHITE, CYAN), Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) }), Enabled = false, Parent = hrp })
end
player.CharacterAdded:Connect(setupTrail)
if player.Character then
	task.spawn(setupTrail, player.Character)
end

RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and cam then
		local v = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
		local goal = 70 + math.clamp((v - 16) / 3, 0, 28)
		cam.FieldOfView += (goal - cam.FieldOfView) * math.min(1, dt * 4)
		if trail then
			trail.Enabled = v > 40
		end
	end
	if tread.Visible then
		marker.Position = UDim2.new(markerPos(), -5, 0, -6)
		target.Position = UDim2.fromScale(targetCenter - targetWidth / 2, 0)
	end
	local now = os.clock()
	for _, f in ipairs(floaters) do
		f.gui.Position = UDim2.new(0, 4, 0, 4 + math.sin(now * 2.2 + f.phase) * 3)
		f.gui.Rotation = math.sin(now * 1.6 + f.phase) * 6
	end
	for i, g in ipairs(pillGradients) do
		g.Rotation = 90 + math.sin(now * 0.8 + i) * 25
	end
	if spinModel and spinModel.Parent then
		spinModel:PivotTo(CFrame.Angles(0, now * 1.2, 0))
	end
	if reveal.Visible then
		rays.Rotation += dt * 25
	end
end)

---------------------------------------------------------------------
-- Modo persecución: pantalla roja, ¡CORRE! y soltar sobre
---------------------------------------------------------------------
local chaseCC = new("ColorCorrectionEffect", { TintColor = WHITE, Parent = game:GetService("Lighting") })
local runBadge = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(300, 70), Position = UDim2.new(0.5, 0, 0, 90), AnchorPoint = Vector2.new(0.5, 0), Visible = false, ZIndex = 15, Parent = gui }, {
	corner(18),
	gradient(Color3.fromRGB(255, 80, 60), Color3.fromRGB(170, 20, 40), 90),
	stroke(Color3.fromRGB(255, 220, 120), 4),
})
heavy({ Parent = runBadge, Text = t("run"), Size = UDim2.new(1, -20, 1, -12), Position = UDim2.fromOffset(10, 6), ZIndex = 16, StrokeThickness = 4 })
local distLabel = heavy({ Parent = gui, Size = UDim2.fromOffset(460, 30), Position = UDim2.new(0.5, 0, 0, 166), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 15 })
local dropBtn = button({ Parent = gui, Text = t("dropPack"), Size = UDim2.fromOffset(230, 58), Position = UDim2.new(0.5, 0, 1, -24), AnchorPoint = Vector2.new(0.5, 1), Color = Color3.fromRGB(255, 60, 120), ZIndex = 15, OnClick = function()
	Action:FireServer("dropPack")
end })
dropBtn.FontFace = HEAVY
dropBtn.Visible = false

local function updateChase()
	local carrying = state.carrying ~= nil
	if carrying and not runBadge.Visible then
		bump(runBadge, 1.5)
		play("whoosh", 1.4)
		play("reward", 1.5)
		shake(0.8, 0.35)
		local fl = new("Frame", { BackgroundColor3 = rcolor(state.carrying), BackgroundTransparency = 0.3, Size = UDim2.fromScale(1, 1), ZIndex = 13, Parent = gui })
		TweenService:Create(fl, TweenInfo.new(0.45), { BackgroundTransparency = 1 }):Play()
		task.delay(0.5, function()
			fl:Destroy()
		end)
	end
	runBadge.Visible = carrying
	dropBtn.Visible = carrying
	distLabel.Visible = carrying and state.chase ~= nil
	if carrying then
		local pulse = 0.5 + 0.5 * math.sin(os.clock() * 8)
		chaseCC.TintColor = Color3.new(1, 0.72 + 0.12 * pulse, 0.72 + 0.12 * pulse)
		runBadge.Rotation = math.sin(os.clock() * 10) * 3
		if state.chase then
			distLabel.Text = t("guardianDist", state.chase)
			distLabel.TextColor3 = state.chase < 40 and Color3.fromRGB(255, 90, 90) or WHITE
		end
	else
		chaseCC.TintColor = WHITE
	end
end

-- Título grande al entrar en una zona
local zoneTitle = heavy({ Parent = gui, Size = UDim2.fromOffset(800, 80), Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 14, StrokeThickness = 5 })
local zoneSub = heavy({ Parent = zoneTitle, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, 0), TextColor3 = CYAN, ZIndex = 14 })
local zoneToken = 0
local function showZone(zi)
	local zone = Config.ZONES[zi]
	zoneToken += 1
	local my = zoneToken
	zoneTitle.Text = string.upper(Locale.name(zone))
	zoneTitle.TextColor3 = zone.accent
	zoneSub.Text = zi > 1 and t("recommended", Format.num(Config.ZONES[zi].guardian.speed)) or t("recommended", Format.num(zone.guardian.speed))
	zoneTitle.Visible = true
	bump(zoneTitle, 1.6)
	play("whoosh", 0.9)
	task.delay(2.5, function()
		if my == zoneToken then
			zoneTitle.Visible = false
		end
	end)
end

-- "+$" saltando sobre tus dioses
local function myPlot()
	local w = workspace:FindFirstChild("World")
	if not w then
		return nil
	end
	for _, f in ipairs(w:GetChildren()) do
		if f:IsA("Folder") and f:GetAttribute("Owner") == player.UserId then
			return f
		end
	end
	return nil
end
task.spawn(function()
	while true do
		task.wait(2.5)
		local plot = myPlot()
		if plot then
			local statues = {}
			for _, m in ipairs(plot:GetChildren()) do
				if m:IsA("Model") and m:GetAttribute("Income") then
					table.insert(statues, m)
				end
			end
			for k = 1, math.min(5, #statues) do
				local m = table.remove(statues, math.random(1, #statues))
				local torso = m:FindFirstChild("Torso")
				if torso then
					local bb = new("BillboardGui", { Size = UDim2.fromScale(5, 1.4), StudsOffset = Vector3.new(0, 2.5, 0), LightInfluence = 0, MaxDistance = 70, Parent = torso })
					local l = heavy({ Parent = bb, Text = "+$" .. Format.num((m:GetAttribute("Income") or 0) * (state.moneyMult or 1) * 2.5), TextColor3 = GREEN })
					TweenService:Create(bb, TweenInfo.new(1.1, Enum.EasingStyle.Quad), { StudsOffset = Vector3.new(0, 5, 0) }):Play()
					TweenService:Create(l, TweenInfo.new(1.1), { TextTransparency = 1 }):Play()
					task.delay(1.15, function()
						bb:Destroy()
					end)
				end
			end
		end
	end
end)

---------------------------------------------------------------------
-- Los dioses pasean libremente por cada parcela (solo visual, en tu pantalla)
---------------------------------------------------------------------
local walkers = {}
local function plotFolders()
	local w = workspace:FindFirstChild("World")
	local list = {}
	if w then
		for _, f in ipairs(w:GetChildren()) do
			if f:IsA("Folder") and f:GetAttribute("PlotCF") then
				table.insert(list, f)
			end
		end
	end
	return list
end
local function newTarget()
	return Vector3.new(-19 + math.random() * 38, 0, -17 + math.random() * 30)
end
local walkAcc = 0
RunService.Heartbeat:Connect(function(dt)
	walkAcc += dt
	if walkAcc < 1 / 30 then
		return
	end
	dt = walkAcc
	walkAcc = 0
	local cam = workspace.CurrentCamera
	local now = os.clock()
	for _, folder in ipairs(plotFolders()) do
		local cf = folder:GetAttribute("PlotCF")
		if cam and (cam.CFrame.Position - cf.Position).Magnitude < 220 then
			for _, m in ipairs(folder:GetChildren()) do
				if m:IsA("Model") and m:GetAttribute("Income") and m.PrimaryPart then
					local st = walkers[m]
					if not st then
						local rel = cf:ToObjectSpace(m:GetPivot())
						st = { pos = Vector3.new(rel.X, 0, rel.Z), y = rel.Y, target = newTarget(), wait = math.random() * 2, yaw = math.pi, speed = 3 + math.random() * 2.5, phase = math.random() * 6 }
						walkers[m] = st
						m.AncestryChanged:Connect(function()
							if not m.Parent then
								walkers[m] = nil
							end
						end)
					end
					local moving = false
					if st.wait > 0 then
						st.wait -= dt
					else
						local delta = st.target - st.pos
						local dist = delta.Magnitude
						if dist < 0.5 then
							st.target = newTarget()
							st.wait = 1 + math.random() * 3
						else
							moving = true
							st.pos += delta.Unit * math.min(dist, st.speed * dt)
							local goalYaw = math.atan2(-delta.X, -delta.Z)
							local diff = (goalYaw - st.yaw + math.pi) % (2 * math.pi) - math.pi
							st.yaw += diff * math.min(1, dt * 6)
						end
					end
					local bob = moving and math.abs(math.sin(now * 9 + st.phase)) * 0.35 or math.sin(now * 2 + st.phase) * 0.08
					local tilt = moving and math.sin(now * 9 + st.phase) * 0.08 or 0
					local animated = m:GetAttribute("Animated")
					if animated then
						bob, tilt = moving and math.abs(math.sin(now * 9 + st.phase)) * 0.12 or 0, 0
					end
					m:PivotTo(cf * CFrame.new(st.pos.X, st.y + bob, st.pos.Z) * CFrame.Angles(0, st.yaw, tilt))
					if animated then
						GodModel.animate(m, now * 9 + st.phase, moving and 0.55 or 0)
					end
					local runes = m:FindFirstChild("Runes")
					if runes then
						runes.CFrame = m:GetPivot() * CFrame.new(0, 0.04 - bob, 0) * CFrame.Angles(0, now * 0.8, 0)
					end
				end
			end
		end
	end
end)

-- Cinta: animación de correr y banda en movimiento
local runTrack = nil
local belts = {}
local function myTreadmill()
	local plot = myPlot()
	return plot and plot:FindFirstChild("Treadmill")
end
local function ensureBelt(tm)
	if #belts > 0 and belts[1].Parent and belts.tm == tm then
		return
	end
	for _, b in ipairs(belts) do
		b:Destroy()
	end
	belts = { tm = tm }
	for k = 1, 8 do
		local stripe = new("Part", { Anchored = true, CanCollide = false, CanQuery = false, Size = Vector3.new(tm.Size.X - 0.4, 0.05, 0.35), Color = Color3.fromRGB(90, 230, 255), Material = Enum.Material.Neon, Transparency = 0.35, Parent = workspace })
		table.insert(belts, stripe)
	end
end
local beltOffset = 0
RunService.RenderStepped:Connect(function(dt)
	local tm = myTreadmill()
	local running = state.onTreadmill == true or state.afk == true
	if tm then
		ensureBelt(tm)
		beltOffset = (beltOffset + dt * (running and (10 + (state.combo or 1) * 4) or 1.5)) % tm.Size.Z
		for k, stripe in ipairs(belts) do
			local z = ((k - 1) * tm.Size.Z / 8 + beltOffset) % tm.Size.Z - tm.Size.Z / 2
			stripe.CFrame = tm.CFrame * CFrame.new(0, tm.Size.Y / 2 + 0.03, -z)
		end
	end
	local char = player.Character
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if running and animator then
		if not runTrack then
			local animate = char:FindFirstChild("Animate")
			local runFolder = animate and animate:FindFirstChild("run")
			local anim = runFolder and runFolder:FindFirstChildOfClass("Animation")
			if anim then
				runTrack = animator:LoadAnimation(anim)
				runTrack.Looped = true
				runTrack.Priority = Enum.AnimationPriority.Action
				runTrack:Play(0.2)
			end
		end
		if runTrack then
			runTrack:AdjustSpeed(1.2 + (state.combo or 1) * 0.35)
		end
	elseif runTrack then
		runTrack:Stop(0.2)
		runTrack = nil
	end
end)
player.CharacterAdded:Connect(function()
	runTrack = nil
end)

---------------------------------------------------------------------
-- Actualización de la interfaz (10 veces por segundo)
---------------------------------------------------------------------
task.spawn(function()
	local renderAcc = 0
	local lastNight = nil
	local lastZone = 0
	while true do
		task.wait(0.1)
		local left = math.max(0, (state.cycleLeft or 0) - (os.clock() - stateAt))
		moneyLabel.Text = string.format('$%s <font size="24" color="#C8FFB0">+$%s/s</font>', Format.num(state.money or 0), Format.num(state.income or 0))
		speedLabel.Text = string.format('⚡ %s <font size="22" color="#C9A6FF">(x%s)</font>', Format.num(state.speed or 0), Format.num(state.speedMult or 1))
		multLabel.Text = string.format("💰 x%s   🍀 x%s", Format.num(state.moneyMult or 1), Format.num(state.luck or 1))
		cycleLabel.Text = string.format('%s <font color="#FFD23F">%s</font>', state.night and t("dawnIn") or t("nightIn"), Format.time(left))
		-- "NEW" en la tienda si puedes comprar una mejora
		local canBuy = (state.money or 0) >= Config.treadmillCost((state.treadmill or 1) + 1) or (state.money or 0) >= Config.plotCost((state.plot or 1) + 1)
		badges[1].Visible = canBuy
		if lastNight ~= state.night then
			lastNight = state.night
			cycleIcon.Text = state.night and "☀️" or "🌙"
			bump(cyclePill, 1.2)
		end
		local z = state.zone or 0
		updateChase()
		if z ~= lastZone then
			if z > 0 then
				showZone(z)
			end
			lastZone = z
		end
		if z > 0 then
			zoneLabel.Text = string.format("%s · %s %d: %s", t("combatZone"), t("zone"), z, Locale.name(Config.ZONES[z]))
			zoneLabel.TextColor3 = Color3.fromRGB(255, 120, 110)
		else
			zoneLabel.Text = t("safeZone")
			zoneLabel.TextColor3 = Color3.fromRGB(150, 255, 170)
		end
		if state.carrying then
			local r = Config.RARITIES[state.carrying]
			carryLabel.Text = "📦 " .. t("carrying", string.upper(Locale.name(r)))
			carryLabel.TextColor3 = rcolor(state.carrying)
			carryLabel.Rotation = math.sin(os.clock() * 6) * 2
		else
			carryLabel.Text = ""
		end
		local showTread = state.onTreadmill == true and not state.afk
		if showTread and not tread.Visible then
			bump(tread, 0.7)
		end
		tread.Visible = showTread
		comboLabel.Text = string.format("%s x%.1f  ·  ⚡ +%s/s", t("combo"), state.combo or 1, Format.num((state.treadmillGain or 0) * (state.combo or 1) * (state.night and Config.NIGHT_TREADMILL_MULT or 1)))
		comboLabel.TextColor3 = (state.combo or 1) >= Config.COMBO_MAX and GOLD or CYAN
		afkButton:FindFirstChildOfClass("UIStroke").Color = state.afk and GREEN or darker(PURPLE, 0.3)
		for _, bb in ipairs(CollectionService:GetTagged("Loc")) do
			locLabel(bb)
		end
		renderAcc += 0.1
		if renderAcc >= 1 then
			renderAcc = 0
			render(false)
		end
	end
end)

---------------------------------------------------------------------
-- AFK: evitar la expulsión por inactividad (reconexión automática)
---------------------------------------------------------------------
local lastInput = os.clock()
local rejoinSent = false
UserInputService.InputBegan:Connect(function()
	lastInput = os.clock()
end)
local function tryRejoin()
	if state.afk and not rejoinSent then
		rejoinSent = true
		Action:FireServer("rejoin")
		task.delay(30, function()
			rejoinSent = false
		end)
	end
end
player.Idled:Connect(function(idleTime)
	if idleTime >= Config.AFK_REJOIN_AFTER then
		tryRejoin()
	end
end)
task.spawn(function()
	while true do
		task.wait(30)
		if os.clock() - lastInput >= Config.AFK_REJOIN_AFTER then
			tryRejoin()
		end
	end
end)
