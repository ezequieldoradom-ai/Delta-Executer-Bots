-- Misiones diarias, racha diaria y tutorial para jugadores nuevos (cliente).
-- Lo arranca init.client.luau con Missions.start(ctx) dentro de un pcall: si algo falla aquí,
-- el resto del HUD sigue funcionando. También se puede cargar en el servidor para las pruebas
-- (tools/check_client_missions.luau): por eso no usa Players.LocalPlayer ni RemoteEvents directamente.
--
-- ctx = { player, Config, Locale, t, Format, opt, gui, play, getState, send(acción, a, b), myPlot(),
--         ui = { new, corner, stroke, gradient, darker, label, heavy, button, bump, toast, showBanner, floatText, fonts, colors },
--         panel = { open, render, renderers, signatures, content, current() }, sideButton, badges,
--         refs = { shopButton, tapButton, toastHolder }, isBusy(), hooks }
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local Missions = {}

local ctx, C, Q, t, F, ui
local new, corner, stroke, gradient, darker, label, heavy, button, bump
local TITLE, BTN
local GOLD, GREEN, CYAN, PINK, PURPLE, WHITE
local GREY = Color3.fromRGB(96, 92, 120)
local ORANGE = Color3.fromRGB(255, 150, 50)

local running = false
local generation = 0 -- cada start() tiene su número: el bucle de un start() anterior se para solo
local conns = {}
local made = {} -- instancias de este módulo (se destruyen en stop)

-- estado de cada pieza
local side = { button = nil, badge = nil, badgeLabel = nil, lastCount = -1, pulseAt = 0 }
local panelRefs = { timer = nil, comeBack = nil, tiles = {} }
local confirm = { key = nil, untilT = 0 } -- doble toque para "cambiar misión"
local popup = { shown = false, firstSeen = nil, holder = nil }
local tut = { card = nil, lastStep = nil, skipped = false, skipArmed = nil, welcomed = false, text = nil, done = false }
local guide = { folder = nil, target = nil, ring = nil, a0 = nil, a1 = nil, beams = {}, bb = nil, label = nil, at = 0, key = nil }
local halo = { target = nil, pointerText = nil, frame = nil, stroke = nil, pointer = nil }
local rowGlow = { stroke = nil, color = nil, thickness = nil }

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function keep(inst)
	table.insert(made, inst)
	return inst
end

local function getState()
	return ctx.getState() or {}
end

local function quests()
	return getState().quests
end

-- Segundos que faltan para el cambio de día (UTC, igual que el servidor)
local function resetLeft()
	local now = workspace:GetServerTimeNow()
	return 86400 - (now % 86400)
end

local function rewardIcon(rw)
	if rw.kind == "money" then
		return "💰"
	elseif rw.kind == "luck" then
		return "🍀"
	elseif rw.kind == "speed" then
		return "⚡"
	elseif rw.kind == "pack" then
		return rw.big and "🎁" or "📦"
	end
	return "🎁"
end

local function rewardValue(rw)
	if rw.kind == "money" then
		local income = tonumber(getState().income) or 0
		return "$" .. F.num(math.max(Q.MONEY_MIN, math.floor(income * (rw.secs or 0))))
	elseif rw.kind == "luck" then
		return string.format("x%s · %sm", tostring(Q.LUCK_BOOST), tostring(rw.mins or 0))
	elseif rw.kind == "speed" then
		return string.format("x3 · %sm", tostring(rw.mins or 0))
	elseif rw.kind == "pack" then
		return rw.big and t("megaPack") or t("packWord")
	end
	return ""
end

local function rewardText(rw)
	return rewardIcon(rw) .. " " .. rewardValue(rw)
end

-- Día de hoy dentro del ciclo de 7 (1..7) y cuántas casillas del ciclo están ya reclamadas
local function streakInfo(q)
	local n = #Q.DAILY
	local streak = math.max(1, tonumber(q.streak) or 1)
	local idx = ((streak - 1) % n) + 1
	return idx, q.dailyCan and idx - 1 or idx
end

-- Racha actual (antes de reclamar hoy, la que ya llevas)
local function currentStreak(q)
	local s = tonumber(q.streak) or 0
	return q.dailyCan and math.max(0, s - 1) or s
end

-- Cosas que se pueden reclamar ahora (para el globo rojo)
local function claimable(q)
	if not q then
		return 0
	end
	local n = q.dailyCan and 1 or 0
	for _, m in ipairs(q.missions or {}) do
		if not m.claimed and m.progress >= m.goal then
			n += 1
		end
	end
	return n
end

