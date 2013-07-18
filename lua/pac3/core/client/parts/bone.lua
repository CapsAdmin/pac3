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

function PART:OnHide()	
	local owner = self:GetOwner()
	
	if owner:IsValid() then
		owner.pac_follow_bones = owner.pac_follow_bones or {}
		owner.pac_follow_bones[self.BoneIndex] = nil
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

local dt = 1

local function manpos(ent, id, pos)
	ent:ManipulateBonePosition(id, pos)
end

local function manang(ent, i, ang)		
	ent:ManipulateBoneAngles(i, ang)
end

function pac.build_bone_callback(ent)
	if ent.pac_follow_bones then
		for id, data in pairs(ent.pac_follow_bones) do
			local mat = ent:GetBoneMatrix(id)
			mat:SetAngles(data.ang)
			mat:SetTranslation(data.pos)
			ent:SetBoneMatrix(id, mat)
		end
	end
end

function PART:OnBuildBonePositions()	

	dt = FrameTime() * 2
	local owner = self:GetOwner()
	
	if not owner:IsValid() then return end
	
	self.BoneIndex = self.BoneIndex or owner:LookupBone(self:GetRealBoneName(self.Bone)) or 0
	
	local ang = self:CalcAngles(self.Angles) or self.Angles

	owner.pac_follow_bones = owner.pac_follow_bones or {}
	
	if self.FollowPart:IsValid() then		
		local pos, ang = self:GetBonePosition()
		
		owner.pac_follow_bones[self.BoneIndex] = owner.pac_follow_bones[self.BoneIndex] or {}
		
		owner.pac_follow_bones[self.BoneIndex].pos = self.FollowPart.cached_pos + self.Position
		owner.pac_follow_bones[self.BoneIndex].ang = self.FollowPart.cached_ang + self.Angles
		
		if not owner.pac_follow_bones_function then
			owner:AddCallback("BuildBonePositions", pac.build_bone_callback)
			owner.pac_follow_bones_function = pac.build_bone_callback
		end
	else
		owner.pac_follow_bones[self.BoneIndex] = nil
		
		if self.EyeAngles or self.AimPart:IsValid() then
			ang.r = ang.y
			ang.y = -ang.p			
		end
		
		if self.Modify then
			if self.RotateOrigin then
				manpos(owner, self.BoneIndex, owner:GetManipulateBonePosition(self.BoneIndex) + self.Position + self.PositionOffset)
				manang(owner, self.BoneIndex, owner:GetManipulateBoneAngles(self.BoneIndex) + ang + self.AngleOffset)
			else
				manang(owner, self.BoneIndex, owner:GetManipulateBoneAngles(self.BoneIndex) + ang + self.AngleOffset)
				manpos(owner, self.BoneIndex, owner:GetManipulateBonePosition(self.BoneIndex) + self.Position + self.PositionOffset)
			end
		else
			manang(owner, self.BoneIndex, ang + self.AngleOffset) -- this should be world
			manpos(owner, self.BoneIndex, self.Position + self.PositionOffset) -- this should be world
		end
	end
	
	owner:ManipulateBoneJiggle(self.BoneIndex, type(self.Jiggle) == "number" and self.Jiggle or (self.Jiggle and 1 or 0)) -- afaik anything but 1 is not doing anything at all
	owner:ManipulateBoneScale(self.BoneIndex, owner:GetManipulateBoneScale(self.BoneIndex) * self.Scale * self.Size)
end

pac.RegisterPart(PART)