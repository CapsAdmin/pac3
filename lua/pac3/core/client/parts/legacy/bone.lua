local NULL = NULL
local pairs = pairs

local entMeta = FindMetaTable("Entity")
local IsEntValid = entMeta.IsValid
local GetTable = entMeta.GetTable
local GetBoneCount = entMeta.GetBoneCount
local GetBoneMatrix = entMeta.GetBoneMatrix
local SetBoneMatrix = entMeta.SetBoneMatrix
local ManipulateBonePosition = entMeta.ManipulateBonePosition
local ManipulateBoneAngles = entMeta.ManipulateBoneAngles
local ManipulateBoneScale = entMeta.ManipulateBoneScale
local ManipulateBoneJiggle = entMeta.ManipulateBoneJiggle
local GetManipulateBonePosition = entMeta.GetManipulateBonePosition
local GetManipulateBoneAngles = entMeta.GetManipulateBoneAngles
local GetManipulateBoneScale = entMeta.GetManipulateBoneScale

for _, v in ents.Iterator() do
	v.pac_bone_setup_data = nil
end

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.FriendlyName = "legacy bone"
PART.ClassName = "bone"
PART.Group = "legacy"
PART.is_bone_part = true

PART.Icon = "icon16/connect.png"

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
		BUILDER:PropertyOrder("Name")
		BUILDER:PropertyOrder("Hide")
		BUILDER:PropertyOrder("ParentName")
		BUILDER:GetSet("Jiggle", false)
		BUILDER:GetSet("ScaleChildren", false)
		BUILDER:GetSet("AlternativeBones", false)
		BUILDER:GetSet("MoveChildrenToOrigin", false)
		BUILDER:GetSet("FollowAnglesOnly", false)
		--BUILDER:GetSet("HideMesh", false)
		--BUILDER:GetSet("InvertHideMesh", false)
		BUILDER:GetSetPart("FollowPart")

	BUILDER:SetPropertyGroup("orientation")
		BUILDER:PropertyOrder("AimPartName")
		BUILDER:PropertyOrder("Bone")
		BUILDER:PropertyOrder("Position")
		BUILDER:PropertyOrder("Angles")
		BUILDER:PropertyOrder("EyeAngles")
		BUILDER:GetSet("Size", 1, {editor_sensitivity = 0.25})
		BUILDER:GetSet("Scale", Vector(1,1,1), {editor_sensitivity = 0.25})
		BUILDER:PropertyOrder("PositionOffset")
		BUILDER:PropertyOrder("AngleOffset")

	BUILDER:SetPropertyGroup("appearance")


	BUILDER:SetPropertyGroup("other")
		BUILDER:PropertyOrder("DrawOrder")

BUILDER:EndStorableVars()

BUILDER:RemoveProperty("Translucent")
BUILDER:RemoveProperty("IgnoreZ")
BUILDER:RemoveProperty("BlendMode")
BUILDER:RemoveProperty("NoTextureFiltering")

local BaseClass_GetOwner = PART.GetOwner

function PART:GetNiceName()
	return self:GetBone()
end

PART.ThinkTime = 0

function PART:OnShow()
	self:SetBone(self:GetBone())
end
PART.OnParent = PART.OnShow

function PART:OnThink()
	-- this is to setup the cached values
	if not self.first_getbpos and IsEntValid(self:GetOwner()) then
		self:GetBonePosition()
		self.first_getbpos = true
	end
end

function PART:OnHide()
	local owner = self:GetOwner()

	if IsEntValid(owner) then
		owner.pac_bone_setup_data = owner.pac_bone_setup_data or {}
		owner.pac_bone_setup_data[self.UniqueID] = nil
	end
end

function PART:GetBonePosition()
	local owner = self:GetOwner()
	local pos, ang

	pos, ang = pac.GetBonePosAng(owner, self.Bone, true)

	return pos, ang
end

local function manpos(ent, entTbl, id, pos, part)
	if part.AlternativeBones then
		entTbl.pac_bone_setup_data[part.UniqueID].pos = part.Position + part.PositionOffset
	else
		ManipulateBonePosition(ent, id, GetManipulateBonePosition(ent, id) + pos)
		part.modified_bones = true
	end
end

local function manang(ent, entTbl, id, ang, part)
	if part.AlternativeBones then
		entTbl.pac_bone_setup_data[part.UniqueID].ang = part.Angles + part.AngleOffset
	else
		ManipulateBoneAngles(ent, id, GetManipulateBoneAngles(ent, id) + ang)
		part.modified_bones = true
	end
end

local inf_scale = Vector(math.huge, math.huge, math.huge)
local inf_scale_tempcrashfix = Vector(1, 1, 1) * 0.001

local function manscale(ent, entTbl, id, scale, part)
	if part.AlternativeBones then
		entTbl.pac_bone_setup_data[part.UniqueID].scale = scale
	else
		ManipulateBoneScale(ent, id, GetManipulateBoneScale(ent, id) * scale)
		part.modified_bones = true
	end
end

