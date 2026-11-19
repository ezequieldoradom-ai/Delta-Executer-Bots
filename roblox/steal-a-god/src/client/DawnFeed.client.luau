-- Avisos de sobres en pantalla al amanecer (petición del dueño): además del chat, cada sobre raro sale ARRIBA,
-- SOLO LETRAS (sin bloque), en fila uno debajo de otro, entrando uno a uno y desvaneciéndose después.
-- Cada rareza tiene su letra, sus colores animados (fuego, luz, galaxia, arcoíris, oscuridad) y su sonido.
-- Escucha el remote "Announce" (packSpawned / packSpawnedBig). Sonidos: Config.SOUNDS.feed (5 huecos de 3 s).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Locale = require(Shared:WaitForChild("Locale"))
local Announce = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Announce")
local WHITE = Color3.new(1, 1, 1)
local rgb = Color3.fromRGB

local function seq(cols)
	local kp = {}
	for i, c in ipairs(cols) do
		kp[i] = ColorSequenceKeypoint.new((i - 1) / (#cols - 1), c)
	end
	return ColorSequence.new(kp)
end
local THEMES = {
	fire = { font = Enum.Font.LuckiestGuy, slot = 1, colors = seq({ rgb(255, 240, 120), rgb(255, 120, 30), rgb(255, 40, 20), rgb(255, 200, 60), rgb(255, 240, 120) }), stroke = rgb(90, 10, 0), glow = rgb(255, 120, 30) },
	holy = { font = Enum.Font.Fondamento, slot = 2, colors = seq({ WHITE, rgb(255, 235, 160), rgb(255, 255, 230), rgb(255, 210, 110), WHITE }), stroke = rgb(110, 70, 0), glow = rgb(255, 230, 140) },
	galaxy = { font = Enum.Font.Michroma, slot = 3, colors = seq({ rgb(120, 220, 255), rgb(170, 90, 255), rgb(255, 120, 230), rgb(90, 140, 255), rgb(120, 220, 255) }), stroke = rgb(10, 0, 50), glow = rgb(120, 200, 255) },
	prism = { font = Enum.Font.Bangers, slot = 4, colors = seq({ rgb(255, 70, 90), rgb(255, 200, 60), rgb(80, 235, 110), rgb(60, 210, 255), rgb(190, 100, 255), rgb(255, 70, 90) }), stroke = rgb(20, 0, 40), glow = WHITE },
	shadow = { font = Enum.Font.Creepster, slot = 5, colors = seq({ rgb(255, 40, 60), rgb(60, 0, 20), rgb(255, 80, 100), rgb(40, 0, 10), rgb(255, 40, 60) }), stroke = rgb(0, 0, 0), glow = rgb(255, 40, 60), glitch = true },
	god = { font = Enum.Font.Bangers, slot = 4, colors = seq({ rgb(255, 230, 90), rgb(255, 90, 30), rgb(190, 90, 255), rgb(70, 210, 255), rgb(255, 120, 220), rgb(255, 230, 90) }), stroke = rgb(30, 0, 40), glow = rgb(255, 220, 120), flash = true },
}
local function themeFor(r)
	if r <= 6 then
		return THEMES.fire
	elseif r == 7 then
		return THEMES.holy
	elseif r == 8 then
		return THEMES.galaxy
	elseif r == 9 then
		return THEMES.prism
	elseif r == 10 then
		return THEMES.shadow
	end
	return THEMES.god
end

local function new(class, props)
	local o = Instance.new(class)
	for k, v in pairs(props) do
		if k ~= "Parent" then
			o[k] = v
		end
	end
	o.Parent = props.Parent
	return o
end

local gui = new("ScreenGui", { Name = "DawnFeed", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
local sound = new("Sound", { SoundId = Config.SOUNDS.feed or "", Volume = 0.7, Parent = gui })
local flash = new("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = gui })
-- columna arriba en el centro, justo debajo de la barra de Roblox
local column = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(0.62, 0, 0.5, 0), AnchorPoint = Vector2.new(0.5, 0), Parent = gui })
new("UIListLayout", { Padding = UDim.new(0, 2), HorizontalAlignment = Enum.HorizontalAlignment.Center, SortOrder = Enum.SortOrder.LayoutOrder, Parent = column })
local function place()
	local inset = GuiService.TopbarInset
	column.Position = UDim2.new(0.5, 0, 0, inset.Max.Y + 4)
end
place()
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(place)

local queue = {}
local busy = false
local order = 0
local live = {} -- líneas en pantalla (para animarlas)

local function playSlot(slot)
	if sound.SoundId == "" then
		return
	end
	sound.TimePosition = (slot - 1) * 3
	sound:Play()
	local my = os.clock()
	sound:SetAttribute("At", my)
	task.delay(2.9, function()
		if sound:GetAttribute("At") == my then
			sound:Stop()
		end
	end)
end

-- añade una línea de texto a la fila; vive unos segundos y se desvanece
local function addLine(data)
	local r = data.rarity
	local th = themeFor(r)
	local cam = workspace.CurrentCamera
	local h = math.clamp((cam and cam.ViewportSize.Y or 720) * 0.042, 20, 36)
	order += 1
	local zone = Config.ZONES[data.zone]
	local text = string.format("%s %s · %s", r >= 10 and "⚡" or "✨", Locale.upper(Locale.name(Config.RARITIES[r])), zone and Locale.name(zone) or "")
	-- (cada línea va dentro de un marco: el UIListLayout fija la posición del marco y la letra puede temblar dentro)
	local holder = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, 0, 0, h), LayoutOrder = order, Parent = column })
	local line = new("TextLabel", { BackgroundTransparency = 1, Text = text, Font = th.font, TextScaled = true, TextColor3 = WHITE, TextTransparency = 1, Size = UDim2.fromScale(1, 1), Parent = holder })
	local stroke = new("UIStroke", { Thickness = 3, Color = th.stroke, Transparency = 1, Parent = line })
	local grad = new("UIGradient", { Color = th.colors, Parent = line })
	local scale = new("UIScale", { Scale = 1.6, Parent = line })
	-- entrada: aparece grande y se asienta
	TweenService:Create(line, TweenInfo.new(0.35), { TextTransparency = 0 }):Play()
	TweenService:Create(stroke, TweenInfo.new(0.35), { Transparency = 0 }):Play()
	TweenService:Create(scale, TweenInfo.new(0.45, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = 1 }):Play()
	playSlot(th.slot)
	if th.flash then
		flash.BackgroundTransparency = 0.35
		TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	end
	local rec = { line = line, stroke = stroke, grad = grad, th = th, t0 = os.clock() }
	live[line] = rec
	-- se queda un rato (más cuanto más rara) y se desvanece
	task.delay(4 + math.min(r - 6, 4) * 0.6, function()
		local fade = TweenInfo.new(1.2)
		TweenService:Create(line, fade, { TextTransparency = 1 }):Play()
		TweenService:Create(stroke, fade, { Transparency = 1 }):Play()
		task.wait(1.25)
		live[line] = nil
		holder:Destroy()
	end)
