local L = pace.LanguageString
local L = pace.LanguageString

function pace.OnMenuBarPopulate(bar)
	for k,v in pairs(bar.Menus) do
		v:Remove()
	end

	local menu = bar:AddMenu("pac")
			local save, pnl = menu:AddSubMenu(L"save", function() pace.SaveParts() end)
			pnl:SetImage(pace.MiscIcons.save)
			pace.AddSaveMenuToMenu(save)

			local load, pnl = menu:AddSubMenu(L"load", function() pace.LoadParts(nil, true) end)
			pnl:SetImage(pace.MiscIcons.load)
			pace.AddSavedPartsToMenu(load, true)

			menu:AddOption(L"wear", function() pace.WearParts() end):SetImage(pace.MiscIcons.wear)

			local clear, pnl = menu:AddSubMenu(L"clear", function() end)
			pnl:SetImage(pace.MiscIcons.clear)
			clear.GetDeleteSelf = function() return false end
			clear:AddOption(L"OK", function() pace.ClearParts() end):SetImage(pace.MiscIcons.clear)
		menu:AddSpacer()

			local help, pnl = menu:AddSubMenu(L"help", function() pace.ShowWiki() end)
			help.GetDeleteSelf = function() return false end
			pnl:SetImage(pace.MiscIcons.help)

			help:AddOption(
				L"Getting Started",
				function() pace.ShowWiki(pace.WikiURL .. "Beginners-FAQ") end
			):SetImage(pace.MiscIcons.help)

			menu:AddOption(
				L"about",
				function() pace.ShowAbout() end
			):SetImage(pace.MiscIcons.about)

		menu:AddOption(L"exit", function() pace.CloseEditor() end):SetImage(pace.MiscIcons.exit)

	local menu = bar:AddMenu(L"view")
		menu:AddOption(L"hide editor", function() pace.Call("ToggleFocus") chat.AddText("[pac3] \"ctrl + e\" to get the editor back") end)
		menu:AddCVar(L"camera follow", "pac_camera_follow_entity", "1", "0")
		menu:AddOption(L"reset view position", function() pace.ResetView() end)

	local menu = bar:AddMenu(L"options")
		menu:AddCVar(L"show deprecated features", "pac_show_deprecated", "1", "0").DoClick = function() pace.ToggleDeprecatedFeatures() end
		menu:AddCVar(L"advanced mode", "pac_basic_mode", "0", "1").DoClick = function() pace.ToggleBasicMode() end
		menu:AddCVar(L"put parts in submenu", "pac_submenu_parts", "1", "0")
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
		menu:AddSpacer()

		menu:AddCVar(L"automatic property size", "pac_auto_size_properties", "1", "0")
		pace.AddLanguagesToMenu(menu)
		pace.AddFontsToMenu(menu)

		menu:AddSpacer()

		local rendering = menu:AddSubMenu(L"rendering", function() end)
			rendering.GetDeleteSelf = function() return false end
			rendering:AddCVar(L"draw in reflections", "pac_suppress_frames", "0", "1")

	local menu = bar:AddMenu(L"player")
		menu:AddCVar(L"t pose").OnChecked = function(s, b) pace.SetTPose(b) end
		menu:AddOption(L"reset eye angles", function() pace.ResetEyeAngles() end)

		local mods = menu:AddSubMenu(L"modifiers", function() end)
			mods.GetDeleteSelf = function() return false end
			for name in pairs(pac.GetServerModifiers()) do
				mods:AddCVar(L(name), "pac_modifier_" .. name, "1", "0")
			end

	local menu = bar:AddMenu(L"tools")
		pace.AddToolsToMenu(menu)

	bar:RequestFocus(true)
end

function pace.OnOpenMenu()
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())

		menu:AddOption(L"save parts", function() pace.SaveParts() end)
		menu:AddOption(L"load parts", function() pace.LoadParts(nil, true) end)
		menu:AddOption(L"wear parts", function() pace.WearParts() end)
		menu:AddSubMenu(L"clear parts", function()end):AddOption(L"OK", function() pace.ClearParts() end)

	menu:AddSpacer()

		menu:AddOption(L"toggle basic mode", function() pace.ToggleBasicMode() end)
		menu:AddOption(L"toggle t pose", function() pace.SetTPose(not pace.GetTPose()) end)
		menu:AddOption(L"toggle focus", function() pace.Call("ToggleFocus") chat.AddText("[pac3] \"ctrl + e\" to get the editor focus back") end)
		menu:AddOption(L"disable input", function() pace.Call("ToggleFocus", true) chat.AddText("[pac3] \"ctrl + e\" to get the editor focus back") end)
		menu:AddOption(L"toggle camera follow", function() pace.ToggleCameraFollow() end)
		menu:AddOption(L"reset eye angles", function() pace.ResetEyeAngles() end)
		menu:AddOption(L"reset view", function() pace.ResetView() end)

	menu:AddSpacer()

		pace.AddLanguagesToMenu(menu)
		pace.AddFontsToMenu(menu)

	menu:AddSpacer()

		menu:AddOption(L"help", function() pace.ShowWiki() end)

	menu:Open()
	menu:MakePopup()
end