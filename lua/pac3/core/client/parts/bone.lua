local NULL = NULL
local pairs = pairs

for _, v in pairs(ents.GetAll()) do
	v.pac_bone_setup_data = nil
end

local BUILDER, PART = pac.PartTemplate("base_movable")

PART.FriendlyName = "bone"
PART.ClassName = "bone3"
PART.Groups = {'entity', 'model'}
PART.Icon = 'icon16/connect.png'

BUILDER:StartStorableVars()
	BUILDER:SetPropertyGroup("generic")
		BUILDER:PropertyOrder("Name")
		BUILDER:PropertyOrder("Hide")
		BUILDER:PropertyOrder("ParentName")
		BUILDER:GetSet("Jiggle", false)
		BUILDER:GetSet("ScaleChildren", false)
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

local BaseClass_GetOwner = PART.GetOwner

function PART:GetNiceName()
	return self:GetBone()
end

function PART:SetJiggle(val)
	self.Jiggle = val

	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	self:SetBone(self:GetBone())

	if self.bone_index then
		owner:ManipulateBoneJiggle(self.bone_index, self.Jiggle and 1 or 0)
	end
end

function PART:SetBone(val)
	self.Bone = val
	self.bone_index = self:GetModelBoneIndex(self.Bone)
end

function PART:OnShow()
	self:SetBone(self:GetBone())

	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	if self.build_bone_id then return end

	local build_bone_id

	build_bone_id = owner:AddCallback("BuildBonePositions", function(...)
		if not self:IsValid() then
			owner:RemoveCallback("BuildBonePositions", build_bone_id)
			self.build_bone_id = nil
			return
		end

		self:BuildBonePositions2(...)
	end)

	self.build_bone_id = build_bone_id
end

function PART:OnHide()
	local owner = self:GetOwner()
	if not owner:IsValid() then return end

	if self.build_bone_id then
		owner:RemoveCallback("BuildBonePositions", self.build_bone_id)
		self.build_bone_id = nil
	end
end

local inf_scale = Vector(math.huge, math.huge, math.huge)

local function scale_children(ent, root_index, bone_count, scale, move_to_origin)
	for child_index = 0, bone_count - 1 do
		if ent:GetBoneParent(child_index) == root_index then
			local m = ent:GetBoneMatrix(child_index)

			if m then
				if move_to_origin then
					m:SetTranslation(move_to_origin)
				end

				m:Scale(scale)
				ent:SetBoneMatrix(child_index, m)
			end

			scale_children(ent, child_index, bone_count, scale, move_to_origin)
		end
	end
end

local function move_children(ent, root_index, bone_count, parent_matrix, prev_matrix, scale)
	for child_index = 0, bone_count - 1 do
		if ent:GetBoneParent(child_index) == root_index then
			local child_matrix = ent:GetBoneMatrix(child_index)
			if child_matrix then
				local inverse_prev_matrix = prev_matrix:GetInverse()
				if inverse_prev_matrix then
					local m = parent_matrix * inverse_prev_matrix
					m = m * child_matrix
					ent:SetBoneMatrix(child_index, m)
					move_children(ent, child_index, bone_count, m, child_matrix, scale)
				end
			end
		end
	end
end

function PART:BuildBonePositions2(ent, bone_count)
	local index = self.bone_index

	if not index then return end

	local m = ent:GetBoneMatrix(index)
	if not m then return end

	local original_matrix = Matrix()
	original_matrix:Set(m)

	if self.FollowPart:IsValid() and self.FollowPart.GetWorldPosition then
		if not self.FollowAnglesOnly then
			m:SetTranslation(self.FollowPart:GetWorldPosition())
		end

		m:SetAngles(self.FollowPart:GetWorldAngles())
		m:Rotate(self.Angles)
	else

		local prev_ang = m:GetAngles()
		if true then
			m:Rotate(Angle(0,0,-90))
		end

		m:Translate(self.Position)


		if true then
			m:SetAngles(prev_ang)
		end


		m:Rotate(self.Angles)
	end

	local scale

	if self.HideMesh then
		scale = inf_scale
		ent.pac_inf_scale = true

		if self.InvertHideMesh then
			local count = ent:GetBoneCount()

			for i = 0, count - 1 do
				if i ~= index then
					local m = ent:GetBoneMatrix(i)
					if m then
						m:Scale(scale)
						ent:SetBoneMatrix(i, m)
					end
				end
			end

			return
		end
	else
		ent.pac_inf_scale = false

		scale = self.Scale * self.Size
	end


	if self.ScaleChildren then
		scale_children(ent, index, bone_count, scale, self.MoveChildrenToOrigin and m:GetTranslation())
	end

	move_children(ent, index, bone_count, m, original_matrix, scale)


	m:Scale(scale)

	ent:SetBoneMatrix(index, m)
end

function PART:GetOwner(root)
	local parent = self:GetParent()

	if parent:IsValid() and parent.is_model_part then
		return parent.Entity
	end

	return BaseClass_GetOwner(self, root)
end

function PART:GetBonePosition()
	local owner = self:GetOwner()
	return pac.GetBonePosAng(owner, self.Bone, true)
end

BUILDER:Register()

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