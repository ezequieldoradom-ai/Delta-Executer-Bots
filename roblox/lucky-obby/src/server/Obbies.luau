-- Lucky Obby Race — OBBYS NORMALES (fácil, medio y difícil) (Shadow)
--   · Tres recorridos fijos y largos, aparte de la carrera, cada uno con su portal en el vestíbulo.
--   · Puntos de control cada 3 tramos; si caes o tocas lava, vuelves al último (lo hace tu pantalla).
--   · Al llegar a la meta: monedas (más cuanto más difícil) y cuenta para el tablón "🏅 OBBYS".
--   · Anti-trampas: los puntos de control cuentan de uno en uno y hace falta un tiempo mínimo creíble.
local Players = game:GetService("Players")

local Obbies = {}
local G, C

local DEFS = {
	{ id = "easy", icon = "🟢", es = "FÁCIL", en = "EASY", segments = 30, x = -300, seed = 11, reward = 60, color = Color3.fromRGB(90, 230, 120), minTime = 45, types = { "steps", "stones", "lava", "beams", "pads", "movers" } },
	{ id = "medium", icon = "🟠", es = "MEDIO", en = "MEDIUM", segments = 45, x = -380, seed = 22, reward = 180, color = Color3.fromRGB(255, 140, 40), minTime = 90, types = { "stones", "lava", "spinners", "movers", "beams", "pads", "belts", "pillars", "gaps" } },
	{ id = "hard", icon = "🔴", es = "DIFÍCIL", en = "HARD", segments = 60, x = -460, seed = 33, reward = 450, color = Color3.fromRGB(255, 80, 90), minTime = 150, types = { "spinners", "sweepers", "gaps", "tightrope", "belts", "pillars", "movers", "stones", "gaps", "tightrope" } },
}
Obbies.DEFS = DEFS
local Y, Z = 60, -40
Obbies.Y = Y

local sessions = {} -- [player] = { def, info, cp, t0 }
Obbies.sessions = sessions
local built = {} -- [id] = info de Course.generate

local function hrpOf(p)
	local c = p.Character
	return c and c:FindFirstChild("HumanoidRootPart")
end
local function toast(p, es, en)
	-- el texto va en español; los que juegan en otro idioma lo ven traducido (Translate)
	G.Net.Event:FireClient(p, "toast", { text = es, en = en })
end

local function setCp(p, s, idx)
	s.cp = idx
	local cp = s.info.checkpoints[idx]
	if cp then
		p:SetAttribute("ObbyCP", cp.pos)
	end
end

function Obbies.leave(p, toLobby)
	local s = sessions[p]
	if not s then
		return
	end
	sessions[p] = nil
	p:SetAttribute("Obby", nil)
	p:SetAttribute("ObbyCP", nil)
	p:SetAttribute("ObbyStage", nil)
	if toLobby then
		local hrp = hrpOf(p)
		if hrp then
			local L = C.COURSE.LOBBY
			hrp.AssemblyLinearVelocity = Vector3.zero
			hrp.CFrame = CFrame.new(L + Vector3.new(math.random(-6, 6), 3, math.random(-6, 6)))
		end
	end
end

function Obbies.start(p, id)
	local def
	for _, d in ipairs(DEFS) do
		if d.id == id then
			def = d
		end
	end
	local info = def and built[id]
	local hrp = hrpOf(p)
	if not info or not hrp then
		return false
	end
	if G.Race.isRacing(p) then
		return false
	end
	-- sale de lo que estuviera haciendo
	if G.Slap and G.Slap.stationOf(p) then
		G.Slap.leave(p)
	end
	if G.Hill and G.Hill.memberOf(p) then
		G.Hill.leave(p)
	end
	if G.Race.joined then
		G.Race.joined[p] = nil
	end
	sessions[p] = { def = def, info = info, cp = 0, t0 = os.clock() }
	p:SetAttribute("Obby", id)
	p:SetAttribute("ObbyStage", 0)
	setCp(p, sessions[p], 0)
	local start = info.checkpoints[0].pos
	hrp.AssemblyLinearVelocity = Vector3.zero
	hrp.CFrame = CFrame.lookAt(start, start + Vector3.new(0, 0, 1))
	return true
end

