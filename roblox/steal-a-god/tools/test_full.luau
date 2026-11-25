-- Arranca el servidor del juego paso a paso y prueba cada sistema
local out = {}
local fails = 0
local function add(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring((select(i, ...)))
	end
	table.insert(out, table.concat(t, " "))
end
local function step(name, fn)
	local ok, err = pcall(fn)
	if ok then
		add("✅", name)
	else
		fails += 1
		add("❌", name, "->", err)
	end
end

local RS = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared = RS:WaitForChild("Shared")
local G = {}
step("Cargar módulos", function()
	G.Config = require(Shared.Config)
	G.Format = require(Shared.Format)
	G.GodModel = require(Shared.GodModel)
	G.Net = require(Server.Net)
	G.Data = require(Server.Data)
	G.World = require(Server.World)
	G.Core = require(Server.Core)
	G.Packs = require(Server.Packs)
	G.Combat = require(Server.Combat)
	G.DayNight = require(Server.DayNight)
	G.Boards = require(Server.Boards)
	G.Shop = require(Server.Shop)
	G.Quests = require(Server.Quests)
	G.serverLuckUntil = 0
	local function optional(name)
		local m = Server:FindFirstChild(name)
		return m and require(m) or nil
	end
	G.AuraFx = optional("AuraFx")
	G.PackStyle = optional("PackStyle")
	G.Vendors = optional("Vendors")
	G.PackTemplates = optional("PackTemplates")
	G.Obby = optional("Obby")
end)
step("Red", function() G.Net.init() end)
step("Avatares", function() G.Avatars = require(Server.Avatars); G.Avatars.init(G) end)
step("Modelos 3D", function() require(Server.Models).load(G.Config); assert(game.ReplicatedStorage.GodTemplates:FindFirstChild("zeus"), "sin zeus"); assert(game.ReplicatedStorage.GodTemplates:FindFirstChild("minotaur"), "sin minotauro") end)
step("Construir mundo", function()
	if G.AuraFx and G.AuraFx.init then G.AuraFx.init(G) end
	if G.PackStyle and G.PackStyle.init then G.PackStyle.init(G) end
	if G.PackTemplates then G.PackTemplates.init(G) end
	G.World.init(G)
	if G.Vendors then G.Vendors.init(G) end
end)
step("Iniciar sistemas", function()
	G.DayNight.init(G)
	G.Combat.init(G)
	G.Packs.init(G)
	G.Shop.init(G)
	G.Boards.init(G)
	G.Core.init(G)
	G.Quests.init(G)
	if G.Obby then G.Obby.init(G) end
end)
step("Amanecer (sobres)", function() G.Packs.refreshAll() end)
add("   Sobres creados:", (function() local n = 0; for _ in pairs(G.Packs.list) do n += 1 end; return n end)())
add("   Parcelas:", #G.World.plots, "Guardianes:", #G.World.guardians, "Zonas:", #G.World.zoneParts)

-- Todos los dioses se construyen bien
step("Construir los 64 dioses", function()
	for _, god in ipairs(G.Config.GODS) do
		local ok, err = pcall(function()
			local m = G.GodModel.build(god, G.Config.RARITIES[god.r].color)
			G.GodModel.decorate(m, G.Config.RARITIES[god.r])
			assert(m.PrimaryPart, "sin PrimaryPart")
			m:ScaleTo(0.8)
			m:Destroy()
		end)
		if not ok then
			error(god.id .. ": " .. tostring(err))
		end
	end
end)

-- Estatuas en una parcela (36 pedestales)
step("Estatuas en parcela", function()
	local plot = G.World.plots[1]
	for i = 1, 36 do
		G.World.setStatue(plot, i, { god = G.Config.GODS[((i - 1) % #G.Config.GODS) + 1], kg = G.Config.rollKg() })
	end
	for lvl = 1, 25, 6 do
		G.World.styleplot(plot, lvl)
	end
	G.World.pedestalVisible(plot, 10)
	G.World.altarVisible(plot, 5)
end)

step("Mutaciones: aspecto del dios mutado en la parcela", function()
	local plot = G.World.plots[2]
	for i, m in ipairs(G.Config.MUTATIONS) do
		G.World.setStatue(plot, i, { god = G.Config.GODS[i * 7], kg = 200, mut = m.id })
	end
	for i, m in ipairs(G.Config.MUTATIONS) do
		local model
		for _, d in ipairs(workspace:GetDescendants()) do
			if d:IsA("Model") and d:GetAttribute("Mutation") == m.id then
				model = d
				break
			end
		end
		assert(model, "sin dios mutado " .. m.id)
		assert(model:FindFirstChild("MutationFX", true), "sin efectos " .. m.id)
		local base = G.Config.RARITIES[G.Config.GODS[i * 7].r].income * G.Config.kgMult(200)
		assert(math.abs(model:GetAttribute("Income") - base * m.mult) < 1e-6, "ingreso sin multiplicar " .. m.id)
		for _, acc in ipairs(model:GetDescendants()) do
			if acc:IsA("BasePart") and acc:FindFirstAncestorOfClass("Accessory") then
				assert(acc.Material ~= Enum.Material.CrackedLava or m.id == "lava", "pintó la ropa")
			end
		end
	end
	for i = 1, #G.Config.MUTATIONS do
		G.World.setStatue(plot, i, nil)
	end
end)

-- Probabilidades: 200.000 tiradas por zona
step("Probabilidades de sobres", function()
	for z = 1, #G.Config.ZONES do
		local counts = {}
		local N = 200000
		for _ = 1, N do
			local r = G.Packs.rollRarity(z, 1)
			counts[r] = (counts[r] or 0) + 1
		end
		local parts = {}
		for r = 1, 14 do
			if counts[r] then
				table.insert(parts, string.format("%s %.2f%%", G.Config.RARITIES[r].es, counts[r] / N * 100))
			end
		end
		add("   Zona", z, table.concat(parts, " · "))
	end
end)

-- Economía: tiempo aproximado para cada zona
step("Economía", function()
	local C = G.Config
	for z, zone in ipairs(C.ZONES) do
		-- nivel de cinta más bajo que alcanza la velocidad del guardián en < 5 min con combo x3
		local need = zone.guardian.speed
		local lvl = 1
		while C.treadmillGain(lvl) * 3 * 300 < need and lvl < C.TREADMILL_MAX do
			lvl += 1
		end
		add(string.format("   Zona %d: guardián %s ⚡ → cinta nivel %d (cuesta %s)", z, G.Format.num(need), lvl, G.Format.num(C.treadmillCost(lvl))))
	end
end)

-- Avatares: los 64 dioses y los 6 guardianes
step("Avatares de los 64 dioses", function()
	local t0 = os.clock()
	for _, god in ipairs(G.Config.GODS) do
		local ok, err = pcall(function()
			local rig = G.Avatars.make(god)
			assert(rig, "no se creó")
			local m = G.GodModel.build(god, Color3.new(1, 1, 1))
			assert(m:FindFirstChildOfClass("Humanoid"), "sin Humanoid")
			G.GodModel.decorate(m, G.Config.RARITIES[god.r])
			m:Destroy()
		end)
		if not ok then
			error(god.id .. ": " .. tostring(err))
		end
	end
	add(string.format("   64 avatares en %.1f s", os.clock() - t0))
	local g1 = G.World.guardians[1].model
	add("   Guardián 1:", g1:GetAttribute("Avatar") and "avatar gigante" or "otro", string.format("altura %.1f", g1:GetExtentsSize().Y))
end)

-- Modelos 3D animados
step("Animación de modelos 3D", function()
	for _, id in ipairs({ "zeus", "thor", "anubis" }) do
		local t = G.GodModel.template(id)
		assert(t, id .. ": sin plantilla 3D")
		local m = t:Clone()
		G.GodModel.decorate(m, G.Config.RARITIES[10])
		m:ScaleTo(1.3)
		m.Parent = workspace
		local legBefore = m.LegL.CFrame
		G.GodModel.animate(m, 1.2, 0.6)
		assert((m.LegL.CFrame.Position - legBefore.Position).Magnitude > 0.01 or m.LegL.CFrame ~= legBefore, id .. ": la pierna no se mueve")
		G.GodModel.animate(m, 0, 0)
		add("   " .. id .. " altura:", string.format("%.1f", m:GetExtentsSize().Y), "piezas:", #m:GetChildren())
		m:Destroy()
	end

end)

-- Kilos: distribución
step("Kilos", function()
	local n, heavy, giant, maxKg = 100000, 0, 0, 0
	for _ = 1, n do
		local kg = G.Config.rollKg()
		if kg >= 200 then heavy += 1 end
		if kg >= 500 then giant += 1 end
		maxKg = math.max(maxKg, kg)
	end
	add(string.format("   ≥200 kg: %.1f%%  ≥500 kg: %.2f%%  máx: %d kg", heavy / n * 100, giant / n * 100, maxKg))
end)

-- Formato de números
step("Formato", function()
	assert(G.Format.num(718.4) == "718")
	assert(G.Format.num(1500) == "1.5K")
	assert(G.Format.num(2.5e15) == "2.5Qa")
	assert(G.Format.num(1.5e5) == "150K", G.Format.num(1.5e5))
	assert(G.Format.num(3e8) == "300M", G.Format.num(3e8))
	assert(G.Format.num(1e3) == "1K", G.Format.num(1e3))
	assert(G.Format.num(2.10e6) == "2.1M", G.Format.num(2.1e6))
end)

-- Guardianes se mueven sin errores
step("Guardianes (simulación)", function()
	for _, guard in ipairs(G.World.guardians) do
		guard.model:PivotTo(CFrame.new(guard.home))
		for ph = 0, 6, 0.5 do
			G.GodModel.animate(guard.model, ph, 0.9)
		end
	end
end)

-- Ciclo día/noche
step("Noche y amanecer", function()
	G.Packs.nightfall()
	G.Packs.refreshAll()
end)


-- Fragmento para tools/test_full.luau (pegar después del paso "Noche y amanecer").
-- Usa las variables que ya existen allí: step, G.
step("Vendedores: santuarios, avisos y carteles", function()
	assert(G.Vendors, "falta el módulo Vendors")
	assert(#G.Vendors.errors == 0, table.concat(G.Vendors.errors, " | "))
	local CS = game:GetService("CollectionService")
	for key, name in pairs({ aura = "VendorAura", coach = "VendorCoach" }) do
		local folder = G.World.getRoot():FindFirstChild(name)
		assert(folder and folder:GetAttribute("VendorPos") == G.Config.VENDORS[key].pos, name)
		local prompts, plates = 0, 0
		for _, p in ipairs(CS:GetTagged("VendorPrompt")) do
			if p:IsDescendantOf(folder) then
				prompts += 1
				assert(p:IsA("ProximityPrompt") and p:GetAttribute("Vendor") == key, "aviso " .. key)
			end
		end
		for _, bb in ipairs(CS:GetTagged("Loc")) do
			if bb:IsDescendantOf(folder) then
				plates += 1
				assert(bb:GetAttribute("Vendor") == key and bb:FindFirstChild("Label"), "cartel " .. key)
			end
		end
		assert(prompts == 1 and plates == 1, key .. ": avisos " .. prompts .. ", carteles " .. plates)
		assert(folder:FindFirstChildWhichIsA("Model"), key .. ": sin dios")
	end
end)

step("Auras: capas en Attachments AuraFX y limpieza", function()
	assert(G.AuraFx, "falta el módulo AuraFx")
	local hrp = Instance.new("Part")
	hrp.Anchored = true
	hrp.Parent = workspace
	for i, aura in ipairs(G.Config.AURAS) do
		G.AuraFx.apply(hrp, aura)
		local rate, n = 0, 0
		for _, d in ipairs(hrp:GetDescendants()) do
			if d:IsA("ParticleEmitter") then
				assert(d.Parent.Name == "AuraFX" and d.Parent.Parent == hrp, aura.id .. ": emisor fuera de AuraFX")
				rate += d.Rate
				n += 1
			end
		end
		assert(n >= 3 and rate <= (i == 1 and 36 or 70), aura.id .. ": " .. n .. " emisores, " .. rate .. " partículas/s")
		assert(hrp:GetAttribute("AuraColor") == aura.color, aura.id .. ": AuraColor")
	end
	G.AuraFx.apply(hrp, nil)
	assert(#hrp:GetChildren() == 0 and hrp:GetAttribute("AuraColor") == nil, "la limpieza deja restos")
	hrp:Destroy()
end)

---------------------------------------------------------------------
-- PRUEBAS DE SEGURIDAD, DATOS Y COMPRAS (jugadores simulados)
---------------------------------------------------------------------
local noop = { FireClient = function() end, FireAllClients = function() end }
G.Net.State, G.Net.Toast, G.Net.Offer, G.Net.Reveal, G.Net.Announce, G.Net.Knock, G.Net.Tap, G.Net.Sfx = noop, noop, noop, noop, noop, noop, noop, noop
local C = G.Config
local function fakePlayer(id)
	local fp = { UserId = id, DisplayName = "Test" .. math.abs(id), Name = "Test" .. math.abs(id), Character = nil }
	G.Data.profiles[fp] = G.Data.sanitize(nil, C)
	G.Core.sessions[fp] = { passes = {}, combo = 1, lastTap = 0, lastHit = 0, invulnUntil = 0, afk = false, joinedAt = os.clock(), actionTimes = {}, locked = false, tapId = 0, tapHits = 0, nextTapAt = 0, leftAt = 0 }
	return fp, G.Data.profiles[fp], G.Core.sessions[fp]
end

step("Validación de datos rotos o manipulados", function()
	local d = G.Data.sanitize({ money = 0 / 0, speed = -5, treadmill = 999, plot = "x", gods = { zeus = 3, fake = 9 }, godList = { { id = "zeus", kg = 1e9 }, { id = "nope" } }, altarPacks = { { r = 99 }, { r = 3, rem = -4 } }, coaches = { ["heracles:1"] = 1e12, bad = 2 }, aura = "noexiste", weapon = "lanzallamas" }, C)
	assert(d.money == 0 and d.speed == 0, "números")
	assert(d.treadmill == C.TREADMILL_MAX and d.plot == 1, "niveles")
	assert(d.gods.zeus == 3 and d.gods.fake == nil, "dioses")
	assert(#d.godList == 1 and d.godList[1].kg == 5000, "lista de dioses")
	assert(#d.altarPacks == 1 and d.altarPacks[1].rem == 0, "altares")
	assert(d.coaches["heracles:1"] == 1e6 and d.coaches.bad == nil, "entrenadores")
	assert(d.aura == nil and d.weapon == "bat", "aura/arma")
end)

step("Guardar, cargar y bloqueo de sesión (DataStore real, clave de prueba)", function()
	G.Data.KEY_PREFIX = "test_" .. os.time() .. "_"
	local fp = { UserId = 777 }
	local d, status = G.Data.load(fp, C)
	assert(d and status == "new", "nuevo: " .. tostring(status))
	d.money = 12345
	assert(G.Data.save(fp), "guardar")
	G.Data.profiles[fp] = nil
	local d2, st2 = G.Data.load(fp, C)
	assert(d2 and st2 == "existing" and d2.money == 12345, "cargar: " .. tostring(st2))
	-- otro servidor se queda la partida: no debemos pisarla
	local store = game:GetService("DataStoreService"):GetDataStore(G.Data.STORE_NAME)
	store:UpdateAsync(G.Data.KEY_PREFIX .. 777, function(old)
		old._lock = { job = "otro-servidor", t = os.time() }
		old.money = 999
		return old
	end)
	d2.money = 1
	assert(G.Data.save(fp) == false, "debe negarse a guardar sin el bloqueo")
	local raw = store:GetAsync(G.Data.KEY_PREFIX .. 777)
	assert(raw.money == 999, "no debe haber pisado la otra partida")
	store:RemoveAsync(G.Data.KEY_PREFIX .. 777)
	G.Data.profiles[fp] = nil
	G.Data.KEY_PREFIX = "u_"
end)

step("Compras: un recibo repetido no entrega dos veces", function()
	local fp, d = fakePlayer(-101)
	local info = { PlayerId = -101, ProductId = C.PRODUCTS.speedBoost.id, PurchaseId = "recibo-1" }
	local r1 = G.Shop.processReceipt(info, fp)
	local first = d.boosts.speed
	local r2 = G.Shop.processReceipt(info, fp)
	assert(r1 == Enum.ProductPurchaseDecision.PurchaseGranted and r2 == Enum.ProductPurchaseDecision.PurchaseGranted, "decisión")
	assert(d.boosts.speed == first and first > os.time(), "el boost se dio dos veces")
	assert(G.Data.hasReceipt(d, "recibo-1"), "recibo apuntado")
end)

step("Cola llena: nunca se pasa del límite", function()
	local fp, d = fakePlayer(-102)
	for _ = 1, 30 do
		G.Packs.givePack(fp, { r = 1, rem = 10, dawn = false, kg = 100 })
	end
	assert(#d.altarPacks == G.Core.altarCount(fp), "altares")
	assert(#d.queue == C.PACK_QUEUE_MAX, "cola " .. #d.queue)
	assert(G.Packs.savePurchased(fp) == false, "salvar sobre con cola llena debe fallar")
	assert(#d.queue == C.PACK_QUEUE_MAX, "cola tras salvar")
end)

step("Abrir ya: solo su categoría y si no hay, se guarda para después", function()
	local fp, d = fakePlayer(-103)
	G.Packs.givePack(fp, { r = 2, rem = 500, dawn = false, kg = 100 })
	G.Shop.handlers.openNowHigh(fp)
	assert(d.altarPacks[1].rem == 500, "abrió un sobre de otra categoría")
	assert(d.openTokens.high == 1, "no guardó el abrir-ya")
	G.Packs.givePack(fp, { r = 9, rem = 9000, dawn = false, kg = 100 })
	G.Packs.tickAltars(fp, 0)
	assert(d.altarPacks[2].rem == 0 and d.openTokens.high == 0, "no aplicó el abrir-ya pendiente")
	G.Shop.handlers.openNowLow(fp)
	assert(d.altarPacks[1].rem == 0, "no abrió el de su categoría")
end)

step("Mejora de parcela al máximo: compensa en vez de cobrar sin dar nada", function()
	local fp, d = fakePlayer(-104)
	d.plot = C.PLOT_MAX
	local before = d.money
	assert(G.Shop.handlers.instantUpgrade(fp) == true)
	assert(d.plot == C.PLOT_MAX and d.money > before, "sin compensación")
end)

step("Probabilidades mostradas = probabilidades reales", function()
	for _, case in ipairs({ { 1, 1 }, { 4, 1 }, { 6, 1 }, { 6, 3 } }) do
		local z, luck = case[1], case[2]
		local odds = C.odds(z, luck)
		local sum = 0
		for _, p in pairs(odds) do
			sum += p
		end
		assert(math.abs(sum - 1) < 1e-9, "no suman 1")
		local counts, N = {}, 200000
		for _ = 1, N do
			local r = C.rollRarity(z, luck)
			counts[r] = (counts[r] or 0) + 1
		end
		for r, p in pairs(odds) do
			if p > 0.01 then
				local real = (counts[r] or 0) / N
				assert(math.abs(real - p) < 0.01, string.format("zona %d rareza %d: muestra %.3f real %.3f", z, r, p, real))
			end
		end
	end
	-- con mucha suerte, las imposibles aparecen con la frecuencia anunciada
	local o = C.odds(6, 1e6)
	assert(o[10] > 0.85 and o[11] > 0.09, "suerte extrema")
	add(string.format("   Zona 6: Secreta 1/%s (normal) · 1/%s (suerte x3)", G.Format.num(1 / C.odds(6, 1)[10]), G.Format.num(1 / C.odds(6, 3)[10])))
end)

step("Límite de peticiones: un tramposo no puede spamear acciones", function()
	local fp = fakePlayer(-105)
	local accepted = 0
	for _ = 1, 40 do
		if G.Core.handleAction(fp, "settings", { sfx = true }) then
			accepted += 1
		end
	end
	assert(accepted == G.Core.ACTION_LIMIT, "aceptadas " .. accepted)
	assert(G.Core.handleAction(fp, "noexiste") == false, "acción inventada")
end)

step("Combo: toques en pantalla decididos por el servidor (x2, x3, x4, x5)", function()
	local fp, _, s = fakePlayer(-106)
	-- fuera de la cinta no cuenta nada
	assert(G.Core.handleCombo(fp, 1) == false, "aceptó combo fuera de la cinta")
	s.locked, s.onTreadmill = true, true
	local tap = G.Core.spawnTap(fp)
	assert(tap and tap.x >= 0.2 and tap.x <= 0.8 and tap.y >= 0.24 and tap.y <= 0.68, "toque fuera de la zona segura")
	assert(G.Core.handleCombo(fp, tap.id + 1) == false, "aceptó un toque que no existe")
	assert(G.Core.handleCombo(fp, tap.id) == true and s.combo == 2 and s.tapHits == 1, "el primer toque debe dar x2")
	assert(G.Core.handleCombo(fp, tap.id) == false, "aceptó el mismo toque dos veces")
	local expect = { [5] = 3, [15] = 4, [30] = 5, [45] = 5 }
	for n = 2, 45 do
		local t2 = G.Core.spawnTap(fp)
		assert(G.Core.handleCombo(fp, t2.id), "toque " .. n)
		if expect[n] then
			assert(s.combo == expect[n], "toque " .. n .. ": x" .. s.combo)
		end
	end
	-- un toque caducado sin tocar hace perder el combo
	local late = G.Core.spawnTap(fp)
	late.expires = os.clock() - 1
	G.Core.tapTick(fp, s, os.clock())
	assert(s.combo == 1 and s.tapHits == 0, "no se perdió el combo al caducar")
	assert(G.Core.handleCombo(fp, late.id) == false, "aceptó un toque caducado")
	-- en AFK no hay toques
	s.afk = true
	assert(G.Core.handleCombo(fp, (G.Core.spawnTap(fp)).id) == false, "aceptó toques en AFK")
	s.afk = false
	-- pulsar E/R2 sin círculo (id 0) hace perder el combo; justo al salir un toque hay 0,3 s de margen
	s.tap = nil
	G.Core.handleCombo(fp, G.Core.spawnTap(fp).id)
	G.Core.handleCombo(fp, G.Core.spawnTap(fp).id)
	assert(s.tapHits == 2, "no sumó antes del fallo")
	local fresh = G.Core.spawnTap(fp)
	G.Core.handleCombo(fp, 0)
	assert(s.tapHits == 2, "castigó un toque recién salido")
	fresh.born = os.clock() - 1
	G.Core.handleCombo(fp, 0)
	assert(s.tapHits == 0 and s.combo == 1, "machacar sin círculo mantuvo el combo")
	for _ = 1, 200 do
		local tp = G.Core.spawnTap(fp)
		assert(tp.y >= 0.24 and tp.y <= 0.6 and tp.x >= 0.2 and tp.x <= 0.8, "toque fuera de la zona")
	end
	-- bajar de la cinta lo reinicia todo
	G.Core.spawnTap(fp)
	G.Core.handleCombo(fp, s.tap.id)
	assert(G.Core.leaveTreadmill(fp) == true and not s.locked and s.combo == 1 and s.tapHits == 0 and s.tap == nil, "bajar de la cinta")
	assert(G.Core.leaveTreadmill(fp) == false, "bajar dos veces")
end)

step("Golpe del jefe: te lanza volando hacia atrás sin salir del pasillo", function()
	local fp, _, s = fakePlayer(-121)
	local W = C.CORRIDOR_HALF_WIDTH
	for _, x in ipairs({ -W + 2, -30, 0, 25, W - 2 }) do
		for _, z in ipairs({ C.CORRIDOR_START + 20, C.CORRIDOR_START + 500 }) do
			local pos = Vector3.new(x, 5, z)
			for _, side in ipairs({ -1, 1 }) do
				s.invulnUntil = 0
				local vel, T = G.Packs.launch(fp, pos + Vector3.new(side * 6, 0, 4), pos)
				local land = pos + Vector3.new(vel.X, 0, vel.Z) * T
				assert(math.abs(land.X) <= W - 7.9, string.format("sale por el lado: x=%.1f", land.X))
				assert(land.Z < pos.Z - 40, "no vuela hacia atrás")
				local apex = vel.Y * vel.Y / (2 * workspace.Gravity)
				assert(apex > 15 and apex < 60, string.format("altura rara: %.1f", apex))
				assert(s.invulnUntil > os.clock() + T, "sin invulnerabilidad al aterrizar")
			end
		end
	end
end)

step("Apertura 3D: un sobre de muestra por rareza y columna de luz en el altar", function()
	local folder = game.ReplicatedStorage:FindFirstChild("PackTemplates")
	assert(folder, "sin PackTemplates")
	local CS = game:GetService("CollectionService")
	local counts = {}
	for r = 1, #C.RARITIES do
		local m = folder:FindFirstChild("R" .. r)
		assert(m and m:IsA("Model") and m.PrimaryPart, "falta la muestra de la rareza " .. r)
		local n = 0
		for _, d in ipairs(m:GetDescendants()) do
			assert(not (d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Light") or d:IsA("LayerCollector") or d:IsA("ProximityPrompt") or d:IsA("Script")), "muestra " .. r .. " con " .. d.ClassName)
			assert(#CS:GetTags(d) == 0, "muestra " .. r .. " con etiquetas: " .. d:GetFullName())
			if d:IsA("BasePart") then
				assert(d.Anchored, "pieza suelta en la muestra " .. r)
				n += 1
			end
		end
		local _, size = m:GetBoundingBox()
		assert(size.Magnitude < 20, "muestra " .. r .. " demasiado grande")
		counts[#counts + 1] = r .. ":" .. n
	end
	add("   piezas por muestra: " .. table.concat(counts, " "))
	-- abrir en el altar: columna de luz y onda de choque que se limpian solas
	local fp, d, s = fakePlayer(-125)
	local plot = G.World.plots[3]
	s.plot = plot
	table.insert(d.altarPacks, { r = 8, rem = 0, dawn = false, kg = 100, luck = 50 })
	G.Packs.openAltar(fp, 1)
	task.wait(0.1)
	assert(workspace:FindFirstChild("OpenPillar") and workspace:FindFirstChild("Shockwave"), "sin columna de luz u onda")
	task.wait(1.6)
	assert(not workspace:FindFirstChild("OpenPillar") and not workspace:FindFirstChild("Shockwave"), "la columna de luz no se limpia")
	s.plot = nil
end)

step("Música y gritos: pistas subidas, un grito por guardián y la línea segura", function()
	for _, k in ipairs({ "chase", "bgm", "shouts", "hit" }) do
		assert(type(C.SOUNDS[k]) == "string" and C.SOUNDS[k]:match("^rbxassetid://%d+$"), "falta el audio " .. k)
	end
	local slots = {}
	for zi, zone in ipairs(C.ZONES) do
		local sh = C.SHOUTS[zone.guardian.kind]
		assert(sh, "el guardián de la zona " .. zi .. " no tiene grito")
		assert(not slots[sh.slot] and sh.len > 0.5 and sh.len < C.SHOUT_SLOT, "hueco del grito " .. zone.guardian.kind)
		slots[sh.slot] = true
	end
	assert(C.SAFE_Z == G.World.SAFE_Z, "la línea segura del cliente y la del servidor no coinciden")
	-- la música de persecución solo con el sobre y al otro lado de la línea
	local Music = require(game:GetService("StarterPlayer").StarterPlayerScripts.Client.Music)
	local fakeChar = { FindFirstChild = function(_, n) return n == "HumanoidRootPart" and { Position = Vector3.new(0, 5, C.SAFE_Z + 50) } or nil end }
	local who = { Character = fakeChar }
	assert(Music.inDanger({ carrying = 3 }, who, C) == true, "en el pasillo con sobre: peligro")
	fakeChar.FindFirstChild = function(_, n) return n == "HumanoidRootPart" and { Position = Vector3.new(0, 5, C.SAFE_Z - 5) } or nil end
	assert(Music.inDanger({ carrying = 3 }, who, C) == false, "en la plaza ya no hay persecución")
	assert(Music.inDanger({ carrying = nil }, who, C) == false, "sin sobre no hay persecución")
end)

step("Suerte de cada sobre: según zona, rareza y amanecer", function()
	for zi, zone in ipairs(C.ZONES) do
		local base = C.PACK_LUCK.zoneBase[zi]
		local minR = C.zoneMinRarity(zi)
		for r in pairs(zone.weights) do
			local k = base * (1 + C.PACK_LUCK.perTier * (r - minR))
			for _ = 1, 100 do
				local l = C.packLuck(zi, r, false)
				assert(l == math.floor(l) and l >= 1, "suerte no entera")
				assert(l >= math.floor(k * 0.55) and l <= k * 1.6, string.format("zona %d rareza %d: %d fuera de rango", zi, r, l))
			end
		end
	end
	assert(C.packLuck(3, 4, true, function() return 0.5 end) == 3 * C.packLuck(3, 4, false, function() return 0.5 end) or math.abs(C.packLuck(3, 4, true, function() return 0.5 end) - 3 * C.packLuck(3, 4, false, function() return 0.5 end)) <= 3, "amanecer x3")
	assert(C.packLuck(6, 9, false, function() return 1 end) > C.packLuck(1, 1, false, function() return 0 end) * 1000, "las zonas lejanas no traen más suerte")
	add(string.format("   Ejemplos: zona 1 común x%d · zona 3 épica x%d · zona 6 primordial al amanecer x%s", C.packLuck(1, 1, false), C.packLuck(3, 4, false), G.Format.group(C.packLuck(6, 9, true))))
	-- el sobre del mundo lleva su suerte en el cartel
	local pack = G.Packs.debugSpawn(2, 1, 3, 100)
	assert(pack.luck and pack.luck >= 1, "el sobre no tiene suerte")
	local bb = pack.part:FindFirstChildWhichIsA("BillboardGui", true)
	assert(bb and bb:GetAttribute("Luck") == pack.luck, "el cartel del sobre no muestra la suerte")
end)

step("Suerte al abrir: el sobre puede subir de rareza (nunca pasa de Primordial)", function()
	assert(C.upgradeChance(1) == 0 and C.upgradeChance(0) == 0, "sin suerte no sube")
	local last = 0
	for e = 1, 12 do
		local c = C.upgradeChance(10 ^ e)
		assert(c >= last and c <= C.UPGRADE.cap, "la probabilidad no crece o pasa del tope")
		last = c
	end
	assert(C.upgradeChance(1e300) == C.UPGRADE.cap, "tope")
	local always, never = function() return 0 end, function() return 0.999 end
	assert(C.rollUpgrade(1, 1e9, always) == 1 + C.UPGRADE.maxTiers, "más de 4 rarezas")
	assert(C.rollUpgrade(7, 1e9, always) == 9, "pasó de Primordial")
	assert(C.rollUpgrade(9, 1e9, always) == 9 and C.rollUpgrade(10, 1e9, always) == 10 and C.rollUpgrade(14, 1e9, always) == 14, "cambió un sobre de rareza 10+")
	assert(C.rollUpgrade(3, 1e9, never) == 3, "subió sin acertar")
	-- reparto real: con T = 100.000 la probabilidad por paso es 9 %
	local N, up = 20000, 0
	for _ = 1, N do
		if C.rollUpgrade(1, 1e5) > 1 then
			up += 1
		end
	end
	assert(math.abs(up / N - C.upgradeChance(1e5)) < 0.012, string.format("reparto raro: %.3f", up / N))
	add(string.format("   Subir de rareza por paso: x12 → %.1f %% · x5.000 → %.1f %% · x1M → %.1f %% · x1M con suerte nivel 30 → %.1f %%", C.upgradeChance(12) * 100, C.upgradeChance(5000) * 100, C.upgradeChance(1e6) * 100, C.upgradeChance(1e6 * C.luckMult(C.LUCK_MAX)) * 100))
	-- abrir: sobres antiguos sin suerte abren bien, la suerte viaja al altar y no se abre dos veces
	local fp, d = fakePlayer(-122)
	local reveals = {}
	local saved = G.Net.Reveal
	G.Net.Reveal = { FireClient = function(_, _, data) table.insert(reveals, data) end }
	local ok, err = pcall(function()
		table.insert(d.altarPacks, { r = 2, rem = 0, dawn = false, kg = 100 })
		G.Packs.openAltar(fp, 1)
		G.Packs.openAltar(fp, 1)
		local from, to = G.Packs.rollUpgrade({ r = 2, luck = 1000 }, fp, always)
		assert(from == 2 and to == 6, "rollUpgrade")
		local item = { r = 3, rem = 0, dawn = false, kg = 100, luck = 777 }
		table.insert(d.altarPacks, item)
		G.Packs.openAltar(fp, 1)
	end)
	G.Net.Reveal = saved
	assert(ok, tostring(err))
	assert(#reveals == 2, "se abrió dos veces o ninguna")
	assert(reveals[1].fromR == 2 and reveals[1].toR >= 2 and reveals[1].luck == 1, "sobre antiguo sin suerte")
	assert(reveals[2].fromR == 3 and reveals[2].luck == 777 and C.GOD_BY_ID[reveals[2].god].r == reveals[2].toR, "la rareza final no manda")
	-- se guarda y se limpia
	local dd = G.Data.sanitize({ altarPacks = { { r = 2, rem = 5, luck = 93754 }, { r = 3, rem = 5, luck = -4 }, { r = 3, rem = 5, luck = "x" } }, luckLevel = 999 }, C)
	assert(dd.altarPacks[1].luck == 93754 and dd.altarPacks[2].luck == 1 and dd.altarPacks[3].luck == nil, "guardar la suerte del sobre")
	assert(dd.luckLevel == C.LUCK_MAX and G.Data.sanitize({}, C).luckLevel == 1, "nivel de suerte")
end)

step("Carteles de mejora: suerte en la parcela y cinta delante (solo el dueño)", function()
	local plot = G.World.plots[1]
	assert(plot.luckSign and plot.treadSign, "faltan carteles")
	assert(G.World.inPlot(plot, plot.luckSign.part.Position), "el cartel de suerte no está en la parcela")
	assert(not G.World.inPlot(plot, plot.treadmill.Position), "la cinta sigue dentro de la parcela")
	assert(not G.World.inPlot(plot, plot.treadSign.part.Position), "el cartel de la cinta está dentro")
	local CS = game:GetService("CollectionService")
	assert(CS:HasTag(plot.luckSign.gui, "UpgradeSign") and CS:HasTag(plot.treadSign.prompt, "LocPrompt"), "etiquetas")
	-- la cinta y su cartel no chocan con nada de fuera de su parcela (farolas, bordillo, otras parcelas)
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	for _, pl in ipairs(G.World.plots) do
		params.FilterDescendantsInstances = { pl.folder }
		for _, p in ipairs({ pl.treadmill, pl.treadSign.part }) do
			local box = CFrame.new(p.Position.X, 6, p.Position.Z) * p.CFrame.Rotation
			local hits = workspace:GetPartBoundsInBox(box, Vector3.new(p.Size.X + 3, 9, p.Size.Z + 3), params)
			for _, h in ipairs(hits) do
				assert(not h.CanCollide or h.Transparency >= 1, string.format("parcela %d: %s choca con %s", pl.index, p.Name, h:GetFullName()))
			end
			assert(math.abs(p.Position.X) <= 37, "fuera de la plaza")
		end
	end
	-- dueño: compra desde el cartel; otro jugador no puede
	local fp, d, s = fakePlayer(-123)
	local other = fakePlayer(-124)
	s.plot = plot
	plot.owner = fp
	G.Core.refreshSigns(fp)
	assert(plot.luckSign.gui:GetAttribute("Owner") == fp.UserId and plot.luckSign.gui:GetAttribute("Level") == 1, "cartel sin datos")
	assert(plot.treadSign.gui:GetAttribute("Cost") == C.treadmillCost(2), "precio de la cinta")
	d.money = C.luckCost(2) + C.treadmillCost(2)
	assert(G.Core.useSign(other, plot, "luck") == false and d.luckLevel == 1, "otro jugador mejoró tu suerte")
	G.Core.useSign(fp, plot, "luck")
	assert(d.luckLevel == 2 and plot.luckSign.gui:GetAttribute("Level") == 2, "no subió la suerte")
	G.Core.useSign(fp, plot, "treadmill")
	assert(d.treadmill == 2 and d.money == 0 and plot.treadSign.gui:GetAttribute("Level") == 2, "no subió la cinta")
	d.luckLevel, d.money = C.LUCK_MAX, 1e300
	G.Core.handleAction(fp, "buyLuck")
	assert(d.luckLevel == C.LUCK_MAX and d.money == 1e300, "pasó del máximo")
	-- subir a la cinta nueva: te coloca encima, mirando a lo largo
	local cf = G.Core.treadmillCF(plot)
	local rel = plot.treadmill.CFrame:PointToObjectSpace(cf.Position)
	assert(math.abs(rel.X) < 0.1 and math.abs(rel.Z) < 0.1 and rel.Y > 0, "posición en la cinta")
	plot.owner = nil
	s.plot = nil
end)

step("Regalos gratis por tiempo y bonus de amigos", function()
	local fp, d, s = fakePlayer(-126)
	s.joinedAt = os.clock()
	assert(not G.Core.giftReady(fp, 1), "regalo antes de tiempo")
	local m0 = d.money
	G.Core.handleAction(fp, "claimGift", 1)
	assert(d.money == m0, "cobró un regalo antes de tiempo")
	s.joinedAt = os.clock() - 61 * 60
	for i = 1, #C.GIFTS do
		assert(G.Core.giftReady(fp, i), "regalo " .. i .. " no está listo a los 61 min")
	end
	G.Core.handleAction(fp, "claimGift", 1)
	assert(d.money > m0 and s.gifts[1], "no dio el regalo 1")
	local m1 = d.money
	G.Core.handleAction(fp, "claimGift", 1)
	assert(d.money == m1, "regalo cobrado dos veces")
	for _, bad in ipairs({ 0, 99, 1.5, "x", -1 }) do
		G.Core.handleAction(fp, "claimGift", bad)
	end
	assert(d.money == m1, "regalo con número raro")
	local before = #d.altarPacks + #d.queue
	G.Core.handleAction(fp, "claimGift", 5)
	assert(#d.altarPacks + #d.queue == before + 1 and s.gifts[5], "el regalo 5 no dio el sobre")
	-- amigos: +10 % de dinero por amigo (máximo 5)
	local _, base = G.Core.mults(fp)
	local old = G.Core.friendCount
	G.Core.friendCount = function() return 3 end
	G.Core.invalidate(fp)
	local _, withFriends = G.Core.mults(fp)
	G.Core.friendCount = old
	G.Core.invalidate(fp)
	assert(withFriends > base * 1.05, string.format("el bonus de amigos no suma: %.3f → %.3f", base, withFriends))
	assert(G.Core.friendCount(fp) == 0, "amigos de mentira")
end)

step("Ascenso al Olimpo: isla, 101 puntos de control, 100 etapas variadas y nada que choque", function()
	local O = C.OBBY
	local obby = workspace:FindFirstChild("Obby")
	assert(obby and obby:FindFirstChild("Pads") and obby:FindFirstChild("Stages"), "sin obby")
	for i = 0, O.STAGES do
		assert(obby.Pads:FindFirstChild("CP" .. i), "falta el punto de control " .. i)
	end
	local kinds, parts = {}, 0
	for i = 1, O.STAGES do
		local f = obby.Stages:FindFirstChild("Stage" .. i)
		assert(f and #f:GetChildren() > 0, "etapa vacía " .. i)
		local k = f:GetAttribute("Kind")
		kinds[k] = (kinds[k] or 0) + 1
	end
	for _, k in ipairs(G.Obby.TYPES) do
		assert((kinds[k] or 0) >= 5, "pocas etapas de " .. k .. ": " .. tostring(kinds[k]))
	end
	for _, d in ipairs(obby:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	local CS = game:GetService("CollectionService")
	for _, tag in ipairs({ "ObbyKill", "ObbySpin", "ObbyMove", "ObbySwing", "ObbyVanish", "ObbyPad", "ObbyBelt", "ObbyWind", "ObbyGateSign" }) do
		assert(#CS:GetTagged(tag) > 0, "nada con " .. tag)
	end
	-- ninguna pieza sólida de una etapa se mete en otra etapa ni en la isla
	local params = OverlapParams.new()
	params.FilterType = Enum.RaycastFilterType.Exclude
	local clashes = {}
	for i = 1, O.STAGES do
		local f = obby.Stages["Stage" .. i]
		params.FilterDescendantsInstances = { f, obby.Pads }
		for _, p in ipairs(f:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide then
				for _, h in ipairs(workspace:GetPartsInPart(p, params)) do
					if h.CanCollide and h:IsDescendantOf(obby) then
						table.insert(clashes, string.format("etapa %d %s ↔ %s", i, p.Name, h:GetFullName()))
					end
				end
			end
		end
	end
	assert(#clashes == 0, "choques: " .. table.concat(clashes, " | ", 1, math.min(#clashes, 6)))
	-- el puente de la cima no choca con las columnas del templo
	local island = obby:FindFirstChild("Island")
	local bridge = island and island:FindFirstChild("SummitBridge")
	assert(bridge, "sin puente a la cima")
	local ip = OverlapParams.new()
	ip.FilterType = Enum.RaycastFilterType.Include
	ip.FilterDescendantsInstances = { island }
	for _, h in ipairs(workspace:GetPartsInPart(bridge, ip)) do
		assert(h.Name ~= "SummitColumn" and h.Name ~= "SummitAltar", "el puente choca con " .. h.Name)
	end
	-- el portal y el ranking de la plaza no se meten en nada del mundo
	local portal = obby:FindFirstChild("ObbyPortal")
	assert(portal, "sin portal en la plaza")
	local boards, plazaBoard = {}, nil
	for _, m in ipairs(obby:GetChildren()) do
		if m.Name == "OlympusBoard" then
			table.insert(boards, m)
			if m:GetPivot().Position.Y < 100 then
				plazaBoard = m
			end
		end
	end
	assert(#boards == 2 and plazaBoard, "faltan los rankings del Olimpo")
	params.FilterDescendantsInstances = { obby }
	local plazaStuff = portal:GetDescendants()
	for _, p in ipairs(plazaBoard:GetDescendants()) do
		table.insert(plazaStuff, p)
	end
	-- ni tapan la entrada de ninguna parcela (franja de 26 × 16 delante de su puerta)
	for _, pl in ipairs(G.World.plots) do
		local gate = pl.cf * CFrame.new(0, 6, G.World.PLOT_SIZE / 2 + 8)
		local ip = OverlapParams.new()
		ip.FilterType = Enum.RaycastFilterType.Include
		ip.FilterDescendantsInstances = { portal, plazaBoard }
		assert(#workspace:GetPartBoundsInBox(gate, Vector3.new(26, 10, 16), ip) == 0, "el portal o el ranking tapan la entrada de la parcela " .. pl.index)
	end
	for _, p in ipairs(plazaStuff) do
		if p:IsA("BasePart") and p.CanCollide then
			for _, h in ipairs(workspace:GetPartsInPart(p, params)) do
				assert(not h.CanCollide or h.Name:find("^Plaza"), "el portal choca con " .. h:GetFullName())
			end
		end
	end
	local top = obby.Pads["CP" .. O.STAGES].Position.Y - obby.Pads.CP0.Position.Y
	local counts = {}
	for _, k in ipairs(G.Obby.TYPES) do
		table.insert(counts, k .. " " .. kinds[k])
	end
	add(string.format("   %d piezas · sube %d studs · %s", parts, math.floor(top), table.concat(counts, ", ")))
end)

step("Ascenso al Olimpo: cada etapa se puede pasar saltando (huecos ≤ 9, subidas ≤ 6; más con impulsor o celosía)", function()
	local O = C.OBBY
	local obby = workspace.Obby
	local CS = game:GetService("CollectionService")
	-- puntos de la cara de arriba de una pieza (las que se mueven, en todo su recorrido)
	local function surface(p)
		local pts = {}
		local half = p.Size / 2
		local amp = CS:HasTag(p, "ObbyMove") and (p:GetAttribute("Amp") or 0) or 0
		local base = (CS:HasTag(p, "ObbyMove") and p:GetAttribute("BaseCF")) or p.CFrame
		local n = 4
		for ix = 0, n do
			for iz = 0, n do
				local x = -half.X - amp + (2 * half.X + 2 * amp) * ix / n
				local z = -half.Z + 2 * half.Z * iz / n
				table.insert(pts, (base * CFrame.new(x, half.Y, z)).Position)
			end
		end
		return pts
	end
	local function link(A, B)
		local best, up = math.huge, 0
		for _, a in ipairs(A.pts) do
			for _, b in ipairs(B.pts) do
				local d = Vector2.new(a.X - b.X, a.Z - b.Z).Magnitude
				if d < best then
					best, up = d, b.Y - a.Y
				end
			end
		end
		return best, up
	end
	local bad, worst = {}, 0
	for i = 1, O.STAGES do
		local nodes = {}
		local function addNode(p, kind)
			table.insert(nodes, { part = p, pts = surface(p), kind = kind })
		end
		addNode(obby.Pads["CP" .. (i - 1)], "start")
		for _, p in ipairs(obby.Stages["Stage" .. i]:GetDescendants()) do
			if p:IsA("BasePart") and p.CanCollide and not CS:HasTag(p, "ObbyKill") and p.Name ~= "Arm" then
				addNode(p, p:IsA("TrussPart") and "truss" or (CS:HasTag(p, "ObbyPad") and "pad" or "floor"))
			end
		end
		addNode(obby.Pads["CP" .. i], "goal")
		local reached, queue = { [1] = true }, { 1 }
		while #queue > 0 do
			local a = nodes[table.remove(queue, 1)]
			for j, b in ipairs(nodes) do
				if not reached[j] and b.kind ~= "truss" then
					local gap, up = link(a, b)
					local ok = (up <= 6 and gap <= 9 - math.max(0, up) * 0.5) or (a.kind == "pad" and up <= 16 and gap <= 9)
					if ok then
						reached[j] = true
						table.insert(queue, j)
						worst = math.max(worst, gap)
					end
				elseif not reached[j] and b.kind == "truss" then
					-- celosía: se sube desde cualquier suelo que la toque y lleva a lo que hay en su parte alta
					local gap = link(a, b)
					if gap <= 3 then
						reached[j] = true
						for k, c in ipairs(nodes) do
							local g2 = link(b, c)
							if not reached[k] and g2 <= 3.5 and c.part.Position.Y > b.part.Position.Y then
								reached[k] = true
								table.insert(queue, k)
							end
						end
					end
				end
			end
		end
		if not reached[#nodes] then
			table.insert(bad, i .. " (" .. obby.Stages["Stage" .. i]:GetAttribute("Kind") .. ")")
		end
	end
	add(string.format("   hueco más grande que hay que saltar: %.1f studs", worst))
	assert(#bad == 0, "etapas que no se pueden pasar: " .. table.concat(bad, ", "))
end)

step("Ascenso al Olimpo: comprar Saltar etapa y ranking de récords", function()
	local O = C.OBBY
	local fp, d, s = fakePlayer(-128)
	G.Obby.enter(fp)
	d.obby.stage = 4
	s.obbyRunStart = os.clock()
	local res = G.Shop.processReceipt({ PlayerId = fp.UserId, ProductId = C.PRODUCTS.obbySkip.id, PurchaseId = "skip-1" }, fp)
	assert(res == Enum.ProductPurchaseDecision.PurchaseGranted and d.obby.stage == 5, "no saltó la etapa")
	assert(s.obbyRunStart == nil, "con saltos sigue contando para el récord")
	res = G.Shop.processReceipt({ PlayerId = fp.UserId, ProductId = C.PRODUCTS.obbySkip.id, PurchaseId = "skip-1" }, fp)
	assert(d.obby.stage == 5, "el mismo recibo saltó dos veces")
	d.obby.stage = O.STAGES
	local m0 = d.money
	G.Shop.processReceipt({ PlayerId = fp.UserId, ProductId = C.PRODUCTS.obbySkip.id, PurchaseId = "skip-2" }, fp)
	assert(d.obby.stage == O.STAGES and d.money > m0, "arriba: compensa con dinero")
	G.Obby.leave(fp)
	-- ranking: filas con medallas y aviso si está vacío
	G.Obby.renderBoards({ { name = "Zeus", value = 754 }, { name = "Hera", value = 801 } })
	for _, b in ipairs(G.Obby.boards) do
		local texts = {}
		for _, l in ipairs(b.list:GetChildren()) do
			if l:IsA("TextLabel") then
				table.insert(texts, l.Text)
			end
		end
		assert(#texts == 2 and texts[1]:find("Zeus", 1, true) and texts[1]:find("12:34", 1, true), "filas del ranking: " .. table.concat(texts, " | "))
	end
	G.Obby.renderBoards({})
	add("   producto Saltar etapa: " .. C.PRODUCTS.obbySkip.id .. " (" .. C.PRODUCTS.obbySkip.price .. " R$)")
end)

step("Ascenso al Olimpo: entrar, puntos de control seguidos, premios por tramo y Sobre del Olimpo", function()
	local O = C.OBBY
	local fp, d, s = fakePlayer(-127)
	s.carrying = { rarity = 1 }
	assert(G.Obby.enter(fp) == false and not s.inObby, "entró llevando un sobre")
	s.carrying = nil
	assert(G.Obby.enter(fp) == true and s.inObby, "no entró")
	assert(G.Core.walkSpeed(s, d) == O.WALK, "velocidad dentro del obby")
	assert(G.Obby.reach(fp, 2) == false, "se saltó un punto de control")
	s.obbyLastCp = os.clock() - 5
	assert(G.Obby.reach(fp, 1) == true and d.obby.stage == 1, "no llegó al 1")
	assert(G.Obby.reach(fp, 2) == false, "demasiado deprisa")
	local m0 = d.money
	for i = 2, 10 do
		s.obbyLastCp = os.clock() - 5
		assert(G.Obby.reach(fp, i), "no llegó al " .. i)
	end
	local m1 = d.money
	assert(m1 > m0 and d.obby.secs[1] == true and #d.obby.secs == O.STAGES / O.PER_SECTION - 1, "premio del tramo 1")
	d.obby.stage = 9
	s.obbyLastCp = os.clock() - 5
	G.Obby.reach(fp, 10)
	assert(d.money == m1, "cobró dos veces el tramo 1 el mismo día")
	-- cima: Sobre del Olimpo una vez al día
	assert(G.Obby.finish(fp) == false, "terminó sin llegar arriba")
	d.obby.stage = O.STAGES
	s.obbyRunStart = os.clock() - 600
	local before = #d.altarPacks + #d.queue
	assert(G.Obby.finish(fp) == true, "no terminó")
	assert(#d.altarPacks + #d.queue == before + 1, "sin Sobre del Olimpo")
	local item = d.altarPacks[#d.altarPacks] or d.queue[#d.queue]
	assert(item.luck and item.luck >= O.TOP_PACK_LUCK, "el Sobre del Olimpo no trae suerte")
	assert(d.obby.wins == 1 and d.obby.best >= 599 and d.obby.best <= 601 and d.obby.stage == 0, "récord y reinicio")
	d.obby.stage = O.STAGES
	local m2 = d.money
	G.Obby.finish(fp)
	assert(#d.altarPacks + #d.queue == before + 1 and d.money > m2, "dos Sobres del Olimpo el mismo día")
	-- estado del cliente
	local sent
	local saved = G.Net.State
	G.Net.State = { FireClient = function(_, _, payload) sent = payload end }
	pcall(G.Core.sendState, fp)
	G.Net.State = saved
	assert(sent and sent.obby and sent.obby.on == true and sent.obby.wins == 2 and sent.obby.topToday == true, "estado del obby")
	assert(G.Obby.leave(fp) == true and not s.inObby, "salir")
	-- datos guardados: se limpian y la lista de tramos va seguida
	local dd = G.Data.sanitize({ obby = { stage = 999, wins = -3, best = "x", secs = { [3] = true, [99] = true, foo = true } } }, C)
	assert(dd.obby.stage == O.STAGES and dd.obby.wins == 0 and dd.obby.best == 0, "datos del obby")
	assert(#dd.obby.secs == O.STAGES / O.PER_SECTION - 1 and dd.obby.secs[3] == true and dd.obby.secs[1] == false, "lista de tramos")
	-- los puntos de control y la cima tienen su sitio para aparecer
	assert(G.Obby.spawnCF(0).Position.Y > O.CENTER.Y + O.START_UP and G.Obby.summit, "aparecer")
end)

step("Renacer: pide dinero y velocidad, reinicia lo justo y multiplica para siempre", function()
	local fp, d, s = fakePlayer(-129)
	G.Core.addGod(fp, C.GOD_BY_ID.zeus, 300)
	d.plot, d.altars, d.treadmill, d.luckLevel = 7, 5, 12, 9
	local _, money0 = G.Core.mults(fp)
	local speed0 = G.Core.mults(fp)
	d.money, d.speed = C.rebirthCost(0) - 1, C.rebirthSpeed(0)
	G.Core.handleAction(fp, "rebirth")
	assert(d.rebirths == 0 and d.money == C.rebirthCost(0) - 1, "renació sin dinero suficiente")
	d.money, d.speed = C.rebirthCost(0), C.rebirthSpeed(0) - 1
	G.Core.handleAction(fp, "rebirth")
	assert(d.rebirths == 0, "renació sin velocidad suficiente")
	d.speed = C.rebirthSpeed(0)
	G.Core.handleAction(fp, "rebirth")
	assert(d.rebirths == 1, "no renació")
	assert(d.money == 0 and d.speed == 0 and d.treadmill == 1 and d.luckLevel == 1, "no reinició dinero, velocidad, cinta y suerte")
	assert(d.plot == 7 and d.altars == 5 and d.gods.zeus == 1 and #d.godList >= 1, "perdió dioses, parcela o altares")
	G.Core.invalidate(fp)
	local speed1, money1 = G.Core.mults(fp)
	assert(math.abs(money1 / money0 - C.rebirthMult(1)) < 1e-6 and math.abs(speed1 / speed0 - C.rebirthMult(1)) < 1e-6, "el multiplicador no se aplica")
	-- el siguiente cuesta más; y hay un máximo
	assert(C.rebirthCost(1) > C.rebirthCost(0) and C.rebirthSpeed(1) > C.rebirthSpeed(0), "el siguiente no cuesta más")
	d.rebirths = C.REBIRTH.MAX
	d.money, d.speed = math.huge / 2, math.huge / 2
	s.actionTimes = {}
	G.Core.handleAction(fp, "rebirth")
	assert(d.rebirths == C.REBIRTH.MAX, "pasó del máximo")
	assert(G.Data.sanitize({ rebirths = 999 }, C).rebirths == C.REBIRTH.MAX and G.Data.sanitize({}, C).rebirths == 0, "datos de renacimientos")
	add(string.format("   1º: 💰 %s + ⚡ %s · 5º: 💰 %s + ⚡ %s · x%s con 5", G.Format.num(C.rebirthCost(0)), G.Format.num(C.rebirthSpeed(0)), G.Format.num(C.rebirthCost(4)), G.Format.num(C.rebirthSpeed(4)), G.Format.mult(C.rebirthMult(5))))
end)

step("Colección enorme: se recorta sin tocar el índice", function()
	local fp, d = fakePlayer(-107)
	for i = 1, 700 do
		table.insert(d.godList, { id = "pan", kg = 100 })
	end
	d.gods.pan = 700
	G.Core.addGod(fp, C.GOD_BY_ID.zeus, 300)
	assert(#d.godList <= G.Data.GODLIST_MAX, "no recortó")
	assert(d.godList[1].id == "zeus", "quitó el más valioso")
	assert(d.gods.pan == 700, "tocó el índice")
end)

step("Mutaciones: probabilidades, guardado y multiplicador de ingresos", function()
	-- Barrido uniforme de la tirada: cada mutación sale con su probabilidad exacta
	local N, counts = 100000, {}
	for k = 0, N - 1 do
		local x = (k + 0.5) / N
		local m = C.rollMutation(function()
			return x
		end)
		if m then
			counts[m] = (counts[m] or 0) + 1
		end
	end
	local total = 0
	for _, m in ipairs(C.MUTATIONS) do
		assert(math.abs((counts[m.id] or 0) / N - m.chance) < 0.001, "probabilidad " .. m.id)
		assert(C.mutMult(m.id) == m.mult, "multiplicador " .. m.id)
		total += m.chance
	end
	assert(math.abs(total - 0.1435) < 1e-9, "total de mutaciones")
	assert(C.mutMult(nil) == 1 and C.mutMult("falsa") == 1, "sin mutación = x1")
	-- Datos: guarda una mutación válida y quita una inventada
	local d = G.Data.sanitize({ godList = { { id = "zeus", kg = 100, mut = "lava" }, { id = "hera", kg = 100, mut = "hackeada" } } }, C)
	local lava = 0
	for _, e in ipairs(d.godList) do
		assert(e.mut == nil or C.MUTATION_BY_ID[e.mut], "mutación inventada")
		lava += (e.mut == "lava") and 1 or 0
	end
	assert(lava == 1, "perdió la mutación")
	-- Ingresos: el dios mutado vale más y va primero en la parcela
	local fp, pd = fakePlayer(-120)
	G.Core.addGod(fp, C.GOD_BY_ID.zeus, 100)
	G.Core.addGod(fp, C.GOD_BY_ID.zeus, 100, "rainbow")
	G.Core.addGod(fp, C.GOD_BY_ID.zeus, 100, "trampa")
	local found = 0
	for _, e in ipairs(pd.godList) do
		if e.mut == "rainbow" then
			found += 1
		end
		assert(e.mut == nil or e.mut == "rainbow", "guardó una mutación falsa")
	end
	assert(found == 1, "no guardó la mutación")
	local placed = G.Core.computePlaced(fp)
	assert(placed[1].mut == "rainbow", "el mutado no va primero")
	assert(math.abs(placed[1].value - placed[2].value * 8) < 1e-6, "arcoíris no multiplica x8")
end)

step("Rendimiento: multiplicadores e ingresos en caché", function()
	local fp, d = fakePlayer(-108)
	for _, g in ipairs(C.GODS) do
		d.gods[g.id] = 1
		table.insert(d.godList, { id = g.id, kg = 150 })
	end
	local t0 = os.clock()
	for _ = 1, 20000 do
		G.Core.mults(fp)
		G.Core.income(fp)
	end
	local dt = os.clock() - t0
	add(string.format("   20.000 consultas de ingresos en %.3f s", dt))
	assert(dt < 1, "demasiado lento")
end)

---------------------------------------------------------------------
-- SOBRES: nidos por zona, tamaño por kilos, 14 diseños y sobres quietos
---------------------------------------------------------------------
local CollectionService = game:GetService("CollectionService")
local PS = G.PackStyle
local FX_TAGS = { "FxSpin", "FxBob", "FxOrbit", "FxRainbow", "FxGlitch" }

-- punto más bajo, punto más alto y radio horizontal máximo (respecto a `centre`) de una pieza
local function extents(p, centre)
	local c = p.CFrame
	local pos = c.Position
	local flat = centre and Vector3.new(pos.X - centre.X, 0, pos.Z - centre.Z).Magnitude or 0
	if p:IsA("Part") and p.Shape == Enum.PartType.Ball then
		local r = math.min(p.Size.X, p.Size.Y, p.Size.Z) / 2
		return pos.Y - r, pos.Y + r, flat + r
	elseif p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then
		-- cilindro: eje = X local
		local axis = c.RightVector
		local r = math.min(p.Size.Y, p.Size.Z) / 2
		local half = p.Size.X / 2
		local v = r * math.sqrt(math.max(0, 1 - axis.Y * axis.Y)) + half * math.abs(axis.Y)
		local rad = 0
		if centre then
			-- el extremo más alejado del centro, más el radio del cilindro
			for _, side in ipairs({ -1, 1 }) do
				local tip = pos + axis * (half * side)
				rad = math.max(rad, Vector3.new(tip.X - centre.X, 0, tip.Z - centre.Z).Magnitude + r)
			end
		end
		return pos.Y - v, pos.Y + v, rad
	end
	local h = p.Size / 2
	local lo, hi, rad = math.huge, -math.huge, 0
	for _, sx in ipairs({ -1, 1 }) do
		for _, sy in ipairs({ -1, 1 }) do
			for _, sz in ipairs({ -1, 1 }) do
				local w = c * Vector3.new(sx * h.X, sy * h.Y, sz * h.Z)
				lo, hi = math.min(lo, w.Y), math.max(hi, w.Y)
				if centre then
					rad = math.max(rad, Vector3.new(w.X - centre.X, 0, w.Z - centre.Z).Magnitude)
				end
			end
		end
	end
	return lo, hi, rad
end

step("Nidos: seis huecos juntos por zona y nido decorado sin colisión", function()
	assert(PS, "falta el módulo PackStyle")
	local floorY = PS.FLOOR_Y
	local info = {}
	for i = 1, #C.ZONES do
		local centre = Vector3.new(0, 0, G.World.zoneStart(i) + C.NEST_OFFSET)
		local spots = G.World.zoneParts[i].spots
		assert(#spots == C.PACKS_PER_ZONE, "zona " .. i .. ": huecos " .. #spots)
		for a = 1, #spots do
			assert((spots[a] - centre).Magnitude <= C.NEST_RADIUS + 0.5, "zona " .. i .. ": hueco " .. a .. " fuera del nido")
			for b = a + 1, #spots do
				assert((spots[a] - spots[b]).Magnitude >= 4, "zona " .. i .. ": huecos " .. a .. " y " .. b .. " demasiado juntos")
			end
		end
		local nest = G.World.getRoot():FindFirstChild("Nest" .. i)
		assert(nest and nest:IsA("Folder"), "zona " .. i .. ": sin nido")
		local parts, lights, emitters, spin, maxR, maxY = 0, 0, 0, 0, 0, 0
		for _, d in ipairs(nest:GetDescendants()) do
			if d:IsA("BasePart") then
				parts += 1
				assert(d.Anchored and not d.CanCollide and not d.CanQuery and not d.CanTouch, "zona " .. i .. ": " .. d.Name .. " estorba el paso")
				local _, hi, rad = extents(d, centre)
				maxR, maxY = math.max(maxR, rad), math.max(maxY, hi)
				if CollectionService:HasTag(d, "FxSpin") then
					spin += 1
					assert(d:GetAttribute("SpinAxis") == "X" and d.Shape == Enum.PartType.Cylinder, "disco de runas")
					assert(d:FindFirstChildOfClass("Decal"), "disco sin runas")
				end
			elseif d:IsA("PointLight") then
				lights += 1
				assert(not d.Shadows, "luz con sombras")
			elseif d:IsA("ParticleEmitter") then
				emitters += 1
				assert(d.Rate <= 10, "demasiadas chispas")
			end
		end
		assert(parts <= 70, "zona " .. i .. ": " .. parts .. " piezas")
		assert(parts >= 40, "zona " .. i .. ": nido pobre (" .. parts .. " piezas)")
		assert(lights == 1 and emitters >= 1 and emitters <= 2 and spin == 1, string.format("zona %d: luces %d emisores %d discos %d", i, lights, emitters, spin))
		assert(maxR <= PS.NEST_OUTER, string.format("zona %d: radio %.2f", i, maxR))
		assert(maxY - floorY <= PS.NEST_RIM, string.format("zona %d: borde de %.2f de alto", i, maxY - floorY))
		table.insert(info, string.format("%d piezas r=%.1f h=%.1f", parts, maxR, maxY - floorY))
	end
	add("   Nidos: " .. table.concat(info, " · "))
end)

step("Tamaño del sobre según sus kilos", function()
	local last = 0
	for _, kg in ipairs({ 1, 40, 60, 100, 160, 300, 600, 1500, 5000 }) do
		local k = C.packScale(kg)
		assert(k >= last, "packScale no crece en " .. kg .. " kg")
		last = k
	end
	assert(C.packScale(160) > C.packScale(100) * 1.2 and C.packScale(300) > C.packScale(100) * 1.7, "la diferencia de tamaño no se nota")
	assert(C.packScale(1) >= 0.85 and C.packScale(1e6) <= 3.6, "límites")
	local sizes = {}
	for _, kg in ipairs({ 40, 100, 300, 5000 }) do
		local pack = G.Packs.debugSpawn(1, 2, 3, kg, false)
		local k = C.packScale(kg)
		assert(pack.kg == kg and pack.k == k, "peso")
		assert((pack.part.Size - Vector3.new(3, 4, 0.5) * k).Magnitude < 0.01, "el cuerpo no mide 3×4×0.5×k")
		table.insert(sizes, string.format("%d kg → %.1f de alto", kg, pack.part.Size.Y))
	end
	add("   " .. table.concat(sizes, " · "))
end)

step("Diseños de las 14 rarezas: presupuesto, contrato, ocultar, mostrar y destruir", function()
	local prev, lastScore, lastRange = nil, -1, -1
	local summary = {}
	for r = 1, 14 do
		for _, dawn in ipairs({ false, true }) do
			-- el más raro, además, gigante: nada puede quedar bajo el suelo
			local pack = G.Packs.debugSpawn(2, 3, r, (r == 14 or r == 7) and 5000 or 120, dawn)
			if prev then
				assert(prev.state == "gone" and prev.part.Parent == nil and G.Packs.list[prev.id] == nil, "el sobre anterior no se destruyó")
			end
			prev = pack
			local part = pack.part
			local what = string.format("rareza %d%s", r, dawn and " (amanecer)" or "")
			assert(part and part.Parent == workspace and part.Anchored and not part.CanCollide, what .. ": cuerpo")
			local maxE, maxP = PS.budget(r)
			local emitters, extra, lights, range = 0, 0, 0, 0
			local before, toggles = {}, {}
			before[part] = part.Transparency
			for _, d in ipairs(part:GetDescendants()) do
				if d:IsA("BasePart") then
					extra += 1
					assert(not d.CanCollide and not d.CanQuery and not d.CanTouch, what .. ": " .. d.Name .. " choca")
					if d.Anchored then
						assert(d.Parent == part and (d.Name == "Beam" or CollectionService:HasTag(d, "FxOrbit")), what .. ": pieza anclada sin motivo: " .. d.Name)
					else
						assert(d.Massless and d:FindFirstChildOfClass("WeldConstraint"), what .. ": " .. d.Name .. " sin soldar")
					end
					local lo = extents(d)
					assert(lo >= PS.FLOOR_Y - 0.05, string.format("%s: %s bajo el suelo (%.2f)", what, d.Name, lo))
				elseif d:IsA("ParticleEmitter") then
					emitters += 1
				elseif d:IsA("PointLight") then
					lights += 1
					range = PS.STYLES[r].light.range -- alcance base (el real crece un poco con el tamaño)
					assert(d.Range >= range and d.Range <= 32, what .. ": alcance de la luz")
					assert(not d.Shadows, what .. ": luz con sombras")
				end
				if d:IsA("BasePart") or d:IsA("Decal") then
					before[d] = d.Transparency
				elseif d:IsA("ParticleEmitter") or d:IsA("PointLight") or d:IsA("SurfaceGui") or d:IsA("BillboardGui") or d:IsA("Beam") or d:IsA("Trail") then
					table.insert(toggles, d)
				end
				-- contrato de efectos: las piezas etiquetadas van ancladas y lo que orbita cuelga del sobre
				if d:IsA("BasePart") then
					for _, tagName in ipairs(FX_TAGS) do
						if CollectionService:HasTag(d, tagName) then
							assert(d.Anchored, what .. ": " .. d.Name .. " lleva " .. tagName .. " sin estar anclada")
						end
					end
					if CollectionService:HasTag(d, "FxOrbit") then
						assert(type(d:GetAttribute("OrbitRadius")) == "number" and type(d:GetAttribute("OrbitSpeed")) == "number", what .. ": órbita sin datos")
					end
				end
			end
			assert(emitters <= maxE, string.format("%s: %d emisores (máx %d)", what, emitters, maxE))
			assert(extra <= maxP, string.format("%s: %d piezas extra (máx %d)", what, extra, maxP))
			assert(lights <= 1, what .. ": más de una luz")
			local sgs = 0
			for _, ch in ipairs(part:GetChildren()) do
				if ch:IsA("SurfaceGui") then
					sgs += 1
					assert(ch:FindFirstChild("Kg", true).Text == pack.kg .. " KG", what .. ": peso de la carta")
				end
			end
			assert(sgs == 2, what .. ": caras de la carta")
			if r >= C.ANNOUNCE_BIG_FROM then
				assert(pack.beam and pack.beam.Size.X >= 200, what .. ": sin haz de luz")
				assert(math.abs(pack.beam.CFrame.RightVector.Y) > 0.999, what .. ": haz torcido")
			end
			local gui = part:FindFirstChildOfClass("BillboardGui")
			assert(gui and CollectionService:HasTag(gui, "Loc") and gui:FindFirstChild("Label"), what .. ": cartel")
			assert(gui:GetAttribute("Rarity") == r and gui:GetAttribute("Kg") == pack.kg and gui:GetAttribute("Dawn") == dawn, what .. ": datos del cartel")
			assert(gui.StudsOffsetWorldSpace.Y > part.Size.Y / 2, what .. ": cartel dentro del sobre")
			assert(pack.prompt:GetAttribute("Kind") == "steal" and CollectionService:HasTag(pack.prompt, "LocPrompt"), what .. ": aviso de robo")
			assert(pack.prompt.MaxActivationDistance >= 8 and pack.prompt.MaxActivationDistance <= 13, what .. ": distancia del aviso")
			-- ocultar (dos veces: no debe perder la transparencia original) y volver a mostrar
			G.Packs.setPackVisible(pack, false)
			G.Packs.setPackVisible(pack, false)
			for d in pairs(before) do
				assert(d.Transparency == 1, what .. ": " .. d.Name .. " sigue visible")
			end
			for _, d in ipairs(toggles) do
				assert(d.Enabled == false, what .. ": " .. d.ClassName .. " sigue encendido")
			end
			local box = part:FindFirstChildOfClass("SelectionBox")
			assert(not box or box.Visible == false, what .. ": borde visible")
			assert(not CollectionService:HasTag(part, "FxGlitch"), what .. ": parpadea estando oculto")
			G.Packs.setPackVisible(pack, true)
			for d, t in pairs(before) do
				assert(math.abs(d.Transparency - t) < 1e-4, string.format("%s: %s no recuperó su transparencia (%.2f → %.2f)", what, d.Name, t, d.Transparency))
			end
			for _, d in ipairs(toggles) do
				assert(d.Enabled == true, what .. ": " .. d.ClassName .. " no volvió")
			end
			assert(not box or box.Visible == true, what .. ": borde")
			assert(CollectionService:HasTag(part, "FxGlitch") == (r == 14), what .. ": etiqueta de parpadeo")
			if not dawn then
				-- cada rareza, al menos tan recargada y luminosa como la anterior
				local score = emitters + extra
				assert(score >= lastScore and range >= lastRange, string.format("%s es menos épica que la anterior (%d < %d o luz %.0f < %.0f)", what, score, lastScore, range, lastRange))
				lastScore, lastRange = score, range
				table.insert(summary, string.format("%d:%de/%dp", r, emitters, extra))
			else
				assert(part:FindFirstChild("DawnArc") and part:FindFirstChild("Dawn", true), what .. ": sin brillo de amanecer")
			end
		end
	end
	G.Packs.debugSpawn(2, 3, 2, 100, false)
	assert(prev.state == "gone" and prev.part.Parent == nil, "el último no se destruyó")
	add("   emisores/piezas por rareza: " .. table.concat(summary, " "))
end)

step("Sobres quietos en el nido: de pie, algo inclinados y mirando hacia fuera", function()
	G.Packs.refreshAll()
	local n = 0
	local snap = {}
	G.Packs.stepPacks()
	for id, pack in pairs(G.Packs.list) do
		snap[id] = pack.part.CFrame
		n += 1
	end
	assert(n == #C.ZONES * C.PACKS_PER_ZONE, "sobres " .. n)
	task.wait(0.1)
	G.Packs.stepPacks()
	task.wait()
	G.Packs.stepPacks()
	local bed = PS.FLOOR_Y + PS.NEST_BED
	for id, pack in pairs(G.Packs.list) do
		local cf = pack.part.CFrame
		assert(cf == snap[id], "el sobre " .. id .. " se movió estando en el suelo")
		local centre = Vector3.new(0, 0, G.World.zoneStart(pack.zone) + C.NEST_OFFSET)
		assert(pack.home == G.World.zoneParts[pack.zone].spots[pack.spot], "hueco")
		assert(Vector3.new(cf.X - pack.home.X, 0, cf.Z - pack.home.Z).Magnitude < 0.01, "fuera de su hueco")
		local lean = math.deg(math.acos(math.clamp(cf.UpVector.Y, -1, 1)))
		assert(lean >= 4.9 and lean <= 12.1, string.format("inclinación %.1f°", lean))
		local out = Vector3.new(pack.home.X - centre.X, 0, pack.home.Z - centre.Z)
		if out.Magnitude > 0.5 then
			assert(cf.LookVector:Dot(out.Unit) > 0.9, "la cara no mira hacia fuera del nido")
			assert(cf.UpVector:Dot(out.Unit) < 0, "no se apoya hacia el centro")
		else
			assert(cf.LookVector.Z < -0.9, "el del centro no mira a la entrada")
		end
		-- un poco hundido en el lecho, nunca bajo el suelo
		local lo = math.huge
		for _, d in ipairs(pack.part:GetChildren()) do
			if d:IsA("BasePart") and d.Name == "Crimp" then
				lo = math.min(lo, (extents(d)))
			end
		end
		assert(lo <= bed and lo >= bed - 0.3, string.format("apoyo a %.2f del lecho", lo - bed))
	end
end)

step("Robar, llevar, soltar y entregar un sobre del nido", function()
	local fp, d, s = fakePlayer(-201)
	local char = Instance.new("Model")
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Anchored = true
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Parent = char
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.Size = Vector3.new(2, 1, 1)
	head.Parent = char
	char.Parent = workspace
	fp.Character = char
	local function stand(pos) -- pos = punto del suelo
		hrp.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
		head.CFrame = CFrame.new(pos.X, pos.Y + 4.5, pos.Z)
	end
	-- un Secreta gigante en un hueco del anillo: su aviso se alcanza desde fuera del nido
	local pack = G.Packs.debugSpawn(1, 2, 10, 5000, false)
	local home = pack.part.CFrame
	local centre = Vector3.new(0, 0, G.World.zoneStart(1) + C.NEST_OFFSET)
	local out = (pack.home - centre).Unit
	stand(pack.home + out * 30 + Vector3.new(0, 0.2, 0))
	G.Packs.grab(fp, pack)
	assert(pack.state == "ground" and not s.carrying, "se robó desde lejos")
	stand(pack.home + out * 5 + Vector3.new(0, 0.2, 0))
	local reach = (hrp.Position - pack.part.Position).Magnitude
	assert(reach <= pack.prompt.MaxActivationDistance, string.format("aviso inalcanzable (%.1f > %.1f)", reach, pack.prompt.MaxActivationDistance))
	local shouts = {}
	G.Net.Sfx = { FireAllClients = function(_, data) table.insert(shouts, data) end }
	G.Packs.grab(fp, pack)
	G.Net.Sfx = noop
	assert(pack.state == "carried" and s.carrying == pack and pack.carrier == fp and pack.prompt.Enabled == false, "no lo cogió")
	-- el guardián grita al empezar a perseguirte (con su frase) y no repite enseguida
	assert(#shouts == 1 and shouts[1].kind == "shout" and C.SHOUTS[shouts[1].guardian] and shouts[1].victim == fp.UserId, "sin grito del guardián")
	assert(G.World.guardians[1].target == fp, "el guardián no persigue")
	assert(pack.part:FindFirstChild("CarryFX") and pack.part:FindFirstChild("CarryTrail"), "sin estela")
	-- sigue a la cabeza, de pie, con su haz de luz
	stand(Vector3.new(40, 0.2, 150))
	G.Packs.stepPacks()
	local c = pack.part.Position
	assert(math.abs(c.X - 40) < 0.01 and math.abs(c.Z - 150) < 0.01 and c.Y - pack.part.Size.Y / 2 > head.Position.Y + 0.5, "no flota sobre la cabeza")
	assert(pack.part.CFrame.UpVector.Y > 0.999, "torcido al llevarlo")
	assert(math.abs(pack.beam.Position.X - 40) < 0.01 and math.abs(pack.beam.Position.Z - 150) < 0.01, "el haz no lo sigue")
	local crimp = pack.part:FindFirstChild("Crimp")
	assert((crimp.Position - c).Magnitude < pack.part.Size.Y, "los adornos soldados no siguen al sobre")
	-- golpe: cae y se queda quieto donde cayó
	G.Packs.dropCarried(fp, true, hrp.Position)
	assert(pack.state == "loose" and pack.prompt.Enabled and not s.carrying and not pack.carrier, "no cayó")
	assert(G.World.guardians[1].target == nil, "el guardián sigue persiguiendo")
	assert(not pack.part:FindFirstChild("CarryFX") and not pack.part:FindFirstChild("CarryTrail"), "la estela sigue")
	local cf = pack.part.CFrame
	G.Packs.stepPacks()
	task.wait()
	G.Packs.stepPacks()
	assert(pack.part.CFrame == cf, "el sobre suelto se mueve")
	assert(math.abs(cf.X - 40) < 0.01 and math.abs(cf.Z - 150) < 0.01, "no está donde cayó")
	local lo = math.huge
	for _, ch in ipairs(pack.part:GetChildren()) do
		if ch:IsA("BasePart") and ch.Name == "Crimp" then
			lo = math.min(lo, (extents(ch)))
		end
	end
	assert(math.abs(lo - PS.FLOOR_Y) < 0.05, string.format("no se apoya en el suelo (%.2f)", lo))
	-- si cae dentro del nido, se apoya en el lecho (no se hunde hasta la pista)
	stand(Vector3.new(42, 0.2, 150))
	G.Packs.grab(fp, pack)
	stand(centre + Vector3.new(4, 0.2, -3))
	G.Packs.dropCarried(fp, true, hrp.Position)
	lo = math.huge
	for _, ch in ipairs(pack.part:GetChildren()) do
		if ch:IsA("BasePart") and ch.Name == "Crimp" then
			lo = math.min(lo, (extents(ch)))
		end
	end
	assert(pack.state == "loose" and math.abs(lo - (PS.FLOOR_Y + PS.NEST_BED)) < 0.05, string.format("dentro del nido no se apoya en el lecho (%.2f)", lo))
	stand(centre + Vector3.new(6, 0.2, -3))
	-- se vuelve a coger y se suelta sin golpe: vuelve a su hueco, igual que estaba
	G.Packs.grab(fp, pack)
	assert(pack.state == "carried", "no se pudo recoger del suelo")
	G.Packs.dropCarried(fp, false)
	assert(pack.state == "ground" and pack.loosePos == nil, "no volvió al nido")
	assert((pack.part.Position - home.Position).Magnitude < 0.001 and pack.part.CFrame.LookVector:Dot(home.LookVector) > 0.9999, "no quedó como estaba")
	-- entrega en la parcela
	s.plot = G.World.plots[1]
	stand(pack.home + out * 5 + Vector3.new(0, 0.2, 0))
	G.Packs.grab(fp, pack)
	assert(pack.state == "carried", "no lo cogió para entregarlo")
	stand(s.plot.center + Vector3.new(0, 1, 0))
	G.Packs.stepPacks()
	assert(pack.state == "gone" and pack.part.Parent == nil and not s.carrying, "no se entregó")
	local got = d.altarPacks[#d.altarPacks]
	assert(got and got.r == 10 and got.kg == 5000, "el altar no recibió el sobre")
	s.plot = nil
	char:Destroy()
end)

---------------------------------------------------------------------
-- FASE 2: misiones diarias, racha diaria, tutorial y suerte (jugadores simulados)
---------------------------------------------------------------------
local Q = C.QUESTS
local Quests = G.Quests
local today = Quests.today()

-- personaje mínimo (raíz y cabeza) para robar, llevar y golpear
local function withChar(fp)
	local char = Instance.new("Model")
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Anchored = true
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Parent = char
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Anchored = true
	head.Size = Vector3.new(2, 1, 1)
	head.Parent = char
	char.Parent = workspace
	fp.Character = char
	local function stand(pos)
		hrp.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
		head.CFrame = CFrame.new(pos.X, pos.Y + 4.5, pos.Z)
	end
	return char, hrp, stand
end
local function setMissions(d, ids)
	d.missions = { day = today, rr = 0, list = {} }
	for _, id in ipairs(ids) do
		table.insert(d.missions.list, { id = id, goal = C.QUEST_BY_ID[id].goal, progress = 0, claimed = false })
	end
end
local function progressOf(d, id)
	for _, m in ipairs(d.missions.list) do
		if m.id == id then
			return m.progress
		end
	end
	return nil
end
local function forget(...)
	for _, fp in ipairs({ ... }) do
		if fp.Character then
			fp.Character:Destroy()
			fp.Character = nil
		end
		G.Data.profiles[fp] = nil
		G.Core.sessions[fp] = nil
	end
end

step("Misiones: al entrar, 3 distintas y el tutorial según el progreso", function()
	local fp, d = fakePlayer(-301)
	Quests.onJoin(fp)
	assert(d.missions.day == today and #d.missions.list == Q.PER_DAY, "misiones: " .. #d.missions.list)
	local seen, ids = {}, {}
	for i, m in ipairs(d.missions.list) do
		assert(C.QUEST_BY_ID[m.id] and not seen[m.id], "misión repetida o desconocida: " .. tostring(m.id))
		seen[m.id] = true
		ids[i] = m.id
		assert(m.goal == C.QUEST_BY_ID[m.id].goal and m.progress == 0 and m.claimed == false, "misión mal creada")
	end
	assert(d.tutorial == 1, "un jugador nuevo empieza el tutorial")
	-- el mismo día salen las mismas (no se arreglan entrando y saliendo)
	d.missions.day = 0
	Quests.onJoin(fp)
	for i, m in ipairs(d.missions.list) do
		assert(m.id == ids[i], "cambiaron al volver a entrar")
	end
	-- veteranos (con dioses o más de 10 min jugados): sin tutorial
	local fp2, d2 = fakePlayer(-302)
	d2.gods.zeus = 1
	Quests.onJoin(fp2)
	local fp3, d3 = fakePlayer(-303)
	d3.playtime = 900
	Quests.onJoin(fp3)
	assert(d2.tutorial == Q.TUTORIAL_DONE and d3.tutorial == Q.TUTORIAL_DONE, "un veterano tiene tutorial")
	-- "dios nuevo" solo se pide si hay alguno que pueda conseguir en sus zonas
	local withNew, without = 0, 0
	for k = 1, 30 do
		local f1, a = fakePlayer(-1000 - k)
		Quests.onJoin(f1)
		if progressOf(a, "newgod") then
			withNew += 1
		end
		local f2, b = fakePlayer(-2000 - k)
		for _, g in ipairs(C.GODS) do
			if C.ZONES[1].weights[g.r] then
				b.gods[g.id] = 1
			end
		end
		Quests.onJoin(f2)
		if progressOf(b, "newgod") then
			without += 1
		end
		forget(f1, f2)
	end
	assert(withNew > 0 and without == 0, string.format("dios nuevo: %d veces a quien puede · %d a quien no", withNew, without))
	add(string.format("   Misiones de hoy (ejemplo): %s", table.concat(ids, ", ")))
	forget(fp, fp2, fp3)
end)

step("Misiones: robar, escapar, abrir, combo, dios nuevo y golpe suman (sin pasarse)", function()
	local fp, d, s = fakePlayer(-310)
	d.tutorial = Q.TUTORIAL_DONE
	setMissions(d, { "steal", "escape", "open" })
	for _ = 1, 9 do
		Quests.event(fp, "steal", 1)
	end
	assert(progressOf(d, "steal") == 5, "robar no se para en la meta: " .. progressOf(d, "steal"))
	Quests.event(fp, "hit", 1) -- no está en su lista: no pasa nada
	-- robar de verdad: soltar y coger otra vez el mismo sobre no suma
	setMissions(d, { "steal", "escape", "open" })
	local _, hrp, stand = withChar(fp)
	local pack = G.Packs.debugSpawn(1, 4, 2, 100, false)
	local centre = Vector3.new(0, 0, G.World.zoneStart(1) + C.NEST_OFFSET)
	stand(pack.home + (pack.home - centre).Unit * 5 + Vector3.new(0, 0.2, 0))
	G.Packs.grab(fp, pack)
	assert(s.carrying == pack and progressOf(d, "steal") == 1, "robar no sumó")
	G.Packs.dropCarried(fp, true, hrp.Position)
	G.Packs.grab(fp, pack)
	assert(s.carrying == pack and progressOf(d, "steal") == 1, "coger otra vez el mismo sobre sumó")
	-- llegar a casa con él = escapar
	s.plot = G.World.plots[2]
	stand(s.plot.center + Vector3.new(0, 1, 0))
	G.Packs.stepPacks()
	assert(pack.state == "gone" and progressOf(d, "escape") == 1, "escapar no sumó")
	-- abrirlo en el altar
	s.plot = nil
	local i = #d.altarPacks
	d.altarPacks[i].rem = 0
	G.Packs.openAltar(fp, i)
	assert(progressOf(d, "open") == 1, "abrir no sumó")
	-- combo acertado, dios nuevo (uno repetido no cuenta) y golpe en el pasillo
	setMissions(d, { "combo", "newgod", "hit" })
	s.onTreadmill, s.locked = true, true
	assert(G.Core.handleCombo(fp, G.Core.spawnTap(fp).id) == true and progressOf(d, "combo") == 1, "combo no sumó")
	s.onTreadmill, s.locked = false, false
	G.Core.addGod(fp, C.GOD_BY_ID.ouroboros, 100)
	G.Core.addGod(fp, C.GOD_BY_ID.ouroboros, 100)
	assert(progressOf(d, "newgod") == 1, "dios nuevo: " .. progressOf(d, "newgod"))
	local fv, dv = fakePlayer(-311)
	dv.playtime = C.NEWBIE_PROTECTION + 1
	local _, vhrp = withChar(fv)
	hrp.CFrame = CFrame.lookAt(Vector3.new(30, 3.2, 160), Vector3.new(30, 3.2, 170))
	vhrp.CFrame = CFrame.new(30, 3.2, 164)
	s.lastHit = 0
	local sfx = {}
	G.Net.Sfx = { FireAllClients = function(_, data) table.insert(sfx, data) end }
	G.Combat.swing(fp, Instance.new("Folder"))
	G.Net.Sfx = noop
	assert(dv.playtime > 0 and progressOf(d, "hit") == 1, "golpear no sumó")
	assert(#sfx == 1 and sfx[1].kind == "hit" and sfx[1].victim == fv.UserId and sfx[1].attacker == fp.UserId and typeof(sfx[1].pos) == "Vector3", "sin ¡FAHHH! al golpear")
	forget(fp, fv)
end)

step("Misiones: reclamar paga una sola vez y llega cada tipo de premio", function()
	local fp, d = fakePlayer(-320)
	d.tutorial = Q.TUTORIAL_DONE
	setMissions(d, { "steal", "open", "escape" }) -- dinero, suerte, velocidad
	assert(Quests.claimMission(fp, 1) == false, "pagó una misión sin terminar")
	for _, m in ipairs(d.missions.list) do
		m.progress = m.goal
	end
	local m0 = d.money
	assert(Quests.claimMission(fp, 1) == true and d.money >= m0 + Q.MONEY_MIN, "no pagó el dinero")
	local m1 = d.money
	assert(Quests.claimMission(fp, 1) == false and d.money == m1, "pagó dos veces")
	assert(Quests.claimMission(fp, 2) == true and d.boosts.luck > os.time() + 9 * 60, "sin suerte")
	assert(Quests.claimMission(fp, 3) == true and d.boosts.speed > os.time() + 4 * 60, "sin velocidad")
	for _, bad in ipairs({ 0, 4, 99, -1, "x", 1.5, {} }) do
		assert(Quests.claimMission(fp, bad) == false, "índice raro: " .. tostring(bad))
	end
	assert(Quests.claimMission(fp, nil) == false, "índice nil")
	-- premio de sobre: llega al altar
	setMissions(d, { "newgod" })
	d.missions.list[1].progress = 1
	local before = #d.altarPacks + #d.queue
	assert(Quests.claimMission(fp, 1) == true and #d.altarPacks + #d.queue == before + 1, "el sobre no llegó")
	-- por la acción del cliente (como lo pide el botón)
	setMissions(d, { "train" })
	d.missions.list[1].progress = d.missions.list[1].goal
	local m2 = d.money
	G.Core.handleAction(fp, "claimMission", 1)
	local m3 = d.money
	G.Core.handleAction(fp, "claimMission", 1)
	assert(d.missions.list[1].claimed and m3 > m2 and d.money == m3, "la acción claimMission no pagó o pagó dos veces")
	forget(fp)
end)

step("Misiones: cambiar una sin terminar (1 al día) y cambio de día", function()
	local fp, d, s = fakePlayer(-325)
	setMissions(d, { "steal", "open", "escape" })
	d.missions.list[2].progress = d.missions.list[2].goal
	assert(Quests.rerollMission(fp, 2) == false, "cambió una terminada")
	assert(G.Core.handleAction(fp, "rerollMission", 1) and d.missions.list[1].id ~= "steal", "no cambió")
	local id = d.missions.list[1].id
	assert(id ~= "open" and id ~= "escape" and d.missions.list[1].progress == 0, "la nueva repite o trae progreso: " .. id)
	assert(Quests.rerollMission(fp, 3) == false and Quests.state(fp).rr == 0, "dejó cambiar dos veces")
	-- medianoche UTC: las terminadas sin reclamar se pagan solas y salen nuevas
	d.missions.day = today - 1
	d.missions.list[1].progress = d.missions.list[1].goal
	local m0 = d.money
	Quests.tick(fp, s, d)
	assert(d.missions.day == today and #d.missions.list == Q.PER_DAY and d.missions.rr == 0, "no salieron las de hoy")
	assert(d.money >= m0 + Q.MONEY_MIN or d.boosts.luck > os.time() or d.boosts.speed > os.time() or #d.altarPacks > 0, "no pagó la terminada de ayer")
	for _, m in ipairs(d.missions.list) do
		assert(m.progress == 0 and not m.claimed, "una nueva trae progreso")
	end
	-- una lista de hoy vacía (partida rota o misiones quitadas de Config) se vuelve a llenar, sin pagar nada
	d.missions = { day = today, rr = 1, list = {} }
	local m1 = d.money
	Quests.tick(fp, s, d)
	assert(#d.missions.list == Q.PER_DAY and d.money == m1, "la lista vacía de hoy no se rellena")
	-- misiones de "mañana" (otro servidor con el reloj algo adelantado ya pasó la medianoche): se conservan,
	-- ni se pagan ni se cambian por las de ayer (que se podrían volver a cobrar)
	setMissions(d, { "steal", "open", "escape" })
	d.missions.day = today + 1
	d.missions.list[1].progress = d.missions.list[1].goal
	d.missions.list[2].progress = 2
	local m2 = d.money
	Quests.tick(fp, s, d)
	assert(d.missions.day == today + 1 and d.missions.list[1].id == "steal" and d.missions.list[2].progress == 2 and d.money == m2, "las de mañana se tiraron")
	assert(Quests.claimMission(fp, 1) == true and d.money > m2, "no se pudo reclamar la de mañana")
	-- más allá de mañana es un dato roto: salen las de hoy
	d.missions.day = today + 5
	Quests.tick(fp, s, d)
	assert(d.missions.day == today, "un día roto no se corrige")
	forget(fp)
end)

step("Racha diaria: una vez al día, sigue si es seguida y se reinicia tras un hueco", function()
	local fp, d = fakePlayer(-340)
	local q = Quests.state(fp)
	assert(q.dailyCan == true and q.streak == 1, "un jugador nuevo puede reclamar el día 1")
	local m0 = d.money
	assert(Quests.claimDaily(fp) == true and d.daily.last == today and d.daily.streak == 1 and d.money >= m0 + Q.MONEY_MIN, "día 1")
	local m1 = d.money
	assert(Quests.claimDaily(fp) == false and d.money == m1, "cobró dos veces el mismo día")
	G.Core.handleAction(fp, "claimDaily")
	assert(d.money == m1, "la acción cobró dos veces")
	q = Quests.state(fp)
	assert(q.dailyCan == false and q.streak == 1, "estado tras reclamar")
	-- ayer reclamó el día 3: hoy toca el 4 (velocidad)
	d.daily.last, d.daily.streak = today - 1, 3
	assert(Quests.state(fp).streak == 4, "la racha seguida no sube")
	assert(Quests.claimDaily(fp) == true and d.daily.streak == 4 and d.boosts.speed > os.time() + 60, "día 4: velocidad")
	-- un hueco de 3 días: vuelta al día 1
	d.daily.last, d.daily.streak = today - 3, 5
	assert(Quests.state(fp).streak == 1 and Quests.claimDaily(fp) == true and d.daily.streak == 1, "el hueco no reinicia la racha")
	-- el día 7 da un MEGA sobre del amanecer; el 8 vuelve al premio del día 1
	d.daily.last, d.daily.streak = today - 1, 6
	assert(Quests.claimDaily(fp) == true and d.daily.streak == 7, "día 7")
	local mega = false
	for _, p in ipairs(d.altarPacks) do
		mega = mega or p.dawn == true
	end
	for _, p in ipairs(d.queue) do
		mega = mega or p.dawn == true
	end
	assert(mega, "el día 7 no dio el MEGA sobre")
	assert(Quests.dailyReward(8) == Q.DAILY[1] and Quests.dailyReward(14) == Q.DAILY[7], "el ciclo no es de 7 días")
	-- dato roto (último día muy en el futuro): se puede reclamar y empieza de cero
	d.daily.last, d.daily.streak = today + 400, 9
	assert(Quests.claimDaily(fp) == true and d.daily.streak == 1, "un dato roto bloquea la racha")
	forget(fp)
end)

step("Tutorial: avanza con lo que hace el jugador, vuelve atrás si pierde el sobre y paga una vez", function()
	local fp, d, s = fakePlayer(-350)
	Quests.onJoin(fp)
	assert(d.tutorial == 1, "empieza en 1")
	s.onTreadmill = true
	d.speed = 10
	Quests.tick(fp, s, d)
	assert(d.tutorial == 1, "avanzó sin velocidad")
	d.speed = C.ZONES[1].guardian.speed
	Quests.tick(fp, s, d)
	assert(d.tutorial == 2, "paso 1 (cinta)")
	s.locked = true
	G.Core.handleCombo(fp, G.Core.spawnTap(fp).id)
	assert(d.tutorial == 3, "paso 2 (combo): " .. d.tutorial)
	s.onTreadmill, s.locked = false, false
	Quests.event(fp, "steal", 1)
	assert(d.tutorial == 4, "paso 3 (robar)")
	Quests.tick(fp, s, d) -- no lleva nada: lo perdió
	assert(d.tutorial == 3, "no vuelve a robar al perder el sobre")
	s.carrying = { rarity = 1 }
	Quests.tick(fp, s, d)
	assert(d.tutorial == 4, "recoger un sobre del suelo no avanza")
	s.carrying = nil
	G.Packs.givePack(fp, { r = 1, rem = 10, dawn = false, kg = 100 })
	Quests.event(fp, "escape", 1)
	Quests.tick(fp, s, d)
	assert(d.tutorial == 5, "paso 4 (volver a casa)")
	Quests.event(fp, "open", 1)
	assert(d.tutorial == 6, "paso 5 (abrir)")
	d.money = C.treadmillCost(2)
	G.Core.handleAction(fp, "buyTreadmill")
	local m0 = d.money
	Quests.tick(fp, s, d)
	assert(d.treadmill == 2 and d.tutorial == Q.TUTORIAL_DONE and d.money >= m0 + Q.MONEY_MIN, "paso 6 (mejorar) o premio")
	local m1 = d.money
	Quests.advance(fp)
	Quests.tick(fp, s, d)
	Quests.event(fp, "open", 1)
	Quests.onJoin(fp)
	assert(d.tutorial == Q.TUTORIAL_DONE and d.money == m1, "el premio del tutorial se pagó dos veces")
	-- "Salvar el sobre" (Robux) en el tutorial: el sobre ya está en casa → paso 5 (sin contar como escapar)
	local fp3, d3, s3 = fakePlayer(-352)
	Quests.onJoin(fp3)
	setMissions(d3, { "escape", "steal", "open" })
	d3.tutorial = 3
	assert(G.Packs.savePurchased(fp3) == true and #d3.altarPacks + #d3.queue == 1, "la compra no dio el sobre")
	Quests.tick(fp3, s3, d3)
	assert(d3.tutorial == 5 and progressOf(d3, "escape") == 0, "tras salvar el sobre: paso " .. d3.tutorial)
	d3.tutorial = Q.TUTORIAL_DONE
	assert(G.Packs.savePurchased(fp3) == true and d3.tutorial == Q.TUTORIAL_DONE, "salvar el sobre cambió un tutorial terminado")
	forget(fp3)
	-- saltarlo: termina sin premio y no vuelve
	local fp2, d2 = fakePlayer(-351)
	Quests.onJoin(fp2)
	Quests.event(fp2, "combo", 1)
	local mm = d2.money
	G.Core.handleAction(fp2, "skipTutorial")
	Quests.onJoin(fp2)
	assert(d2.tutorial == Q.TUTORIAL_DONE and d2.money == mm, "saltar el tutorial")
	forget(fp, fp2)
end)

step("Datos: partidas antiguas cargan bien, la basura se rechaza y todo se guarda", function()
	local old = G.Data.sanitize({ money = 50, speed = 10, gods = { zeus = 1 }, boosts = { speed = 5 } }, C)
	assert(old.money == 50 and old.gods.zeus == 1 and old.boosts.speed == 5, "lo antiguo no se conserva")
	assert(old.missions.day == 0 and #old.missions.list == 0 and old.missions.rr == 0, "misiones por defecto")
	assert(old.daily.last == 0 and old.daily.streak == 0 and old.tutorial == 0 and old.boosts.luck == 0, "racha/tutorial/suerte por defecto")
	local junk = G.Data.sanitize({
		missions = {
			day = "x",
			rr = -5,
			list = { { id = "fake", goal = 1 }, { id = "steal", goal = 5, progress = 999, claimed = "yes" }, { id = "steal", goal = 3 }, "basura", { id = "open", goal = 0 / 0, progress = -3 }, { id = "train", goal = 1e12, progress = 1e12 }, { id = "combo" } },
		},
		daily = { last = math.huge, streak = "mucho" },
		tutorial = 99,
		boosts = { luck = 0 / 0 },
	}, C)
	local l = junk.missions.list
	assert(#l == Q.PER_DAY, "lista: " .. #l)
	assert(l[1].id == "steal" and l[1].progress == 5 and l[1].claimed == false, "progreso sin tope o reclamado falso")
	assert(l[2].id == "open" and l[2].goal == C.QUEST_BY_ID.open.goal and l[2].progress == 0, "meta rota")
	assert(l[3].id == "train" and l[3].goal == 1e6 and l[3].progress == 1e6, "meta enorme")
	assert(junk.missions.day == 0 and junk.missions.rr == 0, "día o cambios rotos")
	assert(junk.daily.last == 0 and junk.daily.streak == 0, "racha rota")
	assert(junk.tutorial == Q.TUTORIAL_DONE and junk.boosts.luck == 0, "tutorial o suerte rotos")
	for _, bad in ipairs({ "basura", 42, { list = "no" } }) do
		local dd = G.Data.sanitize({ missions = bad, daily = bad }, C)
		assert(#dd.missions.list == 0 and dd.daily.streak == 0 and dd.missions.day == 0, "basura: " .. typeof(bad))
	end
	-- guardar y cargar de verdad (DataStore real, clave de prueba)
	G.Data.KEY_PREFIX = "test_q_" .. os.time() .. "_"
	local fp = { UserId = 778 }
	local d = G.Data.load(fp, C)
	d.missions = { day = today, rr = 1, list = { { id = "open", goal = 5, progress = 3, claimed = false } } }
	d.daily = { last = today, streak = 6 }
	d.tutorial = 4
	d.boosts.luck = os.time() + 300
	assert(G.Data.save(fp), "guardar")
	G.Data.profiles[fp] = nil
	local d2, st = G.Data.load(fp, C)
	assert(st == "existing" and d2.missions.day == today and d2.missions.list[1].progress == 3 and d2.missions.rr == 1, "misiones no guardadas")
	assert(d2.daily.streak == 6 and d2.daily.last == today and d2.tutorial == 4 and d2.boosts.luck > os.time(), "racha, tutorial o suerte no guardados")
	game:GetService("DataStoreService"):GetDataStore(G.Data.STORE_NAME):RemoveAsync(G.Data.KEY_PREFIX .. 778)
	G.Data.profiles[fp] = nil
	G.Data.KEY_PREFIX = "u_"
end)

step("Suerte: el boost multiplica tu suerte y cuenta al abrir los sobres", function()
	local fp, d, s = fakePlayer(-360)
	assert(select(3, G.Core.mults(fp)) == 1 and G.Core.personalLuck(fp) == 1, "suerte base")
	local msg = Quests.give(fp, { kind = "luck", mins = 10 })
	assert(msg[1] == "rewardLuck" and msg[2] == 10, "aviso del premio")
	assert(select(3, G.Core.mults(fp)) == Q.LUCK_BOOST and G.Core.personalLuck(fp) == Q.LUCK_BOOST, "el boost no cuenta")
	s.passes.luck2x = true
	G.Core.invalidate(fp)
	assert(select(3, G.Core.mults(fp)) == 2 * Q.LUCK_BOOST, "pase + boost")
	G.serverLuckUntil = os.clock() + 60
	G.Core.invalidate(fp)
	assert(select(3, G.Core.mults(fp)) == 6 * Q.LUCK_BOOST and G.Core.personalLuck(fp) == 2 * Q.LUCK_BOOST, "suerte del servidor")
	G.serverLuckUntil = 0
	s.passes.luck2x = nil
	d.boosts.luck = os.time() - 1
	G.Core.invalidate(fp)
	assert(select(3, G.Core.mults(fp)) == 1, "el boost no caduca")
	-- la suerte ya no cambia el sobre al llegar a casa: cuenta al ABRIRLO (suerte del sobre × la tuya)
	assert(G.Packs.luckUpgrade == nil, "sigue la mejora al llegar a casa")
	d.boosts.luck = os.time() + 600
	assert(math.abs(G.Core.openLuck(fp, 100) - 100 * Q.LUCK_BOOST) < 1e-6, "el boost no cuenta al abrir")
	d.luckLevel = 5
	assert(math.abs(G.Core.openLuck(fp, 100) - 100 * Q.LUCK_BOOST * C.luckMult(5)) < 1e-6, "el nivel de suerte no cuenta al abrir")
	d.luckLevel = 1
	d.boosts.luck = 0
	forget(fp)
end)

step("Estado del cliente: misiones solo cuando cambian, boost de suerte y suerte del servidor", function()
	local fp, d = fakePlayer(-370)
	Quests.onJoin(fp)
	local sent = {}
	local saved = G.Net.State
	G.Net.State = { FireClient = function(_, _, payload)
		table.insert(sent, payload)
	end }
	d.boosts.luck = os.time() + 120
	local ok, err = pcall(function()
		G.Core.sendState(fp)
		G.Core.sendState(fp)
		Quests.event(fp, d.missions.list[1].id, 1)
		G.Core.sendState(fp)
	end)
	G.Net.State = saved
	assert(ok, tostring(err))
	local q1 = sent[1].quests
	assert(q1 and #q1.missions == Q.PER_DAY and q1.tutorial == 1 and q1.dailyCan == true and q1.rr == Q.REROLLS, "el primer estado no lleva las misiones")
	assert(sent[2].quests == nil, "manda las misiones sin cambios")
	assert(sent[3].quests and sent[3].quests.missions[1].progress == 1, "no mandó el progreso")
	assert(sent[1].luckLeft > 100 and sent[1].luckLeft <= 120 and sent[1].spawnLuck == 1, "suerte en el estado")
	forget(fp)
end)

add(fails == 0 and "🎉 TODO OK" or ("⚠️ FALLOS: " .. fails))
return table.concat(out, "\n")
