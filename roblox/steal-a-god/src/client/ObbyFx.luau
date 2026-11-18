-- Ascenso al Olimpo (cliente): mueve los obstáculos, te devuelve a tu punto de control si tocas
-- algo rojo o te caes, aplica impulsores, baldosas que caen, cintas y viento, y dibuja la barra
-- de la etapa. El servidor construye todo (src/server/Obby.luau) y decide los puntos de control.
-- Todo lo que se mueve usa workspace:GetServerTimeNow(): lo ves igual que los demás jugadores.
local CollectionService = game:GetService("CollectionService")
local MarketplaceService = game:GetService("MarketplaceService")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local ObbyFx = {}

local ctx, t, C, O, ui
local running = false
local conns = {}

local reg = { spin = {}, move = {}, swing = {}, vanish = {}, pad = {}, belt = {}, wind = {}, kill = {} }
local killParams, vanishParams, padParams
local lastRespawn, lastPad = 0, 0
local wasOn = false
local lastStage = -1
local lastSection = 0
local runBase = nil -- os.clock() del inicio de la subida (para el cronómetro)
local hud = {}

local function now()
	return workspace:GetServerTimeNow()
end

local function addParam(list, part)
	table.insert(list, part)
end

local function rebuildParams()
	killParams = OverlapParams.new()
	killParams.FilterType = Enum.RaycastFilterType.Include
	killParams.FilterDescendantsInstances = reg.kill
	vanishParams = OverlapParams.new()
	vanishParams.FilterType = Enum.RaycastFilterType.Include
	local tiles = {}
	for p in pairs(reg.vanish) do
		table.insert(tiles, p)
	end
	vanishParams.FilterDescendantsInstances = tiles
	padParams = OverlapParams.new()
	padParams.FilterType = Enum.RaycastFilterType.Include
	local pads = {}
	for p in pairs(reg.pad) do
		table.insert(pads, p)
	end
	padParams.FilterDescendantsInstances = pads
end

---------------------------------------------------------------------
-- Registro por etiquetas
---------------------------------------------------------------------
local dirty = false
local HOOKS = {
	ObbySpin = function(p)
		reg.spin[p] = { base = p:GetAttribute("BaseCF") or p.CFrame, speed = p:GetAttribute("Speed") or 2 }
	end,
	ObbyMove = function(p)
		reg.move[p] = { base = p:GetAttribute("BaseCF") or p.CFrame, amp = p:GetAttribute("Amp") or 5, period = p:GetAttribute("Period") or 4, phase = p:GetAttribute("Phase") or 0 }
	end,
	ObbySwing = function(m)
		local pivot = m:GetAttribute("Pivot")
		if typeof(pivot) ~= "CFrame" then
			return
		end
		local parts = {}
		for _, d in ipairs(m:GetDescendants()) do
			if d:IsA("BasePart") then
				parts[d] = pivot:ToObjectSpace(d.CFrame)
			end
		end
		reg.swing[m] = { pivot = pivot, parts = parts, amp = m:GetAttribute("Amp") or 1, period = m:GetAttribute("Period") or 2.5, phase = m:GetAttribute("Phase") or 0 }
	end,
	ObbyVanish = function(p)
		reg.vanish[p] = { delay = p:GetAttribute("Delay") or 0.5, t0 = p.Transparency, color = p.Color, busy = false }
		dirty = true
	end,
	ObbyPad = function(p)
		reg.pad[p] = { power = p:GetAttribute("Power") or 80 }
		dirty = true
	end,
	ObbyBelt = function(p)
		local v = p:GetAttribute("Belt")
		if typeof(v) == "Vector3" then
			p.AssemblyLinearVelocity = v -- cinta: arrastra a quien está encima
		end
	end,
	ObbyWind = function(p)
		reg.wind[p] = { push = p:GetAttribute("Push") or Vector3.zero, period = p:GetAttribute("Period") or 3 }
	end,
	ObbyKill = function(p)
		addParam(reg.kill, p)
		dirty = true
	end,
}

local function hookAll()
	for tag, fn in pairs(HOOKS) do
		for _, inst in ipairs(CollectionService:GetTagged(tag)) do
			pcall(fn, inst)
		end
		table.insert(conns, CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
			pcall(fn, inst)
		end))
	end
	rebuildParams()
end

---------------------------------------------------------------------
-- Volver al punto de control
---------------------------------------------------------------------
local function padPart(stage)
	local obby = workspace:FindFirstChild("Obby")
	local pads = obby and obby:FindFirstChild("Pads")
	return pads and pads:FindFirstChild("CP" .. tostring(stage))
