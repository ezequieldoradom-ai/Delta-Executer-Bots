-- Lucky Obby Race — "¿QUIÉN HA SIDO?" (Shadow, idea del dueño). Minijuego de la plaza para quien no corre.
-- 6 mesas de hasta 4 jugadores. Uno se sienta mirando al vacío; otro le da un guantazo por detrás y el sentado
-- tiene que adivinar quién fue. Si acierta, el que pegó se sienta; si no, sigue sentado.
--   · Barra de fuerza (ida y vuelta) con un cuadradito rojo: si la paras ahí → GUANTAZO SUPREMO (sale volando y muere).
--   · El sentado puede ESQUIVAR: le sale un botón al azar 0,4 s (clic en un punto de la pantalla; con mando △ ○ ✕ □).
--     Si esquiva, se sienta el que iba a pegar.
--   · Todos los de cerca (menos el sentado) ven el guantazo en primer plano.
-- Canal: Remotes.Slap. Cliente → servidor: "slap" | "stop", pos | "dodge", ok | "guess", userId | "leave".
-- Servidor → cliente: "station", info | "bar", {...} | "dodge", {key} | "guess", {options} | "hit", {...} | "msg", text
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local Slap = {}
local G

local PLAZA = Vector3.new(-125, 0, -40) -- centro de la plaza (a un lado del vestíbulo, en la isla; ver Decor.PLAZA)
local PLAZA_R = 44
local STATION_R = 28
local MAX_PLAYERS = 4
local START_DELAY = 15 -- cuenta atrás antes de empezar una partida
local AREA = 24 -- si te alejas más de esto de tu mesa, sales del juego
local BAR_PERIOD = 0.6 -- segundos de 0 a 1 (luego vuelve)
local RED_W = 0.032 -- ancho del cuadradito rojo (fracción de la barra): muy difícil de clavar
local DODGE_WINDOW = 0.4
local GUESS_TIME = 10
local IDLE_PICK = 30 -- si nadie pega en este tiempo, le toca a uno al azar
local COLORS = {
	Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 190, 60), Color3.fromRGB(90, 220, 120),
	Color3.fromRGB(80, 170, 255), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 130, 200),
}

local stations = {}
local stationOf = {} -- [player] = station
Slap.respawnHere = {} -- [player] = true si lo eliminaron en una mesa

local function hrpOf(p)
	local c = p.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function humOf(p)
	local c = p.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function isBot(p)
	return type(p) == "table" and p.IsBot == true
end
Slap.isBot = isBot
local function send(p, kind, data)
	if isBot(p) then
		if p.onSlap then
			task.spawn(p.onSlap, kind, data)
		end
	elseif p and p.Parent then
		G.Net.Slap:FireClient(p, kind, data)
	end
end
-- empujón: a un jugador se lo aplica su cliente; a un bot, el servidor
local function knock(p, vel)
	if isBot(p) then
		local hrp, hum = hrpOf(p), humOf(p)
		if hrp and hum then
			hum.PlatformStand = true
			hrp.AssemblyLinearVelocity = vel
		end
	elseif p and p.Parent then
		G.Net.Knock:FireClient(p, vel)
	end
end
-- MONEDAS del minijuego con tope (evita granjear con amigos o cuentas secundarias):
-- como mucho SLAP_CAP monedas cada 10 minutos por jugador
local SLAP_CAP = 120
local earned = {} -- [player] = { t0, n }
local function reward(p, n)
	if isBot(p) or not p or not p.Parent then
		return
	end
	local e = earned[p]
	if not e or os.clock() - e.t0 > 600 then
		e = { t0 = os.clock(), n = 0 }
		earned[p] = e
	end
	local give = math.min(n, SLAP_CAP - e.n)
	if give > 0 then
		e.n += give
		G.Data.addCoins(p, give)
	end
