-- Comprobación en vivo (no forma parte de la batería): arranca el bucle real de Packs (Heartbeat),
-- roba un sobre con un jugador simulado, deja que el guardián lo atrape y mira que el sobre
-- se oculta, vuelve entero a su hueco del nido y que "Salvar el sobre" lo entrega.
--   python3 tools/preview.py run tools/tmp_packs/live_check.luau
local out = {}
local function add(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring((select(i, ...)))
	end
	table.insert(out, table.concat(t, " "))
end
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
local noop = { FireClient = function() end, FireAllClients = function() end }
G.Net.State, G.Net.Toast, G.Net.Offer, G.Net.Reveal, G.Net.Announce, G.Net.Knock = noop, noop, noop, noop, noop, noop
local C = G.Config
G.Packs.start() -- bucle real: guardianes y sobres en cada fotograma

local fp = { UserId = -301, DisplayName = "Live", Name = "Live", Character = nil }
G.Data.profiles[fp] = G.Data.sanitize(nil, C)
G.Core.sessions[fp] = { passes = {}, combo = 1, lastTap = 0, lastHit = 0, invulnUntil = 0, afk = false, joinedAt = os.clock(), actionTimes = {}, comboTarget = 0.5 }
local d, s = G.Data.profiles[fp], G.Core.sessions[fp]
local char = Instance.new("Model")
local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Anchored = true
hrp.Size = Vector3.new(2, 2, 1)
hrp.Parent = char
local head = Instance.new("Part")
head.Name = "Head"
head.Anchored = true
head.Size = Vector3.new(2, 1, 1)
head.Parent = char
char.Parent = workspace
fp.Character = char
local function stand(pos)
	hrp.CFrame = CFrame.new(pos.X, pos.Y + 3, pos.Z)
	head.CFrame = CFrame.new(pos.X, pos.Y + 4.5, pos.Z)
end
local function allHidden(part)
	if part.Transparency ~= 1 then return false end
	for _, x in ipairs(part:GetDescendants()) do
		if (x:IsA("BasePart") or x:IsA("Decal")) and x.Transparency ~= 1 then return false end
		if (x:IsA("ParticleEmitter") or x:IsA("PointLight") or x:IsA("SurfaceGui") or x:IsA("BillboardGui") or x:IsA("Beam")) and x.Enabled then return false end
	end
	return true
end

for round = 1, 2 do
	local pack = G.Packs.debugSpawn(1, 3, round == 1 and 13 or 7, 140, round == 2)
	local home = pack.part.CFrame
	local guard = G.World.guardians[1]
	local g0 = guard.model:GetPivot().Position
	local snap = {}
	for _, x in ipairs(pack.part:GetDescendants()) do
		if x:IsA("BasePart") or x:IsA("Decal") then snap[x] = x.Transparency end
	end
	local centre = Vector3.new(0, 0, G.World.zoneStart(1) + C.NEST_OFFSET)
	local spot = pack.home + (pack.home - centre).Unit * 4 + Vector3.new(0, 0.2, 0)
	stand(spot)
	G.Packs.grab(fp, pack)
	add("ronda", round, "· cogido:", pack.state)
	task.wait(0.4)
	local c = pack.part.Position
	add("  sigue a la cabeza (Heartbeat):", math.abs(c.X - head.Position.X) < 0.01 and math.abs(c.Z - head.Position.Z) < 0.01 and c.Y > head.Position.Y + 2)
	local orb = nil
	for _, x in ipairs(pack.part:GetChildren()) do
		if x:IsA("BasePart") and x.Anchored and x.Name ~= "Beam" then orb = x end
	end
	add("  guardián en marcha:", (guard.model:GetPivot().Position - g0).Magnitude > 2, "objetivo:", guard.target == fp)
	-- el guardián lo atrapa
	local t0 = os.clock()
	while s.carrying and os.clock() - t0 < 12 do
		task.wait(0.1)
	end
	add(string.format("  atrapado en %.1f s · estado:", os.clock() - t0), pack.state, "· oculto del todo:", allHidden(pack.part), "· sin estela:", pack.part:FindFirstChild("CarryFX") == nil)
	if round == 1 then
		-- no compra: a los 10,5 s vuelve a su hueco
		task.wait(11.2)
		local same = (pack.part.Position - home.Position).Magnitude < 0.001 and pack.part.CFrame.LookVector:Dot(home.LookVector) > 0.9999
		local restored = true
		for x, tr in pairs(snap) do
			if math.abs(x.Transparency - tr) > 1e-4 then restored = false end
		end
		add("  de vuelta:", pack.state, "· en su hueco como estaba:", same, "· transparencias originales:", restored, "· aviso activo:", pack.prompt.Enabled)
		add("  haz de luz vertical sobre el sobre:", pack.beam ~= nil and math.abs(pack.beam.CFrame.RightVector.Y) > 0.999 and math.abs(pack.beam.Position.X - pack.part.Position.X) < 2)
		if orb then
			add("  pieza que orbita recolocada junto al sobre:", (orb.Position - pack.part.Position).Magnitude < 6 * pack.k)
		end
	else
		-- compra "Salvar el sobre" mientras está pendiente
		local before = #d.altarPacks
		local ok = G.Packs.savePurchased(fp)
		add("  salvado:", ok, "· altar recibe:", #d.altarPacks == before + 1 and d.altarPacks[#d.altarPacks].r == 7 and d.altarPacks[#d.altarPacks].dawn == true, "· sobre destruido:", pack.state == "gone" and pack.part.Parent == nil)
	end
end
-- los sobres del suelo no se han movido en todo este rato
local moved = 0
local snap2 = {}
for id, p in pairs(G.Packs.list) do snap2[id] = p.part.CFrame end
task.wait(0.5)
for id, p in pairs(G.Packs.list) do
	if p.part.CFrame ~= snap2[id] then moved += 1 end
end
add("sobres del suelo que se movieron con el bucle real:", moved)
return table.concat(out, "\n")
