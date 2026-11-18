-- Apertura de sobres por etapas: el sobre se agita con "¿COMÚN?", se parte con una animación mística,
-- sale el siguiente con "¿POCO COMÚN?"… hasta llegar a la rareza que le ha tocado (la suerte decide
-- en el servidor: fromR → toR). Cada salto usa una animación distinta en la misma apertura:
--   runas (círculo rúnico y grietas de luz) · rayo divino (añicos) · vórtice de estrellas (implosión)
--   fénix (arde y se deshace en brasas) · eclipse (corona solar y cuatro trozos que flotan)
-- El sobre es el de verdad (ReplicatedStorage.PackTemplates) dentro de un ViewportFrame; sin muestras,
-- se usa la carta plana con los mismos efectos de pantalla.
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local RevealFx = {}
RevealFx.errors = {} -- errores atrapados (para la prueba en el servidor)
RevealFx.lastOrder = {} -- transiciones usadas en la última apertura

-- en el cliente, cada fotograma; en un servidor de prueba (sin RenderStepped), cada paso de física
local STEP = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat
local function note(err)
	table.insert(RevealFx.errors, tostring(err))
	if #RevealFx.errors > 20 then
		table.remove(RevealFx.errors, 1)
	end
end

local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local CAM_CF = CFrame.lookAt(Vector3.new(0, 0.3, -14), Vector3.new(0, 0.1, 0))

local ctx -- piezas del HUD que da init.client (ver RevealFx.setup)
local model = nil -- sobre 3D que se ve ahora
local spin = math.pi -- giro acumulado del sobre
local fxBack, fxFront, aura, labelScale

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
local function tween(o, t, props, style, dir)
	local tw = TweenService:Create(o, TweenInfo.new(t, style or Enum.EasingStyle.Quad, dir or Enum.EasingDirection.Out), props)
	tw:Play()
	return tw
end

local function frame(parent, props)
	props.Parent = parent
	props.BorderSizePixel = 0
	if props.BackgroundTransparency == nil then
		props.BackgroundTransparency = 0
	end
	return ctx.new("Frame", props)
end

local function circle(parent, size, color, transp, pos)
	return frame(parent, { BackgroundColor3 = color, BackgroundTransparency = transp or 0, Size = UDim2.fromOffset(size, size), Position = pos or UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5) }), nil
end

local function round(f)
	ctx.corner(999).Parent = f
	return f
end

local function ring(parent, size, color, thickness, transp)
	local f = round(frame(parent, { BackgroundTransparency = 1, Size = UDim2.fromOffset(size, size), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5) }))
	local st = ctx.stroke(color, thickness)
	st.Transparency = transp or 0
	st.Parent = f
	return f, st
end

local function later(t, fn)
	task.delay(t, function()
		local ok, err = pcall(fn)
		if not ok then
			note(err)
		end
	end)
end

local function easeOutBack(x)
	local c1, c3 = 1.70158, 2.70158
	return 1 + c3 * (x - 1) ^ 3 + c1 * (x - 1) ^ 2
end

local function easeOutBounce(x)
	local n1, d1 = 7.5625, 2.75
	if x < 1 / d1 then
		return n1 * x * x
	elseif x < 2 / d1 then
		x -= 1.5 / d1
		return n1 * x * x + 0.75
	elseif x < 2.5 / d1 then
		x -= 2.25 / d1
		return n1 * x * x + 0.9375
	end
	x -= 2.625 / d1
	return n1 * x * x + 0.984375
end

-- Ejecuta fn(k, e, dt) cada fotograma durante dur segundos (k de 0 a 1) y espera a que acabe
local function animate(dur, fn)
	local t0 = os.clock()
	local done = false
	local conn
	conn = STEP:Connect(function(dt)
		local e = os.clock() - t0
		local k = math.clamp(e / dur, 0, 1)
		local ok, err = pcall(fn, k, e, dt)
		if not ok then
			note(err)
		end
		if not ok or e >= dur then
			conn:Disconnect()
			done = true
		end
	end)
	while not done do
		task.wait()
	end
end

-- Lo mismo sin esperar
local function animateAsync(dur, fn)
	task.spawn(animate, dur, fn)
