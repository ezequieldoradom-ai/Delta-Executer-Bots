-- Steal a God ⚡ Roba un Dios — cliente (interfaz y efectos)
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local TextChatService = game:GetService("TextChatService")
local LocalizationService = game:GetService("LocalizationService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Format = require(Shared:WaitForChild("Format"))
local Locale = require(Shared:WaitForChild("Locale"))
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

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
-- Utilidades de interfaz
---------------------------------------------------------------------
local FONT = Enum.Font.FredokaOne
local FONT2 = Enum.Font.GothamBold
local DARK = Color3.fromRGB(16, 12, 32)
local GOLD = Color3.fromRGB(255, 210, 63)
local CYAN = Color3.fromRGB(94, 231, 255)

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

local function stroke(color, th)
	return new("UIStroke", { Color = color or GOLD, Thickness = th or 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border })
end

local function label(props)
	local l = new("TextLabel", {
		BackgroundTransparency = 1,
		Font = props.Font or FONT,
		TextColor3 = props.TextColor3 or Color3.new(1, 1, 1),
		TextScaled = props.TextScaled ~= false,
		RichText = true,
		Text = props.Text or "",
		Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		TextStrokeTransparency = props.TextStrokeTransparency or 0.4,
		ZIndex = props.ZIndex or 1,
		LayoutOrder = props.LayoutOrder or 0,
		Parent = props.Parent,
	})
	if props.TextSize then
		l.TextScaled = false
		l.TextSize = props.TextSize
	end
	return l
end

local function button(props)
	local b = new("TextButton", {
		AutoButtonColor = true,
		BackgroundColor3 = props.Color or GOLD,
		Font = FONT,
		TextScaled = true,
		Text = props.Text or "",
		TextColor3 = props.TextColor3 or Color3.fromRGB(20, 16, 30),
		Size = props.Size,
		Position = props.Position or UDim2.new(),
		AnchorPoint = props.AnchorPoint or Vector2.new(),
		LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1,
		Parent = props.Parent,
	}, { corner(12), new("UIPadding", { PaddingLeft = UDim.new(0, 6), PaddingRight = UDim.new(0, 6), PaddingTop = UDim.new(0, 4), PaddingBottom = UDim.new(0, 4) }) })
	if props.OnClick then
		b.Activated:Connect(props.OnClick)
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

---------------------------------------------------------------------
-- Pantalla principal
---------------------------------------------------------------------
local gui = new("ScreenGui", { Name = "HUD", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = player:WaitForChild("PlayerGui") })

-- Barra superior: dinero, velocidad, día/noche
local top = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 560, 0, 54), Position = UDim2.new(0.5, 0, 0, 8), AnchorPoint = Vector2.new(0.5, 0), Parent = gui }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 8) }),
	new("UISizeConstraint", { MaxSize = Vector2.new(560, 54) }),
})
local function pill(order, width, color)
	local f = new("Frame", { BackgroundColor3 = DARK, BackgroundTransparency = 0.15, Size = UDim2.new(0, width, 1, 0), LayoutOrder = order, Parent = top }, { corner(27), stroke(color, 2) })
	return label({ Parent = f, Size = UDim2.new(1, -16, 1, -10), Position = UDim2.fromOffset(8, 5), TextColor3 = color })
end
local moneyLabel = pill(1, 220, GOLD)
local speedLabel = pill(2, 180, CYAN)
local cycleLabel = pill(3, 120, Color3.fromRGB(255, 180, 90))

local zoneLabel = label({ Parent = gui, Size = UDim2.new(0, 460, 0, 26), Position = UDim2.new(0.5, 0, 0, 66), AnchorPoint = Vector2.new(0.5, 0), Font = FONT2 })
local carryLabel = label({ Parent = gui, Size = UDim2.new(0, 560, 0, 34), Position = UDim2.new(0.5, 0, 0, 94), AnchorPoint = Vector2.new(0.5, 0) })

