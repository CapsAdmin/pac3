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

net.Receive("pac_spawn_part", function()
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

	pnl:NumSlider(
		L"draw distance",
		"pac_draw_distance",
		0,
		20000,
		0
	)
	
	pnl:NumSlider(
		L"editor grid position size", 
		"pac_grid_pos_size",
		0, 
		64,
		0		
	)
	
	pnl:NumSlider(
		L"editor grid angle size", 
		"pac_grid_ang_size",
		0, 
		360,
		0
	)
	
	pnl:Button(	
		L"convert active pac2 outfit",
		"pac_convert_pac2_config"
	)	
end

list.Set(
	"DesktopWindows", 
	"PACEditor",
	{
		title           = "PAC Editor",
		icon            = "icon64/playermodel.png",
		width           = 960,
		height          = 700,
		onewindow       = true,
		init            = function()
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