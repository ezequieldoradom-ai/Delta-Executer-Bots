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
	G.serverLuckUntil = 0
end)
step("Red", function() G.Net.init() end)
step("Avatares", function() G.Avatars = require(Server.Avatars) G.Avatars.init(G) end)
step("Modelos 3D", function() require(Server.Models).load(G.Config) assert(game.ReplicatedStorage.GodTemplates:FindFirstChild("zeus"), "sin zeus") assert(game.ReplicatedStorage.GodTemplates:FindFirstChild("minotaur"), "sin minotauro") end)
step("Construir mundo", function() G.World.init(G) end)
step("Iniciar sistemas", function()
	G.DayNight.init(G)
	G.Combat.init(G)
	G.Packs.init(G)
	G.Shop.init(G)
	G.Boards.init(G)
	G.Core.init(G)
end)
step("Amanecer (sobres)", function() G.Packs.refreshAll() end)
add("   Sobres creados:", (function() local n = 0 for _ in pairs(G.Packs.list) do n += 1 end return n end)())
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


---------------------------------------------------------------------
-- PRUEBAS DE SEGURIDAD, DATOS Y COMPRAS (jugadores simulados)
---------------------------------------------------------------------
local noop = { FireClient = function() end, FireAllClients = function() end }
G.Net.State, G.Net.Toast, G.Net.Offer, G.Net.Reveal, G.Net.Announce, G.Net.Knock = noop, noop, noop, noop, noop, noop
local C = G.Config
local function fakePlayer(id)
	local fp = { UserId = id, DisplayName = "Test" .. math.abs(id), Name = "Test" .. math.abs(id), Character = nil }
	G.Data.profiles[fp] = G.Data.sanitize(nil, C)
	G.Core.sessions[fp] = { passes = {}, combo = 1, lastTap = 0, lastHit = 0, invulnUntil = 0, afk = false, joinedAt = os.clock(), actionTimes = {}, comboTarget = 0.5 }
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

step("Combo: el servidor decide el acierto", function()
	local fp, d, s = fakePlayer(-106)
	s.onTreadmill = true
	s.comboTarget = 0.5
	-- marcador en el extremo (1.0): fallo aunque el cliente diga que acertó
	local tMiss = (math.pi / 2) / 2.6
	assert(G.Core.handleCombo(fp, tMiss) == false and s.combo == 1, "aceptó un fallo")
	s.lastTap = 0
	-- marcador en el centro (0.5): acierto
	assert(G.Core.handleCombo(fp, 0) == true and s.combo == 1.5, "rechazó un acierto")
	-- demasiado rápido: ignorado
	assert(G.Core.handleCombo(fp, 0) == false, "aceptó toques demasiado seguidos")
	-- fuera de la cinta: ignorado
	s.lastTap, s.onTreadmill = 0, false
	assert(G.Core.handleCombo(fp, 0) == false, "aceptó combo fuera de la cinta")
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

add(fails == 0 and "🎉 TODO OK" or ("⚠️ FALLOS: " .. fails))
return table.concat(out, "\n")