end

RunService.RenderStepped:Connect(function()
	local now = os.clock()
	for _, rec in pairs(live) do
		local t = now - rec.t0
		-- los colores recorren las letras (fuego que sube, galaxia que gira, arcoíris…)
		rec.grad.Offset = Vector2.new(math.sin(t * 1.3) * 0.5, 0)
		rec.grad.Rotation = rec.th == THEMES.fire and 90 or (t * 40) % 360
		if rec.th.glitch then
			local on = math.random() < 0.12
			rec.line.Position = UDim2.fromOffset(on and math.random(-6, 6) or 0, 0)
			rec.stroke.Color = on and rgb(255, 40, 60) or rec.th.stroke
		end
	end
end)

local function pump()
	if busy then
		return
	end
	busy = true
	while #queue > 0 do
		local ok, err = pcall(addLine, table.remove(queue, 1))
		if not ok then
			warn("[SAG] DawnFeed: " .. tostring(err))
		end
		task.wait(0.7) -- uno a uno
		-- como mucho 5 líneas a la vez en pantalla (si no, la fila llegaba al centro)
		while (function()
			local n = 0
			for _ in pairs(live) do
				n += 1
			end
			return n >= 5
		end)() do
			task.wait(0.25)
		end
	end
	busy = false
end

Announce.OnClientEvent:Connect(function(payload)
	if type(payload) ~= "table" then
		return
	end
	if payload.key == "packSpawned" or payload.key == "packSpawnedBig" then
		local a = payload.args or {}
		local r = type(a[1]) == "table" and a[1].rarity
		if r and Config.RARITIES[r] then
			table.insert(queue, { rarity = r, zone = tonumber(a[3]) or (type(a[2]) == "table" and a[2].zone) or 0 })
			task.spawn(pump)
		end
	end
end)
