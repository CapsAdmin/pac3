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

pace.StreamQueue = pace.StreamQueue or {}

local frame_number = 0

timer.Create("pac_check_stream_queue", 0.1, 0, function()
	if not pace.BusyStreaming and #pace.StreamQueue ~= 0 then
		pace.SubmitPart(unpack(table.remove(pace.StreamQueue)))
	end
	frame_number = frame_number + 1
end)


local function make_copy(tbl, input)
	for key, val in pairs(tbl.self) do
		if key == "ClassName" then continue end
				
		if key:find("UID", 0, true) or key == "UniqueID" then
			tbl.self[key] = util.CRC(val .. input)
		end
	end
	for key, val in pairs(tbl.children) do
		make_copy(val, input)
	end
end

pace.dupe_ents = pace.dupe_ents or {}

duplicator.RegisterEntityModifier("pac_config", function(ply, ent, parts)
	local id = ent:EntIndex()
	
	if parts.part then
		parts = {[parts.part.self.UniqueID] = parts}
	end
	
	ent.pac_parts = parts
	pace.dupe_ents[ent:EntIndex()] = {owner = ply, ent = ent}

	for uid, data in pairs(parts) do
		
		if type(data.part) == "table" then
			make_copy(data.part, id)
		
			data.part.self.Name = tostring(ent)
			data.part.self.OwnerName = id
		end
		
		data.owner = ply
		data.uid = ply:UniqueID()
		data.skip_dupe = true
		
		pace.SubmitPart(data, nil, true)
	end	
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
	local allowed, reason = hook.Call("PrePACConfigApply", GAMEMODE, data.owner, data, true)

	if type(data.part) == "table" then	
		local ent = Entity(tonumber(data.part.self.OwnerName) or -1)
		if ent:IsValid()then
			if ent.CPPICanTool and (ent:CPPIGetOwner() ~= data.owner and not ent:CPPICanTool(data.owner, "paint")) then
				allowed = false
				reason = "you are not allowed to modify this entity: " .. tostring(ent) .. " owned by: " .. tostring(ent:CPPIGetOwner())
			elseif not data.skip_dupe then
				ent.pac_parts = ent.pac_parts or {}
				ent.pac_parts[data.part.self.UniqueID] = data
				
				pace.dupe_ents[ent:EntIndex()] = {owner = data.owner, ent = ent}
				
				duplicator.ClearEntityModifier(ent, "pac_config")
				duplicator.StoreEntityModifier(ent, "pac_config", ent.pac_parts)
			end
			
			ent:CallOnRemove("pac_config", function(ent)
				if ent.pac_parts then
					for _, data in pairs(ent.pac_parts) do
						if type(data.part) == "table" then
							data.part = data.part.self.UniqueID
						end
						data.skip_dupe = true
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
						v.ent.pac_parts = {}
						duplicator.ClearEntityModifier(v.ent, "pac_config")
						duplicator.StoreEntityModifier(v.ent, "pac_config", v.ent.pac_parts)	
						return
					else
						pace.dupe_ents[key] = nil
					end
				else
					pace.dupe_ents[key] = nil
				end
			end
			
		else
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
	
	if filter == false then
		filter = data.owner
	elseif filter == true then
		local tbl = {}
		for k,v in pairs(player.GetAll()) do
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
	
		local players = filter or player.GetAll()
		
		if pace.GlobalBans then
			if type(players) == "table" and data.owner:IsValid() then
				local owner_steamid = data.owner:SteamID() 
				for key, ply in pairs(players) do
					local steamid = ply:SteamID()
					for var, reason in pairs(pace.GlobalBans) do
						if  var == steamid or type(var) == "table" and (table.HasValue(var, steamid) or table.HasValue(var, ply:IPAddress():match("(.+):"))) then
							table.remove(players, key)
							print("[pac3] not sending data to "..ply:Nick().." because he/her is globally banned from using pac")
							
							if owner_steamid == steamid then
								return false, "you have been globally banned from using pac. see global_bans.lua for more info"
							end
						end
					end
				end
			end
		end
	
		if hook.Run("pac_SendData", players, data) ~= false then
			if pace.netstream then
				pace.netstream.Start(players, data)
			else
				net.Start("pac_submit")
					net.WriteTable(decimal_hack_pack(table.Copy(data)))
				net.Send(players)	
			end
			
			if type(data.part) == "table" then	
				last_frame = frame_number
				pac.HandleModifiers(data.part, data.owner)
			end
		end
	end
	
	return true
end

function pace.SubmitPartNotify(data)
	pace.dprint("submitted outfit %q from %s with %i number of children to set on %s", data.part.self.Name or "", data.owner:GetName(), table.Count(data.part.children), data.part.self.OwnerName or "")
	
	local allowed, reason = pace.SubmitPart(data)
	
	if data.owner:IsPlayer() then
		if allowed == "queue" then return end
		umsg.Start("pac_submit_acknowledged", data.owner)
			umsg.Bool(allowed)
			umsg.String(reason or "")
			umsg.String(data.part.self.Name or "no name")
		umsg.End()
	end
end

function pace.RemovePart(data)
	pace.dprint("%s is removed %q", data.owner:GetName(), data.part)
	
	if data.part == "__ALL__" then
		pac.HandleModifiers(nil, data.owner)
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
util.AddNetworkString("pac_effect_precached")
util.AddNetworkString("pac_precache_effect")

if pace.netstream then
	pace.netstream.Hook("pac_submit", function(ply, data)
		pace.HandleReceivedData(ply, data)
	end)
else
	net.Receive("pac_submit", function(_, ply)
		local data = net.ReadTable()
		decimal_hack_unpack(data)
		pace.HandleReceivedData(ply, data)
	end)
end

function pace.ClearOutfit(ply)
	local uid = ply:UniqueID()
	
	pace.SubmitPart({part = "__ALL__", uid = ply:UniqueID(), owner = ply})
	pac.HandleModifiers(nil, ply)
end

function pace.RequestOutfits(ply)
	if ply:IsValid() and not ply.pac_requested_outfits then
		for id, outfits in pairs(pace.Parts) do
			local owner = (player.GetByUniqueID(id) or NULL)
			if id == false or owner:IsValid() and owner:IsPlayer() and owner.GetPos and id ~= ply:UniqueID() then
				for key, outfit in pairs(outfits) do
					pace.SubmitPart(outfit, ply)
				end
			end
		end
		ply.pac_requested_outfits = true
	end
end

concommand.Add("pac_request_outfits", pace.RequestOutfits)