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
-- Ganchos del módulo Missions (estado nuevo y avisos). Se declaran aquí, antes de los manejadores que los llaman.
local hooks = {}

---------------------------------------------------------------------
-- Estilo
---------------------------------------------------------------------
local TITLE = Enum.Font.LuckiestGuy
local BTN = Enum.Font.FredokaOne
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
	-- Secreta (casi negra) y ??? (negra) usan su color de acento para que se lean
	return rr.id == 10 and Color3.fromRGB(200, 120, 255) or rr.id == 14 and Color3.fromRGB(255, 40, 60) or rr.color
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
	fly = sound("rbxasset://sounds/action_falling.mp3", 0.6, 1),
	thud = sound("rbxasset://sounds/collide.wav", 0.7, 0.7),
	reward = sound("rbxasset://sounds/electronicpingshort.wav", 0.6, 0.8),
}
local function opt(key)
	local st = state.settings
	if not st then
		return key ~= "ui" and true or 2
	end
	if key == "ui" then
		return st.ui or 2
	end
	return st[key] ~= false
end

local function play(name, pitch)
	if not opt("sfx") then
		return
	end
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

local CLOSE_FONT = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy)
local function button(props)
	local base = props.Color or GOLD
	-- el símbolo ✕ no está en las fuentes de Roblox (en el iPhone salía un círculo vacío): se usa una X gruesa
	local isClose = props.Text == "✕"
	local b = new("TextButton", {
		AutoButtonColor = false,
		BackgroundColor3 = WHITE,
		Font = BTN,
		TextScaled = true,
		Text = isClose and "X" or (props.Text or ""),
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
	if isClose then
		b.FontFace = CLOSE_FONT
	end
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
		elseif a.mission then
			return Locale.mission(a.mission, tonumber(a.goal))
		elseif a.mutation then
			local m = Config.MUTATION_BY_ID and Config.MUTATION_BY_ID[a.mutation]
			return m and (m.icon .. " " .. string.upper(Locale.name(m))) or "?"
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
	local h = math.max(4, model:GetExtentsSize().Y + 0.5)
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
	local mult = ({ 0.82, 1, 1.18 })[(state and state.settings and state.settings.ui) or 2]
	uiScale.Scale = math.clamp(h / 760, 0.5, 1) * mult
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
-- En el móvil el joystick (abajo a la izquierda) tapaba la velocidad y el dinero: van arriba a la derecha
if UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled then
	stats.Position = UDim2.new(1, -18, 0, 58)
	stats.AnchorPoint = Vector2.new(1, 0)
	for _, l in ipairs({ speedLabel, moneyLabel, multLabel }) do
		l.TextXAlignment = Enum.TextXAlignment.Right
	end
	-- y el chat de Roblox, más bajito para que no llegue a los botones de la izquierda
	pcall(function()
		local cfg = TextChatService:FindFirstChildOfClass("ChatWindowConfiguration")
		if cfg then
			cfg.HeightScale = 0.75
		end
	end)
end
local moneyPill = moneyLabel

-- Abajo a la derecha: reloj de la noche
local cyclePill = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(250, 62), Position = UDim2.new(1, -18, 1, -150), AnchorPoint = Vector2.new(1, 1), Parent = gui }, {
	corner(16),
	gradient(Color3.fromRGB(40, 30, 90), Color3.fromRGB(14, 10, 34), 90),
	stroke(Color3.fromRGB(170, 140, 255), 3),
})
local cycleIcon = label({ Parent = cyclePill, Text = "🌙", Font = TITLE, Size = UDim2.fromOffset(46, 46), Position = UDim2.fromOffset(8, 8), Stroke = false })
local cycleLabel = heavy({ Parent = cyclePill, Size = UDim2.new(1, -66, 1, -14), Position = UDim2.fromOffset(58, 7), TextXAlignment = Enum.TextXAlignment.Left })

local zoneLabel = heavy({ Parent = gui, Size = UDim2.new(0, 560, 0, 30), Position = UDim2.new(0.5, 0, 0, 10), AnchorPoint = Vector2.new(0.5, 0) })
-- Aviso del sobre que llevas: una píldora oscura con el borde del color de su rareza
local carryPill = new("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 0.15, Size = UDim2.new(0, 640, 0, 40), Position = UDim2.new(0.5, 0, 0, 44), AnchorPoint = Vector2.new(0.5, 0), Visible = false, Parent = gui }, {
	corner(20),
	gradient(Color3.fromRGB(44, 30, 92), Color3.fromRGB(14, 10, 32), 90),
	stroke(GOLD, 3),
})
local carryLabel = heavy({ Parent = carryPill, Size = UDim2.new(1, -28, 1, -8), Position = UDim2.fromOffset(14, 4) })

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
-- (más abajo del centro: arriba a la izquierda está el chat de Roblox, que se come los toques aunque se desvanezca)
local side = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 210, 0, 420), Position = UDim2.new(0, 14, 0.57, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = gui }, {
	-- orden por LayoutOrder (explícito: Misiones va entre la Tienda y el Índice aunque se cree la última)
	new("UIListLayout", { Padding = UDim.new(0, 10), VerticalAlignment = Enum.VerticalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder }),
})

