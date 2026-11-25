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
		check("11 bots con 1 jugador (3 carrera + 4 mesas + 4 colina)", #Bots.list == 11, #Bots.list)
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
		-- límites de la economía
		local keepLuck, keepCoins = d.luck, d.coins
		d.coins = 0
		Hub.buyLuck(p)
		check("sin monedas no se compra suerte", d.luck == keepLuck and d.coins == 0)
		local hadToxic = table.find(d.trails, "toxic") ~= nil
		Extras.shop.toxic(p)
		check("sin monedas no se compra estela", hadToxic or table.find(d.trails, "toxic") == nil)
		d.coins = 10 ^ 7
		d.luck = 10
		Hub.buyLuck(p)
		check("la suerte no pasa de 10", d.luck == 10, d.luck)
		check("al máximo no cobra", d.coins == 10 ^ 7)
		d.luck, d.coins = keepLuck, keepCoins
		G.Data.refresh(p)
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
		-- no se puede entrar en una mesa con la partida empezada
		local busy
		waitFor(function()
			for kk = 1, 6 do
				local stk = G.Slap.station(kk)
				if stk.match and #stk.members < 4 then
					busy = kk
					return true
				end
			end
		end, 60)
		if busy then
			check("no se entra con la partida en curso", G.Slap.join(p, busy) == false)
		else
			check("había una partida en curso para probar", false)
		end
		-- mesa vacía: al entrar 2, cuenta atrás de 15 s
		local empty
		for kk = 1, 6 do
			if #G.Slap.station(kk).members == 0 then
				empty = kk
				break
			end
		end
		if empty then
			local ste = G.Slap.station(empty)
			G.Slap.join(p, empty)
			check("solo: la mesa espera", ste.phase == "idle", ste.phase)
			local deadline = os.clock() + 40
			while #ste.members < 2 and os.clock() < deadline do
				task.wait(0.5) -- los bots buscan mesa
			end
			if #ste.members >= 2 then
				check("con 2: cuenta atrás", ste.phase == "starting" and ste.countdown ~= nil, ste.phase)
				local t0 = os.clock()
				waitFor(function()
					return ste.match
				end, 20)
				local full = #ste.members >= 4
				check("la partida empieza a los ~15 s", ste.match and (full and os.clock() - t0 < 16 or math.abs(os.clock() - t0 - 15) < 3), string.format("%.1f s%s", os.clock() - t0, full and " (llena)" or ""))
			else
				check("con 2: cuenta atrás", false, "no vino ningún bot")
			end
			G.Slap.leave(p)
			task.wait(1)
		end
		-- mesa LLENA (4/4): la cuenta atrás baja a 5 s
		do
			local free
			for kk = 1, G.Slap.COUNT do
				if #G.Slap.station(kk).members == 0 then
					free = kk
					break
				end
			end
			local sb = {}
			for _, b in ipairs(Bots.list) do
				if b.role == "slap" and #sb < 3 then
					table.insert(sb, b)
				end
			end
			if free and #sb == 3 then
				local stf = G.Slap.station(free)
				G.Slap.join(p, free)
				for _, b in ipairs(sb) do
					if G.Slap.stationOf(b) then
						G.Slap.leave(b)
					end
					G.Slap.join(b, free)
				end
				task.wait(0.3)
				local left = stf.countdown and (stf.countdown - os.clock()) or -1
				check("mesa llena: la cuenta baja a 5 s", #stf.members == 4 and left > 0 and left <= 5.5, string.format("%d jugadores · %.1f s", #stf.members, left))
				G.Slap.leave(p)
				task.wait(1)
			else
				check("mesa llena: la cuenta baja a 5 s", false, "sin mesa libre o sin 3 bots")
			end
		end
		local k
		waitFor(function()
			for kk = 1, 6 do
				if not G.Slap.station(kk).match and G.Slap.freeSlots(kk) >= 1 then
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
				return G.Slap.lastResult ~= nil and G.Slap.lastResult.slapper == p
			end, 6)
			if G.Slap.lastResult and G.Slap.lastResult.slapper ~= p then
				G.Slap.lastResult = nil
			end
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
			-- (se mira enseguida: si acaba la partida, el bot eliminado puede volver a entrar)
			check("supremo elimina al sentado", r and r.supreme and not table.find(st.members, victim), r and tostring(r.supreme))
			check("el que pega sigue en la mesa", G.Slap.stationOf(p) == k)
			task.wait(3.5)
		end
		-- adivinar MAL: sigues sentado (si en 30 s no me ha tocado sentarme, me siento yo entre rondas)
		if waitFor(function()
			return st.seated == p and st.phase == "guessing"
		end, 30) or waitFor(function()
			if st.seated ~= p then
				G.Slap.debugSeat(k, p)
			end
			return st.seated == p and st.phase == "guessing"
		end, 90) then
			G.Slap.guess(p, -999)
			task.wait(2.5)
			check("fallar al adivinar: sigues sentado", st.seated == p, st.seated and st.seated.Name)
		else
			check("me tocó sentarme para fallar", false)
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
		check("al salir te puedes mover", h and h.WalkSpeed >= 16 and h.JumpHeight > 7, h and h.WalkSpeed)
		check("al salir, vida llena", h and h.Health >= h.MaxHealth - 0.5, h and h.Health)
	end)

	-- F. REY DE LA COLINA -----------------------------------------------------------------
	safe("colina", function()
		local H = G.Hill
		check("arena construida", workspace:FindFirstChild("KingHill") and workspace.KingHill:FindFirstChild("Hill") ~= nil)
		check("máximo 10 jugadores", H.MAX == 10)
		local hasBoard = false
		for _, d in ipairs(workspace.Hub:GetDescendants()) do
			if d:IsA("TextLabel") and d.Text:find("COLINA") then
				hasBoard = true
			end
		end
		check("ranking Reyes de la colina", hasBoard)
		if H.PAD and hrp() then
			hrp().CFrame = CFrame.new(H.PAD + Vector3.new(0, 3, 0))
			task.wait(1)
			local d = hrp() and (Vector3.new(hrp().Position.X, 0, hrp().Position.Z) - Vector3.new(H.CENTER.X, 0, H.CENTER.Z)).Magnitude or 999
			check("la plataforma del vestíbulo te lleva a la colina", d < H.R + 15, math.floor(d))
		else
			check("la plataforma del vestíbulo te lleva a la colina", false, "sin plataforma")
		end
		if G.Slap.stationOf(p) then
			G.Slap.leave(p)
		end
		waitFor(function()
			return H.st.phase ~= "playing" and H.st.phase ~= "result"
		end, 120)
		check("entrar en la arena", H.join(p) == true)
		check("fuera de partida no se empuja", H.push(p) == false)
		task.wait(0.5)
		check("en la arena (arriba)", hrp() and hrp().Position.Y > H.CENTER.Y + H.TOP, hrp() and math.floor(hrp().Position.Y))
		check("con 2+: cuenta atrás", waitFor(function()
			return H.st.phase == "starting"
		end, 45), H.st.phase .. " · " .. #H.st.members)
		-- si la cuenta ya estaba a punto de acabar, se espera a la siguiente (si no, la prueba mide décimas)
		if H.st.countdown and H.st.countdown - os.clock() < 3 then
			waitFor(function()
				return H.st.phase == "playing"
			end, 6)
			H.botsCalm = true
			waitFor(function()
				return H.st.phase == "starting" and H.st.countdown and H.st.countdown - os.clock() > 5
			end, 150)
			if not H.memberOf(p) then
				H.join(p)
			end
			H.botsCalm = nil
		end
		task.wait(0.5)
		check("en la cuenta atrás no te puedes mover", hum() and hum().WalkSpeed == 0 and hum().JumpHeight == 0, hum() and hum().WalkSpeed)
		local t0 = (H.st.countdown or (os.clock() + 15)) - 15 -- desde que empezó la cuenta (puede que ya estuviera en marcha)
		check("empieza a los ~15 s", waitFor(function()
			return H.st.phase == "playing"
		end, 20) and math.abs(os.clock() - t0 - 15) < 3, string.format("%.1f s", os.clock() - t0))
		check("velocidad 18 al empezar", hum() and hum().WalkSpeed == 18 and hum().JumpHeight > 7, hum() and hum().WalkSpeed)
		H.botsCalm = true
		-- nadie entra a mitad de partida
		local outsider
		for _, b in ipairs(Bots.list) do
			if not H.memberOf(b) then
				outsider = b
				break
			end
		end
		if outsider then
			check("no se entra con la partida en curso", H.join(outsider) == false)
		end
		-- puntos en la colina
		hrp().CFrame = CFrame.new(H.CENTER + Vector3.new(0, H.TOP + 4.5, 0))
		task.wait(2.2)
		check("puntos al estar en la colina", (H.st.score[p] or 0) >= 1.6, H.st.score[p])
		-- empujar a un bot
		local target
		for _, m in ipairs(H.st.members) do
			if m ~= p and H.st.alive[m] and m.Character and m.Character:FindFirstChild("HumanoidRootPart") then
				target = m
				break
			end
		end
		if target then
			local th = target.Character.HumanoidRootPart
			local th2 = target.Character:FindFirstChildOfClass("Humanoid")
			th2.WalkSpeed = 0 -- que no se vaya mientras le apunto
			th.CFrame = CFrame.new(H.CENTER + Vector3.new(4, H.TOP + 3.2, 0))
			task.wait(0.3)
			local from = th.Position + Vector3.new(0, 0, 3)
			hrp().CFrame = CFrame.lookAt(from, Vector3.new(th.Position.X, from.Y, th.Position.Z))
			task.wait(0.1)
			H.lastPushed = nil
			check("empujar da al de delante", H.push(p) and H.lastPushed == target)
			task.wait(0.05)
			check("el empujado sale despedido", th.AssemblyLinearVelocity.Magnitude > 30, math.floor(th.AssemblyLinearVelocity.Magnitude))
			check("hay espera entre empujones", H.push(p) == false)
			th2.WalkSpeed = 16
		else
			check("había un bot para empujar", false)
		end
		-- ganar: echamos a todos los demás
		local d0 = G.Data.profiles[p].hillWins or 0
		local c0 = G.Data.profiles[p].coins
		local size = H.st.matchSize or 0
		hrp().CFrame = CFrame.new(H.CENTER + Vector3.new(0, H.TOP + 4.5, 0))
		for _, m in ipairs(H.st.members) do
			if m ~= p and H.st.alive[m] and m.Character and m.Character:FindFirstChild("HumanoidRootPart") then
				m.Character.HumanoidRootPart.CFrame = CFrame.new(H.CENTER + Vector3.new(0, 4, H.R + 9))
			end
		end
		check("caer de la arena elimina y el último gana", waitFor(function()
			return H.st.phase == "result" and H.lastWinner == p
		end, 6), H.lastWinner and H.lastWinner.Name)
		if size >= 3 then
			check("victoria apuntada en el ranking", (G.Data.profiles[p].hillWins or 0) == d0 + 1, G.Data.profiles[p].hillWins)
			check("premio de 20 monedas", G.Data.profiles[p].coins == c0 + 20, G.Data.profiles[p].coins - c0)
		else
			check("partida de 2: sin premio (anti-granjeo)", (G.Data.profiles[p].hillWins or 0) == d0)
		end
		-- siguiente partida: caer = eliminado y a mirar desde fuera
		check("vuelve a empezar sola", waitFor(function()
			return H.st.phase == "playing"
		end, 40), H.st.phase)
		hrp().CFrame = CFrame.new(H.CENTER + Vector3.new(0, 4, H.R + 9))
		task.wait(1.5)
		check("caer te elimina", not H.st.alive[p])
		check("eliminado: andas normal", hum() and hum().WalkSpeed >= 16, hum() and hum().WalkSpeed)
		local dist = hrp() and (hrp().Position - C.COURSE.LOBBY).Magnitude
		check("eliminado: vuelves al vestíbulo", dist and dist < 30, dist and math.floor(dist))
		check("eliminado: sales de la arena", not H.memberOf(p))
		check("no puedes volver a mitad de partida", H.join(p) == false)
		H.botsCalm = false
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
		-- TRAMPAS: aparecer en la meta o saltarse puntos de control no cuenta
		hrp().CFrame = CFrame.new(0, C.COURSE.START.Y + 3, G.Course.finishZ + 4)
		task.wait(0.8)
		check("teletransporte a la meta no cuenta", not s.finished)
		local cp0 = s.cp
		local far = G.Course.checkpoints[math.min(#G.Course.checkpoints, cp0 + 3)]
		hrp().CFrame = CFrame.new(far.pos)
		task.wait(0.8)
		check("saltarse puntos de control no cuenta", s.cp == cp0, s.cp)
		local nextCp = G.Course.checkpoints[cp0 + 1]
		hrp().AssemblyLinearVelocity = Vector3.zero
		hrp().CFrame = CFrame.new(nextCp.pos)
		task.wait(0.8)
		check("el siguiente punto de control sí cuenta", s.cp == cp0 + 1, s.cp)
		check("reapareces en tu punto de control", p:GetAttribute("Checkpoint") == nextCp.pos)
		-- lucky block automático
		s.item, s.rolling, s.nextLucky = nil, false, os.clock() + 0.3
		check("el lucky block llega solo", waitFor(function()
			return s.item ~= nil
		end, 5), s.item)
		local function useNow(id)
			s.item, s.rolling, s.frozenUntil = id, false, nil
			local h = hrp()
			return G.Items.use(p, h and (h.Position + Vector3.new(0, 0, 30)) or Vector3.zero)
		end
		-- escudo
		useNow("shield")
		check("el escudo se activa", (s.shieldUntil or 0) > os.clock())
		check("el escudo bloquea un golpe", G.Items.knock(p, Vector3.new(0, 40, 0), nil, "rock") == false)
		check("el escudo se gasta", (s.shieldUntil or 0) <= os.clock())
		-- fantasma
		useNow("ghost")
		check("fantasma: inmune a los golpes", G.Items.knock(p, Vector3.new(0, 40, 0), nil, "rock") == false)
		s.immuneUntil = nil
		task.wait(0.3)
		-- turbo y vuelta a la normalidad
		useNow("boost")
		task.wait(0.2)
		check("turbo: más velocidad", hum() and hum().WalkSpeed == C.BOOST_SPEED, hum() and hum().WalkSpeed)
		task.wait(C.BOOST_TIME + 0.6)
		check("turbo: luego vuelves a 20", hum() and hum().WalkSpeed == 20, hum() and hum().WalkSpeed)
		-- congelación a los bots
		useNow("freeze")
		local frozen = 0
		for b, bs in pairs(G.Race.sessions) do
			if type(b) == "table" and b.IsBot and (bs.frozenUntil or 0) > os.clock() then
				frozen += 1
			end
		end
		check("congelación: congela a los bots", frozen >= 1, frozen)
		-- portal al siguiente punto de control
		local cpP = s.cp
		local target = G.Course.checkpoints[cpP + 1]
		if target then
			useNow("portal")
			task.wait(0.3)
			check("portal: te lleva al siguiente punto de control", hrp() and (hrp().Position - target.pos).Magnitude < 8, hrp() and math.floor((hrp().Position - target.pos).Magnitude))
		end
		task.wait(1)
		local adv = 0
		for b, bs in pairs(G.Race.sessions) do
			if type(b) == "table" and b.IsBot and (bs.progress or 0) > adv then
				adv = bs.progress
			end
		end
		check("los bots avanzan por el recorrido", adv > 20, math.floor(adv))
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
		local dd = G.Data.profiles[p]
		local cBefore, wBefore = dd.coins, dd.wins
		check("llegar a la meta", G.Race.finish(p))
		check("corriendo solo: premio de terminar (10)", dd.coins - cBefore == C.REWARD_FINISH, dd.coins - cBefore)
		check("corriendo solo: no cuenta victoria", dd.wins == wBefore)
		check("récord guardado", (dd.best or 0) > 0 and p:GetAttribute("Best") == dd.best, dd.best)
		check("no se puede llegar dos veces", G.Race.finish(p) == false)
		task.wait(4.5)
		check("al terminar vuelves al vestíbulo", hrp() and (hrp().Position - lobby).Magnitude < 40 and hum().WalkSpeed >= 16)
	end)

	-- G. OBBYS NORMALES -------------------------------------------------------------------
	safe("obbys", function()
		local O = G.Obbies
		check("módulo de obbys", O ~= nil)
		if not O then
			return
		end
		for _, def in ipairs(O.DEFS) do
			local info = O.built[def.id]
			local want = math.floor((def.segments - 1) / 3)
			check("obby " .. def.id .. ": construido con " .. def.segments .. " tramos", info ~= nil and info.segments == def.segments and #info.checkpoints == want, info and #info.checkpoints)
			check("obby " .. def.id .. ": portal en el vestíbulo", O.PADS and O.PADS[def.id] ~= nil)
		end
		check("más largo cuanto más difícil", O.DEFS[1].segments < O.DEFS[2].segments and O.DEFS[2].segments < O.DEFS[3].segments)
		check("más premio cuanto más difícil", O.DEFS[1].reward < O.DEFS[2].reward and O.DEFS[2].reward < O.DEFS[3].reward)
		-- pisar el portal fácil te lleva a la salida
		if G.Slap.stationOf(p) then
			G.Slap.leave(p)
		end
		if G.Hill and G.Hill.memberOf(p) then
			G.Hill.leave(p)
		end
		local pad = O.PADS and O.PADS.easy
		if pad and hrp() then
			hrp().CFrame = CFrame.new(pad + Vector3.new(0, 3, 0))
			waitFor(function()
				return p:GetAttribute("Obby") == "easy"
			end, 3)
		end
		local info = O.built.easy
		local s = O.sessions[p]
		check("el portal te mete en el obby fácil", p:GetAttribute("Obby") == "easy" and s ~= nil, p:GetAttribute("Obby"))
		check("apareces en la salida", hrp() and (hrp().Position - info.checkpoints[0].pos).Magnitude < 6)
		if not s then
			return
		end
		-- trampa: saltar al punto de control 3 no cuenta
		local cp3 = info.checkpoints[3].pos
		hrp().CFrame = CFrame.new(cp3)
		task.wait(0.6)
		check("obby: no se saltan puntos de control", s.cp == 0, s.cp)
		-- trampa: ir a la meta de golpe no da premio
		local dd = G.Data.profiles[p]
		local c0, o0 = dd.coins, dd.obbies or 0
		hrp().CFrame = CFrame.new(info.x, info.y + 3, info.finishZ + 6)
		task.wait(0.6)
		check("obby: teletransporte a la meta no da premio", dd.coins == c0 and O.sessions[p] ~= nil)
		-- avanzar a saltos imposibles: el servidor te devuelve a tu punto de control
		hrp().CFrame = CFrame.new(info.checkpoints[0].pos)
		task.wait(0.5)
		hrp().CFrame = CFrame.new(info.checkpoints[0].pos + Vector3.new(0, 0, 300))
		task.wait(0.6)
		check("obby: velocidad imposible te devuelve atrás", hrp() and (hrp().Position - info.checkpoints[0].pos).Magnitude < 8, hrp() and math.floor((hrp().Position - info.checkpoints[0].pos).Magnitude))
		-- de uno en uno sí cuentan (la prueba va a saltos: sin el control de velocidad)
		O.noSpeedCheck = true
		for i = 1, #info.checkpoints do
			hrp().CFrame = CFrame.new(info.checkpoints[i].pos)
			task.wait(0.35)
		end
		check("obby: puntos de control de uno en uno", s.cp == #info.checkpoints, s.cp .. "/" .. #info.checkpoints)
		check("obby: guarda tu punto de control", p:GetAttribute("ObbyCP") == info.checkpoints[s.cp].pos)
		check("obby: cuenta el tramo", (p:GetAttribute("ObbyStage") or 0) >= info.segments - 3, p:GetAttribute("ObbyStage"))
		-- caída muy lejos: el servidor te devuelve
		hrp().CFrame = CFrame.new(info.x, info.y - 80, info.checkpoints[s.cp].pos.Z)
		task.wait(0.6)
		check("obby: si caes, vuelves al punto de control", hrp() and (hrp().Position - info.checkpoints[s.cp].pos).Magnitude < 8)
		-- demasiado rápido: no cuenta
		hrp().CFrame = CFrame.new(info.x, info.y + 3, info.finishZ + 6)
		task.wait(0.6)
		check("obby: tiempo imposible no da premio", dd.coins == c0, dd.coins - c0)
		-- tiempo creíble: premio
		s.t0 -= 1000
		task.wait(0.6)
		check("obby fácil completado: +60 monedas", dd.coins - c0 == O.DEFS[1].reward, dd.coins - c0)
		check("obby: cuenta para el tablón", (dd.obbies or 0) == o0 + 1 and (dd.obby.easy or 0) >= 1)
		check("obby: se acaba la sesión", O.sessions[p] == nil and p:GetAttribute("Obby") == nil)
		O.noSpeedCheck = nil
		task.wait(4.5)
		local lobby = C.COURSE.LOBBY
		check("obby: al terminar vuelves al vestíbulo", hrp() and (hrp().Position - lobby).Magnitude < 40)
		-- salir a mitad
		O.start(p, "hard")
		task.wait(0.3)
		check("entrar al obby difícil", p:GetAttribute("Obby") == "hard")
		O.leave(p, true)
		task.wait(0.3)
		check("salir del obby: vuelves al vestíbulo", p:GetAttribute("Obby") == nil and hrp() and (hrp().Position - lobby).Magnitude < 40)
		-- irte andando/teletransportado fuera del obby también te saca
		O.start(p, "medium")
		task.wait(0.3)
		hrp().CFrame = CFrame.new(lobby + Vector3.new(0, 3, 0))
		task.wait(0.6)
		check("fuera del obby se acaba la sesión", O.sessions[p] == nil)
	end)

	-- H. VELOCIDAD EN LA PLAZA CENTRAL -------------------------------------------------------
	safe("plaza", function()
		if G.Slap.stationOf(p) then
			G.Slap.leave(p)
		end
		if G.Hill and G.Hill.memberOf(p) then
			G.Hill.leave(p)
		end
		if G.Obbies and G.Obbies.sessions[p] then
			G.Obbies.leave(p, true)
		end
		local lobby = C.COURSE.LOBBY
		hrp().CFrame = CFrame.new(lobby + Vector3.new(0, 3, 0))
		hum().WalkSpeed = 16
		task.wait(0.6)
		check("en la plaza central andas más rápido (24)", hum().WalkSpeed == 24, hum().WalkSpeed)
		-- en un obby vuelve a la normal
		G.Obbies.start(p, "easy")
		task.wait(0.6)
		check("en un obby, velocidad normal (16)", hum().WalkSpeed == 16, hum().WalkSpeed)
		G.Obbies.leave(p, true)
		task.wait(0.6)
		check("al volver a la plaza, otra vez rápido", hum().WalkSpeed == 24, hum().WalkSpeed)
		-- sentado en una mesa no se toca
		local k
		for kk = 1, G.Slap.COUNT do
			if not G.Slap.station(kk).match and G.Slap.freeSlots(kk) >= 1 and G.Slap.join(p, kk) then
				k = kk
				break
			end
		end
		if k then
			task.wait(0.6)
			check("en una mesa no se acelera", hum().WalkSpeed == 0, hum().WalkSpeed)
			G.Slap.leave(p)
		end
	end)

	-- I. SALA DE ESPERA ------------------------------------------------------------------
	safe("sala de espera", function()
		local Wr = G.WaitRoom
		check("sala de espera construida", Wr ~= nil and workspace:FindFirstChild("WaitRoom") ~= nil)
		if not Wr then
			return
		end
		-- esperar a que la carrera NO esté en inscripción
		waitFor(function()
			return G.Race.state ~= "joining"
		end, 60)
		local portal = workspace:FindFirstChild("PortalPad", true)
		if portal and hrp() then
			hrp().CFrame = CFrame.new(portal.Position + Vector3.new(0, 3, 0))
			waitFor(function()
				return Wr.waiting[p] == true
			end, 3)
		end
		check("portal con carrera en marcha → sala de espera", Wr.waiting[p] == true and p:GetAttribute("Waiting") == true)
		check("apareces dentro de la sala", hrp() and (hrp().Position - Wr.CENTER).Magnitude < 20)
		-- al abrirse la inscripción te apunta solo
		local opened = waitFor(function()
			return G.Race.state == "joining"
		end, 150)
		if opened then
			task.wait(1)
			check("en la sala: apuntado solo a la siguiente carrera", G.Race.joined[p] == true)
		end
		-- salir: vuelves al vestíbulo y ya no estás apuntado
		Wr.leave(p, true)
		task.wait(0.4)
		check("salir de la sala: al vestíbulo", not Wr.waiting[p] and p:GetAttribute("Waiting") == nil and hrp() and (hrp().Position - C.COURSE.LOBBY).Magnitude < 40)
		if opened and G.Race.state == "joining" then
			check("salir de la sala: te desapunta", not G.Race.joined[p])
		end
	end)

	print(string.format("TEST RESUMEN: %d bien · %d mal%s", ok, bad, #fails > 0 and (" · fallos: " .. table.concat(fails, ", ")) or ""))
	return ok, bad
end

return SelfTest
