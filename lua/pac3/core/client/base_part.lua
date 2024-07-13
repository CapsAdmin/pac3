local pac = pac
local pace = pace

local debug_traceback = debug.traceback
local string_format = string.format
local math_random = math.random
local table_insert = table.insert
local table_copy = table.Copy
local tostring = tostring
local assert = assert
local xpcall = xpcall
local pairs = pairs
local ipairs = ipairs
local table = table
local Color = Color
local NULL = NULL

local classname_event = "event"
local prefix_get = "Get"
local prefix_set = "Set"

local pac_editor_scale = GetConVar("pac_editor_scale")
local pac_popups_preferred_location = GetConVar("pac_popups_preferred_location")

local BUILDER, PART = pac.PartTemplate()

PART.ClassName = "base"
PART.BaseName = PART.ClassName

function PART:__tostring()
	return string_format("part[%s][%s][%i]", self.ClassName, self:GetName(), self.Id)
end

BUILDER
	:GetSet("PlayerOwner", NULL)
	:GetSet("Owner", NULL)
	:GetSet("Enabled", true)

BUILDER
	:StartStorableVars()
		:SetPropertyGroup("generic")
			:GetSet("Name", "")
			:GetSet("Notes", "")
			:GetSet("Hide", false)
			:GetSet("EditorExpand", false, {hidden = true})
			:GetSet("UniqueID", "", {hidden = true})
			:GetSetPart("Parent")
			:GetSetPart("TargetEntity", {description = "allows you to change which entity this part targets"})
			-- this is an unfortunate name, it controls the order in which the scene related functions iterate over children
			-- in practice it's often used to make something draw above something else in translucent rendering
			:GetSet("DrawOrder", 0)
			:GetSet("IsDisturbing", false, {
				editor_friendly = "IsExplicit",
				description = "Marks this content as NSFW, and makes it hidden for most of players who have pac_hide_disturbing set to 1"
			})
	:EndStorableVars()


PART.is_valid = true

function PART:IsValid()
	return self.is_valid
end

local pac_enable_convars = {}
local function get_enable_convar(classname)
	local convar = pac_enable_convars[classname]

	if not convar then
		convar = GetConVar("pac_enable_" .. string.Replace(classname, " ", "_"):lower())
		pac_enable_convars[classname] = convar
	end

	return convar
end

function PART:PreInitialize()
	self.Children = {}
	self.ChildrenMap = {}
	self.modifiers = {}
	self.RootPart = NULL
	self.DrawOrder = 0
	self.hide_disturbing = false
	self.active_events = {}
	self.active_events_ref_count = 0

	local convar = get_enable_convar(self.ClassName)
	if not convar:GetBool() then self:SetWarning("This part class is disabled! Enable it with " .. convar:GetName() .. " 1") end
end

function PART:Initialize() end

function PART:OnRemove() end

function PART:GetNiceName()
	return self.ClassName
end

function PART:GetPrintUniqueID()
	if not self.UniqueID then return '00000000' end
	return self.UniqueID:sub(1, 8)
end

function PART:GetName()
	if self.Name == "" then
		-- recursive call guard
		if self.last_nice_name_frame and self.last_nice_name_frame == pac.FrameNumber then
			return self.last_nice_name
		end

		self.last_nice_name_frame = pac.FrameNumber

		local nice = self:GetNiceName()
		local num
		local count = 0

		if self:HasParent() then
			local children = self:GetParent():GetChildren()
			for i = 1, #children do
				local ent = children[i]

				if ent:GetNiceName() == nice then
					count = count + 1

					if ent == self then
						num = count
					end
				end
			end
		end

		if num and count > 1 and num > 1 then
			nice = nice:Trim() .. " (" .. num - 1 .. ")"
		end

		self.last_nice_name = nice

		return nice
	end

	return self.Name
end

function PART:SetUniqueID(id)
	if id then
		local existing = pac.GetPartFromUniqueID(self:GetPlayerOwnerId(), id)

		if existing:IsValid() then
			pac.Message(Color(255, 50, 50), "unique id collision between ", self, " and ", existing)
			id = nil
		end
	end

	id = id or pac.Hash()

	local owner_id = self:GetPlayerOwnerId()

	if owner_id then
		pac.RemoveUniqueIDPart(owner_id, self.UniqueID)
	end

	self.UniqueID = id

	if owner_id then
		pac.SetUniqueIDPart(owner_id, id, self)
	end
