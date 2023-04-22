include("pac3/editor/client/panels/properties.lua")
local L = pace.LanguageString
local BulkSelectList = {}
local BulkSelectUIDs = {}
pace.BulkSelectClipboard = {}
refresh_halo_hook = true


CreateConVar( "pac_hover_color", "255 255 255", FCVAR_ARCHIVE, "R G B value of the highlighting when hovering over pac3 parts, there are also special options: none, ocean, funky, rave, rainbow")
CreateConVar( "pac_hover_pulserate", 20, FCVAR_ARCHIVE, "pulse rate of the highlighting when hovering over pac3 parts")
CreateConVar( "pac_hover_halo_limit", 100, FCVAR_ARCHIVE, "max number of parts before hovering over pac3 parts stops computing to avoid lag")

CreateConVar( "pac_bulk_select_key", "ctrl", FCVAR_ARCHIVE, "Button to hold to use bulk select")
CreateConVar( "pac_bulk_select_halo_mode", 1, FCVAR_ARCHIVE, "Halo Highlight mode.\n0 is no highlighting\n1 is passive\n2 is when the same key as bulk select is pressed\n3 is when control key pressed\n4 is when shift key is pressed.")

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
	timer.Simple(0.3, function() BulkSelectRefreshFadedNodes() end)
	return part
end

local last_span_select_part
local last_select_was_span = false
local last_direction

function pace.OnPartSelected(part, is_selecting)

	if input.IsKeyDown(input.GetKeyCode(GetConVar("pac_bulk_select_key"):GetString())) and not input.IsKeyDown(input.GetKeyCode("z")) and not input.IsKeyDown(input.GetKeyCode("y")) then
		--jumping multi-select if holding shift + ctrl
		if input.IsControlDown() and input.IsShiftDown() and not input.IsKeyDown(input.GetKeyCode("z")) and not input.IsKeyDown(input.GetKeyCode("y")) then
			--ripped some local functions from tree.lua
			local added_nodes = {}
			for i,v in ipairs(pace.tree.added_nodes) do
				if v.part and v:IsVisible() and v:IsExpanded() then
					table.insert(added_nodes, v)
				end
			end

			local startnodenumber = table.KeyFromValue( added_nodes, pace.current_part.pace_tree_node)
			local endnodenumber = table.KeyFromValue( added_nodes, part.pace_tree_node)

			table.sort(added_nodes, function(a, b) return select(2, a:LocalToScreen()) < select(2, b:LocalToScreen()) end)

			local i = startnodenumber

			direction = math.Clamp(endnodenumber - startnodenumber,-1,1)
			if direction == 0 then last_direction = direction return end
			last_direction = last_direction or 0
			if last_span_select_part == nil then last_span_select_part = part end

			if last_select_was_span then
				if last_direction == -direction then
					pace.DoBulkSelect(pace.current_part, true)
				end
				if last_span_select_part == pace.current_part then
					pace.DoBulkSelect(pace.current_part, true)
				end
			end
			while (i ~= endnodenumber) do
				pace.DoBulkSelect(added_nodes[i].part, true)
				i = i + direction
			end
			pace.DoBulkSelect(part)
			last_direction = direction
			last_select_was_span = true
		else
			pace.DoBulkSelect(part)
			last_select_was_span = false
		end

	else last_select_was_span = false end
	last_span_select_part = part



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
	if not pace.Active or refresh_halo_hook then
		hook.Remove('PreDrawHalos', "BulkSelectHighlights")
	end

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
		if table.HasValue(BulkSelectList,obj) then table.RemoveByValue(BulkSelectList,obj) end

		pace.RecordUndoHistory()
		obj:Remove()
		pace.RecordUndoHistory()

		pace.RefreshTree()

		if not obj:HasParent() and obj.ClassName == "group" then
			pace.RemovePartOnServer(obj:GetUniqueID(), false, true)
		end
	end

	function pace.ClearBulkList()
		for _,v in ipairs(BulkSelectList) do
			if v.pace_tree_node ~= nil then v.pace_tree_node:SetAlpha( 255 ) end
			v:SetInfo()
		end
		BulkSelectList = {}
		print("Bulk list deleted!")
		--surface.PlaySound('buttons/button16.wav')
	end
