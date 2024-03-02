--include("pac3/editor/client/panels/properties.lua")
include("popups_part_tutorials.lua")

local L = pace.LanguageString
pace.BulkSelectList = {}
pace.BulkSelectUIDs = {}
pace.BulkSelectClipboard = {}
local refresh_halo_hook = true
pace.operations_all_operations = {"wear", "copy", "paste", "cut", "paste_properties", "clone", "spacer", "registered_parts", "save", "load", "remove", "bulk_select", "bulk_apply_properties", "partsize_info", "hide_editor", "expand_all", "collapse_all", "copy_uid", "help_part_info", "reorder_movables"}

pace.operations_default = {"help_part_info", "wear", "copy", "paste", "cut", "paste_properties", "clone", "spacer", "registered_parts", "spacer", "bulk_select", "bulk_apply_properties", "spacer", "save", "load", "spacer", "remove"}
pace.operations_legacy = {"wear", "copy", "paste", "cut", "paste_properties", "clone", "spacer", "registered_parts", "spacer", "save", "load", "spacer", "remove"}

pace.operations_experimental = {"help_part_info", "wear", "copy", "paste", "cut", "paste_properties", "clone", "bulk_select", "spacer", "registered_parts", "spacer", "bulk_apply_properties", "partsize_info", "copy_uid", "spacer", "save", "load", "spacer", "remove"}
pace.operations_bulk_poweruser = {"bulk_select", "clone", "registered_parts", "spacer", "copy", "paste", "cut", "spacer", "wear", "save", "load", "partsize_info"}

if not file.Exists("pac3_config/pac_editor_partmenu_layouts.txt", "DATA") then
	pace.operations_order = pace.operations_default
end

local hover_color = CreateConVar( "pac_hover_color", "255 255 255", FCVAR_ARCHIVE, "R G B value of the highlighting when hovering over pac3 parts, there are also special options: none, ocean, funky, rave, rainbow")
CreateConVar( "pac_hover_pulserate", 20, FCVAR_ARCHIVE, "pulse rate of the highlighting when hovering over pac3 parts")
CreateConVar( "pac_hover_halo_limit", 100, FCVAR_ARCHIVE, "max number of parts before hovering over pac3 parts stops computing to avoid lag")

CreateConVar( "pac_bulk_select_key", "ctrl", FCVAR_ARCHIVE, "Button to hold to use bulk select")
CreateConVar( "pac_bulk_select_halo_mode", 1, FCVAR_ARCHIVE, "Halo Highlight mode.\n0 is no highlighting\n1 is passive\n2 is when the same key as bulk select is pressed\n3 is when control key pressed\n4 is when shift key is pressed.")

CreateConVar("pac_copilot_partsearch_depth", -1, FCVAR_ARCHIVE, "amount of copiloting in the searchable part menu\n-1:none\n0:auto-focus on the text edit for events\n1:bring up a list of clickable event types\nother parts aren't supported yet")
CreateConVar("pac_copilot_make_popup_when_selecting_event", 1, FCVAR_ARCHIVE, "whether to create a popup so you can read what an event does")
CreateConVar("pac_copilot_open_asset_browser_when_creating_part", 0, FCVAR_ARCHIVE, "whether to open the asset browser for models, materials, or sounds")
CreateConVar("pac_copilot_force_preview_cameras", 1, FCVAR_ARCHIVE, "whether to force the editor camera off when creating a camera part")
CreateConVar("pac_copilot_auto_setup_command_events", 0, FCVAR_ARCHIVE, "whether to automatically setup a command event if the name you type doesn't match an existing event. we'll assume you want a command event name.\nif this is set to 0, it will only auto-setup in such a case if you already have such a command event actively present in your events or waiting to be activated by your command parts")
CreateConVar("pac_copilot_auto_focus_main_property_when_creating_part", 1, FCVAR_ARCHIVE, "whether to automatically focus on the main property that defines a part, such as the event's event type, the text's text, the proxy's expression or the command's string.")

--the necessary properties we always edit for certain parts
--others might be opened with the asset browser so this is not the full list
--should be a minimal list because we don't want to get too much in the way of routine editing
local star_properties = {
	["event"] = "Event",
	["proxy"] = "Expression",
	["text"] = "Text",
	["command"] = "String",
	["animation"] = "SequenceName",
	["flex"] = "Flex",
	["bone3"] = "Bone",
	["poseparameter"] = "PoseParameter",
	["damage_zone"] = "Damage",
	["hitscan"] = "Damage"
}

-- load only when hovered above
local function add_expensive_submenu_load(pnl, callback)
	local old = pnl.OnCursorEntered
	pnl.OnCursorEntered = function(...)
		callback()
		pnl.OnCursorEntered = old
		return old(...)
	end
end


local function BulkSelectRefreshFadedNodes(part_trace)
	if refresh_halo_hook then return end
	if part_trace then
		for _,v in ipairs(part_trace:GetRootPart():GetChildrenList()) do
			if IsValid(v.pace_tree_node) then
				v.pace_tree_node:SetAlpha( 255 )
			end

		end
	end

	for _,v in ipairs(pace.BulkSelectList) do
		if not v:IsValid() then table.RemoveByValue(pace.BulkSelectList, v)
		elseif IsValid(v.pace_tree_node) then
			v.pace_tree_node:SetAlpha( 150 )
		end
	end
end

local function RebuildBulkHighlight()
	local parts_tbl = {}
	local ents_tbl = {}
	local hover_tbl = {}
	local ent = {}

	--get potential entities and part-children from each parent in the bulk list
	for _,v in pairs(pace.BulkSelectList) do --this will get parts

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

local function TestPrintTable(tbl, tbl_name)
	MsgC(Color(200,255,200), "TABLE CONTENTS:" .. tbl_name .. " = {\n")
	for _,v in pairs(tbl) do
		MsgC(Color(200,255,200), "\t", tostring(v), ", \n")
	end
	MsgC(Color(200,255,200), "}\n")
end

local function DrawHaloHighlight(tbl)
	if (type(tbl) ~= "table") then return end
	if not pace.Active then
		pac.RemoveHook("PreDrawHalos", "BulkSelectHighlights")
	end

	--Find out the color and apply the halo
	local color_string = GetConVar("pac_hover_color"):GetString()
	local pulse_rate = math.min(math.abs(GetConVar("pac_hover_pulserate"):GetFloat()), 100)
	local pulse = math.sin(SysTime() * pulse_rate) * 0.5 + 0.5
	if pulse_rate == 0 then pulse = 1 end
	local pulseamount

	local halo_color = Color(255,255,255)

	if color_string == "rave" then
		halo_color = Color(255*((0.33 + SysTime() * pulse_rate/20)%1), 255*((0.66 + SysTime() * pulse_rate/20)%1), 255*((SysTime() * pulse_rate/20)%1), 255)
		pulseamount = 8
	elseif color_string == "funky" then
		halo_color = Color(255*((0.33 + SysTime() * pulse_rate/10)%1), 255*((0.2 + SysTime() * pulse_rate/15)%1), 255*((SysTime() * pulse_rate/15)%1), 255)
		pulseamount = 5
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

