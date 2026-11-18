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
local FLOOR_Y = 0.2 -- parte de arriba de la pista del pasillo
local HALF = 2.25 -- media altura del sobre con sus sellos, por unidad de escala
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- pone de pie un cilindro

-- Centro del nido de una zona
function Packs.nestCentre(zoneIndex)
	return Vector3.new(0, 0, G.World.zoneStart(zoneIndex) + C.NEST_OFFSET)
end

-- Altura del lecho del nido (donde se apoyan los sobres)
local function nestFloor()
	local PS = G.PackStyle
	return PS and (PS.FLOOR_Y + PS.NEST_BED) or FLOOR_Y
end

-- El tamaño depende del peso: k = Config.packScale(kg). El aspecto por rareza lo pone PackStyle.
local function makePackPart(pack)
	local rarity = C.RARITIES[pack.rarity]
	local k = C.packScale(pack.kg)
	pack.k = k
	local p = Instance.new("Part")
	p.Name = "Pack"
	p.Size = Vector3.new(3, 4, 0.5) * k
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Color = rarity.color
	p.Material = Enum.Material.Foil
	p:SetAttribute("K", k)
	p:SetAttribute("Rarity", pack.rarity)
	local top, accent = HALF, rarity.color
	local PS = G.PackStyle
	if PS then
		local info = PS.build(pack, p, k)
		top, accent = info.top, info.accent
	else
		-- sin el módulo de diseño: sobre liso con borde y luz
		local border = Instance.new("SelectionBox")
		border.Adornee = p
		border.LineThickness = 0.08
		border.Color3 = Color3.fromRGB(255, 220, 120)
		border.Parent = p
		local light = Instance.new("PointLight")
		light.Color = rarity.color
		light.Range = 10 + pack.rarity
		light.Brightness = 1 + pack.rarity * 0.2
		light.Shadows = false
		light.Parent = p
	end
	-- cartel con la rareza y el peso: encima de todos los adornos y más grande cuanto más pesa
	-- (más estrecho que la separación entre sobres del nido para que los carteles no se monten)
	local gui = G.World.billboard(p, "", accent, UDim2.fromOffset(120 + 36 * k, 32 + 10 * k), Vector3.new(0, 0, 0))
	gui.StudsOffsetWorldSpace = Vector3.new(0, top * k + 0.7 + 0.55 * k, 0)
	if pack.beam then
		-- hacia la cámara, por delante de la columna de luz, para que se lea
		gui.StudsOffset = Vector3.new(0, 0, pack.beam.Size.Y / 2 + 0.4)
	end
	-- de lejos solo se ven los raros; los comunes aparecen al acercarse (evita la maraña de carteles)
	gui.MaxDistance = 40 + pack.rarity * 5
	gui:SetAttribute("Rarity", pack.rarity)
	gui:SetAttribute("Kg", pack.kg)
	gui:SetAttribute("Dawn", pack.dawn == true)
	gui.Label.Text = "" -- el cliente pone el nombre en su idioma
	CollectionService:AddTag(gui, "Loc")
	local prompt = Instance.new("ProximityPrompt")
	prompt.ActionText = "Steal"
	prompt.ObjectText = ""
	prompt.HoldDuration = 0.3
	-- los sobres están juntos: distancia corta (algo mayor en los gigantes, cuyo centro queda alto)
	prompt.MaxActivationDistance = 9 + math.max(0, k - 1.5) * 1.5
	prompt.RequiresLineOfSight = false
	prompt:SetAttribute("Kind", "steal")
	CollectionService:AddTag(prompt, "LocPrompt")
	prompt.Parent = p
	prompt.Triggered:Connect(function(player)
		Packs.grab(player, pack)
	end)
	p.Parent = workspace
	pack.part = p
	pack.prompt = prompt
end

-- Muestra u oculta el sobre con todos sus adornos (cada pieza recupera su transparencia original)
local function setPackVisible(pack, on)
	local p = pack.part
	if not p then
		return
	end
	local PS = G.PackStyle
	if PS then
		PS.setVisible(p, on)
		return
	end
	p.Transparency = on and 0 or 1
	for _, d in ipairs(p:GetDescendants()) do
		if d:IsA("SelectionBox") then
			d.Visible = on
		elseif d:IsA("PointLight") or d:IsA("BillboardGui") then
			d.Enabled = on
		end
	end
end
Packs.setPackVisible = setPackVisible

