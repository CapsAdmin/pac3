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

local function SETUP_CACHE_FUNC(tbl, func_name)
	local old_func = tbl[func_name]

	local cached_key = "cached_" .. func_name
	local cached_key2 = "cached_" .. func_name .. "_2"
	local last_key = "last_" .. func_name .. "_framenumber"

	tbl[func_name] = function(self, a,b,c,d,e)
		if self[last_key] ~= pac.FrameNumber or self[cached_key] == nil then
			self[cached_key], self[cached_key2] = old_func(self, a,b,c,d,e)
			self[last_key] = pac.FrameNumber
		end

		return self[cached_key], self[cached_key2]
	end
end

local PART = {}

PART.ClassName = "base"
PART.Internal = true

function PART:__tostring()
	return string.format("%s[%s][%s][%i]", self.Type, self.ClassName, self.Name, self.Id)
end

local pac_hide_disturbing = GetConVar("pac_hide_disturbing")

pac.GetSet(PART, "BoneIndex")
pac.GetSet(PART, "PlayerOwner", NULL)
pac.GetSet(PART, "Owner", NULL)

pac.StartStorableVars()

	pac.SetPropertyGroup(PART, "generic")
		pac.GetSet(PART, "Name", "")
		pac.GetSet(PART, "Hide", false)
		pac.GetSet(PART, "OwnerName", "self")
		pac.GetSet(PART, "EditorExpand", false, {hidden = true})
		pac.GetSet(PART, "UniqueID", "", {hidden = true})
		pac.GetSet(PART, "IsDisturbing", false, {
			editor_friendly = "IsExplicit",
			description = "Marks this content as NSFW, and makes it hidden for most of players who have pac_hide_disturbing set to 1"
		})

	pac.SetPropertyGroup(PART, "orientation")
		pac.GetSet(PART, "Bone", "head")
		pac.GetSet(PART, "Position", Vector(0,0,0))
		pac.GetSet(PART, "Angles", Angle(0,0,0))
		pac.GetSet(PART, "EyeAngles", false)
		pac.GetSet(PART, "PositionOffset", Vector(0,0,0))
		pac.GetSet(PART, "AngleOffset", Angle(0,0,0))
		pac.SetupPartName(PART, "AimPart", {editor_panel = "aimpartname"})
		pac.SetupPartName(PART, "Parent")

	pac.SetPropertyGroup(PART, "appearance")
		pac.GetSet(PART, "Translucent", false)
		pac.GetSet(PART, "IgnoreZ", false)
		pac.GetSet(PART, "NoTextureFiltering", false)
		pac.GetSet(PART, "BlendMode", "", {enums = {
			none = "one;zero;one;zero",
			alpha = "src_alpha;one_minus_src_alpha;one;one_minus_src_alpha",
			multiplicative = "dst_color;zero;dst_color;zero",
			premultiplied = "one;one_src_minus_alpha;one;one_src_minus_alpha",
			additive = "src_alpha;one;src_alpha;one",
		}})

		pac.GetSet(PART, "DrawOrder", 0)

pac.EndStorableVars()

PART.AllowSetupPositionFrameSkip = true

local blend_modes = {
	zero = 0,
	one = 1,
	dst_color = 2,
	one_minus_dst_color = 3,
	src_alpha = 4,
	one_minus_src_alpha = 5,
	dst_alpha = 6,
	one_minus_dst_alpha = 7,
	src_alpha_saturate = 8,
	src_color = 9,
	one_minus_src_color = 10,
}

function PART:SetBlendMode(str)
	str = str:lower():gsub("%s+", ""):gsub(",", ";"):gsub("blend_", "")

	self.BlendMode = str

	local tbl = str:Split(";")
	local src_color
	local dst_color

	local src_alpha
	local dst_alpha

	if tbl[1] then src_color = blend_modes[tbl[1]] end
	if tbl[2] then dst_color = blend_modes[tbl[2]] end

	if tbl[3] then src_alpha = blend_modes[tbl[3]] end
	if tbl[4] then dst_alpha = blend_modes[tbl[4]] end

	if src_color and dst_color then
		self.blend_override = {src_color, dst_color, src_alpha, dst_alpha, tbl[5]}
	else
		self.blend_override = nil
	end
