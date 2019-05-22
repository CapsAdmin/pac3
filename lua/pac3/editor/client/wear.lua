
local pac_wear_friends_only = CreateClientConVar("pac_wear_friends_only", "0", true, false, 'Wear outfits only to friends')
local pac_wear_reverse = CreateClientConVar("pac_wear_reverse", "0", true, false, 'Wear to NOBODY but to people from list (Blacklist -> Whitelist)')

do -- to server
	local function assemblePlayerFilter()
		local filter = {}

		if pac_wear_friends_only:GetBool() then
			for i, v in ipairs(player.GetAll()) do
				if v:GetFriendStatus() == "friend" then
					table.insert(filter, tonumber(v:UniqueID()))
				end
			end
		elseif pac_wear_reverse:GetBool() then
			for i, v in ipairs(player.GetAll()) do
				if cookie.GetString('pac3_wear_block_' .. v:UniqueID(), '0') == '1' then
					table.insert(filter, tonumber(v:UniqueID()))
				end
			end
		else
			for i, v in ipairs(player.GetAll()) do
				if cookie.GetString('pac3_wear_block_' .. v:UniqueID(), '0') ~= '1' then
					table.insert(filter, tonumber(v:UniqueID()))
				end
			end
		end

		return filter
	end

	net.Receive('pac_update_playerfilter', function()
		local filter = assemblePlayerFilter()

		net.Start('pac_update_playerfilter')

		if #filter>=256 then error("Filter too large! " .. #filter) end
		net.WriteUInt(#filter, 8)
		for i, id in ipairs(filter) do
			net.WriteUInt(id, 32)
		end

		net.SendToServer()
	end)

	function pace.IsPartSendable(part, extra)
		local allowed, reason = pac.CallHook("CanWearParts", LocalPlayer())

		if allowed == false then
			return false
		end

		if part.ClassName == "group" and not part:HasChildren() then return false end
		if not part.show_in_editor == false then return false end

		return true
	end

	function pace.SendPartToServer(part, extra)
		local allowed, reason = pac.CallHook("CanWearParts", LocalPlayer())

		if allowed == false then
			pac.Message(reason or "the server doesn't want you to wear parts for some reason")
			return false
		end

		-- if it's (ok not very exact) the "my outfit" part without anything added to it, don't bother sending it
		if part.ClassName == "group" and not part:HasChildren() then return false end
		if not part.show_in_editor == false then return false end

		local data = {part = part:ToTable()}

		if extra then
			table.Merge(data, extra)
		end

		data.owner = part:GetPlayerOwner()
		data.wear_filter = assemblePlayerFilter()

		net.Start("pac_submit")

		local bytes, err = pace.net.SerializeTable(data)

		if not bytes then
			pace.Notify(false, "unable to transfer data to server: " .. tostring(err or "too big"), part:GetName())
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
			if ret == nil then
				pace.Notify(false, "unable to transfer data to server: "..tostring(err or "too big"), name)
				return false
			end
		net.SendToServer()

		return true
	end
end

do -- from server
	function pace.WearPartFromServer(owner, part_data, data, doItNow)
		pac.dprint("received outfit %q from %s with %i number of children to set on %s", part_data.self.Name or "", tostring(owner), table.Count(part_data.children), part_data.self.OwnerName or "")

		if pace.CallHook("WearPartFromServer", owner, part_data, data) == false then return end

		local dupepart = pac.GetPartFromUniqueID(data.player_uid, part_data.self.UniqueID)

		if dupepart:IsValid() then
			pac.dprint("removing part %q to be replaced with the part previously received", dupepart.Name)
			dupepart:Remove()
		end

		local dupeEnt

		-- safe guard
		if data.is_dupe then
			local id = tonumber(part_data.self.OwnerName)
			dupeEnt = Entity(id or -1)
			if not dupeEnt:IsValid() then
				return
			end
		end

		local func = function()
			if dupeEnt and not dupeEnt:IsValid() then return end

			dupepart = pac.GetPartFromUniqueID(data.player_uid, part_data.self.UniqueID)

			if dupepart:IsValid() then
				pac.dprint("removing part %q to be replaced with the part previously received ON callback call", dupepart.Name)
				dupepart:Remove()
			end

			local part = pac.CreatePart(part_data.self.ClassName, owner)
			part:SetIsBeingWorn(true)
			part:SetTable(part_data)

			if data.is_dupe then
				part.dupe_remove = true
			end

			part:CallRecursive('SetIsBeingWorn', false)

			if owner == pac.LocalPlayer then
				pace.CallHook("OnWoreOutfit", part)
			end

			part:CallRecursive('OnWorn')
			part:CallRecursive('PostApplyFixes')
		end

		if doItNow then
			func()
		end

		return func
	end

	function pace.RemovePartFromServer(owner, part_name, data)
		pac.dprint("%s removed %q", tostring(owner), part_name)

		if part_name == "__ALL__" then
			pac.RemovePartsFromUniqueID(data.player_uid)

			pace.CallHook("RemoveOutfit", owner)
			pac.CleanupEntityIgnoreBound(owner)
		else
			local part = pac.GetPartFromUniqueID(data.player_uid, part_name)

			if part:IsValid() then
				part:Remove()
			end
		end
	end
end

do
	local pac_onuse_only = CreateClientConVar('pac_onuse_only', '0', true, false, 'Enable "on +use only" mode. Within this mode, outfits are not being actually "loaded" until you hover over player and press your use button')
	local transmissions = {}

	function pace.OnUseOnlyUpdates(cvar, ...)
		hook.Call('pace_OnUseOnlyUpdates', nil, ...)
	end

	cvars.AddChangeCallback("pac_onuse_only", pace.OnUseOnlyUpdates, "PAC3")

	concommand.Add("pac_onuse_reset", function()
		for i, ent in ipairs(ents.GetAll()) do
			if ent.pac_onuse_only then
				ent.pac_onuse_only_check = true

				if pac_onuse_only:GetBool() then
					pac.ToggleIgnoreEntity(ent, ent.pac_onuse_only_check, 'pac_onuse_only')
				else
					pac.ToggleIgnoreEntity(ent, false, 'pac_onuse_only')
				end
			end
		end
	end)

	timer.Create('pac3_transmissions_ttl', 1, 0, function()
		local time = RealTime()

		for transmissionID, data in pairs(transmissions) do
			if data.activity + 10 < time then
				transmissions[transmissionID] = nil
				pac.Message('Marking transmission session with id ', transmissionID, ' as dead. Received ', #data.list, ' out from ', data.total, ' parts.')
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

	local function defaultHandlerNow(data)
		local T = type(data.part)

		if T == "table" then
			pace.WearPartFromServer(data.owner, data.part, data, true)
		elseif T ==  "string" then
			pace.RemovePartFromServer(data.owner, data.part, data)
		else
			ErrorNoHalt("PAC: Unhandled "..T..'!?\n')
		end
	end

	function pace.HandleReceivedData(data)
		if data.owner ~= LocalPlayer() then
			if not data.owner.pac_onuse_only then
				data.owner.pac_onuse_only = true
				-- if TRUE - hide outfit
				data.owner.pac_onuse_only_check = true

				if pac_onuse_only:GetBool() then
					pac.ToggleIgnoreEntity(data.owner, data.owner.pac_onuse_only_check, 'pac_onuse_only')
				else
					pac.ToggleIgnoreEntity(data.owner, false, 'pac_onuse_only')
				end
			end

			-- behaviour of this (if one of entities on this hook becomes invalid)
			-- is undefined if DLib is not installed, but anyway
			hook.Add('pace_OnUseOnlyUpdates', data.owner, function()
				if pac_onuse_only:GetBool() then
					pac.ToggleIgnoreEntity(data.owner, data.owner.pac_onuse_only_check, 'pac_onuse_only')
				else
					pac.ToggleIgnoreEntity(data.owner, false, 'pac_onuse_only')
				end
			end)
		else
			return defaultHandlerNow(data)
		end

		local validTransmission = type(data.partID) == 'number' and
			type(data.totalParts) == 'number' and
			type(data.transmissionID) == 'number'

		if not validTransmission then
			local func = defaultHandler(data)

			if type(func) == 'function' then
				pac.EntityIgnoreBound(data.owner, func)
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

			local transmissionID = data.transmissionID
			data.transmissionID = nil
			data.totalParts = nil
			data.partID = nil
			table.insert(trData.list, data)
			trData.activity = RealTime()

			if #trData.list == trData.total then
				local funcs = {}

				for i, part in ipairs(trData.list) do
					local func = defaultHandler(part)

					if type(func) == 'function' then
						table.insert(funcs, func)
					end
				end

				for i, func in ipairs(funcs) do
					pac.EntityIgnoreBound(data.owner, func)
				end

				transmissions[data.transmissionID or transmissionID] = nil
			end
		end
	end
end

net.Receive("pac_submit", function()
	if not pac.IsEnabled() then return end

	local data = pace.net.DeserializeTable()

	if type(data.owner) ~= "Player" or not data.owner:IsValid() then
		pac.Message("received message from server but owner is not valid!? typeof " .. type(data.owner) .. ' || ', data.owner)
		return
	end

	pace.HandleReceivedData(data)
end)

function pace.Notify(allowed, reason, name)
	name = name or "???"

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
	function pace.LoadUpDefault()
		if next(pac.GetLocalParts()) then
			pac.Message("not wearing autoload outfit, already wearing something")
		elseif pace.IsActive() then
			pac.Message("not wearing autoload outfit, editor is open")
		else
			pac.Message("Wearing autoload...")
			pace.WearParts("autoload")
		end

		pac.RemoveHook("Think", "pac_request_outfits")
		pac.Message("Requesting outfits in 8 seconds...")

		timer.Simple(8, function()
			pac.Message("Requesting outfits...")
			RunConsoleCommand("pac_request_outfits")
		end)
	end

	local function Initialize()
		pac.RemoveHook("KeyRelease", "pac_request_outfits")

		if not pac.LocalPlayer:IsValid() then
			return
		end

		if not pac.IsEnabled() then
			pac.RemoveHook("Think", "pac_request_outfits")
			pace.NeverLoaded = true
			return
		end

		pace.LoadUpDefault()
	end

	hook.Add("pac_Enable", "pac_LoadUpDefault", function()
		if not pace.NeverLoaded then return end
		pace.NeverLoaded = nil
		pace.LoadUpDefault()
	end)

	local frames = 0

	pac.AddHook("Think", "pac_request_outfits", function()
		if RealFrameTime() > 0.2 then -- lag?
			return
		end

		frames = frames + 1

		if frames > 400 then
			Initialize()
		end
	end)

	pac.AddHook("KeyRelease", "pac_request_outfits", function()
		local me = pac.LocalPlayer

		if me:IsValid() and me:GetVelocity():Length() > 50 then
			frames = frames + 200

			if frames > 400 then
				Initialize()
			end
		end
	end)
end



