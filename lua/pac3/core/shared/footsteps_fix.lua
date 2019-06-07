
if game.SinglePlayer() then
	if SERVER then
		util.AddNetworkString('pac_footstep')
		hook.Add("PlayerFootstep", "footstep_fix", function(ply, pos, _, snd, vol)
			net.Start("pac_footstep")
				net.WriteEntity(ply)
				net.WriteVector(pos)
				net.WriteString(snd)
				net.WriteFloat(vol)
			net.Broadcast()
		end)
	end

	if CLIENT then
		net.Receive("pac_footstep", function(len)
			local ply = net.ReadEntity()
			local pos = net.ReadVector()
			local snd = net.ReadString()
			local vol = net.ReadFloat()

			if ply:IsValid() then
				hook.Run("pac_PlayerFootstep", ply, pos, snd, vol)
			end
		end)
	end
else
	hook.Add("PlayerFootstep", "footstep_fix", function(ply, pos, _, snd, vol)
		return hook.Run("pac_PlayerFootstep", ply, pos, snd, vol)
	end)
end