end

local function rc(r)
	return ctx.rcolor(r)
end

local function flash(color, from, t)
	ctx.flash.BackgroundColor3 = color or WHITE
	ctx.flash.BackgroundTransparency = from or 0.2
	tween(ctx.flash, t or 0.45, { BackgroundTransparency = 1 })
end

local function darken(on)
	tween(ctx.reveal, 0.3, { BackgroundTransparency = on and 0.03 or 0.15 })
end

---------------------------------------------------------------------
-- El sobre 3D
---------------------------------------------------------------------
local function setModel(r)
	if model then
		model:Destroy()
		model = nil
	end
	local folder = ReplicatedStorage:FindFirstChild("PackTemplates")
	local tpl = folder and folder:FindFirstChild("R" .. tostring(r))
	if not tpl then
		return nil
	end
	model = tpl:Clone()
	model.Parent = ctx.packVP
	ctx.packCam.CFrame = CAM_CF
	return model
end

local function pose(x, y, tilt, roll, scale)
	if not model then
		return
	end
	if scale then
		pcall(function()
			model:ScaleTo(math.max(0.03, scale))
		end)
	end
	model:PivotTo(CFrame.new(x or 0, y or 0, 0) * CFrame.Angles(tilt or 0, spin, roll or 0))
end

local function bodyColor(r)
	local body = model and model.PrimaryPart
	return body and body.Color or rc(r)
end

local function piece(size, cf, color, mat, class)
	local p = Instance.new(class or "Part")
	p.Anchored = true
	p.Size = size
	p.CFrame = cf
	p.Color = color
	p.Material = mat or Enum.Material.Foil
	p.Parent = ctx.packVP
	return p
end

-- Trozos que salen despedidos: { part, v (studs/s), w (giro rad/s) }; gravedad g; se desvanecen al final
local function fly(list, dur, g)
	animateAsync(dur, function(k, e)
		for _, it in ipairs(list) do
			local pos = it.p0 + it.v * e + Vector3.new(0, -(g or 0) * e * e / 2, 0)
			it.part.CFrame = CFrame.new(pos) * it.r0 * CFrame.Angles(it.w.X * e, it.w.Y * e, it.w.Z * e)
			it.part.Transparency = math.clamp((k - 0.45) / 0.55, 0, 1)
		end
		if k >= 1 then
			for _, it in ipairs(list) do
				it.part:Destroy()
			end
		end
	end)
end

local function dropModel()
	if model then
		model:Destroy()
		model = nil
	end
end

-- Formas de romperse
local BREAK = {}
function BREAK.halves(color)
	dropModel()
	local list = {}
	for s = -1, 1, 2 do
		local p0 = Vector3.new(s * 0.75, 0, 0)
		table.insert(list, { part = piece(Vector3.new(1.5, 4, 0.5), CFrame.new(p0), color), p0 = p0, r0 = CFrame.Angles(0, spin, 0), v = Vector3.new(s * 9, 4, 1.5), w = Vector3.new(4, s * 2, s * 6) })
	end
	fly(list, 0.7, 14)
end
function BREAK.shards(color)
	dropModel()
	local list = {}
	for i = 1, 16 do
		local p0 = Vector3.new((math.random() - 0.5) * 2.6, (math.random() - 0.5) * 3.6, 0)
		local dir = (p0 + Vector3.new(0, 0, -0.3)).Unit
		local size = Vector3.new(0.2 + math.random() * 0.25, 0.4 + math.random() * 0.9, 0.3 + math.random() * 0.8)
		table.insert(list, { part = piece(size, CFrame.new(p0), i % 4 == 0 and WHITE or color, i % 4 == 0 and Enum.Material.Neon or Enum.Material.Foil, "WedgePart"), p0 = p0, r0 = CFrame.Angles(math.random() * 6, math.random() * 6, math.random() * 6), v = dir * (8 + math.random() * 8) + Vector3.new(0, 3, 0), w = Vector3.new(math.random() * 12 - 6, math.random() * 12 - 6, math.random() * 12 - 6) })
	end
	fly(list, 0.8, 12)
