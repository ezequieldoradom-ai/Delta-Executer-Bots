-- Prueba completa de Lucky Obby Race en un servidor de Roblox (sin jugadores reales: jugadores de mentira)
local RS = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared = RS:WaitForChild("Shared")
local out, fails = {}, 0
local function add(...)
	table.insert(out, table.concat({ ... }, " "))
end
local function step(name, fn)
	local ok, err = pcall(fn)
	if ok then
		add("✅ " .. name)
	else
		fails += 1
		add("❌ " .. name .. " -> " .. tostring(err))
	end
end

local noop = { FireClient = function() end, FireAllClients = function() end, OnServerEvent = { Connect = function() end } }
local G = { Config = require(Shared.Config), Net = { State = noop, Event = noop, Knock = noop, Use = noop } }
local C = G.Config

step("Cargar módulos", function()
	G.Data = require(Server.Data)
	G.Course = require(Server.Course)
	G.Race = require(Server.Race)
	G.Items = require(Server.Items)
	G.Lobby = require(Server.Lobby)
	G.Course.init(G)
	G.Lobby.init(G)
	G.Items.init(G)
end)

step("Recorrido: salida, puntos de control, meta y todos los tipos de tramo", function()
	local f = G.Course.build(12345)
	assert(f and f.Parent == workspace, "sin recorrido")
	local n = 0
	for i in pairs(G.Course.checkpoints) do
		n = math.max(n, i)
	end
	assert(n == math.floor((C.COURSE.SEGMENTS - 1) / C.COURSE.CHECKPOINT_EVERY), "puntos de control: " .. n)
	assert(G.Course.finishZ > C.COURSE.SEGMENTS * C.COURSE.SEG_LEN, "meta")
	-- en varias semillas salen todos los tipos y nunca el mismo dos veces seguidas
	local seen = {}
	for seed = 1, 12 do
		G.Course.build(seed)
		for i, k in ipairs(G.Course.kinds) do
			seen[k] = true
			assert(i == 1 or G.Course.kinds[i - 1] ~= k, "tramo repetido")
		end
	end
	for _, k in ipairs(G.Course.TYPES) do
		assert(seen[k], "nunca sale " .. k)
	end
	local parts = 0
	for _, d in ipairs(workspace.Course:GetDescendants()) do
		if d:IsA("BasePart") then
			parts += 1
		end
	end
	add("   piezas por recorrido: " .. parts .. " · largo " .. math.floor(G.Course.length) .. " studs")
	-- un punto de control se reconoce por la posición
	local cp = G.Course.checkpoints[1]
	assert(G.Course.checkpointAt(cp.pos) == 1, "punto de control 1")
	assert(G.Course.checkpointAt(cp.pos + Vector3.new(0, -40, 0)) == nil, "debajo no cuenta")
end)

step("Lucky block: los de detrás reciben objetos mejores", function()
	local function share(p)
		local strong, weak, N = 0, 0, 20000
		for k = 0, N - 1 do
			local x = (k + 0.5) / N
			local id = C.rollItem(p, function()
				return x
			end)
			local tier = C.ITEM_BY_ID[id].tier
			if tier == 3 then
				strong += 1
			elseif tier == 1 then
				weak += 1
			end
		end
		return strong / N, weak / N
	end
	local s0, w0 = share(0)
	local s1, w1 = share(1)
	add(string.format("   primero: %.0f %% fuertes, %.0f %% flojos · último: %.0f %% fuertes, %.0f %% flojos", s0 * 100, w0 * 100, s1 * 100, w1 * 100))
	assert(s1 > s0 * 5 and w0 > w1 * 2, "el puesto no cambia los objetos")
end)

-- jugadores de mentira en carrera
local function fake(id, progress)
	local fp = { UserId = id, DisplayName = "P" .. id }
	G.Data.profiles[fp] = { coins = 0, wins = 0 }
	local s = G.Race.newSession(fp)
	s.racing, s.progress, s.cp = true, progress, 0
	return fp, s
end

step("Puestos en directo, llegada a meta y monedas", function()
	table.clear(G.Race.finishers)
	G.Race.startedAt = os.clock()
	G.Race.endsAt = os.clock() + 100
	local a = fake(1, 100)
	local b = fake(2, 300)
	local c = fake(3, 200)
	assert(G.Race.rankOf(b) == 1 and G.Race.rankOf(c) == 2 and G.Race.rankOf(a) == 3, "orden por avance")
	assert(G.Race.finish(a) == true and G.Race.rankOf(a) == 1, "el que llega va primero")
	assert(G.Race.finish(a) == false, "llegó dos veces")
	assert(G.Data.coins(a) == C.REWARDS[1] + C.REWARD_FINISH and G.Data.profiles[a].wins == 1, "premio del primero")
	G.Race.finish(c)
	assert(G.Data.coins(c) == C.REWARDS[2] + C.REWARD_FINISH and G.Data.profiles[c].wins == 0, "premio del segundo")
	assert(G.Race.endsAt <= os.clock() + C.ROUND.AFTER_WINNER + 0.1, "tras el primero, cuenta atrás")
	for _, p in ipairs({ a, b, c }) do
		G.Race.sessions[p] = nil
	end
end)

step("Objetos: dar, usar una vez, escudo que bloquea y cambiazo", function()
	table.clear(G.Race.finishers)
	local a, sa = fake(11, 50)
	local b, sb = fake(12, 400)
	-- lucky block
	local id = G.Items.grant(a)
	assert(id and C.ITEM_BY_ID[id] and sa.rolling, "no dio lucky block")
	assert(G.Items.grant(a) == nil, "dos lucky blocks a la vez")
	task.wait(C.ROLL_TIME + 0.2)
	assert(sa.item == id and not sa.rolling, "el objeto no llegó")
	-- escudo: bloquea un golpe y se gasta
	sb.shieldUntil = os.clock() + 5
	assert(G.Items.knock(b, Vector3.new(0, 10, 50), a, "rock") == false and sb.shieldUntil == 0, "el escudo no bloqueó")
	assert(G.Items.knock(b, Vector3.new(0, 10, 50), a, "rock") == true, "sin escudo no empuja")
	-- congelar: a los demás
	sa.item = "freeze"
	assert(G.Items.use(a, Vector3.new(0, 0, 100)) == true and sa.item == nil, "no usó congelación")
	assert(sb.frozenUntil and sb.frozenUntil > os.clock(), "no congeló al otro")
	assert(not sa.frozenUntil, "se congeló a sí mismo")
	-- un objeto solo se usa una vez
	assert(G.Items.use(a, Vector3.new(0, 0, 100)) == false, "usó un objeto que ya no tiene")
	for _, p in ipairs({ a, b }) do
		G.Race.sessions[p] = nil
	end
end)

step("Monedas y victorias: guardar y cargar no rompe nada sin jugador real", function()
	local fp = { UserId = 99 }
	G.Data.profiles[fp] = { coins = 5, wins = 1 }
	G.Data.addCoins(fp, 10.7)
	assert(G.Data.coins(fp) == 15, "monedas")
	G.Data.addCoins(fp, -50)
	assert(G.Data.coins(fp) == 15, "monedas negativas")
end)

add(fails == 0 and "🎉 TODO OK" or ("⚠️ FALLOS: " .. fails))
return table.concat(out, "\n")
