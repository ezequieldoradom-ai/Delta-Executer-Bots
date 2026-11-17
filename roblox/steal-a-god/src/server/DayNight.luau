-- Ciclo: 5 min de día, 15 s de noche. Al amanecer se renuevan los sobres.
local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")

local DayNight = {}
local G
local C

local night = false
local endsAt = 0
local warned = false

function DayNight.isNight()
	return night
end

function DayNight.timeLeft()
	return math.max(0, endsAt - os.clock())
end

local function tweenLight(toNight)
	local info = TweenInfo.new(2.5, Enum.EasingStyle.Sine)
	TweenService:Create(Lighting, info, {
		ClockTime = toNight and 0.5 or 16.3,
		Brightness = toNight and 0.7 or 3,
		OutdoorAmbient = toNight and Color3.fromRGB(50, 45, 100) or Color3.fromRGB(175, 145, 125),
	}):Play()
	local grade = Lighting:FindFirstChild("Grade")
	if grade then
		TweenService:Create(grade, info, { TintColor = toNight and Color3.fromRGB(170, 170, 255) or Color3.fromRGB(255, 240, 222) }):Play()
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
	endsAt = os.clock() + C.DAY_SECONDS
	warned = false
	tweenLight(false)
	G.Packs.refreshAll()
end

-- Producto "Noche para el servidor": adelanta la noche
function DayNight.forceNight(buyerName)
	if not night then
		endsAt = math.min(endsAt, os.clock() + 3)
		G.Net.announce("all", "nightBought", { buyerName }, { color = "#A78BFA", big = true })
		warned = true
	end
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
