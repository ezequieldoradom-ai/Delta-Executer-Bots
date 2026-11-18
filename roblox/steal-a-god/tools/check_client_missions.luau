-- Ejecuta el módulo del cliente Missions (misiones, racha diaria y tutorial) en un servidor de verdad,
-- con el mundo real, un jugador simulado y las MISMAS piezas de estilo que init.client.luau
-- (copiadas abajo, más un registro de los botones para poder "pulsarlos"). Comprueba lo que se ve en
-- cada paso y que no salte ningún error ni aviso.
local out = {}
local fails = 0
-- Recorta un texto sin partir ningún carácter UTF-8 (emojis, tildes). OJO: si lo que devuelve el script
-- lleva UTF-8 roto (p. ej. de un :sub() en mitad de un emoji), la ejecución en Open Cloud se queda colgada
-- y acaba con "Task timed out due to an internal error".
local function cut(s, n)
	s = tostring(s)
	if utf8.len(s) == nil then
		s = s:gsub("[\128-\255]", "?") -- ya venía roto: se cambian los bytes no ASCII
	end
	if #s <= n then
		return s
	end
	local last = 0
	for p in utf8.codes(s) do
		if p > n then
			break
		end
		last = p - 1
	end
	return s:sub(1, last) .. "…"
end
local function add(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring((select(i, ...)))
	end
	table.insert(out, table.concat(t, " "))
end
-- Las pruebas se apuntan y se ejecutan al final en otro hilo, con un vigilante: si alguna se queda
-- colgada, el script devuelve igualmente lo que lleva y dice cuál fue.
local queue = {}
local function step(name, fn)
	table.insert(queue, { name = name, fn = fn })
end
local T0 = os.clock()

local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared = RS:WaitForChild("Shared")
local G = {
	Config = require(Shared.Config), Format = require(Shared.Format), GodModel = require(Shared.GodModel),
	Net = require(Server.Net), Data = require(Server.Data), World = require(Server.World), Core = require(Server.Core),
	Packs = require(Server.Packs), Combat = require(Server.Combat), DayNight = require(Server.DayNight),
	Boards = require(Server.Boards), Shop = require(Server.Shop), Quests = require(Server.Quests), serverLuckUntil = 0,
}
local function optional(name)
	local m = Server:FindFirstChild(name)
	return m and require(m) or nil
end
G.AuraFx = optional("AuraFx"); G.PackStyle = optional("PackStyle"); G.Vendors = optional("Vendors")
G.Net.init()
require(Server.Models).load(G.Config)
G.Avatars = require(Server.Avatars); G.Avatars.init(G)
if G.AuraFx then G.AuraFx.init(G) end
if G.PackStyle then G.PackStyle.init(G) end
G.World.init(G)
if G.Vendors then G.Vendors.init(G) end
G.DayNight.init(G); G.Combat.init(G); G.Packs.init(G); G.Shop.init(G); G.Boards.init(G); G.Core.init(G); G.Quests.init(G)
G.Packs.refreshAll()

local warns = {}
game:GetService("LogService").MessageOut:Connect(function(msg, kind)
	if kind == Enum.MessageType.MessageWarning or kind == Enum.MessageType.MessageError then
		table.insert(warns, msg)
	end
end)

local Config = G.Config
local Format = G.Format
local Locale = require(Shared.Locale)
Locale.setSpanish(true)
local t = Locale.t

---------------------------------------------------------------------
-- Piezas de estilo: copia de init.client.luau (mismas firmas y mismo código)
---------------------------------------------------------------------
local TITLE = Enum.Font.LuckiestGuy
local BTN = Enum.Font.FredokaOne
local GOLD = Color3.fromRGB(255, 210, 63)
local CYAN = Color3.fromRGB(94, 231, 255)
local PINK = Color3.fromRGB(255, 90, 180)
local GREEN = Color3.fromRGB(80, 230, 130)
local PURPLE = Color3.fromRGB(170, 110, 255)
local WHITE = Color3.new(1, 1, 1)
local played, banners, toasts, sent = {}, {}, {}, {}
local clicks = {} -- { text, fn, gui }

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
		BackgroundTransparency = 1, Font = props.Font or BTN, TextColor3 = props.TextColor3 or WHITE, TextScaled = props.TextSize == nil,
		TextSize = props.TextSize or 14, RichText = true, TextWrapped = true, Text = props.Text or "", Size = props.Size or UDim2.fromScale(1, 1),
		Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.new(), TextXAlignment = props.TextXAlignment or Enum.TextXAlignment.Center,
		ZIndex = props.ZIndex or 1, LayoutOrder = props.LayoutOrder or 0, Rotation = props.Rotation or 0, Parent = props.Parent,
	})
	if props.Stroke ~= false then
		textStroke(props.StrokeColor, props.StrokeThickness).Parent = l
	end
	return l
