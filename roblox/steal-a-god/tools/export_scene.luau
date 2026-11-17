-- Construye el juego y exporta todas las piezas para dibujarlas en 3D fuera de Roblox
local RS = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared = RS:WaitForChild("Shared")
local G = {
	Config = require(Shared.Config), Format = require(Shared.Format), GodModel = require(Shared.GodModel),
	Net = require(Server.Net), Data = require(Server.Data), World = require(Server.World), Core = require(Server.Core),
	Packs = require(Server.Packs), Combat = require(Server.Combat), DayNight = require(Server.DayNight),
	Boards = require(Server.Boards), Shop = require(Server.Shop), serverLuckUntil = 0,
}
G.Net.init()
require(Server.Models).load(G.Config)
G.Avatars = require(Server.Avatars)
G.Avatars.init(G)
G.World.init(G)
G.DayNight.init(G); G.Combat.init(G); G.Packs.init(G); G.Shop.init(G); G.Boards.init(G); G.Core.init(G)
G.Packs.refreshAll()
-- parcela de ejemplo con dioses de todas las rarezas y kilos variados
local plot = G.World.plots[2]
G.World.styleplot(plot, 12)
local picks = { "zeus", "thor", "anubis", "poseidon", "ra", "odin", "bastet", "hermes", "atenea", "ymir", "nyx", "cronos", "isis", "quetzalcoatl", "atlas", "unknown" }
for i, id in ipairs(picks) do
	G.World.setStatue(plot, i, { god = G.Config.GOD_BY_ID[id], kg = ({ 80, 120, 300, 650, 100, 150 })[(i % 6) + 1] })
end
for i = 1, 6 do
	local d = { altarPacks = {} }
end
local SHAPES = { [Enum.PartType.Ball] = "ball", [Enum.PartType.Cylinder] = "cyl", [Enum.PartType.Block] = "box", [Enum.PartType.Wedge] = "wedge" }
local rows = {}
local function r2(x) return math.floor(x * 100 + 0.5) / 100 end
for _, p in ipairs(workspace:GetDescendants()) do
	if p:IsA("BasePart") and p.Transparency < 0.98 and p.Name ~= "Terrain" then
		local c = p.CFrame
		local rx, ry, rz = c:ToEulerAnglesXYZ()
		local shape = p:IsA("WedgePart") and "wedge" or (p:IsA("Part") and (SHAPES[p.Shape] or "box") or "box")
		local mesh = p:FindFirstChildOfClass("SpecialMesh")
		if mesh and mesh.MeshType == Enum.MeshType.Head then shape = "head" end
		table.insert(rows, table.concat({
			shape, r2(c.X), r2(c.Y), r2(c.Z), r2(rx), r2(ry), r2(rz), r2(p.Size.X), r2(p.Size.Y), r2(p.Size.Z),
			string.format("%02x%02x%02x", math.floor(p.Color.R * 255), math.floor(p.Color.G * 255), math.floor(p.Color.B * 255)),
			r2(p.Transparency), p.Material == Enum.Material.Neon and 1 or 0,
		}, ","))
	end
end
return table.concat(rows, ";")
