-- Objetos del lucky block. Todo lo decide el servidor; el cliente solo pide "usar" con el punto al que apunta.
--   rock    piedra con parábola: empuja al que toca
--   bow     flecha recta y rápida, de lejos
--   banana  cáscara en el suelo detrás de ti: quien la pisa resbala
--   gust    soplido: empuja a todos los que tienes cerca
--   shield  escudo: bloquea el siguiente golpe (8 s)
--   swap    cambiazo: te cambias de sitio con alguien que va por delante
--   freeze  congelación: todos los demás quietos 2 s
local RunService = game:GetService("RunService")
local Debris = game:GetService("Debris")

local Items = {}
local G, C

local bananas = {} -- { part, owner, untilT }

local function hrpOf(player)
	local char = typeof(player) == "Instance" and player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end

local function notify(player, kind, data)
	if typeof(player) == "Instance" then
		G.Net.Event:FireClient(player, kind, data or {})
	end
end

-- Empujón (con escudo, se bloquea y se gasta el escudo)
function Items.knock(target, vel, by, itemId)
	local s = G.Race.sessions[target]
	if not s then
		return false
	end
	if s.shieldUntil and os.clock() < s.shieldUntil then
		s.shieldUntil = 0
		local char = typeof(target) == "Instance" and target.Character
		local ff = char and char:FindFirstChild("LuckyShield")
		if ff then
			ff:Destroy()
		end
		notify(target, "blocked")
		return false
	end
	if typeof(target) == "Instance" then
		G.Net.Knock:FireClient(target, vel)
	end
	local item = C.ITEM_BY_ID[itemId]
	if by then
		notify(target, "hitBy", { name = by.DisplayName, item = itemId })
		notify(by, "youHit", { name = typeof(target) == "Instance" and target.DisplayName or "?" })
	end
	s.lastHitAt = os.clock()
	return item ~= nil
end

-- Proyectil simulado en el servidor (pieza visual anclada que avanza cada paso)
local function projectile(owner, from, vel, gravity, life, radius, look, onHit)
	local p = Instance.new("Part")
	p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.CastShadow = true, false, false, false, false
	for k, v in pairs(look) do
		p[k] = v
	end
	p.CFrame = CFrame.new(from)
	p.Parent = workspace
	local pos, v, t0 = from, vel, os.clock()
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = { workspace:FindFirstChild("Course") }
	local conn
	conn = RunService.Heartbeat:Connect(function(dt)
		v += Vector3.new(0, -gravity * dt, 0)
		local nextPos = pos + v * dt
		-- ¿toca a algún corredor? (distancia del segmento recorrido a su raíz)
		for player, s in pairs(G.Race.sessions) do
			if player ~= owner and s.racing then
				local hrp = hrpOf(player)
				if hrp then
					local seg = nextPos - pos
					local tt = seg.Magnitude > 0 and math.clamp((hrp.Position - pos):Dot(seg) / seg:Dot(seg), 0, 1) or 0
					if (pos + seg * tt - hrp.Position).Magnitude <= radius then
						conn:Disconnect()
						p:Destroy()
						onHit(player, v)
						return
					end
				end
			end
		end
		local hit = params.FilterDescendantsInstances[1] and workspace:Raycast(pos, nextPos - pos, params)
		pos = nextPos
		p.CFrame = CFrame.lookAt(pos, pos + v)
		if hit or os.clock() - t0 > life then
			conn:Disconnect()
			Debris:AddItem(p, 0.05)
		end
	end)
end

local USE = {}

