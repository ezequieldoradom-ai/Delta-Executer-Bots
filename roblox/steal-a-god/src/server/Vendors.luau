-- Vendedores: dos dioses místicos junto a la entrada del pasillo, cada uno en su templete redondo.
--   · Hécate, diosa de la magia, las antorchas, la luna y las encrucijadas → vende AURAS
--   · Quirón, el centauro que entrenó a Heracles, Aquiles, Perseo y Teseo → vende ENTRENADORES
-- Aquí solo se construye el escenario y se dejan etiquetas; el cliente hace el resto:
--   anima (FxSpin, FxBob, FxOrbit), traduce el cartel (etiqueta Loc + atributo Vendor) y abre el panel
--   al usar el ProximityPrompt (etiqueta VendorPrompt + atributo Vendor). Las compras van por "Action".
local CollectionService = game:GetService("CollectionService")

local Vendors = {}
local G

local rgb = Color3.fromRGB
local N = Enum.NormalId
local M = Enum.Material
local CYL = Enum.PartType.Cylinder
local BALL = Enum.PartType.Ball
local UP = CFrame.Angles(0, 0, math.rad(90)) -- pone de pie un cilindro (su eje es el X local)
local FACING = CFrame.Angles(0, math.rad(90), 0) -- disco de cilindro mirando al frente (eje a lo largo de Z)

Vendors.RADIUS = 8.5 -- todo lo sólido cabe en este radio alrededor del vendedor
Vendors.LOOK_AT = Vector3.new(0, 0, -62) -- los dos miran hacia el centro de la plaza, junto a los rankings
Vendors.shrines = {} -- [clave] = { folder, npc, prompt, sign, cf }
Vendors.errors = {} -- fallos al construir (el juego arranca igualmente)

-- Medidas comunes del templete (tholos)
local DAIS_TOP = 1.2 -- altura del último escalón: bajo, para subir andando
local COL_R = 6.6 -- radio del anillo de columnas
local COL_TOP = 17.4 -- donde acaba el capitel
local RING_H = 1.6
local RING_TOP = COL_TOP + RING_H
local NODE = math.rad(18) -- columnas y juntas del anillo en 18° + 36°·n
local RING_MID = COL_R * math.cos(NODE)
local BEACON_H = 70

local STYLES = {
	aura = {
		folder = "VendorAura", npc = "Hecate",
		god = { id = "v_hecate", myth = "greek", r = 0, name = "Hécate" },
		object = "Hecate", action = "Auras", sign = "✨ AURAS",
		scale = 2.2, standZ = 0.8, hover = 0.9, -- levita sobre el círculo de runas
		steps = { rgb(60, 44, 110), rgb(88, 64, 152), rgb(122, 94, 198) },
		floor = rgb(164, 136, 228),
		column = rgb(232, 226, 248),
		trim = rgb(212, 214, 240),
		ring = rgb(74, 48, 138),
		banner = rgb(106, 52, 184),
		glow = rgb(196, 120, 255), -- neón principal
		pale = rgb(234, 226, 255), -- neón claro (luna)
		flame = rgb(170, 70, 255),
		flameCore = rgb(236, 205, 255),
	},
	coach = {
		folder = "VendorCoach", npc = "Quiron",
		god = { id = "v_quiron", myth = "greek", r = 0, name = "Quirón" },
		object = "Chiron", action = "Coaches", sign = "🏋️ COACHES",
		scale = 2.2, standZ = -2.8,
		steps = { rgb(150, 108, 62), rgb(208, 178, 128), rgb(240, 226, 194) },
		floor = rgb(255, 246, 222),
		column = rgb(246, 238, 218),
		trim = rgb(224, 174, 78),
		ring = rgb(44, 112, 64),
		banner = rgb(40, 122, 68),
		glow = rgb(255, 200, 80),
		pale = rgb(255, 236, 170),
		flame = rgb(255, 170, 40),
		flameCore = rgb(255, 240, 190),
	},
}

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
-- Pieza del santuario: decorativa (sin colisión, consultas ni toques) salvo que se pida otra cosa
local function piece(S, props)
	props.Parent = props.Parent or S.folder
	for _, k in ipairs({ "CanCollide", "CanQuery", "CanTouch" }) do
		if props[k] == nil then
			props[k] = false
		end
	end
	return G.World.part(props)
end

-- Pieza pequeña o de neón: además no proyecta sombra
local function glowPiece(S, props)
	props.Material = props.Material or M.Neon
	props.CastShadow = false
	return piece(S, props)
end

