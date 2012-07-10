pac = pac or {}

pac.Parts = pac.Parts or {}
pac.Errors = {}

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
			print(ply, " precached effect ", name)
			pac.PrecacheEffect(name)
		end
	end)
end

function pac.IsAllowedToModify(ply, ent)
	if ent:IsPlayer() and ent ~= ply then
		return false, "you cannot change other player's pac outfits"
	end
	return true
end

function pac.CheckPart(ply, data)
	local allowed, reason = true, ""
	if IsValid(data.ent) and type(data.part) == "table" then
		allowed, reason = pac.IsAllowedToModify(ply, data.ent)
	end
	return true
end

function pac.SubmitPart(data, ply)
	if net then
		net.Start("pac_submit")
			net.WriteString(glon.encode(data))
		net.Send(ply or player.GetAll())
	else
		datastream.StreamToClients(ply or player.GetAll(), "pac_submit", data)
	end
end

function pac.PlayerInitialSpawn(ply)
	timer.Simple(1, function()
		if ply:IsPlayer() then
			for id, outfits in pairs(pac.Parts) do
				if player.GetByUniqueID(id) then
                    for key, outfit in pairs(outfits) do
						local ent = outfit.ent or NULL
						if ent:IsValid() then
							pac.SubmitPart(outfit, ply)
						end
					end
				end
			end
		end
	end)
end

pac.AddHook("PlayerInitialSpawn")

function pac.CheckSubmitPart(ply, data)
	local allowed, issue = true, ""

	if (ply.LastPACSubmission or 0) > CurTime() then
		allowed, issue = false, "You must wait 1 second between submissions."
	end

	allowed, issue = pac.CheckPart(ply, data)

	local args = { hook.Call("PrePACPartApply", GAMEMODE, ply, data) }

	if args[1] == false then
		allowed, issue = false, args[2]
	end

	if true or allowed then
		print(ply, " submitted outfit to ", data.ent)
		pac.SubmitPart(data)

		pac.Parts[ply:UniqueID()] = pac.Parts[ply:UniqueID()] or {}
		pac.Parts[ply:UniqueID()][data.part.self.Name] = data

		ply.LastPACSubmission = CurTime() + 2
		umsg.Start("pac_submit_acknowledged", ply)
			umsg.Bool(allowed)
			umsg.String("")
		umsg.End()
	else
		umsg.Start("pac_submit_acknowledged", ply)
			umsg.Bool(allowed)
			umsg.String(issue or "")
		umsg.End()
	end
end

function pac.RemovePart(ply, data)
	print(ply, " is removing ", data.part)
	--if pac.IsAllowedToModify(ply, data.ent) then
		pac.Parts[ply:UniqueID()] = pac.Parts[ply:UniqueID()] or {}
		pac.Parts[ply:UniqueID()][data.part] = nil
		
		pac.SubmitPart(data)
	--end
end

function pac.SetOwnerPart(ply, data)
	print(ply, " is changing owner ", data.part)
	--if pac.IsAllowedToModify(ply, data.ent) then
		pac.Parts[ply:UniqueID()] = pac.Parts[ply:UniqueID()] or {}
		local part = pac.Parts[ply:UniqueID()][data.part]
		part.ent = data.b
		pac.SubmitPart({ply = ply, ent = data.a, part = data.part})
		pac.SubmitPart(part)
	--end
end

local function handle_data(ply, data)
	if IsValid(data.ent) then
		data.ply = ply
		if IsEntity(data.a) and data.a:IsValid() and IsEntity(data.b) and data.b:IsValid() then
			pac.SetOwnerPart(ply, data)
		elseif type(data.part) == "table" then
			pac.CheckSubmitPart(ply, data)
		elseif type(data.part) == "string" then
			pac.RemovePart(ply, data)
		end
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

-- should this be here?

concommand.Add("pac_in_editor", function(ply, _, args)
	ply:SetNWBool("in pac3 editor", tonumber(args[1]) == 1)
end)
