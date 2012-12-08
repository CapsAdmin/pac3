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
	
	pac.GetSet(PART, "EditorExpand", false)
	pac.GetSet(PART, "UniqueID", "")
	
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
		
		if ent:GetClass() == "class C_HL2MPRagdoll" then
			if prev_owner:IsPlayer() then
				local rag = prev_owner:GetRagdollEntity() or NULL
				if rag:IsValid() then
					self:SetOwner(rag)
					return
				end
			end
		end
		
		if removed and prev_owner == ent then
			self:SetOwner()
			return
		end
			
		if not removed and self.OwnerName ~= "" then
			local ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent, self)
			if ent ~= prev_owner then
				self:SetOwner(ent)
				return true
			end
		end
	end

	function PART:SetOwner(ent)
		ent = ent or NULL
				
		if ent:IsValid() then
			self.Owner = ent
			self:CallOnChildrenAndSelf("OnShow")
			pac.HookEntityRender(ent, self:GetRootPart()) 
		else
			self:CallOnChildrenAndSelf("OnHide")
			pac.UnhookEntityRender(ent) 
			self.Owner = ent
		end
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

	function PART:GetOwnerModelBones()
		return pac.GetModelBones(self:GetOwner())
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
		local children = self.Children

		for key, part in pairs(children) do
			if part == var then
				part.Parent = pac.NULL
				part.ParentName = ""
				part.ParentUID = nil
				children[key] = nil
				if self:HasParent() then 
					self:GetParent():SortChildren() 
				end
				part:OnUnParent(self)
				return
			end
		end
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
	
	function PART:IsHiddenEx()
		
		if self:IsHidden() then return true end
		
		local temp = self
		
		for i = 1, 100 do
			local parent = temp:GetParent()
			
			if parent:IsValid() then
				if parent:IsHidden() then
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

	function PART:GetModelBones()
		return pac.GetModelBones(self:GetOwner())
	end

	function PART:GetRealBoneName(name, owner)
		owner = owner or self:GetOwner()
		
		local bones = pac.GetModelBones(owner)
		
		if owner:IsValid() and bones and bones[name] then
			return bones[name].real
		end
		
		return name
	end
	
	function PART:GetDrawPosition(pos, ang)			
		local owner = self:GetOwner()
		if owner:IsValid() then
			local pos, ang = self:GetBonePosition(nil, pos, ang)
							
			pos, ang = LocalToWorld(
				self.Position, 
				self.Angles, 
				pos or owner:GetPos(), 
				ang or owner:GetAngles()
			)
			
			ang = self:CalcAngles(owner, ang) or ang
			
			return pos or owner:GetPos(), ang or owner:GetAngles()
		end
		
		return Vector(0, 0, 0), Angle(0, 0, 0)
	end
	
	local Angle = Angle
	local math_NormalizeAngle = math.NormalizeAngle

	function PART:GetBonePosition(idx, pos, ang)
		local owner = self:GetOwner()
		local parent = self:GetParent()
		
		if parent:IsValid() and parent.ClassName == "jiggle" then
			return parent.pos, parent.ang
		end
		
		if not self.BoneIndex then
			self:UpdateBoneIndex(owner)
		end
		
		if self.BoneIndex then
			if parent:IsValid() and parent.ClassName ~= "group" and parent.ClassName ~= "entity" then
				
				local ent = parent.Entity or NULL
				
				if ent:IsValid() then
					-- if the parent part is a model, get the bone position of the parent model
					pos, ang = ent:GetBonePosition(self.BoneIndex)
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
				pos, ang = owner:GetBonePosition(idx or self.BoneIndex)
			end
		else
			if owner:IsValid() then
				-- default to owner origin until BoneIndex is ready
				pos = owner:GetPos()
				if owner:IsPlayer() then
					ang = owner:EyeAngles()
					ang.p = 0
				else
					ang = owner:GetAngles()
				end
			else
				pos = Vector(0,0,0)
				ang = Angle(0,0,0)
			end
		end
			
		return pos, ang
	end

	function PART:UpdateBoneIndex(owner)
		owner = owner or self:GetOwner()
		if owner:IsValid() then
			self.BoneIndex = owner:LookupBone(self:GetRealBoneName(self.Bone))
			if not self.BoneIndex then
				self.Error = "pac3 warning: " .. self.Bone .. " cannot be found on '" .. tostring(owner) .. "' \n are you sure you're using the the same model?"
				if self.Bone ~= "head"  then
					pac.dprint(self.Error)
				end
				self.TriedToFindBone = self.Bone
			end
		end
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
		for key, value in pairs(tbl.self) do
			if self["Set" .. key] then
				-- hack?? it effectively removes name confliction for other parts
				if key:find("Name", nil, true) and key ~= "OwnerName" and key ~= "SequenceName" and key ~= "VariableName" then
					self["Set" .. key](self, pac.HandlePartName(self:GetPlayerOwner(), value, key))
				else
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

		return pac.class.Copy(var)
	end

	function PART:ToTable(make_copy_name, is_child)
		local tbl = {self = {ClassName = self.ClassName}, children = {}}

		for _, key in pairs(self:GetStorableVars()) do
			local var = COPY(self[key] and self["Get"..key](self) or self[key], key)
			
			if var == self["__def" .. key] then
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
		local uid = part.UniqueID
		part:SetTable(self:ToTable(true))
		part:ResolveParentName()
		part.UniqueID = uid
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
		local pulse = math.abs(1+math.sin(RealTime()*20) * 255)
		pulse = pulse + 2
		pac.haloex.Add(tbl, Color(pulse, pulse, pulse, 255), 1, 1, 1, true, true, 5, 1, 1)
	end