end
local function play(name, pitch)
	table.insert(played, name)
end
local function pressable(gui)
	local scale = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = gui })
	local function to(v, style)
		TweenService:Create(scale, TweenInfo.new(0.12, style or Enum.EasingStyle.Quad), { Scale = v }):Play()
	end
	gui.MouseEnter:Connect(function() to(1.05) end)
	gui.MouseLeave:Connect(function() to(1) end)
end
local function bump(gui, amount)
	local scale = gui:FindFirstChildOfClass("UIScale") or new("UIScale", { Parent = gui })
	scale.Scale = amount or 1.12
	TweenService:Create(scale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = 1 }):Play()
end
local function button(props)
	local base = props.Color or GOLD
	local b = new("TextButton", {
		AutoButtonColor = false, BackgroundColor3 = WHITE, Font = BTN, TextScaled = true, Text = props.Text or "", TextColor3 = props.TextColor3 or WHITE,
		Size = props.Size, Position = props.Position or UDim2.new(), AnchorPoint = props.AnchorPoint or Vector2.new(), LayoutOrder = props.LayoutOrder or 0,
		ZIndex = props.ZIndex or 1, Parent = props.Parent,
	}, {
		corner(props.Radius or 14), gradient(base, darker(base, 0.65), 90), stroke(darker(base, 0.4), 3),
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 5), PaddingBottom = UDim.new(0, 5) }),
	})
	textStroke(darker(base, 0.3), 2).Parent = b
	pressable(b)
	if props.OnClick then
		local fn = props.OnClick
		b.Activated:Connect(function()
			play("click")
			fn()
		end)
		table.insert(clicks, { text = props.Text or "", fn = function()
			play("click")
			fn()
		end, gui = b })
	end
	return b
end
local HEAVY = Font.new("rbxasset://fonts/families/GothamSSm.json", Enum.FontWeight.Heavy, Enum.FontStyle.Italic)
local function heavy(props)
	props.StrokeThickness = props.StrokeThickness or 3
	local l = label(props)
	l.FontFace = HEAVY
	return l
end

local gui = new("ScreenGui", { Name = "HUDTest", ResetOnSpawn = false, ZIndexBehavior = Enum.ZIndexBehavior.Sibling, Parent = game:GetService("StarterGui") })
local toastHolder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 540, 0, 240), Position = UDim2.new(0.5, 0, 0, 92), AnchorPoint = Vector2.new(0.5, 0), Parent = gui })
local function toast(text, color)
	table.insert(toasts, text)
end
local function showBanner(text, color)
	table.insert(banners, text)
end
local function floatText(text, color, parent, pos)
	local l = label({ Parent = parent or gui, Font = TITLE, Text = text, TextColor3 = color, Size = UDim2.fromOffset(200, 44), Position = pos or UDim2.new(0.5, -100, 1, -200), ZIndex = 25 })
	TweenService:Create(l, TweenInfo.new(0.8, Enum.EasingStyle.Quad), { Position = l.Position - UDim2.fromOffset(0, 70), TextTransparency = 1 }):Play()
	task.delay(0.85, function()
		l:Destroy()
	end)
end
-- panel común (versión reducida de la del HUD: misma lógica de firmas y repintado)
local panel = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromScale(0.64, 0.74), Visible = false, ZIndex = 10, Parent = gui })
local content = new("ScrollingFrame", { BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, -122), ScrollBarThickness = 8, AutomaticCanvasSize = Enum.AutomaticSize.Y, CanvasSize = UDim2.new(), ZIndex = 11, Parent = panel })
local renderers, signatures = {}, {}
local currentPanel = nil
local renders = 0
local function render(force)
	if not panel.Visible or not currentPanel then
		return
	end
	local sigFn = signatures[currentPanel]
	local sig = sigFn and sigFn() or tostring(os.clock())
	if not force and content:GetAttribute("Sig") == sig then
		return
	end
	content:SetAttribute("Sig", sig)
	for _, c in ipairs(content:GetChildren()) do
		c:Destroy()
	end
	renders += 1
	renderers[currentPanel]()