-- Mensajes cortos
local toastHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 520, 0, 200), Position = UDim2.new(0.5, 0, 0, 132), AnchorPoint = Vector2.new(0.5, 0), Parent = gui }, {
	new("UIListLayout", { HorizontalAlignment = Enum.HorizontalAlignment.Center, Padding = UDim.new(0, 6) }),
})
local function toast(text, color)
	local f = new("Frame", { BackgroundColor3 = DARK, BackgroundTransparency = 0.1, Size = UDim2.new(1, 0, 0, 40), Parent = toastHolder }, { corner(12), stroke(color or GOLD, 2) })
	label({ Parent = f, Text = text, Size = UDim2.new(1, -16, 1, -8), Position = UDim2.fromOffset(8, 4), Font = FONT2, TextColor3 = color or Color3.new(1, 1, 1) })
	task.delay(3.2, function()
		f:Destroy()
	end)
	if #toastHolder:GetChildren() > 5 then
		for _, c in ipairs(toastHolder:GetChildren()) do
			if c:IsA("Frame") then
				c:Destroy()
				break
			end
		end
	end
end

-- Cartel grande
local banner = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Size = UDim2.new(1, 0, 0, 90), Position = UDim2.new(0, 0, 0.28, 0), Visible = false, ZIndex = 20, Parent = gui }, { stroke(GOLD, 3) })
local bannerLabel = label({ Parent = banner, Size = UDim2.new(1, -40, 1, -16), Position = UDim2.fromOffset(20, 8), ZIndex = 21 })
local bannerToken = 0
local function showBanner(text, color)
	bannerToken += 1
	local my = bannerToken
	bannerLabel.Text = text
	bannerLabel.TextColor3 = color or GOLD
	banner.Visible = true
	banner.Size = UDim2.new(1, 0, 0, 0)
	TweenService:Create(banner, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Size = UDim2.new(1, 0, 0, 90) }):Play()
	task.delay(4, function()
		if my == bannerToken then
			banner.Visible = false
		end
	end)
end

---------------------------------------------------------------------
-- Botones de la izquierda y paneles
---------------------------------------------------------------------
local side = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 82, 0, 360), Position = UDim2.new(0, 10, 0.5, 0), AnchorPoint = Vector2.new(0, 0.5), Parent = gui }, {
	new("UIListLayout", { Padding = UDim.new(0, 8), VerticalAlignment = Enum.VerticalAlignment.Center }),
})

