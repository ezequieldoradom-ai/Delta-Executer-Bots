-- Steal a God ⚡ Roba un Dios — servidor
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")

local G = {
	Config = require(Shared.Config),
	Format = require(Shared.Format),
	GodModel = require(Shared.GodModel),
	Net = require(script.Net),
	Data = require(script.Data),
	World = require(script.World),
	Core = require(script.Core),
	Packs = require(script.Packs),
	Combat = require(script.Combat),
	DayNight = require(script.DayNight),
	Boards = require(script.Boards),
	Shop = require(script.Shop),
	serverLuckUntil = 0,
}

-- Módulos que pueden faltar en una copia de trabajo (se cargan solo si existen)
local function optional(name)
	local m = script:FindFirstChild(name)
	return m and require(m) or nil
end
G.AuraFx = optional("AuraFx") -- efectos de las auras de los jugadores
G.PackStyle = optional("PackStyle") -- diseño de los sobres por rareza y nidos
G.Vendors = optional("Vendors") -- dioses que venden auras y entrenadores

G.Net.init()
require(script.Models).load(G.Config)
G.Avatars = require(script.Avatars)
G.Avatars.init(G)
if G.AuraFx and G.AuraFx.init then
	G.AuraFx.init(G)
end
if G.PackStyle and G.PackStyle.init then
	G.PackStyle.init(G)
end
G.World.init(G)
if G.Vendors then
	G.Vendors.init(G)
end
G.DayNight.init(G)
G.Combat.init(G)
G.Packs.init(G)
G.Shop.init(G)
G.Boards.init(G)
G.Core.init(G)

-- Solo en Roblox Studio: enganche para revisar el juego desde la barra de comandos
-- (la barra carga sus propias copias de los módulos y no ve las partidas). Ejemplos:
--   ServerStorage.StudioDebug:Invoke("Core.addGod", jugador, Config.GOD_BY_ID.zeus, 300)
--   ServerStorage.StudioDebug:Invoke("profile", jugador, { money = 1e12, plot = 12 })
if game:GetService("RunService"):IsStudio() then
	local debug = Instance.new("BindableFunction")
	debug.Name = "StudioDebug"
	debug.OnInvoke = function(cmd, a, b, c, d)
		if cmd == "profile" then
			local prof = G.Data.profiles[a]
			for k, v in pairs(b or {}) do
				prof[k] = v
			end
			G.Core.invalidate(a)
			return true
		end
		local mod, fn = string.match(cmd, "^(%w+)%.(%w+)$")
		return G[mod][fn](a, b, c, d)
	end
	debug.Parent = game:GetService("ServerStorage")
end

G.DayNight.start()
G.Packs.start()
G.Core.start()
G.Boards.start()

print("⚡ Steal a God listo")