end
local function part(props, parent)
	local p = Instance.new(props.Class or "Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		if k ~= "Class" then
			p[k] = v
		end
	end
	p.Parent = parent
	return p
end
local function tri(x) -- onda triangular 0→1→0 con periodo 2
	x = x % 2
	return x <= 1 and x or 2 - x
end

-- ANIMACIONES: el servidor no puede mover las articulaciones (C0 es de solo lectura en los personajes
-- actuales), así que avisa a todos y cada cliente anima el brazo / la cabeza en su pantalla (Slap.client).
local function animAll(char, pose, time, power)
	if char then
		local p = Players:GetPlayerFromCharacter(char)
		G.Net.Slap:FireAllClients("anim", { who = p and p.UserId or 0, char = char, pose = pose, time = time, power = power or 0.5 })
	end
end
local function armPose(char, pose, time)
	pcall(animAll, char, pose, time)
end
local function headJolt(char, power)
	pcall(animAll, char, "jolt", 0.8, power)
end

function Slap.jumpVel(power, supreme)
	return 38 + 110 * power + (supreme and 40 or 0)
end

-- SALTO ÉPICO del que pega: cuanto más fuerte, más alto (y con fuego a partir del 60 %); onda al caer
function Slap.epicJump(p, power, supreme)
	local hrp = hrpOf(p)
	if not hrp then
		return
	end
	local v = Slap.jumpVel(power, supreme)
	if isBot(p) then
		local hum = humOf(p)
		if hum then
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
		end
		hrp.AssemblyLinearVelocity = Vector3.new(0, v, 0)
	else
		G.Net.Event:FireClient(p, "launch", { vel = Vector3.new(0, v, 0) })
	end
	-- estela de chispas (y fuego si es fuerte) mientras está en el aire
	local at = Instance.new("Attachment")
	at.Name = "SlapJumpFx"
	at.Parent = hrp
	local pe = Instance.new("ParticleEmitter")
	pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pe.Rate = 40 + 120 * power
	pe.Lifetime = NumberRange.new(0.4, 0.9)
	pe.Speed = NumberRange.new(2, 6)
	pe.SpreadAngle = Vector2.new(180, 180)
	pe.LightEmission = 1
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.8 + power), NumberSequenceKeypoint.new(1, 0) })
	pe.Color = ColorSequence.new(Color3.fromRGB(255, 255, 200), supreme and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 180, 40))
	pe.Parent = at
	if power > 0.6 or supreme then
		local fire = Instance.new("Fire")
		fire.Size = 6 + power * 6
		fire.Heat = 15
		fire.Color = supreme and Color3.fromRGB(255, 40, 40) or Color3.fromRGB(255, 140, 30)
		fire.Parent = hrp
		task.delay(1.6, function()
			fire:Destroy()
		end)
	end
	task.delay(1.6, function()
		at:Destroy()
	end)
	-- al caer: onda expansiva en el suelo
	local airtime = 2 * v / workspace.Gravity
	task.delay(math.min(2.5, airtime), function()
		local h = hrpOf(p)
		if not h then
			return
		end
		local ring = Instance.new("Part")
		ring.Anchored, ring.CanCollide, ring.CanQuery, ring.CanTouch = true, false, false, false
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = supreme and Color3.fromRGB(255, 60, 60) or Color3.fromRGB(255, 220, 120)
		ring.Transparency = 0.2
		ring.Size = Vector3.new(0.3, 2, 2)
		ring.CFrame = CFrame.new(h.Position.X, PLAZA.Y + 1.15, h.Position.Z) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = workspace
		local r = 10 + 22 * power
		TweenService:Create(ring, TweenInfo.new(0.5, Enum.EasingStyle.Quad), { Size = Vector3.new(0.3, r, r), Transparency = 1 }):Play()
		task.delay(0.6, function()
			ring:Destroy()
		end)
		if supreme then
			local e = Instance.new("Explosion")
			e.Position = h.Position - Vector3.new(0, 2.5, 0)
			e.BlastRadius = 6
			e.BlastPressure = 0
			e.DestroyJointRadiusPercent = 0
			e.Parent = workspace
		end
	end)
end

-- SENTARSE / LEVANTARSE --------------------------------------------------------------
local function standSpot(st, i)
	-- detrás de la silla (hacia el centro de la plaza), repartidos
	local side = ({ -2.5, 2.5, 0, -5, 5 })[i] or 0
	return st.cf * CFrame.new(side, 3, 6)
end

-- Todos los de la mesa están QUIETOS en su sitio (de pie detrás de la silla, mirando al sentado).
-- La vida no se regenera mientras juegas y se ve siempre encima de la cabeza.
local function setRegen(p, on)
	local c = p.Character
	local h = c and c:FindFirstChild("Health")
	if h and h:IsA("Script") then
		h.Enabled = on
	end
end
local function hold(st, p)
	local hum, hrp = humOf(p), hrpOf(p)
	if not hum or not hrp or hum.Health <= 0 then
		return
	end
	local i = table.find(st.members, p) or 1
	if st.seated and table.find(st.members, st.seated) and table.find(st.members, st.seated) < i then
		i -= 1 -- el sentado no ocupa sitio de pie
	end
	hum.Sit = false
	hum.WalkSpeed = 0
	hum.JumpHeight = 0
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOn
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = standSpot(st, i)
	setRegen(p, false)
end
local function release(p)
	local hum = humOf(p)
	if hum then
		hum.WalkSpeed = 16
		hum.JumpHeight = 7.2
		hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.DisplayWhenDamaged
		if hum.Health > 0 then
			hum.Health = hum.MaxHealth -- al salir, vida llena
		end
	end
	setRegen(p, true)
end
Slap.hold = hold

local function unseat(st, p)
	local hum = humOf(p)
	if hum then
		local w = st.seat:FindFirstChild("SeatWeld")
		if w then
			w:Destroy()
		end
		hum.Sit = false
	end
	p:SetAttribute("SlapSeated", nil)
end

local function seatPlayer(st, p)
	local hum, hrp = humOf(p), hrpOf(p)
	if not hum or not hrp or hum.Health <= 0 or not hum:IsDescendantOf(workspace) or hum:GetState() == Enum.HumanoidStateType.Dead then
		return false
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = st.seat.CFrame * CFrame.new(0, 2.5, 0)
	hum.JumpHeight = 0
	if not pcall(function()
		st.seat:Sit(hum)
	end) then
		return false
	end
	p:SetAttribute("SlapSeated", st.id)
	return true
end