-- Postura de reposo: de pie, algo inclinado hacia atrás (5–12°, siempre igual para el mismo id) y mirando hacia `dir`
local function restCFrame(pack, pos, floorY, dir, sink)
	local k = pack.k or 1
	local rng = Random.new(pack.id * 7919 + 13)
	local lean = math.rad(rng:NextNumber(5, 12))
	local side = math.rad(rng:NextNumber(-15, 15)) -- hacia qué lado cae un poco
	local yaw = math.rad(rng:NextNumber(-10, 10))
	if not dir then
		dir = CFrame.Angles(0, rng:NextNumber(0, math.pi * 2), 0).LookVector
	end
	local rot = CFrame.lookAt(Vector3.zero, dir) * CFrame.Angles(0, yaw, 0) * CFrame.Angles(lean * math.cos(side), 0, lean * math.sin(side))
	-- altura para que la esquina más baja toque el suelo (los gigantes no se hunden)
	local extent = math.abs(rot.RightVector.Y) * 1.55 * k + math.abs(rot.UpVector.Y) * HALF * k + math.abs(rot.LookVector.Y) * 0.31 * k
	return CFrame.new(pos.X, floorY + extent - (sink or 0), pos.Z) * rot
end

-- Deja el sobre quieto en su sitio: en su hueco del nido o donde cayó. Solo se llama cuando cambia su estado.
local function placeAtRest(pack)
	local pos, floorY, dir, sink
	if pack.state == "loose" and pack.loosePos then
		pos, floorY, sink, dir = pack.loosePos, pack.loosePos.Y, 0, pack.looseDir
	else
		pos, floorY, sink = pack.home, nestFloor(), 0.12
		-- la cara mira hacia fuera del nido; el del centro, hacia la entrada de la zona
		local centre = Packs.nestCentre(pack.zone)
		local out = Vector3.new(pos.X - centre.X, 0, pos.Z - centre.Z)
		dir = out.Magnitude > 0.5 and out.Unit or Vector3.new(0, 0, -1)
	end
	pack.part.CFrame = restCFrame(pack, pos, floorY, dir, sink)
	if G.PackStyle then
		G.PackStyle.settle(pack.part, floorY) -- columna de luz, piezas que orbitan y efectos de suelo
	end
end

-- Sobre que alguien lleva: flota de pie sobre su cabeza y gira (único caso en que se mueve cada fotograma)
local function placeCarried(pack, head, settle)
	local k = pack.k or 1
	local c = head.Position + Vector3.new(0, 1.7 + HALF * k, 0)
	pack.part.CFrame = CFrame.new(c) * CFrame.Angles(0, (os.clock() * 2.1) % (math.pi * 2), 0)
	if settle and G.PackStyle then
		G.PackStyle.settle(pack.part, nil)
	elseif pack.beam then
		-- la columna de luz va anclada: sube recta desde encima del sobre
		local base = pack.beam:GetAttribute("Base") or HALF * k
		pack.beam.CFrame = CFrame.new(c.X, c.Y + base + pack.beam.Size.X / 2, c.Z) * UPRIGHT
	end
end

-- Suelo bajo un punto (para los sobres que caen fuera del nido)
local function floorAt(at, character)
	local ignore = {}
	if character then
		table.insert(ignore, character)
	end
	for _, guard in ipairs(G.World.guardians) do
		table.insert(ignore, guard.model)
	end
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	for _ = 1, 4 do
		params.FilterDescendantsInstances = ignore
		local hit = workspace:Raycast(at, Vector3.new(0, -60, 0), params)
		if not hit then
			break
		end
		if hit.Instance.Anchored and hit.Instance.CanCollide then
			return hit.Position.Y
		end
		table.insert(ignore, hit.Instance) -- otro jugador o algo suelto: se ignora
	end
	return at.Z >= C.CORRIDOR_START and FLOOR_Y or math.max(0, math.min(at.Y - 3, 0.4))
end

-- Si el punto cae dentro de un nido, el suelo es su lecho (las piezas del nido no se detectan con rayos)
local function nestFloorAt(pos)
	local zi = G.World.zoneAt(pos.Z)
	if zi >= 1 then
		local centre = Packs.nestCentre(zi)
		local d = Vector3.new(pos.X - centre.X, 0, pos.Z - centre.Z).Magnitude
		if d <= 13 then
			return nestFloor() - (d > 10.5 and 0.1 or 0)
		end
	end
	return nil
end

-- ¿Hay ya otro sobre descansando en el hueco de este?
local function homeTaken(pack)
	for _, other in pairs(Packs.list) do
		if other ~= pack and other.zone == pack.zone and other.spot == pack.spot and other.state == "ground" then
			return true
		end
	end
	return false
end

-- Devuelve el sobre a su hueco del nido (o delante del nido si el hueco ya está ocupado)
local function returnHome(pack)
	if homeTaken(pack) then
		local centre = Packs.nestCentre(pack.zone)
		pack.state = "loose"
		pack.loosePos = Vector3.new(centre.X + ((pack.id % 5) - 2) * 3.5, FLOOR_Y, centre.Z - 19)
	else
		pack.state = "ground"
		pack.loosePos = nil
	end
	placeAtRest(pack)
