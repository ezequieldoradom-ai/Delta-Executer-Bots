-- Convierte cada dios (y cada guardián) en un avatar R15 de Roblox con sus accesorios
-- (cabezas de animal, coronas, barbas, alas, armas...) y animaciones oficiales.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Avatars = {}
local G
local folder

local HEAD = {
	Hair = true, HairBack = true, Beard = true, Patch = true, Stripe = true, HornL = true, HornR = true,
	HornTipL = true, HornTipR = true, Snout = true, EarL = true, EarR = true, Beak = true, Mask = true,
	Teeth = true, EyeL = true, EyeR = true, Laurel = true, Nemes = true, NemesStripe = true, Helmet = true,
	WingL = true, WingR = true, Feather = true, Crown = true, Spike = true, Sun = true, Moon = true,
	Petasos = true, Antler = true, Tine = true, Flower = true, Crest = true, Atef = true, FeatherL = true,
	FeatherR = true, Brim = true, Cap = true, Halo = true, Torc = true, Question = true, Mane = true,
	FlameHead = true, NoseRing = true, Nose = true, Fangs = true, Crescent = true, Veil = true,
}
local ITEM = {
	Shaft = true, Prong = true, Bar = true, Handle = true, HammerHead = true, Bolt1 = true, Bolt2 = true,
	Blade = true, Guard = true, Tip = true, Wings = true, Gem = true, Bow = true, String = true, Lyre = true,
	Stick = true, Flame = true, Orb = true, PanL = true, PanR = true, Beam = true, Horn = true, Pipe = true,
	Ring = true, AxeBlade = true, AxeEdge = true,
}
local TORSO = { Skirt = true, Belt = true, Sash = true, Wing = true, Shield = true, Star = true }
-- Piezas de una cabeza de animal (se conservan con keep = { "head" })
local ANIMAL_HEAD = {
	Snout = true, EarL = true, EarR = true, Beak = true, Teeth = true, EyeL = true, EyeR = true, HornL = true, HornR = true,
	HornTipL = true, HornTipR = true, Mane = true, Fangs = true, NoseRing = true, Nose = true,
}

-- Ropa del catálogo (Outfits.luau). Se carga sin romper nada si el archivo no existe.
local OUTFITS = {}
do
	local m = script.Parent:FindFirstChild("Outfits")
	if m then
		local ok, t = pcall(require, m)
		if ok and type(t) == "table" then
			OUTFITS = t
		end
	end
end
Avatars.OUTFITS = OUTFITS
local OUTFIT_FIELDS = {
	hat = "HatAccessory", hair = "HairAccessory", face = "FaceAccessory", neck = "NeckAccessory",
	shoulders = "ShouldersAccessory", front = "FrontAccessory", back = "BackAccessory", waist = "WaistAccessory",
}

local function idString(list)
	local parts = {}
	for _, v in ipairs(list) do
		local n = tonumber(v)
		if n and n > 0 then
			table.insert(parts, string.format("%.0f", n))
		end
	end
	return table.concat(parts, ",")
end

-- Pone la ropa del catálogo en la descripción del avatar
local function applyOutfit(d, outfit)
	for key, field in pairs(OUTFIT_FIELDS) do
		if type(outfit[key]) == "table" then
			d[field] = idString(outfit[key])
		end
	end
	if tonumber(outfit.shirt) then
		d.Shirt = tonumber(outfit.shirt)
	end
	if tonumber(outfit.pants) then
		d.Pants = tonumber(outfit.pants)
	end
	if type(outfit.layered) == "table" and #outfit.layered > 0 then
		local acc = {}
		for i, l in ipairs(outfit.layered) do
			local ok, kind = pcall(function()
				return Enum.AccessoryType[l.type]
			end)
			if ok and kind and tonumber(l.id) then
				table.insert(acc, { AccessoryType = kind, AssetId = tonumber(l.id), IsLayered = true, Order = i })
			end
		end
		if #acc > 0 then
			d:SetAccessories(acc, false) -- false: solo la ropa 3D; no quita pelo ni sombreros
		end
	end
