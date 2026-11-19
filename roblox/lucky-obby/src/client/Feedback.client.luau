-- Lucky Obby Race — buzón en tu pantalla (Shadow): botón 📮 para mandar ideas o fallos; el dueño ve además 📬
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local rf = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Feedback", 30)
if not rf then
	return
end
local Locale = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Locale"))
pcall(function()
	Locale.detect(player.LocaleId)
end)
local function L(es, en)
	return Locale.lang() == "es" and es or en
end

local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 215, 70)
local BANGERS = Font.new("rbxasset://fonts/families/Bangers.json")
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")

local gui = Instance.new("ScreenGui")
gui.Name = "FeedbackGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9
gui.Parent = player:WaitForChild("PlayerGui")
local scale = Instance.new("UIScale")
scale.Parent = gui
local function rescale()
	local v = workspace.CurrentCamera.ViewportSize
	scale.Scale = math.clamp(math.min(v.X / 1280, v.Y / 760), 0.55, 1)
end
rescale()
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(rescale)

local function corner(o, r)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(0, r or 12)
	c.Parent = o
end
local function stroke(o, col, th)
	local s = Instance.new("UIStroke")
	s.Color = col or WHITE
	s.Thickness = th or 2
	s.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	s.Parent = o
end
local function btn(parent, text, color, size, pos)
	local b = Instance.new("TextButton")
	b.Size = size
	b.Position = pos or UDim2.new()
	b.BackgroundColor3 = color
	b.FontFace = BANGERS
	b.TextScaled = true
	b.TextColor3 = WHITE
	b.TextStrokeTransparency = 0.4
	b.Text = text
	b.AutoButtonColor = true
	b.Parent = parent
	corner(b, 12)
	stroke(b, WHITE, 2)
	return b
end

-- botón pequeño arriba a la derecha (debajo de la barra de Roblox)
local open = btn(gui, "📮", Color3.fromRGB(90, 70, 160), UDim2.fromOffset(46, 46), UDim2.new(1, -60, 0, 66))
local inboxBtn -- solo el dueño

-- PANEL PARA ESCRIBIR ----------------------------------------------------------------
local panel = Instance.new("Frame")
panel.AnchorPoint = Vector2.new(0.5, 0.5)
panel.Position = UDim2.fromScale(0.5, 0.5)
panel.Size = UDim2.fromOffset(520, 360)
panel.BackgroundColor3 = Color3.fromRGB(36, 24, 60)
panel.Visible = false
panel.Parent = gui
corner(panel, 20)
stroke(panel, GOLD, 3)
local title = Instance.new("TextLabel")
title.BackgroundTransparency = 1
title.Size = UDim2.new(1, -70, 0, 50)
title.Position = UDim2.fromOffset(18, 8)
title.FontFace = BANGERS
title.TextScaled = true
title.TextXAlignment = Enum.TextXAlignment.Left
title.TextColor3 = GOLD
title.Text = L("📮 BUZÓN DE IDEAS Y FALLOS", "📮 IDEAS & BUG REPORTS")
title.Parent = panel
local close = btn(panel, "X", Color3.fromRGB(200, 60, 80), UDim2.fromOffset(42, 42), UDim2.new(1, -54, 0, 12))
local kind = "idea"
local ideaB = btn(panel, L("💡 IDEA", "💡 IDEA"), Color3.fromRGB(70, 170, 90), UDim2.fromOffset(150, 40), UDim2.fromOffset(18, 66))
local bugB = btn(panel, L("🐞 FALLO", "🐞 BUG"), Color3.fromRGB(80, 70, 100), UDim2.fromOffset(150, 40), UDim2.fromOffset(180, 66))
local function setKind(k)
	kind = k
	ideaB.BackgroundColor3 = k == "idea" and Color3.fromRGB(70, 170, 90) or Color3.fromRGB(80, 70, 100)
	bugB.BackgroundColor3 = k == "bug" and Color3.fromRGB(220, 90, 60) or Color3.fromRGB(80, 70, 100)
