timer.Create("pac_in_skybox", 0.5, 0, function()

	local sky_camera = ents.FindByClass("sky_camera")[1]

	if not sky_camera then timer.Remove("pac_in_skybox") return end

	local in_skybox = {}

	for _, ent in ipairs(ents.FindInPVS(sky_camera:GetPos())) do
		if not ent:GetNW2Bool("pac_in_skybox") then
			ent:SetNW2Bool("pac_in_skybox", true)
		end
		in_skybox[ent] = true
	end

	for _, ent in ipairs(ents.GetAll()) do
		if not in_skybox[ent] then
			if ent:GetNW2Bool("pac_in_skybox") then
				ent:SetNW2Bool("pac_in_skybox", false)
			end
		end
	end
end)