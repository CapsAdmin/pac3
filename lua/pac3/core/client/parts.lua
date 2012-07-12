local class = pac.class

pac.ActiveParts = pac.ActiveParts or {}
local part_count = 0 -- unique id thing

function pac.CreatePart(name, owner)
	owner = owner or LocalPlayer()
	
	local part = class.Create("part", name)
	
	if part.PreInitialize then 
		part:PreInitialize()
	end
		
	part:Initialize()

	table.insert(pac.ActiveParts, part)
	part.Id = part_count
	part_count = part_count + 1
	
	if owner then
		part:SetPlayerOwner(owner)
	end
	
	pac.dprint("creating %s part owned by %s", part.ClassName, owner:Nick())
	
	return part
end

function pac.RegisterPart(META, name)
	if not META.Base then
		class.InsertIntoBaseField(META, "base")
	end
	class.Register(META, "part", name)
end

function pac.GetRegisteredParts()
	return class.GetAll("part")
end

function pac.GetPart(name)
	return class.Get("part", name)
end

function pac.GetParts(owned_only)
	if owned_only then		
		local tbl = {}
		for key, part in pairs(pac.ActiveParts) do
			if not part:IsValid() then
				pac.ActiveParts[key] = nil
			elseif part:GetPlayerOwner() == LocalPlayer() then
				table.insert(tbl, part)
			end
		end
		return tbl
	end
	for key, part in pairs(pac.ActiveParts) do
		if not part:IsValid() then
			pac.ActiveParts[key] = nil
		end
	end
	return pac.ActiveParts
end

function pac.RemoveAllParts(owned_only)
	for key, part in pairs(pac.GetParts(owned_only)) do
		if part:IsValid() then
			part:Remove()
		end
	end
	pac.ActiveParts = {}
end

function pac.GetPartCount(class, children)
	class = class:lower()
	local count = 0

	for key, part in pairs(children or pac.GetParts(true)) do
		if part.ClassName:lower() == class then
			count = count + 1
		end
	end

	return count
end

function pac.CallPartHook(name, ...)
	for key, part in pairs(pac.GetParts()) do
		if part[name] then
			part[name](part, ...)
		end
	end
end

