-- Steal a God ⚡ Roba un Dios — efectos del cliente (módulo hijo del LocalScript)
--
-- 1) Animador por etiquetas (CollectionService). El servidor solo crea la pieza, le pone atributos y la etiqueta;
--    aquí, en la pantalla de cada jugador, se mueve (sin tráfico de red):
--      FxSpin    gira sobre un eje local         · SpinSpeed (rad/s, 0.6) · SpinAxis ("X"|"Y"|"Z", "Y")
--      FxBob     flota arriba y abajo            · BobAmp (0.6) · BobSpeed (rad/s, 1.5) · BobPhase (0)
--      FxOrbit   orbita alrededor de su Parent   · OrbitRadius · OrbitSpeed · OrbitHeight · OrbitPhase · OrbitTilt · OrbitSpin
--      FxRainbow el color recorre el arcoíris    · RainbowSpeed (vueltas/s, 0.25) · RainbowSat (0.7)
--      FxGlitch  parpadeos cortos al azar (la rareza "???")
--      LocText   texto en el idioma del jugador  · LocKey
-- 2) Estelas de velocidad para todos los jugadores (cuerpo + resplandor en el suelo).
-- 3) Líneas de viento alrededor del jugador local cuando corre muy rápido.
--
-- Todo va en UNA sola conexión por fotograma. Cada pieza se trata por separado: si una falla, se quita del
-- registro y las demás siguen.
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Fx = {}

---------------------------------------------------------------------
-- Ajustes
---------------------------------------------------------------------
local TAU = math.pi * 2
local NEAR_DIST = 150 -- hasta aquí (bloques desde la cámara) se anima en cada fotograma
local CULL_DIST = 320 -- más lejos no se anima
local FAR_EVERY = 3 -- entre las dos distancias: 1 de cada 3 fotogramas
local GLITCH_DIST = 220
local RAINBOW_HZ = 15
local TRAIL_ON = 40 -- bloques/s para que aparezca la estela…
local TRAIL_OFF = 34 -- …y para que se apague (así no parpadea justo en el límite)
local TRAIL_TOP = 100 -- a esta velocidad la estela es la más larga y ancha
local TRAIL_STEPS = 10
local WIND_FROM = 70 -- bloques/s para que aparezcan las líneas de viento
local WIND_TOP = 110

local WHITE = Color3.new(1, 1, 1)
local CYAN = Color3.fromRGB(94, 231, 255)
local GLITCH_RED = Color3.fromRGB(255, 45, 70)
local EYE = Vector3.new(0, 5, 0)

---------------------------------------------------------------------
-- Estado del módulo
---------------------------------------------------------------------
local started = false
local connections = {}
local ctx = {}
local localPlayer = nil
local particlesOn = true
local othersAurasOn = true

local function num(v, default)
	if type(v) == "number" and v == v and v > -1e6 and v < 1e6 then
		return v
	end
	return default
end

local function optOn(key)
	local f = ctx.opt
	if type(f) ~= "function" then
		return true
	end
	local ok, v = pcall(f, key)
	if not ok then
		return true
	end
	return v ~= false
end

-- Envuelve una parte del fotograma: un fallo se avisa UNA vez y, si se repite, esa parte se apaga
-- (nunca una lluvia de errores en cada fotograma, y el resto del módulo sigue funcionando).
local function section(name, fn)
	local fails = 0
	local off = false
	return function(...)
		if off then
			return
		end
		local ok, err = pcall(fn, ...)
		if not ok then
			fails += 1
			if fails == 1 then
				warn("[SAG] Fx." .. name .. ": " .. tostring(err))
			end
			if fails >= 30 then
				off = true
				warn("[SAG] Fx." .. name .. " desactivado por errores repetidos")
			end
		end
	end
end

---------------------------------------------------------------------
-- 1a) Movimiento: FxSpin, FxBob, FxOrbit
---------------------------------------------------------------------
local motionList = {} -- lista densa de registros (recorrido rápido)
local motionOf = {} -- [pieza] = registro
local MOTION_FIELD = { FxSpin = "spin", FxBob = "bob", FxOrbit = "orbit" }
local frameCount = 0

local function dropMotion(rec, restore)
	local part = rec.part
	if motionOf[part] ~= rec then
		return
	end
	motionOf[part] = nil
	local n = #motionList
	local last = motionList[n]
	motionList[rec.index] = last
	last.index = rec.index
	motionList[n] = nil
	if restore then
		-- al quitarle las etiquetas vuelve a su postura de reposo
		pcall(function()
			if part.Parent then
				part.CFrame = rec.base
			end
		end)
	end
end

local function motionAdd(part, tag)
	if not part:IsA("BasePart") then
		return
	end
	local rec = motionOf[part]
	if not rec then
		local cf = part.CFrame -- postura base: la primera vez que se ve la pieza
		rec = {
			part = part,
			base = cf,
			pos = cf.Position,
			rot0 = cf.Rotation,
			ok = false,
			refreshAt = 0,
		}
		table.insert(motionList, rec)
		rec.index = #motionList
		motionOf[part] = rec
	end
	rec[MOTION_FIELD[tag]] = true
	rec.refreshAt = 0 -- leer los atributos en el próximo fotograma
