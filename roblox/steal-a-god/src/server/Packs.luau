-- Sobres: aparición al amanecer, robo, guardianes que persiguen, entrega en la parcela y altares
local RunService = game:GetService("RunService")
local MessagingService = game:GetService("MessagingService")
local CollectionService = game:GetService("CollectionService")

local Packs = {}
local G
local C

Packs.list = {} -- sobres en el mundo
local nextId = 0
local pendingSave = {} -- [player] = { pack = datos, untilT = tiempo }
local tierOf

---------------------------------------------------------------------
-- Tirada de rareza
---------------------------------------------------------------------
local function rollRarity(zoneIndex, luck)
	return C.rollRarity(zoneIndex, luck)
end
Packs.rollRarity = rollRarity

-- Probabilidades reales de cada zona (las mismas que usa la tirada)
function Packs.odds(zoneIndex, luck)
	return C.odds(zoneIndex, luck)
end

-- Entrega central de sobres: altar libre → cola (con límite) → si no cabe, false
function Packs.givePack(player, item)
	local d = G.Data.profiles[player]
	if not d then
		return false
	end
	if #d.altarPacks < G.Core.altarCount(player) then
		table.insert(d.altarPacks, item)
		return true, "altar"
	elseif #d.queue < C.PACK_QUEUE_MAX then
		table.insert(d.queue, item)
		return true, "queue"
	end
	return false, "full"
end

-- Estallido de partículas y luz en un punto del mundo
function Packs.burst(pos, color, amount)
	local holder = Instance.new("Part")
	holder.Anchored = true
	holder.CanCollide = false
	holder.CanQuery = false
	holder.Transparency = 1
	holder.Size = Vector3.new(1, 1, 1)
	holder.Position = pos
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.6, 1.4)
	pe.Speed = NumberRange.new(12, 32)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Drag = 3
	pe.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.6), NumberSequenceKeypoint.new(1, 0) })
	pe.Texture = C.VFX.sparkle
	pe.RotSpeed = NumberRange.new(-180, 180)
	pe.Parent = holder
	local ring = Instance.new("ParticleEmitter")
	ring.Rate = 0
	ring.Lifetime = NumberRange.new(0.4)
	ring.Speed = NumberRange.new(0)
	ring.LightEmission = 1
	ring.Color = ColorSequence.new(color)
	ring.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 14) })
	ring.Transparency = NumberSequence.new(0.2, 1)
	ring.Texture = C.VFX.ring
	ring.Parent = holder
	local light = Instance.new("PointLight")
	light.Color = color
	light.Range = 26
	light.Brightness = 5
	light.Parent = holder
	holder.Parent = workspace
	pe:Emit(amount or 60)
	ring:Emit(3)
	game:GetService("Debris"):AddItem(holder, 2)
end

