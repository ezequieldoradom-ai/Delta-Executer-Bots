-- Lucky Obby Race — servidor
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Shared = ReplicatedStorage:WaitForChild("Shared")

local G = {
	Config = require(Shared.Config),
	Net = {},
	Data = require(script.Data),
	Course = require(script.Course),
	Race = require(script.Race),
	Items = require(script.Items),
	Lobby = require(script.Lobby),
}

-- Canales servidor <-> cliente
local remotes = Instance.new("Folder")
remotes.Name = "Remotes"
for _, name in ipairs({ "State", "Event", "Knock", "Use", "Join", "Slap" }) do
	local ev = Instance.new("RemoteEvent")
	ev.Name = name
	ev.Parent = remotes
	G.Net[name] = ev
end
remotes.Parent = ReplicatedStorage

G.Data.init()
G.Course.init(G)
G.Lobby.init(G)
local hub = script:FindFirstChild("Hub")
if hub then
	require(hub).init(G) -- clasificaciones y santuario de la suerte (Shadow)
end
-- decoración (solo visual; módulo opcional de Shadow): isla del vestíbulo, islas, arcos, meta
local decor = script:FindFirstChild("Decor")
if decor then
	require(decor).init(G)
end
local plaza = script:FindFirstChild("Plaza")
if plaza then
	require(plaza).init(G) -- suelo del vestíbulo, caminos con señales y portal al obby (Shadow)
end
local extras = script:FindFirstChild("Extras")
if extras then
	require(extras).init(G) -- cajas lucky, récords y tienda de estelas (Shadow)
end
local slap = script:FindFirstChild("Slap")
if slap then
	require(slap).init(G) -- minijuego "¿Quién ha sido?" en la plaza (Shadow)
end
local feedback = script:FindFirstChild("Feedback")
if feedback then
	require(feedback).init(G) -- buzón de ideas y fallos (Shadow)
end
G.Items.init(G)
local bots = script:FindFirstChild("Bots")
if bots then
	require(bots).init(G) -- bots en servidores con poca gente (Shadow)
end
G.Race.init(G)
G.Race.start()
print("🏁 Lucky Obby Race listo")

