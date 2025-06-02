--include("pac3/editor/client/panels/properties.lua")
include("popups_part_tutorials.lua")

local L = pace.LanguageString
pace.BulkSelectList = {}
pace.BulkSelectUIDs = {}
pace.BulkSelectClipboard = {}
local refresh_halo_hook = true
pace.operations_all_operations = {"wear", "copy", "paste", "cut", "paste_properties", "clone", "spacer", "registered_parts", "save", "load", "remove", "bulk_select", "bulk_apply_properties", "partsize_info", "hide_editor", "expand_all", "collapse_all", "copy_uid", "help_part_info", "reorder_movables", "arraying_menu", "criteria_process", "bulk_morph", "view_goto", "view_lockon"}

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

CreateConVar("pac_bulk_select_key", "ctrl", FCVAR_ARCHIVE, "Button to hold to use bulk select")
CreateConVar("pac_bulk_select_halo_mode", 1, FCVAR_ARCHIVE, "Halo Highlight mode.\n0 is no highlighting\n1 is passive\n2 is when the same key as bulk select is pressed\n3 is when control key pressed\n4 is when shift key is pressed.")
local bulk_select_subsume = CreateConVar("pac_bulk_select_subsume", "1", FCVAR_ARCHIVE, "Whether bulk-selecting a part implicitly deselects its children since they are covered by the parent already.\nWhile it can provide a clearer view of what's being selected globally which simplifies broad operations like deleting, moving and copying, it prevents targeted operations on nested parts like bulk property editing.")
local bulk_select_deselect = CreateConVar("pac_bulk_select_deselect", "1", FCVAR_ARCHIVE, "Whether selecting a part without holding bulk select key will deselect the bulk selected parts")
local bulkselect_cursortext = CreateConVar("pac_bulk_select_cursor_info", "1", FCVAR_ARCHIVE, "Whether to draw some info next to your cursor when there is a bulk selection")

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
			if bulk_select_subsume:GetBool() then
				v.pace_tree_node:SetAlpha( 150 )
			else
				v.pace_tree_node:SetAlpha( 255 )
			end
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
	if pace.camera_orthographic then return end

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

pac.AddHook("VGUIMousePressed", "kecode_tracker", function(pnl, mc)
	pace.last_mouse_code = mc
end)

