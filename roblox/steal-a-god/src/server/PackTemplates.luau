-- Un sobre de muestra por rareza en ReplicatedStorage.PackTemplates ("R1"…"R14").
-- Lo usa el cliente para la apertura en 3D (ViewportFrame): el sobre de verdad, con su diseño,
-- gira, se carga y se rompe. Solo piezas ancladas: sin partículas, luces, carteles, avisos ni etiquetas
-- (un ViewportFrame no los dibuja y las etiquetas harían que Fx.luau animara las muestras).
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

local PackTemplates = {}

local STRIP = {
	ParticleEmitter = true, Beam = true, Trail = true, PointLight = true, SpotLight = true, SurfaceLight = true,
	BillboardGui = true, SurfaceGui = true, ProximityPrompt = true, Sound = true, Script = true, LocalScript = true,
	Fire = true, Sparkles = true, Smoke = true, SelectionBox = true, WeldConstraint = true, Attachment = true,
}

local function untag(inst)
	for _, tagName in ipairs(CollectionService:GetTags(inst)) do
		CollectionService:RemoveTag(inst, tagName)
	end
end

-- Construye la muestra de una rareza (devuelve el modelo, sin padre)
function PackTemplates.build(G, r)
	local C = G.Config
	local p = Instance.new("Part")
	p.Name = "Body"
	p.Size = Vector3.new(3, 4, 0.5)
	p.CFrame = CFrame.new()
	p.Anchored = true
	p.CanCollide, p.CanQuery, p.CanTouch = false, false, false
	p.Color = C.RARITIES[r].color
	p.Material = Enum.Material.Foil
	p.TopSurface = Enum.SurfaceType.Smooth
	p.BottomSurface = Enum.SurfaceType.Smooth
	if G.PackStyle then
		G.PackStyle.build({ id = 0, rarity = r, kg = 100, dawn = false, zone = 1 }, p, 1)
	end
	local m = Instance.new("Model")
	m.Name = "R" .. r
	p.Parent = m
	m.PrimaryPart = p
	untag(m)
	for _, d in ipairs(m:GetDescendants()) do
		untag(d)
		if STRIP[d.ClassName] then
			d:Destroy()
		elseif d:IsA("BasePart") then
			d.Anchored = true
			d.CastShadow = false
			-- fuera lo que se aleja o es enorme (columnas, aros grandes): la cámara enfoca el sobre
			local big = math.max(d.Size.X, d.Size.Y, d.Size.Z)
			if d ~= p and (d.Position.Magnitude > 6 or big > 7) then
				d:Destroy()
			end
		end
	end
	m:SetAttribute("Rarity", r)
	return m
end

function PackTemplates.init(G)
	local old = ReplicatedStorage:FindFirstChild("PackTemplates")
	if old then
		old:Destroy()
	end
	local folder = Instance.new("Folder")
	folder.Name = "PackTemplates"
	for r = 1, #G.Config.RARITIES do
		local ok, res = pcall(PackTemplates.build, G, r)
		if ok then
			res.Parent = folder
		else
			warn("[PackTemplates] rareza " .. r .. ": " .. tostring(res))
		end
	end
	folder.Parent = ReplicatedStorage
	return folder
end

return PackTemplates
