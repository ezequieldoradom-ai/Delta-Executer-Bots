-- Lucky Obby Race — obbys normales en tu pantalla (Shadow)
--   · Lava / trampas y caídas → vuelves a tu último punto de control
--   · Impulsores (JumpPad)
--   · Panel: dificultad, tramo, tiempo y botón SALIR (cruceta abajo con mando)
--   · Celebración al llegar a la meta
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local Net = Remotes:WaitForChild("Obby")
local Locale = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Locale"))
local es = Locale.code(player.LocaleId) == "es"
local function L(a, b)
	return es and a or b
end

local DEFS = {
	easy = { icon = "🟢", es = "FÁCIL", en = "EASY", segments = 30, color = Color3.fromRGB(90, 230, 120) },
	medium = { icon = "🟠", es = "MEDIO", en = "MEDIUM", segments = 45, color = Color3.fromRGB(255, 140, 40) },
	hard = { icon = "🔴", es = "DIFÍCIL", en = "HARD", segments = 60, color = Color3.fromRGB(255, 80, 90) },
}
local function title(def)
	return es and (def.icon .. " OBBY " .. def.es) or (def.icon .. " " .. def.en .. " OBBY")
end

local function snd(id, vol, speed)
	local s = Instance.new("Sound")
	s.SoundId = id
	s.Volume = vol
	s.PlaybackSpeed = speed or 1
	s.Parent = SoundService
	return s
end
local S = {
	back = snd("rbxasset://sounds/swordslash.wav", 0.5, 0.7),
	pad = snd("rbxasset://sounds/action_jump.mp3", 0.5, 0.8),
	fanfare = snd("rbxasset://sounds/victory.wav", 0.8, 1),
}

-- PANEL ----------------------------------------------------------------------------------
local BANGERS = Font.new("rbxasset://fonts/families/Bangers.json")
local FREDOKA = Font.new("rbxasset://fonts/families/FredokaOne.json")
local gui = Instance.new("ScreenGui")
gui.Name = "ObbyGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 6
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
panel.Position = UDim2.fromOffset(14, 120)
panel.Size = UDim2.fromOffset(250, 92)
panel.BackgroundColor3 = Color3.fromRGB(22, 16, 38)
panel.BackgroundTransparency = 0.12
panel.Visible = false
panel.Parent = gui
Instance.new("UICorner", panel).CornerRadius = UDim.new(0, 14)
-- en táctil el botón 🎵 está arriba a la izquierda (12,56): el panel va justo debajo
local function place()
	local touch = UserInputService.TouchEnabled and not UserInputService.MouseEnabled
	panel.Position = UDim2.fromOffset(14, touch and 104 / scale.Scale or 120)
end
place()
UserInputService.LastInputTypeChanged:Connect(place)
workspace.CurrentCamera:GetPropertyChangedSignal("ViewportSize"):Connect(place)
local pst = Instance.new("UIStroke")
pst.Thickness = 3
pst.Parent = panel
local function lab(props)
	local l = Instance.new(props.Button and "TextButton" or "TextLabel")
	l.BackgroundTransparency = props.Button and 0 or 1
	l.BackgroundColor3 = props.Color or Color3.fromRGB(200, 60, 80)
	l.Position = props.Position
	l.Size = props.Size
	l.FontFace = props.Font or FREDOKA
	l.TextScaled = true
	l.TextColor3 = props.TextColor or Color3.new(1, 1, 1)
	l.TextXAlignment = props.Align or Enum.TextXAlignment.Center
	l.Text = props.Text or ""
	l.Parent = panel
	if props.Button then
		Instance.new("UICorner", l).CornerRadius = UDim.new(0, 10)
	end
	return l
