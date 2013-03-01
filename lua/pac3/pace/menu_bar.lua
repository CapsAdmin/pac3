local L = pace.LanguageString
local L = pace.LanguageString

function pace.OnMenuBarPopulate(bar)
	local menu = bar:AddMenu("pac")
			menu:AddOption(L"save", function() pace.SaveSession() end)
			pace.AddSessionsToMenu(menu:AddSubMenu(L"load", function() pace.LoadSession() end))		
			menu:AddOption(L"wear", function() pace.WearSession() end)
			local clear = menu:AddSubMenu(L"clear", function() end)
			clear.GetDeleteSelf = function() return false end
			clear:AddOption(L"OK", function() pace.ClearSession() end)
		menu:AddSpacer()
			menu:AddOption(L"help", function() pace.ShowWiki() end)
			menu:AddOption(L"exit", function() pace.CloseEditor() end)
	
	local menu = bar:AddMenu(L"view")
		menu:AddOption(L"hide editor", function() pace.Call("ToggleFocus") chat.AddText("[pac3] \"ctrl + e\" to get the editor back") end)
		menu:AddCVar(L"camera follow", "pac_camera_follow_entity", "1", "0")
		menu:AddOption(L"reset view position", function() pace.ResetView() end)

	local menu = bar:AddMenu(L"options")
		menu:AddCVar(L"show deprecated features", "pac_show_deprecated", "1", "0").DoClick = function() pace.ToggleDeprecatedFeatures() end
		menu:AddCVar(L"advanced mode", "pac_basic_mode", "0", "1").DoClick = function() pace.ToggleBasicMode() end
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
		pace.AddLanguagesToMenu(menu)
		pace.AddFontsToMenu(menu)
		
		menu:AddSpacer()
		
		local rendering = menu:AddSubMenu(L"rendering", function() end)
			rendering.GetDeleteSelf = function() return false end
			rendering:AddCVar(L"draw in reflections", "pac_suppress_frames", "1", "0")
		
	local menu = bar:AddMenu(L"player")
		menu:AddCVar(L"t pose").OnChecked = function(s, b) pace.SetTPose(b) end
		menu:AddOption(L"reset eye angles", function() pace.ResetEyeAngles() end)		
		menu:AddCVar(L"physical player size", "pac_server_player_size", "1", "0")
		
	local menu = bar:AddMenu(L"tools")
		pace.AddToolsToMenu(menu)
		
	bar:RequestFocus(true)
end

function pace.OnOpenMenu()
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
	
		menu:AddOption(L"save session", function() pace.SaveSession() end)
		menu:AddOption(L"load session", function() pace.LoadSession() end)
		menu:AddOption(L"wear session", function() pace.WearSession() end)
		menu:AddSubMenu(L"clear session", function()end):AddOption(L"OK", function() pace.ClearSession() end)
		
	menu:AddSpacer()
		
		menu:AddOption(L"toggle basic mode", function() pace.ToggleBasicMode() end)
		menu:AddOption(L"toggle t pose", function() pace.SetTPose(not pace.GetTPose()) end)
		menu:AddOption(L"toggle focus", function() pace.Call("ToggleFocus") chat.AddText("[pac3] \"ctrl + e\" to get the editor focus back") end)
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