end

local function motionRemove(part, tag)
	local rec = motionOf[part]
	if not rec then
		return
	end
	rec[MOTION_FIELD[tag]] = nil
	if rec.spin or rec.bob or rec.orbit then
		rec.refreshAt = 0
	else
		dropMotion(rec, true)
	end
end

-- Postura del padre respecto a la que se guarda la posición relativa de un hijo que lo sigue
local function followFrame(parent)
	local prec = motionOf[parent]
	return prec and prec.base or parent.CFrame
end

-- Relee atributos y jerarquía (1 vez por segundo y por pieza: los atributos pueden llegar después de la etiqueta)
local function refreshMotion(rec, now)
	local part = rec.part
	rec.refreshAt = now + 1 + (rec.index % 8) * 0.04
	rec.ok = part.Anchored and part:IsDescendantOf(workspace)
	if rec.spin then
		rec.spinSpeed = num(part:GetAttribute("SpinSpeed"), 0.6)
		local axis = part:GetAttribute("SpinAxis")
		axis = type(axis) == "string" and string.upper(axis) or "Y"
		rec.spinAxis = axis == "X" and 1 or (axis == "Z" and 3 or 2)
	end
	if rec.bob then
		rec.bobAmp = num(part:GetAttribute("BobAmp"), 0.6)
		rec.bobSpeed = num(part:GetAttribute("BobSpeed"), 1.5)
		rec.bobPhase = num(part:GetAttribute("BobPhase"), 0)
	end
	local parent = part.Parent
	if rec.orbit then
		rec.oSpeed = num(part:GetAttribute("OrbitSpeed"), 1)
		rec.oPhase = num(part:GetAttribute("OrbitPhase"), 0)
		rec.oSpin = num(part:GetAttribute("OrbitSpin"), 0)
		rec.oTilt = CFrame.Angles(num(part:GetAttribute("OrbitTilt"), 0), 0, 0)
		rec.oOffset = CFrame.new(num(part:GetAttribute("OrbitRadius"), 3), num(part:GetAttribute("OrbitHeight"), 0), 0)
		rec.centre = (parent ~= nil and parent:IsA("BasePart")) and parent or nil
		rec.follow, rec.rel = nil, nil
		if rec.centre then
			rec.pos = rec.centre.Position
		end
		return
	end
	-- FxSpin / FxBob "en su sitio". Si su padre es otra pieza que mueve el servidor (o que orbita), la siguen.
	-- Si el padre también gira o flota con este módulo NO se sigue: así las piezas de un mismo objeto
	-- flotan a la vez y no se suma el movimiento dos veces.
	local follow = nil
	if parent ~= nil and parent:IsA("BasePart") then
		local prec = motionOf[parent]
		if not prec or prec.orbit then
			follow = parent
		elseif rec.follow == parent and rec.rel then
			rec.base = prec.base * rec.rel -- el padre ha empezado a animarse: quedarse junto a su postura de reposo
		end
	end
	if follow then
		if rec.follow ~= follow then
			rec.follow = follow
			rec.rel = followFrame(follow):ToObjectSpace(rec.base)
			rec.pcf = nil -- recalcular la base en la próxima actualización
		end
	else
		rec.follow, rec.rel = nil, nil
	end
	rec.pos = part.Position
end

local function updateMotion(rec, now)
	local part = rec.part
	local cf
	if rec.orbit then
		local centre = rec.centre
		if not centre then
			return
		end
		local c = centre.Position -- el centro puede moverse (un sobre que lleva un jugador)
		rec.pos = c
		cf = (rec.oTilt + c) * CFrame.Angles(0, (rec.oPhase + now * rec.oSpeed) % TAU, 0) * rec.oOffset
		if rec.oSpin ~= 0 then
			cf = cf * CFrame.Angles(0, (now * rec.oSpin) % TAU, 0)
		end
		cf = cf * rec.rot0 -- conserva la orientación con la que se construyó (un disco tumbado sigue tumbado)
	else
		local follow = rec.follow
		local last = rec.lastPos
		if last and (part.Position - last).Magnitude > 0.05 then
			-- alguien (el servidor) ha movido la pieza: esa es su nueva postura base
			rec.base = part.CFrame
			if follow then
				rec.rel = followFrame(follow):ToObjectSpace(rec.base)
				rec.pcf = nil
			end
		end
		if follow then
			local pcf = follow.CFrame
			if pcf ~= rec.pcf then
				rec.pcf = pcf
				rec.base = pcf * rec.rel
			end
		end
		cf = rec.base
		rec.pos = cf.Position
	end
	if rec.bob then
		cf = cf + Vector3.new(0, rec.bobAmp * math.sin(now * rec.bobSpeed + rec.bobPhase), 0)
	end
	local jit = rec.jit
	if jit then
		cf = cf + jit
	end
	if rec.spin then
		local a = (now * rec.spinSpeed) % TAU
		local axis = rec.spinAxis
		if axis == 1 then
			cf = cf * CFrame.Angles(a, 0, 0)
		elseif axis == 3 then
			cf = cf * CFrame.Angles(0, 0, a)
		else
			cf = cf * CFrame.Angles(0, a, 0)
		end
	end
	part.CFrame = cf
	rec.lastPos = cf.Position