end

-- Brillo de la columna de luz: más tenue mientras alguien lleva el sobre
local function dimBeam(pack, carried)
	if pack.beam then
		local base = pack.beam:GetAttribute("BaseT") or 0.4
		pack.beam.Transparency = carried and math.min(0.92, base + 0.3) or base
	end
end

-- Estela y chispas mientras lo llevas
local function carryFx(pack, on)
	local PS = G.PackStyle
	if PS then
		PS.carryFx(pack, on)
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

-- forced = { rarity, kg } para pruebas y vistas previas; si no, se tira la rareza y el peso
local function spawnPack(zoneIndex, spotIndex, dawn, forced)
	local luck = (G.serverLuckUntil and os.clock() < G.serverLuckUntil) and 3 or 1
	if dawn then
		luck *= C.DAWN_LUCK
	end
	nextId += 1
	local pack = {
		id = nextId,
		zone = zoneIndex,
		spot = spotIndex,
		rarity = forced and forced.rarity or rollRarity(zoneIndex, luck),
		kg = forced and forced.kg or C.rollKg(),
		dawn = dawn,
		state = "ground",
		carrier = nil,
	}
	pack.home = G.World.zoneParts[zoneIndex].spots[spotIndex]
	makePackPart(pack)
	placeAtRest(pack)
	Packs.list[pack.id] = pack
	return pack
end

