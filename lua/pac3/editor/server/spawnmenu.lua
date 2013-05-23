concommand.Add("pac_in_editor", function(ply, _, args)
	ply:SetNWBool("in pac3 editor", tonumber(args[1]) == 1)
end)

function pace.SpawnPart(ply, model)
	if model then
		if IsValid(ply) and ply:GetNWBool("in pac3 editor") then
			net.Start("pac_spawn_part")
				net.WriteString(model)
			net.Send(ply)
			return false
		end
	end
end

hook.Add( "PlayerSpawnProp", "pac_PlayerSpawnProp", pace.SpawnPart)
hook.Add( "PlayerSpawnRagdoll", "pac_PlayerSpawnRagdoll", pace.SpawnPart)
hook.Add( "PlayerSpawnEffect", "pac_PlayerSpawnEffect", pace.SpawnPart)

util.AddNetworkString("pac_spawn_part")