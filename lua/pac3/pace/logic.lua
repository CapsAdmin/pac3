pace.current_part = pac.NULL
pace.properties = NULL
pace.tree = NULL

local L = pace.LanguageString

function pace.SetViewPart(part, reset_campos)	
	pace.SetViewEntity(part:GetOwner())

	if reset_campos then
		pace.ResetView()
	end	
end

function pace.PopulateProperties(part)
	if pace.properties:IsValid() then
		pace.properties:Populate(part)
	end
end

function pace.OnDraw()
	pace.mctrl.HUDPaint()
end

function pace.OnPartSelected(part, is_selecting)
	local owner = part:GetOwner()
	if owner:IsValid() and owner:GetClass() == "viewmodel" then
		pace.editing_viewmodel = true
	elseif pace.editing_viewmodel then
		pace.editing_viewmodel = false
	end

	pace.PopulateProperties(part)
	pace.mctrl.SetTarget(part)
	pace.current_part = part
	
	pace.SetViewPart(part)
	
	pace.Editor:InvalidateLayout()
	
	pace.SafeRemoveSpecialPanel()
	
	if pace.tree:IsValid() then
		pace.tree:SelectPart(part)
	end
	
	if not is_selecting then
		pace.StopSelect()
	end
end

function pace.OnCreatePart(class_name, name, desc, mdl)
	local part = pac.CreatePart(class_name)
	part:SetName(name or (L(class_name) .. " " .. (pac.GetPartCount(class_name)) + 1))
	
	local parent = pace.current_part
	
	if parent:IsValid() then	
		part:SetParent(parent)
	end
	
	if desc then part:SetDescription(desc) end
	if mdl then part:SetModel(mdl) end
		
	if part:GetPlayerOwner() == LocalPlayer() then
		pace.SetViewPart(part)
	end

	pace.OnPartSelected(part)
	
	part.newly_created = true
	
	pace.RefreshTree()	
end

function pace.OnVariableChanged(obj, key, val, undo_delay)
	local func = obj["Set" .. key]
	if func then
	
		-- no change
		--if obj[key] == val then return end
	
		if key == "OwnerName" then
			if val == "viewmodel" then
				pace.editing_viewmodel = true
			elseif obj[key] == "viewmodel" then
				pace.editing_viewmodel = false
			end
		end
		
		func(obj, val)
	
		pace.CallChangeForUndo(obj, key, val, undo_delay)
		
		local node = obj.editor_node
		if IsValid(node) then			
			if key == "Name" then
				if not obj:HasParent() then
					pac.RemovePartOnServer(obj:GetName(), true)
				end
				node:SetText(val)
			elseif key == "Model" and val and val ~= "" then
				node:SetModel(val)
			elseif key == "Parent" then
				local tree = obj.editor_node
				if IsValid(tree) then
					node:Remove()
					tree = tree:GetRoot()
					if tree:IsValid() then
						tree:SetSelectedItem(nil)
						pace.RefreshTree(true)
					end
				end
			end
		end
	end
	
	timer.Create("autosave_session", 0.5, 1, function()
		pace.SaveSession("autosave")
	end)
end

hook.Add("pac_OnPartParent", "pace_parent", function(parent, child)
	pace.OnVariableChanged(parent, "Parent", child)
end)

pace.OnUndo = pace.Undo
pace.OnRedo = pace.Redo

function pace.SavePartToFile(part, name)
	if not name then
		Derma_StringRequest(
			L"save part",
			L"filename:",
			part:GetName(),

			function(name)
				pace.SavePartToFile(part, name)
			end
		)
	else
		pac.dprint("saving %s", name)
		file.CreateDir("pac3")
		pac.luadata.WriteFile("pac3/" .. name .. ".txt", part:ToTable())
	end
end

