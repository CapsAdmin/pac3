setfenv(1, _G)
pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}

function pac.dprint(fmt, ...)
	if pac.debug or GetHostName() == "CapsAdmin's Server" then
		MsgN("\n")
		MsgN(">>>PAC3>>>")
		MsgN(fmt:format(...))
		if pac.debug_trace then
			MsgN("==TRACE==")
			debug.Trace()
			MsgN("==TRACE==")
		end
		MsgN("<<<PAC3<<<")
		MsgN("\n")
	end
end

do -- hook helpers
	function pac.CallHook(str, ...)
		hook.Call("pac_" .. str, GAMEMODE, ...)
	end

	function pac.AddHook(str, func)
		func = func or pac[str]
		hook.Add(str, "pac_" .. str, function(...)
			local args = {pcall(func, ...)}
			if not args[1] then
				ErrorNoHalt(args[2] .. "\n")
				--table.insert(pac.Errors, args[2])
			end
			table.remove(args, 1)
			return unpack(args)
		end)
	end

	function pac.RemoveHook(str)
		hook.Remove(str, "pac_" .. str)
	end
end

do -- effects

	pac.EffectsBlackList =
	{
		"frozen_steam",
		"portal_rift_01",
		"explosion_silo",
		"citadel_shockwave_06",
		"citadel_shockwave",
		"choreo_launch_rocket_start",
		"choreo_launch_rocket_jet",
	}

	function pac.PrecacheEffect(name)
		PrecacheParticleSystem(name)
		if net then
			net.Start("pac_effect_precached")
				net.WriteString(name)
			net.Send()
		else
			umsg.Start("pac_effect_precached")
				umsg.String(name)
			umsg.End()
		-- compat hack
		if PAC then
		  if PAC.EffectsBlackList and table.HasValue(PAC.EffectsBlackList, effect) then return end
			umsg.Start("PAC Effect Precached")
			  umsg.String(name)
			umsg.End()
		  end
		 end
	end

	if net then
		net.Receive("pac_precache_effect", function()
			local name = net.ReadString()
			if not table.HasValue(pac.EffectsBlackList, name) then
				pac.PrecacheEffect(name)
			end
		end)
	else
		concommand.Add("pac_precache_effect", function(ply, _, args)
			local name = args[1]
			if not table.HasValue(pac.EffectsBlackList, name) then
				pac.dprint("%s precached effect %s", ply:Nick(), name)
				pac.PrecacheEffect(name)
			end
		end)
	end
end

local function get_owner(var)
	return (IsEntity(var) and var) or (type(var) == "string" and player.GetByUniqueID(var)) or NULL
end

function pac.SubmitPart(data, filter)

	local uid = data.uid
	pac.Parts[uid] = pac.Parts[uid] or {}
	
	if type(data.part) == "table" then
		pac.Parts[uid][data.part.self.Name] = data
	else
		pac.Parts[uid][data.part] = nil
	end

	if net then
		net.Start("pac_submit")
			net.WriteString(glon.encode(data))
		net.Send(filter or player.GetAll())
	else
		datastream.StreamToClients(filter or player.GetAll(), "pac_submit", data)
	end
end

function pac.SubmitPartNotify(data)
	pac.dprint("submitted outfit %q from %s with %i number of children to set on %s", data.part.self.Name, data.owner:Nick(), table.Count(data.part.children), data.part.self.OwnerName)
	
	pac.SubmitPart(data)
	
	-- todo: check owner name if the player is allowed to modify
	
	if data.owner:IsPlayer() then
		umsg.Start("pac_submit_acknowledged", data.owner)
			umsg.Bool(true)
			umsg.String("")
		umsg.End()
	end
end

function pac.RemovePart(data)
	pac.dprint("%s is removed %q", data.owner:Nick(), data.part)
	
	pac.SubmitPart(data)
end

local function handle_data(owner, data)
	data.owner = owner
	data.uid = owner:UniqueID()
	
	if type(data.part) == "table" then
		pac.SubmitPartNotify(data)
	elseif type(data.part) == "string" then
		pac.RemovePart(data)
	end
end

if net then
	util.AddNetworkString("pac_submit")
	util.AddNetworkString("pac_effect_precached")
	util.AddNetworkString("pac_precache_effect")

	net.Receive("pac_submit", function(_, ply)
		local data = glon.decode(net.ReadString())
		handle_data(ply, data)
	end)
else
	require("datastream")
	
	datastream.Hook("pac_submit", function(ply, _, _, _, data)
		handle_data(ply, data)
	end)
end


function pac.PlayerInitialSpawn(ply)
	timer.Simple(1, function()
		if ply:IsPlayer() then
			for id, outfits in pairs(pac.Parts) do
				if player.GetByUniqueID(id) then
                    for key, outfit in pairs(outfits) do
						pac.SubmitPart(outfit, ply)
					end
				end
			end
		end
	end)
end

pac.AddHook("PlayerInitialSpawn")

-- should this be here?

concommand.Add("pac_in_editor", function(ply, _, args)
	ply:SetNWBool("in pac3 editor", tonumber(args[1]) == 1)
end)
