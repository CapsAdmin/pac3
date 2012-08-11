timer.Create("pac_playermodels", 0.25, 0, function()
	for key, ply in pairs(player.GetAll()) do
		local mdl = ply:GetInfo("cl_playermodel")
		if ply.pac_last_model ~= mdl then
			local realmdl = player_manager.TranslatePlayerModel(mdl)
			if realmdl then
				ply:SetModel(realmdl)
			end
			ply.pac_last_model = mdl
		end
	end
end)