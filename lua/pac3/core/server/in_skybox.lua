hook.Add("InitPostEntity","pac_get_sky_camera",function()
	local sky_camera = ents.FindByClass("sky_camera")[1]
	if sky_camera then
		local nwVarName = "pac_in_skybox"
		local in_skybox = {}

		timer.Create("pac_in_skybox", 0.5, 0, function()
			if not IsValid(sky_camera) then
				sky_camera = ents.FindByClass("sky_camera")[1]
			end
			local new_in_skybox = {}
			for _, ent in ipairs(ents.FindInPVS(sky_camera:GetPos())) do
				if not in_skybox[ent] then
					ent:SetNW2Bool(nwVarName, true)
				end
				new_in_skybox[ent] = true
			end

			for ent in pairs(in_skybox) do
				if not new_in_skybox[ent] and ent:IsValid() then
					ent:SetNW2Bool(nwVarName, false)
				end
			end

			in_skybox = new_in_skybox
		end)
	end
end)