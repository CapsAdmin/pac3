local function decimal_hack_unpack(tbl)
	for key, val in pairs(tbl) do
		local t = type(val)
		if t == "table" then 
			if val.__type then
				t = val.__type 
				
				if t == "Vector" then
					tbl[key] = Vector()
					tbl[key].x = tostring(val.x)
					tbl[key].y = tonumber(val.y)
					tbl[key].z = tonumber(val.z)
				elseif t == "number" then
					tbl[key] = tonumber(val.val)
				end
			else
				decimal_hack_unpack(val)
			end
		end
	end
	
	return tbl
end

local function decimal_hack_pack(tbl)
	for key, val in pairs(tbl) do
		local t = type(val)
		if t == "Vector" then
			tbl[key] = {}
			tbl[key].x = tostring(val.x)
			tbl[key].y = tostring(val.y)
			tbl[key].z = tostring(val.z)
			tbl[key].__type = "Vector"
		elseif t == "number" then
			tbl[key] = {__type = "number", val = tostring(val)}
		elseif t == "table" then
			decimal_hack_pack(val)
		end
	end
	
	return tbl
end

do -- to server
	function pac.SendPartToServer(part)
		local data = {part = part:ToTable()}
		data.owner = part:GetOwner()

		if hook.Run("pac_SendData", filter or player.GetAll(), data) ~= false then
			if pac.netstream then
				pac.netstream.Start("pac_submit", data)
			else
				net.Start("pac_submit")
					decimal_hack_pack(data)
					net.WriteTable(data)
				net.SendToServer()
			end
		end
	end

	function pac.RemovePartOnServer(name, server_only, filter)
		local data = {part = name, server_only = server_only, filter = filter}
		
		if name == "__ALL__" then
			pac.HandleModifiers(nil, LocalPlayer())
		end
		
		if pac.netstream then
			pac.netstream.Start("pac_submit", data)
		else
			net.Start("pac_submit")
				decimal_hack_pack(data)
				net.WriteTable(data)
			net.SendToServer()
		end
	end
end

do -- from server
	function pac.WearPartFromServer(owner, part_data)
		pac.dprint("received outfit %q from %s with %i number of children to set on %s", part_data.self.Name or "", tostring(owner), table.Count(part_data.children), part_data.self.OwnerName or "")

		for key, part in pairs(pac.GetParts()) do
			if 
				not part:HasParent() and 
				part:GetPlayerOwner() == owner and 
				part.UniqueID == part_data.self.UniqueID and 
				part.ClassName == part_data.self.ClassName 
			then
				pac.dprint("removing part %q to be replaced with the part previously received", part.Name)
				part:Remove()
			end
		end
	
		timer.Simple(0.25, function()
			if not owner:IsValid() then return end
			
			local part = pac.CreatePart(part_data.self.ClassName, owner)
			part:SetTable(part_data)
			part:CheckOwner()
			
			pac.HandleModifiers(part_data, owner)
			
			pac.CallHook("OnWoreOutfit", part, owner == pac.LocalPlayer)
		end)
	end

	function pac.RemovePartFromServer(owner, part_name)
		pac.dprint("%s removed %q", tostring(owner), part_name)

		if part_name == "__ALL__" then					
			for key, part in pairs(pac.GetParts()) do
				if not part:HasParent() and part:GetPlayerOwner() == owner then
					part:Remove()
				end
			end 
			
			pac.HandleModifiers(nil, owner)
		else
			for key, part in pairs(pac.GetParts()) do
				if 
					not part:HasParent() and 
					part:GetPlayerOwner() == owner and 
					part.UniqueID == part_name
				then
					part:Remove()
					break
				end
			end
		end
	end
end

pac.submit_queue = {}

function pac.HandleReceivedData(data)

	if GetConVarNumber("pac_enable") == 0 then
		table.insert(pac.submit_queue, function() pac.HandleReceivedData(data) end)
	end

	if data.owner:IsValid() then
		local T = type(data.part)
		if T == "table" then
			pac.WearPartFromServer(data.owner, data.part)
		elseif T ==  "string" then
			pac.RemovePartFromServer(data.owner, data.part)
		end
	end
end

if pac.netstream then
	pac.netstream.Hook("pac_submit", function(data)
		pac.HandleReceivedData(data)
	end)
else
	net.Receive("pac_submit", function()
		local data = net.ReadTable()
		decimal_hack_unpack(data)
		
		pac.HandleReceivedData(data)
	end)
end

function pac.Notify(allowed, reason, name)
	 if allowed then
		MsgC(Color(255,255,0), "[PAC3] ")
		MsgC(Color(0,255,0), "Your part " .. name .. " has been applied.\n")
	else
		chat.AddText(Color(255,255,0), "[PAC3] ", Color(255,0,0), reason)
	end
end

usermessage.Hook("pac_submit_acknowledged", function(umr)
	local allowed = umr:ReadBool()
	local reason = umr:ReadString()
	local name = umr:ReadString()

	pac.Notify(allowed, reason, name)
end)

hook.Add("KeyRelease", "pac_request_outfits", function()	
	if pac.LocalPlayer:IsValid() and pac.LocalPlayer:GetVelocity():Length() > 5 then
		RunConsoleCommand("pac_request_outfits")
		hook.Remove("KeyRelease", "pac_request_outfits")
	end
end)