local PART = {}

PART.ClassName = "bone"

pac.StartStorableVars()
	pac.GetSet(PART, "Modify", true)
	pac.GetSet(PART, "RotateOrigin", true)

	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
pac.EndStorableVars()

function PART:OnAttach(owner)
	self.BoneIndex = nil
	pac.HookBuildBone(owner)
	self.pac3_bonebuild_ref = owner
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
	if self.first_getbpos == nil and self:GetOwner():IsValid() then
		self:GetBonePosition()
		self.first_getbpos = false
	end
end

function PART:GetBonePosition(owner, ...)
	owner = owner or self:GetOwner()

	if not self.BoneIndex then
		self:UpdateBoneIndex(owner)
	end

	local pos, ang = owner:GetBonePosition(owner:GetBoneParent(self.BoneIndex))
	owner:InvalidateBoneCache()

	if not pos and not ang then
		pos, ang = owner:GetBonePosition(self.BoneIndex)
		owner:InvalidateBoneCache()
	end
		
	self.cached_pos = pos
	self.cached_ang = ang

	return pos or Vector(0,0,0), ang or Angle(0,0,0)
end

function PART:OnBuildBonePositions(owner)	
	self.BoneIndex = self.BoneIndex or owner:LookupBone(self:GetRealBoneName(self.Bone))

	local matrix = owner:GetBoneMatrix(self.BoneIndex)
	
	if matrix then	
		
		local ang = self:CalcAngles(owner, self.Angles) or self.Angles
				
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
			matrix:SetAngle(ang)
			matrix:SetTranslation(self.Position)
		end
		
		matrix:Scale(self.Scale * self.Size)
		
		owner:SetBoneMatrix(self.BoneIndex, matrix)
	end
end

pac.RegisterPart(PART)