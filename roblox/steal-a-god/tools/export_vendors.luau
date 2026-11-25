-- Como export_scene.luau, pero añade un muñeco del tamaño de un jugador delante de cada vendedor
-- (solo en la vista previa, para comparar proporciones). No forma parte del juego.
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
if G.AuraFx and G.AuraFx.init then G.AuraFx.init(G) end
if G.PackStyle and G.PackStyle.init then G.PackStyle.init(G) end
G.World.init(G)
if G.Vendors then G.Vendors.init(G) end
G.DayNight.init(G); G.Combat.init(G); G.Packs.init(G); G.Shop.init(G); G.Boards.init(G); G.Core.init(G)
G.Packs.refreshAll()
-- parcela de ejemplo con dioses de todas las rarezas y kilos variados
local plot = G.World.plots[2]
G.World.styleplot(plot, 12)
local picks = { "zeus", "thor", "anubis", "poseidon", "ra", "odin", "bastet", "hermes", "atenea", "ymir", "nyx", "cronos", "isis", "quetzalcoatl", "atlas", "unknown" }
for i, id in ipairs(picks) do
	G.World.setStatue(plot, i, { god = G.Config.GOD_BY_ID[id], kg = ({ 80, 120, 300, 650, 100, 150 })[(i % 6) + 1] })
end
-- muñecos de referencia (tamaño de un jugador R15) delante de cada santuario
do
	local function box(size, cf, color)
		local p = Instance.new("Part")
		p.Anchored = true
		p.Size = size
		p.CFrame = cf
		p.Color = color
		p.Parent = workspace
	end
	for _, key in ipairs({ "aura", "coach" }) do
		local pos = G.Config.VENDORS[key].pos
		local cf = CFrame.lookAt(pos, Vector3.new(0, pos.Y, 68)) * CFrame.new(2.5, 0, -10.5) * CFrame.Angles(0, math.rad(180), 0)
		local shirt, skin, pants = Color3.fromRGB(230, 40, 40), Color3.fromRGB(245, 205, 150), Color3.fromRGB(30, 60, 160)
		box(Vector3.new(0.95, 2, 1), cf * CFrame.new(-0.5, 1, 0), pants)
		box(Vector3.new(0.95, 2, 1), cf * CFrame.new(0.5, 1, 0), pants)
		box(Vector3.new(2, 2, 1), cf * CFrame.new(0, 3, 0), shirt)
		box(Vector3.new(0.95, 2, 1), cf * CFrame.new(-1.5, 3, 0), skin)
		box(Vector3.new(0.95, 2, 1), cf * CFrame.new(1.5, 3, 0), skin)
		box(Vector3.new(1.2, 1.2, 1.2), cf * CFrame.new(0, 4.6, 0), skin)
	end
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