end
local function openPanel(name, title)
	if panel.Visible and currentPanel == name then
		panel.Visible = false
		return
	end
	currentPanel = name
	panel.Visible = true
	render(true)
end
local badges = {}
local side = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0, 210, 0, 420), Parent = gui }, { new("UIListLayout", { Padding = UDim.new(0, 10) }) })
local function sideButton(order, emoji, text, color, onClick)
	local b = new("TextButton", { Text = "", AutoButtonColor = false, BackgroundColor3 = WHITE, Size = UDim2.fromOffset(200, 60), LayoutOrder = order * 10, Parent = side }, {
		corner(16), gradient(color, darker(color, 0.45), 100), stroke(darker(color, 0.25), 3.5),
	})
	pressable(b)
	heavy({ Parent = b, Text = string.upper(text), Size = UDim2.new(1, -70, 1, -14), Position = UDim2.fromOffset(64, 7), TextXAlignment = Enum.TextXAlignment.Left })
	local badge = new("Frame", { BackgroundColor3 = Color3.fromRGB(255, 50, 70), Size = UDim2.fromOffset(58, 22), Position = UDim2.new(1, -40, 0, -10), Visible = false, ZIndex = 3, Parent = b }, { corner(11), stroke(WHITE, 2) })
	heavy({ Parent = badge, Text = t("new"), Size = UDim2.new(1, -6, 1, -4), Position = UDim2.fromOffset(3, 2), ZIndex = 4, StrokeThickness = 1.5 })
	badges[order] = badge
	b.Activated:Connect(function()
		onClick()
	end)
	table.insert(clicks, { text = "side:" .. text, fn = onClick, gui = b })
	return b
end
local shopButton = sideButton(1, "🛒", t("shop"), Color3.fromRGB(255, 80, 60), function()
	openPanel("shop")
end)
-- la tienda de verdad pinta la fila de la cinta con LayoutOrder 1: aquí una igual
renderers.shop = function()
	new("UIListLayout", { Parent = content })
	new("Frame", { Name = "TreadmillRow", Size = UDim2.new(1, -14, 0, 82), LayoutOrder = 1, Parent = content }, { stroke(CYAN, 2.5) })
end
local tread = new("Frame", { Size = UDim2.new(0, 440, 0, 160), Parent = gui })
local tapButton = button({ Parent = tread, Text = t("tap"), Size = UDim2.new(1, -40, 0, 60), Position = UDim2.fromOffset(20, 84), Color = CYAN })
tapButton.Name = "TapButton"

---------------------------------------------------------------------
-- Jugador simulado con su parcela y su estado
---------------------------------------------------------------------
local player = { UserId = 424242, Name = "Tester", DisplayName = "Tester" }
local char = Instance.new("Model")
char.Name = "Tester"
local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Anchored = true
hrp.Size = Vector3.new(2, 2, 1)
hrp.Parent = char
char.Parent = workspace
player.Character = char
local plot = G.World.plots[1]
plot.folder:SetAttribute("Owner", player.UserId)
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
local function standAt(pos)
	hrp.CFrame = CFrame.new(pos + Vector3.new(0, 3, 0))
end
standAt(plot.spawn)

local state = { money = 0, speed = 0, income = 4, combo = 1, altarPacks = {}, treadmill = 1 }
local hooks = {}
local function quests(tutorial, extra)
	local q = {
		day = G.Quests.today(), dailyCan = true, streak = 3, rr = 1, tutorial = tutorial,
		missions = {
			{ id = "steal", goal = 5, progress = 2, claimed = false },
			{ id = "train", goal = 180, progress = 180, claimed = false },
			{ id = "newgod", goal = 1, progress = 1, claimed = true },
		},
	}
	for k, v in pairs(extra or {}) do
		q[k] = v
	end
	return q
end
local function setState(changes)
	for k, v in pairs(changes) do
		state[k] = v
	end
	-- igual que el manejador de "State" del HUD: repinta el panel abierto y avisa al módulo
	render(false)
	if hooks.state then
		hooks.state(state)
	end
