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
	local allowed, reason = pac.CallHook("CanWearParts", LocalPlayer(), file)

	if allowed == false then
		pac.Message(reason or "the server doesn't want you to wear parts for some reason")
		return
	end

	if file then
		pace.LoadParts(file, clear)
	end

	local toWear = {}
	local transmissionID = math.random(1, math.pow(2, 31) - 1)

	for key, part in pairs(pac.GetLocalParts()) do
		if not part:HasParent() and part.show_in_editor ~= false and pace.IsPartSendable(part) then
			table.insert(toWear, part)
		end
	end

	for i, part in ipairs(toWear) do
		pace.SendPartToServer(part, {partID = i, totalParts = #toWear, transmissionID = transmissionID})
	end
end

function pace.ClearParts()
	pace.ClearUndo()
	pac.RemoveAllParts(true, true)
	pace.RefreshTree()

	timer.Simple(0.1, function()
		if not pace.Editor:IsValid() then return end

		if table.Count(pac.GetLocalParts()) == 0 then
			pace.Call("CreatePart", "group", L"my outfit")
		end

		pace.TrySelectPart()
	end)
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

	local ply = LocalPlayer()

	if part:GetPlayerOwner() == ply then
		pace.SetViewPart(part)
	end

	if not input.IsControlDown() then
		pace.Call("PartSelected", part)
	end

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

	pace.Editor:InvalidateLayout()

	pace.SafeRemoveSpecialPanel()

	if pace.tree:IsValid() then
		pace.tree:SelectPart(part)
	end

	pace.current_part_uid = part.UniqueID

	if not is_selecting then
		pace.StopSelect()
	end

	if part.ClassName == 'group' then
		if #part:GetChildrenList() ~= 0 then
			local position

			for i, child in ipairs(part:GetChildrenList()) do
				if not position then
					local pos = child:GetDrawPosition()

					if not position then
						position = pos
					else
						position = LerpVector(0.5, position, pos)
					end
				end
			end

			if not position then
				-- wtf
				part.centreAngle = nil
				part.centrePosMV = nil
				part.centrePosCTRL = nil
				part.centrePosO = nil
				part.centrePos = nil
			else
				part.centrePos = Vector(position)
				part.centrePosO = Vector(position)
				part.centrePosMV = Vector()
				part.centrePosCTRL = Vector()
				part.centreAngle = Angle(0, pac.LocalPlayer:EyeAngles().y, 0)
			end
		else
			part.centrePos = nil
			part.centrePosO = nil
			part.centrePosMV = nil
			part.centrePosCTRL = nil
			part.centreAngle = nil
		end
	end
end

function pace.OnVariableChanged(obj, key, val, not_from_editor)
	local funcGet = obj["Get" .. key]
	local func = obj["Set" .. key]
	if not func or not funcGet then return end

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
		if val == "viewmodel" then
			pace.editing_viewmodel = true
		elseif val == "hands" then
			pace.editing_hands = true
		elseif obj[key] == "hands" then
			pace.editing_hands = false
		elseif obj[key] == "viewmodel" then
			pace.editing_viewmodel = false
		end
	end


	func(obj, val)

	local node = obj.pace_tree_node
	if IsValid(node) then
		if key == "Event" then
			pace.PopulateProperties(obj)
		elseif key == "Name" then
			if not obj:HasParent() then
				pace.RemovePartOnServer(obj:GetUniqueID(), true, true)
			end
			node:SetText(val)
		elseif key == "Model" and val and val ~= "" and type(val) == "string" then
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
			node:SetText(obj:GetName())
		end
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

function pace.GetRegisteredParts()
	local out = {}
	for class_name, part in pairs(pac.GetRegisteredParts()) do
		local cond = (not pace.IsInBasicMode() or pace.BasicParts[class_name]) and
			not part.Internal and
			part.show_in_editor ~= false and
			part.is_deprecated ~= false

		if cond then
			table.insert(out, part)
		end
	end

	return out
end

do -- menu
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

		if pace.IsInBasicMode() then
			for _, part in ipairs(pace.GetRegisteredParts()) do
				add_part(menu, part)
			end
		else
			local sortedTree = {}

			for _, part in pairs(pace.GetRegisteredParts()) do
				local group = part.Group or part.Groups or "other"

				if type(group) == "string" then
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

				local trap = false
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
		if pace.IsInBasicMode() then
			edit:SetTall(0)
		end
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
		pace.Clipboard = obj:ToTable(true)
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
		newObj:SetTable(pace.Clipboard)
		newObj:SetParent(obj)
		pace.RecordUndoHistory()
	end

	function pace.PasteProperties(obj)
		if not pace.Clipboard then return end
		pace.RecordUndoHistory()
		local tbl = pace.Clipboard
			tbl.self.Name = nil
			tbl.self.ParentName = nil
			tbl.self.Parent = nil
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
		pace.current_part = pac.NULL
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

function pace.OnHoverPart(self)
	local tbl = {}

	if self.Entity and self.Entity:IsValid() then
		table.insert(tbl, self.Entity)
	end

	for _, child in ipairs(self:GetChildrenList()) do
		if child.Entity and child.Entity:IsValid() then
			table.insert(tbl, child.Entity)
		end
	end

	if #tbl > 0 then
		local pulse = math.sin(pac.RealTime * 20) * 0.5 + 0.5
		pulse = pulse * 255
		pac.haloex.Add(tbl, Color(pulse, pulse, pulse, 255), 1, 1, 1, true, true, 5, 1, 1)
	end
end

pac.AddHook("pac_OnPartParent", "pace_parent", function(parent, child)
	pace.Call("VariableChanged", parent, "Parent", child, true)
end)

do
	local hold = false
	local last = 0

	local function thinkUndo()
		-- whooaaa
		-- if input.IsControlDown() and input.IsKeyDown(KEY_X) then
		--  pace.UndoPosition = math.Round((gui.MouseY() / ScrH()) * #pace.UndoHistory)
		--  pace.ApplyUndo()
		--  return
		-- end

		if not input.IsKeyDown(KEY_Z) and not input.IsKeyDown(KEY_Y) then
			hold = false
		end

		if hold then return end

		if input.IsControlDown() and ((input.IsKeyDown(KEY_LSHIFT) and input.IsKeyDown(KEY_Z)) or input.IsKeyDown(KEY_Y)) then
			pace.Redo()
			hold = true
		elseif input.IsControlDown() and input.IsKeyDown(KEY_Z) then
			pace.Undo()
			hold = true
		end
	end

	local hold = false

	local function thinkCopy()
		if not input.IsKeyDown(KEY_C) then
			hold = false
		end

		if hold or not (input.IsControlDown() and input.IsKeyDown(KEY_C)) then return end

		-- copy
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part selected to copy')
			return
		end

		pace.Copy(part)

		surface.PlaySound("buttons/button9.wav")
	end

	local hold = false

	local function thinkCut()
		if not input.IsKeyDown(KEY_X) then
			hold = false
		end

		if hold or not (input.IsControlDown() and input.IsKeyDown(KEY_X)) then return end

		-- copy
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part selected to cut')
			return
		end

		pace.Cut(part)

		surface.PlaySound("buttons/button9.wav")
	end

	local hold = false

	local function thinkDelete()
		if not input.IsKeyDown(KEY_DELETE) then
			hold = false
		end

		if hold or not input.IsKeyDown(KEY_DELETE) then return end

		-- delete
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part to delete')
			return
		end

		pace.RemovePart(part)

		surface.PlaySound("buttons/button9.wav")
	end

	local REVERSE_COLLAPSE_CONTROLS = CreateConVar('pac_reverse_collapse', '1', {FCVAR_ARCHIVE}, 'Reverse Collapse/Expand hotkeys')
	local hold = false

	local function thinkExpandAll()
		if not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT) and not input.IsKeyDown(KEY_0) then
			hold = false
		end

		if hold or not input.IsShiftDown() or (not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT)) or not input.IsKeyDown(KEY_0) then return end

		-- expand all
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part to expand')
			return
		end

		part:CallRecursive('SetEditorExpand', not REVERSE_COLLAPSE_CONTROLS:GetBool())

		surface.PlaySound("buttons/button9.wav")
		pace.RefreshTree(true)
	end

	local hold = false

	local function thinkCollapseAll()
		if not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT) and not input.IsKeyDown(KEY_0) then
			hold = false
		end

		if hold or input.IsShiftDown() or (not input.IsKeyDown(KEY_LALT) and not input.IsKeyDown(KEY_RALT)) or not input.IsKeyDown(KEY_0) then return end

		-- collapse all
		hold = true
		local part = pace.current_part

		if not part or not part:IsValid() then
			pace.FlashNotification('No part to collapse')
			return
		end

		part:CallRecursive('SetEditorExpand', REVERSE_COLLAPSE_CONTROLS:GetBool())

		surface.PlaySound("buttons/button9.wav")
		pace.RefreshTree(true)
	end

	local hold = false

	local function thinkPaste()
		if not input.IsKeyDown(KEY_V) then
			hold = false
		end

		if hold or not (input.IsControlDown() and input.IsKeyDown(KEY_V)) then return end

		-- paste
		hold = true
		local part = pace.Clipboard

		if not part then
			pace.FlashNotification('No part is stored in clipboard')
			return
		end

		local findParent

		if part == pace.current_part then
			findParent = part:GetParent()

			if not findParent or not findParent:IsValid() then
				findParent = part
			end
		elseif pace.current_part and pace.current_part:IsValid() then
			findParent = pace.current_part
		else
			pace.RecordUndoHistory()
			findParent = pace.Call("CreatePart", "group", L"paste data")
			pace.RecordUndoHistory()
		end

		pace.Paste(findParent)

		surface.PlaySound("buttons/button9.wav")
	end

	pac.AddHook("Think", "pace_keyboard_shortcuts", function()
		if not pace.IsActive() then return end
		if not pace.Focused then return end
		if IsValid(vgui.GetKeyboardFocus()) and vgui.GetKeyboardFocus():GetClassName():find('Text') then return end
		if gui.IsConsoleVisible() then return end
		thinkUndo()
		thinkCopy()
		thinkPaste()
		thinkCut()
		thinkDelete()
		thinkExpandAll()
		thinkCollapseAll()
	end)
end