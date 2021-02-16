local pac = pac
local pairs = pairs
local ipairs = ipairs
local table = table
local Vector = Vector
local Angle = Angle
local Color = Color
local NULL = NULL
local SysTime = SysTime

local LocalToWorld = LocalToWorld

local function SETUP_CACHE_FUNC(tbl, func_name)
	local old_func = tbl[func_name]

	local cached_key = "cached_" .. func_name
	local cached_key2 = "cached_" .. func_name .. "_2"
	local last_key = "last_" .. func_name .. "_framenumber"

	tbl[func_name] = function(self, a,b,c,d,e)
		if self[last_key] ~= pac.FrameNumber or self[cached_key] == nil then
			self[cached_key], self[cached_key2] = old_func(self, a,b,c,d,e)
			self[last_key] = pac.FrameNumber
		end

		return self[cached_key], self[cached_key2]
	end
end

local BUILDER, PART = pac.PartTemplate("base")

PART.ClassName = "base_movable"

function PART:__tostring()
	return string.format("%s[%s][%s][%i]", self.Type, self.ClassName, self.Name, self.Id)
end

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

local BaseClass_PreInitialize = PART.PreInitialize

function PART:PreInitialize()
	BaseClass_PreInitialize(self)

	self.cached_pos = Vector(0,0,0)
	self.cached_ang = Angle(0,0,0)
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

function PART:GetDrawPosition(bone_override, skip_cache)
	if not self.AllowSetupPositionFrameSkip or pac.FrameNumber ~= self.last_drawpos_framenum or not self.last_drawpos or skip_cache then
		self.last_drawpos_framenum = pac.FrameNumber

		local owner = self:GetOwner()
		if owner:IsValid() then
			local pos, ang = self:GetBonePosition(bone_override, skip_cache)

			pos, ang = LocalToWorld(
				self.Position or Vector(),
				self.Angles or Angle(),
				pos or owner:GetPos(),
				ang or owner:GetAngles()
			)

			ang = self:CalcAngles(ang) or ang

			if not self.PositionOffset:IsZero() or not self.AngleOffset:IsZero() then
				pos, ang = LocalToWorld(self.PositionOffset, self.AngleOffset, pos, ang)
			end

			self.last_drawpos = pos
			self.last_drawang = ang

			return pos, ang
		end
	end

	return self.last_drawpos, self.last_drawang
end

function PART:GetBonePosition(bone_override, skip_cache)
	if not self.AllowSetupPositionFrameSkip or pac.FrameNumber ~= self.last_bonepos_framenum or not self.last_bonepos or skip_cache then
		self.last_bonepos_framenum = pac.FrameNumber

		local owner = self:GetOwner()
		local parent = self:GetParent()

		if parent:IsValid() and parent.ClassName == "jiggle" then
			if skip_cache then
				if parent.Translucent then
					parent:Draw(nil, nil, "translucent")
				else
					parent:Draw(nil, nil, "opaque")
				end
			end

			return parent.pos, parent.ang
		end

		local pos, ang

		if parent:IsValid() and parent.GetDrawPosition then
			local ent = parent.Entity or NULL

			if ent:IsValid() then
				-- if the parent part is a model, get the bone position of the parent model
				if ent.pac_bone_affected ~= FrameNumber() then
					ent:InvalidateBoneCache()
				end

				pos, ang = pac.GetBonePosAng(ent, bone_override or self.Bone)
			else
				-- else just get the origin of the part
				-- unless we've passed it from parent
				pos, ang = parent:GetDrawPosition()
			end
		elseif owner:IsValid() then
			-- if there is no parent, default to owner bones
			owner:InvalidateBoneCache()
			pos, ang = pac.GetBonePosAng(owner, self.Bone)
		end

		self.last_bonepos = pos
		self.last_boneang = ang

		return pos, ang
	end

	return self.last_bonepos, self.last_boneang
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
	local owner = self:GetOwner(true)

	if pac.StringFind(self.AimPartName, "LOCALEYES_YAW", true, true) then
		ang = (pac.EyePos - self.cached_pos):Angle()
		ang.p = 0
		return self.Angles + ang
	end

	if pac.StringFind(self.AimPartName, "LOCALEYES_PITCH", true, true) then
		ang = (pac.EyePos - self.cached_pos):Angle()
		ang.y = 0
		return self.Angles + ang
	end

	if pac.StringFind(self.AimPartName, "LOCALEYES", true, true) then
		return self.Angles + (pac.EyePos - self.cached_pos):Angle()
	end


	if pac.StringFind(self.AimPartName, "PLAYEREYES", true, true) then
		local ent = owner.pac_traceres and owner.pac_traceres.Entity or NULL

		if ent:IsValid() then
			return self.Angles + (ent:EyePos() - self.cached_pos):Angle()
		end

		return self.Angles + (pac.EyePos - self.cached_pos):Angle()
	end

	if self.AimPart:IsValid() and self.AimPart.cached_pos then
		return self.Angles + (self.AimPart.cached_pos - self.cached_pos):Angle()
	end

	if self.EyeAngles then
		if owner:IsPlayer() then
			return self.Angles + ((owner.pac_hitpos or owner:GetEyeTraceNoCursor().HitPos) - self.cached_pos):Angle()
		elseif owner:IsNPC() then
			return self.Angles + ((owner:EyePos() + owner:GetForward() * 100) - self.cached_pos):Angle()
		end
	end

	return ang or Angle(0,0,0)
end

BUILDER:Register()
