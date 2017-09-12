if CLIENT then
	-- so the client knows it exists
	pacx.AddServerModifier("model", function(data, owner) end)

	function pacx.SetModel(path)
		net.Start("pac_setmodel")
			net.WriteString(path)
		net.SendToServer()
	end
end

if SERVER then
	function pacx.SetPlayerModel(ply, model)
		if not model then return end
		model = player_manager.AllValidModels()[model] or model

		if not util.IsValidModel(model) then
			model = player_manager.TranslatePlayerModel(ply:GetInfo("cl_playermodel"))
		end

		ply:SetModel(model)

		ply.pac_last_modifier_model = model:lower()
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
				pacx.SetPlayerModel(owner, model)
			end
		end
	end)

	util.AddNetworkString("pac_setmodel")

	net.Receive("pac_setmodel", function(_, ply)
		local path = net.ReadString()

		if path:find("^http") then
			local url = path
			pac.Message(ply, " wants to use ", url, " as player model")
			pac.DownloadMDL(url, function(path)
				pac.Message(url, " downloaded for ", ply)
				ply:SetModel(path)
				ply.pac_mdl_zip = true
			end, function(err)
				pac.Message(err)
			end, ply)
		else
			ply.pac_mdl_zip = false
		end

		if ALLOW_TO_CHANGE_MODEL:GetBool() then
			pacx.SetPlayerModel(ply, args[1])
		end
	end)

	local function PlayerCheckModel(ply)
		if not ply.pac_mdl_zip and ply.pac_last_modifier_model and ply:GetModel():lower() ~= ply.pac_last_modifier_model then
			ply:SetModel(ply.pac_last_modifier_model)
		end
	end

	hook.Add("Think", "pac_setmodel", function(ply)
		for key, ply in pairs(player.GetAll()) do
			PlayerCheckModel(ply)
		end
	end)

	hook.Add("PlayerSlowThink", "pac_setmodel", function(ply)
		hook.Remove("Think", "pac_setmodel")
		hook.Add("PlayerSlowThink", "pac_setmodel", PlayerCheckModel)
	end)
end