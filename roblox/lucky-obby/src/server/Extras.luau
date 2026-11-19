-- Lucky Obby Race — extras (Shadow)
--   · CAJAS LUCKY por el recorrido: 2 cajas "?" al principio de cada tramo; si no llevas objeto, al tocarla te da uno
--     (con tu suerte y tu puesto, como el lucky block normal). Se recargan a los 6 s.
--   · RÉCORDS: tu mejor tiempo se guarda (Data.best) y si lo bates te lo celebra (evento "record").
--   · TIENDA DE ESTELAS en el vestíbulo: 6 estelas que se compran con monedas y se equipan (Data.trails / Data.trail).
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Extras = {}
local G, C, K

local function hrpOf(player)
	local char = typeof(player) == "Instance" and player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end
local function notify(player, kind, data)
	if typeof(player) == "Instance" then
		G.Net.Event:FireClient(player, kind, data or {})
	end
end
local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end
local function billboard(parent, text, color, w, h, offset)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(w, h)
	bb.StudsOffsetWorldSpace = offset or Vector3.new(0, 3, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 90
	bb.Parent = parent
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.RichText = true
	l.Font = Enum.Font.LuckiestGuy
	l.TextColor3 = color
	l.TextStrokeTransparency = 0.2
	l.Text = text
	l.Parent = bb
	return l
end

-- CAJAS LUCKY ----------------------------------------------------------------
local boxes = {} -- { part, readyAt }
local function newBox(pos, parent)
	local b = part({ Name = "LuckyBox", Size = Vector3.new(2.8, 2.8, 2.8), CFrame = CFrame.new(pos), Color = Color3.fromRGB(255, 205, 50), Material = Enum.Material.SmoothPlastic }, parent)
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back, Enum.NormalId.Left, Enum.NormalId.Right, Enum.NormalId.Top, Enum.NormalId.Bottom }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.LightInfluence = 0
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 25
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.TextScaled = true
		l.Font = Enum.Font.LuckiestGuy
		l.Text = "?"
		l.TextColor3 = Color3.new(1, 1, 1)
		l.TextStrokeColor3 = Color3.fromRGB(160, 90, 0)
		l.TextStrokeTransparency = 0
		l.Parent = sg
		sg.Parent = b
	end
	local edge = Instance.new("SelectionBox")
	edge.Adornee = b
	edge.LineThickness = 0.08
	edge.Color3 = Color3.fromRGB(255, 140, 0)
	edge.Parent = b
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 5
	pe.Lifetime = NumberRange.new(0.8, 1.4)
	pe.Speed = NumberRange.new(1, 2)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 240, 150))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	pe.Parent = b
	b:SetAttribute("BaseCF", b.CFrame)
	CollectionService:AddTag(b, "LuckyBox")
	table.insert(boxes, { part = b, readyAt = 0 })
end

local function setBoxVisible(b, on)
	b.part.Transparency = on and 0 or 1
	for _, d in ipairs(b.part:GetChildren()) do
		if d:IsA("SurfaceGui") then
			d.Enabled = on
		elseif d:IsA("SelectionBox") then
			d.Visible = on
		elseif d:IsA("ParticleEmitter") then
			d.Enabled = on
		end
	end
end

function Extras.placeBoxes(folder)
	table.clear(boxes)
	local f = Instance.new("Folder")
	f.Name = "LuckyBoxes"
	for _, p in ipairs(folder:GetChildren()) do
		if p:IsA("BasePart") and (p.Name == "Rest" or p.Name == "Checkpoint") then
			for _, x in ipairs({ -4.5, 4.5 }) do
				newBox(Vector3.new(x, p.Position.Y + 3.6, p.Position.Z), f)
			end
		end
	end
	f.Parent = folder
end

local function boxTick()
	if G.Race.state ~= "racing" or #boxes == 0 then
		return
	end
	local now = os.clock()
	for _, b in ipairs(boxes) do
		if b.readyAt > 0 and now >= b.readyAt then
			b.readyAt = 0
			setBoxVisible(b, true)
		end
	end
	for player, s in pairs(G.Race.sessions) do
		if s.racing and not s.finished and not s.item and not s.rolling then
			local hrp = hrpOf(player)
			if hrp then
				for _, b in ipairs(boxes) do
					if b.readyAt == 0 and b.part.Parent and (b.part.Position - hrp.Position).Magnitude < 4.6 then
						if G.Items.grant(player) then
							b.readyAt = now + 6
							setBoxVisible(b, false)
							G.Net.Event:FireAllClients("boxPop", { pos = b.part.Position })
						end
						break
					end
				end
			end
		end
	end
