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
		return tostring(math.floor(n))
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
	if string.find(s, ".", 1, true) then
		s = s:gsub("0+$", ""):gsub("%.$", "")
	end
	return s .. SUFFIXES[tier + 1]
end

-- Multiplicador con decimales cuando es pequeño: 1.35, 12.6, 840, 6.04K
function Format.mult(x: number): string
	if x ~= x then
		return "1"
	end
	local s
	if x < 10 then
		s = string.format("%.2f", math.floor(x * 100 + 0.5) / 100)
	elseif x < 100 then
		s = string.format("%.1f", math.floor(x * 10 + 0.5) / 10)
	else
		return Format.num(x)
	end
	s = s:gsub("0+$", ""):gsub("%.$", "")
	return s
end

-- Número entero con separador de miles: 93.754 (es) o 93,754 (en)
function Format.group(n: number, sep: string?): string
	local s = tostring(math.floor(math.max(0, n or 0)))
	local out = s:reverse():gsub("(%d%d%d)", "%1" .. (sep or ".")):reverse()
	if out:sub(1, 1) == (sep or ".") then
		out = out:sub(2)
	end
	return out
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
