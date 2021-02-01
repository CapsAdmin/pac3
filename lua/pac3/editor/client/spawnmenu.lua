local L = pace.LanguageString

concommand.Add("pac_wear_parts", function(ply, _, args)
	pace.WearParts(args[1], true)
end)

concommand.Add("pac_clear_parts", function()
	pace.ClearParts()
end)

concommand.Add("pac_panic", function()
	pac.Panic()
end)

net.Receive("pac_spawn_part", function()
	if not pace.current_part:IsValid() then return end

	local mdl = net.ReadString()

	if pace.close_spawn_menu then
		pace.RecordUndoHistory()
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)

		if g_SpawnMenu:IsVisible() then
			g_SpawnMenu:Close()
		end

		pace.close_spawn_menu = false
	elseif pace.current_part.ClassName ~= "model" then
		local name = mdl:match(".+/(.+)%.mdl")

		pace.RecordUndoHistory()
		pace.Call("CreatePart", "model", name, mdl)
	else
		pace.RecordUndoHistory()
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)
	end
end)

pace.SpawnlistBrowser = NULL

local PLAYER_LIST_PANEL
local PLAYER_LIST_PANEL2
local pac_wear_friends_only

local function rebuildPlayerList()
	local self = PLAYER_LIST_PANEL
	if not IsValid(self) then return end

	if self.plist then
		for i, panel in ipairs(self.plist) do
			if IsValid(panel) then
				panel:Remove()
			end
		end
	end

	if count == 1 then
		self.plist = {self:Help(L"no players are online")}
	else
		pac_wear_friends_only = pac_wear_friends_only or GetConVar('pac_wear_friends_only')
		local plys = player.GetAll()
		self.plist = {}

		for _, ply in ipairs(plys) do
			if ply ~= LocalPlayer() then
				local check = self:CheckBox(ply:Nick())
				table.insert(self.plist, check)

				if pac_wear_friends_only:GetBool() then
					check:SetChecked(ply:GetFriendStatus() ~= "friend")
				else
					check:SetChecked(cookie.GetString("pac3_wear_block_" .. ply:UniqueID()) == "1")
				end

				check.OnChange = function(_, newValue)
					if pac_wear_friends_only:GetBool() then
						check:SetChecked(ply:GetFriendStatus() ~= "friend")
					elseif newValue then
						cookie.Set("pac3_wear_block_" .. ply:UniqueID(), '1')
					else
						cookie.Delete("pac3_wear_block_" .. ply:UniqueID())
					end
				end
			end
		end
	end
end

local function rebuildPlayerList2()
	local self = PLAYER_LIST_PANEL2
	if not IsValid(self) then return end

	if self.plist then
		for i, panel in ipairs(self.plist) do
			if IsValid(panel) then
				panel:Remove()
			end
		end
	end

	if count == 1 then
		self.plist = {self:Help(L"no players are online")}
	else
		pac_wear_friends_only = pac_wear_friends_only or GetConVar('pac_wear_friends_only')
		local plys = player.GetAll()
		self.plist = {}

		for _, ply in ipairs(plys) do
			if ply ~= LocalPlayer() then
				local check = self:CheckBox(ply:Nick())
				table.insert(self.plist, check)
				check:SetChecked(cookie.GetString("pac3_wear_wl_" .. ply:UniqueID(), '0') == "1")

				check.OnChange = function(_, newValue)
					if pac_wear_friends_only:GetBool() then
						check:SetChecked(ply:GetFriendStatus() ~= "friend")
					elseif newValue then
						cookie.Set("pac3_wear_wl_" .. ply:UniqueID(), '1')
					else
						cookie.Delete("pac3_wear_wl_" .. ply:UniqueID())
					end

					pac.UseWhitelistUpdatesPerPlayer(ply)
				end
			end
		end
	end
end

do
	local count = -1

	local function playerListWatchdog()
		if count == player.GetCount() then return end
		count = player.GetCount()
		rebuildPlayerList()
		rebuildPlayerList2()
	end

	timer.Create('pac3.menus.playerlist.rebuild', 5, 0, playerListWatchdog)
