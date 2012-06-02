local PART = {}

PART.ClassName = "model"

pac.StartStorableVars()
	--pac.GetSet(PART, "BoneMerge", false)
	pac.GetSet(PART, "Skin", 0)
	pac.GetSet(PART, "Fullbright", false)
	pac.GetSet(PART, "Invert", false)
	pac.GetSet(PART, "DoubleFace", false)
	pac.GetSet(PART, "Bodygroup", 0)
	pac.GetSet(PART, "BodygroupState", 0)
	pac.GetSet(PART, "Sequence", 1)
	pac.GetSet(PART, "Material", "")
	pac.GetSet(PART, "Color", Vector(255, 255, 255))
	pac.GetSet(PART, "Alpha", 1)
	pac.GetSet(PART, "Scale", Vector(1,1,1))
	pac.GetSet(PART, "Size", 1)
	pac.GetSet(PART, "Model", "models/props_junk/watermelon01.mdl")
pac.EndStorableVars()

pac.GetSet(PART, "Entity", NULL)

function PART:Initialize()
	self.ClipPlanes = {}
	
	self.Color = self.Color * 1
	self.Scale = self.Scale * 1
	
	self.Entity = pac.CreateEntity(self.Model)
	self.Entity:SetNoDraw(true)
	self.Entity.PACPart = self
end

function PART:GetModelBones()
	local parent = self.RealParent
	if parent and parent.Entity:IsValid() then
		return pac.GetModelBones(parent.Entity)
	else
		return pac.GetModelBones(self:GetOwner())
	end
end

function PART:GetModelBonesSorted()
	local parent = self.RealParent
	if parent and IsValid(parent.Entity) then
		return pac.GetModelBonesSorted(parent.Entity)
	else
		return pac.GetModelBonesSorted(self:GetOwner())
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

function PART:OnAttach(owner)
	local ent = self:GetEntity()
	
	if ent:IsValid() and owner:IsValid() then
		ent:SetPos(owner:EyePos())
		ent:SetParent(owner)
		self.BoneIndex = nil
	end
end

function PART:OnParent(part)
	local ent = self:GetEntity()

	if part.ClassName == self.ClassName and part:GetEntity():IsValid() then
		ent:SetParent(self:GetParent():GetEntity())
	else
		ent:SetParent(owner)
	end	
end

function PART:OnUnParent()
	local ent = self:GetEntity()
	
	if ent:IsValid() then
		ent:SetParent(self:GetOwner())
	end
end

local ring = Material("particle/particle_Ring_Sharp")

function PART:DrawHighlight(owner, pos, ang)
	local ent = self.Entity

	if ent:IsValid() then
		render.SetMaterial(ring)
		render.DrawSprite(pos, 8, 8, color_white)
	end
end

local bclip

function PART:OnDraw(owner, pos, ang)
	if self:IsHighlighting() then
		self:DrawHighlight(owner, pos, ang)
	end
	
	local ent = self.Entity

	if ent:IsValid() then
	
		if ent:GetParent():IsValid() then
			if self.BoneMerge then
				ent:AddEffects(EF_BONEMERGE)
			else
				ent:RemoveEffects(EF_BONEMERGE)
			end
		end
	
		ent:SetPos(pos)
		ent:SetRenderOrigin(pos)
		ent:SetAngles(ang)
		ent:SetRenderAngles(ang)
		
		if #self.ClipPlanes > 0 then
			bclip = render.EnableClipping(true)

			for key, clip in pairs(self.ClipPlanes) do
				if clip:IsValid() and not clip:IsHidden() then
					local pos, ang = LocalToWorld(clip.Position, clip:CalcAngleVelocity(clip.Angles), pos, ang)
					local normal = ang:Forward()
					render.PushCustomClipPlane(normal, normal:Dot(pos + normal))
				end
			end
		end

			if self.DoubleFace then
				render.CullMode(MATERIAL_CULLMODE_CW)
			else
				if self.Invert then
					render.CullMode(MATERIAL_CULLMODE_CW)
				end
			end
						
			if self.Colorf then render.SetColorModulation(self.Colorf.r, self.Colorf.g, self.Colorf.b) end
			if self.Alpha then render.SetBlend(self.Alpha) end
			if self.Materialm then if net then render.MaterialOverride(self.Materialm) else SetMaterialOverride(self.Materialm) end end
		
			if self.Fullbright then
				render.SuppressEngineLighting(true) 
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
				
			if self.Fullbright then
				render.SuppressEngineLighting(false) 
			end
			
			render.SetColorModulation(1,1,1)
			render.SetBlend(1)
			
			if net then render.MaterialOverride() else SetMaterialOverride() end
		
		if #self.ClipPlanes > 0 then
			for key, clip in pairs(self.ClipPlanes) do
				if not clip:IsValid() then
					table.remove(self.ClipPlanes, key)
				end
				if not clip:IsHidden() then
					render.PopCustomClipPlane()
				end
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
	var = var or Vector()

	self.Color = var
	self.Colorf = Vector(var.r, var.g, var.b) / 255
end

function PART:SetMaterial(var)
	var = var or ""

	self.Material = var
	if var ~= "" then
		self.Materialm = Material(var)
	end
end

function PART:SetBodygroupState(var)
	var = var or 0

	self.BodygroupState = var
	timer.Simple(0, function() 
		if self:IsValid() and self.Entity:IsValid() then
			self.Entity:SetBodygroup(self.Bodygroup, var) 
		end
	end)		
end

function PART:SetBodygroup(var)
	var = var or 0

	self.Bodygroup = var
	timer.Simple(0, function() 
		if self:IsValid() and self.Entity:IsValid() then
			self.Entity:SetBodygroup(var, self.BodygroupState) 
		end
	end)		
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