local panel = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromScale(0.64, 0.7), Position = UDim2.fromScale(0.5, 0.47), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 10, Parent = gui }, {
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
-- Franja de ayuda (ocupa el hueco de las pestañas): consejo del vendedor y tu dinero
local hint = { bar = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -36, 0, 42), Position = UDim2.fromOffset(18, 62), Visible = false, ZIndex = 11, Parent = panel }) }
hint.label = label({ Parent = hint.bar, Font = BTN, Size = UDim2.new(0.72, -12, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(228, 218, 250), ZIndex = 11 })
new("UITextSizeConstraint", { MaxTextSize = 22, Parent = hint.label })
hint.chip = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(0.28, 0, 1, -4), Position = UDim2.new(1, 0, 0, 2), AnchorPoint = Vector2.new(1, 0), ZIndex = 11, Parent = hint.bar }, {
	corner(12),
	gradient(Color3.fromRGB(34, 84, 52), Color3.fromRGB(14, 32, 24), 90),
	stroke(GREEN, 2),
})
hint.money = heavy({ Parent = hint.chip, Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), TextColor3 = Color3.fromRGB(190, 255, 200), ZIndex = 12, StrokeThickness = 2 })
local content = new("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, -122), Position = UDim2.fromOffset(18, 112), ScrollBarThickness = 8, ScrollBarImageColor3 = GOLD, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 11, Parent = panel })

-- closing = se está cerrando (animación) · token = para que un cierre antiguo no esconda un panel recién abierto
local panelState = { closing = false, token = 0 }
local function closePanel()
	if not panel.Visible or panelState.closing then
		return
	end
	panelState.closing = true
	panelState.token += 1
	local my = panelState.token
	TweenService:Create(panelScale, TweenInfo.new(0.15), { Scale = 0.7 }):Play()
	task.delay(0.15, function()
		if my == panelState.token then
			panel.Visible = false
			panelState.closing = false
		end
	end)
end
button({ Parent = panel, Text = "✕", Size = UDim2.fromOffset(50, 50), Position = UDim2.new(1, -60, 0, 10), Color = Color3.fromRGB(255, 70, 100), ZIndex = 12, Radius = 25, OnClick = closePanel })

local currentPanel, currentTab = nil, nil
local renderers = {}
local signatures = {}
-- vistas previas animadas de las auras (las mueve el bucle de RenderStepped mientras el panel está abierto)
local auraPreviews = {}

local function clearContent()
	table.clear(auraPreviews)
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

local function setTabs(list)
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

-- tip = consejo bajo el título (paneles de vendedor) · keepOpen = si ya está abierto, no lo cierres
local function openPanel(name, title, list, color, tip, keepOpen)
	if panel.Visible and not panelState.closing and currentPanel == name then
		if not keepOpen then
			closePanel()
		end
		return
	end
	panelState.token += 1
	panelState.closing = false
	currentPanel = name
	currentTab = list and list[1] and list[1].id or nil
	panelTitle.Text = title
	panelStroke.Color = color or GOLD
	titleGrad.Color = tip and ColorSequence.new(WHITE, color or GOLD) or ColorSequence.new(GOLD, Color3.fromRGB(255, 130, 60))
	setTabs(list or {})
	-- sin pestañas ni consejo, el contenido sube y aprovecha el hueco
	local hasTabs = list ~= nil and #list > 0
	local top = (hasTabs or tip) and 112 or 68
	tabs.Visible = hasTabs
	hint.bar.Visible = not hasTabs and tip ~= nil
	hint.label.Text = tip or ""
	hint.money.Text = string.format("%s 💰 %s", t("youHave"), Format.num(state.money or 0))
	content.Position = UDim2.fromOffset(18, top)
	content.Size = UDim2.new(1, -36, 1, -(top + 10))
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
-- Tienda (solo mejoras: las auras y los entrenadores los venden Hécate y Quirón)
---------------------------------------------------------------------
signatures.shop = function()
	local money = state.money or 0
	local tm, pl, al = state.treadmill or 1, state.plot or 1, state.altarsBought or Config.ALTARS_BASE
	return table.concat({ tm, pl, al, state.queue or 0, tostring(money >= Config.treadmillCost(tm + 1)), tostring(money >= Config.plotCost(pl + 1)), tostring(money >= Config.altarCost(al + 1)) }, "|")
end

renderers.shop = function()
	listLayout()
	local money = state.money or 0
	-- la cinta y la suerte se mejoran en los carteles de la parcela (ver aviso de abajo)
	local pl = state.plot or 1
	local plMax = pl >= Config.PLOT_MAX
	local plCost = not plMax and Config.plotCost(pl + 1) or 0
	row(2, "🏛️", string.format("%s · %s %d", t("plot"), t("level"), pl), string.format("%d %s → %d", Config.pedestalsFor(pl), t("pedestals"), plMax and Config.pedestalsFor(pl) or Config.pedestalsFor(pl + 1)), plMax and t("max") or ("💰 " .. Format.num(plCost)), GOLD, not plMax and money >= plCost, function()
		Action:FireServer("buyPlot")
	end, GOLD)
	local al = state.altarsBought or Config.ALTARS_BASE
	local alMax = al >= Config.ALTARS_MAX
	local alCost = not alMax and Config.altarCost(al + 1) or 0
	row(3, "🔮", string.format("%s · %d / %d", t("altar"), al, Config.ALTARS_MAX), string.format("%s: %d", t("queue"), state.queue or 0), alMax and t("max") or ("💰 " .. Format.num(alCost)), PURPLE, not alMax and money >= alCost, function()
		Action:FireServer("buyAltar")
	end, PURPLE)
	-- aviso: dónde se compran ahora las auras y los entrenadores
	local info = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, -14, 0, 110), LayoutOrder = 4, ZIndex = 11, Parent = content }, {
		corner(16),
		gradient(Color3.fromRGB(58, 40, 112), Color3.fromRGB(26, 18, 50), 0),
		stroke(Config.VENDORS.aura.color, 2, 0.35),
	})
	label({ Parent = info, Text = "🧭", Font = TITLE, Size = UDim2.fromOffset(48, 48), Position = UDim2.fromOffset(12, 13), ZIndex = 12, Stroke = false })
	local infoText = label({ Parent = info, Font = BTN, Text = t("signsHint") .. "\n" .. t("vendorMoved"), Size = UDim2.new(1, -90, 1, -16), Position = UDim2.fromOffset(72, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(228, 218, 250), ZIndex = 12 })
	new("UITextSizeConstraint", { MaxTextSize = 24, Parent = infoText })
end

---------------------------------------------------------------------
-- Vendedores: auras de Hécate y entrenadores de Quirón
-- (se abren al hablar con ellos: ProximityPrompt con la etiqueta "VendorPrompt")
---------------------------------------------------------------------
local VENDOR_PANELS = { auraShop = "aura", coachShop = "coach" }
local GREY = Color3.fromRGB(90, 88, 110)

-- porcentaje redondeado (0.15 * 6 * 100 no da 90 exacto)
local function pct(x)
	return Format.num(math.floor(x * 100 + 0.5))
end

signatures.auraShop = function()
	local money = state.money or 0
	local mine = state.auras or {}
	local s = tostring(state.aura)
	for _, a in ipairs(Config.AURAS) do
		s ..= mine[a.id] and "o" or (money >= a.cost and "y" or "n")
	end
	return s
end

renderers.auraShop = function()
	new("UIGridLayout", { CellSize = UDim2.fromOffset(264, 216), CellPadding = UDim2.fromOffset(12, 12), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	new("UIPadding", { PaddingTop = UDim.new(0, 10), PaddingBottom = UDim.new(0, 8), Parent = content })
	local money = state.money or 0
	local mine = state.auras or {}
	local n = #Config.AURAS
	local function img(parent, tex, color, size, z, tr)
		return new("ImageLabel", { BackgroundTransparency = 1, Image = tex, ImageColor3 = color, ImageTransparency = tr or 0, Size = UDim2.fromOffset(size, size), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z, Parent = parent })
	end
	for i, a in ipairs(Config.AURAS) do
		local k = n > 1 and (i - 1) / (n - 1) or 0 -- 0 = la más barata · 1 = la más cara
		local c = a.color
		local light = c:Lerp(WHITE, 0.5)
		-- un aura blanca (la Divina) lleva el fondo violeta para que no quede gris
		local _, sat = c:ToHSV()
		local bg = sat < 0.15 and Color3.fromRGB(165, 130, 255) or c
		local owned = mine[a.id] and true or false
		local eq = state.aura == a.id
		-- marco: cuanto más cara, borde más grueso, fondo más vivo y más estrellas
		local card = new("Frame", { BackgroundColor3 = WHITE, LayoutOrder = i, ZIndex = 11, Parent = content }, {
			corner(18),
			gradient(darker(bg, 0.3 + 0.28 * k), Color3.fromRGB(16, 11, 34), 90),
		})
		local cardStroke = stroke(c, 2 + 3 * k)
		cardStroke.Parent = card
		-- vista previa animada: halo, rayos que giran, círculo mágico, núcleo que late y chispas en órbita
		local view = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, 108), ZIndex = 1, Parent = card })
		local halo = img(view, Config.VFX.glow, c, 104, 1, 0.5)
		halo.Size = UDim2.fromOffset(200 + 56 * k, 104)
		local rays = img(view, Config.VFX.rays, c, 98 + 10 * k, 2, 0.05)
		local ring = nil
		if i >= 5 then
			ring = img(view, Config.VFX.runes, light, 104, 3, 0)
		elseif i >= 3 then
			ring = img(view, Config.VFX.ring, light, 80 + 12 * k, 3, 0.2)
		end
		local coreSize = 84 + 20 * k
		local core = img(view, Config.VFX.glow, light, coreSize, 4, 0)
		local sparks = {}
		for j = 1, 1 + math.floor(i * 0.6) do
			table.insert(sparks, {
				img = img(view, Config.VFX.sparkle, WHITE, 40, 5, 0),
				radius = 30 + 4 * j + 8 * k,
				speed = (j % 2 == 0 and -1 or 1) * (0.9 + 0.22 * j),
				phase = j * 2.4 + i,
				size = 38 + 16 * k,
			})
		end
		local stars = {}
		if i >= 3 then
			-- {escala X, píxeles X, escala Y, píxeles Y}: las dos de arriba; las 2 auras más caras, las cuatro esquinas
			local spots = { { 0, 5, 0, 5 }, { 1, -5, 0, 5 }, { 0, 5, 1, -5 }, { 1, -5, 1, -5 } }
			for j = 1, i >= 5 and 4 or 2 do
				local sp = spots[j]
				local star = img(card, Config.VFX.sparkle, j % 2 == 0 and WHITE or light, 46, 6, 0.1)
				star.Position = UDim2.new(sp[1], sp[2], sp[3], sp[4])
				table.insert(stars, star)
			end
		end
		table.insert(auraPreviews, { halo = halo, rays = rays, ring = ring, core = core, coreSize = coreSize, sparks = sparks, stars = stars, stroke = cardStroke, rainbow = i == n and n > 1, speed = 0.8 + 0.5 * k, phase = i * 1.3 })
		-- nivel del aura (estrellas) y si ya es tuya
		local rating = string.format('<font color="#FFD23F">%s</font>', string.rep("★", i))
		if i < n then
			rating ..= string.format('<font color="#6A5F8C">%s</font>', string.rep("★", n - i))
		end
		label({ Parent = card, Font = BTN, Text = rating, Size = UDim2.fromOffset(110, 18), Position = UDim2.fromOffset(18, 8), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7, StrokeThickness = 1.5 })
		if owned then
			label({ Parent = card, Font = BTN, Text = t("owned"), Size = UDim2.fromOffset(100, 18), Position = UDim2.new(1, -18, 0, 8), AnchorPoint = Vector2.new(1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = eq and GREEN or Color3.fromRGB(215, 205, 245), ZIndex = 7, StrokeThickness = 1.5 })
		end
		label({ Parent = card, Font = TITLE, Text = Locale.name(a), Size = UDim2.new(1, -20, 0, 28), Position = UDim2.fromOffset(10, 106), TextColor3 = WHITE, ZIndex = 7 })
		local eff = {}
		if a.speed then
			table.insert(eff, string.format("+%s%% ⚡", pct(a.speed)))
		end
		if a.money then
			table.insert(eff, string.format("+%s%% 💰", pct(a.money)))
		end
		label({ Parent = card, Font = BTN, Text = table.concat(eff, "   "), Size = UDim2.new(1, -20, 0, 22), Position = UDim2.fromOffset(10, 135), TextColor3 = light, ZIndex = 7, StrokeThickness = 2 })
		-- un solo botón: comprar (verde si te llega el dinero), equipar o "equipada"
		local btnText, btnColor, onClick
		if eq then
			btnText, btnColor = "✅ " .. t("equipped"), GREY
		elseif owned then
			btnText, btnColor = t("equip"), Config.VENDORS.aura.color
			onClick = function()
				Action:FireServer("equipAura", a.id)
			end
		else
			-- en gris también se puede tocar: el servidor responde "no tienes suficiente dinero"
			btnText, btnColor = "💰 " .. Format.num(a.cost), money >= a.cost and GREEN or GREY
			onClick = function()
				Action:FireServer("buyAura", a.id)
			end
		end
		button({ Parent = card, Text = btnText, Size = UDim2.new(1, -24, 0, 46), Position = UDim2.new(0, 12, 1, -56), Color = btnColor, ZIndex = 7, OnClick = onClick })
	end
end

signatures.coachShop = function()
	local money = state.money or 0
	local mine = state.coaches or {}
	local s = ""
	for _, co in ipairs(Config.COACHES) do
		s ..= money >= co.cost and "y" or "n"
		for tier = 1, #Config.COACH_TIERS do
			s ..= "," .. tostring(mine[co.id .. ":" .. tier] or 0)
		end
		s ..= "|"
	end
	return s
end

renderers.coachShop = function()
	listLayout()
	local money = state.money or 0
	local mine = state.coaches or {}
	local vc = Config.VENDORS.coach.color
	-- misma regla que el servidor (Core.computeMults): cada pila cuenta hasta COACH_EQUIP copias
	-- y se suman los COACH_EQUIP mejores
	local list = {}
	for _, co in ipairs(Config.COACHES) do
		for tier, tierInfo in ipairs(Config.COACH_TIERS) do
			local key = co.id .. ":" .. tier
			for _ = 1, math.min(tonumber(mine[key]) or 0, Config.COACH_EQUIP) do
				table.insert(list, { key = key, bonus = co.bonus * tierInfo.mult, name = tier > 1 and (Locale.name(co) .. " " .. Locale.name(tierInfo)) or Locale.name(co) })
			end
		end
	end
	table.sort(list, function(x, y)
		if x.bonus ~= y.bonus then
			return x.bonus > y.bonus
		end
		return x.key < y.key
	end)
	local total, used, names = 0, {}, {}
	for j = 1, math.min(Config.COACH_EQUIP, #list) do
		total += list[j].bonus
		used[list[j].key] = true
		table.insert(names, list[j].name)
	end
	-- cabecera: bonus total de tus mejores entrenadores
	local head = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, -14, 0, 80), LayoutOrder = 0, ZIndex = 11, Parent = content }, {
		corner(16),
		gradient(darker(vc, 0.6), Color3.fromRGB(34, 22, 52), 0),
		stroke(vc, 3),
	})
	label({ Parent = head, Font = TITLE, Text = string.format("%s · %d / %d", t("coaches"), #names, Config.COACH_EQUIP), Size = UDim2.new(0.64, -24, 0, 34), Position = UDim2.fromOffset(14, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = WHITE, ZIndex = 12 })
	label({ Parent = head, Font = BTN, Text = #names > 0 and table.concat(names, "  +  ") or "—", Size = UDim2.new(0.64, -24, 0, 26), Position = UDim2.fromOffset(14, 46), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 232, 190), ZIndex = 12 })
	label({ Parent = head, Font = TITLE, Text = string.format("+%s%% ⚡", pct(total)), Size = UDim2.new(0.36, -14, 1, -18), Position = UDim2.new(0.64, 0, 0, 9), TextColor3 = CYAN, ZIndex = 12, StrokeThickness = 3 })
	-- un entrenador por fila para comprar y, debajo, tus pilas por nivel con el botón de fusionar
	local order = 0
	local tierColors = { CYAN, GOLD, PINK, Color3.fromRGB(120, 255, 120) }
	for _, co in ipairs(Config.COACHES) do
		order += 1
		local have = 0
		for tier = 1, #Config.COACH_TIERS do
			have += tonumber(mine[co.id .. ":" .. tier]) or 0
		end
		-- en gris también se puede tocar: el servidor responde "no tienes suficiente dinero"
		row(order, "🏋️", Locale.name(co), string.format("+%s%% ⚡   ·   %s: %d", pct(co.bonus), t("youHave"), have), "💰 " .. Format.num(co.cost), money >= co.cost and GREEN or GREY, true, function()
			Action:FireServer("buyCoach", co.id)
		end, vc)
		for tier, tierInfo in ipairs(Config.COACH_TIERS) do
			local key = co.id .. ":" .. tier
			local count = tonumber(mine[key]) or 0
			if count > 0 then
				order += 1
				local canFuse = count >= 2 and tier < #Config.COACH_TIERS
				row(order, used[key] and "✅" or "⭐", string.format("%s %s ×%d", Locale.name(co), Locale.name(tierInfo), count), string.format("+%s%% ⚡", pct(co.bonus * tierInfo.mult)), canFuse and t("fuse") or nil, PINK, canFuse, function()
					Action:FireServer("fuseCoach", co.id, tier)
				end, tierColors[tier] or CYAN)
			end
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
		local icons = { speed2x = "⚡", money2x = "💰", luck2x = "🍀", moreSlots = "📦", vip = "👑" }
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
	local s = tab .. tostring(state.spawnLuck)
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
			-- lo que aparece en el mundo solo depende de la suerte del servidor (tu suerte mejora los sobres al llegar a casa)
			local odds = Config.odds(zi, state.spawnLuck or 1)
			local order = zi * 100
			for r = 1, #Config.RARITIES do
				local chance = odds[r]
				if chance and chance > 0 then
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
	-- LayoutOrder = order × 10: deja hueco para meter botones entre medias (Misiones va en el 15)
	local b = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, Size = UDim2.fromOffset(200, 60), LayoutOrder = order * 10, Parent = side }, {
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

local function openShop()
	openPanel("shop", "🛒 " .. t("shop") .. " · " .. t("upgrades"), nil, CYAN)
end
local function openIndex()
	openPanel("index", "📖 " .. t("indexTitle"), { { id = "gods", text = t("index") }, { id = "rewards", text = "🎁" }, { id = "odds", text = "🎲 " .. t("odds") } }, GOLD)
end
sideButton(2, "📖", t("index"), GOLD, openIndex)
local shopButton = sideButton(1, "🛒", t("shop"), Color3.fromRGB(255, 80, 60), openShop)
signatures.settings = function()
	local st = state.settings or {}
	return string.format("%s%s%s%s%s%s%s%s", tostring(st.sfx), tostring(st.music), tostring(st.particles), tostring(st.shake), tostring(st.othersAuras), tostring(st.ui), tostring(st.ownerPasses), tostring(state.isOwner))
end
renderers.settings = function()
	listLayout()
	local st = state.settings or { sfx = true, music = true, particles = true, shake = true, othersAuras = true, ui = 2 }
	local function send(key, value)
		local copy = {}
		for k, v in pairs(st) do
			copy[k] = v
		end
		copy[key] = value
		state.settings = copy
		Action:FireServer("settings", copy)
		updateScale()
		render(true)
	end
	local rows = {
		{ "🔊", "sfx", t("sfx") },
		{ "🎵", "music", t("music") },
		{ "✨", "particles", t("particlesOpt") },
		{ "📳", "shake", t("shakeOpt") },
		{ "🌀", "othersAuras", t("othersAuras") },
	}
	for i, r in ipairs(rows) do
		local on = st[r[2]] ~= false
		row(i, r[1], r[3], "", on and t("on") or t("off"), on and GREEN or Color3.fromRGB(255, 80, 100), true, function()
			send(r[2], not on)
		end, on and GREEN or Color3.fromRGB(255, 80, 100))
	end
	if state.isOwner then
		local on = st.ownerPasses == true
		row(9, "👑", t("ownerPasses"), "", on and t("on") or t("off"), on and GREEN or Color3.fromRGB(255, 80, 100), true, function()
			send("ownerPasses", not on)
		end, GOLD)
	end
	local sizes = { t("small"), t("normal"), t("big") }
	local ui = st.ui or 2
	row(10, "🔠", t("uiSize"), sizes[ui], sizes[ui % 3 + 1] .. " →", CYAN, true, function()
		send("ui", ui % 3 + 1)
	end, CYAN)
	local pad = UserInputService.GamepadEnabled
	sectionTitle(20, "🎮 " .. t("controls"), GOLD)
	local use = string.format("%s / %s / %s", t("steal"), t("open"), t("talk"))
	local lines = pad and {
		"R2 · " .. t("tap"), "X · " .. use, "A · " .. t("jumpButton"), "L2 · " .. t("dropPack"), "Y · " .. t("shop"), "↑ · " .. t("index"), "↓ · " .. t("missions"), "← · " .. t("afk"), "→ · " .. t("settings"), "B · " .. t("close"),
	} or {
		"E · " .. t("tap"), "E · " .. use, t("spaceKey") .. " · " .. t("jumpButton"), "Q · " .. t("dropPack"), "B · " .. t("shop"), "I · " .. t("index"), "M · " .. t("missions"), "F · " .. t("afk"), "G · " .. t("settings"), "X · " .. t("close"),
	}
	for i, l in ipairs(lines) do
		label({ Parent = content, LayoutOrder = 20 + i, Size = UDim2.new(1, -14, 0, 26), Font = BTN, TextXAlignment = Enum.TextXAlignment.Left, Text = "   " .. l, ZIndex = 11 })
	end
end

sideButton(3, "💎", t("robux"), GREEN, function()
	openPanel("robux", "💎 Robux", { { id = "passes", text = t("passes") }, { id = "products", text = t("products") } }, GREEN)
end)
local afkButton = sideButton(4, "💤", t("afk"), PURPLE, function()
	Action:FireServer("afk", not state.afk)
end)
local function openSettings()
	openPanel("settings", "⚙️ " .. t("settings"), nil, Color3.fromRGB(200, 200, 220))
end
sideButton(5, "⚙️", t("settings"), Color3.fromRGB(150, 150, 175), openSettings)

---------------------------------------------------------------------
-- Controles de PC (teclado) y consola (mando de PS5/Xbox)
---------------------------------------------------------------------
local ContextActionService = game:GetService("ContextActionService")
local GuiService = game:GetService("GuiService")
-- fn devuelve true si la acción hizo algo. Si no, la tecla sigue su camino (Pass) para que
-- la reciban los ProximityPrompt (robar, abrir, hablar con un vendedor) y el resto del juego.
local function bind(name, fn, ...)
	ContextActionService:BindAction(name, function(_, inputState)
		if inputState == Enum.UserInputState.Begin and fn() then
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	end, false, ...)
end
local function focusPanel()
	if UserInputService.GamepadEnabled and panel.Visible then
		task.defer(function()
			for _, c in ipairs(content:GetDescendants()) do
				if c:IsA("GuiButton") and c.Visible then
					GuiService.SelectedObject = c
					return
				end
			end
		end)
	end
end
-- (las teclas se enlazan más abajo, después de la cinta: usan `tread` y `doTap`)

---------------------------------------------------------------------
-- Cinta: bloqueado corriendo y toques de combo que salen por la pantalla
-- (el servidor decide cuándo, dónde y si se acertó; aquí solo se dibujan)
---------------------------------------------------------------------
local Combo = Remotes:WaitForChild("Combo")
local TapRemote = Remotes:WaitForChild("Tap")
local shake -- temblor de cámara: se define más abajo (apertura de sobres); aquí solo se usa dentro de funciones
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

-- Panel compacto abajo en el centro: combo, toques seguidos, barra hasta el siguiente nivel y cómo bajar
local tread = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(0, 460, 0, 96), Position = UDim2.new(0.5, 0, 1, -96), AnchorPoint = Vector2.new(0.5, 1), Visible = false, Parent = gui }, {
	corner(20),
	gradient(Color3.fromRGB(20, 60, 90), Color3.fromRGB(14, 12, 40), 90),
	stroke(CYAN, 3),
})
local comboLabel = heavy({ Parent = tread, Size = UDim2.new(1, -24, 0, 34), Position = UDim2.fromOffset(12, 6), TextColor3 = CYAN, StrokeThickness = 2.5 })
local tierBack = new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 34, 80), Size = UDim2.new(1, -24, 0, 12), Position = UDim2.fromOffset(12, 44), Parent = tread }, { corner(6) })
local tierFill = new("Frame", { BackgroundColor3 = GOLD, Size = UDim2.new(0, 0, 1, 0), Parent = tierBack }, { corner(6), gradient(GOLD, Color3.fromRGB(255, 120, 60), 0) })
local leaveLabel = label({ Parent = tread, Font = BTN, Size = UDim2.new(1, -24, 0, 26), Position = UDim2.fromOffset(12, 62), TextColor3 = Color3.fromRGB(205, 225, 255) })
new("UITextSizeConstraint", { MaxTextSize = 20, Parent = leaveLabel })
local tapButton = tread -- el tutorial resalta este panel en el paso del combo