-- Chispas que salen disparadas desde un punto (en coordenadas de `parent`)
local function sparkBurst(parent, at, n, colors, z, dist)
	for k = 1, n do
		local sz = math.random(8, 18)
		local p = new("Frame", { BackgroundColor3 = colors[(k % #colors) + 1], Size = UDim2.fromOffset(sz, sz), Position = at, AnchorPoint = Vector2.new(0.5, 0.5), Rotation = 45, ZIndex = z, Parent = parent }, { corner(3) })
		local a = math.random() * math.pi * 2
		local d = (dist or 200) * (0.4 + math.random() * 0.6)
		TweenService:Create(p, TweenInfo.new(0.7 + math.random() * 0.5, Enum.EasingStyle.Quint), {
			Position = at + UDim2.fromOffset(math.cos(a) * d, math.sin(a) * d),
			Rotation = math.random(-360, 360),
			BackgroundTransparency = 1,
		}):Play()
		task.delay(1.3, function()
			p:Destroy()
		end)
	end
end

-- Confeti que cae desde arriba por toda la pantalla
local function confetti(n)
	local colors = { GOLD, PINK, CYAN, GREEN, WHITE, ORANGE }
	for k = 1, n do
		local w, h = math.random(10, 18), math.random(16, 26)
		local x = math.random()
		local p = new("Frame", { BackgroundColor3 = colors[(k % #colors) + 1], BorderSizePixel = 0, Size = UDim2.fromOffset(w, h), Position = UDim2.new(x, 0, 0, -40), Rotation = math.random(0, 360), ZIndex = 48, Parent = ctx.gui })
		TweenService:Create(p, TweenInfo.new(1.6 + math.random() * 1.2, Enum.EasingStyle.Sine, Enum.EasingDirection.In), {
			Position = UDim2.new(x + (math.random() - 0.5) * 0.25, 0, 1, 40),
			Rotation = math.random(-720, 720),
		}):Play()
		task.delay(3, function()
			p:Destroy()
		end)
	end
end

---------------------------------------------------------------------
-- Tira de la racha (7 casillas) para el panel y para el aviso diario
---------------------------------------------------------------------
-- tiles: lista donde se guardan las casillas animadas (la de hoy) y la de hoy aunque ya esté reclamada
local function buildStrip(parent, q, z, tiles)
	local idx, done = streakInfo(q)
	new("UIListLayout", { FillDirection = Enum.FillDirection.Horizontal, HorizontalAlignment = Enum.HorizontalAlignment.Center, VerticalAlignment = Enum.VerticalAlignment.Center, Padding = UDim.new(0, 8), SortOrder = Enum.SortOrder.LayoutOrder, Parent = parent })
	for i, rw in ipairs(Q.DAILY) do
		local isToday = q.dailyCan and i == idx
		local isDone = i <= done
		local isMega = rw.big == true
		local base = isDone and Color3.fromRGB(46, 150, 90) or (isToday and GOLD or (isMega and Color3.fromRGB(190, 80, 255) or Color3.fromRGB(84, 66, 158)))
		local tile = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1 / 7, -8, 1, -12), LayoutOrder = i, ZIndex = z, Parent = parent }, {
			corner(14),
			gradient(base, darker(base, 0.38), 90),
		})
		local st = stroke(isToday and WHITE or darker(base, 0.3), isToday and 4 or 2.5)
		st.Parent = tile
		local sc = new("UIScale", { Parent = tile })
		label({ Parent = tile, Font = TITLE, Text = t("dayN", i), Size = UDim2.new(1, -6, 0.2, 0), Position = UDim2.new(0, 3, 0.05, 0), ZIndex = z + 1, StrokeThickness = 1.5 })
		label({ Parent = tile, Font = TITLE, Text = rewardIcon(rw), Size = UDim2.new(1, 0, 0.36, 0), Position = UDim2.new(0, 0, 0.26, 0), ZIndex = z + 1, Stroke = false })
		label({ Parent = tile, Font = BTN, Text = rewardValue(rw), Size = UDim2.new(1, -8, 0.2, 0), Position = UDim2.new(0, 4, 0.68, 0), TextColor3 = Color3.fromRGB(255, 244, 214), ZIndex = z + 1, StrokeThickness = 1.5 })
		if isDone then
			local shade = new("Frame", { BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 1), ZIndex = z + 2, Parent = tile }, { corner(14) })
			label({ Parent = shade, Font = TITLE, Text = "✅", Size = UDim2.new(0.8, 0, 0.5, 0), Position = UDim2.fromScale(0.1, 0.25), ZIndex = z + 3, Stroke = false })
		end
		if isToday then
			table.insert(tiles, { tile = tile, stroke = st, scale = sc, z = z })
		end
	end
	return idx
end

-- Marca al momento la casilla de hoy como reclamada (antes de que llegue el estado del servidor)
local function stampTiles(tiles)
	for _, tl in ipairs(tiles) do
		if tl.tile.Parent and not tl.tile:FindFirstChild("Stamp") then
			local shade = new("Frame", { Name = "Stamp", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 0.5, Size = UDim2.fromScale(1, 1), ZIndex = tl.z + 2, Parent = tl.tile }, { corner(14) })
			label({ Parent = shade, Font = TITLE, Text = "✅", Size = UDim2.new(0.8, 0, 0.5, 0), Position = UDim2.fromScale(0.1, 0.25), ZIndex = tl.z + 3, Stroke = false })
			bump(tl.tile, 1.35)
		end
	end
end

---------------------------------------------------------------------
-- Panel de misiones (usa el panel común del HUD: renderers/signatures)
---------------------------------------------------------------------
local function confirmed(key)
	if confirm.key == key and os.clock() < confirm.untilT then
		confirm.key = nil
		return true
	end
	confirm.key, confirm.untilT = key, os.clock() + 3
	ctx.panel.render(true)
	return false
end

local function missionCard(content, i, m, q)
	local def = C.QUEST_BY_ID[m.id]
	if not def then
		return
	end
	local complete = m.progress >= m.goal
	local accent = m.claimed and GREY or (complete and GREEN or Color3.fromRGB(150, 110, 255))
	local f = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, -14, 0, 108), LayoutOrder = 10 + i, ZIndex = 11, Parent = content }, {
		corner(16),
		gradient(darker(accent, 0.45), Color3.fromRGB(26, 18, 50), 0),
		stroke(accent, (complete and not m.claimed) and 3.5 or 2.5),
	})
	local ic = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(76, 76), Position = UDim2.fromOffset(12, 16), ZIndex = 12, Parent = f }, { corner(16), gradient(accent, darker(accent, 0.5), 90) })
	label({ Parent = ic, Text = m.claimed and "✅" or def.icon, Font = TITLE, Size = UDim2.new(1, -12, 1, -12), Position = UDim2.fromOffset(6, 6), ZIndex = 13, Stroke = false })
	label({ Parent = f, Font = TITLE, Text = ctx.Locale.mission(m.id, m.goal), Size = UDim2.new(0.62, -104, 0, 34), Position = UDim2.fromOffset(100, 8), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 12 })
	label({ Parent = f, Font = BTN, Text = "🎁 " .. rewardText(def.reward), Size = UDim2.new(0.62, -104, 0, 24), Position = UDim2.fromOffset(100, 43), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(255, 226, 150), ZIndex = 12, StrokeThickness = 2 })
	-- barra de progreso
	local k = math.clamp(m.progress / math.max(1, m.goal), 0, 1)
	local track = new("Frame", { BackgroundColor3 = Color3.fromRGB(16, 12, 34), Size = UDim2.new(0.62, -104, 0, 24), Position = UDim2.fromOffset(100, 74), ZIndex = 12, Parent = f }, { corner(12), stroke(darker(accent, 0.6), 2) })
	if k > 0 then
		new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(math.max(0.06, k), 0, 1, 0), ZIndex = 13, Parent = track }, { corner(12), gradient(accent:Lerp(WHITE, 0.25), accent, 90) })
	end
	local progressText = m.id == "train" and string.format("%s / %s", F.time(m.progress), F.time(m.goal)) or string.format("%s / %s", tostring(m.progress), tostring(m.goal))
	label({ Parent = track, Font = BTN, Text = progressText, Size = UDim2.new(1, -10, 1, -4), Position = UDim2.fromOffset(5, 2), ZIndex = 14, StrokeThickness = 2 })
	-- botón: reclamar, reclamado, cambiar (doble toque) o progreso
	local bSize, bPos = UDim2.new(0.38, -22, 0, 76), UDim2.new(0.62, 6, 0, 16)
	if m.claimed then
		button({ Parent = f, Text = "✅ " .. t("claimed"), Size = bSize, Position = bPos, Color = GREY, ZIndex = 12 })
	elseif complete then
		local b
		b = button({ Parent = f, Text = t("claim"), Size = bSize, Position = bPos, Color = GREEN, ZIndex = 12, OnClick = function()
			ctx.send("claimMission", i)
			ctx.play("reward", 1.1)
			sparkBurst(f, UDim2.new(0.81, 0, 0.5, 0), 22, { GOLD, WHITE, GREEN }, 20, 160)
			bump(b, 1.2)
		end })
		b.FontFace = ui.fonts.HEAVY
	elseif (tonumber(q.rr) or 0) > 0 then
		local key = "reroll" .. i
		local asking = confirm.key == key and os.clock() < confirm.untilT
		button({ Parent = f, Text = asking and t("sure") or ("🔄 " .. t("reroll")), Size = bSize, Position = bPos, Color = asking and PINK or PURPLE, ZIndex = 12, OnClick = function()
			if confirmed(key) then
				ctx.send("rerollMission", i)
			end
		end })
	else
		button({ Parent = f, Text = string.format("⏳ %d%%", math.floor(k * 100)), Size = bSize, Position = bPos, Color = GREY, ZIndex = 12 })
	end
