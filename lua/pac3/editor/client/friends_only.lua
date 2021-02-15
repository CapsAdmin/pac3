net.Receive("pac.TogglePartDrawing", function()
	local ent = net.ReadEntity()
	if ent:IsValid() then
		local b = (net.ReadBit() == 1)
		pac.TogglePartDrawing(ent, b)
	end
end)

do -- ignore
	function pac.ToggleIgnoreEntity(ent, status, strID)
		if status then
			return pac.IgnoreEntity(ent, strID)
		else
			return pac.UnIgnoreEntity(ent, strID)
		end
	end

	function pac.IsEntityIgnored(ent)
		return ent.pac_ignored or false
	end

	function pac.IsEntityIgnoredBy(ent, strID)
		return ent.pac_ignored_data and ent.pac_ignored_data[strID] or false
	end

	function pac.IsEntityIgnoredOnlyBy(ent, strID)
		return ent.pac_ignored_data and ent.pac_ignored_data[strID] and table.Count(ent.pac_ignored_data) == 1 or false
	end

	function pac.EntityIgnoreBound(ent, callback)
		if not pac.IsEntityIgnored(ent) then
			return callback(ent)
		end

		ent.pac_ignored_callbacks = ent.pac_ignored_callbacks or {}
		table.insert(ent.pac_ignored_callbacks, callback)
	end

	function pac.CleanupEntityIgnoreBound(ent)
		ent.pac_ignored_callbacks = nil
	end

	function pac.IgnoreEntity(ent, strID)
		if ent == pac.LocalPlayer then return false end

		strID = strID or 'generic'
		if ent.pac_ignored_data and ent.pac_ignored_data[strID] then return end
		ent.pac_ignored = ent.pac_ignored or false
		ent.pac_ignored_data = ent.pac_ignored_data or {}
		ent.pac_ignored_data[strID] = true
		local newStatus = true

		if newStatus ~= ent.pac_ignored then
			ent.pac_ignored = newStatus
			pac.TogglePartDrawing(ent, not newStatus)
		end

		return true
	end

	function pac.UnIgnoreEntity(ent, strID)
		if ent == pac.LocalPlayer then return false end

		strID = strID or 'generic'
		if ent.pac_ignored_data and ent.pac_ignored_data[strID] == nil then return end
		ent.pac_ignored = ent.pac_ignored or false
		ent.pac_ignored_data = ent.pac_ignored_data or {}
		ent.pac_ignored_data[strID] = nil
		local newStatus = false

		for _, v in pairs(ent.pac_ignored_data) do
			if v then
				newStatus = true
				break
			end
		end

		if newStatus ~= ent.pac_ignored then
			ent.pac_ignored = newStatus

			if not newStatus and ent.pac_ignored_callbacks then
				for i, callback in ipairs(ent.pac_ignored_callbacks) do
					ProtectedCall(function()
						callback(ent)
					end)
				end

				ent.pac_ignored_callbacks = nil
			end

			pac.TogglePartDrawing(ent, not newStatus)
		end

		return newStatus
	end

end

local pac_friendonly = CreateClientConVar("pac_friendonly", 0, true, false, 'Load PACs from friends only')
local pac_use_whitelist = CreateClientConVar("pac_use_whitelist", 0, true, false, 'Load PACs only from players listed in settings')
local pac_use_whitelist_b = CreateClientConVar("pac_use_whitelist_b", 0, true, false, 'Whitelist acts as blacklist')

function pac.FriendOnlyUpdate()
	local lply = pac.LocalPlayer

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
	local lply = pac.LocalPlayer

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