end
function BREAK.quarters(color)
	dropModel()
	local list = {}
	for sx = -1, 1, 2 do
		for sy = -1, 1, 2 do
			local p0 = Vector3.new(sx * 0.75, sy * 1, 0)
			table.insert(list, { part = piece(Vector3.new(1.45, 1.95, 0.5), CFrame.new(p0), color), p0 = p0, r0 = CFrame.Angles(0, spin, 0), v = Vector3.new(sx * 2.4, sy * 2, -0.5), w = Vector3.new(sy * 0.8, sx * 0.6, sx * sy * 1.2) })
		end
	end
	fly(list, 1.3, 0)
end
function BREAK.crumble()
	if not model then
		return
	end
	local list = {}
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.Parent = ctx.packVP
			local p0 = d.Position
			table.insert(list, { part = d, p0 = p0, r0 = d.CFrame.Rotation, v = Vector3.new((math.random() - 0.5) * 3, math.random() * 1.5, (math.random() - 0.5) * 2), w = Vector3.new(math.random() * 3, math.random() * 3, math.random() * 3) })
		end
	end
	-- brasas que suben
	for _ = 1, 14 do
		local p0 = Vector3.new((math.random() - 0.5) * 3, (math.random() - 0.5) * 3.5, 0)
		table.insert(list, { part = piece(Vector3.new(0.18, 0.18, 0.18), CFrame.new(p0), Color3.fromRGB(255, 140 + math.random(0, 80), 40), Enum.Material.Neon), p0 = p0, r0 = CFrame.new(), v = Vector3.new((math.random() - 0.5) * 2, 4 + math.random() * 4, 0), w = Vector3.new(3, 3, 3) })
	end
	model:Destroy()
	model = nil
	fly(list, 1, 9)
end

---------------------------------------------------------------------
-- Etapa: color, cartel y sacudida
---------------------------------------------------------------------
local function setStage(r, mode)
	local c = rc(r)
	for _, ray in ipairs(ctx.rayFrames) do
		ray.BackgroundColor3 = c
	end
	ctx.packGrad.Color = ColorSequence.new(c, ctx.darker(c, 0.35))
	if aura then
		aura.BackgroundColor3 = c
	end
	local name = ctx.Locale.upper(ctx.Locale.name(ctx.Config.RARITIES[r]))
	ctx.packLabel.Text = ctx.t(mode == "bang" and "rarityBang" or "rarityQ", name)
	ctx.packLabel.TextColor3 = model and c:Lerp(WHITE, 0.3) or WHITE
	labelScale.Scale = mode == "bang" and 1.8 or 1.35
	tween(labelScale, 0.35, { Scale = 1 }, Enum.EasingStyle.Back)
end

-- El sobre se agita cada vez más (latidos que suben de tono)
local function agitate(r, dur, from, to)
	from, to = from or 0, to or 1
	local rarity = ctx.Config.RARITIES[r]
	local nextBeat, beat = 0, 0
	animate(dur, function(k, e, dt)
		local a = from + (to - from) * k
		ctx.rays.Rotation += dt * (30 + a * 240)
		spin += dt * (1.2 + a * a * 15)
		local j = 0.04 + 0.32 * a * a
		if model then
			pose((math.random() - 0.5) * j, (math.random() - 0.5) * j + math.sin(e * 2.2) * 0.08, math.sin(e * 3) * 0.12, (math.random() - 0.5) * 0.3 * a)
		else
			ctx.packCard.Rotation = (math.random() - 0.5) * 16 * a
		end
		ctx.packCard.Position = UDim2.new(0.5, (math.random() - 0.5) * 16 * a, 0.5, (math.random() - 0.5) * 16 * a)
		ctx.packScale.Scale = 1 + 0.1 * a + math.sin(e * 20) * 0.035 * a
		ctx.packLabel.Rotation = (math.random() - 0.5) * 7 * a
		if aura then
			aura.Size = UDim2.fromOffset(300 + a * 120 + math.sin(e * 9) * 18, 300 + a * 120 + math.sin(e * 9) * 18)
			aura.BackgroundTransparency = 0.72 - a * 0.25
		end
		if rarity and (rarity.rainbow or rarity.sparkle) then
			ctx.packStroke.Color = Color3.fromHSV((os.clock() * 0.5) % 1, 0.7, 1)
		end
		if e >= nextBeat then
			beat += 1
			nextBeat = e + math.max(0.12, 0.42 - a * 0.3)
			ctx.play("click", 0.55 + a * 0.9)
		end
	end)
	ctx.packLabel.Rotation = 0
