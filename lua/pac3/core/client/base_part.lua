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
	pac.GetSet(PART, "AngleVelocity", Angle(0, 0, 0))
	pac.GetSet(PART, "EyeAngles", false)
	pac.GetSet(PART, "Name", "")
	pac.GetSet(PART, "Description", "")
	pac.GetSet(PART, "Hide", false)
	pac.GetSet(PART, "DrawOrder", 0)
	
	pac.GetSet(PART, "PositionOffset", Vector(0,0,0))
	pac.GetSet(PART, "AngleOffset", Angle(0,0,0))
	
	pac.GetSet(PART, "EditorExpand", false)
	pac.GetSet(PART, "UniqueID", "")
	
	pac.SetupPartName(PART, "AnglePart")
	pac.GetSet(PART, "AnglePartMultiplier", Vector(1,1,1))
	
	pac.SetupPartName(PART, "AimPart")
	
	pac.SetupPartName(PART, "Parent")
pac.EndStorableVars()

function PART:PreInitialize()
	self.Children = {}
	
	self.cached_pos = Vector(0,0,0)
	self.cached_ang = Angle(0,0,0)
end

do -- owner	
	function PART:SetOwnerName(name)
		self.OwnerName = name
		self:CheckOwner()
	end

	function PART:CheckOwner(ent, removed)		
		local parent = self:GetParent()
		
		if parent:IsValid() then
			return parent:CheckOwner(ent)
		end
		
		local prev_owner = self:GetOwner()
			
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

	function PART:SetOwner(ent)
		ent = ent or NULL
				
		if ent:IsValid() then
			self.Owner = ent
			pac.HookEntityRender(ent, self:GetRootPart()) 
		else
			pac.UnhookEntityRender(ent) 
			self.Owner = ent
		end
		
		self:CallRecursive("OnShow")
	end
	
	-- always return the root owner
	function PART:GetPlayerOwner()
		local parent = self:GetParent()
		
		if parent:IsValid() then
			return parent:GetPlayerOwner()
		end
		
		return self.PlayerOwner or self:GetOwner() or NULL
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
		
		pac.CallHook("OnPartParent", self, var)

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
		return self:GetParent() and self:GetParent():IsValid()
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
	
		local temp = self
		
		for i = 1, 100 do
			local parent = temp:GetParent()

			if parent:IsValid() then
				temp = parent
			else
				break
			end
		end
		
		return temp
	end
	
	do
		-- this doesn't work
		--[[
		
		function PART:IsHidden()
			return 
				self.temp_hidden or 
				self._Hide or
				self.Hide or
				self.EventHide 
			
		end
		
		function PART:SetHide(b)
			self:CallRecursive(b and "OnHide" or "OnShow")
			
			self.Hide = b
			self:SetKeyValueRecursive("_Hide", b)
		end
		
		function pac.InvalidateEvents()
			for key, val in pairs(pac.GetParts()) do
				val.last_eventhide = nil
			end
		end

		function PART:SetEventHide(b, filter)
			-- or is this needed for all the chilren children as well?
			if self.last_eventhide ~= b then
				self:CallRecursive(b and "OnHide" or "OnShow", true)
				self.last_eventhide = b
			end
			
			self:SetKeyValueRecursive("EventHide", b, filter)
		end]]
		
		function PART:SetHide(b)
			self.Hide = b
			
			self:CallRecursive(b and "OnHide" or "OnShow")
		end

		function PART:SetEventHide(b)
			if b ~= self.EventHide then
				self:CallRecursive(b and "OnHide" or "OnShow", true)
			end
			self.EventHide = b
		end

		function PART:IsHiddenEx()
			return self.Hide == true or self.EventHide == true or false
		end
			
		function PART:IsHidden()
			if self.temp_hidden then return true end
			if self:IsHiddenEx() then return true end
			
			local temp = self
			
			for i = 1, 100 do
				local parent = temp:GetParent()
				
				if parent:IsValid() then
					if parent:IsHiddenEx() then
						return true
					else
						temp = parent
					end
				else
					break
				end
			end
			
			return false
		end
	
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
		
		if owner:IsValid() and bones and bones[name] then
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
	
	function PART:SetTable(tbl)
		self.delayed_variables = self.delayed_variables or {}
		
		for key, value in pairs(tbl.self) do
			if self["Set" .. key] then
				-- hack?? it effectively removes name confliction for other parts
				if key:find("Name", nil, true) and key ~= "OwnerName" and key ~= "SequenceName" and key ~= "VariableName" then
					self.supress_part_name_find = true
					self["Set" .. key](self, pac.HandlePartName(self:GetPlayerOwner(), value, key))
					self.supress_part_name_find = false
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
				--self[key] = value
				pac.dprint("settable: unhandled key [%q] = %q", key, tostring(val))
			end
		end
		
		for key, value in pairs(tbl.children) do
			local part = pac.CreatePart(value.self.ClassName, self:GetPlayerOwner())
			part:SetTable(value)
			part:SetParent(self)
		end
	end
	
	local function COPY(var, key) 							
		if var and (key == "UniqueID" or key:sub(-3) == "UID") and var ~= "" then
			return util.CRC(var .. var)
		end

		return pac.class.Copy(var) or var
	end

	function PART:ToTable(make_copy_name, is_child)
		local tbl = {self = {ClassName = self.ClassName}, children = {}}

		for _, key in pairs(self:GetStorableVars()) do
			local var = COPY(self[key] and self["Get"..key](self) or self[key], key)
			
			if var == self.DefaultVars[key] then
				continue
			end
			
			tbl.self[key] = var

			if make_copy_name and (key == "Name" or key == "AimPartName"  or key == "FollowPartName" or (key == "ParentName" and is_child)) then
				if tbl.self[key] ~= "" then
					tbl.self[key] = tbl.self[key] .. " copy"
				end
			end
		end

		for _, part in pairs(self.Children) do
			table.insert(tbl.children, part:ToTable(make_copy_name, true))
		end

		return tbl
	end
	
	function PART:GetVars()
		local tbl = {}

		for _, key in pairs(self:GetStorableVars()) do
			tbl[key] = COPY(self[key], key)
		end
		
		return tbl
	end
			
	function PART:Clone()
		local part = pac.CreatePart(self.ClassName)
		if not part then return end
		part:SetTable(self:ToTable(true))
		part:ResolveParentName()
		return part
	end
