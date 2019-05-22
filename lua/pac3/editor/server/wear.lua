pace.StreamQueue = pace.StreamQueue or {}

local frame_number = 0
local last_frame
local ERROR_COLOR = Color(228, 37, 37)

local function catchError(err)
	pac.Message(ERROR_COLOR, 'Error: ', err)
	pac.Message(debug.traceback())
end

timer.Create("pac_check_stream_queue", 0.1, 0, function()
	if not pace.BusyStreaming and #pace.StreamQueue ~= 0 then
		xpcall(pace.SubmitPart, catchError, unpack(table.remove(pace.StreamQueue)))
	end

	frame_number = frame_number + 1
end)

local function make_copy(tbl, input)
	if tbl.self.UniqueID then
		tbl.self.UniqueID = util.CRC(tbl.self.UniqueID .. input)
	end

	for key, val in pairs(tbl.children) do
		make_copy(val, input)
	end
end

pace.dupe_ents = pace.dupe_ents or {}

local function fixSanity(tableIn, target)
	for key, value2 in pairs(tableIn) do
		local value

		if type(value2) == 'table' then
			value = fixSanity(value2, {})
		else
			value = value2
		end

		if type(key) == 'number' and key > 10000 then
			local str = tostring(key)
			target[str] = value
		else
			target[key] = value
		end
	end

	return target
end

duplicator.RegisterEntityModifier("pac_config", function(ply, ent, parts)
	if parts.json then
		parts = util.JSONToTable(parts.json)

		-- sanity police for json's __index accesses
		parts = fixSanity(parts, {})
	end

	pace.net.SimulateTableReceive(parts)

	local id = ent:EntIndex()

	if parts.part then
		parts = {[parts.part.self.UniqueID] = parts}
	end

	ent.pac_parts = parts
	pace.dupe_ents[ent:EntIndex()] = {owner = ply, ent = ent}

	-- give source engine time
	timer.Simple(0.5, function()
		for uid, data in pairs(parts) do
			if type(data.part) == "table" then
				make_copy(data.part, id)

				data.part.self.Name = tostring(ent)
				data.part.self.OwnerName = id
			end

			data.owner = ply
			data.uid = ply:UniqueID()
			data.is_dupe = true

			-- clientside sent variables cleanup for sanity
			data.wear_filter = nil
			data.partID = nil
			data.totalParts = nil
			data.transmissionID = nil

			pace.SubmitPart(data)
		end
	end)
end)

