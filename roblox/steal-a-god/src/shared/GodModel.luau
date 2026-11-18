-- Construye la figura de cada dios con piezas (se usa en las estatuas y en las cartas 3D)
local GodModel = {}

local rgb = Color3.fromRGB

-- Estilo base de cada mitología
local MYTH_STYLE = {
	greek = { skin = rgb(236, 196, 160), robe = rgb(245, 244, 238), trim = rgb(232, 186, 60), hair = rgb(90, 60, 35), hat = "laurel" },
	egyptian = { skin = rgb(186, 128, 86), robe = rgb(248, 244, 230), trim = rgb(240, 190, 50), trim2 = rgb(40, 80, 190), hair = rgb(20, 20, 25), hat = "nemes" },
	norse = { skin = rgb(242, 205, 175), robe = rgb(85, 105, 140), trim = rgb(120, 85, 50), hair = rgb(200, 150, 70), hat = "helmet", beard = true },
	aztec = { skin = rgb(176, 112, 70), robe = rgb(30, 150, 130), trim = rgb(210, 50, 40), hair = rgb(20, 20, 20), hat = "feathers" },
	babylonian = { skin = rgb(190, 138, 98), robe = rgb(40, 70, 165), trim = rgb(235, 190, 70), hair = rgb(30, 22, 18), hat = "tallcrown", beard = true },
	celtic = { skin = rgb(244, 210, 186), robe = rgb(40, 115, 65), trim = rgb(205, 170, 90), hair = rgb(170, 70, 30), hat = "torc" },
	cosmic = { skin = rgb(60, 40, 120), robe = rgb(20, 12, 40), trim = rgb(170, 120, 255), hair = rgb(10, 10, 20), hat = "halo", glow = true },
}

