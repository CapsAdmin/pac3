if CLIENT then
	-- so the client knows it exists
	pac.AddServerModifier("model", function(data, owner) end)
end

if SERVER then

	function pac.SetPlayerModel(ply, model)
		if ClockWork then return end -- Clockwork fix
		model = player_manager.AllValidModels()[model] or model

		if not util.IsValidModel(model) then
			model = player_manager.TranslatePlayerModel(ply:GetInfo("cl_playermodel"))
		end

		ply:SetModel(model)

		ply.pac_last_modifier_model = model:lower()
	end

	pac.AddServerModifier("model", function(data, owner)
		if not data then
			pac.SetPlayerModel(owner, player_manager.TranslatePlayerModel(owner:GetInfo("cl_playermodel")))
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
				pac.SetPlayerModel(owner, model)
			end
		end
	end)

	concommand.Add("pac_setmodel", function(ply, _, args)
		if GetConVarNumber("pac_modifier_model") ~= 0 and ply:GetInfo("pac_modifier_model") ~= 0 and !ClockWork then
			pac.SetPlayerModel(ply, args[1])
		end
	end)
	local function PlayerCheckModel(ply)
		if ply.pac_last_modifier_model and ply:GetModel():lower() ~= ply.pac_last_modifier_model then
			ply:SetModel(ply.pac_last_modifier_model)
		end
	end

	hook.Add("Think", "pac_setmodel", function(ply)
		if ClockWork then hook.Remove("Think", "pac_setmodel") return end
		for key, ply in pairs(player.GetAll()) do
			PlayerCheckModel(ply)
		end
	end)

	hook.Add("PlayerSlowThink", "pac_setmodel", function(ply)
		hook.Remove("Think", "pac_setmodel")
		hook.Add("PlayerSlowThink", "pac_setmodel", PlayerCheckModel)
	end)
end