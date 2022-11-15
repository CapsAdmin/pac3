local NULL = NULL
local pairs = pairs

for _, v in pairs(ents.GetAll()) do
	v.pac_bone_setup_data = nil
end

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.FriendlyName = "legacy experimental bone"
PART.ClassName = "bone2"
PART.Group = "legacy"
PART.Icon = 'icon16/connect.png'
PART.is_bone_part = true

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
		BUILDER:GetSet("HideMesh", false)
		BUILDER:GetSet("InvertHideMesh", false)
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
	if not self.first_getbpos and self:GetOwner():IsValid() then
		self:GetBonePosition()
		self.first_getbpos = true
	end
end

function PART:OnHide()
	local owner = self:GetOwner()

	if owner:IsValid() then
		owner.pac_bone_setup_data = owner.pac_bone_setup_data or {}
		owner.pac_bone_setup_data[self.UniqueID] = nil
	end
end

function PART:GetBonePosition()
	local owner = self:GetOwner()
	return pac.GetBonePosAng(owner, self.Bone, true)
end

local function manpos(ent, id, pos, part)
	if part.AlternativeBones then
		ent.pac_bone_setup_data[part.UniqueID].pos = part.Position + part.PositionOffset
	else
		ent:ManipulateBonePosition(id, ent:GetManipulateBonePosition(id) + pos)
		part.modified_bones = true
	end
end

local function manang(ent, id, ang, part)
	if part.AlternativeBones then
		ent.pac_bone_setup_data[part.UniqueID].ang = part.Angles + part.AngleOffset
	else
		ent:ManipulateBoneAngles(id, ent:GetManipulateBoneAngles(id) + ang)
		part.modified_bones = true
	end
end

local inf_scale = Vector(math.huge, math.huge, math.huge)

local function manscale(ent, id, scale, part)
	if part and part.AlternativeBones then
		ent.pac_bone_setup_data[part.UniqueID].scale = scale
	else
		ent:ManipulateBoneScale(id, ent:GetManipulateBoneScale(id) * scale)
		part.modified_bones = true
	end
end

local function scale_children(owner, id, scale, origin, ownerScale)
	local count = owner:GetBoneCount()
	ownerScale = ownerScale or owner.pac3_Scale or 1

	if count == 0 or count < id then return end

	for i = 0, count - 1 do
		if owner:GetBoneParent(i) ~= id then goto CONTINUE end

		local mat = owner:GetBoneMatrix(i)

		if mat then
			if origin then
				mat:SetTranslation(origin)
			end

			mat:Scale(mat:GetScale() * scale / ownerScale)
			owner:SetBoneMatrix(i, mat)
		end

		scale_children(owner, i, scale, origin, ownerScale)
		::CONTINUE::
	end
end

function pac.build_bone_callback(ent)
	if ent.pac_matrixhack then
		pac.LegacyScale(ent)
	end

	if ent.pac_bone_setup_data then
		for uid, data in pairs(ent.pac_bone_setup_data) do
			local part = data.part or NULL

			if part:IsValid() then
				local mat = ent:GetBoneMatrix(data.bone)
				if mat then
					if part.FollowPart:IsValid() and part.FollowPart.GetWorldPosition then

						mat:SetAngles(part.FollowPart:GetWorldAngles())

						if not part.FollowAnglesOnly then
							mat:SetTranslation(part.FollowPart:GetWorldPosition())
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
						local scale = part.Scale * part.Size
						scale_children(ent, data.bone, scale, data.origin)
					end

					ent:SetBoneMatrix(data.bone, mat)
				end
			else
				ent.pac_bone_setup_data[uid] = nil
			end
		end
	end
end

function PART:OnBuildBonePositions()
	local owner = self:GetOwner()

	if not owner:IsValid() then return end

	local index = self:GetModelBoneIndex()

	if not index then return end

	owner.pac_bone_setup_data = owner.pac_bone_setup_data or {}

	if self.AlternativeBones or self.ScaleChildren or self.FollowPart:IsValid() then
		owner.pac_bone_setup_data[self.UniqueID] = owner.pac_bone_setup_data[self.UniqueID] or {}
		owner.pac_bone_setup_data[self.UniqueID].bone = index
		owner.pac_bone_setup_data[self.UniqueID].part = self
	else
		owner.pac_bone_setup_data[self.UniqueID] = nil
	end

	local ang = self:CalcAngles(self.Angles) or self.Angles

	if not owner.pac_follow_bones_function then
		owner.pac_follow_bones_function = pac.build_bone_callback
		local id
		id = owner:AddCallback("BuildBonePositions", function(ent)
			if pac and pac.build_bone_callback then
				pac.build_bone_callback(ent)
			else
				owner:RemoveCallback("BuildBonePositions", id)
			end
		end)
	end

	if not self.FollowPart:IsValid() then
		if self.EyeAngles or self.AimPart:IsValid() then
			ang.r = ang.y
			ang.y = -ang.p
		end

		local pos2, ang2 = self.Position + self.PositionOffset, ang + self.AngleOffset

		local parent = self:GetParent()

		if parent and parent:IsValid() and parent.ClassName == 'jiggle' then
			local pos3, ang3 = parent.Position, parent.Angles

			if parent.pos then
				pos2 = pos2 + parent.pos - pos3
			end

			if parent.ang then
				ang2 = ang2 + parent.ang - ang3
			end
		end

		manpos(owner, index, pos2, self)
		manang(owner, index, ang2, self)
	end

	if owner.pac_bone_setup_data[self.UniqueID] then
		if self.MoveChildrenToOrigin then
			owner.pac_bone_setup_data[self.UniqueID].origin = self:GetBonePosition()
		else
			owner.pac_bone_setup_data[self.UniqueID].origin = nil
		end
	end

	owner:ManipulateBoneJiggle(index, isnumber(self.Jiggle) and self.Jiggle or (self.Jiggle and 1 or 0)) -- afaik anything but 1 is not doing anything at all

	local scale

	if self.HideMesh then
		scale = inf_scale
		owner.pac_inf_scale = true

		if self.InvertHideMesh then
			local count = owner:GetBoneCount()

			for i = 0, count - 1 do
				if i ~= index then
					manscale(owner, i, inf_scale, self)
				end
			end

			return
		end
	else
		owner.pac_inf_scale = false

		scale = self.Scale * self.Size
	end

	manscale(owner, index, scale, self)

	owner.needs_setupbones_from_legacy_bone_parts = true
end

BUILDER:Register()
