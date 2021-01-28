
local pac_friendonly = CreateClientConVar("pac_friendonly", 0, true, false, 'Load PACs from friends only')
local pac_use_whitelist = CreateClientConVar("pac_use_whitelist", 0, true, false, 'Load PACs only from players listed in settings')
local pac_use_whitelist_b = CreateClientConVar("pac_use_whitelist_b", 0, true, false, 'Whitelist acts as blacklist')

function pac.FriendOnlyUpdate()
	local lply = LocalPlayer()

	if pac_friendonly:GetBool() then
		for k, v in ipairs(player.GetAll()) do
			if v ~= lply then
				pac.ToggleIgnoreEntity(v, v:GetFriendStatus() ~= "friend", 'pac_friendonly')
			end
		end
	else
		for k, v in ipairs(player.GetAll()) do
			if v ~= lply then
				pac.ToggleIgnoreEntity(v, false, 'pac_friendonly')
			end
		end
	end
end

function pac.UseWhitelistUpdates()
	local lply = LocalPlayer()

	if pac_use_whitelist:GetBool() then
		if pac_use_whitelist_b:GetBool() then
			for k, v in ipairs(player.GetAll()) do
				if v ~= lply then
					pac.ToggleIgnoreEntity(v, cookie.GetString('pac3_wear_wl_' .. v:UniqueID(), '0') == '1', 'pac_whitelist')
				end
			end
		else
			for k, v in ipairs(player.GetAll()) do
				if v ~= lply then
					pac.ToggleIgnoreEntity(v, cookie.GetString('pac3_wear_wl_' .. v:UniqueID(), '0') ~= '1', 'pac_whitelist')
				end
			end
		end
	else
		for k, v in ipairs(player.GetAll()) do
			if v ~= lply then
				pac.ToggleIgnoreEntity(v, false, 'pac_whitelist')
			end
		end
	end
end

function pac.UseWhitelistUpdatesPerPlayer(ply)
	if pac_use_whitelist:GetBool() then
		if pac_use_whitelist_b:GetBool() then
			pac.ToggleIgnoreEntity(ply, cookie.GetString('pac3_wear_wl_' .. ply:UniqueID(), '0') == '1', 'pac_whitelist')
		else
			pac.ToggleIgnoreEntity(ply, cookie.GetString('pac3_wear_wl_' .. ply:UniqueID(), '0') ~= '1', 'pac_whitelist')
		end
	else
		pac.ToggleIgnoreEntity(ply, false, 'pac_whitelist')
	end
end

cvars.AddChangeCallback("pac_friendonly", pac.FriendOnlyUpdate, "PAC3")
cvars.AddChangeCallback("pac_use_whitelist", pac.UseWhitelistUpdates, "PAC3")
cvars.AddChangeCallback("pac_use_whitelist_b", pac.UseWhitelistUpdates, "PAC3")

pac.AddHook("NetworkEntityCreated", "friendonly", function(ply)
	if not IsValid(ply) or not ply:IsPlayer() then return end

	timer.Simple(4, function()
		if not ply:IsValid() then return end

		if pac_friendonly:GetBool() then
			pac.ToggleIgnoreEntity(ply, ply:GetFriendStatus() ~= "friend", 'pac_friendonly')
		else
			pac.ToggleIgnoreEntity(ply, false, 'pac_friendonly')
		end

		pac.UseWhitelistUpdatesPerPlayer(ply)
	end)
end)

pac.AddHook("pac_Initialized", "friendonly", pac.FriendOnlyUpdate)