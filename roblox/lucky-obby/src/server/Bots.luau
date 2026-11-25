-- Lucky Obby Race — BOTS para servidores con poca gente (Shadow, petición del dueño)
-- Son NPC con aspecto y comportamiento de persona (ropa y pelo variados, saludan, bailan, hablan en bocadillos)
-- para que el servidor se sienta vivo. No salen en la lista de jugadores ni cuentan en las clasificaciones.
--   · Corredores: en cada carrera salen detrás de la parrilla y recorren el obby saltando huecos y lava;
--     si caen o tocan algo que mata, vuelven a su punto de control. No usan objetos ni cuentan en el puesto.
--   · Sillas: juegan a "¿Quién ha sido?" (se sientan, pegan con la barra, a veces esquivan y adivinan al azar).
-- Cuántos: con 1 jugador 4 corredores + 4 en sillas; van desapareciendo según entra gente (con 5 o más, ninguno).
local CollectionService = game:GetService("CollectionService")
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

local Bots = {}
local G, C

local NAMES = {
	"Luna", "sofii_gamer", "xHugox", "Valeee", "Nico_pro", "MiaaXD", "dani2013", "zoe_lindaa", "AlexPlays", "noaaa",
	"teo_ytb", "Ari💜", "Iker_10", "lolaa", "MaxGG", "leoo", "Pablo_xd", "Carlaa", "martinaa_07", "Bruno",
	"Lucas_007", "emmaa", "Paula_owo", "Gael", "SaraBlox", "elchino_99", "Nerea", "Marcos_YT", "julia💖", "Thiago",
}
local CHAT = {
	hi = { "hola!", "holaa 👋", "hey", "q tal?", "hola :D", "holiii", "buenass" },
	start = { "suerte!", "vamooos", "a ganar 😎", "gl", "vamos vamos", "esta la gano yo" },
	fall = { "noooo", "casi 😭", "uff", "jajaja me caí", "otra vez no", "nooo la lava", "😭😭" },
	finish = { "gg", "llegué!!", "gg wp", "ez", "siii", "🏆" },
	slap = { "toma!", "jajaja", "😂", "pum", "eso dolió" },
	guess = { "fuiste tú 👀", "seguro que fue este", "mmm...", "a ver..." },
	push = { "fuera!", "jaja adios", "mi colina 😤", "sal de ahí" },
	idle = { "alguien carrera?", "q aburrido", "jajaja", "me encanta este juego", "vamos a la colina?", "quien juega guantazos?", "lol" },
}
local ANIM = {
	idle = "rbxassetid://507766388",
	run = "rbxassetid://913376220",
	jump = "rbxassetid://507765000",
	fall = "rbxassetid://507767968",
	sit = "rbxassetid://2506281703",
	-- gestos (los emotes de Roblox)
	wave = "rbxassetid://507770239",
	point = "rbxassetid://507770453",
	cheer = "rbxassetid://507770677",
	laugh = "rbxassetid://507770818",
	dance = "rbxassetid://507771019",
	dance2 = "rbxassetid://507776043",
	dance3 = "rbxassetid://507777268",
}
local EMOTES = { wave = true, point = true, cheer = true, laugh = true, dance = true, dance2 = true, dance3 = true }
local TARGET = { -- [jugadores reales] = { corredores, sillas, colina }
	[0] = { 0, 0, 0 },
	[1] = { 3, 4, 4 },
	[2] = { 3, 3, 4 },
	[3] = { 2, 2, 3 },
	[4] = { 1, 2, 2 },
}
local bots = {} -- lista de bots (tablas)
local nextId = 0

-- los bots no chocan con los jugadores (ni entre ellos): no estorban en las pasarelas estrechas
local function setupGroups()
	pcall(function()
		PhysicsService:RegisterCollisionGroup("LOBots")
		PhysicsService:RegisterCollisionGroup("LOPlayers")
		PhysicsService:CollisionGroupSetCollidable("LOBots", "LOPlayers", false)
		PhysicsService:CollisionGroupSetCollidable("LOBots", "LOBots", false)
	end)
	local function tagChar(char)
		for _, d in ipairs(char:GetDescendants()) do
			if d:IsA("BasePart") then
				d.CollisionGroup = "LOPlayers"
			end
		end
		char.DescendantAdded:Connect(function(d)
			if d:IsA("BasePart") then
				d.CollisionGroup = "LOPlayers"
			end
		end)
	end
	local function onPlayer(p)
		p.CharacterAdded:Connect(tagChar)
		if p.Character then
			tagChar(p.Character)
		end
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
end

local function realCount()
	return #Players:GetPlayers()
end