-- Solo en Studio: ServerStorage.StudioDebug:Invoke("use", player, itemId) da y usa un objeto (para probar)
if game:GetService("RunService"):IsStudio() then
	local bf = Instance.new("BindableFunction")
	bf.Name = "StudioDebug"
	bf.OnInvoke = function(cmd, player, arg)
		if cmd == "slapjoin" then
			G.Slap.debugJoin(player, arg)
			return G.Slap.debugState(arg)
		end
		if cmd == "bots" then
			local B = require(script.Bots)
			local t = {}
			for _, b in ipairs(B.list) do
				local h = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
				if b.role == "race" and h then
					table.insert(t, string.format("%s z=%d cp=%s d=%s wp=%s", b.Name, h.Position.Z, tostring(b.cp), tostring(b.deaths), tostring(b.wpi)))
				end
			end
			return table.concat(t, " | ") .. " || kinds=" .. table.concat(G.Course.kinds or {}, ",")
		end
		if cmd == "selftest" then
			task.spawn(function()
				require(script.SelfTest).run(G, player, require(script.Hub), require(script.Extras), require(script.Feedback), require(script.Bots))
			end)
			return "lanzado"
		end
		if cmd == "stopat" then -- pega YA parando la barra a 'arg' de distancia del rojo y devuelve el resultado
			G.Slap.lastResult = nil
			G.Slap.debugPos = arg
			if not G.Slap.request(player) then
				G.Slap.debugPos = nil
				local sid = G.Slap.stationOf(player)
				return "no me toca", sid, sid and G.Slap.debugState(sid)
			end
			task.wait(0.4)
			G.Slap.stop(player, nil)
			for _ = 1, 40 do
				if G.Slap.lastResult then
					break
				end
				task.wait(0.1)
			end
			local r = G.Slap.lastResult
			task.wait(0.3)
			local vh = r and r.victim and r.victim.Character and r.victim.Character:FindFirstChildOfClass("Humanoid")
			return r and string.format("dist=%.3f fuerza=%d%% supremo=%s esquivado=%s vidaVictima=%s", arg, math.floor(r.power * 100), tostring(r.supreme), tostring(r.dodged), vh and math.floor(vh.Health) or "?") or "sin resultado"
		end
		if cmd == "lastresult" then
			local r = G.Slap.lastResult
			return r and string.format("fuerza=%d%% supremo=%s esquivado=%s", math.floor(r.power * 100), tostring(r.supreme), tostring(r.dodged)) or "nada"
		end
		if cmd == "slapstats" then
			local t = G.Slap.stats or { hits = 0, dodges = 0 }
			return t.hits, t.dodges
		end
		if cmd == "slapnow" then -- me toca pegar ya (si estoy de pie en una mesa esperando)
			local ok = G.Slap.request(player)
			return ok
		end
		if cmd == "finishnow" then
			return G.Race.finish(player)
		end
		if cmd == "join" then
			return G.Race.setJoined(player, true), G.Race.state
		end
		if cmd == "itemtest2" then -- comprueba si el objeto afecta a CUALQUIER bot (golpe, congelación o lentitud)
			local B = require(script.Bots)
			local target
			for _, b in ipairs(B.list) do
				local h = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
				local s2 = G.Race.sessions[b]
				if h and s2 and not s2.finished and (not target or h.Position.Z > target.h.Position.Z) then
					target = { b = b, h = h, s = s2 }
				end
			end
			if not target then
				return "sin bot en carrera"
			end
			local before = {}
			for _, b in ipairs(B.list) do
				local s2 = G.Race.sessions[b]
				if s2 then
					before[b] = { hit = s2.lastHitAt or 0, fr = s2.frozenUntil or 0, sp = s2.speedUntil or 0 }
				end
			end
			local hrp = player.Character.HumanoidRootPart
			local tp = target.h.Position
			local aim = tp
			local trap = arg == "glue" or arg == "banana"
			if trap then
				-- delante del bot, mirando hacia delante: la trampa cae detrás de mí, en su camino
				local at = tp + Vector3.new(0, 0, 7)
				hrp.CFrame = CFrame.lookAt(at, at + Vector3.new(0, 0, 1))
			else
				local at = tp - Vector3.new(0, 0, 6)
				hrp.CFrame = CFrame.lookAt(at, tp)
				aim = tp + target.h.AssemblyLinearVelocity * 0.05
			end
			task.wait(0.2)
			local s = G.Race.sessions[player]
			s.item, s.rolling = arg, false
			local ok, res = pcall(G.Items.use, player, aim)
			if trap then
				hrp.CFrame = hrp.CFrame + Vector3.new(0, 0, 14) -- me aparto para que el bot pase
			end
			local affected, seen = {}, {}
			local t0 = os.clock()
			while os.clock() - t0 < (trap and 8 or 2.5) do
				for _, b in ipairs(B.list) do
					local s2 = G.Race.sessions[b]
					local o = before[b]
					if s2 and o then
						local function mark(tag)
							if not seen[b.Name .. tag] then
								seen[b.Name .. tag] = true
								table.insert(affected, b.Name .. ":" .. tag)
							end
						end
						if (s2.lastHitAt or 0) > o.hit then mark("golpe") end
						if (s2.frozenUntil or 0) > o.fr then mark("congelado") end
						if (s2.speedUntil or 0) > o.sp then mark("lento") end
					end
				end
				task.wait(0.1)
			end
			return string.format("%s used=%s -> %s", arg, tostring(ok and res), #affected > 0 and table.concat(affected, ",") or "NADA")
		end
		if cmd == "itemtest" then -- se pone detrás del bot más adelantado, usa el objeto y mira si le dio
			local B = require(script.Bots)
			local target
			for _, b in ipairs(B.list) do
				local h = b.Character and b.Character:FindFirstChild("HumanoidRootPart")
				local s2 = G.Race.sessions[b]
				if h and s2 and not s2.finished and (not target or h.Position.Z > target.h.Position.Z) then
					target = { b = b, h = h, s = s2 }
				end
			end
			if not target then
				return "sin bot en carrera"
			end
			local hrp = player.Character.HumanoidRootPart
			local from = target.h.Position - Vector3.new(0, 0, 5)
			hrp.CFrame = CFrame.lookAt(from, target.h.Position)
			task.wait(0.3)
			local s = G.Race.sessions[player]
			s.item, s.rolling = arg, false
			local before = target.s.lastHitAt or 0
			local frozenBefore = target.s.frozenUntil
			local ok, res = pcall(G.Items.use, player, target.h.Position)
			task.wait(2.5)
			local hit = (target.s.lastHitAt or 0) > before
			local frozen = target.s.frozenUntil ~= frozenBefore
			return string.format("%s racing=%s ok=%s used=%s hitBot=%s frozenBot=%s", arg, tostring(s.racing), tostring(ok), tostring(res), tostring(hit), tostring(frozen))
		end
		if cmd == "supreme" then
			G.Slap.debugSupreme = true
			return "ok"
		end
		if cmd == "slapstate" then
			return G.Slap.debugState(arg)
		end
		if cmd == "coins" then
			G.Data.addCoins(player, arg)
			return G.Data.coins(player)
		end
		if cmd == "use" then
			local s = G.Race.sessions[player]
			if not s then
				return "sin sesión"
			end
			s.item, s.rolling = arg, false
			local hrp = player.Character and player.Character:FindFirstChild("HumanoidRootPart")
			local ok, res = pcall(G.Items.use, player, hrp and hrp.Position + hrp.CFrame.LookVector * 30)
			return tostring(ok) .. " " .. tostring(res) .. " racing=" .. tostring(s.racing)
		end
	end
	bf.Parent = game:GetService("ServerStorage")
end
