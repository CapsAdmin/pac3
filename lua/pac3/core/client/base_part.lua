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
	:GetSet("Enabled", true)

BUILDER
	:StartStorableVars()
		:SetPropertyGroup("generic")
			:GetSet("Name", "")
			:GetSet("Hide", false)
			:GetSet("OwnerName", "self")
			:GetSet("EditorExpand", false, {hidden = true})
			:GetSet("UniqueID", "", {hidden = true})
			:GetSetPart("Parent")
			-- this is an unfortunate name, it controls the order in which the scene related functions iterate over children
			-- in practice it's often used to make something draw above something else in translucent rendering
			:GetSet("DrawOrder", 0)
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
	self.active_events = {}
	self.active_events_ref_count = 0
end

function PART:Initialize() end

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

function PART:OnRemove() end

function PART:GetNiceName()
	return self.ClassName
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
				return
			end

			if not removed and self.OwnerName ~= "" then
				ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent, self) or NULL
				if ent ~= prev_owner then
					self:SetOwner(ent)
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

		pac.RunNextFrame(self:GetRootPart().Id .. "_hook_render", function()
			if self:IsValid() then
				self:HookEntityRender()
			end
		end)
	end

		-- unfortunate name, it will actually add the part for updating, not just rendering
	function PART:HookEntityRender()
		local root = self:GetRootPart()
		local owner = root:GetOwner()
		if root.ClassName ~= "group" then return end -- FIX ME

		if root.last_owner:IsValid() then
			pac.UnhookEntityRender(root.last_owner, root)
		end

		if owner:IsValid() then
			pac.HookEntityRender(owner, root)
		end
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

do -- scene graph

	function PART:OnParent() end
	function PART:OnChildAdd() end
	function PART:OnUnParent() end

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

		local function add_children_to_list(parent, list, drawOrder)
			for _, child in ipairs(parent:GetChildren()) do
				table.insert(list, {child, child.DrawOrder + drawOrder})
				add_children_to_list(child, list, drawOrder + child.DrawOrder)
			end
		end

		function PART:GetChildrenList()
			if not self.children_list then
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

		do
			function PART:GetParentList()
				if not self.parent_list then
					self.parent_list = {}

					local temp = self:GetParent()

					if temp:IsValid() then
						table.insert(self.parent_list, temp)

						for _ = 1, 100 do
							local parent = temp:GetParent()
							if not parent:IsValid() then break end

							table.insert(self.parent_list, parent)

							temp = parent
						end
					end
				end

				return self.parent_list
			end
		end

		function PART:InvalidateParentList()
			self.parent_list = nil
			self:CallRecursiveExcludeSelf("InvalidateParentList")
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
			self.ChildrenMap[part] = part
			table.insert(self.Children, part)
		end

		self:InvalidateChildrenList()

		part.ParentUID = self:GetUniqueID()

		part:OnParent(self)
		self:OnChildAdd(part)

		if self:HasParent() then
			self:GetParent():SortChildren()
		end

		part:SortChildren()
		self:SortChildren()

		self:InvalidateParentList()
		part:InvalidateParentList()

		if self:GetPlayerOwner() == pac.LocalPlayer then
			pac.CallHook("OnPartParent", self, part)
		end

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
		if list[1] then
			return list[#list]
		end
		return self
	end

	function PART:CallRecursive(func, ...)
		if self[func] then
			self[func](self, ...)
		end

		for _, child in ipairs(self:GetChildren()) do
			child:CallRecursive(func, ...)
		end
	end

	function PART:CallRecursiveExcludeSelf(func, ...)
		for _, child in ipairs(self:GetChildren()) do
			child:CallRecursive(func, ...)
		end
	end

	function PART:SetKeyValueRecursive(key, val)
		self[key] = val

		for _, child in ipairs(self:GetChildren()) do
			child:SetKeyValueRecursive(key, val)
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

		for i, part in ipairs(self:GetChildren()) do
			local owner_id = part:GetPlayerOwnerId()

			if owner_id then
				pac.RemoveUniqueIDPart(owner_id, part.UniqueID)
			end

			pac.RemovePart(part)
		end
	end

end

do -- hidden / events
	function PART:OnHide() end
	function PART:OnShow() end

	function PART:SetEnabled(val)
		self.Enabled = val
		print(self, val)
		if val then
			self:ShowFromRendering()
		else
			self:HideFromRendering()
		end
	end

	function PART:IsDrawHidden()
		return self.draw_hidden
	end

	function PART:SetDrawHidden(b)
		self.draw_hidden = b
	end

	function PART:ShowFromRendering()
		self:SetDrawHidden(true)

		if not self:IsHidden() then
			self:OnShow(true)
		end

		for _, child in ipairs(self:GetChildrenList()) do
			if not child:IsHidden() then
				child:OnShow(true)
			end
		end
	end

	function PART:HideFromRendering()
		self:SetDrawHidden(false)
		self:CallRecursive("OnHide", true)
	end

	local function is_hidden(part, ignored_event_part)
		if part.active_events_ref_count > 0 then
			if not ignored_event_part or not part.active_events[ignored_event_part] then
				return true
			end
		end

		return part.Hide
	end

	function PART:IsHidden(ignored_event_part, only_self)
		if is_hidden(self, ignored_event_part) then
			return true
		end

		if only_self then return false end

		for _, parent in ipairs(self:GetParentList()) do
			if is_hidden(parent, ignored_event_part) then
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
				self:CalcShowHide()
			end
		else
			if self.active_events[event_part] then
				self.active_events[event_part] = nil
				self.active_events_ref_count = self.active_events_ref_count - 1
				self:CalcShowHide()
			end
		end
	end

	function PART:CalcShowHide()
		local b = self:IsHidden()

		if b ~= self.last_hidden then
			if b then
				self:OnHide()
			else
				self:OnShow()
			end
		end

		self.last_hidden = b
	end

	function PART:IsHiddenCached()
		return self.last_hidden
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
			if key ~= "ParentUID" and var ~= self.DefaultVars[key] then
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
			if key ~= "ParentUID" then
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

do
	local function think(self)
		self:CalcShowHide()

		if not self.AlwaysThink and self:IsHiddenCached() then return end

		local owner = self:GetOwner()

		if owner:IsValid() then
			if owner ~= self.last_owner then
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

	function PART:Think()
		if not self.Enabled then return end

		if self.ThinkTime == 0 then
			think(self)
		elseif not self.last_think or self.last_think < pac.RealTime then
			think(self)
			self.last_think = pac.RealTime + (self.ThinkTime or 0.1)
		end
	end

	function PART:OnThink() end
end

BUILDER:Register()
