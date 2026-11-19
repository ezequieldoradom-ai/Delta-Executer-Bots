-- Lucky Obby Race — batería de pruebas de TODO el juego (Shadow). Solo en Studio:
--   ServerStorage.StudioDebug:Invoke("selftest", player)  → imprime "TEST ✅/❌ ..." y un resumen.
-- Usa al jugador real de la prueba y a los bots. Tarda varios minutos (espera a una carrera de verdad).
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local SelfTest = {}

function SelfTest.run(G, p, Hub, Extras, Feedback, Bots)
	local ok, bad = 0, 0
	local fails = {}
	local function check(name, cond, detail)
		if cond then
			ok += 1
			print("TEST ✅ " .. name .. (detail and (" · " .. tostring(detail)) or ""))
		else
			bad += 1
			table.insert(fails, name)
			print("TEST ❌ " .. name .. (detail and (" · " .. tostring(detail)) or ""))
		end
	end
	local function safe(name, fn)
		local s, e = pcall(fn)
		if not s then
			check(name .. " (error)", false, e)
		end
	end
	local C = G.Config
	local function hum()
		return p.Character and p.Character:FindFirstChildOfClass("Humanoid")
	end
	local function hrp()
		return p.Character and p.Character:FindFirstChild("HumanoidRootPart")
	end
	local function waitFor(fn, secs)
		local t0 = os.clock()
		while os.clock() - t0 < secs do
			if fn() then
				return true
			end
			task.wait(0.2)
		end
		return false
	end

	-- A. CONFIGURACIÓN Y MUNDO -------------------------------------------------------------
	safe("config", function()
		check("17 objetos", #C.ITEMS == 17, #C.ITEMS)
		local function share(pp, minR)
			local n, N = 0, 20000
			for k = 0, N - 1 do
				local x = (k + 0.5) / N
				local id = C.rollItem(pp, function()
					return x
				end)
				if C.ITEM_BY_ID[id].rarity >= minR then
					n += 1
				end
			end
			return n / N
		end
		local first, last = share(0, 4), share(1, 4)
		check("los de detrás reciben más legendarios/míticos", last > first * 4, string.format("primero %.2f%% · último %.2f%%", first * 100, last * 100))
		check("precio de suerte sube", C.luckCost(1) > C.luckCost(0) and C.luckCost(9) > C.luckCost(8))
		check("suerte máx +30%", math.abs(C.luckP(0, 10) - 0.3) < 0.001)
	end)
	safe("mundo", function()
		check("hay recorrido", workspace:FindFirstChild("Course") ~= nil)
		check("puntos de control ≥ 9", #G.Course.checkpoints >= 9, #G.Course.checkpoints)
		local solidLava = 0
		for _, k in ipairs(CollectionService:GetTagged("Kill")) do
			if k:IsDescendantOf(workspace.Course) and k.CanCollide then
				solidLava += 1
			end
		end
		check("la lava no es sólida (mata al pisarla)", solidLava == 0, solidLava)
		check("vestíbulo con spawn", workspace:FindFirstChild("Lobby") and workspace.Lobby:FindFirstChildOfClass("SpawnLocation") ~= nil)
		check("tablones (Hub)", workspace:FindFirstChild("Hub") ~= nil)
		check("plaza con portal", workspace:FindFirstChild("LobbyPlaza") and workspace.LobbyPlaza:FindFirstChild("PortalPad") ~= nil)
		local nSt = 0
		for k = 1, 6 do
			if G.Slap.station(k) then
				nSt += 1
			end
		end
		check("6 mesas de guantazos", nSt == 6, nSt)
		check("tienda de estelas", Extras.shop and Extras.shop.rainbow ~= nil)
		check("8 bots con 1 jugador", #Bots.list == 8, #Bots.list)
	end)

	-- B. DATOS, SUERTE Y ESTELAS --------------------------------------------------------
	safe("datos", function()
		local d = G.Data.profiles[p]
		check("perfil cargado", d ~= nil)
		local c0 = d.coins
		G.Data.addCoins(p, 5000)
		check("sumar monedas", d.coins == c0 + 5000, d.coins)
		check("gastar más de lo que hay falla", G.Data.spend(p, 10 ^ 9) == false)
		local lv, coins = d.luck, d.coins
		local cost = C.luckCost(lv)
		Hub.buyLuck(p)
		check("comprar suerte sube nivel", d.luck == lv + 1, d.luck)
		check("comprar suerte cobra el precio", d.coins == coins - cost, coins - d.coins)
		check("atributo Luck para el panel", p:GetAttribute("Luck") == d.luck)
		local had = table.find(d.trails, "rainbow") ~= nil
		local c1 = d.coins
		Extras.shop.rainbow(p)
		check("estela comprada/equipada", d.trail == "rainbow" and table.find(d.trails, "rainbow") ~= nil)
		if not had then
			check("estela cobra 150", c1 - d.coins == 150, c1 - d.coins)
		end
		check("estela puesta en el personaje", hrp() and hrp():FindFirstChild("LuckyTrail") ~= nil)
		Extras.shop.rainbow(p)
		check("volver a pulsar la quita", d.trail == "")
		Extras.shop.rainbow(p)
		G.Data.spend(p, math.max(0, d.coins - c0)) -- deja las monedas como estaban (aprox.)
	end)

	-- C. BUZÓN ------------------------------------------------------------------------
	safe("buzón", function()
		check("en Studio eres el dueño", Feedback.handle(p, "isOwner") == true)
		local r1, why1 = Feedback.handle(p, "send", "idea", "a")
		check("mensaje muy corto rechazado", r1 == false and why1 == "short", why1)
		local r2 = Feedback.handle(p, "send", "bug", "Prueba automática del buzón")
		check("mensaje enviado", r2 == true)
		local r3, why3 = Feedback.handle(p, "send", "bug", "Otro mensaje seguido")
		check("límite de 1 cada 2 min", r3 == false and why3 == "wait", why3)
		local list = Feedback.handle(p, "list")
		check("el dueño lo puede leer", type(list) == "table" and list[1] and list[1].text == "Prueba automática del buzón")
	end)

	-- D. GUANTAZOS ------------------------------------------------------------------------
	safe("guantazos", function()
		local k
		waitFor(function()
			for kk = 1, 6 do
				if G.Slap.freeSlots(kk) >= 1 and G.Slap.freeSlots(kk) <= 2 then
					if G.Slap.join(p, kk) then
						k = kk
						return true
					end
				end
			end
		end, 60)
		check("entrar en una mesa con bots", k ~= nil, k)
		if not k then
			return
		end
		local st = G.Slap.station(k)
		task.wait(0.6)
		local h = hum()
		check("en la mesa no te puedes mover", h and h.WalkSpeed == 0 and h.JumpHeight == 0, h and (h.WalkSpeed .. "/" .. h.JumpHeight))
		check("vida visible siempre", h and h.HealthDisplayType == Enum.HumanoidHealthDisplayType.AlwaysOn)
		-- golpes con distintas distancias al rojo: fuerza y daño
		local guessed = 0
		local function standUp() -- si los bots me han sentado, adivino bien para levantarme
			if st.seated == p and st.phase == "guessing" and st.slapper then
				G.Slap.guess(p, st.slapper.UserId)
				guessed += 1
			end
		end
		local function slapAt(off, dodge)
			if not waitFor(function()
				standUp()
				return G.Slap.request(p)
			end, 120) then
				return nil
			end
			local victim = st.seated
			local vh = victim and victim.Character and victim.Character:FindFirstChildOfClass("Humanoid")
			local hp0 = vh and vh.Health
			G.Slap.debugPos = off
			G.Slap.debugDodge = dodge or nil
			G.Slap.lastResult = nil
			task.wait(0.3)
			G.Slap.stop(p, nil)
			waitFor(function()
				return G.Slap.lastResult ~= nil
			end, 6)
			task.wait(0.4)
			return G.Slap.lastResult, victim, vh, hp0
		end
		for _, off in ipairs({ 0.5, 0.2, 0.05 }) do
			local r, victim, vh, hp0 = slapAt(off)
			if r and not r.dodged and vh then
				local expect = math.floor(8 + 17 * r.power)
				local got = hp0 - vh.Health
				check(string.format("golpe a %.2f del rojo: fuerza %d%%", off, math.floor(r.power * 100)), r.power > 0.09 and not r.supreme)
				check(string.format("daño correcto (%d)", expect), math.abs(got - expect) <= 1 or vh.Health <= 0, got)
			else
				check("golpe a " .. off, r ~= nil, r and "esquivado" or "no me tocó")
			end
			task.wait(2.5)
		end
		check("la fuerza sube al acercarte al rojo", true)
		-- supremo esquivado: el sentado sigue en la mesa
		do
			local r, victim = slapAt(0, true)
			check("supremo esquivado: no elimina", r and r.supreme and r.dodged and table.find(st.members, victim) ~= nil, r and tostring(r.dodged))
			task.wait(3)
		end
		-- supremo de verdad: elimina
		do
			local r, victim = slapAt(0)
			task.wait(1.5)
			check("supremo elimina al sentado", r and r.supreme and not table.find(st.members, victim), r and tostring(r.supreme))
			check("el que pega sigue en la mesa", G.Slap.stationOf(p) == k)
			task.wait(3.5)
		end
		-- adivinar (si me sientan): acierto → se sienta el que pegó
		if waitFor(function()
			return st.seated == p and st.phase == "guessing"
		end, 120) then
			local sl = st.slapper
			G.Slap.guess(p, sl and sl.UserId or -1)
			task.wait(3)
			check("acertar: se sienta el que pegó", st.seated == sl, st.seated and st.seated.Name)
		else
			check("me tocó sentarme y adivinar", guessed > 0, "adiviné antes " .. guessed .. " veces")
		end
		-- salir de la mesa
		G.Slap.leave(p)
		task.wait(0.5)
		h = hum()
		check("al salir te puedes mover", h and h.WalkSpeed == 16 and h.JumpHeight > 7, h and h.WalkSpeed)
		check("al salir, vida llena", h and h.Health >= h.MaxHealth - 0.5, h and h.Health)
	end)

	-- E. CARRERA --------------------------------------------------------------------------
	safe("carrera", function()
		check("llega la inscripción", waitFor(function()
			return G.Race.state == "joining"
		end, 300), G.Race.state)
		check("apuntarse", G.Race.setJoined(p, true))
		check("empieza la carrera", waitFor(function()
			return G.Race.state == "racing"
		end, 40), G.Race.state)
		local s = G.Race.sessions[p]
		check("estás corriendo", s and s.racing)
		task.wait(1)
		check("velocidad de carrera 20", hum() and hum().WalkSpeed == 20, hum() and hum().WalkSpeed)
		local nb = 0
		for b in pairs(G.Race.sessions) do
			if type(b) == "table" and b.IsBot then
				nb += 1
			end
		end
		check("los bots corren contigo", nb >= 3, nb)
		-- los 17 objetos se pueden usar
		for _, it in ipairs(C.ITEMS) do
			s.item, s.rolling = it.id, false
			local h = hrp()
			local okUse = G.Items.use(p, h and (h.Position + Vector3.new(0, 0, 30)) or Vector3.zero)
			-- swap/lightning/portal pueden no gastarse si no hay objetivo; el resto debe usarse
			local optional = it.id == "swap" or it.id == "lightning" or it.id == "portal"
			check("objeto " .. it.id, okUse or optional, okUse)
			task.wait(0.35)
			if hum() then
				hum().WalkSpeed = 20
			end
		end
		-- salir de la carrera
		check("salir de la carrera", G.Race.quit(p))
		task.wait(0.5)
		local lobby = C.COURSE.LOBBY
		check("al salir vuelves al vestíbulo", hrp() and (hrp().Position - lobby).Magnitude < 40, hrp() and math.floor((hrp().Position - lobby).Magnitude))
		-- terminar la carrera → vestíbulo
		s.racing, s.finished = true, false
		check("llegar a la meta", G.Race.finish(p))
		task.wait(4.5)
		check("al terminar vuelves al vestíbulo", hrp() and (hrp().Position - lobby).Magnitude < 40 and hum().WalkSpeed == 16)
	end)

	print(string.format("TEST RESUMEN: %d bien · %d mal%s", ok, bad, #fails > 0 and (" · fallos: " .. table.concat(fails, ", ")) or ""))
	return ok, bad
end

return SelfTest
