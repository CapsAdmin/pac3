
if game.SinglePlayer() then
	if SERVER then
		util.AddNetworkString('pac_footstep')
		util.AddNetworkString('pac_footstep_request_state_update')
		util.AddNetworkString('pac_signal_mute_footstep')

		hook.Add("PlayerFootstep", "footstep_fix", function(ply, pos, _, snd, vol)
			net.Start("pac_footstep_request_state_update")
			net.Send(ply)

			net.Start("pac_footstep")
				net.WriteEntity(ply)
				net.WriteVector(pos)
				net.WriteString(snd)
				net.WriteFloat(vol)
			net.Broadcast()
		end)

		net.Receive("pac_signal_mute_footstep", function(len,ply)
			local b = net.ReadBool()
			ply.pac_mute_footsteps = b
			if ply.pac_mute_footsteps then
				hook.Add("PlayerFootstep", "pac_footstep_silence", function()
					return b
				end)
			else hook.Remove("PlayerFootstep", "pac_footstep_silence") end
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
		net.Receive("pac_footstep_request_state_update", function()
			net.Start("pac_signal_mute_footstep")
			net.WriteBool(LocalPlayer().pac_mute_footsteps)
			net.SendToServer()
		end)
	end
else
	hook.Add("PlayerFootstep", "footstep_fix", function(ply, pos, _, snd, vol)
		return hook.Run("pac_PlayerFootstep", ply, pos, snd, vol)
	end)
end
