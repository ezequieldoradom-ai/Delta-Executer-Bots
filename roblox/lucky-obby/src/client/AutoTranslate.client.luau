-- Lucky Obby Race — si tu Roblox no está en español, todo lo que aparece en pantalla y en el mapa
-- (carteles, paneles, avisos, botones de acción) se pasa al inglés en cuanto aparece o cambia.
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local Shared = ReplicatedStorage:WaitForChild("Shared")
if require(Shared:WaitForChild("Locale")).code(player.LocaleId) == "es" then
	return
end
local Translate = require(Shared:WaitForChild("Translate"))

local hooked = setmetatable({}, { __mode = "k" })
local function fix(obj, prop)
	if obj:GetAttribute("NoTranslate") then
		return
	end
	local ok, cur = pcall(function()
		return obj[prop]
	end)
	if not ok or type(cur) ~= "string" or cur == "" then
		return
	end
	local out = Translate.tr(cur)
	if out ~= cur then
		obj[prop] = out
	end
end
local function hook(obj)
	if hooked[obj] then
		return
	end
	local props
	if obj:IsA("TextLabel") or obj:IsA("TextButton") then
		props = { "Text" }
	elseif obj:IsA("TextBox") then
		props = { "PlaceholderText" }
	elseif obj:IsA("ProximityPrompt") then
		props = { "ActionText", "ObjectText" }
	else
		return
	end
	hooked[obj] = true
	for _, prop in ipairs(props) do
		fix(obj, prop)
		obj:GetPropertyChangedSignal(prop):Connect(function()
			fix(obj, prop)
		end)
	end
end
local function watch(root)
	for _, d in ipairs(root:GetDescendants()) do
		hook(d)
	end
	root.DescendantAdded:Connect(hook)
end
watch(workspace)
watch(player:WaitForChild("PlayerGui"))
