local PART = {}

PART.ClassName = "bone"

pac.StartStorableVars()
	pac.GetSet(PART, "ModifyAngles", true)

	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
pac.EndStorableVars()

function PART:OnAttach(outfit)
	self.BoneIndex = nil
	local owner = outfit:GetOwner()
	pac.HookBuildBone(owner)

	self:SetTooltip(self.Bone)
end

function PART:GetBonePosition(owner)
	owner = owner or self.Owner

	if not self.BoneIndex then
		self:UpdateBoneIndex(owner)
	end

	local pos, ang = owner:GetBonePosition(owner:GetBoneParent(self.BoneIndex))

	if not pos and not ang then
		pos, ang = owner:GetBonePosition(self.BoneIndex)
	end

	return pos, ang
end

function PART:BuildBonePositions(owner)
	if self.Hide then return end

	self.BoneIndex = self.BoneIndex or owner:LookupBone(self:GetRealBoneName(self.Bone))

	local matrix = owner:GetBoneMatrix(self.BoneIndex)

	if matrix then

		matrix:Translate(self.LocalPos)

		if self.ModifyAngles then
			matrix:Rotate(self:GetVelocityAngle(self.LocalAng))
		else
			matrix:SetAngle(self:GetVelocityAngle(self.LocalAng))
		end

		matrix:Scale(self.Scale * self.Size)

		owner:InvalidateBoneCache()
		owner:SetBoneMatrix(self.BoneIndex, matrix)
	end
end

pac.RegisterPart(PART)