end

local function stepMotion(now, camPos)
	local n = #motionList
	if n == 0 then
		return
	end
	frameCount += 1
	for i = n, 1, -1 do -- hacia atrás: quitar un registro no altera los que faltan por recorrer
		local rec = motionList[i]
		if now >= rec.refreshAt and not pcall(refreshMotion, rec, now) then
			dropMotion(rec, false)
			continue
		end
		if rec.ok then
			local due = true
			if camPos then
				local d = (rec.pos - camPos).Magnitude
				if d > CULL_DIST then
					due = false
				elseif d > NEAR_DIST then
					due = (frameCount + i) % FAR_EVERY == 0
				end
			end
			if due and not pcall(updateMotion, rec, now) then
				dropMotion(rec, true)
			end
		end
	end
end

---------------------------------------------------------------------
-- 1b) Arcoíris: FxRainbow (15 veces por segundo)
---------------------------------------------------------------------
local rainbowList = {}
local rainbowOf = {}
local hueOffsets = setmetatable({}, { __mode = "k" }) -- [objeto] = desfase del color

-- Qué propiedad lleva el color en cada clase (seq = ColorSequence)
local function rainbowProp(inst)
	if inst:IsA("BasePart") or inst:IsA("Light") or inst:IsA("UIStroke") then
		return "Color", false
	elseif inst:IsA("ParticleEmitter") or inst:IsA("Trail") or inst:IsA("Beam") then
		return "Color", true
	elseif inst:IsA("Decal") or inst:IsA("SelectionBox") then
		return "Color3", false
	elseif inst:IsA("ImageLabel") or inst:IsA("ImageButton") then
		return "ImageColor3", false
	elseif inst:IsA("TextLabel") or inst:IsA("TextButton") then
		return "TextColor3", false
	end
	return nil, false
end

-- Las piezas de un mismo objeto (un sobre con sus adornos, luces y partículas) cambian de color a la vez;
-- objetos distintos van desfasados entre sí.
local function rainbowGroup(inst)
	local root = nil
	local p = inst
	while p and p ~= workspace and p ~= game do
		if p:IsA("BasePart") then
			root = p
		end
		p = p.Parent
	end
	root = root or inst
	return root:FindFirstAncestorOfClass("Model") or root
end

local function dropRainbow(rec, restore)
	local inst = rec.inst
	if rainbowOf[inst] ~= rec then
		return
	end
	rainbowOf[inst] = nil
	local n = #rainbowList
	local last = rainbowList[n]
	rainbowList[rec.index] = last
	last.index = rec.index
	rainbowList[n] = nil
	if restore then
		pcall(function()
			if inst.Parent then
				inst[rec.prop] = rec.orig
			end
		end)
	end
end

local function rainbowAdd(inst)
	if rainbowOf[inst] then
		return
	end
	local prop, seq = rainbowProp(inst)
	if not prop then
		return
	end
	local group = rainbowGroup(inst)
	local offset = hueOffsets[group]
	if not offset then
		offset = math.random()
		hueOffsets[group] = offset
	end
	local rec = {
		inst = inst,
		prop = prop,
		seq = seq,
		orig = inst[prop],
		group = group, -- mantiene vivo el desfase del grupo mientras exista el registro
		offset = offset,
		speed = 0.25,
		sat = 0.7,
		live = false,
		refreshAt = 0,
	}
	table.insert(rainbowList, rec)
	rec.index = #rainbowList
	rainbowOf[inst] = rec
end

local function rainbowRemove(inst)
	local rec = rainbowOf[inst]
	if rec then
		dropRainbow(rec, true)
	end
end

local function updateRainbow(rec, now, camPos)
	local inst = rec.inst
	if now >= rec.refreshAt then
		rec.refreshAt = now + 1 + (rec.index % 8) * 0.04
		rec.speed = num(inst:GetAttribute("RainbowSpeed"), 0.25)
		rec.sat = math.clamp(num(inst:GetAttribute("RainbowSat"), 0.7), 0, 1)
		local own = inst:GetAttribute("RainbowOffset")
		if type(own) == "number" and own == own then
			rec.offset = own % 1
		end
		rec.live = inst:IsDescendantOf(workspace)
		rec.anchor = inst:IsA("BasePart") and inst or inst:FindFirstAncestorWhichIsA("BasePart")
	end
	if not rec.live then
		return
	end
	local anchor = rec.anchor
	if anchor and camPos and (anchor.Position - camPos).Magnitude > CULL_DIST then
		return
	end
	local h = (now * rec.speed + rec.offset) % 1
	local c = Color3.fromHSV(h, rec.sat, 1)
	if rec.seq then
		inst[rec.prop] = ColorSequence.new(c, Color3.fromHSV((h + 0.12) % 1, rec.sat, 1))
	else
		inst[rec.prop] = c
	end