function pace.OnPartSelected(part, is_selecting)
	pace.delaybulkselect = pace.delaybulkselect or 0 --a time updated in shortcuts.lua to prevent common pac operations from triggering bulk selection
	local bulk_key_pressed = input.IsKeyDown(input.GetKeyCode(GetConVar("pac_bulk_select_key"):GetString()))

	if (not bulk_key_pressed) and bulk_select_deselect:GetBool() and not IsValid(pace.bulk_apply_properties_active) then
		if pace.last_mouse_code == MOUSE_LEFT then pace.ClearBulkList(true) end
	end

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
	if pace.bypass_tree then return end

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

	function pace.SubstituteBaseMovable(obj,action,cast_class)
		local prompt = (cast_class == nil)
		cast_class = cast_class or "model2"
		if action == "create_parent" then
			local function func(str)
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
			end
			if prompt then
				Derma_StringRequest("Create substitute parent", "Select a class name to create a parent", "model2", function(str) func(str) end)
			else
				func(cast_class)
			end
		elseif action == "reorder_child" then
			if obj.Parent then
				if obj.Parent.Position and obj.Parent.Angles then
					pace.SwapBaseMovables(obj, obj.Parent, true)
				end
			end
			pace.RefreshTree()
		elseif action == "cast" then
			local function func(str)
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
			end
			if prompt then
				Derma_StringRequest("Cast", "Select a class name to convert to. Make sure you know what you\'re doing! It will do a pac_restart after!", "model2", function(str) func(str) end)
			else
				func(cast_class)
			end
		end
		pace.recently_substituted_movable_part = obj
	end

	function pace.ClearBulkList(silent)
		for _,v in ipairs(pace.BulkSelectList) do
			if IsValid(v.pace_tree_node) then v.pace_tree_node:SetAlpha( 255 ) end
			v:SetInfo()
		end
		pace.BulkSelectList = {}
		if not silent then pac.Message("Bulk list deleted!") end
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
			pace.FlashNotification("Bulk select: de-selected " .. tostring(obj))
			selected_part_added = false
		elseif (pace.BulkSelectList[obj] == nil) then
			pace.AddToBulkSelect(obj)
			pace.FlashNotification("Bulk select: selected " .. tostring(obj))
			selected_part_added = true
			if bulk_select_subsume:GetBool() then
				for _,v in ipairs(obj:GetChildrenList()) do
					pace.RemoveFromBulkSelect(v)
				end
			end
		end

		if bulk_select_subsume:GetBool() then
			--check parents and children
			for _,v in ipairs(pace.BulkSelectList) do
				if table.HasValue(v:GetChildrenList(), obj) then
					--print("selected part is already child to a bulk-selected part!")
					pace.RemoveFromBulkSelect(obj)
					pace.FlashNotification("")
					selected_part_added = false
				elseif table.HasValue(obj:GetChildrenList(), v) then
					--print("selected part is already parent to a bulk-selected part!")
					pace.RemoveFromBulkSelect(v)
					pace.FlashNotification("")
					selected_part_added = false
				end
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
		if IsValid(obj.pace_tree_node) then
			obj.pace_tree_node:SetAlpha( 255 )
		end
		obj:SetInfo()
		--RebuildBulkHighlight()
	end

	function pace.AddToBulkSelect(obj)
		table.insert(pace.BulkSelectList, obj)
		if obj.pace_tree_node == nil then return end
		obj:SetInfo("selected in bulk select")
		if IsValid(obj.pace_tree_node) then
			if bulk_select_subsume:GetBool() then
				obj.pace_tree_node:SetAlpha( 150 )
			else
				obj.pace_tree_node:SetAlpha( 255 )
			end
			
		end
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
		pace.bulk_apply_properties_active = Panel

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
			if shared and basepart["Get" .. prop["key"]] ~= nil then
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
		table.sort(shared_properties)

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

	function pace.BulkMorphProperty()
		if #pace.BulkSelectList == 0 then timer.Simple(0.3, function()
			pace.FlashNotification("Bulk Morph Property needs parts in bulk select!") end)
		end

		local parts_backup_properties_values = {}
		local excluded_properties = {["ParentUID"] = true,["UniqueID"] = true}
		for i,v in ipairs(pace.BulkSelectList) do
			parts_backup_properties_values[v] = {}
			for _,prop in pairs(v:GetProperties()) do
				if not excluded_properties[prop.key] then
					if v["Get"..prop.key] then
						parts_backup_properties_values[v][prop.key] = v["Get"..prop.key](v)
					end
				end
			end
		end

		local main_panel = vgui.Create("DFrame")
		main_panel:SetTitle("Morph properties")
		main_panel:SetSize(400,280)

		local properties_pnl = pace.CreatePanel("properties", main_panel) properties_pnl:SetSize(380,150) properties_pnl:SetPos(10,125)
		local start_value = pace.CreatePanel("properties_number") properties_pnl:AddKeyValue("StartValue",start_value)
		local end_value = pace.CreatePanel("properties_number") properties_pnl:AddKeyValue("EndValue",end_value)
		start_value:SetNumberValue(1) end_value:SetNumberValue(1)
		local function swap_properties(property, property_type, success)
			properties_pnl:Clear()
			properties_pnl:InvalidateLayout()
			--timer.Simple(0.2, function()
				if success then
					start_value = pace.CreatePanel("properties_" .. property_type, properties_pnl) properties_pnl:AddKeyValue("StartValue",start_value)
					end_value = pace.CreatePanel("properties_" .. property_type, properties_pnl) properties_pnl:AddKeyValue("EndValue",end_value)
					if property_type == "vector" then
						function start_value.OnValueChanged(val)
							if isstring(val) then
								if val == "" then return end
								local x,y,z = unpack(string.Split(val, " "))
								val = Vector(x,y,z)
							end
							start_value:SetValue(val)
						end
						function end_value.OnValueChanged(val)
							if isstring(val) then
								if val == "" then return end
								local x,y,z = unpack(string.Split(val, " "))
								val = Vector(x,y,z)
							end
							end_value:SetValue(val)
						end
					elseif property_type == "angle" then
						function start_value.OnValueChanged(val)
							if isstring(val) then
								if val == "" then return end
								local x,y,z = unpack(string.Split(val, " "))
								val = Angle(x,y,z)
							end
							start_value:SetValue(val)
						end
						function end_value.OnValueChanged(val)
							if isstring(val) then
								if val == "" then return end
								local x,y,z = unpack(string.Split(val, " "))
								val = Angle(x,y,z)
							end
							end_value:SetValue(val)
						end
					elseif property_type == "color" then
						function start_value.OnValueChanged(val)
							if isstring(val) then
								if val == "" then return end
								local x,y,z = unpack(string.Split(val, " "))
								val = Color(x,y,z)
							end
							start_value:SetValue(val)
						end
						function end_value.OnValueChanged(val)
							if isstring(val) then
								if val == "" then return end
								local x,y,z = unpack(string.Split(val, " "))
								val = Color(x,y,z)
							end
							end_value:SetValue(val) 
						end
					elseif property_type == "number" then
						function start_value.OnValueChanged(val)
							start_value:SetValue(tonumber(val) or val)
						end
						function end_value.OnValueChanged(val)
							end_value:SetValue(tonumber(val) or val)
						end
					end
				else
					start_value = pace.CreatePanel("properties_label", properties_pnl) properties_pnl:AddKeyValue("ERROR",start_value)
					end_value = pace.CreatePanel("properties_label", properties_pnl) properties_pnl:AddKeyValue("ERROR",end_value)
				end
			--end)
			if start_value.Restart then start_value:Restart() end if end_value.Restart then end_value:Restart() end
			if start_value.OnValueChanged then
				local def = start_value:GetValue()
				if pace.BulkSelectList[1] then def = pace.BulkSelectList[1][property] end
				start_value.OnValueChanged(def)
				start_value.OnValueChanged(start_value:GetValue())
			end
			if end_value.OnValueChanged then
				local def = end_value:GetValue()
				if pace.BulkSelectList[1] then def = pace.BulkSelectList[1][property] end
				end_value.OnValueChanged(def)
				end_value.OnValueChanged(end_value:GetValue())
			end
		end

		local function setsingle(part, property_name, property_type, frac)

			if property_type == "vector" then
				local start_val = Vector(start_value.left:GetValue(), start_value.middle:GetValue(), start_value.right:GetValue())
				local end_val = Vector(end_value.left:GetValue(), end_value.middle:GetValue(), end_value.right:GetValue())
				local delta = end_val - start_val
				part["Set"..property_name](part, start_val + frac*delta)
			elseif property_type == "angle" then
				local start_val = Angle(start_value.left:GetValue(), start_value.middle:GetValue(), start_value.right:GetValue())
				local end_val = Angle(end_value.left:GetValue(), end_value.middle:GetValue(), end_value.right:GetValue())
				local delta = end_val - start_val
				part["Set"..property_name](part, start_val + frac*delta)
			elseif property_type == "color" then
				local r1 = start_value.left:GetValue()
				local g1 = start_value.middle:GetValue()
				local b1 = start_value.right:GetValue()
				local r2 = start_value.left:GetValue()
				local g2 = start_value.middle:GetValue()
				local b2 = start_value.right:GetValue()

				part["Set"..property_name](part, Color(r1 + frac*(r2-r1), g1 + frac*(g2-g1), b1 + frac*(b2-b1)))
			elseif property_type == "number" then
				local start_val = start_value:GetValue()
				local end_val = end_value:GetValue()
				local delta = end_val - start_val
				part["Set"..property_name](part, start_val + frac*delta)
			end
		end
		local function setmultiple(property_name, property_type)
			if #pace.BulkSelectList <= 1 then return end
			for i,v in ipairs(pace.BulkSelectList) do
				local frac = (i-1) / (#pace.BulkSelectList-1)
				setsingle(v, property_name, property_type, frac)
			end
		end
		local function reset_initial_properties()
			--self.left = left
			--self.middle = middle
			--self.right = right
			if start_value.left then
				print(start_value.left:GetValue(), start_value.middle:GetValue(), start_value.right:GetValue())
				print(end_value.left:GetValue(), end_value.middle:GetValue(), end_value.right:GetValue())
			else
				print(start_value:GetValue())
				print(end_value:GetValue())
			end

			for part, tbl in pairs(parts_backup_properties_values) do
				for prop, value in pairs(tbl) do
					part["Set"..prop](part, value)
				end
			end
		end

		local properties_2 = pace.CreatePanel("properties", main_panel) properties_2:SetSize(380,85) properties_2:SetPos(10,30)
		local variable_name = ""
		local full_success = false
		local found_type = "number"
		local variable_name_pnl = pace.CreatePanel("properties_string", main_panel) properties_2:AddKeyValue("VariableName", variable_name_pnl)
			function variable_name_pnl:SetValue(var)
				local str = tostring(var)
				variable_name = str
				self:SetTextColor(self.alt_line and self:GetSkin().Colours.Category.AltLine.Text or self:GetSkin().Colours.Category.Line.Text)
				self:SetFont(pace.CurrentFont)
				self:SetText("  " .. str) -- ugh
				self:SizeToContents()

				if #str > 10 then
					self:SetTooltip(str)
				else
					self:SetTooltip()
				end
				self.original_str = str
				self.original_var = var
				if self.OnValueSet then
					self:OnValueSet(str)
				end

				full_success = true
				found_type = "number"
				for _,v in ipairs(pace.BulkSelectList) do
					if not v["Get"..str] or not v["Set"..str] then full_success = false
					else
						if full_success then found_type = string.lower(type(v["Get"..str](v))) end
					end
				end
				swap_properties(str, found_type, full_success)
				if full_success then setmultiple(str, found_type) end
			end
			function variable_name_pnl:EditText()
				local oldText = self:GetText()
				self:SetText("")

				local pnl = vgui.Create("DTextEntry")
				self.editing = pnl
				pnl:SetFont(pace.CurrentFont)
				pnl:SetDrawBackground(false)
				pnl:SetDrawBorder(false)
				pnl:SetText(self:EncodeEdit(self.original_str or ""))
				pnl:SetKeyboardInputEnabled(true)
				pnl:SetDrawLanguageID(false)
				pnl:RequestFocus()
				pnl:SelectAllOnFocus(true)

				pnl.OnTextChanged = function() oldText = pnl:GetText() end

				local hookID = tostring({})
				local textEntry = pnl
				local delay = os.clock() + 0.1

				pac.AddHook('Think', hookID, function(code)
					if not IsValid(self) or not IsValid(textEntry) then return pac.RemoveHook('Think', hookID) end
					if textEntry:IsHovered() or self:IsHovered() then return end
					if delay > os.clock() then return end
					if not input.IsMouseDown(MOUSE_LEFT) and not input.IsKeyDown(KEY_ESCAPE) then return end
					pac.RemoveHook('Think', hookID)
					self.editing = false
					pace.BusyWithProperties = NULL
					textEntry:Remove()
					self:SetText(oldText)
					pnl:OnEnter()
				end)

				--local x,y = pnl:GetPos()
				--pnl:SetPos(x+3,y-4)
				--pnl:Dock(FILL)
				local x, y = self:LocalToScreen()
				local inset_x = self:GetTextInset()
				pnl:SetPos(x+5 + inset_x, y)
				pnl:SetSize(self:GetSize())
				pnl:SetWide(ScrW())
				pnl:MakePopup()

				pnl.OnEnter = function()
					pace.BusyWithProperties = NULL
					self.editing = false

					pnl:Remove()
					self:SetText(pnl:GetText())
					self:SetValue(pnl:GetText())
				end

				local old = pnl.Paint
				pnl.Paint = function(...)
					if not self:IsValid() then pnl:Remove() return end

					surface.SetFont(pnl:GetFont())
					local w = surface.GetTextSize(pnl:GetText()) + 6

					surface.DrawRect(0, 0, w, pnl:GetTall())
					surface.SetDrawColor(self:GetSkin().Colours.Properties.Border)
					surface.DrawOutlinedRect(0, 0, w, pnl:GetTall())

					pnl:SetWide(w)

					old(...)
				end

				pace.BusyWithProperties = pnl
			end
			variable_name_pnl:SetValue(variable_name)
			local btn = vgui.Create("DButton", variable_name_pnl)
				btn:SetSize(16, 16)
				btn:Dock(RIGHT)
				btn:SetText("...")
				btn.DoClick = function()
					do
						local get_list = function()
							local enums = {}
							local excluded_properties = {["ParentUID"] = true,["UniqueID"] = true}
							for i,v in ipairs(pace.BulkSelectList) do
								for _,prop in pairs(v:GetProperties()) do
									if not excluded_properties[prop.key] and type(v["Get"..prop.key](v)) ~= "string" and type(v["Get"..prop.key](v)) ~= "boolean" then
										enums[prop.key] = prop.key
									end
								end
							end
							return enums
						end
						pace.SafeRemoveSpecialPanel()

						local frame = vgui.Create("DFrame")
						frame:SetTitle("Variable name")
						frame:SetSize(300, 300)
						frame:Center()
						frame:SetSizable(true)

						local list = vgui.Create("DListView", frame)
						list:Dock(FILL)
						list:SetMultiSelect(false)
						list:AddColumn("Variable name", 1)

						list.OnRowSelected = function(_, id, line)
							local val = line.list_key
							variable_name_pnl:SetValue(val)
							variable_name = val
						end

						local first = NULL

						local function build(find)
							list:Clear()

							for key, val in pairs(get_list()) do
								local pnl = list:AddLine(key) pnl.list_key = key
							end
						end

						local search = vgui.Create("DTextEntry", frame)
						search:Dock(BOTTOM)
						search.OnTextChanged = function() build(search:GetValue()) end
						search.OnEnter = function() if first:IsValid() then list:SelectItem(first) end frame:Remove() end
						search:RequestFocus()
						frame:MakePopup()

						build()

						pace.ActiveSpecialPanel = frame
					end
				end

		--

		local reset_button = vgui.Create("DButton", main_panel)
		reset_button:SetText("reset") reset_button:SetSize(190,30)
		properties_2:AddKeyValue("revert", reset_button)
		function reset_button:DoClick() reset_initial_properties() end

		local apply_button = vgui.Create("DButton", main_panel)
		apply_button:SetText("confirm") apply_button:SetSize(190,30)
		properties_2:AddKeyValue("apply", apply_button)
		function apply_button:DoClick() if full_success then setmultiple(variable_name, found_type) end end
		main_panel:Center()
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
		local contained_bulk_select = false
		for _,option_name in ipairs(pace.operations_order) do
			if option_name == "bulk_select" then
				contained_bulk_select = true
			end
			pace.addPartMenuComponent(menu, obj, option_name)
		end

		if #pace.BulkSelectList >= 1 and not contained_bulk_select then
			menu:AddSpacer()
			pace.addPartMenuComponent(menu, obj, "bulk_select")
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

local part_classes_with_quicksetups = {
	text = true,
	particles = true,
	proxy = true,
	sprite = true,
	projectile = true,
	entity2 = true,
	model2 = true,
	group = true,
	camera = true,
	faceposer = true,
	command = true,
	bone3 = true,
	health_modifier = true,
	hitscan = true,
	jiggle = true,
	interpolated_multibone = true,
}
local function AddOptionRightClickable(title, func, parent_menu)
	local pnl = parent_menu:AddOption(title, func)
	function pnl:Think()
		if input.IsMouseDown(MOUSE_RIGHT) and self:IsHovered() then
			if not self.clicked then func() end
			self.clicked = true
		else
			self.clicked = false
		end
	end
	--to communicate to the user that they can right click to activate without closing the parent menu
	--tooltip may be set later, so we'll sandwich it with a timer
	timer.Simple(0.5, function()
		if not IsValid(pnl) then return end
		if pnl:GetTooltip() == nil then
			pnl:SetTooltip("You can right click this to use the option without exiting the menu")
		end
	end)
	return pnl
end
--those are more to configure a part into common setups, might involve creating other parts
function pace.AddQuickSetupsToPartMenu(menu, obj)
	if not part_classes_with_quicksetups[obj.ClassName] and not obj.GetDrawPosition then
		return
	end

	local main, pnlmain = menu:AddSubMenu("quick setups") pnlmain:SetIcon("icon16/basket_go.png")
	--base_movables can restructure, but nah bones aint it
	if obj.GetDrawPosition and obj.ClassName ~= "bone" and obj.ClassName ~= "bone2" and obj.ClassName ~= "bone3" then
		if obj.Bone and obj.Bone == "camera" then
			main:AddOption("camera bone suggestion: limit view to yourself", function()
				local event = pac.CreatePart("event") event:SetEvent("viewed_by_owner") event:SetParent(obj)
			end):SetImage("icon16/star.png")
			if obj.GetAlpha then main:AddOption("camera bone suggestion: fade with distance", function()
				local model = pac.CreatePart("model2") model:SetModel("models/empty.mdl") model:SetParent(obj.Parent) model:SetName("head_position")
				local proxy = pac.CreatePart("proxy") proxy:SetExpression("clamp(2 - (part_distance(\"head_position\")/100),0,1)") proxy:SetParent(obj) proxy:SetVariableName("Alpha")
			end):SetImage("icon16/star.png") end
		end
		local substitutes, pnl = main:AddSubMenu("Restructure / Create parent substitute", function()
			pace.SubstituteBaseMovable(obj, "create_parent")
			timer.Simple(20, function() if pace.recently_substituted_movable_part == obj then pace.recently_substituted_movable_part = nil end end)
		end) pnl:SetImage("icon16/application_double.png")
			substitutes:AddOption("empty model", function()
				--pulled from pace.SubstituteBaseMovable(obj, "create_parent")
				local newObj = pac.CreatePart("model2")
				if not IsValid(newObj) then return end

				newObj:SetParent(obj.Parent)
				obj:SetParent(newObj)

				newObj:SetPosition(obj.Position)
				newObj:SetPositionOffset(obj.PositionOffset)
				newObj:SetAngles(obj.Angles)
				newObj:SetAngleOffset(obj.AngleOffset)
				newObj:SetEyeAngles(obj.EyeAngles)
				newObj:SetAimPart(obj.AimPart)
				newObj:SetAimPartName(obj.AimPartName)
				newObj:SetBone(obj.Bone)
				newObj:SetEditorExpand(true)
				newObj:SetSize(0)
				newObj:SetModel("models/empty.mdl")

				obj:SetPosition(Vector(0,0,0))
				obj:SetPositionOffset(Vector(0,0,0))
				obj:SetAngles(Angle(0,0,0))
				obj:SetAngleOffset(Angle(0,0,0))
				obj:SetEyeAngles(false)
				obj:SetAimPart(nil)
				obj:SetAimPartName("")
				obj:SetBone("head")

				pace.RefreshTree()
			end):SetIcon("icon16/anchor.png")
			substitutes:AddOption("jiggle", function()
				pace.SubstituteBaseMovable(obj, "create_parent", "jiggle")
			end):SetIcon("icon16/chart_line.png")
			substitutes:AddOption("interpolator", function()
				pace.SubstituteBaseMovable(obj, "create_parent", "interpolated_multibone")
			end):SetIcon("icon16/table_multiple.png")
	end

	local function install_submaterial_options(menu)
		local mats = obj:GetOwner():GetMaterials()
		local mats_str = table.concat(mats,"\n")
		local dyn_props = obj:GetDynamicProperties()
		local submat_togglers, pnl = main:AddSubMenu("create submaterial zone togglers (hide/show materials)", function()
			Derma_StringRequest("submaterial togglers", "please input a submaterial name or a list of submaterial names with spaces\navailable materials:\n"..mats_str, "", function(str)
				local event = pac.CreatePart("event") event:SetAffectChildrenOnly(true) event:SetEvent("command") event:SetArguments("materials_"..string.sub(obj.UniqueID,1,6))
				local proxy = pac.CreatePart("proxy") proxy:SetAffectChildren(true) proxy:SetVariableName("no_draw") proxy:SetExpression("0") proxy:SetExpressionOnHide("1")
				event:SetParent(obj) proxy:SetParent(event)
				for i, kw in ipairs(string.Split(str, " ")) do
					for id,mat2 in ipairs(mats) do
						if string.GetFileFromFilename(mat2) == kw then
							local mat = pac.CreatePart("material_3d") mat:SetParent(proxy)
							mat:SetName("toggled_"..kw.."_"..string.sub(obj.UniqueID,1,6))
							mat:SetLoadVmt(mat2)
							dyn_props[kw].set("toggled_"..kw.."_"..string.sub(obj.UniqueID,1,6))
						end
					end
				end
			end)
		end) pnl:SetImage("icon16/picture_delete.png") pnl:SetTooltip("The sub-options are right clickable")

		local submat_toggler_proxy
		local submat_toggler_event
		local submaterials = {}
		for i,mat2 in ipairs(mats) do
			table.insert(submaterials,"")
			local kw = string.GetFileFromFilename(mat2)
			AddOptionRightClickable(kw, function()
				if not submat_toggler_proxy then
					local event = pac.CreatePart("event") event:SetAffectChildrenOnly(true) event:SetEvent("command") event:SetArguments("materials_"..string.sub(obj.UniqueID,1,6))
					local proxy = pac.CreatePart("proxy") proxy:SetAffectChildren(true) proxy:SetVariableName("no_draw") proxy:SetExpression("0") proxy:SetExpressionOnHide("1")
					event:SetParent(obj) proxy:SetParent(event)
					submat_toggler_proxy = proxy
				end
				local mat = pac.CreatePart("material_3d") mat:SetParent(submat_toggler_proxy)
				mat:SetName("toggled_"..kw.."_"..string.sub(obj.UniqueID,1,6))
				mat:SetLoadVmt(mat2)

				submaterials[i] = "toggled_"..kw.."_"..string.sub(obj.UniqueID,1,6)
				if #submaterials == 1 then
					obj:SetMaterials("") obj:SetMaterial(submaterials[1])
				else
					obj:SetMaterials(table.concat(submaterials, ";"))
				end
				
			end, submat_togglers):SetIcon("icon16/paintcan.png")
		end

		local edit_materials, pnl = main:AddSubMenu("edit all materials", function()
			local materials = ""
			obj:SetMaterial("")
			for i,mat2 in ipairs(mats) do
				local kw = string.GetFileFromFilename(mat2)
				local mat = pac.CreatePart("material_3d") mat:SetParent(obj)
				mat:SetName(kw.."_"..string.sub(obj.UniqueID,1,6))
				mat:SetLoadVmt(mat2)
				submaterials[i] = kw.."_"..string.sub(obj.UniqueID,1,6)
				
			end
			if #submaterials == 1 then
				obj:SetMaterials("") obj:SetMaterial(submaterials[1])
			else
				obj:SetMaterials(table.concat(submaterials, ";"))
			end
		end) pnl:SetImage("icon16/paintcan.png")

		for i,mat2 in ipairs(mats) do
			local kw = string.GetFileFromFilename(mat2)
			AddOptionRightClickable(kw, function()
				obj:SetMaterial("")

				local mat = pac.CreatePart("material_3d") mat:SetParent(obj)
				mat:SetName(kw.."_"..string.sub(obj.UniqueID,1,6))
				mat:SetLoadVmt(mat2)

				submaterials[i] = kw.."_"..string.sub(obj.UniqueID,1,6)
				if #submaterials == 1 then
					obj:SetMaterials("") obj:SetMaterial(submaterials[1])
				else
					obj:SetMaterials(table.concat(submaterials, ";"))
				end
			end, edit_materials):SetIcon("icon16/paintcan.png")
		end
	end
	if obj.ClassName == "particles" then
		main:AddOption("bare 3D setup", function()
			obj:Set3D(true) obj:SetZeroAngle(false) obj:SetVelocity(0) obj:SetParticleAngleVelocity(Vector(0,0,0)) obj:SetGravity(Vector(0,0,0))
		end):SetIcon("icon16/star.png")
		main:AddOption("simple 3D setup : Blast", function()
			obj:Set3D(true) obj:SetZeroAngle(false) obj:SetLighting(false) obj:SetAngleOffset(Angle(90,0,0)) obj:SetStartSize(0) obj:SetEndSize(500) obj:SetFireOnce(true) obj:SetMaterial("particle/Particle_Ring_Wave_Additive") obj:SetVelocity(0) obj:SetParticleAngleVelocity(Vector(0,0,0)) obj:SetGravity(Vector(0,0,0)) obj:SetDieTime(1.5)
		end):SetIcon("icon16/transmit.png")
		main:AddOption("simple 3D setup : Slash", function()
			obj:Set3D(true) obj:SetZeroAngle(false) obj:SetLighting(false) obj:SetAngleOffset(Angle(90,0,0)) obj:SetStartSize(100) obj:SetEndSize(90) obj:SetFireOnce(true) obj:SetMaterial("particle/Particle_Crescent") obj:SetVelocity(0) obj:SetParticleAngleVelocity(Vector(0,0,1500)) obj:SetGravity(Vector(0,0,0)) obj:SetDieTime(0.4)
		end):SetIcon("icon16/arrow_refresh.png")
		main:AddOption("simple setup : Piercer", function()
			obj:Set3D(false) obj:SetZeroAngle(false) obj:SetLighting(false) obj:SetStartSize(30) obj:SetEndSize(10) obj:SetEndLength(100) obj:SetEndLength(1000) obj:SetFireOnce(true) obj:SetVelocity(50) obj:SetDieTime(0.2)
		end):SetIcon("icon16/asterisk_orange.png")
		main:AddOption("simple setup : Twinkle cloud", function()
			obj:Set3D(false) obj:SetZeroAngle(false) obj:SetLighting(false) obj:SetStartSize(10) obj:SetEndSize(0) obj:SetEndLength(0) obj:SetEndLength(0) obj:SetFireOnce(false) obj:SetVelocity(0) obj:SetDieTime(0.5) obj:SetNumberParticles(2) obj:SetFireDelay(0.03) obj:SetPositionSpread(50) obj:SetGravity(Vector(0,0,0))  obj:SetMaterial("sprites/light_ignorez")
		end):SetIcon("icon16/weather_snow.png")
		main:AddOption("simple setup : Dust cloud", function()
			obj:Set3D(false) obj:SetZeroAngle(false) obj:SetLighting(false) obj:SetStartSize(60) obj:SetEndSize(100) obj:SetEndLength(0) obj:SetEndLength(0) obj:SetStartAlpha(100) obj:SetFireOnce(false) obj:SetVelocity(0) obj:SetDieTime(2) obj:SetNumberParticles(2) obj:SetFireDelay(0.03) obj:SetPositionSpread(100) obj:SetGravity(Vector(0,0,-20))
		end):SetIcon("icon16/weather_clouds.png")
		main:AddOption("simple setup : Dust kickup", function()
			obj:Set3D(false) obj:SetZeroAngle(false) obj:SetLighting(false) obj:SetStartSize(10) obj:SetEndSize(15) obj:SetEndLength(0) obj:SetEndLength(0) obj:SetStartAlpha(100) obj:SetFireOnce(true) obj:SetSpread(0.8) obj:SetVelocity(100) obj:SetDieTime(2) obj:SetNumberParticles(10) obj:SetPositionSpread(1) obj:SetAirResistance(80) obj:SetGravity(Vector(0,0,-100))
		end):SetIcon("icon16/weather_clouds.png")
	elseif obj.ClassName == "sprite" then
		main:AddOption("simple shockwave (will use " .. (obj.Size == 1 and "size 200" or "existing size " .. obj.Size) ..")", function()
			local proxyAlpha = pac.CreatePart("proxy")
				proxyAlpha:SetParent(obj)
				proxyAlpha:SetVariableName("Alpha")
				proxyAlpha:SetExpression("clamp(1 - timeex()^0.5,0,1)")
			local proxySize = pac.CreatePart("proxy")
				proxySize:SetParent(obj)
				proxySize:SetVariableName("Size")
				proxySize:SetExpression((obj.Size == 1 and 200 or obj.Size) .. " * clamp(timeex()^0.5,0,1)")
				obj:SetNotes("showhidetest")

			pace.FlashNotification("Hide and unhide the sprite to review its effects. An additional menu option will be provided for this.")
		end):SetIcon("icon16/transmit.png")
		main:AddOption("cross flare", function()
			obj:SetSizeY(0.1)
			local proxy1 = pac.CreatePart("proxy")
				proxy1:SetParent(obj)
				proxy1:SetVariableName("SizeY")
				proxy1:SetExpression("0.15*clamp(1 - timeex()^0.5,0,1)")
			local proxy1_size = pac.CreatePart("proxy")
				proxy1_size:SetParent(obj)
				proxy1_size:SetVariableName("Size")
				proxy1_size:SetExpression("100 + 100*clamp(timeex()^0.5,0,1)")

			local sprite2 = pac.CreatePart("sprite")
				sprite2:SetSpritePath(obj:GetSpritePath())
				sprite2:SetParent(obj)
				sprite2:SetSizeX(0.1)
			local proxy2 = pac.CreatePart("proxy")
				proxy2:SetParent(sprite2)
				proxy2:SetVariableName("SizeX")
				proxy2:SetExpression("0.15*clamp(1 - timeex()^0.5,0,1)")
			local proxy2_size = pac.CreatePart("proxy")
				proxy2_size:SetParent(sprite2)
				proxy2_size:SetVariableName("Size")
				proxy2_size:SetExpression("100 + 100*clamp(timeex()^0.5,0,1)")
			obj:SetNotes("showhidetest")
		end):SetIcon("icon16/asterisk_yellow.png")
	elseif obj.ClassName == "proxy" then
		pnlmain:SetTooltip("remember you also have a preset library by right clicking on the expression field")
		main:AddOption("basic feedback controller setup", function()
			Derma_StringRequest("What should we call this controller variable?", "Type a name for the commands.\nThese number ranges would be appropriate for positions\nIf you make more, name them something different", "speed", function(str)
				if str == "" then return end if str == " " then return end
				local cmdforward = pac.CreatePart("command") cmdforward:SetParent(obj)
				cmdforward:SetString("pac_proxy " .. str .. " 100")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("up") btn:SetParent(cmdforward)

				local cmdback = pac.CreatePart("command") cmdback:SetParent(obj)
				cmdback:SetString("pac_proxy " .. str .. " -100")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("down") btn:SetParent(cmdback)

				local cmdneutral = pac.CreatePart("command") cmdneutral:SetParent(obj)
				cmdneutral:SetString("pac_proxy " .. str .. " 0")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("up") btn:SetParent(cmdneutral) btn:SetInvert(false)
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("down") btn:SetParent(cmdneutral) btn:SetInvert(false)

				obj:SetExpression("feedback() + ftime()*command(\"".. str .. "\")")
			end)
		end):SetIcon("icon16/joystick.png")
		main:AddOption("2D feedback controller setup", function()
			Derma_StringRequest("What should we call this controller variable?", "Type a name for the commands.\nThese number ranges would be appropriate for positions\nIf you make more, name them something different", "speed", function(str)
				if str == "" then return end if str == " " then return end
				local cmdforward = pac.CreatePart("command") cmdforward:SetParent(obj)
				cmdforward:SetString("pac_proxy " .. str .. "_x" .. " 100")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("up") btn:SetParent(cmdforward)

				local cmdback = pac.CreatePart("command") cmdback:SetParent(obj)
				cmdback:SetString("pac_proxy " .. str .. "_x" .. " -100")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("down") btn:SetParent(cmdback)

				local cmdneutral = pac.CreatePart("command") cmdneutral:SetParent(obj)
				cmdneutral:SetString("pac_proxy " .. str .. "_x" .. " 0")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("up") btn:SetParent(cmdneutral) btn:SetInvert(false)
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("down") btn:SetParent(cmdneutral) btn:SetInvert(false)


				local cmdright = pac.CreatePart("command") cmdright:SetParent(obj)
				cmdright:SetString("pac_proxy " .. str .. "_y" .. " 100")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("right") btn:SetParent(cmdright)

				local cmdleft = pac.CreatePart("command") cmdleft:SetParent(obj)
				cmdleft:SetString("pac_proxy " .. str .. "_y" .. " -100")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("left") btn:SetParent(cmdleft)

				local cmdneutral = pac.CreatePart("command") cmdneutral:SetParent(obj)
				cmdneutral:SetString("pac_proxy " .. str .. "_y" .. " 0")
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("left") btn:SetParent(cmdneutral) btn:SetInvert(false)
				local btn = pac.CreatePart("event") btn:SetEvent("button") btn:SetArguments("right") btn:SetParent(cmdneutral) btn:SetInvert(false)
				obj:SetExpression(
					"feedback_x() + ftime()*command(\"".. str .. "_x\")"
					.. "," ..
					"feedback_y() + ftime()*command(\"".. str .. "_y\")"
				)
			end)
		end):SetIcon("icon16/joystick.png")
		main:AddOption("command feedback attractor setup (-100, -50, 0, 50, 100)", function()
			Derma_StringRequest("What should we call this attractor?", "Type a name for the commands.\nThese number ranges would be appropriate for positions\nIf you make more, name them something different", "target_number", function(str)
				if str == "" then return end if str == " " then return end
				local demonstration_values = {-100, -50, 0, 50, 100}
				for i,value in ipairs(demonstration_values) do
					local test_cmd_part = pac.CreatePart("command") test_cmd_part:SetParent(obj)
					test_cmd_part:SetString("pac_proxy " .. str .. " " .. value)
				end
				obj:SetExpression("feedback() + 3*ftime()*(command(\"".. str .. "\") - feedback())")
			end)
		end):SetIcon("icon16/calculator.png")
		main:AddOption("variable attractor multiplier base +1/0/-1", function()
			Derma_StringRequest("What should we call this attractor?", "Type a name for the commands.\nIf you make more, name them something different", "target_number", function(str)
				if str == "" then return end if str == " " then return end
				local demonstration_values = {-1, 0, 1}
				for i,value in ipairs(demonstration_values) do
					local test_cmd_part = pac.CreatePart("command") test_cmd_part:SetParent(obj)
					test_cmd_part:SetString("pac_proxy " .. str .. " " .. value)
				end
				local outsourced_proxy = pac.CreatePart("proxy")
				outsourced_proxy:SetParent(obj) outsourced_proxy:SetName(str)
				outsourced_proxy:SetExpression("feedback() + 3*ftime()*(command(\"".. str .. "\") - feedback())")
				outsourced_proxy:SetExtra1("feedback() + 3*ftime()*(command(\"".. str .. "\") - feedback())")
				if obj.Expression == "" then
					obj:SetExpression("var1(\"".. str .. "\")")
				else
					obj:SetExpression(obj.Expression .. " * var1(\"".. str .. "\")")
				end
			end)
		end):SetIcon("icon16/calculator.png")
		main:AddOption("smoothen (wrap into dynamic feedback attractor)", function()
			obj:SetExpression("feedback() + 4*ftime()*((" .. obj.Expression .. ") - feedback())")
		end):SetIcon("icon16/calculator.png")
		main:AddOption("smoothen (make extra variable attractor)", function()
			Derma_StringRequest("What should we call this attractor variable?", "Type a name for the attractor. It will be used somewhere else like var1(\"eased_function\") for example\nsuggestions from the active functions:\n"..table.concat(obj:GetActiveFunctions(),"\n"), "eased_function", function(str)
				local new_proxy = pac.CreatePart("proxy") new_proxy:SetParent(obj.Parent)
				new_proxy:SetExpression("feedback() + 4*ftime()*((" .. obj.Expression .. ") - feedback())")
				new_proxy:SetName(str)
				new_proxy:SetExtra1(new_proxy.Expression)
			end)
		end):SetIcon("icon16/calculator.png")
	elseif obj.ClassName == "text" then
		main:AddOption("fast proxy link", function()
			obj:SetTextOverride("Proxy")
			obj:SetConcatenateTextAndOverrideValue(true)
			--add proxy
			local proxy = pac.CreatePart("proxy")
			proxy:SetParent(obj)
			proxy:SetVariableName("DynamicTextValue")
			pace.Call("PartSelected", proxy)
		end):SetIcon("icon16/calculator_link.png")
		main:AddOption("quick large 2D text", function()
			obj:SetDrawMode("SurfaceText")
			obj:SetFont("DermaLarge")
		end):SetIcon("icon16/text_letter_omega.png")
		main:AddOption("make HUD", function()
			obj:SetBone("player_eyes")
			obj:SetPosition(Vector(10,0,0))
			obj:SetDrawMode("SurfaceText")
			local newevent = pac.CreatePart("event")
			newevent:SetParent(obj)
			newevent:SetEvent("viewed_by_owner")
		end):SetIcon("icon16/monitor.png")
	elseif obj.ClassName == "projectile" then
		if obj.OutfitPartUID ~= "" then
			local modelpart = obj.OutfitPart
			if not modelpart.ClassName == "model2" then
				modelpart = modelpart:GetChildren()[1]
				if not modelpart.ClassName == "model2" then
					return
				end
			end
			if not modelpart.Model then return end
			if obj.FallbackSurfpropModel ~= modelpart.Model then
				main:AddOption("Reshape outfit part into a throwable prop: " .. obj.FallbackSurfpropModel, function()
					obj:SetOverridePhysMesh(true)
					obj:SetPhysical(true)
					obj:SetRescalePhysMesh(true)
					obj:SetRadius(modelpart.Size)
					obj:SetFallbackSurfpropModel(modelpart.Model)
					modelpart:SetHide(true)
				end):SetIcon("materials/spawnicons/"..string.gsub(obj.FallbackSurfpropModel, ".mdl", "")..".png")
				main:AddOption("Shape projectile into a throwable prop: " .. modelpart.Model, function()
					obj:SetOverridePhysMesh(true)
					obj:SetPhysical(true)
					obj:SetRescalePhysMesh(true)
					obj:SetFallbackSurfpropModel(modelpart.Model)
					modelpart:SetHide(true)
					modelpart:SetSize(obj.Radius)
					modelpart:SetModel(obj.FallbackSurfpropModel)
				end):SetIcon("materials/spawnicons/"..string.gsub(modelpart.Model, ".mdl", "")..".png")
			end

		else
			if obj.FallbackSurfpropModel then
				main:AddOption("make throwable prop (" .. obj.FallbackSurfpropModel .. ")", function()
					local modelpart = pac.CreatePart("model2")
					modelpart:SetParent(obj)
					obj:SetOverridePhysMesh(true)
					obj:SetPhysical(true)
					obj:SetRescalePhysMesh(true)
					obj:SetOutfitPart(modelpart)
					modelpart:SetHide(true)
					modelpart:SetSize(obj.Radius)
					modelpart:SetModel(obj.FallbackSurfpropModel)
				end):SetIcon("materials/spawnicons/"..string.gsub(obj.FallbackSurfpropModel, ".mdl", "")..".png")
			end
			main:AddOption("make throwable prop (opens asset browser)", function()
				local modelpart = pac.CreatePart("model2")
				modelpart:SetParent(obj)
				obj:SetRadius(1)
				obj:SetOverridePhysMesh(true)
				obj:SetPhysical(true)
				obj:SetRescalePhysMesh(true)
				obj:SetOutfitPart(modelpart)
				modelpart:SetHide(true)
				pace.AssetBrowser(function(path)
					modelpart:SetModel(path)
					obj:SetFallbackSurfpropModel(path)
				end, "models")
			end):SetIcon("icon16/link.png")
		end
		main:AddOption("make shield", function()
			local model = pac.CreatePart("model2") model:SetModel("models/props_lab/blastdoor001c.mdl")
			model:SetParent(obj)
			obj:SetPosition(Vector(60,0,0))
			obj:SetRadius(1)
			obj:SetSpeed(0)
			obj:SetMass(10000)
			obj:SetBone("invalidbone")
			obj:SetOverridePhysMesh(true)
			obj:SetPhysical(true)
			obj:SetOutfitPart(model)
			obj:SetCollideWithOwner(true)
			obj:SetCollideWithSelf(true)
			obj:SetFallbackSurfpropModel("models/props_lab/blastdoor001c.mdl")
			model:SetHide(true)
			pace.PopulateProperties(obj)
		end):SetIcon("icon16/shield.png")

	elseif obj.ClassName == "entity2" then
		if obj:GetOwner().GetBodyGroups then
			local bodygroups = obj:GetOwner():GetBodyGroups()
			if #bodygroups > 0 then
				local submenu, pnl = main:AddSubMenu("toggleable bodygroup with a dual proxy") pnl:SetImage("icon16/table_refresh.png")
				pnl:SetTooltip("It will apply 1 and 0. But if there are more variations in that bodygroup, change the expression and the expression on hide if you wish")
				for i,bodygroup in ipairs(bodygroups) do
					if bodygroup.num == 1 then continue end
					local pnl = submenu:AddOption(bodygroup.name, function()
						local proxy = pac.CreatePart("proxy") proxy:SetParent(obj)
						proxy:SetExpression("1") proxy:SetExpressionOnHide("0")
						proxy:SetVariableName(bodygroup.name)
						local event = pac.CreatePart("event") event:SetParent(proxy) event:SetEvent("command") event:SetArguments(string.Replace(bodygroup.name, " "))
					end)
					pnl:SetTooltip(table.ToString(bodygroup.submodels, nil, true))
				end
			end
		end
		install_submaterial_options(main)

	elseif obj.ClassName == "model2" then
		local pm = pace.current_part:GetPlayerOwner():GetModel()
		local pm_selected = player_manager.TranslatePlayerModel(GetConVar("cl_playermodel"):GetString())

		if pm_selected ~= pm then
			main:AddOption("Selected playermodel - " .. string.gsub(string.GetFileFromFilename(pm_selected), ".mdl", ""), function()
				obj:SetModel(pm_selected)
				obj.pace_properties["Model"]:SetValue(pm_selected)
				pace.PopulateProperties(obj)

			end):SetImage("materials/spawnicons/"..string.gsub(pm_selected, ".mdl", "")..".png")
		end
		main:AddOption("Active playermodel - " .. string.gsub(string.GetFileFromFilename(pm), ".mdl", ""), function()
			pace.current_part:SetModel(pm)
			pace.current_part.pace_properties["Model"]:SetValue(pm)
			pace.PopulateProperties(obj)

		end):SetImage("materials/spawnicons/"..string.gsub(pm, ".mdl", "")..".png")
		if IsValid(pac.LocalPlayer:GetActiveWeapon()) then
			local wep = pac.LocalPlayer:GetActiveWeapon()
			local wep_mdl = wep:GetModel()
			if wep:GetClass() ~= "none" then --the uh hands have no model
				main:AddOption("Active weapon - " .. wep:GetClass() .. " - model - " .. string.gsub(string.GetFileFromFilename(wep_mdl), ".mdl", ""), function()
					obj:SetModel(wep_mdl)
					obj.pace_properties["Model"]:SetValue(wep_mdl)
					pace.PopulateProperties(obj)
				end):SetImage("materials/spawnicons/"..string.gsub(wep_mdl, ".mdl", "")..".png")
			end
		end
		if obj.Owner.GetBodyGroups then
			local bodygroups = obj.Owner:GetBodyGroups()
			if (#bodygroups > 1) or (#bodygroups[1].submodels > 1) then
				local submenu, pnl = main:AddSubMenu("toggleable bodygroup with a dual proxy") pnl:SetImage("icon16/table_refresh.png")
				pnl:SetTooltip("It will apply 1 and 0. But if there are more variations in that bodygroup, change the expression and the expression on hide if you wish")
				for i,bodygroup in ipairs(bodygroups) do
					if bodygroup.num == 1 then continue end
					local pnl = submenu:AddOption(bodygroup.name, function()
						local proxy = pac.CreatePart("proxy") proxy:SetParent(obj)
						proxy:SetExpression("1") proxy:SetExpressionOnHide("0")
						proxy:SetVariableName(bodygroup.name)
						local event = pac.CreatePart("event") event:SetParent(proxy) event:SetEvent("command") event:SetArguments(string.Replace(bodygroup.name, " "))
					end)
					pnl:SetTooltip(table.ToString(bodygroup.submodels, nil, true))
				end
			end
		end

		install_submaterial_options(main)

		local collapses, pnl = main:AddSubMenu("bone collapsers") pnl:SetImage("icon16/compress.png")
			collapses:AddOption("collapse arms", function()
				local group = pac.CreatePart("group") group:SetParent(obj)
				local right = pac.CreatePart("bone3") right:SetParent(group) right:SetSize(0) right:SetScaleChildren(true) right:SetBone("right clavicle")
				local left = pac.CreatePart("bone3") left:SetParent(group) left:SetSize(0) left:SetScaleChildren(true) left:SetBone("left clavicle")
			end):SetIcon("icon16/user.png")
			collapses:AddOption("collapse legs", function()
				local group = pac.CreatePart("group") group:SetParent(obj)
				local right = pac.CreatePart("bone3") right:SetBone("left thigh")
				right:SetParent(group) right:SetSize(0) right:SetScaleChildren(true) right:SetBone("right thigh")
				local left = pac.CreatePart("bone3") left:SetParent(group) left:SetSize(0) left:SetScaleChildren(true) left:SetBone("left thigh")
			end):SetIcon("icon16/user.png")
			collapses:AddOption("collapse by keyword", function()
				Derma_StringRequest("collapse bones", "please input a keyword to match", "head", function(str)
					local group = pac.CreatePart("group") group:SetParent(obj)
					local ent = obj:GetOwner()
					for bone,tbl in pairs(pac.GetAllBones(ent)) do
						if string.find(bone, str) ~= nil then
							local newbone = pac.CreatePart("bone3") newbone:SetParent(group) newbone:SetSize(0) newbone:SetScaleChildren(true) newbone:SetBone(bone)
						end
					end
				end)
			end):SetIcon("icon16/text_align_center.png")

		main:AddOption("clone model inside itself", function()
			local copiable_properties = {
				"Model", "Size", "Scale", "Alpha", "Material", "Materials", "NoLighting", "NoCulling", "Invert", "Skin", "IgnoreZ", "Translucent", "Brightness", "BlendMode"
			}
			local clone = obj:CreatePart("model2")
			for i,v in ipairs(copiable_properties) do
				clone:SetProperty(v, obj:GetProperty(v))
			end
		end):SetIcon("icon16/shape_group.png")
	elseif obj.ClassName == "group" then
		main:AddOption("Assign to viewmodel", function()
			obj:SetParent()
			obj:SetOwnerName("viewmodel")
			pace.RefreshTree(true)
		end):SetIcon("icon16/user.png")
		main:AddOption("Assign to hands", function()
			obj:SetParent()
			obj:SetOwnerName("hands")
			pace.RefreshTree(true)
		end):SetIcon("icon16/user.png")
		main:AddOption("Assign to active vehicle", function()
			obj:SetParent()
			obj:SetOwnerName("active vehicle")
			pace.RefreshTree(true)
		end):SetIcon("icon16/user.png")
		main:AddOption("Assign to active weapon", function()
			obj:SetParent()
			obj:SetOwnerName("active weapon")
			pace.RefreshTree(true)
		end):SetIcon("icon16/user.png")
		main:AddOption("gather arm parts into hands", function()
			if #obj:GetChildrenList() == 0 then return end
			local gatherable_classes = {
				model2 = true,
				model = true,
			}
			local groupable_classes = {
				group = true,
				event = true,
			}
			local newgroup = pac.CreatePart("group")
			local function ProcessDrawablePartsRecursively(part, root)
				if gatherable_classes[part.ClassName] then
					if not (string.find(part.Bone, "hand") ~= nil or string.find(part.Bone, "upperarm") ~= nil or string.find(part.Bone, "forearm") ~= nil
							or string.find(part.Bone, "wrist") ~= nil or string.find(part.Bone, "ulna") ~= nil or string.find(part.Bone, "bicep") ~= nil
							or string.find(part.Bone, "finger") ~= nil)
					then
						part:Remove()
					end
				elseif groupable_classes[part.ClassName] then
					for i, child in ipairs(part:GetChildrenList()) do
						ProcessDrawablePartsRecursively(child, root)
					end
				else
					part:Remove()
				end
			end
			pace.Copy(obj)
			pace.Paste(newgroup)
			ProcessDrawablePartsRecursively(newgroup, newgroup)

			newgroup:SetOwnerName("hands")
			newgroup:SetName("[HANDS]")
			pace.RefreshTree(true)
		end):SetIcon("icon16/user.png")
	elseif obj.ClassName == "camera" then
		menu:AddOption("clone position as a node for interpolators", function()
			local newpart = pac.CreatePart("model2")
			newpart:SetParent(obj:GetParent())
			newpart:SetModel("models/editor/camera.mdl") newpart:SetMaterial("models/wireframe")
			newpart:SetPosition(obj:GetPosition())
			newpart:SetPositionOffset(obj:GetPositionOffset())
			newpart:SetAngles(obj:GetAngles())
			newpart:SetAngleOffset(obj:GetAngleOffset())
			newpart:SetBone(obj:GetBone())
			newpart:SetNotes("editor FOV: " .. math.Round(pace.ViewFOV,1) ..
				"\ncamera FOV: " .. math.Round(obj:GetFOV(),1) ..
				(obj.Name ~= "" and ("\ncamera name: " .. obj:GetName()) or "") ..
				"\ncamera UID: " .. obj.UniqueID
			)
			Derma_StringRequest("Set a name", "give a name to the camera position node", "camera_node", function(str)
				newpart:SetName(str)
				if newpart.pace_tree_node then
					newpart.pace_tree_node:SetText(str)
				end
			end)
		end):SetImage("icon16/find.png")

		local bone_parent = obj:GetParent()
		if obj:GetOwner() ~= obj:GetRootPart():GetOwner() then
			while not (bone_parent.Bone and bone_parent.GetWorldPosition) do
				bone_parent = bone_parent:GetParent()
				if bone_parent:GetOwner() == obj:GetRootPart():GetOwner() then
					bone_parent = obj:GetRootPart():GetOwner()
				end
			end
		else
			bone_parent = obj:GetRootPart():GetOwner()
		end
		local function bone_reposition(bone)
			local bone_pos, bone_ang = pac.GetBonePosAng(obj:GetOwner(), bone)
			local pos, ang = WorldToLocal(pace.ViewPos, pace.view_roll and pace.ViewAngles_postRoll or pace.ViewAngles, bone_pos, bone_ang)
			obj:SetPosition(pos) obj:SetAngles(ang) obj:SetEyeAnglesLerp(0) obj:SetBone(bone)
			pace.PopulateProperties(obj)
		end
		local translate_from_view, pnl = main:AddSubMenu("Apply editor view", function()
			bone_reposition(obj.Bone)
		end) pnl:SetImage("icon16/arrow_redo.png")

		AddOptionRightClickable("apply FOV: " .. math.Round(pace.ViewFOV,1), function()
			obj:SetFOV(math.Round(pace.ViewFOV,1))
			pace.PopulateProperties(obj)
		end, translate_from_view):SetImage("icon16/zoom.png")
		
		AddOptionRightClickable("reset FOV" , function()
			obj:SetFOV(-1)
			pace.PopulateProperties(obj)
		end, translate_from_view):SetImage("icon16/zoom_out.png")

		translate_from_view:AddOption("current bone: " .. obj.Bone, function()
			bone_reposition(obj.Bone)
		end):SetImage("icon16/arrow_redo.png")
		translate_from_view:AddOption("no bone", function()
			bone_reposition("invalidbone")
		end):SetImage("icon16/arrow_redo.png")

		local bone_list = {}
		if isentity(bone_parent) then
			bone_list = pac.GetAllBones(bone_parent)
		else
			bone_list = pac.GetAllBones(bone_parent:GetOwner())
		end
		local bonekeys = {}
		local common_human_bones = {
			"head", "neck", "spine", "spine 1", "spine 2", "spine 4", "pelvis",
			"left clavicle", "left upperarm", "left forearm", "left hand",
			"right clavicle", "right upperarm", "right forearm", "right hand",
			"left thigh", "left calf", "left foot", "left toe", "right thigh", "right calf", "right foot", "right toe"
		}
		local sorted_bonekeys = {}
		for i,v in pairs(bone_list) do
			bonekeys[v.friendly] = v.friendly
		end
		for i,v in SortedPairs(bonekeys) do
			table.insert(sorted_bonekeys, v)
		end

		--basic humanoid bones
		if bone_list["spine"] and bone_list["head"] and bone_list["left upperarm"] and bone_list["right upperarm"] then
			local common_bones_menu, pnl = translate_from_view:AddSubMenu("shortened bone list (humanoid)") pnl:SetIcon("icon16/user.png")
			for _,bonename in ipairs(common_human_bones) do
				AddOptionRightClickable(bonename, function()
					bone_reposition(bonename)
				end, common_bones_menu):SetImage("icon16/user.png")
			end
		end

		translate_from_view:AddSpacer()
		local full_bones_menu, pnl = translate_from_view:AddSubMenu("full bone list for " .. tostring(bone_parent)) pnl:SetIcon("icon16/user_add.png")
		--full bone list
		for _,bonename in ipairs(sorted_bonekeys) do
			AddOptionRightClickable(bonename, function()
				bone_reposition(bonename)
			end, full_bones_menu):SetImage("icon16/connect.png")
		end 

		local function extract_camera_from_jiggle()
			camera = obj
			if not IsValid(camera.recent_jiggle) then
				return
			end
			local jig = camera.recent_jiggle
			local camang = jig:GetAngles()
			local campos = jig:GetPosition()
			local cambone = jig:GetBone()
			local camparent = jig:GetParent()
			camera:SetParent(camparent)
			camera:SetBone(cambone) camera:SetAngles(camang) camera:SetPosition(campos)
			jig:Remove()
			if not camera:IsHidden() then
				if not camera.Hide then
					timer.Simple(0, function()
						camera:SetHide(true) camera:SetHide(false)
					end)
				end
			end
		end
		local function insert_camera_into_jiggle()
			camera = obj
			local jig = camera.recent_jiggle
			if not IsValid(camera.recent_jiggle) then
				jig = pac.CreatePart("jiggle")
				camera.recent_jiggle = jig
				jig:SetEditorExpand(true)
			end
			jig:SetParent(camera:GetParent())
			jig:SetBone(camera.Bone) jig:SetAngles(camera:GetAngles()) jig:SetPosition(camera:GetPosition())
			camera:SetBone("head") camera:SetAngles(Angle(0,0,0)) camera:SetPosition(Vector(0,0,0))
			camera:SetParent(jig)
			if not camera:IsHidden() then
				if not camera.Hide then
					timer.Simple(0, function()
						camera:SetHide(true) camera:SetHide(false)
					end)
				end
			end

			return jig
		end

		--helper variable to adjust relative to player height
		local ent = obj:GetRootPart():GetOwner()
		local default_headbone = ent:LookupBone("ValveBiped.Bip01_Head1")
		if not default_headbone then
			for i=0,ent:GetBoneCount(),1 do
				if string.find(ent:GetBoneName(i), "head") or string.find(ent:GetBoneName(i), "Head") then
					default_headbone = i
					break
				end
			end
		end

		if default_headbone then
			local head_base_pos = ent:GetBonePosition(default_headbone)
			local trace = util.QuickTrace(head_base_pos + Vector(0,0,50), Vector(0,0,-10000), function(ent2) return ent2 == ent end)
			local mins, maxs = ent:GetHull()

			local height_headbase = math.Round((head_base_pos - ent:GetPos()).z,1)
			local height_eyepos = math.Round((ent:EyePos() - ent:GetPos()).z,1)
			local height_traced = math.Round((trace.HitPos - ent:GetPos()).z,1)
			local height_hull = (maxs - mins).z

			local height = height_traced
			if trace.Entity ~= ent then
				height = height_headbase
			end
 
			local info, pnl = main:AddSubMenu("calculated head height : " .. height .. " HU (" .. math.Round(height / 39,2) .." m)")
			info:AddOption("alternate height calculations"):SetImage("icon16/help.png")
			info:SetTooltip("Due to lack of standardization on models' scales, heights are not guaranteed to be accurate or consistent\n\nThe unit conversion used is 1 Hammer Unit : 2.5 cm (1 inch)")
			info:AddSpacer()

			AddOptionRightClickable("head bone's base position : " .. height_headbase .. " HU (" .. math.Round(height_headbase / 39,2) .." m)", function()
				height = height_headbase
				pnl:SetText("calculated head height : " .. height .. " HU (" .. math.Round(height / 39,2) .." m)")
			end, info):SetIcon("icon16/monkey.png")
			AddOptionRightClickable("traced to top of the head: " .. height_traced .. " HU (" .. math.Round(height_traced / 39,2) .." m)", function()
				height = height_traced
				pnl:SetText("calculated head height : " .. height .. " HU (" .. math.Round(height / 39,2) .." m)")
			end, info):SetIcon("icon16/arrow_down.png")
			AddOptionRightClickable("player eye position (ent:EyePos()) : " .. height_eyepos .. " HU (" .. math.Round(height_eyepos / 39,2) .." m)", function()
				height = height_eyepos
				pnl:SetText("calculated head height : " .. height .. " HU (" .. math.Round(height / 39,2) .." m)")
			end, info):SetIcon("icon16/eye.png")
			AddOptionRightClickable("hull dimensions : " .. height_hull .. " HU (" .. math.Round(height_hull / 39,2) .." m)", function()
				height = height_hull
				pnl:SetText("calculated head height : " .. height .. " HU (" .. math.Round(height / 39,2) .." m)")
			end, info):SetIcon("icon16/collision_on.png")

			pnl:SetImage("icon16/help.png")
			pnl:SetTooltip(ent:GetBoneName(default_headbone) .. "\n" .. ent:GetModel())
			local fp, pnl = main:AddSubMenu("first person camera setups") pnl:SetImage("icon16/eye.png")
				AddOptionRightClickable("easy first person (head)", function()
					extract_camera_from_jiggle()
					obj:SetBone("head")
					obj:SetPosition(Vector(5,-4,0)) obj:SetEyeAnglesLerp(1) obj:SetAngles(Angle(0,-90,-90))
					pace.PopulateProperties(obj)
				end, fp):SetIcon("icon16/eye.png")
	
				AddOptionRightClickable("on neck + collapsed head", function()
					extract_camera_from_jiggle()
					obj:SetBone("neck")
					obj:SetPosition(Vector(5,0,0)) obj:SetEyeAnglesLerp(1) obj:SetAngles(Angle(0,-90,-90))
					local bone = pac.CreatePart("bone3")
					bone:SetScaleChildren(true) bone:SetSize(0)
					bone:SetParent(obj)
					local event = pac.CreatePart("event") event:SetEvent("viewed_by_owner") event:SetParent(bone)
					pace.PopulateProperties(obj)
				end, fp):SetIcon("icon16/eye.png")
	
				AddOptionRightClickable("on neck + collapsed head + eyeang limiter", function()
					extract_camera_from_jiggle()
					obj:SetBone("neck")
					obj:SetPosition(Vector(5,0,0)) obj:SetEyeAnglesLerp(0.7) obj:SetAngles(Angle(0,-90,-90))
					local bone = pac.CreatePart("bone3")
					bone:SetScaleChildren(true) bone:SetSize(0)
					bone:SetParent(obj)
					local event = pac.CreatePart("event") event:SetEvent("viewed_by_owner") event:SetParent(bone)
					pace.PopulateProperties(obj)
				end, fp):SetIcon("icon16/eye.png")

			AddOptionRightClickable("smoothen", function()
				insert_camera_into_jiggle()
				pace.PopulateProperties(obj)
			end, main):SetIcon("icon16/chart_line.png")
			AddOptionRightClickable("undo smoothen (extract from jiggle)", function()
				extract_camera_from_jiggle()
				pace.PopulateProperties(obj)
			end, main):SetIcon("icon16/chart_line_delete.png")
	
			AddOptionRightClickable("close up (zoomed on the face)", function()
				extract_camera_from_jiggle()
				obj:SetBone("head") obj:SetAngles(Angle(0,90,90)) obj:SetPosition(Vector(3,-20,0)) obj:SetEyeAnglesLerp(0) obj:SetFOV(45)
				pace.PopulateProperties(obj)
			end, main):SetIcon("icon16/monkey.png")
	
			AddOptionRightClickable("Cowboy / medium shot (waist up) (relative to neck)", function()
				extract_camera_from_jiggle()
				obj:SetBone("neck") obj:SetAngles(Angle(0,120,90)) obj:SetPosition(Vector(14,-24,0)) obj:SetEyeAnglesLerp(0) obj:SetFOV(-1)
				pace.PopulateProperties(obj)
			end, main):SetIcon("icon16/user.png")
	
			AddOptionRightClickable("Cowboy / medium shot (waist up) (no bone) (20 + 0.6*height)", function()
				extract_camera_from_jiggle()
				obj:SetBone("invalidbone") obj:SetAngles(Angle(0,180,0)) obj:SetPosition(Vector(40,0,20 + 0.6*height)) obj:SetEyeAnglesLerp(0) obj:SetFOV(-1)
				pace.PopulateProperties(obj)
			end, main):SetIcon("icon16/user.png")
	
			AddOptionRightClickable("over the shoulder (no bone) (12 + 0.8*height)", function()
				extract_camera_from_jiggle()
				obj:SetBone("invalidbone") obj:SetAngles(Angle(0,0,0)) obj:SetPosition(Vector(-30,15,12 + 0.8*height)) obj:SetEyeAnglesLerp(0.3) obj:SetFOV(-1)
				pace.PopulateProperties(obj)
			end, main):SetIcon("icon16/user_gray.png")
	
			AddOptionRightClickable("over the shoulder (with jiggle)", function()
				local jiggle = insert_camera_into_jiggle()
				jiggle:SetConstrainSphere(75) jiggle:SetSpeed(3)
				obj:SetEyeAnglesLerp(0.7) obj:SetFOV(-1)
				jiggle:SetBone("neck") jiggle:SetAngles(Angle(180,90,90)) jiggle:SetPosition(Vector(-2,18,-10))
				pace.PopulateProperties(obj)
			end, main):SetIcon("icon16/user_gray.png")

			AddOptionRightClickable("full shot (0.7*height)", function()
				extract_camera_from_jiggle()
				obj:SetEyeAnglesLerp(0) obj:SetFOV(-1)
				obj:SetBone("invalidbone") obj:SetAngles(Angle(6,180,0)) obj:SetPosition(Vector(height,-15,height * 0.7))
				pace.PopulateProperties(obj)
			end, main):SetIcon("icon16/user_suit.png")
		end

		AddOptionRightClickable("wide shot (with jiggle)", function()
			local jiggle = insert_camera_into_jiggle()
			jiggle:SetConstrainSphere(150) jiggle:SetSpeed(1)
			obj:SetEyeAnglesLerp(0.2) obj:SetFOV(-1)
			jiggle:SetBone("invalidbone") jiggle:SetAngles(Angle(0,0,0)) jiggle:SetPosition(Vector(0,15,120))
			obj:SetPosition(Vector(-250,0,0))
			pace.PopulateProperties(obj)
		end, main):SetIcon("icon16/arrow_out.png")

		AddOptionRightClickable("extreme wide shot (with jiggle)", function()
			local jiggle = insert_camera_into_jiggle()
			jiggle:SetConstrainSphere(0) jiggle:SetSpeed(0.3)
			obj:SetEyeAnglesLerp(0.1) obj:SetFOV(-1)
			jiggle:SetBone("invalidbone") jiggle:SetAngles(Angle(0,0,0)) jiggle:SetPosition(Vector(-500,0,200))
			obj:SetPosition(Vector(0,0,0)) obj:SetAngles(Angle(15,0,0))
			pace.PopulateProperties(obj)
		end, main):SetIcon("icon16/map.png")

		AddOptionRightClickable("bird eye view (with jiggle)", function()
			local jiggle = insert_camera_into_jiggle()
			jiggle:SetConstrainSphere(300) jiggle:SetSpeed(1)
			obj:SetEyeAnglesLerp(0.2) obj:SetFOV(-1)
			jiggle:SetBone("invalidbone") jiggle:SetAngles(Angle(0,0,0)) jiggle:SetPosition(Vector(-150,0,300))
			obj:SetPosition(Vector(0,0,0)) obj:SetAngles(Angle(70,0,0))
			pace.PopulateProperties(obj)
		end, main):SetIcon("icon16/map_magnify.png")

		AddOptionRightClickable("Dutch shot (tilt)", function()
			local jiggle = insert_camera_into_jiggle()
			jiggle:SetConstrainSphere(150) jiggle:SetSpeed(1)
			obj:SetEyeAnglesLerp(0) obj:SetFOV(-1)
			jiggle:SetBone("invalidbone") jiggle:SetAngles(Angle(0,0,0)) jiggle:SetPosition(Vector(0,15,50))
			obj:SetPosition(Vector(-75,0,0)) obj:SetAngles(Angle(0,0,25))
			pace.PopulateProperties(obj)
		end, main):SetIcon("icon16/arrow_refresh.png")
	elseif obj.ClassName == "faceposer" then
		if obj:GetDynamicProperties() == nil then main:AddOption("No flexes found!"):SetIcon("icon16/cancel.png") return end
		main:AddOption("reset expressions", function()
			for i,prop in pairs(obj:GetDynamicProperties()) do
				if string.lower(prop.key) == prop.key or prop.key == "Blink" then
					prop.set(obj,0)
				end
			end
			pace.PopulateProperties(obj)
		end):SetIcon("icon16/cancel.png")
		local flexes = {}
		for i,prop in pairs(obj:GetDynamicProperties()) do
			flexes[prop.key] = prop.key
		end

		local function full_match(tbl)
			for i,v in pairs(tbl) do
				if not flexes[v] then
					return false
				end
			end
			return true
		end
		local common_combinations = {
			{"eyes_look_down", "eyes_look_up", "eyes_look_right", "eyes_look_left"},
			{"eyes-look-down", "eyes-look-up", "eyes-look-right", "eyes-look-left"},
			{"eye_left_down", "eye_left_up", "eye_left_right", "eye_left_left", "eye_right_down", "eye_right_up", "eye_right_right", "eye_right_left"},
			{"Eyes Down", "Eyes Up", "Eyes Right", "Eyes Left"},
			{"eyes down", "eyes up", "eyes right", "eyes left"},
			{"eye_down", "eye_up", "eye_right", "eye_left"},
			{"LookDown", "LookUp", "LookRight", "LookLeft"}
		}
		local final_combination
		for i,tbl in ipairs(common_combinations) do
			if full_match(tbl) then
				final_combination = tbl
			end
		end

		if final_combination then
			main:AddOption("4-way look", function()
				for _, flex in ipairs(final_combination) do
					local new_proxy = pac.CreatePart("proxy") new_proxy:SetParent(obj)
					if string.match(string.lower(flex), "down$") then
						new_proxy:SetExpression("pose_parameter_true(\"head_pitch\")/60")
					elseif string.match(string.lower(flex), "up$") then
						new_proxy:SetExpression("-pose_parameter_true(\"head_pitch\")/60")
					elseif string.match(string.lower(flex), "left$") then
						new_proxy:SetExpression("pose_parameter_true(\"head_yaw\")/30")
					elseif string.match(string.lower(flex), "right$") then
						new_proxy:SetExpression("-pose_parameter_true(\"head_yaw\")/30")
					end
					new_proxy:SetVariableName(flex)
				end
			end):SetIcon("icon16/calculator.png")
		else --what if those are bones?

		end

		main:AddOption("add face camera and view it", function()
			local cam = pac.CreatePart("camera") cam:SetParent(obj)
			cam:SetBone("head") cam:SetAngles(Angle(0,90,90)) cam:SetPosition(Vector(3,-20,0)) cam:SetEyeAnglesLerp(0) cam:SetFOV(45)
			pace.PopulateProperties(cam)
			pace.ManuallySelectCamera(cam, true)
		end):SetIcon("icon16/camera.png")
	elseif obj.ClassName == "command" then
		if pac.LocalPlayer.pac_command_events then
			local cmd_menu, pnl = main:AddSubMenu("command event activators") pnl:SetImage("icon16/clock_red.png")
			for cmd,_ in SortedPairs(pac.LocalPlayer.pac_command_events) do
				cmd_menu2, pnl2 = cmd_menu:AddSubMenu(cmd) pnl2:SetImage("icon16/clock_red.png")
				cmd_menu2:AddOption("instant", function()
					obj:SetString("pac_event " .. cmd)
				end):SetImage("icon16/clock_red.png")
				cmd_menu2:AddOption("on", function()
					obj:SetString("pac_event " .. cmd .. " 1")
				end):SetImage("icon16/clock_red.png")
				cmd_menu2:AddOption("off", function()
					obj:SetString("pac_event " .. cmd .. " 0")
				end):SetImage("icon16/clock_red.png")
				cmd_menu2:AddOption("toggle", function()
					obj:SetString("pac_event " .. cmd .. " 2")
				end):SetImage("icon16/clock_red.png")
			end

			main:AddOption("save current events to a single command", function()
				local tbl3 = {}
				for i,v in pairs(pac.LocalPlayer.pac_command_events) do tbl3[i] = v.on end
				new_expression = ""
				for i,v in pairs(tbl3) do new_expression = new_expression .. "pac_event " .. i .. " " .. v .. ";" end
				obj:SetUseLua(false)
			end):SetIcon("icon16/application_xp_terminal.png")

		end
		local inputs = {"forward", "back", "moveleft", "moveright", "attack", "attack2", "use", "left", "right", "jump", "duck", "speed", "walk", "reload", "alt1", "alt2", "showscores", "grenade1", "grenade2"}
		local input_menu, pnl = main:AddSubMenu("movement controllers (dash etc.)")
			--standard blip
			local input_menu1, pnl2 = input_menu:AddSubMenu("quick trigger") pnl2:SetImage("icon16/asterisk_yellow.png")
			for i,mv in ipairs(inputs) do
				input_menu1:AddOption(mv, function()
					obj:SetString("+"..mv)
					local timerx = pac.CreatePart("event") timerx:SetParent(obj) timerx:SetAffectChildrenOnly(true) timerx:SetEvent("timerx") timerx:SetArguments("0.2@@1@@0")
					local off_cmd = pac.CreatePart("command") off_cmd:SetParent(timerx) off_cmd:SetString("-"..mv)
				end):SetIcon("icon16/asterisk_yellow.png")
			end
			--button substitutor
			local input_menu2, pnl2 = input_menu:AddSubMenu("button pair (fake bind)") pnl2:SetImage("icon16/contrast_high.png")
			for i,mv in ipairs(inputs) do
				input_menu2:AddOption(mv, function()
					Derma_StringRequest("movement command setup", "write a button to use!", "mouse_left", function(str)
						obj:SetString("+"..mv)
						local newevent1 = pac.CreatePart("event") newevent1:SetEvent("button") newevent1:SetInvert(true) newevent1:SetArguments(str)
						local newevent2 = pac.CreatePart("event") newevent2:SetEvent("button") newevent2:SetInvert(false) newevent2:SetArguments(str)
						local off_cmd = pac.CreatePart("command") off_cmd:SetString("-"..mv)

						off_cmd:SetParent(obj.Parent)
						if obj.Parent.ClassName == "event" and obj.Parent.AffectChildrenOnly then
							local parent = obj.Parent
							newevent1:SetParent(parent)
							newevent1:SetAffectChildrenOnly(true)
							obj:SetParent(newevent1)
							newevent2:SetParent(parent)
							newevent2:SetAffectChildrenOnly(true)
							off_cmd:SetParent(newevent2)
						else
							newevent1:SetParent(obj)
							newevent2:SetParent(off_cmd)
							off_cmd:SetParent(obj.Parent)
						end
					end)
				end):SetIcon("icon16/contrast_high.png")
			end
		pnl:SetImage("icon16/keyboard.png")


		local lua_menu, pnl = main:AddSubMenu("Lua hackery") pnl:SetImage("icon16/page_code.png")
			lua_menu:AddOption("Chat decoder -> command proxy", function()
				Derma_StringRequest("create chat decoder", "please input a name to use for the decoder.\ne.g. you will say \"value=5", "", function(str)
					obj:SetUseLua(true) obj:SetString([[local strs = string.Split(LocalPlayer().pac_say_event.str, "=") RunConsoleCommand("pac_proxy", "]] .. str .. [[", tonumber(strs[2]))]])
					local say = pac.CreatePart("event") say:SetEvent("say") say:SetInvert(true) say:SetArguments(str .. "=0.5") say:SetAffectChildrenOnly(true)
					local timerx = pac.CreatePart("event") timerx:SetEvent("timerx") timerx:SetInvert(false) timerx:SetArguments("0.2@@1@@0") timerx:SetAffectChildrenOnly(true)
					say:SetParent(obj.Parent) timerx:SetParent(say) obj:SetParent(say)
					local proxy = pac.CreatePart("proxy") proxy:SetExpression("command(\"" .. str .. "\")")
					proxy:SetParent(obj.Parent)
				end)
			end):SetIcon("icon16/comment.png")
			lua_menu:AddOption("random command (e.g. trigger random animations)", function()
				Derma_StringRequest("create random command", "please input a name for the event series\nyou should probably already have a series of command events like animation1, animation2, animation3 etc", "", function(str)
					obj:SetUseLua(true) obj:SetString([[local num = math.floor(math.random()*5) RunConsoleCommand("pac_event", "]] .. str .. [[" num]])
				end)
			end):SetIcon("icon16/award_star_gold_1.png")
			lua_menu:AddOption("random command (pac_proxy)", function()
				Derma_StringRequest("create random command", "please input a name for the proxy command", "", function(str)
					obj:SetUseLua(true) obj:SetString([[local num = math.random()*100 RunConsoleCommand("pac_proxy", "]] .. str .. [[" num]])
				end)
			end):SetIcon("icon16/calculator.png")
			lua_menu:AddOption("X-Ray hook (halos)", function()
				obj:SetName("halos on") obj:SetString([[hook.Add("PreDrawHalos","xray_halos", function() halo.Add(ents.FindByClass("npc_combine_s"), Color(255,0,0), 5, 5, 5, true, true) end)]])
				local newobj = pac.CreatePart("command") newobj:SetParent(obj.Parent) newobj:SetName("halos off") newobj:SetString([[hook.Remove("PreDrawHalos","xray_halos")]])
				obj:SetUseLua(true) newobj:SetUseLua(true)
			end):SetIcon("icon16/shading.png")
			lua_menu:AddOption("X-Ray hook (ignorez)", function()
				obj:SetName("ignoreZ on") obj:SetString([[hook.Add("PostDrawTranslucentRenderables","xray_ignorez", function() cam.IgnoreZ( true ) for i,ent in pairs(ents.FindByClass("npc_combine_s")) do ent:DrawModel() end cam.IgnoreZ( false ) end)]])
				local newobj = pac.CreatePart("command") newobj:SetName("ignoreZ off") newobj:SetParent(obj.Parent) newobj:SetString([[hook.Remove("PostDrawTranslucentRenderables","xray_ignorez")]])
				obj:SetUseLua(true) newobj:SetUseLua(true)
			end):SetIcon("icon16/shape_move_front.png")
	elseif obj.ClassName == "bone3" then
		local collapses, pnl = main:AddSubMenu("bone collapsers") pnl:SetImage("icon16/compress.png")
		collapses:AddOption("collapse arms", function()
			local group = pac.CreatePart("group") group:SetParent(obj.Parent)
			local right = pac.CreatePart("bone3") right:SetParent(group) right:SetSize(0) right:SetScaleChildren(true) right:SetBone("right clavicle")
			local left = pac.CreatePart("bone3") left:SetParent(group) left:SetSize(0) left:SetScaleChildren(true) left:SetBone("left clavicle")
		end):SetIcon("icon16/compress.png")
		collapses:AddOption("collapse legs", function()
			local group = pac.CreatePart("group") group:SetParent(obj.Parent)
			local right = obj
			right:SetParent(group) right:SetSize(0) right:SetScaleChildren(true) right:SetBone("right thigh")
			local left = pac.CreatePart("bone3") left:SetParent(group) left:SetSize(0) left:SetScaleChildren(true) left:SetBone("left thigh")
		end):SetIcon("icon16/compress.png")
		collapses:AddOption("collapse by keyword", function()
			Derma_StringRequest("collapse bones", "please input a keyword to match", "head", function(str)
				local group = pac.CreatePart("group") group:SetParent(obj.Parent)
				local ent = obj:GetOwner()
				for bone,tbl in pairs(pac.GetAllBones(ent)) do
					if string.find(bone, str) ~= nil then
						local newbone = pac.CreatePart("bone3") newbone:SetParent(group) newbone:SetSize(0) newbone:SetScaleChildren(true) newbone:SetBone(bone)
					end
				end
			end)
		end):SetIcon("icon16/text_align_center.png")
	elseif obj.ClassName == "health_modifier" then
		main:AddOption("setup HUD display for extra health (total)", function()
			local cmd_on = pac.CreatePart("command") cmd_on:SetParent(obj) cmd_on:SetUseLua(true) cmd_on:SetName("enable HUD") cmd_on:SetExecuteOnWear(true)
			local cmd_off = pac.CreatePart("command") cmd_off:SetParent(obj) cmd_off:SetUseLua(true) cmd_off:SetName("disable HUD") cmd_off:SetExecuteOnWear(false)
			cmd_on:SetString([[surface.CreateFont("HudNumbers_Bigger", {font = "HudNumbers", size = 75})
surface.CreateFont("HudNumbersGlow_Bigger", {font = "HudNumbersGlow", size = 75, blursize = 4, scanlines = 2, antialias = true})
local x = 50
local y = ScrH() - 190
local clr = Color(255,230,0)
hook.Add("HUDPaint", "extrahealth_total", function()
	draw.DrawText("PAC EX HP", "Trebuchet24", x, y + 20, clr)
	draw.DrawText("subtitle", "Trebuchet18", x, y + 40, clr)
	draw.DrawText(LocalPlayer().pac_healthbars_total, "HudNumbersGlow_Bigger", x + 100, y, clr)
	draw.DrawText(LocalPlayer().pac_healthbars_total, "HudNumbers_Bigger", x + 100, y, clr)
end)]])
			cmd_off:SetString([[hook.Remove("HUDPaint", "extrahealth_total")]])
		end):SetIcon("icon16/application_xp_terminal.png")

		main:AddOption("setup HUD display for extra health (this part only)", function()
			local function setup()
				local cmd_on = pac.CreatePart("command") cmd_on:SetParent(obj) cmd_on:SetUseLua(true) cmd_on:SetName("enable HUD") cmd_on:SetExecuteOnWear(true)
			local cmd_off = pac.CreatePart("command") cmd_off:SetParent(obj) cmd_off:SetUseLua(true) cmd_off:SetName("disable HUD") cmd_off:SetExecuteOnWear(false)
			cmd_on:SetString([[surface.CreateFont("HudNumbers_Bigger", {font = "HudNumbers", size = 75})
surface.CreateFont("HudNumbersGlow_Bigger", {font = "HudNumbersGlow", size = 75, blursize = 4, scanlines = 2, antialias = true})
local x = 50
local y = ScrH() - 190
local clr = Color(255,230,0)
hook.Add("HUDPaint", "extrahealth_]]..obj.UniqueID..[[", function()
	draw.DrawText("PAC EX HP\n]]..obj:GetName()..[[", "Trebuchet24", x, y + 20, clr)
	draw.DrawText(LocalPlayer().pac_healthbars_uidtotals["]]..obj.UniqueID..[["], "HudNumbersGlow_Bigger", x + 100, y, clr)
	draw.DrawText(LocalPlayer().pac_healthbars_uidtotals["]]..obj.UniqueID..[["], "HudNumbers_Bigger", x + 100, y, clr)
end)]])
			cmd_off:SetString([[hook.Remove("HUDPaint", "extrahealth_]]..obj.UniqueID..[[")]])
			end
			if obj.Name == "" then
				Derma_StringRequest("prompt", "Looks like your health modifier doesn't have a name.\ngive it one?", "", function(str) obj:SetName(str) setup() end)
			else
				setup(obj.Name)
			end
		end):SetIcon("icon16/application_xp_terminal.png")

		main:AddOption("setup HUD display for extra health (this layer)", function()
			local cmd_on = pac.CreatePart("command") cmd_on:SetParent(obj) cmd_on:SetUseLua(true) cmd_on:SetName("enable HUD") cmd_on:SetExecuteOnWear(true)
			local cmd_off = pac.CreatePart("command") cmd_off:SetParent(obj) cmd_off:SetUseLua(true) cmd_off:SetName("disable HUD") cmd_off:SetExecuteOnWear(false)
			cmd_on:SetString([[surface.CreateFont("HudNumbers_Bigger", {font = "HudNumbers", size = 75})
surface.CreateFont("HudNumbersGlow_Bigger", {font = "HudNumbersGlow", size = 75, blursize = 4, scanlines = 2, antialias = true})
local x = 50
local y = ScrH() - 190
local clr = Color(255,230,0)
hook.Add("HUDPaint", "extrahealth_layer_]]..obj.BarsLayer..[[", function()
	draw.DrawText("PAC EX HP\nLYR]]..obj.BarsLayer..[[", "Trebuchet24", x, y + 20, clr)
	draw.DrawText(LocalPlayer().pac_healthbars_layertotals[]]..obj.BarsLayer..[[], "HudNumbersGlow_Bigger", x + 100, y, clr)
	draw.DrawText(LocalPlayer().pac_healthbars_layertotals[]]..obj.BarsLayer..[[], "HudNumbers_Bigger", x + 100, y, clr)
end)]])
			cmd_off:SetString([[hook.Remove("HUDPaint", "extrahealth_layer_]]..obj.BarsLayer..[[")]])
		end):SetIcon("icon16/application_xp_terminal.png")

		main:AddOption("Use extra health (total value) in a proxy", function() local proxy = pac.CreatePart("proxy") proxy:SetParent(obj) proxy:SetExpression("pac_healthbars_total()") proxy:SetExtra1(obj.Expression) end):SetIcon("icon16/calculator.png")
		main:AddOption("Use extra health (this part's current HP) in a proxy", function() local proxy = pac.CreatePart("proxy") proxy:SetParent(obj) proxy:SetExpression("pac_healthbar_uidvalue(\""..obj.UniqueID.."\")") end):SetIcon("icon16/calculator.png")
		main:AddOption("Use extra health (this part's remaining number of bars) in a proxy", function() local proxy = pac.CreatePart("proxy") proxy:SetParent(obj) proxy:SetExpression("pac_healthbar_remaining_bars(\""..obj.UniqueID.."\")") end):SetIcon("icon16/calculator.png")
		main:AddOption("Use extra health (this layer's current total value) in a proxy", function() local proxy = pac.CreatePart("proxy") proxy:SetParent(obj) proxy:SetExpression("pac_healthbars_layertotal("..obj.BarsLayer..")") end):SetIcon("icon16/calculator.png")
	elseif obj.ClassName == "hitscan" then
		main:AddOption("approximate tracers from particles", function()
			if not obj.previous_tracerparticle then
				obj.previous_tracerparticle = pac.CreatePart("particles")
			end
			local particle = obj.previous_tracerparticle
			particle:SetParent(obj)
			particle:SetNumberParticles(obj.NumberBullets) particle:SetDieTime(0.3)
			particle:SetSpread(obj.Spread) obj:SetTracerSparseness(0)
			particle:SetMaterial("sprites/orangecore1") particle:SetLighting(false) particle:SetCollide(false)
			particle:SetFireOnce(true) particle:SetStartSize(10) particle:SetEndSize(0) particle:SetStartLength(250) particle:SetEndLength(2000)
			particle:SetGravity(Vector(0,0,0))
		end):SetIcon("icon16/water.png")
	elseif obj.ClassName == "jiggle" then
		main:AddOption("Limit Angles", function()
			obj:SetClampAngles(true) obj:SetAngleClampAmount(Vector(50,50,50))
		end):SetIcon("icon16/compress.png")
		local named_part = obj.Parent or obj
		if not IsValid(named_part) then named_part = obj end
		if pace.recently_substituted_movable_part then
			if pace.recently_substituted_movable_part.Parent == obj then
				named_part = pace.recently_substituted_movable_part
			end
		end
		local str = named_part:GetName() str = string.Replace(str," ","")
		main:AddOption("jiggle speed trick: deployable anchor (hidden by event)", function()
			obj:SetSpeed(0) obj:SetResetOnHide(true)
			local event = pac.CreatePart("event") event:SetParent(obj)
			event:SetEvent("command") event:SetArguments("jiggle_anchor_"..str)
		end):SetIcon("icon16/anchor.png")
		main:AddOption("jiggle speed trick: movable anchor (proxy control)", function()
			obj:SetSpeed(0) obj:SetResetOnHide(true)
			local proxy = pac.CreatePart("proxy") proxy:SetParent(obj)
			proxy:SetVariableName("Speed")
			proxy:SetExpression("3") proxy:SetExpressionOnHide("0")
			local event = pac.CreatePart("event") event:SetParent(proxy)
			event:SetEvent("command") event:SetArguments("jiggle_anchor_"..str)
		end):SetIcon("icon16/anchor.png")
	elseif obj.ClassName == "interpolated_multibone" then
		main:AddOption("rough demo: create random nodes", function()
			local group = pac.CreatePart("group")
			group:SetParent(obj.Parent)
			obj:SetParent(group)
			local axismodel = pac.CreatePart("model2") axismodel:SetParent(obj) axismodel:SetModel("models/editor/axis_helper_thick.mdl") axismodel:SetSize(5)
			for i=1,5,1 do
				local newnode = pac.CreatePart("model2") newnode:SetParent(obj.Parent) newnode:SetModel("models/empty.mdl")
				newnode:SetName("test_node_"..i)
				obj["SetNode"..i](obj,newnode)
				newnode:SetPosition(VectorRand()*100) newnode:SetAngles(AngleRand()) newnode:SetBone(obj.Bone)
			end
			local proxy = pac.CreatePart("proxy")
			proxy:SetParent(obj) proxy:SetVariableName("LerpValue") proxy:SetExpression("time()%6")
		end):SetIcon("icon16/anchor.png")
		main:AddOption("add node at camera (local head)", function()
			if obj.Parent.ClassName == "group" and obj.Parent ~= obj:GetRootPart() then
				obj.recent_parent = obj.Parent
			end
			if not obj.recent_parent then
				local group = pac.CreatePart("group")
				group:SetParent(obj.Parent)
				obj:SetParent(group)
				obj.recent_parent = group
			end
			local index = 1
			for i=1,20,1 do
				if not IsValid(obj["Node"..i]) then --free slot?
					index = i
					break
				end
			end
			local newnode = pac.CreatePart("model2") newnode:SetParent(obj.Parent) newnode:SetModel("models/empty.mdl")
			local localpos, localang = WorldToLocal(pace.ViewPos, pace.ViewAngles, newnode:GetWorldPosition(), newnode:GetWorldAngles())
			newnode:SetNotes("recorded FOV : " .. math.Round(pace.ViewFOV))
			newnode:SetName("cam_node_"..index)
			obj["SetNode"..index](obj,newnode)
			newnode:SetPosition(localpos) newnode:SetAngles(localang)
		end):SetIcon("icon16/camera.png")
		main:AddOption("add node at camera (entity invalidbone)", function()
			local index = 1
			for i=1,20,1 do
				if not IsValid(obj["Node"..i]) then --free slot?
					index = i
					break
				end
			end
			local newnode = pac.CreatePart("model2")
			newnode:SetParent(obj:GetRootPart())

			newnode:SetModel("models/empty.mdl")
			newnode:SetBone("invalidbone")
			local localpos, localang = WorldToLocal(pace.ViewPos, pace.ViewAngles, newnode:GetWorldPosition(), newnode:GetWorldAngles())
			newnode:SetNotes("recorded FOV : " .. math.Round(pace.ViewFOV))
			newnode:SetName("cam_node_"..index) newnode:SetBone("invalidbone")
			obj["SetNode"..index](obj,newnode)
			newnode:SetPosition(localpos) newnode:SetAngles(localang)
		end):SetIcon("icon16/camera.png")
		if #pace.BulkSelectList > 0 then
			main:AddOption("(" .. #pace.BulkSelectList .. " parts in Bulk select) Set nodes (overwrite)", function()
				for i=1,20,1 do
					if pace.BulkSelectList[i] then
						obj["SetNode"..i](obj,pace.BulkSelectList[i])
					else
						obj["SetNode"..i](obj,nil)
					end
				end
				pace.PopulateProperties(obj)
			end):SetIcon("icon16/pencil_delete.png")
			main:AddOption("(" .. #pace.BulkSelectList .. " parts in Bulk select) Set nodes (append)", function()
				for i=1,20,1 do
					if not IsValid(obj["Node"..i]) then --free slot?
						index = i
						break
					end
				end
				for i,part in ipairs(pace.BulkSelectList) do
					obj["SetNode"..(index + i - 1)](obj,part)
				end
				pace.PopulateProperties(obj)
			end):SetIcon("icon16/pencil_add.png")
		end
	end
end

--these are more to perform an action that doesn't really affect many different parameters. maybe one or two at most
function pace.AddClassSpecificPartMenuComponents(menu, obj)
	if obj.Notes == "showhidetest" then menu:AddOption("(hide/show test) reset", function() obj:CallRecursive("OnShow") end):SetIcon("icon16/star.png") end

	if obj.ClassName == "camera" then
		if not obj:IsHidden() then
			local remembered_view = {pace.ViewPos, pace.ViewAngles}
			local view
			local viewing = obj == pac.active_camera
			local initial_name = viewing and "Unview this camera" or "View this camera"
			view = AddOptionRightClickable(initial_name, function()
				if not viewing then
					remembered_view = {pace.ViewPos, pace.ViewAngles}
					pace.ManuallySelectCamera(obj, true)
					view:SetText("Unview this camera")
				else
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
					pace.ViewPos = remembered_view[1]
					pace.ViewAngles = remembered_view[2]
					view:SetText("View this camera")
				end
				viewing = obj == pac.active_camera
			end, menu) view:SetIcon("icon16/star.png")
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
		menu:AddOption("do damage", function() obj:OnShow() end):SetIcon("icon16/star.png")
		menu:AddOption("debug: clear hit markers", function() obj:ClearHitMarkers() end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "force" and not obj.Continuous then
		menu:AddOption("(non-continuous only) force impulse", function() obj:OnShow() end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "particles" then
		if obj.FireOnce then
			menu:AddOption("(FireOnce only) spew", function() obj:OnShow() end):SetIcon("icon16/star.png")
		end
	elseif obj.ClassName == "proxy" then
		if string.find(obj.Expression, "timeex") or string.find(obj.Expression, "ezfade") then
			menu:AddOption("(timeex) reset clock", function() obj:OnHide() obj:OnShow() end):SetIcon("icon16/star.png")
		end
		if not IsValid(obj.TargetPart) and obj.MultipleTargetParts == "" then
			menu:AddOption("engrave / quick-link to parent", function()
				if not obj.AffectChildrenOnly then
					obj:SetTargetPart(obj:GetParent())
				elseif #obj:GetChildrenList() == 1 then
					obj:SetTargetPart(obj:GetChildrenList()[1])
				end

			end):SetIcon("icon16/star.png")
		end
		if #pace.BulkSelectList > 0 then
			menu:AddOption("(" .. #pace.BulkSelectList .. " parts in Bulk select) Set multiple target parts", function()
				local uid_tbl = {}
				for i,part in ipairs(pace.BulkSelectList) do
					table.insert(uid_tbl, part.UniqueID)
				end
				obj:SetMultipleTargetParts(table.concat(uid_tbl,";"))
			end):SetIcon("icon16/star.png")
			if obj.MultipleTargetParts ~= "" then
				menu:AddOption("(" .. #pace.BulkSelectList .. " parts in Bulk select) Add to multiple target parts", function()
					local anti_duplicate = {}
					local uid_tbl = string.Split(obj.MultipleTargetParts,";")
					
					for i,uid in ipairs(uid_tbl) do
						anti_duplicate[uid] = uid
					end
					for i,part in ipairs(pace.BulkSelectList) do
						anti_duplicate[part.UniqueID] = part.UniqueID
					end
					uid_tbl = {}
					for _,uid in pairs(anti_duplicate) do
						table.insert(uid_tbl, uid)
					end
					obj:SetMultipleTargetParts(table.concat(uid_tbl,";"))
				end):SetIcon("icon16/star.png")
			end
		end
	elseif obj.ClassName == "beam" then
		if not IsValid(obj.TargetPart) and obj.MultipleEndPoints == "" then
			menu:AddOption("Link parent as end point", function()
				obj:SetEndPoint(obj:GetParent())
			end):SetIcon("icon16/star.png")
		end
		if #pace.BulkSelectList > 0 then
			menu:AddOption("(" .. #pace.BulkSelectList .. " parts in Bulk select) Set multiple end points", function()
				local uid_tbl = {}
				for i,part in ipairs(pace.BulkSelectList) do
					if not part.GetWorldPosition then erroring = true else table.insert(uid_tbl, part.UniqueID) end
				end
				if erroring then pac.InfoPopup("Some selected parts were invalid endpoints as they are not base_movables", {pac_part = false, obj_type = "cursor", panel_exp_height = 100}) end
				obj:SetMultipleEndPoints(table.concat(uid_tbl,";"))
			end):SetIcon("icon16/star.png")
		end
	elseif obj.ClassName == "shake" then
		menu:AddOption("activate (editor camera should be off)", function() obj:OnHide() obj:OnShow() end):SetIcon("icon16/star.png")
	elseif obj.ClassName == "event" then
		if obj.Event == "command" and pac.LocalPlayer.pac_command_events then
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
		if #pace.BulkSelectList > 0 then
			menu:AddOption("(" .. #pace.BulkSelectList .. " parts in Bulk select) Set multiple target parts", function()
				local uid_tbl = {}
				for i,part in ipairs(pace.BulkSelectList) do
					table.insert(uid_tbl, part.UniqueID)
				end
				obj:SetMultipleTargetParts(table.concat(uid_tbl,";"))
			end):SetIcon("icon16/star.png")
			if obj.Event == "and_gate" or obj.Event == "or_gate" then
				menu:AddOption("(" .. #pace.BulkSelectList .. " parts in Bulk select) Set AND or OR gate arguments", function()
					local uid_tbl = {}
					for i,part in ipairs(pace.BulkSelectList) do
						table.insert(uid_tbl, part.UniqueID)
					end
					obj:SetProperty("uids", table.concat(uid_tbl,";"))
				end):SetIcon("icon16/clock_link.png")
			end
			if obj.Event == "xor_gate" and #pace.BulkSelectList == 2 then
				menu:AddOption("(2 parts in Bulk select) Set XOR arguments", function()
					local uid_tbl = {}
					for i,part in ipairs(pace.BulkSelectList) do
						table.insert(uid_tbl, part.UniqueID)
					end
					obj:SetArguments(table.concat(uid_tbl,"@@"))
				end):SetIcon("icon16/clock_link.png")
			end
		end
		if not IsValid(obj.DestinationPart) then
			menu:AddOption("engrave / quick-link to parent", function() obj:SetDestinationPart(obj:GetParent()) end):SetIcon("icon16/star.png")
		end
	end

	do --event reorganization
		local full_events = true
		for i,v in ipairs(pace.BulkSelectList) do
			if v.ClassName ~= "event" then full_events = false end
		end
		if #pace.BulkSelectList > 0 and full_events then
			menu:AddOption("reorganize into a non-ACO pocket", function()
				for i,part in ipairs(pace.BulkSelectList) do
					part:SetParent(part:GetRootPart())
				end
				local prime_parent = obj:GetParent()
				if prime_parent.ClassName == "event" or pace.BulkSelectList[1] == prime_parent then
					prime_parent = obj:GetRootPart()
				end
				for i,part in ipairs(pace.BulkSelectList) do
					part:SetParent()
					part:SetAffectChildrenOnly(false)
					part:SetDestinationPart()
				end
				obj:SetParent(prime_parent)
				for i,part in ipairs(pace.BulkSelectList) do
					part:SetParent(obj)
				end
			end):SetIcon("icon16/clock_link.png")
			menu:AddOption("reorganize into an ACO downward tower", function()
				local parent = obj:GetParent()
				local grandparent = obj:GetParent()
				if parent.Parent then grandparent = parent:GetParent() end
				
				for i,part in ipairs(pace.BulkSelectList) do
					part:SetAffectChildrenOnly(true)
					part:SetDestinationPart()
					part:SetParent(parent)
					parent = part
				end
				pace.BulkSelectList[1]:SetParent(obj:GetParent())
				obj:SetParent(parent)
			end):SetIcon("icon16/clock_link.png")
		end
	end

	pace.AddQuickSetupsToPartMenu(menu, obj)
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
	elseif option_name == "arraying_menu" then
		local arraying_menu, pnl = menu:AddSubMenu(L"arraying menu", function() pace.OpenArrayingMenu(obj) end) pnl:SetImage("icon16/table_multiple.png")
		if obj.GetWorldPosition then
			local icon = obj.pace_tree_node.ModelPath or obj.Icon
			if string.sub(icon,-3) == "mdl" then icon = "materials/spawnicons/"..string.gsub(icon, ".mdl", "")..".png" end
			arraying_menu:AddOption(L"base:" .. obj:GetName(), function() pace.OpenArrayingMenu(obj) end):SetImage(icon)
		end
		if obj.Parent.GetWorldPosition then
			local icon = obj.pace_tree_node.ModelPath or obj.Icon
			if string.sub(icon,-3) == "mdl" then icon = "materials/spawnicons/"..string.gsub(icon, ".mdl", "")..".png" end
			arraying_menu:AddOption(L"base:" .. obj.Parent:GetName(), function() pace.OpenArrayingMenu(obj.Parent) end):SetImage(icon)
		end
	elseif option_name == "criteria_process" then
		menu:AddOption("Process parts by criteria", function() pace.PromptProcessPartsByCriteria(obj) end):SetIcon("icon16/text_list_numbers.png")
	elseif option_name == "bulk_morph" then
		menu:AddOption("Morph Properties over bulk select", function() pace.BulkMorphProperty() end):SetIcon("icon16/chart_line.png")
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
		if mode == 0 then info = "none"
		elseif mode == 1 then info = "passive"
		elseif mode == 2 then info = "custom keypress:"..GetConVar("pac_bulk_select_halo_key"):GetString()
		elseif mode == 3 then info = "preset keypress: control"
		elseif mode == 4 then info = "preset keypress: shift" end

		bulk_menu:AddOption(L"Bulk select highlight mode: "..info, function()
			Derma_StringRequest("Change bulk select halo highlighting mode", "0 is no highlighting\n1 is passive\n2 is when the same key as bulk select is pressed\n3 is when control key pressed\n4 is when shift key is pressed.",
			tostring(mode), function(str) RunConsoleCommand("pac_bulk_select_halo_mode", str) end)
		end):SetImage(pace.MiscIcons.info)
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
		local subsume_pnl = bulk_menu:AddCVar("bulk select subsume", "pac_bulk_select_subsume", "1", "0")
		subsume_pnl:SetTooltip("Whether bulk select should take the hierarchy into account, deselecting children when selecting a part.\nEnable this if you commonly do broad operations like copying, deleting or moving parts.\nDisable this for targeted operations like property editing on nested model structures, for example.")
		bulk_menu:AddCVar("draw bulk select info next to cursor", "pac_bulk_select_cursor_info", "1", "0")
		local deselect_pnl = bulk_menu:AddCVar("bulk select deselect", "pac_bulk_select_deselect", "1", "0")
		deselect_pnl:SetTooltip("Deselect all bulk selects if you select a part without holding bulk select key")

		local resetting_mode, resetpnl = bulk_menu:AddSubMenu("Clear selection after operation?") resetpnl:SetImage("icon16/table_delete.png")
		local resetting_mode1 = resetting_mode:AddOption("Yes") resetting_mode1:SetIsCheckable(true) resetting_mode1:SetRadio(true)
		local resetting_mode2 = resetting_mode:AddOption("No") resetting_mode2:SetIsCheckable(true) resetting_mode2:SetRadio(true)
		if pace.BulkSelect_clear_after_operation == nil then pace.BulkSelect_clear_after_operation = true end

		function resetting_mode1.OnChecked(b)
			pace.BulkSelect_clear_after_operation = true
		end
		function resetting_mode2.OnChecked(b)
			pace.BulkSelect_clear_after_operation = false
		end
		if pace.BulkSelect_clear_after_operation then resetting_mode1:SetChecked(true) else resetting_mode2:SetChecked(true) end

		bulk_menu:AddOption(L"Insert (Move / Cut + Paste)", function()
			pace.BulkCutPaste(obj)
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage("icon16/arrow_join.png")

		if not pace.ordered_operation_readystate then
			bulk_menu:AddOption(L"prepare Ordered Insert (please select parts in order beforehand)", function()
				pace.BulkCutPasteOrdered()
				if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
			end):SetImage("icon16/text_list_numbers.png")
		else
			bulk_menu:AddOption(L"do Ordered Insert (select destinations in order)", function()
				pace.BulkCutPasteOrdered()
				if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
			end):SetImage("icon16/arrow_switch.png")
		end


		bulk_menu:AddOption(L"Copy to Bulk Clipboard", function()
			pace.BulkCopy(obj)
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage(pace.MiscIcons.copy)

		bulk_menu:AddSpacer()

		--bulk paste modes
		bulk_menu:AddOption(L"Bulk Paste (bulk select -> into this part)", function()
			pace.BulkPasteFromBulkSelectToSinglePart(obj)
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage("icon16/arrow_join.png")

		bulk_menu:AddOption(L"Bulk Paste (clipboard or this part -> into bulk selection)", function()
			if not pace.Clipboard then pace.Copy(obj) end
			pace.BulkPasteFromSingleClipboard()
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage("icon16/arrow_divide.png")

		bulk_menu:AddOption(L"Bulk Paste (Single paste from bulk clipboard -> into this part)", function()
			pace.BulkPasteFromBulkClipboard(obj)
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage("icon16/arrow_join.png")

		bulk_menu:AddOption(L"Bulk Paste (Multi-paste from bulk clipboard -> into bulk selection)", function()
			pace.BulkPasteFromBulkClipboardToBulkSelect()
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage("icon16/arrow_divide.png")

		bulk_menu:AddSpacer()

		bulk_menu:AddOption(L"Bulk paste properties from selected part", function()
			pace.Copy(obj)
			for _,v in ipairs(pace.BulkSelectList) do
				pace.PasteProperties(v)
			end
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage(pace.MiscIcons.replace)

		bulk_menu:AddOption(L"Bulk paste properties from clipboard", function()
			for _,v in ipairs(pace.BulkSelectList) do
				pace.PasteProperties(v)
			end
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage(pace.MiscIcons.replace)

		bulk_menu:AddOption(L"Deploy a numbered command event series ("..#pace.BulkSelectList..")", function()
			Derma_StringRequest(L"command series", L"input the base name", "", function(str)
				str = string.gsub(str, " ", "")
				for i,v in ipairs(pace.BulkSelectList) do
					part = pac.CreatePart("event")
					part:SetOperator("equal")
					part:SetParent(v)
					part.Event = "command"
					part.Arguments = str..i.."@@0@@0"
				end
				if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
			end)
		end):SetImage("icon16/clock.png")

		bulk_menu:AddOption(L"Pack into a new group", function()
			local root = pac.CreatePart("group")
			root:SetParent(obj:GetParent())
			for i,v in ipairs(pace.BulkSelectList) do
				v:SetParent(root)
			end
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage("icon16/world.png")
		bulk_menu:AddOption(L"Pack into a new root group", function()
			local root = pac.CreatePart("group")
			for i,v in ipairs(pace.BulkSelectList) do
				v:SetParent(root)
			end
			if pace.BulkSelect_clear_after_operation then pace.ClearBulkList() end
		end):SetImage("icon16/world.png")

		bulk_menu:AddSpacer()

		bulk_menu:AddOption(L"Morph properties over bulk select", function()
			pace.BulkMorphProperty()
		end):SetImage("icon16/chart_line_edit.png")

		bulk_menu:AddOption(L"bulk change properties", function() pace.BulkApplyProperties(obj, "harsh") end):SetImage("icon16/application_form.png")

		local arraying_menu, pnl = bulk_menu:AddSubMenu(L"arraying menu", function() pace.OpenArrayingMenu(obj) end) pnl:SetImage("icon16/table_multiple.png")
		if obj and obj.GetWorldPosition then
			local icon = obj.pace_tree_node.ModelPath or obj.Icon
			if string.sub(icon,-3) == "mdl" then icon = "materials/spawnicons/"..string.gsub(icon, ".mdl", "")..".png" end
			arraying_menu:AddOption(L"base:" .. tostring(obj), function() pace.OpenArrayingMenu(obj) end):SetImage(icon)
		end
		if obj and obj.Parent.GetWorldPosition then
			local icon = obj.pace_tree_node.ModelPath or obj.Icon
			if string.sub(icon,-3) == "mdl" then icon = "materials/spawnicons/"..string.gsub(icon, ".mdl", "")..".png" end
			arraying_menu:AddOption(L"base:" .. tostring(obj.Parent), function() pace.OpenArrayingMenu(obj.Parent) end):SetImage(icon)
		end

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
		local pnl = menu:AddOption(L"View specific help or info about this part", function()
			pac.AttachInfoPopupToPart(obj, nil, {
				obj_type = GetConVar("pac_popups_preferred_location"):GetString(),
				hoverfunc = "open",
				pac_part = pace.current_part,
				panel_exp_width = 900, panel_exp_height = 400
			})
		end) pnl:SetImage("icon16/information.png") pnl:SetTooltip("for some classes it'll be the same as hitting F1, giving you the basic class tutorial, but for proxies and events they will be more specific")
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
	elseif option_name == "view_lockon" then
		if not obj then return end
		local function add_entity_version(obj, root_owner)
			local root_owner = obj:GetRootPart():GetOwner()
			local lockons, pnl2 = menu:AddSubMenu("lock on to " .. tostring(root_owner))
				local function viewlock(mode)
					if mode ~= "toggle" then
						pace.viewlock_mode = mode
					else
						if pace.viewlock then
							if pace.viewlock ~= root_owner then
								pace.viewlock = root_owner
								return
							end
							pace.viewlock = nil
							return
						end
						pace.viewlock = root_owner
					end
					if mode == "disable" then
						pace.ViewAngles.r = 0
						pace.viewlock = nil
						return
					end
					pace.viewlock_distance = pace.ViewPos:Distance(root_owner:GetPos() + root_owner:OBBCenter())
					pace.viewlock = root_owner
				end
				lockons:AddOption("direct", function() viewlock("direct") end):SetImage("icon16/arrow_right.png")
				lockons:AddOption("free pitch", function() viewlock("free pitch") end):SetImage("icon16/arrow_refresh.png")
				lockons:AddOption("zero pitch", function() viewlock("zero pitch") end):SetImage("icon16/arrow_turn_right.png")
				lockons:AddOption("disable", function() viewlock("disable") end):SetImage("icon16/cancel.png")
			pnl2:SetImage("icon16/zoom.png")
		end
		local function add_part_version(obj)
			local lockons, pnl2 = menu:AddSubMenu("lock on to " .. tostring(obj))
				local function viewlock(mode)
					if mode ~= "toggle" then
						pace.viewlock_mode = mode
					else
						if pace.viewlock then
							if pace.viewlock ~= obj then
								pace.viewlock = obj
								return
							end
							pace.viewlock = nil
							return
						end
						pace.viewlock = obj
					end
					if mode == "disable" then
						pace.ViewAngles.r = 0
						pace.viewlock = nil
						return
					end
					pace.viewlock_distance = pace.ViewPos:Distance(obj:GetWorldPosition())
					pace.viewlock = obj
				end
				lockons:AddOption("direct", function() viewlock("direct") end):SetImage("icon16/arrow_right.png")
				lockons:AddOption("free pitch", function() viewlock("free pitch") end):SetImage("icon16/arrow_refresh.png")
				lockons:AddOption("zero pitch", function() viewlock("zero pitch") end):SetImage("icon16/arrow_turn_right.png")
				lockons:AddOption("frame of reference (x)", function() pace.viewlock_axis = "x" viewlock("frame of reference") end):SetImage("icon16/arrow_branch.png")
				lockons:AddOption("frame of reference (y)", function() pace.viewlock_axis = "y" viewlock("frame of reference") end):SetImage("icon16/arrow_branch.png")
				lockons:AddOption("frame of reference (z)", function() pace.viewlock_axis = "z" viewlock("frame of reference") end):SetImage("icon16/arrow_branch.png")
				lockons:AddOption("disable", function() viewlock("disable") end):SetImage("icon16/cancel.png")
				pnl2:SetImage("icon16/zoom.png")
		end
		local is_root_entity = obj:GetOwner() == obj:GetRootPart():GetOwner()
		if obj.ClassName == "group" then
			if is_root_entity then
				add_entity_version(obj, obj:GetRootPart():GetOwner())
			elseif obj:GetOwner().GetWorldPosition then
				add_part_version(obj:GetOwner())
			end
		elseif obj.GetWorldPosition then
			add_part_version(obj)
		end
	elseif option_name == "view_goto" then
		if not obj then return end
		local is_root_entity = obj:GetOwner() == obj:GetRootPart():GetOwner()
		if obj.ClassName == "group" then
			if is_root_entity then
				local gotos, pnl2 = menu:AddSubMenu("go to")
				pnl2:SetImage("icon16/arrow_turn_right.png")
				local axes = {"x","y","z","world_x","world_y","world_z"}
				for _,ax in ipairs(axes) do
					gotos:AddOption("+" .. ax, function()
						pace.GoTo(obj:GetRootPart():GetOwner(), "view", {radius = 50, axis = ax})
					end):SetImage("icon16/arrow_turn_right.png")
					gotos:AddOption("-" .. ax, function()
						pace.GoTo(obj:GetRootPart():GetOwner(), "view", {radius = -50, axis = ax})
					end):SetImage("icon16/arrow_turn_right.png")
				end
			elseif obj:GetOwner().GetWorldPosition then
				local gotos, pnl2 = menu:AddSubMenu("go to")
				pnl2:SetImage("icon16/arrow_turn_right.png")
				local axes = {"x","y","z","world_x","world_y","world_z"}
				for _,ax in ipairs(axes) do
					gotos:AddOption("+" .. ax, function()
						pace.GoTo(obj, "view", {radius = 50, axis = ax})
					end):SetImage("icon16/arrow_turn_right.png")
					gotos:AddOption("-" .. ax, function()
						pace.GoTo(obj, "view", {radius = -50, axis = ax})
					end):SetImage("icon16/arrow_turn_right.png")
				end
			end
		elseif obj.GetWorldPosition then
			local gotos, pnl2 = menu:AddSubMenu("go to")
			pnl2:SetImage("icon16/arrow_turn_right.png")
			local axes = {"x","y","z","world_x","world_y","world_z"}
			for _,ax in ipairs(axes) do
				gotos:AddOption("+" .. ax, function()
					pace.GoTo(obj, "view", {radius = 50, axis = ax})
				end):SetImage("icon16/arrow_turn_right.png")
				gotos:AddOption("-" .. ax, function()
					pace.GoTo(obj, "view", {radius = -50, axis = ax})
				end):SetImage("icon16/arrow_turn_right.png")
			end
		end

	end

end

--destructive tool
function pace.UltraCleanup(obj)
	if not obj then return end

	local root = obj
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

--match parts then replace properties or do other stuff like deleting
function pace.ProcessPartsByCriteria(raw_args)

	local match_criteria_tbl = {}
	local process_actions = {}
	local function match_criteria(part)
		for i,v in ipairs(match_criteria_tbl) do
			if v[2] == "=" then
				if part[v[1]] ~= v[3] then
					return false
				end
			elseif v[2] == ">" then
				if part[v[1]] <= v[3] then
					return false
				end
			elseif v[2] == ">=" then
				if part[v[1]] < v[3] then
					return false
				end
			elseif v[2] == "<" then
				if part[v[1]] >= v[3] then
					return false
				end
			elseif v[2] == "<=" then
				if part[v[1]] > v[3] then
					return false
				end
			else --bad operator
				return false
			end
		end
		return true
	end
	local function process(part)
		print(part, "ready for processing")
		for i,v in ipairs(process_actions) do
			local action = v[1]
			local key = v[2]
			local value = v[3]
			if action == "DELETE" then part:Remove() return end
			if action == "REPLACE" then
				if part["Set"..key] then
					local type = type(part["Get"..key](part))
					if type == "string" then
						part["Set"..key](part,value)
					elseif type == "Vector" then
						local tbl = string.Split(value, " ")
						if tbl[3] then
							local vec = Vector(tonumber(tbl[1]),tonumber(tbl[2]),tonumber(tbl[3]))
							part["Set"..key](part,vec)
						end
					elseif type == "Angle" then
						local tbl = string.Split(value, " ")
						if tbl[3] then
							local ang = Angle(tonumber(tbl[1]),tonumber(tbl[2]),tonumber(tbl[3]))
							part["Set"..key](part,ang)
						end
					elseif type == "number" then
						part["Set"..key](part,tonumber(value))
					elseif type == "boolean" then
						part["Set"..key](part,tobool(value))
					end
				end
			end
		end
	end

	if isstring(raw_args) then
		local reading_criteria = false
		local reading_processing = false
		local process
		for i,line in ipairs(string.Split(raw_args, "\n")) do
			local line_tbl = string.Split(line, "=")
			if string.sub(line,1,8) == "CRITERIA" then
				reading_criteria = true
			elseif string.sub(line, 1,7) == "REPLACE" then
				process = "REPLACE"
				reading_criteria = false
				reading_processing = true
			elseif string.sub(line, 1,6) == "DELETE" then
				process = "DELETE"
				reading_criteria = false
				reading_processing = true
			elseif line ~= "" then
				if reading_criteria then
					table.insert(match_criteria_tbl, {line_tbl[1], "=", line_tbl[2]})
				elseif reading_processing then
					if process ~= nil then
						table.insert(process_actions, {process, line_tbl[1], line_tbl[2] or ""})
					end
				end
			end
		end
	elseif istable(raw_args) then
		match_criteria_tbl = raw_args[1]
		process_actions = raw_args[2]
	else
		return
	end
	pac.Message("PROCESS BY CRITERIA")
	pac.Message("====================CRITERIA====================")
	PrintTable(match_criteria_tbl)
	print("\n")
	pac.Message("====================PROCESSING====================")
	PrintTable(process_actions)
	pace.processing = true
	for _,part in pairs(pac.GetLocalParts()) do
		if match_criteria(part) then
			process(part)
		end
	end
	pace.processing = false
end

function pace.PromptProcessPartsByCriteria(part)
	local default_args = ""
	local default_class = ""
	if part then
		default_class = part.ClassName
		if part.ClassName == "event" then
			default_args = default_args .. "CRITERIA"
			default_args = default_args .. "\nClassName=event"
			default_args = default_args .. "\nArguments="..part:GetArguments()
			default_args = default_args .. "\nEvent="..part:GetEvent()
			default_args = default_args .. "\n\nREPLACE"
			default_args = default_args .. "\nEvent="
			default_args = default_args .. "\nArguments="
		else
			default_args = default_args .. "CRITERIA"
			default_args = default_args .. "\nClassName=" .. default_class
			default_args = default_args .. "\nKey=Value"
			default_args = default_args .. "\n\nREPLACE"
			default_args = default_args .. "\nKey=NewValue"
		end
	else
		default_args = default_args .. "CRITERIA"
		default_args = default_args .. "\nClassName=class"
		default_args = default_args .. "\nKey=Value"
		default_args = default_args .. "\n\nREPLACE"
		default_args = default_args .. "\nKey=NewValue"
	end
	pace.MultilineStringRequest("Process by criteria", "enter arguments", default_args, function(str) pace.ProcessPartsByCriteria(str) end)
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

pace.arraying = false
local last_clone = nil
local axis_choice = "x"
local axis_choice_id = 1
local mode_choice = "Circle"
local subdivisions = 1
local length = 50
local height = 50
local offset = 0
local save_settings = false
local angle_follow = false

function pace.OpenArrayingMenu(obj)
	local locked_matrix_part = obj or pace.current_part
	if locked_matrix_part.GetWorldPosition == nil then pace.FlashNotification("Please select a movable part before using the arraying menu") return end

	local pos, ang = pace.mctrl.GetWorldPosition()
	local mctrl = pos:ToScreen()
	mctrl.x = mctrl.x + 100

	local main_panel = vgui.Create("DFrame") main_panel:SetSize(600,400) main_panel:SetPos(mctrl.x + 100, mctrl.y - 200) main_panel:SetSizable(true)

	main_panel:SetTitle("Arraying Menu - Please select an arrayed part contained inside " .. tostring(locked_matrix_part))
	local properties_pnl = pace.CreatePanel("properties", main_panel) properties_pnl:SetSize(580,360) properties_pnl:SetPos(10,30)

	properties_pnl:AddCollapser("Parts")
		local matrix_part_selector = pace.CreatePanel("properties_part")
			matrix_part_selector.part = locked_matrix_part
			properties_pnl:AddKeyValue("Matrix",matrix_part_selector)
			matrix_part_selector:SetValue(locked_matrix_part.UniqueID)
			matrix_part_selector:PostInit()
		local arraying_part_selector = pace.CreatePanel("properties_part")
			properties_pnl:AddKeyValue("ArrayedPart",arraying_part_selector)
			arraying_part_selector:PostInit()

	properties_pnl:AddCollapser("Dimensions")
		local height_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("Height",height_slider)
		local length_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("Length",length_slider)
		local array_modes = vgui.Create("DComboBox")
			array_modes:AddChoice("Circle", "Circle", true, "icon16/cd.png")
			array_modes:AddChoice("Rectangle", "Rectangle", false, "icon16/collision_on.png")
			array_modes:AddChoice("Line", "Line", false, "icon16/chart_line.png")
			properties_pnl:AddKeyValue("Mode",array_modes)
			function array_modes:OnSelect(index, val, data) mode_choice = data end
		local axes = vgui.Create("DComboBox")
			axes:AddChoice("x", "x", true)
			axes:AddChoice("y", "y", false)
			axes:AddChoice("z", "z", false)
			properties_pnl:AddKeyValue("Axis",axes)
			function axes:OnSelect(index, val, data) axis_choice = data axis_choice_id = index end

	properties_pnl:AddCollapser("Utilities")
		local subdivs_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("Count",subdivs_slider)
		local offset_slider = pace.CreatePanel("properties_number")
			properties_pnl:AddKeyValue("Offset",offset_slider)
		local anglefollow = pace.CreatePanel("properties_boolean")
			properties_pnl:AddKeyValue("AlignToShape",anglefollow)
			anglefollow:SetTooltip("Sets the Angles field in accordance to the shape. If you want to offset from that, use AngleOffset")
			anglefollow:SetValue(false)
		local savesettings = pace.CreatePanel("properties_boolean")
			properties_pnl:AddKeyValue("SaveSettings",savesettings)
			savesettings:SetTooltip("Preserves your settings if you close the window")
			function savesettings.chck:OnChange(b) save_settings = b end
			savesettings:SetValue(save_settings)
		local force_update = vgui.Create("DButton")
			force_update:SetText("Refresh")
			force_update:SetTooltip("Updates clones (paste properties from the first part)")
			properties_pnl:AddKeyValue("ForceUpdate",force_update)

	if save_settings then
		axes:ChooseOption(axis_choice, axis_choice_id)
		anglefollow:SetValue(angle_follow)
		subdivs_slider:SetValue(subdivisions)
		offset_slider:SetValue(offset)
		length_slider:SetValue(length)
		height_slider:SetValue(height)
		if last_clone then
			arraying_part_selector:SetValue(last_clone.UniqueID)
			arraying_part_selector:PostInit()
		end
	else
		axes:ChooseOption("x",1)
		anglefollow:SetValue(false)
		subdivs_slider:SetValue(1)
		offset_slider:SetValue(0)
		length_slider:SetValue(50)
		height_slider:SetValue(50)
	end

	local clone_positions = {}
	local clones = {}
	do
		local toremove = {}
		for i,v in ipairs(locked_matrix_part:GetChildren()) do
			if v.Notes == "original array instance" then
				last_clone = v
			elseif v.Notes == "arrayed copy" then
				table.insert(toremove, v)
			end
		end
		if last_clone and save_settings then
			arraying_part_selector:SetValue(last_clone.UniqueID)
		end
		for i,v in ipairs(toremove) do v:Remove() end
	end

	local clone_original = last_clone or arraying_part_selector.part

	function main_panel:OnClose() pac.RemoveHook("PostDrawTranslucentRenderables", "ArrayingVisualize") pace.arraying = false end

	local function get_basis(axis)

	end

	local function get_shape_angle(tbl, i)
		if mode_choice == "Circle" then
			return tbl.basis_angle * (tbl.index - 1) + tbl.offset_angle
		elseif mode_choice == "Rectangle" then
			return tbl.basis_angle
		elseif mode_choice == "Line" then
			if axis_choice == "x" then
				if length >= 0 then return Angle(0,0,0) else return Angle(180,0,0) end
			elseif axis_choice == "y" then
				if length >= 0 then return tbl.basis_angle else return -tbl.basis_angle end
			elseif axis_choice == "z" then
				if length >= 0 then return tbl.basis_angle else return -tbl.basis_angle end
			end
		end
	end

	local function update_clones(recreate_parts)
		for i,v in pairs(clones) do
			if i > #clone_positions then
				v:Remove()
				clones[i] = nil
			end
		end

		if arraying_part_selector:GetValue() == "" then print("empty boys") return end
		clone_original = arraying_part_selector.part --pac.GetPartFromUniqueID(pac.Hash(LocalPlayer()), :DecodeEdit(arraying_part_selector:GetValue()))
		last_clone = clone_original
		local warning = false
		if not clone_original then return end

		if clone_original:HasChild(locked_matrix_part) or clone_original == locked_matrix_part then --avoid bad case of recursion
			warning = true
		end
		for i,v in ipairs(clone_positions) do
			if i ~= 1 then
				local clone = clones[i]
				if not clone then
					--if recreate_parts and not warning then
						clone = clone_original:Clone()
						clone.Notes = "arrayed copy"
						local name = "" .. i
						if math.floor(math.log10(i)) == 0 then
							name = "00" .. name
						elseif math.floor(math.log10(i)) == 1  then
							name = "0" .. name
						end
						clone.Name = "[" .. name .. "]"
						clones[i] = clone
					--end
				end
				clone:SetPosition(v.vec)
				if anglefollow.chck:GetChecked() then
					clone:SetAngleOffset(clone_original:GetAngleOffset())
					clone:SetAngles(get_shape_angle(v, i-1))
					--clone:SetAngles((i-1) * v.basis_angle + v.offset_angle)
				end
			else
				if string.sub(clone_original:GetName(),1,5) ~= "[001]" then clone_original:SetName("[001]" .. clone_original:GetName()) end
				clone_original:SetPosition(v.vec)
				if anglefollow.chck:GetChecked() then

					clone_original:SetAngles(get_shape_angle(v, i))
				end
			end
		end
	end

	--that's a nice preview but what about local positions
	local last_offset = 0
	local function draw_circle(pos, basis_normal, basis_x, basis_y, length, height, subdivs)
		--[[render.DrawLine(pos, pos + 50*basis_normal, Color(255,255,255), false)
		render.DrawLine(pos, pos + 50*basis_x, Color(255,0,0), false)
		render.DrawLine(pos, pos + 50*basis_y, Color(0,255,0), false)]]
		clone_positions = {}
		local radiansubdiv = 2*math.pi / subdivs
		for i=0,subdivs,1 do
			local pos1 = pos + math.sin(i*radiansubdiv)*basis_y*height + math.cos(i*radiansubdiv)*basis_x*length
			local pos2 = pos + math.sin((i+1)*radiansubdiv)*basis_y*height + math.cos((i+1)*radiansubdiv)*basis_x*length
			render.DrawLine(pos1,pos2,Color(255,255,200 + 50*math.sin(CurTime()*10)),true)
		end
		radiansubdiv = 2*math.pi / (subdivisions)
		local matrix_pos, matrix_ang = locked_matrix_part:GetDrawPosition()
		matrix_ang = matrix_ang -- locked_matrix_part.Angles
		render.DrawLine(matrix_pos, matrix_pos + 50*matrix_ang:Forward(), Color(255,0,0), false)
		render.DrawLine(matrix_pos, matrix_pos + 50*matrix_ang:Right(), Color(0,255,0), false)
		for i=0,subdivisions,1 do
			local degrees = offset + 360*i*radiansubdiv/(math.pi * 2)
			local degrees2 = offset + 360*(i+1)*radiansubdiv/(math.pi * 2)
			local radians = (degrees/360)*math.pi*2
			local radians2 = (degrees2/360)*math.pi*2
			if i == subdivisions then break end --don't make overlapping one
			local ellipse_x = math.cos(radians)*length
			local ellipse_y = math.sin(radians)*height
			local pos1 = pos + math.sin(radians)*basis_y*height + math.cos(radians)*basis_x*length
			local pos2 = pos + math.sin(radians2)*basis_y*height + math.cos(radians2)*basis_x*length

			local the_original = false
			if i == 0 then the_original = true end

			local localpos, localang = WorldToLocal( pos1, ang, pos, matrix_ang )

			local basis_angle = Angle()
			local offset_angle = Angle()
			if axis_choice == "y" then
				basis_angle = Angle(-1,0,0) * (360 / subdivisions)
				offset_angle = Angle(-offset,0,0)
			elseif axis_choice == "z" then
				basis_angle = Angle(0,-1,0) * (360 / subdivisions)
				offset_angle = Angle(0,-offset,0)
			elseif axis_choice == "x" then
				basis_angle = Angle(0,0,1) * (360 / subdivisions)
				offset_angle = Angle(0,0,offset)
			end
			table.insert(clone_positions, i+1, {wpos = pos1, wang = ang, vec = localpos, ang = localang, basis_angle = basis_angle, offset_angle = offset_angle, is_the_original = the_original, index = i+1, x = ellipse_x, y = ellipse_y, degrees = degrees})
		end
		if last_offset ~= offset_slider:GetValue() then last_offset = offset_slider:GetValue() update_clones() end
	end
	local function draw_rectangle(pos, basis_normal, basis_x, basis_y, length, height)
		render.DrawLine(pos, pos + 50*basis_normal, Color(255,255,255), false)
		render.DrawLine(pos, pos + 50*basis_x, Color(255,0,0), false)
		render.DrawLine(pos, pos + 50*basis_y, Color(0,255,0), false)
		clone_positions = {}

		local x = basis_x*length
		local y = basis_y*height
		render.DrawLine(pos + x - y,pos + x + y,Color(255,255,200 + 50*math.sin(CurTime()*10)),true)
		render.DrawLine(pos + x + y,pos - x + y,Color(255,255,200 + 50*math.sin(CurTime()*10)),true)
		render.DrawLine(pos - x + y,pos - x - y,Color(255,255,200 + 50*math.sin(CurTime()*10)),true)
		render.DrawLine(pos - x - y,pos + x - y,Color(255,255,200 + 50*math.sin(CurTime()*10)),true)

		local matrix_pos, matrix_ang = locked_matrix_part:GetBonePosition()
		for i=0,subdivisions,1 do
			local frac = (offset/360 + (i-1)/subdivisions) % 1
			local x
			local y
			local basis_ang_value = 0

			if (frac >= 0.875) or (frac < 0.125) then --right side
				x = basis_x*length
				basis_ang_value = 0
				if frac >= 0.875 then
					y = 8*(frac-1)*basis_y*height
				elseif frac < 0.125 then
					y = 8*frac*basis_y*height
				end
			elseif (frac >= 0.125) and (frac < 0.375) then --up side
				y = basis_y*height
				basis_ang_value = 90
				if frac < 0.25 then
					x = 8*(-frac+0.25)*basis_x*length
				elseif frac >= 0.25 then
					x = 8*(-frac+0.25)*basis_x*length
				end
			elseif (frac >= 0.375) and (frac < 0.625) then --left side
				x = -basis_x*length
				basis_ang_value = 180
				if frac < 0.5 then
					y = 8*(-frac+0.5)*basis_y*height
				elseif frac >= 0.5 then
					y = 8*(-frac+0.5)*basis_y*height
				end
			elseif frac >= 0.625 then --down side
				y = -basis_y*height
				basis_ang_value = -90
				if frac < 0.75 then
					x = 8*(frac-0.75)*basis_x*length
				elseif frac >= 0.75 then
					x = 8*(frac-0.75)*basis_x*length
				end
			end
			if i == subdivisions then break end --don't make overlapping one
			local pos1 = pos + x + y

			local the_original = false
			if i == 0 then the_original = true end

			local localpos, localang = WorldToLocal( pos1, matrix_ang, pos, ang )

			local basis_angle = Angle()
			local offset_angle = Angle()
			if axis_choice == "x" then
				basis_angle = Angle(0,0,1)*basis_ang_value
				offset_angle = Angle(0,0,0)
			elseif axis_choice == "y" then
				basis_angle = Angle(-1,0,0)*basis_ang_value
				offset_angle = Angle(0,0,0)
			elseif axis_choice == "z" then
				basis_angle = Angle(0,1,0)*basis_ang_value
				offset_angle = Angle(0,0,0)
			end
			table.insert(clone_positions, i+1, {frac = frac, wpos = pos1, wang = ang, vec = localpos, ang = localang, basis_angle = basis_angle, offset_angle = offset_angle, is_the_original = the_original, index = i+1})

		end
		if last_offset ~= offset_slider:GetValue() then last_offset = offset_slider:GetValue() update_clones() end
	end
	local function draw_line(pos, basis_normal, length)
		clone_positions = {}

		render.DrawLine(pos, pos + basis_normal*length,Color(255,255,200 + 50*math.sin(CurTime()*10)),true)

		for i=0,subdivisions,1 do
			local forward = offset + (length*i)/subdivisions
			local pos1 = pos + forward*basis_normal

			local the_original = false
			if i == 0 then the_original = true end

			local localpos
			local localang = Angle(0,0,0)
			local basis_angle = Angle(0,0,0)
			local offset_angle = Angle(0,0,0)
			if axis_choice == "x" then
				localpos = Vector(1,0,0)*forward
				basis_angle = Angle(0,0,0)
			elseif axis_choice == "y" then
				localpos = Vector(0,1,0)*forward
				basis_angle = Angle(0,90,0)
			elseif axis_choice == "z" then
				localpos = Vector(0,0,1)*forward
				basis_angle = Angle(-90,0,0)
			end


			table.insert(clone_positions, i+1, {wpos = pos1, wang = ang, vec = localpos, ang = localang, basis_angle = basis_angle, offset_angle = offset_angle, is_the_original = the_original, index = i+1})
		end
		if last_offset ~= offset_slider:GetValue() then last_offset = offset_slider:GetValue() update_clones() end
	end

	--oof this one's gonna be rough how do we even do this
	local function draw_clones()
		update_clones(false)
		for i,v in pairs(clone_positions) do
			render.DrawLine(v.wpos, v.wpos + 10*v.wang:Forward(),Color(255,0,0),true)
			render.DrawLine(v.wpos, v.wpos - 10*v.wang:Right(),Color(0,255,0),true)
			render.DrawLine(v.wpos, v.wpos + 10*v.wang:Up(),Color(0,0,255),true)
			if length < 10 or height < 10 then return end
			if i == 1 then
				render.SetMaterial(Material("sprites/grip_hover.vmt")) render.DrawSprite( v.wpos, 5, 5, Color( 255, 255, 255) )
			else
				render.SetMaterial(Material("sprites/grip.vmt")) render.DrawSprite( v.wpos, 3, 3, Color( 255, 255, 255) )
			end
		end
	end

	function subdivs_slider.OnValueChanged(val)
		subdivisions = math.floor(val)
		update_clones(true)
		subdivs_slider:SetValue(math.floor(val))
	end
	function anglefollow.OnValueChanged(b)
		angle_follow = b
		anglefollow:SetValue(b)
	end
	function length_slider.OnValueChanged(val)
		length = val
		length_slider:SetValue(val)
	end
	function height_slider.OnValueChanged(val)
		height = val
		height_slider:SetValue(val)
	end
	function offset_slider.OnValueChanged(val)
		offset = val
		offset_slider:SetValue(val)
	end
	function force_update.DoClick()
		local skip_properties = {
			["Position"] = true,
			["Angles"] = true,
			["Name"] = true,
			["Notes"] = true,
		}
		local originalpart = arraying_part_selector.part
		local properties = originalpart:GetProperties()
		for i,tbl in ipairs(properties) do
			if skip_properties[tbl.key] then continue end
			local val = originalpart["Get"..tbl.key](originalpart)
			for _,part in pairs(clones) do
				part["Set"..tbl.key](part, val)
			end
		end

	end

	if pace.arraying then pac.RemoveHook("PostDrawTranslucentRenderables", "ArrayingVisualize") pace.arraying = false return end

	timer.Simple(0.3, function()
		pac.AddHook("PostDrawTranslucentRenderables", "ArrayingVisualize", function()
			matrix_part_selector.part = pac.GetPartFromUniqueID(pac.Hash(LocalPlayer()), matrix_part_selector:DecodeEdit(matrix_part_selector:GetValue()))
			locked_matrix_part = matrix_part_selector.part
			pace.mctrl.SetTarget(locked_matrix_part)
			if arraying_part_selector:GetValue() then
				if arraying_part_selector:GetValue() ~= locked_matrix_part.UniqueID then
					arraying_part_selector.part = pac.GetPartFromUniqueID(pac.Hash(LocalPlayer()), arraying_part_selector:GetValue())
					arraying_part_selector:SetValue(arraying_part_selector.part.UniqueID)
				end
			elseif pace.current_part ~= locked_matrix_part or ((arraying_part_selector.part ~= nil) and (arraying_part_selector.part ~= locked_matrix_part)) then
				arraying_part_selector.part = pace.current_part
				arraying_part_selector:SetValue(arraying_part_selector.part.UniqueID)
			end

			subdivisions = subdivs_slider:GetValue()
			length = length_slider:GetValue()
			height = height_slider:GetValue()
			offset = offset_slider:GetValue()

			--it's possible the part gets deleted
			if not locked_matrix_part.GetDrawPosition then main_panel:Remove() pac.RemoveHook("PostDrawTranslucentRenderables", "ArrayingVisualize") return end
			local pos, ang = locked_matrix_part:GetDrawPosition()
			if not pos or not ang then return end
			local forward, right, up = pace.mctrl.GetAxes(ang)

			local basis_x, basis_y, basis_normal
			if axis_choice == "x" then
				basis_x = right
				basis_y = up
				basis_normal = forward
			elseif axis_choice == "y" then
				basis_x = forward
				basis_y = up
				basis_normal = right
			elseif axis_choice == "z" then
				basis_x = right
				basis_y = forward
				basis_normal = up
			else
				basis_x, basis_y, basis_normal = pace.mctrl.GetAxes(ang)
			end

			if not locked_matrix_part.GetWorldPosition then print("early exit 3") return end
			if mode_choice == "Circle" then
				draw_circle(pos, basis_normal, basis_x, basis_y, length_slider:GetValue(), height_slider:GetValue(), 40)
			elseif mode_choice == "Rectangle" then
				draw_rectangle(pos, basis_normal, basis_x, basis_y, length_slider:GetValue(), height_slider:GetValue())
			elseif mode_choice == "Line" then
				draw_line(pos, basis_normal, length_slider:GetValue())
			end
			draw_clones()
		end)
	end)

	pace.arraying = true


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

local bsel_main_icon = Material("icon16/table_multiple.png")
local bsel_clipboard_icon = Material("icon16/page_white_text.png")
local white = Color(255,255,255)

pac.AddHook("DrawOverlay", "bulkselect_cursor_info", function()
	if not bulkselect_cursortext:GetBool() then return end
	if not pace then return end
	if not pace.IsFocused() then return end
	local mx, my = input.GetCursorPos()

	surface.SetFont("BudgetLabel")
	surface.SetMaterial(Material("icon16/table_multiple.png"))
	surface.SetTextColor(white)
	surface.SetDrawColor(white)
	local base_y = my + 8

	if pace.BulkSelectList then
		if #pace.BulkSelectList > 0 then
			surface.DrawTexturedRect(mx + 10, base_y, 16, 16)
			surface.SetTextPos(mx + 12 + 16, base_y)
			surface.DrawText("bulk select [" .. #pace.BulkSelectList .."]")
			base_y = base_y + 16
		end
	end
	if pace.BulkSelectClipboard then
		if #pace.BulkSelectClipboard > 0 then
			surface.SetMaterial(Material("icon16/page_white_text.png"))
			surface.DrawTexturedRect(mx + 10, base_y, 16, 16)
			surface.SetTextPos(mx + 12 + 16, base_y)
			surface.DrawText("bulk clipboard [" .. #pace.BulkSelectClipboard .."]")
		end
	end
end)