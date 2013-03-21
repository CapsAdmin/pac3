
function pac.Ban(ply)

	ply:ConCommand("pac_clear_parts")

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
	
	pac.Bans = bans
	
	file.Write("pac_bans.txt", util.TableToKeyValues(bans), "DATA")
end

function pac.Unban(ply)
	
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
	
	pac.Bans = bans
	
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
		pac.Ban(target)
	end
end)

concommand.Add("pac_unban", function(ply, cmd, args)
	local target = GetPlayer(args[1])
	if (not IsValid(ply) or ply:IsAdmin()) and target then
		pac.Unban(target)
	end
end)

function pac.IsBanned(ply)
	if not ply or not ply:IsValid() then return false end
	if not pac.Bans then
		local fil = file.Read("pac_bans.txt", "DATA")
	
		local bans = {}
		if fil and fil ~= "" then
			bans = util.KeyValuesToTable(fil)
		end
			
		pac.Bans = bans
	end
	return table.HasValue(pac.Bans, ply:SteamID())	
end