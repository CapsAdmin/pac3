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

function pace.WearParts(temp_wear_filter)
	local allowed, reason = pac.CallHook("CanWearParts", pac.LocalPlayer)

	if allowed == false then
		pac.Message(reason or "the server doesn't want you to wear parts for some reason")
		return
	end

	return pace.WearOnServer(temp_wear_filter)
end

function pace.OnCreatePart(class_name, name, mdl, no_parent)
	local part
	local parent = NULL

	if no_parent then
		if class_name ~= "group" then
			local group
			local parts = pac.GetLocalParts()
			if table.Count(parts) == 1 then
				local test = select(2, next(parts))
				if test.ClassName == "group" then
					group = test
				end
			else
				group = pac.CreatePart("group")
			end
			part = pac.CreatePart(class_name)
			part:SetParent(group)
			parent = group
		else
			part = pac.CreatePart(class_name)
		end
	else
		if class_name ~= "group" and not next(pac.GetLocalParts()) then
			pace.Call("CreatePart", "group")
		end

		part = pac.CreatePart(class_name)

		parent = pace.current_part

		if parent:IsValid() then
			part:SetParent(parent)
		elseif class_name ~= "group" then
			for _, v in pairs(pac.GetLocalParts()) do
				if v.ClassName == "group" then
					part:SetParent(v)
					parent = v
					break
				end
			end
		end
	end

	if name then part:SetName(name) end

	if part.SetModel then
		if mdl then
			part:SetModel(mdl)
		elseif class_name == "model" or class_name == "model2" then
			part:SetModel("models/pac/default.mdl")
		end
	end

	local ply = pac.LocalPlayer

	if part:GetPlayerOwner() == ply then
		pace.SetViewPart(part)
	end

	if not input.IsControlDown() then
		pace.Call("PartSelected", part)
	end

	part.newly_created = true

	if parent.GetDrawPosition and parent:IsValid() and not parent:HasParent() and parent.OwnerName == "world" and part:GetPlayerOwner() == ply then
		local data = ply:GetEyeTrace()

		if data.HitPos:Distance(ply:GetPos()) < 1000 then
			part:SetPosition(data.HitPos)
		else
			part:SetPosition(ply:GetPos())
		end
	end

	pace.RefreshTree()

	return part
end

function pace.OnPartSelected(part, is_selecting)
	local parent = part:GetRootPart()

	if parent:IsValid() and (parent.OwnerName == "viewmodel" or parent.OwnerName == "hands") then
		pace.editing_viewmodel = parent.OwnerName == "viewmodel"
		pace.editing_hands = parent.OwnerName == "hands"
	elseif pace.editing_viewmodel or pace.editing_hands then
		pace.editing_viewmodel = false
		pace.editing_hands = false
	end

	pace.current_part = part
	pace.PopulateProperties(part)
	pace.mctrl.SetTarget(part)

	pace.SetViewPart(part)

	if pace.Editor:IsValid() then
		pace.Editor:InvalidateLayout()
	end

	pace.SafeRemoveSpecialPanel()

	if pace.tree:IsValid() then
		pace.tree:SelectPart(part)
	end

	pace.current_part_uid = part.UniqueID

	if not is_selecting then
		pace.StopSelect()
	end
end