end

-- El sobre nuevo aparece (cada transición usa una entrada distinta)
local function emerge(r, how)
	setModel(r)
	setStage(r, "q")
	ctx.play("pop", 0.9 + r * 0.03)
	if not model then
		ctx.packScale.Scale = 0.3
		tween(ctx.packScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
		task.wait(0.45)
		return
	end
	animate(0.5, function(k)
		if how == "drop" then
			pose(0, 6 * (1 - easeOutBounce(k)), 0, 0, 1)
		elseif how == "rise" then
			pose(0, -3.5 * (1 - easeOutBack(k)), 0, 0, 0.3 + 0.7 * easeOutBack(k))
		elseif how == "spin" then
			spin += 0.5
			pose(0, 0, 0, (1 - k) * 2, 0.05 + 0.95 * easeOutBack(k))
		else
			pose(0, 0, 0, 0, 0.4 + 0.6 * easeOutBack(k))
		end
	end)
	pose(0, 0, 0, 0, 1)
end

---------------------------------------------------------------------
-- Efectos de pantalla
---------------------------------------------------------------------
-- Círculo rúnico: dos aros, rombos y letras griegas que giran
local GREEK = { "Α", "Β", "Γ", "Δ", "Θ", "Λ", "Ξ", "Π", "Σ", "Φ", "Ψ", "Ω" }
local function runeCircle(color)
	local holder = frame(fxBack, { BackgroundTransparency = 1, Size = UDim2.fromOffset(520, 520), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5) })
	local scale = ctx.new("UIScale", { Scale = 0, Parent = holder })
	local outer = ring(holder, 520, color, 5)
	outer.Size = UDim2.fromScale(1, 1)
	local inner = ring(holder, 400, WHITE, 3, 0.3)
	for i = 1, 12 do
		local a = (i - 1) / 12 * math.pi * 2
		local d = frame(holder, { BackgroundColor3 = i % 2 == 0 and WHITE or color, Size = UDim2.fromOffset(16, 16), Rotation = 45, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, math.cos(a) * 230, 0.5, math.sin(a) * 230) })
		ctx.corner(3).Parent = d
		local l = ctx.new("TextLabel", { BackgroundTransparency = 1, Text = GREEK[i], Font = Enum.Font.Arial, TextScaled = true, TextColor3 = color:Lerp(WHITE, 0.5), TextStrokeTransparency = 0.4, Size = UDim2.fromOffset(34, 34), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = math.deg(a) + 90, Position = UDim2.new(0.5, math.cos(a + 0.26) * 178, 0.5, math.sin(a + 0.26) * 178), Parent = holder })
		l.Name = "Rune"
	end
	for i = 1, 6 do
		local a = (i - 1) / 6 * 180
		frame(holder, { BackgroundColor3 = color, BackgroundTransparency = 0.55, Size = UDim2.fromOffset(3, 400), Rotation = a, AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) })
	end
	tween(scale, 0.5, { Scale = 1 }, Enum.EasingStyle.Back)
	local alive = true
	task.spawn(function()
		local t0 = os.clock()
		while alive and holder.Parent do
			local e = os.clock() - t0
			holder.Rotation = e * 40
			inner.Rotation = -e * 90
			STEP:Wait()
		end
	end)
	return {
		explode = function()
			alive = false
			tween(scale, 0.5, { Scale = 1.6 }, Enum.EasingStyle.Quart)
			for _, d in ipairs(holder:GetDescendants()) do
				if d:IsA("Frame") then
					tween(d, 0.5, { BackgroundTransparency = 1 })
				elseif d:IsA("TextLabel") then
					tween(d, 0.5, { TextTransparency = 1, TextStrokeTransparency = 1 })
				elseif d:IsA("UIStroke") then
					tween(d, 0.5, { Transparency = 1 })
				end
			end
			later(0.55, function()
				holder:Destroy()
			end)
		end,
	}