end

function PART:SetUniqueID(id)
	if self.owner_id then
		pac.RemoveUniqueIDPart(self.owner_id, self.UniqueID)
	end

	self.UniqueID = id

	if self.owner_id then
		pac.SetUniqueIDPart(self.owner_id, id, self)
	end
end

function PART:PreInitialize()
	self.Children = {}
	self.Children2 = {}
	self.modifiers = {}
	self.RootPart = NULL
	self.DrawOrder = 0
	self.hide_disturbing = false

	self.cached_pos = Vector(0,0,0)
	self.cached_ang = Angle(0,0,0)
end

function PART:GetNiceName()
	return self.ClassName
end

function PART:RemoveOnNULLOwner(b)
	self.remove_on_null_owner = b
end

function PART:GetName()
	if self.Name == "" then

		if self.last_nice_name_frame and self.last_nice_name_frame == FrameNumber() then
			return self.last_nice_name
		end

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
		self.last_nice_name_frame = FrameNumber()

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

do -- modifiers
	PART.HandleModifiersManually = false

	function PART:AddModifier(part)
		self:RemoveModifier(part)
		table.insert(self.modifiers, part)
	end

	function PART:RemoveModifier(part)
		for i, v in ipairs(self.modifiers) do
			if v == part then
				table.remove(self.modifiers, i)
				break
			end
		end
	end

	function PART:ModifiersPreEvent(event)
		if #self.modifiers > 0 then
			for _, part in ipairs(self.modifiers) do
				if not part:IsHidden() then

					if not part.pre_draw_events then part.pre_draw_events = {} end
					if not part.pre_draw_events[event] then part.pre_draw_events[event] = "Pre" .. event end

					if part[part.pre_draw_events[event]] then
						part[part.pre_draw_events[event]](part)
					end
				end
			end
		end
	end

	function PART:ModifiersPostEvent(event)
		if #self.modifiers > 0 then
			for _, part in ipairs(self.modifiers) do
				if not part:IsHidden() then

					if not part.post_draw_events then part.post_draw_events = {} end
					if not part.post_draw_events[event] then part.post_draw_events[event] = "Post" .. event end

					if part[part.post_draw_events[event]] then
						part[part.post_draw_events[event]](part)
					end
				end
			end
		end
	end

end

do -- owner
	function PART:SetPlayerOwner(ply)
		self.PlayerOwner = ply

		if ply:IsValid() then
			self.owner_id = ply:IsPlayer() and ply:UniqueID() or ply:EntIndex()
		end

		if not self:HasParent() then
			self:CheckOwner()
		end

		self:SetUniqueID(self:GetUniqueID())
	end
	function PART:SetOwnerName(name)
		self.OwnerName = name
		self:CheckOwner()
	end

	function PART:CheckOwner(ent, removed)
		local part = self:GetRootPart()

		if part ~= self then
			return part:CheckOwner(ent, removed)
		end

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
		self.last_owner = self.Owner
		self.Owner = ent or NULL
		pac.RunNextFrame(self:GetRootPart().Id .. "_hook_render", function()
			if self:IsValid() then
				self:HookEntityRender()
			end
		end)
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

	--SETUP_CACHE_FUNC(PART, "GetOwner")
end

