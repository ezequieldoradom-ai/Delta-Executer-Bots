-- Panel de administrador ("admin abuse") — petición del dueño.
-- Solo el creador del juego (o el dueño del grupo, o los ids de Admin.EXTRA) puede usarlo.
-- Cada orden puede ir a ESTE servidor o a TODOS (MessagingService, tema "SAG_Admin").
-- Órdenes: mensaje global, suerte x3, noche, lluvia de dinero, velocidad x2 y lluvia de sobres de una rareza.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MessagingService = game:GetService("MessagingService")
local TextService = game:GetService("TextService")
local RunService = game:GetService("RunService")

local Admin = {}
local G, C

Admin.EXTRA = {} -- ids de otros administradores, p. ej. { 12345678 }
Admin.TOPIC = "SAG_Admin"
Admin.COOLDOWN = 3 -- segundos entre órdenes de un mismo admin

local lastCmd = {}

function Admin.isAdmin(player)
	if player.UserId == game.CreatorId and game.CreatorType == Enum.CreatorType.User then
		return true
	end
	if table.find(Admin.EXTRA, player.UserId) then
		return true
	end
	if game.CreatorType == Enum.CreatorType.Group then
		local ok, rank = pcall(function()
			return player:GetRankInGroup(game.CreatorId)
		end)
		return ok and rank >= 255
	end
	return RunService:IsStudio() -- en Studio (pruebas) todos son admin
end

local function everyone(fn)
	for p in pairs(G.Core.sessions) do
		pcall(fn, p)
		G.Core.invalidate(p)
	end
end

-- Ejecuta una orden en este servidor (ya validada). by = nombre del admin
local RUN = {}
RUN.msg = function(by, args)
	G.Net.announce("all", "adminMsg", { by, tostring(args.text or "") }, { color = "#FFD23F", big = true })
end
RUN.luck = function(by, args)
	local mins = math.clamp(tonumber(args.mins) or 10, 1, 60)
	G.serverLuckUntil = math.max(os.clock(), G.serverLuckUntil or 0) + mins * 60
	everyone(function() end)
	G.Net.announce("all", "adminLuck", { by, mins }, { color = "#3DDC84", big = true })
end
RUN.night = function(by)
	G.DayNight.forceNight(by)
end
RUN.money = function(by, args)
	local secs = math.clamp(tonumber(args.secs) or 600, 60, 3600)
	everyone(function(p)
		G.Core.addMoney(p, math.max(5000, math.floor(G.Core.income(p) * secs)))
	end)
	G.Net.announce("all", "adminMoney", { by }, { color = "#6CFF7A", big = true })
end
RUN.speed = function(by, args)
	local mins = math.clamp(tonumber(args.mins) or 10, 1, 60)
	everyone(function(p)
		local d = G.Data.profiles[p]
		if d then
			d.boosts.speed = math.max(os.time(), d.boosts.speed or 0) + mins * 60
		end
	end)
	G.Net.announce("all", "adminSpeed", { by, mins }, { color = "#5EE7FF", big = true })
end
RUN.packs = function(by, args)
	local r = math.clamp(math.floor(tonumber(args.rarity) or 6), 1, #C.RARITIES)
	for z = 1, #C.ZONES do
		local zp = G.World.zoneParts[z]
		local n = zp and zp.spots and #zp.spots or 6
		for spot = 1, n do
			pcall(G.Packs.debugSpawn, z, spot, r, math.random(150, 400))
		end
	end
	G.Net.announce("all", "adminPacks", { by, { rarity = r } }, { color = G.Format.hex(C.RARITIES[r].color), big = true })
end

local function runLocal(cmd, by, args)
	local fn = RUN[cmd]
	if fn then
		local ok, err = pcall(fn, by, args or {})
		if not ok then
			warn("[SAG] Admin " .. cmd .. ": " .. tostring(err))
		end
	end
end

local function onCommand(player, cmd, args, global)
	if not Admin.isAdmin(player) or type(cmd) ~= "string" or not RUN[cmd] then
		return
	end
	local now = os.clock()
	if now - (lastCmd[player] or 0) < Admin.COOLDOWN then
		return
	end
	lastCmd[player] = now
	args = type(args) == "table" and args or {}
	-- el texto que verán todos pasa por el filtro de Roblox (obligatorio para mensajes públicos)
	if cmd == "msg" then
		local text = tostring(args.text or ""):sub(1, 140)
		local ok, filtered = pcall(function()
			return TextService:FilterStringAsync(text, player.UserId):GetNonChatStringForBroadcastAsync()
		end)
		if not ok or filtered == "" then
			return
		end
		args = { text = filtered }
	end
	local by = player.DisplayName
	runLocal(cmd, by, args)
	if global == true then
		pcall(function()
			MessagingService:PublishAsync(Admin.TOPIC, { cmd = cmd, args = args, by = by, jobId = game.JobId })
		end)
	end
end

function Admin.init(g)
	G = g
	C = g.Config
	G.Admin = Admin
	local remotes = ReplicatedStorage:WaitForChild("Remotes")
	local ev = Instance.new("RemoteEvent")
	ev.Name = "Admin"
	ev.Parent = remotes
	ev.OnServerEvent:Connect(onCommand)
	-- el cliente solo enseña el panel a quien tenga este atributo (el servidor vuelve a comprobarlo en cada orden)
	local function mark(p)
		p:SetAttribute("SAGAdmin", Admin.isAdmin(p))
	end
	Players.PlayerAdded:Connect(mark)
	for _, p in ipairs(Players:GetPlayers()) do
		mark(p)
	end
	Players.PlayerRemoving:Connect(function(p)
		lastCmd[p] = nil
	end)
	-- órdenes de otros servidores
	task.spawn(function()
		pcall(function()
			MessagingService:SubscribeAsync(Admin.TOPIC, function(msg)
				local d = msg.Data
				if type(d) == "table" and d.jobId ~= game.JobId and type(d.cmd) == "string" then
					runLocal(d.cmd, tostring(d.by or "Admin"), d.args)
				end
			end)
		end)
	end)
end

return Admin
