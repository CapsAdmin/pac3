local L = pace.LanguageString

function pace.OnCreatePart(class_name, name, desc, mdl)
	local part = pac.CreatePart(class_name)
	
	local parent = pace.current_part
	
	if parent:IsValid() then	
		part:SetParent(parent)
	end
	
	if desc then part:SetDescription(desc) end
	if mdl then part:SetModel(mdl) end
		
	if part:GetPlayerOwner() == LocalPlayer() then
		pace.SetViewPart(part)
	end

	pace.Call("PartSelected", part)
	
	part.newly_created = true
	
	pace.RefreshTree()	
end

function pace.OnPartSelected(part, is_selecting)
	local parent = part:GetRootPart()
	if parent:IsValid() and parent.OwnerName == "viewmodel" then
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
	
	pace.current_part_uid = part.UniqueID
	
	if not is_selecting then
		pace.StopSelect()
	end
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
						
			if obj.Name == "" then
				node:SetText(obj:GetName())
			end
		end		
	end
	
	timer.Create("autosave_session", 0.5, 1, function()
		pace.SaveSession("autosave")
	end)
end

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

				function(url)
					pace.LoadPartFromURL(part, url)
				end
			)
		end
		
		frm:SetSize(300, 500)
		frm:MakePopup()
		frm:Center()
	else
		pac.dprint("loading %s",  name)
		
		if name:find("http") then	
			pace.LoadPartFromURL(part, name)
		else
			name = name:gsub("%.txt", "")
			local data = pac.luadata.ReadFile("pac3/" .. name .. ".txt")
			
			if data and data.self then
				part:Clear()	
				part:SetTable(data)
				
				if IsValid(part.editor_node) then
					part.editor_node:SetText(part:GetName())
				end
				
				pace.RefreshTree(true)
			else
				print("pac3 tried to load non existant part " .. name)
			end
		end
	end
end

function pace.LoadPartFromURL(part, url)
	url = url:gsub("https://", "http://")
	
	if url:lower():find("pastebin.com") then
		url = url:gsub(".com/", ".com/raw.php?i=")
	end
	
	http.Fetch(url, function(str)
		if not part:IsValid() then return end
		
		local data = pac.luadata.Decode(str)

		if data and data.self then
			part:Clear()	
			part:SetTable(data)
									
			if IsValid(part.editor_node) then
				part.editor_node:SetText(part:GetName())
			end
			
			pace.RefreshTree()
		else
			print("pac3 tried to load invalid part " .. url)
		end
	end)
end


do -- menu
	function pace.AddRegisteredPartsToMenu(menu)
		local temp = {}
		
		for class_name, tbl in pairs(pac.GetRegisteredParts()) do
			
			if pace.IsInBasicMode() and not pace.BasicParts[class_name] then continue end
			if not pace.IsShowingDeprecatedFeatures() and pace.DeprecatedParts[class_name] then continue end
			
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
		
		menu:AddOption(L"help", function()
			pace.ShowHelp(obj.ClassName)
		end)
		
		menu:AddSpacer()

		pace.AddRegisteredPartsToMenu(menu)

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
		
		pace.AddRegisteredPartsToMenu(menu)
		
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
end


function pace.OnHoverPart(obj)
	obj:Highlight()
end

hook.Add("pac_OnPartParent", "pace_parent", function(parent, child)
	pace.Call("VariableChanged",parent, "Parent", child)
end)