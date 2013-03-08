local PART = {}

PART.ClassName = "bone"

pac.StartStorableVars()
	pac.GetSet(PART, "Modify", true)
	pac.GetSet(PART, "RotateOrigin", true)

	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "Jiggle", false)
	pac.SetupPartName(PART, "FollowPart")
pac.EndStorableVars()

function PART:GetNiceName()
	return self:GetBone()
end

PART.ThinkTime = 0

function PART:OnShow(owner)
	self.BoneIndex = nil
end

PART.OnParent = PART.OnShow

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
end

function PART:GetBonePosition()
	local owner = self:GetOwner()
	local pos, ang
	
	pos, ang = pac.GetBonePosAng(owner, self.Bone, true)
	if owner:IsValid() then owner:InvalidateBoneCache() end
		
	self.cached_pos = pos
	self.cached_ang = ang

	return pos, ang
end

function PART:OnBuildBonePositions()	
	local owner = self:GetOwner()
	
	if not owner:IsValid() then return end
	
	self.BoneIndex = self.BoneIndex or owner:LookupBone(self:GetRealBoneName(self.Bone)) or 0
	
	local ang = self:CalcAngles(self.Angles) or self.Angles

	if self.FollowPart:IsValid() then		
		local pos, ang = self:GetBonePosition()
		
		pos, ang = WorldToLocal(pos, ang, self.FollowPart.cached_pos + self.Position, self.FollowPart.cached_ang + self.Angles)
		owner:ManipulateBoneAngles(self.BoneIndex, ang) -- this should be world
		owner:ManipulateBonePosition(self.BoneIndex, pos) -- this should be world
	else				
		if self.EyeAngles or self.AimPart:IsValid() then
			ang.r = ang.y
			ang.y = -ang.p			
		end
		
		if self.Modify then
			if self.RotateOrigin then
				owner:ManipulateBonePosition(self.BoneIndex, owner:GetManipulateBonePosition(self.BoneIndex) + self.Position)
				owner:ManipulateBoneAngles(self.BoneIndex, owner:GetManipulateBoneAngles(self.BoneIndex) + ang)
			else
				owner:ManipulateBoneAngles(self.BoneIndex, owner:GetManipulateBoneAngles(self.BoneIndex) + ang)
				owner:ManipulateBonePosition(self.BoneIndex, owner:GetManipulateBonePosition(self.BoneIndex) + self.Position)
			end
		else
			owner:ManipulateBoneAngles(self.BoneIndex, ang) -- this should be world
			owner:ManipulateBonePosition(self.BoneIndex, self.Position) -- this should be world
		end
	end
	
	owner:ManipulateBoneJiggle(self.BoneIndex, type(self.Jiggle) == "number" and self.Jiggle or (self.Jiggle and 1 or 0)) -- afaik anything but 1 is not doing anything at all
	owner:ManipulateBoneScale(self.BoneIndex, owner:GetManipulateBoneScale(self.BoneIndex) * self.Scale * self.Size)
end

pac.RegisterPart(PART)