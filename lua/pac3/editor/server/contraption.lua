util.AddNetworkString("pac_to_contraption")

local receieved = {}

net.Receive("pac_to_contraption", function(len, ply)
	local data = net.ReadTable()
	
	for key, val in pairs(data) do
		if hook.Call("PlayerSpawnProp", GAMEMODE, ply, data.mdl) ~= false then
			local ent = ents.Create("prop_physics")
			
			SafeRemoveEntity(receieved[val.id])
			receieved[val.id] = ent
			
			ent:SetModel(val.mdl)
			ent:SetPos(val.pos)
			ent:SetAngles(val.ang)
			ent:SetColor(val.clr)
			ent:SetSkin(val.skn)
			ent:SetMaterial(val.mat)
			ent:Spawn()
			ent:SetHealth(9999999) -- how do i make it unbreakable?
			
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