-- Anti-trampas de movimiento (servidor). Petición del dueño.
-- El personaje lo mueve el cliente, así que un exploit puede teletransportarse, volar o correr más de la cuenta.
-- Aquí el servidor vigila cada 0,2 s:
--   · TELETRANSPORTE / SPEEDHACK: avance horizontal mayor que el que permite tu WalkSpeed (con margen).
--   · VUELO: más de 2,5 s en el aire, sin caer, sin suelo debajo.
-- Al detectarlo: si llevas un sobre, vuelve a su nido; te devuelve al último punto válido; y si se repite
-- mucho en poco tiempo, te expulsa. No da falsos positivos con los movimientos del propio juego:
--   · todo lo que el SERVIDOR mueve (cinta, parcela, portal del obby, AFK...) dispara CFrame en el servidor
--     y abre un margen de 1,5 s (los movimientos físicos del cliente no disparan esa señal);
--   · el vuelo por el golpe del guardián (invulnUntil), el obby (plataformas, viento, impulsores) y la cinta
--     (anclado) quedan fuera de la vigilancia.
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local AntiCheat = {}
local G

AntiCheat.CHECK = 0.2 -- segundos entre comprobaciones
AntiCheat.SPEED_FACTOR = 1.6 -- margen sobre tu WalkSpeed
AntiCheat.SPEED_EXTRA = 16 -- studs de margen por comprobación (lag, saltos, rampas)
AntiCheat.AIR_SECS = 2.5 -- segundos en el aire sin caer = vuelo
AntiCheat.KICK_STRIKES = 10 -- avisos en KICK_WINDOW segundos para expulsar
AntiCheat.KICK_WINDOW = 60

local recs = {} -- [player] = { last, t, safe, grace, air, strikes }

-- Para otros módulos: "voy a mover a este jugador, no lo cuentes como trampa"
function AntiCheat.allow(player, secs)
	local r = recs[player]
	if r then
		r.grace = math.max(r.grace, os.clock() + (secs or 1.5))
		r.last = nil
	end
end

local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Exclude

-- suelo bajo los pies: un bloque de 3x1x3 hacia abajo (un rayo fino fallaba en los bordes de un saliente)
local function grounded(char, pos)
	rayParams.FilterDescendantsInstances = { char }
	return workspace:Blockcast(CFrame.new(pos), Vector3.new(3, 1, 3), Vector3.new(0, -14, 0), rayParams) ~= nil
end

-- ¿está cerca de la isla del Olimpo? (la exención del obby solo vale allí)
local function nearIsland(pos)
	local O = G.Config.OBBY
	if not O then
		return false
	end
	local c = O.CENTER
	return pos.Y > c.Y - 120 and Vector3.new(pos.X - c.X, 0, pos.Z - c.Z).Magnitude < O.RADIUS + 120
end

