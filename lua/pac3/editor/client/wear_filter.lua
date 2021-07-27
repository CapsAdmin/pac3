local list_form = include("panels/list.lua")
local L = pace.LanguageString

local cache = {}

local function store_config(id, tbl)
	file.CreateDir("pac/config")
	file.Write("pac/config/"..id..".json", util.TableToJSON(tbl))
	cache[id] = tbl
end

local function read_config(id)
	local tbl = util.JSONToTable(file.Read("pac/config/"..id..".json", "DATA") or "{}") or {}
	cache[id] = tbl
	return tbl
end

local function get_config_value(id, key)
	return cache[id] and cache[id][key]
end

local function jsonid(ply)
	return "_" .. pac.Hash(ply)
end

local function update_ignore()
	for _, ply in ipairs(player.GetHumans()) do
		pac.ToggleIgnoreEntity(ply, pace.ShouldIgnorePlayer(ply), "wear_filter")
	end
end

hook.Add("PlayerSpawn", "pace_outfit_ignore_update", function()
	update_ignore()
end)

net.Receive("pac.TogglePartDrawing", function()
	local ent = net.ReadEntity()

	if ent:IsValid() then
		local b = (net.ReadBit() == 1)
		pac.TogglePartDrawing(ent, b)
	end
end)

-- ignore
do
	function pac.ToggleIgnoreEntity(ent, status, strID)
		if status then
			return pac.IgnoreEntity(ent, strID)
		else
			return pac.UnIgnoreEntity(ent, strID)
		end
	end

	function pac.IsEntityIgnored(ent)
		if pace.ShouldIgnorePlayer(ent) then
			return true
		end
		return ent.pac_ignored or false
	end

	function pac.IsEntityIgnoredBy(ent, strID)
		return ent.pac_ignored_data and ent.pac_ignored_data[strID] or false
	end

	function pac.IsEntityIgnoredOnlyBy(ent, strID)
		return ent.pac_ignored_data and ent.pac_ignored_data[strID] and table.Count(ent.pac_ignored_data) == 1 or false
	end

	function pac.EntityIgnoreBound(ent, callback, index)
		assert(isfunction(callback), "isfunction(callback)")

		if not pac.IsEntityIgnored(ent) then return callback(ent) end

		ent.pac_ignored_callbacks = ent.pac_ignored_callbacks or {}

		if index then
			for i, data in ipairs(ent.pac_ignored_callbacks) do
				if data.index == index then
					table.remove(ent.pac_ignored_callbacks, i)
					break
				end
			end
		end

		table.insert(ent.pac_ignored_callbacks, {callback = callback, index = index})
	end

	function pac.CleanupEntityIgnoreBound(ent)
		ent.pac_ignored_callbacks = nil
	end

	function pac.IgnoreEntity(ent, strID)
		if ent == pac.LocalPlayer then return false end
		strID = strID or "generic"
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
		strID = strID or "generic"
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
				for i, data in ipairs(ent.pac_ignored_callbacks) do
					ProtectedCall(function()
						data.callback(ent)
					end)
				end

				ent.pac_ignored_callbacks = nil
			end

			pac.TogglePartDrawing(ent, not newStatus)
		end

		return newStatus
	end
end

CreateClientConVar("pace_wear_filter_mode", "disabled")
CreateClientConVar("pace_outfit_filter_mode", "disabled")

function pace.ShouldIgnorePlayer(ply)
	local mode = GetConVar("pace_outfit_filter_mode"):GetString()

	if mode == "steam_friends" then
		return ply:GetFriendStatus() ~= "friend"
	elseif mode == "whitelist" then
		return get_config_value("outfit_whitelist", jsonid(ply)) == nil
	elseif mode == "blacklist" then
		return get_config_value("outfit_blacklist", jsonid(ply)) ~= nil
	end

	return false
end

function pace.CreateWearFilter()
	local mode = GetConVar("pace_wear_filter_mode"):GetString()

	local tbl = {}

	for _, ply in ipairs(player.GetHumans()) do
		if ply == pac.LocalPlayer then continue end

		if mode == "steam_friends" then
			if ply:GetFriendStatus() == "friend" then
				table.insert(tbl, pac.Hash(ply))
			end
		elseif mode == "whitelist" then
			if get_config_value("wear_whitelist", jsonid(ply)) ~= nil then
				table.insert(tbl, pac.Hash(ply))
			end
		elseif mode == "blacklist" then
			if get_config_value("wear_blacklist", jsonid(ply)) == nil then
				table.insert(tbl, pac.Hash(ply))
			end
		else
			table.insert(tbl, pac.Hash(ply))
		end
	end

	table.insert(tbl, pac.Hash(pac.LocalPlayer))

	return tbl
end

local function generic_form(help)
	local pnl = vgui.Create("DListLayout")

	local label = pnl:Add("DLabel")
	label:DockMargin(0,5,0,5)
	label:SetWrap(true)
	label:SetDark(true)
	label:SetAutoStretchVertical(true)
	label:SetText(help)

	return pnl
end