end

local function respawn(reason)
	local char = ctx.player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local st = ctx.getState()
	local pad = padPart(st.obby and st.obby.stage or 0)
	if not hrp or not pad or os.clock() - lastRespawn < 0.5 then
		return
	end
	lastRespawn = os.clock()
	local top = pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 3.4, 1)
	hrp.AssemblyLinearVelocity = Vector3.zero
	char:PivotTo(top)
	ctx.play(reason == "kill" and "thud" or "whoosh", reason == "kill" and 1.2 or 0.9)
	ui.floatText(reason == "kill" and "💥" or "💫", Color3.fromRGB(255, 120, 90), ctx.gui, UDim2.new(0.5, -100, 0.4, 0))
end
ObbyFx.respawn = respawn

---------------------------------------------------------------------
-- Barra de la etapa (abajo, encima de la barra de herramientas)
---------------------------------------------------------------------
local function buildHud()
	local new, corner, stroke, gradient = ui.new, ui.corner, ui.stroke, ui.gradient
	local GOLD = ui.colors.GOLD
	hud.bar = new("Frame", { Name = "ObbyBar", BackgroundColor3 = Color3.new(1, 1, 1), Size = UDim2.fromOffset(740, 64), Position = UDim2.new(0.5, 0, 1, -104), AnchorPoint = Vector2.new(0.5, 1), Visible = false, ZIndex = 6, Parent = ctx.gui }, {
		corner(18),
		gradient(Color3.fromRGB(70, 50, 120), Color3.fromRGB(20, 14, 40), 90),
		stroke(GOLD, 3),
	})
	hud.title = ui.heavy({ Parent = hud.bar, Text = "", Size = UDim2.new(1, -330, 0, 34), Position = UDim2.fromOffset(16, 4), TextXAlignment = Enum.TextXAlignment.Left, ZIndex = 7 })
	hud.sub = ui.label({ Parent = hud.bar, Font = ui.fonts.BTN, Text = "", Size = UDim2.new(1, -330, 0, 22), Position = UDim2.fromOffset(16, 38), TextXAlignment = Enum.TextXAlignment.Left, TextColor3 = Color3.fromRGB(230, 220, 255), ZIndex = 7 })
	hud.fillBack = new("Frame", { BackgroundColor3 = Color3.fromRGB(30, 22, 50), Size = UDim2.new(1, -24, 0, 6), Position = UDim2.new(0, 12, 1, -4), ZIndex = 7, Parent = hud.bar }, { corner(3) })
	hud.fill = new("Frame", { BackgroundColor3 = GOLD, Size = UDim2.fromScale(0, 1), ZIndex = 8, Parent = hud.fillBack }, { corner(3) })
	-- saltar etapa (compra de Robux; el servidor la entrega en Shop.processReceipt → Obby.skip)
	local skip = C.PRODUCTS and C.PRODUCTS.obbySkip
	hud.skip = ui.button({ Parent = hud.bar, Text = "⏭ " .. (skip and skip.price or ""), Size = UDim2.fromOffset(92, 48), Position = UDim2.new(1, -306, 0.5, -26), Color = Color3.fromRGB(255, 190, 60), ZIndex = 8, OnClick = function()
		if skip and skip.id ~= 0 then
			pcall(function()
				MarketplaceService:PromptProductPurchase(ctx.player, skip.id)
			end)
		end
	end })
	ui.button({ Parent = hud.bar, Text = "↩", Size = UDim2.fromOffset(92, 48), Position = UDim2.new(1, -206, 0.5, -26), Color = Color3.fromRGB(90, 180, 255), ZIndex = 8, OnClick = function()
		lastRespawn = 0
		respawn("button")
	end })
	ui.button({ Parent = hud.bar, Text = "🚪", Size = UDim2.fromOffset(92, 48), Position = UDim2.new(1, -106, 0.5, -26), Color = Color3.fromRGB(255, 90, 100), ZIndex = 8, OnClick = function()
		ctx.send("obbyLeave")
	end })
end

local function sectionName(sec)
	local s = O.SECTIONS[sec]
	return s and ctx.Locale.name(s) or "?"
end