end

local function renderPanel()
	local content = ctx.panel.content
	new("UIListLayout", { Padding = UDim.new(0, 12), SortOrder = Enum.SortOrder.LayoutOrder, Parent = content })
	new("UIPadding", { PaddingTop = UDim.new(0, 4), PaddingLeft = UDim.new(0, 4), PaddingBottom = UDim.new(0, 12), Parent = content })
	panelRefs.timer, panelRefs.comeBack, panelRefs.tiles = nil, nil, {}
	local q = quests()
	if not q then
		label({ Parent = content, Font = BTN, Text = "⏳ …", Size = UDim2.new(1, -14, 0, 40), LayoutOrder = 1, ZIndex = 11 })
		return
	end
	-- 1) racha diaria
	local head = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.new(1, -14, 0, 250), LayoutOrder = 1, ZIndex = 11, Parent = content }, {
		corner(18),
		gradient(Color3.fromRGB(128, 62, 28), Color3.fromRGB(30, 16, 46), 90),
		stroke(GOLD, 3),
	})
	label({ Parent = head, Font = TITLE, Text = t("dailyStreak"), Size = UDim2.new(0.5, -14, 0, 38), Position = UDim2.fromOffset(16, 8), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, ZIndex = 12 })
	label({ Parent = head, Font = BTN, Text = t("streakDays", currentStreak(q)), Size = UDim2.new(0.5, -18, 0, 30), Position = UDim2.new(0.5, 0, 0, 12), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(255, 220, 170), ZIndex = 12 })
	local strip = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -20, 0, 124), Position = UDim2.fromOffset(10, 50), ZIndex = 12, Parent = head })
	local idx = buildStrip(strip, q, 12, panelRefs.tiles)
	if q.dailyCan then
		local b
		b = button({ Parent = head, Text = t("claimDay", idx), Size = UDim2.new(0.62, 0, 0, 60), Position = UDim2.new(0.5, 0, 1, -12), AnchorPoint = Vector2.new(0.5, 1), Color = GREEN, ZIndex = 12, OnClick = function()
			ctx.send("claimDaily")
			ctx.play("reward", 0.9)
			stampTiles(panelRefs.tiles)
			sparkBurst(head, UDim2.fromScale(0.5, 0.45), 30, { GOLD, WHITE, GREEN, PINK }, 20, 300)
			bump(b, 1.15)
		end })
		b.FontFace = ui.fonts.HEAVY
	else
		local nextRw = Q.DAILY[(idx % #Q.DAILY) + 1]
		panelRefs.comeBack = label({ Parent = head, Font = BTN, Text = "", Size = UDim2.new(1, -30, 0, 26), Position = UDim2.new(0, 15, 1, -62), TextColor3 = Color3.fromRGB(190, 255, 200), ZIndex = 12, StrokeThickness = 2 })
		label({ Parent = head, Font = BTN, Text = t("tomorrow", rewardText(nextRw)), Size = UDim2.new(1, -30, 0, 24), Position = UDim2.new(0, 15, 1, -32), TextColor3 = Color3.fromRGB(255, 226, 150), ZIndex = 12, StrokeThickness = 2 })
	end
	-- 2) misiones de hoy y cuenta atrás hasta las nuevas
	local bar = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -14, 0, 38), LayoutOrder = 2, ZIndex = 11, Parent = content })
	label({ Parent = bar, Font = TITLE, Text = t("todayMissions"), Size = UDim2.new(0.6, 0, 1, 0), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, ZIndex = 11 })
	panelRefs.timer = label({ Parent = bar, Font = BTN, Text = "", Size = UDim2.new(0.4, -6, 0.8, 0), Position = UDim2.new(0.6, 0, 0.1, 0), TextXAlignment = Enum.TextXAlignment.Right, TextColor3 = Color3.fromRGB(215, 205, 245), ZIndex = 11 })
	-- 3) las misiones
	for i, m in ipairs(q.missions or {}) do
		missionCard(content, i, m, q)
	end
end

local function panelSignature()
	local q = quests()
	if not q then
		return "none"
	end
	local income = tonumber(getState().income) or 0
	local parts = { tostring(q.day), tostring(q.dailyCan), tostring(q.streak), tostring(q.rr), tostring(math.floor(math.log10(math.max(1, income)) * 4)), tostring(confirm.key) }
	for _, m in ipairs(q.missions or {}) do
		table.insert(parts, string.format("%s:%s:%s:%s", tostring(m.id), tostring(m.progress), tostring(m.goal), tostring(m.claimed)))
	end
	return table.concat(parts, "|")
end

local function openMissions()
	ctx.panel.open("missions", "📜 " .. t("missionsTitle"), nil, ORANGE)
end
Missions.open = function()
	openMissions()
end

