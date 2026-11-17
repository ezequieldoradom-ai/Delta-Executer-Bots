-- Bate y armas mitológicas: solo se puede pegar dentro del pasillo
local Combat = {}
local G
local C

local function buildTool(weaponKey)
	local w = C.WEAPONS[weaponKey] or C.WEAPONS.bat
	local tool = Instance.new("Tool")
	tool.Name = w.es
	tool:SetAttribute("Weapon", weaponKey)
	tool.RequiresHandle = true
	tool.CanBeDropped = false
	tool.ToolTip = w.en
	tool.Grip = CFrame.new(0, -0.9, 0) * CFrame.Angles(math.rad(-35), 0, 0)
	local handle = Instance.new("Part")
	handle.Name = "Handle"
	handle.Size = Vector3.new(0.45, 2.4 + w.power * 0.1, 0.45)
	handle.Color = w.color
	handle.Material = (w.order >= 5) and Enum.Material.Neon or Enum.Material.Wood
	handle.CanCollide = false
	handle.Massless = true
	handle.Parent = tool
	local headPart = Instance.new("Part")
	headPart.Name = "Head"
	headPart.Size = weaponKey == "mjolnir" and Vector3.new(1.8, 1.1, 1.1) or Vector3.new(0.75, 1.1, 0.75)
	headPart.Color = w.color
	headPart.Material = (w.order >= 3) and Enum.Material.Metal or Enum.Material.Wood
	headPart.CanCollide = false
	headPart.Massless = true
	headPart.CFrame = handle.CFrame * CFrame.new(0, handle.Size.Y / 2 + headPart.Size.Y / 2 - 0.2, 0)
	local weld = Instance.new("WeldConstraint")
	weld.Part0 = handle
	weld.Part1 = headPart
	weld.Parent = headPart
	headPart.Parent = tool
	if w.order >= 4 then
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 10
		pe.Lifetime = NumberRange.new(0.4, 0.8)
		pe.LightEmission = 1
		pe.Color = ColorSequence.new(w.color)
		pe.Size = NumberSequence.new(0.4, 0)
		pe.Parent = headPart
	end
	return tool
end

function Combat.giveWeapon(player)
	local d = G.Data.profiles[player]
	if not d then
		return
	end
	local function clear(container)
		if container then
			for _, t in ipairs(container:GetChildren()) do
				if t:IsA("Tool") and t:GetAttribute("Weapon") then
					t:Destroy()
				end
			end
		end
	end
	clear(player:FindFirstChild("Backpack"))
	clear(player.Character)
	local tool = buildTool(d.weapon)
	tool.Activated:Connect(function()
		Combat.swing(player, tool)
	end)
	tool.Parent = player:FindFirstChild("Backpack")
end

local function lightning(a, b)
	local dist = (b - a).Magnitude
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = false
	p.Material = Enum.Material.Neon
	p.Color = Color3.fromRGB(150, 210, 255)
	p.Size = Vector3.new(0.4, 0.4, dist)
	p.CFrame = CFrame.lookAt((a + b) / 2, b)
	p.Parent = workspace
	game:GetService("Debris"):AddItem(p, 0.2)
end

function Combat.swing(player, tool)
	local s = G.Core.sessions[player]
	local d = G.Data.profiles[player]
	if not s or not d then
		return
	end
	local now = os.clock()
	if now - s.lastHit < C.HIT_COOLDOWN then
		return
	end
	s.lastHit = now
	-- animación de golpe del script Animate por defecto
	local anim = Instance.new("StringValue")
	anim.Name = "toolanim"
	anim.Value = "Slash"
	anim.Parent = tool
	game:GetService("Debris"):AddItem(anim, 1)

	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp or not G.World.inCorridor(hrp.Position) then
		return
	end
	local w = C.WEAPONS[d.weapon] or C.WEAPONS.bat
	local best, bestDist = nil, C.HIT_RANGE
	for other, os2 in pairs(G.Core.sessions) do
		if other ~= player then
			local oc = other.Character
			local ohrp = oc and oc:FindFirstChild("HumanoidRootPart")
			if ohrp and G.World.inCorridor(ohrp.Position) then
				local delta = ohrp.Position - hrp.Position
				local dist = delta.Magnitude
				local facing = dist > 0.1 and hrp.CFrame.LookVector:Dot(delta.Unit) or 1
				if dist < bestDist and facing > 0.2 then
					best, bestDist = other, dist
				end
			end
		end
	end
	if not best then
		return
	end
	local vs = G.Core.sessions[best]
	local vd = G.Data.profiles[best]
	if not vs or not vd then
		return
	end
	if now < vs.invulnUntil or now < vs.shieldUntil or vs.afk then
		return
	end
	if vd.playtime < C.NEWBIE_PROTECTION then
		G.Net.toast(player, "newbie")
		return
	end
	vs.invulnUntil = now + C.HIT_INVULN
	local ohrp = best.Character.HumanoidRootPart
	local dir = Vector3.new(ohrp.Position.X - hrp.Position.X, 0, ohrp.Position.Z - hrp.Position.Z)
	dir = dir.Magnitude > 0.1 and dir.Unit or hrp.CFrame.LookVector
	local vel = dir * (70 * w.power) + Vector3.new(0, 30 + 10 * w.power, 0)
	if vel.Magnitude > 450 then
		vel = vel.Unit * 450
	end
	G.Net.Knock:FireClient(best, vel)
	if w.lightning then
		lightning(hrp.Position, ohrp.Position)
	end
	if vs.carrying then
		local rarity = vs.carrying.rarity
		G.Packs.dropCarried(best, true, ohrp.Position)
		if rarity >= C.ANNOUNCE_CHAT_FROM then
			G.Net.announce("all", "batSteal", { player.DisplayName, { rarity = rarity }, best.DisplayName }, { color = "#FF8A3D" })
		end
	end
end

function Combat.init(g)
	G = g
	C = g.Config
end

return Combat