end

-- Animaciones oficiales de Roblox (R15)
Avatars.ANIM = {
	idle = "rbxassetid://507766666",
	walk = "rbxassetid://507777826",
	run = "rbxassetid://507767714",
}

local function weld(a, b)
	local w = Instance.new("WeldConstraint")
	w.Part0 = a
	w.Part1 = b
	w.Parent = b
end

local function makeRig(L, god, outfit)
	local d = Instance.new("HumanoidDescription")
	local skin = L.skin
	local chest = L.chest or L.robe
	local legs = L.legs or L.robe
	d.HeadColor = skin
	d.LeftArmColor = skin
	d.RightArmColor = skin
	d.TorsoColor = chest
	d.LeftLegColor = legs
	d.RightLegColor = legs
	d.HeightScale = 1.05
	d.WidthScale = math.clamp((L.bulk or 1) * 1.0, 0.7, 1)
	d.DepthScale = 1
	d.HeadScale = 1
	d.BodyTypeScale = 0.3
	d.ProportionScale = 0
	if L.silhouette then
		for _, k in ipairs({ "HeadColor", "LeftArmColor", "RightArmColor", "TorsoColor", "LeftLegColor", "RightLegColor" }) do
			d[k] = Color3.fromRGB(8, 8, 12)
		end
	end
	if outfit then
		applyOutfit(d, outfit)
	end
	local rig = Players:CreateHumanoidModelFromDescription(d, Enum.HumanoidRigType.R15)
	return rig
end

