-- Lucky Obby Race — panel de estadísticas abajo a la izquierda (Shadow)
-- 💰 monedas · 🍀 suerte · 🏆 victorias · ⏱ récord. Los números cuentan hacia arriba/abajo con animación
-- y la fila "salta" y brilla cuando cambia.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Locale = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Locale"))
pcall(function()
	Locale.detect(player.LocaleId)
end)
local es = Locale.lang() == "es"

local BANGERS = Font.new("rbxasset://fonts/families/Bangers.json")
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local WHITE = Color3.new(1, 1, 1)

local gui = Instance.new("ScreenGui")
gui.Name = "StatsHud"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 4
gui.Parent = player:WaitForChild("PlayerGui")
local scale = Instance.new("UIScale")
scale.Parent = gui
local function rescale()
	local v = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.clamp(math.min(v.X / 1280, v.Y / 760), 0.6, 1)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0, 1)
panel.Position = UDim2.new(0, 14, 1, -14)
panel.Size = UDim2.fromOffset(236, 196)
panel.BackgroundColor3 = Color3.fromRGB(22, 16, 38)
panel.BackgroundTransparency = 0.12
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 18)
-- en móvil/tablet abajo a la izquierda va el joystick: el panel sube arriba a la derecha (bajo el buzón)
local UIS = game:GetService("UserInputService")
local function place()
	local touch = UIS.TouchEnabled and not UIS.MouseEnabled
	if touch then
		panel.AnchorPoint = Vector2.new(1, 0)
		panel.Position = UDim2.new(1, -10, 0, 124)
	else
		panel.AnchorPoint = Vector2.new(0, 1)
		panel.Position = UDim2.new(0, 14, 1, -14)
	end
end
place()
UIS.LastInputTypeChanged:Connect(place)
local stroke = Instance.new("UIStroke")
stroke.Thickness = 3
stroke.Color = WHITE
stroke.Parent = panel
local sg = Instance.new("UIGradient")
sg.Color = ColorSequence.new({
	ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 200, 60)),
	ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 90, 160)),
	ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 170, 255)),
})
sg.Parent = stroke
local bgGrad = Instance.new("UIGradient")
bgGrad.Rotation = 90
bgGrad.Color = ColorSequence.new(Color3.fromRGB(60, 40, 100), Color3.fromRGB(20, 14, 34))
bgGrad.Parent = panel
local pad = Instance.new("UIPadding")
pad.PaddingTop, pad.PaddingBottom, pad.PaddingLeft, pad.PaddingRight = UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 10)
pad.Parent = panel
local list = Instance.new("UIListLayout")
list.Padding = UDim.new(0, 6)
list.SortOrder = Enum.SortOrder.LayoutOrder
list.Parent = panel

local rows = {}
local function makeRow(order, icon, color, title)
	local r = Instance.new("Frame")
	r.LayoutOrder = order
	r.Size = UDim2.new(1, 0, 0, 38)
	r.BackgroundColor3 = WHITE
	r.BackgroundTransparency = 0.93
	r.Parent = panel
	Instance.new("UICorner", r).CornerRadius = UDim.new(0, 12)
	local badge = Instance.new("TextLabel")
	badge.Size = UDim2.fromOffset(34, 34)
	badge.Position = UDim2.fromOffset(2, 2)
	badge.BackgroundColor3 = color
	badge.Text = icon
	badge.TextScaled = true
	badge.Font = Enum.Font.GothamBold
	badge.Parent = r
	Instance.new("UICorner", badge).CornerRadius = UDim.new(1, 0)
	local bs = Instance.new("UIStroke")
	bs.Color = WHITE
	bs.Thickness = 2
	bs.Parent = badge
	local t = Instance.new("TextLabel")
	t.BackgroundTransparency = 1
	t.Position = UDim2.fromOffset(44, 1)
	t.Size = UDim2.new(1, -48, 0, 14)
	t.FontFace = FREDOKA
	t.TextSize = 13
	t.TextXAlignment = Enum.TextXAlignment.Left
	t.TextColor3 = color:Lerp(WHITE, 0.4)
	t.Text = title
	t.Parent = r
	local v = Instance.new("TextLabel")
	v.BackgroundTransparency = 1
	v.Position = UDim2.fromOffset(44, 13)
	v.Size = UDim2.new(1, -48, 0, 24)
	v.FontFace = BANGERS
	v.TextSize = 24
	v.TextXAlignment = Enum.TextXAlignment.Left
	v.TextColor3 = WHITE
	v.TextStrokeTransparency = 0.5
	v.Text = "0"
	v.Parent = r
	local rs = Instance.new("UIScale")
	rs.Parent = r
	rows[order] = { frame = r, value = v, scale = rs, color = color, shown = nil, target = nil }
	return rows[order]
end

local coinsRow = makeRow(1, "💰", Color3.fromRGB(255, 190, 40), es and "MONEDAS" or "COINS")
local luckRow = makeRow(2, "🍀", Color3.fromRGB(80, 220, 120), es and "SUERTE" or "LUCK")
local winsRow = makeRow(3, "🏆", Color3.fromRGB(255, 120, 60), es and "VICTORIAS" or "WINS")
local bestRow = makeRow(4, "⏱", Color3.fromRGB(90, 170, 255), es and "RÉCORD" or "BEST TIME")

local function fmtTime(t)
	if not t or t <= 0 then
		return "--:--"
	end
	return string.format("%d:%05.2f", math.floor(t / 60), t % 60)
end

local function pulse(row)
	row.scale.Scale = 1.12
	TweenService:Create(row.scale, TweenInfo.new(0.4, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	row.frame.BackgroundColor3 = row.color
	row.frame.BackgroundTransparency = 0.55
	TweenService:Create(row.frame, TweenInfo.new(0.6), { BackgroundTransparency = 0.93 }):Play()
end

local function setNum(row, n, suffix)
	if row.target == n then
		return
	end
	local first = row.target == nil
	row.target = n
	if first then
		row.shown = n
		row.value.Text = tostring(n) .. (suffix or "")
		return
	end
	pulse(row)
end

local function read()
	local ls = player:FindFirstChild("leaderstats")
	local coins = ls and ls:FindFirstChild("💰")
	local wins = ls and ls:FindFirstChild("🏆")
	setNum(coinsRow, coins and coins.Value or 0)
	setNum(winsRow, wins and wins.Value or 0)
	local luck = player:GetAttribute("Luck") or player:GetAttribute("LuckLevel") or 0
	if luckRow.target ~= luck then
		local first = luckRow.target == nil
		luckRow.target = luck
		luckRow.value.Text = string.format("%s %d/10", es and "NIVEL" or "LEVEL", luck)
		if not first then
			pulse(luckRow)
		end
	end
	local best = player:GetAttribute("Best") or 0
	if bestRow.target ~= best then
		local first = bestRow.target == nil
		bestRow.target = best
		bestRow.value.Text = fmtTime(best)
		if not first then
			pulse(bestRow)
		end
	end
end

-- números que cuentan hasta el valor nuevo
RunService.RenderStepped:Connect(function(dt)
	for _, row in ipairs({ coinsRow, winsRow }) do
		if row.target and row.shown ~= row.target then
			local diff = row.target - row.shown
			local step = math.max(1, math.floor(math.abs(diff) * math.min(1, dt * 8)))
			row.shown += math.sign(diff) * math.min(step, math.abs(diff))
			row.value.Text = tostring(row.shown)
		end
	end
	sg.Rotation = (os.clock() * 40) % 360
end)

task.spawn(function()
	while true do
		pcall(read)
		task.wait(0.3)
	end
end)