local doneHere = {} -- [player] = { [id] = true }: ya lo completó en este servidor (las repeticiones pagan menos)
local function finish(p, s)
	local secs = os.clock() - s.t0
	local seen = doneHere[p] or {}
	doneHere[p] = seen
	local coins = seen[s.def.id] and math.floor(s.def.reward * 0.25) or s.def.reward
	seen[s.def.id] = true
	G.Data.addCoins(p, coins)
	G.Data.addObby(p, s.def.id)
	G.Net.Event:FireClient(p, "obbyDone", { id = s.def.id, coins = coins, time = secs })
	sessions[p] = nil
	p:SetAttribute("Obby", nil)
	p:SetAttribute("ObbyCP", nil)
	p:SetAttribute("ObbyStage", nil)
	task.delay(4, function()
		if p.Parent and not sessions[p] and not G.Race.isRacing(p) then
			local hrp = hrpOf(p)
			-- solo si sigue en este obby (no si ya se lo llevó la carrera u otra cosa)
			if hrp and math.abs(hrp.Position.X - s.info.x) <= 45 then
				local L = C.COURSE.LOBBY
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = CFrame.new(L + Vector3.new(math.random(-6, 6), 3, math.random(-6, 6)))
			end
		end
	end)
end

-- vigilancia: puntos de control, tramo actual, meta, y si te has ido (carrera, otra zona…)
local function tick()
	for p, s in pairs(sessions) do
		local hrp = hrpOf(p)
		if not p.Parent then
			sessions[p] = nil
			continue
		end
		local hum = p.Character and p.Character:FindFirstChildOfClass("Humanoid")
		if hrp and hum and hum.Health > 0 and os.clock() >= (s.graceUntil or 0) then
			local pos = hrp.Position
			local info = s.info
			-- fuera del obby (te han llevado a la carrera, al vestíbulo…) → se acaba la sesión
			if math.abs(pos.X - info.x) > 45 or pos.Z < info.checkpoints[0].pos.Z - 40 then
				Obbies.leave(p, false)
				continue
			end
			-- caída muy lejos (por si la pantalla no te devolvió): al punto de control
			if pos.Y < info.y - 60 then
				local cp = info.checkpoints[s.cp]
				s.lastZ = nil
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = CFrame.lookAt(cp.pos, cp.pos + Vector3.new(0, 0, 1))
				continue
			end
			-- avance imposible (teletransporte / velocidad trucada): de vuelta al punto de control.
			-- Solo mira hacia delante (volver atrás al caer es normal) y deja margen de sobra para cintas e impulsores.
			local now = os.clock()
			if not Obbies.noSpeedCheck and s.lastZ and now - s.lastT < 1 and pos.Z - s.lastZ > 70 * (now - s.lastT) + 6 then
				local cp = info.checkpoints[s.cp]
				s.lastZ = nil
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = CFrame.lookAt(cp.pos, cp.pos + Vector3.new(0, 0, 1))
				continue
			end
			s.lastZ, s.lastT = pos.Z, now
			-- punto de control = franja que se cruza (la plataforma y el tramo siguiente), no una caja pequeña:
			-- así no se escapa aunque pases saltando desde un escalón alto
			local nextCp = info.checkpoints[s.cp + 1]
			if nextCp and pos.Z >= nextCp.z0 and pos.Z <= nextCp.z0 + info.segLen and math.abs(pos.X - info.x) <= C.COURSE.WIDTH / 2 + 3 and pos.Y > info.y - 6 and pos.Y < info.y + 24 then
				setCp(p, s, s.cp + 1)
				G.Net.Event:FireClient(p, "checkpoint", { index = s.cp })
			end
			local stage = math.clamp(math.floor((pos.Z - info.z0) / info.segLen) + 1, 0, info.segments)
			if stage ~= p:GetAttribute("ObbyStage") then
				p:SetAttribute("ObbyStage", stage)
			end
			if pos.Z >= info.finishZ and pos.Y > info.y - 8 then
				if s.cp >= #info.checkpoints and os.clock() - s.t0 >= info.minTime then
					finish(p, s)
				elseif s.cp < #info.checkpoints and os.clock() - (s.warnAt or 0) > 5 then
					s.warnAt = os.clock()
					G.Net.Event:FireClient(p, "toast", { text = "⚠️ Te falta un punto de control: vuelve atrás" })
				end
			end
		end
	end
end