-- Texto de la tecla según el aparato
local function deviceKey(kind)
	local pad = UserInputService.GamepadEnabled and not UserInputService.KeyboardEnabled
	local touch = UserInputService.TouchEnabled and not UserInputService.KeyboardEnabled
	if kind == "jump" then
		return pad and "A / ✕" or (touch and t("jumpButton") or t("spaceKey"))
	end
	return pad and "R2" or (touch and "" or "E / Click")
end

-- Capa de los toques (no bloquea el resto de la pantalla: solo los botones reciben el toque)
local tapLayer = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 18, Parent = gui })
local activeTap = nil

local function sparkBurst(pos, color, n)
	for k = 1, n do
		local sz = math.random(10, 20)
		local p = new("Frame", { BackgroundColor3 = k % 3 == 0 and WHITE or color, Size = UDim2.fromOffset(sz, sz), Position = pos, AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, ZIndex = 20, Parent = tapLayer }, { corner(4) })
		local a = math.random() * math.pi * 2
		local d = math.random(60, 160)
		TweenService:Create(p, TweenInfo.new(0.5 + math.random() * 0.3, Enum.EasingStyle.Quint), { Position = pos + UDim2.fromOffset(math.cos(a) * d, math.sin(a) * d), Rotation = math.random(-200, 200), BackgroundTransparency = 1 }):Play()
		task.delay(0.9, function()
			p:Destroy()
		end)
	end