-- AVISOS --------------------------------------------------------------------------
local function info(st, viewer)
	local list = {}
	for _, m in ipairs(st.members) do
		table.insert(list, { id = m.UserId, name = m.DisplayName })
	end
	return {
		id = st.id,
		phase = st.phase,
		members = list,
		seated = st.seated and st.seated.UserId or 0,
		-- quién pega solo lo saben los que están de pie
		slapper = (viewer ~= st.seated and st.slapper) and st.slapper.UserId or 0,
		max = MAX_PLAYERS,
		startsIn = st.countdown and math.max(0, math.ceil(st.countdown - os.clock())) or nil,
		inMatch = st.match == true,
		cf = st.cf,
	}
end
local function broadcast(st)
	for _, m in ipairs(st.members) do
		send(m, "station", info(st, m))
	end
	st.label.Text = string.format("🖐️ ¿QUIÉN HA SIDO?\n<font color=\"#FFE36B\">%d/%d</font>", #st.members, MAX_PLAYERS)
end
local function msgAll(st, text)
	for _, m in ipairs(st.members) do
		send(m, "msg", text)
	end
end

-- FLUJO DE CADA MESA ---------------------------------------------------------------
local function setPhase(st, phase)
	st.phase = phase
	st.phaseAt = os.clock()
	st.round += 1
	broadcast(st)
end

local function pickSeated(st, who)
	if st.seated then
		unseat(st, st.seated)
	end
	st.seated = who or st.members[math.random(1, #st.members)]
	st.slapper = nil
	seatPlayer(st, st.seated)
	setPhase(st, "waiting")
end

-- GANADOR: cuando en una partida empezada solo queda uno, gana la mesa
local function declareWinner(st, w)
	local hadKills = st.eliminated ~= nil and next(st.eliminated) ~= nil
	local wasOut = st.eliminated or {}
	st.match = false
	st.eliminated = {}
	local big = (st.matchSize or 0) >= 3
	st.matchSize = 0
	if not w or not hadKills then
		return -- sin eliminados no hay ganador (si no, salir de la mesa a propósito daría monedas)
	end
	if big then -- premio solo en partidas de 3 o más (con 2 sería fácil de granjear)
		reward(w, 25)
		if not isBot(w) then
			G.Data.addSlapWin(w) -- para el ranking de guantazos
		end
	end
	-- solo lo ven los de esta mesa (y el eliminado que mira desde cerca)
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		if table.find(st.members, p) or wasOut[p] or (h and (h.Position - st.cf.Position).Magnitude < 25) then
			send(p, "winner", { name = w.DisplayName, id = w.UserId, station = st.id })
		end
	end
end

local function refresh(st)
	if #st.members < 2 then
		if st.seated then
			unseat(st, st.seated)
		end
		st.seated, st.slapper = nil, nil
		st.countdown, st.cdToken, st.startNow = nil, nil, nil
		if st.match then
			declareWinner(st, st.members[1])
		end
		setPhase(st, "idle")
	elseif not st.match then
		-- CUENTA ATRÁS de 15 s antes de empezar (se puede entrar mientras; luego, no)
		if not st.countdown then
			st.countdown = os.clock() + START_DELAY
			local token = {}
			st.cdToken = token
			setPhase(st, "starting")
			msgAll(st, string.format("⏳ ¡La partida empieza en %d s! Aún puede entrar gente", START_DELAY))
			task.spawn(function()
				while st.cdToken == token and os.clock() < st.countdown do
					broadcast(st)
					task.wait(1)
				end
				if st.cdToken ~= token then
					return
				end
				st.countdown, st.cdToken = nil, nil
				if #st.members >= 2 then
					st.startNow = true
				end
				refresh(st)
			end)
		else
			broadcast(st)
		end
		if st.startNow then
			st.startNow = nil
			st.match = true -- empieza una partida a eliminación
			st.eliminated = {}
			for _, m in ipairs(st.members) do
				local h = humOf(m)
				if h and h.Health > 0 then
					h.Health = h.MaxHealth
				end
			end
			st.matchSize = #st.members
			msgAll(st, "🖐️ ¡Empieza la partida! Si te quedas sin vida o te dan un SUPREMO, eliminado")
			pickSeated(st)
		end
	elseif not st.seated or not table.find(st.members, st.seated) then
		if not st.match then
			st.match = true
			st.eliminated = {}
			for _, m in ipairs(st.members) do
				local h = humOf(m)
				if h and h.Health > 0 then
					h.Health = h.MaxHealth
				end
			end
			st.matchSize = #st.members
			msgAll(st, "🖐️ ¡Empieza la partida! Al que le den un guantazo SUPREMO, eliminado")
		end
		pickSeated(st)
	else
		broadcast(st)
	end
	if st.match then
		st.matchSize = math.max(st.matchSize or 0, #st.members)
	end
end

function Slap.leave(p)
	local st = stationOf[p]
	if not st then
		return
	end
	stationOf[p] = nil
	local i = table.find(st.members, p)
	if i then
		table.remove(st.members, i)
	end
	if st.seated == p then
		unseat(st, p)
		st.seated = nil
	end
	release(p)
	if st.slapper == p then
		st.slapper = nil
		if st.phase == "charging" or st.phase == "windup" then
			st.phase = "waiting"
		end
	end
	send(p, "station", nil)
	refresh(st)
end

local function join(p, st)
	if stationOf[p] == st then
		Slap.leave(p)
		return
	end
	if G.Race.sessions[p] and G.Race.sessions[p].racing then
		return
	end
	if #st.members >= MAX_PLAYERS then
		send(p, "msg", "🚫 Mesa llena (4/4)")
		return
	end
	if st.match then
		send(p, "msg", "⏳ Partida en curso: espera a que termine para entrar")
		return false
	end
	if stationOf[p] then
		Slap.leave(p)
	end
	if G.Hill and G.Hill.memberOf(p) then
		G.Hill.leave(p)
	end
	if G.Race.joined then
		G.Race.joined[p] = nil -- si se mete a jugar aquí, no corre
	end
	stationOf[p] = st
	table.insert(st.members, p)
	local hum = humOf(p)
	if hum then
		hum.Health = hum.MaxHealth
	end
	hold(st, p)
	refresh(st)
end

-- Empieza el guantazo: el que pega va detrás de la silla y le sale la barra
local function startCharge(st, p)
	st.slapper = p
	local hrp, hum = hrpOf(p), humOf(p)
	if hrp and hum then
		hum.WalkSpeed = 0
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = st.cf * CFrame.new(0.9, 3, 2.6) * CFrame.Angles(0, math.rad(8), 0)
	end
	st.redPos = 0.25 + math.random() * 0.65
	st.barT0 = os.clock()
	setPhase(st, "charging")
	send(p, "bar", { period = BAR_PERIOD, red = st.redPos, width = RED_W })
	local round = st.round
	task.delay(6, function() -- si no la para, se para sola
		if st.round == round and st.phase == "charging" then
			Slap.stop(p, nil)
		end
	end)
end

local function nearbyPlayers(pos, range)
	local out = {}
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		if h and (h.Position - pos).Magnitude <= range then
			table.insert(out, p)
		end
	end
	return out
end

local function swapSeat(st, newSeated)
	local old = st.seated
	if old then
		unseat(st, old)
	end
	pickSeated(st, newSeated)
	if old and table.find(st.members, old) then
		hold(st, old)
	end
end

-- El que pega para la barra: fuerza = posición; el rojo = supremo. Luego, 0,4 s para esquivar.
function Slap.stop(p, clientPos)
	local st = stationOf[p]
	if not st or st.phase ~= "charging" or st.slapper ~= p then
		return
	end
	-- Lo que vale es lo que VES: se acepta la posición que manda tu pantalla si cuadra con el tiempo
	-- (con margen por el retraso de la red; antes se rechazaba y por eso el rojo "no daba")
	local ping = math.min(0.4, p:GetNetworkPing())
	local pos = tri((os.clock() - st.barT0 - ping * 0.5) / BAR_PERIOD)
	if type(clientPos) == "number" and clientPos == clientPos and os.clock() - st.barT0 > 0.15 then
		local best = math.huge
		for _, lag in ipairs({ 0, ping * 0.5, ping, ping * 1.5 }) do
			best = math.min(best, math.abs(clientPos - tri((os.clock() - st.barT0 - lag) / BAR_PERIOD)))
		end
		if best < 0.18 then
			pos = math.clamp(clientPos, 0, 1)
		end
	end
	if Slap.debugPos then -- solo pruebas en Studio: parar la barra a esta distancia del rojo
		pos = math.clamp(st.redPos + Slap.debugPos, 0, 1)
		Slap.debugPos = nil
	end
	-- FUERZA = lo cerca que la paras del rojo (en el rojo, 100 % y supremo)
	local dist = math.abs(pos - st.redPos)
	st.power = math.clamp(1 - dist / 0.55, 0.1, 1)
	st.supreme = dist <= RED_W / 2 + 0.003
	if Slap.debugSupreme then -- solo pruebas en Studio
		st.supreme, pos, st.power = true, st.redPos, st.redPos
		Slap.debugSupreme = false
	end
	if st.supreme then
		st.power = 1 -- el rojo es el golpe al 100 %
	end
	setPhase(st, "windup")
	armPose(p.Character, "windup", 0.35)
	pcall(animAll, p.Character, "coil", 0.35)
	pcall(Slap.epicJump, p, pos, st.supreme)
	-- la esquiva sale justo antes de que caiga del salto (0,4 s) y el guantazo llega al aterrizar
	local air = math.min(2.2, 2 * Slap.jumpVel(pos, st.supreme) / workspace.Gravity)
	-- ESTILO de guantazo al azar (el supremo, siempre el más bestia) + cinemática para la mesa
	local STYLES = { "clasico", "giratorio", "voltereta", "doble", "gancho" }
	st.style = st.supreme and "supremo" or STYLES[math.random(1, #STYLES)]
	if st.style == "giratorio" or st.style == "supremo" then
		pcall(animAll, p.Character, "spin", air, pos)
	elseif st.style == "voltereta" then
		pcall(animAll, p.Character, "flip", air, pos)
	end
	for _, m in ipairs(st.members) do
		if m ~= st.seated then
			send(m, "windup", { station = st.id, slapper = p.UserId, slapperChar = p.Character, victimChar = st.seated and st.seated.Character, style = st.style, air = air, power = st.power, seatCF = st.cf })
		end
	end
	st.dodged = false
	st.dodgeSentAt = nil
	st.dodgeKey = math.random(1, 4)
	local round = st.round
	task.delay(math.max(0, air - DODGE_WINDOW - 0.15), function()
		if st.round ~= round or st.phase ~= "windup" then
			return
		end
		st.dodgeSentAt = os.clock()
		send(st.seated, "dodge", { key = st.dodgeKey, window = DODGE_WINDOW })
		local wait = DODGE_WINDOW + math.min(0.35, (st.seated and st.seated:GetNetworkPing() or 0) * 2) + 0.1
		task.delay(wait, function()
			if st.round == round and st.phase == "windup" then
				Slap.resolve(st)
			end
		end)
	end)
end

function Slap.dodge(p, key)
	local st = stationOf[p]
	if not st or st.phase ~= "windup" or st.seated ~= p or not st.dodgeSentAt then
		return
	end
	local dt = os.clock() - st.dodgeSentAt
	if key == st.dodgeKey and dt >= 0.12 and dt <= DODGE_WINDOW + math.min(0.35, p:GetNetworkPing() * 2) + 0.1 then
		st.dodged = true
	end
	Slap.resolve(st)
end

function Slap.resolve(st)
	if st.phase ~= "windup" then
		return
	end
	local slapper, victim = st.slapper, st.seated
	if not slapper or not victim then
		refresh(st)
		return
	end
	if st.style == "gancho" then
		armPose(slapper.Character, "uppercut", 0.08)
	else
		armPose(slapper.Character, "strike", 0.07)
		pcall(animAll, slapper.Character, "twist", 0.16)
	end
	if st.style == "doble" then -- ida y vuelta
		task.delay(0.16, function()
			armPose(slapper.Character, "backhand", 0.08)
		end)
	end
	task.delay(st.style == "doble" and 0.5 or 0.35, function()
		armPose(slapper.Character, "rest", 0.3)
	end)
	local head = victim.Character and victim.Character:FindFirstChild("Head")
	local headPos = head and head.Position or st.cf.Position
	local watchers = nearbyPlayers(headPos, 110)
	if Slap.debugDodge then -- solo pruebas en Studio: forzar esquiva
		Slap.debugDodge = nil
		st.dodged = true
	end
	Slap.stats = Slap.stats or { hits = 0, dodges = 0 }
	if st.dodged then
		Slap.stats.dodges += 1
	else
		Slap.stats.hits += 1
	end
	Slap.lastResult = { power = st.power, supreme = st.supreme, dodged = st.dodged, victim = victim, slapper = slapper }
	if st.dodged then
		-- se agacha y el guantazo da al aire: ahora se sienta el que iba a pegar
		setPhase(st, "result")
		for _, w in ipairs(watchers) do
			send(w, "hit", { station = st.id, victim = victim.UserId, victimChar = victim.Character, slapper = slapper.UserId, dodged = true, power = st.power })
		end
		msgAll(st, "💨 ¡" .. victim.DisplayName .. " lo ha esquivado! Se sienta " .. slapper.DisplayName)
		reward(victim, 5)
		local r0 = st.round
		task.wait(1.6)
		if st.round ~= r0 then
			return
		end
		if table.find(st.members, slapper) then
			swapSeat(st, slapper)
		else
			refresh(st)
		end
		return
	end
	-- ¡PAM!
	setPhase(st, "result")
	for _, w in ipairs(watchers) do
		send(w, "hit", { station = st.id, victim = victim.UserId, victimChar = victim.Character, slapper = slapper.UserId, power = st.power, supreme = st.supreme, seatCF = st.cf, style = st.style, dmg = math.floor(8 + 17 * (st.power or 0.5)) })
	end
	task.delay(0.8, function()
		if table.find(st.members, slapper) and st.seated ~= slapper then
			hold(st, slapper)
		end
	end)
	-- EL GUANTAZO QUITA VIDA: más fuerte = más daño. Si te deja a 0, quedas eliminado (KO).
	local vh = humOf(victim)
	local dmg = math.floor(8 + 17 * (st.power or 0.5))
	local ko = st.supreme
	if vh and not ko then
		vh.Health = math.max(0, vh.Health - dmg)
		ko = vh.Health <= 0
	end
	if ko then
		-- GUANTAZO SUPREMO: sale volando, muere y queda ELIMINADO de esta partida
		reward(slapper, st.supreme and 10 or 6)
		if st.supreme then
			msgAll(st, "💀 ¡GUANTAZO SUPREMO de " .. slapper.DisplayName .. "! " .. victim.DisplayName .. " eliminado")
		else
			msgAll(st, "🥊 ¡K.O.! " .. victim.DisplayName .. " se ha quedado sin vida. ¡Eliminado!")
		end
		local fwd = st.cf.LookVector
		unseat(st, victim)
		st.eliminated = st.eliminated or {}
		st.eliminated[victim] = true
		Slap.respawnHere[victim] = true -- al reaparecer, en la plaza de los guantazos
		stationOf[victim] = nil
		local vi = table.find(st.members, victim)
		if vi then
			table.remove(st.members, vi)
		end
		st.seated = nil
		send(victim, "station", nil)
		send(victim, "msg", "💀 ¡ELIMINADO! Espera a la siguiente partida")
		knock(victim, fwd * 95 + Vector3.new(math.random(-20, 20), 85, 0))
		task.delay(0.9, function()
			local h = humOf(victim)
			if h then
				h.Health = 0
			end
		end)
		st.slapper = nil
		local r0 = st.round
		task.wait(3.2)
		if st.round == r0 then
			refresh(st) -- si solo queda uno, gana; si no, se sienta otro al azar
		end
		return
	end
	pcall(function()
		local c = victim.Character
		local p = Players:GetPlayerFromCharacter(c)
		G.Net.Slap:FireAllClients("anim", { who = p and p.UserId or 0, char = c, pose = "react", power = st.power, side = math.random() < 0.5 and -1 or 1 })
	end)
	local r0 = st.round
	task.wait(0.9)
	if st.round ~= r0 or st.seated ~= victim or not table.find(st.members, victim) then
		return -- la mesa cambió mientras (alguien se fue): no tocar
	end
	-- ¿quién ha sido? (todos los de la mesa menos él, desordenados)
	local options = {}
	for _, m in ipairs(st.members) do
		if m ~= victim then
			table.insert(options, { id = m.UserId, name = m.DisplayName })
		end
	end
	for i = #options, 2, -1 do
		local j = math.random(1, i)
		options[i], options[j] = options[j], options[i]
	end
	setPhase(st, "guessing")
	send(victim, "guess", { options = options, time = GUESS_TIME })
	local round = st.round
	task.delay(GUESS_TIME + 0.5, function()
		if st.round == round and st.phase == "guessing" then
			Slap.guess(victim, -1)
		end
	end)
end

function Slap.guess(p, userId)
	local st = stationOf[p]
	if not st or st.phase ~= "guessing" or st.seated ~= p then
		return
	end
	local slapper = st.slapper
	-- SUSPENSE: toda la mesa ve "X dice que fue... Y" y, un momento después, si acertó
	local guessedName = "?"
	for _, m in ipairs(st.members) do
		if m.UserId == userId then
			guessedName = m.DisplayName
		end
	end
	local correct = slapper ~= nil and userId == slapper.UserId
	for _, m in ipairs(st.members) do
		send(m, "guessed", { seated = p.DisplayName, seatedId = p.UserId, guessed = guessedName, guessedId = userId, correct = correct, slapper = slapper and slapper.DisplayName or "?", slapperId = slapper and slapper.UserId or 0, timeout = userId == -1 })
	end
	st.phase = "reveal"
	task.wait(1.6)
	if st.phase ~= "reveal" or st.seated ~= p then
		return
	end
	st.phase = "guessing"
	if correct then
		msgAll(st, "🎯 ¡" .. p.DisplayName .. " ha acertado! Fue " .. slapper.DisplayName .. ". ¡Se sienta!")
		if #st.members >= 3 then -- con 2 en la mesa acertar es regalado: sin premio
			reward(p, 5)
		end
		setPhase(st, "result")
		local r0 = st.round
		task.wait(1.2)
		if st.round ~= r0 then
			return
		end
		if table.find(st.members, slapper) then
			swapSeat(st, slapper)
			return
		end
	else
		msgAll(st, "❌ " .. p.DisplayName .. " ha fallado" .. (slapper and (" (fue " .. slapper.DisplayName .. ")") or "") .. ". Sigue sentado")
		if slapper then
			reward(slapper, 3)
		end
	end
	st.slapper = nil
	setPhase(st, "waiting")
end

-- CONSTRUCCIÓN ---------------------------------------------------------------------
local function build()
	local f = Instance.new("Folder")
	f.Name = "SlapPlaza"
	local lobby = G.Config.COURSE.LOBBY - Vector3.new(0, 4, 0) -- centro del suelo del vestíbulo (y = 0)
	-- camino de piedra desde el vestíbulo, con farolillos
	local A = Vector3.new(lobby.X, 0, lobby.Z)
	local Bp = Vector3.new(PLAZA.X, 0, PLAZA.Z)
	local dirAB = (Bp - A).Unit
	local p0, p1 = A + dirAB * 56, Bp - dirAB * (PLAZA_R - 1)
	local len = (p1 - p0).Magnitude
	local pathCF = CFrame.lookAt((p0 + p1) / 2 + Vector3.new(0, 0.45, 0), (p0 + p1) / 2 + Vector3.new(0, 0.45, 0) + dirAB)
	part({ Name = "Path", Size = Vector3.new(12, 1, len), CFrame = pathCF, Color = Color3.fromRGB(225, 215, 200), Material = Enum.Material.Cobblestone }, f)
	for _, sx in ipairs({ -1, 1 }) do
		for d = -len / 2 + 4, len / 2 - 4, 12 do
			local lp = (pathCF * CFrame.new(sx * 7.5, 2.5, d)).Position
			part({ Name = "LampPost", Size = Vector3.new(0.6, 5, 0.6), CFrame = CFrame.new(lp), Color = Color3.fromRGB(60, 50, 45), Material = Enum.Material.Metal }, f)
			local bulb = part({ Name = "Lamp", Shape = Enum.PartType.Ball, Size = Vector3.new(1.4, 1.4, 1.4), CFrame = CFrame.new(lp + Vector3.new(0, 3, 0)), Color = Color3.fromRGB(255, 220, 140), Material = Enum.Material.Neon, CanCollide = false }, f)
			local pl = Instance.new("PointLight")
			pl.Color = Color3.fromRGB(255, 210, 140)
			pl.Range = 12
			pl.Brightness = 1.2
			pl.Parent = bulb
		end
	end
	-- isla de la plaza
	part({ Name = "PlazaFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, PLAZA_R * 2, PLAZA_R * 2), CFrame = CFrame.new(PLAZA) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(235, 225, 245), Material = Enum.Material.Pavement }, f)
	part({ Name = "PlazaRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, PLAZA_R * 2 + 2, PLAZA_R * 2 + 2), CFrame = CFrame.new(PLAZA - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Neon }, f)
	-- cartel de entrada, en el lado que da al vestíbulo
	local toLobby = -dirAB
	local gateCF = CFrame.lookAt(PLAZA + toLobby * (PLAZA_R - 2) + Vector3.new(0, 11, 0), PLAZA + toLobby * (PLAZA_R + 10) + Vector3.new(0, 11, 0))
	local gate = part({ Name = "PlazaSign", Size = Vector3.new(26, 5, 1), CFrame = gateCF, Color = Color3.fromRGB(40, 25, 60), Material = Enum.Material.SmoothPlastic }, f)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "SignPost", Size = Vector3.new(1.2, 11, 1.2), CFrame = gateCF * CFrame.new(sx * 13.6, -5.5, 0), Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Neon }, f)
	end
	local sg = Instance.new("SurfaceGui")
	sg.Face = Enum.NormalId.Back
	sg.LightInfluence = 0
	sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
	sg.PixelsPerStud = 25
	local l = Instance.new("TextLabel")
	l.BackgroundTransparency = 1
	l.Size = UDim2.fromScale(1, 1)
	l.TextScaled = true
	l.Font = Enum.Font.LuckiestGuy
	l.TextColor3 = Color3.fromRGB(255, 220, 90)
	l.Text = "🖐️ ¿QUIÉN HA SIDO? 🖐️"
	l.Parent = sg
	sg.Parent = gate
	local sg2 = sg:Clone()
	sg2.Face = Enum.NormalId.Front
	sg2.Parent = gate
	-- mesas
	for k = 1, 6 do
		local a = math.rad(k * 60 - 30)
		local dir = Vector3.new(math.sin(a), 0, math.cos(a))
		local center = PLAZA + dir * STATION_R + Vector3.new(0, 1, 0)
		local cf = CFrame.lookAt(center, center + dir) -- mira hacia fuera (al vacío)
		local col = COLORS[k]
		local st = { id = k, cf = cf, members = {}, phase = "idle", phaseAt = 0, round = 0 }
		local sf = Instance.new("Folder")
		sf.Name = "Station" .. k
		-- alfombra de la mesa
		part({ Name = "Area", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 18, 18), CFrame = cf * CFrame.new(0, 0.1, 4) * CFrame.Angles(0, 0, math.rad(90)), Color = col:Lerp(Color3.new(1, 1, 1), 0.55), Material = Enum.Material.SmoothPlastic, CanCollide = false }, sf)
		part({ Name = "AreaRing", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.22, 18.6, 18.6), CFrame = cf * CFrame.new(0, 0.09, 4) * CFrame.Angles(0, 0, math.rad(90)), Color = col, Material = Enum.Material.Neon, CanCollide = false }, sf)
		-- silla tipo trono (mirando hacia fuera)
		part({ Name = "ChairBase", Size = Vector3.new(3.2, 1.6, 3.2), CFrame = cf * CFrame.new(0, 0.8, 0), Color = Color3.fromRGB(70, 50, 40), Material = Enum.Material.Wood }, sf)
		local seat = part({ Class = "Seat", Name = "Seat", Size = Vector3.new(3, 0.6, 3), CFrame = cf * CFrame.new(0, 1.9, 0), Color = col, Material = Enum.Material.Fabric, Disabled = true }, sf)
		part({ Name = "ChairBack", Size = Vector3.new(3.2, 2.2, 0.5), CFrame = cf * CFrame.new(0, 3.2, 1.45), Color = Color3.fromRGB(70, 50, 40), Material = Enum.Material.Wood }, sf)
		part({ Name = "ChairTrim", Size = Vector3.new(3.4, 0.3, 0.6), CFrame = cf * CFrame.new(0, 4.35, 1.45), Color = col, Material = Enum.Material.Neon, CanCollide = false }, sf)
		-- cartel con el número de jugadores y botón para unirse
		local post = part({ Name = "Post", Size = Vector3.new(0.8, 7, 0.8), CFrame = cf * CFrame.new(-6, 3.5, 6), Color = Color3.new(1, 1, 1), Material = Enum.Material.SmoothPlastic }, sf)
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(6.5, 2.4)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 4.5, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 34
		bb.Parent = post
		local label = Instance.new("TextLabel")
		label.BackgroundTransparency = 1
		label.Size = UDim2.fromScale(1, 1)
		label.TextScaled = true
		label.RichText = true
		label.Font = Enum.Font.LuckiestGuy
		label.TextColor3 = col:Lerp(Color3.new(1, 1, 1), 0.4)
		label.TextStrokeTransparency = 0.2
		label.Parent = bb
		st.label = label
		local pp = Instance.new("ProximityPrompt")
		pp.ActionText = "Jugar / Salir"
		pp.ObjectText = "¿Quién ha sido? (máx. 4)"
		pp.HoldDuration = 0.25
		pp.MaxActivationDistance = 12
		pp.RequiresLineOfSight = false
		pp.Parent = post
		pp.Triggered:Connect(function(p)
			join(p, st)
		end)
		st.seat = seat
		sf.Parent = f
		stations[k] = st
		broadcast(st)
	end
	f.Parent = workspace
end

function Slap.init(g)
	G = g
	G.Slap = Slap
	build()
	G.Net.Slap.OnServerEvent:Connect(function(p, kind, a)
		local st = stationOf[p]
		if kind == "leave" then
			Slap.leave(p)
		elseif kind == "slap" then
			Slap.request(p)
		elseif kind == "stop" then
			Slap.stop(p, a)
		elseif kind == "dodge" then
			Slap.dodge(p, tonumber(a))
		elseif kind == "guess" then
			Slap.guess(p, tonumber(a) or -1)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		Slap.leave(p)
	end)
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			-- tras un guantazo supremo vuelve a su silla
			task.wait(0.5)
			local st = stationOf[p]
			if st and st.seated == p then
				seatPlayer(st, p)
			elseif st then
				hold(st, p)
			elseif Slap.respawnHere[p] then
				Slap.respawnHere[p] = nil
				local hrp = hrpOf(p)
				if hrp then
					local lobby = G.Config.COURSE.LOBBY
					local toLobby = (Vector3.new(lobby.X, 0, lobby.Z) - Vector3.new(PLAZA.X, 0, PLAZA.Z)).Unit
					local spot = PLAZA + toLobby * (PLAZA_R - 9) + Vector3.new(math.random(-4, 4), 4, math.random(-4, 4))
					hrp.CFrame = CFrame.lookAt(spot, Vector3.new(PLAZA.X, spot.Y, PLAZA.Z))
				end
			end
		end)
	end)
	-- vigilancia: alejarse = salir; sentado que se levanta = vuelve a sentarse; nadie pega = le toca a uno
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, st in ipairs(stations) do
				local ok, err = pcall(function()
				for i = #st.members, 1, -1 do
					local p = st.members[i]
					local hrp = hrpOf(p)
					-- ya nadie se va andando (están quietos): si alguien acaba lejos (salto épico, empujón), al
					-- aterrizar vuelve a su sitio. Nunca se le echa de la mesa por esto.
					local hum = humOf(p)
					if hrp and hum and hum.Health > 0 and p ~= st.seated and p ~= st.slapper
						and hum.FloorMaterial ~= Enum.Material.Air
						and (hrp.Position - st.cf.Position).Magnitude > 9
						and os.clock() - (st.phaseAt or 0) > 1 then
						hold(st, p)
					end
				end
				if st.seated and st.phase ~= "result" then
					local hum = humOf(st.seated)
					if hum and hum.Health > 0 and not hum.Sit then
						seatPlayer(st, st.seated)
					end
				end
				if st.phase == "waiting" and #st.members >= 2 and os.clock() - st.phaseAt > IDLE_PICK then
					local pool = {}
					for _, m in ipairs(st.members) do
						if m ~= st.seated then
							table.insert(pool, m)
						end
					end
					if #pool > 0 then
						local p = pool[math.random(1, #pool)]
						send(p, "msg", "🖐️ ¡Te toca dar el guantazo!")
						startCharge(st, p)
					end
				end
				end)
				if not ok then
					warn("[Slap] " .. tostring(err))
				end
			end
		end
	end)
end

-- Para los bots (y el botón): pedir dar el guantazo si toca
function Slap.request(p)
	local st = stationOf[p]
	if st and st.phase == "waiting" and st.seated ~= p and #st.members >= 2 then
		startCharge(st, p)
		return true
	end
	return false
end
function Slap.join(p, k)
	local st = stations[k]
	if st then
		join(p, st)
	end
	return stationOf[p] ~= nil
end
function Slap.stationOf(p)
	local st = stationOf[p]
	return st and st.id
end
function Slap.freeSlots(k)
	local st = stations[k]
	return st and (MAX_PLAYERS - #st.members) or 0
end
Slap.COUNT = 6

Slap.PLAZA = PLAZA
function Slap.debugJoin(p, k) -- solo para pruebas en Studio
	join(p, stations[k or 1])
end
function Slap.station(k) -- (pruebas)
	return stations[k]
end
function Slap.debugState(k)
	local st = stations[k or 1]
	return st.phase, st.seated and st.seated.Name, st.slapper and st.slapper.Name, #st.members
end
return Slap