function pace.SubmitPart(data, filter)
	if type(data.part) == "table" then
		if last_frame == frame_number then
			table.insert(pace.StreamQueue, {data, filter})
			pace.dprint("queuing part %q from %s", data.part.self.Name, tostring(data.owner))
			return "queue"
		end
	end

	-- last arg "true" is pac3 only in case you need to do your checking differnetly from pac2
	local allowed, reason = hook.Run("PrePACConfigApply", data.owner, data, true)

	if type(data.part) == "table" then
		local ent = Entity(tonumber(data.part.self.OwnerName) or -1)
		if ent:IsValid() then
			if ent.CPPICanTool and (ent:CPPIGetOwner() ~= data.owner and data.owner:IsValid() and not ent:CPPICanTool(data.owner, "paint")) then
				allowed = false
				reason = "you are not allowed to modify this entity: " .. tostring(ent) .. " owned by: " .. tostring(ent:CPPIGetOwner())
			elseif not data.is_dupe then
				ent.pac_parts = ent.pac_parts or {}
				ent.pac_parts[data.part.self.UniqueID] = data

				pace.dupe_ents[ent:EntIndex()] = {owner = data.owner, ent = ent}

				duplicator.ClearEntityModifier(ent, "pac_config")
				--duplicator.StoreEntityModifier(ent, "pac_config", ent.pac_parts)
				--duplicator.StoreEntityModifier(ent, "pac_config", {json = util.TableToJSON(ent.pac_parts)})
				-- fresh table copy
				duplicator.StoreEntityModifier(ent, "pac_config", {json = util.TableToJSON(table.Copy(ent.pac_parts))})
			end

			ent:CallOnRemove("pac_config", function(ent)
				if ent.pac_parts then
					for _, data in pairs(ent.pac_parts) do
						if type(data.part) == "table" then
							data.part = data.part.self.UniqueID
						end
						data.is_dupe = true
						pace.RemovePart(data)
					end
				end
			end)
		end
	end

	if data.uid ~= false then
		if allowed == false then return allowed, reason end
		if pace.IsBanned(data.owner) then return false, "you are banned from using pac" end
	end

	local uid = data.uid
	pace.Parts[uid] = pace.Parts[uid] or {}

	if type(data.part) == "table" then
		pace.Parts[uid][data.part.self.UniqueID] = data
	else
		if data.part == "__ALL__" then
			pace.Parts[uid] = {}
			filter = true

			for key, v in pairs(pace.dupe_ents) do
				if v.owner:IsValid() and v.owner == data.owner then
					if v.ent:IsValid() and v.ent.pac_parts then
						v.ent.pac_parts = nil
						duplicator.ClearEntityModifier(v.ent, "pac_config")
					end
				end

				pace.dupe_ents[key] = nil
			end
		elseif data.part then
			pace.Parts[uid][data.part] = nil

			-- this doesn't work because the unique id is different for some reason
			-- use clear for now if you wanna clear a dupes outfit
			--[[for key, v in pairs(pace.dupe_ents) do
				if v.owner:IsValid() and v.owner == data.owner then
					if v.ent:IsValid() and v.ent.pac_parts then
						local id = util.CRC(data.part .. v.ent:EntIndex())
						v.ent.pac_parts[id] = nil
						duplicator.ClearEntityModifier(v.ent, "pac_config")
						duplicator.StoreEntityModifier(v.ent, "pac_config", v.ent.pac_parts)
						return
					else
						pace.dupe_ents[key] = nil
					end
				else
					pace.dupe_ents[key] = nil
				end
			end]]
		end
	end

	local players

	if type(data.wear_filter) == 'table' then
		players = {}

		local lookup = {}

		for i, ply in ipairs(player.GetAll()) do
			lookup[ply:UniqueID()] = ply
		end

		for i, v in ipairs(data.wear_filter) do
			local ply = lookup[tostring(v)]

			if IsValid(ply) then
				table.insert(players, ply)
			end
		end
	else
		players = player.GetAll()
	end

	if filter == false then
		filter = data.owner
	elseif filter == true then
		local tbl = {}

		for k, v in pairs(players) do
			if v ~= data.owner then
				table.insert(tbl, v)
			end
		end

		filter = tbl
	end

	if not data.server_only then
		if data.owner:IsValid() then
			data.player_uid = data.owner:UniqueID()
		end

		local players = filter or players

		if type(players) == "table" then
			for key = #players, 1, -1 do
				local ply = players[key]
				if not ply.pac_requested_outfits and ply ~= data.owner then
					table.remove(players, key)
				end
			end

			if pace.GlobalBans and data.owner:IsValid() then
				local owner_steamid = data.owner:SteamID()
				for key, ply in pairs(players) do
					local steamid = ply:SteamID()
					for var, reason in pairs(pace.GlobalBans) do
						if  var == steamid or type(var) == "table" and (table.HasValue(var, steamid) or table.HasValue(var, util.CRC(ply:IPAddress():match("(.+):") or ""))) then
							table.remove(players, key)

							if owner_steamid == steamid then
								pac.Message("Dropping data transfer request by '", ply:Nick(), "' due to a global PAC ban.")
								return false, "You have been globally banned from using PAC. See global_bans.lua for more info."
							end
						end
					end
				end
			end
		elseif type(players) == "Player" and (not players.pac_requested_outfits and players ~= data.owner) then
			data.transmissionID = nil
			return true
		end

		if not players or type(players) == "table" and not next(players) then return true end

		-- Alternative transmission system
		local ret = hook.Run("pac_SendData", players, data)
		if ret == nil then
			net.Start("pac_submit")
			local bytes, err = pace.net.SerializeTable(data)

			if not bytes then
				ErrorNoHalt("[PAC3] Outfit broadcast failed for " .. tostring(data.owner) .. ": " .. tostring(err) .. '\n')

				if data.owner and data.owner:IsValid() then
					data.owner:ChatPrint('[PAC3] ERROR: Could not broadcast your outfit: ' .. tostring(err))
				end
			else
				net.Send(players)
			end
		end

		if type(data.part) == "table" then
			last_frame = frame_number
			pace.CallHook("OnWoreOutfit", data.owner, data.part)
		end
	end

	-- nullify transmission ID
	data.transmissionID = nil

	return true
end

function pace.SubmitPartNotify(data)
	pace.dprint("submitted outfit %q from %s with %i number of children to set on %s", data.part.self.Name or "", data.owner:GetName(), table.Count(data.part.children), data.part.self.OwnerName or "")

	local allowed, reason = pace.SubmitPart(data)

	if data.owner:IsPlayer() then
		if allowed == "queue" then return end

		if not reason and allowed and type(data.part) == 'table' then
			reason = string.format('Your part %q has been applied', data.part.self.Name or '<unknown>')
		end

		net.Start("pac_submit_acknowledged")
			net.WriteBool(allowed)
			net.WriteString(reason or "")
			net.WriteString(data.part.self.Name or "no name")
		net.Send(data.owner)

		hook.Run("PACSubmitAcknowledged", data.owner, util.tobool(allowed), reason or "", data.part.self.Name or "no name", data)
	end
end

function pace.RemovePart(data)
	pace.dprint("%s is removed %q", data.owner and data.owner:IsValid() and data.owner:GetName(), data.part)

	if data.part == "__ALL__" then
		pace.CallHook("RemoveOutfit", data.owner)
	end

	pace.SubmitPart(data, data.filter)
end

