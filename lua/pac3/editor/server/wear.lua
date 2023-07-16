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
		tbl.self.UniqueID = pac.Hash(tbl.self.UniqueID .. input)
	end

	for key, val in pairs(tbl.children) do
		make_copy(val, input)
	end
end

local function net_write_table(tbl)

	local buffer = pac.StringStream()
	buffer:writeTable(tbl)

	local data = buffer:getString()
	local ok, err = pcall(net.WriteStream, data)

	if not ok then
		return ok, err
	end

	return #data
end


pace.dupe_ents = pace.dupe_ents or {}

local uid2key = include("legacy_network_dictionary_translate.lua")

local function translate_old_dupe(tableIn, target)
	for key, value2 in pairs(tableIn) do
		local value

		if istable(value2) then
			value = translate_old_dupe(value2, {})
		else
			value = value2
		end

		if isnumber(key) and key > 10000 then
			local str = uid2key[key] or key
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
		parts = translate_old_dupe(parts, {})
	end

	local id = ent:EntIndex()

	if parts.part then
		parts = {[parts.part.self.UniqueID] = parts}
	end

	ent.pac_parts = parts
	pace.dupe_ents[ent:EntIndex()] = {owner = ply, ent = ent}

	-- give source engine time
	timer.Simple(0, function()
		for uid, data in pairs(parts) do
			if istable(data.part) then
				make_copy(data.part, id)

				data.part.self.Name = tostring(ent)
				data.part.self.OwnerName = id
			end

			data.owner = ply
			data.uid = pac.Hash(ply)
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
	if istable(data.part) then
		if last_frame == frame_number then
			table.insert(pace.StreamQueue, {data, filter})
			pace.dprint("queuing part %q from %s", data.part.self.Name, tostring(data.owner))
			return "queue"
		end
	end

	-- last arg "true" is pac3 only in case you need to do your checking differnetly from pac2
	local allowed, reason = hook.Run("PrePACConfigApply", data.owner, data, true)

	if istable(data.part) then
		local ent = Entity(tonumber(data.part.self.OwnerName) or -1)
		if ent:IsValid() then
			if not pace.CanPlayerModify(data.owner, ent) then
				allowed = false
				reason = "you are not allowed to modify this entity: " .. tostring(ent) .. " owned by: " .. tostring(ent.CPPIGetOwner and ent:CPPIGetOwner() or "world")
			else
				if not data.is_dupe then
					ent.pac_parts = ent.pac_parts or {}
					ent.pac_parts[pac.Hash(data.owner)] = data

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
							if istable(data.part) then
								data.part = data.part.self.UniqueID
							end
							pace.RemovePart(data)
						end
					end
				end)
			end
		end
	end

	if data.uid ~= false then
		if allowed == false then return allowed, reason end
		if pace.IsBanned(data.owner) then return false, "you are banned from using pac" end
	end

	local uid = data.uid
	pace.Parts[uid] = pace.Parts[uid] or {}

	if istable(data.part) then
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
						local id = pac.Hash(data.part .. v.ent:EntIndex())
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
	if IsValid(data.temp_wear_filter) and type(data.temp_wear_filter) == "Player" then
		players = {data.temp_wear_filter}
	elseif istable(data.wear_filter) then
		players = {}

		for _, id in ipairs(data.wear_filter) do
			local ply = pac.ReverseHash(id, "Player")
			if ply:IsValid() then
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
			data.player_uid = pac.Hash(data.owner)
		end

		local players = filter or players

		if istable(players) then
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
						if  var == steamid or istable(var) and (table.HasValue(var, steamid) or table.HasValue(var, util.CRC(ply:IPAddress():match("(.+):") or ""))) then
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

		if not players or istable(players) and not next(players) then return true end

		-- Alternative transmission system
		local ret = hook.Run("pac_SendData", players, data)
		if ret == nil then
			net.Start("pac_submit")
			local bytes, err = net_write_table(data)

			if not bytes then
				ErrorNoHalt("[PAC3] Outfit broadcast failed for " .. tostring(data.owner) .. ": " .. tostring(err) .. '\n')

				if data.owner and data.owner:IsValid() then
					data.owner:ChatPrint('[PAC3] ERROR: Could not broadcast your outfit: ' .. tostring(err))
				end
			else
				net.Send(players)
			end
		end

		if istable(data.part) then
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

		if not reason and allowed and istable(data.part) then
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
	data.uid = pac.Hash(ply)

	if data.wear_filter and #data.wear_filter > game.MaxPlayers() then
		pac.Message("Player ", ply, " tried to submit extraordinary wear filter size of ", #data.wear_filter, ", dropping.")
		data.wear_filter = nil
	end

	if istable(data.part) and data.part.self then
		if istable(data.part.self) and not data.part.self.UniqueID then return end -- bogus data

		pac.Message("Received pac group ", data.partID or 0 , "/", data.totalParts or 0, " from ", ply)
		pace.SubmitPartNotify(data)
	elseif isstring(data.part) then
		local clearing = data.part == "__ALL__"

		pac.Message("Clearing ", clearing and "Oufit" or "Part" , " from ", ply)
		pace.RemovePart(data)
	end
end

util.AddNetworkString("pac_submit")

local pac_submit_spam = CreateConVar('pac_submit_spam', '1', {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 'Prevent users from spamming pac_submit')
local pac_submit_limit = CreateConVar('pac_submit_limit', '30', {FCVAR_NOTIFY, FCVAR_ARCHIVE}, 'pac_submit spam limit')

pace.PCallNetReceive(net.Receive, "pac_submit", function(len, ply)
	if len < 64 then return end
	if pac_submit_spam:GetBool() and not game.SinglePlayer() then
		local allowed = pac.RatelimitPlayer( ply, "pac_submit", pac_submit_limit:GetInt(), 5, {"Player ", ply, " is spamming pac_submit!"} )
		if not allowed then return end
	end

	if pac.CallHook("CanWearParts", ply) == false then
		return
	end

	net.ReadStream(ply, function(data)
		if not data then
			pac.Message("message from ", ply, " timed out")
			return
		end
		if not ply:IsValid() then
			pac.Message("received message from ", ply, " but player is no longer valid!")
			return
		end
		local buffer = pac.StringStream(data)
		pace.HandleReceivedData(ply, buffer:readTable())
	end)
end)

function pace.ClearOutfit(ply)
	local uid = pac.Hash(ply)

	pace.SubmitPart({part = "__ALL__", uid = pac.Hash(ply), owner = ply})
	pace.CallHook("RemoveOutfit", ply)
end

function pace.RequestOutfits(ply)
	if not ply:IsValid() then return end

	if ply.pac_requested_outfits_time and ply.pac_requested_outfits_time > RealTime() then return end
	ply.pac_requested_outfits_time = RealTime() + 30
	ply.pac_requested_outfits = true

	ply.pac_gonna_receive_outfits = true

	pace.UpdateWearFilters()

	timer.Simple(6, function()
		if not IsValid(ply) then return end
		ply.pac_gonna_receive_outfits = false

		for id, outfits in pairs(pace.Parts) do
			local owner = pac.ReverseHash(id, "Player")

			if owner:IsValid() and owner:IsPlayer() and owner.GetPos and id ~= pac.Hash(ply) then
				for key, outfit in pairs(outfits) do
					if not outfit.wear_filter or table.HasValue(outfit.wear_filter, pac.Hash(ply)) then
						pace.SubmitPart(outfit, ply)
					end
				end
			end
		end
	end)
end

concommand.Add("pac_request_outfits", pace.RequestOutfits)