end

local function removeTap(tp)
	if activeTap == tp then
		activeTap = nil
	end
	if tp and tp.button and tp.button.Parent then
		local sc = tp.button:FindFirstChildOfClass("UIScale")
		if sc then
			TweenService:Create(sc, TweenInfo.new(0.12), { Scale = 0 }):Play()
		end
		local b = tp.button
		task.delay(0.13, function()
			b:Destroy()
		end)
	end
end

-- Toca el toque activo (botón, tecla E / clic, gatillo R2 del mando)
local lastEmptyTap = 0
local function doTap(fromKey)
	local tp = activeTap
	if not tp then
		-- Con teclado o mando, pulsar sin círculo en la cinta cuenta como fallo (no vale machacar a ciegas)
		if fromKey and state.onTreadmill and not state.afk then
			if os.clock() - lastEmptyTap > 0.25 then
				lastEmptyTap = os.clock()
				Combo:FireServer(0)
			end
			return true
		end
		return false
	end
	Combo:FireServer(tp.id)
	sparkBurst(tp.button.Position, tp.color, 14)
	play("reward", 1 + math.min(30, tp.number) * 0.03)
	removeTap(tp)
	return true
end

local function showTap(data)
	if activeTap then
		removeTap(activeTap)
	end
	local number = (tonumber(data.hits) or 0) + 1
	local mult = Config.tapMult(number)
	local tierColors = { [2] = CYAN, [3] = GREEN, [4] = PURPLE, [5] = GOLD }
	local color = tierColors[mult] or CYAN
	local size = 132
	local b = new("TextButton", {
		Text = "",
		AutoButtonColor = false,
		BackgroundColor3 = WHITE,
		Size = UDim2.fromOffset(size, size),
		Position = UDim2.fromScale(tonumber(data.x) or 0.5, tonumber(data.y) or 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = 19,
		Parent = tapLayer,
	}, {
		corner(size),
		gradient(color:Lerp(WHITE, 0.25), darker(color, 0.45), 90),
		stroke(WHITE, 5),
	})
	-- aro dorado que se cierra: cuando llega al botón, el toque caduca
	local ring = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(2, 2), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 19, Parent = b }, { corner(999), stroke(GOLD, 6) })
	TweenService:Create(ring, TweenInfo.new(tonumber(data.life) or 1.8, Enum.EasingStyle.Linear), { Size = UDim2.fromScale(1.04, 1.04) }):Play()
	local glow = new("ImageLabel", { BackgroundTransparency = 1, Image = Config.VFX.glow, ImageColor3 = color, ImageTransparency = 0.35, Size = UDim2.fromScale(2.2, 2.2), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 18, Parent = b })
	TweenService:Create(glow, TweenInfo.new(0.6, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { ImageTransparency = 0.7 }):Play()
	heavy({ Parent = b, Text = tostring(number), Size = UDim2.new(1, -20, 0.5, 0), Position = UDim2.new(0, 10, 0.12, 0), ZIndex = 20, StrokeThickness = 4 })
	heavy({ Parent = b, Text = "x" .. mult, Size = UDim2.new(1, -30, 0.28, 0), Position = UDim2.new(0, 15, 0.6, 0), TextColor3 = GOLD, ZIndex = 20, StrokeThickness = 3 })
	local key = deviceKey("tap")
	if key ~= "" then
		label({ Parent = b, Font = BTN, Text = key, Size = UDim2.new(1, 0, 0, 22), Position = UDim2.new(0, 0, 1, 6), ZIndex = 20, StrokeThickness = 2 })
	end
	local sc = new("UIScale", { Scale = 0.2, Parent = b })
	TweenService:Create(sc, TweenInfo.new(0.28, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	local tp = { id = data.id, button = b, color = color, number = number }
	b.Activated:Connect(function()
		if activeTap == tp then
			doTap()
		end
	end)
	activeTap = tp
	play("pop", 1.3)
end

TapRemote.OnClientEvent:Connect(function(data)
	if type(data) ~= "table" then
		return
	end
	if data.hit then
		local mult = tonumber(data.mult) or 1
		if data.up then
			-- sube de nivel: cartel grande en el centro
			floatText("🔥 COMBO x" .. mult .. "!", GOLD, gui, UDim2.new(0.5, -100, 0.42, 0))
			bump(tread, 1.25)
			shake(0.25, 0.25)
		else
			floatText("+1  ·  x" .. mult, GREEN, tread, UDim2.new(0.5, -100, 0, -16))
		end
	elseif data.missed or data.reset then
		if activeTap and (data.reset or activeTap.id == data.missed) then
			removeTap(activeTap)
		end
		if data.lost then
			floatText(t("comboLost"), Color3.fromRGB(255, 80, 90), gui, UDim2.new(0.5, -100, 0.42, 0))
			bump(tread, 0.85)
			play("whoosh", 0.6)
		end
	elseif data.id then
		showTap(data)
	end
end)

-- Saltar baja de la cinta (y sale del modo AFK)
local lastLeave = 0
UserInputService.JumpRequest:Connect(function()
	if (state.onTreadmill or state.afk) and os.clock() - lastLeave > 0.6 then
		lastLeave = os.clock()
		Action:FireServer("leaveTreadmill")
	end
end)

-- Teclas y botones del mando. Van aquí, DESPUÉS de declarar `tread` y `doTap`: una función que
-- nombra un local declarado más abajo no lo captura (leería un global nil).
bind("SAG_Tap", function()
	-- En la cinta la tecla es del combo (sin círculo = fallo); fuera, sigue su camino (robar, abrir, hablar)
	return doTap(true)
end, Enum.KeyCode.E, Enum.KeyCode.ButtonR2)
bind("SAG_Drop", function()
	if state.carrying then
		Action:FireServer("dropPack")
		return true
	end
	return false
end, Enum.KeyCode.Q, Enum.KeyCode.ButtonL2)
bind("SAG_Shop", function()
	openShop()
	focusPanel()
	return true
end, Enum.KeyCode.B, Enum.KeyCode.ButtonY)
bind("SAG_Index", function()
	openIndex()
	focusPanel()
	return true
end, Enum.KeyCode.I, Enum.KeyCode.DPadUp)
bind("SAG_AFK", function()
	Action:FireServer("afk", not state.afk)
	return true
end, Enum.KeyCode.F, Enum.KeyCode.DPadLeft)
bind("SAG_Settings", function()
	openSettings()
	focusPanel()
	return true
end, Enum.KeyCode.G, Enum.KeyCode.DPadRight)
local missionsMod = nil -- se rellena al arrancar el módulo Missions (abajo)
bind("SAG_Missions", function()
	if missionsMod and missionsMod.open then
		missionsMod.open()
		focusPanel()
		return true
	end
	return false
end, Enum.KeyCode.M, Enum.KeyCode.DPadDown)
bind("SAG_Close", function()
	if panel.Visible and not panelState.closing then
		closePanel()
		GuiService.SelectedObject = nil
		return true
	end
	return false
end, Enum.KeyCode.X, Enum.KeyCode.ButtonB)

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
-- Sobre en 3D (el de verdad, de ReplicatedStorage.PackTemplates): gira, se carga, sube de rareza y se rompe
local packVP = new("ViewportFrame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1.7, 1.35), Position = UDim2.fromScale(0.5, 0.45), AnchorPoint = Vector2.new(0.5, 0.5), Ambient = Color3.fromRGB(175, 170, 195), LightColor = WHITE, LightDirection = Vector3.new(-0.6, -1, 0.8), ZIndex = 33, Parent = packCard })
local packCam = new("Camera", { FieldOfView = 30, Parent = packVP })
packVP.CurrentCamera = packCam
local packModel = nil
local packRevealToken = 0 -- para que el cierre retrasado de un sobre no esconda el siguiente
local function setPackModel(r)
	if packModel then
		packModel:Destroy()
		packModel = nil
	end
	local folder = ReplicatedStorage:FindFirstChild("PackTemplates")
	local tpl = folder and folder:FindFirstChild("R" .. tostring(r))
	if not tpl then
		return false
	end
	packModel = tpl:Clone()
	packModel.Parent = packVP
	local _, size = packModel:GetBoundingBox()
	local dim = math.max(size.X, size.Y, 4)
	packCam.CFrame = CFrame.lookAt(Vector3.new(0, 0.3, -dim * 2.9), Vector3.new(0, 0.1, 0))
	return true
end
-- Las dos mitades del sobre salen volando al romperse
local function packHalves(color)
	if packModel then
		packModel:Destroy()
		packModel = nil
	end
	local halves = {}
	for s = -1, 1, 2 do
		local h = new("Part", { Anchored = true, Size = Vector3.new(1.5, 4, 0.5), Color = color, Material = Enum.Material.Foil, CFrame = CFrame.new(s * 0.75, 0, 0), Parent = packVP })
		table.insert(halves, { part = h, s = s })
	end
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function()
		local e = os.clock() - t0
		for _, it in ipairs(halves) do
			it.part.CFrame = CFrame.new(it.s * (0.75 + e * 11), e * 5 - e * e * 14, e * 2) * CFrame.Angles(e * 7, it.s * e * 3, it.s * e * 6)
			it.part.Transparency = math.clamp(e / 0.55, 0, 1)
		end
		if e > 0.6 then
			conn:Disconnect()
			for _, it in ipairs(halves) do
				it.part:Destroy()
			end
		end
	end)
end
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

function shake(power, duration)
	if not opt("shake") then
		return
	end
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
	packRevealToken += 1
	packCard.Visible = true
	rays.Visible = true
	for _, r in ipairs(rayFrames) do
		r.BackgroundColor3 = rc
	end
	TweenService:Create(reveal, TweenInfo.new(0.4), { BackgroundTransparency = 0.15 }):Play()
	-- el sobre empieza con SU rareza; la suerte puede subirlo durante la carga (fromR → toR)
	local fromR = math.clamp(tonumber(data.fromR) or g.r, 1, #Config.RARITIES)
	local toR = math.clamp(tonumber(data.toR) or g.r, fromR, #Config.RARITIES)
	local rcFrom = rcolor(fromR)
	for _, r in ipairs(rayFrames) do
		r.BackgroundColor3 = rcFrom
	end
	local has3D = setPackModel(fromR)
	packCard.BackgroundTransparency = has3D and 1 or 0
	packStroke.Transparency = has3D and 1 or 0
	packLabel.Position = has3D and UDim2.new(0, 10, 1, -14) or UDim2.new(0, 10, 0.5, -30)
	packGrad.Color = ColorSequence.new(rcFrom, darker(rcFrom, 0.35))
	packStroke.Color = WHITE
	packLabel.Text = string.upper(Locale.name(Config.RARITIES[fromR]))
	packLabel.TextColor3 = has3D and rcFrom:Lerp(WHITE, 0.35) or WHITE
	packScale.Scale = 0
	TweenService:Create(packScale, TweenInfo.new(0.45, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	play("pop")
	-- 2) carga con temblor que aumenta (más larga si sube de rareza: un salto por rareza)
	local ups = {}
	local nUp = toR - fromR
	local charge = 1.1 + math.min(g.r, 10) * 0.14 + nUp * 0.4
	for i = 1, nUp do
		ups[i] = { r = fromR + i, at = charge * (0.3 + 0.55 * i / nUp) }
	end
	local nextUp = 1
	local angle = math.pi
	local t0 = os.clock()
	local conn
	conn = RunService.RenderStepped:Connect(function(dt)
		local e = os.clock() - t0
		local k = math.clamp(e / charge, 0, 1)
		rays.Rotation += dt * (30 + k * 260)
		if packModel then
			-- gira cada vez más rápido, tiembla y se inclina
			angle += dt * (1.4 + k * k * 18)
			local j = 0.18 * k
			packModel:PivotTo(CFrame.new((math.random() - 0.5) * j, (math.random() - 0.5) * j, 0) * CFrame.Angles(math.sin(e * 3) * 0.12, angle, math.sin(e * 22) * 0.1 * k))
		else
			packCard.Rotation = (math.random() - 0.5) * 14 * k
		end
		packCard.Position = UDim2.new(0.5, (math.random() - 0.5) * 18 * k, 0.5, (math.random() - 0.5) * 18 * k)
		packScale.Scale = 1 + 0.12 * k + math.sin(e * 18) * 0.03 * k
		-- ¡sube de rareza! cambia el sobre, los rayos y el nombre con un destello
		local up = ups[nextUp]
		if up and e >= up.at then
			nextUp += 1
			local c = rcolor(up.r)
			if has3D then
				setPackModel(up.r)
			end
			packGrad.Color = ColorSequence.new(c, darker(c, 0.35))
			packLabel.Text = "⬆️ " .. string.upper(Locale.name(Config.RARITIES[up.r]))
			packLabel.TextColor3 = has3D and c:Lerp(WHITE, 0.35) or WHITE
			for _, r in ipairs(rayFrames) do
				r.BackgroundColor3 = c
			end
			flash.BackgroundTransparency = 0.45
			TweenService:Create(flash, TweenInfo.new(0.3), { BackgroundTransparency = 1 }):Play()
			burst(c, 14)
			play("reward", 0.9 + nextUp * 0.12)
			shake(0.35, 0.2)
		end
		if rarity.rainbow or rarity.sparkle then
			local hue = (os.clock() * 0.5) % 1
			packStroke.Color = Color3.fromHSV(hue, 0.7, 1)
		end
		if e >= charge then
			conn:Disconnect()
		end
	end)
	task.wait(charge)
	-- 3) destello + explosión (el sobre 3D se parte en dos)
	for _, r in ipairs(rayFrames) do
		r.BackgroundColor3 = rc
	end
	if has3D then
		packHalves(rc)
		packLabel.Text = ""
		packRevealToken += 1
		local my = packRevealToken
		task.delay(0.6, function()
			if my == packRevealToken then
				packCard.Visible = false
			end
		end)
	else
		packCard.Visible = false
	end
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
	-- Mutación (Dorado, Hielo, Diamante, Lava, Arcoíris): cinta del color de la mutación y su multiplicador
	local mut = data.mut and Config.MUTATION_BY_ID and Config.MUTATION_BY_ID[data.mut]
	if mut then
		ribbon.BackgroundColor3 = mut.color
		ribbonLabel.Text = string.format("%s %s · %s x%d", mut.icon, string.upper(Locale.name(mut)), string.upper(Locale.name(rarity)), mut.mult)
		ribbonLabel.TextColor3 = DARK
		godNameGrad.Color = ColorSequence.new(mut.color, rc)
	end
	local upgraded = tonumber(data.fromR) and tonumber(data.toR) and data.toR > data.fromR
	if upgraded then
		ribbonLabel.Text = "⬆️ " .. ribbonLabel.Text
	end
	local kg = data.kg or 100
	godIncome.Text = string.format("⚖️ %d kg   💰 +%s/s", kg, Format.num(rarity.income * (kg / 100) * (mut and mut.mult or 1) * (state.moneyMult or 1)))
	godFact.Text = Locale.lang() == "es" and g.factEs or g.factEn
	godNew.Text = data.isNew and t("gotNew") or ""
	godCard.Visible = true
	godScale.Scale = 0.2
	TweenService:Create(godScale, TweenInfo.new(0.55, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	play("reward", 0.7)
	if data.isNew then
		bump(godNew, 1.6)
	end
	if mut then
		bump(ribbon, 1.25)
		if mut.mult >= 6 then
			shake(0.6, 0.35)
		end
	end
	if upgraded then
		floatText(t("upgraded", Locale.name(Config.RARITIES[data.fromR]), Locale.name(Config.RARITIES[data.toR])), Color3.fromRGB(110, 255, 140), gui, UDim2.new(0.5, -100, 0.12, 0))
		bump(ribbon, 1.35)
		shake(0.45, 0.3)
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

-- avisos de premio (misiones, racha, tutorial): en verde y con sonido
local GOOD_TOASTS = { bought = true, afkOn = true, missionDone = true, missionAuto = true, tutorialDone = true, rewardMoney = true, rewardLuck = true, rewardSpeed = true, rewardPack = true, luckUpgrade = true }
Remotes:WaitForChild("Toast").OnClientEvent:Connect(function(key, args)
	local good = GOOD_TOASTS[key] == true
	toast(fmtKey(key, args), good and GREEN or (key == "notEnough" and Color3.fromRGB(255, 90, 100) or GOLD))
	if good then
		play("reward", 1.2)
	end
	if hooks.toast then
		pcall(hooks.toast, key, args)
	end
end)

-- Vuelo cuando un guardián te atrapa: das vueltas por el aire con estela, estrellitas y la cámara se abre
local flying = false
local function launchFlight(vel, T)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if not hrp or not hum or flying then
		return
	end
	flying = true
	hum.PlatformStand = true
	hrp.AssemblyLinearVelocity = vel
	local axis = Vector3.new(math.random() - 0.5, 0, math.random() - 0.5)
	axis = axis.Magnitude > 0.05 and axis.Unit or Vector3.new(1, 0, 0)
	hrp.AssemblyAngularVelocity = axis * 9
	-- estela blanca y dorada
	local a0 = new("Attachment", { Position = Vector3.new(0, 1.2, 0), Parent = hrp })
	local a1 = new("Attachment", { Position = Vector3.new(0, -1.2, 0), Parent = hrp })
	local trail = new("Trail", {
		Attachment0 = a0,
		Attachment1 = a1,
		Lifetime = 0.45,
		LightEmission = 0.7,
		Color = ColorSequence.new(WHITE, GOLD),
		Transparency = NumberSequence.new(0.2, 1),
		WidthScale = NumberSequence.new(1, 0),
		FaceCamera = true,
		Parent = hrp,
	})
	-- estrellitas girando sobre la cabeza
	local head = char:FindFirstChild("Head")
	local stars = head and new("BillboardGui", { Size = UDim2.fromOffset(110, 44), StudsOffset = Vector3.new(0, 2.6, 0), AlwaysOnTop = true, Parent = head }, {
		label({ Text = "💫 💥 💫", Size = UDim2.fromScale(1, 1), TextScaled = true }),
	})
	floatText(t("flying"), Color3.fromRGB(255, 120, 90), gui, UDim2.new(0.5, -100, 0.36, 0))
	shake(1.1, 0.5)
	play("whoosh", 0.6)
	play("fly", 1)
	local cam = workspace.CurrentCamera
	local fov = cam.FieldOfView
	if opt("shake") then
		TweenService:Create(cam, TweenInfo.new(0.25, Enum.EasingStyle.Quad), { FieldOfView = math.min(100, fov + 18) }):Play()
	end
	local spin = stars and RunService.RenderStepped:Connect(function()
		stars.StudsOffset = Vector3.new(math.sin(os.clock() * 8) * 0.4, 2.6, 0)
	end)
	task.delay(T, function()
		if spin then
			spin:Disconnect()
		end
		if stars then
			stars:Destroy()
		end
		trail.Enabled = false
		task.delay(0.5, function()
			trail:Destroy()
			a0:Destroy()
			a1:Destroy()
		end)
		if hrp.Parent then
			hrp.AssemblyAngularVelocity = Vector3.zero
			local _, yaw = hrp.CFrame:ToEulerAnglesYXZ()
			hrp.CFrame = CFrame.new(hrp.Position) * CFrame.Angles(0, yaw, 0)
		end
		if hum.Parent then
			hum.PlatformStand = false
			hum:ChangeState(Enum.HumanoidStateType.GettingUp)
		end
		if opt("shake") then
			TweenService:Create(cam, TweenInfo.new(0.4, Enum.EasingStyle.Quad), { FieldOfView = fov }):Play()
		end
		shake(0.6, 0.25)
		play("thud", 0.8)
		flying = false
	end)
end

Remotes:WaitForChild("Knock").OnClientEvent:Connect(function(vel, opts)
	if type(opts) == "table" and opts.flight then
		launchFlight(vel, tonumber(opts.time) or 1.3)
		return
	end
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
	-- las misiones solo llegan cuando cambian: si no vienen, se conservan las anteriores
	if s.quests == nil then
		s.quests = state.quests
	end
	state = s
	stateAt = os.clock()
	-- el panel abierto se repinta en cuanto cambia algo suyo (compras, dinero suficiente…)
	render(false)
	if hooks.state then
		pcall(hooks.state, s)
	end
end)

---------------------------------------------------------------------
-- Carteles del mundo en tu idioma
---------------------------------------------------------------------
-- Suerte con separador de miles en el idioma del jugador: x93.754 / x93,754
local function luckText(n)
	return Format.group(n, Locale.lang() == "es" and "." or ",")
end

local function locLabel(bb)
	local l = bb:FindFirstChild("Label")
	if not l then
		return
	end
	l.Font = TITLE
	-- Cartel de un vendedor: arriba lo que vende (grande) y debajo su nombre y título (más pequeño)
	local vendorKey = bb:GetAttribute("Vendor")
	if vendorKey then
		local v = Config.VENDORS[vendorKey]
		if v then
			local sub = bb:FindFirstChild("SubLabel")
			if not sub then
				l.Size = UDim2.fromScale(1, 0.62)
				l.Position = UDim2.new()
				sub = new("TextLabel", { Name = "SubLabel", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 0.36), Position = UDim2.fromScale(0, 0.64), Font = BTN, TextScaled = true, TextStrokeTransparency = 0.2, Parent = bb })
			end
			l.TextColor3 = v.color
			l.Text = t(vendorKey == "aura" and "auraSign" or "coachSign")
			sub.TextColor3 = v.color:Lerp(WHITE, 0.6)
			sub.Text = string.format("%s · %s", Locale.name(v), Locale.lang() == "es" and v.titleEs or v.titleEn)
		end
		return
	end
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
			l.Text = string.format("%s · %d kg · 🍀 x%s\n%s", Locale.name(Config.RARITIES[r]), bb:GetAttribute("Kg") or 100, luckText(bb:GetAttribute("Luck") or 1), rem <= 0 and ("✨ " .. t("ready")) or ("⏳ " .. Format.time(rem)))
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
		l.Text = string.format("%s%s\n<font size=\"16\" color=\"#FFE9A8\">⚖️ %d kg</font>  <font size=\"16\" color=\"#7CFF8A\">🍀 x%s</font>", string.upper(Locale.name(Config.RARITIES[r])), bb:GetAttribute("Dawn") and " 🌅" or "", bb:GetAttribute("Kg") or 100, luckText(bb:GetAttribute("Luck") or 1))
	end
end

local PROMPT_TEXT = { steal = "steal", open = "open", upgradeLuck = "upgradeLuck", upgradeTreadmill = "upgradeTreadmill" }
local function promptOwnerOnly(p)
	local owner = p:GetAttribute("Owner")
	p.Enabled = owner == player.UserId
end
local function locPrompt(p)
	local kind = p:GetAttribute("Kind")
	p.ActionText = t(PROMPT_TEXT[kind] or "open")
	if kind == "upgradeLuck" or kind == "upgradeTreadmill" then
		promptOwnerOnly(p)
		p:GetAttributeChangedSignal("Owner"):Connect(function()
			promptOwnerOnly(p)
		end)
	end
end

-- Carteles de mejora (suerte en la parcela, cinta delante): el servidor pone los números en atributos
local function drawSign(gui)
	local kind = gui:GetAttribute("Kind")
	local level = gui:GetAttribute("Level") or 0
	local title, body, cost = gui:FindFirstChild("Title"), gui:FindFirstChild("Body"), gui:FindFirstChild("Cost")
	if not title or not body or not cost then
		return
	end
	title.Text = t(kind == "luck" and "luckSign" or "treadSign")
	if level <= 0 or not gui:GetAttribute("Owner") then
		body.Text = t("signFree")
		cost.Text = ""
		return
	end
	local max = (gui:GetAttribute("Max") or 1)
	local now, nxt = gui:GetAttribute("Now") or 1, gui:GetAttribute("Next") or 0
	if kind == "luck" then
		body.Text = string.format(t("luckSignBody"), level, Format.mult(now), level >= max and "—" or Format.mult(nxt))
	else
		body.Text = string.format(t("treadSignBody"), level, Format.num(now), level >= max and "—" or Format.num(nxt))
	end
	local c = gui:GetAttribute("Cost") or 0
	local mine = gui:GetAttribute("Owner") == player.UserId
	cost.Text = level >= max and t("max") or string.format("💰 %s%s", Format.num(c), mine and ("  ·  " .. t(kind == "luck" and "upgradeLuck" or "upgradeTreadmill")) or "")
	cost.TextColor3 = (mine and (state.money or 0) >= c) and Color3.fromRGB(110, 255, 140) or Color3.fromRGB(255, 200, 120)
end
local function hookSign(gui)
	drawSign(gui)
	gui.AttributeChanged:Connect(function()
		drawSign(gui)
	end)
end
for _, g in ipairs(CollectionService:GetTagged("UpgradeSign")) do
	hookSign(g)
end
CollectionService:GetInstanceAddedSignal("UpgradeSign"):Connect(hookSign)
-- el color del precio depende de tu dinero: se repasa cada 2 s
task.spawn(function()
	while true do
		task.wait(2)
		for _, g in ipairs(CollectionService:GetTagged("UpgradeSign")) do
			if g:GetAttribute("Owner") == player.UserId then
				drawSign(g)
			end
		end
	end
end)
for _, p in ipairs(CollectionService:GetTagged("LocPrompt")) do
	locPrompt(p)
end
CollectionService:GetInstanceAddedSignal("LocPrompt"):Connect(locPrompt)

-- Vendedores (Hécate y Quirón): al hablar con ellos (ProximityPrompt "VendorPrompt") se abre su panel
do
	local function openVendor(key)
		if key == "aura" then
			openPanel("auraShop", "✨ " .. t("auraShop"), nil, Config.VENDORS.aura.color, t("auraHint"), true)
		elseif key == "coach" then
			openPanel("coachShop", "🏋️ " .. t("coachShop"), nil, Config.VENDORS.coach.color, t("coachHint"), true)
		else
			return
		end
		focusPanel()
	end
	local bound = setmetatable({}, { __mode = "k" })
	local function vendorPrompt(p)
		if bound[p] or not p:IsA("ProximityPrompt") then
			return
		end
		bound[p] = true
		local function localize()
			local key = p:GetAttribute("Vendor")
			local v = key and Config.VENDORS[key]
			if v then
				p.ObjectText = Locale.name(v)
				p.ActionText = key == "aura" and t("auras") or t("coaches")
			end
		end
		localize()
		p:GetAttributeChangedSignal("Vendor"):Connect(localize)
		-- en el cliente, Triggered solo salta cuando lo activa el jugador local
		p.Triggered:Connect(function()
			openVendor(p:GetAttribute("Vendor"))
		end)
	end
	for _, p in ipairs(CollectionService:GetTagged("VendorPrompt")) do
		vendorPrompt(p)
	end
	CollectionService:GetInstanceAddedSignal("VendorPrompt"):Connect(vendorPrompt)
end

---------------------------------------------------------------------
-- Efectos de velocidad (la estela la dibuja el módulo Fx para todos los jugadores)
---------------------------------------------------------------------
RunService.RenderStepped:Connect(function(dt)
	local cam = workspace.CurrentCamera
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and cam then
		local v = Vector3.new(hrp.AssemblyLinearVelocity.X, 0, hrp.AssemblyLinearVelocity.Z).Magnitude
		local goal = 70 + math.clamp((v - 16) / 3, 0, 28)
		cam.FieldOfView += (goal - cam.FieldOfView) * math.min(1, dt * 4)
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
		spinModel:PivotTo(CFrame.new(0, spinModel:GetAttribute("PivotH") or 0, 0) * CFrame.Angles(0, now * 1.2, 0))
	end
	if reveal.Visible then
		rays.Rotation += dt * 25
	end
	-- vistas previas de las auras: solo se mueven mientras el panel de Hécate está abierto
	if panel.Visible and currentPanel == "auraShop" then
		for _, p in ipairs(auraPreviews) do
			local tt = now * p.speed + p.phase
			local pulse = 0.5 + 0.5 * math.sin(tt * 2.6)
			p.rays.Rotation = (tt * 24) % 360
			if p.ring then
				p.ring.Rotation = (-tt * 15) % 360
			end
			local cs = p.coreSize * (0.88 + 0.2 * pulse)
			p.core.Size = UDim2.fromOffset(cs, cs)
			p.halo.ImageTransparency = 0.62 - 0.22 * pulse
			for _, s in ipairs(p.sparks) do
				local a = tt * s.speed + s.phase
				local sz = s.size * (0.55 + 0.6 * (0.5 + 0.5 * math.sin(tt * 4.5 + s.phase * 3)))
				s.img.Position = UDim2.new(0.5, math.cos(a) * s.radius, 0.5, math.sin(a) * s.radius * 0.62)
				s.img.Size = UDim2.fromOffset(sz, sz)
				s.img.Rotation = (tt * 30) % 360
			end
			for j, star in ipairs(p.stars) do
				star.ImageTransparency = 0.05 + 0.55 * (0.5 + 0.5 * math.sin(tt * 3 + j * 1.7))
				star.Rotation = math.sin(tt * 1.4 + j) * 25
			end
			if p.rainbow then
				p.stroke.Color = Color3.fromHSV((now * 0.18) % 1, 0.5, 1)
			end
		end
	end
end)

---------------------------------------------------------------------
-- Modo persecución: viñeta roja que late, ¡CORRE! y soltar sobre
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

-- Viñeta: cuatro bordes rojos degradados en su propia pantalla, por debajo del HUD y sin recibir toques.
-- Cuanto más cerca está el guardián (state.chase), más fuerte y más rápido late.
local chaseFx = { phase = 0, danger = 0, edges = {}, carryStroke = carryPill:FindFirstChildOfClass("UIStroke") }
do
	local fxGui = new("ScreenGui", { Name = "ChaseFx", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = -1, Enabled = false, Parent = gui.Parent })
	pcall(function()
		fxGui.ScreenInsets = Enum.ScreenInsets.None -- cubre también la zona de la muesca del móvil
	end)
	chaseFx.gui = fxGui
	local function edge(size, pos, anchor, rot)
		local f = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 24, 40), BackgroundTransparency = 1, BorderSizePixel = 0, Active = false, Size = size, Position = pos, AnchorPoint = anchor, Parent = fxGui }, {
			new("UIGradient", { Rotation = rot, Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0), NumberSequenceKeypoint.new(0.4, 0.62), NumberSequenceKeypoint.new(1, 1) }) }),
		})
		table.insert(chaseFx.edges, f)
	end
	edge(UDim2.fromScale(1, 0.26), UDim2.fromScale(0, 0), Vector2.new(0, 0), 90) -- arriba
	edge(UDim2.fromScale(1, 0.26), UDim2.fromScale(0, 1), Vector2.new(0, 1), 270) -- abajo
	edge(UDim2.fromScale(0.17, 1), UDim2.fromScale(0, 0), Vector2.new(0, 0), 0) -- izquierda
	edge(UDim2.fromScale(0.17, 1), UDim2.fromScale(1, 0), Vector2.new(1, 0), 180) -- derecha