-- portales en el vestíbulo (lado contrario a la colina), buscando huecos libres
local function portals()
	local f = Instance.new("Folder")
	f.Name = "ObbyPortals"
	local L = C.COURSE.LOBBY
	local function free(pos)
		for _, x in ipairs(workspace:GetPartBoundsInBox(CFrame.new(pos + Vector3.new(0, 5.5, 0)), Vector3.new(9, 9, 9))) do
			if x.CanCollide and x.Name ~= "LobbyFloor" and x.Name ~= "Platform" and x.Name ~= "LobbyRim" then
				return false
			end
		end
		return true
	end
	-- huecos de SUELO libre: el rayo tiene que dar en el suelo del vestíbulo (no encima de un puesto o un tejado),
	-- sin nada sólido alrededor, lejos del centro (aparición), de la plataforma de la colina y entre sí
	local floorY
	do
		local hit = workspace:Raycast(Vector3.new(L.X, L.Y + 40, L.Z + 14), Vector3.new(0, -80, 0))
		floorY = hit and hit.Position.Y or (L.Y - 3)
	end
	local hillPad = G.Hill and G.Hill.PAD
	-- pasillos que no se pueden pisar sin querer: hacia la carrera (+Z), la plaza de guantazos y la colina
	local Decor = require(script.Parent.Decor)
	local lanes = { math.pi / 2 }
	for _, t in ipairs({ Decor.PLAZA, Decor.HILL }) do
		if t then
			table.insert(lanes, math.atan2(t.Z - L.Z, t.X - L.X))
		end
	end
	local stands = {}
	local shop = workspace:FindFirstChild("TrailShop")
	if shop then
		for _, d in ipairs(shop:GetChildren()) do
			if d.Name == "Pedestal" then
				table.insert(stands, d.Position)
			end
		end
	end
	if hillPad then
		table.insert(stands, hillPad) -- (y de la plataforma dorada de la colina)
	end
	local function spotAt(r, deg)
		local a = math.rad(deg)
		for _, g in ipairs(lanes) do
			if math.cos(a - g) > 0 and math.abs(math.sin(a - g)) * r < 11 then
				return nil
			end
		end
		local p = Vector3.new(L.X + math.cos(a) * r, 0, L.Z + math.sin(a) * r)
		local hit = workspace:Raycast(p + Vector3.new(0, 40, 0), Vector3.new(0, -80, 0))
		if not hit or math.abs(hit.Position.Y - floorY) > 0.6 then
			return nil
		end
		local pos = Vector3.new(p.X, floorY, p.Z)
		if not free(pos) then
			return nil
		end
		-- lejos de los puestos de estelas (sus carteles flotantes se pisarían con los de los portales)
		for _, st in ipairs(stands) do
			if Vector3.new(st.X - pos.X, 0, st.Z - pos.Z).Magnitude < 16 then
				return nil
			end
		end
		if hillPad and Vector3.new(hillPad.X - pos.X, 0, hillPad.Z - pos.Z).Magnitude < 16 then
			return nil
		end
		-- no delante de un tablón (el cartel flotante taparía sus filas vistas desde el centro)
		local out = Vector3.new(pos.X - L.X, 0, pos.Z - L.Z).Unit
		local bh = workspace:Raycast(pos + Vector3.new(0, 8, 0), out * 30)
		if bh and (bh.Instance.Name == "Board" or bh.Instance.Name == "BoardPost" or bh.Instance.Name == "BoardTrim") then
			return nil
		end
		return pos
	end
	-- 1) los tres JUNTOS (uno al lado del otro en el mismo arco)
	local spots = {}
	for _, r in ipairs({ 30, 34, 26, 38, 22, 42, 18 }) do
		if #spots == 3 then
			break
		end
		local step = math.deg(2 * math.asin(4.8 / r)) + 1
		for a0 = 0, 355, 5 do
			local a, b2, c = spotAt(r, a0 - step), spotAt(r, a0), spotAt(r, a0 + step)
			if a and b2 and c then
				spots = { a, b2, c }
				break
			end
		end
	end
	Obbies.together = #spots == 3
	-- 2) si no caben en un mismo arco: los tres huecos libres MÁS CERCANOS entre sí
	if #spots < 3 then
		local cands = {}
		for r = 23, 44, 3 do
			for deg = 0, 350, 10 do
				local pos = spotAt(r, deg)
				if pos then
					table.insert(cands, pos)
				end
			end
		end
		local best, bestCost
		for _, a in ipairs(cands) do
			-- los dos más cercanos a 'a' que estén a 9+ studs de él y entre sí
			local near = {}
			for _, b2 in ipairs(cands) do
				local d = (b2 - a).Magnitude
				if d >= 13 then
					table.insert(near, { pos = b2, d = d })
				end
			end
			table.sort(near, function(x, y)
				return x.d < y.d
			end)
			for k = 1, math.min(#near, 6) do
				for m = k + 1, math.min(#near, 7) do
					local d3 = (near[k].pos - near[m].pos).Magnitude
					if d3 >= 13 then
						local cost = near[k].d + near[m].d + d3
						if not bestCost or cost < bestCost then
							best, bestCost = { near[k].pos, a, near[m].pos }, cost
						end
					end
				end
			end
		end
		spots = best or {}
		if #spots < 3 then
			for _, c in ipairs(cands) do
				if #spots < 3 then
					table.insert(spots, c)
				end
			end
		end
	end
	local pads = {}
	for i, def in ipairs(DEFS) do
		local pos = spots[i]
		if not pos then
			warn("[Obbies] no hay sitio para el portal " .. def.id)
			continue
		end
		local base = Instance.new("Part")
		base.Anchored = true
		base.Shape = Enum.PartType.Cylinder
		base.Size = Vector3.new(0.6, 8, 8)
		base.CFrame = CFrame.new(pos + Vector3.new(0, 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
		base.Color = Color3.fromRGB(50, 40, 80)
		base.Material = Enum.Material.SmoothPlastic
		base.Name = "ObbyPadBase"
		base.Parent = f
		local pad = base:Clone()
		pad.Name = "ObbyPad_" .. def.id
		pad.Size = Vector3.new(0.2, 6.4, 6.4)
		pad.CFrame = CFrame.new(pos + Vector3.new(0, 0.65, 0)) * CFrame.Angles(0, 0, math.rad(90))
		pad.Color = def.color
		pad.Material = Enum.Material.Neon
		pad.CanCollide = false
		pad.Parent = f
		local bb = Instance.new("BillboardGui")
		bb.Size = UDim2.fromScale(8.5, 3.2)
		bb.StudsOffsetWorldSpace = Vector3.new(0, 4.6, 0)
		bb.LightInfluence = 0
		bb.MaxDistance = 160
		bb.Parent = pad
		local l = Instance.new("TextLabel")
		l.BackgroundTransparency = 1
		l.Size = UDim2.fromScale(1, 1)
		l.TextScaled = true
		l.RichText = true
		l.Font = Enum.Font.LuckiestGuy
		l.TextColor3 = def.color
		l.TextStrokeTransparency = 0
		l.Text = string.format('%s OBBY %s\n<font color="#FFFFFF">%d tramos · 💰 %d</font>', def.icon, def.es, def.segments, def.reward)
		l.Parent = bb
		local pe = Instance.new("ParticleEmitter")
		pe.Texture = "rbxasset://textures/particles/sparkles_main.dds"
		pe.Rate = 10
		pe.Lifetime = NumberRange.new(1, 1.6)
		pe.Speed = NumberRange.new(3, 6)
		pe.EmissionDirection = Enum.NormalId.Right
		pe.SpreadAngle = Vector2.new(10, 10)
		pe.LightEmission = 0.5
		pe.Color = ColorSequence.new(def.color)
		pe.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.4), NumberSequenceKeypoint.new(1, 0) })
		pe.Parent = pad
		pads[def.id] = pos
	end
	f.Parent = workspace
	Obbies.PADS = pads
	-- pisar el portal (por distancia: Touched falla si apareces encima)
	local cool = {}
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, p in ipairs(Players:GetPlayers()) do
				local hrp = hrpOf(p)
				if hrp and not sessions[p] and not (cool[p] and os.clock() - cool[p] < 3) and not (G.Race.joined and G.Race.joined[p]) then
					for id, pos in pairs(pads) do
						local d = Vector3.new(hrp.Position.X - pos.X, 0, hrp.Position.Z - pos.Z).Magnitude
						local dy = hrp.Position.Y - pos.Y
						if d < 3.2 and dy > 0 and dy < 6 then
							cool[p] = os.clock()
							Obbies.start(p, id)
							break
						end
					end
				end
			end
		end
	end)
	-- tablón de obbys completados: en un hueco libre del anillo de tablones (no encima de nada ni en un pasillo)
	if #spots > 0 and G.Hub and G.Hub.addBoard then
		local function boardCF(deg, r)
			local a = math.rad(deg)
			for _, g in ipairs(lanes) do
				if math.abs((math.deg(a - g) + 180) % 360 - 180) < 25 then
					return nil
				end
			end
			local pos = Vector3.new(L.X + math.cos(a) * r, floorY + 10, L.Z + math.sin(a) * r)
			local cf = CFrame.lookAt(pos, Vector3.new(L.X, pos.Y, L.Z))
			for _, q in ipairs(spots) do
				if Vector3.new(q.X - pos.X, 0, q.Z - pos.Z).Magnitude < 14 then
					return nil
				end
			end
			if hillPad and Vector3.new(hillPad.X - pos.X, 0, hillPad.Z - pos.Z).Magnitude < 16 then
				return nil
			end
			for _, x in ipairs(workspace:GetPartBoundsInBox(cf * CFrame.new(0, -1, 0), Vector3.new(23, 20, 5))) do
				if x.CanCollide and x.Name ~= "LobbyFloor" and x.Name ~= "LobbyRim" and x.Name ~= "Platform" then
					return nil
				end
			end
			return cf
		end
		-- lo más cerca posible (en ángulo) de los portales
		local mid = Vector3.zero
		for _, q in ipairs(spots) do
			mid += q
		end
		mid /= #spots
		local base = math.deg(math.atan2(mid.Z - L.Z, mid.X - L.X))
		local cf
		for _, r in ipairs({ 46, 50, 42 }) do
			for off = 0, 180, 10 do
				cf = cf or boardCF(base + off, r) or boardCF(base - off, r)
			end
		end
		if cf then
			pcall(G.Hub.addBoard, cf, "🏅 OBBYS COMPLETADOS", Color3.fromRGB(120, 230, 255), "obbies", "LuckyObby_Obbies_v1")
		else
			warn("[Obbies] sin hueco para el tablón de obbys")
		end
	end
