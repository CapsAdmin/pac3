local L = pace.LanguageString

local function add_expensive_submenu_load(pnl, callback)
	local old = pnl.OnCursorEntered
	pnl.OnCursorEntered = function(...)
		callback()
		pnl.OnCursorEntered = old
		return old(...)
	end
end

local function populate_pac(menu)
	do
		local menu, icon = menu:AddSubMenu(L"save", function() pace.SaveParts() end)
		menu:SetDeleteSelf(false)
		icon:SetImage(pace.MiscIcons.save)
		add_expensive_submenu_load(icon, function() pace.AddSaveMenuToMenu(menu) end)
	end

	do
		local menu, icon = menu:AddSubMenu(L"load", function() pace.LoadParts(nil, true) end)
		menu:SetDeleteSelf(false)
		icon:SetImage(pace.MiscIcons.load)
		add_expensive_submenu_load(icon, function() pace.AddSavedPartsToMenu(menu, true) end)
	end

	do
		local menu, icon = menu:AddSubMenu(L"wear", function() pace.WearParts() end)
		menu:SetDeleteSelf(false)
		icon:SetImage(pace.MiscIcons.wear)

		menu:AddOption(L"wear")

		menu:AddSpacer()

		local function is_blocked(ply)
			if GetConVar('pac_wear_friends_only'):GetBool() then
				return ply:GetFriendStatus() ~= "friend"
			end
			return cookie.GetString("pac3_wear_block_" .. ply:UniqueID()) == "1"
		end

		local function is_enabled(ply)
			if GetConVar("pac_wear_reverse"):GetBool() then
				return not is_blocked(ply)
			end
			return is_blocked(ply)
		end

		local function set_enabled(ply, b)
			if b then
				cookie.Set("pac3_wear_block_" .. ply:UniqueID(), "1")
			else
				cookie.Delete("pac3_wear_block_" .. ply:UniqueID())
			end
		end

		local function OnMouseReleased( self, mousecode )

			DButton.OnMouseReleased( self, mousecode )

			if ( self.m_MenuClicking && mousecode == MOUSE_LEFT ) then

				self.m_MenuClicking = false

			end

		end

		local updaters = {}

		for _,  ply in ipairs(player.GetAll()) do
			if ply ~= pac.LocalPlayer then
				local icon

				local function update()
					if not ply:IsValid() then
						icon:SetAlpha(0.5)
						return
					end

					icon:SetChecked(is_enabled(ply))
				end

				icon = menu:AddOption(ply:Nick(), function(self)
					if not ply:IsValid() then
						self:SetAlpha(0.5)
						return
					end

					set_enabled(ply, not is_blocked(ply))

					update()
				end)
				icon.OnMouseReleased = OnMouseReleased

				table.insert(updaters, function() update(icon) end)
			end
		end

		menu:AddSpacer()

		local function update_all()
			for _, func in ipairs(updaters) do
				func()
			end
		end

		menu:AddCVar(L"reverse blocklist", "pac_wear_reverse", "1", "0", update_all).OnMouseReleased = OnMouseReleased
		menu:AddCVar(L"friends only", "pac_wear_friends_only", "1", "0", update_all).OnMouseReleased = OnMouseReleased
		menu:AddOption(L"reset", function()
			for _, ply in ipairs(player.GetAll()) do
				set_enabled(ply, false)
			end
			update_all()
		end).OnMouseReleased = OnMouseReleased

		update_all()
	end

	do
		local menu, icon = menu:AddSubMenu(L"clear", function() end)
		icon:SetImage(pace.MiscIcons.clear)
		menu.GetDeleteSelf = function() return false end
		menu:AddOption(L"OK", function() pace.ClearParts() end):SetImage(pace.MiscIcons.clear)
	end

	menu:AddSpacer()

	do
		local help, help_pnl = menu:AddSubMenu(L"help", function() pace.ShowWiki() end)
		help.GetDeleteSelf = function() return false end
		help_pnl:SetImage(pace.MiscIcons.help)

		help:AddOption(
			L"Getting Started",
			function() pace.ShowWiki(pace.WikiURL .. "Beginners-FAQ") end
		):SetImage(pace.MiscIcons.info)

		do
			local chat_pnl = help:AddOption(
				L"Discord / PAC3 Chat",
				function() gui.OpenURL("https://discord.gg/utpR3gJ") cookie.Set("pac3_discord_ad", 3)  end
			) chat_pnl:SetImage(pace.MiscIcons.chat)

			if cookie.GetNumber("pac3_discord_ad", 0) < 3 then
				help_pnl.PaintOver = function(_,w,h) surface.SetDrawColor(255,255,0,50 + math.sin(SysTime()*20)*20) surface.DrawRect(0,0,w,h) end
				chat_pnl.PaintOver = help_pnl.PaintOver
				cookie.Set("pac3_discord_ad", cookie.GetNumber("pac3_discord_ad", 0) + 1)
			end
		end

		local info = _G.PAC_VERSION and PAC_VERSION()
		if info then
			local version, version_pnl = help:AddSubMenu(L"Version", function() pace.ShowWiki() end)
			version.GetDeleteSelf = function() return false end
			version_pnl:SetImage(pace.MiscIcons.info)

			version:AddOption("Addon: " .. info.addon.version_name)
			version:AddOption("Editor: " .. info.editor.version_name)
			version:AddOption("Core: " .. info.core.version_name)
		end
	end

	do
		menu:AddOption(L"exit", function() pace.CloseEditor() end):SetImage(pace.MiscIcons.exit)
	end
