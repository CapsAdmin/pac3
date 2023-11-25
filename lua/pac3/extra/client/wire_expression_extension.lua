local IsValid = IsValid

hook.Add("pac_Initialized", "pac_e2_extension", function()
	if E2Helper then
		E2Helper.Descriptions["pacSetKeyValue"] = "Sets a property value on given part. Part unique id is recommended but you can also input name."
	end
end)

local function SetKeyValue(ply, ent, unique_id, key, val)
	local set = "Set" .. key
	
	if ent == game.GetWorld() then ent = pac.WorldEntity end

	local part = pac.GetPartFromUniqueID(pac.Hash(ply), unique_id)
	if not IsValid( part ) then return end

	if part:GetRootPart():GetOwner() == ent then
		if key == "EventHide" then
			part:SetEventTrigger(ent, val > 0)
		else
			local t1 = type(part[key])
			local t2 = type(val)

			if t1 == "boolean" and t2 == "number" then
				t2 = "boolean"
				val = val > 0
			end

			if t1 == t2 then
				part[set](part, val)
			end
		end
	end
end

net.Receive("pac_e2_setkeyvalue_str", function()
	local ply = net.ReadEntity()

	if ply:IsValid() then
		local ent = net.ReadEntity()
		local id = net.ReadString()
		local key = net.ReadString()
		local val = net.ReadString()

		SetKeyValue(ply, ent, id, key, val)
	end
end)

net.Receive("pac_e2_setkeyvalue_vec", function()
	local ply = net.ReadEntity()

	if ply:IsValid() then
		local ent = net.ReadEntity()
		local id = net.ReadString()
		local key = net.ReadString()
		local val = net.ReadVector()

		SetKeyValue(ply, ent, id, key, val)
	end
end)

net.Receive("pac_e2_setkeyvalue_ang", function()
	local ply = net.ReadEntity()

	if ply:IsValid() then
		local ent = net.ReadEntity()
		local id = net.ReadString()
		local key = net.ReadString()
		local val = net.ReadAngle()

		SetKeyValue(ply, ent, id, key, val)
	end
end)

net.Receive("pac_e2_setkeyvalue_num", function()
	local ply = net.ReadEntity()

	if ply:IsValid() then
		local ent = net.ReadEntity()
		local id = net.ReadString()
		local key = net.ReadString()
		local val = net.ReadFloat()

		SetKeyValue(ply, ent, id, key, val)
	end
end)