local L = pace.LanguageString

-- load only when hovered above
local function add_expensive_submenu_load(pnl, callback)
	local old = pnl.OnCursorEntered
	pnl.OnCursorEntered = function(...)
		callback()
		pnl.OnCursorEntered = old
		return old(...)
	end
end

function pace.WearParts(file, clear)
	if file then
		pace.LoadParts(file, clear)
	end

	for key, part in pairs(pac.GetParts(true)) do
		if not part:HasParent() and part.show_in_editor ~= false then
			pace.SendPartToServer(part)
		end
	end
end

function pace.ClearParts()
	pac.RemoveAllParts(true, true)
	pace.RefreshTree()

	timer.Simple(0.1, function()
		if not pace.Editor:IsValid() then return end

		if table.Count(pac.GetParts(true)) == 0 then
			pace.Call("CreatePart", "group", L"my outfit", L"add parts to me!")
		end

		pace.TrySelectPart()
	end)
end

function pace.OnCreatePart(class_name, name, desc, mdl)

	if class_name ~= "group" and not next(pac.GetParts(true)) then
		pace.Call("CreatePart", "group")
	end

	local part = pac.CreatePart(class_name)

	if name then part:SetName(name) end

	local parent = pace.current_part

	if parent:IsValid() then
		part:SetParent(parent)
	elseif class_name ~= "group" then
		for _, parent in pairs(pac.GetParts(true)) do
			if parent.ClassName == "group" then
				part:SetParent(parent)
				break
			end
		end
	end

	if desc then part:SetDescription(desc) end
	if mdl then
		part:SetModel(mdl)
	elseif class_name == "model" then
		part:SetModel("models/pac/default.mdl")
	end

	local ply = LocalPlayer()

	if part:GetPlayerOwner() == ply then
		pace.SetViewPart(part)
	end

	pace.Call("PartSelected", part)

	part.newly_created = true

	if not part.NonPhysical and parent:IsValid() and not parent:HasParent() and parent.OwnerName == "world" and part:GetPlayerOwner() == ply then
		local data = ply:GetEyeTrace()

		if data.HitPos:Distance(ply:GetPos()) < 1000 then
			part:SetPosition(data.HitPos)
		else
			part:SetPosition(ply:GetPos())
		end
	end

	pace.RefreshTree()
end

function pace.OnPartSelected(part, is_selecting)
	local parent = part:GetRootPart()

	if parent:IsValid() and parent.OwnerName == "viewmodel" then
		pace.editing_viewmodel = true
	elseif pace.editing_viewmodel then
		pace.editing_viewmodel = false
	end

	pace.current_part = part
	pace.PopulateProperties(part)
	pace.mctrl.SetTarget(part)

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

		timer.Create("pace_backup", 1, 1, function() pace.Backup() end)

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
			if key == "Event" then
				pace.PopulateProperties(obj)
			elseif key == "Name" then
				if not obj:HasParent() then
					pace.RemovePartOnServer(obj:GetUniqueID(), false, true)
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
end

