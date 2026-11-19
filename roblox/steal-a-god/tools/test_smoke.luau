-- Prueba básica: ¿arranca el servidor del juego sin errores?
local out = {}
local function add(...)
	local t = {}
	for i = 1, select("#", ...) do
		t[i] = tostring((select(i, ...)))
	end
	table.insert(out, table.concat(t, " "))
end
local w = workspace:WaitForChild("World", 15)
add("Mundo creado:", w ~= nil)
if w then
	local plots, guardians, parts = 0, 0, 0
	for _, c in ipairs(w:GetChildren()) do
		if c.Name:match("^Plot") then plots += 1 end
		if c.Name:match("^Guardian") then guardians += 1 end
	end
	for _, d in ipairs(w:GetDescendants()) do
		if d:IsA("BasePart") then parts += 1 end
	end
	add("Parcelas:", plots, "Guardianes:", guardians, "Piezas:", parts)
end
local packs = 0
for _, c in ipairs(workspace:GetChildren()) do
	if c.Name == "Pack" then packs += 1 end
end
add("Sobres en el mapa:", packs)
add("Remotes:", game.ReplicatedStorage:FindFirstChild("Remotes") ~= nil)
return table.concat(out, "\n")