---------------------------------------------------------------------
-- Aviso diario al entrar (una vez por sesión, si hay premio)
---------------------------------------------------------------------
local function closePopup()
	local holder = popup.holder
	if not holder then
		return
	end
	popup.holder = nil
	if popup.scale then
		TweenService:Create(popup.scale, TweenInfo.new(0.22, Enum.EasingStyle.Back, Enum.EasingDirection.In), { Scale = 0 }):Play()
	end
	TweenService:Create(holder, TweenInfo.new(0.25), { BackgroundTransparency = 1 }):Play()
	task.delay(0.26, function()
		holder:Destroy()
	end)
end

local function openPopup(q)
	if popup.holder then
		return
	end
	local z = 44
	local holder = keep(new("Frame", { Name = "DailyPopup", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = z, Parent = ctx.gui }))
	popup.holder = holder
	popup.claimed = false
	popup.tiles = {}
	TweenService:Create(holder, TweenInfo.new(0.3), { BackgroundTransparency = 0.45 }):Play()
	popup.rays = new("ImageLabel", { BackgroundTransparency = 1, Image = C.VFX.rays, ImageColor3 = GOLD, ImageTransparency = 0.5, Size = UDim2.fromOffset(1000, 1000), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z, Parent = holder })
	local frame = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(700, 450), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = z + 1, Parent = holder }, {
		corner(28),
		gradient(Color3.fromRGB(160, 74, 30), Color3.fromRGB(28, 14, 52), 90),
		stroke(GOLD, 5),
	})
	popup.scale = new("UIScale", { Scale = 0.3, Parent = frame })
	local title = heavy({ Parent = frame, Text = t("dailyTitle"), Size = UDim2.new(1, -120, 0, 58), Position = UDim2.fromOffset(60, 12), ZIndex = z + 2, StrokeThickness = 4 })
	gradient(Color3.fromRGB(255, 240, 160), GOLD, 90).Parent = title
	-- racha y consejo en dos líneas (en una sola, en el móvil la letra quedaba diminuta)
	label({ Parent = frame, Font = BTN, Text = "🔥 " .. t("streakDays", currentStreak(q)), Size = UDim2.new(1, -60, 0, 30), Position = UDim2.fromOffset(30, 70), TextColor3 = Color3.fromRGB(255, 226, 190), ZIndex = z + 2, StrokeThickness = 2 })
	label({ Parent = frame, Font = BTN, Text = t("streakHint"), Size = UDim2.new(1, -60, 0, 24), Position = UDim2.fromOffset(30, 100), TextColor3 = Color3.fromRGB(215, 205, 245), ZIndex = z + 2, StrokeThickness = 2 })
	local strip = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -36, 0, 148), Position = UDim2.fromOffset(18, 128), ZIndex = z + 2, Parent = frame })
	local idx = buildStrip(strip, q, z + 2, popup.tiles)
	local nextRw = Q.DAILY[(idx % #Q.DAILY) + 1]
	label({ Parent = frame, Font = BTN, Text = t("tomorrow", rewardText(nextRw)), Size = UDim2.new(1, -60, 0, 26), Position = UDim2.fromOffset(30, 282), TextColor3 = Color3.fromRGB(255, 226, 150), ZIndex = z + 2, StrokeThickness = 2 })
	local claimBtn
	claimBtn = button({ Parent = frame, Text = t("claimDay", idx), Size = UDim2.fromOffset(460, 84), Position = UDim2.new(0.5, 0, 1, -22), AnchorPoint = Vector2.new(0.5, 1), Color = GREEN, ZIndex = z + 3, OnClick = function()
		if popup.claimed then
			return
		end
		popup.claimed = true
		ctx.send("claimDaily")
		ctx.play("reward", 0.9)
		stampTiles(popup.tiles)
		sparkBurst(frame, UDim2.fromScale(0.5, 0.42), 44, { GOLD, WHITE, GREEN, PINK, CYAN }, z + 6, 460)
		claimBtn.Text = "✅"
		bump(claimBtn, 1.2)
		task.delay(1.4, closePopup)
	end })
	claimBtn.FontFace = ui.fonts.HEAVY
	button({ Parent = frame, Text = "✕", Size = UDim2.fromOffset(52, 52), Position = UDim2.new(1, -12, 0, 12), AnchorPoint = Vector2.new(1, 0), Color = Color3.fromRGB(255, 70, 100), ZIndex = z + 3, Radius = 26, OnClick = closePopup })
	TweenService:Create(popup.scale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	ctx.play("pop")
	task.delay(0.25, function()
		ctx.play("reward", 0.75)
	end)
end
Missions.openPopup = function()
	local q = quests()
	if q then
		openPopup(q)
	end
end

---------------------------------------------------------------------
-- Guía del tutorial en el mundo: haz de luz desde ti hasta el objetivo, aro en el suelo y flecha
-- (piezas solo de tu pantalla: el servidor no las ve)
---------------------------------------------------------------------
local function guideBuild()
	if guide.folder then
		return
	end
	local folder = Instance.new("Folder")
	folder.Name = "TutorialGuide"
	guide.folder = keep(folder)
	local function part(size)
		local p = Instance.new("Part")
		p.Anchored = true
		p.CanCollide = false
		p.CanQuery = false
		p.CanTouch = false
		p.CastShadow = false
		p.Transparency = 1
		p.Size = size
		p.Parent = folder
		return p
	end
	guide.target = part(Vector3.new(1, 1, 1))
	guide.target.Name = "Target"
	-- el eje de los dos extremos mira hacia arriba: el haz sale hacia arriba y cae sobre el objetivo
	guide.a1 = Instance.new("Attachment")
	guide.a1.CFrame = CFrame.new(0, 0.6, 0) * CFrame.Angles(0, 0, math.rad(90))
	guide.a1.Parent = guide.target
	-- aro dorado en el suelo (disco de cilindro: su cara de arriba es la X local)
	guide.ring = part(Vector3.new(0.1, 8, 8))
	guide.ring.Name = "Ring"
	local decal = Instance.new("Decal")
	decal.Texture = C.VFX.ring
	decal.Color3 = GOLD
	decal.Face = Enum.NormalId.Right
	decal.Parent = guide.ring
	guide.decal = decal
	local function beam(width, transp, color, tex)
		local b = Instance.new("Beam")
		b.Attachment1 = guide.a1
		b.FaceCamera = true
		b.Width0 = width
		b.Width1 = width * 0.8
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Segments = 24
		b.Color = ColorSequence.new(color)
		b.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.06, transp), NumberSequenceKeypoint.new(0.94, transp), NumberSequenceKeypoint.new(1, 0.6) })
		if tex then
			b.Texture = tex
			b.TextureMode = Enum.TextureMode.Wrap
			b.TextureLength = 3
			b.TextureSpeed = 1.6
		end
		b.Parent = guide.target
		return b
	end
	guide.beams = {
		beam(0.35, 0.3, GOLD, nil), -- hilo dorado
		beam(1.6, 0.05, Color3.fromRGB(255, 240, 190), C.VFX.sparkle), -- chispas que fluyen hacia el objetivo
	}
	-- flecha y texto encima del objetivo (se ven a través de las paredes). Su tamaño es en píxeles:
	-- en pantallas bajas (móvil en horizontal) se hace más pequeño para no tapar el juego.
	local bb = Instance.new("BillboardGui")
	bb.Name = "TutorialMarker"
	bb.Adornee = guide.target
	bb.AlwaysOnTop = true
	bb.LightInfluence = 0
	bb.Size = UDim2.fromOffset(190, 110)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
	bb.Parent = guide.target
	guide.bb = bb
	guide.label = heavy({ Parent = bb, Text = "", Size = UDim2.fromScale(1, 0.32), TextColor3 = GOLD, StrokeThickness = 3 })
	guide.arrow = label({ Parent = bb, Font = BTN, Text = "▼", Size = UDim2.fromScale(0.34, 0.5), Position = UDim2.fromScale(0.33, 0.36), TextColor3 = GOLD, StrokeThickness = 3 })
	TweenService:Create(guide.arrow, TweenInfo.new(0.45, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Position = UDim2.fromScale(0.33, 0.5) }):Play()