end

function PART:CallEvent(event, ...)
	self:OnEvent(event, ...)
	for _, part in pairs(self.Children) do
		part:CallEvent(event, ...)
	end
end
	
function PART:CallRecursive(func, ...)
	if self[func] then self[func](self, ...) end
	
	for k, v in pairs(self.Children) do	
		v:CallRecursive(func, ...)
	end
end

function PART:SetKeyValueRecursive(key, val, filter)
	self[key] = val
	
	for k,v in pairs(self.Children) do
		if v ~= filter then
			v:SetKeyValueRecursive(key, val)
		end
	end
end

do -- events
	function PART:Initialize() end
	function PART:OnRemove() end
	
	function PART:Remove()		
		pac.CallHook("OnPartRemove", self)
		self:OnHide()
		self:OnRemove()
		
		if self:HasParent() then
			self:GetParent():RemoveChild(self)
		end

		self:RemoveChildren()
		
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

function PART:Highlight(skip_children)
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
		local pulse = math.abs(1+math.sin(pac.RealTime*20) * 255)
		pulse = pulse + 2
		pac.haloex.Add(tbl, Color(pulse, pulse, pulse, 255), 1, 1, 1, true, true, 5, 1, 1)
	end
end

do -- drawing. this code is running every frame
	local VEC0 = Vector(0,0,0)
	local ANG0 = Angle(0,0,0)

	PART.cached_pos = Vector(0,0,0)
	PART.cached_ang = Angle(0,0,0)
			
	local pos, ang, owner
	
	function PART:Draw(event, pos, ang, draw_type)
		if not self:IsHidden() then			
			owner = self:GetOwner()	
			
			if self.OwnerName == "viewmodel" and owner:GetOwner() == pac.LocalPlayer and pac.LocalPlayer:ShouldDrawLocalPlayer() then
				return
			end
			
			if self[event] then	
							
				if 
					self.Translucent == nil or
					(self.Translucent == true and draw_type == "translucent")  or
					(self.Translucent == false and draw_type == "opaque")
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
				
					self[event](self, owner, pos, ang) -- this is where it usually calls Ondraw on all the parts
				end
			end

			for _, part in pairs(self.Children) do
				part:Draw(event, pos, ang, draw_type)
			end
		end
	end
	
	local LocalToWorld = LocalToWorld
	
	function PART:GetDrawPosition()		
		if pac.FrameNumber ~= self.last_drawpos_framenum or not self.last_drawpos then
			self.last_drawpos_framenum = pac.FrameNumber

			local owner = self:GetOwner()
			if owner:IsValid() then
				local pos, ang = self:GetBonePosition()
								
				pos, ang = LocalToWorld(
					self.Position or Vector(), 
					self.Angles or Angle(), 
					pos or owner:GetPos(), 
					ang or owner:GetAngles()
				)
								
				ang = self:CalcAngles(owner, ang) or ang
				
				self.last_drawpos = pos
				self.last_drawang = ang
				
				return pos, ang
			end			
		
		else
			return self.last_drawpos, self.last_drawang
		end
		
		return Vector(0,0,0), Angle(0,0,0)
	end
	
	function PART:GetBonePosition()		
		if pac.FrameNumber ~= self.last_bonepos_framenum or not self.last_bonepos then
			self.last_bonepos_framenum = pac.FrameNumber

			local owner = self:GetOwner()
			local parent = self:GetParent()
			
			if parent:IsValid() and parent.ClassName == "jiggle" then
				return parent.pos, parent.ang
			end
			
			if parent:IsValid() and parent.ClassName ~= "group" and parent.ClassName ~= "entity" then
				
				local ent = parent.Entity or NULL
				
				if ent:IsValid() then
					-- if the parent part is a model, get the bone position of the parent model
					pos, ang = pac.GetBonePosAng(ent, self.Bone)
					ent:InvalidateBoneCache()
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
		
	function PART:CalcAngles(owner, ang)
		owner = owner or self:GetOwner()
		
		ang = self.calc_angvel and self:CalcAngleVelocity(ang) or ang

		if self.EyeAngles then
		
			if owner:IsPlayer() then
				return self.Angles + ((owner.pac_hitpos or owner:GetEyeTraceNoCursor().HitPos) - self.cached_pos):Angle()
			elseif owner:IsNPC() then
				return self.Angles + ((owner:EyePos() + owner:GetForward() * 100) - self.cached_pos):Angle()
			end
			
		end
		
		if self.AnglePart:IsValid() then
			
			local a = self.AnglePart.cached_ang * 1
			
			a.p = self.AnglePartMultiplier.x
			a.y = self.AnglePartMultiplier.y
			a.r = self.AnglePartMultiplier.z
			
			return self.AngleOffset + self.Angles + a
			
		end
		
		if self.AimPart:IsValid() then	
		
			return self.Angles + (self.AimPart.cached_pos - self.cached_pos):Angle()
			
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
			
		return ang or Angle(0,0,0)
	end
