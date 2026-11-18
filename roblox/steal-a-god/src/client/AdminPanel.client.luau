-- Panel de administrador ("ADMIN ABUSE"): solo aparece si el servidor marca al jugador con SAGAdmin.
-- Corona dorada en la barra de arriba (centro) → panel con mensaje global y botones de eventos.
-- Interruptor "Todos los servidores" (por defecto activado). El servidor vuelve a validar cada orden.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local GuiService = game:GetService("GuiService")

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("Remotes"):WaitForChild("Admin", 30)
if not remote then
	return
end
-- espera a que el servidor diga si eres admin
local t0 = os.clock()
while player:GetAttribute("SAGAdmin") == nil and os.clock() - t0 < 20 do
	task.wait(0.5)
end
if player:GetAttribute("SAGAdmin") ~= true then
	return
end

local WHITE = Color3.new(1, 1, 1)
local GOLD = Color3.fromRGB(255, 214, 90)
local FONT = Enum.Font.FredokaOne

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
	o.Parent = props and props.Parent
	return o
end
local function corner(r)
	return new("UICorner", { CornerRadius = UDim.new(0, r) })
end
local function rainbow()
	local kp = {}
	local cols = { Color3.fromRGB(255, 70, 90), Color3.fromRGB(255, 200, 60), Color3.fromRGB(80, 235, 110), Color3.fromRGB(60, 210, 255), Color3.fromRGB(190, 100, 255), Color3.fromRGB(255, 70, 90) }
	for i, c in ipairs(cols) do
		kp[i] = ColorSequenceKeypoint.new((i - 1) / (#cols - 1), c)
	end
	return ColorSequence.new(kp)
end

local gui = new("ScreenGui", { Name = "AdminPanel", ResetOnSpawn = false, IgnoreGuiInset = true, DisplayOrder = 20, Parent = player:WaitForChild("PlayerGui") })
local spinners = {}

-- botón de la corona (centro de la barra de arriba)
local crown = new("TextButton", { Text = "👑", Font = FONT, TextScaled = true, AutoButtonColor = false, BackgroundColor3 = Color3.fromRGB(40, 24, 70), Size = UDim2.fromOffset(40, 40), AnchorPoint = Vector2.new(0.5, 0.5), Parent = gui }, {
	new("UICorner", { CornerRadius = UDim.new(1, 0) }),
})
local crownStroke = new("UIStroke", { Thickness = 3, Color = WHITE, Parent = crown })
table.insert(spinners, new("UIGradient", { Color = rainbow(), Parent = crownStroke }))
local function placeCrown()
	local inset = GuiService.TopbarInset
	crown.Position = UDim2.new(0.5, 0, 0, inset.Min.Y + inset.Height / 2)
end
placeCrown()
GuiService:GetPropertyChangedSignal("TopbarInset"):Connect(placeCrown)

-- panel
local panel = new("Frame", { Visible = false, BackgroundColor3 = WHITE, Size = UDim2.fromOffset(460, 420), Position = UDim2.fromScale(0.5, 0.5), AnchorPoint = Vector2.new(0.5, 0.5), Parent = gui }, {
	corner(22),
	new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(60, 24, 110), Color3.fromRGB(14, 8, 34)) }),
	new("UISizeConstraint", { MaxSize = Vector2.new(460, 420) }),
})
new("UIAspectRatioConstraint", { AspectRatio = 460 / 420, Parent = panel })
local panelScale = new("UIScale", { Parent = panel })
-- en pantallas bajas (móvil) el panel se encoge para caber entero
local function fitScale()
	local cam = workspace.CurrentCamera
	local h = cam and cam.ViewportSize.Y or 720
	return math.clamp((h - 70) / 430, 0.45, 1)
end
local stroke = new("UIStroke", { Thickness = 4, Color = WHITE, Parent = panel })
table.insert(spinners, new("UIGradient", { Color = rainbow(), Parent = stroke }))
local title = new("TextLabel", { BackgroundTransparency = 1, Text = "👑 ADMIN ABUSE", Font = FONT, TextScaled = true, TextColor3 = WHITE, Size = UDim2.new(1, -80, 0, 44), Position = UDim2.fromOffset(18, 10), TextXAlignment = Enum.TextXAlignment.Left, Parent = panel })
new("UIGradient", { Rotation = 90, Color = ColorSequence.new(Color3.fromRGB(255, 240, 160), GOLD), Parent = title })
new("UIStroke", { Thickness = 2.5, Color = Color3.fromRGB(60, 20, 0), Parent = title })
local close = new("TextButton", { Text = "✕", Font = FONT, TextScaled = true, TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(255, 70, 100), Size = UDim2.fromOffset(40, 40), Position = UDim2.new(1, -54, 0, 12), Parent = panel }, { new("UICorner", { CornerRadius = UDim.new(1, 0) }) })

-- interruptor todos los servidores / solo este
local global = true
local scope = new("TextButton", { Font = FONT, TextScaled = true, TextColor3 = WHITE, AutoButtonColor = false, Size = UDim2.new(1, -36, 0, 34), Position = UDim2.fromOffset(18, 62), Parent = panel }, { corner(12) })
local function paintScope()
	scope.Text = global and "🌍 TODOS LOS SERVIDORES" or "📍 SOLO ESTE SERVIDOR"
	scope.BackgroundColor3 = global and Color3.fromRGB(40, 170, 90) or Color3.fromRGB(90, 80, 130)