---------------------------------------------------------------------
-- Objeto físico del sobre
---------------------------------------------------------------------
local function makePackPart(pack)
	local rarity = C.RARITIES[pack.rarity]
	local k = 1.5 * (0.75 + (C.kgScale(pack.kg) - 0.75) * 0.6)
	local p = Instance.new("Part")
	p.Name = "Pack"
	p.Size = Vector3.new(3, 4, 0.5) * k
	p.Anchored = true
	p.CanCollide = false
	p.Color = rarity.color
	p.Material = pack.rarity >= 5 and Enum.Material.Neon or Enum.Material.SmoothPlastic
	local border = Instance.new("SelectionBox")
	border.Adornee = p
	border.LineThickness = 0.08
	border.Color3 = Color3.fromRGB(255, 220, 120)
	border.Parent = p
	local light = Instance.new("PointLight")
	light.Color = rarity.color
	light.Range = 10 + pack.rarity
	light.Brightness = 1 + pack.rarity * 0.2
	light.Parent = p
	if rarity.sparkle or rarity.rainbow or pack.dawn then
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 15
		pe.Lifetime = NumberRange.new(0.8, 1.6)
		pe.Speed = NumberRange.new(1, 4)
		pe.LightEmission = 1
		pe.Color = ColorSequence.new(rarity.color, Color3.new(1, 1, 1))
		pe.Size = NumberSequence.new(0.5, 0)
		pe.Parent = p
	end
	-- cara de la carta: degradado de la rareza, "?" y el peso
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.CanvasSize = Vector2.new(300, 400)
		sg.LightInfluence = 0
		sg.Brightness = 1.5
		local bg = Instance.new("Frame")
		bg.Size = UDim2.fromScale(1, 1)
		bg.BackgroundColor3 = Color3.new(1, 1, 1)
		local grad = Instance.new("UIGradient")
		grad.Color = ColorSequence.new(rarity.color, Color3.new(rarity.color.R * 0.35, rarity.color.G * 0.35, rarity.color.B * 0.35))
		grad.Rotation = 90
		grad.Parent = bg
		local st = Instance.new("UIStroke")
		st.Color = Color3.fromRGB(255, 225, 130)
		st.Thickness = 14
		st.Parent = bg
		bg.Parent = sg
		local q = Instance.new("TextLabel")
		q.BackgroundTransparency = 1
		q.Size = UDim2.new(1, 0, 0.55, 0)
		q.Position = UDim2.fromScale(0, 0.12)
		q.Font = Enum.Font.LuckiestGuy
		q.TextScaled = true
		q.Text = "?"
		q.TextColor3 = Color3.new(1, 1, 1)
		q.Parent = bg
		local w = Instance.new("TextLabel")
		w.BackgroundTransparency = 1
		w.Size = UDim2.new(1, 0, 0.16, 0)
		w.Position = UDim2.fromScale(0, 0.74)
		w.Font = Enum.Font.LuckiestGuy
		w.TextScaled = true
		w.Text = pack.kg .. " KG"
		w.TextColor3 = Color3.fromRGB(255, 230, 140)
		w.Parent = bg
		sg.Parent = p
	end
	local gui = G.World.billboard(p, "", rarity.color, UDim2.fromOffset(240, 60), Vector3.new(0, 3.5 * k, 0))
	gui:SetAttribute("Rarity", pack.rarity)
	gui:SetAttribute("Kg", pack.kg)
	gui:SetAttribute("Dawn", pack.dawn == true)
	gui.Label.Text = "" -- el cliente pone el nombre en su idioma
	CollectionService:AddTag(gui, "Loc")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0.3
	prompt.MaxActivationDistance = 10
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Kind", "steal")
	CollectionService:AddTag(prompt, "LocPrompt")
	prompt.Parent = p
	prompt.Triggered:Connect(function(player)
		Packs.grab(player, pack)
	end)
	-- haz de luz para las rarezas Secreta o superiores
	if pack.rarity >= C.ANNOUNCE_BIG_FROM then
		local beam = Instance.new("Part")
		beam.Name = "Beam"
		beam.Anchored = true
		beam.CanCollide = false
		beam.Material = Enum.Material.Neon
		beam.Color = rarity.id == 10 and Color3.fromRGB(200, 120, 255) or rarity.color
		beam.Transparency = 0.4
		beam.Shape = Enum.PartType.Cylinder
		beam.Size = Vector3.new(300, 3, 3)
		beam.Parent = p
		pack.beam = beam
	end
	p.Parent = workspace
	pack.part = p
	pack.prompt = prompt
end

local function placeOnGround(pack, pos)
	local y = pack.part.Size.Y / 2 + 1.4 + math.sin(os.clock() * 2 + pack.id) * 0.35
	pack.part.CFrame = CFrame.new(pos.X, y, pos.Z) * CFrame.Angles(0, math.rad(os.clock() * 50 % 360), 0)
	if pack.beam then
		pack.beam.CFrame = CFrame.new(pos + Vector3.new(0, 150, 0)) * CFrame.Angles(0, 0, math.rad(90))
	end
end

local function destroyPack(pack)
	pack.state = "gone"
	if pack.part then
		pack.part:Destroy()
	end
	if pack.beam then
		pack.beam:Destroy()
	end
	Packs.list[pack.id] = nil