end

local function stepRainbow(now, camPos)
	for i = #rainbowList, 1, -1 do
		local rec = rainbowList[i]
		if not pcall(updateRainbow, rec, now, camPos) then
			dropRainbow(rec, false)
		end
	end
end

---------------------------------------------------------------------
-- 1c) Fallo visual: FxGlitch
-- Parpadeo: LocalTransparencyModifier (solo existe en este cliente, así nunca pisa lo que el servidor decide
-- sobre Transparency: un sobre oculto sigue oculto). Destello de color y pequeño salto de posición: se
-- deshacen a los pocos fotogramas, y solo si nadie más ha tocado la pieza entre medias.
---------------------------------------------------------------------
local glitchList = {}
local glitchOf = {}

local function colorNear(a, b)
	return math.abs(a.R - b.R) + math.abs(a.G - b.G) + math.abs(a.B - b.B) < 0.02
end

local function glitchRestore(rec)
	local part = rec.part
	rec.restoreAt = nil
	local m = rec.jitRec
	if m then
		m.jit = nil
		rec.jitRec = nil
	end
	part.LocalTransparencyModifier = 0
	local colorSet = rec.colorSet
	if colorSet then
		rec.colorSet = nil
		if colorNear(part.Color, colorSet) then
			part.Color = rec.colorOld
		end
	end
	local posSet = rec.posSet
	if posSet then
		rec.posSet = nil
		if (part.Position - posSet).Magnitude < 0.02 then
			part.CFrame = rec.cfOld
		end
	end
end

local function dropGlitch(rec)
	local part = rec.part
	if glitchOf[part] ~= rec then
		return
	end
	glitchOf[part] = nil
	local n = #glitchList
	local last = glitchList[n]
	glitchList[rec.index] = last
	last.index = rec.index
	glitchList[n] = nil
	pcall(glitchRestore, rec) -- nunca dejarla desplazada ni medio invisible
end

local function glitchAdd(part)
	if glitchOf[part] or not part:IsA("BasePart") then
		return
	end
	local rec = { part = part, nextAt = os.clock() + math.random() * 0.4 }
	table.insert(glitchList, rec)
	rec.index = #glitchList
	glitchOf[part] = rec
end

local function glitchRemove(part)
	local rec = glitchOf[part]
	if rec then
		dropGlitch(rec)
	end
end

local function glitchFire(rec, now, camPos)
	local part = rec.part
	rec.nextAt = now + 0.05 + 0.35 * math.random()
	if not particlesOn or not part:IsDescendantOf(workspace) or part.Transparency >= 0.98 then
		return -- efectos apagados en ajustes, pieza fuera del mundo u oculta por el servidor
	end
	if camPos and (part.Position - camPos).Magnitude > GLITCH_DIST then
		return
	end
	local roll = math.random()
	if roll < 0.5 then
		part.LocalTransparencyModifier = 0.45 + 0.5 * math.random()
	elseif roll < 0.75 then
		local accent = part:GetAttribute("GlitchColor")
		if typeof(accent) ~= "Color3" then
			accent = math.random() < 0.5 and WHITE or GLITCH_RED
		end
		rec.colorOld = part.Color
		part.Color = accent
		rec.colorSet = part.Color
	elseif part.Anchored then
		-- salto pequeño (las piezas soldadas a un sobre no se mueven: solo parpadean)
		local amp = math.clamp(part.Size.Magnitude * 0.04, 0.06, 0.35)
		local off = Vector3.new((math.random() - 0.5) * 2 * amp, (math.random() - 0.5) * amp, (math.random() - 0.5) * 2 * amp)
		local m = motionOf[part]
		if m then
			m.jit = off -- la mueve el animador: el salto se suma allí
			rec.jitRec = m
		else
			rec.cfOld = part.CFrame
			part.CFrame = rec.cfOld + off
			rec.posSet = part.Position
		end
		part.LocalTransparencyModifier = 0.25 * math.random()
	else
		part.LocalTransparencyModifier = 0.3 + 0.4 * math.random()
	end
	rec.restoreAt = now + 0.03 + 0.07 * math.random()
	rec.nextAt = rec.restoreAt + 0.05 + 0.35 * math.random()
end

local function stepGlitch(now, camPos)
	for i = #glitchList, 1, -1 do
		local rec = glitchList[i]
		local restoreAt = rec.restoreAt
		if restoreAt then
			if now >= restoreAt and not pcall(glitchRestore, rec) then
				dropGlitch(rec)
			end
		elseif now >= rec.nextAt and not pcall(glitchFire, rec, now, camPos) then
			dropGlitch(rec)
		end
	end
end

