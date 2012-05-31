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

function pace.OnCreatePart(name)
	local part = pac.CreatePart(name)

	local parent = pace.current_part
	
	if parent:IsValid() then	
		part:SetName(name .. " " .. pac.GetPartCount(name, parent:GetChildren()))
		part:SetParent(parent)
	else
		part:SetName(name .. " " .. pac.GetPartCount(name))
	end
		
	pace.SetViewPart(part)

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
		if data then
			part:SetTable(data)
		else
			ErrorNoHalt("pac3 tried to load non existant part " .. name)
		end
		pace.RefreshTree()
	end
end

function pace.OnOpenMenu()
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
	menu:AddOption("toggle t pose", function()
		pace.SetTPose(not pace.GetTPose())
	end)
	menu:AddOption("reset view", function()
		pace.ResetView()
	end)
	menu:AddOption("reset eye angles", function()
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
	menu:Open()
	menu:MakePopup()
end

local function add_parts(menu)
	for class_name in pairs(pac.GetRegisteredParts()) do
		menu:AddOption(class_name, function()
			pace.Call("CreatePart", class_name)
		end)--:SetImage(pace.PartIcons[class_name])
	end
end

function pace.OnPartMenu(obj)
	local menu = DermaMenu()
	menu:SetPos(gui.MousePos())
		
	if not obj:HasParent() then
		menu:AddOption("wear", function()
			pac.SubmitPart(obj:GetOwner(), obj)
		end)
	end
	
	menu:AddOption("clone", function()
		obj:Clone()
		pace.RefreshTree()
	end)

	menu:AddOption("set owner", function()
		pace.SelectEntity(function(ent)
			obj:SetOwner(ent)
			pace.SetViewEntity(ent)
		end)
		
	end)
		
	menu:AddSpacer()

	add_parts(menu)
	
	menu:AddSpacer()

	menu:AddOption("save", function()
		pace.SavePartToFile(obj)
		CloseDermaMenus()
	end)

	menu:AddOption("load", function()
		pace.LoadPartFromFile(obj)
		pace.RefreshTree()
		CloseDermaMenus()
	end)
	
	menu:AddOption("remove", function()
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
end

function pace.OnHoverPart(obj)
	obj:Highlight()
end

function pace.OnOpenEditor()
	pace.SetViewPos(LocalPlayer():EyePos())
	pace.SetViewAngles(LocalPlayer():EyeAngles())
	pace.EnableView(true)
end

function pace.OnCloseEditor()
	pace.EnableView(false)
	pace.StopSelect()
end