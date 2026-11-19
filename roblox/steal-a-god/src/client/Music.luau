-- Música: de fondo (alegre y acogedora, en todo el juego y en el Ascenso al Olimpo) y de persecución.
-- La de persecución suena solo mientras llevas un sobre robado Y estás al otro lado de la línea segura
-- (Config.SAFE_Z): al pasar a la plaza se apaga con un fundido y vuelve la de fondo donde se quedó.
-- La persecución se acelera un poco cuando el guardián está cerca.
-- ctx = { player, Config, Locale, t, opt, getState, gui, play } (lo prepara init.client.luau)
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local Music = {}

local CHASE_VOLUME = 0.5
local BGM_VOLUME = 0.32
local FADE_IN = 0.5
local FADE_OUT = 1.2

local running = false
local tracks = {} -- name = { sound, fade, on }

local function track(name, id, volume)
	if type(id) ~= "string" or id == "" then
		return nil
	end
	local s = Instance.new("Sound")
	s.Name = name
	s.SoundId = id
	s.Looped = true
	s.Volume = 0
	s.Parent = SoundService
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ s })
		end)
	end)
	local t = { sound = s, fade = nil, on = false, volume = volume }
	tracks[name] = t
	return t
end

-- Enciende o apaga una pista con fundido. restart: empezar desde el principio (persecución) o seguir (fondo)
local function setOn(t, on, restart)
	if not t or t.on == on then
		return
	end
	t.on = on
	if t.fade then
		t.fade:Cancel()
	end
	local s = t.sound
	if on then
		if restart then
			s.TimePosition = 0
			s.PlaybackSpeed = 1
		end
		if not s.IsPlaying then
			s:Resume()
			if not s.IsPlaying then
				s:Play()
			end
		end
		t.fade = TweenService:Create(s, TweenInfo.new(FADE_IN, Enum.EasingStyle.Sine), { Volume = t.volume })
		t.fade:Play()
	else
		t.fade = TweenService:Create(s, TweenInfo.new(FADE_OUT, Enum.EasingStyle.Sine), { Volume = 0 })
		t.fade.Completed:Connect(function(state)
			-- si vuelve a encenderse durante el fundido, este tween se cancela y no se para
			if state == Enum.PlaybackState.Completed and not t.on then
				s:Pause()
			end
		end)
		t.fade:Play()
	end
end

-- ¿Estás en peligro? Llevas un sobre y estás al otro lado de la línea segura
function Music.inDanger(state, player, Config)
	if state.carrying == nil then
		return false
	end
	local char = player and player.Character
	local hrp = char and char:FindFirstChild("HumanoidRootPart")
	local safeZ = Config.SAFE_Z or 102
	return not hrp or hrp.Position.Z >= safeZ
end

function Music.start(ctx)
	if running then
		return
	end
	local S = ctx and ctx.Config and ctx.Config.SOUNDS or {}
	running = true
	local chase = track("ChaseMusic", S.chase, CHASE_VOLUME)
	local bgm = track("BackgroundMusic", S.bgm, BGM_VOLUME)
	task.spawn(function()
		while running do
			task.wait(0.1)
			local ok = pcall(function()
				local state = ctx.getState and ctx.getState() or {}
				local musicOn = not ctx.opt or ctx.opt("music")
				local danger = musicOn and Music.inDanger(state, ctx.player, ctx.Config)
				setOn(chase, danger, true)
				setOn(bgm, musicOn and not danger, false)
				if chase and chase.on then
					-- tensión: a menos de 60 bloques sube poco a poco hasta x1.08 (a 15 o menos)
					local d = tonumber(state.chase)
					local goal = 1
					if d and d < 60 then
						goal = 1 + 0.08 * math.clamp((60 - d) / 45, 0, 1)
					end
					chase.sound.PlaybackSpeed += (goal - chase.sound.PlaybackSpeed) * 0.15
				end
			end)
			if not ok then
				task.wait(1)
			end
		end
	end)
end

function Music.stop()
	running = false
	for _, t in pairs(tracks) do
		if t.fade then
			t.fade:Cancel()
		end
		t.sound:Stop()
		t.sound:Destroy()
	end
	table.clear(tracks)
end

return Music