function PART:SetIsDisturbing(val)
	self.IsDisturbing = val
	self.hide_disturbing = pac_hide_disturbing:GetBool() and val
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

		self:ClearBone()
		part:ClearBone()

		part:OnParent(self)
		self:OnChildAdd(part)

		if self:HasParent() then
			self:GetParent():SortChildren()
		end

		part:SortChildren()
		self:SortChildren()

		self:BuildParentList()

		pac.CallHook("OnPartParent", self, part)

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

	SETUP_CACHE_FUNC(PART, "GetRootPart")

	do
		local function doRecursiveCall(childrens, func, profileName, profileNameChildren, ...)
			for i, child in ipairs(childrens) do
				local sysTime = SysTime()
				child[func](child, func, ...)
				child[profileName] = SysTime() - sysTime

				sysTime = SysTime()
				doRecursiveCall(child:GetChildren(), func, profileName, profileNameChildren, ...)
				child[profileNameChildren] = SysTime() - sysTime
			end
		end

		function PART:CallRecursiveProfiled(func, ...)
			local profileName = func .. 'Runtime'
			local profileNameChildren = func .. 'RuntimeChildren'

			if self[func] then
				local sysTime = SysTime()
				self[func](self, ...)
				self[profileName] = SysTime() - sysTime
			end

			local sysTime = SysTime()
			doRecursiveCall(self:GetChildren(), func, profileName, profileNameChildren, ...)
			self[profileNameChildren] = SysTime() - sysTime
		end

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

		function PART:SetEventHide(b)
			if self.event_hidden ~= b and self.event_hidden ~= nil then
				self.shown_from_rendering = nil
			end

			self.event_hidden = b
		end

		function PART:FlushFromRenderingState(newState)
			self.shown_from_rendering = nil
		end

		function PART:IsDrawHidden()
			return self.draw_hidden
		end

		function PART:IsEventHidden()
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
				self.event_hidden
			then
				return true, self.event_hidden
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
					return true, parent.event_hidden
				end
			end

			return false
		end

		SETUP_CACHE_FUNC(PART, "IsHidden")
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
			if part.owner_id and part.UniqueID then
				pac.RemoveUniqueIDPart(part.owner_id, part.UniqueID)
			end

			pac.RemovePart(part)
		end
	end

	function PART:UnParent()
		local parent = self:GetParent()

		if parent:IsValid() then
			parent:RemoveChild(self)
		end

		self:ClearBone()

		self:OnUnParent(parent)

		self.Parent = NULL
		self.ParentName = ""
		self.ParentUID = ""

		self:CallRecursive("OnHide")
	end
end

