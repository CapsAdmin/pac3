function pace.Ban(ply)

	ply:ConCommand("pac_clear_parts")
	
	timer.Simple( 1, function() -- made it a timer because the ConCommand din't run fast enough. - Bizzclaw
	
		umsg.Start("pac_submit_acknowledged", ply)
			umsg.Bool(false)
			umsg.String("You have been banned from using pac!")
		umsg.End()
	
		local fil = file.Read("pac_bans.txt", "DATA")
	
		local bans = {}
		if fil and fil ~= "" then
		bans = util.KeyValuesToTable(fil)
		end
		
		for name, steamid in pairs(bans) do
			if ply:SteamID() == steamid then
			bans[name] = nil
			end
		end

		bans[ply:Nick():lower():gsub("%A", "")] = ply:SteamID()
	
		pace.Bans = bans
	
		file.Write("pac_bans.txt", util.TableToKeyValues(bans), "DATA")
	end)
end

function pace.Unban(ply)
	
	umsg.Start("pac_submit_acknowledged", ply)
		umsg.Bool(false)
		umsg.String("You are now permitted to use pac!")
	umsg.End()
		
	local fil = file.Read("pac_bans.txt", "DATA")
	
	local bans = {}
	if fil and fil ~= "" then
		bans = util.KeyValuesToTable(fil)
	end
		
	for name, steamid in pairs(bans) do
		if ply:SteamID() == steamid then
			bans[name] = nil
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
	end
end)

concommand.Add("pac_unban", function(ply, cmd, args)
	local target = GetPlayer(args[1])
	if (not IsValid(ply) or ply:IsAdmin()) and target then
		pace.Unban(target)
	end
end)

function pace.IsBanned(ply)
	if not ply or not ply:IsValid() then return false end
	if not pace.Bans then
		local fil = file.Read("pac_bans.txt", "DATA")
	
		local bans = {}
		if fil and fil ~= "" then
			bans = util.KeyValuesToTable(fil)
		end
			
		pace.Bans = bans
	end
	return table.HasValue(pace.Bans, ply:SteamID())	
end
