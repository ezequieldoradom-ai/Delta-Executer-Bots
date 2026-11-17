-- Números absurdos: 1.5K, 20M, 3.2B, 1T, 4Qa, 7Qi, 2Sx...
local Format = {}

local SUFFIXES = { "", "K", "M", "B", "T", "Qa", "Qi", "Sx", "Sp", "Oc", "No", "Dc", "UDc", "DDc", "TDc", "QaDc", "QiDc" }

function Format.num(n: number): string
	if n ~= n then
		return "0"
	end
	if n < 0 then
		return "-" .. Format.num(-n)
	end
	if n < 1000 then
		if n == math.floor(n) then
			return tostring(math.floor(n))
		end
		return string.format("%.1f", n)
	end
	local tier = math.floor(math.log10(n) / 3)
	if tier >= #SUFFIXES then
		return string.format("%.2e", n)
	end
	local scaled = n / 10 ^ (tier * 3)
	local s
	if scaled >= 100 then
		s = string.format("%d", math.floor(scaled))
	elseif scaled >= 10 then
		s = string.format("%.1f", math.floor(scaled * 10) / 10)
	else
		s = string.format("%.2f", math.floor(scaled * 100) / 100)
	end
	s = s:gsub("%.?0+$", "")
	return s .. SUFFIXES[tier + 1]
end

function Format.time(sec: number): string
	sec = math.max(0, math.floor(sec))
	local d = math.floor(sec / 86400)
	local h = math.floor(sec % 86400 / 3600)
	local m = math.floor(sec % 3600 / 60)
	local s = sec % 60
	if d > 0 then
		return string.format("%dd %dh", d, h)
	elseif h > 0 then
		return string.format("%dh %02dm", h, m)
	end
	return string.format("%d:%02d", m, s)
end

function Format.oneIn(chance: number): string
	if chance <= 0 then
		return "—"
	end
	return "1/" .. Format.num(1 / chance)
end

function Format.hex(c: Color3): string
	return string.format("#%02X%02X%02X", math.floor(c.R * 255), math.floor(c.G * 255), math.floor(c.B * 255))
end

return Format
