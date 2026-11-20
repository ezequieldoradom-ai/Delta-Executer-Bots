-- Lucky Obby Race — 👑 REY DE LA COLINA (Shadow, petición del dueño)
-- Arena redonda elevada a la derecha del vestíbulo, hasta 10 jugadores (con bots si hay poca gente).
--   · Con 2 o más: cuenta atrás de 15 s (se puede entrar). Empezada la partida, no entra nadie más.
--   · Los guantazos aquí no quitan vida: EMPUJAN. Si caes de la arena, eliminado (miras desde fuera).
--   · Cada segundo en la colina dorada del centro suma puntos (y llevas la 👑 si vas primero).
--   · Gana el último en pie, o el que más tiempo ha estado en la colina si se acaban los 90 s.
--   · Premio y ranking "👑 REYES DE LA COLINA" (solo en partidas de 3 o más, para que no se pueda granjear).
-- Canal: Remotes.Hill. Cliente → servidor: "push" | "leave". Servidor → cliente: "state", "msg", "winner", "pushFx".
local Players = game:GetService("Players")

local Hill = {}
local G

Hill.MAX, Hill.MIN = 10, 2
local START_DELAY, MATCH_TIME, RESULT_TIME = 15, 90, 4
local R = 24 -- radio de la arena
local TOP = 9 -- altura del suelo de la arena
local HILL_R, HILL_H = 6, 1.2 -- la colina dorada del centro
local PUSH_CD, PUSH_RANGE, PUSH_POWER = 0.8, 8, 78
local WALK = 18
local CENTER -- Decor.HILL

local st = { members = {}, phase = "idle", alive = {}, score = {}, round = 0 }
Hill.st = st

local function isBot(p)
	return type(p) == "table" and p.IsBot == true
end
local function hrpOf(p)
	local c = p and p.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function humOf(p)
	local c = p and p.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end
local function send(p, kind, data)
	if isBot(p) then
		if p.onHill then
			task.spawn(p.onHill, kind, data)
		end
	elseif p and p.Parent then
		G.Net.Hill:FireClient(p, kind, data)
	end
end
local function flat(v)
	return Vector3.new(v.X, 0, v.Z)
end
local function part(props, parent)
	local p = Instance.new("Part")
	p.Anchored = true
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	for k, v in pairs(props) do
		p[k] = v
	end
	p.Parent = parent
	return p
end

function Hill.memberOf(p)
	return table.find(st.members, p) ~= nil
end

local function toLobbyDir()
	local lobby = G.Config.COURSE.LOBBY
	return (flat(lobby) - flat(CENTER)).Unit
end
local function spectatorCF()
	local d = toLobbyDir()
	local pos = CENTER + d * (R + 7) + Vector3.new(math.random(-5, 5) * 0.6, 3.5, math.random(-5, 5) * 0.6)
	return CFrame.lookAt(pos, Vector3.new(CENTER.X, pos.Y, CENTER.Z))
end
local function ringCF(i, n)
	local a = (i - 1) / math.max(1, n) * math.pi * 2
	local pos = CENTER + Vector3.new(math.cos(a) * R * 0.72, TOP + 3.2, math.sin(a) * R * 0.72)
	return CFrame.lookAt(pos, Vector3.new(CENTER.X, pos.Y, CENTER.Z))
end

-- ESTADO PARA LOS CLIENTES -------------------------------------------------------------
local function info()
	local list = {}
	for _, m in ipairs(st.members) do
		table.insert(list, { id = m.UserId, name = m.DisplayName, alive = st.alive[m] == true, score = math.floor(st.score[m] or 0) })
	end
	table.sort(list, function(a, b)
		if a.alive ~= b.alive then
			return a.alive
		end
		return a.score > b.score
	end)
	return {
		phase = st.phase,
		members = list,
		max = Hill.MAX,
		startsIn = st.countdown and math.max(0, math.ceil(st.countdown - os.clock())) or nil,
		timeLeft = st.endsAt and math.max(0, math.ceil(st.endsAt - os.clock())) or nil,
	}
