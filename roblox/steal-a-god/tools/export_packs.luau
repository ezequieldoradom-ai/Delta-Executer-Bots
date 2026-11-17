-- Vista previa de los sobres y los nidos: construye el juego, coloca un escaparate con las 14 rarezas
-- y varios pesos, llena algunos nidos con rarezas altas y exporta todas las piezas para dibujarlas fuera de Roblox.
--   python3 tools/preview.py render --export tools/export_packs.luau --views tools/tmp_packs/views.json --out tools/tmp_packs/out
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

local Packs = G.Packs
-- Escaparate 1: rarezas 1–7 en la plaza (Z = -20), todas de 100 kg, mirando hacia +Z
for r = 1, 7 do
	Packs.debugSpawn(1, 1, r, 100, false, Vector3.new(-27 + (r - 1) * 9, 0.4, -20), Vector3.new(0, 0, 1))
end
-- Escaparate 2: rarezas 8–14 en la pista de la zona 1 (Z = 150), mirando hacia la entrada
for r = 8, 14 do
	Packs.debugSpawn(1, 1, r, 100, false, Vector3.new(-30 + (r - 8) * 10, 0.2, 150), Vector3.new(0, 0, -1))
end
-- Escaparate 3: la misma rareza con distintos pesos (zona 2, Z = 350)
for j, kg in ipairs({ 40, 100, 160, 300, 900 }) do
	Packs.debugSpawn(2, 1, 5, kg, false, Vector3.new(({ -26, -15, -3, 11, 29 })[j], 0.2, 350), Vector3.new(0, 0, -1))
end
-- Nidos de muestra: el de la zona 3 con rarezas altas y un gigante; el de la 6 con las más raras
for spot, v in ipairs({ { 7, 150 }, { 10, 300 }, { 12, 100 }, { 5, 900 }, { 13, 120 }, { 14, 160 } }) do
	Packs.debugSpawn(3, spot, v[1], v[2], spot == 3)
end
for spot, v in ipairs({ { 9, 110 }, { 11, 140 }, { 8, 90 }, { 6, 200 }, { 7, 60 }, { 4, 480 } }) do
	Packs.debugSpawn(6, spot, v[1], v[2], false)
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