-- Rasgos propios de cada dios
local LOOKS = {
	pan = { head = "goat", item = "pipes", robe = rgb(130, 90, 55), hat = "none", beard = true },
	eolo = { item = "cloud", robe = rgb(170, 215, 255) },
	iris = { wings = rgb(255, 140, 210), robe = rgb(255, 170, 215), item = "staff" },
	bastet = { head = "cat", skin = rgb(40, 35, 35) },
	sobek = { head = "croc", skin = rgb(70, 120, 60) },
	heimdall = { item = "horn", robe = rgb(220, 200, 120) },
	eos = { robe = rgb(255, 170, 120), item = "torch", hat = "sundisk" },
	selene = { robe = rgb(190, 205, 240), hat = "moon", hair = rgb(230, 230, 245) },
	bragi = { item = "lyre", beard = true, hair = rgb(235, 235, 235) },
	khonsu = { hat = "moon", robe = rgb(200, 210, 240) },
	brigid = { item = "torch", hair = rgb(220, 70, 30) },
	xochiquetzal = { robe = rgb(255, 120, 170), hat = "flowers" },
	hermes = { hat = "winged", item = "caduceus", robe = rgb(230, 240, 255) },
	artemisa = { item = "bow", hat = "moon", robe = rgb(70, 140, 80) },
	apolo = { item = "lyre", hat = "sundisk", hair = rgb(240, 200, 80) },
	horus = { head = "falcon", hat = "crown" },
	freya = { hair = rgb(250, 220, 120), item = "orb", robe = rgb(220, 120, 160), hat = "wingedhelmet" },
	tyr = { item = "sword", robe = rgb(120, 40, 40) },
	cernunnos = { hat = "antlers", robe = rgb(90, 70, 45) },
	tlaloc = { robe = rgb(40, 110, 200), item = "staff" },
	shamash = { hat = "sundisk", item = "scales" },
	atenea = { hat = "crest", item = "spear", trim = rgb(230, 190, 60), shield = true },
	ares = { hat = "crest", item = "sword", robe = rgb(170, 30, 30), shield = true },
	hefesto = { item = "hammer", robe = rgb(110, 75, 45), beard = true, hat = "none" },
	anubis = { head = "jackal", skin = rgb(25, 25, 30), item = "staff" },
	isis = { wings = rgb(60, 140, 220), hat = "sundisk" },
	loki = { hat = "horns", robe = rgb(40, 120, 60), item = "sword", hair = rgb(20, 30, 20), beard = false },
	quetzalcoatl = { wings = rgb(60, 200, 120), robe = rgb(30, 160, 90) },
	morrigan = { robe = rgb(25, 25, 30), wings = rgb(20, 20, 25), item = "spear", hair = rgb(10, 10, 10) },
	ishtar = { hat = "star", robe = rgb(240, 200, 80), wings = rgb(240, 200, 120) },
	poseidon = { item = "trident", robe = rgb(40, 120, 200), beard = true, hat = "crown" },
	hades = { robe = rgb(25, 22, 35), hat = "darkcrown", item = "staff", glowColor = rgb(80, 160, 255) },
	hera = { hat = "crown", robe = rgb(140, 60, 170), item = "staff" },
	ra = { head = "falcon", hat = "sundisk", item = "staff" },
	thor = { item = "hammer", hair = rgb(200, 80, 30), beard = true, hat = "wingedhelmet", robe = rgb(160, 40, 40) },
	huitzilopochtli = { robe = rgb(40, 90, 210), item = "sword", hat = "feathers" },
	dagda = { item = "hammer", beard = true, robe = rgb(80, 100, 50) },
	enki = { robe = rgb(40, 150, 210), beard = true },
	odin = { hat = "widehat", beard = true, hair = rgb(230, 230, 230), robe = rgb(90, 90, 100), item = "spear", eyepatch = true },
	osiris = { skin = rgb(70, 140, 80), hat = "atef", item = "staff" },
	cronos = { item = "scythe", beard = true, hair = rgb(220, 220, 220), robe = rgb(70, 60, 50) },
	tiamat = { head = "dragon", wings = rgb(30, 140, 140), skin = rgb(40, 150, 150), robe = rgb(20, 90, 100) },
	tezcatlipoca = { robe = rgb(20, 20, 25), item = "orb", stripe = true },
	hiperion = { glowColor = rgb(255, 210, 90), hat = "sundisk", robe = rgb(255, 230, 160) },
	atlas = { item = "globe", beard = true, robe = rgb(160, 120, 80) },
	set = { head = "jackal", skin = rgb(170, 50, 40), item = "staff" },
	marduk = { item = "sword", wings = rgb(220, 180, 80) },
	danu = { robe = rgb(20, 90, 60), item = "orb", glowColor = rgb(120, 255, 170) },
	urano = { robe = rgb(30, 50, 140), stars = true, glowColor = rgb(120, 170, 255), beard = true },
	nut = { skin = rgb(40, 60, 160), robe = rgb(20, 30, 90), stars = true },
	ymir = { skin = rgb(170, 210, 240), beard = true, hair = rgb(240, 250, 255), robe = rgb(120, 160, 200), scale = 1.25, hat = "none" },
	gaia = { robe = rgb(70, 140, 60), hat = "flowers", item = "globe" },
	erebo = { robe = rgb(15, 10, 25), glowColor = rgb(150, 80, 255), hat = "none" },
	nun = { robe = rgb(30, 120, 170), glowColor = rgb(90, 200, 255) },
	zeus = { item = "bolt", beard = true, hair = rgb(240, 240, 240), hat = "crown", glowColor = rgb(255, 240, 120) },
	nyx = { robe = rgb(20, 12, 40), wings = rgb(40, 20, 80), stars = true, glowColor = rgb(170, 110, 255), hat = "moon" },
	prometeo = { item = "torch", robe = rgb(200, 90, 40) },
	caos = { glowColor = rgb(255, 60, 200), stars = true, hat = "halo" },
	fanes = { wings = rgb(255, 230, 140), glowColor = rgb(255, 230, 140), hat = "halo" },
	atum = { hat = "atef", glowColor = rgb(255, 200, 80), skin = rgb(220, 170, 60) },
	ananke = { item = "orb", glowColor = rgb(255, 255, 255), stars = true },
	ometeotl = { wings = rgb(255, 255, 255), glowColor = rgb(255, 255, 255), hat = "feathers" },
	ouroboros = { head = "serpent", item = "ring", glowColor = rgb(140, 100, 255), stars = true },
	unknown = { silhouette = true },
	-- Guardianes (avatares gigantes)
	g_minotaur = { head = "bull", skin = rgb(115, 64, 38), chest = rgb(115, 64, 38), legs = rgb(115, 64, 38), robe = rgb(130, 40, 35), trim = rgb(220, 170, 60), item = "axe", hat = "none", bulk = 1.4, eyes = rgb(255, 60, 40) },
	g_dullahan = { head = "none", skin = rgb(40, 45, 55), chest = rgb(70, 75, 90), legs = rgb(35, 38, 48), robe = rgb(25, 25, 32), trim = rgb(90, 255, 140), item = "scythe", hat = "none", glowColor = rgb(110, 255, 140), wings = rgb(20, 20, 28) },
	g_sphinx = { head = "lion", skin = rgb(215, 170, 95), chest = rgb(215, 170, 95), legs = rgb(215, 170, 95), robe = rgb(40, 80, 190), trim = rgb(245, 195, 50), hair = rgb(150, 95, 40), hat = "nemes", item = "staff", eyes = rgb(80, 220, 255) },
	g_jaguar = { head = "cat", skin = rgb(235, 165, 45), chest = rgb(235, 165, 45), legs = rgb(235, 165, 45), robe = rgb(30, 150, 130), trim = rgb(210, 50, 40), hat = "feathers", item = "sword", eyes = rgb(120, 255, 120) },
	g_lamassu = { skin = rgb(195, 145, 105), chest = rgb(40, 70, 165), legs = rgb(40, 70, 165), robe = rgb(40, 70, 165), trim = rgb(245, 195, 70), hat = "tallcrown", beard = true, hair = rgb(30, 22, 18), wings = rgb(240, 210, 140), item = "spear" },
	g_fenrir = { head = "wolf", skin = rgb(95, 100, 115), chest = rgb(95, 100, 115), legs = rgb(95, 100, 115), robe = rgb(60, 62, 75), trim = rgb(180, 185, 200), hat = "none", eyes = rgb(120, 220, 255), glowColor = rgb(120, 220, 255) },
	-- Vendedores (dioses místicos junto a la entrada del pasillo)
	v_hecate = { skin = rgb(228, 216, 238), robe = rgb(92, 46, 158), legs = rgb(60, 32, 110), trim = rgb(208, 210, 236), trim2 = rgb(176, 112, 255), hair = rgb(20, 14, 30), hat = "lunar", item = "moonstaff", glowColor = rgb(196, 120, 255), stars = true },
	v_quiron = { skin = rgb(198, 142, 98), robe = rgb(44, 112, 64), legs = rgb(124, 82, 48), trim = rgb(218, 168, 72), hair = rgb(96, 60, 34), beard = true, hat = "laurel", item = "longbow", shield = true },
}

local function mk(model, name, size, cf, color, material, shape)
	local p = Instance.new("Part")
	p.Name = name
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CastShadow = true
	p.Size = size
	if shape then
		p.Shape = shape
	end
	p.CFrame = cf
	p.Color = color
	p.Material = material or Enum.Material.SmoothPlastic
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.Parent = model
	return p
end

local function lookFor(god)
	return GodModel._lookFor(god)
end
function GodModel._lookFor(god)
	local base = MYTH_STYLE[god.myth] or MYTH_STYLE.greek
	local look = {}
	for k, v in pairs(base) do
		look[k] = v
	end
	for k, v in pairs(LOOKS[god.id] or {}) do
		look[k] = v
	end
	return look
end

local templates = nil
local function template(id)
	if templates == nil then
		templates = game:GetService("ReplicatedStorage"):FindFirstChild("GodTemplates") or false
	end
	return templates and templates:FindFirstChild(id) or nil
end
GodModel.template = template

