net.Receive("pac_to_contraption", function()
	local data = net.ReadTable()
	
	for key, val in pairs(data) do
		if hook.Call("PlayerSpawnProp", GAMEMODE, ply, data.mdl) ~= false then
			local ent = ents.Create("prop_physics")
			ent:SetModel(val.mdl)
			ent:SetPos(val.pos)
			ent:SetAngles(val.ang)
			ent:SetColor(unpack(val.clr))
			ent:SetSkin(val.skn)
			ent:SetMaterial(val.mat)
			ent:Spawn()
			
			if ent.CPPISetOwner then
				ent:CPPISetOwner(ply)
			end
			
			local phys = ent:GetPhysicsObject()
			if phys:IsValid() then
				phys:EnableMotion(false)
				
				undo.Create("prop")
					undo.SetPlayer(ply)
					undo.AddEntity(ent)
				undo.Finish()
				
				hook.Call("PlayerSpawnedProp", GAMEMODE, ply, data.mdl, ent)
			else
				ent:Remove()
			end
		end
	end
end)