end

local function spawnPack(zoneIndex, spotIndex, dawn)
	local luck = (G.serverLuckUntil and os.clock() < G.serverLuckUntil) and 3 or 1
	if dawn then
		luck *= C.DAWN_LUCK
	end
	nextId += 1
	local pack = {
		id = nextId,
		zone = zoneIndex,
		spot = spotIndex,
		rarity = rollRarity(zoneIndex, luck),
		kg = C.rollKg(),
		dawn = dawn,
		state = "ground",
		carrier = nil,
	}
	pack.home = G.World.zoneParts[zoneIndex].spots[spotIndex]
	makePackPart(pack)
	placeOnGround(pack, pack.home)
	Packs.list[pack.id] = pack
	return pack
end

---------------------------------------------------------------------
-- Amanecer: se renuevan todos los sobres y se avisa en el chat
---------------------------------------------------------------------
function Packs.refreshAll()
	for _, pack in pairs(Packs.list) do
		if pack.state ~= "carried" and pack.state ~= "pending" then
			destroyPack(pack)
		end
	end
	G.Net.announce("all", "dawn", {}, { color = "#FFB347" })
	local best = {}
	for z = 1, #C.ZONES do
		local dawnSpot = math.random(1, C.PACKS_PER_ZONE)
		for i = 1, C.PACKS_PER_ZONE do
			local pack = spawnPack(z, i, i == dawnSpot)
			if pack.rarity >= C.ANNOUNCE_CHAT_FROM then
				table.insert(best, pack)
			end
		end
	end
	table.sort(best, function(a, b)
		return a.rarity > b.rarity
	end)
	for _, pack in ipairs(best) do
		local big = pack.rarity >= C.ANNOUNCE_BIG_FROM
		local color = G.Format.hex(C.RARITIES[pack.rarity].color)
		G.Net.announce("all", big and "packSpawnedBig" or "packSpawned", { { rarity = pack.rarity }, { zone = pack.zone }, pack.zone }, { color = color, big = big })
		if pack.rarity >= C.ANNOUNCE_GLOBAL_FROM then
			local host = game:GetService("Players"):GetPlayers()[1]
			pcall(function()
				MessagingService:PublishAsync("GlobalAnnounce", { key = "packGlobal", args = { { rarity = pack.rarity }, host and host.DisplayName or "?" }, color = color, jobId = game.JobId })
			end)
		end
	end
end

-- Al anochecer, los sobres que alguien llevaba se pierden
function Packs.nightfall()
	for player, s in pairs(G.Core.sessions) do
		if s.carrying then
			Packs.dropCarried(player, false)
		end
	end
end

---------------------------------------------------------------------
-- Robar, llevar, soltar
---------------------------------------------------------------------
function Packs.grab(player, pack)
	local s = G.Core.sessions[player]
	local d = G.Data.profiles[player]
	if not s or not d or pack.state == "carried" or pack.state == "gone" or pack.state == "pending" then
		return
	end
	if s.carrying or s.afk or G.DayNight.isNight() then
		return
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or (hrp.Position - pack.part.Position).Magnitude > 14 then
		return
	end
	if d.speed < C.ZONES[pack.zone].req then
		return
	end
	pack.state = "carried"
	pack.carrier = player
	s.carrying = pack
	pack.prompt.Enabled = false
	Packs.burst(pack.part.Position, C.RARITIES[pack.rarity].color, 40 + pack.rarity * 8)
	-- aura mientras lo llevas
	if not pack.part:FindFirstChild("CarryFX") then
		local att = Instance.new("Attachment")
		att.Name = "CarryFX"
		att.Parent = pack.part
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 35
		pe.Lifetime = NumberRange.new(0.5, 1)
		pe.Speed = NumberRange.new(2, 6)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.LightEmission = 1
		pe.Color = ColorSequence.new(C.RARITIES[pack.rarity].color, Color3.new(1, 1, 1))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.9), NumberSequenceKeypoint.new(1, 0) })
		pe.Texture = C.VFX.sparkle
		pe.RotSpeed = NumberRange.new(-120, 120)
		pe.Parent = att
	end
	if pack.beam then
		pack.beam.Transparency = 0.7
	end
	-- el guardián de la zona de origen despierta y persigue
	local guard = G.World.guardians[pack.zone]
	guard.target = player
	guard.pack = pack
	if pack.rarity >= C.ANNOUNCE_CHAT_FROM then
		G.Net.announce("all", "stoleBig", { player.DisplayName, { rarity = pack.rarity }, { guardian = pack.zone } }, { color = G.Format.hex(C.RARITIES[pack.rarity].color) })
	end
