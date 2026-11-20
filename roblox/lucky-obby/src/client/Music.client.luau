-- Lucky Obby Race — música (Shadow). Composición propia (tools/audio/gen_music.py).
--   · Música obby alegre en el vestíbulo y la carrera.
--   · Música de TENSIÓN cuando estás en una mesa de "¿Quién ha sido?" (y sube cuando te toca pegar o te van a pegar).
--   · Botón 🎵 para silenciar (se recuerda en esta sesión).
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Remotes = ReplicatedStorage:WaitForChild("Remotes")

local IDS = {
	obby = "rbxassetid://92067940679570",
	tension = "rbxassetid://131822164483795",
}
local VOL = { obby = 0.35, tension = 0.45 }

local tracks = {}
for k, id in pairs(IDS) do
	local s = Instance.new("Sound")
	s.Name = "Music_" .. k
	s.SoundId = id
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	tracks[k] = s
end

local muted = false
local current = nil
local function switch(name)
	if name == current then
		return
	end
	current = name
	for k, s in pairs(tracks) do
		local target = (k == name and not muted) and VOL[k] or 0
		if target > 0 and not s.IsPlaying then
			s:Play()
		end
		TweenService:Create(s, TweenInfo.new(1.2), { Volume = target }):Play()
	end
end

-- en una mesa → tensión; si no → obby
local inStation = false
local phase = nil
Remotes:WaitForChild("Slap").OnClientEvent:Connect(function(kind, d)
	if kind == "station" then
		inStation = type(d) == "table"
		phase = inStation and d.phase or nil
		switch(inStation and "tension" or "obby")
		-- la tensión aprieta en el momento clave (cargar / salto)
		local t = tracks.tension
		if inStation and not muted then
			t.PlaybackSpeed = (phase == "charging" or phase == "windup") and 1.08 or 1
		end
	end
end)

-- botón 🎵 (arriba a la derecha, junto al buzón)
local gui = Instance.new("ScreenGui")
gui.Name = "MusicGui"
gui.ResetOnSpawn = false
gui.IgnoreGuiInset = true
gui.DisplayOrder = 9
gui.Parent = player:WaitForChild("PlayerGui")
local b = Instance.new("TextButton")
b.Size = UDim2.fromOffset(40, 40)
b.AnchorPoint = Vector2.new(1, 1)
b.Position = UDim2.new(1, -10, 1, -10) -- esquina de abajo a la derecha
b.BackgroundColor3 = Color3.fromRGB(60, 140, 90)
b.Text = "🎵"
b.TextScaled = true
b.Parent = gui
Instance.new("UICorner", b).CornerRadius = UDim.new(0, 12)
local st = Instance.new("UIStroke")
st.Color = Color3.new(1, 1, 1)
st.Thickness = 2
st.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
st.Parent = b
b.Activated:Connect(function()
	muted = not muted
	b.Text = muted and "🔇" or "🎵"
	b.BackgroundColor3 = muted and Color3.fromRGB(110, 60, 70) or Color3.fromRGB(60, 140, 90)
	local c = current
	current = nil
	switch(c or "obby")
end)

-- la pantalla de carga trae su propia música: empezamos cuando se cierra
task.spawn(function()
	local t = os.clock()
	while player:GetAttribute("Loading") and os.clock() - t < 30 do
		task.wait(0.2)
	end
	if current == nil then
		switch("obby")
	end
end)
