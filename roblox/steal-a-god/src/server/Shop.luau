-- Robux: pases (para siempre) y compras sueltas
local MarketplaceService = game:GetService("MarketplaceService")
local Players = game:GetService("Players")

local Shop = {}
local G
local C

function Shop.checkPasses(player)
	local s = G.Core.sessions[player]
	if not s then
		return
	end
	for key, pass in pairs(C.PASSES) do
		if pass.id ~= 0 then
			local ok, owns = pcall(function()
				return MarketplaceService:UserOwnsGamePassAsync(player.UserId, pass.id)
			end)
			s.passes[key] = ok and owns or false
		end
	end
end

local handlers = {}

handlers.savePack = function(player)
	return G.Packs.savePurchased(player)
end
handlers.speedBoost = function(player)
	local s = G.Core.sessions[player]
	s.speedBoostUntil = math.max(os.clock(), s.speedBoostUntil) + 15 * 60
	return true
end
handlers.serverNight = function(player)
	G.DayNight.forceNight(player.DisplayName)
	return true
end
handlers.serverLuck = function(player)
	G.serverLuckUntil = math.max(os.clock(), G.serverLuckUntil or 0) + 10 * 60
	G.Net.announce("all", "serverLuck", { player.DisplayName }, { color = "#3DDC84", big = true })
	return true
end
handlers.moneySmall = function(player)
	G.Core.addMoney(player, math.max(1000, G.Core.income(player) * 600))
	return true
end
handlers.moneyBig = function(player)
	G.Core.addMoney(player, math.max(25000, G.Core.income(player) * 7200))
	return true
end
handlers.openNowLow = function(player)
	return G.Packs.openNow(player, 1, 4)
end
handlers.openNowMid = function(player)
	return G.Packs.openNow(player, 5, 8)
end
handlers.openNowHigh = function(player)
	return G.Packs.openNow(player, 9, 14)
end
handlers.instantUpgrade = function(player)
	local d = G.Data.profiles[player]
	if d.plot < C.PLOT_MAX then
		d.plot += 1
		G.Core.refreshPlot(player)
	end
	return true
end
handlers.divineShield = function(player)
	local s = G.Core.sessions[player]
	s.shieldUntil = math.max(os.clock(), s.shieldUntil) + 180
	return true
end

local productById = {}

function Shop.init(g)
	G = g
	C = g.Config
	for key, prod in pairs(C.PRODUCTS) do
		if prod.id ~= 0 then
			productById[prod.id] = key
		end
	end
	MarketplaceService.ProcessReceipt = function(info)
		local player = Players:GetPlayerByUserId(info.PlayerId)
		local key = productById[info.ProductId]
		if not player or not key or not G.Data.profiles[player] or not G.Core.sessions[player] then
			return Enum.ProductPurchaseDecision.NotProcessedYet
		end
		local ok, granted = pcall(handlers[key], player)
		if ok and granted then
			G.Data.save(player)
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			Shop.checkPasses(player)
			G.Core.refreshPlot(player)
		end
	end)
end

return Shop
