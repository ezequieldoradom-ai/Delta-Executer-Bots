local m = game:GetService("InsertService"):LoadAsset(128139695746688)
for _, d in ipairs(m:GetDescendants()) do
	if d:IsA("MeshPart") then
		print(d.Name, d.TextureID)
	elseif d:IsA("SurfaceAppearance") then
		print(d.Parent.Name, "SA", d.ColorMap)
	end
end