end

-- Latido (cada fotograma, solo mientras llevas un sobre)
RunService.RenderStepped:Connect(function(dt)
	local carried = state.carrying
	if carried == nil then
		return
	end
	-- peligro de 0 a 1: guardián a 170 bloques o más = 0 · a 30 o menos = 1
	local goal = state.chase and math.clamp((170 - state.chase) / 140, 0, 1) or 0.15
	chaseFx.danger += (goal - chaseFx.danger) * math.min(1, dt * 3)
	local d = chaseFx.danger
	-- de 0.8 a 2.2 latidos por segundo: rápido, pero nunca un parpadeo molesto
	chaseFx.phase += dt * (5 + 9 * d)
	local pulse = 0.5 + 0.5 * math.sin(chaseFx.phase)
	local alpha = 0.2 + 0.32 * d + (0.14 + 0.2 * d) * pulse
	for _, f in ipairs(chaseFx.edges) do
		f.BackgroundTransparency = 1 - alpha
	end
	local gb = 0.9 - 0.18 * d - 0.07 * pulse
	chaseCC.TintColor = Color3.new(1, gb, gb)
	runBadge.Rotation = math.sin(chaseFx.phase * 1.2) * 3
	carryPill.Rotation = math.sin(chaseFx.phase * 0.6) * 1.5
	-- las rarezas arcoíris o con destellos cambian de color sin parar (el resto lo pinta el bucle de 10 Hz)
	local rarity = Config.RARITIES[carried]
	if rarity and (rarity.rainbow or rarity.sparkle) then
		local hue = Color3.fromHSV((os.clock() * 0.5) % 1, 0.7, 1)
		carryLabel.TextColor3 = hue
		if chaseFx.carryStroke then
			chaseFx.carryStroke.Color = hue
		end
	end
end)