local function hook(player, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	local old = recs[player]
	if old and old.conns then
		for _, c in ipairs(old.conns) do
			c:Disconnect()
		end
	end
	local r = { grace = os.clock() + 3, air = 0, strikes = old and old.strikes or {}, last = nil, safe = hrp.Position, conns = {}, wsMax = 16, wsAt = 0, lowY = hrp.Position.Y }
	recs[player] = r
	-- solo el servidor dispara estas señales al mover el personaje: margen para no confundirlo con trampa
	r.conns[1] = hrp:GetPropertyChangedSignal("CFrame"):Connect(function()
		r.grace = math.max(r.grace, os.clock() + 1.5)
		r.last = nil
		r.air = 0
	end)
	r.conns[2] = hrp:GetPropertyChangedSignal("Anchored"):Connect(function()
		r.grace = math.max(r.grace, os.clock() + 1.5)
		r.last = nil
	end)
end

local function punish(player, s, r, hrp, why, kind)
	local now = os.clock()
	table.insert(r.strikes, now)
	while r.strikes[1] and now - r.strikes[1] > AntiCheat.KICK_WINDOW do
		table.remove(r.strikes, 1)
	end
	warn(string.format("[SAG] AntiCheat %s (%d): %s · avisos %d", player.Name, player.UserId, why, #r.strikes))
	-- 1) el sobre robado vuelve a su nido (no al primer aviso de velocidad: un tirón de red no te quita el sobre)
	if s.carrying and G.Packs and G.Packs.dropCarried and (kind ~= "speed" or #r.strikes >= 2) then
		pcall(G.Packs.dropCarried, player, false)
		G.Net.toast(player, "acPack")
	end
	-- 2) de vuelta al último punto válido
	if r.safe then
		hrp.AssemblyLinearVelocity = Vector3.zero
		hrp.CFrame = CFrame.new(r.safe + Vector3.new(0, 3, 0)) -- (abre su propio margen: ver hook)
	end
	if #r.strikes == 3 then
		G.Net.toast(player, "acWarn")
	end
	-- 3) si insiste, fuera (solo por vuelo o saltos enormes: a una víctima la pueden lanzar otros por los aires)
	r.hard = (r.hard or 0) + ((kind ~= "speed" or why:find("tele")) and 1 or 0)
	if #r.strikes >= AntiCheat.KICK_STRIKES and r.hard >= 3 then
		player:Kick("⚠️ Movimiento no válido detectado. / Invalid movement detected.")
	end
end

local function step(now)
	for player, s in pairs(G.Core.sessions) do
		local r = recs[player]
		local char = player.Character
		local hrp = char and char:FindFirstChild("HumanoidRootPart")
		local hum = char and char:FindFirstChildOfClass("Humanoid")
		if r and hrp and hum and hum.Health > 0 then
			local pos = hrp.Position
			-- velocidad permitida: la mayor del último segundo (si el servidor la baja, el cliente tarda en enterarse)
			if hum.WalkSpeed >= r.wsMax or now - r.wsAt > 1 then
				r.wsMax, r.wsAt = math.max(hum.WalkSpeed, 16), now
			end
			-- en el obby solo se exime cerca de la isla; allí se vigila con margen grande (cintas, viento, impulsores)
			local inObby = s.inObby and nearIsland(pos)
			local exempt = hrp.Anchored or s.locked or s.afk or now < r.grace or now < (s.invulnUntil or 0) or hum.SeatPart ~= nil
			if exempt then
				r.last, r.t, r.air, r.lowY = pos, now, 0, pos.Y
			else
				local bad, kind
				if r.last then
					-- si el servidor no ha recibido movimiento (tirón de red), no avanza la referencia: el margen se acumula
					local moved = (pos - r.last).Magnitude > 0.05
					local dt = math.clamp(now - r.t, 1 / 60, 2)
					local flat = Vector3.new(pos.X - r.last.X, 0, pos.Z - r.last.Z).Magnitude
					local limit = r.wsMax * AntiCheat.SPEED_FACTOR * dt + AntiCheat.SPEED_EXTRA + (inObby and 14 or 0)
					-- en el obby, caer o tocar lo rojo te devuelve a tu punto de control desde el cliente: eso no es trampa
					local backToPad = false
					if inObby and flat > limit and G.Obby and G.Obby.spawnCF then
						local d = G.Data.profiles[player]
						local stage = d and d.obby and d.obby.stage or 0
						local ok, cf = pcall(G.Obby.spawnCF, stage)
						backToPad = ok and cf and (pos - cf.Position).Magnitude < 12
					end
					if flat > limit and not backToPad then
						kind = "speed"
						bad = string.format("%s %.0f studs en %.2fs (máx %.0f)", flat > limit * 4 and "teletransporte" or "velocidad", flat, dt, limit)
					end
					if not moved and not bad then
						pos = r.last -- seguimos midiendo desde el último punto conocido
					end
				end
				-- vuelo: sin suelo debajo durante AIR_SECS sin haber caído de verdad (se mira la altura, no la velocidad que dice el cliente)
				if not bad and not inObby then
					local onGround = grounded(char, hrp.Position)
					if onGround then
						r.air, r.lowY = 0, hrp.Position.Y
						r.safe = hrp.Position
					else
						if hrp.Position.Y < r.lowY - 3 then
							r.air, r.lowY = 0, hrp.Position.Y -- está cayendo: no es vuelo
						else
							r.air += now - (r.t or now)
							if r.air > AntiCheat.AIR_SECS then
								kind = "fly"
								bad = string.format("vuelo %.1fs", r.air)
								r.air = 0
							end
						end
					end
				end
				if bad then
					punish(player, s, r, hrp, bad, kind)
					r.last, r.t = nil, now
				elseif not r.last or (pos - r.last).Magnitude > 0.05 or now - r.t > 2 then
					r.last, r.t = hrp.Position, now
				end
			end
			-- "estoy en el obby" pero lejos de la isla: se le saca del obby (si no, quedaba exento en todo el mapa)
			if s.inObby and not nearIsland(hrp.Position) and now > r.grace and G.Obby and G.Obby.leave then
				pcall(G.Obby.leave, player)
			end
		end
	end
end

function AntiCheat.init(g)
	G = g
	G.AntiCheat = AntiCheat
	local function watch(player)
		player.CharacterAdded:Connect(function(char)
			hook(player, char)
		end)
		if player.Character then
			task.spawn(hook, player, player.Character)
		end
	end
	Players.PlayerAdded:Connect(watch)
	for _, p in ipairs(Players:GetPlayers()) do
		watch(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		recs[p] = nil
	end)
	local acc = 0
	RunService.Heartbeat:Connect(function(dt)
		acc += dt
		if acc < AntiCheat.CHECK then
			return
		end
		acc = 0
		local ok, err = pcall(step, os.clock())
		if not ok then
			warn("[SAG] AntiCheat: " .. tostring(err))
		end
	end)
end

return AntiCheat