end

function PART:CallOnChildren(func, ...)
	for k,v in pairs(self:GetChildren()) do
		if v[func] then v[func](v, ...) end
		v:CallOnChildren(...)
	end
end

function PART:CallOnChildrenAndSelf(func, ...)
	if self[func] then self[func](self, ...) end
	self:CallOnChildren(func, ...)
end

function PART:SetHide(b)
	if b ~= self.Hide then
		if b then
			self:OnHide()
			self:CallOnChildren("OnHide")
		else
			self:OnShow()
			self:CallOnChildren("OnShow")
		end
	end
	self.Hide = b
	self:CallOnChildren("OnHide")
end

function PART:SetEventHide(b)
	if b ~= self.EventHide then
		if b then
			self:OnHide()
			self:CallOnChildren("OnHide")
		else
			self:OnShow()
			self:CallOnChildren("OnShow")
		end
	end
	self.EventHide = b
end

function PART:IsHidden()
	return self.Hide == true or self.EventHide == true or false
end

do
	PART.cached_pos = Vector(0,0,0)
	PART.cached_ang = Angle(0,0,0)
			
	local pos, ang, owner
	
	function PART:Draw(event, pos, ang)
		if not self:IsHiddenEx() then				
			
			if self[event] then
				self:OnBuildBonePositions()
			
				pos = pos or Vector(0,0,0)
				ang = ang or Angle(0,0,0)
				
				owner = self:GetOwner()
				
				pos, ang = self:GetDrawPosition(pos, ang)
				
				pos = pos or Vector(0,0,0)
				ang = ang or Angle(0,0,0)
				
				self.cached_pos = pos
				self.cached_ang = ang
			
				self[event](self, owner, pos, ang)
			end

			for _, part in pairs(self.Children) do
				if part[event] or part.ClassName == "group" then
					part:Draw(event, pos, ang)
				end
			end
		end
	end
end
	
function PART:Think()	
	local owner = self:GetOwner()
	
	if owner:IsValid() then
		if not owner.pac_bones then
			owner:SetupBones()
			owner:InvalidateBoneCache()
			pac.GetModelBones(owner)
		end
	
		if not self.BoneIndex and self.TriedToFindBone ~= self.Bone then
			self:UpdateBoneIndex(owner)
		end
	end
	
	if self.ResolvePartNames then
		self:ResolvePartNames()
	end
	
	self:OnThink()
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

function PART:CalcAngles(owner, ang)
	owner = owner or self:GetOwner()
	
	if owner:IsValid() and owner:GetOwner():IsValid() then
		owner = owner:GetOwner()
	end
	
	ang = self:CalcAngleVelocity(ang)
	
	if pac.StringFind(self.AimPartName, "LOCALEYES", true, true) then
		return self.Angles + (pac.EyePos - self.cached_pos):Angle()
	elseif self.AimPart:IsValid() then	
		return self.Angles + (self.AimPart.cached_pos - self.cached_pos):Angle()
	elseif self.EyeAngles then
		if owner:IsPlayer() then
			return self.Angles + ((owner.pac_hitpos or owner:GetEyeTraceNoCursor().HitPos) - self.cached_pos):Angle()
		elseif owner:IsNPC() then
			return self.Angles + ((owner:EyePos() + owner:GetForward() * 100) - self.cached_pos):Angle()
		end
	end
		
	return self:CalcAngleVelocity(ang) or Angle(0,0,0)
end
	
function PART:CalcAngleVelocity(ang)
	local v = self.AngleVelocity
	
	if v.p == 0 and v.y == 0 and v.r == 0 then
		self.AnglesVel = nil
	else				
		local delta = FrameTime() * 10
		self.AnglesVel = self.AnglesVel or Angle(0, 0, 0)

		self.AnglesVel.p = self.AnglesVel.p + (v.p * delta)
		self.AnglesVel.y = self.AnglesVel.y + (v.y * delta)
		self.AnglesVel.r = self.AnglesVel.r + (v.r * delta)
			
		return self.AnglesVel + ang	
	end
	
	return ang
end

function PART:SetDrawOrder(num)
	self.DrawOrder = num
	if self:HasParent() then self:GetParent():SortChildren() end
end

pac.RegisterPart(PART)