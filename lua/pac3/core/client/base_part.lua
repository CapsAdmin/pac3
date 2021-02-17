local pac = pac
local pairs = pairs
local ipairs = ipairs
local table = table
local Vector = Vector
local Angle = Angle
local Color = Color
local NULL = NULL
local SysTime = SysTime

local LocalToWorld = LocalToWorld

local BUILDER, PART = pac.PartTemplate()

PART.ClassName = "base"

function PART:__tostring()
	return string.format("part[%s][%s][%i]", self.ClassName, self:GetName(), self.Id)
end

BUILDER
	:GetSet("PlayerOwner", NULL)
	:GetSet("Owner", NULL)

BUILDER
	:StartStorableVars()
		:SetPropertyGroup("generic")
			:GetSet("Name", "")
			:GetSet("Hide", false)
			:GetSet("OwnerName", "self")
			:GetSet("EditorExpand", false, {hidden = true})
			:GetSet("UniqueID", "", {hidden = true})
			:GetSetPart("Parent")
			:GetSet("IsDisturbing", false, {
				editor_friendly = "IsExplicit",
				description = "Marks this content as NSFW, and makes it hidden for most of players who have pac_hide_disturbing set to 1"
			})
			:GetSet("DrawOrder", 0)
	:EndStorableVars()

function PART:SetUniqueID(id)
	local owner_id = self:GetPlayerOwnerId()

	if owner_id then
		pac.RemoveUniqueIDPart(owner_id, self.UniqueID)
	end

	self.UniqueID = id

	if owner_id then
		pac.SetUniqueIDPart(owner_id, id, self)
	end
end

function PART:PreInitialize()
	self.Children = {}
	self.Children2 = {}
	self.modifiers = {}
	self.RootPart = NULL
	self.DrawOrder = 0
	self.hide_disturbing = false
	self.event_hide_registry = {}
end

function PART:GetNiceName()
	return self.ClassName
end

function PART:RemoveOnNULLOwner(b)
	self.remove_on_null_owner = b
end

function PART:GetName()
	if self.Name == "" then

		-- recursive call guard
		if self.last_nice_name_frame and self.last_nice_name_frame == FrameNumber() then
			return self.last_nice_name
		end

		self.last_nice_name_frame = FrameNumber()

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

function PART:GetEnabled()

	local enabled = self:IsEnabled()

	if self.last_enabled == enabled then
		return enabled
	end

	-- changed

	if self.last_enabled == nil then
		self.last_enabled = enabled
	else
		self.last_enabled = enabled

		if enabled then
			self:CallRecursive("OnShow")
		else
			self:CallRecursive("OnHide")
		end

	end

	return enabled

end

do -- owner
	function PART:SetPlayerOwner(ply)
		self.PlayerOwner = ply

		if not self:HasParent() then
			self:CheckOwner()
		end

		self:SetUniqueID(self:GetUniqueID())
	end

	function PART:GetPlayerOwnerId()
		local owner = self:GetPlayerOwner()

		if not owner:IsValid() then return end

		if owner:IsPlayer() then
			return owner:UniqueID()
		end

		return owner:EntIndex()
	end

	function PART:SetOwnerName(name)
		self.OwnerName = name
		self:CheckOwner()
	end

	function PART:CheckOwner(ent, removed)
		self = self:GetRootPart()

		local prev_owner = self:GetOwner()

		if self.Duplicate then

			ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent, self, function(e) return e.pac_duplicate_attach_uid ~= self.UniqueID end) or NULL

			if ent ~= prev_owner and ent:IsValid() then

				local tbl = self:ToTable(true)
				tbl.self.OwnerName = "self"
				pac.SetupENT(ent)
				ent:SetShowPACPartsInEditor(false)
				ent:AttachPACPart(tbl)
				ent:CallOnRemove("pac_remove_outfit_" .. tbl.self.UniqueID, function()
					ent:RemovePACPart(tbl)
				end)

				if self:GetPlayerOwner() == pac.LocalPlayer then
					ent:SetPACDrawDistance(0)
				end

				ent.pac_duplicate_attach_uid = self.UniqueID
			end

		else
			if removed and prev_owner == ent then
				self:SetOwner(NULL)
				self.temp_hidden = true
				return
			end

			if not removed and self.OwnerName ~= "" then
				ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent, self) or NULL
				if ent ~= prev_owner then
					self:SetOwner(ent)
					self.temp_hidden = false
					return true
				end
			end

		end
	end

	function PART:SetOwner(ent)

		if IsValid(self.last_owner) and self.last_owner ~= ent then
			self:CallRecursive("OnHide", true)
		end

		self.last_owner = self.Owner
		self.Owner = ent or NULL
	end

	-- always return the root owner
	function PART:GetPlayerOwner()
		if not self.PlayerOwner then
			return self:GetOwner(true) or NULL
		end

		return self.PlayerOwner
	end

	function PART:GetOwner(root)
		if self.owner_override then
			return self.owner_override
		end

		if root then
			return self:GetRootPart():GetOwner()
		end

		local parent = self:GetParent()

		if parent:IsValid() then
			if
				self.ClassName ~= "event" and
				parent.is_model_part and
				parent.Entity:IsValid()
			then
				return parent.Entity
			end

			return parent:GetOwner()
		end

		return self.Owner or NULL
	end
