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

	local toWear = {}
	local transmissionID = math.random(1, math.pow(2, 31) - 1)

	for key, part in pairs(pac.GetLocalParts()) do
		if not part:HasParent() and part.show_in_editor ~= false then
			table.insert(toWear, part)
		end
	end

	for i, part in ipairs(toWear) do
		pace.SendPartToServer(part, {partID = i, totalParts = #toWear, transmissionID = transmissionID})
	end
end

function pace.ClearParts()
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

function pace.OnCreatePart(class_name, name, mdl)
	if class_name ~= "group" and not next(pac.GetLocalParts()) then
		pace.Call("CreatePart", "group")
	end

	local part = pac.CreatePart(class_name)

	if name then part:SetName(name) end

	local parent = pace.current_part

	if parent:IsValid() then
		part:SetParent(parent)
	elseif class_name ~= "group" then
		for _, parent in pairs(pac.GetLocalParts()) do
			if parent.ClassName == "group" then
				part:SetParent(parent)
				break
			end
		end
	end

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

function pace.OnVariableChanged(obj, key, val, undo_delay)
	local funcGet = obj["Get" .. key]
	local func = obj["Set" .. key]
	if not func or not funcGet then return end
	local oldValue = funcGet(obj)

	local valType = type(val)
	if valType == 'Vector' then
		val = Vector(val)
	elseif valType == 'Angle' then
		val = Angle(val)
	end

	timer.Create("pace_backup", 1, 1, pace.Backup)

	if key == "OwnerName" then
		if val == "viewmodel" then
			pace.editing_viewmodel = true
		elseif obj[key] == "viewmodel" then
			pace.editing_viewmodel = false
		end
	end

	-- pace.CallChangeForUndo(obj, key, funcGet(obj), undo_delay)
	func(obj, val)

	if undo_delay ~= false then
		pace.CallChangeForUndo(obj, key, oldValue, funcGet(obj), undo_delay)
	end

	local node = obj.editor_node
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
	function pace.AddRegisteredPartsToMenu(menu)
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

		if pace.IsInBasicMode() then
			for _, part in ipairs(pace.GetRegisteredParts()) do
				local newMenuEntry = menu:AddOption(L(part.Name or part.ClassName), function()
					pace.AddUndoPartCreation(pace.Call("CreatePart", part.ClassName))
				end)

				if part.Icon then
					newMenuEntry:SetImage(part.Icon)
				end
			end
		else
			local sortedTree = {}

			for _, part in pairs(pace.GetRegisteredParts()) do
				local group = part.Group or part.Groups
				local groups

				if type(group) == 'string' then
					groups = {group}
				else
					groups = group
				end

				if groups then
					for i, groupName in ipairs(groups) do
						if not sortedTree[groupName] then
							sortedTree[groupName] = {}
							sortedTree[groupName].parts = {}
							sortedTree[groupName].icon = pace.GroupsIcons[groupName]
							sortedTree[groupName].name = L(groupName)
						end

						partsToShow[part.ClassName] = nil

						if groupName == part.ClassName then
							sortedTree[groupName].hasPart = true
						else
							table.insert(sortedTree[groupName].parts, {part.ClassName, part})
						end
					end
				end
			end

			for group, groupData in pairs(sortedTree) do
				local sub, pnl = menu:AddSubMenu(groupData.name, function()
					if groupData.hasPart then
						pace.AddUndoPartCreation(pace.Call("CreatePart", group))
					end
				end)

				sub.GetDeleteSelf = function() return false end

				if groupData.icon then
					pnl:SetImage(groupData.icon)
				end

				local trap = false
				table.sort(groupData.parts, function(a, b) return a[1] < b[1] end)
				for i, partData in ipairs(groupData.parts) do
					local newMenuEntry = sub:AddOption(L(partData[2].Name or partData[1]:Replace('_', ' ')), function()
						pace.AddUndoPartCreation(pace.Call("CreatePart", partData[1]))
						trap = true
					end)

					if partData[2].Icon then
						newMenuEntry:SetImage(partData[2].Icon)

						if group == "experimental" then
							local mat = Material(pace.GroupsIcons.experimental)
							newMenuEntry.m_Image.PaintOver = function(_, w,h)
								surface.SetMaterial(mat)
								surface.DrawTexturedRect(2,6,13,13)
							end
						end
					end
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

			for class_name, part in pairs(partsToShow) do
				local newMenuEntry = menu:AddOption(L((part.Name or part.ClassName):Replace('_', ' ')), function()
					pace.AddUndoPartCreation(pace.Call("CreatePart", class_name))
				end)

				if part.Icon then
					newMenuEntry:SetImage(part.Icon)
				end
			end
		end
	end

	function pace.OnAddPartMenu(obj)
		local base = vgui.Create("EditablePanel")
		base:SetPos(gui.MousePos())
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
				pace.AddUndoPartCreation(pace.Call("CreatePart", result.found[1].ClassName))
			end
			base:Remove()
		end

		edit.OnValueChange = function(_, str)
			result:Clear()
			result.found = {}

			for _, part in ipairs(pace.GetRegisteredParts()) do
				if (part.Name or part.ClassName):find(str, nil, true) then
					table.insert(result.found, part)
				end
			end

			table.sort(result.found, function(a, b) return #a.ClassName < #b.ClassName end)

			for _, part in ipairs(result.found) do
				local line = result:Add("DButton")
				line:SetText("")
				line:SetTall(20)
				line.DoClick = function()
					pace.AddUndoPartCreation(pace.Call("CreatePart", part.ClassName))
					base:Remove()
				end

				local btn = line:Add("DImageButton")
				btn:SetSize(16, 16)
				btn:SetPos(4,0)
				btn:CenterVertical()
				btn:SetMouseInputEnabled(false)
				if part.Icon then
					btn:SetImage(part.Icon)

					if part.Group == "experimental" then
						local mat = Material(pace.GroupsIcons.experimental)
						btn.m_Image.PaintOver = function(_, w,h)
							surface.SetMaterial(mat)
							surface.DrawTexturedRect(2,6,13,13)
						end
					end
				end

				local label = line:Add("DLabel")
				label:SetTextColor(label:GetSkin().Colours.Category.Line.Text)
				label:SetText(L((part.Name or part.ClassName):Replace('_', ' ')))
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
				newObj:Attach(obj)
				pace.AddUndoPartCreation(newObj)
			end
		end):SetImage(pace.MiscIcons.paste)

		menu:AddOption(L"cut", function()
			pace.Clipboard = obj
			obj:DeattachFull()
			pace.AddUndoPartRemoval(obj)
		end):SetImage('icon16/cut.png')

		-- needs proper undo
		menu:AddOption(L"paste properties", function()
			if pace.Clipboard then
				local tbl = pace.Clipboard:ToTable()
					tbl.self.Name = nil
					tbl.self.ParentName = nil
					tbl.self.Parent = nil
					tbl.self.UniqueID = util.CRC(tbl.self.UniqueID .. tostring(tbl))

					tbl.children = {}
				obj:SetTable(tbl)
			end
			--pace.Clipboard = nil
		end):SetImage(pace.MiscIcons.replace)

		menu:AddOption(L"clone", function()
			local part_ = obj:Clone()
			pace.AddUndoPartCreation(part_)
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
			-- obj:Remove()
			pace.AddUndoPartRemoval(obj)
			obj:DeattachFull()

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

pac.AddHook("pac_OnPartParent", "pace_parent", function(parent, child)
	pace.Call("VariableChanged",parent, "Parent", child)
end)