function Avatars.make(god)
	local existing = folder:FindFirstChild(god.id)
	if existing then
		return existing
	end
	local L = G.GodModel.look(god)
	local outfit = OUTFITS[god.id]
	local ok, rig = pcall(makeRig, L, god, outfit)
	if (not ok or not rig) and outfit then
		-- si la ropa del catálogo falla (prenda borrada…), se crea sin ella
		warn("Ropa del catálogo no cargada", god.id, rig)
		outfit = nil
		ok, rig = pcall(makeRig, L, god, nil)
	end
	if not ok or not rig then
		warn("Avatar no creado", god.id, rig)
		return nil
	end
	-- qué piezas propias se conservan cuando lleva ropa del catálogo
	local keep = nil
	if outfit then
		keep = {}
		for _, k in ipairs(outfit.keep or { "item" }) do
			keep[k] = true
		end
		rig:SetAttribute("Outfit", true)
	end
	rig.Name = god.id
	local hum = rig:FindFirstChildOfClass("Humanoid")
	hum.DisplayDistanceType = Enum.HumanoidDisplayDistanceType.None
	hum.HealthDisplayType = Enum.HumanoidHealthDisplayType.AlwaysOff
	hum.BreakJointsOnDeath = false
	hum.RequiresNeck = false
	local hrp = rig:FindFirstChild("HumanoidRootPart")
	for _, p in ipairs(rig:GetDescendants()) do
		if p:IsA("BasePart") then
			p.CanCollide = false
			p.CanQuery = false
			p.CanTouch = false
			p.Massless = true
			p.Anchored = false
		end
	end
	hrp.Anchored = true
	-- de pie, con los pies en Y = 0
	local pivotH = hum.HipHeight + hrp.Size.Y / 2
	rig:PivotTo(CFrame.new(0, pivotH, 0))
	rig:SetAttribute("PivotH", pivotH)
	rig:SetAttribute("Avatar", true)
	if hum:FindFirstChild("Animator") == nil then
		Instance.new("Animator").Parent = hum
	end
	-- accesorios: se toman de la figura de piezas y se sueldan al avatar
	local old = G.GodModel.buildParts(god, Color3.new(1, 1, 1))
	local oldHead = old:FindFirstChild("Head") or old:FindFirstChild("FlameHead")
	local rigHead = rig:FindFirstChild("Head")
	local k = (rigHead.Size.Y / 1.2) * 0.96
	old:ScaleTo(k)
	local oldTorso = old:FindFirstChild("Torso")
	local oldArmR = old:FindFirstChild("ArmR")
	local oldHand = oldArmR.CFrame * CFrame.new(0, -oldArmR.Size.Y / 2, 0) * CFrame.Angles(math.rad(-35), 0, 0)
	local animalHead = L.head ~= nil and L.head ~= "goat" and (not keep or keep.head == true)
	if animalHead then
		rigHead.Transparency = 1
		local face = rigHead:FindFirstChildOfClass("Decal")
		if face then
			face:Destroy()
		end
	end
	local acc = Instance.new("Folder")
	acc.Name = "Accessories"
	acc.Parent = rig
	local headTop = (L.head == nil or L.head == "goat") and old:FindFirstChild("Head") and old.Head.Position.Y - 0.7 * k or -math.huge
	for _, p in ipairs(old:GetChildren()) do
		if p:IsA("BasePart") then
			local name = p.Name
			local target, rel
			-- con ropa del catálogo solo se conservan las piezas pedidas en "keep"
			local wanted = true
			if keep then
				wanted = (keep.item and ITEM[name] ~= nil)
					or (keep.head and animalHead and (name == "Head" or ANIMAL_HEAD[name] ~= nil))
					or (keep.wings and (name == "Wing" or name == "WingL" or name == "WingR"))
					or false
			end
			if not wanted then
				target = nil
			elseif HEAD[name] or (name == "Head" and animalHead) then
				if name == "Star" then
					continue
				end
				target, rel = rigHead, oldHead.CFrame:ToObjectSpace(p.CFrame)
			elseif ITEM[name] then
				target, rel = rig:FindFirstChild("RightHand"), oldHand:ToObjectSpace(p.CFrame)
			elseif TORSO[name] then
				if name == "Star" and p.Position.Y > headTop then
					target, rel = rigHead, oldHead.CFrame:ToObjectSpace(p.CFrame)
				else
					target, rel = rig:FindFirstChild("UpperTorso"), oldTorso.CFrame:ToObjectSpace(p.CFrame)
				end
			end
			if target then
				p.Anchored = false
				p.CanCollide = false
				p.CanQuery = false
				p.Massless = true
				p.CFrame = target.CFrame * rel
				p.Parent = acc
				weld(target, p)
			end
		end
	end
	old:Destroy()
	rig.PrimaryPart = hrp
	rig.Parent = folder
	return rig
end

-- Reproduce una animación en un avatar (servidor: guardianes)
function Avatars.play(rig, name, speed)
	local hum = rig:FindFirstChildOfClass("Humanoid")
	local animator = hum and hum:FindFirstChildOfClass("Animator")
	if not animator then
		return
	end
	rig:SetAttribute("Anim", name)
	local tracks = rig:GetAttribute("_t") and nil
	Avatars._tracks = Avatars._tracks or setmetatable({}, { __mode = "k" })
	local set = Avatars._tracks[rig]
	if not set then
		set = {}
		Avatars._tracks[rig] = set
	end
	if set.current == name then
		if set[name] and speed then
			set[name]:AdjustSpeed(speed)
		end
		return
	end
	if set.current and set[set.current] then
		set[set.current]:Stop(0.2)
	end
	if not set[name] then
		local a = Instance.new("Animation")
		a.AnimationId = Avatars.ANIM[name]
		set[name] = animator:LoadAnimation(a)
		set[name].Looped = true
	end
	set[name]:Play(0.2)
	if speed then
		set[name]:AdjustSpeed(speed)
	end
	set.current = name
end

function Avatars.init(g)
	G = g
	folder = Instance.new("Folder")
	folder.Name = "AvatarTemplates"
	folder.Parent = ReplicatedStorage
	G.GodModel.avatarBuilder = Avatars.make
end

return Avatars
