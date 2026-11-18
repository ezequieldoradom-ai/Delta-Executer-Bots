-- Ciclo: 5 min de día, 20 s de noche. Al amanecer se renuevan los sobres.
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local DayNight = {}
local G
local C

local night = false
local endsAt = 0
local warned = false
local pendingNight = false -- "Noche para el servidor" comprada de noche: la siguiente llega 20 s después del amanecer

function DayNight.isNight()
	return night
end

function DayNight.timeLeft()
	return math.max(0, endsAt - os.clock())
end

local function tweenLight(toNight)
	local info = TweenInfo.new(2.5, Enum.EasingStyle.Sine)
	local L = C.LIGHT
	local to = toNight and L.night or L.day
	TweenService:Create(Lighting, info, { ClockTime = to.clock, Brightness = to.brightness, OutdoorAmbient = to.outdoor }):Play()
	local grade = Lighting:FindFirstChild("Grade")
	if grade then
		TweenService:Create(grade, info, { TintColor = to.tint }):Play()
	end
	local gate = G.World.nightGate
	if gate then
		TweenService:Create(gate, info, { Transparency = toNight and 0.15 or 1 }):Play()
		gate.CanCollide = toNight
	end
end

local function startNight()
	night = true
	endsAt = os.clock() + C.NIGHT_SECONDS
	warned = false
	tweenLight(true)
	G.Packs.nightfall()
	G.Net.announce("all", "nightStart", {}, { color = "#A78BFA", big = true })
end

local function startDay()
	night = false
	endsAt = os.clock() + (pendingNight and 20 or C.DAY_SECONDS)
	pendingNight = false
	warned = false
	tweenLight(false)
	G.Packs.refreshAll()
end

-- Producto "Noche para el servidor": adelanta la noche
function DayNight.forceNight(buyerName)
	if not night then
		endsAt = math.min(endsAt, os.clock() + 3)
		warned = true
	else
		pendingNight = true -- ya es de noche: la próxima llegará 20 s después del amanecer
	end
	G.Net.announce("all", "nightBought", { buyerName }, { color = "#A78BFA", big = true })
end

function DayNight.init(g)
	G = g
	C = g.Config
end

function DayNight.start()
	startDay()
	task.spawn(function()
		while true do
			task.wait(0.25)
			local left = endsAt - os.clock()
			if not night and not warned and left <= C.NIGHT_WARNING then
				warned = true
				G.Net.announce("all", "nightSoon", { math.ceil(left) }, { color = "#A78BFA" })
			end
			if left <= 0 then
				if night then
					startDay()
				else
					startNight()
				end
			end
		end
	end)
end

return DayNight
