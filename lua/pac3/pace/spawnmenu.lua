local L = pace.LanguageString

concommand.Add("pac_wear_session", function()
	for key, part in pairs(pac.GetParts(true)) do
		if not part:HasParent() then
			pac.SendPartToServer(part)
		end
	end
end)

concommand.Add("pac_clear_session", function()
	pac.RemoveAllParts(true, true)
	pace.RefreshTree()
end)

pace.SpawnlistBrowser = NULL

function pace.ClientOptionsMenu(pnl)
	pnl:AddControl("Button", {
		Label = L"show editor",
		Command = "pac_editor",
	})
	local browser = pnl:AddControl("pace_browser", {})
	
	browser.OnLoad = function(node)
		pace.LoadSession(node.FileName)
	end
	browser:SetDir("sessions/")
	browser:SetSize(400,700)
	
	pace.SpawnlistBrowser = browser
	
	pnl:AddControl("Button", {
		Label = L"wear on server",
		Command = "pac_wear_session",
	})	
	pnl:AddControl("Button", {
		Label = L"clear",
		Command = "pac_clear_session",
	})	

	pnl:AddControl("Slider", {
		Label = L"draw distance",
		Command = "pac_draw_distance",
		min = 0,
		max = 20000,
	})
	
	pnl:AddControl("Button", {
		Label = L"convert active pac2 outfit",
		Command = "pac_convert_pac2_config",
	})	
end

hook.Add("PopulateToolMenu", "pac3_spawnmenu", function()
	spawnmenu.AddToolMenuOption(
		"Options", 
		"PAC",  
		"PAC3", 
		L"PAC3", 
		"", 
		"",
		pace.ClientOptionsMenu,  
		{ 
			SwitchConVar = "pac_enable" 
		}
	)
end)