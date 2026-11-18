-- Núcleo: parcelas, velocidad, cinta, dinero, índice, entrenadores, auras, AFK y sincronización
local Players = game:GetService("Players")
local TeleportService = game:GetService("TeleportService")
local RunService = game:GetService("RunService")

local Core = {}
local G
local C

Core.sessions = {} -- [player] = estado temporal (no se guarda)

-- Títulos según la mejor velocidad (el cliente los traduce)
Core.TITLES = { 0, 1e3, 5e4, 2e6, 1e8, 5e9, 1e12, 1e15, 1e18, 1e21 }
local function titleIndex(best)
	local idx = 1
	for i, v in ipairs(Core.TITLES) do
		if best >= v then
			idx = i
		end
	end
	return idx
end

local CollectionService = game:GetService("CollectionService")
local function overhead(player, char)
	local head = char:FindFirstChild("Head")
	if not head then
		return
	end
	local old = head:FindFirstChild("Overhead")
	if old then
		old:Destroy()
	end
	local bb = Instance.new("BillboardGui")
	bb.Name = "Overhead"
	bb.Size = UDim2.fromScale(9, 2.6)
	bb.StudsOffset = Vector3.new(0, 3.4, 0)
	bb.MaxDistance = 120
	bb.LightInfluence = 0
	bb:SetAttribute("Overhead", true)
	bb:SetAttribute("Title", 1)
	bb:SetAttribute("Income", 0)
	local l = Instance.new("TextLabel")
	l.Name = "Label"
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.RichText = true
	l.Font = Enum.Font.FredokaOne
	l.TextColor3 = Color3.new(1, 1, 1)
	l.Text = ""
	l.Parent = bb
	bb.Parent = head
	CollectionService:AddTag(bb, "Loc")
end

---------------------------------------------------------------------
-- Multiplicadores
---------------------------------------------------------------------
local function uniqueGods(d)
	local n = 0
	for _, c in pairs(d.gods) do
		if c > 0 then
			n += 1
		end
	end
	return n
end
Core.uniqueGods = uniqueGods

local function mythComplete(d, myth)
	for _, g in ipairs(C.GODS) do
		if g.myth == myth and (d.gods[g.id] or 0) <= 0 then
			return false
		end
	end
	return true
end
Core.mythComplete = mythComplete

-- Borra las cachés cuando cambia algo que afecta a multiplicadores o colección
function Core.invalidate(player)
	local s = Core.sessions[player]
	if s then
		s.mcT = nil
		s.placed = nil
	end
end

function Core.mults(player)
	local d = G.Data.profiles[player]
	local s = Core.sessions[player]
	if not d or not s then
		return 1, 1, 1
	end
	local now = os.clock()
	if s.mcT and now - s.mcT < 0.5 then
		return s.mc[1], s.mc[2], s.mc[3]
	end
	local a, b, c = Core.computeMults(player, d, s)
	s.mc = { a, b, c }
	s.mcT = now
	return a, b, c
end

