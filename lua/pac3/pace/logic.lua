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

	local parent = pace.current_part
	
	if parent:IsValid() then	
		part:SetParent(parent)
	end

	part:SetName(name or (L(class_name) .. " " .. pac.GetPartCount(class_name)))
	
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
			elseif key == "Parent" or key == "ParentName" then
				local tree = obj.editor_node
				if IsValid(tree) then
					tree = tree:GetRoot()
					tree:SetSelectedItem(nil)
					node:Remove()
					pace.RefreshTree(true)
				end
			end
		end
	end
	
	timer.Create("autosave_session", 0.5, 1, function()
		pace.SaveSession("autosave")
	end)
end

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
			"autoload",

			function(name)
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

pace.SetFont()

function pace.OnOpenMenu()
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
	menu:AddOption(L"save session", function()
		pace.SaveSession()
	end)
	menu:AddOption(L"load session", function()
		pace.LoadSession()
	end)
	menu:AddOption(L"wear session", function()
		for key, part in pairs(pac.GetParts(true)) do
			if not part:HasParent() then
				pac.SendPartToServer(part)
			end
		end
	end)
	menu:AddSpacer()
	menu:AddOption(L"toggle t pose", function()
		pace.SetTPose(not pace.GetTPose())
	end)
	menu:AddOption(L"toggle breathing", function()
		pace.SetBreathing(not pace.GetBreathing())
	end)
	menu:AddOption(L"reset view", function()
		pace.ResetView()
	end)
	menu:AddOption(L"reset eye angles", function()
		local ent = pace.GetViewEntity()
		if ent:IsValid() then
			if ent:IsPlayer() then
				ent:SetEyeAngles(Angle(0, 0, 0))
			else
				ent:SetAngles(Angle(0, 0, 0))
			end
		
			ent:SetupBones()
		end
	end)
	local langmenu = menu:AddSubMenu(L"language")
	langmenu:AddOption("english", function()
		pace.SetLanguage("english")
	end)
	
	for key, val in pairs(file.Find("lua/pac3/pace/translations/*", "GAME")) do
		val = val:gsub("%.lua", "")
		langmenu:AddOption(val, function()
			pace.SetLanguage(val)
		end)
	end
	
	local fontmenu = menu:AddSubMenu(L"font")
	for key, val in pairs(pace.Fonts) do
		fontmenu:AddOption(val, function()
			pace.SetFont(val)
		end)
		local pnl = fontmenu.Items and fontmenu.Items[#fontmenu.Items]
		if pnl and pnl:IsValid() then
			pnl:SetFont(val)
			if pace.ShadowedFonts[val] then
				pnl:SetTextColor(derma.Color("text_bright", pnl, color_white))
			else
				pnl:SetTextColor(derma.Color("text_dark", pnl, color_black))
			end
		end
	end
		
		
	menu:AddSpacer()
	
	menu:AddOption(L"clear", function()
		pac.RemoveAllParts(true, true)
		pace.RefreshTree()
	end)
		
	menu:Open()
	menu:MakePopup()
end

local function add_parts(menu)
	local temp = {}
	
	for class_name, tbl in pairs(pac.GetRegisteredParts()) do
		if not tbl.Internal then
			table.insert(temp, class_name)
		end
	end
	
	table.sort(temp)
	
	for _, class_name in pairs(temp) do
		menu:AddOption(L(class_name), function()
			pace.Call("CreatePart", class_name)
		end)--:SetImage(pace.PartIcons[class_name])
	end
end

function pace.OnPartMenu(obj)
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
		
	if not obj:HasParent() then
		menu:AddOption(L"wear", function()
			pac.SendPartToServer(obj)
		end)
		
		menu:AddOption(L"spawn", function()
			local data = pac.PartToContraptionData(obj)
			net.Start("pac_to_contraption")
				net.WriteTable(data)
			net.SendToServer()
		end)
	end

	menu:AddOption(L"copy", function()
		local tbl = obj:ToTable()
			tbl.Name = nil
			tbl.Description = nil
			tbl.ParentName = nil
			tbl.UniqueID = nil
			
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
		pace.RefreshTree()
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