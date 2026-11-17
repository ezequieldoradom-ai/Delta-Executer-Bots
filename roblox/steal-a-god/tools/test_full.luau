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
		G.World.setStatue(plot, i, G.Config.GODS[((i - 1) % #G.Config.GODS) + 1])
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
	end
end)

-- Ciclo día/noche
step("Noche y amanecer", function()
	G.Packs.nightfall()
	G.Packs.refreshAll()
end)

add(fails == 0 and "🎉 TODO OK" or ("⚠️ FALLOS: " .. fails))
return table.concat(out, "\n")
