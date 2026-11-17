-- Diseño visual de los sobres y de los nidos de cada zona.
-- · 14 rarezas, cada una más épica que la anterior: tabla STYLES (fácil de ajustar).
-- · El tamaño lo decide el peso: k = Config.packScale(kg). Todo lo que cuelga del sobre se escala con k.
-- · Las piezas rígidas van soldadas al sobre (lo siguen solas); lo que orbita lo anima el cliente (etiquetas Fx*).
-- Packs.luau lleva la jugabilidad; aquí solo se construyen piezas, partículas, luces y carteles.
local CollectionService = game:GetService("CollectionService")

local PackStyle = {}
local G
local C

local M = Enum.Material
local WHITE = Color3.new(1, 1, 1)
local BLACK = Color3.new(0, 0, 0)
local GOLD = Color3.fromRGB(240, 196, 92)
local UPRIGHT = CFrame.Angles(0, 0, math.rad(90)) -- pone de pie un cilindro (su eje es la X local)
local function rgb(r, g, b)
	return Color3.fromRGB(r, g, b)
end

-- El cartón solo existe en motores recientes: si falta, plástico liso
local okPaper, PAPER = pcall(function()
	return Enum.Material.Cardboard
end)
if not okPaper or not PAPER then
	PAPER = M.SmoothPlastic
end

PackStyle.FLOOR_Y = 0.2 -- parte de arriba de la pista del pasillo
PackStyle.NEST_BED = 0.6 -- grosor del lecho del nido (donde descansan los sobres)
PackStyle.HALF = 2.25 -- media altura del sobre con sus sellos, por unidad de escala
PackStyle.NEST_OUTER = 16 -- radio máximo del nido
PackStyle.NEST_RIM = 2.5 -- altura máxima del borde del nido

-- Presupuesto por sobre: emisores de partículas y piezas extra
function PackStyle.budget(r)
	local emitters = r <= 3 and 2 or r <= 6 and 4 or r <= 9 and 5 or 7
	local parts = r <= 6 and 6 or 14
	return emitters, parts
end