do -- meta
	local PART = {}

	PART.ClassName = "base"
	PART.Internal = true

	function PART:__tostring()
		return string.format("%s[%s][%i]", self.Type, self.ClassName, self.Id)
	end
	
	pac.GetSet(PART, "BoneIndex")
	pac.GetSet(PART, "PlayerOwner", NULL)
	pac.GetSet(PART, "Owner", NULL)
	pac.GetSet(PART, "Parent", pac.NULL)

	pac.StartStorableVars()
		pac.GetSet(PART, "OwnerName", "self")
		pac.GetSet(PART, "ParentName", "")
		pac.GetSet(PART, "Bone", "head")
		pac.GetSet(PART, "Position", Vector(0,0,0))
		pac.GetSet(PART, "Angles", Angle(0,0,0))
		pac.GetSet(PART, "AngleVelocity", Angle(0, 0, 0))
		pac.GetSet(PART, "EyeAngles", false)
		pac.GetSet(PART, "AimPartName", "")
		pac.GetSet(PART, "Name", "")
		pac.GetSet(PART, "Description", "")
		pac.GetSet(PART, "Hide", false)
	pac.EndStorableVars()
	
	function PART:PreInitialize()
		self.Children = {}
		
		self.Position = self.Position * 1
		self.Angles = self.Angles * 1
		self.AngleVelocity = self.AngleVelocity * 1
		
		self.Owner = NULL
		self.Parent = pac.NULL
		self.AimPart = pac.NULL
	end
	
	function PART:SetName(var)
	
		for key, part in pairs(self:GetChildren()) do
			part:SetParentName(var)
		end
		
		for key, part in pairs(pac.GetParts()) do
			if part.AimPartName and part.AimPartName ~= "" and part.AimPartName == self.Name then
				part:SetAimPartName(var)
			end
		end
		
		self.Name = var
	end
	
	do -- owner	
		function PART:SetOwnerName(name)
			self.OwnerName = name
			self:CheckOwner()
		end

		function PART:CheckOwner(ent)
			local parent = self:GetParent()
			
			if parent:IsValid() then
				return parent:CheckOwner(ent)
			end
		
			if self.OwnerName ~= "" then
				local ent = pac.HandleOwnerName(self:GetPlayerOwner(), self.OwnerName, ent)
				if ent ~= self:GetOwner() then
					self:SetOwner(ent)
					return true
				end
			end
		end

		function PART:SetOwner(ent)
			ent = ent or NULL
						
			if self:GetOwner():IsValid() then self:OnDetach(self:GetOwner()) end
			
			self.Owner = ent
			
			if ent:IsValid() then
				self:OnAttach(ent)
				if pac.HookEntityRender then
					timer.Simple(0.1, function()
						if ent:IsValid() and self:IsValid() then
							pac.HookEntityRender(ent, self:GetRootPart()) 
						end
					end)
				end
			end
		end
		
		-- always return the root owner
		function PART:GetPlayerOwner()
			local parent = self:GetParent()
			
			if parent:IsValid() then
				return parent:GetPlayerOwner()
			end
			
			return self.PlayerOwner or NULL
		end
		
		function PART:GetOwner()
			local parent = self:GetParent()
			
			if parent:IsValid() then
				if 
					self.ClassName ~= "event" and 
					parent.ClassName == "model" and parent.Entity:IsValid() 
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

		function PART:GetOwnerModelBonesSorted()
			return pac.GetModelBonesSorted(self:GetOwner())
		end
	end

	do -- parenting
		function PART:CreatePart(name)
			local part = pac.CreatePart(name)
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
		
		function PART:SetParentName(var)
			if not var or var == "" then
				self:UnParent()
				return
			end

			self.ParentName = var
			
			self:ResolveParentName()
		end
		
		function PART:ResolveParentName()
			for key, part in pairs(pac.GetParts()) do
				if part:GetName() == self.ParentName then
					self:SetParent(part)
					break
				end
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

			local id = table.insert(self:GetChildren(), var)
			
			var.ParentName = self:GetName()
			var:OnParent(self)
			self:OnChildAdd(var)

			return id
		end

		function PART:HasParent()
			return self.Parent and self.Parent:IsValid()
		end

		function PART:HasChildren()
			return #self:GetChildren() > 0
		end

		function PART:HasChild(part)
			for key, child in pairs(self:GetChildren()) do
				if child == part or child:HasChild(part) then
					return true
				end
			end
			return false
		end
		
		function PART:RemoveChild(var)
			local children = self:GetChildren()
			
			if children[var] then	
				if children[var]:IsValid() then
					children[var].Parent = pac.NULL
					children[var].ParentName = ""
					children[var] = nil
				end
			else
				for index, part in pairs(children) do
					if part == var then
						children[index].Parent = pac.NULL
						children[index].ParentName = ""
						children[index] = nil
						return
					end
				end
			end
			
			self.Children = children
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
			
			return self
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

		function PART:GetChildren()
			local children = self.Children
			
			for key, part in pairs(children) do
				if not part:IsValid() then
					children[key] = nil
				end
			end

			return children
		end
		
		function PART:RemoveChildren()
			for key, part in pairs(self:GetChildren()) do
				part:Remove()
			end
			self.Children = {}
		end

		function PART:UnParent()
			local parent = self:GetParent()
			
			if parent:IsValid() then
				parent:RemoveChild(self)
			end
			
			self:OnUnParent()
		end
	end

	do -- bones
		function PART:SetBone(var)
			self.Bone = var
			self.BoneIndex = nil
			self.TriedToFindBone = nil
		end

		function PART:ClearBone()
			self.BoneIndex = nil
			self.TriedToFindBone = nil
		end

		function PART:GetModelBones()
			return pac.GetModelBones(self:GetOwner())
		end

		function PART:GetModelBonesSorted()
			return pac.GetModelBonesSorted(self:GetOwner())
		end

		function PART:GetRealBoneName(name, owner)
			owner = owner or self:GetOwner()
			
			if owner:IsValid() and owner.pac_bones and owner.pac_bones[name] then
				return owner.pac_bones[name].real
			end
			
			return name
		end
		
		function PART:GetDrawPosition(owner, pos, ang)
			owner = owner or self:GetOwner()
			if owner:IsValid() then
				local pos, ang = self:GetBonePosition(owner, nil, pos, ang)
		
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

		function PART:GetBonePosition(owner, idx, pos, ang)
			owner = owner or self:GetOwner()
			
			if self.BoneIndex then
				local parent = self:GetParent()
				if parent:IsValid() and parent.ClassName ~= "group" then
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
				-- default to owner origin until BoneIndex is ready
				pos = owner:GetPos()
				ang = owner:GetAngles()
			end
				
			return pos, ang
		end

		function PART:UpdateBoneIndex(owner)
			owner = owner or self:GetOwner()
			if owner:IsValid() then
				self.BoneIndex = owner:LookupBone(self:GetRealBoneName(self.Bone))
				if not self.BoneIndex and (owner:IsNPC() or owner:IsPlayer()) and owner.GetActiveWeapon then
					local wep = owner:GetActiveWeapon()

					if wep:IsWeapon() then
						self.BoneIndex = wep:LookupBone(self:GetRealBoneName(self.Bone, wep))
						if not self.BoneIndex then
							self.Error = self.Bone .. " cannot be found on '" .. tostring(owner) .. "'"
							MsgN(self.Error)
							self.TriedToFindBone = self.Bone
						end
					end
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
					if key:find("Name", nil, true) then
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
			end
						
			timer.Simple(0.1, function()
				if self:IsValid() then
					self:ResolveParentName()
					self:ResolveAimPartName()
				end
			end)
		end
		
		local function COPY(var) 
			if type(var) == "Vector" or type(var) == "Angle" then 
				return var * 1 
			end 
			
			if type(var) == "table" then
				return table.Copy(var)
			end
			
			return var 
		end

		function PART:ToTable(make_copy_name, is_child)
			local tbl = {self = {ClassName = self.ClassName}, children = {}}

			for _, key in pairs(self:GetStorableVars()) do
				tbl.self[key] = COPY(self["Get"..key] and self["Get"..key](self) or self[key])
				if make_copy_name and (key == "Name" or key == "AimPartName" or (key == "ParentName" and is_child)) then
					tbl.self[key] = tbl.self[key] .. " copy"
				end
			end

			for _, part in pairs(self:GetChildren()) do
				table.insert(tbl.children, part:ToTable(make_copy_name, true))
			end

			return tbl
		end
		
		function PART:GetVars()
			local tbl = {}

			for _, key in pairs(self:GetStorableVars()) do
				tbl[key] = COPY(self[key])
			end
			
			return tbl			
		end
		
		function PART:Clone()
			local part = pac.CreatePart(self.ClassName)
			part:SetTable(self:ToTable(true))
			return part
		end
	end

	do -- events
		function PART:Initialize() end
		function PART:OnRemove() end
		
		function PART:Remove()
			pac.CallHook("OnPartRemove", self)

			self:RemoveChildren()
			
			self:OnRemove()
			
			self.IsValid = function() return false end
		end

		function PART:OnAttach() end
		function PART:OnDetach() end
				
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
	end
	
	do -- highlight
		PART.highlight = 0

		function PART:Highlight()
			self.highlight = CurTime() + 0.1	
			
			for key, part in pairs(self:GetChildren()) do
				part.highlight = CurTime() + 0.1
				part:Highlight()
			end
		end

		function PART:IsHighlighting()
			return self.highlight > CurTime()
		end
				
		local ring = Material("particle/particle_Ring_Sharp")

		function PART:DrawHighlight(owner, pos, ang)
			render.SetMaterial(ring)
			cam.IgnoreZ(true)
			render.DrawSprite(pos, 8, 8, color_white)
			cam.IgnoreZ(false)
		end
	end
	
	function PART:SetHide(b)
		if b ~= self.Hide then
			if b then
				self:OnHide()
			else
				self:OnShow()
			end
		end
		self.Hide = b
	end
	
	function PART:SetEventHide(b)
		if b ~= self.EventHide then
			if b then
				self:OnHide()
			else
				self:OnShow()
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
					pos = pos or Vector(0,0,0)
					ang = ang or Angle(0,0,0)
					
					owner = self:GetOwner()
					
					pos, ang = self:GetDrawPosition(owner, pos, ang)
					
					pos = pos or Vector(0,0,0)
					ang = ang or Angle(0,0,0)
					
					self.cached_pos = pos
					self.cached_ang = ang
					
					self[event](self, owner, pos, ang)
				end
								
				for index, part in pairs(self:GetChildren()) do
					if part[event] then
						part:Draw(event, pos, ang)
					end
				end
			end
			
			if pos and ang and owner and self:IsHighlighting() then
				self:DrawHighlight(owner, pos, ang)
			end
		end
	end
	
	function PART:BuildBonePositions(owner)
		self:OnBuildBonePositions(owner)
		do return end
		if not self:IsHiddenEx() then
			
			self:OnBuildBonePositions(owner)
			
			for key, child in pairs(self:GetChildren()) do
				child:BuildBonePositions(owner)
			end
		end
	end
	
	function PART:Think()	
		local owner = self:GetOwner()
	
		if not owner.pac_bones then
			pac.GetModelBones(owner)
		end
	
		if not self.BoneIndex and self.TriedToFindBone ~= self.Bone then
			self:UpdateBoneIndex(owner)
		end
				
		if self.AimPartName and self.AimPartName ~= "" and not self.AimPart:IsValid() and part ~= self then
			self:ResolveAimPartName()
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
	
	do -- aim part		
		function PART:SetAimPartName(name)
			if not name or name == "" then
				self.AimPart = pac.NULL
			return end
			
			self.AimPartName = name
		end	
	
		function PART:ResolveAimPartName()
			for key, part in pairs(pac.GetParts()) do	
				if part ~= self and part:GetName() == self.AimPartName then
					self.AimPart = part
					break
				end
			end
		end
	end

	function PART:CalcAngles(owner, ang)
		owner = owner or self:GetOwner()
		
		ang = self:CalcAngleVelocity(ang)
		
		if self.AimPart:IsValid() then	
			return self.Angles + (self.AimPart.cached_pos - self.cached_pos):Angle()
		elseif self.EyeAngles and owner:IsPlayer() then
			return self.Angles + (owner:GetEyeTraceNoCursor().HitPos - self.cached_pos):Angle()
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
	
	pac.RegisterPart(PART)
end