---------------------------------------------------------------------
-- 1d) Textos del mundo en el idioma del jugador: LocText
---------------------------------------------------------------------
local locTexts = {} -- [etiqueta] = true

local function applyLocText(inst)
	if not (inst:IsA("TextLabel") or inst:IsA("TextButton") or inst:IsA("TextBox")) then
		return
	end
	local key = inst:GetAttribute("LocKey")
	if type(key) ~= "string" or key == "" then
		return
	end
	local translate = ctx.t
	if type(translate) ~= "function" then
		return
	end
	local text = translate(key)
	-- si la clave no existe, Locale devuelve la propia clave: en ese caso se deja el texto que puso el servidor
	if type(text) == "string" and text ~= key and inst.Text ~= text then
		inst.Text = text
	end
end

local function locAdd(inst)
	locTexts[inst] = true
	pcall(applyLocText, inst)
end

local function locRemove(inst)
	locTexts[inst] = nil
end

local function stepLoc()
	-- repaso lento: por si LocKey llegó después de la etiqueta o el servidor ha vuelto a escribir el texto
	for inst in pairs(locTexts) do
		if not pcall(applyLocText, inst) then
			locTexts[inst] = nil
		end
	end
end

---------------------------------------------------------------------
-- 2) Estelas de velocidad (todos los jugadores)
---------------------------------------------------------------------
local trailRecs = {} -- [personaje] = registro
local trailPending = {} -- [personaje] = true mientras se espera a su HumanoidRootPart
local playerConns = {}
local localSpeed = 0
local localHrp = nil

-- Tablas ya calculadas por nivel de velocidad (así no se crean secuencias nuevas en cada actualización)
local BODY_WIDTH, BODY_ALPHA, GROUND_WIDTH, GROUND_ALPHA = {}, {}, {}, {}
for s = 0, TRAIL_STEPS do
	local k = s / TRAIL_STEPS
	BODY_WIDTH[s] = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.6 + 0.4 * k), NumberSequenceKeypoint.new(1, 0.08) })
	BODY_ALPHA[s] = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.42 - 0.3 * k), NumberSequenceKeypoint.new(0.6, 0.75 - 0.2 * k), NumberSequenceKeypoint.new(1, 1) })
	GROUND_WIDTH[s] = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.55 + 0.45 * k), NumberSequenceKeypoint.new(1, 0.3) })
	GROUND_ALPHA[s] = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.62 - 0.27 * k), NumberSequenceKeypoint.new(1, 1) })
end
local BODY_DEFAULT = ColorSequence.new(WHITE, CYAN)
local GROUND_DEFAULT = ColorSequence.new(CYAN:Lerp(WHITE, 0.35), CYAN)

-- Distancia del centro del HumanoidRootPart al suelo (cambia con el tamaño del avatar)
local function groundDrop(char, hrp)
	local drop = 3
	local hum = char:FindFirstChildOfClass("Humanoid")
	if hum then
		drop = hum.HipHeight + hrp.Size.Y / 2
		if hum.RigType ~= Enum.HumanoidRigType.R15 then
			local leg = char:FindFirstChild("Left Leg")
			drop += (leg ~= nil and leg:IsA("BasePart")) and leg.Size.Y or 2
		end
	end
	return math.clamp(num(drop, 3), 1.5, 8)
end

local function placeTrail(rec)
	local drop = groundDrop(rec.char, rec.hrp)
	if rec.drop and math.abs(drop - rec.drop) < 0.1 then
		return
	end
	rec.drop = drop
	rec.b0.Position = Vector3.new(0, 1.6, 0.3)
	rec.b1.Position = Vector3.new(0, -drop * 0.72, 0.3)
	rec.g0.Position = Vector3.new(-2, 0.25 - drop, 0.6)
	rec.g1.Position = Vector3.new(2, 0.25 - drop, 0.6)
end

local function dropTrail(char)
	local rec = trailRecs[char]
	if not rec then
		return
	end
	trailRecs[char] = nil
	if localHrp == rec.hrp then
		localHrp = nil
		localSpeed = 0
	end
	pcall(function()
		for _, inst in ipairs({ rec.body, rec.ground, rec.b0, rec.b1, rec.g0, rec.g1 }) do
			inst:Destroy()
		end
	end)
end

