-- Sonda: medidas del avatar de cada vendedor (escala 1) para colocar bien las piezas
local RS = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared = RS:WaitForChild("Shared")
local G = { Config = require(Shared.Config), GodModel = require(Shared.GodModel) }
G.Avatars = require(Server.Avatars)
G.Avatars.init(G)
local out = {}
local function r2(x) return math.floor(x * 100 + 0.5) / 100 end
for _, id in ipairs({ "v_hecate", "v_quiron" }) do
	local t = G.Avatars.make({ id = id, myth = "greek", r = 0, name = id })
	if not t then
		table.insert(out, id .. ": SIN AVATAR")
		continue
	end
	local m = t:Clone()
	m.Parent = workspace
	local ph = m:GetAttribute("PivotH")
	local cf, size = m:GetBoundingBox()
	table.insert(out, string.format("%s PivotH=%.2f bbox size=(%.2f,%.2f,%.2f) centre y=%.2f z=%.2f", id, ph, size.X, size.Y, size.Z, cf.Y, cf.Z))
	for _, p in ipairs(m:GetDescendants()) do
		if p:IsA("BasePart") then
			local rx, ry, rz = p.CFrame:ToEulerAnglesXYZ()
			table.insert(out, string.format("  %-16s %-9s size=(%.2f,%.2f,%.2f) pos=(%.2f,%.2f,%.2f) rot=(%d,%d,%d)", p.Name, p.ClassName, p.Size.X, p.Size.Y, p.Size.Z, r2(p.Position.X), r2(p.Position.Y), r2(p.Position.Z), math.deg(rx), math.deg(ry), math.deg(rz)))
		end
	end
	m:Destroy()
end
return table.concat(out, "\n")
