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
	if net then
		net.Start("pac_effect_precached")
			net.WriteString(name)
		net.Send()
	else
		umsg.Start("pac_effect_precached")
			umsg.String(name)
		umsg.End()
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
	local rp = RecipientFilter()
	rp:AddAllPlayers()
	
	if data.ply then
		rp:RemovePlayer(data.ply)
	end
	
	if net then
		net.Start("pac_receive")
			net.WriteString(glon.encode(data))
		net.Send(ply or rp)
	else
		datastream.StreamToClients(ply or rp, "pac_receive", data)
	end
end

function pac.PlayerInitialSpawn(ply)
	timer.Simple(1, function()
		if ply:IsPlayer() then
			for ent, data in pairs(pac.Parts) do
				if Entity(ent):IsValid() then
					local ent = data[#data].ent
					if ent:IsValid() then
						local part = data[#data].part

						pac.SubmitPart({ent = ent, part = part}, ply)
					end
				end
			end
		end
	end)
end

pac.AddHook("PlayerInitialSpawn")

function pac.CheckSubmitPart(ply, data)
	local allowed, issue = true, ""

	if CurTime() < (ply.LastPACSubmission or 0) + 0.3 then
		allowed, issue = false, "You must wait 1 second between submissions."
	end

	allowed, issue = pac.CheckPart(ply, data)

	local args = { hook.Call("PrePACPartApply", GAMEMODE, ply, data) }

	if args[1] == false then
		allowed, issue = false, args[2]
	end

	if allowed then
		pac.SubmitPart(data)

		pac.Parts[ply:EntIndex()] = pac.Parts[ply:EntIndex()] or {}
		table.insert(pac.Parts[ply:EntIndex()], data)

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

function pac.RemovePart(ply, data)
	if pac.IsAllowedToModify(ply, data.ent) then
		pac.Parts[ply:EntIndex()] = pac.Parts[ply:EntIndex()] or {}

		pac.SubmitPart(data)

		for key, _data in pairs(pac.Parts[ply:EntIndex()]) do
			if _data.part.Name == data.part then
				table.remove(pac.Parts[ply:EntIndex()], key)
				break
			end
		end
	end
end

local function handle_data(ply, data)
	if IsValid(data.ent) then
		data.ply = ply
		if type(data.part) == "table" then
			pac.CheckSubmitPart(ply, data)
		elseif type(data.part) == "string" then
			pac.RemovePart(ply, data)
		end
	end
end

if net then
	util.AddNetworkString("pac_submit")
	util.AddNetworkString("pac_receive")
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