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

G.Net.init()
require(script.Models).load(G.Config)
G.World.init(G)
G.DayNight.init(G)
G.Combat.init(G)
G.Packs.init(G)
G.Shop.init(G)
G.Boards.init(G)
G.Core.init(G)

G.DayNight.start()
G.Packs.start()
G.Core.start()
G.Boards.start()

print("⚡ Steal a God listo")
