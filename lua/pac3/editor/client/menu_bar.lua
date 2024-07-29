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

		pace.PopulateWearMenu(menu)
	end

	do
		menu:AddOption(L"request", function() RunConsoleCommand("pac_request_outfits") pac.Message('Requesting outfits.') end):SetImage(pace.MiscIcons.replace)
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

		help:AddOption(
			L"PAC3 Wiki",
			function() pace.ShowWiki("https://wiki.pac3.info/start") end
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

		local version_string = _G.PAC_VERSION and PAC_VERSION()
		if version_string then
			local version, version_pnl = help:AddSubMenu(L"Version", function() pace.ShowWiki() end)
			version.GetDeleteSelf = function() return false end
			version_pnl:SetImage(pace.MiscIcons.info)

			version:AddOption(version_string)

			version:AddOption("local update changelogs", function() pac.OpenMOTD("local_changelog") end)
			version:AddOption("external commit history", function() pac.OpenMOTD("commit_history") end)
			version:AddOption("major update news (combat update)", function() pac.OpenMOTD("combat_update") end)
		end



		help:AddOption(
			L"about",
			function() pace.ShowAbout() end
		):SetImage(pace.MiscIcons.about)
	end

	do
		menu:AddOption(L"exit", function() pace.CloseEditor() end):SetImage(pace.MiscIcons.exit)
	end


end

local function populate_view(menu)
	menu:AddOption(L"hide editor",
		function() pace.Call("ToggleFocus") chat.AddText("[PAC3] \"ctrl + e\" to get the editor back")
	end):SetImage("icon16/application_delete.png")

	menu:AddCVar(L"camera follow: "..GetConVar("pac_camera_follow_entity"):GetInt(), "pac_camera_follow_entity", "1", "0"):SetImage("icon16/camera_go.png")
	menu:AddCVar(L"enable editor camera: "..GetConVar("pac_enable_editor_view"):GetInt(), "pac_enable_editor_view", "1", "0"):SetImage("icon16/camera.png")
	menu:AddOption(L"reset view position", function() pace.ResetView() end):SetImage("icon16/camera_link.png")
	menu:AddOption(L"reset zoom", function() pace.ResetZoom() end):SetImage("icon16/magnifier.png")
end

local function populate_options(menu)
	menu:AddOption(L"settings", function() pace.OpenSettings() end)
	menu:AddCVar(L"Keyboard shortcuts: Legacy mode", "pac_editor_shortcuts_legacy_mode", "1", "0")
	menu:AddCVar(L"inverse collapse/expand controls", "pac_reverse_collapse", "1", "0")
	menu:AddCVar(L"enable shift+move/rotate clone", "pac_grab_clone", "1", "0")
	menu:AddCVar(L"remember editor position", "pac_editor_remember_position", "1", "0")
	menu:AddCVar(L"remember divider position", "pac_editor_remember_divider_height", "1", "0")
	menu:AddCVar(L"ask before loading autoload", "pac_prompt_for_autoload", "1", "0")

	local prop_pac_load_mode, pnlpplm = menu:AddSubMenu("(singleplayer only) How to handle prop/npc outfits", function() end)
		prop_pac_load_mode.GetDeleteSelf = function() return false end
		pnlpplm:SetImage("icon16/transmit.png")
		prop_pac_load_mode:AddOption(L"Load without queuing", function() RunConsoleCommand("pac_autoload_preferred_prop", "0") end)
		prop_pac_load_mode:AddOption(L"Queue parts if there's only one group", function() RunConsoleCommand("pac_autoload_preferred_prop", "1") end)
		prop_pac_load_mode:AddOption(L"Queue parts if there's one or more groups", function() RunConsoleCommand("pac_autoload_preferred_prop", "2") end)

	menu:AddCVar(L"show parts IDs", "pac_show_uniqueid", "1", "0")

	local halos, pnlh = menu:AddSubMenu("configure hover halo highlights", function() end)
	halos.GetDeleteSelf = function() return false end
	pnlh:SetImage("icon16/shading.png")
	halos:AddCVar(L"disable hover halos", "pac_hover_color", "none", "255 255 255")
	halos:AddOption("object limit (performance)", function()
		Derma_StringRequest("pac_hover_halo_limit ", "how many objects can halo at once?", GetConVarNumber("pac_hover_halo_limit"), function(val) RunConsoleCommand("pac_hover_halo_limit", val) end)
	end):SetImage("icon16/sitemap.png")
	halos:AddOption("pulse rate", function()
		Derma_StringRequest("pac_hover_pulserate", "how fast to pulse?", GetConVarNumber("pac_hover_pulserate"), function(val) RunConsoleCommand("pac_hover_pulserate", val) end)
	end):SetImage("icon16/time.png")

	halos:AddOption("How it reacts to bulk select", function()
		local bulk_key_option_str = "bulk select key (current bind:" .. GetConVar("pac_bulk_select_key"):GetString() .. ")"
		Derma_Query("What keys should trigger the hover halo on bulk select?","pac_bulk_select_halo_mode",
			"passive",function() RunConsoleCommand("pac_bulk_select_halo_mode", 1) end,
			bulk_key_option_str, function() RunConsoleCommand("pac_bulk_select_halo_mode", 2) end,
			"control", function() RunConsoleCommand("pac_bulk_select_halo_mode", 3) end,
			"shift", function() RunConsoleCommand("pac_bulk_select_halo_mode", 4) end
		)
	end):SetImage("icon16/table_multiple.png")
	halos:AddOption("Do not highlight bulk select", function()
		RunConsoleCommand("pac_bulk_select_halo_mode", "0")
	end):SetImage("icon16/table_delete.png")

	local halos_color, pnlhclr = halos:AddSubMenu("hover halo color", function() end)
		pnlhclr:SetImage("icon16/color_wheel.png")
		halos_color.GetDeleteSelf = function() return false end
		halos_color:AddOption(L"none (disable halos)", function() RunConsoleCommand("pac_hover_color", "none") end):SetImage('icon16/page_white.png')
		halos_color:AddOption(L"white (default)", function() RunConsoleCommand("pac_hover_color", "255 255 255") end):SetImage('icon16/bullet_white.png')
		halos_color:AddOption(L"color (opens a menu)", function()
			local clr_frame = vgui.Create("DFrame")
			clr_frame:SetSize(300,200) clr_frame:Center()
			local clr_pnl = vgui.Create("DColorMixer", clr_frame)
				clr_frame:SetSize(300,200) clr_pnl:Dock(FILL)
				clr_frame:RequestFocus()
				function clr_pnl:ValueChanged(col)
					hover_color:SetString(col.r .. " " .. col.g .. " " .. col.b)
				end
		end):SetImage('icon16/color_swatch.png')
		halos_color:AddOption(L"ocean", function() RunConsoleCommand("pac_hover_color", "ocean") end):SetImage('icon16/bullet_blue.png')
		halos_color:AddOption(L"funky", function() RunConsoleCommand("pac_hover_color", "funky") end):SetImage('icon16/color_wheel.png')
		halos_color:AddOption(L"rave", function() RunConsoleCommand("pac_hover_color", "rave") end):SetImage('icon16/color_wheel.png')
		halos_color:AddOption(L"rainbow", function() RunConsoleCommand("pac_hover_color", "rainbow") end):SetImage('icon16/rainbow.png')

	local popups, pnlp = menu:AddSubMenu("configure editor popups", function() end)
		popups.GetDeleteSelf = function() return false end
		pnlp:SetImage("icon16/comment.png")
		popups:AddCVar(L"enable editor popups", "pac_popups_enable", "1", "0")
		popups:AddCVar(L"don't kill popups on autofade", "pac_popups_preserve_on_autofade", "1", "0")
		popups:AddOption("Configure popups appearance", function() pace.OpenPopupConfig() end):SetImage('icon16/color_wheel.png')
		local popup_pref_mode, pnlppm = popups:AddSubMenu("prefered location", function() end)
			pnlppm:SetImage("icon16/layout_header.png")
			popup_pref_mode.GetDeleteSelf = function() return false end
			popup_pref_mode:AddOption(L"parts on viewport", function() RunConsoleCommand("pac_popups_preferred_location", "part world") end):SetImage('icon16/camera.png')
			popup_pref_mode:AddOption(L"part label on tree", function() RunConsoleCommand("pac_popups_preferred_location", "pac tree label") end):SetImage('icon16/layout_content.png')
			popup_pref_mode:AddOption(L"menu bar", function() RunConsoleCommand("pac_popups_preferred_location", "menu bar") end):SetImage('icon16/layout_header.png')
			popup_pref_mode:AddOption(L"cursor", function() RunConsoleCommand("pac_popups_preferred_location", "cursor") end):SetImage('icon16/mouse.png')
			popup_pref_mode:AddOption(L"screen", function() RunConsoleCommand("pac_popups_preferred_location", "screen") end):SetImage('icon16/monitor.png')

	menu:AddOption(L"configure event wheel", pace.ConfigureEventWheelMenu):SetImage("icon16/color_wheel.png")

	local copilot, pnlc = menu:AddSubMenu("configure editor copilot", function() end)
		copilot.GetDeleteSelf = function() return false end
		pnlc:SetImage("icon16/award_star_gold_3.png")
		copilot:AddCVar(L"show info popup when changing an event's type", "pac_copilot_make_popup_when_selecting_event", "1", "0")
		copilot:AddCVar(L"auto-focus on the main property when creating some parts", "pac_copilot_auto_focus_main_property_when_creating_part","1","0")
		copilot:AddCVar(L"auto-setup a command event when entering a name as an event type", "pac_copilot_auto_setup_command_events", "1", "0")
		copilot:AddCVar(L"open asset browser when creating some parts", "pac_copilot_open_asset_browser_when_creating_part", "1", "0")
		copilot:AddCVar(L"disable the editor view when creating a camera part", "pac_copilot_force_preview_cameras", "1", "0")
		local copilot_add_part_search_menu, pnlaps = copilot:AddSubMenu("configure the searchable add part menu", function() end)
			pnlaps:SetImage("icon16/add.png")
			copilot_add_part_search_menu.GetDeleteSelf = function() return false end
			copilot_add_part_search_menu:AddOption(L"No copilot", function() RunConsoleCommand("pac_copilot_partsearch_depth", "-1") end):SetImage('icon16/page_white.png')
			copilot_add_part_search_menu:AddOption(L"automatically select a text field after creating the part (e.g. event type)", function() RunConsoleCommand("pac_copilot_partsearch_depth", "0") end):SetImage('icon16/layout_edit.png')
			copilot_add_part_search_menu:AddOption(L"open another quick list menu (event types, favorite models...)", function() RunConsoleCommand("pac_copilot_partsearch_depth", "1") end):SetImage('icon16/application_view_list.png')

	local combat_consents, pnlcc = menu:AddSubMenu("pac combat consents", function() end)
	combat_consents.GetDeleteSelf = function() return false end
	pnlcc:SetImage("icon16/joystick.png")

	local npc_pref = combat_consents:AddOption(L"Level of protection for friendly NPCs", function()
		Derma_Query("Prevent friendly fire against NPCs? (damage zone and hitscan)", "NPC relationship preferences (pac_client_npc_exclusion_consent = " .. GetConVar("pac_client_npc_exclusion_consent"):GetInt() .. ")",
		"Don't protect (0)", function() GetConVar("pac_client_npc_exclusion_consent"):SetInt(0) end,
		"Protect friendly NPCs (1)", function() GetConVar("pac_client_npc_exclusion_consent"):SetInt(1) end,
		"Protect friendly and neutral NPCs (2)", function() GetConVar("pac_client_npc_exclusion_consent"):SetInt(2) end,
		"cancel")
	end)
	npc_pref:SetImage("icon16/group.png")
	npc_pref:SetTooltip("\"Friendliness\" is based on an NPC's Disposition toward you: Error&Hate, Fear&Neutral, Like")

	combat_consents:AddCVar(L"damage_zone part (area damage)", "pac_client_damage_zone_consent", "1", "0")
	combat_consents:AddCVar(L"hitscan part (bullets)", "pac_client_hitscan_consent", "1", "0")
	combat_consents:AddCVar(L"force part (physics forces)", "pac_client_force_consent", "1", "0")
	combat_consents:AddCVar(L"lock part's grab (can take control of your position and eye angles)", "pac_client_grab_consent", "1", "0")
	combat_consents:AddCVar(L"lock part's grab calcview (can take control of your view position)", "pac_client_lock_camera_consent", "1", "0"):SetTooltip("You're still not immune to it changing your eye angles.\nCalcviews are a different thing than eye angles.")


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
	menu:AddCVar(L"Use the new PAC4.5 icon", "pac_icon", "1", "0")

	menu:AddSpacer()

	local rendering, pnl = menu:AddSubMenu(L"rendering", function() end)
		rendering.GetDeleteSelf = function() return false end
		pnl:SetImage("icon16/camera_edit.png")
		rendering:AddCVar(L"no outfit reflections", "pac_optimization_render_once_per_frame", "1", "0")
end

local function get_events()
	local events = {}
	for k,v in pairs(pac.GetLocalParts()) do
		if v.ClassName == "event" then
			local e = v:GetEvent()
			if e == "command" then
				local cmd, time, hide = v:GetParsedArgumentsForObject(v.Events.command)
				local b = false
				events[cmd] = pac.LocalPlayer.pac_command_events[cmd] and pac.LocalPlayer.pac_command_events[cmd].on == 1 or false
			end
		end
	end
	return events
end

local function populate_player(menu)
	local pnl = menu:AddOption(L"t pose", function() pace.SetTPose(not pace.GetTPose()) end):SetImage("icon16/user_go.png")
	menu:AddOption(L"reset eye angles", function() pace.ResetEyeAngles() end):SetImage("icon16/user_delete.png")
	menu:AddOption(L"reset zoom", function() pace.ResetZoom() end):SetImage("icon16/magnifier.png")

	local seq_cmdmenu, pnl2 = menu:AddSubMenu(L"sequenced command events") pnl2:SetImage("icon16/clock.png")
	seq_cmdmenu.GetDeleteSelf = function() return false end

	local full_cmdmenu, pnl3 = menu:AddSubMenu(L"full list of command events") pnl3:SetImage("icon16/clock_play.png")
	full_cmdmenu.GetDeleteSelf = function() return false end

	local full_proxymenu, pnl4 = menu:AddSubMenu(L"full list of command proxies") pnl4:SetImage("icon16/calculator.png")
	full_proxymenu.GetDeleteSelf = function() return false end

	local rebuild_events_menu
	local rebuild_seq_menu
	local rebuild_proxies_menu


	local rebuild_seq_menu = function()
		seq_cmdmenu:Clear()
		if pac.LocalPlayer.pac_command_event_sequencebases == nil then return end
		for cmd, tbl in pairs(pac.LocalPlayer.pac_command_event_sequencebases) do
			if tbl.max ~= 0 then
				local submenu, pnl3 = seq_cmdmenu:AddSubMenu(cmd) pnl3:SetImage("icon16/clock_red.png")
				submenu.GetDeleteSelf = function() return false end
				if tbl.min == nil then continue end
				for i=tbl.min,tbl.max,1 do
					local func_sequenced = function()
						RunConsoleCommand("pac_event_sequenced", cmd, "set", tostring(i,0)) rebuild_events_menu()
					end
					local option = submenu:AddOption(cmd..i,func_sequenced) option:SetIsCheckable(true) option:SetRadio(true)
					if i == tbl.current then option:SetChecked(true) end
					if pac.LocalPlayer.pac_command_events[cmd..i] then
						if pac.LocalPlayer.pac_command_events[cmd..i].on == 1  then
							option:SetChecked(true)
						end
					end
					function option:SetChecked(b)
						if ( self:GetChecked() != b ) then
							self:OnChecked( b )
						end
						self.m_bChecked = b
						if b then func_sequenced() end
						timer.Simple(0.4, rebuild_events_menu)
					end
				end
			end
		end
	end

	if pac.LocalPlayer.pac_command_event_sequencebases then
		if table.Count(pac.LocalPlayer.pac_command_event_sequencebases) > 0 then
			rebuild_seq_menu()
		end
	end

	rebuild_events_menu = function()
		full_cmdmenu:Clear()
		for cmd, b in SortedPairs(get_events()) do
			local option = full_cmdmenu:AddOption(cmd,function() RunConsoleCommand("pac_event", cmd, "2") end) option:SetIsCheckable(true)
			if b then option:SetChecked(true) end
			function option:OnChecked(b)
				if b then RunConsoleCommand("pac_event", cmd, "1") else RunConsoleCommand("pac_event", cmd, "0") end rebuild_seq_menu()
			end
			if pace.command_colors == nil then continue end
			if pace.command_colors[cmd] ~= nil then
				local clr = Color(unpack(string.Split(pace.command_colors[cmd]," ")))
				clr.a = 100
				option.PaintOver = function(_,w,h) surface.SetDrawColor(clr) surface.DrawRect(0,0,w,h) end
			end
		end
	end

	rebuild_proxies_menu = function()
		full_proxymenu:Clear()
		if pac.LocalPlayer.pac_proxy_events == nil then return end
		for cmd, tbl in SortedPairs(pac.LocalPlayer.pac_proxy_events) do
			local num = tbl.x
			if tbl.y ~= 0 or tbl.z ~= 0 then
				num = tbl.x .. " " .. tbl.y .. " " .. tbl.z
			end
			full_proxymenu:AddOption(cmd .. " : " .. num,function()
				Derma_StringRequest("Set new value for pac_proxy " .. cmd, "please input a number or spaced vector-notation.\n++ and -- notation is also supported for any component.\nit shall be used in a proxy expression as command(\""..cmd.."\")", num,
					function(str)
						local args = string.Split(str, " ")
						RunConsoleCommand("pac_proxy", cmd, unpack(args))
						timer.Simple(0.4, rebuild_proxies_menu)
					end)
			end)
		end
	end
	
	if pac.LocalPlayer.pac_command_events then
		if table.Count(pac.LocalPlayer.pac_command_events) > 0 then
			rebuild_events_menu()
		end
	end
	if pac.LocalPlayer.pac_proxy_events then
		if table.Count(pac.LocalPlayer.pac_proxy_events) > 0 then
			rebuild_proxies_menu()
		end
	end

	function pnl2:Think()
		if self:IsHovered() then
			if not self.isrebuilt then
				rebuild_events_menu()
				self.isrebuilt = true
			end
		else
			self.isrebuilt = false
		end
	end
	function pnl3:Think()
		if self:IsHovered() then
			if not self.isrebuilt then
				rebuild_seq_menu()
				self.isrebuilt = true
			end
		else
			self.isrebuilt = false
		end
	end
	function pnl4:Think()
		if self:IsHovered() then
			if not self.isrebuilt then
				rebuild_proxies_menu()
				self.isrebuilt = true
			end
		else
			self.isrebuilt = false
		end
	end

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

function pace.PopulateMenuBarTab(menu, tab)
	if tab == "pac" then
		populate_pac(menu)
	elseif tab == "player" then
		populate_player(menu)
	elseif tab == "options" then
		populate_options(menu)
	elseif tab == "view" then
		populate_view(menu)
	end
	--timer.Simple(0.3, function() menu:RequestFocus() end)
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
	--[[timer.Simple(0.2, function()
		if IsValid(bar) then
			bar:RequestFocus(true)
		end
	end)]]
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
