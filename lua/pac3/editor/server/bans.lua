local function get_bans()
	local str = file.Read("pac_bans.txt", "DATA")

	local bans = {}

	if str and str ~= "" then
		bans = util.KeyValuesToTable(str)
	end

	do -- check if this needs to be rebuilt
		local k,v = next(bans)
		if type(v) == "string" then
			local temp = {}

			for k,v in pairs(bans) do
				temp[util.CRC("gm_" .. v .. "_gm")] = {steamid = v, name = k}
			end

			bans = temp
		end
	end

	return bans
end

function pace.Ban(ply)

	ply:ConCommand("pac_clear_parts")

	timer.Simple( 1, function() -- made it a timer because the ConCommand don't run fast enough. - Bizzclaw

		net.Start("pac_submit_acknowledged")
			net.WriteBool(false)
			net.WriteString("You have been banned from using pac!")
		net.Send(ply)

		local bans = get_bans()

		for key, data in pairs(bans) do
			if ply:SteamID() == data.steamid then
				bans[key] = nil
			end
		end

		bans[ply:UniqueID()] = {steamid = ply:SteamID(), nick = ply:Nick()}

		pace.Bans = bans

		file.Write("pac_bans.txt", util.TableToKeyValues(bans), "DATA")
	end)
end

function pace.Unban(ply)

	net.Start("pac_submit_acknowledged")
		net.WriteBool(true)
		net.WriteString("You are now permitted to use pac!")
	net.Send(ply)

	local bans = get_bans()

	for key, data in pairs(bans) do
		if ply:SteamID() == data.steamid then
			bans[key] = nil
		end
	end

	pace.Bans = bans

	file.Write("pac_bans.txt", util.TableToKeyValues(bans), "DATA")
end

local function GetPlayer(target)
	for key, ply in pairs(player.GetAll()) do
		if ply:SteamID() == target or ply:UniqueID() == target or ply:Nick():lower():find(target:lower()) then
			return ply
		end
	end
end

concommand.Add("pac_ban", function(ply, cmd, args)
	local target = GetPlayer(args[1])
	if (not IsValid(ply) or ply:IsAdmin()) and target then
		pace.Ban(target)
		pac.Message(ply, " banned ", target, " from PAC.")
	end
end)

concommand.Add("pac_unban", function(ply, cmd, args)
	local target = GetPlayer(args[1])
	if (not IsValid(ply) or ply:IsAdmin()) and target then
		pace.Unban(target)
		pac.Message(ply, " unbanned ", target, " from PAC.")
	end
end)

function pace.IsBanned(ply)
	if not ply or not ply:IsValid() then return false end

	if not pace.Bans then
		pace.Bans = get_bans()
	end

	return pace.Bans[ply:UniqueID()] ~= nil
end
