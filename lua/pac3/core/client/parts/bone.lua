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

function PART:GetNiceName()
	return self:GetBone()
end

function PART:SetBone(val)
	self.Bone = val
	self.bone_index = self:GetModelBoneIndex(self.Bone)
end

function PART:OnShow()
	self:SetBone(self:GetBone())

	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	ent.pac_bone_parts = ent.pac_bone_parts or {}
	if not table.HasValue(ent.pac_bone_parts, self) then
		table.insert(ent.pac_bone_parts, self)
	end

	if ent.pac_build_bone_id then
		ent:RemoveCallback("BuildBonePositions", ent.pac_build_bone_id)
	end

	local id
	id = ent:AddCallback("BuildBonePositions", function(ent, ...)
		if not ent.pac_bone_parts or not ent.pac_bone_parts[1] then
			ent:RemoveCallback("BuildBonePositions", id)
			return
		end

		for _, bone in ipairs(ent.pac_bone_parts) do
			bone:BuildBonePositions2(ent)
		end
	end)

	ent.pac_build_bone_id = id
end

function PART:OnHide()
	local ent = self:GetOwner()
	if not ent:IsValid() then return end

	if ent.pac_bone_parts then
		for i,v in ipairs(ent.pac_bone_parts) do
			if v == self then
				table.remove(ent.pac_bone_parts, i)
				break
			end
		end
	end
end

local inf_scale = Vector(math.huge, math.huge, math.huge)

local function get_children_bones(ent, root_index, bone_count, out)
	ent:SetLOD(0)
	for child_index = 0, bone_count - 1 do
		if ent:GetBoneParent(child_index) == root_index then
			table.insert(out, child_index)
			get_children_bones(ent, child_index, bone_count, out)
		end
	end
end

local function get_children_bones_cached(ent, root_index)
	ent.pac_cached_child_bones = ent.pac_cached_child_bones or {}

	if not ent.pac_cached_child_bones[root_index] then
		ent.pac_cached_child_bones[root_index] = {}
		get_children_bones(ent, root_index, ent:GetBoneCount(), ent.pac_cached_child_bones[root_index])
	end

	return ent.pac_cached_child_bones[root_index]
end

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

local original_matrix = Matrix()
function PART:BuildBonePositions2(ent)
	local index = self.bone_index

	if not index then return end

	local m = ent:GetBoneMatrix(index)

	if not m then return end


	original_matrix:Set(m)

	self.bone_matrix = original_matrix

	if self.FollowPart:IsValid() and self.FollowPart.GetWorldPosition then
		local pos, ang
		if self.FollowPart.ClassName == "jiggle" then
			pos = self.FollowPart.pos
			ang = self.FollowPart.ang
		else
			pos = self.FollowPart:GetWorldPosition()
			ang = self.FollowPart:GetWorldAngles()
		end

		if not self.FollowAnglesOnly then
			m:SetTranslation(pos)
		end

		m:SetAngles(ang + self.AngleOffset)
		m:Rotate(self.Angles)
		original_matrix:Set(m)
	else
		m:Translate(self.Position + self.PositionOffset)
		m:Rotate(self.Angles + self.AngleOffset)
	end

	local scale = self.Scale * self.Size

	do
		local should_scale = self.ScaleChildren
		local scale_origin = self.MoveChildrenToOrigin and m:GetTranslation()

		for _, child_index in ipairs(get_children_bones_cached(ent, index)) do
			local m = ent:GetBoneMatrix(child_index)
			if not m then continue end

			if should_scale then
				if scale_origin then
					m:SetTranslation(scale_origin)
				end


				m:Scale(scale)
			end

			ent:SetBoneMatrix(child_index, m)
		end
	end


	local parent_matrix = m
	local prev_matrix = original_matrix

	for _, child_index in ipairs(get_children_bones_cached(ent, index)) do
		local child_matrix = ent:GetBoneMatrix(child_index)
		if not child_matrix then continue end
		local inverse_prev_matrix = prev_matrix:GetInverse()
		if inverse_prev_matrix then
			local m = parent_matrix * inverse_prev_matrix
			m = m * child_matrix

			ent:SetBoneMatrix(child_index, m)

			parent_matrix = m
			prev_matrix = child_matrix
		end
	end

	m:Scale(scale)

	ent:SetBoneMatrix(index, m)

	if self.HideMesh then
		local inf_scale = inf_scale

		if ent.GetRagdollEntity and ent:GetRagdollEntity():IsValid() then
			inf_scale = vector_origin
		end

		ent.pac_inf_scale = true

		if self.InvertHideMesh then
			local count = ent:GetBoneCount()

			for i = 0, count - 1 do
				if i ~= index then
					ent:ManipulateBoneScale(i, inf_scale)
				end
			end
		else
			ent:ManipulateBoneScale(index, inf_scale)
		end
	else
		ent.pac_inf_scale = false
	end
end

function PART:GetBonePosition()
	local ent = self:GetOwner()

	if not ent:IsValid() then return Vector(), Angle() end

	local index = self.bone_index

	if not index then return ent:GetPos(), ent:GetAngles() end

	local m = (self.bone_matrix and self.bone_matrix * Matrix()) or ent:GetBoneMatrix(index)
	if not m then return ent:GetPos(), ent:GetAngles() end

	local pos = m:GetTranslation()
	local ang = m:GetAngles()

	return pos, ang
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