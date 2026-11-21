-- Lucky Obby Race — en la plaza central (la isla del vestíbulo) se anda más rápido para ir de un juego a otro (Shadow)
-- Dentro de un juego manda la velocidad de ese juego: carrera, mesas de guantazos, rey de la colina y obbys.
local Players = game:GetService("Players")

local LobbySpeed = {}
LobbySpeed.SPEED = 24
local NORMAL = 16

function LobbySpeed.init(G)
	local Decor = require(script.Parent.Decor)
	local center = Decor.ISLAND_CENTER or G.Config.COURSE.LOBBY
	local radius = (Decor.ISLAND_R or 185) + 10
	local function busy(p)
		if G.Race.isRacing(p) then
			return true
		end
		if G.Slap and G.Slap.stationOf(p) then
			return true
		end
		if G.Hill and G.Hill.memberOf(p) then
			return true
		end
		if G.Obbies and G.Obbies.sessions[p] then
			return true
		end
		return false
	end
	task.spawn(function()
		while true do
			task.wait(0.25)
			for _, p in ipairs(Players:GetPlayers()) do
				local c = p.Character
				local hrp = c and c:FindFirstChild("HumanoidRootPart")
				local hum = c and c:FindFirstChildOfClass("Humanoid")
				if hrp and hum and hum.Health > 0 then
					local d = Vector3.new(hrp.Position.X - center.X, 0, hrp.Position.Z - center.Z).Magnitude
					local inPlaza = d < radius and hrp.Position.Y < 40
					if inPlaza and not busy(p) then
						-- solo si va a la velocidad normal (no pisa a nadie que la haya cambiado: hielo, miel, mesas…)
						if hum.WalkSpeed == NORMAL then
							hum.WalkSpeed = LobbySpeed.SPEED
						end
					elseif hum.WalkSpeed == LobbySpeed.SPEED then
						hum.WalkSpeed = NORMAL -- fuera de la plaza o dentro de un juego: velocidad normal
					end
				end
			end
		end
	end)
end

return LobbySpeed