end

-- RÉCORDS --------------------------------------------------------------------
local function hookRecords()
	local finish = G.Race.finish
	G.Race.finish = function(player, ...)
		local ok = finish(player, ...)
		local s = ok and G.Race.sessions[player]
		local d = G.Data.profiles[player]
		if s and d and s.finishTime then
			local t = s.finishTime
			local old = d.best or 0
			if old <= 0 or t < old then
				d.best = t
				notify(player, "record", { time = t, old = old })
			end
		end
		return ok
	end
end

-- ESTELAS --------------------------------------------------------------------
Extras.TRAILS = {
	{ id = "rainbow", icon = "🌈", es = "Arcoíris", en = "Rainbow", price = 150, colors = { Color3.fromRGB(255, 80, 90), Color3.fromRGB(255, 220, 70), Color3.fromRGB(90, 220, 110), Color3.fromRGB(70, 170, 255), Color3.fromRGB(170, 100, 255) } },
	{ id = "fire", icon = "🔥", es = "Fuego", en = "Fire", price = 300, colors = { Color3.fromRGB(255, 240, 120), Color3.fromRGB(255, 120, 30), Color3.fromRGB(200, 30, 20) } },
	{ id = "ice", icon = "❄️", es = "Hielo", en = "Ice", price = 300, colors = { Color3.fromRGB(255, 255, 255), Color3.fromRGB(140, 220, 255), Color3.fromRGB(60, 140, 255) } },
	{ id = "toxic", icon = "☠️", es = "Tóxica", en = "Toxic", price = 450, colors = { Color3.fromRGB(200, 255, 120), Color3.fromRGB(60, 220, 80), Color3.fromRGB(120, 40, 180) } },
	{ id = "galaxy", icon = "🌌", es = "Galaxia", en = "Galaxy", price = 700, colors = { Color3.fromRGB(255, 150, 240), Color3.fromRGB(150, 90, 255), Color3.fromRGB(40, 20, 120) } },
	{ id = "gold", icon = "👑", es = "Oro", en = "Gold", price = 1200, colors = { Color3.fromRGB(255, 255, 210), Color3.fromRGB(255, 205, 50), Color3.fromRGB(200, 130, 20) } },
}
local TRAIL_BY_ID = {}
for _, tr in ipairs(Extras.TRAILS) do
	TRAIL_BY_ID[tr.id] = tr
end

local function makeTrail(parent, a0, a1, tr)
	local kp = {}
	for i, c in ipairs(tr.colors) do
		kp[i] = ColorSequenceKeypoint.new((i - 1) / (#tr.colors - 1), c)
	end
	local t = Instance.new("Trail")
	t.Name = "LuckyTrail"
	t.Attachment0 = a0
	t.Attachment1 = a1
	t.Color = ColorSequence.new(kp)
	t.Lifetime = 0.55
	t.LightEmission = 0.8
	t.FaceCamera = true
	t.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.1), NumberSequenceKeypoint.new(1, 1) })
	t.WidthScale = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0.2) })
	t.Parent = parent
	return t
end

local function applyTrail(player)
	local hrp = hrpOf(player)
	local d = G.Data.profiles[player]
	if not hrp or not d then
		return
	end
	for _, n in ipairs({ "LuckyTrail", "TrailA0", "TrailA1" }) do
		local o = hrp:FindFirstChild(n)
		if o then
			o:Destroy()
		end
	end
	local tr = TRAIL_BY_ID[d.trail or ""]
	if not tr then
		return
	end
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA0"
	a0.Position = Vector3.new(0, 0.9, 0)
	a0.Parent = hrp
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailA1"
	a1.Position = Vector3.new(0, -0.9, 0)
	a1.Parent = hrp
	makeTrail(hrp, a0, a1, tr)
end

local function owns(d, id)
	return table.find(d.trails or {}, id) ~= nil
end

