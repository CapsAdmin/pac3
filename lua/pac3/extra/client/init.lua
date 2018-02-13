pacx = pacx or {}

include("pac3/extra/shared/init.lua")

include("contraption.lua")
include("pac2_compat.lua")
include("wire_expression_extension.lua")

pac.AddHook("NetworkEntityCreated", "player_size", function(ply)
	if not ply:IsPlayer() then return end

	if ply.pac_player_size then
		pacx.SetPlayerSize(ply,ply.pac_player_size,true)
	end
end)

pac.AddHook("NotifyShouldTransmit", "player_size", function(ply,st)
	if not st then return end

	if ply:IsPlayer() and ply.pac_player_size then
		pacx.SetPlayerSize(ply, ply.pac_player_size, true)

		pac.RunNextFrame('update_entity_size_' .. ply:EntIndex(), function()
			if not ply:IsValid() then return end

			if ply.pac_player_size then
				pacx.SetPlayerSize(ply, ply.pac_player_size, true)
			end
		end)
	end
end)
