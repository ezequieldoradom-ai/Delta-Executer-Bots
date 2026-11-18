-- Efectos visuales de las auras de los jugadores: capas de partículas, cada aura más épica que la anterior.
-- Contrato con el cliente:
--   · todo cuelga de Attachments llamados exactamente "AuraFX", hijos directos del HumanoidRootPart
--     (el cliente los busca por ese nombre para ocultar las auras de otros jugadores);
--   · el atributo "AuraColor" del HumanoidRootPart da color a las estelas de velocidad.
-- Sin piezas, sin soldaduras y sin bucles por jugador: solo emisores y, como mucho, una luz.
local AuraFx = {}
local G
local VFX

local rgb = Color3.fromRGB
local WHITE = Color3.new(1, 1, 1)
local NAME = "AuraFX"
local PO = Enum.ParticleOrientation

-- Alturas respecto al centro del HumanoidRootPart (los pies quedan unos 3 studs por debajo)
local SPOTS = {
	feet = Vector3.new(0, -2.85, 0),
	body = Vector3.new(0, 0, 0),
	back = Vector3.new(0, 0.6, 0.4),
	head = Vector3.new(0, 2.75, 0),
}

AuraFx.NAME = NAME
AuraFx.MAX_RATE = { rayo = 30, divina = 70 } -- límites de partículas por segundo (la más barata y la más cara)

---------------------------------------------------------------------
-- Utilidades
---------------------------------------------------------------------
local function ns(points) -- { {tiempo, valor}, ... } → NumberSequence
	local kp = {}
	for i, p in ipairs(points) do
		kp[i] = NumberSequenceKeypoint.new(p[1], p[2])
	end
	return NumberSequence.new(kp)
end

