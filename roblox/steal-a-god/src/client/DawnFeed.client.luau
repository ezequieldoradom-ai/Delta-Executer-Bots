-- Avisos de sobres en pantalla (petición del dueño): cuando amanece y aparecen sobres raros, además del chat
-- sale una tarjeta en pantalla, UNA A UNA, con sonido, letra y efectos según la rareza:
--   Mítica → fuego · Divina → luz sagrada · Celestial → galaxia · Primordial → galaxia arcoíris
--   Secreta → oscuridad que parpadea · Godlike/Omnipotente/Infinita → galaxia + fuego + arcoíris y destello
-- Escucha el remote "Announce" (packSpawned / packSpawnedBig). Sonidos: Config.SOUNDS.feed (5 huecos de 3 s).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))
local Locale = require(Shared:WaitForChild("Locale"))
local Announce = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Announce")
local VFX = Config.VFX
local WHITE = Color3.new(1, 1, 1)
local rgb = Color3.fromRGB

local THEMES = {
	fire = { font = Enum.Font.LuckiestGuy, slot = 1, top = rgb(255, 120, 40), bottom = rgb(90, 0, 10), stroke = rgb(255, 200, 80) },
	holy = { font = Enum.Font.Fondamento, slot = 2, top = rgb(255, 250, 225), bottom = rgb(200, 150, 60), stroke = rgb(255, 230, 140), dark = true },
	galaxy = { font = Enum.Font.Michroma, slot = 3, top = rgb(60, 30, 140), bottom = rgb(5, 5, 30), stroke = rgb(90, 230, 255), galaxy = true },
	prism = { font = Enum.Font.Bangers, slot = 4, top = rgb(120, 40, 160), bottom = rgb(10, 5, 40), stroke = WHITE, galaxy = true, rainbow = true },
	shadow = { font = Enum.Font.Creepster, slot = 5, top = rgb(40, 0, 20), bottom = rgb(0, 0, 0), stroke = rgb(255, 40, 60), glitch = true },
	god = { font = Enum.Font.Bangers, slot = 4, top = rgb(255, 140, 20), bottom = rgb(20, 0, 50), stroke = WHITE, galaxy = true, fire = true, rainbow = true, flash = true },
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

local function rainbowSeq()
	local kp = {}
	local cols = { rgb(255, 70, 90), rgb(255, 200, 60), rgb(80, 235, 110), rgb(60, 210, 255), rgb(190, 100, 255), rgb(255, 70, 90) }
	for i, c in ipairs(cols) do
		kp[i] = ColorSequenceKeypoint.new((i - 1) / (#cols - 1), c)
	end
	return ColorSequence.new(kp)
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

local gui = new("ScreenGui", { Name = "DawnFeed", ResetOnSpawn = false, DisplayOrder = 6, Parent = player:WaitForChild("PlayerGui") })
local sound = new("Sound", { SoundId = Config.SOUNDS.feed or "", Volume = 0.7, Parent = gui })
local flash = new("Frame", { BackgroundColor3 = WHITE, BackgroundTransparency = 1, Size = UDim2.fromScale(1, 1), ZIndex = 0, Parent = gui })

local queue = {}
local busy = false

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

local function show(data)
	local r = data.rarity
	local rarity = Config.RARITIES[r]
	local th = themeFor(r)
	local cam = workspace.CurrentCamera
	local s = math.clamp((cam and cam.ViewportSize.Y or 720) / 720, 0.6, 1.1)

	local card = new("Frame", { BackgroundColor3 = WHITE, Size = UDim2.fromOffset(500, 104), AnchorPoint = Vector2.new(0.5, 0), Position = UDim2.new(0.5, 0, 0, -140), ClipsDescendants = true, ZIndex = 2, Parent = gui })
	new("UICorner", { CornerRadius = UDim.new(0, 20), Parent = card })
	local scale = new("UIScale", { Scale = s * 0.6, Parent = card })
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(th.top, th.bottom), Parent = card })
	local stroke = new("UIStroke", { Thickness = 4, Color = th.rainbow and WHITE or th.stroke, Parent = card })
	local spin = {}
	if th.rainbow then
		table.insert(spin, new("UIGradient", { Color = rainbowSeq(), Parent = stroke }))
	end
	-- capas de efecto (detrás del texto)
	local layers = {}
	if th.galaxy then
		local g = new("ImageLabel", { BackgroundTransparency = 1, Image = VFX.galaxy, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(180, 180), Size = UDim2.new(2, 0, 2, 0), Position = UDim2.fromScale(-0.5, -0.5), ImageTransparency = 0.15, ZIndex = 2, Parent = card })
		table.insert(layers, { gui = g, kind = "scroll" })
		local st = new("ImageLabel", { BackgroundTransparency = 1, Image = VFX.stars, ScaleType = Enum.ScaleType.Tile, TileSize = UDim2.fromOffset(110, 110), Size = UDim2.new(2, 0, 2, 0), Position = UDim2.fromScale(-0.5, -0.5), ZIndex = 2, Parent = card })
		table.insert(layers, { gui = st, kind = "scroll", speed = -1.7 })
	end
	if r <= 6 or th.fire then
		for k = 1, 9 do
			local f = new("ImageLabel", { BackgroundTransparency = 1, Image = VFX.flame, ImageColor3 = k % 2 == 0 and rgb(255, 200, 60) or rgb(255, 80, 20), Size = UDim2.fromOffset(70, 90), AnchorPoint = Vector2.new(0.5, 1), Position = UDim2.new((k - 0.5) / 9, 0, 1, 20), ZIndex = 3, Parent = card })
			table.insert(layers, { gui = f, kind = "flame", phase = k })
		end
	end
	if r == 7 or th.flash then
		local rays = new("ImageLabel", { BackgroundTransparency = 1, Image = VFX.rays, ImageColor3 = th.dark and rgb(255, 230, 150) or WHITE, ImageTransparency = 0.35, Size = UDim2.fromOffset(520, 520), AnchorPoint = Vector2.new(0.5, 0.5), Position = UDim2.fromScale(0.5, 0.5), ZIndex = 2, Parent = card })
		table.insert(layers, { gui = rays, kind = "spin" })
	end
	for k = 1, 8 do
		local sp = new("ImageLabel", { BackgroundTransparency = 1, Image = VFX.sparkle, ImageColor3 = th.stroke, Size = UDim2.fromOffset(22, 22), AnchorPoint = Vector2.new(0.5, 0.5), ZIndex = 4, Parent = card })
		table.insert(layers, { gui = sp, kind = "spark", phase = k / 8 })
	end
	-- textos
	local title = new("TextLabel", { BackgroundTransparency = 1, Text = Locale.upper(Locale.name(rarity)), Font = th.font, TextScaled = true, TextColor3 = WHITE, Size = UDim2.new(1, -30, 0, 58), Position = UDim2.fromOffset(15, 8), ZIndex = 5, Parent = card })
	new("UIStroke", { Thickness = 3, Color = th.dark and rgb(90, 50, 0) or rgb(0, 0, 0), Parent = title })
	local tg = new("UIGradient", { Rotation = 90, Color = th.rainbow and rainbowSeq() or ColorSequence.new(WHITE, th.stroke), Parent = title })
	if th.rainbow then
		table.insert(spin, tg)
	end
	local zone = Config.ZONES[data.zone]
	local sub = new("TextLabel", { BackgroundTransparency = 1, Text = string.format("🎁 %s · %s %d", zone and Locale.name(zone) or "", Locale.lang() == "es" and "Zona" or "Zone", data.zone or 0), Font = Enum.Font.GothamBlack, TextScaled = true, TextColor3 = th.dark and rgb(60, 30, 0) or rgb(240, 230, 255), Size = UDim2.new(1, -30, 0, 26), Position = UDim2.fromOffset(15, 66), ZIndex = 5, Parent = card })
	new("UIStroke", { Thickness = 1.5, Color = th.dark and rgb(255, 250, 220) or rgb(0, 0, 0), Parent = sub })

	-- sonido, destello y entrada
	playSlot(th.slot)
	if th.flash then
		flash.BackgroundTransparency = 0.25
		TweenService:Create(flash, TweenInfo.new(0.8), { BackgroundTransparency = 1 }):Play()
	end
	TweenService:Create(card, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Position = UDim2.new(0.5, 0, 0, 96) }):Play()
	TweenService:Create(scale, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), { Scale = s }):Play()

	local t0 = os.clock()
	local conn = RunService.RenderStepped:Connect(function()
		local t = os.clock() - t0
		for _, g in ipairs(spin) do
			g.Rotation = (t * 160) % 360
		end
		for _, L in ipairs(layers) do
			if L.kind == "scroll" then
				local v = (L.speed or 1) * 30
				L.gui.Position = UDim2.new(-0.5, (t * v) % 180 - 90, -0.5, (t * v * 0.4) % 180 - 90)
			elseif L.kind == "flame" then
				local k = math.sin(t * 9 + L.phase * 1.7)
				L.gui.Size = UDim2.fromOffset(60 + 14 * k, 80 + 26 * k)
				L.gui.ImageTransparency = 0.15 + 0.2 * (1 - k) / 2
			elseif L.kind == "spin" then
				L.gui.Rotation = t * 40
			elseif L.kind == "spark" then
				local p = (t * 0.6 + L.phase) % 1
				L.gui.Position = UDim2.fromScale((L.phase * 7.3) % 1, 1 - p)
				L.gui.ImageTransparency = 1 - math.sin(p * math.pi)
				L.gui.Rotation = t * 200
			end
		end
		if th.glitch then
			local on = math.random() < 0.12
			card.Position = UDim2.new(0.5, on and math.random(-8, 8) or 0, 0, 96 + (on and math.random(-4, 4) or 0))
			title.TextTransparency = on and 0.6 or 0
		end
	end)
	-- más tiempo en pantalla cuanto más rara
	task.wait(2.2 + math.min(r - 6, 4) * 0.35)
	TweenService:Create(card, TweenInfo.new(0.35, Enum.EasingStyle.Quad, Enum.EasingDirection.In), { Position = UDim2.new(0.5, 0, 0, -150) }):Play()
	task.wait(0.4)
	conn:Disconnect()
	card:Destroy()
end

local function pump()
	if busy then
		return
	end
	busy = true
	while #queue > 0 do
		local item = table.remove(queue, 1)
		local ok, err = pcall(show, item)
		if not ok then
			warn("[SAG] DawnFeed: " .. tostring(err))
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

-- Solo en Studio: _G.SAGFeedTest() enseña una tarjeta de cada rareza alta
if RunService:IsStudio() then
	_G.SAGFeedTest = function()
		for r = 6, 13 do
			table.insert(queue, { rarity = r, zone = math.min(6, r - 5) })
		end
		task.spawn(pump)
	end
end
