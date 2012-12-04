function pac.SpawnPart(ply, model)
	if model then
		if IsValid(ply) and ply:GetNWBool("in pac3 editor") then
			net.Start("pac_spawn_part")
				net.WriteString(model)
			net.Send(ply)
			return false
		end
	end
end

hook.Add( "PlayerSpawnProp", "pac_PlayerSpawnProp", pac.SpawnPart)
hook.Add( "PlayerSpawnRagdoll", "pac_PlayerSpawnRagdoll", pac.SpawnPart)
hook.Add( "PlayerSpawnEffect", "pac_PlayerSpawnEffect", pac.SpawnPart)

util.AddNetworkString("pac_spawn_part")