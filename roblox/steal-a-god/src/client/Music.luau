-- Música de persecución: suena mientras llevas un sobre robado (un guardián te persigue).
-- Entra con un fundido corto, sale con uno más largo y se acelera un poco cuando el guardián está cerca.
-- ctx = { player, Config, Locale, t, opt, getState, gui, play } (lo prepara init.client.luau)
local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local Music = {}

local VOLUME = 0.5
local FADE_IN = 0.5
local FADE_OUT = 1.2

local sound = nil
local fade = nil
local playing = false
local running = false

local function tweenVolume(goal, seconds)
	if fade then
		fade:Cancel()
	end
	fade = TweenService:Create(sound, TweenInfo.new(seconds, Enum.EasingStyle.Sine), { Volume = goal })
	fade:Play()
	return fade
end

local function setOn(on)
	if on == playing or not sound then
		return
	end
	playing = on
	if on then
		sound.TimePosition = 0
		sound.PlaybackSpeed = 1
		if not sound.IsPlaying then
			sound:Play()
		end
		tweenVolume(VOLUME, FADE_IN)
	else
		local tw = tweenVolume(0, FADE_OUT)
		tw.Completed:Connect(function(state)
			-- si la persecución vuelve durante el fundido, este tween se cancela y no se para la música
			if state == Enum.PlaybackState.Completed and not playing then
				sound:Stop()
			end
		end)
	end
end

function Music.start(ctx)
	if running then
		return
	end
	local id = ctx and ctx.Config and ctx.Config.SOUNDS and ctx.Config.SOUNDS.chase
	if type(id) ~= "string" or id == "" then
		return -- todavía no hay música subida
	end
	running = true
	sound = Instance.new("Sound")
	sound.Name = "ChaseMusic"
	sound.SoundId = id
	sound.Looped = true
	sound.Volume = 0
	sound.Parent = SoundService
	task.spawn(function()
		pcall(function()
			ContentProvider:PreloadAsync({ sound })
		end)
	end)
	task.spawn(function()
		while running do
			task.wait(0.1)
			local ok = pcall(function()
				local state = ctx.getState and ctx.getState() or {}
				local musicOn = not ctx.opt or ctx.opt("music")
				local chasing = state.carrying ~= nil and musicOn
				setOn(chasing)
				if playing then
					-- tensión: a menos de 60 bloques sube poco a poco hasta x1.08 (a 15 o menos)
					local d = tonumber(state.chase)
					local goal = 1
					if d and d < 60 then
						goal = 1 + 0.08 * math.clamp((60 - d) / 45, 0, 1)
					end
					sound.PlaybackSpeed += (goal - sound.PlaybackSpeed) * 0.15
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
	playing = false
	if fade then
		fade:Cancel()
	end
	if sound then
		sound:Stop()
		sound:Destroy()
		sound = nil
	end
end

return Music
