if CLIENT then
	-- so the client knows it exists
	pacx.AddServerModifier("model", function(data, owner) end)

	function pacx.SetModel(path)
		net.Start("pac_setmodel")
			net.WriteString(path or "")
		net.SendToServer()
	end
end

if SERVER then
	function pacx.SetPlayerModel(ply, model)
		if model:find("^http") then
			pac.Message(ply, " wants to use ", model, " as player model")
			pac.DownloadMDL(model, function(path)
				pac.Message(model, " downloaded for ", ply)

				ply:SetModel(path)
				ply.pac_last_modifier_model = path:lower()
				ply.pac_url_playermodel = true
			end, function(err)
				pac.Message(err)
			end, ply)
		else
			if model == "" then
				model = player_manager.TranslatePlayerModel(ply:GetInfo("cl_playermodel"))
			else
				model = player_manager.AllValidModels()[model] or model

				if not util.IsValidModel(model) then
					model = player_manager.TranslatePlayerModel(ply:GetInfo("cl_playermodel"))
				end
			end

			ply:SetModel(model)
			ply.pac_last_modifier_model = model:lower()
			ply.pac_url_playermodel = false
		end
	end

	local ALLOW_TO_CHANGE_MODEL = pacx.AddServerModifier("model", function(data, owner)
		if not data then
			pacx.SetPlayerModel(owner, player_manager.TranslatePlayerModel(owner:GetInfo("cl_playermodel")))
		else
			local model

			for key, part in pairs(data.children) do
				if
					part.self.ClassName == "entity" and
					part.self.Model and
					part.self.Model ~= ""
				then
					model = part.self.Model
				end
			end

			if model then
				model = model:lower()
				if hook.Run("PACApplyModel", owner, model) == false then return end
				pacx.SetPlayerModel(owner, model)
			end
		end
	end)

	timer.Create("pac_setmodel", 0.25, 0, function()
		if not ALLOW_TO_CHANGE_MODEL:GetBool() then return end

		for _, ply in ipairs(player.GetAll()) do
			if ply.pac_last_modifier_model and ply:GetModel():lower() ~= ply.pac_last_modifier_model then
				ply:SetModel(ply.pac_last_modifier_model)
			end
		end
	end)

	util.AddNetworkString("pac_setmodel")

	net.Receive("pac_setmodel", function(_, ply)
		if ALLOW_TO_CHANGE_MODEL:GetBool() then
			local pathraw = net.ReadString()
			local path = pathraw:lower()

			if path:find("^http") then
				path = pathraw
			end

			if hook.Run("PACApplyModel", ply, path) == false then return end
			pacx.SetPlayerModel(ply, path)
		end
	end)
end