local function player_list_form(name, id, help)
	local pnl = vgui.Create("DListLayout")

	local label = pnl:Add("DLabel")
	label:DockMargin(0,5,0,5)
	label:SetWrap(true)
	label:SetDark(true)
	label:SetAutoStretchVertical(true)
	label:SetText(help)

	list_form(pnl, name, {
		empty_message = L"No players online.",

		name_left = "players",
		populate_left = function()
			local blacklist = read_config(id)

			local tbl = {}
			for _, ply in ipairs(player.GetHumans()) do
				if ply == pac.LocalPlayer then continue end
				if not blacklist[jsonid(ply)] then
					table.insert(tbl, {
						name = ply:Nick(),
						value = ply,
					})
				end
			end
			return tbl
		end,
		store_left = function(kv)
			local tbl = read_config(id)
			tbl[jsonid(kv.value)] = kv.name
			store_config(id, tbl)

			if id:StartWith("outfit") then
				update_ignore()
			end
		end,

		name_right = name,
		populate_right = function()
			local tbl = {}
			for id, nick in pairs(read_config(id)) do
				local ply = pac.ReverseHash(id:sub(2), "Player")
				if ply == pac.LocalPlayer then continue end

				if IsValid(ply) then
					table.insert(tbl, {
						name = ply:Nick(),
						value = id,
					})
				else
					table.insert(tbl, {
						name = nick .. " (offline)",
						value = id,
					})
				end
			end
			return tbl
		end,
		store_right = function(kv)
			local tbl = read_config(id)
			tbl[kv.value] = nil
			store_config(id, tbl)

			if id:StartWith("outfit") then
				update_ignore()
			end
		end,
	})

	return pnl
end

do
	net.Receive("pac_update_playerfilter", function()
		local ids = pace.CreateWearFilter()
		net.Start("pac_update_playerfilter")
		net.WriteUInt(#ids, 8)

		for _, val in ipairs(ids) do
			net.WriteString(val)
		end

		net.SendToServer()
	end)

	function pace.PopulateWearMenu(menu)
		for _, ply in ipairs(player.GetHumans()) do
			if ply == pac.LocalPlayer then continue end

			local icon = menu:AddOption(L"wear only for " .. ply:Nick(), function()
				pace.WearParts(ply)
			end)
			icon:SetImage(pace.MiscIcons.wear)
		end
	end
end

function pace.FillWearSettings(pnl)
	local list = vgui.Create("DCategoryList", pnl)
	list:Dock(FILL)

	do
		local cat = list:Add(L"wear filter")
		cat.Header:SetSize(40,40)
		cat.Header:SetFont("DermaLarge")
		local list = vgui.Create("DListLayout")
		list:DockPadding(20,20,20,20)
		cat:SetContents(list)

		local mode = vgui.Create("DComboBox", list)
		mode:SetSortItems(false)
		mode:AddChoice("disabled")
		mode:AddChoice("steam friends")
		mode:AddChoice("whitelist")
		mode:AddChoice("blacklist")

		mode.OnSelect = function(_, _, value)
			if IsValid(mode.form) then
				mode.form:Remove()
			end

			if value == "steam friends" then
				mode.form = generic_form(L"Only your steam friends can see your worn outfit.")
			elseif value == "whitelist" then
				mode.form = player_list_form(L"whitelist", "wear_whitelist", L"Only the players in the whitelist can see your worn outfit.")
			elseif value == "blacklist" then
				mode.form = player_list_form( L"blacklist", "wear_blacklist", L"The players in the blacklist cannot see your worn outfit.")
			elseif value == "disabled" then
				mode.form = generic_form(L"Everyone can see your worn outfit.")
			end

			GetConVar("pace_wear_filter_mode"):SetString(value:gsub(" ", "_"))

			mode.form:SetParent(list)
		end

		local mode_str = GetConVar("pace_wear_filter_mode"):GetString():gsub("_", " ")
		mode:ChooseOption(mode_str)
		mode:OnSelect(nil, mode_str)
	end

	do
		local cat = list:Add(L"outfit filter")
		cat.Header:SetSize(40,40)
		cat.Header:SetFont("DermaLarge")
		local list = vgui.Create("DListLayout")
		list:DockPadding(20,20,20,20)
		cat:SetContents(list)

		local mode = vgui.Create("DComboBox", list)
		mode:SetSortItems(false)
		mode:AddChoice("disabled")
		mode:AddChoice("steam friends")
		mode:AddChoice("whitelist")
		mode:AddChoice("blacklist")

		mode.OnSelect = function(_, _, value)
			if IsValid(mode.form) then
				mode.form:Remove()
			end

			if value == "steam friends" then
				mode.form = generic_form(L"You will only see outfits from your steam friends.")
			elseif value == "whitelist" then
				mode.form = player_list_form(L"whitelist", "outfit_whitelist", L"You will only see outfits from the players in the whitelist.")
			elseif value == "blacklist" then
				mode.form = player_list_form(L"blacklist", "outfit_blacklist", L"You will see outfits from everyone except the players in the blacklist.")
			elseif value == "disabled" then
				mode.form = generic_form(L"You will see everyone's outfits.")
			end

			GetConVar("pace_outfit_filter_mode"):SetString(value:gsub(" ", "_"))

			mode.form:SetParent(list)

			update_ignore()
		end

		local mode_str = GetConVar("pace_outfit_filter_mode"):GetString():gsub("_", " ")
		mode:ChooseOption(mode_str)
		mode:OnSelect(nil, mode_str)
	end

	return list
end