end
local titleL = lab({ Position = UDim2.fromOffset(12, 6), Size = UDim2.new(1, -100, 0, 30), Font = BANGERS, Align = Enum.TextXAlignment.Left })
local stageL = lab({ Position = UDim2.fromOffset(12, 40), Size = UDim2.new(1, -24, 0, 22), Align = Enum.TextXAlignment.Left })
local timeL = lab({ Position = UDim2.fromOffset(12, 64), Size = UDim2.new(1, -24, 0, 20), Align = Enum.TextXAlignment.Left, TextColor = Color3.fromRGB(200, 200, 230) })
local leave = lab({ Button = true, Position = UDim2.new(1, -84, 0, 8), Size = UDim2.fromOffset(74, 30), Font = BANGERS, Text = L("SALIR", "LEAVE") })
local leaveAsk = 0
local function leavePress()
	if os.clock() - leaveAsk < 2.5 then
		Net:FireServer("leave")
		leave.Text = L("SALIR", "LEAVE")
	else
		leaveAsk = os.clock()
		leave.Text = L("¿SEGURO?", "SURE?")
		task.delay(2.5, function()
			leave.Text = L("SALIR", "LEAVE") .. (UserInputService.GamepadEnabled and " ⬇" or "")
		end)
	end
end
leave.Activated:Connect(leavePress)
ContextActionService:BindActionAtPriority("ObbyLeavePad", function(_, st)
	if st ~= Enum.UserInputState.Begin or not panel.Visible then
		return Enum.ContextActionResult.Pass
	end
	leavePress()
	return Enum.ContextActionResult.Sink
end, false, 2000, Enum.KeyCode.DPadDown)

local t0 = 0
local current = nil
local function fmt(s)
	return string.format("%d:%02d", math.floor(s / 60), math.floor(s % 60))
end
local function refresh()
	local id = player:GetAttribute("Obby")
	local def = id and DEFS[id]
	if def ~= current then
		current = def
		if def then
			t0 = os.clock()
			titleL.Text = title(def)
			titleL.TextColor3 = def.color
			pst.Color = def.color
			leave.Text = L("SALIR", "LEAVE") .. (UserInputService.GamepadEnabled and " ⬇" or "")
		end
	end
	panel.Visible = def ~= nil
	if def then
		local st = player:GetAttribute("ObbyStage") or 0
		stageL.Text = string.format(L("🧱 Tramo %d / %d", "🧱 Stage %d / %d"), st, def.segments)
	end
end
player:GetAttributeChangedSignal("Obby"):Connect(refresh)
player:GetAttributeChangedSignal("ObbyStage"):Connect(refresh)
refresh()

-- TRAMPAS: lava, impulsores y caídas (solo dentro de un obby) --------------------------
local killSet, padSet = {}, {}
local function track(tag, set)
	local function add(p)
		local root = workspace:FindFirstChild("Obbies")
		if root and p:IsA("BasePart") and p:IsDescendantOf(root) then
			set[p] = true
		end
	end
	for _, p in ipairs(CollectionService:GetTagged(tag)) do
		add(p)
	end
	CollectionService:GetInstanceAddedSignal(tag):Connect(add)
	CollectionService:GetInstanceRemovedSignal(tag):Connect(function(p)
		set[p] = nil
	end)
end
track("Kill", killSet)
track("JumpPad", padSet)
local killParams = OverlapParams.new()
killParams.FilterType = Enum.RaycastFilterType.Include
local padParams = OverlapParams.new()
padParams.FilterType = Enum.RaycastFilterType.Include
local listsAt = 0
local lastBack, lastPad = 0, 0
local function back()
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local cp = player:GetAttribute("ObbyCP")
	if not hrp or typeof(cp) ~= "Vector3" or os.clock() - lastBack < 0.6 then
		return
	end
	lastBack = os.clock()
	hrp.AssemblyLinearVelocity = Vector3.zero
	char:PivotTo(CFrame.lookAt(cp, cp + Vector3.new(0, 0, 1)))
	S.back:Play()
