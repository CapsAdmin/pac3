pacx = pacx or {}

include("pac3/extra/shared/init.lua")

include("contraption.lua")
include("pac2_compat.lua")
include("wire_expression_extension.lua")

function pac.NetworkEntityCreated(ply)
	if not ply:IsPlayer() then return end

	if ply.pac_player_size then
		pacx.SetPlayerSize(ply,ply.pac_player_size,true)
	end

end
pac.AddHook("NetworkEntityCreated")

function pac.NotifyShouldTransmit(ent,st)
	if not st then return end
	if ent:IsPlayer() then
		local ply = ent
		if ply.pac_player_size then
			pacx.SetPlayerSize(ply,ply.pac_player_size,true)
			timer.Simple(0,function()
				if not ply:IsValid() then return end
				if ply.pac_player_size then
					pacx.SetPlayerSize(ply,ply.pac_player_size,true)
				end
			end)
		end
	end
end
pac.AddHook("NotifyShouldTransmit")