end

-- Suelta el sobre que lleva el jugador. loose=true lo deja en el suelo (golpe); false lo devuelve a su sitio
function Packs.dropCarried(player, loose, at)
	local s = G.Core.sessions[player]
	if not s or not s.carrying then
		return nil
	end
	local pack = s.carrying
	s.carrying = nil
	pack.carrier = nil
	for _, guard in ipairs(G.World.guardians) do
		if guard.target == player then
			guard.target = nil
		end
	end
	if G.DayNight.isNight() then
		destroyPack(pack)
		return nil
	end
	pack.state = loose and "loose" or "ground"
	pack.prompt.Enabled = true
	local fx = pack.part:FindFirstChild("CarryFX")
	if fx then
		fx:Destroy()
	end
	if pack.beam then
		pack.beam.Transparency = 0.4
	end
	local pos = loose and at and Vector3.new(at.X, 2.5, at.Z) or pack.home
	pack.loosePos = pos
	placeOnGround(pack, pos)
	return pack
end

local function deliver(player, pack)
	local d = G.Data.profiles[player]
	local s = G.Core.sessions[player]
	local item = { r = pack.rarity, rem = C.RARITIES[pack.rarity].open, dawn = pack.dawn == true, kg = pack.kg }
	local ok, where = Packs.givePack(player, item)
	if not ok then
		-- avisar como mucho cada 3 s (antes se repetía en cada fotograma)
		if os.clock() - (s.lastFullToast or 0) > 3 then
			s.lastFullToast = os.clock()
			G.Net.toast(player, "queueFull")
		end
		return false
	elseif where == "queue" then
		G.Net.toast(player, "altarsFull")
	end
	s.carrying = nil
	for _, guard in ipairs(G.World.guardians) do
		if guard.target == player then
			guard.target = nil
		end
	end
	if pack.rarity >= C.ANNOUNCE_CHAT_FROM then
		G.Net.announce("all", "escaped", { player.DisplayName, { rarity = pack.rarity } }, { color = G.Format.hex(C.RARITIES[pack.rarity].color) })
	end
	destroyPack(pack)
	return true
end

local function caught(player, guardIndex)
	local s = G.Core.sessions[player]
	if not s or not s.carrying then
		return
	end
	local pack = s.carrying
	G.Net.announce("all", "caught", { { guardian = guardIndex }, player.DisplayName }, { color = "#FF5A5A" })
	local product = C.PRODUCTS.savePack
	if product.id ~= 0 then
		-- ofrecer "Salvar el sobre" durante 10 s
		s.carrying = nil
		pack.carrier = nil
		pack.state = "pending"
		pack.part.Transparency = 1
		pendingSave[player] = { pack = pack, untilT = os.clock() + 10 }
		G.Net.Offer:FireClient(player, "savePack")
		task.delay(10.5, function()
			local p = pendingSave[player]
			if p and p.pack == pack then
				pendingSave[player] = nil
				if pack.state == "pending" then
					pack.part.Transparency = 0
					pack.state = "ground"
					pack.prompt.Enabled = true
					placeOnGround(pack, pack.home)
				end
			end
		end)
	else
		Packs.dropCarried(player, false)
	end
	for _, guard in ipairs(G.World.guardians) do
		if guard.target == player then
			guard.target = nil
		end
	end
	-- de vuelta a casa
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp and s.plot then
		hrp.CFrame = s.plot.spawnCF
	end
