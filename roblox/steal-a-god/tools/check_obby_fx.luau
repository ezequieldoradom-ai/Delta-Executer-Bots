-- Prueba en un servidor de Roblox de la parte del jugador del Ascenso al Olimpo (src/client/ObbyFx.luau)
-- con un personaje de prueba: los obstáculos se mueven, tocar algo rojo o caerse te devuelve a tu punto
-- de control, el impulsor te lanza, las baldosas se caen, la barra muestra la etapa y no salta ningún error.
local RS = game:GetService("ReplicatedStorage")
local Shared = RS:WaitForChild("Shared")
local Server = game:GetService("ServerScriptService"):WaitForChild("Server")
local CS = game:GetService("CollectionService")
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

local G = { Config = require(Shared.Config), Core = { actions = {}, sessions = {} } }
local Obby = require(Server.Obby)
-- solo construir (sin bucles del servidor)
local okInit = pcall(function()
	G.Quests = nil
	Obby.init(G)
end)
local C = G.Config
local O = C.OBBY
local Locale = require(Shared.Locale)
Locale.setSpanish(true)

-- personaje de prueba
local char = Instance.new("Model")
char.Name = "TestChar"
local hrp = Instance.new("Part")
hrp.Name = "HumanoidRootPart"
hrp.Size = Vector3.new(2, 2, 1)
hrp.Anchored = true
hrp.CanCollide = false
hrp.Parent = char
char.PrimaryPart = hrp
char.Parent = workspace

local state = { obby = { on = true, stage = 5, wins = 0, best = 0 } }
local played, floats, banners = {}, {}, {}
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
local gui = new("ScreenGui", { Name = "ObbyTest", Parent = game:GetService("StarterGui") })
local function label(props)
	return new("TextLabel", { Text = props.Text or "", Size = props.Size, Position = props.Position, Parent = props.Parent })
end
local sent = {}
local ctx = {
	player = { Character = char, UserId = 1 },
	Config = C, Locale = Locale, Format = require(Shared.Format), t = Locale.t, gui = gui,
	getState = function()
		return state
	end,
	send = function(name)
		table.insert(sent, name)
	end,
	play = function(n)
		played[n] = (played[n] or 0) + 1
	end,
	isBusy = function()
		return false
	end,
	ui = {
		new = new,
		corner = function(r)
			return new("UICorner", { CornerRadius = UDim.new(0, r or 8) })
		end,
		stroke = function(c, th)
			return new("UIStroke", { Color = c, Thickness = th or 2 })
		end,
		gradient = function(a, b, r)
			return new("UIGradient", { Color = ColorSequence.new(a, b), Rotation = r or 90 })
		end,
		label = label,
		heavy = label,
		button = function(props)
			return new("TextButton", { Text = props.Text, Size = props.Size, Position = props.Position, Parent = props.Parent })
		end,
		floatText = function(text)
			table.insert(floats, text)
		end,
		showBanner = function(text)
			table.insert(banners, text)
		end,
		fonts = { BTN = Enum.Font.FredokaOne },
		colors = { GOLD = Color3.fromRGB(255, 210, 63) },
	},
}

local function padTop(i)
	local pad = workspace.Obby.Pads["CP" .. i]
	return (pad.CFrame * CFrame.new(0, pad.Size.Y / 2 + 3, 0)).Position, pad
end

local client = game:GetService("StarterPlayer").StarterPlayerScripts:FindFirstChild("Client")
local ObbyFx = require(client.ObbyFx)

