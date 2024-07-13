pac.AddHook("InitPostEntity", "get_sky_camera", function()
	local sky_camera = ents.FindByClass("sky_camera")[1]

	if sky_camera then
		local nwVarName = "pac_in_skybox"
		local in_skybox = {}

		timer.Create("pac_in_skybox", 0.5, 0, function()
			if not IsValid(sky_camera) then
				sky_camera = ents.FindByClass("sky_camera")[1]
			end

			local new_in_skybox = {}

			local ents_pvs = ents.FindInPVS(sky_camera:GetPos())

			for i = 1, #ents_pvs do
				local ent = ents_pvs[i]

				if not in_skybox[ent] then
					ent:SetNW2Bool(nwVarName, true)
				end
				new_in_skybox[ent] = true
			end

			for i = 1, #in_skybox do
				local ent = in_skybox[i]

				if not new_in_skybox[ent] and ent:IsValid() then
					ent:SetNW2Bool(nwVarName, false)
				end
			end

			in_skybox = new_in_skybox
		end)
	end
end)