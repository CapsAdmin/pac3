local pac = pac
local pairs = pairs
local ipairs = ipairs
local table = table
local Vector = Vector
local Angle = Angle
local Color = Color
local NULL = NULL
local SysTime = SysTime
local Matrix = Matrix

local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "base_movable"

BUILDER
	:GetSet("BoneIndex")
	:GetSet("PlayerOwner", NULL)
	:GetSet("Owner", NULL)

BUILDER
	:StartStorableVars()
		:SetPropertyGroup("orientation")
			:GetSet("Bone", "head")
			:GetSet("Position", Vector(0,0,0))
			:GetSet("Angles", Angle(0,0,0))
			:GetSet("EyeAngles", false)
			:GetSet("PositionOffset", Vector(0,0,0))
			:GetSet("AngleOffset", Angle(0,0,0))
			:GetSetPart("AimPart", {editor_panel = "aimpartname"})
			:GetSetPart("Parent")
	:EndStorableVars()

PART.AllowSetupPositionFrameSkip = true

do -- bones
	function PART:GetBonePosition()
		local owner = self:GetOwner()
		local parent = self:GetParent()

		local bone = self.BoneOverride or self.Bone

		if parent:IsValid() and parent.ClassName == "jiggle" then
			return parent.pos, parent.ang
		end

		if parent:IsValid() and parent.GetDrawPosition then
			local ent = parent.GetEntity and parent:GetEntity()
			if ent:IsValid() then
				-- if the parent part is a model, get the bone position of the parent model
				return pac.GetBonePosAng(ent, bone)
			else
				-- else just get the origin of the part
				-- unless we've passed it from parent
				return parent:GetDrawPosition()
			end
		elseif owner:IsValid() then
			-- if there is no parent, default to owner bones
			return pac.GetBonePosAng(owner, bone)
		end
	end

	function PART:SetBone(var)
		self.Bone = var
		self:ClearBone()
	end

	function PART:ClearBone()
		self.BoneIndex = nil
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

		if owner:IsValid() and bones and bones[name] and not bones[name].is_special then
			return bones[name].real
		end

		return name
	end

	function PART:BuildBonePositions()
		if not self:IsHidden() then
			self:OnBuildBonePositions()
		end
	end

	function PART:OnBuildBonePositions()

	end
end

function PART:BuildWorldMatrix(with_offsets)
	local local_matrix = Matrix()
	local_matrix:SetTranslation(self.Position)
	local_matrix:SetAngles(self.Angles)

	if with_offsets then
		local_matrix:Translate(self.PositionOffset)
		local_matrix:Rotate(self.AngleOffset)
	end

	local world_matrix = Matrix()
	local pos, ang = self:GetBonePosition()
	if pos then
		world_matrix:SetTranslation(pos)
	end
	if ang then
		world_matrix:SetAngles(ang)
	end

	local m = world_matrix * local_matrix

	m:SetAngles(self:CalcAngles(m:GetAngles()))

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

-- since this is kind of like a hack I choose to have upper case names to avoid name conflicts with parts
-- the editor can use the keys as friendly names
pac.AimPartNames =
{
	["local eyes"] = "LOCALEYES",
	["player eyes"] = "PLAYEREYES",
	["local eyes yaw"] = "LOCALEYES_YAW",
	["local eyes pitch"] = "LOCALEYES_PITCH",
}

function PART:CalcAngles(ang)
	if not self.WorldMatrix then return ang end

	local owner = self:GetOwner(true)
	local wpos = self.WorldMatrix:GetTranslation()

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