function Core.computeMults(player, d, s)
	local speedAdd, moneyAdd, speedMul, moneyMul = 0, 0, 1, 1
	local n = uniqueGods(d)
	for _, rw in ipairs(C.INDEX_REWARDS) do
		if n >= rw.count then
			speedAdd += rw.speed or 0
			moneyAdd += rw.money or 0
			speedMul *= rw.speedMult or 1
			moneyMul *= rw.moneyMult or 1
		end
	end
	for key, myth in pairs(C.MYTHS) do
		if mythComplete(d, key) then
			speedAdd += myth.bonus
			moneyAdd += myth.bonus
		end
	end
	-- entrenadores: los 3 mejores
	local list = {}
	for key, count in pairs(d.coaches) do
		if count > 0 then
			local id, tier = key:match("^(%w+):(%d+)$")
			tier = tonumber(tier)
			for _, co in ipairs(C.COACHES) do
				if co.id == id and tier and C.COACH_TIERS[tier] then
					for _ = 1, math.min(count, C.COACH_EQUIP) do
						table.insert(list, co.bonus * C.COACH_TIERS[tier].mult)
					end
				end
			end
		end
	end
	table.sort(list, function(a, b)
		return a > b
	end)
	for k = 1, math.min(C.COACH_EQUIP, #list) do
		speedAdd += list[k]
	end
	local aura = d.aura and C.AURA_BY_ID[d.aura]
	if aura then
		speedAdd += aura.speed or 0
		moneyAdd += aura.money or 0
	end
	if s.passes.vip then
		speedAdd += 0.1
		moneyAdd += 0.1
	end
	if s.passes.speed2x then
		speedMul *= 2
	end
	if s.passes.money2x then
		moneyMul *= 2
	end
	if os.time() < (d.boosts and d.boosts.speed or 0) then
		speedMul *= 3
	end
	-- suerte que se muestra: la tuya (pase y premio) por la del servidor (compra de Suerte x3)
	local luck = Core.personalLuck(player, d, s)
	if os.clock() < (G.serverLuckUntil or 0) then
		luck *= 3
	end
	return (1 + speedAdd) * speedMul, (1 + moneyAdd) * moneyMul, luck
end

-- Tu suerte propia: pase Suerte x2 y boost de suerte (premio de misiones y racha).
-- Mejora los sobres que llevas a casa (Packs.luckUpgrade) y los sobres de premio.
function Core.personalLuck(player, d, s)
	d = d or G.Data.profiles[player]
	s = s or Core.sessions[player]
	local luck = 1
	if s and s.passes and s.passes.luck2x then
		luck *= 2
	end
	if d and d.boosts and os.time() < (d.boosts.luck or 0) then
		luck *= C.QUESTS.LUCK_BOOST
	end
	return luck
end

---------------------------------------------------------------------
-- Dioses colocados e ingresos
---------------------------------------------------------------------
function Core.pedestalCount(player)
	local d = G.Data.profiles[player]
	local s = Core.sessions[player]
	if not d then
		return 0
	end
	return C.pedestalsFor(d.plot) + ((s and s.passes.moreSlots) and 5 or 0)
end

function Core.altarCount(player)
	local d = G.Data.profiles[player]
	local s = Core.sessions[player]
	if not d then
		return 0
	end
	return d.altars + ((s and s.passes.moreSlots) and 2 or 0)
end

-- Los mejores dioses (por ingresos, contando los kilos) que caben en la parcela
function Core.placedGods(player)
	local s = Core.sessions[player]
	if s and s.placed then
		return s.placed
	end
	local placed = Core.computePlaced(player)
	if s then
		s.placed = placed
	end
	return placed
end

function Core.computePlaced(player)
	local d = G.Data.profiles[player]
	local all = {}
	for _, e in ipairs(d.godList or {}) do
		local g = C.GOD_BY_ID[e.id]
		if g then
			table.insert(all, { god = g, kg = e.kg or 100, mut = e.mut, value = C.RARITIES[g.r].income * C.kgMult(e.kg) * C.mutMult(e.mut) })
		end
	end
	table.sort(all, function(x, y)
		if x.value ~= y.value then
			return x.value > y.value
		end
		return x.god.index < y.god.index
	end)
	local n = Core.pedestalCount(player)
	local placed = {}
	for i = 1, math.min(n, #all) do
		placed[i] = all[i]
	end
	return placed
end

function Core.income(player)
	local _, moneyMult = Core.mults(player)
	local sum = 0
	for _, e in ipairs(Core.placedGods(player)) do
		sum += e.value
	end
	return sum * moneyMult
end

function Core.refreshPlot(player)
	Core.invalidate(player)
	local s = Core.sessions[player]
	local d = G.Data.profiles[player]
	if not s or not d or not s.plot then
		return
	end
	local plot = s.plot
	local count = Core.pedestalCount(player)
	G.World.pedestalVisible(plot, count)
	G.World.altarVisible(plot, Core.altarCount(player))
	local placed = Core.placedGods(player)
	for i = 1, #plot.pedestals do
		G.World.setStatue(plot, i, i <= count and placed[i] or nil)
	end
	if s.plotStyled ~= d.plot then
		s.plotStyled = d.plot
		G.World.styleplot(plot, d.plot)
	end
	plot.signGui.Label.Text = string.format("<b>%s</b>\n%s %d", player.DisplayName, "⭐", d.plot)
end

---------------------------------------------------------------------
-- Dinero
---------------------------------------------------------------------
function Core.addMoney(player, amount)
	local d = G.Data.profiles[player]
	if not d then
		return
	end
	d.money += amount
	d.totalMoney += amount
end

function Core.spend(player, amount)
	local d = G.Data.profiles[player]
	if not d or d.money < amount then
		G.Net.toast(player, "notEnough")
		return false
	end
	d.money -= amount
	return true
end

---------------------------------------------------------------------
-- Índice y armas
---------------------------------------------------------------------
function Core.bestWeapon(d)
	local best, order = "bat", 0
	for key, myth in pairs(C.MYTHS) do
		local w = C.WEAPONS[myth.weapon]
		if w and w.order > order and mythComplete(d, key) then
			best, order = myth.weapon, w.order
		end
	end
	return best
end

function Core.addGod(player, god, kg, mut)
	local d = G.Data.profiles[player]
	local isNew = (d.gods[god.id] or 0) == 0
	d.gods[god.id] = (d.gods[god.id] or 0) + 1
	if mut and not C.MUTATION_BY_ID[mut] then
		mut = nil
	end
	table.insert(d.godList, { id = god.id, kg = kg or 100, mut = mut })
	G.Data.trimGodList(d, C)
	Core.invalidate(player)
	if isNew and G.Quests then
		G.Quests.event(player, "newgod", 1)
	end
	if isNew then
		local w = Core.bestWeapon(d)
		if w ~= d.weapon then
			d.weapon = w
			for key, myth in pairs(C.MYTHS) do
				if myth.weapon == w then
					G.Net.announce(player, "weaponUnlocked", { { myth = key }, { weapon = w } }, { color = "#FFD23F", big = true })
				end
			end
			G.Combat.giveWeapon(player)
		end
	end
	Core.refreshPlot(player)
	return isNew
end

---------------------------------------------------------------------
-- Acciones del cliente
---------------------------------------------------------------------
local actions = {}
Core.actions = actions

function actions.buyTreadmill(player)
	local d = G.Data.profiles[player]
	if d.treadmill >= C.TREADMILL_MAX then
		return
	end
	if Core.spend(player, C.treadmillCost(d.treadmill + 1)) then
		d.treadmill += 1
		G.Net.toast(player, "bought")
	end
end

function actions.buyPlot(player)
	local d = G.Data.profiles[player]
	if d.plot >= C.PLOT_MAX then
		return
	end
	if Core.spend(player, C.plotCost(d.plot + 1)) then
		d.plot += 1
		Core.refreshPlot(player)
		G.Net.toast(player, "bought")
	end
end

function actions.buyAltar(player)
	local d = G.Data.profiles[player]
	if d.altars >= C.ALTARS_MAX then
		return
	end
	if Core.spend(player, C.altarCost(d.altars + 1)) then
		d.altars += 1
		Core.refreshPlot(player)
		G.Net.toast(player, "bought")
	end
end

function actions.buyCoach(player, id)
	local d = G.Data.profiles[player]
	for _, co in ipairs(C.COACHES) do
		if co.id == id then
			if Core.spend(player, co.cost) then
				local key = id .. ":1"
				d.coaches[key] = (d.coaches[key] or 0) + 1
				G.Net.toast(player, "bought")
			end
			return
		end
	end
end

function actions.fuseCoach(player, id, tier)
	local d = G.Data.profiles[player]
	tier = tonumber(tier)
	if type(id) ~= "string" or not tier or tier >= #C.COACH_TIERS then
		return
	end
	local key = id .. ":" .. tier
	if (d.coaches[key] or 0) >= 2 then
		d.coaches[key] -= 2
		local up = id .. ":" .. (tier + 1)
		d.coaches[up] = (d.coaches[up] or 0) + 1
		G.Net.toast(player, "bought")
	end
end

function actions.buyAura(player, id)
	local d = G.Data.profiles[player]
	local a = C.AURA_BY_ID[id]
	if not a or d.auras[id] then
		return
	end
	if Core.spend(player, a.cost) then
		d.auras[id] = true
		d.aura = id
		Core.applyAura(player)
		G.Net.toast(player, "bought")
	end
end

function actions.equipAura(player, id)
	local d = G.Data.profiles[player]
	if d.auras[id] then
		d.aura = id
		Core.applyAura(player)
	end
end

function actions.dropPack(player)
	local s = Core.sessions[player]
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if s and s.carrying and hrp then
		G.Packs.dropCarried(player, true, hrp.Position)
	end
end

function actions.claimOffline(player)
	local s = Core.sessions[player]
	if s and s.offline and s.offline > 0 then
		Core.addMoney(player, s.offline)
		s.offline = 0
		G.Net.toast(player, "bought")
	end
end

function actions.settings(player, tbl)
	local d = G.Data.profiles[player]
	if type(tbl) ~= "table" then
		return
	end
	local s = {}
	for _, k in ipairs({ "sfx", "music", "particles", "shake", "othersAuras" }) do
		s[k] = tbl[k] ~= false
	end
	s.ui = math.clamp(tonumber(tbl.ui) or 2, 1, 3)
	s.ownerPasses = tbl.ownerPasses == true
	local changed = (d.settings and d.settings.ownerPasses) ~= s.ownerPasses
	d.settings = s
	if changed then
		G.Shop.checkPasses(player)
		Core.refreshPlot(player)
	end
end

function actions.leaveTreadmill(player)
	Core.leaveTreadmill(player)
end

function actions.afk(player, on)
	Core.setAfk(player, on == true)
end

function actions.rejoin(player)
	local s = Core.sessions[player]
	if not s or not s.afk or s.rejoining then
		return
	end
	s.rejoining = true
	G.Data.save(player)
	local opts = Instance.new("TeleportOptions")
	opts:SetTeleportData({ afk = true })
	local ok = pcall(function()
		TeleportService:TeleportAsync(game.PlaceId, { player }, opts)
	end)
	if not ok then
		s.rejoining = false
	end
end

---------------------------------------------------------------------
-- Aura visual
---------------------------------------------------------------------
function Core.applyAura(player)
	local d = G.Data.profiles[player]
	local char = player.Character
	if not d or not char then
		return
	end
	local hrp = char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local a = d.aura and C.AURA_BY_ID[d.aura]
	if G.AuraFx then
		G.AuraFx.apply(hrp, a) -- quita el aura anterior y crea la nueva (a puede ser nil)
		return
	end
	local old = hrp:FindFirstChild("AuraFX")
	if old then
		old:Destroy()
	end
	if not a then
		return
	end
	local att = Instance.new("Attachment")
	att.Name = "AuraFX"
	att.Parent = hrp
	local pe = Instance.new("ParticleEmitter")
	pe.Rate = 30
	pe.Lifetime = NumberRange.new(0.6, 1.2)
	pe.Speed = NumberRange.new(2, 5)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Color = ColorSequence.new(a.color)
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8), NumberSequenceKeypoint.new(1, 0) })
	pe.Transparency = NumberSequence.new(0.2, 1)
	pe.Texture = C.VFX.sparkle
	pe.RotSpeed = NumberRange.new(-120, 120)
	pe.Parent = att
	local light = Instance.new("PointLight")
	light.Color = a.color
	light.Range = 10
	light.Brightness = 1.5
	light.Parent = att
