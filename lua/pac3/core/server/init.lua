pac = pac or {}

pac.Outfits = {}
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
				table.insert(pac.Errors, args[2])
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
	umsg.Start("pac_effect_precached")
			umsg.String(name)
	umsg.End()
end

concommand.Add("pac_precache_effect", function(ply, _, args)
	local name = args[1]
	if not table.HasValue(pac.EffectsBlackList, name) then
		pac.PrecacheEffect(name)
	end
end)

function pac.IsAllowedToModify(ply, ent)
	if ent:IsPlayer() and ent ~= ply then
		return false, "you cannot change other player's pac outfits"
	end
	return true
end

function pac.CheckOutfit(ply, data)
	local allowed, reason = true, ""
	if IsValid(data.ent) and type(data.outfit) == "table" then
		allowed, reason = pac.IsAllowedToModify(ply, data.ent)
	end
	return true
end

function pac.SubmitOutfit(data, ply)
	local rp = RecipientFilter()
	rp:AddAllPlayers()
	if data.ply then
		rp:RemovePlayer(data.ply)
	end

	datastream.StreamToClients(ply or rp, "pac_submit", data)
end

function pac.PlayerInitialSpawn(ply)
	timer.Simple(1, function()
		if ply:IsPlayer() then
			for ent, data in pairs(pac.Outfits) do
				if Entity(ent):IsValid() then
					local ent = data[#data].ent
					if ent:IsValid() then
						local outfit = data[#data].outfit

						pac.SubmitOutfit({ent = ent, outfit = outfit}, ply)
					end
				end
			end
		end
	end)
end

pac.AddHook("PlayerInitialSpawn")

function pac.CheckSubmitOutfit(ply, data)
	local allowed, issue = true, ""

	if CurTime() < (ply.LastPACSubmission or 0) + 0.3 then
		allowed, issue = false, "You must wait 1 second between submissions."
	end

	allowed, issue = pac.CheckOutfit(ply, data)

	local args = { hook.Call("PrePACOutfitApply", GAMEMODE, ply, data) }

	if args[1] == false then
		allowed, issue = false, args[2]
	end

	if allowed then
		pac.SubmitOutfit(data)

		pac.Outfits[ply:EntIndex()] = pac.Outfits[ply:EntIndex()] or {}
		table.insert(pac.Outfits[ply:EntIndex()], data)

		ply.LastPACSubmission = CurTime()
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

function pac.RemoveOutfit(ply, data)
	if pac.IsAllowedToModify(ply, data.ent) then
		pac.Outfits[ply:EntIndex()] = pac.Outfits[ply:EntIndex()] or {}

		pac.SubmitOutfit(data)

		for key, _data in ipairs(pac.Outfits[ply:EntIndex()]) do
			if _data.outfit.Name == data.outfit then
				table.remove(pac.Outfits[ply:EntIndex()], key)
				break
			end
		end
	end
end

datastream.Hook("pac_submit", function(ply, _, _, _, data)
	if IsValid(data.ent) then
		data.ply = ply
		if type(data.outfit) == "table" then
			pac.CheckSubmitOutfit(ply, data)
		elseif type(data.outfit) == "string" then
			pac.RemoveOutfit(ply, data)
		end
	end
end)