end

-- Compra de "Salvar el sobre"
function Packs.savePurchased(player)
	local p = pendingSave[player]
	local d = G.Data.profiles[player]
	if not d then
		return false
	end
	local rarity
	if p and p.pack.state == "pending" then
		rarity = p.pack.rarity
		local item = { r = rarity, rem = C.RARITIES[rarity].open, dawn = p.pack.dawn == true, kg = p.pack.kg }
		if not Packs.givePack(player, item) then
			G.Net.toast(player, "queueFull")
			return false -- no cabe: Roblox reintentará la entrega más tarde
		end
		pendingSave[player] = nil
		destroyPack(p.pack)
	else
		pendingSave[player] = nil
		-- si el tiempo se pasó, se le da un sobre de la mejor zona a la que puede entrar
		local z = 1
		for i, zone in ipairs(C.ZONES) do
			if d.speed >= zone.req then
				z = i
			end
		end
		rarity = rollRarity(z, 1)
		if not Packs.givePack(player, { r = rarity, rem = C.RARITIES[rarity].open, dawn = false, kg = C.rollKg() }) then
			G.Net.toast(player, "queueFull")
			return false
		end
	end
	G.Net.toast(player, "bought")
	return true
end

---------------------------------------------------------------------
-- Altares: cuenta atrás y apertura
---------------------------------------------------------------------
function Packs.tickAltars(player, mult)
	local d = G.Data.profiles[player]
	local s = G.Core.sessions[player]
	if not d or not s then
		return
	end
	local maxA = G.Core.altarCount(player)
	while #d.altarPacks < maxA and #d.queue > 0 do
		table.insert(d.altarPacks, table.remove(d.queue, 1))
	end
	-- "Abrir ya" comprados sin sobre de esa categoría: se aplican al llegar uno
	for _, p in ipairs(d.altarPacks) do
		local tier = tierOf(p.r)
		if p.rem > 0 and (d.openTokens[tier] or 0) > 0 then
			d.openTokens[tier] -= 1
			p.rem = 0
		end
	end
	for _, p in ipairs(d.altarPacks) do
		if p.rem > 0 then
			p.rem = math.max(0, p.rem - mult)
		end
	end
	if not s.plot then
		return
	end
	for i, a in ipairs(s.plot.altars) do
		local p = d.altarPacks[i]
		if i > maxA then
			a.prompt.Enabled = false
			a.glow.Transparency = 1
			a.gui.Label.Text = ""
		elseif p then
			local rarity = C.RARITIES[p.r]
			a.glow.Color = rarity.color
			a.glow.Transparency = p.rem <= 0 and 0 or 0.5
			a.gui.Label.TextColor3 = rarity.color
			a.gui:SetAttribute("Rarity", p.r)
			a.gui:SetAttribute("Rem", p.rem)
			a.gui:SetAttribute("Kg", p.kg or 100)
			a.prompt.Enabled = p.rem <= 0
		else
			a.glow.Transparency = 1
			a.prompt.Enabled = false
			a.gui:SetAttribute("Rarity", 0)
			a.gui:SetAttribute("Rem", 0)
		end
	end
end