end

---------------------------------------------------------------------
-- AFK: te quedas en la cinta entrenando
---------------------------------------------------------------------
function Core.setAfk(player, on)
	local s = Core.sessions[player]
	if not s then
		return
	end
	s.afk = on
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		if on and s.plot then
			if s.carrying then
				G.Packs.dropCarried(player, false)
			end
			s.locked = false
			s.tap = nil
			hrp.CFrame = Core.treadmillCF(s.plot)
			hrp.Anchored = true
		else
			hrp.Anchored = false
			s.leftAt = os.clock()
		end
	end
	G.Net.toast(player, on and "afkOn" or "afkOff")
end

---------------------------------------------------------------------
-- Cinta: al subirte te quedas bloqueado corriendo; para bajar, salta
---------------------------------------------------------------------
-- Postura del corredor encima de la banda (mira hacia el +Z de la cinta: la banda se mueve hacia -Z)
function Core.treadmillCF(plot)
	local t = plot.treadmill
	local dir = t.CFrame:VectorToWorldSpace(Vector3.new(0, 0, 1))
	local pos = t.Position + Vector3.new(0, t.Size.Y / 2 + 3, 0)
	return CFrame.lookAt(pos, pos + dir)
end

local function fireTap(player, payload)
	if typeof(player) == "Instance" then
		G.Net.Tap:FireClient(player, payload)
	end