end

-- Tamaño del cartel de la guía según la altura de la pantalla
local function markerSize()
	local cam = workspace.CurrentCamera
	local h = cam and cam.ViewportSize.Y or 720
	local k = math.clamp(h / 760, 0.62, 1)
	return UDim2.fromOffset(math.floor(190 * k), math.floor(110 * k))
end

local function guideHide()
	if guide.folder then
		guide.folder.Parent = nil
	end
	guide.key = nil
end

local function guideDestroy()
	if guide.folder then
		guide.folder:Destroy()
	end
	if guide.a0 then
		guide.a0:Destroy()
	end
	guide = { folder = nil, target = nil, ring = nil, a0 = nil, a1 = nil, beams = {}, bb = nil, label = nil, at = 0, key = nil }
end

-- Sobre más cercano de la zona 1 que se pueda robar
local function nearestPack(from)
	local best, bestD = nil, math.huge
	local z0 = C.CORRIDOR_START
	for _, p in ipairs(workspace:GetChildren()) do
		if p.Name == "Pack" and p:IsA("BasePart") then
			local pos = p.Position
			if pos.Z >= z0 and pos.Z < z0 + C.ZONE_LENGTH then
				local prompt = p:FindFirstChildOfClass("ProximityPrompt")
				local dd = (pos - from).Magnitude
				if prompt and prompt.Enabled and dd < bestD then
					best, bestD = p, dd
				end
			end
		end
	end
	return best
end

-- Tu parcela, guardada: ctx.myPlot() recorre todo workspace.World (miles de piezas) y la guía pregunta
-- 4 veces por segundo. Se vuelve a buscar solo si deja de ser tuya.
local plotCache = nil
local function myPlotCached()
	local p = plotCache
	if p and p.Parent and p:GetAttribute("Owner") == (ctx.player and ctx.player.UserId) then
		return p
	end
	plotCache = ctx.myPlot()
	return plotCache
end