local function rollGod(r, dawn)
	local pool = {}
	for _, g in ipairs(C.GODS_BY_RARITY[r] or {}) do
		if not g.dawnOnly or dawn then
			table.insert(pool, g)
		end
	end
	if #pool == 0 then
		pool = C.GODS_BY_RARITY[r]
	end
	return pool[math.random(1, #pool)]
end

function Packs.openAltar(player, i)
	local d = G.Data.profiles[player]
	local p = d and d.altarPacks[i]
	if not p or p.rem > 0 then
		return
	end
	table.remove(d.altarPacks, i)
	local god = rollGod(p.r, p.dawn)
	local kg = p.kg or 100
	G.Avatars.make(god)
	local isNew = G.Core.addGod(player, god, kg)
	-- estallido de luz y partículas en el altar
	local s = G.Core.sessions[player]
	local altar = s and s.plot and s.plot.altars[i]
	if altar then
		local rarity = C.RARITIES[god.r]
		local color = rarity.id == 10 and Color3.fromRGB(200, 120, 255) or rarity.color
		local att = Instance.new("Attachment")
		att.Parent = altar.glow
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 0
		pe.Lifetime = NumberRange.new(0.8, 1.6)
		pe.Speed = NumberRange.new(15, 35)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.LightEmission = 1
		pe.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(1, 0) })
		pe.Parent = att
		pe:Emit(40 + god.r * 10)
		local light = Instance.new("PointLight")
		light.Color = color
		light.Range = 30
		light.Brightness = 6
		light.Parent = att
		game:GetService("Debris"):AddItem(att, 2)
	end
	G.Net.Reveal:FireClient(player, { god = god.id, isNew = isNew, kg = kg })
	if god.r >= C.ANNOUNCE_CHAT_FROM then
		local color = G.Format.hex(C.RARITIES[god.r].color)
		G.Net.announce("all", "gotGod", { player.DisplayName, { god = god.id }, { rarity = god.r } }, { color = color, big = god.r >= C.ANNOUNCE_BIG_FROM })
		if god.r >= C.ANNOUNCE_GLOBAL_FROM then
			pcall(function()
				MessagingService:PublishAsync("GlobalAnnounce", { key = "gotGodGlobal", args = { player.DisplayName, { god = god.id }, { rarity = god.r }, "" }, color = color, jobId = game.JobId })
			end)
		end
	end
	Packs.tickAltars(player, 0)
end

-- "Abrir ya" con Robux: abre el primer sobre de ese grupo de rarezas
function Packs.openNow(player, minR, maxR)
	local d = G.Data.profiles[player]
	if not d then
		return false
	end
	-- solo un sobre de la categoría comprada (el que más tiempo le quede)
	local best
	for _, p in ipairs(d.altarPacks) do
		if p.rem > 0 and p.r >= minR and p.r <= maxR and (not best or p.rem > best.rem) then
			best = p
		end
	end
	if best then
		best.rem = 0
		return true
	end
	return false
end

tierOf = function(r)
	if r <= 4 then
		return "low"
	elseif r <= 8 then
		return "mid"
	end
	return "high"
end
Packs.tierOf = tierOf

---------------------------------------------------------------------
-- Bucle: guardianes, entregas, sobres flotando, pasillo
---------------------------------------------------------------------
local function guardianStep(guard, dt)
	local model = guard.model
	local pos = model:GetPivot().Position
	local target = guard.target
	local s = target and G.Core.sessions[target]
	local hrp = target and target.Character and target.Character:FindFirstChild("HumanoidRootPart")
	if target and (not s or not s.carrying or not hrp or hrp.Position.Z < G.World.SAFE_Z) then
		guard.target = nil
		target = nil
	end
	local goal, speed
	if target and hrp then
		local d = G.Data.profiles[target]
		local hum = target.Character:FindFirstChildOfClass("Humanoid")
		local ws = hum and hum.WalkSpeed or 16
		local guardSpeed = C.ZONES[guard.zone].guardian.speed
		if d and d.speed >= guardSpeed then
			speed = math.max(18, ws * 0.82) -- eres más rápido: escapas
		else
			speed = ws * 1.18 + 4 -- te alcanza
		end
		goal = Vector3.new(hrp.Position.X, guard.height, hrp.Position.Z)
		if (Vector3.new(pos.X, 0, pos.Z) - Vector3.new(hrp.Position.X, 0, hrp.Position.Z)).Magnitude < 7 + guard.height * 0.3 then
			caught(target, guard.zone)
			return
		end
	else
		goal = guard.home
		speed = 40
	end
	local flat = Vector3.new(goal.X - pos.X, 0, goal.Z - pos.Z)
	local dist = flat.Magnitude
	local isAvatar = model:GetAttribute("Avatar")
	if dist < 0.5 then
		if isAvatar then
			G.Avatars.play(model, "idle")
		end
		return
	end
	if isAvatar then
		G.Avatars.play(model, target and "run" or "walk", target and 1.4 or 1)
	end
	local step = math.min(dist, speed * dt)
	local newPos = Vector3.new(pos.X, guard.height, pos.Z) + flat.Unit * step
	local bob = target and math.abs(math.sin(os.clock() * 10)) * 0.8 or 0
	if model:GetAttribute("Animated") or isAvatar then
		bob = 0
	end
	model:PivotTo(CFrame.lookAt(newPos + Vector3.new(0, bob, 0), newPos + flat.Unit + Vector3.new(0, bob, 0)))
	guard.phase = (guard.phase or 0) + dt * (target and 11 or 6)
	G.GodModel.animate(model, guard.phase, target and 0.9 or 0.45)
