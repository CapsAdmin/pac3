local string_format = string.format
local tostring = tostring
local pace = pace
local assert = assert
local debug_traceback = debug.traceback
local math_random = math.random
local xpcall = xpcall
local pac = pac
local pairs = pairs
local ipairs = ipairs
local table = table
local Color = Color
local NULL = NULL
local table_insert = table.insert

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

function PART:PreInitialize()
	self.Children = {}
	self.ChildrenMap = {}
	self.modifiers = {}
	self.RootPart = NULL
	self.DrawOrder = 0
	self.hide_disturbing = false
	self.active_events = {}
	self.active_events_ref_count = 0
	local cvarName = "pac_enable_" .. string.Replace(self.ClassName, " ", "_"):lower()
	if not GetConVar(cvarName):GetBool() then self:SetWarning("This part class is disabled! Enable it with " .. cvarName .. " 1") end
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
			for _, val in ipairs(self:GetParent():GetChildren()) do
				if val:GetNiceName() == nice then
					count = count + 1

					if val == self then
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

		for _, parent in ipairs(self:GetParentList()) do

			-- legacy behavior
			if parent.ClassName == "event" and not parent.RootOwner then
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
				self["Set" .. key](self, part)
			end
		end

		do
			if not self.unresolved_uid_parts then return end
			if not self.unresolved_uid_parts[owner_id] then return end
			local keys = self.unresolved_uid_parts[owner_id][part.UniqueID]

			if not keys then return end

			for _, key in pairs(keys) do
				self["Set" .. key](self, part)
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

			for _, parent in ipairs(self:GetParentList()) do
				parent.children_list = nil
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

			for _, child in ipairs(self:GetChildrenList()) do
				child.parent_list = nil
			end
		end

		function PART:InvalidateParentListPartial(parent_list, parent)
			self.parent_list = quick_copy(parent_list)
			self.parent_list[1] = parent

			for _, child in ipairs(self:GetChildren()) do
				child:InvalidateParentListPartial(self.parent_list, self)
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

		for i, val in ipairs(self:GetChildren()) do
			if val == part then
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

	function PART:CallRecursive(func, a,b,c)
		assert(c == nil, "EXTEND ME")
		if self[func] then
			self[func](self, a,b,c)
		end

		for _, child in ipairs(self:GetChildrenList()) do
			if child[func] then
				child[func](child, a,b,c)
			end
		end
	end

	function PART:CallRecursiveOnClassName(class_name, func, a,b,c)
		assert(c == nil, "EXTEND ME")
		if self[func] and self.ClassName == class_name then
			self[func](self, a,b,c)
		end

		for _, child in ipairs(self:GetChildrenList()) do
			if child[func] and self.ClassName == class_name then
				child[func](child, a,b,c)
			end
		end
	end

	function PART:SetKeyValueRecursive(key, val)
		self[key] = val

		for _, child in ipairs(self:GetChildrenList()) do
			child[key] = val
		end
	end


	function PART:RemoveChildren()
		self:InvalidateChildrenList()

		for i, part in ipairs(self:GetChildren()) do
			part:Remove(true)
			self.Children[i] = nil
			self.ChildrenMap[part] = nil
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

		for _, part in ipairs(self:GetChildren()) do
			local owner_id = part:GetPlayerOwnerId()

			if owner_id then
				pac.RemoveUniqueIDPart(owner_id, part.UniqueID)
			end

			pac.RemovePart(part)
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

		for _, child in ipairs(self:GetChildrenList()) do
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

		for _, parent in ipairs(self:GetParentList()) do
			if is_hidden(parent) then
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

		return ""
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
			local val = self["Get" .. name]

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
			if self["Set" .. key] ~= nil then
				if self["Get" .. key](self) ~= val then
					self["Set" .. key](self, val)
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
					set = function(v) self["Set" .. key](self, v) end,
					get = function() return self["Get" .. key](self) end,
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

				if self["Set" .. key] then
					if key == "Material" then
						table_insert(self.delayed_variables, {key = key, val = value})
					end
					self["Set" .. key](self, value)
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
				tbl, pepper, uid_list = make_copy(table.Copy(tbl), copy_id)
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
			local var = self[key] and self["Get" .. key](self) or self[key]
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

		for _, part in ipairs(self:GetChildren()) do
			if not self.is_valid or self.is_deattached then

			else
				table_insert(tbl.children, part:ToTable())
			end
		end

		return tbl
	end

	function PART:ToSaveTable()
		if self:GetPlayerOwner() ~= pac.LocalPlayer then return end

		local tbl = {self = {ClassName = self.ClassName}, children = {}}

		for _, key in pairs(self:GetStorableVars()) do
			local var = self[key] and self["Get" .. key](self) or self[key]
			var = pac.CopyValue(var) or var

			if key == "Name" and self[key] == "" then
				var = ""
			end

			-- these arent needed because parent system uses the tree structure
			if key ~= "ParentUID" then
				tbl.self[key] = var
			end
		end

		for _, part in ipairs(self:GetChildren()) do
			if not self.is_valid or self.is_deattached then

			else
				table_insert(tbl.children, part:ToSaveTable())
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

					if self["Set" .. key] then
						if key == "Material" then
							table_insert(self.delayed_variables, {key = key, val = value})
						end
						self["Set" .. key](self, value)
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

				tbl.self[key] = pac.CopyValue(self["Get" .. key](self))
                ::CONTINUE::
			end

			for _, part in ipairs(self:GetChildren()) do
				if not self.is_valid or self.is_deattached then

				else
					table_insert(tbl.children, part:ToUndoTable())
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

		if self.delayed_variables then

			for _, data in ipairs(self.delayed_variables) do
				self["Set" .. data.key](self, data.val)
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

BUILDER:Register()
