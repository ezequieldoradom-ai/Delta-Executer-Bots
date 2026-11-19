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