end
local busy = false
local ctx = {
	player = player, Config = Config, Locale = Locale, Format = Format, t = t,
	opt = function() return true end, gui = gui, play = play,
	getState = function() return state end,
	send = function(name, a, b) table.insert(sent, { name, a, b }) end,
	myPlot = myPlot,
	ui = { new = new, corner = corner, stroke = stroke, gradient = gradient, darker = darker, label = label, heavy = heavy, button = button, bump = bump, toast = toast, showBanner = showBanner, floatText = floatText,
		fonts = { TITLE = TITLE, BTN = BTN, HEAVY = HEAVY }, colors = { GOLD = GOLD, GREEN = GREEN, CYAN = CYAN, PINK = PINK, PURPLE = PURPLE, WHITE = WHITE } },
	panel = { open = openPanel, render = render, renderers = renderers, signatures = signatures, content = content,
		current = function() return panel.Visible and currentPanel or nil end },
	sideButton = sideButton, badges = badges,
	refs = { shopButton = shopButton, tapButton = tapButton, toastHolder = toastHolder },
	isBusy = function() return busy end,
	hooks = hooks,
}

local client = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Client")
local Missions = require(client.Missions)
local function find(text)
	for i = #clicks, 1, -1 do
		local c = clicks[i]
		if c.text == text and c.gui.Parent then
			return c
		end
	end
	return nil
