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

local PLAZA = Vector3.new(0, 0, -205) -- centro de la plaza (detrás del vestíbulo, unida por un puente)
local PLAZA_R = 44
local STATION_R = 28
local MAX_PLAYERS = 4
local AREA = 24 -- si te alejas más de esto de tu mesa, sales del juego
local BAR_PERIOD = 0.9 -- segundos de 0 a 1 (luego vuelve)
local RED_W = 0.07 -- ancho del cuadradito rojo (fracción de la barra)
local DODGE_WINDOW = 0.4
local GUESS_TIME = 10
local IDLE_PICK = 30 -- si nadie pega en este tiempo, le toca a uno al azar
local COLORS = {
	Color3.fromRGB(255, 90, 90), Color3.fromRGB(255, 190, 60), Color3.fromRGB(90, 220, 120),
	Color3.fromRGB(80, 170, 255), Color3.fromRGB(190, 110, 255), Color3.fromRGB(255, 130, 200),
}

local stations = {}
local stationOf = {} -- [player] = station

local function hrpOf(p)
	local c = p.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function humOf(p)
	local c = p.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function send(p, kind, data)
	if p and p.Parent then
		G.Net.Slap:FireClient(p, kind, data)
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
	local p = char and Players:GetPlayerFromCharacter(char)
	if p then
		G.Net.Slap:FireAllClients("anim", { who = p.UserId, pose = pose, time = time, power = power or 0.5 })
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
	G.Net.Event:FireClient(p, "launch", { vel = Vector3.new(0, v, 0) })
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

local function unseat(st, p)
	local hum = humOf(p)
	if hum then
		local w = st.seat:FindFirstChild("SeatWeld")
		if w then
			w:Destroy()
		end
		hum.Sit = false
		hum.JumpHeight = 7.2
		hum.WalkSpeed = 16
	end
	p:SetAttribute("SlapSeated", nil)
end