-- Animación de caminar/correr: balancea brazos y piernas alrededor de sus articulaciones
local rest = setmetatable({}, { __mode = "k" })
function GodModel.animate(model, phase, amp)
	if not model:GetAttribute("Animated") then
		return
	end
	local pivot = model:GetPivot()
	local cache = rest[model]
	if not cache then
		cache = {}
		local scale = model:GetScale()
		for _, name in ipairs({ "LegL", "LegR", "ArmL", "ArmR" }) do
			local p = model:FindFirstChild(name)
			if p and p:GetAttribute("Joint") then
				cache[name] = { part = p, rest = pivot:ToObjectSpace(p.CFrame), joint = p:GetAttribute("Joint") * scale }
			end
		end
		rest[model] = cache
	end
	local s = math.sin(phase) * amp
	local angles = { LegL = s, LegR = -s, ArmL = -s * 0.8, ArmR = s * 0.5 }
	for name, c in pairs(cache) do
		local j = CFrame.new(c.joint)
		c.part.CFrame = pivot * j * CFrame.Angles(angles[name], 0, 0) * j:Inverse() * c.rest
	end
end

GodModel.look = function(god)
	return lookFor(god)
end
GodModel.avatarBuilder = nil -- lo pone el servidor (Avatars.luau)

-- Devuelve el modelo del dios: avatar de Roblox si existe, si no, figura de piezas
function GodModel.build(god, rarityColor)
	local RS = game:GetService("ReplicatedStorage")
	local folder = RS:FindFirstChild("AvatarTemplates")
	local t = folder and folder:FindFirstChild(god.id)
	if not t and GodModel.avatarBuilder then
		t = GodModel.avatarBuilder(god)
	end
	if t then
		local m = t:Clone()
		m.Name = god.id
		return m
	end
	return GodModel.buildParts(god, rarityColor)
end

