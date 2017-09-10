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
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)

		if g_SpawnMenu:IsVisible() then
			g_SpawnMenu:Close()
		end

		pace.close_spawn_menu = false
	elseif pace.current_part.ClassName ~= "model" then
		local name = mdl:match(".+/(.+)%.mdl")

		pace.Call("CreatePart", "model", name, mdl)
	else
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)
	end
end)

pace.SpawnlistBrowser = NULL

function pace.ClientOptionsMenu(pnl)
	pnl:Button(L"show editor", "pac_editor")
	pnl:CheckBox(L"enable", "pac_enable")
	pnl:Button(L"clear", "pac_clear_parts")
	pnl:Button(L"wear on server", "pac_wear_parts"	)

	local browser = pnl:AddControl("pace_browser", {})

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

	pnl:Button(L"request outfits", "pac_request_outfits")
	pnl:Button(L"panic", "pac_panic")
end

function pace.ClientSettingsMenu(pnl)
	pnl:Help(L"Performance"):SetFont("DermaDefaultBold")
		pnl:CheckBox(L"Enable PAC", "pac_enable")
		pnl:NumSlider(L"Draw distance:", "pac_draw_distance", 0, 20000, 0)
		pnl:NumSlider(L"Max render time: ", "pac_max_render_time", 0, 50, 0)

	pnl:CheckBox(
		L"Enable PAC",
		"pac_enable"
	)

	pnl:CheckBox(
		L"Friend only",
		"pac_friendonly"
	)

	pnl:NumSlider(
		L"PAC Volume",
		"pac_ogg_volume",
		0,
		1,
		2
	)

	pnl:CheckBox(L"no outfit reflections", "pac_suppress_frames")
	pnl:CheckBox(L"render objects outside visible fov", "pac_override_fov")
	pnl:CheckBox(L"render projected textures (flashlight)", "pac_render_projected_texture")

	pnl:Help(L"Misc"):SetFont("DermaDefaultBold")
		pnl:NumSlider(L"PAC Volume", "pac_ogg_volume", 0, 1, 2)
		pnl:CheckBox(L"Custom error model", "pac_error_mdl")

	pnl:Help(L"Enable"):SetFont("DermaDefaultBold")
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
		pnl:CheckBox(L(str), "pac_enable_" .. str)
	end


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

hook.Add("PopulateToolMenu", "pac3_spawnmenu", function()
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
