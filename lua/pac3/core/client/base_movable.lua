local pac = pac
local Vector = Vector
local Angle = Angle
local NULL = NULL
local Matrix = Matrix

local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "base_movable"
PART.BaseName = PART.ClassName

BUILDER
	:StartStorableVars()
		:SetPropertyGroup("orientation")
			:GetSet("Bone", "head")
			:GetSet("Position", Vector(0,0,0))
			:GetSet("Angles", Angle(0,0,0))
			:GetSet("EyeAngles", false)
			:GetSet("PositionOffset", Vector(0,0,0))
			:GetSet("AngleOffset", Angle(0,0,0))
			:GetSetPart("AimPart")
			:GetSet("AimPartName", "", {enums = {
				["local eyes"] = "LOCALEYES",
				["player eyes"] = "PLAYEREYES",
				["local eyes yaw"] = "LOCALEYES_YAW",
				["local eyes pitch"] = "LOCALEYES_PITCH",
				["nearest npc or player (torso-level)"] = "NEAREST_LIFE",
				["nearest npc or player (entity position)"] = "NEAREST_LIFE_POS",
				["nearest npc or player (yaw only)"] = "NEAREST_LIFE_YAW"
			}})
			:GetSetPart("Parent")
	:EndStorableVars()

do -- bones
	function PART:SetBone(val)
		self.Bone = val
		pac.ResetBoneCache(self:GetOwner())
	end

	function PART:GetBonePosition()
		local parent = self:GetParent()
		if parent:IsValid() then
			if parent.ClassName == "jiggle" or parent.ClassName == "interpolated_multibone" then
				return parent.pos, parent.ang
			elseif
				not parent.is_model_part and
				not parent.is_entity_part and
				not parent.is_bone_part and
				not self.is_bone_part and
				parent.WorldMatrix
			then
				return parent:GetWorldPosition(), parent:GetWorldAngles()
			end
		end

		local owner = self:GetParentOwner()
		if owner:IsValid() then
			-- if there is no parent, default to owner bones
			return pac.GetBonePosAng(owner, self.BoneOverride or self.Bone)
		end

		return Vector(), Angle()
	end

	function PART:GetBoneMatrix()
		local parent = self:GetParent()
		if IsValid(parent) then
			if parent.ClassName == "jiggle" or parent.ClassName == "interpolated_multibone" then
				local bone_matrix = Matrix()
				if parent.pos then
					bone_matrix:SetTranslation(parent.pos)
					bone_matrix:SetAngles(parent.ang)
				end
				return bone_matrix
			elseif
				not parent.is_model_part and
				not parent.is_entity_part and
				not parent.is_bone_part and
				not self.is_bone_part and
				parent.WorldMatrix
			then
				return parent.WorldMatrix
			end
		end

		local bone_matrix = Matrix()
		local owner = self:GetParentOwner()
		if owner:IsValid() then
			-- if there is no parent, default to owner bones
			local pos, ang = pac.GetBonePosAng(owner, self.BoneOverride or self.Bone)
			bone_matrix:SetTranslation(pos)
			bone_matrix:SetAngles(ang)
		end

		return bone_matrix
	end

	function PART:GetModelBones()
		return pac.GetModelBones(self:GetOwner())
	end

	function PART:GetModelBoneIndex()
		local bones = self:GetModelBones()
		local owner = self:GetOwner()
		if not owner:IsValid() then return end

		local name = self.Bone

		if bones[name] and not bones[name].is_special then
			return owner:LookupBone(bones[name].real)
		end

		return nil
	end
end

function PART:BuildWorldMatrix(with_offsets)
	local local_matrix = Matrix()
	local_matrix:SetTranslation(self.Position)
	local_matrix:SetAngles(self.Angles)

	local m = self:GetBoneMatrix() * local_matrix

	m:SetAngles(self:CalcAngles(m:GetAngles(), m:GetTranslation()))

	if with_offsets then
		m:Translate(self.PositionOffset)
		m:Rotate(self.AngleOffset)
	end

	return m
end

function PART:GetWorldMatrixWithoutOffsets()
	-- this is only used by the editor, no need to cache
	return self:BuildWorldMatrix(false)