---------------------------------------------------------------------
-- Ayudantes
---------------------------------------------------------------------
local function seq(points) -- NumberSequence a partir de { { tiempo, valor }, ... }
	local kp = table.create(#points)
	for i, p in ipairs(points) do
		kp[i] = NumberSequenceKeypoint.new(p[1], p[2])
	end
	return NumberSequence.new(kp)
end

local function colors(a, b, c) -- ColorSequence de dos o tres colores
	if c then
		return ColorSequence.new({ ColorSequenceKeypoint.new(0, a), ColorSequenceKeypoint.new(0.5, b), ColorSequenceKeypoint.new(1, c) })
	end
	return ColorSequence.new(a, b or a)
end

local function tag(inst, name, attrs)
	if attrs then
		for key, v in pairs(attrs) do
			inst:SetAttribute(key, v)
		end
	end
	CollectionService:AddTag(inst, name)
	return inst
end

local function rainbow(inst, speed, sat)
	return tag(inst, "FxRainbow", { RainbowSpeed = speed or 0.25, RainbowSat = sat or 0.7 })
end

-- Pieza rígida soldada al sobre (lo sigue cuando el servidor lo mueve)
local function deco(ctx, name, size, offset, color, mat, opts)
	opts = opts or {}
	local d = Instance.new(opts.class or "Part")
	d.Name = name
	if opts.shape then
		d.Shape = opts.shape
	end
	d.Size = size
	d.CFrame = ctx.part.CFrame * offset
	d.Color = color
	d.Material = mat or M.SmoothPlastic
	d.Transparency = opts.t or 0
	d.Reflectance = opts.refl or 0
	d.Anchored = false
	d.Massless = true
	d.CanCollide = false
	d.CanQuery = false
	d.CanTouch = false
	d.CastShadow = false
	d.TopSurface = Enum.SurfaceType.Smooth
	d.BottomSurface = Enum.SurfaceType.Smooth
	d.Parent = ctx.part
	local w = Instance.new("WeldConstraint")
	w.Part0 = ctx.part
	w.Part1 = d
	w.Parent = d
	ctx.parts += 1
	return d
end

-- Estela de luz detrás de una pieza que se mueve
local function trail(part, half, color, life)
	local a0 = Instance.new("Attachment")
	a0.Name = "TrailA"
	a0.Position = Vector3.new(0, half, 0)
	a0.Parent = part
	local a1 = Instance.new("Attachment")
	a1.Name = "TrailB"
	a1.Position = Vector3.new(0, -half, 0)
	a1.Parent = part
	local tr = Instance.new("Trail")
	tr.Name = "Trail"
	tr.Attachment0 = a0
	tr.Attachment1 = a1
	tr.Lifetime = life or 0.4
	tr.MinLength = 0.05
	tr.FaceCamera = true
	tr.LightEmission = 1
	tr.LightInfluence = 0
	tr.Color = colors(WHITE, color)
	tr.Transparency = seq({ { 0, 0.15 }, { 1, 1 } })
	tr.WidthScale = seq({ { 0, 1 }, { 1, 0 } })
	tr.Parent = part
	return tr
end

-- Pieza que orbita alrededor del sobre: anclada; el cliente la mueve (FxOrbit)
local function orbiter(ctx, name, size, color, o)
	local p = Instance.new("Part")
	p.Name = name
	p.Shape = o.shape or Enum.PartType.Ball
	p.Size = size
	p.Color = color
	p.Material = o.mat or M.Neon
	p.Transparency = o.t or 0
	p.Anchored = true
	p.CanCollide = false
	p.CanQuery = false
	p.CanTouch = false
	p.CastShadow = false
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	p.CFrame = ctx.part.CFrame * (o.rot or CFrame.new())
	tag(p, "FxOrbit", {
		OrbitRadius = o.radius,
		OrbitSpeed = o.speed or 1.5,
		OrbitHeight = o.height or 0,
		OrbitPhase = o.phase or 0,
		OrbitTilt = o.tilt or 0,
		OrbitSpin = o.spin or 0,
	})
	if o.trail then
		local tr = trail(p, math.min(size.X, size.Y) * 0.45, color, 0.35)
		if o.rainbow then
			rainbow(tr, o.rainbow, 0.8)
		end
	end
	if o.rainbow then
		rainbow(p, o.rainbow, 0.75)
	end
	if o.glitch then
		tag(p, "FxGlitch")
	end
	p.Parent = ctx.part
	ctx.parts += 1
	return p
end

local function emitter(ctx, parent, props)
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	e.LightInfluence = 0
	for key, v in pairs(props) do
		e[key] = v
	end
	e.Parent = parent
	ctx.emitters += 1
	return e
end

-- Anillo de luz hecho con dos haces curvos (no gasta piezas ni emisores).
-- cf = centro y plano del anillo en el espacio del sobre (el anillo queda en el plano XZ de cf)
local function ringBeams(ctx, cf, radius, width, color, transparency)
	local a0 = Instance.new("Attachment")
	a0.Name = "RingA"
	a0.CFrame = cf * CFrame.new(-radius, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	a0.Parent = ctx.part
	local a1 = Instance.new("Attachment")
	a1.Name = "RingB"
	a1.CFrame = cf * CFrame.new(radius, 0, 0) * CFrame.Angles(0, -math.pi / 2, 0)
	a1.Parent = ctx.part
	local list = {}
	for s = -1, 1, 2 do
		local b = Instance.new("Beam")
		b.Name = "RingBeam"
		b.Attachment0 = a0
		b.Attachment1 = a1
		b.CurveSize0 = s * radius * 4 / 3
		b.CurveSize1 = -s * radius * 4 / 3
		b.Segments = 18
		b.Width0 = width
		b.Width1 = width
		b.FaceCamera = true
		b.LightEmission = 1
		b.LightInfluence = 0
		b.Color = ColorSequence.new(color)
		b.Transparency = NumberSequence.new(transparency or 0.1)
		b.Parent = ctx.part
		table.insert(list, b)
	end
	return list
end

-- Punto de efectos a ras de suelo (Packs lo endereza al colocar el sobre)
local function groundPoint(ctx)
	if not ctx.ground then
		local att = Instance.new("Attachment")
		att.Name = "GroundFX"
		att.Position = Vector3.new(0, -PackStyle.HALF * ctx.k + 0.25, 0)
		att:SetAttribute("Ground", 0.22)
		att.Parent = ctx.part
		ctx.ground = att
	end
	return ctx.ground
end

---------------------------------------------------------------------
-- PIEZAS (coordenadas locales del sobre en unidades de k: ancho X = 3, alto Y = 4, grosor Z = 0.5)
---------------------------------------------------------------------
local PARTS = {}

-- sellos de arriba y abajo, como en un sobre de cartas
local function crimps(ctx)
	local k = ctx.k
	local cr = ctx.style.crimp or {}
	local mat = cr.mat or M.Foil
	for _, sy in ipairs({ -1, 1 }) do
		local c = deco(ctx, "Crimp", Vector3.new(3.1, 0.4, 0.62) * k, CFrame.new(0, sy * 2.05 * k, 0), cr.color or GOLD, mat)
		if mat ~= M.Neon and not cr.plain then
			for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
				local tex = Instance.new("Texture")
				tex.Name = "Greca"
				tex.Texture = C.VFX.meander
				tex.StudsPerTileU = 0.4 * k
				tex.StudsPerTileV = 0.4 * k
				tex.Color3 = cr.tex or WHITE
				tex.Transparency = cr.texT or 0.1
				tex.Face = face
				tex.Parent = c
			end
		end
	end
end

-- lomos laterales
function PARTS.seams(ctx, o)
	local k = ctx.k
	for _, sx in ipairs({ -1, 1 }) do
		deco(ctx, "Seam", Vector3.new(o.w or 0.18, 3.7, 0.56) * k, CFrame.new(sx * 1.5 * k, 0, 0), o.color or ctx.accent, o.mat or M.Foil)
	end
end

-- gema en forma de rombo sobre el sello de arriba (star = dos cuadrados cruzados: estrella de ocho puntas)
function PARTS.gem(ctx, o)
	local k = ctx.k
	local s = o.size or 0.6
	local y = PackStyle.HALF + s * 0.75
	local size = Vector3.new(s, s, s * 0.45) * k
	deco(ctx, "Gem", size, CFrame.new(0, y * k, 0) * CFrame.Angles(0, 0, math.rad(45)), o.color or ctx.accent, M.Neon)
	if o.star then
		deco(ctx, "Gem", size, CFrame.new(0, y * k, 0), o.color2 or ctx.accent2, M.Neon)
	end
	ctx.top = math.max(ctx.top, y + s * 0.75)
	ctx.crest = math.max(ctx.crest, y + s * 0.75)
end

-- chispas / orbes que dan vueltas alrededor (el cliente los mueve)
function PARTS.orbs(ctx, o)
	local k = ctx.k
	local n = o.n or 2
	for j = 1, n do
		local color = o.colors and o.colors[(j - 1) % #o.colors + 1] or o.color or ctx.accent
		local s = (o.size or 0.45) * k
		orbiter(ctx, o.name or "Orb", o.shape == "block" and Vector3.new(s, s * (o.tall or 1), s) or Vector3.new(s, s, s), color, {
			shape = o.shape == "block" and Enum.PartType.Block or Enum.PartType.Ball,
			mat = o.mat,
			t = o.t,
			rot = o.rot,
			radius = (o.radius or 2.4) * k,
			speed = o.speed or 1.5,
			height = ((o.heights and o.heights[(j - 1) % #o.heights + 1]) or 0) * k,
			phase = (j - 1) / n * math.pi * 2,
			tilt = (o.tilts and o.tilts[(j - 1) % #o.tilts + 1]) or 0,
			spin = o.spin or 0,
			trail = o.trail,
			rainbow = o.rainbow,
			glitch = o.glitch,
		})
	end
end

-- dos cuernos de fuego en las esquinas de arriba
function PARTS.horns(ctx, o)
	local k = ctx.k
	local h, base = o.h or 1.2, o.base or 1.0
	for _, sx in ipairs({ -1, 1 }) do
		-- cuña: el lado alto (su +Z local) hacia el exterior del sobre
		deco(ctx, "Horn", Vector3.new(0.34, h, base) * k, CFrame.new(sx * (1.55 - base / 2) * k, (PackStyle.HALF + h / 2) * k, 0) * CFrame.Angles(0, sx * math.rad(90), 0), o.color or ctx.accent, M.Neon, { class = "WedgePart" })
	end
	ctx.top = math.max(ctx.top, PackStyle.HALF + h)
end

-- halo: disco de luz tumbado sobre el sobre, con su anillo brillante
function PARTS.halo(ctx, o)
	local k = ctx.k
	local y, d = o.y or 3.2, o.d or 2.6
	local color = o.color or ctx.accent2
	deco(ctx, "Halo", Vector3.new(0.1, d, d) * k, CFrame.new(0, y * k, 0) * UPRIGHT, color, M.Neon, { shape = Enum.PartType.Cylinder, t = o.t or 0.5 })
	ringBeams(ctx, CFrame.new(0, y * k, 0), d / 2 * k, 0.2 * k, color, 0.05)
	ctx.top = math.max(ctx.top, y + 0.25)
	ctx.crest = math.max(ctx.crest, y + 0.1)
end

-- alas de luz: plumas anchas en abanico a cada lado (borde recto arriba, la punta hacia fuera)
function PARTS.wings(ctx, o)
	local k = ctx.k
	local feathers = o.feathers or { { 56, 3.0, 1.25 }, { 31, 2.6, 1.15 }, { 6, 2.0, 1.0 } } -- { ángulo, largo, ancho }
	local top = ctx.top
	for _, sx in ipairs({ -1, 1 }) do
		local root = Vector3.new(sx * (o.x or 1.4), o.y or 0.6, 0)
		for _, f in ipairs(feathers) do
			local a = math.rad(f[1])
			local len, wide = f[2], f[3]
			local dir = Vector3.new(sx * math.cos(a), math.sin(a), 0) -- a lo largo de la pluma
			local up = Vector3.new(-sx * math.sin(a), math.cos(a), 0) -- hacia el borde de arriba
			-- cuña: su -Z local es la punta; su cara plana (-Y local) queda arriba y el corte en diagonal, abajo
			local zVec = -dir
			local yVec = -up
			local xVec = yVec:Cross(zVec)
			local pos = (root + dir * (len / 2) - up * (wide / 2)) * k
			deco(ctx, "Feather", Vector3.new(0.12, wide, len) * k, CFrame.fromMatrix(pos, xVec, yVec, zVec), o.color or WHITE, M.Neon, { class = "WedgePart", t = o.t or 0.12 })
			top = math.max(top, root.Y + math.sin(a) * len + 0.1)
		end
	end
	ctx.top = top
end

-- estrella de seis puntas (tres barras cruzadas)
function PARTS.crest(ctx, o)
	local k = ctx.k
	local y, len = o.y or 3.25, o.len or 1.5
	for j = 0, 2 do
		deco(ctx, "Star", Vector3.new(len, 0.17, 0.17) * k, CFrame.new(0, y * k, 0) * CFrame.Angles(0, 0, math.rad(j * 60)), o.color or WHITE, M.Neon)
	end
	ctx.top = math.max(ctx.top, y + len / 2)
	ctx.crest = math.max(ctx.crest, y + len / 2)
end

-- anillos horizontales alrededor del sobre
function PARTS.discs(ctx, o)
	local k = ctx.k
	for _, ring in ipairs(o.rings) do -- { altura, diámetro }
		deco(ctx, "Ring", Vector3.new(0.08, ring[2], ring[2]) * k, CFrame.new(0, ring[1] * k, 0) * UPRIGHT, o.color or WHITE, M.Neon, { shape = Enum.PartType.Cylinder, t = o.t or 0.6 })
		local beams = ringBeams(ctx, CFrame.new(0, ring[1] * k, 0), ring[2] / 2 * k, 0.22 * k, ctx.accent, 0.05)
		if o.rainbow then
			for _, b in ipairs(beams) do
				rainbow(b, o.rainbow, 0.85)
			end
		end
	end
end

-- dos anillos inclinados que se cruzan (como las órbitas de un átomo)
function PARTS.tilted(ctx, o)
	local k = ctx.k
	local d = o.d or 5.4
	for _, tilt in ipairs(o.tilts) do -- { giroX, giroZ } en grados
		local cf = CFrame.Angles(math.rad(tilt[1]), 0, math.rad(tilt[2]))
		deco(ctx, "Orbit", Vector3.new(0.08, d, d) * k, cf * UPRIGHT, o.color or WHITE, M.Neon, { shape = Enum.PartType.Cylinder, t = o.t or 0.6 })
		local beams = ringBeams(ctx, cf, d / 2 * k, 0.24 * k, ctx.accent, 0.05)
		if o.rainbow then
			for _, b in ipairs(beams) do
				rainbow(b, o.rainbow, 0.85)
			end
		end
	end
end

-- corona de tres picos sobre el sello de arriba
function PARTS.crown(ctx, o)
	local k = ctx.k
	local y0 = PackStyle.HALF
	local band = 0.42
	deco(ctx, "CrownBand", Vector3.new(2.5, band, 0.72) * k, CFrame.new(0, (y0 + band / 2) * k, 0), o.band or rgb(255, 215, 90), M.Foil)
	local half = 0.415
	local top = 0
	for _, peak in ipairs({ { -0.83, 0.95 }, { 0, 1.35 }, { 0.83, 0.95 } }) do -- { centro X, altura }
		local x0, h = peak[1], peak[2]
		for _, side in ipairs({ -1, 1 }) do
			-- dos cuñas espalda con espalda: el lado alto de cada una mira al centro del pico
			deco(ctx, "CrownPeak", Vector3.new(0.5, h, half) * k, CFrame.new((x0 + side * half / 2) * k, (y0 + band + h / 2) * k, 0) * CFrame.Angles(0, -side * math.rad(90), 0), o.color or ctx.accent2, M.Neon, { class = "WedgePart" })
		end
		top = math.max(top, y0 + band + h)
	end
	-- rubí en el centro de la diadema (sobresale por las dos caras)
	deco(ctx, "CrownJewel", Vector3.new(0.4, 0.4, 0.92) * k, CFrame.new(0, (y0 + band / 2) * k, 0) * CFrame.Angles(0, 0, math.rad(45)), o.jewel or rgb(255, 60, 70), M.Neon)
	ctx.top = math.max(ctx.top, top)
	ctx.crest = math.max(ctx.crest, top)
end

-- cinco esquirlas en abanico sobre el sello: una corona oscura de puntas
function PARTS.shards(ctx, o)
	local k = ctx.k
	local top = ctx.top
	for _, sh in ipairs({ { -1.1, 0.85, 30 }, { -0.56, 1.15, 15 }, { 0, 1.45, 0 }, { 0.56, 1.15, -15 }, { 1.1, 0.85, -30 } }) do -- { x, alto, inclinación }
		local lean = CFrame.Angles(0, 0, math.rad(sh[3]))
		-- la base de cada esquirla nace del sello y la punta se abre hacia fuera
		local cf = CFrame.new(sh[1] * k, (PackStyle.HALF + 0.05) * k, 0) * lean * CFrame.new(0, sh[2] / 2 * k, 0) * CFrame.Angles(0, math.rad(45), 0)
		deco(ctx, "Shard", Vector3.new(0.3, sh[2], 0.3) * k, cf, o.color or ctx.accent, M.Neon)
		top = math.max(top, PackStyle.HALF + 0.05 + sh[2] * math.cos(math.rad(sh[3])) + 0.15)
	end
	ctx.top = top
	ctx.crest = math.max(ctx.crest, top)
end

-- símbolo de infinito: dos aros de frente sobre el sello
function PARTS.infinity(ctx, o)
	local k = ctx.k
	local y, d = PackStyle.HALF + 0.62, 0.95
	for _, sx in ipairs({ -1, 1 }) do
		local cf = CFrame.new(sx * 0.52 * k, y * k, 0)
		deco(ctx, "Infinity", Vector3.new(0.16, d, d) * k, cf * CFrame.Angles(0, math.rad(90), 0), o.color or WHITE, M.Neon, { shape = Enum.PartType.Cylinder, t = 0.25 })
		local beams = ringBeams(ctx, cf * CFrame.Angles(math.rad(90), 0, 0), (d / 2 + 0.06) * k, 0.14 * k, ctx.accent2, 0)
		if o.rainbow then
			for _, b in ipairs(beams) do
				rainbow(b, o.rainbow, 0.85)
			end
		end
	end
	ctx.top = math.max(ctx.top, y + d / 2 + 0.1)
	ctx.crest = math.max(ctx.crest, y + d / 2 + 0.1)
end

-- copias desplazadas en rojo y cian (aberración cromática de un "glitch")
function PARTS.ghosts(ctx, o)
	local k = ctx.k
	deco(ctx, "Ghost", Vector3.new(3.1, 4.4, 0.22) * k, CFrame.new(0.27 * k, 0.07 * k, 0), o.a or rgb(255, 40, 60), M.Neon, { t = 0.15 })
	deco(ctx, "Ghost", Vector3.new(3.1, 4.4, 0.22) * k, CFrame.new(-0.27 * k, -0.04 * k, 0), o.b or rgb(120, 255, 255), M.Neon, { t = 0.3 })
	ctx.top = math.max(ctx.top, PackStyle.HALF + 0.1)
end

-- franjas descolocadas que cruzan el sobre (no tapan el peso)
function PARTS.bars(ctx, o)
	local k = ctx.k
	for j, b in ipairs({ { 0.45, 1.3 }, { -0.5, 0.25 }, { 0.35, -0.72 } }) do -- { x, y }
		deco(ctx, "GlitchBar", Vector3.new(3.7, 0.13, 0.6) * k, CFrame.new(b[1] * k, b[2] * k, 0), j == 2 and (o.b or ctx.accent) or (o.a or WHITE), M.Neon)
	end
end

-- columna de luz: corta en las rarezas altas, hasta el cielo desde ANNOUNCE_BIG_FROM.
-- Nace encima del sobre para no taparlo; va anclada y la coloca settle() (y Packs mientras alguien lo lleva).
local function column(ctx, o, tall)
	local k = ctx.k
	local h = tall and 300 or (o.h or 12) * k
	local d = tall and (1.5 + 0.7 * k) or (o.d or 1.4) * k
	local base = (tall and ctx.crest + 0.15 or PackStyle.HALF) * k -- altura sobre el centro del sobre
	local b = Instance.new("Part")
	b.Name = "Beam"
	b.Shape = Enum.PartType.Cylinder
	b.Size = Vector3.new(h, d, d)
	b.Anchored = true
	b.CanCollide = false
	b.CanQuery = false
	b.CanTouch = false
	b.CastShadow = false
	b.Material = M.Neon
	b.Color = o.color or ctx.accent
	b.Transparency = tall and 0.4 or (o.t or 0.72)
	b.CFrame = CFrame.new(ctx.part.Position + Vector3.new(0, base + h / 2, 0)) * UPRIGHT
	b:SetAttribute("Base", base)
	if o.rainbow then
		rainbow(b, o.rainbow, 0.7)
	end
	b.Parent = ctx.part
	ctx.parts += 1
	ctx.pack.beam = b
end

---------------------------------------------------------------------
-- PARTÍCULAS
---------------------------------------------------------------------
local FX = {}

-- resplandor suave detrás del sobre
function FX.aura(ctx, o)
	local k = ctx.k
	local s, t = o.size or 4.5, o.t or 0.65
	local e = emitter(ctx, ctx.fx, {
		Name = "Aura", Texture = C.VFX.glow, Rate = o.rate or 3, Lifetime = NumberRange.new(1.2, 1.6), Speed = NumberRange.new(0), LockedToPart = true,
		Color = ColorSequence.new(o.color or ctx.accent), Size = seq({ { 0, s * k }, { 1, s * 1.35 * k } }),
		Transparency = seq({ { 0, 1 }, { 0.25, t }, { 0.6, math.min(0.96, t + 0.12) }, { 1, 1 } }), ZOffset = -(0.5 * k + 0.5),
	})
	if o.rainbow then
		rainbow(e, o.rainbow, 0.8)
	end
end

-- destellos sobre la carta
function FX.glint(ctx, o)
	local k = ctx.k
	ctx.sparkle = emitter(ctx, ctx.part, {
		Name = "Glint", Texture = C.VFX.sparkle, Rate = o.rate or 3, Lifetime = NumberRange.new(0.5, 1), Speed = NumberRange.new(0.2 * k, 0.9 * k), SpreadAngle = Vector2.new(180, 180),
		Color = colors(WHITE, o.color or ctx.accent), Size = seq({ { 0, 0 }, { 0.35, (o.size or 1.2) * k }, { 1, 0 } }),
		Rotation = NumberRange.new(0, 90), RotSpeed = NumberRange.new(-60, 60), ZOffset = 0.35 * k + 0.3,
	})
end

-- motas de luz que suben
function FX.motes(ctx, o)
	local k = ctx.k
	local spread = o.spread or 25
	local e = emitter(ctx, ctx.part, {
		Name = "Motes", Texture = C.VFX[o.tex or "glow"], Rate = o.rate or 5, Lifetime = NumberRange.new(1.2, 2), Speed = NumberRange.new(1.1 * k, 2.4 * k), SpreadAngle = Vector2.new(spread, spread),
		Acceleration = Vector3.new(0, 0.8 * k, 0), Drag = 0.6, Color = colors(o.color or ctx.accent, WHITE), Size = seq({ { 0, 0 }, { 0.2, (o.size or 0.55) * k }, { 1, 0 } }),
		Transparency = seq({ { 0, 0.1 }, { 0.7, 0.3 }, { 1, 1 } }), ZOffset = 0.3 * k + 0.2,
	})
	if o.rainbow then
		rainbow(e, o.rainbow, 0.8)
	end
end

-- rayos de sol detrás (giran despacio)
function FX.sunburst(ctx, o)
	local k = ctx.k
	local t = o.t or 0.45
	local e = emitter(ctx, ctx.fx, {
		Name = "Sunburst", Texture = C.VFX.rays, Rate = 0.8, Lifetime = NumberRange.new(3), Speed = NumberRange.new(0), LockedToPart = true,
		Color = ColorSequence.new(o.color or ctx.accent), Size = NumberSequence.new((o.size or 14) * k),
		Transparency = seq({ { 0, 1 }, { 0.25, t }, { 0.75, t }, { 1, 1 } }), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(10, 16), ZOffset = -(0.5 * k + 0.6),
	})
	if o.rainbow then
		rainbow(e, o.rainbow, 0.8)
	end
end

-- llamas que suben por detrás: se ven arder el borde y la parte de arriba, sin tapar la carta
function FX.flames(ctx, o)
	local k = ctx.k
	emitter(ctx, ctx.part, {
		Name = "Flames", Texture = C.VFX.flame, Rate = o.rate or 14, Lifetime = NumberRange.new(0.6, 1), Speed = NumberRange.new(2.2 * k, 4 * k), SpreadAngle = Vector2.new(10, 10),
		Acceleration = Vector3.new(0, 3 * k, 0), Color = colors(o.hot or rgb(255, 235, 150), o.color or ctx.accent, o.dark or rgb(120, 10, 10)),
		Size = seq({ { 0, 1.3 * k }, { 0.4, 1.8 * k }, { 1, 0.3 * k } }), Transparency = seq({ { 0, 0.25 }, { 0.6, 0.45 }, { 1, 1 } }),
		Rotation = NumberRange.new(-12, 12), LightEmission = 0.85, ZOffset = -(0.3 * k + 0.4),
	})
end

-- ascuas / chispas que saltan hacia arriba
function FX.embers(ctx, o)
	local k = ctx.k
	ctx.sparkle = emitter(ctx, ctx.part, {
		Name = "Embers", Texture = C.VFX.sparkle, Rate = o.rate or 8, Lifetime = NumberRange.new(1, 1.8), Speed = NumberRange.new(2 * k, 4.5 * k), SpreadAngle = Vector2.new(28, 28),
		Acceleration = Vector3.new(0, 2 * k, 0), Drag = 0.8, Color = colors(o.hot or rgb(255, 225, 130), o.color or ctx.accent),
		Size = seq({ { 0, (o.size or 1) * k }, { 1, 0 } }), RotSpeed = NumberRange.new(-120, 120), ZOffset = 0.3 * k + 0.2,
	})
end

-- humo oscuro que envuelve el sobre
function FX.smoke(ctx, o)
	local k = ctx.k
	emitter(ctx, ctx.part, {
		Name = "Smoke", Texture = C.VFX.smoke, Rate = o.rate or 5, Lifetime = NumberRange.new(2, 3), Speed = NumberRange.new(0.7 * k, 1.5 * k), SpreadAngle = Vector2.new(35, 35),
		Color = colors(o.color or ctx.accent, o.dark or BLACK), Size = seq({ { 0, 1.6 * k }, { 1, 3.8 * k } }),
		Transparency = seq({ { 0, 1 }, { 0.2, o.t or 0.5 }, { 0.7, 0.75 }, { 1, 1 } }), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-20, 20),
		LightEmission = o.glow or 0, ZOffset = -(0.3 * k + 0.4),
	})
end

-- círculo en el suelo (anillo o runas) que gira bajo el sobre.
-- Partícula tumbada (perpendicular a su velocidad, que es hacia arriba); casi siempre hay una sola, con un fundido al relevarse
function FX.ground(ctx, o)
	local k = ctx.k
	local t = o.t or 0.25
	local e = emitter(ctx, groundPoint(ctx), {
		Name = "GroundRing", Texture = C.VFX[o.tex or "ring"], Rate = 0.3, Lifetime = NumberRange.new(4), Speed = NumberRange.new(0.05), SpreadAngle = Vector2.new(0, 0), LockedToPart = true,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Color = ColorSequence.new(o.color or ctx.accent), Size = NumberSequence.new((o.size or 6.5) * k),
		Transparency = seq({ { 0, 1 }, { 0.15, t }, { 0.85, t }, { 1, 1 } }), Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(22),
	})
	if o.rainbow then
		rainbow(e, o.rainbow, 0.8)
	end
end

-- ondas de choque que se abren por el suelo
function FX.shock(ctx, o)
	local k = ctx.k
	local e = emitter(ctx, groundPoint(ctx), {
		Name = "Shock", Texture = C.VFX.ring, Rate = 0.7, Lifetime = NumberRange.new(1.5), Speed = NumberRange.new(0.05), SpreadAngle = Vector2.new(0, 0), LockedToPart = true,
		Orientation = Enum.ParticleOrientation.VelocityPerpendicular, Color = ColorSequence.new(o.color or ctx.accent),
		Size = seq({ { 0, 1.5 * k }, { 1, (o.size or 11) * k } }), Transparency = seq({ { 0, 0.15 }, { 0.7, 0.6 }, { 1, 1 } }),
	})
	if o.rainbow then
		rainbow(e, o.rainbow, 0.8)
	end
end

-- polvo de estrellas de galaxia
function FX.galaxy(ctx, o)
	local k = ctx.k
	ctx.sparkle = emitter(ctx, ctx.fx, {
		Name = "Galaxy", Texture = C.VFX.sparkle, Rate = o.rate or 14, Lifetime = NumberRange.new(1.6, 2.6), Speed = NumberRange.new(1.2 * k, 3.2 * k), SpreadAngle = Vector2.new(180, 180), Drag = 1.1,
		Color = colors(WHITE, o.color or ctx.accent, o.color2 or ctx.accent2), Size = seq({ { 0, 0 }, { 0.2, 1.2 * k }, { 1, 0 } }), RotSpeed = NumberRange.new(-90, 90),
	})
	if o.rainbow then
		rainbow(ctx.sparkle, o.rainbow, 0.8)
	end
end

-- líneas horizontales que parpadean sobre la carta (interferencias)
function FX.scan(ctx, o)
	local k = ctx.k
	emitter(ctx, ctx.part, {
		Name = "Scan", Texture = C.VFX.streak, Rate = o.rate or 9, Lifetime = NumberRange.new(0.08, 0.22), Speed = NumberRange.new(0), LockedToPart = true,
		Rotation = NumberRange.new(90), Color = colors(WHITE, o.color or ctx.accent), Size = NumberSequence.new(3.4 * k), Transparency = NumberSequence.new(0.1), ZOffset = 0.35 * k + 0.3,
	})
end

-- Sobre del amanecer: arco de sol naciente y destellos cálidos (si no queda hueco, se refuerzan los que ya tiene)
local DAWN_A, DAWN_B, DAWN_C = rgb(255, 236, 170), rgb(255, 160, 90), rgb(255, 110, 150)
local function dawn(ctx)
	local k = ctx.k
	local r = 1.75 * k
	local a0 = Instance.new("Attachment")
	a0.Name = "DawnA"
	a0.CFrame = CFrame.new(-r, 2 * k, 0) * CFrame.Angles(0, 0, math.rad(90))
	a0.Parent = ctx.part
	local a1 = Instance.new("Attachment")
	a1.Name = "DawnB"
	a1.CFrame = CFrame.new(r, 2 * k, 0) * CFrame.Angles(0, 0, math.rad(90))
	a1.Parent = ctx.part
	local arc = Instance.new("Beam")
	arc.Name = "DawnArc"
	arc.Attachment0 = a0
	arc.Attachment1 = a1
	arc.CurveSize0 = r * 4 / 3
	arc.CurveSize1 = -r * 4 / 3
	arc.Segments = 18
	arc.Width0 = 0.26 * k
	arc.Width1 = 0.26 * k
	arc.FaceCamera = true
	arc.LightEmission = 1
	arc.LightInfluence = 0
	arc.Color = colors(DAWN_C, DAWN_A, DAWN_C)
	arc.Transparency = NumberSequence.new(0.05)
	arc.Parent = ctx.part
	ctx.top = math.max(ctx.top, 3.8)
	if ctx.emitters < ctx.maxEmitters then
		emitter(ctx, ctx.part, {
			Name = "Dawn", Texture = C.VFX.sparkle, Rate = 9, Lifetime = NumberRange.new(0.9, 1.6), Speed = NumberRange.new(1.5 * k, 3.5 * k), SpreadAngle = Vector2.new(40, 40),
			Acceleration = Vector3.new(0, 1.5 * k, 0), Color = colors(DAWN_A, DAWN_B, DAWN_C), Size = seq({ { 0, 0 }, { 0.25, 1.5 * k }, { 1, 0 } }),
			RotSpeed = NumberRange.new(-90, 90), ZOffset = 0.35 * k + 0.3,
		})
	elseif ctx.sparkle then
		ctx.sparkle.Name = "Dawn"
		ctx.sparkle.Rate = math.min(20, ctx.sparkle.Rate * 2.5)
		ctx.sparkle.Color = colors(DAWN_A, DAWN_B, DAWN_C)
	end
end

---------------------------------------------------------------------
-- LAS 14 RAREZAS
-- accent = color de los efectos · body = cuerpo · crimp = sellos · parts = piezas · fx = partículas
-- light = luz · border = borde fino · column = columna de luz corta · face = dibujo de la carta
---------------------------------------------------------------------
local STYLES = {
	{ -- 1 Común: papel mate, borde fino, sin brillo
		body = { mat = PAPER },
		crimp = { color = rgb(128, 128, 128), mat = M.SmoothPlastic, plain = true },
		border = { color = rgb(80, 80, 80), t = 0.03 },
		face = { top = rgb(198, 198, 194), bottom = rgb(128, 128, 128), frame = rgb(105, 105, 105), frameT = 8, q = rgb(238, 238, 238), bright = 1.1 },
	},
	{ -- 2 Poco común: aluminio verde, un destello de vez en cuando
		body = { mat = M.Foil, refl = 0.12 },
		crimp = { color = rgb(195, 228, 195) },
		border = { color = rgb(205, 255, 205), t = 0.03 },
		light = { range = 7, bright = 0.45 },
		parts = { { "seams", { color = rgb(195, 228, 195) } } },
		fx = { { "glint", { rate = 2, size = 1.1 } } },
		face = { frame = rgb(205, 236, 205), frameT = 10, stars = 1, pattern = "hexgrid", patternT = 0.88 },
	},
	{ -- 3 Rara: aluminio azul, aura suave, luz y una gema
		body = { mat = M.Foil, refl = 0.2 },
		border = { color = rgb(190, 225, 255), t = 0.04 },
		light = { range = 11, bright = 0.9 },
		parts = { { "seams", { color = rgb(235, 205, 120) } }, { "gem", { size = 0.5, color = rgb(150, 205, 255) } } },
		fx = { { "aura", { rate = 2.5, size = 4.2, t = 0.72 } }, { "glint", { rate = 3, size = 1.3 } } },
		face = { stars = 1, pattern = "hexgrid", patternT = 0.8, rays = 0.55 },
	},
	{ -- 4 Épica: morado con cantos de neón y chispas que orbitan
		body = { mat = M.Foil, refl = 0.1 },
		border = { color = rgb(225, 185, 255), t = 0.05 },
		light = { range = 13, bright = 1.2 },
		parts = {
			{ "seams", { mat = M.Neon, w = 0.24, color = rgb(205, 130, 255) } },
			{ "orbs", { name = "Spark", n = 2, size = 0.62, radius = 2.35, speed = 1.8, heights = { 0.7, -0.6 }, tilts = { 0.3, -0.3 }, color = rgb(240, 210, 255), trail = true } },
		},
		fx = { { "aura", { size = 4.8, t = 0.66 } }, { "glint", { rate = 4, size = 1.4 } }, { "motes", { rate = 5 } } },
		face = { stars = 2, pattern = "hexgrid", patternT = 0.75, rays = 0.4, double = rgb(225, 185, 255) },
	},
	{ -- 5 Legendaria: oro, sol de ocho puntas, rayos detrás y anillo en el suelo
		body = { mat = M.Neon },
		crimp = { color = rgb(255, 236, 170) },
		border = { color = rgb(255, 245, 190), t = 0.05 },
		light = { range = 16, bright = 1.8 },
		parts = {
			{ "seams", { mat = M.Neon, w = 0.22, color = rgb(255, 236, 150) } },
			{ "gem", { size = 0.95, star = true, color = rgb(255, 225, 110), color2 = rgb(255, 250, 215) } },
		},
		fx = { { "aura", { size = 5.4, t = 0.6 } }, { "glint", { rate = 5, size = 1.5 } }, { "sunburst", { size = 14, t = 0.45 } }, { "ground", { size = 6.4 } } },
		face = { stars = 3, pattern = "hexgrid", patternT = 0.8, rays = 0.25, frameT = 16, double = rgb(255, 250, 215) },
	},
	{ -- 6 Mítica: rojo en llamas, cuernos de fuego, ascuas y anillo
		accent2 = rgb(255, 150, 50),
		body = { mat = M.Neon },
		crimp = { color = rgb(255, 180, 70) },
		border = { color = rgb(255, 190, 120), t = 0.05 },
		light = { range = 17, bright = 2 },
		parts = { { "seams", { mat = M.Neon, w = 0.24, color = rgb(255, 150, 50) } }, { "horns", { color = rgb(255, 120, 40) } } },
		fx = { { "aura", { size = 5.6, t = 0.6 } }, { "flames", { rate = 14 } }, { "embers", { rate = 8 } }, { "ground", { size = 6.8 } } },
		face = { stars = 3, pattern = "hexgrid", patternT = 0.78, rays = 0.3, raysColor = rgb(255, 200, 120), frame = rgb(255, 196, 96), frameT = 16, double = rgb(255, 120, 40) },
	},
	{ -- 7 Divina: marfil con halo, dos alas de luz y columna corta
		accent = rgb(255, 240, 200),
		accent2 = rgb(255, 222, 130),
		body = { mat = M.Neon },
		border = { color = rgb(255, 235, 170), t = 0.05 },
		light = { range = 19, bright = 2.2 },
		column = { h = 12, d = 1.3, t = 0.74 },
		parts = { { "seams", { color = rgb(255, 222, 130) } }, { "halo", { y = 3.2, d = 2.5 } }, { "wings", {} } },
		fx = { { "aura", { size = 6, t = 0.55 } }, { "glint", { rate = 5, size = 1.6 } }, { "sunburst", { size = 15, t = 0.5 } }, { "motes", { rate = 6, size = 0.7 } } },
		face = { stars = 4, runes = 0.5, runesColor = rgb(255, 215, 120), rays = 0.2, frameT = 16, double = rgb(255, 250, 225), q = rgb(255, 255, 255), qStroke = rgb(150, 105, 30) },
	},
	{ -- 8 Celestial: cian con halo, estrella y orbes que giran
		accent2 = rgb(215, 250, 255),
		body = { mat = M.Neon },
		crimp = { color = rgb(235, 250, 255) },
		border = { color = rgb(215, 250, 255), t = 0.05 },
		light = { range = 20, bright = 2.3 },
		column = { h = 13, d = 1.4, t = 0.72 },
		parts = {
			{ "seams", { mat = M.Neon, w = 0.2, color = rgb(225, 252, 255) } },
			{ "halo", { y = 3.25, d = 2.7 } },
			{ "crest", { y = 3.25, len = 1.5 } },
			{ "orbs", { name = "StarOrb", n = 4, size = 0.55, radius = 2.6, speed = 1.3, heights = { 1.1, -0.9, 0.2, -0.2 }, tilts = { 0.25, -0.25 }, color = rgb(225, 252, 255), trail = true } },
		},
		fx = { { "aura", { size = 6.2, t = 0.55 } }, { "glint", { rate = 6, size = 1.6 } }, { "sunburst", { size = 15, t = 0.5 } }, { "motes", { rate = 7, tex = "sparkle", size = 1.1, spread = 180 } } },
		face = { stars = 4, runes = 0.5, pattern = "hexgrid", patternT = 0.82, rays = 0.25, frame = rgb(215, 250, 255), frameT = 16, double = rgb(120, 235, 255) },
	},
	{ -- 9 Primordial: cambia de color como el arcoíris, dos anillos y rayos
		rainbow = { speed = 0.25, sat = 0.75 },
		body = { mat = M.Neon },
		crimp = { color = rgb(255, 255, 255) },
		border = { color = WHITE, t = 0.05 },
		light = { range = 21, bright = 2.4 },
		column = { h = 14, d = 1.4, t = 0.7, rainbow = 0.25 },
		parts = {
			{ "seams", { mat = M.Neon, w = 0.2, color = WHITE } },
			{ "gem", { size = 0.7, color = WHITE } },
			{ "discs", { rings = { { -0.9, 5.2 }, { 1, 4.2 } }, rainbow = 0.25 } },
			{ "orbs", { n = 4, size = 0.5, radius = 2.9, speed = 1.2, heights = { 0.05 }, color = rgb(255, 160, 220), trail = true, rainbow = 0.25 } },
		},
		fx = {
			{ "aura", { size = 6.4, t = 0.55, rainbow = 0.25 } }, { "glint", { rate = 6, size = 1.6, color = WHITE } }, { "sunburst", { size = 16, t = 0.42, rainbow = 0.25 } },
			{ "ground", { tex = "runes", size = 7.2, rainbow = 0.25 } }, { "motes", { rate = 7, tex = "sparkle", size = 1.1, spread = 180, rainbow = 0.25 } },
		},
		face = { alpha = 0.42, top = WHITE, bottom = rgb(70, 70, 86), stars = 5, runes = 0.4, rays = 0.2, frame = WHITE, frameT = 16, double = rgb(255, 235, 150) },
	},
	{ -- 10 Secreta: negro con contorno de neón morado, humo oscuro y haz de luz
		accent = rgb(200, 120, 255),
		accent2 = rgb(120, 60, 200),
		body = { color = rgb(18, 14, 26), mat = M.SmoothPlastic, refl = 0.06 },
		crimp = { color = rgb(200, 120, 255), mat = M.Neon },
		border = { color = rgb(200, 120, 255), t = 0.06 },
		light = { range = 22, bright = 2.4 },
		parts = {
			{ "seams", { mat = M.Neon, w = 0.22 } },
			{ "shards", {} },
			{ "orbs", { name = "VoidShard", n = 3, shape = "block", size = 0.32, tall = 2.6, radius = 2.6, speed = 0.9, heights = { 0.9, -0.4, -1.2 }, spin = 1.2, rot = CFrame.Angles(math.rad(16), 0, math.rad(12)), color = rgb(170, 90, 255) } },
		},
		fx = {
			{ "aura", { size = 6.4, t = 0.55 } }, { "smoke", { color = rgb(60, 25, 95), rate = 5 } }, { "glint", { rate = 5, size = 1.6 } },
			{ "sunburst", { size = 17, t = 0.5 } }, { "ground", { tex = "runes", size = 7.6 } }, { "shock", { size = 11 } },
		},
		face = { top = rgb(72, 36, 112), bottom = rgb(8, 6, 14), frame = rgb(200, 120, 255), frameT = 14, stars = 5, starColor = rgb(225, 180, 255), runes = 0.3, runesColor = rgb(200, 120, 255), rays = 0.5, raysColor = rgb(190, 120, 255), q = rgb(236, 205, 255), qStroke = rgb(40, 10, 70), double = rgb(120, 60, 200) },
	},
	{ -- 11 Godlike: oro anaranjado con corona, llamas, haz y ondas de choque
		accent2 = rgb(255, 228, 120),
		body = { mat = M.Neon },
		crimp = { color = rgb(255, 228, 120) },
		border = { color = rgb(255, 240, 170), t = 0.06 },
		light = { range = 24, bright = 2.8 },
		parts = { { "seams", { mat = M.Neon, w = 0.24, color = rgb(255, 232, 140) } }, { "crown", {} } },
		fx = {
			{ "aura", { size = 6.8, t = 0.5 } }, { "flames", { rate = 14, color = rgb(255, 150, 20), dark = rgb(150, 40, 0) } }, { "embers", { rate = 10 } },
			{ "sunburst", { size = 18, t = 0.4 } }, { "ground", { tex = "runes", size = 8 } }, { "shock", { size = 12 } },
		},
		face = { stars = 6, runes = 0.35, runesColor = rgb(255, 245, 190), rays = 0.15, frame = rgb(255, 238, 150), frameT = 18, double = rgb(255, 120, 20), q = rgb(255, 250, 215), qStroke = rgb(120, 50, 0) },
	},
	{ -- 12 Omnipotente: prisma blanco y oro, cristales flotantes, halo, alas y haz
		accent = rgb(255, 244, 205),
		accent2 = rgb(255, 222, 120),
		rainbow = { speed = 0.18, sat = 0.22 },
		body = { mat = M.Neon },
		crimp = { color = rgb(255, 222, 120), mat = M.Neon },
		border = { color = rgb(255, 235, 160), t = 0.06 },
		light = { range = 25, bright = 3 },
		parts = {
			{ "gem", { size = 0.8, color = WHITE } },
			{ "halo", { y = 3.75, d = 3 } },
			{ "wings", { y = 0.5, feathers = { { 50, 3.4, 1.6 }, { 17, 2.5, 1.4 } }, t = 0.08 } },
			{ "orbs", { name = "Crystal", n = 4, shape = "block", size = 0.38, tall = 2.5, radius = 2.75, speed = 0.8, heights = { 1.7, 0.6, -0.4, -1.3 }, spin = 1.2, rot = CFrame.Angles(math.rad(18), math.rad(45), math.rad(12)), color = WHITE, rainbow = 0.3 } },
		},
		fx = {
			{ "aura", { size = 7, t = 0.5 } }, { "glint", { rate = 7, size = 1.8 } }, { "sunburst", { size = 19, t = 0.4 } },
			{ "motes", { rate = 8, size = 0.7, color = rgb(255, 222, 120) } }, { "ground", { tex = "runes", size = 8.5, color = rgb(255, 222, 120) } }, { "shock", { size = 12, color = WHITE } },
		},
		face = { alpha = 0.18, top = WHITE, bottom = rgb(255, 214, 120), frame = rgb(255, 222, 120), frameT = 18, stars = 6, starColor = rgb(255, 205, 80), runes = 0.3, runesColor = rgb(225, 165, 40), rays = 0.3, raysColor = rgb(255, 215, 110), q = rgb(255, 214, 90), qStroke = rgb(110, 65, 5), double = WHITE },
	},
	{ -- 13 Infinita: violeta que recorre el arcoíris, dos órbitas cruzadas, polvo de galaxia y haz
		accent2 = rgb(255, 120, 220),
		rainbow = { speed = 0.2, sat = 0.75 },
		body = { mat = M.Neon },
		crimp = { color = rgb(228, 218, 255) },
		border = { color = rgb(228, 218, 255), t = 0.06 },
		light = { range = 26, bright = 3 },
		column = { rainbow = 0.2 },
		parts = {
			{ "seams", { mat = M.Neon, w = 0.2, color = rgb(215, 200, 255) } },
			{ "tilted", { d = 5.4, tilts = { { 0, 35 }, { 24, -35 } }, rainbow = 0.2 } },
			{ "infinity", { rainbow = 0.2 } },
			{ "orbs", { n = 4, size = 0.5, radius = 2.7, speed = 1.6, tilts = { 0.61, -0.61 }, color = rgb(215, 200, 255), trail = true, rainbow = 0.2 } },
		},
		fx = {
			{ "smoke", { color = rgb(120, 90, 255), dark = rgb(40, 20, 120), t = 0.72, glow = 0.8, rate = 3 } }, { "galaxy", { rainbow = 0.2 } }, { "glint", { rate = 6, size = 1.7 } },
			{ "sunburst", { size = 19, t = 0.4, rainbow = 0.2 } }, { "ground", { tex = "runes", size = 9, rainbow = 0.2 } }, { "shock", { size = 13 } },
		},
		face = { alpha = 0.38, top = WHITE, bottom = rgb(30, 22, 70), stars = 7, runes = 0.3, pattern = "hexgrid", patternT = 0.78, rays = 0.25, frame = rgb(228, 218, 255), frameT = 18, double = rgb(255, 120, 220) },
	},
	{ -- 14 ???: vacío negro que parpadea, copias en rojo y cian, interferencias y haz
		accent = rgb(255, 40, 60),
		accent2 = WHITE,
		glitch = true,
		body = { color = rgb(6, 6, 8), mat = M.SmoothPlastic },
		crimp = { color = rgb(255, 40, 60), mat = M.Neon },
		border = { color = WHITE, t = 0.06 },
		light = { range = 26, bright = 3 },
		parts = {
			{ "seams", { mat = M.Neon, w = 0.12, color = WHITE } },
			{ "ghosts", {} },
			{ "bars", {} },
			{ "orbs", { name = "VoidCube", n = 3, shape = "block", size = 0.42, radius = 2.6, speed = 1.3, heights = { 1.2, -0.2, -1.3 }, spin = 3, rot = CFrame.Angles(math.rad(30), math.rad(30), 0), colors = { rgb(255, 40, 60), WHITE, rgb(255, 40, 60) }, glitch = true } },
		},
		fx = {
			{ "aura", { size = 7, t = 0.55 } }, { "smoke", { color = rgb(30, 0, 6), rate = 5 } }, { "scan", { rate = 9 } },
			{ "embers", { rate = 10, hot = WHITE, size = 1.1 } }, { "ground", { tex = "runes", size = 9 } }, { "shock", { size = 13 } },
		},
		face = { text = "???", top = rgb(46, 0, 8), bottom = BLACK, frame = rgb(255, 40, 60), frameT = 14, stars = 7, starColor = rgb(255, 60, 80), pattern = "hexgrid", patternT = 0.7, patternColor = rgb(255, 40, 60), rays = 0.45, raysColor = rgb(255, 40, 60), q = WHITE, qStroke = rgb(255, 20, 40), double = WHITE },
	},
}
PackStyle.STYLES = STYLES

-- Color de los efectos de una rareza (la Secreta y la ??? son casi negras: usan su acento)
function PackStyle.accent(r)
	r = math.clamp(r, 1, #STYLES)
	return STYLES[r].accent or C.RARITIES[r].color
end

---------------------------------------------------------------------
-- Cara de la carta: degradado, marco, estrellas, "?" y el peso (siempre legible)
---------------------------------------------------------------------
local function image(parent, name, key, color, transparency, z)
	local img = Instance.new("ImageLabel")
	img.Name = name
	img.BackgroundTransparency = 1
	img.Image = C.VFX[key]
	img.ImageColor3 = color
	img.ImageTransparency = transparency
	img.ZIndex = z
	img.Parent = parent
	return img
end

local function buildFace(ctx, normal)
	local f = ctx.style.face or {}
	local pack = ctx.pack
	local top = f.top or C.RARITIES[ctx.r].color
	local bottom = f.bottom or Color3.new(top.R * 0.35, top.G * 0.35, top.B * 0.35)
	local frameColor = f.frame or rgb(255, 225, 130)
	local frameT = f.frameT or 14
	local sg = Instance.new("SurfaceGui")
	sg.Name = "Face"
	sg.Face = normal
	sg.CanvasSize = Vector2.new(300, 400)
	sg.LightInfluence = 0
	sg.Brightness = f.bright or 1.5
	sg.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	local bg = Instance.new("Frame")
	bg.Name = "Bg"
	bg.Size = UDim2.fromScale(1, 1)
	bg.BorderSizePixel = 0
	bg.BackgroundColor3 = WHITE
	bg.BackgroundTransparency = f.alpha or 0
	bg.ClipsDescendants = true
	local grad = Instance.new("UIGradient")
	grad.Color = ColorSequence.new(top, bottom)
	grad.Rotation = 90
	grad.Parent = bg
	bg.Parent = sg
	-- rayos detrás del "?"
	if f.rays then
		local rays = image(bg, "Rays", "rays", f.raysColor or rgb(255, 240, 200), f.rays, 2)
		rays.Size = UDim2.fromScale(1.5, 1.125)
		rays.Position = UDim2.fromScale(0.5, 0.4)
		rays.AnchorPoint = Vector2.new(0.5, 0.5)
	end
	-- trama de fondo
	if f.pattern then
		local pattern = image(bg, "Pattern", f.pattern, f.patternColor or WHITE, f.patternT or 0.82, 3)
		pattern.ScaleType = Enum.ScaleType.Tile
		pattern.TileSize = UDim2.fromOffset(120, 120)
		pattern.Size = UDim2.fromScale(1, 1)
	end
	-- círculo de runas (rarezas altas)
	if f.runes then
		local runes = image(bg, "Runes", "runes", f.runesColor or WHITE, f.runes, 4)
		runes.Size = UDim2.fromOffset(270, 270)
		runes.Position = UDim2.fromScale(0.5, 0.4)
		runes.AnchorPoint = Vector2.new(0.5, 0.5)
	end
	-- relieve con roseta (desde Rara)
	if ctx.r >= 3 then
		local relief = image(bg, "Relief", "carved", frameColor, 0.3, 5)
		relief.Size = UDim2.fromScale(1, 1)
	end
	-- brillo en diagonal
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.BackgroundColor3 = WHITE
	shine.BorderSizePixel = 0
	shine.Size = UDim2.fromScale(1, 1)
	shine.ZIndex = 6
	shine.Visible = ctx.r >= 2
	local sgrad = Instance.new("UIGradient")
	sgrad.Rotation = 35
	sgrad.Transparency = seq({ { 0, 1 }, { 0.42, 1 }, { 0.5, 0.65 }, { 0.58, 1 }, { 1, 1 } })
	sgrad.Parent = shine
	shine.Parent = bg
	-- marco: el trazo queda hacia fuera, así que la caja va metida su grosor
	local border = Instance.new("Frame")
	border.Name = "Border"
	border.BackgroundTransparency = 1
	border.AnchorPoint = Vector2.new(0.5, 0.5)
	border.Position = UDim2.fromScale(0.5, 0.5)
	border.Size = UDim2.new(1, -2 * frameT, 1, -2 * frameT)
	border.ZIndex = 7
	local st = Instance.new("UIStroke")
	st.Color = frameColor
	st.Thickness = frameT
	st.LineJoinMode = Enum.LineJoinMode.Miter
	st.Parent = border
	border.Parent = bg
	if f.double then
		local inner = Instance.new("Frame")
		inner.Name = "Border2"
		inner.BackgroundTransparency = 1
		inner.AnchorPoint = Vector2.new(0.5, 0.5)
		inner.Position = UDim2.fromScale(0.5, 0.5)
		inner.Size = UDim2.new(1, -2 * frameT - 14, 1, -2 * frameT - 14)
		inner.ZIndex = 7
		local st2 = Instance.new("UIStroke")
		st2.Color = f.double
		st2.Thickness = 3
		st2.Parent = inner
		inner.Parent = bg
	end
	-- estrellas: cuantas más, más rara
	local stars = f.stars or 0
	if stars > 0 then
		local row = Instance.new("Frame")
		row.Name = "Stars"
		row.BackgroundTransparency = 1
		row.AnchorPoint = Vector2.new(0.5, 0)
		row.Position = UDim2.new(0.5, 0, 0, frameT - 6)
		row.Size = UDim2.new(1, 0, 0, 64)
		row.ZIndex = 8
		local layout = Instance.new("UIListLayout")
		layout.FillDirection = Enum.FillDirection.Horizontal
		layout.HorizontalAlignment = Enum.HorizontalAlignment.Center
		layout.VerticalAlignment = Enum.VerticalAlignment.Center
		layout.Padding = UDim.new(0, -30)
		layout.Parent = row
		for _ = 1, stars do
			local star = image(row, "Star", "sparkle", f.starColor or rgb(255, 240, 170), 0, 8)
			star.Size = UDim2.fromOffset(64, 64)
		end
		row.Parent = bg
	end
	-- el "?"
	local q = Instance.new("TextLabel")
	q.Name = "Mark"
	q.BackgroundTransparency = 1
	q.Size = UDim2.new(1, -2 * frameT, 0.5, 0)
	q.AnchorPoint = Vector2.new(0.5, 0)
	q.Position = UDim2.fromScale(0.5, 0.17)
	q.Font = Enum.Font.LuckiestGuy
	q.TextScaled = true
	q.Text = f.text or "?"
	q.TextColor3 = f.q or WHITE
	q.ZIndex = 9
	local qs = Instance.new("UIStroke")
	qs.Color = f.qStroke or rgb(60, 30, 10)
	qs.Thickness = 5
	qs.Parent = q
	q.Parent = bg
	-- el peso, sobre una placa oscura para que se lea con cualquier fondo
	local plate = Instance.new("Frame")
	plate.Name = "KgPlate"
	plate.AnchorPoint = Vector2.new(0.5, 0.5)
	plate.Position = UDim2.fromScale(0.5, 0.815)
	plate.Size = UDim2.new(0.8, -frameT, 0.16, 0)
	plate.BackgroundColor3 = BLACK
	plate.BackgroundTransparency = 0.45
	plate.BorderSizePixel = 0
	plate.ZIndex = 9
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0.3, 0)
	corner.Parent = plate
	local w = Instance.new("TextLabel")
	w.Name = "Kg"
	w.BackgroundTransparency = 1
	w.Size = UDim2.new(1, -12, 1, -8)
	w.AnchorPoint = Vector2.new(0.5, 0.5)
	w.Position = UDim2.fromScale(0.5, 0.5)
	w.Font = Enum.Font.LuckiestGuy
	w.TextScaled = true
	w.Text = pack.kg .. " KG"
	w.TextColor3 = rgb(255, 232, 150)
	w.ZIndex = 10
	local ws = Instance.new("UIStroke")
	ws.Color = rgb(40, 20, 5)
	ws.Thickness = 3
	ws.Parent = w
	w.Parent = plate
	plate.Parent = bg
	sg.Parent = ctx.part
end

---------------------------------------------------------------------
-- Construcción de un sobre
---------------------------------------------------------------------
-- part = cuerpo del sobre (3 × 4 × 0.5 × k, anclado, todavía sin colocar) · devuelve { top, accent, emitters, parts }
function PackStyle.build(pack, part, k)
	local r = math.clamp(pack.rarity, 1, #STYLES)
	local st = STYLES[r]
	local rarity = C.RARITIES[r]
	local maxEmitters = PackStyle.budget(r)
	local ctx = {
		pack = pack, part = part, k = k, r = r, style = st,
		accent = st.accent or rarity.color, accent2 = st.accent2 or WHITE,
		emitters = 0, parts = 0, maxEmitters = maxEmitters,
		top = PackStyle.HALF, -- punto más alto de los adornos (encima va el cartel)
		crest = PackStyle.HALF, -- punto más alto del adorno central (de ahí nace el haz de luz)
	}
	local body = st.body or {}
	part.Color = body.color or rarity.color
	part.Material = body.mat or M.Foil
	part.Reflectance = body.refl or 0
	local fx = Instance.new("Attachment")
	fx.Name = "PackFX"
	fx.Parent = part
	ctx.fx = fx
	crimps(ctx)
	for _, f in ipairs(st.parts or {}) do
		PARTS[f[1]](ctx, f[2])
	end
	if r >= C.ANNOUNCE_BIG_FROM then
		column(ctx, st.column or {}, true)
	elseif st.column then
		column(ctx, st.column, false)
	end
	if st.border then
		local box = Instance.new("SelectionBox")
		box.Name = "Border"
		box.Adornee = part
		box.LineThickness = st.border.t
		box.Color3 = st.border.color
		box.SurfaceTransparency = 1
		box.Parent = part
	end
	if st.light then
		local light = Instance.new("PointLight")
		light.Color = ctx.accent
		light.Range = math.min(32, st.light.range + 2 * k)
		light.Brightness = st.light.bright
		light.Shadows = false
		light.Parent = part
		if st.rainbow then
			rainbow(light, st.rainbow.speed, st.rainbow.sat)
		end
	end
	for _, f in ipairs(st.fx or {}) do
		FX[f[1]](ctx, f[2])
	end
	if pack.dawn then
		dawn(ctx)
	end
	if st.rainbow then
		rainbow(part, st.rainbow.speed, st.rainbow.sat)
	end
	if st.glitch then
		tag(part, "FxGlitch")
	end
	for _, face in ipairs({ Enum.NormalId.Front, Enum.NormalId.Back }) do
		buildFace(ctx, face)
	end
	part:SetAttribute("TopY", ctx.top)
	PackStyle.remember(part)
	return { top = ctx.top, accent = ctx.accent, emitters = ctx.emitters, parts = ctx.parts }
end

-- Guarda la transparencia original de cada pieza (para poder ocultar y volver a mostrar)
function PackStyle.remember(part)
	if part:GetAttribute("BaseT") == nil then
		part:SetAttribute("BaseT", part.Transparency)
	end
	for _, d in ipairs(part:GetDescendants()) do
		if (d:IsA("BasePart") or d:IsA("Decal")) and d:GetAttribute("BaseT") == nil then
			d:SetAttribute("BaseT", d.Transparency)
		end
	end
end

-- Oculta o muestra el sobre entero con todos sus adornos; al mostrar, cada pieza recupera su transparencia original
function PackStyle.setVisible(part, on)
	local function apply(d)
		if d:IsA("BasePart") or d:IsA("Decal") then
			local base = d:GetAttribute("BaseT")
			if base == nil then
				base = d.Transparency
				d:SetAttribute("BaseT", base)
			end
			d.Transparency = on and base or 1
			if d:IsA("BasePart") then
				-- el parpadeo del cliente no debe volver a enseñar una pieza oculta
				if not on and CollectionService:HasTag(d, "FxGlitch") then
					CollectionService:RemoveTag(d, "FxGlitch")
					d:SetAttribute("GlitchOff", true)
				elseif on and d:GetAttribute("GlitchOff") then
					d:SetAttribute("GlitchOff", nil)
					CollectionService:AddTag(d, "FxGlitch")
				end
			end
		elseif d:IsA("SelectionBox") then
			d.Visible = on
		elseif d:IsA("ParticleEmitter") or d:IsA("Beam") or d:IsA("Trail") or d:IsA("PointLight") or d:IsA("SurfaceGui") or d:IsA("BillboardGui") then
			d.Enabled = on
		end
	end
	apply(part)
	for _, d in ipairs(part:GetDescendants()) do
		apply(d)
	end
end

-- Posición de una pieza que orbita (sin cliente se queda aquí; con cliente, él la mueve)
local function orbitCFrame(part, orb)
	local radius = orb:GetAttribute("OrbitRadius") or 0
	local phase = orb:GetAttribute("OrbitPhase") or 0
	local tilt = orb:GetAttribute("OrbitTilt") or 0
	local height = orb:GetAttribute("OrbitHeight") or 0
	local offset = CFrame.Angles(tilt, 0, 0) * Vector3.new(math.cos(phase) * radius, 0, math.sin(phase) * radius)
	return CFrame.new(part.Position + offset + Vector3.new(0, height, 0)) * orb.CFrame.Rotation
end

-- Coloca lo que NO va soldado (columna de luz, piezas que orbitan) y endereza los efectos de suelo.
-- groundY = altura del suelo bajo el sobre; nil si lo lleva alguien (se usa el pie del sobre)
function PackStyle.settle(part, groundY)
	local c = part.Position
	local k = part:GetAttribute("K") or 1
	local baseY = groundY or (c.Y - PackStyle.HALF * k)
	for _, ch in ipairs(part:GetChildren()) do
		if ch:IsA("BasePart") and ch.Anchored then
			if ch.Name == "Beam" then
				-- nace encima del sobre (siguiendo su inclinación) y sube recta
				local foot = part.CFrame * Vector3.new(0, ch:GetAttribute("Base") or PackStyle.HALF * k, 0)
				ch.CFrame = CFrame.new(foot.X, foot.Y + ch.Size.X / 2, foot.Z) * UPRIGHT
			elseif CollectionService:HasTag(ch, "FxOrbit") then
				ch.CFrame = orbitCFrame(part, ch)
			end
		elseif ch:IsA("Attachment") and ch:GetAttribute("Ground") then
			ch.CFrame = part.CFrame:ToObjectSpace(CFrame.new(c.X, baseY + ch:GetAttribute("Ground"), c.Z))
		end
	end
end

-- Efecto mientras alguien lleva el sobre: estela y, si cabe en el presupuesto, chispas
function PackStyle.carryFx(pack, on)
	local part = pack.part
	if not part then
		return
	end
	for _, name in ipairs({ "CarryFX", "CarryLow", "CarryTrail" }) do
		local old = part:FindFirstChild(name)
		if old then
			old:Destroy()
		end
	end
	if not on then
		return
	end
	local k = part:GetAttribute("K") or 1
	local r = math.clamp(pack.rarity, 1, #STYLES)
	local accent = PackStyle.accent(r)
	-- dos puntos sobre el eje del sobre (no se mueven al girar): entre ellos se dibuja la estela
	local high = Instance.new("Attachment")
	high.Name = "CarryFX"
	high.Position = Vector3.new(0, 1.9 * k, 0)
	local low = Instance.new("Attachment")
	low.Name = "CarryLow"
	low.Position = Vector3.new(0, -1.9 * k, 0)
	local tr = Instance.new("Trail")
	tr.Name = "CarryTrail"
	tr.Attachment0 = high
	tr.Attachment1 = low
	tr.Lifetime = 0.45
	tr.MinLength = 0.1
	tr.FaceCamera = true
	tr.LightEmission = 1
	tr.LightInfluence = 0
	tr.Color = colors(WHITE, accent)
	tr.Transparency = seq({ { 0, 0.35 }, { 1, 1 } })
	tr.WidthScale = seq({ { 0, 1 }, { 1, 0.2 } })
	local count = 0
	for _, d in ipairs(part:GetDescendants()) do
		if d:IsA("ParticleEmitter") then
			count += 1
		end
	end
	if count < PackStyle.budget(r) then
		local pe = Instance.new("ParticleEmitter")
		pe.Name = "CarrySparks"
		pe.Texture = C.VFX.sparkle
		pe.Rate = 18
		pe.Lifetime = NumberRange.new(0.5, 1)
		pe.Speed = NumberRange.new(2, 6)
		pe.SpreadAngle = Vector2.new(180, 180)
		pe.LightEmission = 1
		pe.LightInfluence = 0
		pe.Color = colors(accent, WHITE)
		pe.Size = seq({ { 0, 1.3 * k }, { 1, 0 } })
		pe.RotSpeed = NumberRange.new(-120, 120)
		pe.Parent = high
	end
	high.Parent = part
	low.Parent = part
	tr.Parent = part
end

---------------------------------------------------------------------
-- NIDOS: los sobres de cada zona descansan juntos en un nido de su mitología
---------------------------------------------------------------------
-- Uno en el centro y el resto en un anillo; el hueco del anillo mira a la entrada para que se vea el del centro
function PackStyle.spots(centre)
	local n = C.PACKS_PER_ZONE
	local list = { Vector3.new(centre.X, centre.Y, centre.Z) }
	local ring = n - 1
	for j = 0, ring - 1 do
		local a = math.rad(-90 + 180 / ring + j * 360 / ring)
		table.insert(list, centre + Vector3.new(math.cos(a), 0, math.sin(a)) * C.NEST_RADIUS)
	end
	return list
end

-- Colores propios de cada nido (lo demás sale de la paleta de la muralla de su zona)
local NESTS = {
	{ -- griega: nido dorado de laurel
		twigA = rgb(190, 148, 78), twigAMat = M.Wood, twigB = rgb(236, 192, 88), twigBMat = M.Foil, twigC = rgb(112, 160, 66), twigCMat = M.Grass,
		bed = rgb(206, 178, 116), bedMat = M.Sand, lining = rgb(240, 226, 186), liningMat = M.Fabric, skin = "meander",
	},
	{ -- celta: ramas con musgo
		twigA = rgb(92, 64, 40), twigAMat = M.Wood, twigB = rgb(64, 46, 30), twigBMat = M.Wood, twigC = rgb(72, 140, 60), twigCMat = M.Grass,
		bed = rgb(58, 88, 52), bedMat = M.Grass, lining = rgb(112, 136, 78), liningMat = M.Grass, skin = "carved",
	},
	{ -- egipcia: cuenco de oro y lapislázuli
		twigA = rgb(214, 172, 92), twigAMat = M.Wood, twigB = rgb(240, 196, 92), twigBMat = M.Foil, twigC = rgb(36, 70, 175), twigCMat = M.Foil,
		bed = rgb(232, 200, 134), bedMat = M.Sand, lining = rgb(250, 228, 176), liningMat = M.Sand, skin = "meander",
		bowlA = rgb(240, 196, 92), bowlAMat = M.Foil, bowlB = rgb(36, 70, 175), bowlBMat = M.Foil,
	},
	{ -- azteca: piedra tallada y jade
		twigA = rgb(112, 92, 62), twigAMat = M.Wood, twigB = rgb(132, 120, 96), twigBMat = M.Rock, twigC = rgb(50, 170, 140), twigCMat = M.Marble,
		bed = rgb(88, 116, 66), bedMat = M.Grass, lining = rgb(140, 152, 100), liningMat = M.Grass, skin = "carved",
	},
	{ -- babilónica: ladrillo vidriado azul y oro
		twigA = rgb(226, 190, 96), twigAMat = M.Foil, twigB = rgb(162, 122, 62), twigBMat = M.Wood, twigC = rgb(60, 110, 225), twigCMat = M.Foil,
		bed = rgb(188, 160, 104), bedMat = M.Sand, lining = rgb(226, 202, 150), liningMat = M.Sand, skin = "bricks",
	},
	{ -- nórdica: hielo y runas
		twigA = rgb(70, 58, 96), twigAMat = M.Wood, twigB = rgb(48, 38, 76), twigBMat = M.Basalt, twigC = rgb(160, 225, 255), twigCMat = M.Ice,
		bed = rgb(214, 226, 246), bedMat = M.Snow, lining = rgb(186, 214, 246), liningMat = M.Ice, skin = "hexgrid",
	},
}

-- Adornos de cada mitología. nb = ayudantes del nido (at, piece, egg, ball, block)
local ORNAMENTS = {}

ORNAMENTS[1] = function(nb, t) -- huevos de mármol, hojas de laurel y bayas doradas
	nb.egg(54, 11.5, 2.0, rgb(246, 242, 232), M.Marble)
	nb.egg(126, 11.3, 1.7, rgb(246, 242, 232), M.Marble)
	nb.egg(198, 11.6, 1.5, t.trim, t.trimMat)
	for j = 0, 9 do
		local lean = j % 2 == 0 and 24 or -24
		nb.block(j * 36 + 12, 13.5, 2.3, Vector3.new(0.85, 0.12, 2), j % 2 == 0 and rgb(104, 156, 62) or rgb(246, 206, 98), j % 2 == 0 and M.Grass or M.Foil,
			CFrame.Angles(0, math.rad(lean), 0) * CFrame.Angles(math.rad(8), 0, 0), false)
	end
	for j = 0, 3 do
		nb.ball(j * 90 + 48, 14.1, 2.3, 0.55, rgb(255, 222, 120), M.Neon)
	end
end

ORNAMENTS[2] = function(nb, t) -- musgo, menhires con runas y setas que brillan
	for j = 0, 6 do
		nb.ball(j * 51.4 + 8, 13.5, 1.75, 1.3 + (j % 3) * 0.25, j % 2 == 0 and rgb(70, 140, 60) or rgb(96, 160, 70), M.Grass)
	end
	for _, a in ipairs({ 54, 126, 198 }) do
		local stone = nb.block(a, 11.7, 1.63, Vector3.new(1.05, 1.85, 1.5), rgb(104, 112, 106), M.Slate, CFrame.Angles(0, 0, math.rad(a % 4 - 2)), true)
		nb.piece({ Name = "Rune", Size = Vector3.new(0.08, 0.95, 0.6), CFrame = stone.CFrame * CFrame.new(-0.55, 0.15, 0), Color = t.glow, Material = M.Neon })
	end
	nb.ball(-90, 12.2, 1.05, 0.7, t.glow, M.Neon)
	nb.ball(-18, 12, 1.05, 0.6, t.glow, M.Neon)
end

ORNAMENTS[3] = function(nb, t) -- piramidiones en las esquinas y huevos de escarabeo
	for j = 0, 3 do
		local a = j * 90 + 45
		nb.block(a, 13.9, 1.78, Vector3.new(1.5, 0.55, 1.5), t.pillar, t.pillarMat, nil, true)
		nb.block(a, 13.9, 2.28, Vector3.new(0.9, 0.46, 0.9), GOLD, M.Foil, nil, false)
	end
	nb.egg(54, 11.5, 1.9, rgb(36, 70, 175), M.Foil)
	nb.egg(126, 11.4, 1.6, rgb(240, 196, 92), M.Foil)
	nb.egg(198, 11.5, 1.6, rgb(30, 150, 160), M.Foil)
	nb.ball(-90, 12.4, 1.0, 0.6, t.glow, M.Neon)
end

ORNAMENTS[4] = function(nb, t) -- piedras escalonadas, huevos de jade y plumas rojas
	for j = 0, 3 do
		local a = j * 90 + 45
		nb.block(a, 13.9, 1.72, Vector3.new(2, 0.6, 2), t.pillar, t.pillarMat, nil, true)
		nb.block(a, 13.9, 2.27, Vector3.new(1.2, 0.5, 1.2), t.trim, t.trimMat, nil, false)
	end
	nb.egg(54, 11.5, 1.9, rgb(60, 180, 145), M.Marble)
	nb.egg(126, 11.4, 1.6, rgb(60, 180, 145), M.Marble)
	nb.egg(198, 11.5, 1.6, rgb(40, 150, 120), M.Marble)
	for j = 0, 4 do
		nb.block(j * 72 - 90, 14.3, 2.15, Vector3.new(2, 0.1, 0.55), j % 2 == 0 and t.banner or rgb(60, 205, 190), M.Fabric, CFrame.Angles(0, 0, math.rad(14)), false)
	end
end

ORNAMENTS[5] = function(nb, t) -- huevos de oro y orbes de lapislázuli sobre el borde dorado
	nb.egg(54, 11.5, 1.9, GOLD, M.Foil)
	nb.egg(126, 11.4, 1.6, GOLD, M.Foil)
	nb.egg(198, 11.5, 1.7, rgb(60, 110, 225), M.Foil)
	for j = 0, 5 do
		nb.ball(j * 60 + 30, 14, 2.2, 0.75, j % 2 == 0 and rgb(70, 130, 255) or t.glow, M.Neon)
	end
end

ORNAMENTS[6] = function(nb, t) -- cristales de hielo, piedras rúnicas y huevos de escarcha
	for j = 0, 5 do
		nb.block(j * 60 + 20, 13.8, 1.62, Vector3.new(0.75, 1.6, 0.75), rgb(165, 228, 255), M.Ice, CFrame.Angles(math.rad(14), math.rad(45), math.rad(j % 2 == 0 and 12 or -12)), false, 0.2)
	end
	for _, a in ipairs({ 54, 126, 198 }) do
		local stone = nb.block(a, 11.7, 1.6, Vector3.new(0.95, 1.8, 1.4), rgb(46, 38, 70), M.Basalt, CFrame.Angles(0, 0, math.rad(a % 4 - 2)), true)
		nb.piece({ Name = "Rune", Size = Vector3.new(0.08, 0.95, 0.6), CFrame = stone.CFrame * CFrame.new(-0.5, 0.15, 0), Color = t.glow, Material = M.Neon })
	end
	nb.egg(-90, 12.3, 1.3, rgb(225, 240, 255), M.Ice)
	nb.egg(-18, 12, 1.5, rgb(225, 240, 255), M.Ice)
end

-- Construye el nido de la zona i → carpeta Nest<i> dentro de workspace.World
function PackStyle.buildNest(i, centre)
	local root = G.World.getRoot()
	local old = root:FindFirstChild("Nest" .. i)
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "Nest" .. i
	folder.Parent = root
	local themes = G.World.WALL_THEMES
	local t = themes[i] or themes[#themes]
	local N = NESTS[i] or NESTS[#NESTS]
	local rng = Random.new(4200 + i)
	local floorY = PackStyle.FLOOR_Y
	local bedTop = floorY + PackStyle.NEST_BED
	local base = CFrame.new(centre.X, 0, centre.Z)
	local nb = { count = 0 }

	-- punto del nido en polares: X local = hacia fuera, Z local = tangente, y = altura absoluta
	function nb.at(angle, radius, y)
		return base * CFrame.Angles(0, -math.rad(angle), 0) * CFrame.new(radius, y, 0)
	end
	-- pieza decorativa: nadie choca con ella (los jugadores y el guardián pasan a través)
	function nb.piece(props)
		props.Parent = folder
		props.CanCollide = false
		props.CanQuery = false
		props.CanTouch = false
		if props.CastShadow == nil then
			props.CastShadow = false
		end
		nb.count += 1
		return G.World.part(props)
	end
	function nb.ball(angle, radius, y, d, color, mat)
		return nb.piece({ Name = "Orb", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = nb.at(angle, radius, y), Color = color, Material = mat })
	end
	function nb.egg(angle, radius, d, color, mat)
		return nb.piece({ Name = "Egg", Shape = Enum.PartType.Ball, Size = Vector3.new(d, d, d), CFrame = nb.at(angle, radius, bedTop + d / 2 - 0.3), Color = color, Material = mat, CastShadow = true })
	end
	function nb.block(angle, radius, y, size, color, mat, rot, shadow, transparency)
		return nb.piece({ Name = "Ornament", Size = size, CFrame = nb.at(angle, radius, y) * (rot or CFrame.new()), Color = color, Material = mat, CastShadow = shadow == true, Transparency = transparency or 0 })
	end

	-- lecho: disco de fondo y forro más claro donde descansan los sobres
	local bed = nb.piece({ Name = "NestBed", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.5, 27, 27), CFrame = base * CFrame.new(0, floorY + 0.25, 0) * UPRIGHT, Color = N.bed, Material = N.bedMat })
	G.World.skin(bed, "grass", 5, N.lining, 0.3, { Enum.NormalId.Right })
	local lining = nb.piece({ Name = "NestLining", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.3, 21.5, 21.5), CFrame = base * CFrame.new(0, bedTop - 0.15, 0) * UPRIGHT, Color = N.lining, Material = N.liningMat })
	-- disco de runas que brilla en el centro (el cliente lo hace girar)
	local disc = nb.piece({ Name = "NestRunes", Shape = Enum.PartType.Cylinder, Size = Vector3.new(0.1, 9.5, 9.5), CFrame = base * CFrame.new(0, bedTop + 0.03, 0) * UPRIGHT, Color = t.glow, Material = M.Neon, Transparency = 0.4 })
	local decal = Instance.new("Decal")
	decal.Name = "Runes"
	decal.Texture = C.VFX.runes
	decal.Face = Enum.NormalId.Right
	decal.Color3 = WHITE
	decal.Parent = disc
	tag(disc, "FxSpin", { SpinSpeed = 0.35, SpinAxis = "X" })
	-- una sola luz y un solo emisor de chispas suaves para todo el nido
	local glowAt = Instance.new("Attachment")
	glowAt.Name = "NestGlow"
	glowAt.Position = Vector3.new(2.2, 0, 0) -- 2.2 studs por encima del disco (su X local es la vertical)
	glowAt.Parent = disc
	local light = Instance.new("PointLight")
	light.Color = t.glow
	light.Range = 24
	light.Brightness = 1.3
	light.Shadows = false
	light.Parent = glowAt
	local sparks = Instance.new("ParticleEmitter")
	sparks.Name = "NestSparkles"
	sparks.Texture = C.VFX.sparkle
	sparks.Rate = 9
	sparks.Lifetime = NumberRange.new(1.6, 2.6)
	sparks.Speed = NumberRange.new(0.8, 2.2)
	sparks.SpreadAngle = Vector2.new(25, 25)
	sparks.EmissionDirection = Enum.NormalId.Right -- hacia arriba (X local del disco)
	sparks.Acceleration = Vector3.new(0, 0.5, 0)
	sparks.LightEmission = 1
	sparks.LightInfluence = 0
	sparks.Color = colors(t.glow, WHITE)
	sparks.Size = seq({ { 0, 0 }, { 0.2, 1.3 }, { 1, 0 } })
	sparks.RotSpeed = NumberRange.new(-60, 60)
	sparks.Parent = lining -- salen de todo el lecho, sin salirse del nido

	-- cuenco: doce bloques en corro, con el labio hacia fuera
	local bowlA, bowlAMat = N.bowlA or t.body, N.bowlAMat or t.bodyMat
	local bowlB, bowlBMat = N.bowlB or t.panel, N.bowlBMat or t.bodyMat
	for j = 0, 11 do
		local block = nb.piece({
			Name = "NestBowl", Size = Vector3.new(2.4, 0.95, 7.5), CFrame = nb.at(j * 30, 13.6, floorY + 0.5) * CFrame.Angles(0, 0, math.rad(18)),
			Color = j % 2 == 0 and bowlA or bowlB, Material = j % 2 == 0 and bowlAMat or bowlBMat, CastShadow = true,
		})
		G.World.skin(block, N.skin, 2.4, t.trim, 0.15, { Enum.NormalId.Top })
		if i == 5 and j % 2 == 0 then
			-- remate dorado de los ladrillos vidriados
			nb.piece({ Name = "NestCap", Size = Vector3.new(2.5, 0.2, 7.3), CFrame = block.CFrame * CFrame.new(0, 0.57, 0), Color = GOLD, Material = M.Foil })
		end
	end

	-- borde tejido: ramas cruzadas en tres capas (unas suben, otras bajan, otras sobresalen)
	local function twig(angle, radius, y, len, dia, yaw, pitch, color, mat)
		nb.piece({
			Name = "Twig", Shape = Enum.PartType.Cylinder, Size = Vector3.new(len, dia, dia),
			CFrame = nb.at(angle, radius, y) * CFrame.Angles(0, math.rad(90 + yaw), 0) * CFrame.Angles(0, 0, math.rad(pitch)),
			Color = color, Material = mat, CastShadow = true,
		})
	end
	local nA, nC = 13, 10
	for j = 0, nA - 1 do
		local a = j * 360 / nA
		twig(a + rng:NextNumber(-3, 3), 13 + rng:NextNumber(-0.25, 0.25), floorY + 1.05, 8.5, 0.6, rng:NextNumber(-7, 7), 9 + rng:NextNumber(-2, 2),
			N.twigA:Lerp(BLACK, rng:NextNumber(0, 0.18)), N.twigAMat)
		twig(a + 180 / nA + rng:NextNumber(-3, 3), 13.8 + rng:NextNumber(-0.2, 0.2), floorY + 1.25, 8.5, 0.55, rng:NextNumber(-7, 7), -9 + rng:NextNumber(-2, 2),
			N.twigB:Lerp(BLACK, rng:NextNumber(0, 0.15)), N.twigBMat)
	end
	for j = 0, nC - 1 do
		twig(j * 360 / nC + 9 + rng:NextNumber(-6, 6), 13.4, floorY + 1.75, 6.2, 0.42, (j % 2 == 0 and 1 or -1) * rng:NextNumber(22, 36), rng:NextNumber(-8, 8),
			j % 3 == 0 and N.twigA or N.twigC, j % 3 == 0 and N.twigAMat or N.twigCMat)
	end

	local ornaments = ORNAMENTS[i] or ORNAMENTS[#ORNAMENTS]
	ornaments(nb, t)
	folder:SetAttribute("Parts", nb.count)
	return folder
end

function PackStyle.init(g)
	G = g
	C = g.Config
end

return PackStyle
