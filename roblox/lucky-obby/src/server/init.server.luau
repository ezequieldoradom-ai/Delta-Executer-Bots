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
for _, name in ipairs({ "State", "Event", "Knock", "Use" }) do
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
G.Items.init(G)
G.Race.init(G)
G.Race.start()
print("🏁 Lucky Obby Race listo")