function pace.OnVariableChanged(obj, key, val, not_from_editor)
	local valType = type(val)
	if valType == 'Vector' then
		val = Vector(val)
	elseif valType == 'Angle' then
		val = Angle(val)
	end

	if not not_from_editor then
		timer.Create("pace_backup", 1, 1, pace.Backup)

		if not pace.undo_release_varchange then
			pace.RecordUndoHistory()
			pace.undo_release_varchange = true
		end

		timer.Create("pace_undo", 0.25, 1, function()
			pace.undo_release_varchange = false
			pace.RecordUndoHistory()
		end)
	end

	if key == "OwnerName" then
		local owner_name = obj:GetProperty(key)
		if val == "viewmodel" then
			pace.editing_viewmodel = true
		elseif val == "hands" then
			pace.editing_hands = true
		elseif owner_name == "hands" then
			pace.editing_hands = false
		elseif owner_name == "viewmodel" then
			pace.editing_viewmodel = false
		end
	end

	obj:SetProperty(key, val)

	local node = obj.pace_tree_node
	if IsValid(node) then
		if key == "Event" then
			pace.PopulateProperties(obj)
		elseif key == "Name" then
			if not obj:HasParent() then
				pace.RemovePartOnServer(obj:GetUniqueID(), true, true)
			end
			node:SetText(val)
		elseif key == "Model" and val and val ~= "" and isstring(val) then
			node:SetModel(val)
		elseif key == "Parent" then
			local tree = obj.pace_tree_node
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
			node:SetText(pace.pac_show_uniqueid:GetBool() and string.format("%s (%s)", obj:GetName(), obj:GetPrintUniqueID()) or obj:GetName())
		end
	end

	if obj.ClassName:StartWith("sound", nil, true) then
		timer.Create("pace_preview_sound", 0.25, 1, function()
			obj:OnShow()
		end)
	end

	timer.Simple(0, function()
		if not IsValid(obj) then return end

		local prop_panel = obj.pace_properties and obj.pace_properties[key]

		if IsValid(prop_panel) then
			local old = prop_panel.OnValueChanged
			prop_panel.OnValueChanged = function() end
			prop_panel:SetValue(val)
			prop_panel.OnValueChanged = old
		end
	end)
end

pac.AddHook("pac_OnPartParent", "pace_parent", function(parent, child)
	pace.Call("VariableChanged", parent, "Parent", child, true)
end)

function pace.GetRegisteredParts()
	local out = {}
	for class_name, PART in pairs(pac.GetRegisteredParts()) do
		local cond = not PART.ClassName:StartWith("base") and
			PART.show_in_editor ~= false and
			PART.is_deprecated ~= false

		if cond then
			table.insert(out, PART)
		end
	end

	return out
end

