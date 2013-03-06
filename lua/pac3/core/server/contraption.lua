util.AddNetworkString("pac_to_contraption")

net.Receive("pac_to_contraption", function(len, ply)
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

local function make_copy(tbl, input)
	for key, val in pairs(tbl.self) do
		if key == "ClassName" then continue end
		
		if (key == "Name" or key == "ParentName" or key:find("PartName", 0, true)) and val ~= "" then
			tbl.self[key] = val .. " " .. input
		end
		if key:find("UID", 0, true) or key == "UniqueID" then
			tbl.self[key] = util.CRC(val .. input)
		end
	end
	for key, val in pairs(tbl.children) do
		make_copy(val, input)
	end
end

duplicator.RegisterEntityModifier("pac_config", function(ply, ent, data)
	local id = ent:EntIndex()
	
	make_copy(data.part, id)
	
	data.owner = ply
	data.uid = ply:UniqueID()
	data.part.self.OwnerName = id
	
	ent:CallOnRemove("pac_config", function(ent)	
		data.part = data.part.self.UniqueID
		pac.RemovePart(data)
	end)
	
	pac.SubmitPart(data)
end)