-- Objetivo de cada paso: posición del suelo, texto y tamaño del aro (nil = sin guía en el mundo)
local function guideTarget(step, from)
	local st = getState()
	local plot = myPlotCached()
	if step == 1 or step == 2 then
		if st.onTreadmill then
			return nil
		end
		local tm = plot and plot:FindFirstChild("Treadmill")
		if tm then
			return tm.Position + Vector3.new(0, tm.Size.Y / 2 + 0.05, 0), "🏃 " .. t("treadmill"), 9, "tm"
		end
	elseif step == 3 then
		if from.Z < C.CORRIDOR_START - 8 then
			return Vector3.new(0, 0.45, C.CORRIDOR_START + 4), "⚔️ " .. t("tutCorridor"), 14, "corridor"
		end
		local p = nearestPack(from)
		if p then
			return Vector3.new(p.Position.X, p.Position.Y - p.Size.Y / 2, p.Position.Z), "📦 " .. t("steal"), 6, "pack"
		end
		return Vector3.new(0, 0.45, C.CORRIDOR_START + C.NEST_OFFSET), "📦 " .. t("nest"), 14, "nest"
	elseif step == 4 then
		local cf = plot and plot:GetAttribute("PlotCF")
		if typeof(cf) == "CFrame" then
			return cf.Position + Vector3.new(0, 1.05, 0), "🏠 " .. t("tutHome"), 16, "home"
		end
	elseif step == 5 then
		local packs = st.altarPacks or {}
		local pick = nil
		for i, p in ipairs(packs) do
			if (tonumber(p.rem) or 0) <= 0 then
				pick = i
				break
			end
		end
		pick = pick or (#packs > 0 and 1 or nil)
		local altar = plot and pick and plot:FindFirstChild("Altar" .. pick)
		if altar and altar:IsA("BasePart") then
			return altar.Position + Vector3.new(0, altar.Size.Y / 2 + 0.6, 0), "🔮 " .. t("altar"), 5.5, "altar" .. pick
		end
	end
	return nil
end

local function guideUpdate(step)
	local char = ctx.player and ctx.player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not hrp:IsA("BasePart") then
		guideHide()
		return
	end
	local pos, text, ringSize, key = guideTarget(step, hrp.Position)
	if not pos then
		guideHide()
		return
	end
	guideBuild()
	-- el punto de salida va en tu personaje (al reaparecer, se crea otro)
	if not guide.a0 or guide.a0.Parent ~= hrp then
		if guide.a0 then
			guide.a0:Destroy()
		end
		local a0 = Instance.new("Attachment")
		a0.Name = "TutorialGuideA0"
		a0.CFrame = CFrame.new(0, 0.4, 0) * CFrame.Angles(0, 0, math.rad(90))
		a0.Parent = hrp
		guide.a0 = a0
		for _, b in ipairs(guide.beams) do
			b.Attachment0 = a0
		end
	end
	guide.target.CFrame = CFrame.new(pos)
	if key ~= guide.key then
		guide.key = key
		guide.ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))
		guide.ring.Size = Vector3.new(0.1, ringSize, ringSize)
		TweenService:Create(guide.ring, TweenInfo.new(0.9, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut, -1, true), { Size = Vector3.new(0.1, ringSize * 1.25, ringSize * 1.25) }):Play()
	else
		guide.ring.CFrame = CFrame.new(pos + Vector3.new(0, 0.06, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end
	local dist = (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude
	local near = dist < 7
	for _, b in ipairs(guide.beams) do
		b.Enabled = not near
		b.CurveSize0 = math.clamp(dist * 0.22, 2, 26)
		b.CurveSize1 = 0
	end
	guide.label.Text = near and text or string.format("%s · %dm", text, math.floor(dist))
	guide.bb.Size = markerSize()
	guide.folder.Parent = workspace
end

---------------------------------------------------------------------
-- Brillo que llama la atención sobre un botón del HUD (tocar la cinta, la tienda)
---------------------------------------------------------------------
local function setHalo(target, pointerText)
	if halo.target == target and halo.pointerText == pointerText and (target == nil or (halo.frame and halo.frame.Parent)) then
		return
	end
	if halo.frame then
		halo.frame:Destroy()
	end
	if halo.pointer then
		halo.pointer:Destroy()
	end
	halo = { target = target, pointerText = pointerText, frame = nil, stroke = nil, pointer = nil }
	if not target or not target.Parent then
		halo.target = nil
		return
	end
	-- el marco va dentro del botón; si el botón tiene UIPadding (TOCA), se compensa para que lo rodee entero
	local pad = target:FindFirstChildOfClass("UIPadding")
	local pl, pr = pad and pad.PaddingLeft.Offset or 0, pad and pad.PaddingRight.Offset or 0
	local pt, pb = pad and pad.PaddingTop.Offset or 0, pad and pad.PaddingBottom.Offset or 0
	halo.frame = new("Frame", {
		Name = "TutorialHalo",
		BackgroundTransparency = 1,
		Size = UDim2.new(1, 16 + pl + pr, 1, 16 + pt + pb),
		Position = UDim2.new(0.5, (pr - pl) / 2, 0.5, (pb - pt) / 2),
		AnchorPoint = Vector2.new(0.5, 0.5),
		ZIndex = target.ZIndex + 2,
		Parent = target,
	}, { corner(22) })
	halo.stroke = stroke(GOLD, 4)
	halo.stroke.Parent = halo.frame
	if pointerText then
		halo.pointer = heavy({ Parent = target, Text = pointerText, Size = UDim2.fromOffset(190, 46), Position = UDim2.new(1, 16, 0.5, -23), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = GOLD, ZIndex = target.ZIndex + 3 })
	end
end

-- En la tienda (paso 6): la fila de la cinta late hasta que la mejoras
local function setRowGlow(st)
	if rowGlow.stroke == st then
		return
	end
	if rowGlow.stroke and rowGlow.stroke.Parent then
		rowGlow.stroke.Color = rowGlow.color
		rowGlow.stroke.Thickness = rowGlow.thickness
	end
	rowGlow = { stroke = st, color = st and st.Color, thickness = st and st.Thickness }
end

local function treadmillRowStroke()
	for _, c in ipairs(ctx.panel.content:GetChildren()) do
		if c:IsA("Frame") and c.LayoutOrder == 1 then
			return c:FindFirstChildOfClass("UIStroke")
		end
	end
	return nil
end

---------------------------------------------------------------------
-- Tarjeta del tutorial (arriba, pequeña, nunca bloquea)
---------------------------------------------------------------------
local function onSkip()
	if tut.skipArmed and os.clock() < tut.skipArmed then
		tut.skipArmed = nil
		tut.skipped = true
		ctx.send("skipTutorial")
		ctx.play("click", 0.8)
		return
	end
	tut.skipArmed = os.clock() + 3
	tut.skipBtn.Text = t("sure")
	bump(tut.skipBtn, 1.15)
end

local function buildCard()
	-- 88 de alto: el texto cabe en dos líneas a tamaño completo (con 72, en el iPhone se encogía a ~10 px)
	local card = keep(new("Frame", { Name = "TutorialCard", BackgroundColor3 = WHITE, Size = UDim2.fromOffset(720, 88), Position = UDim2.new(0.5, 0, 0, 44), AnchorPoint = Vector2.new(0.5, 0), Visible = false, ZIndex = 6, Parent = ctx.gui }, {
		corner(18),
		gradient(Color3.fromRGB(64, 36, 124), Color3.fromRGB(16, 10, 36), 90),
		stroke(GOLD, 3),
	}))
	tut.card = card
	tut.scale = new("UIScale", { Parent = card })
	local badge = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(64, 64), Position = UDim2.fromOffset(8, 12), ZIndex = 7, Parent = card }, {
		corner(32),
		gradient(Color3.fromRGB(255, 226, 110), Color3.fromRGB(240, 130, 40), 90),
		stroke(WHITE, 2),
	})
	label({ Parent = badge, Font = BTN, Text = t("tutStep"), Size = UDim2.new(1, -10, 0.34, 0), Position = UDim2.new(0, 5, 0.1, 0), ZIndex = 8, StrokeThickness = 1.5 })
	tut.stepLabel = heavy({ Parent = badge, Text = "1/6", Size = UDim2.new(1, -8, 0.5, 0), Position = UDim2.new(0, 4, 0.42, 0), ZIndex = 8, StrokeThickness = 2 })
	tut.text = label({ Parent = card, Font = BTN, Text = "", Size = UDim2.new(1, -222, 1, -26), Position = UDim2.fromOffset(82, 5), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7, StrokeThickness = 2 })
	new("UITextSizeConstraint", { MaxTextSize = 26, Parent = tut.text })
	local trackBar = new("Frame", { BackgroundColor3 = Color3.fromRGB(10, 6, 24), Size = UDim2.new(1, -222, 0, 7), Position = UDim2.new(0, 82, 1, -15), ZIndex = 7, Parent = card }, { corner(4) })
	tut.fill = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromScale(0, 1), ZIndex = 8, Parent = trackBar }, { corner(4), gradient(Color3.fromRGB(255, 240, 150), GOLD, 0) })
	tut.skipBtn = button({ Parent = card, Text = t("skip"), Size = UDim2.fromOffset(120, 56), Position = UDim2.new(1, -10, 0.5, 0), AnchorPoint = Vector2.new(1, 0.5), Color = Color3.fromRGB(120, 100, 150), ZIndex = 8, OnClick = onSkip })