do -- bones
	function PART:SetBone(var)
		self.Bone = var
		self:ClearBone()
	end

	function PART:ClearBone()
		self.BoneIndex = nil
		self.TriedToFindBone = nil
		local owner = self:GetOwner()
		if owner:IsValid() then
			owner.pac_bones = nil
		end
	end

	function PART:GetModelBones(owner)
		return pac.GetModelBones(owner or self:GetOwner())
	end

	function PART:GetRealBoneName(name, owner)
		owner = owner or self:GetOwner()

		local bones = self:GetModelBones(owner)

		if owner:IsValid() and bones and bones[name] and not bones[name].is_special then
			return bones[name].real
		end

		return name
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

	do
		local function SetTable(self, tbl)
			self.supress_part_name_find = true
			self.delayed_variables = self.delayed_variables or {}

			-- this needs to be set first
			self:SetUniqueID(tbl.self.UniqueID or util.CRC(tostring(tbl.self)))

			for key, value in pairs(tbl.self) do

				-- these arent needed because parent system uses the tree structure
				local cond = key ~= "ParentUID" and
					key ~= "ParentName" and
					key ~= "UniqueID" and
					(key ~= "AimPartName" and not (self.IngoreSetKeys and self.IngoreSetKeys[key]) or
					key == "AimPartName" and table.HasValue(pac.AimPartNames, value))

				if cond then
					if self["Set" .. key] then
						if key == "Material" then
							table.insert(self.delayed_variables, {key = key, val = value})
						end

						self["Set" .. key](self, value)
					elseif key ~= "ClassName" then
						pac.dprint("settable: unhandled key [%q] = %q", key, tostring(value))
					end
				end
			end

			for _, value in pairs(tbl.children) do
				local part = pac.CreatePart(value.self.ClassName, self:GetPlayerOwner())
				part:SetIsBeingWorn(self:IsBeingWorn())
				part:SetTable(value)
				part:SetParent(self)
			end
		end

		function PART:SetTable(tbl)
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
			var = pac.class.Copy(var) or var

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
			table.insert(tbl.children, part:ToTable(make_copy_name))
		end

		return tbl
	end

	function PART:ToSaveTable()
		if self:GetPlayerOwner() ~= LocalPlayer() then return end

		local tbl = {self = {ClassName = self.ClassName}, children = {}}

		for _, key in pairs(self:GetStorableVars()) do
			local var = self[key] and self["Get" .. key](self) or self[key]
			var = pac.class.Copy(var) or var

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
			table.insert(tbl.children, part:ToSaveTable())
		end

		return tbl
	end

	function PART:GetVars()
		local tbl = {}

		for _, key in pairs(self:GetStorableVars()) do
			tbl[key] = pac.class.Copy(self[key])
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
		self:OnRemove()

		if self.owner_id and self.UniqueID then
			pac.RemoveUniqueIDPart(self.owner_id, self.UniqueID)
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

	function PART:Attach(parent)
		if not self.is_deattached then
			return self:SetParent(parent)
		end

		self.is_deattached = false
		self.is_valid = true
		self:CallRecursive("OnShow")
		self:SetParent(parent)

		if self.SetPlayerOwner then
			self:SetPlayerOwner(self.PlayerOwner_)
		end

		timer.Simple(0.1, function()
			if self:IsValid() and self.show_in_editor ~= false and self.PlayerOwner_ == pac.LocalPlayer then
				pac.CallHook("OnPartCreated", self)
			end
		end)

		pac.AddPart(self)
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
	function PART:OnBuildBonePositions() end
	function PART:OnParent() end
	function PART:OnChildAdd() end
	function PART:OnUnParent() end
	function PART:Highlight() end

	function PART:OnHide() end
	function PART:OnShow() end

	function PART:OnSetOwner(ent) end

	function PART:OnEvent(event, ...) end
end

function PART:Highlight(skip_children, data)
	local tbl = {self.Entity and self.Entity:IsValid() and self.Entity or nil}

	if not skip_children then
		for _, part in ipairs(self:GetChildren()) do
			local ent = part.Entity

			if ent and ent:IsValid() then
				table.insert(tbl, ent)
			end
		end
	end

	if #tbl > 0 then
		if data then
			pac.haloex.Add(tbl, unpack(data))
		else
			local pulse = math.abs(1 + math.sin(pac.RealTime * 20) * 255)
			pulse = pulse + 2
			pac.haloex.Add(tbl, Color(pulse, pulse, pulse, 255), 1, 1, 1, true, true, 5, 1, 1)
		end
	end
end

