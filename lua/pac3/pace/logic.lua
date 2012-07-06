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

function pace.OnPartSelected(part)
	pace.PopulateProperties(part)
	pace.mctrl.SetTarget(part)
	pace.current_part = part
	
	pace.SetViewPart(part)
	
	pace.Editor:InvalidateLayout()
	
	if pac.MatBrowser and pac.MatBrowser:IsValid() then
		pac.MatBrowser:Remove()
	end
	
	pace.StopSelect()
end

function pace.OnCreatePart(class_name, name, desc)
	local part = pac.CreatePart(class_name)

	local parent = pace.current_part
	
	if parent:IsValid() then	
		part:SetParent(parent)
	end

	part:SetName(name or (L(class_name) .. " " .. pac.GetPartCount(class_name)))
	
	if desc then part:SetDescription(desc) end
		
	pace.SetViewPart(part)
	pace.OnPartSelected(part)
	
	pace.RefreshTree()	
end

function pace.OnVariableChanged(obj, key, val, skip_undo)
	local func = obj["Set" .. key]
	if func then
		func(obj, val)

		if not skip_undo then
			pace.CallChangeForUndo(obj, key, val)
		end
		
		local node = obj.editor_node
		if IsValid(node) then			
			if key == "Name" then
				node:SetText(val)
			elseif key == "Model" and val and val ~= "" then
				node:SetModel(val)
			elseif key == "Parent" or key == "ParentName" then
				local tree = obj.editor_node
				if IsValid(tree) then
					tree = tree:GetRoot()
					tree:SetSelectedItem(nil)
					node:Remove()
					pace.RefreshTree()
				end
			end
		end
	end
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
		print("[pac3] saving " .. name)
		luadata.WriteFile("pac3/" .. name .. ".txt", part:ToTable())
	end
end

function pace.LoadPartFromFile(part, name)
	if not name then
		Derma_StringRequest(
			L"load part",
			L"filename:",
			"",

			function(name)
				pace.LoadPartFromFile(part, name)
			end
		)
	else
		print("[pac3] loading " .. name)
		local data = luadata.ReadFile("pac3/" .. name .. ".txt")
		if data and data.self then
			part:SetTable(data)
		else
			ErrorNoHalt("pac3 tried to load non existant part " .. name)
		end
		
		if IsValid(part.editor_node) then
			part.editor_node:SetText(part:GetName())
		end
		
		pace.RefreshTree()
	end
end

function pace.OnOpenMenu()
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
	menu:AddOption(L"toggle t pose", function()
		pace.SetTPose(not pace.GetTPose())
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
	for key, val in pairs(file.Find("lua/pac3/pace/translations/*", true)) do
		val = val:gsub("%.txt", "")
		langmenu:AddOption(val, function()
			pace.SetLanguage(val)
		end)
	end
	menu:Open()
	menu:MakePopup()
end

local function add_parts(menu)
	for class_name, tbl in pairs(pac.GetRegisteredParts()) do
		if not tbl.Internal then
			menu:AddOption(L(class_name), function()
				pace.Call("CreatePart", class_name)
			end)--:SetImage(pace.PartIcons[class_name])
		end
	end
end

function pace.OnPartMenu(obj)
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
		
	if not obj:HasParent() then
		menu:AddOption(L"wear", function()
			pac.SubmitPart(obj:GetOwner(), obj)
		end)
	end

	menu:AddOption(L"copy", function()
		local tbl = obj:ToTable()
			tbl.Name = nil
			tbl.Description = nil
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
		pace.RefreshTree()
		CloseDermaMenus()
	end)
	
	menu:AddOption(L"remove", function()
		pac.SubmitRemove(obj:GetOwner(), obj:GetName())
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
	menu:AddOption(L"clear", function()
		for key, part in pairs(pac.GetParts()) do
			part:Remove()
		end
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
	
	if #pac.GetParts() == 0 then
		pace.Call("CreatePart", "group", L"my outfit", L"add parts to me!")
	else
		pace.OnPartSelected(select(2, next(pac.GetParts())))
	end
	
	pace.ResetView()
end

function pace.OnCloseEditor()
	pace.EnableView(false)
	pace.StopSelect()
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
		pac.SubmitPart(part:GetOwner(), part)
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
		if last > CurTime() then return end

		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_S) then
			pace.Call("ShortcutSave")
			last = CurTime() + 0.2
		end
		
		if input.IsKeyDown(KEY_LCONTROL) and input.IsKeyDown(KEY_D) then
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