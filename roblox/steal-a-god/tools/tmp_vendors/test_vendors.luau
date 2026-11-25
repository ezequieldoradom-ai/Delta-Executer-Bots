-- Pruebas de los vendedores (Vendors.luau) y de las auras de los jugadores (AuraFx.luau)
local CollectionService = game:GetService("CollectionService")
local out = {}
local fails = 0
local function add(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring((select(i, ...)))
	end
	table.insert(out, table.concat(t, " "))
end
local function step(name, fn)
	local ok, err = pcall(fn)
	if ok then
		add("✅", name)
	else
		fails += 1
		add("❌", name, "->", err)
	end
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
step("Arranque del servidor", function()
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
	G.DayNight.init(G) G.Combat.init(G) G.Packs.init(G) G.Shop.init(G) G.Boards.init(G) G.Core.init(G)
end)

---------------------------------------------------------------------
-- VENDEDORES
---------------------------------------------------------------------
-- Alcance horizontal (desde el centro del santuario) y altura máxima de una pieza, según su forma
local function reach(p, centre)
	local pts = {}
	local s = p.Size / 2
	if p:IsA("Part") and p.Shape == Enum.PartType.Ball then
		local r = math.min(s.X, s.Y, s.Z)
		local c = p.Position
		return math.sqrt((c.X - centre.X) ^ 2 + (c.Z - centre.Z) ^ 2) + r, c.Y + r
	elseif p:IsA("Part") and p.Shape == Enum.PartType.Cylinder then
		local r = math.min(s.Y, s.Z)
		for _, sx in ipairs({ -1, 1 }) do
			for k = 0, 23 do
				local a = k / 24 * math.pi * 2
				table.insert(pts, p.CFrame * Vector3.new(sx * s.X, math.cos(a) * r, math.sin(a) * r))
			end
		end
	else
		for _, sx in ipairs({ -1, 1 }) do
			for _, sy in ipairs({ -1, 1 }) do
				for _, sz in ipairs({ -1, 1 }) do
					table.insert(pts, p.CFrame * Vector3.new(sx * s.X, sy * s.Y, sz * s.Z))
				end
			end
		end
	end
	local far, top = 0, -math.huge
	for _, v in ipairs(pts) do
		far = math.max(far, math.sqrt((v.X - centre.X) ^ 2 + (v.Z - centre.Z) ^ 2))
		top = math.max(top, v.Y)
	end
	return far, top
end

step("Vendedores: módulo cargado y sin errores de construcción", function()
	assert(G.Vendors, "no existe el módulo Vendors")
	assert(#G.Vendors.errors == 0, table.concat(G.Vendors.errors, " | "))
end)

local EXPECT = {
	aura = { folder = "VendorAura", action = "Auras", object = "Hecate" },
	coach = { folder = "VendorCoach", action = "Coaches", object = "Chiron" },
}
for _, key in ipairs({ "aura", "coach" }) do
	local info = EXPECT[key]
	step("Vendedor " .. key .. ": contratos (carpeta, aviso, cartel, dios)", function()
		local V = G.Config.VENDORS[key]
		local folder = G.World.getRoot():FindFirstChild(info.folder)
		assert(folder and folder:IsA("Folder"), "falta la carpeta " .. info.folder)
		assert(folder:GetAttribute("VendorPos") == V.pos, "atributo VendorPos")
		-- aviso de interacción
		local prompts = {}
		for _, p in ipairs(CollectionService:GetTagged("VendorPrompt")) do
			if p:IsDescendantOf(folder) then
				table.insert(prompts, p)
			end
		end
		assert(#prompts == 1, "avisos: " .. #prompts)
		local p = prompts[1]
		assert(p:IsA("ProximityPrompt"), "no es ProximityPrompt")
		assert(p:GetAttribute("Vendor") == key, "atributo Vendor del aviso")
		assert(p.HoldDuration == 0 and p.MaxActivationDistance == 16 and p.RequiresLineOfSight == false, "ajustes del aviso")
		assert(p.ActionText == info.action and p.ObjectText == info.object, "textos del aviso")
		assert(not CollectionService:HasTag(p, "LocPrompt"), "no debe llevar LocPrompt")
		assert(p.Parent:IsA("BasePart") and p.Parent.Anchored, "el aviso debe colgar de una pieza anclada")
		local flat = Vector3.new(p.Parent.Position.X - V.pos.X, 0, p.Parent.Position.Z - V.pos.Z).Magnitude
		assert(flat < 4, "aviso lejos del vendedor: " .. flat)
		-- cartel
		local plates = {}
		for _, bb in ipairs(CollectionService:GetTagged("Loc")) do
			if bb:IsDescendantOf(folder) then
				table.insert(plates, bb)
			end
		end
		assert(#plates == 1, "carteles: " .. #plates)
		local bb = plates[1]
		assert(bb:IsA("BillboardGui") and bb:GetAttribute("Vendor") == key and bb.MaxDistance == 240, "cartel")
		assert(bb:FindFirstChild("Label") and #bb.Label.Text > 3, "texto por defecto del cartel")
		assert(bb.Adornee and bb.Adornee:IsA("BasePart"), "adornee del cartel")
		local plateTop = bb.Adornee.Position.Y + bb.StudsOffset.Y + bb.Size.Y.Scale / 2
		-- dios
		local npc = folder:FindFirstChildWhichIsA("Model")
		assert(npc and npc:GetAttribute("Vendor") == key, "falta el dios")
		local root = npc.PrimaryPart
		assert(root and root.Anchored, "raíz del dios sin anclar")
		for _, z in ipairs({ 62, 68 }) do -- hacia la fuente de la plaza
			local toPlaza = (Vector3.new(0, root.Position.Y, z) - root.Position).Unit
			assert(root.CFrame.LookVector:Dot(toPlaza) > 0.99, "el dios no mira a la plaza")
		end
		local bcf, bsize = npc:GetBoundingBox()
		add(string.format("   %s: %s · altura %.1f (de %.1f a %.1f) · ancho %.1f · cartel hasta %.1f", npc.Name, npc:GetAttribute("Avatar") and "avatar R15" or "figura de piezas", bsize.Y, bcf.Y - bsize.Y / 2, bcf.Y + bsize.Y / 2, bsize.X, plateTop))
		if npc:GetAttribute("Avatar") then
			local hum = npc:FindFirstChildOfClass("Humanoid")
			assert(hum, "sin Humanoid")
			add("   animación:", tostring(npc:GetAttribute("Anim")))
			local feet = math.min(npc.LeftFoot.Position.Y - npc.LeftFoot.Size.Y / 2, npc.RightFoot.Position.Y - npc.RightFoot.Size.Y / 2)
			-- Hécate levita un poco sobre el círculo de runas; Quirón pisa el último escalón
			local hover = CollectionService:HasTag(root, "FxBob") and 0.9 or 0
			assert(math.abs(feet - 1.2 - hover) < 0.25, "los pies no están donde deben: " .. feet)
		end
		assert(plateTop <= 30, "cartel demasiado alto: " .. plateTop)
	end)

	step("Vendedor " .. key .. ": geometría y presupuesto", function()
		local V = G.Config.VENDORS[key]
		local folder = G.World.getRoot():FindFirstChild(info.folder)
		local npc = folder:FindFirstChildWhichIsA("Model")
		local count, hidden, horse, solidMax, anyMax, top = 0, 0, 0, 0, 0, 0
		local solidWho, anyWho, topWho = "", "", ""
		local names = {}
		for _, d in ipairs(folder:GetDescendants()) do
			if d:IsA("BasePart") and not d:IsDescendantOf(npc) then
				count += 1
				names[d.Name] = (names[d.Name] or 0) + 1
				if d.Transparency >= 1 then
					hidden += 1
				end
				if d.Name:sub(1, 5) == "Horse" then
					horse += 1
				end
				assert(d.Anchored, d.Name .. " sin anclar")
				local far, y = reach(d, V.pos)
				if far > anyMax then
					anyMax, anyWho = far, d.Name
				end
				if d.CanCollide and far > solidMax then
					solidMax, solidWho = far, d.Name
				end
				if d.Name ~= "Beacon" and y > top then
					top, topWho = y, d.Name
				end
				if d.Name ~= "Beacon" and not d.CanCollide then
					assert(d.CanQuery == false and d.CanTouch == false, d.Name .. ": decoración con consultas/toques")
				end
				if d.Name == "Beacon" then
					assert(d.Material == Enum.Material.Neon and d.Transparency >= 0.7 and not d.CanCollide, "faro")
					add(string.format("   faro: de %.1f a %.1f", d.Position.Y - d.Size.X / 2, d.Position.Y + d.Size.X / 2))
				end
			end
		end
		local list = {}
		for n, c in pairs(names) do
			table.insert(list, n .. "×" .. c)
		end
		table.sort(list)
		add("   piezas:", count, "(invisibles " .. hidden .. ", cuerpo de caballo " .. horse .. ")")
		add("   " .. table.concat(list, " "))
		add(string.format("   radio sólido %.2f (%s) · radio total %.2f (%s) · altura %.1f (%s)", solidMax, solidWho, anyMax, anyWho, top, topWho))
		assert(count <= 90, "demasiadas piezas: " .. count)
		assert(solidMax <= 8.5, "pieza sólida fuera del radio 8,5: " .. solidWho .. " " .. solidMax)
		assert(anyMax <= 8.5, "pieza fuera del radio 8,5: " .. anyWho .. " " .. anyMax)
		assert(top <= 30, "demasiado alto: " .. topWho .. " " .. top)
		-- emisores y luces (aparte de los braseros)
		local emitters, lights, brazierFx = 0, 0, 0
		for _, d in ipairs(folder:GetDescendants()) do
			local inBrazier = d:FindFirstAncestor("BrazierBowl") ~= nil
			if d:IsA("ParticleEmitter") or d:IsA("Fire") or d:IsA("Smoke") or d:IsA("Sparkles") then
				if d:IsDescendantOf(npc) then
					error("emisor dentro del dios: " .. d:GetFullName())
				elseif inBrazier then
					brazierFx += 1
				else
					emitters += 1
					assert(d:IsA("ParticleEmitter") and d.Rate <= 12, d.Name .. ": Rate " .. tostring(d.Rate))
					assert(d.Parent:IsA("Attachment"), d.Name .. " no cuelga de un Attachment")
					assert(d.Texture ~= "", d.Name .. " sin textura")
				end
			elseif d:IsA("Light") then
				assert(d.Shadows == false, "luz con sombras: " .. d:GetFullName())
				if not inBrazier then
					lights += 1
				end
			end
		end
		add("   emisores:", emitters, "luces:", lights, "braseros:", brazierFx)
		assert(emitters <= 3, "emisores: " .. emitters)
		assert(lights <= 2, "luces: " .. lights)
		assert(brazierFx == 2, "braseros: " .. brazierFx)
		-- etiquetas de animación
		local tags = { FxSpin = 0, FxBob = 0, FxOrbit = 0 }
		for tagName in pairs(tags) do
			for _, inst in ipairs(CollectionService:GetTagged(tagName)) do
				if inst:IsDescendantOf(folder) then
					tags[tagName] += 1
					assert(inst:IsA("BasePart") and inst.Anchored, tagName .. " en algo que no es una pieza anclada")
					if tagName == "FxOrbit" then
						assert(inst.Parent:IsA("BasePart"), "FxOrbit: su padre debe ser la pieza que orbita")
						assert(type(inst:GetAttribute("OrbitRadius")) == "number" and type(inst:GetAttribute("OrbitSpeed")) == "number", "FxOrbit sin atributos")
					elseif tagName == "FxBob" then
						-- la pieza debe estar derecha (solo giro en Y) para que flote en vertical
						assert(inst.CFrame.UpVector.Y > 0.999, inst.Name .. ": FxBob en pieza inclinada")
					end
				end
			end
		end
		add("   etiquetas: FxSpin", tags.FxSpin, "FxBob", tags.FxBob, "FxOrbit", tags.FxOrbit)
		assert(tags.FxSpin >= 1 and tags.FxBob >= 1 and tags.FxOrbit >= 1, "faltan etiquetas de animación")
		local runes = folder:FindFirstChild("RuneCircle")
		assert(runes and CollectionService:HasTag(runes, "FxSpin") and runes:GetAttribute("SpinAxis") == "X", "círculo de runas")
		assert(#runes:GetChildren() == 2 and runes:FindFirstChildOfClass("Decal").Texture == G.Config.VFX.runes, "calcomanías de runas")
		assert(runes.CFrame.RightVector.Y > 0.999, "el círculo de runas no está tumbado (su eje X debe mirar hacia arriba)")
	end)
end

step("Vendedores: zona libre delante (se puede llegar andando desde la plaza)", function()
	-- del borde de la plaza al dios no hay nada sólido más alto que un escalón
	for _, key in ipairs({ "aura", "coach" }) do
		local V = G.Config.VENDORS[key]
		local folder = G.World.getRoot():FindFirstChild(EXPECT[key].folder)
		local params = RaycastParams.new()
		params.FilterType = Enum.RaycastFilterType.Include
		params.FilterDescendantsInstances = { folder }
		local dir = (Vector3.new(0, 0, 62) - V.pos).Unit
		for _, side in ipairs({ -3, 0, 3 }) do
			local right = dir:Cross(Vector3.yAxis)
			local from = V.pos + dir * 12 + right * side + Vector3.new(0, 2.6, 0)
			local hit = workspace:Raycast(from, -dir * 9, params)
			assert(not hit, key .. ": algo sólido tapa la entrada: " .. (hit and hit.Instance.Name or ""))
		end
	end
end)

step("Vendedores: figura de piezas de reserva (si fallara el avatar)", function()
	for _, id in ipairs({ "v_hecate", "v_quiron" }) do
		local m = G.GodModel.buildParts({ id = id, myth = "greek", r = 0, name = id }, Color3.new(1, 1, 1))
		assert(m.PrimaryPart, id .. " sin PrimaryPart")
		m:ScaleTo(2.3)
		add(string.format("   %s: %d piezas, altura %.1f", id, #m:GetChildren(), m:GetExtentsSize().Y))
		m:Destroy()
	end
end)

---------------------------------------------------------------------
-- AURAS DE LOS JUGADORES
---------------------------------------------------------------------
local function inspect(hrp)
	local rate, emitters, lights = 0, 0, 0
	for _, ch in ipairs(hrp:GetChildren()) do
		assert(ch:IsA("Attachment") and ch.Name == "AuraFX", "hijo inesperado: " .. ch.Name .. " (" .. ch.ClassName .. ")")
		for _, e in ipairs(ch:GetChildren()) do
			if e:IsA("ParticleEmitter") then
				emitters += 1
				rate += e.Rate
				assert(e.Texture ~= "" and e.Enabled, e.Name .. ": sin textura o apagado")
			elseif e:IsA("PointLight") then
				lights += 1
				assert(e.Shadows == false, "luz con sombras")
			else
				error("objeto inesperado en el aura: " .. e.ClassName)
			end
		end
	end
	for _, d in ipairs(hrp:GetDescendants()) do
		assert(not d:IsA("BasePart") and not d:IsA("JointInstance") and not d:IsA("WeldConstraint") and not d:IsA("LuaSourceContainer"), "el aura creó " .. d.ClassName)
		if d:IsA("ParticleEmitter") then
			assert(d.Parent.Name == "AuraFX" and d.Parent.Parent == hrp, "emisor fuera de un Attachment AuraFX")
		end
	end
	return rate, emitters, lights
end

step("AuraFx: las 6 auras, limpieza y aura desconocida", function()
	local A = G.AuraFx
	assert(A and A.apply, "no existe AuraFx.apply")
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Anchored = true
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Parent = workspace
	local last = 0
	for i, aura in ipairs(G.Config.AURAS) do
		A.apply(hrp, aura)
		local rate, emitters, lights = inspect(hrp)
		add(string.format("   %-9s %2d emisores · %4.1f partículas/s · %d luz", aura.id, emitters, rate, lights))
		assert(emitters >= 3, aura.id .. ": pocas capas")
		assert(lights <= 1, aura.id .. ": más de una luz")
		assert(hrp:GetAttribute("AuraColor") == aura.color, aura.id .. ": atributo AuraColor")
		assert(rate <= 70, aura.id .. ": demasiadas partículas " .. rate)
		if i == 1 then
			assert(rate <= 30, "la más barata pasa de 30: " .. rate)
		end
		assert(emitters >= last, aura.id .. ": menos capas que la anterior")
		last = emitters
	end
	-- repetir no acumula
	A.apply(hrp, G.Config.AURAS[6])
	local n1 = #hrp:GetDescendants()
	A.apply(hrp, G.Config.AURAS[6])
	assert(#hrp:GetDescendants() == n1, "aplicar dos veces acumula objetos")
	-- quitar el aura no deja nada
	A.apply(hrp, nil)
	assert(#hrp:GetChildren() == 0, "la limpieza deja " .. #hrp:GetChildren() .. " objetos")
	assert(hrp:GetAttribute("AuraColor") == nil, "AuraColor no se borró")
	-- aura desconocida → genérica
	A.apply(hrp, { id = "nueva", color = Color3.fromRGB(0, 255, 0) })
	local _, emitters = inspect(hrp)
	assert(emitters >= 1 and hrp:GetAttribute("AuraColor") == Color3.fromRGB(0, 255, 0), "aura genérica")
	-- no toca lo que no es suyo
	local other = Instance.new("Attachment")
	other.Name = "RootAttachment"
	other.Parent = hrp
	A.apply(hrp, nil)
	assert(other.Parent == hrp and #hrp:GetChildren() == 1, "borró algo que no era del aura")
	-- entradas raras no rompen
	A.apply(nil, G.Config.AURAS[1])
	A.apply(hrp, { id = "sincolor" })
	A.apply(hrp, nil)
	hrp:Destroy()
end)

step("AuraFx: Core.applyAura la usa con un jugador simulado", function()
	local char = Instance.new("Model")
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Anchored = true
	hrp.Parent = char
	char.Parent = workspace
	local fp = { UserId = -901, Name = "Test901", DisplayName = "Test901", Character = char }
	local d = G.Data.sanitize(nil, G.Config)
	G.Data.profiles[fp] = d
	d.auras.sol = true
	d.aura = "sol"
	G.Core.applyAura(fp)
	local rate, emitters = inspect(hrp)
	assert(emitters >= 3 and rate > 0 and hrp:GetAttribute("AuraColor") == G.Config.AURA_BY_ID.sol.color, "no puso el aura")
	d.aura = nil
	G.Core.applyAura(fp)
	assert(#hrp:GetChildren() == 0, "no quitó el aura")
	G.Data.profiles[fp] = nil
	char:Destroy()
end)

add(fails == 0 and "🎉 VENDEDORES OK" or ("⚠️ FALLOS: " .. fails))
return table.concat(out, "\n")