end

function Core.lockTreadmill(player)
	local s = Core.sessions[player]
	if not s or s.locked or s.afk or not s.plot or s.carrying then
		return false
	end
	s.locked = true
	s.onTreadmill = true
	s.tapHits, s.combo, s.tap = 0, 1, nil
	s.nextTapAt = os.clock() + 1
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp then
		hrp.CFrame = Core.treadmillCF(s.plot)
		hrp.Anchored = true
	end
	return true
end

function Core.leaveTreadmill(player)
	local s = Core.sessions[player]
	if not s then
		return false
	end
	if s.afk then
		Core.setAfk(player, false)
	end
	if not s.locked then
		return false
	end
	s.locked = false
	s.onTreadmill = false
	s.tap = nil
	s.tapHits, s.combo = 0, 1
	s.leftAt = os.clock()
	local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
	if hrp and s.plot then
		-- baja por detrás de la cinta, mirando hacia ella
		local t = s.plot.treadmill
		local dir = t.CFrame:VectorToWorldSpace(Vector3.new(0, 0, 1))
		local pos = t.Position - dir * (t.Size.Z / 2 + 3) + Vector3.new(0, 3, 0)
		hrp.Anchored = false
		hrp.CFrame = CFrame.lookAt(pos, pos + dir)
		hrp.AssemblyLinearVelocity = Vector3.new(0, 25, 0)
	end
	fireTap(player, { lost = false, reset = true })
	return true