end

function Packs.start()
	RunService.Heartbeat:Connect(function(dt)
		for _, guard in ipairs(G.World.guardians) do
			guardianStep(guard, dt)
			guard.bb = guard.bb or guard.model:FindFirstChildWhichIsA("BillboardGui", true)
			local bb = guard.bb
			if bb then
				bb:SetAttribute("Chasing", guard.target ~= nil)
			end
		end
		for _, pack in pairs(Packs.list) do
			if pack.state == "carried" and pack.carrier then
				local char = pack.carrier.Character
				local head = char and char:FindFirstChild("Head")
				if head then
					pack.part.CFrame = head.CFrame * CFrame.new(0, 3, 0) * CFrame.Angles(0, math.rad(os.clock() * 120 % 360), 0)
					if pack.beam then
						pack.beam.CFrame = CFrame.new(head.Position + Vector3.new(0, 152, 0)) * CFrame.Angles(0, 0, math.rad(90))
					end
				end
				-- ¿ha llegado a su parcela?
				local s = G.Core.sessions[pack.carrier]
				if s and s.plot and char and char:FindFirstChild("HumanoidRootPart") then
					local hp = char.HumanoidRootPart.Position
					if G.World.inPlot(s.plot, hp) then
						deliver(pack.carrier, pack)
					end
				end
			elseif pack.state == "ground" or pack.state == "loose" then
				placeOnGround(pack, pack.state == "loose" and pack.loosePos or pack.home)
			end
		end
	end)
	-- control del pasillo (5 veces por segundo)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local night = G.DayNight.isNight()
			for player, s in pairs(G.Core.sessions) do
				local d = G.Data.profiles[player]
				local char = player.Character
				local hrp = char and char:FindFirstChild("HumanoidRootPart")
				if d and hrp and s.plot then
					local p = hrp.Position
					if p.Z >= C.CORRIDOR_START - 3 then
						if night then
							hrp.CFrame = s.plot.spawnCF
							G.Net.toast(player, "nightClosed")
						else
							local zi = G.World.zoneAt(p.Z)
							local zone = C.ZONES[zi]
							if zi > 1 and d.speed < zone.req then
								local back = G.World.zoneStart(zi) - 10
								hrp.CFrame = CFrame.new(Vector3.new(p.X, p.Y, back), Vector3.new(p.X, p.Y, back - 10))
								G.Net.toast(player, "needSpeed", G.Format.num(zone.req), { zone = zi })
							end
						end
					end
				end
			end
		end
	end)
end

function Packs.init(g)
	G = g
	C = g.Config
	-- altares: abrir
	for _, plot in ipairs(G.World.plots) do
		for i, a in ipairs(plot.altars) do
			a.prompt.Triggered:Connect(function(player)
				if plot.owner == player then
					Packs.openAltar(player, i)
				end
			end)
		end
	end
	-- avisos de otros servidores
	pcall(function()
		MessagingService:SubscribeAsync("GlobalAnnounce", function(msg)
			local data = msg.Data
			if type(data) == "table" and data.jobId ~= game.JobId then
				G.Net.announce("all", data.key, data.args, { color = data.color, big = true })
			end
		end)
	end)
end

return Packs
