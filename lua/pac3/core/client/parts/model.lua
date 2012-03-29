local PART = {}

PART.ClassName = "model"

PART.ClipPlanes = {}

pac.StartStorableVars()
	pac.GetSet(PART, "Skin", 0)
	pac.GetSet(PART, "Fullbright", false)
	pac.GetSet(PART, "Invert", false)
	pac.GetSet(PART, "DoubleFace", false)
	pac.GetSet(PART, "Bodygroup", 0)
	pac.GetSet(PART, "BodygroupState", 0)
	pac.GetSet(PART, "Animation", {})
	pac.GetSet(PART, "Sequence", 1)
	pac.GetSet(PART, "Material", "")
	pac.GetSet(PART, "Color", color_white)
	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "Model", "models/props_junk/watermelon01.mdl")
pac.EndStorableVars()

pac.GetSet(PART, "Entity", NULL)

function PART:Initialize()
	self.Entity = pac.CreateEntity(self.Model)
	self.Entity:SetNoDraw(true)
	self.Entity.PACPart = self
end

function PART:GetModelBones()
	local parent = self.RealParent
	if parent and parent.Entity:IsValid() then
		return pac.GetModelBones(parent.Entity)
	else
		return pac.GetModelBones(self.Owner)
	end
end

function PART:GetModelBonesSorted()
	local parent = self.RealParent
	if parent and IsValid(parent.Entity) then
		return pac.GetModelBonesSorted(parent.Entity)
	else
		return pac.GetModelBonesSorted(self.Owner)
	end
end

function PART:AddClipPlane(part)
	return table.insert(self.ClipPlanes, part)
end

function PART:RemoveClipPlane(id)
	local part = self.ClipPlanes[id]
	if part then
		table.remove(self.ClipPlanes, id)
		part:Remove()
	end
end

function PART:OnAttach(outfit)
	local owner = outfit:GetOwner()

	local ent = self:GetEntity()
	if ent:IsValid() and owner:IsValid() then
		ent:SetPos(owner:EyePos())
		ent:SetParent(owner)
		self.BoneIndex = nil
	end
end

local bclip

function PART:PostPlayerDraw(owner, pos, ang)
	local ent = self.Entity

	if ent:IsValid() then
		ent:SetPos(pos)
		ent:SetRenderOrigin(pos)
		ent:SetAngles(ang)
		ent:SetRenderAngles(ang)

		if #self.ClipPlanes > 0 then
			bclip = render.EnableClipping(true)

			for key, clip in ipairs(self.ClipPlanes) do
				local pos, ang = LocalToWorld(clip.LocalPos, self:GetVelocityAngle(clip.LocalAng), pos, ang)
				local normal = ang:Forward()
				render.PushCustomClipPlane(normal, normal:Dot(pos + normal))
			end
		end

		if self.Fullbright then	render.SuppressEngineLighting(true)	end

			if self.DoubleFace then
				render.CullMode(MATERIAL_CULLMODE_CW)
			else
				if self.Invert then
					render.CullMode(MATERIAL_CULLMODE_CW)
				end
			end

				ent:DrawModel()

			if self.DoubleFace then
				render.CullMode(MATERIAL_CULLMODE_CCW)
				ent:DrawModel()
			else
				if self.Invert then
					render.CullMode(MATERIAL_CULLMODE_CCW)
				end
			end

		if self.Fullbright then	render.SuppressEngineLighting(false) end

		if #self.ClipPlanes > 0 then
			for key, clip in ipairs(self.ClipPlanes) do
				render.PopCustomClipPlane()
			end

			render.EnableClipping(bclip)
		end
	end
end

function PART:SetModel(var)
	self.Model = var
	self.Entity.pac_bones = nil
	self.Entity:SetModel(var)
	self:SetTooltip(var)
end

function PART:SetScale(var)
	var = var or Vector(1,1,1)

	self.Scale = var
	self.Entity:SetModelScale(self.Scale * self.Size)
end

function PART:SetSize(var)
	var = var or 1

	self.Size = var
	self.Entity:SetModelScale(self.Scale * self.Size)
end

function PART:SetColor(var)
	var = var or color_white

	self.Color = var
	self.Entity:SetColor(var.r, var.g, var.b, var.a)
end

function PART:SetMaterial(var)
	var = var or ""

	self.Material = var
	self.Entity:SetMaterial(var or "")
end

function PART:SetAnimation(var)
	if not var then self.Animation = nil return end

	self.Animation = {
		Loop = var.Loop,
		Name = var.Name or "invalid name",
		Rate = var.Rate or 1,
		Offset = var.Offset or 0,
		Min = var.Min or 0,
		Max = var.Max or 1,
	}
end

function PART:SetBodygroupState(var)
	var = var or 0

	self.BodygroupState = var
	self.Entity:SetBodygroup(self.Bodygroup, var)
end

function PART:SetBodygroup(var)
	var = var or 0

	self.Bodygroup = var
	self.Entity:SetBodygroup(var, self.BodygroupState)
end

function PART:SetSkin(var)
	var = var or 0

	self.Skin = var
	self.Entity:SetSkin(var)
end

function PART:OnRemove()
	SafeRemoveEntity(self.Entity)
end

pac.RegisterPart(PART)