end

-- Toques de combo: el servidor decide cuándo y dónde sale cada uno y si se acertó a tiempo
function Core.spawnTap(player)
	local s = Core.sessions[player]
	if not s then
		return nil
	end
	local now = os.clock()
	s.tapId = (s.tapId or 0) + 1
	s.tap = {
		id = s.tapId,
		x = 0.2 + math.random() * 0.6,
		y = 0.24 + math.random() * 0.36, -- hasta 0,6: más abajo pisaría el panel de la cinta en móvil
		born = now,
		expires = now + C.TAP_LIFE,
	}
	s.nextTapAt = now + C.TAP_EVERY[1] + math.random() * (C.TAP_EVERY[2] - C.TAP_EVERY[1])
	fireTap(player, { id = s.tap.id, x = s.tap.x, y = s.tap.y, life = C.TAP_LIFE, hits = s.tapHits or 0, mult = s.combo or 1 })
	return s.tap
end

-- Se llama en cada fotograma: saca toques nuevos y castiga los que caducan sin tocar
function Core.tapTick(player, s, now)
	if not s.locked or s.afk then
		return
	end
	local tap = s.tap
	if tap and now > tap.expires + 0.35 then
		s.tap = nil
		local had = (s.tapHits or 0) > 0
		s.tapHits, s.combo = 0, 1
		fireTap(player, { lost = had, missed = tap.id })
	end
	if not s.tap and now >= (s.nextTapAt or 0) then
		Core.spawnTap(player)
	end
end

---------------------------------------------------------------------
-- Posición en la cinta
---------------------------------------------------------------------
local function onTreadmill(s, hrp)
	if not s.plot or not hrp then
		return false
	end
	local t = s.plot.treadmill
	local rel = t.CFrame:PointToObjectSpace(hrp.Position)
	return math.abs(rel.X) <= t.Size.X / 2 + 0.5 and math.abs(rel.Z) <= t.Size.Z / 2 + 0.5 and rel.Y > 0 and rel.Y < 8
end

---------------------------------------------------------------------
-- Entrada y salida de jugadores
---------------------------------------------------------------------
local function freePlot()
	for _, plot in ipairs(G.World.plots) do
		if not plot.owner then
			return plot
		end
	end
	return nil
end

local function setupLeaderstats(player)
	local ls = Instance.new("Folder")
	ls.Name = "leaderstats"
	for _, n in ipairs({ "⚡", "💰", "⏱️" }) do
		local v = Instance.new("StringValue")
		v.Name = n
		v.Value = "0"
		v.Parent = ls
	end
	ls.Parent = player
end

local function onCharacter(player, char)
	local s = Core.sessions[player]
	local d = G.Data.profiles[player]
	if not s or not d then
		return
	end
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	local hum = char:WaitForChild("Humanoid", 10)
	if not hrp or not hum then
		return
	end
	-- personaje nuevo: ya no está en la cinta
	s.locked, s.onTreadmill, s.tap, s.tapHits, s.combo = false, false, nil, 0, 1
	if s.plot then
		task.wait(0.1)
		hrp.CFrame = s.plot.spawnCF
	end
	hum.WalkSpeed = C.walkSpeedFor(d.speed)
	hum.Died:Connect(function()
		if s.carrying then
			G.Packs.dropCarried(player, false)
		end
	end)
	Core.applyAura(player)
	overhead(player, char)
	G.Combat.giveWeapon(player)
	if s.afk then
		task.wait(0.5)
		Core.setAfk(player, true)
	end