local orbs = {}
local function buildShop()
	local f = Instance.new("Folder")
	f.Name = "TrailShop"
	local c = C.LOBBY - Vector3.new(0, 3, 0) -- suelo del vestíbulo
	local angles = { 30, 60, 120, 240, 300, 330 } -- huecos libres entre tablones, santuario y arco
	for i, tr in ipairs(Extras.TRAILS) do
		local a = math.rad(angles[i])
		local pos = c + Vector3.new(math.sin(a) * 19, 0, math.cos(a) * 19)
		local main = tr.colors[math.ceil(#tr.colors / 2)]
		part({ Name = "Pedestal", Shape = Enum.PartType.Cylinder, Size = Vector3.new(3, 5, 5), CFrame = CFrame.new(pos + Vector3.new(0, 1.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(245, 245, 250), Material = Enum.Material.Marble, CanCollide = true }, f)
		part({ Name = "PedestalRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 5.4, 5.4), CFrame = CFrame.new(pos + Vector3.new(0, 3.05, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = main, Material = Enum.Material.Neon }, f)
		-- orbe que da vueltas y deja la estela de muestra
		local orb = part({ Name = "TrailOrb", Shape = Enum.PartType.Ball, Size = Vector3.new(1.2, 1.2, 1.2), CFrame = CFrame.new(pos + Vector3.new(0, 6, 0)), Color = main, Material = Enum.Material.Neon }, f)
		local a0 = Instance.new("Attachment")
		a0.Position = Vector3.new(0, 0.5, 0)
		a0.Parent = orb
		local a1 = Instance.new("Attachment")
		a1.Position = Vector3.new(0, -0.5, 0)
		a1.Parent = orb
		makeTrail(orb, a0, a1, tr)
		table.insert(orbs, { part = orb, center = pos + Vector3.new(0, 6, 0), phase = i })
		local label = billboard(orb, string.format('%s %s\n<font color="#FFE36B">🪙 %d</font>', tr.icon, string.upper(tr.es), tr.price), Color3.new(1, 1, 1), 7, 2.6, Vector3.new(0, 3, 0))
		local _ = label
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Comprar / Equipar"
		pp.ObjectText = tr.icon .. " " .. tr.es .. " · 🪙" .. tr.price
		pp.HoldDuration = 0.2
		pp.MaxActivationDistance = 10
		pp.RequiresLineOfSight = false
		local anchor = part({ Name = "PromptAnchor", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(pos + Vector3.new(0, 3.5, 0)), Transparency = 1 }, f)
		pp.Parent = anchor
		pp.Triggered:Connect(function(player)
			local d = G.Data.profiles[player]
			if not d then
				return
			end
			if owns(d, tr.id) then
				if d.trail == tr.id then
					d.trail = "" -- volver a pulsar = quitársela
					notify(player, "toast", { text = "Estela quitada" })
				else
					d.trail = tr.id
					notify(player, "toast", { text = tr.icon .. " ¡Estela " .. tr.es .. " equipada!" })
				end
			elseif G.Data.spend(player, tr.price) then
				table.insert(d.trails, tr.id)
				d.trail = tr.id
				notify(player, "toast", { text = tr.icon .. " ¡Has comprado la estela " .. tr.es .. "!" })
				G.Net.Event:FireClient(player, "boxPop", { pos = orb.Position })
			else
				notify(player, "toast", { text = string.format("🪙 %d / %d", d.coins, tr.price) })
				return
			end
			G.Data.save(player)
			applyTrail(player)
		end)
	end
	f.Parent = workspace
	task.spawn(function()
		while true do
			local t = os.clock()
			for _, o in ipairs(orbs) do
				local a = t * 2.2 + o.phase
				o.part.CFrame = CFrame.new(o.center + Vector3.new(math.cos(a) * 2.2, math.sin(t * 3 + o.phase) * 0.6, math.sin(a) * 2.2))
			end
			task.wait(1 / 30)
		end
	end)
end

function Extras.init(g)
	G = g
	K = g.Config
	C = g.Config.COURSE
	-- cajas en cada recorrido nuevo
	local build = G.Course.build
	G.Course.build = function(...)
		local f = build(...)
		local ok, err = pcall(Extras.placeBoxes, f)
		if not ok then
			warn("[Extras] " .. tostring(err))
		end
		return f
	end
	hookRecords()
	buildShop()
	local function onPlayer(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.5)
			applyTrail(p)
		end)
		task.spawn(function()
			for _ = 1, 50 do
				if G.Data.profiles[p] and p.Character then
					break
				end
				task.wait(0.2)
			end
			applyTrail(p)
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
	task.spawn(function()
		while true do
			task.wait(0.1)
			pcall(boxTick)
		end
	end)
	local _ = K
end

return Extras