end

-- Grietas de luz sobre la cara del sobre (piezas de neón que se mueven con él)
local function cracks(color, dur)
	if not model then
		return
	end
	local body = model.PrimaryPart
	local segs = {}
	for b = 1, 3 do
		local p = Vector3.new(0, 0, -0.27)
		local ang = (b - 1) * 2.1 + math.random() * 0.6
		for _ = 1, 4 do
			ang += (math.random() - 0.5) * 1.2
			local len = 0.45 + math.random() * 0.4
			local q = p + Vector3.new(math.cos(ang) * len, math.sin(ang) * len, 0)
			local mid = (p + q) / 2
			local s = Instance.new("Part")
			s.Anchored = true
			s.Material = Enum.Material.Neon
			s.Color = color:Lerp(WHITE, 0.4)
			s.Size = Vector3.new(0.07, len + 0.05, 0.04)
			s.Transparency = 1
			s.CFrame = body.CFrame * CFrame.new(mid) * CFrame.Angles(0, 0, ang - math.pi / 2)
			s.Parent = model
			table.insert(segs, s)
			p = q
		end
	end
	for i, s in ipairs(segs) do
		later(dur * (i - 1) / #segs, function()
			s.Transparency = 0
			ctx.play("click", 1.4 + i * 0.03)
		end)
	end
end

-- Rayo en zigzag desde arriba hasta el sobre
local function bolt(color, width, life)
	local abs = ctx.reveal.AbsoluteSize
	local scale = 1
	local uiScale = ctx.reveal:FindFirstAncestorWhichIsA("ScreenGui") and ctx.reveal:FindFirstAncestorWhichIsA("ScreenGui"):FindFirstChildOfClass("UIScale")
	if uiScale and uiScale.Scale > 0 then
		scale = uiScale.Scale
	end
	local W, H = abs.X / scale, abs.Y / scale
	local pts = { Vector2.new(W * (0.5 + (math.random() - 0.5) * 0.3), -20) }
	local n = 8
	for i = 1, n do
		local y = -20 + (H * 0.5 + 20) * i / n
		local x = W * 0.5 + (i < n and (math.random() - 0.5) * 140 or 0)
		table.insert(pts, Vector2.new(x, y))
	end
	local parts = {}
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		local mid = (a + b) / 2
		local d = b - a
		for _, layer in ipairs({ { w = width * 3, c = color, t = 0.55 }, { w = width, c = WHITE, t = 0 } }) do
			local f = frame(fxFront, { BackgroundColor3 = layer.c, BackgroundTransparency = layer.t, Size = UDim2.fromOffset(layer.w, d.Magnitude + layer.w * 0.5), Position = UDim2.fromOffset(mid.X, mid.Y), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = math.deg(math.atan2(d.Y, d.X)) - 90 })
			ctx.corner(layer.w).Parent = f
			table.insert(parts, f)
		end
	end
	later(life, function()
		for _, f in ipairs(parts) do
			f:Destroy()
		end
	end)
end

-- Plumas de fuego que se abren como alas a los lados del sobre
local function wings(color)
	local list = {}
	for side = -1, 1, 2 do
		for i = 1, 7 do
			local f = frame(fxBack, { BackgroundColor3 = color, Size = UDim2.fromOffset(26, 120 + i * 18), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new(0.5, side * 40, 0.5, 60), Rotation = side * 8, BackgroundTransparency = 0.15 })
			ctx.corner(14).Parent = f
			local g = ctx.gradient(Color3.fromRGB(255, 240, 160), color, 90)
			g.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
			g.Parent = f
			tween(f, 0.55 + i * 0.03, { Rotation = side * (14 + i * 11) }, Enum.EasingStyle.Back)
			table.insert(list, f)
		end
	end
	return list
end