end

local function onJoin(player)
	local d, status = G.Data.load(player, C)
	if not player.Parent then
		-- salió mientras se cargaba: liberar sin guardar nada
		G.Data.discard(player)
		return
	end
	if not d then
		-- NUNCA se juega con una partida vacía si falló la lectura: se le pide volver a entrar
		player:Kick("⚠️ No se pudo cargar tu partida de forma segura. Vuelve a entrar en un momento.\nYour data could not be loaded safely. Please rejoin in a moment. (" .. tostring(status) .. ")")
		return
	end
	local s = {
		passes = {},
		combo = 1,
		lastTap = 0,
		lastHit = 0,
		invulnUntil = 0,
		shieldUntil = 0,
		speedBoostUntil = 0,
		afk = false,
		joinedAt = os.clock(),
		carrying = nil,
		actionTimes = {},
		locked = false, -- bloqueado corriendo en la cinta
		tapId = 0,
		tapHits = 0,
		nextTapAt = 0,
		leftAt = 0,
	}
	Core.sessions[player] = s
	-- misiones del día y tutorial: antes de cualquier espera, así el primer estado ya los lleva
	if G.Quests then
		local ok, err = pcall(G.Quests.onJoin, player)
		if not ok then
			warn("Misiones al entrar:", err)
		end
	end
	G.Shop.checkPasses(player)
	local plot = freePlot()
	if plot then
		plot.owner = player
		s.plot = plot
		plot.folder:SetAttribute("Owner", player.UserId)
	end
	setupLeaderstats(player)
	task.spawn(function()
		for id in pairs(d.gods) do
			local g = C.GOD_BY_ID[id]
			if g then
				G.Avatars.make(g)
			end
		end
	end)
	Core.refreshPlot(player)
	-- dinero ganado mientras no estabas (50 %, máximo 8 h)
	local away = G.Data.elapsed[player] or 0
	if away >= 60 then
		local amount = math.min(away, 8 * 3600) * Core.income(player) * 0.5
		if amount > 0 then
			s.offline = amount
			task.delay(3, function()
				if player.Parent then
					G.Net.Offer:FireClient(player, "offline", amount, away)
				end
			end)
		end
	end
	-- volver del "rejoin" AFK
	local jd = player:GetJoinData()
	if jd and type(jd.TeleportData) == "table" and jd.TeleportData.afk then
		s.afk = true
	end
	player.CharacterAdded:Connect(function(char)
		onCharacter(player, char)
	end)
	if player.Character then
		task.spawn(onCharacter, player, player.Character)
	end
end

local function onLeave(player)
	local s = Core.sessions[player]
	if s then
		if s.carrying then
			G.Packs.dropCarried(player, false)
		end
		if s.plot then
			for i = 1, #s.plot.pedestals do
				G.World.setStatue(s.plot, i, nil)
			end
			G.World.pedestalVisible(s.plot, 0)
			G.World.altarVisible(s.plot, 0)
			for _, a in ipairs(s.plot.altars) do
				a.prompt.Enabled = false
				a.glow.Transparency = 1
				a.gui.Label.Text = ""
			end
			s.plot.signGui.Label.Text = ""
			s.plot.treadmillGui.Label.Text = ""
			s.plot.owner = nil
			s.plot.folder:SetAttribute("Owner", nil)
		end
	end
	Core.sessions[player] = nil
	G.Data.release(player)
end

---------------------------------------------------------------------
-- Entrada del cliente: siempre validada en el servidor
---------------------------------------------------------------------
Core.ACTION_LIMIT = 12 -- acciones como máximo...
Core.ACTION_WINDOW = 2 -- ...cada 2 segundos

function Core.handleAction(player, name, a, b)
	local s = Core.sessions[player]
	if type(name) ~= "string" or not actions[name] or not s or not G.Data.profiles[player] then
		return false
	end
	local now = os.clock()
	local times = s.actionTimes
	while #times > 0 and now - times[1] > Core.ACTION_WINDOW do
		table.remove(times, 1)
	end
	if #times >= Core.ACTION_LIMIT then
		return false -- demasiadas peticiones: se ignora
	end
	table.insert(times, now)
	local ok, err = pcall(actions[name], player, a, b)
	if not ok then
		warn("Acción con error", name, err)
	end
	Core.invalidate(player)
	Core.sendState(player)
	return ok