-- Figura hecha con piezas (fuente de los accesorios de los avatares)
function GodModel.buildParts(god, rarityColor)
	local L = lookFor(god)
	local S = L.scale or 1
	local m = Instance.new("Model")
	m.Name = god.id
	local O = CFrame.new()
	local function at(x, y, z)
		return O * CFrame.new(x * S, y * S, z * S)
	end
	local function v(x, y, z)
		return Vector3.new(x, y, z) * S
	end
	local silhouette = L.silhouette
	local function col(c)
		return silhouette and rgb(8, 8, 12) or c
	end
	local fabric = Enum.Material.Fabric
	local gold = Enum.Material.Foil

	local root = mk(m, "Root", v(2.4, 0.2, 1.6), at(0, 0.1, 0), col(L.trim), gold)
	root.Transparency = 1
	-- piernas y túnica
	mk(m, "LegL", v(0.8, 2.2, 0.8), at(-0.5, 1.1, 0), col(L.skin))
	mk(m, "LegR", v(0.8, 2.2, 0.8), at(0.5, 1.1, 0), col(L.skin))
	mk(m, "Skirt", v(2.2, 1.6, 1.3), at(0, 1.9, 0), col(L.robe), fabric)
	mk(m, "Torso", v(2.1, 2, 1.1), at(0, 3.6, 0), col(L.robe), fabric)
	mk(m, "Belt", v(2.2, 0.35, 1.2), at(0, 2.75, 0), col(L.trim), gold)
	mk(m, "Sash", v(0.4, 2.1, 1.15), at(0.45, 3.6, 0) * CFrame.Angles(0, 0, math.rad(-28)), col(L.trim2 or L.trim), gold)
	mk(m, "ArmL", v(0.75, 2, 0.75), at(-1.45, 3.5, 0), col(L.skin))
	local armR = mk(m, "ArmR", v(0.75, 2, 0.75), at(1.45, 3.75, -0.35) * CFrame.Angles(math.rad(35), 0, 0), col(L.skin))
	-- cabeza
	local headY = 5.25
	if L.head == nil or L.head == "goat" then
		local head = mk(m, "Head", v(1.25, 1.25, 1.25), at(0, headY, 0), col(L.skin))
		local mesh = Instance.new("SpecialMesh")
		mesh.MeshType = Enum.MeshType.Head
		mesh.Scale = Vector3.new(1.25, 1.25, 1.25)
		mesh.Parent = head
		if not silhouette then
			local face = Instance.new("Decal")
			face.Texture = "rbxasset://textures/face.png"
			face.Face = Enum.NormalId.Front
			face.Parent = head
		end
		mk(m, "Hair", v(1.35, 0.5, 1.35), at(0, headY + 0.55, 0.05), col(L.hair))
		mk(m, "HairBack", v(1.35, 1.1, 0.4), at(0, headY + 0.05, 0.55), col(L.hair))
		if L.beard then
			mk(m, "Beard", v(1.1, 0.9, 0.5), at(0, headY - 0.55, -0.45), col(L.hair))
		end
		if L.eyepatch then
			mk(m, "Patch", v(0.35, 0.3, 0.1), at(-0.25, headY + 0.1, -0.66), rgb(15, 15, 15))
		end
		if L.stripe then
			mk(m, "Stripe", v(1.3, 0.25, 0.1), at(0, headY + 0.05, -0.64), rgb(240, 200, 50))
		end
		if L.head == "goat" then
			mk(m, "HornL", v(0.25, 0.8, 0.25), at(-0.4, headY + 0.85, 0) * CFrame.Angles(0, 0, math.rad(20)), rgb(230, 220, 200))
			mk(m, "HornR", v(0.25, 0.8, 0.25), at(0.4, headY + 0.85, 0) * CFrame.Angles(0, 0, math.rad(-20)), rgb(230, 220, 200))
		end
	else
		-- cabezas de animal
		local hc = col(L.skin)
		if L.head == "none" then
			local f = mk(m, "FlameHead", v(1.2, 1.2, 1.2), at(0, headY, 0), L.glowColor or rgb(120, 255, 140), Enum.Material.Neon, Enum.PartType.Ball)
			local fire = Instance.new("Fire")
			fire.Color = L.glowColor or rgb(120, 255, 140)
			fire.SecondaryColor = rgb(20, 80, 30)
			fire.Size = 4
			fire.Parent = f
		else
			mk(m, "Head", v(1.3, 1.3, 1.3), at(0, headY, 0), hc)
			mk(m, "EyeL", v(0.2, 0.2, 0.1), at(-0.32, headY + 0.15, -0.66), L.eyes or rgb(255, 230, 90), Enum.Material.Neon)
			mk(m, "EyeR", v(0.2, 0.2, 0.1), at(0.32, headY + 0.15, -0.66), L.eyes or rgb(255, 230, 90), Enum.Material.Neon)
		end
		if L.head == "bull" then
			mk(m, "Snout", v(0.95, 0.65, 0.6), at(0, headY - 0.3, -0.8), rgb(160, 110, 90))
			mk(m, "NoseRing", v(0.5, 0.08, 0.5), at(0, headY - 0.55, -1.05), rgb(240, 200, 70), Enum.Material.Neon)
			mk(m, "HornL", v(1.1, 0.25, 0.25), at(-0.95, headY + 0.6, 0) * CFrame.Angles(0, 0, math.rad(-35)), rgb(240, 230, 210))
			mk(m, "HornR", v(1.1, 0.25, 0.25), at(0.95, headY + 0.6, 0) * CFrame.Angles(0, 0, math.rad(35)), rgb(240, 230, 210))
			mk(m, "HornTipL", v(0.2, 0.6, 0.2), at(-1.4, headY + 1.05, 0), rgb(240, 230, 210))
			mk(m, "HornTipR", v(0.2, 0.6, 0.2), at(1.4, headY + 1.05, 0), rgb(240, 230, 210))
		elseif L.head == "wolf" then
			mk(m, "Snout", v(0.6, 0.5, 1.2), at(0, headY - 0.25, -1.0), hc)
			mk(m, "Nose", v(0.25, 0.2, 0.15), at(0, headY - 0.1, -1.6), rgb(20, 20, 20))
			mk(m, "EarL", v(0.35, 0.8, 0.2), at(-0.42, headY + 0.85, 0.1) * CFrame.Angles(0, 0, math.rad(12)), hc)
			mk(m, "EarR", v(0.35, 0.8, 0.2), at(0.42, headY + 0.85, 0.1) * CFrame.Angles(0, 0, math.rad(-12)), hc)
			mk(m, "Fangs", v(0.5, 0.15, 0.2), at(0, headY - 0.55, -1.3), rgb(250, 250, 240))
		elseif L.head == "lion" then
			mk(m, "Snout", v(0.7, 0.45, 0.4), at(0, headY - 0.25, -0.75), rgb(235, 200, 140))
			for k = 0, 9 do
				local a = k / 10 * math.pi * 2
				mk(m, "Mane", v(0.6, 0.6, 0.6), at(math.cos(a) * 0.85, headY + math.sin(a) * 0.85, 0.25), L.hair or rgb(150, 90, 40), Enum.Material.Fabric, Enum.PartType.Ball)
			end
		end
		if L.head == "cat" then
			mk(m, "Snout", v(0.6, 0.4, 0.35), at(0, headY - 0.25, -0.75), hc)
			mk(m, "EarL", v(0.35, 0.6, 0.2), at(-0.42, headY + 0.85, 0), hc)
			mk(m, "EarR", v(0.35, 0.6, 0.2), at(0.42, headY + 0.85, 0), hc)
		elseif L.head == "jackal" then
			mk(m, "Snout", v(0.55, 0.45, 1.1), at(0, headY - 0.2, -1.05), hc)
			mk(m, "EarL", v(0.3, 1.1, 0.2), at(-0.38, headY + 1.1, 0.1), hc)
			mk(m, "EarR", v(0.3, 1.1, 0.2), at(0.38, headY + 1.1, 0.1), hc)
		elseif L.head == "falcon" then
			mk(m, "Beak", v(0.45, 0.5, 0.7), at(0, headY - 0.15, -0.9) * CFrame.Angles(math.rad(25), 0, 0), rgb(240, 190, 60))
			mk(m, "Mask", v(1.32, 0.35, 1.32), at(0, headY + 0.1, 0), rgb(30, 60, 140))
		elseif L.head == "croc" then
			mk(m, "Snout", v(0.75, 0.45, 1.6), at(0, headY - 0.25, -1.3), hc)
			mk(m, "Teeth", v(0.8, 0.12, 1.5), at(0, headY - 0.45, -1.3), rgb(250, 250, 240))
		elseif L.head == "dragon" or L.head == "serpent" then
			mk(m, "Snout", v(0.8, 0.5, 1.2), at(0, headY - 0.2, -1.1), hc)
			mk(m, "HornL", v(0.2, 0.9, 0.2), at(-0.4, headY + 0.9, 0.2) * CFrame.Angles(math.rad(-25), 0, 0), rgb(240, 230, 210))
			mk(m, "HornR", v(0.2, 0.9, 0.2), at(0.4, headY + 0.9, 0.2) * CFrame.Angles(math.rad(-25), 0, 0), rgb(240, 230, 210))
		end
	end
	-- tocados
	local hy = headY + 0.85
	local hat = L.hat
	if hat == "laurel" then
		mk(m, "Laurel", v(1.45, 0.25, 1.45), at(0, hy - 0.1, 0), rgb(110, 170, 70), Enum.Material.Grass)
	elseif hat == "nemes" then
		mk(m, "Nemes", v(1.5, 0.9, 1.5), at(0, hy - 0.4, 0.05), col(L.trim2 or rgb(40, 80, 190)), fabric)
		mk(m, "NemesStripe", v(1.55, 0.2, 1.55), at(0, hy - 0.2, 0.05), col(L.trim), gold)
	elseif hat == "helmet" or hat == "wingedhelmet" then
		mk(m, "Helmet", v(1.45, 0.7, 1.45), at(0, hy - 0.15, 0), rgb(160, 165, 175), Enum.Material.Metal)
		if hat == "wingedhelmet" then
			mk(m, "WingL", v(0.15, 0.7, 0.9), at(-0.85, hy + 0.2, 0) * CFrame.Angles(0, 0, math.rad(25)), rgb(245, 245, 245))
			mk(m, "WingR", v(0.15, 0.7, 0.9), at(0.85, hy + 0.2, 0) * CFrame.Angles(0, 0, math.rad(-25)), rgb(245, 245, 245))
		end
	elseif hat == "feathers" then
		for k = -2, 2 do
			mk(m, "Feather", v(0.25, 1.4, 0.12), at(k * 0.3, hy + 0.5, 0.2) * CFrame.Angles(0, 0, math.rad(-k * 12)), k % 2 == 0 and rgb(40, 190, 120) or rgb(230, 60, 50))
		end
	elseif hat == "tallcrown" then
		mk(m, "Crown", v(1.2, 1.2, 1.2), at(0, hy + 0.35, 0), col(L.trim), gold, Enum.PartType.Cylinder).CFrame = at(0, hy + 0.35, 0) * CFrame.Angles(0, 0, math.rad(90))
	elseif hat == "torc" then
		mk(m, "Torc", v(1.3, 0.2, 1.3), at(0, headY - 0.75, 0), col(L.trim), gold)
	elseif hat == "crown" or hat == "darkcrown" then
		local cc = hat == "darkcrown" and rgb(40, 40, 60) or rgb(255, 210, 60)
		mk(m, "Crown", v(1.4, 0.45, 1.4), at(0, hy, 0), cc, hat == "darkcrown" and Enum.Material.Metal or Enum.Material.Neon)
		for k = -1, 1 do
			mk(m, "Spike", v(0.25, 0.5, 0.25), at(k * 0.45, hy + 0.4, -0.55), cc, Enum.Material.Neon)
		end
	elseif hat == "sundisk" then
		mk(m, "Sun", v(0.25, 1.4, 1.4), at(0, hy + 0.7, 0.2), rgb(255, 180, 40), Enum.Material.Neon, Enum.PartType.Cylinder).CFrame = at(0, hy + 0.7, 0.2) * CFrame.Angles(0, math.rad(90), 0)
	elseif hat == "moon" then
		mk(m, "Moon", v(0.2, 1.1, 1.1), at(0, hy + 0.55, 0.2), rgb(220, 230, 255), Enum.Material.Neon, Enum.PartType.Cylinder).CFrame = at(0, hy + 0.55, 0.2) * CFrame.Angles(0, math.rad(90), 0)
	elseif hat == "winged" then
		mk(m, "Petasos", v(1.6, 0.3, 1.6), at(0, hy - 0.05, 0), rgb(200, 180, 140))
		mk(m, "WingL", v(0.1, 0.5, 0.7), at(-0.85, hy + 0.15, 0) * CFrame.Angles(0, 0, math.rad(30)), rgb(255, 255, 255))
		mk(m, "WingR", v(0.1, 0.5, 0.7), at(0.85, hy + 0.15, 0) * CFrame.Angles(0, 0, math.rad(-30)), rgb(255, 255, 255))
	elseif hat == "antlers" then
		for _, sx in ipairs({ -1, 1 }) do
			mk(m, "Antler", v(0.2, 1.4, 0.2), at(sx * 0.45, hy + 0.5, 0) * CFrame.Angles(0, 0, math.rad(-sx * 30)), rgb(200, 170, 120))
			mk(m, "Tine", v(0.15, 0.6, 0.15), at(sx * 0.8, hy + 0.7, 0) * CFrame.Angles(0, 0, math.rad(sx * 20)), rgb(200, 170, 120))
		end
	elseif hat == "flowers" then
		for k = 0, 5 do
			local a = k / 6 * math.pi * 2
			mk(m, "Flower", v(0.3, 0.3, 0.3), at(math.cos(a) * 0.62, hy - 0.05, math.sin(a) * 0.62), k % 2 == 0 and rgb(255, 120, 170) or rgb(255, 230, 90), Enum.Material.Neon, Enum.PartType.Ball)
		end
	elseif hat == "crest" then
		mk(m, "Helmet", v(1.45, 0.7, 1.45), at(0, hy - 0.15, 0), rgb(220, 190, 80), Enum.Material.Metal)
		mk(m, "Crest", v(0.2, 0.7, 1.5), at(0, hy + 0.45, 0.1), rgb(200, 30, 30), fabric)
	elseif hat == "horns" then
		mk(m, "HornL", v(0.2, 1, 0.2), at(-0.5, hy + 0.3, 0) * CFrame.Angles(0, 0, math.rad(25)), rgb(220, 190, 60), gold)
		mk(m, "HornR", v(0.2, 1, 0.2), at(0.5, hy + 0.3, 0) * CFrame.Angles(0, 0, math.rad(-25)), rgb(220, 190, 60), gold)
	elseif hat == "star" then
		mk(m, "Star", v(0.9, 0.9, 0.2), at(0, hy + 0.5, 0) * CFrame.Angles(0, 0, math.rad(45)), rgb(255, 230, 100), Enum.Material.Neon)
	elseif hat == "atef" then
		mk(m, "Atef", v(0.8, 1.4, 0.8), at(0, hy + 0.5, 0), rgb(245, 245, 235))
		mk(m, "FeatherL", v(0.15, 1.3, 0.4), at(-0.5, hy + 0.5, 0), rgb(240, 190, 60), gold)
		mk(m, "FeatherR", v(0.15, 1.3, 0.4), at(0.5, hy + 0.5, 0), rgb(240, 190, 60), gold)
	elseif hat == "widehat" then
		mk(m, "Brim", v(2.1, 0.15, 2.1), at(0, hy - 0.1, 0), rgb(60, 60, 70), fabric)
		mk(m, "Cap", v(1.2, 0.7, 1.2), at(0, hy + 0.25, 0), rgb(60, 60, 70), fabric)
	elseif hat == "halo" then
		mk(m, "Halo", v(0.15, 1.8, 1.8), at(0, hy + 0.4, 0.5), L.glowColor or rgb(255, 230, 140), Enum.Material.Neon, Enum.PartType.Cylinder).CFrame = at(0, hy + 0.4, 0.5) * CFrame.Angles(0, math.rad(90), 0)
	elseif hat == "lunar" then
		-- diadema lunar (Hécate): aro oscuro, media luna con los cuernos hacia arriba y velo por la espalda
		mk(m, "Crown", v(1.42, 0.28, 1.42), at(0, hy - 0.12, 0), rgb(48, 36, 84), Enum.Material.Metal)
		local moon = rgb(232, 224, 255)
		for k = -2, 2 do
			local a = math.rad(k * 45)
			local thick = 0.36 - math.abs(k) * 0.1
			mk(m, "Crescent", v(0.52, thick, 0.18), at(math.sin(a) * 0.62, hy + 0.8 - math.cos(a) * 0.62, 0.1) * CFrame.Angles(0, 0, a), moon, Enum.Material.Neon)
		end
		mk(m, "Veil", v(1.5, 2.3, 0.18), at(0, headY - 0.75, 0.74), col(L.robe), fabric)
	end
	-- alas
	if L.wings then
		for _, sx in ipairs({ -1, 1 }) do
			mk(m, "Wing", v(0.15, 3.2, 2.2), at(sx * 1.4, 4.2, 0.9) * CFrame.Angles(math.rad(-15), math.rad(sx * 35), math.rad(sx * 20)), col(L.wings), Enum.Material.Neon).Transparency = 0.15
		end
	end
	if L.shield then
		mk(m, "Shield", v(0.2, 1.8, 1.8), at(-1.75, 3.4, -0.2), rgb(230, 190, 60), Enum.Material.Metal, Enum.PartType.Cylinder).CFrame = at(-1.75, 3.4, -0.2) * CFrame.Angles(0, 0, 0)
	end
	if L.stars and not silhouette then
		for k = 1, 8 do
			mk(m, "Star", v(0.15, 0.15, 0.05), at(-0.8 + (k * 37 % 16) / 10, 1.2 + (k * 53 % 30) / 10, -0.68), rgb(255, 255, 230), Enum.Material.Neon)
		end
	end
	-- objeto en la mano derecha
	local hand = armR.CFrame * CFrame.new(0, -1.05 * S, 0)
	local item = L.item
	local function itemPart(name, size, offsetCf, color, mat, shape)
		return mk(m, name, size * S, hand * offsetCf, color, mat, shape)
	end
	if item == "trident" then
		itemPart("Shaft", Vector3.new(0.2, 5, 0.2), CFrame.new(0, 1.4, 0), rgb(220, 190, 70), gold)
		for k = -1, 1 do
			itemPart("Prong", Vector3.new(0.15, 0.9, 0.15), CFrame.new(k * 0.35, 4.2, 0), rgb(120, 220, 255), Enum.Material.Neon)
		end
		itemPart("Bar", Vector3.new(0.9, 0.15, 0.15), CFrame.new(0, 3.75, 0), rgb(220, 190, 70), gold)
	elseif item == "hammer" then
		itemPart("Handle", Vector3.new(0.25, 1.6, 0.25), CFrame.new(0, 0.4, 0), rgb(110, 70, 40), Enum.Material.Wood)
		itemPart("HammerHead", Vector3.new(1.2, 0.8, 0.8), CFrame.new(0, 1.3, 0), rgb(170, 175, 190), Enum.Material.Metal)
	elseif item == "bolt" then
		itemPart("Bolt1", Vector3.new(0.3, 1.4, 0.2), CFrame.new(0, 1, 0) * CFrame.Angles(0, 0, math.rad(20)), rgb(255, 240, 90), Enum.Material.Neon)
		itemPart("Bolt2", Vector3.new(0.3, 1.4, 0.2), CFrame.new(0.3, 2.1, 0) * CFrame.Angles(0, 0, math.rad(-20)), rgb(255, 240, 90), Enum.Material.Neon)
	elseif item == "sword" then
		itemPart("Blade", Vector3.new(0.25, 2.6, 0.1), CFrame.new(0, 1.6, 0), rgb(220, 225, 235), Enum.Material.Metal)
		itemPart("Guard", Vector3.new(0.9, 0.15, 0.2), CFrame.new(0, 0.3, 0), rgb(220, 180, 60), gold)
	elseif item == "spear" or item == "staff" or item == "caduceus" then
		itemPart("Shaft", Vector3.new(0.18, 4.6, 0.18), CFrame.new(0, 1.2, 0), item == "staff" and rgb(230, 190, 70) or rgb(120, 85, 50), item == "staff" and gold or Enum.Material.Wood)
		if item == "spear" then
			itemPart("Tip", Vector3.new(0.3, 0.7, 0.1), CFrame.new(0, 3.8, 0), rgb(220, 225, 235), Enum.Material.Metal)
		elseif item == "caduceus" then
			itemPart("Wings", Vector3.new(1, 0.25, 0.1), CFrame.new(0, 3.5, 0), rgb(255, 255, 255))
		else
			itemPart("Gem", Vector3.new(0.5, 0.5, 0.5), CFrame.new(0, 3.65, 0), L.glowColor or rgb(120, 220, 255), Enum.Material.Neon, Enum.PartType.Ball)
		end
	elseif item == "bow" then
		itemPart("Bow", Vector3.new(0.15, 3, 0.15), CFrame.new(0, 0.9, -0.3), rgb(150, 100, 50), Enum.Material.Wood)
		itemPart("String", Vector3.new(0.04, 2.8, 0.04), CFrame.new(0, 0.9, 0), rgb(255, 255, 255))
	elseif item == "lyre" then
		itemPart("Lyre", Vector3.new(0.9, 1.1, 0.15), CFrame.new(0, 0.5, -0.2), rgb(230, 190, 70), gold)
	elseif item == "torch" then
		itemPart("Stick", Vector3.new(0.25, 1.4, 0.25), CFrame.new(0, 0.4, 0), rgb(110, 70, 40), Enum.Material.Wood)
		local fire = itemPart("Flame", Vector3.new(0.6, 0.6, 0.6), CFrame.new(0, 1.3, 0), rgb(255, 140, 30), Enum.Material.Neon, Enum.PartType.Ball)
		local f = Instance.new("Fire")
		f.Size = 2
		f.Heat = 4
		f.Parent = fire
	elseif item == "orb" or item == "globe" or item == "cloud" then
		local size = item == "globe" and 1.8 or 0.9
		local off = item == "globe" and CFrame.new(-1.2, 3.2, 0.3) or CFrame.new(0, 0.6, -0.2)
		local c = item == "globe" and rgb(60, 140, 210) or (item == "cloud" and rgb(240, 245, 255) or (L.glowColor or rgb(170, 120, 255)))
		itemPart("Orb", Vector3.new(size, size, size), off, c, item == "globe" and Enum.Material.SmoothPlastic or Enum.Material.Neon, Enum.PartType.Ball)
	elseif item == "axe" then
		itemPart("Shaft", Vector3.new(0.25, 4.6, 0.25), CFrame.new(0, 1.2, 0), rgb(90, 60, 40), Enum.Material.Wood)
		itemPart("AxeBlade", Vector3.new(2.2, 1.5, 0.2), CFrame.new(0, 3.2, 0), rgb(185, 190, 200), Enum.Material.Metal)
		itemPart("AxeEdge", Vector3.new(2.4, 0.2, 0.25), CFrame.new(0, 3.95, 0), rgb(235, 240, 250), Enum.Material.Metal)
	elseif item == "scythe" then
		itemPart("Shaft", Vector3.new(0.18, 4.4, 0.18), CFrame.new(0, 1.2, 0), rgb(90, 70, 50), Enum.Material.Wood)
		itemPart("Blade", Vector3.new(1.8, 0.25, 0.1), CFrame.new(-0.8, 3.3, 0) * CFrame.Angles(0, 0, math.rad(-15)), rgb(200, 205, 215), Enum.Material.Metal)
	elseif item == "scales" then
		itemPart("Beam", Vector3.new(1.4, 0.12, 0.12), CFrame.new(0, 0.9, 0), rgb(230, 190, 70), gold)
		itemPart("PanL", Vector3.new(0.5, 0.1, 0.5), CFrame.new(-0.6, 0.5, 0), rgb(230, 190, 70), gold)
		itemPart("PanR", Vector3.new(0.5, 0.1, 0.5), CFrame.new(0.6, 0.5, 0), rgb(230, 190, 70), gold)
	elseif item == "horn" then
		itemPart("Horn", Vector3.new(0.35, 1.3, 0.35), CFrame.new(0, 0.6, -0.2) * CFrame.Angles(math.rad(50), 0, 0), rgb(240, 220, 170))
	elseif item == "pipes" then
		for k = 0, 3 do
			itemPart("Pipe", Vector3.new(0.15, 0.9 - k * 0.15, 0.15), CFrame.new(k * 0.18, 0.5, -0.2), rgb(200, 160, 90), Enum.Material.Wood)
		end
	elseif item == "ring" then
		itemPart("Ring", Vector3.new(0.25, 1.6, 1.6), CFrame.new(0, 1, -0.3), L.glowColor or rgb(140, 100, 255), Enum.Material.Neon, Enum.PartType.Cylinder)
	elseif item == "moonstaff" then
		-- báculo de Hécate, vertical y apoyado en el suelo: asta oscura, orbe brillante y media luna que lo abraza
		local grip = CFrame.Angles(math.rad(-35), 0, 0) * CFrame.new(0, 0, -0.62) -- deshace la inclinación del brazo; delante del puño
		local moon = rgb(232, 224, 255)
		itemPart("Shaft", Vector3.new(0.2, 6.4, 0.2), grip * CFrame.new(0, 0.5, 0), rgb(74, 62, 108), Enum.Material.Metal)
		itemPart("Gem", Vector3.new(0.6, 0.6, 0.6), grip * CFrame.new(0, 4.3, 0), L.glowColor or rgb(196, 120, 255), Enum.Material.Neon, Enum.PartType.Ball)
		itemPart("Prong", Vector3.new(0.8, 0.18, 0.18), grip * CFrame.new(0, 3.82, 0), moon, Enum.Material.Neon)
		for _, sx in ipairs({ -1, 1 }) do
			itemPart("Prong", Vector3.new(0.18, 0.75, 0.18), grip * CFrame.new(sx * 0.5, 4.2, 0) * CFrame.Angles(0, 0, math.rad(sx * 18)), moon, Enum.Material.Neon)
		end
	elseif item == "longbow" then
		-- arco largo de Quirón, vertical delante del puño: empuñadura dorada, dos palas curvadas y la cuerda
		local grip = CFrame.Angles(math.rad(-35), 0, 0) * CFrame.new(0, 0, -0.62)
		local a = math.rad(16)
		itemPart("Bow", Vector3.new(0.24, 1, 0.24), grip, rgb(218, 168, 72), gold)
		for _, sy in ipairs({ -1, 1 }) do
			itemPart("Bow", Vector3.new(0.17, 1.9, 0.17), grip * CFrame.new(0.95 * math.sin(a), sy * (0.5 + 0.95 * math.cos(a)), 0) * CFrame.Angles(0, 0, -sy * a), rgb(140, 92, 48), Enum.Material.Wood)
		end
		itemPart("String", Vector3.new(0.05, 2 * (0.5 + 1.9 * math.cos(a)), 0.05), grip * CFrame.new(1.9 * math.sin(a), 0, 0), rgb(255, 255, 255))
	end
	-- brillo propio
	if L.glow or L.glowColor then
		local lightPart = m:FindFirstChild("Torso")
		local light = Instance.new("PointLight")
		light.Color = L.glowColor or rarityColor or rgb(200, 160, 255)
		light.Range = 10
		light.Brightness = 2
		light.Parent = lightPart
	end
	if silhouette then
		for _, p in ipairs(m:GetDescendants()) do
			if p:IsA("BasePart") then
				p.Color = rgb(8, 8, 12)
				p.Material = Enum.Material.SmoothPlastic
			end
		end
		local q = mk(m, "Question", v(0.2, 1.6, 1.2), at(0, 6.9, 0), rgb(200, 120, 255), Enum.Material.Neon)
		q.Transparency = 0.2
	end
	m.PrimaryPart = root
	return m