end

local function set_info(msg, info_type)
	if not msg then return nil end
	local msg = tostring(msg)
	return {
		message = msg,
		type = info_type or 1
	}
end

function PART:SetInfo(message)
	self.Info = set_info(message, 1)
end
function PART:SetWarning(message)
	self.Info = set_info(message, 2)
end
function PART:SetError(message)
	self.Info = set_info(message, 3)
end

do -- owner
	function PART:SetPlayerOwner(ply)
		local owner_id = self:GetPlayerOwnerId()
		self.PlayerOwner = ply

		if ply and ply:IsValid() then
			self.PlayerOwnerHash = pac.Hash(ply)
		else
			self.PlayerOwnerHash = nil
		end

		if owner_id then
			pac.RemoveUniqueIDPart(owner_id, self.UniqueID)
		end

		local owner_id = self:GetPlayerOwnerId()

		if owner_id then
			pac.SetUniqueIDPart(owner_id, self.UniqueID, self)
		end
	end

	-- always return the root owner
	function PART:GetPlayerOwner()
		return self:GetRootPart().PlayerOwner
	end

	function PART:GetPlayerOwnerId()
		return self:GetRootPart().PlayerOwnerHash
	end

	function PART:SetRootOwnerDeprecated(b)
		if b then
			self:SetTargetEntity(self:GetRootPart())
			self.RootOwner = false
			if pace then
				pace.Call("VariableChanged", self, "TargetEntityUID", self:GetTargetEntityUID(), 0.25)
			end
		end
	end

	function PART:GetParentOwner()
		if self.TargetEntity:IsValid() and self.TargetEntity ~= self then
			return self.TargetEntity:GetOwner()
		end

		local parents = self:GetParentList()
		for i = 1, #parents do
			local parent = parents[i]

			-- legacy behavior
			if parent.ClassName == classname_event and not parent.RootOwner then
				local parent = parent:GetParent()
				if parent:IsValid() then
					local parent = parent:GetParent()
					if parent:IsValid() then
						return parent:GetOwner()
					end
				end
			end

			if parent ~= self then
				local owner = parent:GetOwner()
				if owner:IsValid() then return owner end
			end
		end

		return NULL
	end

	function PART:GetOwner()
		if self.Owner:IsValid() then
			return self.Owner
		end

		return self:GetParentOwner()
	end
end