end

-- Acierto en un toque de combo: solo vale el toque pendiente, por su id y antes de caducar
-- (con un pequeño margen por el ping)
function Core.handleCombo(player, id)
	local s = Core.sessions[player]
	if not s or not s.locked or s.afk then
		return false
	end
	local tap = s.tap
	-- Pulsar E/R2 sin círculo en pantalla (id 0) es fallar: machacar la tecla a ciegas ya no mantiene el combo.
	-- Margen de 0,3 s tras salir un toque: el cliente aún puede no haberlo recibido.
	if id == 0 then
		if (s.tapHits or 0) > 0 and not (tap and os.clock() - (tap.born or 0) < 0.3) then
			s.tapHits, s.combo = 0, 1
			fireTap(player, { lost = true, empty = true })
		end
		return false
	end
	if not tap or type(id) ~= "number" or id ~= tap.id or os.clock() > tap.expires + 0.35 then
		return false
	end
	s.tap = nil
	s.lastTap = os.clock()
	s.tapHits = (s.tapHits or 0) + 1
	local before = s.combo or 1
	s.combo = math.min(C.COMBO_MAX, C.tapMult(s.tapHits))
	fireTap(player, { hit = id, hits = s.tapHits, mult = s.combo, up = s.combo > before })
	if G.Quests then
		G.Quests.event(player, "combo", 1)
	end
	return true
end

---------------------------------------------------------------------
-- Estado para el cliente
---------------------------------------------------------------------
function Core.sendState(player)
	local d = G.Data.profiles[player]
	local s = Core.sessions[player]
	if not d or not s then
		return
	end
	local speedMult, moneyMult, luck = Core.mults(player)
	local altars = {}
	for i, p in ipairs(d.altarPacks) do
		altars[i] = { r = p.r, rem = p.rem, dawn = p.dawn }
	end
	local chase = nil
	if s.carrying then
		local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
		for _, guard in ipairs(G.World.guardians) do
			if guard.target == player and hrp then
				chase = math.floor((guard.model:GetPivot().Position - hrp.Position).Magnitude)
			end
		end
	end
	-- misiones, racha y tutorial: solo cuando cambian (y cada 5 s por si se perdió un mensaje)
	local quests = nil
	if G.Quests then
		local ok, q = pcall(G.Quests.state, player)
		local sig = ok and G.Quests.signature(q) or nil
		if sig and (sig ~= s.questSig or os.clock() - (s.questAt or 0) > 5) then
			s.questSig, s.questAt = sig, os.clock()
			quests = q
		end
	end
	G.Net.State:FireClient(player, {
		quests = quests,
		luckLeft = math.max(0, (d.boosts.luck or 0) - os.time()),
		spawnLuck = os.clock() < (G.serverLuckUntil or 0) and 3 or 1,
		chase = chase,
		isOwner = s.isOwner,
		settings = d.settings,
		offline = s.offline,
		money = d.money,
		speed = d.speed,
		income = Core.income(player),
		combo = s.combo,
		treadmill = d.treadmill,
		treadmillGain = C.treadmillGain(d.treadmill) * speedMult,
		plot = d.plot,
		pedestals = Core.pedestalCount(player),
		altarsMax = Core.altarCount(player),
		altarsBought = d.altars,
		altarPacks = altars,
		queue = #d.queue,
		gods = d.gods,
		coaches = d.coaches,
		auras = d.auras,
		aura = d.aura,
		weapon = d.weapon,
		passes = s.passes,
		carrying = s.carrying and s.carrying.rarity or nil,
		afk = s.afk,
		night = G.DayNight.isNight(),
		cycleLeft = G.DayNight.timeLeft(),
		speedMult = speedMult,
		moneyMult = moneyMult,
		luck = luck,
		onTreadmill = s.onTreadmill,
		zone = s.zone or 0,
		shieldLeft = math.max(0, (d.boosts.shield or 0) - os.time()),
		boostLeft = math.max(0, (d.boosts.speed or 0) - os.time()),
		tapHits = s.tapHits or 0,
		openTokens = d.openTokens,
		protectedLeft = math.max(0, C.NEWBIE_PROTECTION - d.playtime),
	})