do -- drawing. this code is running every frame
	PART.cached_pos = Vector(0, 0, 0)
	PART.cached_ang = Angle(0, 0, 0)

	function PART:DrawChildren(event, pos, ang, draw_type, drawAll)
		if drawAll then
			for i, child in ipairs(self:GetChildrenList()) do
				child:Draw(pos, ang, draw_type, true)
			end
		else
			for i, child in ipairs(self:GetChildren()) do
				child:Draw(pos, ang, draw_type)
			end
		end
	end

	--function PART:Draw(pos, ang, draw_type, isNonRoot)
	function PART:Draw(pos, ang, draw_type)
		-- Think takes care of polling this
		if not self.last_enabled then return end

		if self:IsHidden() then return end

		if
			self.OnDraw and
			(
				draw_type == "viewmodel" or draw_type == "hands" or
				((self.Translucent == true or self.force_translucent == true) and draw_type == "translucent")  or
				((self.Translucent == false or self.force_translucent == false) and draw_type == "opaque")
			)
		then
			local sysTime = SysTime()
			pos, ang = self:GetDrawPosition()

			self.cached_pos = pos
			self.cached_ang = ang

			if not self.PositionOffset:IsZero() or not self.AngleOffset:IsZero() then
				pos, ang = LocalToWorld(self.PositionOffset, self.AngleOffset, pos, ang)
			end

			if not self.HandleModifiersManually then self:ModifiersPreEvent('OnDraw', draw_type) end

			if self.IgnoreZ then cam.IgnoreZ(true) end

			if self.blend_override then
				render.OverrideBlendFunc(true,
					self.blend_override[1],
					self.blend_override[2],
					self.blend_override[3],
					self.blend_override[4]
				)

				if self.blend_override[5] then
					render.OverrideAlphaWriteEnable(true, self.blend_override[5] == "write_alpha")
				end

				if self.blend_override[6] then
					render.OverrideColorWriteEnable(true, self.blend_override[6] == "write_color")
				end
			end

			if self.NoTextureFiltering then
				render.PushFilterMin(TEXFILTER.POINT)
				render.PushFilterMag(TEXFILTER.POINT)
			end

			self:OnDraw(self:GetOwner(), pos, ang)

			if self.NoTextureFiltering then
				render.PopFilterMin()
				render.PopFilterMag()
			end

			if self.blend_override then
				render.OverrideBlendFunc(false)

				if self.blend_override[5] then
					render.OverrideAlphaWriteEnable(false)
				end

				if self.blend_override[6] then
					render.OverrideColorWriteEnable(false)
				end
			end

			if self.IgnoreZ then cam.IgnoreZ(false) end

			if not self.HandleModifiersManually then self:ModifiersPostEvent('OnDraw', draw_type) end
			self.selfDrawTime = SysTime() - sysTime
		end

		-- if not isNonRoot then
		--  for i, child in ipairs(self:GetChildrenList()) do
		--      child:Draw(pos, ang, draw_type, true)
		--  end
		-- end

		local sysTime = SysTime()

		for _, child in ipairs(self:GetChildren()) do
			child:Draw(pos, ang, draw_type)
		end

		if draw_type == "translucent" then
			self.childrenTranslucentDrawTime = SysTime() - sysTime
		elseif draw_type == "opaque" then
			self.childrenOpaqueDrawTime = SysTime() - sysTime
		end
	end

	function PART:GetDrawPosition(bone_override, skip_cache)
		if not self.AllowSetupPositionFrameSkip or pac.FrameNumber ~= self.last_drawpos_framenum or not self.last_drawpos or skip_cache then
			self.last_drawpos_framenum = pac.FrameNumber

			local owner = self:GetOwner()
			if owner:IsValid() then
				local pos, ang = self:GetBonePosition(bone_override, skip_cache)

				pos, ang = LocalToWorld(
					self.Position or Vector(),
					self.Angles or Angle(),
					pos or owner:GetPos(),
					ang or owner:GetAngles()
				)

				ang = self:CalcAngles(ang) or ang

				self.last_drawpos = pos
				self.last_drawang = ang

				return pos, ang
			end
		end

		return self.last_drawpos, self.last_drawang
	end

	function PART:GetBonePosition(bone_override, skip_cache)
		if not self.AllowSetupPositionFrameSkip or pac.FrameNumber ~= self.last_bonepos_framenum or not self.last_bonepos or skip_cache then
			self.last_bonepos_framenum = pac.FrameNumber

			local owner = self:GetOwner()
			local parent = self:GetParent()

			if parent:IsValid() and parent.ClassName == "jiggle" then
				if skip_cache then
					if parent.Translucent then
						parent:Draw(nil, nil, "translucent")
					else
						parent:Draw(nil, nil, "opaque")
					end
				end

				return parent.pos, parent.ang
			end

			local pos, ang

			if parent:IsValid() and not parent.NonPhysical then
				local ent = parent.Entity or NULL

				if ent:IsValid() then
					-- if the parent part is a model, get the bone position of the parent model
					if ent.pac_bone_affected ~= FrameNumber() then
						ent:InvalidateBoneCache()
					end

					pos, ang = pac.GetBonePosAng(ent, bone_override or self.Bone)
				else
					-- else just get the origin of the part
					-- unless we've passed it from parent
					pos, ang = parent:GetDrawPosition()
				end
			elseif owner:IsValid() then
				-- if there is no parent, default to owner bones
				owner:InvalidateBoneCache()
				pos, ang = pac.GetBonePosAng(owner, self.Bone)
			end

			self.last_bonepos = pos
			self.last_boneang = ang

			return pos, ang
		end

		return self.last_bonepos, self.last_boneang
	end

	-- since this is kind of like a hack I choose to have upper case names to avoid name conflicts with parts
	-- the editor can use the keys as friendly names
	pac.AimPartNames =
	{
		["local eyes"] = "LOCALEYES",
		["player eyes"] = "PLAYEREYES",
		["local eyes yaw"] = "LOCALEYES_YAW",
		["local eyes pitch"] = "LOCALEYES_PITCH",
	}

	function PART:CalcAngles(ang)
		local owner = self:GetOwner(true)

		if pac.StringFind(self.AimPartName, "LOCALEYES_YAW", true, true) then
			ang = (pac.EyePos - self.cached_pos):Angle()
			ang.p = 0
			return self.Angles + ang
		end

		if pac.StringFind(self.AimPartName, "LOCALEYES_PITCH", true, true) then
			ang = (pac.EyePos - self.cached_pos):Angle()
			ang.y = 0
			return self.Angles + ang
		end

		if pac.StringFind(self.AimPartName, "LOCALEYES", true, true) then
			return self.Angles + (pac.EyePos - self.cached_pos):Angle()
		end


		if pac.StringFind(self.AimPartName, "PLAYEREYES", true, true) then
			local ent = owner.pac_traceres and owner.pac_traceres.Entity or NULL

			if ent:IsValid() then
				return self.Angles + (ent:EyePos() - self.cached_pos):Angle()
			end

			return self.Angles + (pac.EyePos - self.cached_pos):Angle()
		end

		if self.AimPart:IsValid() then
			return self.Angles + (self.AimPart.cached_pos - self.cached_pos):Angle()
		end

		if self.EyeAngles then
			if owner:IsPlayer() then
				return self.Angles + ((owner.pac_hitpos or owner:GetEyeTraceNoCursor().HitPos) - self.cached_pos):Angle()
			elseif owner:IsNPC() then
				return self.Angles + ((owner:EyePos() + owner:GetForward() * 100) - self.cached_pos):Angle()
			end
		end

		return ang or Angle(0,0,0)
	end

	--SETUP_CACHE_FUNC(PART, "CalcAngles")