function pace.LoadPartFromFile(part, name)
	if not part:IsValid() then return end
	
	if not name then
		
		local frm = vgui.Create("DFrame")
		frm:SetTitle(L"parts")
		local pnl = pace.CreatePanel("browser", frm)
		pnl:Dock(FILL)
		
		local btn = vgui.Create("DButton", frm)
		btn:Dock(BOTTOM)
		btn:SetText(L"load from url")
		btn.DoClick = function()
			Derma_StringRequest(
				L"load part",
				L"pastebin urls also work!",
				"",

				function(name)
					pace.LoadPartFromFile(part, name)
				end
			)
		end
		
		frm:SetSize(300, 500)
		frm:MakePopup()
		frm:Center()
	else
		pac.dprint("loading %s",  name)
		
		if name:find("http") then	
			name = name:gsub("https://", "http://")
			
			if name:lower():find("pastebin.com") then
				name = name:gsub(".com/", ".com/raw.php?i=")
			end
			
			local function callback(str)
				local data = pac.luadata.Decode(str)
		
				if data and data.self then
					if part:IsValid() then
						part:Clear()	
						part:SetTable(data)
					end
				else
					ErrorNoHalt("pac3 tried to load non existant part " .. name)
				end
				
				if IsValid(part.editor_node) then
					part.editor_node:SetText(part:GetName())
				end
			end
			
			http.Fetch(name, callback)	
			
			pace.RefreshTree()
		else
			name = name:gsub("%.txt", "")
			local data = pac.luadata.ReadFile("pac3/" .. name .. ".txt")
			if data and data.self then
				if part:IsValid() then
					part:Clear()	
					part:SetTable(data)
				end
			else
				ErrorNoHalt("pac3 tried to load non existant part " .. name)
			end
			
			if IsValid(part.editor_node) then
				part.editor_node:SetText(part:GetName())
			end
			
			pace.RefreshTree(true)
		end
	end
end

function pace.SaveSession(name)
	if not name then
		Derma_StringRequest(
			L"save session",
			L"filename:",
			pace.LastSaveName or "autoload",

			function(name)
				pace.LastSaveName = name
				pace.SaveSession(name)
			end
		)
	else
		pac.dprint("saving session %s", name)
		
		local data = {}
		
		for key, part in pairs(pac.GetParts(true)) do
			if not part:HasParent() then
				table.insert(data, part:ToTable())
			end
		end
		
		file.CreateDir("pac3")
		file.CreateDir("pac3/sessions")
		pac.luadata.WriteFile("pac3/sessions/" .. name .. ".txt", data)
		
		if pace.SpawnlistBrowser:IsValid() then
			pace.SpawnlistBrowser:PopulateFromClient()
		end
	end
end

function pace.LoadSession(name, append)
	if not name then
		local frm = vgui.Create("DFrame")
		frm:SetTitle(L"sessions")
		local pnl = pace.CreatePanel("browser", frm)
		
		pnl.OnLoad = function(node)
			pace.LoadSession(node.FileName)
		end
		pnl:SetDir("sessions/")
		
		pnl:Dock(FILL)
		
		frm:SetSize(300, 500)
		frm:MakePopup()
		frm:Center()
		
		
		local btn = vgui.Create("DButton", frm)
		btn:Dock(BOTTOM)
		btn:SetText(L"load from url")
		btn.DoClick = function()
			Derma_StringRequest(
				L"load part",
				L"pastebin urls also work!",
				"",

				function(name)
					pace.LoadSession(name, append)
				end
			)
		end
		
	else
		pac.dprint("loading session %s",  name)
		
		if not append then
			for key, part in pairs(pac.GetParts(true)) do
				if not part:HasParent() then
					pac.RemovePartOnServer(part:GetName(), nil, true)
					part:Remove()
				end
			end
		end
		
		if name:find("http") then	
			name = name:gsub("https://", "http://")
			
			if name:lower():find("pastebin.com") then
				name = name:gsub(".com/", ".com/raw.php?i=")
			end
			
			local function callback(str)
				local data = pac.luadata.Decode(str)
		
				for key, tbl in pairs(data) do
					local part = pac.CreatePart(tbl.self.ClassName)
					part:SetTable(tbl)
				end
				
				pace.RefreshTree(true)
			end
			
			http.Fetch(name, callback)		
		else
			name = name:gsub("%.txt", "")
		
			local data = pac.luadata.ReadFile("pac3/sessions/" .. name .. ".txt")
			
			timer.Simple(0.1, function()				
				for key, tbl in pairs(data) do
					local part = pac.CreatePart(tbl.self.ClassName)
					part:SetTable(tbl)
				end
				
				pace.RefreshTree(true)
			end)
			
		end
	end