end

---------------------------------------------------------------------
-- Bucle principal
---------------------------------------------------------------------
local function tick(dt)
	local night = G.DayNight.isNight()
	for player, s in pairs(Core.sessions) do
		local d = G.Data.profiles[player]
		if d then
			local char = player.Character
			local hrp = char and char:FindFirstChild("HumanoidRootPart")
			local hum = char and char:FindFirstChildOfClass("Humanoid")
			-- subirse a la cinta te bloquea en ella (para bajar hay que saltar)
			if not s.locked and not s.afk and not s.carrying and onTreadmill(s, hrp)
				and os.clock() - (s.leftAt or 0) > C.TREADMILL_RELOCK then
				Core.lockTreadmill(player)
			end
			s.onTreadmill = s.locked == true
			Core.tapTick(player, s, os.clock())
			local speedMult = Core.mults(player)
			local onBelt = s.locked or s.afk
			if onBelt then
				local combo = s.locked and not s.afk and (s.combo or 1) or 1
				local gain = C.treadmillGain(d.treadmill) * combo * speedMult * (night and C.NIGHT_TREADMILL_MULT or 1)
				d.speed += gain * dt
				if d.speed > d.bestSpeed then
					d.bestSpeed = d.speed
				end
			end
			if hum then
				hum.WalkSpeed = C.walkSpeedFor(d.speed)
			end
			if hrp then
				s.zone = G.World.zoneAt(hrp.Position.Z)
			end
		end
	end
end

local acc, secAcc = 0, 0
function Core.start()
	RunService.Heartbeat:Connect(function(dt)
		tick(dt)
		acc += dt
		secAcc += dt
		if secAcc >= 1 then
			secAcc -= 1
			local night = G.DayNight.isNight()
			for player, s in pairs(Core.sessions) do
				local d = G.Data.profiles[player]
				if d then
					d.playtime += 1
					Core.addMoney(player, Core.income(player))
					G.Packs.tickAltars(player, night and C.NIGHT_OPEN_MULT or 1)
					if G.Quests then
						-- protegido: un fallo en las misiones no debe parar el bucle de todos los jugadores
						local ok, err = pcall(G.Quests.tick, player, s, d)
						if not ok and not s.questWarned then
							s.questWarned = true
							warn("Misiones:", err)
						end
					end
					local ls = player:FindFirstChild("leaderstats")
					if ls then
						ls["⚡"].Value = G.Format.num(d.speed)
						ls["💰"].Value = G.Format.num(d.money)
						ls["⏱️"].Value = G.Format.time(d.playtime)
					end
					local head = player.Character and player.Character:FindFirstChild("Head")
					local bb = head and head:FindFirstChild("Overhead")
					if bb then
						bb:SetAttribute("Title", titleIndex(d.bestSpeed))
						bb:SetAttribute("Income", Core.income(player))
					end
					if s.plot then
						s.plot.treadmillGui.Label.Text = string.format("⚡ +%s/s", G.Format.num(C.treadmillGain(d.treadmill) * Core.mults(player)))
					end
				end
			end
		end
		if acc >= 0.5 then
			acc = 0
			for player in pairs(Core.sessions) do
				Core.sendState(player)
			end
		end
	end)
	-- guardado automático
	task.spawn(function()
		while true do
			task.wait(120)
			for player in pairs(Core.sessions) do
				task.spawn(G.Data.save, player)
			end
		end
	end)
end

function Core.init(g)
	G = g
	C = g.Config
	G.Net.Action.OnServerEvent:Connect(function(player, name, a, b)
		Core.handleAction(player, name, a, b)
	end)
	G.Net.Combo.OnServerEvent:Connect(function(player, id)
		Core.handleCombo(player, tonumber(id))
	end)
	Players.PlayerAdded:Connect(onJoin)
	Players.PlayerRemoving:Connect(onLeave)
	for _, p in ipairs(Players:GetPlayers()) do
		task.spawn(onJoin, p)
	end
	game:BindToClose(function()
		local pending = 0
		for player in pairs(Core.sessions) do
			pending += 1
			task.spawn(function()
				G.Data.release(player)
				pending -= 1
			end)
		end
		local t0 = os.clock()
		while pending > 0 and os.clock() - t0 < 25 do
			task.wait(0.2)
		end
	end)
end

return Core