end

local function populate_view(menu)
	menu:AddOption(L"hide editor",
		function() pace.Call("ToggleFocus") chat.AddText("[PAC3] \"ctrl + e\" to get the editor back")
	end):SetImage("icon16/application_delete.png")

	menu:AddCVar(L"camera follow", "pac_camera_follow_entity", "1", "0"):SetImage("icon16/camera_go.png")
	menu:AddOption(L"reset view position", function() pace.ResetView() end):SetImage("icon16/camera_link.png")
	menu:AddOption(L"reset zoom", function() pace.ResetZoom() end):SetImage("icon16/magnifier.png")

	menu:AddOption(
		L"about",
		function() pace.ShowAbout() end
	):SetImage(pace.MiscIcons.about)

end

local function populate_options(menu)
	menu:AddCVar(L"advanced mode", "pac_basic_mode", "0", "1").DoClick = function() pace.ToggleBasicMode() end
	menu:AddCVar(L"inverse collapse/expand controls", "pac_reverse_collapse", "1", "0")
	menu:AddCVar(L"enable shift+move/rotate clone", "pac_grab_clone", "1", "0")
	menu:AddCVar(L"remember editor position", "pac_editor_remember_position", "1", "0")
	menu:AddSpacer()
	menu:AddOption(L"position grid size", function()
		Derma_StringRequest(L"position grid size", L"size in units:", GetConVarNumber("pac_grid_pos_size"), function(val)
			RunConsoleCommand("pac_grid_pos_size", val)
		end)
	end)
	menu:AddOption(L"angles grid size", function()
		Derma_StringRequest(L"angles grid size", L"size in degrees:", GetConVarNumber("pac_grid_ang_size"), function(val)
			RunConsoleCommand("pac_grid_ang_size", val)
		end)
	end)
	menu:AddCVar(L"render attachments as bones", "pac_render_attachments", "1", "0").DoClick = function() pace.ToggleRenderAttachments() end
	menu:AddSpacer()

	menu:AddCVar(L"automatic property size", "pac_auto_size_properties", "1", "0")
	menu:AddCVar(L"enable language identifier in text fields", "pac_editor_languageid", "1", "0")
	pace.AddLanguagesToMenu(menu)
	pace.AddFontsToMenu(menu)

	menu:AddSpacer()

	local rendering, pnl = menu:AddSubMenu(L"rendering", function() end)
		rendering.GetDeleteSelf = function() return false end
		pnl:SetImage("icon16/camera_edit.png")
		rendering:AddCVar(L"no outfit reflections", "pac_suppress_frames", "1", "0")
end

local function populate_player(menu)
	local pnl = menu:AddOption(L"t pose", function() pace.SetTPose(not pace.GetTPose()) end):SetImage("icon16/user_go.png")
	menu:AddOption(L"reset eye angles", function() pace.ResetEyeAngles() end):SetImage("icon16/user_delete.png")
	menu:AddOption(L"reset zoom", function() pace.ResetZoom() end):SetImage("icon16/magnifier.png")

	-- this should be in pacx but it's kinda stupid to add a hook just to populate the player menu
	-- make it more generic
	if pacx and pacx.GetServerModifiers then
		local mods, pnl = menu:AddSubMenu(L"modifiers", function() end)
		pnl:SetImage("icon16/user_edit.png")
		mods.GetDeleteSelf = function() return false end
		for name in pairs(pacx.GetServerModifiers()) do
			mods:AddCVar(L(name), "pac_modifier_" .. name, "1", "0")
		end
	end
end

function pace.OnMenuBarPopulate(bar)
	for k,v in pairs(bar.Menus) do
		v:Remove()
	end

	populate_pac(bar:AddMenu("pac"))
	populate_view(bar:AddMenu(L"view"))
	populate_options(bar:AddMenu(L"options"))
	populate_player(bar:AddMenu(L"player"))
	pace.AddToolsToMenu(bar:AddMenu(L"tools"))

	bar:RequestFocus(true)
end

function pace.OnOpenMenu()
	local menu = DermaMenu()
	menu:SetPos(input.GetCursorPos())

	populate_player(menu) menu:AddSpacer()
	populate_view(menu) menu:AddSpacer()
	populate_options(menu) menu:AddSpacer()
	populate_pac(menu) menu:AddSpacer()

	local menu, pnl = menu:AddSubMenu(L"tools")
	pnl:SetImage("icon16/plugin.png")
	pace.AddToolsToMenu(menu)

	menu:MakePopup()
end