-- Llamas que suben alrededor del sobre
local function flames(dur)
	local stop = os.clock() + dur
	task.spawn(function()
		while os.clock() < stop do
			local sz = math.random(16, 38)
			local c = Color3.fromRGB(255, math.random(80, 200), 30)
			local f = frame(fxFront, { BackgroundColor3 = c, Size = UDim2.fromOffset(sz, sz * 1.4), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, math.random(-120, 120), 0.5, math.random(40, 140)), BackgroundTransparency = 0.1 })
			ctx.corner(sz).Parent = f
			tween(f, 0.7 + math.random() * 0.4, { Position = f.Position - UDim2.fromOffset(math.random(-30, 30), math.random(150, 240)), Size = UDim2.fromOffset(sz * 0.3, sz * 0.5), BackgroundTransparency = 1 })
			later(1.2, function()
				f:Destroy()
			end)
			task.wait(0.025)
		end
	end)
end

---------------------------------------------------------------------
-- Las cinco transiciones místicas (de la rareza a a la b)
---------------------------------------------------------------------
local TRANS = {}

-- 1) Círculo rúnico: aparece girando detrás, la cara se llena de grietas de luz y se parte en dos
function TRANS.runes(a, b)
	local c2 = rc(b)
	local circ = runeCircle(c2)
	ctx.play("whoosh", 0.6)
	cracks(c2, 0.75)
	agitate(a, 0.85, 0.7, 1)
	flash(c2, 0.25, 0.4)
	ctx.shake(0.5, 0.3)
	ctx.play("reward", 0.7)
	BREAK.halves(bodyColor(a))
	ctx.burst(c2, 18)
	circ.explode()
	task.wait(0.2)
	emerge(b, "rise")
end

-- 2) Rayo divino: se oscurece, el rayo parpadea y cae sobre el sobre, que estalla en añicos
function TRANS.lightning(a, b)
	local c2 = rc(b)
	darken(true)
	for i = 1, 2 do
		bolt(c2, 5, 0.07)
		ctx.play("click", 2)
		task.wait(0.11 + i * 0.04)
	end
	agitate(a, 0.35, 0.8, 1)
	bolt(c2, 10, 0.22)
	flash(WHITE, 0, 0.5)
	ctx.shake(1, 0.4)
	ctx.play("thud", 1.3)
	ctx.play("whoosh", 1.5)
	BREAK.shards(bodyColor(a))
	ctx.burst(c2, 24)
	task.wait(0.35)
	darken(false)
	emerge(b, "drop")
end

-- 3) Vórtice estelar: las estrellas giran hacia dentro, el sobre se encoge hasta un punto de luz y estalla
function TRANS.vortex(a, b)
	local c1, c2 = rc(a), rc(b)
	local stars = {}
	for i = 1, 48 do
		local s = math.random(5, 12)
		local f = round(frame(fxFront, { BackgroundColor3 = i % 3 == 0 and WHITE or (i % 3 == 1 and c2 or c1), Size = UDim2.fromOffset(s, s), AnchorPoint = Vector2.new(0.5, 0.5), BackgroundTransparency = 1 }))
		table.insert(stars, { f = f, r0 = 160 + math.random() * 320, a0 = math.random() * math.pi * 2 })
	end
	ctx.play("fly", 1.4)
	animate(0.95, function(k, e, dt)
		for _, s in ipairs(stars) do
			local rr = s.r0 * (1 - k) ^ 1.4
			local ang = s.a0 + k * 7
			s.f.Position = UDim2.new(0.5, math.cos(ang) * rr, 0.5, math.sin(ang) * rr)
			s.f.BackgroundTransparency = 1 - math.min(1, k * 3) + k * 0.2
		end
		ctx.rays.Rotation += dt * 400
		spin += dt * (6 + k * 30)
		pose(0, 0, 0, k * 0.6, 1 - 0.97 * k * k)
	end)
	for _, s in ipairs(stars) do
		s.f:Destroy()
	end
	dropModel()
	local core = round(frame(fxFront, { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(70, 70), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }))
	tween(core, 0.18, { Size = UDim2.fromOffset(8, 8) })
	task.wait(0.2)
	core:Destroy()
	for k = 0, 2 do
		local f, st = ring(fxFront, 30, k == 1 and WHITE or c2, 7 - k * 2)
		tween(f, 0.6 + k * 0.15, { Size = UDim2.fromOffset(700 + k * 160, 700 + k * 160) }, Enum.EasingStyle.Quart)
		tween(st, 0.6 + k * 0.15, { Transparency = 1 })
		later(0.9, function()
			f:Destroy()
		end)
	end
	flash(c2, 0.3, 0.35)
	ctx.burst(c2, 22)
	ctx.play("pop", 0.7)
	ctx.shake(0.6, 0.3)
	emerge(b, "spin")