end

function pace.WearSession()
	for key, part in pairs(pac.GetParts(true)) do
		if not part:HasParent() then
			pac.SendPartToServer(part)
		end
	end
end

function pace.ClearSession()
	pac.RemoveAllParts(true, true)
	pace.RefreshTree()
end

hook.Add("InitPostEntity", "pace_autoload_session", function()	
	timer.Simple(5, function()
		pace.LoadSession("autoload")
		timer.Simple(3, function()
		-- give pac some time to solve bones and parents
			for key, part in pairs(pac.GetParts(true)) do
				if not part:HasParent() then
					pac.SendPartToServer(part)
				end
			end
		end)
	end)
end)

local font_cvar = CreateClientConVar("pac_editor_font", pace.Fonts[1])

function pace.SetFont(fnt)
	pace.CurrentFont = fnt or font_cvar:GetString()
	RunConsoleCommand("pac_editor_font", pace.CurrentFont)
	
	if pace.Editor and pace.Editor:IsValid() then
		pace.CloseEditor()
		timer.Simple(0.1, function()
			pace.OpenEditor()
		end)
	end
end

function pace.ToggleCameraFollow()
	local c = GetConVar("pac_camera_follow_entity")
	RunConsoleCommand("pac_camera_follow_entity", c:GetBool() and "0" or "1")
end

pace.SetFont()

function pace.ResetEyeAngles()
	local ent = pace.GetViewEntity()
	if ent:IsValid() then
		if ent:IsPlayer() then
			
			RunConsoleCommand("+forward")
			timer.Simple(0, function() 
				RunConsoleCommand("-forward") 
				timer.Simple(0.1, function()
					RunConsoleCommand("+back")
					timer.Simple(0.015, function() 
						RunConsoleCommand("-back")
					end)
				end)
			end)
			
			ent:SetEyeAngles(Angle(0, 0, 0))
		else
			ent:SetAngles(Angle(0, 0, 0))
		end
	
		ent:SetupBones()
	end
end
function pace.AddLanguagesToMenu(menu)
	local menu = menu:AddSubMenu(L"language")
	menu.GetDeleteSelf = function() return false end
	menu:AddOption("english", function()
		pace.SetLanguage("english")
	end)
	
	for key, val in pairs(file.Find("pac3/pace/translations/*", "LUA")) do
		val = val:gsub("%.lua", "")
		menu:AddOption(val, function()
			pace.SetLanguage(val)
		end)
	end
end

