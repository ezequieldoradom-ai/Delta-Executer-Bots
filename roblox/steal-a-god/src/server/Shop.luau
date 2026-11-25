-- Robux: pases (para siempre) y compras sueltas.
-- Las compras son "idempotentes": cada recibo (PurchaseId) se entrega UNA sola vez y solo se
-- confirma a Roblox cuando el premio ha quedado guardado en la partida.
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
	-- El creador tiene todos los pases gratis: por defecto se desactivan para probar como un jugador normal
	local d = G.Data.profiles[player]
	local isOwner = player.UserId == game.CreatorId
	s.isOwner = isOwner
	if isOwner and not (d and d.settings and d.settings.ownerPasses) then
		s.passes = {}
		G.Core.invalidate(player)
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
	G.Core.invalidate(player)
end

-- Categorías de "Abrir ya"
Shop.OPEN_TIERS = {
	openNowLow = { tier = "low", min = 1, max = 4 },
	openNowMid = { tier = "mid", min = 5, max = 8 },
	openNowHigh = { tier = "high", min = 9, max = 14 },
}

-- Cada función entrega el premio y devuelve true. Nunca debe devolver true sin entregar algo.
local handlers = {}

handlers.savePack = function(player)
	return G.Packs.savePurchased(player)
end
handlers.speedBoost = function(player)
	local d = G.Data.profiles[player]
	d.boosts.speed = math.max(os.time(), d.boosts.speed or 0) + 15 * 60
	G.Core.invalidate(player)
	return true
end
handlers.serverNight = function(player)
	G.DayNight.forceNight(player.DisplayName)
	return true
end
handlers.serverLuck = function(player)
	G.serverLuckUntil = math.max(os.clock(), G.serverLuckUntil or 0) + 10 * 60
	for p in pairs(G.Core.sessions) do
		G.Core.invalidate(p)
	end
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
for key, info in pairs(Shop.OPEN_TIERS) do
	handlers[key] = function(player)
		-- si hay un sobre de esa categoría se abre ya; si no, queda guardado para el próximo
		if not G.Packs.openNow(player, info.min, info.max) then
			local d = G.Data.profiles[player]
			d.openTokens[info.tier] = (d.openTokens[info.tier] or 0) + 1
			G.Net.toast(player, "openSaved")
		end
		return true
	end
end
handlers.instantUpgrade = function(player)
	local d = G.Data.profiles[player]
	if d.plot < C.PLOT_MAX then
		d.plot += 1
		G.Core.refreshPlot(player)
	else
		-- parcela al máximo: se compensa con 2 h de ingresos
		G.Core.addMoney(player, math.max(25000, G.Core.income(player) * 7200))
		G.Net.toast(player, "plotMaxRefund")
	end
	return true
end
handlers.divineShield = function(player)
	local d = G.Data.profiles[player]
	d.boosts.shield = math.max(os.time(), d.boosts.shield or 0) + 180
	return true
end
Shop.handlers = handlers

local productById = {}

-- Procesa un recibo. playerOverride sirve para las pruebas automáticas.
function Shop.processReceipt(info, playerOverride)
	local player = playerOverride or Players:GetPlayerByUserId(info.PlayerId)
	local key = productById[info.ProductId]
	if not player or not key or not G.Data.profiles[player] or not G.Core.sessions[player] then
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	local d = G.Data.profiles[player]
	local purchaseId = tostring(info.PurchaseId)
	-- 1) ya entregado antes: solo falta confirmarlo (se intenta guardar de nuevo)
	if G.Data.hasReceipt(d, purchaseId) then
		if playerOverride or G.Data.save(player) then
			return Enum.ProductPurchaseDecision.PurchaseGranted
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	-- 2) entregar el premio y apuntar el recibo a la vez
	local ok, granted = pcall(handlers[key], player)
	if not ok or not granted then
		if not ok then
			warn("Error al entregar compra", key, granted)
		end
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	G.Data.addReceipt(d, purchaseId)
	-- 3) solo se confirma a Roblox cuando está guardado
	if playerOverride or G.Data.save(player) then
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	return Enum.ProductPurchaseDecision.NotProcessedYet
end

function Shop.init(g)
	G = g
	C = g.Config
	for key, prod in pairs(C.PRODUCTS) do
		if prod.id ~= 0 then
			productById[prod.id] = key
		end
	end
	Shop.productById = productById
	MarketplaceService.ProcessReceipt = function(info)
		return Shop.processReceipt(info)
	end
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(function(player, passId, purchased)
		if purchased then
			Shop.checkPasses(player)
			G.Core.refreshPlot(player)
		end
	end)
end

return Shop
