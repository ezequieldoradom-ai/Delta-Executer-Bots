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
	local function optional(name)
		local m = Server:FindFirstChild(name)
		return m and require(m) or nil
	end
	G.AuraFx = optional("AuraFx")
	G.PackStyle = optional("PackStyle")
	G.Vendors = optional("Vendors")
end)
step("Red", function() G.Net.init() end)
step("Avatares", function() G.Avatars = require(Server.Avatars); G.Avatars.init(G) end)
step("Modelos 3D", function() require(Server.Models).load(G.Config); assert(game.ReplicatedStorage.GodTemplates:FindFirstChild("zeus"), "sin zeus"); assert(game.ReplicatedStorage.GodTemplates:FindFirstChild("minotaur"), "sin minotauro") end)
step("Construir mundo", function()
	if G.AuraFx and G.AuraFx.init then G.AuraFx.init(G) end
	if G.PackStyle and G.PackStyle.init then G.PackStyle.init(G) end
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
	local fp, _, s = fakePlayer(-106)
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
		assert(lights == 1 and emitters == 1 and spin == 1, string.format("zona %d: luces %d emisores %d discos %d", i, lights, emitters, spin))
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
	G.Packs.grab(fp, pack)
	assert(pack.state == "carried" and s.carrying == pack and pack.carrier == fp and pack.prompt.Enabled == false, "no lo cogió")
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

add(fails == 0 and "🎉 TODO OK" or ("⚠️ FALLOS: " .. fails))
return table.concat(out, "\n")