end

-- Texto del paso actual (con datos en vivo)
local function stepText(step)
	local st = getState()
	if step == 1 then
		local goal = C.ZONES[1].guardian.speed
		return string.format('%s  <font color="#9BE7FF">(%s/%s)</font>', t("tut1", F.num(goal)), F.num(math.min(tonumber(st.speed) or 0, goal)), F.num(goal))
	elseif step == 2 then
		return t("tut2")
	elseif step == 3 then
		return t("tut3")
	elseif step == 4 then
		return t("tut4")
	elseif step == 5 then
		local minRem = nil
		for _, p in ipairs(st.altarPacks or {}) do
			local rem = tonumber(p.rem) or 0
			minRem = minRem and math.min(minRem, rem) or rem
		end
		if minRem and minRem > 0 then
			return t("tut5wait", F.time(minRem))
		end
		return t("tut5")
	elseif step == 6 then
		return t("tut6", F.num(C.treadmillCost((tonumber(st.treadmill) or 1) + 1)))
	end
	return ""
end

local function celebrateStep(step)
	ctx.play("reward", 1.35)
	if tut.card then
		bump(tut.card, 1.18)
		sparkBurst(tut.card, UDim2.fromScale(0.5, 0.5), 20, { GOLD, WHITE, CYAN }, 9, 260)
	end
	ui.floatText("✔ " .. t("tutNice"), GREEN, ctx.gui, UDim2.new(0.5, -100, 0, 120))
	if step == 3 then
		-- primer paso del pasillo: un toque de ánimo
		ctx.play("whoosh", 1.2)
	end
end

local function celebrateDone()
	ctx.play("reward", 0.8)
	ui.showBanner(t("tutorialDoneBanner"), GOLD)
	confetti(70)
end

---------------------------------------------------------------------
-- Actualización (10 veces por segundo y al llegar cada estado)
---------------------------------------------------------------------
local function updateSide(q)
	local n = claimable(q)
	if side.badge then
		side.badge.Visible = n > 0
		if n ~= side.lastCount then
			side.lastCount = n
			if side.badgeLabel then
				side.badgeLabel.Text = "🎁 " .. n
			end
			if n > 0 then
				bump(side.badge, 1.5)
			end
		end
	end
end

local function updateTutorial(q, now)
	local st = getState()
	local step = tonumber(q.tutorial) or 0
	local DONE = Q.TUTORIAL_DONE
	-- ¿cambió de paso?
	if tut.lastStep == nil then
		tut.lastStep = step
	elseif step ~= tut.lastStep then
		local prev = tut.lastStep
		tut.lastStep = step
		if step > prev and prev >= 1 and prev < DONE and not tut.skipped then
			if step >= DONE then
				celebrateDone()
			else
				celebrateStep(step)
			end
		end
	end
	local active = step >= 1 and step < DONE and not tut.skipped
	if not active then
		if tut.card and tut.card.Visible then
			tut.card.Visible = false
		end
		if not tut.done and (step >= DONE or tut.skipped) then
			-- terminado o saltado: fuera la guía, el brillo y la tarjeta
			tut.done = true
			guideDestroy()
			setHalo(nil)
			setRowGlow(nil)
			if tut.card then
				tut.card:Destroy()
				tut.card = nil
			end
		end
		return false
	end
	if not tut.card then
		buildCard()
	end
	-- bienvenida (solo si empieza desde el principio)
	if not tut.welcomed then
		tut.welcomed = true
		if step == 1 then
			task.delay(1.2, function()
				if running then
					ui.showBanner(t("tutWelcome"), GOLD)
				end
			end)
		end
	end
	-- la tarjeta se esconde mientras llevas un sobre (el aviso de "vuelve a tu parcela" ocupa su sitio)
	local show = st.carrying == nil
	if tut.card.Visible ~= show then
		tut.card.Visible = show
		if show then
			bump(tut.card, 0.8)
		end
	end
	local txt = stepText(step)
	if tut.text.Text ~= txt then
		tut.text.Text = txt
	end
	tut.stepLabel.Text = string.format("%d/%d", step, Q.TUTORIAL_STEPS)
	tut.fill.Size = UDim2.fromScale((step - 1) / Q.TUTORIAL_STEPS, 1)
	if tut.skipArmed and now > tut.skipArmed then
		tut.skipArmed = nil
		tut.skipBtn.Text = t("skip")
	end
	-- brillos del HUD: el botón TOCA en el paso 2 (si estás en la cinta) y la tienda en el 6
	local refs = ctx.refs or {}
	if step == 2 and st.onTreadmill and refs.tapButton then
		setHalo(refs.tapButton, nil)
	elseif step == 6 and refs.shopButton then
		local inShop = ctx.panel.current() == "shop"
		setHalo(refs.shopButton, (not inShop) and ("👈 " .. t("tutHere")) or nil)
		setRowGlow(inShop and treadmillRowStroke() or nil)
	else
		setHalo(nil)
	end
	if step ~= 6 then
		setRowGlow(nil)
	end
	-- guía en el mundo (4 veces por segundo)
	if now - guide.at >= 0.25 then
		guide.at = now
		guideUpdate(step)
	end
	return show
end

local function update()
	if not running then
		return
	end
	local now = os.clock()
	local q = quests()
	if not q then
		return
	end
	updateSide(q)
	local cardShown = updateTutorial(q, now)
	-- los avisos cortos bajan un poco cuando la tarjeta del tutorial está arriba
	local th = ctx.refs and ctx.refs.toastHolder
	if th then
		local y = cardShown and 140 or 92 -- la tarjeta ocupa de 44 a 132
		if th.Position.Y.Offset ~= y then
			th.Position = UDim2.new(0.5, 0, 0, y)
		end
	end
	-- cuenta atrás del panel
	if panelRefs.timer and panelRefs.timer.Parent then
		panelRefs.timer.Text = "⏳ " .. t("resetIn", F.time(resetLeft()))
	end
	if panelRefs.comeBack and panelRefs.comeBack.Parent then
		panelRefs.comeBack.Text = t("comeBack", F.time(resetLeft()))
	end
	-- el doble toque de "cambiar" caduca
	if confirm.key and now > confirm.untilT then
		confirm.key = nil
	end
	-- aviso diario: una vez por sesión, cuando no hay otra ventana delante
	if not popup.shown then
		if q.dailyCan then
			popup.firstSeen = popup.firstSeen or now
			local wait = (tonumber(q.tutorial) or 0) == 1 and 6.5 or 4 -- a los nuevos, después de la bienvenida
			if now - popup.firstSeen > wait and not (ctx.isBusy and ctx.isBusy()) then
				popup.shown = true
				openPopup(q)
			end
		elseif popup.firstSeen == nil then
			popup.shown = true -- ya lo reclamó hoy (en otro servidor o antes): no hace falta
		end
	elseif popup.holder and not q.dailyCan and not popup.claimed then
		closePopup() -- lo reclamó desde el panel
	end
