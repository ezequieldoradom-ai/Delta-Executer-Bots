-- Lucky Obby Race — bocadillos de los NPC (Shadow). Se ven como el chat de burbujas de Roblox.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TextChatService = game:GetService("TextChatService")

local Remotes = ReplicatedStorage:WaitForChild("Remotes")
local ev = Remotes:WaitForChild("BotChat")

ev.OnClientEvent:Connect(function(head, msg)
	if typeof(head) ~= "Instance" or not head.Parent or type(msg) ~= "string" then
		return
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
