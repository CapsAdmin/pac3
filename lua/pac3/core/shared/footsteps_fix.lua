if game.SinglePlayer() then
	if SERVER then
		hook.Add("PlayerFootstep", "pac_footstep_fix", function(ply, pos, _, snd, vol)
			umsg.Start("pac_footstep")
				umsg.Entity(ply)
				umsg.Vector(pos)
				umsg.String(snd)
				umsg.Float(vol)
			umsg.End()
		end)
	end

	if CLIENT then
		usermessage.Hook("pac_footstep", function(umr)
			local ply = umr:ReadEntity()
			local pos = umr:ReadVector()
			local snd = umr:ReadString()
			local vol = umr:ReadFloat()

			if ply:IsValid() then
				hook.Run("pac_PlayerFootstep", ply, pos, snd, vol)
			end
		end)
	end
else
	hook.Add("PlayerFootstep", "pac_footstep_fix", function(ply, pos, _, snd, vol)
		return hook.Run("pac_PlayerFootstep", ply, pos, snd, vol)
	end)
end