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
	local save, pnl = menu:AddSubMenu(L"save", function() pace.SaveParts() end)
	save:SetDeleteSelf(false)
	pnl:SetImage(pace.MiscIcons.save)
	add_expensive_submenu_load(pnl, function() pace.AddSaveMenuToMenu(save) end)

	local load, pnl = menu:AddSubMenu(L"load", function() pace.LoadParts(nil, true) end)
	load:SetDeleteSelf(false)
	pnl:SetImage(pace.MiscIcons.load)
	add_expensive_submenu_load(pnl, function() pace.AddSavedPartsToMenu(load, true) end)

	menu:AddOption(L"wear", function() pace.WearParts() end):SetImage(pace.MiscIcons.wear)

	local clear, pnl = menu:AddSubMenu(L"clear", function() end)
	pnl:SetImage(pace.MiscIcons.clear)
	clear.GetDeleteSelf = function() return false end
	clear:AddOption(L"OK", function() pace.ClearParts() end):SetImage(pace.MiscIcons.clear)

	menu:AddSpacer()

	local help, help_pnl = menu:AddSubMenu(L"help", function() pace.ShowWiki() end)
	help.GetDeleteSelf = function() return false end
	help_pnl:SetImage(pace.MiscIcons.help)

	help:AddOption(
		L"Getting Started",
		function() pace.ShowWiki(pace.WikiURL .. "Beginners-FAQ") end
	):SetImage(pace.MiscIcons.info)

	local chat_pnl = help:AddOption(
		L"Discord / PAC3 Chat",
		function() gui.OpenURL("https://discord.gg/utpR3gJ") cookie.Set("pac3_discord_ad", 3)  end
	) chat_pnl:SetImage(pace.MiscIcons.chat)

	if cookie.GetNumber("pac3_discord_ad", 0) < 3 then
		help_pnl.PaintOver = function(_,w,h) surface.SetDrawColor(255,255,0,50 + math.sin(SysTime()*20)*20) surface.DrawRect(0,0,w,h) end
		chat_pnl.PaintOver = help_pnl.PaintOver
		cookie.Set("pac3_discord_ad", cookie.GetNumber("pac3_discord_ad", 0) + 1)
	end

	menu:AddOption(L"exit", function() pace.CloseEditor() end):SetImage(pace.MiscIcons.exit)
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
		rendering:AddCVar(L"render objects outside visible fov", "pac_override_fov", "1", "0")
		rendering:AddCVar(L"render projected textures (flashlight)", "pac_render_projected_texture", "1", "0")
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