-- Rondas de la carrera: espera → cuenta atrás → carrera → resultados → otra vez.
-- Puesto en directo por lo que ha avanzado cada uno (los que llegan, por orden de llegada).
local Players = game:GetService("Players")

local Race = {}
local G, C, R

Race.sessions = {} -- [player] = { racing, finished, finishTime, progress, cp, item, rolling, nextLucky, shieldUntil, frozenUntil }
Race.state = "break" -- break | joining | countdown | racing | results
Race.endsAt = 0
Race.startedAt = 0
Race.finishers = {} -- jugadores por orden de llegada
Race.WALK = 20

local function hrpOf(player)
	local char = typeof(player) == "Instance" and player.Character
	return char and char:FindFirstChild("HumanoidRootPart")
end
local function humOf(player)
	local char = typeof(player) == "Instance" and player.Character
	return char and char:FindFirstChildOfClass("Humanoid")
end

function Race.newSession(player)
	local s = { racing = false, finished = false, progress = 0, cp = 0, item = nil, rolling = false, nextLucky = 0 }
	Race.sessions[player] = s
	return s
end

-- Puesto de un corredor (1 = primero) y cuántos corren
function Race.rankOf(player)
	local list = {}
	for p, s in pairs(Race.sessions) do
		if s.racing then
			table.insert(list, p)
		end
	end
	local fIndex = {}
	for i, p in ipairs(Race.finishers) do
		fIndex[p] = i
	end
	table.sort(list, function(a, b)
		local fa, fb = fIndex[a], fIndex[b]
		if fa or fb then
			return (fa or math.huge) < (fb or math.huge)
		end
		return Race.sessions[a].progress > Race.sessions[b].progress
	end)
	for i, p in ipairs(list) do
		if p == player then
			return i, #list
		end
	end
	return #list, #list
end

local setCheckpoint
function Race.setCheckpoint(player, s, idx)
	setCheckpoint(player, s, idx)
end
function setCheckpoint(player, s, idx)
	s.cp = idx
	local cp = G.Course.checkpoints[idx]
	if typeof(player) == "Instance" and cp then
		player:SetAttribute("Checkpoint", cp.pos)
	end
end

local function teleport(player, pos, look)
	local hrp = hrpOf(player)
	if hrp then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = CFrame.lookAt(pos, pos + (look or Vector3.new(0, 0, 1)))
	end
end

local function racerCount()
	local n = 0
	for _, s in pairs(Race.sessions) do
		if s.racing and not s.finished then
			n += 1
		end
	end
	return n
end

local function setWalk(player, speed, jump)
	local hum = humOf(player)
	if hum then
		hum.WalkSpeed = speed
		hum.JumpHeight = jump
	end
end

-- Llegada a la meta
function Race.finish(player)
	local s = Race.sessions[player]
	if not s or not s.racing or s.finished then
		return false
	end
	s.finished = true
	s.finishTime = os.clock() - Race.startedAt
	table.insert(Race.finishers, player)
	local place = #Race.finishers
	for _, os2 in pairs(Race.sessions) do
		if os2.isBot and os2.finished then
			place += 1 -- bots que ya habían llegado
		end
	end
	-- corriendo solo no hay premio por puesto ni victoria (se podría granjear); solo lo de terminar
	local contested = (Race.fieldSize or 0) >= 2
	local coins = (contested and (C.REWARDS[place] or 0) or 0) + C.REWARD_FINISH
	G.Data.addCoins(player, coins)
	if place == 1 and contested then
		G.Data.addWin(player)
	end
	if place == 1 then
		G.Net.Event:FireAllClients("winner", { name = typeof(player) == "Instance" and player.DisplayName or "?" })
		Race.endsAt = math.min(Race.endsAt, os.clock() + R.AFTER_WINNER)
	end
	if typeof(player) == "Instance" then
		G.Net.Event:FireClient(player, "finished", { place = place, coins = coins, time = s.finishTime })
		-- al llegar, unos segundos de celebración y de vuelta al vestíbulo (no te quedas esperando)
		task.delay(3.5, function()
			if Race.sessions[player] == s and s.finished then
				s.item, s.rolling = nil, false
				player:SetAttribute("Checkpoint", nil)
				setWalk(player, 16, 7.2)
				teleport(player, C.COURSE.LOBBY + Vector3.new(math.random(-8, 8), 0, math.random(-6, 6)))
			end
		end)
	end
	return true
end