local function updateChase()
	local carrying = state.carrying ~= nil
	if carrying and not runBadge.Visible then
		chaseFx.phase, chaseFx.danger = 0, 0
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
	chaseFx.gui.Enabled = carrying
	distLabel.Visible = carrying and state.chase ~= nil
	if carrying then
		if state.chase then
			local near = state.chase < 40
			distLabel.Text = (near and "⚠️ " or "") .. t("guardianDist", state.chase)
			distLabel.TextColor3 = near and Color3.fromRGB(255, 90, 90) or WHITE
		end
	else
		chaseCC.TintColor = WHITE
	end
end

-- Título grande al entrar en una zona: degradado (color de la zona → blanco) y entrada con rebote
local zoneTitle = heavy({ Parent = gui, Size = UDim2.fromOffset(800, 80), Position = UDim2.fromScale(0.5, 0.3), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 14, StrokeThickness = 5 })
local zoneSub = heavy({ Parent = zoneTitle, Size = UDim2.new(1, 0, 0, 30), Position = UDim2.new(0, 0, 1, 0), TextColor3 = CYAN, ZIndex = 14 })
local zoneFx = {
	token = 0,
	scale = new("UIScale", { Parent = zoneTitle }),
	grad = new("UIGradient", { Rotation = 90, Parent = zoneTitle }),
	-- "⚔️ ZONA 2" encima del nombre
	tag = heavy({ Parent = zoneTitle, Size = UDim2.new(1, 0, 0, 26), Position = UDim2.new(0, 0, 0, -22), ZIndex = 14, StrokeThickness = 2.5 }),
	-- raya de luz que se abre bajo el subtítulo
	rule = new("Frame", { BackgroundColor3 = WHITE, BorderSizePixel = 0, Size = UDim2.new(0, 0, 0, 4), Position = UDim2.new(0.5, 0, 1, 36), AnchorPoint = Vector2.new(0.5, 0), ZIndex = 14, Parent = zoneTitle }, {
		new("UIGradient", { Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.5, 0), NumberSequenceKeypoint.new(1, 1) }) }),
	}),
}
local zoneGrade = new("ColorCorrectionEffect", { Name = "ZoneGrade", Parent = game:GetService("Lighting") })
-- Ambiente de cada zona. Los números de la luz salen de Config.LIGHT (los mismos que usa el servidor).
local function zoneMood(zi)
	local zone = Config.ZONES[zi]
	local light = Config.LIGHT
	local atm = game:GetService("Lighting"):FindFirstChildOfClass("Atmosphere")
	local info = TweenInfo.new(1.5, Enum.EasingStyle.Sine)
	TweenService:Create(zoneGrade, info, { TintColor = zone and zone.tint or WHITE, Saturation = zone and 0.1 or 0 }):Play()
	if atm then
		TweenService:Create(atm, info, {
			Color = zone and zone.atmo or light.atmo.color,
			Density = zone and (zone.cosmic and light.cosmicDensity or light.zoneDensity) or light.atmo.density,
		}):Play()
	end