-- Marco en un anillo: ángulo desde el fondo (0 = detrás del dios, 180° = frente). +Z local = hacia fuera
local function polar(S, angle, radius, y)
	return S.cf * CFrame.Angles(0, angle, 0) * CFrame.new(0, y or 0, radius)
end

-- Marco de un objeto del interior que mira hacia la entrada del templete (su -Z local es su frente)
local function propFrame(S, angle, radius)
	local p = polar(S, angle, radius, DAIS_TOP).Position
	local front = (S.cf * CFrame.new(0, DAIS_TOP, -6)).Position
	return CFrame.lookAt(p, front)
end

local function tag(inst, name, attrs)
	for k, v in pairs(attrs or {}) do
		inst:SetAttribute(k, v)
	end
	CollectionService:AddTag(inst, name)
	return inst
end

local function ns(points)
	local kp = {}
	for i, p in ipairs(points) do
		kp[i] = NumberSequenceKeypoint.new(p[1], p[2])
	end
	return NumberSequence.new(kp)
end

-- Emisor en un Attachment con ejes del mundo (Top = hacia arriba) colgado de una pieza anclada
local function emitterAt(part, worldPos, props)
	local att = Instance.new("Attachment")
	att.Name = "Fx"
	att.Parent = part
	att.WorldCFrame = CFrame.new(worldPos)
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	e.LightInfluence = 0
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = att
	return e
end

