local next = next
local type = type
local istable = istable
local IsValid = IsValid
local tostring = tostring
local isfunction = isfunction
local ProtectedCall = ProtectedCall

pace.StreamQueue = pace.StreamQueue or {}

timer.Create("pac_check_stream_queue", 0.1, 0, function()
	local item = table.remove(pace.StreamQueue)
	if not item then return end

	local data = item.data
	local filter = item.filter
	local callback = item.callback

	local allowed, reason
	local function submitPart()
		allowed, reason = pace.SubmitPartNow(data, filter)
	end

	local success = ProtectedCall(submitPart)

	if not isfunction(callback) then return end

	if not success then
		allowed = false
		reason = "Unexpected Error"
	end

	ProtectedCall(function()
		callback(allowed, reason)
	end)
end)

local function make_copy(tbl, input)
	if tbl.self.UniqueID then
		tbl.self.UniqueID = pac.Hash(tbl.self.UniqueID .. input)
	end

	for _, val in pairs(tbl.children) do
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

local uid2key = include("pac3/editor/server/legacy_network_dictionary_translate.lua")

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
		for _, data in pairs(parts) do
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

function pace.SubmitPartNow(data, filter)
	local part = data.part
	local owner = data.owner

	-- last arg "true" is pac3 only in case you need to do your checking differently from pac2
	local allowed, reason = hook.Run("PrePACConfigApply", owner, data, true)
	if allowed == false then return allowed, reason end

	local uid = data.uid
	if uid ~= false and pace.IsBanned(owner) then
		return false, "you are banned from using pac"
	end

	if istable(part) then
		local ent = Entity(tonumber(part.self.OwnerName) or -1)

		if ent:IsValid() then
			if not pace.CanPlayerModify(owner, ent) then
				local entOwner = ent.CPPIGetOwner and ent:CPPIGetOwner()
				entOwner = tostring(entOwner or "world")

				return false, "you are not allowed to modify this entity: " .. tostring(ent) .. " owned by: " .. entOwner
			else
				if not data.is_dupe then
					ent.pac_parts = ent.pac_parts or {}
					ent.pac_parts[pac.Hash(owner)] = data

					pace.dupe_ents[ent:EntIndex()] = {owner = owner, ent = ent}

					duplicator.ClearEntityModifier(ent, "pac_config")
					-- fresh table copy
					duplicator.StoreEntityModifier(ent, "pac_config", {json = util.TableToJSON(table.Copy(ent.pac_parts))})
				end

				ent:CallOnRemove("pac_config", function(e)
					if e.pac_parts then
						for _, eData in pairs(e.pac_parts) do
							if istable(eData.part) then
								eData.part = eData.part.self.UniqueID
							end
							pace.RemovePart(eData)
						end
					end
				end)
			end
		end
	end

	pace.Parts[uid] = pace.Parts[uid] or {}

	if istable(part) then
		pace.Parts[uid][part.self.UniqueID] = data
	else
		if part == "__ALL__" then
			pace.Parts[uid] = {}
			filter = true

			for key, v in pairs(pace.dupe_ents) do
				if v.owner:IsValid() and v.owner == owner then
					if v.ent:IsValid() and v.ent.pac_parts then
						v.ent.pac_parts = nil
						duplicator.ClearEntityModifier(v.ent, "pac_config")
					end
				end

				pace.dupe_ents[key] = nil
			end
		elseif part then
			pace.Parts[uid][part] = nil
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
		filter = owner
	elseif filter == true then
		local tbl = {}

		for _, v in pairs(players) do
			if v ~= owner then
				table.insert(tbl, v)
			end
		end

		filter = tbl
	end

	if not data.server_only then
		if owner:IsValid() then
			data.player_uid = pac.Hash(owner)
		end

		players = filter or players

		if istable(players) then
			for key = #players, 1, -1 do
				local ply = players[key]
				if not ply.pac_requested_outfits and ply ~= owner then
					table.remove(players, key)
				end
			end

			if pace.GlobalBans and owner:IsValid() then
				local owner_steamid = owner:SteamID()

				for key, ply in pairs(players) do
					local steamid = ply:SteamID()

					for var in pairs(pace.GlobalBans) do
						if var == steamid or istable(var) and (table.HasValue(var, steamid) or table.HasValue(var, util.CRC(ply:IPAddress():match("(.+):") or ""))) then
							table.remove(players, key)

							if owner_steamid == steamid then
								pac.Message("Dropping data transfer request by '", ply:Nick(), "' due to a global PAC ban.")
								return false, "You have been globally banned from using PAC. See global_bans.lua for more info."
							end
						end
					end
				end
			end
		elseif type(players) == "Player" and (not players.pac_requested_outfits and players ~= owner) then
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
				local errStr = tostring(err)
				ErrorNoHalt("[PAC3] Outfit broadcast failed for " .. tostring(owner) .. ": " .. errStr .. '\n')

				if owner and owner:IsValid() then
					owner:ChatPrint('[PAC3] ERROR: Could not broadcast your outfit: ' .. errStr)
				end
			else
				net.Send(players)
			end
		end

		if istable(part) then
			pace.CallHook("OnWoreOutfit", owner, part)
		end
	end

	-- nullify transmission ID
	data.transmissionID = nil

	return true
end

-- Inserts the given part into the StreamQueue
function pace.SubmitPart(data, filter, callback)
	if istable(data.part) then
		pac.dprint("queuing part %q from %s", data.part.self.Name, tostring(data.owner))
		table.insert(pace.StreamQueue, {
			data = data,
			filter = filter,
			callback = callback
		})

		return "queue"
	end

	return pace.SubmitPartNow(data, filter)
end

-- Inserts the given part into the StreamQueue, and notifies when it completes
function pace.SubmitPartNotify(data)
	local part = data.part
	local partName = part.self.Name or "no name"

	pac.dprint("submitted outfit %q from %s with %i children to set on %s", partName, data.owner:GetName(), table.Count(part.children), part.self.OwnerName or "")

	local function callback(allowed, reason)
		if allowed == "queue" then return end
		if not data.owner:IsPlayer() then return end

		reason = reason or ""

		if not reason and allowed and istable(part) then
			reason = string.format("Your part %q has been applied", partName or "<unknown>")
		end

		net.Start("pac_submit_acknowledged")
			net.WriteBool(allowed)
			net.WriteString(reason)
			net.WriteString(partName)
		net.Send(data.owner)

		hook.Run("PACSubmitAcknowledged", data.owner, not not allowed, reason, partName, data)
	end

	pace.SubmitPart(data, nil, callback)
end

function pace.RemovePart(data)
	local part = data.part
	local owner = data.owner
	pac.dprint("%s is removed %q", owner and owner:IsValid() and owner:GetName(), part)

	if part == "__ALL__" then
		pace.CallHook("RemoveOutfit", owner)
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
