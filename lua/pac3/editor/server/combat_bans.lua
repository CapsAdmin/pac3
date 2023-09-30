
local function get_combat_ban_states()
	local str = file.Read("pac_combat_bans.txt", "DATA")

	local banstates = {}

	if str and str ~= "" then
		banstates = util.KeyValuesToTable(str)
	end

	do -- check if this needs to be rebuilt
		local k,v = next(banstates)
		if isstring(v) then
			local temp = {}

			for k,v in pairs(banstates) do
				permission = pac.global_combat_whitelist[player.GetBySteamID(k)] or "Default"
				temp[util.CRC("gm_" .. v .. "_gm")] = {steamid = v, name = k, permission = permission}
			end

			banstates = temp
		end
	end

	return banstates
end

local function load_table_from_file()
	tbl_on_file = get_combat_ban_states()
	for id, data in pairs(tbl_on_file) do
		if not pac.global_combat_whitelist[id] then
			pac.global_combat_whitelist[id] = tbl_on_file[id]
		end
	end
end

if SERVER then
	util.AddNetworkString("pac.BanUpdate")
	util.AddNetworkString("pac.RequestBanStates")
	util.AddNetworkString("pac.SendBanStates")


	util.AddNetworkString("pac.CombatBanUpdate")
	util.AddNetworkString("pac.SendCombatBanStates")
	util.AddNetworkString("pac.RequestCombatBanStates")
end


net.Receive("pac.CombatBanUpdate", function()
	--get old states first
	pac.old_tbl_on_file = get_combat_ban_states()

	load_table_from_file()

	local combatstates_update = net.ReadTable()
	local is_id_table = net.ReadBool()
	local banstates_for_file = pac.old_tbl_on_file

	--update
	if not is_id_table then
		for ply, perm in pairs(combatstates_update) do
			banstates_for_file[ply:SteamID()] = {
				steamid = ply:SteamID(),
				nick = ply:Nick(),
				permission = perm
			}

			pac.global_combat_whitelist[ply:SteamID()] = {
				steamid = ply:SteamID(),
				nick = ply:Nick(),
				permission = perm
			}
		end
	else
		pac.global_combat_whitelist = combatstates_update
		banstates_for_file = combatstates_update
	end

	file.Write("pac_combat_bans.txt", util.TableToKeyValues(banstates_for_file), "DATA")
end)

net.Receive("pac.RequestCombatBanStates", function(len, ply)
	pac.global_combat_whitelist = get_combat_ban_states()
	net.Start("pac.SendCombatBanStates")
	net.WriteTable(pac.global_combat_whitelist)
	net.Send(ply)
end)


pac.old_tbl_on_file = get_combat_ban_states()



concommand.Add("pac_read_combat_bans", function()
	print("PAC3 combat bans and whitelist:")
	for k,v in pairs(get_combat_ban_states()) do
		print("\t" .. v.nick .. " is " .. v.permission .. " [" .. v.steamid .. "]")
	end
end)

concommand.Add("pac_read_outfit_bans", function()
	PrintTable(pace.Bans)
end)
