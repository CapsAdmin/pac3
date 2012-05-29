local PART = {}

PART.ClassName = "bone"

pac.StartStorableVars()
	pac.GetSet(PART, "RelativeAngles", true)

	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
pac.EndStorableVars()

function PART:OnAttach(owner)
	self.BoneIndex = nil
	pac.HookBuildBone(owner)
	
	self:SetTooltip(self.Bone)
end

function PART:OnParent()
	self:OnAttach(self:GetOwner())
end

function PART:GetOwner()
	local parent = self:GetParent()
	
	if parent:IsValid() then
		if parent.ClassName == "model" and parent:GetEntity():IsValid() then
			return parent.Entity
		end
		
		if parent.ClassName == "player" then
			return LocalPlayer()
		end
	end
	
	return self.Owner
end

function PART:GetBonePosition(owner)
	owner = owner or self:GetOwner()

	if not self.BoneIndex then
		self:UpdateBoneIndex(owner)
	end

	local pos, ang = owner:GetBonePosition(owner:GetBoneParent(self.BoneIndex))

	if not pos and not ang then
		pos, ang = owner:GetBonePosition(self.BoneIndex)
	end

	return pos or Vector(0,0,0), ang or Angle(0,0,0)
end

function PART:BuildBonePositions(owner)
	if self.Hide then return end
	
	self.BoneIndex = self.BoneIndex or owner:LookupBone(self:GetRealBoneName(self.Bone))

	local matrix = owner:GetBoneMatrix(self.BoneIndex)

	if matrix then
	
		matrix:Translate(self.Position)

		if self.RelativeAngles then
			matrix:Rotate(self:CalcAngleVelocity(self.Angles))
		else
			matrix:SetAngle(self:CalcAngleVelocity(self.Angles))
		end

		matrix:Scale(self.Scale * self.Size)

		owner:InvalidateBoneCache()
		owner:SetBoneMatrix(self.BoneIndex, matrix)
	end
end

pac.RegisterPart(PART)