local function cs(...) -- colores repartidos por igual a lo largo de la vida de la partícula
	local list = { ... }
	if #list == 1 then
		return ColorSequence.new(list[1])
	end
	local kp = {}
	for i, c in ipairs(list) do
		kp[i] = ColorSequenceKeypoint.new((i - 1) / (#list - 1), c)
	end
	return ColorSequence.new(kp)
end

local FADE = ns({ { 0, 0 }, { 0.6, 0.25 }, { 1, 1 } }) -- nace nítida y se apaga

local function emit(att, props)
	local e = Instance.new("ParticleEmitter")
	e.LightEmission = 1
	e.LightInfluence = 0
	e.Speed = NumberRange.new(0)
	e.Transparency = FADE
	for k, v in pairs(props) do
		e[k] = v
	end
	e.Parent = att
	return e
end

-- Nota de ajuste (visto en Studio, de día y sobre mármol blanco): la luz aditiva (LightEmission 1)
-- en capas grandes y suaves se suma hasta el blanco puro; esas capas van con LightEmission ~0,5
-- para que conserven el color. Las chispas, arcos y destellos pequeños sí pueden ir a 1.

-- Resplandor pegado al cuerpo (se dibuja por detrás del personaje)
local function bodyGlow(att, color, size, rate, clear)
	return emit(att, {
		Name = "Glow", Texture = VFX.glow, Rate = rate, Lifetime = NumberRange.new(0.9, 1.3), LightEmission = 0.5,
		LockedToPart = true, ZOffset = -1.5, Rotation = NumberRange.new(0, 360),
		Color = cs(color), Size = ns({ { 0, size * 0.8 }, { 1, size } }),
		Transparency = ns({ { 0, 1 }, { 0.25, clear }, { 0.7, clear }, { 1, 1 } }),
	})
end

-- Partícula tumbada en el suelo (anillos, círculos de runas, halos): no mira a la cámara
local function flat(att, props)
	props.Orientation = PO.VelocityPerpendicular
	props.EmissionDirection = Enum.NormalId.Top
	props.Speed = NumberRange.new(0.01)
	props.SpreadAngle = Vector2.new(0, 0)
	return emit(att, props)
end

-- Onda que se abre en el suelo y se queda donde nació (al correr deja un rastro de ondas)
local function groundPulse(att, color, rate, from, to, life)
	return flat(att, {
		Name = "Pulse", Texture = VFX.ring, Rate = rate, Lifetime = NumberRange.new(life or 1.3),
		Color = cs(WHITE, color), Size = ns({ { 0, from }, { 1, to } }),
		Transparency = ns({ { 0, 0.25 }, { 0.6, 0.6 }, { 1, 1 } }),
	})
end

-- Círculo de runas que gira bajo los pies (pegado al jugador)
local function runeCircle(att, color, size, spin, clear)
	return flat(att, {
		Name = "Runes", Texture = VFX.runes, Rate = 1, Lifetime = NumberRange.new(2),
		LockedToPart = true, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(spin),
		Color = cs(color), Size = ns({ { 0, size }, { 1, size } }),
		Transparency = ns({ { 0, 1 }, { 0.25, clear }, { 0.75, clear }, { 1, 1 } }),
	})
end

-- Halo horizontal sobre la cabeza
local function halo(att, color, size)
	return flat(att, {
		Name = "Halo", Texture = VFX.ring, Rate = 1, Lifetime = NumberRange.new(2), LockedToPart = true,
		Color = cs(color), Size = ns({ { 0, size }, { 1, size } }), Brightness = 2,
		Transparency = ns({ { 0, 1 }, { 0.25, 0.1 }, { 0.75, 0.1 }, { 1, 1 } }),
	})
end

-- Rayos de sol que giran despacio detrás del jugador
local function sunburst(att, color, size, spin, rate, clear)
	return emit(att, {
		Name = "Rays", Texture = VFX.rays, Rate = rate, Lifetime = NumberRange.new(2.4, 3), LightEmission = 0.55,
		LockedToPart = true, ZOffset = -2.5, Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(spin),
		Color = cs(color), Size = ns({ { 0, size * 0.85 }, { 0.5, size }, { 1, size * 0.9 } }),
		Transparency = ns({ { 0, 1 }, { 0.3, clear }, { 0.7, clear }, { 1, 1 } }),
	})
end

-- Chispas sueltas: se quedan atrás al correr
local function sparks(att, c1, c2, rate, size, props)
	local p = {
		Name = "Sparks", Texture = VFX.sparkle, Rate = rate, Lifetime = NumberRange.new(0.8, 1.4),
		Speed = NumberRange.new(3, 7), SpreadAngle = Vector2.new(180, 180), Drag = 1.5,
		Rotation = NumberRange.new(0, 360), RotSpeed = NumberRange.new(-180, 180),
		Color = cs(c1, c2), Size = ns({ { 0, size }, { 1, 0 } }),
	}
	for k, v in pairs(props or {}) do
		p[k] = v
	end
	return emit(att, p)
end

local function light(att, color, range, brightness)
	local l = Instance.new("PointLight")
	l.Color = color
	l.Range = range
	l.Brightness = brightness
	l.Shadows = false
	l.Parent = att
	return l
end

---------------------------------------------------------------------
-- Las auras (en orden de precio). a(sitio) → Attachment "AuraFX" a esa altura; c = color del aura
---------------------------------------------------------------------
local BUILD = {}

-- 1 · Rayo de Zeus: chispazos eléctricos que saltan del cuerpo
function BUILD.rayo(a, c)
	bodyGlow(a("body"), c, 6, 3, 0.6)
	emit(a("body"), {
		Name = "Arcs", Texture = VFX.streak, Rate = 16, Lifetime = NumberRange.new(0.12, 0.26),
		Speed = NumberRange.new(10, 18), SpreadAngle = Vector2.new(180, 180), Drag = 4, LockedToPart = true,
		Orientation = PO.VelocityParallel, Brightness = 3, Color = cs(WHITE, c),
		Size = ns({ { 0, 3.2 }, { 1, 0.8 } }), Transparency = ns({ { 0, 0 }, { 0.7, 0.2 }, { 1, 1 } }),
	})
	sparks(a("body"), WHITE, c, 12, 0.7, { Lifetime = NumberRange.new(0.5, 0.9), Speed = NumberRange.new(4, 9), Acceleration = Vector3.new(0, -10, 0) })
	groundPulse(a("feet"), c, 1, 3, 8, 0.9) -- chispazo en el suelo: se ve aunque haya mucha luz
	light(a("body"), c, 10, 1.1)
end

-- 2 · Fuego del Inframundo: llamas que suben desde los pies, ascuas y humo oscuro
function BUILD.fuego(a, c)
	local ember = rgb(255, 200, 90)
	local dark = rgb(150, 20, 10)
	bodyGlow(a("body"), c, 6.5, 3, 0.6)
	emit(a("feet"), {
		Name = "Flames", Texture = VFX.flame, Rate = 22, Lifetime = NumberRange.new(0.7, 1.1), LightEmission = 0.6,
		Speed = NumberRange.new(3, 6), SpreadAngle = Vector2.new(28, 28), Acceleration = Vector3.new(0, 7, 0),
		Rotation = NumberRange.new(-12, 12), Color = cs(ember, c, dark),
		Size = ns({ { 0, 3.2 }, { 0.5, 2.6 }, { 1, 0.5 } }), Transparency = ns({ { 0, 0.05 }, { 0.6, 0.3 }, { 1, 1 } }),
	})
	groundPulse(a("feet"), c, 1, 3, 9, 1.2)
	sparks(a("body"), ember, c, 10, 0.4, { Name = "Embers", Lifetime = NumberRange.new(1, 1.8), Speed = NumberRange.new(2, 5), SpreadAngle = Vector2.new(60, 60), Acceleration = Vector3.new(0, 6, 0) })
	emit(a("body"), {
		Name = "Smoke", Texture = VFX.smoke, Rate = 4, Lifetime = NumberRange.new(1.2, 1.8), LightEmission = 0,
		Speed = NumberRange.new(2, 3), SpreadAngle = Vector2.new(25, 25), Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-40, 40), Color = cs(rgb(90, 24, 12), rgb(30, 10, 10)),
		Size = ns({ { 0, 2 }, { 1, 4.5 } }), Transparency = ns({ { 0, 0.7 }, { 1, 1 } }),
	})
	light(a("body"), c, 12, 1.3)
end

-- 3 · Sol de Ra: rayos de sol a la espalda, disco solar sobre la cabeza y ondas doradas
function BUILD.sol(a, c)
	local pale = c:Lerp(WHITE, 0.55)
	sunburst(a("back"), c, 10, 22, 1.2, 0.5)
	bodyGlow(a("body"), pale, 6.5, 3, 0.72)
	halo(a("head"), c, 3.2)
	sparks(a("body"), WHITE, c, 18, 0.6, { Lifetime = NumberRange.new(1, 1.6) })
	emit(a("feet"), {
		Name = "Flares", Texture = VFX.flame, Rate = 10, Lifetime = NumberRange.new(0.7, 1.1),
		Speed = NumberRange.new(3, 5), SpreadAngle = Vector2.new(35, 35), Acceleration = Vector3.new(0, 5, 0),
		Color = cs(WHITE, c), Size = ns({ { 0, 2.2 }, { 1, 0.3 } }), Transparency = ns({ { 0, 0.3 }, { 1, 1 } }),
	})
	groundPulse(a("feet"), c, 1.5, 3, 9, 1.2)
	light(a("body"), c, 14, 1.4)
end

-- 4 · Escarcha nórdica: nieve que cae, niebla helada, púas de hielo y runas bajo los pies
function BUILD.escarcha(a, c)
	local ice = c:Lerp(WHITE, 0.6)
	bodyGlow(a("body"), c, 7, 3, 0.6)
	runeCircle(a("feet"), c, 7.5, 40, 0.1) -- en el color del aura: el blanco helado no se veía sobre el mármol
	groundPulse(a("feet"), c, 1.5, 4, 11, 1.6)
	sparks(a("head"), WHITE, c, 18, 0.55, {
		Name = "Snow", Lifetime = NumberRange.new(1.2, 2), Speed = NumberRange.new(2, 5),
		Acceleration = Vector3.new(0, -5, 0), Size = ns({ { 0, 0.55 }, { 1, 0.12 } }),
	})
	emit(a("feet"), {
		Name = "Mist", Texture = VFX.smoke, Rate = 6, Lifetime = NumberRange.new(1.5, 2.2), LightEmission = 0.6,
		Speed = NumberRange.new(1, 2.5), SpreadAngle = Vector2.new(80, 80), Rotation = NumberRange.new(0, 360),
		RotSpeed = NumberRange.new(-30, 30), Color = cs(ice), Size = ns({ { 0, 3 }, { 1, 6 } }),
		Transparency = ns({ { 0, 0.78 }, { 1, 1 } }),
	})
	emit(a("feet"), {
		Name = "Shards", Texture = VFX.streak, Rate = 6, Lifetime = NumberRange.new(0.4, 0.6),
		Speed = NumberRange.new(10, 14), SpreadAngle = Vector2.new(35, 35), Drag = 3,
		Orientation = PO.VelocityParallel, Brightness = 2, Color = cs(c, rgb(60, 140, 255)),
		Size = ns({ { 0, 2.6 }, { 1, 0.4 } }),
	})
	light(a("body"), c, 14, 1.5)
end

-- 5 · Marea de Poseidón: surtidores de agua, gotas, espuma, olas y un gran aro de mar a la espalda
function BUILD.marea(a, c)
	local foam = rgb(210, 245, 255)
	local deep = rgb(20, 80, 230)
	bodyGlow(a("body"), c, 7.5, 3, 0.7)
	runeCircle(a("feet"), foam, 8.5, -45, 0.1)
	groundPulse(a("feet"), c, 3, 3, 13, 1.4)
	emit(a("back"), {
		Name = "Wave", Texture = VFX.ring, Rate = 1, Lifetime = NumberRange.new(2), LockedToPart = true, ZOffset = -2,
		Color = cs(foam, c), Size = ns({ { 0, 5 }, { 1, 9 } }), Transparency = ns({ { 0, 1 }, { 0.3, 0.35 }, { 1, 1 } }),
	})
	emit(a("feet"), {
		Name = "Spout", Texture = VFX.streak, Rate = 14, Lifetime = NumberRange.new(0.6, 0.95),
		Speed = NumberRange.new(9, 13), SpreadAngle = Vector2.new(38, 38), Acceleration = Vector3.new(0, -20, 0),
		Orientation = PO.VelocityParallel, Brightness = 2, Color = cs(foam, c, deep),
		Size = ns({ { 0, 1.8 }, { 1, 0.5 } }),
	})
	sparks(a("feet"), foam, c, 14, 0.5, {
		Name = "Drops", Lifetime = NumberRange.new(0.8, 1.3), Speed = NumberRange.new(7, 11),
		SpreadAngle = Vector2.new(50, 50), Acceleration = Vector3.new(0, -22, 0), Drag = 0,
		Size = ns({ { 0, 0.5 }, { 1, 0.15 } }),
	})
	emit(a("feet"), {
		Name = "Foam", Texture = VFX.smoke, Rate = 6, Lifetime = NumberRange.new(1.2, 1.8), LightEmission = 0.7,
		Speed = NumberRange.new(1.5, 3), SpreadAngle = Vector2.new(85, 85), Rotation = NumberRange.new(0, 360),
		Color = cs(foam, c), Size = ns({ { 0, 2.5 }, { 1, 5.5 } }), Transparency = ns({ { 0, 0.72 }, { 1, 1 } }),
	})
	emit(a("body"), {
		Name = "Bubbles", Texture = VFX.glow, Rate = 6, Lifetime = NumberRange.new(1.4, 2),
		Speed = NumberRange.new(1, 3), SpreadAngle = Vector2.new(70, 70), Acceleration = Vector3.new(0, 3, 0),
		Color = cs(foam, c), Size = ns({ { 0, 0.3 }, { 0.5, 0.75 }, { 1, 0.2 } }),
		Transparency = ns({ { 0, 0.2 }, { 0.8, 0.4 }, { 1, 1 } }),
	})
	light(a("body"), c, 16, 1.6)
end

-- 6 · Aura Divina: doble sol a la espalda, halo, doble círculo de runas, columnas de luz y lluvia de destellos
function BUILD.divina(a, _c)
	local gold = rgb(255, 214, 110)
	local pale = rgb(255, 244, 205)
	-- (más contenida: en Studio quemaba a blanco media pantalla y no se veía al jugador)
	sunburst(a("back"), gold, 12, 16, 1.2, 0.5)
	sunburst(a("back"), rgb(255, 180, 60), 9, -28, 1, 0.45)
	bodyGlow(a("body"), gold, 7, 3, 0.68)
	halo(a("head"), gold, 3.6)
	runeCircle(a("feet"), gold, 10.5, 30, 0.05)
	runeCircle(a("feet"), WHITE, 6.5, -55, 0.1)
	groundPulse(a("feet"), gold, 2, 4, 15, 1.5)
	emit(a("feet"), {
		Name = "Pillars", Texture = VFX.streak, Rate = 14, Lifetime = NumberRange.new(0.7, 1.1),
		Speed = NumberRange.new(9, 14), SpreadAngle = Vector2.new(14, 14),
		Orientation = PO.VelocityParallel, Brightness = 3, Color = cs(WHITE, gold),
		Size = ns({ { 0, 2.6 }, { 1, 0.6 } }),
	})
	sparks(a("body"), WHITE, gold, 26, 0.75, { Lifetime = NumberRange.new(1.4, 2.2), Speed = NumberRange.new(2, 6), Acceleration = Vector3.new(0, 3, 0) })
	emit(a("body"), {
		Name = "Motes", Texture = VFX.glow, Rate = 8, Lifetime = NumberRange.new(1.6, 2.4),
		Speed = NumberRange.new(1, 2.5), SpreadAngle = Vector2.new(180, 180), Acceleration = Vector3.new(0, 4, 0),
		Color = cs(pale, gold), Size = ns({ { 0, 0.4 }, { 0.5, 1 }, { 1, 0.2 } }),
		Transparency = ns({ { 0, 0.3 }, { 0.7, 0.5 }, { 1, 1 } }),
	})
	light(a("body"), pale, 18, 2)
end

-- Aura desconocida (por si se añade una al Config sin diseño propio): destellos del color del aura
local function generic(a, c)
	bodyGlow(a("body"), c, 5.5, 3, 0.8)
	sparks(a("body"), WHITE, c, 20, 0.7, {})
	light(a("body"), c, 10, 1.2)
end

---------------------------------------------------------------------
-- API
---------------------------------------------------------------------
-- Quita todo lo que una llamada anterior creó en ese HumanoidRootPart
function AuraFx.clear(hrp)
	for _, ch in ipairs(hrp:GetChildren()) do
		if ch.Name == NAME then
			ch:Destroy()
		end
	end
end

-- Pone el aura (entrada de Config.AURAS) en el HumanoidRootPart; aura = nil la quita
function AuraFx.apply(hrp, aura)
	if typeof(hrp) ~= "Instance" or not hrp:IsA("BasePart") then
		return
	end
	AuraFx.clear(hrp)
	hrp:SetAttribute("AuraColor", aura and aura.color or nil)
	if not aura then
		return
	end
	local color = aura.color or WHITE
	local made = {}
	local function a(where)
		local att = made[where]
		if not att then
			att = Instance.new("Attachment")
			att.Name = NAME
			att.Position = SPOTS[where] or SPOTS.body
			att.Parent = hrp
			made[where] = att
		end
		return att
	end
	local ok, err = pcall(BUILD[aura.id] or generic, a, color)
	if not ok then
		-- nunca dejar un aura a medias: se limpia y se pone la genérica
		warn("AuraFx: fallo al crear el aura", aura.id, err)
		AuraFx.clear(hrp)
		table.clear(made)
		pcall(generic, a, color)
	end
end

function AuraFx.init(g)
	G = g
	VFX = G.Config.VFX
end

return AuraFx
