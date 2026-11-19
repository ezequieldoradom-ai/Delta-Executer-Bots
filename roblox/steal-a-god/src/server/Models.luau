-- Carga los modelos 3D (subidos desde Blender) y los deja listos como plantillas
local InsertService = game:GetService("InsertService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Models = {}

function Models.load(Config)
	local folder = Instance.new("Folder")
	folder.Name = "GodTemplates"
	folder.Parent = ReplicatedStorage
	for id, info in pairs(Config.MODELS) do
		local ok, asset = pcall(function()
			return InsertService:LoadAsset(info.asset)
		end)
		if ok and asset then
			local m = asset:FindFirstChildOfClass("Model") or asset
			m.Name = id
			for _, p in ipairs(m:GetDescendants()) do
				if p:IsA("BasePart") then
					p.Anchored = true
					p.CanCollide = false
					p.CanQuery = false
					p.CanTouch = false
					local j = info.joints[p.Name]
					if j then
						p:SetAttribute("Joint", j)
					end
				end
			end
			local root = Instance.new("Part")
			root.Name = "Root"
			root.Size = Vector3.new(1, 0.2, 1)
			root.Position = Vector3.new(0, 0.1, 0)
			root.Anchored = true
			root.CanCollide = false
			root.CanQuery = false
			root.Transparency = 1
			root.Parent = m
			m.PrimaryPart = root
			m:SetAttribute("Animated", true)
			m.Parent = folder
		else
			warn("No se pudo cargar el modelo", id, asset)
		end
	end
end

return Models