end
ideaB.Activated:Connect(function()
	setKind("idea")
end)
bugB.Activated:Connect(function()
	setKind("bug")
end)
local box = Instance.new("TextBox")
box.Size = UDim2.new(1, -36, 0, 160)
box.Position = UDim2.fromOffset(18, 116)
box.BackgroundColor3 = Color3.fromRGB(20, 14, 34)
box.TextColor3 = WHITE
box.PlaceholderColor3 = Color3.fromRGB(150, 140, 170)
box.PlaceholderText = L("Cuéntanos tu idea o qué ha fallado (dónde y qué pasó)…", "Tell us your idea or what broke (where and what happened)…")
box.FontFace = FREDOKA
box.TextSize = 20
box.TextWrapped = true
box.MultiLine = true
box.ClearTextOnFocus = false
box.TextXAlignment = Enum.TextXAlignment.Left
box.TextYAlignment = Enum.TextYAlignment.Top
box.Text = ""
box.Parent = panel
corner(box, 10)
local pad = Instance.new("UIPadding")
pad.PaddingLeft, pad.PaddingRight, pad.PaddingTop = UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 8)
pad.Parent = box
local count = Instance.new("TextLabel")
count.BackgroundTransparency = 1
count.Size = UDim2.fromOffset(100, 20)
count.Position = UDim2.new(1, -118, 0, 280)
count.FontFace = FREDOKA
count.TextSize = 16
count.TextColor3 = Color3.fromRGB(180, 170, 200)
count.TextXAlignment = Enum.TextXAlignment.Right
count.Text = "0/300"
count.Parent = panel
box:GetPropertyChangedSignal("Text"):Connect(function()
	if #box.Text > 300 then
		box.Text = box.Text:sub(1, 300)
	end
	count.Text = #box.Text .. "/300"
end)
local status = Instance.new("TextLabel")
status.BackgroundTransparency = 1
status.Size = UDim2.new(1, -220, 0, 40)
status.Position = UDim2.fromOffset(18, 306)
status.FontFace = FREDOKA
status.TextScaled = true
status.TextXAlignment = Enum.TextXAlignment.Left
status.TextColor3 = WHITE
status.Text = ""
status.Parent = panel
local sendB = btn(panel, L("ENVIAR", "SEND"), Color3.fromRGB(255, 150, 40), UDim2.fromOffset(170, 46), UDim2.new(1, -188, 0, 300))
local busy = false
sendB.Activated:Connect(function()
	if busy then
		return
	end
	busy = true
	status.Text = L("Enviando…", "Sending…")
	local ok, res, extra = pcall(function()
		return rf:InvokeServer("send", kind, box.Text)
	end)
	local good, why = ok and res, ok and extra or "?"
	local _ = why
	if ok and res == true then
		status.TextColor3 = Color3.fromRGB(130, 255, 150)
		status.Text = L("✅ ¡Gracias! Lo leeremos", "✅ Thanks! We'll read it")
		box.Text = ""
		task.delay(1.5, function()
			panel.Visible = false
		end)
	else
		status.TextColor3 = Color3.fromRGB(255, 130, 130)
		local reason = ok and extra or "?"
		local secs = nil
		if ok then
			local r1, r2, r3 = res, extra, nil
			local _ = r1
			reason = r2
			secs = r3
		end
		if reason == "short" then
			status.Text = L("Escribe un poco más", "Write a bit more")
		elseif reason == "wait" then
			status.Text = L("Espera un poco antes de mandar otro", "Wait a bit before sending another")
		elseif reason == "filter" then
			status.Text = L("No se pudo enviar (filtro)", "Couldn't send (filter)")
		else
			status.Text = L("No se pudo enviar, prueba luego", "Couldn't send, try later")
		end
		local _ = secs
	end
	local _ = good
	busy = false
end)
open.Activated:Connect(function()
	panel.Visible = not panel.Visible
	status.Text = ""
	if panel.Visible then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	end
end)
close.Activated:Connect(function()
	panel.Visible = false
end)