end

-- 4) Fénix: alas de fuego, el sobre arde (se vuelve brasa) y se deshace en cenizas que suben
function TRANS.phoenix(a, b)
	local fire = Color3.fromRGB(255, 110, 30)
	local w = wings(fire)
	flames(1.1)
	ctx.play("whoosh", 0.5)
	-- el sobre se pone al rojo y luego negro
	local parts = {}
	if model then
		for _, d in ipairs(model:GetDescendants()) do
			if d:IsA("BasePart") then
				table.insert(parts, { p = d, c = d.Color })
			end
		end
	end
	local ember, ash = Color3.fromRGB(255, 120, 30), Color3.fromRGB(45, 25, 18)
	animate(0.9, function(k, e, dt)
		for _, it in ipairs(parts) do
			it.p.Color = k < 0.6 and it.c:Lerp(ember, k / 0.6) or ember:Lerp(ash, (k - 0.6) / 0.4)
		end
		spin += dt * (2 + k * 8)
		local j = 0.1 + 0.25 * k
		pose((math.random() - 0.5) * j, (math.random() - 0.5) * j, 0, 0)
		ctx.rays.Rotation += dt * 120
	end)
	ctx.play("thud", 0.6)
	BREAK.crumble()
	flash(fire, 0.35, 0.5)
	ctx.burst(fire, 20)
	for _, f in ipairs(w) do
		tween(f, 0.5, { BackgroundTransparency = 1, Size = f.Size + UDim2.fromOffset(0, 80) })
		later(0.55, function()
			f:Destroy()
		end)
	end
	task.wait(0.3)
	ctx.play("reward", 1.15)
	emerge(b, "rise")
end

