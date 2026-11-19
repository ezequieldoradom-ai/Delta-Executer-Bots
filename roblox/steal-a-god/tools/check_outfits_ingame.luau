-- Crea con Avatars.make (como el juego) a todos los personajes que tienen ropa del catálogo
-- y comprueba prendas cargadas, que estén colocadas y la altura real.
local RS = game:GetService("ReplicatedStorage")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local Shared = RS:WaitForChild("Shared")
local G = { Config = require(Shared.Config), GodModel = require(Shared.GodModel) }
G.Avatars = require(Server.Avatars)
G.Avatars.init(G)
local out, bad = {}, 0
local ids = {}
for id in pairs(G.Avatars.OUTFITS) do table.insert(ids, id) end
table.sort(ids)
for _, id in ipairs(ids) do
	local god = G.Config.GOD_BY_ID[id]
	local entry = god or { id = id, myth = id:find("^g_") and ({ g_minotaur = "greek", g_dullahan = "celtic", g_sphinx = "egyptian", g_jaguar = "aztec", g_lamassu = "babylonian", g_fenrir = "norse" })[id] or "greek", r = 0, name = id }
	local ok, err = pcall(function()
		local rig = G.Avatars.make(entry)
		assert(rig, "sin avatar")
		local acc, far = 0, 0
		local hrp = rig:FindFirstChild("HumanoidRootPart")
		for _, a in ipairs(rig:GetChildren()) do
			if a:IsA("Accessory") then
				acc += 1
				local h = a:FindFirstChild("Handle")
				if h and (h.Position - hrp.Position).Magnitude > 12 then far += 1 end
			end
		end
		local size = rig:GetExtentsSize()
		local ok2 = rig:GetAttribute("Outfit") == true and far == 0 and size.Y < 14
		if not ok2 then bad += 1 end
		table.insert(out, string.format("%s %s: prendas %d · lejos %d · tamaño %.1f×%.1f×%.1f", ok2 and "✅" or "⚠️", id, acc, far, size.X, size.Y, size.Z))
	end)
	if not ok then
		bad += 1
		table.insert(out, "❌ " .. id .. ": " .. tostring(err))
	end
end
table.insert(out, bad == 0 and "🎉 ROPA OK" or (bad .. " con problemas"))
return table.concat(out, "\n")