end
	
function PART:Think()	
	local owner = self:GetOwner()
	
	if owner:IsValid() then
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
end

function PART:BuildBonePositions()	
	if not self:IsHidden() then
		self:OnBuildBonePositions()
	end
end

function PART:SubmitToServer()
	pac.SubmitPart(self:ToTable())
end

function PART:GetName()
	return self.Name or "no name"
end

function PART:IsValid()
	return true
end

do -- this is kinda deprecated	
	function PART:SetAngleVelocity(ang)
		self.calc_angvel = ang.p == 0 and ang.y == 0 and ang.r == 0
		
		self.AngleVelocity = ang
	end

	function PART:CalcAngleVelocity(ang)
		local v = self.AngleVelocity
		
		if self.calc_angvel then				
			local delta = FrameTime() * 10
			self.AnglesVel = self.AnglesVel or Angle(0, 0, 0)

			self.AnglesVel.p = self.AnglesVel.p + (v.p * delta)
			self.AnglesVel.y = self.AnglesVel.y + (v.y * delta)
			self.AnglesVel.r = self.AnglesVel.r + (v.r * delta)
				
			return self.AnglesVel + ang	
		end
		
		return ang
	end
end

function PART:SetDrawOrder(num)
	self.DrawOrder = num
	if self:HasParent() then self:GetParent():SortChildren() end
end

pac.RegisterPart(PART)