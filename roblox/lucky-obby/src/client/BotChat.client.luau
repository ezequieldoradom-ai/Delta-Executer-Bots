-- Lucky Obby Race — bocadillos de los NPC (Shadow). Se ven como el chat de burbujas de Roblox.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ev = Remotes:WaitForChild("BotChat")
local english = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Locale")).code(game:GetService("Players").LocalPlayer.LocaleId) ~= "es"
local Translate = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Translate"))

ev.OnClientEvent:Connect(function(head, msg)
	if typeof(head) ~= "Instance" or not head.Parent or type(msg) ~= "string" then
		return
	end
	if english then
		msg = Translate.tr(msg)
	end
	local ok = pcall(function()
		TextChatService:DisplayBubble(head, msg)
	end)
	if not ok then
		pcall(function()
			game:GetService("Chat"):Chat(head, msg, Enum.ChatColor.White)
		end)
	end
end)