end
local function lastSent()
	local s = sent[#sent]
	return s and s[1] or nil
end
local function texts(root)
	local list = {}
	for _, d in ipairs(root:GetDescendants()) do
		if (d:IsA("TextLabel") or d:IsA("TextButton")) and d.Text ~= "" then
			table.insert(list, d.Text)
		end
	end
	return table.concat(list, " ¦ ")
end

---------------------------------------------------------------------
-- Pruebas
---------------------------------------------------------------------
step("Arranque: botón lateral entre la tienda y el índice, con globo de premios", function()
	state.quests = quests(1, { dailyCan = true })
	Missions.start(ctx)
	task.wait(0.25)
	local d = Missions.debug()
	assert(d.running and not d.error, "error: " .. tostring(d.error))
	local btn = find("side:" .. t("missions"))
	assert(btn and btn.gui.LayoutOrder == 15, "botón de misiones")
	-- 1 premio diario + 1 misión terminada sin reclamar
	assert(d.badge == "🎁 2", "globo: " .. tostring(d.badge))
end)

step("Tutorial paso 1: tarjeta arriba, guía dorada hasta tu cinta y avisos más abajo", function()
	setState({ speed = 12, onTreadmill = false })
	task.wait(0.4)
	local d = Missions.debug()
	assert(d.card and d.step == 1, "sin tarjeta")
	assert(d.cardText:find("cinta") and d.cardText:find("12/30"), "texto: " .. tostring(d.cardText))
	assert(d.guide == "tm" and d.beam, "guía: " .. tostring(d.guide) .. " haz " .. tostring(d.beam))
	assert(d.guideLabel:find("m$"), "distancia: " .. tostring(d.guideLabel))
	assert(toastHolder.Position.Y.Offset == 124, "los avisos no bajan")
	local folder = workspace:FindFirstChild("TutorialGuide")
	assert(folder and folder:FindFirstChild("Target") and folder.Target:FindFirstChildOfClass("Beam"), "piezas de la guía")
	assert(hrp:FindFirstChild("TutorialGuideA0"), "punto de salida en el personaje")
	for _, p in ipairs(folder:GetDescendants()) do
		if p:IsA("BasePart") then
			assert(p.Anchored and not p.CanCollide and not p.CanQuery and not p.CanTouch, "la guía estorba: " .. p.Name)
		end
	end
	-- en la cinta: la guía desaparece
	setState({ onTreadmill = true })
	task.wait(0.4)
	assert(Missions.debug().guide == nil, "guía encima de la cinta")
	add("   paso 1:", d.cardText, "·", d.guideLabel)
end)

step("Paso 2 (combo): el botón TOCA brilla; al subir de paso se celebra", function()
	local before = #played
	setState({ quests = quests(2), onTreadmill = true })
	task.wait(0.3)
	local d = Missions.debug()
	assert(d.step == 2 and d.halo == "TapButton", "brillo: " .. tostring(d.halo))
	assert(#played > before, "sin sonido de celebración")
	add("   paso 2:", d.cardText)
end)

step("Paso 3 (robar): primero a la entrada del pasillo, luego al sobre más cercano de la zona 1", function()
	setState({ quests = quests(3), onTreadmill = false })
	standAt(plot.spawn)
	task.wait(0.4)
	local d = Missions.debug()
	assert(d.halo == nil and d.guide == "corridor", "guía: " .. tostring(d.guide))
	standAt(Vector3.new(0, 0.2, 160))
	task.wait(0.4)
	d = Missions.debug()
	assert(d.guide == "pack" and d.beam, "guía al sobre: " .. tostring(d.guide))
	add("   paso 3:", d.cardText, "·", d.guideLabel)
end)

step("Paso 4 (volver): la tarjeta se esconde mientras llevas el sobre y la guía va a casa", function()
	setState({ quests = quests(4), carrying = 3 })
	task.wait(0.4)
	local d = Missions.debug()
	assert(not d.card and d.guide == "home", "tarjeta " .. tostring(d.card) .. " guía " .. tostring(d.guide))
	assert(toastHolder.Position.Y.Offset == 92, "los avisos no vuelven a su sitio")
	add("   paso 4:", d.guideLabel)
end)

step("Paso 5 (abrir): cuenta atrás y luego guía al altar con el sobre listo", function()
	standAt(plot.spawn)
	state.carrying = nil -- (pairs no recorre los nil: se borra aquí)
	setState({ quests = quests(5), altarPacks = { { r = 1, rem = 7 } } })
	task.wait(0.4)
	local d = Missions.debug()
	assert(d.card and d.cardText:find("0:07"), "texto: " .. tostring(d.cardText))
	assert(d.guide == "altar1", "guía: " .. tostring(d.guide))
	setState({ altarPacks = { { r = 1, rem = 9 }, { r = 2, rem = 0 } } })
	task.wait(0.4)
	d = Missions.debug()
	assert(d.guide == "altar2" and d.cardText:find("listo"), "altar listo: " .. tostring(d.guide) .. " " .. tostring(d.cardText))
	add("   paso 5:", d.cardText)
end)

step("Paso 6 (mejorar): brilla la tienda con flecha; dentro, late la fila de la cinta", function()
	setState({ quests = quests(6), altarPacks = {} })
	task.wait(0.3)
	local d = Missions.debug()
	assert(d.guide == nil and d.halo == shopButton.Name and d.pointer, "brillo de la tienda: " .. tostring(d.halo))
	find("side:" .. t("shop")).fn()
	task.wait(0.3)
	d = Missions.debug()
	assert(d.rowGlow and not d.pointer, "fila de la cinta " .. tostring(d.rowGlow) .. " flecha " .. tostring(d.pointer))
	find("side:" .. t("shop")).fn() -- cerrar
	add("   paso 6:", d.cardText)
end)

step("Tutorial completado: celebración y todo desaparece", function()
	setState({ quests = quests(7) })
	task.wait(0.3)
	local d = Missions.debug()
	assert(not d.card and d.guide == nil and d.halo == nil, "quedan restos")
	assert(workspace:FindFirstChild("TutorialGuide") == nil, "la guía sigue en el mundo")
	assert(banners[#banners] == t("tutorialDoneBanner"), "sin cartel final: " .. tostring(banners[#banners]))
	assert(not hrp:FindFirstChild("TutorialGuideA0"), "punto de salida en el personaje")
end)

step("Panel de misiones: racha de 7 días, misiones con progreso y botones que funcionan", function()
	find("side:" .. t("missions")).fn()
	task.wait(0.2)
	assert(panel.Visible and currentPanel == "missions", "no se abrió")
	local all = texts(content)
	for _, must in ipairs({ t("dailyStreak"), t("dayN", 7), t("claimDay", 3), Locale.mission("steal", 5), Locale.mission("train", 180), "2 / 5", "3:00 / 3:00", t("claim"), "✅ " .. t("claimed"), t("todayMissions") }) do
		assert(all:find(must, 1, true), "falta «" .. must .. "»")
	end
	-- reclamar la misión terminada
	find(t("claim")).fn()
	assert(lastSent() == "claimMission" and sent[#sent][2] == 2, "reclamar misión")
	-- cambiar una misión: hace falta tocar dos veces
	local n = #sent
	find("🔄 " .. t("reroll")).fn()
	assert(#sent == n and find(t("sure")), "el primer toque ya cambió la misión")
	find(t("sure")).fn()
	assert(lastSent() == "rerollMission" and sent[#sent][2] == 1, "cambiar misión")
	-- reclamar el día desde el panel
	find(t("claimDay", 3)).fn()
	assert(lastSent() == "claimDaily", "reclamar día")
	-- el servidor responde: día reclamado, misión pagada → se repinta con la cuenta atrás
	local r0 = renders
	setState({ quests = quests(7, { dailyCan = false, rr = 0, missions = { { id = "steal", goal = 5, progress = 2, claimed = false }, { id = "train", goal = 180, progress = 180, claimed = true }, { id = "newgod", goal = 1, progress = 1, claimed = true } } }) })
	task.wait(0.3)
	assert(renders > r0, "no se repintó")
	all = texts(content)
	assert(all:find(t("comeBack", ""), 1, true) and all:find("⏳ 40%", 1, true), "sin cuenta atrás o progreso: " .. cut(all, 300))
	assert(Missions.debug().badge == nil, "globo sin nada que reclamar")
	add("   panel:", cut(all, 420))
	find("side:" .. t("missions")).fn() -- cerrar
end)

step("Aviso diario al entrar: espera a que no haya otra ventana, se reclama y se cierra", function()
	Missions.stop()
	clicks = {}
	sent = {}
	state.quests = quests(7, { dailyCan = true, streak = 7 })
	busy = true
	Missions.start(ctx)
	task.wait(4.6)
	assert(not Missions.debug().popup, "salió encima de otra ventana")
	busy = false
	task.wait(0.4)
	local d = Missions.debug()
	assert(d.popup and d.popupShown, "no salió el aviso")
	local pop = gui:FindFirstChild("DailyPopup")
	local all = texts(pop)
	assert(all:find(t("dailyTitle"), 1, true) and all:find(t("megaPack"), 1, true) and all:find(t("claimDay", 7), 1, true), "aviso: " .. cut(all, 300))
	find(t("claimDay", 7)).fn()
	assert(lastSent() == "claimDaily", "no reclamó")
	task.wait(1.9)
	assert(gui:FindFirstChild("DailyPopup") == nil and not Missions.debug().popup, "no se cerró")
	-- solo una vez por sesión
	setState({ quests = quests(7, { dailyCan = true, streak = 8 }) })
	task.wait(4.5)
	assert(not Missions.debug().popup, "salió dos veces")
	add("   aviso diario:", cut(all, 300))
end)

step("Saltar el tutorial: dos toques, sin celebración, y se va todo", function()
	Missions.stop()
	clicks = {}
	sent = {}
	banners = {}
	state.quests = quests(3, { dailyCan = false })
	standAt(plot.spawn)
	Missions.start(ctx)
	task.wait(0.4)
	local d = Missions.debug()
	assert(d.card and d.guide == "corridor", "tarjeta/guía")
	d.onSkip()
	d = Missions.debug()
	assert(d.skipText == t("sure") and #sent == 0, "el primer toque ya saltó")
	d.onSkip()
	assert(lastSent() == "skipTutorial", "no pidió saltar")
	task.wait(0.3)
	d = Missions.debug()
	assert(not d.card and d.guide == nil, "sigue la tarjeta o la guía")
	setState({ quests = quests(7, { dailyCan = false }) })
	task.wait(0.2)
	assert(#banners == 0, "celebró un tutorial saltado")
end)

step("Parar: no deja nada (botón, guía, ventanas, ganchos)", function()
	Missions.stop()
	assert(find("side:" .. t("missions")) == nil, "queda el botón")
	assert(workspace:FindFirstChild("TutorialGuide") == nil and gui:FindFirstChild("DailyPopup") == nil and gui:FindFirstChild("TutorialCard") == nil, "quedan piezas")
	assert(hooks.state == nil and renderers.missions == nil, "quedan ganchos")
end)

step("Sin avisos ni errores en el registro", function()
	local mine = {}
	for _, w in ipairs(warns) do
		if w:find("Missions") or w:find("Misiones") or w:find("Client") then
			table.insert(mine, w)
		end
	end
	assert(#mine == 0, cut(table.concat(mine, " | "), 600))
	if #warns > 0 then
		add("   (otros avisos del servidor: " .. #warns .. ") " .. cut(table.concat(warns, " | "), 300))
	end
end)

add(string.format("   (mundo listo en %.1f s)", os.clock() - T0))
local finished, current = false, nil
task.spawn(function()
	for _, s in ipairs(queue) do
		current = s.name
		local t1 = os.clock()
		local ok, err = pcall(s.fn)
		if ok then
			add("✅", s.name, string.format("(%.1f s)", os.clock() - t1))
		else
			fails += 1
			add("❌", s.name, "->", err)
		end
	end
	finished = true
end)
local t0 = os.clock()
while not finished and os.clock() - t0 < 150 do
	task.wait(0.5)
end
if not finished then
	fails += 1
	add("❌ Se quedó colgado en:", current)
end
pcall(Missions.stop)
add(fails == 0 and "🎉 CLIENTE OK" or ("⚠️ FALLOS: " .. fails))
return cut(table.concat(out, "\n"), 60000) -- (cut también arregla cualquier UTF-8 roto)