local function buildTrail(char, hrp)
	local vfx = type(ctx.Config) == "table" and ctx.Config.VFX or nil
	local function attachment(name)
		local a = Instance.new("Attachment")
		a.Name = name
		a.Parent = hrp
		return a
	end
	local rec = {
		char = char,
		hrp = hrp,
		b0 = attachment("FxTrailTop"),
		b1 = attachment("FxTrailBottom"),
		g0 = attachment("FxTrailLeft"),
		g1 = attachment("FxTrailRight"),
		lastPos = hrp.Position,
		v = 0,
		on = false,
		step = -1,
		color = false,
		checkAt = 0,
	}
	-- estela del cuerpo: siempre de cara a la cámara
	local body = Instance.new("Trail")
	body.Name = "FxSpeedTrail"
	body.Texture = vfx and vfx.streak or ""
	body.TextureMode = Enum.TextureMode.Stretch
	body.FaceCamera = true
	body.LightEmission = 1
	body.LightInfluence = 0
	body.Lifetime = 0.25
	body.MinLength = 0.05
	body.Color = BODY_DEFAULT
	body.Transparency = BODY_ALPHA[0]
	body.WidthScale = BODY_WIDTH[0]
	body.Attachment0 = rec.b0
	body.Attachment1 = rec.b1
	body.Enabled = false
	body.Parent = hrp
	rec.body = body
	-- resplandor ancho y suave a ras de suelo
	local ground = Instance.new("Trail")
	ground.Name = "FxGroundTrail"
	ground.Texture = vfx and vfx.glow or ""
	ground.TextureMode = Enum.TextureMode.Stretch
	ground.FaceCamera = false
	ground.LightEmission = 1
	ground.LightInfluence = 0
	ground.Lifetime = 0.35
	ground.MinLength = 0.05
	ground.Color = GROUND_DEFAULT
	ground.Transparency = GROUND_ALPHA[0]
	ground.WidthScale = GROUND_WIDTH[0]
	ground.Attachment0 = rec.g0
	ground.Attachment1 = rec.g1
	ground.Enabled = false
	ground.Parent = hrp
	rec.ground = ground
	placeTrail(rec)
	trailRecs[char] = rec
end

-- Añade las estelas a un personaje (se llama sola para todos los jugadores)
function Fx.attach(char)
	if typeof(char) ~= "Instance" or trailRecs[char] or trailPending[char] then
		return
	end
	trailPending[char] = true
	task.spawn(function()
		local ok, err = pcall(function()
			local hrp = char:WaitForChild("HumanoidRootPart", 15)
			if hrp and hrp:IsA("BasePart") and char.Parent and started and not trailRecs[char] then
				buildTrail(char, hrp)
			end
		end)
		trailPending[char] = nil
		if not ok then
			warn("[SAG] Fx.attach: " .. tostring(err))
		end
	end)
end

local function updateTrail(char, rec, e, now, me)
	local hrp = rec.hrp
	if char.Parent == nil or hrp.Parent ~= char then
		dropTrail(char) -- el personaje ha desaparecido (las estelas se destruyen con él)
		return
	end
	local isLocal = char == me
	local pos = hrp.Position
	local d = pos - rec.lastPos
	rec.lastPos = pos
	if d.Magnitude > 30 + 300 * e then
		-- teletransporte (reaparecer, volver a la parcela): sin esto se dibujaría una raya de punta a punta
		rec.v = 0
		rec.body:Clear()
		rec.ground:Clear()
	else
		local flat = Vector3.new(d.X, 0, d.Z).Magnitude / e
		rec.v += (flat - rec.v) * 0.45
	end
	local v = rec.v
	if isLocal then
		localSpeed = v
		localHrp = hrp
	end
	local on = particlesOn and ((rec.on and v > TRAIL_OFF) or v > TRAIL_ON)
	if on ~= rec.on then
		rec.on = on
		rec.body.Enabled = on
		rec.ground.Enabled = on
	end
	if not on then
		return
	end
	-- más rápido = estela más larga, ancha y visible (con tope)
	local step = math.floor(math.clamp((v - TRAIL_ON) / (TRAIL_TOP - TRAIL_ON), 0, 1) * TRAIL_STEPS + 0.5)
	if step ~= rec.step then
		rec.step = step
		local k = step / TRAIL_STEPS
		rec.body.Lifetime = 0.22 + 0.33 * k
		rec.body.WidthScale = BODY_WIDTH[step]
		rec.body.Transparency = BODY_ALPHA[step]
		rec.ground.Lifetime = 0.3 + 0.4 * k
		rec.ground.WidthScale = GROUND_WIDTH[step]
		rec.ground.Transparency = GROUND_ALPHA[step]
	end
	-- color: el del aura del jugador (si la tiene y se pueden ver) o blanco → cian
	local color = hrp:GetAttribute("AuraColor")
	if typeof(color) ~= "Color3" or not (isLocal or othersAurasOn) then
		color = false
	end
	if color ~= rec.color then
		rec.color = color
		if color then
			rec.body.Color = ColorSequence.new(color:Lerp(WHITE, 0.55), color)
			rec.ground.Color = ColorSequence.new(color:Lerp(WHITE, 0.2), color)
		else
			rec.body.Color = BODY_DEFAULT
			rec.ground.Color = GROUND_DEFAULT
		end
	end
	if now >= rec.checkAt then
		rec.checkAt = now + 2
		placeTrail(rec) -- el avatar puede terminar de cargar (y cambiar de altura) después de aparecer
	end
end

---------------------------------------------------------------------
-- 3) Sensación de velocidad del jugador local: líneas de viento que le pasan al lado
-- Una pieza invisible delante del jugador suelta rayas finas hacia él; al correr hacia ellas pasan volando.
---------------------------------------------------------------------
local windPart, windEmitter = nil, nil
local windOn = false
local windRate = 0
local windDir = Vector3.new(0, 0, -1)

