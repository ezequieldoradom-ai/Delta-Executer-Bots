-- Fragmento para tools/test_full.luau (pegar después del paso "Noche y amanecer").
-- Usa las variables que ya existen allí: step, G.
step("Vendedores: santuarios, avisos y carteles", function()
	assert(G.Vendors, "falta el módulo Vendors")
	assert(#G.Vendors.errors == 0, table.concat(G.Vendors.errors, " | "))
	local CS = game:GetService("CollectionService")
	for key, name in pairs({ aura = "VendorAura", coach = "VendorCoach" }) do
		local folder = G.World.getRoot():FindFirstChild(name)
		assert(folder and folder:GetAttribute("VendorPos") == G.Config.VENDORS[key].pos, name)
		local prompts, plates = 0, 0
		for _, p in ipairs(CS:GetTagged("VendorPrompt")) do
			if p:IsDescendantOf(folder) then
				prompts += 1
				assert(p:IsA("ProximityPrompt") and p:GetAttribute("Vendor") == key, "aviso " .. key)
			end
		end
		for _, bb in ipairs(CS:GetTagged("Loc")) do
			if bb:IsDescendantOf(folder) then
				plates += 1
				assert(bb:GetAttribute("Vendor") == key and bb:FindFirstChild("Label"), "cartel " .. key)
			end
		end
		assert(prompts == 1 and plates == 1, key .. ": avisos " .. prompts .. ", carteles " .. plates)
		assert(folder:FindFirstChildWhichIsA("Model"), key .. ": sin dios")
	end
end)

step("Auras: capas en Attachments AuraFX y limpieza", function()
	assert(G.AuraFx, "falta el módulo AuraFx")
	local hrp = Instance.new("Part")
	hrp.Anchored = true
	hrp.Parent = workspace
	for i, aura in ipairs(G.Config.AURAS) do
		G.AuraFx.apply(hrp, aura)
		local rate, n = 0, 0
		for _, d in ipairs(hrp:GetDescendants()) do
			if d:IsA("ParticleEmitter") then
				assert(d.Parent.Name == "AuraFX" and d.Parent.Parent == hrp, aura.id .. ": emisor fuera de AuraFX")
				rate += d.Rate
				n += 1
			end
		end
		assert(n >= 3 and rate <= (i == 1 and 30 or 70), aura.id .. ": " .. n .. " emisores, " .. rate .. " partículas/s")
		assert(hrp:GetAttribute("AuraColor") == aura.color, aura.id .. ": AuraColor")
	end
	G.AuraFx.apply(hrp, nil)
	assert(#hrp:GetChildren() == 0 and hrp:GetAttribute("AuraColor") == nil, "la limpieza deja restos")
	hrp:Destroy()
end)
