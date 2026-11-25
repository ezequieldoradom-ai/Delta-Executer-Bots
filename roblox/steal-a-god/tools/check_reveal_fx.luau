-- Prueba en un servidor de Roblox de la apertura por etapas (src/client/RevealFx.luau):
-- "¿COMÚN?" → se parte → "¿POCO COMÚN?"… hasta la rareza final, con una animación distinta por salto.
-- Monta una copia de la pantalla de apertura (mismas piezas que init.client) y comprueba textos,
-- transiciones sin repetir, tiempos, que no salte ningún error y que no quede nada al terminar.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local out, fails = {}, 0
local function add(...)
	table.insert(out, table.concat({ ... }, " "))
end
local function step(name, fn)
	local t0 = os.clock()
	local ok, err = pcall(fn)
	if ok then
		add(string.format("✅ %s (%.1f s)", name, os.clock() - t0))
	else
		fails += 1
		add("❌ " .. name .. " -> " .. tostring(err))
	end
end

local G = { Config = require(Shared.Config) }
G.PackStyle = require(Server.PackStyle)
G.PackStyle.init(G)
require(Server.PackTemplates).init(G)
local Config = G.Config
local Locale = require(Shared.Locale)
Locale.setSpanish(true)

local WHITE = Color3.new(1, 1, 1)
local function new(class, props, children)
	local o = Instance.new(class)
	for k, v in pairs(props or {}) do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	for _, c in ipairs(children or {}) do
		c.Parent = o
	end
	if props and props.Parent then
		o.Parent = props.Parent
	end
	return o
end
local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r or 14) })
end
local function stroke(color, th)
	return new("UIStroke", { Color = color or WHITE, Thickness = th or 2 })
end
local function gradient(c1, c2, rot)
	return new("UIGradient", { Color = ColorSequence.new(c1, c2), Rotation = rot or 90 })
end
local function darker(c, k)
	k = k or 0.55
	return Color3.new(c.R * k, c.G * k, c.B * k)
end
local played = {}

-- copia de la pantalla de apertura
local gui = new("ScreenGui", { Name = "RevealTest", Parent = game:GetService("StarterGui") })
local reveal = new("TextButton", { Text = "", BackgroundColor3 = Color3.new(0, 0, 0), BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 30, Parent = gui })
local rays = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromOffset(1000, 1000), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 31, Parent = reveal })
local rayFrames = {}
for i = 1, 6 do
	rayFrames[i] = new("Frame", { Size = UDim2.new(0, 70, 0.5, 0), Parent = rays })
end
local packCard = new("Frame", { Size = UDim2.fromOffset(190, 260), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 33, Parent = reveal }, { corner(18) })
local packGrad = gradient(WHITE, WHITE, 90)
packGrad.Parent = packCard
local packStroke = stroke(WHITE, 5)
packStroke.Parent = packCard
local packScale = new("UIScale", { Parent = packCard })
local packLabel = new("TextLabel", { Size = UDim2.new(1, -20, 0, 60), Parent = packCard })
local packVP = new("ViewportFrame", { Size = UDim2.fromScale(1.7, 1.35), Parent = packCard })
local packCam = new("Camera", { Parent = packVP })
packVP.CurrentCamera = packCam
local flash = new("Frame", { BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 40, Parent = reveal })

local client = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Client")
local RevealFx = require(client.RevealFx)
RevealFx.setup({
	reveal = reveal, packCard = packCard, packVP = packVP, packCam = packCam, packScale = packScale,
	packLabel = packLabel, packGrad = packGrad, packStroke = packStroke, flash = flash, rays = rays,
	rayFrames = rayFrames, burst = function() end, shake = function() end,
	play = function(name)
		played[name] = (played[name] or 0) + 1
	end,
	rcolor = function(r)
		return Config.RARITIES[r].color
	end,
	darker = darker, new = new, corner = corner, stroke = stroke, gradient = gradient,
	t = Locale.t, Locale = Locale, Config = Config,
})

local function upper(r)
	return Locale.upper(Locale.name(Config.RARITIES[r]))
end