function USE.rock(player, hrp, aim)
	local from = hrp.Position + Vector3.new(0, 2.5, 0)
	local dir = (aim - from)
	dir = Vector3.new(dir.X, 0, dir.Z).Magnitude > 0.1 and Vector3.new(dir.X, 0, dir.Z).Unit or hrp.CFrame.LookVector
	projectile(player, from + dir * 2, dir * 85 + Vector3.new(0, 30, 0), 120, 2.2, 3.2, { Name = "Rock", Shape = Enum.PartType.Ball, Size = Vector3.new(1.6, 1.6, 1.6), Color = Color3.fromRGB(140, 130, 120), Material = Enum.Material.Slate }, function(target, v)
		local flat = Vector3.new(v.X, 0, v.Z)
		flat = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
		Items.knock(target, flat * C.KNOCK + Vector3.new(0, 38, 0), player, "rock")
	end)
	return true
end

function USE.bow(player, hrp, aim)
	local from = hrp.Position + Vector3.new(0, 2, 0)
	local dir = (aim - from).Magnitude > 0.1 and (aim - from).Unit or hrp.CFrame.LookVector
	projectile(player, from + dir * 2, dir * 210, 8, 1.2, 2.6, { Name = "Arrow", Size = Vector3.new(0.25, 0.25, 3), Color = Color3.fromRGB(200, 150, 90), Material = Enum.Material.Wood }, function(target, v)
		local flat = Vector3.new(v.X, 0, v.Z)
		flat = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
		Items.knock(target, flat * (C.KNOCK * 0.8) + Vector3.new(0, 30, 0), player, "bow")
	end)
	return true
end

function USE.banana(player, hrp)
	local behind = hrp.Position - hrp.CFrame.LookVector * 3 - Vector3.new(0, 2.6, 0)
	local p = Instance.new("Part")
	p.Name = "Banana"
	p.Anchored, p.CanCollide, p.CanQuery, p.CastShadow = true, false, false, false
	p.Size = Vector3.new(1.8, 0.4, 1)
	p.Color = Color3.fromRGB(255, 220, 60)
	p.Material = Enum.Material.SmoothPlastic
	p.CFrame = CFrame.new(behind) * CFrame.Angles(0, math.random() * 6.28, 0)
	p.Parent = workspace
	table.insert(bananas, { part = p, owner = player, untilT = os.clock() + 25 })
	return true
end

function USE.gust(player, hrp)
	for other, s in pairs(G.Race.sessions) do
		local o = other ~= player and s.racing and hrpOf(other)
		if o then
			local d = o.Position - hrp.Position
			if d.Magnitude <= 20 then
				local flat = Vector3.new(d.X, 0, d.Z)
				flat = flat.Magnitude > 0.1 and flat.Unit or hrp.CFrame.LookVector
				Items.knock(other, flat * C.KNOCK * 0.95 + Vector3.new(0, 34, 0), player, "gust")
			end
		end
	end
	G.Net.Event:FireAllClients("gustFx", { pos = hrp.Position })
	return true
end

function USE.shield(player)
	local s = G.Race.sessions[player]
	s.shieldUntil = os.clock() + C.SHIELD_TIME
	local char = typeof(player) == "Instance" and player.Character
	if char then
		local ff = Instance.new("ForceField")
		ff.Name = "LuckyShield"
		ff.Visible = true
		ff.Parent = char
		task.delay(C.SHIELD_TIME, function()
			if ff.Parent then
				ff:Destroy()
			end
		end)
	end
	notify(player, "shieldOn")
	return true
end

