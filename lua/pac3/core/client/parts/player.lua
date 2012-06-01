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

function PART:GetOwner()
	return self.PlayerOwner
end

function PART:SetSize(var)
	local owner = self:GetOwner()
	
	if owner:IsValid() then
		owner:SetModelScale(self.Scale * var)
	end
	
	self.Size = var
end

function PART:SetScale(var)
	local owner = self:GetOwner()

	if owner:IsValid() then
		owner:SetModelScale(var * self.Size)
	end
	
	self.Scale = var
end

function PART:OnAttach(owner)
	self:SetSize(self:GetSize())
	self:SetScale(self:GetScale())
	owner:SetModel(self:GetModel())
end

PART.Colorf = Vector(1,1,1)

function PART:SetColor(var)
	var = var or Vector(255, 255, 255)

	self.Color = var
	self.Colorf = Vector(var.r, var.g, var.b) / 255
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
	
function PART:PrePlayerDraw(owner, pos, ang)
	render.SetColorModulation(self.Colorf.r, self.Colorf.g, self.Colorf.b)
	render.SetBlend(self.Alpha)
	-- seems to work better than destroying the shadow..
	
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

	if net then
		owner:SetColor(Color(self.Color.r, self.Color.g, self.Color.b, math.max(self.Alpha * 255, 1)))
	else
		owner:SetColor(self.Color.r, self.Color.g, self.Color.b, math.max(self.Alpha * 255, 1)) 
	end
	
	local wep = owner.GetActiveWeapon and owner:GetActiveWeapon() or NULL
	
	if self.Alpha == 0 then	
		if wep:IsWeapon() then 
			wep:DestroyShadow() 
		end
		
		owner:SetMaterial("models/effects/vol_light001")
	else
		owner:SetMaterial(self.Material)
	end
	
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

function PART:PostPlayerDraw(owner, pos, ang)
	if net then
		render.MaterialOverride()
	else
		SetMaterialOverride(0)
	end
	
	render.SetColorModulation(1,1,1)
	render.SetBlend(1)
	
	if self.Alpha == 0 then
		owner:DestroyShadow()
	end
	
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
		
pac.RegisterPart(PART)