-- Sigue el cartel durante la apertura para ver los "¿…?" por los que pasa
local function watchLabels()
	local seen = {}
	local conn = packLabel:GetPropertyChangedSignal("Text"):Connect(function()
		if seen[#seen] ~= packLabel.Text and packLabel.Text ~= "" then
			table.insert(seen, packLabel.Text)
		end
	end)
	return seen, conn
end

local function leftovers()
	local parts = 0
	for _, d in ipairs(packVP:GetChildren()) do
		if d:IsA("BasePart") or d:IsA("Model") then
			parts += 1
		end
	end
	local front = reveal:FindFirstChild("RevealFxFront")
	local back = reveal:FindFirstChild("RevealFxBack")
	return parts, front and #front:GetChildren() or -1, back and #back:GetChildren() or -1
end

step("Muestras de los 14 sobres", function()
	for r = 1, #Config.RARITIES do
		assert(RS.PackTemplates:FindFirstChild("R" .. r), "falta R" .. r)
	end
end)

step("Sin subir: ¿COMÚN? y luego ¡COMÚN! (con tilde)", function()
	local seen, conn = watchLabels()
	local t0 = os.clock()
	local has3D = RevealFx.run(1, 1)
	conn:Disconnect()
	assert(has3D, "sin sobre 3D")
	assert(seen[1] == "¿" .. upper(1) .. "?" and seen[1]:find("COMÚN", 1, true), "primer cartel: " .. tostring(seen[1]))
	assert(packLabel.Text == "¡" .. upper(1) .. "!", "cartel final: " .. packLabel.Text)
	assert(#RevealFx.lastOrder == 0, "hubo transiciones sin subir")
	add(string.format("   duración %.1f s · carteles: %s", os.clock() - t0, table.concat(seen, " → ")))
	RevealFx.finale(Config.RARITIES[1].color)
	task.wait(1.5)
	local parts, front = leftovers()
	assert(parts == 0 and front == 0, string.format("quedan %d piezas 3D y %d efectos", parts, front))
end)

step("Común → Legendaria: 4 saltos, cada uno con una animación distinta", function()
	table.clear(RevealFx.errors)
	local seen, conn = watchLabels()
	local t0 = os.clock()
	RevealFx.run(1, 5)
	conn:Disconnect()
	local dur = os.clock() - t0
	local q = {}
	for _, txt in ipairs(seen) do
		if txt:sub(1, 2) == "¿" then
			table.insert(q, txt)
		end
	end
	for r = 1, 5 do
		assert(table.find(q, "¿" .. upper(r) .. "?"), "no pasó por ¿" .. upper(r) .. "?")
	end
	assert(packLabel.Text == "¡" .. upper(5) .. "!", "cartel final: " .. packLabel.Text)
	assert(#RevealFx.lastOrder == 4, "transiciones: " .. #RevealFx.lastOrder)
	local used = {}
	for _, n in ipairs(RevealFx.lastOrder) do
		assert(not used[n], "repite la animación " .. n)
		used[n] = true
	end
	assert(#RevealFx.errors == 0, "errores: " .. table.concat(RevealFx.errors, " | "))
	assert(dur < 16, string.format("demasiado larga: %.1f s", dur))
	add(string.format("   duración %.1f s · animaciones: %s", dur, table.concat(RevealFx.lastOrder, ", ")))
	add("   carteles: " .. table.concat(q, " → "))
	RevealFx.finale(Config.RARITIES[5].color)
	task.wait(1.6)
	local parts, front, back = leftovers()
	assert(parts == 0 and front == 0 and back <= 1, string.format("quedan %d piezas 3D, %d efectos delante y %d detrás", parts, front, back))
end)

step("Las cinco animaciones funcionan solas (sin errores ni restos)", function()
	local times = {}
	for _, name in ipairs(RevealFx.TRANSITIONS) do
		table.clear(RevealFx.errors)
		RevealFx.forceOrder = { name }
		local t0 = os.clock()
		RevealFx.run(7, 8)
		RevealFx.forceOrder = nil
		assert(RevealFx.lastOrder[1] == name, "no usó " .. name)
		assert(#RevealFx.errors == 0, name .. ": " .. table.concat(RevealFx.errors, " | "))
		assert(packLabel.Text == "¡" .. upper(8) .. "!", name .. ": cartel final " .. packLabel.Text)
		table.insert(times, string.format("%s %.1fs", name, os.clock() - t0))
		RevealFx.finale(WHITE)
		task.wait(1.6)
		local parts, front = leftovers()
		assert(parts == 0 and front == 0, string.format("%s deja %d piezas 3D y %d efectos", name, parts, front))
	end
	add("   un salto cada una: " .. table.concat(times, " · "))
	local snd = {}
	for k, v in pairs(played) do
		table.insert(snd, k .. "×" .. v)
	end
	table.sort(snd)
	add("   sonidos: " .. table.concat(snd, " "))
end)

step("Rareza 14 (no sube): sin transiciones", function()
	RevealFx.run(14, 14)
	assert(#RevealFx.lastOrder == 0 and packLabel.Text == "¡" .. upper(14) .. "!", "rareza 14")
	RevealFx.finale(WHITE)
end)

gui:Destroy()
add(fails == 0 and "🎉 APERTURA OK" or ("⚠️ FALLOS: " .. fails))
return table.concat(out, "\n")