end

do
	local pac_hide_disturbing = CreateClientConVar("pac_hide_disturbing", "1", true, true, "Hide parts which outfit creators marked as 'nsfw' (e.g. gore or explicit content)")

	function PART:SetIsDisturbing(val)
		self.IsDisturbing = val
		self.hide_disturbing = pac_hide_disturbing:GetBool() and val
	end
end

do -- parenting
	function PART:GetChildren()
		return self.Children
	end

	function PART:GetChildrenList()
		if not self.children_list then
			self:BuildChildrenList()
		end

		return self.children_list
	end

	local function add_children_to_list(parent, list, drawOrder)
		for _, child in ipairs(parent:GetChildren()) do
			table.insert(list, {child, child.DrawOrder + drawOrder})
			add_children_to_list(child, list, drawOrder + child.DrawOrder)
		end
	end

	function PART:BuildChildrenList()
		local child = {}
		self.children_list = child

		local tableToSort = {}
		add_children_to_list(self, tableToSort, self.DrawOrder)

		table.sort(tableToSort, function(a, b)
			return a[2] < b[2]
		end)

		for i, data in ipairs(tableToSort) do
			child[#child + 1] = data[1]
		end
	end

	function PART:CreatePart(name)
		local part = pac.CreatePart(name, self:GetPlayerOwner())
		if not part then return end
		part:SetParent(self)
		return part
	end

	function PART:SetParent(part)
		if not part or not part:IsValid() then
			self:UnParent()
			return false
		else
			return part:AddChild(self)
		end
	end

	function PART:BuildParentList()

		if not self:HasParent() then return end

		self.parent_list = {}

		local temp = self:GetParent()

		table.insert(self.parent_list, temp)

		for _ = 1, 100 do
			local parent = temp:GetParent()
			if not parent:IsValid() then break end

			table.insert(self.parent_list, parent)

			temp = parent
		end

		self.RootPart = temp

		for _, part in ipairs(self:GetChildren()) do
			part:BuildParentList()
		end
	end

	function PART:AddChild(part)
		if not part or not part:IsValid() then
			self:UnParent()
			return
		end

		if self == part or part:HasChild(self) then
			return false
		end

		part:UnParent()

		part.Parent = self

		if not part:HasChild(self) then
			self.Children2[part] = part
			table.insert(self.Children, part)
		end

		self:InvalidateChildrenList()

		part.ParentName = self:GetName()
		part.ParentUID = self:GetUniqueID()

		part:OnParent(self)
		self:OnChildAdd(part)

		if self:HasParent() then
			self:GetParent():SortChildren()
		end

		part:SortChildren()
		self:SortChildren()

		self:BuildParentList()
		part:BuildParentList()

		if self:GetPlayerOwner() == pac.LocalPlayer then
			pac.CallHook("OnPartParent", self, part)
		end

		part.shown_from_rendering = true
		part:SetKeyValueRecursive("last_hidden", nil)
		part:SetKeyValueRecursive("last_hidden_by_event", nil)

		return part.Id
	end

	do
		local sort = function(a, b)
			return a.DrawOrder < b.DrawOrder
		end

		function PART:SortChildren()
			table.sort(self.Children, sort)
		end
	end

	function PART:HasParent()
		return self.Parent:IsValid()
	end

	function PART:HasChildren()
		return self.Children[1] ~= nil
	end

	function PART:HasChild(part)
		return self.Children2[part] ~= nil
	end

	function PART:RemoveChild(part)
		self.Children2[part] = nil

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

		if not self:HasParent() then return self end

		if not self.RootPart:IsValid() then
			self:BuildParentList()
		end

		return self.RootPart
	end

	do
		function PART:CallRecursive(func, ...)
			if self[func] then
				self[func](self, ...)
			end

			local child = self:GetChildrenList()

			for i = 1, #child do
				if child[i][func] then
					child[i][func](child[i], ...)
				end
			end
		end

		function PART:CallRecursiveExclude(func, ...)
			local child = self:GetChildrenList()

			for i = 1, #child do
				if child[i][func] then
					child[i][func](child[i], ...)
				end
			end
		end

		function PART:SetKeyValueRecursive(key, val)
			self[key] = val

			local child = self:GetChildrenList()

			for i = 1, #child do
				child[i][key] = val
			end
		end

		function PART:SetHide(b)
			self.Hide = b

			self:SetKeyValueRecursive("hidden", b)
		end

		function PART:RemoveEventHide(object)
			self.event_hide_registry[object] = nil
		end

		function PART:SetEventHide(b, object)
			object = object or self

			-- this can and will produce undefined behavior (like skipping keys)
			-- but still, it will do the job at cleaning up at least a part of table
			for k, v in pairs(self.event_hide_registry) do
				if not IsValid(k) then
					self.event_hide_registry[k] = nil
				end
			end

			self.event_hide_registry[object] = b
			self.event_hidden = self:CalculateEventHidden()

			if self.event_hidden ~= b then
				self.shown_from_rendering = nil
			end
		end

		function PART:FlushFromRenderingState(newState)
			self.shown_from_rendering = nil
		end

		function PART:IsDrawHidden()
			return self.draw_hidden
		end

		function PART:CalculateEventHidden()
			for k, v in pairs(self.event_hide_registry) do
				if v then
					return true
				end
			end

			return false
		end

		function PART:IsEventHidden(object, invert)
			if object then
				if invert then
					for k, v in pairs(self.event_hide_registry) do
						if k ~= object and v then
							return true
						end
					end

					return false
				end

				return self.event_hide_registry[object] == true
			end

			if self.event_hidden == nil then
				self.event_hidden = self:CalculateEventHidden()
			end

			return self.event_hidden
		end

		function PART:IsHiddenInternal()
			return self.hidden
		end

		function PART:IsHidden()
			if
				self.draw_hidden or
				self.temp_hidden or
				self.hidden or
				self.hide_disturbing or
				self:IsEventHidden()
			then
				return true, self:IsEventHidden()
			end

			if not self:HasParent() then
				return false
			end

			if not self.parent_list then
				self:BuildParentList()
			end

			for _, parent in ipairs(self.parent_list) do
				if
					parent.draw_hidden or
					parent.temp_hidden or
					parent.hidden or
					parent.event_hidden
				then
					return true, parent:IsEventHidden()
				end
			end

			return false
		end
	end

	function PART:InvalidateChildrenList()
		self.children_list = nil
		if self.parent_list then
			for _, part in ipairs(self.parent_list) do
				part.children_list = nil
			end
		end
	end

	function PART:RemoveChildren()
		self:InvalidateChildrenList()

		for i, part in ipairs(self:GetChildren()) do
			part:Remove(true)
			self.Children[i] = nil
			self.Children2[part] = nil
		end
	end

	function PART:DeattachChildren()
		self:InvalidateChildrenList()

		for i, part in ipairs(self:GetChildren()) do
			local owner_id = part:GetPlayerOwnerId()

			if owner_id then
				pac.RemoveUniqueIDPart(owner_id, part.UniqueID)
			end

			pac.RemovePart(part)
		end
	end

	function PART:UnParent()
		local parent = self:GetParent()

		if parent:IsValid() then
			parent:RemoveChild(self)
		end

		self:OnUnParent(parent)

		self.Parent = NULL
		self.ParentName = ""
		self.ParentUID = ""

		self:CallRecursive("OnHide")
	end
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

	function PART:IsBeingWorn()
		return self.isBeingWorn
	end

	function PART:SetIsBeingWorn(status)
		self.isBeingWorn = status
		return self
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

	function PART:GetProperties()
		local tbl = {}
		for _, key in pairs(self:GetStorableVars()) do
			local val = {}
			val.set = function(v) self["Set" .. key](self, v) end
			val.get = function() return self["Get" .. key](self) end
			val.key = key
			val.udata = pac.GetPropertyUserdata(self, key) or {}

			table.insert(tbl, val)
		end
		return tbl
	end

	do
		local function SetTable(self, tbl)
			self:SetUniqueID(tbl.self.UniqueID or util.CRC(tostring(tbl.self)))
			self.delayed_variables = self.delayed_variables or {}

			for key, value in pairs(tbl.self) do
				if key == "UniqueID" then continue end

				if self["Set" .. key] then
					if key == "Material" then
						table.insert(self.delayed_variables, {key = key, val = value})
					end
					self["Set" .. key](self, value)
				elseif key ~= "ClassName" then
					pac.dprint("settable: unhandled key [%q] = %q", key, tostring(value))
				end
			end

			for _, value in pairs(tbl.children) do
				local part = pac.CreatePart(value.self.ClassName, self:GetPlayerOwner(), value)
				part:SetIsBeingWorn(self:IsBeingWorn())
				part:SetParent(self)
			end
		end

		local function make_copy(tbl, pepper)
			for key, val in pairs(tbl.self) do
				if key == "UniqueID" or key:sub(-3) == "UID" then
					tbl.self[key] = util.CRC(val .. pepper)
				end
			end

			for _, child in ipairs(tbl.children) do
				make_copy(child, pepper)
			end
			return tbl
		end

		function PART:SetTable(tbl, copy_id)

			if copy_id then
				tbl = make_copy(table.Copy(tbl), copy_id)
			end

			local ok, err = xpcall(SetTable, ErrorNoHalt, self, tbl)
			if not ok then
				pac.Message(Color(255, 50, 50), "SetTable failed: ", err)
			end
		end
	end

	function PART:ToTable(make_copy_name)
		local tbl = {self = {ClassName = self.ClassName}, children = {}}

		for _, key in pairs(self:GetStorableVars()) do
			local var = self[key] and self["Get" .. key](self) or self[key]
			var = pac.CopyValue(var) or var

			if make_copy_name and var ~= "" and (key == "UniqueID" or key:sub(-3) == "UID") then
				var = util.CRC(var .. var)
			end

			if key == "Name" and self[key] == "" then
				var = ""
			end

			-- these arent needed because parent system uses the tree structure
			if
				key ~= "ParentUID" and
				key ~= "ParentName" and
				var ~= self.DefaultVars[key]
			then
				tbl.self[key] = var
			end
		end

		for _, part in ipairs(self:GetChildren()) do
			if not self.is_valid or self.is_deattached then

			else
				table.insert(tbl.children, part:ToTable(make_copy_name))
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
			if
				key ~= "ParentUID" and
				key ~= "ParentName"
			then
				tbl.self[key] = var
			end
		end

		for _, part in ipairs(self:GetChildren()) do
			if not self.is_valid or self.is_deattached then

			else
				table.insert(tbl.children, part:ToSaveTable())
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
					if key == "UniqueID" then continue end

					if self["Set" .. key] then
						if key == "Material" then
							table.insert(self.delayed_variables, {key = key, val = value})
						end
						self["Set" .. key](self, value)
					elseif key ~= "ClassName" then
						pac.dprint("settable: unhandled key [%q] = %q", key, tostring(value))
					end
				end

				for _, value in pairs(tbl.children) do
					local part = pac.CreatePart(value.self.ClassName, self:GetPlayerOwner())
					part:SetUndoTable(value)
					part:SetParent(self)
				end
			end

			function PART:SetUndoTable(tbl)
				local ok, err = xpcall(SetTable, ErrorNoHalt, self, tbl)
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
					continue
				end

				tbl.self[key] = pac.CopyValue(self["Get" .. key](self))
			end

			for _, part in ipairs(self:GetChildren()) do
				if not self.is_valid or self.is_deattached then

				else
					table.insert(tbl.children, part:ToUndoTable())
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
		part:SetTable(self:ToTable(true))

		part:SetParent(self:GetParent())

		return part
	end
end

function PART:CallEvent(event, ...)
	self:OnEvent(event, ...)
	for _, part in ipairs(self:GetChildren()) do
		part:CallEvent(event, ...)
	end
end

do -- events
	function PART:Initialize() end
	function PART:OnRemove() end

	function PART:IsDeattached()
		return self.is_deattached
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

		self:DeattachChildren()
	end

	function PART:DeattachFull()
		self:Deattach()

		if self:HasParent() then
			self:GetParent():RemoveChild(self)
		end
	end

	function PART:OnOtherPartCreated(part)
		local owner_id = part:GetPlayerOwnerId()
		if not owner_id then return end
		if not self.unresolved_uid_parts then return end
		if not self.unresolved_uid_parts[owner_id] then return end
		local keys = self.unresolved_uid_parts[owner_id][part.UniqueID]

		if not keys then return end

		for _, key in pairs(keys) do
			self["Set" .. key](self, part)
		end

		if self:GetPlayerOwner() == pac.LocalPlayer then
			pac.CallHook("OnPartCreated", self)
		end
	end

	function PART:Remove(skip_removechild)
		self:Deattach()

		if not skip_removechild and self:HasParent() then
			self:GetParent():RemoveChild(self)
		end

		self:RemoveChildren()
	end

	function PART:OnStore() end
	function PART:OnRestore() end

	function PART:OnThink() end

	function PART:OnParent() end
	function PART:OnChildAdd() end
	function PART:OnUnParent() end

	function PART:OnHide() end
	function PART:OnShow() end

	function PART:OnSetOwner(ent) end

	function PART:OnEvent(event, ...) end
end

function PART:CalcShowHide()
	local b, byEvent = self:IsHidden()
	local triggerUpdate = b ~= self.last_hidden or self.last_hidden_by_event ~= byEvent
	if not triggerUpdate then return end

	if b ~= self.last_hidden then
		if b then
			self:OnHide()
		else
			self:OnShow(self.shown_from_rendering == true or self.shown_from_rendering == FrameNumber())
		end
	end

	if FrameNumber() ~= self.shown_from_rendering then
		self.shown_from_rendering = nil
	end

	self.last_hidden = b
	self.last_hidden_by_event = byEvent
end

function PART:CThink()
	if self.ThinkTime == 0 then
		if self.last_think ~= pac.FrameNumber then
			self:Think()
			self.last_think = pac.FrameNumber
		end
	elseif not self.last_think or self.last_think < pac.RealTime then
		self:Think()
		self.last_think = pac.RealTime + (self.ThinkTime or 0.1)
	end
end

function PART:Think()
	if not self:GetEnabled() then return end

	self:CalcShowHide()

	if not self.AlwaysThink and self:IsHidden() then return end

	local owner = self:GetOwner()

	if owner:IsValid() then
		if owner ~= self.last_owner then
			self.last_hidden = false
			self.last_hidden_by_event = false
			self.last_owner = owner
		end
	end

	if self.delayed_variables then

		for _, data in ipairs(self.delayed_variables) do
			self["Set" .. data.key](self, data.val)
		end

		self.delayed_variables = nil
	end
	self:OnThink()
end


function PART:SubmitToServer()
	pac.SubmitPart(self:ToTable())
end

PART.is_valid = true

function PART:IsValid()
	return self.is_valid
end


BUILDER:Register()
