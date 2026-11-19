-- Arranca el mundo y ejecuta el módulo Fx del cliente con Heartbeat para comprobar que no da errores
local RS = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared = RS:WaitForChild("Shared")
local G = {
	Config = require(Shared.Config), Format = require(Shared.Format), GodModel = require(Shared.GodModel),
	Net = require(Server.Net), Data = require(Server.Data), World = require(Server.World), Core = require(Server.Core),
	Packs = require(Server.Packs), Combat = require(Server.Combat), DayNight = require(Server.DayNight),
	Boards = require(Server.Boards), Shop = require(Server.Shop), serverLuckUntil = 0,
}
local function optional(name)
	local m = Server:FindFirstChild(name)
	return m and require(m) or nil
end
G.AuraFx = optional("AuraFx"); G.PackStyle = optional("PackStyle"); G.Vendors = optional("Vendors")
G.Net.init()
require(Server.Models).load(G.Config)
G.Avatars = require(Server.Avatars); G.Avatars.init(G)
if G.AuraFx then G.AuraFx.init(G) end
if G.PackStyle then G.PackStyle.init(G) end
G.World.init(G)
if G.Vendors then G.Vendors.init(G) end
G.DayNight.init(G); G.Combat.init(G); G.Packs.init(G); G.Shop.init(G); G.Boards.init(G); G.Core.init(G)
G.Packs.refreshAll()
for r = 1, 14 do
	G.Packs.debugSpawn(1, (r % 6) + 1, r, 100 + r * 10, r == 7, Vector3.new(-45 + r * 6, 0, -30))
end
local warns = {}
game:GetService("LogService").MessageOut:Connect(function(msg, kind)
	if kind == Enum.MessageType.MessageWarning or kind == Enum.MessageType.MessageError then
		table.insert(warns, msg)
	end
end)
local client = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Client")
local Fx = require(client.Fx)
local Music = require(client.Music)
local CS = game:GetService("CollectionService")
-- posiciones de algunas piezas animadas antes de arrancar
local watch = {}
for _, tag in ipairs({ "FxOrbit", "FxSpin", "FxBob" }) do
	local list = CS:GetTagged(tag)
	for i = 1, math.min(6, #list) do
		table.insert(watch, { part = list[i], cf = list[i].CFrame, tag = tag })
	end
end
Fx.start({ Config = G.Config, Locale = require(Shared.Locale), t = require(Shared.Locale).t, opt = function() return true end, getState = function() return {} end })
Music.start({ Config = G.Config, opt = function() return true end, getState = function() return { carrying = 5, chase = 20 } end })
task.wait(2)
local moved = 0
for _, w in ipairs(watch) do
	if w.part.Parent and (w.part.CFrame.Position - w.cf.Position).Magnitude + math.abs(w.part.CFrame.LookVector:Dot(w.cf.LookVector) - 1) > 0.001 then
		moved += 1
	end
end
local st = Fx.stats()
local snd = game:GetService("SoundService"):FindFirstChild("ChaseMusic")
local info = game:GetService("MarketplaceService"):GetProductInfo(134426853581343)
Fx.stop()
Music.stop()
return string.format("Fx: motion=%d rainbow=%d glitch=%d loc=%d · movidas %d/%d · música: %s vol=%.2f · asset tipo %s · avisos: %s",
	st.motion, st.rainbow, st.glitch, st.loc, moved, #watch, snd and "creada" or "NO", snd and snd.Volume or -1, tostring(info.AssetTypeId), #warns == 0 and "ninguno" or table.concat(warns, " | "):sub(1, 600))