local function seatPlayer(st, p)
	local hum, hrp = humOf(p), hrpOf(p)
	if not hum or not hrp or hum.Health <= 0 then
		return false
	end
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = st.seat.CFrame * CFrame.new(0, 2.5, 0)
	hum.JumpHeight = 0
	st.seat:Sit(hum)
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
	st.match = false
	st.eliminated = {}
	if not w or not hadKills then
		return -- sin eliminados no hay ganador (si no, salir de la mesa a propósito daría monedas)
	end
	G.Data.addCoins(w, 25)
	for _, p in ipairs(Players:GetPlayers()) do
		local h = hrpOf(p)
		if h and (h.Position - st.cf.Position).Magnitude < 140 then
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
		if st.match then
			declareWinner(st, st.members[1])
		end
		setPhase(st, "idle")
	elseif not st.seated or not table.find(st.members, st.seated) then
		if not st.match then
			st.match = true -- empieza una partida a eliminación
			st.eliminated = {}
			msgAll(st, "🖐️ ¡Empieza la partida! Al que le den un guantazo SUPREMO, eliminado")
		end
		pickSeated(st)
	else
		broadcast(st)
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
	if st.slapper == p then
		st.slapper = nil
		local hum = humOf(p)
		if hum then
			hum.WalkSpeed = 16
		end
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
	if st.match and st.eliminated and st.eliminated[p] then
		send(p, "msg", "💀 Estás eliminado: espera a que acabe esta partida")
		return
	end
	if stationOf[p] then
		Slap.leave(p)
	end
	if G.Race.joined then
		G.Race.joined[p] = nil -- si se mete a jugar aquí, no corre
	end
	stationOf[p] = st
	table.insert(st.members, p)
	local hrp = hrpOf(p)
	if hrp then
		hrp.CFrame = standSpot(st, #st.members)
	end
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
		local hrp = hrpOf(old)
		if hrp then
			hrp.CFrame = standSpot(st, 1)
		end
	end
	local hum = humOf(newSeated)
	if hum then
		hum.WalkSpeed = 16
	end
	pickSeated(st, newSeated)
end

-- El que pega para la barra: fuerza = posición; el rojo = supremo. Luego, 0,4 s para esquivar.
function Slap.stop(p, clientPos)
	local st = stationOf[p]
	if not st or st.phase ~= "charging" or st.slapper ~= p then
		return
	end
	local serverPos = tri((os.clock() - st.barT0 - math.min(0.3, p:GetNetworkPing())) / BAR_PERIOD)
	local pos = serverPos
	if type(clientPos) == "number" and clientPos == clientPos and math.abs(clientPos - serverPos) < 0.2 then
		pos = math.clamp(clientPos, 0, 1)
	end
	st.power = pos
	st.supreme = math.abs(pos - st.redPos) <= RED_W / 2 + 0.01
	if Slap.debugSupreme then -- solo pruebas en Studio
		st.supreme, pos, st.power = true, st.redPos, st.redPos
		Slap.debugSupreme = false
	end
	setPhase(st, "windup")
	armPose(p.Character, "windup", 0.35)
	pcall(Slap.epicJump, p, pos, st.supreme)
	-- la esquiva sale justo antes de que caiga del salto (0,4 s) y el guantazo llega al aterrizar
	local air = math.min(2.2, 2 * Slap.jumpVel(pos, st.supreme) / workspace.Gravity)
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

function Slap.dodge(p, ok)
	local st = stationOf[p]
	if not st or st.phase ~= "windup" or st.seated ~= p or not st.dodgeSentAt then
		return
	end
	if ok == true and os.clock() - st.dodgeSentAt <= DODGE_WINDOW + math.min(0.35, p:GetNetworkPing() * 2) + 0.1 then
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
	armPose(slapper.Character, "strike", 0.07, Enum.EasingStyle.Linear)
	task.delay(0.35, function()
		armPose(slapper.Character, "rest", 0.3)
	end)
	local head = victim.Character and victim.Character:FindFirstChild("Head")
	local headPos = head and head.Position or st.cf.Position
	local watchers = nearbyPlayers(headPos, 110)
	if st.dodged then
		-- se agacha y el guantazo da al aire: ahora se sienta el que iba a pegar
		setPhase(st, "result")
		for _, w in ipairs(watchers) do
			send(w, "hit", { station = st.id, victim = victim.UserId, slapper = slapper.UserId, dodged = true, power = st.power })
		end
		msgAll(st, "💨 ¡" .. victim.DisplayName .. " lo ha esquivado! Se sienta " .. slapper.DisplayName)
		G.Data.addCoins(victim, 5)
		task.wait(1.6)
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
		send(w, "hit", { station = st.id, victim = victim.UserId, slapper = slapper.UserId, power = st.power, supreme = st.supreme, seatCF = st.cf })
	end
	local hum = humOf(slapper)
	if hum then
		hum.WalkSpeed = 16
	end
	if st.supreme then
		-- GUANTAZO SUPREMO: sale volando, muere y queda ELIMINADO de esta partida
		G.Data.addCoins(slapper, 10)
		msgAll(st, "💀 ¡GUANTAZO SUPREMO de " .. slapper.DisplayName .. "! " .. victim.DisplayName .. " eliminado")
		local fwd = st.cf.LookVector
		unseat(st, victim)
		st.eliminated = st.eliminated or {}
		st.eliminated[victim] = true
		stationOf[victim] = nil
		local vi = table.find(st.members, victim)
		if vi then
			table.remove(st.members, vi)
		end
		st.seated = nil
		send(victim, "station", nil)
		send(victim, "msg", "💀 ¡ELIMINADO! Espera a la siguiente partida")
		G.Net.Knock:FireClient(victim, fwd * 95 + Vector3.new(math.random(-20, 20), 85, 0))
		task.delay(0.9, function()
			local h = humOf(victim)
			if h then
				h.Health = 0
			end
		end)
		st.slapper = nil
		task.wait(3.2)
		refresh(st) -- si solo queda uno, gana; si no, se sienta otro al azar
		return
	end
	headJolt(victim.Character, st.power)
	task.wait(0.9)
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
	if slapper and userId == slapper.UserId then
		msgAll(st, "🎯 ¡" .. p.DisplayName .. " ha acertado! Fue " .. slapper.DisplayName .. ". ¡Se sienta!")
		G.Data.addCoins(p, 5)
		setPhase(st, "result")
		task.wait(1.2)
		if table.find(st.members, slapper) then
			swapSeat(st, slapper)
			return
		end
	else
		msgAll(st, "❌ " .. p.DisplayName .. " ha fallado" .. (slapper and (" (fue " .. slapper.DisplayName .. ")") or "") .. ". Sigue sentado")
		if slapper then
			G.Data.addCoins(slapper, 3)
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
	-- puente desde el vestíbulo
	local z0, z1 = lobby.Z - 34, PLAZA.Z + PLAZA_R - 1
	part({ Name = "Bridge", Size = Vector3.new(12, 1, z0 - z1), CFrame = CFrame.new(0, 0.5, (z0 + z1) / 2), Color = Color3.fromRGB(240, 235, 225), Material = Enum.Material.WoodPlanks }, f)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "BridgeRail", Size = Vector3.new(0.6, 0.6, z0 - z1), CFrame = CFrame.new(sx * 6, 2.6, (z0 + z1) / 2), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Neon }, f)
		for z = z1 + 2, z0 - 2, 6 do
			part({ Name = "BridgePost", Size = Vector3.new(0.6, 2.2, 0.6), CFrame = CFrame.new(sx * 6, 1.6, z), Color = Color3.fromRGB(150, 100, 60), Material = Enum.Material.Wood }, f)
		end
	end
	-- isla de la plaza
	part({ Name = "PlazaFloor", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2, PLAZA_R * 2, PLAZA_R * 2), CFrame = CFrame.new(PLAZA) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(235, 225, 245), Material = Enum.Material.Pavement }, f)
	part({ Name = "PlazaRim", Shape = Enum.PartType.Cylinder, Size = Vector3.new(2.2, PLAZA_R * 2 + 2, PLAZA_R * 2 + 2), CFrame = CFrame.new(PLAZA - Vector3.new(0, 0.2, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Neon }, f)
	for k = 0, 4 do
		local rr = PLAZA_R * (1 - k * 0.18)
		part({ Name = "PlazaRock", Shape = Enum.PartType.Cylinder, Size = Vector3.new(7, rr * 2, rr * 2), CFrame = CFrame.new(PLAZA - Vector3.new(0, 4.5 + k * 6.5, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(135 - k * 10, 110 - k * 8, 95 - k * 6), Material = Enum.Material.Rock }, f)
	end
	-- cartel de entrada
	local gate = part({ Name = "PlazaSign", Size = Vector3.new(26, 5, 1), CFrame = CFrame.new(PLAZA + Vector3.new(0, 11, PLAZA_R - 2)), Color = Color3.fromRGB(40, 25, 60), Material = Enum.Material.SmoothPlastic }, f)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "SignPost", Size = Vector3.new(1.2, 11, 1.2), CFrame = CFrame.new(PLAZA + Vector3.new(sx * 13.6, 5.5, PLAZA_R - 2)), Color = Color3.fromRGB(255, 120, 200), Material = Enum.Material.Neon }, f)
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
		bb.Size = UDim2.fromScale(9, 3.2)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 5.5, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 80
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
	-- quitar islas decorativas del vestíbulo que tapen el puente o la plaza
	local deco = workspace:FindFirstChild("LobbyDecor")
	if deco then
		for _, p in ipairs(deco:GetChildren()) do
			if p:IsA("BasePart") and (p.Name == "IslandTop" or p.Name == "IslandRock" or p.Name == "Bush") then
				local pos = p.Position
				if pos.Z < lobby.Z - 25 and math.abs(pos.X) < PLAZA_R + 20 then
					p:Destroy()
				end
			end
		end
	end
end

function Slap.init(g)
	G = g
	G.Slap = Slap
	build()
	G.Net.Slap.OnServerEvent:Connect(function(p, kind, a)
		local st = stationOf[p]
		if kind == "leave" then
			Slap.leave(p)
		elseif kind == "slap" and st and st.phase == "waiting" and st.seated ~= p then
			startCharge(st, p)
		elseif kind == "stop" then
			Slap.stop(p, a)
		elseif kind == "dodge" then
			Slap.dodge(p, a)
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
				local hrp = hrpOf(p)
				if hrp then
					hrp.CFrame = standSpot(st, 1)
				end
			end
		end)
	end)
	-- vigilancia: alejarse = salir; sentado que se levanta = vuelve a sentarse; nadie pega = le toca a uno
	task.spawn(function()
		while true do
			task.wait(0.5)
			for _, st in ipairs(stations) do
				for i = #st.members, 1, -1 do
					local p = st.members[i]
					local hrp = hrpOf(p)
					if hrp and p ~= st.seated and p ~= st.slapper and (hrp.Position - st.cf.Position).Magnitude > AREA then
						Slap.leave(p)
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
			end
		end
	end)
end

Slap.PLAZA = PLAZA
function Slap.debugJoin(p, k) -- solo para pruebas en Studio
	join(p, stations[k or 1])
end
function Slap.debugState(k)
	local st = stations[k or 1]
	return st.phase, st.seated and st.seated.Name, st.slapper and st.slapper.Name, #st.members
end
return Slap