local function ensureWind()
	if windPart and windPart.Parent and windEmitter and windEmitter.Parent == windPart then
		return
	end
	if windPart then
		windPart:Destroy()
	end
	local vfx = type(ctx.Config) == "table" and ctx.Config.VFX or nil
	local part = Instance.new("Part")
	part.Name = "FxWind"
	part.Anchored = true
	part.CanCollide = false
	part.CanQuery = false
	part.CanTouch = false
	part.CastShadow = false
	part.Transparency = 1
	part.Size = Vector3.new(34, 16, 2)
	local pe = Instance.new("ParticleEmitter")
	pe.Name = "FxWindLines"
	pe.Texture = vfx and vfx.streak or ""
	pe.Rate = 0
	pe.Lifetime = NumberRange.new(0.35, 0.55)
	pe.Speed = NumberRange.new(10, 18)
	pe.SpreadAngle = Vector2.new(0, 0)
	pe.EmissionDirection = Enum.NormalId.Front
	pe.LightEmission = 0.8
	pe.LightInfluence = 0
	pe.Color = ColorSequence.new(WHITE, Color3.fromRGB(200, 240, 255))
	pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1.2), NumberSequenceKeypoint.new(0.5, 1.8), NumberSequenceKeypoint.new(1, 1.2) })
	pe.Transparency = NumberSequence.new({ NumberSequenceKeypoint.new(0, 1), NumberSequenceKeypoint.new(0.25, 0.55), NumberSequenceKeypoint.new(0.75, 0.6), NumberSequenceKeypoint.new(1, 1) })
	pe.Rotation = NumberRange.new(0)
	pe.RotSpeed = NumberRange.new(0)
	-- propiedades más recientes, cada una por separado: si alguna no existiera, el efecto sigue funcionando
	pcall(function()
		pe.Orientation = Enum.ParticleOrientation.VelocityParallel -- la raya se alinea con su movimiento
	end)
	pcall(function()
		pe.Squash = NumberSequence.new(1.2) -- más fina y más larga
	end)
	pcall(function()
		pe.Shape = Enum.ParticleEmitterShape.Box
		pe.ShapeStyle = Enum.ParticleEmitterShapeStyle.Volume
	end)
	pe.Parent = part
	part.Parent = workspace.CurrentCamera or workspace
	windPart, windEmitter = part, pe
end

-- 15 veces por segundo: ¿cuántas líneas por segundo tocan?
local function tuneWind()
	local rate = 0
	if particlesOn and localHrp and localHrp.Parent and localSpeed > WIND_FROM then
		rate = 3 + 13 * math.clamp((localSpeed - WIND_FROM) / (WIND_TOP - WIND_FROM), 0, 1)
	end
	if rate > 0 then
		ensureWind()
		windOn = true
	elseif not windOn then
		return
	else
		windOn = false
	end
	if windEmitter and math.abs(rate - windRate) > 0.4 then
		windRate = rate
		windEmitter.Rate = rate
	elseif windEmitter and rate == 0 and windRate ~= 0 then
		windRate = 0
		windEmitter.Rate = 0
	end
end

-- Cada fotograma (solo mientras hay viento): la pieza va por delante del jugador, mirando hacia él
local function stepWind()
	if not windOn then
		return
	end
	local hrp = localHrp
	if not hrp or not windPart or not windPart.Parent then
		return
	end
	local vel = hrp.AssemblyLinearVelocity
	local flat = Vector3.new(vel.X, 0, vel.Z)
	local speed = flat.Magnitude
	if speed > 8 then
		windDir = flat / speed
	end
	local eye = hrp.Position + EYE
	windPart.CFrame = CFrame.lookAt(eye + windDir * (8 + localSpeed * 0.18), eye)
end

---------------------------------------------------------------------
-- Fotograma
---------------------------------------------------------------------
local stepMotionSafe = section("motion", stepMotion)
local stepGlitchSafe = section("glitch", stepGlitch)
local stepRainbowSafe = section("rainbow", stepRainbow)
local stepLocSafe = section("loc", stepLoc)
local stepWindSafe = section("wind", stepWind)
local stepTrailsSafe = section("trails", function(e, now)
	local me = localPlayer and localPlayer.Character
	for char, rec in pairs(trailRecs) do
		updateTrail(char, rec, e, now, me)
	end
	if not me or not trailRecs[me] then
		localSpeed = 0
		localHrp = nil
	end
	tuneWind()
end)

local acc15 = 0
local slowAt = 0