end
local function showZone(zi)
	local zone = Config.ZONES[zi]
	zoneMood(zi)
	zoneFx.token += 1
	local my = zoneFx.token
	-- color de la zona, aclarado si es oscuro para que se lea sobre el juego
	local h, s, v = zone.accent:ToHSV()
	local accent = Color3.fromHSV(h, s, math.max(v, 0.9))
	zoneTitle.Text = string.upper(Locale.name(zone))
	zoneTitle.TextColor3 = WHITE
	zoneFx.grad.Color = ColorSequence.new(accent, WHITE)
	zoneFx.tag.Text = string.format("⚔️ %s %d", string.upper(t("zone")), zi)
	zoneFx.tag.TextColor3 = accent
	zoneFx.rule.BackgroundColor3 = accent
	zoneFx.rule.Size = UDim2.new(0, 0, 0, 4)
	zoneSub.Text = t("recommended", Format.num(zone.guardian.speed))
	zoneTitle.Visible = true
	-- entrada: crece con rebote mientras se endereza y la raya se abre
	zoneTitle.Rotation = -5
	zoneFx.scale.Scale = 0.3
	local pop = TweenInfo.new(0.55, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	TweenService:Create(zoneFx.scale, pop, { Scale = 1 }):Play()
	TweenService:Create(zoneTitle, pop, { Rotation = 0 }):Play()
	TweenService:Create(zoneFx.rule, TweenInfo.new(0.8, Enum.EasingStyle.Quart, Enum.EasingDirection.Out), { Size = UDim2.new(0.5, 0, 0, 4) }):Play()
	play("whoosh", 0.9)
	task.delay(2.5, function()
		if my ~= zoneFx.token then
			return
		end
		-- salida: se encoge (si entras en otra zona mientras tanto, el nuevo tween de escala manda)
		TweenService:Create(zoneFx.scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
		task.wait(0.24)
		if my == zoneFx.token then
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
local ANIM = { idle = "rbxassetid://507766666", walk = "rbxassetid://507777826" }
local animSets = setmetatable({}, { __mode = "k" })
local function playAnim(model, name, speed)
	local hum = model:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	local set = animSets[model]
	if not set then
		set = {}
		animSets[model] = set
	end
	if set.current == name then
		return
	end
	if set.current and set[set.current] then
		set[set.current]:Stop(0.25)
	end
	if not set[name] then
		local a = Instance.new("Animation")
		a.AnimationId = ANIM[name]
		local ok, track = pcall(function()
			return animator:LoadAnimation(a)
		end)
		if not ok then
			return
		end
		track.Looped = true
		set[name] = track
	end
	set[name]:Play(0.25)
	if speed then
		set[name]:AdjustSpeed(speed)
	end
	set.current = name
end
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
		local camDist = cam and (cam.CFrame.Position - cf.Position).Magnitude or math.huge
		folder:SetAttribute("_skip", ((folder:GetAttribute("_skip") or 0) + 1) % 3)
		if camDist < 90 or (camDist < 180 and folder:GetAttribute("_skip") == 0) then
			local dt = camDist < 90 and dt or dt * 3 -- los lejanos se actualizan 1 de cada 3 veces
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
					if m:GetAttribute("Avatar") then
						bob, tilt = 0, 0
						playAnim(m, moving and "walk" or "idle", moving and st.speed / 5 or 1)
					end
					if animated then
						bob, tilt = moving and math.abs(math.sin(now * 9 + st.phase)) * 0.12 or 0, 0
					end
					m:PivotTo(cf * CFrame.new(st.pos.X, st.y + bob, st.pos.Z) * CFrame.Angles(0, st.yaw, tilt))
					if animated then
						GodModel.animate(m, now * 9 + st.phase, moving and 0.55 or 0)
					end
					local runes = m:FindFirstChild("Runes")
					if runes then
						st.runeY = st.runeY or (m:GetPivot():ToObjectSpace(runes.CFrame).Y - bob)
						runes.CFrame = m:GetPivot() * CFrame.new(0, st.runeY - bob, 0) * CFrame.Angles(0, now * 0.8, 0)
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
-- Ajuste de partículas (gráficos bajos) y auras de otros jugadores
---------------------------------------------------------------------
local hidden = setmetatable({}, { __mode = "k" })
local emitters = setmetatable({}, { __mode = "k" })
local function track(e)
	if e:IsA("ParticleEmitter") or e:IsA("Fire") then
		emitters[e] = true
	end
end
for _, e in ipairs(workspace:GetDescendants()) do
	track(e)
end
workspace.DescendantAdded:Connect(track)
workspace.DescendantRemoving:Connect(function(e)
	emitters[e] = nil
	hidden[e] = nil
end)
task.spawn(function()
	while true do
		task.wait(2)
		local partsOn = opt("particles")
		local aurasOn = opt("othersAuras")
		for e in pairs(emitters) do
			if e.Parent then
				local isOtherAura = false
				local att = e.Parent
				if att and att.Name == "AuraFX" then
					local char = att:FindFirstAncestorOfClass("Model")
					isOtherAura = char ~= nil and char ~= player.Character and Players:GetPlayerFromCharacter(char) ~= nil
				end
				local want = partsOn and (aurasOn or not isOtherAura)
				if not want and e.Enabled then
					hidden[e] = true
					e.Enabled = false
				elseif want and hidden[e] then
					hidden[e] = nil
					e.Enabled = true
				end
			end
		end
	end
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
		-- multiplicadores y, si hay boosts activos (premios de misiones o compras), su tiempo
		local boosts = ""
		if (state.luckLeft or 0) > 0 then
			boosts ..= string.format('   <font color="#7CFF8A">🍀 %s</font>', Format.time(state.luckLeft))
		end
		if (state.boostLeft or 0) > 0 then
			boosts ..= string.format('   <font color="#9BE7FF">⚡x3 %s</font>', Format.time(state.boostLeft))
		end
		multLabel.Text = string.format("💰 x%s   🍀 x%s%s", Format.mult(state.moneyMult or 1), Format.mult(state.luck or 1), boosts)
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
			else
				zoneMood(0)
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
			-- las rarezas arcoíris o con destellos las colorea el latido de la persecución
			if not (r and (r.rainbow or r.sparkle)) then
				local rc = rcolor(state.carrying)
				carryLabel.TextColor3 = rc
				carryPill:FindFirstChildOfClass("UIStroke").Color = rc
			end
			carryPill.Visible = true
		else
			carryPill.Visible = false
		end
		-- paneles de los vendedores: tu dinero al momento y cierre automático al alejarte
		if panel.Visible and hint.bar.Visible then
			hint.money.Text = string.format("%s 💰 %s", t("youHave"), Format.num(state.money or 0))
		end
		local vendorKey = panel.Visible and VENDOR_PANELS[currentPanel]
		if vendorKey and not panelState.closing then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local off = hrp and (hrp.Position - Config.VENDORS[vendorKey].pos)
			if not off or Vector3.new(off.X, 0, off.Z).Magnitude > 28 then
				closePanel()
			end
		end
		local showTread = state.onTreadmill == true and not state.afk
		if showTread and not tread.Visible then
			bump(tread, 0.7)
		end
		tread.Visible = showTread
		local hits = tonumber(state.tapHits) or 0
		local mult = state.combo or 1
		comboLabel.Text = string.format('🔥 %s x%d  <font size="20" color="#C8E6FF">· %d %s · ⚡ +%s/s</font>', t("combo"), mult, hits, t("taps"), Format.num((state.treadmillGain or 0) * mult * (state.night and Config.NIGHT_TREADMILL_MULT or 1)))
		comboLabel.TextColor3 = mult >= Config.COMBO_MAX and GOLD or CYAN
		-- barra hasta el siguiente nivel de combo
		local prevHits, nextHits = 0, nil
		for _, tier in ipairs(Config.TAP_TIERS) do
			if hits >= tier.hits then
				prevHits = tier.hits
			elseif not nextHits then
				nextHits = tier.hits
			end
		end
		tierFill.Size = UDim2.new(nextHits and math.clamp((hits - prevHits) / (nextHits - prevHits), 0, 1) or 1, 0, 1, 0)
		leaveLabel.Text = t("jumpToLeave", deviceKey("jump"))
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

---------------------------------------------------------------------
-- Módulos opcionales del cliente: Fx (animaciones del mundo, estelas…), Music (música) y
-- Missions (misiones diarias, racha diaria y tutorial).
-- Son hijos de este script; si alguno no existe o falla, el HUD sigue funcionando.
---------------------------------------------------------------------
task.spawn(function()
	-- `state` se sustituye con cada mensaje del servidor: por eso se entrega con getState()
	local ctx = {
		player = player,
		Config = Config,
		Locale = Locale,
		Format = Format,
		t = t,
		opt = opt,
		gui = gui,
		play = play,
		getState = function()
			return state
		end,
		send = function(name, a, b)
			Action:FireServer(name, a, b)
		end,
		myPlot = myPlot,
		-- piezas de estilo del HUD (Missions dibuja con ellas para que todo se vea igual)
		ui = {
			new = new,
			corner = corner,
			stroke = stroke,
			gradient = gradient,
			darker = darker,
			label = label,
			heavy = heavy,
			button = button,
			bump = bump,
			toast = toast,
			showBanner = showBanner,
			floatText = floatText,
			fonts = { TITLE = TITLE, BTN = BTN, HEAVY = HEAVY },
			colors = { GOLD = GOLD, GREEN = GREEN, CYAN = CYAN, PINK = PINK, PURPLE = PURPLE, WHITE = WHITE },
		},
		panel = {
			open = openPanel,
			render = render,
			renderers = renderers,
			signatures = signatures,
			content = content,
			-- nombre del panel abierto (nil si no hay ninguno)
			current = function()
				return (panel.Visible and not panelState.closing) and currentPanel or nil
			end,
		},
		sideButton = sideButton,
		badges = badges,
		refs = { shopButton = shopButton, tapButton = tapButton, toastHolder = toastHolder },
		-- hay otra ventana importante delante (dinero offline o apertura de un sobre)
		isBusy = function()
			return offlinePopup.Visible or reveal.Visible
		end,
		hooks = hooks,
	}
	for _, name in ipairs({ "Fx", "Music", "Missions" }) do
		local m = script:FindFirstChild(name)
		if m then
			local ok, err = pcall(function()
				local mod = require(m)
				mod.start(ctx)
				if name == "Missions" then
					missionsMod = mod
				end
			end)
			if not ok then
				warn("[SAG] " .. name .. ": " .. tostring(err))
			end
		end
	end
end)