-- Salir de la carrera a mitad (botón): vuelves al vestíbulo y dejas de contar
function Race.quit(player)
	local s = Race.sessions[player]
	if not s or not s.racing or s.finished or (Race.state ~= "racing" and Race.state ~= "countdown") then
		return false
	end
	s.racing, s.item, s.rolling = false, nil, false
	s.speedUntil, s.frozenUntil, s.immuneUntil = nil, nil, nil
	player:SetAttribute("Checkpoint", nil) -- si no, tu pantalla te "devolvería" a tu punto de control
	setWalk(player, 16, 7.2)
	teleport(player, C.COURSE.LOBBY + Vector3.new(math.random(-8, 8), 0, math.random(-6, 6)))
	G.Net.Event:FireClient(player, "toast", { text = "🚪 Has salido de la carrera" })
	return true
end

-- Cada 0,2 s en carrera: avance, puntos de control, meta y lucky blocks
function Race.step()
	if Race.state ~= "racing" then
		return
	end
	local now = os.clock()
	for player, s in pairs(Race.sessions) do
		if s.racing and not s.finished then
			local hrp = hrpOf(player)
			if hrp then
				local pos = hrp.Position
				if pos.Y > C.COURSE.START.Y - C.COURSE.FALL then
					s.progress = math.max(s.progress, pos.Z - C.COURSE.START.Z)
				end
				local cp = G.Course.checkpointAt(pos)
				-- de uno en uno (aparecer de golpe más adelante = teletransporte del cliente: no cuenta)
				if cp and cp == s.cp + 1 then
					setCheckpoint(player, s, cp)
					if typeof(player) == "Instance" then
						G.Net.Event:FireClient(player, "checkpoint", { index = cp })
					end
				end
				-- meta: haber pasado el último punto de control y un tiempo creíble (el recorrido limpio son ~60 s)
				local lastCp = #G.Course.checkpoints
				if pos.Z >= G.Course.finishZ and pos.Y > C.COURSE.START.Y - 8 and s.cp >= lastCp and now - Race.startedAt >= 25 then
					Race.finish(player)
				end
			end
			if not s.item and not s.rolling and now >= s.nextLucky then
				G.Items.grant(player)
			end
		end
	end
end

local function playersReady()
	local n = 0
	for _, p in ipairs(Players:GetPlayers()) do
		if Race.sessions[p] then
			n += 1
		end
	end
	return n
end

-- Apuntarse / desapuntarse a la próxima carrera (botón "Entrar a la carrera"; solo en la fase de inscripción)
Race.joined = {} -- [player] = true
function Race.setJoined(player, on)
	if Race.state ~= "joining" or not Race.sessions[player] then
		return false
	end
	Race.joined[player] = on and true or nil
	if on and G.Slap and G.Slap.leave then
		G.Slap.leave(player) -- si estaba en un minijuego de la plaza, sale
	end
	return true
end

-- Bucle de rondas (en su propia tarea):
-- descanso (BREAK) → inscripción con botón (JOIN_TIME) → cuenta atrás → carrera → resultados → otra vez
local courseUsed = true
function Race.loop()
	while true do
		Race.state = "break"
		Race.endsAt = os.clock() + R.BREAK
		while os.clock() < Race.endsAt do
			task.wait(0.25)
		end
		-- inscripción: el recorrido nuevo se construye solo si el anterior ya se corrió
		Race.state = "joining"
		table.clear(Race.joined)
		Race.endsAt = os.clock() + R.JOIN_TIME
		if courseUsed or not workspace:FindFirstChild("Course") then
			G.Course.build(math.random(1, 1e9))
			courseUsed = false
		end
		while os.clock() < Race.endsAt do
			task.wait(0.25)
		end
		local list = {}
		for _, p in ipairs(Players:GetPlayers()) do
			local s = Race.sessions[p]
			if s and Race.joined[p] and hrpOf(p) then
				table.insert(list, p)
			end
		end
		table.clear(Race.joined)
		local botsRunning = Race.extraRunners and Race.extraRunners(true) or 0
		if #list < R.MIN_PLAYERS and botsRunning == 0 then
			continue -- nadie se apuntó: otro descanso
		end
		courseUsed = true
		Race.fieldSize = #list
		-- salida: los apuntados a la parrilla, quietos durante la cuenta atrás
		table.clear(Race.finishers)
		G.Items.clear()
		for i, p in ipairs(list) do
			local s = Race.sessions[p]
			s.racing, s.finished, s.progress, s.item, s.rolling = true, false, 0, nil, false
			s.shieldUntil, s.frozenUntil, s.finishTime = 0, nil, nil
			s.immuneUntil, s.speedUntil = nil, nil -- (Shadow) que no se arrastren efectos de la carrera anterior
			s.nextLucky = os.clock() + R.COUNTDOWN + 3
			setCheckpoint(p, s, 0)
			local col = (i - 1) % 6
			local row = math.floor((i - 1) / 6)
			teleport(p, C.COURSE.START + Vector3.new(-7.5 + col * 3, 3, -6 - row * 3.5))
			setWalk(p, 0, 0)
		end
		Race.state = "countdown"
		Race.endsAt = os.clock() + R.COUNTDOWN
		while os.clock() < Race.endsAt do
			task.wait(0.1)
		end
		for _, p in ipairs(list) do
			setWalk(p, Race.WALK, 7.2)
		end
		Race.state = "racing"
		Race.startedAt = os.clock()
		Race.endsAt = os.clock() + R.RACE_TIME
		while os.clock() < Race.endsAt and (racerCount() > 0 or (Race.extraRunners and Race.extraRunners(false) or 0) > 0) do
			task.wait(0.2)
		end
		-- resultados: monedas por participar a los que no llegaron
		Race.state = "results"
		local results = {}
		for _, p in ipairs(list) do
			local s = Race.sessions[p]
			if s then
				if not s.finished then
					G.Data.addCoins(p, C.REWARD_PLAY)
				end
				local rank = Race.rankOf(p)
				table.insert(results, { name = typeof(p) == "Instance" and p.DisplayName or "?", rank = rank, time = s.finishTime })
			end
		end
		table.sort(results, function(a, b)
			return a.rank < b.rank
		end)
		G.Net.Event:FireAllClients("results", { list = results })
		Race.endsAt = os.clock() + R.RESULTS
		while os.clock() < Race.endsAt do
			task.wait(0.25)
		end
		for _, p in ipairs(list) do
			local s = Race.sessions[p]
			if s then
				s.racing, s.item, s.rolling = false, nil, false
				setWalk(p, 16, 7.2)
				teleport(p, C.COURSE.LOBBY + Vector3.new(math.random(-8, 8), 0, math.random(-6, 6)))
			end
		end
	end