end

function PART:CalcShowHide()
	local b, byEvent = self:IsHidden()
	local triggerUpdate = b ~= self.last_hidden or self.last_hidden_by_event ~= byEvent

	if not triggerUpdate then return end

	if b ~= self.last_hidden then
		if b then
			self:OnHide()
		else
			self:OnShow(self.shown_from_rendering ~= nil)
		end
	end

	if FrameNumber() ~= self.shown_from_rendering then
		self.shown_from_rendering = nil
	end

	self.last_hidden = b
	self.last_hidden_by_event = byEvent
end

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
			self.last_hidden = nil
			self.last_hidden_by_event = nil
			self.last_owner = owner
		end

		if not owner.pac_bones then
			self:GetModelBones()
		end
	end

	if self.ResolvePartNames then
		self:ResolvePartNames()
	end

	if self.delayed_variables then

		for _, data in ipairs(self.delayed_variables) do
			self["Set" .. data.key](self, data.val)
		end

		self.delayed_variables = nil
	end

	self:OnThink()

	self.supress_part_name_find = false
end

function PART:BuildBonePositions()
	if not self:IsHidden() then
		self:OnBuildBonePositions()
	end
end

function PART:SubmitToServer()
	pac.SubmitPart(self:ToTable())
end

PART.is_valid = true

function PART:IsValid()
	return self.is_valid
end

function PART:SetDrawOrder(num)
	self.DrawOrder = num
	if self:HasParent() then self:GetParent():SortChildren() end
end

pac.RegisterPart(PART)