local function updateHud(st)
	local ob = st.obby
	local stage = ob.stage or 0
	local sec = math.clamp(math.floor(math.max(stage, 0) / O.PER_SECTION) + 1, 1, #O.SECTIONS)
	if stage >= O.STAGES then
		hud.title.Text = t("obbySummit")
	else
		hud.title.Text = "🏛️ " .. t("obbyStage", stage, O.STAGES)
	end
	local timeTxt = runBase and ("⏱ " .. ctx.Format.time(os.clock() - runBase)) or ""
	local best = (ob.best or 0) > 0 and ("  ·  🏆 " .. ctx.Format.time(ob.best)) or ""
	hud.sub.Text = t("obbySection", sec, sectionName(sec)) .. "   " .. timeTxt .. best
	hud.fill.Size = UDim2.fromScale(math.clamp(stage / O.STAGES, 0, 1), 1)
	if hud.skip then
		hud.skip.Visible = stage < O.STAGES
	end
end

-- Aros de los puntos de control ya superados: dorados (solo en tu pantalla)
local function paintPads(stage)
	local obby = workspace:FindFirstChild("Obby")
	local pads = obby and obby:FindFirstChild("Pads")
	if not pads then
		return
	end
	for i = 0, O.STAGES do
		local ring = pads:FindFirstChild("CPRing" .. i)
		if ring then
			ring.Color = i <= stage and Color3.fromRGB(255, 205, 80) or Color3.fromRGB(110, 255, 150)
		end
	end
end

-- Carteles de fin de tramo (en tu idioma)
local function signGate(p)
	if p:FindFirstChild("GateGui") then
		return
	end
	local sg = Instance.new("SurfaceGui")
	sg.Name = "GateGui"
	sg.Face = Enum.NormalId.Back
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 40
	sg.LightInfluence = 0
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.fromRGB(255, 230, 150)
	l.TextStrokeTransparency = 0.3
	local stage = p:GetAttribute("Stage") or 0
	local sec = p:GetAttribute("Section") or 1
	l.Text = stage >= O.STAGES and t("obbyGateTop") or t("obbyGate", sec, ctx.Locale.upper(sectionName(sec)))
	l.Parent = sg
	sg.Parent = p
end

---------------------------------------------------------------------
-- Cada fotograma (solo dentro del obby)
---------------------------------------------------------------------
local function animate(hrpPos)
	local T = now()
	local near = 240
	for p, it in pairs(reg.spin) do
		if p.Parent and (p.Position - hrpPos).Magnitude < near then
			p.CFrame = it.base * CFrame.Angles(0, T * it.speed, 0)
		end
	end
	for p, it in pairs(reg.move) do
		if p.Parent and (it.base.Position - hrpPos).Magnitude < near then
			local w = 2 * math.pi / it.period
			local x = it.amp * math.sin(T * w + it.phase)
			p.CFrame = it.base * CFrame.new(x, 0, 0)
			-- velocidad de la plataforma: te lleva con ella
			p.AssemblyLinearVelocity = it.base.RightVector * (it.amp * w * math.cos(T * w + it.phase))
		end
	end
	for m, it in pairs(reg.swing) do
		if m.Parent and (it.pivot.Position - hrpPos).Magnitude < near then
			local ang = it.amp * math.sin(T * 2 * math.pi / it.period + it.phase)
			local cf = it.pivot * CFrame.Angles(0, 0, ang)
			for part, off in pairs(it.parts) do
				part.CFrame = cf * off
			end
		end
	end
end

local function vanishTile(p, it)
	if it.busy then
		return
	end
	it.busy = true
	ctx.play("click", 0.7)
	TweenService:Create(p, TweenInfo.new(it.delay), { Color = Color3.fromRGB(255, 120, 90) }):Play()
	task.delay(it.delay, function()
		p.Transparency = 0.85
		p.CanCollide = false
		task.delay(2.4, function()
			p.Transparency = it.t0
			p.CanCollide = true
			p.Color = it.color
			it.busy = false
		end)
	end)
end

local function step(dt)
	local st = ctx.getState()
	local ob = st and st.obby
	local on = ob and ob.on == true
	hud.bar.Visible = on and not (ctx.isBusy and ctx.isBusy())
	if on ~= wasOn then
		wasOn = on
		-- la barra de herramientas (el bate) se montaba sobre la barra del obby: fuera mientras subes
		pcall(function()
			game:GetService("StarterGui"):SetCoreGuiEnabled(Enum.CoreGuiType.Backpack, not on)
		end)
		if on then
			ui.showBanner("🏛️ " .. t("obbyTitle"), Color3.fromRGB(255, 215, 110))
			ctx.play("whoosh", 0.8)
			lastStage = ob.stage
			lastSection = 0
			paintPads(ob.stage or 0)
		end
	end
	if not on then
		runBase = nil
		return
	end
	-- cronómetro (el servidor manda cuánto llevas)
	if ob.run then
		local base = os.clock() - ob.run
		if not runBase or math.abs(runBase - base) > 1 then
			runBase = base
		end
	else
		runBase = nil
	end
	-- nuevo punto de control o tramo
	local stage = ob.stage or 0
	if stage ~= lastStage then
		if stage > lastStage and lastStage >= 0 then
			ctx.play("reward", 1 + (stage % 10) * 0.04)
			ui.floatText(t("obbyCheckpoint", stage), Color3.fromRGB(110, 255, 150), ctx.gui, UDim2.new(0.5, -100, 0.32, 0))
		end
		lastStage = stage
		paintPads(stage)
	end
	local sec = math.clamp(math.floor(stage / O.PER_SECTION) + 1, 1, #O.SECTIONS)
	if sec ~= lastSection and stage < O.STAGES then
		if lastSection ~= 0 then
			ui.showBanner(t("obbySection", sec, sectionName(sec)), O.SECTIONS[sec].accent)
		end
		lastSection = sec
	end
	updateHud(st)
	local char = ctx.player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	if dirty then
		dirty = false
		rebuildParams()
	end
	local pos = hrp.Position
	animate(pos)
	-- ¿te has caído?
	local pad = padPart(stage)
	if pad and pos.Y < pad.Position.Y - O.FALL then
		respawn("fall")
		return
	end
	-- ¿tocas algo rojo?
	if #reg.kill > 0 then
		local hits = workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, -1.3, 0), Vector3.new(2.6, 7.2, 2.2), killParams) -- (llega 1 stud bajo los pies: las franjas finas de lava del suelo no se detectaban)
		if #hits > 0 then
			respawn("kill")
			return
		end
	end
	-- bajo tus pies: baldosas que caen e impulsores
	local feet = hrp.CFrame * CFrame.new(0, -3.1, 0)
	for _, p in ipairs(workspace:GetPartBoundsInBox(feet, Vector3.new(2.6, 1.4, 2.6), vanishParams)) do
		local it = reg.vanish[p]
		if it and p.CanCollide then
			vanishTile(p, it)
		end
	end
	if os.clock() - lastPad > 0.45 then
		for _, p in ipairs(workspace:GetPartBoundsInBox(feet, Vector3.new(2.6, 1.6, 2.6), padParams)) do
			local it = reg.pad[p]
			if it then
				lastPad = os.clock()
				local v = hrp.AssemblyLinearVelocity
				hrp.AssemblyLinearVelocity = Vector3.new(v.X, it.power, v.Z)
				ctx.play("pop", 0.8)
				break
			end
		end
	end
	-- viento: empuja de lado mientras sopla la ráfaga
	local T = now()
	for p, it in pairs(reg.wind) do
		local rel = p.CFrame:PointToObjectSpace(pos)
		local blowing = math.sin(T * 2 * math.pi / it.period) > 0.35
		p.Transparency = blowing and 0.92 or 1
		if blowing and math.abs(rel.X) <= p.Size.X / 2 and math.abs(rel.Y) <= p.Size.Y / 2 and math.abs(rel.Z) <= p.Size.Z / 2 then
			hrp.CFrame += it.push * dt
		end
	end
end

---------------------------------------------------------------------
-- Arranque y parada (lo llama init.client con su ctx)
---------------------------------------------------------------------
function ObbyFx.start(c)
	ctx = c
	t = c.t
	C = c.Config
	O = C.OBBY
	ui = c.ui
	if not O then
		return
	end
	running = true
	buildHud()
	task.spawn(function()
		local obby = workspace:WaitForChild("Obby", 60)
		if not obby or not running then
			return
		end
		hookAll()
		for _, p in ipairs(CollectionService:GetTagged("ObbyGateSign")) do
			pcall(signGate, p)
		end
		table.insert(conns, CollectionService:GetInstanceAddedSignal("ObbyGateSign"):Connect(function(p)
			pcall(signGate, p)
		end))
		table.insert(conns, RunService.Heartbeat:Connect(function(dt)
			local ok, err = pcall(step, dt)
			if not ok then
				warn("[ObbyFx] " .. tostring(err))
			end
		end))
	end)
end

function ObbyFx.stop()
	running = false
	for _, c in ipairs(conns) do
		c:Disconnect()
	end
	table.clear(conns)
	if hud.bar then
		hud.bar:Destroy()
	end
end

return ObbyFx
