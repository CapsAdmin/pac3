jit.on(true, true)

local pac = pac

local function SETUP_CACHE_FUNC(tbl, func_name)
	local old_func = tbl[func_name]

	local cached_key = "cached_" .. func_name
	local last_key = "last_" .. func_name .. "_framenumber"

	tbl[func_name] = function(self, a,b,c,d,e)

		if self[last_key] ~= pac.FrameNumber or self[cached_key] == nil then
			self[cached_key] = old_func(self, a,b,c,d,e)
			self[last_key] = pac.FrameNumber
		end

		return self[cached_key]
	end
end

local pairs = pairs
local pac = pac
local table = table
local Vector = Vector
local Angle = Angle

local PART = {}

PART.ClassName = "base"
PART.Internal = true

function PART:__tostring()
	return string.format("%s[%s][%s][%i]", self.Type, self.ClassName, self.Name, self.Id)
end

pac.GetSet(PART, "BoneIndex")
pac.GetSet(PART, "PlayerOwner", NULL)
pac.GetSet(PART, "Owner", NULL)

pac.StartStorableVars()
	pac.GetSet(PART, "OwnerName", "self")
	pac.GetSet(PART, "Bone", "head")
	pac.GetSet(PART, "Position", Vector(0,0,0))
	pac.GetSet(PART, "Angles", Angle(0,0,0))
	pac.GetSet(PART, "EyeAngles", false)
	pac.GetSet(PART, "Name", "")
	pac.GetSet(PART, "Description", "")
	pac.GetSet(PART, "Hide", false)
	pac.GetSet(PART, "DrawOrder", 0)
	pac.GetSet(PART, "Translucent", false)

	pac.GetSet(PART, "PositionOffset", Vector(0,0,0))
	pac.GetSet(PART, "AngleOffset", Angle(0,0,0))

	pac.GetSet(PART, "EditorExpand", false)
	pac.GetSet(PART, "UniqueID", "")

	pac.SetupPartName(PART, "AnglePart")
	pac.GetSet(PART, "AnglePartMultiplier", Vector(1,1,1))

	pac.SetupPartName(PART, "AimPart")

	pac.SetupPartName(PART, "Parent")
pac.EndStorableVars()

function PART:SetUniqueID(id)
	if self.owner_id then
		pac.UniqueIDParts[self.owner_id] = pac.UniqueIDParts[self.owner_id] or {}
		pac.UniqueIDParts[self.owner_id][self.UniqueID] = nil
	end

	self.UniqueID = id

	if self.owner_id then
		pac.UniqueIDParts[self.owner_id][id] = self
	end
end

function PART:PreInitialize()
	self.Children = {}
	self.modifiers = {}
	self.RootPart = NULL

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

		local nice = self:GetNiceName()
		local num
		local count = 0

		if self:HasParent() then
			for key, val in pairs(self:GetParent():GetChildren()) do
				if val:GetNiceName() == self:GetNiceName() then
					count = count + 1

					if val == self then
						num = count
					end
				end
			end
		end

		if num and count > 1 then
			nice = nice .. " " .. num
		end


		self.last_nice_name = nice

		return nice
	end

	return self.Name
end

function PART:GetEnabled()

	local enabled = self:IsEnabled()

	if self.last_enabled==enabled then
		return enabled
	end

	-- changed

	if self.last_enabled == nil then
		self.last_enabled = enabled
	else
		self.last_enabled = enabled

		if enabled then
			self:CallRecursive("OnShow")
			--Msg"OnShow"print(self)
		else
			self:CallRecursive("OnHide")
			--Msg"OnHide"print(self)
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
		for k,v in pairs(self.modifiers) do
			if v == part then
				table.remove(self.modifiers, k)
				break
			end
		end
	end

	function PART:ModifiersPreEvent(event)
		if #self.modifiers > 0 then
			for _, part in pairs(self.modifiers) do
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
			for _, part in pairs(self.modifiers) do
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

			local ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent, self, function(ent) return ent.pac_duplicate_attach_uid ~= self.UniqueID end) or NULL

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
				self:SetOwner()
				self.temp_hidden = true
				return
			end

			if not removed and self.OwnerName ~= "" then
				local ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent, self) or NULL
				if ent ~= prev_owner then
					self:SetOwner(ent)
					self.temp_hidden = false
					return true
				end
			end

		end
	end

	function PART:SetOwner(ent)
		local root = self:GetRootPart()

		pac.RunNextFrame(self, function()
			local ent = self.Owner

			if ent:IsValid() then

				if self.last_owner and self.last_owner ~= ent then
					pac.UnhookEntityRender(self.last_owner, root)
				end

				pac.HookEntityRender(ent, root)
				self.last_owner = ent
			else
				pac.UnhookEntityRender(ent, root)
			end
		end)

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
		if root then
			return self:GetRootPart():GetOwner()
		end

		local parent = self:GetParent()

		if parent:IsValid() then
			if
				self.ClassName ~= "event" and
				parent.ClassName == "model" and
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