//@note pace.DoBulkSelect
	function pace.DoBulkSelect(obj, silent)
		refresh_halo_hook = false
		--print(obj.pace_tree_node, "color", obj.pace_tree_node:GetFGColor().r .. " " .. obj.pace_tree_node:GetFGColor().g .. " " .. obj.pace_tree_node:GetFGColor().b)
		if obj.ClassName == "timeline_dummy_bone" then return end
		local selected_part_added = false	--to decide the sound to play afterward

		BulkSelectList = BulkSelectList or {}
		if (table.HasValue(BulkSelectList, obj)) then
			pace.RemoveFromBulkSelect(obj)
			selected_part_added = false
		elseif (BulkSelectList[obj] == nil) then
			pace.AddToBulkSelect(obj)
			selected_part_added = true
			for _,v in ipairs(obj:GetChildrenList()) do
				pace.RemoveFromBulkSelect(v)
			end
		end

		--check parents and children
		for _,v in ipairs(BulkSelectList) do
			if table.HasValue(v:GetChildrenList(), obj) then
				--print("selected part is already child to a bulk-selected part!")
				pace.RemoveFromBulkSelect(obj)
				selected_part_added = false
			elseif table.HasValue(obj:GetChildrenList(), v) then
				--print("selected part is already parent to a bulk-selected part!")
				pace.RemoveFromBulkSelect(v)
				selected_part_added = false
			end
		end

		RebuildBulkHighlight()
		if not silent then
			if selected_part_added then
				surface.PlaySound('buttons/button1.wav')
				--test print
				for i,v in ipairs(BulkSelectList) do
					print("["..i.."] = "..v.UniqueID)
				end
				print("\n")
			else surface.PlaySound('buttons/button16.wav') end
		end

		if table.IsEmpty(BulkSelectList) then
			--remove halo hook
			hook.Remove('PreDrawHalos', "BulkSelectHighlights")
		else
			--start halo hook
			hook.Add('PreDrawHalos', "BulkSelectHighlights", function()
				local mode = GetConVar("pac_bulk_select_halo_mode"):GetInt()
				if mode == 0 then return
				elseif mode == 1 then ThinkBulkHighlight()
				elseif mode == 2 then if input.IsKeyDown(input.GetKeyCode(GetConVar("pac_bulk_select_key"):GetString())) then ThinkBulkHighlight() end
				elseif mode == 3 then if input.IsControlDown() then ThinkBulkHighlight() end
				elseif mode == 4 then if input.IsShiftDown() then ThinkBulkHighlight() end
				end
			end)
		end

		for _,v in ipairs(BulkSelectList) do
			--v.pace_tree_node:SetAlpha( 150 )
		end
	end

	function pace.RemoveFromBulkSelect(obj)
		table.RemoveByValue(BulkSelectList, obj)
		obj.pace_tree_node:SetAlpha( 255 )
		obj:SetInfo()
		--RebuildBulkHighlight()
	end

	function pace.AddToBulkSelect(obj)
		table.insert(BulkSelectList, obj)
		if obj.pace_tree_node == nil then return end
		obj:SetInfo("selected in bulk select")
		obj.pace_tree_node:SetAlpha( 150 )
		--RebuildBulkHighlight()
	end