local panel = new("Frame", { BackgroundColor3 = DARK, BackgroundTransparency = 0.05, Size = UDim2.fromScale(0.62, 0.72), Position = UDim2.fromScale(0.5, 0.52), AnchorPoint = Vector2.new(0.5, 0.5), Visible = false, ZIndex = 10, Parent = gui }, {
	corner(20),
	stroke(GOLD, 3),
	new("UISizeConstraint", { MinSize = Vector2.new(340, 300), MaxSize = Vector2.new(860, 620) }),
})
local panelTitle = label({ Parent = panel, Size = UDim2.new(1, -120, 0, 44), Position = UDim2.fromOffset(16, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, ZIndex = 11 })
local tabs = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -32, 0, 38), Position = UDim2.fromOffset(16, 56), ZIndex = 11, Parent = panel }, {
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, Padding = UDim.new(0, 8) }),
})
local content = new("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, -32, 1, -112), Position = UDim2.fromOffset(16, 100), ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 11, Parent = panel })
button({ Parent = panel, Text = "✕", Size = UDim2.fromOffset(46, 46), Position = UDim2.new(1, -54, 0, 8), Color = Color3.fromRGB(255, 70, 90), TextColor3 = Color3.new(1, 1, 1), ZIndex = 12, OnClick = function()
	panel.Visible = false
end })

local currentPanel, currentTab = nil, nil
local renderers = {}

local function clearContent()
	for _, c in ipairs(content:GetChildren()) do
		if not c:IsA("UIListLayout") and not c:IsA("UIGridLayout") and not c:IsA("UIPadding") then
			c:Destroy()
		end
	end
	for _, c in ipairs(content:GetChildren()) do
		c:Destroy()
	end
end

local function render()
	if not panel.Visible or not currentPanel then
		return
	end
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
		button({ Parent = tabs, Text = tb.text, Size = UDim2.new(0, 170, 1, 0), LayoutOrder = i, ZIndex = 12, Color = (currentTab == tb.id) and GOLD or Color3.fromRGB(60, 50, 90), TextColor3 = (currentTab == tb.id) and DARK or Color3.new(1, 1, 1), OnClick = function()
			currentTab = tb.id
			setTabs(list)
			render()
		end })
	end
end

local function openPanel(name, title, tabList)
	if panel.Visible and currentPanel == name then
		panel.Visible = false
		return
	end
	currentPanel = name
	currentTab = tabList and tabList[1].id or nil
	panelTitle.Text = title
	setTabs(tabList or {})
	panel.Visible = true
	content.CanvasPosition = Vector2.zero
	render()
end

-- Fila genérica: título, subtítulo y botón
local function row(order, title, subtitle, btnText, btnColor, enabled, onClick, accent)
	local f = new("Frame", { BackgroundColor3 = Color3.fromRGB(32, 26, 58), Size = UDim2.new(1, -10, 0, 74), LayoutOrder = order, ZIndex = 11, Parent = content }, { corner(14), stroke(accent or Color3.fromRGB(80, 70, 130), 2) })
	label({ Parent = f, Text = title, Size = UDim2.new(0.62, -10, 0, 34), Position = UDim2.fromOffset(12, 6), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = accent or Color3.new(1, 1, 1), ZIndex = 12 })
	label({ Parent = f, Text = subtitle, Font = FONT2, Size = UDim2.new(0.62, -10, 0, 26), Position = UDim2.fromOffset(12, 42), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(200, 195, 230), ZIndex = 12 })
	if btnText then
		local b = button({ Parent = f, Text = btnText, Size = UDim2.new(0.36, -12, 1, -18), Position = UDim2.new(0.64, 0, 0, 9), Color = enabled and (btnColor or GOLD) or Color3.fromRGB(80, 80, 95), TextColor3 = enabled and DARK or Color3.fromRGB(170, 170, 180), ZIndex = 12 })
		if enabled and onClick then
			b.Activated:Connect(onClick)
		end
	end
	return f
end

local function listLayout()
	new("UIListLayout", { Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
end

local function sectionTitle(order, text)
	label({ Parent = content, Text = text, Size = UDim2.new(1, -10, 0, 34), LayoutOrder = order, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, ZIndex = 11 })
end

local Action = Remotes:WaitForChild("Action")

---------------------------------------------------------------------
-- Tienda: mejoras, entrenadores, auras
---------------------------------------------------------------------
renderers.shop = function(tab)
	listLayout()
	if tab == "up" then
		local tm = state.treadmill or 1
		local tmMax = tm >= Config.TREADMILL_MAX
		local tmCost = not tmMax and Config.treadmillCost(tm + 1) or 0
		row(1, string.format("🏃 %s · %s %d", t("treadmill"), t("level"), tm), string.format("⚡ +%s/s → +%s/s", Format.num(Config.treadmillGain(tm)), tmMax and "—" or Format.num(Config.treadmillGain(tm + 1))), tmMax and t("max") or ("💰 " .. Format.num(tmCost)), CYAN, not tmMax and state.money >= tmCost, function()
			Action:FireServer("buyTreadmill")
		end, CYAN)
		local pl = state.plot or 1
		local plMax = pl >= Config.PLOT_MAX
		local plCost = not plMax and Config.plotCost(pl + 1) or 0
		row(2, string.format("🏛️ %s · %s %d", t("plot"), t("level"), pl), string.format("%d %s → %d", Config.pedestalsFor(pl), t("pedestals"), plMax and Config.pedestalsFor(pl) or Config.pedestalsFor(pl + 1)), plMax and t("max") or ("💰 " .. Format.num(plCost)), GOLD, not plMax and state.money >= plCost, function()
			Action:FireServer("buyPlot")
		end, GOLD)
		local al = state.altarsBought or Config.ALTARS_BASE
		local alMax = al >= Config.ALTARS_MAX
		local alCost = not alMax and Config.altarCost(al + 1) or 0
		row(3, string.format("🔮 %s · %d / %d", t("altar"), al, Config.ALTARS_MAX), string.format("%s: %d", t("queue"), state.queue or 0), alMax and t("max") or ("💰 " .. Format.num(alCost)), Color3.fromRGB(190, 140, 255), not alMax and state.money >= alCost, function()
			Action:FireServer("buyAltar")
		end, Color3.fromRGB(190, 140, 255))
	elseif tab == "coach" then
		local order = 0
		for _, co in ipairs(Config.COACHES) do
			order += 1
			row(order, "🏋️ " .. Locale.name(co), string.format("+%d%% ⚡", co.bonus * 100), "💰 " .. Format.num(co.cost), CYAN, state.money >= co.cost, function()
				Action:FireServer("buyCoach", co.id)
			end)
			for tier, tierInfo in ipairs(Config.COACH_TIERS) do
				local count = state.coaches[co.id .. ":" .. tier] or 0
				if count > 0 then
					order += 1
					local canFuse = count >= 2 and tier < #Config.COACH_TIERS
					row(order, string.format("   %s %s ×%d", Locale.name(co), Locale.name(tierInfo), count), string.format("+%s%% ⚡", Format.num(co.bonus * tierInfo.mult * 100)), canFuse and t("fuse") or nil, Color3.fromRGB(255, 120, 200), canFuse, function()
						Action:FireServer("fuseCoach", co.id, tier)
					end, Color3.fromRGB(255, 160, 220))
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
			row(i, "✨ " .. Locale.name(a), table.concat(eff, "  "), txt, a.color, (owned and not eq) or (not owned and state.money >= a.cost), function()
				Action:FireServer(owned and "equipAura" or "buyAura", a.id)
			end, a.color)
		end
	end
end

---------------------------------------------------------------------
-- Robux
---------------------------------------------------------------------
renderers.robux = function(tab)
	listLayout()
	if tab == "passes" then
		local order = 0
		for key, p in pairs(Config.PASSES) do
			order += 1
			local owned = state.passes[key]
			local available = p.id ~= 0
			row(order, "💎 " .. Locale.name(p), string.format("R$ %d", p.price), owned and t("owned") or (available and ("R$ " .. p.price) or t("soon")), Color3.fromRGB(80, 220, 120), available and not owned, function()
				MarketplaceService:PromptGamePassPurchase(player, p.id)
			end, Color3.fromRGB(120, 255, 160))
		end
	else
		local order = 0
		for _, key in ipairs({ "speedBoost", "serverLuck", "serverNight", "openNowLow", "openNowMid", "openNowHigh", "instantUpgrade", "divineShield", "moneySmall", "moneyBig", "savePack" }) do
			local p = Config.PRODUCTS[key]
			order += 1
			local available = p.id ~= 0
			row(order, "🛒 " .. Locale.name(p), string.format("R$ %d", p.price), available and ("R$ " .. p.price) or t("soon"), Color3.fromRGB(80, 220, 120), available, function()
				MarketplaceService:PromptProductPurchase(player, p.id)
			end)
		end
	end
end

---------------------------------------------------------------------
-- Índice
---------------------------------------------------------------------
renderers.index = function(tab)
	if tab == "gods" then
		new("UIGridLayout", { CellSize = UDim2.fromOffset(118, 150), CellPadding = UDim2.fromOffset(8, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
		local n = 0
		for _, g in ipairs(Config.GODS) do
			if (state.gods[g.id] or 0) > 0 then
				n += 1
			end
		end
		-- cabecera
		local head = new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 32, 70), LayoutOrder = 0, ZIndex = 11, Parent = content }, { corner(12) })
		label({ Parent = head, Text = string.format("📖\n%d/%d", n, #Config.GODS), TextColor3 = GOLD, ZIndex = 12, Size = UDim2.new(1, -8, 1, -8), Position = UDim2.fromOffset(4, 4) })
		for i, g in ipairs(Config.GODS) do
			local count = state.gods[g.id] or 0
			local rarity = Config.RARITIES[g.r]
			local owned = count > 0
			local card = new("TextButton", { Text = "", AutoButtonColor = owned, BackgroundColor3 = owned and rarity.color or Color3.fromRGB(30, 28, 40), LayoutOrder = i, ZIndex = 11, Parent = content }, { corner(12), stroke(rarity.color, owned and 3 or 1) })
			label({ Parent = card, Text = owned and g.name or "?", Size = UDim2.new(1, -8, 0, 50), Position = UDim2.fromOffset(4, 30), TextColor3 = owned and (g.r == 10 and Color3.new(1, 1, 1) or DARK) or Color3.fromRGB(110, 110, 130), TextStrokeTransparency = owned and 0.8 or 1, ZIndex = 12 })
			label({ Parent = card, Text = Locale.name(rarity), Font = FONT2, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.fromOffset(4, 6), TextColor3 = owned and (g.r == 10 and GOLD or DARK) or rarity.color, TextStrokeTransparency = 1, ZIndex = 12 })
			label({ Parent = card, Text = owned and ("×" .. count) or "", Font = FONT2, Size = UDim2.new(1, -8, 0, 22), Position = UDim2.new(0, 4, 1, -30), TextColor3 = owned and (g.r == 10 and Color3.new(1, 1, 1) or DARK) or Color3.new(1, 1, 1), TextStrokeTransparency = 1, ZIndex = 12 })
			if owned then
				card.Activated:Connect(function()
					toast(g.name .. ": " .. (Locale.lang() == "es" and g.factEs or g.factEn), rarity.color)
				end)
			end
		end
	elseif tab == "rewards" then
		listLayout()
		local n = 0
		for _, g in ipairs(Config.GODS) do
			if (state.gods[g.id] or 0) > 0 then
				n += 1
			end
		end
		sectionTitle(0, string.format("📖 %s", t("indexProgress", n, #Config.GODS)))
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
			row(i, string.format("%s %d", done and "✅" or "🔒", rw.count), table.concat(parts, "  "), nil, nil, false, nil, done and Color3.fromRGB(80, 220, 120) or nil)
		end
		local order = 100
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
			row(order, string.format("%s %s · %d/%d", have >= total and "✅" or "🏛️", Locale.name(myth), have, total), string.format("%s · x%s · +%d%% ⚡💰", Locale.name(w), tostring(w.power), myth.bonus * 100), nil, nil, false, nil, have >= total and Color3.fromRGB(80, 220, 120) or nil)
		end
	elseif tab == "odds" then
		listLayout()
		for zi, zone in ipairs(Config.ZONES) do
			sectionTitle(zi * 100, string.format("%s %d · %s", t("zone"), zi, Locale.name(zone)))
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
					local rr = Config.RARITIES[r]
					local txt = chance >= 0.001 and string.format("%.2f%%", chance * 100) or Format.oneIn(chance)
					label({ Parent = content, LayoutOrder = order, Size = UDim2.new(1, -10, 0, 26), Font = FONT2, TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = rr.id == 10 and Color3.fromRGB(200, 120, 255) or rr.color, Text = string.format("   %s — %s", Locale.name(rr), txt), ZIndex = 11 })
				end
			end
		end
	end
end

local function sideButton(order, emoji, text, color, onClick)
	local b = button({ Parent = side, Text = "", Size = UDim2.fromOffset(78, 78), LayoutOrder = order, Color = DARK, OnClick = onClick })
	stroke(color, 3).Parent = b
	label({ Parent = b, Text = emoji, Size = UDim2.new(1, 0, 0.6, 0) })
	label({ Parent = b, Text = text, Font = FONT2, Size = UDim2.new(1, 0, 0.32, 0), Position = UDim2.fromScale(0, 0.64), TextColor3 = color })
	return b
end

sideButton(1, "📖", t("index"), GOLD, function()
	openPanel("index", "📖 " .. t("indexTitle"), { { id = "gods", text = t("index") }, { id = "rewards", text = "🎁" }, { id = "odds", text = "🎲 " .. t("odds") } })
end)
sideButton(2, "🛒", t("shop"), CYAN, function()
	openPanel("shop", "🛒 " .. t("shop"), { { id = "up", text = t("upgrades") }, { id = "coach", text = t("coaches") }, { id = "aura", text = t("auras") } })
end)
sideButton(3, "💎", t("robux"), Color3.fromRGB(120, 255, 160), function()
	openPanel("robux", "💎 Robux", { { id = "passes", text = t("passes") }, { id = "products", text = t("products") } })
end)
local afkButton = sideButton(4, "💤", t("afk"), Color3.fromRGB(190, 140, 255), function()
	Action:FireServer("afk", not state.afk)
end)

---------------------------------------------------------------------
-- Minijuego de la cinta (combo)
---------------------------------------------------------------------
local tread = new("Frame", { BackgroundColor3 = DARK, BackgroundTransparency = 0.1, Size = UDim2.new(0, 420, 0, 150), Position = UDim2.new(0.5, 0, 1, -16), AnchorPoint = Vector2.new(0.5, 1), Visible = false, Parent = gui }, { corner(18), stroke(CYAN, 3) })
local comboLabel = label({ Parent = tread, Size = UDim2.new(1, -20, 0, 30), Position = UDim2.fromOffset(10, 6), TextColor3 = CYAN })
local bar = new("Frame", { BackgroundColor3 = Color3.fromRGB(40, 36, 70), Size = UDim2.new(1, -40, 0, 26), Position = UDim2.fromOffset(20, 42), Parent = tread }, { corner(13) })
local target = new("Frame", { BackgroundColor3 = Color3.fromRGB(80, 220, 120), Size = UDim2.new(0.18, 0, 1, 0), Position = UDim2.fromScale(0.41, 0), Parent = bar }, { corner(13) })
local marker = new("Frame", { BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.new(0, 8, 1, 10), Position = UDim2.new(0, 0, 0, -5), Parent = bar }, { corner(4) })
local targetCenter, targetWidth = 0.5, 0.18
local tapButton = button({ Parent = tread, Text = t("tap"), Size = UDim2.new(1, -40, 0, 56), Position = UDim2.fromOffset(20, 80), Color = CYAN })
local Combo = Remotes:WaitForChild("Combo")
local function markerPos()
	return (math.sin(os.clock() * 2.6) + 1) / 2
end
tapButton.Activated:Connect(function()
	local m = markerPos()
	if math.abs(m - targetCenter) <= targetWidth / 2 + 0.02 then
		Combo:FireServer()
		target.BackgroundColor3 = Color3.new(1, 1, 1)
		targetCenter = 0.15 + math.random() * 0.7
		task.delay(0.12, function()
			target.BackgroundColor3 = Color3.fromRGB(80, 220, 120)
		end)
	else
		tapButton.BackgroundColor3 = Color3.fromRGB(255, 80, 90)
		task.delay(0.15, function()
			tapButton.BackgroundColor3 = CYAN
		end)
	end
end)

---------------------------------------------------------------------
-- Revelar dios
---------------------------------------------------------------------
local reveal = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.35, Size = UDim2.fromScale(1, 1), Visible = false, ZIndex = 30, Parent = gui })
local revealCard = new("Frame", { BackgroundColor3 = DARK, Size = UDim2.fromOffset(340, 440), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 31, Parent = reveal }, { corner(24) })
local revealStroke = stroke(GOLD, 6)
revealStroke.Parent = revealCard
local revealNew = label({ Parent = revealCard, Size = UDim2.new(1, -20, 0, 40), Position = UDim2.fromOffset(10, 12), TextColor3 = Color3.fromRGB(80, 255, 140), ZIndex = 32 })
local revealName = label({ Parent = revealCard, Size = UDim2.new(1, -20, 0, 90), Position = UDim2.fromOffset(10, 70), ZIndex = 32 })
local revealRarity = label({ Parent = revealCard, Size = UDim2.new(1, -20, 0, 44), Position = UDim2.fromOffset(10, 170), ZIndex = 32 })
local revealIncome = label({ Parent = revealCard, Font = FONT2, Size = UDim2.new(1, -20, 0, 34), Position = UDim2.fromOffset(10, 222), TextColor3 = GOLD, ZIndex = 32 })
local revealFact = label({ Parent = revealCard, Font = FONT2, Size = UDim2.new(1, -30, 0, 150), Position = UDim2.fromOffset(15, 270), TextColor3 = Color3.fromRGB(220, 215, 240), ZIndex = 32, TextScaled = false, TextSize = 22 })
revealFact.TextWrapped = true
reveal.Activated:Connect(function()
	reveal.Visible = false
end)

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

Remotes:WaitForChild("Reveal").OnClientEvent:Connect(function(data)
	local g = Config.GOD_BY_ID[data.god]
	if not g then
		return
	end
	local rarity = Config.RARITIES[g.r]
	revealStroke.Color = rarity.id == 10 and Color3.fromRGB(200, 120, 255) or rarity.color
	revealNew.Text = data.isNew and t("gotNew") or ""
	revealName.Text = g.name
	revealName.TextColor3 = rarity.id == 10 and Color3.fromRGB(220, 160, 255) or rarity.color
	revealRarity.Text = string.upper(Locale.name(rarity))
	revealRarity.TextColor3 = revealName.TextColor3
	revealIncome.Text = string.format("💰 +%s/s", Format.num(rarity.income * (state.moneyMult or 1)))
	revealFact.Text = Locale.lang() == "es" and g.factEs or g.factEn
	reveal.Visible = true
	revealCard.Size = UDim2.fromOffset(40, 50)
	TweenService:Create(revealCard, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Size = UDim2.fromOffset(340, 440) }):Play()
	if g.r >= Config.ANNOUNCE_BIG_FROM then
		shake(1.2, 1.2)
	elseif g.r >= 6 then
		shake(0.4, 0.5)
	end
	task.delay(5, function()
		reveal.Visible = false
	end)
end)

---------------------------------------------------------------------
-- Mensajes del servidor
---------------------------------------------------------------------
local function chat(text, color)
	local channels = TextChatService:FindFirstChild("TextChannels")
	local general = channels and channels:FindFirstChild("RBXGeneral")
	if general then
		pcall(function()
			general:DisplaySystemMessage(string.format('<font color="%s">%s</font>', color or "#FFD23F", text))
		end)
	end
end

Remotes:WaitForChild("Announce").OnClientEvent:Connect(function(payload)
	local text = fmtKey(payload.key, payload.args)
	local opts = payload.opts or {}
	chat(text, opts.color)
	if opts.big then
		local c = opts.color and Color3.fromHex(opts.color) or GOLD
		if opts.color == "#19191F" then
			c = Color3.fromRGB(200, 120, 255)
		end
		showBanner(text, c)
	end
end)

Remotes:WaitForChild("Toast").OnClientEvent:Connect(function(key, args)
	toast(fmtKey(key, args))
end)

Remotes:WaitForChild("Knock").OnClientEvent:Connect(function(vel)
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local hum = char and char:FindFirstChildOfClass("Humanoid")
	if hrp and hum then
		hum.PlatformStand = true
		hrp.AssemblyLinearVelocity = vel
		shake(0.8, 0.4)
		task.delay(0.8, function()
			hum.PlatformStand = false
		end)
	end
end)

Remotes:WaitForChild("Offer").OnClientEvent:Connect(function(key)
	local p = Config.PRODUCTS[key]
	if p and p.id ~= 0 then
		showBanner(t("savePackAsk"), Color3.fromRGB(255, 120, 120))
		MarketplaceService:PromptProductPurchase(player, p.id)
	end
end)

Remotes:WaitForChild("State").OnClientEvent:Connect(function(s)
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
	if bb:GetAttribute("Altar") then
		local r = bb:GetAttribute("Rarity") or 0
		if r > 0 then
			local rem = bb:GetAttribute("Rem") or 0
			l.Text = string.format("<b>%s</b>\n%s", Locale.name(Config.RARITIES[r]), rem <= 0 and t("ready") or ("⏳ " .. Format.time(rem)))
		else
			l.Text = ""
		end
	elseif bb:GetAttribute("Guardian") then
		local gi = bb:GetAttribute("Guardian")
		local zone = Config.ZONES[gi]
		local chasing = bb:GetAttribute("Chasing")
		l.Text = string.format("<b>%s</b>%s", Locale.name(zone.guardian), chasing and ("\n" .. t("chasing")) or "")
	elseif bb:GetAttribute("Zone") then
		local zi = bb:GetAttribute("Zone")
		local zone = Config.ZONES[zi]
		local ok = (state.speed or 0) >= zone.req
		l.Text = string.format("<b>%s %d · %s</b>%s", t("zone"), zi, Locale.name(zone), zi > 1 and string.format('\n<font color="%s">%s ⚡ %s</font>', ok and "#5CFF8A" or "#FF5A5A", t("requires"), Format.num(zone.req)) or "")
	elseif bb:GetAttribute("EndSign") then
		l.Text = string.format("<b>%s</b>\n%s", t("endSign"), t("moreZones"))
	elseif bb:GetAttribute("Rarity") then
		local r = bb:GetAttribute("Rarity")
		l.Text = string.format("<b>%s</b>%s", string.upper(Locale.name(Config.RARITIES[r])), bb:GetAttribute("Dawn") and " 🌅" or "")
		if r == 10 then
			l.TextColor3 = Color3.fromRGB(210, 140, 255)
		end
	end
end

local function locPrompt(p)
	local kind = p:GetAttribute("Kind")
	p.ActionText = kind == "steal" and t("steal") or t("open")
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
	local a0 = new("Attachment", { Position = Vector3.new(0, 1, 0), Parent = hrp })
	local a1 = new("Attachment", { Position = Vector3.new(0, -1, 0), Parent = hrp })
	trail = new("Trail", { Attachment0 = a0, Attachment1 = a1, Lifetime = 0.25, LightEmission = 1, Color = ColorSequence.new(CYAN, Color3.new(1, 1, 1)), Transparency = NumberSequence.new(0.3, 1), Enabled = false, Parent = hrp })
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
		marker.Position = UDim2.new(markerPos(), -4, 0, -5)
		target.Position = UDim2.fromScale(targetCenter - targetWidth / 2, 0)
	end
end)

---------------------------------------------------------------------
-- Actualización de la interfaz (10 veces por segundo)
---------------------------------------------------------------------
task.spawn(function()
	local renderAcc = 0
	while true do
		task.wait(0.1)
		local left = math.max(0, (state.cycleLeft or 0) - (os.clock() - stateAt))
		moneyLabel.Text = string.format("💰 %s <font size=\"16\" color=\"#FFF2B0\">+%s/s</font>", Format.num(state.money or 0), Format.num(state.income or 0))
		speedLabel.Text = "⚡ " .. Format.num(state.speed or 0)
		cycleLabel.Text = (state.night and "🌙 " or "☀️ ") .. Format.time(left)
		local z = state.zone or 0
		if z > 0 then
			zoneLabel.Text = string.format("%s · %s %d: %s", t("combatZone"), t("zone"), z, Locale.name(Config.ZONES[z]))
			zoneLabel.TextColor3 = Color3.fromRGB(255, 120, 110)
		else
			zoneLabel.Text = t("safeZone")
			zoneLabel.TextColor3 = Color3.fromRGB(150, 255, 170)
		end
		if state.carrying then
			local r = Config.RARITIES[state.carrying]
			carryLabel.Text = t("carrying", string.upper(Locale.name(r)))
			carryLabel.TextColor3 = r.id == 10 and Color3.fromRGB(210, 140, 255) or r.color
		else
			carryLabel.Text = ""
		end
		tread.Visible = state.onTreadmill == true and not state.afk
		comboLabel.Text = string.format("%s x%.1f  ·  ⚡ +%s/s", t("combo"), state.combo or 1, Format.num((state.treadmillGain or 0) * (state.combo or 1) * (state.night and Config.NIGHT_TREADMILL_MULT or 1)))
		afkButton.BackgroundColor3 = state.afk and Color3.fromRGB(110, 70, 190) or DARK
		for _, bb in ipairs(CollectionService:GetTagged("Loc")) do
			locLabel(bb)
		end
		renderAcc += 0.1
		if renderAcc >= 1 then
			renderAcc = 0
			render()
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