function pace.AddFontsToMenu(menu)
	local menu = menu:AddSubMenu(L"font")
	menu.GetDeleteSelf = function() return false end
	
	for key, val in pairs(pace.Fonts) do
		menu:AddOption(val, function()
			pace.SetFont(val)
		end)
		
		local pnl = menu.Items and menu.Items[#menu.Items]
		
		if pnl and pnl:IsValid() then
			pnl:SetFont(val)
			if pace.ShadowedFonts[val] then
				pnl:SetTextColor(derma.Color("text_bright", pnl, color_white))
			else
				pnl:SetTextColor(derma.Color("text_dark", pnl, color_black))
			end
		end
	end
end

function pace.GetOutfits()
	local out = {}
	
	for i, name in pairs(file.Find("pac3/sessions/*", "DATA")) do
		if name:find("%.txt") then
			local outfit = "pac3/sessions/" .. name
			if file.Exists(outfit, "DATA") then
				local data = {}
					data.Name = name:gsub("%.txt", "")
					data.FileName = name
					data.Size = string.NiceSize(file.Size(outfit, "DATA"))
					data.LastModified = os.date("%m/%d/%Y %H:%M", file.Time(outfit, "DATA"))
				table.insert(out, data)
			end
		end
	end
	
	return out
end

function pace.AddOutfitsToMenu(menu)
	menu.GetDeleteSelf = function() return false end
	for key, data in pairs(pace.GetOutfits()) do
		local menu = menu:AddSubMenu(data.Name, function() pace.LoadSession(data.FileName) end)
		menu.GetDeleteSelf = function() return false end
		menu:AddOption(L"rename", function()
			Derma_StringRequest(L"rename", L"type the new name:", data.Name, function(text)
				
				local c = file.Read(data.FileName)
				file.Delete(data.FileName, "DATA")
				file.Write(data.FileName, c, "DATA")
			end)
		end)
		
		local clear = menu:AddSubMenu(L"delete", function() end)
		clear.GetDeleteSelf = function() return false end
		clear:AddOption(L"OK", function() file.Delete("pac3/sessions/" .. data.FileName, "DATA") end)
	end
end

function pace.AddToolsToMenu(menu)
	menu.GetDeleteSelf = function() return false end
	for key, data in pairs(pace.Tools) do
		if #data.suboptions > 0 then
			local menu = menu:AddSubMenu(data.name)
			menu.GetDeleteSelf = function() return false end
			for key, option in pairs(data.suboptions) do
				menu:AddOption(option, function() 
					if pace.current_part:IsValid() then
						data.callback(pace.current_part, key) 
					end
				end)
			end
		else
			menu:AddOption(data.name, function() 
				if pace.current_part:IsValid() then
					data.callback(pace.current_part) 
				end
			end)
		end
	end
end

function pace.OnMenuBarPopulate(bar)
	local menu = bar:AddMenu("pac")
			menu:AddOption(L"save", function() pace.SaveSession() end)
			pace.AddOutfitsToMenu(menu:AddSubMenu(L"load", function() pace.LoadSession() end))		
			menu:AddOption(L"wear", function() pace.WearSession() end)
			local clear = menu:AddSubMenu(L"clear", function() end)
			clear.GetDeleteSelf = function() return false end
			clear:AddOption(L"OK", function() pac.ClearSession() end)
		menu:AddSpacer()
			menu:AddOption(L"help", function() pace.ShowWiki() end)
			menu:AddOption(L"exit", function() pace.CloseEditor() end)
	
	local menu = bar:AddMenu(L"view")
		menu:AddOption(L"hide editor", function() pace.Call("ToggleFocus") chat.AddText("[pac3] \"ctrl + e\" to get the editor back") end)
		menu:AddCVar(L"camera follow", "pac_camera_follow_entity", "1", "0")
		menu:AddOption(L"reset view position", function() pace.ResetView() end)

	local menu = bar:AddMenu(L"options")
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
		
	local menu = bar:AddMenu(L"player")
		menu:AddCVar(L"t pose").OnChecked = function(s, b) pace.SetTPose(b) end
		menu:AddOption(L"reset eye angles", function() pace.ResetEyeAngles() end)		
		menu:AddCVar(L"physical player size", "pac_allow_server_size", "1", "0")
		
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
		menu:AddSubMenu(L"clear session", function()end):AddOption(L"OK", function() pac.ClearSession() end)
		
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

local function add_parts(menu)
	local temp = {}
	
	for class_name, tbl in pairs(pac.GetRegisteredParts()) do
		if pace.IsInBasicMode() and not pace.BasicParts[class_name] then continue end
		if not tbl.Internal then
			table.insert(temp, class_name)
		end
	end
	
	table.sort(temp)
	
	for _, class_name in pairs(temp) do
		menu:AddOption(L(class_name), function()
			pace.Call("CreatePart", class_name)
		end):SetImage(pace.PartIcons[class_name])
	end
end

function pace.OnPartMenu(obj)
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
		
	if not obj:HasParent() then
		menu:AddOption(L"wear", function()
			pac.SendPartToServer(obj)
		end)
	end

	menu:AddOption(L"copy", function()
		local tbl = obj:ToTable()
			tbl.self.Name = nil
			tbl.self.Description = nil
			tbl.self.ParentName = nil
			tbl.self.Parent = nil
			tbl.self.UniqueID = nil
			
			tbl.children = {}
		pace.Clipboard = tbl
	end)
	
	if type(pace.Clipboard) == "table" then
		menu:AddOption(L"paste", function()
			obj:SetTable(pace.Clipboard)
			pace.Clipboard = nil
		end)
	end
	
	menu:AddOption(L"clone", function()
		obj:Clone()
	end)
	
	menu:AddSpacer()

	add_parts(menu)

	menu:AddSpacer()

	menu:AddOption(L"save", function()
		pace.SavePartToFile(obj)
		CloseDermaMenus()
	end)

	menu:AddOption(L"load", function()
		pace.LoadPartFromFile(obj)
		CloseDermaMenus()
	end)
	
	menu:AddOption(L"remove", function()
		obj:Remove()
		pace.RefreshTree()
	end)

	menu:Open()
	menu:MakePopup()
end

function pace.OnNewPartMenu()
	pace.current_part = pac.NULL
	local menu = DermaMenu()
	menu:MakePopup()
	menu:SetPos(gui.MousePos())
	
	add_parts(menu)
	
	menu:AddSpacer()
		
	menu:AddOption(L"load", function()
		local obj = pac.CreatePart("group")
		pace.OnPartSelected(obj)
		pace.LoadPartFromFile(obj)
		CloseDermaMenus()
	end)
	
	menu:AddOption(L"clear", function()
		pac.RemoveAllParts(true, true)
		pace.RefreshTree()
	end)
end

function pace.OnHoverPart(obj)
	obj:Highlight()
end

function pace.OnOpenEditor()
	pace.SetViewPos(LocalPlayer():EyePos())
	pace.SetViewAngles(LocalPlayer():EyeAngles())
	pace.EnableView(true)
	
	if table.Count(pac.GetParts(true)) == 0 then
		pace.Call("CreatePart", "group", L"my outfit", L"add parts to me!")
	else
		pace.OnPartSelected(select(2, next(pac.GetParts(true))))
	end
	
	pace.ResetView()
end

function pace.OnCloseEditor()
	pace.EnableView(false)
	pace.StopSelect()
	pace.SafeRemoveSpecialPanel()
end

function pace.OnShortcutSave()
	if pace.current_part:IsValid() then
		local part = pace.current_part:GetRootPart()
		pace.SavePartToFile(part, part:GetName())
		surface.PlaySound("buttons/button9.wav")
	end
end

function pace.OnShortcutWear()
	if pace.current_part:IsValid() then
		local part = pace.current_part:GetRootPart()
		pac.SendPartToServer(part)
		surface.PlaySound("buttons/button9.wav")
	end
end

function pace.OnToggleFocus()
	if pace.Focused then
		pace.KillFocus()
	else
		pace.GainFocus()
	end
end

local last = 0

function pace.CheckShortcuts()
	if pace.Editor and pace.Editor:IsValid() then
		if last > CurTime() or input.IsMouseDown(MOUSE_LEFT) then return end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_M) then
			pace.Call("ShortcutSave")
			last = CurTime() + 0.2
		end
		
		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_N) then
			pace.Call("ShortcutWear")
			last = CurTime() + 0.2
		end
		
		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_E) then
			pace.Call("ToggleFocus")
			last = CurTime() + 0.2
		end
	end
end

hook.Add("Think", "pace_shortcuts", pace.CheckShortcuts)