//@note apply properties
	function pace.BulkApplyProperties(obj, policy)
		local basepart = obj
		--[[if not table.HasValue(BulkSelectList,obj) then
			basepart = BulkSelectList[1]
		end]]
		
		local Panel = vgui.Create( "DFrame" )
		Panel:SetSize( 500, 600 )
		Panel:Center()
		Panel:SetTitle("BULK SELECT PROPERTY EDIT - WARNING! EXPERIMENTAL FEATURE!")
		
		Panel:MakePopup()
		surface.CreateFont("Font", {
			font = "Arial",
			extended = true,
			weight = 700,
			size = 15
		})

		local scroll_panel = vgui.Create("DScrollPanel", Panel)
		scroll_panel:SetSize( 500, 540 )
		scroll_panel:SetPos( 0, 60 )
		local thoroughness_tickbox = vgui.Create("DCheckBox", Panel)
		thoroughness_tickbox:SetSize(20,20)
		thoroughness_tickbox:SetPos( 5, 30 )
		local thoroughness_tickbox_label = vgui.Create("DLabel", Panel)
		thoroughness_tickbox_label:SetSize(150,30)
		thoroughness_tickbox_label:SetPos( 30, 25 )
		thoroughness_tickbox_label:SetText("Affect children?")
		thoroughness_tickbox_label:SetFont("Font")
		local basepart_label = vgui.Create("DLabel", Panel)
		basepart_label:SetSize(340,30)
		basepart_label:SetPos( 160, 25 )
		local partinfo = basepart.ClassName
		if basepart.ClassName == "event" then partinfo = basepart.Event  .. " " .. partinfo  end
		local partinfo_icon = vgui.Create("DImage",basepart_label)
		partinfo_icon:SetSize(30,30)
		partinfo_icon:SetPos( 300, 0 )
		partinfo_icon:SetImage(basepart.Icon)
		
		basepart_label:SetText("base part: "..partinfo)
		basepart_label:SetFont("Font")

		local excluded_vars = {"Duplicate","OwnerName","ParentUID","UniqueID","TargetEntityUID"}
		local var_candidates = {}
		
		local shared_properties = {}
		local shared_udata_properties = {}

		for _,prop in pairs(basepart:GetProperties()) do
			
			local shared = true
			for _,part2 in pairs(BulkSelectList) do
				if basepart ~= part2 and basepart.ClassName ~= part2.ClassName then
					if part2["Get" .. prop["key"]] == nil then
						if policy == "harsh" then shared = false end
					end
				end
			end
			if shared and not prop.udata.editor_friendly and basepart["Get" .. prop["key"]] ~= nil then
				shared_properties[#shared_properties + 1] = prop["key"]
			elseif shared and prop.udata.editor_friendly and basepart["Get" .. prop["key"]] == nil then
				shared_udata_properties[#shared_udata_properties + 1] = "event_udata_"..prop["key"]
			end
		end

		if policy == "lenient" then
			local initial_shared_properties = table.Copy(shared_properties)
			local initial_shared_udata_properties = table.Copy(shared_udata_properties)
			for _,part2 in pairs(BulkSelectList) do
				for _,prop in ipairs(part2:GetProperties()) do
					if not (table.HasValue(shared_properties, prop["key"]) or table.HasValue(shared_udata_properties, "event_udata_"..prop["key"])) then
						if part2["Get" .. prop["key"]] ~= nil then
							initial_shared_properties[#initial_shared_properties + 1] = prop["key"]
						elseif part2["Get" .. prop["key"]] == nil then
							initial_shared_udata_properties[#initial_shared_udata_properties + 1] = "event_udata_"..prop["key"]
						end
					end
				end
			end
			shared_properties = initial_shared_properties
			shared_udata_properties = initial_shared_udata_properties
		end
		--populate panels for standard GetSet part properties
		for i,v in pairs(shared_properties) do
			local VAR_PANEL = vgui.Create("DFrame")
			VAR_PANEL:SetSize(500,30)
			VAR_PANEL:SetPos(0,0)
			VAR_PANEL:ShowCloseButton( false )
			local VAR_PANEL_BUTTON = VAR_PANEL:Add("DButton")
			VAR_PANEL_BUTTON:SetSize(80,30)
			VAR_PANEL_BUTTON:SetPos(400,0)
			local VAR_PANEL_EDITZONE
			local var_type
			for _,testpart in ipairs(BulkSelectList) do
				if
				testpart["Get" .. v] ~= nil
				then
					var_type = type(testpart["Get" .. v](testpart))
				end
			end
			if basepart["Get" .. v] ~= nil then var_type = type(basepart["Get" .. v](basepart)) end
			
			if var_type == "number" then
				VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
				VAR_PANEL_EDITZONE:SetSize(200,30)
			elseif var_type == "boolean" then
				VAR_PANEL_EDITZONE = vgui.Create("DCheckBox", VAR_PANEL)
				VAR_PANEL_EDITZONE:SetSize(30,30)
			elseif var_type == "string" then
				VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
				VAR_PANEL_EDITZONE:SetSize(200,30)
			elseif var_type == "Vector" then
				VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
				VAR_PANEL_EDITZONE:SetSize(200,30)
			elseif var_type == "Angle" then
				VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
				VAR_PANEL_EDITZONE:SetSize(200,30)
			else
				VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
				VAR_PANEL_EDITZONE:SetSize(200,30)
			end
			VAR_PANEL_EDITZONE:SetPos(200,0)
			
			VAR_PANEL_BUTTON:SetText("APPLY")
			
			VAR_PANEL:SetTitle("[" .. i .. "]   "..v.."   "..var_type)
			
			VAR_PANEL:Dock( TOP )
			VAR_PANEL:DockMargin( 5, 0, 0, 5 )
			VAR_PANEL_BUTTON.DoClick = function()
				for i,part in pairs(BulkSelectList) do
					local sent_var
					if var_type == "number" then
						sent_var = VAR_PANEL_EDITZONE:GetValue()
						if not tonumber(sent_var) then
							local ok, res = pac.CompileExpression(sent_var)
							if ok then
								sent_var = res() or 0
							end
						end
					elseif var_type == "boolean" then
						sent_var = VAR_PANEL_EDITZONE:GetChecked()
					elseif var_type == "string" then
						sent_var = VAR_PANEL_EDITZONE:GetValue()
						if v == "Name" and sent_var ~= "" then 
							sent_var = sent_var..i
						end
					elseif var_type == "Vector" then
						local str = string.Split(VAR_PANEL_EDITZONE:GetValue(), ",")
						sent_var = Vector()
						sent_var.x = tonumber(str[1]) or 1
						sent_var.y = tonumber(str[2]) or 1
						sent_var.z = tonumber(str[3]) or 1
						if v and not part.ProperColorRange then sent_var = sent_var*255 end
					elseif var_type == "Angle" then
						local str = string.Split(VAR_PANEL_EDITZONE:GetValue(), ",")
						sent_var = Angle()
						sent_var.r = tonumber(str[1]) or 1
						sent_var.g = tonumber(str[2]) or 1
						sent_var.b = tonumber(str[3]) or 1
					else sent_var = VAR_PANEL_EDITZONE:GetValue() end


					if policy == "harsh" then part["Set" .. v](part, sent_var)
					elseif policy == "lenient" then
						if part["Get" .. v] ~= nil then part["Set" .. v](part, sent_var) end
					end
					if thoroughness_tickbox:GetChecked() then
						for _,child in pairs(part:GetChildrenList()) do
							if part["Get" .. v] ~= nil then child["Set" .. v](child, sent_var) end
						end
					end
				end

				pace.RefreshTree(true)
				timer.Simple(0.3, function() BulkSelectRefreshFadedNodes() end)
			end
			scroll_panel:AddItem( VAR_PANEL )
		end
		
		--populate panels for event "userdata" packaged into arguments
		if #shared_udata_properties > 1 then
			local udata_types = {
				hide_in_eventwheel = "boolean",
				find = "string",
				time = "number",
				distance = "number",
				compare = "number",
				min = "number",
				max = "number",
				primary = "boolean",
				amount = "number",
				ammo_id = "number",
				find_ammo = "string",
				hide = "boolean",
				interval = "number",
				offset = "number",
				find_sound = "string",
				mute = "boolean",
				all_players = "boolean"}
			local udata_orders = {
				["command"] = {[1] = "find", [2] = "time", [3] = "hide_in_eventwheel"},
				["timerx"] = {[1] = "seconds", [2] = "reset_on_hide", [3] = "synced_time"},
				["ranger"] = {[1] = "distance", [2] = "compare", [3] = "npcs_and_players_only"},
				["randint"] = {[1] = "compare", [2] = "min", [3] = "max"},
				["random_timer"] = {[1] = "min", [2] = "max", [3] = "compare"},
				["timersys"] = {[1] = "seconds", [2] = "reset_on_hide"},
				["pose_parameter"] = {[1] = "name", [2] = "num"},
				["ammo"] = {[1] = "primary", [2] = "amount"},
				["total_ammo"] = {[1] = "ammo_id", [2] = "amount"},
				["clipsize"] = {[1] = "primary", [2] = "amount"},
				["weapon_class"] = {[1] = "find", [2] = "hide"},
				["timer"] = {[1] = "interval", [2] = "offset"},
				["animation_event"] = {[1] = "find", [2] = "time"},
				["fire_bullets"] = {[1] = "find_ammo", [2] = "time"},
				["emit_sound"] = {[1] = "find_sound", [2] = "time", [3] = "mute"},
				["say"] = {[1] = "find", [2] = "time", [3] = "all_players"}}
			for i,v in pairs(shared_udata_properties) do
				local udata_val_name = string.gsub(v, "event_udata_", "")
				
				local var_type = udata_types[udata_val_name]

				local VAR_PANEL = vgui.Create("DFrame")
				
				VAR_PANEL:SetSize(500,30)
				VAR_PANEL:SetPos(0,0)
				VAR_PANEL:ShowCloseButton( false )
				local VAR_PANEL_BUTTON = VAR_PANEL:Add("DButton")
				VAR_PANEL_BUTTON:SetSize(80,30)
				VAR_PANEL_BUTTON:SetPos(400,0)
				local VAR_PANEL_EDITZONE
				if var_type == "number" then
					VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
					VAR_PANEL_EDITZONE:SetSize(200,30)
				elseif var_type == "boolean" then
					VAR_PANEL_EDITZONE = vgui.Create("DCheckBox", VAR_PANEL)
					VAR_PANEL_EDITZONE:SetSize(30,30)
				elseif var_type == "string" then
					VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
					VAR_PANEL_EDITZONE:SetSize(200,30)
				elseif var_type == "Vector" then
					VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
					VAR_PANEL_EDITZONE:SetSize(200,30)
				elseif var_type == "Angle" then
					VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
					VAR_PANEL_EDITZONE:SetSize(200,30)
				else
					VAR_PANEL_EDITZONE = vgui.Create("DTextEntry", VAR_PANEL)
					VAR_PANEL_EDITZONE:SetSize(200,30)
				end

				VAR_PANEL_EDITZONE:SetPos(200,0)
				VAR_PANEL:SetTitle("[" .. i .. "]   "..string.gsub(v, "event_udata_", "").."   "..var_type)
				VAR_PANEL_BUTTON:SetText("APPLY")
				
				
				VAR_PANEL:Dock( TOP )
				VAR_PANEL:DockMargin( 5, 0, 0, 5 )
				VAR_PANEL_BUTTON.DoClick = function()
					
					for i,part in pairs(BulkSelectList) do
						if part.ClassName == "event" and part.Event == basepart.Event then
							local sent_var
							if var_type == "number" then
								sent_var = VAR_PANEL_EDITZONE:GetValue()
								if not tonumber(sent_var) then
									local ok, res = pac.CompileExpression(sent_var)
									if ok then
										sent_var = res() or 0
									end
								end
							elseif var_type == "boolean" then
								sent_var = VAR_PANEL_EDITZONE:GetChecked()
								if sent_var == true then sent_var = "1"
								else sent_var = "0" end
							elseif var_type == "string" then
								sent_var = VAR_PANEL_EDITZONE:GetValue()
								if v == "Name" and sent_var ~= "" then 
									sent_var = sent_var..i
								end
							else sent_var = VAR_PANEL_EDITZONE:GetValue() end

							local arg_split = string.Split(part:GetArguments(), "@@")
							if #udata_orders[part.Event] ~= #string.Split(part:GetArguments(), "@@") then arg_split[#arg_split + 1] = "0" end

							local sent_var_final = ""
							--		PRESCRIBED			X @@ Y @@ Z ...
							--      EVERY STEP  		ADD
							--		EVERY STEP EXCEPT LAST..@@
							for n,arg in ipairs(arg_split) do
								if udata_orders[part.Event][n] == udata_val_name then
									sent_var_final = sent_var_final .. sent_var
								else
									sent_var_final = sent_var_final .. arg_split[n]
								end
								if n ~= #arg_split then
									sent_var_final = sent_var_final .. "@@"
								end
							end

							part:SetArguments(sent_var_final)
						end

						if thoroughness_tickbox:GetChecked() then
							for _,child in pairs(part:GetChildrenList()) do
								if child.ClassName == "event" and child.Event == basepart.Event then
									local sent_var
									if var_type == "number" then
										sent_var = VAR_PANEL_EDITZONE:GetValue()
										if not tonumber(sent_var) then
											local ok, res = pac.CompileExpression(sent_var)
											if ok then
												sent_var = res() or 0
											end
										end
									elseif var_type == "boolean" then
										sent_var = VAR_PANEL_EDITZONE:GetChecked()
										if sent_var == true then sent_var = "1"
										else sent_var = "0" end
									elseif var_type == "string" then
										sent_var = VAR_PANEL_EDITZONE:GetValue()
										if v == "Name" and sent_var ~= "" then 
											sent_var = sent_var..i
										end
									else sent_var = VAR_PANEL_EDITZONE:GetValue() end

									local arg_split = string.Split(child:GetArguments(), "@@")
									if #udata_orders[basepart.Event] ~= #string.Split(child:GetArguments(), "@@") then arg_split[#arg_split + 1] = "0" end
									local sent_var_final = ""

									for n,arg in ipairs(arg_split) do
										if udata_orders[child.Event][n] == udata_val_name then
											sent_var_final = sent_var_final .. sent_var
										else
											sent_var_final = sent_var_final .. arg_split[n]
										end
										if n ~= #arg_split then
											sent_var_final = sent_var_final .. "@@"
										end
									end
		
									child:SetArguments(sent_var_final)
								end
							end
						end
					end
					
					pace.RefreshTree(true)
					timer.Simple(0.3, function() BulkSelectRefreshFadedNodes() end)
				end
				scroll_panel:AddItem( VAR_PANEL )
			end
		end
	end

	function pace.BulkCutPaste(obj)
		pace.RecordUndoHistory()
		for _,v in ipairs(BulkSelectList) do
			--if a part is inserted onto itself, it should instead serve as a parent
			if v ~= obj then v:SetParent(obj) end
		end
		pace.RecordUndoHistory()
		pace.RefreshTree()
	end

	function pace.BulkCopy(obj)
		if #BulkSelectList == 1 then pace.Copy(obj) end				--at least if there's one selected, we can take it that we want to copy that part
		pace.BulkSelectClipboard = table.Copy(BulkSelectList)		--if multiple parts are selected, copy it to a new bulk clipboard
		print("copied: ")
		TestPrintTable(pace.BulkSelectClipboard,"pace.BulkSelectClipboard")
	end

	function pace.BulkPasteFromBulkClipboard(obj) --paste bulk clipboard into one part
		pace.RecordUndoHistory()
		if not table.IsEmpty(pace.BulkSelectClipboard) then
			for _,v in ipairs(pace.BulkSelectClipboard) do
				local newObj = pac.CreatePart(v.ClassName)
				newObj:SetTable(v:ToTable(), true)
				newObj:SetParent(obj)
			end
		end
		pace.RecordUndoHistory()
		--timer.Simple(0.3, function BulkSelectRefreshFadedNodes(obj) end)
	end

	function pace.BulkPasteFromBulkSelectToSinglePart(obj) --paste bulk selection into one part
		pace.RecordUndoHistory()
		if not table.IsEmpty(BulkSelectList) then
			for _,v in ipairs(BulkSelectList) do
				local newObj = pac.CreatePart(v.ClassName)
				newObj:SetTable(v:ToTable(), true)
				newObj:SetParent(obj)
			end
		end
		pace.RecordUndoHistory()
	end

	function pace.BulkPasteFromSingleClipboard() --paste the normal clipboard into each bulk select item
		pace.RecordUndoHistory()
		if not table.IsEmpty(BulkSelectList) then
			for _,v in ipairs(BulkSelectList) do
				local newObj = pac.CreatePart(pace.Clipboard.self.ClassName)
				newObj:SetTable(pace.Clipboard, true)
				newObj:SetParent(v)
			end
		end
		pace.RecordUndoHistory()
		--timer.Simple(0.3, function BulkSelectRefreshFadedNodes(obj) end)
	end

	function pace.BulkRemovePart()
		pace.RecordUndoHistory()
		if not table.IsEmpty(BulkSelectList) then
			for _,v in ipairs(BulkSelectList) do
				v:Remove()

				if not v:HasParent() and v.ClassName == "group" then
					pace.RemovePartOnServer(v:GetUniqueID(), false, true)
				end
			end
		end
		pace.RefreshTree()
		pace.RecordUndoHistory()
		pace.ClearBulkList()
		--timer.Simple(0.1, function BulkSelectRefreshFadedNodes() end)
	end
//@note part menu
	function pace.OnPartMenu(obj)
		local menu = DermaMenu()
		menu:SetPos(input.GetCursorPos())

		if obj then
			if not obj:HasParent() then
				menu:AddOption(L"wear", function()
					pace.SendPartToServer(obj)
					BulkSelectList = {}
				end):SetImage(pace.MiscIcons.wear)
			end

			menu:AddOption(L"copy", function() pace.Copy(obj) end):SetImage(pace.MiscIcons.copy)
			menu:AddOption(L"paste", function() pace.Paste(obj) end):SetImage(pace.MiscIcons.paste)
			menu:AddOption(L"cut", function() pace.Cut(obj) end):SetImage('icon16/cut.png')
			menu:AddOption(L"paste properties", function() pace.PasteProperties(obj) end):SetImage(pace.MiscIcons.replace)
			menu:AddOption(L"clone", function() pace.Clone(obj) end):SetImage(pace.MiscIcons.clone)
			
			local bulk_apply_properties,bap_icon = menu:AddSubMenu(L"bulk change properties", function() pace.BulkApplyProperties(obj, "harsh") end)
			bap_icon:SetImage('icon16/table_multiple.png')
			bulk_apply_properties:AddOption("Policy: harsh filtering", function() pace.BulkApplyProperties(obj, "harsh") end)
			bulk_apply_properties:AddOption("Policy: lenient filtering", function() pace.BulkApplyProperties(obj, "lenient") end)

			--bulk select
			bulk_menu, bs_icon = menu:AddSubMenu(L"bulk select ("..#BulkSelectList..")", function() pace.DoBulkSelect(obj) end)
				bs_icon:SetImage('icon16/table_multiple.png')
				bulk_menu.GetDeleteSelf = function() return false end

				local mode = GetConVar("pac_bulk_select_halo_mode"):GetInt()
				local info
				if mode == 0 then info = "not halo-highlighted"
				elseif mode == 1 then info = "automatically halo-highlighted"
				elseif mode == 2 then info = "halo-highlighted on custom keypress:"..GetConVar("pac_bulk_select_halo_key"):GetString()
				elseif mode == 3 then info = "halo-highlighted on preset keypress: control"
				elseif mode == 4 then info = "halo-highlighted on preset keypress: shift" end

				bulk_menu:AddOption(L"Bulk select info: "..info, function() end):SetImage(pace.MiscIcons.info)
				bulk_menu:AddOption(L"Bulk select clipboard info: " .. #pace.BulkSelectClipboard .. " copied parts", function() end):SetImage(pace.MiscIcons.info)

				bulk_menu:AddOption(L"Insert (Move / Cut + Paste)", function()
					pace.BulkCutPaste(obj)
				end):SetImage('icon16/arrow_join.png')

				bulk_menu:AddOption(L"Copy to Bulk Clipboard", function()
					pace.BulkCopy(obj)
				end):SetImage(pace.MiscIcons.copy)

				bulk_menu:AddSpacer()

				--bulk paste modes
				bulk_menu:AddOption(L"Bulk Paste (bulk select -> into this part)", function()
					pace.BulkPasteFromBulkSelectToSinglePart(obj)
				end):SetImage('icon16/arrow_join.png')

				bulk_menu:AddOption(L"Bulk Paste (clipboard or this part -> into bulk selection)", function()
					if not pace.Clipboard then pace.Copy(obj) end
					pace.BulkPasteFromSingleClipboard()
				end):SetImage('icon16/arrow_divide.png')

				bulk_menu:AddOption(L"Bulk Paste (Single paste from bulk clipboard -> into this part)", function()
					pace.BulkPasteFromBulkClipboard(obj)
				end):SetImage('icon16/arrow_join.png')

				bulk_menu:AddOption(L"Bulk Paste (Multi-paste from bulk clipboard -> into bulk selection)", function()
					for _,v in ipairs(BulkSelectList) do
						pace.BulkPasteFromBulkClipboard(v)
					end
				end):SetImage('icon16/arrow_divide.png')

				bulk_menu:AddSpacer()

				bulk_menu:AddOption(L"Bulk paste properties from selected part", function()
					pace.Copy(obj)
					for _,v in ipairs(BulkSelectList) do
						pace.PasteProperties(v)
					end
				end):SetImage(pace.MiscIcons.replace)

				bulk_menu:AddOption(L"Bulk paste properties from clipboard", function()
					for _,v in ipairs(BulkSelectList) do
						pace.PasteProperties(v)
					end
				end):SetImage(pace.MiscIcons.replace)

				bulk_menu:AddSpacer()

				bulk_menu:AddOption(L"Bulk Delete", function()
					pace.BulkRemovePart()
				end):SetImage(pace.MiscIcons.clear)

				bulk_menu:AddOption(L"Clear Bulk List", function()
					pace.ClearBulkList()
				end):SetImage('icon16/table_delete.png')

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
			pace.ClearBulkList()
			pace.ClearParts()
		end):SetImage(pace.MiscIcons.clear)

	end
end


do --hover highlight halo
	pac.haloex = include("pac3/libraries/haloex.lua")

	local hover_halo_limit
	local warn = false
	local post_warn_next_allowed_check_time = 0
	local post_warn_next_allowed_warn_time = 0
	local last_culprit_UID = 0
	local last_checked_partUID = 0
	local last_tbl = {}
	local last_bulk_select_tbl = nil
	local last_root_ent = {}
	local last_time_checked = 0

	function pace.OnHoverPart(self)
		local skip = false
		if GetConVar("pac_hover_color"):GetString() == "none" then return end
		hover_halo_limit = GetConVar("pac_hover_halo_limit"):GetInt()

		local tbl = {}
		local ent = self:GetOwner()
		local is_root = ent == self:GetRootPart():GetOwner()

		--decide whether to skip
		--it will skip the part-search loop if we already checked the part recently
		if self.UniqueID == last_checked_partUID then
			skip = true
			if is_root and last_root_ent ~= self:GetRootPart():GetOwner() then
				table.RemoveByValue(last_tbl, last_root_ent)
				table.insert(last_tbl, self:GetRootPart():GetOwner())
			end
			tbl = last_tbl
		end

		--operations : search the part and look for entity-candidates to halo
		if not skip then
			--start with entity, which could be part or entity
			if (is_root and ent:IsValid()) then
				table.insert(tbl, ent)
			else
				if not ((self.ClassName == "group" or self.ClassName == "jiggle") or (self.Hide == true) or (self.Size == 0) or (self.Alpha == 0)) then
					table.insert(tbl, ent)
				end
			end

			--get the children if any
			if self:HasChildren() then
				for _,v in ipairs(self:GetChildrenList()) do
					local can_add = false
					local ent = v:GetOwner()

					--we're not gonna add parts that don't have a specific reason to be haloed or that don't at least group up some haloable models
					--because the table.insert function has a processing load on the memory, and so is halo-drawing
					if (v.ClassName == "model" or v.ClassName ==  "model2" or v.ClassName == "jiggle") then
						can_add = true
					else can_add = false end
					if (v.Hide == true) or (v.Size == 0) or (v.Alpha == 0) or (v:IsHidden()) then
						can_add = false
					end
					if can_add then table.insert(tbl, ent) end
				end
			end
		end

		last_tbl = tbl
		last_root_ent = self:GetRootPart():GetOwner()
		last_checked_partUID = self.UniqueID

		DrawHaloHighlight(tbl)

		--also refresh the bulk-selected nodes' labels because pace.RefreshTree() resets their alphas, but I want to keep the fade because it indicates what's being bulk-selected
		if not skip then timer.Simple(0.3, function() BulkSelectRefreshFadedNodes(self) end) end
	end

	function BulkSelectRefreshFadedNodes(part_trace)
		if refresh_halo_hook then return end
		if part_trace then
			for _,v in ipairs(part_trace:GetRootPart():GetChildrenList()) do
				v.pace_tree_node:SetAlpha( 255 )
			end
		end

		for _,v in ipairs(BulkSelectList) do
			if not v:IsValid() then table.RemoveByValue(BulkSelectList, v)
			else
				v.pace_tree_node:SetAlpha( 150 )
			end
		end
	end

	function RebuildBulkHighlight()
		local parts_tbl = {}
		local ents_tbl = {}
		local hover_tbl = {}
		local ent = {}

		--get potential entities and part-children from each parent in the bulk list
		for _,v in pairs(BulkSelectList) do --this will get parts

			if (v == v:GetRootPart()) then --if this is the root part, send the entity
				table.insert(ents_tbl,v:GetRootPart():GetOwner())
				table.insert(parts_tbl,v)
			else
				table.insert(parts_tbl,v)
			end

			for _,child in ipairs(v:GetChildrenList()) do --now do its children
				table.insert(parts_tbl,child)
			end
		end

		--check what parts are candidates we can give to halo
		for _,v in ipairs(parts_tbl) do
			local can_add = false
			if (v.ClassName == "model" or v.ClassName ==  "model2") then
				can_add = true
			end
			if (v.ClassName == "group") or (v.Hide == true) or (v.Size == 0) or (v.Alpha == 0) or (v:IsHidden()) then
				can_add = false
			end
			if can_add then
				table.insert(hover_tbl, v:GetOwner())
			end
		end

		table.Add(hover_tbl,ents_tbl)
		--TestPrintTable(hover_tbl, "hover_tbl")

		last_bulk_select_tbl = hover_tbl
	end

	function TestPrintTable(tbl, tbl_name)
		MsgC(Color(200,255,200), "TABLE CONTENTS:" .. tbl_name .. " = {\n")
		for _,v in pairs(tbl) do
			MsgC(Color(200,255,200), "\t", tostring(v), ", \n")
		end
		MsgC(Color(200,255,200), "}\n")
	end

	function ThinkBulkHighlight()
		if table.IsEmpty(BulkSelectList) or last_bulk_select_tbl == nil or table.IsEmpty(pac.GetLocalParts()) or (#pac.GetLocalParts() == 1) then
			hook.Remove('PreDrawHalos', "BulkSelectHighlights")
			return
		end
		DrawHaloHighlight(last_bulk_select_tbl)
	end

	function DrawHaloHighlight(tbl)
		if (type(tbl) ~= "table") then return end
		if not pace.Active then
			hook.Remove('PreDrawHalos', "BulkSelectHighlights")
		end

		--Find out the color and apply the halo
		local color_string = GetConVar("pac_hover_color"):GetString()
		local pulse_rate = math.min(math.abs(GetConVar("pac_hover_pulserate"):GetFloat()), 100)
		local pulse = math.sin(SysTime() * pulse_rate) * 0.5 + 0.5
		if pulse_rate == 0 then pulse = 1 end
		local pulseamount

		local halo_color

		if color_string == "rave" then
			halo_color = Color(255*((0.33 + SysTime() * pulse_rate/20)%1), 255*((0.66 + SysTime() * pulse_rate/20)%1), 255*((SysTime() * pulse_rate/20)%1), 255)
			pulseamount = 8
		elseif color_string == "ocean" then
			halo_color = Color(0, 80 + 30*(pulse), 200 + 50*(pulse) * 0.5 + 0.5, 255)
			pulseamount = 4
		elseif color_string == "rainbow" then
			--halo_color = Color(255*(0.5 + 0.5*math.sin(pac.RealTime * pulse_rate/20)),255*(0.5 + 0.5*-math.cos(pac.RealTime * pulse_rate/20)),255*(0.5 + 0.5*math.sin(1 + pac.RealTime * pulse_rate/20)), 255)
			halo_color = HSVToColor(SysTime() * 360 * pulse_rate/20, 1, 1)
			pulseamount = 4
		elseif #string.Split(color_string, " ") == 3 then
			halo_color_tbl = string.Split( color_string, " " )
			for i,v in ipairs(halo_color_tbl) do
				if not isnumber(tonumber(halo_color_tbl[i])) then halo_color_tbl[i] = 0 end
			end
			halo_color = Color(pulse*halo_color_tbl[1],pulse*halo_color_tbl[2],pulse*halo_color_tbl[3],255)
			pulseamount = 4
		else
			halo_color = Color(255,255,255,255)
			pulseamount = 2
		end
		--print("using", halo_color, "blurs=" .. 2, "amount=" .. pulseamount)

		pac.haloex.Add(tbl, halo_color, 2, 2, pulseamount, true, true, pulseamount, 1, 1)
		--haloex.Add( ents, color, blurx, blury, passes, add, ignorez, amount, spherical, shape )
	end
end


--[[ test visualise part
local cachedmodel = ClientsideModel( obj:GetRootPart():GetOwner():GetModel(), RENDERGROUP_BOTH )
		
print(tbl ~= nil)
previewmdl_tbl = previewmdl_tbl or obj:ToTable()

timer.Simple(8,function() Panel:Remove() end)

ENT = cachedmodel
--ENT = icon:GetEntity()
pac.SetupENT(ENT)
ENT:AttachPACPart(tbl, ENT:GetOwner(), false)


function Panel:Paint( w, h )

	local x, y = self:GetPos()
	local vec = LocalPlayer():GetPos()

	cachedmodel:SetPos(vec + Vector(100,0,50))
	cachedmodel:SetAngles(Angle(0,180 + SysTime()*60,0))
	render.RenderView( {
		origin = vec + Vector( 0, 0, 90 ),
		angles = Angle(0,0,0),
		x = x, y = y,
		w = w, h = h,
		fov = 50, aspect = w/h
	} )

end
timer.Simple(8, function()
	SafeRemoveEntity(cachedmodel)
end)]]
