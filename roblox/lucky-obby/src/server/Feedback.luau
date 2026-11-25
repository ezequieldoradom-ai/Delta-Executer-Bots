-- Lucky Obby Race — BUZÓN de sugerencias y fallos (Shadow, petición del dueño)
-- Cualquier jugador manda una idea 💡 o un fallo 🐞 (máx. 300 letras, 1 cada 2 min). Se filtra con el filtro de
-- texto de Roblox y se guarda en el DataStore "LuckyObby_Feedback_v1" (clave "inbox", los 300 últimos).
-- Solo el dueño del juego (creador, rango 255 del grupo, o en Studio) puede leerlos con el botón 📬.
-- También se pueden leer desde fuera con una tarea de Luau (Open Cloud luau-execution) leyendo esa clave.
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TextService = game:GetService("TextService")

local Feedback = {}
local STORE_NAME, KEY, KEEP = "LuckyObby_Feedback_v1", "inbox", 300
local COOLDOWN, MAX_LEN = 120, 300

local store
local last = {} -- [player] = os.clock() del último envío
local memory = {} -- si no hay DataStore (Studio sin acceso), se quedan en memoria del servidor

local function isOwner(p)
	if RunService:IsStudio() then
		return true
	end
	if game.CreatorType == Enum.CreatorType.User then
		return p.UserId == game.CreatorId
	end
	local ok, rank = pcall(function()
		return p:GetRankInGroup(game.CreatorId)
	end)
	return ok and rank >= 255
end

local function filter(text, p)
	local ok, res = pcall(function()
		local r = TextService:FilterStringAsync(text, p.UserId, Enum.TextFilterContext.PublicChat)
		return r:GetNonChatStringForBroadcastAsync()
	end)
	if ok then
		return res
	end
	if RunService:IsStudio() then
		return text -- en Studio el filtro puede no estar disponible
	end
	return nil
end

local function add(entry)
	table.insert(memory, 1, entry)
	if #memory > KEEP then
		table.remove(memory)
	end
	if not store then
		return true
	end
	local ok = pcall(function()
		store:UpdateAsync(KEY, function(old)
			old = type(old) == "table" and old or {}
			table.insert(old, 1, entry)
			while #old > KEEP do
				table.remove(old)
			end
			return old
		end)
	end)
	return ok
end

local function list()
	if store then
		local ok, data = pcall(function()
			return store:GetAsync(KEY)
		end)
		if ok and type(data) == "table" then
			return data
		end
	end
	return memory
end

function Feedback.init(G)
	if not RunService:IsStudio() then
		pcall(function()
			store = DataStoreService:GetDataStore(STORE_NAME)
		end)
	end
	local rf = Instance.new("RemoteFunction")
	rf.Name = "Feedback"
	rf.Parent = game:GetService("ReplicatedStorage"):WaitForChild("Remotes")
	local function handle(p, action, a, b)
		if action == "isOwner" then
			return isOwner(p)
		elseif action == "send" then
			local kind = a == "bug" and "bug" or "idea"
			if type(b) ~= "string" then
				return false, "?"
			end
			local text = b:gsub("^%s+", ""):gsub("%s+$", "")
			if #text < 3 then
				return false, "short"
			end
			text = text:sub(1, MAX_LEN)
			if last[p] and os.clock() - last[p] < COOLDOWN then
				return false, "wait", math.ceil(COOLDOWN - (os.clock() - last[p]))
			end
			last[p] = os.clock()
			local clean = filter(text, p)
			if not clean then
				return false, "filter"
			end
			local ok = add({ t = os.time(), id = p.UserId, name = p.Name, kind = kind, text = clean, place = game.PlaceVersion })
			return ok, ok and "ok" or "store"
		elseif action == "list" then
			if not isOwner(p) then
				return nil
			end
			return list()
		end
		return nil
	end
	Feedback.handle = handle -- (también para pruebas)
	rf.OnServerInvoke = handle
	Players.PlayerRemoving:Connect(function(p)
		last[p] = nil
	end)
	local _ = G
end

return Feedback