end
paintScope()
scope.Activated:Connect(function()
	global = not global
	paintScope()
end)

-- mensaje global
local box = new("TextBox", { PlaceholderText = "Mensaje para todos…", Text = "", ClearTextOnFocus = false, Font = Enum.Font.GothamBold, TextSize = 18, TextColor3 = WHITE, PlaceholderColor3 = Color3.fromRGB(190, 180, 220), BackgroundColor3 = Color3.fromRGB(30, 18, 56), Size = UDim2.new(1, -150, 0, 40), Position = UDim2.fromOffset(18, 106), TextXAlignment = Enum.TextXAlignment.Left, Parent = panel }, {
	corner(12),
	new("UIPadding", { PaddingLeft = UDim.new(0, 10) }),
	new("UIStroke", { Color = GOLD, Thickness = 1.5, Transparency = 0.3 }),
})
local send = new("TextButton", { Text = "📢 ENVIAR", Font = FONT, TextScaled = true, TextColor3 = WHITE, BackgroundColor3 = Color3.fromRGB(255, 150, 40), Size = UDim2.fromOffset(110, 40), Position = UDim2.new(1, -128, 0, 106), Parent = panel }, { corner(12) })

-- botones de eventos
local grid = new("Frame", { BackgroundTransparency = 1, Size = UDim2.new(1, -36, 1, -170), Position = UDim2.fromOffset(18, 158), Parent = panel }, {
	new("UIGridLayout", { CellSize = UDim2.new(0.5, -6, 0, 50), CellPadding = UDim2.fromOffset(12, 10), SortOrder = Enum.SortOrder.LayoutOrder }),
})
local status = new("TextLabel", { BackgroundTransparency = 1, Text = "", Font = FONT, TextScaled = true, TextColor3 = Color3.fromRGB(150, 255, 170), Size = UDim2.new(1, -36, 0, 22), Position = UDim2.new(0, 18, 1, -30), Parent = panel })

local function fire(cmd, args)
	remote:FireServer(cmd, args or {}, global)
	status.Text = "✅ Enviado " .. (global and "a todos los servidores" or "a este servidor")
	task.delay(2.5, function()
		status.Text = ""
	end)
end

local EVENTS = {
	{ "🍀 SUERTE x3 · 10 min", Color3.fromRGB(60, 200, 110), "luck", { mins = 10 } },
	{ "🌙 HACER DE NOCHE", Color3.fromRGB(110, 80, 220), "night" },
	{ "💰 LLUVIA DE DINERO", Color3.fromRGB(230, 180, 40), "money", { secs = 600 } },
	{ "⚡ VELOCIDAD · 10 min", Color3.fromRGB(50, 170, 255), "speed", { mins = 10 } },
	{ "🎁 SOBRES LEGENDARIOS", Color3.fromRGB(255, 140, 40), "packs", { rarity = 5 } },
	{ "🔮 SOBRES MÍTICOS", Color3.fromRGB(220, 60, 120), "packs", { rarity = 6 } },
	{ "✨ SOBRES DIVINOS", Color3.fromRGB(255, 215, 90), "packs", { rarity = 7 } },
	{ "🌌 SOBRES CELESTIALES", Color3.fromRGB(130, 90, 255), "packs", { rarity = 8 } },
}
for i, e in ipairs(EVENTS) do
	local b = new("TextButton", { Text = e[1], Font = FONT, TextScaled = true, TextColor3 = WHITE, AutoButtonColor = false, BackgroundColor3 = WHITE, LayoutOrder = i, Parent = grid }, {
		corner(14),
		new("UIGradient", { Rotation = 90, Color = ColorSequence.new(e[2]:Lerp(WHITE, 0.2), e[2]:Lerp(Color3.new(0, 0, 0), 0.4)) }),
		new("UIStroke", { Color = Color3.fromRGB(255, 230, 150), Thickness = 2, ApplyStrokeMode = Enum.ApplyStrokeMode.Border }),
		new("UIPadding", { PaddingLeft = UDim.new(0, 8), PaddingRight = UDim.new(0, 8), PaddingTop = UDim.new(0, 6), PaddingBottom = UDim.new(0, 6) }),
	})
	new("UIStroke", { Thickness = 1.5, Color = Color3.fromRGB(30, 10, 40), ApplyStrokeMode = Enum.ApplyStrokeMode.Contextual, Parent = b })
	local sc = new("UIScale", { Parent = b })
	b.Activated:Connect(function()
		sc.Scale = 0.88
		TweenService:Create(sc, TweenInfo.new(0.3, Enum.EasingStyle.Back), { Scale = 1 }):Play()
		fire(e[3], e[4])
	end)
end

send.Activated:Connect(function()
	local text = box.Text
	if #text > 0 then
		fire("msg", { text = text })
		box.Text = ""
	end
end)

local function toggle(on)
	if on then
		panel.Visible = true
		panelScale.Scale = fitScale() * 0.5
		TweenService:Create(panelScale, TweenInfo.new(0.35, Enum.EasingStyle.Back), { Scale = fitScale() }):Play()
	else
		panel.Visible = false
	end
end
crown.Activated:Connect(function()
	toggle(not panel.Visible)
end)
close.Activated:Connect(function()
	toggle(false)
end)

RunService.RenderStepped:Connect(function()
	local r = (os.clock() * 120) % 360
	for _, g in ipairs(spinners) do
		g.Rotation = r
	end
end)
