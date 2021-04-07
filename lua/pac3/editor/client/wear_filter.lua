local L = pace.LanguageString

net.Receive("pac.TogglePartDrawing", function()
    local ent = net.ReadEntity()

    if ent:IsValid() then
        local b = (net.ReadBit() == 1)
        pac.TogglePartDrawing(ent, b)
    end
end)

local function get_other_real_players()
	local out = {}

	for _, ply in ipairs(player.GetAll()) do
		if not ply:SteamID64() then continue end -- this will return nil for bots
		if ply == pac.LocalPlayer then continue end
		table.insert(out, ply)
	end

	return out
end

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
        return ent.pac_ignored or false
    end

    function pac.IsEntityIgnoredBy(ent, strID)
        return ent.pac_ignored_data and ent.pac_ignored_data[strID] or false
    end

    function pac.IsEntityIgnoredOnlyBy(ent, strID)
        return ent.pac_ignored_data and ent.pac_ignored_data[strID] and table.Count(ent.pac_ignored_data) == 1 or false
    end

    function pac.EntityIgnoreBound(ent, callback)
        if not pac.IsEntityIgnored(ent) then return callback(ent) end
        ent.pac_ignored_callbacks = ent.pac_ignored_callbacks or {}
        table.insert(ent.pac_ignored_callbacks, callback)
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

-- show
do
    CreateClientConVar("pac_use_whitelist", 0, true, false, "Load outfits only from certain players")
    CreateClientConVar("pac_friendonly", 0, true, false, "Load PACs from friends only")
    CreateClientConVar("pac_use_whitelist_b", 0, true, false, "Whitelist acts as blacklist")

    local function id(ply)
        return "pac3_wear_wl_" .. ply:UniqueID()
    end

    local function is_enabled(ply)
        if GetConVar("pac_friendonly"):GetBool() then return ply:GetFriendStatus() ~= "friend" end

        return cookie.GetString(id(ply)) == "1"
    end

    local function should_ignore(ply)
        if ply == pac.LocalPlayer then return false end
        if GetConVar("pac_use_whitelist_b"):GetBool() then return not is_enabled(ply) end

        return is_enabled(ply)
    end

    local function update_show_list()
        for _, ply in ipairs(get_other_real_players()) do
            pac.ToggleIgnoreEntity(ply, should_ignore(ply), "pac_showlist")
        end
    end

    cvars.AddChangeCallback("pac_friendonly", update_show_list, "PAC3")
    cvars.AddChangeCallback("pac_use_whitelist", update_show_list, "PAC3")
    cvars.AddChangeCallback("pac_use_whitelist_b", update_show_list, "PAC3")

    pac.AddHook("NetworkEntityCreated", "friendonly", function(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        timer.Simple(4, function()
            if not IsValid(ply) or not ply:IsPlayer() then return end
            update_show_list()
        end)
    end)

    pac.AddHook("pac_Initialized", "friendonly", update_show_list)
end

-- wear
do
    CreateClientConVar("pac_use_wear_list", "0", true, false, "Wear outfits only to certain players")
    CreateClientConVar("pac_wear_friends_only", "0", true, false, "Wear outfits only to friends")
    CreateClientConVar("pac_wear_reverse", "0", true, false, "Wear to NOBODY but to people from list (Blacklist -> Whitelist)")

    local function id(ply)
        return "pac3_wear_block_" .. ply:UniqueID()
    end

    local function is_blocked(ply)
        if GetConVar("pac_wear_friends_only"):GetBool() then return ply:GetFriendStatus() ~= "friend" end

        return cookie.GetString(id(ply)) == "1"
    end

    local function should_ignore(ply)
        if GetConVar("pac_wear_reverse"):GetBool() then return not is_blocked(ply) end

        return is_blocked(ply)
    end

    local function set_ignore(ply, b)
		if GetConVar("pac_wear_reverse"):GetBool() then b = not b end

        if b then
            cookie.Set(id(ply), "1")
        else
            cookie.Delete(id(ply))
        end
    end

    function pace.CreateWearFilter()
        local filter = {}

        for _, ply in ipairs(get_other_real_players()) do
            if not should_ignore(ply) then
                table.insert(filter, pac.Hash(ply))
            end
        end

		-- also add the local player so that you can "feel" that it worked
		table.insert(filter, pac.Hash(pac.LocalPlayer))

        return filter
    end

    net.Receive("pac_update_playerfilter", function()
        local ids = pace.CreateWearFilter()
        net.Start("pac_update_playerfilter")
        net.WriteUInt(#ids, 8)

        for _, val in ipairs(ids) do
            net.WriteString(val)
        end

        net.SendToServer()
    end)

    local function OnMouseReleased(self, mousecode)
        DButton.OnMouseReleased(self, mousecode)

        if (self.m_MenuClicking and mousecode == MOUSE_LEFT) then
            self.m_MenuClicking = false
        end
    end

    function pace.PopulateWearMenu(menu)
		local root = menu
        local updaters = {}

        for _, ply in ipairs(get_other_real_players()) do
			local icon

			local function update()
				if not ply:IsValid() then
					icon:SetAlpha(0.5)
					return
				end

				if should_ignore(ply) then
					icon:SetImage("icon16/cross.png")
				else
					icon:SetImage("icon16/tick.png")
				end
			end

			do

				local menu
				menu, icon = root:AddSubMenu(ply:Nick(), function(self)
					if not ply:IsValid() then
						self:SetAlpha(0.5)

						return
					end

					set_ignore(ply, not should_ignore(ply))
					update()
				end)
				menu:SetDeleteSelf(false)

				icon.OnMouseReleased = OnMouseReleased

				do
					local icon = menu:AddOption(L"wear only for " .. ply:Nick(), function()
						pace.WearParts(ply)
					end)
					icon:SetImage(pace.MiscIcons.wear)
				end
				menu:AddSpacer()

				menu:AddOption(L"block", function()
					set_ignore(ply, true)
					update()
				end).OnMouseReleased = OnMouseReleased

				menu:AddOption(L"unblock", function()
					set_ignore(ply, false)
					update()
				end).OnMouseReleased = OnMouseReleased
			end

			table.insert(updaters, function()
				update()
			end)
        end

        menu:AddSpacer()

        local function update_all()
            for _, func in ipairs(updaters) do
                func()
            end
        end

        menu:AddCVar(L"reverse list", "pac_wear_reverse", "1", "0").OnMouseReleased = OnMouseReleased
        menu:AddCVar(L"friends only", "pac_wear_friends_only", "1", "0").OnMouseReleased = OnMouseReleased

		cvars.AddChangeCallback("pac_wear_reverse", update_all, "PAC3")
		cvars.AddChangeCallback("pac_wear_friends_only", update_all, "PAC3")


        menu:AddOption(L"reset", function()
			GetConVar("pac_wear_reverse"):SetBool(false)
			GetConVar("pac_wear_friends_only"):SetBool(false)

            for _, ply in ipairs(get_other_real_players()) do
				cookie.Delete(id(ply))
            end

            update_all()

			for _, ply in ipairs(get_other_real_players()) do
				print(ply, should_ignore(ply))
			end
        end).OnMouseReleased = OnMouseReleased

        update_all()
    end
end