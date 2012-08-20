local PART = {}

PART.ClassName = "bone"

pac.StartStorableVars()
	pac.GetSet(PART, "Modify", true)
	pac.GetSet(PART, "RotateOrigin", true)

	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "FollowPartName", "")
pac.EndStorableVars()

function PART:Initialize()
	self.FollowPart = pac.NULL
end

function PART:SetFollowPartName(var)

	if var and type(var) ~= "string" then
		self.FollowPartName = var:GetName()
		self.FollowPartUID = var:GetUniqueID()
		self.FollowPart = var
		return
	end

	self.FollowPartName = var or ""
	self.FollowPartUID = nil
	self.FollowPart = pac.NULL
end	

function PART:ResolveFollowPartName()
	for key, part in pairs(pac.GetParts()) do	
		if part ~= self and (part.UniqueID == self.UniqueID or part:GetName() == self.FollowPartName) then
			self.FollowPart = part
			self.FollowPartUID = part.UniqueID
			
			pac.HookBuildBone(part:GetOwner())
			break
		end
	end
end

function PART:OnAttach(owner)
	self.BoneIndex = nil
	pac.HookBuildBone(owner, self)
end

function PART:OnParent()
	self:OnAttach(self:GetOwner())
end

function PART:GetOwner()
	local parent = self:GetParent()
	
	if parent:IsValid() then		
		if parent.ClassName == "model" and parent.Entity:IsValid() then
			return parent.Entity
		end
	end
	
	return self.BaseClass.GetOwner(self)
end

function PART:OnThink()
	
	-- this is to setup the cached values
	if not self.first_getbpos and self:GetOwner():IsValid() then
		self:GetBonePosition()
		self.first_getbpos = true
	end
	
	local owner = self:GetOwner()
	
	if owner:IsValid() and not owner.BuildBonePositions then
		pac.HookBuildBone(owner)
	end
end

function PART:GetBonePosition(...)
	local owner = self:GetOwner()
	local pos, ang
	
	if owner:IsValid() then
		if not self.BoneIndex then
			self:UpdateBoneIndex(owner)
		end
	
		pos, ang = owner:GetBonePosition(owner:GetBoneParent(self.BoneIndex))
		owner:InvalidateBoneCache()

		if not pos and not ang then
			pos, ang = owner:GetBonePosition(self.BoneIndex)
			owner:InvalidateBoneCache()
		end
			
		self.cached_pos = pos
		self.cached_ang = ang
	end

	return pos or Vector(0,0,0), ang or Angle(0,0,0)
end

function PART:OnBuildBonePositions(owner)	
	self.BoneIndex = self.BoneIndex or owner:LookupBone(self:GetRealBoneName(self.Bone))

	local matrix = owner:GetBoneMatrix(self.BoneIndex)
	
	if matrix then			
		local ang = self:CalcAngles(owner, self.Angles) or self.Angles
	
		if self.FollowPart:IsValid() then			
			if VERSION >= 150 then
				matrix:SetAngles(self.FollowPart.cached_ang + ang)
			else
				matrix:SetAngle(self.FollowPart.cached_ang + ang)
			end
			matrix:SetTranslation(self.FollowPart.cached_pos + self.Position)
		else				
			if self.EyeAngles or self.AimPart:IsValid() then
				ang.r = ang.y
				ang.y = -ang.p			
			end
			
			if self.Modify then
				if self.RotateOrigin then
					matrix:Translate(self.Position)
					matrix:Rotate(ang)
				else
					matrix:Rotate(ang)
					matrix:Translate(self.Position)
				end
			else
				if VERSION >= 150 then
					matrix:SetAngles(ang)
				else
					matrix:SetAngle(ang)
				end
				matrix:SetTranslation(self.Position)
			end
		end
	
		matrix:Scale(self.Scale * self.Size)
	
		owner:SetBoneMatrix(self.BoneIndex, matrix)
	end
end

pac.RegisterPart(PART)