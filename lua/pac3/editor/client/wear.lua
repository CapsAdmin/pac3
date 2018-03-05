
local pac_wear_friends_only = CreateClientConVar("pac_wear_friends_only", "0", true, false, 'Wear outfits only to friends')
local pac_wear_reverse = CreateClientConVar("pac_wear_reverse", "0", true, false, 'Wear to NOBODY but to people from list (Blacklist -> Whitelist)')

do -- to server
	local count = -1

	local function assemblePlayerFilter()
		local filter = {}

		if pac_wear_friends_only:GetBool() then
			for i, v in ipairs(player.GetAll()) do
				if v:GetFriendStatus() == "friend" then
					table.insert(filter, v:UniqueID())
				end
			end
		elseif pac_wear_reverse:GetBool() then
			for i, v in ipairs(player.GetAll()) do
				if cookie.GetString('pac3_wear_block_' .. v:UniqueID(), '0') == '1' then
					table.insert(filter, v:UniqueID())
				end
			end
		else
			for i, v in ipairs(player.GetAll()) do
				if cookie.GetString('pac3_wear_block_' .. v:UniqueID(), '0') ~= '1' then
					table.insert(filter, v:UniqueID())
				end
			end
		end

		return filter
	end

	local function updatePlayerList()
		if player.GetCount() == count then return end
		count = player.GetCount()
		local filter = assemblePlayerFilter()

		net.Start('pac_update_playerfilter')

		for i, id in ipairs(filter) do
			net.WriteUInt(tonumber(id), 32)
		end

		net.WriteUInt(0, 32)
		net.SendToServer()
	end

	timer.Create('pac_update_playerfilter', 5, 0, updatePlayerList)

	function pace.SendPartToServer(part, extra)
		-- if it's (ok not very exact) the "my outfit" part without anything added to it, don't bother sending it
		if part.ClassName == "group" and not part:HasChildren() then return end
		if not part.show_in_editor == false then return end

		local data = {part = part:ToTable()}

		if extra then
			table.Merge(data, extra)
		end

		data.owner = part:GetOwner()
		data.wear_filter = assemblePlayerFilter()

		net.Start("pac_submit")

		local bytes, err = pace.net.SerializeTable(data)

		if not bytes then
			pace.Notify(false, "unable to transfer data to server: " .. tostring(err or "too big"))
			return false
		end

		net.SendToServer()
		pac.Message(('Transmitting outfit %q to server (%s)'):format(part.Name or part.ClassName or '<unknown>', string.NiceSize(bytes)))

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

		if pace.CallHook("WearPartFromServer", owner, part_data, data) == false then return end

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
		part:SetIsBeingWorn(true)
		part:SetTable(part_data)

		if data.is_dupe then
			part.dupe_remove = true
		end

		return function()
			part:CallRecursive('SetIsBeingWorn', false)

			if owner == pac.LocalPlayer then
				pace.CallHook("OnWoreOutfit", part)
			end

			part:CallRecursive('OnWorn')
		end
	end

	function pace.RemovePartFromServer(owner, part_name, data)
		pac.dprint("%s removed %q", tostring(owner), part_name)

		if part_name == "__ALL__" then
			pac.RemovePartsFromUniqueID(data.player_uid)

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
	local transmissions = {}

	timer.Create('pac3_transmissions_ttl', 10, 0, function()
		local time = RealTime()

		for transmissionID, data in pairs(transmissions) do
			if data.activity + 60 < time then
				transmissions[transmissionID] = nil
				pac.Message('Marking transmission session with id ', transmissionID, ' as dead, cleaning up... Dropped ', data.total, ' parts')
			end
		end
	end)

	local function defaultHandler(data)
		local T = type(data.part)

		if T == "table" then
			return pace.WearPartFromServer(data.owner, data.part, data)
		elseif T ==  "string" then
			return pace.RemovePartFromServer(data.owner, data.part, data)
		else
			ErrorNoHalt("PAC: Unhandled "..T..'!?\n')
		end
	end

	function pace.HandleReceivedData(data)
		local validTransmission = type(data.partID) == 'number' and
			type(data.totalParts) == 'number' and
			type(data.transmissionID) == 'number'

		if not validTransmission then
			local func = defaultHandler(data)

			if type(func) == 'function' then
				func()
			end
		else
			local trData = transmissions[data.transmissionID]

			if not trData then
				trData = {
					id = data.transmissionID,
					total = data.totalParts,
					list = {},
					activity = RealTime()
				}

				transmissions[data.transmissionID] = trData
			end

			data.transmissionID = nil
			data.totalParts = nil
			data.partID = nil
			table.insert(trData.list, data)
			-- trData.activity = RealTime()

			if #trData.list == trData.total then
				local funcs = {}

				for i, part in ipairs(trData.list) do
					local func = defaultHandler(part)

					if type(func) == 'function' then
						table.insert(funcs, func)
					end
				end

				for i, func in ipairs(funcs) do
					func()
				end

				transmissions[data.transmissionID] = nil
			end
		end
	end
end

net.Receive("pac_submit", function()
	local data = pace.net.DeserializeTable()

	if type(data.owner) ~= "Player" or not data.owner:IsValid() then
		pac.Message("received message from server but owner is not valid!?")
		return
	end

	pace.HandleReceivedData(data)
end)

function pace.Notify(allowed, reason, name)
	 if allowed == true then
		pac.Message(string.format('Your part %q has been applied', name))
	else
		chat.AddText(Color(255, 255, 0), "[PAC3] ", Color(255, 0, 0), string.format('The server rejected applying your part (%q) - %s', name, reason))
	end
end

net.Receive("pac_submit_acknowledged", function(umr)
	pace.Notify(net.ReadBool(), net.ReadString(), net.ReadString())
end)

do
	local t = 0
	local max_time = 123 -- timeout in seconds

	local function Initialize()
		if not pac.LocalPlayer:IsValid() then
			return
		end

		t = false

		if not pac.IsEnabled() then
			-- check every 2 seconds, ugly hack
			t = max_time - 2
			return
		end

		if next(pac.GetLocalParts()) then
			pac.Message("not wearing autoload outfit, already wearing something")
		elseif pace.IsActive() then
			pac.Message("not wearing autoload outfit, editor is open")
		else
			pace.WearParts("autoload")
		end

		pac.RemoveHook("Think", "pac_request_outfits")
		pac.RemoveHook("KeyRelease", "pac_request_outfits")
		pac.Message("Requesting outfits...")

		RunConsoleCommand("pac_request_outfits")
	end

	pac.AddHook("Think", "pac_request_outfits", function()
		if not t then
			pac.RemoveHook("Think", "pac_request_outfits")
			return
		end

		local ft = FrameTime()

		-- ignore long frames...
		ft = ft < 0 and 0 or ft > 0.2 and 0.2 or ft

		t = t + ft

		if t > max_time then
			Initialize()
			return
		end
	end)

	pac.AddHook("KeyRelease", "pac_request_outfits", function()
		local me = pac.LocalPlayer

		if me:IsValid() and me:GetVelocity():Length() > 5 then
			Initialize()
		end
	end)
end