end
RunService.Heartbeat:Connect(function()
	if not current then
		return
	end
	timeL.Text = "⏱ " .. fmt(os.clock() - t0)
	if os.clock() - listsAt > 1 then
		listsAt = os.clock()
		local k, pd = {}, {}
		for p in pairs(killSet) do
			if p.Parent then
				table.insert(k, p)
			end
		end
		for p in pairs(padSet) do
			if p.Parent then
				table.insert(pd, p)
			end
		end
		killParams.FilterDescendantsInstances = k
		padParams.FilterDescendantsInstances = pd
	end
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if not hrp then
		return
	end
	local cp = player:GetAttribute("ObbyCP")
	if typeof(cp) == "Vector3" and hrp.Position.Y < cp.Y - 30 then
		back()
		return
	end
	if #workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, -0.9, 0), Vector3.new(2.2, 6.2, 1.6), killParams) > 0 then
		back()
		return
	end
	if os.clock() - lastPad > 0.45 then
		for _, p in ipairs(workspace:GetPartBoundsInBox(hrp.CFrame * CFrame.new(0, -3.1, 0), Vector3.new(2.6, 1.6, 2.6), padParams)) do
			lastPad = os.clock()
			local v = hrp.AssemblyLinearVelocity
			hrp.AssemblyLinearVelocity = Vector3.new(v.X, p:GetAttribute("Power") or 80, v.Z)
			S.pad:Play()
			break
		end
	end
end)

-- META: celebración -------------------------------------------------------------------
local big = Instance.new("TextLabel")
big.AnchorPoint = Vector2.new(0.5, 0.5)
big.Position = UDim2.fromScale(0.5, 0.3)
big.Size = UDim2.fromOffset(700, 110)
big.BackgroundTransparency = 1
big.FontFace = BANGERS
big.TextScaled = true
big.RichText = true
big.TextColor3 = Color3.fromRGB(255, 220, 80)
big.TextStrokeTransparency = 0
big.Visible = false
big.Parent = gui
local bigScale = Instance.new("UIScale")
bigScale.Parent = big
Remotes:WaitForChild("Event").OnClientEvent:Connect(function(kind, d)
	if kind ~= "obbyDone" or type(d) ~= "table" then
		return
	end
	local def = DEFS[d.id]
	if not def then
		return
	end
	S.fanfare:Play()
	big.Text = string.format(L('🏆 ¡%s COMPLETADO!\n<font size="34" color="#FFFFFF">+%d 💰 · ⏱ %s</font>', '🏆 %s COMPLETE!\n<font size="34" color="#FFFFFF">+%d 💰 · ⏱ %s</font>'), title(def), d.coins or 0, fmt(d.time or 0))
	big.Visible = true
	bigScale.Scale = 0.3
	TweenService:Create(bigScale, TweenInfo.new(0.5, Enum.EasingStyle.Back), { Scale = 1 }):Play()
	-- confeti
	local char = player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	if hrp then
		for i = 0, 3 do
			task.delay(i * 0.3, function()
				local p = Instance.new("Part")
				p.Anchored, p.CanCollide, p.CanQuery, p.CanTouch, p.Transparency = true, false, false, false, 1
				p.Size = Vector3.one
				p.CFrame = CFrame.new(hrp.Position + Vector3.new(math.random(-5, 5), 5, math.random(-5, 5)))
				p.Parent = workspace.CurrentCamera
				local e = Instance.new("ParticleEmitter")
				e.Texture = "rbxasset://textures/particles/sparkles_main.dds"
				e.Color = ColorSequence.new({ ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 80, 120)), ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 220, 70)), ColorSequenceKeypoint.new(1, Color3.fromRGB(90, 220, 255)) })
				e.Size = NumberSequence.new({ NumberSequenceKeypoint.new(0, 0.7), NumberSequenceKeypoint.new(1, 0) })
				e.Speed = NumberRange.new(18, 36)
				e.SpreadAngle = Vector2.new(180, 180)
				e.Lifetime = NumberRange.new(0.8, 1.4)
				e.Acceleration = Vector3.new(0, -25, 0)
				e.Rate = 0
				e.LightEmission = 0.6
				e.Parent = p
				e:Emit(70)
				task.delay(1.8, function()
					p:Destroy()
				end)
			end)
		end
	end
	task.delay(4, function()
		big.Visible = false
	end)
end)