local function scale_children(owner, id, scale, origin, ownerScale)
	local count = GetBoneCount(owner)

	if count == 0 or count < id then return end

	for i = 0, count - 1 do
		if owner:GetBoneParent(i) ~= id then goto CONTINUE end

		local mat = GetBoneMatrix(owner, i)

		if mat then
			if origin then
				mat:SetTranslation(origin)
			end

			mat:Scale(mat:GetScale() * scale / ownerScale)

			SetBoneMatrix(owner, i, mat)
		end

		scale_children(owner, i, scale, origin, ownerScale)
		::CONTINUE::
	end
end
local in_build = false
function pac.build_bone_callback(ent)
	if in_build then return end

	local entTbl = GetTable(ent)

	in_build = true
	if entTbl.pac_matrixhack then
		pac.LegacyScale(ent)
	end

	if entTbl.pac_bone_setup_data then
		local entScale = entTbl.pac3_Scale or 1

		for uid, data in pairs(entTbl.pac_bone_setup_data) do
			local part = data.part or NULL

			if part:IsValid() then
				local mat = GetBoneMatrix(ent, data.bone)

				if mat then
					if part.FollowPart:IsValid() and part.FollowPart.GetWorldAngles and part.FollowPart.GetWorldPosition then
						if part.FollowAnglesOnly then
							local pos = mat:GetTranslation()
							mat:SetAngles(part.Angles + part.AngleOffset + part.FollowPart:GetWorldAngles())
							mat:SetTranslation(pos)
						else
							mat:SetAngles(part.Angles + part.AngleOffset + part.FollowPart:GetWorldAngles())
							mat:SetTranslation(part.Position + part.PositionOffset + part.FollowPart:GetWorldPosition())
						end
					else
						if data.pos then
							mat:Translate(data.pos)
						end

						if data.ang then
							mat:Rotate(data.ang)
						end
					end

					if data.scale then
						mat:Scale(mat:GetScale() * data.scale)
					end

					if part.ScaleChildren then
						scale_children(ent, data.bone, part.Scale * part.Size, data.origin, entScale)
					end

					SetBoneMatrix(ent, data.bone, mat)
				end
			else
				entTbl.pac_bone_setup_data[uid] = nil
			end
		end
	end

	in_build = false
end

function PART:OnBuildBonePositions()
	local owner = self:GetOwner()
	if not IsEntValid(owner) then return end

	local ownerTbl = GetTable(owner)

	local index = self:GetModelBoneIndex()

	if not index then
		index = 0
	end

	if not ownerTbl.pac_bone_setup_data then
		ownerTbl.pac_bone_setup_data = {}
	end

	if self.AlternativeBones or self.ScaleChildren or self.FollowPart:IsValid() then
		if not ownerTbl.pac_bone_setup_data[self.UniqueID] then
			ownerTbl.pac_bone_setup_data[self.UniqueID] = {}
		end

		ownerTbl.pac_bone_setup_data[self.UniqueID].bone = index
		ownerTbl.pac_bone_setup_data[self.UniqueID].part = self
	else
		ownerTbl.pac_bone_setup_data[self.UniqueID] = nil
	end

	local ang = self:CalcAngles(self.Angles) or self.Angles

	if not ownerTbl.pac_follow_bones_function then
		ownerTbl.pac_follow_bones_function = pac.build_bone_callback

		local id

		id = owner:AddCallback("BuildBonePositions", function(ent)
			if not self:IsValid() then
				owner:RemoveCallback("BuildBonePositions", id)
				return
			end

			pac.build_bone_callback(ent)
		end)
	end

	if not self.FollowPart:IsValid() then
		if self.EyeAngles or self.AimPart:IsValid() then
			ang.r = ang.y
			ang.y = -ang.p
		end

		manpos(owner, ownerTbl, index, self.Position + self.PositionOffset, self)
		manang(owner, ownerTbl, index, ang + self.AngleOffset, self)
	end

	if ownerTbl.pac_bone_setup_data[self.UniqueID] then
		if self.MoveChildrenToOrigin then
			ownerTbl.pac_bone_setup_data[self.UniqueID].origin = self:GetBonePosition()
		else
			ownerTbl.pac_bone_setup_data[self.UniqueID].origin = nil
		end
	end

	-- afaik anything but 1 is not doing anything at all
	ManipulateBoneJiggle(owner, index, isnumber(self.Jiggle) and self.Jiggle or (self.Jiggle and 1 or 0))

	local scale

	if self.HideMesh then
		scale = inf_scale

		ownerTbl.pac_inf_scale = true

		if self.InvertHideMesh then
			local count = GetBoneCount(owner)

			for i = 0, count - 1 do
				if i ~= index then
					manscale(owner, ownerTbl, i, inf_scale, self)
				end
			end

			return
		end
	else
		ownerTbl.pac_inf_scale = false

		scale = self.Scale * self.Size
	end

	manscale(owner, ownerTbl, index, scale, self)

	ownerTbl.needs_setupbones_from_legacy_bone_parts = true
end

BUILDER:Register()
