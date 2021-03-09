local NULL = NULL
local pairs = pairs

for _, v in pairs(ents.GetAll()) do
	v.pac_bone_setup_data = nil
end

local PART = {}

PART.FriendlyName = "bone"
PART.ClassName = "bone2"
PART.Groups = {'entity', 'model'}
PART.Icon = 'icon16/connect.png'

pac.StartStorableVars()
	pac.SetPropertyGroup(PART, "generic")
		pac.PropertyOrder(PART, "Name")
		pac.PropertyOrder(PART, "Hide")
		pac.PropertyOrder(PART, "ParentName")
		pac.GetSet(PART, "Jiggle", false)
		pac.GetSet(PART, "ScaleChildren", false)
		pac.GetSet(PART, "AlternativeBones", false)
		pac.GetSet(PART, "MoveChildrenToOrigin", false)
		pac.GetSet(PART, "FollowAnglesOnly", false)
		pac.GetSet(PART, "HideMesh", false)
		pac.GetSet(PART, "InvertHideMesh", false)
		pac.SetupPartName(PART, "FollowPart")

	pac.SetPropertyGroup(PART, "orientation")
		pac.PropertyOrder(PART, "AimPartName")
		pac.PropertyOrder(PART, "Bone")
		pac.PropertyOrder(PART, "Position")
		pac.PropertyOrder(PART, "Angles")
		pac.PropertyOrder(PART, "EyeAngles")
		pac.GetSet(PART, "Size", 1, {editor_sensitivity = 0.25})
		pac.GetSet(PART, "Scale", Vector(1,1,1), {editor_sensitivity = 0.25})
		pac.PropertyOrder(PART, "PositionOffset")
		pac.PropertyOrder(PART, "AngleOffset")

	pac.SetPropertyGroup(PART, "appearance")


	pac.SetPropertyGroup(PART, "other")
		pac.PropertyOrder(PART, "DrawOrder")

pac.EndStorableVars()

pac.RemoveProperty(PART, "Translucent")
pac.RemoveProperty(PART, "IgnoreZ")
pac.RemoveProperty(PART, "BlendMode")
pac.RemoveProperty(PART, "NoTextureFiltering")

function PART:GetNiceName()
	return self:GetBone()
end

PART.ThinkTime = 0

function PART:OnShow()
	self.BoneIndex = nil
end

PART.OnParent = PART.OnShow

function PART:GetOwner(root)
	local parent = self:GetParent()

	if parent:IsValid() and parent.is_model_part then
		return parent.Entity
	end

	return self.BaseClass.GetOwner(self, root)
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
		owner.pac_bone_setup_data = owner.pac_bone_setup_data or {}
		owner.pac_bone_setup_data[self.UniqueID] = nil
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

local function manpos(ent, id, pos, part)
	if part.AlternativeBones then
		ent.pac_bone_setup_data[part.UniqueID].pos = part.Position + part.PositionOffset
	else
		ent:ManipulateBonePosition(id, ent:GetManipulateBonePosition(id) + pos)
		if ent:EntIndex() == -1 then ent.pac_bone_affected = FrameNumber() end
	end
end

local function manang(ent, id, ang, part)
	if part.AlternativeBones then
		ent.pac_bone_setup_data[part.UniqueID].ang = part.Angles + part.AngleOffset
	else
		ent:ManipulateBoneAngles(id, ent:GetManipulateBoneAngles(id) + ang)
		if ent:EntIndex() == -1 then ent.pac_bone_affected = FrameNumber() end
	end
end

local inf_scale = Vector(math.huge, math.huge, math.huge)
local inf_scale_tempcrashfix = Vector(1,1,1)*0.001

local function manscale(ent, id, scale, part)
	if part and part.AlternativeBones then
		ent.pac_bone_setup_data[part.UniqueID].scale = scale
	else
		ent:ManipulateBoneScale(id, ent:GetManipulateBoneScale(id) * scale)
		if ent:EntIndex() == -1 then ent.pac_bone_affected = FrameNumber() end
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
					if part.FollowPart:IsValid() then
						local _, angles = LocalToWorld(Vector(), part.Angles + part.AngleOffset, Vector(), part.FollowPart.cached_ang)
						if part.FollowAnglesOnly then
							mat:SetAngles(angles)
						else
							mat:SetTranslation(part.Position + part.PositionOffset + part.FollowPart.cached_pos)
							mat:SetAngles(angles)
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

	self.BoneIndex = owner:LookupBone(self:GetRealBoneName(self.Bone))

	if not self.BoneIndex then return end

	owner.pac_bone_setup_data = owner.pac_bone_setup_data or {}

	if self.AlternativeBones or self.ScaleChildren or self.FollowPart:IsValid() then
		owner.pac_bone_setup_data[self.UniqueID] = owner.pac_bone_setup_data[self.UniqueID] or {}
		owner.pac_bone_setup_data[self.UniqueID].bone = self.BoneIndex
		owner.pac_bone_setup_data[self.UniqueID].part = self
	else
		owner.pac_bone_setup_data[self.UniqueID] = nil
	end

	local ang = self:CalcAngles(self.Angles) or self.Angles

	if not owner.pac_follow_bones_function then
		owner.pac_follow_bones_function = pac.build_bone_callback
		owner:AddCallback("BuildBonePositions", function(ent) pac.build_bone_callback(ent) end)
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

		manpos(owner, self.BoneIndex, pos2, self)
		manang(owner, self.BoneIndex, ang2, self)
	end

	if owner.pac_bone_setup_data[self.UniqueID] then
		if self.MoveChildrenToOrigin then
			owner.pac_bone_setup_data[self.UniqueID].origin = self:GetBonePosition()
		else
			owner.pac_bone_setup_data[self.UniqueID].origin = nil
		end
	end

	owner:ManipulateBoneJiggle(self.BoneIndex, type(self.Jiggle) == "number" and self.Jiggle or (self.Jiggle and 1 or 0)) -- afaik anything but 1 is not doing anything at all

	local scale

	if self.HideMesh then
		scale = inf_scale
		owner.pac_inf_scale = true

		if self.InvertHideMesh then
			local count = owner:GetBoneCount()

			for i = 0, count - 1 do
				if i ~= self.BoneIndex then
					manscale(owner, i, inf_scale, self)
				end
			end

			return
		end
	else
		owner.pac_inf_scale = false

		scale = self.Scale * self.Size
	end

	manscale(owner, self.BoneIndex, scale, self)

	-- TODO: only when actually modified?
	owner:SetupBones()
end

pac.RegisterPart(PART)

pac.AddHook("OnEntityCreated", "hide_mesh_no_crash", function(ent)
	local ply = ent:GetRagdollOwner()
	if ply:IsPlayer() and ply.pac_inf_scale then
		for i = 0, ply:GetBoneCount() - 1 do
			local scale = ply:GetManipulateBoneScale(i)
			if scale == inf_scale then
				scale = Vector(0,0,0)
			end
			ply:ManipulateBoneScale(i, scale)
		end
	end
end)