do -- parenting
	function PART:GetChildren()
		return self.Children
	end

	function PART:CreatePart(name)
		local part = pac.CreatePart(name, self:GetPlayerOwner())
		if not part then return end
		part:SetParent(self)
		return part
	end

	function PART:SetParent(var)
		if not var or not var:IsValid() then
			self:UnParent()
			return false
		else
			return var:AddChild(self)
		end
	end

	function PART:BuildParentList()

		if not self:HasParent() then return end

		self.parent_list = {}

		local temp = self:GetParent()

		table.insert(self.parent_list, temp)

		for i = 1, 100 do
			local parent = temp:GetParent()

			if parent:IsValid() then
				table.insert(self.parent_list, parent)
				temp = parent
			else
				break
			end
		end

		self.RootPart = temp

		for key, part in pairs(self.Children) do
			part:BuildParentList()
		end
	end

	function PART:AddChild(var)
		if not var or not var:IsValid() then
			self:UnParent()
			return
		end

		if self == var or var:HasChild(self) then
			return false
		end

		var:UnParent()

		var.Parent = self

		if not table.HasValue(self.Children, var) then
			table.insert(self.Children, var)
		end

		var.ParentName = self:GetName()
		var.ParentUID = self:GetUniqueID()

		self:ClearBone()
		var:ClearBone()

		var:OnParent(self)
		self:OnChildAdd(var)

		if self:HasParent() then
			self:GetParent():SortChildren()
		end

		var:SortChildren()
		self:SortChildren()

		self:BuildParentList()

		pac.CallHook("OnPartParent", self, var)

		var:SetKeyValueRecursive("last_hidden", nil)

		return var.Id
	end

	local sort = function(a, b)
		if a and b then
			return a.DrawOrder < b.DrawOrder
		end
	end

	function PART:SortChildren()
		self.DrawOrder = self.DrawOrder or 0
		local new = {}
		for key, val in pairs(self.Children) do
			table.insert(new, val)
			val:SortChildren()
		end
		self.Children = new
		table.sort(self.Children, sort)
	end

	function PART:HasParent()
		return self.Parent:IsValid()
	end

	function PART:HasChildren()
		return next(self.Children) ~= nil
	end

	function PART:HasChild(part)
		for key, child in pairs(self.Children) do
			if child == part or child:HasChild(part) then
				return true
			end
		end
		return false
	end

	function PART:RemoveChild(var)
		for key, part in pairs(self.Children) do
			if part == var then
				self.Children[key] = nil
				if self:HasParent() then
					self:GetParent():SortChildren()
				end
				part:OnUnParent(self)
				break
			end
		end

		self:SortChildren()
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
		function PART:CallRecursive(func, ...)
			if self[func] then
				self[func](self, ...)
			end

			for k, v in pairs(self.Children) do
				v:CallRecursive(func, ...)
			end
		end

		function PART:SetKeyValueRecursive(key, val)
			self[key] = val

			for k,v in pairs(self.Children) do
				v:SetKeyValueRecursive(key, val)
			end
		end

		function PART:SetHide(b)
			self.Hide = b

			self:SetKeyValueRecursive("hidden", b)
		end

		function PART:SetEventHide(b)
			self.event_hidden = b
		end

		function PART:IsHidden()
			if
				self.draw_hidden or
				self.temp_hidden or
				self.hidden or
				self.event_hidden
			then return true end

			if not self:HasParent() then return false end

			if not self.parent_list then
				self:BuildParentList()
			end

			for i, parent in ipairs(self.parent_list) do
				if parent.event_hidden then
					return true
				end
			end

			return false
		end

		--SETUP_CACHE_FUNC(PART, "IsHidden")
	end

	function PART:RemoveChildren()
		for key, part in pairs(self.Children) do
			part:Remove()
		end
		self.Children = {}
	end

	function PART:UnParent()
		local parent = self:GetParent()

		if parent:IsValid() then
			parent:RemoveChild(self)
		end

		self:ClearBone()

		self:OnUnParent(parent)

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

	function PART:SetTable(tbl, instant)
		self.supress_part_name_find = true
		self.delayed_variables = self.delayed_variables or {}

		-- this needs to be set first
		self:SetUniqueID(tbl.self.UniqueID)

		for key, value in pairs(tbl.self) do

			-- these arent needed because parent system uses the tree structure
			if key == "ParentUID" then continue end
			if key == "ParentName" then continue end

			-- already set
			if key == "UniqueID" then continue end

			-- ughhh
			if key ~= "AimPartName" and self.IngoreSetKeys and self.IngoreSetKeys[key] then continue end
			if key == "AimPartName" and not table.HasValue(pac.AimPartNames, value) then
				continue
			end

			self = hook.Run("pac_PART:SetTable",self,key,value) or self

			if self["Set" .. key] then
				-- hacky
				if key:find("Name", nil, true) and key ~= "OwnerName" and key ~= "SequenceName" and key ~= "GestureName" and key ~= "VariableName" and key ~= "BodyGroupName" then
					self["Set" .. key](self, pac.HandlePartName(self:GetPlayerOwner(), value, key))
				else
					if key == "Material" then
						if not value:find("/") then
							value = pac.HandlePartName(self:GetPlayerOwner(), value, key)
						end

						table.insert(self.delayed_variables, {key = key, val = value})
					end

					self["Set" .. key](self, value)
				end
			elseif key ~= "ClassName" then
				pac.dprint("settable: unhandled key [%q] = %q", key, tostring(val))
			end
		end

		for key, value in pairs(tbl.children) do
			local function create()
				local part = pac.CreatePart(value.self.ClassName, self:GetPlayerOwner())
				part:SetTable(value, instant)
				part:SetParent(self)
			end

			if instant then
				create()
			else
				timer.Simple(math.random(), create)
			end
		end
	end

	function PART:ToTable(make_copy_name)
		local tbl = {self = {ClassName = self.ClassName}, children = {}}

		for _, key in pairs(self:GetStorableVars()) do
			local var = self[key] and self["Get"..key](self) or self[key], key
			var = pac.class.Copy(var) or var

			if make_copy_name and var ~= "" and (key == "UniqueID" or key:sub(-3) == "UID") then
				var = util.CRC(var .. var)
			end

			if key == "Name" and self[key] == "" then
				var = ""
			end

			-- these arent needed because parent system uses the tree structure
			if
				key == "ParentUID" or
				key == "ParentName" or
				var == self.DefaultVars[key]
			then
				continue
			end

			tbl.self[key] = var
		end

		for _, part in pairs(self.Children) do
			table.insert(tbl.children, part:ToTable(make_copy_name))
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
		part:SetTable(self:ToTable(true), true)

		part:SetParent(self:GetParent())

		return part
	end