end

function Obbies.init(g)
	G = g
	C = g.Config
	G.Obbies = Obbies
	local root = Instance.new("Folder")
	root.Name = "Obbies"
	for _, def in ipairs(DEFS) do
		local info = G.Course.generate({ name = "Obby_" .. def.id, seed = def.seed, segments = def.segments, types = def.types, x = def.x, y = Y, z = Z })
		info.folder.Parent = root
		built[def.id] = info
		-- tiempo mínimo creíble: nunca menos que recorrerlo a 18 studs/s (un jugador va a 16)
		info.minTime = math.max(def.minTime, (info.finishZ - info.checkpoints[0].pos.Z) / 18)
	end
	root.Parent = workspace
	Obbies.built = built
	portals()
	G.Net.Obby.OnServerEvent:Connect(function(p, kind)
		if kind == "leave" then
			Obbies.leave(p, true)
		end
	end)
	Players.PlayerRemoving:Connect(function(p)
		sessions[p] = nil
		doneHere[p] = nil
	end)
	-- al reaparecer (si mueres), vuelves a tu punto de control
	local function onPlayer(p)
		p.CharacterAdded:Connect(function(char)
			local s0 = sessions[p]
			if s0 then
				s0.graceUntil = os.clock() + 2 -- reapareces en el vestíbulo: que la vigilancia no te dé por "fuera"
			end
			task.wait(0.4)
			local s = sessions[p]
			local hrp = char:FindFirstChild("HumanoidRootPart") or char:WaitForChild("HumanoidRootPart", 3)
			if s and hrp then
				local cp = s.info.checkpoints[s.cp]
				hrp.AssemblyLinearVelocity = Vector3.zero
				hrp.CFrame = CFrame.lookAt(cp.pos, cp.pos + Vector3.new(0, 0, 1))
			end
		end)
	end
	Players.PlayerAdded:Connect(onPlayer)
	for _, p in ipairs(Players:GetPlayers()) do
		onPlayer(p)
	end
	task.spawn(function()
		while true do
			task.wait(0.2)
			local ok, err = pcall(tick)
			if not ok then
				warn("[Obbies] " .. tostring(err))
			end
		end
	end)
end

return Obbies