-- BANDEJA DEL DUEÑO --------------------------------------------------------------------
local ok, owner = pcall(function()
	return rf:InvokeServer("isOwner")
end)
if not (ok and owner) then
	return
end
inboxBtn = btn(gui, "📬", Color3.fromRGB(200, 120, 40), UDim2.fromOffset(46, 46), UDim2.new(1, -112, 0, 66))
local inbox = Instance.new("Frame")
inbox.AnchorPoint = Vector2.new(0.5, 0.5)
inbox.Position = UDim2.fromScale(0.5, 0.5)
inbox.Size = UDim2.fromOffset(640, 480)
inbox.BackgroundColor3 = Color3.fromRGB(30, 22, 48)
inbox.Visible = false
inbox.Parent = gui
corner(inbox, 20)
stroke(inbox, Color3.fromRGB(255, 160, 60), 3)
local ititle = title:Clone()
ititle.Text = "📬 BUZÓN (solo tú lo ves)"
ititle.Parent = inbox
local iclose = btn(inbox, "X", Color3.fromRGB(200, 60, 80), UDim2.fromOffset(42, 42), UDim2.new(1, -54, 0, 12))
local scroll = Instance.new("ScrollingFrame")
scroll.Size = UDim2.new(1, -30, 1, -80)
scroll.Position = UDim2.fromOffset(15, 66)
scroll.BackgroundTransparency = 1
scroll.CanvasSize = UDim2.new()
scroll.AutomaticCanvasSize = Enum.AutomaticSize.Y
scroll.ScrollBarThickness = 8
scroll.Parent = inbox
local lay = Instance.new("UIListLayout")
lay.Padding = UDim.new(0, 8)
lay.Parent = scroll
local function refresh()
	for _, c in ipairs(scroll:GetChildren()) do
		if c:IsA("TextLabel") then
			c:Destroy()
		end
	end
	local okL, items = pcall(function()
		return rf:InvokeServer("list")
	end)
	if not okL or type(items) ~= "table" or #items == 0 then
		local l = Instance.new("TextLabel")
		l.Size = UDim2.new(1, -10, 0, 40)
		l.BackgroundTransparency = 1
		l.FontFace = FREDOKA
		l.TextSize = 20
		l.TextColor3 = WHITE
		l.Text = "Todavía no hay mensajes"
		l.Parent = scroll
		return
	end
	for i, e in ipairs(items) do
		local l = Instance.new("TextLabel")
		l.LayoutOrder = i
		l.Size = UDim2.new(1, -14, 0, 0)
		l.AutomaticSize = Enum.AutomaticSize.Y
		l.BackgroundColor3 = e.kind == "bug" and Color3.fromRGB(80, 40, 40) or Color3.fromRGB(40, 70, 50)
		l.FontFace = FREDOKA
		l.TextSize = 18
		l.TextWrapped = true
		l.RichText = false
		l.TextXAlignment = Enum.TextXAlignment.Left
		l.TextColor3 = WHITE
		l.Text = string.format("%s  %s · %s\n%s", e.kind == "bug" and "🐞" or "💡", os.date("%d/%m %H:%M", tonumber(e.t) or 0), tostring(e.name), tostring(e.text))
		l.Parent = scroll
		corner(l, 8)
		local p2 = Instance.new("UIPadding")
		p2.PaddingLeft, p2.PaddingRight, p2.PaddingTop, p2.PaddingBottom = UDim.new(0, 10), UDim.new(0, 10), UDim.new(0, 6), UDim.new(0, 6)
		p2.Parent = l
	end
end
inboxBtn.Activated:Connect(function()
	inbox.Visible = not inbox.Visible
	if inbox.Visible then
		UserInputService.MouseBehavior = Enum.MouseBehavior.Default
		refresh()
	end
end)
iclose.Activated:Connect(function()
	inbox.Visible = false
end)
local _ = TweenService