end

function PART:CallEvent(event, ...)
	self:OnEvent(event, ...)
	for _, part in pairs(self.Children) do
		part:CallEvent(event, ...)
	end
end

do -- events
	function PART:Initialize() end
	function PART:OnRemove() end

	function PART:Remove()
		pac.CallHook("OnPartRemove", self)
		self:CallRecursive("OnHide")
		self:OnRemove()

		if self:HasParent() then
			self:GetParent():RemoveChild(self)
		end

		self:RemoveChildren()

		if self.owner_id then
			pac.UniqueIDParts[self.owner_id][self.UniqueID] = nil
		end

		pac.ActiveParts[self.Id] = nil

		self.IsValid = function() return false end
	end

	function PART:OnStore()	end
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
		for key, part in pairs(self.Children) do
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
			local pulse = math.abs(1+math.sin(pac.RealTime*20) * 255)
			pulse = pulse + 2
			pac.haloex.Add(tbl, Color(pulse, pulse, pulse, 255), 1, 1, 1, true, true, 5, 1, 1)
		end
	end
end

do -- drawing. this code is running every frame
	local VEC0 = Vector(0,0,0)
	local ANG0 = Angle(0,0,0)
	local LocalToWorld = LocalToWorld

	PART.cached_pos = Vector(0,0,0)
	PART.cached_ang = Angle(0,0,0)

	local pos, ang, owner

	function PART:Draw(event, pos, ang, draw_type)

		-- Think takes care of polling this
		if not self.last_enabled then return end

		if self:IsHidden() then	return end

		owner = self:GetOwner()

		if self[event] then

			if
				draw_type == "viewmodel" or
				((self.Translucent == true or self.force_translucent == true) and draw_type == "translucent")  or
				((self.Translucent == false or self.force_translucent == false) and draw_type == "opaque")
			then

				pos = pos or Vector(0,0,0)
				ang = ang or Angle(0,0,0)

				pos, ang = self:GetDrawPosition()

				pos = pos or Vector(0,0,0)
				ang = ang or Angle(0,0,0)

				self.cached_pos = pos
				self.cached_ang = ang

				if self.PositionOffset ~= VEC0 or self.AngleOffset ~= ANG0 then
					pos, ang = LocalToWorld(self.PositionOffset, self.AngleOffset, pos, ang)
				end

				if not self.HandleModifiersManually then self:ModifiersPreEvent(event, draw_type) end

				self[event](self, owner, pos, ang) -- this is where it usually calls Ondraw on all the parts

				if not self.HandleModifiersManually then self:ModifiersPostEvent(event, draw_type) end
			end
		end

		for _, part in pairs(self.Children) do
			part:Draw(event, pos, ang, draw_type)
		end

	end

	local LocalToWorld = LocalToWorld

	function PART:GetDrawPosition(bone_override, skip_cache)
		if pac.FrameNumber ~= self.last_drawpos_framenum or not self.last_drawpos or skip_cache then
			self.last_drawpos_framenum = pac.FrameNumber

			local owner = self:GetOwner()
			if owner:IsValid() then
				local pos, ang = self:GetBonePosition(bone_override)

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

		else
			return self.last_drawpos, self.last_drawang
		end

		return Vector(0,0,0), Angle(0,0,0)
	end

	function PART:GetBonePosition(bone_override)
		if pac.FrameNumber ~= self.last_bonepos_framenum or not self.last_bonepos then
			self.last_bonepos_framenum = pac.FrameNumber

			local owner = self:GetOwner()
			local parent = self:GetParent()

			if parent:IsValid() and parent.ClassName == "jiggle" then
				return parent.pos, parent.ang
			end

			if parent:IsValid() and not parent.NonPhysical then

				local ent = parent.Entity or NULL

				if ent:IsValid() then
					-- if the parent part is a model, get the bone position of the parent model
					ent:InvalidateBoneCache()
					pos, ang = pac.GetBonePosAng(ent, bone_override or self.Bone)
				else
					-- else just get the origin of the part
					if not pos or not ang then
						-- unless we've passed it from parent
						pos, ang = parent:GetDrawPosition()
					end
				end

			elseif owner:IsValid() then
				-- if there is no parent, default to owner bones
				owner:InvalidateBoneCache()
				pos, ang = pac.GetBonePosAng(owner, self.Bone)
			end

			self.last_bonepos = pos
			self.last_boneang = ang

			return pos, ang
		else
			return self.last_bonepos, self.last_boneang
		end
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

			local ang = (pac.EyePos - self.cached_pos):Angle()
			ang.p = 0
			return self.Angles + ang

		end

		if pac.StringFind(self.AimPartName, "LOCALEYES_PITCH", true, true) then

			local ang = (pac.EyePos - self.cached_pos):Angle()
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
			else
				return self.Angles + (pac.EyePos - self.cached_pos):Angle()
			end
		end

		if self.AnglePart:IsValid() then

			local a = self.AnglePart.cached_ang * 1

			a.p = a.p * self.AnglePartMultiplier.x
			a.y = a.y * self.AnglePartMultiplier.y
			a.r = a.r * self.AnglePartMultiplier.z

			return self.AngleOffset + self.Angles + a

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

function PART:Think()
	if not self:GetEnabled() then return end

	local b = self:IsHidden()

	if b ~= self.last_hidden then

		if b then
			self:OnHide()
		else
			self:OnShow(self.shown_from_rendering)
		end

		self.shown_from_rendering = nil

		self.last_hidden = b
	end

	if not self.AlwaysThink and b then return end

	local owner = self:GetOwner()

	if owner:IsValid() then
		if owner ~= self.last_owner then
			self:OnShow()
			self:OnHide()
			self.last_hidden = nil
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

		for _, data in pairs(self.delayed_variables) do
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

function PART:IsValid()
	return true
end

function PART:SetDrawOrder(num)
	self.DrawOrder = num
	if self:HasParent() then self:GetParent():SortChildren() end
end

pac.RegisterPart(PART)
