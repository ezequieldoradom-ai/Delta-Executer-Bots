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
AntiCheat.SPEED_EXTRA = 9 -- studs de margen por comprobación (lag, saltos, rampas)
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

local function grounded(char, pos)
	rayParams.FilterDescendantsInstances = { char }
	return workspace:Raycast(pos, Vector3.new(0, -14, 0), rayParams) ~= nil
end

local function hook(player, char)
	local hrp = char:WaitForChild("HumanoidRootPart", 10)
	if not hrp then
		return
	end
	local r = { grace = os.clock() + 3, air = 0, strikes = {}, last = nil, safe = hrp.Position }
	recs[player] = r
	-- solo el servidor dispara estas señales al mover el personaje: margen para no confundirlo con trampa
	hrp:GetPropertyChangedSignal("CFrame"):Connect(function()
		r.grace = math.max(r.grace, os.clock() + 1.5)
		r.last = nil
		r.air = 0
	end)
	hrp:GetPropertyChangedSignal("Anchored"):Connect(function()
		r.grace = math.max(r.grace, os.clock() + 1.5)
		r.last = nil
	end)
end

local function punish(player, s, r, hrp, why)
	local now = os.clock()
	table.insert(r.strikes, now)
	while r.strikes[1] and now - r.strikes[1] > AntiCheat.KICK_WINDOW do
		table.remove(r.strikes, 1)
	end
	warn(string.format("[SAG] AntiCheat %s (%d): %s · avisos %d", player.Name, player.UserId, why, #r.strikes))
	-- 1) el sobre robado vuelve a su nido
	if s.carrying and G.Packs and G.Packs.dropCarried then
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
	-- 3) si insiste, fuera
	if #r.strikes >= AntiCheat.KICK_STRIKES then
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
			local exempt = hrp.Anchored or s.inObby or s.locked or s.afk or now < r.grace or now < (s.invulnUntil or 0) or hum.Sit
			if exempt then
				r.last, r.t, r.air = pos, now, 0
			else
				local bad
				if r.last then
					local dt = math.max(now - r.t, 1 / 60)
					local flat = Vector3.new(pos.X - r.last.X, 0, pos.Z - r.last.Z).Magnitude
					local limit = math.max(hum.WalkSpeed, 16) * AntiCheat.SPEED_FACTOR * dt + AntiCheat.SPEED_EXTRA
					if flat > limit then
						bad = string.format("velocidad %.0f studs en %.2fs (máx %.0f)", flat, dt, limit)
					end
				end
				-- vuelo: en el aire, sin suelo debajo y sin caer
				if not bad then
					local onGround = grounded(char, pos)
					if not onGround and math.abs(hrp.AssemblyLinearVelocity.Y) < 6 then
						r.air += now - (r.t or now)
						if r.air > AntiCheat.AIR_SECS then
							bad = string.format("vuelo %.1fs", r.air)
							r.air = 0
						end
					else
						r.air = 0
						if onGround then
							r.safe = pos
						end
					end
				end
				if bad then
					punish(player, s, r, hrp, bad)
					r.last, r.t = nil, now
				else
					r.last, r.t = pos, now
				end
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