end

function pace.ClientOptionsMenu(self)
	if not IsValid(self) then return end
	PLAYER_LIST_PANEL = self

	self:Button(L"show editor", "pac_editor")
	self:CheckBox(L"enable", "pac_enable")
	self:Button(L"clear", "pac_clear_parts")
	self:Button(L"wear on server", "pac_wear_parts" )

	local browser = self:AddControl("pace_browser", {})

	browser.OnLoad = function(node)
		pace.LoadParts(node.FileName, true)
	end

	if #file.Find("pac3/sessions/*", "DATA") > 0 then
		browser:SetDir("sessions/")
	else
		browser:SetDir("")
	end

	browser:SetSize(400,480)

	pace.SpawnlistBrowser = browser

	self:Button(L"request outfits", "pac_request_outfits")
	self:Button(L"panic", "pac_panic")

	self:CheckBox(L"wear for friends only", "pac_wear_friends_only")
	self:CheckBox(L"wear blacklist acts as whitelist", "pac_wear_reverse")

	self:Help(L"don't wear for these players:")

	rebuildPlayerList()
end

function pace.ClientSettingsMenu(self)
	if not IsValid(self) then return end
	PLAYER_LIST_PANEL2 = self
	self:Help(L"Performance"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable PAC", "pac_enable")
		self:NumSlider(L"Draw distance:", "pac_draw_distance", 0, 20000, 0)
		self:NumSlider(L"Max render time: ", "pac_max_render_time", 0, 50, 0)

	self:CheckBox(L"Friend only", "pac_friendonly")
	self:CheckBox(L"Reveal outfits only on +use", "pac_onuse_only")
	self:CheckBox(L"Hide outfits that some folks can find disturbing", "pac_hide_disturbing")

	self:NumSlider(
		L"PAC Volume",
		"pac_ogg_volume",
		0,
		1,
		2
	)

	self:CheckBox(L"Process OBJ in background", "pac_obj_async")

	self:CheckBox(L"render objects outside visible fov", "pac_override_fov")
	self:CheckBox(L"render projected textures (flashlight)", "pac_render_projected_texture")

	self:Help(L"Misc"):SetFont("DermaDefaultBold")
		self:NumSlider(L"PAC Volume", "pac_ogg_volume", 0, 1, 2)
		self:CheckBox(L"Custom error model", "pac_error_mdl")

	self:Help(L"Enable"):SetFont("DermaDefaultBold")

	local t = {
		"urlobj",
		"urltex"
	}

	for k in pairs(pac.convarcache or {}) do
		local str = k:match("^pac_enable_(.*)")
		if str then
			table.insert(t, str)
		end
	end

	table.sort(t)

	for _,str in pairs(t) do
		self:CheckBox(L(str), "pac_enable_" .. str)
	end

	self:Help("")
	self:CheckBox(L"Load PACs only from next players", "pac_use_whitelist")
	self:CheckBox(L"next list acts as blacklist", "pac_use_whitelist_b")

	rebuildPlayerList2()
end


local icon = "icon64/pac3.png"
icon = file.Exists("materials/"..icon,'GAME') and icon or "icon64/playermodel.png"

list.Set(
	"DesktopWindows",
	"PACEditor",
	{
		title = "PAC Editor",
		icon = icon,
		width = 960,
		height = 700,
		onewindow = true,
		init = function(icn, pnl)
			pnl:Remove()
			RunConsoleCommand("pac_editor")
		end
	}
)

hook.Add("PopulateToolMenu", "pac_spawnmenu", function()
	spawnmenu.AddToolMenuOption(
		"Utilities",
		"PAC",
		"PAC3",
		L"PAC3",
		"",
		"",
		pace.ClientOptionsMenu,
		{
			SwitchConVar = "pac_enable",
		}
	)
	spawnmenu.AddToolMenuOption(
		"Utilities",
		"PAC",
		"PAC3S",
		L"Settings",
		"",
		"",
		pace.ClientSettingsMenu,
		{
		}
	)
end)

if IsValid(g_ContextMenu) and CreateContextMenu then
	CreateContextMenu()
end