do -- menu
	local trap
	function pace.AddRegisteredPartsToMenu(menu, parent)
		local partsToShow = {}
		local clicked = false

		hook.Add('Think', menu, function()
			local ctrl = input.IsControlDown()

			if clicked and not ctrl then
				menu:SetDeleteSelf(true)
				RegisterDermaMenuForClose(menu)
				CloseDermaMenus()
				return
			end

			menu:SetDeleteSelf(not ctrl)
		end)

		hook.Add('CloseDermaMenus', menu, function()
			clicked = true
			if input.IsControlDown() then
				menu:SetVisible(true)
				RegisterDermaMenuForClose(menu)
			end
		end)

		local function add_part(menu, part)
			local newMenuEntry = menu:AddOption(L(part.FriendlyName or part.ClassName:Replace('_', ' ')), function()
				pace.RecordUndoHistory()
				pace.Call("CreatePart", part.ClassName, nil, nil, parent)
				pace.RecordUndoHistory()
				trap = true
			end)

			if part.Icon then
				newMenuEntry:SetImage(part.Icon)

				if part.Group == "legacy" then
					local mat = Material(pace.GroupsIcons.experimental)
					newMenuEntry.m_Image.PaintOver = function(_, w,h)
						surface.SetMaterial(mat)
						surface.DrawTexturedRect(2,6,13,13)
					end
				end
			end
		end

		local sortedTree = {}

		for _, part in pairs(pace.GetRegisteredParts()) do
			local group = part.Group or part.Groups or "other"

			if isstring(group) then
				group = {group}
			end

			for i, name in ipairs(group) do
				if not sortedTree[name] then
					sortedTree[name] = {}
					sortedTree[name].parts = {}
					sortedTree[name].icon = pace.GroupsIcons[name]
					sortedTree[name].name = L(name)
				end

				partsToShow[part.ClassName] = nil

				if name == part.ClassName or name == part.FriendlyName then
					sortedTree[name].group_class_name = part.ClassName
				else
					table.insert(sortedTree[name].parts, part)
				end
			end
		end

		local other = sortedTree.other
		sortedTree.other = nil

		for group, groupData in pairs(sortedTree) do
			local sub, pnl = menu:AddSubMenu(groupData.name, function()
				if groupData.group_class_name then
					pace.RecordUndoHistory()
					pace.Call("CreatePart", groupData.group_class_name, nil, nil, parent)
					pace.RecordUndoHistory()
				end
			end)

			sub.GetDeleteSelf = function() return false end

			if groupData.icon then
				pnl:SetImage(groupData.icon)
			end

			trap = false
			table.sort(groupData.parts, function(a, b) return a.ClassName < b.ClassName end)
			for i, part in ipairs(groupData.parts) do
				add_part(sub, part)
			end

			hook.Add('Think', sub, function()
				local ctrl = input.IsControlDown()

				if clicked and not ctrl then
					sub:SetDeleteSelf(true)
					RegisterDermaMenuForClose(sub)
					CloseDermaMenus()
					return
				end

				sub:SetDeleteSelf(not ctrl)
			end)

			hook.Add('CloseDermaMenus', sub, function()
				if input.IsControlDown() and trap then
					trap = false
					sub:SetVisible(true)
				end

				RegisterDermaMenuForClose(sub)
			end)
		end

		for i,v in ipairs(other.parts) do
			add_part(menu, v)
		end

		for class_name, part in pairs(partsToShow) do
			local newMenuEntry = menu:AddOption(L((part.FriendlyName or part.ClassName):Replace('_', ' ')), function()
				pace.RecordUndoHistory()
				pace.Call("CreatePart", class_name, nil, nil, parent)
				pace.RecordUndoHistory()
			end)

			if part.Icon then
				newMenuEntry:SetImage(part.Icon)
			end
		end
	end

	function pace.OnAddPartMenu(obj)
		local base = vgui.Create("EditablePanel")
		base:SetPos(input.GetCursorPos())
		base:SetSize(200, 300)
		base:MakePopup()

		function base:OnRemove()
			pac.RemoveHook("VGUIMousePressed", "search_part_menu")
		end

		local edit = base:Add("DTextEntry")
		edit:SetTall(20)
		edit:Dock(TOP)
		edit:RequestFocus()
		edit:SetUpdateOnType(true)

		local result = base:Add("DPanel")
		result:Dock(FILL)

		function edit:OnEnter()
			if result.found[1] then
				pace.RecordUndoHistory()
				pace.Call("CreatePart", result.found[1].ClassName)
				pace.RecordUndoHistory()
			end
			base:Remove()
		end

		edit.OnValueChange = function(_, str)
			result:Clear()
			result.found = {}

			for _, part in ipairs(pace.GetRegisteredParts()) do
				if (part.FriendlyName or part.ClassName):find(str, nil, true) then
					table.insert(result.found, part)
				end
			end

			table.sort(result.found, function(a, b) return #a.ClassName < #b.ClassName end)

			for _, part in ipairs(result.found) do
				local line = result:Add("DButton")
				line:SetText("")
				line:SetTall(20)
				line.DoClick = function()
					pace.RecordUndoHistory()
					pace.Call("CreatePart", part.ClassName)
					base:Remove()
					pace.RecordUndoHistory()
				end

				local btn = line:Add("DImageButton")
				btn:SetSize(16, 16)
				btn:SetPos(4,0)
				btn:CenterVertical()
				btn:SetMouseInputEnabled(false)
				if part.Icon then
					btn:SetImage(part.Icon)

					if part.Group == "legacy" then
						local mat = Material(pace.GroupsIcons.experimental)
						btn.m_Image.PaintOver = function(_, w,h)
							surface.SetMaterial(mat)
							surface.DrawTexturedRect(2,6,13,13)
						end
					end
				end

				local label = line:Add("DLabel")
				label:SetTextColor(label:GetSkin().Colours.Category.Line.Text)
				label:SetText(L((part.FriendlyName or part.ClassName):Replace('_', ' ')))
				label:SizeToContents()
				label:MoveRightOf(btn, 4)
				label:SetMouseInputEnabled(false)
				label:CenterVertical()

				line:Dock(TOP)
			end

			base:SetHeight(20 * #result.found + edit:GetTall())
		end

		edit:OnValueChange("")

		pac.AddHook("VGUIMousePressed", "search_part_menu", function(pnl, code)
			if code == MOUSE_LEFT or code == MOUSE_RIGHT then
				if not base:IsOurChild(pnl) then
					base:Remove()
				end
			end
		end)
	end

	function pace.Copy(obj)
		pace.Clipboard = obj:ToTable()
	end

	function pace.Cut(obj)
		pace.RecordUndoHistory()
		pace.Copy(obj)
		obj:Remove()
		pace.RecordUndoHistory()
	end

	function pace.Paste(obj)
		if not pace.Clipboard then return end
		pace.RecordUndoHistory()
		local newObj = pac.CreatePart(pace.Clipboard.self.ClassName)
		newObj:SetTable(pace.Clipboard, true)
		newObj:SetParent(obj)
		pace.RecordUndoHistory()
	end

	function pace.PasteProperties(obj)
		if not pace.Clipboard then return end
		pace.RecordUndoHistory()
		local tbl = pace.Clipboard
		tbl.self.Name = nil
		tbl.self.ParentUID = nil
		tbl.self.UniqueID = nil
		tbl.children = {}
		obj:SetTable(tbl)
		pace.RecordUndoHistory()
	end

	function pace.Clone(obj)
		pace.RecordUndoHistory()
		obj:Clone()
		pace.RecordUndoHistory()
	end

	function pace.RemovePart(obj)
		pace.RecordUndoHistory()
		obj:Remove()
		pace.RecordUndoHistory()

		pace.RefreshTree()

		if not obj:HasParent() and obj.ClassName == "group" then
			pace.RemovePartOnServer(obj:GetUniqueID(), false, true)
		end
	end

	function pace.OnPartMenu(obj)
		local menu = DermaMenu()
		menu:SetPos(input.GetCursorPos())

		if obj then
			if not obj:HasParent() then
				menu:AddOption(L"wear", function() pace.SendPartToServer(obj) end):SetImage(pace.MiscIcons.wear)
			end

			menu:AddOption(L"copy", function() pace.Copy(obj) end):SetImage(pace.MiscIcons.copy)
			menu:AddOption(L"paste", function() pace.Paste(obj) end):SetImage(pace.MiscIcons.paste)
			menu:AddOption(L"cut", function() pace.Cut(obj) end):SetImage('icon16/cut.png')
			menu:AddOption(L"paste properties", function() pace.PasteProperties(obj) end):SetImage(pace.MiscIcons.replace)
			menu:AddOption(L"clone", function() pace.Clone(obj) end):SetImage(pace.MiscIcons.clone)

			menu:AddSpacer()
		end

		pace.AddRegisteredPartsToMenu(menu, not obj)

		menu:AddSpacer()

		if obj then
			local save, pnl = menu:AddSubMenu(L"save", function() pace.SaveParts() end)
			pnl:SetImage(pace.MiscIcons.save)
			add_expensive_submenu_load(pnl, function() pace.AddSaveMenuToMenu(save, obj) end)
		end

		local load, pnl = menu:AddSubMenu(L"load", function() pace.LoadParts() end)
		add_expensive_submenu_load(pnl, function() pace.AddSavedPartsToMenu(load, false, obj) end)

		pnl:SetImage(pace.MiscIcons.load)

		if obj then
			menu:AddSpacer()
			menu:AddOption(L"remove", function() pace.RemovePart(obj) end):SetImage(pace.MiscIcons.clear)
		end

		menu:Open()
		menu:MakePopup()
	end

	function pace.OnNewPartMenu()
		pace.current_part = NULL
		local menu = DermaMenu()
		menu:MakePopup()
		menu:SetPos(input.GetCursorPos())

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

do
	pac.haloex = include("pac3/libraries/haloex.lua")

	function pace.OnHoverPart(self)
		local tbl = {}
		local ent = self:GetOwner()

		if ent:IsValid() then
			table.insert(tbl, ent)
		end

		for _, child in ipairs(self:GetChildrenList()) do
			local ent = self:GetOwner()
			if ent:IsValid() then
				table.insert(tbl, ent)
			end
		end

		if #tbl > 0 then
			local pulse = math.sin(pac.RealTime * 20) * 0.5 + 0.5
			pulse = pulse * 255
			pac.haloex.Add(tbl, Color(pulse, pulse, pulse, 255), 1, 1, 1, true, true, 5, 1, 1)
		end
	end
end