-- Solo para pruebas y vistas previas (módulo de servidor: ningún cliente puede llamarlo).
-- Crea un sobre concreto en un hueco del nido (sustituye al que hubiera) o, con `at`, suelto en ese punto
-- (at.Y = altura del suelo; `face` = hacia dónde mira su cara, opcional).
function Packs.debugSpawn(zoneIndex, spotIndex, rarity, kg, dawn, at, face)
	if not at then
		for _, other in pairs(Packs.list) do
			if other.zone == zoneIndex and other.spot == spotIndex and other.state == "ground" then
				destroyPack(other)
			end
		end
	end
	local pack = spawnPack(zoneIndex, spotIndex, dawn == true, { rarity = math.clamp(math.floor(rarity or 1), 1, #C.RARITIES), kg = math.max(1, math.floor(kg or 100)) })
	if at then
		pack.state = "loose"
		pack.loosePos = at
		pack.looseDir = face
		placeAtRest(pack)
	end
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
	pack.lucky = nil -- la tirada de suerte es de quien lo lleve a casa
	pack.loosePos = nil
	pack.looseDir = nil
	s.carrying = pack
	pack.prompt.Enabled = false
	local color = G.PackStyle and G.PackStyle.accent(pack.rarity) or C.RARITIES[pack.rarity].color
	Packs.burst(pack.part.Position, color, 40 + pack.rarity * 8)
	-- sube sobre la cabeza con estela y chispas; la columna de luz se atenúa
	carryFx(pack, true)
	dimBeam(pack, true)
	placeCarried(pack, char:FindFirstChild("Head") or hrp, true)
	-- el guardián de la zona de origen despierta y persigue
	local guard = G.World.guardians[pack.zone]
	guard.target = player
	guard.pack = pack
	if pack.rarity >= C.ANNOUNCE_CHAT_FROM then
		G.Net.announce("all", "stoleBig", { player.DisplayName, { rarity = pack.rarity }, { guardian = pack.zone } }, { color = G.Format.hex(C.RARITIES[pack.rarity].color) })
	end
	-- misión "robar": cada sobre cuenta una vez por jugador (soltarlo y cogerlo otra vez no suma)
	pack.stolenBy = pack.stolenBy or {}
	if G.Quests and not pack.stolenBy[player.UserId] then
		pack.stolenBy[player.UserId] = true
		G.Quests.event(player, "steal", 1)
	end
end

-- La suerte propia (pase Suerte x2 o boost de las misiones) puede mejorar el sobre al llegar a casa:
-- 12 % con suerte x2, 24 % con x4… (máximo 40 %) y solo hasta la rareza más alta de su zona.
-- roll = número de 0 a 1 para las pruebas (si no, al azar).
function Packs.luckUpgrade(player, zoneIndex, item, roll)
	local luck = G.Core.personalLuck(player)
	local zone = C.ZONES[zoneIndex]
	if luck <= 1 or not zone then
		return false
	end
	local maxR = 0
	for r in pairs(zone.weights) do
		maxR = math.max(maxR, r)
	end
	if item.r >= maxR then
		return false
	end
	if (roll or math.random()) < math.min(0.4, 0.12 * math.log(luck, 2)) then
		item.r += 1
		item.rem = C.RARITIES[item.r].open
		return true
	end
	return false
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
	pack.prompt.Enabled = true
	carryFx(pack, false)
	dimBeam(pack, false)
	if loose and at then
		-- se queda quieto donde cayó
		pack.state = "loose"
		local floorY = floorAt(at, player.Character)
		pack.loosePos = Vector3.new(at.X, math.max(floorY, nestFloorAt(at) or floorY), at.Z)
		placeAtRest(pack)
	else
		returnHome(pack)
	end
	return pack
end

local function deliver(player, pack)
	local s = G.Core.sessions[player]
	local item = { r = pack.rarity, rem = C.RARITIES[pack.rarity].open, dawn = pack.dawn == true, kg = pack.kg }
	-- se tira la suerte una sola vez por sobre (si no cabe y se reintenta, no se vuelve a tirar)
	if pack.lucky == nil then
		pack.lucky = Packs.luckUpgrade(player, pack.zone, item) and item.r or false
	elseif pack.lucky then
		item.r, item.rem = pack.lucky, C.RARITIES[pack.lucky].open
	end
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
	if pack.lucky then
		G.Net.toast(player, "luckUpgrade", { rarity = pack.lucky })
	end
	destroyPack(pack)
	if G.Quests then
		G.Quests.event(player, "escape", 1)
	end
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
		carryFx(pack, false)
		dimBeam(pack, false)
		setPackVisible(pack, false)
		pendingSave[player] = { pack = pack, untilT = os.clock() + 10 }
		G.Net.Offer:FireClient(player, "savePack")
		task.delay(10.5, function()
			local p = pendingSave[player]
			if p and p.pack == pack then
				pendingSave[player] = nil
				if pack.state == "pending" then
					setPackVisible(pack, true)
					pack.prompt.Enabled = true
					returnHome(pack)
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
	-- tutorial: el sobre ya está en casa (si no, le pediría robar otro con este esperando en el altar)
	if G.Quests then
		G.Quests.packHome(player)
	end
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
	-- mutación (Dorado, Hielo, Diamante, Lava, Arcoíris): más dinero y otro aspecto
	local mut = C.rollMutation()
	local isNew = G.Core.addGod(player, god, kg, mut)
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
	G.Net.Reveal:FireClient(player, { god = god.id, isNew = isNew, kg = kg, mut = mut })
	-- las mutaciones más raras se anuncian a todo el servidor
	local mdef = mut and C.MUTATION_BY_ID[mut]
	if mdef and mdef.mult >= 6 then
		G.Net.announce("all", "gotMutation", { player.DisplayName, { mutation = mut }, { god = god.id } }, { color = G.Format.hex(mdef.color) })
	end
	if G.Quests then
		G.Quests.event(player, "open", 1)
	end
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
-- Bucle: guardianes, entregas, sobres que alguien lleva, pasillo
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

-- Sobres en cada fotograma: solo se mueven los que alguien lleva. Los del suelo descansan quietos
-- (se colocan una vez al aparecer, al soltarlos o al volver), así no generan tráfico de red.
function Packs.stepPacks()
	for _, pack in pairs(Packs.list) do
		if pack.state == "carried" and pack.carrier then
			local char = pack.carrier.Character
			local head = char and (char:FindFirstChild("Head") or char:FindFirstChild("HumanoidRootPart"))
			if head then
				placeCarried(pack, head, false)
			end
			-- ¿ha llegado a su parcela?
			local s = G.Core.sessions[pack.carrier]
			if s and s.plot and char and char:FindFirstChild("HumanoidRootPart") then
				local hp = char.HumanoidRootPart.Position
				if G.World.inPlot(s.plot, hp) then
					deliver(pack.carrier, pack)
				end
			end
		end
	end
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
		Packs.stepPacks()
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
	-- nidos: los seis sobres de cada zona aparecen juntos (uno en el centro y cinco alrededor)
	local PS = G.PackStyle
	if PS and PS.init then
		PS.init(G)
	end
	for i = 1, #C.ZONES do
		local zp = G.World.zoneParts[i]
		if zp then
			local centre = Packs.nestCentre(i)
			zp.nest = centre
			if PS then
				zp.spots = PS.spots(centre)
				PS.buildNest(i, centre)
			else
				zp.spots = { centre }
				for j = 0, C.PACKS_PER_ZONE - 2 do
					local a = math.rad(-54 + j * 360 / (C.PACKS_PER_ZONE - 1))
					table.insert(zp.spots, centre + Vector3.new(math.cos(a), 0, math.sin(a)) * C.NEST_RADIUS)
				end
			end
		end
	end
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
