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
	function pace.SendPartToServer(part)
		
		-- if it's (ok not very exact) the "my outfit" part without anything added to it, don't bother sending it
		if part.ClassName == "group" and not part:HasChildren() then return end
	
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

	function pace.RemovePartOnServer(name, server_only, filter)
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
	function pace.WearPartFromServer(owner, part_data, data)
		pac.dprint("received outfit %q from %s with %i number of children to set on %s", part_data.self.Name or "", tostring(owner), table.Count(part_data.children), part_data.self.OwnerName or "")
				
		local part = pac.GetPartFromUniqueID(data.player_uid, part_data.self.UniqueID)
		
		if part:IsValid() then
			pac.dprint("removing part %q to be replaced with the part previously received", part.Name)
			part:Remove()
		end
		
		timer.Simple(0.25, function()
			if not owner:IsValid() then return end
			
			local part = pac.CreatePart(part_data.self.ClassName, owner)
			
			part:SetTable(part_data)
			
			pac.HandleModifiers(part_data, owner)
			
			pace.CallHook("OnWoreOutfit", part, owner == pac.LocalPlayer)
		end)
	end

	function pace.RemovePartFromServer(owner, part_name, data)
		pac.dprint("%s removed %q", tostring(owner), part_name)

		if part_name == "__ALL__" then					
			for key, part in pairs(pac.GetPartsFromUniqueID(data.player_uid)) do
				if not part:HasParent() then
					part:Remove()
				end
			end 
			
			pac.HandleModifiers(nil, owner)
		else
			local part = pac.GetPartFromUniqueID(data.player_uid, part_name)
			
			if part:IsValid() then
				part:Remove()
			end
		end
	end
end

do
	local function go(data)
		local T = type(data.part)
		if T == "table" then
			pace.WearPartFromServer(data.owner, data.part, data)
		elseif T ==  "string" then
			pace.RemovePartFromServer(data.owner, data.part, data)
		end
	end

	local queue = {}

	timer.Create("pac_wear_queue", 1, 0, function()
		for uid, queue in pairs(queue) do
			local ply = player.GetByUniqueID(uid) or NULL			
			
			if ply:IsValid() then
				
				--if ply:IsPlayer() and (not ply.pac_last_drawn or (ply.pac_last_drawn + 0.25) < pac.RealTime) then continue end
				
				for k,v in pairs(queue) do
					go(v)
					queue[k] = nil
				end
			end
		end
	end)

	function pace.HandleReceivedData(data)		
		queue[data.player_uid] = queue[data.player_uid] or {}
		table.insert(queue[data.player_uid], data)
	end
end

if pac.netstream then
	pac.netstream.Hook("pac_submit", function(data)
		pace.HandleReceivedData(data)
	end)
else
	net.Receive("pac_submit", function()
		local data = net.ReadTable()
		decimal_hack_unpack(data)
		
		pace.HandleReceivedData(data)
	end)
end

function pace.Notify(allowed, reason, name)
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

	pace.Notify(allowed, reason, name)
end)

do -- python 1320
	local t=0
	local function Initialize()
		
		if not pac.LocalPlayer:IsValid() then return end
		
		t = false
		hook.Remove("Think","pac_request_outfits")
		hook.Remove("KeyRelease", "pac_request_outfits")
		
		Msg"[PAC3] " print"Requesting outfits..."
		
		RunConsoleCommand("pac_request_outfits")

	end

	hook.Add("Think","pac_request_outfits",function() 
		
		local ft = FrameTime()
		
		-- ignore long frames...
		ft=ft<0 and 0 or ft>0.2 and 0.2 or ft
		
		t=t+ft
		
		if t>120 then
			Initialize()
			return
		end
		
	end)

	hook.Add("KeyRelease", "pac_request_outfits", function()	
		if pac.LocalPlayer:IsValid() and pac.LocalPlayer:GetVelocity():Length() > 5 then
			Initialize()
		end
	end)
end