local PART = {}

PART.ClassName = "player"	
PART.HideGizmo = true

function PART:Initialize()
	self.ClipPlanes = {}
	
	self.StorableVars = {}

	pac.StartStorableVars()
		pac.GetSet(self, "Name", "")
		pac.GetSet(self, "Description", "")
		pac.GetSet(self, "Hide", false)
		pac.GetSet(self, "Material", "")
		pac.GetSet(self, "Color", Vector(255, 255, 255))
		pac.GetSet(self, "Alpha", 1)
		pac.GetSet(self, "Scale", Vector(1,1,1))
		pac.GetSet(self, "Size", 1)
		pac.GetSet(self, "Model", "")
		pac.GetSet(self, "DrawWeapon", true)
	pac.EndStorableVars()
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

function PART:StartClipping(pos, ang)
	if #self.ClipPlanes > 0 then
		bclip = render.EnableClipping(true)

		for key, clip in pairs(self.ClipPlanes) do
			if clip:IsValid() then
				local pos, ang = LocalToWorld(clip.Position, clip:CalcAngleVelocity(clip.Angles), pos, ang)
				local normal = ang:Forward()
				render.PushCustomClipPlane(normal, normal:Dot(pos + normal))
			end
		end
	end
end

function PART:EndClipping()
	if #self.ClipPlanes > 0 then
		for key, clip in pairs(self.ClipPlanes) do
			if not clip:IsValid() then
				table.remove(key, self.ClipPlanes)
			end
			render.PopCustomClipPlane()
		end

		render.EnableClipping(bclip)
	end
end

function PART:GetOwner()
	return self.PlayerOwner
end

function PART:UpdateScale(owner)	
	owner:SetModelScale(self.Scale * self.Size)
end

function PART:SetSize(var)
	self.Size = var
	self:UpdateScale()
end

function PART:SetScale(var)	
	self.Scale = var
	self:UpdateScale()
end

PART.Colorf = Vector(1,1,1)

function PART:SetColor(var)
	var = var or Vector(255, 255, 255)

	self.Color = var
	self.Colorf = Vector(var.r, var.g, var.b) / 255
end

function PART:SetMaterial(var)
	self.Material = var
	self.Materialm = Material(var)
end

function PART:GetModel()
	local owner = self:GetOwner()

	if owner:IsValid() and (not self.Model or self.Model == "") then
		return owner:GetModel()
	end
	
	return self.Model
end

function PART:SetModel(path)
	local owner = self:GetOwner()

	if owner:IsValid() then
		owner:SetModel(path)
	end
	
	self.Model = path
end

function PART:UpdateWeaponDraw(owner)
	local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
	
	if wep:IsWeapon() then
		if self.DrawWeapon then
			if wep.RenderOverride then
				wep.RenderOverride = nil
			end
		else
			if not wep.RenderOverride then
				wep.RenderOverride = function() end
			end
		end
	end
end

function PART:UpdateColor(owner)	
	if net then 
		owner:SetColor(Color(self.Color.r, self.Color.g, self.Color.b, math.ceil(self.Alpha * 255)))
	else
		owner:SetColor(self.Color.r, self.Color.g, self.Color.b, math.ceil(self.Alpha * 255))
	end
	
	render.SetBlend(self.Alpha)
end

function PART:UpdateMaterial(owner)
	owner:SetMaterial(self.Material)
end

function PART:UpdateAll(owner)
	self:UpdateScale(owner)
	self:UpdateMaterial(owner)
	self:UpdateColor(owner)
end

function PART:OnAttach(owner)
	owner:SetModel(self:GetModel())
end

function PART:PrePlayerDraw(owner, pos, ang)
	self:StartClipping(pos, ang)
	
	self:UpdateWeaponDraw(owner)
	
	self:UpdateAll(owner)	
end

function PART:PostPlayerDraw(owner, pos, ang)	
	render.SetBlend(1)

	self:EndClipping()
end

pac.RegisterPart(PART)