-- 5) Eclipse: la luna tapa el sol detrás del sobre, sale la corona y el sobre se abre en cuatro trozos
function TRANS.eclipse(a, b)
	local c2 = rc(b)
	darken(true)
	local sun = round(frame(fxBack, { BackgroundColor3 = c2:Lerp(WHITE, 0.3), Size = UDim2.fromOffset(330, 330), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), BackgroundTransparency = 1 }))
	tween(sun, 0.35, { BackgroundTransparency = 0.05 })
	local moon = round(frame(fxBack, { BackgroundColor3 = BLACK, Size = UDim2.fromOffset(318, 318), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.new(0.5, -520, 0.5, -40) }))
	ctx.play("reward", 0.5)
	tween(moon, 0.85, { Position = UDim2.fromScale(0.5, 0.5) }, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	agitate(a, 0.85, 0.3, 0.9)
	-- totalidad: corona y rayos
	local corona, cst = ring(fxBack, 340, WHITE, 10, 0)
	tween(corona, 0.7, { Size = UDim2.fromOffset(640, 640) }, Enum.EasingStyle.Quart)
	tween(cst, 0.7, { Transparency = 1 })
	local rays = {}
	for i = 1, 16 do
		local f = frame(fxBack, { BackgroundColor3 = i % 2 == 0 and WHITE or c2, Size = UDim2.fromOffset(6, 40), AnchorPoint = Vector2.new(0.5, 0.5), Rotation = i * 22.5, Position = UDim2.fromScale(0.5, 0.5) })
		local ang = math.rad(i * 22.5 - 90)
		tween(f, 0.6, { Position = UDim2.new(0.5, math.cos(ang) * 260, 0.5, math.sin(ang) * 260), Size = UDim2.fromOffset(4, 140), BackgroundTransparency = 1 }, Enum.EasingStyle.Quart)
		table.insert(rays, f)
	end
	flash(c2, 0.45, 0.5)
	ctx.play("thud", 0.75)
	ctx.shake(0.5, 0.35)
	BREAK.quarters(bodyColor(a))
	tween(moon, 0.8, { Position = UDim2.new(0.5, 520, 0.5, 40), BackgroundTransparency = 1 }, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	tween(sun, 0.8, { BackgroundTransparency = 1, Size = UDim2.fromOffset(500, 500) })
	later(0.85, function()
		sun:Destroy()
		moon:Destroy()
		corona:Destroy()
		for _, f in ipairs(rays) do
			f:Destroy()
		end
	end)
	task.wait(0.35)
	darken(false)
	emerge(b, "fade")
end

RevealFx.TRANSITIONS = { "runes", "lightning", "vortex", "phoenix", "eclipse" }

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------
-- c = { reveal, packCard, packVP, packCam, packScale, packLabel, packGrad, packStroke, flash, rays, rayFrames,
--       play, shake, burst, rcolor, darker, new, corner, stroke, gradient, t, Locale, Config }
function RevealFx.setup(c)
	ctx = c
	fxBack = ctx.new("Frame", { Name = "RevealFxBack", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 32, Parent = c.reveal })
	fxFront = ctx.new("Frame", { Name = "RevealFxFront", BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 37, Parent = c.reveal })
	aura = round(frame(fxBack, { Name = "Aura", BackgroundColor3 = WHITE, BackgroundTransparency = 1, Size = UDim2.fromOffset(300, 300), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5) }))
	labelScale = c.packLabel:FindFirstChildOfClass("UIScale") or ctx.new("UIScale", { Parent = c.packLabel })
end

-- Toda la parte del sobre: aparece, se agita con "¿RAREZA?", salta de rareza en rareza con una
-- transición distinta cada vez y termina con "¡RAREZA!". Espera hasta el final. Devuelve si hubo 3D.
function RevealFx.run(fromR, toR)
	spin = math.pi
	setModel(fromR)
	local has3D = model ~= nil
	ctx.packCard.BackgroundTransparency = has3D and 1 or 0
	ctx.packStroke.Transparency = has3D and 1 or 0
	ctx.packStroke.Color = WHITE
	ctx.packLabel.Position = has3D and UDim2.new(0, 10, 1, -14) or UDim2.new(0, 10, 0.5, -30)
	aura.BackgroundTransparency = 1
	setStage(fromR, "q")
	pose(0, 0, 0, 0, 1)
	ctx.packScale.Scale = 0
	tween(ctx.packScale, 0.45, { Scale = 1 }, Enum.EasingStyle.Back)
	ctx.play("pop")
	-- transiciones sin repetir en esta apertura (orden al azar)
	local order = table.clone(RevealFx.forceOrder or RevealFx.TRANSITIONS)
	if not RevealFx.forceOrder then
		for i = #order, 2, -1 do
			local j = math.random(1, i)
			order[i], order[j] = order[j], order[i]
		end
	end
	table.clear(RevealFx.lastOrder)
	local cur = fromR
	agitate(cur, 1 + math.min(fromR, 10) * 0.08, 0, toR > fromR and 0.75 or 1)
	local step = 0
	while cur < toR do
		step += 1
		local nxt = cur + 1
		local name = order[(step - 1) % #order + 1]
		table.insert(RevealFx.lastOrder, name)
		local ok, err = pcall(TRANS[name], cur, nxt)
		if not ok then
			note(name .. ": " .. tostring(err))
			warn("[RevealFx] " .. tostring(err))
			emerge(nxt, "fade")
		end
		cur = nxt
		agitate(cur, cur < toR and (0.7 + math.min(cur, 10) * 0.05) or 0.9, 0.3, cur < toR and 0.8 or 1)
	end
	-- ¡ya es la suya!
	setStage(toR, "bang")
	flash(rc(toR), 0.55, 0.3)
	ctx.play("reward", 1.2)
	animate(0.28, function(k, e, dt)
		spin += dt * 20
		pose(0, 0, 0, 0, 1 + 0.12 * math.sin(k * math.pi))
	end)
	return has3D
end

-- Golpe final: el sobre se parte en dos (luego sale el dios). Devuelve si había sobre 3D.
function RevealFx.finale(color)
	local had = model ~= nil
	if had then
		BREAK.halves(color)
	end
	if aura then
		tween(aura, 0.4, { BackgroundTransparency = 1 })
	end
	ctx.packLabel.Text = ""
	return had
end

return RevealFx