local function pointLight(parent, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = parent
	return l
end

---------------------------------------------------------------------
-- Estructura común: escalinata redonda, círculo de runas, columnas y anillo
---------------------------------------------------------------------
local function buildDais(S)
	local st = S.st
	-- tres escalones bajos (0,4 cada uno); son lo único grande con colisión
	local radii = { 8.4, 7.9, 7.4 }
	for i, r in ipairs(radii) do
		local top = i * 0.4
		local bottom = i == 1 and -0.3 or top - 0.6
		local step = piece(S, {
			Name = "Step" .. i, Shape = CYL, Size = Vector3.new(top - bottom, r * 2, r * 2),
			CFrame = S.cf * CFrame.new(0, (top + bottom) / 2, 0) * UP, Color = st.steps[i], Material = M.Marble,
			CanCollide = true, CanQuery = true,
		})
		G.World.skin(step, "paving", 4, i == 3 and st.floor or st.steps[i]:Lerp(Color3.new(1, 1, 1), 0.35), 0.1, { N.Right })
		if i == 3 then
			G.World.skin(step, "grime", 18, Color3.new(1, 1, 1), 0.6, { N.Right })
		end
	end
	-- filo de luz alrededor del último escalón
	glowPiece(S, {
		Name = "DaisRim", Shape = CYL, Size = Vector3.new(0.2, 15.1, 15.1),
		CFrame = S.cf * CFrame.new(0, DAIS_TOP - 0.12, 0) * UP, Color = st.glow,
	})
	-- círculo de runas delante del dios (el cliente lo hace girar)
	local runes = glowPiece(S, {
		Name = "RuneCircle", Shape = CYL, Size = Vector3.new(0.12, 7.4, 7.4),
		CFrame = S.cf * CFrame.new(0, DAIS_TOP + 0.07, -2.4) * UP, Color = st.glow, Transparency = 0.55,
	})
	for _, face in ipairs({ N.Right, N.Left }) do
		local d = Instance.new("Decal")
		d.Name = "Runes"
		d.Texture = G.Config.VFX.runes
		d.Face = face
		d.Color3 = st.pale
		d.Parent = runes
	end
	tag(runes, "FxSpin", { SpinSpeed = S.key == "aura" and 0.4 or -0.4, SpinAxis = "X" })
	S.runes = runes
end

local function buildColonnade(S)
	local st = S.st
	local shaftH = COL_TOP - 0.6 - (DAIS_TOP + 0.6)
	for _, deg in ipairs({ -90, -54, -18, 18, 54, 90 }) do
		local f = polar(S, math.rad(deg), COL_R, 0)
		piece(S, {
			Name = "ColumnBase", Size = Vector3.new(1.9, 0.6, 1.9), CFrame = f * CFrame.new(0, DAIS_TOP + 0.3, 0),
			Color = st.trim, Material = M.Foil, CanCollide = true, CanQuery = true,
		})
		piece(S, {
			Name = "Column", Shape = CYL, Size = Vector3.new(shaftH, 1.3, 1.3),
			CFrame = f * CFrame.new(0, DAIS_TOP + 0.6 + shaftH / 2, 0) * UP, Color = st.column, Material = M.Marble,
			CanCollide = true, CanQuery = true,
		})
		piece(S, {
			Name = "ColumnCap", Size = Vector3.new(1.9, 0.6, 1.9), CFrame = f * CFrame.new(0, COL_TOP - 0.3, 0),
			Color = st.trim, Material = M.Foil,
		})
	end
	-- anillo de diez tramos con greca; queda abierto por arriba (óculo) para que el dios reciba el sol
	local len = 2 * COL_R * math.sin(NODE) + 0.5
	for i = 0, 9 do
		local seg = piece(S, {
			Name = "Ring", Size = Vector3.new(len, RING_H, 1.5),
			CFrame = polar(S, math.rad(i * 36), RING_MID, COL_TOP + RING_H / 2), Color = st.ring, Material = M.Marble,
		})
		G.World.skin(seg, "meander", RING_H, st.pale, 0.05, { N.Front, N.Back })
	end
end

-- Estandarte que cuelga del anillo entre dos columnas, con remate y emblema redondo
local function banner(S, deg, width, height, emblemSize)
	local st = S.st
	local f = polar(S, math.rad(deg), RING_MID - 0.1, 0)
	local top = COL_TOP
	piece(S, {
		Name = "Banner", Size = Vector3.new(width, height, 0.18), CFrame = f * CFrame.new(0, top - height / 2, 0),
		Color = st.banner, Material = M.Fabric,
	})
	local tip = piece(S, {
		Name = "BannerTip", Size = Vector3.new(width + 0.2, 0.5, 0.26), CFrame = f * CFrame.new(0, top - height - 0.2, 0),
		Color = st.trim, Material = M.Foil, CastShadow = false,
	})
	G.World.skin(tip, "meander", 0.5, Color3.new(1, 1, 1), 0.2, { N.Front, N.Back })
	return glowPiece(S, {
		Name = "BannerEmblem", Shape = CYL, Size = Vector3.new(0.3, emblemSize, emblemSize),
		CFrame = f * CFrame.new(0, top - height * 0.38, 0) * FACING, Color = st.pale,
	})
end

-- Dos braseros con fuego de color a los lados de la entrada
local function buildBraziers(S)
	local st = S.st
	for _, deg in ipairs({ -108, 108 }) do
		local f = polar(S, math.rad(deg), 7, 0.8)
		for _, p in ipairs(G.World.brazier(f.Position, st.flame, S.folder, 0.65)) do
			if p.Name ~= "BrazierBowl" then
				p.CFrame = f.Rotation + p.Position -- alineado con el templete
			else
				p.Color = st.trim
				local fire = p:FindFirstChildWhichIsA("ParticleEmitter", true)
				if fire then
					fire.Color = ColorSequence.new(st.flameCore, st.flame)
				end
				local l = p:FindFirstChildWhichIsA("PointLight", true)
				if l then
					l.Color = st.flame:Lerp(Color3.new(1, 1, 1), 0.25)
				end
			end
		end
	end
end

---------------------------------------------------------------------
-- El dios: avatar R15 (como los guardianes) o, si falla, figura de piezas
---------------------------------------------------------------------
local function spawnNpc(S)
	local st = S.st
	local ground = S.cf * CFrame.new(0, DAIS_TOP, st.standZ)
	local feet = ground * CFrame.new(0, st.hover or 0, 0)
	local k = st.scale
	local ok, tmpl = pcall(function()
		return G.Avatars and G.Avatars.make(st.god)
	end)
	if not ok then
		tmpl = nil
	end
	local m, pivotH
	if tmpl then
		m = tmpl:Clone()
		m:ScaleTo(k)
		pivotH = (m:GetAttribute("PivotH") or 3) * k
	else
		m = G.GodModel.buildParts(st.god, S.V.color)
		m:ScaleTo(k)
		pivotH = 0.1 * k -- el pivote de la figura de piezas está a ras de suelo
	end
	m.Name = st.npc
	m:SetAttribute("Vendor", S.key)
	m:PivotTo(feet * CFrame.new(0, pivotH, 0)) -- el frente de un avatar es su -Z: mira a la plaza
	m.Parent = S.folder
	if tmpl then
		pcall(G.Avatars.play, m, "idle")
		if st.hover and m.PrimaryPart then
			-- la raíz está anclada: el cliente la hace subir y bajar despacio y todo el cuerpo la sigue
			tag(m.PrimaryPart, "FxBob", { BobAmp = 0.3, BobSpeed = 1.1, BobPhase = 0 })
		end
	end
	S.npc = m
	S.ground = ground
	S.feet = feet
	S.k = k
	-- pieza invisible en el pecho: lleva el aviso de interacción, la luz y los emisores
	local core = piece(S, {
		Name = "Core", Size = Vector3.new(1, 1, 1), CFrame = feet * CFrame.new(0, 3.3 * k, 0), Transparency = 1,
	})
	S.core = core
	local prompt = Instance.new("ProximityPrompt")
	prompt.Name = "VendorPrompt"
	prompt.ObjectText = st.object
	prompt.ActionText = st.action
	prompt.HoldDuration = 0
	prompt.MaxActivationDistance = 16
	prompt.RequiresLineOfSight = false
	prompt.Parent = core
	tag(prompt, "VendorPrompt", { Vendor = S.key })
	S.prompt = prompt
	pointLight(core, S.V.color, 20, 1.1)
end

-- Cuerpo de caballo de Quirón: piezas ancladas detrás del avatar (sus piernas son las patas delanteras)
local function buildCentaur(S)
	local st = S.st
	local k = S.k
	local coat = rgb(124, 82, 48)
	local dark = rgb(64, 40, 24)
	local function at(x, y, z)
		return S.feet * CFrame.new(x * k, y * k, z * k)
	end
	local function horse(name, size, cf, color, material, shape)
		return piece(S, { Name = name, Shape = shape, Size = size * k, CFrame = cf, Color = color, Material = material or M.SmoothPlastic })
	end
	horse("HorseBody", Vector3.new(2.9, 2, 2), at(0, 2.05, 1.7) * FACING, coat, nil, CYL)
	horse("HorseRump", Vector3.new(2.1, 2.1, 2.1), at(0, 2.08, 3.05), coat, nil, BALL)
	local cloth = horse("HorseCloth", Vector3.new(2.08, 1.15, 1.7), at(0, 2.56, 1.6), st.banner, M.Fabric)
	G.World.skin(cloth, "meander", 0.5 * k, st.pale, 0.1, { N.Left, N.Right }, 0.5 * k)
	for _, sx in ipairs({ -1, 1 }) do
		horse("HorseLeg", Vector3.new(0.62, 1.9, 0.72), at(sx * 0.55, 1.2, 3.15), coat)
		horse("HorseHoof", Vector3.new(0.72, 0.3, 0.84), at(sx * 0.55, 0.15, 3.15), dark)
	end
	horse("HorseTail", Vector3.new(0.42, 2, 0.42), at(0, 1.75, 4.25) * CFrame.Angles(math.rad(-16), 0, 0), dark, M.Fabric)
end

---------------------------------------------------------------------
-- Remates comunes: cartel, faro de luz, orbes que giran y partículas
---------------------------------------------------------------------
local function buildSign(S)
	local st = S.st
	local sign = piece(S, {
		Name = "Sign", Size = Vector3.new(1, 1, 1), CFrame = polar(S, math.pi, RING_MID, RING_TOP + 8.6), Transparency = 1,
	})
	-- (visto en Studio: desde la plaza el cartel se leía mal; un 40 % más grande y algo más alto)
	local bb = G.World.billboard(sign, "", S.V.color, UDim2.fromOffset(540, 155), Vector3.new(0, 0, 0))
	bb.Name = "Nameplate"
	bb.MaxDistance = 240
	bb:SetAttribute("Vendor", S.key)
	CollectionService:AddTag(bb, "Loc")
	bb.Label.Text = st.sign .. "\n" .. S.V.en -- el cliente lo cambia por el texto en el idioma del jugador
	S.sign = bb
	-- faro de luz fino y muy transparente para encontrar al vendedor desde lejos
	glowPiece(S, {
		Name = "Beacon", Shape = CYL, Size = Vector3.new(BEACON_H, 1.6, 1.6),
		CFrame = S.cf * CFrame.new(0, RING_TOP + 0.4 + BEACON_H / 2, 0) * UP, Color = S.V.color, Transparency = 0.72,
	})
end

-- Orbes que giran alrededor del dios (FxOrbit: tienen que ser hijos de la pieza que orbitan)
local function buildOrbit(S, count, radius, size, color, speed)
	local centre = piece(S, {
		Name = "OrbitCentre", Size = Vector3.new(1, 1, 1), CFrame = CFrame.new((S.cf * CFrame.new(0, 12.6, 0)).Position), Transparency = 1,
	})
	for i = 1, count do
		local phase = (i - 1) / count * math.pi * 2
		local tilt = 0.16
		local orb = glowPiece(S, {
			Name = "Orb", Shape = BALL, Size = Vector3.new(size, size, size), Color = color, Parent = centre,
			-- misma fórmula que usa el cliente, así la vista previa coincide con el instante 0
			CFrame = CFrame.new(centre.Position) * CFrame.Angles(tilt, 0, 0) * CFrame.Angles(0, phase, 0) * CFrame.new(radius, 0, 0),
		})
		tag(orb, "FxOrbit", { OrbitRadius = radius, OrbitSpeed = speed, OrbitHeight = 0, OrbitPhase = phase, OrbitTilt = tilt, OrbitSpin = 1.5 })
	end
end

local function buildParticles(S, sparkColor)
	local st = S.st
	local floor = (S.ground * CFrame.new(0, 0.25, 0)).Position
	-- destellos que suben desde el suelo alrededor del dios
	emitterAt(S.core, floor, {
		Name = "Sparkles", Texture = G.Config.VFX.sparkle, Rate = 9, Lifetime = NumberRange.new(2.6, 3.6),
		Speed = NumberRange.new(2.5, 5), SpreadAngle = Vector2.new(38, 38), Drag = 0.4,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-120, 120),
		Color = ColorSequence.new(Color3.new(1, 1, 1), sparkColor),
		Size = ns({ { 0, 0 }, { 0.15, 0.9 }, { 1, 0 } }), Transparency = ns({ { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
	})
	-- onda de luz que se abre sobre el suelo
	emitterAt(S.core, floor, {
		Name = "FloorPulse", Texture = G.Config.VFX.ring, Rate = 0.6, Lifetime = NumberRange.new(2.6),
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, EmissionDirection = N.Top,
		Speed = NumberRange.new(0.01), SpreadAngle = Vector2.new(0, 0),
		Color = ColorSequence.new(st.pale, st.glow),
		Size = ns({ { 0, 2 }, { 1, 14 } }), Transparency = ns({ { 0, 0.2 }, { 0.6, 0.6 }, { 1, 1 } }),
	})
end

---------------------------------------------------------------------
-- Hécate: luna triple, portal de runas, caldero, llave flotante y cristales
---------------------------------------------------------------------
local function decorHecate(S)
	local st = S.st
	local front = polar(S, math.pi, RING_MID, 0)
	-- luna triple sobre la entrada: creciente, llena y menguante
	local cy = RING_TOP + 2
	local moon = glowPiece(S, {
		Name = "FullMoon", Shape = CYL, Size = Vector3.new(0.5, 4, 4), CFrame = front * CFrame.new(0, cy, 0) * FACING, Color = st.pale,
	})
	pointLight(moon, st.pale, 16, 0.8)
	for _, sx in ipairs({ -1, 1 }) do
		for i = -2, 2 do
			local a = math.rad(i * 35)
			glowPiece(S, {
				Name = "Crescent", Size = Vector3.new(0.95 - math.abs(i) * 0.3, 1.2, 0.45), Color = st.pale,
				CFrame = front * CFrame.new(sx * (4.3 - 1.7 * math.cos(a)), cy + 1.7 * math.sin(a), 0) * CFrame.Angles(0, 0, -sx * a),
			})
		end
	end
	-- portal de runas al fondo: recorta la silueta de la diosa
	local back = polar(S, 0, RING_MID - 0.1, 0)
	local portal = glowPiece(S, {
		Name = "Portal", Size = Vector3.new(3, 11, 0.3), CFrame = back * CFrame.new(0, DAIS_TOP + 5.7, 0),
		Color = rgb(150, 84, 255), Transparency = 0.4,
	})
	G.World.skin(portal, "runes", 3, st.pale, 0.1, { N.Front, N.Back })
	piece(S, {
		Name = "PortalLintel", Size = Vector3.new(3.7, 0.5, 0.7), CFrame = back * CFrame.new(0, DAIS_TOP + 11.45, 0),
		Color = st.trim, Material = M.Foil, CastShadow = false,
	})
	banner(S, -36, 2.4, 7.4, 1.3)
	banner(S, 36, 2.4, 7.4, 1.3)
	-- caldero con poción brillante (lado del báculo)
	local c = propFrame(S, math.rad(72), 5.5)
	piece(S, { Name = "Cauldron", Shape = BALL, Size = Vector3.new(2.4, 2.4, 2.4), CFrame = c * CFrame.new(0, 1, 0), Color = rgb(54, 48, 70), Material = M.Metal })
	piece(S, { Name = "CauldronRim", Shape = CYL, Size = Vector3.new(0.3, 2.3, 2.3), CFrame = c * CFrame.new(0, 2.15, 0) * UP, Color = rgb(74, 66, 96), Material = M.Metal, CastShadow = false })
	glowPiece(S, { Name = "Potion", Shape = CYL, Size = Vector3.new(0.12, 1.9, 1.9), CFrame = c * CFrame.new(0, 2.26, 0) * UP, Color = rgb(222, 110, 255) })
	for i, o in ipairs({ Vector3.new(-0.35, 2.9, 0.1), Vector3.new(0.4, 3.5, -0.2) }) do
		local bubble = glowPiece(S, { Name = "Bubble", Shape = BALL, Size = Vector3.new(0.6 - i * 0.12, 0.6 - i * 0.12, 0.6 - i * 0.12), CFrame = c * CFrame.new(o), Color = st.pale, Transparency = 0.2 })
		tag(bubble, "FxBob", { BobAmp = 0.3, BobSpeed = 2 + i * 0.5, BobPhase = i * 2 })
	end
	-- llave dorada flotando sobre un pedestal (Hécate guarda las llaves de todas las puertas)
	local kf = propFrame(S, math.rad(-72), 5.5)
	piece(S, { Name = "KeyPedestal", Shape = CYL, Size = Vector3.new(1.6, 1.5, 1.5), CFrame = kf * CFrame.new(0, 0.8, 0) * UP, Color = st.column, Material = M.Marble })
	piece(S, { Name = "KeyPedestalTop", Size = Vector3.new(1.9, 0.3, 1.9), CFrame = kf * CFrame.new(0, 1.75, 0), Color = st.trim, Material = M.Foil, CastShadow = false })
	local keyGold = rgb(255, 214, 110)
	local keyParts = {
		glowPiece(S, { Name = "KeyBow", Shape = CYL, Size = Vector3.new(0.24, 1.3, 1.3), CFrame = kf * CFrame.new(0, 5, 0) * FACING, Color = keyGold }),
		glowPiece(S, { Name = "KeyShaft", Size = Vector3.new(0.26, 2.3, 0.26), CFrame = kf * CFrame.new(0, 3.4, 0), Color = keyGold }),
		glowPiece(S, { Name = "KeyTooth", Size = Vector3.new(0.62, 0.24, 0.24), CFrame = kf * CFrame.new(0.4, 2.45, 0), Color = keyGold }),
		glowPiece(S, { Name = "KeyTooth", Size = Vector3.new(0.45, 0.24, 0.24), CFrame = kf * CFrame.new(0.32, 2.95, 0), Color = keyGold }),
	}
	for _, p in ipairs(keyParts) do
		tag(p, "FxBob", { BobAmp = 0.3, BobSpeed = 1.4, BobPhase = 0 }) -- mismos valores: la llave sube y baja entera
	end
	-- cristales que flotan sobre el anillo
	for i, deg in ipairs({ -126, -54, 54, 126 }) do
		local crystal = glowPiece(S, {
			Name = "Crystal", Size = Vector3.new(0.9, 2.3, 0.9), CFrame = polar(S, math.rad(deg), COL_R, RING_TOP + 1.9) * CFrame.Angles(0, math.rad(45), 0),
			Color = i % 2 == 0 and st.glow or rgb(140, 110, 255),
		})
		tag(crystal, "FxSpin", { SpinSpeed = 0.9, SpinAxis = "Y" })
		tag(crystal, "FxBob", { BobAmp = 0.45, BobSpeed = 1.2, BobPhase = i * 1.6 })
	end
	-- gran círculo mágico, muy tenue, que gira al revés por todo el suelo del templete
	local ring = glowPiece(S, {
		Name = "RuneRing", Shape = CYL, Size = Vector3.new(0.06, 14.4, 14.4),
		CFrame = S.cf * CFrame.new(0, DAIS_TOP + 0.035, 0) * UP, Color = st.glow, Transparency = 0.85,
	})
	local d = Instance.new("Decal")
	d.Name = "Runes"
	d.Texture = G.Config.VFX.runes
	d.Face = N.Right
	d.Color3 = st.glow
	d.Transparency = 0.3
	d.Parent = ring
	tag(ring, "FxSpin", { SpinSpeed = -0.15, SpinAxis = "X" })
	buildOrbit(S, 3, 5, 1, st.pale, 0.7) -- tres lunas alrededor de la diosa triple
	buildParticles(S, st.glow)
	-- bruma violeta a ras de suelo
	emitterAt(S.core, (S.cf * CFrame.new(0, DAIS_TOP + 0.6, -1.5)).Position, {
		Name = "Mist", Texture = G.Config.VFX.smoke, Rate = 4, Lifetime = NumberRange.new(3, 4.5), LightEmission = 0.5,
		Speed = NumberRange.new(0.6, 1.5), SpreadAngle = Vector2.new(85, 85),
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-15, 15),
		Color = ColorSequence.new(rgb(150, 90, 255), rgb(90, 50, 190)),
		Size = ns({ { 0, 3.5 }, { 1, 8 } }), Transparency = ns({ { 0, 1 }, { 0.2, 0.8 }, { 0.7, 0.88 }, { 1, 1 } }),
	})
end

---------------------------------------------------------------------
-- Quirón: escudo con lanzas y laurel, diana de tiro, armero y medallones de héroe
---------------------------------------------------------------------
local function decorQuiron(S)
	local st = S.st
	local bronze = rgb(196, 124, 62)
	local wood = rgb(126, 84, 46)
	local steel = rgb(222, 226, 236)
	local laurel = rgb(96, 180, 76)
	local front = polar(S, math.pi, RING_MID, 0)
	-- emblema sobre la entrada: escudo de bronce, dos lanzas cruzadas y corona de laurel
	local cy = RING_TOP + 2
	piece(S, { Name = "CrestRim", Shape = CYL, Size = Vector3.new(0.3, 4.6, 4.6), CFrame = front * CFrame.new(0, cy, -0.05) * FACING, Color = st.trim, Material = M.Foil, CastShadow = false })
	piece(S, { Name = "CrestShield", Shape = CYL, Size = Vector3.new(0.5, 4, 4), CFrame = front * CFrame.new(0, cy, 0) * FACING, Color = bronze, Material = M.Metal, CastShadow = false })
	local boss = glowPiece(S, { Name = "CrestBoss", Shape = BALL, Size = Vector3.new(1.3, 1.3, 1.3), CFrame = front * CFrame.new(0, cy, 0.25), Color = st.glow })
	pointLight(boss, st.pale, 16, 0.8)
	for _, sx in ipairs({ -1, 1 }) do
		piece(S, { Name = "CrestSpear", Size = Vector3.new(0.24, 7.2, 0.24), CFrame = front * CFrame.new(0, cy, -0.3) * CFrame.Angles(0, 0, math.rad(sx * 40)), Color = wood, Material = M.Wood, CastShadow = false })
		for i, deg in ipairs({ 200, 165, 130 }) do
			local a = math.rad(sx > 0 and deg or 180 - deg)
			piece(S, {
				Name = "CrestLaurel", Size = Vector3.new(0.6, 1.6 - i * 0.1, 0.3), Color = laurel, Material = M.SmoothPlastic, CastShadow = false,
				CFrame = front * CFrame.new(math.cos(a) * 2.8, cy + math.sin(a) * 2.8, 0.1) * CFrame.Angles(0, 0, a),
			})
		end
	end
	banner(S, -36, 2.4, 7.4, 1.4)
	banner(S, 36, 2.4, 7.4, 1.4)
	-- diana de tiro con arco (lado del arco)
	local t = propFrame(S, math.rad(72), 5.5)
	for _, sx in ipairs({ -1, 1 }) do
		piece(S, { Name = "TargetLeg", Size = Vector3.new(0.24, 4.5, 0.24), CFrame = t * CFrame.new(sx * 0.6, 2.1, 0.3) * CFrame.Angles(0, 0, math.rad(sx * 14)), Color = wood, Material = M.Wood, CastShadow = false })
	end
	piece(S, { Name = "TargetLeg", Size = Vector3.new(0.24, 4.4, 0.24), CFrame = t * CFrame.new(0, 2.05, 0.95) * CFrame.Angles(math.rad(-20), 0, 0), Color = wood, Material = M.Wood, CastShadow = false })
	local face = t * CFrame.new(0, 3.3, 0)
	piece(S, { Name = "Target", Shape = CYL, Size = Vector3.new(0.4, 2.8, 2.8), CFrame = face * FACING, Color = rgb(238, 226, 196), Material = M.Fabric })
	piece(S, { Name = "TargetRing", Shape = CYL, Size = Vector3.new(0.46, 1.9, 1.9), CFrame = face * FACING, Color = rgb(214, 58, 48), Material = M.SmoothPlastic, CastShadow = false })
	glowPiece(S, { Name = "TargetBull", Shape = CYL, Size = Vector3.new(0.52, 0.9, 0.9), CFrame = face * FACING, Color = st.glow })
	piece(S, { Name = "TargetArrow", Size = Vector3.new(0.12, 0.12, 1.5), CFrame = face * CFrame.new(0.15, 0.1, -0.9) * CFrame.Angles(math.rad(8), math.rad(-6), 0), Color = st.banner, Material = M.Wood, CastShadow = false })
	-- armero con un escudo y dos lanzas (lado del escudo)
	local r = propFrame(S, math.rad(-72), 5.4)
	for _, sx in ipairs({ -1, 1 }) do
		piece(S, { Name = "RackPost", Size = Vector3.new(0.28, 3.7, 0.28), CFrame = r * CFrame.new(sx * 1.2, 1.85, 0.2), Color = wood, Material = M.Wood, CastShadow = false })
	end
	piece(S, { Name = "RackBar", Size = Vector3.new(2.9, 0.26, 0.26), CFrame = r * CFrame.new(0, 3.5, 0.2), Color = wood, Material = M.Wood, CastShadow = false })
	local sh = r * CFrame.new(-0.45, 1.15, -0.15) * CFrame.Angles(math.rad(14), 0, 0)
	piece(S, { Name = "RackShield", Shape = CYL, Size = Vector3.new(0.26, 2.1, 2.1), CFrame = sh * FACING, Color = bronze, Material = M.Metal, CastShadow = false })
	glowPiece(S, { Name = "RackShieldBoss", Shape = BALL, Size = Vector3.new(0.6, 0.6, 0.6), CFrame = sh * CFrame.new(0, 0, -0.15), Color = st.glow })
	for i, x in ipairs({ 0.55, 1 }) do
		local sp = r * CFrame.new(x, 2.75, 0) * CFrame.Angles(math.rad(4), 0, math.rad(-3 * i))
		piece(S, { Name = "RackSpear", Size = Vector3.new(0.16, 5.5, 0.16), CFrame = sp, Color = wood, Material = M.Wood, CastShadow = false })
		piece(S, { Name = "RackSpearTip", Size = Vector3.new(0.34, 0.7, 0.1), CFrame = sp * CFrame.new(0, 3.05, 0), Color = steel, Material = M.Metal, CastShadow = false })
	end
	-- medallones de héroe que flotan sobre el anillo, a los lados del emblema
	for i, deg in ipairs({ -126, 126 }) do
		local medal = piece(S, {
			Name = "Medal", Shape = CYL, Size = Vector3.new(0.3, 1.8, 1.8), CFrame = polar(S, math.rad(deg), COL_R, RING_TOP + 1.8) * FACING,
			Color = st.trim, Material = M.Foil, CastShadow = false,
		})
		tag(medal, "FxSpin", { SpinSpeed = 1.1, SpinAxis = "Y" })
		tag(medal, "FxBob", { BobAmp = 0.4, BobSpeed = 1.3, BobPhase = i * 2 })
	end
	buildOrbit(S, 4, 5, 0.9, st.glow, -0.6) -- cuatro luces: los cuatro héroes que entrenó
	buildParticles(S, st.glow)
	-- rayos de sol que giran despacio detrás del maestro
	emitterAt(S.core, S.core.Position, {
		Name = "Rays", Texture = G.Config.VFX.rays, Rate = 0.5, Lifetime = NumberRange.new(4.5), LockedToPart = true,
		ZOffset = -5, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(10),
		Color = ColorSequence.new(st.pale, st.glow),
		Size = ns({ { 0, 15 }, { 1, 17 } }), Transparency = ns({ { 0, 1 }, { 0.3, 0.72 }, { 0.7, 0.72 }, { 1, 1 } }),
	})
end

---------------------------------------------------------------------
-- Construcción
---------------------------------------------------------------------
local function build(key)
	local V = G.Config.VENDORS[key]
	local st = STYLES[key]
	local folder = Instance.new("Folder")
	folder.Name = st.folder
	folder:SetAttribute("VendorPos", V.pos)
	folder:SetAttribute("Vendor", key)
	folder.Parent = G.World.getRoot()
	local look = Vector3.new(Vendors.LOOK_AT.X, V.pos.Y, Vendors.LOOK_AT.Z)
	-- el frente del templete (y del dios) es el -Z local: mira a la fuente de la plaza
	local S = { key = key, V = V, st = st, folder = folder, cf = CFrame.lookAt(V.pos, look) }
	Vendors.shrines[key] = S
	buildDais(S)
	buildColonnade(S)
	buildBraziers(S)
	spawnNpc(S)
	buildSign(S)
	if key == "aura" then
		decorHecate(S)
	else
		buildCentaur(S)
		decorQuiron(S)
	end
	return S
end

function Vendors.init(g)
	G = g
	for _, key in ipairs({ "aura", "coach" }) do
		-- un fallo en un santuario no debe impedir que arranque el juego
		local ok, err = pcall(build, key)
		if not ok then
			table.insert(Vendors.errors, key .. ": " .. tostring(err))
			warn("Vendors: no se pudo construir el santuario", key, err)
		end
	end
end

return Vendors