function USE.swap(player, hrp)
	local s = G.Race.sessions[player]
	local ahead = {}
	for other, os2 in pairs(G.Race.sessions) do
		if other ~= player and os2.racing and not os2.finished and os2.progress > s.progress and hrpOf(other) then
			table.insert(ahead, other)
		end
	end
	if #ahead == 0 then
		return false -- nadie delante: no se gasta
	end
	local other = ahead[math.random(1, #ahead)]
	local o = hrpOf(other)
	local a, b = hrp.CFrame, o.CFrame
	hrp.CFrame, o.CFrame = b, a
	local os2 = G.Race.sessions[other]
	s.progress, os2.progress = os2.progress, s.progress
	s.cp, os2.cp = math.max(s.cp, os2.cp), os2.cp
	notify(player, "swapped", { name = other.DisplayName })
	notify(other, "swapped", { name = typeof(player) == "Instance" and player.DisplayName or "?" })
	return true
end

function USE.freeze(player)
	for other, s in pairs(G.Race.sessions) do
		if other ~= player and s.racing and not s.finished then
			s.frozenUntil = os.clock() + C.FREEZE_TIME
			local hum = typeof(other) == "Instance" and other.Character and other.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = 0
				hum.JumpHeight = 0
			end
		end
	end
	G.Net.Event:FireAllClients("frozen", { name = typeof(player) == "Instance" and player.DisplayName or "?", by = typeof(player) == "Instance" and player.UserId or 0, time = C.FREEZE_TIME })
	return true
end

-- Usar el objeto que llevas (aim = punto al que apuntas)
function Items.use(player, aim)
	local s = G.Race.sessions[player]
	if not s or not s.racing or s.finished or not s.item or s.rolling then
		return false
	end
	if s.frozenUntil and os.clock() < s.frozenUntil then
		return false
	end
	local hrp = hrpOf(player)
	if not hrp and typeof(player) == "Instance" then
		return false
	end
	if typeof(aim) ~= "Vector3" or aim ~= aim then
		aim = hrp and (hrp.Position + hrp.CFrame.LookVector * 40) or Vector3.zero
	end
	local fn = USE[s.item]
	local ok, used = pcall(fn, player, hrp, aim)
	if ok and used then
		s.item = nil
		s.nextLucky = os.clock() + C.LUCKY_EVERY
		return true
	end
	return false
end

-- Lucky block: el objeto depende de tu puesto (los de detrás, mejores)
function Items.grant(player)
	local s = G.Race.sessions[player]
	if not s or s.item or s.rolling then
		return nil
	end
	local rank, total = G.Race.rankOf(player)
	local p = total > 1 and (rank - 1) / (total - 1) or 0.5
	local d = G.Data and G.Data.profiles[player]
	local id = C.rollItem(C.luckP(p, d and d.luck or 0))
	s.rolling = true
	notify(player, "lucky", { item = id, roll = C.ROLL_TIME })
	task.delay(C.ROLL_TIME, function()
		if G.Race.sessions[player] == s then
			s.rolling = false
			s.item = id
		end
	end)
	return id
end

-- Cada 0,1 s: cáscaras pisadas y fin de la congelación
local function tick()
	local now = os.clock()
	for i = #bananas, 1, -1 do
		local b = bananas[i]
		if now > b.untilT or not b.part.Parent then
			b.part:Destroy()
			table.remove(bananas, i)
		else
			for player, s in pairs(G.Race.sessions) do
				local hrp = s.racing and hrpOf(player)
				if hrp and player ~= b.owner and (hrp.Position - b.part.Position).Magnitude < 3.2 then
					b.part:Destroy()
					table.remove(bananas, i)
					local fwd = hrp.CFrame.LookVector
					if Items.knock(player, fwd * 30 + Vector3.new(math.random(-20, 20), 20, 0), nil, "banana") ~= nil then
						notify(player, "slipped", { time = C.SLIP_TIME })
					end
					break
				end
			end
		end
	end
	for player, s in pairs(G.Race.sessions) do
		if s.frozenUntil and now >= s.frozenUntil then
			s.frozenUntil = nil
			local hum = typeof(player) == "Instance" and player.Character and player.Character:FindFirstChildOfClass("Humanoid")
			if hum then
				hum.WalkSpeed = G.Race.WALK
				hum.JumpHeight = 7.2
			end
		end
	end
end

function Items.clear()
	for _, b in ipairs(bananas) do
		b.part:Destroy()
	end
	table.clear(bananas)
end

function Items.init(g)
	G = g
	C = g.Config
	G.Net.Use.OnServerEvent:Connect(function(player, aim)
		Items.use(player, aim)
	end)
	task.spawn(function()
		while true do
			task.wait(0.1)
			pcall(tick)
		end
	end)
end

return Items