step("Construir el obby y arrancar el módulo del jugador", function()
	assert(okInit, "no se construyó el obby")
	ObbyFx.start(ctx)
	hrp.CFrame = CFrame.new((padTop(5)))
	task.wait(1)
	local bar = gui:FindFirstChild("ObbyBar")
	assert(bar and bar.Visible, "sin barra de etapa")
	local txt = {}
	for _, d in ipairs(bar:GetDescendants()) do
		if d:IsA("TextLabel") then
			table.insert(txt, d.Text)
		end
	end
	add("   barra: " .. table.concat(txt, " | "))
	assert(table.concat(txt, " "):find("5/100", 1, true), "la barra no dice la etapa")
	assert(#banners > 0, "sin cartel de bienvenida")
end)

step("Barras que giran, plataformas y martillos se mueven cerca de ti", function()
	local moved = { spin = false, move = false, swing = false }
	-- ponerse junto a una etapa de cada tipo y ver que se mueve
	for _, info in ipairs({ { "ObbySpin", "spin" }, { "ObbyMove", "move" } }) do
		local p = CS:GetTagged(info[1])[1]
		hrp.CFrame = p.CFrame + Vector3.new(0, 30, 0)
		local before = p.CFrame
		task.wait(0.4)
		moved[info[2]] = (p.CFrame.Position - before.Position).Magnitude > 0.01 or p.CFrame.LookVector:Dot(before.LookVector) < 0.9999
	end
	local m = CS:GetTagged("ObbySwing")[1]
	local head = m:FindFirstChild("Hammer")
	hrp.CFrame = head.CFrame + Vector3.new(0, 30, 0)
	local hb = head.Position
	task.wait(0.4)
	moved.swing = (head.Position - hb).Magnitude > 0.01
	assert(moved.spin and moved.move and moved.swing, string.format("giran %s · van y vienen %s · martillos %s", tostring(moved.spin), tostring(moved.move), tostring(moved.swing)))
end)

step("Tocar algo rojo o caerse te devuelve a tu punto de control", function()
	local p0 = padTop(5)
	local kill = CS:GetTagged("ObbyKill")[1]
	hrp.CFrame = kill.CFrame
	task.wait(0.4)
	assert((hrp.Position - p0).Magnitude < 4, "tocar lava no te devuelve")
	task.wait(0.6)
	hrp.CFrame = CFrame.new(p0 - Vector3.new(0, 60, 0))
	task.wait(0.4)
	assert((hrp.Position - p0).Magnitude < 4, "caerte no te devuelve")
end)

step("El impulsor te lanza hacia arriba", function()
	local pad = CS:GetTagged("ObbyPad")[1]
	hrp.Anchored = false
	hrp.CFrame = pad.CFrame * CFrame.new(0, 3.2, 0)
	hrp.AssemblyLinearVelocity = Vector3.zero
	local best = 0
	for _ = 1, 12 do
		task.wait(0.05)
		best = math.max(best, hrp.AssemblyLinearVelocity.Y)
		if best > 40 then
			break
		end
	end
	hrp.Anchored = true
	assert(best > 40, "no lanza: " .. best)
end)

step("Las baldosas se caen al pisarlas y vuelven", function()
	local tile = CS:GetTagged("ObbyVanish")[1]
	hrp.CFrame = tile.CFrame * CFrame.new(0, 3.1, 0)
	task.wait((tile:GetAttribute("Delay") or 0.5) + 0.35)
	assert(tile.CanCollide == false, "la baldosa no se cae")
	hrp.CFrame = CFrame.new((padTop(5)))
	task.wait(2.8)
	assert(tile.CanCollide == true, "la baldosa no vuelve")
end)

step("Nueva etapa y nuevo tramo: aviso y aros dorados", function()
	state.obby.stage = 10
	task.wait(0.3)
	state.obby.stage = 11
	task.wait(0.3)
	assert(table.find(floats, Locale.t("obbyCheckpoint", 11)), "sin aviso de etapa")
	assert(workspace.Obby.Pads.CPRing10.Color == Color3.fromRGB(255, 205, 80), "aro superado sin dorar")
	assert(#banners >= 2, "sin cartel de tramo nuevo")
	-- salir
	state.obby.on = false
	task.wait(0.2)
	assert(not gui.ObbyBar.Visible, "la barra sigue al salir")
end)

ObbyFx.stop()
gui:Destroy()
char:Destroy()
local snd = {}
for k, v in pairs(played) do
	table.insert(snd, k .. "×" .. v)
end
table.sort(snd)
add("   sonidos: " .. table.concat(snd, " "))
add(fails == 0 and "🎉 OBBY OK" or ("⚠️ FALLOS: " .. fails))
return table.concat(out, "\n")