end

function PART:GetWorldMatrix()
	if not self.WorldMatrix or pac.FrameNumber ~= self.last_framenumber then
		self.last_framenumber = pac.FrameNumber
		self.WorldMatrix = self:BuildWorldMatrix(true)
	end

	return self.WorldMatrix
end

function PART:GetWorldAngles()
	return self:GetWorldMatrix():GetAngles()
end

function PART:GetWorldPosition()
	return self:GetWorldMatrix():GetTranslation()
end

function PART:GetDrawPosition()
	return self:GetWorldPosition(), self:GetWorldAngles()
end

function PART:CalcAngles(ang, wpos)
	wpos = wpos or self.WorldMatrix and self.WorldMatrix:GetTranslation()
	if not wpos then return ang end

	local owner = self:GetRootPart():GetOwner()

	if pac.StringFind(self.AimPartName, "LOCALEYES_YAW", true, true) then
		ang = (pac.EyePos - wpos):Angle()
		ang.p = 0
		return self.Angles + ang
	end

	if pac.StringFind(self.AimPartName, "LOCALEYES_PITCH", true, true) then
		ang = (pac.EyePos - wpos):Angle()
		ang.y = 0
		return self.Angles + ang
	end

	if pac.StringFind(self.AimPartName, "LOCALEYES", true, true) then
		return self.Angles + (pac.EyePos - wpos):Angle()
	end


	if pac.StringFind(self.AimPartName, "PLAYEREYES", true, true) then
		local ent = owner.pac_traceres and owner.pac_traceres.Entity or NULL

		if ent:IsValid() then
			return self.Angles + (ent:EyePos() - wpos):Angle()
		end

		return self.Angles + (pac.EyePos - wpos):Angle()
	end

	local function get_nearest_ent(part)
		local nearest_ent = part:GetRootPart():GetOwner()
		local nearest_dist = math.huge
		local owner_ent = part:GetRootPart():GetOwner()

		local ents_in_sphere = ents.FindInSphere(wpos, 5000)

		for i = 1, #ents_in_sphere do
			local ent = ents_in_sphere[i]
			if (ent:IsNPC() or ent:IsPlayer()) and ent ~= owner_ent then
				local dist = (wpos - ent:GetPos()):LengthSqr()
				if dist < nearest_dist then
					nearest_ent = ent
					nearest_dist = dist
				end
			end
		end

		return nearest_ent
	end

	if pac.StringFind(self.AimPartName, "NEAREST_LIFE_YAW", true, true) then
		local nearest_ent = get_nearest_ent(self)
		if not IsValid(nearest_ent) then return ang or Angle(0,0,0) end
		local ang = (nearest_ent:GetPos() - wpos):Angle()
		return Angle(0,ang.y,0) + self.Angles
	end

	if pac.StringFind(self.AimPartName, "NEAREST_LIFE_POS", true, true) then
		local nearest_ent = get_nearest_ent(self)
		if not IsValid(nearest_ent) then return ang or Angle(0,0,0) end
		return self.Angles + (nearest_ent:GetPos() - wpos):Angle()
	end

	if pac.StringFind(self.AimPartName, "NEAREST_LIFE", true, true) then
		local nearest_ent = get_nearest_ent(self)
		if not IsValid(nearest_ent) then return ang or Angle(0,0,0) end
		return self.Angles + ( nearest_ent:GetPos() + Vector(0,0,(nearest_ent:WorldSpaceCenter() - nearest_ent:GetPos()).z * 1.5) - wpos):Angle()
	end

	if self.AimPart:IsValid() and self.AimPart.GetWorldPosition then
		return self.Angles + (self.AimPart:GetWorldPosition() - wpos):Angle()
	end

	if self.EyeAngles then
		if owner:IsPlayer() then
			return self.Angles + ((owner.pac_hitpos or owner:GetEyeTraceNoCursor().HitPos) - wpos):Angle()
		elseif owner:IsNPC() then
			return self.Angles + ((owner:EyePos() + owner:GetForward() * 100) - wpos):Angle()
		end
	end

	return ang or Angle(0,0,0)
end

BUILDER:Register()