-- PERSONAJE ---------------------------------------------------------------------------
local function randomColor(rng)
	local skins = { Color3.fromRGB(255, 204, 153), Color3.fromRGB(234, 184, 146), Color3.fromRGB(204, 142, 105), Color3.fromRGB(124, 92, 70), Color3.fromRGB(86, 66, 54) }
	return skins[rng:NextInteger(1, #skins)]
end

-- SKINS "DE PRO": objetos míticos del catálogo de Roblox (Headless, Korblox, Valkyrie, Dominus, Fedoras…)
-- Si alguno no carga, se prueba sin accesorios y, si no, con colores.
local PRO = {
	heads = { 134082579, 0, 0 }, -- Headless Horseman (a veces)
	rightLegs = { 139607718, 0 }, -- Korblox
	hats = { "1365767", "21070012", "1285307", "1235488", "1365767,1235488", "21070012,1235488", "1285307,1235488" },
	faces = { 494290547, 2409281591, 0 },
}
local DARK = { Color3.fromRGB(20, 20, 24), Color3.fromRGB(35, 30, 45), Color3.fromRGB(240, 240, 245), Color3.fromRGB(150, 20, 30), Color3.fromRGB(20, 40, 90) }
-- ropa y pelo NORMALES del catálogo oficial de Roblox (gratis): así parecen gente cualquiera
local CASUAL = {
	hair = { 2956239660, 63690008, 451221329, 1103003368, 376526888, 376524487, 376548738, 376527350, 451220849, 3814474927, 3814476174, 62234425, 7193442167, 6993754725, 7193448258, 9174355709, 9243987340, 9244095135, 7193444640, 9243992729, 9244097555, 7193448988, 9244111257 },
	shirts = { 144076358, 607785314, 398633584, 144076436, 398634295, 3670737444, 382538059, 398635081, 382537702, 382537085, 382538295, 4047884939, 4047884046, 4047886060 },
	pants = { 144076760, 398634487, 398633812, 398635338, 382537806, 382538503, 382537569, 382537950 },
}

local function makeDesc(rng, withItems)
	local desc = Instance.new("HumanoidDescription")
	local skin = randomColor(rng)
	desc.HeadColor, desc.LeftArmColor, desc.RightArmColor = skin, skin, skin
	local shirt = DARK[rng:NextInteger(1, #DARK)]
	local pants = DARK[rng:NextInteger(1, #DARK)]
	desc.TorsoColor, desc.LeftLegColor, desc.RightLegColor = shirt, pants, pants
	if withItems then
		-- casi todos van "normales"; alguno de vez en cuando con algo caro (como en cualquier servidor)
		desc.HairAccessory = tostring(CASUAL.hair[rng:NextInteger(1, #CASUAL.hair)])
		desc.Shirt = CASUAL.shirts[rng:NextInteger(1, #CASUAL.shirts)]
		desc.Pants = CASUAL.pants[rng:NextInteger(1, #CASUAL.pants)]
		if rng:NextNumber() < 0.15 then
			desc.HatAccessory = PRO.hats[rng:NextInteger(1, #PRO.hats)]
			desc.HairAccessory = ""
		end
		if rng:NextNumber() < 0.08 then
			desc.RightLeg = PRO.rightLegs[1]
		end
		desc.Face = PRO.faces[rng:NextInteger(1, #PRO.faces)]
	end
	return desc
end

local function buildCharacter(bot)
	local rng = Random.new()
	local ok, model
	for _, withItems in ipairs({ true, false }) do
		local desc = makeDesc(rng, withItems)
		ok, model = pcall(function()
			return Players:CreateHumanoidModelFromDescription(desc, Enum.HumanoidRigType.R15)
		end)
		if ok and model then
			break
		end
	end
	if not ok or not model then
		return nil
	end
	model.Name = "Bot_" .. bot.Name
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.DisplayName = bot.DisplayName
	hum.NameDisplayDistance = 60
	hum.WalkSpeed = 16
	hum.JumpHeight = 7.2
	hum.BreakJointsOnDeath = false
	for _, d in ipairs(model:GetDescendants()) do
		if d:IsA("BasePart") then
			d.CollisionGroup = "LOBots"
		elseif d:IsA("Script") or d:IsA("LocalScript") then
			d:Destroy() -- (Animate no corre en NPC; se anima abajo)
		end
	end
	model:SetAttribute("IsBot", true)
	model:SetAttribute("BotId", bot.UserId)
	CollectionService:AddTag(model, "LuckyBot")
	-- animaciones (las reproduce el servidor: se ven en todos los clientes)
	local animator = hum:FindFirstChildOfClass("Animator") or Instance.new("Animator", hum)
	local tracks = {}
	for k, id in pairs(ANIM) do
		local a = Instance.new("Animation")
		a.AnimationId = id
		local okT, tr = pcall(function()
			return animator:LoadAnimation(a)
		end)
		if okT then
			tracks[k] = tr
			tr.Priority = (k == "idle") and Enum.AnimationPriority.Idle or (EMOTES[k] and Enum.AnimationPriority.Action or Enum.AnimationPriority.Movement)
		end
	end
	local current
	local function playT(k, fade)
		if current == k then
			return
		end
		if current and tracks[current] then
			tracks[current]:Stop(fade or 0.2)
		end
		current = k
		if tracks[k] then
			tracks[k]:Play(fade or 0.2)
		end
	end
	hum.Running:Connect(function(speed)
		if hum:GetState() == Enum.HumanoidStateType.Seated then
			return
		end
		playT(speed > 0.5 and "run" or "idle")
	end)
	hum.StateChanged:Connect(function(_, new)
		if new == Enum.HumanoidStateType.Jumping then
			playT("jump", 0.1)
		elseif new == Enum.HumanoidStateType.Freefall then
			playT("fall", 0.2)
		elseif new == Enum.HumanoidStateType.Seated then
			playT("sit", 0.1)
		elseif new == Enum.HumanoidStateType.Landed or new == Enum.HumanoidStateType.Running then
			playT("idle", 0.15)
		end
	end)
	playT("idle")
	-- gestos: saludar, bailar, reír… (se cortan al echar a correr)
	bot.emote = function(k, dur)
		local tr = tracks[k]
		if not tr then
			return
		end
		for e in pairs(EMOTES) do
			if tracks[e] and tracks[e].IsPlaying then
				tracks[e]:Stop(0.2)
			end
		end
		tr:Play(0.2)
		task.delay(dur or (k:sub(1, 5) == "dance" and 6 or 2.2), function()
			if tr.IsPlaying then
				tr:Stop(0.3)
			end
		end)
	end
	hum.Running:Connect(function(speed)
		if speed > 2 then
			for e in pairs(EMOTES) do
				if tracks[e] and tracks[e].IsPlaying then
					tracks[e]:Stop(0.2)
				end
			end
		end
	end)
	return model
end

local function spawnAt(bot, cf)
	if bot.Character then
		bot.Character:Destroy()
	end
	local model = buildCharacter(bot)
	if not model then
		return false
	end
	model:PivotTo(cf)
	model.Parent = workspace
	bot.Character = model
	local hrp = model:FindFirstChild("HumanoidRootPart")
	pcall(function()
		hrp:SetNetworkOwner(nil) -- lo mueve el servidor
	end)
	local hum = model:FindFirstChildOfClass("Humanoid")
	hum.Died:Connect(function()
		if bot.Character ~= model then
			return
		end
		task.delay(3, function()
			if bot.alive and bot.Character == model then
				local spot = bot.role == "slap" and CFrame.new(G.Slap.PLAZA + Vector3.new(math.random(-6, 6), 4, math.random(-6, 6))) or (bot.role == "hill" and G.Hill and CFrame.new(G.Hill.CENTER + Vector3.new(math.random(-6, 6), 4, G.Hill.R + 8))) or CFrame.new(C.COURSE.LOBBY + Vector3.new(math.random(-8, 8), 3, math.random(-8, 8)))
				spawnAt(bot, spot)
			end
		end)
	end)
	return true
end

local function hrpOf(bot)
	local c = bot.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function humOf(bot)
	local c = bot.Character
	return c and c:FindFirstChildOfClass("Humanoid")
end

local function newBot(role)
	nextId += 1
	local name = NAMES[(nextId - 1) % #NAMES + 1]
	local bot = {
		IsBot = true,
		UserId = -1000 - nextId,
		Name = name .. "Bot",
		DisplayName = name,
		Parent = workspace, -- (algunos módulos comprueban .Parent)
		role = role,
		alive = true,
		attrs = {},
		chatty = 0.5 + math.random() * 0.8, -- cada uno habla más o menos
		greeted = {},
	}
	function bot:GetNetworkPing()
		return 0
	end
	function bot:SetAttribute(k, v)
		self.attrs[k] = v
	end
	function bot:GetAttribute(k)
		return self.attrs[k]
	end
	return bot
end

local function removeBot(bot)
	bot.alive = false
	G.Race.sessions[bot] = nil
	if bot.role == "hill" and G.Hill then
		pcall(G.Hill.leave, bot)
	end
	if bot.role == "slap" and G.Slap then
		pcall(G.Slap.leave, bot)
	end
	if bot.Character then
		bot.Character:Destroy()
		bot.Character = nil
	end
	local i = table.find(bots, bot)
	if i then
		table.remove(bots, i)
	end
end

-- HABLAR (bocadillos encima de la cabeza, como el chat de burbujas) -----------------------
local lastChatAll = 0
local function say(bot, kind, chance)
	if not bot or not bot.alive or not bot.Character then
		return
	end
	if math.random() > (chance or 1) * (bot.chatty or 1) then
		return
	end
	local now = os.clock()
	if now - lastChatAll < 2.5 or now - (bot.lastChat or 0) < 10 then
		return
	end
	local list = CHAT[kind]
	local head = bot.Character:FindFirstChild("Head")
	if not list or not head then
		return
	end
	lastChatAll, bot.lastChat = now, now
	local msg = list[math.random(1, #list)]
	bot.lastSaid = msg
	task.delay(0.3 + math.random() * 0.9, function() -- tarda un poco en "escribir"
		if bot.alive and head.Parent and G.Net.BotChat then
			G.Net.BotChat:FireAllClients(head, msg)
		end
	end)
end
Bots.say = say

local function emote(bot, k, dur)
	if bot.emote then
		pcall(bot.emote, k, dur)
	end
end
Bots.emote = emote

-- vida social: saludar a quien se acerca, bailar, reírse, saltar… (todos los bots, cuando están libres)
local DANCES = { "dance", "dance2", "dance3", "cheer", "laugh", "point" }
local function isBusy(bot)
	if bot.racing then
		return true
	end
	if G.Slap and G.Slap.stationOf then
		local k = G.Slap.stationOf(bot)
		if k then
			return true
		end
	end
	if G.Hill and G.Hill.memberOf(bot) and G.Hill.st.phase == "playing" then
		return true
	end
	return false
end
local function socialLoop(bot)
	task.wait(2 + math.random() * 4)
	while bot.alive do
		task.wait(3 + math.random() * 5)
		local hum, hrp = humOf(bot), hrpOf(bot)
		if hum and hrp and hum.Health > 0 and not isBusy(bot) and hum:GetState() ~= Enum.HumanoidStateType.Seated then
			-- ¿alguien de verdad cerca al que no haya saludado?
			local near, nd
			for _, p in ipairs(Players:GetPlayers()) do
				local ph = p.Character and p.Character:FindFirstChild("HumanoidRootPart")
				if ph then
					local d = (ph.Position - hrp.Position).Magnitude
					if d < 22 and (not nd or d < nd) and os.clock() - (bot.greeted[p.UserId] or -1e9) > 180 then
						near, nd = p, d
					end
				end
			end
			if near and math.random() < 0.7 then
				bot.greeted[near.UserId] = os.clock()
				local ph = near.Character.HumanoidRootPart
				hum:MoveTo(hrp.Position) -- se para
				hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(ph.Position.X, hrp.Position.Y, ph.Position.Z))
				emote(bot, "wave")
				say(bot, "hi", 0.8)
			else
				local r = math.random()
				if r < 0.16 then
					emote(bot, DANCES[math.random(1, #DANCES)])
				elseif r < 0.26 then
					hum.Jump = true
				elseif r < 0.3 then
					say(bot, "idle", 0.6)
				end
			end
		end
	end
end

-- CARRERA ------------------------------------------------------------------------------
local rayParams = RaycastParams.new()
rayParams.FilterType = Enum.RaycastFilterType.Include
local overlap = OverlapParams.new()
overlap.FilterType = Enum.RaycastFilterType.Include

-- suelo bajo (x, z): altura y si es peligroso (Kill)
local function groundAt(x, z, fromY)
	local hit = workspace:Raycast(Vector3.new(x, fromY + 8, z), Vector3.new(0, -30, 0), rayParams)
	if not hit then
		return nil
	end
	return hit.Position.Y, CollectionService:HasTag(hit.Instance, "Kill"), hit.Instance
end

local function cpPos(i)
	local cp = G.Course.checkpoints[i]
	return cp and cp.pos or (C.COURSE.START + Vector3.new(0, 3, 0))
end

-- RUTA: al crearse el recorrido se calcula una cadena de plataformas de la salida a la meta
-- (cada una alcanzable de un salto desde la anterior). Los bots van de waypoint en waypoint.
local WALKABLE = { StartPad = true, Rest = true, Checkpoint = true, Floor = true, Stone = true, Mover = true, Beam = true, Pillar = true, High = true, Step = true, Belt = true, JumpPad = true, FinishPad = true }
local pathCache = { seed = nil, wps = nil }

local function top(part)
	local cf, size = part.CFrame, part.Size
	local y = cf.Position.Y + size.Y / 2
	return y, cf.Position.X - size.X / 2, cf.Position.X + size.X / 2, cf.Position.Z - size.Z / 2, cf.Position.Z + size.Z / 2
end

local function buildPath(course)
	local plats = {}
	for _, part in ipairs(course:GetChildren()) do
		if part:IsA("BasePart") and WALKABLE[part.Name] then
			local y, x0, x1, z0, z1 = top(part)
			table.insert(plats, { part = part, y = y, x0 = x0, x1 = x1, z0 = z0, z1 = z1, pad = part.Name == "JumpPad", cx = (x0 + x1) / 2 })
		end
	end
	table.sort(plats, function(a, b)
		return a.z0 < b.z0
	end)
	local wps = {}
	local cur = nil
	for _, pl in ipairs(plats) do
		if pl.part.Name == "StartPad" then
			cur = pl
		end
	end
	if not cur then
		return wps
	end
	local x = 0
	local guard = 0
	local used = {}
	local prevZ1 = -math.huge
	while cur and guard < 400 do
		guard += 1
		used[cur] = true
		-- recorrer la plataforma actual hasta su final (centrado en x dentro de ella)
		local cx = cur.cx
		if cur.x1 - cur.x0 >= 2.4 then
			cx = math.clamp(x, cur.x0 + 1.2, cur.x1 - 1.2)
		end
		x = cx
		local endZ = math.max(cur.z0 + 0.8, cur.z1 - 1.2)
		-- entrar un poco más allá del final de la anterior (si la anterior está encima y la tapa, no apuntar debajo)
		local entryZ = math.min(endZ, math.max(cur.z0 + 1.2, prevZ1 + 1.6))
		table.insert(wps, { pos = Vector3.new(cx, cur.y + 3, entryZ), y = cur.y, pad = cur.pad })
		prevZ1 = cur.z1
		if cur.z1 - cur.z0 > 3 then
			table.insert(wps, { pos = Vector3.new(cx, cur.y + 3, endZ), y = cur.y })
		end
		-- siguiente: la plataforma alcanzable más cercana por delante (con el impulsor se llega más alto)
		local best, bestCost = nil, math.huge
		for _, pl in ipairs(plats) do
			local padOnTop = pl.pad and not cur.pad and pl.z0 > cur.z0 and math.abs(pl.y - cur.y) < 1.5
			if pl ~= cur and not used[pl] and (pl.z1 > cur.z1 + 0.5 or padOnTop) then
				local gap = math.max(0, pl.z0 - cur.z1)
				local dy = pl.y - cur.y
				local maxUp = cur.pad and 17 or 5
				local overlapX = math.max(0, math.max(pl.x0 - cx, cx - pl.x1))
				if gap <= 9 and dy <= maxUp and dy > -14 and overlapX <= 9 then
					-- en los impulsores hay que ir al pad (está encima del suelo, no después)
					local cost = gap + overlapX * 0.8 + math.max(0, pl.z0 - cur.z1) * 0.2 + (pl.pad and -3 or 0) + (pl.z0 - cur.z0) * 0.05
					if cost < bestCost then
						best, bestCost = pl, cost
					end
				end
			end
		end
		-- si en el suelo hay un impulsor (pads), primero el pad
		if not best then
			break
		end
		-- un impulsor encima del suelo: no ir hasta el final del suelo, sino al pad
		if best.pad and #wps > 0 and wps[#wps].pos.Z > best.z0 then
			table.remove(wps)
		end
		cur = best
		if cur.part.Name == "FinishPad" then
			table.insert(wps, { pos = Vector3.new(0, cur.y + 3, cur.z0 + 6), y = cur.y })
			break
		end
	end
	return wps
end

local function pathFor(course)
	local seed = course:GetAttribute("Seed")
	if pathCache.seed ~= seed or not pathCache.wps then
		pathCache.seed = seed
		pathCache.wps = buildPath(course)
	end
	return pathCache.wps
end

local function nearestIndex(wps, p)
	for i, w in ipairs(wps) do
		if w.pos.Z > p.Z - 0.5 then
			return i
		end
	end
	return #wps
end

local function raceStep(bot)
	local hrp, hum = hrpOf(bot), humOf(bot)
	if not hrp or not hum or hum.Health <= 0 then
		return
	end
	local course = workspace:FindFirstChild("Course")
	if not course then
		return
	end
	rayParams.FilterDescendantsInstances = { course }
	overlap.FilterDescendantsInstances = { course }
	local wps = pathFor(course)
	local p = hrp.Position
	local finishZ = G.Course.finishZ
	-- su "sesión" de carrera (la comparten con los jugadores: objetos y puesto)
	local sess = G.Race.sessions[bot]
	if sess then
		sess.progress = math.max(sess.progress, p.Z - C.COURSE.START.Z)
		if sess.cp > bot.cp then -- un Cambiazo le cambió de sitio
			bot.cp = sess.cp
			bot.wpi = nil
		end
		-- congelado o recién golpeado: quieto
		if (sess.frozenUntil and os.clock() < sess.frozenUntil) or (sess.lastHitAt and os.clock() - sess.lastHitAt < 0.9) then
			hum:Move(Vector3.zero)
			bot.wpi = nil
			return
		end
	end
	-- caer o tocar algo que mata
	local dead = p.Y < C.COURSE.START.Y - C.COURSE.FALL
	if not dead then
		for _, part in ipairs(workspace:GetPartBoundsInRadius(p - Vector3.new(0, 2.4, 0), 1.0, overlap)) do
			-- las barras giratorias solo giran en los clientes (en el servidor están quietas): no matan a los bots
			if CollectionService:HasTag(part, "Kill") and not CollectionService:HasTag(part, "Spin") then
				dead = true
				break
			end
		end
	end
	if dead then
		bot.deaths = (bot.deaths or 0) + 1
		say(bot, "fall", 0.3)
		hrp.AssemblyLinearVelocity = Vector3.zero
		-- caídas seguidas en el mismo tramo: tras 3, el siguiente salto sale seguro; tras 5, pasa al siguiente
		-- waypoint (como un jugador que al final lo consigue). Así nunca se queda atascado toda la carrera.
		local spot = bot.wpi or 0
		if bot.failSpot == spot then
			bot.fails = (bot.fails or 0) + 1
		else
			bot.failSpot, bot.fails = spot, 1
		end
		bot.sure = bot.fails >= 3
		if bot.fails >= 5 and bot.wpi and wps[bot.wpi + 1] then
			local nxt = wps[bot.wpi + 1]
			hrp.CFrame = CFrame.lookAt(nxt.pos, nxt.pos + Vector3.new(0, 0, 1))
			bot.wpi += 1
			bot.fails = 0
			bot.stuckZ, bot.stuckT = nil, os.clock()
			return
		end
		-- nivel normal: muchas veces vuelve al último waypoint pisado; si no, a su punto de control
		local back = bot.wpi and wps[math.max(1, bot.wpi - 2)]
		if back and (math.random() < 0.7 or bot.fails >= 2) then
			hrp.CFrame = CFrame.lookAt(back.pos, back.pos + Vector3.new(0, 0, 1))
			bot.wpi = math.max(1, bot.wpi - 1)
		else
			local cp = cpPos(bot.cp)
			hrp.CFrame = CFrame.lookAt(cp, cp + Vector3.new(0, 0, 1))
			bot.wpi = nearestIndex(wps, cp)
		end
		bot.stuckZ, bot.stuckT = nil, os.clock()
		return
	end
	local cpi = G.Course.checkpointAt(p)
	if cpi and cpi > bot.cp then
		bot.cp = cpi
	end
	if sess then
		sess.cp = bot.cp
	end
	-- meta
	if p.Z >= finishZ then
		bot.done = true
		if sess then
			sess.finished = true
		end
		say(bot, "finish", 0.6)
		task.delay(1.5, function()
			emote(bot, math.random() < 0.5 and "cheer" or "dance")
		end)
		hum:MoveTo(Vector3.new(math.random(-6, 6), p.Y, finishZ + 10))
		task.delay(0.6, function()
			if hum.Parent then
				hum.Jump = true
			end
		end)
		return
	end
	if #wps == 0 then
		return
	end
	bot.wpi = bot.wpi or nearestIndex(wps, p)
	local w = wps[bot.wpi]
	-- ¿llegado al waypoint? (en horizontal cerca y a su altura)
	local flat = Vector3.new(w.pos.X - p.X, 0, w.pos.Z - p.Z)
	local onGround = hum.FloorMaterial ~= Enum.Material.Air
	if (flat.Magnitude < 1.8 and math.abs(p.Y - w.pos.Y) < 3) or p.Z > w.pos.Z + 1.5 then
		if bot.wpi < #wps then
			bot.wpi += 1
			w = wps[bot.wpi]
			flat = Vector3.new(w.pos.X - p.X, 0, w.pos.Z - p.Z)
		end
	end
	hum:MoveTo(w.pos)
	-- impulsor bajo los pies
	local gyU, _, under = groundAt(p.X, p.Z, p.Y)
	if under and CollectionService:HasTag(under, "JumpPad") and os.clock() - (bot.padAt or 0) > 1 then
		bot.padAt = os.clock()
		hrp.AssemblyLinearVelocity = Vector3.new(0, (under:GetAttribute("Power") or 80), 14)
	end
	local _ = gyU
	if onGround then
		local dir = flat.Magnitude > 0.1 and flat.Unit or Vector3.new(0, 0, 1)
		local gyA = groundAt(p.X + dir.X * 1.4, p.Z + dir.Z * 1.4, p.Y)
		local _, killA = groundAt(p.X + dir.X * 2.6, p.Z + dir.Z * 2.6, p.Y)
		local feet = p.Y - 3
		local gap = (not gyA) or gyA < feet - 1.5
		local higher = w.pos.Y - 3 > feet + 1.2 and flat.Magnitude < 7
		local dist = flat.Magnitude
		if (gap or higher) and dist <= 11.5 and os.clock() - (bot.hopAt or 0) > 0.5 then
			-- salto calculado para caer en el waypoint (como lo haría un jugador que apunta bien);
			-- a veces se queda corto: nivel normal
			bot.hopAt = os.clock()
			local miss = not bot.sure and math.random() < bot.clumsy
			bot.sure = false
			local t = math.clamp(dist / 17, 0.38, 0.75)
			local g = workspace.Gravity
			local dy = (w.pos.Y - p.Y) + 0.5
			local vy = (dy + 0.5 * g * t * t) / t
			local k = miss and 0.72 or 1
			hum:ChangeState(Enum.HumanoidStateType.Jumping)
			hrp.AssemblyLinearVelocity = Vector3.new(flat.X / t * k, math.min(vy, 75), flat.Z / t * k)
		elseif (gap or killA or higher) and math.random() > bot.clumsy then
			hum.Jump = true
		end
	end
	-- atascado: saltar; si sigue, volver al waypoint anterior
	if not bot.stuckZ or p.Z > bot.stuckZ + 1.5 then
		bot.stuckZ, bot.stuckT = p.Z, os.clock()
	elseif os.clock() - bot.stuckT > 2.5 then
		hum.Jump = true
		if os.clock() - bot.stuckT > 6 then
			local back = wps[math.max(1, bot.wpi - 1)]
			hrp.CFrame = CFrame.new(back.pos)
			bot.stuckT = os.clock()
		end
	end
end

local function raceLoop(bot)
	local wasState = nil
	while bot.alive do
		local state = G.Race.state
		local hum = humOf(bot)
		if state ~= wasState then
			if state == "countdown" and hum then
				-- a la parrilla, detrás de los jugadores
				bot.cp, bot.done, bot.lane, bot.stuckZ, bot.wpi = 0, false, 0, nil, nil
				bot.racing = true
				G.Race.sessions[bot] = { racing = true, finished = false, progress = 0, cp = 0, item = nil, rolling = false, nextLucky = math.huge, isBot = true }
				local k = bot.slot or 1
				local pos = C.COURSE.START + Vector3.new(-6 + ((k - 1) % 4) * 4, 3, -9.5 - math.floor((k - 1) / 4) * 3)
				local hrp = hrpOf(bot)
				if hrp then
					hrp.AssemblyLinearVelocity = Vector3.zero
					hrp.CFrame = CFrame.lookAt(pos, pos + Vector3.new(0, 0, 1))
				end
				hum.WalkSpeed = 0
				bot.clumsy = math.random() * 0.06 + 0.03 -- nivel normal: fallan algún salto
				say(bot, "start", 0.35)
			elseif state == "racing" and hum and bot.racing then
				hum.WalkSpeed = 20 * (0.88 + math.random() * 0.1)
			elseif (state == "results" or state == "break") and bot.racing then
				bot.racing = false
				G.Race.sessions[bot] = nil
				local hrp = hrpOf(bot)
				if hrp then
					hrp.CFrame = CFrame.new(C.COURSE.LOBBY + Vector3.new(math.random(-10, 10), 3, math.random(-8, 8)))
				end
				if hum then
					hum.WalkSpeed = 12 + math.random() * 4
				end
			end
			wasState = state
		end
		if state == "racing" and bot.racing and not bot.done then
			local okS, errS = pcall(raceStep, bot)
			if not okS and os.clock() - (bot.warnAt or 0) > 10 then
				bot.warnAt = os.clock()
				warn("[Bots] " .. tostring(errS))
			end
			task.wait(0.12)
		else
			-- en el vestíbulo: pasear un poco
			if hum and not bot.racing and math.random() < 0.25 then
				local c = C.COURSE.LOBBY
				local a = math.random() * math.pi * 2
				hum:MoveTo(Vector3.new(c.X + math.cos(a) * math.random(4, 18), c.Y, c.Z + math.sin(a) * math.random(4, 18)))
			end
			task.wait(state == "countdown" and 0.3 or 1.5)
		end
	end
end

-- SILLAS -------------------------------------------------------------------------------
local function slapBrain(bot)
	return function(kind, data)
		if not bot.alive then
			return
		end
		if kind == "station" then
			bot.station = data
			if type(data) == "table" and data.phase == "waiting" and data.seated ~= bot.UserId then
				local round = data
				-- si hay gente de verdad en la mesa, los bots dejan que peguen ellos primero
				local humans = 0
				for _, m in ipairs(data.members or {}) do
					if m.id > 0 then
						humans += 1
					end
				end
				task.delay(humans > 0 and (3 + math.random() * 3) or (1.2 + math.random() * 1.8), function()
					if bot.station == round and bot.alive then
						G.Slap.request(bot)
					end
				end)
			end
		elseif kind == "bar" then
			task.delay(0.3 + math.random() * 1.6, function()
				if bot.alive then
					G.Slap.stop(bot, nil)
					say(bot, "slap", 0.25)
				end
			end)
		elseif kind == "dodge" and type(data) == "table" then
			if math.random() < 0.12 then -- esquiva pocas veces (nivel normal)
				task.delay(0.15 + math.random() * 0.15, function()
					if bot.alive then
						G.Slap.dodge(bot, data.key)
					end
				end)
			end
		elseif kind == "guess" and type(data) == "table" then
			local opts = data.options or {}
			say(bot, "guess", 0.2)
			task.delay(1.5 + math.random() * 2, function()
				if bot.alive and #opts > 0 then
					G.Slap.guess(bot, opts[math.random(1, #opts)].id)
				end
			end)
		end
	end
end

local function slapLoop(bot)
	while bot.alive do
		task.wait(2 + math.random() * 2)
		-- ¿hay una PERSONA esperando sola (o con sitio) en una mesa que aún no ha empezado? → ir con ella
		local humanTable
		for k = 1, G.Slap.COUNT do
			local st = G.Slap.station(k)
			local humans = 0
			for _, m in ipairs(st.members) do
				if not (type(m) == "table" and m.IsBot) then
					humans += 1
				end
			end
			if humans > 0 and not st.match and #st.members < 4 then
				humanTable = k
				break
			end
		end
		local mine = G.Slap.stationOf(bot)
		if humanTable and mine ~= humanTable and bot.alive and bot.Character then
			local cur = mine and G.Slap.station(mine)
			local curHasHuman = false
			if cur then
				for _, m in ipairs(cur.members) do
					if not (type(m) == "table" and m.IsBot) then
						curHasHuman = true
					end
				end
			end
			-- solo se cambia si en su mesa no hay personas y no está sentado ni pegando
			if not cur or (not curHasHuman and cur.seated ~= bot and cur.slapper ~= bot) then
				if mine then
					G.Slap.leave(bot)
				end
				if G.Slap.join(bot, humanTable) then
					continue
				end
			end
		end
		if bot.alive and not G.Slap.stationOf(bot) and bot.Character then
			-- buscar mesa: la que ya tenga bots o gente y sitio (deja siempre un hueco para jugadores)
			-- mesas por preferencia (las que ya tienen gente primero); si una le rechaza (eliminado), prueba otra
			local order = {}
			for k = 1, G.Slap.COUNT do
				local free = G.Slap.freeSlots(k)
				if free >= 2 then
					table.insert(order, { k = k, used = 4 - free })
				end
			end
			table.sort(order, function(a, b)
				return a.used > b.used
			end)
			for _, o in ipairs(order) do
				if o.used < 3 and G.Slap.join(bot, o.k) then
					break
				end
			end
		end
	end
end

-- REY DE LA COLINA ----------------------------------------------------------------------
-- Entran a la arena cuando no hay partida; en partida van hacia la colina y empujan al que tienen cerca.
local function hillLoop(bot)
	local H = G.Hill
	local nextPush = 0
	while bot.alive do
		local st = H.st
		local hum, hrp = humOf(bot), hrpOf(bot)
		if hum and hrp and hum.Health > 0 then
			if not H.memberOf(bot) then
				if st.phase ~= "playing" and st.phase ~= "result" and #st.members < H.MAX and math.random() < 0.35 then
					H.join(bot)
					hum.WalkSpeed = 16 -- algo más lentos que un jugador (18): nivel normal
				end
				task.wait(1.5)
			elseif st.phase == "playing" and st.alive[bot] then
				-- hacia la colina, con un poco de desorden
				local target = H.CENTER + Vector3.new(math.random(-3, 3), H.TOP + 2, math.random(-3, 3))
				local nearest, nd = nil, math.huge
				for _, m in ipairs(st.members) do
					local mh = m ~= bot and st.alive[m] and hrpOf(m)
					if mh then
						local d = (mh.Position - hrp.Position).Magnitude
						if d < nd then
							nearest, nd = mh, d
						end
					end
				end
				if nearest and nd < 9 and math.random() < 0.6 then
					target = nearest.Position -- ir a por el que tiene cerca
				end
				hum:MoveTo(target)
				if not H.botsCalm and nearest and nd < 6.5 and os.clock() > nextPush then
					-- mirar al objetivo y empujar
					hrp.CFrame = CFrame.lookAt(hrp.Position, Vector3.new(nearest.Position.X, hrp.Position.Y, nearest.Position.Z))
					H.push(bot)
					say(bot, "push", 0.12)
					nextPush = os.clock() + 1 + math.random() * 1.4
				end
				task.wait(0.25)
			else
				task.wait(1)
			end
		else
			task.wait(1)
		end
	end
end

-- POBLACIÓN ----------------------------------------------------------------------------
local function count(role)
	local n = 0
	for _, b in ipairs(bots) do
		if b.role == role then
			n += 1
		end
	end
	return n
end

local function balance()
	local n = realCount()
	local t = TARGET[n] or { 0, 0 }
	for _, spec in ipairs({ { "race", t[1] }, { "slap", t[2] }, { "hill", G.Hill and (t[3] or 0) or 0 } }) do
		local role, want = spec[1], spec[2]
		while count(role) > want do
			-- quitar primero los que no están en mitad de algo
			local victim
			for _, b in ipairs(bots) do
				if b.role == role and not (role == "race" and b.racing) then
					victim = b
					break
				end
			end
			if not victim then
				break
			end
			removeBot(victim)
		end
		while count(role) < want do
			local bot = newBot(role)
			bot.slot = count(role) + 1
			local spot = role == "slap" and CFrame.new(G.Slap.PLAZA + Vector3.new(math.random(-8, 8), 4, math.random(-8, 8))) or (role == "hill" and G.Hill and CFrame.new(G.Hill.CENTER + Vector3.new(math.random(-8, 8), 4, G.Hill.R + 8))) or CFrame.new(C.COURSE.LOBBY + Vector3.new(math.random(-10, 10), 3, math.random(-8, 8)))
			if not spawnAt(bot, spot) then
				break
			end
			table.insert(bots, bot)
			task.spawn(socialLoop, bot)
			if role == "slap" then
				bot.onSlap = slapBrain(bot)
				task.spawn(slapLoop, bot)
			elseif role == "hill" then
				task.spawn(hillLoop, bot)
			else
				task.spawn(raceLoop, bot)
			end
		end
	end
end

function Bots.init(g)
	G = g
	C = g.Config
	-- la carrera cuenta con los bots: con ellos hay carrera aunque nadie se apunte
	G.Race.extraRunners = function(all)
		local n = 0
		for _, b in ipairs(bots) do
			if b.role == "race" and b.alive and b.Character and (all or (b.racing and not b.done)) then
				n += 1
			end
		end
		return n
	end
	if not G.Slap then
		warn("[Bots] sin Slap: no hay bots de sillas")
	end
	setupGroups()
	task.spawn(function()
		while true do
			local ok, err = pcall(balance)
			if not ok then
				warn("[Bots] " .. tostring(err))
			end
			task.wait(5)
		end
	end)
end

Bots.list = bots
return Bots