end
local function broadcast()
	local data = info()
	for _, m in ipairs(st.members) do
		send(m, "state", data)
	end
	if st.label then
		st.label.Text = string.format('👑 REY DE LA COLINA\n<font color="#FFE36B">%d/%d</font>', #st.members, Hill.MAX)
	end
	if st.bigLabel then
		local status = st.phase == "playing" and "⚔️ PARTIDA EN CURSO" or (st.phase == "starting" and "⏳ ¡EMPIEZA YA! ENTRA" or "¡ENTRA A JUGAR!")
		st.bigLabel.Text = string.format('👑 REY DE LA COLINA 👑\n<font size="40" color="#FFFFFF">%s · %d/%d</font>', status, #st.members, Hill.MAX)
	end
end
local function msgAll(text)
	for _, m in ipairs(st.members) do
		send(m, "msg", text)
	end
end

-- corona flotante sobre el que va primero
local crown
local function updateCrown()
	local best, bestS = nil, 0
	if st.phase == "playing" then
		for _, m in ipairs(st.members) do
			if st.alive[m] and (st.score[m] or 0) > bestS then
				best, bestS = m, st.score[m]
			end
		end
	end
	local head = best and best.Character and best.Character:FindFirstChild("Head")
	if head then
		if not crown then
			crown = Instance.new("BillboardGui")
			crown.Name = "HillCrown"
			crown.Size = UDim2.fromScale(3, 3)
			crown.StudsOffset = Vector3.new(0, 3, 0)
			crown.AlwaysOnTop = true
			crown.LightInfluence = 0
			local l = Instance.new("TextLabel")
			l.BackgroundTransparency = 1
			l.Size = UDim2.fromScale(1, 1)
			l.TextScaled = true
			l.Text = "👑"
			l.Parent = crown
		end
		crown.Adornee = head
		crown.Parent = head
	elseif crown then
		crown.Parent = nil
	end
end

-- ENTRAR / SALIR -----------------------------------------------------------------------
local function walkNormal(p)
	local h = humOf(p)
	if h then
		h.WalkSpeed = 16
		h.JumpHeight = 7.2
	end
end

local refresh

function Hill.leave(p)
	local i = table.find(st.members, p)
	if not i then
		return
	end
	table.remove(st.members, i)
	st.alive[p], st.score[p] = nil, nil
	walkNormal(p)
	send(p, "state", nil)
	refresh()
end

function Hill.join(p)
	if Hill.memberOf(p) then
		Hill.leave(p)
		return false
	end
	if G.Race.sessions[p] and G.Race.sessions[p].racing then
		return false
	end
	if st.phase == "playing" or st.phase == "result" then
		send(p, "msg", "⏳ Partida en curso: espera a que termine para entrar")
		return false
	end
	if #st.members >= Hill.MAX then
		send(p, "msg", "🚫 Arena llena (10/10)")
		return false
	end
	if G.Slap and G.Slap.stationOf(p) then
		G.Slap.leave(p)
	end
	if G.Race.joined then
		G.Race.joined[p] = nil
	end
	table.insert(st.members, p)
	local hrp, h = hrpOf(p), humOf(p)
	if h then
		h.Health = h.MaxHealth
		h.WalkSpeed = WALK
		h.JumpHeight = 7.2
	end
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = ringCF(#st.members, Hill.MAX)
	end
	refresh()
	return true
end

-- PARTIDA -----------------------------------------------------------------------------
local function startMatch()
	st.phase = "playing"
	st.round += 1
	st.matchSize = #st.members
	st.endsAt = os.clock() + MATCH_TIME
	table.clear(st.alive)
	table.clear(st.score)
	for i, m in ipairs(st.members) do
		st.alive[m] = true
		st.score[m] = 0
		local hrp, h = hrpOf(m), humOf(m)
		if h then
			h.Health = h.MaxHealth
			h.WalkSpeed = WALK
			h.JumpHeight = 7.2
		end
		if hrp then
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = ringCF(i, #st.members)
		end
	end
	msgAll("👑 ¡A por la colina! Empuja con guantazos y no te caigas")
	broadcast()
end

local function eliminate(p, why)
	if not st.alive[p] then
		return
	end
	st.alive[p] = false
	send(p, "msg", why or "💥 ¡Te han echado de la arena!")
	-- sonido de caída: solo lo oyen los de la arena (y el que cae)
	local ph = hrpOf(p)
	for _, m in ipairs(st.members) do
		send(m, "fall", { pos = ph and ph.Position or CENTER, name = p.DisplayName, me = m == p })
		if m ~= p then
			send(m, "msg", "💥 " .. p.DisplayName .. " eliminado")
		end
	end
	-- al poco, vuelve al vestíbulo central y sale de la arena
	task.delay(1, function()
		if not Hill.memberOf(p) or st.alive[p] then
			return
		end
		local hrp, h = hrpOf(p), humOf(p)
		if hrp and h and h.Health > 0 then
			hrp.AssemblyLinearVelocity = Vector3.zero
			local lobby = G.Config.COURSE.LOBBY
			hrp.CFrame = CFrame.new(lobby + Vector3.new(math.random(-8, 8), 0, math.random(-6, 6)))
		end
		Hill.leave(p)
	end)
	broadcast()
end

local function finish()
	st.phase = "result"
	st.endsAt = nil
	-- ganador: el último en pie; si se acabó el tiempo, el que más tiempo estuvo en la colina (entre los vivos)
	local winner, best = nil, -1
	for _, m in ipairs(st.members) do
		if st.alive[m] and (st.score[m] or 0) > best then
			winner, best = m, st.score[m] or 0
		end
	end
	if winner then
		if (st.matchSize or 0) >= 3 and not isBot(winner) then
			G.Data.addCoins(winner, 20)
			G.Data.addHillWin(winner)
		end
		for _, p in ipairs(Players:GetPlayers()) do
			local h = hrpOf(p)
			if Hill.memberOf(p) or (h and (h.Position - CENTER).Magnitude < 60) then
				send(p, "winner", { name = winner.DisplayName, id = winner.UserId, score = math.floor(best) })
			end
		end
		for _, m in ipairs(st.members) do
			if isBot(m) then
				send(m, "winner", { id = winner.UserId })
			end
		end
	end
	Hill.lastWinner = winner
	updateCrown()
	broadcast()
	local r0 = st.round
	task.delay(RESULT_TIME, function()
		if st.round ~= r0 then
			return
		end
		-- todos vuelven a la arena para la siguiente
		table.clear(st.alive)
		for i, m in ipairs(st.members) do
			local hrp, h = hrpOf(m), humOf(m)
			if hrp and h and h.Health > 0 then
				h.WalkSpeed = WALK
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = ringCF(i, #st.members)
			end
		end
		st.phase = "idle"
		refresh()
	end)
end

function refresh()
	if st.phase == "playing" or st.phase == "result" then
		broadcast()
		return
	end
	if #st.members < Hill.MIN then
		st.countdown, st.cdToken = nil, nil
		st.phase = "idle"
		broadcast()
		return
	end
	if not st.countdown then
		st.countdown = os.clock() + START_DELAY
		st.phase = "starting"
		local token = {}
		st.cdToken = token
		msgAll(string.format("⏳ ¡La partida empieza en %d s! Aún puede entrar gente", START_DELAY))
		task.spawn(function()
			while st.cdToken == token and os.clock() < st.countdown do
				broadcast()
				task.wait(1)
			end
			if st.cdToken ~= token then
				return
			end
			st.countdown, st.cdToken = nil, nil
			if #st.members >= Hill.MIN then
				startMatch()
			else
				st.phase = "idle"
				broadcast()
			end
		end)
	end
	broadcast()
end

-- EMPUJAR (guantazo que empuja) ------------------------------------------------------
local lastPush = {}
function Hill.push(p)
	if st.phase ~= "playing" or not st.alive[p] then
		return false
	end
	if lastPush[p] and os.clock() - lastPush[p] < PUSH_CD then
		return false
	end
	lastPush[p] = os.clock()
	local hrp = hrpOf(p)
	if not hrp then
		return false
	end
	-- animación del brazo (la hacen los clientes, como en las mesas)
	pcall(function()
		G.Net.Slap:FireAllClients("anim", { who = isBot(p) and 0 or p.UserId, char = p.Character, pose = "shove" })
	end)
	local look = flat(hrp.CFrame.LookVector)
	look = look.Magnitude > 0.1 and look.Unit or Vector3.new(0, 0, 1)
	local target, bestD = nil, math.huge
	for _, m in ipairs(st.members) do
		local th = m ~= p and st.alive[m] and hrpOf(m)
		if th then
			local d = flat(th.Position - hrp.Position)
			local dist = d.Magnitude
			-- cerca y más o menos delante (o pegado)
			if dist <= PUSH_RANGE and (dist < 3 or d.Unit:Dot(look) > 0.2) and dist < bestD then
				target, bestD = m, dist
			end
		end
	end
	local th0 = target and hrpOf(target)
	for _, w in ipairs(st.members) do
		send(w, "pushFx", { pos = hrp.Position, hit = target ~= nil, at = th0 and th0.Position or nil })
	end
	if not target then
		return true
	end
	local th = hrpOf(target)
	local dir = flat(th.Position - hrp.Position)
	dir = dir.Magnitude > 0.1 and dir.Unit or look
	local vel = dir * PUSH_POWER + Vector3.new(0, 34, 0)
	if isBot(target) then
		local h = humOf(target)
		if h then
			h.PlatformStand = true
			th.AssemblyLinearVelocity = vel
			task.delay(0.7, function()
				if h.Parent then
					h.PlatformStand = false
					h:ChangeState(Enum.HumanoidStateType.GettingUp)
				end
			end)
		end
	else
		G.Net.Knock:FireClient(target, vel)
	end
	pcall(function()
		G.Net.Slap:FireAllClients("anim", { who = isBot(target) and 0 or target.UserId, char = target.Character, pose = "react", power = 0.8, side = math.random() < 0.5 and -1 or 1 })
	end)
	if not isBot(target) then
		send(target, "pushed", { from = hrp.Position })
	end
	Hill.lastPushed = target
	return true
end

-- CONSTRUCCIÓN ---------------------------------------------------------------------
local RAINBOW = {
	Color3.fromRGB(255, 80, 90), Color3.fromRGB(255, 160, 50), Color3.fromRGB(255, 220, 70),
	Color3.fromRGB(90, 210, 110), Color3.fromRGB(70, 160, 255), Color3.fromRGB(170, 100, 255),
}
local function build()
	local f = Instance.new("Folder")
	f.Name = "KingHill"
	local c = CENTER
	local function cyl(r, h, y, color, mat, collide)
		return part({ Shape = Enum.PartType.Cylinder, Size = Vector3.new(h, r * 2, r * 2), CFrame = CFrame.new(c.X, y, c.Z) * CFrame.Angles(0, 0, math.rad(90)), Color = color, Material = mat or Enum.Material.SmoothPlastic, CanCollide = collide ~= false }, f)
	end
	-- plataforma elevada con columnas
	cyl(R, 2, TOP - 1, Color3.fromRGB(245, 240, 232), Enum.Material.SmoothPlastic).Name = "Arena"
	cyl(R + 0.6, 1.6, TOP - 1.3, Color3.fromRGB(255, 200, 60), Enum.Material.Neon, false).Name = "ArenaRim"
	for i = 1, 6 do -- anillos de colores en el suelo
		local rr = R - (i - 1) * 2.4
		if rr > HILL_R + 1 then
			cyl(rr - 0.2, 0.06, TOP + 0.03 * i, RAINBOW[i]:Lerp(Color3.new(1, 1, 1), 0.45), Enum.Material.SmoothPlastic, false).Name = "Ring"
		end
	end
	for k = 0, 5 do
		local a = k / 6 * math.pi * 2
		part({ Name = "Pillar", Size = Vector3.new(2.4, TOP - 1.5, 2.4), CFrame = CFrame.new(c + Vector3.new(math.cos(a) * (R - 4), (TOP - 1.5) / 2, math.sin(a) * (R - 4))), Color = Color3.fromRGB(110, 90, 160), Material = Enum.Material.Slate }, f)
	end
	-- la colina dorada
	local hillTop = cyl(HILL_R, HILL_H, TOP + HILL_H / 2, Color3.fromRGB(255, 205, 60), Enum.Material.Foil)
	hillTop.Name = "Hill"
	cyl(HILL_R + 0.3, 0.12, TOP + HILL_H + 0.06, Color3.fromRGB(255, 240, 150), Enum.Material.Neon, false).Name = "HillGlow"
	local fx = Instance.new("ParticleEmitter")
	fx.Rate = 14
	fx.Lifetime = NumberRange.new(1.2, 2)
	fx.Speed = NumberRange.new(2, 5)
	fx.EmissionDirection = Enum.NormalId.Right
	fx.LightEmission = 1
	fx.Color = ColorSequence.new(Color3.fromRGB(255, 250, 200), Color3.fromRGB(255, 200, 60))
	fx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 0) })
	fx.Parent = hillTop
	-- corona gigante girando encima (la anima cada cliente: FxSpin)
	local crownC = CFrame.new(c + Vector3.new(0, TOP + 16, 0))
	local cm = Instance.new("Model")
	cm.Name = "BigCrown"
	local base = part({ Name = "CrownBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(1.6, 6, 6), CFrame = crownC * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 205, 50), Material = Enum.Material.Foil, CanCollide = false }, cm)
	for k = 0, 4 do
		local a = k / 5 * math.pi * 2
		part({ Name = "CrownSpike", Size = Vector3.new(1, 2.4, 1), CFrame = crownC * CFrame.new(math.cos(a) * 2.5, 1.9, math.sin(a) * 2.5), Color = Color3.fromRGB(255, 205, 50), Material = Enum.Material.Foil, CanCollide = false }, cm)
		part({ Name = "CrownGem", Shape = Enum.PartType.Ball, Size = Vector3.new(0.8, 0.8, 0.8), CFrame = crownC * CFrame.new(math.cos(a) * 2.5, 3.3, math.sin(a) * 2.5), Color = RAINBOW[k + 1], Material = Enum.Material.Neon, CanCollide = false }, cm)
	end
	cm.PrimaryPart = base
	cm:SetAttribute("BaseCF", crownC)
	cm:SetAttribute("Phase", 0)
	game:GetService("CollectionService"):AddTag(cm, "FxSpin")
	cm.Parent = f
	-- franja roja en el suelo alrededor: "si caes aquí, fuera"
	cyl(R + 4, 0.08, 0.6, Color3.fromRGB(255, 70, 80), Enum.Material.Neon, false).Name = "FallZone"
	cyl(R + 3.4, 0.1, 0.62, Color3.fromRGB(240, 230, 220), Enum.Material.SmoothPlastic, false).Name = "FallZoneInner"
	-- camino corto desde el vestíbulo
	local lobby = G.Config.COURSE.LOBBY
	local d = toLobbyDir()
	local p0 = flat(lobby) - d * 57
	local p1 = flat(c) + d * (R + 6.5)
	local len = (p1 - p0).Magnitude
	if len > 1 then
		part({ Name = "Path", Size = Vector3.new(12, 1, len), CFrame = CFrame.lookAt((p0 + p1) / 2 + Vector3.new(0, 0.5, 0), (p0 + p1) / 2 + Vector3.new(0, 0.5, 0) - d), Color = Color3.fromRGB(255, 220, 120), Material = Enum.Material.SmoothPlastic }, f)
	end
	-- poste con botón para unirse y cartel con plazas
	local postPos = c + d * (R + 4) + Vector3.new(d.Z * 7, 3.5, -d.X * 7)
	local post = part({ Name = "Post", Size = Vector3.new(0.8, 7, 0.8), CFrame = CFrame.new(postPos), Color = Color3.new(1, 1, 1) }, f)
	local bb = Instance.new("BillboardGui")
	bb.Size = UDim2.fromScale(8, 3)
	bb.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	bb.LightInfluence = 0
	bb.MaxDistance = 60
	bb.Parent = post
	local label = Instance.new("TextLabel")
	label.BackgroundTransparency = 1
	label.Size = UDim2.fromScale(1, 1)
	label.TextScaled = true
	label.RichText = true
	label.Font = Enum.Font.LuckiestGuy
	label.TextColor3 = Color3.fromRGB(255, 225, 90)
	label.TextStrokeTransparency = 0.2
	label.Parent = bb
	st.label = label
	local pp = Instance.new("ProximityPrompt")
	pp.Name = "HillPrompt"
	pp.ActionText = "Jugar / Salir"
	pp.ObjectText = "👑 Rey de la colina (máx. 10)"
	pp.HoldDuration = 0.25
	pp.MaxActivationDistance = 12
	pp.RequiresLineOfSight = false
	pp.Parent = post
	pp.Triggered:Connect(function(p)
		Hill.join(p)
	end)
	-- arco con el nombre, mirando al vestíbulo
	local archCF = CFrame.lookAt(c + d * (R + 9) + Vector3.new(0, 11, 0), c + d * (R + 30) + Vector3.new(0, 11, 0))
	local sign = part({ Name = "HillSign", Size = Vector3.new(22, 4.5, 1), CFrame = archCF, Color = Color3.fromRGB(60, 30, 90) }, f)
	for _, sx in ipairs({ -1, 1 }) do
		part({ Name = "SignPost", Size = Vector3.new(1.2, 11, 1.2), CFrame = archCF * CFrame.new(sx * 11.6, -5.5, 0), Color = Color3.fromRGB(255, 200, 60), Material = Enum.Material.Neon }, f)
	end
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		local sg = Instance.new("SurfaceGui")
		sg.Face = face
		sg.LightInfluence = 0
		sg.SizingMode = Enum.SurfaceGuiSizingMode.PixelsPerStud
		sg.PixelsPerStud = 25
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.TextScaled = true
		l.Font = Enum.Font.LuckiestGuy
		l.TextColor3 = Color3.fromRGB(255, 220, 90)
		l.Text = "👑 REY DE LA COLINA 👑"
		l.Parent = sg
		sg.Parent = sign
	end
	-- SE VE DESDE TODO EL MAPA: rótulo flotante gigante + haz de luz dorado
	local beacon = part({ Name = "Beacon", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new(c + Vector3.new(0, 34, 0)), Transparency = 1, CanCollide = false, CanQuery = false, CanTouch = false }, f)
	local big = Instance.new("BillboardGui")
	big.Name = "HillBig"
	big.Size = UDim2.fromScale(44, 11) -- en studs: crece con la distancia como un cartel de verdad
	big.LightInfluence = 0
	big.MaxDistance = 900
	big.Parent = beacon
	local bl = Instance.new("TextLabel")
	bl.BackgroundTransparency = 1
	bl.Size = UDim2.fromScale(1, 1)
	bl.TextScaled = true
	bl.RichText = true
	bl.Font = Enum.Font.LuckiestGuy
	bl.TextColor3 = Color3.fromRGB(255, 215, 80)
	bl.TextStrokeTransparency = 0
	bl.TextStrokeColor3 = Color3.fromRGB(70, 30, 10)
	bl.Parent = big
	st.bigLabel = bl
	local beam = part({ Name = "LightBeam", Shape = Enum.PartType.Cylinder, Size = Vector3.new(160, 5, 5), CFrame = CFrame.new(c + Vector3.new(0, TOP + 80, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 210, 110), Material = Enum.Material.Neon, Transparency = 0.86, CanCollide = false, CanQuery = false, CanTouch = false, CastShadow = false }, f)
	beam.Name = "LightBeam"
	-- PLATAFORMA en el vestíbulo que te lleva a la entrada de la arena
	-- (hueco libre del vestíbulo, entre el centro y los puestos de estelas)
	local padXZ = flat(lobby) - d * 22 + Vector3.new(d.Z, 0, -d.X) * 7
	local hit = workspace:Raycast(Vector3.new(padXZ.X, lobby.Y + 30, padXZ.Z), Vector3.new(0, -80, 0))
	local floorY = hit and hit.Position.Y or (lobby.Y - 3.5)
	local padPos = Vector3.new(padXZ.X, floorY, padXZ.Z)
	part({ Name = "HillPadBase", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.6, 10, 10), CFrame = CFrame.new(padPos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(70, 40, 100), Material = Enum.Material.SmoothPlastic }, f)
	local pad = part({ Name = "HillPad", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.2, 8, 8), CFrame = CFrame.new(padPos + Vector3.new(0, 0.65, 0)) * CFrame.Angles(0, 0, math.rad(90)), Color = Color3.fromRGB(255, 200, 70), Material = Enum.Material.Neon, CanCollide = false }, f)
	local padBB = Instance.new("BillboardGui")
	padBB.Size = UDim2.fromScale(12, 3.2)
	padBB.StudsOffsetWorldSpace = Vector3.new(0, 5, 0)
	padBB.LightInfluence = 0
	padBB.MaxDistance = 150
	padBB.Parent = pad
	local pl = Instance.new("TextLabel")
	pl.BackgroundTransparency = 1
	pl.Size = UDim2.fromScale(1, 1)
	pl.TextScaled = true
	pl.Font = Enum.Font.LuckiestGuy
	pl.TextColor3 = Color3.fromRGB(255, 220, 90)
	pl.TextStrokeTransparency = 0
	pl.Text = "👑 IR AL REY DE LA COLINA"
	pl.Parent = padBB
	local pfx = Instance.new("ParticleEmitter")
	pfx.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	pfx.Rate = 12
	pfx.Lifetime = NumberRange.new(1, 1.6)
	pfx.Speed = NumberRange.new(3, 6)
	pfx.EmissionDirection = Enum.NormalId.Right -- (el cilindro está tumbado: "derecha" es hacia arriba)
	pfx.SpreadAngle = Vector2.new(10, 10)
	pfx.LightEmission = 0.5
	pfx.Color = ColorSequence.new(Color3.fromRGB(255, 230, 140))
	pfx.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
	pfx.Parent = pad
	local cool = {}
	local entry = CFrame.lookAt(c + d * (R + 9) + Vector3.new(0, 3.5, 0), c + Vector3.new(0, 3.5, 0))
	-- (por distancia: Touched falla si apareces encima o estás quieto)
	task.spawn(function()
		while pad.Parent do
			task.wait(0.25)
			for _, p in ipairs(Players:GetPlayers()) do
				local hrp = hrpOf(p)
				if hrp and not (cool[p] and os.clock() - cool[p] < 3) then
					local dxz = flat(hrp.Position - padPos).Magnitude
					local dy = hrp.Position.Y - padPos.Y
					if dxz < 4 and dy > 0 and dy < 6 and not (G.Race.sessions[p] and G.Race.sessions[p].racing) then
						cool[p] = os.clock()
						hrp.AssemblyLinearVelocity = Vector3.zero
						hrp.CFrame = entry
						send(p, "msg", "👑 ¡Pulsa en el poste para entrar a la arena!")
					end
				end
			end
		end
	end)
	Hill.PAD = padPos
	f.Parent = workspace
	broadcast()
end

function Hill.init(g)
	G = g
	G.Hill = Hill
	CENTER = require(script.Parent.Decor).HILL
	Hill.CENTER, Hill.R, Hill.TOP = CENTER, R, TOP
	build()
	G.Net.Hill.OnServerEvent:Connect(function(p, kind)
		if kind == "push" then
			Hill.push(p)
		elseif kind == "leave" then
			Hill.leave(p)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		Hill.leave(p)
		lastPush[p] = nil
	end)
	Players.PlayerAdded:Connect(function(p)
		p.CharacterAdded:Connect(function()
			task.wait(0.7)
			if Hill.memberOf(p) then
				local hrp = hrpOf(p)
				if hrp then
					if st.phase == "playing" or st.phase == "result" then
						hrp.CFrame = spectatorCF()
					else
						hrp.CFrame = ringCF(table.find(st.members, p) or 1, Hill.MAX)
						local h = humOf(p)
						if h then
							h.WalkSpeed = WALK
						end
					end
				end
			end
		end)
	end)
	-- vigilancia: caídas, puntos en la colina, fin de partida, gente que se va lejos
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(function()
				local now = os.clock()
				for i = #st.members, 1, -1 do
					local m = st.members[i]
					local hrp, h = hrpOf(m), humOf(m)
					local dist = hrp and flat(hrp.Position - CENTER).Magnitude or 0
					-- cuenta atrás: todos quietos en su sitio del anillo hasta que empiece
					if h and st.phase == "starting" then
						h.WalkSpeed, h.JumpHeight = 0, 0
					elseif h and st.phase == "idle" and h.WalkSpeed == 0 then
						h.WalkSpeed, h.JumpHeight = WALK, 7.2
					end
					if st.phase == "playing" and st.alive[m] then
						if not hrp or not h or h.Health <= 0 then
							eliminate(m, "💀 ¡Eliminado!")
						elseif hrp.Position.Y < CENTER.Y + TOP + 0.5 or dist > R + 2 then
							eliminate(m, "💥 ¡Te has caído de la arena!")
						elseif dist <= HILL_R and hrp.Position.Y > CENTER.Y + TOP + HILL_H + 1.2 then
							st.score[m] = (st.score[m] or 0) + 0.2
						end
					elseif hrp and dist > R + 45 then
						Hill.leave(m) -- se ha ido andando
					elseif st.phase == "playing" and hrp and not st.alive[m] and dist < R and hrp.Position.Y > CENTER.Y + TOP then
						hrp.CFrame = spectatorCF() -- los eliminados no vuelven a la arena
					end
				end
				if st.phase == "playing" then
					local alive = 0
					for _, m in ipairs(st.members) do
						if st.alive[m] then
							alive += 1
						end
					end
					if alive <= 1 or now >= (st.endsAt or now) then
						finish()
					end
					updateCrown()
				end
			end)
			if not ok then
				warn("[Hill] " .. tostring(err))
			end
		end
	end)
	task.spawn(function() -- estado cada segundo durante la partida (tiempo y puntos)
		while true do
			task.wait(1)
			if st.phase == "playing" then
				pcall(broadcast)
			end
		end
	end)
end

return Hill
