local L = pace.LanguageString

concommand.Add("pac_wear_parts", function(ply, _, _, file)
	if file then
		file = string.Trim(file)
		if file ~= "" then
			pace.LoadParts(string.Trim(string.Replace(file, "\"", "")), true)
		end
	end

	pace.WearParts()
end,
function(cmd, args)
	-- Replace \ with /
	args = string.Trim(string.Replace(args, "\\", "/"))

	-- Find path
	local path = ""
	local slashPos = string.find(args, "/[^/]*$")
	if slashPos then
		-- Set path to the directory without the file name
		path = string.sub(args, 1, slashPos)
	end

	-- Find files and directories
	local files, dirs = file.Find("pac3/" .. args .. "*", "DATA")
	if not dirs then return end

	-- Format directories
	for k, v in ipairs(dirs) do
		dirs[k] = v .. "/"
	end

	-- Format results
	for k, v in ipairs(table.Add(dirs, files)) do
		dirs[k] = cmd .. " " .. path .. v
	end

	return dirs
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
		pace.Call("CreatePart", "model2", name, mdl)
	else
		pace.RecordUndoHistory()
		pace.Call("VariableChanged", pace.current_part, "Model", mdl)
	end
end)

pace.SpawnlistBrowser = NULL

function pace.ClientOptionsMenu(self)
	if not IsValid(self) then return end

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
end

function pace.ClientSettingsMenu(self)
	if not IsValid(self) then return end
	self:Help(L"Performance"):SetFont("DermaDefaultBold")
		self:CheckBox(L"Enable PAC", "pac_enable")
		self:NumSlider(L"Draw distance:", "pac_draw_distance", 0, 20000, 0)
		self:NumSlider(L"Max render time: ", "pac_max_render_time", 0, 100, 0)
end



local icon_cvar = CreateConVar("pac_icon", "0", {FCVAR_ARCHIVE}, "Use the new PAC4.5 icon or the old PAC icon.\n0 = use the old one\n1 = use the new one")
local icon = icon_cvar:GetBool() and "icon64/new pac icon.png" or "icon64/pac3.png"

icon = file.Exists("materials/"..icon,'GAME') and icon or "icon64/playermodel.png"

local function ResetPACIcon()
	if icon_cvar:GetBool() then icon = "icon64/new pac icon.png" else icon = "icon64/pac3.png" end
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
	RunConsoleCommand("spawnmenu_reload")
end

cvars.AddChangeCallback("pac_icon", ResetPACIcon)

concommand.Add("pac_change_icon", function() RunConsoleCommand("pac_icon", (not icon_cvar:GetBool()) and "1" or "0") ResetPACIcon() end)


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