end

-- Animaciones de cada fotograma (baratas: solo lo que está a la vista)
local function onFrame()
	local now = os.clock()
	local pulse = 0.5 + 0.5 * math.sin(now * 5)
	if halo.stroke then
		halo.stroke.Transparency = 0.55 * (1 - pulse)
		halo.stroke.Thickness = 3 + 3 * pulse
	end
	if halo.pointer then
		halo.pointer.Position = UDim2.new(1, 16 + math.sin(now * 6) * 8, 0.5, -23)
	end
	if rowGlow.stroke and rowGlow.stroke.Parent then
		rowGlow.stroke.Color = GOLD:Lerp(WHITE, pulse)
		rowGlow.stroke.Thickness = 3 + 3 * pulse
	end
	for _, list in ipairs({ panelRefs.tiles, popup.tiles or {} }) do
		for _, tl in ipairs(list) do
			if tl.tile.Parent and not tl.tile:FindFirstChild("Stamp") then
				tl.stroke.Color = WHITE:Lerp(GOLD, pulse)
				tl.scale.Scale = 1 + 0.05 * pulse
			end
		end
	end
	if popup.holder and popup.rays then
		popup.rays.Rotation = (now * 18) % 360
	end
end

---------------------------------------------------------------------
-- Arranque y parada
---------------------------------------------------------------------
function Missions.start(context)
	if running then
		return
	end
	ctx = context
	C = ctx.Config
	Q = C.QUESTS
	t = ctx.t
	F = ctx.Format
	ui = ctx.ui
	new, corner, stroke, gradient, darker = ui.new, ui.corner, ui.stroke, ui.gradient, ui.darker
	label, heavy, button, bump = ui.label, ui.heavy, ui.button, ui.bump
	TITLE, BTN = ui.fonts.TITLE, ui.fonts.BTN
	GOLD, GREEN, CYAN, PINK, PURPLE, WHITE = ui.colors.GOLD, ui.colors.GREEN, ui.colors.CYAN, ui.colors.PINK, ui.colors.PURPLE, ui.colors.WHITE
	running = true
	-- panel
	ctx.panel.renderers.missions = renderPanel
	ctx.panel.signatures.missions = panelSignature
	-- botón lateral (entre la Tienda y el Índice) con globo rojo cuando hay algo que reclamar
	local ORDER = 6
	side.button = ctx.sideButton(ORDER, "📜", t("missions"), ORANGE, openMissions)
	side.button.LayoutOrder = 15
	keep(side.button)
	side.badge = ctx.badges and ctx.badges[ORDER]
	side.badgeLabel = side.badge and side.badge:FindFirstChildWhichIsA("TextLabel")
	if side.badge then
		side.badge.Size = UDim2.fromOffset(64, 26)
	end
	-- ganchos: estado nuevo y avisos del servidor
	if ctx.hooks then
		ctx.hooks.state = function()
			update()
		end
		ctx.hooks.toast = function(key)
			if key == "missionDone" and side.button then
				bump(side.button, 1.2)
			end
		end
	end
	local signal = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat
	table.insert(conns, signal:Connect(function()
		local ok, err = pcall(onFrame)
		if not ok and not Missions.lastError then
			Missions.lastError = tostring(err)
			warn("[SAG] Missions (frame): " .. Missions.lastError)
		end
	end))
	generation += 1
	local gen = generation
	task.spawn(function()
		while running and gen == generation do
			task.wait(0.1)
			if not running or gen ~= generation then
				break
			end
			local ok, err = pcall(update)
			if not ok and not Missions.lastError then
				Missions.lastError = tostring(err)
				warn("[SAG] Missions: " .. Missions.lastError)
			end
		end
	end)
end

function Missions.stop()
	running = false
	for _, c in ipairs(conns) do
		c:Disconnect()
	end
	table.clear(conns)
	closePopup()
	guideDestroy()
	setHalo(nil)
	setRowGlow(nil)
	for _, inst in ipairs(made) do
		if inst.Parent then
			inst:Destroy()
		end
	end
	table.clear(made)
	plotCache = nil
	if ctx then
		ctx.panel.renderers.missions = nil
		ctx.panel.signatures.missions = nil
		if ctx.hooks then
			ctx.hooks.state = nil
			ctx.hooks.toast = nil
		end
	end
	side = { button = nil, badge = nil, badgeLabel = nil, lastCount = -1, pulseAt = 0 }
	panelRefs = { timer = nil, comeBack = nil, tiles = {} }
	confirm = { key = nil, untilT = 0 }
	popup = { shown = false, firstSeen = nil, holder = nil }
	tut = { card = nil, lastStep = nil, skipped = false, skipArmed = nil, welcomed = false, text = nil, done = false }
end

-- Para las pruebas: qué se ve ahora mismo
function Missions.debug()
	update()
	return {
		running = running,
		badge = side.badge and side.badge.Visible and side.badgeLabel and side.badgeLabel.Text or nil,
		card = tut.card ~= nil and tut.card.Visible,
		cardText = tut.text and tut.card and tut.text.Text or nil,
		step = tut.lastStep,
		guide = guide.folder ~= nil and guide.folder.Parent ~= nil and guide.key or nil,
		guideLabel = guide.label and guide.label.Text or nil,
		beam = guide.beams[1] ~= nil and guide.beams[1].Enabled and guide.beams[1].Attachment0 ~= nil,
		halo = halo.target and halo.target.Name or nil,
		pointer = halo.pointer ~= nil,
		rowGlow = rowGlow.stroke ~= nil,
		popup = popup.holder ~= nil,
		popupShown = popup.shown,
		error = Missions.lastError,
		skipText = tut.skipBtn and tut.card and tut.skipBtn.Text or nil,
		onSkip = onSkip,
	}
end

return Missions