do -- menu
	function pace.AddRegisteredPartsToMenu(menu)
		local temp = {}

		for class_name, tbl in pairs(pac.GetRegisteredParts()) do

			if pace.IsInBasicMode() and not pace.BasicParts[class_name] then continue end
			if not pace.IsShowingDeprecatedFeatures() and pace.DeprecatedParts[class_name] then continue end
			if tbl.show_in_editor == false then continue end

			if not tbl.Internal then
				table.insert(temp, class_name)
			end
		end

		if pace.IsInBasicMode() then
			table.sort(temp)

			for _, class_name in pairs(temp) do
				menu:AddOption(L(class_name), function()
					pace.Call("CreatePart", class_name)
				end):SetImage(pace.PartIcons[class_name])
			end
		else
			local added = {}

			for key, tbl in pairs(pace.PartTree) do
				if type(tbl) == "table" then
					added[key] = true
					local sub, pnl = menu:AddSubMenu(L(key), function()
						if pac.GetRegisteredParts()[key] then
							pace.Call("CreatePart", key)
						end
					end)
					sub.GetDeleteSelf = function() return false end

					pnl:SetImage(pace.PartIcons[key])

					for class_name in pairs(tbl) do
						added[class_name] = true
						sub:AddOption(L(class_name), function()
							pace.Call("CreatePart", class_name)
						end):SetImage(pace.PartIcons[class_name])
					end
				else
					menu:AddOption(L(key), function()
						pace.Call("CreatePart", key)
					end):SetImage(pace.PartIcons[key])
				end
			end

			local cur = menu

			for class_name, part in pairs(pac.GetRegisteredParts()) do
				if part.Category then
					local sub, pnl = menu:AddSubMenu(L(part.Category), function()
						if pac.GetRegisteredParts()[part.Category] then
							pace.Call("CreatePart", part.Category)
						end
					end)
					sub.GetDeleteSelf = function() return false end
					if pace.PartIcons[part.Category] then
						pnl:SetImage(pace.PartIcons[part.Category])
					end
					cur = sub
				else
					cur = menu
				end

				local pnl = cur:AddOption(L(class_name), function()
					pace.Call("CreatePart", class_name)
				end)

				if pace.PartIcons[class_name] then
					pnl:SetImage(pace.PartIcons[class_name])
				end
			end
		end
	end

	function pace.OnPartMenu(obj)
		local menu = DermaMenu()
		menu:SetPos(gui.MousePos())

		if not obj:HasParent() then
			menu:AddOption(L"wear", function()
				pace.SendPartToServer(obj)
			end):SetImage(pace.MiscIcons.wear)
		end

		menu:AddOption(L"copy", function()
			pace.Clipboard = obj
		end):SetImage(pace.MiscIcons.copy)

		menu:AddOption(L"paste", function()
			if pace.Clipboard then
				local newObj = pace.Clipboard:Clone()
				newObj:SetParent(obj)
			end
			--pace.Clipboard = nil
		end):SetImage(pace.MiscIcons.paste)

		menu:AddOption(L"paste properties", function()
			if pace.Clipboard then
				local tbl = pace.Clipboard:ToTable()
					tbl.self.Name = nil
					tbl.self.Description = nil
					tbl.self.ParentName = nil
					tbl.self.Parent = nil
					tbl.self.UniqueID = util.CRC(tbl.self.UniqueID .. tostring(tbl))

					tbl.children = {}
				obj:SetTable(tbl)
			end
			--pace.Clipboard = nil
		end):SetImage(pace.MiscIcons.replace)

		menu:AddOption(L"clone", function()
			obj:Clone()
		end):SetImage(pace.MiscIcons.clone)

		menu:AddSpacer()

		pace.AddRegisteredPartsToMenu(menu)

		menu:AddSpacer()

		local save, pnl = menu:AddSubMenu(L"save", function() pace.SaveParts() end)
		pnl:SetImage(pace.MiscIcons.save)
		add_expensive_submenu_load(pnl, function() pace.AddSaveMenuToMenu(save, obj) end)

		local load, pnl = menu:AddSubMenu(L"load", function() pace.LoadParts() end)
		add_expensive_submenu_load(pnl, function() pace.AddSavedPartsToMenu(load, false, obj) end)

		pnl:SetImage(pace.MiscIcons.load)

		menu:AddSpacer()

		menu:AddOption(L"remove", function()
			obj:Remove()
			pace.RefreshTree()
			if not obj:HasParent() and obj.ClassName == "group" then
				pace.RemovePartOnServer(obj:GetUniqueID(), false, true)
			end
		end):SetImage(pace.MiscIcons.clear)

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

		local load, pnl = menu:AddSubMenu(L"load", function() pace.LoadParts() end)
		pnl:SetImage(pace.MiscIcons.load)
		add_expensive_submenu_load(pnl, function() pace.AddSavedPartsToMenu(load, false, obj) end)

		menu:AddOption(L"clear", function()
			pace.ClearParts()
		end):SetImage(pace.MiscIcons.clear)

	end
end

function pace.OnHoverPart(obj)
	obj:Highlight()
end

hook.Add("pac_OnPartParent", "pace_parent", function(parent, child)
	pace.Call("VariableChanged",parent, "Parent", child)
end)