do -- scene graph
	function PART:OnParent() end
	function PART:OnChildAdd() end
	function PART:OnUnParent() end

	function PART:OnOtherPartCreated(part)
		local owner_id = part:GetPlayerOwnerId()
		if not owner_id then return end

		-- this will handle cases like if a part is removed and added again
		for _, key in pairs(self.PartReferenceKeys) do
			if self[key] and self[key].UniqueID == part.UniqueID then
				self[prefix_set .. key](self, part)
			end
		end

		do
			if not self.unresolved_uid_parts then return end
			if not self.unresolved_uid_parts[owner_id] then return end
			local keys = self.unresolved_uid_parts[owner_id][part.UniqueID]

			if not keys then return end

			for _, key in pairs(keys) do
				self[prefix_set .. key](self, part)
			end
		end
	end

	function PART:CreatePart(name)
		local part = pac.CreatePart(name, self:GetPlayerOwner())
		if not part then return end
		part:SetParent(self)
		return part
	end

	function PART:SetDrawOrder(num)
		self.DrawOrder = num
		if self:HasParent() then
			self:GetParent():SortChildren()
		end
	end

	do -- children
		function PART:GetChildren()
			return self.Children
		end

		local function add_recursive(part, tbl, index)
			local source = part.Children

			for i = 1, #source do
				tbl[index] = source[i]
				index = index + 1
				index = add_recursive(source[i], tbl, index)
			end

			return index
		end

		function PART:GetChildrenList()
			if not self.children_list then
				local tbl = {}

				add_recursive(self, tbl, 1)

				self.children_list = tbl
			end

			return self.children_list
		end

		function PART:InvalidateChildrenList()
			self.children_list = nil

			local parents = self:GetParentList()
			for i = 1, #parents do
				parents[i].children_list = nil
			end
		end
	end

	do -- parent
		function PART:SetParent(part)
			if not part or not part:IsValid() then
				self:UnParent()
				return false
			else
				return part:AddChild(self)
			end
		end

		local function quick_copy(input)
			local output = {}
			for i = 1, #input do output[i + 1] = input[i] end
			return output
		end

		function PART:GetParentList()
			if not self.parent_list then
				if self.Parent and self.Parent:IsValid() then
					self.parent_list = quick_copy(self.Parent:GetParentList())
					self.parent_list[1] = self.Parent
				else
					self.parent_list = {}
				end
			end

			return self.parent_list
		end

		function PART:InvalidateParentList()
			self.parent_list = nil

			local children = self:GetChildrenList()
			for i = 1, #children do
				children[i].parent_list = nil
			end
		end

		function PART:InvalidateParentListPartial(parent_list, parent)
			self.parent_list = quick_copy(parent_list)
			self.parent_list[1] = parent

			local children = self:GetChildren()
			for i = 1, #children do
				children[i]:InvalidateParentListPartial(self.parent_list, self)
			end
		end
	end

	function PART:AddChild(part, ignore_show_hide)
		if not part or not part:IsValid() then
			self:UnParent()
			return
		end

		if self == part or part:HasChild(self) then
			return false
		end

		if part:HasParent() then
			part:UnParent()
		end

		part.Parent = self

		if not part:HasChild(self) then
			self.ChildrenMap[part] = part
			table_insert(self.Children, part)
		end

		self:InvalidateChildrenList()

		part.ParentUID = self:GetUniqueID()

		part:OnParent(self)
		self:OnChildAdd(part)

		if self:HasParent() then
			self:GetParent():SortChildren()
		end

		-- why would we need to sort part's children
		-- if it is completely unmodified?
		part:SortChildren()
		self:SortChildren()

		part:InvalidateParentListPartial(self:GetParentList(), self)

		if self:GetPlayerOwner() == pac.LocalPlayer then
			pac.CallHook("OnPartParent", self, part)
		end

		if not ignore_show_hide then
			part:CallRecursive("CalcShowHide", true)
		end

		return part.Id
	end

	do
		local function sort(a, b)
			return a.DrawOrder < b.DrawOrder
		end

		function PART:SortChildren()
			table.sort(self.Children, sort)
			self:InvalidateChildrenList()
		end
	end

	function PART:HasParent()
		return self.Parent:IsValid()
	end

	function PART:HasChildren()
		return self.Children[1] ~= nil
	end

	function PART:HasChild(part)
		return self.ChildrenMap[part] ~= nil
	end

	function PART:RemoveChild(part)
		self.ChildrenMap[part] = nil

		local children = self:GetChildren()
		for i = 1, #children do
			if children[i] == part then
				self:InvalidateChildrenList()
				table.remove(self.Children, i)
				part:OnUnParent(self)
				break
			end
		end
	end

	function PART:GetRootPart()
		local list = self:GetParentList()
		if list[1] then return list[#list] end
		return self
	end

	function PART:CallRecursive(func, a, b, c)
		assert(c == nil, "EXTEND ME")

		if self[func] then
			self[func](self, a, b, c)
		end

		local children = self:GetChildrenList()
		for i = 1, #children do
			local child = children[i]

			if child[func] then
				child[func](child, a, b, c)
			end
		end
	end

	function PART:CallRecursiveOnClassName(class_name, func, a, b, c)
		assert(c == nil, "EXTEND ME")

		if self[func] and self.ClassName == class_name then
			self[func](self, a,b,c)
		end

		local children = self:GetChildrenList()
		for i = 1, #children do
			local child = children[i]

			if child[func] and child.ClassName == class_name then
				child[func](child, a,b,c)
			end
		end
	end

	function PART:SetKeyValueRecursive(key, val)
		self[key] = val

		local children = self:GetChildrenList()
		for i = 1, #children do
			children[i][key] = val
		end
	end

	function PART:RemoveChildren()
		self:InvalidateChildrenList()

		local children = self:GetChildren()
		for i = 1, #children do
			local part = children[i]

			part:Remove(true)
			self.ChildrenMap[part] = nil
			self.Children[i] = nil
		end
	end

	function PART:UnParent()
		local parent = self:GetParent()

		if parent:IsValid() then
			parent:RemoveChild(self)
		end

		self:OnUnParent(parent)

		self.Parent = NULL
		self.ParentUID = ""

		self:CallRecursive("OnHide")
	end

	function PART:Remove(skip_removechild)
		self:Deattach()

		if not skip_removechild and self:HasParent() then
			self:GetParent():RemoveChild(self)
		end

		self:RemoveChildren()
	end

	function PART:Deattach()
		if not self.is_valid or self.is_deattached then return end
		self.is_deattached = true
		self.PlayerOwner_ = self.PlayerOwner

		if self:GetPlayerOwner() == pac.LocalPlayer then
			pac.CallHook("OnPartRemove", self)
		end

		self:CallRecursive("OnHide")
		self:CallRecursive("OnRemove")

		local owner_id = self:GetPlayerOwnerId()
		if owner_id then
			pac.RemoveUniqueIDPart(owner_id, self.UniqueID)
		end

		pac.RemovePart(self)
		self.is_valid = false

		self:InvalidateChildrenList()

		local children = self:GetChildren()
		for i = 1, #children do
			local part = children[i]
			local owner_id = part:GetPlayerOwnerId()

			if owner_id then
				pac.RemoveUniqueIDPart(owner_id, part.UniqueID)
			end

			pac.RemovePart(part)
		end
	end

	function PART:SetSmallIcon(str)
		if str == classname_event then str = "icon16/clock_red.png" end

		if self.pace_tree_node then
			if self.pace_tree_node.Icon then
				if not self.pace_tree_node.Icon.event_icon then
					pac_editor_scale = pac_editor_scale or GetConVar("pac_editor_scale")

					local pnl = vgui.Create("DImage", self.pace_tree_node.Icon)

					self.pace_tree_node.Icon.event_icon_alt = true
					self.pace_tree_node.Icon.event_icon = pnl

					pnl:SetSize(8 * (1 + 0.5 * (pac_editor_scale:GetFloat() - 1)), 8 * (1 + 0.5 * (pac_editor_scale:GetFloat() - 1)))
					pnl:SetPos(8 * (1 + 0.5 * (pac_editor_scale:GetFloat() - 1)), 8 * (1 + 0.5 * (pac_editor_scale:GetFloat() - 1)))
				end

				self.pace_tree_node.Icon.event_icon_alt = true
				self.pace_tree_node.Icon.event_icon:SetImage(str)
				self.pace_tree_node.Icon.event_icon:SetVisible(true)
			end
		end
	end
	function PART:RemoveSmallIcon()
		if self.pace_tree_node then
			if self.pace_tree_node.Icon then
				if self.pace_tree_node.Icon.event_icon then
					self.pace_tree_node.Icon.event_icon_alt = false
					self.pace_tree_node.Icon.event_icon:SetImage("icon16/clock_red.png")
					self.pace_tree_node.Icon.event_icon:SetVisible(false)
				end
			end
		end
	end

end

do -- hidden / events
	local pac_hide_disturbing = CreateClientConVar("pac_hide_disturbing", "1", true, true, "Hide parts which outfit creators marked as 'nsfw' (e.g. gore or explicit content)")

	function PART:SetIsDisturbing(val)
		self.IsDisturbing = val
		self.hide_disturbing = pac_hide_disturbing:GetBool() and val

		self:CallRecursive("CalcShowHide", true)
	end

	function PART:UpdateIsDisturbing()
		local new_value = pac_hide_disturbing:GetBool() and self.IsDisturbing
		if new_value == self.hide_disturbing then return end
		self.hide_disturbing = new_value

		self:CallRecursive("CalcShowHide", true)
	end

	function PART:OnHide() end
	function PART:OnShow() end

	function PART:SetEnabled(val)
		self.Enabled = val

		if val then
			self:ShowFromRendering()
		else
			self:HideFromRendering()
		end
	end

	function PART:SetHide(val)
		self.Hide = val

		-- so that IsHiddenCached works in OnHide/OnShow events
		self:SetKeyValueRecursive("last_hidden", val)

		if val then
			self:CallRecursive("OnHide", true)
		else
			self:CallRecursive("OnShow", true)
		end

		self:CallRecursive("CalcShowHide", true)
	end

	function PART:IsDrawHidden()
		return self.draw_hidden
	end

	function PART:SetDrawHidden(b)
		self.draw_hidden = b
	end

	function PART:ShowFromRendering()
		self:SetDrawHidden(false)

		if not self:IsHidden() then
			self:OnShow(true)
		end

		local children = self:GetChildrenList()
		for i = 1, #children do
			local child = children[i]

			child:SetDrawHidden(false)

			if not child:IsHidden() then
				child:OnShow(true)
			end
		end
	end

	function PART:HideFromRendering()
		self:SetDrawHidden(true)
		self:CallRecursive("OnHide", true)
	end

	local function is_hidden(part)
		if part.active_events_ref_count > 0 then
			return true
		end

		return part.Hide or part.hide_disturbing
	end

	function PART:IsHidden()
		if is_hidden(self) then
			return true
		end

		local parents = self:GetParentList()
		for i = 1, #parents do
			if is_hidden(parents[i]) then
				return true
			end
		end

		return false
	end

	function PART:SetEventTrigger(event_part, enable)
		if enable then
			if not self.active_events[event_part] then
				self.active_events[event_part] = event_part
				self.active_events_ref_count = self.active_events_ref_count + 1
				self:CallRecursive("CalcShowHide", false)
			end
		else
			if self.active_events[event_part] then
				self.active_events[event_part] = nil
				self.active_events_ref_count = self.active_events_ref_count - 1
				self:CallRecursive("CalcShowHide", false)
			end
		end
	end

	function PART:GetReasonHidden()
		local found = {}

		for part in pairs(self.active_events) do
			table_insert(found, tostring(part) .. " is event hiding")
		end

		if found[1] then
			return table.concat(found, "\n")
		end

		if self.Hide then
			return "hide enabled"
		end

		if self.hide_disturbing then
			return "pac_hide_disturbing is set to 1"
		end

		local parents = self:GetParentList()
		for i = 1, #parents do
			local part = parents[i]

			if part:IsHidden() then
				table_insert(found, tostring(part) .. " is parent hiding")
			end
		end

		if found[1] then
			return table.concat(found, "\n")
		end

		return ""
	end

	function PART:GetReasonsHidden()
		local found = {}

		for part in pairs(self.active_events) do
			found[part] = "event hiding"
		end

		if self.Hide then
			found[self] = "self hiding"
		end

		if self.hide_disturbing then
			if self.Hide then
				found[self] = "self hiding and disturbing"
			else
				found[self] = "disturbing"
			end
		end

		local parents = self:GetParentList()
		for i = 1, #parents do
			local part = parents[i]

			if not found[part] then
				if part:IsHidden() then
					found[part] = "parent hidden"
				end
			end
		end

		return found
	end

	function PART:CalcShowHide(from_rendering)
		local b = self:IsHidden()

		if b ~= self.last_hidden then
			if b then
				self:OnHide(from_rendering)
			else
				self:OnShow(from_rendering)
			end
		end

		self.last_hidden = b
	end

	function PART:IsHiddenCached()
		return self.last_hidden
	end

	function PART:BuildBonePositions()
		if not self.Enabled then return end

		if not self:IsHiddenCached() then
			self:OnBuildBonePositions()
		end
	end

	function PART:OnBuildBonePositions()

	end
end

PART.show_in_editor = true

function PART:GetShowInEditor()
	return self:GetRootPart().show_in_editor == true
end

function PART:SetShowInEditor(b)
	self:GetRootPart().show_in_editor = b
end

do -- serializing
	function PART:AddStorableVar(var)
		self.StorableVars = self.StorableVars or {}

		self.StorableVars[var] = var
	end

	function PART:GetStorableVars()
		self.StorableVars = self.StorableVars or {}

		return self.StorableVars
	end

	function PART:Clear()
		self:RemoveChildren()
	end

	function PART:OnWorn()
		-- override
	end

	function PART:OnOutfitLoaded()
		-- override
	end

	function PART:PostApplyFixes()
		-- override
	end


	do
		function PART:GetProperty(name)
			local val = self[prefix_get .. name]

			if val == nil then
				if self.GetDynamicProperties then
					local info = self:GetDynamicProperties()
					if info and info[name] then
						return info[name].get()
					end
				end
			else
				return val(self)
			end
		end

		function PART:SetProperty(key, val)
			local setFunc = self[prefix_set .. key]

			if setFunc ~= nil then
				if self[prefix_get .. key](self) ~= val then
					setFunc(self, val)
				end
			elseif self.GetDynamicProperties then
				local info = self:GetDynamicProperties()[key]
				if info and info then
					info.set(val)
				end
			end
		end

		function PART:GetProperties()
			local out = {}

			for _, key in pairs(self:GetStorableVars()) do
				if self.PropertyWhitelist and not self.PropertyWhitelist[key] then
					goto CONTINUE
				end

				table_insert(out, {
					key = key,
					set = function(v) self[prefix_set .. key](self, v) end,
					get = function() return self[prefix_get .. key](self) end,
					udata = pac.GetPropertyUserdata(self, key) or {},
				})

				::CONTINUE::
			end

			if self.GetDynamicProperties then
				local props = self:GetDynamicProperties()

				if props then
					for _, info in pairs(props) do
						if not self.PropertyWhitelist or self.PropertyWhitelist[info.key] then
							table_insert(out, info)
						end
					end
				end
			end

			local sorted = {}
			local done = {}

			for _, key in ipairs({"Name", "Hide"}) do
				for _, prop in ipairs(out) do
					if key == prop.key then
						if not done[key] then
							table_insert(sorted, prop)
							done[key] = true
							break
						end
					end
				end
			end

			if pac.VariableOrder[self.ClassName] then
				for _, key in ipairs(pac.VariableOrder[self.ClassName]) do
					for _, prop in ipairs(out) do
						if key == prop.key then
							if not done[key] then
								table_insert(sorted, prop)
								done[key] = true
								break
							end
						end
					end
				end
			end

			for _, variables in pairs(pac.VariableOrder) do
				for _, key in ipairs(variables) do
					for _, prop in ipairs(out) do
						if key == prop.key then
							if not done[key] then
								table_insert(sorted, prop)
								done[key] = true
								break
							end
						end
					end
				end
			end

			for _, prop in ipairs(out) do
				if not done[prop.key] then
					table_insert(sorted, prop)
				end
			end

			return sorted
		end
	end

	local function on_error(msg)
		ErrorNoHalt(debug_traceback(msg))
	end

	do
		local function SetTable(self, tbl, level)
			self:SetUniqueID(tbl.self.UniqueID)
			self.delayed_variables = self.delayed_variables or {}

			for key, value in next, tbl.self do
				if key == "UniqueID" then goto CONTINUE end
				local setFunc = self[prefix_set .. key]

				if setFunc then
					if key == "Material" then
						table_insert(self.delayed_variables, {key = key, val = value})
					end

					setFunc(self, value)
				elseif key ~= "ClassName" then
					pac.dprint("settable: unhandled key [%q] = %q", key, tostring(value))
				end

		        ::CONTINUE::
			end

			for _, value in pairs(tbl.children) do
				local part = pac.CreatePart(value.self.ClassName, self:GetPlayerOwner(), value, nil --[[make_copy]], level + 1)
				self:AddChild(part, true)
			end
		end

		local function make_copy(tbl, pepper, uid_list)
			if pepper == true then
				pepper = tostring(math_random()) .. tostring(math_random())
			end

			uid_list = uid_list or {}
			tbl.self.UniqueID = pac.Hash(tbl.self.UniqueID .. pepper)
			uid_list[tostring(tbl.self.UniqueID)] = tbl.self

			for _, child in ipairs(tbl.children) do
				make_copy(child, pepper, uid_list)
			end

			return tbl, pepper, uid_list
		end

		local function update_uids(uid_list, pepper)
			for uid, part in pairs(uid_list) do
				for key, val in pairs(part) do
					if (key:sub(-3) == "UID") then
						local new_uid = pac.Hash(val .. pepper)

						if uid_list[tostring(new_uid)] then
							part[key] = new_uid
						end
					end
				end
			end
		end

		function PART:SetTable(tbl, copy_id, level)
			level = level or 0

			if copy_id then
				local pepper, uid_list
				tbl, pepper, uid_list = make_copy(table_copy(tbl), copy_id)
				update_uids(uid_list, pepper)
			end

			local ok, err = xpcall(SetTable, on_error, self, tbl, level)

			if not ok then
				pac.Message(Color(255, 50, 50), "SetTable failed: ", err)
			end

			-- figure out if children needs to be hidden
			if level == 0 then
				self:CallRecursive("CalcShowHide", true)
			end
		end
	end

	function PART:ToTable()
		local tbl = {self = {ClassName = self.ClassName}, children = {}}

		for _, key in pairs(self:GetStorableVars()) do
			local var = self[key] and self[prefix_get .. key](self) or self[key]
			var = pac.CopyValue(var) or var

			if make_copy_name and var ~= "" and (key == "UniqueID" or key:sub(-3) == "UID") then
				var = pac.Hash(var .. var)
			end

			if key == "Name" and self[key] == "" then
				var = ""
			end

			-- these arent needed because parent system uses the tree structure
			if key ~= "ParentUID" and var ~= self.DefaultVars[key] then
				tbl.self[key] = var
			end
		end

		local children = self:GetChildren()
		for i = 1, #children do
			if self.is_valid and not self.is_deattached then
				table_insert(tbl.children, children[i]:ToTable())
			end
		end

		return tbl
	end

	function PART:ToSaveTable()
		if self:GetPlayerOwner() ~= pac.LocalPlayer then return end

		local tbl = {self = {ClassName = self.ClassName}, children = {}}

		for _, key in pairs(self:GetStorableVars()) do
			local var = self[key] and self[prefix_get .. key](self) or self[key]
			var = pac.CopyValue(var) or var

			if key == "Name" and self[key] == "" then
				var = ""
			end

			-- these arent needed because parent system uses the tree structure
			if key ~= "ParentUID" then
				tbl.self[key] = var
			end
		end

		local children = self:GetChildren()
		for i = 1, #children do
			if self.is_valid and not self.is_deattached then
				table_insert(tbl.children, children[i]:ToSaveTable())
			end
		end

		return tbl
	end

	do -- undo
		do
			local function SetTable(self, tbl)
				self:SetUniqueID(tbl.self.UniqueID)
				self.delayed_variables = self.delayed_variables or {}

				for key, value in pairs(tbl.self) do
					if key == "UniqueID" then goto CONTINUE end
					local setFunc = self[prefix_set .. key]

					if setFunc then
						if key == "Material" then
							table_insert(self.delayed_variables, {key = key, val = value})
						end

						setFunc(self, value)
					elseif key ~= "ClassName" then
						pac.dprint("settable: unhandled key [%q] = %q", key, tostring(value))
					end

                    ::CONTINUE::
				end

				for _, value in pairs(tbl.children) do
					local part = pac.CreatePart(value.self.ClassName, self:GetPlayerOwner())
					part:SetUndoTable(value)
					part:SetParent(self)
				end
			end

			function PART:SetUndoTable(tbl)
				local ok, err = xpcall(SetTable, on_error, self, tbl)
				if not ok then
					pac.Message(Color(255, 50, 50), "SetUndoTable failed: ", err)
				end
			end
		end

		function PART:ToUndoTable()
			if self:GetPlayerOwner() ~= pac.LocalPlayer then return end

			local tbl = {self = {ClassName = self.ClassName}, children = {}}

			for _, key in pairs(self:GetStorableVars()) do
				if key == "Name" and self.Name == "" then
					-- TODO: seperate debug name and name !!!
					goto CONTINUE
				end

				tbl.self[key] = pac.CopyValue(self[prefix_get .. key](self))
                ::CONTINUE::
			end

			local children = self:GetChildren()
			for i = 1, #children do
				if self.is_valid and not self.is_deattached then
					table_insert(tbl.children, children[i]:ToUndoTable())
				end
			end

			return tbl
		end

	end

	function PART:GetVars()
		local tbl = {}

		for _, key in pairs(self:GetStorableVars()) do
			tbl[key] = pac.CopyValue(self[key])
		end

		return tbl
	end

	function PART:Clone()
		local part = pac.CreatePart(self.ClassName, self:GetPlayerOwner())
		if not part then return end

		-- ugly workaround for cloning bugs
		if self:GetOwner() == self:GetPlayerOwner() then
			part:SetOwner(self:GetOwner())
		end

		part:SetTable(self:ToTable(), true)

		if self:GetParent():IsValid() then
			part:SetParent(self:GetParent())
		end

		return part
	end
end

do
	function PART:Think()
		if not self.Enabled then return end
		if self.ThinkTime ~= 0 and self.last_think and self.last_think > pac.RealTime then return end

		if not self.AlwaysThink and self:IsHiddenCached() then
			self:AlwaysOnThink() -- for things that drive general logic
			-- such as processing outfit URL downloads
			-- without calling probably expensive self:OnThink()
			return
		end

		local delayedVars = self.delayed_variables

		if delayedVars then
			for i = 1, #delayedVars do
				local data = delayedVars[i]

				self[prefix_set .. data.key](self, data.val)
			end

			self.delayed_variables = nil
		end

		self:AlwaysOnThink() -- for things that drive general logic
		-- such as processing outfit URL downloads
		-- without calling probably expensive self:OnThink()
		self:OnThink()
	end

	function PART:OnThink() end
	function PART:AlwaysOnThink() end
end

--the popup system
function PART:SetupEditorPopup(str, force_open, tbl)
	local legacy_help_popup_hack = false

	if not tbl then
		legacy_help_popup_hack = false
	elseif tbl.from_legacy then
		legacy_help_popup_hack = true
	end

	if not IsValid(self) then return end

	pac_popups_preferred_location = pac_popups_preferred_location or GetConVar("pac_popups_preferred_location")

	local popup_config_table = tbl or {
		pac_part = self,
		obj_type = pac_popups_preferred_location:GetString(),
		hoverfunc = function() end,
		doclickfunc = function() end,
		panel_exp_width = 900,
		panel_exp_height = 400
	}

	local default_state = str == nil or str == ""
	local info_string

	if self.ClassName == classname_event and default_state then
		info_string = self:GetEventTutorialText()
	end

	info_string = info_string or str or self.ClassName .. "\nno special information available"

	if default_state and pace then
		local partsize_tbl = pace.GetPartSizeInformation(self)
		info_string = info_string .. "\n" .. partsize_tbl.info .. ", " .. partsize_tbl.all_share_percent .. "% of all parts"
	end

	if self.Notes and self.Notes ~= "" then
		info_string = info_string .. "\n\nNotes:\n\n" .. self.Notes
	end

	local tree_node = self.pace_tree_node
	local part = self
	self.killpopup = false
	local pnl

	--local pace = pace or {}
	if tree_node then
		tree_node.Label:SetTooltip(self.ClassName)
		local part = self

		function tree_node:Think()
			--if not part.killpopup and ((self.Label:IsHovered() and GetConVar("pac_popups_preferred_location"):GetString() == "pac tree label") or input.IsButtonDown(KEY_F1) or force_open) then
			if not part.killpopup and ((self.Label:IsHovered() and pac_popups_preferred_location:GetString() == "pac tree label") or force_open) then
				if not self.popuppnl_is_up and not IsValid(self.popupinfopnl) and not part.killpopup and not legacy_help_popup_hack then
					self.popupinfopnl = pac.InfoPopup(
						info_string,
						popup_config_table
					)
					self.popuppnl_is_up = true
				end

				--if IsValid(self.popupinfopnl) then self.popupinfopnl:MakePopup() end
				pnl = self.popupinfopnl

			end
			if not IsValid(self.popupinfopnl) then self.popupinfopnl = nil self.popuppnl_is_up = false end
		end
		tree_node:Think()
	end
	if not pnl then
		pnl = pac.InfoPopup(info_string,popup_config_table)
		self.pace_tree_node.popupinfopnl = pnl
	end
	if pace then
		pace.legacy_floating_popup_reserved = pnl
	end

	return pnl
end

function PART:AttachEditorPopup(str, flash, tbl)
	local pnl = self:SetupEditorPopup(str, flash, tbl)
	if flash and pnl then
		pnl:MakePopup()
	end
end

function PART:DetachEditorPopup()
	local tree_node = self.pace_tree_node
	if tree_node then
		if tree_node.popupinfopnl then
			tree_node.popupinfopnl:Remove()
		end
		if not IsValid(tree_node.popupinfopnl) then tree_node.popupinfopnl = nil end
	end
end

BUILDER:Register()
