local L = pace.LanguageString

concommand.Add("pac_wear_session", function()
	pace.WearSession()
end)

concommand.Add("pac_clear_session", function()
	pace.ClearSession()
end)

net.Receive("pac_spawn_part", function()
	if not pace.current_part:IsValid() then return end
	
	local mdl = net.ReadString()
	
	if pace.close_spawn_menu then
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)
	
		if g_SpawnMenu:IsVisible() then
			g_SpawnMenu:Close()
		end
		
		pace.close_spawn_menu = false
	elseif pace.current_part.ClassName ~= "model" then
		local name = mdl:match(".+/(.+)%.mdl")
		
		pace.Call("CreatePart", "model", name, nil, mdl)
	else
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)
	end
end)

pace.SpawnlistBrowser = NULL

function pace.ClientOptionsMenu(pnl)
	pnl:Button(
		L"show editor",
		"pac_editor"
	)
	
	pnl:CheckBox(
		L"enable",
		"pac_enable"
	)	

	pnl:NumSlider(
		L"draw distance",
		"pac_draw_distance",
		0,
		20000,
		0
	)
	
	local browser = pnl:AddControl("pace_browser", {})
	
	browser.OnLoad = function(node)
		pace.LoadSession(node.FileName)
	end
	browser:SetDir("sessions/")
	browser:SetSize(400,700)
	
	pace.SpawnlistBrowser = browser
	
	pnl:Button(
		L"wear on server",
		"pac_wear_session"
	)	
	
	pnl:Button(
		L"clear",
		"pac_clear_session"
	)	
end

list.Set(
	"DesktopWindows", 
	"PACEditor",
	{
		title = "PAC Editor",
		icon = "icon64/playermodel.png",
		width = 960,
		height = 700,
		onewindow = true,
		init = function(icn, pnl)
			pnl:Remove()
			pace.OpenEditor()
		end
	}
)

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
			SwitchConVar = "pac_enable",
		}
	)
end)