local function onFrame(dt)
	local now = os.clock()
	local cam = workspace.CurrentCamera
	local camPos = cam and cam.CFrame.Position or nil
	stepMotionSafe(now, camPos)
	if #glitchList > 0 then
		stepGlitchSafe(now, camPos)
	end
	stepWindSafe()
	acc15 += dt
	if acc15 >= 1 / RAINBOW_HZ then
		local e = math.min(acc15, 0.5)
		acc15 = 0
		particlesOn = optOn("particles")
		othersAurasOn = optOn("othersAuras")
		if #rainbowList > 0 then
			stepRainbowSafe(now, camPos)
		end
		stepTrailsSafe(e, now)
	end
	if now >= slowAt then
		slowAt = now + 2
		if next(locTexts) ~= nil then
			stepLocSafe()
		end
	end
end

---------------------------------------------------------------------
-- Arranque
---------------------------------------------------------------------
local function hookTag(tag, onAdd, onRemove)
	table.insert(connections, CollectionService:GetInstanceAddedSignal(tag):Connect(function(inst)
		local ok, err = pcall(onAdd, inst, tag)
		if not ok then
			warn("[SAG] Fx " .. tag .. ": " .. tostring(err))
		end
	end))
	table.insert(connections, CollectionService:GetInstanceRemovedSignal(tag):Connect(function(inst)
		pcall(onRemove, inst, tag)
	end))
	for _, inst in ipairs(CollectionService:GetTagged(tag)) do
		local ok, err = pcall(onAdd, inst, tag)
		if not ok then
			warn("[SAG] Fx " .. tag .. ": " .. tostring(err))
		end
	end
end

local function watchPlayer(plr)
	if playerConns[plr] then
		return
	end
	playerConns[plr] = plr.CharacterAdded:Connect(Fx.attach)
	if plr.Character then
		Fx.attach(plr.Character)
	end
end

local function unwatchPlayer(plr)
	local conn = playerConns[plr]
	if conn then
		conn:Disconnect()
		playerConns[plr] = nil
	end
	local char = plr.Character
	if char then
		dropTrail(char)
	end
end

local function safely(name, fn)
	local ok, err = pcall(fn)
	if not ok then
		warn("[SAG] Fx." .. name .. ": " .. tostring(err))
	end
end

-- ctx = { player, Config, Locale, t, opt, getState, gui, play } (lo prepara init.client.luau)
function Fx.start(context)
	if started then
		return
	end
	started = true
	ctx = type(context) == "table" and context or {}
	localPlayer = ctx.player or Players.LocalPlayer
	if type(ctx.t) ~= "function" and type(ctx.Locale) == "table" then
		ctx.t = ctx.Locale.t
	end
	safely("tags", function()
		hookTag("FxSpin", motionAdd, motionRemove)
		hookTag("FxBob", motionAdd, motionRemove)
		hookTag("FxOrbit", motionAdd, motionRemove)
		hookTag("FxRainbow", rainbowAdd, rainbowRemove)
		hookTag("FxGlitch", glitchAdd, glitchRemove)
		hookTag("LocText", locAdd, locRemove)
	end)
	safely("players", function()
		table.insert(connections, Players.PlayerAdded:Connect(watchPlayer))
		table.insert(connections, Players.PlayerRemoving:Connect(unwatchPlayer))
		for _, plr in ipairs(Players:GetPlayers()) do
			watchPlayer(plr)
		end
	end)
	safely("zonesky", function()
		-- cielos y suelos animados de cada zona (módulo hermano, opcional)
		local m = script.Parent and script.Parent:FindFirstChild("ZoneSky")
		if m and RunService:IsClient() then
			require(m).start(ctx)
		end
	end)
	safely("frame", function()
		-- RenderStepped solo existe en el cliente (justo antes de dibujar: el movimiento sale suave)
		local signal = RunService:IsClient() and RunService.RenderStepped or RunService.Heartbeat
		table.insert(connections, signal:Connect(onFrame))
	end)
end

-- Para todo y deja las piezas como estaban (por seguridad; el juego normal no lo necesita)
function Fx.stop()
	if not started then
		return
	end
	started = false
	for _, conn in ipairs(connections) do
		conn:Disconnect()
	end
	table.clear(connections)
	for plr, conn in pairs(playerConns) do
		conn:Disconnect()
		playerConns[plr] = nil
	end
	for i = #motionList, 1, -1 do
		dropMotion(motionList[i], true)
	end
	for i = #rainbowList, 1, -1 do
		dropRainbow(rainbowList[i], true)
	end
	for i = #glitchList, 1, -1 do
		dropGlitch(glitchList[i])
	end
	table.clear(locTexts)
	for char in pairs(trailRecs) do
		dropTrail(char)
	end
	if windPart then
		windPart:Destroy()
	end
	windPart, windEmitter, windOn, windRate = nil, nil, false, 0
	localSpeed, localHrp = 0, nil
end

-- Cuántas cosas hay registradas (para diagnosticar)
function Fx.stats()
	local loc, trails = 0, 0
	for _ in pairs(locTexts) do
		loc += 1
	end
	for _ in pairs(trailRecs) do
		trails += 1
	end
	return { motion = #motionList, rainbow = #rainbowList, glitch = #glitchList, loc = loc, trails = trails, wind = windOn }
end

return Fx
