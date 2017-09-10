do -- to server
	function pace.SendPartToServer(part)

		-- if it's (ok not very exact) the "my outfit" part without anything added to it, don't bother sending it
		if part.ClassName == "group" and not part:HasChildren() then return end
		if not part.show_in_editor == false then return end

		local data = {part = part:ToTable()}
		data.owner = part:GetOwner()

		net.Start("pac_submit")

			local ret,err = pace.net.SerializeTable(data)
			if ret==nil then
				pace.Notify(false,"unable to transfer data to server: "..tostring(err or "too big"))
				return false
			end

		net.SendToServer()

		pac.Message("Transmitting outfit ("..string.NiceSize(ret)..')')

		return true

	end

	function pace.RemovePartOnServer(name, server_only, filter)
		local data = {part = name, server_only = server_only, filter = filter}

		if name == "__ALL__" then
			pace.CallHook("RemoveOutfit", LocalPlayer())
		end

		net.Start("pac_submit")
			local ret,err = pace.net.SerializeTable(data)
			if ret==nil then
				pace.Notify(false,"unable to transfer data to server: "..tostring(err or "too big"))
				return false
			end
		net.SendToServer()

		return true

	end
end

do -- from server
	function pace.WearPartFromServer(owner, part_data, data)
		pac.dprint("received outfit %q from %s with %i number of children to set on %s", part_data.self.Name or "", tostring(owner), table.Count(part_data.children), part_data.self.OwnerName or "")

		if pace.CallHook("WearPartFromServer",owner, part_data, data)==false then return end

		local part = pac.GetPartFromUniqueID(data.player_uid, part_data.self.UniqueID)

		if part:IsValid() then
			pac.dprint("removing part %q to be replaced with the part previously received", part.Name)
			part:Remove()
		end

		-- safe guard
		if data.is_dupe then
			local id = tonumber(part_data.self.OwnerName)
			if id and not Entity(id):IsValid() then
				return
			end
		end

		local part = pac.CreatePart(part_data.self.ClassName, owner)
		part:SetTable(part_data)

		if data.is_dupe then
			part.dupe_remove = true
		end

		pace.CallHook("OnWoreOutfit", part, owner == pac.LocalPlayer)
		pace.CallHook("WearOutfit", owner, part) -- ugh
	end

	function pace.RemovePartFromServer(owner, part_name, data)
		pac.dprint("%s removed %q", tostring(owner), part_name)

		if part_name == "__ALL__" then
			for key, part in pairs(pac.GetPartsFromUniqueID(data.player_uid)) do
				if not part:HasParent() then
					part:Remove()
				end
			end

			pace.CallHook("RemoveOutfit", owner)
		else
			local part = pac.GetPartFromUniqueID(data.player_uid, part_name)

			if part:IsValid() then
				part:Remove()
			end
		end
	end
end

do
	function pace.HandleReceivedData(data)
		local T = type(data.part)
		if T == "table" then
			pace.WearPartFromServer(data.owner, data.part, data)
		elseif T ==  "string" then
			pace.RemovePartFromServer(data.owner, data.part, data)
		else
			ErrorNoHalt("PAC: Unhandled "..T..'!?\n')
		end
	end
end


net.Receive("pac_submit", function()
	local data = pace.net.DeserializeTable()

	pace.HandleReceivedData(data)
end)




function pace.Notify(allowed, reason, name)
	 if allowed then
		pac.Message("Your part " .. name .. " has been applied.")
	else
		chat.AddText(Color(255,255,0), "[PAC3] ", Color(255,0,0), reason)
	end
end

net.Receive("pac_submit_acknowledged", function(umr)
	local allowed = net.ReadBool()
	local reason = net.ReadString()
	local name = net.ReadString()

	pace.Notify(allowed, reason, name)
end)


do
	local t=0
	local max_time = 123 -- timeout in seconds
	local removed_req = false
	local function Initialize()

		if not pac.LocalPlayer:IsValid() then
			return
		end

		t = false

		if not removed_req then
			hook.Remove("KeyRelease", "pac_request_outfits")
			removed_req = true
		end


		if not pac.IsEnabled() then
			-- check every 2 seconds, ugly hack
			t = max_time - 2
			return
		end

		hook.Remove("Think","pac_request_outfits")
		pac.Message("Requesting outfits...")

		RunConsoleCommand("pac_request_outfits")

	end

	hook.Add("Think","pac_request_outfits",function()

		local ft = FrameTime()

		-- ignore long frames...
		ft=ft<0 and 0 or ft>0.2 and 0.2 or ft

		t=t+ft

		if t>max_time then
			Initialize()
			return
		end

	end)

	hook.Add("KeyRelease", "pac_request_outfits", function()
		local me = pac.LocalPlayer
		if me:IsValid() and me:GetVelocity():Length() > 5 then
			Initialize()
		end
	end)
end