end

-- Efectos de rareza: contorno, anillo en los pies, aura, partículas y luz
function GodModel.decorate(model, rarity)
	local color = rarity.id == 10 and Color3.fromRGB(200, 120, 255) or rarity.color
	local root = model.PrimaryPart
	local torso = model:FindFirstChild("Torso") or model:FindFirstChild("Body") or model:FindFirstChild("UpperTorso")
	local feet = root and root.CFrame * CFrame.new(0, -(model:GetAttribute("PivotH") or 0), 0) or nil
	local VFX = require(script.Parent.Config).VFX
	-- Los dioses con avatar (ropa del catálogo) van sin Highlight: visto en Studio, el contorno
	-- dibujaba el borde de la placa invisible de runas (cuadrados planos en el suelo), el relleno
	-- apagaba los colores de la ropa y Roblox solo pinta ~31 Highlights a la vez (con varias
	-- parcelas llenas unos dioses lo tenían y otros no). La rareza se ve en el anillo, runas y partículas.
	if rarity.id >= 2 and not model:GetAttribute("Avatar") then
		local h = Instance.new("Highlight")
		h.FillColor = color
		h.FillTransparency = rarity.id >= 7 and 0.75 or 0.92
		h.OutlineColor = color
		h.OutlineTransparency = rarity.id >= 4 and 0 or 0.45
		h.DepthMode = Enum.HighlightDepthMode.Occluded
		h.Parent = model
	end
	-- círculo rúnico místico bajo los pies (Mítica o más)
	if root and rarity.id >= 6 then
		local disc = Instance.new("Part")
		disc.Name = "Runes"
		disc.Anchored = true
		disc.CanCollide = false
		disc.CanQuery = false
		disc.Transparency = 1
		disc.Size = Vector3.new(6, 0.1, 6)
		disc.CFrame = feet * CFrame.new(0, 0.02, 0)
		local dec = Instance.new("Decal")
		dec.Face = Enum.NormalId.Top
		dec.Texture = VFX.runes
		dec.Color3 = color
		dec.Transparency = 0.15
		dec.Parent = disc
		disc.Parent = model
	end
	-- anillo de luz en los pies
	if root then
		local ring = Instance.new("Part")
		ring.Name = "AuraRing"
		ring.Anchored = true
		ring.CanCollide = false
		ring.CanQuery = false
		ring.Shape = Enum.PartType.Cylinder
		ring.Material = Enum.Material.Neon
		ring.Color = color
		ring.Transparency = rarity.id >= 5 and 0.35 or 0.6
		ring.Size = Vector3.new(0.12, 3.4, 3.4)
		ring.CFrame = feet * CFrame.new(0, 0.03, 0) * CFrame.Angles(0, 0, math.rad(90))
		ring.Parent = model
	end
	if torso then
		local att = Instance.new("Attachment")
		att.Name = "AuraFX"
		att.Parent = torso
		-- chispas que suben
		local pe = Instance.new("ParticleEmitter")
		pe.Rate = 2 + rarity.id * 3
		pe.Lifetime = NumberRange.new(1, 2)
		pe.Speed = NumberRange.new(1, 3)
		pe.Acceleration = Vector3.new(0, 3, 0)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.LightEmission = 1
		pe.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.45 + rarity.id * 0.05), NumberSequenceKeypoint.new(1, 0) })
		pe.Texture = VFX.sparkle
		pe.RotSpeed = NumberRange.new(-90, 90)
		pe.Parent = att
		-- aura envolvente para las rarezas altas
		if rarity.id >= 5 then
			local aura = Instance.new("ParticleEmitter")
			aura.Rate = 6 + rarity.id
			aura.Lifetime = NumberRange.new(0.8, 1.2)
			aura.Speed = NumberRange.new(0.2, 0.6)
			aura.LightEmission = 0.8
			aura.LockedToPart = true
			aura.Color = ColorSequence.new(color)
			aura.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 3.2), NumberSequenceKeypoint.new(1, 4.4) })
			aura.Texture = VFX.glow
			aura.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.75), NumberSequenceKeypoint.new(1, 1) })
			aura.Parent = att
			local light = Instance.new("PointLight")
			light.Color = color
			light.Range = 8 + rarity.id
			light.Brightness = 1.5
			light.Parent = att
		end
		-- orbes que giran alrededor (Celestial o más)
		if rarity.id >= 8 then
			local orbs = Instance.new("ParticleEmitter")
			orbs.Name = "CelestialOrbs"
			orbs.Rate = 10
			orbs.Lifetime = NumberRange.new(1.5)
			orbs.Speed = NumberRange.new(4)
			orbs.RotSpeed = NumberRange.new(200)
			orbs.SpreadAngle = Vector2.new(10, 180)
			orbs.LightEmission = 1
			orbs.Color = ColorSequence.new(Color3.new(1, 1, 1), color)
			orbs.Size = NumberSequence.new(0.6, 0)
			orbs.Texture = VFX.sparkle
			orbs.Parent = att
		end
		-- Motas ascendentes y un halo de luz adicional para las rarezas divinas.
		if rarity.id >= 7 then
			local motes = Instance.new("ParticleEmitter")
			motes.Name = "DivineMotes"
			motes.Rate = 3 + rarity.id
			motes.Lifetime = NumberRange.new(1.4, 2.2)
			motes.Speed = NumberRange.new(1.5, 3.5)
			motes.Acceleration = Vector3.new(0, 4, 0)
			motes.SpreadAngle = Vector2.new(180, 180)
			motes.LightEmission = 1
			motes.Color = ColorSequence.new(color, Color3.new(1, 1, 1))
			motes.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.32), NumberSequenceKeypoint.new(1, 0) })
			motes.Transparency = NumberSequence.new(0.08, 1)
			motes.Texture = VFX.sparkle
			motes.Parent = att
		end
	end
end

return GodModel