end

-- Estado para cada cliente (4 veces por segundo)
function Race.sendState()
	local total = 0
	for _, s in pairs(Race.sessions) do
		if s.racing then
			total += 1
		end
	end
	for player, s in pairs(Race.sessions) do
		if typeof(player) == "Instance" then
			local rank = s.racing and Race.rankOf(player) or 0
			G.Net.State:FireClient(player, {
				state = Race.state,
				left = math.max(0, Race.endsAt - os.clock()),
				elapsed = Race.state == "racing" and (os.clock() - Race.startedAt) or 0,
				racing = s.racing,
				finished = s.finished,
				rank = rank,
				total = total,
				item = s.item,
				rolling = s.rolling,
				progress = G.Course.length > 0 and math.clamp(s.progress / G.Course.length, 0, 1) or 0,
				coins = G.Data.coins(player),
				shield = s.shieldUntil and os.clock() < s.shieldUntil or false,
				joined = Race.joined[player] == true,
			})
		end
	end
end

function Race.init(g)
	G = g
	C = g.Config
	R = C.ROUND
	Players.PlayerAdded:Connect(function(p)
		Race.newSession(p)
		G.Data.load(p)
		p.CharacterAdded:Connect(function(char)
			-- en carrera, reaparecer en tu punto de control; si no, en el vestíbulo
			local hrp = char:WaitForChild("HumanoidRootPart", 10)
			local hum = char:WaitForChild("Humanoid", 10)
			task.wait(0.1)
			local s = Race.sessions[p]
			if not hrp or not hum or not s then
				return
			end
			if s.racing and not s.finished and (Race.state == "racing" or Race.state == "countdown") then
				local cp = G.Course.checkpoints[s.cp]
				teleport(p, cp and cp.pos or C.COURSE.START + Vector3.new(0, 3, 0))
				hum.WalkSpeed = Race.WALK
			else
				teleport(p, C.COURSE.LOBBY)
				hum.WalkSpeed = 16
			end
		end)
	end)
	G.Net.Join.OnServerEvent:Connect(function(p, on)
		if on == "quit" then
			Race.quit(p)
		else
			Race.setJoined(p, on == true)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		G.Data.release(p)
		Race.joined[p] = nil
		Race.sessions[p] = nil
	end)
	for _, p in ipairs(Players:GetPlayers()) do
		Race.newSession(p)
		G.Data.load(p)
	end
end

function Race.start()
	task.spawn(function() -- si una ronda da error, se avisa y vuelve a empezar (no se congelan las rondas)
		while true do
			local ok, err = pcall(Race.loop)
			warn("[Race] " .. tostring(err))
			local _ = ok
			task.wait(2)
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(Race.step)
			if not ok then
				warn("[Race] " .. tostring(err))
			end
		end
	end)
	task.spawn(function()
		while true do
			task.wait(0.25)
			pcall(Race.sendState)
		end
	end)
end

return Race