function pace.HandleReceivedData(ply, data)
	data.owner = ply
	data.uid = ply:UniqueID()

	if type(data.part) == "table" and data.part.self then
		if type(data.part.self) == "table" and not data.part.self.UniqueID then return end -- bogus data

		pace.SubmitPartNotify(data)
	elseif type(data.part) == "string" then
		pace.RemovePart(data)
	end
end

util.AddNetworkString("pac_submit")

timer.Create("pac_submit_spam", 3, 0, function()
	for k, ply in ipairs(player.GetAll()) do
		ply.pac_submit_spam = math.max((ply.pac_submit_spam or 0) - 5, 0)
		ply.pac_submit_spam2 = math.max((ply.pac_submit_spam2 or 0) - 5, 0)

		if ply.pac_submit_spam_msg then
			ply.pac_submit_spam_msg = ply.pac_submit_spam >= 20
		end

		if ply.pac_submit_spam_msg2 then
			ply.pac_submit_spam_msg2 = ply.pac_submit_spam2 >= 20
		end
	end
end)

local pac_submit_spam = CreateConVar('pac_submit_spam', '1', {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 'Prevent users from spamming pac_submit')
local pac_submit_limit = CreateConVar('pac_submit_limit', '30', {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 'pac_submit spam limit')

pace.PCallNetReceive(net.Receive, "pac_submit", function(len, ply)
	if pac.CallHook("CanWearParts", ply) == false then
		return
	end

	if pac_submit_spam:GetBool() then
		-- data is too short, not even 8 bytes
		if len < 64 then return end

		ply.pac_submit_spam = ply.pac_submit_spam + 1

		if ply.pac_submit_spam >= pac_submit_limit:GetInt() then
			if not ply.pac_submit_spam_msg then
				pac.Message("Player ", ply, " is spamming pac_submit!")
				ply.pac_submit_spam_msg = true
			end

			return
		end
	end

	local data = pace.net.DeserializeTable()
	pace.HandleReceivedData(ply, data)
end)

function pace.ClearOutfit(ply)
	local uid = ply:UniqueID()

	pace.SubmitPart({part = "__ALL__", uid = ply:UniqueID(), owner = ply})
	pace.CallHook("RemoveOutfit", ply)
end

function pace.RequestOutfits(ply)
	if not ply:IsValid() then return end

	if ply.pac_requested_outfits_time and ply.pac_requested_outfits_time > RealTime() then return end
	ply.pac_requested_outfits_time = RealTime() + 30
	ply.pac_requested_outfits = true

	ply.pac_gonna_receive_outfits = true

	net.Start('pac_update_playerfilter')
	net.Broadcast()

	timer.Simple(6, function()
		if not IsValid(ply) then return end
		ply.pac_gonna_receive_outfits = false

		for id, outfits in pairs(pace.Parts) do
			local owner = player.GetByUniqueID(id) or NULL

			if owner:IsValid() and owner:IsPlayer() and owner.GetPos and id ~= ply:UniqueID() then
				for key, outfit in pairs(outfits) do
					if not outfit.wear_filter or table.HasValue(outfit.wear_filter, tonumber(ply:UniqueID())) then
						pace.SubmitPart(outfit, ply)
					end
				end
			end
		end
	end)
end

local function qhasvalue(tab, value)
	for i, val in ipairs(tab) do
		if val == value then
			return true
		end
	end

	return false
end

local function pac_update_playerfilter(len, ply)
	if not IsValid(ply) then return end

	if pac_submit_spam:GetBool() then
		if player.GetCount() > 4 and len < 16 then return end

		ply.pac_submit_spam2 = ply.pac_submit_spam2 + 1

		if ply.pac_submit_spam2 >= pac_submit_limit:GetInt() / 2 then
			if not ply.pac_submit_spam_msg2 then
				pac.Message("Player ", ply, " is spamming pac_update_playerfilter!")
				ply.pac_submit_spam_msg2 = true
			end

			return
		end
	end

	local filter = {}
	local filterCount = net.ReadUInt(8)
	for i=1, filterCount do
		table.insert(filter, net.ReadUInt(32))
	end

	local players = {}

	for i, ply in ipairs(player.GetAll()) do
		players[ply:UniqueID()] = ply
	end

	for id, outfits in pairs(pace.Parts) do
		local owner = player.GetByUniqueID(id) or NULL

		if owner == ply then
			for key, outfit in pairs(outfits) do
				if outfit.wear_filter then
					for i, plyID in ipairs(filter) do
						if not qhasvalue(outfit.wear_filter, plyID) then
							local getPly = players[tostring(plyID)]

							if getPly and getPly.pac_requested_outfits and not getPly.pac_gonna_receive_outfits then
								pace.SubmitPart(outfit, getPly)
							end
						end
					end
				end

				outfit.wear_filter = filter
			end
		end
	end
end

concommand.Add("pac_request_outfits", pace.RequestOutfits)
net.Receive('pac_update_playerfilter', pac_update_playerfilter)