local function ThinkBulkHighlight()
	if table.IsEmpty(pace.BulkSelectList) or last_bulk_select_tbl == nil or table.IsEmpty(pac.GetLocalParts()) or (#pac.GetLocalParts() == 1) then
		pac.RemoveHook("PreDrawHalos", "BulkSelectHighlights")
		return
	end
	DrawHaloHighlight(last_bulk_select_tbl)
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

	if GetConVar("pac_copilot_open_asset_browser_when_creating_part"):GetBool() then
		timer.Simple(0.5, function()
			local self = nil
			if class_name == "model2" then
				self = pace.current_part.pace_properties["Model"]

				pace.AssetBrowser(function(path)
					if not part:IsValid() then return end
					-- because we refresh the properties

					if IsValid(self) and self.OnValueChanged then
						self.OnValueChanged(path)
					end

					if pace.current_part.SetMaterials then
						local model = pace.current_part:GetModel()
						local part = pace.current_part
						if part.pace_last_model and part.pace_last_model ~= model then
							part:SetMaterials("")
						end
						part.pace_last_model = model
					end

					pace.PopulateProperties(pace.current_part)

					for k,v in ipairs(pace.properties.List) do
						if v.panel and v.panel.part == part and v.key == key then
							self = v.panel
							break
						end
					end

				end, "models")
			elseif class_name == "sound" or class_name == "sound2" then
				if class_name == "sound"then
					self = pace.current_part.pace_properties["Sound"]
				elseif class_name == "sound2" then
					self = pace.current_part.pace_properties["Path"]
				end

				pace.AssetBrowser(function(path)
					if not self:IsValid() then return end

					self:SetValue(path)
					self.OnValueChanged(path)

				end, "sound")
			elseif pace.current_part.pace_properties["LoadVmt"] then
				self = pace.current_part.pace_properties["LoadVmt"]
				pace.AssetBrowser(function(path)
					if not self:IsValid() then return end
					path = string.gsub(string.StripExtension(path), "^materials/", "") or "error"
					self:SetValue(path)
					self.OnValueChanged(path)
					pace.current_part:SetLoadVmt(path)
				end, "materials")

			end
		end)

	end
	if class_name == "camera" and GetConVar("pac_copilot_force_preview_cameras"):GetBool() then
		timer.Simple(0.2, function() pace.EnableView(false) end)
	end
	if GetConVar("pac_copilot_auto_focus_main_property_when_creating_part"):GetBool() then
		if star_properties[part.ClassName] then
			timer.Simple(0.2, function()

				pace.FlashProperty(part, star_properties[part.ClassName], true)

			end)
		end
	end

	return part
end

local last_span_select_part
local last_select_was_span = false
local last_direction

function pace.OnPartSelected(part, is_selecting)
	pace.delaybulkselect = pace.delaybulkselect or 0 --a time updated in shortcuts.lua to prevent common pac operations from triggering bulk selection
	local bulk_key_pressed = input.IsKeyDown(input.GetKeyCode(GetConVar("pac_bulk_select_key"):GetString()))
	if RealTime() > pace.delaybulkselect and bulk_key_pressed and not input.IsKeyDown(input.GetKeyCode("v")) and not input.IsKeyDown(input.GetKeyCode("z")) and not input.IsKeyDown(input.GetKeyCode("y")) then
		--jumping multi-select if holding shift + ctrl
		if bulk_key_pressed and input.IsShiftDown() then
			--ripped some local functions from tree.lua
			local added_nodes = {}
			for i,v in ipairs(pace.tree.added_nodes) do
				if v.part and v:IsVisible() and v:IsExpanded() then
					table.insert(added_nodes, v)
				end
			end

			local startnodenumber = table.KeyFromValue( added_nodes, pace.current_part.pace_tree_node)
			local endnodenumber = table.KeyFromValue( added_nodes, part.pace_tree_node)

			if not startnodenumber or not endnodenumber then return end

			table.sort(added_nodes, function(a, b) return select(2, a:LocalToScreen()) < select(2, b:LocalToScreen()) end)

			local i = startnodenumber

			local direction = math.Clamp(endnodenumber - startnodenumber,-1,1)
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

pace.suppress_flashing_property = false

function pace.FlashProperty(obj, key, edit)
	if pace.suppress_flashing_property then return end
	if not obj.flashing_property then
		obj.flashing_property = true
		timer.Simple(0.1, function()
			if not obj.pace_properties[key] then return end
			obj.pace_properties[key]:Flash()
			pace.current_flashed_property = key
			if edit then
				obj.pace_properties[key]:RequestFocus()
				if obj.pace_properties[key].EditText then
					obj.pace_properties[key]:EditText()
				end
			end
		end)
		timer.Simple(0.3, function() obj.flashing_property = false end)
	end

end

function pace.OnVariableChanged(obj, key, val, not_from_editor)
	local valType = type(val)
	if valType == "Vector" then
		val = Vector(val)
	elseif valType == "Angle" then
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
		pac.RemoveHook("PreDrawHalos", "BulkSelectHighlights")
	end
//@note registered parts
	function pace.AddRegisteredPartsToMenu(menu, parent)
		local partsToShow = {}
		local clicked = false

		pac.AddHook("Think", menu, function()
			local ctrl = input.IsControlDown()

			if clicked and not ctrl then
				menu:SetDeleteSelf(true)
				RegisterDermaMenuForClose(menu)
				CloseDermaMenus()
				return
			end

			menu:SetDeleteSelf(not ctrl)
		end)

		pac.AddHook("CloseDermaMenus", menu, function()
			clicked = true
			if input.IsControlDown() then
				menu:SetVisible(true)
				RegisterDermaMenuForClose(menu)
			end
		end)

		local function add_part(menu, part)
			local newMenuEntry = menu:AddOption(L(part.FriendlyName or part.ClassName:Replace("_", " ")), function()
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
			return newMenuEntry
		end

		local sortedTree = {}
		local PartStructure = {}
		local Groups = {}
		local Parts = pac.GetRegisteredParts()
		for _, part in pairs(pace.GetRegisteredParts()) do
			local class = part.ClassName
			local groupname = "other"

			local group = part.Group or part.Groups or "other"
			--print(group)
			if isstring(group) then
				--MsgC(Color(0,255,0), "\t" .. group .. "\n")
				groupname = group
				group = {group}
			else
				--PrintTable(group)
				Groups[groupname] = Groups[groupname] or {}
				for i,v in ipairs(group) do
					Groups[v] = Groups[v] or {}
					Groups[v][class] = Groups[v][class] or class
				end
			end

			Groups[groupname] = Groups[groupname] or group

			Groups[groupname][class] = Groups[groupname][class] or class

			--[[if isstring(group) then
				group = {group}
			end]]

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

		--file.Write("pac_partgroups.txt", util.TableToKeyValues(Groups))

		local other = sortedTree.other
		sortedTree.other = nil

		if not file.Exists("pac3_config/pac_part_categories.txt", "DATA") then
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

				pac.AddHook("Think", sub, function()
					local ctrl = input.IsControlDown()

					if clicked and not ctrl then
						sub:SetDeleteSelf(true)
						RegisterDermaMenuForClose(sub)
						CloseDermaMenus()
						return
					end

					sub:SetDeleteSelf(not ctrl)
				end)

				pac.AddHook("CloseDermaMenus", sub, function()
					if input.IsControlDown() and trap then
						trap = false
						sub:SetVisible(true)
					end

					RegisterDermaMenuForClose(sub)
				end)
			end
		else --custom part categories
			pace.partgroups = pace.partgroups or util.KeyValuesToTable(file.Read("pac3_config/pac_part_categories.txt", "DATA"))
			Groups = pace.partgroups
		--group is the group name
		--tbl is a shallow table with part class names
		--PrintTable(Groups)
			for group, tbl in pairs(Groups) do

				local sub, pnl = menu:AddSubMenu(group, function()
					if Parts[group] then
						if group == "entity" then
							pace.RecordUndoHistory()
							pace.Call("CreatePart", "entity2", nil, nil, parent)
							pace.RecordUndoHistory()
						elseif group == "model" then
							pace.RecordUndoHistory()
							pace.Call("CreatePart", "model2", nil, nil, parent)
							pace.RecordUndoHistory()
						else
							pace.RecordUndoHistory()
							pace.Call("CreatePart", group, nil, nil, parent)
							pace.RecordUndoHistory()
						end
					end
				end)

--@note partmenu definer
				sub.GetDeleteSelf = function() return false end

				if tbl["icon"] then
					--print(tbl["icon"])
					if pace.MiscIcons[string.gsub(tbl["icon"], "pace.MiscIcons.", "")] then
						pnl:SetImage(pace.MiscIcons[string.gsub(tbl["icon"], "pace.MiscIcons.", "")])
					else
						local img = string.gsub(tbl["icon"], ".png", "") --remove the png extension
						img = string.gsub(img, "icon16/", "") --remove the icon16 base path
						img = "icon16/" .. img .. ".png" --why do this? to be able to write any form and let the program fix the form
						pnl:SetImage(img)
					end
				elseif Parts[group] then
					pnl:SetImage(Parts[group].Icon)
				else
					pnl:SetImage("icon16/page_white.png")
				end
				if tbl["tooltip"] then
					pnl:SetTooltip(tbl["tooltip"])
				end
				--trap = false
				table.sort(tbl, function(a, b) return a < b end)
				for i, class in pairs(tbl) do
					if isstring(i) and Parts[class] then
						local tooltip = pace.TUTORIALS.PartInfos[class].tooltip

						if not tooltip or tooltip == "" then tooltip = "no information available" end
						if #i > 2 then
							local part_submenu = add_part(sub, Parts[class])
							part_submenu:SetTooltip(tooltip)
						end
					end
				end
			end
		end

		for i,v in ipairs(other.parts) do
			add_part(menu, v)
		end

		for class_name, part in pairs(partsToShow) do
			local newMenuEntry = menu:AddOption(L((part.FriendlyName or part.ClassName):Replace("_", " ")), function()
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
		local event_part_template
		for _, part in ipairs(pace.GetRegisteredParts()) do
			if part.ClassName == "event" then
				event_part_template = part
			end
		end
		local mode = GetConVar("pac_copilot_partsearch_depth"):GetInt()
		pace.suppress_flashing_property = false

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

		local result = base:Add("DScrollPanel")
		result:Dock(FILL)
		base.search_mode = "classes"

		local function populate_with_sounds(base,result,filter)
			base.search_mode = "sounds"
			for _,snd in ipairs(pace.bookmarked_ressources["sound"]) do
				if filter ~= nil and filter ~= "" then
					if snd:find(filter, nil, true) then
						table.insert(result.found, snd)
					end
				else
					table.insert(result.found, snd)
				end
			end
			for _,snd in ipairs(result.found) do
				if not isstring(snd) then continue end
				local line = result:Add("DButton")
				line:SetText("")
				line:SetTall(20)
				local btn = line:Add("DImageButton")
				btn:SetSize(16, 16)
				btn:SetPos(4,0)
				btn:CenterVertical()
				btn:SetMouseInputEnabled(false)
				local icon = "icon16/sound.png"

				if string.find(snd, "music") or string.find(snd, "theme") then
					icon = "icon16/music.png"
				elseif string.find(snd, "loop") then
					icon = "icon16/arrow_rotate_clockwise.png"
				end

				btn:SetIcon(icon)
				local label = line:Add("DLabel")
				label:SetTextColor(label:GetSkin().Colours.Category.Line.Text)
				label:SetText(snd)
				label:SizeToContents()
				label:MoveRightOf(btn, 4)
				label:SetMouseInputEnabled(false)
				label:CenterVertical()

				line.DoClick = function()
					if pace.current_part.ClassName == "sound" then
						pace.current_part:SetSound(snd)
					elseif pace.current_part.ClassName == "sound2" then
						pace.current_part:SetPath(snd)
					end
					pace.PopulateProperties(pace.current_part)
					base:Remove()
				end

				line:Dock(TOP)
			end
		end

		local function populate_with_models(base,result,filter)
			base.search_mode = "models"
			for _,mdl in ipairs(pace.bookmarked_ressources["models"]) do
				if filter ~= nil and filter ~= "" then
					if mdl:find(filter, nil, true) then
						table.insert(result.found, mdl)
					end
				else
					table.insert(result.found, mdl)
				end
			end
			for _,mdl in ipairs(result.found) do
				if not isstring(mdl) then continue end
				local line = result:Add("DButton")
				line:SetText("")
				line:SetTall(20)
				local btn = line:Add("DImageButton")
				btn:SetSize(16, 16)
				btn:SetPos(4,0)
				btn:CenterVertical()
				btn:SetMouseInputEnabled(false)
				btn:SetIcon("materials/spawnicons/"..string.gsub(mdl, ".mdl", "")..".png")
				local label = line:Add("DLabel")
				label:SetTextColor(label:GetSkin().Colours.Category.Line.Text)
				label:SetText(mdl)
				label:SizeToContents()
				label:MoveRightOf(btn, 4)
				label:SetMouseInputEnabled(false)
				label:CenterVertical()

				line.DoClick = function()
					if pace.current_part.Model then
						pace.current_part:SetModel(mdl)
						pace.PopulateProperties(pace.current_part)
					end
					base:Remove()
				end

				line:Dock(TOP)
			end
		end

		local function populate_with_events(base,result,filter)
			base.search_mode = "events"
			for e,tbl in pairs(event_part_template.Events) do
				if filter ~= nil and filter ~= "" then
					if e:find(filter, nil, true) then
						table.insert(result.found, e)
					end
				else
					table.insert(result.found, e)
				end
			end
			for _,e in ipairs(result.found) do
				if not isstring(e) then continue end
				local line = result:Add("DButton")
				line:SetText("")
				line:SetTall(20)
				local btn = line:Add("DImageButton")
				btn:SetSize(16, 16)
				btn:SetPos(4,0)
				btn:CenterVertical()
				btn:SetMouseInputEnabled(false)
				btn:SetIcon("icon16/clock.png")
				local label = line:Add("DLabel")
				label:SetTextColor(label:GetSkin().Colours.Category.Line.Text)
				label:SetText(e)
				label:SizeToContents()
				label:MoveRightOf(btn, 4)
				label:SetMouseInputEnabled(false)
				label:CenterVertical()

				line.DoClick = function()
					if pace.current_part.Event then
						pace.current_part:SetEvent(e)
						pace.PopulateProperties(pace.current_part)
					end
					base:Remove()
				end

				line:Dock(TOP)
			end
		end

		local function populate_with_classes(base, result, filter)
			for i, part in ipairs(pace.GetRegisteredParts()) do
				if filter then
					if (part.FriendlyName or part.ClassName):find(filter, nil, true) then
						table.insert(result.found, part)
					end
				else table.insert(result.found, part) end
			end
			table.sort(result.found, function(a, b) return #a.ClassName < #b.ClassName end)
			for _, part in ipairs(result.found) do
				local line = result:Add("DButton")
				line:SetText("")
				line:SetTall(20)
				local remove_now = false
				line.DoClick = function()
					pace.RecordUndoHistory()
					pace.Call("CreatePart", part.ClassName)

					if part.ClassName == "event" then
						remove_now = false
						result:Clear()
						result.found = {}

						if mode == 0 then --auto-focus mode
							remove_now = true
							timer.Simple(0.1, function()
								pace.FlashProperty(pace.current_part, "Event", true)
							end)
						elseif mode == 1 then --event partsearch
							pace.suppress_flashing_property = true
							populate_with_events(base,result,"")
							edit:SetText("")
							edit:RequestFocus()
						else
							remove_now = true
						end
					elseif part.ClassName == "model2" and mode == 1 then --model partsearch
						remove_now = false
						result:Clear()
						result.found = {}
						populate_with_models(base,result,"")
						pace.suppress_flashing_property = true
						edit:SetText("")
						edit:RequestFocus()
					elseif (part.ClassName == "sound" or part.ClassName == "sound2") and mode == 1 then
						remove_now = false
						result:Clear()
						result.found = {}
						populate_with_sounds(base,result,"")
						pace.suppress_flashing_property = true
						edit:SetText("")
						edit:RequestFocus()
					elseif star_properties[result.found[1].ClassName] and (mode == 0 or GetConVar("pac_copilot_auto_focus_main_property_when_creating_part"):GetBool()) then
						pace.suppress_flashing_property = false
						local classname = part.ClassName
						timer.Simple(0.1, function()
							pace.FlashProperty(pace.current_part, star_properties[classname], true)
						end)
						remove_now = true
					else
						remove_now = true
					end
					timer.Simple(0.4, function()
						pace.suppress_flashing_property = false
					end)
					if remove_now then base:Remove() end
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
				label:SetText(L((part.FriendlyName or part.ClassName):Replace("_", " ")))
				label:SizeToContents()
				label:MoveRightOf(btn, 4)
				label:SetMouseInputEnabled(false)
				label:CenterVertical()

				line:Dock(TOP)
			end
		end

		function edit:OnEnter()
			local remove_now = true
			if result.found[1] then
				if base.search_mode == "classes" then
					pace.RecordUndoHistory()
					local part = pace.Call("CreatePart", result.found[1].ClassName)
					pace.RecordUndoHistory()

					if mode == 1 then
						if result.found[1].ClassName == "event" then
							result:Clear()
							populate_with_events(base,result,"")
						elseif result.found[1].ClassName == "model2" then
							result:Clear()
							populate_with_models(base,result,"")
						end

					else
						base:Remove()
					end

				elseif base.search_mode == "events" then
					if pace.current_part.Event then
						pace.current_part:SetEvent()
						pace.PopulateProperties(pace.current_part)
					end
					base:Remove()

				elseif base.search_mode == "models" then
					if mode == 1 then
						result:Clear()
						pace.current_part:SetModel(result.found[1])
						pace.PopulateProperties(pace.current_part)
					else
						base:Remove()
					end
				elseif base.search_mode == "sounds" then
					if mode == 1 then
						result:Clear()
						if pace.current_part.ClassName == "sound" then
							pace.current_part:SetSound(result.found[1])
						elseif pace.current_part.ClassName == "sound2" then
							pace.current_part:SetPath(result.found[1])
						end
						pace.PopulateProperties(pace.current_part)
					else
						base:Remove()
					end

				end

				if result.found[1].ClassName == "event" then
					remove_now = false
					result:Clear()
					result.found = {}
					if mode == 0 then
						remove_now = true
						timer.Simple(0.1, function()
							pace.FlashProperty(pace.current_part, "Event", true)
						end)
					elseif mode == 1 then
						pace.suppress_flashing_property = true
						populate_with_events(base,result,"")
						edit:SetText("")
						edit:RequestFocus()
					else
						remove_now = true
					end
				elseif star_properties[result.found[1].ClassName] and (mode == 0 or GetConVar("pac_copilot_auto_focus_main_property_when_creating_part"):GetBool()) then
					local classname = result.found[1].ClassName
					timer.Simple(0.1, function()
						pace.FlashProperty(pace.current_part, star_properties[classname], true)
					end)
				end
			end
			timer.Simple(0.4, function()
				pace.suppress_flashing_property = false
			end)
			if remove_now then base:Remove() end
		end

		edit.OnValueChange = function(_, str)
			result:Clear()
			result.found = {}
			local remove_now = true

			if base.search_mode == "classes" then
				populate_with_classes(base, result, str)

			elseif base.search_mode == "events" then
				populate_with_events(base,result,str,event_template)

			elseif base.search_mode == "models" then
				populate_with_models(base,result,str)
			elseif base.search_mode == "sounds" then
				populate_with_sounds(base,result,str)
			end

			--base:SetHeight(20 * #result.found + edit:GetTall())
			base:SetHeight(600 + edit:GetTall())

		end

		edit:OnValueChange("")

		pac.AddHook("VGUIMousePressed", "search_part_menu", function(pnl, code)
			if code == MOUSE_LEFT or code == MOUSE_RIGHT then
				if not base:IsOurChild(pnl) then
					base:Remove()
				end
			end
		end)

		timer.Simple(0.1, function()
			base:MoveToFront()
			base:RequestFocus()
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
		pace.ExtendWearTracker(1)
		if table.HasValue(pace.BulkSelectList,obj) then table.RemoveByValue(pace.BulkSelectList,obj) end

		pace.RecordUndoHistory()
		obj:Remove()
		pace.RecordUndoHistory()

		pace.RefreshTree()

		if not obj:HasParent() and obj.ClassName == "group" then
			pace.RemovePartOnServer(obj:GetUniqueID(), false, true)
		end
		
	end

	function pace.SwapBaseMovables(obj1, obj2, promote)
		if not obj1 or not obj2 then return end
		if not obj1.Position or not obj1.Angles or not obj2.Position or not obj2.Angles then return end
		local base_movable_fields = {
			"Position", "PositionOffset", "Angles", "AngleOffset", "EyeAngles", "AimPart", "AimPartName"
		}
		local a_part = obj2
		local b_part = obj1

		if promote then --obj1 takes place of obj2 up or down the hierarchy
			if obj1.Parent == obj2 then
				a_part = obj2
				b_part = obj1
			elseif obj2.Parent == obj1 then
				a_part = obj1
				b_part = obj2
			end
		end

		for i,field in ipairs(base_movable_fields) do
			local a_val = a_part["Get"..field](a_part)
			local b_val = b_part["Get"..field](b_part)
			a_part["Set"..field](a_part, b_val)
			b_part["Set"..field](b_part, a_val)
		end

		if promote then
			b_part:SetParent(a_part.Parent) b_part:SetEditorExpand(true)
			a_part:SetParent(b_part) a_part:SetEditorExpand(true)
		else
			local a_parent = a_part.Parent
			local b_parent = b_part.Parent

			a_part:SetParent(b_parent)
			b_part:SetParent(a_parent)
		end
		pace.RefreshTree()
	end

	function pace.SubstituteBaseMovable(obj,action)
		if action == "create_parent" then
			Derma_StringRequest("Create substitute parent", "Select a class name to create a parent", "model2",
				function(str)
					if str == "model" then str = "model2" end --I don't care, stop using legacy
					local newObj = pac.CreatePart(str)
					if not IsValid(newObj) then return end

					newObj:SetParent(obj.Parent)
					obj:SetParent(newObj)

					for i,v in pairs(obj:GetChildren()) do
						v:SetParent(newObj)
					end

					newObj:SetPosition(obj.Position)
					newObj:SetPositionOffset(obj.PositionOffset)
					newObj:SetAngles(obj.Angles)
					newObj:SetAngleOffset(obj.AngleOffset)
					newObj:SetEyeAngles(obj.EyeAngles)
					newObj:SetAimPart(obj.AimPart)
					newObj:SetAimPartName(obj.AimPartName)
					newObj:SetBone(obj.Bone)
					newObj:SetEditorExpand(true)

					obj:SetPosition(Vector(0,0,0))
					obj:SetPositionOffset(Vector(0,0,0))
					obj:SetAngles(Angle(0,0,0))
					obj:SetAngleOffset(Angle(0,0,0))
					obj:SetEyeAngles(false)
					obj:SetAimPart(nil)
					obj:SetAimPartName("")
					obj:SetBone("head")

					pace.RefreshTree()
				end)
		elseif action == "reorder_child" then
			if obj.Parent then
				if obj.Parent.Position and obj.Parent.Angles then
					pace.SwapBaseMovables(obj, obj.Parent, true)
				end
			end
			pace.RefreshTree()
		elseif action == "cast" then
			Derma_StringRequest("Cast", "Select a class name to convert to. Make sure you know what you\'re doing! It will do a pac_restart after!", "model2",
			function(str)
				if str == obj.ClassName then return end
				if str == "model" then str = "model2" end --I don't care, stop using legacy
				local uid = obj.UniqueID

				if pace.Editor:IsValid() then
					pace.RefreshTree()
					pace.Editor:InvalidateLayout()
					pace.RefreshTree()
				end


				obj.ClassName = str

				timer.Simple(0, function()
					_G.pac_Restart()
					if str == "model2" then
						obj = pac.GetPartFromUniqueID(pac.Hash(pac.LocalPlayer), uid)
						obj:SetModel("models/pac/default.mdl")
					end

				end)
			end)
		end
	end

	function pace.ClearBulkList()
		for _,v in ipairs(pace.BulkSelectList) do
			if v.pace_tree_node ~= nil then v.pace_tree_node:SetAlpha( 255 ) end
			v:SetInfo()
		end
		pace.BulkSelectList = {}
		pac.Message("Bulk list deleted!")
		--surface.PlaySound('buttons/button16.wav')
	end
//@note pace.DoBulkSelect
	function pace.DoBulkSelect(obj, silent)
		obj = obj or pace.current_part
		refresh_halo_hook = false
		--print(obj.pace_tree_node, "color", obj.pace_tree_node:GetFGColor().r .. " " .. obj.pace_tree_node:GetFGColor().g .. " " .. obj.pace_tree_node:GetFGColor().b)
		if obj.ClassName == "timeline_dummy_bone" then return end
		local selected_part_added = false	--to decide the sound to play afterward

		pace.BulkSelectList = pace.BulkSelectList or {}
		if (table.HasValue(pace.BulkSelectList, obj)) then
			pace.RemoveFromBulkSelect(obj)
			selected_part_added = false
		elseif (pace.BulkSelectList[obj] == nil) then
			pace.AddToBulkSelect(obj)
			selected_part_added = true
			for _,v in ipairs(obj:GetChildrenList()) do
				pace.RemoveFromBulkSelect(v)
			end
		end

		--check parents and children
		for _,v in ipairs(pace.BulkSelectList) do
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
				surface.PlaySound("buttons/button1.wav")

			else surface.PlaySound("buttons/button16.wav") end
		end

		if table.IsEmpty(pace.BulkSelectList) then
			--remove halo hook
			pac.RemoveHook("PreDrawHalos", "BulkSelectHighlights")
		else
			--start halo hook
			pac.AddHook("PreDrawHalos", "BulkSelectHighlights", function()
				local mode = GetConVar("pac_bulk_select_halo_mode"):GetInt()
				if hover_color:GetString() == "none" then return end
				if mode == 0 then return
				elseif mode == 1 then ThinkBulkHighlight()
				elseif mode == 2 then if input.IsKeyDown(input.GetKeyCode(GetConVar("pac_bulk_select_key"):GetString())) then ThinkBulkHighlight() end
				elseif mode == 3 then if input.IsControlDown() then ThinkBulkHighlight() end
				elseif mode == 4 then if input.IsShiftDown() then ThinkBulkHighlight() end
				end
			end)
		end

	end

	function pace.RemoveFromBulkSelect(obj)
		table.RemoveByValue(pace.BulkSelectList, obj)
		obj.pace_tree_node:SetAlpha( 255 )
		obj:SetInfo()
		--RebuildBulkHighlight()
	end

	function pace.AddToBulkSelect(obj)
		table.insert(pace.BulkSelectList, obj)
		if obj.pace_tree_node == nil then return end
		obj:SetInfo("selected in bulk select")
		obj.pace_tree_node:SetAlpha( 150 )
		--RebuildBulkHighlight()
	end
	function pace.BulkHide()
		if #pace.BulkSelectList == 0 then return end
		local first_bool = pace.BulkSelectList[1]:GetHide()
		for _,v in ipairs(pace.BulkSelectList) do
			v:SetHide(not first_bool)
		end
	end
//@note apply properties
	function pace.BulkApplyProperties(obj, policy)
		local basepart = obj
		--[[if not table.HasValue(pace.BulkSelectList,obj) then
			basepart = pace.BulkSelectList[1]
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

		local excluded_vars = {
			["Duplicate"] = true,
			["OwnerName"] = true,
			["ParentUID"] = true,
			["UniqueID"] = true,
			["TargetEntityUID"] = true
		}

		local shared_properties = {}
		local shared_udata_properties = {}

		for _,prop in pairs(basepart:GetProperties()) do

			local shared = true
			for _,part2 in pairs(pace.BulkSelectList) do
				if basepart ~= part2 and basepart.ClassName ~= part2.ClassName then
					if part2["Get" .. prop["key"]] == nil then
						if policy == "harsh" then shared = false end
					end
				end
			end
			if shared and not prop.udata.editor_friendly and basepart["Get" .. prop["key"]] ~= nil then
				shared_properties[#shared_properties + 1] = prop["key"]
			elseif shared and prop.udata.editor_friendly and basepart["Get" .. prop["key"]] == nil then
				if not table.HasValue(shared_udata_properties, "event_udata_"..prop["key"]) then
					shared_udata_properties[#shared_udata_properties + 1] = "event_udata_"..prop["key"]
				end
			end
		end

		if policy == "lenient" then
			local initial_shared_properties = table.Copy(shared_properties)
			local initial_shared_udata_properties = table.Copy(shared_udata_properties)
			for _,part2 in pairs(pace.BulkSelectList) do
				for _,prop in ipairs(part2:GetProperties()) do
					if not (table.HasValue(shared_properties, prop["key"]) or table.HasValue(shared_udata_properties, "event_udata_"..prop["key"])) then
						if part2["Get" .. prop["key"]] ~= nil then
							initial_shared_properties[#initial_shared_properties + 1] = prop["key"]
						elseif part2["Get" .. prop["key"]] == nil then
							if not table.HasValue(initial_shared_udata_properties, "event_udata_"..prop["key"]) then
								initial_shared_udata_properties[#initial_shared_udata_properties + 1] = "event_udata_"..prop["key"]
							end
						end
					end
				end
			end
			shared_properties = initial_shared_properties
			shared_udata_properties = initial_shared_udata_properties
		end

		for i,v in ipairs(shared_properties) do
			if excluded_vars[v] then table.remove(shared_properties,i) end
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
			for _,testpart in ipairs(pace.BulkSelectList) do
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
				for i,part in pairs(pace.BulkSelectList) do
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
						if v == "Color" and not part.ProperColorRange then sent_var = sent_var*255 end
					elseif var_type == "Angle" then
						local str = string.Split(VAR_PANEL_EDITZONE:GetValue(), ",")
						sent_var = Angle()
						sent_var.p = tonumber(str[1]) or 1
						sent_var.y = tonumber(str[2]) or 1
						sent_var.r = tonumber(str[3]) or 1
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
		if #shared_udata_properties > 0 then
			local fallback_event_types = {}
			local fallback_event
			for i,v in ipairs(pace.BulkSelectList) do
				if v.ClassName == "event" then
					table.Add(fallback_event_types,v.Event)
					fallback_event = v
				end
			end

			--[[example udata arg from part.Events[part.Event].__registeredArguments
			1:
				1	=	button
				2	=	string
				3:
						default	=	mouse_left
						enums	=	function: 0xa88929ea
						group	=	arguments
			]]

			local function GetEventArgType(part, str)
				if not part.Events then return "string" end
				for argn,arg in ipairs(part.Events[part.Event].__registeredArguments) do
					if arg[1] == str then
						return arg[2]
					end
				end
				if fallback_event then
					for i,e in ipairs(fallback_event_types) do
						for argn,arg in ipairs(fallback_event.Events[e].__registeredArguments) do
							if arg[1] == str then
								return arg[2]
							end
						end
					end
				end
				return "string"
			end

			local function GetEventArgIndex(part,str)
				str = string.gsub(str, "event_udata_", "")

				for argn,arg in ipairs(part.Events[part.Event].__registeredArguments) do
					if arg[1] == str then
						return argn
					end
				end
				return 1
			end

			local function ApplyArgToIndex(args_str, str, index)
				local args_tbl = string.Split(args_str,"@@")
				args_tbl[index] = str
				return table.concat(args_tbl,"@@")
			end

			for i,v in ipairs(shared_udata_properties) do

				local udata_val_name = string.gsub(v, "event_udata_", "")

				local var_type = GetEventArgType(obj, udata_val_name)
				if var_type == nil then var_type = "string" end

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
				VAR_PANEL:SetTitle("[" .. i .. "]   "..udata_val_name.."   "..var_type)
				VAR_PANEL_BUTTON:SetText("APPLY")


				VAR_PANEL:Dock( TOP )
				VAR_PANEL:DockMargin( 5, 0, 0, 5 )
				VAR_PANEL_BUTTON.DoClick = function()

					for i,part in ipairs(pace.BulkSelectList) do
						--PrintTable(part.Events[part.Event].__registeredArguments)
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
						if part.ClassName == "event" and part.Event == basepart.Event then
							part:SetArguments(ApplyArgToIndex(part:GetArguments(), sent_var, GetEventArgIndex(part,v)))
						else
							part:SetProperty(udata_val_name, sent_var)
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

									child:SetArguments(ApplyArgToIndex(child:GetArguments(), sent_var, GetEventArgIndex(child,v)))
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
		for _,v in ipairs(pace.BulkSelectList) do
			--if a part is inserted onto itself, it should instead serve as a parent
			if v ~= obj then v:SetParent(obj) end
		end
		pace.RecordUndoHistory()
		pace.RefreshTree()
	end

	function pace.BulkCutPasteOrdered() --two-state operation
		--first to define an ordered list of parts to move, from bulk select
		--second to transfer these parts to bulk select list
		if not pace.ordered_operation_readystate then
			pace.temp_bulkselect_orderedlist = {}
			for i,v in ipairs(pace.BulkSelectList) do
				pace.temp_bulkselect_orderedlist[i] = v
			end
			pace.ordered_operation_readystate = true
			pace.ClearBulkList()
			pace.FlashNotification("Selected " .. #pace.temp_bulkselect_orderedlist .. " parts for Ordered Insert. Now select " .. #pace.temp_bulkselect_orderedlist .. " parts destinations.")
			surface.PlaySound("buttons/button4.wav")
		else
			if #pace.temp_bulkselect_orderedlist == #pace.BulkSelectList then
				pace.RecordUndoHistory()
				for i,v in ipairs(pace.BulkSelectList) do
					pace.temp_bulkselect_orderedlist[i]:SetParent(v)
				end
				pace.RecordUndoHistory()
				pace.RefreshTree()
				surface.PlaySound("buttons/button6.wav")
			end
			pace.ordered_operation_readystate = false
		end
	end

	function pace.BulkCopy(obj)
		if #pace.BulkSelectList == 1 then pace.Copy(obj) end				--at least if there's one selected, we can take it that we want to copy that part
		pace.BulkSelectClipboard = table.Copy(pace.BulkSelectList)		--if multiple parts are selected, copy it to a new bulk clipboard
		print("[PAC3 bulk select] copied: ")
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
		if not table.IsEmpty(pace.BulkSelectList) then
			for _,v in ipairs(pace.BulkSelectList) do
				local newObj = pac.CreatePart(v.ClassName)
				newObj:SetTable(v:ToTable(), true)
				newObj:SetParent(obj)
			end
		end
		pace.RecordUndoHistory()
	end

	function pace.BulkPasteFromSingleClipboard() --paste the normal clipboard into each bulk select item
		pace.RecordUndoHistory()
		if not table.IsEmpty(pace.BulkSelectList) then
			for _,v in ipairs(pace.BulkSelectList) do
				local newObj = pac.CreatePart(pace.Clipboard.self.ClassName)
				newObj:SetTable(pace.Clipboard, true)
				newObj:SetParent(v)
			end
		end
		pace.RecordUndoHistory()
		--timer.Simple(0.3, function BulkSelectRefreshFadedNodes(obj) end)
	end

	function pace.BulkPasteFromBulkClipboardToBulkSelect()
		for _,v in ipairs(pace.BulkSelectList) do
			pace.BulkPasteFromBulkClipboard(v)
		end
	end

	function pace.BulkRemovePart()
		pace.RecordUndoHistory()
		if not table.IsEmpty(pace.BulkSelectList) then
			for _,v in ipairs(pace.BulkSelectList) do
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

	function pace.CopyUID(obj)
		pace.Clipboard = obj.UniqueID
		SetClipboardText("\"" .. obj.UniqueID .. "\"")
		pace.FlashNotification(tostring(obj) .. " UID " .. obj.UniqueID .. " has been copied")
	end
//@note part menu
	function pace.OnPartMenu(obj)
		local menu = DermaMenu()
		menu:SetPos(input.GetCursorPos())
			--new_operations_order
			--default_operations_order
		--if not obj then obj = pace.current_part end
		if obj then pace.AddClassSpecificPartMenuComponents(menu, obj) end
		for _,option_name in ipairs(pace.operations_order) do
			pace.addPartMenuComponent(menu, obj, option_name)
		end

		--[[if obj then
			if not obj:HasParent() then
				menu:AddOption(L"wear", function()
					pace.SendPartToServer(obj)
					pace.BulkSelectList = {}
				end):SetImage(pace.MiscIcons.wear)
			end

			menu:AddOption(L"copy", function() pace.Copy(obj) end):SetImage(pace.MiscIcons.copy)
			menu:AddOption(L"paste", function() pace.Paste(obj) end):SetImage(pace.MiscIcons.paste)
			menu:AddOption(L"cut", function() pace.Cut(obj) end):SetImage('icon16/cut.png')
			menu:AddOption(L"paste properties", function() pace.PasteProperties(obj) end):SetImage(pace.MiscIcons.replace)
			menu:AddOption(L"clone", function() pace.Clone(obj) end):SetImage(pace.MiscIcons.clone)

			local part_size_info, psi_icon = menu:AddSubMenu(L"get part size information", function()
				local function GetTableSizeInfo(obj_arg)
					if not IsValid(obj_arg) then return {
						raw_bytes = 0,
						info = ""
					} end
					local charsize = #util.TableToJSON(obj_arg:ToTable())

					local kilo_range = -1
					local remainder = charsize*2
					while remainder / 1000 > 1 do
						kilo_range = kilo_range + 1
						remainder = remainder / 1000
					end
					local unit = ""
					if kilo_range == -1 then
						unit = "B"
					elseif kilo_range == 0 then
						unit = "KB"
					elseif (kilo_range == 1) then
						unit = "MB"
					elseif (kilo_range == 2) then
						unit = "GB"
					end
					return {
						raw_bytes = charsize*2,
						info = "raw JSON table size: " .. charsize*2 .. " bytes (" .. remainder .. " " .. unit .. ")"
					}
				end

				local part_size_info = GetTableSizeInfo(obj)
				local part_size_info_root = GetTableSizeInfo(obj:GetRootPart())

				local part_size_info_root_processed = "\t" .. math.Round(100 * part_size_info.raw_bytes / part_size_info_root.raw_bytes,1) .. "% share of root "

				local part_size_info_parent
				local part_size_info_parent_processed
				if IsValid(obj.Parent) then
					part_size_info_parent = GetTableSizeInfo(obj.Parent)
					part_size_info_parent_processed = "\t" .. math.Round(100 * part_size_info.raw_bytes / part_size_info_parent.raw_bytes,1) .. "% share of parent "
					pac.Message(
						obj, " " ..
						part_size_info.info.."\n"..
						part_size_info_parent_processed,obj.Parent,"\n"..
						part_size_info_root_processed,obj:GetRootPart()
					)
				else
					pac.Message(
						obj, " " ..
						part_size_info.info.."\n"..
						part_size_info_root_processed,obj:GetRootPart()
					)
				end

			end)
			psi_icon:SetImage('icon16/drive.png')

			part_size_info:AddOption(L"from bulk select", function()
					local cumulative_bytes = 0
					for _,v in pairs(pace.BulkSelectList) do
						cumulative_bytes = cumulative_bytes + 2*#util.TableToJSON(v:ToTable())
					end
					local kilo_range = -1
					local remainder = cumulative_bytes
					while remainder / 1000 > 1 do
						kilo_range = kilo_range + 1
						remainder = remainder / 1000
					end
					local unit = ""
					if kilo_range == -1 then
						unit = "B"
					elseif kilo_range == 0 then
						unit = "KB"
					elseif (kilo_range == 1) then
						unit = "MB"
					elseif (kilo_range == 2) then
						unit = "GB"
					end
					pac.Message("Bulk selected parts total " .. remainder .. unit)
				end
			)

			local bulk_apply_properties,bap_icon = menu:AddSubMenu(L"bulk change properties", function() pace.BulkApplyProperties(obj, "harsh") end)
			bap_icon:SetImage('icon16/table_multiple.png')
			bulk_apply_properties:AddOption("Policy: harsh filtering", function() pace.BulkApplyProperties(obj, "harsh") end)
			bulk_apply_properties:AddOption("Policy: lenient filtering", function() pace.BulkApplyProperties(obj, "lenient") end)

			--bulk select
			bulk_menu, bs_icon = menu:AddSubMenu(L"bulk select ("..#pace.BulkSelectList..")", function() pace.DoBulkSelect(obj) end)
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
					for _,v in ipairs(pace.BulkSelectList) do
						pace.BulkPasteFromBulkClipboard(v)
					end
				end):SetImage('icon16/arrow_divide.png')

				bulk_menu:AddSpacer()

				bulk_menu:AddOption(L"Bulk paste properties from selected part", function()
					pace.Copy(obj)
					for _,v in ipairs(pace.BulkSelectList) do
						pace.PasteProperties(v)
					end
				end):SetImage(pace.MiscIcons.replace)

				bulk_menu:AddOption(L"Bulk paste properties from clipboard", function()
					for _,v in ipairs(pace.BulkSelectList) do
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
		end]]

		--pace.AddRegisteredPartsToMenu(menu, not obj)

		--menu:AddSpacer()

		--[[if obj then
			local save, pnl = menu:AddSubMenu(L"save", function() pace.SaveParts() end)
			pnl:SetImage(pace.MiscIcons.save)
			add_expensive_submenu_load(pnl, function() pace.AddSaveMenuToMenu(save, obj) end)
		end]]

		--[[local load, pnl = menu:AddSubMenu(L"load", function() pace.LoadParts() end)
		add_expensive_submenu_load(pnl, function() pace.AddSavedPartsToMenu(load, false, obj) end)
		pnl:SetImage(pace.MiscIcons.load)]]

		--[[if obj then
			menu:AddSpacer()
			menu:AddOption(L"remove", function() pace.RemovePart(obj) end):SetImage(pace.MiscIcons.clear)
		end]]

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

function pace.GetPartSizeInformation(obj)
	if not IsValid(obj) then return { raw_bytes = 0, info = "" } end
	local charsize = #util.TableToJSON(obj:ToTable())
	local root_charsize = #util.TableToJSON(obj:GetRootPart():ToTable())

	local roots = {}
	local all_charsize = 0
	for i,v in pairs(pac.GetLocalParts()) do
		roots[v:GetRootPart()] = v:GetRootPart()
	end
	for i,v in pairs(roots) do
		all_charsize = all_charsize + #util.TableToJSON(v:ToTable())
	end

	return {
		raw_bytes = charsize*2,
		info = "raw JSON table size: " .. charsize*2 .. " bytes (" .. string.NiceSize(charsize*2) .. ")",
		root_share_fraction = 	math.Round(charsize / root_charsize, 1),
		root_share_percent = 	math.Round(100 * charsize / root_charsize, 1),
		all_share_fraction = 	math.Round(charsize / all_charsize, 1),
		all_share_percent = 	math.Round(100 * charsize / all_charsize, 1),
		all_size_raw_bytes = 	all_charsize*2,
		all_size_nice = 		string.NiceSize(all_charsize*2)
	}
end

function pace.AddClassSpecificPartMenuComponents(menu, obj)
	if obj.ClassName == "camera" then
		if not obj:IsHidden() then
			if obj ~= pac.active_camera then
				menu:AddOption("View this camera", function()
					pace.ManuallySelectCamera(obj, true)
				end):SetIcon("icon16/star.png")
			else
				menu:AddOption("Unview this camera", function()
					pace.EnableView(true)
					pace.ResetView()
					pac.active_camera_manual = nil
					if obj.pace_tree_node then
						if obj.pace_tree_node.Icon then
							if obj.pace_tree_node.Icon.event_icon then
								obj.pace_tree_node.Icon.event_icon_alt = false
								obj.pace_tree_node.Icon.event_icon:SetImage("event")
								obj.pace_tree_node.Icon.event_icon:SetVisible(false)
							end
						end
					end
				end):SetIcon("icon16/camera_delete.png")
			end
		else
			menu:AddOption("View this camera", function()
				local toggleable_command_events = {}
				for part,reason in pairs(obj:GetReasonsHidden()) do
					if reason == "event hiding" then
						if part.Event == "command" then
							local cmd, time, hide = part:GetParsedArgumentsForObject(part.Events.command)
							if time == 0 then
								toggleable_command_events[part] = cmd
							end
						end
					end
				end
				for part,cmd in pairs(toggleable_command_events) do
					RunConsoleCommand("pac_event", cmd, part.Invert and "1" or "0")
				end
				timer.Simple(0.1, function()
					pace.ManuallySelectCamera(obj, true)
				end)
			end):SetIcon("icon16/star.png")
		end
	elseif obj.ClassName == "command" then
		menu:AddOption("run command", function() obj:Execute() end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "sound" or obj.ClassName == "sound2" then
		menu:AddOption("play sound", function() obj:PlaySound() end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "projectile" then
		local pos, ang = obj:GetDrawPosition()
		menu:AddOption("fire", function() obj:Shoot(pos, ang, obj.NumberProjectiles) end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "hitscan" then
		menu:AddOption("fire", function() obj:Shoot() end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "damage_zone" then
		menu:AddOption("run command", function() obj:OnShow() end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "particles" then
		if obj.FireOnce then
			menu:AddOption("(FireOnce only) spew", function() obj:OnShow() end):SetIcon("icon16/star.png")
		end
	elseif obj.ClassName == "proxy" then
		if string.find(obj.Expression, "timeex") or string.find(obj.Expression, "ezfade") then
			menu:AddOption("(timeex) reset clock", function() obj:OnHide() obj:OnShow() end):SetIcon("icon16/star.png")
		end
	elseif obj.ClassName == "shake" then
		menu:AddOption("activate (editor camera should be off)", function() obj:OnHide() obj:OnShow() end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "event" then
		if obj.Event == "command" then
			local cmd, time, hide = obj:GetParsedArgumentsForObject(obj.Events.command)
			if time == 0 then --toggling mode
				pac.LocalPlayer.pac_command_events[cmd] = pac.LocalPlayer.pac_command_events[cmd] or {name = cmd, time = pac.RealTime, on = 0}
				----MORE PAC JANK?? SOMETIMES, THE 2 NOTATION DOESN'T CHANGE THE STATE YET
				if pac.LocalPlayer.pac_command_events[cmd].on == 1 then
					menu:AddOption("(command) toggle", function() RunConsoleCommand("pac_event", cmd, "0") end):SetIcon("icon16/star.png")
				else
					menu:AddOption("(command) toggle", function() RunConsoleCommand("pac_event", cmd, "1") end):SetIcon("icon16/star.png")
				end
				
			else
				menu:AddOption("(command) trigger", function() RunConsoleCommand("pac_event", cmd) end):SetIcon("icon16/star.png")
			end
			
		end
	end
end

function pace.addPartMenuComponent(menu, obj, option_name)

	if option_name == "save" and obj then
		local save, pnl = menu:AddSubMenu(L"save", function() pace.SaveParts() end)
		pnl:SetImage(pace.MiscIcons.save)
		add_expensive_submenu_load(pnl, function() pace.AddSaveMenuToMenu(save, obj) end)
	elseif option_name == "load" then
		local load, pnl = menu:AddSubMenu(L"load", function() pace.LoadParts() end)
		add_expensive_submenu_load(pnl, function() pace.AddSavedPartsToMenu(load, false, obj) end)
		pnl:SetImage(pace.MiscIcons.load)
	elseif option_name == "wear" and obj then
		if not obj:HasParent() then
			menu:AddOption(L"wear", function()
				pace.SendPartToServer(obj)
				pace.BulkSelectList = {}
			end):SetImage(pace.MiscIcons.wear)
		end
	elseif option_name == "remove" and obj then
		menu:AddOption(L"remove", function() pace.RemovePart(obj) end):SetImage(pace.MiscIcons.clear)
	elseif option_name == "copy" and obj then
		local menu2, pnl = menu:AddSubMenu(L"copy", function() pace.Copy(obj) end)
		pnl:SetIcon(pace.MiscIcons.copy)
		--menu:AddOption(L"copy", function() pace.Copy(obj) end):SetImage(pace.MiscIcons.copy)
		menu2:AddOption(L"Copy part UniqueID", function() pace.CopyUID(obj) end):SetImage(pace.MiscIcons.uniqueid)
	elseif option_name == "paste" and obj then
		menu:AddOption(L"paste", function() pace.Paste(obj) end):SetImage(pace.MiscIcons.paste)
	elseif option_name == "cut" and obj then
		menu:AddOption(L"cut", function() pace.Cut(obj) end):SetImage("icon16/cut.png")
	elseif option_name == "paste_properties" and obj then
		menu:AddOption(L"paste properties", function() pace.PasteProperties(obj) end):SetImage(pace.MiscIcons.replace)
	elseif option_name == "clone" and obj then
		menu:AddOption(L"clone", function() pace.Clone(obj) end):SetImage(pace.MiscIcons.clone)
	elseif option_name == "partsize_info" and obj then
		local function GetTableSizeInfo(obj_arg)
			return pace.GetPartSizeInformation(obj_arg)
		end
		local part_size_info, psi_icon = menu:AddSubMenu(L"get part size information", function()
			local part_size_info = GetTableSizeInfo(obj)
			local part_size_info_root = GetTableSizeInfo(obj:GetRootPart())

			local part_size_info_root_processed = "\t" .. math.Round(100 * part_size_info.raw_bytes / part_size_info_root.raw_bytes,1) .. "% share of root "

			local part_size_info_parent
			local part_size_info_parent_processed
			if IsValid(obj.Parent) then
				part_size_info_parent = GetTableSizeInfo(obj.Parent)
				part_size_info_parent_processed = "\t" .. math.Round(100 * part_size_info.raw_bytes / part_size_info_parent.raw_bytes,1) .. "% share of parent "
				pac.Message(
					obj, " " ..
					part_size_info.info.."\n"..
					part_size_info_parent_processed,obj.Parent,"\n"..
					part_size_info_root_processed,obj:GetRootPart()
				)
			else
				pac.Message(
					obj, " " ..
					part_size_info.info.."\n"..
					part_size_info_root_processed,obj:GetRootPart()
				)
			end

		end)
		psi_icon:SetImage("icon16/drive.png")
		part_size_info:AddOption(L"from bulk select", function()
			local cumulative_bytes = 0
			for _,v in pairs(pace.BulkSelectList) do
				v.partsize_info = pace.GetPartSizeInformation(v)
				cumulative_bytes = cumulative_bytes + 2*#util.TableToJSON(v:ToTable())
			end

			pac.Message("Bulk selected parts total " .. string.NiceSize(cumulative_bytes) .. "\nhere's the breakdown:")
			for _,v in pairs(pace.BulkSelectList) do
				local partsize_info = pace.GetPartSizeInformation(v)
				MsgC(Color(100,255,100), string.NiceSize(partsize_info.raw_bytes)) MsgC(Color(200,200,200), " - ", v, "\n\t  ")
				MsgC(Color(0,255,255), math.Round(100 * partsize_info.raw_bytes/cumulative_bytes,1) .. "%")
				MsgC(Color(200,200,200), " of bulk select total\n\t  ")
				MsgC(Color(0,255,255), math.Round(100 * partsize_info.raw_bytes/partsize_info.all_size_raw_bytes,1) .. "%")
				MsgC(Color(200,200,200), " of total local parts)\n")
			end
		end)
	elseif option_name == "bulk_apply_properties" then
		local bulk_apply_properties,bap_icon = menu:AddSubMenu(L"bulk change properties", function() pace.BulkApplyProperties(obj, "harsh") end)
		bap_icon:SetImage("icon16/application_form.png")
		bulk_apply_properties:AddOption("Policy: harsh filtering", function() pace.BulkApplyProperties(obj, "harsh") end)
		bulk_apply_properties:AddOption("Policy: lenient filtering", function() pace.BulkApplyProperties(obj, "lenient") end)
	elseif option_name == "bulk_select" then
		bulk_menu, bs_icon = menu:AddSubMenu(L"bulk select ("..#pace.BulkSelectList..")", function() pace.DoBulkSelect(obj) end)
		bs_icon:SetImage("icon16/table_multiple.png")
		bulk_menu.GetDeleteSelf = function() return false end

		local mode = GetConVar("pac_bulk_select_halo_mode"):GetInt()
		local info
		if mode == 0 then info = "not halo-highlighted"
		elseif mode == 1 then info = "automatically halo-highlighted"
		elseif mode == 2 then info = "halo-highlighted on custom keypress:"..GetConVar("pac_bulk_select_halo_key"):GetString()
		elseif mode == 3 then info = "halo-highlighted on preset keypress: control"
		elseif mode == 4 then info = "halo-highlighted on preset keypress: shift" end

		bulk_menu:AddOption(L"Bulk select info: "..info):SetImage(pace.MiscIcons.info)
		if #pace.BulkSelectList == 0 then
			bulk_menu:AddOption(L"Bulk select info: nothing selected"):SetImage(pace.MiscIcons.info)
		else
			local copied, pnl = bulk_menu:AddSubMenu(L"Bulk select info: " .. #pace.BulkSelectList .. " copied parts")
			pnl:SetImage(pace.MiscIcons.info)
			for i,v in ipairs(pace.BulkSelectList) do
				local name_str
				if v.Name == "" then
					name_str = tostring(v)
				else
					name_str = v.Name
				end

				copied:AddOption(i .. " : " .. name_str .. " (" .. v.ClassName .. ")"):SetIcon(v.Icon)
			end
		end
		if #pace.BulkSelectClipboard == 0 then
			bulk_menu:AddOption(L"Bulk select clipboard info: nothing copied"):SetImage(pace.MiscIcons.info)
		else
			local copied, pnl = bulk_menu:AddSubMenu(L"Bulk select clipboard info: " .. #pace.BulkSelectClipboard .. " copied parts")
			pnl:SetImage(pace.MiscIcons.info)
			for i,v in ipairs(pace.BulkSelectClipboard) do
				local name_str
				if v.Name == "" then
					name_str = tostring(v)
				else
					name_str = v.Name
				end

				copied:AddOption(i .. " : " .. name_str .. " (" .. v.ClassName .. ")"):SetIcon(v.Icon)
			end
		end

		bulk_menu:AddOption(L"Insert (Move / Cut + Paste)", function()
			pace.BulkCutPaste(obj)
		end):SetImage("icon16/arrow_join.png")

		if not pace.ordered_operation_readystate then
			bulk_menu:AddOption(L"prepare Ordered Insert (please select parts in order beforehand)", function()
				pace.BulkCutPasteOrdered()
			end):SetImage("icon16/text_list_numbers.png")
		else
			bulk_menu:AddOption(L"do Ordered Insert (select destinations in order)", function()
				pace.BulkCutPasteOrdered()
			end):SetImage("icon16/arrow_switch.png")
		end


		bulk_menu:AddOption(L"Copy to Bulk Clipboard", function()
			pace.BulkCopy(obj)
		end):SetImage(pace.MiscIcons.copy)

		bulk_menu:AddSpacer()

		--bulk paste modes
		bulk_menu:AddOption(L"Bulk Paste (bulk select -> into this part)", function()
			pace.BulkPasteFromBulkSelectToSinglePart(obj)
		end):SetImage("icon16/arrow_join.png")

		bulk_menu:AddOption(L"Bulk Paste (clipboard or this part -> into bulk selection)", function()
			if not pace.Clipboard then pace.Copy(obj) end
			pace.BulkPasteFromSingleClipboard()
		end):SetImage("icon16/arrow_divide.png")

		bulk_menu:AddOption(L"Bulk Paste (Single paste from bulk clipboard -> into this part)", function()
			pace.BulkPasteFromBulkClipboard(obj)
		end):SetImage("icon16/arrow_join.png")

		bulk_menu:AddOption(L"Bulk Paste (Multi-paste from bulk clipboard -> into bulk selection)", function()
			pace.BulkPasteFromBulkClipboardToBulkSelect()
		end):SetImage("icon16/arrow_divide.png")

		bulk_menu:AddSpacer()

		bulk_menu:AddOption(L"Bulk paste properties from selected part", function()
			pace.Copy(obj)
			for _,v in ipairs(pace.BulkSelectList) do
				pace.PasteProperties(v)
			end
		end):SetImage(pace.MiscIcons.replace)

		bulk_menu:AddOption(L"Bulk paste properties from clipboard", function()
			for _,v in ipairs(pace.BulkSelectList) do
				pace.PasteProperties(v)
			end
		end):SetImage(pace.MiscIcons.replace)

		bulk_menu:AddOption(L"Deploy a numbered command event series ("..#pace.BulkSelectList..")", function()
			Derma_StringRequest(L"command series", L"input the base name", "", function(str)
				str = string.gsub(str, " ", "")
				for i,v in ipairs(pace.BulkSelectList) do
					part = pac.CreatePart("event")
					part:SetParent(v)
					part.Event = "command"
					part.Arguments = str..i.."@@0@@0"
				end
			end)
		end):SetImage("icon16/clock.png")

		bulk_menu:AddOption(L"Pack into a new root group", function()
			root = pac.CreatePart("group")
			for i,v in ipairs(pace.BulkSelectList) do
				v:SetParent(root)
			end
		end):SetImage("icon16/world.png")

		bulk_menu:AddSpacer()

		bulk_menu:AddOption(L"Bulk Delete", function()
			pace.BulkRemovePart()
		end):SetImage(pace.MiscIcons.clear)

		bulk_menu:AddOption(L"Clear Bulk List", function()
			pace.ClearBulkList()
		end):SetImage("icon16/table_delete.png")
	elseif option_name == "spacer" then
		menu:AddSpacer()
	elseif option_name == "registered_parts" then
		pace.AddRegisteredPartsToMenu(menu, not obj)
	elseif option_name == "hide_editor" then
		menu:AddOption(L"hide editor / toggle focus", function() pace.Call("ToggleFocus") end):SetImage("icon16/zoom.png")
	elseif option_name == "expand_all" and obj then
		menu:AddOption(L"expand all", function()
		obj:CallRecursive("SetEditorExpand", true)
		pace.RefreshTree(true) end):SetImage("icon16/arrow_down.png")
	elseif option_name == "collapse_all" and obj then
		menu:AddOption(L"collapse all", function()
		obj:CallRecursive("SetEditorExpand", false)
		pace.RefreshTree(true) end):SetImage("icon16/arrow_in.png")
	elseif option_name == "copy_uid" and obj then
		local menu2, pnl = menu:AddSubMenu(L"Copy part UniqueID", function() pace.CopyUID(obj) end)
		pnl:SetIcon(pace.MiscIcons.uniqueid)
	elseif option_name == "help_part_info" and obj then
		menu:AddOption(L"View help or info about this part", function() pac.AttachInfoPopupToPart(obj, nil, {
			obj_type = GetConVar("pac_popups_preferred_location"):GetString(),
			hoverfunc = "open",
			pac_part = pace.current_part,
			panel_exp_width = 900, panel_exp_height = 400
		}) end):SetImage("icon16/information.png")
	elseif option_name == "reorder_movables" and obj then
		if (obj.Position and obj.Angles and obj.PositionOffset) then
			local substitute, pnl = menu:AddSubMenu("Reorder / replace base movable")
			pnl:SetImage("icon16/application_double.png")
			substitute:AddOption("Create a parent for position substitution", function() pace.SubstituteBaseMovable(obj, "create_parent") end)
			if obj.Parent then
				if obj.Parent.Position and obj.Parent.Angles then
					substitute:AddOption("Switch with parent", function() pace.SubstituteBaseMovable(obj, "reorder_child") end)
				end
			end
			substitute:AddOption("Switch with another (select two parts with bulk select)", function() pace.SwapBaseMovables(pace.BulkSelectList[1], pace.BulkSelectList[2], false) end)
			substitute:AddOption("Recast into new class (warning!)", function() pace.SubstituteBaseMovable(obj, "cast") end)
		end
	end

end

--destructive tool
function pace.UltraCleanup(obj)
	if not obj then return end

	local root = obj:GetRootPart()
	local safe_parts = {}
	local parts_have_saved_parts = {}
	local marked_for_deletion = {}

	local function IsImportantMarked(part)
		if not IsValid(part) then return false end
		if part.Notes == "important" then return true end
		return false
	end

	local function FoundImportantMarkedParent(part)
		if not IsValid(part) then return false end
		if IsImportantMarked(part) then return true end
		local root = part:GetRootPart()
		local parent = part
		while parent ~= root do
			if parent.Notes and parent.Notes == "important" then return true end
			parent = parent:GetParent()
		end
		return false
	end

	local function Important(part)
		if not IsValid(part) then return false end
		return IsImportantMarked(part) or FoundImportantMarkedParent(part)
	end

	local function CheckPartWithLinkedParts(part)
		local found_parts = false
		local part_roles = {
			["AimPart"] = nil, --base_movable
			["OutfitPart"] = nil, --projectile bullets
			["EndPoint"] = nil --beams
		}

		if part.ClassName == "projectile" then
			if part.OutfitPart then
				if part.OutfitPart:IsValid() then
					part_roles["OutfitPart"] = part.OutfitPart
					found_parts = true
				end
			end
		end

		if part.AimPart then
			if part.AimPart:IsValid() then
				part_roles["AimPart"] = part.AimPart
				found_parts = true
			end
		end

		if part.ClassName == "beam" then
			if part.EndPoint then
				if part.EndPoint:IsValid() then
					part_roles["EndPoint"] = part.EndPoint
					found_parts = true
				end
			end
		end

		parts_have_saved_parts[part] = found_parts
		if found_parts then
			safe_parts[part] = part
			for i2,v2 in pairs(part_roles) do
				if v2 then
					safe_parts[v2] = v2
				end
			end
		end
	end

	local function IsSafe(part)
		local safe = true

		if part.Notes then
			if #(part.Notes) > 20 then return true end --assume if we write 20 characters in the notes then it's fine to keep it...
		end

		if part.ClassName == "event" or part.ClassName == "proxy" or part.ClassName == "command" then
			return false
		end

		if not part:IsHidden() and not part.Hide then
		else
			safe = false
			if string.find(part.ClassName,"material") then
				safe = true
			end
		end

		return safe
	end

	local function IsMildlyRisky(part)
		if part.ClassName == "event" or part.ClassName == "proxy" or part.ClassName == "command" then
			if not part:IsHidden() and not part.Hide then
				return true
			end
			return false
		end
		return false
	end

	local function IsHangingPart(part)
		if IsImportantMarked(part) then return false end
		local c = part.ClassName

		--unlooped sounds or 0 volume should be wiped
		if c == "sound" or c == "ogg" or c == "webaudio" or c == "sound2" then
			if part.Volume == 0 then return true end
			if part.Loop ~= nil then
				if not part.Loop then return true end
			end
			if part.PlayCount then
				if part.PlayCount == 0 then return true end
			end
		end

		--fireonce particles should be wiped
		if c == "particle" then
			if part.NumberParticles == 0 or part.FireOnce then return true end
		end

		--0 weight flexes have to be removed
		if c == "flex" then
			if part.Weight < 0.1 then return true end
		end

		if c == "sunbeams" then
			if math.abs(part.Multiplier) == 0 then return true end
		end

		--other parts to leave forever
		if c == "shake" or c == "gesture"  then
			return true
		end
	end

	local function FindNearestSafeParent(part)
		if not part then return end
		local root = part:GetRootPart()
		local parent = part:GetParent()
		local child = part
		local i = 0
		while parent ~= root do
			if i > 10 then return parent end
			i = i + 1
			if IsSafe(parent) then
				return parent
			elseif not IsMildlyRisky(parent) then
				return parent
			elseif not parent:IsHidden() and parent.Hide then
				return parent
			end
			child = parent
			parent = parent:GetParent()
		end
		return parent
	end


	local function SafeRemove(part)
		if IsValid(part) then
			if IsSafe(part) or Important(part) then
				return
			elseif IsMildlyRisky(part) then
				if table.Count(part:GetChildren()) == 0 then
					part:Remove()
				end
			end
		end
	end

	--does algorithm needs to be recursive?
		--delete absolute unsafes: hiddens.
			--now there are safe events.
			--extract children into nearest safe parent BUT ONLY DO IT VIA ITS DOMINANT and IF IT'S SAFE
		--delete remaining unsafes: events, hiddens, commands ...
			--but we still need to check for children to extract!

	local function Move_contents_up(part) --this will be the powerhouse recursor
		local parent = FindNearestSafeParent(part)
		--print(part, "nearest parent is", parent)
		for _,child in pairs(part:GetChildren()) do
			if child:IsHidden() or child.Hide then 				--hidden = delete
				marked_for_deletion[child] = child
			else 												--visible = possible container = check
				if table.Count(child:GetChildren()) == 0 then 	--dead end = immediate action
					if IsSafe(child) then 						--safe = keep but now extract it
						child:SetParent(parent)
						--print(child, "moved to", parent)
						safe_parts[child] = child
					elseif child:IsHidden() or child.Hide then	--hidden = delete
						marked_for_deletion[child] = child
					end
				else											--parent = process the children? done by the recursion
																--the parent still needs to be moved up
					child:SetParent(parent)

					safe_parts[child] = child
					Move_contents_up(child)						--recurse
				end

			end

		end
	end

	--find parts to delete
		--first pass: absolute unsafes: hidden parts
	for i,v in pairs(root:GetChildrenList()) do
		if v:IsHidden() or v.Hide then
			if not FoundImportantMarkedParent(v) then
				v:Remove()
			end

		end
	end

		--second pass:
			--A: mark safe parts
			--B: extract children in remaining unsafes (i.e. break the chain of an event)
	for i,v in pairs(root:GetChildrenList()) do
		if IsSafe(v) then
			safe_parts[v] = v
			CheckPartWithLinkedParts(v)
			if IsMildlyRisky(v:GetParent()) then
				v:SetParent(v:GetParent():GetParent())
			end
		elseif IsMildlyRisky(v) then
			Move_contents_up(v)
			marked_for_deletion[v] = v
		end

	end
		--after that, the remaining events etc are marked
	for i,v in pairs(root:GetChildrenList()) do
		if IsMildlyRisky(v) then
			marked_for_deletion[v] = v
		end
	end

	pace.RefreshTree()
	--go through delete tables except when marked as important or those protected by these
	for i,v in pairs(marked_for_deletion) do

		local delete = false

		if not safe_parts[v] then

			if v:IsValid() then
				delete = true
			end
			if FoundImportantMarkedParent(v) then
				delete = false
			end
		end

		if delete then SafeRemove(v) end
	end

		--third pass: cleanup the last remaining unwanted parts
	for i,v in pairs(root:GetChildrenList()) do
		--remove remaining events after their children have been freed, and delete parts that don't have durable use, like sounds that aren't looping
		if IsMildlyRisky(v) or IsHangingPart(v) then
			if not Important(v) then
				v:Remove()
			end
		end
	end

		--fourth pass: delete bare containing nothing left
	for i,v in pairs(root:GetChildrenList()) do
		if v.ClassName == "group" then
			local bare = true
			for i2,v2 in pairs(v:GetChildrenList()) do
				if v2.ClassName ~= "group" then
					bare = false
				end
			end
			if bare then v:Remove() end
		end
	end
	pace.RefreshTree()

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

end

--custom info panel
--[[args
tbl = {
	obj = part.Label, --the associated object, could be a tree label, mouse, part etc.
	pac_part = part --a pac part reference, if applicable
	obj_type = "pac tree label",
	hoverfunc = function() end,
	doclickfunc = function() end,
	panel_exp_width = 300, panel_exp_height = 200
}

]]

