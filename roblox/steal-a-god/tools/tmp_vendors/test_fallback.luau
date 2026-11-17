-- Prueba de reserva: si no se pueden crear avatares, los vendedores usan la figura de piezas y el juego arranca igual
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
G.AuraFx = optional("AuraFx")
G.PackStyle = optional("PackStyle")
G.Vendors = optional("Vendors")
G.Net.init()
require(Server.Models).load(G.Config)
G.Avatars = require(Server.Avatars)
G.Avatars.init(G)
local real = G.Avatars.make
G.Avatars.make = function(god)
	if god.id == "v_hecate" then
		return nil -- como si Roblox no hubiera podido crear el avatar
	elseif god.id == "v_quiron" then
		error("fallo simulado al crear el avatar")
	end
	return real(god)
end
if G.AuraFx and G.AuraFx.init then G.AuraFx.init(G) end
if G.PackStyle and G.PackStyle.init then G.PackStyle.init(G) end
G.World.init(G)
G.Vendors.init(G)
local out = {}
table.insert(out, "errores: " .. #G.Vendors.errors .. " " .. table.concat(G.Vendors.errors, " | "))
for _, key in ipairs({ "aura", "coach" }) do
	local S = G.Vendors.shrines[key]
	local npc = S and S.npc
	assert(npc and npc.Parent == S.folder, key .. ": sin dios")
	assert(not npc:GetAttribute("Avatar"), key .. ": debería ser la figura de piezas")
	local cf, size = npc:GetBoundingBox()
	local anchored = true
	for _, p in ipairs(npc:GetDescendants()) do
		if p:IsA("BasePart") and not p.Anchored then
			anchored = false
		end
	end
	local look = (Vector3.new(0, npc:GetPivot().Position.Y, 68) - npc:GetPivot().Position).Unit
	table.insert(out, string.format("%s: %s · %d piezas · de %.1f a %.1f · ancho %.1f · anclado %s · mira a la plaza %.3f · aviso %s", key, npc.Name, #npc:GetChildren(), cf.Y - size.Y / 2, cf.Y + size.Y / 2, size.X, tostring(anchored), npc:GetPivot().LookVector:Dot(look), tostring(S.prompt and S.prompt.Parent ~= nil)))
	assert(anchored, key .. ": piezas sin anclar")
	assert(npc:GetPivot().LookVector:Dot(look) > 0.99, key .. ": no mira a la plaza")
end
assert(#G.Vendors.errors == 0, "hubo errores")
table.insert(out, "🎉 RESERVA OK")
return table.concat(out, "\n")
